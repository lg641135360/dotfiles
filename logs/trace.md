# Trace

> 本文件只记录实际发生过的修改、验证证据与后续线索，不定义长期规则；若某条经验已稳定复用，应提升到 `AGENTS.md` 或 `memory/`。

## 维护规则

- 本文件总长度建议不超过 150 行。
- 最近变更摘要（按 `### 子条目` 计，每条变更算一条）最多保留 5 条；单日多变更可并列多条 `###`，归档时按子条目而非日期计数。
- 归档通过 `scripts/archive_trace.ts` 手动触发，或由 agent 按 `AGENTS.md` 验证策略在提交前执行：
  ```bash
  npm --prefix scripts run archive-trace -- --dry-run   # 预览
  npm --prefix scripts run archive-trace --              # 执行
  ```
- 旧条目按月份归档到 `logs/trace-archive/YYYY-MM.md`。
- 默认任务不得读取 `logs/trace-archive/` 全文。
- 长期有效的规则、方法论或决策边界，不应长期停留在 `logs/trace.md`；若跨多次任务仍有效，应提升到对应 `memory/` 规则文件。


## 2026-08-14 — 整理工作区并校正钉钉默认入口与 trace 归档顺序

- 目的：把已验证的 aarch64 钉钉路径与仓库说明对齐，并恢复 trace“只保留最近 5 条”的维护约束。
- 改动：niri/scripts README、`memory/dingtalk.md` 与 `dingtalk-wayland` 帮助统一说明 aarch64 日常通过 Mod+C 调用官方 `Elevator.sh`，仓库脚本仅作 portal 检查、安全 restart、日志和 hook 回退；修复 `archive_trace.ts` 在同一天多条记录时错误保留最早条目的排序，以文档后出现者作为更新记录，并新增回归测试。
- 验证：为 rofi 运行时主题测试补充假 `rofi`，隔离真实显示服务依赖；`./tests/run.sh` 全量通过，归档排序、dingtalk/niri、rofi 等回归均通过；启动器 `sh -n`、aarch64/x86_64 两份 `niri validate` 与 `git diff --check` 通过。niri 测试仍有既存的 `browser-wayland: uname: not found` 非阻断提示。
- live 同步与运行态：未同步 live，未重载 niri，未重启钉钉；未提交、未推送。


## 2026-08-14 — 收敛钉钉与 niri 的窗口、portal 和重启行为

- 目的：在不改变“界面走 XWayland、aarch64 共享走原生 portal/PipeWire”架构的前提下，降低 mtgpu 透明合成、登录后 portal 竞态和宽泛进程匹配带来的风险。
- 改动：niri 为钉钉设置 2/3 默认列宽和 1.0 不透明度，aarch64 在平台级 0.90 全局规则之后再次覆盖；`dingtalk-wayland` 启动前最多等待 5 秒确认 ScreenCast backend，超时只告警、不重启服务；PipeWire 告警改为不依赖 hook 的通用文本；`restart` 改为读取 `/proc/<pid>/status` 与 `/proc/<pid>/exe`，只向当前用户的 `com.alibabainc.dingtalk`/`tblive` 发送 TERM/KILL。同步更新 niri/scripts README、dingtalk memory 和回归测试。
- 验证：先确认新增测试在实现前失败；实现后 `sh -n`、aarch64/x86_64 两份 `niri validate`、真实钉钉 PID 与当前 shell 的 `/proc/exe` 分类探针、portal backend 探针、shellcheck（可用时）、dingtalk/niri 回归测试和 `git diff --check` 均通过。niri 测试仍有既存的 `browser-wayland: uname: not found` 非阻断提示。
- live 同步与运行态：未同步 live，未重载 niri，未重启钉钉；未提交、未推送。


## 2026-08-14 — 修复 mako 1.8 配置解析失败

