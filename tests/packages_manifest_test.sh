#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

BREWFILE=$REPO_ROOT/.config/linux/Brewfile
APT_MANIFEST=$REPO_ROOT/.config/linux/packages/apt.txt
DNF_MANIFEST=$REPO_ROOT/.config/linux/packages/dnf.txt
ROOT_README=$REPO_ROOT/README.md
ZSH_README=$REPO_ROOT/.config/shared/zsh/README.md

# Non-comment, non-blank lines. `|| true` keeps `set -e` happy when a file
# has no active entries (the emptiness check below reports it properly).
active_lines() {
    grep -vE '^[[:space:]]*(#|$)' "$1" || true
}

test_brewfile_layers_and_entries() {
    assert_file_exists "$BREWFILE"
    # tmux 按既有决策走系统包（libevent/ncurses 与系统一致、避免遮蔽），
    # 不得再出现在 Brewfile。
    assert_not_contains 'brew "tmux"' "$BREWFILE"
    for formula in fd fzf neovim yazi bat lsd ripgrep zoxide; do
        assert_contains "brew \"$formula\"" "$BREWFILE"
    done
    # 分层入口必须在文件头可见。
    assert_contains 'packages/apt.txt' "$BREWFILE"
    assert_contains 'packages/dnf.txt' "$BREWFILE"
}

test_manifest_format() {
    manifest=$1
    assert_file_exists "$manifest"

    [ -n "$(active_lines "$manifest")" ] ||
        fail "manifest has no active entries: $manifest"

    # 一行一个包名，禁止空白（注释与空行除外），保证 xargs 用法可靠。
    bad_lines=$(awk '!/^[[:space:]]*#/ && NF > 1 { print FNR ": " $0 }' "$manifest")
    [ -z "$bad_lines" ] ||
        fail "manifest entries must be one token per line: $manifest ($bad_lines)"

    # 单文件内不得重复。
    dups=$(active_lines "$manifest" | sort | uniq -d)
    [ -z "$dups" ] ||
        fail "duplicate entries in $manifest: $dups"
}

test_no_cross_channel_overlap() {
    # 单一渠道原则：Brewfile 里的 formula 不得同时出现在任一系统层清单。
    for manifest in "$APT_MANIFEST" "$DNF_MANIFEST"; do
        while IFS= read -r pkg; do
            [ -n "$pkg" ] || continue
            if grep -qF "brew \"$pkg\"" "$BREWFILE"; then
                fail "package '$pkg' is both a brew formula and an entry in $manifest"
            fi
        done <<EOF
$(active_lines "$manifest")
EOF
    done
}

test_manifests_are_documented() {
    assert_contains 'packages/' "$ROOT_README"
    assert_contains 'apt.txt' "$ROOT_README"
    assert_contains 'dnf.txt' "$ROOT_README"
    # zsh 依赖文档必须指向分层清单，而不是只有 brew/pacman 两列。
    assert_contains 'packages/apt.txt' "$ZSH_README"
    assert_contains 'packages/dnf.txt' "$ZSH_README"
}

test_brewfile_layers_and_entries
test_manifest_format "$APT_MANIFEST"
test_manifest_format "$DNF_MANIFEST"
test_no_cross_channel_overlap
test_manifests_are_documented

printf 'PASS: packages manifest tests\n'
