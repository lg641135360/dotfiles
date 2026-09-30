#!/bin/bash
# macOS system defaults
#
# Idempotent: every key is written only when its current value differs, and
# Finder/Dock/SystemUIServer are restarted only when something actually
# changed. install.sh calls this script on every run, so without the value
# comparison each run re-applied every setting and bounced the UI for nothing.
set -e

echo "Setting macOS defaults..."

changed=0

# Read a preference; empty string when unset. `defaults read` exits non-zero
# for missing keys, which must not abort the script.
defaults_read() {
    defaults read "$1" "$2" 2>/dev/null || true
}

set_bool() {
    local domain=$1 key=$2 value=$3 want current
    if [ "$value" = "true" ]; then want=1; else want=0; fi

    current=$(defaults_read "$domain" "$key")
    case "$current" in
        1|true|YES|yes) current=1 ;;
        0|false|NO|no) current=0 ;;
    esac
    [ "$current" = "$want" ] && return 0

    defaults write "$domain" "$key" -bool "$value"
    changed=$((changed + 1))
}

set_value() {
    local domain=$1 key=$2 type=$3 value=$4 current

    current=$(defaults_read "$domain" "$key")
    [ "$current" = "$value" ] && return 0

    defaults write "$domain" "$key" "-$type" "$value"
    changed=$((changed + 1))
}

# --- Key repeat ---
# Disable press-and-hold for accented characters, enable key repeat
set_bool NSGlobalDomain ApplePressAndHoldEnabled false
# Fast key repeat
set_value NSGlobalDomain KeyRepeat int 2
set_value NSGlobalDomain InitialKeyRepeat int 15

# --- Dock ---
# Auto-hide with zero animation delay
set_bool com.apple.dock autohide true
set_value com.apple.dock autohide-delay float 0
set_value com.apple.dock autohide-time-modifier float 0
# Don't show recent apps
set_bool com.apple.dock show-recents false

# --- Mission Control / Desktop（yabai & AeroSpace 的窗口管理前提）---
# 关闭"根据最近使用情况自动重新排列空间"：空间顺序稳定，WM 的 space 索引/标签才可靠
set_bool com.apple.dock mru-spaces false
# "点按墙纸以显示桌面"设为"仅在台前调度时"（macOS 14+），否则空间/显示器聚焦命令不稳定
set_bool com.apple.WindowManager EnableStandardClickToShowDesktop false
# 保持桌面图标可见（"显示项目"开启）；Finder 桌面窗口是聚焦空空间的前提
set_bool com.apple.WindowManager StandardHideDesktopIcons false

# --- Screenshots ---
# Disable shadow in screenshots
set_bool com.apple.screencapture disable-shadow true
# Save to ~/Downloads
set_value com.apple.screencapture location string "$HOME/Downloads"

# --- Finder ---
# Show hidden files
set_bool com.apple.finder AppleShowAllFiles true
# Show path bar
set_bool com.apple.finder ShowPathbar true
# Show all file extensions
set_bool NSGlobalDomain AppleShowAllExtensions true
# Keep folders on top when sorting by name
set_bool com.apple.finder _FXSortFoldersFirst true

# --- Trackpad ---
# Tap to click
set_bool com.apple.AppleMultitouchTrackpad Clicking true
set_bool com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking true

# --- No .DS_Store on network drives ---
set_bool com.apple.desktopservices DSDontWriteNetworkStores true

# --- Save dialogs expanded by default ---
set_bool NSGlobalDomain NSNavPanelExpandedStateForSaveMode true
set_bool NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 true

if [ "$changed" -gt 0 ]; then
    # Apply changes
    killall Finder &>/dev/null || true
    killall Dock &>/dev/null || true
    killall SystemUIServer &>/dev/null || true
    printf 'macOS defaults set (%s change(s)). Some changes require logout/restart to fully apply.\n' "$changed"
else
    printf 'macOS defaults already up to date; nothing changed.\n'
fi
