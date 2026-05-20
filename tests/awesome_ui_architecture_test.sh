#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
RC_FILE=$REPO_ROOT/.config/linux/awesome/rc.lua
BINDINGS_FILE=$REPO_ROOT/.config/linux/awesome/bindings.lua
WIBAR_FILE=$REPO_ROOT/.config/linux/awesome/ui/wibar.lua
ACTIONS_FILE=$REPO_ROOT/.config/linux/awesome/actions.lua
SYSTEM_WIDGETS_FILE=$REPO_ROOT/.config/linux/awesome/widgets/system.lua
BRIGHTNESS_FILE=$REPO_ROOT/.config/linux/awesome/widgets/brightness.lua
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
    assert_contains 'local function is_compact_screen(screen, config)' "$WIBAR_FILE"
    assert_contains 'local function screen_diagonal_inches(screen)' "$WIBAR_FILE"
    assert_contains 'local function create_lock_button(ctpp, actions)' "$WIBAR_FILE"
    assert_contains 'objects = { lock_button },' "$WIBAR_FILE"
    assert_contains 'return "锁屏' "$WIBAR_FILE"
    assert_contains '操作：立即锁屏' "$WIBAR_FILE"
    assert_contains '快捷键：Super+Shift+L' "$WIBAR_FILE"
    assert_contains 'local function create_textclock(ctpp, config, screen)' "$WIBAR_FILE"
    assert_contains 'local function stop_timer(timer)' "$WIBAR_FILE"
    assert_contains 'local function update_clock()' "$WIBAR_FILE"
    assert_contains 'local clock_timer = gears.timer {' "$WIBAR_FILE"
    assert_contains 'local clock_h_padding = is_compact_screen(screen, config) and 5 or 6' "$WIBAR_FILE"
    assert_contains 'local clock_v_padding = is_compact_screen(screen, config) and 1 or 2' "$WIBAR_FILE"
    assert_contains 'local clock_widget = wibox.widget {' "$WIBAR_FILE"
    assert_contains 'clock_widget._refresh = update_clock' "$WIBAR_FILE"
    assert_contains 'clock_widget._dispose = dispose' "$WIBAR_FILE"
    assert_contains 'bg = ctpp.mantle,' "$WIBAR_FILE"
    assert_contains 'border_color = ctpp.surface1,' "$WIBAR_FILE"
    assert_contains 'local function render_clock_tooltip()' "$WIBAR_FILE"
    assert_contains '日期：' "$WIBAR_FILE"
    assert_contains '星期：' "$WIBAR_FILE"
    assert_contains '当前：' "$WIBAR_FILE"
    assert_contains 'objects = { clock_widget },' "$WIBAR_FILE"
    assert_contains 'return render_clock_tooltip()' "$WIBAR_FILE"
    assert_not_contains 'awful.widget.calendar_popup.month {' "$WIBAR_FILE"
    assert_not_contains 'clock_widget:buttons(clock_buttons)' "$WIBAR_FILE"
    assert_not_contains 'textclock:buttons(clock_buttons)' "$WIBAR_FILE"
    assert_not_contains 'local clock_buttons = gears.table.join(' "$WIBAR_FILE"
    assert_not_contains 'month_calendar:connect_signal' "$WIBAR_FILE"
    assert_not_contains 'show_calendar(' "$WIBAR_FILE"
    assert_contains 'local function create_systray_widget(ctpp)' "$WIBAR_FILE"
    assert_contains 'left = 4,' "$WIBAR_FILE"
    assert_contains 'right = 4,' "$WIBAR_FILE"
    assert_contains 'top = 2,' "$WIBAR_FILE"
    assert_contains 'bottom = 2,' "$WIBAR_FILE"
    assert_contains 'local function create_separator(ctpp)' "$WIBAR_FILE"
    assert_contains 'local function create_sysinfo_bundle(config, screen, compact)' "$WIBAR_FILE"
    assert_contains 'compact = compact == nil and is_compact_screen(screen, config) or compact' "$WIBAR_FILE"
    assert_contains 'local brightness_bundle = nil' "$WIBAR_FILE"
    assert_contains 'if config.has_brightness then' "$WIBAR_FILE"
    assert_contains 'brightness_bundle = require("widgets.brightness").create({' "$WIBAR_FILE"
    assert_contains 'if brightness_bundle then' "$WIBAR_FILE"
    assert_contains 'brightness_bundle.widget' "$WIBAR_FILE"
    assert_contains 'brightness_bundle.dispose()' "$WIBAR_FILE"
    assert_contains 'local function dispose_status_widgets(s)' "$WIBAR_FILE"
    assert_contains 'local function ensure_primary_status_widgets(config, ctpp, s, compact)' "$WIBAR_FILE"
    assert_contains 'if s.mystatusbundle and s.mystatusspec == spec then' "$WIBAR_FILE"
    assert_contains 's.mystatusbundle = {' "$WIBAR_FILE"
    assert_contains 's.mystatusspec = spec' "$WIBAR_FILE"
    assert_contains 'local function create_right_widgets(config, ctpp, target_screen, clock_widget)' "$WIBAR_FILE"
    assert_contains 'compact = compact == nil and is_compact_screen(screen, config) or compact' "$WIBAR_FILE"
    assert_contains 'compact = compact,' "$WIBAR_FILE"
    assert_contains 'spacing = compact and 2 or 4,' "$WIBAR_FILE"
    assert_not_contains 'configure_screen_dpi(s, config)' "$WIBAR_FILE"
    assert_contains 'systray:set_base_size(dpi(20))' "$WIBAR_FILE"
    assert_contains 'border_color = ctpp.surface1,' "$WIBAR_FILE"
    assert_contains 'id = "focus_indicator_role",' "$WIBAR_FILE"
    assert_contains 'id = "background_role",' "$WIBAR_FILE"
    assert_contains 'local function update_task_item(self, c, ctpp, screen, config)' "$WIBAR_FILE"
    assert_contains 'local function render_task_tooltip(c)' "$WIBAR_FILE"
    assert_contains 'local lines = { "窗口", "标题：" .. title }' "$WIBAR_FILE"
    assert_contains 'local function task_title_max_width(screen, config)' "$WIBAR_FILE"
    assert_contains 'layout = wibox.layout.fixed.horizontal,' "$WIBAR_FILE"
    assert_contains 'ellipsize = "end",' "$WIBAR_FILE"
    assert_contains 'id = "text_constraint_role",' "$WIBAR_FILE"
    assert_contains 'strategy = "max",' "$WIBAR_FILE"
    assert_contains 'width = task_title_max_width(screen, config),' "$WIBAR_FILE"
    assert_contains 'local item_spacing = is_compact_screen(screen, config) and 4 or 6' "$WIBAR_FILE"
    assert_contains 'local item_h_padding = is_compact_screen(screen, config) and 6 or 8' "$WIBAR_FILE"
    assert_contains 'local item_v_padding = is_compact_screen(screen, config) and 1 or 2' "$WIBAR_FILE"
    assert_contains 'self._task_tooltip_text = render_task_tooltip(c)' "$WIBAR_FILE"
    assert_contains 'if not self._task_tooltip then' "$WIBAR_FILE"
    assert_contains 'objects = { self },' "$WIBAR_FILE"
    assert_contains 'return self._task_tooltip_text or ""' "$WIBAR_FILE"
    assert_contains 'img.forced_width = dpi(20)' "$WIBAR_FILE"
    assert_contains 'img.forced_height = dpi(20)' "$WIBAR_FILE"
    assert_contains 'spacing = dpi(3),' "$WIBAR_FILE"
    assert_contains 'left = item_h_padding,' "$WIBAR_FILE"
    assert_contains 'right = item_h_padding,' "$WIBAR_FILE"
    assert_contains 'top = item_v_padding,' "$WIBAR_FILE"
    assert_contains 'bottom = item_v_padding,' "$WIBAR_FILE"
    assert_contains 'local function create_floating_wibar_content(ctpp, left_widgets, tasklist_widget, right_widgets)' "$WIBAR_FILE"
    assert_contains 'gears.shape.rounded_rect(cr, w, h, dpi(12))' "$WIBAR_FILE"
    assert_contains 'local function setup_floating_wibar(s, ctpp, left_widgets, tasklist_widget, right_widgets)' "$WIBAR_FILE"
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
    assert_contains 'dispose_status_widgets(s)' "$WIBAR_FILE"
    assert_contains 'if s.mytextclock and s.mytextclock._dispose then' "$WIBAR_FILE"
    assert_contains 's.mytextclock._dispose()' "$WIBAR_FILE"
    assert_contains 's._omx_wibar_probe = nil' "$WIBAR_FILE"
    assert_contains 'queue_wibar_refresh()' "$WIBAR_FILE"
    assert_contains 'awesome.connect_signal("screen::change", queue_wibar_refresh)' "$WIBAR_FILE"
    assert_contains 's.mylockbutton = create_lock_button(ctpp, actions)' "$WIBAR_FILE"
    assert_contains 'if not s.mytextclock then' "$WIBAR_FILE"
    assert_contains 's.mytextclock._refresh()' "$WIBAR_FILE"
    assert_contains 'local desired_tasklist_width = task_title_max_width(s, config)' "$WIBAR_FILE"
    assert_contains 'if not s.mytasklist or s.mytasklist_width ~= desired_tasklist_width then' "$WIBAR_FILE"
    assert_contains 's.mytasklist = create_tasklist(ctpp, s, tasklist_buttons, config)' "$WIBAR_FILE"
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
    assert_contains 'update_wibar_probe_state(s, left_widgets, s.mytasklist, right_widgets, config)' "$WIBAR_FILE"
}