- 目的：恢复 niri 会话的标准通知服务；mako 因不支持 `icon-border-radius` 而启动失败，`notify-send` 无法取得 `org.freedesktop.Notifications`。
- 改动：从 mako 配置删除不兼容的图标圆角选项，在模块 README 记录 Ubuntu 24.04 / mako 1.8 的兼容边界，并增加回归断言。
- 验证：使用仓库配置启动 mako 时不再报告解析错误；`tests/niri_wayland_config_test.sh` 与 `git diff --check` 通过。
- live 同步与运行态：用户通过 `./install.sh` 完成同步，repo/live 配置 SHA-256 均为 `95c02e60c63f9a44576e1f1543abd099787f4c94a8ba5fe9e43e73aaca4249d9`。原重启命令因当前终端持有旧 `NIRI_SOCKET` 而未执行；改用当前 niri socket 启动 mako 后，PID 303482 已持有 `org.freedesktop.Notifications`，`notify-send` 返回 0。未提交、未推送。


## 2026-08-14 — 在 niri autostart 中固化 portal ScreenCast 启动时序

- 目的：避免 niri 新会话中 GNOME portal 抢先启动、永久停留在 Settings-only，导致钉钉无选择器且黑屏。
- 改动：`wayland-autostart` 新增 `start_portal_after_niri`：先等待 `org.gnome.Mutter.ScreenCast` D-Bus 名称（最多 15 秒），再依次重启 GNOME backend 与 portal frontend，并验证 backend 暴露 `org.freedesktop.impl.portal.ScreenCast`。以 `NIRI_SOCKET` 写入 `portal.niri-session`，同会话且接口健康时不重复重启；日志写入 `portal.log`。删除原先仅按进程存在性直接启动 portal 的 `run_once_logged` 路径。同步更新 niri/scripts README、dingtalk memory 和回归测试。
- live 同步与运行态：已同步 `~/.config/scripts/wayland-autostart`，repo/live SHA-256 均为 `83e9769b1e0ef5f05abc75dbc0227b62fb2cb4a12802744999642568eb91c2e2`；使用当前 niri 会话环境执行后，日志显示 ScreenCast 已就绪并成功重启 portal，marker 记录当前 `NIRI_SOCKET`。
- 验证：GNOME backend 的 ScreenCast/CreateSession/SelectSources/Start 接口齐全，libportal probe `CREATE_OK`；同一会话第二次执行前后 backend/frontend MainPID 不变，证明不会重复重启；niri/dingtalk 测试、两脚本语法和 `git diff --check` 通过。niri 测试仍有既存的 `uname: not found` 非阻断提示。
- 后续实测结论：aarch64 上钉钉 8.1.1 在不加载 `libdingtalkhook.so` 的情况下已成功共享；运行进程保持 `XDG_SESSION_TYPE=wayland` / `WAYLAND_DISPLAY`，自定义 hook 不在 `LD_PRELOAD` 中。该结论已同步到 niri/scripts README 与 `memory/dingtalk.md`，并明确不外推到尚未验证的 x86_64。
- 提交推送：未提交、未推送。


## 2026-08-14 — 修复 niri 重启后 portal 过早启动导致选择器消失

- 目的：原生钉钉路径无选择器且黑屏，确认 portal 后端状态。
- 根因：17:16 niri 会话重启后，`xdg-desktop-portal-gnome` 在 17:16:14 先启动，此时 niri 尚未在 17:16:19 注册 `org.gnome.Mutter.ScreenCast`；backend 因此打印 `Non-compatible display server, exposing settings only` 并持续只有 Settings。钉钉请求实际到达 frontend，但 frontend 报 ScreenCast backend 接口不存在。
- 运行态修复：待 niri 已就绪后，按顺序停止 portal frontend/backend，再启动 GNOME backend 与 frontend。当前 GNOME backend 已恢复 ScreenCast 的 `CreateSession`、`SelectSources`、`Start` 接口；最小 libportal probe 返回 `CREATE_OK`。
- 未修改仓库文件；未同步 live 配置；未提交、未推送。


## 2026-08-15 — 清理 starship 配置死代码并修复 os/directory 双空格

