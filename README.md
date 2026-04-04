# 🗒️ Neovim Sticky Notes

Simple **per-project** floating sticky notes for Neovim.

One note per folder/project. Super lightweight and fast.

### Features
- Floating window with Markdown support
- Automatically saves per current working directory
- Easy picker to browse all notes
- No dependencies

---

### How to Install (Manual)

1. **Download the file**

   Copy the file [`sticky-notes.lua`](sticky-notes.lua) from this repo.

2. **Put it in your config**

   Paste it into your Neovim config folder:
   ```
   ~/.config/nvim/lua/config/sticky-notes.lua
   ```

3. **Load it in your config**

   Add this line in your `init.lua`:

   ```lua
   -- Load sticky notes
   require("config.sticky-notes").setup()
   ```

4. **Add keybinds (Optional but recommended)**

   You can also add these keybinds in your keymaps file:

   ```lua
   vim.keymap.set("n", "<leader>mn", function()
     require("config.sticky-notes").open_split_sticky_note()
   end, { desc = "Open Sticky Note" })

   vim.keymap.set("n", "<leader>ms", function()
     require("config.sticky-notes").toggle_sticky_note_picker()
   end, { desc = "Browse Sticky Notes" })
   ```

---

### Usage

- `<leader>mn` → Open sticky note for current project
- `<leader>w` → Save note and close
- `<leader>ms` → Browse all your sticky notes

---

### Future Plans
- Task progress tracking
- Global search across notes
- Templates
- Auto-hide / persistent mode

Star ⭐ the repo if you like it and want me to develop it further!

