# fzfnvim

Unified fzf-based picker UI for Neovim — heavily inspired by fzf-lua. File search, grep (with Ctrl-G regex toggle), git, LSP navigation, sessions, harpoon-like bookmarks, and many built-in pickers.

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

### Search

| Command | Description |
|---|---|
| `:FzfFiles` | Search project files (rg --files) |
| `:FzfGrep` | Interactive grep across project (Ctrl-g toggles regex mode) |
| `:FzfGrepW` | Grep word under cursor (Ctrl-g toggles regex mode) |
| `:FzfLiveGrep` | Live grep with dynamic refresh on each keystroke |
| `:FzfBuffers` | Switch between open buffers (with icons) |
| `:FzfTodos` | Search TODO/FIXME/HACK/NOTE/BUG/WARN |
| `:FzfOldFiles` | Browse recently opened files |
| `:FzfHelpTags` | Search Neovim help tags |
| `:FzfManPages` | Search man pages |
| `:FzfKeymaps` | Browse and execute keymaps |
| `:FzfCommands` | Browse and run commands |
| `:FzfHighlights` | Browse highlight groups |
| `:FzfMarks` | Browse file marks |
| `:FzfRegisters` | Browse and paste registers |
| `:FzfJumps` | Browse jumplist |
| `:FzfChanges` | Browse changelist |
| `:FzfSpellSuggest` | Spell suggestions for word under cursor |
| `:FzfColorschemes` | Pick a colorscheme |
| `:FzfQuickfix` | Browse quickfix list |
| `:FzfLoclist` | Browse location list |
| `:FzfSearchHistory` | Browse search history |
| `:FzfResume` | Resume last picker |

### Git

| Command | Description |
|---|---|
| `:FzfGitFiles` | Git tracked files |
| `:FzfGitStatus` | Git status picker |
| `:FzfGitCommits` | Git log with checkout on select |
| `:FzfGitBranches` | Git branches with checkout on select |
| `:FzfGitStash` | Git stash apply picker |
| `:FzfGitDiff` | Git diff file picker |

### Harpoon

| Command | Description |
|---|---|
| `:FzfHarpoonAdd` | Add current file to harpoon |
| `:FzfHarpoon` | Open harpoon file list |
| `:FzfHarpoonRemove` | Remove file from harpoon |

### Sessions

| Command | Description |
|---|---|
| `:FzfSessionSave` | Save session |
| `:FzfSessionLoad` | Load session |
| `:FzfSessionDelete` | Delete session |

### LSP

| Command | Description |
|---|---|
| `:FzfLspDiagnostics` | LSP diagnostics picker |
| `:FzfLspSymbols` | LSP document symbols |
| `:FzfLspReferences` | LSP references |
| `:FzfLspDefinitions` | LSP definition |
| `:FzfLspImplementations` | LSP implementations |
| `:FzfLspType` | LSP type definition |

## Features

- **Ctrl-G regex toggle** - In grep pickers, press `Ctrl-g` to switch to regex mode (query passed directly to ripgrep). Press `Alt-g` to return to fuzzy mode.
- **Preview scrolling** - Use `Ctrl-d` and `Ctrl-u` to scroll preview up/down.
- **Resume** - `:FzfResume` reopens the last picker with the same source.
- **Live grep** - `:FzfLiveGrep` refreshes results on each keystroke using ripgrep.
- **20+ built-in pickers** - Navigate help, keymaps, commands, marks, registers, jumps, changes, quickfix, loclist, and more.

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
    rg_opts = "--column --line-number --no-heading --color=always --smart-case",
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

-- Search
fzf.files()
fzf.grep()
fzf.grep_word()
fzf.live_grep()
fzf.buffers()
fzf.todos()
fzf.oldfiles()
fzf.help_tags()
fzf.man_pages()
fzf.keymaps()
fzf.commands()
fzf.highlights()
fzf.marks()
fzf.registers()
fzf.jumps()
fzf.changes()
fzf.spell_suggest()
fzf.colorschemes()
fzf.quickfix()
fzf.loclist()
fzf.search_history()
fzf.resume()

-- Git
fzf.git_files()
fzf.git_status()
fzf.git_commits()
fzf.git_branches()
fzf.git_stash()
fzf.git_diff()

-- Harpoon
fzf.harpoon_add()
fzf.harpoon_open()
fzf.harpoon_remove()
fzf.harpoon_jump(1)

-- Sessions
fzf.session_save()
fzf.session_load()
fzf.session_delete()

-- LSP
fzf.lsp_diagnostics()
fzf.lsp_symbols()
fzf.lsp_references()
fzf.lsp_definitions()
fzf.lsp_implementations()
fzf.lsp_type_definitions()

-- Generic picker
fzf.pick({ source = ..., on_select = ... })
```
