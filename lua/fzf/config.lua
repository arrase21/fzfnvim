local M = {}

M.options = {
  files = {
    fzf_opts = {
      ["--exact"] = "",
      ["--no-sort"] = "",
    },
  },

  grep = {
    fzf_opts = {
      ["--exact"] = "",
    },
  },

  buffers = {
    fzf_opts = {},
  },

  todos = {
    fzf_opts = {},
  },

  ui = {
    width = 0.90,
    height = 0.65,
    backdrop = true,
  },

  preview = {
    command = "bat",
    opts = "--color=always --style=numbers",
  },

  fzf = {
    base = {
      "--ansi",
      "--layout=reverse",
      "--height=100%",
      "--border=none",
      "--info=inline-right",
      "--prompt='󰍉  '",
      "--pointer='▶'",
      "--marker='✓'",
      "--separator='─'",
      "--scrollbar='│'",
      "--preview-window='right:60%:border-left'",
    },
  },

  keymaps = true,
  ui_select = false,
}

function M.setup(opts)
  M.options = vim.tbl_deep_extend(
    "force",
    M.options,
    opts or {}
  )
end

return M
