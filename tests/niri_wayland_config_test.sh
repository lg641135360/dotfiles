#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

NIRI_CONFIG=$REPO_ROOT/.config/linux/niri/ubuntu_x64/config.kdl
NIRI_AARCH64_CONFIG=$REPO_ROOT/.config/linux/niri/ubuntu_aarch64/config.kdl
NIRI_COMMON_CONFIG=$REPO_ROOT/.config/linux/niri/common.kdl
NIRI_README=$REPO_ROOT/.config/linux/niri/README.md
WAYBAR_CONFIG=$REPO_ROOT/.config/linux/waybar/config
WAYBAR_AARCH64_CONFIG=$REPO_ROOT/.config/linux/waybar/config.aarch64
WAYBAR_STYLE=$REPO_ROOT/.config/linux/waybar/style.css
WAYBAR_MOCHA=$REPO_ROOT/.config/linux/waybar/mocha.css
MAKO_CONFIG=$REPO_ROOT/.config/linux/mako/config
FUZZEL_CONFIG=$REPO_ROOT/.config/linux/fuzzel/fuzzel.ini
PORTAL_CONFIG=$REPO_ROOT/.config/linux/xdg-desktop-portal/niri-portals.conf
DINGTALK_SOURCE=$REPO_ROOT/tools/dingtalk-wayland-screenshare
AUTOSTART_SCRIPT=$REPO_ROOT/.config/scripts/wayland-autostart
FILE_MANAGER_SCRIPT=$REPO_ROOT/.config/scripts/file-manager-wayland
DINGTALK_SCRIPT=$REPO_ROOT/.config/scripts/dingtalk-wayland
TERMINAL_SCRIPT=$REPO_ROOT/.config/scripts/terminal-wayland
LAUNCHER_SCRIPT=$REPO_ROOT/.config/scripts/launcher-wayland
LOCK_SCRIPT=$REPO_ROOT/.config/scripts/lock-wayland
SCREENSHOT_SCRIPT=$REPO_ROOT/.config/scripts/screenshot-wayland
WALLPAPER_SCRIPT=$REPO_ROOT/.config/scripts/wallpaper-wayland
WALLPAPER_NEXT_SCRIPT=$REPO_ROOT/.config/scripts/wallpaper-wayland-next
BROWSER_SCRIPT=$REPO_ROOT/.config/scripts/browser-wayland
CHROME_DESKTOP=$REPO_ROOT/.config/linux/desktop-entries/google-chrome.desktop
TRAE_SCRIPT=$REPO_ROOT/.config/scripts/trae-cn-wayland
TRAE_DESKTOP=$REPO_ROOT/.config/linux/desktop-entries/trae-cn.desktop
INSTALL_FILE=$REPO_ROOT/install.sh

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
    assert_contains 'output "DP-4" {' "$NIRI_CONFIG"
    assert_contains 'output "HDMI-A-3" {' "$NIRI_CONFIG"
    assert_contains 'scale 1.25' "$NIRI_CONFIG"
    assert_contains 'position x=2048 y=0' "$NIRI_CONFIG"
}

test_niri_aarch64_config_maps_media_tek_hybrid_outputs_and_foot_terminal() {
    # Platform config includes the shared common.kdl like every other platform.
    assert_file_exists "$NIRI_AARCH64_CONFIG"
    assert_contains '// Platform: ubuntu_aarch64' "$NIRI_AARCH64_CONFIG"
    assert_contains 'include "../common.kdl"' "$NIRI_AARCH64_CONFIG"

    # External DP-2 (AOC) at 1.25x on the left, internal eDP-1 at 2x HiDPI on the right.
    assert_contains 'output "eDP-1" {' "$NIRI_AARCH64_CONFIG"
    assert_contains 'mode "2880x1800@120"' "$NIRI_AARCH64_CONFIG"
    assert_contains 'scale 2.0' "$NIRI_AARCH64_CONFIG"
    assert_contains 'position x=2048 y=0' "$NIRI_AARCH64_CONFIG"
    assert_contains 'output "DP-2" {' "$NIRI_AARCH64_CONFIG"
    assert_contains 'mode "2560x1440@100"' "$NIRI_AARCH64_CONFIG"
    assert_contains 'scale 1.25' "$NIRI_AARCH64_CONFIG"
    assert_contains 'position x=0 y=0' "$NIRI_AARCH64_CONFIG"

    # 全平台默认 Alacritty：移除 aarch64-kitty 分支后，脚本无条件优先 alacritty，
    # kitty 仅作最后兜底。alacritty 内屏 2x 字形问题未根治，见 logs/trace.md。
    assert_not_contains 'uname -m' "$TERMINAL_SCRIPT"
    assert_not_contains 'exec foot "$@"' "$TERMINAL_SCRIPT"
    assert_contains 'exec "$HOME/.nix-profile/bin/alacritty" "$@"' "$TERMINAL_SCRIPT"
    # niri spawn PATH 不含 ~/.local/bin，脚本需补进该目录才能找到二进制安装的 kitty。
    assert_contains '$HOME/.local/bin' "$TERMINAL_SCRIPT"

    # 常驻单实例快速开窗方案已移除（kitty 冷启动 ~1.5s 改为普通冷启动，避免残留
    # socket / 登录多一个常驻窗口等维护成本）；不得再出现 socket 控制或远程控制。
    assert_not_contains 'kitty @ --to' "$TERMINAL_SCRIPT"
    assert_not_contains '--listen-on' "$TERMINAL_SCRIPT"
    assert_not_contains 'allow_remote_control' "$REPO_ROOT/.config/linux/kitty/kitty.conf"

    # aarch64 keeps transparency but disables blur: mtgpu blur is invisible.
    assert_contains 'blur false' "$NIRI_AARCH64_CONFIG"
    assert_contains 'opacity 0.88' "$NIRI_AARCH64_CONFIG"
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

    # animations {} refined with per-action spring settings.
    assert_contains 'workspace-switch {' "$NIRI_COMMON_CONFIG"
    assert_contains 'window-open {' "$NIRI_COMMON_CONFIG"
    assert_contains 'window-close {' "$NIRI_COMMON_CONFIG"
    assert_contains 'window-resize {' "$NIRI_COMMON_CONFIG"
    assert_contains 'spring damping-ratio=0.8 stiffness=800 epsilon=0.0001' "$NIRI_COMMON_CONFIG"
}

test_waybar_drops_dead_battery_module_on_desktop_platform() {
    # Ubuntu x64 target is a desktop without battery; the shared config must
    # not enable a battery module in modules-right. Battery CSS in style.css
    # is shared with aarch64 (which does use the module) and thus not dead.
    assert_not_contains '"battery"' "$WAYBAR_CONFIG"
}

