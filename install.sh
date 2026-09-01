#!/usr/bin/env bash
# Bootstrap dev-setup on this machine.
#
# Safe to re-run: every step checks before it acts, so a second run reports what
# is already in place and changes nothing. Ordering matters -- packages first,
# then dotfiles, then the things that depend on both -- so a failure late on
# never leaves the shell config half-wired.
set -euo pipefail

# Resolve the repo root from this script's own location. Do not assume
# ~/dev-setup -- the clone location is the user's choice.
# Pulling is opt-in. Installing and updating are different jobs: fusing them
# means you cannot install a pin, roll back, or test a branch, because every
# install silently becomes "install whatever is newest".
UPDATE=0

usage() {
  cat <<'USAGE'
usage: install.sh [--update]

  --update   Fast-forward every checkout to its origin default branch first.
             Without it, install.sh installs whatever the checkouts are at
             now, and only clones what is missing.

To install a specific version, check it out and install without --update:

  git -C ~/.local/share/dev-setup/self checkout v1.2
  ~/.local/share/dev-setup/self/install.sh
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --update) UPDATE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "install.sh: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# Where this script is running from. May be a development clone.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The checkout the dotfiles are wired to. Deliberately NOT the running clone:
# the dotfiles read it by reference, so if it were a clone you develop in, a
# half-saved edit or a checked-out WIP branch would change every new shell the
# moment you made it. This one is pristine -- pulled and read, never developed
# in -- for the same reason Gnomon deploys a copy instead of a symlink.
#
# Set DEV_SETUP_SELF_DIR to the running clone to wire your working copy instead,
# which is what you want while iterating on the config itself.
SELF_DIR="${DEV_SETUP_SELF_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/dev-setup/self}"

# Resolved by install_self(); the wiring reads this, never REPO_DIR.
WIRE_DIR="$REPO_DIR"

case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)  OS=linux ;;
  *)      echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

echo "dev-setup: repo at $REPO_DIR, detected $OS"
echo

# ---------------------------------------------------------------- packages ---

install_packages() {
  if [ "$OS" = macos ]; then
    if ! command -v brew >/dev/null 2>&1; then
      echo "!! Homebrew not found. Install it first: https://brew.sh" >&2
      echo "!! Then run its 'Next steps' shellenv line so brew is on PATH." >&2
      return 1
    fi
    echo "==> brew bundle"
    brew bundle --file="$REPO_DIR/Brewfile"
  else
    echo "==> Linux: dotfiles will still be wired below, but install these"
    echo "    packages yourself:"
    echo "    sudo apt install neovim git tree ripgrep kitty fonts-jetbrains-mono"
    echo "    git-delta: https://github.com/dandavison/delta/releases"
    echo "    fnm:       curl -fsSL https://fnm.vercel.app/install | bash"
  fi
}

# ---------------------------------------------------------------- dotfiles ---
#
# Nothing is ever copied out of this repo. Each dotfile gets a small block that
# points back here, so `git pull` alone updates your live config.
#
# That block is delimited by sentinel comments rather than matched on its own
# text. Two things fall out of that: re-running is a no-op regardless of how the
# path is quoted, and if the repo MOVES, the existing block is rewritten in
# place instead of a second one being appended.

BEGIN_TAG=">>> dev-setup >>>"
END_TAG="<<< dev-setup <<<"

# _block_get <file> <begin> <end> -- print the payload currently between sentinels
_block_get() {
  awk -v b="$2" -v e="$3" '$0==b{f=1;next} $0==e{f=0} f' "$1"
}

# _block_set <file> <begin> <end> <payload> -- replace the payload in place
_block_set() {
  local file="$1" tmp
  tmp="$(mktemp)"
  BEGIN_MARK="$2" END_MARK="$3" PAYLOAD="$4" awk '
    $0 == ENVIRON["BEGIN_MARK"] { print; printf "%s\n", ENVIRON["PAYLOAD"]; skip=1; next }
    $0 == ENVIRON["END_MARK"]   { skip=0; print; next }
    !skip                       { print }
  ' "$file" > "$tmp"
  cat "$tmp" > "$file"   # via cat, so the original inode and mode survive
  rm -f "$tmp"
}

# wire_block <file> <comment-prefix> <payload> <conflict-needle>
#
# comment-prefix differs per file type ("#" for shell and gitconfig, "--" for
# Lua), so the sentinels are always valid syntax for the file they live in.
# conflict-needle detects a pre-existing hand-wired reference that predates the
# sentinels -- appending on top of one would double-source, so we stop instead.
# cs is a closing comment delimiter, for formats that have no line comment at
# all -- markdown needs "<!-- ... -->" or the sentinel swallows the rest of the
# file. Empty for shell, gitconfig and Lua.
wire_block() {
  local file="$1" cp="$2" payload="$3" needle="$4" label="${5:-dev-setup}" cs="${6:-}"
  local begin="$cp >>> $label >>>${cs:+ $cs}" end="$cp <<< $label <<<${cs:+ $cs}"

  mkdir -p "$(dirname "$file")"
  [ -f "$file" ] || : > "$file"

  if grep -qF -e "$begin" "$file"; then
    if [ "$(_block_get "$file" "$begin" "$end")" = "$payload" ]; then
      echo "    already current: $file"
    else
      _block_set "$file" "$begin" "$end" "$payload"
      echo "    updated in place: $file"
    fi
    return 0
  fi

  if grep -qF -e "$needle" "$file"; then
    echo "    !! $file already references $needle outside a dev-setup block."
    echo "       Remove that line by hand and re-run, or you would be sourcing"
    echo "       it twice. Skipped."
    return 0
  fi

  printf '\n%s\n%s\n%s\n' "$begin" "$payload" "$end" >> "$file"
  echo "    wired: $file"
}

wire_shell() {
  local rc target
  if [ "$OS" = macos ]; then
    rc="$HOME/.zshrc"; target="$WIRE_DIR/zshrc"
  else
    rc="$HOME/.bashrc"; target="$WIRE_DIR/bashrc"
  fi
  echo "==> shell rc"
  wire_block "$rc" "#" "export BASE_PATH=\"\$HOME\"
source \"$target\"" "$target"
}

