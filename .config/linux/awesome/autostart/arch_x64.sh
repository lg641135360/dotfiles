#!/bin/sh
# ==============================================
# AwesomeWM autostart script
# ==============================================

. "$(dirname "$0")/common.sh"

if [ "${1:-}" = "--display-layout" ]; then
    exit 0
fi

# Wait for X11 to be ready
sleep 1

prepare_xresources

randomize_wallpaper "$HOME/Pictures" "/usr/share/backgrounds"
run Snipaste
run_common_desktop_services picom
run greenclip daemon
run_common_tray_services
