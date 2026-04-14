--- sticky-notes.nvim
--- GitHub: https://github.com/Sou1lah/StickyNotes.nvim

local M = {}

local uv = vim.uv or vim.loop
local notes_dir = vim.fn.stdpath("data") .. "/sticky-notes"
vim.fn.mkdir(notes_dir, "p")

--- Convert path to safe filename
local function get_filename(cwd)
  cwd = cwd or uv.cwd() or vim.fn.getcwd()
  return cwd:gsub("[^%w%._-]", "_"):gsub("__+", "_")
end

--- Get custom title from first line if it starts with #
local function get_custom_title(filepath)
  if vim.fn.filereadable(filepath) == 0 then
    return nil
  end
  local first_line = vim.fn.readfile(filepath, "", 1)[1] or ""
  return first_line:match("^#%s+(.*)") and first_line:match("^#%s+(.*)"):gsub("^%s+", ""):gsub("%s+$", "")
end

--- Open Note Window
local function open_note(file, display_name)
  local lines = vim.fn.filereadable(file) == 1 and vim.fn.readfile(file) or {
    "# " .. (display_name or "New Note"),
    "",
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
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

  local title = get_custom_title(file) or display_name or "Sticky Note"
  local width = math.floor(vim.o.columns * 0.68)
  local height = math.floor(vim.o.lines * 0.58)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
  })

  --- Statusline/Footer logic: path + word count
  local function update_footer()
    if not vim.api.nvim_win_is_valid(win) then return end

    local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local words = 0
    for _, line in ipairs(content) do
      for _ in line:gmatch("%S+") do words = words + 1 end
    end

    local path_str = vim.fn.fnamemodify(file, ":~") -- Shorten home to ~
    local word_str = "Words: " .. words
    local win_w = vim.api.nvim_win_get_width(win)

    local padding_len = win_w - #path_str - #word_str - 4

    if padding_len < 2 then
      path_str = vim.fn.pathshorten(path_str)   -- Shorten path if it's too long
      padding_len = win_w - #path_str - #word_str - 4
    end

    local padding = string.rep(" ", math.max(1, padding_len))
    local footer_text = " " .. path_str .. padding .. word_str .. " "

    vim.api.nvim_win_set_config(win, {
      footer = footer_text,
      footer_pos = "left",
    })
  end

  local function save()
    pcall(vim.fn.writefile, vim.api.nvim_buf_get_lines(buf, 0, -1, false), file)
  end

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufLeave" }, {
    buffer = buf,
    callback = save,
  })

  update_footer()
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "CursorMoved" }, {
    buffer = buf,
    callback = update_footer,
  })

  local function close()
    pcall(vim.api.nvim_win_close, win, true)
  end

  vim.keymap.set("n", "q", close, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, silent = true })

  vim.keymap.set("i", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    if line:match("^%s*%- %[[^%]]*%]") then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>- [ ] ", true, true, true), "n", false)
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, true, true), "n", false)
    end
  end, { buffer = buf, noremap = true, silent = true })

  vim.keymap.set("n", "<Tab>", function()
    local line = vim.api.nvim_get_current_line()
    local toggled = line:gsub("%[[ x]%]", function(m)
      return m == "[ ]" and "[x]" or "[ ]"
    end, 1)
    vim.api.nvim_set_current_line(toggled)
  end, { buffer = buf, silent = true })
end