test_waybar_aarch64_has_battery_module() {
    # aarch64 is a MediaTek laptop with a battery; the backlight-enabled
    # config.aarch64 variant also exposes a battery module in modules-right.
    assert_file_exists "$WAYBAR_AARCH64_CONFIG"
    assert_contains '"battery"' "$WAYBAR_AARCH64_CONFIG"
    assert_contains '"modules-right": ["network", "custom/cpu", "custom/memory", "backlight", "pulseaudio", "battery", "privacy", "tray"]' "$WAYBAR_AARCH64_CONFIG"
    # Battery styles live in the shared style.css (deployed to both platforms).
    assert_contains '#battery' "$WAYBAR_STYLE"
    assert_contains '#battery.charging' "$WAYBAR_STYLE"
    assert_contains '#battery.warning' "$WAYBAR_STYLE"
    assert_contains '#battery.critical' "$WAYBAR_STYLE"
    # AwesomeWM convention: charging green, <=35% yellow, <=15% red.
    assert_contains '"warning": 35' "$WAYBAR_AARCH64_CONFIG"
    assert_contains '"critical": 15' "$WAYBAR_AARCH64_CONFIG"
    # 背光回退到 waybar 内置 backlight 模块（最简实现）：on-scroll/on-click 直接调
    # brightnessctl，waybar 事件驱动 dp.emit() 立即重读 sysfs 刷新，不再需要 custom
    # 脚本 + 信号/watcher 的冗余方案（曾因 sandbox 里 brightnessctl 被拦截误判为
    # "无法实时更新" 而引入，实测 live 无此问题）。
    assert_contains '"backlight": {' "$WAYBAR_AARCH64_CONFIG"
    assert_contains '{percent}%' "$WAYBAR_AARCH64_CONFIG"
    assert_not_contains '"custom/backlight"' "$WAYBAR_AARCH64_CONFIG"
    assert_not_contains 'waybar-backlight' "$WAYBAR_AARCH64_CONFIG"
    assert_contains '"on-scroll-up": "brightnessctl set 5%+"' "$WAYBAR_AARCH64_CONFIG"
    assert_contains '"on-scroll-down": "brightnessctl set 5%-"' "$WAYBAR_AARCH64_CONFIG"
    # MediaTek m1000_backlight 不发出 uevent，内置模块只能靠 interval 轮询兜底；
    # 默认轮询 2s（waybar ALabel 构造参数），interval 0.1 缩到 ~100ms 贴近 vol 跟手。
    assert_contains '"interval": 0.1,' "$WAYBAR_AARCH64_CONFIG"
    assert_contains '#backlight' "$WAYBAR_STYLE"
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

test_wayland_autostart_checks_apps_and_separates_logs() {
    assert_executable "$AUTOSTART_SCRIPT"
    assert_contains 'run_once_logged' "$AUTOSTART_SCRIPT"
    assert_contains "run_once_logged waybar '(^|/)waybar( |$)' waybar" "$AUTOSTART_SCRIPT"
    assert_contains "run_once_logged mako '(^|/)mako( |$)' mako" "$AUTOSTART_SCRIPT"
    assert_contains "run_once_logged nm-applet '(^|/)nm-applet( |$)' nm-applet" "$AUTOSTART_SCRIPT"
    # pasystray 自启已移除：其音量控制能力由 waybar pulseaudio 模块 + pavucontrol
    # 覆盖，移除后 niri 会话不再有 XWayland 客户端。
    assert_not_contains "run_once_logged pasystray '(^|/)pasystray( |$)' pasystray" "$AUTOSTART_SCRIPT"
    assert_contains "run_once_logged blueman-applet '(^|/)blueman-applet( |$)' blueman-applet" "$AUTOSTART_SCRIPT"
    assert_not_contains "run_once_logged pot '(^|/)pot( |$)' pot" "$AUTOSTART_SCRIPT"
    assert_contains "run_once_logged udiskie '(^|/)udiskie( |$)' udiskie -t" "$AUTOSTART_SCRIPT"
    assert_contains '未找到命令' "$AUTOSTART_SCRIPT"
    assert_contains '${XDG_STATE_HOME:-$HOME/.local/state}/niri/autostart' "$AUTOSTART_SCRIPT"
    assert_contains 'log_file=$log_dir/$app.log' "$AUTOSTART_SCRIPT"
    assert_contains '>"$log_file" 2>&1 &' "$AUTOSTART_SCRIPT"
    assert_contains 'export INPUT_METHOD=fcitx' "$AUTOSTART_SCRIPT"
    assert_contains 'dbus-update-activation-environment --systemd' "$AUTOSTART_SCRIPT"
    assert_contains 'systemctl --user import-environment' "$AUTOSTART_SCRIPT"
    assert_contains 'start_portal_after_niri' "$AUTOSTART_SCRIPT"
    assert_contains 'org.gnome.Mutter.ScreenCast' "$AUTOSTART_SCRIPT"
    assert_contains 'xdg-desktop-portal-gnome.service' "$AUTOSTART_SCRIPT"
    assert_contains 'xdg-desktop-portal.service' "$AUTOSTART_SCRIPT"
    assert_contains 'portal.niri-session' "$AUTOSTART_SCRIPT"
    assert_not_contains 'run_once_logged xdg-desktop-portal' "$AUTOSTART_SCRIPT"
    assert_contains '等待 `org.gnome.Mutter.ScreenCast`' "$NIRI_README"
    assert_contains 'fcitx5 -d --replace' "$AUTOSTART_SCRIPT"
    assert_contains 'export XCURSOR_SIZE=32' "$AUTOSTART_SCRIPT"
    assert_contains 'swaybg' "$AUTOSTART_SCRIPT"
    assert_contains 'wallpaper-wayland-next' "$NIRI_README"
    assert_contains 'gammastep -m wayland -l 30.6:114.3 -t 6500:4800' "$AUTOSTART_SCRIPT"
    assert_contains 'start_gammastep' "$AUTOSTART_SCRIPT"
    assert_contains 'gammastep.log' "$NIRI_README"
    # aarch64 (MediaTek) 禁用 gammastep：wlr-gamma-control 压低色温/亮度会连带把
    # 外接屏压得过暗，脚本需在 aarch64 下跳过自动色温。
    assert_contains 'uname -m' "$AUTOSTART_SCRIPT"
    assert_contains 'aarch64' "$AUTOSTART_SCRIPT"
    assert_contains '跳过 gammastep：aarch64 (MediaTek) 下外接屏会过暗，已禁用自动色温' "$AUTOSTART_SCRIPT"
    assert_contains 'aarch64 跳过 `gammastep`，不启用自动色温' "$NIRI_README"
    assert_contains "timeout 1800 'systemctl suspend'" "$AUTOSTART_SCRIPT"
    assert_contains 'swayidle -w timeout 600 "$lock_script" timeout 1800 '"'"'systemctl suspend'"'"' before-sleep "$lock_script"' "$AUTOSTART_SCRIPT"
    assert_contains '/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1' "$AUTOSTART_SCRIPT"
    assert_not_contains 'picom' "$AUTOSTART_SCRIPT"
    assert_not_contains 'xrandr' "$AUTOSTART_SCRIPT"
    assert_not_contains 'xautolock' "$AUTOSTART_SCRIPT"
    assert_not_contains 'redshift' "$AUTOSTART_SCRIPT"
    assert_not_contains 'wlsunset' "$AUTOSTART_SCRIPT"
    assert_not_contains 'systemctl --user stop gammastep' "$AUTOSTART_SCRIPT"
    assert_not_contains 'gammastep-indicator' "$AUTOSTART_SCRIPT"
    assert_not_contains 'gammastep -m drm' "$AUTOSTART_SCRIPT"
    assert_not_contains 'feh --' "$AUTOSTART_SCRIPT"
    # gammastep 输出数量检测：wayland-autostart 被调用时若输出数量变化则重启 gammastep
    assert_contains 'count_niri_outputs' "$AUTOSTART_SCRIPT"
    assert_contains 'gammastep.outputs' "$AUTOSTART_SCRIPT"
    assert_contains 'niri 输出数量变化' "$AUTOSTART_SCRIPT"
    assert_not_contains 'start_gammastep_watch' "$AUTOSTART_SCRIPT"
    assert_not_contains 'gammastep-watch.pid' "$AUTOSTART_SCRIPT"
    # aarch64 kitty 常驻单实例预启动已移除（改回普通冷启动）；不得再预启动 daemon。
    assert_not_contains 'kitty-daemon' "$AUTOSTART_SCRIPT"
    assert_not_contains 'kitty --listen-on' "$AUTOSTART_SCRIPT"
}

test_wayland_autostart_logs_each_app_and_warns_for_missing_commands() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    state_dir=$tmpdir/state
    bin_dir=$tmpdir/bin
    stderr_log=$tmpdir/stderr.log

    mkdir -p "$home_dir" "$state_dir" "$bin_dir"
    ln -s "$(command -v mkdir)" "$bin_dir/mkdir"

    cat >"$bin_dir/waybar" <<'EOF'
#!/bin/sh
printf 'waybar stdout\n'
printf 'waybar stderr\n' >&2
exit 7
EOF
    chmod +x "$bin_dir/waybar"

    PATH=$bin_dir HOME=$home_dir XDG_STATE_HOME=$state_dir \
        /bin/sh "$AUTOSTART_SCRIPT" 2>"$stderr_log" ||
        fail "wayland-autostart should continue when optional commands are missing"

    log_file=$state_dir/niri/autostart/waybar.log
    attempt=0
    while [ "$attempt" -lt 50 ]; do
        if [ -f "$log_file" ] && grep -Fq '[exit] code=7' "$log_file"; then
            break
        fi
        sleep 0.05
        attempt=$((attempt + 1))
    done

    assert_file_exists "$log_file"
    assert_contains 'waybar stdout' "$log_file"
    assert_contains 'waybar stderr' "$log_file"
    assert_contains '[exit] code=7' "$log_file"
    assert_contains '未找到命令 mako' "$stderr_log"

    rm -rf "$tmpdir"
}

