#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CONFIG_FILE=$REPO_ROOT/.config/linux/awesome/config.lua
BRIGHTNESS_FILE=$REPO_ROOT/.config/linux/awesome/widgets/brightness.lua
STATUS_AREA_FILE=$REPO_ROOT/.config/linux/awesome/ui/status_area.lua

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

test_brightness_widget_uses_native_backlight_sysfs() {
    assert_contains '/sys/class/backlight/*' "$BRIGHTNESS_FILE"
    assert_contains 'read_brightness_number(brightness_path .. "/actual_brightness")' "$BRIGHTNESS_FILE"
    assert_contains 'read_brightness_number(brightness_path .. "/brightness")' "$BRIGHTNESS_FILE"
    assert_contains 'read_brightness_number(brightness_path .. "/max_brightness")' "$BRIGHTNESS_FILE"
    assert_contains 'if not brightness_path then' "$BRIGHTNESS_FILE"
    assert_contains 'return nil' "$BRIGHTNESS_FILE"
}

test_brightness_widget_calculates_percent_and_exposes_private_helpers() {
    lua - "$BRIGHTNESS_FILE" <<'LUA' || fail "expected brightness helpers to round percentages and quote device names safely"
local brightness_file = arg[1]
package.path = brightness_file:gsub("/widgets/brightness%.lua$", "/?.lua") .. ";" .. package.path

package.preload["awful"] = function()
    return { spawn = { easy_async_with_shell = function() end } }
end
package.preload["gears"] = function()
    return { timer = function() end }
end
package.preload["wibox"] = function()
    return {}
end
package.preload["naughty"] = function()
    return { config = { presets = { warn = {} } }, notify = function() end }
end
package.preload["beautiful"] = function()
    return { ctpp = {} }
end
package.preload["lib.common"] = function()
    return {
        read_command_output = function() end,
        command_exists = function(command)
            return command == "apt"
        end,
        stop_timer = function() end,
        truncate_message = function(text) return text end,
        shell_quote = function(value)
            return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
        end,
    }
end

local brightness = assert(loadfile(brightness_file))()
local private = assert(brightness._private)
assert(private.calculate_brightness_percent(198, 500) == 40)
assert(private.calculate_brightness_percent(0, 500) == 0)
assert(private.calculate_brightness_percent(nil, 500) == nil)
assert(private.calculate_brightness_percent(100, 0) == nil)
assert(private.brightnessctl_install_hint() == "sudo apt install brightnessctl")
assert(private.shell_quote("m1000_backlight") == "'m1000_backlight'")
assert(private.shell_quote("foo'bar") == "'foo'\\''bar'")
LUA
}

test_brightness_widget_uses_tight_value_spacing() {
    assert_contains 'local brightness_label = compact and "L" or "BRI"' "$BRIGHTNESS_FILE"
    assert_contains 'brightness_label .. ":</span>' "$BRIGHTNESS_FILE"
    assert_contains '>N/A</span>' "$BRIGHTNESS_FILE"
    assert_contains '.. percent .. "%</span>"' "$BRIGHTNESS_FILE"
}

test_brightness_widget_has_hover_details_and_optional_scroll_hint() {
    assert_contains 'local brightness_tooltip_status = brightness_label .. ": N/A"' "$BRIGHTNESS_FILE"
    assert_contains 'awful.tooltip {' "$BRIGHTNESS_FILE"
    assert_contains 'objects = { brightness_widget },' "$BRIGHTNESS_FILE"
    assert_contains 'return render_brightness_tooltip()' "$BRIGHTNESS_FILE"
    assert_contains '"亮度"' "$BRIGHTNESS_FILE"
    assert_contains '"状态：" .. brightness_tooltip_status' "$BRIGHTNESS_FILE"
    assert_contains '"设备：" .. device_name' "$BRIGHTNESS_FILE"
    assert_contains '"原始：" .. last_current .. " / " .. last_maximum' "$BRIGHTNESS_FILE"
    assert_contains '"滚轮：调整亮度"' "$BRIGHTNESS_FILE"
    assert_contains '"滚轮：未启用（缺少 brightnessctl）"' "$BRIGHTNESS_FILE"
    assert_contains '"滚轮：未启用（权限不足）"' "$BRIGHTNESS_FILE"
}

