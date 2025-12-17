#!/bin/sh
# ==============================================
# AwesomeWM autostart script
# ==============================================

run() {
    if ! pgrep -x "$1" >/dev/null; then
        "$@" &
    fi
}

run_custom() {
    if ! pgrep -f "$1" >/dev/null; then
        shift
        "$@" &
    fi
}

# Wait for X11 to be ready
sleep 1

xrdb merge ~/.Xresources

feh --bg-fill --randomize ~/Pictures/wall/* &
run_custom "Snipaste-2.11.2-x86_64.AppImage" ~/Documents/Snipaste-2.11.2-x86_64.AppImage
run nm-applet
run blueman-applet
run pasystray
run picom
run fcitx5
run redshift -l 30.6:114.3 -t 6500:4000
run pot
# run dunst  # use naughty instead
run udiskie -t
