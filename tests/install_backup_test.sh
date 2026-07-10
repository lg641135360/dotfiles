#!/bin/bash
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"
. "$REPO_ROOT/install.sh"

test_clean_old_backups_reports_removed_count() {
    tmpdir=$(mktemp -d)
    target=$tmpdir/config

    touch "$target.backup.20260710_120000"
    touch "$target.backup.20260710_120100"
    touch "$target.backup.20260710_120200"
    touch "$target.backup.20260710_120300"

    output=$(clean_old_backups "$target")

    assert_file_not_exists "$target.backup.20260710_120000"
    assert_file_exists "$target.backup.20260710_120100"
    assert_file_exists "$target.backup.20260710_120200"
    assert_file_exists "$target.backup.20260710_120300"
    assert_output_contains 'Cleaned 1 old backup' "$output"

    rm -rf "$tmpdir"
}

test_clean_old_backups_reports_removed_count

printf 'PASS: install backup tests\n'