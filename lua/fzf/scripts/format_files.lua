local function passthrough()
  for line in io.lines() do
    if line ~= "" then
      io.write(line, "\t", line, "\n")
    end
  end
end

local rtp = vim.env.FZF_MINI_RTP
if rtp and #rtp > 0 then
  vim.opt.rtp:append(rtp)
end

local ok, Micons = pcall(require, "mini.icons")
if not ok then
  passthrough()
  return
end

pcall(Micons.setup)

local colors = {}
local colors_path = vim.env.FZF_ICON_COLORS
if colors_path and #colors_path > 0 then
  local loader = loadfile(colors_path)
  if loader then
    local ok_colors, result = pcall(loader)
    if ok_colors and type(result) == "table" then
      colors = result
    end
  end
end

local reset = "\27[0m"
local function ansi(hl)
  if not hl then return "" end
  return colors[hl] or ""
end

local function styled(icon, hl)
  if type(icon) ~= "string" or icon == "" then return "" end
  local color = ansi(hl)
  if color == "" then return icon end
  return color .. icon .. reset
end

local ok_icon, default_icon, default_hl = pcall(Micons.get, "default", "file")
if not ok_icon or type(default_icon) ~= "string" then
  default_icon = ""
else
  default_icon = styled(default_icon, default_hl)
end

local special = {}
local ok_list, names = pcall(Micons.list, "file")
if ok_list then
  for _, name in ipairs(names) do
    special[name] = true
  end
end
for name in pairs(Micons.config.file or {}) do
  special[name] = true
end
for _, name in ipairs({
  "Makefile",
  "makefile",
  "GNUmakefile",
  "Dockerfile",
  "Containerfile",
  "Justfile",
  "justfile",
  "Procfile",
  "Brewfile",
  "Gemfile",
  "Rakefile",
  "Vagrantfile",
  "Jenkinsfile",
  "LICENSE",
  "LICENCE",
  "COPYING",
  "README",
  "CHANGELOG",
  "AUTHORS",
  "CONTRIBUTING",
}) do
  special[name] = true
end

local explicit_ext = {}
local ok_ext, exts = pcall(Micons.list, "extension")
if ok_ext then
  for _, ext in ipairs(exts) do
    explicit_ext[ext] = true
  end
end

local function plausible_ext(ext)
  if explicit_ext[ext] then return true end
  if #ext < 1 or #ext > 10 then return false end
  return ext:match("^[a-z][a-z0-9_+%-]*$") ~= nil
end

local cache_ext, cache_name = {}, {}
local function lookup(category, name)
  local ok_get, icon, hl = pcall(Micons.get, category, name)
  if not ok_get or type(icon) ~= "string" or icon == "" then
    return default_icon
  end
  local color = ansi(hl)
  if color == "" then
    return icon
  end
  return color .. icon .. reset
end

local function icon_for(base)
  if special[base] then
    local cached = cache_name[base]
    if cached then return cached end
    cached = lookup("file", base)
    cache_name[base] = cached
    return cached
  end

  if not base:find("%.", 2) then
    return default_icon
  end

  local ext = base:match("%.([^%.]+)$")
  if not ext then
    return default_icon
  end
  ext = ext:lower()
  if not plausible_ext(ext) then
    return default_icon
  end

  local cached = cache_ext[ext]
  if cached then return cached end
  cached = lookup("extension", ext)
  cache_ext[ext] = cached
  return cached
end

local marks = {}
local marks_path = vim.env.FZF_MARKS
if marks_path and #marks_path > 0 then
  for line in io.lines(marks_path) do
    local path, mark = line:match("^(.-)\t(.*)$")
    if path then marks[path] = mark end
  end
end

local root = vim.env.FZF_ROOT or vim.fn.getcwd()
root = root:gsub("/$", "")

pcall(io.stdout.setvbuf, io.stdout, "full", 65536)

for line in io.lines() do
  if line ~= "" then
    local base = line:match("([^/]+)$") or line
    local icon = icon_for(base)
    local display = icon ~= "" and (icon .. " " .. line) or line
    local mark = marks[root .. "/" .. line]
    if mark and mark ~= "" then
      display = display .. " " .. mark
    end
    io.write(display, "\t", line, "\n")
  end
end

io.stdout:flush()
