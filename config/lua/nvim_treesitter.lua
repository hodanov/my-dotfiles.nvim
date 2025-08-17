require("nvim-treesitter.configs").setup({
	ensure_installed = { "go", "python", "markdown", "markdown_inline" },
	highlight = {
		enable = true,
		-- disable = { "go", "python" },
		-- TODO: neovim 0.11.4リリース後にコメントアウトする。
		-- markdown編集時に下記のエラーが発生するため一時的に無効にしている。
		-- Error executing lua: ...al/share/nvim/runtime/lua/vim/treesitter/highlighter.lua:370: Invalid 'end_col': out of range
		-- 関連issue: https://github.com/neovim/neovim/issues/29550
		disable = function(lang, _)
			return lang == "markdown" or lang == "markdown_inline"
		end,
		additional_vim_regex_highlighting = { markdown = true },
	},
})
