#!/bin/bash

input=$(cat)

get() {
    printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null
}

short() {
    local n="${1:-}"

    if [ -z "$n" ] || [ "$n" = "null" ]; then
        return 1
    elif [ "$n" -ge 1000000 ] 2>/dev/null; then
        printf '%sM' $((n / 1000000))
    elif [ "$n" -ge 1000 ] 2>/dev/null; then
        printf '%sk' $((n / 1000))
    else
        printf '%s' "$n"
    fi
}

seg() {
    local bg="$1"
    local fg="$2"
    local text="$3"

    printf '\033[%s;%sm %s \033[0m' "$bg" "$fg" "$text"
}

dir=$(get '.workspace.current_dir // .cwd')
[ -z "$dir" ] && dir=$(pwd)

home=${HOME%/}
display=$dir
case "$display" in
    "$home") display='~' ;;
    "$home"/*) display="~/${display#$home/}" ;;
esac

git_info=''
dirty=''
if GIT_OPTIONAL_LOCKS=0 git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null || GIT_OPTIONAL_LOCKS=0 git -C "$dir" rev-parse --short HEAD 2>/dev/null)
    [ -n "$(GIT_OPTIONAL_LOCKS=0 git -C "$dir" status --porcelain 2>/dev/null)" ] && dirty='*'
    git_info="$branch$dirty"
fi

model=$(get '.model.display_name // .model.id')
[ -z "$model" ] && model='-'

effort=$(get '.effort_level // .effortLevel')
[ -z "$effort" ] && effort='xhigh'

used_pct=$(get '.context_window.used_percentage')
used_total=$(get '.context_window.total_input_tokens')
win_size=$(get '.context_window.context_window_size')

if used_fmt=$(short "$used_total") && win_fmt=$(short "$win_size") && [ -n "$used_pct" ] && [ "$used_pct" != "null" ]; then
    ctx="CTX ${used_pct}% (${used_fmt}/${win_fmt})"
else
    ctx='CTX ?'
fi

seg 44 97 "$model"
printf ' '
seg 45 97 "$effort"
printf ' '
seg 46 30 "$ctx"
printf ' '
path_block=$display
[ -n "$git_info" ] && path_block="$display [$git_info]"
seg 47 30 "$path_block"
