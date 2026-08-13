#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PLUGINS_FILE=$REPO_ROOT/.config/shared/zsh/plugins.zsh

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
}

# p10k 已弃用（gitstatus 二进制在 aarch64 版本不匹配导致初始化失败，拖慢
# 提示符渲染）。改用 starship（单一 Rust 二进制，无版本依赖问题）。
# plugins.zsh 不应再引用 powerlevel10k。
test_p10k_is_removed() {
    assert_not_contains 'powerlevel10k' "$PLUGINS_FILE"
    assert_not_contains 'p10k' "$PLUGINS_FILE"
}

# compinit 必须在所有 zinit light/snippet 之后、cdreplay 之前。
test_compinit_order_before_cdreplay() {
    assert_order 'zinit light zsh-users/zsh-autosuggestions' 'compinit -u' "$PLUGINS_FILE"
    assert_order 'zinit snippet OMZP::command-not-found' 'compinit -u' "$PLUGINS_FILE"
    assert_order 'compinit -u' 'zinit cdreplay -q' "$PLUGINS_FILE"
}

test_compinit_skips_compaudit
test_compinit_uses_explicit_dump_path
test_autopair_is_deferred
test_you_should_use_is_deferred
test_critical_plugins_load_immediately
test_p10k_is_removed
test_compinit_order_before_cdreplay

printf 'PASS: zsh plugins tests\n'
