
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
        source /etc/profile.d/vte.sh
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

alias go="cd $BASE_PATH/.go && cd -P "
mkdir -p $BASE_PATH/.go
golink() {
    if [ -z "$1" ]; then
        echo "Usage: golink <name>"
        return 1
    fi

    local target="$PWD"
    local link_name="$HOME/.go/$1"

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

    # Use find to locate all files and sed to replace strings
    find . -type f -exec sed -i "s/$search/$replace/g" {} +
    echo "Replaced '$search' with '$replace' in all files recursively."
}

ssgr() {
    if [ $# -ne 2 ]; then
        echo "Usage: ssgr <replace_string> <search_string>"
        return 1
    fi

    ssg "$2" "$1"
}

export PATH="/snap/bin:$PATH"

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'


# FNM setup, see https://github.com/Schniz/fnm
# Install: curl -fsSL https://fnm.vercel.app/install | bash
# Delete the appended text from your .bashrc since we have it here.
FNM_PATH="$BASE_PATH/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env`"
fi

eval "$(fnm env --use-on-cd --shell bash)"

