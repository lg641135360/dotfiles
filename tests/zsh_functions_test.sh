#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
FUNCTIONS_FILE=$REPO_ROOT/.config/shared/zsh/functions.zsh
INTEGRATIONS_FILE=$REPO_ROOT/.config/shared/zsh/integrations.zsh

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

# zoxide --cmd cd 的默认补全只对当前目录跑 _cd -/；本地无匹配时
# 直接成功返回，Tab 看起来像没反应。必须包装官方函数：本地无匹配
# 才 query --list，其余分支走 orig，不要整函数复制、不要再 compdef。
test_zoxide_cd_tab_wraps_official_complete() {
    assert_contains 'eval "$(zoxide init --cmd cd zsh)"' "$INTEGRATIONS_FILE"
    assert_contains 'functions[_zoxide_z_complete_orig]=$functions[__zoxide_z_complete]' "$INTEGRATIONS_FILE"
    assert_contains 'function __zoxide_z_complete()' "$INTEGRATIONS_FILE"
    assert_contains '_cd -/' "$INTEGRATIONS_FILE"
    assert_contains '(( compstate[nmatches] > 0 )) && return 0' "$INTEGRATIONS_FILE"
    assert_contains 'query --exclude' "$INTEGRATIONS_FILE"
    assert_contains '--list --' "$INTEGRATIONS_FILE"
    assert_contains 'compadd -U -Q -f -S / --' "$INTEGRATIONS_FILE"
    assert_contains '_zoxide_z_complete_orig' "$INTEGRATIONS_FILE"
    assert_not_contains 'compdef __zoxide_z_complete cd' "$INTEGRATIONS_FILE"
    assert_not_contains '__zoxide_z_complete_helper' "$INTEGRATIONS_FILE"
    assert_order 'eval "$(zoxide init --cmd cd zsh)"' 'functions[_zoxide_z_complete_orig]=$functions[__zoxide_z_complete]' "$INTEGRATIONS_FILE"
    assert_order 'functions[_zoxide_z_complete_orig]=$functions[__zoxide_z_complete]' 'function __zoxide_z_complete()' "$INTEGRATIONS_FILE"
    assert_order '_cd -/' '--list --' "$INTEGRATIONS_FILE"
}

test_cpp_prefers_rsync_without_strace_fallback
test_zoxide_cd_tab_wraps_official_complete

printf 'PASS: zsh functions tests\n'
