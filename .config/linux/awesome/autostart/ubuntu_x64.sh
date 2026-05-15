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

randomize_wallpaper "$HOME/Pictures/wall" "$HOME/Pictures" "/usr/share/backgrounds"
run_first_custom "Snipaste" \
    "$HOME"/Applications/Snipaste-2.11.2-*.AppImage \
    "$HOME"/Applications/Snipaste-*.AppImage \
    "$HOME"/Downloads/Snipaste-2.11.2-x86_64.AppImage \
    "$HOME"/Documents/Snipaste-2.11.2-x86_64.AppImage
run_common_tray_services
run_common_desktop_services picom
run greenclip daemon
# run dunst  # use naughty instead
