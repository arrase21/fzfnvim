local config = require("fzf.config").options
local ui = require("fzf.ui")
local helpers = require("fzf.helpers")

local G = {}

local function git_checkout(target, msg, root)
  root = root or vim.fn.getcwd()

  local output = vim.fn.system(string.format(
    "cd %s && git checkout %s",
    vim.fn.shellescape(root),
    vim.fn.shellescape(target)
  ))

  if vim.v.shell_error == 0 then
    vim.cmd("checktime")
    helpers.notify(msg)
  else
    helpers.notify(
      "❌ Error: " .. output,
      vim.log.levels.ERROR
    )
  end
end

-- git files
G.files = function()
  local cmd = string.format(
    "git ls-files --cached --others --exclude-standard | %s " ..
    "--preview '%s {}'",
    ui.get_fzf_base(),
    ui.get_preview_cmd()
  )

  ui.fzf_ui(cmd, function(selection)
    if selection and selection ~= "" then
      helpers.jump(selection, 1, 1)
    end
  end)
end

-- git status
G.status = function()
  local cmd = string.format(
    "git status --short | %s " ..
    "--ansi " ..
    "--delimiter ' ' " ..
    "--nth 1,2.. " ..
    "--preview '%s {2..}' " ..
    "--preview-window=right:60%%",
    ui.get_fzf_base(),
    ui.get_preview_cmd()
  )

  ui.fzf_ui(cmd, function(selection)
    local file = selection:match("^..%s+(.+)$")

    if file then
      file = file:gsub("%s+->%s+.*$", "")
      helpers.jump(file, 1, 1)
    end
  end)
end

-- git branches
G.branches = function()
  local cmd = string.format(
    "git branch --all --color=always | %s " ..
    "--ansi " ..
    "--preview 'git log --oneline --graph --decorate --color=always -20 $(echo {} | sed \"s#^[* ] ##\" | sed \"s#remotes/##\")'",
    ui.get_fzf_base()
  )

  ui.fzf_ui(cmd, function(selection)
    if not selection then
      return
    end

    local branch = selection
        :gsub("\27%[[%d;]*m", "")
        :gsub("^%*%s+", "")
        :gsub("^%s+", "")
        :gsub("^remotes/", "")

    git_checkout(
      branch,
      "🌱 Switched to " .. branch
    )
  end)
end

-- git commits
G.commits = function()
  local cmd =
      "git log --oneline --color=always | " ..
      ui.get_fzf_base() ..
      " --ansi " ..
      "--preview 'git show --color=always {1}'"

  ui.fzf_ui(cmd, function(selection, root)
    local hash = selection:match("^(%S+)")

    if hash then
      git_checkout(
        hash,
        "🚀 Commit: " .. hash,
        root
      )
    end
  end)
end

-- git stash
G.stash = function()
  local cmd =
      "git stash list | " ..
      ui.get_fzf_base() ..
      " --preview 'git stash show -p --color=always {1}'"

  ui.fzf_ui(cmd, function(selection)
    local stash =
        selection:match("^(stash@{%d+})")

    if stash then
      local res =
          vim.system({
            "git",
            "stash",
            "apply",
            stash
          }):wait()

      if res.code == 0 then
        helpers.notify("✅ Stash aplicado")
      else
        helpers.notify(
          res.stderr,
          vim.log.levels.ERROR
        )
      end
    end
  end)
end

-- git diff
G.diff = function()
  local cmd =
      "git diff --name-only | " ..
      ui.get_fzf_base() ..
      " --preview 'git diff --color=always {}'"

  ui.fzf_ui(cmd, function(selection, root)
    vim.cmd(
      "edit " ..
      vim.fn.fnameescape(
        root .. "/" .. selection
      )
    )
  end)
end

-- git grep
G.grep = function()
  local query = vim.fn.input("Git grep > ")

  if query == "" then
    return
  end

  local cmd = string.format(
    "git grep -n --color=always %s | %s " ..
    "--ansi " ..
    "--delimiter ':' " ..
    "--preview '%s --highlight-line {2} {1}' " ..
    "--preview-window=right:60%%",
    vim.fn.shellescape(query),
    ui.get_fzf_base(),
    ui.get_preview_cmd()
  )

  ui.fzf_ui(cmd, function(selection)
    local file, lnum =
        selection:match("^(.-):(%d+):")

    if file then
      helpers.jump(file, lnum, 1)
    end
  end)
end

return G
