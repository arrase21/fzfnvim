local picker = require("fzf.picker")
local config = require("fzf.config").options
local helpers = require("fzf.helpers")

local S = {}

local reset = helpers.reset

local function preview()
  return require("fzf.ui").get_preview_cmd() .. " --line-range :500 {}"
end

local function rg_preview()
  return require("fzf.ui").get_preview_cmd() .. " --highlight-line {2} {1}"
end

local function rg_opts_str(key)
  local opts = config[key] and config[key].rg_opts
  return opts or "--column --line-number --no-heading --color=never --smart-case"
end

local function open_rg_selection(selection, ctx)
  if not selection then return end
  local file, line, col = selection:match("^([^:]+):(%d+):(%d+):")
  if file then
    helpers.jump(helpers.join_path(ctx.root, file), line, col)
  end
end

local function grep_common(rg_extra, title)
  local rg_base = "rg " .. rg_opts_str("grep")
  local header_fuzzy = " [Fuzzy] Ctrl-g:regex "
  local header_regex = " [Regex] Ctrl-g:fuzzy "

  picker.pick({
    source = rg_base .. " " .. (rg_extra or "''"),
    preview = rg_preview,
    title = title or " Grep ",
    header = header_fuzzy,
    delimiter = ":",
    bind = {
      ["ctrl-g"] = "reload(" .. rg_base .. " -e {q})+change-header(" .. header_regex .. ")",
      ["alt-g"] = "reload(" .. rg_base .. " '')+change-header(" .. header_fuzzy .. ")",
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    fzf_opts = helpers.build_fzf_opts(config.grep.fzf_opts),
    on_select = open_rg_selection,
  })
end

S.files = function()
  picker.pick({
    source = "rg --files --hidden --no-ignore-vcs -g '!.git'",
    preview = function()
      return require("fzf.ui").get_preview_cmd() .. " --line-range :500 {}"
    end,
    title = " Files ",
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    fzf_opts = helpers.build_fzf_opts(config.files.fzf_opts),
    on_select = function(selection, ctx)
      if not selection then return end
      vim.cmd("edit " .. vim.fn.fnameescape(helpers.join_path(ctx.root, selection)))
    end,
  })
end

S.grep = function()
  grep_common(nil, " Grep ")
end

S.grep_word = function()
  local word = vim.fn.expand("<cword>")
  local rg_base = "rg " .. rg_opts_str("grep_word")
  local header_fuzzy = " [Fuzzy] Ctrl-g:regex "
  local header_regex = " [Regex] Ctrl-g:fuzzy "

  picker.pick({
    source = rg_base .. " " .. vim.fn.shellescape(word),
    preview = rg_preview,
    title = " Grep Word ",
    header = header_fuzzy,
    delimiter = ":",
    bind = {
      ["ctrl-g"] = "reload(" .. rg_base .. " -e {q})+change-header(" .. header_regex .. ")",
      ["alt-g"] = "reload(" .. rg_base .. " " .. vim.fn.shellescape(word) .. ")+change-header(" .. header_fuzzy .. ")",
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    fzf_opts = helpers.build_fzf_opts(config.grep_word.fzf_opts),
    on_select = open_rg_selection,
  })
end

S.live_grep = function()
  local rg_base = "rg " .. rg_opts_str("live_grep")
  local header_fuzzy = " [Fuzzy] Ctrl-g:regex Ctrl-r:refresh "
  local header_regex = " [Regex] Ctrl-g:fuzzy Ctrl-r:refresh "

  picker.pick({
    source = rg_base .. " ''",
    preview = rg_preview,
    title = " Live Grep ",
    header = header_fuzzy,
    delimiter = ":",
    bind = {
      ["ctrl-g"] = "reload(" .. rg_base .. " -e {q})+change-header(" .. header_regex .. ")",
      ["alt-g"] = "reload(" .. rg_base .. " '')+change-header(" .. header_fuzzy .. ")",
      ["ctrl-r"] = "reload(" .. rg_base .. " {q})",
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    fzf_opts = helpers.build_fzf_opts(config.live_grep.fzf_opts),
    on_select = open_rg_selection,
  })
end

local function buffer_preview()
  return require("fzf.ui").get_preview_cmd() .. " --line-range :500 {3}"
end

S.buffers = function()
  local buffers = vim.fn.getbufinfo({ buflisted = 1 })
  table.sort(buffers, function(a, b)
    return a.lastused > b.lastused
  end)

  local lines = {}
  for _, buf in ipairs(buffers) do
    if buf.name ~= "" then
      local bn = buf.bufnr
      local icon, _ = helpers.file_icon(buf.name)
      local short = vim.fn.fnamemodify(buf.name, ":~:.")
      table.insert(lines, string.format("%s\t%s\t%s", bn, icon or "", short))
    end
  end

  if #lines == 0 then
    return helpers.notify("No buffers")
  end

  picker.pick({
    source = lines,
    preview = buffer_preview,
    title = " Buffers ",
    delimiter = "\t",
    with_nth = "2..3",
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
      ["ctrl-x"] = "execute(echo {1})+abort",
    },
    on_select = function(selection)
      if not selection then return end
      local parts = vim.split(selection, "\t")
      local bufnr = tonumber(parts[1])
      if bufnr then
        vim.api.nvim_set_current_buf(bufnr)
      end
    end,
  })
end

S.buffers_native = function()
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
    preview = preview,
    title = " Buffers ",
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    on_select = function(selection)
      if not selection then return end
      vim.cmd("edit " .. vim.fn.fnameescape(selection))
    end,
  })
