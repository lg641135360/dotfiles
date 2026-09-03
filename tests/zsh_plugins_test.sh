#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PLUGINS_FILE=$REPO_ROOT/.config/shared/zsh/plugins.zsh
ENV_FILE=$REPO_ROOT/.config/shared/zsh/env.zsh
ALIASES_FILE=$REPO_ROOT/.config/shared/zsh/aliases.zsh
OPTIONS_FILE=$REPO_ROOT/.config/shared/zsh/options.zsh

. "$REPO_ROOT/tests/lib/assert.sh"

# compinit 默认会跑 compaudit 检查 fpath 目录权限，实测占 ~0.15s。
# 单用户桌面环境下 fpath 目录均由 zinit 管理（用户自己控制），compaudit
# 无实际安全价值。用 -u 跳过可显著缩短启动时间。
test_compinit_skips_compaudit() {
    assert_contains 'compinit -u' "$PLUGINS_FILE"
    # 排除「裸 compinit」（无 -u）的旧写法：行尾不是 compinit，而是 compinit -u
    assert_not_matches 'compinit[[:space:]]*$' "$PLUGINS_FILE"
}

# compinit 默认把 dump 写到 $ZDOTDIR/.zcompdump，但在写入受限环境（IDE sandbox）
# 或 ZDOTDIR 不一致时会生成 .zcompdump.<host>.<pid> 孤儿文件。显式 -d 指定路径
# 可避免此问题，并让 dump 路径可控。
test_compinit_uses_explicit_dump_path() {
    assert_contains 'compinit -u -d "$ZSH_CONF/.zcompdump"' "$PLUGINS_FILE"
}

# zsh-autopair 与 zsh-you-should-use 是 plugins.zsh 中最慢的两个插件
# （分别约 0.22s / 0.12s，合计占 plugins.zsh 73%）。两者功能均在按键时
# 才需要，不参与首次提示符渲染，用 `zinit ice wait lucid` 延迟到首次
# 提示符后异步加载。
test_autopair_is_deferred() {
    assert_contains 'zinit ice wait lucid; zinit light hlissner/zsh-autopair' "$PLUGINS_FILE"
}

test_you_should_use_is_deferred() {
    assert_contains 'zinit ice wait lucid; zinit light MichaelAquilina/zsh-you-should-use' "$PLUGINS_FILE"
}

# 非延迟插件必须保持立即加载：syntax-highlighting/autosuggestions/fzf-tab
# 参与 prompt 渲染或补全交互，延迟会破坏首次提示符体验。
test_critical_plugins_load_immediately() {
    assert_contains 'zinit light zsh-users/zsh-syntax-highlighting' "$PLUGINS_FILE"
    assert_contains 'zinit light zsh-users/zsh-autosuggestions' "$PLUGINS_FILE"
    assert_contains 'zinit light Aloxaf/fzf-tab' "$PLUGINS_FILE"
    assert_not_matches 'zinit ice wait.*Aloxaf/fzf-tab' "$PLUGINS_FILE"
}

# p10k 已弃用（gitstatus 二进制在 aarch64 版本不匹配导致初始化失败，拖慢
# 提示符渲染）。改用 starship（单一 Rust 二进制，无版本依赖问题）。
# plugins.zsh 不应再引用 powerlevel10k。
test_p10k_is_removed() {
    assert_not_contains 'powerlevel10k' "$PLUGINS_FILE"
    assert_not_contains 'p10k' "$PLUGINS_FILE"
}

# 会注册补全的 snippet 必须在 compinit 之前；cdreplay 紧跟 compinit。
# fzf-tab 必须在 compinit 之后（官方要求），且在会包装 widget 的
# autosuggestions / syntax-highlighting 之前。
test_compinit_order_before_cdreplay() {
    assert_order 'zinit snippet OMZP::command-not-found' 'compinit -u' "$PLUGINS_FILE"
    assert_order 'compinit -u' 'zinit cdreplay -q' "$PLUGINS_FILE"
}

