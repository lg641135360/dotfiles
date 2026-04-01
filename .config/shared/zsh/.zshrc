# ============================================================================
# ZSH Configuration
# ============================================================================

# Ensure ZSHDOTDIR has a default value (if not defined externally)
: "${ZSHDOTDIR:=$HOME/.config/zsh}"

# Load Zap plugin manager
[ -f "$HOME/.local/share/zap/zap.zsh" ] && source "$HOME/.local/share/zap/zap.zsh"

# Continue only for interactive shell, return early in script mode
[[ $- != *i* ]] && return

# ============================================================================
# History Configuration
# ============================================================================
HISTFILE="$ZSHDOTDIR/.zsh_history"
HISTSIZE=20000
SAVEHIST=20000
mkdir -p -- "${HISTFILE%/*}" 2>/dev/null || true

# History options
setopt HIST_IGNORE_DUPS          # Don't record duplicate entries
setopt HIST_IGNORE_ALL_DUPS      # Delete old duplicate entries
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks
setopt HIST_FIND_NO_DUPS         # Don't display duplicates in search
setopt INC_APPEND_HISTORY        # Write to history immediately
setopt SHARE_HISTORY             # Share history between sessions

# ============================================================================
# Shell Options
# ============================================================================
setopt GLOB_DOTS                 # Include dotfiles in glob
setopt EXTENDED_GLOB             # Enable extended globbing

# ============================================================================
# Local Customizations
# ============================================================================
[ -r "$HOME/.config/zsh/aliases.zsh" ] && plug "$HOME/.config/zsh/aliases.zsh"
[ -r "$HOME/.config/zsh/exports.zsh" ] && plug "$HOME/.config/zsh/exports.zsh"

# ============================================================================
# Plugins (syntax-highlighting must be last)
# ============================================================================
plug "zap-zsh/supercharge"             # Enhanced completion, auto-cd, Ctrl+X reload
plug "zap-zsh/vim"                     # Vim keybindings
plug "rupa/z"                          # Smart directory jumping
plug "hlissner/zsh-autopair"           # Auto-close quotes, brackets
plug "zsh-users/zsh-autosuggestions"   # Command suggestions from history
plug "zap-zsh/fzf"                     # Fuzzy finder integration
plug "Aloxaf/fzf-tab"                  # fzf-powered completion menu
plug "wfxr/forgit"                     # Interactive git operations with fzf
plug "kutsan/zsh-system-clipboard"     # System clipboard integration
plug "MichaelAquilina/zsh-you-should-use"  # Suggest aliases
plug "zsh-users/zsh-history-substring-search"
plug "wintermi/zsh-brew"                # Homebrew integration
plug "wintermi/zsh-starship"            # promt
plug "zsh-users/zsh-syntax-highlighting"  # Must be last

# brew promt config
autoload -Uz compinit
compinit -d "${ZDOTDIR:-$HOME}/.zcompdump"

# ============================================================================
# Key Bindings
# ============================================================================
# History substring search (Ctrl-P/N for up/down)
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down

# ============================================================================
# Platform-Specific Configuration
# ============================================================================
if [[ "$(uname)" == "Linux" ]]; then
    # Conda (lazy-loaded for faster shell startup)
    if [ -f "/opt/miniforge/bin/conda" ]; then
        export PATH="/opt/miniforge/bin:$PATH"
        conda() {
            unset -f conda
            __conda_setup="$('/opt/miniforge/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
            if [ $? -eq 0 ]; then
                eval "$__conda_setup"
            else
                [ -f "/opt/miniforge/etc/profile.d/conda.sh" ] && . "/opt/miniforge/etc/profile.d/conda.sh"
            fi
            unset __conda_setup
            conda "$@"
        }
    fi

    # CUDA environment
    if [ -d "/opt/cuda" ]; then
        export PATH="/opt/cuda/bin:$PATH"
        export LD_LIBRARY_PATH="/opt/cuda/lib64:$LD_LIBRARY_PATH"
    fi

    # Rust/Cargo
    [ -f "$HOME/.cargo/env" ] && export PATH="$HOME/.cargo/bin:$PATH"
fi

# npm
export PATH="$HOME/.npm-global/bin:$PATH"
# homebrew
export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