test_file_manager_wayland_uses_available_fallbacks() {
    assert_executable "$FILE_MANAGER_SCRIPT"
    assert_contains 'exec dolphin "$target"' "$FILE_MANAGER_SCRIPT"
    assert_contains 'exec xdg-open "$target"' "$FILE_MANAGER_SCRIPT"
    assert_contains 'exec nautilus --new-window "$target"' "$FILE_MANAGER_SCRIPT"
    assert_contains 'exec thunar "$target"' "$FILE_MANAGER_SCRIPT"
    assert_contains 'exec pcmanfm "$target"' "$FILE_MANAGER_SCRIPT"
    assert_order 'exec dolphin "$target"' 'exec xdg-open "$target"' "$FILE_MANAGER_SCRIPT"
    assert_order 'exec xdg-open "$target"' 'exec nautilus --new-window "$target"' "$FILE_MANAGER_SCRIPT"

    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    call_log=$tmpdir/call.log
    mkdir -p "$bin_dir"

    cat >"$bin_dir/xdg-open" <<'EOF'
#!/bin/sh
printf 'xdg-open %s\n' "$*" >"$FILE_MANAGER_CALL_LOG"
EOF
    chmod +x "$bin_dir/xdg-open"

    PATH=$bin_dir HOME=$tmpdir FILE_MANAGER_CALL_LOG=$call_log \
        /bin/sh "$FILE_MANAGER_SCRIPT" || fail "file manager should fall back to xdg-open"
    assert_contains "xdg-open $tmpdir" "$call_log"

    rm -rf "$tmpdir"
}

test_wayland_wallpaper_helper_covers_current_wallpaper_locations() {
    assert_executable "$WALLPAPER_SCRIPT"
    assert_executable "$WALLPAPER_NEXT_SCRIPT"
    assert_contains 'exec swaybg -i "$image" -m fill' "$WALLPAPER_SCRIPT"
    assert_contains 'pkill -x swaybg' "$WALLPAPER_NEXT_SCRIPT"
    assert_contains 'exec "$HOME/.config/scripts/wallpaper-wayland"' "$WALLPAPER_NEXT_SCRIPT"
    assert_contains 'current-wayland-wallpaper' "$WALLPAPER_SCRIPT"
    assert_contains '"$HOME/Pictures/wall"' "$WALLPAPER_SCRIPT"
    assert_not_contains '"$HOME/Pictures"' "$WALLPAPER_SCRIPT"
    assert_not_contains '"$HOME/Pictures/Wallpapers"' "$WALLPAPER_SCRIPT"
    assert_not_contains '"$HOME/Pictures/wallpapers"' "$WALLPAPER_SCRIPT"
    assert_not_contains '"$HOME/.config/wallpapers"' "$WALLPAPER_SCRIPT"
    # Mirrors the Awesome session's randomize_wallpaper fallback pool.
    assert_contains '/usr/share/backgrounds' "$WALLPAPER_SCRIPT"
    assert_contains '-maxdepth 2' "$WALLPAPER_SCRIPT"
}

test_wayland_wallpaper_helper_records_current_wallpaper() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    state_dir=$tmpdir/state
    bin_dir=$tmpdir/bin
    args_log=$tmpdir/swaybg.args
    image=$home_dir/Pictures/wall/current-wallpaper.jpg

    mkdir -p "$home_dir/Pictures/wall" "$state_dir" "$bin_dir"
    printf 'fake image\n' >"$image"

    cat >"$bin_dir/shuf" <<'EOF'
#!/bin/sh
IFS= read -r line || exit 1
printf '%s\n' "$line"
EOF
    chmod +x "$bin_dir/shuf"

    cat >"$bin_dir/swaybg" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"$SWAYBG_ARGS_LOG"
EOF
    chmod +x "$bin_dir/swaybg"

    PATH=$bin_dir:/usr/bin HOME=$home_dir XDG_STATE_HOME=$state_dir SWAYBG_ARGS_LOG=$args_log \
        /bin/sh "$WALLPAPER_SCRIPT" >/dev/null 2>&1 ||
        fail "wallpaper-wayland should start swaybg with a recorded wallpaper"

    assert_file_exists "$state_dir/dotfiles/current-wayland-wallpaper"
    assert_contains "$image" "$state_dir/dotfiles/current-wayland-wallpaper"
    assert_contains '-i' "$args_log"
    assert_contains "$image" "$args_log"
    assert_contains '-m' "$args_log"
    assert_contains 'fill' "$args_log"

    rm -rf "$tmpdir"
}

test_wayland_wallpaper_switcher_restarts_swaybg_and_reuses_helper() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin
    call_log=$tmpdir/calls.log

    mkdir -p "$home_dir/.config/scripts" "$bin_dir"

    cat >"$bin_dir/pkill" <<'EOF'
#!/bin/sh
printf 'pkill %s\n' "$*" >>"$WALLPAPER_NEXT_CALL_LOG"
EOF
    chmod +x "$bin_dir/pkill"

    cat >"$home_dir/.config/scripts/wallpaper-wayland" <<'EOF'
#!/bin/sh
printf 'wallpaper-wayland\n' >>"$WALLPAPER_NEXT_CALL_LOG"
EOF
    chmod +x "$home_dir/.config/scripts/wallpaper-wayland"

    PATH=$bin_dir:/usr/bin HOME=$home_dir WALLPAPER_NEXT_CALL_LOG=$call_log \
        /bin/sh "$WALLPAPER_NEXT_SCRIPT" >/dev/null 2>&1 ||
        fail "wallpaper-wayland-next should restart swaybg and call wallpaper-wayland"

    assert_contains 'pkill -x swaybg' "$call_log"
    assert_contains 'wallpaper-wayland' "$call_log"
    assert_order 'pkill -x swaybg' 'wallpaper-wayland' "$call_log"

    rm -rf "$tmpdir"
}

test_portal_preferences_avoid_nautilus_filechooser_requirement() {
    assert_file_exists "$PORTAL_CONFIG"
    assert_contains '[preferred]' "$PORTAL_CONFIG"
    assert_contains 'default=gnome;gtk;' "$PORTAL_CONFIG"
    assert_contains 'org.freedesktop.impl.portal.Access=gtk;' "$PORTAL_CONFIG"
    assert_contains 'org.freedesktop.impl.portal.Notification=gtk;' "$PORTAL_CONFIG"
    assert_contains 'org.freedesktop.impl.portal.Secret=gnome-keyring;' "$PORTAL_CONFIG"
    assert_contains 'org.freedesktop.impl.portal.FileChooser=gtk;' "$PORTAL_CONFIG"
}

test_launcher_and_lock_have_wayland_first_fallbacks() {
    assert_executable "$TERMINAL_SCRIPT"
    assert_executable "$LAUNCHER_SCRIPT"
    assert_executable "$LOCK_SCRIPT"
    assert_contains 'exec "$HOME/.nix-profile/bin/alacritty" "$@"' "$TERMINAL_SCRIPT"
    assert_contains 'exec alacritty "$@"' "$TERMINAL_SCRIPT"
    assert_contains 'exec kitty "$@"' "$TERMINAL_SCRIPT"
    # 全平台无条件优先 Alacritty，kitty 仅作最后兜底；因此 alacritty 一定在
    # 最后一个 kitty 兜底之前。
    alacritty_line=$(grep -nF 'exec alacritty "$@"' "$TERMINAL_SCRIPT" | head -n 1 | cut -d: -f1)
    last_kitty_line=$(grep -nF 'exec kitty "$@"' "$TERMINAL_SCRIPT" | tail -n 1 | cut -d: -f1)
    [ -n "$alacritty_line" ] && [ -n "$last_kitty_line" ] &&
        [ "$alacritty_line" -lt "$last_kitty_line" ] ||
        fail "expected 'exec alacritty' before the final kitty fallback in $TERMINAL_SCRIPT"
    assert_contains '回退 kitty' "$NIRI_README"
    assert_contains 'export INPUT_METHOD=fcitx' "$LAUNCHER_SCRIPT"
    assert_contains 'fcitx5 -d --replace' "$LAUNCHER_SCRIPT"
    assert_contains 'exec fuzzel "$@"' "$LAUNCHER_SCRIPT"
    assert_contains 'exec "$HOME/.config/scripts/rofi-launch" "$@"' "$LAUNCHER_SCRIPT"
    assert_contains 'LOCK_WAYLAND_SWAYLOCK' "$LOCK_SCRIPT"
    assert_contains 'current-wayland-wallpaper' "$LOCK_SCRIPT"
    assert_contains 'current_wallpaper_from_swaybg' "$LOCK_SCRIPT"
    assert_contains 'exec "$locker" -f --show-failed-attempts --show-keyboard-layout -i "$image" -s fill -c 11111b' "$LOCK_SCRIPT"
    assert_contains 'exec "$locker" -f --show-failed-attempts --show-keyboard-layout -c 11111b' "$LOCK_SCRIPT"
    assert_contains 'loginctl lock-session "$XDG_SESSION_ID"' "$LOCK_SCRIPT"
}

