# Sticky Notes for Neovim 📝

A lightweight plugin that gives you **project-specific sticky notes** in Neovim.

## Features

- One sticky note per project (based on current working directory)
- Beautiful floating window
- Auto-save on every change
- Markdown support
- Easy picker to browse all notes
- Delete notes easily

## Installation

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

### With vim.pack (native package)
Clone or symlink this repo into `~/.config/nvim/pack/plugins/start/sticky-notes.nvim` (or any `pack/*/start/` directory). It will auto-load via the `plugin/` directory.

**Do not** call `require("sticky-notes").setup()` manually in your `init.lua` for either method.

### Testing
- For **vim.pack**: Restart Neovim, run `:Lazy clean` if switching from Lazy.nvim, and check `:messages` for errors.
- For **Lazy.nvim**: Use the config above, restart Neovim, and check that `<leader>mn` and `<leader>ms` work.

**Note:** No double-initialization will occur. Both methods are supported and can be switched between without conflicts.
