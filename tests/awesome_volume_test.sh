#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VOLUME_FILE=$REPO_ROOT/.config/linux/awesome/widgets/volume.lua

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

test_volume_widget_queries_mute_state() {
    assert_contains 'pactl get-sink-mute @DEFAULT_SINK@' "$VOLUME_FILE"
}

test_volume_widget_refreshes_periodically() {
    assert_contains 'timeout = 2,' "$VOLUME_FILE"
    assert_contains 'callback = update_volume,' "$VOLUME_FILE"
}

test_volume_widget_renders_muted_state_explicitly() {
    assert_contains 'MUTE' "$VOLUME_FILE"
}

test_volume_widget_handles_invalid_output_gracefully() {
    assert_contains 'local function parse_volume_percent(output)' "$VOLUME_FILE"
    assert_contains 'local function parse_mute_state(output)' "$VOLUME_FILE"
    assert_contains 'local function render_unavailable_markup()' "$VOLUME_FILE"
    assert_contains 'N/A' "$VOLUME_FILE"
    assert_contains '2>/dev/null || true' "$VOLUME_FILE"
    assert_contains 'if not volume and muted == nil then' "$VOLUME_FILE"
}

test_volume_widget_uses_tight_value_spacing() {
    assert_contains '>N/A</span>' "$VOLUME_FILE"
    assert_contains '>MUTE</span>' "$VOLUME_FILE"
    assert_contains '.. volume .. "%</span>"' "$VOLUME_FILE"
}

test_volume_widget_handles_write_failures_gracefully() {
    assert_contains 'local function run_volume_action(command)' "$VOLUME_FILE"
    assert_contains 'awful.spawn.easy_async_with_shell(command .. " >/dev/null 2>&1",' "$VOLUME_FILE"
    assert_contains 'if exit_code ~= 0 then' "$VOLUME_FILE"
    assert_contains 'vol_widget:set_markup(render_unavailable_markup())' "$VOLUME_FILE"
    assert_contains 'run_volume_action("pactl set-sink-volume @DEFAULT_SINK@ +5%")' "$VOLUME_FILE"
    assert_contains 'run_volume_action("pactl set-sink-volume @DEFAULT_SINK@ -5%")' "$VOLUME_FILE"
    assert_contains 'run_volume_action("pactl set-sink-mute @DEFAULT_SINK@ toggle")' "$VOLUME_FILE"
}

test_volume_widget_queries_mute_state
test_volume_widget_refreshes_periodically
test_volume_widget_renders_muted_state_explicitly
test_volume_widget_handles_invalid_output_gracefully
test_volume_widget_uses_tight_value_spacing
test_volume_widget_handles_write_failures_gracefully

printf 'PASS: awesome volume tests\n'
