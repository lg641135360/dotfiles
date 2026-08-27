#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"
. "$REPO_ROOT/tests/lib/sandbox.sh"

INSTALL_FILE=$REPO_ROOT/install.sh

test_install_deploys_wayland_trial_files() {
    assert_not_contains 'is_wayland_session()' "$INSTALL_FILE"
    assert_not_contains 'XDG_SESSION_TYPE' "$INSTALL_FILE"
    assert_not_contains 'WAYLAND_DISPLAY' "$INSTALL_FILE"
    assert_contains 'script_dir=' "$INSTALL_FILE"
    assert_contains 'cur_path=$script_dir' "$INSTALL_FILE"
    assert_contains 'linux_wayland_configs=(' "$INSTALL_FILE"
    assert_contains 'linux_wayland_dir_configs=(' "$INSTALL_FILE"
    assert_contains '|.config/scripts/wayland-autostart|~/.config/scripts/wayland-autostart|Wayland autostart script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/file-manager-wayland|~/.config/scripts/file-manager-wayland|Wayland file manager selector' "$INSTALL_FILE"
    assert_contains '|.config/scripts/dingtalk-wayland|~/.config/scripts/dingtalk-wayland|DingTalk Wayland script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/terminal-wayland|~/.config/scripts/terminal-wayland|Wayland terminal script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/launcher-wayland|~/.config/scripts/launcher-wayland|Wayland launcher script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/lock-wayland|~/.config/scripts/lock-wayland|Wayland lock script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/screenshot-wayland|~/.config/scripts/screenshot-wayland|Wayland screenshot script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/browser-wayland|~/.config/scripts/browser-wayland|Wayland browser script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/trae-cn-wayland|~/.config/scripts/trae-cn-wayland|Wayland Trae CN script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/obsidian-wayland|~/.config/scripts/obsidian-wayland|Wayland Obsidian script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/waybar-system-tooltip|~/.config/scripts/waybar-system-tooltip|Waybar CPU/MEM tooltip script' "$INSTALL_FILE"
    # backlight 用 waybar 内置模块，不再部署独立 watcher 脚本。
    assert_not_contains 'waybar-backlight' "$INSTALL_FILE"
    assert_contains '|.config/linux/desktop-entries/google-chrome.desktop|~/.local/share/applications/google-chrome.desktop|Google Chrome Wayland desktop entry' "$INSTALL_FILE"
    assert_contains '|.config/linux/desktop-entries/trae-cn.desktop|~/.local/share/applications/trae-cn.desktop|Trae CN Wayland desktop entry' "$INSTALL_FILE"
    assert_contains '|.config/linux/desktop-entries/obsidian.desktop|~/.local/share/applications/obsidian.desktop|Obsidian Wayland desktop entry' "$INSTALL_FILE"
    # install.sh substitutes the __HOME__ placeholder in desktop entries with $HOME at deploy time.
    assert_contains '//__HOME__/$HOME' "$INSTALL_FILE"
    assert_contains '|.config/scripts/wallpaper-wayland|~/.config/scripts/wallpaper-wayland|Wayland wallpaper script' "$INSTALL_FILE"
    assert_contains '|.config/scripts/wallpaper-wayland-next|~/.config/scripts/wallpaper-wayland-next|Wayland wallpaper switcher' "$INSTALL_FILE"
    assert_contains '|.config/linux/xdg-desktop-portal/niri-portals.conf|~/.local/share/xdg-desktop-portal/niri-portals.conf|niri desktop portal preferences' "$INSTALL_FILE"
    # XDG autostart 覆盖：Hidden=true 禁用 GNOME/X11 遗留 autostart（niri 会话）。
    assert_contains '|.config/linux/xdg-autostart/org.gnome.Evolution-alarm-notify.desktop|~/.config/autostart/org.gnome.Evolution-alarm-notify.desktop|XDG autostart override: evolution-alarm-notify' "$INSTALL_FILE"
    assert_contains '|.config/linux/xdg-autostart/nm-applet.desktop|~/.config/autostart/nm-applet.desktop|XDG autostart override: nm-applet' "$INSTALL_FILE"
    assert_contains '|.config/linux/xdg-autostart/print-applet.desktop|~/.config/autostart/print-applet.desktop|XDG autostart override: print-applet' "$INSTALL_FILE"
    assert_contains '|.config/linux/xdg-autostart/geoclue-demo-agent.desktop|~/.config/autostart/geoclue-demo-agent.desktop|XDG autostart override: geoclue-demo-agent' "$INSTALL_FILE"
    assert_contains 'if command -v niri >/dev/null 2>&1; then' "$INSTALL_FILE"
    assert_contains 'install_niri_config_for_platform()' "$INSTALL_FILE"
    assert_contains 'niri_platform_key()' "$INSTALL_FILE"
    assert_contains 'is_repo_niri_platform()' "$INSTALL_FILE"
    assert_contains "printf 'ubuntu_x64'" "$INSTALL_FILE"
    assert_contains 'is_opensuse()' "$INSTALL_FILE"
    assert_contains 'skipping Alacritty configuration copy' "$INSTALL_FILE"
    assert_contains 'skipping niri configuration copy' "$INSTALL_FILE"
    assert_contains 'source="$cur_path/.config/linux/niri/$platform/config.kdl"' "$INSTALL_FILE"
    assert_contains 'common_source="$cur_path/.config/linux/niri/common.kdl"' "$INSTALL_FILE"
    assert_contains 'copy_config "$common_source" "$target_dir/common.kdl" "niri common config"' "$INSTALL_FILE"
    assert_contains 'sed ' "$INSTALL_FILE"
    assert_contains 'include "common.kdl"' "$INSTALL_FILE"
    assert_not_contains 'command -v niri|.config/linux/niri|~/.config/niri|niri' "$INSTALL_FILE"
    assert_contains 'install_waybar_config_for_platform()' "$INSTALL_FILE"
    assert_contains '"$src_dir/config.aarch64"' "$INSTALL_FILE"
    assert_contains 'copy_config "$config_src" "$target_dir/config" "waybar config (${arch:-generic})"' "$INSTALL_FILE"
    assert_contains 'command -v mako|.config/linux/mako|~/.config/mako|Mako' "$INSTALL_FILE"
    assert_contains 'command -v fuzzel|.config/linux/fuzzel|~/.config/fuzzel|Fuzzel' "$INSTALL_FILE"
}

