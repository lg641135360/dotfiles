#!/bin/sh
# ==============================================
# AwesomeWM autostart script
# ==============================================

run() {
    if ! pgrep -x "$1" >/dev/null; then
        "$@" &
    fi
}

# Wait for X11 to be ready
sleep 1

xrdb merge ~/.Xresources

feh --bg-fill --randomize ~/Pictures/* &
run Snipaste
run picom
run fcitx5
run redshift -l 30.6:114.3 -t 6500:4000  # Auto night mode for Wuhan location
run pot
run udiskie -t  # automount usb drives
run pasystray  # volume control tray icon
run nm-applet  # network manager tray icon
run blueman-applet  # bluetooth tray icon
run dunst  # notification daemon