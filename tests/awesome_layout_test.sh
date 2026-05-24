#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CLIENT_FILE=$REPO_ROOT/.config/linux/awesome/client.lua
CLIENT_RULES_FILE=$REPO_ROOT/.config/linux/awesome/client/rules.lua
CLIENT_DECORATIONS_FILE=$REPO_ROOT/.config/linux/awesome/client/decorations.lua
CLIENT_POLICIES_FILE=$REPO_ROOT/.config/linux/awesome/client/policies.lua
BINDINGS_FILE=$REPO_ROOT/.config/linux/awesome/bindings.lua
RC_FILE=$REPO_ROOT/.config/linux/awesome/rc.lua
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

test_default_layout_is_tile_left() {
    assert_contains 'awful.layout.suit.tile.left,' "$RC_FILE"
}

test_layout_keys_still_adjust_master_width_factor() {
    assert_contains 'awful.tag.incmwfact(0.05)' "$BINDINGS_FILE"
    assert_contains 'awful.tag.incmwfact(-0.05)' "$BINDINGS_FILE"
}

test_layout_keys_do_not_adjust_master_count_or_columns() {
    assert_not_contains 'awful.tag.incnmaster' "$BINDINGS_FILE"
    assert_not_contains 'awful.tag.incncol' "$BINDINGS_FILE"
    assert_not_contains '| `Mod+Shift+h` | 增加主区域窗口数量 |' "$README_FILE"
    assert_not_contains '| `Mod+Ctrl+Shift+l` | 减少主区域窗口数量 |' "$README_FILE"
    assert_not_contains '| `Mod+Ctrl+h` | 增加列数 |' "$README_FILE"
    assert_not_contains '| `Mod+Ctrl+l` | 减少列数 |' "$README_FILE"
}

test_client_rules_ignore_size_hints_for_tiling() {
    assert_contains 'size_hints_honor = false,' "$CLIENT_RULES_FILE"
}

test_no_dingtalk_specific_layout_hook() {
    assert_not_contains 'maybe_reset_master_width_for_dingtalk' "$CLIENT_RULES_FILE"
    assert_not_contains 'com.alibabainc.dingtalk' "$CLIENT_RULES_FILE"
}

test_no_legacy_dta_auto_float_rule() {
    assert_not_contains '"DTA",' "$CLIENT_RULES_FILE"
}

test_dingtalk_tlive_utility_helpers_are_not_tasklist_clients() {
    assert_contains 'rule = { class = "tblive", type = "utility" }' "$CLIENT_POLICIES_FILE"
    assert_contains 'skip_taskbar = true,' "$CLIENT_POLICIES_FILE"
    assert_contains 'floating = true,' "$CLIENT_POLICIES_FILE"
    assert_not_contains 'rule = { class = "tblive" }' "$CLIENT_POLICIES_FILE"
}

test_clients_use_rounded_shape_except_fullscreen_or_maximized() {
    assert_contains 'local function apply_client_shape(c)' "$CLIENT_DECORATIONS_FILE"
    assert_contains 'c.fullscreen or c.maximized or c.maximized_horizontal or c.maximized_vertical' "$CLIENT_DECORATIONS_FILE"
    assert_contains 'c.shape = gears.shape.rectangle' "$CLIENT_DECORATIONS_FILE"
    assert_contains 'gears.shape.rounded_rect(cr, w, h, beautiful.border_radius or 0)' "$CLIENT_DECORATIONS_FILE"
    assert_contains 'client.connect_signal("property::fullscreen", apply_client_shape)' "$CLIENT_DECORATIONS_FILE"
    assert_contains 'client.connect_signal("property::maximized", apply_client_shape)' "$CLIENT_DECORATIONS_FILE"
    assert_contains 'client.connect_signal("property::maximized_horizontal", apply_client_shape)' "$CLIENT_DECORATIONS_FILE"
    assert_contains 'client.connect_signal("property::maximized_vertical", apply_client_shape)' "$CLIENT_DECORATIONS_FILE"
    assert_contains '普通/对话框等 managed 窗口使用 `theme.border_radius` 圆角' "$README_FILE"
    assert_contains '全屏或最大化窗口会自动退回矩形' "$README_FILE"
}

