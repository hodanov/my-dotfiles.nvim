require'dap-go'.setup()

-- nvim-dap: keymap
vim.keymap.set('n', '<Leader>5', function() require('dap').continue() end)
vim.keymap.set('n', '<Leader>1', function() require('dap').step_over() end)
vim.keymap.set('n', '<Leader>2', function() require('dap').step_into() end)
vim.keymap.set('n', '<Leader>3', function() require('dap').step_out() end)
vim.keymap.set('n', '<Leader>9', function() require('dap').toggle_breakpoint() end)
vim.keymap.set('n', '<Leader>0', function() require('dap').clear_breakpoints() end)
vim.keymap.set('n', '<Leader>dr', function() require('dap').repl.toggle() end)
vim.keymap.set({'n', 'v'}, '<Leader>dh', function()
  require('dap.ui.widgets').hover()
end)
vim.keymap.set({'n', 'v'}, '<Leader>dp', function()
  require('dap.ui.widgets').preview()
end)
vim.keymap.set('n', '<Leader>df', function()
  local widgets = require('dap.ui.widgets')
  widgets.centered_float(widgets.frames)
end)
vim.keymap.set('n', '<Leader>ds', function()
  local widgets = require('dap.ui.widgets')
  widgets.centered_float(widgets.scopes)
end)

-- nvim-dap: the color of sign settings
vim.api.nvim_set_hl(0, "maroon",   { fg = "#E64653" })
vim.api.nvim_set_hl(0, "blue",   { fg = "#1E66F5" })
vim.api.nvim_set_hl(0, "green",  { fg = "#4DA02C" })
vim.api.nvim_set_hl(0, "peach", { fg = "#F46326" })
vim.api.nvim_set_hl(0, "rosewater", { fg = "#DC8A78" })
vim.api.nvim_set_hl(0, "mocha_maroon",   { fg = "#EBA0AC" })
vim.api.nvim_set_hl(0, "mocha_blue",   { fg = "#89B4FA" })
vim.api.nvim_set_hl(0, "mocha_green",  { fg = "#A6E3A1" })
vim.api.nvim_set_hl(0, "mocha_peach", { fg = "#FAB387" })
vim.api.nvim_set_hl(0, "mocha_rosewater", { fg = "#FAB387" })
vim.fn.sign_define('DapBreakpoint',          { text='●', texthl='mocha_maroon', linehl='DapBreakpoint', numhl='DapBreakpoint' })
-- vim.fn.sign_define('DapBreakpointCondition', { text='●', texthl='blue', linehl='DapBreakpointCondition', numhl='DapBreakpointCondition' })
-- vim.fn.sign_define('DapBreakpointRejected',  { text='●', texthl='peach', linehl='DapBreakpointRejected', numhl='DapBreakpointRejected' })
vim.fn.sign_define('DapStopped',             { text='▶︎', texthl='mocha_green', linehl='DapStopped', numhl='DapStopped' })
-- vim.fn.sign_define('DapLogPoint',            { text='●', texthl='rosewater', linehl='DapLogPoint', numhl='DapLogPoint' })

vim.keymap.set('n', '<Leader>dt', function() require('dap-go').debug_test() end)
