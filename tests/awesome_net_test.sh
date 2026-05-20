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


test_system_widgets_parse_cpu_and_memory_without_lain() {
    if grep -F 'require("lain")' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1; then
        fail "expected system widgets to avoid the lain runtime dependency"
    fi

    lua - "$SYSTEM_WIDGETS_FILE" <<'LUA' || fail "expected native CPU/MEM parser helpers to behave correctly"
local system_file = arg[1]
package.path = system_file:gsub("/widgets/system%.lua$", "/?.lua") .. ";" .. package.path

package.preload["awful"] = function()
    return { spawn = { easy_async_with_shell = function() end } }
end
package.preload["gears"] = function()
    return { timer = function() end }
end
package.preload["wibox"] = function()
    return {}
end
package.preload["beautiful"] = function()
    return { ctpp = {} }
end
package.preload["beautiful.xresources"] = function()
    return { apply_dpi = function(value) return value end }
end

local system = assert(loadfile(system_file))()
local private = assert(system._private)
local first = assert(private.parse_proc_stat_line("cpu  100 0 50 850 0 0 0 0 0 0"))
local second = assert(private.parse_proc_stat_line("cpu  150 0 100 900 0 0 0 0 0 0"))
assert(first.total == 1000)
assert(first.idle == 850)
assert(private.calculate_cpu_usage(first, second) == 67)

	local mem = assert(private.parse_meminfo([[MemTotal:       1000 kB
MemFree:         100 kB
MemAvailable:    250 kB
Buffers:          50 kB
Cached:          150 kB
]]))
	assert(private.calculate_mem_usage(mem) == 75)
	assert(private.interface_matches("wlp1s0", "wlan0|eth0|enp|wlp"))
	assert(private.parse_default_route_interface([[Iface Destination Gateway Flags RefCnt Use Metric Mask MTU Window IRTT
eth0 00000000 0101A8C0 0003 0 0 0 00000000 0 0 0
wlp1s0 0008FEA9 00000000 0001 0 0 0 00FFFFFF 0 0 0
]], "wlan0|eth0|enp|wlp") == "eth0")
	local entries = private.parse_network_totals([[Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
eth0: 100 0 0 0 0 0 0 0 200 0 0 0 0 0 0 0
wlp1s0: 300 0 0 0 0 0 0 0 400 0 0 0 0 0 0 0
]], "wlan0|eth0|enp|wlp")
	assert(#entries == 2)
	assert(private.choose_network_totals(entries, "wlp1s0").interface == "wlp1s0")
	assert(private.choose_network_totals(entries, "missing0").interface == "eth0")
	assert(private.format_speed(1536) == "1.5K")
LUA
}

test_net_widget_avoids_shell_pipeline_parsing() {
    if grep -F "cat /proc/net/dev | grep -E" "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1; then
        fail "expected NET widget to avoid shell pipeline parsing of /proc/net/dev"
    fi
}

test_net_widget_parses_proc_net_dev_in_lua() {
    grep -F 'local function parse_default_route_interface(content, patterns)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET widget to parse /proc/net/route for a preferred interface"
    grep -F 'return parse_default_route_interface(read_file_all("/proc/net/route"), patterns)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET widget to read /proc/net/route directly"
    grep -F 'local function parse_network_totals(content, patterns)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET widget to parse all matching interfaces before choosing one"
    grep -F 'local function choose_network_totals(entries, preferred_interface)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET widget to select the preferred interface when available"
    grep -F 'local function read_network_totals(patterns)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET widget to expose a Lua parser for /proc/net/dev"
    grep -F 'local content = read_file_all("/proc/net/dev")' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET widget to read /proc/net/dev directly"
    grep -F 'return choose_network_totals(entries, read_default_route_interface(patterns))' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET widget to prefer the default-route interface"
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
    grep -F 'left = 2,' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected sysinfo left padding to be compacted to 2"
    grep -F 'right = 2,' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected sysinfo right padding to be compacted to 2"
    grep -F 'top = 2,' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected sysinfo top padding to be compacted to 2"
    grep -F 'bottom = 2,' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected sysinfo bottom padding to be compacted to 2"
    grep -F 'spacing = compact and 2 or 4,' "$WIBAR_FILE" >/dev/null 2>&1 ||
        fail "expected right side wibar spacing to adapt between tighter compact and full layouts"
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
    grep -F 'local net_tooltip_text = "网络\n状态：离线\n接口：未匹配"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET tooltip to have an explicit offline state"
    grep -F 'awful.tooltip {' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET widget to create a hover tooltip"
    grep -F 'objects = { net_widget },' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET tooltip to attach to net_widget"
    grep -F 'timer_function = function()' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET tooltip to refresh from current state"
    grep -F 'totals.interface' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET tooltip to expose interface name"
    grep -F '"\n下载：" .. format_speed(recv_speed) .. "/s"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET tooltip to show download speed units"
    grep -F '"\n上传：" .. format_speed(sent_speed) .. "/s"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET tooltip to show upload speed units"
    grep -F 'local function render_net_offline_markup()' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET widget to render an explicit offline state"
    grep -F 'NET:N/A' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET offline markup to show N/A"
    grep -F 'local function set_net_offline()' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET widget to reset stale rates when no interface is available"
    grep -F 'net_prev.recv = nil' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET offline state to clear previous download counters"
    grep -F 'net_prev.sent = nil' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected NET offline state to clear previous upload counters"
    python - "$SYSTEM_WIDGETS_FILE" <<'PY' || fail "expected NET update loop to switch to offline when totals are unavailable"
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text()
start = text.index("local function update_net()")
end = text.index("\n    update_net()", start)
chunk = text[start:end]

assert "if not totals then" in chunk
assert "set_net_offline()" in chunk
PY
}

test_battery_widget_has_hover_details() {
    grep -F 'local battery_tooltip_text = battery_label .. "\n状态：读取中"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected BAT tooltip to have a loading state"
    grep -F 'local function translate_battery_status(status)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected BAT tooltip to translate battery status"
    grep -F 'local function read_battery_number(path)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected BAT tooltip to read numeric power_supply attributes"
    grep -F 'local function format_watts(microwatts)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected BAT tooltip to format power draw"
    grep -F 'local function format_duration(hours)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected BAT tooltip to format remaining time"
    grep -F 'local function update_battery_tooltip(summary)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected BAT tooltip to render detailed text"
    grep -F 'local battery_paths = find_battery_paths()' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected BAT tooltip updates to work from aggregated battery paths"
    grep -F 'objects = { battery_widget },' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected BAT tooltip to attach to battery_widget"
    grep -F 'return battery_tooltip_text' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected BAT tooltip to read cached text"
    grep -F 'summary.count > 1' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected BAT tooltip to mention multi-battery aggregation when needed"
    grep -F '状态：' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected BAT tooltip to show status"
    grep -F '电量：' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected BAT tooltip to show capacity"
    grep -F '功率：' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected BAT tooltip to show power when available"
    grep -F 'duration_label = "剩余"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected BAT tooltip to show remaining time when available"
    grep -F 'duration_label = "充满"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected BAT tooltip to show charge time when available"
}

test_status_widgets_use_hover_details_only() {
    grep -F 'local function read_load_average()' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected CPU/MEM hover details to show load average"
    grep -F 'cpu_processes = "process list loading"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected CPU hover details to keep a cached process list"
    grep -F 'mem_processes = "process list loading"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected MEM hover details to keep a cached process list"
    grep -F 'local function normalize_command_output(output, fallback)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected CPU/MEM process cache to normalize command output"
    grep -F 'local function update_system_details_cache()' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected CPU/MEM hover details to refresh a background cache"
    grep -F 'awful.spawn.easy_async_with_shell(system_details_command("cpu")' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected CPU process list cache to refresh asynchronously"
    grep -F 'awful.spawn.easy_async_with_shell(system_details_command("mem")' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected MEM process list cache to refresh asynchronously"
    grep -F 'timeout = 5,' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected CPU/MEM detail cache to refresh every 5 seconds"
    grep -F 'callback = update_system_details_cache,' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected CPU/MEM detail cache timer to call the refresh function"
    grep -F 'local function render_system_details_text(section)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected CPU/MEM hover details to render tooltip text"
    grep -F 'local title = is_cpu and "CPU" or "内存"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected CPU/MEM hover titles to use concise Chinese labels"
    grep -F '"使用率：" .. system_state.cpu_usage' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected CPU hover summary to use Chinese usage label"
    grep -F '"\n负载：" .. system_state.load_average' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected CPU hover summary to use Chinese load label"
    grep -F '"使用率：" .. system_state.mem_usage' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected MEM hover summary to use Chinese usage label"
    grep -F '"Top CPU 进程"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected CPU process section title to use a unified label"
    grep -F '"Top 内存进程"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected MEM process section title to use a unified label"
    grep -F 'objects = { cpu_widget },' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected CPU detail tooltip to attach to cpu_widget"
    grep -F 'objects = { mem_widget },' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected MEM detail tooltip to attach to mem_widget"
    grep -F 'return render_system_details_text("cpu")' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected CPU hover to show details"
    grep -F 'return render_system_details_text("mem")' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected MEM hover to show details"
    grep -F 'ps -eo pid,comm,%cpu --sort=-%cpu' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected CPU hover details to show only top CPU process columns"
    grep -F 'ps -eo pid,comm,%mem --sort=-%mem' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected MEM hover details to show only top memory process columns"
    grep -F 'local summary = is_cpu' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected CPU/MEM hover details to use section-specific summaries"

    python - "$SYSTEM_WIDGETS_FILE" <<'PY' || fail "expected CPU/MEM hover tooltip to read cached details without spawning commands"
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text()
start = text.index("local function render_system_details_text(section)")
end = text.index("\n    update_system_details_cache()", start)
chunk = text[start:end]

assert "system_details_command" not in chunk
assert "easy_async_with_shell" not in chunk
assert "read_load_average()" not in chunk
assert "system_state.cpu_processes" in chunk
assert "system_state.mem_processes" in chunk
assert "system_state.load_average" in chunk
assert '"CPU: " .. system_state.cpu_usage .. "    MEM: "' not in chunk
assert '"内存详情"' not in chunk
assert '"MEM: " .. system_state.mem_usage' not in chunk
PY

    for forbidden in \
        'net_widget:buttons(gears.table.join(' \
        'cpu_widget:buttons(gears.table.join(' \
        'mem_widget:buttons(gears.table.join(' \
        'local function open_network_status()' \
        'local function open_system_monitor()' \
        'awful.spawn.raise_or_spawn(' \
        'awful.popup {' \
        'awesome-system-monitor' \
        'show_system_details(' \
        'read_command_output('
    do
        if grep -F "$forbidden" "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1; then
            fail "expected NET/CPU/MEM to be hover-only, but found $forbidden"
        fi
    done
}

test_net_pattern_includes_wlp_interfaces
test_system_widgets_parse_cpu_and_memory_without_lain
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
test_battery_widget_has_hover_details
test_status_widgets_use_hover_details_only

printf 'PASS: awesome net tests\n'
