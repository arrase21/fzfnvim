local ui =
    require("fzf.ui")

local M = {}

function M.setup()
  vim.ui.select = function(items, opts, on_choice)
    opts = opts or {}

    local lines = {}

    local format_item =
        opts.format_item or tostring

    for _, item in ipairs(items) do
      table.insert(
        lines,
        format_item(item)
      )
    end

    local cmd = string.format(
      "echo %s | %s --prompt '%s> '",
      vim.fn.shellescape(
        table.concat(lines, "\n")
      ),
      ui.get_fzf_base(),
      opts.prompt or "Select"
    )

    ui.fzf_ui(cmd, function(selection)
      for i, item in ipairs(items) do
        if format_item(item) == selection then
          on_choice(item, i)
          return
        end
      end
    end)
  end
end

return M
