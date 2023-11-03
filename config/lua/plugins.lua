-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- File manager
  use 'lambdalisue/fern.vim'

  -- Color schema
  use 'catppuccin/nvim'

  -- Appearance
  use 'lukas-reineke/indent-blankline.nvim'
  use 'nvim-lualine/lualine.nvim'
  use 'lewis6991/gitsigns.nvim'

  -- Configurations for Nvim LSP
  use 'neovim/nvim-lspconfig'

  -- Formatt and lint runner
  use 'nvim-lua/plenary.nvim'
  use 'nvimtools/none-ls.nvim'

  -- Auto completion
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/vim-vsnip'

  -- Debug Adapter Protocol
  use 'mfussenegger/nvim-dap'

  -- Debug Adapter
  use 'leoluz/nvim-dap-go'

  -- GitHub Copilot
  use 'github/copilot.vim'

end)
