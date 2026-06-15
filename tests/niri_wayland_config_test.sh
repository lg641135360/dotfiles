#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

NIRI_CONFIG=$REPO_ROOT/.config/linux/niri/ubuntu_x64/config.kdl
ARCH_NIRI_CONFIG=$REPO_ROOT/.config/linux/niri/arch_x64/config.kdl
NIRI_LEGACY_CONFIG=$REPO_ROOT/.config/linux/niri/config.kdl
NIRI_README=$REPO_ROOT/.config/linux/niri/README.md
WAYBAR_CONFIG=$REPO_ROOT/.config/linux/waybar/config
WAYBAR_STYLE=$REPO_ROOT/.config/linux/waybar/style.css
MAKO_CONFIG=$REPO_ROOT/.config/linux/mako/config
FUZZEL_CONFIG=$REPO_ROOT/.config/linux/fuzzel/fuzzel.ini
PORTAL_CONFIG=$REPO_ROOT/.config/linux/xdg-desktop-portal/niri-portals.conf
DINGTALK_SOURCE=$REPO_ROOT/tools/dingtalk-wayland-screenshare
AUTOSTART_SCRIPT=$REPO_ROOT/.config/scripts/wayland-autostart
DINGTALK_SCRIPT=$REPO_ROOT/.config/scripts/dingtalk-wayland
TERMINAL_SCRIPT=$REPO_ROOT/.config/scripts/terminal-wayland
LAUNCHER_SCRIPT=$REPO_ROOT/.config/scripts/launcher-wayland
LOCK_SCRIPT=$REPO_ROOT/.config/scripts/lock-wayland
SCREENSHOT_SCRIPT=$REPO_ROOT/.config/scripts/screenshot-wayland
WALLPAPER_SCRIPT=$REPO_ROOT/.config/scripts/wallpaper-wayland
WALLPAPER_NEXT_SCRIPT=$REPO_ROOT/.config/scripts/wallpaper-wayland-next
INSTALL_FILE=$REPO_ROOT/install.sh

test_niri_config_exists_and_validates_when_available() {
    assert_file_exists "$NIRI_CONFIG"
    assert_file_exists "$ARCH_NIRI_CONFIG"
    assert_file_not_exists "$NIRI_LEGACY_CONFIG"

    if command -v niri >/dev/null 2>&1; then
        niri validate -c "$NIRI_CONFIG" >/dev/null 2>&1 ||
            fail "expected niri config to validate with installed niri"
        niri validate -c "$ARCH_NIRI_CONFIG" >/dev/null 2>&1 ||
            fail "expected Arch niri config to validate with installed niri"
    fi
}

test_niri_config_keeps_awesome_muscle_memory() {
    assert_contains 'spawn-sh-at-startup "~/.config/scripts/wayland-autostart"' "$NIRI_CONFIG"
    assert_contains 'Mod+Return hotkey-overlay-title="打开终端" { spawn "~/.config/scripts/terminal-wayland"; }' "$NIRI_CONFIG"
    assert_contains 'Mod+C hotkey-overlay-title="启动应用" { spawn "~/.config/scripts/launcher-wayland"; }' "$NIRI_CONFIG"
    assert_contains 'Mod+Q repeat=false hotkey-overlay-title="关闭当前窗口" { close-window; }' "$NIRI_CONFIG"
    assert_contains 'Mod+Shift+L repeat=false hotkey-overlay-title="锁屏" { spawn "~/.config/scripts/lock-wayland"; }' "$NIRI_CONFIG"
    assert_contains 'Mod+Shift+W hotkey-overlay-title="切换壁纸" { spawn "~/.config/scripts/wallpaper-wayland-next"; }' "$NIRI_CONFIG"
    assert_contains 'Mod+Shift+W hotkey-overlay-title="切换壁纸" { spawn "~/.config/scripts/wallpaper-wayland-next"; }' "$ARCH_NIRI_CONFIG"
    assert_contains 'Mod+O hotkey-overlay-title="显示总览" { toggle-overview; }' "$NIRI_CONFIG"
    assert_contains 'Mod+H { focus-column-left; }' "$NIRI_CONFIG"
    assert_contains 'Mod+L { focus-column-right; }' "$NIRI_CONFIG"
    assert_contains 'Mod+J { focus-workspace-down; }' "$NIRI_CONFIG"
    assert_contains 'Mod+K { focus-workspace-up; }' "$NIRI_CONFIG"
    assert_contains 'Mod+Minus { set-column-width "-10%"; }' "$NIRI_CONFIG"
    assert_contains 'Mod+Equal { set-column-width "+10%"; }' "$NIRI_CONFIG"
    assert_not_contains 'Mod+Left' "$NIRI_CONFIG"
    assert_not_contains 'Mod+Right' "$NIRI_CONFIG"
    assert_not_contains 'Mod+Up' "$NIRI_CONFIG"
    assert_not_contains 'Mod+Down' "$NIRI_CONFIG"
}