wire_gitconfig() {
  echo "==> gitconfig"
  wire_block "$HOME/.gitconfig" "#" "[include]
	path = $WIRE_DIR/gitconfig" "$WIRE_DIR/gitconfig"
}

wire_nvim() {
  echo "==> nvim init.lua"
  wire_block "$HOME/.config/nvim/init.lua" "--" "package.path = \";$WIRE_DIR/nvim/?.lua;\" .. package.path
vim.opt.runtimepath:append(\"$WIRE_DIR/nvim\")
require(\"plugins_base\")
require(\"init_base\")" "$WIRE_DIR/nvim"
}

# -------------------------------------------------------------------- node ---

setup_node() {
  echo "==> node"
  if ! command -v fnm >/dev/null 2>&1; then
    echo "    skipped: fnm not on PATH"
    return 0
  fi
  # fnm deliberately ships no Node of its own, so node/npx -- and the nx
  # aliases that shell out to npx -- stay broken until a version exists.
  if fnm list 2>/dev/null | grep -qE 'v[0-9]+\.'; then
    echo "    already installed: $(fnm list 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | tr '\n' ' ')"
    return 0
  fi
  fnm install --lts
  fnm default lts-latest
  echo "    installed $(fnm list 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | tr '\n' ' ')"
}

# ------------------------------------------------------------ nvim plugins ---

# Each nvim call gets an in-editor watchdog because macOS has no coreutils
# `timeout`: if a clone stalls, defer_fn force-quits rather than hanging here.
nvim_headless() {
  nvim --headless \
    -c 'lua vim.defer_fn(function() vim.cmd("quitall!") end, 300000)' \
    "$@" >/dev/null 2>&1 || true
}

# Does nvim start with no errors? A missing plugin shows up here, because the
# config requires them at startup.
nvim_startup_clean() {
  [ -z "$(nvim --headless -c 'quitall' 2>&1 || true)" ]
}

# Space-separated ensure_installed parsers that are not built yet. Prints
# nothing if treesitter itself is not loadable -- that case is caught by
# nvim_startup_clean instead.
nvim_missing_parsers() {
  nvim --headless -c 'lua
local ok, cfg = pcall(require, "nvim-treesitter.configs")
if ok then
  local m = {}
  for _, name in ipairs(cfg.get_ensure_installed_parsers()) do
    if #vim.api.nvim_get_runtime_file("parser/" .. name .. ".so", false) == 0 then
      m[#m + 1] = name
    end
  end
  io.stdout:write(table.concat(m, " "))
end' -c 'quitall' 2>/dev/null
}

setup_nvim_plugins() {
  echo "==> nvim plugins"
  if ! command -v nvim >/dev/null 2>&1; then
    echo "    skipped: nvim not on PATH"
    return 0
  fi

  # Fast path, and the common case on a re-run. Everything below is expensive:
  # PackerSync fetches every plugin, and treesitter's ensure_installed_sync does
  # not return at all once the parsers exist -- it used to burn the watchdog
  # timeout on every single run. So check first, and only act if something is
  # actually missing.
  local missing
  if nvim_startup_clean; then
    missing="$(nvim_missing_parsers)"
    if [ -z "$missing" ]; then
      echo "    already installed, startup clean"
      return 0
    fi
    echo "    missing treesitter parsers:$missing"
  fi

  # Packer clones itself on first launch, but the config already requires
  # plugins that do not exist yet, so this run always errors. Absorb that here
  # so the first interactive launch is clean.
  nvim_headless -c 'quitall'

  # PackerSync is asynchronous; PackerComplete fires when it has finished.
  nvim_headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

  # Install parsers one at a time via TSUpdateSync, which terminates. Packer's
  # own `run = ":TSUpdate"` hook cannot do this during bootstrap, because the
  # command is not registered yet in that session.
  missing="$(nvim_missing_parsers)"
  local name
  for name in $missing; do
    echo "    installing treesitter parser: $name"
    # TSUpdateSync blocks until the parser is built; quitall then exits
    # immediately. Without it, nvim idles until the watchdog fires.
    nvim_headless -c "TSUpdateSync $name" -c 'quitall'
  done

  # Report honestly: a healthy config prints nothing on startup.
  if nvim_startup_clean; then
    echo "    plugins installed, startup clean"
  else
    echo "    !! nvim still reports errors on startup. Open nvim and run"
    echo "       :PackerSync by hand, then restart it."
  fi
}

# ------------------------------------------------------------------ prompts ---

# Every prompt is skipped when stdin is not a terminal, so an automated or
# piped run never hangs waiting for input.
interactive() { [ -t 0 ] && [ -r /dev/tty ]; }

skip_reason() { echo "    skipped: not a terminal"; }

# ask_yn <prompt> <default y|n>
ask_yn() {
  local prompt="$1" default="$2" reply hint
  [ "$default" = y ] && hint="[Y/n]" || hint="[y/N]"
  # With no tty, take the default silently rather than letting the /dev/tty
  # redirect fail noisily on every call.
  if ! interactive; then
    case "$default" in [Yy]*) return 0 ;; *) return 1 ;; esac
  fi
  printf '%s %s ' "$prompt" "$hint" >&2
  read -r reply < /dev/tty || reply=""
  [ -z "$reply" ] && reply="$default"
  case "$reply" in [Yy]*) return 0 ;; *) return 1 ;; esac
}

# ask_line <prompt> <default>  -- echoes the answer on stdout
ask_line() {
  local prompt="$1" default="${2:-}" reply
  if [ -n "$default" ]; then
    printf '%s [%s] ' "$prompt" "$default" >&2
  else
    printf '%s ' "$prompt" >&2
  fi
  read -r reply < /dev/tty || reply=""
  [ -z "$reply" ] && reply="$default"
  printf '%s' "$reply"
}

