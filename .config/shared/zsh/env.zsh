#######################################################
# Environment Variables
#######################################################

export EDITOR=nvim
export VISUAL=nvim
export SUDO_EDITOR=nvim
export FCEDIT=nvim
export TERMINAL=alacritty

# Homebrew mirror (China)
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"

if [[ "$OSTYPE" == linux* && "${XDG_SESSION_TYPE:-}" != "wayland" ]]; then
    export XDG_CURRENT_DESKTOP=awesome
    export XDG_SESSION_DESKTOP=awesome
    export GTK_USE_PORTAL=1
elif [[ "$OSTYPE" == linux* ]]; then
    export GTK_USE_PORTAL=1
fi

# Use bat as pager
if [[ -x "$(command -v bat)" ]]; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export PAGER=bat
fi

# FZF default options (Catppuccin Mocha — 与 zsh-syntax-highlighting / starship 主题统一)
if [[ -x "$(command -v fzf)" ]]; then
    export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
      --info=inline-right \
      --ansi \
      --layout=reverse \
      --border=rounded \
      --color=bg:#1e1e2e \
      --color=bg+:#313244 \
      --color=fg:#cdd6f4 \
      --color=fg+:#cdd6f4 \
      --color=gutter:#1e1e2e \
      --color=header:#fab387 \
      --color=hl+:#89dceb \
      --color=hl:#89dceb \
      --color=info:#6c7086 \
      --color=marker:#f38ba8 \
      --color=pointer:#f38ba8 \
      --color=prompt:#89dceb \
      --color=query:#cdd6f4:regular \
      --color=scrollbar:#89dceb \
      --color=separator:#fab387 \
      --color=spinner:#f38ba8 \
    "
fi

# Ctrl-T / Alt-C 在 fd 可用时用它列文件（尊重隐藏文件、跳过 .git）。
# fd 未安装时不设，fzf 回退默认 find。
if [[ -x "$(command -v fd)" ]]; then
    export FZF_CTRL_T_COMMAND='fd --hidden --follow --exclude .git'
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

# fzf --zsh（Tab / Ctrl-R / Ctrl-T）改在 plugins.zsh 的 zvm_after_init
# 里加载：zsh-vi-mode 会覆盖先前 bindkey，提前 source 会让 Tab 失效。

