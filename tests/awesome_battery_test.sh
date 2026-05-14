#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SYSTEM_WIDGETS_FILE=$REPO_ROOT/.config/linux/awesome/widgets/system.lua

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

test_system_widgets_detect_battery_devices() {
    grep -F 'local function find_battery_paths()' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected battery widget code to gather all Battery devices from /sys/class/power_supply"
    grep -F '"/type") == "Battery"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected battery widget code to detect Battery devices from /sys/class/power_supply"
}

test_system_widgets_hide_battery_when_missing() {
    grep -F 'if battery_widget then' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected battery widget insertion to be conditional"
}

test_system_widgets_aggregate_multiple_batteries() {
    grep -F 'local function aggregate_battery_status(snapshots)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected battery widget code to aggregate battery statuses"
    grep -F 'local function aggregate_battery_readings(snapshots)' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected battery widget code to aggregate multi-battery readings"
    grep -F 'local battery_paths = find_battery_paths()' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected battery widget to retain every detected battery path"
    grep -F 'for _, battery_path in ipairs(battery_paths) do' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected battery widget updates to iterate over all battery paths"
    grep -F 'summary.count > 1' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected battery tooltip to mention multiple battery packs when present"

    lua - "$SYSTEM_WIDGETS_FILE" <<'LUA' || fail "expected battery aggregation helpers to combine multiple batteries correctly"
local system_file = arg[1]

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
local summary = assert(private.aggregate_battery_readings({
    {
        capacity = 50,
        status = "Discharging",
        charge_now = 4000,
        charge_full = 8000,
        current_now = 1000,
        power_now = 4000000,
    },
    {
        capacity = 100,
        status = "Full",
        charge_now = 2000,
        charge_full = 2000,
        current_now = 0,
        power_now = 0,
    },
}))

assert(summary.count == 2)
assert(summary.status == "Discharging")
assert(summary.capacity == 60)
assert(summary.charge_now == 6000)
assert(summary.charge_full == 10000)
assert(summary.power_now == 4000000)
LUA
}

test_system_widgets_avoid_find_based_probe() {
    if grep -F 'find /sys/class/power_supply' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1; then
        fail "expected battery detection to avoid the brittle find-based probe"
    fi
}

test_system_widgets_detect_battery_devices
test_system_widgets_hide_battery_when_missing
test_system_widgets_aggregate_multiple_batteries
test_system_widgets_avoid_find_based_probe

printf 'PASS: awesome battery tests\n'
