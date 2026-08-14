#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"
CONFIG_FILE=$REPO_ROOT/.config/linux/awesome/config.lua
MENU_FILE=$REPO_ROOT/.config/linux/awesome/menu.lua

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
