
local install_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  print("Downloading wbthomason/packer.nvim...")
  local install_cmd = "git clone https://github.com/wbthomason/packer.nvim --depth 1 " .. install_path
  local stdout = vim.fn.system(install_cmd)
  print(stdout)
  print("Packer installed. You'll need to restart now.")
end

-- :PackerUpdate
-- :PackerSync

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

end)