# ask_choice <prompt> <none-label> <newline-separated-items>
# Prints the chosen item on stdout, or nothing if the 0 option is picked.
ask_choice() {
  local prompt="$1" none_label="$2" items="$3"
  local count n line reply

  items="$(printf '%s\n' "$items" | grep . || true)"
  count="$(printf '%s\n' "$items" | grep -c . || true)"
  if [ "$count" -eq 0 ]; then
    printf ''
    return 0
  fi

  echo "    $prompt" >&2
  n=0
  while IFS= read -r line; do
    n=$((n + 1))
    printf '      %d) %s\n' "$n" "$line" >&2
  done <<INNER
$items
INNER
  printf '      0) %s\n' "$none_label" >&2

  while :; do
    reply="$(ask_line "    Choice:" "1")"
    case "$reply" in
      0) printf ''; return 0 ;;
      ''|*[!0-9]*) echo "      please enter a number" >&2; continue ;;
    esac
    if [ "$reply" -ge 1 ] && [ "$reply" -le "$count" ]; then
      printf '%s' "$(printf '%s\n' "$items" | sed -n "${reply}p")"
      return 0
    fi
    echo "      out of range" >&2
  done
}

# Expand a leading ~ and make the path absolute without requiring it to exist.
abs_path() {
  local p="$1"
  case "$p" in "~") p="$HOME" ;; "~/"*) p="$HOME/${p#\~/}" ;; esac
  case "$p" in /*) ;; *) p="$PWD/$p" ;; esac
  printf '%s' "$p"
}

# -------------------------------------------------------------------- rust ---

ensure_rust() {
  # A non-login shell (cron, CI, another tool's subprocess) has no ~/.cargo/bin
  # on PATH, so `command -v cargo` alone would re-run rustup on every pass.
  if ! command -v cargo >/dev/null 2>&1 && [ -f "$HOME/.cargo/env" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.cargo/env"
  fi
  if command -v cargo >/dev/null 2>&1; then
    return 0
  fi
  echo "    choros is written in Rust, but cargo is not installed."
  echo "    rustup installs into ~/.cargo/bin, which these shell configs"
  echo "    already put on PATH."
  if ! ask_yn "    Install the Rust toolchain via rustup now?" y; then
    echo "    skipped -- install Rust yourself, then re-run: https://rustup.rs"
    return 1
  fi
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  # shellcheck disable=SC1091
  [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
  command -v cargo >/dev/null 2>&1
}

# Establish the pristine checkout the dotfiles point at, and set WIRE_DIR.
# Runs before any wiring so every block is written with the final path.
install_self() {
  echo "==> dev-setup source"

  # Running from the pristine checkout itself -- the normal case once you have
  # no development clone, since this is the only install.sh left on the machine.
  # It still has to pull, or `./install.sh` from here could never update itself.
  if [ -z "${DEV_SETUP_SELF_DIR:-}" ] && [ "$SELF_DIR" = "$REPO_DIR" ]; then
    local self_url
    self_url="$(ssh_remote "$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || echo "")")"
    if [ -n "$self_url" ]; then
      ensure_checkout "$self_url" "$SELF_DIR" || true
    fi
    WIRE_DIR="$SELF_DIR"
    return 0
  fi

  # DEV_SETUP_SELF_DIR names this clone, so it is a working copy being iterated
  # on. Never pull it -- that is the user's tree to manage.
  if [ "$SELF_DIR" = "$REPO_DIR" ]; then
    echo "    wiring this clone directly: $REPO_DIR"
    echo "    (DEV_SETUP_SELF_DIR points here; edits go live immediately)"
    WIRE_DIR="$REPO_DIR"
    return 0
  fi

  local url
  url="$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || echo "")"
  if [ -z "$url" ]; then
    echo "    !! this clone has no origin remote, so there is nothing to pull"
    echo "       from. Wiring it directly: $REPO_DIR"
    WIRE_DIR="$REPO_DIR"
    return 0
  fi

  if ! ensure_checkout "$url" "$SELF_DIR"; then
    echo "    !! could not establish $SELF_DIR. Wiring this clone instead."
    WIRE_DIR="$REPO_DIR"
    return 0
  fi
  WIRE_DIR="$SELF_DIR"

  # If this clone holds work the pristine copy cannot have, the config about to
  # go live is not the config being edited. Say so plainly -- silently wiring
  # the older tree would be the worst outcome.
  local dirty ahead
  dirty="$(git -C "$REPO_DIR" status --porcelain 2>/dev/null | wc -l | tr -d " ")"
  ahead="$(git -C "$REPO_DIR" rev-list --count "@{upstream}..HEAD" 2>/dev/null || echo 0)"
  if [ "$dirty" != "0" ] || [ "$ahead" != "0" ]; then
    echo "    note: $REPO_DIR has $dirty uncommitted file(s), $ahead unpushed commit(s)."
    echo "          Those are NOT what is wired. Push them and re-run, or set"
    echo "          DEV_SETUP_SELF_DIR=$REPO_DIR to wire this clone while iterating."
  fi
}

# kitty reads ~/.config/kitty/kitty.conf and supports `include`, so the same
# by-reference wiring works. Two includes rather than one: the shared file holds
# font, colors, the tab bar and the tab keybindings (all of which are valid on
# both platforms), and the per-OS file holds window chrome -- decorations and
# background blur, which differ.
wire_kitty() {
  echo "==> kitty"
  wire_block "$HOME/.config/kitty/kitty.conf" "#" \
             "include $WIRE_DIR/kitty/kitty.conf
include $WIRE_DIR/kitty/$OS.conf" \
             "$WIRE_DIR/kitty/kitty.conf"
}

# Hammerspoon owns the keyboard layer (Linux-style ctrl bindings) and the window
# management. Lua has no include directive, so the wired block is a dofile rather
# than a source-alike -- same by-reference intent, different spelling.
#
# GOTCHA worth remembering: after granting Hammerspoon any macOS permission you
# must QUIT AND RELAUNCH the app. "Reload Config" re-runs the Lua in the same
# process, and AXIsProcessTrusted() caches its answer per process, so a reload
# keeps reporting the stale value and the config looks broken when it is not.
wire_hammerspoon() {
  [ "$OS" = macos ] || return 0
  echo "==> hammerspoon"
  wire_block "$HOME/.hammerspoon/init.lua" "--" \
             "dofile(\"$WIRE_DIR/hammerspoon/init.lua\")" \
             "$WIRE_DIR/hammerspoon/init.lua"
}

# macOS keeps these in cfprefsd, per user. They are environment rather than
# config: there is no file to wire, no block to remove, and no way to express
# them as a dotfile. So dev-setup writes them, and writes ONLY the keys it holds
# an opinion about -- importing a whole plist would drag along window positions
# and update timestamps that are none of its business.
macos_defaults_changed=0

set_default() {
  local domain="$1" key="$2" type="$3" want="$4" have label
  if [ "$domain" = "-g" ]; then label="$key"; else label="$domain $key"; fi
  have="$(defaults read "$domain" "$key" 2>/dev/null || true)"
  if [ "$have" = "$want" ]; then
    printf '    ok   %s = %s\n' "$label" "$want"
    return 0
  fi
  defaults write "$domain" "$key" "-$type" "$want"
  printf '    set  %s = %s (was %s)\n' "$label" "$want" "${have:-unset}"
  macos_defaults_changed=1
}

# key type value. step is the pace knob and the one to expect to retune: with
# acceleration off it is the ONLY thing setting how far a notch scrolls.
MOS_SETTINGS="smooth bool 1
smoothSimTrackpad bool 0
reverse bool 1
step float 25
speed float 2.2
duration float 1.4"

mos_defaults() {
  if [ ! -d /Applications/Mos.app ]; then
    echo "    -- Mos not installed (Brewfile cask \"mos\"), settings skipped"
    return 0
  fi

  # Check for drift before touching anything, so the common case of "nothing to
  # do" does not restart a running Mos on every install.
  local drift=0 key type want have
  while read -r key type want; do
    [ -n "$key" ] || continue
    have="$(defaults read com.caldis.Mos "$key" 2>/dev/null || true)"
    [ "$have" = "$want" ] || drift=1
  done <<MOSEOF
$MOS_SETTINGS
MOSEOF

  if [ "$drift" -eq 0 ]; then
    echo "    ok   Mos: all settings current"
    return 0
  fi

  # Mos holds its prefs in memory and writes them back when it exits, so a write
  # underneath a running Mos is silently undone the next time it quits. This is
  # the whole reason for the quit/write/relaunch dance.
  local relaunch=0
  if pgrep -x Mos >/dev/null 2>&1; then
    relaunch=1
    osascript -e 'quit app "Mos"' >/dev/null 2>&1 || true
    sleep 1
    if pgrep -x Mos >/dev/null 2>&1; then killall Mos 2>/dev/null || true; sleep 1; fi
  fi

  while read -r key type want; do
    [ -n "$key" ] || continue
    set_default com.caldis.Mos "$key" "$type" "$want"
  done <<MOSEOF
$MOS_SETTINGS
MOSEOF

  [ "$relaunch" -eq 1 ] && open -a Mos
  return 0
}

apply_macos_defaults() {
  [ "$OS" = macos ] || return 0
  echo "==> macos defaults"

  # Scroll DIRECTION is a single global key -- the Trackpad and Mouse panes in
  # System Settings are both views onto it -- so per-device direction cannot be
  # expressed there at all. The split is these two settings together: macOS
  # natural ON so the trackpad scrolls naturally, and Mos reverse ON to flip the
  # wheel back. Neither half means anything without the other.
  set_default -g com.apple.swipescrolldirection bool 1

  # -1 disables wheel acceleration outright. ANY positive value re-enables
  # macOS's curve, which damps slow scrolling and multiplies fast scrolling; the
  # symptom is a breakpoint where the page suddenly flies. Linear means a fast
  # spin is just more notches, each travelling the same distance. Wheel only --
  # the trackpad is pixel-continuous and never reads this key.
  set_default -g com.apple.scrollwheel.scaling float -1

  set_default -g com.apple.mouse.scaling float 1.5

  # Keep Spaces in a fixed order so an index means the same thing tomorrow.
  set_default com.apple.dock mru-spaces bool 0

  mos_defaults

  # Deliberately NOT set here: com.apple.spaces spans-displays. It is at the
  # macOS default, so dev-setup has no opinion to enforce -- and flipping it
  # rearranges every existing window. See README if you want displays to share
  # one Space.

  if [ "$macos_defaults_changed" -eq 1 ]; then
    echo "    note: WindowServer reads the pointer and scroll scaling keys at"
    echo "          LOGIN, so log out and back in for those to fully apply."
  fi
}

# Claude Code reads ~/.claude/CLAUDE.md as global instructions. Wire it by
# reference like every other dotfile, using CLAUDE.md's own @import syntax, so
# the content is version-controlled here and a pull updates it.
#
# The file lives at claude/CLAUDE.md rather than the repo root on purpose: a root
# CLAUDE.md would also be picked up as dev-setup's *project* instructions, so
# global rules would apply twice here and anything repo-specific would leak into
# every other project.
wire_claude() {
  echo "==> claude global instructions"
  wire_block "$HOME/.claude/CLAUDE.md" "<!--" "@$WIRE_DIR/claude/CLAUDE.md" \
             "$WIRE_DIR/claude/CLAUDE.md" "dev-setup" "-->"
}

# ---------------------------------------------------------------- workspaces ---

# A choros project root is any dir containing .choros-config/registry.
registry_of() { printf '%s/.choros-config/registry' "$1"; }

# Force github remotes to SSH. This matters far more than it looks: a registry
# entry is the clone SOURCE for every workspace choros ever creates, so an HTTPS
# origin there is inherited forever -- and since GitHub dropped password auth in
# 2021, every inheriting clone can fetch but never push, failing with a
# credential prompt that cannot succeed. register_dev_sources copies the remote
# of whatever checkout install.sh happens to be run from, so without this one
# HTTPS clone anywhere reintroduces the problem for good.
# `choros add <ssh-url>` is the official way to populate a registry: it enforces
# ssh URLs and derives the entry name from the URL itself. It is deliberately not
# idempotent -- a second add of the same repo exits 1 with "already exists" -- and
# install.sh must stay re-runnable, so check for the entry before calling rather
# than printing an error on every re-run.
choros_add() {
  local reg="$1" url name root dest
  url="$(ssh_remote "$2")"
  [ -n "$url" ] || return 0
  name="$(basename "${url%.git}")"
  root="${reg%/.choros-config/registry}"
  dest="$reg/$name"

  if [ -d "$dest/.git" ]; then
    echo "      already registered: $name"
    return 0
  fi
  if ! command -v choros >/dev/null 2>&1; then
    echo "      !! choros not on PATH, cannot register $name"
    return 0
  fi
  # Run from the root: choros resolves the registry relative to the cwd.
  if ( cd "$root" && choros add "$url" >/dev/null 2>&1 ); then
    echo "      registered: $name"
  else
    echo "      !! choros add failed: $url"
  fi
}

ssh_remote() {
  case "$1" in
    https://github.com/*)
      local path="${1#https://github.com/}"
      printf 'git@github.com:%s' "${path%.git}.git" ;;
    *) printf '%s' "$1" ;;
  esac
}

# Existing top-level git repos in a workspace root. These are "direct clones":
# they predate the workspace and are not managed by choros. We register them so
# choros can see them, but never move or delete them.
list_direct_clones() {
  local root="$1" d
  [ -d "$root" ] || return 0
  for d in "$root"/*/; do
    [ -d "$d" ] || continue
    d="${d%/}"
    case "$(basename "$d")" in .choros-config) continue ;; esac
    # Skip choros workspaces -- those are managed, not direct clones.
    [ -f "$d/.choros-meta.toml" ] && continue
    [ -e "$d/.git" ] || continue
    printf '%s\n' "$d"
  done
}

