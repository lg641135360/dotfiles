#!/bin/bash
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"
. "$REPO_ROOT/install.sh"

ZDOTDIR_EXPORT='export ZDOTDIR=$HOME/.config/zsh'

test_ensure_zdotdir_preserves_existing_zshenv() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    zshenv=$home_dir/.zshenv

    mkdir -p "$home_dir"
    printf 'export PATH=$HOME/bin:$PATH\n' >"$zshenv"

    HOME=$home_dir ensure_zdotdir

    assert_contains 'export PATH=$HOME/bin:$PATH' "$zshenv"
    assert_contains "$ZDOTDIR_EXPORT" "$zshenv"

    rm -rf "$tmpdir"
}

test_ensure_zdotdir_skips_existing_export() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    zshenv=$home_dir/.zshenv

    mkdir -p "$home_dir"
    printf '%s\n' "$ZDOTDIR_EXPORT" >"$zshenv"

    HOME=$home_dir ensure_zdotdir
    HOME=$home_dir ensure_zdotdir

    count=$(grep -Fxc -- "$ZDOTDIR_EXPORT" "$zshenv")
    assert_equals 1 "$count"

    rm -rf "$tmpdir"
}

test_install_invokes_zdotdir_setup_with_zsh() {
    assert_contains 'ensure_zdotdir' "$REPO_ROOT/install.sh"
}

test_ensure_zdotdir_preserves_existing_zshenv
test_ensure_zdotdir_skips_existing_export
test_install_invokes_zdotdir_setup_with_zsh

printf 'PASS: install zshenv tests\n'
