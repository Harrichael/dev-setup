# NeoVim nvim_create_autocmd is nil (cannot be called)

Your neovim is too old. Install the latest stable build.

## Linux

Distro packages, and the neovim PPA, are often too old. This config needs 0.10
or newer. Install the release build into `~/.local`, which is ahead of
`/usr/bin` on `PATH`:

```
curl -fL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
  | tar -xz -C ~/.local --strip-components=1
```

## macOS

Homebrew already ships current stable, so this shouldn't happen:

```
brew install neovim
brew upgrade neovim
```
