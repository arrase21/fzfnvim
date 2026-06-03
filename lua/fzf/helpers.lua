local icons = {
  py = "", js = "", ts = "", jsx = "", tsx = "",
  rs = "", go = "", java = "", rb = "",
  c = "", cpp = "", h = "", hpp = "", hs = "",
  md = "", json = "", yaml = "", yml = "", toml = "",
  css = "", html = "", svelte = "", vue = "", astro = "",
  sh = "", bash = "", zsh = "",
  vim = "", lua = "",
  ["makefile"] = "", dockerfile = "",
  sql = "", graphql = "", xml = "謹",
  pdf = "", txt = "",
  jpg = "", jpeg = "", png = "", gif = "", svg = "",
  mp3 = "", mp4 = "",
  zip = "", tar = "", gz = "", rar = "", ["7z"] = "",
  lock = "", cfg = "", conf = "", ini = "", env = "",
}

local colors = {
  py = {255, 212, 59}, js = {247, 223, 30}, ts = {49, 120, 198},
  jsx = {97, 218, 251}, tsx = {97, 218, 251},
  rs = {239, 81, 9}, go = {0, 173, 216}, java = {227, 116, 52}, rb = {204, 52, 53},
  c = {85, 85, 255}, cpp = {0, 85, 170}, h = {85, 85, 255}, hpp = {0, 85, 170}, hs = {147, 61, 195},
  lua = {86, 156, 214},
  md = {66, 133, 244}, json = {190, 170, 80}, yaml = {225, 75, 65}, yml = {225, 75, 65}, toml = {156, 180, 60},
  css = {21, 114, 182}, html = {227, 76, 38}, svelte = {255, 62, 0}, vue = {65, 184, 131}, astro = {255, 90, 0},
  sh = {60, 179, 60}, bash = {60, 179, 60}, zsh = {60, 179, 60},
  vim = {0, 170, 0},
  ["makefile"] = {156, 180, 60}, dockerfile = {0, 105, 180},
  sql = {230, 100, 50}, txt = {170, 170, 170}, pdf = {230, 50, 50},
  jpg = {100, 180, 100}, jpeg = {100, 180, 100}, png = {100, 180, 100}, gif = {100, 180, 100}, svg = {255, 180, 50},
  zip = {180, 140, 100}, tar = {180, 140, 100}, gz = {180, 140, 100}, rar = {180, 140, 100}, ["7z"] = {180, 140, 100},
  lock = {200, 50, 50}, cfg = {156, 180, 60}, conf = {156, 180, 60}, ini = {156, 180, 60}, env = {255, 180, 50},
}

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

local function get_ext(filename)
  return filename:match("%.([^./]+)$")
end

local function get_basename(filename)
  return filename:match("([^/]+)$")
end

local function lookup(key)
  key = key and key:lower()
  local icon = key and icons[key]
  local color = key and colors[key]
  return icon, color
end

function M.file_icon(filename)
  local ext = get_ext(filename)
  local icon, color = lookup(ext)
  if icon then return icon, color end
  local base = get_basename(filename)
  icon, color = lookup(base)
  return icon or "", color
end

function M.add_file_icons(files)
  local result = {}
  for _, f in ipairs(files) do
    local icon, color = M.file_icon(f)
    if color then
      result[#result + 1] = M.ansi_color(color[1], color[2], color[3]) .. icon .. reset .. "\t" .. f
    else
      result[#result + 1] = icon .. "\t" .. f
    end
  end
  return result
end

function M.strip_icon(line)
  return line:gsub("^%S+%s+", "", 1)
end

function M.get_ansi(hl_name, fallback)
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

local kind_icons = {
  File = "", Module = "", Namespace = "", Package = "", Class = "",
  Method = "", Property = "", Field = "", Constructor = "", Enum = "",
  Interface = "", Function = "", Variable = "", Constant = "", String = "",
  Number = "", Boolean = "", Array = "", Object = "", Key = "",
  Null = "", EnumMember = "", Struct = "", Event = "", Operator = "",
  TypeParameter = "", Keyword = "", Snippet = "", Folder = "", Unit = "",
  Value = "", Reference = "", Text = "",
}

function M.kind_icon(kind)
  return kind_icons[kind] or ""
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

return M
