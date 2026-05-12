local picker = require("fzf.picker")
local helpers = require("fzf.helpers")
local storage = require("fzf.storage")

local H = {}

H.add = function()
  local key = storage.get_git_root()

  local file = vim.fn.expand("%:p")

  if file == "" then
    return helpers.notify("not opened file", vim.log.levels.WARN)
  end

  local data = storage.harpoon_load()

  data[key] = data[key] or {}

  for _, f in ipairs(data[key]) do
    if f == file then
      return helpers.notify("You are in Harpoon", vim.log.levels.WARN)
    end
  end

  table.insert(data[key], file)

  storage.harpoon_save(data)

  helpers.notify("Harpoon: " .. vim.fn.fnamemodify(file, ":~:."))
end

H.open = function()
  local key = storage.get_git_root()

  local files = (storage.harpoon_load())[key] or {}

  if #files == 0 then
    return helpers.notify("Harpoon is empty", vim.log.levels.WARN)
  end

  picker.pick({
    source = files,
    preview = require("fzf.ui").get_preview_cmd() .. " --line-range :500 {}",
    on_select = function(selection)
      vim.cmd("edit " .. vim.fn.fnameescape(selection))
    end,
  })
end

H.remove = function()
  local key = storage.get_git_root()

  local data = storage.harpoon_load()

  local files = data[key] or {}

  if #files == 0 then
    return
  end

  picker.pick({
    source = files,
    header = "Delete file",
    on_select = function(selection)
      local new_files = {}

      for _, f in ipairs(files) do
        if f ~= selection then
          table.insert(new_files, f)
        end
      end

      data[key] = new_files

      storage.harpoon_save(data)

      helpers.notify("Removed from Harpoon")
    end,
  })
end

H.jump = function(index)
  local files = (storage.harpoon_load())[storage.get_git_root()]

  if files and files[index] then
    vim.cmd("edit " .. vim.fn.fnameescape(files[index]))
  end
end

return H
