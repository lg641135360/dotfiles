#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"
WRAPPER_FILE=$REPO_ROOT/.config/linux/awesome/autostart.sh
DISPLAY_LAYOUT_WRAPPER_FILE=$REPO_ROOT/.config/linux/awesome/display-layout.sh
COMMON_FILE=$REPO_ROOT/.config/linux/awesome/autostart/common.sh
ARCH_FILE=$REPO_ROOT/.config/linux/awesome/autostart/arch_x64.sh
UBUNTU_ARM_FILE=$REPO_ROOT/.config/linux/awesome/autostart/ubuntu_aarch64.sh
UBUNTU_X64_FILE=$REPO_ROOT/.config/linux/awesome/autostart/ubuntu_x64.sh
README_FILE=$REPO_ROOT/.config/linux/awesome/autostart/README.md
INSTALL_FILE=$REPO_ROOT/install.sh

wait_for_file_contains() {
    needle=$1
    file=$2
    i=0

    while [ "$i" -lt 50 ]; do
        if [ -f "$file" ] && grep -F -- "$needle" "$file" >/dev/null 2>&1; then
            return 0
        fi
        i=$((i + 1))
        sleep 0.1
    done

    fail "expected '$needle' in $file"
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

test_display_layout_wrapper_dispatches_to_platform_script() {
    [ -f "$DISPLAY_LAYOUT_WRAPPER_FILE" ] || fail "expected Awesome display-layout wrapper to exist"
    assert_contains 'SCRIPT="$BASE_DIR/autostart/ubuntu_aarch64.sh"' "$DISPLAY_LAYOUT_WRAPPER_FILE"
    assert_contains 'SCRIPT="$BASE_DIR/autostart/ubuntu_x64.sh"' "$DISPLAY_LAYOUT_WRAPPER_FILE"
    assert_contains 'SCRIPT="$BASE_DIR/autostart/arch_x64.sh"' "$DISPLAY_LAYOUT_WRAPPER_FILE"
    assert_contains 'exec sh "$SCRIPT" --display-layout' "$DISPLAY_LAYOUT_WRAPPER_FILE"
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
    assert_contains 'process_matching_pattern_exists() {' "$COMMON_FILE"
    assert_contains 'start_background() {' "$COMMON_FILE"
    assert_contains 'setsid -f "$@" >/dev/null 2>&1' "$COMMON_FILE"
    assert_contains 'nohup "$@" >/dev/null 2>&1 &' "$COMMON_FILE"
    assert_contains 'run_first_custom() {' "$COMMON_FILE"
    assert_contains 'pick_latest_executable_candidate() {' "$COMMON_FILE"
    assert_contains 'run_latest_custom() {' "$COMMON_FILE"
    assert_contains 'detect_laptop_display() {' "$COMMON_FILE"
    assert_contains 'detect_external_displays() {' "$COMMON_FILE"
    assert_contains 'detect_external_display() {' "$COMMON_FILE"
    assert_contains 'detect_display_preferred_mode() {' "$COMMON_FILE"
    assert_contains 'display_mode_line() {' "$COMMON_FILE"
    assert_contains 'display_supports_mode() {' "$COMMON_FILE"
    assert_contains 'display_supports_mode_rate() {' "$COMMON_FILE"
    assert_contains 'resolve_display_mode() {' "$COMMON_FILE"
    assert_contains 'configure_laptop_panel_only() {' "$COMMON_FILE"
    assert_contains 'configure_laptop_display_layout() {' "$COMMON_FILE"
    assert_contains 'randomize_wallpaper() {' "$COMMON_FILE"
    assert_contains 'run_idle_lock_service() {' "$COMMON_FILE"
    assert_contains 'xautolock -time 10 -locker "$locker" -detectsleep' "$COMMON_FILE"
    assert_contains 'feh --no-fehbg --bg-fill --randomize "$dir"/*' "$COMMON_FILE"
    assert_not_contains '.fehbg' "$COMMON_FILE"
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

    wait_for_file_contains 'fake-service --flag' "$log_file"

    if [ -s "$stderr_file" ]; then
        fail "expected missing optional autostart commands to be skipped without shell errors"
    fi

    rm -rf "$tmpdir"
}

test_run_custom_ignores_current_shell_when_checking_duplicates() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    log_file=$tmpdir/run.log

    mkdir -p "$bin_dir"

    cat >"$bin_dir/pgrep" <<'EOF'
#!/bin/sh
printf '%s\n' "$CURRENT_PID"
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
        CURRENT_PID=$$
        export PATH RUN_LOG CURRENT_PID
        . "$COMMON_FILE"
        run_custom "fake-service" fake-service --flag
        wait
    )

    wait_for_file_contains 'fake-service --flag' "$log_file"

    rm -rf "$tmpdir"
}

