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
cask "linearmouse"  # per-device scroll: see the scrolling note below

# No window manager cask on purpose: the requirement is one workspace spanning
# every monitor with most-recently-used switching scoped to it, and nothing
# shipping does both. Hammerspoon owns the shortcuts and the window management
# is written against it. See README for what was tried.

# Scrolling is split across two places by necessity. macOS has exactly ONE
# scroll-direction setting (`com.apple.swipescrolldirection`) and both the
# Trackpad and Mouse panes are views onto it, so it cannot differ per device.
# LinearMouse matches on device category, so:
#   macOS natural scrolling ON        -> trackpad scrolls naturally
#   LinearMouse scrolling.reverse     -> external mouse scrolls traditionally,
#                                        scoped to `device.category = mouse`
#
# LinearMouse also fixes scroll ACCELERATION. macOS inflates a single wheel
# detent by up to ~14x depending only on how fast the previous detent arrived,
# and that inflation cannot be disabled -- not by com.apple.scrollwheel.scaling,
# not by hidutil. LinearMouse discards the inflated fields and rewrites each
# event as sign x a fixed distance, so every detent travels the same distance.
#
# install.sh wires the config and writes the macOS half -- see wire_linearmouse
# and apply_macos_defaults there. Installing the cask is not enough on its own.
# The remaining manual step is granting LinearMouse Accessibility, which no
# script can do.
