local picker = require("fzf.picker")
local helpers = require("fzf.helpers")

local L = {}

local ansi_cache = {}

local function get_ansi(hl_name, fallback)
  if ansi_cache[hl_name] then
    return ansi_cache[hl_name]
  end
  local hl = vim.api.nvim_get_hl(0, { name = hl_name, link = true })
  local ansi
  if hl and hl.fg then
    ansi = string.format(
      "\27[38;2;%d;%d;%dm",
      bit.band(bit.rshift(hl.fg, 16), 0xFF),
      bit.band(bit.rshift(hl.fg, 8), 0xFF),
      bit.band(hl.fg, 0xFF)
    )
  elseif fallback then
    ansi = helpers.ansi_color(fallback[1], fallback[2], fallback[3])
  else
    ansi = ""
  end
  ansi_cache[hl_name] = ansi
  return ansi
end

local severity_hl = {
  [1] = { "DiagnosticError", { 255, 85, 85 } },
  [2] = { "DiagnosticWarn", { 255, 200, 50 } },
  [3] = { "DiagnosticInfo", { 85, 185, 255 } },
  [4] = { "DiagnosticHint", { 170, 170, 170 } },
}

local severity_icons = {
  [1] = "💀",
  [2] = " ",
  [3] = "󰌵 ",
  [4] = " ",
}

local reset = "\27[0m"
local bold = "\27[1m"

local function preview_cmd()
  return require("fzf.ui").get_preview_cmd()
end

local function process_and_show(diagnostics)
  if #diagnostics == 0 then
    helpers.notify("There are no diagnostics", vim.log.levels.INFO)
    return
  end

  table.sort(diagnostics, function(a, b)
    return (a.severity or 4) < (b.severity or 4)
  end)

  local lines = {}

  for _, d in ipairs(diagnostics) do
    local abs_path = d.filename or (d.bufnr and vim.api.nvim_buf_get_name(d.bufnr)) or ""

    if abs_path ~= "" then
      local fname = vim.fn.fnamemodify(abs_path, ":~:.")

      local sev = severity_hl[d.severity] or severity_hl[4]

      local color = get_ansi(sev[1], sev[2])

      local icon = severity_icons[d.severity] or " ? "

      local msg = d.message:gsub("[\n\t]", " ")

      local lnum = d.lnum + 1
      local col = d.col + 1

      table.insert(
        lines,
        string.format(
          "%s%s%s\t%s%s:%d:%d%s\t%s\t%d\t%d\t%s",
          color, icon, reset,
          color, fname, lnum, col, reset,
          msg,
          lnum, col,
          abs_path
        )
      )
    end
  end

  if #lines == 0 then
    helpers.notify("No valid diagnostics", vim.log.levels.WARN)
    return
  end

  picker.pick({
    source = lines,
    preview = preview_cmd() .. " --line-range {4}: --highlight-line {4} {6}",
    title = " Diagnostics ",
    prompt = "  ",
    delimiter = "\t",
    with_nth = "1,2,3",
    on_select = function(selection)
      local parts = vim.split(selection, "\t")

      local lnum = parts[4]
      local col = parts[5]
      local abs_path = parts[6]
      lnum = lnum and lnum:gsub("\27%[[%d;]*m", "")
      col = col and col:gsub("\27%[[%d;]*m", "")

      if abs_path and lnum then
        helpers.jump(abs_path, lnum, col)
      end
    end,
  })
end

L.diagnostics = function()
  -- Get diagnostics from ALL existing buffers (like fzf-lua does)
  -- This includes unloaded buffers that still have diagnostics stored
  local diagnostics = {}
  local all_diags = vim.diagnostic.get(nil)

  for _, d in ipairs(all_diags) do
    if d.bufnr and vim.api.nvim_buf_is_valid(d.bufnr) then
      local filename = vim.api.nvim_buf_get_name(d.bufnr)
      if filename ~= "" then
        d.filename = filename
        table.insert(diagnostics, d)
      end
    end
  end

  process_and_show(diagnostics)
end

local function location_picker(method, title)
  local params = vim.lsp.util.make_position_params(0, "utf-8")

  if method:match("references") then
    params.context = {
      includeDeclaration = true,
    }
  end

  vim.lsp.buf_request(0, method, params, function(err, result)
    if err or not result or vim.tbl_isempty(result) then
      return helpers.notify("No results")
    end

    local items = (type(result) == "table" and result[1] ~= nil) and result or { result }

    if #items == 1 then
      local item = items[1]

      local target = item.uri or item.targetUri

      local range = item.range or item.targetSelectionRange

      helpers.jump(vim.uri_to_fname(target), range.start.line + 1, range.start.character + 1)

      return
    end

    local lines = {}

    for _, loc in ipairs(items) do
      local uri = loc.uri or loc.targetUri

      local range = loc.range or loc.targetSelectionRange

      local path = vim.uri_to_fname(uri)

      table.insert(
        lines,
        string.format(
          "%s:%d:%d",
          vim.fn.fnamemodify(path, ":~:."),
          range.start.line + 1,
          range.start.character + 1
        )
      )
    end

    picker.pick({
      source = lines,
      preview = preview_cmd() .. " --highlight-line {2} {1}",
      title = title or " Locations ",
      prompt = "  ",
      delimiter = ":",
      on_select = function(selection)
        local file, lnum, col = selection:match("^(.-):(%d+):(%d+)")

        if file then
          helpers.jump(vim.fn.expand(file), lnum, col)
        end
      end,
    })
  end)
