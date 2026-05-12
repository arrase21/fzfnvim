local config = require("fzf.config").options
local ui = require("fzf.ui")
local helpers = require("fzf.helpers")

local S = {}

local Preview = function()
  return string.format(
    "--preview '%s --line-range :500 {}' " ..
    "--preview-window=right:60%%",
    ui.get_preview_cmd()
  )
end

local Join_path = function(root, file)
  root = root:gsub("/$", "")
  file = file:gsub("^/", "")

  return root .. "/" .. file
end

local function open_rg_selection(selection, root)
  local file, line, col =
      selection:match(
        "^([^:]+):(%d+):(%d+):"
      )

  if file then
    helpers.jump(
      Join_path(root, file),
      line,
      col
    )
  end
end

-- files
S.files = function()
  local fzf_opts =
      helpers.build_fzf_opts(
        config.files.fzf_opts
      )

  local cmd =
      "rg --files --hidden -g '!.git' | " ..
      ui.get_fzf_base() ..
      " " ..
      fzf_opts ..
      " " ..
      Preview()

  ui.fzf_ui(cmd, function(selection, root)
    vim.cmd(
      "edit " ..
      vim.fn.fnameescape(
        Join_path(root, selection)
      )
    )
  end)
end

-- grep
S.grep = function()
  local preview = string.format(
    "--preview '%s --highlight-line {2} {1}' " ..
    "--preview-window=right:60%%",
    ui.get_preview_cmd()
  )

  local fzf_opts =
      helpers.build_fzf_opts(
        config.grep.fzf_opts
      )

  local cmd =
      "rg " ..
      "--column " ..
      "--line-number " ..
      "--no-heading " ..
      "--color=always " ..
      "--smart-case '' | " ..
      ui.get_fzf_base() ..
      " " ..
      fzf_opts ..
      " --delimiter ':' " ..
      preview

  ui.fzf_ui(cmd, open_rg_selection)
end

-- grep current word
S.grep_word = function()
  local word =
      vim.fn.expand("<cword>")

  local preview = string.format(
    "--preview '%s --highlight-line {2} {1}' " ..
    "--preview-window=right:60%%",
    ui.get_preview_cmd()
  )

  local fzf_opts =
      helpers.build_fzf_opts(
        config.grep.fzf_opts
      )

  local cmd = string.format(
        "rg " ..
        "--column " ..
        "--line-number " ..
        "--no-heading " ..
        "--color=always " ..
        "--smart-case %s | ",
        vim.fn.shellescape(word)
      ) ..
      ui.get_fzf_base() ..
      " " ..
      fzf_opts ..
      " --delimiter ':' " ..
      preview

  ui.fzf_ui(cmd, open_rg_selection)
end

-- buffers
S.buffers = function()
  local buffers =
      vim.fn.getbufinfo({
        buflisted = 1
      })

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

  local fzf_opts =
      helpers.build_fzf_opts(
        config.buffers.fzf_opts
      )

  local cmd = string.format(
    "echo %s | %s %s %s",
    vim.fn.shellescape(
      table.concat(lines, "\n")
    ),
    ui.get_fzf_base(),
    fzf_opts,
    Preview()
  )

  ui.fzf_ui(cmd, function(selection)
    vim.cmd(
      "edit " ..
      vim.fn.fnameescape(selection)
    )
  end)
end

-- todos
S.todos = function()
  local patterns =
  "TODO|FIXME|HACK|NOTE|BUG|WARN"

  local preview = string.format(
    "--preview '%s --highlight-line {2} {1}' " ..
    "--preview-window=right:60%%",
    ui.get_preview_cmd()
  )

  local fzf_opts =
      helpers.build_fzf_opts(
        config.todos.fzf_opts
      )

  local cmd = string.format(
        "rg " ..
        "--column " ..
        "--line-number " ..
        "--no-heading " ..
        "--color=always " ..
        "--smart-case " ..
        "-e '%s' | ",
        patterns
      ) ..
      ui.get_fzf_base() ..
      " " ..
      fzf_opts ..
      " --delimiter ':' " ..
      preview

  ui.fzf_ui(cmd, open_rg_selection)
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

  local preview = string.format(
    "--preview '%s --line-range :500 {}' --preview-window=right:60%%",
    ui.get_preview_cmd()
  )

  local cmd = string.format(
    "echo %s | %s %s",
    vim.fn.shellescape(table.concat(lines, "\n")),
    ui.get_fzf_base(),
    preview
  )

  ui.fzf_ui(cmd, function(selection)
    if selection and selection ~= "" then
      vim.cmd("edit " .. vim.fn.fnameescape(selection))
    end
  end)
end

return S
