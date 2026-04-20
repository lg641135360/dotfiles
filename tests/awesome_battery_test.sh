#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SYSTEM_WIDGETS_FILE=$REPO_ROOT/.config/linux/awesome/widgets/system.lua

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

test_system_widgets_detect_battery_devices() {
    grep -F '"/type") == "Battery"' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected battery widget code to detect Battery devices from /sys/class/power_supply"
}

test_system_widgets_hide_battery_when_missing() {
    grep -F 'if battery_widget then' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1 ||
        fail "expected battery widget insertion to be conditional"
}

test_system_widgets_avoid_find_based_probe() {
    if grep -F 'find /sys/class/power_supply' "$SYSTEM_WIDGETS_FILE" >/dev/null 2>&1; then
        fail "expected battery detection to avoid the brittle find-based probe"
    fi
}

test_system_widgets_detect_battery_devices
test_system_widgets_hide_battery_when_missing
test_system_widgets_avoid_find_based_probe

printf 'PASS: awesome battery tests\n'
