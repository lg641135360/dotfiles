#!/bin/bash

os=$(uname -s)
cur_path=$(pwd)

# Ensure directory exists
ensure_dir() {
    [ ! -d "$1" ] && mkdir -p "$1"
}

# Copy configuration file
copy_config() {
    local source="$1" target="$2" name="$3"

    [ ! -f "$source" ] && echo "ERROR: $source not found" && return 1

    ensure_dir "$(dirname "$target")"
    [ -f "$target" ] && cp "$target" "$target.backup.$(date +%Y%m%d_%H%M%S)"

    cp "$source" "$target" && echo "Copied $name" || echo "Failed: $name"
}

# Process configuration
process_config() {
    local check_cmd="$1" source="$2" target="$3" name="$4"

    [ -n "$check_cmd" ] && ! eval "$check_cmd" >/dev/null 2>&1 && return 0
    [[ "$source" != /* ]] && source="$cur_path/$source"
    target="${target/#\~/$HOME}"

    copy_config "$source" "$target" "$name"
}

# Configuration arrays
# app name | source path | target path | display name
shared_configs=(
#    "command -v alacritty|.config/shared/alacritty/alacritty.toml|~/.config/alacritty/alacritty.toml|Alacritty"
    "command -v tmux|.config/shared/tmux/.tmux.conf|~/.tmux.conf|Tmux"
	"Command -v kitty|.config/shared/kitty/kitty.conf|~/.config/kitty/kitty.conf|Kitty"
)

macos_configs=(
    "command -v aerospace|.config/macos/aerospace/aerospace.toml|~/.config/aerospace/aerospace.toml|Aerospace"
)

linux_configs=(
    # "command -v i3|.config/linux/i3/config|~/.config/i3/config|i3wm"
)

# Process configurations
for config in "${shared_configs[@]}"; do
    IFS='|' read -r check_cmd source target name <<< "$config"
    process_config "$check_cmd" "$source" "$target" "$name"
done

if [[ "$os" == "Darwin" ]]; then
    for config in "${macos_configs[@]}"; do
        IFS='|' read -r check_cmd source target name <<< "$config"
        process_config "$check_cmd" "$source" "$target" "$name"
    done
elif [[ "$os" == "Linux" ]]; then
    for config in "${linux_configs[@]}"; do
        IFS='|' read -r check_cmd source target name <<< "$config"
        process_config "$check_cmd" "$source" "$target" "$name"
    done
fi

echo "Done"
