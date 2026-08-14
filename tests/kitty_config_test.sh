#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"
KITTY_FILE=$REPO_ROOT/.config/linux/kitty/kitty.conf
ALACRITTY_MAIN=$REPO_ROOT/.config/shared/alacritty/alacritty.toml
ALACRITTY_WINDOW=$REPO_ROOT/.config/shared/alacritty/window.linux.toml
ALACRITTY_KEYS=$REPO_ROOT/.config/shared/alacritty/keys.linux.toml
INSTALL_FILE=$REPO_ROOT/install.sh
TERMINAL_SCRIPT=$REPO_ROOT/.config/scripts/terminal-wayland

test_font_matches_alacritty() {
    assert_contains 'MesloLGS Nerd Font Mono' "$KITTY_FILE"
    assert_contains 'font_size            13.0' "$KITTY_FILE"
    assert_contains 'size = 13' "$ALACRITTY_MAIN"
}

test_window_matches_alacritty() {
    assert_contains 'hide_window_decorations  yes' "$KITTY_FILE"
    assert_contains 'window_padding_width     12' "$KITTY_FILE"
    # 有意差异：aarch64 mtgpu 驱动对 0.82 半透明背景 alpha 合成有 bug，会渲染成
    # 全透明，故 kitty 用 1.0（完全不透）走不透明路径；alacritty 仍为 0.82。
    assert_contains 'background_opacity       1.0' "$KITTY_FILE"
    assert_contains 'decorations = "none"' "$ALACRITTY_WINDOW"
    assert_contains 'opacity = 0.82' "$ALACRITTY_WINDOW"
    assert_contains 'padding = { x = 12, y = 12 }' "$ALACRITTY_WINDOW"
}

test_mouse_hides_while_typing() {
    # kitty 0.32.2 默认 mouse_hide_wait=0.0（不隐藏），alacritty 的
    # hide_when_typing=true 行为需显式 mouse_hide_wait -3 才能对齐。
    assert_contains 'mouse_hide_wait -3' "$KITTY_FILE"
}

test_catppuccin_mocha_palette() {
    assert_contains 'background            #1e1e2e' "$KITTY_FILE"
    assert_contains 'foreground            #cdd6f4' "$KITTY_FILE"
    assert_contains 'color1  #f38ba8' "$KITTY_FILE"
    assert_contains 'color2  #a6e3a1' "$KITTY_FILE"
    assert_contains 'color4  #89b4fa' "$KITTY_FILE"
}

test_keys_mirror_alacritty() {
    assert_contains 'map alt+h send_text all \x01h' "$KITTY_FILE"
    assert_contains 'map alt+j send_text all \x01j' "$KITTY_FILE"
    assert_contains 'map alt+k send_text all \x01k' "$KITTY_FILE"
    assert_contains 'map alt+l send_text all \x01l' "$KITTY_FILE"
    assert_contains 'map alt+left  send_text all \x1b[1;3D' "$KITTY_FILE"
    assert_contains 'map alt+right send_text all \x1b[1;3C' "$KITTY_FILE"
    assert_contains 'map shift+alt+up   send_text all \x1b[1;4A' "$KITTY_FILE"
    assert_contains 'map shift+alt+down send_text all \x1b[1;4B' "$KITTY_FILE"

    assert_contains 'key = "H", mods = "Alt"' "$ALACRITTY_KEYS"
    assert_contains 'key = "Left", mods = "Alt"' "$ALACRITTY_KEYS"
    assert_contains 'key = "Up", mods = "Shift|Alt"' "$ALACRITTY_KEYS"
}

test_installed_in_wayland_dir_configs() {
    assert_contains 'command -v kitty|.config/linux/kitty|~/.config/kitty|Kitty' "$INSTALL_FILE"
}

test_terminal_wayland_falls_back_to_kitty() {
    # 全平台优先 Alacritty，kitty 仅作最后兜底（普通冷启动，无 socket/远程控制）。
    assert_not_contains 'uname -m' "$TERMINAL_SCRIPT"
    assert_contains 'exec kitty "$@"' "$TERMINAL_SCRIPT"
    assert_not_contains 'allow_remote_control' "$KITTY_FILE"
    assert_not_contains 'kitty @ --to' "$TERMINAL_SCRIPT"
    assert_not_contains '--listen-on' "$TERMINAL_SCRIPT"
}

test_font_matches_alacritty
test_window_matches_alacritty
test_mouse_hides_while_typing
test_catppuccin_mocha_palette
test_keys_mirror_alacritty
test_installed_in_wayland_dir_configs
test_terminal_wayland_falls_back_to_kitty

printf 'PASS: kitty config tests\n'
