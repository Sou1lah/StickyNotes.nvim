#!/bin/bash
# ================================================
# Neovim Sticky Notes - Installer
# ================================================

set -e

echo "🗒️  Neovim Sticky Notes Installer"
echo "================================="

# Detect Neovim config path
if [ -z "$XDG_CONFIG_HOME" ]; then
  CONFIG_DIR="$HOME/.config/nvim"
else
  CONFIG_DIR="$XDG_CONFIG_HOME/nvim"
fi

LUA_DIR="$CONFIG_DIR/lua/config"
FILE_NAME="sticky-notes.lua"

echo "Installing to: $CONFIG_DIR"

# Create directories
mkdir -p "$LUA_DIR"

# Download the file
echo "Downloading sticky-notes.lua..."
curl -fsSL -o "$LUA_DIR/$FILE_NAME" \
  "https://raw.githubusercontent.com/YOUR_USERNAME/nvim-sticky-notes/main/sticky-notes.lua"

# Check if download was successful
if [ ! -f "$LUA_DIR/$FILE_NAME" ]; then
  echo "❌ Failed to download sticky-notes.lua"
  exit 1
fi

echo "✅ Sticky notes file installed"

# Add require and keybinds to init.lua
INIT_FILE="$CONFIG_DIR/init.lua"

if [ -f "$INIT_FILE" ]; then
  echo "Adding require and keybinds to init.lua..."

  # Check if already installed
  if grep -q "sticky-notes" "$INIT_FILE"; then
    echo "⚠️  Sticky notes already configured in init.lua"
  else
    cat >> "$INIT_FILE" << EOF

-- ================================================
-- STICKY NOTES
-- ================================================
require("config.sticky-notes").setup()

-- Keybinds (you can change them)
vim.keymap.set("n", "<leader>mn", function() require("config.sticky-notes").open_split_sticky_note() end, { desc = "Open Sticky Note" })
vim.keymap.set("n", "<leader>ms", function() require("config.sticky-notes").toggle_sticky_note_picker() end, { desc = "Browse Sticky Notes" })
EOF
    echo "✅ Keybinds and setup added to init.lua"
  fi
else
  echo "⚠️  init.lua not found. Creating basic one..."
  mkdir -p "$CONFIG_DIR"
  cat > "$INIT_FILE" << EOF
-- Basic init.lua with Sticky Notes
require("config.sticky-notes").setup()

vim.keymap.set("n", "<leader>mn", function() require("config.sticky-notes").open_split_sticky_note() end, { desc = "Open Sticky Note" })
vim.keymap.set("n", "<leader>ms", function() require("config.sticky-notes").toggle_sticky_note_picker() end, { desc = "Browse Sticky Notes" })

print("Sticky Notes installed!")
EOF
fi

echo ""
echo "🎉 Installation completed!"
echo ""
echo "Usage:"
echo "   <leader>mn   → Open sticky note for current project"
echo "   <leader>w    → Save & close"
echo "   <leader>ms   → Browse all notes"
echo ""
echo "Restart Neovim and enjoy!"
