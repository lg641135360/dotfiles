#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SCRIPT_FILE=$REPO_ROOT/.config/scripts/corplink-service
INSTALL_FILE=$REPO_ROOT/install.sh

# shellcheck source=tests/lib/assert.sh
. "$REPO_ROOT/tests/lib/assert.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

bin_dir=$tmpdir/bin
log_file=$tmpdir/systemctl.log
sudo_log=$tmpdir/sudo.log
mkdir -p "$bin_dir"

cat >"$bin_dir/id" <<'EOF'
#!/bin/sh
printf '%s\n' "${FAKE_ID_UID:-0}"
EOF

cat >"$bin_dir/systemctl" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$FAKE_SYSTEMCTL_LOG"
if [ "$1" = "is-active" ]; then
    exit "${FAKE_IS_ACTIVE_EXIT:-3}"
fi
if [ "$1" = "show" ]; then
    printf '%s\n' "${FAKE_CONTROL_GROUP:-}"
fi
EOF

cat >"$bin_dir/sudo" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >"$FAKE_SUDO_LOG"
EOF

chmod +x "$bin_dir/id" "$bin_dir/systemctl" "$bin_dir/sudo"

run_script() {
    PATH=$bin_dir:/usr/bin:/bin \
        FAKE_SYSTEMCTL_LOG=$log_file \
        FAKE_SUDO_LOG=$sudo_log \
        CORPLINK_SYSTEMCTL=$bin_dir/systemctl \
        CORPLINK_CGROUP_ROOT=$tmpdir/cgroup \
        CORPLINK_KILL_WAIT_SECONDS=0 \
        /bin/sh "$SCRIPT_FILE" "$@"
}

test_script_contract() {
    assert_file_exists "$SCRIPT_FILE"
    assert_executable "$SCRIPT_FILE"
    assert_contains 'unit=${CORPLINK_UNIT:-corplink.service}' "$SCRIPT_FILE"
    assert_contains 'systemctl_cmd=${CORPLINK_SYSTEMCTL:-systemctl}' "$SCRIPT_FILE"
    assert_contains '"$systemctl_cmd" stop "$unit"' "$SCRIPT_FILE"
    assert_contains 'kill --kill-whom=all --signal=TERM "$unit"' "$SCRIPT_FILE"
    assert_contains 'kill --kill-whom=all --signal=KILL "$unit"' "$SCRIPT_FILE"
    assert_not_contains 'mask --now --force' "$SCRIPT_FILE"
    assert_not_contains 'unmask' "$SCRIPT_FILE"
    assert_not_contains '"$systemctl_cmd" mask' "$SCRIPT_FILE"
    assert_not_contains '"$systemctl_cmd" disable' "$SCRIPT_FILE"
    assert_not_contains '"$systemctl_cmd" enable' "$SCRIPT_FILE"
}

test_status_is_default_action() {
    : >"$log_file"
    run_script >/dev/null
    assert_contains 'status corplink.service --no-pager' "$log_file"
}

test_disable_stops_temporarily_and_verifies_service() {
    : >"$log_file"
    run_script disable >/dev/null
    assert_contains 'stop corplink.service' "$log_file"
    assert_contains 'kill --kill-whom=all --signal=TERM corplink.service' "$log_file"
    assert_contains 'kill --kill-whom=all --signal=KILL corplink.service' "$log_file"
    assert_not_contains 'mask' "$log_file"
    assert_not_contains 'daemon-reload' "$log_file"
    assert_contains 'is-active --quiet corplink.service' "$log_file"
    assert_contains 'show corplink.service --property=ControlGroup --value' "$log_file"
    assert_order 'stop corplink.service' 'kill --kill-whom=all --signal=TERM corplink.service' "$log_file"
    assert_order 'kill --kill-whom=all --signal=TERM corplink.service' 'kill --kill-whom=all --signal=KILL corplink.service' "$log_file"
}

test_disable_fails_if_service_remains_active() {
    : >"$log_file"
    if FAKE_IS_ACTIVE_EXIT=0 run_script disable >/dev/null 2>&1; then
        fail "expected disable to fail while corplink.service remains active"
    fi
}

test_disable_fails_if_cgroup_still_has_processes() {
    cgroup_dir=$tmpdir/cgroup/system.slice/corplink.service
    mkdir -p "$cgroup_dir"
    printf '4126935\n' >"$cgroup_dir/cgroup.procs"

    if FAKE_CONTROL_GROUP=/system.slice/corplink.service run_script disable >/dev/null 2>&1; then
        fail "expected disable to fail while the corplink cgroup still has processes"
    fi

    rm -f "$cgroup_dir/cgroup.procs"
}

test_enable_starts_service_without_changing_boot_state() {
    : >"$log_file"
    run_script enable >/dev/null
    assert_not_contains 'unmask' "$log_file"
    assert_not_contains 'daemon-reload' "$log_file"
    assert_contains 'start corplink.service' "$log_file"
}

test_non_root_execution_delegates_to_sudo() {
    : >"$sudo_log"
    FAKE_ID_UID=1000 run_script disable >/dev/null
    assert_contains "-- $SCRIPT_FILE disable" "$sudo_log"
}

test_unknown_action_fails_with_usage() {
    if run_script unknown >"$tmpdir/stdout" 2>"$tmpdir/stderr"; then
        fail "expected unknown action to fail"
    fi
    assert_contains '用法:' "$tmpdir/stderr"
}

test_install_and_docs_include_script() {
    assert_contains '|.config/scripts/corplink-service|~/.config/scripts/corplink-service|Corplink temporary service manager' "$INSTALL_FILE"
    assert_contains '`corplink-service`' "$REPO_ROOT/.config/scripts/README.md"
}

test_script_contract
test_status_is_default_action
test_disable_stops_temporarily_and_verifies_service
test_disable_fails_if_service_remains_active
test_disable_fails_if_cgroup_still_has_processes
test_enable_starts_service_without_changing_boot_state
test_non_root_execution_delegates_to_sudo
test_unknown_action_fails_with_usage
test_install_and_docs_include_script

printf 'PASS: corplink service tests\n'
