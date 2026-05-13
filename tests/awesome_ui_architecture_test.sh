#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
RC_FILE=$REPO_ROOT/.config/linux/awesome/rc.lua
BINDINGS_FILE=$REPO_ROOT/.config/linux/awesome/bindings.lua
WIBAR_FILE=$REPO_ROOT/.config/linux/awesome/ui/wibar.lua
ACTIONS_FILE=$REPO_ROOT/.config/linux/awesome/actions.lua
SYSTEM_WIDGETS_FILE=$REPO_ROOT/.config/linux/awesome/widgets/system.lua
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
    assert_contains 'lain_ok = lain_ok,' "$RC_FILE"
    assert_contains 'terminal = terminal,' "$RC_FILE"
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

test_wibar_owns_bar_widget_creation() {
    assert_contains 'local config = args.config' "$WIBAR_FILE"
    assert_contains 'local actions = args.actions or {}' "$WIBAR_FILE"
    assert_contains 'local terminal = args.terminal or "alacritty"' "$WIBAR_FILE"
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
    assert_contains 'local clock_widget = wibox.widget {' "$WIBAR_FILE"
    assert_contains 'bg = ctpp.mantle,' "$WIBAR_FILE"
    assert_contains 'border_color = ctpp.surface1,' "$WIBAR_FILE"
    assert_contains 'local function render_clock_tooltip()' "$WIBAR_FILE"
    assert_contains '日期：' "$WIBAR_FILE"
    assert_contains '星期：' "$WIBAR_FILE"
    assert_contains '时间：' "$WIBAR_FILE"
    assert_contains 'objects = { clock_widget },' "$WIBAR_FILE"
    assert_contains 'return render_clock_tooltip()' "$WIBAR_FILE"
    assert_not_contains 'awful.widget.calendar_popup.month {' "$WIBAR_FILE"
    assert_not_contains 'clock_widget:buttons(clock_buttons)' "$WIBAR_FILE"
    assert_not_contains 'textclock:buttons(clock_buttons)' "$WIBAR_FILE"
    assert_not_contains 'local clock_buttons = gears.table.join(' "$WIBAR_FILE"
    assert_not_contains 'month_calendar:connect_signal' "$WIBAR_FILE"
    assert_not_contains 'show_calendar(' "$WIBAR_FILE"
    assert_contains 'local function create_systray_widget(ctpp)' "$WIBAR_FILE"
    assert_contains 'local function create_separator(ctpp)' "$WIBAR_FILE"
    assert_contains 'local function create_sysinfo_bundle(config, ctpp, lain_ok, screen, terminal)' "$WIBAR_FILE"
    assert_contains 'local function create_right_widgets(config, ctpp, lain_ok, target_screen, terminal, clock_widget)' "$WIBAR_FILE"
    assert_contains 'compact = is_compact_screen(screen, config),' "$WIBAR_FILE"
    assert_contains 'compact = compact,' "$WIBAR_FILE"
    assert_not_contains 'configure_screen_dpi(s, config)' "$WIBAR_FILE"
    assert_contains 'systray:set_base_size(dpi(20))' "$WIBAR_FILE"
    assert_contains 'border_color = ctpp.surface1,' "$WIBAR_FILE"
    assert_contains 'id = "focus_indicator_role",' "$WIBAR_FILE"
    assert_contains 'id = "background_role",' "$WIBAR_FILE"
    assert_contains 'local function update_task_item(self, c, ctpp)' "$WIBAR_FILE"
    assert_contains 'layout = wibox.layout.fixed.horizontal,' "$WIBAR_FILE"
    assert_contains 'ellipsize = "end",' "$WIBAR_FILE"
    assert_contains 'strategy = "max",' "$WIBAR_FILE"
    assert_contains 'width = dpi(420),' "$WIBAR_FILE"
    assert_contains 'img.forced_width = dpi(20)' "$WIBAR_FILE"
    assert_contains 'img.forced_height = dpi(20)' "$WIBAR_FILE"
    assert_not_contains 'dpi(20, screen)' "$WIBAR_FILE"
}

