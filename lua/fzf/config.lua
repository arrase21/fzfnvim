local M = {}

M.layout_presets = {
  center = function(opts)
    local c = opts.center or {}
    local w = math.floor(vim.o.columns * (c.width or opts.width or 0.80))
    local h = math.floor(vim.o.lines * (c.height or opts.height or 0.80))
    return {
      width = w,
      height = h,
      row = math.floor((vim.o.lines - h) / 3),
      col = math.floor((vim.o.columns - w) / 2),
      border = nil,
      preview_window = c.preview_window or "right:55%:border-rounded",
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
      preview_window = "right:50%",
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
  vertical = function(opts)
    local v = opts.vertical or {}
    local w = math.floor(vim.o.columns * (v.width or 0.90))
    local h = math.floor(vim.o.lines * (v.height or 0.80))
    return {
      width = w,
      height = h,
      row = math.floor((vim.o.lines - h) / 2),
      col = math.floor((vim.o.columns - w) / 2),
      border = nil,
      preview_window = v.preview_window or "bottom:50%:border-top",
    }
  end,
}

local defaults = {
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
    rg_opts = "--column --line-number --no-heading --color=never --smart-case",
  },

  grep_word = {
    rg_opts = "--column --line-number --no-heading --color=never --smart-case",
  },

  live_grep = {
    rg_opts = "--column --line-number --no-heading --color=never --smart-case",
  },

  buffers = {
    fzf_opts = {},
  },

  help_tags = {
    fzf_opts = {},
  },

  man_pages = {
    fzf_opts = {},
  },

  keymaps = {
    fzf_opts = {},
  },

  commands = {
    fzf_opts = {},
  },

  highlights = {
    fzf_opts = {},
  },

  marks = {
    fzf_opts = {},
  },

  registers = {
    fzf_opts = {},
  },

  jumps = {
    fzf_opts = {},
  },

  changes = {
    fzf_opts = {},
  },

  spell_suggest = {
    fzf_opts = {},
  },

  colorschemes = {
    fzf_opts = {},
  },

  quickfix = {
    fzf_opts = {},
  },

  loclist = {
    fzf_opts = {},
  },

  todos = {
    fzf_opts = {},
  },

  oldfiles = {
    fzf_opts = {},
  },

  ui = {
    layout = "center",
    width = 0.80,
    height = 0.80,
    backdrop = true,
    backdrop_bg = "#000000",
    border = "rounded",
    title = " FZF ",
    title_pos = "center",
    center = {
      width = 0.80,
      height = 0.80,
      preview_window = "right:55%:border-rounded",
    },
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
    vertical = {
      width = 0.90,
      height = 0.80,
      preview_window = "bottom:50%:border-top",
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
    },
  },

  keymaps = true,
  ui_select = true,
}

M.options = vim.deepcopy(defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

return M
