#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
FLOAT_TREM_FILE=$REPO_ROOT/.config/shared/nvim/lua/customs/float_trem.lua

. "$REPO_ROOT/tests/lib/assert.sh"

# 浮窗终端应使用 vim.o.shell 跟随用户登录 shell，不应硬编码 zsh，
# 以便在 macOS（fish/其它 shell）或非 zsh 环境下正常工作。
test_float_trem_uses_shell_option_not_hardcoded_zsh() {
    assert_contains 'vim.o.shell' "$FLOAT_TREM_FILE"
    assert_not_contains '"zsh", "-i"' "$FLOAT_TREM_FILE"
}

test_float_trem_uses_shell_option_not_hardcoded_zsh

printf 'PASS: nvim float_trem tests\n'