# Write the workspace's own git identity and ssh key, and point ~/.gitconfig at
# it. Both live with the workspace, so neither lands in this public repo.
#
# The key belongs here beside the identity rather than in ~/.ssh/config, because
# that file keys off the host and both roots reach the same host (github.com) as
# different accounts. Pinning one key there wins globally and leaves the other
# root unable to even read its remotes -- and since GitHub hides a private repo
# instead of reporting a permission error, that surfaces as the thoroughly
# misleading "Repository not found".
setup_workspace_identity() {
  local root="$1" cfg name email key cur_name cur_email cur_key
  # Strip a trailing slash before anything interpolates it. gitdir: patterns are
  # matched literally, so "gitdir:$root/" on a root that already ended in "/"
  # produced "gitdir:/path/psrc//" -- which silently matches nothing, leaving
  # every repo under that root with no identity and commits authored to a
  # hostname fallback. Callers pass roots both ways, so normalise here.
  root="${root%/}"
  cfg="$root/.choros-config/gitconfig"

  cur_name=""; cur_email=""; cur_key=""
  if [ -f "$cfg" ]; then
    cur_name="$(git config --file "$cfg" --get user.name  || true)"
    cur_email="$(git config --file "$cfg" --get user.email || true)"
    # Recover the bare key path from the stored command. The identity write
    # below truncates this file, so anything not read back here is lost.
    cur_key="$(git config --file "$cfg" --get core.sshCommand 2>/dev/null \
      | sed -n 's/^ssh -i \([^ ]*\).*/\1/p')"
  fi

  name="$(ask_line "    git user.name  for $root:" "$cur_name")"
  email="$(ask_line "    git user.email for $root:" "$cur_email")"

  if [ -z "$name" ] || [ -z "$email" ]; then
    echo "    identity left unset for $root"
    return 0
  fi

  printf '[user]\n\tname = %s\n\temail = %s\n' "$name" "$email" > "$cfg"
  echo "    identity: $name <$email> -> $cfg"

  key="$(ask_line "    ssh key     for $root (blank for ssh defaults):" "$cur_key")"
  if [ -n "$key" ]; then
    key="$(abs_path "$key")"
    # Advisory, not fatal: keys are often provisioned after the first install.
    [ -f "$key" ] || echo "    warning: $key does not exist yet"
    # IdentitiesOnly is the point of the exercise -- without it ssh still offers
    # whatever the agent holds first and can authenticate as the wrong account.
    git config --file "$cfg" core.sshCommand "ssh -i $key -o IdentitiesOnly=yes"
    echo "    ssh key: $key -> $cfg"
  else
    echo "    ssh key left unset for $root (ssh defaults apply)"
  fi

  # gitdir: needs the trailing slash to match everything beneath the root. The
  # include also covers `git clone` into the root -- git tests the gitdir
  # condition against the clone destination -- so the key is in force for the
  # very first fetch, not just for commits made later.
  wire_block "$HOME/.gitconfig" "#" "[includeIf \"gitdir:$root/\"]
	path = $cfg" "gitdir:$root/" "dev-setup identity $root"
}

