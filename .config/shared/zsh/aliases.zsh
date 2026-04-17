#######################################################
# Aliases
#######################################################

alias c='clear'
alias q='exit'
alias ..='cd ..'
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias rmdir='rmdir -v'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Neovim
if [[ -x "$(command -v nvim)" ]]; then
    alias nv='nvim'
    alias snv='sudo nvim'
    alias nvis='nvim "+set si"'
elif [[ -x "$(command -v vim)" ]]; then
    alias vi='vim'
    alias svi='sudo vim'
    alias vis='vim "+set si"'
fi

# lsd
if [[ -x "$(command -v lsd)" ]]; then
    alias ls='lsd -F --group-dirs first'
    alias ll='lsd --all --header --long --group-dirs first'
    alias tree='lsd --tree'
fi

# xdg-open
if [[ -x "$(command -v xdg-open)" ]]; then
    alias open='runfree xdg-open'
fi

# evince PDF reader
if [[ -x "$(command -v evince)" ]]; then
    alias pdf='runfree evince'
fi

# lazygit
if [[ -x "$(command -v lazygit)" ]]; then
    alias lg='lazygit'
fi

# fzf
if [[ -x "$(command -v fzf)" ]]; then
    alias fzf='fzf --preview "bat --style=numbers --color=always --line-range :500 {}"'
    # Use functions instead of aliases to avoid eager $() expansion
    if [[ -x "$(command -v xdg-open)" ]]; then
        function preview() {
            open "$(fzf --info=inline --query="${@}")"
        }
    else
        function preview() {
            edit "$(fzf --info=inline --query="${@}")"
        }
    fi
fi

# IP addresses
if [[ -x "$(command -v ip)" ]]; then
    alias iplocal="ip -br -c a"
else
    alias iplocal="ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'"
fi

if [[ -x "$(command -v curl)" ]]; then
    alias ipexternal="curl -s ifconfig.me && echo"
elif [[ -x "$(command -v wget)" ]]; then
    alias ipexternal="wget -qO- ifconfig.me && echo"
fi

# Homebrew mirror (China)
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
