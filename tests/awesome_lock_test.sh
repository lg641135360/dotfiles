#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_file_exists() {
    [ -e "$1" ] || fail "expected file to exist: $1"
}

assert_not_contains() {
    needle=$1
    file=$2

    if grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        fail "did not expect '$needle' in $file"
    fi
}

link_cmd() {
    cmd=$1
    target_dir=$2
    ln -s "$(command -v "$cmd")" "$target_dir/$cmd"
}

test_install_copies_lock_script_without_i3lock() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin

    mkdir -p "$home_dir" "$bin_dir"

    for cmd in bash basename cp date diff dirname find grep head ln mkdir mv pwd rm sed sort tail uname; do
        link_cmd "$cmd" "$bin_dir"
    done

    cat >"$bin_dir/awesome" <<'EOF'
#!/bin/sh
exit 0
EOF
    chmod +x "$bin_dir/awesome"

    PATH=$bin_dir HOME=$home_dir /bin/bash "$REPO_ROOT/install.sh" >/dev/null 2>&1 ||
        fail "install.sh should succeed without i3lock in PATH"

    assert_file_exists "$home_dir/.config/scripts/lock"
    [ -x "$home_dir/.config/scripts/lock" ] ||
        fail "expected installed lock script to be executable"

    rm -rf "$tmpdir"
}

test_install_repairs_lock_script_exec_bit() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin

    mkdir -p "$home_dir" "$bin_dir"

    for cmd in bash basename cp date diff dirname find grep head ln mkdir mv pwd rm sed sort tail uname; do
        link_cmd "$cmd" "$bin_dir"
    done

    cat >"$bin_dir/awesome" <<'EOF'
#!/bin/sh
exit 0
EOF
    chmod +x "$bin_dir/awesome"

    PATH=$bin_dir HOME=$home_dir /bin/bash "$REPO_ROOT/install.sh" >/dev/null 2>&1 ||
        fail "initial install.sh run should succeed"

    chmod 644 "$home_dir/.config/scripts/lock"

    PATH=$bin_dir HOME=$home_dir /bin/bash "$REPO_ROOT/install.sh" >/dev/null 2>&1 ||
        fail "second install.sh run should succeed"

    [ -x "$home_dir/.config/scripts/lock" ] ||
        fail "expected reinstall to restore executable bit on lock script"

    rm -rf "$tmpdir"
}

test_lock_script_falls_back_to_plain_i3lock() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    args_log=$tmpdir/i3lock.args

    mkdir -p "$bin_dir"

    cat >"$bin_dir/i3lock" <<'EOF'
#!/bin/sh
for arg in "$@"; do
    if [ "$arg" = "--blur" ]; then
        echo "plain i3lock does not support --blur" >&2
        exit 64
    fi
done

printf '%s\n' "$@" >"$LOCK_ARGS_LOG"
EOF
    chmod +x "$bin_dir/i3lock"

    PATH=$bin_dir LOCK_ARGS_LOG=$args_log /bin/sh "$REPO_ROOT/.config/scripts/lock" >/dev/null 2>&1 ||
        fail "lock script should succeed with only plain i3lock available"

    assert_file_exists "$args_log"
    assert_not_contains "--blur" "$args_log"

    rm -rf "$tmpdir"
}

test_install_copies_lock_script_without_i3lock
test_install_repairs_lock_script_exec_bit
test_lock_script_falls_back_to_plain_i3lock

printf 'PASS: awesome lock tests\n'
