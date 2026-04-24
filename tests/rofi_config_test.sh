#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CONFIG_FILE=$REPO_ROOT/.config/linux/rofi/config.rasi
THEME_FILE=$REPO_ROOT/.config/linux/rofi/theme.rasi
BINDINGS_FILE=$REPO_ROOT/.config/linux/awesome/bindings.lua
ACTIONS_FILE=$REPO_ROOT/.config/linux/awesome/actions.lua

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

section_body() {
    section_name=$1
    file=$2

    awk -v name="$section_name" '
        $0 ~ "^" name "[[:space:]]*\\{" { in_section = 1; next }
        in_section && $0 ~ "^\\}" { exit }
        in_section { print }
    ' "$file"
}

test_rofi_config_uses_external_theme_file() {
    assert_contains '@theme "theme.rasi"' "$CONFIG_FILE"
}

test_rofi_config_pins_monitor_dpi_for_rofi_1_7_1() {
    assert_contains 'dpi: 1;' "$CONFIG_FILE"
}

test_rofi_launcher_sets_locale_and_input_method() {
    assert_contains 'LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 LC_CTYPE=zh_CN.UTF-8 GTK_IM_MODULE=fcitx QT_IM_MODULE=fcitx XMODIFIERS=@im=fcitx rofi -show drun' "$ACTIONS_FILE"
    assert_contains 'local actions = args.actions or {}' "$BINDINGS_FILE"
    assert_contains 'local launch_rofi = actions.launch_rofi or function() end' "$BINDINGS_FILE"
}

test_rofi_theme_uses_rofi_1_7_1_compatible_pixel_distances() {
    star_section=$(section_body "\\*" "$THEME_FILE")
    window_section=$(section_body "window" "$THEME_FILE")
    mainbox_section=$(section_body "mainbox" "$THEME_FILE")
    inputbar_section=$(section_body "inputbar" "$THEME_FILE")
    listview_section=$(section_body "listview" "$THEME_FILE")
    element_section=$(section_body "element" "$THEME_FILE")
    element_icon_section=$(section_body "element-icon" "$THEME_FILE")

    printf '%s\n' "$star_section" | grep -F 'width:' >/dev/null 2>&1 &&
        fail "did not expect global rofi widget defaults to hardcode width"

    printf '%s\n' "$window_section" | grep -F 'width: 680px;' >/dev/null 2>&1 ||
        fail "expected rofi window width to use rofi 1.7.1-compatible pixel distance"
    printf '%s\n' "$window_section" | grep -F 'border-radius: 12px;' >/dev/null 2>&1 ||
        fail "expected rofi window radius to use rofi 1.7.1-compatible pixel distance"
    printf '%s\n' "$mainbox_section" | grep -F 'padding: 24px;' >/dev/null 2>&1 ||
        fail "expected rofi mainbox padding to use rofi 1.7.1-compatible pixel distance"
    printf '%s\n' "$mainbox_section" | grep -F 'spacing: 16px;' >/dev/null 2>&1 ||
        fail "expected rofi mainbox spacing to use rofi 1.7.1-compatible pixel distance"
    printf '%s\n' "$inputbar_section" | grep -F 'padding: 14px;' >/dev/null 2>&1 ||
        fail "expected rofi inputbar padding to use rofi 1.7.1-compatible pixel distance"
    printf '%s\n' "$inputbar_section" | grep -F 'spacing: 12px;' >/dev/null 2>&1 ||
        fail "expected rofi inputbar spacing to use rofi 1.7.1-compatible pixel distance"
    printf '%s\n' "$inputbar_section" | grep -F 'border-radius: 8px;' >/dev/null 2>&1 ||
        fail "expected rofi inputbar radius to use rofi 1.7.1-compatible pixel distance"
    printf '%s\n' "$listview_section" | grep -F 'spacing: 4px;' >/dev/null 2>&1 ||
        fail "expected rofi list spacing to use rofi 1.7.1-compatible pixel distance"
    printf '%s\n' "$element_section" | grep -F 'padding: 10px;' >/dev/null 2>&1 ||
        fail "expected rofi element padding to use rofi 1.7.1-compatible pixel distance"
    printf '%s\n' "$element_section" | grep -F 'spacing: 10px;' >/dev/null 2>&1 ||
        fail "expected rofi element spacing to use rofi 1.7.1-compatible pixel distance"
    printf '%s\n' "$element_section" | grep -F 'border-radius: 6px;' >/dev/null 2>&1 ||
        fail "expected rofi element radius to use rofi 1.7.1-compatible pixel distance"
    printf '%s\n' "$element_icon_section" | grep -F 'size: 36px;' >/dev/null 2>&1 ||
        fail "expected rofi icon size to use rofi 1.7.1-compatible pixel distance"
}

test_rofi_theme_keeps_entry_visible_and_cjk_friendly() {
    mainbox_section=$(section_body "mainbox" "$THEME_FILE")
    inputbar_section=$(section_body "inputbar" "$THEME_FILE")
    prompt_section=$(section_body "prompt" "$THEME_FILE")
    entry_section=$(section_body "entry" "$THEME_FILE")
    element_text_section=$(section_body "element-text" "$THEME_FILE")
    textbox_section=$(section_body "textbox" "$THEME_FILE")

    printf '%s\n' "$mainbox_section" | grep -F 'children: [inputbar, message, listview];' >/dev/null 2>&1 ||
        fail "expected rofi mainbox to declare its children explicitly"
    printf '%s\n' "$inputbar_section" | grep -F 'children: [prompt, entry];' >/dev/null 2>&1 ||
        fail "expected rofi inputbar to declare prompt and entry widgets explicitly"
    printf '%s\n' "$prompt_section" | grep -F 'font: "JetBrainsMono Nerd Font Bold 12";' >/dev/null 2>&1 ||
        fail "expected rofi prompt to step down one font size"
    printf '%s\n' "$entry_section" | grep -F 'expand: true;' >/dev/null 2>&1 ||
        fail "expected rofi entry to expand so typed text stays visible"
    printf '%s\n' "$entry_section" | grep -F 'cursor: text;' >/dev/null 2>&1 ||
        fail "expected rofi entry to keep text cursor styling"
    printf '%s\n' "$entry_section" | grep -F 'placeholder-color: #565c64;' >/dev/null 2>&1 ||
        fail "expected rofi entry placeholder color to be explicit"
    printf '%s\n' "$entry_section" | grep -F 'font: "Noto Sans CJK SC 11.5";' >/dev/null 2>&1 ||
        fail "expected rofi entry to use a CJK-capable font"
    printf '%s\n' "$element_text_section" | grep -F 'font: "Noto Sans CJK SC 11.5";' >/dev/null 2>&1 ||
        fail "expected rofi list entries to use a CJK-capable font"
    printf '%s\n' "$textbox_section" | grep -F 'font: "Noto Sans CJK SC 11.5";' >/dev/null 2>&1 ||
        fail "expected rofi textbox widgets to use a CJK-capable font"
}

test_rofi_config_pins_monitor_dpi_for_rofi_1_7_1
test_rofi_config_uses_external_theme_file
test_rofi_launcher_sets_locale_and_input_method
test_rofi_theme_uses_rofi_1_7_1_compatible_pixel_distances
test_rofi_theme_keeps_entry_visible_and_cjk_friendly

printf 'PASS: rofi config tests\n'
