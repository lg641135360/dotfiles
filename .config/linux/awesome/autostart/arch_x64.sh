#!/bin/sh
# ==============================================
# AwesomeWM autostart script
# ==============================================

. "$(dirname "$0")/common.sh"

# Wait for X11 to be ready
sleep 1

prepare_xresources

restore_or_randomize_wallpaper "$HOME/Pictures" "/usr/share/backgrounds"
run Snipaste
run_common_desktop_services picom
run greenclip daemon
run_common_tray_services
# run dunst  # notification daemon use naughty instead
