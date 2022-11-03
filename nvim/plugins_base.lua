
local install_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  print("Downloading wbthomason/packer.nvim...")
  local install_cmd = "git clone https://github.com/wbthomason/packer.nvim --depth 1 " .. install_path
  local stdout = vim.fn.system(install_cmd)
  print(stdout)
  print("Packer installed. You'll need to restart now.")
end

require('packer').startup(function(use)
  
  use 'wbthomason/packer.nvim'
  use 'hrsh7th/cmp-buffer'

end)
