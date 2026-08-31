#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"
FOOT_FILE=$REPO_ROOT/.config/linux/foot/foot.ini
ALACRITTY_MAIN=$REPO_ROOT/.config/shared/alacritty/alacritty.toml
ALACRITTY_WINDOW=$REPO_ROOT/.config/shared/alacritty/window.linux.toml
ALACRITTY_KEYS=$REPO_ROOT/.config/shared/alacritty/keys.linux.toml
INSTALL_FILE=$REPO_ROOT/install.sh
TERMINAL_SCRIPT=$REPO_ROOT/.config/scripts/terminal-wayland

test_font_matches_alacritty() {
    # foot 在 aarch64 HiDPI 内屏 2x 下用 12（比 alacritty 的 13 略小，更紧凑）；
    # 其他平台 alacritty 仍用 13。font-* 必须显式带 :size，foot 不继承 font 的 size。
    assert_contains 'MesloLGS Nerd Font Mono:size=12' "$FOOT_FILE"
    assert_contains 'font-bold=MesloLGS Nerd Font Mono:weight=bold:size=12' "$FOOT_FILE"
    assert_contains 'font-italic=MesloLGS Nerd Font Mono:slant=italic:size=12' "$FOOT_FILE"
    assert_contains 'font-bold-italic=MesloLGS Nerd Font Mono:weight=bold:slant=italic:size=12' "$FOOT_FILE"
    assert_contains 'size = 13' "$ALACRITTY_MAIN"
}

test_window_matches_alacritty() {
    # csd.preferred=none mirrors alacritty decorations="none"; pad=12x12 mirrors
    # padding={x=12,y=12}; colors.alpha=0.82 mirrors opacity=0.82.
    assert_contains 'preferred=none' "$FOOT_FILE"
    assert_contains 'pad=12x12' "$FOOT_FILE"
    assert_contains 'alpha=0.82' "$FOOT_FILE"
    assert_contains 'decorations = "none"' "$ALACRITTY_WINDOW"
    assert_contains 'opacity = 0.82' "$ALACRITTY_WINDOW"
    assert_contains 'padding = { x = 12, y = 12 }' "$ALACRITTY_WINDOW"
}

test_mouse_hides_while_typing() {
    # foot default hide-when-typing=no, must set yes to mirror alacritty.
    assert_contains 'hide-when-typing=yes' "$FOOT_FILE"
}

test_cursor_is_blinking_beam() {
    assert_contains 'style=beam' "$FOOT_FILE"
    assert_contains 'blink=yes' "$FOOT_FILE"
    # foot 1.25 起 colors.cursor 取代废弃的 cursor.color（text 在前 cursor 在后）。
    assert_contains 'cursor=1e1e2e f5e0dc' "$FOOT_FILE"
    assert_not_contains 'color=1e1e2e f5e0dc' "$FOOT_FILE"
}

test_term_uses_xterm_256color() {
    # 与 alacritty 一致使用 xterm-256color，避免 SSH 远端缺少 foot terminfo。
    assert_contains 'term=xterm-256color' "$FOOT_FILE"
    assert_contains 'TERM = "xterm-256color"' "$ALACRITTY_MAIN"
}

test_scrollback_matches_alacritty() {
    assert_contains 'lines=50000' "$FOOT_FILE"
    assert_contains 'multiplier=3.0' "$FOOT_FILE"
}

test_catppuccin_mocha_palette() {
    assert_contains 'background=1e1e2e' "$FOOT_FILE"
    assert_contains 'foreground=cdd6f4' "$FOOT_FILE"
    assert_contains 'regular1=f38ba8' "$FOOT_FILE"
    assert_contains 'regular2=a6e3a1' "$FOOT_FILE"
    assert_contains 'regular4=89b4fa' "$FOOT_FILE"
    assert_contains 'bright0=585b70' "$FOOT_FILE"
    assert_contains '16=fab387' "$FOOT_FILE"
    assert_contains '17=f5c2e7' "$FOOT_FILE"
}

test_keys_mirror_alacritty() {
    # text-bindings: \x01 = Ctrl-a, \x1b = ESC. foot 要求 modifier 用 XKB 名称，
    # Alt 对应 Mod1，不能用 "Alt" 字面量。
    assert_contains '\x01h = Mod1+h' "$FOOT_FILE"
    assert_contains '\x01j = Mod1+j' "$FOOT_FILE"
    assert_contains '\x01k = Mod1+k' "$FOOT_FILE"
    assert_contains '\x01l = Mod1+l' "$FOOT_FILE"
    assert_contains '\x1b[1;3D = Mod1+Left' "$FOOT_FILE"
    assert_contains '\x1b[1;3C = Mod1+Right' "$FOOT_FILE"
    assert_contains '\x1b[1;3A = Mod1+Up' "$FOOT_FILE"
    assert_contains '\x1b[1;3B = Mod1+Down' "$FOOT_FILE"
    assert_contains '\x1b[1;4A = Shift+Mod1+Up' "$FOOT_FILE"
    assert_contains '\x1b[1;4B = Shift+Mod1+Down' "$FOOT_FILE"

    assert_contains 'key = "H", mods = "Alt"' "$ALACRITTY_KEYS"
    assert_contains 'key = "Left", mods = "Alt"' "$ALACRITTY_KEYS"
    assert_contains 'key = "Up", mods = "Shift|Alt"' "$ALACRITTY_KEYS"
}

test_installed_in_wayland_dir_configs() {
    assert_contains 'command -v foot|.config/linux/foot|~/.config/foot|Foot' "$INSTALL_FILE"
}

test_terminal_wayland_prefers_foot() {
    # niri/Wayland 默认终端统一为 foot（2026-08-31 起含 x86_64），alacritty 仅兜底。
    assert_not_contains 'exec kitty "$@"' "$TERMINAL_SCRIPT"
    assert_contains 'exec foot "$@"' "$TERMINAL_SCRIPT"
    assert_contains 'exec alacritty "$@"' "$TERMINAL_SCRIPT"
}

test_font_matches_alacritty
test_window_matches_alacritty
test_mouse_hides_while_typing
test_cursor_is_blinking_beam
test_term_uses_xterm_256color
test_scrollback_matches_alacritty
test_catppuccin_mocha_palette
test_keys_mirror_alacritty
test_installed_in_wayland_dir_configs
test_terminal_wayland_prefers_foot

printf 'PASS: foot config tests\n'
