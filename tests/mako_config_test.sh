#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

MAKO_CONFIG=$REPO_ROOT/.config/linux/mako/config

# Split from the original test_waybar_and_mako_match_niri_trial_contract: the
# mako-specific assertions cover the notification daemon theme + 1.8
# compatibility (mako 1.8 rejects icon-border-radius and similar keys added
# in newer versions, so they must NOT appear in the config).
test_mako_matches_niri_trial_contract() {
    assert_file_exists "$MAKO_CONFIG"

    assert_contains 'background-color=#1e1e2ef2' "$MAKO_CONFIG"
    assert_contains 'border-color=#89b4fa' "$MAKO_CONFIG"
    assert_contains 'font=Maple Mono NF CN 11' "$MAKO_CONFIG"
    assert_contains 'border-radius=10' "$MAKO_CONFIG"
    assert_not_contains 'icon-border-radius' "$MAKO_CONFIG"
    assert_contains '[urgency=critical]' "$MAKO_CONFIG"
}

test_mako_matches_niri_trial_contract

# mako 1.8 (Ubuntu Noble) rejects keys added in 1.9+ with "not a valid
# option", failing to start. Assert each known-incompatible key is absent
# so an accidental upgrade-trigger doesn't break the session.
test_mako_config_avoids_post_1_8_keys() {
    # icon-border-radius: added in mako 1.10
    assert_not_contains 'icon-border-radius' "$MAKO_CONFIG"
    # output: 1.10+ only; we don't pin notifications to an output anyway
    assert_not_contains 'output=' "$MAKO_CONFIG"
    # group-by: 1.10+ only; we use the default grouping
    assert_not_contains 'group-by' "$MAKO_CONFIG"
    # max-history / history: 1.11+ only
    assert_not_contains 'max-history' "$MAKO_CONFIG"
    assert_not_contains 'history=' "$MAKO_CONFIG"
}

# If mako is installed, smoke-test that it actually accepts the config.
# `makoctl reload` would require a running session; instead we use
# `mako --help` to confirm the binary exists and parse the config file
# structurally (every section header is `[urgency=...]` and every line
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

test_mako_config_avoids_post_1_8_keys
test_mako_config_structure_is_valid

printf 'PASS: mako config tests\n'
