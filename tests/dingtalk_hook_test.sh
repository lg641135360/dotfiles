#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

HOOK_SOURCE=$REPO_ROOT/tools/dingtalk-wayland-screenshare/hook.cpp

extract_xshm_attach() {
    awk '
        /Bool XShmAttach\(Display\* dpy, XShmSegmentInfo\* shminfo\)/ { capture=1 }
        capture { print }
        capture && /^}/ { exit }
    ' "$HOOK_SOURCE"
}

test_exported_xshm_attach_initializes_and_delegates() {
    assert_file_exists "$HOOK_SOURCE"

    body=$(extract_xshm_attach)
    printf '%s\n' "$body" | grep -F 'XShmAttachHook();' >/dev/null ||
        fail 'exported XShmAttach must initialize the screencast hook'
    printf '%s\n' "$body" | grep -F 'return XShmAttachFunc(dpy, shminfo);' >/dev/null ||
        fail 'exported XShmAttach must delegate to the original XShmAttach'
    if printf '%s\n' "$body" | grep -F 'return false;' >/dev/null; then
        fail 'exported XShmAttach must not unconditionally fail'
    fi
}

test_launcher_defaults_to_native_wayland_capture_with_opt_in_x11_hook() {
    launcher=$REPO_ROOT/.config/scripts/dingtalk-wayland
    payload=$REPO_ROOT/tools/dingtalk-wayland-screenshare/payload.hpp

    assert_contains 'DINGTALK_FORCE_X11_CAPTURE' "$launcher"
    assert_contains 'force_x11_capture=${DINGTALK_FORCE_X11_CAPTURE:-0}' "$launcher"
    assert_contains 'log_file=${DINGTALK_WAYLAND_LOG:-/tmp/dingtalk-wayland.log}' "$launcher"
    assert_contains 'if [ "$force_x11_capture" = 1 ]' "$launcher"
    assert_contains 'export XDG_SESSION_TYPE=x11' "$launcher"
    assert_contains 'unset WAYLAND_DISPLAY' "$launcher"
    assert_contains 'DINGTALK_WAYLAND_SESSION_TYPE' "$payload"
    assert_contains 'native Wayland/PipeWire capture' "$launcher"
}

test_portal_async_calls_use_the_global_main_context_without_forced_thread_default() {
    payload_hpp=$REPO_ROOT/tools/dingtalk-wayland-screenshare/payload.hpp
    payload_cpp=$REPO_ROOT/tools/dingtalk-wayland-screenshare/payload.cpp
    assert_contains 'g_main_loop_new(NULL, FALSE)' "$payload_hpp"
    if grep -F 'g_main_context_push_thread_default' "$payload_hpp" "$payload_cpp" >/dev/null; then
        fail 'libportal 0.7 calls must not force the process-global context as thread-default'
    fi
}

test_restart_cleans_dingtalk_and_tblive_processes() {
    launcher=$REPO_ROOT/.config/scripts/dingtalk-wayland
    assert_contains 'is_owned_dingtalk_process()' "$launcher"
    assert_contains '/proc/[0-9]*' "$launcher"
    assert_contains 'readlink "$proc_dir/exe"' "$launcher"
    assert_contains 'com.alibabainc.dingtalk|tblive)' "$launcher"
    assert_contains 'tblive' "$launcher"
    assert_contains 'kill -TERM "$pid"' "$launcher"
    assert_contains 'kill -KILL "$pid"' "$launcher"
    assert_not_contains 'pkill -f' "$launcher"
    assert_not_contains 'pgrep -f' "$launcher"
}

test_launcher_waits_for_portal_without_managing_services() {
    launcher=$REPO_ROOT/.config/scripts/dingtalk-wayland
    assert_contains 'portal_backend_has_screencast()' "$launcher"
    assert_contains 'wait_for_portal_screencast()' "$launcher"
    assert_contains 'org.freedesktop.impl.portal.desktop.gnome' "$launcher"
    assert_contains 'org.freedesktop.impl.portal.ScreenCast' "$launcher"
    assert_contains '等待 ScreenCast portal 就绪超时' "$launcher"
    assert_contains 'DingTalk screen sharing needs PipeWire, WirePlumber, and xdg-desktop-portal.' "$launcher"
    assert_not_contains 'Screen sharing through the DingTalk Wayland hook needs PipeWire' "$launcher"
    assert_not_contains 'systemctl --user restart' "$launcher"
}

test_portal_create_failure_cancels_without_hanging_tblive() {
    payload_hpp=$REPO_ROOT/tools/dingtalk-wayland-screenshare/payload.hpp
    payload_cpp=$REPO_ROOT/tools/dingtalk-wayland-screenshare/payload.cpp
    assert_contains 'portal create failed:' "$payload_hpp"
    assert_contains 'create_cancellable' "$payload_hpp"
    assert_contains 'status.store(XdpScreencastPortalStatus::kCancelled' "$payload_hpp"
    assert_contains 'g_main_loop_quit(this_ptr->gio_mainloop)' "$payload_hpp"
    assert_contains 'portal_handle->status.load() == XdpScreencastPortalStatus::kInit' "$payload_cpp"
    assert_contains 'constexpr auto kPortalCreateTimeout = std::chrono::seconds(60)' "$payload_cpp"
    assert_contains 'g_cancellable_cancel(portal_handle->create_cancellable)' "$payload_cpp"
    assert_contains 'portal create timed out' "$payload_cpp"
    assert_contains 'if (!portal_handle->session.load() ||' "$payload_cpp"
    assert_contains 'niri --session' "$REPO_ROOT/.config/linux/niri/README.md"
}

test_exported_xshm_attach_initializes_and_delegates
test_launcher_defaults_to_native_wayland_capture_with_opt_in_x11_hook
test_portal_async_calls_use_the_global_main_context_without_forced_thread_default
test_restart_cleans_dingtalk_and_tblive_processes
test_launcher_waits_for_portal_without_managing_services
test_portal_create_failure_cancels_without_hanging_tblive

printf 'PASS: dingtalk hook tests\n'
