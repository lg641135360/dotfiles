#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CONFIG_FILE=$REPO_ROOT/.config/linux/awesome/config.lua

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

test_config_exposes_command_capability_helper() {
    assert_contains 'local function command_exists(command)' "$CONFIG_FILE"
    assert_contains 'command -v ' "$CONFIG_FILE"
}

test_volume_widget_uses_capability_detection() {
    assert_contains 'has_volume = (platform.os == "Linux" and command_exists("pactl")),' "$CONFIG_FILE"
}

test_brightness_widget_is_limited_to_aarch64_profiles() {
    assert_contains 'brightness_override ~= "0" and platform.os == "Linux" and (platform.arch == "aarch64" or platform.arch == "arm64")' "$CONFIG_FILE"
}

test_brightness_override_is_supported_without_changing_default_policy() {
    assert_contains 'local brightness_override = os.getenv("AWESOME_HAS_BRIGHTNESS")' "$CONFIG_FILE"
    assert_contains 'has_brightness = brightness_override == "1" or (brightness_override ~= "0" and platform.os == "Linux" and (platform.arch == "aarch64" or platform.arch == "arm64")),' "$CONFIG_FILE"
}

test_net_interfaces_are_flattened_after_convergence() {
    assert_contains 'net_interfaces = "wlan0|eth0|enp|wlp",' "$CONFIG_FILE"
    assert_not_contains 'and "wlan0|eth0|enp|wlp"' "$CONFIG_FILE"
}

test_config_exposes_compact_wibar_thresholds() {
    assert_contains 'compact_wibar_max_width = 3000,' "$CONFIG_FILE"
    assert_contains 'compact_wibar_max_diagonal_inches = 15,' "$CONFIG_FILE"
    assert_contains 'compact_date_format = " %m/%d %H:%M ",' "$CONFIG_FILE"
}

test_config_keeps_xft_dpi_global_without_per_screen_overrides() {
    assert_not_contains 'screen_dpi = {' "$CONFIG_FILE"
    assert_not_contains 'internal = 192,' "$CONFIG_FILE"
    assert_not_contains 'external = 96,' "$CONFIG_FILE"
}

test_config_exposes_command_capability_helper
test_volume_widget_uses_capability_detection
test_brightness_widget_is_limited_to_aarch64_profiles
test_brightness_override_is_supported_without_changing_default_policy
test_net_interfaces_are_flattened_after_convergence
test_config_exposes_compact_wibar_thresholds
test_config_keeps_xft_dpi_global_without_per_screen_overrides

printf 'PASS: awesome config tests\n'
