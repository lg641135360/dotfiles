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
sleep 2

xrdb merge ~/.Xresources
xrandr --output eDP-1 --mode 0x4b
# set touchpad natutral scrolling
xinput set-prop 10 "libinput Natural Scrolling Enabled" 1
xinput set-prop 10 "libinput Tapping Enabled" 1
xinput set-prop 10 "libinput Click Method Enabled" 1 0
xinput set-prop 10 "libinput Disable While Typing Enabled" 1

feh --bg-fill --randomize /usr/share/backgrounds/* &

run gestures start
run nm-applet
run blueman-applet
run pasystray
run picom --experimental-backends
run fcitx5
run redshift -l 30.6:114.3 -t 6500:4000
run pot
# run dunst
run udiskie -t
run flameshot