test_install_copies_wayland_files_when_niri_exists_outside_wayland_session() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin

    mkdir -p "$home_dir" "$bin_dir"
    prepare_install_path "$bin_dir"

    (
        cd "$tmpdir"
        PATH=$bin_dir HOME=$home_dir DOTFILES_OS=Linux DOTFILES_DISTRO=ubuntu DOTFILES_ARCH=x86_64 XDG_SESSION_TYPE=x11 WAYLAND_DISPLAY= \
            /bin/bash "$REPO_ROOT/install.sh" >/dev/null 2>&1
    ) || fail "install.sh should use its own directory and deploy niri outside Wayland"

    assert_file_exists "$home_dir/.config/scripts/wayland-autostart"
    assert_file_exists "$home_dir/.config/scripts/file-manager-wayland"
    assert_file_exists "$home_dir/.config/niri/config.kdl"

    rm -rf "$tmpdir"
}

test_install_copies_ubuntu_x64_niri_config() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin

    mkdir -p "$home_dir" "$bin_dir"
    prepare_install_path "$bin_dir"

    PATH=$bin_dir HOME=$home_dir DOTFILES_OS=Linux DOTFILES_DISTRO=ubuntu DOTFILES_ARCH=x86_64 XDG_SESSION_TYPE=wayland /bin/bash "$REPO_ROOT/install.sh" >/dev/null 2>&1 ||
        fail "install.sh should succeed in Wayland session"

    assert_file_exists "$home_dir/.config/scripts/wayland-autostart"
    assert_file_exists "$home_dir/.config/niri/config.kdl"
    assert_file_exists "$home_dir/.config/niri/common.kdl"
    assert_file_not_exists "$home_dir/.config/niri/README.md"
    assert_contains '// Platform: ubuntu_x64' "$home_dir/.config/niri/config.kdl"
    assert_contains 'include "common.kdl"' "$home_dir/.config/niri/config.kdl"
    assert_not_contains 'include "../common.kdl"' "$home_dir/.config/niri/config.kdl"
    assert_contains 'output "DP-4" {' "$home_dir/.config/niri/config.kdl"
    assert_contains 'scale 1.25' "$home_dir/.config/niri/config.kdl"

    # Desktop entries get the __HOME__ placeholder substituted with the real $HOME.
    assert_file_exists "$home_dir/.local/share/applications/google-chrome.desktop"
    assert_contains "Exec=$home_dir/.config/scripts/browser-wayland %U" "$home_dir/.local/share/applications/google-chrome.desktop"
    assert_not_contains '__HOME__' "$home_dir/.local/share/applications/google-chrome.desktop"

    # XDG autostart overrides are deployed with Hidden=true.
    for autostart_override in \
        org.gnome.Evolution-alarm-notify \
        nm-applet \
        print-applet \
        geoclue-demo-agent; do
        assert_file_exists "$home_dir/.config/autostart/$autostart_override.desktop"
        assert_contains 'Hidden=true' "$home_dir/.config/autostart/$autostart_override.desktop"
    done

    rm -rf "$tmpdir"
}

