local config = require("fzf.config")
local ui = require("fzf.ui")
local helpers = require("fzf.helpers")

local M = {}

M._last_state = nil

function M.resume()
  if not M._last_state then
    return helpers.notify("No previous picker to resume", vim.log.levels.WARN)
  end
  M.pick(M._last_state)
end

local function resolve_win_opts(opts)
  local win_opts = opts.win_opts
  if win_opts then
    return win_opts
  end

  local layout = opts.layout or config.options.ui.layout
  local resolver = config.layout_presets[layout]
  if resolver then
    win_opts = resolver(config.options.ui)
  else
    win_opts = config.layout_presets.center(config.options.ui)
  end

  if opts.title then
    win_opts.title = opts.title
  end

  return win_opts
end

local function write_source_to_temp(source, format_item)
  local lines = {}
  format_item = format_item or tostring
  for _, item in ipairs(source) do
    table.insert(lines, format_item(item))
  end
  local tmpfile = vim.fn.tempname()
  vim.fn.writefile(lines, tmpfile)
  return tmpfile
end

local function build_pipeline_cmd(source, tmpfile, format_item)
  local cmd
  if type(source) == "string" then
    cmd = source
  elseif type(source) == "function" then
    local res = source()
    if type(res) == "string" then
      cmd = res
    elseif type(res) == "table" then
      tmpfile[1] = write_source_to_temp(res, format_item)
      cmd = "cat " .. vim.fn.shellescape(tmpfile[1])
    end
  elseif type(source) == "table" then
    tmpfile[1] = write_source_to_temp(source, format_item)
    cmd = "cat " .. vim.fn.shellescape(tmpfile[1])
  else
    error("picker: source must be string, table, or function")
  end
  return cmd
end

local function build_fzf_flags(win_opts, opts)
  local flags = {}

  if opts.preview then
    local preview_cmd = type(opts.preview) == "function" and opts.preview() or opts.preview
    table.insert(flags, string.format("--preview '%s'", helpers.escape_shell(preview_cmd)))
    table.insert(flags, string.format(
      "--preview-window=%s",
      opts.preview_window or (win_opts and win_opts.preview_window) or "right:60%"
    ))
  end

  if opts.delimiter then
    local delim = opts.delimiter:gsub("\t", "\\t")
    table.insert(flags, string.format("--delimiter '%s'", delim))
  end

  if opts.with_nth then
    table.insert(flags, string.format("--with-nth %s", opts.with_nth))
  end

  if opts.header then
    table.insert(flags, string.format("--header '%s'", helpers.escape_shell(opts.header)))
  end

  if opts.multiselect then
    table.insert(flags, "--multi")
  end

  if not opts.multiselect then
    table.insert(flags, "--no-multi")
  end

  if opts.prompt then
    table.insert(flags, string.format("--prompt '%s'", opts.prompt))
  end

  if opts.nth then
    table.insert(flags, string.format("--nth %s", opts.nth))
  end

  if opts.bind then
    local parts = {}
    for key, action in pairs(opts.bind) do
      table.insert(parts, key .. ":" .. helpers.escape_shell(action))
    end
    table.insert(flags, "--bind '" .. table.concat(parts, ",") .. "'")
  end

  if opts.fzf_opts then
    if type(opts.fzf_opts) == "string" then
      table.insert(flags, opts.fzf_opts)
    elseif type(opts.fzf_opts) == "table" then
      for _, opt in ipairs(opts.fzf_opts) do
        table.insert(flags, opt)
      end
    end
  end

  if win_opts and win_opts.fzf_opts then
    for _, opt in ipairs(win_opts.fzf_opts) do
      table.insert(flags, opt)
    end
  end

  if opts.preview then
    table.insert(flags, "--preview-label=' Preview '")
  end

  table.insert(flags, "--cycle")

  return " " .. table.concat(flags, " ")
end

local function read_selection(temp, multiselect)
  if vim.fn.filereadable(temp) ~= 1 then
    return nil, nil
  end

  local f = io.open(temp, "r")
  if not f then
    return nil, nil
  end

  local content = f:read("*all")
  f:close()

  content = content:gsub("\n$", "")

  if multiselect then
    local items = vim.split(content, "\n")
    return items, nil
  end

  return content, nil
end

function M.pick(opts)
  opts = opts or {}
  local root = vim.fn.getcwd()

  local win_opts = resolve_win_opts(opts)

  local tmpfiles = {}
  local cmd = build_pipeline_cmd(opts.source, tmpfiles, opts.format_item)

  local flag_str = build_fzf_flags(win_opts, opts)

  local pipeline = cmd .. " | " .. ui.get_fzf_base() .. flag_str

  if opts.prompt_title then
    win_opts.title = opts.prompt_title
  end

  local temp_out = vim.fn.tempname()

  local full_cmd = string.format(
    "cd %s && %s > %s",
    vim.fn.shellescape(root),
    pipeline,
    vim.fn.shellescape(temp_out)
  )

  local backdrop
  if config.options.ui.backdrop then
    backdrop = ui.create_backdrop()
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local width = win_opts.width or math.floor(vim.o.columns * config.options.ui.width)
  local height = win_opts.height or math.floor(vim.o.lines * config.options.ui.height)
  local row = win_opts.row or math.floor((vim.o.lines - height) / 2)
  local col = win_opts.col or math.floor((vim.o.columns - width) / 2)
  local border = win_opts.border or config.options.ui.border or "rounded"
  local title = win_opts.title or config.options.ui.title or " FZF "
  local title_pos = win_opts.title_pos or config.options.ui.title_pos or "center"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = border,
    style = "minimal",
    zindex = 50,
    title = title,
    title_pos = title_pos,
  })

  vim.fn.termopen({ "sh", "-c", full_cmd }, {
    on_exit = function(_, code)
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
        if backdrop and vim.api.nvim_win_is_valid(backdrop) then
          vim.api.nvim_win_close(backdrop, true)
        end

        local multiselect = opts.multiselect or false
        local selection, _ = read_selection(temp_out, multiselect)

        if selection == nil or selection == "" then
          selection = nil
        end

        if selection then
          M._last_state = vim.deepcopy(opts)
        end

        if selection ~= nil and opts.on_select then
          if multiselect and type(selection) == "table" then
            if #selection > 0 then
              opts.on_select(selection, { root = root })
            end
          else
            opts.on_select(selection, { root = root })
          end
        end

        if opts.on_cleanup then
          opts.on_cleanup(selection ~= nil)
        end

        pcall(os.remove, temp_out)
        for _, tf in ipairs(tmpfiles) do
          pcall(os.remove, tf)
        end
      end)
    end,
  })

  vim.keymap.set("t", "<C-c>", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if backdrop and vim.api.nvim_win_is_valid(backdrop) then
      vim.api.nvim_win_close(backdrop, true)
    end
  end, { buffer = buf, nowait = true })

  vim.cmd("startinsert!")
end

return M
