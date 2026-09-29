#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

DEFAULTS_SH=$REPO_ROOT/.config/macos/defaults.sh

# Stub `defaults`/`killall` so this runs on any host (Linux CI included) and
# never touches the real macOS preference store. The fake `defaults` keeps a
# `domain|key|value` state file and logs every write, so the test can assert
# what a re-run would actually change.
build_sandbox() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    home_dir=$tmpdir/home
    state=$tmpdir/state
    writes=$tmpdir/writes
    kills=$tmpdir/kills
    mkdir -p "$bin_dir" "$home_dir"
    : >"$state"
    : >"$writes"
    : >"$kills"

    cat >"$bin_dir/defaults" <<'EOF'
#!/bin/sh
set -eu
state=${FAKE_DEFAULTS_STATE:?}
writes=${FAKE_DEFAULTS_WRITES:?}
cmd=${1:-}
shift || true
case "$cmd" in
    read)
        domain=$1; key=$2
        awk -F'|' -v d="$domain" -v k="$key" \
            '$1==d && $2==k {print $3; found=1; exit} END {exit !found}' "$state"
        ;;
    write)
        domain=$1; key=$2; shift 2
        type=${1#-}; value=$2
        case "$type" in
            bool) case "$value" in true|1|YES|yes) value=1 ;; *) value=0 ;; esac ;;
        esac
        awk -F'|' -v d="$domain" -v k="$key" '!($1==d && $2==k)' "$state" >"$state.tmp"
        mv "$state.tmp" "$state"
        printf '%s|%s|%s\n' "$domain" "$key" "$value" >>"$state"
        printf '%s|%s|%s\n' "$domain" "$key" "$value" >>"$writes"
        ;;
    *)
        printf 'fake defaults: unsupported subcommand %s\n' "$cmd" >&2
        exit 2
        ;;
esac
EOF
    chmod +x "$bin_dir/defaults"

    cat >"$bin_dir/killall" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$FAKE_KILLALL_LOG"
exit 0
EOF
    chmod +x "$bin_dir/killall"
}

run_defaults() {
    PATH="$bin_dir:/usr/bin:/bin" \
    HOME="$home_dir" \
    FAKE_DEFAULTS_STATE="$state" \
    FAKE_DEFAULTS_WRITES="$writes" \
    FAKE_KILLALL_LOG="$kills" \
        /bin/bash "$DEFAULTS_SH" >/dev/null
}

test_first_run_writes_all_and_restarts_ui() {
    build_sandbox

    run_defaults

    [ -s "$writes" ] || fail "expected defaults writes on first run"
    [ -s "$kills" ] || fail "expected Finder/Dock restart on first run"

    rm -rf "$tmpdir"
}

# 回归：install.sh 每次运行都会调用 defaults.sh，重复应用偏好并 killall
# Finder/Dock 会无谓打断用户。第二次运行必须完全 no-op。
test_second_run_is_a_noop() {
    build_sandbox
    run_defaults

    : >"$writes"
    : >"$kills"
    run_defaults

    [ ! -s "$writes" ] || fail "expected no writes on second run, got:
$(cat "$writes")"
    [ ! -s "$kills" ] || fail "expected no Finder/Dock restart on second run"

    rm -rf "$tmpdir"
}

# 只有当前值不同的键才应被重写，且此时才重启 UI。
test_only_changed_key_is_rewritten() {
    build_sandbox
    run_defaults

    awk -F'|' -v OFS='|' '
        $1=="com.apple.dock" && $2=="autohide" {$3="0"}
        {print}
    ' "$state" >"$state.tmp"
    mv "$state.tmp" "$state"

    : >"$writes"
    : >"$kills"
    run_defaults

    write_count=$(grep -c . "$writes" || true)
    assert_equals 1 "$write_count"
    assert_contains 'com.apple.dock|autohide|1' "$writes"
    [ -s "$kills" ] || fail "expected Finder/Dock restart after a value changed"

    rm -rf "$tmpdir"
}

test_first_run_writes_all_and_restarts_ui
test_second_run_is_a_noop
test_only_changed_key_is_rewritten

printf 'PASS: macOS defaults tests\n'
