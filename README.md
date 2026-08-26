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

Clone it wherever you like. `install.sh` pulls its own pristine checkout to
`~/.local/share/dev-setup/self` and wires the dotfiles *there*, so this clone
carries no special status — keep it to develop the config in, or delete it. See
[How the wiring works](#how-the-wiring-works).

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
sudo apt install neovim git tree ripgrep kitty fonts-jetbrains-mono

# git-delta: https://github.com/dandavison/delta/releases
# fnm:
curl -fsSL https://fnm.vercel.app/install | bash
```

If `nvim` is too old, see [troubleshooting.md](troubleshooting.md) — some distros
don't package a current build.

`fonts-jetbrains-mono` is the plain font, **not** the Nerd Font patch that
`kitty/kitty.conf` asks for by the family name `JetBrainsMono NFM`. Either grab
the patched build from
[nerd-fonts releases](https://github.com/ryanoasis/nerd-fonts/releases) into
`~/.local/share/fonts` and run `fc-cache -f`, or change `font_family` to
`JetBrains Mono` and lose the glyphs.

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

**Optional — root shell.** Add to `/root/.bashrc`, pointing at the *wired*
checkout (the path `install.sh` prints, not the clone you ran it from):

```
source "<SELF_DIR>/bashrc"
```

**Optional — `rc.local`.** Linux-only and unused on macOS. `chmod +x
/etc/rc.local`, then:

```
#! /bin/sh

source "<SELF_DIR>/rc.local"
```

---

## What install.sh does

Idempotent — re-running reports what's already in place and changes nothing. A
re-run with everything installed takes about a second.

| Step | Action |
| --- | --- |
| Packages | macOS: `brew bundle`. Linux: prints the list to install yourself. |
| Choros workspaces | Interactive, defaults to yes. Creates choros roots, re-clones pre-existing repos into the registry, and sets a per-workspace git identity. |
| Tools | Defaults to yes. Clones/updates Choros, LatticeQL, and Gnomon into `~/.local/share/dev-setup/tools/` and installs each. Installs Rust via rustup first if needed. See [Tools](#tools). |
| aerospace | macOS only. Symlinks `~/.config/aerospace/aerospace.toml` to this repo's copy. |
| karabiner | macOS only. Copies `karabiner/karabiner.json` if absent; never overwrites a divergent one. |
| kitty | Wires `~/.config/kitty/kitty.conf` to include this repo's shared + per-OS kitty config. |
| Claude global | Wires `~/.claude/CLAUDE.md` to import `claude/CLAUDE.md` from this repo. |
| dev-setup source | Pulls the pristine checkout the dotfiles point at, into `~/.local/share/dev-setup/self`. Runs before wiring so paths are recorded once. |
| Development clones | Interactive, optional. Clones dev-setup and the tool repos into a workspace registry so a choros can hack on them. Nothing is installed from these. |
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
points at a checkout by reference:

```
# >>> dev-setup >>>
export BASE_PATH="$HOME"
source "<SELF_DIR>/zshrc"
# <<< dev-setup <<<
```

**Which checkout matters.** That path is *not* the clone you ran `install.sh`
from. It's a pristine one at
`${XDG_DATA_HOME:-~/.local/share}/dev-setup/self` that dev-setup pulls and never
develops in.

The reason is that "by reference" cuts both ways. If the referenced checkout were
the clone you develop in, then a half-saved `zshrc` edit, or a WIP branch you
forgot you were on, would change every new shell the moment it happened — and
`gitconfig` and nvim with it. That's the same hazard Gnomon avoids by deploying a
copy rather than a symlink; it just happened to be less visible here.

So the update procedure is **`./install.sh --update`**, which fast-forwards that
checkout and re-wires in one pass. A `git pull` in your own clone changes nothing
that's live. That's the point: your working tree is yours to break.

**`install.sh` on its own does not pull.** Installing and updating are separate
jobs, and fusing them would mean every install silently became "install whatever
is newest" — leaving no way to install a pin, roll back, or test a branch. So a
bare run installs whatever the checkouts are at, and only clones what is missing
(a checkout that doesn't exist yet has no version to preserve).

To install a specific version, check it out and install without `--update`:

```
git -C ~/.local/share/dev-setup/self checkout v1.2
~/.local/share/dev-setup/self/install.sh
```

That needs no extra flag, which is why there isn't one. A pinned checkout is
detached, and `--update` deliberately refuses to move it — it reports
`pinned at <sha>, not updating` and tells you how to unpin. Same for the tools:
check out a ref in `~/.local/share/dev-setup/tools/<Name>` and install.

Unknown arguments are an error rather than being ignored, so a typo like
`--dry` fails instead of quietly performing a real install.

While you're actually iterating on the config, wire your clone directly:

```
DEV_SETUP_SELF_DIR=$PWD ./install.sh
```

The run says so out loud when you do. And if your clone is dirty or has unpushed
commits, `install.sh` names them and warns that they are **not** what got wired —
silently going live with the older tree would be the worst outcome.

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

**Development clones.** Setup can clone dev-setup *and* the tool repos into a
workspace registry, so a new choros can check them out and you have somewhere to
develop them. This is a separate, optional step, and nothing is ever installed
from those clones — installs come from `~/.local/share/dev-setup/tools`.

dev-setup is **not** moved into a registry, and never was a good candidate for
it: the dotfiles point at this checkout by reference, so its authoritative
location is wherever you cloned it. An earlier version did move it, which
produced exactly the hazard registries invite — a second, identical-looking
checkout that drifted commits behind and got read as the live one. If you have
one of those lying around, it is inert; delete it or `git pull` it.

The move runs **before** the dotfile wiring, so all three blocks are written once
with the final path. There is no second pass, and no window where a dotfile
points at a directory that no longer exists. Re-running afterwards reports
`already at` and changes nothing.

---

## Tools

`install.sh` clones and installs a set of tools into
**`${XDG_DATA_HOME:-~/.local/share}/dev-setup/tools/`**, which dev-setup owns. That directory is the authoritative copy of each tool: it
is never developed in, only pulled and re-installed from, so every installed
binary has a provenance you can check. All are repos you own and update; each is
a plain clone, not a submodule — they're tool dependencies you also develop, and
pinning them to a dev-setup commit would only add friction.

**Why not a choros registry?** An earlier version installed from
`<root>/.choros-config/registry/`, which was a mistake. A registry holds *clone
sources*; its layout belongs to choros, and a deploy path reaching into another
tool's data structure breaks when that tool evolves — bare registry entries, for
one, have no working tree at all, and `cargo install --path` needs one. It also
left a second, identical-looking checkout of every tool on disk, which is its own
hazard. If you still want registry-hosted installs, see the override below; the
tools step names any other checkout it finds so it can't quietly mislead you.

There is no macOS/Linux split here on purpose. `~/Library/Application Support` is
the macOS convention for *GUI* apps; CLI tools there use XDG or dotdirs, and
macOS honours `$XDG_DATA_HOME` when it's set. The variable is the portability
seam, not a `uname` branch — and it matches the build stamps, which already live
under `$XDG_STATE_HOME`.

| Tool | Kind | Installed as |
| --- | --- | --- |
| [Choros](https://github.com/Harrichael/Choros) | Rust | `cargo install --path` → `~/.cargo/bin/choros` |
| [LatticeQL](https://github.com/Harrichael/LatticeQL) | Rust | `cargo install --path` → `~/.cargo/bin/lql` |
| [Gnomon](https://github.com/Harrichael/Gnomon) | Python | delegates to the repo's own `install.sh` |

`~/.cargo/bin` is already on `PATH` in both shell configs, which is why it's
preferred over the `~/.local/bin` that some of these installers default to. If
`cargo` is missing, setup offers to install rustup — which also lands in
`~/.cargo/bin`.

**Every install is stamped, but only Rust builds are skipped.** `cargo install` re-links on every invocation, and
these packages don't bump their version between commits, so cargo can neither
skip reliably nor notice that the code changed. The commit each tool was built
from is recorded under `${XDG_STATE_HOME:-~/.local/state}/dev-setup/`.

A rebuild is skipped only when the commit matches **and** cargo's own record in
`~/.cargo/.crates.toml` says the installed binary was built from this checkout.
Otherwise a binary installed from a stray clone elsewhere would satisfy a
commit-only check and never converge; it reports `re-installing: current binary
was not built from this checkout`. A re-run with nothing to do prints
`already built at <sha>`. A cold build takes minutes.

Script tools (Gnomon) are stamped the same way, but the stamp is only a
*record* — never a skip condition. Re-running their installer every pass is how
they update, and in Gnomon's case it's also the smoke gate that stops a broken
copy going live, so dev-setup always runs it again and just reports movement:
`deployed 2d5a558 -> 987a119`. A failed installer is not stamped, so the record
can't claim a deploy that didn't happen. Whether the *deployed artifact* came
from this checkout is the installer's business, not dev-setup's — Gnomon answers
it in `~/.claude/gnomon.provenance`.

**One report for everything.** Every install writes
`${XDG_STATE_HOME:-~/.local/state}/dev-setup/provenance`, listing dev-setup
itself and each tool with its source checkout, commit and dirty flag:

```
dev-setup(wired)     /Users/you/.local/share/dev-setup/self        f738a01  clean
dev-setup(ran from)  /Users/you/psrc/dev-setup                     f738a01  clean
Choros     /Users/you/.local/share/dev-setup/tools/Choros     1fbb763  clean
LatticeQL  /Users/you/.local/share/dev-setup/tools/LatticeQL  ce1ba63  clean
Gnomon     /Users/you/.local/share/dev-setup/tools/Gnomon     987a119  clean
```

It exists because the underlying records live in three different places — cargo
in `~/.cargo/.crates.toml`, script tools in whatever their own installer writes,
and dev-setup only implicitly, in the paths embedded in the dotfiles it wired.
That answers "which checkout is live?" only if you already know where to look for
each one. This is a **report, not state**: nothing reads it back and deleting it
breaks nothing. It's tab-separated so it stays greppable.

`dev-setup(wired)` is the row that matters — it's what the dotfiles read.
`dev-setup(ran from)` appears only when you invoked `install.sh` from a different
clone, which is the normal case. If any other checkout of dev-setup exists, the
report names it and says nothing points at it.

**Overriding the location.** Two environment variables, both optional:

| Variable | Effect |
| --- | --- |
| `DEV_SETUP_TOOLS_DIR` | Install from this directory instead of the default. |
| `DEV_SETUP_TOOLS_REGISTRY` | Go back to registry-hosted installs. Takes a workspace root or a registry path. |

```
DEV_SETUP_TOOLS_DIR=~/opt/dev-tools ./install.sh
DEV_SETUP_TOOLS_REGISTRY=~/psrc ./install.sh
```

With no tty, prompts take their defaults, so a plain `./install.sh </dev/null`
installs the tools into the default location unattended.

**Gnomon is the exception to wiring by reference.** Its installer deliberately
deploys a *copy* to `~/.claude/gnomon.py` and pins `statusLine` at that path.
The property that buys is a **smoke gate**: every byte that reaches
`~/.claude/gnomon.py` rendered a sample payload first, so something executing on
every keystroke is never live until it has run once. Its installer also writes
`~/.claude/gnomon.provenance` recording which checkout and commit deployed it. Wiring it by reference instead would be silently reverted the next
time its installer ran. So dev-setup delegates to it, and because that happens on
every pass, a pull here is also a redeploy — `git pull` alone is *not* enough for
Gnomon, unlike everything else in this repo.

That installer merges into `~/.claude/settings.json` rather than overwriting it,
and is all-or-nothing: on malformed JSON it deploys nothing, changes nothing, and
exits non-zero. dev-setup surfaces that failure rather than swallowing it.

`bashrc` and `zshrc` already contain the `eval "$(choros shell-init)"` hook,
guarded so a machine without choros starts cleanly.

---

## Terminal

`install.sh` wires `~/.config/kitty/kitty.conf` to `include` two files from this
repo: `kitty/kitty.conf` for font, colors and the tab bar, and
`kitty/macos.conf` or `kitty/linux.conf` for window chrome and tab keys.

**Why kitty and not Ghostty or Alacritty.** Both of those use native macOS
`NSWindow` tabs, which means each tab genuinely *is* a window. A tiling window
manager therefore tiles every tab as its own node and re-tiles the workspace on
every tab switch. Measured with three tabs open:

| Terminal | Windows AeroSpace sees | Native-tab selectors in the binary |
| --- | --- | --- |
| Ghostty | 3 | 4 |
| Alacritty | — | 8 |
| kitty | 1 | 0 |

kitty draws its own tab bar inside one window, so tab switching is invisible to
the window manager. There is no Ghostty setting that changes this — its
non-native tab options are Linux-only.

**The keybindings can't be shared across platforms.** `cmd` doesn't exist on
Linux, and `ctrl+shift+1..9` is already `first_window`/`second_window`/… there
for splits within a tab. So tab jumping is `cmd+1..9` on macOS and
`ctrl+alt+1..9` on Linux.

Note what that costs on macOS: kitty binds `cmd+1..9` by default to
`first_window`…`ninth_window`, which jumps between *splits* inside a tab.
Repointing them at tabs leaves split-by-number unbound — splits are still
reachable with `cmd+opt+arrows`. Linux keeps its split bindings, since
`ctrl+alt` was free. `cmd+9` / `ctrl+alt+9` go to the *last* tab rather
than the ninth, matching Ghostty. `cmd+shift+p` (`ctrl+alt+p`) opens a fuzzy tab
picker.

**Appearance notes.** The font is JetBrains Mono Nerd Font — specifically the
`NFM` (cell-width) variant, so icons can't overflow a cell and shove the line.
Colors are One Dark; Ghostty's own defaults pair One Dark's background
(`#282c34`) with a Tomorrow Night ANSI palette, which is a mismatch worth not
reproducing. `ctrl+cmd+,` reloads the config in place, `cmd+,` edits it, and
`opt+cmd+,` dumps what actually got resolved.

---

## Keyboard scheme (macOS)

`cmd` = spaces and windows · `cmd+alt` = layout · `ctrl` = inside the app.
Full printable reference: **[docs/shortcuts.md](docs/shortcuts.md)**.

Four layers cooperate, and the order they see a keystroke in matters:

| Layer | File | Wiring |
| --- | --- | --- |
| Karabiner | `karabiner/karabiner.json` | **copy** — its UI rewrites the file |
| AeroSpace | `aerospace/aerospace.toml` | **symlink** — TOML has no include |
| kitty | `kitty/*.conf` | `include`, by reference |
| shell | `zshrc` / `bashrc` | `source`, by reference |

Karabiner sits lowest, then global hotkeys (AeroSpace), then the app. Three
consequences worth knowing:

- **An AeroSpace binding always wins over the focused app.** That's why
  `cmd+shift+i` opens a new Chrome window instead of Chrome intercepting it.
- **Chrome cannot have tab-by-number.** Karabiner would have to emit `cmd+N`,
  and AeroSpace grabs `cmd+N` first. Chrome has no rebinding mechanism at all,
  so `ctrl+Tab` is the answer there.
- **Karabiner excludes terminals** via `frontmost_application_unless`, so
  `ctrl+c` stays SIGINT and `ctrl+a` stays beginning-of-line in a shell.

**`cmd+tab` is not MRU.** AeroSpace's `focus-back-and-forth` tracks the last
focused window *globally* and will jump you to another workspace, which is the
opposite of contained. So the binding is
`focus dfs-next --boundaries workspace --boundaries-action wrap-around-the-workspace`
— positional cycling that never leaves the space. With two windows it is a
toggle; with three or more it is a cycle. AeroSpace has no workspace-scoped MRU.
(`--boundaries` and `--wrap-around` are mutually exclusive; the containment
needs the `--boundaries-action` form.)

**One manual step:** disable *Move left/right a space* in System Settings →
Keyboard → Keyboard Shortcuts → Mission Control. macOS binds those to
`ctrl+arrows` and swallows word movement. `install.sh` checks and reminds.

---

## Claude Code global instructions

Claude Code reads `~/.claude/CLAUDE.md` as instructions for every session on the
machine, whatever project you're in. `install.sh` wires it by reference like the
other dotfiles, using CLAUDE.md's own `@import` syntax, so the content is
version-controlled here and a pull updates it:

```
<!-- >>> dev-setup >>> -->
@~/.local/share/dev-setup/self/claude/CLAUDE.md
<!-- <<< dev-setup <<< -->
```

**Write your instructions in `claude/CLAUDE.md` in this repo.** Not in
`~/.claude/CLAUDE.md` — that file holds only the import, and `install.sh` rewrites
the block between the sentinels. Anything you add *outside* the sentinels there is
left alone, but it won't be version-controlled.

It's at `claude/CLAUDE.md` rather than the repo root deliberately. A root
`CLAUDE.md` would also be read as dev-setup's own *project* instructions, so
global rules would apply twice while working here, and anything repo-specific
would leak into every other project.

The sentinels are `<!-- ... -->` because markdown has no line comment — an
unterminated `<!--` would swallow the rest of the file.

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
things up by hand.

Replace `<SELF_DIR>` with the checkout you want these to read. `install.sh` uses
a pristine one at `~/.local/share/dev-setup/self`; wiring by hand you can point
at any clone, but be aware that whatever you name here is live — an unsaved edit
or a WIP branch in it takes effect on the next shell.

`~/.zshrc` (macOS)
```
export BASE_PATH="$HOME"
source "<SELF_DIR>/zshrc"
```

`~/.bashrc` (Linux)
```
export BASE_PATH="$HOME"
source "<SELF_DIR>/bashrc"
```

`~/.config/nvim/init.lua`
```
package.path = ";<SELF_DIR>/nvim/?.lua;" .. package.path
vim.opt.runtimepath:append("<SELF_DIR>/nvim")
require("plugins_base")
require("init_base")
```

`~/.gitconfig`
```
[include]
        path = <SELF_DIR>/gitconfig
```

`~/.claude/CLAUDE.md`
```
<!-- >>> dev-setup >>> -->
@<SELF_DIR>/claude/CLAUDE.md
<!-- <<< dev-setup <<< -->
```