setup_one_workspace() {
  local root reg clone
  root="$(abs_path "$(ask_line "    Workspace directory:" "")")"
  if [ -z "$root" ]; then
    echo "    no path given, skipped"
    return 1
  fi

  reg="$(registry_of "$root")"
  if [ -d "$reg" ]; then
    echo "    already a choros root: $root"
  else
    mkdir -p "$reg"
    echo "    created: $reg"
  fi

  # Flag pre-existing direct clones and offer to register them. The clone
  # itself is left exactly where it is, for you to clean up in your own time.
  # A registry entry is a fresh clone of the upstream default branch, never a
  # copy or a symlink of a working directory -- choros re-clones from it, so it
  # must be clean. Your existing clone is left exactly where it is, with all its
  # uncommitted state, for you to clean up whenever you like.
  local clones oldifs name link url
  clones="$(list_direct_clones "$root")"
  if [ -n "$clones" ]; then
    oldifs="$IFS"; IFS=$'\n'
    for clone in $clones; do
      IFS="$oldifs"
      name="$(basename "$clone")"
      link="$reg/$name"

      if [ "$clone" = "$REPO_DIR" ]; then
        echo "    direct clone $name: this repo, handled by the move step below"
        IFS=$'\n'; continue
      fi
      if [ -e "$link" ]; then
        echo "    direct clone $name: already in registry"
        IFS=$'\n'; continue
      fi

      echo "    direct clone found: $clone"
      url="$(git -C "$clone" remote get-url origin 2>/dev/null || true)"
      if [ -z "$url" ]; then
        echo "      !! no origin remote, cannot re-clone -- skipped"
        IFS=$'\n'; continue
      fi
      if ask_yn "      re-clone $url into the registry?" y; then
        if git clone "$url" "$link"; then
          echo "      re-cloned: $link"
          echo "      your original at $clone is untouched"
        else
          echo "      !! clone failed, skipped"
          rm -rf "$link"
        fi
      fi
      IFS=$'\n'
    done
    IFS="$oldifs"
  fi

  setup_workspace_identity "$root"
  WORKSPACES="$WORKSPACES$root
"
  return 0
}

