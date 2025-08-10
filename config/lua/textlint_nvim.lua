local M = {}

-- textlintの設定
local config = {
	cmd = "textlint",
	args = { "--format", "json", "--stdin", "--stdin-filename" },
	filetypes = { "markdown", "text", "plaintext" },
	debounce = 500, -- ミリ秒
}

-- デバウンス用のタイマー
local timers = {}

-- diagnosticsの名前空間を作成
local ns_id = vim.api.nvim_create_namespace("textlint")

-- textlintの結果をneovimのdiagnosticsに変換
local function parse_textlint_output(output, bufnr)
	local ok, result = pcall(vim.json.decode, output)
	if not ok or not result or not result[1] then
		return {}
	end

	local diagnostics = {}
	local messages = result[1].messages or {}

	for _, msg in ipairs(messages) do
		local diagnostic = {
			lnum = msg.line - 1, -- neovimは0-indexedなので-1
			col = msg.column - 1,
			end_lnum = msg.line - 1,
			end_col = msg.column - 1 + (msg.fix and msg.fix.range and (msg.fix.range[2] - msg.fix.range[1]) or 0),
			severity = msg.severity == 2 and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
			message = msg.message,
			source = "textlint",
			code = msg.ruleId,
		}
		table.insert(diagnostics, diagnostic)
	end

	return diagnostics
end

-- textlintを実行する関数
local function run_textlint(bufnr)
	local filename = vim.api.nvim_buf_get_name(bufnr)
	local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")

	if content == "" then
		vim.diagnostic.set(ns_id, bufnr, {})
		return
	end

	local cmd = { config.cmd }
	vim.list_extend(cmd, config.args)
	table.insert(cmd, filename)

	-- 非同期でtextlintを実行
	local job_id = vim.fn.jobstart(cmd, {
		stdin = "pipe",
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			if data and #data > 0 then
				local output = table.concat(data, "\n")
				local diagnostics = parse_textlint_output(output, bufnr)
				vim.schedule(function()
					vim.diagnostic.set(ns_id, bufnr, diagnostics)
				end)
			end
		end,
		on_stderr = function(_, data)
			if data and #data > 0 and data[1] ~= "" then
				vim.schedule(function()
					vim.notify("textlint error: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
				end)
			end
		end,
		on_exit = function(_, code)
			if code == 0 then
				-- 正常終了時、エラーがない場合は空のdiagnosticsをセット
				vim.schedule(function()
					-- stdoutで結果が返ってこない場合の処理
				end)
			end
		end,
	})

	if job_id > 0 then
		vim.fn.chansend(job_id, content)
		vim.fn.chanclose(job_id, "stdin")
	end
end

-- デバウンス付きでtextlintを実行
local function run_textlint_debounced(bufnr)
	if timers[bufnr] then
		timers[bufnr]:stop()
	end

	timers[bufnr] = vim.defer_fn(function()
		run_textlint(bufnr)
		timers[bufnr] = nil
	end, config.debounce)
end

-- バッファが閉じられた時のクリーンアップ
local function on_buffer_delete(bufnr)
	if timers[bufnr] then
		timers[bufnr]:stop()
		timers[bufnr] = nil
	end
	vim.diagnostic.set(ns_id, bufnr, {})
end

-- セットアップ関数
function M.setup(user_config)
	config = vim.tbl_extend("force", config, user_config or {})

	-- autocmdを設定
	local group = vim.api.nvim_create_augroup("TextlintNvim", { clear = true })

	vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "TextChanged", "TextChangedI" }, {
		group = group,
		pattern = "*",
		callback = function(args)
			local bufnr = args.buf
			local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

			-- 対象のfiletypeかチェック
			if vim.tbl_contains(config.filetypes, filetype) then
				run_textlint_debounced(bufnr)
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufDelete", {
		group = group,
		pattern = "*",
		callback = function(args)
			on_buffer_delete(args.buf)
		end,
	})
end

-- 手動実行用の関数
function M.lint()
	local bufnr = vim.api.nvim_get_current_buf()
	run_textlint(bufnr)
end

-- diagnosticsをクリア
function M.clear()
	local bufnr = vim.api.nvim_get_current_buf()
	vim.diagnostic.set(ns_id, bufnr, {})
end

-- 設定を変更
function M.configure(new_config)
	config = vim.tbl_extend("force", config, new_config)
end

return M
