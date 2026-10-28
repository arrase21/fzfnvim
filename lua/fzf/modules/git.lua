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
  local root = vim.fn.getcwd()

  local function collect()
    local ok, res = pcall(function()
      return vim
        .system({ "git", "-C", root, "ls-files", "-z", "--cached", "--others", "--exclude-standard" })
        :wait()
    end)
    if not ok or res.code ~= 0 then
      local err = ok and (res.stderr or ""):gsub("%s+$", "") or "git ls-files failed"
      if err ~= "" then helpers.notify(err, vim.log.levels.WARN) end
      return {}
    end

    local st = helpers.git_status(root)
    local lines = {}
    for _, rel in ipairs(vim.split(res.stdout or "", "\0")) do
      if rel ~= "" then
        lines[#lines + 1] = helpers.badge_line(st, root .. "/" .. rel, rel)
      end
    end
    return lines
  end

  picker.pick({
    source = collect,
    preview = require("fzf.ui").get_preview_cmd() .. " {2}",
    title = " Git Files ",
    prompt = "  ",
    delimiter = "\t",
    with_nth = "1",
    on_select = function(selection)
      if selection and selection ~= "" then
        local rel = selection:match("\t(.+)$")
        if rel then helpers.jump(rel, 1, 1) end
      end
    end,
  })
end

G.status = function()
  local st = helpers.git_status()
  if not st.top then
    return helpers.notify("Not a git repository", vim.log.levels.WARN)
  end
  if #st.list == 0 then
    return helpers.notify("No changes found", vim.log.levels.INFO)
  end

  local lines = {}
  for _, e in ipairs(st.list) do
    local short = vim.fn.fnamemodify(e.abs, ":~:.")
    local display = helpers.file_badge(e.abs, short, e.xy)
    lines[#lines + 1] = display .. "\t" .. short .. "\t" .. e.abs
  end

  picker.pick({
    source = lines,
    preview = require("fzf.ui").get_preview_cmd() .. " --line-range :500 {3}",
    title = " Git Status ",
    prompt = "  ",
    delimiter = "\t",
    with_nth = "1",
    on_select = function(selection)
      if not selection then return end
      local file = vim.split(selection, "\t")[3]
      if file and file ~= "" then helpers.jump(file, 1, 1) end
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
  local st = helpers.git_status()
  local lines = {}
  for _, f in ipairs(files) do
    lines[#lines + 1] = helpers.badge_line(st, f)
  end
  picker.pick({
    source = lines,
    preview = "git diff --color=always -- {2} 2>/dev/null; git diff --cached --color=always -- {2} 2>/dev/null",
    title = " Git Diff ",
    prompt = "  ",
    delimiter = "\t",
    with_nth = "1",
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    on_select = function(selection)
      if not selection then return end
      local path = selection:match("\t(.+)$")
      if path then helpers.jump(path, 1, 1) end
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
  local st = helpers.git_status()
  local lines = {}
  for _, f in ipairs(files) do
    lines[#lines + 1] = helpers.badge_line(st, f)
  end
  picker.pick({
    source = lines,
    preview = require("fzf.ui").get_preview_cmd() .. " --line-range :500 {2}",
    title = " Git Diff (Staged) ",
    prompt = "  ",
    delimiter = "\t",
    with_nth = "1",
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    on_select = function(selection)
      if not selection then return end
      local path = selection:match("\t(.+)$")
      if path then helpers.jump(path, 1, 1) end
    end,
  })
end

return G
