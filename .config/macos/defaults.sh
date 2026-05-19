#!/bin/bash
# macOS system defaults — run once per machine
set -e

echo "Setting macOS defaults..."

# --- Key repeat ---
# Disable press-and-hold for accented characters, enable key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Fast key repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# --- Dock ---
# Auto-hide with zero animation delay
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0
# Don't show recent apps
defaults write com.apple.dock show-recents -bool false

# --- Screenshots ---
# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true
# Save to ~/Downloads
defaults write com.apple.screencapture location -string "$HOME/Downloads"

# --- Finder ---
# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true
# Show path bar
defaults write com.apple.finder ShowPathbar -bool true
# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# --- Trackpad ---
# Tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# --- No .DS_Store on network drives ---
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# --- Save dialogs expanded by default ---
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Apply changes
killall Finder &> /dev/null || true
killall Dock &> /dev/null || true
killall SystemUIServer &> /dev/null || true

echo "macOS defaults set. Some changes require logout/restart to fully apply."