test_run_first_custom_uses_first_available_candidate() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    app_dir=$tmpdir/apps
    log_file=$tmpdir/snipaste.log

    mkdir -p "$bin_dir" "$app_dir"

    cat >"$bin_dir/pgrep" <<'EOF'
#!/bin/sh
exit 1
EOF
    chmod +x "$bin_dir/pgrep"

    cat >"$app_dir/Snipaste-2.11.2-x86_64.AppImage" <<'EOF'
#!/bin/sh
printf '%s\n' "$0 $*" >>"$SNIPASTE_LOG"
EOF
    chmod +x "$app_dir/Snipaste-2.11.2-x86_64.AppImage"

    (
        PATH="$bin_dir:/usr/bin:/bin"
        SNIPASTE_LOG=$log_file
        export PATH SNIPASTE_LOG
        . "$COMMON_FILE"
        run_first_custom "Snipaste" "$app_dir/missing.AppImage" "$app_dir/Snipaste-2.11.2-x86_64.AppImage"
        wait
    )

    wait_for_file_contains 'Snipaste-2.11.2-x86_64.AppImage' "$log_file"

    rm -rf "$tmpdir"
}

test_run_latest_custom_prefers_highest_version_candidate() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    app_dir=$tmpdir/apps
    download_dir=$tmpdir/downloads
    log_file=$tmpdir/snipaste.log

    mkdir -p "$bin_dir" "$app_dir" "$download_dir"

    cat >"$bin_dir/pgrep" <<'EOF'
#!/bin/sh
exit 1
EOF
    chmod +x "$bin_dir/pgrep"

    cat >"$app_dir/Snipaste-2.11.2-x86_64.AppImage" <<'EOF'
#!/bin/sh
printf '%s\n' "$0 $*" >>"$SNIPASTE_LOG"
EOF
    chmod +x "$app_dir/Snipaste-2.11.2-x86_64.AppImage"

    cat >"$download_dir/Snipaste-2.11.3-x86_64.AppImage" <<'EOF'
#!/bin/sh
printf '%s\n' "$0 $*" >>"$SNIPASTE_LOG"
EOF
    chmod +x "$download_dir/Snipaste-2.11.3-x86_64.AppImage"

    (
        PATH="$bin_dir:/usr/bin:/bin"
        SNIPASTE_LOG=$log_file
        export PATH SNIPASTE_LOG
        . "$COMMON_FILE"
        run_latest_custom "Snipaste" \
            "$app_dir/Snipaste-2.11.2-x86_64.AppImage" \
            "$download_dir/Snipaste-2.11.3-x86_64.AppImage"
        wait
    )

    wait_for_file_contains 'Snipaste-2.11.3-x86_64.AppImage' "$log_file"

    if grep -F 'Snipaste-2.11.2-x86_64.AppImage' "$log_file" >/dev/null 2>&1; then
        fail "expected run_latest_custom to skip older Snipaste candidates"
    fi

    rm -rf "$tmpdir"
}

test_xresources_and_wallpaper_helpers_skip_missing_optional_tools() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    home_dir=$tmpdir/home
    stderr_file=$tmpdir/stderr.log

    mkdir -p "$bin_dir" "$home_dir"

    (
        PATH=$bin_dir
        HOME=$home_dir
        export PATH HOME
        . "$COMMON_FILE"
        prepare_xresources
        randomize_wallpaper "$home_dir/Pictures" >/dev/null
    ) 2>"$stderr_file" || fail "missing xrdb/feh should not abort autostart helpers"

    if [ -s "$stderr_file" ]; then
        fail "expected missing xrdb/feh to be skipped without stderr noise"
    fi

    rm -rf "$tmpdir"
}

test_xresources_helper_only_merges_existing_file() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    home_dir=$tmpdir/home
    log_file=$tmpdir/xrdb.log

    mkdir -p "$bin_dir" "$home_dir"

    cat >"$bin_dir/xrdb" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$XRDB_LOG"
