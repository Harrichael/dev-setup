set nocompatible            " disable compatibility to old-time vi

" using ::another;

" Searching
set ignorecase              " case insensitive 
set smartcase               " requires ignorecase, but capitals in searchs are not ignored
set hlsearch                " highlight search 
set noincsearch             " incremental search is annoying

" Indentation
set autoindent              " indent a new line the same amount as the line just typed
set expandtab               " converts tabs to white space
filetype plugin indent on   " allow auto-indenting depending on file type

" Static Appearance
set number                  " add line numbers
set cursorline              " highlight current cursorline
syntax on                   " syntax highlighting
set showmatch               " show matching parens

" Usability
set ttyfast                 " Speed up scrolling in Vim
set history=10000           " Elephants never forget
set autoread                " If the file changes outside vim, automatically read it again

" Interopability
filetype plugin on

" Functional Behavior
set wildmode=longest,list   " get bash-like tab completions
set clipboard=unnamedplus   " using system clipboard

" Custom Editing Functions
source cpp_primitives.vim
command -nargs=1 I call CPPAddIncludeFromArg(<f-args>)
command -nargs=0 Ip call CPPAddIncludeFromArg(getreg('0'))
command -nargs=0 Ipp call CPPAddIncludeToOtherPane()

command -nargs=1 U call CPPAddUsingFromArg(<f-args>)
command -nargs=0 Up call CPPAddUsingFromArg(getreg('0'))

command -nargs=1 Uh call CPPAddUsingFromArgInHeader(<f-args>)
command -nargs=0 Uph call CPPAddUsingFromArgInHeader(getreg('0'))

" Plugins

call plug#begin()
Plug 'ggandor/leap.nvim'
call plug#end()

" Leap is for leaping the cursor within the current window frame
lua <<EOF
require('leap').add_default_mappings()
