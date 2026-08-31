#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

GTKLOCK_DIR=$REPO_ROOT/.config/linux/gtklock
GTKLOCK_CONFIG=$GTKLOCK_DIR/config.ini
GTKLOCK_STYLE=$GTKLOCK_DIR/style.css
GTKLOCK_README=$GTKLOCK_DIR/README.md

# gtklock 4.0 配置契约：config.ini 是 glib key file（[main] 组 + name=value），
# 时间/日期用 date(1) 格式。本测试锁定时间格式与 Mocha 主题关键色。
test_gtklock_config_matches_contract() {
    assert_file_exists "$GTKLOCK_CONFIG"
    assert_file_exists "$GTKLOCK_STYLE"

    # config.ini 必须是 glib key file：[main] 段 + 选项，不能混入注释不当格式。
    assert_contains '[main]' "$GTKLOCK_CONFIG"
    assert_contains 'time-format=' "$GTKLOCK_CONFIG"
    assert_contains 'date-format=' "$GTKLOCK_CONFIG"

    # 时间/日期用 date(1) 的 %H:%M / 中文星期+日期格式。
    assert_contains 'time-format=%H:%M' "$GTKLOCK_CONFIG"
    assert_contains 'date-format=%A %m月%d日' "$GTKLOCK_CONFIG"

    # Mocha 主题关键色（与 swaylock/mako/fuzzel 配色对齐）。
    assert_contains 'background-color: #11111b' "$GTKLOCK_STYLE"
    assert_contains 'color: #cdd6f4' "$GTKLOCK_STYLE"
    assert_contains 'border: 2px solid #89b4fa' "$GTKLOCK_STYLE"

    # 目标 widget 名必须与 gtklock 默认 UI 一致。
    assert_contains '#clock-label' "$GTKLOCK_STYLE"
    assert_contains '#input-field' "$GTKLOCK_STYLE"
    assert_contains '#warning-label' "$GTKLOCK_STYLE"
    assert_contains '#error-label' "$GTKLOCK_STYLE"
    assert_contains '#unlock-button' "$GTKLOCK_STYLE"
}

# config.ini 不得含 style=/background= 这类路径键：背景与样式路径都由
# lock-wayland 命令行（--style/--background）传入，避免部署后相对路径漂移。
test_gtklock_config_keeps_paths_in_script() {
    assert_not_contains '^style=' "$GTKLOCK_CONFIG"
    assert_not_contains '^background=' "$GTKLOCK_CONFIG"
}

# README 必须存在并说明协议/PAM/时钟能力。
test_gtklock_readme_documents_capabilities() {
    assert_file_exists "$GTKLOCK_README"
    assert_contains 'ext-session-lock-v1' "$GTKLOCK_README"
    assert_contains 'pam.d/gtklock' "$GTKLOCK_README"
    assert_contains 'time-format' "$GTKLOCK_README"
    assert_contains 'swaylock' "$GTKLOCK_README"
}

test_gtklock_config_matches_contract
test_gtklock_config_keeps_paths_in_script
test_gtklock_readme_documents_capabilities

printf 'PASS: gtklock config tests\n'
