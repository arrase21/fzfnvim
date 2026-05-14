local picker = require("fzf.picker")
local helpers = require("fzf.helpers")

local G = {}

local function git_checkout(target, msg, root)
  root = root or vim.fn.getcwd()

  local output = vim.fn.system(
    string.format("cd %s && git checkout %s", vim.fn.shellescape(root), vim.fn.shellescape(target))
  )

  if vim.v.shell_error == 0 then
    vim.cmd("checktime")
    helpers.notify(msg)
  else
    helpers.notify("Error: " .. output, vim.log.levels.ERROR)
  end
end

G.files = function()
  picker.pick({
    source = "git ls-files --cached --others --exclude-standard",
    preview = require("fzf.ui").get_preview_cmd() .. " {}",
    title = " Git Files ",
    on_select = function(selection)
      if selection and selection ~= "" then
        helpers.jump(selection, 1, 1)
      end
    end,
  })
end

G.status = function()
  picker.pick({
    source = "git status --short",
    preview = require("fzf.ui").get_preview_cmd()
      .. [[ --line-range :500 "$(echo {} | awk '{print $NF}')"]],
    title = " Git Status ",
    on_select = function(selection)
      local file = selection:match("^..%s+(.+)$")

      if file then
        file = file:gsub("%s+->%s+.*$", "")
        helpers.jump(file, 1, 1)
      end
    end,
  })
end

G.branches = function()
  picker.pick({
    source = "git branch --all --color=always",
    preview = "git log --oneline --graph --decorate --color=always -20 "
      .. [[$(echo {} | sed "s#^[* ] ##" | sed "s#remotes/##")]],
    title = " Git Branches ",
    on_select = function(selection)
      if not selection then
        return
      end

      local branch =
        selection:gsub("\27%[[%d;]*m", ""):gsub("^%*%s+", ""):gsub("^%s+", ""):gsub("^remotes/", "")

      git_checkout(branch, "Switched to " .. branch)
    end,
  })
end

G.commits = function()
  picker.pick({
    source = "git log --oneline --color=always",
    preview = "git show --color=always {1}",
    title = " Git Commits ",
    on_select = function(selection, ctx)
      local hash = selection:match("^(%S+)")

      if hash then
        git_checkout(hash, "Commit: " .. hash, ctx.root)
      end
    end,
  })
end

G.stash = function()
  picker.pick({
    source = "git stash list",
    preview = "git stash show -p --color=always {1}",
    title = " Git Stash ",
    on_select = function(selection)
      local stash = selection:match("^(stash@{%d+})")

      if stash then
        local res = vim
          .system({
            "git",
            "stash",
            "apply",
            stash,
          })
          :wait()

        if res.code == 0 then
          helpers.notify("Stash applied")
        else
          helpers.notify(res.stderr, vim.log.levels.ERROR)
        end
      end
    end,
  })
end

G.diff = function()
  picker.pick({
    source = "git diff --name-only",
    preview = "git diff --color=always {}",
    title = " Git Diff ",
    on_select = function(selection, ctx)
      helpers.jump(helpers.join_path(ctx.root, selection), 1, 1)
    end,
  })
end

return G
