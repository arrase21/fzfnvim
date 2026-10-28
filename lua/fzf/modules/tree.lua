local helpers = require("fzf.helpers")
local picker = require("fzf.picker")
local ui = require("fzf.ui")

local M = {}

local function normalize(dir)
  local p = vim.fn.fnamemodify(dir, ":p")
  if p == nil or p == "" then p = vim.fn.getcwd() end
  p = p:gsub("/+$", "")
  if p == "" then p = "/" end
  return p
end

local function join(dir, name)
  if dir == "/" then return "/" .. name end
  return dir .. "/" .. name
end

local function read_entries(dir)
  local entries = {}
  local fd = vim.uv.fs_scandir(dir)
  if not fd then return entries end
  while true do
    local name, typ = vim.uv.fs_scandir_next(fd)
    if not name then break end
    local path = join(dir, name)
    local isdir = typ == "directory"
    if not isdir and typ == "link" then
      isdir = vim.fn.isdirectory(path) == 1
    end
    entries[#entries + 1] = { name = name, path = path, isdir = isdir }
  end
  return entries
end

local function build_lines(dir, st)
  local lines = {}

  if dir ~= "/" then
    local parent = vim.fn.fnamemodify(dir, ":h")
    local icon = helpers.dir_icon_text("../")
    local base = icon ~= "" and (icon .. " ../") or "../"
    local mark = helpers.git_mark_of(st, parent)
    if mark ~= " " then base = base .. " " .. mark end
    lines[#lines + 1] = base .. "\t" .. parent .. "\tparent"
  end

  local entries = read_entries(dir)
  table.sort(entries, function(a, b)
    if a.isdir ~= b.isdir then return a.isdir end
    return a.name:lower() < b.name:lower()
  end)

  for _, e in ipairs(entries) do
    local display
    if e.isdir then
      local icon = helpers.dir_icon_text(e.name)
      local base = icon ~= "" and (icon .. " " .. e.name .. "/") or (e.name .. "/")
      local mark = helpers.git_mark_of(st, e.path)
      if mark ~= " " then base = base .. " " .. mark end
      display = base
    else
      display = helpers.file_badge(e.path, e.name, helpers.git_status_of(st, e.path))
    end
    lines[#lines + 1] = display .. "\t" .. e.path .. "\t" .. (e.isdir and "dir" or "file")
  end

  return lines
end

local function build_preview()
  local file_cmd = ui.get_preview_cmd()
  local dir_cmd = "ls -A --color=always"
  if vim.fn.executable("eza") == 1 then
    dir_cmd = "eza --tree --level=2 --icons --color=always --group-directories-first"
  end
  return string.format("test -d {2} && %s {2} || %s {2}", dir_cmd, file_cmd)
end

local function reopen(dir)
  return function() M.open(dir) end
end

local function create(dir)
  ui.input({
    title = "New (end with / for a directory)",
    message = vim.fn.fnamemodify(dir, ":~"),
    on_cancel = reopen(dir),
  }, function(name)
    name = vim.trim(name)
    if name == "" then return M.open(dir) end

    local is_dir = name:sub(-1) == "/"
    if is_dir then name = name:sub(1, -2) end
    if name == "" then return M.open(dir) end

    local path = join(dir, name)
    if vim.fn.isdirectory(path) == 1 or vim.fn.filereadable(path) == 1 then
      helpers.notify("Already exists: " .. name, vim.log.levels.WARN)
      return M.open(dir)
    end

    local parent = vim.fn.fnamemodify(path, ":h")
    if vim.fn.isdirectory(parent) ~= 1 then
      vim.fn.mkdir(parent, "p")
    end

    if is_dir then
      vim.fn.mkdir(path, "p")
      return M.open(path)
    end

    vim.fn.writefile({}, path)
    M.open(dir)
  end)
end

local function rename(dir, path)
  if path == "" then return M.open(dir) end
  local base = vim.fn.fnamemodify(path, ":t")
  ui.input({
    title = "Rename",
    message = vim.fn.fnamemodify(dir, ":~"),
    default = base,
    on_cancel = reopen(dir),
  }, function(name)
    if name ~= base then
      if vim.fn.rename(path, join(dir, name)) ~= 0 then
        helpers.notify("Rename failed", vim.log.levels.ERROR)
      end
    end
    M.open(dir)
  end)
end

local function delete(dir, path)
  if path == "" then return M.open(dir) end
  local base = vim.fn.fnamemodify(path, ":t")
  ui.confirm("Delete " .. base .. "?", function()
    vim.fn.delete(path, "rf")
    M.open(dir)
  end, reopen(dir))
end

local function build_fzf_opts()
  local opts = "--expect=ctrl-d,ctrl-r,ctrl-x,ctrl-o"
  local clip = helpers.clipboard_pipe()
  if clip then
    opts = opts .. " --bind 'ctrl-y:execute-silent(printf %s {2} | " .. clip .. ")+bell'"
  end
  return opts
end

function M.open(dir)
  dir = normalize(dir or vim.fn.getcwd())
  if vim.fn.isdirectory(dir) ~= 1 then
    return helpers.notify("Not a directory: " .. dir, vim.log.levels.WARN)
  end
  local st = helpers.git_status(dir)
  local lines = build_lines(dir, st)

  picker.pick({
    source = lines,
    delimiter = "\t",
    with_nth = "1",
    preview = build_preview(),
    prompt_title = "  " .. dir .. "  ",
    fzf_opts = build_fzf_opts(),
    keep_window = function(selection)
      local nl = selection:find("\n", 1, true)
      local key = nl and selection:sub(1, nl - 1) or ""
      return key == "ctrl-d" or key == "ctrl-r" or key == "ctrl-x"
    end,
    on_select = function(selection)
      local nl = selection:find("\n", 1, true)
      local key, line
      if nl then
        key = selection:sub(1, nl - 1)
        line = selection:sub(nl + 1)
      else
        key, line = selection, ""
      end

      local parts = vim.split(line, "\t", { plain = true })
      local path = parts[2] or ""
      local kind = parts[3] or "file"

      if key ~= "" then
        if key == "ctrl-o" then
          return M.open(vim.fn.fnamemodify(dir, ":h"))
        elseif key == "ctrl-d" then
          return create(dir)
        elseif key == "ctrl-r" and kind ~= "parent" then
          return rename(dir, path)
        elseif key == "ctrl-x" and kind ~= "parent" then
          return delete(dir, path)
        end
        return M.open(dir)
      end

      if kind == "dir" or kind == "parent" then
        return M.open(path)
      end
      if path ~= "" then
        helpers.jump(path)
      end
    end,
  })
end

return M
