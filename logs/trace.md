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

## 2026-07-27 — Niri 快捷键精简与防连发

- 目的：减少重复的 workspace/列导航快捷键，并避免一次性桌面动作因长按重复触发。
- 已做：移除 `Page_Up/Page_Down` 及其 Shift workspace 组合和重复的 `Mod+Alt+h/l`；增加 `Mod+Tab` 切换到焦点历史中的上一个窗口；为启动程序、壁纸、overview、退出、F1 截图与关闭显示器增加 `repeat=false`；修正列宽注释，并为浮动、列标签和窗口并入/移出操作补充热键面板中文说明；同步 Niri README、回归测试与长期偏好。
- 验证：`bash -n tests/niri_wayland_config_test.sh`、`./tests/niri_wayland_config_test.sh`、`niri validate -c .config/linux/niri/ubuntu_x64/config.kdl`、`./tests/repo_docs_test.sh` 与 `git diff --check` 均通过。
- 后续：按当前使用习惯暂不新增列内窗口聚焦绑定；用户已通过 `./install.sh` 同步 live，仓库与 live Niri 配置比对一致；未手动重载 niri，随本轮提交推送。

## 2026-07-27 — Niri 列位置与锁屏快捷键调整

- 目的：用更顺手的 `Mod+Shift+h/l` 调整同一 workspace 中窗口列的位置，并避开该组合与锁屏的冲突。
- 已做：将移动列绑定从 `Mod+Ctrl+h/l` 改为 `Mod+Shift+h/l`，将锁屏从 `Mod+Shift+l` 改为 `Mod+Alt+l`；同步 Niri README、回归测试与长期偏好。
- 验证：待本轮配置修改后运行 Niri 回归、配置验证、文档测试和 `git diff --check`。
- 后续：未同步 live、未重载 niri、未提交推送。
