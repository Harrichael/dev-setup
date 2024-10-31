
PS1='[\D{%T}] ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]$(__git_ps1 " (git:%s)")\n\[\033[01;34m\]\w\[\033[00m\]\n\$ '


# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth

HISTSIZE=1000
HISTFILESIZE=100000

# append to the history file, don't overwrite it
shopt -s histappend


# Recheck winsize after each command
shopt -s checkwinsize


# Erland shell History
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

alias gls="git ls-files && git ls-files --exclude-standard --others"

alias v="nvim"

alias go="cd ~/.go && cd -P "
mkdir -p ~/.go
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


# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