end

L.references = function()
  location_picker("textDocument/references", " References ")
end

L.definitions = function()
  location_picker("textDocument/definition", " Definitions ")
end

L.implementations = function()
  location_picker("textDocument/implementation", " Implementations ")
end

L.type_definition = function()
  location_picker("textDocument/typeDefinition", " Type Definition ")
end

L.code_actions = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local params = vim.lsp.util.make_range_params(0, "utf-8")
  local cur_line = vim.fn.line(".") - 1
  local line_diags = {}
  for _, d in ipairs(vim.diagnostic.get(bufnr)) do
    if d.lnum == cur_line then
      table.insert(line_diags, d)
    end
  end
  params.context = {
    diagnostics = line_diags,
  }

  vim.lsp.buf_request(0, "textDocument/codeAction", params, function(err, result)
    if err or not result or #result == 0 then
      return helpers.notify("No code actions available")
    end

    local lines = {}
    local actions = {}
    for _, action in ipairs(result) do
      if action.title then
        table.insert(lines, action.title)
        table.insert(actions, action)
      end
    end

    if #lines == 0 then
      return helpers.notify("No code actions available")
    end

    picker.pick({
      source = lines,
    title = " Code Actions ",
    prompt = "  ",
    on_select = function(selection)
        if not selection then return end
        for _, action in ipairs(actions) do
          if action.title == selection then
            if action.edit then
              vim.lsp.util.apply_workspace_edit(action.edit)
            end
            if action.command then
              vim.lsp.buf.execute_command(action.command)
            end
            break
          end
        end
      end,
    })
  end)
end

L.workspace_symbols = function()
  vim.lsp.buf_request(0, "workspace/symbol", { query = "" }, function(err, result)
    if err or not result or vim.tbl_isempty(result) then
      return helpers.notify("No workspace symbols")
    end

    local lines = {}
    for _, s in ipairs(result) do
      local name = s.name
      local kind = vim.lsp.protocol.SymbolKind[s.kind] or "Unknown"
      local container = s.containerName or ""
      local uri = s.location and s.location.uri
      local range = s.location and s.location.range
      if uri and range then
        local path = vim.uri_to_fname(uri)
        local short = vim.fn.fnamemodify(path, ":~:.")
        table.insert(
          lines,
          string.format("%s\t%s\t%s\t%s\t%d", kind, name, container, short, range.start.line + 1)
        )
      end
    end

    if #lines == 0 then
      return helpers.notify("No workspace symbols")
    end

    picker.pick({
      source = lines,
      preview = require("fzf.ui").get_preview_cmd()
        .. " --line-range :500 --highlight-line {5} {4}",
    title = " Workspace Symbols ",
    prompt = "☰ ",
    delimiter = "\t",
      with_nth = "1,2,3",
      on_select = function(selection)
        if not selection then return end
        local parts = vim.split(selection, "\t")
        local file, lnum = parts[4], tonumber(parts[5])
        if file and lnum then
          helpers.jump(file, lnum, 1)
        end
      end,
    })
  end)
end

L.symbols = function()
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(0),
  }

  vim.lsp.buf_request(0, "textDocument/documentSymbol", params, function(err, result)
    if err or not result or vim.tbl_isempty(result) then
      return helpers.notify("No symbols")
    end

    local lines = {}

    local function flatten(symbols)
      for _, s in ipairs(symbols) do
        local range = s.selectionRange or s.range

        if range then
          table.insert(
            lines,
            string.format(
              "%s\t%s\t%d",
              vim.lsp.protocol.SymbolKind[s.kind] or "Unknown",
              s.name,
              range.start.line + 1
            )
          )
        end

        if s.children then
          flatten(s.children)
        end
      end
    end

    flatten(result)

    local current_file = vim.api.nvim_buf_get_name(0)

    picker.pick({
      source = lines,
      preview = preview_cmd() .. " --highlight-line {3} " .. current_file,
    title = " Symbols ",
    prompt = "  ",
    delimiter = "\t",
      with_nth = "1,2",
      on_select = function(selection)
        local lnum = selection:match("\t(%d+)$")

        if lnum then
          helpers.jump(current_file, lnum, 1)
        end
      end,
    })
  end)
end

return L
