#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

FUZZEL_CONFIG=$REPO_ROOT/.config/linux/fuzzel/fuzzel.ini

test_fuzzel_config_matches_wayland_launcher_contract() {
    assert_file_exists "$FUZZEL_CONFIG"
    assert_contains 'font=Noto Sans CJK SC:size=13' "$FUZZEL_CONFIG"
    assert_contains 'terminal=~/.config/scripts/terminal-wayland' "$FUZZEL_CONFIG"
    assert_contains 'prompt=应用 >' "$FUZZEL_CONFIG"
    assert_contains 'width=58' "$FUZZEL_CONFIG"
    assert_contains 'line-height=28' "$FUZZEL_CONFIG"
    assert_contains 'filter-desktop=yes' "$FUZZEL_CONFIG"
    assert_contains 'background=15161dee' "$FUZZEL_CONFIG"
    assert_contains 'selection=89b4faff' "$FUZZEL_CONFIG"
    assert_contains 'selection-text=1e1e2eff' "$FUZZEL_CONFIG"
    assert_contains 'border=94e2d5ff' "$FUZZEL_CONFIG"
    assert_contains 'icon-theme=Papirus-Dark' "$FUZZEL_CONFIG"

    # Ubuntu Noble ships fuzzel 1.9.2, which predates these options (added in
    # 1.11: placeholder/use-bold/keyboard-focus/match-mode/match-counter and the
    # colors.prompt/placeholder/input/counter keys). They must NOT be present or
    # fuzzel rejects the whole config with "not a valid option".
    assert_not_contains 'placeholder=输入应用名或命令' "$FUZZEL_CONFIG"
    assert_not_contains 'use-bold' "$FUZZEL_CONFIG"
    assert_not_contains 'keyboard-focus' "$FUZZEL_CONFIG"
    assert_not_contains 'match-mode' "$FUZZEL_CONFIG"
    assert_not_contains 'match-counter' "$FUZZEL_CONFIG"
    assert_not_contains 'selection-radius' "$FUZZEL_CONFIG"
    assert_not_contains 'counter=' "$FUZZEL_CONFIG"
    assert_not_contains 'input=' "$FUZZEL_CONFIG"
    assert_not_contains 'prompt=94e2d5ff' "$FUZZEL_CONFIG"
}

test_fuzzel_config_matches_wayland_launcher_contract

printf 'PASS: fuzzel config tests\n'
