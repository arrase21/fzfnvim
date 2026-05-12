local core = require("fzf.config").options
local S = {}


S.session_save = function()
  vim.ui.input({ prompt = "Nombre de sesión: " }, function(name)
    if not name or name == "" then return end
    vim.cmd("mksession! " .. vim.fn.fnameescape(core.sessions_dir .. "/" .. name))
    core.notify("✅ Sesion saved: " .. name)
  end)
end

S.session_load = function()
  local cmd = string.format("ls %s | %s", vim.fn.shellescape(core.sessions_dir), core.fzf_base)
  core.fzf_ui(cmd, function(selection)
    vim.cmd("source " .. vim.fn.fnameescape(core.sessions_dir .. "/" .. selection))
    core.notify("🚀 Load session")
  end)
end

S.session_delete = function()
  local cmd = string.format("ls %s | %s --header 'Borrar sesión'", vim.fn.shellescape(core.sessions_dir), core.fzf_base)
  core.fzf_ui(cmd, function(selection)
    os.remove(core.sessions_dir .. "/" .. selection)
    core.notify("🗑️ Delete sesion")
  end)
end

return S
