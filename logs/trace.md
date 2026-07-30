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

## 2026-07-30 — Waybar CPU/内存模块按负载阈值变色

- 目的：让 CPU/内存使用率超过阈值时在状态栏自动变色警示，符合"少量图标化文字降噪"偏好（平时保持柔和色，高负载才警示）。
- 已做：`.config/linux/waybar/config` 的 `cpu` 模块新增 `states: { warning: 70, critical: 90 }`，`memory` 模块新增 `states: { warning: 80, critical: 95 }`；`.config/linux/waybar/style.css` 在 `#cpu`（peach）/`#memory`（teal）基础色后新增 `#cpu.warning`/`#memory.warning`（yellow）和 `#cpu.critical`/`#memory.critical`（red）状态色，使用 Catppuccin Mocha token。
- 行为变化：CPU ≥70% 变黄、≥90% 变红；内存 ≥80% 变黄、≥95% 变红；低于阈值保持原色（CPU=peach，内存=teal）。
- 验证：`jq empty .config/linux/waybar/config` 通过；`./tests/niri_wayland_config_test.sh` 通过（`PASS: niri Wayland config tests`）；`git diff --check` 通过。IDE 的 CSS 诊断报错是 GTK `@define-color`/`alpha(@var)` 扩展语法不被标准 CSS 解析器识别，原文件就有，非本轮引入。
- live 同步：`~/.config/waybar/config` 已同步；`~/.config/waybar/style.css` 因 sandbox 路径白名单未含该文件，未同步，需用户手动执行 `cp .config/linux/waybar/style.css ~/.config/waybar/style.css`；waybar 不支持热重载，同步后需 `pkill waybar` 并重新拉起。
- 后续：改动尚未提交推送。

## 2026-07-30 — Niri focus-ring urgent-color 与 cursor hide-when-typing

- 目的：启用两项此前未开启的 niri 实用配置——紧急窗口视觉高亮、打字时自动隐藏鼠标。
- 已做：`common.kdl` 的 `focus-ring` 块新增 `urgent-color "#f38ba8"`（Catppuccin Mocha red），用于 IM 闪动等紧急窗口的焦点环高亮；`cursor` 块新增 `hide-when-typing`，键盘输入时自动隐藏鼠标光标；同步更新 niri README 的「光标」条目并新增「焦点环」条目说明三种颜色（活动蓝/非活动灰/紧急红）。
- 行为变化：紧急窗口（如消息应用闪动）焦点环变为红色，区别于普通活动窗口的蓝色；键盘打字时鼠标光标自动隐藏，停止输入后恢复显示。
- 验证：`LD_LIBRARY_PATH=/nix/store/0p8b2lqk47fvxm9hc6c8mnln5l8x51q1-gcc-14.3.0-lib/lib niri validate -c .config/linux/niri/ubuntu_x64/config.kdl` 返回 `config is valid`；`./tests/niri_wayland_config_test.sh` 通过（`PASS: niri Wayland config tests`）；`git diff --check` 通过。
- live 同步：用户反馈 `hide-when-typing` 未生效，排查发现仓库 `cursor` 块改动被外部还原且 live 从未同步。重新应用仓库改动后，`cp .config/linux/niri/common.kdl ~/.config/niri/common.kdl` 完成 live 同步，`diff` 确认 live 与仓库一致；niri 自动热重载，`cursor`/`focus-ring` 改动即时生效，无需重启会话。

## 2026-07-29 — Mod+H/L 扩展为跨显示器切列

