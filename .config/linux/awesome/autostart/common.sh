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
        start_background "$@"
    fi
}

run_custom() {
    [ "$#" -gt 1 ] || return 0

    pattern=$1
    shift
    command_available "$1" || return 0

    if ! process_matching_pattern_exists "$pattern"; then
        start_background "$@"
    fi
}

process_matching_pattern_exists() {
    pattern=$1
    current_pid=$$
    parent_pid=${PPID:-}

    for pid in $(pgrep -f "$pattern" 2>/dev/null); do
        [ "$pid" = "$current_pid" ] && continue
        [ -n "$parent_pid" ] && [ "$pid" = "$parent_pid" ] && continue
        return 0
    done

    return 1
}

start_background() {
    [ "$#" -gt 0 ] || return 0

    if command_available setsid; then
        setsid -f "$@" >/dev/null 2>&1
    elif command_available nohup; then
        nohup "$@" >/dev/null 2>&1 &
    else
        "$@" >/dev/null 2>&1 &
    fi
}

run_first_custom() {
    [ "$#" -gt 1 ] || return 0

    pattern=$1
    shift

    for candidate do
        command_available "$candidate" || continue
        run_custom "$pattern" "$candidate"
        return 0
    done
}

pick_latest_executable_candidate() {
    latest_candidate=
    latest_name=

    for candidate do
        command_available "$candidate" || continue

        candidate_name=$(basename "$candidate")
        if [ -z "$latest_candidate" ]; then
            latest_candidate=$candidate
            latest_name=$candidate_name
            continue
        fi

        newest_name=$(printf '%s\n%s\n' "$latest_name" "$candidate_name" | sort -V | tail -n 1)
        if [ "$newest_name" = "$candidate_name" ] && [ "$candidate_name" != "$latest_name" ]; then
            latest_candidate=$candidate
            latest_name=$candidate_name
        fi
    done

    [ -n "$latest_candidate" ] || return 1
    printf '%s\n' "$latest_candidate"
}

run_latest_custom() {
    [ "$#" -gt 1 ] || return 0

    pattern=$1
    shift

    latest_candidate=$(pick_latest_executable_candidate "$@") || return 0
    run_custom "$pattern" "$latest_candidate"
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

detect_external_displays() {
    laptop_display=$1

    command_available xrandr || return 0

    xrandr --query 2>/dev/null |
        awk -v laptop_display="$laptop_display" '
            / connected/ && $1 != laptop_display && $1 !~ /^(eDP|LVDS|DSI)/ {
                print $1
            }
        '
}

detect_external_display() {
    detect_external_displays "$1" | awk 'NR == 1 { print; exit }'
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
    laptop_mode=$2
    laptop_rate=$3
    external_position=$4
    external_scale=$5
    shift 5

    [ "$#" -gt 0 ] || return 1

    laptop_width=$(mode_width "$laptop_mode")
    laptop_height=$(mode_height "$laptop_mode")
    scale_x=$(scale_x_factor "$external_scale")
    scale_y=$(scale_y_factor "$external_scale")

    [ -n "$laptop_width" ] && [ -n "$laptop_height" ] || return 1
    [ -n "$scale_x" ] && [ -n "$scale_y" ] || return 1

    layout_records=
    total_external_width=0
    total_external_height=0
    max_external_width=0
    max_external_height=0

    for external_display do
        external_mode=$(detect_display_preferred_mode "$external_display")
        [ -n "$external_mode" ] || return 1

        external_width=$(mode_width "$external_mode")
        external_height=$(mode_height "$external_mode")
        [ -n "$external_width" ] && [ -n "$external_height" ] || return 1

        external_logical_width=$(scaled_dimension "$external_width" "$scale_x")
        external_logical_height=$(scaled_dimension "$external_height" "$scale_y")

        if [ -n "$layout_records" ]; then
            layout_records="$layout_records
$external_display|$external_mode|$external_logical_width|$external_logical_height"
        else
            layout_records="$external_display|$external_mode|$external_logical_width|$external_logical_height"
        fi

        total_external_width=$((total_external_width + external_logical_width))
        total_external_height=$((total_external_height + external_logical_height))
        max_external_width=$(max_dimension "$max_external_width" "$external_logical_width")
        max_external_height=$(max_dimension "$max_external_height" "$external_logical_height")
    done

    case "$external_position" in
        right|right-of)
            framebuffer_width=$((laptop_width + total_external_width))
            framebuffer_height=$(max_dimension "$laptop_height" "$max_external_height")
            laptop_pos="0x0"
            cursor_x=$laptop_width
            cursor_y=
            ;;
        above)
            framebuffer_width=$(max_dimension "$laptop_width" "$max_external_width")
            framebuffer_height=$((total_external_height + laptop_height))
            laptop_pos="0x${total_external_height}"
            cursor_x=
            cursor_y=0
            ;;
        below)
            framebuffer_width=$(max_dimension "$laptop_width" "$max_external_width")
            framebuffer_height=$((laptop_height + total_external_height))
            laptop_pos="0x0"
            cursor_x=
            cursor_y=$laptop_height
            ;;
        left|left-of|*)
            framebuffer_width=$((total_external_width + laptop_width))
            framebuffer_height=$(max_dimension "$laptop_height" "$max_external_height")
            laptop_pos="${total_external_width}x0"
            cursor_x=0
            cursor_y=
            ;;
    esac

    set -- --fb "${framebuffer_width}x${framebuffer_height}"

    old_ifs=$IFS
    IFS='
