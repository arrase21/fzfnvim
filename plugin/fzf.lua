if vim.g.loaded_fzf then
  return
end

vim.g.loaded_fzf = 1

require("fzf").setup()

local fzf = require("fzf")

-- search
vim.api.nvim_create_user_command("FzfFiles", function()
  fzf.files()
end, {})

vim.api.nvim_create_user_command("FzfGrep", function()
  fzf.grep()
end, {})

vim.api.nvim_create_user_command("FzfBuffers", function()
  fzf.buffers()
end, {})

-- git
vim.api.nvim_create_user_command("FzfGitStatus", function()
  fzf.git_status()
end, {})

vim.api.nvim_create_user_command("FzfGitCommits", function()
  fzf.git_commits()
end, {})

-- harpoon
vim.api.nvim_create_user_command("FzfHarpoon", function()
  fzf.harpoon_open()
end, {})

-- session
vim.api.nvim_create_user_command("FzfSessionLoad", function()
  fzf.session_load()
end, {})

vim.api.nvim_create_user_command("FzfSessionSave", function()
  fzf.session_save()
end, {})
