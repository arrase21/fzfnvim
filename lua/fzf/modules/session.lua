local ui = require("fzf.ui")
local helpers = require("fzf.helpers")
local storage = require("fzf.storage")

local S = {}

S.session_save = function()
  vim.ui.input({
    prompt = "Session name: "
  }, function(name)
    if not name or name == "" then
      return
    end

    vim.cmd(
      "mksession! " ..
      vim.fn.fnameescape(
        storage.sessions_dir .. "/" .. name
      )
    )

    helpers.notify(
      "✅ Session saved: " .. name
    )
  end)
end

S.session_load = function()
  local cmd = string.format(
    "ls %s | %s",
    vim.fn.shellescape(storage.sessions_dir),
    ui.get_fzf_base()
  )

  ui.fzf_ui(cmd, function(selection)
    vim.cmd(
      "source " ..
      vim.fn.fnameescape(
        storage.sessions_dir .. "/" .. selection
      )
    )

    helpers.notify(
      "🚀 Session loaded"
    )
  end)
end

S.session_delete = function()
  local cmd = string.format(
    "ls %s | %s --header 'Delete session'",
    vim.fn.shellescape(storage.sessions_dir),
    ui.get_fzf_base()
  )

  ui.fzf_ui(cmd, function(selection)
    os.remove(
      storage.sessions_dir .. "/" .. selection
    )

    helpers.notify(
      "🗑️ Session deleted"
    )
  end)
end

return S
