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

assert_contains() {
    needle=$1
    file=$2

    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        fail "expected '$needle' in $file"
    fi
}

link_cmd() {
    cmd=$1
    target_dir=$2
    ln -s "$(command -v "$cmd")" "$target_dir/$cmd"
}

test_install_warns_when_redshift_missing_on_ubuntu() {
    if [ ! -f /etc/os-release ] || ! grep -q '^ID=ubuntu$' /etc/os-release; then
        printf 'SKIP: redshift install warning test requires Ubuntu\n'
        return 0
    fi

    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin
    output_file=$tmpdir/install.output
    sudo_log=$tmpdir/sudo.log

    mkdir -p "$home_dir" "$bin_dir"

    for cmd in bash basename cp date diff dirname find grep head ln mkdir mv pwd rm sed sort tail uname; do
        link_cmd "$cmd" "$bin_dir"
    done

    cat >"$bin_dir/dpkg" <<'EOF'
#!/bin/sh
if [ "$1" = "-l" ] && [ "$2" = "redshift" ]; then
    exit 0
fi

exit 1
EOF
    chmod +x "$bin_dir/dpkg"

    cat >"$bin_dir/sudo" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >"$SUDO_LOG"
exit 99
EOF
    chmod +x "$bin_dir/sudo"

    PATH=$bin_dir HOME=$home_dir SUDO_LOG=$sudo_log /bin/bash "$REPO_ROOT/install.sh" >"$output_file" 2>&1 ||
        fail "install.sh should succeed and only warn when redshift is missing"

    assert_file_exists "$output_file"
    assert_contains "redshift" "$output_file"
    assert_contains "Please install it manually" "$output_file"

    if [ -e "$sudo_log" ]; then
        fail "install.sh should not invoke sudo for redshift installation"
    fi

    rm -rf "$tmpdir"
}

test_install_warns_when_redshift_missing_on_ubuntu

printf 'PASS: install redshift tests\n'
