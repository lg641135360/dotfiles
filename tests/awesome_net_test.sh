#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CONFIG_FILE=$REPO_ROOT/.config/linux/awesome/config.lua

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

test_ubuntu_pattern_includes_wlp_interfaces() {
    grep -F 'or "wlan0|eth0|enp|wlp",' "$CONFIG_FILE" >/dev/null 2>&1 ||
        fail "expected Ubuntu net interface pattern to include wlp"
}

test_ubuntu_pattern_includes_wlp_interfaces

printf 'PASS: awesome net tests\n'
