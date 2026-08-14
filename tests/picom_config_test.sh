#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"
PICOM_UBUNTU_FILE=$REPO_ROOT/.config/linux/picom/picom-ubuntu_x64.conf
PICOM_ARCH_X64_FILE=$REPO_ROOT/.config/linux/picom/picom-arch_x64.conf
PICOM_ARCH_AARCH64_FILE=$REPO_ROOT/.config/linux/picom/picom-arch_aarch64.conf
AWESOME_THEME_FILE=$REPO_ROOT/.config/linux/awesome/theme/catppuccin.lua

test_shared_visual_baseline() {
    assert_contains 'shadow-radius = 16' "$PICOM_UBUNTU_FILE"
    assert_contains 'shadow-opacity = 0.22' "$PICOM_UBUNTU_FILE"
    assert_contains 'shadow-offset-x = -8' "$PICOM_UBUNTU_FILE"
    assert_contains 'shadow-offset-y = -8' "$PICOM_UBUNTU_FILE"
    assert_contains 'inactive-opacity = 0.90' "$PICOM_UBUNTU_FILE"
    assert_contains 'active-opacity = 0.94' "$PICOM_UBUNTU_FILE"
    assert_contains 'frame-opacity = 0.92' "$PICOM_UBUNTU_FILE"
    assert_contains 'corner-radius = 12' "$PICOM_UBUNTU_FILE"
    assert_contains 'corner-radius = 12; }' "$PICOM_UBUNTU_FILE"
    assert_contains "utility = { shadow = true; corner-radius = 12; }" "$PICOM_UBUNTU_FILE"
    assert_contains "dialog = { shadow = true; corner-radius = 12; }" "$PICOM_UBUNTU_FILE"
}

test_ubuntu_x64_keeps_live_blur_route_and_x64_excludes() {
    assert_contains 'blur-method = "dual_kawase"' "$PICOM_UBUNTU_FILE"
    assert_contains 'blur-strength = 12' "$PICOM_UBUNTU_FILE"
    assert_contains 'blur-background-frame = true' "$PICOM_UBUNTU_FILE"
    assert_contains 'blur-background = true' "$PICOM_UBUNTU_FILE"
    if awk '/blur-background-exclude = \[/{in_blur=1} in_blur && /override_redirect = true/{found=1} in_blur && /\];/{in_blur=0} END{exit found ? 0 : 1}' "$PICOM_UBUNTU_FILE"; then
        fail "did not expect override_redirect in Ubuntu x64 blur-background-exclude"
    fi
    assert_contains '"window_type = '\''splash'\''"' "$PICOM_UBUNTU_FILE"
    assert_contains '"window_type = '\''tooltip'\''"' "$PICOM_UBUNTU_FILE"
    assert_contains '"class_g = '\''maim'\''"' "$PICOM_UBUNTU_FILE"
    assert_contains '"class_g = '\''tblive'\''"' "$PICOM_UBUNTU_FILE"
    if grep -F '"_GTK_FRAME_EXTENTS@"' "$PICOM_UBUNTU_FILE" >/dev/null 2>&1; then
        fail "did not expect '_GTK_FRAME_EXTENTS@' in Ubuntu x64 picom config"
    fi
}

test_terminal_opacity_is_left_to_terminal_configs() {
    if grep -F "100:class_g = 'Alacritty'" "$PICOM_UBUNTU_FILE" >/dev/null 2>&1; then
        fail "did not expect picom to force Alacritty opacity in Ubuntu x64 config"
    fi
    if grep -F "100:class_g = 'kitty'" "$PICOM_UBUNTU_FILE" >/dev/null 2>&1; then
        fail "did not expect picom to force kitty opacity in Ubuntu x64 config"
    fi
    assert_contains "100:class_g = 'firefox'" "$PICOM_UBUNTU_FILE"
    assert_contains "100:class_g = 'Thunderbird'" "$PICOM_UBUNTU_FILE"
}

test_non_current_platform_configs_remain_platform_specific() {
    assert_contains 'strength = 8;' "$PICOM_ARCH_X64_FILE"
    assert_contains 'inactive-opacity = 0.9' "$PICOM_ARCH_X64_FILE"
    assert_contains 'corner-radius = 16' "$PICOM_ARCH_X64_FILE"
    assert_contains "100:class_g = 'firefox'" "$PICOM_ARCH_X64_FILE"

    assert_contains 'strength = 4;' "$PICOM_ARCH_AARCH64_FILE"
    assert_contains 'inactive-opacity = 0.87' "$PICOM_ARCH_AARCH64_FILE"
    assert_contains 'corner-radius = 8' "$PICOM_ARCH_AARCH64_FILE"
    assert_contains "100:class_g = 'firefox'" "$PICOM_ARCH_AARCH64_FILE"
    assert_contains "100:class_g = 'Thunderbird'" "$PICOM_ARCH_AARCH64_FILE"
}

# Guard against the aarch64 corner-radius drift bug: the top-level value
# and every wintypes entry must agree (aarch64 was previously 8 at top-level
# but 16 inside wintypes).
test_wintypes_corner_radius_matches_top_level() {
    for file in "$PICOM_UBUNTU_FILE" "$PICOM_ARCH_X64_FILE" "$PICOM_ARCH_AARCH64_FILE"; do
        top_level=$(grep -E '^corner-radius = [0-9]+' "$file" | head -1 | grep -oE '[0-9]+')
        [ -n "$top_level" ] || fail "missing top-level corner-radius in $file"
        # Every wintypes corner-radius must equal the top-level value.
        mismatch=$(grep -oE 'corner-radius = [0-9]+' "$file" | grep -oE '[0-9]+' | grep -vx "$top_level" || true)
        [ -z "$mismatch" ] || fail "wintypes corner-radius ($mismatch) != top-level ($top_level) in $file"
    done
}

test_ubuntu_x64_corner_radius_matches_awesome_theme() {
    assert_contains 'corner-radius = 12' "$PICOM_UBUNTU_FILE"
    assert_contains 'theme.border_radius = dpi(12)' "$AWESOME_THEME_FILE"
}

test_shared_visual_baseline
test_ubuntu_x64_keeps_live_blur_route_and_x64_excludes
test_terminal_opacity_is_left_to_terminal_configs
test_non_current_platform_configs_remain_platform_specific
test_wintypes_corner_radius_matches_top_level
test_ubuntu_x64_corner_radius_matches_awesome_theme

printf 'PASS: picom config tests\n'
