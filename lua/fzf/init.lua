local M = {}

local config = require("fzf.config")
local picker = require("fzf.picker")

M.pick = picker.pick
M.resume = picker.resume

M.search = require("fzf.modules.search")
M.git = require("fzf.modules.git")
M.lsp = require("fzf.modules.lsp")
M.harpoon = require("fzf.modules.harpoon")
M.session = require("fzf.modules.session")

-- search
M.files = M.search.files
M.grep = M.search.grep
M.grep_word = M.search.grep_word
M.live_grep = M.search.live_grep
M.buffers = M.search.buffers
M.todos = M.search.todos
M.oldfiles = M.search.oldfiles
M.help_tags = M.search.help_tags
M.man_pages = M.search.man_pages
M.keymaps = M.search.keymaps
M.commands = M.search.commands
M.highlights = M.search.highlights
M.marks = M.search.marks
M.registers = M.search.registers
M.changes = M.search.changes
M.spell_suggest = M.search.spell_suggest
M.colorschemes = M.search.colorschemes
M.quickfix = M.search.quickfix
M.loclist = M.search.loclist
M.search_history = M.search.search_history

-- git
M.git_files = M.git.files
M.git_status = M.git.status
M.git_commits = M.git.commits
M.git_branches = M.git.branches
M.git_stash = M.git.stash
M.git_diff = M.git.diff
M.git_diff_staged = M.git.diff_staged

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
  config.setup(opts)

  local cfg = require("fzf.config").options

  if cfg.ui_select then
    require("fzf.ui_select").setup()
  elseif _G.__fzf_original_ui_select then
    vim.ui.select = _G.__fzf_original_ui_select
    _G.__fzf_original_ui_select = nil
  end
end

return M
