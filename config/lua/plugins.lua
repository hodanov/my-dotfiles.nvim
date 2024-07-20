return {
  -- File manager
  'lambdalisue/fern.vim',
  { -- colorscheme
    'catppuccin/nvim',
    config = function() vim.cmd('colorscheme catppuccin-mocha') end,
  },
  { -- Appearance
    'lukas-reineke/indent-blankline.nvim',
    lazy = true,
    event = { 'BufRead', 'BufNewFile' }
  },
  { -- Appearance
    'nvim-lualine/lualine.nvim',
    lazy = true,
    event = { 'BufRead', 'BufNewFile' },
    config = function() require('nvim_lualine') end
  },
  { -- Appearance
    'lewis6991/gitsigns.nvim',
    lazy = true,
    event = { 'BufRead', 'BufNewFile' },
    config = function() require('gitsigns_nvim') end
  },
  { -- Configurations for Nvim LSP
    'neovim/nvim-lspconfig',
    lazy = true,
    event = { 'BufRead', 'BufNewFile' },
    config = function() require('nvim_lspconfig') end
  },
  { -- Formatt and lint runner
    'nvimtools/none-ls.nvim',
    lazy = true,
    event = { 'BufRead', 'BufNewFile' },
    dependencies = {
      {
        'nvim-lua/plenary.nvim',
        lazy = true,
        event = { 'BufRead', 'BufNewFile' },
      }
    },
    config = function() require('null_ls') end
  },
  { -- Auto completion
    'hrsh7th/nvim-cmp',
    dependencies = {
      {
        'hrsh7th/cmp-nvim-lsp',
        lazy = true,
        event = { 'InsertEnter' }
      },
      {
        'hrsh7th/vim-vsnip',
        lazy = true,
        event = { 'InsertEnter' }
      },
    },
    config = function() require('nvim_cmp') end
  },
  { -- Debug Adapter Protocol
    'mfussenegger/nvim-dap',
    lazy = true,
    event = { 'BufRead', 'BufNewFile' },
    dependencies = {
      {
        'leoluz/nvim-dap-go',
        lazy = true,
        event = { 'BufRead', 'BufNewFile' }
      },
    },
    config = function() require('nvim_dap') end
  },
  -- GitHub Copilot
  'github/copilot.vim'
}
