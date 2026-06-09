#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

ROOT_README=$REPO_ROOT/README.md
X11_README=$REPO_ROOT/.config/linux/x11/README.md
LINUX_BREWFILE=$REPO_ROOT/.config/linux/Brewfile
GIT_MEMORY=$REPO_ROOT/memory/git.md

# Root README — new structure format
assert_contains 'shared/' "$ROOT_README"
assert_contains 'linux/' "$ROOT_README"
assert_contains 'macos/' "$ROOT_README"
assert_contains 'tests/' "$ROOT_README"
assert_contains 'tools/' "$ROOT_README"
assert_contains '├── .config/' "$ROOT_README"
assert_contains '│   │   ├── nvim/' "$ROOT_README"
assert_contains '│   │   ├── awesome/' "$ROOT_README"
assert_contains '│   │   ├── niri/' "$ROOT_README"
assert_contains '├── tests/' "$ROOT_README"
assert_not_contains '│   ├── tests/' "$ROOT_README"
assert_not_contains '- kitty' "$ROOT_README"
assert_not_contains '- zed settings' "$ROOT_README"

# Test runner docs
assert_contains './tests/run.sh' "$ROOT_README"
assert_contains 'tests/run.sh docs' "$ROOT_README"
assert_contains 'tests/run.sh awesome' "$ROOT_README"

# X11 README
assert_file_exists "$X11_README"
assert_file_not_exists "$REPO_ROOT/.config/linux/x11/REAME.md"
assert_contains '# X11 配置文件' "$X11_README"

if git -C "$REPO_ROOT" ls-files --error-unmatch .config/linux/x11/REAME.md >/dev/null 2>&1; then
    fail 'tracked X11 README should not use the misspelled REAME.md filename'
fi

# New READMEs
assert_file_exists "$REPO_ROOT/.config/scripts/README.md"
assert_file_exists "$REPO_ROOT/.config/shared/ssh/README.md"
assert_file_not_exists "$REPO_ROOT/.config/linux/dunst/README.md"
assert_file_not_exists "$REPO_ROOT/.config/linux/dunst"
assert_file_exists "$REPO_ROOT/.config/linux/mako/README.md"
assert_file_exists "$REPO_ROOT/.config/linux/fuzzel/README.md"
assert_file_exists "$REPO_ROOT/.config/linux/waybar/README.md"
assert_file_exists "$REPO_ROOT/.config/linux/xdg-desktop-portal/README.md"
assert_file_not_exists "$REPO_ROOT/.config/linux/xmobar/README.md"
assert_file_not_exists "$REPO_ROOT/.config/linux/xmonad/README.md"
assert_file_not_exists "$REPO_ROOT/.config/linux/xmobar"
assert_file_not_exists "$REPO_ROOT/.config/linux/xmonad"

# Removed Linux desktop modules should not remain in install docs.
assert_not_contains 'dunst' "$LINUX_BREWFILE"

# Scripts README content
assert_contains 'lock' "$REPO_ROOT/.config/scripts/README.md"
assert_contains 'dingtalk-wayland' "$REPO_ROOT/.config/scripts/README.md"

# Git memory
assert_contains 'core.editor = vim' "$GIT_MEMORY"
assert_not_contains 'core.editor = nvim' "$GIT_MEMORY"

printf 'PASS: repo docs tests\n'