test_niri_config_exposes_multi_monitor_navigation() {
    assert_contains 'Mod+A { focus-monitor-left; }' "$NIRI_CONFIG"
    assert_contains 'Mod+D { focus-monitor-right; }' "$NIRI_CONFIG"
    assert_contains 'Mod+Shift+A { move-column-to-monitor-left; }' "$NIRI_CONFIG"
    assert_contains 'Mod+Shift+D { move-column-to-monitor-right; }' "$NIRI_CONFIG"
    assert_contains 'Mod+Ctrl+Shift+A { move-workspace-to-monitor-left; }' "$NIRI_CONFIG"
    assert_contains 'Mod+Ctrl+Shift+D { move-workspace-to-monitor-right; }' "$NIRI_CONFIG"
}

test_niri_config_uses_wayland_replacements_not_x11_autostart() {
    assert_contains 'prefer-no-csd' "$NIRI_CONFIG"
    assert_contains 'screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"' "$NIRI_CONFIG"
    assert_contains '// Platform: ubuntu_x64' "$NIRI_CONFIG"
    assert_contains 'output "DP-4" {' "$NIRI_CONFIG"
    assert_contains 'output "HDMI-A-3" {' "$NIRI_CONFIG"
    assert_contains 'scale 1.25' "$NIRI_CONFIG"
    assert_contains 'position x=2048 y=0' "$NIRI_CONFIG"
    assert_not_contains 'picom' "$NIRI_CONFIG"
    assert_not_contains 'xrandr' "$NIRI_CONFIG"
    assert_not_contains 'xinput' "$NIRI_CONFIG"
    assert_not_contains 'xautolock' "$NIRI_CONFIG"
    assert_not_contains 'feh' "$NIRI_CONFIG"
}

test_arch_niri_config_uses_current_arch_x64_output() {
    assert_contains '// Platform: arch_x64' "$ARCH_NIRI_CONFIG"
    assert_contains 'output "DP-3" {' "$ARCH_NIRI_CONFIG"
    assert_contains 'mode "3840x2160@59.997"' "$ARCH_NIRI_CONFIG"
    assert_contains 'scale 2' "$ARCH_NIRI_CONFIG"
    assert_contains 'position x=0 y=0' "$ARCH_NIRI_CONFIG"
    assert_not_contains 'scale 1.25' "$ARCH_NIRI_CONFIG"
    assert_not_contains 'output "DP-4" {' "$ARCH_NIRI_CONFIG"
    assert_not_contains 'output "HDMI-A-3" {' "$ARCH_NIRI_CONFIG"
    assert_contains 'Mod+O hotkey-overlay-title="显示总览" { toggle-overview; }' "$ARCH_NIRI_CONFIG"
    assert_contains 'Mod+H { focus-column-left; }' "$ARCH_NIRI_CONFIG"
    assert_contains 'Mod+J { focus-workspace-down; }' "$ARCH_NIRI_CONFIG"
    assert_not_contains 'Mod+Left' "$ARCH_NIRI_CONFIG"
    assert_not_contains 'com\.alibabainc\.dingtalk' "$ARCH_NIRI_CONFIG"
}

