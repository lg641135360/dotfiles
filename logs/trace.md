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

## 2026-07-01 — Waybar 一体化 Catppuccin 视觉精修

- 目的：按用户要求参考 `catppuccin/waybar`，把 niri 主线 Waybar 从三段独立胶囊改为更有一体感的连续顶栏，同时保持现有轻量模块结构。
- 已做：
  - 新增 `.config/linux/waybar/mocha.css`，提供 Catppuccin Mocha GTK CSS 颜色变量；`style.css` 改为导入 token，并将整条 `window#waybar` 设为半透明 Mocha 顶栏。
  - `.config/linux/waybar/config`：缩短 bar 高度和窗口标题长度；网络、CPU、内存、音量改为图标化显示并加入宽度约束；按用户要求不加标题 rewrite。
  - `.config/scripts/wayland-autostart`：移除 `pot` 默认自启动，保留常用托盘与挂载辅助服务。
  - 更新 `.config/linux/waybar/README.md`、`tests/niri_wayland_config_test.sh` 和 `memory/desktop.md`，记录一体化顶栏偏好与回归断言。
- 运行态：用户反馈从工具 shell 重启后 Waybar 退出；改用 `niri msg action spawn -- waybar` 从 niri 会话内恢复，复核进程 `3435564 waybar` 存活且两个输出的 top layer 均有 `Namespace: "waybar"`。
- 验证：`jq empty .config/linux/waybar/config` 通过；`./tests/niri_wayland_config_test.sh` 通过；`git diff --check` 通过。
- 后续：本轮未执行 install/sync；live `~/.config/waybar` 与仓库一致，Waybar 已从 niri 会话内重启；未提交推送。trace 标题数量继续超过建议上限，提交前应运行归档。

## 2026-06-25 — Brewfile 精简（macOS 移除系统自带）+ Linux 安全筛选注释 + SETUP.md 引用强化

- 目的：按用户三点要求——macOS Brewfile 仅保留非系统默认必要第三方（移除 zsh/git）；Linux Brewfile 明确安全筛选原则（排除 redshift 等不适合 brew 的）；SETUP.md 明确引用两个 Brewfile 路径/适用系统/安装命令。
- 已做：
  - `.config/macos/Brewfile`：移除 `brew "git"`（CLT 自带）、`brew "zsh"`（Catalina+ 默认 shell）；顶部新增筛选原则注释说明排除项与原因。
  - `.config/linux/Brewfile`：重写顶部注释，明确安全筛选原则——仅收录来源可靠的纯用户级 CLI 工具；列出不适合 brew 的类别（桌面/系统服务/输入法/系统级工具如 redshift 有系统集成需求/构建库/字体）及示例 apt 命令。包列表不变（bat/fd/fzf/lsd/neovim/ripgrep/tmux/yazi/zoxide 均为安全 CLI 工具）。
  - `SETUP.md` 3.2.4 Linux Homebrew：新增"适用系统 / Brewfile 路径 / 筛选原则"三行，命令拆分为安装 Linuxbrew + bundle 两步并加注释。
  - `SETUP.md` 3.4 macOS：新增"适用系统 / Brewfile 路径 / 筛选原则"三行；第 1 步注释补充 CLT 自带 git；第 5 步 `chsh -s /opt/homebrew/bin/zsh` 改为 `chsh -s /bin/zsh`（brew zsh 已移除，用系统自带）；末尾描述移除 git/zsh，更新包列表。
- 验证：`git diff --check` 通过；`./tests/run.sh docs` 通过（repo docs + git_config PASS）。
- 后续：未同步 live `~/.config`，未提交推送。macOS Brewfile 保留 `rsync`（brew 3.x 提供 `--info=progress2`，zsh cpp 函数依赖，系统自带 2.6.9 不支持），如不需要 cpp 进度条可后续移除。trace 已累积 9 条标题，提交前必须运行 `npm --prefix scripts run archive-trace` 归档。

## 2026-06-25 — SETUP.md 补全 zsh 配置遗漏 + Brewfile 移除 zsh 插件

- 目的：参考 zsh 配置，补全 SETUP.md 中遗漏的 zsh 相关内容；同步修改 macOS Brewfile，移除与 zinit 重复的三个 zsh 插件。
- 已做：
  - `SETUP.md` 2.1：新增"zinit 加载的完整插件清单"表（powerlevel10k + 7 插件 + OMZP 片段）；新增"其他 zsh 配置要点"表（ZDOTDIR、tmuxifier 可选安装、fzf --zsh 集成版本要求、Conda /opt/miniforge 路径与懒加载、Homebrew USTC 镜像、EDITOR/TERMINAL 环境变量）；更新"macOS Brewfile 已移除三个 zsh 插件"说明；更新 3.4 macOS Brewfile 描述（不再含 zsh 增强插件，改为说明由 zinit 加载）。
  - `.config/macos/Brewfile`：移除 `brew "zsh-completions"` / `brew "zsh-autosuggestions"` / `brew "zsh-syntax-highlighting"` 三行，统一由 zinit 从 zsh-users 官方仓库加载，避免重复加载与补全冲突。
