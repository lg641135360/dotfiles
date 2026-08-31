#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

SWAYLOCK_CONFIG=$REPO_ROOT/.config/linux/swaylock/config
SWAYLOCK_README=$REPO_ROOT/.config/linux/swaylock/README.md

# swaylock 1.8 (apt) 支持配置文件，格式 long-option=value。本测试锁定
# Catppuccin Mocha 解锁环配色契约，防止配色被意外改乱或引入无效键。
test_swaylock_config_matches_mocha_contract() {
    assert_file_exists "$SWAYLOCK_CONFIG"

    # 默认态：blue（与 niri focus-ring active-color #89b4fa 对齐）
    assert_contains 'ring-color=#89b4fa' "$SWAYLOCK_CONFIG"
    assert_contains 'inside-color=#1e1e2e80' "$SWAYLOCK_CONFIG"
    assert_contains 'line-color=#1e1e2e' "$SWAYLOCK_CONFIG"

    # 验证中：green
    assert_contains 'ring-ver-color=#a6e3a1' "$SWAYLOCK_CONFIG"
    assert_contains 'line-ver-color=#a6e3a1' "$SWAYLOCK_CONFIG"

    # 密码错误：red
    assert_contains 'ring-wrong-color=#f38ba8' "$SWAYLOCK_CONFIG"
    assert_contains 'line-wrong-color=#f38ba8' "$SWAYLOCK_CONFIG"

    # 按键/退格高亮
    assert_contains 'key-hl-color=#f9e2af' "$SWAYLOCK_CONFIG"
    assert_contains 'bs-hl-color=#f38ba8' "$SWAYLOCK_CONFIG"

    # 解锁环尺寸与字体
    assert_contains 'indicator-radius=80' "$SWAYLOCK_CONFIG"
    assert_contains 'indicator-thickness=8' "$SWAYLOCK_CONFIG"
    assert_contains 'font=Maple Mono NF CN' "$SWAYLOCK_CONFIG"
}

# swaylock 配置文件只接受 long-option=value 行与注释行；lock-wayland 的壁纸
# 逻辑仍在命令行（-i/-s/-c），配置文件不得混入 background/image/color 命令，
# 避免与脚本重复管理背景。
test_swaylock_config_keeps_background_in_script() {
    assert_not_contains '^color=' "$SWAYLOCK_CONFIG"
    assert_not_contains '^image=' "$SWAYLOCK_CONFIG"
    assert_not_contains '^scaling=' "$SWAYLOCK_CONFIG"
}

# README 必须存在并说明 swaylock-effects 移除后的能力边界（无 --effect-blur）。
test_swaylock_readme_documents_effects_boundary() {
    assert_file_exists "$SWAYLOCK_README"
    assert_contains 'effect-blur' "$SWAYLOCK_README"
    assert_contains 'swaylock-effects' "$SWAYLOCK_README"
}

test_swaylock_config_matches_mocha_contract
test_swaylock_config_keeps_background_in_script
test_swaylock_readme_documents_effects_boundary

printf 'PASS: swaylock config tests\n'
