

-- Searching
vim.o.ignorecase  = true            -- case insensitive 
vim.o.smartcase   = true            -- requires ignorecase, but capitals in searchs are not ignored
vim.o.hlsearch    = true            -- highlight search 
vim.g.noincsearch = true            -- incremental search is annoying

-- Indentation
vim.o.autoindent  = true           -- indent a new line the same amount as the line just typed
vim.o.expandtab   = true           -- converts tabs to white space

-- Static Appearance
vim.o.number      = true           -- add line numbers
vim.o.cursorline  = true           -- highlight current cursorline
vim.o.showmatch   = true           -- show matching parens

-- Usability
vim.o.ttyfast     = true           -- Speed up scrolling in Vim
vim.o.history     = 10000           -- Elephants never forget
vim.o.autoread    = true           -- If the file changes outside vim, automatically read it again
vim.o.scrolloff   = 5              -- Minimum spacing from current line to top or bottom
vim.api.nvim_create_autocmd(       -- Saves the position of screen at exit 
  'BufWinLeave',
  {
    command = [[mkview]]
  }
)
vim.api.nvim_create_autocmd(       -- Restores last screen position 
  'BufWinEnter',
  {
    command = [[silent! loadview]]
  }
)

-- Functional Behavior
vim.o.wildmode    = longest,list   -- get bash-like tab completions
vim.o.clipboard   = unnamedplus   -- using system clipboard
