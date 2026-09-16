# dev-setup

## Tool integration

Personal CLI tools that dev-setup clones and installs. The division of
responsibility matters more than the mechanics:

- **A tool repo owns its own deployment.** `./install.sh` at the repo root is the
  whole contract: clone it, run it, it is installed. The script decides what to
  build and where the binary goes. This holds regardless of language, which is
  what keeps a Python tool uniform with the Rust ones.
- **dev-setup owns the environment, never the build** -- checkouts, toolchain,
  PATH. It used to build the Rust tools itself, so two places knew how Choros
  installs and they disagreed: two binaries at different commits, the stale one
  earlier on PATH. Resist adding a second install path for a special case. One
  uniform path is the fix; a smarter dispatch is not.
- **An installer advises about shell config, it never edits it.** A tool
  mutating dotfiles it does not own is the same inversion pointed the other way.
- **Deploy a copy, never a reference into a build directory.** A rebuild in
  progress or a `cargo clean` must not be able to break the live command.
- **Record what was deployed**, under XDG state. A checkout's HEAD is not proof
  of what is live, because any clone can run the installer. It is also what lets
  a tool clean up its own renamed binary -- nothing outside the repo can see that
  a rename happened.

Follow the existing scripts rather than re-deriving this.

## Global instructions live in claude/, not here

`claude/CLAUDE.md` is wired into `~/.claude/CLAUDE.md` by reference and applies
to every project. It is deliberately not the repo root file, so nothing
dev-setup-specific reaches other repos. Repo-specific guidance belongs in this
file.

`claude/CLAUDE.md` should ONLY be written to by a human, never an LLM or AI.