test_lock_wayland_uses_recorded_wallpaper_when_available() {
    tmpdir=$(mktemp -d)
    state_dir=$tmpdir/state
    image=$tmpdir/current-wallpaper.jpg
    args_log=$tmpdir/swaylock.args
    fake_swaylock=$tmpdir/swaylock

    mkdir -p "$state_dir/dotfiles"
    printf 'fake image\n' >"$image"
    printf '%s\n' "$image" >"$state_dir/dotfiles/current-wayland-wallpaper"

    cat >"$fake_swaylock" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"$SWAYLOCK_ARGS_LOG"
EOF
    chmod +x "$fake_swaylock"

    PATH=$tmpdir XDG_STATE_HOME=$state_dir LOCK_WAYLAND_SWAYLOCK=$fake_swaylock SWAYLOCK_ARGS_LOG=$args_log \
        /bin/sh "$LOCK_SCRIPT" >/dev/null 2>&1 ||
        fail "lock-wayland should use the recorded current wallpaper"

    assert_contains '-i' "$args_log"
    assert_contains "$image" "$args_log"
    assert_contains '-s' "$args_log"
    assert_contains 'fill' "$args_log"
    assert_contains '-c' "$args_log"
    assert_contains '11111b' "$args_log"

    rm -rf "$tmpdir"
}

test_lock_wayland_falls_back_to_color_without_wallpaper() {
    tmpdir=$(mktemp -d)
    state_dir=$tmpdir/state
    args_log=$tmpdir/swaylock.args
    fake_swaylock=$tmpdir/swaylock

    mkdir -p "$state_dir"

    cat >"$fake_swaylock" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"$SWAYLOCK_ARGS_LOG"
EOF
    chmod +x "$fake_swaylock"

    PATH=$tmpdir XDG_STATE_HOME=$state_dir LOCK_WAYLAND_SWAYLOCK=$fake_swaylock SWAYLOCK_ARGS_LOG=$args_log \
        /bin/sh "$LOCK_SCRIPT" >/dev/null 2>&1 ||
        fail "lock-wayland should fall back to the plain color lock"

    assert_not_contains '-i' "$args_log"
    assert_contains '-c' "$args_log"
    assert_contains '11111b' "$args_log"

    rm -rf "$tmpdir"
}

test_wayland_screenshot_uses_selection_and_annotation() {
    assert_executable "$SCREENSHOT_SCRIPT"
    assert_contains 'require grim' "$SCREENSHOT_SCRIPT"
    assert_contains 'require slurp' "$SCREENSHOT_SCRIPT"
    assert_contains 'require satty' "$SCREENSHOT_SCRIPT"
    assert_contains 'require wl-copy' "$SCREENSHOT_SCRIPT"
    assert_contains 'unset GTK_IM_MODULE' "$SCREENSHOT_SCRIPT"
    assert_contains 'export INPUT_METHOD=fcitx' "$SCREENSHOT_SCRIPT"
    assert_contains 'export XMODIFIERS=@im=fcitx' "$SCREENSHOT_SCRIPT"
    assert_contains 'export LC_CTYPE=${LC_CTYPE:-zh_CN.UTF-8}' "$SCREENSHOT_SCRIPT"
    assert_not_contains 'swappy' "$SCREENSHOT_SCRIPT"
    assert_not_contains 'ksnip' "$SCREENSHOT_SCRIPT"
    assert_contains 'geometry=$(slurp)' "$SCREENSHOT_SCRIPT"
    assert_contains 'grim -g "$geometry" -t ppm "$tmp_file"' "$SCREENSHOT_SCRIPT"
    assert_contains 'satty --filename "$tmp_file" --fullscreen --output-filename "$output_file"' "$SCREENSHOT_SCRIPT"
    assert_contains '--copy-command wl-copy' "$SCREENSHOT_SCRIPT"
    assert_contains '--font-family "Noto Sans CJK SC"' "$SCREENSHOT_SCRIPT"
    assert_contains '--actions-on-enter save-to-file' "$SCREENSHOT_SCRIPT"
    assert_contains '--actions-on-escape exit' "$SCREENSHOT_SCRIPT"
    assert_contains 'Mod+S repeat=false { spawn "~/.config/scripts/screenshot-wayland"; }' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'F1' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'Print { spawn "~/.config/scripts/screenshot-wayland"; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Ctrl+Print repeat=false { screenshot-screen; }' "$NIRI_COMMON_CONFIG"
    assert_contains 'Alt+Print repeat=false { screenshot-window; }' "$NIRI_COMMON_CONFIG"
    assert_not_contains 'power-off-monitors' "$NIRI_COMMON_CONFIG"
}

test_wayland_screenshot_uses_satty() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    screenshot_dir=$tmpdir/screenshots
    bin_dir=$tmpdir/bin
    grim_args=$tmpdir/grim.args
    satty_args=$tmpdir/satty.args
    satty_env=$tmpdir/satty.env

    mkdir -p "$home_dir" "$screenshot_dir" "$bin_dir"

    cat >"$bin_dir/slurp" <<'EOF'
#!/bin/sh
printf '%s\n' '100,200 300x400'
EOF
    chmod +x "$bin_dir/slurp"

    cat >"$bin_dir/grim" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"$GRIM_ARGS_LOG"
for arg do
    output_file=$arg
done
printf 'fake ppm\n' >"$output_file"
EOF
    chmod +x "$bin_dir/grim"

    cat >"$bin_dir/satty" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"$SATTY_ARGS_LOG"
{
    printf 'GTK_IM_MODULE=%s\n' "${GTK_IM_MODULE-unset}"
    printf 'INPUT_METHOD=%s\n' "${INPUT_METHOD-unset}"
    printf 'XMODIFIERS=%s\n' "${XMODIFIERS-unset}"
    printf 'LC_CTYPE=%s\n' "${LC_CTYPE-unset}"
} >"$SATTY_ENV_LOG"
EOF
    chmod +x "$bin_dir/satty"

    cat >"$bin_dir/wl-copy" <<'EOF'
#!/bin/sh
cat >/dev/null
EOF
    chmod +x "$bin_dir/wl-copy"

    PATH=$bin_dir:/usr/bin HOME=$home_dir XDG_SCREENSHOTS_DIR=$screenshot_dir \
        GRIM_ARGS_LOG=$grim_args SATTY_ARGS_LOG=$satty_args SATTY_ENV_LOG=$satty_env GTK_IM_MODULE=fcitx LC_CTYPE= \
        /bin/sh "$SCREENSHOT_SCRIPT" >/dev/null 2>&1 ||
        fail "screenshot-wayland should use Satty for Wayland screenshot annotation"

    assert_contains '-g' "$grim_args"
    assert_contains '100,200 300x400' "$grim_args"
    assert_contains '-t' "$grim_args"
    assert_contains 'ppm' "$grim_args"
    assert_contains '--filename' "$satty_args"
    assert_contains '--fullscreen' "$satty_args"
    assert_contains '--output-filename' "$satty_args"
    assert_contains "$screenshot_dir/Screenshot from" "$satty_args"
    assert_contains '--copy-command' "$satty_args"
    assert_contains 'wl-copy' "$satty_args"
    assert_contains '--font-family' "$satty_args"
    assert_contains 'Noto Sans CJK SC' "$satty_args"
    assert_contains '--actions-on-enter' "$satty_args"
    assert_contains 'save-to-file' "$satty_args"
    assert_contains '--actions-on-escape' "$satty_args"
    assert_contains 'exit' "$satty_args"
    assert_contains 'GTK_IM_MODULE=unset' "$satty_env"
    assert_contains 'INPUT_METHOD=fcitx' "$satty_env"
    assert_contains 'XMODIFIERS=@im=fcitx' "$satty_env"
    assert_contains 'LC_CTYPE=zh_CN.UTF-8' "$satty_env"

    rm -rf "$tmpdir"
}

