#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

SCRIPT=$REPO_ROOT/.config/scripts/dingtalk-wayland
HOOK_SOURCE=$REPO_ROOT/tools/dingtalk-wayland-screenshare

test_hook_source_removed() {
    assert_file_not_exists "$HOOK_SOURCE"
    assert_file_not_exists "$HOOK_SOURCE/hook.cpp"
    assert_file_not_exists "$HOOK_SOURCE/CMakeLists.txt"
}

test_script_is_troubleshooting_only() {
    assert_executable "$SCRIPT"
    assert_contains 'print_usage' "$SCRIPT"
    assert_contains 'usage|--help|-h' "$SCRIPT"
    assert_contains 'status)' "$SCRIPT"
    assert_contains 'stop|kill)' "$SCRIPT"
    assert_contains '显示此帮助' "$SCRIPT"
    assert_contains '排障' "$SCRIPT"
    assert_not_contains 'nohup ./com.alibabainc.dingtalk' "$SCRIPT"
    assert_not_contains '/opt/apps/com.alibabainc.dingtalk/files/Elevator.sh' "$SCRIPT"
    assert_not_contains 'export QT_QPA_PLATFORM=xcb' "$SCRIPT"
    assert_not_contains 'export LD_PRELOAD=' "$SCRIPT"
    assert_not_contains 'DINGTALK_FORCE_X11_CAPTURE' "$SCRIPT"
    assert_not_contains 'DINGTALK_WAYLAND_HOOK' "$SCRIPT"
    assert_not_contains 'libdingtalkhook.so' "$SCRIPT"
    assert_not_contains 'force_x11_capture' "$SCRIPT"
    assert_not_contains 'export XDG_SESSION_TYPE=x11' "$SCRIPT"
    assert_not_contains 'unset WAYLAND_DISPLAY' "$SCRIPT"
}

test_stop_cleans_dingtalk_and_tblive_processes() {
    assert_contains 'is_owned_dingtalk_process()' "$SCRIPT"
    assert_contains '/proc/[0-9]*' "$SCRIPT"
    assert_contains 'readlink "$proc_dir/exe"' "$SCRIPT"
    assert_contains 'com.alibabainc.dingtalk|tblive)' "$SCRIPT"
    assert_contains 'tblive' "$SCRIPT"
    assert_contains 'kill -TERM "$pid"' "$SCRIPT"
    assert_contains 'kill -KILL "$pid"' "$SCRIPT"
    assert_contains '缺少基础命令' "$SCRIPT"
    assert_contains 'for dep in id readlink' "$SCRIPT"
    assert_contains 'SIGKILL' "$SCRIPT"
    assert_not_contains 'pkill -f' "$SCRIPT"
    assert_not_contains 'pgrep -f' "$SCRIPT"
}

test_status_checks_portal_without_managing_services() {
    assert_contains 'portal_backend_has_screencast()' "$SCRIPT"
    assert_contains 'org.freedesktop.impl.portal.desktop.gnome' "$SCRIPT"
    assert_contains 'org.freedesktop.impl.portal.ScreenCast' "$SCRIPT"
    assert_contains 'PipeWire is not running' "$SCRIPT"
    assert_contains 'DingTalk screen sharing needs PipeWire, WirePlumber, and xdg-desktop-portal.' "$SCRIPT"
    assert_not_contains 'systemctl --user restart' "$SCRIPT"
}

test_hook_source_removed
test_script_is_troubleshooting_only
test_stop_cleans_dingtalk_and_tblive_processes
test_status_checks_portal_without_managing_services

printf 'PASS: dingtalk wayland tests\n'
