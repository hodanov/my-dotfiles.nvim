local null_ls = require("null-ls")

-- ------------------------------
-- Autoformat settings.
-- https://github.com/jose-elias-alvarez/null-ls.nvim/wiki/Formatting-on-save
-- https://github.com/jose-elias-alvarez/null-ls.nvim/wiki/Avoiding-LSP-formatting-conflicts
-- ------------------------------
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local lsp_formatting = function(bufnr)
    vim.lsp.buf.format({
        timeout_ms = 5000,
        filter = function(client)
            return client.name == "null-ls"
        end,
        bufnr = bufnr,
    })
end

-- ------------------------------
-- null_ls setup.
-- ------------------------------
null_ls.setup({
    sources = {
        null_ls.builtins.formatting.shfmt,
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.formatting.prettier,
        null_ls.builtins.formatting.goimports,
        null_ls.builtins.formatting.black.with({
            extra_args = { "--fast", "--line-length=120" },
        }),
        null_ls.builtins.formatting.isort,
    },
    on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = augroup,
                buffer = bufnr,
                callback = function()
                  lsp_formatting(bufnr)
                end,
            })
        end
    end,
})
