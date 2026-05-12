
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
  -- use 'github/copilot.vim'

  -- deps
  use 'nvim-lua/plenary.nvim'
  use {
    'nvim-telescope/telescope.nvim',
    config = function()
      vim.keymap.set('n', '<leader>ff', ':Telescope find_files<CR>', { desc = 'Find files' })
      vim.keymap.set('n', '<leader>fg', ':Telescope live_grep<CR>', { desc = 'Live grep' })
      vim.keymap.set('n', '<leader>fb', ':Telescope buffers<CR>', { desc = 'Buffers' })
      vim.keymap.set('n', '<leader>fh', ':Telescope help_tags<CR>', { desc = 'Help tags' })
      vim.keymap.set('n', '<leader>fr', ':Telescope oldfiles<CR>', { desc = 'Recent files' })
      vim.keymap.set('n', '<leader>fw', ':Telescope grep_string<CR>', { desc = 'Grep word under cursor' })
      vim.keymap.set('n', '<leader>fd', ':Telescope diagnostics<CR>', { desc = 'Diagnostics' })
      vim.keymap.set('n', '<leader>fc', ':Telescope git_commits<CR>', { desc = 'Git commits' })
      vim.keymap.set('n', '<leader>fs', ':Telescope git_status<CR>', { desc = 'Git status' })
    end
  }
  -- use {
  --   'CopilotC-Nvim/CopilotChat.nvim',
  --   branch = 'main',
  --   dependencies = {
  --     'github/copilot.vim',
  --     'nvim-lua/plenary.nvim',
  --     'nvim-telescope/telescope.nvim',
  --   },
  --   config = function()
  --     require('CopilotChat').setup {
  --       window = {
  --         layout = 'vertical',
  --         width = 0.35,
  --         border = 'single',
  --       },
  --       auto_follow_cursor = false,
  --     }
  --
  --     vim.api.nvim_set_keymap('n', '<leader>cc', ':CopilotChat<CR>', { noremap = true, silent = true, desc = 'Open Copilot Chat' })
  --     vim.api.nvim_set_keymap('n', '<leader>ce', ':CopilotChatExplain<CR>', { noremap = true, silent = true, desc = 'Explain selected code' })
  --     vim.api.nvim_set_keymap('n', '<leader>cr', ':CopilotChatReview<CR>', { noremap = true, silent = true, desc = 'Review selected code' })
  --   end,
  -- }

  -- Treesitter
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate'
  }

  use {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup({
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local function opts(desc)
            return { buffer = bufnr, desc = desc }
          end

          vim.keymap.set('n', ']h', gs.next_hunk, opts('Next hunk'))
          vim.keymap.set('n', '[h', gs.prev_hunk, opts('Previous hunk'))

          vim.keymap.set('n', '<leader>hs', gs.stage_hunk, opts('Stage hunk'))
          vim.keymap.set('n', '<leader>hr', gs.reset_hunk, opts('Reset hunk'))
          vim.keymap.set('v', '<leader>hs', function() gs.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, opts('Stage selected hunk'))
          vim.keymap.set('v', '<leader>hr', function() gs.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, opts('Reset selected hunk'))
          vim.keymap.set('n', '<leader>hu', gs.undo_stage_hunk, opts('Undo stage hunk'))
          vim.keymap.set('n', '<leader>hS', gs.stage_buffer, opts('Stage entire buffer'))
          vim.keymap.set('n', '<leader>hR', gs.reset_buffer, opts('Reset entire buffer'))

          vim.keymap.set('n', '<leader>hp', gs.preview_hunk, opts('Preview hunk'))
          vim.keymap.set('n', '<leader>hb', gs.blame_line, opts('Blame line'))
          vim.keymap.set('n', '<leader>hB', function() gs.blame_line({ full = true }) end, opts('Blame line (full)'))

          vim.keymap.set('n', '<leader>hd', gs.diffthis, opts('Diff against index'))
          vim.keymap.set('n', '<leader>htb', gs.toggle_current_line_blame, opts('Toggle line blame'))
          vim.keymap.set('n', '<leader>htd', gs.toggle_deleted, opts('Toggle show deleted'))
        end
      })
    end
  }

  -- Syntax highlighting
  --use { 'm-demare/hlargs.nvim' }
  --require('hlargs').setup()
  
  if packer_bootstrap then
    require("packer").sync()
  end
end)