test_dingtalk_wayland_entrypoint_preserves_preload_contract() {
    assert_executable "$DINGTALK_SCRIPT"
    assert_file_exists "$DINGTALK_SOURCE/CMakeLists.txt"
    assert_file_exists "$DINGTALK_SOURCE/payload.hpp"
    assert_file_exists "$DINGTALK_SOURCE/hook.cpp"
    assert_contains 'DINGTALK_WAYLAND_HOOK' "$DINGTALK_SCRIPT"
    assert_contains 'libdingtalkhook.so' "$DINGTALK_SCRIPT"
    assert_contains 'PipeWire is not running' "$DINGTALK_SCRIPT"
    assert_contains 'export QT_QPA_PLATFORM=xcb' "$DINGTALK_SCRIPT"
    assert_contains 'DINGTALK_FORCE_X11_CAPTURE' "$DINGTALK_SCRIPT"
    assert_contains 'preload_libs="$hook_lib $preload_libs"' "$DINGTALK_SCRIPT"
    assert_contains 'preload_libs="$preload_libs ./plugins/dtwebview/libcef.so"' "$DINGTALK_SCRIPT"
    assert_contains 'export LD_PRELOAD="$preload_libs${LD_PRELOAD:+ $LD_PRELOAD}"' "$DINGTALK_SCRIPT"
    assert_contains 'DINGTALK_WAYLAND_LOG' "$DINGTALK_SCRIPT"
    assert_contains '/tmp/dingtalk-wayland.log' "$DINGTALK_SCRIPT"
    assert_contains 'nohup ./com.alibabainc.dingtalk' "$DINGTALK_SCRIPT"
    assert_contains '>>"$log_file" 2>&1 </dev/null &' "$DINGTALK_SCRIPT"
    assert_contains 'exit 0' "$DINGTALK_SCRIPT"
    # restart 子命令：先终止当前用户名下钉钉进程，再继续走启动流程
    assert_contains 'restart)' "$DINGTALK_SCRIPT"
    assert_contains 'is_owned_dingtalk_process()' "$DINGTALK_SCRIPT"
    assert_contains 'readlink "$proc_dir/exe"' "$DINGTALK_SCRIPT"
    assert_contains 'kill -TERM "$pid"' "$DINGTALK_SCRIPT"
    assert_contains 'kill -KILL "$pid"' "$DINGTALK_SCRIPT"
    assert_not_contains 'pkill -f' "$DINGTALK_SCRIPT"
    assert_not_contains 'pgrep -f' "$DINGTALK_SCRIPT"
    assert_contains '通过 `/proc/<pid>/exe` 精确查找' "$NIRI_README"
    # 问题1：id/readlink 缺失时不得静默跳过（必须 notify+exit）
    assert_contains '缺少基础命令' "$DINGTALK_SCRIPT"
    assert_contains 'for dep in id readlink' "$DINGTALK_SCRIPT"
    # 问题2：SIGTERM 5 秒未退出则 SIGKILL 兜底（restart 语义是必须重启）
    assert_contains 'SIGKILL' "$DINGTALK_SCRIPT"
    # 问题3：提供 usage 帮助
    assert_contains 'print_usage' "$DINGTALK_SCRIPT"
    assert_contains 'usage|--help|-h' "$DINGTALK_SCRIPT"
    assert_contains 'dingtalk-wayland restart' "$DINGTALK_SCRIPT"
    assert_contains '显示此帮助' "$DINGTALK_SCRIPT"
    # 问题4：-- 分隔符支持（usage 中承诺，实际也要处理）
    assert_contains '"${1:-}" = "--"' "$DINGTALK_SCRIPT"
    assert_contains '原样透传给钉钉' "$DINGTALK_SCRIPT"
    assert_contains 'SPA_FORMAT_VIDEO_modifier' "$DINGTALK_SOURCE/payload.hpp"
    assert_contains 'SPA_POD_PROP_FLAG_MANDATORY' "$DINGTALK_SOURCE/payload.hpp"
    assert_contains 'DRM_FORMAT_MOD_LINEAR' "$DINGTALK_SOURCE/payload.hpp"
    assert_contains 'SPA_DATA_DmaBuf' "$DINGTALK_SOURCE/payload.hpp"
    assert_contains 'DMA_BUF_IOCTL_SYNC' "$DINGTALK_SOURCE/payload.hpp"
    assert_contains 'mmap(nullptr, mapped_size, PROT_READ, MAP_SHARED, pw_data.fd, pw_data.mapoffset)' "$DINGTALK_SOURCE/payload.hpp"
    assert_contains 'dingtalk_debug_log' "$DINGTALK_SOURCE/helpers.hpp"
    assert_contains 'tools/dingtalk-wayland-screenshare' "$NIRI_README"
    assert_contains 'Mod+C' "$NIRI_README"
    assert_contains 'Elevator.sh' "$NIRI_README"
    assert_contains '维护与兼容入口' "$NIRI_README"
    assert_contains '~/.local/lib/dingtalk-wayland-screenshare/build/libdingtalkhook.so' "$NIRI_README"
    assert_contains 'no more input formats' "$NIRI_README"
    assert_contains 'DmaBuf' "$NIRI_README"
    # 钉钉保持 XWayland 模式：CEF 109 Wayland 后端有搜索崩溃和 scale 不动态更新两个缺陷
    assert_not_contains '--ozone-platform=wayland' "$DINGTALK_SCRIPT"
    assert_not_contains '--enable-wayland-ime' "$DINGTALK_SCRIPT"
    assert_contains 'CEF 109' "$DINGTALK_SCRIPT"
    assert_contains 'active_to_render_terminated' "$DINGTALK_SCRIPT"
    assert_contains 'deviceScaleFactor' "$DINGTALK_SCRIPT"
    # aarch64 mtgpu 缩放输出撕裂，保留 --disable-gpu-compositing
    assert_contains 'gpu_flags' "$DINGTALK_SCRIPT"
    assert_contains 'uname -m' "$DINGTALK_SCRIPT"
    assert_contains '--disable-gpu-compositing' "$DINGTALK_SCRIPT"
}

test_fuzzel_config_matches_wayland_launcher_contract() {
    assert_file_exists "$FUZZEL_CONFIG"
    assert_contains 'font=Noto Sans CJK SC:size=13' "$FUZZEL_CONFIG"
    assert_contains 'terminal=~/.config/scripts/terminal-wayland' "$FUZZEL_CONFIG"
    assert_contains 'prompt=应用 >' "$FUZZEL_CONFIG"
    assert_contains 'width=58' "$FUZZEL_CONFIG"
    assert_contains 'line-height=28' "$FUZZEL_CONFIG"
    assert_contains 'filter-desktop=yes' "$FUZZEL_CONFIG"
    assert_contains 'background=15161dee' "$FUZZEL_CONFIG"
    assert_contains 'selection=89b4faff' "$FUZZEL_CONFIG"
    assert_contains 'selection-text=1e1e2eff' "$FUZZEL_CONFIG"
    assert_contains 'border=94e2d5ff' "$FUZZEL_CONFIG"
    assert_contains 'icon-theme=Papirus-Dark' "$FUZZEL_CONFIG"

    # Ubuntu Noble ships fuzzel 1.9.2, which predates these options (added in
    # 1.11: placeholder/use-bold/keyboard-focus/match-mode/match-counter and the
    # colors.prompt/placeholder/input/counter keys). They must NOT be present or
    # fuzzel rejects the whole config with "not a valid option".
    assert_not_contains 'placeholder=输入应用名或命令' "$FUZZEL_CONFIG"
    assert_not_contains 'use-bold' "$FUZZEL_CONFIG"
    assert_not_contains 'keyboard-focus' "$FUZZEL_CONFIG"
    assert_not_contains 'match-mode' "$FUZZEL_CONFIG"
    assert_not_contains 'match-counter' "$FUZZEL_CONFIG"
    assert_not_contains 'selection-radius' "$FUZZEL_CONFIG"
    assert_not_contains 'counter=' "$FUZZEL_CONFIG"
    assert_not_contains 'input=' "$FUZZEL_CONFIG"
    assert_not_contains 'prompt=94e2d5ff' "$FUZZEL_CONFIG"
}

test_browser_wayland_forces_native_wayland_ozone() {
    assert_executable "$BROWSER_SCRIPT"
    # Chrome does not auto-detect Wayland; the wrapper must pass the explicit
    # ozone platform flag under a Wayland session.
    assert_contains '--ozone-platform=wayland' "$BROWSER_SCRIPT"
    # Wayland text-input-v3 so fcitx5 can serve Chinese input in Chrome.
    assert_contains '--enable-wayland-ime' "$BROWSER_SCRIPT"
    assert_contains 'google-chrome-stable' "$BROWSER_SCRIPT"
    assert_contains 'WAYLAND_DISPLAY' "$BROWSER_SCRIPT"
    assert_contains 'XDG_SESSION_TYPE' "$BROWSER_SCRIPT"
    assert_contains 'exec "$browser" $flags "$@"' "$BROWSER_SCRIPT"
    assert_contains 'exec "$browser" "$@"' "$BROWSER_SCRIPT"
    # MediaTek mtgpu tears horizontally when Chrome composites on scaled
    # outputs; must disable GPU compositing on aarch64 only.
    assert_contains 'uname -m' "$BROWSER_SCRIPT"
    assert_contains 'aarch64' "$BROWSER_SCRIPT"
    assert_contains '--disable-gpu-compositing' "$BROWSER_SCRIPT"

    # fuzzel's drun launches the desktop entry, so its Exec must route Chrome
    # through the wrapper (the raw binary would use the X11 platform and fail
    # in a Wayland session).
    assert_file_exists "$CHROME_DESKTOP"
    # Repo uses a __HOME__ placeholder; install.sh substitutes $HOME at deploy time
    # so the entry is portable across machines/users.
    assert_contains 'Exec=__HOME__/.config/scripts/browser-wayland %U' "$CHROME_DESKTOP"
    assert_contains 'Exec=__HOME__/.config/scripts/browser-wayland --incognito' "$CHROME_DESKTOP"
    assert_not_contains 'Exec=/usr/bin/google-chrome-stable' "$CHROME_DESKTOP"
}

