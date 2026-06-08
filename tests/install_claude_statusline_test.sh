#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
INSTALL_FILE=$REPO_ROOT/install.sh
STATUSLINE_FILE=$REPO_ROOT/.config/shared/cc/statusline.sh
README_FILE=$REPO_ROOT/README.md
CC_README_FILE=$REPO_ROOT/.config/shared/cc/README.md

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

test_statusline_script_renders_claude_payload() {
    if ! command -v jq >/dev/null 2>&1; then
        printf 'SKIP: Claude statusline render test requires jq
'
        return 0
    fi

    tmpdir=$(mktemp -d)
    repo=$tmpdir/repo

    mkdir -p "$repo"
    git -C "$repo" init -q
    git -C "$repo" config user.email test@example.invalid
    git -C "$repo" config user.name Test
    printf 'clean\n' >"$repo/tracked.txt"
    git -C "$repo" add tracked.txt
    git -C "$repo" commit -q -m init
    printf 'dirty\n' >"$repo/tracked.txt"

    payload=$(printf '{"workspace":{"current_dir":"%s"},"model":{"display_name":"Opus","max_context_tokens":1000000},"effort_level":"high","context_window":{"used_percentage":42,"total_input_tokens":212000,"auto_compact_window_size":200000,"context_window_size":200000}}\n' "$repo")
    output=$(printf '%s' "$payload" |
        env -u CLAUDE_CODE_AUTO_COMPACT_WINDOW -u CLAUDE_CODE_MAX_CONTEXT_TOKENS "$STATUSLINE_FILE")

    printf '%s\n' "$output" | grep -F 'Opus' >/dev/null 2>&1 ||
        fail "expected rendered statusline to include model"
    printf '%s\n' "$output" | grep -F 'high' >/dev/null 2>&1 ||
        fail "expected rendered statusline to include effort"
    printf '%s\n' "$output" | grep -F 'CTX 12k/200k max:1M' >/dev/null 2>&1 ||
        fail "expected rendered statusline to include formatted context"
    printf '%s\n' "$output" | grep -E '\[[^]]+\*\]' >/dev/null 2>&1 ||
        fail "expected rendered statusline to include dirty git branch"

    rm -rf "$tmpdir"
}

test_statusline_script_prefers_claude_env_for_context_limits() {
    if ! command -v jq >/dev/null 2>&1; then
        printf 'SKIP: Claude statusline env context test requires jq
'
        return 0
    fi

    tmpdir=$(mktemp -d)
    repo=$tmpdir/repo

    mkdir -p "$repo"
    git -C "$repo" init -q
    git -C "$repo" config user.email test@example.invalid
    git -C "$repo" config user.name Test
    printf 'clean\n' >"$repo/tracked.txt"
    git -C "$repo" add tracked.txt
    git -C "$repo" commit -q -m init

    payload=$(printf '{"workspace":{"current_dir":"%s"},"model":{"display_name":"Opus"},"effort_level":"high","context_window":{"total_input_tokens":48000,"context_window_size":1000000}}\n' "$repo")
    output=$(printf '%s' "$payload" |
        env CLAUDE_CODE_AUTO_COMPACT_WINDOW=400000 CLAUDE_CODE_MAX_CONTEXT_TOKENS=1000000 "$STATUSLINE_FILE")

    printf '%s\n' "$output" | grep -F 'CTX 48k/400k max:1M' >/dev/null 2>&1 ||
        fail "expected rendered statusline to prefer Claude env context limits"

    rm -rf "$tmpdir"
}

test_install_configures_claude_statusline() {
    if ! command -v jq >/dev/null 2>&1; then
        printf 'SKIP: Claude statusline install test requires jq\n'
        return 0
    fi

    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin

    mkdir -p "$home_dir" "$bin_dir"

    for cmd in bash basename chmod cmp cp date diff dirname find grep head jq ln mkdir mktemp mv pwd rm sed sort tail uname; do
        link_cmd "$cmd" "$bin_dir"
    done

    cat >"$bin_dir/claude" <<'EOF'
#!/bin/sh
exit 0
EOF
    chmod +x "$bin_dir/claude"

    PATH=$bin_dir HOME=$home_dir /bin/bash "$INSTALL_FILE" >/dev/null 2>&1 ||
        fail "install.sh should configure Claude statusline when claude and jq exist"

    assert_file_exists "$home_dir/.config/cc/statusline.sh"
    [ -x "$home_dir/.config/cc/statusline.sh" ] ||
        fail "expected installed Claude statusline script to be executable"
    assert_file_exists "$home_dir/.claude/settings.json"

    command_value=$(jq -r '.statusLine.command' "$home_dir/.claude/settings.json")
    [ "$command_value" = "$home_dir/.config/cc/statusline.sh" ] ||
        fail "expected Claude statusline command to point at installed script"
    type_value=$(jq -r '.statusLine.type' "$home_dir/.claude/settings.json")
    [ "$type_value" = "command" ] ||
        fail "expected Claude statusline type to be command"

    rm -rf "$tmpdir"
}

test_install_updates_existing_claude_settings_without_clobbering_other_keys() {
    if ! command -v jq >/dev/null 2>&1; then
        printf 'SKIP: Claude statusline merge test requires jq\n'
        return 0
    fi

    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin

    mkdir -p "$home_dir/.claude" "$bin_dir"
    printf '{"theme":"dark","statusLine":{"type":"command","command":"old"}}\n' >"$home_dir/.claude/settings.json"

    for cmd in bash basename chmod cmp cp date diff dirname find grep head jq ln mkdir mktemp mv pwd rm sed sort tail uname; do
        link_cmd "$cmd" "$bin_dir"
    done

    cat >"$bin_dir/claude" <<'EOF'
#!/bin/sh
exit 0
EOF
    chmod +x "$bin_dir/claude"

    PATH=$bin_dir HOME=$home_dir /bin/bash "$INSTALL_FILE" >/dev/null 2>&1 ||
        fail "install.sh should merge Claude settings"

    assert_contains '"theme": "dark"' "$home_dir/.claude/settings.json"
    assert_contains '"command": "'"$home_dir"'/.config/cc/statusline.sh"' "$home_dir/.claude/settings.json"
    ls "$home_dir/.claude"/settings.json.backup.* >/dev/null 2>&1 ||
        fail "expected existing Claude settings to be backed up"

    rm -rf "$tmpdir"
}

test_docs_describe_claude_statusline_install() {
    assert_contains "Claude Code statusline" "$README_FILE"
    assert_contains ".config/shared/cc/statusline.sh" "$README_FILE"
    assert_contains "statusLine" "$CC_README_FILE"
    assert_contains "compact-window progress modulo total context" "$CC_README_FILE"
}

test_install_main_is_guarded_for_shell_tests() {
    assert_contains 'if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then' "$INSTALL_FILE"
    assert_contains '    main "$@"' "$INSTALL_FILE"
}

assert_file_exists "$STATUSLINE_FILE"
[ -x "$STATUSLINE_FILE" ] || fail "expected repo Claude statusline script to be executable"

test_statusline_script_renders_claude_payload
test_statusline_script_prefers_claude_env_for_context_limits
test_install_configures_claude_statusline
test_install_updates_existing_claude_settings_without_clobbering_other_keys
test_docs_describe_claude_statusline_install
test_install_main_is_guarded_for_shell_tests

printf 'PASS: install Claude statusline tests\n'
