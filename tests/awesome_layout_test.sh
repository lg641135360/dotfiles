#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CLIENT_FILE=$REPO_ROOT/.config/linux/awesome/client.lua
BINDINGS_FILE=$REPO_ROOT/.config/linux/awesome/bindings.lua
RC_FILE=$REPO_ROOT/.config/linux/awesome/rc.lua
README_FILE=$REPO_ROOT/.config/linux/awesome/README.md

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

test_no_legacy_dta_auto_float_rule() {
    assert_not_contains '"DTA",' "$CLIENT_FILE"
}

test_dingtalk_tlive_utility_helpers_are_not_tasklist_clients() {
    assert_contains 'rule = { class = "tblive", type = "utility" }' "$CLIENT_FILE"
    assert_contains 'skip_taskbar = true,' "$CLIENT_FILE"
    assert_contains 'floating = true,' "$CLIENT_FILE"
    assert_not_contains 'rule = { class = "tblive" }' "$CLIENT_FILE"
}

test_clients_use_rounded_shape_except_fullscreen_or_maximized() {
    assert_contains 'local function apply_client_shape(c)' "$CLIENT_FILE"
    assert_contains 'c.fullscreen or c.maximized or c.maximized_horizontal or c.maximized_vertical' "$CLIENT_FILE"
    assert_contains 'c.shape = gears.shape.rectangle' "$CLIENT_FILE"
    assert_contains 'gears.shape.rounded_rect(cr, w, h, beautiful.border_radius or 0)' "$CLIENT_FILE"
    assert_contains 'client.connect_signal("property::fullscreen", apply_client_shape)' "$CLIENT_FILE"
    assert_contains 'client.connect_signal("property::maximized", apply_client_shape)' "$CLIENT_FILE"
    assert_contains 'client.connect_signal("property::maximized_horizontal", apply_client_shape)' "$CLIENT_FILE"
    assert_contains 'client.connect_signal("property::maximized_vertical", apply_client_shape)' "$CLIENT_FILE"
    assert_contains '普通/对话框等 managed 窗口使用 `theme.border_radius` 圆角' "$README_FILE"
    assert_contains '全屏或最大化窗口会自动退回矩形' "$README_FILE"
}

test_default_layout_is_tile_left
test_layout_keys_still_adjust_master_width_factor
test_client_rules_ignore_size_hints_for_tiling
test_no_dingtalk_specific_layout_hook
test_no_legacy_dta_auto_float_rule
test_dingtalk_tlive_utility_helpers_are_not_tasklist_clients
test_clients_use_rounded_shape_except_fullscreen_or_maximized

printf 'PASS: awesome layout tests\n'
