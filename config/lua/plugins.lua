-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- File manager
  use 'lambdalisue/fern.vim'

  -- Color schema
  use 'Morhetz/gruvbox'
  use 'sainnhe/gruvbox-material'
  use 'catppuccin/nvim'

  -- Appearance
  use 'nathanaelkane/vim-indent-guides'
  use 'airblade/vim-gitgutter'
  use 'vim-airline/vim-airline'
  use 'vim-airline/vim-airline-themes'

  -- LSP
  use 'neovim/nvim-lspconfig' -- Configurations for Nvim LSP

  -- Formatt and lint runner
  use 'nvim-lua/plenary.nvim'
  use 'jose-elias-alvarez/null-ls.nvim'

  -- Auto completion
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/vim-vsnip'

  -- Debug Adapter Protocol
  use 'mfussenegger/nvim-dap'

  -- Debug Adapter
  use 'leoluz/nvim-dap-go'

  -- Debugger
  use 'sebdah/vim-delve'

end)