end

S.todos = function()
  local patterns = "TODO|FIXME|HACK|NOTE|BUG|WARN"
  picker.pick({
    source = string.format(
      "rg --column --line-number --no-heading --color=always --smart-case -e '%s'",
      patterns
    ),
    preview = rg_preview,
    title = " TODOs ",
    delimiter = ":",
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
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
      local icon, color = helpers.file_icon(file)
      local name = file:match("([^/]+)$") or file
      if color then
        table.insert(lines, helpers.ansi_color(color[1], color[2], color[3]) .. icon .. reset .. "\t" .. name .. "\t" .. file)
      else
        table.insert(lines, icon .. "\t" .. name .. "\t" .. file)
      end
    end
  end

  picker.pick({
    source = lines,
    preview = function()
      return require("fzf.ui").get_preview_cmd() .. " --line-range :500 {r3}"
    end,
    title = " Old Files ",
    delimiter = "\t",
    with_nth = "1..2",
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    fzf_opts = helpers.build_fzf_opts(config.oldfiles.fzf_opts),
    on_select = function(selection)
      if not selection then return end
      local file = selection:match("\t([^\t]+)$")
      if file and file ~= "" then
        vim.cmd("edit " .. vim.fn.fnameescape(file))
      end
    end,
  })
end

-- Help tags
S.help_tags = function()
  local tags = vim.fn.getcompletion("", "help")
  local lines = {}
  for _, tag in ipairs(tags or {}) do
    if tag ~= "" then
      table.insert(lines, tag)
    end
  end

  if #lines == 0 then
    return helpers.notify("No help tags found")
  end

  picker.pick({
    source = lines,
    title = " Help Tags ",
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    on_select = function(selection)
      if selection then
        local tag = selection:match("^([^\t]+)") or selection
        vim.cmd("help " .. vim.fn.fnameescape(tag))
      end
    end,
  })
end

-- Man pages
S.man_pages = function()
  local cmd = "man -k . 2>/dev/null | head -500"
  picker.pick({
    source = cmd,
    title = " Man Pages ",
    delimiter = " - ",
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    on_select = function(selection)
      if selection then
        local name = selection:match("^([^( ]+)")
        if name then
          vim.cmd("Man " .. name)
        end
      end
    end,
  })
end

-- Keymaps
S.keymaps = function()
  local maps = vim.api.nvim_get_keymap("n")
  local lines = {}
  for _, m in ipairs(maps) do
    local desc = m.desc or (m.rhs and #m.rhs > 0 and m.rhs) or ""
    local mode = m.mode or "n"
    local lhs = m.lhs or ""
    local rhs = m.rhs or ""
    table.insert(lines, string.format("%s\t%s\t%s\t%s", mode, lhs, desc, rhs))
  end

  picker.pick({
    source = lines,
    title = " Keymaps ",
    delimiter = "\t",
    with_nth = "1..3",
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    on_select = function(selection)
      if not selection then return end
      local parts = vim.split(selection, "\t")
      local lhs = parts[2]
      if lhs then
        pcall(vim.cmd, "normal " .. lhs)
      end
    end,
  })
end

-- Commands
S.commands = function()
  local cmds = vim.api.nvim_get_commands({})
  local lines = {}
  for name, cmd in pairs(cmds) do
    local desc = cmd.description or ""
    table.insert(lines, name .. "\t" .. desc)
  end
  table.sort(lines)

  picker.pick({
    source = lines,
    title = " Commands ",
    delimiter = "\t",
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    on_select = function(selection)
      if not selection then return end
      local name = selection:match("^([^\t]+)")
      if name then
        vim.cmd(":" .. name)
      end
    end,
  })
end

-- Highlights
S.highlights = function()
  local hl_groups = vim.fn.getcompletion("", "highlight")
  local lines = {}
  for _, hl in ipairs(hl_groups) do
    table.insert(lines, hl)
  end
  table.sort(lines)

  picker.pick({
    source = lines,
    title = " Highlights ",
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    on_select = function(selection)
      if not selection then return end
      vim.cmd("highlight " .. selection)
    end,
  })
end

-- Marks
S.marks = function()
  local marks = vim.fn.getmarklist()
  local lines = {}
  for _, m in ipairs(marks) do
    if m.mark and m.pos then
      local lnum = m.pos[2] or 1
      local col = m.pos[3] or 1
      local file = m.file or ""
      local fname = vim.fn.fnamemodify(file, ":~:.")
      table.insert(lines, string.format("%s\t%s\t%d\t%d", m.mark, fname, lnum, col))
    end
  end

  picker.pick({
    source = lines,
    title = " Marks ",
    delimiter = "\t",
    with_nth = "1,2",
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    preview = function()
      return require("fzf.ui").get_preview_cmd() .. " --line-range :500 --highlight-line {3} {2}"
    end,
    on_select = function(selection)
      if not selection then return end
      local parts = vim.split(selection, "\t")
      local mark = parts[1]
      if mark then
        vim.cmd("normal! '" .. mark:sub(1, 1))
      end
    end,
  })
end

-- Registers
S.registers = function()
  local lines = {}
  for _, r in ipairs({ '"', "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-", ".", ":", "/", "=", "#", "*", "+", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" }) do
    local value = vim.fn.getreg(r)
    local regtype = vim.fn.getregtype(r)
    if value and value ~= "" then
      local disp = value:gsub("\n", "\\n"):gsub("\t", "\\t")
      if #disp > 60 then
        disp = disp:sub(1, 60) .. "..."
      end
      table.insert(lines, string.format("%s\t%s\t%s", r, regtype or "v", disp))
    end
  end

  picker.pick({
    source = lines,
    title = " Registers ",
    delimiter = "\t",
    with_nth = "1,3",
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    on_select = function(selection)
      if not selection then return end
      local parts = vim.split(selection, "\t")
      local reg = parts[1]
      if reg then
        vim.fn.setreg('"', vim.fn.getreg(reg))
        vim.cmd("normal! \"0p")
      end
    end,
  })
end

-- Jump list (removed - use builtin <C-o>/<C-i>)

-- Change list
S.changes = function()
  local lines = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local list = vim.fn.getchangelist(bufnr)
      local entries = list[1] or {}
      for _, c in ipairs(entries) do
        local file = c.fname or ""
        if file ~= "" then
          local lnum = c.lnum or 1
          local col = c.col or 1
          local rel = vim.fn.fnamemodify(file, ":~:.")
          table.insert(lines, string.format("%s\t%s\t%d\t%d", rel, file, lnum, col))
        end
      end
    end
  end

  if #lines == 0 then
    return helpers.notify("Change list is empty")
  end

  picker.pick({
    source = lines,
    title = " Changes ",
    delimiter = "\t",
    with_nth = "1",
    preview = function()
      return require("fzf.ui").get_preview_cmd() .. " --line-range :500 --highlight-line {3} {2}"
    end,
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    on_select = function(selection)
      if not selection then return end
      local parts = vim.split(selection, "\t")
      local file, lnum, col = parts[2], parts[3], parts[4]
      if file then
        helpers.jump(file, lnum, col)
      end
    end,
  })
end

-- Spell suggest
S.spell_suggest = function()
  local word = vim.fn.expand("<cword>")
  local ok, suggestions = pcall(vim.fn.spellsuggest, word, 50)
  if not ok then
    return helpers.notify("Spell check not configured (:set spelllang=en)")
  end

  local lines = {}
  for _, s in ipairs(suggestions) do
    table.insert(lines, s)
  end

  if #lines == 0 then
    return helpers.notify("No spell suggestions for '" .. word .. "'")
  end

  picker.pick({
    source = lines,
    title = " Spell Suggest ",
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    on_select = function(selection)
      if selection then
        vim.cmd("normal! ciw" .. selection)
      end
    end,
  })
end

-- Colorschemes
S.colorschemes = function()
  local schemes = vim.fn.getcompletion("", "color")
  if not schemes or #schemes == 0 then
    return helpers.notify("No colorschemes found")
  end
  table.sort(schemes)

  local scheme_file = vim.fn.tempname()
  local old_scheme = vim.g.colors_name or "default"

  local timer
  local selected = false

  timer = vim.uv.new_timer()
  timer:start(80, 80, vim.schedule_wrap(function()
    local f = io.open(scheme_file, "r")
    if f then
      local name = f:read("*l")
      f:close()
      if name and name ~= "" and (vim.g.colors_name or "") ~= name then
        pcall(vim.cmd, "colorscheme " .. name)
      end
    end
  end))

  picker.pick({
    source = schemes,
    title = " Colorschemes ",
    preview = function()
      return "cat " .. vim.fn.shellescape(scheme_file) .. " 2>/dev/null; echo '<< live preview'"
    end,
    bind = {
      ["focus"] = "execute-silent:echo {} > " .. vim.fn.shellescape(scheme_file),
    },
    on_select = function(selection)
      if selection then
        selected = true
        vim.cmd("colorscheme " .. selection)
        helpers.notify("Colorscheme: " .. selection)
      end
    end,
    on_cleanup = function(had_selection)
      timer:stop()
      timer:close()
      pcall(os.remove, scheme_file)
      if not had_selection then
        pcall(vim.cmd, "colorscheme " .. old_scheme)
      end
    end,
  })
end

-- Quickfix list
S.quickfix = function()
  local qflist = vim.fn.getqflist()
  if not qflist or #qflist == 0 then
    return helpers.notify("Quickfix list is empty")
  end

  local lines = {}
  for _, entry in ipairs(qflist) do
    local fname = vim.fn.bufname(entry.bufnr or 0)
    if fname ~= "" then
      fname = vim.fn.fnamemodify(fname, ":~:.")
      local lnum = entry.lnum or 1
      local col = entry.col or 1
      local text = entry.text or ""
      table.insert(lines, string.format("%s:%d:%d:%s", fname, lnum, col, text))
    end
  end

  picker.pick({
    source = lines,
    title = " Quickfix ",
    delimiter = ":",
    with_nth = "1,2,3,4",
    preview = function()
      return require("fzf.ui").get_preview_cmd() .. " --line-range :500 --highlight-line {2} {1}"
    end,
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    on_select = function(selection)
      if not selection then return end
      local file, lnum, col = selection:match("^(.-):(%d+):(%d+):")
      if file then
        helpers.jump(file, lnum, col)
      end
    end,
  })
end

-- Location list
S.loclist = function()
  local loclist = vim.fn.getloclist(0)
  if not loclist or #loclist == 0 then
    return helpers.notify("Location list is empty (use :lgrep, :lhelpgrep, etc.)")
  end

  local lines = {}
  for _, entry in ipairs(loclist) do
    local fname = vim.fn.bufname(entry.bufnr or 0)
    if fname ~= "" then
      fname = vim.fn.fnamemodify(fname, ":~:.")
      local lnum = entry.lnum or 1
      local col = entry.col or 1
      local text = entry.text or ""
      table.insert(lines, string.format("%s:%d:%d:%s", fname, lnum, col, text))
    end
  end

  picker.pick({
    source = lines,
    title = " Location List ",
    delimiter = ":",
    with_nth = "1,2,3,4",
    preview = function()
      return require("fzf.ui").get_preview_cmd() .. " --line-range :500 --highlight-line {2} {1}"
    end,
    bind = {
      ["ctrl-d"] = "preview-half-page-down",
      ["ctrl-u"] = "preview-half-page-up",
    },
    on_select = function(selection)
      if not selection then return end
      local file, lnum, col = selection:match("^(.-):(%d+):(%d+):")
      if file then
        helpers.jump(file, lnum, col)
      end
    end,
  })
end

-- Resume
S.resume = function()
  picker.resume()
end

-- Search history
S.search_history = function()
  local lines = {}
  local last = vim.fn.histnr("/")
  if last and last > 0 then
    for i = 1, math.min(last, 100) do
      local entry = vim.fn.histget("/", i)
      if entry and entry ~= "" then
        table.insert(lines, entry)
      end
    end
  end

  if #lines == 0 then
    return helpers.notify("No search history")
  end

  picker.pick({
    source = lines,
    title = " Search History ",
    on_select = function(selection)
      if selection and selection ~= "" then
        vim.fn.setreg("/", selection)
        helpers.notify("Search pattern set: " .. selection)
      end
    end,
  })
end

return S
