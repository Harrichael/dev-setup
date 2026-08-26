# Keyboard reference

macOS. Generated from `aerospace/aerospace.toml`, `kitty/`, `karabiner/` and
`zshrc` — if those change, change this too.

**The scheme in one line:** `cmd` = spaces and windows · `cmd+alt` = layout ·
`ctrl` = inside the app.

> On this machine **Command and Globe are swapped**, so `cmd` is the physical
> bottom-left key. Anything below written as `cmd` is that key.

---

## Spaces and windows (AeroSpace)

| Key | Does |
| --- | --- |
| `cmd fn 1`…`5` | Go to workspace 1–5 |
| `cmd fn w` | Go to workspace **W** (Work) |
| `cmd fn tab` | Back to the **previous workspace** |
| `cmd alt 1`…`5` | Send window to workspace 1–5 |
| `cmd alt w` | Send window to workspace W |
| `alt tab` | Next window **in this space** (cycles, never leaves) |
| `alt shift tab` | Previous window in this space |
| `alt backtick` | Back to the previous workspace |

**Two paths on purpose.** AeroSpace cannot bind `fn`/Globe at all — it only
understands `cmd`, `alt`, `ctrl`, `shift`. So the real bindings are `cmd+ctrl+N`,
`cmd+ctrl+w` and `alt+backtick`, and Karabiner aliases `cmd+fn+…` on top of
them. If Karabiner is off, use the native chords below and nothing is lost.

| Native fallback | Same as |
| --- | --- |
| `cmd ctrl 1`…`5` | `cmd fn 1`…`5` |
| `cmd ctrl w` | `cmd fn w` |
| `alt backtick` | `cmd fn tab` |
| `F18` / `F19` / `F20` | cycle next / cycle prev / last workspace |

`cmd 1`…`cmd 9` is left free on purpose, so **browser tab-by-number works**.
`cmd+tab` is unusable for window management: macOS consumes it above global
hotkeys, so AeroSpace never sees it.

## cmd+alt — layout and movement (AeroSpace)

| Key | Does |
| --- | --- |
| `cmd alt ← ↓ ↑ →` | Move focus between windows |
| `cmd alt shift ← ↓ ↑ →` | Move the window itself |
| `cmd alt f` | Fullscreen (fill the space) |
| `cmd alt /` | Rotate split — horizontal ↔ vertical |
| `cmd alt ,` | Accordion (stacked) layout |
| `alt space` | Float / unfloat **this window** |
| `cmd alt e` | Suspend tiling — floats **everything** |
| `cmd alt b` | Balance sizes |
| `cmd alt r` | Reset a mangled layout |
| `cmd alt -` / `cmd alt =` | Shrink / grow |
| `cmd alt [` / `cmd alt ]` | Focus previous / next monitor |
| `cmd alt shift [` / `]` | Send window to previous / next monitor |
| `cmd alt ;` | Service mode — then `esc` reload, `r` reset, `f` float, `backspace` close others |

## cmd+shift — launchers (AeroSpace)

Always a **new window**, never "go to the existing one".

| Key | Opens |
| --- | --- |
| `cmd shift i` | Google Chrome |
| `cmd shift c` | kitty |
| `cmd shift t` | Terminal.app (floats automatically) |

## ctrl — inside the app

**kitty** — tabs are on `alt`, because every `ctrl+digit` except 1 and 9 sends a
real control code (`ctrl+3` is ESC, `ctrl+7` is undo).

| Key | Does |
| --- | --- |
| `alt 1`…`alt 8` | Go to tab 1–8 |
| `alt 9` | Last tab |
| `alt w` | Close tab |
| `alt p` | Fuzzy tab picker |
| `ctrl tab` / `ctrl shift tab` | Next / previous tab |
| `cmd t` | New tab |
| `cmd w` | Close tab |
| `cmd enter` | New **split** |
| `ctrl shift [` / `ctrl shift ]` | Previous / next split |
| `cmd 1`…`cmd 9` | Go to split 1–9 |
| `cmd shift d` | ⚠️ Close **split** (not "split down") |
| `cmd shift w` | Close window (all tabs) |
| `ctrl cmd ,` | Reload kitty config |

**Chrome** — cannot be rebound; these are its own.

| Key | Does |
| --- | --- |
| `ctrl tab` / `ctrl shift tab` | Next / previous tab |
| `cmd ←` / `cmd →` | Back / forward |
| `cmd 1`…`cmd 9` | Go to tab N / last tab — AeroSpace leaves these free |
| `ctrl 1`…`ctrl 9` | Same, via Karabiner (feels Linux-like) |

## Text editing — Linux-style (Karabiner)

Everywhere **except** terminals, so `ctrl+c` stays SIGINT in a shell.

