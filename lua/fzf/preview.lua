local M = {}

local function get_hl(name)
  if not name or name == "" then
    return {}
  end
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if (not ok or type(hl) ~= "table" or next(hl) == nil) then
    ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name })
    if ok and type(hl) == "table" and hl.link then
      ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = hl.link, link = false })
    end
  end
  if not ok or type(hl) ~= "table" then
    return {}
  end
  if hl.reverse and hl.fg and hl.bg then
    hl.fg, hl.bg = hl.bg, hl.fg
  end
  return hl
end

local function hex(value)
  if type(value) ~= "number" then return nil end
  return string.format("#%06x", value)
end

local function font_style(hl)
  local attrs = {}
  if hl.bold then attrs[#attrs + 1] = "bold" end
  if hl.italic then attrs[#attrs + 1] = "italic" end
  if hl.underline then attrs[#attrs + 1] = "underline" end
  return #attrs > 0 and table.concat(attrs, " ") or nil
end

local function xml_escape(value)
  return (value:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function setting(scope, hl)
  local fg = hex(hl.fg) or hex(hl.bg)
  local style = font_style(hl)
  if not fg and not style then return nil end

  local lines = {
    "    <dict>",
    "      <key>scope</key><string>" .. xml_escape(scope) .. "</string>",
    "      <key>settings</key><dict>",
  }
  if fg then
    lines[#lines + 1] = "        <key>foreground</key><string>" .. fg .. "</string>"
  end
  if style then
    lines[#lines + 1] = "        <key>fontStyle</key><string>" .. style .. "</string>"
  end
  lines[#lines + 1] = "      </dict>"
  lines[#lines + 1] = "    </dict>"
  return table.concat(lines, "\n")
end

local scopes = {
  { "comment", { "@comment", "Comment" } },
  { "string", { "@string", "String" } },
  { "string.regexp", { "@string.regexp", "String" } },
  { "string.escape", { "@string.escape", "SpecialChar" } },
  { "constant", { "@constant", "Constant" } },
  { "constant.numeric", { "@number", "Number" } },
  { "constant.language", { "@constant.builtin", "Constant" } },
  { "constant.character.escape", { "@string.escape", "SpecialChar" } },
  { "keyword", { "@keyword", "Keyword" } },
  { "keyword.control", { "@keyword.control", "@keyword", "Keyword" } },
  { "keyword.declaration", { "@keyword", "Keyword" } },
  { "keyword.function", { "@keyword.function", "@keyword", "Keyword" } },
  { "keyword.type", { "@keyword.type", "@keyword", "Keyword" } },
  { "keyword.operator", { "@operator", "Operator" } },
  { "storage", { "@keyword", "Keyword" } },
  { "storage.type", { "@type", "@type.builtin", "Type" } },
  { "storage.type.function", { "@keyword.function", "@keyword", "Keyword" } },
  { "storage.type.class", { "@type", "Keyword" } },
  { "storage.type.struct", { "@type", "Keyword" } },
  { "storage.type.enum", { "@type", "Keyword" } },
  { "storage.type.interface", { "@type", "Keyword" } },
  { "entity.name.function", { "@function", "Function" } },
  { "entity.name.type", { "@type", "Type" } },
  { "entity.name.class", { "@type", "Type" } },
  { "entity.name.tag", { "@tag", "Tag" } },
  { "entity.other.attribute-name", { "@attribute", "Identifier" } },
  { "variable.member", { "@variable.member", "Identifier" } },
  { "variable.other.member", { "@variable.member", "Identifier" } },
  { "variable.other.property", { "@variable.member", "Identifier" } },
  { "meta.property.lua", { "@variable.member", "Identifier" } },
  { "meta.property", { "@property", "Identifier" } },
  { "meta.property-name", { "@property", "Identifier" } },
  { "meta.property-value", { "@property", "Identifier" } },
  { "variable.parameter", { "@variable.parameter", "Identifier" } },
  { "variable.language", { "@variable.builtin", "Constant" } },
  { "variable.other", { "@variable", "Identifier" } },
  { "variable", { "@variable", "Identifier" } },
  { "support.function", { "@function.call", "@function", "Function" } },
  { "support.class", { "@type", "Type" } },
  { "support.type", { "@type", "Type" } },
  { "support.constant", { "@constant", "Constant" } },
  { "support.variable", { "@variable.builtin", "Constant" } },
  { "preprocessor", { "@keyword.directive", "PreProc" } },
  { "meta.preprocessor", { "@keyword.directive", "PreProc" } },
  { "punctuation.accessor.lua", { "@variable", "Normal" } },
  { "punctuation.accessor", { "@punctuation.delimiter", "Delimiter" } },
  { "punctuation.definition", { "@punctuation", "Delimiter" } },
  { "punctuation.definition.comment", { "@comment", "Comment" } },
  { "punctuation.definition.string", { "@string", "String" } },
  { "punctuation.definition.string.begin", { "@string", "String" } },
  { "punctuation.definition.string.end", { "@string", "String" } },
  { "punctuation.definition.escape", { "@string.escape", "SpecialChar" } },
  { "punctuation.definition.variable", { "@variable", "Identifier" } },
  { "punctuation.section", { "@punctuation.bracket", "@punctuation", "Delimiter" } },
  { "punctuation.separator", { "@punctuation.delimiter", "Delimiter" } },
  { "punctuation.terminator", { "@punctuation.delimiter", "Delimiter" } },
  { "punctuation", { "@punctuation", "Delimiter" } },
  { "operator", { "@operator", "Operator" } },
  { "invalid", { "@error", "Error" } },
  { "invalid.illegal", { "@error", "Error" } },
  { "markup.heading", { "@markup.heading", "Title" } },
  { "markup.raw", { "@markup.raw", "String" } },
  { "markup.raw.inline", { "@markup.raw.inline", "@markup.raw", "String" } },
  { "markup.raw.block", { "@markup.raw.block", "@markup.raw", "String" } },
  { "markup.list", { "@markup.list", "Special" } },
  { "markup.inserted", { "@diff.plus", "DiffAdd" } },
  { "markup.deleted", { "@diff.minus", "DiffDelete" } },
  { "markup.changed", { "@diff.delta", "DiffChange" } },
  { "meta.diff.header", { "@diff.delta", "DiffText" } },
  { "markup.bold", { "@markup.bold", "Bold" } },
  { "markup.italic", { "@markup.italic", "Italic" } },
  { "markup.underline", { "@markup.underline", "Underlined" } },
}

local function scopes_hl(groups)
  for _, name in ipairs(groups) do
    local hl = get_hl(name)
    if next(hl) ~= nil then return hl end
  end
  return {}
end

local function generate()
  local normal = get_hl("Normal")
  local visual = get_hl("Visual")
  local cursorline = get_hl("CursorLine")
  local linenr = get_hl("LineNr")
  local cursorlinenr = get_hl("CursorLineNr")
  local search = get_hl("Search")
  local incsearch = get_hl("IncSearch")
  local default_fg = hex(normal.fg) or hex(get_hl("@variable").fg) or "#ffffff"

  local parts = {
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">',
    '<plist version="1.0">',
    '<dict>',
    '  <key>name</key><string>Neovim</string>',
    '  <key>settings</key>',
    '  <array>',
  }

  local global = { "    <dict>", "      <key>settings</key><dict>" }
  local function global_key(key, value)
    if value then
      global[#global + 1] = "        <key>" .. key .. "</key><string>" .. value .. "</string>"
    end
  end
  global_key("foreground", default_fg)
  global_key("caret", default_fg)
  global_key("selection", hex(visual.bg))
  global_key("selectionForeground", hex(visual.fg))
  global_key("lineHighlight", hex(cursorline.bg) or hex(visual.bg))
  global_key("gutterForeground", hex(linenr.fg))
  global_key("gutterForegroundHighlight", hex(cursorlinenr.fg) or hex(linenr.fg))
  global_key("findHighlight", hex(search.bg))
  global_key("findHighlightForeground", hex(search.fg) or hex(incsearch.fg))
  global[#global + 1] = "      </dict>"
  global[#global + 1] = "    </dict>"
  parts[#parts + 1] = table.concat(global, "\n")

  for _, item in ipairs(scopes) do
    local block = setting(item[1], scopes_hl(item[2]))
    if block then parts[#parts + 1] = block end
  end

  parts[#parts + 1] = "  </array>"
  parts[#parts + 1] = "</dict>"
  parts[#parts + 1] = "</plist>"

  return table.concat(parts, "\n")
end

function M.ensure()
  if vim.fn.executable("bat") ~= 1 then return nil end

  local xml = generate()
  local hash = vim.fn.sha256(xml):sub(1, 12)
  local theme = "fzf-" .. hash
  local root = vim.fn.stdpath("cache") .. "/fzf-bat"
  local config_dir = root .. "/config"
  local cache_dir = root .. "/cache"
  local themes_dir = config_dir .. "/themes"
  local theme_file = themes_dir .. "/" .. theme .. ".tmTheme"
  local marker = cache_dir .. "/" .. theme .. ".built"

  if vim.fn.filereadable(theme_file) == 0 then
    vim.fn.mkdir(themes_dir, "p")
    vim.fn.writefile(vim.split(xml, "\n"), theme_file)
  end

  if vim.fn.filereadable(marker) == 0 or vim.fn.filereadable(cache_dir .. "/themes.bin") == 0 then
    vim.fn.mkdir(cache_dir, "p")
    vim.fn.system({
      "env",
      "BAT_CONFIG_DIR=" .. config_dir,
      "BAT_CACHE_PATH=" .. cache_dir,
      vim.fn.exepath("bat"),
      "cache",
      "--build",
    })
    if vim.v.shell_error ~= 0 then return nil end
    pcall(vim.fn.writefile, { tostring(vim.fn.localtime()) }, marker)
  end

  return theme, config_dir, cache_dir
end

return M
