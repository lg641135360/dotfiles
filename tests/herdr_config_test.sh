#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
HERDR_FILE=$REPO_ROOT/.config/shared/herdr/config.toml
INSTALL_FILE=$REPO_ROOT/install.sh

. "$REPO_ROOT/tests/lib/assert.sh"

# herdr 配置文件存在
test_herdr_config_exists() {
    [ -f "$HERDR_FILE" ] || { echo "FAIL: config.toml not found"; exit 1; }
}

# install.sh 必须包含 herdr config.toml 部署项（shared_configs）
test_install_deploys_herdr_config() {
    assert_contains '.config/shared/herdr/config.toml' "$INSTALL_FILE"
    assert_contains '~/.config/herdr/config.toml' "$INSTALL_FILE"
}

# 主题对齐 Catppuccin（与 tmux/桌面一致）
test_herdr_theme_catppuccin() {
    assert_contains '[theme]' "$HERDR_FILE"
    assert_contains 'name = "catppuccin"' "$HERDR_FILE"
}

# 前缀对齐 tmux 的 ctrl+a
test_herdr_prefix_ctrl_a() {
    assert_contains 'prefix = "ctrl+a"' "$HERDR_FILE"
}

# 默认 shell 与 cwd 策略
test_herdr_terminal_defaults() {
    assert_contains 'default_shell = "zsh"' "$HERDR_FILE"
    assert_contains 'new_cwd = "follow"' "$HERDR_FILE"
}

# vim 风格 pane 移动 h/j/k/l（与 tmux 一致）
test_herdr_vim_pane_navigation() {
    assert_contains 'focus_pane_left = "prefix+h"' "$HERDR_FILE"
    assert_contains 'focus_pane_down = "prefix+j"' "$HERDR_FILE"
    assert_contains 'focus_pane_up = "prefix+k"' "$HERDR_FILE"
    assert_contains 'focus_pane_right = "prefix+l"' "$HERDR_FILE"
}

# 分屏与重载对齐 tmux 键位（| / - / r）
test_herdr_split_and_reload_keys() {
    assert_contains 'split_vertical = "prefix+v"' "$HERDR_FILE"
    assert_contains 'split_horizontal = "prefix+minus"' "$HERDR_FILE"
    assert_contains 'reload_config = "prefix+r"' "$HERDR_FILE"
}

# 状态栏右侧日期时间格式对齐 tmux status-right
test_herdr_tab_bar_right_datetime() {
    assert_contains 'tab_bar_right' "$HERDR_FILE"
    assert_contains 'format = "%m/%d %H:%M"' "$HERDR_FILE"
}

# 通知走系统通知服务（niri + mako），而非 in-app toast
test_herdr_toast_delivery_system() {
    assert_contains 'delivery = "system"' "$HERDR_FILE"
}

test_herdr_config_exists
test_install_deploys_herdr_config
test_herdr_theme_catppuccin
test_herdr_prefix_ctrl_a
test_herdr_terminal_defaults
test_herdr_vim_pane_navigation
test_herdr_split_and_reload_keys
test_herdr_tab_bar_right_datetime
test_herdr_toast_delivery_system

printf 'PASS: herdr config tests\n'