setup_workspaces() {
  echo "==> choros workspaces"
  if ! interactive; then
    skip_reason
    return 0
  fi
  if ! ask_yn "    Set up a choros workspace directory?" y; then
    echo "    skipped"
    return 0
  fi
  while :; do
    setup_one_workspace || true
    ask_yn "    Set up another workspace?" n || break
  done
}

# Choros roots to offer: ones created this run, any directly under $HOME, and
# any ancestor of this repo. Deduplicated.
discover_choros_roots() {
  {
    printf '%s\n' "$WORKSPACES"
    local d
    for d in "$HOME"/*/; do
      [ -d "$d" ] || continue
      [ -d "${d}.choros-config/registry" ] && printf '%s\n' "${d%/}"
    done
    d="$REPO_DIR"
    while [ -n "$d" ] && [ "$d" != "/" ]; do
      [ -d "$d/.choros-config/registry" ] && printf '%s\n' "$d"
      d="$(dirname "$d")"
    done
  } | grep . | sort -u
}

# Pick a destination registry from a numbered list of known choros roots.
choose_registry() {
  local prompt="$1" none_label="$2" root
  root="$(ask_choice "$prompt" "$none_label" "$(discover_choros_roots)")"
  [ -n "$root" ] || { printf ''; return 0; }
  printf '%s' "$(registry_of "$root")"
}

# -------------------------------------------------------------------- tools ---

# name|clone-url|kind|binary
# Every tool answers to ./install.sh at its root, and that script owns every
# deployment decision -- what to build, where the binary goes, how to clean up
# after a rename. dev-setup used to build the Rust ones itself with `cargo
# install --path`, which meant two places knew how Choros installs and they
# disagreed: two binaries at different commits, the stale one earlier on PATH.
# One uniform path is the fix; a smarter dispatch was not.
TOOLS="Choros|git@github.com:Harrichael/Choros.git
LatticeQL|git@github.com:Harrichael/LatticeQL.git
Gnomon|git@github.com:Harrichael/Gnomon.git"

# Records the commit each tool was last built from. `cargo install` re-links on
# every invocation otherwise, and these packages do not bump their version
# between commits, so cargo alone can neither skip reliably nor detect changes.
STAMP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dev-setup"

# The authoritative checkout of each tool. dev-setup owns this directory: it is
# never developed in, only pulled and re-installed from, so every install has a
# known provenance and a `git pull` here is the whole update.
#
# It deliberately does NOT live in a choros registry. A registry holds *clone
# sources* -- its layout is choros's to change (bare entries, for one, have no
# working tree at all, and `cargo install --path` needs one), and a deploy path
# that reaches into another tool's data structure breaks when that tool
# evolves. It also put a second, identical-looking checkout of every tool on
# disk, which is its own hazard.
#
# XDG_DATA_HOME is the portability seam, so there is no per-OS branch here: it
# is honoured on both platforms, and macOS's ~/Library/Application Support
# convention is for GUI apps, not CLI tools. This also pairs with STAMP_DIR
# above, which is already XDG_STATE_HOME.
#
# Set DEV_SETUP_TOOLS_DIR to move it, or DEV_SETUP_TOOLS_REGISTRY to a workspace
# root to go back to registry-hosted installs.
TOOLS_DIR="${DEV_SETUP_TOOLS_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/dev-setup/tools}"

# Clone if absent; update only when --update was given. A missing checkout has
# no version to preserve, so cloning it is not an update.
ensure_checkout() {
  local url="$1" dest="$2"
  if [ -d "$dest/.git" ]; then
    if [ "$UPDATE" -eq 0 ]; then
      echo "      at $(git -C "$dest" rev-parse --short HEAD 2>/dev/null || echo unknown) (--update to pull)"
      return 0
    fi
    # A pinned checkout is detached, which is a deliberate state, not a
    # problem -- say so rather than blaming a dirty tree.
    if ! git -C "$dest" symbolic-ref -q HEAD >/dev/null; then
      echo "      pinned at $(git -C "$dest" rev-parse --short HEAD), not updating"
      echo "        (git -C $dest checkout main   to unpin)"
      return 0
    fi
    if git -C "$dest" pull --ff-only --quiet 2>/dev/null; then
      echo "      pulled: $dest"
    else
      echo "      !! pull failed (local commits or dirty tree?), using as-is"
    fi
  else
    if git clone --quiet "$url" "$dest"; then
      echo "      cloned: $dest"
    else
      echo "      !! clone failed, skipped"
      rm -rf "$dest"
      return 1
    fi
  fi
}

# dev-setup used to `cargo install --path` the Rust tools, so on any machine
# provisioned before that changed there is a binary in ~/.cargo/bin that nothing
# will ever update again. Once ~/.local/bin goes ahead of ~/.cargo/bin on PATH it
# is merely shadowed, not gone -- and a shadowed stale binary is the bug waiting
# to resurface the next time PATH order changes. dev-setup created them, so
# dev-setup removes them.
#
# Only packages cargo recorded as installed FROM this tools directory are
# touched; a hand-run `cargo install` of anything else is the user's business.
# Deletable once every machine has run this at least once.
drop_cargo_installed_tools() {
  local base="$1" crates="${CARGO_HOME:-$HOME/.cargo}/.crates.toml" pkg
  [ -f "$crates" ] || return 0
  command -v cargo >/dev/null 2>&1 || return 0

  for pkg in $(awk -v b="$base" '
        /^"/ {
          line = $0
          sub(/^"/, "", line)
          split(line, f, " ")
          if (index(line, "path+file://" b "/") > 0) print f[1]
        }' "$crates"); do
    if cargo uninstall "$pkg" >/dev/null 2>&1; then
      echo "    removed superseded cargo install: $pkg"
    fi
  done
}

run_tool_installer() {
  local name="$1" dest="$2"
  if [ ! -x "$dest/install.sh" ]; then
    echo "      !! no executable install.sh, skipped"
    return 0
  fi
  # Its own installer owns the deployment decisions; do not second-guess them.
  # Capture first and print after, so the exit status is the installer's and not
  # sed's -- a failing installer must be surfaced, never swallowed. Gnomon for
  # instance exits 1 on a malformed ~/.claude/settings.json and deploys nothing.
  local out status
  out="$( cd "$dest" && ./install.sh 2>&1 )" && status=0 || status=$?
  [ -n "$out" ] && printf '%s\n' "$out" | sed 's/^/      /'
  if [ "$status" -ne 0 ]; then
    echo "      !! $name install.sh failed (exit $status) -- nothing was deployed"
    return 0
  fi

  # Record what was deployed, the same as a cargo tool. This is a *record*, not
  # a skip condition: re-running the installer every pass is the update path for
  # these tools, and for Gnomon it is also the smoke gate that keeps a broken
  # copy from going live. So stamp it and always run again next time.
  local stamp head previous=""
  stamp="$STAMP_DIR/$name.sha"
  head="$(git -C "$dest" rev-parse HEAD 2>/dev/null || echo unknown)"
  [ -f "$stamp" ] && previous="$(cat "$stamp")"
  if [ -n "$previous" ] && [ "$previous" != "$head" ]; then
    echo "      deployed ${previous%"${previous#???????}"} -> ${head%"${head#???????}"}"
  fi
  mkdir -p "$STAMP_DIR"
  printf '%s\n' "$head" > "$stamp"
}

install_tools() {
  echo "==> tools"

  local base
  if [ -n "${DEV_SETUP_TOOLS_REGISTRY:-}" ]; then
    # Explicit opt-in to registry-hosted installs. Accepts either a workspace
    # root or the registry directory itself.
    case "$DEV_SETUP_TOOLS_REGISTRY" in
      */.choros-config/registry) base="$DEV_SETUP_TOOLS_REGISTRY" ;;
      *) base="$(registry_of "$(abs_path "$DEV_SETUP_TOOLS_REGISTRY")")" ;;
    esac
    echo "    destination from DEV_SETUP_TOOLS_REGISTRY: $base"
  else
    base="$TOOLS_DIR"
    if interactive && ! ask_yn "    Install/update tools (choros, latticeql, gnomon) in $base?" y; then
      echo "    skipped"
      return 0
    fi
    [ -n "${DEV_SETUP_TOOLS_DIR:-}" ] && echo "    destination from DEV_SETUP_TOOLS_DIR: $base"
  fi

  mkdir -p "$base"
  TOOLS_BASE="$base"

  # Providing the toolchain is machine provisioning, so it stays dev-setup's job
  # even though building is not. The installers check for cargo themselves and
  # fail loudly without it, which is what a standalone clone needs.
  ensure_rust || echo "    !! cargo unavailable; Rust tools will report it"

  drop_cargo_installed_tools "$base"

  local line name url dest oldifs
  oldifs="$IFS"; IFS=$'\n'
  for line in $TOOLS; do
    IFS="$oldifs"
    name="$(printf '%s' "$line" | cut -d'|' -f1)"
    url="$(printf '%s' "$line" | cut -d'|' -f2)"
    dest="$base/$name"

    echo "    --- $name"
    if ensure_checkout "$url" "$dest"; then
      run_tool_installer "$name" "$dest"
      report_stale_copies "$name" "$dest"
    fi
    IFS=$'\n'
  done
  IFS="$oldifs"
}

