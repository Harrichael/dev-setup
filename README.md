# Setup

Personal dev environment: shell config, git aliases, and a Neovim setup.
Supports Linux (bash) and macOS (zsh).

Clone it anywhere — nothing assumes a particular path. `install.sh` resolves the
repo location from its own path, so `~/dev-setup`, `~/psrc/dev-setup`, or
anywhere else all work.

Jump to [macOS](#installing-on-macos) or [Linux](#installing-on-linux).

---

## Installing on macOS

Shell config is `zshrc`. macOS ships bash 3.2 and defaults to zsh, so the Mac
side deliberately does not use `bashrc`.

**1. Install Homebrew.** This also pulls in Apple's Command Line Tools, which is
where `git` comes from on a fresh machine.

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**2. Run the `shellenv` line Homebrew prints** under "Next steps". It goes in
`~/.zprofile` and puts brew on your `PATH`:

```
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Don't skip this. `zshrc` finds nvim, fnm, and delta through brew's `PATH`, and
if brew is missing they are skipped *silently* rather than erroring.

**3. Add an ssh key to your GitHub account**
([guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)),
or use an `https://` clone URL below instead.

**4. Clone and install.**

```
git clone git@github.com:Harrichael/dev-setup.git
cd dev-setup
./install.sh
```

**5. Open a new shell** — `exec zsh -l`, or just a new terminal tab.

**6. Set your git identity.** `gitconfig` deliberately pins no name or email, so
commits fail until you do this. `install.sh` reminds you if it's unset. Repos
inside a choros workspace get their own identity instead — see
[Choros workspaces](#choros-workspaces).

```
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
```

---

## Installing on Linux

Shell config is `bashrc`.

**1. Install the packages.** `install.sh` prints this list too, but it can't
install them for you:

```
sudo apt install neovim git tree ripgrep

# git-delta: https://github.com/dandavison/delta/releases
# fnm:
curl -fsSL https://fnm.vercel.app/install | bash
```

If `nvim` is too old, see [troubleshooting.md](troubleshooting.md) — some distros
don't package a current build.

**2. Add an ssh key to your GitHub account**
([guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)),
or use an `https://` clone URL below instead.

**3. Clone and install.**

```
git clone git@github.com:Harrichael/dev-setup.git
cd dev-setup
./install.sh
```

**4. Open a new shell** — `exec bash -l`, or a new terminal tab.

**5. Set your git identity** (see step 6 in the macOS section above).

**Optional — root shell.** Add to `/root/.bashrc`:

```
source "<REPO_DIR>/bashrc"
```

**Optional — `rc.local`.** Linux-only and unused on macOS. `chmod +x
/etc/rc.local`, then:

```
#! /bin/sh

source "<REPO_DIR>/rc.local"
```

---

## What install.sh does

Idempotent — re-running reports what's already in place and changes nothing. A
re-run with everything installed takes about a second.

| Step | Action |
| --- | --- |
| Packages | macOS: `brew bundle`. Linux: prints the list to install yourself. |
| Choros workspaces | Interactive, defaults to yes. Creates choros roots, re-clones pre-existing repos into the registry, and sets a per-workspace git identity. |
| Tools | Interactive, defaults to yes. Clones/updates Choros, LatticeQL, and Gnomon into a workspace registry and installs each. Installs Rust via rustup first if needed. See [Tools](#tools). |
| Relocate | Interactive. Moves this repo into a workspace registry. Runs before the dotfile wiring, so paths are recorded once. |
| Dotfiles | Wires `~/.zshrc` or `~/.bashrc`, `~/.gitconfig`, and `~/.config/nvim/init.lua`, creating each if absent. |
| Node | `fnm install --lts` + `fnm default lts-latest`, only if no version exists. fnm ships no Node of its own, so `node`/`npx` — and the `nx` aliases — don't work until this runs. |
| Neovim | Checks health first; only bootstraps packer, runs `PackerSync`, and builds missing treesitter parsers if something is actually missing. |
| Git identity | Not automated for the global default. Prints the commands if `user.email` is unset. |

The Neovim step exists because a cold `nvim` launch is otherwise ugly: packer
clones itself, but the config already requires plugins that don't exist yet, so
the first run errors until you manually `:PackerSync`. Doing it here means your
first interactive launch is clean.

It checks before it acts, because the work is expensive and almost always
unnecessary. If nvim starts without errors and every `ensure_installed` parser is
built, the whole step is skipped. A missing plugin surfaces as a startup error,
since the config `require`s them.

One consequence: adding a plugin that nothing `require`s at startup won't be
detected here. `plugins_base.lua` already has an autocmd that runs `PackerSync`
when you save it, so that case is covered in the editor.

### How the wiring works

Nothing is ever copied out of this repo. Each dotfile gets a small block that
points back here:

```
# >>> dev-setup >>>
export BASE_PATH="$HOME"
source "<REPO_DIR>/zshrc"
# <<< dev-setup <<<
```

So `git pull` is the whole update procedure for anything in `bashrc`, `zshrc`,
`gitconfig`, or `nvim/` — the next shell or nvim launch reads the new file. No
reinstall needed.

Re-run `./install.sh` only when a pull changes *dependencies* rather than config:
a new `Brewfile` entry, a new plugin in `plugins_base.lua`, or a new treesitter
parser in `ensure_installed`.

Idempotency keys off those sentinel comments, not off the text between them.
Three consequences:

- Re-running any number of times never adds a second `source` line, regardless
  of how the path happens to be quoted.
- If the repo **moves**, the existing block is rewritten in place rather than a
  second one appended, so you never source a path that no longer exists.
- Anything you write outside the block is left alone.

If a dotfile already sources this repo from *outside* a sentinel block — e.g. you
wired it by hand from the reference section below — `install.sh` refuses to touch
that file and says so, rather than silently double-sourcing. Delete your manual
line and re-run.

---

## Choros workspaces

[Choros](https://github.com/Harrichael/Choros) manages short-lived multi-repo
work environments — one choros per task-sized unit of work. A directory becomes
a *choros root* when it contains `.choros-config/registry/`; repos in that
registry are what a new choros can clone.

`./install.sh` sets this up interactively. Every prompt is skipped when stdin is
not a terminal, so automated runs never hang.

```
==> choros workspaces
    Set up a choros workspace directory? [Y/n]
    Workspace directory: ~/psrc
    created: ~/psrc/.choros-config/registry
    direct clone found: ~/psrc/some-repo
      re-clone git@github.com:you/some-repo.git into the registry? [Y/n]
    git user.name  for ~/psrc: Your Name
    git user.email for ~/psrc: personal@example.com
    Set up another workspace? [y/N] y
    ...
```

**Direct clones.** A git repo already sitting at the top of a workspace root
predates choros and isn't managed by it. Setup flags each one and offers to
**re-clone it from its `origin` default branch** into the registry.

A registry entry is a fresh clone, never a copy or a symlink of a working
directory — choros re-clones *from* the registry, so the registry copy has to be
clean. Your existing clone is left exactly where it is, with all its uncommitted
state, for you to clean up whenever you like. A repo with no `origin` remote is
reported and skipped.

**Per-workspace git identity.** Each root owns its identity, so personal and
work repos can't cross-contaminate:

```
~/psrc/.choros-config/gitconfig     [user] name/email  (personal)
~/xsrc/.choros-config/gitconfig     [user] name/email  (work)
```

`~/.gitconfig` gets one `includeIf "gitdir:<root>/"` block per workspace,
pointing at those files. The identity lives *with the workspace*, so it never
lands in this public repo, and it applies to every repo beneath the root —
including fresh choros clones. Re-running setup pre-fills the current values, so
pressing enter keeps them.

A repo outside every workspace root falls back to your global identity, which is
why `install.sh` still nags about setting one.

**Relocating this repo.** Setup can move dev-setup into a workspace registry
(e.g. `~/psrc/.choros-config/registry/dev-setup`) so a choros can clone it like
any other repo. This repo is *moved* rather than re-cloned, since it holds your
live config and any work in progress.

The move runs **before** the dotfile wiring, so all three blocks are written once
with the final path. There is no second pass, and no window where a dotfile
points at a directory that no longer exists. Re-running afterwards reports
`already at` and changes nothing.

---

## Tools

`install.sh` clones and installs a set of tools into a workspace registry, so a
choros can also clone them like any other repo. All are repos you own and
update; each is a plain clone, not a submodule — they're tool dependencies you
also develop, and pinning them to a dev-setup commit would only add friction.

| Tool | Kind | Installed as |
| --- | --- | --- |
| [Choros](https://github.com/Harrichael/Choros) | Rust | `cargo install --path` → `~/.cargo/bin/choros` |
| [LatticeQL](https://github.com/Harrichael/LatticeQL) | Rust | `cargo install --path` → `~/.cargo/bin/latticeql` |
| [Gnomon](https://github.com/Harrichael/Gnomon) | Python | delegates to the repo's own `install.sh` |

`~/.cargo/bin` is already on `PATH` in both shell configs, which is why it's
preferred over the `~/.local/bin` that some of these installers default to. If
`cargo` is missing, setup offers to install rustup — which also lands in
`~/.cargo/bin`.

**Rust builds are stamped.** `cargo install` re-links on every invocation, and
these packages don't bump their version between commits, so cargo can neither
skip reliably nor notice that the code changed. The commit each tool was built
from is recorded under `${XDG_STATE_HOME:-~/.local/state}/dev-setup/`.

A rebuild is skipped only when the commit matches **and** cargo's own record in
`~/.cargo/.crates.toml` says the installed binary was built from this registry
copy. Otherwise a binary installed from a stray clone elsewhere would satisfy a
commit-only check and never converge on the registry; it now reports
`re-installing: current binary was not built from this registry copy`. A re-run
with nothing to do prints `already built at <sha>`. A cold build takes minutes.

**Unattended installs.** The tools step normally prompts. Set
`DEV_SETUP_TOOLS_REGISTRY` to a workspace root (or a registry path) to run it
with no prompts:

```
DEV_SETUP_TOOLS_REGISTRY=~/psrc ./install.sh
```

**Gnomon is the exception to wiring by reference.** Its installer deliberately
deploys a *copy* to `~/.claude/gnomon.py` and pins `statusLine` at that path, so
that something executing on every keystroke can't be broken by a half-saved file
in a checkout. Wiring it by reference instead would be silently reverted the next
time its installer ran. So dev-setup delegates to it, and because that happens on
every pass, a pull here is also a redeploy — `git pull` alone is *not* enough for
Gnomon, unlike everything else in this repo.

That installer merges into `~/.claude/settings.json` rather than overwriting it,
and is all-or-nothing: on malformed JSON it deploys nothing, changes nothing, and
exits non-zero. dev-setup surfaces that failure rather than swallowing it.

`bashrc` and `zshrc` already contain the `eval "$(choros shell-init)"` hook,
guarded so a machine without choros starts cleanly.

---

## Shell notes

`golink <name>` registers the current directory as a link under
`$BASE_PATH/.go`; `go <name>` jumps to it. Bare `go` lists the links.

`go` resolves its target in a subshell and then does a single `cd`, so `cd -`
returns to wherever you were before the jump. (An earlier version ran two `cd`s,
which left `OLDPWD` pointing at the `.go` directory.)

`go` shadows the Go compiler — reach the real toolchain as `golang`.

`ssg <search> <replace>` recursively rewrites files below the current directory,
skipping every `.git`. It uses `perl -pi` rather than `sed -i`, whose `-i` flag
takes incompatible arguments on BSD and GNU.

The `dir` and `vdir` aliases in `bashrc` are GNU coreutils only, so `zshrc` omits
them. `zshrc` also implements `alert` with `osascript` instead of `notify-send`.

---

## Dotfile Addendums

These are what `install.sh` writes. Listed for reference, or if you'd rather wire
things up by hand. Replace `<REPO_DIR>` with the path you cloned to.

`~/.zshrc` (macOS)
```
export BASE_PATH="$HOME"
source "<REPO_DIR>/zshrc"
```

`~/.bashrc` (Linux)
```
export BASE_PATH="$HOME"
source "<REPO_DIR>/bashrc"
```

`~/.config/nvim/init.lua`
```
package.path = ";<REPO_DIR>/nvim/?.lua;" .. package.path
vim.opt.runtimepath:append("<REPO_DIR>/nvim")
require("plugins_base")
require("init_base")
```

`~/.gitconfig`
```
[include]
        path = <REPO_DIR>/gitconfig
```
