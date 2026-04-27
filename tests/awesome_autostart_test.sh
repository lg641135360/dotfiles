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
    assert_contains 'command_available() {' "$COMMON_FILE"
    assert_contains 'detect_laptop_display() {' "$COMMON_FILE"
    assert_contains 'detect_external_display() {' "$COMMON_FILE"
    assert_contains 'detect_display_preferred_mode() {' "$COMMON_FILE"
    assert_contains 'configure_laptop_display_layout() {' "$COMMON_FILE"
    assert_contains 'restore_or_randomize_wallpaper() {' "$COMMON_FILE"
    assert_contains '[ -f "$HOME/.fehbg" ]' "$COMMON_FILE"
    assert_contains 'sh "$HOME/.fehbg"' "$COMMON_FILE"
}

test_optional_autostart_commands_are_skipped_when_missing() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    log_file=$tmpdir/run.log
    stderr_file=$tmpdir/stderr.log

    mkdir -p "$bin_dir"

    cat >"$bin_dir/pgrep" <<'EOF'
#!/bin/sh
exit 1
EOF
    chmod +x "$bin_dir/pgrep"

    cat >"$bin_dir/fake-service" <<'EOF'
#!/bin/sh
printf '%s\n' "$0 $*" >>"$RUN_LOG"
EOF
    chmod +x "$bin_dir/fake-service"

    (
        PATH="$bin_dir:/usr/bin:/bin"
        RUN_LOG=$log_file
        export RUN_LOG
        . "$COMMON_FILE"
        run missing-autostart-command >/dev/null 2>"$stderr_file"
        run fake-service --flag >/dev/null 2>>"$stderr_file"
        run_custom "missing-appimage" "$tmpdir/missing-appimage" >/dev/null 2>>"$stderr_file"
        wait
    )

    grep -F 'fake-service --flag' "$log_file" >/dev/null 2>&1 ||
        fail "expected available autostart command to run"

    if [ -s "$stderr_file" ]; then
        fail "expected missing optional autostart commands to be skipped without shell errors"
    fi

    rm -rf "$tmpdir"
}

test_laptop_display_layout_places_external_monitor_on_the_left() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    query_file=$tmpdir/xrandr.query
    log_file=$tmpdir/xrandr.log

    mkdir -p "$bin_dir"

    cat >"$query_file" <<'EOF'
Screen 0: minimum 320 x 200, current 2880 x 1800, maximum 32767 x 32767
DP-1 disconnected (normal left inverted right x axis y axis)
eDP-1 connected primary 2880x1800+0+0 (normal left inverted right x axis y axis) 300mm x 190mm
   2880x1800    120.00*+  60.00
DP-2 connected (normal left inverted right x axis y axis)
   1920x1080     60.00 +  59.94
EOF

    cat >"$bin_dir/xrandr" <<'EOF'
#!/bin/sh
if [ "$1" = "--query" ]; then
    cat "$XRANDR_QUERY"
    exit 0
fi
printf '%s\n' "$*" >>"$XRANDR_LOG"
EOF
    chmod +x "$bin_dir/xrandr"

    (
        PATH="$bin_dir:/usr/bin:/bin"
        XRANDR_QUERY=$query_file
        XRANDR_LOG=$log_file
        export XRANDR_QUERY XRANDR_LOG
        . "$COMMON_FILE"
        configure_laptop_display_layout 2880x1800 120 left
    )

    grep -Fx -- '--output eDP-1 --primary --mode 2880x1800 --rate 120 --output DP-2 --auto --left-of eDP-1' "$log_file" >/dev/null 2>&1 ||
        fail "expected external monitor to use xrandr --auto on the left"

    rm -rf "$tmpdir"
}

test_laptop_display_layout_can_scale_external_monitor_on_the_left() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    query_file=$tmpdir/xrandr.query
    log_file=$tmpdir/xrandr.log

    mkdir -p "$bin_dir"

    cat >"$query_file" <<'EOF'
