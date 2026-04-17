#######################################################
# Environment Variables
#######################################################

export EDITOR=nvim
export VISUAL=nvim
export SUDO_EDITOR=nvim
export FCEDIT=nvim
export TERMINAL=alacritty

# Use bat as pager
if [[ -x "$(command -v bat)" ]]; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export PAGER=bat
fi

# FZF default options (Tokyo Night colors)
if [[ -x "$(command -v fzf)" ]]; then
    export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
      --info=inline-right \
      --ansi \
      --layout=reverse \
      --border=rounded \
      --color=border:#27a1b9 \
      --color=fg:#c0caf5 \
      --color=gutter:#16161e \
      --color=header:#ff9e64 \
      --color=hl+:#2ac3de \
      --color=hl:#2ac3de \
      --color=info:#545c7e \
      --color=marker:#ff007c \
      --color=pointer:#ff007c \
      --color=prompt:#2ac3de \
      --color=query:#c0caf5:regular \
      --color=scrollbar:#27a1b9 \
      --color=separator:#ff9e64 \
      --color=spinner:#ff007c \
    "
fi

# fzf zsh integration
if [[ -x "$(command -v fzf)" ]]; then
    source <(fzf --zsh)
fi

# codex env
if [[ -f "$HOME/codex_env" ]]; then
  source "$HOME/codex_env"
fi
