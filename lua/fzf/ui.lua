local config = require("fzf.config")
local M = {}

local function short_path(path)
  local parts = vim.split(path, "/")
  if #parts <= 2 then return path end
  local last = table.concat({parts[#parts - 1], parts[#parts]}, "/")
  if #last > 25 then
    return parts[#parts]
  end
  return last
end

local function resolve_hl(name)
  local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
  if next(hl) == nil then
    hl = vim.api.nvim_get_hl(0, { name = name })
    if hl.link then
      hl = vim.api.nvim_get_hl(0, { name = hl.link, link = false })
    end
  end
  return hl
end

local function rgb(value)
  if type(value) == "number" then
    return string.format("#%06x", value)
  end
end

local function cterm(value)
  if type(value) == "number" then
    return tostring(value)
  end
end

local function fg_of(group)
  local hl = resolve_hl(group)
  return rgb(hl.fg) or cterm(hl.ctermfg)
end

local function bg_of(group)
  local hl = resolve_hl(group)
  return rgb(hl.bg) or cterm(hl.ctermbg)
end

function M.get_fzf_colors()
  local normal_fg = fg_of("Normal") or "-1"
  local normal_bg = bg_of("Normal") or "-1"
  local special = fg_of("Special") or normal_fg
  local border = fg_of("FloatBorder") or fg_of("NonText") or normal_fg
  local sel_fg = fg_of("CursorLine") or normal_fg
  local sel_bg = bg_of("CursorLine") or normal_bg
  local title = fg_of("FloatTitle") or fg_of("Title") or normal_fg

  local colors = {
    "fg:" .. normal_fg,
    "bg:" .. normal_bg,
    "hl:" .. special,
    "fg+:" .. sel_fg,
    "bg+:" .. sel_bg,
    "hl+:" .. special,
    "prompt:" .. special,
    "pointer:" .. special,
    "marker:" .. special,
    "spinner:" .. special,
    "info:" .. (fg_of("NonText") or normal_fg),
    "header:" .. title,
    "border:" .. border,
    "label:" .. title,
    "gutter:" .. normal_bg,
    "query:" .. normal_fg .. ":regular",
    "disabled:" .. (fg_of("Comment") or normal_fg),
    "separator:" .. border,
    "scrollbar:" .. border,
  }
  return table.concat(colors, ",")
end

function M.get_fzf_base()
  local parts = {}
  for _, opt in ipairs(config.options.fzf.base) do
    if not opt:match("^%-%-color") then
      parts[#parts + 1] = opt
    end
  end
  local colors = M.get_fzf_colors()
  if colors ~= "" then
    parts[#parts + 1] = "--color='" .. colors .. "'"
  end
  local cwd = short_path(vim.fn.fnamemodify(vim.fn.getcwd(), ":~"))
  parts[#parts + 1] = string.format("--prompt=' %s 󰍉  '", cwd)
  return "fzf " .. table.concat(parts, " ")
end

function M.get_preview_cmd()
  local command = config.options.preview.command
  local opts = config.options.preview.opts
  local is_bat = vim.fn.fnamemodify(command, ":t"):match("^bat") ~= nil
  if not is_bat or opts:match("%-%-theme") then
    return command .. " " .. opts
  end
  local theme, config_dir, cache_dir = require("fzf.preview").ensure()
  if not theme then
    return command .. " " .. opts
  end
  return string.format(
    "BAT_CONFIG_DIR=%s BAT_CACHE_PATH=%s %s %s --theme=%s",
    vim.fn.shellescape(config_dir),
    vim.fn.shellescape(cache_dir),
    command,
    opts,
    theme
  )
end

local frozen_statuslines = {}
local refresh_autocmd

local function escape_statusline(str)
  return (str:gsub("%%", "%%%%"))
end

local function groups_hl(groups)
  local opts = {}
  for _, group in ipairs(groups) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    if ok and type(hl) == "table" then
      opts = vim.tbl_extend("force", opts, hl)
    end
  end
  return opts
end

local function frozen_hl(groups, index)
  local name = "FzfFrozenStatusline" .. index
  vim.api.nvim_set_hl(0, name, groups_hl(groups))
  return name
end

local function has_transparent_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local ok, wh = pcall(vim.api.nvim_win_get_option, win, "winhighlight")
    if ok and wh:find("Normal:FzfTransparent", 1, true) then
      return true
    end
  end
  return false
end

local function refresh_live_highlights()
  for win, state in pairs(frozen_statuslines) do
    if not vim.api.nvim_win_is_valid(win) then
      frozen_statuslines[win] = nil
    else
      for i = 1, state.count do
        vim.api.nvim_set_hl(0, "FzfFrozenStatusline" .. i, groups_hl(state.groups[i]))
      end
    end
  end

  if has_transparent_window() then
    local normal = resolve_hl("Normal")
    local opts = { bg = "NONE", ctermbg = "NONE" }
    if normal.fg then opts.fg = normal.fg end
    if normal.ctermfg then opts.ctermfg = normal.ctermfg end
    if normal.sp then opts.sp = normal.sp end
    vim.api.nvim_set_hl(0, "FzfTransparent", opts)
  end
end

local function ensure_refresh_autocmd()
  if refresh_autocmd then return end
  refresh_autocmd = vim.api.nvim_create_autocmd("ColorScheme", {
    callback = refresh_live_highlights,
  })
end

function M.freeze_statusline()
  local win = vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(win) or frozen_statuslines[win] then return nil end

  local original = vim.api.nvim_win_get_option(win, "statusline")
  local stl = original ~= "" and original or vim.o.statusline
  if stl == "" then return nil end

  local ok, res = pcall(vim.api.nvim_eval_statusline, stl, { winid = win, highlights = true })
  if not ok or type(res) ~= "table" then return nil end

  local text = res.str or ""
  local parts = {}
  local pos = 0
  local hl_count = 0
  local group_sets = {}

  for _, item in ipairs(res.highlights or {}) do
    local start = math.max(0, math.min(item.start or 0, #text))
    if start > pos then
      parts[#parts + 1] = escape_statusline(text:sub(pos + 1, start))
      pos = start
    end
    local groups = item.groups or (item.group and { item.group }) or {}
    if #groups > 0 then
      hl_count = hl_count + 1
      group_sets[hl_count] = groups
      parts[#parts + 1] = "%#" .. frozen_hl(groups, hl_count) .. "#"
    end
  end

  parts[#parts + 1] = escape_statusline(text:sub(pos + 1))
  if hl_count == 0 then return nil end

  vim.api.nvim_win_set_option(win, "statusline", table.concat(parts))
  frozen_statuslines[win] = { original = original, count = hl_count, groups = group_sets }
  ensure_refresh_autocmd()

  return function()
    local state = frozen_statuslines[win]
    if not state then return end
    frozen_statuslines[win] = nil
    for i = 1, state.count do
      pcall(vim.api.nvim_set_hl, 0, "FzfFrozenStatusline" .. i, {})
    end
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_option(win, "statusline", state.original)
    end
  end
end

function M.restore_statusline_on_close(win, restore)
  if not restore then return end
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = restore,
  })
end

function M.apply_transparency(win)
  if not config.options.ui.transparent then return end
  local normal = resolve_hl("Normal")
  local opts = { bg = "NONE", ctermbg = "NONE" }
  if normal.fg then opts.fg = normal.fg end
  if normal.ctermfg then opts.ctermfg = normal.ctermfg end
  if normal.sp then opts.sp = normal.sp end
  vim.api.nvim_set_hl(0, "FzfTransparent", opts)
  vim.api.nvim_win_set_option(win, "winhighlight", "Normal:FzfTransparent")
  ensure_refresh_autocmd()
end

function M.get_size()
  local opts = config.options.ui

  local width = math.floor(vim.o.columns * opts.width)

  local height = math.floor(vim.o.lines * opts.height)

  return width, height
end

function M.create_backdrop()
  local buf = vim.api.nvim_create_buf(false, true)

  local height = vim.o.lines - vim.o.cmdheight - (vim.o.laststatus > 0 and 1 or 0)

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = vim.o.columns,
    height = height,
    row = 0,
    col = 0,
    focusable = false,
    style = "minimal",
    zindex = 1,
    border = "none",
  })

  local normal = resolve_hl("Normal")
  vim.api.nvim_set_hl(0, "MyFzfBackdrop", {
    bg = config.options.ui.backdrop_bg or normal.bg,
  })

  vim.api.nvim_win_set_option(win, "winhighlight", "Normal:MyFzfBackdrop")

  vim.api.nvim_win_set_option(win, "winblend", config.options.ui.backdrop_blend or 70)

  return win
end

local function float_box(buf, win_opts)
  return vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = win_opts.width,
    height = win_opts.height,
    row = math.floor((vim.o.lines - win_opts.height) / 2),
    col = math.floor((vim.o.columns - win_opts.width) / 2),
    style = "minimal",
    border = "rounded",
    zindex = 100,
    title = win_opts.title,
    title_pos = "center",
  })
end

local function destroy(win, backdrop, buf)
  if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  if backdrop and vim.api.nvim_win_is_valid(backdrop) then vim.api.nvim_win_close(backdrop, true) end
  if buf and vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
end

function M.input(opts, on_submit)
  opts = opts or {}
  local title = opts.title or " Input "
  local default = opts.default or ""
  local message = opts.message or ""

  local width = math.max(24, math.min(math.floor(vim.o.columns * 0.5), 80))
  local height = message ~= "" and 2 or 1
  local buf = vim.api.nvim_create_buf(false, true)
  local backdrop = config.options.ui.backdrop and M.create_backdrop() or nil
  local win = float_box(buf, { width = width, height = height, title = " " .. title .. " " })
  local done = false

  local function close(cancel)
    if done then return end
    done = true
    local text = ""
    if not cancel and vim.api.nvim_buf_is_valid(buf) then
      text = vim.api.nvim_buf_get_lines(buf, height - 1, height, false)[1] or ""
    end
    destroy(win, backdrop, buf)
    vim.schedule(function()
      if text ~= "" and on_submit then
        on_submit(text)
      elseif opts.on_cancel then
        opts.on_cancel()
      end
    end)
  end

  local lines = message ~= "" and { message, default } or { default }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(win, { height, #default })
  vim.keymap.set({ "i", "n" }, "<CR>", function() vim.schedule(function() close(false) end) end,
    { buffer = buf, nowait = true })
  vim.keymap.set({ "i", "n" }, "<Esc>", function() vim.schedule(function() close(true) end) end,
    { buffer = buf, nowait = true })
  vim.keymap.set({ "i", "n" }, "<C-c>", function() vim.schedule(function() close(true) end) end,
    { buffer = buf, nowait = true })
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("i", true, false, true), "n", false)
    end
  end)
end

function M.confirm(msg, on_yes, on_cancel)
  msg = msg or "Are you sure?"
  local width = math.max(24, math.min(vim.fn.strdisplaywidth(msg) + 4, vim.o.columns - 4))
  local buf = vim.api.nvim_create_buf(false, true)
  local backdrop = config.options.ui.backdrop and M.create_backdrop() or nil
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { msg, "", "  [y] yes      [n] no  " })
  local win = float_box(buf, { width = width, height = 3, title = " Confirm " })
  vim.bo[buf].modifiable = false
  local done = false

  local function close(confirmed)
    if done then return end
    done = true
    destroy(win, backdrop, buf)
    vim.schedule(function()
      if confirmed then
        on_yes()
      elseif on_cancel then
        on_cancel()
      end
    end)
  end

  for _, key in ipairs({ "y", "Y", "<CR>" }) do
    vim.keymap.set("n", key, function() close(true) end, { buffer = buf, nowait = true })
  end
  for _, key in ipairs({ "n", "N", "q", "<Esc>", "<C-c>" }) do
    vim.keymap.set("n", key, function() close(false) end, { buffer = buf, nowait = true })
  end
end

function M.fzf_ui(cmd, on_select, win_opts)
  local backdrop

  if config.options.ui.backdrop then
    backdrop = M.create_backdrop()
  end

  local buf = vim.api.nvim_create_buf(false, true)

  local width, height, row, col

  if win_opts then
    width = win_opts.width or math.floor(vim.o.columns * config.options.ui.width)
    height = win_opts.height or math.floor(vim.o.lines * config.options.ui.height)
    row = win_opts.row or math.floor((vim.o.lines - height) / 2)
    col = win_opts.col or math.floor((vim.o.columns - width) / 2)
  else
    width, height = M.get_size()
    row = math.floor((vim.o.lines - height) / 2)
    col = math.floor((vim.o.columns - width) / 2)
  end

  local border = (win_opts and win_opts.border) or config.options.ui.border or "rounded"
  local title = (win_opts and win_opts.title) or config.options.ui.title or " FZF "
  local title_pos = (win_opts and win_opts.title_pos) or config.options.ui.title_pos or "center"
  local root = vim.fn.getcwd()

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
  local restore_statusline = M.freeze_statusline()
  M.restore_statusline_on_close(win, restore_statusline)
  M.apply_transparency(win)

  local winblend = config.options.ui.winblend or 0
  if winblend > 0 then
    vim.api.nvim_win_set_option(win, "winblend", winblend)
  end

  local temp = vim.fn.tempname()

  local full_cmd =
    string.format("cd %s && %s > %s", vim.fn.shellescape(root), cmd, vim.fn.shellescape(temp))

  vim.fn.termopen({ "sh", "-c", full_cmd }, {
    on_exit = function(_, code)
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end

        if backdrop and vim.api.nvim_win_is_valid(backdrop) then
          vim.api.nvim_win_close(backdrop, true)
        end

        local selection = nil

        if code == 0 and vim.fn.filereadable(temp) == 1 then
          local f = io.open(temp, "r")

          if f then
            selection = f:read("*all"):gsub("\n$", "")
            f:close()
          end
        end

        if vim.fn.filereadable(temp) == 1 then
          os.remove(temp)
        end

        if on_select then
          on_select(selection, root)
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
  end, {
    buffer = buf,
    nowait = true,
  })

  vim.cmd("startinsert!")
end

return M
