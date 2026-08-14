#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

XRESOURCES_DIR=$REPO_ROOT/.config/linux/x11/xresources
XRESOURCES_ARCH_X64=$XRESOURCES_DIR/arch_x64
XRESOURCES_UBUNTU_X64=$XRESOURCES_DIR/ubuntu_x64
XRESOURCES_UBUNTU_AARCH64=$XRESOURCES_DIR/ubuntu_aarch64
XSESSIONRC=$REPO_ROOT/.config/linux/x11/xsessionrc
CURSOR_1X=$REPO_ROOT/.config/linux/x11/xsessionrc.d/cursor.1x
CURSOR_2X=$REPO_ROOT/.config/linux/x11/xsessionrc.d/cursor.2x

test_xresources_contain_dpi_and_antialiasing() {
    for file in "$XRESOURCES_ARCH_X64" "$XRESOURCES_UBUNTU_X64" "$XRESOURCES_UBUNTU_AARCH64"; do
        assert_file_exists "$file"
        assert_contains 'Xft.dpi:' "$file"
        assert_contains 'Xft.antialias:' "$file"
        assert_contains 'Xft.hinting:' "$file"
        assert_contains 'Xft.hintstyle:' "$file"
        assert_contains 'Xft.rgba:' "$file"
        assert_contains 'Xft.lcdfilter:' "$file"
    done
}

test_xresources_dpi_matches_cursor_size_contract() {
    # arch_x64 / ubuntu_aarch64 are 2x HiDPI (Xft.dpi=192 → XCURSOR_SIZE=48).
    # ubuntu_x64 is standard DPI (Xft.dpi=124 → XCURSOR_SIZE=32).
    assert_contains 'Xft.dpi: 192' "$XRESOURCES_ARCH_X64"
    assert_contains 'Xft.dpi: 192' "$XRESOURCES_UBUNTU_AARCH64"
    assert_contains 'Xft.dpi: 124' "$XRESOURCES_UBUNTU_X64"

    assert_contains 'export XCURSOR_SIZE=48' "$CURSOR_2X"
    assert_contains 'export XCURSOR_SIZE=32' "$CURSOR_1X"
}

test_xresources_define_color_palette() {
    # Every xresources file defines the same base00..base0F catppuccin/one-dark
    # palette so ~/.Xresources consumers (rofi, terminals) see consistent colors.
    for file in "$XRESOURCES_ARCH_X64" "$XRESOURCES_UBUNTU_X64" "$XRESOURCES_UBUNTU_AARCH64"; do
        for n in 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F; do
            assert_contains "#define base$n " "$file"
        done
    done
}

test_xsessionrc_sources_cursor_and_xresources() {
    assert_file_exists "$XSESSIONRC"
    # xsessionrc sources cursor settings (selected by install.sh based on arch).
    assert_contains '. "$HOME/.xsessionrc.d/cursor"' "$XSESSIONRC"
    # Merges ~/.Xresources so the xresources/* files become active.
    assert_contains 'xrdb -merge "$HOME/.Xresources"' "$XSESSIONRC"
    # Standard IME env vars for X11 session.
    assert_contains 'export GTK_IM_MODULE=fcitx' "$XSESSIONRC"
    assert_contains 'export QT_IM_MODULE=fcitx' "$XSESSIONRC"
    assert_contains 'export XMODIFIERS=@im=fcitx' "$XSESSIONRC"
    # DPMS off: MediaTek aarch64 eDP fails to re-light after DPMS cycle.
    assert_contains 'xset -dpms' "$XSESSIONRC"
    assert_contains 'xset s off' "$XSESSIONRC"
}

test_xsessionrc_runs_xinitrc_d() {
    # Standard Xsession contract: source every executable in /etc/X11/xinit/xinitrc.d/.
    assert_contains '/etc/X11/xinit/xinitrc.d' "$XSESSIONRC"
    assert_contains '[ -x "$i" ] && . "$i"' "$XSESSIONRC"
}

test_cursor_files_document_target_dpi() {
    # Each cursor file documents which platform/arch it targets so install.sh
    # can pick the right one without inferring from dpi alone.
    assert_contains 'standard DPI' "$CURSOR_1X"
    assert_contains 'ubuntu_amd64' "$CURSOR_1X"
    assert_contains '2x HiDPI' "$CURSOR_2X"
    assert_contains 'arch_x64' "$CURSOR_2X"
    assert_contains 'ubuntu_aarch64' "$CURSOR_2X"
}

test_xresources_contain_dpi_and_antialiasing
test_xresources_dpi_matches_cursor_size_contract
test_xresources_define_color_palette
test_xsessionrc_sources_cursor_and_xresources
test_xsessionrc_runs_xinitrc_d
test_cursor_files_document_target_dpi

printf 'PASS: x11 config tests\n'