Screen 0: minimum 320 x 200, current 2880 x 1800, maximum 32767 x 32767
DP-1 disconnected (normal left inverted right x axis y axis)
eDP-1 connected primary 2880x1800+0+0 (normal left inverted right x axis y axis) 300mm x 190mm
   2880x1800    120.00*+  60.00
DP-2 connected (normal left inverted right x axis y axis)
   1920x1080     60.00 +  59.94
EOF

    cat >"$bin_dir/xrandr" <<'EOF'
#!/bin/sh
if [ "$1" = "--query" ]; then
    cat "$XRANDR_QUERY"
    exit 0
fi
printf '%s\n' "$*" >>"$XRANDR_LOG"
EOF
    chmod +x "$bin_dir/xrandr"

    (
        PATH="$bin_dir:/usr/bin:/bin"
        XRANDR_QUERY=$query_file
        XRANDR_LOG=$log_file
        export XRANDR_QUERY XRANDR_LOG
        . "$COMMON_FILE"
        configure_laptop_display_layout 2880x1800 120 left 1.5x1.5
    )

    grep -Fx -- '--fb 5760x1800 --output DP-2 --mode 1920x1080 --scale 1.5x1.5 --pos 0x0 --output eDP-1 --primary --mode 2880x1800 --rate 120 --scale 1x1 --pos 2880x0' "$log_file" >/dev/null 2>&1 ||
        fail "expected external monitor to use detected 1920x1080 mode with 1.5x1.5 scaling on the left"

    rm -rf "$tmpdir"
}

test_laptop_display_layout_handles_no_external_monitor() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    query_file=$tmpdir/xrandr.query
    log_file=$tmpdir/xrandr.log

    mkdir -p "$bin_dir"

    cat >"$query_file" <<'EOF'
Screen 0: minimum 320 x 200, current 2880 x 1800, maximum 32767 x 32767
DP-1 disconnected (normal left inverted right x axis y axis)
eDP-1 connected primary 2880x1800+0+0 (normal left inverted right x axis y axis) 300mm x 190mm
   2880x1800    120.00*+  60.00
DP-2 disconnected (normal left inverted right x axis y axis)
EOF

    cat >"$bin_dir/xrandr" <<'EOF'
#!/bin/sh
if [ "$1" = "--query" ]; then
    cat "$XRANDR_QUERY"
    exit 0
fi
printf '%s\n' "$*" >>"$XRANDR_LOG"
EOF
    chmod +x "$bin_dir/xrandr"

    (
        PATH="$bin_dir:/usr/bin:/bin"
        XRANDR_QUERY=$query_file
        XRANDR_LOG=$log_file
        export XRANDR_QUERY XRANDR_LOG
        . "$COMMON_FILE"
        configure_laptop_display_layout 2880x1800 120 left
    )

    grep -Fx -- '--output eDP-1 --primary --mode 2880x1800 --rate 120' "$log_file" >/dev/null 2>&1 ||
        fail "expected laptop panel to be configured without external positioning when no external monitor is connected"

    rm -rf "$tmpdir"
}

test_platform_specific_behaviors_remain_declared() {
    assert_contains 'restore_or_randomize_wallpaper "$HOME/Pictures"' "$ARCH_FILE"
    assert_contains 'run Snipaste' "$ARCH_FILE"
    assert_contains 'run greenclip daemon' "$ARCH_FILE"
    assert_contains 'configure_laptop_display_layout 2880x1800 120 left 1.5x1.5' "$UBUNTU_ARM_FILE"
    assert_not_contains 'configure_laptop_display_layout 2880x1800 120 left 2x2' "$UBUNTU_ARM_FILE"
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
test_optional_autostart_commands_are_skipped_when_missing
test_laptop_display_layout_places_external_monitor_on_the_left
test_laptop_display_layout_can_scale_external_monitor_on_the_left
test_laptop_display_layout_handles_no_external_monitor
test_platform_specific_behaviors_remain_declared
test_install_does_not_overwrite_root_wrapper_with_platform_script

printf 'PASS: awesome autostart tests\n'