test_install_preserves_arch_niri_config() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin

    mkdir -p "$home_dir" "$bin_dir"
    prepare_install_path "$bin_dir"
    mkdir -p "$home_dir/.config/niri"
    printf 'include "arch-existing.kdl"\n' >"$home_dir/.config/niri/config.kdl"
    printf 'arch common configuration\n' >"$home_dir/.config/niri/common.kdl"

    PATH=$bin_dir HOME=$home_dir DOTFILES_OS=Linux DOTFILES_DISTRO=arch DOTFILES_ARCH=x86_64 XDG_SESSION_TYPE=wayland /bin/bash "$REPO_ROOT/install.sh" >/dev/null 2>&1 ||
        fail "install.sh should succeed on Arch x64 Wayland"

    assert_file_exists "$home_dir/.config/scripts/wayland-autostart"
    assert_contains 'include "arch-existing.kdl"' "$home_dir/.config/niri/config.kdl"
    assert_contains 'arch common configuration' "$home_dir/.config/niri/common.kdl"

    rm -rf "$tmpdir"
}

test_install_preserves_opensuse_dms_niri_and_alacritty_configs() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin

    mkdir -p "$home_dir" "$bin_dir"
    prepare_install_path "$bin_dir"
    mkdir -p "$home_dir/.config/niri" "$home_dir/.config/alacritty"
    printf 'include "dms/layout.kdl"\n' >"$home_dir/.config/niri/config.kdl"
    printf 'dms common configuration\n' >"$home_dir/.config/niri/common.kdl"
    printf '[general]\nimport = ["~/.config/alacritty/dank-theme.toml"]\n' >"$home_dir/.config/alacritty/alacritty.toml"
    printf 'dms keys configuration\n' >"$home_dir/.config/alacritty/keys.toml"
    printf 'dms window configuration\n' >"$home_dir/.config/alacritty/window.toml"

    PATH=$bin_dir HOME=$home_dir DOTFILES_OS=Linux DOTFILES_DISTRO=opensuse-tumbleweed DOTFILES_ARCH=x86_64 XDG_SESSION_TYPE=wayland /bin/bash "$REPO_ROOT/install.sh" >/dev/null 2>&1 ||
        fail "install.sh should succeed on openSUSE Tumbleweed x64"

    assert_file_exists "$home_dir/.config/scripts/wayland-autostart"
    assert_contains 'include "dms/layout.kdl"' "$home_dir/.config/niri/config.kdl"
    assert_contains 'dms common configuration' "$home_dir/.config/niri/common.kdl"
    assert_contains 'dank-theme.toml' "$home_dir/.config/alacritty/alacritty.toml"
    assert_contains 'dms keys configuration' "$home_dir/.config/alacritty/keys.toml"
    assert_contains 'dms window configuration' "$home_dir/.config/alacritty/window.toml"

    rm -rf "$tmpdir"
}

test_install_keeps_live_niri_config_for_unmapped_platform() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin

    mkdir -p "$home_dir" "$bin_dir"
    prepare_install_path "$bin_dir"
    mkdir -p "$home_dir/.config/niri"
    printf 'include "existing-output.kdl"\n' >"$home_dir/.config/niri/config.kdl"

    PATH=$bin_dir HOME=$home_dir DOTFILES_OS=Linux DOTFILES_DISTRO=fedora DOTFILES_ARCH=x86_64 XDG_SESSION_TYPE=wayland /bin/bash "$REPO_ROOT/install.sh" >/dev/null 2>&1 ||
        fail "install.sh should keep the live niri config for an unmapped platform"

    assert_file_exists "$home_dir/.config/scripts/wayland-autostart"
    assert_file_exists "$home_dir/.config/niri/config.kdl"
    assert_contains 'include "existing-output.kdl"' "$home_dir/.config/niri/config.kdl"
    assert_file_not_exists "$home_dir/.config/niri/common.kdl"

    rm -rf "$tmpdir"
}

test_install_skips_niri_and_wayland_files_when_niri_is_missing() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin
    output=$tmpdir/output.log

    mkdir -p "$home_dir" "$bin_dir"
    prepare_install_path "$bin_dir"
    rm -f "$bin_dir/niri"

    PATH=$bin_dir HOME=$home_dir DOTFILES_OS=Linux DOTFILES_DISTRO=ubuntu DOTFILES_ARCH=x86_64 \
        /bin/bash "$REPO_ROOT/install.sh" >"$output" 2>&1 ||
        fail "install.sh should succeed when niri is missing"

    assert_file_not_exists "$home_dir/.config/niri/config.kdl"
    assert_file_not_exists "$home_dir/.config/scripts/wayland-autostart"
    assert_contains 'niri not found' "$output"

    rm -rf "$tmpdir"
}

test_install_deploys_wayland_trial_files
test_install_copies_wayland_files_when_niri_exists_outside_wayland_session
test_install_copies_ubuntu_x64_niri_config
test_install_preserves_arch_niri_config
test_install_preserves_opensuse_dms_niri_and_alacritty_configs
test_install_keeps_live_niri_config_for_unmapped_platform
test_install_skips_niri_and_wayland_files_when_niri_is_missing

printf 'PASS: install wayland tests\n'
