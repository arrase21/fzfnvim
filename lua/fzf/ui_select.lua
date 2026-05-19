local config = require("fzf.config")
local ui = require("fzf.ui")

local M = {}

local function resolve_win_opts()
  local layout = config.options.ui.layout
  local resolver = config.layout_presets[layout]
  if resolver then
    return resolver(config.options.ui)
  end
  return config.layout_presets.center(config.options.ui)
end

local function build_fzf_flags(win_opts)
  local parts = {}
  if win_opts.fzf_opts then
    for _, opt in ipairs(win_opts.fzf_opts) do
      table.insert(parts, opt)
    end
  end
  if win_opts.title then
    table.insert(parts, string.format("--border-label='%s'", win_opts.title))
  end
  if #parts == 0 then return "" end
  return " " .. table.concat(parts, " ")
end

function M.setup()
  vim.ui.select = function(items, opts, on_choice)
    opts = opts or {}

    local lines = {}

    local format_item = opts.format_item or tostring

    for _, item in ipairs(items) do
      table.insert(lines, format_item(item))
    end

    local prompt = string.format("--prompt='%s> '", opts.prompt or "Select")
    local win_opts = resolve_win_opts()
    local preview_window = win_opts.preview_window or "right:55%"

    local cmd = string.format(
      "echo %s | %s --preview 'echo {}' --preview-window='%s' %s%s",
      vim.fn.shellescape(table.concat(lines, "\n")),
      ui.get_fzf_base(),
      preview_window,
      prompt,
      build_fzf_flags(win_opts)
    )

    ui.fzf_ui(cmd, function(selection)
      for i, item in ipairs(items) do
        if format_item(item) == selection then
          on_choice(item, i)
          return
        end
      end
    end, win_opts)
  end
end

return M
