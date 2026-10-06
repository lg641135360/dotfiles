#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"
. "$REPO_ROOT/tests/lib/sandbox.sh"

SCRIPT=$REPO_ROOT/.config/scripts/dms-niri-setup
FRAGMENT=$REPO_ROOT/.config/linux/dms/niri-repo.kdl
SETTINGS_MANIFEST=$REPO_ROOT/.config/linux/dms/settings.txt
DMS_README=$REPO_ROOT/.config/linux/dms/README.md
ROOT_README=$REPO_ROOT/README.md
DNF_MANIFEST=$REPO_ROOT/.config/linux/packages/dnf.txt

# Stub niri: the setup script only probes for its presence.
write_stub_niri() {
    bin_dir=$1
    printf '#!/bin/sh\nexit 0\n' >"$bin_dir/niri"
    chmod +x "$bin_dir/niri"
}

# Stub dms CLI covering exactly the subcommands dms-niri-setup uses:
#   dms setup binds
#   dms config resolve-include niri <basename>
#   dms config windowrules list|add niri
# State lives under $HOME/.stub-dms so tests can assert on rule count.
write_stub_dms() {
    bin_dir=$1
    cat >"$bin_dir/dms" <<'STUB'
#!/bin/sh
set -u
state_dir=$HOME/.stub-dms
niri_dir=$HOME/.config/niri
mkdir -p "$state_dir"
# 记录调用参数：stub 可能运行在临时 HOME 里，日志放到 stub 自己旁边。
printf '%s\n' "$*" >>"$(dirname "$0")/../stub-dms-args" 2>/dev/null || true

case "${1:-}" in
    setup)
        # setup binds 与 setup headless 都产出默认键位（真实 dms 里前者交互、后者非交互）。
        case "${2:-}" in
            binds|headless)
                mkdir -p "$niri_dir/dms"
                printf 'binds {\n    Mod+T { spawn "dms" "ipc" "call" "spotlight" "toggle"; }\n}\n' >"$niri_dir/dms/binds.kdl"
                exit 0
                ;;
        esac
        exit 0
        ;;
    config)
        case "${2:-}" in
            resolve-include)
                name=${4:-}
                if [ -f "$niri_dir/dms/$name" ]; then
                    exists=true
                else
                    exists=false
                fi
                if [ -f "$niri_dir/config.kdl" ] && grep -qF "include \"dms/$name\"" "$niri_dir/config.kdl"; then
                    included=true
                else
                    included=false
                fi
                printf '{"exists":%s,"included":%s}\n' "$exists" "$included"
                exit 0
                ;;
            windowrules)
                rules_file=$state_dir/rules
                case "${3:-}" in
                    list)
                        printf '{"rules":['
                        if [ -f "$rules_file" ]; then
                            tr '\n' ',' <"$rules_file" | sed 's/,$//'
                        fi
                        printf '],"dmsStatus":{"exists":true,"included":true,"effective":true}}\n'
                        exit 0
                        ;;
                    add)
                        printf '%s\n' "${5:-}" >>"$rules_file"
                        exit 0
                        ;;
                esac
                ;;
        esac
        ;;
    ipc)
        # settings get/set 与 night 族：状态存在 $state_dir，未写过的键回 DMS 默认值，
        # 与真实 DMS 的行为对齐（真实机器上未改过的键也返回默认值而不是 undefined）。
        case "${2:-}${3:-}" in
            callsettings)
                key=${5:-}
                case "${4:-}" in
                    get)
                        if [ -f "$state_dir/setting.$key" ]; then
                            cat "$state_dir/setting.$key"
                        else
                            case $key in
                                acLockTimeout|acMonitorTimeout) printf '0\n' ;;
                                useAutoLocation) printf 'false\n' ;;
                                touchpadDragLock) printf 'false\n' ;;
                                *) printf 'undefined\n' ;;
                            esac
                        fi
                        exit 0
                        ;;
                    set)
                        printf '%s\n' "${6:-}" >"$state_dir/setting.$key"
                        printf 'SETTINGS_SET_SUCCESS\n'
                        exit 0
                        ;;
                esac
                ;;
            callnight)
                case "${4:-}" in
                    getTargetTemp)
                        if [ -f "$state_dir/night-temp" ]; then
                            cat "$state_dir/night-temp"
                        else
                            printf '4500\n'
                        fi
                        exit 0
                        ;;
                    status)
                        if [ -f "$state_dir/night-enabled" ]; then
                            night_state=$(cat "$state_dir/night-enabled")
                        else
                            night_state=disabled
                        fi
                        printf 'Night mode: %s\nCurrent temperature: 6500K\n' "$night_state"
                        exit 0
                        ;;
                    enable)
                        printf 'enabled\n' >"$state_dir/night-enabled"
                        exit 0
                        ;;
                    disable)
                        printf 'disabled\n' >"$state_dir/night-enabled"
                        exit 0
                        ;;
                    setTargetTemp)
                        printf '%s\n' "${5:-}" >"$state_dir/night-temp"
                        exit 0
                        ;;
                esac
                ;;
        esac
        exit 0
        ;;
