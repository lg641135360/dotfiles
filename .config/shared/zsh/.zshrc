# Ensure ZSHDOTDIR has a default value (if not defined externally)
: "${ZSHDOTDIR:=$HOME/.config/zsh}"

# Load Zap plugin manager
[ -f "$HOME/.local/share/zap/zap.zsh" ] && source "$HOME/.local/share/zap/zap.zsh"

# Continue only for interactive shell, return early in script mode (reduce overhead)
[[ $- != *i* ]] && return

# History settings
HISTFILE="$ZSHDOTDIR/.zsh_history"
HISTSIZE=20000
SAVEHIST=20000
mkdir -p -- "${HISTFILE%/*}" 2>/dev/null || true
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_FIND_NO_DUPS \
	INC_APPEND_HISTORY SHARE_HISTORY

# Local customizations (load only if exists)
[ -r "$HOME/.config/zsh/aliases.zsh" ] && plug "$HOME/.config/zsh/aliases.zsh"
[ -r "$HOME/.config/zsh/exports.zsh" ] && plug "$HOME/.config/zsh/exports.zsh"

# Plugin order: syntax highlighting must be last
plug "zap-zsh/supercharge"
plug "zap-zsh/vim"
# plug "zap-zsh/zap-prompt"
plug "hlissner/zsh-autopair"
plug "zsh-users/zsh-autosuggestions"
# plug "zap-zsh/atmachine"
plug "romkatv/powerlevel10k"
plug "zap-zsh/fzf"
plug "rupa/z"
plug "zsh-users/zsh-history-substring-search"
plug "zsh-users/zsh-syntax-highlighting"  # Must be last

# History substring search keybindings (choose between arrow keys or Ctrl-P/N, default to Ctrl-P/N)
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down

# Common convenient setopt settings (keep as needed)
setopt AUTO_CD GLOB_DOTS EXTENDED_GLOB

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh

# Linux specific configurations
if [[ "$(uname)" == "Linux" ]]; then
    # >>> conda lazy initialize >>>
    # Lazy load conda to speed up shell startup
    # Only initialize when conda command is actually used
    if [ -f "/opt/miniforge/bin/conda" ]; then
        export PATH="/opt/miniforge/bin:$PATH"
        
        # Lazy load function
        conda() {
            unset -f conda
            __conda_setup="$('/opt/miniforge/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
            if [ $? -eq 0 ]; then
                eval "$__conda_setup"
            else
                if [ -f "/opt/miniforge/etc/profile.d/conda.sh" ]; then
                    . "/opt/miniforge/etc/profile.d/conda.sh"
                fi
            fi
            unset __conda_setup
            conda "$@"
        }
    fi
    # <<< conda lazy initialize <<<

    # cuda env
    export PATH=/opt/cuda/bin:$PATH
    export LD_LIBRARY_PATH=/opt/cuda/lib64:$LD_LIBRARY_PATH

    # cargo (lazy load)
    if [ -f "$HOME/.cargo/env" ]; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
fi

export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_CASK_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
