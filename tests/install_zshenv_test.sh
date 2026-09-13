#!/bin/bash
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"
. "$REPO_ROOT/install.sh"

ZDOTDIR_EXPORT='export ZDOTDIR=$HOME/.config/zsh'
SKIP_COMPINIT='skip_global_compinit=1'

test_ensure_zdotdir_preserves_existing_zshenv() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    zshenv=$home_dir/.zshenv

    mkdir -p "$home_dir"
    printf 'export PATH=$HOME/bin:$PATH\n' >"$zshenv"

    HOME=$home_dir ensure_zdotdir

    assert_contains 'export PATH=$HOME/bin:$PATH' "$zshenv"
    assert_contains "$ZDOTDIR_EXPORT" "$zshenv"
    assert_contains "$SKIP_COMPINIT" "$zshenv"

    rm -rf "$tmpdir"
}

test_ensure_zdotdir_skips_existing_export() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    zshenv=$home_dir/.zshenv

    mkdir -p "$home_dir"
    printf '%s\n%s\n' "$ZDOTDIR_EXPORT" "$SKIP_COMPINIT" >"$zshenv"

    HOME=$home_dir ensure_zdotdir
    HOME=$home_dir ensure_zdotdir

    count=$(grep -Fxc -- "$ZDOTDIR_EXPORT" "$zshenv")
    assert_equals 1 "$count"
    count=$(grep -Fxc -- "$SKIP_COMPINIT" "$zshenv")
    assert_equals 1 "$count"

    rm -rf "$tmpdir"
}

# 回归：2026-09-13 前 live ~/.zshenv 只有 ZDOTDIR 一行，缺少
# skip_global_compinit 时 Ubuntu /etc/zsh/zshrc 的全局 compinit 每次交互
# 启动都与 plugins.zsh 互踢 dump（aarch64 实测 +3.9s）。ensure_zdotdir
# 必须给已有的单行 ~/.zshenv 补上 skip 行。
test_ensure_zdotdir_backfills_skip_global_compinit() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    zshenv=$home_dir/.zshenv

    mkdir -p "$home_dir"
    printf '%s\n' "$ZDOTDIR_EXPORT" >"$zshenv"

    HOME=$home_dir ensure_zdotdir

    assert_contains "$SKIP_COMPINIT" "$zshenv"
    count=$(grep -Fxc -- "$ZDOTDIR_EXPORT" "$zshenv")
    assert_equals 1 "$count"

    rm -rf "$tmpdir"
}

test_install_invokes_zdotdir_setup_with_zsh() {
    assert_contains 'ensure_zdotdir' "$REPO_ROOT/install.sh"
}

test_ensure_zdotdir_preserves_existing_zshenv
test_ensure_zdotdir_skips_existing_export
test_ensure_zdotdir_backfills_skip_global_compinit
test_install_invokes_zdotdir_setup_with_zsh

printf 'PASS: install zshenv tests\n'
