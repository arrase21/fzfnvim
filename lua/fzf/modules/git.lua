local picker = require("fzf.picker")
local helpers = require("fzf.helpers")

local G = {}

local function git_checkout(target, msg, root)
  root = root or vim.fn.getcwd()

  local res = vim.system({ "git", "-C", root, "checkout", target }):wait()

  if res.code == 0 then
    vim.cmd("checktime")
    helpers.notify(msg)
  else
    local err = res.stderr or ""
    helpers.notify("Error: " .. err, vim.log.levels.ERROR)
  end
end

G.files = function()
  picker.pick({
    source = "git ls-files --cached --others --exclude-standard",
    preview = require("fzf.ui").get_preview_cmd() .. " {}",
    title = " Git Files ",
    prompt = "  ",
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
      .. [[ --line-range :500 "$(x={}; echo "${x##* }")"]],
    title = " Git Status ",
    prompt = "  ",
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
    prompt = "  ",
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
    prompt = "  ",
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
    prompt = "  ",
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

local function git_root()
  local res = vim.fn.systemlist("git rev-parse --show-toplevel")
  if res and #res > 0 then
    return res[1]:gsub("[\r\n]+$", "") .. "/"
  end
  return vim.fn.getcwd() .. "/"
end

local function get_diff_files()
  local root = git_root()
  local files, seen = {}, {}
  for _, list in ipairs({
    vim.fn.systemlist("git diff --name-only") or {},
    vim.fn.systemlist("git diff --cached --name-only") or {},
  }) do
    for _, f in ipairs(list) do
      local clean = f:gsub("[\r\n]+$", "")
      if clean ~= "" and not seen[clean] then
        table.insert(files, root .. clean)
        seen[clean] = true
      end
    end
  end
  return files
end

G.diff = function()
  local files = get_diff_files()
  if #files == 0 then
    return helpers.notify("No changes found", vim.log.levels.INFO)
  end
  picker.pick({
    source = files,
    preview = "git diff --color=always -- {} 2>/dev/null; git diff --cached --color=always -- {} 2>/dev/null",
    title = " Git Diff ",
    prompt = "  ",
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    on_select = function(selection)
      if not selection then return end
      helpers.jump(selection, 1, 1)
    end,
  })
end

G.diff_staged = function()
  local root = git_root()
  local raw = vim.fn.systemlist("git diff --cached --name-only") or {}
  local files = {}
  for _, f in ipairs(raw) do
    local clean = f:gsub("[\r\n]+$", "")
    if clean ~= "" then
      table.insert(files, root .. clean)
    end
  end
  if #files == 0 then
    return helpers.notify("No staged changes", vim.log.levels.INFO)
  end
  picker.pick({
    source = files,
    preview = require("fzf.ui").get_preview_cmd() .. " --line-range :500 {}",
    title = " Git Diff (Staged) ",
    prompt = "  ",
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    on_select = function(selection)
      if not selection then return end
      helpers.jump(selection, 1, 1)
    end,
  })
end

return G