- 目的：删除 starship.toml 中永远不会渲染的模块与未使用的 palette，并修复 `[os]` 与 `[directory]` 之间因 directory 前导空格叠加 os 默认 format 产生的双空格。
- 改动：`.config/shared/starship.toml` 删除 `[golang]`/`[php]`/`[java]`/`[kotlin]`/`[haskell]` 五个未在 `format` 中引用的模块；删除 `catppuccin_frappe`/`latte`/`macchiato` 三个未使用的 palette（保留 `catppuccin_mocha`）；删除 `[os.symbols]` 中默认空字符串的条目（Windows/SUSE/Manjaro/Alpine/Amazon/Android/AOSC/CentOS）；为 `[os]` 增加 `format = '[ $symbol]($style)'`，使 os 与 directory 之间只保留 directory 自身的一个前导空格。
- 验证：`tests/starship_config_test.sh` PASS；`git diff --check` 无告警；`starship config` 与 `starship explain` 能正常解析配置，输出中 os 图标与 directory 之间不再出现双空格。
- live 同步与运行态：未同步 live `~/.config/starship.toml`，未重载 shell；未提交、未推送。
- 后续可能方向：`[directory]` 仍使用 emoji 默认 `read_only` 图标，与 Nerd Font 主题不一致；`[git_branch]` 无 `truncation_length`，长分支名会顶宽；`[character]` 的 success/error 符号来自不同图标族。如需统一可再开一轮 `repo-change`。


## 2026-08-15 — starship 美化 git_status 符号、语言配色与 character 错误态

- 目的：统一 git_status 状态符号视觉族、为语言模块按品牌色分配独立色、让 character 错误态与成功态使用同字符靠颜色区分。
- 改动：`.config/shared/starship.toml` 中 `[git_status]` 显式设置 ahead/behind/diverged/untracked/stashed/modified/staged/renamed/deleted 为 `↑ ↓ ↕ ? $ ! + » ✘`；`[nodejs]`/`[bun]`/`[c]`/`[rust]`/`[python]` 的 style 从统一 `fg:teal` 改为 `fg:green`/`fg:sky`/`fg:blue`/`fg:peach`/`fg:yellow`；`[character]` 的 `error_symbol` 从 `✗` 改为 `❯`，与 `success_symbol` 同字符靠颜色区分。同步更新 `tests/starship_config_test.sh` 中写死的 `error_symbol` 断言。
- 验证：`tests/starship_config_test.sh` PASS；`git diff --check` 无告警；`starship explain` 能正常解析配置。
- live 同步与运行态：未同步 live `~/.config/starship.toml`，未重载 shell；未提交、未推送。
- 后续可能方向：`[directory]` 默认 emoji `read_only` 图标、`[git_branch]` 无 `truncation_length`、`[git_status]` 各状态仍共用 `fg:yellow` 未按严重度分色。


## 2026-08-15 — starship 增加 git_branch 截断、directory read_only 图标与清理 cmd_duration 死配置

- 目的：防止长分支名顶宽、统一 directory 只读图标为 Nerd Font 主题、清理 cmd_duration 中因 `show_notifications = false` 而永不生效的 `min_time_to_notify`。
- 改动：`.config/shared/starship.toml` 中 `[git_branch]` 增加 `truncation_length = 20` + `truncation_symbol = "…"`；`[directory]` 增加 `read_only = " 󰌾"` + `read_only_style = "fg:red"`，替换默认 emoji `🔒`；`[cmd_duration]` 删除 `min_time_to_notify = 45000`。
- 验证：`tests/starship_config_test.sh` PASS；`git diff --check` 无告警；`starship explain` 能正常解析配置。
- live 同步与运行态：未同步 live `~/.config/starship.toml`，未重载 shell；未提交、未推送。
- 后续可能方向：`[directory]` 无 `repo_root_style` 突出仓库根、`[git_status]` 各状态仍共用 `fg:yellow`、模块间空格叠加导致视觉松散。


## 2026-08-15 — starship 增加 directory repo_root_style、home_symbol 与 cmd_duration min_time

