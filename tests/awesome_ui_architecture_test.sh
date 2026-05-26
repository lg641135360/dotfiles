#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
RC_FILE=$REPO_ROOT/.config/linux/awesome/rc.lua
BINDINGS_FILE=$REPO_ROOT/.config/linux/awesome/bindings.lua
WIBAR_FILE=$REPO_ROOT/.config/linux/awesome/ui/wibar.lua
TASKLIST_FILE=$REPO_ROOT/.config/linux/awesome/ui/tasklist.lua
STATUS_AREA_FILE=$REPO_ROOT/.config/linux/awesome/ui/status_area.lua
ACTIONS_FILE=$REPO_ROOT/.config/linux/awesome/actions.lua
SYSTEM_WIDGETS_FILE=$REPO_ROOT/.config/linux/awesome/widgets/system.lua
VOLUME_FILE=$REPO_ROOT/.config/linux/awesome/widgets/volume.lua
BRIGHTNESS_FILE=$REPO_ROOT/.config/linux/awesome/widgets/brightness.lua
CLIENT_SHIM_FILE=$REPO_ROOT/.config/linux/awesome/client.lua
CLIENT_INIT_FILE=$REPO_ROOT/.config/linux/awesome/client/init.lua
CLIENT_POLICIES_FILE=$REPO_ROOT/.config/linux/awesome/client/policies.lua
CLIENT_RULES_FILE=$REPO_ROOT/.config/linux/awesome/client/rules.lua
CLIENT_DECORATIONS_FILE=$REPO_ROOT/.config/linux/awesome/client/decorations.lua
README_FILE=$REPO_ROOT/.config/linux/awesome/README.md

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
    assert_not_contains 'local lain_ok = pcall(require, "lain")' "$RC_FILE"
    assert_not_contains 'Please install lain' "$RC_FILE"
}

test_rc_no_longer_builds_bar_widgets_locally() {
    assert_not_contains 'local lock_button =' "$RC_FILE"
    assert_not_contains 'local mytextclock =' "$RC_FILE"
    assert_not_contains 'local systray_widget =' "$RC_FILE"
    assert_not_contains 'require("widgets.system").create' "$RC_FILE"
}

test_rc_refreshes_runtime_display_layout_on_screen_topology_changes() {
    assert_contains 'local display_layout_refresh_queued = false' "$RC_FILE"
    assert_contains 'local function queue_display_layout_refresh()' "$RC_FILE"
    assert_contains 'gears.timer.start_new(1, function()' "$RC_FILE"
    assert_contains 'test -x ~/.config/awesome/display-layout.sh && ~/.config/awesome/display-layout.sh >/dev/null 2>&1' "$RC_FILE"
    assert_contains 'screen.connect_signal("added", queue_display_layout_refresh)' "$RC_FILE"
    assert_contains 'screen.connect_signal("removed", queue_display_layout_refresh)' "$RC_FILE"
    assert_contains 'awesome.connect_signal("screen::change", queue_display_layout_refresh)' "$RC_FILE"
}

test_bindings_use_injected_prompt_runners() {
    assert_contains 'local run_prompt = args.run_prompt' "$BINDINGS_FILE"
    assert_contains 'local run_lua_prompt = args.run_lua_prompt' "$BINDINGS_FILE"
    assert_not_contains 'awful.screen.focused().mypromptbox' "$BINDINGS_FILE"
}

test_bindings_keep_lock_on_mod_shift_l() {
    assert_contains 'awful.key({ modkey, "Shift" }, "l", lock,' "$BINDINGS_FILE"
    assert_not_contains 'awful.key({ modkey, "Control" }, "l", lock,' "$BINDINGS_FILE"
}

test_bindings_leave_bare_f1_to_snipaste() {
    assert_not_contains '"F1"' "$BINDINGS_FILE"
    assert_not_contains "'F1'" "$BINDINGS_FILE"
}

test_bindings_do_not_duplicate_shortcuts() {
    python - "$BINDINGS_FILE" <<'PY' || fail "expected Awesome keybindings to avoid duplicate modifier/key combinations"
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text()
seen = {}
pattern = re.compile(r'awful\.key\(\{([^}]*)\}\s*,\s*"([^"]+)"')

for match in pattern.finditer(text):
    line = text[:match.start()].count("\n") + 1
    mods = tuple(sorted(
        part.strip().strip('"')
        for part in match.group(1).split(",")
        if part.strip()
    ))
    key = match.group(2)
    combo = (mods, key)
    seen.setdefault(combo, []).append(line)

duplicates = {
    combo: lines
    for combo, lines in seen.items()
    if len(lines) > 1
}

if duplicates:
    for (mods, key), lines in sorted(duplicates.items()):
        print(f"duplicate {'+'.join(mods)}+{key}: lines {lines}", file=sys.stderr)
    raise SystemExit(1)
PY
}

test_bindings_use_shared_occupied_tag_helper() {
    python - "$BINDINGS_FILE" <<'PY' || fail "expected occupied-tag navigation to use one shared directional helper"
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text()

old_helpers = (
    "local function view_previous_occupied_tag()",
    "local function view_next_occupied_tag()",
)
for helper in old_helpers:
    assert helper not in text, f"old duplicated helper remains: {helper}"

assert text.count("local function find_occupied_tag(") == 1
assert text.count("local function view_occupied_tag(direction)") == 1

def function_body(name):
    pattern = re.compile(rf"local function {name}[^\n]*\n(.*?)(?=\nlocal function |\nfunction M\.setup)", re.S)
    match = pattern.search(text)
    assert match, f"missing local function {name}"
    return match.group(1)

find_body = function_body("find_occupied_tag")
assert "direction" in find_body
assert ":clients()" in find_body
assert "return tags[i]" in find_body
assert find_body.count("for i =") >= 2, "helper should handle forward and wrapped traversal"

view_body = function_body("view_occupied_tag")
assert "find_occupied_tag(tags, current_tag_index, direction)" in view_body
assert "target_tag:view_only()" in view_body

assert "view_occupied_tag(-1)" in text
assert "view_occupied_tag(1)" in text
PY
}

