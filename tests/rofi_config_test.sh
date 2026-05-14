#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CONFIG_FILE=$REPO_ROOT/.config/linux/rofi/config.rasi
THEME_FILE=$REPO_ROOT/.config/linux/rofi/theme.rasi
BINDINGS_FILE=$REPO_ROOT/.config/linux/awesome/bindings.lua
ACTIONS_FILE=$REPO_ROOT/.config/linux/awesome/actions.lua
SCRIPT_FILE=$REPO_ROOT/.config/scripts/rofi-launch
INSTALL_FILE=$REPO_ROOT/install.sh

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

test_rofi_config_defers_dpi_to_system_scaling() {
    assert_not_contains 'dpi: 1;' "$CONFIG_FILE"
}

test_rofi_config_uses_compact_chinese_labels() {
    assert_contains 'display-drun: "  应用";' "$CONFIG_FILE"
    assert_contains 'display-window: "  窗口";' "$CONFIG_FILE"
    assert_contains 'display-run: "  命令";' "$CONFIG_FILE"
    assert_contains 'window-format: "{w} · {c}";' "$CONFIG_FILE"
}

test_rofi_launcher_sets_locale_and_input_method() {
    assert_contains 'local ROFI_COMMAND = "~/.config/scripts/rofi-launch"' "$ACTIONS_FILE"
    assert_contains 'local actions = args.actions or {}' "$BINDINGS_FILE"
    assert_contains 'local launch_rofi = actions.launch_rofi or function() end' "$BINDINGS_FILE"
    assert_contains 'executable_check(ROFI_COMMAND) .. " && " .. command_check({ "rofi" })' "$ACTIONS_FILE"
    assert_contains 'run_shell_after_check(' "$ACTIONS_FILE"
    assert_not_contains 'local function rofi_scale_for_focused_screen()' "$ACTIONS_FILE"
    assert_not_contains 'ROFI_SCALE=' "$ACTIONS_FILE"
}

test_rofi_launcher_script_scales_theme_from_xft_dpi() {
    [ -f "$SCRIPT_FILE" ] || fail "expected rofi launch script to exist"
    assert_not_contains 'ROFI_SCALE' "$SCRIPT_FILE"
    assert_contains 'xrdb -query' "$SCRIPT_FILE"
    assert_contains 'Xft.dpi' "$SCRIPT_FILE"
    assert_contains 'scale=$(awk' "$SCRIPT_FILE"
    assert_contains 'python3 - "$theme_source" "$theme_output" "$scale"' "$SCRIPT_FILE"
    assert_contains 'LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 LC_CTYPE=zh_CN.UTF-8 GTK_IM_MODULE=fcitx QT_IM_MODULE=fcitx XMODIFIERS=@im=fcitx' "$SCRIPT_FILE"
    assert_contains 'exec rofi -config "$config_file" -theme "$theme_output" -show drun "$@"' "$SCRIPT_FILE"
}

test_rofi_launcher_runtime_theme_scales_fonts_and_pixels() {
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT INT TERM HUP

    mkdir -p "$tmpdir/bin" "$tmpdir/config/rofi" "$tmpdir/cache/rofi"
    cp "$CONFIG_FILE" "$tmpdir/config/rofi/config.rasi"
    cp "$THEME_FILE" "$tmpdir/config/rofi/theme.rasi"

    cat >"$tmpdir/bin/xrdb" <<'EOF'
#!/bin/sh
printf 'Xft.dpi:\t192\n'
EOF
    chmod +x "$tmpdir/bin/xrdb"

    PATH="$tmpdir/bin:$PATH" \
    XDG_CONFIG_HOME="$tmpdir/config" \
    XDG_CACHE_HOME="$tmpdir/cache" \
    "$SCRIPT_FILE" -dump-theme >/dev/null 2>&1

    scaled_theme="$tmpdir/cache/rofi/theme.scaled.rasi"
    [ -f "$scaled_theme" ] || fail "expected scaled rofi theme to be generated"

    grep -F 'width: 1360px;' "$scaled_theme" >/dev/null 2>&1 ||
        fail "expected scaled rofi theme to double window width at 192 dpi"
    grep -F 'font: "JetBrainsMono Nerd Font Mono 23";' "$scaled_theme" >/dev/null 2>&1 ||
        fail "expected base monospace font size to scale with dpi"
    grep -F 'font: "JetBrainsMono Nerd Font Bold 24";' "$scaled_theme" >/dev/null 2>&1 ||
        fail "expected prompt font size to scale with dpi"
    grep -F 'font: "Noto Sans CJK SC 23";' "$scaled_theme" >/dev/null 2>&1 ||
        fail "expected CJK font size to scale with dpi"

    rm -rf "$tmpdir"
    trap - EXIT INT TERM HUP
}

