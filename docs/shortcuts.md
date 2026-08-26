# Keyboard reference

macOS. Generated from `aerospace/aerospace.toml`, `kitty/`, `karabiner/` and
`zshrc` — if those change, change this too.

**The scheme in one line:** `cmd` = spaces and windows · `cmd+alt` = layout ·
`ctrl` = inside the app.

> On this machine **Command and Globe are swapped**, so `cmd` is the physical
> bottom-left key. Anything below written as `cmd` is that key.

---

## cmd — spaces and windows (AeroSpace)

| Key | Does |
| --- | --- |
| `cmd 1`…`cmd 5` | Go to workspace 1–5 |
| `cmd 0` | Go to workspace **W** (Work) |
| `cmd shift 1`…`5` | Send window to workspace 1–5 |
| `cmd shift 0` | Send window to workspace W |
| `cmd tab` | Next window **in this space** (cycles, never leaves) |
| `cmd alt tab` | Previous window in this space |
| `cmd shift tab` | Back to the **previous workspace** |

## cmd+alt — layout and movement (AeroSpace)

| Key | Does |
| --- | --- |
| `cmd alt ← ↓ ↑ →` | Move focus between windows |
| `cmd alt shift ← ↓ ↑ →` | Move the window itself |
| `cmd alt f` | Fullscreen (fill the space) |
| `cmd alt /` | Rotate split — horizontal ↔ vertical |
| `cmd alt ,` | Accordion (stacked) layout |
| `cmd alt space` | Float / unfloat **this window** |
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

**kitty**

| Key | Does |
| --- | --- |
| `ctrl 1`…`ctrl 8` | Go to tab 1–8 |
| `ctrl 9` | **Last** tab |
| `ctrl tab` / `ctrl shift tab` | Next / previous tab |
| `ctrl shift w` | Close tab |
| `ctrl shift p` | Fuzzy tab picker |
| `cmd t` / `cmd w` | New / close tab (kitty defaults) |
| `cmd d` / `cmd shift d` | Split right / down |
| `cmd alt ← ↓ ↑ →` | Move between splits |
| `ctrl cmd ,` | Reload kitty config |

**Chrome** — cannot be rebound; these are its own.

| Key | Does |
| --- | --- |
| `ctrl tab` / `ctrl shift tab` | Next / previous tab |
| `cmd ←` / `cmd →` | Back / forward |
| `cmd 1`…`9` | ⚠️ **Taken by AeroSpace** — no tab-by-number in Chrome |

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

## Deliberately not bound

| Key | Left alone because |
| --- | --- |
| `cmd w` | Close Window, in every app |
| `cmd f` | Find, in every app |
| `cmd h` `cmd j` `cmd k` `cmd l` | Hide, Downloads, Search, **Address bar** |
| `cmd ←` `cmd →` | Back / Forward in browsers |
| `ctrl [` | It *is* Escape |
| `ctrl w` `ctrl t` | Delete-word and transpose-char in the shell |

## Required macOS setting

**System Settings → Keyboard → Keyboard Shortcuts → Mission Control** — disable
*Move left/right a space*. macOS binds those to `ctrl+arrows` and will swallow
word movement before any app sees it. Safe: AeroSpace does not use macOS Spaces.

## Known gaps

- **No workspace-scoped MRU.** `cmd tab` cycles in tree order. With two windows
  that is a toggle; with three or more it is a cycle, not "last used".
- **No tab-by-number in Chrome.** `cmd 1`…`9` belongs to AeroSpace, and Chrome
  has no rebinding of any kind. Use `ctrl tab`.
- **Terminal.app transparency** is a Terminal profile setting, set by hand.
