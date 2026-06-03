#!/bin/sh
# ==============================================
# AwesomeWM autostart script
# ==============================================

. "$(dirname "$0")/common.sh"

# Add Homebrew PATH (linuxbrew) so awesome-spawned scripts can find brew-installed binaries
append_path_if_exists "/home/linuxbrew/.linuxbrew/bin"

apply_display_layout() {
    configure_fixed_external_display_layout 2880x1800 120 right 2560x1440 59.95
}

if [ "${1:-}" = "--display-layout" ]; then
    apply_display_layout
    exit 0
fi

# Wait for X11 to be ready
sleep 2

prepare_xresources

apply_display_layout

# set touchpad natural scrolling and tap-to-click
touchpad_id=$(xinput list 2>/dev/null | grep -i 'Touchpad' | sed 's/.*id=\([0-9]*\).*/\1/')
if [ -n "$touchpad_id" ]; then
    xinput set-prop "$touchpad_id" "libinput Natural Scrolling Enabled" 1
    xinput set-prop "$touchpad_id" "libinput Tapping Enabled" 1
    xinput set-prop "$touchpad_id" "libinput Click Method Enabled" 1 0
    xinput set-prop "$touchpad_id" "libinput Accel Speed" 0.5
    xinput set-prop "$touchpad_id" "libinput Disable While Typing Enabled" 1
fi

randomize_wallpaper "$HOME/Pictures/wall" "$HOME/Pictures" "/usr/share/backgrounds"

run gestures start
run_common_tray_services
run_common_desktop_services picom --experimental-backends
run flameshot
# run dunst
