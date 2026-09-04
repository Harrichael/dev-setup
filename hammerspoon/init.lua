-- Hammerspoon config for dev-setup.
--
-- Wired by reference: ~/.hammerspoon/init.lua dofile()s this, so a pull
-- updates it. Reload with the Hammerspoon menu, or: hs -c 'hs.reload()'
--
-- NOTE: after granting Hammerspoon a new macOS permission you must QUIT AND
-- RELAUNCH it, not "Reload Config". AXIsProcessTrusted() caches its answer for
-- the life of the process, so a reload keeps reporting the stale value.

require("hs.ipc")
hs.ipc.cliInstall()

--------------------------------------------------------------------------------
-- Linux-style ctrl bindings for GUI apps
--------------------------------------------------------------------------------
-- macOS puts editing on cmd and word-movement on alt. Muscle memory from Linux
-- puts both on ctrl. This rewrites the modifier so ctrl behaves the Linux way
-- everywhere EXCEPT where ctrl already means something load-bearing.
--
-- The exclusion list is the whole point. In a shell, ctrl+c is SIGINT, ctrl+a
-- is beginning-of-line and ctrl+v is literal-next; rewriting those to cmd would
-- silently break interrupting a process. So terminals and terminal-grade editors
-- pass through untouched, and zshrc/bashrc bind ctrl+arrows themselves to get
-- the same word movement inside the shell by a different route.

