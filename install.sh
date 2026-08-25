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
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    echo "    sudo apt install neovim git tree ripgrep"
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
wire_block() {
  local file="$1" cp="$2" payload="$3" needle="$4" label="${5:-dev-setup}"
  local begin="$cp >>> $label >>>" end="$cp <<< $label <<<"

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
    rc="$HOME/.zshrc"; target="$REPO_DIR/zshrc"
  else
    rc="$HOME/.bashrc"; target="$REPO_DIR/bashrc"
  fi
  echo "==> shell rc"
  wire_block "$rc" "#" "export BASE_PATH=\"\$HOME\"
source \"$target\"" "$target"
}

wire_gitconfig() {
  echo "==> gitconfig"
  wire_block "$HOME/.gitconfig" "#" "[include]
	path = $REPO_DIR/gitconfig" "$REPO_DIR/gitconfig"
}

wire_nvim() {
  echo "==> nvim init.lua"
  wire_block "$HOME/.config/nvim/init.lua" "--" "package.path = \";$REPO_DIR/nvim/?.lua;\" .. package.path
vim.opt.runtimepath:append(\"$REPO_DIR/nvim\")
require(\"plugins_base\")
require(\"init_base\")" "$REPO_DIR/nvim"
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

# ---------------------------------------------------------------- workspaces ---

CHOROS_URL="${CHOROS_URL:-https://github.com/Harrichael/Choros}"

# A choros project root is any dir containing .choros-config/registry.
registry_of() { printf '%s/.choros-config/registry' "$1"; }

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

# Write the workspace's own git identity and point ~/.gitconfig at it. The
# identity lives with the workspace, so it never lands in this public repo.
setup_workspace_identity() {
  local root="$1" cfg name email cur_name cur_email
  cfg="$root/.choros-config/gitconfig"

  cur_name=""; cur_email=""
  if [ -f "$cfg" ]; then
    cur_name="$(git config --file "$cfg" --get user.name  || true)"
    cur_email="$(git config --file "$cfg" --get user.email || true)"
  fi

  name="$(ask_line "    git user.name  for $root:" "$cur_name")"
  email="$(ask_line "    git user.email for $root:" "$cur_email")"

  if [ -z "$name" ] || [ -z "$email" ]; then
    echo "    identity left unset for $root"
    return 0
  fi

  printf '[user]\n\tname = %s\n\temail = %s\n' "$name" "$email" > "$cfg"
  echo "    identity: $name <$email> -> $cfg"

  # gitdir: needs the trailing slash to match everything beneath the root.
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
#   cargo  -- cargo install --path, so the binary lands in ~/.cargo/bin, which
#             both shell configs already put on PATH
#   script -- run the repo's own install.sh and let it decide what to do.
#             Gnomon deliberately deploys a copy to ~/.claude and pins
#             statusLine at it, so wiring it by reference instead would be
#             silently reverted by its next install. Since this runs its
#             installer on every pass, a pull here is a redeploy anyway.
TOOLS="Choros|git@github.com:Harrichael/Choros.git|cargo|choros
LatticeQL|git@github.com:Harrichael/LatticeQL.git|cargo|latticeql
Gnomon|git@github.com:Harrichael/Gnomon.git|script|"

# Records the commit each tool was last built from. `cargo install` re-links on
# every invocation otherwise, and these packages do not bump their version
# between commits, so cargo alone can neither skip reliably nor detect changes.
STAMP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dev-setup"

clone_or_pull() {
  local url="$1" dest="$2"
  if [ -d "$dest/.git" ]; then
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

# Is the installed binary the one cargo built from this exact directory? Cargo
# records the source path per package, and a binary left over from a clone
# somewhere else is stale even when the commit matches.
cargo_installed_from() {
  local dest="$1" crates="${CARGO_HOME:-$HOME/.cargo}/.crates.toml"
  [ -f "$crates" ] || return 1
  grep -qF "(path+file://$dest)" "$crates"
}

build_cargo_tool() {
  local name="$1" dest="$2" bin="$3"
  local stamp="$STAMP_DIR/$name.sha" head installed=""

  ensure_rust || { echo "      !! cargo unavailable, not built"; return 0; }

  head="$(git -C "$dest" rev-parse HEAD 2>/dev/null || echo unknown)"
  [ -f "$stamp" ] && installed="$(cat "$stamp")"

  if [ "$installed" = "$head" ] && command -v "$bin" >/dev/null 2>&1 \
     && cargo_installed_from "$dest"; then
    echo "      already built at ${head%"${head#???????}"}"
    return 0
  fi

  # Say so when the reason for rebuilding is provenance rather than a new
  # commit -- e.g. the binary was installed from a stray clone elsewhere.
  if [ "$installed" = "$head" ] && ! cargo_installed_from "$dest"; then
    echo "      re-installing: current binary was not built from this registry copy"
  fi

  echo "      building (a cold build can take several minutes)"
  if cargo install --path "$dest" --force >/dev/null 2>&1; then
    mkdir -p "$STAMP_DIR"
    printf '%s\n' "$head" > "$stamp"
    echo "      installed: $(command -v "$bin" 2>/dev/null || echo "$bin")"
  else
    echo "      !! build failed. Run for the error:"
    echo "         cargo install --path $dest --force"
  fi
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
  fi
}

install_tools() {
  echo "==> tools"

  local reg base
  if [ -n "${DEV_SETUP_TOOLS_REGISTRY:-}" ]; then
    # Unattended entry point: name the destination and no prompts are asked.
    # Accepts either a workspace root or the registry directory itself.
    case "$DEV_SETUP_TOOLS_REGISTRY" in
      */.choros-config/registry) reg="$DEV_SETUP_TOOLS_REGISTRY" ;;
      *) reg="$(registry_of "$(abs_path "$DEV_SETUP_TOOLS_REGISTRY")")" ;;
    esac
    echo "    destination from DEV_SETUP_TOOLS_REGISTRY: $reg"
  elif ! interactive; then
    skip_reason
    echo "    (set DEV_SETUP_TOOLS_REGISTRY=<workspace root> to install unattended)"
    return 0
  elif ! ask_yn "    Install/update tools (choros, latticeql, gnomon)?" y; then
    echo "    skipped"
    return 0
  else
    reg="$(choose_registry "Which workspace registry should hold the tool clones?" \
                           "clone them beside dev-setup instead")"
  fi

  if [ -n "$reg" ]; then
    mkdir -p "$reg"
    base="$reg"
  else
    base="$(dirname "$REPO_DIR")"
  fi

  local line name url kind bin dest oldifs
  oldifs="$IFS"; IFS=$'\n'
  for line in $TOOLS; do
    IFS="$oldifs"
    name="$(printf '%s' "$line" | cut -d'|' -f1)"
    url="$(printf '%s' "$line" | cut -d'|' -f2)"
    kind="$(printf '%s' "$line" | cut -d'|' -f3)"
    bin="$(printf '%s' "$line" | cut -d'|' -f4)"
    dest="$base/$name"

    echo "    --- $name"
    if clone_or_pull "$url" "$dest"; then
      case "$kind" in
        cargo)  build_cargo_tool "$name" "$dest" "$bin" ;;
        script) run_tool_installer "$name" "$dest" ;;
      esac
    fi
    IFS=$'\n'
  done
  IFS="$oldifs"
}

# ------------------------------------------------------- relocate dev-setup ---

# Moving this repo means every wired path changes, so the move is the last thing
# that happens and the script re-execs itself from the new location to re-wire.
relocate_self() {
  echo "==> dev-setup location"
  if ! interactive; then
    skip_reason
    return 0
  fi

  local reg dest
  reg="$(choose_registry "Move dev-setup into which workspace registry?" \
                         "leave it where it is")"
  [ -n "$reg" ] || { echo "    staying at $REPO_DIR"; return 0; }

  dest="$reg/$(basename "$REPO_DIR")"
  if [ "$dest" = "$REPO_DIR" ]; then
    echo "    already at $REPO_DIR"
    return 0
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    echo "    !! $dest already exists, not moving"
    return 0
  fi

  echo "    $REPO_DIR"
  echo "    -> $dest"
  ask_yn "    Move it?" y || { echo "    skipped"; return 0; }

  mkdir -p "$(dirname "$dest")"
  mv "$REPO_DIR" "$dest"

  # Point the rest of this run at the new location. The dotfile wiring runs
  # after this, so every block is written with the final path -- no second pass
  # and no window where a dotfile points at a directory that no longer exists.
  REPO_DIR="$dest"
  echo "    moved. wiring below will use the new location."
}

# -------------------------------------------------------------------- main ---

WORKSPACES=""

install_packages
echo
# Workspaces and the move come first, so that dotfile wiring below records the
# final dev-setup location in one pass.
setup_workspaces
install_tools
relocate_self
echo
wire_shell
wire_gitconfig
wire_nvim
echo
setup_node
setup_nvim_plugins

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