- 目的：让 `Mod+H/L` 在到边界后自然跨到左/右显示器，减少双屏下 `Mod+A/D` 的额外按键。
- 已做：`common.kdl` 的 `Mod+H/L` 从 `focus-column-left-or-last/right-or-first`（屏内循环）改为 `focus-column-or-monitor-left/right`（到边界后切到左/右显示器）；`Mod+WheelScrollLeft/Right` 同步改为 `focus-column-or-monitor-left/right`，保持滚轮与键盘行为一致；更新 `common.kdl` 注释说明新行为；更新 niri README 快捷键映射表和导航说明段落（注明 `Mod+a/d` 仍可作为「显式只切显示器」的补充）；更新 `tests/niri_wayland_config_test.sh` 的 `Mod+H/L` 断言匹配新 action。
- 行为变化：`Mod+H/L` 不再屏内循环到首/末列，而是跨到相邻显示器；单显示器时停在最左/最右列不循环。
- 验证：`LD_LIBRARY_PATH=/nix/store/.../gcc-14.3.0-lib/lib niri validate -c .config/linux/niri/ubuntu_x64/config.kdl` 返回 `config is valid`；`bash tests/niri_wayland_config_test.sh` 通过（`PASS: niri Wayland config tests`）；`git diff --check` 通过。
- 后续：未同步 live、未重载 niri；已提交推送（commit 见 `git log`）。

## 2026-07-29 — Launcher 美化：fuzzel blur + 选中色 + 图标主题

- 目的：提升应用启动器视觉体验，统一 fuzzel 与 rofi fallback 的配色和图标风格。
- 已做：niri `common.kdl` 新增 `layer-rule { match namespace="^fuzzel$" }` 启用 `background-effect { blur true }`，启动器弹出时背景模糊；fuzzel.ini 选中项配色从 `#2a2d3a`/`#ffffff` 改为 `#89b4fa`/`#1e1e2e`（Catppuccin Mocha 蓝），与 rofi 主题对齐；fuzzel.ini 新增 `icon-theme=Papirus-Dark`，与 rofi 一致；同步更新 fuzzel README、niri README 和 niri 测试断言。
- 验证：`niri validate` 返回 `config is valid`；`fuzzel --check-config` 因环境 libstdc++ RPATH 问题无法运行（与 niri 同源问题）；`bash tests/niri_wayland_config_test.sh` 通过（除历史遗留 install 环境问题）；`bash tests/repo_docs_test.sh` 通过；`git diff --check` 通过。
- 后续：未同步 live、未重载 niri、未提交推送。

## 2026-07-29 — Niri 列循环导航与窗口高度调整

- 目的：补齐列循环切换和键盘窗口高度调整，提升键盘操作完整性。
- 已做：`common.kdl` 的 `Mod+H/L` 从 `focus-column-left/right` 改为 `focus-column-left-or-last/right-or-first`（到边界后循环到首/末列），`Mod+WheelScrollRight/Left` 同步改为循环版本；新增 `Mod+Shift+Minus/Equal` 绑定 `set-window-height "-10%"/"+10%"`，补齐键盘调整窗口高度的缺口；`Mod+J/K` 从 `focus-workspace-down/up` 改为 `focus-window-or-workspace-down/up`（优先切同 workspace 内窗口，到边界后切 workspace，对齐 Awesome 肌肉记忆）；`Mod+Shift+H/L` 从 `move-column-left/right` 改为 `move-column-left-or-to-monitor-left/right-or-to-monitor-right`（到边界后自动移到下一个显示器），并删除冗余的 `Mod+Shift+A/D`（原 `move-column-to-monitor-left/right`，功能已被 `Mod+Shift+H/L` 覆盖）；更新注释和 README 快捷键表及导航说明；更新 `tests/niri_wayland_config_test.sh` 断言匹配新 action 并新增 `Mod+Shift+A/D` 不存在断言。
- 验证：`niri validate -c .config/linux/niri/ubuntu_x64/config.kdl` 返回 `config is valid`；`bash tests/niri_wayland_config_test.sh` 通过；`bash tests/repo_docs_test.sh` 通过；`git diff --check` 通过。所有改动均先用 `niri validate` 验证 action 存在且语法正确。
- 后续：未同步 live、未重载 niri、未提交推送。`Mod+J/K` 与 `Mod+Shift+H/L` 行为变更需用户实际使用后确认是否符合预期。
