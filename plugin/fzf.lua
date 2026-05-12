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

vim.api.nvim_create_user_command("FzfGrepW", function()
  fzf.grep_word()
end, {})

vim.api.nvim_create_user_command("FzfTodos", function()
  fzf.todos()
end, {})

vim.api.nvim_create_user_command("FzfBuffers", function()
  fzf.buffers()
end, {})

vim.api.nvim_create_user_command("FzfOldFiles", function()
  fzf.oldfiles()
end, {})

-- git
vim.api.nvim_create_user_command("FzfGitCommits", function()
  fzf.git_commits()
end, {})

vim.api.nvim_create_user_command("FzfGitBranches", function()
  fzf.git_branches()
end, {})

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

vim.api.nvim_create_user_command("FzfHarpoonRemove", function()
  fzf.harpoon_remove()
end, {})

vim.api.nvim_create_user_command("FzfHarpoonAdd", function()
  fzf.harpoon_add()
end, {})

-- session
vim.api.nvim_create_user_command("FzfSessionLoad", function()
  fzf.session_load()
end, {})

vim.api.nvim_create_user_command("FzfSessionSave", function()
  fzf.session_save()
end, {})

vim.api.nvim_create_user_command("FzfSessionDelete", function()
  fzf.session_delete()
end, {})

-- Lsp
vim.api.nvim_create_user_command("FzfLspSymbols", function()
  fzf.lsp_symbols()
end, {})

vim.api.nvim_create_user_command("FzfLspDiagnostics", function()
  fzf.lsp_diagnostics()
end, {})

vim.api.nvim_create_user_command("FzfLspReferences", function()
  fzf.lsp_references()
end, {})

vim.api.nvim_create_user_command("FzfLspDefinitions", function()
  fzf.lsp_definitions()
end, {})

vim.api.nvim_create_user_command("FzfLspImplementations", function()
  fzf.lsp_implementations()
end, {})

vim.api.nvim_create_user_command("FzfLspType", function()
  fzf.lsp_implementations()
end, {})

-- vim.api.nvim_create_user_command("FzfLspType", function()
--   fzf.lsp_implementations()
-- end, {})