test_browser_wayland_passes_ozone_flag_only_under_wayland() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    chrome_args=$tmpdir/chrome.args

    mkdir -p "$bin_dir"
    cat >"$bin_dir/google-chrome-stable" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"$BROWSER_CHROME_ARGS_LOG"
EOF
    chmod +x "$bin_dir/google-chrome-stable"

    # Wayland session: the ozone flag must be present.
    PATH=$bin_dir WAYLAND_DISPLAY=wayland-1 XDG_SESSION_TYPE=wayland BROWSER_CHROME_ARGS_LOG=$chrome_args \
        /bin/sh "$BROWSER_SCRIPT" "https://example.org" || fail "browser-wayland should run under Wayland"
    assert_contains '--ozone-platform=wayland' "$chrome_args"
    assert_contains '--enable-wayland-ime' "$chrome_args"
    assert_contains 'https://example.org' "$chrome_args"

    # X11 session: args pass through without the ozone flag.
    PATH=$bin_dir WAYLAND_DISPLAY= XDG_SESSION_TYPE=x11 BROWSER_CHROME_ARGS_LOG=$chrome_args \
        /bin/sh "$BROWSER_SCRIPT" "https://example.org" || fail "browser-wayland should run under X11"
    assert_not_contains '--ozone-platform=wayland' "$chrome_args"
    assert_not_contains '--enable-wayland-ime' "$chrome_args"
    assert_contains 'https://example.org' "$chrome_args"

    rm -rf "$tmpdir"
}

test_trae_cn_forces_wayland_with_ime() {
    assert_executable "$TRAE_SCRIPT"
    assert_contains '--ozone-platform=wayland' "$TRAE_SCRIPT"
    # Fcitx5/Rime needs Wayland IME; must be present.
    assert_contains '--enable-wayland-ime' "$TRAE_SCRIPT"
    assert_contains 'WaylandWindowDecorations' "$TRAE_SCRIPT"
    assert_contains 'exec trae-cn' "$TRAE_SCRIPT"

    # fuzzel launches the desktop entry, so its Exec must route through the wrapper.
    assert_file_exists "$TRAE_DESKTOP"
    assert_contains 'Exec=__HOME__/.config/scripts/trae-cn-wayland %F' "$TRAE_DESKTOP"
    assert_contains 'Exec=__HOME__/.config/scripts/trae-cn-wayland --new-window %F' "$TRAE_DESKTOP"
    assert_not_contains 'Exec=/usr/share/trae-cn/trae-cn' "$TRAE_DESKTOP"
}

test_waybar_and_mako_match_niri_trial_contract() {
    assert_file_exists "$WAYBAR_CONFIG"
    assert_file_exists "$WAYBAR_STYLE"
    assert_file_exists "$WAYBAR_MOCHA"
    assert_file_exists "$MAKO_CONFIG"

    assert_contains '"modules-left": ["niri/workspaces", "custom/separator", "niri/window"]' "$WAYBAR_CONFIG"
    assert_contains '"focused": ""' "$WAYBAR_CONFIG"
    assert_contains '"active": ""' "$WAYBAR_CONFIG"
    assert_contains '"urgent": ""' "$WAYBAR_CONFIG"
    assert_contains '"empty": ""' "$WAYBAR_CONFIG"
    assert_not_contains '"1":' "$WAYBAR_CONFIG"
    assert_not_contains '"2":' "$WAYBAR_CONFIG"
    assert_not_contains '"3":' "$WAYBAR_CONFIG"
    assert_not_contains '"4":' "$WAYBAR_CONFIG"
    assert_not_contains '"5":' "$WAYBAR_CONFIG"
    assert_contains '"modules-right": ["network", "custom/cpu", "custom/memory", "pulseaudio", "privacy", "tray"]' "$WAYBAR_CONFIG"
    assert_contains '"format-wifi": "󰤨 ↓{bandwidthDownBytes} ↑{bandwidthUpBytes}"' "$WAYBAR_CONFIG"
    assert_contains '"format-ethernet": "󰈀 ↓{bandwidthDownBytes} ↑{bandwidthUpBytes}"' "$WAYBAR_CONFIG"
    assert_not_contains '"format-alt":' "$WAYBAR_CONFIG"
    assert_contains '"on-click": "nm-connection-editor"' "$WAYBAR_CONFIG"
    assert_contains '"tooltip-format-wifi": "Wi-Fi\nSSID：{essid}\n信号：{signalStrength}%\n接口：{ifname}\n地址：{ipaddr}/{cidr}"' "$WAYBAR_CONFIG"
    assert_contains '"tooltip-format-ethernet": "有线网络\n接口：{ifname}\n地址：{ipaddr}/{cidr}"' "$WAYBAR_CONFIG"
    assert_not_contains '下载：{bandwidthDownBytes}' "$WAYBAR_CONFIG"
    assert_not_contains '上传：{bandwidthUpBytes}' "$WAYBAR_CONFIG"
    assert_contains '"tooltip-format-disconnected": "网络未连接"' "$WAYBAR_CONFIG"
    assert_contains '"max-length": 52' "$WAYBAR_CONFIG"
    assert_contains '"rewrite": {' "$WAYBAR_CONFIG"
    assert_contains '"(.*) - Visual Studio Code$": "$1"' "$WAYBAR_CONFIG"
    assert_contains '"(.*) - Google Chrome$": "$1"' "$WAYBAR_CONFIG"
    assert_contains '"(.*) - Alacritty$": "$1"' "$WAYBAR_CONFIG"
    assert_contains '"format": "󰻠 {}"' "$WAYBAR_CONFIG"
    assert_contains '"format": "󰍛 {}"' "$WAYBAR_CONFIG"
    # CPU/MEM moved from built-in modules to custom modules backed by
    # waybar-system-tooltip. return-type=json means waybar reads tooltip from
    # the JSON field (tooltip-exec is ignored in json mode), so exec must
    # compute top processes each interval. Interval=5 keeps steady-state CPU
    # around 2-3%.
    assert_contains '"custom/cpu": {' "$WAYBAR_CONFIG"
    assert_contains '"custom/memory": {' "$WAYBAR_CONFIG"
    assert_contains '"exec": "$HOME/.config/scripts/waybar-system-tooltip cpu"' "$WAYBAR_CONFIG"
    assert_contains '"exec": "$HOME/.config/scripts/waybar-system-tooltip mem"' "$WAYBAR_CONFIG"
    assert_contains '"interval": 5,' "$WAYBAR_CONFIG"
    assert_contains '"return-type": "json"' "$WAYBAR_CONFIG"
    assert_contains '"tooltip": true,' "$WAYBAR_CONFIG"
    assert_contains '"escape": false,' "$WAYBAR_CONFIG"
    assert_contains '"on-click": "kitty -- htop -s PERCENT_CPU"' "$WAYBAR_CONFIG"
    assert_contains '"on-click": "kitty -- htop -s PERCENT_MEM"' "$WAYBAR_CONFIG"
    # POSIX sh: 用 printf 八进制转义构造 Nerd Font 音量图标 U+F028（UTF-8 EF 80 A8），
    # 避免 bash 专属的 ANSI-C quoting（$'...'）在 dash 下解析失败。
    vol_icon=$(printf '\357\200\250')
    assert_contains "\"format\": \"$vol_icon  {volume}%\"" "$WAYBAR_CONFIG"
    assert_contains '"format-muted": "󰝟 静音"' "$WAYBAR_CONFIG"
    # pulseaudio uses on-scroll + external wpctl; interval 1 keeps display fresh
    assert_contains '"on-scroll-up": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.0"' "$WAYBAR_CONFIG"
    assert_contains '"on-scroll-down": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"' "$WAYBAR_CONFIG"
    assert_contains '"interval": 1,' "$WAYBAR_CONFIG"
    assert_contains '"privacy": {' "$WAYBAR_CONFIG"
    assert_contains '"type": "screenshare"' "$WAYBAR_CONFIG"
    assert_contains '"type": "audio-in"' "$WAYBAR_CONFIG"
    assert_contains '"tooltip-format": "<tt><small>{calendar}</small></tt>"' "$WAYBAR_CONFIG"
    assert_contains '"iso8601": true' "$WAYBAR_CONFIG"
    assert_contains '"tooltip": false' "$WAYBAR_CONFIG"
    assert_contains '@define-color base #1e1e2e;' "$WAYBAR_MOCHA"
    assert_contains '@define-color blue #89b4fa;' "$WAYBAR_MOCHA"
    assert_contains 'font-family: "Maple Mono NF CN", "JetBrainsMono Nerd Font", "Noto Sans CJK SC", sans-serif;' "$WAYBAR_STYLE"
    assert_contains '@import "mocha.css";' "$WAYBAR_STYLE"
    assert_contains 'background-color: alpha(@base, 0.72);' "$WAYBAR_STYLE"
    assert_contains 'border: 1px solid alpha(@surface1, 0.72);' "$WAYBAR_STYLE"
    assert_contains 'background: transparent;' "$WAYBAR_STYLE"
    assert_contains 'border-radius: 12px;' "$WAYBAR_STYLE"
    assert_contains '#workspaces button.empty' "$WAYBAR_STYLE"
    assert_contains '#workspaces button.focused' "$WAYBAR_STYLE"
    assert_contains 'transition: color 0.15s ease, background-color 0.15s ease;' "$WAYBAR_STYLE"
    assert_not_contains 'border-color 0.15s ease' "$WAYBAR_STYLE"
    assert_not_contains 'opacity 0.15s ease' "$WAYBAR_STYLE"
    assert_contains '#workspaces button:hover' "$WAYBAR_STYLE"
    assert_contains '#clock:hover,' "$WAYBAR_STYLE"
    assert_contains '#network.disconnected' "$WAYBAR_STYLE"
    assert_contains '#privacy-item.screenshare' "$WAYBAR_STYLE"
    assert_contains '#privacy-item.audio-in' "$WAYBAR_STYLE"
    assert_contains '#tray > .needs-attention' "$WAYBAR_STYLE"
    assert_contains 'background-color=#1e1e2ef2' "$MAKO_CONFIG"
    assert_contains 'border-color=#89b4fa' "$MAKO_CONFIG"
    assert_contains 'font=Maple Mono NF CN 11' "$MAKO_CONFIG"
    assert_contains 'border-radius=10' "$MAKO_CONFIG"
    assert_not_contains 'icon-border-radius' "$MAKO_CONFIG"
    assert_contains '[urgency=critical]' "$MAKO_CONFIG"

    assert_contains '"$HOME/Pictures/wall"' "$WALLPAPER_SCRIPT"
    assert_not_contains '"$HOME/Pictures"' "$WALLPAPER_SCRIPT"
    assert_not_contains '"$HOME/Pictures/Wallpapers"' "$WALLPAPER_SCRIPT"
    assert_not_contains '"$HOME/Pictures/wallpapers"' "$WALLPAPER_SCRIPT"
}

