"""
" Key bind and other setting
"""
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

augroup auto_remove_unnecessary_spaces_at_the_end_of_line
    autocmd!
    autocmd BufWritePre * :%s/\s\+$//ge "Auto remove unnecessary spaces at the end of line.
augroup END
" set mouse=a " Use mouse
" set ttymouse=xterm2 " Use mouse

" Copy to the system clipboard
if has('clipboard')
    set clipboard=unnamed
endif

" Remember a history of undo/redo
if has('persistent_undo')
    let undo_path = expand('~/.vim/undo/')
    exe 'set undodir =' . undo_path
    set undofile
endif

augroup html_css_js_and_others_indent
    autocmd!
    autocmd BufNewFile,BufRead *.yml,*.yaml,*.tmpl :set tabstop=2
    autocmd BufNewFile,BufRead *.yml,*.yaml,*.tmpl :set shiftwidth=2
    autocmd BufNewFile,BufRead *.html,*.css,*.js,*.php :set tabstop=4
    autocmd BufNewFile,BufRead *.html,*.css,*.js,*.php :set shiftwidth=4
    autocmd BufNewFile,BufRead *.go :set tabstop=8
    autocmd BufNewFile,BufRead *.go :set shiftwidth=8
augroup END

let g:mapleader = "\<Space>" " Set a space key to a leader.

" Open .vimrc and 'source' it
nnoremap <Leader>. :vs ~/.vimrc<CR>
nnoremap <Leader>s :source ~/.vimrc<CR>

" Clear highlighted characters
nnoremap <C-[><C-[> :nohlsearch<CR>

"""
" vimshell setting
"""
if has('nvim')
    nnoremap <Leader>- :split term://bash<CR>
    nnoremap <Leader>l :vsplit term://bash<CR>
elseif !has('nvim')
    nnoremap <Leader>- :below terminal ++close ++rows=13 bash<CR>
    nnoremap <Leader>l :vertical terminal ++close bash<CR>
endif


"""
" dein scripts
"""
" if &compatible
"     set nocompatible
" endif
set runtimepath+=/root/.cache/dein/repos/github.com/Shougo/dein.vim
let g:dein#auto_recache=1

if dein#load_state('/root/.cache/dein')
    call dein#begin('/root/.cache/dein')

    call dein#add('/root/.cache/dein/repos/github.com/Shougo/dein.vim')
    if !has('nvim')
        call dein#add('roxma/nvim-yarp')
        call dein#add('roxma/vim-hug-neovim-rpc')
    endif

    " Set .toml file
    let s:rc_dir = expand('~/.vim')
    if !isdirectory(s:rc_dir)
        call mkdir(s:rc_dir, 'p')
    endif
    let s:toml = s:rc_dir . '/dein.toml'
    let s:lazy_toml = s:rc_dir . '/dein_lazy.toml'

    " Read toml and cache
    call dein#load_toml(s:toml, {'lazy': 0})
    call dein#load_toml(s:lazy_toml, {'lazy': 1})

    call dein#end()
    call dein#save_state()
endif

filetype plugin indent on
syntax enable

" If you want to install not installed plugins on startup.
if dein#check_install()
    call dein#install()
endif

" Uninstall removed plugins from dein.toml.
let s:removed_plugins = dein#check_clean()
if len(s:removed_plugins) > 0
    call map(s:removed_plugins, "delete(v:val, 'rf')")
    call dein#recache_runtimepath()
endif
"""
"End dein Scripts
"""

"""
" Colorscheme setting
"""
"syntax enable
let g:gruvbox_contrast_dark = 'medium'
set background=dark
set t_Co=256
colorscheme gruvbox

"""
" vim-airline setting
"""
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline#extensions#branch#enabled = 1

"""
" gitgutter setting
"""
let g:gitgutter_override_sign_column_highlight = 0
set signcolumn=yes " always show signcolumns
set updatetime=250 " default 4000ms

"""
" indent_guides setting
"""
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_start_level = 2
let g:indent_guides_guide_size = 1
let g:indent_guides_exclude_filetypes = ['help', 'nerdtree', 'tagbar', 'unite']

"""
" fern.vim setting
"""
nnoremap <Leader>o :Fern . -drawer -reveal=% -width=30 -toggle<CR>
let g:fern#default_hidden = 1

"""
" ALE
"""
" ALE enables `gofmt`, `golint` and `go vet` by default.
" https://github.com/dense-analysis/ale/blob/master/doc/ale-go.txt
let g:ale_enabled = 1
let g:ale_completion_enabled = 0
let g:ale_fix_on_save = 1
" let b:ale_fixers = {
"         \ 'javascript': ['prettier', 'eslint'],
"         \ 'go': ['goimports']
"         \ }
let g:airline#extensions#ale#enabled = 0
" let g:ale_set_loclist = 0
" let g:ale_set_quickfix = 0
let g:ale_open_list = 0
let g:ale_linters = {'go': ['golangci-lint']}
let g:ale_go_golangci_lint_options = '--enable-all --disable wrapcheck --disable varnamelen --disable tagliatelle --disable lll --disable errorlint --disable godox --disable godot --disable gocritic --disable exhaustivestruct --disable nlreturn --disable wsl'
let g:ale_go_golangci_lint_package = 1

"""
" vim-lsp
"""
let g:lsp_fold_enabled = 0
let g:lsp_diagnostics_enabled = 0
let g:lsp_diagnostics_echo_cursor = 0
let g:lsp_diagnostics_float_cursor = 1
let g:lsp_diagnostics_float_delay = 80
let g:lsp_diagnostics_virtual_text_enabled = 0
let g:lsp_diagnostics_virtual_text_prefix = ' -> '
let g:lsp_diagnostics_highlights_enabled = 0
let g:lsp_diagnostics_signs_insert_mode_enabled = 0
let g:lsp_diagnostics_signs_delay = 80
let g:lsp_diagnostics_signs_error = {'text': '>>'}
let g:lsp_diagnostics_signs_warning = {'text': '>>'}
let g:lsp_diagnostics_signs_hint = {'text': '>>'}
highlight link LspErrorText Normal
highlight link LspWarningText Normal
let g:lsp_document_highlight_enabled = 0
let g:lsp_document_code_action_signs_enabled = 0
" let g:lsp_settings_filetype_go = ['gopls', 'golangci-lint-langserver']

" debug
" let g:lsp_log_verbose = 1
" let g:lsp_log_file = expand('~/vim-lsp.log')
" let g:asyncomplete_log_file = expand('~/asyncomplete.log')
nmap <silent> gd :LspDefinition<CR>
" nmap <silent> gd :LspPeekDefinition<CR>
nmap <silent> <Leader>d :LspTypeDefinition<CR>
nmap <silent> <Leader>r :LspReferences<CR>
nmap <silent> <Leader>i :LspImplementation<CR>

"""
" vim-lsp-settings
"""
let g:lsp_settings_servers_dir = '/root/.vim/servers'

"""
" terraform
"""
let g:terraform_fmt_on_save = 1

"""
" vim-delve
"""
nmap <silent> <Leader>9 :DlvToggleBreakpoint<CR>
nmap <silent> <Leader>5 :DlvDebug<CR>
nmap <silent> <Leader>0 :DlvClearAll<CR>
let g:delve_sign_priority = 100
let g:delve_new_command = 'enew'
