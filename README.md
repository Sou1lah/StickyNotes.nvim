# Sticky Notes for Neovim

Project-specific sticky notes directly in your editor with auto-save and fast switching.

## Features

- **Per-project notes** - Each working directory gets its own sticky note file
- **Auto-save** - Saves automatically as you type and on buffer leave
- **Floating UI** - Clean centered window with rounded borders
- **Fuzzy picker** - Browse all project notes instantly
- **Delete notes** - Remove old notes easily
- **Markdown support** - Full markdown syntax highlighting
- **Vim-native** - Pure Lua, no external dependencies

## Installation

### LazyVim

Add to `~/.config/nvim/lua/plugins/sticky-notes.lua`:

```lua
return {
  "Sou1lah/Sticky-Notes-for-Nvim-",
  event = "VeryLazy",
  config = function()
    require("sticky-notes").setup()
  end,
  keys = {
    {
      "<leader>mn",
      function()
        require("sticky-notes").open_split_sticky_note()
      end,
      desc = "Open Sticky Note",
    },
    {
      "<leader>ms",
      function()
        require("sticky-notes").toggle_sticky_note_picker()
      end,
      desc = "Browse Sticky Notes",
    },
    {
      "<leader>md",
      function()
        require("sticky-notes").delete_sticky_note()
      end,
      desc = "Delete Sticky Note",
    },
  ],
}
```

### Packer.nvim

```lua
use "Sou1lah/Sticky-Notes-for-Nvim-"

require("sticky-notes").setup()
```

### Vim-plug

```vim
Plug 'Sou1lah/Sticky-Notes-for-Nvim-'

lua require('sticky-notes').setup()
```

## Usage

| Keymap | Action |
|--------|--------|
| `<leader>mn` | Open current project's sticky note |
| `<leader>ms` | Browse all sticky notes |
| `<leader>md` | Delete a sticky note |
| `<Esc>` | Close sticky note window |

Or use commands:

```vim
:StickyNote          " Open sticky note for current project
:StickyNotePicker   " Browse all saved notes
:StickyNoteDelete   " Delete a sticky note
```

## Configuration

```lua
require("sticky-notes").setup({
  keymaps = true,  -- Disable default keymaps if you want custom ones
})
```

## Storage

All notes stored in: `~/.config/nvim/sticky_notes/`

Each project automatically gets a file based on its working directory. Switch between projects and your notes follow you.

## Example Workflow

```
Project A
├─ Open :StickyNote
├─ Add tasks for Project A
├─ Auto-saves as you type

Switch to Project B
├─ Open :StickyNote
├─ See different tasks for Project B
├─ Notes are isolated per directory
```

## Requirements

- Neovim 0.7.0+
- `vim.fn.stdpath()` support (standard in modern Neovim)

## License

MIT License - See LICENSE file

## Contributing

Contributions welcome! Submit issues and PRs on GitHub.
