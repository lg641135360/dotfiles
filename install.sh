#!/bin/bash
set -e  # Exit on error

# Script configuration
os=$(uname -s)
arch=$(uname -m)
cur_path=$(pwd)
backup_limit=3
timestamp=$(date +%Y%m%d_%H%M%S)

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
    local dir backup_items count removed=0
    dir="$(dirname "$target")"
    [ ! -d "$dir" ] && return 0

    # Find all backup items for this target (files or directories)
    backup_items=$(find "$dir" -maxdepth 1 -name "$(basename "$target").backup.*" | sort -r)
    
    count=$(echo "$backup_items" | grep -c . || true)
    if [ "$count" -gt "$backup_limit" ]; then
        echo "$backup_items" | tail -n +"$((backup_limit + 1))" | while read -r item; do
            rm -rf "$item" && removed=$((removed + 1))
        done
        if [ $removed -gt 0 ]; then
            log_info "Cleaned $removed old backups for $(basename "$target")"
        fi
    fi
}

# Copy configuration (replaces link_config)
copy_config() {
    local source="$1" target="$2" name="$3"

    # Validate input
    if [ ! -e "$source" ]; then
        log_error "Source not found: $source"
        return 1
    fi

    # Create target parent directory
    if ! ensure_dir "$(dirname "$target")"; then
        return 1
    fi

    # Create backup if target exists
    if [ -e "$target" ]; then
        # Check if it's identical to source (skip if same)
        if diff -r "$source" "$target" >/dev/null 2>&1; then
             log_info "Skipping $name: Target is identical to source"
             return 0
        fi

        local backup_path="$target.backup.$timestamp"
        if ! mv "$target" "$backup_path"; then
            log_error "Failed to create backup for $target"
            return 1
        fi
        log_info "Backed up existing $name to $(basename "$backup_path")"
        clean_old_backups "$target"
    fi

    # Copy file or directory
    if [ -d "$source" ]; then
        if cp -a "$source" "$target"; then
            log_info "Successfully copied directory $name -> $target"
        else
            log_error "Failed to copy directory $name"
            return 1
        fi
    else
        if cp -p "$source" "$target"; then
            log_info "Successfully copied file $name -> $target"
        else
            log_error "Failed to copy file $name"
            return 1
        fi
    fi
}

# Setup Zsh Environment (ZDOTDIR)
setup_zsh_env() {
    local zshenv="$HOME/.zshenv"
    local zconfig_dir="$HOME/.config/zsh"
    
    if command -v zsh >/dev/null 2>&1; then
        if [ ! -f "$zshenv" ] || ! grep -q "ZDOTDIR" "$zshenv"; then
            log_info "Configuring ZDOTDIR in ~/.zshenv..."
            echo "export ZDOTDIR=\"$zconfig_dir\"" >> "$zshenv"
        else
            log_info "ZDOTDIR configuration detected in ~/.zshenv"
        fi
    fi
}

