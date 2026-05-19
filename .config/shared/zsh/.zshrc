# Powerlevel10k instant prompt (must stay near top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ZSH config root (ZDOTDIR should be set to ~/.config/zsh)
ZSH_CONF="${ZDOTDIR:-$HOME/.config/zsh}"

# Modules (loaded in order)
source "$ZSH_CONF/plugins.zsh"       # zinit + plugins + completions
source "$ZSH_CONF/options.zsh"       # setopt options
source "$ZSH_CONF/path.zsh"          # PATH management (before commands that need it)
source "$ZSH_CONF/env.zsh"           # environment variables + fzf
source "$ZSH_CONF/keybindings.zsh"   # history search bindings
source "$ZSH_CONF/history.zsh"       # history config
source "$ZSH_CONF/aliases.zsh"       # command aliases
source "$ZSH_CONF/functions.zsh"     # utility functions
source "$ZSH_CONF/integrations.zsh"  # zoxide, tmuxifier, p10k, conda
source "$ZSH_CONF/zsh-syntax-highlighting-catppuccin-mocha.zsh"  # Catppuccin Mocha theme
