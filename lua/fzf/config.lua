local M = {}

M.layout_presets = {
  center = function(opts)
    local w = math.floor(vim.o.columns * (opts.width or 0.90))
    local h = math.floor(vim.o.lines * (opts.height or 0.65))
    return {
      width = w,
      height = h,
      row = math.floor((vim.o.lines - h) / 2),
      col = math.floor((vim.o.columns - w) / 2),
    }
  end,
  fullscreen = function(opts)
    local f = opts.fullscreen
    local w = math.floor(vim.o.columns * (f.width or 1.0))
    local h = math.floor(vim.o.lines * (f.height or 1.0))
    return vim.tbl_extend("force", { border = f.border or "none" }, {
      width = w,
      height = h,
      row = 0,
      col = 0,
    })
  end,
  horizontal = function(opts)
    local h = opts.horizontal
    local w = math.floor(vim.o.columns * (h.width or 1.0))
    local hi = math.floor(vim.o.lines * (h.height or 0.35))
    return vim.tbl_extend("force", { border = h.border or "rounded" }, {
      width = w,
      height = hi,
      row = vim.o.lines - hi,
      col = 0,
    })
  end,
}

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
    layout = "center",
    width = 0.90,
    height = 0.65,
    backdrop = true,
    backdrop_bg = "#000000",
    border = "rounded",
    title = " FZF ",
    title_pos = "center",
    fullscreen = {
      width = 1.0,
      height = 1.0,
      border = "none",
    },
    horizontal = {
      width = 1.0,
      height = 0.35,
      border = "rounded",
    },
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
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

return M
