return {
	name = "remark",
	cmd = { "remark-language-server", "--stdio" },
	filetypes = { "markdown" },
	root_markers = { ".remarkrc", ".remarkrc.yml", ".remarkrc.yaml", ".remarkrc.json", ".git" },
	settings = {
		remark = {
			requireConfig = false,
			format = false,
			lint = true,
		},
	},
	capabilities = vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), {
		workspace = {
			didChangeConfiguration = {
				dynamicRegistration = true,
			},
		},
	}),
	on_attach = function(client, bufnr)
		-- Desable formatter.
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentRangeFormattingProvider = false
	end,
}
