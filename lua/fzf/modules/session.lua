local picker = require("fzf.picker")
local helpers = require("fzf.helpers")
local storage = require("fzf.storage")

local S = {}

S.session_save = function()
  vim.ui.input({
    prompt = "Session name: ",
  }, function(name)
    if not name or name == "" then
      return
    end

    vim.cmd("mksession! " .. vim.fn.fnameescape(storage.sessions_dir .. "/" .. name .. ".vim"))

    helpers.notify("Session saved: " .. name)
  end)
end

local function list_sessions()
  local ok, entries = pcall(vim.fn.readdir, storage.sessions_dir)
  if not ok or not entries then
    return {}
  end
  return vim.tbl_filter(function(f)
    return f ~= "." and f ~= ".."
  end, entries)
end

S.session_load = function()
  local sessions = list_sessions()

  if #sessions == 0 then
    return helpers.notify("No sessions found", vim.log.levels.WARN)
  end

  picker.pick({
    source = sessions,
    title = " Sessions ",
    on_select = function(selection)
      vim.cmd("source " .. vim.fn.fnameescape(storage.sessions_dir .. "/" .. selection))

      helpers.notify("Session loaded")
    end,
  })
end

S.session_delete = function()
  local sessions = list_sessions()

  if #sessions == 0 then
    return helpers.notify("No sessions found", vim.log.levels.WARN)
  end

  picker.pick({
    source = sessions,
    header = "Delete session",
    title = " Delete Session ",
    on_select = function(selection)
      os.remove(storage.sessions_dir .. "/" .. selection)

      helpers.notify("Session deleted")
    end,
  })
end

return S
