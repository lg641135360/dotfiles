#!/bin/sh
# ==============================================
# AwesomeWM autostart script
# ==============================================

. "$(dirname "$0")/common.sh"

# Add Homebrew PATH (linuxbrew) so awesome-spawned scripts can find brew-installed binaries
append_path_if_exists "/home/linuxbrew/.linuxbrew/bin"

# Wait for X11 to be ready
sleep 2

prepare_xresources

detect_laptop_display() {
    xrandr --query 2>/dev/null | awk '/ connected/ && $1 ~ /^(eDP|LVDS|DSI)/ { print $1; exit }'
}

display_output=$(detect_laptop_display)
if [ -n "$display_output" ]; then
    xrandr --output "$display_output" --mode 2880x1800 --rate 120
fi

# set touchpad natural scrolling and tap-to-click
touchpad_id=$(xinput list 2>/dev/null | grep -i 'Touchpad' | sed 's/.*id=\([0-9]*\).*/\1/')
if [ -n "$touchpad_id" ]; then
    xinput set-prop "$touchpad_id" "libinput Natural Scrolling Enabled" 1
    xinput set-prop "$touchpad_id" "libinput Tapping Enabled" 1
    xinput set-prop "$touchpad_id" "libinput Click Method Enabled" 1 0
    xinput set-prop "$touchpad_id" "libinput Accel Speed" 0.5
    xinput set-prop "$touchpad_id" "libinput Disable While Typing Enabled" 1
fi

restore_or_randomize_wallpaper "$HOME/Pictures/wall" "$HOME/Pictures" "/usr/share/backgrounds"

run gestures start
run_common_tray_services
run_common_desktop_services picom --experimental-backends
run flameshot
# run dunst
