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

Add this block to any file in your `~/.config/nvim/lua/plugins/` folder:

```lua
{
  "Sou1lah/Sticky-Notes-for-Nvim-",
  event = "VeryLazy",
  config = function()
    require("sticky-notes").setup({
      keymaps = true,
    })
  end,
  keys = {
    { "<leader>mn", "<cmd>StickyNote<cr>",       desc = "Open Sticky Note" },
    { "<leader>ms", "<cmd>StickyNotePicker<cr>", desc = "Browse Sticky Notes" },
    { "<leader>md", "<cmd>StickyNoteDelete<cr>", desc = "Delete Sticky Note" },
  },
},
