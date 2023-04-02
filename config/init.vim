" ----------------------------------------
" Key bind and other setting.
" ----------------------------------------
set encoding=utf-8 " Prevent garbled characters
set fileencoding=utf-8 " Setting for handling multi byte characters
scriptencoding utf-8 " Setting for handling multi byte characters
set number " Add row number
set title " Add a filename to each tabs
set cursorline " Add cursor line
set tabstop=4 " Insert spaces when the tab key is pressed
set shiftwidth=4 " Change the number of spaces inserted for indentation
" set softtabstop=4 " Make spaces feel like real tabs
set expandtab " Convert tabs to spaces
set smartindent " Add a new line with autoindent
set colorcolumn=120 " Add a color on 80'th column
set hlsearch " Highlight searched characters
set incsearch " Highlight when inputting chars
set wildmenu " Show completion suggestions at command line mode
set conceallevel=0 " Show double quatations in json file and so on.
let g:mapleader = "\<Space>" " Set a space key to a leader.
set mouse= " Don't use a mouse.

" ----------------------------------------
" Remove unnecessary spaces at the end of line.
" ----------------------------------------
augroup auto_remove_unnecessary_spaces_at_the_end_of_line
    autocmd!
    autocmd BufWritePre * :%s/\s\+$//ge "Auto remove unnecessary spaces at the end of line.
augroup END

" ----------------------------------------
" Copy to the system clipboard.
" ----------------------------------------
if has('clipboard')
    set clipboard=unnamed
endif

" ----------------------------------------
" Remember a history of undo/redo.
" ----------------------------------------
if has('persistent_undo')
    let undo_path = expand('~/.vim/undo/')
    exe 'set undodir =' . undo_path
    set undofile
endif

" ----------------------------------------
" Settings for indent each files.
" ----------------------------------------
augroup html_css_js_and_others_indent
    autocmd!
    autocmd BufNewFile,BufRead *.yml,*.yaml,*.tmpl :set tabstop=2 shiftwidth=2
    autocmd BufNewFile,BufRead *.html,*.css,*.js,*.php :set tabstop=4 shiftwidth=4
    autocmd BufNewFile,BufRead *.go :set noexpandtab tabstop=8 shiftwidth=8
augroup END

" ----------------------------------------
" Open .vimrc and 'source' it.
" ----------------------------------------
nnoremap <Leader>. :vs ~/.config/nvim/init.vim<CR>
nnoremap <Leader>s :source ~/.config/nvim/init.vim<CR>

" ----------------------------------------
" Clear highlighted characters.
" ----------------------------------------
nnoremap <C-[><C-[> :nohlsearch<CR>

" ----------------------------------------
" vimshell setting.
" ----------------------------------------
if has('nvim')
    nnoremap <Leader>- :split term://bash<CR>
    nnoremap <Leader>l :vsplit term://bash<CR>
elseif !has('nvim')
    nnoremap <Leader>- :below terminal ++close ++rows=13 bash<CR>
    nnoremap <Leader>l :vertical terminal ++close bash<CR>
endif

" ----------------------------------------
" Load plugins and automatically run `:PackerCompile` whenever plugins.lua is updated.
" ----------------------------------------
lua require('plugins')
augroup packer_user_config
  autocmd!
  autocmd BufWritePost plugins.lua source <afile> | PackerCompile
augroup end

" ----------------------------------------
" Colorscheme setting.
" ----------------------------------------
"syntax enable
let g:gruvbox_contrast_dark = 'medium'
set background=dark
set t_Co=256
colorscheme gruvbox

" ----------------------------------------
" vim-airline setting.
" ----------------------------------------
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline#extensions#branch#enabled = 1

" ----------------------------------------
" gitgutter setting.
" ----------------------------------------
let g:gitgutter_override_sign_column_highlight = 0
set signcolumn=yes " always show signcolumns
set updatetime=100 " default 4000ms

" ----------------------------------------
" indent_guides setting.
" ----------------------------------------
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_start_level = 2
let g:indent_guides_guide_size = 1

" ----------------------------------------
" fern.vim setting.
" ----------------------------------------
nnoremap <Leader>o :Fern . -drawer -reveal=% -width=30 -toggle<CR>
let g:fern#default_hidden = 1

" ----------------------------------------
" vim-delve
" ----------------------------------------
nmap <silent> <Leader>9 :DlvToggleBreakpoint<CR>
nmap <silent> <Leader>5 :DlvDebug<CR>
nmap <silent> <Leader>0 :DlvClearAll<CR>
let g:delve_sign_priority = 100
let g:delve_new_command = 'enew'

" ----------------------------------------
" Load lua files.
" ----------------------------------------
lua require('nvim_lspconfig')
lua require('null_ls')
lua require('nvim_cmp')