test_install_deploys_wayland_trial_files() {
    assert_not_contains 'is_wayland_session()' "$INSTALL_FILE"
    assert_not_contains 'XDG_SESSION_TYPE' "$INSTALL_FILE"
    assert_not_contains 'WAYLAND_DISPLAY' "$INSTALL_FILE"
    assert_contains 'script_dir=' "$INSTALL_FILE"
    assert_contains 'cur_path=$script_dir' "$INSTALL_FILE"
    assert_contains 'linux_wayland_configs=(' "$INSTALL_FILE"
    assert_contains 'linux_wayland_dir_configs=(' "$INSTALL_FILE"
    assert_contains '|.config/scripts/wayland-autostart|~/.config/scripts/wayland-autostart|Wayland autostart script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/file-manager-wayland|~/.config/scripts/file-manager-wayland|Wayland file manager selector' "$INSTALL_FILE"
    assert_contains '|.config/scripts/dingtalk-wayland|~/.config/scripts/dingtalk-wayland|DingTalk Wayland script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/terminal-wayland|~/.config/scripts/terminal-wayland|Wayland terminal script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/launcher-wayland|~/.config/scripts/launcher-wayland|Wayland launcher script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/lock-wayland|~/.config/scripts/lock-wayland|Wayland lock script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/screenshot-wayland|~/.config/scripts/screenshot-wayland|Wayland screenshot script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/browser-wayland|~/.config/scripts/browser-wayland|Wayland browser script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/trae-cn-wayland|~/.config/scripts/trae-cn-wayland|Wayland Trae CN script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/waybar-system-tooltip|~/.config/scripts/waybar-system-tooltip|Waybar CPU/MEM tooltip script' "$INSTALL_FILE"
    # backlight 用 waybar 内置模块，不再部署独立 watcher 脚本。
    assert_not_contains 'waybar-backlight' "$INSTALL_FILE"
    assert_contains '|.config/linux/desktop-entries/google-chrome.desktop|~/.local/share/applications/google-chrome.desktop|Google Chrome Wayland desktop entry' "$INSTALL_FILE"
    assert_contains '|.config/linux/desktop-entries/trae-cn.desktop|~/.local/share/applications/trae-cn.desktop|Trae CN Wayland desktop entry' "$INSTALL_FILE"
    # install.sh substitutes the __HOME__ placeholder in desktop entries with $HOME at deploy time.
    assert_contains 's#__HOME__#$HOME#g' "$INSTALL_FILE"
    assert_contains '|.config/scripts/wallpaper-wayland|~/.config/scripts/wallpaper-wayland|Wayland wallpaper script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/wallpaper-wayland-next|~/.config/scripts/wallpaper-wayland-next|Wayland wallpaper switcher' "$INSTALL_FILE"
    assert_contains '|.config/linux/xdg-desktop-portal/niri-portals.conf|~/.local/share/xdg-desktop-portal/niri-portals.conf|niri desktop portal preferences' "$INSTALL_FILE"
    assert_contains 'if command -v niri >/dev/null 2>&1; then' "$INSTALL_FILE"
    assert_contains 'install_niri_config_for_platform()' "$INSTALL_FILE"
    assert_contains 'niri_platform_key()' "$INSTALL_FILE"
    assert_contains 'is_repo_niri_platform()' "$INSTALL_FILE"
    assert_contains "printf 'ubuntu_x64'" "$INSTALL_FILE"
    assert_contains 'is_opensuse()' "$INSTALL_FILE"
    assert_contains 'skipping Alacritty configuration copy' "$INSTALL_FILE"
    assert_contains 'skipping niri configuration copy' "$INSTALL_FILE"
    assert_contains 'source="$cur_path/.config/linux/niri/$platform/config.kdl"' "$INSTALL_FILE"
    assert_contains 'common_source="$cur_path/.config/linux/niri/common.kdl"' "$INSTALL_FILE"
    assert_contains 'copy_config "$common_source" "$target_dir/common.kdl" "niri common config"' "$INSTALL_FILE"
    assert_contains 'sed ' "$INSTALL_FILE"
    assert_contains 'include "common.kdl"' "$INSTALL_FILE"
    assert_not_contains 'command -v niri|.config/linux/niri|~/.config/niri|niri' "$INSTALL_FILE"
    assert_contains 'install_waybar_config_for_platform()' "$INSTALL_FILE"
    assert_contains '"$src_dir/config.aarch64"' "$INSTALL_FILE"
    assert_contains 'copy_config "$config_src" "$target_dir/config" "waybar config (${arch:-generic})"' "$INSTALL_FILE"
    assert_contains 'command -v mako|.config/linux/mako|~/.config/mako|Mako' "$INSTALL_FILE"
    assert_contains 'command -v fuzzel|.config/linux/fuzzel|~/.config/fuzzel|Fuzzel' "$INSTALL_FILE"
}

link_test_cmd() {
    cmd=$1
    target_dir=$2
    ln -s "$(command -v "$cmd")" "$target_dir/$cmd"
}

prepare_install_path() {
    bin_dir=$1

    for cmd in bash basename cp date diff dirname find grep head ln mkdir mv pwd rm sed sort tail uname; do
        link_test_cmd "$cmd" "$bin_dir"
    done

    cat >"$bin_dir/niri" <<'EOF'
#!/bin/sh
exit 0
EOF
    chmod +x "$bin_dir/niri"

    cat >"$bin_dir/alacritty" <<'EOF'
#!/bin/sh
exit 0
EOF
    chmod +x "$bin_dir/alacritty"
}

test_install_copies_wayland_files_when_niri_exists_outside_wayland_session() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin

    mkdir -p "$home_dir" "$bin_dir"
    prepare_install_path "$bin_dir"

    (
        cd "$tmpdir"
        PATH=$bin_dir HOME=$home_dir DOTFILES_OS=Linux DOTFILES_DISTRO=ubuntu DOTFILES_ARCH=x86_64 XDG_SESSION_TYPE=x11 WAYLAND_DISPLAY= \
            /bin/bash "$REPO_ROOT/install.sh" >/dev/null 2>&1
    ) || fail "install.sh should use its own directory and deploy niri outside Wayland"

    assert_file_exists "$home_dir/.config/scripts/wayland-autostart"
    assert_file_exists "$home_dir/.config/scripts/file-manager-wayland"
    assert_file_exists "$home_dir/.config/niri/config.kdl"

    rm -rf "$tmpdir"
}

