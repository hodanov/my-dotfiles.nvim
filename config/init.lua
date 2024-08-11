-- ----------------------------------------
-- Key bind and other setting.
-- ----------------------------------------
vim.opt.encoding = "utf-8" -- Prevent garbled characters
vim.opt.fileencoding = "utf-8" -- Setting for handling multi byte characters
vim.scriptencoding = "utf-8" -- Setting for handling multi byte characters
vim.opt.number = true -- Add row number
vim.opt.title = true -- Add a filename to each tabs
vim.opt.cursorline = true -- Add cursor line
vim.opt.tabstop = 4 -- Insert spaces when the tab key is pressed
vim.opt.shiftwidth = 4 -- Change the number of spaces inserted for indentation
-- vim.opt.softtabstop = 4 -- Make spaces feel like real tabs
vim.opt.expandtab = true -- Convert tabs to spaces
vim.opt.smartindent = true -- Add a new line with autoindent
vim.opt.colorcolumn = "120" -- Add a color on 80'th column
vim.opt.hlsearch = true -- Highlight searched characters
vim.opt.incsearch = true -- Highlight when inputting chars
vim.opt.wildmenu = true -- Show completion suggestions at command line mode
vim.opt.conceallevel = 0 -- Show double quotations in json file and so on.
vim.g.mapleader = " " -- Set a space key to a leader.
vim.opt.mouse = "" -- Don't use a mouse.
vim.opt.signcolumn = "yes" -- Always show signcolumn to prevent rattling.

-- ----------------------------------------
-- Remove unnecessary spaces at the end of line.
-- ----------------------------------------
vim.api.nvim_create_augroup("auto_remove_unnecessary_spaces_at_the_end_of_line", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
	group = "auto_remove_unnecessary_spaces_at_the_end_of_line",
	pattern = "*",
	command = [[%s/\s\+$//e]],
})

-- ----------------------------------------
-- Copy to the system clipboard.
-- ----------------------------------------
if vim.fn.has("clipboard") == 1 then
	vim.opt.clipboard = "unnamed"
end

-- ----------------------------------------
-- Remember a history of undo/redo.
-- ----------------------------------------
if vim.fn.has("persistent_undo") == 1 then
	local undo_path = vim.fn.expand("~/.vim/undo/")
	vim.cmd("set undodir=" .. undo_path)
	vim.opt.undofile = true
end

-- ----------------------------------------
-- Settings for indent each files.
-- ----------------------------------------
vim.api.nvim_create_augroup("html_css_js_and_others_indent", { clear = true })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	group = "html_css_js_and_others_indent",
	pattern = { "*.yml", "*.yaml", "*.tmpl", "*json" },
	command = "set tabstop=2 shiftwidth=2",
})
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	group = "html_css_js_and_others_indent",
	pattern = { "*.html", "*.css", "*.js", "*.ts", "*.php" },
	command = "set tabstop=2 shiftwidth=2",
})
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	group = "html_css_js_and_others_indent",
	pattern = "*.go",
	command = "set noexpandtab tabstop=8 shiftwidth=8",
})

-- ----------------------------------------
-- Open init.vim and 'source' it.
-- ----------------------------------------
vim.api.nvim_set_keymap("n", "<Leader>.", ":vs ~/.config/nvim/init.lua<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<Leader>s", ":source ~/.config/nvim/init.lua<CR>", { noremap = true, silent = true })

-- ----------------------------------------
-- Clear highlighted characters.
-- ----------------------------------------
vim.api.nvim_set_keymap("n", "<C-[><C-[>", ":nohlsearch<CR>", { noremap = true, silent = true })

-- ----------------------------------------
-- vimshell setting.
-- ----------------------------------------
if vim.fn.has("nvim") == 1 then
	vim.api.nvim_set_keymap("n", "<Leader>-", ":split term://bash<CR>", { noremap = true, silent = true })
	vim.api.nvim_set_keymap("n", "<Leader>l", ":vsplit term://bash<CR>", { noremap = true, silent = true })
else
	vim.api.nvim_set_keymap(
		"n",
		"<Leader>-",
		":below terminal ++close ++rows=13 bash<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_set_keymap("n", "<Leader>l", ":vertical terminal ++close bash<CR>", { noremap = true, silent = true })
end

-- ----------------------------------------
-- indent_guides setting.
-- ----------------------------------------
vim.g.indent_guides_enable_on_vim_startup = 1
vim.g.indent_guides_start_level = 2
vim.g.indent_guides_guide_size = 1

-- ----------------------------------------
-- fern.vim setting.
-- ----------------------------------------
vim.api.nvim_set_keymap(
	"n",
	"<Leader>o",
	":Fern . -drawer -reveal=% -width=30 -toggle<CR>",
	{ noremap = true, silent = true }
)
vim.api.nvim_set_var("fern#default_hidden", 1)

-- ----------------------------------------
-- Setting transparent background.
-- ----------------------------------------
vim.cmd([[
  highlight Normal guibg=none
  highlight NonText guibg=none
  highlight Normal ctermbg=none
  highlight NonText ctermbg=none
  highlight NormalNC guibg=none
  highlight NormalSB guibg=none
]])

-- ----------------------------------------
-- lazy.nvim setting.
-- ----------------------------------------
require("lazy_nvim")
