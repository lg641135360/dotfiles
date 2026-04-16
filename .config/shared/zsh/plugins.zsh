#######################################################
# Zinit Plugin Manager + Plugins
#######################################################

# Zinit home directory
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Auto-install zinit if not present
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source zinit
source "${ZINIT_HOME}/zinit.zsh"

# Theme: Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light jeffreytse/zsh-vi-mode
zinit light hlissner/zsh-autopair
zinit light MichaelAquilina/zsh-you-should-use

# Snippets (Oh-My-Zsh plugins)
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::docker
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

# Replay deferred completions (MUST be last, after all plugins/snippets)
zinit cdreplay -q

# Vi-mode cursor styles (set AFTER zsh-vi-mode loads so constants are defined)
# Available: ZVM_CURSOR_BLOCK, ZVM_CURSOR_BEAM, ZVM_CURSOR_BLINKING_BLOCK,
#            ZVM_CURSOR_BLINKING_BEAM, ZVM_CURSOR_BLINKING_UNDERLINE, ZVM_CURSOR_UNDERLINE
ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_BLINKING_UNDERLINE
ZVM_SYSTEM_CLIPBOARD_ENABLED=true  # yy copies to system clipboard
