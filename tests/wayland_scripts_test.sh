#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

NIRI_README=$REPO_ROOT/.config/linux/niri/README.md
NIRI_COMMON_CONFIG=$REPO_ROOT/.config/linux/niri/common.kdl
PORTAL_CONFIG=$REPO_ROOT/.config/linux/xdg-desktop-portal/niri-portals.conf
DINGTALK_SOURCE=$REPO_ROOT/tools/dingtalk-wayland-screenshare
AUTOSTART_SCRIPT=$REPO_ROOT/.config/scripts/wayland-autostart
CLIPBOARD_SCRIPT=$REPO_ROOT/.config/scripts/clipboard-wayland
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
OBSIDIAN_SCRIPT=$REPO_ROOT/.config/scripts/obsidian-wayland
OBSIDIAN_DESKTOP=$REPO_ROOT/.config/linux/desktop-entries/obsidian.desktop

test_wayland_autostart_checks_apps_and_separates_logs() {
    assert_executable "$AUTOSTART_SCRIPT"
    assert_contains 'run_once_logged' "$AUTOSTART_SCRIPT"
    assert_contains "run_once_logged waybar '(^|/)waybar( |$)' waybar" "$AUTOSTART_SCRIPT"
    assert_contains "run_once_logged mako '(^|/)mako( |$)' mako" "$AUTOSTART_SCRIPT"
    # nm-applet 自启已移除（2026-08-26）：网络状态由 waybar network 模块覆盖，
    # 其 XDG autostart 由 ~/.config/autostart/nm-applet.desktop 的 Hidden=true 禁用。
    assert_not_contains "run_once_logged nm-applet '(^|/)nm-applet( |$)' nm-applet" "$AUTOSTART_SCRIPT"
    # pasystray 自启已移除：其音量控制能力由 waybar pulseaudio 模块 + pavucontrol
    # 覆盖，移除后 niri 会话不再有 XWayland 客户端。
    assert_not_contains "run_once_logged pasystray '(^|/)pasystray( |$)' pasystray" "$AUTOSTART_SCRIPT"
    assert_contains "run_once_logged blueman-applet '(^|/)blueman-applet( |$)' blueman-applet" "$AUTOSTART_SCRIPT"
    assert_not_contains "run_once_logged pot '(^|/)pot( |$)' pot" "$AUTOSTART_SCRIPT"
    assert_contains "run_once_logged udiskie '(^|/)udiskie( |$)' udiskie -t" "$AUTOSTART_SCRIPT"
    # 剪贴板守护由 clipboard-wayland 统一入口监管，autostart 检测监管进程，
    # 避免只剩一个子进程时误判服务完整。
    assert_contains "run_once_logged clipboard-wayland '(^|/)(ba)?sh .*/clipboard-wayland( start)?$'" "$AUTOSTART_SCRIPT"
    assert_contains '"$HOME/.config/scripts/clipboard-wayland" start' "$AUTOSTART_SCRIPT"
    assert_contains '未找到命令' "$AUTOSTART_SCRIPT"
    assert_contains '${XDG_STATE_HOME:-$HOME/.local/state}/niri/autostart' "$AUTOSTART_SCRIPT"
    assert_contains 'log_file=$log_dir/$app.log' "$AUTOSTART_SCRIPT"
    assert_contains '>"$log_file" 2>&1 &' "$AUTOSTART_SCRIPT"
    assert_contains 'export INPUT_METHOD=fcitx' "$AUTOSTART_SCRIPT"
    assert_contains 'dbus-update-activation-environment --systemd' "$AUTOSTART_SCRIPT"
    assert_contains 'systemctl --user import-environment' "$AUTOSTART_SCRIPT"
    # GTK_IM_MODULE 必须从 systemd 用户环境清除：sddm/niri-session 会把
    # im-config 注入的 GTK_IM_MODULE=fcitx 导入用户会话，Wayland GTK 应走
    # text-input-v3，否则 fcitx5 会持续弹出 Wayland 检测提示。脚本里的
    # `unset GTK_IM_MODULE` 只影响 fork 的子进程，systemd 用户环境须单独清。
    assert_contains 'unset GTK_IM_MODULE' "$AUTOSTART_SCRIPT"
    assert_contains 'systemctl --user unset-environment GTK_IM_MODULE' "$AUTOSTART_SCRIPT"
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
    assert_contains 'gammastep -m wayland -l 30.6:114.3 -t 6500:5500 -b 1.0:1.0' "$AUTOSTART_SCRIPT"
    assert_contains 'start_gammastep' "$AUTOSTART_SCRIPT"
    assert_contains 'gammastep.log' "$NIRI_README"
    # aarch64 之前的 gammastep 跳过分支已移除：全平台统一启用，改用温和夜间色温
    # 5500K + 亮度上限 -b 1.0:1.0 缓解外接屏过暗（gammastep 亮度范围 0.1~1.0）。
    assert_not_contains '跳过 gammastep：aarch64' "$AUTOSTART_SCRIPT"
    assert_not_contains 'aarch64 跳过 `gammastep`' "$NIRI_README"
    # 自动挂起已移除：挂起唤醒的网络/显示风暴会让 Electron 应用以未捕获的
    # net::ERR_INTERNET_DISCONNECTED 静默退出（VS Code / Trae）。保留 10 分钟
    # 锁屏与 before-sleep 锁屏。
    assert_not_contains "timeout 1800 'systemctl suspend'" "$AUTOSTART_SCRIPT"
    assert_contains 'swayidle -w timeout 600 "$lock_script" before-sleep "$lock_script"' "$AUTOSTART_SCRIPT"
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
    # kitty 常驻单实例预启动已随 kitty 一并移除；不得再预启动任何终端 daemon。
    assert_not_contains 'kitty-daemon' "$AUTOSTART_SCRIPT"
    assert_not_contains 'kitty --listen-on' "$AUTOSTART_SCRIPT"
    assert_not_contains 'foot-daemon' "$AUTOSTART_SCRIPT"
    assert_not_contains 'foot --listen-on' "$AUTOSTART_SCRIPT"
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
    assert_not_contains 'nix-profile' "$TERMINAL_SCRIPT"
    assert_contains 'exec alacritty "$@"' "$TERMINAL_SCRIPT"
    assert_contains 'exec foot "$@"' "$TERMINAL_SCRIPT"
    assert_not_contains 'exec kitty "$@"' "$TERMINAL_SCRIPT"
    # aarch64 + Wayland 优先 foot 分支必须在 alacritty 之前；其他平台 alacritty 在
    # 最后一个 foot 兜底之前。
    assert_contains 'uname -m' "$TERMINAL_SCRIPT"
    assert_contains 'WAYLAND_DISPLAY' "$TERMINAL_SCRIPT"
    aarch64_foot_line=$(grep -nF 'exec foot "$@"' "$TERMINAL_SCRIPT" | head -n 1 | cut -d: -f1)
    alacritty_line=$(grep -nF 'exec alacritty "$@"' "$TERMINAL_SCRIPT" | head -n 1 | cut -d: -f1)
    last_foot_line=$(grep -nF 'exec foot "$@"' "$TERMINAL_SCRIPT" | tail -n 1 | cut -d: -f1)
    [ -n "$aarch64_foot_line" ] && [ -n "$alacritty_line" ] &&
        [ "$aarch64_foot_line" -lt "$alacritty_line" ] ||
        fail "expected aarch64+Wayland foot branch before alacritty in $TERMINAL_SCRIPT"
    [ -n "$alacritty_line" ] && [ -n "$last_foot_line" ] &&
        [ "$alacritty_line" -lt "$last_foot_line" ] ||
        fail "expected 'exec alacritty' before the final foot fallback in $TERMINAL_SCRIPT"
    assert_contains '回退 foot' "$NIRI_README"
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

    # Fake uname so the wrapper's `uname -m` check resolves inside the sandbox
    # PATH (otherwise dash would emit "uname: not found" stderr noise).
    cat >"$bin_dir/uname" <<'EOF'
#!/bin/sh
printf 'x86_64\n'
EOF
    chmod +x "$bin_dir/uname"

    # Wayland session on x86_64: ozone + wayland-ime must be present; no GPU
    # compositing override (that is aarch64-only).
    PATH=$bin_dir WAYLAND_DISPLAY=wayland-1 XDG_SESSION_TYPE=wayland BROWSER_CHROME_ARGS_LOG=$chrome_args \
        /bin/sh "$BROWSER_SCRIPT" "https://example.org" || fail "browser-wayland should run under Wayland"
    assert_contains '--ozone-platform=wayland' "$chrome_args"
    assert_contains '--enable-wayland-ime' "$chrome_args"
    assert_not_contains '--disable-gpu-compositing' "$chrome_args"
    assert_contains 'https://example.org' "$chrome_args"

    # X11 session: args pass through without the ozone flag.
    PATH=$bin_dir WAYLAND_DISPLAY= XDG_SESSION_TYPE=x11 BROWSER_CHROME_ARGS_LOG=$chrome_args \
        /bin/sh "$BROWSER_SCRIPT" "https://example.org" || fail "browser-wayland should run under X11"
    assert_not_contains '--ozone-platform=wayland' "$chrome_args"
    assert_not_contains '--enable-wayland-ime' "$chrome_args"
    assert_not_contains '--disable-gpu-compositing' "$chrome_args"
    assert_contains 'https://example.org' "$chrome_args"

    # aarch64 under Wayland: must additionally disable GPU compositing to work
    # around the MediaTek mtgpu tearing issue.
    cat >"$bin_dir/uname" <<'EOF'
#!/bin/sh
printf 'aarch64\n'
EOF
    chmod +x "$bin_dir/uname"
    PATH=$bin_dir WAYLAND_DISPLAY=wayland-1 XDG_SESSION_TYPE=wayland BROWSER_CHROME_ARGS_LOG=$chrome_args \
        /bin/sh "$BROWSER_SCRIPT" "https://example.org" || fail "browser-wayland should run under Wayland/aarch64"
    assert_contains '--ozone-platform=wayland' "$chrome_args"
    assert_contains '--enable-wayland-ime' "$chrome_args"
    assert_contains '--disable-gpu-compositing' "$chrome_args"
    assert_contains 'https://example.org' "$chrome_args"

    rm -rf "$tmpdir"
}

