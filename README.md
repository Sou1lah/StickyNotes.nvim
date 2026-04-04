# sticky-notes.nvim

Project-specific sticky notes for Neovim with auto-save and fuzzy picking.

## Features

- Per-project sticky notes (auto-organized by directory)
- Auto-save on typing and buffer leave
- Floating window UI with rounded borders
- Browse all notes with fuzzy picker
- Delete notes easily
- Markdown syntax highlighting
- Works with LazyVim and other plugin managers

## Installation

### LazyVim

Create `~/.config/nvim/lua/plugins/sticky-notes.lua`:

```lua
return {
  "your-username/sticky-notes-nvim",
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
  },
}
```

### Packer.nvim

```lua
use "your-username/sticky-notes-nvim"

require("sticky-notes").setup()
```

### Vim-plug

```vim
Plug 'your-username/sticky-notes-nvim'

lua require('sticky-notes').setup()
```

## Usage

| Keymap | Action |
|--------|--------|
| `<leader>mn` | Open sticky note for current project |
| `<leader>ms` | Browse all sticky notes |
| `<leader>md` | Delete a sticky note |
| `<Esc>` | Close sticky note window |

Or use commands:

```vim
:StickyNote           " Open current project note
:StickyNotePicker    " Browse all notes
:StickyNoteDelete    " Delete a note
```

## Configuration

```lua
require("sticky-notes").setup({
  keymaps = true,  -- Set to false to disable default keymaps
})
```

## Storage

Notes stored at: `~/.config/nvim/sticky_notes/`

Each project gets a file based on its working directory path.

## License

MIT