'
    for record in $layout_records; do
        external_display=$(printf '%s\n' "$record" | cut -d'|' -f1)
        external_mode=$(printf '%s\n' "$record" | cut -d'|' -f2)
        external_logical_width=$(printf '%s\n' "$record" | cut -d'|' -f3)
        external_logical_height=$(printf '%s\n' "$record" | cut -d'|' -f4)

        case "$external_position" in
            above|below)
                external_pos="0x${cursor_y}"
                cursor_y=$((cursor_y + external_logical_height))
                ;;
            *)
                external_pos="${cursor_x}x0"
                cursor_x=$((cursor_x + external_logical_width))
                ;;
        esac

        set -- "$@" --output "$external_display" --mode "$external_mode" --scale "$external_scale" --pos "$external_pos"
    done
    IFS=$old_ifs

    set -- "$@" --output "$laptop_display" --primary --mode "$laptop_mode"

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

    external_displays=$(detect_external_displays "$laptop_display")

    if [ -n "$external_displays" ] && [ -n "$external_scale" ] && [ "$external_scale" != "1x1" ] && [ -n "$laptop_mode" ]; then
        configure_scaled_external_display_layout \
            "$laptop_display" "$laptop_mode" "$laptop_rate" "$external_position" "$external_scale" \
            $external_displays &&
            return 0
    fi

    set -- --output "$laptop_display" --primary

    if [ -n "$laptop_mode" ]; then
        set -- "$@" --mode "$laptop_mode"
    fi

    if [ -n "$laptop_rate" ]; then
        set -- "$@" --rate "$laptop_rate"
    fi

    if [ -n "$external_displays" ]; then
        position_arg=$(display_position_arg "$external_position")
        anchor_display=$laptop_display
        for external_display in $external_displays; do
            set -- "$@" --output "$external_display" --auto "$position_arg" "$anchor_display"
            anchor_display=$external_display
        done
    fi

    xrandr "$@"
}

prepare_xresources() {
    command_available xrdb || return 0
    [ -r "$HOME/.Xresources" ] || return 0

    xrdb merge "$HOME/.Xresources"
}

has_wallpaper_files() {
    dir=$1

    [ -d "$dir" ] || return 1

    find "$dir" -maxdepth 1 -type f \(         -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp'     \) -print -quit | grep -q .
}

randomize_wallpaper() {
    command_available feh || return 0

    for dir in "$@"; do
        if has_wallpaper_files "$dir"; then
            feh --no-fehbg --bg-fill --randomize "$dir"/* &
            return 0
        fi
    done

    return 0
}

run_idle_lock_service() {
    locker="$HOME/.config/scripts/lock"

    [ -x "$locker" ] || return 0

    run_custom "xautolock.*\\.config/scripts/lock" \
        xautolock -time 10 -locker "$locker" -detectsleep
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
    run_idle_lock_service
}
