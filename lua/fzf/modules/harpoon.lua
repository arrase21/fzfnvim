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

  local st = helpers.git_status()
  local lines = {}
  for _, f in ipairs(files) do
    lines[#lines + 1] = helpers.badge_line(st, f)
  end

  picker.pick({
    source = lines,
    preview = require("fzf.ui").get_preview_cmd() .. " --line-range :500 {2}",
    title = " Harpoon ",
    prompt = "  ",
    delimiter = "\t",
    with_nth = "1",
    on_select = function(selection)
      local path = selection and selection:match("\t(.+)$")
      if path then vim.cmd("edit " .. vim.fn.fnameescape(path)) end
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

  local st = helpers.git_status()
  local lines = {}
  for _, f in ipairs(files) do
    lines[#lines + 1] = helpers.badge_line(st, f)
  end

  picker.pick({
    source = lines,
    header = "Delete file",
    title = " Harpoon Remove ",
    prompt = "  ",
    preview = require("fzf.ui").get_preview_cmd() .. " --line-range :500 {2}",
    delimiter = "\t",
    with_nth = "1",
    on_select = function(selection)
      local path = selection and selection:match("\t(.+)$")
      if not path then return end

      local new_files = {}

      for _, f in ipairs(files) do
        if f ~= path then
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