test_niri_config_keeps_dingtalk_unmanaged_and_has_app_window_rules() {
    assert_not_contains 'com\.alibabainc\.dingtalk' "$NIRI_CONFIG"
    assert_not_contains 'tblive' "$NIRI_CONFIG"
    assert_contains '钉钉不再由 niri window-rule 管理' "$NIRI_README"
    assert_contains 'blur {' "$NIRI_CONFIG"
    assert_contains 'passes 3' "$NIRI_CONFIG"
    assert_contains 'offset 3.0' "$NIRI_CONFIG"
    assert_contains 'noise 0.02' "$NIRI_CONFIG"
    assert_contains 'saturation 1.5' "$NIRI_CONFIG"
    assert_contains 'draw-border-with-background false' "$NIRI_CONFIG"
    assert_contains 'opacity 0.88' "$NIRI_CONFIG"
    assert_contains 'background-effect {' "$NIRI_CONFIG"
    assert_contains 'blur true' "$NIRI_CONFIG"
    assert_contains '全局窗口默认启用 0.88 透明度和 niri 背景模糊' "$NIRI_README"
    assert_contains 'match app-id=r#"^CherryStudio$"#' "$NIRI_CONFIG"
    assert_contains 'default-column-width { proportion 0.66667; }' "$NIRI_CONFIG"
    assert_contains 'match app-id=r#"^google-chrome$"#' "$NIRI_CONFIG"
    assert_not_contains 'opacity 0.72' "$NIRI_CONFIG"
    assert_not_contains 'opacity 0.72' "$ARCH_NIRI_CONFIG"
    assert_contains 'match app-id=r#"^code$"#' "$NIRI_CONFIG"
    assert_contains 'default-column-width { proportion 1.0; }' "$NIRI_CONFIG"
    assert_contains 'Cherry Studio 默认列宽为 2/3 屏' "$NIRI_README"
    assert_contains 'Chrome 默认列宽为 2/3 屏' "$NIRI_README"
    assert_contains '透明度和背景模糊不做 Chrome 特例' "$NIRI_README"
    assert_not_contains 'Chrome 额外覆盖为 0.72 透明度' "$NIRI_README"
    assert_contains 'VS Code 默认列宽为 1.0' "$NIRI_README"
}

