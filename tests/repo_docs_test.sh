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
# Structure tree must list entries added in Batch G sync.
assert_contains 'starship.toml' "$ROOT_README"
assert_contains 'Brewfile' "$ROOT_README"
assert_contains 'desktop-entries/' "$ROOT_README"
assert_contains 'foot/' "$ROOT_README"
assert_contains 'defaults.sh' "$ROOT_README"
assert_contains '├── scripts/' "$ROOT_README"
assert_contains 'TypeScript 工具' "$ROOT_README"
assert_contains '├── tests/' "$ROOT_README"
assert_not_contains '│   ├── tests/' "$ROOT_README"
assert_not_contains '- kitty' "$ROOT_README"
assert_not_contains '- zed settings' "$ROOT_README"
assert_file_not_exists "$REPO_ROOT/SETUP.md"
assert_contains '不会自动安装桌面软件' "$ROOT_README"
assert_contains '不判断当前会话类型' "$ROOT_README"

# Test runner docs
assert_contains './tests/run.sh' "$ROOT_README"
assert_contains 'tests/run.sh docs' "$ROOT_README"
assert_contains 'tests/run.sh awesome' "$ROOT_README"

# Prompt / agent instruction system docs
assert_contains '完整行为协议定义在 `AGENTS.md`' "$COPILOT_INSTRUCTIONS"
# CLAUDE.md is gitignored, so only the README reference to it is asserted here.
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

# 可追溯/撤回规则（回滚锚点）
assert_contains '*.backup.<时间戳>' "$AGENTS_DOC"
assert_contains '一轮任务一个 commit' "$AGENTS_DOC"
assert_contains '回滚信息' "$AGENTS_DOC"
assert_contains 'backup 快照路径' "$AGENTS_DOC"
assert_contains '保留 3 份' "$AGENTS_DOC"
assert_contains '恢复命令' "$AGENTS_DOC"
assert_contains '回滚信息' "$REPO_ROOT/logs/trace.md"
assert_contains '恢复命令' "$REPO_ROOT/logs/trace.md"

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

# AGENTS.md memory index must match the actual memory/*.md set (excluding
# organizing_preferences.md which is the entry point, not a module file).
# Drift here means new modules are silently unreadable because the agent
# doesn't know to read them.
agents_index=$(grep -oE 'awesome\.md|nvim\.md|tmux\.md|rofi\.md|alacritty\.md|desktop\.md|niri\.md|waybar\.md|git\.md|codex\.md|dingtalk\.md|foot\.md' "$AGENTS_DOC" | sort -u)
actual_modules=$(ls "$REPO_ROOT"/memory/*.md 2>/dev/null | xargs -n1 basename | grep -vx 'organizing_preferences.md' | sort -u)
[ "$agents_index" = "$actual_modules" ] ||
    fail "AGENTS.md memory index drifts from memory/*.md: expected [$actual_modules], got [$agents_index]"

# organizing_preferences.md must list the same module set as AGENTS.md.
org_index=$(grep -oE 'awesome\.md|nvim\.md|tmux\.md|rofi\.md|alacritty\.md|desktop\.md|niri\.md|waybar\.md|git\.md|codex\.md|dingtalk\.md|foot\.md' "$REPO_ROOT/memory/organizing_preferences.md" | sort -u)
[ "$org_index" = "$actual_modules" ] ||
    fail "organizing_preferences.md memory index drifts from memory/*.md: expected [$actual_modules], got [$org_index]"

# G5/G6: README files for tooling directories.
assert_file_exists "$REPO_ROOT/scripts/README.md"
assert_contains 'archive_trace' "$REPO_ROOT/scripts/README.md"
assert_file_exists "$REPO_ROOT/.config/linux/desktop-entries/README.md"
assert_contains 'browser-wayland' "$REPO_ROOT/.config/linux/desktop-entries/README.md"

printf 'PASS: repo docs tests\n'
