#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
WRAPPER_FILE=$REPO_ROOT/.config/linux/awesome/autostart.sh
COMMON_FILE=$REPO_ROOT/.config/linux/awesome/autostart/common.sh
ARCH_FILE=$REPO_ROOT/.config/linux/awesome/autostart/arch_x64.sh
UBUNTU_ARM_FILE=$REPO_ROOT/.config/linux/awesome/autostart/ubuntu_aarch64.sh
UBUNTU_X64_FILE=$REPO_ROOT/.config/linux/awesome/autostart/ubuntu_x64.sh
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

test_common_autostart_module_exists() {
    [ -f "$COMMON_FILE" ] || fail "expected common Awesome autostart module to exist"
}

test_root_autostart_wrapper_dispatches_to_platform_script() {
    [ -f "$WRAPPER_FILE" ] || fail "expected Awesome root autostart wrapper to exist"
    assert_contains 'SCRIPT="$BASE_DIR/autostart/ubuntu_aarch64.sh"' "$WRAPPER_FILE"
    assert_contains 'SCRIPT="$BASE_DIR/autostart/ubuntu_x64.sh"' "$WRAPPER_FILE"
    assert_contains 'SCRIPT="$BASE_DIR/autostart/arch_x64.sh"' "$WRAPPER_FILE"
    assert_contains 'exec sh "$SCRIPT"' "$WRAPPER_FILE"
}

test_platform_scripts_source_common_module() {
    for file in "$ARCH_FILE" "$UBUNTU_ARM_FILE" "$UBUNTU_X64_FILE"; do
        assert_contains '. "$(dirname "$0")/common.sh"' "$file"
        assert_not_contains 'run() {' "$file"
    done
}

test_common_module_exposes_shared_helpers() {
    assert_contains 'run_common_tray_services() {' "$COMMON_FILE"
    assert_contains 'run_common_desktop_services() {' "$COMMON_FILE"
    assert_contains 'prepare_xresources() {' "$COMMON_FILE"
    assert_contains 'append_path_if_exists() {' "$COMMON_FILE"
    assert_contains 'restore_or_randomize_wallpaper() {' "$COMMON_FILE"
    assert_contains '[ -f "$HOME/.fehbg" ]' "$COMMON_FILE"
    assert_contains 'sh "$HOME/.fehbg"' "$COMMON_FILE"
}

test_platform_specific_behaviors_remain_declared() {
    assert_contains 'restore_or_randomize_wallpaper "$HOME/Pictures"' "$ARCH_FILE"
    assert_contains 'run Snipaste' "$ARCH_FILE"
    assert_contains 'run greenclip daemon' "$ARCH_FILE"
    assert_contains 'detect_laptop_display() {' "$UBUNTU_ARM_FILE"
    assert_contains 'display_output=$(detect_laptop_display)' "$UBUNTU_ARM_FILE"
    assert_contains 'xrandr --output "$display_output" --mode 2880x1800 --rate 120' "$UBUNTU_ARM_FILE"
    assert_contains 'touchpad_id=$(xinput list 2>/dev/null | grep -i '\''Touchpad'\'' | sed '\''s/.*id=\([0-9]*\).*/\1/'\'')' "$UBUNTU_ARM_FILE"
    assert_contains 'append_path_if_exists "/home/linuxbrew/.linuxbrew/bin"' "$UBUNTU_ARM_FILE"
    assert_not_contains 'PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"' "$UBUNTU_ARM_FILE"
    assert_contains 'restore_or_randomize_wallpaper "$HOME/Pictures/wall" "$HOME/Pictures" "/usr/share/backgrounds"' "$UBUNTU_X64_FILE"
    assert_contains 'restore_or_randomize_wallpaper "$HOME/Pictures/wall" "$HOME/Pictures" "/usr/share/backgrounds"' "$UBUNTU_ARM_FILE"
    assert_contains 'run_custom "Snipaste-2.11.2-x86_64.AppImage" ~/Documents/Snipaste-2.11.2-x86_64.AppImage' "$UBUNTU_X64_FILE"
    assert_contains 'run greenclip daemon' "$UBUNTU_X64_FILE"
}

test_install_does_not_overwrite_root_wrapper_with_platform_script() {
    assert_not_contains '|.config/linux/awesome/autostart/arch_x64.sh|~/.config/awesome/autostart.sh|' "$INSTALL_FILE"
    assert_not_contains '|.config/linux/awesome/autostart/ubuntu_aarch64.sh|~/.config/awesome/autostart.sh|' "$INSTALL_FILE"
    assert_not_contains '|.config/linux/awesome/autostart/ubuntu_x64.sh|~/.config/awesome/autostart.sh|' "$INSTALL_FILE"
}

test_common_autostart_module_exists
test_root_autostart_wrapper_dispatches_to_platform_script
test_platform_scripts_source_common_module
test_common_module_exposes_shared_helpers
test_platform_specific_behaviors_remain_declared
test_install_does_not_overwrite_root_wrapper_with_platform_script

printf 'PASS: awesome autostart tests\n'