test_wayland_autostart_runs_only_wayland_safe_services() {
    assert_executable "$AUTOSTART_SCRIPT"
    assert_contains 'run_once' "$AUTOSTART_SCRIPT"
    assert_contains "run_once '(^|/)waybar( |$)' waybar" "$AUTOSTART_SCRIPT"
    assert_contains "run_once '(^|/)mako( |$)' mako" "$AUTOSTART_SCRIPT"
    assert_contains "run_once '(^|/)nm-applet( |$)' nm-applet" "$AUTOSTART_SCRIPT"
    assert_contains "run_once '(^|/)pasystray( |$)' pasystray" "$AUTOSTART_SCRIPT"
    assert_contains "run_once '(^|/)blueman-applet( |$)' blueman-applet" "$AUTOSTART_SCRIPT"
    assert_contains "run_once '(^|/)pot( |$)' pot" "$AUTOSTART_SCRIPT"
    assert_contains "run_once '(^|/)udiskie( |$)' udiskie -t" "$AUTOSTART_SCRIPT"
    assert_contains 'export INPUT_METHOD=fcitx' "$AUTOSTART_SCRIPT"
    assert_contains 'dbus-update-activation-environment --systemd' "$AUTOSTART_SCRIPT"
    assert_contains 'systemctl --user import-environment' "$AUTOSTART_SCRIPT"
    assert_contains 'fcitx5 -d --replace' "$AUTOSTART_SCRIPT"
    assert_contains 'export XCURSOR_SIZE=32' "$AUTOSTART_SCRIPT"
    assert_contains 'swaybg' "$AUTOSTART_SCRIPT"
    assert_contains 'wallpaper-wayland-next' "$NIRI_README"
    assert_contains 'gammastep -m wayland -l 30.6:114.3 -t 6500:4000' "$AUTOSTART_SCRIPT"
    assert_contains 'start_gammastep' "$AUTOSTART_SCRIPT"
    assert_contains 'wayland-autostart.log' "$AUTOSTART_SCRIPT"
    assert_contains 'swayidle -w timeout 600 "$HOME/.config/scripts/lock-wayland" before-sleep "$HOME/.config/scripts/lock-wayland"' "$AUTOSTART_SCRIPT"
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
    assert_not_contains '/usr/share/backgrounds' "$WALLPAPER_SCRIPT"
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
    assert_order 'exec alacritty "$@"' 'exec kitty "$@"' "$TERMINAL_SCRIPT"
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
    assert_contains 'F1 { spawn "~/.config/scripts/screenshot-wayland"; }' "$NIRI_CONFIG"
    assert_contains 'F1 { spawn "~/.config/scripts/screenshot-wayland"; }' "$ARCH_NIRI_CONFIG"
    assert_not_contains 'Print { spawn "~/.config/scripts/screenshot-wayland"; }' "$NIRI_CONFIG"
    assert_not_contains 'Print { spawn "~/.config/scripts/screenshot-wayland"; }' "$ARCH_NIRI_CONFIG"
    assert_contains 'Ctrl+Print { screenshot-screen; }' "$NIRI_CONFIG"
    assert_contains 'Alt+Print { screenshot-window; }' "$NIRI_CONFIG"
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
    assert_contains 'preload_libs="$hook_lib $preload_libs ./plugins/dtwebview/libcef.so"' "$DINGTALK_SCRIPT"
    assert_contains 'export LD_PRELOAD="$preload_libs${LD_PRELOAD:+ $LD_PRELOAD}"' "$DINGTALK_SCRIPT"
    assert_contains 'DINGTALK_WAYLAND_LOG' "$DINGTALK_SCRIPT"
    assert_contains '/tmp/dingtalk-wayland.log' "$DINGTALK_SCRIPT"
    assert_contains 'nohup ./com.alibabainc.dingtalk' "$DINGTALK_SCRIPT"
    assert_contains '>>"$log_file" 2>&1 </dev/null &' "$DINGTALK_SCRIPT"
    assert_contains 'exit 0' "$DINGTALK_SCRIPT"
    assert_contains 'SPA_FORMAT_VIDEO_modifier' "$DINGTALK_SOURCE/payload.hpp"
    assert_contains 'SPA_POD_PROP_FLAG_MANDATORY' "$DINGTALK_SOURCE/payload.hpp"
    assert_contains 'DRM_FORMAT_MOD_LINEAR' "$DINGTALK_SOURCE/payload.hpp"
    assert_contains 'SPA_DATA_DmaBuf' "$DINGTALK_SOURCE/payload.hpp"
    assert_contains 'DMA_BUF_IOCTL_SYNC' "$DINGTALK_SOURCE/payload.hpp"
    assert_contains 'mmap(nullptr, mapped_size, PROT_READ, MAP_SHARED, pw_data.fd, pw_data.mapoffset)' "$DINGTALK_SOURCE/payload.hpp"
    assert_contains 'dingtalk_debug_log' "$DINGTALK_SOURCE/helpers.hpp"
    assert_contains 'tools/dingtalk-wayland-screenshare' "$NIRI_README"
    assert_contains '~/.local/lib/dingtalk-wayland-screenshare/build/libdingtalkhook.so' "$NIRI_README"
    assert_contains 'no more input formats' "$NIRI_README"
    assert_contains 'DmaBuf' "$NIRI_README"
}

