local picker = require("fzf.picker")
local config = require("fzf.config").options
local helpers = require("fzf.helpers")

local S = {}

local function preview()
  return require("fzf.ui").get_preview_cmd() .. " --line-range :500 {}"
end

local function rg_preview()
  return require("fzf.ui").get_preview_cmd() .. " --highlight-line {2} {1}"
end

local function open_rg_selection(selection, ctx)
  local file, line, col = selection:match("^([^:]+):(%d+):(%d+):")

  if file then
    helpers.jump(helpers.join_path(ctx.root, file), line, col)
  end
end

S.files = function()
  picker.pick({
    source = "rg --files --hidden -g '!.git'",
    preview = preview(),
    fzf_opts = helpers.build_fzf_opts(config.files.fzf_opts),
    on_select = function(selection, ctx)
      vim.cmd("edit " .. vim.fn.fnameescape(helpers.join_path(ctx.root, selection)))
    end,
  })
end

S.grep = function()
  picker.pick({
    source = "rg --column --line-number " .. "--no-heading --color=always --smart-case ''",
    preview = rg_preview(),
    delimiter = ":",
    fzf_opts = helpers.build_fzf_opts(config.grep.fzf_opts),
    on_select = open_rg_selection,
  })
end

S.grep_word = function()
  local word = vim.fn.expand("<cword>")

  picker.pick({
    source = string.format(
      "rg --column --line-number " .. "--no-heading --color=always --smart-case %s",
      vim.fn.shellescape(word)
    ),
    preview = rg_preview(),
    delimiter = ":",
    fzf_opts = helpers.build_fzf_opts(config.grep.fzf_opts),
    on_select = open_rg_selection,
  })
end

S.buffers = function()
  local buffers = vim.fn.getbufinfo({ buflisted = 1 })

  table.sort(buffers, function(a, b)
    return a.lastused > b.lastused
  end)

  local lines = {}

  for _, buf in ipairs(buffers) do
    if buf.name ~= "" then
      table.insert(lines, buf.name)
    end
  end

  if #lines == 0 then
    return helpers.notify("No buffers")
  end

  picker.pick({
    source = lines,
    preview = preview(),
    on_select = function(selection)
      vim.cmd("edit " .. vim.fn.fnameescape(selection))
    end,
  })
end

S.todos = function()
  local patterns = "TODO|FIXME|HACK|NOTE|BUG|WARN"

  picker.pick({
    source = string.format(
      "rg --column --line-number " .. "--no-heading --color=always --smart-case -e '%s'",
      patterns
    ),
    preview = rg_preview(),
    delimiter = ":",
    fzf_opts = helpers.build_fzf_opts(config.todos.fzf_opts),
    on_select = open_rg_selection,
  })
end

S.oldfiles = function()
  local files = vim.v.oldfiles

  if not files or #files == 0 then
    return helpers.notify("No old files")
  end

  local lines = {}

  for _, file in ipairs(files) do
    if vim.fn.filereadable(file) == 1 then
      table.insert(lines, file)
    end
  end

  picker.pick({
    source = lines,
    preview = preview(),
    on_select = function(selection)
      if selection and selection ~= "" then
        vim.cmd("edit " .. vim.fn.fnameescape(selection))
      end
    end,
  })
end

return S
