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

# Plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light jeffreytse/zsh-vi-mode
# 以下两个插件合计占 plugins.zsh 约 73% 耗时（autopair ~0.22s, you-should-use
# ~0.12s），但功能仅在按键时才需要，用 wait lucid 延迟到首次提示符后异步加载。
zinit ice wait lucid; zinit light hlissner/zsh-autopair
zinit ice wait lucid; zinit light MichaelAquilina/zsh-you-should-use

# Snippets (Oh-My-Zsh plugins)
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::docker
zinit snippet OMZP::command-not-found

# Load completions
# -u 跳过 compaudit：单用户桌面 fpath 目录均由 zinit 管理，权限检查无实际
# 价值，跳过可省约 0.15s（0.20s → 0.05s）。
# -d 显式指定 dump 路径，避免不同 ZDOTDIR / 写入受限环境生成 .zcompdump.<host>.<pid>
# 孤儿文件。
autoload -Uz compinit && compinit -u -d "$ZSH_CONF/.zcompdump"

# Replay deferred completions (MUST be last, after all plugins/snippets)
zinit cdreplay -q

# Vi-mode cursor styles (set AFTER zsh-vi-mode loads so constants are defined)
# Available: ZVM_CURSOR_BLOCK, ZVM_CURSOR_BEAM, ZVM_CURSOR_BLINKING_BLOCK,
#            ZVM_CURSOR_BLINKING_BEAM, ZVM_CURSOR_BLINKING_UNDERLINE, ZVM_CURSOR_UNDERLINE
ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_BLINKING_UNDERLINE
ZVM_SYSTEM_CLIPBOARD_ENABLED=true  # yy copies to system clipboard
