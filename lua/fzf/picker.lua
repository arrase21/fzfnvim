local config = require("fzf.config")
local ui = require("fzf.ui")

local M = {}

function M.pick(opts)
  opts = opts or {}

  local tmpfile
  local cmd
  if type(opts.source) == "string" then
    cmd = opts.source
  elseif type(opts.source) == "table" then
    local lines = {}
    local fmt = opts.format_item or tostring
    for _, item in ipairs(opts.source) do
      table.insert(lines, fmt(item))
    end
    tmpfile = vim.fn.tempname()
    vim.fn.writefile(lines, tmpfile)
    cmd = "cat " .. vim.fn.shellescape(tmpfile)
  else
    error("picker: source must be a string or table")
  end

  local win_opts = opts.win_opts

  if not win_opts then
    local layout = opts.layout or config.options.ui.layout
    local resolver = config.layout_presets[layout]

    if resolver then
      win_opts = resolver(config.options.ui)
    else
      win_opts = config.layout_presets.center(config.options.ui)
    end
  end

  if opts.title then
    win_opts.title = opts.title
  end

  local flags = {}

  if opts.preview then
    table.insert(flags, string.format("--preview '%s'", opts.preview))
    table.insert(flags, string.format("--preview-window=%s", opts.preview_window or win_opts.preview_window or "right:60%"))
  end

  if opts.delimiter then
    local delim = opts.delimiter:gsub("\t", "\\t")
    table.insert(flags, string.format("--delimiter '%s'", delim))
  end

  if opts.with_nth then
    table.insert(flags, string.format("--with-nth %s", opts.with_nth))
  end

  if opts.header then
    table.insert(flags, string.format("--header '%s'", opts.header))
  end

  if opts.bind then
    local parts = {}
    for key, action in pairs(opts.bind) do
      table.insert(parts, key .. ":" .. action)
    end
    table.insert(flags, string.format("--bind '%s'", table.concat(parts, ",")))
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

  if win_opts.fzf_opts then
    for _, opt in ipairs(win_opts.fzf_opts) do
      table.insert(flags, opt)
    end
  end

  local flag_str = ""
  if #flags > 0 then
    flag_str = " " .. table.concat(flags, " ")
  end

  local pipeline = cmd .. " | " .. ui.get_fzf_base() .. flag_str

  local full_cmd

  if tmpfile then
    full_cmd = "{ " .. pipeline .. "; rm -f " .. vim.fn.shellescape(tmpfile) .. "; }"
  else
    full_cmd = pipeline
  end

  ui.fzf_ui(full_cmd, function(selection, root)
    if opts.on_select and selection ~= "" then
      opts.on_select(selection, { root = root })
    end
  end, win_opts)
end

return M
