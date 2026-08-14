#!/bin/sh
set -u

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MODE=full
DRY_RUN=0

# SKIP_EXIT_CODE matches the automake convention: tests that cannot run
# in the current environment exit 77 so the runner can count them as
# skipped instead of passed.
SKIP_EXIT_CODE=77

passed=0
failed=0
skipped=0
failed_list=""

usage() {
    printf 'Usage: %s [--dry-run] [docs|awesome|nvim|fast|full|list]\n' "$0" >&2
}

# Parse leading flags. The first non-flag argument becomes MODE.
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --*)
            printf 'unknown flag: %s\n' "$1" >&2
            usage
            exit 2
            ;;
        *)
            MODE=$1
            shift
            break
            ;;
    esac
done

run_test() {
    test_path=$1
    label=${1#"$REPO_ROOT/"}

    if [ "$DRY_RUN" -eq 1 ]; then
        printf '===== DRY-RUN %s =====\n' "$label"
        return 0
    fi

    printf '===== RUN %s =====\n' "$label"
    "$test_path"
    rc=$?
    case "$rc" in
        0)
            passed=$((passed + 1))
            ;;
        "$SKIP_EXIT_CODE")
            skipped=$((skipped + 1))
            printf -- '----- SKIP %s (exit %s) -----\n' "$label" "$rc"
            ;;
        *)
            failed=$((failed + 1))
            failed_list="$failed_list $label"
            printf -- '----- FAIL %s (exit %s) -----\n' "$label" "$rc"
            ;;
    esac
    return 0
}

run_group() {
    pattern=$1
    for test_file in $REPO_ROOT/tests/$pattern; do
        [ -f "$test_file" ] || continue
        [ "$(basename -- "$test_file")" = "run.sh" ] && continue
        run_test "$test_file"
    done
}

list_group() {
    pattern=$1
    for test_file in $REPO_ROOT/tests/$pattern; do
        [ -f "$test_file" ] || continue
        [ "$(basename -- "$test_file")" = "run.sh" ] && continue
        printf '%s\n' "$test_file"
    done
}

list_all() {
    for test_file in "$REPO_ROOT"/tests/*.sh; do
        [ -f "$test_file" ] || continue
        [ "$(basename -- "$test_file")" = "run.sh" ] && continue
        printf '%s\n' "$test_file"
    done
}

case "$MODE" in
    list)
        list_all
        exit 0
        ;;
    docs)
        run_test "$REPO_ROOT/tests/repo_docs_test.sh"
        ;;
    awesome)
        run_group 'awesome_*_test.sh'
        ;;
    nvim)
        run_group 'nvim_*_test.sh'
        ;;
    fast)
        for test_file in "$REPO_ROOT"/tests/*.sh; do
            [ -f "$test_file" ] || continue
            case "$(basename -- "$test_file")" in
                run.sh|nvim_*) continue ;;
            esac
            run_test "$test_file"
        done
        ;;
    full)
        for test_file in "$REPO_ROOT"/tests/*.sh; do
            [ -f "$test_file" ] || continue
            [ "$(basename -- "$test_file")" = "run.sh" ] && continue
            run_test "$test_file"
        done
        ;;
    *)
        usage
        exit 2
        ;;
esac

if [ "$DRY_RUN" -eq 0 ]; then
    printf '\n===== Summary =====\n'
    printf 'PASS=%s FAIL=%s SKIP=%s\n' "$passed" "$failed" "$skipped"
    if [ -n "$failed_list" ]; then
        printf 'Failed tests:%s\n' "$failed_list"
    fi
fi

[ "$failed" -eq 0 ]
