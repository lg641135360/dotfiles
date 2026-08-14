#!/bin/bash
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

# Verify copy_config refuses to clobber target with an empty source dir
# (guards against uninitialized git submodules such as nvim).
test_copy_config_rejects_empty_source_dir() {
    tmpdir=$(mktemp -d)
    src_dir=$tmpdir/empty-src
    target=$tmpdir/target

    mkdir -p "$src_dir" "$target"
    printf 'existing\n' >"$target/existing.txt"

    # shellcheck disable=SC1090
    . "$REPO_ROOT/install.sh"

    # copy_config should fail (return non-zero) for an empty source dir.
    if copy_config "$src_dir" "$target" "empty test" 2>/dev/null; then
        fail "copy_config should reject empty source directory"
    fi

    # Target must be untouched (no backup created, original file intact).
    assert_file_exists "$target/existing.txt"
    assert_contains 'existing' "$target/existing.txt"

    rm -rf "$tmpdir"
}

# Verify copy_config succeeds for a non-empty source dir (sanity check).
test_copy_config_accepts_non_empty_source_dir() {
    tmpdir=$(mktemp -d)
    src_dir=$tmpdir/src
    target=$tmpdir/target

    mkdir -p "$src_dir"
    printf 'content\n' >"$src_dir/file.txt"

    # shellcheck disable=SC1090
    . "$REPO_ROOT/install.sh"

    copy_config "$src_dir" "$target" "non-empty test" 2>/dev/null ||
        fail "copy_config should accept non-empty source directory"

    assert_file_exists "$target/file.txt"

    rm -rf "$tmpdir"
}

test_install_sh_has_submodule_guard() {
    assert_contains 'submodule status' "$REPO_ROOT/install.sh"
    assert_contains 'submodule is empty' "$REPO_ROOT/install.sh"
}

test_copy_config_rejects_empty_source_dir
test_copy_config_accepts_non_empty_source_dir
test_install_sh_has_submodule_guard

printf 'PASS: install submodule tests\n'
