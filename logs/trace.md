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

## 2026-07-29 — 低风险小优化批量修复

- 目的：消除 trace.md 超条目违规，并修复 zsh/nvim/picom 三处低风险历史遗留问题。
- 已做：归档 trace.md 6 条旧条目到 `logs/trace-archive/2026-07.md`；删除 zsh `cpp()` 的 strace fallback 死代码（strace 通常未安装、进度条逻辑无效、`set -e` 污染调用者 shell），无 rsync 时回退 `cp -v`，同步 zsh README；修复 nvim `float_trem.lua` 硬编码 `zsh -i`，改用 `vim.o.shell` 跟随用户登录 shell；修复 picom `arch_aarch64.conf` 注释拼写（`form aesthetics` → `visual aesthetics`）；新增 `tests/zsh_functions_test.sh` 与 `tests/nvim_float_trem_test.sh` 静态断言测试。
- 验证：`bash tests/zsh_functions_test.sh`、`bash tests/nvim_float_trem_test.sh`、`bash tests/zsh_path_test.sh`、`bash tests/picom_config_test.sh`、`bash tests/repo_docs_test.sh` 均通过；`zsh -n`/`luajit loadfile`/`bash -n`/`git diff --check` 全部 OK。
- 后续：未同步 live、未重载服务、未提交推送；zsh 模块函数级测试覆盖仍不足（`cpg`/`mvg`/`mkdirg`/`y` 等），可作为后续单独切片。

## 2026-07-29 — Niri workspace-wrap-around 回退与 waybar battery dead config 清理

- 目的：补齐 workspace 循环切换肌肉记忆，清理 waybar 中未启用的 battery 模块死配置。
- 已做：尝试在 `common.kdl` 的 `layout {}` 块新增 `workspace-wrap-around`，但 `niri validate` 报 `unexpected node 'workspace-wrap-around'`——niri 26.04 不支持此选项（这是 i3/hyprland 概念，非 niri 原生），已回滚该改动。删除 waybar `config` 中未在 `modules-right` 启用的 `battery` 模块定义，以及 `style.css` 中对应的 `#battery` 样式（ubuntu_x64 是 desktop 无电池）；新增 `test_waybar_drops_dead_battery_module_on_desktop_platform` 回归断言。修复 `test_niri_config_exists_and_validates_when_available`：niri 从 nix profile 安装时，`niri validate` 子命令在非 nix shell 下会因 RUNPATH 解析差异报 `libstdc++.so.6` 加载失败；测试现在会先尝试直接调用，失败后从 niri 二进制的 RUNPATH 提取 gcc-lib 路径作为 `LD_LIBRARY_PATH` 重试。
- 验证：`bash tests/niri_wayland_config_test.sh`（除历史遗留的 `install_copies_wayland_files_when_niri_exists_outside_wayland` 环境问题外）通过；`niri validate -c .config/linux/niri/ubuntu_x64/config.kdl` 用 `LD_LIBRARY_PATH` 修复后返回 `config is valid`；`bash tests/repo_docs_test.sh`、`git diff --check` 通过。
- 后续：未同步 live、未重载 niri、未提交推送。教训：推荐 niri 配置选项前必须先用 `niri validate` 验证，不能仅凭其它 WM 的概念类推。

## 2026-07-29 — Niri 原生环境变量/光标/动画配置

- 目的：用 niri 原生 `environment {}`/`cursor {}`/`animations {}` 块提升 Wayland 会话启动一致性与视觉过渡。
- 已做：在 `common.kdl` 顶部新增 `environment {}` 块（QT_IM_MODULE/XMODIFIERS/SDL_IM_MODULE/GLFW_IM_MODULE/INPUT_METHOD/LC_CTYPE/XCURSOR_SIZE，GTK_IM_MODULE 故意不设置）和 `cursor { xcursor-size 32 }`；将空 `animations {}` 细化为 workspace-switch/window-open/window-close/window-resize 四组 spring 参数；同步 README 与 niri 回归测试断言。
- 验证：`niri validate -c .config/linux/niri/ubuntu_x64/config.kdl`、`./tests/niri_wayland_config_test.sh`、`./tests/repo_docs_test.sh`、`git diff --check` 均通过。
- 后续：未同步 live、未重载 niri、未提交推送；原计划的 `workspace-auto-back-forth` 经查 niri 26.04 不支持此 layout 选项，已回退，如需 "go back" 可后续用 `focus-workspace-previous` bind 替代。
