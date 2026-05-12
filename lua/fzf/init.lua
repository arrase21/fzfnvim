local M = {}

local core = require("fzf.core")

M.search = require("fzf.modules.search")
M.git = require("fzf.modules.git")
M.lsp = require("fzf.modules.lsp")
M.harpoon = require("fzf.modules.harpoon")
M.session = require("fzf.modules.session")

-- search
M.files = M.search.files
M.grep = M.search.grep
M.grep_word = M.search.grep_word
M.buffers = M.search.buffers
M.todos = M.search.todos

-- git
M.git_files = M.git.files
M.git_status = M.git.status
M.git_commits = M.git.commits
M.git_branches = M.git.branches
M.git_stash = M.git.stash
M.git_diff = M.git.diff

-- lsp
M.lsp_symbols = M.lsp.symbols
M.lsp_diagnostics = M.lsp.diagnostics
M.lsp_references = M.lsp.references
M.lsp_definitions = M.lsp.definitions
M.lsp_implementations = M.lsp.implementations
M.lsp_type_definitions = M.lsp.type_definition

-- harpoon
M.harpoon_add = M.harpoon.add
M.harpoon_remove = M.harpoon.remove
M.harpoon_open = M.harpoon.open

-- sessions
M.session_save = M.session.session_save
M.session_load = M.session.session_load
M.session_delete = M.session.session_delete

function M.setup(opts)
  core.setup(opts)

  local cfg = require("fzf.config").options

  if cfg.ui_select then
    require("fzf.ui_select").setup()
  end
end

return M