test_wibar_keeps_status_widgets_on_primary_only() {
    assert_contains 'if target_screen == screen.primary then' "$WIBAR_FILE"
    assert_contains 'local status_bundle = ensure_primary_status_widgets(config, ctpp, target_screen, compact)' "$WIBAR_FILE"
    assert_contains 'dispose_status_widgets(target_screen)' "$WIBAR_FILE"
    assert_contains 'table.insert(right_widgets, sysinfo_widget)' "$WIBAR_FILE"
    assert_contains 'local right_bundle = create_right_widgets(config, ctpp, s, s.mytextclock)' "$WIBAR_FILE"
    assert_contains 'local right_widgets = right_bundle.right_widgets' "$WIBAR_FILE"
    assert_not_contains 'local system_bundle = create_sysinfo_bundle(config, s)' "$WIBAR_FILE"

    python - "$WIBAR_FILE" <<'PY' || fail "expected non-primary right side to only add the clock widget"
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text()
start = text.index("local function create_right_widgets")
end = text.index("\nlocal function create_layoutbox", start)
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
    assert_contains 'table.insert(left_widgets, create_separator(ctpp))' "$WIBAR_FILE"
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
separator_marker = "table.insert(left_widgets, create_separator(ctpp))"
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
    assert_contains 'local spec = table.concat({' "$WIBAR_FILE"
    assert_contains 'compact and "compact" or "full",' "$WIBAR_FILE"
    assert_contains 'config.has_volume and "vol" or "novol",' "$WIBAR_FILE"
    assert_contains 'config.has_brightness and "bri" or "nobri",' "$WIBAR_FILE"
    assert_contains '}, ":")' "$WIBAR_FILE"
}

