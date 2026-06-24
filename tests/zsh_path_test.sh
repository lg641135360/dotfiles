#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PATH_FILE=$REPO_ROOT/.config/shared/zsh/path.zsh
ENV_FILE=$REPO_ROOT/.config/shared/zsh/env.zsh
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

run_path_zsh() {
    tmpdir=$(mktemp -d)
    path_value=$(
        PATH=/usr/bin:/bin HOME="$HOME" ZDOTDIR="$tmpdir" "$ZSH_BIN" -fc \
            ". \"$PATH_FILE\"; print -r -- \$PATH"
    )
    rm -rf "$tmpdir"
    printf '%s\n' "$path_value"
}

run_env_zsh() {
    tmpdir=$(mktemp -d)
    env_value=$(
        PATH=/usr/bin:/bin HOME="$HOME" ZDOTDIR="$tmpdir" XDG_SESSION_TYPE=x11 \
            "$ZSH_BIN" -fc \
            ". \"$ENV_FILE\"; printf '%s|%s|%s\n' \"\$XDG_CURRENT_DESKTOP\" \"\$XDG_SESSION_DESKTOP\" \"\$GTK_USE_PORTAL\""
    )
    rm -rf "$tmpdir"
    printf '%s\n' "$env_value"
}

run_wayland_env_zsh() {
    tmpdir=$(mktemp -d)
    env_value=$(
        PATH=/usr/bin:/bin HOME="$HOME" ZDOTDIR="$tmpdir" \
            XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=niri XDG_SESSION_DESKTOP=niri \
            "$ZSH_BIN" -fc \
            ". \"$ENV_FILE\"; printf '%s|%s|%s\n' \"\$XDG_CURRENT_DESKTOP\" \"\$XDG_SESSION_DESKTOP\" \"\$GTK_USE_PORTAL\""
    )
    rm -rf "$tmpdir"
    printf '%s\n' "$env_value"
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

    path_value=$(run_path_zsh)

    assert_path_contains "/usr/local/nodejs/bin" "$path_value"
}

test_linux_path_includes_user_npm_global_bin() {
    if [ "$(uname)" != "Linux" ]; then
        printf 'SKIP: zsh path test requires Linux\n'
        return 0
    fi

    if [ ! -d "$HOME/.npm-global/bin" ]; then
        printf 'SKIP: %s/.npm-global/bin is not present\n' "$HOME"
        return 0
    fi

    if [ -z "$ZSH_BIN" ]; then
        printf 'SKIP: zsh is not installed\n'
        return 0
    fi

    path_value=$(run_path_zsh)

    assert_path_contains "$HOME/.npm-global/bin" "$path_value"
}

test_linux_path_includes_local_node_current_bin() {
    if [ "$(uname)" != "Linux" ]; then
        printf 'SKIP: zsh path test requires Linux\n'
        return 0
    fi

    if [ ! -d "$HOME/.local/opt/node-current/bin" ]; then
        printf 'SKIP: %s/.local/opt/node-current/bin is not present\n' "$HOME"
        return 0
    fi

    if [ -z "$ZSH_BIN" ]; then
        printf 'SKIP: zsh is not installed\n'
        return 0
    fi

    path_value=$(run_path_zsh)

    assert_path_contains "$HOME/.local/opt/node-current/bin" "$path_value"
}

test_linux_desktop_portal_environment_targets_awesome() {
    if [ "$(uname)" != "Linux" ]; then
        printf 'SKIP: zsh environment test requires Linux\n'
        return 0
    fi

    if [ -z "$ZSH_BIN" ]; then
        printf 'SKIP: zsh is not installed\n'
        return 0
    fi

    env_value=$(run_env_zsh)

    [ "$env_value" = "awesome|awesome|1" ] ||
        fail "expected Awesome portal environment, got: $env_value"
}

test_linux_wayland_environment_preserves_current_desktop() {
    if [ "$(uname)" != "Linux" ]; then
        printf 'SKIP: zsh environment test requires Linux\n'
        return 0
    fi

    if [ -z "$ZSH_BIN" ]; then
        printf 'SKIP: zsh is not installed\n'
        return 0
    fi

    env_value=$(run_wayland_env_zsh)

    [ "$env_value" = "niri|niri|1" ] ||
        fail "expected Wayland desktop environment to be preserved, got: $env_value"
}

test_linux_path_includes_usr_local_nodejs_bin
test_linux_path_includes_user_npm_global_bin
test_linux_path_includes_local_node_current_bin
test_linux_desktop_portal_environment_targets_awesome
test_linux_wayland_environment_preserves_current_desktop

printf 'PASS: zsh path tests\n'
