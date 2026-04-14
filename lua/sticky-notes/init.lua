--- sticky-notes.nvim
--- Expertly crafted for a clean, productive workflow.

local M = {}
local uv = vim.uv or vim.loop
local notes_dir = vim.fn.stdpath("data") .. "/sticky-notes"
vim.fn.mkdir(notes_dir, "p")

-- ----------------------------------------------------------------------------
-- 1. Helpers & Internal Logic
-- ----------------------------------------------------------------------------

local function get_filename(cwd)
  cwd = cwd or uv.cwd() or vim.fn.getcwd()
  return cwd:gsub("[^%w%._-]", "_"):gsub("__+", "_")
end

local function get_custom_title(filepath)
  if vim.fn.filereadable(filepath) == 0 then return nil end
  local first_line = vim.fn.readfile(filepath, "", 1)[1] or ""
  return first_line:match("^#%s+(.*)") and first_line:match("^#%s+(.*)"):gsub("^%s+", ""):gsub("%s+$", "")
end

local function inject_timestamp(buf)
  local time = os.date("%H:%M")
  local str = string.format("[%s] ", time)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_text(buf, row - 1, col, row - 1, col, { str })
  vim.api.nvim_win_set_cursor(0, { row, col + #str })
end

-- ----------------------------------------------------------------------------
-- 2. Core Note Window
-- ----------------------------------------------------------------------------

local function open_note(file, display_name)
  -- Minimal Template
  local lines = vim.fn.filereadable(file) == 1 and vim.fn.readfile(file) or {
    "# " .. (display_name or "New Note"),
    "",
    "- [ ] ",
    "",
  }

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Buffer Settings
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

  -- Window Dimensions
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
    title = " 󰠮 " .. (display_name or "Sticky Note") .. " ",
    title_pos = "center",
  })

  -- Visual Polish: Hyprland-style transparency and line numbers
  vim.wo[win].winblend = 10
  vim.wo[win].number = true
  vim.wo[win].relativenumber = true

  -- Placeholder Logic
  local ns_id = vim.api.nvim_create_namespace("sticky_placeholder")
  local function update_ui()
    if not vim.api.nvim_buf_is_valid(buf) then return end

    -- Placeholder
    vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
    local target_line = vim.api.nvim_buf_get_lines(buf, 2, 3, false)[1] or ""
    if #target_line <= 6 then -- Length of "- [ ] "
      vim.api.nvim_buf_set_extmark(buf, ns_id, 2, 6, {
        virt_text = { { "  Type your first task...", "Comment" } },
        virt_text_pos = "overlay",
      })
    end

    -- Footer
    local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local words = 0
    for _, line in ipairs(content) do
      for _ in line:gmatch("%S+") do words = words + 1 end
    end
    local path_str = vim.fn.fnamemodify(file, ":~")
    local word_str = "Words: " .. words
    local win_w = vim.api.nvim_win_get_width(win)
    local padding = string.rep(" ", math.max(1, win_w - #path_str - #word_str - 4))

    pcall(vim.api.nvim_win_set_config, win, {
      footer = " " .. path_str .. padding .. word_str .. " ",
      footer_pos = "left",
    })
  end

  -- Auto-save
  local function save()
    pcall(vim.fn.writefile, vim.api.nvim_buf_get_lines(buf, 0, -1, false), file)
  end

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufLeave" }, {
    buffer = buf,
    callback = function()
      save(); update_ui()
    end,
  })

  -- Keymaps inside the Note
  local function close() pcall(vim.api.nvim_win_close, win, true) end
  vim.keymap.set("n", "q", close, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, silent = true })
  vim.keymap.set("n", "<leader>tt", function() inject_timestamp(buf) end, { buffer = buf, desc = "Insert TSR Timestamp" })

  -- Smart checkbox Enter
  vim.keymap.set("i", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    if line:match("^%s*%- %[[^%]]*%]") then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>- [ ] ", true, true, true), "n", false)
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, true, true), "n", false)
    end
  end, { buffer = buf, noremap = true, silent = true })

  -- Toggle Checkbox
  vim.keymap.set("n", "<Tab>", function()
    local line = vim.api.nvim_get_current_line()
    local toggled = line:gsub("%[[ x]%]", function(m) return m == "[ ]" and "[x]" or "[ ]" end, 1)
    vim.api.nvim_set_current_line(toggled)
  end, { buffer = buf, silent = true })

  update_ui()
end

-- ----------------------------------------------------------------------------
-- 3. Public API & Telescope
-- ----------------------------------------------------------------------------

function M.telescope_notes()
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    vim.notify("Telescope not found!", vim.log.levels.ERROR)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new({}, {
    prompt_title = "Sticky Notes Explorer",
    finder = finders.new_oneshot_job({ "ls", notes_dir }, {}),
    sorter = conf.generic_sorter({}),
    previewer = conf.file_previewer({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          local full_path = notes_dir .. "/" .. selection[1]
          open_note(full_path, selection[1]:gsub("%.md$", ""))
        end
      end)
      return true
    end,
  }):find()
end

function M.open()
  local cwd = uv.cwd() or vim.fn.getcwd()
  local filepath = notes_dir .. "/" .. get_filename(cwd) .. ".md"
  open_note(filepath, vim.fn.fnamemodify(cwd, ":t"))
end

function M.open_daily()
  local date = os.date("%Y-%m-%d")
  local filepath = notes_dir .. "/" .. date .. ".md"
  open_note(filepath, "Daily: " .. date)
end

function M.setup(opts)
  opts = opts or {}

  vim.api.nvim_create_user_command("StickyNote", M.open, {})
  vim.api.nvim_create_user_command("StickyNoteDaily", M.open_daily, {})
  vim.api.nvim_create_user_command("StickyNoteSearch", M.telescope_notes, {})

  if opts.keymaps ~= false then
    vim.keymap.set("n", "<leader>mn", M.open, { desc = "Open Context Note" })
    vim.keymap.set("n", "<leader>md", M.open_daily, { desc = "Open Daily Note" })
    vim.keymap.set("n", "<leader>ms", M.telescope_notes, { desc = "Search Sticky Notes" })
  end
end

return M