test_volume_widget_uses_relaxed_background_polling() {
    VOLUME_FILE=$REPO_ROOT/.config/linux/awesome/widgets/volume.lua
    assert_contains 'local refresh_timer = gears.timer {' "$VOLUME_FILE"
    assert_contains 'timeout = 5,' "$VOLUME_FILE"
    assert_contains 'local refresh_delays = { 0.15, 0.5, 1.2 }' "$VOLUME_FILE"
}

test_readme_documents_current_awesome_modules() {
    assert_contains 'actions.lua' "$README_FILE"
    assert_contains 'bindings.lua' "$README_FILE"
    assert_contains 'client.lua' "$README_FILE"
    assert_contains 'menu.lua' "$README_FILE"
    assert_contains 'autostart.sh' "$README_FILE"
    assert_contains 'ui/wibar.lua' "$README_FILE"
    assert_contains 'widgets/system.lua' "$README_FILE"
    assert_contains 'widgets/brightness.lua' "$README_FILE"
    assert_contains 'widgets/volume.lua' "$README_FILE"
    assert_contains 'CPU/MEM 直接读取 `/proc/stat` 与 `/proc/meminfo`' "$README_FILE"
    assert_contains 'aarch64/arm64 的笔记本 Awesome 配置会额外启用 BRI' "$README_FILE"
    assert_contains '直接读取 `/sys/class/backlight`' "$README_FILE"
    assert_contains '可选外部依赖' "$README_FILE"
    assert_not_contains 'git clone https://github.com/lcpz/lain.git' "$README_FILE"
}

