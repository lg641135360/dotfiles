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
    "command -v tmux|.config/shared/tmux/.tmux.conf|~/.tmux.conf|Tmux"
    "command -v kitty|.config/shared/kitty/kitty.conf|~/.config/kitty/kitty.conf|Kitty"
    "command -v kitty|.config/shared/kitty/Dracula.conf|~/.config/kitty/themes/Dracula.conf|kitty_theme"
    "command -v alacritty|.config/shared/alacritty/alacritty.toml|~/.config/alacritty/alacritty.toml|Alacritty"
)

# Directory configurations
shared_dir_configs=(
    "command -v git|.config/shared/git|~/.config/git|git"
    "command -v nvim|.config/shared/nvim|~/.config/nvim|nvim"
)

# Zsh module files (all copied to ZDOTDIR)
zsh_files=(
    "|.config/shared/zsh/.zshrc|~/.config/zsh/.zshrc|.zshrc"
    "|.config/shared/zsh/plugins.zsh|~/.config/zsh/plugins.zsh|zsh plugins"
    "|.config/shared/zsh/options.zsh|~/.config/zsh/options.zsh|zsh options"
    "|.config/shared/zsh/env.zsh|~/.config/zsh/env.zsh|zsh env"
    "|.config/shared/zsh/path.zsh|~/.config/zsh/path.zsh|zsh path"
    "|.config/shared/zsh/keybindings.zsh|~/.config/zsh/keybindings.zsh|zsh keybindings"
    "|.config/shared/zsh/history.zsh|~/.config/zsh/history.zsh|zsh history"
    "|.config/shared/zsh/aliases.zsh|~/.config/zsh/aliases.zsh|zsh aliases"
    "|.config/shared/zsh/functions.zsh|~/.config/zsh/functions.zsh|zsh functions"
    "|.config/shared/zsh/integrations.zsh|~/.config/zsh/integrations.zsh|zsh integrations"
    "|.config/shared/zsh/zsh-syntax-highlighting-tokyonight.zsh|~/.config/zsh/zsh-syntax-highlighting-tokyonight.zsh|zsh syntax-highlighting-tokyonight"
)

# .zshrc.pre is only needed when grml-zsh is installed (fixes fpath issues)
zshrc_pre_files=(
    "|.config/shared/zsh/.zshrc.pre|~/.config/zsh/.zshrc.pre|.zshrc.pre"
)

macos_configs=(
    "command -v aerospace|.config/macos/aerospace/aerospace.toml|~/.config/aerospace/aerospace.toml|Aerospace"
    "command -v rift|.config/macos/rift/config.toml|~/.config/rift/config.toml|Rift"
    "command -v alacritty|.config/shared/alacritty/keys.macos.toml|~/.config/alacritty/keys.toml|Alacritty keys"
    "command -v alacritty|.config/shared/alacritty/window.macos.toml|~/.config/alacritty/window.toml|Alacritty window"
)

linux_configs=(
    # "command -v i3|.config/linux/i3/config|~/.config/i3/config|i3wm"
    "command -v alacritty|.config/shared/alacritty/keys.linux.toml|~/.config/alacritty/keys.toml|Alacritty keys"
    "command -v alacritty|.config/shared/alacritty/window.linux.toml|~/.config/alacritty/window.toml|Alacritty window"
    "command -v rofi|.config/linux/rofi/config.rasi|~/.config/rofi/config.rasi|Rofi"
    "command -v i3lock|.config/scripts/lock|~/.config/scripts/lock|Lock screen script"
)

# Linux directory configurations
linux_dir_configs=(
    "command -v awesome|.config/linux/awesome|~/.config/awesome|AwesomeWM"
)

# Architecture and distro-specific configurations (awesome autostart only)
# Arch Linux x86_64
arch_x86_64_configs=(
    "command -v awesome|.config/linux/awesome/autostart/arch_x64.sh|~/.config/awesome/autostart.sh|AwesomeWM autostart script"
    "command -v picom|.config/linux/picom/picom-arch_x64.conf|~/.config/picom.conf|picom configuration"
)

# Ubuntu aarch64 (ARM 64-bit)
ubuntu_aarch64_configs=(
    "command -v awesome|.config/linux/awesome/autostart/ubuntu_aarch64.sh|~/.config/awesome/autostart.sh|AwesomeWM autostart script"
    "command -v picom|.config/linux/picom/picom-arch_aarch64.conf|~/.config/picom.conf|picom configuration"
)

