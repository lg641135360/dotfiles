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
    assert_contains "-n" "$args_log"
    assert_contains "-e" "$args_log"
    assert_contains "-f" "$args_log"
    assert_contains "-c" "$args_log"
    assert_contains "11111b" "$args_log"

    rm -rf "$tmpdir"
}

test_lock_script_plain_i3lock_uses_generated_theme_image() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    home_dir=$tmpdir/home
    cache_dir=$tmpdir/cache
    args_log=$tmpdir/i3lock.args
    python_log=$tmpdir/python.args
    expected_image=$cache_dir/lock/i3lock-catppuccin-1280x720-1280x720+0+0.png

    mkdir -p "$bin_dir" "$home_dir" "$cache_dir"

    for cmd in awk mkdir mv rm; do
        link_cmd "$cmd" "$bin_dir"
    done

    cat >"$bin_dir/xdpyinfo" <<'EOF'
#!/bin/sh
printf '%s\n' '  dimensions:    1280x720 pixels (338x190 millimeters)'
EOF
    chmod +x "$bin_dir/xdpyinfo"

    cat >"$bin_dir/python3" <<'EOF'
#!/bin/sh
[ "${1:-}" = "-" ] || exit 65
printf '%s\n' "$@" >"$PYTHON_ARGS_LOG"
printf '%s\n' 'fake png' >"$4"
EOF
    chmod +x "$bin_dir/python3"

    cat >"$bin_dir/i3lock" <<'EOF'
#!/bin/sh
if [ "${1:-}" = "--help" ]; then
    printf '%s\n' 'plain i3lock help'
    exit 0
fi

printf '%s\n' "$@" >"$LOCK_ARGS_LOG"
EOF
    chmod +x "$bin_dir/i3lock"

    PATH=$bin_dir HOME=$home_dir XDG_CACHE_HOME=$cache_dir \
        LOCK_ARGS_LOG=$args_log PYTHON_ARGS_LOG=$python_log \
        /bin/sh "$REPO_ROOT/.config/scripts/lock" >/dev/null 2>&1 ||
        fail "plain i3lock should use generated themed image when python3 is available"

    assert_file_exists "$expected_image"
    assert_contains "1280" "$python_log"
    assert_contains "720" "$python_log"
    assert_contains "$expected_image.tmp." "$python_log"
    assert_contains "1280x720+0+0" "$python_log"
    assert_contains "-i" "$args_log"
    assert_contains "$expected_image" "$args_log"
    assert_contains "-c" "$args_log"
    assert_contains "11111b" "$args_log"
    assert_not_contains "--blur" "$args_log"

    rm -rf "$tmpdir"
}

test_lock_script_plain_i3lock_draws_theme_on_each_xrandr_output() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    home_dir=$tmpdir/home
    cache_dir=$tmpdir/cache
    args_log=$tmpdir/i3lock.args
    python_log=$tmpdir/python.args
    expected_image=$cache_dir/lock/i3lock-catppuccin-5120x1440-2560x1440+0+0_2560x1440+2560+0.png

    mkdir -p "$bin_dir" "$home_dir" "$cache_dir"

    for cmd in awk mkdir mv rm; do
        link_cmd "$cmd" "$bin_dir"
    done

    cat >"$bin_dir/xrandr" <<'EOF'
#!/bin/sh
printf '%s\n' \
    'Screen 0: minimum 320 x 200, current 5120 x 1440, maximum 16384 x 16384' \
    'DP-4 connected primary 2560x1440+0+0 (normal left inverted right x axis y axis) 527mm x 296mm' \
    'HDMI-3 connected 2560x1440+2560+0 (normal left inverted right x axis y axis) 527mm x 296mm' \
    'HDMI-2 disconnected (normal left inverted right x axis y axis)'
EOF
    chmod +x "$bin_dir/xrandr"

    cat >"$bin_dir/python3" <<'EOF'
#!/bin/sh
[ "${1:-}" = "-" ] || exit 65
printf '%s\n' "$@" >"$PYTHON_ARGS_LOG"
printf '%s\n' 'fake png' >"$4"
EOF
    chmod +x "$bin_dir/python3"

    cat >"$bin_dir/i3lock" <<'EOF'
#!/bin/sh
if [ "${1:-}" = "--help" ]; then
    printf '%s\n' 'plain i3lock help'
    exit 0
fi

printf '%s\n' "$@" >"$LOCK_ARGS_LOG"
EOF
    chmod +x "$bin_dir/i3lock"

    PATH=$bin_dir HOME=$home_dir XDG_CACHE_HOME=$cache_dir \
        LOCK_ARGS_LOG=$args_log PYTHON_ARGS_LOG=$python_log \
        /bin/sh "$REPO_ROOT/.config/scripts/lock" >/dev/null 2>&1 ||
        fail "plain i3lock should pass each xrandr output to the theme generator"

    assert_file_exists "$expected_image"
    assert_contains "5120" "$python_log"
    assert_contains "1440" "$python_log"
    assert_contains "2560x1440+0+0" "$python_log"
    assert_contains "2560x1440+2560+0" "$python_log"
    assert_contains "-i" "$args_log"
    assert_contains "$expected_image" "$args_log"

    rm -rf "$tmpdir"
}

