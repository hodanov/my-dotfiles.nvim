-- ----------------------------------------
-- LSP configuration (Neovim 0.11 native style)
--
-- 参考資料
-- - https://github.com/neovim/nvim-lspconfig/tree/master/lua/lspconfig/configs
-- - https://zenn.dev/kawarimidoll/articles/b202e546bca344
-- ----------------------------------------

-- 共通設定（nvim-cmpとの連携）
vim.lsp.config('*', {
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
})

-- Go
vim.lsp.config.gopls = {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
  root_markers = { 'go.mod', 'go.work' },
}

vim.lsp.config.golangci_lint_ls = {
  cmd = { 'golangci-lint-langserver' },
  filetypes = { 'go', 'gomod' },
  init_options = {
    command = { 'golangci-lint', 'run', '--output.json.path=stdout', '--show-stats=false' },
  },
  root_dir = function(fname)
    return util.root_pattern(
      '.golangci.yml',
      '.golangci.yaml',
      '.golangci.toml',
      '.golangci.json',
      'go.work',
      'go.mod',
      '.git'
    )(fname)
  end,
}

-- TypeScript/JavaScript
vim.lsp.config.ts_ls = {
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_markers = { 'package.json', 'tsconfig.json', 'jsconfig.json' },
}

vim.lsp.config.eslint = {
  cmd = { 'vscode-eslint-language-server', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_markers = { '.eslintrc', '.eslintrc.json', '.eslintrc.js', 'eslint.config.js' },
}

-- Python
-- Enable LSP if the virtual environment is active.
if vim.env.VIRTUAL_ENV then
  vim.lsp.config.pyright = {
    cmd = { 'pyright-langserver', '--stdio' },
    filetypes = { 'python' },
    root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile' },
    settings = {
      python = {
        analysis = {
          typeCheckingMode = "basic"
        }
      }
    }
  }
  vim.lsp.config.ruff = {
    cmd = { 'ruff', 'server', '--preview' },
    filetypes = { 'python' },
    root_markers = { 'pyproject.toml', 'setup.py', 'ruff.toml' },
  }
  vim.lsp.enable('pyright')
  vim.lsp.enable('ruff')
end

vim.lsp.enable('gopls')
vim.lsp.enable('golangci_lint_ls')
vim.lsp.enable('ts_ls')
vim.lsp.enable('eslint')

-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set("n", "<space>e", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		-- Enable completion triggered by <c-x><c-o>
		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

		-- Buffer local mappings.
		-- See `:help vim.lsp.*` for documentation on any of the below functions
		local opts = { buffer = ev.buf }
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
		vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
		vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
		vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
		vim.keymap.set("n", "<space>wl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, opts)
		vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
		vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, opts)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
		vim.keymap.set("n", "<space>f", function()
			vim.lsp.buf.format({ async = true })
		end, opts)
	end,
})

-- Turn off the virtual_text
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
	virtual_text = false,
})
