-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
  use { 'wbthomason/packer.nvim', opt = true }

  -- File manager
  use 'lambdalisue/fern.vim'

  -- Color schema
  use 'catppuccin/nvim'

  -- Appearance
  -- The below plugins will be loaded when reading a file.
  -- https://neovim.io/doc/user/autocmd.html#autocmd-events
  use {
    'lukas-reineke/indent-blankline.nvim',
    event = { 'BufRead', 'BufNewFile' },
  }

  use {
    'nvim-lualine/lualine.nvim',
    event = { 'BufRead', 'BufNewFile' },
    config = function() require('nvim_lualine') end,
  }

  use {
    'lewis6991/gitsigns.nvim',
    event = { 'BufRead', 'BufNewFile' },
    config = function() require('gitsigns_nvim') end,
  }

  -- Configurations for Nvim LSP
  use {
    'neovim/nvim-lspconfig',
    event = { 'BufRead', 'BufNewFile' },
    config = function() require('nvim_lspconfig') end,
  }

  -- Formatt and lint runner
  use {
    'nvimtools/none-ls.nvim',
    event = { 'BufRead', 'BufNewFile' },
    requires = {
      { 'nvim-lua/plenary.nvim', event = { 'BufRead', 'BufNewFile' } },
    },
    config = function() require('null_ls') end,
  }

  -- Auto completion
  -- The below plugins will be loaded when entering insert mode.
  use {
    'hrsh7th/nvim-cmp',
    event = { 'InsertEnter' },
    requires = {
      { 'hrsh7th/cmp-nvim-lsp', event = { 'InsertEnter' } },
      { 'hrsh7th/vim-vsnip', event = { 'InsertEnter' } },
    },
    config = function() require('nvim_cmp') end,
  }

  -- Debug Adapter Protocol
  use 'mfussenegger/nvim-dap'
  use 'leoluz/nvim-dap-go'

  -- GitHub Copilot
  use 'github/copilot.vim'

end)
