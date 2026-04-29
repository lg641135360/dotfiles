#!/bin/sh
# ==============================================
# AwesomeWM autostart script
# ==============================================

. "$(dirname "$0")/common.sh"

# Wait for X11 to be ready
sleep 1

prepare_xresources

randomize_wallpaper "$HOME/Pictures/wall" "$HOME/Pictures" "/usr/share/backgrounds"
run_custom "Snipaste-2.11.2-x86_64.AppImage" ~/Documents/Snipaste-2.11.2-x86_64.AppImage
run_common_tray_services
run_common_desktop_services picom --experimental-backends
run greenclip daemon
# run dunst  # use naughty instead