# A registry copy of a tool may be a deliberate development clone (see
# register_dev_sources) or leftover from when installs came from the registry.
# Either way nothing installs from it, and it looks identical to the checkout
# that does -- so name it rather than let it mislead. Never delete it here.
report_stale_copies() {
  local name="$1" live="$2" root reg other
  for root in $(discover_choros_roots); do
    reg="$(registry_of "$root")"
    other="$reg/$name"
    [ "$other" = "$live" ] && continue
    [ -d "$other/.git" ] || continue
    echo "      note: another checkout exists at $other (not installed from)"
  done
}

# ------------------------------------------------------- relocate dev-setup ---

# Moving this repo means every wired path changes, so the move is the last thing
# that happens and the script re-execs itself from the new location to re-wire.
# dev-setup's authoritative location is wherever it was cloned -- for the same
# reason the tools moved out of the registry: a registry holds clone sources,
# not deploy state, and the dotfiles point at this checkout by reference.
# (An earlier version moved this repo into a registry. That produced exactly the
# hazard it was warned about: a second, identical-looking checkout that drifted
# commits behind and got read as the live one.)
#
# What a registry IS good for is development: entries are what a new choros
# clones, so putting these repos there is how you get a workspace to hack on
# them in. Nothing here is ever installed from -- that is TOOLS_DIR's job.
register_dev_sources() {
  echo "==> development clones (optional)"

  if ! interactive; then
    skip_reason
    return 0
  fi

  echo "    Registry entries are what a new choros clones, so this is how you"
  echo "    get a workspace to develop these repos in. Installs still come from"
  echo "    $TOOLS_DIR, not from here."

  local reg
  reg="$(choose_registry "Clone dev-setup and the tool repos into which registry?" \
                         "don't -- skip this")"
  [ -n "$reg" ] || { echo "    skipped"; return 0; }

  mkdir -p "$reg"

  local self_url line name url oldifs
  self_url="$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || echo "")"

  if [ -n "$self_url" ]; then
    echo "    --- dev-setup"
    choros_add "$reg" "$self_url"
  else
    echo "    --- dev-setup: no origin remote, skipped"
  fi

  oldifs="$IFS"; IFS=$'\n'
  for line in $TOOLS; do
    IFS="$oldifs"
    name="$(printf '%s' "$line" | cut -d'|' -f1)"
    url="$(printf '%s' "$line" | cut -d'|' -f2)"
    echo "    --- $name"
    choros_add "$reg" "$url"
    IFS=$'\n'
  done
  IFS="$oldifs"
}