test_install_copies_ubuntu_x64_niri_config() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin

    mkdir -p "$home_dir" "$bin_dir"
    prepare_install_path "$bin_dir"

    PATH=$bin_dir HOME=$home_dir DOTFILES_OS=Linux DOTFILES_DISTRO=ubuntu DOTFILES_ARCH=x86_64 XDG_SESSION_TYPE=wayland /bin/bash "$REPO_ROOT/install.sh" >/dev/null 2>&1 ||
        fail "install.sh should succeed in Wayland session"

    assert_file_exists "$home_dir/.config/scripts/wayland-autostart"
    assert_file_exists "$home_dir/.config/niri/config.kdl"
    assert_file_exists "$home_dir/.config/niri/common.kdl"
    assert_file_not_exists "$home_dir/.config/niri/README.md"
    assert_contains '// Platform: ubuntu_x64' "$home_dir/.config/niri/config.kdl"
    assert_contains 'include "common.kdl"' "$home_dir/.config/niri/config.kdl"
    assert_not_contains 'include "../common.kdl"' "$home_dir/.config/niri/config.kdl"
    assert_contains 'output "DP-4" {' "$home_dir/.config/niri/config.kdl"
    assert_contains 'scale 1.25' "$home_dir/.config/niri/config.kdl"

    # Desktop entries get the __HOME__ placeholder substituted with the real $HOME.
    assert_file_exists "$home_dir/.local/share/applications/google-chrome.desktop"
    assert_contains "Exec=$home_dir/.config/scripts/browser-wayland %U" "$home_dir/.local/share/applications/google-chrome.desktop"
    assert_not_contains '__HOME__' "$home_dir/.local/share/applications/google-chrome.desktop"

    rm -rf "$tmpdir"
}

test_install_preserves_arch_niri_config() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin

    mkdir -p "$home_dir" "$bin_dir"
    prepare_install_path "$bin_dir"
    mkdir -p "$home_dir/.config/niri"
    printf 'include "arch-existing.kdl"\n' >"$home_dir/.config/niri/config.kdl"
    printf 'arch common configuration\n' >"$home_dir/.config/niri/common.kdl"

    PATH=$bin_dir HOME=$home_dir DOTFILES_OS=Linux DOTFILES_DISTRO=arch DOTFILES_ARCH=x86_64 XDG_SESSION_TYPE=wayland /bin/bash "$REPO_ROOT/install.sh" >/dev/null 2>&1 ||
        fail "install.sh should succeed on Arch x64 Wayland"

    assert_file_exists "$home_dir/.config/scripts/wayland-autostart"
    assert_contains 'include "arch-existing.kdl"' "$home_dir/.config/niri/config.kdl"
    assert_contains 'arch common configuration' "$home_dir/.config/niri/common.kdl"

    rm -rf "$tmpdir"
}

test_install_preserves_opensuse_dms_niri_and_alacritty_configs() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin

    mkdir -p "$home_dir" "$bin_dir"
    prepare_install_path "$bin_dir"
    mkdir -p "$home_dir/.config/niri" "$home_dir/.config/alacritty"
    printf 'include "dms/layout.kdl"\n' >"$home_dir/.config/niri/config.kdl"
    printf 'dms common configuration\n' >"$home_dir/.config/niri/common.kdl"
    printf '[general]\nimport = ["~/.config/alacritty/dank-theme.toml"]\n' >"$home_dir/.config/alacritty/alacritty.toml"
    printf 'dms keys configuration\n' >"$home_dir/.config/alacritty/keys.toml"
    printf 'dms window configuration\n' >"$home_dir/.config/alacritty/window.toml"

    PATH=$bin_dir HOME=$home_dir DOTFILES_OS=Linux DOTFILES_DISTRO=opensuse-tumbleweed DOTFILES_ARCH=x86_64 XDG_SESSION_TYPE=wayland /bin/bash "$REPO_ROOT/install.sh" >/dev/null 2>&1 ||
        fail "install.sh should succeed on openSUSE Tumbleweed x64"

    assert_file_exists "$home_dir/.config/scripts/wayland-autostart"
    assert_contains 'include "dms/layout.kdl"' "$home_dir/.config/niri/config.kdl"
    assert_contains 'dms common configuration' "$home_dir/.config/niri/common.kdl"
    assert_contains 'dank-theme.toml' "$home_dir/.config/alacritty/alacritty.toml"
    assert_contains 'dms keys configuration' "$home_dir/.config/alacritty/keys.toml"
    assert_contains 'dms window configuration' "$home_dir/.config/alacritty/window.toml"

    rm -rf "$tmpdir"
}

test_install_keeps_live_niri_config_for_unmapped_platform() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin

    mkdir -p "$home_dir" "$bin_dir"
    prepare_install_path "$bin_dir"
    mkdir -p "$home_dir/.config/niri"
    printf 'include "existing-output.kdl"\n' >"$home_dir/.config/niri/config.kdl"

    PATH=$bin_dir HOME=$home_dir DOTFILES_OS=Linux DOTFILES_DISTRO=fedora DOTFILES_ARCH=x86_64 XDG_SESSION_TYPE=wayland /bin/bash "$REPO_ROOT/install.sh" >/dev/null 2>&1 ||
        fail "install.sh should keep the live niri config for an unmapped platform"

    assert_file_exists "$home_dir/.config/scripts/wayland-autostart"
    assert_file_exists "$home_dir/.config/niri/config.kdl"
    assert_contains 'include "existing-output.kdl"' "$home_dir/.config/niri/config.kdl"
    assert_file_not_exists "$home_dir/.config/niri/common.kdl"

    rm -rf "$tmpdir"
}

test_install_skips_niri_and_wayland_files_when_niri_is_missing() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin
    output=$tmpdir/output.log

    mkdir -p "$home_dir" "$bin_dir"
    prepare_install_path "$bin_dir"
    rm -f "$bin_dir/niri"

    PATH=$bin_dir HOME=$home_dir DOTFILES_OS=Linux DOTFILES_DISTRO=ubuntu DOTFILES_ARCH=x86_64 \
        /bin/bash "$REPO_ROOT/install.sh" >"$output" 2>&1 ||
        fail "install.sh should succeed when niri is missing"

    assert_file_not_exists "$home_dir/.config/niri/config.kdl"
    assert_file_not_exists "$home_dir/.config/scripts/wayland-autostart"
    assert_contains 'niri not found' "$output"

    rm -rf "$tmpdir"
}

test_readme_documents_parallel_trial_and_fallback() {
    assert_file_exists "$NIRI_README"
    assert_contains '并行试用 niri' "$NIRI_README"
    assert_contains 'AwesomeWM 仍是可回退桌面' "$NIRI_README"
    assert_contains 'xwayland-satellite' "$NIRI_README"
    assert_contains 'niri validate -c .config/linux/niri/ubuntu_x64/config.kdl' "$NIRI_README"
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
test_waybar_drops_dead_battery_module_on_desktop_platform
test_waybar_aarch64_has_battery_module
test_niri_config_has_dingtalk_and_app_window_rules
test_niri_overview_beautification
test_wayland_autostart_checks_apps_and_separates_logs
test_wayland_autostart_logs_each_app_and_warns_for_missing_commands
test_file_manager_wayland_uses_available_fallbacks
test_wayland_wallpaper_helper_covers_current_wallpaper_locations
test_wayland_wallpaper_helper_records_current_wallpaper
test_portal_preferences_avoid_nautilus_filechooser_requirement
test_launcher_and_lock_have_wayland_first_fallbacks
test_lock_wayland_uses_recorded_wallpaper_when_available
test_lock_wayland_falls_back_to_color_without_wallpaper
test_wayland_screenshot_uses_selection_and_annotation
test_wayland_screenshot_uses_satty
test_dingtalk_wayland_entrypoint_preserves_preload_contract
test_fuzzel_config_matches_wayland_launcher_contract
test_browser_wayland_forces_native_wayland_ozone
test_browser_wayland_passes_ozone_flag_only_under_wayland
test_trae_cn_forces_wayland_with_ime
test_waybar_and_mako_match_niri_trial_contract
test_install_deploys_wayland_trial_files
test_install_copies_wayland_files_when_niri_exists_outside_wayland_session
test_install_copies_ubuntu_x64_niri_config
test_install_preserves_arch_niri_config
test_install_preserves_opensuse_dms_niri_and_alacritty_configs
test_install_keeps_live_niri_config_for_unmapped_platform
test_install_skips_niri_and_wayland_files_when_niri_is_missing
test_readme_documents_parallel_trial_and_fallback

printf 'PASS: niri Wayland config tests\n'
