#!/bin/bash
set -e  # Exit on error

# Script configuration
os=$(uname -s)
arch=$(uname -m)
cur_path=$(pwd)
backup_limit=5
timestamp=$(date +%Y%m%d_%H%M%S)
current_user=$(whoami)

# Detect Linux distribution
if [[ "$os" == "Linux" ]]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        distro=$ID
    elif [ -f /etc/arch-release ]; then
        distro="arch"
    else
        distro="unknown"
    fi
fi

# Logging functions
log_info() {
    echo -e "\033[0;32m[INFO]\033[0m $1"
}

log_warn() {
    echo -e "\033[0;33m[WARN]\033[0m $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1" >&2
}

# Error handling
trap 'log_error "An error occurred at line $LINENO. Exiting..."; exit 1' ERR

# Check if required commands are available
check_dependencies() {
    local missing_deps=()
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

# Ensure directory exists
ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || {
            log_error "Failed to create directory: $dir"
            return 1
        }
        log_info "Created directory: $dir"
    fi
}

# Clean old backup files/directories (keep only latest N)
clean_old_backups() {
    local target="$1"
    local is_dir="${2:-false}"  # Optional parameter to handle directories
    local dir backup_items count removed=0
    dir="$(dirname "$target")"
    if [ ! -d "$dir" ]; then
        return 0
    fi
    # Find all backup items for this target, sorted by timestamp (newest first)
    if [ "$is_dir" = "true" ]; then
        backup_items=$(find "$dir" -maxdepth 1 -type d -name "$(basename "$target").backup.*" | sort -r)
    else
        backup_items=$(find "$dir" -maxdepth 1 -type f -name "$(basename "$target").backup.*" | sort -r)
    fi
    count=$(echo "$backup_items" | grep -c . || true)
    if [ "$count" -gt "$backup_limit" ]; then
        echo "$backup_items" | tail -n +"$((backup_limit + 1))" | while read -r item; do
            if [ "$is_dir" = "true" ]; then
                rm -rf "$item" && removed=$((removed + 1))
            else
                rm -f "$item" && removed=$((removed + 1))
            fi
        done
        if [ $removed -gt 0 ]; then
            if [ "$is_dir" = "true" ]; then
                log_info "Cleaned $removed old backup directories for $(basename "$target")"
            else
                log_info "Cleaned $removed old backup files for $(basename "$target")"
            fi
        fi
    fi
}

# Copy configuration file
copy_config() {
    local source="$1" target="$2" name="$3"

    # Validate input
    if [ ! -f "$source" ]; then
        log_error "Source file not found: $source"
        return 1
    fi

    # Create target directory
    if ! ensure_dir "$(dirname "$target")"; then
        return 1
    fi
    # Create backup if target exists
    if [ -f "$target" ]; then
        if ! cp "$target" "$target.backup.$timestamp"; then
            log_error "Failed to create backup for $target"
            return 1
        fi
        log_info "Created backup for $name"
        clean_old_backups "$target"
    fi

    # Copy file
    if cp "$source" "$target"; then
        log_info "Successfully copied $name"
    else
        log_error "Failed to copy $name"
        return 1
    fi

    # Verify copy
    if ! diff "$source" "$target" >/dev/null 2>&1; then
        log_error "Verification failed for $name"
        return 1
    fi
}

