local M = {}

local bridge_dir = os.getenv("AI_BRIDGE_DIR") or "/.ai-bridge"

local function open_prompt_editor(initial_prompt, cwd)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].filetype = "markdown"
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].swapfile = false

	local lines = vim.split(initial_prompt, "\n")
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.6)
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
		title = " Claude Code: Edit prompt then <CR> to send, <Esc> to cancel ",
		title_pos = "center",
	})

	local function submit()
		local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
		vim.api.nvim_win_close(win, true)
		vim.api.nvim_buf_delete(buf, { force = true })
		M.send_prompt(content, cwd)
	end

	local function cancel()
		vim.api.nvim_win_close(win, true)
		vim.api.nvim_buf_delete(buf, { force = true })
	end

	vim.keymap.set("n", "<CR>", submit, { buffer = buf, nowait = true })
	vim.keymap.set("n", "<Esc>", cancel, { buffer = buf, nowait = true })
end

function M.send_prompt(prompt, cwd)
	vim.fn.mkdir(bridge_dir, "p")

	local request = {
		prompt = prompt,
		cwd = cwd,
		timestamp = os.time(),
	}

	local request_file = bridge_dir .. "/request.json"
	local ok, err = pcall(function()
		local f = assert(io.open(request_file, "w"))
		f:write(vim.fn.json_encode(request))
		f:close()
	end)

	if ok then
		vim.notify("ai_bridge: sent to Claude Code", vim.log.levels.INFO)
	else
		vim.notify("ai_bridge: failed to write request: " .. tostring(err), vim.log.levels.ERROR)
	end
end

function M.send_to_claude()
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")

	if start_line == 0 or end_line == 0 then
		vim.notify("ai_bridge: no visual selection found", vim.log.levels.WARN)
		return
	end

	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	local file_path = vim.fn.expand("%:p")
	local filetype = vim.bo.filetype
	local cwd = vim.fn.getcwd()

	local initial_prompt = string.format(
		"File: %s:%d-%d (%s)\n\n```%s\n%s\n```\n",
		file_path,
		start_line,
		end_line,
		filetype,
		filetype,
		table.concat(lines, "\n")
	)

	open_prompt_editor(initial_prompt, cwd)
end

vim.keymap.set("v", "<leader>cc", function()
	local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
	vim.api.nvim_feedkeys(esc, "x", false)
	vim.schedule(function()
		M.send_to_claude()
	end)
end, { desc = "Send selection to Claude Code" })

return M