esac

exit 0
STUB
    chmod +x "$bin_dir/dms"
}

# Sandbox with both stubs. Extra commands beyond link_core_utils are the ones
# the stub body itself invokes inside the sandbox PATH.
setup_sandbox() {
    tmpdir=$(mktemp -d)
    bin_dir=$tmpdir/bin
    home_dir=$tmpdir/home
    mkdir -p "$bin_dir" "$home_dir"
    link_core_utils "$bin_dir"
    for cmd in tr cat; do
        link_cmd "$cmd" "$bin_dir"
    done
    write_stub_niri "$bin_dir"
    write_stub_dms "$bin_dir"
}

# Fixture shaped like a real DMS install: fragments on disk, config.kdl
# including only one of them, and an empty binds.kdl (the state observed on
# Fedora 44 after `dnf install dms`).
seed_niri_fixture() {
    mkdir -p "$home_dir/.config/niri/dms"
    printf 'input {\n}\n' >"$home_dir/.config/niri/dms/input.kdl"
    printf 'layout {\n}\n' >"$home_dir/.config/niri/dms/layout.kdl"
    printf 'colors {\n}\n' >"$home_dir/.config/niri/dms/colors.kdl"
    : >"$home_dir/.config/niri/dms/binds.kdl"
    printf 'include "dms/input.kdl"\n' >"$home_dir/.config/niri/config.kdl"
    cp "$FRAGMENT" "$home_dir/.config/niri/niri-repo.kdl"
    # 设置清单由 install.sh 部署到 ~/.config/dms/settings.txt。
    mkdir -p "$home_dir/.config/dms"
    cp "$SETTINGS_MANIFEST" "$home_dir/.config/dms/settings.txt"
}

run_setup() {
    PATH=$bin_dir HOME=$home_dir "$SCRIPT" "$@"
}

rule_count() {
    if [ -f "$home_dir/.stub-dms/rules" ]; then
        grep -c . "$home_dir/.stub-dms/rules"
    else
        printf '0\n'
    fi
}

backup_count() {
    ls -1 "$home_dir/.config/niri"/config.kdl.backup.* 2>/dev/null | grep -c . || true
}

# -------------------------------------------------------------------------

test_script_and_fragment_exist() {
    assert_file_exists "$SCRIPT"
    assert_executable "$SCRIPT"
    assert_file_exists "$FRAGMENT"
    assert_file_exists "$SETTINGS_MANIFEST"
    assert_file_exists "$DMS_README"
}

test_noop_without_dms() {
    setup_sandbox
    rm -f "$bin_dir/dms"
    seed_niri_fixture
    before=$(cat "$home_dir/.config/niri/config.kdl")

    set +e
    PATH=$bin_dir HOME=$home_dir "$SCRIPT" >/dev/null 2>&1
    status=$?
    set -e

    assert_exit_code 0 "$status" "dms-niri-setup without dms"
    assert_equals "$before" "$(cat "$home_dir/.config/niri/config.kdl")"
    assert_equals "0" "$(rule_count)"
    rm -rf "$tmpdir"
}

test_noop_without_niri() {
    setup_sandbox
    rm -f "$bin_dir/niri"
    seed_niri_fixture
    before=$(cat "$home_dir/.config/niri/config.kdl")

    set +e
    PATH=$bin_dir HOME=$home_dir "$SCRIPT" >/dev/null 2>&1
    status=$?
    set -e

    assert_exit_code 0 "$status" "dms-niri-setup without niri"
    assert_equals "$before" "$(cat "$home_dir/.config/niri/config.kdl")"
    rm -rf "$tmpdir"
}

