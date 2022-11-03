# Setup

Installation prerequisites

```
# sudo apt install gh
sudo apt install neovim
```

Add ssh key ([full guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account))


```
git clone git@github.com:Harrichael/dev-setup.git
```

## Dotfile Addendums

~/.bashrc
```
source ~/dev-setup/.bashrc
```

~/.config/nvim/init.vim
```
source ~/dev-setup/nvim/init.vim
```

~/.gitconfig
```
[include]
    path= ~/dev-setup/.gitconfig
```