--- Picker
function M.toggle_picker()
  local files = vim.fn.globpath(notes_dir, "*.md", false, true)
  if #files == 0 then
    vim.notify("No notes yet. Create one with <leader>mn", vim.log.levels.INFO)
    return
  end

  local items = {}
  for _, file in ipairs(files) do
    local stat = uv.fs_stat(file)
    local modified = stat and os.date("%Y-%m-%d %H:%M", stat.mtime.sec) or "Unknown"
    local path_name = vim.fn.fnamemodify(file, ":t:r"):gsub("_", "/")
    local custom = get_custom_title(file)
    local display = custom and (custom .. "  →  " .. path_name) or path_name

    table.insert(items, {
      file = file,
      display = display,
      path_name = path_name,
      modified = modified,
    })
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.50)
  local height = 22

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Sticky Notes ",
    title_pos = "center",
  })

  local filtered = vim.deepcopy(items)
  local selected = 1
  local show_help = false

  local function render()
    if not vim.api.nvim_buf_is_valid(buf) then return end
    vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
    local lines = {}

    table.insert(lines, "  Note" .. string.rep(" ", width - 28) .. "Last Modified")
    table.insert(lines, string.rep("─", width - 2))

    for i, item in ipairs(filtered) do
      local prefix = (i == selected) and " → " or "    "
      local name = item.display
      local date = item.modified

      local max_len = width - #date - 12
      if #name > max_len then
        name = name:sub(1, max_len - 3) .. "..."
      end

      local padding = width - #prefix - #name - #date - 3
      table.insert(lines, prefix .. name .. string.rep(" ", padding) .. date)
    end

    while #lines < height - 4 do
      table.insert(lines, "")
    end

    table.insert(lines, string.rep("─", width - 2))
    if show_help then
      table.insert(lines, "  ↑↓/jk  <CR> Open   d Delete   r Rename   / Search   ? Help   q Quit")
    else
      table.insert(lines, "  Press ? for shortcuts")
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

    vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
    if #filtered > 0 then
      vim.api.nvim_buf_add_highlight(buf, 0, "Visual", selected + 1, 0, -1)
    end
  end

  render()

  local function close()
    pcall(vim.api.nvim_win_close, win, true)
  end

  local function move(delta)
    selected = math.max(1, math.min(#filtered, selected + delta))
    render()
  end

  vim.keymap.set("n", "j", function() move(1) end, { buffer = buf, silent = true })
  vim.keymap.set("n", "k", function() move(-1) end, { buffer = buf, silent = true })
  vim.keymap.set("n", "<CR>", function()
    if filtered[selected] then
      close()
      open_note(filtered[selected].file, filtered[selected].path_name)
    end
  end, { buffer = buf, silent = true })

  vim.keymap.set("n", "q", close, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, silent = true })

  vim.keymap.set("n", "r", function()
    if not filtered[selected] then return end
    local old_file = filtered[selected].file
    vim.ui.input({
      prompt = "Rename Note Title: ",
      default = get_custom_title(old_file) or filtered[selected].path_name,
    }, function(new_name)
      if not new_name or new_name == "" then return end
      local content = vim.fn.readfile(old_file)
      content[1] = "# " .. new_name
      vim.fn.writefile(content, old_file)
      close()
      M.toggle_picker()
    end)
  end, { buffer = buf, silent = true })

  vim.keymap.set("n", "d", function()
    if not filtered[selected] then return end
    vim.ui.select({ "Yes", "No" }, { prompt = "Delete this note?" }, function(choice)
      if choice == "Yes" then
        vim.fn.delete(filtered[selected].file)
        close()
        M.toggle_picker()
      end
    end)
  end, { buffer = buf, silent = true })

  vim.keymap.set("n", "/", function()
    vim.ui.input({ prompt = "Search: " }, function(input)
      if input then
        filtered = vim.tbl_filter(function(item)
          return item.display:lower():find(input:lower(), 1, true)
        end, items)
        selected = 1
        render()
      end
    end)
  end, { buffer = buf, silent = true })

  vim.keymap.set("n", "?", function()
    show_help = not show_help
    render()
  end, { buffer = buf, silent = true })
end

--- Public API
function M.open()
  local cwd = uv.cwd() or vim.fn.getcwd()
  local filename = get_filename(cwd)
  local filepath = notes_dir .. "/" .. filename .. ".md"
  open_note(filepath, vim.fn.fnamemodify(cwd, ":t"))
end

--- New Daily Note Function
function M.open_daily()
  local date = os.date("%Y-%m-%d")
  local filepath = notes_dir .. "/" .. date .. ".md"
  open_note(filepath, "Daily Note: " .. date)
end

function M.setup(opts)
  opts = opts or {}

  vim.api.nvim_create_user_command("StickyNote", M.open, {})
  vim.api.nvim_create_user_command("StickyNoteDaily", M.open_daily, {})
  vim.api.nvim_create_user_command("StickyNotePicker", M.toggle_picker, {})

  if opts.keymaps ~= false then
    vim.keymap.set("n", "<leader>mn", M.open, { desc = "Open Sticky Note" })
    vim.keymap.set("n", "<leader>md", M.open_daily, { desc = "Open Daily Note" })
    vim.keymap.set("n", "<leader>ms", M.toggle_picker, { desc = "Sticky Notes Picker" })
  end
end

return M