test_clipboard_wayland_persists_and_queries_history() {
    assert_executable "$CLIPBOARD_SCRIPT"
    # 无参数 / start：直接启动 wl-clip-persist 持久化守护，并独立启动
    # wl-paste --watch cliphist store 记录历史；父脚本监管并共同清理两个子进程。
    assert_contains 'wl-clip-persist --clipboard regular &' "$CLIPBOARD_SCRIPT"
    assert_contains 'wl-paste --watch cliphist store &' "$CLIPBOARD_SCRIPT"
    assert_contains 'trap cleanup EXIT' "$CLIPBOARD_SCRIPT"
    assert_contains "trap 'exit 0' INT TERM HUP" "$CLIPBOARD_SCRIPT"
    assert_contains 'kill -0 "$persist_pid"' "$CLIPBOARD_SCRIPT"
    assert_contains 'kill -0 "$history_pid"' "$CLIPBOARD_SCRIPT"
    assert_not_contains 'wl-paste --watch wl-clip-persist' "$CLIPBOARD_SCRIPT"
    # history：cliphist list → fuzzel --dmenu → cliphist decode → wl-copy
    assert_contains 'cliphist list | fuzzel --dmenu --prompt "剪贴板 >"' "$CLIPBOARD_SCRIPT"
    assert_contains 'cliphist decode | wl-copy' "$CLIPBOARD_SCRIPT"
    # fuzzel 1.12.0（Ubuntu apt）：勿引入更新版本才有的选项
    assert_not_contains '--placeholder' "$CLIPBOARD_SCRIPT"
    # wl-clip-persist 2026-08-29 起源码编译装 /usr/local/bin，不得再含 Nix profile 补丁
    assert_not_contains 'nix-profile' "$CLIPBOARD_SCRIPT"
    # 缺依赖时提示并退出，不中断会话
    assert_contains '未找到命令' "$CLIPBOARD_SCRIPT"
    assert_contains '源码编译装 /usr/local/bin' "$CLIPBOARD_SCRIPT"

    # 行为演练：缺命令时 history 模式应报错退出（非零）
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    mkdir -p "$bin_dir"
    set +e
    PATH=$bin_dir /bin/sh "$CLIPBOARD_SCRIPT" history >"$tmpdir/out" 2>"$tmpdir/err"
    rc=$?
    set -e
    [ "$rc" -ne 0 ] || fail "clipboard-wayland history without cliphist should fail"
    assert_contains '未找到命令 cliphist' "$tmpdir/err"
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

test_obsidian_wayland_forces_wayland_with_text_input_v3() {
    assert_executable "$OBSIDIAN_SCRIPT"
    assert_contains '--ozone-platform=wayland' "$OBSIDIAN_SCRIPT"
    # Fcitx5/Rime needs Wayland IME; must be present.
    assert_contains '--enable-wayland-ime' "$OBSIDIAN_SCRIPT"
    # Obsidian 1.8.7 = Electron 33 / Chromium 130, which still defaults to
    # text-input-v1; niri only implements v3, so IME is silently dead without
    # this flag (verified on niri 26.04).
    assert_contains '--wayland-text-input-version=3' "$OBSIDIAN_SCRIPT"
    # AppImage filename embeds the version; the wrapper must discover it by
    # glob so upgrades do not break the entry.
    assert_contains "Obsidian-*.AppImage" "$OBSIDIAN_SCRIPT"
    # Launch via /usr/bin/AppImageLauncher: direct exec hits the buggy
    # binfmt interpreter (>=4 args -> unterminated argv -> execv EFAULT).
    assert_contains '/usr/bin/AppImageLauncher' "$OBSIDIAN_SCRIPT"
    assert_contains 'exec_appimage' "$OBSIDIAN_SCRIPT"

    # fuzzel launches the desktop entry, so its Exec must route through the wrapper.
    assert_file_exists "$OBSIDIAN_DESKTOP"
    assert_contains 'Exec=__HOME__/.config/scripts/obsidian-wayland %U' "$OBSIDIAN_DESKTOP"
    # Exec must not hardcode the versioned AppImage path (glob-discovered in
    # the wrapper); AppImage may still appear in comments.
    exec_line=$(grep '^Exec=' "$OBSIDIAN_DESKTOP")
    assert_not_contains 'AppImage' "$exec_line"
}

test_wayland_autostart_checks_apps_and_separates_logs
test_wayland_autostart_logs_each_app_and_warns_for_missing_commands
test_file_manager_wayland_uses_available_fallbacks
test_wayland_wallpaper_helper_covers_current_wallpaper_locations
test_wayland_wallpaper_helper_records_current_wallpaper
test_wayland_wallpaper_switcher_restarts_swaybg_and_reuses_helper
test_portal_preferences_avoid_nautilus_filechooser_requirement
test_launcher_and_lock_have_wayland_first_fallbacks
test_lock_wayland_uses_recorded_wallpaper_when_available
test_lock_wayland_falls_back_to_color_without_wallpaper
test_wayland_screenshot_uses_selection_and_annotation
test_wayland_screenshot_uses_satty
test_dingtalk_wayland_entrypoint_preserves_preload_contract
test_browser_wayland_forces_native_wayland_ozone
test_browser_wayland_passes_ozone_flag_only_under_wayland
test_clipboard_wayland_persists_and_queries_history
test_trae_cn_forces_wayland_with_ime
test_obsidian_wayland_forces_wayland_with_text_input_v3

printf 'PASS: wayland scripts tests\n'
