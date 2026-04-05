-- plugin/sticky-notes.lua
-- Entry point for native Vim packages

if vim.g.loaded_sticky_notes then
  return
end
vim.g.loaded_sticky_notes = true

local ok, sticky = pcall(require, "sticky-notes")
if ok and sticky and type(sticky.setup) == "function" then
  -- Only auto-setup if not loaded by Lazy.nvim
  if not vim.g.sticky_notes_lazy_loaded then
    sticky.setup()
  end
else
  vim.notify("sticky-notes.nvim: Failed to load main module", vim.log.levels.ERROR)
end

-- hey
