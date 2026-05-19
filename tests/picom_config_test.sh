#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PICOM_UBUNTU_FILE=$REPO_ROOT/.config/linux/picom/picom-ubuntu_x64.conf
PICOM_ARCH_X64_FILE=$REPO_ROOT/.config/linux/picom/picom-arch_x64.conf
PICOM_ARCH_AARCH64_FILE=$REPO_ROOT/.config/linux/picom/picom-arch_aarch64.conf
README_FILE=$REPO_ROOT/.config/linux/picom/README.md

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

test_shared_visual_baseline() {
    assert_contains 'shadow-radius = 12' "$PICOM_UBUNTU_FILE"
    assert_contains 'shadow-opacity = 0.28' "$PICOM_UBUNTU_FILE"
    assert_contains 'shadow-offset-x = -6' "$PICOM_UBUNTU_FILE"
    assert_contains 'shadow-offset-y = -6' "$PICOM_UBUNTU_FILE"
    assert_contains 'inactive-opacity = 0.90' "$PICOM_UBUNTU_FILE"
    assert_contains 'frame-opacity = 1.0' "$PICOM_UBUNTU_FILE"
    assert_contains 'corner-radius = 12' "$PICOM_UBUNTU_FILE"
    assert_contains 'corner-radius = 12; }' "$PICOM_UBUNTU_FILE"
    assert_contains "utility = { shadow = true; corner-radius = 12; }" "$PICOM_UBUNTU_FILE"
    assert_contains "dialog = { shadow = true; corner-radius = 12; }" "$PICOM_UBUNTU_FILE"
}

test_ubuntu_x64_keeps_live_blur_route_and_x64_excludes() {
    assert_contains 'blur-method = "dual_kawase"' "$PICOM_UBUNTU_FILE"
    assert_contains 'blur-strength = 10' "$PICOM_UBUNTU_FILE"
    assert_contains 'blur-background = true' "$PICOM_UBUNTU_FILE"
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

    assert_contains 'strength = 8;' "$PICOM_ARCH_AARCH64_FILE"
    assert_contains "100:class_g = 'Alacritty'" "$PICOM_ARCH_AARCH64_FILE"
    assert_contains "100:class_g = 'kitty'" "$PICOM_ARCH_AARCH64_FILE"
    assert_contains 'corner-radius = 16' "$PICOM_ARCH_AARCH64_FILE"
}

test_readme_documents_current_visual_targets() {
    assert_contains '不强求三平台使用完全相同的参数' "$README_FILE"
    assert_contains 'Ubuntu x64 当前使用 12px radius、0.28 opacity、`-6/-6` offset' "$README_FILE"
    assert_contains 'Ubuntu x64 当前收口到 12px' "$README_FILE"
    assert_contains 'Ubuntu x64 当前使用 dual_kawase strength 10' "$README_FILE"
    assert_contains 'Ubuntu x64 当前使用 0.90 inactive、1.0 active、1.0 frame' "$README_FILE"
    assert_contains 'Alacritty/kitty 不再被 picom 强制拉回 100% opacity' "$README_FILE"
    assert_contains '`utility/dialog` 恢复轻阴影' "$README_FILE"
    assert_contains 'Ubuntu x64: `run picom`' "$README_FILE"
    assert_contains 'Ubuntu x64 + picom v10 path it must stay removed' "$README_FILE"
}

test_shared_visual_baseline
test_ubuntu_x64_keeps_live_blur_route_and_x64_excludes
test_terminal_opacity_is_left_to_terminal_configs
test_non_current_platform_configs_remain_platform_specific
test_readme_documents_current_visual_targets

printf 'PASS: picom config tests\n'
