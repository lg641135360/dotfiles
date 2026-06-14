#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

ROOT_README=$REPO_ROOT/README.md
X11_README=$REPO_ROOT/.config/linux/x11/README.md
LINUX_BREWFILE=$REPO_ROOT/.config/linux/Brewfile
GIT_MEMORY=$REPO_ROOT/memory/git.md
AGENTS_DOC=$REPO_ROOT/AGENTS.md
COPILOT_INSTRUCTIONS=$REPO_ROOT/.github/copilot-instructions.md
CLAUDE_INSTRUCTIONS=$REPO_ROOT/CLAUDE.md

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

# Prompt / agent instruction system docs
assert_contains '完整行为协议定义在 `AGENTS.md`' "$COPILOT_INSTRUCTIONS"
assert_contains '遵从 AGENTS.md 的约束' "$CLAUDE_INSTRUCTIONS"
assert_contains '权威行为协议' "$ROOT_README"
assert_contains '.github/copilot-instructions.md' "$ROOT_README"
assert_contains 'CLAUDE.md' "$ROOT_README"
assert_contains '.omx/' "$ROOT_README"
assert_contains '本地工作流状态' "$ROOT_README"
assert_contains '不提交' "$ROOT_README"
assert_contains '先读 `memory/organizing_preferences.md`' "$AGENTS_DOC"
assert_contains '再按任务路径或关键词读取对应模块' "$AGENTS_DOC"
assert_contains '默认不要全量读取所有模块 memory' "$AGENTS_DOC"
assert_contains '只读评估不更新 `logs/trace.md`' "$AGENTS_DOC"

# User profile — key facts
assert_contains 'TypeScript 优先' "$REPO_ROOT/USER.md"

# organizing_preferences — removed duplicate sections
assert_not_contains '## 记录语言' "$REPO_ROOT/memory/organizing_preferences.md"
assert_not_contains '## 持久化文件读取' "$REPO_ROOT/memory/organizing_preferences.md"

# USER.md / SOUL.md 引用与内容
assert_contains 'USER.md' "$REPO_ROOT/AGENTS.md"
assert_contains 'SOUL.md' "$REPO_ROOT/AGENTS.md"
assert_contains 'Tone' "$REPO_ROOT/SOUL.md"
assert_not_contains 'Personality' "$REPO_ROOT/SOUL.md"
assert_not_contains 'Identity' "$REPO_ROOT/SOUL.md"
assert_contains 'Key Facts' "$REPO_ROOT/USER.md"
assert_not_contains 'Name' "$REPO_ROOT/USER.md"
assert_not_contains 'Timezone' "$REPO_ROOT/USER.md"
assert_not_contains 'Preferences' "$REPO_ROOT/USER.md"
assert_not_contains 'Context' "$REPO_ROOT/USER.md"

# githook 已删除，验证由 prompt 规则接管
assert_file_not_exists "$REPO_ROOT/.githooks/pre-commit"
assert_file_not_exists "$REPO_ROOT/.githooks/pre-push"

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
