-- ----------
-- telescope.nvim
-- ----------
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<Leader>ff", builtin.find_files, { desc = "Find Files" })
vim.keymap.set("n", "<Leader>fg", builtin.live_grep, { desc = "Live Grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })

-- ----------
-- telescope-file-browser.nvim
-- ----------
local telescope = require("telescope")
telescope.setup({
	defaults = {
		sorting_strategy = "ascending", -- 上から順番に表示
		file_sorter = require("telescope.sorters").get_fuzzy_file, -- アルファベット順ベース
		layout_config = {
			prompt_position = "top", -- 検索窓を上に
		},
	},
	extensions = {
		file_browser = {
			sorting_strategy = "ascending",
			layout_config = {
				prompt_position = "top",
			},
			grouped = true, -- ディレクトリを上にまとめる
		},
	},
})
telescope.load_extension("file_browser")
-- vim.keymap.set("n", "<space>fo", ":Telescope file_browser<CR>", { desc = "Telescope File Browser" })
vim.keymap.set("n", "<space>fo", function()
	require("telescope").extensions.file_browser.file_browser({
		path = "%:p:h", -- 現在開いてるファイルのディレクトリ
		select_buffer = true, -- バッファのパスを基準に
	})
end, { desc = "Telescope File Browser (current file dir)" })
