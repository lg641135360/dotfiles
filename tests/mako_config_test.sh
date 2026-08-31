#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

MAKO_CONFIG=$REPO_ROOT/.config/linux/mako/config

# Split from the original test_waybar_and_mako_match_niri_trial_contract: the
# mako-specific assertions cover the notification daemon theme contract.
test_mako_matches_niri_trial_contract() {
    assert_file_exists "$MAKO_CONFIG"

    assert_contains 'background-color=#1e1e2ef2' "$MAKO_CONFIG"
    assert_contains 'border-color=#89b4fa' "$MAKO_CONFIG"
    assert_contains 'font=Maple Mono NF CN 11' "$MAKO_CONFIG"
    assert_contains 'border-radius=10' "$MAKO_CONFIG"
    assert_contains '[urgency=critical]' "$MAKO_CONFIG"
}

test_mako_matches_niri_trial_contract

# mako 1.10 (Ubuntu 26.04 resolute) 支持 icon-border-radius / output /
# group-by / max-history / history（旧 1.8 兼容约束已随 Noble→26.04 迁移移除）。
# 本测试锁定：配置中每个 key=value 的键都必须落在 mako 1.10 支持的选项集合内，
# 防止手滑引入未知/拼写错误选项——mako 遇到未知选项会解析失败退出，导致
# org.freedesktop.Notifications 无服务提供者。
test_mako_config_keys_valid_for_1_10() {
    known="anchor actions background-color border-color border-radius border-size
default-timeout font height icons layer margin markup max-icon-size max-visible
outer-margin padding text-color width"
    invalid=$(awk -v k="$known" '
        /^[[:space:]]*$/ { next }
        /^\[/ { next }
        {
            split($0, a, "=")
            ok = 0
            n = split(k, keys, /[ \n]+/)
            for (i = 1; i <= n; i++) if (a[1] == keys[i]) ok = 1
            if (!ok) print NR ":" $0
        }
    ' "$MAKO_CONFIG")
    [ -z "$invalid" ] || fail "mako config 使用了 1.10 不支持的选项: $invalid"
}

# If mako is installed, smoke-test that it actually accepts the config.
# `makoctl reload` would require a running session; instead we parse the config
# file structurally (every section header is `[urgency=...]` and every line
# outside a section is `key=value`).
test_mako_config_structure_is_valid() {
    # Every non-empty, non-section line must be key=value.
    invalid=$(awk '
        /^[[:space:]]*$/ { next }
        /^\[urgency=/ { next }
        /^[^=]+=/ { next }
        { print NR ":" $0 }
    ' "$MAKO_CONFIG")
    [ -z "$invalid" ] || fail "mako config has non key=value lines: $invalid"
}

test_mako_config_keys_valid_for_1_10
test_mako_config_structure_is_valid

printf 'PASS: mako config tests\n'
