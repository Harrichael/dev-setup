
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
  if fn.empty(fn.glob(install_path)) > 0 then
    print("Downloading wbthomason/packer.nvim...")
    fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
    vim.cmd([[packadd packer.nvim]])
    print("Packer installed")
    return true
  end
  return false
end
local packer_bootstrap = ensure_packer()

-- :PackerUpdate
-- :PackerSync
vim.cmd([[ 
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins_base.lua source <afile> | PackerSync
  augroup end
]])

require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  -- Press 's' to activate leap search.
  -- Proceed by typing up to 2 characters to search.
  -- All matches in window are now tagged with a jump code.
  -- Complete search by typing jump code character.
  -- At anypoint, you may continue with normal workflow if you just continue
  --   on, as long as the first key you press is not highlighted.
  use {
    'ggandor/leap.nvim',
    config = function()
        require('leap').set_default_keymaps()
    end
  }

  -- To surround text:
  --   'ys'
  --   <motion>, e.g. 'w' for word
  --   <character-to-surround-with>, e.g. '"'
  -- To delete surround chars:
  --   'ds'
  --   <character-surrounding-to-delete>
  -- To replace surround chars:
  --   'cs'
  --   <character-surround-to-replace>
  --   <character-to-surround-with>
  use 'tpope/vim-surround'

  -- To finish setup:
  --   1. Navigate to packer's git clone location
  --     a. Open compiled packer lua file, example:
  --        `~/.config/nvim/plugin/packer_compiled.lua`
  --     b. Example of above:
  --        `~/.local/share/nvim/site/pack/packer/start/YouCompleteMe`
  --   2. Compile project:
  --      `./install.py --all`
  --use 'ycm-core/YouCompleteMe'

  -- To setup:
  --   run :Copilot setup
  --   see the github readme for more.
  use 'github/copilot.vim'

  -- deps
  use 'nvim-lua/plenary.nvim'
  use 'nvim-telescope/telescope.nvim'
  use {
    'CopilotC-Nvim/CopilotChat.nvim',
    branch = 'main',
    dependencies = {
      'github/copilot.vim', -- Ensure Copilot is installed
      'nvim-lua/plenary.nvim', -- Required for CopilotChat
      'nvim-telescope/telescope.nvim', -- Optional, for better UI
    },
    config = function()
      require('CopilotChat').setup {
        window = {
          layout = 'vertical', -- Chat in a vertical split
          width = 0.35,        -- 40% of screen width
          border = 'single',
        },
        auto_follow_cursor = false, -- Keep chat focused on selection
      }

      vim.api.nvim_set_keymap('n', '<leader>cc', ':CopilotChat<CR>', { noremap = true, silent = true, desc = 'Open Copilot Chat' })
      vim.api.nvim_set_keymap('n', '<leader>ce', ':CopilotChatExplain<CR>', { noremap = true, silent = true, desc = 'Explain selected code' })
      vim.api.nvim_set_keymap('n', '<leader>cr', ':CopilotChatReview<CR>', { noremap = true, silent = true, desc = 'Review selected code' })
    end,
  }

  -- Treesitter
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate'
  }

  use {
    'lewis6991/gitsigns.nvim',
    config = function()
        require('gitsigns').setup()
    end
  }

  -- Syntax highlighting
  --use { 'm-demare/hlargs.nvim' }
  --require('hlargs').setup()
  
  if packer_bootstrap then
    require("packer").sync()
  end
end)
