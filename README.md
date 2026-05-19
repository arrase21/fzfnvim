# fzfnvim

Unified fzf-based picker UI for Neovim. File search, grep, git, LSP navigation, sessions, and harpoon-like bookmarks — all powered by fzf.

## Requirements

- Neovim >= 0.9
- [fzf](https://github.com/junegunn/fzf)
- [ripgrep](https://github.com/BurntSushi/ripgrep) (optional, for file/grep search)
- [bat](https://github.com/sharkdp/bat) (optional, for syntax-highlighted previews)

## Installation

### lazy.nvim

```lua
{
  "arrase21/fzfnvim",
  opts = {}, -- your config here
}
```

### packer.nvim

```lua
use {
  "arrase21/fzfnvim",
  config = function()
    require("fzf").setup({})
  end,
}
```

## Commands

| Command | Description |
|---|---|
| `:FzfFiles` | Search project files (rg --files) |
| `:FzfGrep` | Interactive grep across project |
| `:FzfGrepW` | Grep word under cursor |
| `:FzfBuffers` | Switch between open buffers |
| `:FzfTodos` | Search TODO/FIXME/HACK/NOTE/BUG/WARN |
| `:FzfOldFiles` | Browse recently opened files |
| `:FzfGitFiles` | Git tracked files |
| `:FzfGitStatus` | Git status picker |
| `:FzfGitCommits` | Git log with checkout on select |
| `:FzfGitBranches` | Git branches with checkout on select |
| `:FzfGitStash` | Git stash apply picker |
| `:FzfGitDiff` | Git diff file picker |
| `:FzfHarpoonAdd` | Add current file to harpoon |
| `:FzfHarpoon` | Open harpoon file list |
| `:FzfHarpoonRemove` | Remove file from harpoon |
| `:FzfSessionSave` | Save session |
| `:FzfSessionLoad` | Load session |
| `:FzfSessionDelete` | Delete session |
| `:FzfLspDiagnostics` | LSP diagnostics picker |
| `:FzfLspSymbols` | LSP document symbols |
| `:FzfLspReferences` | LSP references |
| `:FzfLspDefinitions` | LSP definition |
| `:FzfLspImplementations` | LSP implementations |
| `:FzfLspType` | LSP type definition |

## Configuration

```lua
require("fzf").setup({
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
    dropdown = {
      width = 1.0,
      height = 0.40,
      border = "none",
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
})
```

## API

```lua
local fzf = require("fzf")

fzf.files()
fzf.grep()
fzf.grep_word()
fzf.buffers()
fzf.todos()
fzf.oldfiles()
fzf.git_files()
fzf.git_status()
fzf.git_commits()
fzf.git_branches()
fzf.git_stash()
fzf.git_diff()
fzf.harpoon_add()
fzf.harpoon_open()
fzf.harpoon_remove()
fzf.harpoon_jump(1)
fzf.session_save()
fzf.session_load()
fzf.session_delete()
fzf.lsp_diagnostics()
fzf.lsp_symbols()
fzf.lsp_references()
fzf.lsp_definitions()
fzf.lsp_implementations()
fzf.lsp_type_definitions()
fzf.pick({ source = ..., on_select = ... })
```