test_fuzzel_config_matches_wayland_launcher_contract() {
    assert_file_exists "$FUZZEL_CONFIG"
    assert_contains 'font=Noto Sans CJK SC:size=13' "$FUZZEL_CONFIG"
    assert_contains 'terminal=~/.config/scripts/terminal-wayland' "$FUZZEL_CONFIG"
    assert_contains 'prompt=应用 >' "$FUZZEL_CONFIG"
    assert_contains 'placeholder=输入应用名或命令' "$FUZZEL_CONFIG"
    assert_contains 'width=58' "$FUZZEL_CONFIG"
    assert_contains 'line-height=28' "$FUZZEL_CONFIG"
    assert_contains 'match-mode=fuzzy' "$FUZZEL_CONFIG"
    assert_contains 'filter-desktop=yes' "$FUZZEL_CONFIG"
    assert_contains 'match-counter=yes' "$FUZZEL_CONFIG"
    assert_contains 'background=15161dee' "$FUZZEL_CONFIG"
    assert_contains 'prompt=94e2d5ff' "$FUZZEL_CONFIG"
    assert_contains 'input=f5e0dcff' "$FUZZEL_CONFIG"
    assert_contains 'selection=2a2d3aff' "$FUZZEL_CONFIG"
    assert_contains 'border=94e2d5ff' "$FUZZEL_CONFIG"
}

test_waybar_and_mako_match_niri_trial_contract() {
    assert_file_exists "$WAYBAR_CONFIG"
    assert_file_exists "$WAYBAR_STYLE"
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
    assert_contains '"modules-right": ["network", "cpu", "memory", "pulseaudio", "tray"]' "$WAYBAR_CONFIG"
    assert_contains '"format-wifi": "↓{bandwidthDownBytes} ↑{bandwidthUpBytes}"' "$WAYBAR_CONFIG"
    assert_contains '"format-ethernet": "↓{bandwidthDownBytes} ↑{bandwidthUpBytes}"' "$WAYBAR_CONFIG"
    assert_contains '下载：{bandwidthDownBytes}/s' "$WAYBAR_CONFIG"
    assert_contains '上传：{bandwidthUpBytes}/s' "$WAYBAR_CONFIG"
    assert_contains 'SSID：{essid}' "$WAYBAR_CONFIG"
    assert_contains '"format": "CPU:{usage}%"' "$WAYBAR_CONFIG"
    assert_contains '"format": "MEM:{percentage}%"' "$WAYBAR_CONFIG"
    assert_contains '"format": "VOL:{volume}%"' "$WAYBAR_CONFIG"
    assert_contains 'font-family: "Maple Mono NF CN", "JetBrainsMono Nerd Font", "Noto Sans CJK SC", sans-serif;' "$WAYBAR_STYLE"
    assert_contains 'background: transparent;' "$WAYBAR_STYLE"
    assert_contains 'background: rgba(30, 30, 46, 0.95);' "$WAYBAR_STYLE"
    assert_contains 'border-radius: 12px;' "$WAYBAR_STYLE"
    assert_contains '#workspaces button.empty' "$WAYBAR_STYLE"
    assert_contains '#workspaces button.focused' "$WAYBAR_STYLE"
    assert_contains 'transition: color 0.15s ease, background 0.15s ease, opacity 0.15s ease;' "$WAYBAR_STYLE"
    assert_contains '#workspaces button:hover' "$WAYBAR_STYLE"
    assert_contains '#clock:hover,' "$WAYBAR_STYLE"
    assert_contains '#tray > .needs-attention' "$WAYBAR_STYLE"
    assert_contains 'background-color=#1e1e2ef2' "$MAKO_CONFIG"
    assert_contains 'border-color=#89b4fa' "$MAKO_CONFIG"
    assert_contains 'font=Maple Mono NF CN 11' "$MAKO_CONFIG"
    assert_contains 'border-radius=10' "$MAKO_CONFIG"
    assert_contains '[urgency=critical]' "$MAKO_CONFIG"

    assert_contains '"$HOME/Pictures/wall"' "$WALLPAPER_SCRIPT"
    assert_not_contains '"$HOME/Pictures"' "$WALLPAPER_SCRIPT"
    assert_not_contains '"$HOME/Pictures/Wallpapers"' "$WALLPAPER_SCRIPT"
    assert_not_contains '"$HOME/Pictures/wallpapers"' "$WALLPAPER_SCRIPT"
}

