

-- Disable Copilot on startup. To re-enable: :Copilot enable (or comment this line out)
vim.g.copilot_enabled = false

-- Searching
vim.o.ignorecase  = true           -- case insensitive 
vim.o.smartcase   = true           -- requires ignorecase, but capitals in searchs are not ignored
vim.o.hlsearch    = true           -- highlight search 
vim.o.incsearch   = false          -- incremental search is annoying


-- Indentation
vim.o.autoindent  = true           -- indent a new line the same amount as the line just typed
vim.o.expandtab   = true           -- converts tabs to white space
vim.o.shiftwidth  = 4              -- uses 4 spaces for a tab, used for auto indenting
vim.o.tabstop     = 4              -- uses 4 spaces for a tab, used when hitting tab key explicitly


-- Wrapping
vim.o.textwidth   = 80             -- wrap text at 80 columns


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
local function clean_view_file(view_file)
  local lines = {}
  for line in io.lines(view_file) do
    if not line:match("^cd ") then -- Exclude lines starting with 'cd '
      table.insert(lines, line)
    end
  end

  -- Overwrite the view file with the filtered content
  local file = io.open(view_file, "w")
  if file then
    file:write(table.concat(lines, "\n"))
    file:close()
  end
end
-- vim.api.nvim_create_autocmd(       -- Saves the position of screen at exit 
--   'BufWinLeave',
--   {
--     callback = function()
--       local view_file = vim.fn.expand("~/.config/nvim/view/") .. vim.fn.bufname():gsub("/", "%%") .. ".vim"
--       vim.cmd("mkview!")
--       clean_view_file(view_file)
--     end,
--   }
-- )
-- vim.api.nvim_create_autocmd(       -- Restores last screen position 
--   'BufWinEnter',
--   {
--     command = [[silent! loadview]]
--   }
-- )


-- Functional Behavior
vim.o.wildmode    = 'longest,list' -- get bash-like tab completions
vim.o.clipboard   = 'unnamedplus'  -- using system clipboard


-- Keymaps
vim.g.mapleader = ' '              -- Use space to prefix our custom functions that won't collide with builtins
vim.keymap.set('n', 'x', '"_x')    -- Use x key to delete characters without overwriting register
vim.keymap.set('n', '<leader>l', ':nohl<CR>')   -- Clear search highlights


--Treesitter config
-- Registers the cedar parser and the .cedar filetype. It has to run before
-- ensure_installed below, which errors on a parser it has never heard of.
-- cedar.nvim calls this itself from plugin/cedar.lua, but that is too late:
-- plugin/ scripts are sourced only after init.lua returns.
require('cedar').setup()

-- cedar.nvim's bundled highlights query captures whole parent nodes, tinting
-- every token in a policy as a keyword, and has no rule for comments at all.
-- Ours has to be installed by hand rather than by dropping it on runtimepath:
-- query.get_files keeps the FIRST non-extends file it finds and discards the
-- rest, and the plugin's copy always comes first. Resolved relative to this
-- file so it does not depend on runtimepath order either.
local nvim_config_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
vim.treesitter.query.set(
    "cedar",
    "highlights",
    table.concat(vim.fn.readfile(nvim_config_dir .. "/queries/cedar/highlights.scm"), "\n")
)

require'nvim-treesitter.configs'.setup {
    ensure_installed = { "hcl", "cedar", "typespec" },
    highlight = {
        enable = true,
    },
}

vim.filetype.add({
  extension = {
    tf = "hcl",
    -- Cedar schemas are a separate language from Cedar policies, with no
    -- tree-sitter grammar in existence; syntax/cedarschema.vim highlights them.
    -- The JSON schema format is left alone: nvim keys off the last extension,
    -- so foo.cedarschema.json is already correctly detected as json.
    cedarschema = "cedarschema",
  },
})