- 目的：在 git 仓库内突出仓库根目录、统一 home 目录图标为 Nerd Font、减少短命令耗时噪音。
- 改动：`.config/shared/starship.toml` 中 `[directory]` 增加 `repo_root_style = "fg:peach bold"` 和 `home_symbol = "󰋜"`；`[cmd_duration]` 增加 `min_time = 5000`，只显示 5 秒以上命令的耗时。
- 验证：`tests/starship_config_test.sh` PASS；`git diff --check` 无告警；`starship explain` 能正常解析配置。
- live 同步与运行态：未同步 live `~/.config/starship.toml`，未重载 shell；未提交、未推送。
- 后续可能方向：`[git_status]` 各状态仍共用 `fg:yellow` 未按严重度分色、模块间空格叠加导致视觉松散、语言模块在非项目目录也会渲染 symbol。


## 2026-08-15 — 兜底终端由 kitty 切换为 foot

- 目的：用户希望 Wayland 兜底终端由 foot 接替 kitty，并把 foot 配置做成与 alacritty 一致的观感。
- 改动：
  - 新增 `.config/linux/foot/foot.ini` 与 `.config/linux/foot/README.md`：镜像 `.config/shared/alacritty`（MesloLGS Nerd Font Mono 13、Catppuccin Mocha 内嵌 palette、`csd.preferred=none`、`pad=12x12`、`colors.alpha=0.82`、Beam+blink、`hide-when-typing=yes`、`scrollback.lines=50000`、`multiplier=3.0`、`term=xterm-256color`、`[text-bindings]` 镜像 Alt+hjkl/方向键/Shift+Alt 上下）；透明度采用 0.82（不再沿用 kitty 因 mtgpu alpha bug 走的 1.0）。foot 的 `[text-bindings]` 要求 modifier 用 XKB 名称，`Alt` 必须写成 `Mod1`（实测 `Alt`/`Alt_L` 都会被 `foot --check-config` 拒绝），已在配置与 README、memory 中标注。
  - 新增 `memory/foot.md`，记录 foot 作为 alacritty Wayland 兜底的定位、与 alacritty 的差异（主题内嵌、OSC52 默认行为、cursor color、窗口模糊）和透明度取舍。
  - 新增 `tests/foot_config_test.sh`，覆盖字体/窗口/鼠标/光标/TERM/滚动/Catppuccin palette/text-bindings 镜像 alacritty，并断言 `terminal-wayland` 兜底为 foot。
  - 删除 `.config/linux/kitty/kitty.conf`、`.config/linux/kitty/README.md`、`tests/kitty_config_test.sh` 及空目录。
  - `.config/scripts/terminal-wayland`：kitty 兜底分支改为 `exec foot "$@"`；移除为 kitty 补 PATH 的 `~/.local/bin` 段（foot 走系统包 `/usr/bin/foot`，无需）；notify 文案改为 "Alacritty or foot"。
  - `install.sh`：`linux_wayland_dir_configs` 的 kitty 行改为 foot 行。
  - `.config/linux/waybar/{config,config.aarch64,README.md}`：CPU/MEM 模块 `on-click` 从 `kitty -- htop` 改为 `foot -- htop`。
  - `.config/linux/niri/{README.md,common.kdl}`：终端入口描述与透明度注释从 kitty 改为 foot。
  - `.config/linux/{awesome/theme/README.md,picom/README.md}`、`README.md`、`AGENTS.md`、`memory/{alacritty,desktop,niri,organizing_preferences}.md`、`tests/{picom,repo_docs,starship,waybar,wayland_scripts,niri}_config_test.sh` 中 kitty 相关引用同步替换为 foot；`AGENTS.md` memory 索引与 `repo_docs_test.sh` 正则新增 `foot.md`；`starship_config_test.sh` 注释更新。
- 验证：`./tests/run.sh fast` 全绿（含新增 `foot_config_test.sh` 与更新后的 picom/repo_docs/starship/waybar/wayland_scripts/niri 测试）；`foot --check-config` exit=0；`git diff --check` 无告警。
- live 同步与运行态：已通过 `./install.sh` 同步 live `~/.config/{foot,niri,waybar,scripts}`；foot.ini 后续又手动同步一次（见下方修复）。
- 后续可能方向：aarch64 内屏 2x 下若复现 mtgpu 对 foot 0.82 alpha 合成的 bug，再单独评估是否在该硬件上降回不透明。