test_lock_script_plain_i3lock_falls_back_to_color_when_theme_generation_fails() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    home_dir=$tmpdir/home
    cache_dir=$tmpdir/cache
    args_log=$tmpdir/i3lock.args

    mkdir -p "$bin_dir" "$home_dir" "$cache_dir"

    for cmd in awk mkdir rm; do
        link_cmd "$cmd" "$bin_dir"
    done

    cat >"$bin_dir/xdpyinfo" <<'EOF'
#!/bin/sh
printf '%s\n' '  dimensions:    1280x720 pixels (338x190 millimeters)'
EOF
    chmod +x "$bin_dir/xdpyinfo"

    cat >"$bin_dir/python3" <<'EOF'
#!/bin/sh
exit 42
EOF
    chmod +x "$bin_dir/python3"

    cat >"$bin_dir/i3lock" <<'EOF'
#!/bin/sh
if [ "${1:-}" = "--help" ]; then
    printf '%s\n' 'plain i3lock help'
    exit 0
fi

printf '%s\n' "$@" >"$LOCK_ARGS_LOG"
EOF
    chmod +x "$bin_dir/i3lock"

    PATH=$bin_dir HOME=$home_dir XDG_CACHE_HOME=$cache_dir LOCK_ARGS_LOG=$args_log \
        /bin/sh "$REPO_ROOT/.config/scripts/lock" >/dev/null 2>&1 ||
        fail "plain i3lock should fall back to color when theme generation fails"

    assert_contains "-n" "$args_log"
    assert_contains "-e" "$args_log"
    assert_contains "-f" "$args_log"
    assert_not_contains "-i" "$args_log"
    assert_contains "-c" "$args_log"
    assert_contains "11111b" "$args_log"
    assert_not_contains "--blur" "$args_log"

    rm -rf "$tmpdir"
}

test_lock_script_prefers_i3lock_color_when_available() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    args_log=$tmpdir/i3lock-color.args

    mkdir -p "$bin_dir"

    cat >"$bin_dir/i3lock-color" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"$LOCK_ARGS_LOG"
EOF
    chmod +x "$bin_dir/i3lock-color"

    PATH=$bin_dir LOCK_ARGS_LOG=$args_log /bin/sh "$REPO_ROOT/.config/scripts/lock" >/dev/null 2>&1 ||
        fail "lock script should use i3lock-color when it is available"

    assert_file_exists "$args_log"
    assert_contains "--blur" "$args_log"
    assert_contains "--clock" "$args_log"
    assert_not_contains "--screen" "$args_log"

    rm -rf "$tmpdir"
}

test_lock_script_uses_blur_capable_i3lock_without_screen_pin() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    args_log=$tmpdir/i3lock.args

    mkdir -p "$bin_dir"

    cat >"$bin_dir/i3lock" <<'EOF'
#!/bin/sh
if [ "${1:-}" = "--help" ]; then
    printf '%s\n' "--blur --clock"
    exit 0
fi

printf '%s\n' "$@" >"$LOCK_ARGS_LOG"
EOF
    chmod +x "$bin_dir/i3lock"

    PATH=$bin_dir LOCK_ARGS_LOG=$args_log /bin/sh "$REPO_ROOT/.config/scripts/lock" >/dev/null 2>&1 ||
        fail "lock script should use blur-capable i3lock styling"

    assert_file_exists "$args_log"
    assert_contains "--blur" "$args_log"
    assert_contains "--clock" "$args_log"
    assert_not_contains "--screen" "$args_log"

    rm -rf "$tmpdir"
}

test_lock_script_tolerates_notify_send_failure_when_unavailable() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    stderr_file=$tmpdir/stderr.log

    mkdir -p "$bin_dir"

    cat >"$bin_dir/notify-send" <<'EOF'
#!/bin/sh
exit 1
EOF
    chmod +x "$bin_dir/notify-send"

    set +e
    PATH=$bin_dir /bin/sh "$REPO_ROOT/.config/scripts/lock" >/dev/null 2>"$stderr_file"
    status=$?
    set -e

    [ "$status" -eq 127 ] ||
        fail "lock script should exit 127 when no locker backend is available"
    assert_contains "Lock screen unavailable: install i3lock." "$stderr_file"

    rm -rf "$tmpdir"
}

test_install_copies_lock_script_without_i3lock
test_install_repairs_lock_script_exec_bit
test_lock_script_falls_back_to_plain_i3lock
test_lock_script_plain_i3lock_uses_generated_theme_image
test_lock_script_plain_i3lock_draws_theme_on_each_xrandr_output
test_lock_script_plain_i3lock_falls_back_to_color_when_theme_generation_fails
test_lock_script_prefers_i3lock_color_when_available
test_lock_script_uses_blur_capable_i3lock_without_screen_pin
test_lock_script_tolerates_notify_send_failure_when_unavailable

printf 'PASS: awesome lock tests\n'
