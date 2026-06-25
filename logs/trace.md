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

## 2026-06-24 — zsh PATH 支持本地 Node current npm 全局 CLI

- 目的：修复 `npm install -g oh-my-codex` 后 `omx` 已安装在 `/home/rikoo/.local/opt/node-current/bin` 但 zsh 中 `command not found` 的问题。
- 已做：在 `.config/shared/zsh/path.zsh` 的 Linux PATH 追加 `$HOME/.local/opt/node-current/bin`；更新 `tests/zsh_path_test.sh` 覆盖该目录；更新 `.config/shared/zsh/README.md` 说明 Linux PATH 管理；将本地 Node current npm 全局 CLI 规则记录到 `memory/organizing_preferences.md`。
- 验证：`./tests/zsh_path_test.sh` 通过（当前机器 `/usr/local/nodejs/bin` 与 `$HOME/.npm-global/bin` 不存在而跳过，`$HOME/.local/opt/node-current/bin` 覆盖生效）；`git diff --check` 通过；`zsh -fc ". .config/shared/zsh/path.zsh; command -v omx"` 输出 `/home/rikoo/.local/opt/node-current/bin/omx`。
- live：用户已运行 `./install.sh`，`.config/shared/zsh/path.zsh` 已同步到 `/home/rikoo/.config/zsh/path.zsh`，且 `cmp -s .config/shared/zsh/path.zsh /home/rikoo/.config/zsh/path.zsh` 通过；未重载运行态服务。

## 2026-06-24 — niri 配置 include 化结构性重构

- 目的：消除 ubuntu_x64 与 arch_x64 两份 niri 配置的高度重复，公共段统一维护。
- 已做：
  - 新增 `.config/linux/niri/common.kdl`，承载 input/layout/blur/window-rule/binds 等全部公共段。
  - 改写 `ubuntu_x64/config.kdl` 与 `arch_x64/config.kdl`，只保留头部注释 + output 段 + `include "../common.kdl"`。
  - 调整 `install.sh` 的 `install_niri_config_for_platform`：把 `common.kdl` 复制到 `~/.config/niri/common.kdl`，把平台 `config.kdl` 复制到 `~/.config/niri/config.kdl` 并用 sed 把 include 路径从仓库的 `../common.kdl` 改写成 live 扁平布局的 `common.kdl`；用目标目录内确定性临时文件替代 mktemp，兼容最小 PATH 测试环境。
  - 更新 `tests/niri_wayland_config_test.sh`：公共内容断言指向 `common.kdl`，平台文件只断言 output + include；新增 install.sh 复制 common.kdl 与 include 改写的断言。
  - 同步 `README.md`、`memory/desktop.md` 说明新的 include 结构与安装行为。
- 验证：`bash -n install.sh`、`niri validate` 两份平台配置、`./tests/niri_wayland_config_test.sh` 全部通过；`./install.sh` 部署 live 后 `niri validate -c ~/.config/niri/config.kdl` 通过，旧 config.kdl 自动备份。
- 后续：本次仅结构性重构，行为完全等价；之前分析里的高优先级优化项（关键应用透明度豁免、raise-on-focus 等）未落地，可后续单独进行。

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
