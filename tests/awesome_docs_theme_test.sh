#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
README_FILE=$REPO_ROOT/.config/linux/awesome/README.md
THEME_FILE=$REPO_ROOT/.config/linux/awesome/theme/catppuccin.lua
THEME_README_FILE=$REPO_ROOT/.config/linux/awesome/theme/README.md

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_contains() {
    needle=$1
    file=$2

    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        fail "expected '$needle' in $file"
    fi
}

assert_not_contains() {
    needle=$1
    file=$2

    if grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        fail "did not expect '$needle' in $file"
    fi
}

test_theme_exposes_fallback_titlebar_tokens() {
    assert_contains 'theme.titlebar_size = dpi(24)' "$THEME_FILE"
    assert_contains 'theme.titlebar_radius = dpi(8)' "$THEME_FILE"
    assert_contains 'theme.titlebar_spacing = dpi(4)' "$THEME_FILE"
    assert_contains 'theme.titlebar_bg_normal = palette.surface0' "$THEME_FILE"
    assert_contains 'theme.titlebar_bg_focus = palette.surface1' "$THEME_FILE"
    assert_contains 'theme.titlebar_fg_normal = palette.subtext0' "$THEME_FILE"
    assert_contains 'theme.titlebar_fg_focus = palette.text' "$THEME_FILE"
    assert_contains 'theme.titlebar_border_color = palette.overlay0' "$THEME_FILE"
    assert_contains 'theme.titlebar_border_color_focus = palette.surface2' "$THEME_FILE"
    assert_contains 'theme.titlebar_font = "Maple Mono NF CN 10.5"' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_font = "Maple Mono NF CN 10.5"' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_radius = dpi(5)' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_bg_normal = palette.mantle' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_bg_active = palette.surface0' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_bg_close = palette.mantle' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_fg_normal = palette.subtext0' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_fg_active = palette.blue' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_fg_close = palette.red' "$THEME_FILE"
    assert_contains 'theme.menu_bg_normal = palette.mantle' "$THEME_FILE"
    assert_contains 'theme.menu_bg_focus = palette.surface0' "$THEME_FILE"
    assert_contains 'theme.menu_border_color = palette.overlay0' "$THEME_FILE"
    assert_contains 'theme.tooltip_bg = palette.mantle' "$THEME_FILE"
    assert_contains 'theme.tooltip_border_color = palette.overlay0' "$THEME_FILE"
    assert_contains '回退标题栏' "$THEME_README_FILE"
    assert_contains 'titlebar_bg_*' "$THEME_README_FILE"
    assert_contains 'titlebar_button_*' "$THEME_README_FILE"
}

test_removed_dependencies_stay_gone() {
    # 已移除的依赖/配置不应在 README 或主题文档中复活。
    assert_not_contains 'git clone https://github.com/lcpz/lain.git' "$README_FILE"
    assert_not_contains 'picom-catppuccin.conf' "$THEME_README_FILE"
    assert_not_contains '取消注释 blur 部分' "$THEME_README_FILE"
}

test_theme_exposes_fallback_titlebar_tokens
test_removed_dependencies_stay_gone

printf 'PASS: awesome theme tests\n'
