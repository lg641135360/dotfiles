#!/bin/sh
# ==============================================
# AwesomeWM autostart script
# ==============================================

run() {
    if ! pgrep -x "$1" >/dev/null; then
        "$@" &
    fi
}

# Add Homebrew PATH (linuxbrew) so awesome-spawned scripts can find brew-installed binaries
if [ -d /home/linuxbrew/.linuxbrew/bin ]; then
    PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
fi

# Wait for X11 to be ready
sleep 2

xrdb merge ~/.Xresources
xrandr --output eDP-1 --mode 2880x1800 --rate 120
# set touchpad natural scrolling and tap-to-click
touchpad_id=$(xinput list 2>/dev/null | grep -i 'Touchpad' | sed 's/.*id=\([0-9]*\).*/\1/')
if [ -n "$touchpad_id" ]; then
    xinput set-prop "$touchpad_id" "libinput Natural Scrolling Enabled" 1
    xinput set-prop "$touchpad_id" "libinput Tapping Enabled" 1
    xinput set-prop "$touchpad_id" "libinput Click Method Enabled" 1 0
    xinput set-prop "$touchpad_id" "libinput Accel Speed" 0.5
    xinput set-prop "$touchpad_id" "libinput Disable While Typing Enabled" 1
fi

feh --bg-fill --randomize /usr/share/backgrounds/* &

run gestures start
run nm-applet
run blueman-applet
run pasystray
run picom --experimental-backends
run fcitx5
# Use system redshift (apt installed), not homebrew version which lacks X11 support
if command -v redshift >/dev/null 2>&1 && ! echo "$(command -v redshift)" | grep -q linuxbrew; then
    run redshift -l 30.6:114.3 -t 6500:4000
fi
run pot
# run dunst
run udiskie -t
run flameshot