test_install_copies_rofi_launcher_script() {
    assert_contains '|.config/scripts/rofi-launch|~/.config/scripts/rofi-launch|Rofi launch script' "$INSTALL_FILE"
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
    printf '%s\n' "$mainbox_section" | grep -F 'padding: 20px;' >/dev/null 2>&1 ||
        fail "expected rofi mainbox padding to use tighter rofi 1.7.1-compatible pixel distance"
    printf '%s\n' "$mainbox_section" | grep -F 'spacing: 14px;' >/dev/null 2>&1 ||
        fail "expected rofi mainbox spacing to be compacted"
    printf '%s\n' "$inputbar_section" | grep -F 'padding: 12px;' >/dev/null 2>&1 ||
        fail "expected rofi inputbar padding to be compacted"
    printf '%s\n' "$inputbar_section" | grep -F 'spacing: 10px;' >/dev/null 2>&1 ||
        fail "expected rofi inputbar spacing to be compacted"
    printf '%s\n' "$inputbar_section" | grep -F 'border-radius: 8px;' >/dev/null 2>&1 ||
        fail "expected rofi inputbar radius to use rofi 1.7.1-compatible pixel distance"
    printf '%s\n' "$listview_section" | grep -F 'spacing: 4px;' >/dev/null 2>&1 ||
        fail "expected rofi list spacing to use rofi 1.7.1-compatible pixel distance"
    printf '%s\n' "$element_section" | grep -F 'padding: 8px;' >/dev/null 2>&1 ||
        fail "expected rofi element padding to be compacted"
    printf '%s\n' "$element_section" | grep -F 'spacing: 8px;' >/dev/null 2>&1 ||
        fail "expected rofi element spacing to be compacted"
    printf '%s\n' "$element_section" | grep -F 'border-radius: 6px;' >/dev/null 2>&1 ||
        fail "expected rofi element radius to use rofi 1.7.1-compatible pixel distance"
    printf '%s\n' "$element_icon_section" | grep -F 'size: 32px;' >/dev/null 2>&1 ||
        fail "expected rofi icon size to be compacted"
}

test_rofi_theme_keeps_entry_visible_and_cjk_friendly() {
    mainbox_section=$(section_body "mainbox" "$THEME_FILE")
    inputbar_section=$(section_body "inputbar" "$THEME_FILE")
    prompt_section=$(section_body "prompt" "$THEME_FILE")
    entry_section=$(section_body "entry" "$THEME_FILE")
    message_section=$(section_body "message" "$THEME_FILE")
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
    printf '%s\n' "$message_section" | grep -F 'padding: 8px;' >/dev/null 2>&1 ||
        fail "expected rofi message area to be compacted"
    printf '%s\n' "$element_text_section" | grep -F 'font: "Noto Sans CJK SC 11.5";' >/dev/null 2>&1 ||
        fail "expected rofi list entries to use a CJK-capable font"
    printf '%s\n' "$textbox_section" | grep -F 'padding: 6px 11px;' >/dev/null 2>&1 ||
        fail "expected rofi textbox padding to be compacted"
    printf '%s\n' "$textbox_section" | grep -F 'font: "Noto Sans CJK SC 11.5";' >/dev/null 2>&1 ||
        fail "expected rofi textbox widgets to use a CJK-capable font"
}

test_rofi_config_defers_dpi_to_system_scaling
test_rofi_config_uses_external_theme_file
test_rofi_config_uses_compact_chinese_labels
test_rofi_launcher_sets_locale_and_input_method
test_rofi_launcher_script_scales_theme_from_xft_dpi
test_rofi_launcher_runtime_theme_scales_fonts_and_pixels
test_install_copies_rofi_launcher_script
test_rofi_theme_uses_rofi_1_7_1_compatible_pixel_distances
test_rofi_theme_keeps_entry_visible_and_cjk_friendly

printf 'PASS: rofi config tests\n'
