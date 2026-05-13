# Neovim Config Notes

## Packer Gotchas

### Commenting out a plugin doesn't uninstall it

Packer does not remove plugin directories when you comment out or delete a `use` line from your config. The plugin remains in `~/.local/share/nvim/site/pack/packer/start/` (or `opt/`) and continues to load on startup. This means commented-out plugins can still produce startup messages, keybinding conflicts, and side effects.

To actually remove a plugin: comment it out in your config, then run `:PackerClean` inside Neovim (it will prompt you to confirm deletion). Alternatively, manually delete the directory from `~/.local/share/nvim/site/pack/packer/`.

### :PackerSync vs :PackerUpdate vs :PackerCompile

- `:PackerSync` — the all-in-one command: cleans removed plugins, installs new ones, updates existing ones, and recompiles the loader.
- `:PackerUpdate` — only updates/installs plugins, does **not** clean removed ones.
- `:PackerCompile` — only regenerates `packer_compiled.lua`. Needed after changing plugin config/ordering but not adding or removing plugins.

When in doubt, use `:PackerSync`.

### packer_compiled.lua can go stale

Packer generates `~/.config/nvim/plugin/packer_compiled.lua` (or similar, depending on config). This file caches plugin load order and config. If it gets out of sync with your actual config (e.g. after a git pull or manual edits), you can get errors about missing plugins or stale behavior. Fix with `:PackerCompile` or `:PackerSync`.

### Plugin load order matters for dependencies

If plugin B depends on plugin A, make sure A appears before B in your `startup` block, or use the `requires` key to declare the dependency. Packer doesn't guarantee load order otherwise, which can cause intermittent startup errors.

### `config` runs at load time, `setup` may not

A `config` function in a `use` block runs when the plugin loads. But if the plugin itself expects you to call its `.setup()`, skipping that call inside `config` means the plugin is loaded but not initialized — it may silently do nothing or partially work.

### Packer is unmaintained

Packer has been archived by its author. It still works but receives no updates. The community successor is [lazy.nvim](https://github.com/folke/lazy.nvim). Something to keep in mind if you hit issues that won't get fixed upstream.