test_client_module_is_split_into_focused_submodules() {
    [ -f "$CLIENT_INIT_FILE" ] || fail "expected client init module to exist"
    [ -f "$CLIENT_POLICIES_FILE" ] || fail "expected client policies module to exist"
    [ -f "$CLIENT_RULES_FILE" ] || fail "expected client rules module to exist"
    [ -f "$CLIENT_DECORATIONS_FILE" ] || fail "expected client decorations module to exist"

    assert_contains 'return require("client.init")' "$CLIENT_SHIM_FILE"
    assert_contains 'local rules = require("client.rules")' "$CLIENT_INIT_FILE"
    assert_contains 'local decorations = require("client.decorations")' "$CLIENT_INIT_FILE"
    assert_contains 'function M.setup(args)' "$CLIENT_INIT_FILE"
    assert_contains 'rules.setup({' "$CLIENT_INIT_FILE"
    assert_contains 'decorations.setup()' "$CLIENT_INIT_FILE"

    lua - "$CLIENT_INIT_FILE" <<'LUA' || fail "expected client init setup to delegate to rules and decorations setup"
local init_file = arg[1]
local calls = {
    rules = 0,
    decorations = 0,
}
local expected_keys = {}
local expected_buttons = {}

package.loaded["client.rules"] = nil
package.loaded["client.decorations"] = nil
package.preload["client.rules"] = function()
    return {
        setup = function(args)
            calls.rules = calls.rules + 1
            assert(args.clientkeys == expected_keys)
            assert(args.clientbuttons == expected_buttons)
        end,
    }
end
package.preload["client.decorations"] = function()
    return {
        setup = function()
            calls.decorations = calls.decorations + 1
        end,
    }
end

local init = assert(loadfile(init_file))()
init.setup({
    clientkeys = expected_keys,
    clientbuttons = expected_buttons,
})

assert(calls.rules == 1)
assert(calls.decorations == 1)
LUA
}


test_client_rules_use_data_driven_policy_lists() {
    assert_contains 'floating_classes = {' "$CLIENT_POLICIES_FILE"
    assert_contains 'fallback_titlebar_classes = {' "$CLIENT_POLICIES_FILE"
    assert_contains 'extra_rules = {' "$CLIENT_POLICIES_FILE"
    assert_contains 'class = policies.floating_classes,' "$CLIENT_RULES_FILE"
    assert_contains 'class = policies.fallback_titlebar_classes,' "$CLIENT_RULES_FILE"
    assert_contains 'table.unpack(policies.extra_rules)' "$CLIENT_RULES_FILE"
    assert_contains 'rule = { class = "tblive", type = "utility" }' "$CLIENT_POLICIES_FILE"
    assert_contains 'skip_taskbar = true,' "$CLIENT_POLICIES_FILE"
    assert_contains 'client.lua          # client 入口兼容层' "$README_FILE"
    assert_contains '├── client/' "$README_FILE"
    assert_contains '│   ├── init.lua        # client setup 入口' "$README_FILE"
    assert_contains '│   ├── policies.lua    # app-specific 窗口策略数据' "$README_FILE"
    assert_contains '│   ├── rules.lua       # 根据策略组装 Awesome client rules' "$README_FILE"
    assert_contains '│   └── decorations.lua # 窗口圆角、fallback titlebar 与焦点样式' "$README_FILE"
}


