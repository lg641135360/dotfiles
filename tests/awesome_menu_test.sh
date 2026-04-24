#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CONFIG_FILE=$REPO_ROOT/.config/linux/awesome/config.lua
MENU_FILE=$REPO_ROOT/.config/linux/awesome/menu.lua

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

test_menu_style_defaults_to_auto_detection() {
    assert_contains 'menu_style = "auto",' "$CONFIG_FILE"
    assert_not_contains 'platform.distro == "ubuntu"' "$CONFIG_FILE"
}

test_menu_uses_safe_module_fallbacks() {
    assert_contains 'local has_fdo, freedesktop = pcall(require, "freedesktop")' "$MENU_FILE"
    assert_contains 'local has_debian, debian_menu = pcall(require, "debian.menu")' "$MENU_FILE"
    assert_contains 'if config.menu_style == "basic" then' "$MENU_FILE"
    assert_contains 'debian_menu.Debian_menu.Debian' "$MENU_FILE"
    assert_not_contains 'require("debian.menu").Debian_menu.Debian' "$MENU_FILE"
}

test_menu_style_defaults_to_auto_detection
test_menu_uses_safe_module_fallbacks

printf 'PASS: awesome menu tests\n'
