-- plugin/sticky-notes.lua
-- Entry point for native Vim packages

if vim.g.loaded_sticky_notes then
  return
end
vim.g.loaded_sticky_notes = true

local ok, sticky = pcall(require, "sticky-notes")
if ok then
  sticky.setup()
else
  vim.notify("sticky-notes.nvim: Failed to load main module", vim.log.levels.ERROR)
end
