local M = {}
local uv = vim.uv or vim.loop
local notes_dir = vim.fn.stdpath("data") .. "/sticky-notes"
vim.fn.mkdir(notes_dir, "p")

-- ----------------------------------------------------------------------------
-- 1. HELPERS & TEMPLATES
-- ----------------------------------------------------------------------------

local function get_filename(cwd)
	cwd = cwd or uv.cwd() or vim.fn.getcwd()
	return cwd:gsub("[^%w%._-]", "_"):gsub("__+", "_")
end

local function get_daily_template(display_name)
	return {
		"# " .. display_name,
		"",
		"##  To-Do",
		"- [ ] ",
		"",
		"## 󰠮 Notes",
		"",
		"---",
	}
end

-- ----------------------------------------------------------------------------
-- 2. THE CORE ENGINE
-- ----------------------------------------------------------------------------

local function open_note(file, display_name, is_daily)
	-- Ensure directory exists
	vim.fn.mkdir(vim.fn.fnamemodify(file, ":h"), "p")

	-- Load lines or use template
	local lines
	if vim.fn.filereadable(file) == 1 then
		lines = vim.fn.readfile(file)
	else
		lines = is_daily and get_daily_template(display_name) or { "# " .. display_name, "", "- [ ] ", "" }
	end

	-- Create Buffer
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

	-- Window Math
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
		title = " 󰠮 " .. display_name .. " ",
		title_pos = "center",
	})

	-- Window Styling
	vim.wo[win].winblend = 10 -- Slight transparency
	vim.wo[win].number = true
	vim.wo[win].relativenumber = true

	-- --- INTERNAL SCOPED FUNCTIONS (Capturing local variables) ---

	local function save()
		if vim.api.nvim_buf_is_valid(buf) then
			local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			pcall(vim.fn.writefile, content, file)
		end
	end

	local function update_footer()
		if not (vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_win_is_valid(win)) then
			return
		end

		local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local words = 0
		for _, l in ipairs(content) do
			for _ in l:gmatch("%S+") do
				words = words + 1
			end
		end

		local path_str = vim.fn.fnamemodify(file, ":~")
		local word_str = "Words: " .. words
		local win_w = vim.api.nvim_win_get_width(win)
		local padding = string.rep(" ", math.max(1, win_w - #path_str - #word_str - 6))

		pcall(vim.api.nvim_win_set_config, win, {
			footer = " " .. path_str .. padding .. word_str .. " ",
			footer_pos = "left",
		})
	end

	-- --- KEYMAPS ---

	-- Auto-Checkbox (Enter logic)
	vim.keymap.set("i", "<CR>", function()
		local line = vim.api.nvim_get_current_line()
		if line:match("^%s*-%s*%[%s*%]%s*") or line:match("^%s*-%s*%[x%]%s*") then
			return "<CR>- [ ] "
		else
			return "<CR>"
		end
	end, { buffer = buf, expr = true, silent = true })

	-- Toggle Checkbox status
	vim.keymap.set("n", "<Tab>", function()
		local line = vim.api.nvim_get_current_line()
		local toggled = line:gsub("%[[ x]%]", function(m)
			return m == "[ ]" and "[x]" or "[ ]"
		end, 1)
		vim.api.nvim_set_current_line(toggled)
	end, { buffer = buf, silent = true })

	-- Close controls
	local function close()
		pcall(vim.api.nvim_win_close, win, true)
	end
	vim.keymap.set("n", "q", close, { buffer = buf })
	vim.keymap.set("n", "<Esc>", close, { buffer = buf })

	-- --- AUTOMATION (Debounced Save & Footer) ---
	local timer = uv.new_timer()
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		buffer = buf,
		callback = function()
			timer:stop()
			timer:start(
				250,
				0,
				vim.schedule_wrap(function()
					save()
					update_footer()
				end)
			)
		end,
	})

	-- Final save on leave
	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = buf,
		callback = function()
			if timer and not timer:is_closing() then
				timer:stop()
				timer:close()
			end
			save()
		end,
	})

	update_footer() -- Initial UI draw
end

-- ----------------------------------------------------------------------------
-- 3. PUBLIC INTERFACE
-- ----------------------------------------------------------------------------

function M.telescope_notes()
	local ok, telescope = pcall(require, "telescope")
	if not ok then
		return vim.notify("Telescope not found", 3)
	end

	require("telescope.pickers")
		.new({}, {
			prompt_title = "Sticky Notes",
			finder = require("telescope.finders").new_oneshot_job({ "ls", notes_dir }, {}),
			sorter = require("telescope.config").values.generic_sorter({}),
			previewer = require("telescope.config").values.file_previewer({}),
			attach_mappings = function(prompt_bufnr, _)
				require("telescope.actions").select_default:replace(function()
					require("telescope.actions").close(prompt_bufnr)
					local selection = require("telescope.actions.state").get_selected_entry()
					if selection then
						open_note(
							notes_dir .. "/" .. selection[1],
							selection[1]:gsub("%.md$", ""),
							selection[1]:match("^%d%d%d%d%-%d%d%-%d%d")
						)
					end
				end)
				return true
			end,
		})
		:find()
end

function M.open()
	local cwd = uv.cwd() or vim.fn.getcwd()
	local filepath = notes_dir .. "/" .. get_filename(cwd) .. ".md"
	open_note(filepath, vim.fn.fnamemodify(cwd, ":t"), false)
end

function M.open_daily()
	local date = os.date("%Y-%m-%d")
	local filepath = notes_dir .. "/" .. date .. ".md"
	open_note(filepath, date, true)
end

function M.setup(opts)
	opts = opts or {}
	vim.api.nvim_create_user_command("StickyNote", M.open, {})
	vim.api.nvim_create_user_command("StickyNoteDaily", M.open_daily, {})
	vim.api.nvim_create_user_command("StickyNoteSearch", M.telescope_notes, {})

	if opts.keymaps ~= false then
		vim.keymap.set("n", "<leader>mn", M.open, { desc = "Project Sticky Note" })
		vim.keymap.set("n", "<leader>md", M.open_daily, { desc = "Daily Sticky Note" })
		vim.keymap.set("n", "<leader>ms", M.telescope_notes, { desc = "Search Sticky Notes" })
	end
end

return M