# Copy configuration directory
copy_config_dir() {
    local source="$1" target="$2" name="$3"

    # Validate input
    if [ ! -d "$source" ]; then
        log_error "Source directory not found: $source"
        return 1
    fi

    # Create target parent directory
    if ! ensure_dir "$(dirname "$target")"; then
        return 1
    fi
    # Create backup if target exists
    if [ -d "$target" ]; then
        local backup_path="$target.backup.$timestamp"
        if ! mv "$target" "$backup_path"; then
            log_error "Failed to create backup for $target"
            return 1
        fi
        log_info "Created backup for $name directory"
        # Clean old directory backups
        clean_old_backups "$target" "true"
    fi

    # Copy directory
    if cp -r "$source" "$target"; then
        log_info "Successfully copied $name directory"
        # Verify directory copy
        if ! diff -r "$source" "$target" >/dev/null 2>&1; then
            log_error "Directory verification failed for $name"
            return 1
        fi
    else
        log_error "Failed to copy $name directory"
        return 1
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

# Process directory configuration
process_config_dir() {
    local check_cmd="$1" source="$2" target="$3" name="$4"

    [ -n "$check_cmd" ] && ! eval "$check_cmd" >/dev/null 2>&1 && return 0
    [[ "$source" != /* ]] && source="$cur_path/$source"
    target="${target/#\~/$HOME}"

    copy_config_dir "$source" "$target" "$name"
}

# Configuration arrays
# app name | source path | target path | display name
shared_configs=(
    "command -v tmux|.config/shared/tmux/.tmux.conf|~/.tmux.conf|Tmux"
	"command -v kitty|.config/shared/kitty/kitty.conf|~/.config/kitty/kitty.conf|Kitty"
	"command -v kitty|.config/shared/kitty/Dracula.conf|~/.config/kitty/themes/Dracula.conf|kitty_theme"
	"command -v zsh|.config/shared/zsh/.zshrc|~/.config/zsh/.zshrc|zsh"
    "command -v alacritty|.config/shared/alacritty/alacritty.toml|~/.config/alacritty/alacritty.toml|Alacritty"
)

# Directory configurations (for copying entire directories)
shared_dir_configs=(
	"command -v git|.config/shared/git|~/.config/git|git"
	"command -v nvim|.config/shared/nvim|~/.config/nvim|nvim"
)

macos_configs=(
    "command -v aerospace|.config/macos/aerospace/aerospace.toml|~/.config/aerospace/aerospace.toml|Aerospace"
    "command -v alacritty|.config/shared/alacritty/keys.macos.toml|~/.config/alacritty/keys.toml|Alacritty"
)

linux_configs=(
    # "command -v i3|.config/linux/i3/config|~/.config/i3/config|i3wm"
    "command -v alacritty|.config/shared/alacritty/keys.linux.toml|~/.config/alacritty/keys.toml|Alacritty"
    "command -v rofi|.config/linux/rofi/config.rasi|~/.config/rofi/config.rasi|Rofi"
    "command -v picom|.config/linux/picom/picom.conf|~/.config/picom/picom.conf|Picom"
)

# Architecture and distro-specific configurations
# Arch Linux x86_64
arch_x86_64_configs=(
    "command -v xmonad|.config/linux/xmonad/xmonad-arch-pc.hs|~/.config/xmonad/xmonad.hs|XMonad"
    "command -v xmobar|.config/linux/xmobar/xmobarrc-arch-pc|~/.config/xmobar/xmobarrc|Xmobar"
    "command -v dunst|.config/linux/dunst/dunstrc-arch-pc|~/.config/dunst/dunstrc|Dunst"
)

# Ubuntu aarch64 (ARM 64-bit)
ubuntu_aarch64_configs=(
    "command -v xmonad|.config/linux/xmonad/xmonad-ubuntu-aarch64.hs|~/.config/xmonad/xmonad.hs|XMonad"
    "command -v xmobar|.config/linux/xmobar/xmobarrc-ubuntu-aarch64|~/.config/xmobar/xmobarrc|Xmobar"
    "command -v dunst|.config/linux/dunst/dunstrc-ubuntu-aarch64|~/.config/dunst/dunstrc|Dunst"
)

# Ubuntu amd64 (x86_64)
ubuntu_amd64_configs=(
    "command -v xmonad|.config/linux/xmonad/xmonad-ubuntu-amd64.hs|~/.config/xmonad/xmonad.hs|XMonad"
    "command -v xmobar|.config/linux/xmobar/xmobarrc-ubuntu-amd64|~/.config/xmobar/xmobarrc|Xmobar"
    "command -v dunst|.config/linux/dunst/dunstrc-ubuntu-amd64|~/.config/dunst/dunstrc|Dunst"
)

# Main installation function
main() {
    local start_time=$(date +%s)
    # Check for required dependencies
    check_dependencies find cp mv diff date dirname basename xargs

    log_info "Starting configuration installation..."
    log_info "Operating System: $os"
    log_info "Architecture: $arch"
    if [[ "$os" == "Linux" ]]; then
        log_info "Distribution: $distro"
    fi

    # Process shared configurations
    log_info "Processing shared configurations..."
    for config in "${shared_configs[@]}"; do
        IFS='|' read -r check_cmd source target name <<< "$config"
        process_config "$check_cmd" "$source" "$target" "$name"
    done

    # Process directory configurations
    log_info "Processing directory configurations..."
    for config in "${shared_dir_configs[@]}"; do
        IFS='|' read -r check_cmd source target name <<< "$config"
        process_config_dir "$check_cmd" "$source" "$target" "$name"
    done

    # Process OS-specific configurations
    if [[ "$os" == "Darwin" ]]; then
        log_info "Processing macOS configurations..."
        for config in "${macos_configs[@]}"; do
            IFS='|' read -r check_cmd source target name <<< "$config"
            process_config "$check_cmd" "$source" "$target" "$name"
        done
    elif [[ "$os" == "Linux" ]]; then
        log_info "Processing Linux configurations..."
        for config in "${linux_configs[@]}"; do
            IFS='|' read -r check_cmd source target name <<< "$config"
            process_config "$check_cmd" "$source" "$target" "$name"
        done
        # Process architecture and distro-specific configurations
        if [[ "$distro" == "arch" ]]; then
            log_info "Processing Arch Linux configurations..."
            for config in "${arch_x86_64_configs[@]}"; do
                IFS='|' read -r check_cmd source target name <<< "$config"
                process_config "$check_cmd" "$source" "$target" "$name"
            done
        elif [[ "$distro" == "ubuntu" ]]; then
            if [[ "$arch" == "aarch64" ]]; then
                log_info "Processing Ubuntu ARM64 configurations..."
                for config in "${ubuntu_aarch64_configs[@]}"; do
                    IFS='|' read -r check_cmd source target name <<< "$config"
                    process_config "$check_cmd" "$source" "$target" "$name"
                done
            elif [[ "$arch" == "x86_64" ]]; then
                log_info "Processing Ubuntu AMD64 configurations..."
                for config in "${ubuntu_amd64_configs[@]}"; do
                    IFS='|' read -r check_cmd source target name <<< "$config"
                    process_config "$check_cmd" "$source" "$target" "$name"
                done
            fi
        fi
    else
        log_warn "Unsupported operating system: $os"
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log_info "Installation completed in $duration seconds"
}

# Run main function
main "$@"
