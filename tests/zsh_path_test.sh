#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PATH_FILE=$REPO_ROOT/.config/shared/zsh/path.zsh
ZSH_BIN=$(command -v zsh || true)

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_path_contains() {
    needle=$1
    path_value=$2

    printf '%s\n' "$path_value" | grep -F -- "$needle" >/dev/null 2>&1 ||
        fail "expected PATH to contain: $needle"
}

test_linux_path_includes_usr_local_nodejs_bin() {
    if [ "$(uname)" != "Linux" ]; then
        printf 'SKIP: zsh path test requires Linux\n'
        return 0
    fi

    if [ ! -d /usr/local/nodejs/bin ]; then
        printf 'SKIP: /usr/local/nodejs/bin is not present\n'
        return 0
    fi

    if [ -z "$ZSH_BIN" ]; then
        printf 'SKIP: zsh is not installed\n'
        return 0
    fi

    tmpdir=$(mktemp -d)
    path_value=$(
        PATH=/usr/bin:/bin HOME="$HOME" ZDOTDIR="$tmpdir" "$ZSH_BIN" -fc \
            ". \"$PATH_FILE\"; print -r -- \$PATH"
    )
    rm -rf "$tmpdir"

    assert_path_contains "/usr/local/nodejs/bin" "$path_value"
}

test_linux_path_includes_usr_local_nodejs_bin

printf 'PASS: zsh path tests\n'