test_wibar_keeps_status_widgets_on_primary_only() {
    assert_contains 'if target_screen == screen.primary then' "$WIBAR_FILE"
    assert_contains 'local system_bundle = create_sysinfo_bundle(config, ctpp, lain_ok, target_screen, terminal)' "$WIBAR_FILE"
    assert_contains 'local systray_widget = create_systray_widget(ctpp)' "$WIBAR_FILE"
    assert_contains 'table.insert(right_widgets, sysinfo_widget)' "$WIBAR_FILE"
    assert_contains 'local right_bundle = create_right_widgets(config, ctpp, lain_ok, s, terminal, mytextclock)' "$WIBAR_FILE"
    assert_contains 'local right_widgets = right_bundle.right_widgets' "$WIBAR_FILE"
    assert_not_contains 'local system_bundle = create_sysinfo_bundle(config, ctpp, lain_ok, s, terminal)' "$WIBAR_FILE"

    python - "$WIBAR_FILE" <<'PY' || fail "expected non-primary right side to only add the clock widget"
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text()
start = text.index("local function create_right_widgets")
end = text.index("\nlocal function create_layoutbox", start)
chunk = text[start:end]
primary_marker = "if target_screen == screen.primary then"
clock_marker = "clock_widget,"

before_primary = chunk[:chunk.index(primary_marker)]
primary_start = chunk.index(primary_marker)
clock_start = chunk.index(clock_marker)

assert "create_sysinfo_bundle" not in before_primary
assert "create_systray_widget" not in before_primary
assert primary_start < clock_start
assert "table.insert(right_widgets, sysinfo_widget)" in chunk[primary_start:clock_start]
assert "create_systray_widget(ctpp)" in chunk[primary_start:clock_start]
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

test_readme_documents_current_awesome_modules() {
    assert_contains 'actions.lua' "$README_FILE"
    assert_contains 'bindings.lua' "$README_FILE"
    assert_contains 'client.lua' "$README_FILE"
    assert_contains 'menu.lua' "$README_FILE"
    assert_contains 'autostart.sh' "$README_FILE"
    assert_contains 'ui/wibar.lua' "$README_FILE"
    assert_contains 'widgets/system.lua' "$README_FILE"
    assert_contains 'widgets/volume.lua' "$README_FILE"
}

test_readme_documents_wibar_visual_tuning() {
    assert_contains '聚焦窗口会使用圆角背景、蓝色文字和左侧细条高亮' "$README_FILE"
    assert_contains '只有主屏显示 NET / CPU / MEM / BAT / VOL 与系统托盘' "$README_FILE"
    assert_contains '其他屏幕右侧只保留时钟' "$README_FILE"
    assert_contains '托盘只放在主屏，并使用更小图标、深色胶囊背景和细边框' "$README_FILE"
    assert_contains '全量模式使用 `CPU/MEM/BAT/VOL` 完整标签' "$README_FILE"
    assert_contains '时钟使用独立胶囊背景作为右端视觉终点' "$README_FILE"
    assert_contains '长窗口标题会在单个任务项内尾部省略' "$README_FILE"
    assert_contains 'NET 保持短显示，悬停时显示网卡接口名和带 `/s` 单位的上下行速率' "$README_FILE"
    assert_contains 'NET/CPU/MEM 不绑定点击动作，只在鼠标悬浮时显示内置 detail' "$README_FILE"
    assert_contains '找不到匹配接口时主栏显示 `NET:N/A` 且 hover 显示离线' "$README_FILE"
    assert_contains 'NET/CPU/MEM/VOL/BAT 的 tooltip 使用统一中文文案' "$README_FILE"
    assert_contains 'CPU/MEM detail 使用各自精简内容' "$README_FILE"
    assert_contains 'CPU 显示 CPU 使用率、负载（load average）和 top CPU 进程' "$README_FILE"
    assert_contains 'MEM 显示内存使用率和 top MEM 进程' "$README_FILE"
    assert_contains 'BAT hover 显示充放电状态、当前电量、功率和可估算的剩余/充满时间' "$README_FILE"
    assert_contains '使用 5 秒后台缓存，hover 时不临时执行 `ps`' "$README_FILE"
    assert_contains '右键 VOL 会打开 `pavucontrol`' "$README_FILE"
    assert_contains '静音后只显示 `MUTE`' "$README_FILE"
    assert_contains '悬浮 VOL 会提示左键/右键/滚轮的具体作用' "$README_FILE"
    assert_contains '时钟不绑定点击或滚轮动作' "$README_FILE"
    assert_contains '悬浮时显示完整日期、星期和时间' "$README_FILE"
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
test_bindings_use_injected_prompt_runners
test_bindings_keep_lock_on_mod_shift_l
test_bindings_leave_bare_f1_to_snipaste
test_bindings_do_not_duplicate_shortcuts
test_wibar_owns_bar_widget_creation
test_wibar_keeps_status_widgets_on_primary_only
test_wibar_uses_physical_size_before_width_fallback
test_wibar_escapes_task_titles
test_wibar_exposes_prompt_runners
test_wibar_avoids_container_insert_on_sysinfo_widget
test_system_widget_exposes_row_for_extension
test_readme_documents_current_awesome_modules
test_readme_documents_wibar_visual_tuning
test_readme_documents_snipaste_f1_conflict
test_readme_documents_plain_i3lock_theme_fallback

printf 'PASS: awesome ui architecture tests\n'
