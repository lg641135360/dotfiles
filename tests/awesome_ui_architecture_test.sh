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
    assert_contains 'local function is_compact_screen(screen, config)' "$WIBAR_FILE"
    assert_contains 'local function create_lock_button(ctpp, actions)' "$WIBAR_FILE"
    assert_contains 'local function create_textclock(ctpp, config, screen)' "$WIBAR_FILE"
    assert_contains 'local function create_systray_widget(ctpp)' "$WIBAR_FILE"
    assert_contains 'local function create_sysinfo_bundle(config, ctpp, lain_ok, screen)' "$WIBAR_FILE"
    assert_contains 'compact = is_compact_screen(screen, config),' "$WIBAR_FILE"
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
}

test_actions_module_exists
test_rc_wires_shared_modules
test_rc_no_longer_builds_bar_widgets_locally
test_bindings_use_injected_prompt_runners
test_wibar_owns_bar_widget_creation
test_wibar_escapes_task_titles
test_wibar_exposes_prompt_runners
test_wibar_avoids_container_insert_on_sysinfo_widget
test_system_widget_exposes_row_for_extension

printf 'PASS: awesome ui architecture tests\n'
