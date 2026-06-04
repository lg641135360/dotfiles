#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MODE=${1:-full}

run_test() {
    printf '===== RUN %s =====\n' "${1#$REPO_ROOT/}"
    "$1"
}

run_group() {
    pattern=$1
    for test_file in $REPO_ROOT/tests/$pattern; do
        [ -f "$test_file" ] || continue
        [ "$(basename -- "$test_file")" = "run.sh" ] && continue
        run_test "$test_file"
    done
}

case "$MODE" in
    docs)
        run_test "$REPO_ROOT/tests/repo_docs_test.sh"
        run_test "$REPO_ROOT/tests/git_config_test.sh"
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
        printf 'Usage: %s [docs|awesome|nvim|fast|full]\n' "$0" >&2
        exit 2
        ;;
esac