-- ctrl+KEY becomes MODS+KEY. Only the modifier changes, never the key.
--
-- Whether a rewrite is safe in a terminal is a property of the KEY, not of the
-- app -- so the exclusion lives here rather than in one blanket app list.
--
--   inTerminals = true   nothing in a shell depends on the raw chord, so rewrite
--                        it everywhere. zsh binds BOTH ctrl+arrow and alt+arrow
--                        to backward-word/forward-word, so ctrl -> alt is a
--                        no-op at a prompt, and inside a TUI (which never reads
--                        zsh's keymap) alt+arrow is the convention that works.
--
--   inTerminals = false  the chord already means something load-bearing in a
--                        shell. ctrl+a is beginning-of-line, used constantly,
--                        and cmd+a in a terminal selects the whole scrollback --
--                        never what you want mid-command.
--
-- Deliberately absent entirely: ctrl+c/v/x. Those stay on cmd everywhere. ctrl+c
-- is SIGINT, and a rewrite leaking into any unlisted app would swallow an
-- interrupt silently. cmd+c/v/x already work, so there is nothing to win.
--
-- ctrl+arrows also require macOS's "Move left/right a space" to be OFF
-- (System Settings > Keyboard > Shortcuts > Mission Control). WindowServer
-- handles those above every event tap, so while enabled the keys never arrive.
local REWRITE = {
  a     = { mods = { "cmd" }, inTerminals = false },  -- select all
  left  = { mods = { "alt" }, inTerminals = true  },  -- previous word
  right = { mods = { "alt" }, inTerminals = true  },  -- next word
}

local TERMINALS = {
  ["net.kovidgoyal.kitty"]  = true,
  ["com.mitchellh.ghostty"] = true,
  ["com.apple.Terminal"]    = true,
  ["com.googlecode.iterm2"] = true,
  ["com.microsoft.VSCode"]  = true,   -- integrated terminal
  ["dev.zed.Zed"]           = true,
  ["org.gnu.Emacs"]         = true,
  ["org.vim.MacVim"]        = true,
}

-- Prefixes because JetBrains ships one bundle id per IDE, and Cursor's id is a
-- build-specific hash that changes between releases.
local TERMINAL_PREFIX = { "com.jetbrains.", "com.todesktop." }

-- An unrecognised app counts as NOT a terminal, so the arrows work in it. The
-- tradeoff: a newly installed terminal emulator would get ctrl+a rewritten until
-- its bundle id is added above. That is a one-line fix and an obvious symptom,
-- which beats arrows silently not working in every app nobody listed.
local function isTerminal(id)
  if not id then return false end
  if TERMINALS[id] then return true end
  for _, prefix in ipairs(TERMINAL_PREFIX) do
    if id:sub(1, #prefix) == prefix then return true end
  end
  return false
end

--------------------------------------------------------------------------------
-- Tab keys in the browser, matching kitty
--------------------------------------------------------------------------------
-- kitty binds ctrl+t / ctrl+w / alt+digit natively (see kitty/kitty.conf).
-- Chrome has no user-configurable shortcuts on macOS at all, so rewriting them
-- here is the only mechanism that exists -- not a workaround for a setting
-- nobody found.
--
-- Scoped to browsers by bundle id, deliberately NOT to "anything that is not a
-- terminal". ctrl+w leaking into an ordinary app would arrive as cmd+w and
-- close the WINDOW, turning a stale delete-word reflex into lost work. An
-- unlisted browser merely lacks the keys; the inverse loses data.
local BROWSERS = {
  ["com.google.Chrome"] = true,
  ["com.apple.Safari"]  = true,
}

local BROWSER_CTRL = {
  t = { mods = { "cmd" } },   -- new tab
  w = { mods = { "cmd" } },   -- close tab
}

-- cmd+1..8 and cmd+9 are already tab-N and last-tab in Chrome, exactly what
-- kitty's alt+1..8 and alt+9 do, so the digits need nothing but the modifier
-- swapped. alt+p is kitty's fuzzy tab picker and cmd+shift+a is Chrome's Search
-- Tabs, the same idea -- and the one entry that changes the KEY rather than
-- only the modifier. Safari has no equivalent, so there alt+p does nothing.
local BROWSER_ALT = {
  ["1"] = { mods = { "cmd" } },
  ["2"] = { mods = { "cmd" } },
  ["3"] = { mods = { "cmd" } },
  ["4"] = { mods = { "cmd" } },
  ["5"] = { mods = { "cmd" } },
  ["6"] = { mods = { "cmd" } },
  ["7"] = { mods = { "cmd" } },
  ["8"] = { mods = { "cmd" } },
  ["9"] = { mods = { "cmd" } },
  p     = { mods = { "cmd", "shift" }, key = "a" },
}

-- Keyed by keycode so the hot path does no string work.
local function byKeycode(rules)
  local out = {}
  for key, rule in pairs(rules) do
    local code = hs.keycodes.map[key]
    if code then
      if rule.key then rule.code = hs.keycodes.map[rule.key] end
      out[code] = rule
    end
  end
  return out
end

local CTRL_RULES         = byKeycode(REWRITE)
local BROWSER_CTRL_RULES = byKeycode(BROWSER_CTRL)
local BROWSER_ALT_RULES  = byKeycode(BROWSER_ALT)

-- The event is mutated in place and passed on, rather than swallowed and
-- reposted. Reposting would re-enter this tap and need a loop guard; mutating
-- cannot, because the replacement no longer carries the modifier we match on.
keyLayer = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
  local f = e:getFlags()
  -- ctrl+cmd, ctrl+alt and the like belong to other owners, macOS itself and
  -- kitty's config-reload among them.
  if f.cmd or (f.ctrl and f.alt) then return false end

  local code = e:getKeyCode()
  local rule, browsersOnly
  if f.ctrl then
    rule = CTRL_RULES[code]
    if not rule then rule, browsersOnly = BROWSER_CTRL_RULES[code], true end
  elseif f.alt then
    rule, browsersOnly = BROWSER_ALT_RULES[code], true
  end
  if not rule then return false end

  -- Deliberately after the keycode lookup: this callback runs on every keystroke
  -- typed anywhere, and the app query is the expensive part.
  local app = hs.application.frontmostApplication()
  local id = app and app:bundleID()

  if browsersOnly then
    if not BROWSERS[id] then return false end
    -- Exact chord only. alt+shift+1 is nobody's tab key, and the shift these
    -- rules do want (Chrome's cmd+shift+a) comes from the rule itself.
    if f.shift then return false end
  elseif not rule.inTerminals and isTerminal(id) then
    return false
  end

  local mods = {}
  for _, m in ipairs(rule.mods) do mods[m] = true end
  if f.shift then mods.shift = true end   -- carries ctrl+shift+arrow -> alt+shift+arrow
  e:setFlags(mods)
  if rule.code then e:setKeyCode(rule.code) end
  return false
end)
keyLayer:start()

--------------------------------------------------------------------------------
-- Move the focused window to the next monitor
--------------------------------------------------------------------------------
-- macOS has no shortcut for this and neither did any window manager tried here.
local function moveScreen(dir)
  local w = hs.window.focusedWindow()
  if not w then return end
  local target = (dir == "next") and w:screen():next() or w:screen():previous()
  if target then w:moveToScreen(target, false, true) end
end

hs.hotkey.bind({ "cmd", "alt", "shift" }, "right", function() moveScreen("next") end)
hs.hotkey.bind({ "cmd", "alt", "shift" }, "left",  function() moveScreen("prev") end)

--------------------------------------------------------------------------------
-- App launcher
--------------------------------------------------------------------------------
-- ctrl+cmd, not cmd. A bare cmd chord was the obvious choice and has no room:
-- cmd+c is Copy and cmd+t is New Tab, and hs.hotkey.bind fires BEFORE the
-- focused app sees the key, so binding either would break it in every
-- application on the machine. ctrl+cmd is genuinely free -- macOS claims only
-- F, space, Q and D on it, and kitty only comma.
--
-- Keyed by bundle id rather than app name: a name is localised and drifts
-- between releases, a bundle id does not.
local LAUNCH = {
  i = "com.google.Chrome",
  c = "net.kovidgoyal.kitty",
  t = "com.apple.Terminal",
}

for key, bundleID in pairs(LAUNCH) do
  hs.hotkey.bind({ "ctrl", "cmd" }, key, function()
    -- launchOrFocus rather than launch: a second press returns to the app
    -- instead of opening another copy of it.
    if not hs.application.launchOrFocusByBundleID(bundleID) then
      hs.alert.show("launcher: not installed -- " .. bundleID)
    end
  end)
end

--------------------------------------------------------------------------------
-- Restart Mos, the scroll handler
--------------------------------------------------------------------------------
-- Mos drives the external mouse wheel through an event tap, and that tap has
-- been seen to stop delivering events after hours of uptime: the wheel goes dead
-- while the trackpad, which Mos does not touch, keeps working. Relaunching
-- clears it. This is worth a binding because the failure takes away the very
-- scrolling you would need to go fix it by hand.
--
-- Quit, then SIGKILL whatever is still there. The graceful quit comes first
-- because Mos writes its preferences back on exit, but it cannot be relied on
-- alone: the binding exists precisely for a Mos that has stopped behaving, and
-- a process in that state need not answer a quit AppleEvent.
--
-- The pause runs on hs.timer rather than a sleep. That is not a style choice --
-- this is the same process as keyLayer above, so blocking it would stall that
-- event tap too and swallow every keystroke typed during the wait.
local MOS_BUNDLE_ID = "com.caldis.Mos"

local function restartMos()
  local mos = hs.application.get(MOS_BUNDLE_ID)
  if mos then mos:kill() end

  hs.timer.doAfter(1, function()
    local surviving = hs.application.get(MOS_BUNDLE_ID)
    if surviving then surviving:kill9() end

    hs.timer.doAfter(0.5, function()
      if hs.application.launchOrFocusByBundleID(MOS_BUNDLE_ID) then
        hs.alert.show("Mos restarted")
      else
        hs.alert.show("Mos: not installed")
      end
    end)
  end)
end

hs.hotkey.bind({ "ctrl", "cmd", "alt" }, "m", restartMos)


--------------------------------------------------------------------------------
-- Introspection helpers, callable from the shell via `hs -c`
--------------------------------------------------------------------------------
-- Kept because macOS gives the shell no way to see window geometry: screencapture
-- and osascript both need permissions the terminal does not have, so these are
-- the only way to answer "where did that window actually go".

function windowReport()
  local out = {}
  for _, w in ipairs(hs.window.allWindows()) do
    local app, f = w:application(), w:frame()
    out[#out + 1] = string.format("%-18s %6d,%-6d %4dx%-5d %s",
      app and app:name() or "?", f.x, f.y, f.w, f.h, (w:title() or ""):sub(1, 44))
  end
  table.sort(out)
  return table.concat(out, "\n")
end

function screenReport()
  local out = {}
  for _, s in ipairs(hs.screen.allScreens()) do
    local f = s:fullFrame()
    out[#out + 1] = string.format("%-26s %6d,%-6d %dx%d", s:name(), f.x, f.y, f.w, f.h)
  end
  return table.concat(out, "\n")
end

-- Windows with almost no pixels on any screen. A window manager that hides a
-- workspace by parking it off-screen leaves its windows unreachable if it dies,
-- so this is the recovery check to run before quitting one.
function strandedReport()
  local out = {}
  for _, w in ipairs(hs.window.allWindows()) do
    local f, onScreen = w:frame(), false
    for _, s in ipairs(hs.screen.allScreens()) do
      local sf = s:fullFrame()
      local ox = math.max(0, math.min(f.x + f.w, sf.x + sf.w) - math.max(f.x, sf.x))
      local oy = math.max(0, math.min(f.y + f.h, sf.y + sf.h) - math.max(f.y, sf.y))
      if ox * oy > 0.30 * (f.w * f.h) then onScreen = true end
    end
    if not onScreen then
      out[#out + 1] = string.format("%s :: %s", w:application():name(), w:title() or "")
    end
  end
  return ("stranded: %d%s"):format(#out, #out > 0 and ("\n" .. table.concat(out, "\n")) or "")
end

hs.alert.show("dev-setup config loaded")
