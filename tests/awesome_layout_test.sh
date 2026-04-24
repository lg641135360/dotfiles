#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CLIENT_FILE=$REPO_ROOT/.config/linux/awesome/client.lua
BINDINGS_FILE=$REPO_ROOT/.config/linux/awesome/bindings.lua
RC_FILE=$REPO_ROOT/.config/linux/awesome/rc.lua

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

test_default_layout_is_tile_left() {
    assert_contains 'awful.layout.suit.tile.left,' "$RC_FILE"
}

test_layout_keys_still_adjust_master_width_factor() {
    assert_contains 'awful.tag.incmwfact(0.05)' "$BINDINGS_FILE"
    assert_contains 'awful.tag.incmwfact(-0.05)' "$BINDINGS_FILE"
}

test_client_rules_ignore_size_hints_for_tiling() {
    assert_contains 'size_hints_honor = false,' "$CLIENT_FILE"
}

test_no_dingtalk_specific_layout_hook() {
    assert_not_contains 'maybe_reset_master_width_for_dingtalk' "$CLIENT_FILE"
    assert_not_contains 'com.alibabainc.dingtalk' "$CLIENT_FILE"
}

test_default_layout_is_tile_left
test_layout_keys_still_adjust_master_width_factor
test_client_rules_ignore_size_hints_for_tiling
test_no_dingtalk_specific_layout_hook

printf 'PASS: awesome layout tests\n'
