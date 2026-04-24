#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
WIBAR_FILE=$REPO_ROOT/.config/linux/awesome/ui/wibar.lua
THEME_FILE=$REPO_ROOT/.config/linux/awesome/theme/catppuccin.lua

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

test_theme_does_not_force_builtin_wallpaper() {
    assert_not_contains 'theme.wallpaper = function(s)' "$THEME_FILE"
    assert_not_contains 'return palette.crust' "$THEME_FILE"
}

test_wibar_does_not_override_external_wallpaper() {
    assert_not_contains 'local function set_wallpaper(screen)' "$WIBAR_FILE"
    assert_not_contains 'gears.wallpaper.maximized' "$WIBAR_FILE"
    assert_not_contains 'screen.connect_signal("property::geometry", set_wallpaper)' "$WIBAR_FILE"
    assert_not_contains 'set_wallpaper(s)' "$WIBAR_FILE"
}

test_theme_does_not_force_builtin_wallpaper
test_wibar_does_not_override_external_wallpaper

printf 'PASS: awesome wallpaper tests\n'
