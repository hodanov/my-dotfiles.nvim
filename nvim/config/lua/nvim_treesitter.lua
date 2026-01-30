local ts = require("nvim-treesitter")

ts.setup({
	-- install_dir = vim.fn.stdpath("data") .. "/site",
})

ts.install({ "go", "python", "markdown", "markdown_inline" })

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "go", "python", "markdown", "markdown_inline" },
	callback = function()
		-- highlight
		vim.treesitter.start()
		-- folds
		-- vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		-- vim.wo.foldmethod = "expr"
		-- indent
		-- vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
})
