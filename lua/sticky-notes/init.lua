-- ============================================================================
-- STICKY NOTES PLUGIN - Custom Names + Path in Picker
-- ============================================================================
local M = {}

local sticky_dir = vim.fn.stdpath("data") .. "/sticky-notes"
vim.fn.mkdir(sticky_dir, "p")

local function get_safe_filename(cwd)
  cwd = cwd or vim.loop.cwd() or vim.fn.getcwd()
  return cwd:gsub("[^%w%._-]", "_"):gsub("__+", "_")
end

-- Read custom title from first line of note (if exists)
local function get_custom_title(file)
  if vim.fn.filereadable(file) == 0 then return nil end
  local first_line = vim.fn.readfile(file, "", 1)[1] or ""
  if first_line:match("^#%s+") then
    return first_line:gsub("^#%s+", ""):gsub("^%s+", ""):gsub("%s+$", "")
  end
  return nil
end

-- ====================== Note Window ======================
local function open_note_in_float(file, default_title)
  local lines = vim.fn.filereadable(file) == 1 and vim.fn.readfile(file) or {
    "# " .. (default_title or "New Note"),
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

  local custom_title = get_custom_title(file) or default_title or "Sticky Note"

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
    title = " " .. custom_title .. " ",
    title_pos = "center",
  })

  -- Auto save
  local function save()
    pcall(vim.fn.writefile, vim.api.nvim_buf_get_lines(buf, 0, -1, false), file)
  end
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufLeave" }, { buffer = buf, callback = save })

  local function close() pcall(vim.api.nvim_win_close, win, true) end

  vim.keymap.set("n", "q", close, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, silent = true })

  -- Checkbox
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
    local toggled = line:gsub("%[[ x]%]", function(m) return m == "[ ]" and "[x]" or "[ ]" end)
    vim.api.nvim_set_current_line(toggled)
  end, { buffer = buf, silent = true })

  -- Word count + Path in bottom center
  local function update_status()
    local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local count = 0
    for _, line in ipairs(content) do
      for _ in line:gmatch("%S+") do count = count + 1 end
    end
    local path_hint = vim.fn.fnamemodify(file, ":t:r"):gsub("_", "/")
    vim.wo[win].statusline = "%= " .. path_hint .. "   |   Words: " .. count .. " %="
  end

  update_status()
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "CursorMoved" }, {
    buffer = buf,
    callback = update_status,
  })
end

-- ====================== Picker ======================
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
    local path_name = vim.fn.fnamemodify(file, ":t:r"):gsub("_", "/")
    local custom = get_custom_title(file)

    table.insert(items, {
      file = file,
      display = custom and (custom .. "  →  " .. path_name) or path_name,
      path_name = path_name,
      modified = modified,
    })
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local win_width = math.floor(vim.o.columns * 0.50)
  local win_height = 22

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
  local selected = 1
  local show_help = false

  local function render()
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    local lines = {}

    table.insert(lines, "  Note Name" .. string.rep(" ", 28) .. "Last Modified")
    table.insert(lines, string.rep("─", win_width - 2))

    for i, item in ipairs(filtered) do
      local prefix = (i == selected) and " → " or "   "
      local name = item.display
      if #name > 38 then name = name:sub(1, 35) .. "..." end
      local padding = win_width - #prefix - #name - #item.modified - 4
      table.insert(lines, prefix .. name .. string.rep(" ", padding) .. item.modified)
    end

    while #lines < win_height - 4 do table.insert(lines, "") end

    table.insert(lines, string.rep("─", win_width - 2))
    if show_help then
      table.insert(lines, "  ↑↓/jk : Move   <CR> : Open   d:Del   r:Ren   /:Search   ?:Help   q:Quit")
    else
      table.insert(lines, "  Press ? for shortcuts")
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)

    vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, 0, "Visual", selected + 1, 0, -1)
  end

  render()

  local function close() pcall(vim.api.nvim_win_close, win, true) end
  local function move(delta)
    selected = math.max(1, math.min(#filtered, selected + delta))
    render()
  end

  -- Keymaps
  vim.keymap.set("n", "j", function() move(1) end, { buffer = buf, silent = true })
  vim.keymap.set("n", "k", function() move(-1) end, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Down>", function() move(1) end, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Up>", function() move(-1) end, { buffer = buf, silent = true })

  vim.keymap.set("n", "<CR>", function()
    if filtered[selected] then
      close()
      open_note_in_float(filtered[selected].file, filtered[selected].path_name)
    end
  end, { buffer = buf, silent = true })

  vim.keymap.set("n", "q", close, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, silent = true })

  -- Rename with custom name (supports spaces!)
  vim.keymap.set("n", "r", function()
    if not filtered[selected] then return end
    close()
    vim.ui.input({
      prompt = "New custom name (spaces allowed): ",
      default = get_custom_title(filtered[selected].file) or filtered[selected].path_name
    }, function(new_name)
      if new_name and new_name ~= "" then
        local content = vim.fn.readfile(filtered[selected].file)
        if #content > 0 and content[1]:match("^#") then
          content[1] = "# " .. new_name
        else
          table.insert(content, 1, "# " .. new_name)
        end
        vim.fn.writefile(content, filtered[selected].file)
        M.toggle_sticky_note_picker()
      end
    end)
  end, { buffer = buf, silent = true })

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

-- Setup
function M.setup(opts)
  opts = opts or {}
  vim.api.nvim_create_user_command("StickyNote", M.open_sticky_note, {})
  vim.api.nvim_create_user_command("StickyNotePicker", M.toggle_sticky_note_picker, {})

  if opts.keymaps ~= false then
    vim.keymap.set("n", "<leader>mn", M.open_sticky_note, { desc = "Open Sticky Note" })
    vim.keymap.set("n", "<leader>ms", M.toggle_sticky_note_picker, { desc = "Sticky Notes Picker" })
  end
end

function M.open_sticky_note()
  local cwd = vim.loop.cwd() or vim.fn.getcwd()
  local safe_name = get_safe_filename(cwd)
  local file = sticky_dir .. "/" .. safe_name .. ".md"
  open_note_in_float(file, vim.fn.fnamemodify(cwd, ":t"))
end

return M
