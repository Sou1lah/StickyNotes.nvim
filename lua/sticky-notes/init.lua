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

  -- Update word count on status line
  local function update_word_count()
    local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local word_count = 0
    for _, line in ipairs(content) do
      word_count = word_count + #vim.split(line, "%s+")
    end
    vim.api.nvim_buf_set_option(buf, "statusline", " Words: " .. word_count .. " ")
  end

  update_word_count()
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = buf,
    callback = update_word_count,
  })
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
    local stat = vim.loop.fs_stat(file)
    local modified = stat and os.date("%Y-%m-%d %H:%M", stat.mtime.sec) or "Unknown"
    local content = vim.fn.readfile(file)
    local word_count = 0
    for _, line in ipairs(content) do
      word_count = word_count + #vim.split(line, "%s+")
    end

    table.insert(items, {
      file = file,
      name = vim.fn.fnamemodify(file, ":t:r"):gsub("_", "/"),
      modified = modified,
      word_count = word_count,
    })
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local win_width = 80
  local win_height = math.min(#items + 5, 20)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = math.floor((vim.o.lines - win_height) / 2),
    col = math.floor((vim.o.columns - win_width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Sticky Notes ",
    title_pos = "center",
  })

  local lines = {}
  table.insert(lines, "? for keybinds")
  table.insert(lines, "")
  for i, item in ipairs(items) do
    local display = string.format("%d. %-35s %10s  %s", i, item.name, item.modified, item.word_count .. "w")
    table.insert(lines, display)
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  local selected_idx = nil

  local function show_keybinds()
    vim.notify(
      "Keybinds:\n" ..
      "1-9: Open note\n" ..
      "r: Rename\n" ..
      "d: Delete\n" ..
      "?: Show this help\n" ..
      "q/<Esc>: Close",
      vim.log.levels.INFO
    )
  end

  local function rename_note()
    if not selected_idx then
      vim.notify("Select a note first", vim.log.levels.WARN)
      return
    end
    local item = items[selected_idx]
    vim.ui.input({ prompt = "New name: ", default = item.name }, function(new_name)
      if new_name and new_name ~= item.name then
        local new_safe_name = new_name:gsub("[^%w%._-]", "_"):gsub("__+", "_")
        local new_file = sticky_dir .. "/" .. new_safe_name .. ".md"
        local success, err = pcall(function()
          vim.fn.rename(item.file, new_file)
        end)
        if success then
          vim.notify("Renamed to: " .. new_name, vim.log.levels.INFO)
          vim.api.nvim_win_close(win, true)
          M.toggle_sticky_note_picker()
        else
          vim.notify("Failed to rename: " .. tostring(err), vim.log.levels.ERROR)
        end
      end
    end)
  end

  local function delete_note()
    if not selected_idx then
      vim.notify("Select a note first", vim.log.levels.WARN)
      return
    end
    local item = items[selected_idx]
    vim.ui.select({ "Yes", "No" }, {
      prompt = "Delete " .. item.name .. "?",
    }, function(choice)
      if choice == "Yes" then
        local success, err = pcall(function()
          vim.fn.delete(item.file)
        end)
        if success then
          vim.notify("Deleted: " .. item.name, vim.log.levels.INFO)
          vim.api.nvim_win_close(win, true)
          M.toggle_sticky_note_picker()
        else
          vim.notify("Failed to delete: " .. tostring(err), vim.log.levels.ERROR)
        end
      end
    end)
  end

  local function open_selected()
    if selected_idx then
      local item = items[selected_idx]
      vim.api.nvim_win_close(win, true)
      open_note_in_float(item.file, item.name)
    end
  end

  -- Keymaps
  for i = 1, 9 do
    vim.keymap.set("n", tostring(i), function()
      if i <= #items then
        selected_idx = i
        open_selected()
      end
    end, { buffer = buf, silent = true })
  end

  vim.keymap.set("n", "r", rename_note, { buffer = buf, silent = true })
  vim.keymap.set("n", "d", delete_note, { buffer = buf, silent = true })
  vim.keymap.set("n", "?", show_keybinds, { buffer = buf, silent = true })
  vim.keymap.set("n", "<CR>", open_selected, { buffer = buf, silent = true })
  vim.keymap.set("n", "q", function() vim.api.nvim_win_close(win, true) end, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", function() vim.api.nvim_win_close(win, true) end, { buffer = buf, silent = true })
  vim.keymap.set("n", "j", function()
    if selected_idx and selected_idx < #items then
      selected_idx = selected_idx + 1
    elseif not selected_idx and #items > 0 then
      selected_idx = 1
    end
  end, { buffer = buf, silent = true })
  vim.keymap.set("n", "k", function()
    if selected_idx and selected_idx > 1 then
      selected_idx = selected_idx - 1
    end
  end, { buffer = buf, silent = true })
end

-- Setup
function M.setup(opts)
  opts = opts or {}

  vim.api.nvim_create_user_command("StickyNote", M.open_split_sticky_note, {})
  vim.api.nvim_create_user_command("StickyNotePicker", M.toggle_sticky_note_picker, {})

  if opts.keymaps ~= false then
    vim.keymap.set("n", "<leader>mn", M.open_split_sticky_note, { desc = "Open Sticky Note" })
    vim.keymap.set("n", "<leader>ms", M.toggle_sticky_note_picker, { desc = "Sticky Notes Picker" })
  end
end

return M
