set nocompatible
filetype off

"""
" Set the runtime path to include Vundle and initialize
"""
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'

"""
" Add plugins
"""
Plugin 'scrooloose/nerdtree'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'airblade/vim-gitgutter'
"docker
Plugin 'ekalinin/Dockerfile.vim'
"Golang
Plugin 'fatih/vim-go'
"Python
Plugin 'vim-scripts/indentpython.vim'
Plugin 'nvie/vim-flake8'
"Auto complete and syntax hightlight
Plugin 'valloric/youcompleteme'
Plugin 'tpope/vim-surround'
Plugin 'scrooloose/syntastic'

call vundle#end()
filetype plugin indent on

"""
" Colorscheme setting
"""
syntax enable 
colorscheme gruvbox
set background=dark
set t_Co=256
let g:gruvbox_contrast_dark = 'medium'

"""
" NERDTree setting
"""
let g:NERDTreeDirArrowExpandable = '+'
let g:NERDTreeDirArrowCollapsible = '~'
let NERDTreeShowHidden = 1
let g:NERDTreeWinSize = 30 
let g:NERDTreeIgnore=['\.DS_Store$', '\.git$', '\.svn$', '\.clean$', '\.swp$']
map <C-o> :NERDTreeToggle<CR>

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
set signcolumn=yes

"""
" Vim-go setting
"""
let g:go_template_autocreate = 0
let g:go_fmt_command = 'gofmt'
""let g:syntastic_go_checkers = ['golint', 'govet', 'errcheck']
let g:go_metalinter_enabled = ['vet', 'golint', 'errcheck']
let g:go_metalinter_autosave = 1
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_operators = 1
let g:go_highlight_extra_types = 1

"""
" Python
"""
let python_highlight_all=1

"""
" YouCompleteMe setting
"""
let g:ycm_server_python_interpreter = '/usr/bin/python3'
let g:ycm_python_binary_path = '/usr/bin/python3'
let g:ycm_global_ycm_extra_conf = '/root/.vim/plugged/YouCompleteMe/.ycm_extra_conf.py'
let g:ycm_auto_trigger = 1
let g:ycm_min_num_of_chars_for_completion = 1
let g:ycm_autoclose_preview_window_after_insertion = 1
set completeopt-=preview
let g:ycm_add_preview_to_completeopt = 0

"""
" vimshell setting
"""
map <C-i> :below terminal ++close ++rows=11 bash<CR>

"""
" Other setting
"""
set encoding=utf-8
set number
set title
set expandtab
set tabstop=4
set shiftwidth=4
"split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