EOF
    chmod +x "$bin_dir/xrdb"

    (
        PATH=$bin_dir
        HOME=$home_dir
        XRDB_LOG=$log_file
        export PATH HOME XRDB_LOG
        . "$COMMON_FILE"
        prepare_xresources
    )

    [ ! -e "$log_file" ] ||
        fail "expected prepare_xresources to skip missing ~/.Xresources"

    touch "$home_dir/.Xresources"

    (
        PATH=$bin_dir
        HOME=$home_dir
        XRDB_LOG=$log_file
        export PATH HOME XRDB_LOG
        . "$COMMON_FILE"
        prepare_xresources
    )

    grep -Fx -- "merge $home_dir/.Xresources" "$log_file" >/dev/null 2>&1 ||
        fail "expected prepare_xresources to merge an existing ~/.Xresources"

    rm -rf "$tmpdir"
}

test_wallpaper_helper_uses_feh_when_available() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    wall_dir=$tmpdir/wall
    log_file=$tmpdir/feh.log

    mkdir -p "$bin_dir" "$wall_dir"
    : >"$wall_dir/sample.jpg"

    cat >"$bin_dir/feh" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$FEH_LOG"
EOF
    chmod +x "$bin_dir/feh"

    (
        PATH=$bin_dir:/usr/bin:/bin
        FEH_LOG=$log_file
        export PATH FEH_LOG
        . "$COMMON_FILE"
        randomize_wallpaper "$wall_dir"
        wait
    )

    wait_for_file_contains "--no-fehbg --bg-fill --randomize" "$log_file"

    rm -rf "$tmpdir"
}

test_common_desktop_services_starts_idle_locker_when_available() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    home_dir=$tmpdir/home
    log_file=$tmpdir/xautolock.log
    pgrep_log=$tmpdir/pgrep.log
    lock_script=$home_dir/.config/scripts/lock

    mkdir -p "$bin_dir" "$(dirname "$lock_script")"
    : >"$lock_script"
    chmod +x "$lock_script"

    cat >"$bin_dir/pgrep" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$PGREP_LOG"
exit 1
EOF
    chmod +x "$bin_dir/pgrep"

    cat >"$bin_dir/xautolock" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$XAUTOLOCK_LOG"
EOF
    chmod +x "$bin_dir/xautolock"

    (
        PATH=$bin_dir
        HOME=$home_dir
        XAUTOLOCK_LOG=$log_file
        PGREP_LOG=$pgrep_log
        export PATH HOME XAUTOLOCK_LOG PGREP_LOG
        . "$COMMON_FILE"
        run_common_desktop_services
        wait
    )

    grep -Fx -- "-time 10 -locker $lock_script -detectsleep" "$log_file" >/dev/null 2>&1 ||
        fail "expected xautolock to run with the shared lock script"
    grep -F -- "xautolock.*\\.config/scripts/lock" "$pgrep_log" >/dev/null 2>&1 ||
        fail "expected xautolock duplicate detection to match the lock script"

    rm -rf "$tmpdir"
}

test_laptop_display_layout_places_external_monitor_on_the_right() {
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
        configure_laptop_display_layout 2880x1800 120 right
    )

    grep -Fx -- '--output eDP-1 --primary --mode 2880x1800 --rate 120 --output DP-2 --auto --right-of eDP-1' "$log_file" >/dev/null 2>&1 ||
        fail "expected external monitor to use xrandr --auto on the right"

    rm -rf "$tmpdir"
}

test_laptop_display_layout_can_scale_external_monitor_on_the_right() {
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

     cat >"$query_file" <<'EOF'
Screen 0: minimum 320 x 200, current 2880 x 1800, maximum 32767 x 32767
DP-1 disconnected (normal left inverted right x axis y axis)
eDP-1 connected primary 2880x1800+0+0 (normal left inverted right x axis y axis) 300mm x 190mm
    2880x1800    120.00*+  60.00
DP-2 connected (normal left inverted right x axis y axis)
    3840x2160     29.98*+
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
        configure_laptop_display_layout 2880x1800 120 right 1.5x1.5
    )

    grep -Fx -- '--fb 5760x1800 --output DP-2 --mode 1920x1080 --scale 1.5x1.5 --pos 2880x0 --output eDP-1 --primary --mode 2880x1800 --rate 120 --scale 1x1 --pos 0x0' "$log_file" >/dev/null 2>&1 ||
        fail "expected external monitor to use detected 1920x1080 mode with 1.5x1.5 scaling on the right"

    rm -rf "$tmpdir"
}

