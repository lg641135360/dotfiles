#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

ROOT_README=$REPO_ROOT/README.md
X11_README=$REPO_ROOT/.config/linux/x11/README.md
GIT_MEMORY=$REPO_ROOT/memory/git.md

assert_contains '- alacritty' "$ROOT_README"
assert_contains '- Claude Code statusline' "$ROOT_README"
assert_contains '- X11 / Xresources' "$ROOT_README"
assert_not_contains '- kitty' "$ROOT_README"
assert_not_contains '- zed settings' "$ROOT_README"

assert_file_exists "$X11_README"
assert_file_not_exists "$REPO_ROOT/.config/linux/x11/REAME.md"
assert_contains '# X11 配置文件' "$X11_README"

if git -C "$REPO_ROOT" ls-files --error-unmatch .config/linux/x11/REAME.md >/dev/null 2>&1; then
    fail 'tracked X11 README should not use the misspelled REAME.md filename'
fi

assert_contains 'core.editor = vim' "$GIT_MEMORY"
assert_not_contains 'core.editor = nvim' "$GIT_MEMORY"

printf 'PASS: repo docs tests\n'
