#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

SSH_CONFIG=$REPO_ROOT/.config/shared/ssh/config

test_ssh_config_exists_and_has_global_options() {
    assert_file_exists "$SSH_CONFIG"
    # AddKeysToAgent yes: avoids re-typing passphrase on every git push.
    assert_contains 'AddKeysToAgent yes' "$SSH_CONFIG"
    # ServerAliveInterval 60 + CountMax 3: detect dead SSH connection within
    # ~3 minutes (vs TCP default ~2 hours), so muxed git over SSH fails fast.
    assert_contains 'ServerAliveInterval 60' "$SSH_CONFIG"
    assert_contains 'ServerAliveCountMax 3' "$SSH_CONFIG"
}

# `ssh -G` prints the effective config that ssh would use, including the
# global options from -F. Exits non-zero on syntax errors (malformed
# directives, unknown options). Skipped on hosts without an ssh client.
test_ssh_config_parses_with_ssh_G() {
    skip_unless ssh || return $?
    ssh -F "$SSH_CONFIG" -G example.com >/dev/null 2>&1 ||
        fail "ssh -G rejected $SSH_CONFIG (syntax error?)"
}

test_ssh_config_exists_and_has_global_options
test_ssh_config_parses_with_ssh_G

printf 'PASS: ssh config tests\n'