test_install_deploys_wayland_trial_files() {
    assert_contains 'is_wayland_session()' "$INSTALL_FILE"
    assert_contains '[ "${XDG_SESSION_TYPE:-}" = "wayland" ] || [ -n "${WAYLAND_DISPLAY:-}" ]' "$INSTALL_FILE"
    assert_contains 'linux_wayland_configs=(' "$INSTALL_FILE"
    assert_contains 'linux_wayland_dir_configs=(' "$INSTALL_FILE"
    assert_contains '|.config/scripts/wayland-autostart|~/.config/scripts/wayland-autostart|Wayland autostart script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/dingtalk-wayland|~/.config/scripts/dingtalk-wayland|DingTalk Wayland script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/terminal-wayland|~/.config/scripts/terminal-wayland|Wayland terminal script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/launcher-wayland|~/.config/scripts/launcher-wayland|Wayland launcher script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/lock-wayland|~/.config/scripts/lock-wayland|Wayland lock script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/screenshot-wayland|~/.config/scripts/screenshot-wayland|Wayland screenshot script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/wallpaper-wayland|~/.config/scripts/wallpaper-wayland|Wayland wallpaper script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/wallpaper-wayland-next|~/.config/scripts/wallpaper-wayland-next|Wayland wallpaper switcher' "$INSTALL_FILE"
    assert_contains '|.config/linux/xdg-desktop-portal/niri-portals.conf|~/.local/share/xdg-desktop-portal/niri-portals.conf|niri desktop portal preferences' "$INSTALL_FILE"
    assert_contains 'install_niri_config_for_platform()' "$INSTALL_FILE"
    assert_contains "printf 'ubuntu_x64'" "$INSTALL_FILE"
    assert_contains "printf 'arch_x64'" "$INSTALL_FILE"
    assert_contains 'source="$cur_path/.config/linux/niri/$platform/config.kdl"' "$INSTALL_FILE"
    assert_contains 'copy_config "$source" "$HOME/.config/niri/config.kdl" "niri config ($platform)"' "$INSTALL_FILE"
    assert_not_contains 'command -v niri|.config/linux/niri|~/.config/niri|niri' "$INSTALL_FILE"
    assert_contains 'command -v waybar|.config/linux/waybar|~/.config/waybar|Waybar' "$INSTALL_FILE"
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
}

test_install_skips_wayland_files_outside_wayland_session() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin

    mkdir -p "$home_dir" "$bin_dir"
    prepare_install_path "$bin_dir"

    PATH=$bin_dir HOME=$home_dir XDG_SESSION_TYPE=x11 WAYLAND_DISPLAY= /bin/bash "$REPO_ROOT/install.sh" >/dev/null 2>&1 ||
        fail "install.sh should succeed outside Wayland session"

    [ ! -e "$home_dir/.config/scripts/wayland-autostart" ] ||
        fail "expected Wayland scripts to be skipped outside Wayland session"
    [ ! -e "$home_dir/.config/niri" ] ||
        fail "expected niri config to be skipped outside Wayland session"

    rm -rf "$tmpdir"
}

test_install_copies_wayland_files_in_wayland_session() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin

    mkdir -p "$home_dir" "$bin_dir"
    prepare_install_path "$bin_dir"

    PATH=$bin_dir HOME=$home_dir DOTFILES_OS=Linux DOTFILES_DISTRO=ubuntu DOTFILES_ARCH=x86_64 XDG_SESSION_TYPE=wayland /bin/bash "$REPO_ROOT/install.sh" >/dev/null 2>&1 ||
        fail "install.sh should succeed in Wayland session"

    assert_file_exists "$home_dir/.config/scripts/wayland-autostart"
    assert_file_exists "$home_dir/.config/niri/config.kdl"
    assert_file_not_exists "$home_dir/.config/niri/README.md"
    assert_contains '// Platform: ubuntu_x64' "$home_dir/.config/niri/config.kdl"

    rm -rf "$tmpdir"
}

