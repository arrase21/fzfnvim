local picker = require("fzf.picker")
local helpers = require("fzf.helpers")

local L = {}

local ansi_cache = {}

local function get_ansi(hl_name)
  if ansi_cache[hl_name] then
    return ansi_cache[hl_name]
  end
  local hl = vim.api.nvim_get_hl(0, { name = hl_name })
  if hl and hl.fg then
    local ansi = string.format(
      "\27[38;2;%d;%d;%dm",
      bit.band(bit.rshift(hl.fg, 16), 0xFF),
      bit.band(bit.rshift(hl.fg, 8), 0xFF),
      bit.band(hl.fg, 0xFF)
    )
    ansi_cache[hl_name] = ansi
    return ansi
  end
  return ""
end

local severity_hl = {
  [1] = "FzfDiagError",
  [2] = "FzfDiagWarn",
  [3] = "FzfDiagInfo",
  [4] = "FzfDiagHint",
}

local severity_icons = {
  [1] = " Error",
  [2] = " Warn",
  [3] = " Info",
  [4] = " Hint",
}

local reset = "\27[0m"

vim.api.nvim_set_hl(0, "FzfDiagError", { link = "DiagnosticError", default = true })
vim.api.nvim_set_hl(0, "FzfDiagWarn", { link = "DiagnosticWarn", default = true })
vim.api.nvim_set_hl(0, "FzfDiagInfo", { link = "DiagnosticInfo", default = true })
vim.api.nvim_set_hl(0, "FzfDiagHint", { link = "DiagnosticHint", default = true })

local function preview_cmd()
  return require("fzf.ui").get_preview_cmd()
end

L.diagnostics = function()
  local diagnostics = vim.diagnostic.get(nil)

  if #diagnostics == 0 then
    helpers.notify("There are no diagnostics", vim.log.levels.INFO)
    return
  end

  table.sort(diagnostics, function(a, b)
    return a.severity < b.severity
  end)

  local lines = {}

  for _, d in ipairs(diagnostics) do
    local abs_path = vim.api.nvim_buf_get_name(d.bufnr)

    if abs_path ~= "" then
      local fname = vim.fn.fnamemodify(abs_path, ":~:.")

      local color = get_ansi(severity_hl[d.severity])

      local icon = severity_icons[d.severity] or "?"

      local msg = d.message:gsub("\n", " ")

      table.insert(
        lines,
        string.format(
          "%s%s%s\t%s%s:%d:%d%s\t%s\t%d\t%d\t%s",
          color,
          icon,
          reset,
          color,
          fname,
          d.lnum + 1,
          d.col + 1,
          reset,
          msg,
          d.lnum + 1,
          d.col + 1,
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

local function location_picker(method)
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

    local items = vim.islist(result) and result or { result }

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
  location_picker("textDocument/references")
end

L.definitions = function()
  location_picker("textDocument/definition")
end

L.implementations = function()
  location_picker("textDocument/implementation")
end

L.type_definition = function()
  location_picker("textDocument/typeDefinition")
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
