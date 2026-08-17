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

test_exported_xshm_attach_fails_to_force_xgetimage_fallback() {
    assert_file_exists "$HOOK_SOURCE"

    # 导出的 XShmAttach 必须返回 false，让钉钉 XShm 初始化失败、回退到
    # XGetImage/XShmGetImage hook 路径；portal 初始化由内部 XShmAttachInner
    # 在 XShmGetImage 的线程上下文中触发，避免 tblive 内嵌 GLib main context
    # 不调度 portal create 回调导致 60 秒超时。
    body=$(extract_xshm_attach)
    printf '%s\n' "$body" | grep -F 'return false;' >/dev/null ||
        fail 'exported XShmAttach must return false to force XGetImage fallback'
    if printf '%s\n' "$body" | grep -F 'XShmAttachHook();' >/dev/null; then
        fail 'exported XShmAttach must not initialize the screencast hook directly'
    fi

    # portal 初始化改由内部 XShmAttachInner 触发（XShmGetImage 路径）
    grep -F 'XShmAttachInner' "$HOOK_SOURCE" >/dev/null ||
        fail 'XShmAttachInner must exist for portal init from XShmGetImage context'
    grep -A3 'Bool XShmAttachInner' "$HOOK_SOURCE" | grep -F 'XShmAttachHook();' >/dev/null ||
        fail 'XShmAttachInner must call XShmAttachHook for portal initialization'
}

test_launcher_selects_capture_path_by_arch() {
    launcher=$REPO_ROOT/.config/scripts/dingtalk-wayland

    assert_contains 'DINGTALK_FORCE_X11_CAPTURE' "$launcher"
    # x86_64 默认走 hook 回退（钉钉 8.1.0 libmeeting_sdk.so 缺 Wayland 后端），
    # 其它架构默认走原生捕获；显式 DINGTALK_FORCE_X11_CAPTURE 优先级最高。
    assert_contains '[ "$(uname -m)" = "x86_64" ]' "$launcher"
    assert_contains 'force_x11_capture=$DINGTALK_FORCE_X11_CAPTURE' "$launcher"
    assert_contains 'log_file=${DINGTALK_WAYLAND_LOG:-/tmp/dingtalk-wayland.log}' "$launcher"
    assert_contains 'if [ "$force_x11_capture" = 1 ]' "$launcher"
    assert_contains 'export XDG_SESSION_TYPE=x11' "$launcher"
    assert_contains 'unset WAYLAND_DISPLAY' "$launcher"
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

test_portal_waits_are_bounded_with_polling_timeouts() {
    # 等待 session / pipewire_fd 的忙等循环必须有超时上限（简单计数式超时，
    # 不引入 GCancellable）；取消路径 join sanitizer 前必须先置 stop_flag。
    payload_cpp=$REPO_ROOT/tools/dingtalk-wayland-screenshare/payload.cpp
    assert_contains 'PORTAL_WAIT_TIMEOUT_MS' "$payload_cpp"
    assert_contains 'portal wait timeout' "$payload_cpp"
    assert_contains 'pipewire_fd wait timeout' "$payload_cpp"
    grep -B2 'x11_sanitizer_thread.join();' "$payload_cpp" | grep -F 'x11_sanitizer_stop_flag' >/dev/null ||
        fail 'join x11_sanitizer_thread must be preceded by setting x11_sanitizer_stop_flag'
}

test_pipewire_thread_is_event_driven_without_busy_polling() {
    # PipeWire 线程必须阻塞在 pw_loop_iterate(-1)（事件驱动），不得用
    # iterate(0) + sleep 忙轮询；hook 停止侧置 pw_stop_flag 后必须调用
    # pw_main_loop_quit 唤醒阻塞的 iterate。
    payload_cpp=$REPO_ROOT/tools/dingtalk-wayland-screenshare/payload.cpp
    hook_cpp=$REPO_ROOT/tools/dingtalk-wayland-screenshare/hook.cpp
    assert_contains 'pw_loop_iterate(pw_main_loop_get_loop(pipewire_handle->pw_mainloop), -1)' "$payload_cpp"
    if grep -F 'PW_MIN_CALLTIME_MS' "$payload_cpp" >/dev/null; then
        fail 'pipewire thread must not busy-poll with PW_MIN_CALLTIME_MS sleep'
    fi
    grep -A3 'pw_stop_flag.store' "$hook_cpp" | grep -F 'pw_main_loop_quit' >/dev/null ||
        fail 'hook stop path must call pw_main_loop_quit to wake the blocked pw_loop_iterate'
}

test_portal_status_distinguishes_error_from_cancel() {
    # XdpScreencastPortalStatus 需有 kError 区分创建失败与用户取消；
    # create 失败回调置 kError；等待与失败分支同时识别两种终态。
    payload_hpp=$REPO_ROOT/tools/dingtalk-wayland-screenshare/payload.hpp
    payload_cpp=$REPO_ROOT/tools/dingtalk-wayland-screenshare/payload.cpp
    assert_contains 'kError' "$payload_hpp"
    grep -A8 'Failed to create screencast session' "$payload_hpp" | grep -F 'kError' >/dev/null ||
        fail 'create failure callback must set kError status'
    assert_contains '== XdpScreencastPortalStatus::kError' "$payload_cpp"
}

test_portal_create_fails_legacy_without_cancellable() {
    # 6 月 4 日 hook 版本：portal create 不带 cancellable，失败时只打印日志
    # 并返回；不强制超时取消。该路径已在 x86_64 + 8.1.0 实测可用。
    payload_hpp=$REPO_ROOT/tools/dingtalk-wayland-screenshare/payload.hpp
    payload_cpp=$REPO_ROOT/tools/dingtalk-wayland-screenshare/payload.cpp
    assert_contains 'g_main_loop_new(NULL, FALSE)' "$payload_hpp"
    if grep -F 'create_cancellable' "$payload_hpp" "$payload_cpp" >/dev/null; then
        fail 'legacy hook must not introduce create_cancellable (6月4日版本契约)'
    fi
    if grep -F 'kPortalCreateTimeout' "$payload_hpp" "$payload_cpp" >/dev/null; then
        fail 'legacy hook must not introduce portal create timeout (6月4日版本契约)'
    fi
    assert_contains 'niri --session' "$REPO_ROOT/.config/linux/niri/README.md"
}

test_exported_xshm_attach_fails_to_force_xgetimage_fallback
test_launcher_selects_capture_path_by_arch
test_portal_async_calls_use_the_global_main_context_without_forced_thread_default
test_restart_cleans_dingtalk_and_tblive_processes
test_launcher_waits_for_portal_without_managing_services

test_portal_waits_are_bounded_with_polling_timeouts
test_pipewire_thread_is_event_driven_without_busy_polling
test_portal_status_distinguishes_error_from_cancel
test_portal_create_fails_legacy_without_cancellable

printf 'PASS: dingtalk hook tests\n'