test_checks_without_config_kdl_is_noop() {
    setup_sandbox
    mkdir -p "$home_dir/.config/niri/dms"
    cp "$FRAGMENT" "$home_dir/.config/niri/niri-repo.kdl"

    set +e
    PATH=$bin_dir HOME=$home_dir "$SCRIPT" >/dev/null 2>&1
    status=$?
    set -e

    assert_exit_code 0 "$status" "dms-niri-setup without config.kdl"
    assert_file_not_exists "$home_dir/.config/niri/config.kdl"
    rm -rf "$tmpdir"
}

test_apply_wires_fragments_and_rules() {
    setup_sandbox
    seed_niri_fixture

    PATH=$bin_dir HOME=$home_dir "$SCRIPT" >/dev/null 2>&1 ||
        fail "dms-niri-setup should succeed on a DMS fixture"

    config=$home_dir/.config/niri/config.kdl
    # DMS default binds get deployed when binds.kdl is empty.
    grep -q . "$home_dir/.config/niri/dms/binds.kdl" ||
        fail "expected binds.kdl to be non-empty after dms setup"
    # 非交互生成走 scratch HOME，而不是直接对 live 调用交互式 `dms setup binds`。
    assert_contains 'setup headless --compositor niri' "$home_dir/../stub-dms-args" ||
        fail "expected dms setup headless to be used"
    # ...and every dms fragment is included, with the repo fragment last.
    assert_contains 'include "dms/input.kdl"' "$config"
    assert_contains 'include "dms/layout.kdl"' "$config"
    assert_contains 'include "dms/colors.kdl"' "$config"
    assert_contains 'include "dms/binds.kdl"' "$config"
    assert_contains 'include "niri-repo.kdl"' "$config"
    assert_order 'include "dms/binds.kdl"' 'include "niri-repo.kdl"' "$config"
    # Existing includes are not duplicated.
    assert_equals "1" "$(grep -cF 'include "dms/input.kdl"' "$config")"
    # DingTalk rules are recreated through the DMS channel, in the documented
    # order (generic floating rule before the tiling override).
    assert_equals "3" "$(rule_count)"
    assert_contains '"openFocused":false' "$home_dir/.stub-dms/rules"
    assert_contains '"openFloating":true' "$home_dir/.stub-dms/rules"
    assert_contains '"openFloating":false' "$home_dir/.stub-dms/rules"
    assert_order '"openFloating":true' '"openFloating":false' "$home_dir/.stub-dms/rules"
    # Config edits are backed up.
    [ "$(backup_count)" -ge 1 ] || fail "expected a timestamped config.kdl backup"

    rm -rf "$tmpdir"
}

test_second_run_is_idempotent() {
    setup_sandbox
    seed_niri_fixture

    PATH=$bin_dir HOME=$home_dir "$SCRIPT" >/dev/null 2>&1
    first_config=$(cat "$home_dir/.config/niri/config.kdl")
    first_backups=$(backup_count)
    first_rules=$(rule_count)

    PATH=$bin_dir HOME=$home_dir "$SCRIPT" >/dev/null 2>&1 ||
        fail "second dms-niri-setup run should succeed"

    assert_equals "$first_config" "$(cat "$home_dir/.config/niri/config.kdl")"
    assert_equals "$first_backups" "$(backup_count)"
    assert_equals "$first_rules" "$(rule_count)"

    rm -rf "$tmpdir"
}

test_setup_generation_prefers_installed_alacritty() {
    setup_sandbox
    printf '#!/bin/sh\nexit 0\n' >"$bin_dir/alacritty"
    chmod +x "$bin_dir/alacritty"
    seed_niri_fixture

    PATH=$bin_dir HOME=$home_dir "$SCRIPT" >/dev/null 2>&1 ||
        fail "dms-niri-setup should succeed with alacritty present"

    # 已装 alacritty 时把终端选项传给 dms setup headless，生成的 Mod+T 才可用。
    assert_contains '--terminal alacritty' "$tmpdir/stub-dms-args"

    rm -rf "$tmpdir"
}

