#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
RC_FILE=$REPO_ROOT/.config/linux/awesome/rc.lua
BINDINGS_FILE=$REPO_ROOT/.config/linux/awesome/bindings.lua
WIBAR_FILE=$REPO_ROOT/.config/linux/awesome/ui/wibar.lua
ACTIONS_FILE=$REPO_ROOT/.config/linux/awesome/actions.lua
SYSTEM_WIDGETS_FILE=$REPO_ROOT/.config/linux/awesome/widgets/system.lua

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

test_actions_module_exists() {
    [ -f "$ACTIONS_FILE" ] || fail "expected Awesome actions module to exist"
}

test_rc_wires_shared_modules() {
    assert_contains 'local actions = require("actions")' "$RC_FILE"
    assert_contains 'actions = actions,' "$RC_FILE"
    assert_contains 'config = config,' "$RC_FILE"
    assert_contains 'lain_ok = lain_ok,' "$RC_FILE"
}

test_rc_no_longer_builds_bar_widgets_locally() {
    assert_not_contains 'local lock_button =' "$RC_FILE"
    assert_not_contains 'local mytextclock =' "$RC_FILE"
    assert_not_contains 'local systray_widget =' "$RC_FILE"
    assert_not_contains 'require("widgets.system").create' "$RC_FILE"
}

test_bindings_use_injected_prompt_runners() {
    assert_contains 'local run_prompt = args.run_prompt' "$BINDINGS_FILE"
    assert_contains 'local run_lua_prompt = args.run_lua_prompt' "$BINDINGS_FILE"
    assert_not_contains 'awful.screen.focused().mypromptbox' "$BINDINGS_FILE"
}

test_wibar_owns_bar_widget_creation() {
    assert_contains 'local config = args.config' "$WIBAR_FILE"
    assert_contains 'local actions = args.actions or {}' "$WIBAR_FILE"
    assert_contains 'local lain_ok = args.lain_ok' "$WIBAR_FILE"
    assert_contains 'local dpi = require("beautiful.xresources").apply_dpi' "$WIBAR_FILE"
    assert_not_contains 'local xresources = require("beautiful.xresources")' "$WIBAR_FILE"
    assert_not_contains 'local function configure_screen_dpi(screen, config)' "$WIBAR_FILE"
    assert_not_contains 'screen.dpi = dpi_value' "$WIBAR_FILE"
    assert_not_contains 'output:match("^(eDP|LVDS|DSI)")' "$WIBAR_FILE"
    assert_contains 'local function is_compact_screen(screen, config)' "$WIBAR_FILE"
    assert_contains 'local function screen_diagonal_inches(screen)' "$WIBAR_FILE"
    assert_contains 'local function create_lock_button(ctpp, actions)' "$WIBAR_FILE"
    assert_contains 'local function create_textclock(ctpp, config, screen)' "$WIBAR_FILE"
    assert_contains 'local function create_systray_widget(ctpp)' "$WIBAR_FILE"
    assert_contains 'local function create_sysinfo_bundle(config, ctpp, lain_ok, screen)' "$WIBAR_FILE"
    assert_contains 'compact = is_compact_screen(screen, config),' "$WIBAR_FILE"
    assert_not_contains 'configure_screen_dpi(s, config)' "$WIBAR_FILE"
    assert_contains 'systray:set_base_size(dpi(22))' "$WIBAR_FILE"
    assert_contains 'img.forced_width = dpi(20)' "$WIBAR_FILE"
    assert_contains 'img.forced_height = dpi(20)' "$WIBAR_FILE"
    assert_not_contains 'dpi(22, screen)' "$WIBAR_FILE"
    assert_not_contains 'dpi(20, screen)' "$WIBAR_FILE"
}

test_wibar_uses_physical_size_before_width_fallback() {
    lua - "$WIBAR_FILE" <<'LUA' || fail "expected physical monitors larger than 15 inches to use full wibar mode"
local wibar_file = arg[1]

package.preload["awful"] = function()
    return {}
end

package.preload["gears"] = function()
    return {
        string = {
            xml_escape = function(value)
                return value
            end,
        },
    }
end

package.preload["wibox"] = function()
    return {}
end

package.preload["beautiful"] = function()
    return {}
end

package.preload["beautiful.xresources"] = function()
    return {
        apply_dpi = function(value)
            return value
        end,
    }
end

local wibar = assert(loadfile(wibar_file))()
local is_compact_screen = assert(wibar._private and wibar._private.is_compact_screen)
local config = {
    compact_wibar_max_width = 3000,
    compact_wibar_max_diagonal_inches = 15,
}

assert(is_compact_screen({
    geometry = { width = 2560 },
    outputs = {
        ["DP-1"] = { mm_width = 527, mm_height = 296 },
    },
}, config) == false)

assert(is_compact_screen({
    geometry = { width = 2880 },
    outputs = {
        ["eDP-1"] = { mm_width = 302, mm_height = 189 },
    },
}, config) == true)

assert(is_compact_screen({
    geometry = { width = 2560 },
    outputs = {},
}, config) == true)
LUA
}

test_wibar_escapes_task_titles() {
    assert_contains 'gears.string.xml_escape' "$WIBAR_FILE"
}

test_wibar_exposes_prompt_runners() {
    assert_contains 'run_prompt = function()' "$WIBAR_FILE"
    assert_contains 'run_lua_prompt = function()' "$WIBAR_FILE"
}

test_wibar_avoids_container_insert_on_sysinfo_widget() {
    assert_not_contains 'sysinfo_widget:count()' "$WIBAR_FILE"
    assert_not_contains 'sysinfo_widget:insert(' "$WIBAR_FILE"
}

test_system_widget_exposes_row_for_extension() {
    assert_contains 'system_row = system_row,' "$SYSTEM_WIDGETS_FILE"
    assert_contains 'local compact = options and options.compact' "$SYSTEM_WIDGETS_FILE"
    assert_not_contains 'local screen = options and options.screen' "$SYSTEM_WIDGETS_FILE"
    assert_contains 'gears.shape.rounded_rect(cr, w, h, dpi(8))' "$SYSTEM_WIDGETS_FILE"
    assert_not_contains 'dpi(8, screen)' "$SYSTEM_WIDGETS_FILE"
}

test_actions_module_exists
test_rc_wires_shared_modules
test_rc_no_longer_builds_bar_widgets_locally
test_bindings_use_injected_prompt_runners
test_wibar_owns_bar_widget_creation
test_wibar_uses_physical_size_before_width_fallback
test_wibar_escapes_task_titles
test_wibar_exposes_prompt_runners
test_wibar_avoids_container_insert_on_sysinfo_widget
test_system_widget_exposes_row_for_extension

printf 'PASS: awesome ui architecture tests\n'
