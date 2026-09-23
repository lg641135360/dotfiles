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

# ensure_zdotdir 直接改 live ~/.zshenv，必须与 copy_config 一致先做时间戳备份，
# 否则改坏了 zsh 启动没有回退入口。
test_ensure_zdotdir_backs_up_before_modifying() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    zshenv=$home_dir/.zshenv

    mkdir -p "$home_dir"
    printf 'export PATH=$HOME/bin:$PATH\n' >"$zshenv"

    HOME=$home_dir ensure_zdotdir

    backup_count=$(find "$home_dir" -maxdepth 1 -name '.zshenv.backup.*' | wc -l)
    assert_equals 1 "$backup_count"
    backup_file=$(find "$home_dir" -maxdepth 1 -name '.zshenv.backup.*')
    assert_contains 'export PATH=$HOME/bin:$PATH' "$backup_file"

    # A second run has nothing to add and must not create another backup.
    HOME=$home_dir ensure_zdotdir
    backup_count=$(find "$home_dir" -maxdepth 1 -name '.zshenv.backup.*' | wc -l)
    assert_equals 1 "$backup_count"

    rm -rf "$tmpdir"
}

test_ensure_zdotdir_does_not_back_up_when_already_configured() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    zshenv=$home_dir/.zshenv

    mkdir -p "$home_dir"
    printf '%s\n%s\n' "$ZDOTDIR_EXPORT" "$SKIP_COMPINIT" >"$zshenv"

    HOME=$home_dir ensure_zdotdir

    backup_count=$(find "$home_dir" -maxdepth 1 -name '.zshenv.backup.*' | wc -l)
    assert_equals 0 "$backup_count"

    rm -rf "$tmpdir"
}

test_ensure_zdotdir_creates_zshenv_without_backup_when_missing() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    zshenv=$home_dir/.zshenv

    mkdir -p "$home_dir"

    HOME=$home_dir ensure_zdotdir

    assert_file_exists "$zshenv"
    assert_contains "$ZDOTDIR_EXPORT" "$zshenv"
    assert_contains "$SKIP_COMPINIT" "$zshenv"
    backup_count=$(find "$home_dir" -maxdepth 1 -name '.zshenv.backup.*' | wc -l)
    assert_equals 0 "$backup_count"

    rm -rf "$tmpdir"
}

test_ensure_zdotdir_preserves_existing_zshenv
test_ensure_zdotdir_skips_existing_export
test_ensure_zdotdir_backfills_skip_global_compinit
test_ensure_zdotdir_backs_up_before_modifying
test_ensure_zdotdir_does_not_back_up_when_already_configured
test_ensure_zdotdir_creates_zshenv_without_backup_when_missing
test_install_invokes_zdotdir_setup_with_zsh

printf 'PASS: install zshenv tests\n'
