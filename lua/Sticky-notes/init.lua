-- ============================================================================
-- STICKY NOTES SYSTEM
-- ============================================================================
local M = {}
local sticky_dir = vim.fn.stdpath("config") .. "/sticky_notes"

-- Ensure directory exists
vim.fn.mkdir(sticky_dir, "p")

-- Get safe filename from path
local function get_safe_name(cwd)
  return (cwd or vim.loop.cwd() or vim.fn.getcwd()):gsub("[^%w%._-]", "%%")
end

-- Auto-save on buffer changes
local function setup_autosave(buf, sticky_file)
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      vim.fn.writefile(lines, sticky_file)
      vim.notify("Sticky note saved", vim.log.levels.INFO)
    end,
  })
  vim.api.nvim_create_autocmd("TextChanged", {
    buffer = buf,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      vim.fn.writefile(lines, sticky_file)
    end,
  })
end

-- Open sticky note for current project
function M.open_split_sticky_note()
  local cwd = vim.loop.cwd() or vim.fn.getcwd()
  local safe_name = get_safe_name(cwd)
  local sticky_file = sticky_dir .. "/" .. safe_name .. ".md"

  -- Default content if file doesn't exist
  local default_content = {
    "## Tasks",
    "- [ ] Task 1",
    "- [ ] Task 2",
    "",
    "----------------------------------------",
    "## Notes",
    "> Start typing here...",
    "",
  }

  if vim.fn.filereadable(sticky_file) == 1 then
    default_content = vim.fn.readfile(sticky_file)
  end

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, default_content)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

  -- Floating window config
  local width = math.floor(vim.o.columns * 0.65)
  local height = math.floor(vim.o.lines * 0.45)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Sticky Note ",
    title_pos = "center",
  })

  vim.cmd("startinsert")

  -- Setup auto-save
  setup_autosave(buf, sticky_file)

  -- Close with Esc
  vim.keymap.set("n", "<Esc>", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, silent = true })
end

-- Browse all sticky notes
function M.toggle_sticky_note_picker()
  local files = vim.fn.globpath(sticky_dir, "*.md", false, true)
  if #files == 0 then
    vim.notify("No sticky notes found yet!", vim.log.levels.INFO)
    return
  end

  vim.ui.select(files, {
    prompt = "Select Sticky Note:",
    format_item = function(file)
      local name = vim.fn.fnamemodify(file, ":t:r")
      return name:gsub("%%", "/") -- restore readable path
    end,
  }, function(choice)
    if not choice then return end
    local lines = vim.fn.readfile(choice)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

    local width = math.floor(vim.o.columns * 0.65)
    local height = math.floor(vim.o.lines * 0.45)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = width,
      height = height,
      row = row,
      col = col,
      style = "minimal",
      border = "rounded",
      title = " Sticky Note ",
      title_pos = "center",
    })

    vim.cmd("startinsert")
    setup_autosave(buf, choice)

    -- Close with Esc
    vim.keymap.set("n", "<Esc>", function()
      vim.api.nvim_win_close(win, true)
    end, { buffer = buf, silent = true })
  end)
end

-- Delete a sticky note
function M.delete_sticky_note()
  local files = vim.fn.globpath(sticky_dir, "*.md", false, true)
  if #files == 0 then
    vim.notify("No sticky notes to delete", vim.log.levels.INFO)
    return
  end

  vim.ui.select(files, {
    prompt = "Delete Sticky Note:",
    format_item = function(file)
      local name = vim.fn.fnamemodify(file, ":t:r")
      return name:gsub("%%", "/")
    end,
  }, function(choice)
    if not choice then return end
    vim.fn.delete(choice)
    vim.notify("Sticky note deleted", vim.log.levels.INFO)
  end)
end

-- Setup function
function M.setup(opts)
  opts = opts or {}

  -- Create commands
  vim.api.nvim_create_user_command("StickyNote", M.open_split_sticky_note, {})
  vim.api.nvim_create_user_command("StickyNotePicker", M.toggle_sticky_note_picker, {})
  vim.api.nvim_create_user_command("StickyNoteDelete", M.delete_sticky_note, {})

  -- Set keymaps if not disabled
  if opts.keymaps ~= false then
    vim.keymap.set("n", "<leader>mn", M.open_split_sticky_note, { desc = "Open Sticky Note" })
    vim.keymap.set("n", "<leader>ms", M.toggle_sticky_note_picker, { desc = "Sticky Notes Picker" })
  end
end

return M