test_titlebar_stays_fallback_only_for_select_floating_windows() {
    assert_contains 'titlebars_enabled = false,' "$CLIENT_RULES_FILE"
    assert_contains 'properties = { titlebars_enabled = true },' "$CLIENT_RULES_FILE"
    assert_contains 'except_any = {' "$CLIENT_RULES_FILE"
    assert_contains '"tblive",' "$CLIENT_RULES_FILE"
    assert_not_contains 'type = {' "$CLIENT_RULES_FILE"
    assert_contains '普通 `normal` / `dialog` 窗口继续默认不显示 titlebar' "$README_FILE"
    assert_contains '只有显式 class 白名单里的少数配置类浮动工具窗才会启用紧凑 fallback titlebar' "$README_FILE"
    assert_contains '普通 `utility` 窗口不会仅因为 `type=utility` 就自动出现标题栏' "$README_FILE"
    assert_contains '不会再因为通用 role 自动命中 fallback titlebar' "$README_FILE"

    python - "$CLIENT_RULES_FILE" <<'PY' || fail "expected titlebar fallback rule to rely on explicit class whitelist only"
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text()
start = text.index('properties = { titlebars_enabled = true },')
block = text[:start]
block = block[block.rfind('{', 0, block.rfind('rule_any = {')):]

if 'role = {' in block:
    raise SystemExit('titlebar fallback rule still contains role whitelist')
if 'type = {' in block:
    raise SystemExit('titlebar fallback rule still contains type whitelist')
if 'class = policies.fallback_titlebar_classes' not in block:
    raise SystemExit('titlebar fallback rule lost explicit class whitelist')
PY
}

test_titlebar_controls_are_minimal_and_styleable() {
    assert_contains 'local function update_titlebar_style(c)' "$CLIENT_DECORATIONS_FILE"
    assert_contains 'local function create_titlebar_control(c, spec)' "$CLIENT_DECORATIONS_FILE"
    assert_contains 'c._fallback_titlebar = titlebar' "$CLIENT_DECORATIONS_FILE"
    assert_contains 'c._fallback_titlebar_background = background' "$CLIENT_DECORATIONS_FILE"
    assert_contains "label = \"◇\"" "$CLIENT_DECORATIONS_FILE"
    assert_contains "active_label = \"◆\"" "$CLIENT_DECORATIONS_FILE"
    assert_contains "label = \"□\"" "$CLIENT_DECORATIONS_FILE"
    assert_contains "active_label = \"▣\"" "$CLIENT_DECORATIONS_FILE"
    assert_contains "label = \"×\"" "$CLIENT_DECORATIONS_FILE"
    assert_contains 'awful.client.floating.toggle(client_object)' "$CLIENT_DECORATIONS_FILE"
    assert_contains 'client_object.maximized = not client_object.maximized' "$CLIENT_DECORATIONS_FILE"
    assert_contains 'client_object:kill()' "$CLIENT_DECORATIONS_FILE"
    assert_not_contains 'awful.titlebar.widget.floatingbutton(c),' "$CLIENT_DECORATIONS_FILE"
    assert_not_contains 'awful.titlebar.widget.maximizedbutton(c),' "$CLIENT_DECORATIONS_FILE"
    assert_not_contains 'awful.titlebar.widget.closebutton(c),' "$CLIENT_DECORATIONS_FILE"
    assert_not_contains 'awful.titlebar.widget.stickybutton(c),' "$CLIENT_DECORATIONS_FILE"
    assert_not_contains 'awful.titlebar.widget.ontopbutton(c),' "$CLIENT_DECORATIONS_FILE"
    assert_contains 'left = dpi(3),' "$CLIENT_DECORATIONS_FILE"
    assert_contains 'top = dpi(2),' "$CLIENT_DECORATIONS_FILE"
}

test_default_layout_is_tile_left
test_layout_keys_still_adjust_master_width_factor
test_layout_keys_do_not_adjust_master_count_or_columns
test_client_rules_ignore_size_hints_for_tiling
test_no_dingtalk_specific_layout_hook
test_no_legacy_dta_auto_float_rule
test_dingtalk_tlive_utility_helpers_are_not_tasklist_clients
test_clients_use_rounded_shape_except_fullscreen_or_maximized
test_titlebar_stays_fallback_only_for_select_floating_windows
test_titlebar_controls_are_minimal_and_styleable

printf 'PASS: awesome layout tests\n'
