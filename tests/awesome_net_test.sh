#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CONFIG_FILE=$REPO_ROOT/.config/linux/awesome/config.lua
SYSTEM_WIDGETS_FILE=$REPO_ROOT/.config/linux/awesome/widgets/system.lua
WIBAR_FILE=$REPO_ROOT/.config/linux/awesome/ui/wibar.lua

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

test_net_pattern_includes_wlp_interfaces() {
    grep -F 'net_interfaces = "wlan0|eth0|enp|wlp",' "$CONFIG_FILE" >/dev/null 2>&1 ||
        fail "expected net interface pattern to include wlp"
}

test_net_widget_avoids_shell_pipeline_parsing() {
    if grep -F "cat /proc/net/dev | grep -E" "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1; then
        fail "expected NET widget to avoid shell pipeline parsing of /proc/net/dev"
    fi
}

test_net_widget_parses_proc_net_dev_in_lua() {
    grep -F 'local function read_network_totals()' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET widget to expose a Lua parser for /proc/net/dev"
    grep -F 'local dev_file = io.open("/proc/net/dev", "r")' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET widget to read /proc/net/dev directly"
}

test_net_widget_seeds_previous_counters_before_speed_display() {
    grep -F 'if not net_prev.recv or not net_prev.sent then' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET widget to seed previous counters before computing speed"
}


test_net_widget_moves_before_cpu() {
    grep -F 'local system_items = {' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected system_items declaration"
    python - <<'INNERPY' "$SYSTEM_WIDGETS_FILE"
from pathlib import Path
text = Path(__import__('sys').argv[1]).read_text()
start = text.index('local system_items = {')
end = text.index('    if battery_widget then', start)
chunk = text[start:end]
if chunk.index('net_widget') > chunk.index('cpu_widget'):
    raise SystemExit(1)
INNERPY
    [ $? -eq 0 ] || fail "expected net_widget to appear before cpu_widget in system_items"
}

test_metric_markup_uses_colon_separator() {
    grep -F 'label .. ":</span><span foreground=' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected metric markup to use a colon separator"
    if grep -F '"</span><span foreground='"'"' .. value_color .. '"'"'> "' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1; then
        fail "expected metric markup to avoid leading space before values"
    fi
}

test_sysinfo_uses_contextual_labels() {
    grep -F 'render_metric_markup(cpu_label' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected CPU widget to use contextual label"
    grep -F 'local cpu_label = compact and "C" or "CPU"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected full mode to use CPU label"
    grep -F 'render_metric_markup(mem_label' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected MEM widget to use contextual label"
    grep -F 'local mem_label = compact and "M" or "MEM"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected full mode to use MEM label"
    grep -F 'render_metric_markup(battery_label' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected BAT widget to use contextual label"
    grep -F 'local battery_label = compact and "B" or "BAT"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected full mode to use BAT label"
}

test_net_widget_uses_compact_markup() {
    grep -F 'local function render_net_markup(recv_speed, sent_speed)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET widget to expose compact markup renderer"
    grep -F '↓' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET widget to show download arrow"
    grep -F '↑' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET widget to show upload arrow"
    if grep -F '<span foreground='"'"' .. ctpp.teal .. '"'"'>NET</span>' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1; then
        fail "expected NET widget to stop hardcoding the NET text label"
    fi
}

test_net_widget_uses_compact_spacing() {
    grep -F "ctpp.surface1" "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected separators to use subdued surface1 color"
    grep -F 'system_row.spacing = 2' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET/sysinfo row spacing to be compacted to 2"
    grep -F 'left = 4,' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected sysinfo left padding to be compacted to 4"
    grep -F 'right = 4,' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected sysinfo right padding to be compacted to 4"
    grep -F 'spacing = 6,' "$WIBAR_FILE" >/dev/null 2>&1 ||
        fail "expected right side wibar spacing to be compacted to 6"
}

test_net_widget_uses_short_speed_format() {
    grep -F 'return string.format("%.0fK", bytes_per_sec / 1024)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected compact integer K formatting for higher speeds"
    grep -F 'return string.format("%.0fM", bytes_per_sec / 1024 / 1024)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected compact integer M formatting for higher speeds"
}

test_net_widget_has_hover_tooltip() {
    grep -F 'local awful = require("awful")' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET tooltip to use awful.tooltip"
    grep -F 'local net_tooltip_text = "NET: waiting for data"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET tooltip to have an initial waiting state"
    grep -F 'awful.tooltip {' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET widget to create a hover tooltip"
    grep -F 'objects = { net_widget },' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET tooltip to attach to net_widget"
    grep -F 'timer_function = function()' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET tooltip to refresh from current state"
    grep -F 'totals.interface' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET tooltip to expose interface name"
    grep -F 'format_speed(recv_speed) .. "/s"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET tooltip to show download speed units"
    grep -F 'format_speed(sent_speed) .. "/s"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET tooltip to show upload speed units"
}

test_status_widgets_open_detail_panels() {
    grep -F 'local function shell_quote(value)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected status actions to shell-quote terminal commands"
    grep -F 'local function spawn_terminal_shell(command)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected status actions to open terminal panels"
    grep -F 'local system_monitor_unique_id = "awesome-system-monitor"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected system monitor windows to have a stable unique id"
    grep -F 'local function make_system_monitor_command(command)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected system monitor action to build a reusable terminal command"
    grep -F 'local function match_system_monitor_client(c)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected system monitor action to match existing monitor clients"
    grep -F 'local function focus_existing_client(matcher)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected system monitor action to focus an existing monitor window before spawning"
    grep -F 'awful.spawn.raise_or_spawn(' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected system monitor action to raise or spawn a single monitor window"
    grep -F 'system_monitor_unique_id' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected raise_or_spawn to use the system monitor unique id"
    grep -F 'c.single_instance_id == system_monitor_unique_id' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected matcher to recognize Awesome single-instance monitor windows"
    grep -F 'c.class == system_monitor_unique_id' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected matcher to recognize the monitor terminal class"
    grep -F 'window.dynamic_title=false' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected monitor terminal title to stay stable for matching"
    grep -F 'local function open_system_monitor()' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected CPU/MEM widgets to open a system monitor"
    grep -F 'command -v btop >/dev/null 2>&1' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected system monitor action to prefer btop when available"
    grep -F 'command -v htop >/dev/null 2>&1' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected system monitor action to fall back to htop"
    grep -F 'exec top' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected system monitor action to fall back to top"
    grep -F 'local function open_network_status()' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET widget to open a network status panel"
    grep -F 'nmcli device status' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected network panel to show nmcli device status when available"
    grep -F 'ip -brief address' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected network panel to show ip address summary"
    grep -F 'net_widget:buttons(gears.table.join(' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET widget to bind mouse actions"
    grep -F 'cpu_widget:buttons(gears.table.join(' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected CPU widget to bind mouse actions"
    grep -F 'mem_widget:buttons(gears.table.join(' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected MEM widget to bind mouse actions"
}

test_net_pattern_includes_wlp_interfaces
test_net_widget_avoids_shell_pipeline_parsing
test_net_widget_parses_proc_net_dev_in_lua
test_net_widget_seeds_previous_counters_before_speed_display
test_net_widget_moves_before_cpu
test_metric_markup_uses_colon_separator
test_sysinfo_uses_contextual_labels
test_net_widget_uses_compact_markup
test_net_widget_uses_compact_spacing
test_net_widget_uses_short_speed_format
test_net_widget_has_hover_tooltip
test_status_widgets_open_detail_panels

printf 'PASS: awesome net tests\n'
