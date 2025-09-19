#!/bin/bash

os=$(uname -s)
cur_path=$(pwd)

# Ensure directory exists
ensure_dir() {
    [ ! -d "$1" ] && mkdir -p "$1"
}

# Clean old backup files (keep only latest 5)
clean_old_backups() {
    local target="$1"
    local backup_files
    
    # Find all backup files for this target, sorted by timestamp (newest first)
    backup_files=$(find "$(dirname "$target")" -maxdepth 1 -name "$(basename "$target").backup.*" -type f 2>/dev/null | sort -t. -k3 -r)
    
    # Count backup files
    local count=$(echo "$backup_files" | grep -c .)
    
    if [ "$count" -gt 5 ]; then
        # Keep only the first 5 (newest), remove the rest
        echo "$backup_files" | tail -n +6 | xargs rm -f
        echo "(cleaned $((count - 5)) old backups)"
    fi
}

# Copy configuration file
copy_config() {
    local source="$1" target="$2" name="$3"

    [ ! -f "$source" ] && echo "ERROR: $source not found" && return 1

    ensure_dir "$(dirname "$target")"
    
    # Create backup if target exists
    local cleanup_msg=""
    if [ -f "$target" ]; then
        cp "$target" "$target.backup.$(date +%Y%m%d_%H%M%S)"
        # Clean old backups after creating new one
        cleanup_msg=$(clean_old_backups "$target")
    fi

    if cp "$source" "$target"; then
        if [ -n "$cleanup_msg" ]; then
            echo "Copied $name $cleanup_msg"
        else
            echo "Copied $name"
        fi
    else
        echo "Failed: $name"
    fi
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
    "command -v alacritty|.config/shared/alacritty/alacritty.toml|~/.config/alacritty/alacritty.toml|Alacritty"
    "command -v tmux|.config/shared/tmux/.tmux.conf|~/.tmux.conf|Tmux"
	"command -v kitty|.config/shared/kitty/kitty.conf|~/.config/kitty/kitty.conf|Kitty"
	"command -v kitty|.config/shared/kitty/Dracula.conf|~/.config/kitty/themes/Dracula.conf|kitty_theme"
	"command -v git|.config/shared/git/config|~/.config/git/config|Git_config"
	"command -v git|.config/shared/git/ignore|~/.config/git/ignore|Git_ignore"
	"command -v git|.config/shared/git/template|~/.config/git/template|Git_template"
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
