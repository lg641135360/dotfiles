#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
HISTORY_FILE=$REPO_ROOT/.config/shared/zsh/history.zsh
ZSHRC_FILE=$REPO_ROOT/.config/shared/zsh/.zshrc

. "$REPO_ROOT/tests/lib/assert.sh"

# HISTFILE 应跟随 ZDOTDIR，集中所有 zsh 状态文件到 ~/.config/zsh/，
# 而不是散落在 ~ 下。旧 live 环境的 ~/.zsh_history 需手动迁移。
test_histfile_follows_zdotdir() {
    assert_contains 'HISTFILE=$ZDOTDIR/.zsh_history' "$HISTORY_FILE"
    assert_not_contains 'HISTFILE=~/.zsh_history' "$HISTORY_FILE"
}

# 旧 keybindings.zsh 已合并到 history.zsh，arrow-key history search bindkey
# 应在 history.zsh 末尾，且仓库不再保留该文件、.zshrc 也不再 source。
test_keybindings_merged_into_history() {
    assert_contains 'history-beginning-search-backward' "$HISTORY_FILE"
    assert_contains 'history-beginning-search-forward' "$HISTORY_FILE"
    assert_not_contains 'keybindings.zsh' "$ZSHRC_FILE"
    ZSH_DIR=$(dirname "$HISTORY_FILE")
    if [ -e "$ZSH_DIR/keybindings.zsh" ]; then
        echo "FAIL: leftover $ZSH_DIR/keybindings.zsh" >&2
        exit 1
    fi
}

# HISTDUP 不是 zsh 变量（tcsh histdup 的残留写法），zsh 直接忽略该赋值，
# 属于死代码。去重已由 hist_ignore_all_dups / hist_save_no_dups /
# hist_find_no_dups 覆盖。只匹配非注释行，允许注释里解释这段历史。
test_no_dead_histdup_variable() {
    assert_not_matches '^[^#]*HISTDUP=' "$HISTORY_FILE"
}

# HISTSIZE 从 10000 提到 50000：内存代价可忽略，历史回溯范围更实用。
# SAVEHIST 跟随 HISTSIZE。
test_histsize_is_50000() {
    assert_contains 'HISTSIZE=50000' "$HISTORY_FILE"
    assert_contains 'SAVEHIST=$HISTSIZE' "$HISTORY_FILE"
}

test_histfile_follows_zdotdir
test_keybindings_merged_into_history
test_no_dead_histdup_variable
test_histsize_is_50000

printf 'PASS: zsh history tests\n'
