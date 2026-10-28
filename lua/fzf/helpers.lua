local M = {}

M.reset = "\27[0m"
M.bold = "\27[1m"
local reset = M.reset
local bold = M.bold

function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

function M.jump(filepath, line, col)
  vim.cmd("hide edit " .. vim.fn.fnameescape(filepath))
  local l = tonumber(line) or 1
  local c = tonumber(col) or 1
  pcall(vim.api.nvim_win_set_cursor, 0, { l, c - 1 })
  vim.cmd("normal! zz")
end

function M.build_fzf_opts(opts)
  local parts = {}
  for key, value in pairs(opts or {}) do
    if value == "" then
      table.insert(parts, key)
    else
      table.insert(parts, key .. "=" .. value)
    end
  end
  return table.concat(parts, " ")
end

function M.join_path(root, file)
  if not root or not file then return root or file or "" end
  root = root:gsub("/$", "")
  file = file:gsub("^/", "")
  return root .. "/" .. file
end

function M.ansi_color(r, g, b)
  return string.format("\27[38;2;%d;%d;%dm", r, g, b)
end

local icons_mod

local function get_icons()
  if icons_mod then return icons_mod end
  local mini = rawget(_G, "MiniIcons")
  if mini then
    icons_mod = mini
    return icons_mod
  end
  local ok, mod = pcall(require, "mini.icons")
  if not ok then return nil end
  if not pcall(mod.get, "file", "test") and not pcall(mod.setup) then
    return nil
  end
  icons_mod = mod
  return icons_mod
end

function M.file_icon(filename)
  local icons = get_icons()
  if not icons or not filename or filename == "" then return "", nil end
  local base = filename:match("([^/]+)$") or filename
  local ok, icon, hl = pcall(icons.get, "file", base)
  if not ok or type(icon) ~= "string" or icon == "" then
    ok, icon, hl = pcall(icons.get, "file", filename)
    if not ok or type(icon) ~= "string" or icon == "" then return "", nil end
  end
  return icon, hl
end

function M.icon_text(filename)
  local icon, hl = M.file_icon(filename)
  if icon == "" then return "" end
  return M.get_ansi(hl) .. icon .. reset
end

function M.dir_icon(name)
  local icons = get_icons()
  if not icons or not name or name == "" then return "", nil end
  local base = name:match("([^/]+)/?$") or name
  local ok, icon, hl = pcall(icons.get, "directory", base)
  if not ok or type(icon) ~= "string" or icon == "" then return "", nil end
  return icon, hl
end

function M.dir_icon_text(name)
  local icon, hl = M.dir_icon(name)
  if icon == "" then return "" end
  return M.get_ansi(hl) .. icon .. reset
end

local function git_toplevel(path)
  local ok, res = pcall(function()
    return vim.system({ "git", "-C", path, "rev-parse", "--show-toplevel" }):wait()
  end)
  if not ok or res.code ~= 0 then return nil end
  local top = (res.stdout or ""):gsub("%s+$", "")
  if top == "" then return nil end
  return vim.uv.fs_realpath(top) or top
end

