local core = require("fzf.core")

local G = {}

local function git_checkout(target, msg, root)
  root = root or core.get_git_root()
  local output = vim.fn.system(string.format("cd %s && git checkout %s", vim.fn.shellescape(root),
    vim.fn.shellescape(target)))
  if vim.v.shell_error == 0 then
    vim.cmd("checktime")
    core.notify(msg)
  else
    core.notify("❌ Error: " .. output, vim.log.levels.ERROR)
  end
end

-- git files
G.files = function()
  local cmd = string.format(
    "git ls-files --cached --others --exclude-standard | %s " ..
    "--preview '%s {}'",
    core.fzf_base,
    core.bat_preview
  )

  core.fzf_ui(cmd, function(selection)
    if selection and selection ~= "" then
      core.jump(selection, 1, 1)
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
    core.fzf_base,
    core.bat_preview
  )

  core.fzf_ui(cmd, function(selection)
    local file = selection:match("^..%s+(.+)$")

    if file then
      file = file:gsub("%s+->%s+.*$", "")
      core.jump(file, 1, 1)
    end
  end)
end

-- git branches
G.branches = function()
  local cmd = string.format(
    "git branch --all --color=always | %s " ..
    "--ansi " ..
    "--preview 'git log --oneline --graph --decorate --color=always -20 $(echo {} | sed \"s#^[* ] ##\" | sed \"s#remotes/##\")'",
    core.fzf_base
  )

  core.fzf_ui(cmd, function(selection)
    if not selection then
      return
    end

    local branch = selection
        :gsub("\27%[[%d;]*m", "")
        :gsub("^%*%s+", "")
        :gsub("^%s+", "")
        :gsub("^remotes/", "")

    vim.cmd("Git checkout " .. branch)
  end)
end
G.commits = function()
  local cmd = "git log --oneline --color=always | " .. core.fzf_base ..
      "--ansi --preview 'git show --color=always {1}' --header 'Enter para Checkout (Detached)'"
  core.fzf_ui(cmd, function(selection, root)
    local hash = selection:match("^(%S+)")
    if hash then git_checkout(hash, "🚀 Commit: " .. hash, root) end
  end)
end

-- git stash
G.stash = function()
  local cmd = "git stash list | " .. core.fzf_base .. "--preview 'git stash show -p --color=always {1}'"
  core.fzf_ui(cmd, function(selection)
    local stash = selection:match("^(stash@{%d+})")
    if stash then
      local res = vim.system({ "git", "stash", "apply", stash }):wait()
      if res.code == 0 then core.notify("✅ Stash aplicado") else core.notify(res.stderr, vim.log.levels.ERROR) end
    end
  end)
end

-- git diff
G.diff = function()
  local cmd = "git diff --name-only | " .. core.fzf_base .. "--preview 'git diff --color=always {}'"
  core.fzf_ui(cmd, function(selection, root)
    vim.cmd("edit " .. vim.fn.fnameescape(root .. "/" .. selection))
  end)
end

-- git grep
G.grep = function()
  local query = vim.fn.input("Git grep > ")

  if query == "" then
    return
  end

  local cmd = string.format(
    "git grep -n --line-number --color=always %s | %s " ..
    "--ansi " ..
    "--delimiter ':' " ..
    "--preview '%s --highlight-line {2} {1}' " ..
    "--preview-window=right:60%%",
    vim.fn.shellescape(query),
    core.fzf_base,
    core.bat_preview
  )

  core.fzf_ui(cmd, function(selection)
    local file, lnum, col =
        selection:match("^(.-):(%d+):(%d+)")

    if file then
      core.jump(file, lnum, col)
    end
  end)
end

return G