test_install_copies_arch_x64_niri_config_in_wayland_session() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin

    mkdir -p "$home_dir" "$bin_dir"
    prepare_install_path "$bin_dir"

    PATH=$bin_dir HOME=$home_dir DOTFILES_OS=Linux DOTFILES_DISTRO=arch DOTFILES_ARCH=x86_64 XDG_SESSION_TYPE=wayland /bin/bash "$REPO_ROOT/install.sh" >/dev/null 2>&1 ||
        fail "install.sh should succeed on Arch x64 Wayland"

    assert_file_exists "$home_dir/.config/scripts/wayland-autostart"
    assert_file_exists "$home_dir/.config/niri/config.kdl"
    assert_contains '// Platform: arch_x64' "$home_dir/.config/niri/config.kdl"
    assert_contains 'scale 2' "$home_dir/.config/niri/config.kdl"

    rm -rf "$tmpdir"
}

test_install_skips_niri_config_for_unmapped_platform() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin

    mkdir -p "$home_dir" "$bin_dir"
    prepare_install_path "$bin_dir"

    PATH=$bin_dir HOME=$home_dir DOTFILES_OS=Linux DOTFILES_DISTRO=fedora DOTFILES_ARCH=x86_64 XDG_SESSION_TYPE=wayland /bin/bash "$REPO_ROOT/install.sh" >/dev/null 2>&1 ||
        fail "install.sh should succeed on Wayland even when niri platform mapping is unsupported"

    assert_file_exists "$home_dir/.config/scripts/wayland-autostart"
    assert_file_not_exists "$home_dir/.config/niri/config.kdl"

    rm -rf "$tmpdir"
}

test_install_copies_wayland_files_when_wayland_display_is_set() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin

    mkdir -p "$home_dir" "$bin_dir"
    prepare_install_path "$bin_dir"

    PATH=$bin_dir HOME=$home_dir DOTFILES_OS=Linux DOTFILES_DISTRO=ubuntu DOTFILES_ARCH=x86_64 XDG_SESSION_TYPE= WAYLAND_DISPLAY=wayland-1 /bin/bash "$REPO_ROOT/install.sh" >/dev/null 2>&1 ||
        fail "install.sh should detect Wayland from WAYLAND_DISPLAY"

    assert_file_exists "$home_dir/.config/scripts/wayland-autostart"
    assert_file_exists "$home_dir/.config/niri/config.kdl"

    rm -rf "$tmpdir"
}

test_readme_documents_parallel_trial_and_fallback() {
    assert_file_exists "$NIRI_README"
    assert_contains '并行试用 niri' "$NIRI_README"
    assert_contains 'AwesomeWM 仍是可回退桌面' "$NIRI_README"
    assert_contains 'xwayland-satellite' "$NIRI_README"
    assert_contains 'niri validate -c .config/linux/niri/ubuntu_x64/config.kdl' "$NIRI_README"
    assert_contains '平台配置' "$NIRI_README"
    assert_contains '`arch_x64` | `.config/linux/niri/arch_x64/config.kdl` | 已落地' "$NIRI_README"
    assert_contains '`~/Pictures/wall`' "$NIRI_README"
    assert_not_contains '`~/Pictures` 优先' "$NIRI_README"
}

test_niri_config_exists_and_validates_when_available
test_niri_config_keeps_awesome_muscle_memory
test_niri_config_exposes_multi_monitor_navigation
test_niri_config_uses_wayland_replacements_not_x11_autostart
test_arch_niri_config_uses_current_arch_x64_output
test_niri_config_keeps_dingtalk_unmanaged_and_has_app_window_rules
test_wayland_autostart_runs_only_wayland_safe_services
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
test_waybar_and_mako_match_niri_trial_contract
test_install_deploys_wayland_trial_files
test_install_skips_wayland_files_outside_wayland_session
test_install_copies_wayland_files_in_wayland_session
test_install_copies_arch_x64_niri_config_in_wayland_session
test_install_skips_niri_config_for_unmapped_platform
test_install_copies_wayland_files_when_wayland_display_is_set
test_readme_documents_parallel_trial_and_fallback

printf 'PASS: niri Wayland config tests\n'
