-- ============================================================================
-- STICKY NOTES PLUGIN (Fixed Size Picker + Bottom Right Word Count)
-- ============================================================================
local M = {}

local sticky_dir = vim.fn.stdpath("data") .. "/sticky-notes"
vim.fn.mkdir(sticky_dir, "p")

local function get_safe_name(cwd)
  cwd = cwd or vim.loop.cwd() or vim.fn.getcwd()
  return cwd:gsub("[^%w%._-]", "_"):gsub("__+", "_")
end

-- ====================== Note Window ======================
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

  -- Auto save
  local function save()
    local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    pcall(vim.fn.writefile, content, file)
  end

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufLeave" }, {
    buffer = buf,
    callback = save,
  })

  -- Close
  local function close()
    pcall(vim.api.nvim_win_close, win, true)
  end

  vim.keymap.set("n", "q", close, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, silent = true })

  -- Smart checkbox Enter
  vim.keymap.set("i", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    if line:match("^%s*%- %[[^%]]*%]") then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>- [ ] ", true, true, true), "n", false)
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, true, true), "n", false)
    end
  end, { buffer = buf, noremap = true, silent = true })

  -- Tab to toggle checkbox
  vim.keymap.set("n", "<Tab>", function()
    local line = vim.api.nvim_get_current_line()
    local toggled = line:gsub("%[[ x]%]", function(m)
      return m == "[ ]" and "[x]" or "[ ]"
    end)
    vim.api.nvim_set_current_line(toggled)
  end, { buffer = buf, silent = true })

  -- Word count in bottom right
  local function update_word_count()
    local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local count = 0
    for _, line in ipairs(content) do
      count = count + #vim.split(line, "%s+")
    end
    -- Right aligned word count
    vim.wo[win].statusline = "%= Words: " .. count .. " "
  end

  update_word_count()
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = buf,
    callback = update_word_count,
  })
end

-- ====================== Fixed Size Picker ======================
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
    local name = vim.fn.fnamemodify(file, ":t:r"):gsub("_", "/")

    table.insert(items, {
      file = file,
      name = name,
      modified = modified,
    })
  end

  -- Fixed size picker
  local buf = vim.api.nvim_create_buf(false, true)
  local win_width = 80
  local win_height = 16

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

  local filtered = vim.deepcopy(items)
  local search = ""
  local selected = 1

  local function format_item(item)
    local line = item.name
    if #line > 45 then line = line:sub(1, 42) .. "..." end
    return line .. string.rep(" ", 50 - #line) .. item.modified
  end

  local function render()
    local lines = {}
    for i, item in ipairs(filtered) do
      local prefix = (i == selected) and "→ " or "  "
      table.insert(lines, prefix .. format_item(item))
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end

  render()

  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")

  local function close()
    pcall(vim.api.nvim_win_close, win, true)
  end

  -- Keymaps
  vim.keymap.set("n", "q", close, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, silent = true })
  vim.keymap.set("n", "<CR>", function()
    if filtered[selected] then
      close()
      open_note_in_float(filtered[selected].file, filtered[selected].name)
    end
  end, { buffer = buf, silent = true })

  vim.keymap.set("n", "j", function()
    if selected < #filtered then
      selected = selected + 1; render()
    end
  end, { buffer = buf, silent = true })

  vim.keymap.set("n", "k", function()
    if selected > 1 then
      selected = selected - 1; render()
    end
  end, { buffer = buf, silent = true })

  -- Delete & Rename
  vim.keymap.set("n", "d", function()
    if not filtered[selected] then return end
    close()
    vim.ui.select({ "Yes", "No" }, { prompt = "Delete note?" }, function(choice)
      if choice == "Yes" then
        vim.fn.delete(filtered[selected].file)
        M.toggle_sticky_note_picker()
      end
    end)
  end, { buffer = buf, silent = true })

  vim.keymap.set("n", "r", function()
    if not filtered[selected] then return end
    close()
    vim.ui.input({ prompt = "New name: ", default = filtered[selected].name }, function(new_name)
      if new_name and new_name ~= filtered[selected].name then
        local new_safe = new_name:gsub("[^%w%._-]", "_"):gsub("__+", "_")
        vim.fn.rename(filtered[selected].file, sticky_dir .. "/" .. new_safe .. ".md")
        M.toggle_sticky_note_picker()
      end
    end)
  end, { buffer = buf, silent = true })

  -- Search
  vim.keymap.set("n", "/", function()
    vim.ui.input({ prompt = "Search: " }, function(input)
      if input then
        search = input
        filtered = {}
        for _, item in ipairs(items) do
          if item.name:lower():find(search:lower()) then
            table.insert(filtered, item)
          end
        end
        selected = 1
        render()
      end
    end)
  end, { buffer = buf, silent = true })
end

-- ====================== Setup ======================
function M.setup(opts)
  opts = opts or {}

  vim.api.nvim_create_user_command("StickyNote", M.open_sticky_note, {})
  vim.api.nvim_create_user_command("StickyNotePicker", M.toggle_sticky_note_picker, {})

  if opts.keymaps ~= false then
    vim.keymap.set("n", "<leader>mn", function() M.open_sticky_note() end, { desc = "Open Sticky Note" })
    vim.keymap.set("n", "<leader>ms", function() M.toggle_sticky_note_picker() end, { desc = "Sticky Notes Picker" })
  end
end

function M.open_sticky_note()
  local cwd = vim.loop.cwd() or vim.fn.getcwd()
  local safe_name = get_safe_name(cwd)
  local file = sticky_dir .. "/" .. safe_name .. ".md"
  open_note_in_float(file, vim.fn.fnamemodify(cwd, ":t"))
end

return M