test_display_mode_detection_prefers_progressive_mode_for_scaled_external_monitor() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    query_file=$tmpdir/xrandr.query

    mkdir -p "$bin_dir"

    cat >"$query_file" <<'EOF'
Screen 0: minimum 320 x 200, current 2880 x 1800, maximum 32767 x 32767
DP-1 disconnected (normal left inverted right x axis y axis)
eDP-1 connected primary 2880x1800+0+0 (normal left inverted right x axis y axis) 300mm x 190mm
   2880x1800    120.00*+  60.00
DP-2 connected (normal left inverted right x axis y axis)
   3840x2160     29.98*+
   1920x2160     59.99
   2560x1440     59.95
   1920x1080     60.00 +  59.94
EOF

    cat >"$bin_dir/xrandr" <<'EOF'
#!/bin/sh
if [ "$1" = "--query" ]; then
    cat "$XRANDR_QUERY"
    exit 0
fi
exit 1
EOF
    chmod +x "$bin_dir/xrandr"

    detected_mode=$(
        PATH="$bin_dir:/usr/bin:/bin"
        XRANDR_QUERY=$query_file
        export XRANDR_QUERY
        . "$COMMON_FILE"
        detect_display_preferred_mode DP-2
    )

    [ "$detected_mode" = "1920x1080" ] ||
        fail "expected scaled external display mode detection to prefer 1920x1080 over 3840x2160, got '$detected_mode'"

    rm -rf "$tmpdir"
}

test_laptop_display_layout_chains_multiple_external_monitors() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    query_file=$tmpdir/xrandr.query
    log_file=$tmpdir/xrandr.log

    mkdir -p "$bin_dir"

    cat >"$query_file" <<'EOF'
Screen 0: minimum 320 x 200, current 2880 x 1800, maximum 32767 x 32767
eDP-1 connected primary 2880x1800+0+0 (normal left inverted right x axis y axis) 300mm x 190mm
   2880x1800    120.00*+  60.00
DP-2 connected (normal left inverted right x axis y axis)
   1920x1080     60.00 +  59.94
HDMI-1 connected (normal left inverted right x axis y axis)
   2560x1440     60.00 +  59.94
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
        configure_laptop_display_layout 2880x1800 120 right
    )

    grep -Fx -- '--output eDP-1 --primary --mode 2880x1800 --rate 120 --output DP-2 --auto --right-of eDP-1 --output HDMI-1 --auto --right-of DP-2' "$log_file" >/dev/null 2>&1 ||
        fail "expected multiple external monitors to chain right-of from the laptop panel"

    rm -rf "$tmpdir"
}

test_laptop_display_layout_can_scale_multiple_external_monitors() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    query_file=$tmpdir/xrandr.query
    log_file=$tmpdir/xrandr.log

    mkdir -p "$bin_dir"

    cat >"$query_file" <<'EOF'
Screen 0: minimum 320 x 200, current 2880 x 1800, maximum 32767 x 32767
eDP-1 connected primary 2880x1800+0+0 (normal left inverted right x axis y axis) 300mm x 190mm
   2880x1800    120.00*+  60.00
DP-2 connected (normal left inverted right x axis y axis)
   1920x1080     60.00 +  59.94
HDMI-1 connected (normal left inverted right x axis y axis)
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
        configure_laptop_display_layout 2880x1800 120 right 1.5x1.5
    )

    grep -Fx -- '--fb 8640x1800 --output DP-2 --mode 1920x1080 --scale 1.5x1.5 --pos 2880x0 --output HDMI-1 --mode 1920x1080 --scale 1.5x1.5 --pos 5760x0 --output eDP-1 --primary --mode 2880x1800 --rate 120 --scale 1x1 --pos 0x0' "$log_file" >/dev/null 2>&1 ||
        fail "expected scaled layout to include every connected external monitor after the laptop panel"

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