test_readme_documents_wibar_visual_tuning() {
    assert_contains '聚焦窗口会使用圆角背景、蓝色文字和左侧细条高亮' "$README_FILE"
    assert_contains '只有主屏显示 NET / CPU / MEM / BAT / VOL 与系统托盘' "$README_FILE"
    assert_contains '其他屏幕右侧只保留时钟' "$README_FILE"
    assert_contains '次屏左侧只保留标签与布局' "$README_FILE"
    assert_contains '锁屏按钮悬浮会提示用途' "$README_FILE"
    assert_contains '布局指示器悬浮会提示当前布局和切换方式' "$README_FILE"
    assert_contains 'lock / layout / tasklist 的 tooltip 文案也统一成标题 + 字段行' "$README_FILE"
    assert_contains '主屏右侧状态区会继续统一收紧 spacing' "$README_FILE"
    assert_contains 'sysinfo / clock / systray 的胶囊权重会一起再压一档' "$README_FILE"
    assert_contains 'sysinfo / clock / systray 的胶囊权重会一起再压一档' "$README_FILE"
    assert_contains '托盘只放在主屏，并使用更小图标、深色胶囊背景和细边框' "$README_FILE"
    assert_contains '只在 Linux aarch64/arm64 的 Awesome 配置里尝试启用' "$README_FILE"
    assert_contains '只有检测到背光设备时才显示' "$README_FILE"
    assert_contains '全量模式使用 `CPU/MEM/BAT/VOL` 完整标签' "$README_FILE"
    assert_contains '外接屏热插拔、`xrandr` 改变几何或主屏切换后' "$README_FILE"
    assert_contains '重新判断主屏状态区和 full/compact 模式' "$README_FILE"
    assert_contains '时钟使用独立胶囊背景作为右端视觉终点' "$README_FILE"
    assert_contains '整条顶栏使用悬浮圆角容器' "$README_FILE"
    assert_contains '顶部留出少量空隙' "$README_FILE"
    assert_contains '长窗口标题会在单个任务项内尾部省略' "$README_FILE"
    assert_contains 'tasklist 项在 compact 屏上也会进一步收紧 padding 与 item spacing' "$README_FILE"
    assert_contains 'NET 保持短显示，悬停时显示网卡接口名和带 `/s` 单位的上下行速率' "$README_FILE"
    assert_contains 'NET/CPU/MEM 不绑定点击动作，只在鼠标悬浮时显示内置 detail' "$README_FILE"
    assert_contains '找不到匹配接口时主栏显示 `NET:N/A` 且 hover 显示离线' "$README_FILE"
    assert_contains 'NET/CPU/MEM/VOL/BAT 的 tooltip 使用统一中文文案' "$README_FILE"
    assert_contains 'CPU/MEM detail 使用各自精简内容' "$README_FILE"
    assert_contains 'CPU 显示 CPU 使用率、负载（load average）和 top CPU 进程' "$README_FILE"
    assert_contains 'MEM 显示内存使用率和 top MEM 进程' "$README_FILE"
    assert_contains 'BAT hover 显示充放电状态、当前电量、功率和可估算的剩余/充满时间' "$README_FILE"
    assert_contains '检测到多个电池时会聚合成一个 BAT 读数' "$README_FILE"
    assert_contains '在 Linux aarch64/arm64 且检测到背光设备时，BRI hover 会显示当前亮度百分比、背光设备名与原始亮度值' "$README_FILE"
    assert_contains '安装 `brightnessctl` 且当前用户对背光设备有写权限时，可在 BRI 上用滚轮加减亮度' "$README_FILE"
    assert_contains '未安装时滚轮会提示缺少 `brightnessctl` 并给出安装命令' "$README_FILE"
    assert_contains '若 `brightnessctl` 已安装但当前用户没有写权限，则会提示把用户加入对应设备组' "$README_FILE"
    assert_contains '使用 5 秒后台缓存，hover 时不临时执行 `ps`' "$README_FILE"
    assert_contains '右键 VOL 会尝试打开 `pavucontrol`' "$README_FILE"
    assert_contains '缺少 `pavucontrol` 或启动失败时会提示' "$README_FILE"
    assert_contains '静音后只显示 `MUTE`' "$README_FILE"
    assert_contains '悬浮 VOL 会提示左键/右键/滚轮的具体作用' "$README_FILE"
    assert_contains '时钟不绑定点击或滚轮动作' "$README_FILE"
    assert_contains '悬浮时显示完整日期、星期和时间' "$README_FILE"
    assert_contains '执行 Rofi、Dolphin、截图 OCR 与锁屏前检查关键命令或脚本是否可用' "$README_FILE"
    assert_contains '缺少依赖或执行失败时会通过 Awesome 通知提示' "$README_FILE"
}

