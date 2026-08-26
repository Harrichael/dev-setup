
if [[ -z "${BASE_PATH}" ]]; then
  echo "Error: BASE_PATH is not defined. Please define it in your .bashrc file before sourcing this script."
  return 1
fi


PS1='[\D{%T}] ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]$(__git_ps1 " (git:%s)")\n\[\033[01;34m\]\w\[\033[00m\]\n\$ '


# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth

HISTSIZE=1000
HISTFILESIZE=100000

# append to the history file, don't overwrite it
shopt -s histappend


# Recheck winsize after each command
shopt -s checkwinsize


# Erlang shell History
export ERL_AFLAGS="-kernel shell_history enabled"


# TILIX setup
if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
        [ -f /etc/profile.d/vte.sh ] && source /etc/profile.d/vte.sh
fi


# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias cgrep='grep --color=always'

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

[ -d /snap/bin ] && export PATH="/snap/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'


# FNM setup, see https://github.com/Schniz/fnm
# Install: curl -fsSL https://fnm.vercel.app/install | bash
# Delete the appended text from your .bashrc since we have it here.
# The curl installer drops the fnm *binary* here, so it needs to go on PATH.
# Homebrew puts fnm on PATH already, and this is then merely fnm's data dir
# (aliases/, node-versions/) with no binaries -- so test for the binary, not
# the directory, or we prepend a junk PATH entry on macOS.
FNM_PATH="$BASE_PATH/.local/share/fnm"
if [ -x "$FNM_PATH/fnm" ]; then
  export PATH="$FNM_PATH:$PATH"
fi

if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell bash)"
fi

if command -v choros >/dev/null 2>&1; then
  eval "$(choros shell-init)"
fi

# --- Line editing -----------------------------------------------------------
# Mirrors the zshrc bindings so word movement is the same keystroke on both
# platforms. readline binds \e[1;5D by default on many distros but not all.
bind '"\e[1;5D": backward-word'    # ctrl+left
bind '"\e[1;5C": forward-word'     # ctrl+right
bind '"\e[1;3D": backward-word'    # alt+left
bind '"\e[1;3C": forward-word'     # alt+right
bind '"\e[H": beginning-of-line'
bind '"\e[F": end-of-line'
bind '"\C-h": backward-kill-word'  # ctrl+backspace
bind '"\e[3;5~": kill-word'        # ctrl+delete