| Key | Does |
| --- | --- |
| `ctrl ←` / `ctrl →` | Move by word |
| `ctrl shift ←` / `→` | **Select** by word |
| `ctrl backspace` | Delete previous word |
| `Home` / `End` | Line start / end |
| `ctrl Home` / `ctrl End` | Document start / end |
| `ctrl a` | Select all |
| `ctrl c` / `ctrl v` / `ctrl x` | Copy / paste / cut |
| `ctrl z` / `ctrl shift z` | Undo / redo |
| `ctrl f` | Find |
| `ctrl s` | Save |
| `ctrl shift w` | Close tab |

## Shell line editing (zsh / bash)

The terminal keeps POSIX meanings — `ctrl+c` interrupts, `ctrl+a` goes to line
start. Word movement matches the GUI anyway:

| Key | Does |
| --- | --- |
| `ctrl ←` / `ctrl →` | Move by word |
| `Home` / `End` | Line start / end |
| `ctrl backspace` | Delete previous word |
| `ctrl delete` | Delete next word |
| `ctrl a` / `ctrl e` | Line start / end (POSIX) |
| `ctrl w` | Delete word — **why tabs don't use `ctrl+w`** |

---

## Costs of this scheme

| Lost | To |
| --- | --- |
| Chrome **Reopen Closed Tab** (`cmd shift t`) | Terminal.app launcher |
| Chrome DevTools **element picker** (`cmd shift c`) | kitty launcher |
| `Home`/`End` in browsers | Excluded on purpose, so Home still scrolls rather than navigating Back |
| kitty split-close on `cmd shift d` | Nothing — but it is *not* "split down"; it closes |
| Word's **Apply Heading 1/2/3** (`cmd alt 1/2/3`) | Send-window-to-workspace |
| `alt tab` inside remote-desktop / VM sessions | Captured globally; AeroSpace has no per-app exceptions |
| bare `ctrl h` (was delete-char) | `ctrl backspace` — they are the same byte, 0x08 |

`cmd alt i` and `cmd alt j` still open DevTools.

## Deliberately not bound

| Key | Left alone because |
| --- | --- |
| `cmd w` | Close Window, in every app |
| `cmd 1`…`cmd 9` | So browser tab-by-number keeps working |
| `cmd f` | Find, in every app |
| `cmd h` `cmd j` `cmd k` `cmd l` | Hide, Downloads, Search, **Address bar** |
| `cmd ←` `cmd →` | Back / Forward in browsers |
| `ctrl [` | It *is* Escape |
| `ctrl w` `ctrl t` | Delete-word and transpose-char in the shell |

## Required setup

**Launch Karabiner-Elements once** and approve its system extension and Input
Monitoring. It registers itself at login after that. Until then the `ctrl` text
bindings and every `cmd+Globe` chord do nothing — and Karabiner also owns the
Command/Globe swap, so it is not optional. `install.sh` checks and reminds.

## Required macOS setting

**System Settings → Keyboard → Keyboard Shortcuts → Mission Control** — disable
*Move left/right a space*. macOS binds those to `ctrl+arrows` and will swallow
word movement before any app sees it. Safe: AeroSpace does not use macOS Spaces.

## Known gaps

- **No workspace-scoped MRU.** `alt tab` cycles in tree order. With two windows
  that is a toggle; with three or more it is a cycle, not "last used".
- **`cmd+fn+…` depends on Karabiner**, because AeroSpace cannot bind `fn`. The
  `cmd+ctrl+…` and `alt+…` equivalents are native and always work, which is why
  both are bound.
- **`cmd+tab` is not used at all.** macOS consumes it in the WindowServer, above
  global hotkeys, so AeroSpace never receives it — the App Switcher appears and
  jumps you across workspaces regardless of what is bound.
- **Karabiner must own the Command/Globe swap.** Karabiner grabs the keyboard
  below the layer where System Settings → Modifier Keys applies, so that swap
  stops working the moment Karabiner runs. It is therefore set in
  `karabiner/karabiner.json` as a `simple_modifications` pair instead.
- **Terminal exclusions are by bundle ID.** 17 are listed, covering the common
  terminals plus editors with embedded ones (VS Code, Cursor, JetBrains, Zed,
  Emacs, MacVim). Anything not on the list gets `ctrl+c` as copy inside its
  terminal, and in-browser terminals can never be excluded by bundle ID at all.
- **The `cmd+fn` aliases are unverified.** Command and Globe are swapped in
  System Settings, and which of the two Karabiner observes has not been tested.
  If they misbehave, moving the swap into Karabiner's `simple_modifications`
  gives one source of truth.
- **Terminal.app transparency** is a Terminal profile setting, set by hand.
