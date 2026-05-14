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
    assert_contains 'local function stop_timer(timer)' "$VOLUME_FILE"
    assert_contains 'local refresh_timer = gears.timer {' "$VOLUME_FILE"
    assert_contains 'timeout = 2,' "$VOLUME_FILE"
    assert_contains 'callback = update_volume,' "$VOLUME_FILE"
    assert_contains 'local function dispose()' "$VOLUME_FILE"
    assert_contains 'stop_timer(refresh_timer)' "$VOLUME_FILE"
    assert_contains 'dispose = dispose,' "$VOLUME_FILE"
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
    assert_contains 'local compact = options and options.compact' "$VOLUME_FILE"
    assert_contains 'local volume_label = compact and "V" or "VOL"' "$VOLUME_FILE"
    assert_contains 'volume_label .. ":</span>' "$VOLUME_FILE"
    assert_contains '>N/A</span>' "$VOLUME_FILE"
    assert_contains ">MUTE</span>" "$VOLUME_FILE"
    assert_contains '.. volume .. "%</span>"' "$VOLUME_FILE"
}

test_volume_widget_handles_write_failures_gracefully() {
    assert_contains 'local function run_volume_action(command, on_success)' "$VOLUME_FILE"
    assert_contains 'awful.spawn.easy_async_with_shell(command .. " >/dev/null 2>&1",' "$VOLUME_FILE"
    assert_contains 'if exit_code ~= 0 then' "$VOLUME_FILE"
    assert_contains 'vol_widget:set_markup(render_unavailable_markup())' "$VOLUME_FILE"
    assert_contains 'run_volume_action("pactl set-sink-volume @DEFAULT_SINK@ +5%")' "$VOLUME_FILE"
    assert_contains 'run_volume_action("pactl set-sink-volume @DEFAULT_SINK@ -5%")' "$VOLUME_FILE"
    assert_contains 'run_volume_action("pactl set-sink-mute @DEFAULT_SINK@ toggle", apply_optimistic_mute_toggle)' "$VOLUME_FILE"
}

test_volume_widget_reads_state_with_stable_locale() {
    assert_contains 'LC_ALL=C; export LC_ALL' "$VOLUME_FILE"
    assert_contains 'pactl get-sink-volume @DEFAULT_SINK@' "$VOLUME_FILE"
    assert_contains 'pactl get-sink-mute @DEFAULT_SINK@' "$VOLUME_FILE"
}

test_volume_widget_shows_mute_immediately_after_click() {
    assert_contains 'local last_volume' "$VOLUME_FILE"
    assert_contains 'local last_muted' "$VOLUME_FILE"
    assert_contains 'local function remember_volume_state(volume, muted)' "$VOLUME_FILE"
    assert_contains 'local function apply_optimistic_mute_toggle()' "$VOLUME_FILE"
    assert_contains 'local refresh_delays = { 0.15, 0.5, 1.2 }' "$VOLUME_FILE"
    assert_contains 'run_volume_action("pactl set-sink-mute @DEFAULT_SINK@ toggle", apply_optimistic_mute_toggle)' "$VOLUME_FILE"
}

test_volume_widget_opens_pavucontrol_on_right_click() {
    assert_contains 'local function open_volume_control()' "$VOLUME_FILE"
    assert_contains 'command -v pavucontrol >/dev/null 2>&1 && pavucontrol' "$VOLUME_FILE"
    assert_contains 'awful.button({ }, 3, open_volume_control)' "$VOLUME_FILE"
}

test_volume_widget_has_hover_usage_hint() {
    assert_contains 'local volume_tooltip_status = volume_label .. ": N/A"' "$VOLUME_FILE"
    assert_contains 'local function set_volume_tooltip_status(volume, muted)' "$VOLUME_FILE"
    assert_contains 'awful.tooltip {' "$VOLUME_FILE"
    assert_contains 'objects = { vol_widget },' "$VOLUME_FILE"
    assert_contains 'timer_function = function()' "$VOLUME_FILE"
    assert_contains 'volume_tooltip_status' "$VOLUME_FILE"
    assert_contains '"音量\n状态：" .. volume_tooltip_status' "$VOLUME_FILE"
    assert_contains '左键：切换静音' "$VOLUME_FILE"
    assert_contains '右键：打开控制面板' "$VOLUME_FILE"
    assert_contains '滚轮：调整音量' "$VOLUME_FILE"
    assert_contains 'volume_tooltip_status = volume_label .. ": MUTE"' "$VOLUME_FILE"
    assert_contains 'set_volume_tooltip_status(volume, muted)' "$VOLUME_FILE"
    assert_contains 'set_volume_tooltip_status(nil, nil)' "$VOLUME_FILE"
}

test_volume_widget_queries_mute_state
test_volume_widget_refreshes_periodically
test_volume_widget_renders_muted_state_explicitly
test_volume_widget_handles_invalid_output_gracefully
test_volume_widget_uses_tight_value_spacing
test_volume_widget_handles_write_failures_gracefully
test_volume_widget_reads_state_with_stable_locale
test_volume_widget_shows_mute_immediately_after_click
test_volume_widget_opens_pavucontrol_on_right_click
test_volume_widget_has_hover_usage_hint

printf 'PASS: awesome volume tests\n'
