

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

-- Functional Behavior
vim.o.wildmode    = longest,list   -- get bash-like tab completions
vim.o.clipboard   = unnamedplus   -- using system clipboard

--Plugins

-- require('leap')
--require('plugins/ggandor/leap.nvim')
--require('plugins/hrsh7th/cmp-buffer')
--require('plugins/hrsh7th/cmp-nvim-lua')
--require('plugins/hrsh7th/cmp-path')
--require('plugins/hrsh7th/cmp-vsnip')
--require('plugins/hrsh7th/nvim-cmp')
--require('plugins/hrsh7th/vim-vsnip')
--require('plugins/hrsh7th/cmp-nvim-lsp')
--require('plugins/neovim/nvim-lspconfig')
--require('plugins/onsails/lspkind.nvim')
