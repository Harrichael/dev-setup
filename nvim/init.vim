set nocompatible            " disable compatibility to old-time vi

" Searching
set ignorecase              " case insensitive 
set smartcase               " requires ignorecase, but capitals in searchs are not ignored
set hlsearch                " highlight search 

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