# Every component now records where it came from, but in three different places:
# cargo tools in ~/.cargo/.crates.toml, script tools in whatever their own
# installer writes, and dev-setup itself only implicitly, in the paths embedded
# in the dotfiles it wired. That is enough to answer "which checkout is live?"
# only if you already know where to look for each one.
#
# So write one file that answers it for everything, dev-setup included. It is a
# report, not state: nothing reads it back, and deleting it breaks nothing.
record_provenance() {
  local out="$STAMP_DIR/provenance" line name dest head dirty
  mkdir -p "$STAMP_DIR"

  {
    echo "# Written by dev-setup install.sh. A report, not state."
    echo "# component  source-checkout  commit  dirty"
    echo

    # The wired checkout is the one that matters -- it is what the dotfiles
    # read. List the running clone too, and only when it is a different tree,
    # so it is obvious which one is live and which one you were editing.
    head="$(git -C "$WIRE_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
    dirty=clean
    [ -n "$(git -C "$WIRE_DIR" status --porcelain 2>/dev/null)" ] && dirty=DIRTY
    printf 'dev-setup(wired)\t%s\t%s\t%s\n' "$WIRE_DIR" "$head" "$dirty"

    if [ "$REPO_DIR" != "$WIRE_DIR" ]; then
      head="$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
      dirty=clean
      [ -n "$(git -C "$REPO_DIR" status --porcelain 2>/dev/null)" ] && dirty=DIRTY
      printf 'dev-setup(ran from)\t%s\t%s\t%s\n' "$REPO_DIR" "$head" "$dirty"
    fi

    [ -n "${TOOLS_BASE:-}" ] || return 0
    local oldifs; oldifs="$IFS"; IFS=$'\n'
    for line in $TOOLS; do
      IFS="$oldifs"
      name="$(printf '%s' "$line" | cut -d'|' -f1)"
      dest="$TOOLS_BASE/$name"
      if [ -d "$dest/.git" ]; then
        head="$(git -C "$dest" rev-parse --short HEAD 2>/dev/null || echo unknown)"
        dirty=clean
        [ -n "$(git -C "$dest" status --porcelain 2>/dev/null)" ] && dirty=DIRTY
        printf '%s\t%s\t%s\t%s\n' "$name" "$dest" "$head" "$dirty"

        # A checkout's HEAD is not proof of what is live: any clone can run the
        # installer and become the deployed version. Tools that leave a receipt
        # say so themselves, so report that separately rather than inferring it.
        local receipt rbin rcommit rdirty
        receipt="${XDG_STATE_HOME:-$HOME/.local/state}/$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')/receipt"
        if [ -f "$receipt" ]; then
          rbin="$(sed -n 's/^bin=//p' "$receipt")"
          rcommit="$(sed -n 's/^commit=//p' "$receipt")"
          rdirty=clean
          [ "$(sed -n 's/^dirty=//p' "$receipt")" = yes ] && rdirty=DIRTY
          printf '%s(deployed)\t%s\t%s\t%s\n' "$name" "${rbin:-unknown}" "${rcommit:-unknown}" "$rdirty"
        fi
      fi
      IFS=$'\n'
    done
    IFS="$oldifs"
  } > "$out"

  echo "==> provenance"
  # The file is tab-separated so it stays greppable; align it only for display.
  grep -v -e '^#' -e '^[[:space:]]*$' "$out" \
    | { command -v column >/dev/null 2>&1 && column -t -s "$(printf '\t')" || cat; } \
    | sed 's/^/    /'
  echo "    (written to $out)"

  # dev-setup gets the same courtesy the tools get: name any other checkout of
  # itself, since the dotfiles point at exactly one and the others are inert.
  local root other
  for root in $(discover_choros_roots); do
    other="$(registry_of "$root")/$(basename "$REPO_DIR")"
    [ "$other" = "$REPO_DIR" ] && continue
    [ "$other" = "$WIRE_DIR" ] && continue
    [ -d "$other/.git" ] || continue
    echo "    note: another dev-setup checkout exists at $other (nothing points at it)"
  done
}

# -------------------------------------------------------------------- main ---

WORKSPACES=""
TOOLS_BASE=""

install_packages
echo
setup_workspaces
install_self
install_tools
register_dev_sources
echo
wire_shell
wire_gitconfig
wire_nvim
wire_kitty
wire_claude
wire_hammerspoon
apply_macos_defaults
echo
setup_node
setup_nvim_plugins
echo
record_provenance

echo
echo "Done. Open a new shell (or: exec \$SHELL -l)."

# Surface the one thing that cannot be automated: gitconfig intentionally pins
# no identity, and commits fail until it is set.
if ! git config --get user.email >/dev/null 2>&1; then
  echo
  echo "Remaining manual step -- git identity is not set, commits will fail:"
  echo "  git config --global user.name  \"Your Name\""
  echo "  git config --global user.email \"you@example.com\""
fi
