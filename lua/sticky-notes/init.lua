-- ============================================================================
-- STICKY NOTES PLUGIN (FIXED)
-- ============================================================================
local M = {}

local sticky_dir = vim.fn.stdpath("data") .. "/sticky-notes"
vim.fn.mkdir(sticky_dir, "p")

-- Better filename sanitization
local function get_safe_name(cwd)
  cwd = cwd or vim.loop.cwd() or vim.fn.getcwd()
  return cwd:gsub("[^%w%._-]", "_"):gsub("__+", "_")
end

-- Helper to open a note in floating window
local function open_note_in_float(file, title)
  local lines = vim.fn.filereadable(file) == 1 and vim.fn.readfile(file) or {
    "## Tasks",
    "- [ ] Task 1",
    "- [ ] Task 2",
    "",
    "----------------------------------------",
    "## Notes",
    "> Start typing here...",
  }

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })

  local width = math.floor(vim.o.columns * 0.65)
  local height = math.floor(vim.o.lines * 0.55)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. (title or "Sticky Note") .. " ",
    title_pos = "center",
  })

  -- Auto save with error handling
  local save = function()
    local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local success, err = pcall(function()
      vim.fn.writefile(content, file)
    end)
    if not success then
      vim.notify("Failed to save note: " .. tostring(err), vim.log.levels.ERROR)
    end
  end

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufLeave" }, {
    buffer = buf,
    callback = save,
  })

  -- Close mappings
  local function close_window()
    pcall(function() vim.api.nvim_win_close(win, true) end)
  end

  vim.keymap.set("n", "q", close_window, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", close_window, { buffer = buf, silent = true })
  vim.keymap.set("i", "<C-c>", "<Esc>", { buffer = buf, silent = true })

  -- Enter creates new checkbox line
  vim.keymap.set("i", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    if line:match("^%s*%- %[[^%]]*%]") then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>- [ ] ", true, true, true), "n", false)
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, true, true), "n", false)
    end
  end, { buffer = buf, noremap = true, silent = true })

  -- Tab toggle checkbox
  vim.keymap.set("n", "<Tab>", function()
    local line = vim.api.nvim_get_current_line()
    local toggled = line:gsub("%[[ x]%]", function(match)
      return match == "[ ]" and "[x]" or "[ ]"
    end)
    vim.api.nvim_set_current_line(toggled)
  end, { buffer = buf, silent = true })
end

-- ====================== Public API ======================

function M.open_split_sticky_note()
  local cwd = vim.loop.cwd() or vim.fn.getcwd()
  local safe_name = get_safe_name(cwd)
  local file = sticky_dir .. "/" .. safe_name .. ".md"

  open_note_in_float(file, vim.fn.fnamemodify(cwd, ":t"))
end

function M.toggle_sticky_note_picker()
  local files = vim.fn.globpath(sticky_dir, "*.md", false, true)
  if #files == 0 then
    vim.notify("No sticky notes yet. Create one with <leader>mn", vim.log.levels.INFO)
    return
  end

  local items = {}
  for _, file in ipairs(files) do
    table.insert(items, {
      file = file,
      name = vim.fn.fnamemodify(file, ":t:r"):gsub("_", "/"),
    })
  end

  vim.ui.select(items, {
    prompt = "Sticky Notes",
    format_item = function(item)
      return item.name
    end,
  }, function(choice)
    if choice then
      open_note_in_float(choice.file, choice.name)
    end
  end)
end

function M.delete_sticky_note()
  local files = vim.fn.globpath(sticky_dir, "*.md", false, true)
  if #files == 0 then
    vim.notify("Nothing to delete", vim.log.levels.WARN)
    return
  end

  local items = {}
  for _, file in ipairs(files) do
    table.insert(items, {
      file = file,
      name = vim.fn.fnamemodify(file, ":t:r"):gsub("_", "/"),
    })
  end

  vim.ui.select(items, {
    prompt = "Delete Sticky Note:",
    format_item = function(item)
      return item.name
    end,
  }, function(choice)
    if choice then
      local success, err = pcall(function()
        vim.fn.delete(choice.file)
      end)
      if success then
        vim.notify("Deleted: " .. choice.name, vim.log.levels.INFO)
      else
        vim.notify("Failed to delete: " .. tostring(err), vim.log.levels.ERROR)
      end
    end
  end)
end

-- Setup
function M.setup(opts)
  opts = opts or {}

  vim.api.nvim_create_user_command("StickyNote", M.open_split_sticky_note, {})
  vim.api.nvim_create_user_command("StickyNotePicker", M.toggle_sticky_note_picker, {})
  vim.api.nvim_create_user_command("StickyNoteDelete", M.delete_sticky_note, {})

  if opts.keymaps ~= false then
    vim.keymap.set("n", "<leader>mn", M.open_split_sticky_note, { desc = "Open Sticky Note" })
    vim.keymap.set("n", "<leader>ms", M.toggle_sticky_note_picker, { desc = "Sticky Notes Picker" })
    vim.keymap.set("n", "<leader>md", M.delete_sticky_note, { desc = "Delete Sticky Note" })
  end
end

return M
