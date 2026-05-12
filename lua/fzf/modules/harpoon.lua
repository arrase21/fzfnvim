local core = require("fzf.core")

local H = {}

H.harpoon_jump = function(index)
  local files = (harpoon_load())[get_git_root()]
  if files and files[index] then vim.cmd("edit " .. vim.fn.fnameescape(files[index])) end
end

H.add = function()
  local key, file = core.get_git_root(), vim.fn.expand("%:p")
  if file == "" then return core.notify("No hay archivo abierto", vim.log.levels.WARN) end
  local data = core.harpoon_load()
  data[key] = data[key] or {}
  for _, f in ipairs(data[key]) do
    if f == file then return notify("Ya está en Harpoon", vim.log.levels.WARN) end
  end
  table.insert(data[key], file)
  core.harpoon_save(data)
  core.notify("🪝 Harpoon: " .. vim.fn.fnamemodify(file, ":~:."))
end

H.open = function()
  local key = core.get_git_root()
  local files = (core.harpoon_load())[key] or {}
  if #files == 0 then return core.notify("Harpoon vacío", vim.log.levels.WARN) end
  local list = table.concat(files, "\n")
  local preview = string.format("--preview '%s --line-range :500 {}' --preview-window=right:60%%", core.bat_preview)
  local cmd = string.format("echo %s | %s", vim.fn.shellescape(list), core.fzf_base .. preview)
  core.fzf_ui(cmd, function(selection) vim.cmd("edit " .. vim.fn.fnameescape(selection)) end)
end

H.remove = function()
  local key = core.get_git_root()
  local data = core.harpoon_load()
  local files = data[key] or {}
  if #files == 0 then return end
  local list = table.concat(files, "\n")
  local cmd = string.format("echo %s | %s --header 'Enter para eliminar'", vim.fn.shellescape(list), fzf_base)
  core.fzf_ui(cmd, function(selection)
    local new_files = {}
    for _, f in ipairs(files) do if f ~= selection then table.insert(new_files, f) end end
    data[key] = new_files
    core.harpoon_save(data)
    core.notify("🗑️ Eliminado de Harpoon")
  end)
end

H.jump = function(index)
  local files = (core.harpoon_load())[core.get_git_root()]
  if files and files[index] then vim.cmd("edit " .. vim.fn.fnameescape(files[index])) end
end

return H
