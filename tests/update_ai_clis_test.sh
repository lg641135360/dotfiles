#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
UPDATER=$REPO_ROOT/.config/scripts/update-ai-clis
INSTALL_FILE=$REPO_ROOT/install.sh

. "$REPO_ROOT/tests/lib/assert.sh"

# update-ai-clis 脚本存在且可执行
test_updater_script_exists() {
    [ -f "$UPDATER" ] || { echo "FAIL: update-ai-clis not found"; exit 1; }
    assert_executable "$UPDATER"
}

# 更新目标为两个 npm 全局 AI CLI
test_updater_targets_both_ai_clis() {
    assert_contains '@anthropic-ai/claude-code' "$UPDATER"
    assert_contains '@openai/codex' "$UPDATER"
    assert_contains 'npm update -g' "$UPDATER"
}

# 提供 --check 只读模式与 --help 用法说明
test_updater_check_and_help() {
    assert_contains '--check' "$UPDATER"
    assert_contains 'npm ls -g' "$UPDATER"
    assert_contains '--help' "$UPDATER"
    assert_contains 'usage' "$UPDATER"
    assert_contains 'case "${1:-}"' "$UPDATER"
}

# 缺失 npm 时给出明确报错，不静默失败
test_updater_requires_npm() {
    assert_contains 'npm not found' "$UPDATER"
    assert_contains 'exit 1' "$UPDATER"
}

# install.sh 部署 update-ai-clis 到 ~/.config/scripts/（shared_configs，条件 npm 存在）
test_install_deploys_updater() {
    assert_contains '.config/scripts/update-ai-clis' "$INSTALL_FILE"
    assert_contains '~/.config/scripts/update-ai-clis' "$INSTALL_FILE"
    assert_contains 'command -v npm' "$INSTALL_FILE"
}

# 未知参数报错（非零退出）且打印用法
test_updater_rejects_unknown_args() {
    set +e
    err=$("$UPDATER" --bogus 2>&1)
    rc=$?
    set -e
    [ "$rc" -ne 0 ] || fail "update-ai-clis --bogus should exit non-zero"
    assert_output_contains 'unknown argument' "$err"
}

test_updater_script_exists
test_updater_targets_both_ai_clis
test_updater_check_and_help
test_updater_requires_npm
test_install_deploys_updater
test_updater_rejects_unknown_args

printf 'PASS: update-ai-clis tests\n'