- 验证：`git diff --check` 通过；`./tests/run.sh docs` 通过（repo docs + git_config PASS）。
- 后续：未同步 live `~/.config`，未提交推送。trace 当前 8 条标题，明显超 5 条上限，提交前需运行 `npm --prefix scripts run archive-trace` 归档。

## 2026-06-25 — SETUP.md 二次优化：aarch64 X11 主要、显示参数、Claude/Codex npm、zsh 插件 zinit

- 目的：按用户四点要求修正并补充 SETUP.md——aarch64 上 X11 仍为主要图形显示服务器（修正上一轮把 aarch64 也归为 niri 首选的过度泛化）；移除硬件建议改为 aarch64 默认显示配置说明；Claude Code/Codex 优先 npm 安装；明确三个 zsh 插件用 zinit 安装。
- 已做：
  - `SETUP.md` 1.1 兼容性表：aarch64 恢复为"X11 + AwesomeWM 仍为主要图形显示服务器"；桌面环境策略引言改为按架构区分（x86_64 niri 首选 / aarch64 X11 主要 / macOS AeroSpace）。
  - `SETUP.md` 1.2：移除硬件建议，替换为 aarch64 默认显示配置表（主屏 2880x1800@120Hz 左侧、外接屏右侧、Xft.dpi=192 即 2x、XCURSOR_SIZE=48、触摸板、IME 环境变量、One Dark 主题），并附 x86_64 各平台 DPI/scale 对照。
  - `SETUP.md` 2.1：在表格后新增 Claude Code/Codex 优先 npm 安装说明（brew 走 GitHub 国内无代理易失败）；新增 zsh 三插件（zsh-completions/autosuggestions/syntax-highlighting）推荐 zinit 从官方仓库安装的来源表，不建议额外用 brew/apt 装。
  - `SETUP.md` 2.2：标题移除"维护模式"，提示改为按架构区分（aarch64 必装 / x86_64 维护模式仅回退）。
  - `SETUP.md` 3.2.1：Ubuntu X11 安装块注释改为按架构区分（aarch64 必装 / x86_64 维护模式）。
  - `memory/desktop.md`：niri 首选决策改为按架构区分，消除与"aarch64 X11 主要"的矛盾。
- 验证：`git diff --check` 通过；`./tests/run.sh docs` 通过（repo docs + git_config PASS）。
- 后续：未同步 live `~/.config`，未提交推送。macOS Brewfile 中 zsh 三插件 brew 版未删除（用户只要求文档说明，未要求改配置），如遇补全冲突可后续清理。

## 2026-06-25 — SETUP.md 优化：awesome+x11 降级维护模式、移除 lazygit、明确跨系统包管理策略

- 目的：按用户三点要求优化 SETUP.md 与相关配置——标记 awesome+x11 为维护模式、niri+wayland 为首选；精简 lazygit 等低频工具；明确 macOS 全 brew、Linux 分层（桌面/系统/库走 apt/pacman、CLI 走 brew）的包管理策略。
- 已做：
  - `SETUP.md`：1.1 兼容性表标记 niri+wayland 首选、awesome+x11 维护模式并加桌面环境策略引言；2.2 节标题加维护模式标记与过时提示；2.1 移除 lazygit 行；第 3 节开头新增跨系统包管理策略说明；3.2/3.3 Linux 安装流程重构（CLI 工具从 apt/pacman 移出改由 brew，移除 lazygit，修正 Ubuntu X11 包名为 `x11-xserver-utils`，X11 块标注维护模式）；3.2.4 Homebrew 从"可选"改"CLI 工具推荐"；3.4 macOS 描述移除 lazygit。
  - `.config/macos/Brewfile`：移除 `brew "lazygit"`。
  - `.config/shared/zsh/aliases.zsh`：移除 `lg` 别名（条件判断块）。
  - `.config/shared/zsh/README.md`：移除可选依赖表 lazygit 行与别名表 `lg` 行。
  - `memory/desktop.md`：niri 决策从"并行试用、保持可回退"演进为"首选，awesome 进入维护模式"。
  - `memory/organizing_preferences.md`：新增跨系统包管理策略条目。
- 验证：`grep lazygit SETUP.md` 无残留；`git diff --check` 通过；`bash -n .config/shared/zsh/aliases.zsh` 通过；`./tests/run.sh docs` 通过（repo docs + git_config 测试 PASS）。
- 后续：用户提到的"包括但不限于 lazygit 等"低频工具，本轮只处理明确点名的 lazygit，如需继续精简其他工具请用户指定；未同步 live `~/.config`，未提交推送。trace 当前 6 条 `##` 标题，超出 5 条上限，提交前可运行 `npm --prefix scripts run archive-trace` 归档最旧条目。
