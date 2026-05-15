local picker = require("fzf.picker")
local helpers = require("fzf.helpers")
local storage = require("fzf.storage")

local S = {}

local active_session = nil
local autosave_timer = nil
local autosave_group = nil

local function save_session_file(name)
  local save_session_options = vim.o.sessionoptions
  vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,terminal,localoptions"

  vim.cmd("mksession! " .. vim.fn.fnameescape(storage.sessions_dir .. "/" .. name .. ".vim"))

  vim.o.sessionoptions = save_session_options
end

local function debounced_autosave()
  if not active_session then
    return
  end

  if autosave_timer then
    autosave_timer:stop()
  end

  autosave_timer = vim.defer_fn(function()
    save_session_file(active_session)
  end, 500)
end

local function setup_autosave()
  if autosave_group then
    vim.api.nvim_del_augroup_by_id(autosave_group)
  end

  autosave_group = vim.api.nvim_create_augroup("fzf_session_autosave", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufDelete" }, {
    group = autosave_group,
    callback = debounced_autosave,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = autosave_group,
    callback = function()
      if active_session then
        save_session_file(active_session)
      end
    end,
  })
end

S.session_save = function()
  vim.ui.input({
    prompt = "Session name: ",
  }, function(name)
    if not name or name == "" then
      return
    end

    save_session_file(name)
    active_session = name
    setup_autosave()
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
      local name = selection:gsub("%.vim$", "")
      vim.cmd("source " .. vim.fn.fnameescape(storage.sessions_dir .. "/" .. selection))

      active_session = name
      setup_autosave()
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

      local name = selection:gsub("%.vim$", "")
      if active_session == name then
        active_session = nil
      end

      helpers.notify("Session deleted")
    end,
  })
end

return S
