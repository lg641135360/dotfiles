# Trace

> 本文件只记录实际发生过的修改、验证证据与后续线索，不定义长期规则；若某条经验已稳定复用，应提升到 `AGENTS.md` 或 `memory/`。

## 维护规则

- 本文件总长度建议不超过 150 行。
- 最近变更摘要（按 `## YYYY-MM-DD` 标题计）最多保留 5 条。
- 归档通过 `scripts/archive_trace.ts` 手动触发，或由 agent 按 `AGENTS.md` 验证策略在提交前执行：
  ```bash
  npm --prefix scripts run archive-trace -- --dry-run   # 预览
  npm --prefix scripts run archive-trace --              # 执行
  ```
- 旧条目按月份归档到 `logs/trace-archive/YYYY-MM.md`。
- 默认任务不得读取 `logs/trace-archive/` 全文。
- 只有用户明确要求，或任务确实依赖历史背景时，才按需读取相关月份归档。
- 长期有效的规则、方法论或决策边界，不应长期停留在 `logs/trace.md`；若跨多次任务仍有效，应提升到对应 `memory/` 规则文件。

## 2026-06-14 — 提示词系统优化：移除 githook，全由 prompt 规则接管

- 目的：消除 USER.md 与 organizing_preferences.md 的重复内容，激活 USER.md / SOUL.md；随后删除 githook 体系，交给 AGENTS.md prompt 规则统一接管验证。
- 已做：
  - 将`记录语言`和`持久化文件读取`从 organizing_preferences.md 合并到 USER.md。
  - 创建后删除 `.githooks/`（pre-commit + pre-push），验证策略由 AGENTS.md 统一管理。
  - AGENTS.md 操作前约束中增加读取 `USER.md` / `SOUL.md` 规则。
  - 更新 `logs/trace.md` 维护规则，归档改由 agent 按 AGENTS.md 执行。
  - 扩展 `tests/repo_docs_test.sh` 断言覆盖全部变更。
- 验证：`./tests/repo_docs_test.sh` 通过。

## 2026-06-13 — Brew 大清理 + patchelf 避雷

- 清理 neofetch/rofi/mesa/xinput + unar/meson，brew autoremove 清理 66+15 个孤儿
- Brewfile 删除 git/rsync/zsh/lazygit/alacritty（系统已提供或不必要）
- env.zsh 添加 `HOMEBREW_BOTTLE_DOMAIN` USTC 镜像
- 修复 ARM64 bottle 损坏：`patchelf --force-rpath` 展开 `@@HOMEBREW_PREFIX@@` 占位符
- 根因：brew 自带的 Ruby gem `patchelf` v1.5.2 在 ARM64 上有 bug
- brew 的 patchelf 0.18.0 写操作 segfault，已卸载，改用系统 `/usr/bin/patchelf` 0.14.3
- 效果：150→62 formula，5.6G→4.7G，leaves 仅 8 个
- 稳定知识已归档到 `memory/repo/brew-setup.md`、`memory/dingtalk.md`、`memory/desktop.md`
- 验证：lsd/tmux/nvim 正常运行；`tests/repo_docs_test.sh` 通过
- 提交：`046089d`（chore: cleanup brew packages and update mirror config）

## 2026-06-11 — 提示词系统基线化

- 目的：按提示词系统评估结果收紧仓库 agent 行为协议，减少 memory/trace 读取摩擦，并把本地 OMX 工作流层与公共提示词入口文档化。
- 已做：更新 `AGENTS.md`，将 memory 读取改为先读 `memory/organizing_preferences.md`、再按任务路径或关键词读取对应模块，默认不全量读取所有模块，并明确只读评估不更新 `logs/trace.md`；更新根 `README.md`，新增“提示词系统”说明，记录 `AGENTS.md` 是权威协议、`.github/copilot-instructions.md` 与 `CLAUDE.md` 只是薄入口，`.omx/` 是已忽略的本地工作流状态/计划产物目录且默认不提交；扩展 `tests/repo_docs_test.sh`，用回归断言保护上述入口与文档说明。本轮只修改仓库文件，没有同步 live 配置、没有重载运行态，准备提交但不推送。
- 验证：`./tests/repo_docs_test.sh && sh -n tests/repo_docs_test.sh && git diff --check` 通过；`./tests/run.sh docs` 通过；`git status --short` 仅显示 `AGENTS.md`、`README.md`、`tests/repo_docs_test.sh` 和本 trace 变更。
- 后续：若后续继续优化提示词系统，可考虑单独检查是否需要把更多稳定的 trace 经验提升到 `memory/`，但不要把 `.omx/` 纳入版本控制。

## 2026-06-09 — 仓库整理收口

- fcitx/Wayland GTK_IM_MODULE 排查（知识 → `memory/desktop.md`）
- 重写 README 目录树、补 6 个 README、删除 xmobar/xmonad/dunst 残留
- 修复 wallpaper-wayland 候选目录、Waybar 测试护栏
- 修正 README 目录树层级、补测试护栏、6 个新 README 纳入 Git 跟踪
- 未提交推送（当时为中间状态）

## 2026-06-05 — niri 窗口规则调整

- niri: 钉钉浮动、Cherry Studio/Chrome 默认 0.66667 列宽、VS Code 默认 1.0
