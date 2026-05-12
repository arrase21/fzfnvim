local M = {}

local core = require("fzf.core")

M.search = require("fzf.modules.search")

M.git = require("fzf.modules.git")

M.lsp = require("fzf.modules.lsp")

M.harpoon = require("fzf.modules.harpoon")

M.session = require("fzf.modules.session")

-- public shortcuts
M.files = M.search.files
M.grep = M.search.grep
M.buffers = M.search.buffers
M.todos = M.search.todos

function M.setup(opts)
  core.setup(opts)

  local cfg =
      require("myfzf.config").options

  -- if cfg.keymaps then
  --   require("myfzf.keymaps").setup()
  -- end

  if cfg.ui_select then
    require("myfzf.ui_select").setup()
  end
end

return M

-- local M           = {}
--
-- -- Cargar submódulos
-- local core        = require('myfzf.core')
-- local search      = require('myfzf.modules.search')
-- local lsp         = require('myfzf.modules.lsp')
-- local git         = require('myfzf.modules.git')
-- local harpoon     = require('myfzf.modules.harpoon')
-- local session     = require("myfzf.modules.session")
--
-- -- Exponer funciones al comando M
-- M.files           = search.files
-- M.grep            = search.grep
-- M.buffers         = search.buffers
-- M.todos           = search.todos
-- M.grep_word       = search.grep_word
-- -- Lsp
-- M.symbols         = lsp.symbols
-- M.diag            = lsp.diagnostics
-- M.references      = lsp.references
-- M.definitions     = lsp.definitions
-- M.implementations = lsp.implementations
-- M.type_definition = lsp.type_definition
-- -- Git
-- M.gitfiles        = git.files
-- M.branches        = git.branches
-- M.status          = git.status
-- M.commits         = git.commits
-- M.stash           = git.stash
-- M.diff            = git.diff
-- --harpoon
-- M.add             = harpoon.add
-- M.remove          = harpoon.remove
-- M.open            = harpoon.open
-- M.save            = session.session_save
-- M.load            = session.session_load
-- M.delete          = session.session_delete
--
-- local k           = vim.keymap.set
-- k('n', '<leader>zf', M.files, { desc = 'FZF: Files' })
-- k('n', '<leader>zg', M.grep, { desc = 'FZF: Grep' })
-- k('n', '<leader>zw', M.grep_word, { desc = 'FZF: Word cursor' })
--
-- k('n', '<leader>zb', M.buffers, { desc = 'FZF: Buffers' })
-- k('n', '<leader>zt', M.todos, { desc = 'FZF: TODOs' })
-- -- lsp
-- k('n', '<leader>zs', M.symbols, { desc = 'FZF: LSP Symbols' })
-- k('n', '<leader>ze', M.diag, { desc = 'FZF: LSP Diag' })
-- k('n', '<leader>zr', M.references, { desc = 'FZF LSP: Referencias' })
-- k('n', '<leader>zd', M.definitions, { desc = 'FZF LSP: Definición' })
-- k('n', '<leader>zi', M.implementations, { desc = 'FZF LSP: Implementaciones' })
-- k('n', '<leader>zy', M.type_definition, { desc = 'FZF LSP: Tipo' })
-- --Git
-- k('n', '<leader>zB', M.branches, { desc = 'FZF Git: Branches' })
-- k('n', '<leader>zl', M.commits, { desc = 'FZF Git: Commits' })
-- k('n', '<leader>zs', M.status, { desc = 'FZF Git: Status' })
-- k('n', '<leader>zS', M.stash, { desc = 'FZF Git: Stash' })
-- k('n', '<leader>zD', M.diff, { desc = 'FZF Git: Diff' })
--
-- k('n', '<leader>ha', M.add, { desc = 'Harpoon: Add' })
-- k('n', '<leader>ho', M.open, { desc = 'Harpoon: Open' })
-- k('n', '<leader>hd', M.remove, { desc = 'Harpoon: Delete archivo' })
--
-- k('n', '<leader>ss', M.save, { desc = 'Session Save' })
-- k('n', '<leader>sl', M.load, { desc = 'Session Load' })
-- k('n', '<leader>sx', M.delete, { desc = 'Session_delete' })
--
-- for i = 1, 9 do
--   vim.keymap.set('n', '<leader>h' .. i, function() core.harpoon_jump(i) end,
--     { desc = 'Harpoon: Saltar a archivo ' .. i })
-- end
--
-- vim.ui.select = function(items, opts, on_choice)
--   local lines = {}
--   local format = opts.format_item or tostring
--   for _, item in ipairs(items) do table.insert(lines, format(item)) end
--
--   local cmd = string.format("echo %s | %s --prompt '%s> '",
--     vim.fn.shellescape(table.concat(lines, "\n")), core.fzf_base, opts.prompt or "Select")
--
--   core.fzf_ui(cmd, function(selection)
--     for i, item in ipairs(items) do
--       if format(item) == selection then
--         on_choice(item, i)
--         return
--       end
--     end
--   end)
-- end
--
--
-- return M