fixed_layout_fixture() {
    fixture_dir=$1
    external_modes=$2

    mkdir -p "$fixture_dir/bin"

    cat >"$fixture_dir/xrandr.query" <<EOF
Screen 0: minimum 320 x 200, current 2880 x 1800, maximum 32767 x 32767
DP-1 disconnected (normal left inverted right x axis y axis)
eDP-1 connected primary 2880x1800+0+0 (normal left inverted right x axis y axis) 300mm x 190mm
   2880x1800    120.00*+  60.00
DP-2 connected (normal left inverted right x axis y axis)
$external_modes
EOF

    cat >"$fixture_dir/bin/xrandr" <<'EOF'
#!/bin/sh
if [ "$1" = "--query" ]; then
    cat "$XRANDR_QUERY"
    exit 0
fi
printf '%s\n' "$*" >>"$XRANDR_LOG"
if [ -n "${XRANDR_FAIL_PATTERN:-}" ]; then
    case "$*" in
        *"$XRANDR_FAIL_PATTERN"*)
            printf 'xrandr: configure crtc 1 failed\n' >&2
            exit 1
            ;;
    esac
fi
exit 0
EOF
    chmod +x "$fixture_dir/bin/xrandr"
}

run_fixed_layout() {
    fixture_dir=$1
    fail_pattern=$2
    shift 2

    (
        PATH="$fixture_dir/bin:/usr/bin:/bin"
        XRANDR_QUERY=$fixture_dir/xrandr.query
        XRANDR_LOG=$fixture_dir/xrandr.log
        XRANDR_FAIL_PATTERN=$fail_pattern
        export XRANDR_QUERY XRANDR_LOG XRANDR_FAIL_PATTERN
        . "$COMMON_FILE"
        configure_fixed_external_display_layout "$@"
    )
}

test_fixed_external_display_layout_uses_explicit_2k100_on_the_right() {
    tmpdir=$(mktemp -d)

    fixed_layout_fixture "$tmpdir" '   2560x1440     59.95 + 100.00    74.97
   1920x1080     74.97    60.00'

    run_fixed_layout "$tmpdir" '' 2880x1800 120 right 2560x1440 100

    grep -Fx -- '--output eDP-1 --primary --mode 2880x1800 --rate 120 --output DP-2 --mode 2560x1440 --rate 100 --right-of eDP-1' "$tmpdir/xrandr.log" >/dev/null 2>&1 ||
        fail "expected fixed external layout to force DP-2 to 2560x1440@100 on the right"

    rm -rf "$tmpdir"
}

test_fixed_external_display_layout_falls_back_when_requested_mode_missing() {
    tmpdir=$(mktemp -d)

    fixed_layout_fixture "$tmpdir" '   2560x1440     59.95 + 100.00    74.97
   1920x1080     74.97    60.00'

    run_fixed_layout "$tmpdir" '' 2880x1800 120 right 3840x2160 60

    if grep -F -- '3840x2160' "$tmpdir/xrandr.log" >/dev/null 2>&1; then
        fail "expected an unsupported external mode to never reach xrandr"
    fi

    grep -Fx -- '--output eDP-1 --primary --mode 2880x1800 --rate 120 --output DP-2 --mode 2560x1440 --right-of eDP-1' "$tmpdir/xrandr.log" >/dev/null 2>&1 ||
        fail "expected an unsupported external mode to fall back to the preferred mode"

    rm -rf "$tmpdir"
}

test_fixed_external_display_layout_drops_unsupported_refresh_rate() {
    tmpdir=$(mktemp -d)

    fixed_layout_fixture "$tmpdir" '   2560x1440    100.00 +
   1920x1080     74.97'

    run_fixed_layout "$tmpdir" '' 2880x1800 120 right 2560x1440 59.95

    if grep -F -- '--rate 59.95' "$tmpdir/xrandr.log" >/dev/null 2>&1; then
        fail "expected an unsupported external refresh rate to be dropped"
    fi

    grep -Fx -- '--output eDP-1 --primary --mode 2880x1800 --rate 120 --output DP-2 --mode 2560x1440 --right-of eDP-1' "$tmpdir/xrandr.log" >/dev/null 2>&1 ||
        fail "expected a supported external mode to survive an unsupported refresh rate"

    rm -rf "$tmpdir"
}