test_applies_dms_settings_idempotently() {
    setup_sandbox
    seed_niri_fixture

    PATH=$bin_dir HOME=$home_dir "$SCRIPT" >/dev/null 2>&1 ||
        fail "dms-niri-setup should succeed with a settings manifest"

    state=$home_dir/.stub-dms
    assert_equals '600' "$(cat "$state/setting.acLockTimeout")"
    assert_equals '900' "$(cat "$state/setting.acMonitorTimeout")"
    assert_equals 'true' "$(cat "$state/setting.touchpadDragLock")"
    assert_equals '5500' "$(cat "$state/night-temp")"
    assert_equals 'enabled' "$(cat "$state/night-enabled")"
    # useAutoLocation 默认就是 false：相等就不应产生写操作。
    assert_file_not_exists "$state/setting.useAutoLocation"

    # 第二次运行不再下发任何 settings set。
    before=$(grep -c 'ipc call settings set' "$tmpdir/stub-dms-args" || true)
    PATH=$bin_dir HOME=$home_dir "$SCRIPT" >/dev/null 2>&1 ||
        fail "second dms-niri-setup run should succeed"
    after=$(grep -c 'ipc call settings set' "$tmpdir/stub-dms-args" || true)
    assert_equals "$before" "$after"

    rm -rf "$tmpdir"
}

test_settings_manifest_format() {
    assert_file_exists "$SETTINGS_MANIFEST"
    # 一行一个 key=value；值内不能有空格（脚本按第一个 = 切分），不允许行内注释。
    bad=$(awk '!/^[[:space:]]*#/ && NF > 0 { if ($0 !~ /^[A-Za-z0-9_.]+=[^[:space:]=]+$/) print FNR ": " $0 }' "$SETTINGS_MANIFEST")
    [ -z "$bad" ] || fail "settings manifest lines must be key=value: $bad"
    for entry in \
        'acLockTimeout=600' \
        'acMonitorTimeout=900' \
        'useAutoLocation=false' \
        'touchpadDragLock=true' \
        'night.temperature=5500' \
        'night.enabled=true'; do
        assert_contains "$entry" "$SETTINGS_MANIFEST"
    done
}

test_check_reports_drift_then_clean() {
    setup_sandbox
    seed_niri_fixture

    set +e
    PATH=$bin_dir HOME=$home_dir "$SCRIPT" --check >/dev/null 2>&1
    status=$?
    set -e
    assert_exit_code 1 "$status" "dms-niri-setup --check before apply"

    PATH=$bin_dir HOME=$home_dir "$SCRIPT" >/dev/null 2>&1

    set +e
    PATH=$bin_dir HOME=$home_dir "$SCRIPT" --check >/dev/null 2>&1
    status=$?
    set -e
    assert_exit_code 0 "$status" "dms-niri-setup --check after apply"

    rm -rf "$tmpdir"
}

test_dry_run_changes_nothing() {
    setup_sandbox
    seed_niri_fixture
    before=$(cat "$home_dir/.config/niri/config.kdl")

    PATH=$bin_dir HOME=$home_dir "$SCRIPT" --dry-run >/dev/null 2>&1 ||
        fail "dms-niri-setup --dry-run should succeed"

    assert_equals "$before" "$(cat "$home_dir/.config/niri/config.kdl")"
    assert_equals "0" "$(rule_count)"
    assert_equals "0" "$(backup_count)"
    assert_equals "0" "$(grep -c . "$home_dir/.config/niri/dms/binds.kdl" || true)"
    # 设置也在 dry-run 里不落盘。
    assert_file_not_exists "$home_dir/.stub-dms/setting.acLockTimeout"
    assert_file_not_exists "$home_dir/.stub-dms/night-temp"
    assert_file_not_exists "$home_dir/.stub-dms/night-enabled"

    rm -rf "$tmpdir"
}

test_own_include_is_moved_last() {
    setup_sandbox
    seed_niri_fixture
    config=$home_dir/.config/niri/config.kdl
    # Repo fragment included too early: niri would let dms/binds.kdl win on
    # conflicting keys. The script must rewrite the order.
    printf 'include "niri-repo.kdl"\ninclude "dms/input.kdl"\ninclude "dms/binds.kdl"\n' >"$config"

    PATH=$bin_dir HOME=$home_dir "$SCRIPT" >/dev/null 2>&1 ||
        fail "dms-niri-setup should succeed when reordering includes"

    assert_equals "1" "$(grep -cF 'include "niri-repo.kdl"' "$config")"
    assert_order 'include "dms/binds.kdl"' 'include "niri-repo.kdl"' "$config"

    rm -rf "$tmpdir"
}

