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

# Plugins — 顺序有硬约束：
# 1. zsh-completions 必须在 compinit 之前进 fpath。
# 2. fzf-tab 必须在 compinit 之后、会包装 widget 的插件之前
#    （zsh-autosuggestions / zsh-syntax-highlighting）。
# 3. syntax-highlighting 放这组最后，避免它包不到后续 widget。
zinit light zsh-users/zsh-completions
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

# fzf-tab 官方要求在 compinit 之后加载；随后才加载会 wrap widget 的插件。
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting

# fzf-tab 推荐 zstyle（不要 use-fzf-default-opts，部分 FZF_DEFAULT_OPTS 会拆菜单）。
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd -1 --color=always -- $realpath'

# Replay deferred completions (MUST be last, after all plugins/snippets)
zinit cdreplay -q

# Vi-mode cursor styles (set AFTER zsh-vi-mode loads so constants are defined)
# Available: ZVM_CURSOR_BLOCK, ZVM_CURSOR_BEAM, ZVM_CURSOR_BLINKING_BLOCK,
#            ZVM_CURSOR_BLINKING_BEAM, ZVM_CURSOR_BLINKING_UNDERLINE, ZVM_CURSOR_UNDERLINE
ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_BLINKING_UNDERLINE
ZVM_SYSTEM_CLIPBOARD_ENABLED=true  # yy copies to system clipboard

# zsh-vi-mode 默认在首次提示符才 bindkey -v，并覆盖先前绑定。
# fzf 的 zsh 集成必须在那之后加载（Ctrl-R / Ctrl-T / **），再重新
# 启用 fzf-tab 把 Tab 抢回（最后一个绑 ^I）。fzf_default_completion
# 固定为 expand-or-complete，避免 ** 未触发时回落到 fzf-tab 形成递归。
function zvm_after_init() {
    # path.zsh 在本文件之后才把 linuxbrew 追加进 PATH；用 command -v
    # 而不是 $+commands[fzf]（后者可能在 PATH 更新前被负向缓存）。
    if [[ -x "$(command -v fzf)" ]]; then
        fzf_default_completion=expand-or-complete
        source <(fzf --zsh)
    fi
    (( $+functions[enable-fzf-tab] )) && enable-fzf-tab
}
