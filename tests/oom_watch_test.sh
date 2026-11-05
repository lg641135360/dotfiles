#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

SCRIPT=$REPO_ROOT/.config/scripts/oom-watch

skip_unless_platform Linux || exit $?

tmpdir=$(mktemp -d)
state_dir=$tmpdir/state

cleanup() {
    OOM_WATCH_STATE_DIR=$state_dir "$SCRIPT" stop >/dev/null 2>&1 || true
    rm -rf "$tmpdir"
}
trap cleanup EXIT INT TERM HUP

watch() {
    OOM_WATCH_STATE_DIR=$state_dir \
    OOM_WATCH_CGROUP_ROOT=$tmpdir/cgroup \
    OOM_WATCH_MEMINFO=$tmpdir/meminfo \
    OOM_WATCH_PSI=$tmpdir/psi \
    OOM_WATCH_PROC_ROOT=$tmpdir/proc \
    OOM_WATCH_INTERVAL=${TEST_INTERVAL:-15} \
    OOM_WATCH_MAX_BYTES=${TEST_MAX_BYTES:-8388608} \
    "$SCRIPT" "$@"
}

assert_log_contains() {
    needle=$1
    if ! grep -F -- "$needle" "$state_dir"/oom-watch.log* >/dev/null 2>&1; then
        fail "expected '$needle' in oom-watch.log or its rotated files"
    fi
}

setup_fake_environment() {
    mkdir -p "$tmpdir/cgroup/app.slice/app-test.scope" "$tmpdir/proc/123"

    cat > "$tmpdir/meminfo" <<'EOF'
MemTotal:       32768000 kB
MemFree:         4000000 kB
MemAvailable:    8000000 kB
AnonPages:       2000000 kB
Shmem:           3145728 kB
ShmemHugePages:   400000 kB
SReclaimable:      50000 kB
SUnreclaim:        50000 kB
PageTables:        20000 kB
Committed_AS:    9000000 kB
CommitLimit:    16000000 kB
SwapTotal:       8388608 kB
SwapFree:        6000000 kB
Dirty:               100 kB
Writeback:             0 kB
EOF

    cat > "$tmpdir/psi" <<'EOF'
some avg10=0.00 avg60=0.00 avg300=0.00 total=0
full avg10=0.00 avg60=0.00 avg300=0.00 total=0
EOF

    for base in "$tmpdir/cgroup" "$tmpdir/cgroup/app.slice/app-test.scope"; do
        printf '5242880\n' > "$base/memory.current"
        printf '6291456\n' > "$base/memory.peak"
        printf '102400\n' > "$base/memory.swap.current"
        printf 'anon 1048576\nfile 2097152\nshmem 3145728\nkernel 102400\nslab 204800\n' > "$base/memory.stat"
        printf 'oom_kill 0\n' > "$base/memory.events"
    done

    cat > "$tmpdir/proc/123/status" <<'EOF'
Name:	test-proc
RssAnon:	1024 kB
RssShmem:	2048 kB
VmSwap:	512 kB
EOF
    printf '0\n' > "$tmpdir/proc/123/oom_score_adj"
}

test_script_contract() {
    assert_executable "$SCRIPT"
    sh -n "$SCRIPT"

    output=$("$SCRIPT" help)
    assert_output_contains 'start [--interval N]' "$output"
    assert_output_contains 'stop' "$output"
    assert_output_contains 'status' "$output"
    assert_output_contains 'once' "$output"
    assert_output_contains 'tail' "$output"
    assert_output_contains 'oom-watch.log' "$output"
}

test_once_reports_meminfo_cgroup_scope_proc_and_tmpfs() {
    setup_fake_environment
    mkdir -p "$tmpdir/cgroup/session.slice/niri.service" "$tmpdir/cgroup/app.slice/dms.service"
    for base in "$tmpdir/cgroup/session.slice/niri.service" "$tmpdir/cgroup/app.slice/dms.service"; do
        printf '5242880\n' > "$base/memory.current"
        printf '6291456\n' > "$base/memory.peak"
        printf '102400\n' > "$base/memory.swap.current"
        printf 'anon 1048576\nfile 2097152\nshmem 3145728\nkernel 102400\nslab 204800\n' > "$base/memory.stat"
        printf 'oom_kill 0\n' > "$base/memory.events"
    done
    mkdir -p "$tmpdir/proc/123/fdinfo"
    cat > "$tmpdir/proc/123/fdinfo/40" <<'EOF'
drm-driver:	i915
drm-client-id:	14
drm-total-system0:	1260256 KiB
drm-shared-system0:	999856 KiB
drm-resident-system0:	743716 KiB
drm-purgeable-system0:	44088 KiB
EOF

    output=$(watch once)
    assert_output_contains 'level=INFO' "$output"
    assert_output_contains 'mem_total_kb=32768000' "$output"
    assert_output_contains 'mem_avail_kb=8000000' "$output"
    assert_output_contains 'shmem_kb=3145728' "$output"
    assert_output_contains 'cgroup label=user' "$output"
    assert_output_contains 'cgroup label=app_slice' "$output"
    assert_output_contains 'cgroup label=niri_service' "$output"
    assert_output_contains 'cgroup label=dms_service' "$output"
    assert_output_contains 'scope name=app-test.scope' "$output"
    assert_output_contains 'scope name=app-test.scope current_kb=5242880' "$output"
    assert_output_contains 'proc pid=123 name=test-proc rss_shmem_kb=2048' "$output"
    assert_output_contains 'drm pid=123 name=test-proc client_id=14 total_kb=1260256' "$output"
    assert_output_contains 'tmpfs mount=/tmp' "$output"
}

test_once_level_crit_when_shmem_over_threshold() {
    setup_fake_environment

    output=$(OOM_WATCH_WARN_SHMEM_KB=1000 OOM_WATCH_CRIT_SHMEM_KB=2000 watch once)
    assert_output_contains 'level=CRIT' "$output"
}

test_daemon_writes_log_rotates_and_stops() {
    setup_fake_environment

    TEST_INTERVAL=1 TEST_MAX_BYTES=2000 watch start
    sleep 3

    status=$(watch status)
    assert_output_contains 'running' "$status"
    assert_file_exists "$state_dir/oom-watch.log"
    assert_log_contains '=== oom-watch start'
    assert_log_contains 'mem_total_kb=32768000'
    assert_file_exists "$state_dir/oom-watch.log.1"

    printf 'oom_kill 1\n' > "$tmpdir/cgroup/memory.events"
    sleep 2
    assert_log_contains 'EVENT oom_kill_incremented from=0 to=1'

    watch stop
    status=$(watch status)
    assert_output_contains 'not running' "$status"
    assert_file_not_exists "$state_dir/oom-watch.pid"
}

test_script_contract
test_once_reports_meminfo_cgroup_scope_proc_and_tmpfs
test_once_level_crit_when_shmem_over_threshold
test_daemon_writes_log_rotates_and_stops
