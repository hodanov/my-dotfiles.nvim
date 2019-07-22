set nocompatible
filetype off

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'

" Add plugins
Plugin 'ekalinin/Dockerfile.vim'
Plugin 'fatih/vim-go'
Plugin 'scrooloose/nerdtree'

call vundle#end()
filetype plugin indent on

" Colorscheme setting
colorscheme monokai
syntax enable

" NERDTree setting
let g:NERDTreeDirArrowExpandable="+"
let g:NERDTreeDirArrowCollapsible="~"
let NERDTreeShowHidden=1

" Vim-go setting
let g:go_template_autocreate = 0
let g:go_fmt_command = "gofmt"
let g:syntastic_go_checkers = ['golint', 'govet', 'errcheck']

let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_operators = 1
let g:go_highlight_extra_types = 1

" Other setting
set encoding=utf-8
set number
set title