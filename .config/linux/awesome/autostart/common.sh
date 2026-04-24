#!/bin/sh

run() {
    if ! pgrep -x "$1" >/dev/null 2>&1; then
        "$@" &
    fi
}

run_custom() {
    if ! pgrep -f "$1" >/dev/null 2>&1; then
        shift
        "$@" &
    fi
}

append_path_if_exists() {
    dir=$1

    if [ -d "$dir" ] && [ ":$PATH:" != *":$dir:"* ]; then
        PATH="$PATH:$dir"
    fi
}

prepare_xresources() {
    xrdb merge ~/.Xresources
}

has_wallpaper_files() {
    dir=$1

    [ -d "$dir" ] || return 1

    find "$dir" -maxdepth 1 -type f \(         -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp'     \) -print -quit | grep -q .
}

restore_or_randomize_wallpaper() {
    if [ -f "$HOME/.fehbg" ]; then
        sh "$HOME/.fehbg" >/dev/null 2>&1 &
        return 0
    fi

    for dir in "$@"; do
        if has_wallpaper_files "$dir"; then
            feh --bg-fill --randomize "$dir"/* &
            return 0
        fi
    done

    return 1
}

run_common_tray_services() {
    run nm-applet
    run blueman-applet
    run pasystray
}

run_common_desktop_services() {
    run "$@"
    run fcitx5
    run redshift -l 30.6:114.3 -t 6500:4000
    run pot
    run udiskie -t
}
