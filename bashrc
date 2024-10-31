
shopt -s checkwinsize

PS1='[\D{%T}] ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]\n\[\033[01;34m\]\w\[\033[00m\]\n\$ '

alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'

alias gls="git ls-files && git ls-files --exclude-standard --others"

# Old habits die hard
alias vim="nvim"

export ERL_AFLAGS="-kernel shell_history enabled"
