#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
FUNCTIONS_FILE=$REPO_ROOT/.config/shared/zsh/functions.zsh

. "$REPO_ROOT/tests/lib/assert.sh"

# cpp() 应优先使用 rsync 显示进度；rsync 不可用时回退到 cp -v，
# 不应保留依赖 strace 的旧 fallback（strace 通常未安装，且其进度条
# 逻辑依赖 write 调用计数，基本无法工作，set -e 还会污染调用者 shell）。
test_cpp_prefers_rsync_without_strace_fallback() {
    assert_contains 'rsync -ah --info=progress2' "$FUNCTIONS_FILE"
    assert_contains 'cp -v' "$FUNCTIONS_FILE"
    assert_not_contains 'strace' "$FUNCTIONS_FILE"
    assert_not_contains 'set -e' "$FUNCTIONS_FILE"
}

test_cpp_prefers_rsync_without_strace_fallback

printf 'PASS: zsh functions tests\n'
