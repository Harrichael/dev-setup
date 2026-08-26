
if [[ -z "${BASE_PATH}" ]]; then
  echo "Error: BASE_PATH is not defined. Please define it in your .zshrc file before sourcing this script."
  return 1
fi


# Prompt. Git branch comes from vcs_info (zsh builtin) rather than __git_ps1,
# which would require sourcing git-prompt.sh from the Xcode toolchain.
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' (git:%b)'
zstyle ':vcs_info:git:*' actionformats ' (git:%b|%a)'
precmd_functions+=(vcs_info)
setopt PROMPT_SUBST

PROMPT='[%D{%T}] %F{green}%n@%m%f${vcs_info_msg_0_}
%F{blue}%~%f
%# '


# History
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=100000

setopt APPEND_HISTORY      # append to the history file, don't overwrite it
setopt HIST_IGNORE_DUPS    # don't put duplicate lines in the history
setopt HIST_IGNORE_SPACE   # don't put lines starting with a space in the history

# zsh tracks window size natively, no checkwinsize equivalent needed.


# Erlang shell History
export ERL_AFLAGS="-kernel shell_history enabled"


# Completion
autoload -Uz compinit && compinit


alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias cgrep='grep --color=always'

# dir/vdir are GNU coreutils only and are deliberately absent here.

alias ngrep='grep --exclude-dir=node_modules --exclude-dir=".nx" --exclude-dir=dist'
alias ncgrep='grep --color=always --exclude-dir=node_modules --exclude-dir=dist'
alias nx="npx nx"
alias nx_test_all="npx nx run-many -t test --skip-nx-cache"

alias gls="git ls-files && git ls-files --exclude-standard --others"
alias gtree="git ls-tree -r --name-only HEAD | tree --fromfile"

alias v="nvim"

# The `go` function below shadows the Go compiler, so reach the real binary as
# `golang`. `command` bypasses function and alias lookup, resolving it on PATH.
alias golang="command go"

mkdir -p "$BASE_PATH/.go"
# Jump to a link registered under $BASE_PATH/.go (see golink).
#
# The target is resolved inside a subshell so that exactly ONE cd runs in this
# shell. That matters because every cd overwrites OLDPWD: the old two-cd alias
# left OLDPWD pointing at the .go directory, so `cd -` took you there instead
# of back where you came from.
go() {
    if [ $# -eq 0 ]; then
        ls "$BASE_PATH/.go"
        return 0
    fi

    local target
    target=$(cd "$BASE_PATH/.go" && cd -P "$1" && pwd) || return 1
    cd "$target"
}
golink() {
    if [ -z "$1" ]; then
        echo "Usage: golink <name>"
        return 1
    fi

    local target="$PWD"
    local link_name="$BASE_PATH/.go/$1"

    if [ -e "$link_name" ]; then
        echo "Error: '$link_name' already exists."
        return 1
    fi

    ln -s "$target" "$link_name"
    echo "Created symlink: $link_name -> $target"
}

ssg() {
    if [ $# -ne 2 ]; then
        echo "Usage: ssg <search_string> <replace_string>"
        return 1
    fi

    local search="$1"
    local replace="$2"

    # perl -pi takes identical args on BSD and GNU; sed -i does not.
    find . -type f -not -path '*/.git/*' -exec perl -pi -e "s/$search/$replace/g" {} +
    echo "Replaced '$search' with '$replace' in all files recursively."
}

ssgr() {
    if [ $# -ne 2 ]; then
        echo "Usage: ssgr <replace_string> <search_string>"
        return 1
    fi

    ssg "$2" "$1"
}

# Homebrew's PATH is set up by ~/.zprofile via `brew shellenv`.
export PATH="$HOME/.cargo/bin:$PATH"

# Add an "alert" function for long running commands.  Use like so:
#   sleep 10; alert
# The notification text is passed through argv rather than interpolated into
# the AppleScript source, so quotes in the previous command can't break it.
alert() {
    local rc=$?
    local title
    [ $rc = 0 ] && title="Terminal" || title="Error"

    # $history[$HISTCMD] is the line being executed. `fc -ln -1` would give
    # the PREVIOUS line, so `sleep 10; alert` would name the wrong command.
    local last
    last=$(print -r -- "${history[$HISTCMD]}" | sed -e 's/^[[:space:]]*//' -e 's/[;&|][[:space:]]*alert$//')
    [ -z "$last" ] && last="command"

    osascript -e 'on run argv
        display notification (item 1 of argv) with title (item 2 of argv)
    end run' "$last" "$title"
}


# FNM setup, see https://github.com/Schniz/fnm
# Installed via the Brewfile on macOS.
# The curl installer drops the fnm *binary* here, so it needs to go on PATH.
# Homebrew puts fnm on PATH already, and this is then merely fnm's data dir
# (aliases/, node-versions/) with no binaries -- so test for the binary, not
# the directory, or we prepend a junk PATH entry on macOS.
FNM_PATH="$BASE_PATH/.local/share/fnm"
if [ -x "$FNM_PATH/fnm" ]; then
  export PATH="$FNM_PATH:$PATH"
fi

if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

if command -v choros >/dev/null 2>&1; then
  eval "$(choros shell-init)"
fi

# --- Line editing -----------------------------------------------------------
# kitty already sends these sequences; zsh binds nothing to them by default, so
# ctrl+left/right did nothing at all before this. Deliberately independent of
# whatever remaps keys at the GUI level: ctrl+c/a/e/w must keep their POSIX
# meanings in a shell, so a terminal is always the wrong place to borrow the
# GUI's ctrl conventions wholesale.
bindkey "^[[1;5D" backward-word        # ctrl+left
bindkey "^[[1;5C" forward-word         # ctrl+right
bindkey "^[[1;3D" backward-word        # alt+left, the macOS convention
bindkey "^[[1;3C" forward-word         # alt+right
bindkey "^[[H"    beginning-of-line    # Home
bindkey "^[[F"    end-of-line          # End
bindkey "^[[1~"   beginning-of-line    # Home, alternate encoding
bindkey "^[[4~"   end-of-line          # End, alternate encoding
# ctrl+backspace and ctrl+h transmit the same byte (0x08), so this also
# changes bare ctrl+h from delete-char to delete-word. Plain backspace is
# 0x7f and unaffected.
bindkey "^H"      backward-kill-word   # ctrl+backspace (= ctrl+h)
bindkey "^[[3;5~" kill-word            # ctrl+delete
bindkey "^[[3~"   delete-char          # Delete