# Ubuntu amd64 (x86_64)
ubuntu_amd64_configs=(
    "command -v awesome|.config/linux/awesome/autostart/ubuntu_x64.sh|~/.config/awesome/autostart.sh|AwesomeWM autostart script"
    "command -v picom|.config/linux/picom/picom-ubuntu_x64.conf|~/.config/picom.conf|picom configuration"
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

    # Process shared configurations
    log_info "Processing shared configurations..."
    for config in "${shared_configs[@]}"; do
        IFS='|' read -r check_cmd source target name <<< "$config"
        process_config "$check_cmd" "$source" "$target" "$name"
    done

    # Check and install TPM (Tmux Plugin Manager)
    if command -v tmux >/dev/null 2>&1; then
        tpm_dir="$HOME/.tmux/plugins/tpm"
        if [ ! -d "$tpm_dir" ]; then
            log_info "Installing TPM (Tmux Plugin Manager)"
            if command -v git >/dev/null 2>&1; then
                git clone https://github.com/tmux-plugins/tpm.git "$tpm_dir" || \
                    log_warn "Failed to clone TPM, please install it manually"
            else
                log_warn "git not found, cannot install TPM automatically"
            fi
        fi
    fi

    # Process directory configurations
    log_info "Processing directory configurations..."
    for config in "${shared_dir_configs[@]}"; do
        IFS='|' read -r check_cmd source target name <<< "$config"
        process_config "$check_cmd" "$source" "$target" "$name"
    done

    # Process Zsh file configurations
    log_info "Processing Zsh file configurations..."
    for config in "${zsh_files[@]}"; do
        IFS='|' read -r check_cmd source target name <<< "$config"
        process_config "$check_cmd" "$source" "$target" "$name"
    done

    # Process .zshrc.pre only if grml-zsh is installed
    if [[ -f /etc/zsh/zshrc ]] && grep -q "grml" /etc/zsh/zshrc 2>/dev/null; then
        log_info "Detected grml-zsh, installing .zshrc.pre..."
        for config in "${zshrc_pre_files[@]}"; do
            IFS='|' read -r check_cmd source target name <<< "$config"
            process_config "$check_cmd" "$source" "$target" "$name"
        done
    else
        log_info "grml-zsh not detected, skipping .zshrc.pre"
    fi

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

        # Save AwesomeWM external dependencies before copying
        # (copy_config backs up the entire dir, which would overwrite freshly cloned deps)
        awesome_deps=()
        awesome_deps_save_dir="/tmp/awesome_deps_$$"
        if command -v awesome >/dev/null 2>&1; then
            awesome_config_dir="$HOME/.config/awesome"
            if [ -d "$awesome_config_dir" ]; then
                for dep in lain collision; do
                    if [ -d "$awesome_config_dir/$dep" ]; then
                        log_info "Saving AwesomeWM dependency: $dep"
                        mkdir -p "$awesome_deps_save_dir"
                        cp -a "$awesome_config_dir/$dep" "$awesome_deps_save_dir/$dep"
                        awesome_deps+=("$dep")
                    fi
                done
            fi
        fi

        # Process Linux directory configurations
        log_info "Processing Linux directory configurations..."
        for config in "${linux_dir_configs[@]}"; do
            IFS='|' read -r check_cmd source target name <<< "$config"
            process_config "$check_cmd" "$source" "$target" "$name"
        done

        # Restore AwesomeWM external dependencies after copying
        if [ ${#awesome_deps[@]} -gt 0 ] && [ -d "$awesome_deps_save_dir" ]; then
            awesome_config_dir="$HOME/.config/awesome"
            for dep in "${awesome_deps[@]}"; do
                if [ -d "$awesome_deps_save_dir/$dep" ]; then
                    log_info "Restoring AwesomeWM dependency: $dep"
                    cp -a "$awesome_deps_save_dir/$dep" "$awesome_config_dir/$dep"
                fi
            done
            rm -rf "$awesome_deps_save_dir"
        fi

        # Check and install AwesomeWM external dependencies (if not in backup, clone fresh)
        if command -v awesome >/dev/null 2>&1; then
            awesome_config_dir="$HOME/.config/awesome"

            if [ ! -d "$awesome_config_dir/lain" ]; then
                log_info "Installing AwesomeWM dependency: lain"
                if command -v git >/dev/null 2>&1; then
                    git clone https://github.com/lcpz/lain.git "$awesome_config_dir/lain" || \
                        log_warn "Failed to clone lain, please install it manually"
                else
                    log_warn "git not found, cannot install lain automatically"
                fi
            fi

            if [ ! -d "$awesome_config_dir/collision" ]; then
                log_info "Installing AwesomeWM dependency: collision"
                if command -v git >/dev/null 2>&1; then
                    git clone https://github.com/Elv13/collision.git "$awesome_config_dir/collision" || \
                        log_warn "Failed to clone collision, please install it manually"
                else
                    log_warn "git not found, cannot install collision automatically"
                fi
            fi
        fi

        # Check and install Alacritty themes
        if command -v alacritty >/dev/null 2>&1; then
            alacritty_config_dir="$HOME/.config/alacritty"
            alacritty_themes_dir="$alacritty_config_dir/themes"

            if [ ! -d "$alacritty_themes_dir" ]; then
                log_info "Installing Alacritty themes"
                if command -v git >/dev/null 2>&1; then
                    git clone --depth 1 https://github.com/alacritty-theme/alacritty-themes.git "$alacritty_themes_dir" || \
                        log_warn "Failed to clone alacritty-themes, please install it manually"
                else
                    log_warn "git not found, cannot install alacritty-themes automatically"
                fi
            fi
        fi

        # Process architecture and distro-specific configurations
        if [[ "$distro" == "arch" ]]; then
            log_info "Processing Arch Linux configurations..."
            for config in "${arch_x86_64_configs[@]}"; do
                IFS='|' read -r check_cmd source target name <<< "$config"
                process_config "$check_cmd" "$source" "$target" "$name"
            done
        elif [[ "$distro" == "ubuntu" ]]; then
            # Install redshift from apt (system version has X11 support, unlike homebrew)
            if command -v dpkg >/dev/null 2>&1 && ! dpkg -l redshift 2>/dev/null | grep -q '^ii'; then
                log_info "Installing redshift from apt"
                sudo apt-get install -y redshift || \
                    log_warn "Failed to install redshift, please install it manually"
            fi

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
