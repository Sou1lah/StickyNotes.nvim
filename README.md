# Sticky Notes for Neovim 
> give a star ⭐ if u like

A lightweight plugin that gives you **project-specific sticky notes** in Neovim.

## Features

- One sticky note per project (based on current working directory)
- Beautiful floating window
- Auto-save on every change
- Markdown support
- Easy picker to browse all notes
- Delete notes easily

## Installation

### With Lazy.nvim

Add this block to your Lazy.nvim spec (e.g. `~/.config/nvim/lua/plugins/`):

```lua
{
  "Sou1lah/Sticky-Notes-for-Nvim-",
  event = "VeryLazy",
  config = function()
    vim.g.sticky_notes_lazy_loaded = true
    require("sticky-notes").setup({
      keymaps = true,
    })
  end,
  keys = {
    { "<leader>mn", "<cmd>StickyNote<cr>",       desc = "Open Sticky Note" },
    { "<leader>ms", "<cmd>StickyNotePicker<cr>", desc = "Browse Sticky Notes" },
  },
},
```

### vim.pack (Native Neovim Package Manager)

vim.pack is Neovim's built-in package manager. Installation is simple git cloning.

**Install:**

```bash
mkdir -p ~/.config/nvim/pack/plugins/start
cd ~/.config/nvim/pack/plugins/start
git clone https://github.com/Sou1lah/StickyNotes.nvim.git sticky-notes
```

**Uninstall:**

```bash
rm -rf ~/.config/nvim/pack/plugins/start/sticky-notes
```

**How it works:**

- Neovim automatically loads all plugins in `pack/*/start/` on startup
- No configuration needed — plugin works out of the box
- Default keymaps: `<leader>mn` (open note), `<leader>ms` (picker)

## Usage

### Commands

- `:StickyNote` — Open/create note for current directory
- `:StickyNotePicker` — Browse all notes with search

### Keymaps

- `<leader>mn` — Open sticky note
- `<leader>ms` — Open note picker
- `<Tab>` — Toggle checkbox (in note)
- `q` / `<Esc>` — Close window

## License

MIT — See LICENSE file

## Contributing

Issues and pull requests welcome on GitHub.

---
## Stats

[![GitHub stars](https://img.shields.io/github/stars/Sou1lah/StickyNotes.nvim?style=flat-square&logo=github)](https://github.com/Sou1lah/StickyNotes.nvim)
[![GitHub forks](https://img.shields.io/github/forks/Sou1lah/StickyNotes.nvim?style=flat-square&logo=github)](https://github.com/Sou1lah/StickyNotes.nvim)
[![GitHub issues](https://img.shields.io/github/issues/Sou1lah/StickyNotes.nvim?style=flat-square&logo=github)](https://github.com/Sou1lah/StickyNotes.nvim/issues)
[![License](https://img.shields.io/github/license/Sou1lah/StickyNotes.nvim?style=flat-square)](https://github.com/Sou1lah/StickyNotes.nvim/blob/main/LICENSE)
![Repo Views](https://komarev.com/ghpvc/?username=Sou1lah-StickyNotes&color=dc143c)

