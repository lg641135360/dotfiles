#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

NIRI_CONFIG=$REPO_ROOT/.config/linux/niri/ubuntu_x64/config.kdl
NIRI_AARCH64_CONFIG=$REPO_ROOT/.config/linux/niri/ubuntu_aarch64/config.kdl
NIRI_COMMON_CONFIG=$REPO_ROOT/.config/linux/niri/common.kdl
NIRI_README=$REPO_ROOT/.config/linux/niri/README.md
TERMINAL_SCRIPT=$REPO_ROOT/.config/scripts/terminal-wayland

test_niri_config_exists_and_validates_when_available() {
    assert_file_exists "$NIRI_CONFIG"
    assert_file_exists "$NIRI_COMMON_CONFIG"

    # The Ubuntu platform config includes the shared common.kdl.
    assert_contains 'include "../common.kdl"' "$NIRI_CONFIG"

    if command -v niri >/dev/null 2>&1; then
        # niri from a nix profile may fail to find libstdc++.so.6 when run
        # outside a nix shell because RUNPATH resolution differs for subcommands.
        # Retry with the gcc-lib path from niri's own RUNPATH if the first call
        # fails with a shared library error.
        if niri validate -c "$NIRI_CONFIG" >/dev/null 2>&1; then
            return 0
        fi

        niri_lib_dir=$(readelf -d "$(command -v niri)" 2>/dev/null \
            | grep -oE '/nix/store/[^:]*gcc-[^:]*-lib/lib' | head -n 1)
        if [ -n "$niri_lib_dir" ] && [ -d "$niri_lib_dir" ]; then
            LD_LIBRARY_PATH="$niri_lib_dir" niri validate -c "$NIRI_CONFIG" >/dev/null 2>&1 ||
                fail "expected niri config to validate with installed niri"
        else
            fail "expected niri config to validate with installed niri"
        fi
    fi
}