test_fixed_external_display_layout_keeps_laptop_panel_when_external_fails() {
    tmpdir=$(mktemp -d)

    fixed_layout_fixture "$tmpdir" '   2560x1440     59.95 + 100.00    74.97'

    # The fake xrandr prints a failure on purpose here; keep the suite output clean.
    run_fixed_layout "$tmpdir" 'DP-2' 2880x1800 120 right 2560x1440 100 2>/dev/null || true

    grep -Fx -- '--output eDP-1 --primary --mode 2880x1800 --rate 120' "$tmpdir/xrandr.log" >/dev/null 2>&1 ||
        fail "expected the laptop panel to be reconfigured on its own after an external layout failure"

    rm -rf "$tmpdir"
}

test_platform_specific_behaviors_remain_declared() {
    assert_contains 'randomize_wallpaper "$HOME/Pictures"' "$ARCH_FILE"
    assert_contains 'run Snipaste' "$ARCH_FILE"
    assert_contains 'run greenclip daemon' "$ARCH_FILE"
    assert_contains 'apply_display_layout() {' "$UBUNTU_ARM_FILE"
    assert_contains 'configure_fixed_external_display_layout 2880x1800 120 right 2560x1440 100' "$UBUNTU_ARM_FILE"
    assert_contains 'if [ "${1:-}" = "--display-layout" ]; then' "$UBUNTU_ARM_FILE"
    assert_not_contains 'configure_laptop_display_layout 2880x1800 120 right 1.5x1.5' "$UBUNTU_ARM_FILE"
    assert_not_contains 'configure_laptop_display_layout 2880x1800 120 right 2x2' "$UBUNTU_ARM_FILE"
    assert_contains 'touchpad_id=$(xinput list 2>/dev/null | grep -i '\''Touchpad'\'' | sed '\''s/.*id=\([0-9]*\).*/\1/'\'')' "$UBUNTU_ARM_FILE"
    assert_contains 'append_path_if_exists "/home/linuxbrew/.linuxbrew/bin"' "$UBUNTU_ARM_FILE"
    assert_not_contains 'PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"' "$UBUNTU_ARM_FILE"
    assert_contains 'if [ "${1:-}" = "--display-layout" ]; then' "$ARCH_FILE"
    assert_contains 'if [ "${1:-}" = "--display-layout" ]; then' "$UBUNTU_X64_FILE"
    assert_contains 'randomize_wallpaper "$HOME/Pictures/wall" "$HOME/Pictures" "/usr/share/backgrounds"' "$UBUNTU_X64_FILE"
    assert_contains 'randomize_wallpaper "$HOME/Pictures/wall" "$HOME/Pictures" "/usr/share/backgrounds"' "$UBUNTU_ARM_FILE"
    assert_contains 'run_latest_custom "Snipaste"' "$UBUNTU_X64_FILE"
    assert_contains '"$HOME"/Applications/Snipaste-*.AppImage' "$UBUNTU_X64_FILE"
    assert_contains '"$HOME"/Downloads/Snipaste-*.AppImage' "$UBUNTU_X64_FILE"
    assert_contains '"$HOME"/Documents/Snipaste-*.AppImage' "$UBUNTU_X64_FILE"
    assert_not_contains 'run_custom "Snipaste-2.11.2-x86_64.AppImage" ~/Documents/Snipaste-2.11.2-x86_64.AppImage' "$UBUNTU_X64_FILE"
    assert_contains 'run_common_desktop_services picom' "$UBUNTU_X64_FILE"
    assert_not_contains 'run_common_desktop_services picom --experimental-backends' "$UBUNTU_X64_FILE"
    assert_contains 'run_common_desktop_services picom --experimental-backends' "$UBUNTU_ARM_FILE"
    assert_contains 'run greenclip daemon' "$UBUNTU_X64_FILE"
}

test_readme_documents_random_wallpaper_behavior() {
    assert_contains 'feh --no-fehbg --bg-fill --randomize' "$README_FILE"
    assert_contains '不再优先恢复 `~/.fehbg`' "$README_FILE"
}

test_readme_documents_runtime_wrapper_chain() {
    assert_contains 'rc.lua' "$README_FILE"
    assert_contains '~/.config/awesome/autostart.sh' "$README_FILE"
    assert_contains '~/.config/awesome/display-layout.sh' "$README_FILE"
    assert_contains 'autostart/<platform>.sh' "$README_FILE"
    assert_not_contains '在 `install.sh` 中，根据 `uname -m` 和 `/etc/os-release` 判断使用哪个脚本' "$README_FILE"
}