test_missing_fragment_only_warns() {
    setup_sandbox
    seed_niri_fixture
    rm -f "$home_dir/.config/niri/niri-repo.kdl"
    config=$home_dir/.config/niri/config.kdl

    set +e
    output=$(PATH=$bin_dir HOME=$home_dir "$SCRIPT" 2>&1)
    status=$?
    set -e

    assert_exit_code 0 "$status" "dms-niri-setup without repo fragment"
    assert_output_contains 'niri-repo.kdl' "$output"
    assert_equals "0" "$(grep -cF 'include "niri-repo.kdl"' "$config" || true)"

    rm -rf "$tmpdir"
}

# Repo-side content: the fragment must carry the wayland autostart hook and
# the restored muscle-memory binds, and must NOT re-declare keys the
# 2026-10-06 decision left to DMS.
test_fragment_carries_repo_bindings() {
    for bind in \
        'Mod+Tab' \
        'Mod+F' \
        'Mod+Ctrl+F' \
        'Mod+H' \
        'Mod+L' \
        'Mod+Shift+H' \
        'Mod+Shift+L' \
        'Mod+Ctrl+M' \
        'Mod+S' \
        'Mod+Shift+Q' \
        'Mod+Ctrl+Shift+A' \
        'Mod+Ctrl+Shift+D' \
        'Mod+Ctrl+1' \
        'Mod+grave' \
        'Mod+Shift+Space' \
        'Mod+Shift+N'; do
        assert_contains "$bind" "$FRAGMENT"
    done
    # DMS keeps these keys (2026-10-06 traversal): launcher on Mod+Space,
    # task manager on Mod+M, center-column on Mod+C, close on Mod+Shift+E.
    assert_not_contains 'Mod+Space {' "$FRAGMENT"
    assert_not_contains 'mod+space' "$FRAGMENT"
    assert_not_contains 'Mod+M ' "$FRAGMENT"
    assert_not_contains 'Mod+C ' "$FRAGMENT"
    # 仓库 wayland-autostart 故意不在 DMS 机器上 spawn（职责已由 DMS / niri-session /
    # XDG autostart 覆盖，见模块 README）；只断言真正的指令行（注释里的说明不算）。
    assert_not_matches '^[[:space:]]*spawn-sh-at-startup' "$FRAGMENT"
    assert_contains '故意不 spawn' "$FRAGMENT"

    if command -v niri >/dev/null 2>&1; then
        niri validate -c "$FRAGMENT" >/dev/null 2>&1 ||
            fail "expected the DMS niri fragment to validate with installed niri"
    fi
}

test_docs_and_manifest_cover_dms_machine() {
    # README must carry the DMS-machine section with the explicit
    # "do not install" list the user asked for.
    assert_contains 'DMS 机器' "$ROOT_README"
    assert_contains 'install_weak_deps=False' "$ROOT_README"
    assert_contains 'waybar' "$ROOT_README"
    assert_contains 'dms-niri-setup' "$ROOT_README"
    # Module README documents the per-key decision table and the settings manifest.
    assert_contains 'Mod+Space' "$DMS_README"
    assert_contains '覆盖' "$DMS_README"
    assert_contains 'settings.txt' "$DMS_README"
    # Package manifest gains the Fedora niri/DMS section.
    assert_contains 'avengemedia/dms' "$DNF_MANIFEST"
    assert_contains 'niri' "$DNF_MANIFEST"
    assert_contains 'dms' "$DNF_MANIFEST"
    assert_contains 'wl-clip-persist' "$DNF_MANIFEST"
    assert_contains 'cliphist' "$DNF_MANIFEST"
}

for test_case in \
    test_script_and_fragment_exist \
    test_noop_without_dms \
    test_noop_without_niri \
    test_checks_without_config_kdl_is_noop \
    test_apply_wires_fragments_and_rules \
    test_setup_generation_prefers_installed_alacritty \
    test_applies_dms_settings_idempotently \
    test_settings_manifest_format \
    test_second_run_is_idempotent \
    test_check_reports_drift_then_clean \
    test_dry_run_changes_nothing \
    test_own_include_is_moved_last \
    test_missing_fragment_only_warns \
    test_fragment_carries_repo_bindings \
    test_docs_and_manifest_cover_dms_machine; do
    "$test_case"
done

printf 'PASS: dms-niri-setup tests\n'
