

-- Searching
vim.o.ignorecase  = true           -- case insensitive 
vim.o.smartcase   = true           -- requires ignorecase, but capitals in searchs are not ignored
vim.o.hlsearch    = true           -- highlight search 
vim.g.noincsearch = true           -- incremental search is annoying


-- Indentation
vim.o.autoindent  = true           -- indent a new line the same amount as the line just typed
vim.o.expandtab   = true           -- converts tabs to white space
vim.o.shiftwidth  = 4              -- uses 4 spaces for a tab, used for auto indenting
vim.o.tabstop     = 4              -- uses 4 spaces for a tab, used when hitting tab key explicitly


-- Static Appearance
vim.o.number      = true           -- add line numbers
vim.o.cursorline  = true           -- highlight current cursorline
vim.o.showmatch   = true           -- show matching parens


-- Usability
vim.o.ttyfast     = true           -- Speed up scrolling in Vim
vim.o.history     = 10000          -- Elephants never forget
vim.o.autoread    = true           -- If the file changes outside vim, automatically read it again
vim.o.autochdir   = false          -- Don't auto change directory! Logic is busted, avoid. KISS.
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
vim.o.wildmode    = 'longest,list' -- get bash-like tab completions
vim.o.clipboard   = 'unnamedplus'  -- using system clipboard


-- Keymaps
vim.g.mapleader = ' '              -- Use space to prefix our custom functions that won't collide with builtins
vim.keymap.set('n', 'x', '"_x')    -- Use x key to delete characters without overwriting register
vim.keymap.set('n', '<leader>l', ':nohl<CR>')   -- Clear search highlights


--Treesitter config
require'nvim-treesitter.configs'.setup {
    highlight = {
        enable = true,
    },
}

local parsers = require'nvim-treesitter.parsers'
local ensure_installed = { "hcl" }

for _, lang in ipairs(ensure_installed) do
  if not parsers.has_parser(lang) then
    vim.cmd("TSInstall " .. lang)
  end
end

vim.filetype.add({
  extension = {
    tf = "hcl",
  },
})
