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
# 应在 history.zsh 末尾，且 .zshrc 不再 source keybindings.zsh。
test_keybindings_merged_into_history() {
    assert_contains 'history-beginning-search-backward' "$HISTORY_FILE"
    assert_contains 'history-beginning-search-forward' "$HISTORY_FILE"
    assert_not_contains 'keybindings.zsh' "$ZSHRC_FILE"
}

test_histfile_follows_zdotdir
test_keybindings_merged_into_history

printf 'PASS: zsh history tests\n'