test_fzf_tab_loads_after_compinit_before_widget_wrappers() {
    assert_order 'compinit -u' 'zinit light Aloxaf/fzf-tab' "$PLUGINS_FILE"
    assert_order 'zinit light Aloxaf/fzf-tab' 'zinit light zsh-users/zsh-autosuggestions' "$PLUGINS_FILE"
    assert_order 'zinit light Aloxaf/fzf-tab' 'zinit light zsh-users/zsh-syntax-highlighting' "$PLUGINS_FILE"
}

# fzf --zsh 会 bindkey '^I' fzf-completion，且 zsh-vi-mode 在首次提示符
# 覆盖先前绑定。必须放到 zvm_after_init，并在其后 enable-fzf-tab 把 Tab
# 抢回给 fzf-tab。env.zsh 只保留 FZF_DEFAULT_OPTS，不再提前 source。
test_fzf_integration_runs_in_zvm_after_init() {
    assert_contains 'function zvm_after_init()' "$PLUGINS_FILE"
    assert_contains 'source <(fzf --zsh)' "$PLUGINS_FILE"
    assert_contains '(( $+functions[enable-fzf-tab] )) && enable-fzf-tab' "$PLUGINS_FILE"
    assert_contains 'fzf_default_completion=expand-or-complete' "$PLUGINS_FILE"
    assert_order 'function zvm_after_init()' 'source <(fzf --zsh)' "$PLUGINS_FILE"
    assert_order 'source <(fzf --zsh)' '(( $+functions[enable-fzf-tab] )) && enable-fzf-tab' "$PLUGINS_FILE"
    assert_order 'fzf_default_completion=expand-or-complete' 'source <(fzf --zsh)' "$PLUGINS_FILE"
    assert_not_contains 'source <(fzf --zsh)' "$ENV_FILE"
}

# fzf 本身不再被 alias；带 preview 的入口是 fzfp，避免污染
# command -v / fzf --zsh / fzf-tab。
test_fzf_preview_alias_is_fzfp_not_fzf() {
    assert_contains 'alias fzfp=' "$ALIASES_FILE"
    assert_not_contains "alias fzf=" "$ALIASES_FILE"
}

# fzf-tab 官方推荐：git checkout 不按字母序、关掉 compsys 菜单、
# cd 补全用 lsd 预览。不要 use-fzf-default-opts。
test_fzf_tab_recommended_zstyles() {
    assert_contains "zstyle ':completion:*:git-checkout:*' sort false" "$PLUGINS_FILE"
    assert_contains "zstyle ':completion:*' menu no" "$PLUGINS_FILE"
    assert_contains "zstyle ':fzf-tab:complete:cd:*' fzf-preview" "$PLUGINS_FILE"
    assert_contains 'lsd -1 --color=always' "$PLUGINS_FILE"
    assert_not_matches "zstyle ':fzf-tab[^']*' use-fzf-default-opts" "$PLUGINS_FILE"
}

# Ctrl-T / Alt-C 在 fd 可用时用它列文件，否则保持 fzf 默认 find。
test_env_wires_fd_for_fzf_widgets() {
    assert_contains 'command -v fd' "$ENV_FILE"
    assert_contains 'FZF_CTRL_T_COMMAND=' "$ENV_FILE"
    assert_contains 'FZF_ALT_C_COMMAND=' "$ENV_FILE"
    assert_contains 'fd --hidden --follow --exclude .git' "$ENV_FILE"
    assert_contains 'fd --type d --hidden --follow --exclude .git' "$ENV_FILE"
}

# setopt correct 会和补全抢注意力；autocd 会把目录名当 cd，误触多。
test_options_does_not_enable_correct_or_autocd() {
    assert_not_contains 'setopt correct' "$OPTIONS_FILE"
    assert_not_contains 'setopt autocd' "$OPTIONS_FILE"
}

test_compinit_skips_compaudit
test_compinit_uses_explicit_dump_path
test_autopair_is_deferred
test_you_should_use_is_deferred
test_critical_plugins_load_immediately
test_p10k_is_removed
test_compinit_order_before_cdreplay
test_fzf_tab_loads_after_compinit_before_widget_wrappers
test_fzf_integration_runs_in_zvm_after_init
test_fzf_preview_alias_is_fzfp_not_fzf
test_fzf_tab_recommended_zstyles
test_env_wires_fd_for_fzf_widgets
test_options_does_not_enable_correct_or_autocd

printf 'PASS: zsh plugins tests\n'