# Process configuration
process_config() {
    local check_cmd="$1" source="$2" target="$3" name="$4"

    [ -n "$check_cmd" ] && ! eval "$check_cmd" >/dev/null 2>&1 && return 0
    [[ "$source" != /* ]] && source="$cur_path/$source"
    target="${target/#\~/$HOME}"

    # Special handling for zsh directory to preserve history
    if [[ "$target" == *"/zsh" ]] || [[ "$target" == *"~/.config/zsh" ]]; then
        copy_zsh_config "$source" "$target" "$name"
    else
        copy_config "$source" "$target" "$name"
    fi
}

# Copy zsh configuration while preserving history
copy_zsh_config() {
    local source="$1" target="$2" name="$3"
    local history_backup=""

    # Save existing .zsh_history if present
    if [ -f "$target/.zsh_history" ]; then
        history_backup=$(mktemp /tmp/zsh_history.XXXXXX)
        cp "$target/.zsh_history" "$history_backup"
        log_info "Preserved existing .zsh_history"
    fi

    # Perform normal copy
    copy_config "$source" "$target" "$name"

    # Restore .zsh_history after copy
    if [ -n "$history_backup" ] && [ -f "$history_backup" ]; then
        mv "$history_backup" "$target/.zsh_history"
        log_info "Restored .zsh_history to $target"
    fi
}

# Configuration arrays
# app name | source path | target path | display name
shared_configs=(
    "command -v tmux|.config/shared/tmux/.tmux.conf|~/.tmux.conf|Tmux"
    "command -v kitty|.config/shared/kitty/kitty.conf|~/.config/kitty/kitty.conf|Kitty"
    "command -v kitty|.config/shared/kitty/Dracula.conf|~/.config/kitty/themes/Dracula.conf|kitty_theme"
    "command -v alacritty|.config/shared/alacritty/alacritty.toml|~/.config/alacritty/alacritty.toml|Alacritty"
)

# Directory configurations
shared_dir_configs=(
    "command -v git|.config/shared/git|~/.config/git|git"
    "command -v nvim|.config/shared/nvim|~/.config/nvim|nvim"
    "command -v zsh|.config/shared/zsh|~/.config/zsh|zsh"
)

macos_configs=(
    "command -v aerospace|.config/macos/aerospace/aerospace.toml|~/.config/aerospace/aerospace.toml|Aerospace"
    "command -v rift|.config/macos/rift/config.toml|~/.config/rift/config.toml|Rift"
    "command -v alacritty|.config/shared/alacritty/keys.macos.toml|~/.config/alacritty/keys.toml|Alacritty"
)

linux_configs=(
    # "command -v i3|.config/linux/i3/config|~/.config/i3/config|i3wm"
    "command -v alacritty|.config/shared/alacritty/keys.linux.toml|~/.config/alacritty/keys.toml|Alacritty"
    "command -v rofi|.config/linux/rofi/config.rasi|~/.config/rofi/config.rasi|Rofi"
    "command -v awesome|.config/linux/awesome/theme/default.lua|~/.config/awesome/theme.lua|AwesomeWM theme"
)

# Architecture and distro-specific configurations
# Arch Linux x86_64
arch_x86_64_configs=(
    "command -v xmonad|.config/linux/xmonad/xmonad-arch-pc.hs|~/.config/xmonad/xmonad.hs|XMonad"
    "command -v xmobar|.config/linux/xmobar/xmobarrc-arch-pc|~/.config/xmobar/xmobarrc|Xmobar"
    "command -v dunst|.config/linux/dunst/dunstrc-arch-pc|~/.config/dunst/dunstrc|Dunst"
    "command -v picom|.config/linux/picom/picom-best-power.conf|~/.config/picom/picom.conf|Picom"
    "command -v xrdb|.config/linux/x11/xresources/arch_x64|~/.Xresources|Xresources"
    "command -v awesome|.config/linux/awesome/rc/arch_x64.lua|~/.config/awesome/rc.lua|AwesomeWM rc.lua"
    "command -v awesome|.config/linux/awesome/autostart/arch_x64.sh|~/.config/awesome/autostart.sh|AwesomeWM autostart script"
)

# Ubuntu aarch64 (ARM 64-bit)
ubuntu_aarch64_configs=(
    "command -v xmonad|.config/linux/xmonad/xmonad-ubuntu-aarch64.hs|~/.xmonad/xmonad.hs|XMonad"
    "command -v xmobar|.config/linux/xmobar/xmobarrc-ubuntu-aarch64|~/.config/xmobar/xmobarrc|Xmobar"
    "command -v dunst|.config/linux/dunst/dunstrc-ubuntu-aarch64|~/.config/dunst/dunstrc|Dunst"
    "command -v picom|.config/linux/picom/picom-aarch64.conf|~/.config/picom/picom.conf|Picom"
    "command -v xrdb|.config/linux/x11/xresources/ubuntu_aarch64|~/.Xresources|Xresources"
    "command -v awesome|.config/linux/awesome/rc/ubuntu_aarch64.lua|~/.config/awesome/rc.lua|AwesomeWM rc.lua"
    "command -v awesome|.config/linux/awesome/autostart/ubuntu_aarch64.sh|~/.config/awesome/autostart.sh|AwesomeWM autostart script"
)

# Ubuntu amd64 (x86_64)
ubuntu_amd64_configs=(
    "command -v xmonad|.config/linux/xmonad/xmonad-ubuntu-amd64.hs|~/.config/xmonad/xmonad.hs|XMonad"
    "command -v xmobar|.config/linux/xmobar/xmobarrc-ubuntu-amd64|~/.config/xmobar/xmobarrc|Xmobar"
    "command -v dunst|.config/linux/dunst/dunstrc-ubuntu-amd64|~/.config/dunst/dunstrc|Dunst"
    "command -v picom|.config/linux/picom/picom-lower-power.conf|~/.config/picom/picom.conf|Picom"
    "command -v xrdb|.config/linux/x11/xresources/ubuntu_x64|~/.Xresources|Xresources"
    "command -v awesome|.config/linux/awesome/rc/ubuntu_x64.lua|~/.config/awesome/rc.lua|AwesomeWM rc.lua"
    "command -v awesome|.config/linux/awesome/autostart/ubuntu_x64.sh|~/.config/awesome/autostart.sh|AwesomeWM autostart script"
)

# Main installation function
main() {
    local start_time=$(date +%s)
    # Check for required dependencies
    check_dependencies find cp mv diff date dirname basename sort grep tail

    log_info "Starting configuration installation (Copy Mode)..."
    log_info "Operating System: $os"
    log_info "Architecture: $arch"
    if [[ "$os" == "Linux" ]]; then
        log_info "Distribution: $distro"
    fi

    # Setup Zsh env
    setup_zsh_env

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
        process_config "$check_cmd" "$source" "$target" "$name"
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
