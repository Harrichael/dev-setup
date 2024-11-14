# Setup

Installation prerequisites

```
# For neovim plugins
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# For FNM
curl -fsSL https://fnm.vercel.app/install | bash
```

Add ssh key ([full guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account))


```
git clone git@github.com:Harrichael/dev-setup.git
```

## Dotfile Addendums

~/.bashrc
```
BASE_PATH="<PATH_TO_USER_DIR>"
source <PATH_TO_USER_DIR>/dev-setup/bashrc
```

/root/.bashrc
```
source <PATH_TO_USER_DIR>/dev-setup/bashrc
```

/etc/rc.local # chmod +x /etc/rc.local
```
#! /bin/sh

source <PATH_TO_USER_DIR>/dev-setup/rc.local
```

~/.config/nvim/init.lua
```
local home_dir = os.getenv("HOME")
package.path = ";" .. home_dir .. "/dev-setup/nvim/" .. package.path
require("plugins_base")
require("init_base")
```

~/.gitconfig
```
[include]
        path= ~/dev-setup/gitconfig
```
