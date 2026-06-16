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

## 2026-06-16 — 提示词系统全面优化：12 项改进

- 目的：提升提示词系统的执行保障、规则精确性、职责分离和鲁棒性。
- 已做：
  - AGENTS.md：操作前约束长段落拆成 7 个子标题（用户画像/沟通风格/Memory 门控/Memory 读取策略/Trace 读取策略/USER.md SOUL.md/副作用层级确认）。
  - AGENTS.md：新增 Memory 门控——进入 repo-change 前必须确认已读取相关 memory 并引用证据。
  - AGENTS.md：Intent Gate 增加显式声明要求，agent 须在回复开头声明意图层级。
  - AGENTS.md：告警条件精确化，补充排除项（运行时动态值/已知平台差异/有 memory 记录的临时调试）和路径排除（/tmp /var /run）。
  - AGENTS.md：新增"执行中断与回退"小节，覆盖部分完成、同步失败、memory 冲突三种场景。
  - AGENTS.md：验证策略新增降级验证表和按风险等级追加验证表。
  - AGENTS.md：操作前约束内联 USER.md/SOUL.md 核心信息，SOUL.md 改为可选详细参考。
  - SOUL.md：从纯 Tone 扩展为 Communication Protocol，新增"输出格式"和"记录语言"两个小节。
  - organizing_preferences.md：删除与 desktop.md 重复的桌面环境细节（redshift/Linuxbrew/scripts helper），改为引用 desktop.md。
  - CLAUDE.md / copilot-instructions.md：从 1 行薄入口扩展为含最小上下文的入口（仓库性质/权威文件路径/memory 位置）。
  - README.md：提示词系统说明补充 SOUL.md 和 USER.md 的角色描述。
  - repo_docs_test.sh：新增 15 条语义断言覆盖上述全部变更。
- 验证：`./tests/repo_docs_test.sh`、`sh -n tests/repo_docs_test.sh`、`git diff --check` 通过。

## 2026-06-14 — 提示词系统优化：移除 githook，全由 prompt 规则接管

- 目的：消除 USER.md 与 organizing_preferences.md 的重复内容，激活 USER.md / SOUL.md；随后删除 githook 体系，交给 AGENTS.md prompt 规则统一接管验证。
- 已做：
  - 将`记录语言`和`持久化文件读取`从 organizing_preferences.md 合并到 USER.md。
  - 创建后删除 `.githooks/`（pre-commit + pre-push），验证策略由 AGENTS.md 统一管理。
  - AGENTS.md 操作前约束中增加读取 `USER.md` / `SOUL.md` 规则。
  - 更新 `logs/trace.md` 维护规则，归档改由 agent 按 AGENTS.md 执行。
  - 扩展 `tests/repo_docs_test.sh` 断言覆盖全部变更。
- 验证：`./tests/repo_docs_test.sh` 通过。

## 2026-06-15 — niri 快速切换壁纸快捷键

- 已做：新增 `wallpaper-wayland-next`，先结束当前 `swaybg` 再复用 `wallpaper-wayland` 随机选图；在 Ubuntu/Arch 两份 niri 配置中绑定 `Mod+Shift+w`；更新 niri README、安装清单与回归测试。
- 验证：`./tests/niri_wayland_config_test.sh && sh -n .config/scripts/wallpaper-wayland-next tests/niri_wayland_config_test.sh && git diff --check -- .config/scripts/wallpaper-wayland-next install.sh .config/linux/niri/arch_x64/config.kdl .config/linux/niri/ubuntu_x64/config.kdl .config/linux/niri/README.md tests/niri_wayland_config_test.sh logs/trace.md` 通过。

## 2026-06-15 — niri Chrome 视觉效果回归全局

- 已做：移除 Chrome 专属 `opacity 0.72` 与重复背景模糊规则，保留 2/3 默认列宽；README、测试与桌面记忆同步说明 Chrome 透明度/背景模糊跟随全局窗口效果。
- 验证：`./tests/niri_wayland_config_test.sh && sh -n .config/scripts/wallpaper-wayland-next tests/niri_wayland_config_test.sh && git diff --check -- .config/scripts/wallpaper-wayland-next install.sh .config/linux/niri/arch_x64/config.kdl .config/linux/niri/ubuntu_x64/config.kdl .config/linux/niri/README.md tests/niri_wayland_config_test.sh memory/desktop.md logs/trace.md` 通过。

## 2026-06-15 — niri 壁纸目录收窄到 ~/Pictures/wall

- 已做：将 `wallpaper-wayland` 候选目录改为仅 `~/Pictures/wall`；同步 niri README、测试与桌面记忆，避免继续从 `~/Pictures`、系统背景或其它目录回退。
- 验证：`./tests/niri_wayland_config_test.sh`、`sh -n .config/scripts/wallpaper-wayland .config/scripts/wallpaper-wayland-next tests/niri_wayland_config_test.sh`、`git diff --check -- .config/scripts/wallpaper-wayland .config/linux/niri/README.md tests/niri_wayland_config_test.sh memory/desktop.md logs/trace.md` 通过。

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
