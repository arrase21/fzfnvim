local ui = require("fzf.ui")
local helpers = require("fzf.helpers")

local L = {}

local severity_colors = {
  [1] = "\27[31m", -- Error
  [2] = "\27[33m", -- Warn
  [3] = "\27[36m", -- Info
  [4] = "\27[34m", -- Hint
}

local severity_icons = {
  [1] = " 💀",
  [2] = "  ",
  [3] = " 󰌵 ",
  [4] = "  ",
}

local reset = "\27[0m"

-- diagnostics
L.diagnostics = function()
  local diagnostics = vim.diagnostic.get(nil)

  if #diagnostics == 0 then
    helpers.notify(
      "There are no diagnostics",
      vim.log.levels.INFO
    )
    return
  end

  table.sort(diagnostics, function(a, b)
    return a.severity < b.severity
  end)

  local lines = {}

  for _, d in ipairs(diagnostics) do
    local abs_path =
        vim.api.nvim_buf_get_name(d.bufnr)

    if abs_path ~= "" then
      local fname =
          vim.fn.fnamemodify(abs_path, ":~:.")

      local color =
          severity_colors[d.severity] or ""

      local icon =
          severity_icons[d.severity] or "?"

      local msg =
          d.message:gsub("\n", " ")

      table.insert(lines, string.format(
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
      ))
    end
  end

  if #lines == 0 then
    helpers.notify(
      "No valid diagnostics",
      vim.log.levels.WARN
    )
    return
  end

  local cmd = string.format(
    "echo %s | %s " ..
    "--ansi " ..
    "--delimiter '\t' " ..
    "--with-nth 1,2,3 " ..
    "--preview '%s --line-range {4}: --highlight-line {4} {6}' " ..
    "--preview-window=right:60%%",
    vim.fn.shellescape(
      table.concat(lines, "\n")
    ),
    ui.get_fzf_base(),
    ui.get_preview_cmd()
  )

  ui.fzf_ui(cmd, function(selection)
    local parts =
        vim.split(selection, "\t")

    local lnum = parts[4]
    local col = parts[5]
    local abs_path = parts[6]

    lnum =
        lnum and lnum:gsub("\27%[[%d;]*m", "")

    col =
        col and col:gsub("\27%[[%d;]*m", "")

    if abs_path and lnum then
      helpers.jump(abs_path, lnum, col)
    end
  end)
end

-- generic location picker
local function location_picker(method)
  local params =
      vim.lsp.util.make_position_params(
        0,
        "utf-8"
      )

  if method:match("references") then
    params.context = {
      includeDeclaration = true,
    }
  end

  vim.lsp.buf_request(
    0,
    method,
    params,
    function(err, result)
      if err
          or not result
          or vim.tbl_isempty(result)
      then
        return helpers.notify("No results")
      end

      local items =
          vim.islist(result)
          and result
          or { result }

      -- direct jump
      if #items == 1 then
        local item = items[1]

        local target =
            item.uri or item.targetUri

        local range =
            item.range
            or item.targetSelectionRange

        helpers.jump(
          vim.uri_to_fname(target),
          range.start.line + 1,
          range.start.character + 1
        )

        return
      end

      local lines = {}

      for _, loc in ipairs(items) do
        local uri =
            loc.uri or loc.targetUri

        local range =
            loc.range
            or loc.targetSelectionRange

        local path =
            vim.uri_to_fname(uri)

        table.insert(lines, string.format(
          "%s:%d:%d",
          vim.fn.fnamemodify(path, ":~:."),
          range.start.line + 1,
          range.start.character + 1
        ))
      end

      local cmd = string.format(
        "echo %s | %s " ..
        "--delimiter ':' " ..
        "--preview '%s --highlight-line {2} {1}' " ..
        "--preview-window=right:60%%",
        vim.fn.shellescape(
          table.concat(lines, "\n")
        ),
        ui.get_fzf_base(),
        ui.get_preview_cmd()
      )

      ui.fzf_ui(cmd, function(selection)
        local file, lnum, col =
            selection:match(
              "^(.-):(%d+):(%d+)"
            )

        if file then
          helpers.jump(
            vim.fn.expand(file),
            lnum,
            col
          )
        end
      end)
    end
  )
end

L.references = function()
  location_picker(
    "textDocument/references"
  )
end

L.definitions = function()
  location_picker(
    "textDocument/definition"
  )
end

L.implementations = function()
  location_picker(
    "textDocument/implementation"
  )
end

L.type_definition = function()
  location_picker(
    "textDocument/typeDefinition"
  )
end

-- symbols
L.symbols = function()
  local params = {
    textDocument =
        vim.lsp.util.make_text_document_params(0),
  }

  vim.lsp.buf_request(
    0,
    "textDocument/documentSymbol",
    params,
    function(err, result)
      if err
          or not result
          or vim.tbl_isempty(result)
      then
        return helpers.notify("No symbols")
      end

      local lines = {}

      local function flatten(symbols)
        for _, s in ipairs(symbols) do
          local range =
              s.selectionRange or s.range

          if range then
            table.insert(lines, string.format(
              "%s\t%s\t%d",
              vim.lsp.protocol.SymbolKind[s.kind]
              or "Unknown",
              s.name,
              range.start.line + 1
            ))
          end

          if s.children then
            flatten(s.children)
          end
        end
      end

      flatten(result)

      local current_file =
          vim.api.nvim_buf_get_name(0)

      local cmd = string.format(
        "echo %s | %s " ..
        "--delimiter '\t' " ..
        "--with-nth 1,2 " ..
        "--preview '%s --highlight-line {3} %s' " ..
        "--preview-window=right:60%%",
        vim.fn.shellescape(
          table.concat(lines, "\n")
        ),
        ui.get_fzf_base(),
        ui.get_preview_cmd(),
        current_file
      )

      ui.fzf_ui(cmd, function(selection)
        local lnum =
            selection:match("\t(%d+)$")

        if lnum then
          helpers.jump(
            current_file,
            lnum,
            1
          )
        end
      end)
    end
  )
end

return L