function M.git_status(path)
  local top = git_toplevel(path or vim.fn.getcwd())
  local st = { top = top, files = {}, list = {} }
  if not top then return st end

  local ok, res = pcall(function()
    return vim.system({ "git", "-C", top, "status", "--porcelain", "-z" }):wait()
  end)
  if not ok or res.code ~= 0 then return st end

  local entries = vim.split(res.stdout or "", "\0")
  local i = 1
  while i <= #entries do
    local entry = entries[i]
    if #entry >= 3 then
      local xy = entry:sub(1, 2)
      local rel = entry:sub(4)
      if rel ~= "" then
        local abs = top .. "/" .. rel
        st.files[abs] = xy
        st.list[#st.list + 1] = { abs = abs, rel = rel, xy = xy }
        if xy:sub(1, 1):match("[RC]") then i = i + 1 end
      end
    end
    i = i + 1
  end
  return st
end

function M.git_status_of(st, path)
  if not st or not st.top or not path or path == "" then return nil end
  local xy = st.files[path]
  if xy then return xy end
  local real = vim.uv.fs_realpath(path)
  return real and st.files[real] or nil
end

local git_icons = {
  added = vim.fn.nr2char(0xF0FE),
  modified = vim.fn.nr2char(0xF14B),
  renamed = vim.fn.nr2char(0x2794),
  deleted = vim.fn.nr2char(0xF146),
  unstaged = vim.fn.nr2char(0xF467),
  copied = vim.fn.nr2char(0xF0C5),
  conflict = vim.fn.nr2char(0x26A0),
  untracked = vim.fn.nr2char(0xF128),
  hidden = vim.fn.nr2char(0xF165D),
}

local mark_colors = {
  unstaged = { "DiagnosticError", { 255, 85, 85 } },
  staged = { "DiagnosticOk", { 60, 179, 60 } },
  untracked = { "DiagnosticWarn", { 255, 200, 50 } },
  hidden = { nil, { 128, 128, 128 } },
}

local function git_category(xy)
  if xy == "??" then return "untracked" end
  if xy == "!!" then return "hidden" end
  local x, y = xy:sub(1, 1), xy:sub(2, 2)
  if x == "U" or y == "U" or (x == "A" and y == "A") or (x == "D" and y == "D") then
    return "conflict"
  end
  if y ~= " " then return "unstaged" end
  if x == "A" then return "added" end
  if x == "M" then return "modified" end
  if x == "D" then return "deleted" end
  if x == "R" then return "renamed" end
  if x == "C" then return "copied" end
  return nil
end

local function git_mark_category(category)
  if not category then return " " end
  local color
  if category == "untracked" then
    color = mark_colors.untracked
  elseif category == "unstaged" or category == "deleted" or category == "conflict" then
    color = mark_colors.unstaged
  elseif category == "hidden" then
    color = mark_colors.hidden
  else
    color = mark_colors.staged
  end
  return M.get_ansi(color[1], color[2]) .. git_icons[category] .. reset
end

function M.git_mark(xy)
  if not xy or xy == "" then return " " end
  return git_mark_category(git_category(xy))
end

local git_mark_priority = {
  conflict = 1,
  deleted = 2,
  unstaged = 3,
  modified = 4,
  added = 5,
  renamed = 6,
  copied = 7,
  untracked = 8,
  hidden = 9,
}

function M.git_mark_of(st, dirpath)
  if not st or not st.top or not dirpath or dirpath == "" then return " " end
  local prefix = dirpath .. "/"
  local best, best_rank
  for _, item in ipairs(st.list) do
    local abs = item.abs
    if abs == prefix or abs:sub(1, #prefix) == prefix then
      local category = git_category(item.xy)
      local rank = category and git_mark_priority[category]
      if rank and (not best_rank or rank < best_rank) then
        best, best_rank = category, rank
      end
    end
  end
  return git_mark_category(best)
end

function M.file_badge(path, shown, xy)
  local icon = M.icon_text(path)
  local label = shown or path
  local mark = M.git_mark(xy)
  local has_mark = mark ~= "" and mark ~= " "
  if icon == "" then
    if has_mark then return label .. " " .. mark end
    return label
  end
  if has_mark then
    return icon .. " " .. label .. " " .. mark
  end
  return icon .. " " .. label
end

function M.badge_line(st, path, shown)
  local label = shown or path
  return M.file_badge(path, label, M.git_status_of(st, path)) .. "\t" .. label
end

function M.add_file_icons(files)
  local result = {}
  for _, f in ipairs(files) do
    local icon = M.icon_text(f)
    if icon ~= "" then
      result[#result + 1] = icon .. "\t" .. f
    else
      result[#result + 1] = f
    end
  end
  return result
end

function M.strip_icon(line)
  return (line:gsub("^[^\t]*\t", "", 1))
end

function M.get_ansi(hl_name, fallback)
  if not hl_name then
    if fallback then return M.ansi_color(fallback[1], fallback[2], fallback[3]) end
    return ""
  end
  local hl = vim.api.nvim_get_hl(0, { name = hl_name, link = true })
  local ansi
  if hl and hl.fg then
    ansi = string.format(
      "\27[38;2;%d;%d;%dm",
      bit.band(bit.rshift(hl.fg, 16), 0xFF),
      bit.band(bit.rshift(hl.fg, 8), 0xFF),
      bit.band(hl.fg, 0xFF)
    )
  elseif fallback then
    ansi = M.ansi_color(fallback[1], fallback[2], fallback[3])
  else
    ansi = ""
  end
  return ansi
end

function M.kind_icon(kind)
  local icons = get_icons()
  if not icons or not kind then return "" end
  local ok, icon = pcall(icons.get, "lsp", kind)
  if ok and type(icon) == "string" then return icon end
  return ""
end

local severity_hl = {
  [1] = { "DiagnosticError", { 255, 85, 85 } },
  [2] = { "DiagnosticWarn", { 255, 200, 50 } },
  [3] = { "DiagnosticInfo", { 85, 185, 255 } },
  [4] = { "DiagnosticHint", { 170, 170, 170 } },
}

function M.severity_ansi(severity)
  local sev = severity_hl[severity] or severity_hl[4]
  return M.get_ansi(sev[1], sev[2])
end

local severity_icons = {
  [1] = " ", [2] = " ", [3] = "󰌵 ", [4] = " ",
}

function M.severity_icon(severity)
  return severity_icons[severity] or " ? "
end

function M.escape_shell(str)
  return str:gsub("'", "'\\''")
end

function M.clipboard_pipe()
  if vim.fn.executable("wl-copy") == 1 then return "wl-copy" end
  if vim.fn.executable("xclip") == 1 then return "xclip -selection clipboard" end
  if vim.fn.executable("xsel") == 1 then return "xsel --clipboard --input" end
  if vim.fn.executable("pbcopy") == 1 then return "pbcopy" end
  return nil
end

return M
