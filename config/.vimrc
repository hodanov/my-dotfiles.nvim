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
set colorcolumn=80 " Add a color on 80'th column
set hlsearch " Highlight searched characters
set incsearch " Highlight when inputting chars
set wildmenu " Show completion suggestions at command line mode
autocmd BufWritePre * :%s/\s\+$//ge "Auto remove unnecessary spaces at the end of line.
set mouse=a " Use mouse
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
    autocmd BufNewFile,BufRead *.html,*.css,*.js,*.php,*.yml,*.yaml,*.tmpl :set tabstop=2
    autocmd BufNewFile,BufRead *.html,*.css,*.js,*.php,*.yml,*.yaml,*.tmpl :set shiftwidth=2
    autocmd BufNewFile,BufRead *.go :set tabstop=8
    autocmd BufNewFile,BufRead *.go :set shiftwidth=8
augroup END

let g:mapleader = "\<Space>" " Set a space key to a leader.

" Move the splited window
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Open .vimrc and 'source' it
nnoremap <Leader>. :vs ~/.vimrc<CR>
nnoremap <Leader>s :source ~/.vimrc<CR>

" Clear highlighted characters
nnoremap <Esc><Esc> :nohlsearch<CR>

"""
" vimshell setting
"""
if has('nvim')
    nnoremap <Leader>- :split term://bash<CR>
    nnoremap <Leader>i :vsplit term://bash<CR>
elseif !has('nvim')
    nnoremap <Leader>- :below terminal ++close ++rows=13 bash<CR>
    nnoremap <Leader>i :vertical terminal ++close bash<CR>
endif


"""
" dein scripts
"""
if &compatible
    set nocompatible
endif
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
" colorscheme spring-night

"""
" vim-airline setting
"""
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline#extensions#branch#enabled = 1
" let g:airline_theme = 'spring_night'

"""
" gitgutter setting
"""
let g:gitgutter_override_sign_column_highlight = 0
set signcolumn=yes

"""
" indentLine setting
"""
let g:indentLine_enabled = 1
let g:indentLine_char_list = '|'

"""
" NERDTree setting
"""
let g:NERDTreeDirArrowExpandable = '+'
let g:NERDTreeDirArrowCollapsible = '-'
let NERDTreeShowHidden = 1
let g:NERDTreeWinSize = 30
let g:NERDTreeIgnore=['\.DS_Store$', '\.git$', '\.svn$', '\.clean$', '\.swp$']
nnoremap <C-o> :NERDTreeToggle<CR>

"""
" ALE
"""
" In ~/.vim/ftplugin/javascript.vim, or somewhere similar.
" Fix files with prettier, and then ESLint.
let b:ale_fixers = ['prettier', 'eslint']
" Equivalent to the above.
let b:ale_fixers = {'javascript': ['prettier', 'eslint']}

"""
" Vim-go setting
"""
" let g:go_template_autocreate = 0
let g:go_fmt_command = 'gofmt'
let g:go_metalinter_enabled = ['vet', 'golint', 'errcheck']
let g:go_metalinter_autosave_enabled = ['vet', 'golint', 'errcheck']
let g:go_metalinter_autosave = 1
" let g:go_highlight_types = 1
" let g:go_highlight_fields = 1
" let g:go_highlight_functions = 1
" let g:go_highlight_function_calls = 1
" let g:go_highlight_operators = 1
" let g:go_highlight_extra_types = 1

"""
" Python setting - autopep8
" autopep
" original http://stackoverflow.com/questions/12374200/using-uncrustify-with-vim/15513829#15513829
"""
let python_highlight_all = 1

function! Preserve(command)
    " Save the last search.
    let search = @/
    " Save the current cursor position.
    let cursor_position = getpos('.')
    " Save the current window position.
    normal! H
    let window_position = getpos('.')
    call setpos('.', cursor_position)
    " Execute the command.
    execute a:command
    " Restore the last search.
    let @/ = search
    " Restore the previous window position.
    call setpos('.', window_position)
    normal! zt
    " Restore the previous cursor position.
    call setpos('.', cursor_position)
endfunction

function! Autopep8()
    "--ignote=E501: Ignore completing the length of a line."
    call Preserve(':silent %!autopep8 --ignore=E501 -')
endfunction

augroup python_auto_lint
    autocmd!
    autocmd BufWrite *.py :call Autopep8()
augroup END