test_readme_documents_display_mode_fallback() {
    assert_contains '2560x1440@100Hz' "$README_FILE"
    assert_not_contains '2560x1440@59.95Hz' "$README_FILE"
    assert_contains '`xrandr` 一次调用是原子的' "$README_FILE"
    assert_contains '回退到该外接屏的首选模式' "$README_FILE"
    assert_contains '退到 `--auto`' "$README_FILE"
    assert_contains '刷新率不被支持时只丢掉 `--rate`' "$README_FILE"
    assert_contains '再单独配一次内屏' "$README_FILE"
    assert_contains 'queue_display_layout_refresh()' "$README_FILE"
}

test_readme_documents_idle_lock_service() {
    assert_contains 'xautolock' "$README_FILE"
    assert_contains '10 分钟' "$README_FILE"
    assert_contains '~/.config/scripts/lock' "$README_FILE"
    assert_contains '-detectsleep' "$README_FILE"
}

test_readme_documents_ubuntu_x64_snipaste_candidates() {
    assert_contains 'start_background()' "$README_FILE"
    assert_contains 'setsid -f' "$README_FILE"
    assert_contains 'run_latest_custom()' "$README_FILE"
    assert_contains '~/Applications/Snipaste-*.AppImage' "$README_FILE"
    assert_contains '按版本号选择最新一项' "$README_FILE"
}


test_install_keeps_lain_removed_from_awesome_dependencies() {
    assert_not_contains 'for dep in lain collision; do' "$INSTALL_FILE"
    assert_not_contains 'https://github.com/lcpz/lain.git' "$INSTALL_FILE"
    assert_contains 'for dep in collision; do' "$INSTALL_FILE"
}

test_install_does_not_overwrite_root_wrapper_with_platform_script() {
    assert_not_contains '|.config/linux/awesome/autostart/arch_x64.sh|~/.config/awesome/autostart.sh|' "$INSTALL_FILE"
    assert_not_contains '|.config/linux/awesome/autostart/ubuntu_aarch64.sh|~/.config/awesome/autostart.sh|' "$INSTALL_FILE"
    assert_not_contains '|.config/linux/awesome/autostart/ubuntu_x64.sh|~/.config/awesome/autostart.sh|' "$INSTALL_FILE"
}

test_common_autostart_module_exists
test_root_autostart_wrapper_dispatches_to_platform_script
test_display_layout_wrapper_dispatches_to_platform_script
test_platform_scripts_source_common_module
test_common_module_exposes_shared_helpers
test_optional_autostart_commands_are_skipped_when_missing
test_run_custom_ignores_current_shell_when_checking_duplicates
test_run_first_custom_uses_first_available_candidate
test_run_latest_custom_prefers_highest_version_candidate
test_xresources_and_wallpaper_helpers_skip_missing_optional_tools
test_xresources_helper_only_merges_existing_file
test_wallpaper_helper_uses_feh_when_available
test_common_desktop_services_starts_idle_locker_when_available
test_laptop_display_layout_places_external_monitor_on_the_right
test_laptop_display_layout_can_scale_external_monitor_on_the_right
test_display_mode_detection_prefers_progressive_mode_for_scaled_external_monitor
test_laptop_display_layout_chains_multiple_external_monitors
test_laptop_display_layout_can_scale_multiple_external_monitors
test_laptop_display_layout_handles_no_external_monitor
test_fixed_external_display_layout_uses_explicit_2k100_on_the_right
test_fixed_external_display_layout_falls_back_when_requested_mode_missing
test_fixed_external_display_layout_drops_unsupported_refresh_rate
test_fixed_external_display_layout_keeps_laptop_panel_when_external_fails
test_platform_specific_behaviors_remain_declared
test_readme_documents_random_wallpaper_behavior
test_readme_documents_runtime_wrapper_chain
test_readme_documents_display_mode_fallback
test_readme_documents_idle_lock_service
test_readme_documents_ubuntu_x64_snipaste_candidates
test_install_keeps_lain_removed_from_awesome_dependencies
test_install_does_not_overwrite_root_wrapper_with_platform_script

printf 'PASS: awesome autostart tests\n'
