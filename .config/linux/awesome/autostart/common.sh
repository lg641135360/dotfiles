#!/bin/sh

command_available() {
    [ "$#" -gt 0 ] || return 1

    cmd=$1
    [ -n "$cmd" ] || return 1

    case "$cmd" in
        */*)
            [ -x "$cmd" ]
            ;;
        *)
            command -v "$cmd" >/dev/null 2>&1
            ;;
    esac
}

run() {
    [ "$#" -gt 0 ] || return 0
    command_available "$1" || return 0

    if ! pgrep -x "$1" >/dev/null 2>&1; then
        "$@" &
    fi
}

run_custom() {
    [ "$#" -gt 1 ] || return 0

    pattern=$1
    shift
    command_available "$1" || return 0

    if ! pgrep -f "$pattern" >/dev/null 2>&1; then
        "$@" &
    fi
}

append_path_if_exists() {
    dir=$1

    if [ -d "$dir" ] && [ ":$PATH:" != *":$dir:"* ]; then
        PATH="$PATH:$dir"
    fi
}

detect_laptop_display() {
    command_available xrandr || return 0

    xrandr --query 2>/dev/null |
        awk '/ connected/ && $1 ~ /^(eDP|LVDS|DSI)/ { print $1; exit }'
}

detect_external_display() {
    laptop_display=$1

    command_available xrandr || return 0

    xrandr --query 2>/dev/null |
        awk -v laptop_display="$laptop_display" '
            / connected/ && $1 != laptop_display && $1 !~ /^(eDP|LVDS|DSI)/ {
                print $1
                exit
            }
        '
}

detect_display_preferred_mode() {
    display=$1

    command_available xrandr || return 0

    xrandr --query 2>/dev/null |
        awk -v display="$display" '
            $1 == display && / connected/ {
                in_display = 1
                next
            }
            in_display && /^[^[:space:]]/ {
                exit
            }
            in_display && $1 ~ /^[0-9]+x[0-9]+$/ {
                if ($0 ~ /\+/) {
                    print $1
                    found = 1
                    exit
                }
                if (first == "") {
                    first = $1
                }
            }
            END {
                if (!found && first != "") {
                    print first
                }
            }
        '
}

mode_width() {
    printf '%s\n' "$1" | awk -Fx '{ print $1 }'
}

mode_height() {
    printf '%s\n' "$1" | awk -Fx '{ print $2 }'
}

scale_x_factor() {
    printf '%s\n' "$1" | awk -Fx '{ print $1 }'
}

scale_y_factor() {
    printf '%s\n' "$1" | awk -Fx '{ print ($2 == "" ? $1 : $2) }'
}

scaled_dimension() {
    value=$1
    factor=$2

    awk -v value="$value" -v factor="$factor" 'BEGIN { printf "%d\n", (value * factor) + 0.5 }'
}

max_dimension() {
    if [ "$1" -gt "$2" ]; then
        printf '%s\n' "$1"
    else
        printf '%s\n' "$2"
    fi
}

display_position_arg() {
    case "$1" in
        left|left-of)
            printf '%s\n' "--left-of"
            ;;
        right|right-of)
            printf '%s\n' "--right-of"
            ;;
        above)
            printf '%s\n' "--above"
            ;;
        below)
            printf '%s\n' "--below"
            ;;
        *)
            printf '%s\n' "--left-of"
            ;;
    esac
}

configure_scaled_external_display_layout() {
    laptop_display=$1
    external_display=$2
    laptop_mode=$3
    laptop_rate=$4
    external_position=$5
    external_scale=$6

    external_mode=$(detect_display_preferred_mode "$external_display")
    [ -n "$external_mode" ] || return 1

    laptop_width=$(mode_width "$laptop_mode")
    laptop_height=$(mode_height "$laptop_mode")
    external_width=$(mode_width "$external_mode")
    external_height=$(mode_height "$external_mode")
    scale_x=$(scale_x_factor "$external_scale")
    scale_y=$(scale_y_factor "$external_scale")

    [ -n "$laptop_width" ] && [ -n "$laptop_height" ] || return 1
    [ -n "$external_width" ] && [ -n "$external_height" ] || return 1
    [ -n "$scale_x" ] && [ -n "$scale_y" ] || return 1

    external_logical_width=$(scaled_dimension "$external_width" "$scale_x")
    external_logical_height=$(scaled_dimension "$external_height" "$scale_y")

    case "$external_position" in
        right|right-of)
            framebuffer_width=$((laptop_width + external_logical_width))
            framebuffer_height=$(max_dimension "$laptop_height" "$external_logical_height")
            laptop_pos="0x0"
            external_pos="${laptop_width}x0"
            ;;
        above)
            framebuffer_width=$(max_dimension "$laptop_width" "$external_logical_width")
            framebuffer_height=$((external_logical_height + laptop_height))
            external_pos="0x0"
            laptop_pos="0x${external_logical_height}"
            ;;
        below)
            framebuffer_width=$(max_dimension "$laptop_width" "$external_logical_width")
            framebuffer_height=$((laptop_height + external_logical_height))
            laptop_pos="0x0"
            external_pos="0x${laptop_height}"
            ;;
        left|left-of|*)
            framebuffer_width=$((external_logical_width + laptop_width))
            framebuffer_height=$(max_dimension "$laptop_height" "$external_logical_height")
            external_pos="0x0"
            laptop_pos="${external_logical_width}x0"
            ;;
    esac

    set -- --fb "${framebuffer_width}x${framebuffer_height}" \
        --output "$external_display" --mode "$external_mode" --scale "$external_scale" --pos "$external_pos" \
        --output "$laptop_display" --primary --mode "$laptop_mode"

    if [ -n "$laptop_rate" ]; then
        set -- "$@" --rate "$laptop_rate"
    fi

    set -- "$@" --scale 1x1 --pos "$laptop_pos"

    xrandr "$@"
}

configure_laptop_display_layout() {
    laptop_mode=$1
    laptop_rate=$2
    external_position=${3:-left}
    external_scale=${4:-}

    command_available xrandr || return 0

    laptop_display=$(detect_laptop_display)
    [ -n "$laptop_display" ] || return 0

    external_display=$(detect_external_display "$laptop_display")

    if [ -n "$external_display" ] && [ -n "$external_scale" ] && [ "$external_scale" != "1x1" ] && [ -n "$laptop_mode" ]; then
        configure_scaled_external_display_layout \
            "$laptop_display" "$external_display" "$laptop_mode" "$laptop_rate" "$external_position" "$external_scale" &&
            return 0
    fi

    set -- --output "$laptop_display" --primary

    if [ -n "$laptop_mode" ]; then
        set -- "$@" --mode "$laptop_mode"
    fi

    if [ -n "$laptop_rate" ]; then
        set -- "$@" --rate "$laptop_rate"
    fi

    if [ -n "$external_display" ]; then
        position_arg=$(display_position_arg "$external_position")
        set -- "$@" --output "$external_display" --auto "$position_arg" "$laptop_display"
    fi

    xrandr "$@"
}

prepare_xresources() {
    xrdb merge ~/.Xresources
}

has_wallpaper_files() {
    dir=$1

    [ -d "$dir" ] || return 1

    find "$dir" -maxdepth 1 -type f \(         -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp'     \) -print -quit | grep -q .
}

randomize_wallpaper() {
    for dir in "$@"; do
        if has_wallpaper_files "$dir"; then
            feh --no-fehbg --bg-fill --randomize "$dir"/* &
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