test_brightness_widget_refreshes_periodically_and_optionally_uses_brightnessctl() {
    assert_contains 'local naughty = require("naughty")' "$BRIGHTNESS_FILE"
    assert_contains 'local common = require("lib.common")' "$BRIGHTNESS_FILE"
    assert_contains 'local read_command_output = common.read_command_output' "$BRIGHTNESS_FILE"
    assert_contains 'local truncate_message = common.truncate_message' "$BRIGHTNESS_FILE"
    assert_contains 'local function notify_brightness_failure(title, text)' "$BRIGHTNESS_FILE"
    assert_contains 'local function file_writable(path)' "$BRIGHTNESS_FILE"
    assert_contains 'local function file_group_name(path)' "$BRIGHTNESS_FILE"
    assert_contains 'local function user_in_group(group_name)' "$BRIGHTNESS_FILE"
    assert_contains 'local function brightnessctl_install_hint()' "$BRIGHTNESS_FILE"
    assert_contains 'local function brightness_permission_hint(brightness_file)' "$BRIGHTNESS_FILE"
    assert_contains 'sudo apt install brightnessctl' "$BRIGHTNESS_FILE"
    assert_contains 'local refresh_timer = gears.timer {' "$BRIGHTNESS_FILE"
    assert_contains 'timeout = 10,' "$BRIGHTNESS_FILE"
    assert_contains 'callback = update_brightness,' "$BRIGHTNESS_FILE"
    assert_contains 'local refresh_delays = { 0.15, 0.5, 1.2 }' "$BRIGHTNESS_FILE"
    assert_contains 'command_exists("brightnessctl")' "$BRIGHTNESS_FILE"
    assert_contains 'local can_write_brightness = file_writable(brightness_file)' "$BRIGHTNESS_FILE"
    assert_contains 'local function notify_missing_brightnessctl()' "$BRIGHTNESS_FILE"
    assert_contains 'local function notify_brightness_permission_denied()' "$BRIGHTNESS_FILE"
    assert_contains 'notify_brightness_failure("亮度调节不可用"' "$BRIGHTNESS_FILE"
    assert_contains 'brightnessctl_install_hint())' "$BRIGHTNESS_FILE"
    assert_contains 'notify_brightness_failure("亮度调节权限不足", brightness_permission_hint(brightness_file))' "$BRIGHTNESS_FILE"
    assert_contains 'notify_missing_brightnessctl()' "$BRIGHTNESS_FILE"
    assert_contains 'notify_brightness_permission_denied()' "$BRIGHTNESS_FILE"
    assert_contains 'brightnessctl -q -d ' "$BRIGHTNESS_FILE"
    assert_contains 'if not can_write_brightness then' "$BRIGHTNESS_FILE"
    assert_contains 'error_text:lower():match("permission denied")' "$BRIGHTNESS_FILE"
    assert_contains 'notify_brightness_failure("亮度调节执行失败", error_text or "brightnessctl 执行失败。")' "$BRIGHTNESS_FILE"
    assert_contains 'adjust_brightness("5%+")' "$BRIGHTNESS_FILE"
    assert_contains 'adjust_brightness("5%-")' "$BRIGHTNESS_FILE"
}

test_brightness_widget_is_aarch64_only_in_config_and_status_area() {
    assert_contains 'brightness_override ~= "0" and platform.os == "Linux" and (platform.arch == "aarch64" or platform.arch == "arm64")' "$CONFIG_FILE"
    assert_contains 'if config.has_brightness then' "$STATUS_AREA_FILE"
    assert_contains 'brightness_bundle = require("widgets.brightness").create({' "$STATUS_AREA_FILE"
    assert_contains 'if brightness_bundle then' "$STATUS_AREA_FILE"
    assert_contains 'brightness_bundle.widget' "$STATUS_AREA_FILE"
    python - "$STATUS_AREA_FILE" <<'PY' || fail "expected status area to gate brightness by config and append it before volume"
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text()
start = text.index("local brightness_bundle = nil")
end = text.index("local function dispose()", start)
chunk = text[start:end]

assert "if config.has_brightness then" in chunk
assert chunk.index("brightness_bundle.widget") < chunk.index("volume_bundle.widget")
PY
}

test_brightness_widget_uses_native_backlight_sysfs
test_brightness_widget_calculates_percent_and_exposes_private_helpers
test_brightness_widget_uses_tight_value_spacing
test_brightness_widget_has_hover_details_and_optional_scroll_hint
test_brightness_widget_refreshes_periodically_and_optionally_uses_brightnessctl
test_brightness_widget_is_aarch64_only_in_config_and_status_area

printf 'PASS: awesome brightness tests\n'
