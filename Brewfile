# macOS toolchain for dev-setup. Apply with: brew bundle --file=Brewfile
#
# coreutils is deliberately absent: Apple's BSD ls and grep already accept
# --color and --exclude-dir, so a gnubin PATH shim would buy nothing.

brew "neovim"    # everything under nvim/ depends on this
brew "git"       # newer than Apple's, and ships its own completions
brew "git-delta" # required by the `git delta` alias in gitconfig
brew "fnm"       # node version manager, wired up in bashrc/zshrc
brew "tree"      # required by the `gtree` alias
brew "ripgrep"