test_niri_config_keeps_awesome_muscle_memory() {
    # Shared behavior lives in common.kdl, included by every platform config.
    assert_contains 'spawn-sh-at-startup "~/.config/scripts/wayland-autostart"' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+Return repeat=false hotkey-overlay-title="打开终端" { spawn "~/.config/scripts/terminal-wayland"; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+E repeat=false hotkey-overlay-title="打开文件管理器" { spawn "~/.config/scripts/file-manager-wayland"; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+C repeat=false hotkey-overlay-title="启动应用" { spawn "~/.config/scripts/launcher-wayland"; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+Q repeat=false hotkey-overlay-title="关闭当前窗口" { close-window; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+Alt+L repeat=false hotkey-overlay-title="锁屏" { spawn "~/.config/scripts/lock-wayland"; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+Shift+W repeat=false hotkey-overlay-title="切换壁纸" { spawn "~/.config/scripts/wallpaper-wayland-next"; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+O repeat=false hotkey-overlay-title="显示总览" { toggle-overview; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+Shift+Q repeat=false hotkey-overlay-title="退出 niri" { quit; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+V repeat=false hotkey-overlay-title="剪贴板历史" { spawn "~/.config/scripts/clipboard-wayland" "history"; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+Tab repeat=false hotkey-overlay-title="切换到上一个窗口" { focus-window-previous; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+H { focus-column-or-monitor-left; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+L { focus-column-or-monitor-right; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+J { focus-window-or-workspace-down; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+K { focus-window-or-workspace-up; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+Minus { set-column-width "-10%"; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+Equal { set-column-width "+10%"; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+Shift+Minus { set-window-height "-10%"; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+Shift+Equal { set-window-height "+10%"; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+Shift+H { move-column-left-or-to-monitor-left; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+Shift+L { move-column-right-or-to-monitor-right; }' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'Mod+Ctrl+H { move-column-left; }' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'Mod+Ctrl+L { move-column-right; }' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'Mod+Shift+A { move-column-to-monitor-left; }' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'Mod+Shift+D { move-column-to-monitor-right; }' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'Mod+Left' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'Mod+Right' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'Mod+Up' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'Mod+Down' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'Mod+Alt+H { focus-column-left; }' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'Mod+Alt+L { focus-column-right; }' "$NIRI_COMMON_CONFIG"
}

test_niri_config_exposes_multi_monitor_navigation() {
    assert_contains 'Mod+A repeat=false { focus-monitor-left; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+D repeat=false { focus-monitor-right; }' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'Mod+Shift+A { move-column-to-monitor-left; }' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'Mod+Shift+D { move-column-to-monitor-right; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+Ctrl+Shift+A repeat=false { move-workspace-to-monitor-left; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+Ctrl+Shift+D repeat=false { move-workspace-to-monitor-right; }' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'Mod+Page_Up' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'Mod+Page_Down' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'Mod+Shift+Page_Up' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'Mod+Shift+Page_Down' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+Ctrl+Space repeat=false hotkey-overlay-title="切换窗口浮动" { toggle-window-floating; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+Shift+V repeat=false hotkey-overlay-title="切换浮动/平铺焦点" { switch-focus-between-floating-and-tiling; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+W repeat=false hotkey-overlay-title="切换列标签模式" { toggle-column-tabbed-display; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+BracketLeft repeat=false hotkey-overlay-title="向左并入/移出窗口" { consume-or-expel-window-left; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Mod+BracketRight repeat=false hotkey-overlay-title="向右并入/移出窗口" { consume-or-expel-window-right; }' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'Mod+Comma' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'Mod+Period' "$NIRI_COMMON_CONFIG"
}

test_niri_config_uses_wayland_replacements_not_x11_autostart() {
    # Shared Wayland-native directives live in common.kdl.
    assert_contains 'prefer-no-csd' "$NIRI_COMMON_CONFIG"
    assert_contains 'screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'picom' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'xrandr' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'xinput' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'xautolock' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'feh' "$NIRI_COMMON_CONFIG"

    # Platform-specific output section stays in the platform config.
    assert_contains '// Platform: ubuntu_x64' "$NIRI_CONFIG"
    assert_contains 'output "DP-1" {' "$NIRI_CONFIG"
    assert_contains 'output "HDMI-A-2" {' "$NIRI_CONFIG"
    assert_contains 'scale 1.25' "$NIRI_CONFIG"
    assert_contains 'position x=2048 y=0' "$NIRI_CONFIG"
}

test_niri_aarch64_config_maps_media_tek_hybrid_outputs_and_foot_terminal() {
    # Platform config includes the shared common.kdl like every other platform.
    assert_file_exists "$NIRI_AARCH64_CONFIG"
    assert_contains '// Platform: ubuntu_aarch64' "$NIRI_AARCH64_CONFIG"
    assert_contains 'include "../common.kdl"' "$NIRI_AARCH64_CONFIG"

    # External DP-2 (Dell S2721DGF) at 1.25x on the right, internal eDP-1 at 2x HiDPI on the left.
    assert_contains 'output "eDP-1" {' "$NIRI_AARCH64_CONFIG"
    assert_contains 'mode "2880x1800@120"' "$NIRI_AARCH64_CONFIG"
    assert_contains 'scale 2.0' "$NIRI_AARCH64_CONFIG"
    assert_contains 'position x=0 y=0' "$NIRI_AARCH64_CONFIG"
    assert_contains 'output "DP-2" {' "$NIRI_AARCH64_CONFIG"
    assert_contains 'modeline 497.75 2560 2608 2640 2720 1440 1445 1448 1525 "+hsync" "-vsync"' "$NIRI_AARCH64_CONFIG"
    assert_contains 'scale 1.25' "$NIRI_AARCH64_CONFIG"
    assert_contains 'position x=1440 y=0' "$NIRI_AARCH64_CONFIG"

    # aarch64 + Wayland 优先 foot：alacritty 0.18.0-dev 在 mtgpu 内屏 2x 字形损坏，
    # foot 渲染正常。其他平台仍优先 alacritty，foot 作最后兜底。
    assert_contains 'uname -m' "$TERMINAL_SCRIPT"
    assert_contains 'WAYLAND_DISPLAY' "$TERMINAL_SCRIPT"
    assert_not_contains 'exec kitty "$@"' "$TERMINAL_SCRIPT"
    # Alacritty 2026-08-29 起走 apt，terminal-wayland 不得再特判 Nix profile 路径。
    assert_not_contains 'nix-profile' "$TERMINAL_SCRIPT"
    assert_contains 'exec foot "$@"' "$TERMINAL_SCRIPT"

    # 常驻单实例快速开窗方案已随 kitty 一并移除（避免残留 socket / 登录多一个常驻
    # 窗口等维护成本）；不得再出现 socket 控制或远程控制。
    assert_not_contains 'kitty @ --to' "$TERMINAL_SCRIPT"
    assert_not_contains '--listen-on' "$TERMINAL_SCRIPT"
    assert_not_contains 'allow_remote_control' "$REPO_ROOT/.config/linux/foot/foot.ini"

    # aarch64 keeps transparency but disables blur: mtgpu blur is invisible.
    # Platform override is 0.90 (common.kdl stays 0.88); do not match the
    # common value via comments.
    assert_contains 'blur false' "$NIRI_AARCH64_CONFIG"
    assert_contains 'opacity 0.90' "$NIRI_AARCH64_CONFIG"
    assert_not_contains 'opacity 0.88' "$NIRI_AARCH64_CONFIG"
}

test_niri_config_uses_native_environment_cursor_and_animations() {
    # environment {} block: niri spawns inherit these directly.
    assert_contains 'environment {' "$NIRI_COMMON_CONFIG"
    assert_contains 'QT_IM_MODULE "fcitx"' "$NIRI_COMMON_CONFIG"
    assert_contains 'XMODIFIERS "@im=fcitx"' "$NIRI_COMMON_CONFIG"
    assert_contains 'SDL_IM_MODULE "fcitx"' "$NIRI_COMMON_CONFIG"
    assert_contains 'GLFW_IM_MODULE "ibus"' "$NIRI_COMMON_CONFIG"
    assert_contains 'INPUT_METHOD "fcitx"' "$NIRI_COMMON_CONFIG"
    assert_contains 'LC_CTYPE "zh_CN.UTF-8"' "$NIRI_COMMON_CONFIG"
    assert_contains 'XCURSOR_SIZE "32"' "$NIRI_COMMON_CONFIG"
    # niri spawn env must set ZDOTDIR so spawned shells use the optimized
    # ~/.config/zsh; otherwise they fall back to default config + global
    # compinit (interactive startup 4.2s vs 0.18s measured).
    assert_contains 'ZDOTDIR "/home/rikoo/.config/zsh"' "$NIRI_COMMON_CONFIG"
    # Session runs as a proper Wayland/niri session: manual shell launch would
    # otherwise inherit XDG_SESSION_TYPE=tty / XDG_CURRENT_DESKTOP=awesome and
    # break text-input-v3 routing for fcitx5.
    assert_contains 'XDG_SESSION_TYPE "wayland"' "$NIRI_COMMON_CONFIG"
    assert_contains 'XDG_CURRENT_DESKTOP "niri"' "$NIRI_COMMON_CONFIG"
    assert_contains 'XDG_SESSION_DESKTOP "niri"' "$NIRI_COMMON_CONFIG"
    # GTK_IM_MODULE intentionally unset for Wayland text-input protocol.
    assert_not_contains 'GTK_IM_MODULE "fcitx"' "$NIRI_COMMON_CONFIG"

    # cursor {} block: drawn before autostart runs.
    assert_contains 'cursor {' "$NIRI_COMMON_CONFIG"
    assert_contains 'xcursor-size 32' "$NIRI_COMMON_CONFIG"

    # touchpad: tap / natural-scroll / dwt / clickfinger / two-finger / accel,
    # 并为高分屏（aarch64 内屏 2x）显式提升 scroll-factor 至 1.5。
    assert_contains 'touchpad {' "$NIRI_COMMON_CONFIG"
    assert_contains 'tap' "$NIRI_COMMON_CONFIG"
    assert_contains 'natural-scroll' "$NIRI_COMMON_CONFIG"
    assert_contains 'dwt' "$NIRI_COMMON_CONFIG"
    assert_contains 'click-method "clickfinger"' "$NIRI_COMMON_CONFIG"
    assert_contains 'scroll-method "two-finger"' "$NIRI_COMMON_CONFIG"
    assert_contains 'accel-speed 0.3' "$NIRI_COMMON_CONFIG"
    assert_contains 'scroll-factor 1.5' "$NIRI_COMMON_CONFIG"
    assert_contains 'drag-lock' "$NIRI_COMMON_CONFIG"

    # animations {} refined with per-action spring settings.
    assert_contains 'workspace-switch {' "$NIRI_COMMON_CONFIG"
    assert_contains 'window-open {' "$NIRI_COMMON_CONFIG"
    assert_contains 'window-close {' "$NIRI_COMMON_CONFIG"
    assert_contains 'window-resize {' "$NIRI_COMMON_CONFIG"
    assert_contains 'spring damping-ratio=0.8 stiffness=800 epsilon=0.0001' "$NIRI_COMMON_CONFIG"
}

test_niri_config_has_dingtalk_and_app_window_rules() {
    assert_not_contains 'com\.alibabainc\.dingtalk' "$NIRI_CONFIG"
    assert_not_contains 'tblive' "$NIRI_CONFIG"
    # Window rules and blur live in the shared common.kdl.
    assert_contains 'blur {' "$NIRI_COMMON_CONFIG"
    assert_contains 'passes 3' "$NIRI_COMMON_CONFIG"
    assert_contains 'offset 3.0' "$NIRI_COMMON_CONFIG"
    assert_contains 'noise 0.02' "$NIRI_COMMON_CONFIG"
    assert_contains 'saturation 1.5' "$NIRI_COMMON_CONFIG"
    assert_contains 'draw-border-with-background false' "$NIRI_COMMON_CONFIG"
    assert_contains 'opacity 0.88' "$NIRI_COMMON_CONFIG"
    assert_contains 'background-effect {' "$NIRI_COMMON_CONFIG"
    assert_contains 'blur true' "$NIRI_COMMON_CONFIG"
    assert_contains '全局窗口默认启用 0.88 透明度和 niri 背景模糊' "$NIRI_README"
    assert_contains 'match app-id=r#"^(org\.kde\.polkit-kde-authentication-agent-1|pinentry|ssh-askpass)$"#' "$NIRI_COMMON_CONFIG"
    assert_contains 'open-floating true
    opacity 1.0' "$NIRI_COMMON_CONFIG"
    assert_contains '认证窗口强制浮动并覆盖为 1.0 不透明度' "$NIRI_README"
    assert_contains 'match app-id=r#"^CherryStudio$"#' "$NIRI_COMMON_CONFIG"
    assert_contains 'default-column-width { proportion 0.66667; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'match app-id=r#"^google-chrome$"#' "$NIRI_COMMON_CONFIG"
    assert_contains 'match app-id=r#"^com\.alibabainc\.dingtalk$"#' "$NIRI_COMMON_CONFIG"
    assert_contains '钉钉主窗口默认使用 2/3 列宽并覆盖为 1.0 不透明度' "$NIRI_README"
    # 钉钉弹窗（@ 候选框等）标题不稳定（MainMenuPanelView/Form/…），无法按 title 定向；
    # app-id 级 open-focused false 只影响新 map 窗口：弹窗不抢焦点，主窗口焦点全程不变。
    assert_contains 'match app-id=r#"^com\.alibabainc\.dingtalk$"#
    open-focused false' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'title=r#"^MainMenuPanelView$"#' "$NIRI_COMMON_CONFIG"
    assert_contains '钉钉弹窗不抢焦点' "$NIRI_README"
    # 钉钉弹窗（表情面板等 resizable 弹层）除主窗口外全部浮动：X11 EWMH 类型提示不被
    # xwayland-satellite 翻译，niri 只自动浮动固定尺寸窗口；exclude 主窗口标题（实测稳定）。
    assert_contains 'match app-id=r#"^com\.alibabainc\.dingtalk$"#
    exclude title=r#"^钉钉|钉钉$"#
    open-floating true' "$NIRI_COMMON_CONFIG"
    assert_contains '钉钉弹窗（表情面板等）除主窗口外全部浮动' "$NIRI_README"
    # focus-follows-mouse 保持禁用（2026-08-29 用户决策；曾怀疑与钉钉 @ 候选框消失有关，
    # 实测禁用后问题依旧，两者无关，保持 niri 默认关闭为偏好）。
    assert_not_contains 'focus-follows-mouse' "$NIRI_COMMON_CONFIG"
    assert_contains '禁用 focus-follows-mouse' "$NIRI_README"
    # ubuntu_aarch64/config.kdl 在 include common.kdl 后还有全局透明规则，
    # 必须再次覆盖钉钉，确保最终生效的是 1.0。
    assert_contains 'match app-id=r#"^com\.alibabainc\.dingtalk$"#' "$NIRI_AARCH64_CONFIG"
    assert_contains 'opacity 1.0' "$NIRI_AARCH64_CONFIG"
    assert_not_contains 'opacity 0.72' "$NIRI_COMMON_CONFIG"
    assert_contains 'match app-id=r#"^code$"#' "$NIRI_COMMON_CONFIG"
    assert_contains 'match app-id=r#"^trae-cn$"#' "$NIRI_COMMON_CONFIG"
    assert_contains 'default-column-width { proportion 1.0; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Cherry Studio 默认列宽为 2/3 屏' "$NIRI_README"
    assert_contains 'Chrome 默认列宽为 2/3 屏' "$NIRI_README"
    assert_contains '透明度和背景模糊不做 Chrome 特例' "$NIRI_README"
    assert_not_contains 'Chrome 额外覆盖为 0.72 透明度' "$NIRI_README"
    assert_contains 'VS Code 默认列宽为 1.0' "$NIRI_README"
}

test_niri_overview_beautification() {
    assert_contains 'background-color "transparent"' "$NIRI_COMMON_CONFIG"
    assert_contains 'overview {' "$NIRI_COMMON_CONFIG"
    assert_contains 'backdrop-color "#1e1e2e"' "$NIRI_COMMON_CONFIG"
    assert_contains 'workspace-shadow {' "$NIRI_COMMON_CONFIG"
    assert_contains 'Overview 美化' "$NIRI_README"
}

test_readme_documents_parallel_trial_and_fallback() {
    assert_file_exists "$NIRI_README"
    assert_contains '并行试用 niri' "$NIRI_README"
    assert_contains 'AwesomeWM 仍是可回退桌面' "$NIRI_README"
    assert_contains 'xwayland-satellite' "$NIRI_README"
    assert_contains 'niri validate -c .config/linux/niri/ubuntu_x64/config.kdl' "$NIRI_README"
    assert_contains 'niri validate -c .config/linux/niri/ubuntu_aarch64/config.kdl' "$NIRI_README"
    assert_contains './tests/niri_config_test.sh' "$NIRI_README"
    assert_not_contains 'niri_wayland_config_test.sh' "$NIRI_README"
    assert_contains '平台配置' "$NIRI_README"
    assert_contains '仅 Ubuntu 部署本仓库的 Niri 配置' "$NIRI_README"
    assert_contains '`~/Pictures/wall`' "$NIRI_README"
    assert_not_contains '`~/Pictures` 优先' "$NIRI_README"
}

test_niri_config_exists_and_validates_when_available
test_niri_config_keeps_awesome_muscle_memory
test_niri_config_exposes_multi_monitor_navigation
test_niri_config_uses_wayland_replacements_not_x11_autostart
test_niri_aarch64_config_maps_media_tek_hybrid_outputs_and_foot_terminal
test_niri_config_uses_native_environment_cursor_and_animations
test_niri_config_has_dingtalk_and_app_window_rules
test_niri_overview_beautification
test_readme_documents_parallel_trial_and_fallback

printf 'PASS: niri config tests\n'