test_actions_check_prerequisites_and_notify_failures() {
    lua - "$ACTIONS_FILE" <<'LUA' || fail "expected desktop actions to notify when prerequisites are missing"
local actions_file = arg[1]
local notifications = {}
local shell_commands = {}
local direct_spawns = {}
package.path = actions_file:gsub("/actions%.lua$", "/?.lua") .. ";" .. package.path

package.preload["awful"] = function()
    return {
        spawn = setmetatable({
            easy_async_with_shell = function(command, callback)
                table.insert(shell_commands, command)
                callback("", "missing dependency", "", 1)
            end,
        }, {
            __call = function(_, command)
                table.insert(direct_spawns, command)
            end,
        }),
    }
end

package.preload["naughty"] = function()
    return {
        config = { presets = { warn = {} } },
        notify = function(args)
            table.insert(notifications, args)
        end,
    }
end

local actions = assert(loadfile(actions_file))()
assert(actions._private)
assert(actions._private.command_check({ "maim", "curl" }):match("command %-v 'maim'"))
assert(actions._private.executable_check("~/.config/scripts/lock"):match("/%.config/scripts/lock"))
assert(actions._private.screenshot_ocr_command():match("maim %-s"))
assert(actions._private.screenshot_ocr_command():match("curl %-%-fail"))

actions.open_file_manager()
assert(#notifications == 1)
assert(notifications[1].title:match("文件管理器不可用"))
assert(#direct_spawns == 0)
assert(shell_commands[1]:match("command %-v 'dolphin'"))
LUA
}

test_volume_widget_uses_lower_idle_polling() {
    assert_contains 'timeout = 10,' "$VOLUME_FILE"
    assert_not_contains 'timeout = 5,' "$VOLUME_FILE"
    assert_contains 'local refresh_delays = { 0.15, 0.5, 1.2 }' "$VOLUME_FILE"
}

test_brightness_widget_uses_lower_idle_polling() {
    assert_contains 'timeout = 10,' "$BRIGHTNESS_FILE"
    assert_not_contains 'timeout = 5,' "$BRIGHTNESS_FILE"
    assert_contains 'local refresh_delays = { 0.15, 0.5, 1.2 }' "$BRIGHTNESS_FILE"
}

test_volume_widget_does_not_switch_to_event_subscription() {
    assert_not_contains 'pactl subscribe' "$VOLUME_FILE"
}

test_tasklist_does_not_switch_to_icon_only_mode() {
    assert_not_contains 'icon_only' "$TASKLIST_FILE"
    assert_contains 'id = "text_role",' "$TASKLIST_FILE"
}

test_tasklist_switches_to_icon_only_mode_at_high_density() {
    assert_contains 'local function task_title_display_mode(screen, available_width, config, compact)' "$TASKLIST_FILE"
    assert_contains 'if client_count < 5 then' "$TASKLIST_FILE"
    assert_contains 'return "icon_only"' "$TASKLIST_FILE"
    assert_contains 'local display_mode = task_title_display_mode(screen, available_width, config, compact)' "$TASKLIST_FILE"
    assert_contains 'text.visible = display_mode ~= "icon_only"' "$TASKLIST_FILE"
}

test_tasklist_exposes_overflow_indicator_support() {
    assert_contains 'local function task_overflow_indicator_text(hidden_count)' "$TASKLIST_FILE"
    assert_contains 'return "+" .. hidden_count' "$TASKLIST_FILE"
    assert_contains 'local overflow_text = task_overflow_indicator_text(hidden_count)' "$TASKLIST_FILE"
    assert_contains '还有" .. hidden_count .. " 个窗口未显示' "$TASKLIST_FILE"
    assert_contains 'function M.create_overflow_indicator(ctpp, screen)' "$TASKLIST_FILE"
    assert_contains 'id = "task_overflow_text_role",' "$TASKLIST_FILE"
    assert_contains 'awful.menu.client_list({ theme = { width = 250 } })' "$TASKLIST_FILE"
    assert_contains 'self.visible = hidden_count > 0' "$TASKLIST_FILE"
}

test_tasklist_hidden_count_uses_layout_budget() {
    assert_contains 'local function hidden_task_count(screen, available_width)' "$TASKLIST_FILE"
    assert_contains 'local available_width = math.max(screen_width - left_width - right_width, 0)' "$WIBAR_FILE"
    assert_contains 's.mytaskoverflow:update(available_width)' "$WIBAR_FILE"
    assert_not_contains 'local reserved_width = screen_width < 1800 and 980 or 1320' "$TASKLIST_FILE"
}

test_tasklist_slot_width_prefers_measured_fit() {
    assert_contains 'local function measured_task_slot_width(screen, available_width)' "$TASKLIST_FILE"
    assert_contains 'return math.max(math.floor(fit_width + 0.5), 1)' "$TASKLIST_FILE"
    assert_contains 'local measured_width = measured_task_slot_width(screen, budget_width)' "$TASKLIST_FILE"
    assert_contains 'local fallback_width = current_tag_client_count(screen) >= 8 and 36 or 220' "$TASKLIST_FILE"
    assert_contains 'local slot_width = measured_width or fallback_width' "$TASKLIST_FILE"
}

test_tasklist_icon_only_threshold_uses_budget_pressure() {
    assert_contains 'local function task_title_display_mode(screen, available_width, config, compact)' "$TASKLIST_FILE"
    assert_contains 'if client_count < 5 then' "$TASKLIST_FILE"
    assert_contains 'local average_width = math.floor((budget_width / client_count) + 0.5)' "$TASKLIST_FILE"
    assert_contains 'local text_threshold = task_title_max_width(screen, config, compact)' "$TASKLIST_FILE"
    assert_contains 'if average_width < text_threshold then' "$TASKLIST_FILE"
    assert_contains 'local display_mode = task_title_display_mode(screen, available_width, config, compact)' "$TASKLIST_FILE"
}

test_tasklist_live_available_width_reaches_update_path() {
    assert_not_contains 'update_task_item(self, c, ctpp, screen, config, compact, 0)' "$TASKLIST_FILE"
    assert_contains 'local current_available_width = math.max((screen and screen._omx_task_available_width) or 0, 0)' "$TASKLIST_FILE"
    assert_contains 'update_task_item(self, c, ctpp, screen, config, compact, current_available_width)' "$TASKLIST_FILE"
    assert_contains 's._omx_task_available_width = available_width' "$WIBAR_FILE"
}

test_tasklist_overflow_indicator_uses_lighter_visual_weight() {
    assert_contains 'left = dpi(4),' "$TASKLIST_FILE"
    assert_contains 'right = dpi(4),' "$TASKLIST_FILE"
    assert_contains 'top = dpi(1),' "$TASKLIST_FILE"
    assert_contains 'bottom = dpi(1),' "$TASKLIST_FILE"
    assert_contains 'bg = ctpp.base,' "$TASKLIST_FILE"
    assert_contains '.. ctpp.subtext1 ..' "$TASKLIST_FILE"
}

test_wibar_uses_task_density_tiers() {
    assert_contains 'local function current_tag_client_count(screen)' "$TASKLIST_FILE"
    assert_contains 'local function task_density_tier(screen)' "$TASKLIST_FILE"
    assert_contains 'if client_count >= 7 then' "$TASKLIST_FILE"
    assert_contains 'if client_count >= 4 then' "$TASKLIST_FILE"
    assert_contains 'local density = task_density_tier(screen)' "$TASKLIST_FILE"
}

test_wibar_task_title_width_depends_on_density() {
    assert_contains 'local density = task_density_tier(screen)' "$TASKLIST_FILE"
    assert_contains 'if density == "tight" then' "$TASKLIST_FILE"
    assert_contains 'elseif density == "compact" then' "$TASKLIST_FILE"
}

test_wibar_owns_bar_widget_creation() {
    assert_contains 'local config = args.config' "$WIBAR_FILE"
    assert_contains 'local actions = args.actions or {}' "$WIBAR_FILE"
    assert_not_contains 'local terminal = args.terminal or "alacritty"' "$WIBAR_FILE"
    assert_not_contains 'local lain_ok = args.lain_ok' "$WIBAR_FILE"
    assert_contains 'local dpi = require("beautiful.xresources").apply_dpi' "$WIBAR_FILE"
    assert_not_contains 'local xresources = require("beautiful.xresources")' "$WIBAR_FILE"
    assert_not_contains 'local function configure_screen_dpi(screen, config)' "$WIBAR_FILE"
    assert_not_contains 'screen.dpi = dpi_value' "$WIBAR_FILE"
    assert_not_contains 'output:match("^(eDP|LVDS|DSI)")' "$WIBAR_FILE"
    assert_contains 'local is_compact_screen = assert(status_area.is_compact_screen)' "$WIBAR_FILE"
    assert_contains 'local function is_compact_screen(screen, config)' "$STATUS_AREA_FILE"
    assert_contains 'local function screen_diagonal_inches(screen)' "$STATUS_AREA_FILE"
    assert_contains 'local tasklist = require("ui.tasklist")' "$WIBAR_FILE"
    assert_contains 'tasklist.create_tasklist(ctpp, s, tasklist_buttons, config, is_compact_screen(s, config))' "$WIBAR_FILE"
    assert_contains 'tasklist.create_overflow_indicator(ctpp, s)' "$WIBAR_FILE"
    assert_contains 'tasklist.task_title_max_width(s, config, is_compact_screen(s, config))' "$WIBAR_FILE"
    assert_not_contains 'local function render_task_text(c, ctpp)' "$WIBAR_FILE"
    assert_not_contains 'local function render_task_tooltip(c)' "$WIBAR_FILE"
    assert_not_contains 'local function current_tag_client_count(screen)' "$WIBAR_FILE"
    assert_not_contains 'local function task_density_tier(screen)' "$WIBAR_FILE"
    assert_not_contains 'local function task_title_max_width(screen, config)' "$WIBAR_FILE"
    assert_not_contains 'local function update_task_item(self, c, ctpp, screen, config)' "$WIBAR_FILE"
    assert_not_contains 'local function create_tasklist(ctpp, screen, tasklist_buttons, config)' "$WIBAR_FILE"
    assert_contains 'local function render_task_text(c, ctpp)' "$TASKLIST_FILE"
    assert_contains 'local function render_task_tooltip(c)' "$TASKLIST_FILE"
    assert_contains 'local function current_tag_client_count(screen)' "$TASKLIST_FILE"
    assert_contains 'local function task_density_tier(screen)' "$TASKLIST_FILE"
    assert_contains 'local function task_title_max_width(screen, config, compact)' "$TASKLIST_FILE"
    assert_contains 'local function update_task_item(self, c, ctpp, screen, config, compact, available_width)' "$TASKLIST_FILE"
    assert_contains 'local function create_tasklist(ctpp, screen, tasklist_buttons, config, compact)' "$TASKLIST_FILE"
    assert_contains 'create_overflow_indicator = M.create_overflow_indicator,' "$TASKLIST_FILE"
    assert_contains 'return {' "$TASKLIST_FILE"
    assert_contains 'create_tasklist = create_tasklist,' "$TASKLIST_FILE"
    assert_contains 'local function create_lock_button(ctpp, actions)' "$WIBAR_FILE"
    assert_contains 'objects = { lock_button },' "$WIBAR_FILE"
    assert_contains 'return "锁屏' "$WIBAR_FILE"
    assert_contains '操作：立即锁屏' "$WIBAR_FILE"
    assert_contains '快捷键：Super+Shift+L' "$WIBAR_FILE"
    assert_contains 'local status_area = require("ui.status_area")' "$WIBAR_FILE"
    assert_contains 'local clock_widget = status_area.create_textclock(ctpp, config, s)' "$WIBAR_FILE"
    assert_contains 'local right_widget_data = status_area.create_right_widgets(config, ctpp, s, clock_widget)' "$WIBAR_FILE"
    assert_not_contains 'local function create_textclock(ctpp, config, screen)' "$WIBAR_FILE"
    assert_not_contains 'local function create_systray_widget(ctpp)' "$WIBAR_FILE"
    assert_not_contains 'local function create_separator(ctpp)' "$WIBAR_FILE"
    assert_not_contains 'local function create_sysinfo_bundle(config, screen, compact)' "$WIBAR_FILE"
    assert_not_contains 'local function dispose_status_widgets(s)' "$WIBAR_FILE"
    assert_not_contains 'local function ensure_primary_status_widgets(config, ctpp, s, compact)' "$WIBAR_FILE"
    assert_not_contains 'local function create_right_widgets(config, ctpp, target_screen, clock_widget)' "$WIBAR_FILE"
    assert_contains 'local is_compact_screen = assert(status_area.is_compact_screen)' "$WIBAR_FILE"
    assert_contains 'tasklist.create_tasklist(ctpp, s, tasklist_buttons, config, is_compact_screen(s, config))' "$WIBAR_FILE"
    assert_contains 'tasklist.task_title_max_width(s, config, is_compact_screen(s, config))' "$WIBAR_FILE"
    assert_contains 'local function create_textclock(ctpp, config, screen)' "$STATUS_AREA_FILE"
    assert_contains 'local function create_systray_widget(ctpp)' "$STATUS_AREA_FILE"
    assert_contains 'local function create_separator(ctpp)' "$STATUS_AREA_FILE"
    assert_contains 'local function create_sysinfo_bundle(config, screen, compact)' "$STATUS_AREA_FILE"
    assert_contains 'local function dispose_status_widgets(s)' "$STATUS_AREA_FILE"
    assert_contains 'local function ensure_primary_status_widgets(config, ctpp, s, compact)' "$STATUS_AREA_FILE"
    assert_contains 'local function create_right_widgets(config, ctpp, target_screen, clock_widget)' "$STATUS_AREA_FILE"
    assert_contains 'return {' "$STATUS_AREA_FILE"
    assert_contains 'create_textclock = create_textclock,' "$STATUS_AREA_FILE"
    assert_contains 'create_right_widgets = create_right_widgets,' "$STATUS_AREA_FILE"
    assert_not_contains 'awful.widget.calendar_popup.month {' "$WIBAR_FILE"
    assert_not_contains 'clock_widget:buttons(clock_buttons)' "$WIBAR_FILE"
    assert_not_contains 'textclock:buttons(clock_buttons)' "$WIBAR_FILE"
    assert_not_contains 'local clock_buttons = gears.table.join(' "$WIBAR_FILE"
    assert_not_contains 'month_calendar:connect_signal' "$WIBAR_FILE"
    assert_not_contains 'show_calendar(' "$WIBAR_FILE"
    assert_contains 'spacing = compact and 2 or 4,' "$STATUS_AREA_FILE"
    assert_not_contains 'configure_screen_dpi(s, config)' "$WIBAR_FILE"
    assert_contains 'systray:set_base_size(dpi(20))' "$STATUS_AREA_FILE"
    assert_contains 'border_color = ctpp.surface1,' "$STATUS_AREA_FILE"
    assert_contains 'id = "focus_indicator_role",' "$TASKLIST_FILE"
    assert_contains 'id = "background_role",' "$TASKLIST_FILE"
    assert_contains 'local lines = { "窗口", "标题：" .. title }' "$TASKLIST_FILE"
    assert_contains 'layout = wibox.layout.fixed.horizontal,' "$TASKLIST_FILE"
    assert_contains 'ellipsize = "end",' "$TASKLIST_FILE"
    assert_contains 'id = "text_constraint_role",' "$TASKLIST_FILE"
    assert_contains 'strategy = "max",' "$TASKLIST_FILE"
    assert_contains 'width = task_title_max_width(screen, config, compact),' "$TASKLIST_FILE"
    assert_not_contains 'local function is_compact_screen(screen, config)' "$TASKLIST_FILE"
    assert_not_contains 'local function screen_diagonal_inches(screen)' "$TASKLIST_FILE"
    assert_not_contains 'local function output_diagonal_inches(output)' "$TASKLIST_FILE"
    assert_contains 'local density = task_density_tier(screen)' "$TASKLIST_FILE"
    assert_contains 'local item_spacing = compact and 3 or 5' "$TASKLIST_FILE"
    assert_contains 'local item_h_padding = compact and 5 or 7' "$TASKLIST_FILE"
    assert_contains 'local item_v_padding = compact and 1 or 2' "$TASKLIST_FILE"
    assert_contains 'if density == "tight" then' "$TASKLIST_FILE"
    assert_contains 'item_spacing = compact and 2 or 3' "$TASKLIST_FILE"
    assert_contains 'item_h_padding = compact and 4 or 5' "$TASKLIST_FILE"
    assert_contains 'elseif density == "compact" then' "$TASKLIST_FILE"
    assert_contains 'item_spacing = compact and 3 or 4' "$TASKLIST_FILE"
    assert_contains 'item_h_padding = compact and 5 or 6' "$TASKLIST_FILE"
    assert_contains 'self._task_tooltip_text = render_task_tooltip(c)' "$TASKLIST_FILE"
    assert_contains 'if not self._task_tooltip then' "$TASKLIST_FILE"
    assert_contains 'objects = { self },' "$TASKLIST_FILE"
    assert_contains 'return self._task_tooltip_text or ""' "$TASKLIST_FILE"
    assert_contains 'img.forced_width = dpi(20)' "$TASKLIST_FILE"
    assert_contains 'img.forced_height = dpi(20)' "$TASKLIST_FILE"
    assert_contains 'spacing = dpi(3),' "$TASKLIST_FILE"
    assert_contains 'left = item_h_padding,' "$TASKLIST_FILE"
    assert_contains 'right = item_h_padding,' "$TASKLIST_FILE"
    assert_contains 'top = item_v_padding,' "$TASKLIST_FILE"
    assert_contains 'bottom = item_v_padding,' "$TASKLIST_FILE"
    assert_contains 'local function create_floating_wibar_content(ctpp, left_widgets, task_cluster, right_widgets)' "$WIBAR_FILE"
    assert_contains 'local task_cluster = {' "$WIBAR_FILE"
    assert_contains 's.mytaskoverflow = s.mytaskoverflow or tasklist.create_overflow_indicator(ctpp, s)' "$WIBAR_FILE"
    assert_contains 's.mytaskoverflow:update(available_width)' "$WIBAR_FILE"
    assert_contains 'gears.shape.rounded_rect(cr, w, h, dpi(12))' "$WIBAR_FILE"
    assert_contains 'local function setup_floating_wibar(s, ctpp, left_widgets, task_cluster, right_widgets)' "$WIBAR_FILE"
    assert_contains 'if not s.mywibox then' "$WIBAR_FILE"
    assert_contains 'height = dpi(40),' "$WIBAR_FILE"
    assert_contains 'bg = "#00000000",' "$WIBAR_FILE"
    assert_contains 'top = dpi(6),' "$WIBAR_FILE"
    assert_contains 'left = dpi(8),' "$WIBAR_FILE"
    assert_contains 'right = dpi(8),' "$WIBAR_FILE"
    assert_not_contains 'dpi(20, screen)' "$WIBAR_FILE"
    assert_contains 'local layout_label = {' "$WIBAR_FILE"
    assert_contains 'objects = { layoutbox },' "$WIBAR_FILE"
    assert_contains 'return "布局' "$WIBAR_FILE"
    assert_contains '当前：" .. (layout_label[layout_name] or layout_name)' "$WIBAR_FILE"
}

test_wibar_refreshes_after_screen_topology_changes() {
    assert_contains 'local function rebuild_screen_wibar(s)' "$WIBAR_FILE"
    assert_contains 'local function queue_wibar_refresh()' "$WIBAR_FILE"
    assert_contains 'gears.timer.delayed_call(function()' "$WIBAR_FILE"
    assert_contains 'for s in screen do' "$WIBAR_FILE"
    assert_contains 'rebuild_screen_wibar(s)' "$WIBAR_FILE"
    assert_contains 'screen.connect_signal("property::geometry", queue_wibar_refresh)' "$WIBAR_FILE"
    assert_contains 'screen.connect_signal("property::primary", queue_wibar_refresh)' "$WIBAR_FILE"
    assert_contains 'screen.connect_signal("added", queue_wibar_refresh)' "$WIBAR_FILE"
    assert_contains 'screen.connect_signal("removed", function(s)' "$WIBAR_FILE"
    assert_contains 'status_area.dispose_status_widgets(s)' "$WIBAR_FILE"
    assert_contains 'if s.mytextclock and s.mytextclock._dispose then' "$WIBAR_FILE"
    assert_contains 's.mytextclock._dispose()' "$WIBAR_FILE"
    assert_contains 's._omx_wibar_probe = nil' "$WIBAR_FILE"
    assert_contains 'queue_wibar_refresh()' "$WIBAR_FILE"
    assert_contains 'awesome.connect_signal("screen::change", queue_wibar_refresh)' "$WIBAR_FILE"
    assert_contains 's.mylockbutton = create_lock_button(ctpp, actions)' "$WIBAR_FILE"
    assert_contains 'if not s.mytextclock then' "$WIBAR_FILE"
    assert_contains 's.mytextclock._refresh()' "$WIBAR_FILE"
    assert_contains 'local desired_tasklist_width = tasklist.task_title_max_width(s, config, is_compact_screen(s, config))' "$WIBAR_FILE"
    assert_contains 'if not s.mytasklist or s.mytasklist_width ~= desired_tasklist_width then' "$WIBAR_FILE"
    assert_contains 's.mytasklist = tasklist.create_tasklist(ctpp, s, tasklist_buttons, config, is_compact_screen(s, config))' "$WIBAR_FILE"
    assert_contains 's.mytasklist_width = desired_tasklist_width' "$WIBAR_FILE"
    assert_not_contains 'local mytextclock = create_textclock(ctpp, config, s)' "$WIBAR_FILE"
}

test_wibar_exposes_hidden_probe_state_for_runtime_visibility_checks() {
    assert_contains 'local function count_sequence_items(tbl)' "$WIBAR_FILE"
    assert_contains 'local function widget_fit_size(widget, width, height)' "$WIBAR_FILE"
    assert_contains 'local function update_wibar_probe_state(s, left_widgets, tasklist_widget, right_widgets, config)' "$WIBAR_FILE"
    assert_contains 's._omx_wibar_probe = {' "$WIBAR_FILE"
    assert_contains 'snapshot = snapshot,' "$WIBAR_FILE"
    assert_contains 'last = snapshot(),' "$WIBAR_FILE"
    assert_contains 'tasklist_title_max_width = s.mytasklist_width,' "$WIBAR_FILE"
    assert_contains 'left_width = left_width,' "$WIBAR_FILE"
    assert_contains 'right_width = right_width,' "$WIBAR_FILE"
    assert_contains 'tasklist_width = tasklist_width,' "$WIBAR_FILE"
    assert_contains 'has_promptbox = s == screen.primary,' "$WIBAR_FILE"
    assert_contains 'update_wibar_probe_state(s, left_widgets, task_cluster, right_widgets, config)' "$WIBAR_FILE"
}

test_wibar_keeps_status_widgets_on_primary_only() {
    assert_contains 'if target_screen == screen.primary then' "$STATUS_AREA_FILE"
    assert_contains 'local status_bundle = ensure_primary_status_widgets(config, ctpp, target_screen, compact)' "$STATUS_AREA_FILE"
    assert_contains 'dispose_status_widgets(target_screen)' "$STATUS_AREA_FILE"
    assert_contains 'table.insert(right_widgets, sysinfo_widget)' "$STATUS_AREA_FILE"
    assert_contains 'local right_widget_data = status_area.create_right_widgets(config, ctpp, s, clock_widget)' "$WIBAR_FILE"
    assert_contains 'local right_widgets = right_widget_data.right_widgets' "$WIBAR_FILE"
    assert_not_contains 'local system_bundle = create_sysinfo_bundle(config, s)' "$WIBAR_FILE"

    python - "$STATUS_AREA_FILE" <<'PY' || fail "expected non-primary right side to only add the clock widget"
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text()
start = text.index("local function create_right_widgets")
end = text.index("\nreturn {", start)
chunk = text[start:end]
primary_marker = "if target_screen == screen.primary then"
else_marker = "else\n        dispose_status_widgets(target_screen)"
clock_marker = "clock_widget,"

before_primary = chunk[:chunk.index(primary_marker)]
primary_start = chunk.index(primary_marker)
else_start = chunk.index(else_marker)
clock_start = chunk.index(clock_marker)

assert "ensure_primary_status_widgets" not in before_primary
assert primary_start < clock_start
assert "table.insert(right_widgets, sysinfo_widget)" in chunk[primary_start:clock_start]
assert else_start < clock_start
assert "dispose_status_widgets(target_screen)" in chunk[else_start:clock_start]
PY
}

test_wibar_hides_lock_button_on_secondary_screens() {
    assert_contains 'if s == screen.primary then' "$WIBAR_FILE"
    assert_contains 'table.insert(left_widgets, s.mylockbutton)' "$WIBAR_FILE"
    assert_contains 'table.insert(left_widgets, status_area.create_separator(ctpp))' "$WIBAR_FILE"
    assert_contains 'table.insert(left_widgets, s.mypromptbox)' "$WIBAR_FILE"
    assert_contains 'spacing = s == screen.primary and dpi(4) or dpi(2),' "$WIBAR_FILE"
    assert_not_contains 'lock_button,' "$WIBAR_FILE"

    python - "$WIBAR_FILE" <<'PY' || fail "expected secondary left side to omit lock button, separator, and promptbox"
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text()
start = text.index("local function build_left_widgets")
end = text.index("\n    local function rebuild_screen_wibar", start)
chunk = text[start:end]

primary_marker = "if s == screen.primary then"
lock_marker = "table.insert(left_widgets, s.mylockbutton)"
separator_marker = "table.insert(left_widgets, status_area.create_separator(ctpp))"
prompt_marker = "table.insert(left_widgets, s.mypromptbox)"

assert primary_marker in chunk
primary_start = chunk.index(primary_marker)
lock_start = chunk.index(lock_marker)
separator_start = chunk.index(separator_marker)
prompt_start = chunk.index(prompt_marker)
assert primary_start < lock_start < separator_start < prompt_start
assert lock_marker in chunk[primary_start:separator_start]
assert separator_marker in chunk[primary_start:prompt_start]
assert prompt_marker in chunk[primary_start:]
PY
}

test_status_area_owns_compact_screen_policy() {
    assert_not_contains 'local function output_diagonal_inches(output)' "$WIBAR_FILE"
    assert_not_contains 'local function screen_diagonal_inches(screen)' "$WIBAR_FILE"
    assert_not_contains 'local function is_compact_screen(screen, config)' "$WIBAR_FILE"
    assert_contains 'is_compact_screen = is_compact_screen,' "$STATUS_AREA_FILE"
    assert_contains 'local is_compact_screen = assert(status_area.is_compact_screen)' "$WIBAR_FILE"
}

test_wibar_uses_physical_size_before_width_fallback() {
    lua - "$STATUS_AREA_FILE" <<'LUA' || fail "expected physical monitors larger than 15 inches to use full wibar mode"
local status_area_file = arg[1]

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

package.path = status_area_file:gsub("/ui/status_area%.lua$", "/?.lua;/?/init.lua") .. ";" .. package.path

local status_area = assert(loadfile(status_area_file))()
local is_compact_screen = assert(status_area.is_compact_screen)
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

test_wibar_scales_task_title_width_by_screen_size() {
    lua - "$WIBAR_FILE" <<'LUA' || fail "expected task title width to adapt to screen width"
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

package.path = wibar_file:gsub("/ui/wibar%.lua$", "/?.lua;/?/init.lua") .. ";" .. package.path

local wibar = assert(loadfile(wibar_file))()
local task_title_max_width = assert(wibar._private and wibar._private.task_title_max_width)
local config = {
    compact_wibar_max_width = 3000,
    compact_wibar_max_diagonal_inches = 15,
}

assert(task_title_max_width({ geometry = { width = 1366 }, outputs = {} }, config) == 220)
assert(task_title_max_width({ geometry = { width = 1920 }, outputs = { ["DP-1"] = { mm_width = 527, mm_height = 296 } } }, config) == 320)
assert(task_title_max_width({ geometry = { width = 2560 }, outputs = { ["DP-1"] = { mm_width = 527, mm_height = 296 } } }, config) == 410)
assert(task_title_max_width({ geometry = { width = 3840 }, outputs = { ["DP-1"] = { mm_width = 708, mm_height = 399 } } }, config) == 614)
LUA
}

test_wibar_escapes_task_titles() {
    assert_contains 'gears.string.xml_escape' "$TASKLIST_FILE"
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
    assert_not_contains 'require("lain")' "$SYSTEM_WIDGETS_FILE"
    assert_contains 'M._private = {' "$SYSTEM_WIDGETS_FILE"
    assert_contains 'local stop_timer = common.stop_timer' "$SYSTEM_WIDGETS_FILE"
    assert_contains 'local function dispose()' "$SYSTEM_WIDGETS_FILE"
    assert_contains 'dispose = dispose,' "$SYSTEM_WIDGETS_FILE"
    assert_contains 'stop_timer(details_timer)' "$SYSTEM_WIDGETS_FILE"
    assert_contains 'stop_timer(metrics_timer)' "$SYSTEM_WIDGETS_FILE"
    assert_contains 'stop_timer(net_timer)' "$SYSTEM_WIDGETS_FILE"
    assert_contains 'gears.shape.rounded_rect(cr, w, h, dpi(8))' "$SYSTEM_WIDGETS_FILE"
    assert_not_contains 'dpi(8, screen)' "$SYSTEM_WIDGETS_FILE"
}

test_modules_use_shared_common_helpers() {
    COMMON_FILE=$REPO_ROOT/.config/linux/awesome/lib/common.lua
    VOLUME_FILE=$REPO_ROOT/.config/linux/awesome/widgets/volume.lua

    [ -f "$COMMON_FILE" ] || fail "expected shared common helper module to exist"

    assert_contains 'local common = require("lib.common")' "$ACTIONS_FILE"
    assert_contains 'local truncate_message = common.truncate_message' "$ACTIONS_FILE"
    assert_contains 'local shell_quote = common.shell_quote' "$ACTIONS_FILE"
    assert_not_contains 'local function truncate_message(text)' "$ACTIONS_FILE"
    assert_not_contains 'local function shell_quote(value)' "$ACTIONS_FILE"

    assert_contains 'local common = require("lib.common")' "$BRIGHTNESS_FILE"
    assert_contains 'local read_command_output = common.read_command_output' "$BRIGHTNESS_FILE"
    assert_contains 'local command_exists = common.command_exists' "$BRIGHTNESS_FILE"
    assert_contains 'local stop_timer = common.stop_timer' "$BRIGHTNESS_FILE"
    assert_contains 'local truncate_message = common.truncate_message' "$BRIGHTNESS_FILE"
    assert_contains 'local shell_quote = common.shell_quote' "$BRIGHTNESS_FILE"
    assert_not_contains 'local function read_command_output(command)' "$BRIGHTNESS_FILE"
    assert_not_contains 'local function command_exists(command)' "$BRIGHTNESS_FILE"
    assert_not_contains 'local function stop_timer(timer)' "$BRIGHTNESS_FILE"
    assert_not_contains 'local function truncate_message(text)' "$BRIGHTNESS_FILE"
    assert_not_contains 'local function shell_quote(value)' "$BRIGHTNESS_FILE"

    assert_contains 'local common = require("lib.common")' "$SYSTEM_WIDGETS_FILE"
    assert_contains 'local stop_timer = common.stop_timer' "$SYSTEM_WIDGETS_FILE"
    assert_not_contains 'local function stop_timer(timer)' "$SYSTEM_WIDGETS_FILE"

    assert_contains 'local common = require("lib.common")' "$VOLUME_FILE"
    assert_contains 'local stop_timer = common.stop_timer' "$VOLUME_FILE"
    assert_contains 'local truncate_message = common.truncate_message' "$VOLUME_FILE"
    assert_not_contains 'local function stop_timer(timer)' "$VOLUME_FILE"
    assert_not_contains 'local function truncate_message(text)' "$VOLUME_FILE"
}

test_wibar_status_spec_accounts_for_brightness_and_volume() {
    assert_contains 'local spec = table.concat({' "$STATUS_AREA_FILE"
    assert_contains 'compact and "compact" or "full",' "$STATUS_AREA_FILE"
    assert_contains 'config.has_volume and "vol" or "novol",' "$STATUS_AREA_FILE"
    assert_contains 'config.has_brightness and "bri" or "nobri",' "$STATUS_AREA_FILE"
    assert_contains '}, ":")' "$STATUS_AREA_FILE"
}

test_volume_widget_uses_relaxed_background_polling() {
    VOLUME_FILE=$REPO_ROOT/.config/linux/awesome/widgets/volume.lua
    assert_contains 'local refresh_timer = gears.timer {' "$VOLUME_FILE"
    assert_contains 'timeout = 10,' "$VOLUME_FILE"
    assert_contains 'local refresh_delays = { 0.15, 0.5, 1.2 }' "$VOLUME_FILE"
}

test_actions_module_exists
test_rc_wires_shared_modules
test_rc_no_longer_builds_bar_widgets_locally
test_rc_refreshes_runtime_display_layout_on_screen_topology_changes
test_bindings_use_injected_prompt_runners
test_bindings_keep_lock_on_mod_shift_l
test_bindings_leave_bare_f1_to_snipaste
test_bindings_do_not_duplicate_shortcuts
test_bindings_use_shared_occupied_tag_helper
test_client_module_is_split_into_focused_submodules
test_client_rules_use_data_driven_policy_lists
test_actions_check_prerequisites_and_notify_failures
test_volume_widget_uses_lower_idle_polling
test_brightness_widget_uses_lower_idle_polling
test_volume_widget_does_not_switch_to_event_subscription
test_tasklist_switches_to_icon_only_mode_at_high_density
test_tasklist_exposes_overflow_indicator_support
test_tasklist_hidden_count_uses_layout_budget
test_tasklist_slot_width_prefers_measured_fit
test_tasklist_icon_only_threshold_uses_budget_pressure
test_tasklist_live_available_width_reaches_update_path
test_tasklist_overflow_indicator_uses_lighter_visual_weight
test_wibar_uses_task_density_tiers
test_wibar_task_title_width_depends_on_density
test_wibar_owns_bar_widget_creation
test_wibar_refreshes_after_screen_topology_changes
test_wibar_exposes_hidden_probe_state_for_runtime_visibility_checks
test_wibar_keeps_status_widgets_on_primary_only
test_wibar_hides_lock_button_on_secondary_screens
test_status_area_owns_compact_screen_policy
test_wibar_uses_physical_size_before_width_fallback
test_wibar_scales_task_title_width_by_screen_size
test_wibar_escapes_task_titles
test_wibar_exposes_prompt_runners
test_wibar_avoids_container_insert_on_sysinfo_widget
test_system_widget_exposes_row_for_extension
test_modules_use_shared_common_helpers
test_wibar_status_spec_accounts_for_brightness_and_volume
test_volume_widget_uses_relaxed_background_polling

printf 'PASS: awesome ui architecture tests\n'
