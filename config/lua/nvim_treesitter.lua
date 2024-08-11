require("nvim-treesitter.configs").setup({
	ensure_installed = { "go", "python" },
	highlight = {
		enable = true,
		-- disable = { "go", "python" },
	},
})