test_theme_exposes_fallback_titlebar_tokens() {
    THEME_FILE=$REPO_ROOT/.config/linux/awesome/theme/catppuccin.lua
    THEME_README_FILE=$REPO_ROOT/.config/linux/awesome/theme/README.md

    assert_contains 'theme.titlebar_size = dpi(26)' "$THEME_FILE"
    assert_contains 'theme.titlebar_radius = dpi(8)' "$THEME_FILE"
    assert_contains 'theme.titlebar_spacing = dpi(3)' "$THEME_FILE"
    assert_contains 'theme.titlebar_bg_normal = palette.mantle' "$THEME_FILE"
    assert_contains 'theme.titlebar_bg_focus = palette.surface0' "$THEME_FILE"
    assert_contains 'theme.titlebar_fg_normal = palette.subtext0' "$THEME_FILE"
    assert_contains 'theme.titlebar_fg_focus = palette.text' "$THEME_FILE"
    assert_contains 'theme.titlebar_font = "Maple Mono NF CN 10.5"' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_font = "Maple Mono NF CN 10.5"' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_radius = dpi(6)' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_bg_active = palette.surface1' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_fg_active = palette.blue' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_bg_close = palette.base' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_fg_close = palette.red' "$THEME_FILE"
    assert_contains '回退标题栏' "$THEME_README_FILE"
    assert_contains 'titlebar_bg_*' "$THEME_README_FILE"
    assert_contains 'titlebar_button_*' "$THEME_README_FILE"
}

test_readme_documents_snipaste_f1_conflict() {
    assert_contains 'Snipaste 自己接管裸 `F1` 截图；Awesome 不绑定 `F1`' "$README_FILE"
    assert_contains '[org.flameshot.Flameshot.desktop]' "$README_FILE"
    assert_contains 'Capture` 应为 `none,none,进行截图`' "$README_FILE"
    assert_contains 'Unable to register global hotkey' "$README_FILE"
}

test_readme_documents_plain_i3lock_theme_fallback() {
    assert_contains 'i3lock-catppuccin-<宽>x<高>-<布局>.png' "$README_FILE"
    assert_contains '普通 `i3lock` 路径没有真实模糊/时钟能力' "$README_FILE"
    assert_contains '在每个屏幕中心各画一份卡片/锁图标' "$README_FILE"
    assert_contains '生成失败时才降级到纯色 `i3lock -n -e -f -c 11111b`' "$README_FILE"
}

test_actions_module_exists
test_rc_wires_shared_modules
test_rc_no_longer_builds_bar_widgets_locally
test_rc_refreshes_runtime_display_layout_on_screen_topology_changes
test_bindings_use_injected_prompt_runners
test_bindings_keep_lock_on_mod_shift_l
test_bindings_leave_bare_f1_to_snipaste
test_bindings_do_not_duplicate_shortcuts
test_actions_check_prerequisites_and_notify_failures
test_wibar_owns_bar_widget_creation
test_wibar_refreshes_after_screen_topology_changes
test_wibar_exposes_hidden_probe_state_for_runtime_visibility_checks
test_wibar_keeps_status_widgets_on_primary_only
test_wibar_hides_lock_button_on_secondary_screens
test_wibar_uses_physical_size_before_width_fallback
test_wibar_scales_task_title_width_by_screen_size
test_wibar_escapes_task_titles
test_wibar_exposes_prompt_runners
test_wibar_avoids_container_insert_on_sysinfo_widget
test_system_widget_exposes_row_for_extension
test_modules_use_shared_common_helpers
test_wibar_status_spec_accounts_for_brightness_and_volume
test_volume_widget_uses_relaxed_background_polling
test_readme_documents_current_awesome_modules
test_readme_documents_wibar_visual_tuning
test_theme_exposes_fallback_titlebar_tokens
test_readme_documents_snipaste_f1_conflict
test_readme_documents_plain_i3lock_theme_fallback

printf 'PASS: awesome ui architecture tests\n'
