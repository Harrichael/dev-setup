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

cask "kitty"                          # terminal; draws its own tab bar, so a
                                      # tiling WM sees one window, not one per tab
cask "font-jetbrains-mono-nerd-font"  # kitty/kitty.conf asks for "JetBrainsMono NFM"

cask "hammerspoon"  # Lua keybinding/automation layer
cask "mos"          # per-device scroll: see the scrolling note below

# No window manager cask on purpose: the requirement is one workspace spanning
# every monitor with most-recently-used switching scoped to it, and nothing
# shipping does both. Hammerspoon owns the shortcuts and the window management
# is written against it. See README for what was tried.

# Scrolling is split across two places by necessity. macOS has exactly ONE
# scroll-direction setting (`com.apple.swipescrolldirection`) and both the
# Trackpad and Mouse panes are views onto it, so it cannot differ per device.
# Mos only transforms discrete wheel events and leaves the trackpad alone, so:
#   macOS natural scrolling ON  -> trackpad scrolls naturally
#   Mos `reverse` = true        -> external mouse scrolls the traditional way
#
# install.sh writes both halves, plus Mos's step/speed/duration and
# com.apple.scrollwheel.scaling -- see apply_macos_defaults there. Installing the
# cask is not enough on its own: the tuned values are not Mos defaults, and
# nothing but that function knows them. The remaining manual step is granting
# Mos Accessibility, which no script can do.
