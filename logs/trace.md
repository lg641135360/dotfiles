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


## 2026-08-17 — 根治 fcitx5 Wayland 检测提示：清除 systemd 用户会话的 GTK_IM_MODULE

- 目的：fcitx5 弹出"建议取消设置 GTK_IM_MODULE"的 Wayland 检测提示，且环境曾出现无法输入中文（fcitx5 被中途 `--replace` 重启后 niri 不重发 text_input.enter，所有 wayland_v2 IC focus:0）。
- 诊断证据：
  - `common.kdl:28` 与 `wayland-autostart:178` 已故意不设/`unset GTK_IM_MODULE`，但 `systemctl --user show-environment` 仍显示 `GTK_IM_MODULE=fcitx`。
  - 来源链：`~/.xinputrc` → `run_im fcitx5`（im-config 注入登录环境）→ sddm 传递 → `niri-session:36` 的 `systemctl --user import-environment`（无参数，导入全部登录环境）→ systemd 用户会话带 `GTK_IM_MODULE=fcitx`。
  - `wayland-autostart` 的 `unset GTK_IM_MODULE` 只影响 fork 的子进程，不影响已导入 systemd 的独立环境存储。
  - fcitx5 Wayland 检测逻辑会读 systemd 用户环境 / 自身进程环境，发现 `GTK_IM_MODULE=fcitx` 即弹提示。
  - `dbus-update-activation-environment` 不支持 `--remove`，只能加变量；DBus 激活环境实际由 `dbus-daemon` 维护，无法用该命令删（但 fcitx5 检测主要看 systemd 用户环境 + 进程自身环境，DBus 那边不影响）。
- 改动：`.config/scripts/wayland-autostart` 在 `systemctl --user import-environment` 之后新增 `systemctl --user unset-environment GTK_IM_MODULE`；`tests/wayland_scripts_test.sh` 加 2 条断言（`unset GTK_IM_MODULE` + `systemctl --user unset-environment GTK_IM_MODULE`）；`.config/linux/niri/README.md` 环境变量段补一句说明 sddm/niri-session 导入路径与 unset-environment 的必要性。
- 验证：`sh -n .config/scripts/wayland-autostart` 通过；`./tests/wayland_scripts_test.sh` PASS；手动 `systemctl --user unset-environment GTK_IM_MODULE` 后从 `unset GTK_IM_MODULE` 的 shell 重启 fcitx5，新进程环境与 systemd 用户环境均无 `GTK_IM_MODULE`，启动日志无 Wayland 检测/GTK_IM_MODULE 警告，rime addon 正常加载。
- live 同步与运行态：已同步 `wayland-autostart` 到 `~/.config/scripts/wayland-autostart`（diff 一致）；已手动执行 `systemctl --user unset-environment GTK_IM_MODULE` 并重启 fcitx5 验证；未重载 niri，未重启桌面会话（下次登录 sddm/niri-session 会重新导入，但 `wayland-autostart` 会自动清掉）。
- 提交推送：未提交、未推送。
- 后续可能方向：fcitx5 被中途 `--replace` 重启后 niri 不重发 text_input.enter 导致所有 wayland_v2 IC focus:0 的问题本次靠重启 fcitx5 绕过；若复发，可考虑在 `wayland-autostart` 里加 focus 重新触发的兜底，或上游反馈 niri。


## 2026-08-17 — 修复 x86_64 钉钉共享黑屏：回滚 hook 源码到 6 月 4 日版本

- 目的：x86_64 + 钉钉 8.1.0-Release.6021101 上共享屏幕黑屏只有鼠标；用户确认此前 6 月 4 日 hook 版本能工作，8 月 14 日 commit `3323b5e` 改动后不可用。
- 诊断证据：
  - 原生 Wayland 路径：`libmeeting_sdk.so` 只编译 X11 capturer（`ldd` 无 wayland/portal/pipewire 依赖，`nm -D` 无 `wl_display`/`pw_main`/`xdp_session`）；`dbus-monitor` 抓包期间 ScreenCast method call 0 次；`pw-top` 无 video 节点；tblive fd 无 wayland/portal 句柄。
  - 8 月 14 日 hook 路径：tblive 触发 `XShmAttachHook` 后 `portal create timed out; cancelling request`（60 秒超时），共享对话框卡死。
  - 6 月 4 日 hook 路径：用户实测可用，debug log 显示 `framebuffer=2560x1440` + `processed frame count: 40`，帧正常处理。
  - 8 月 14 日 hook 源码在 x86_64 上导致钉钉启动即崩（`CefExecuteProcess exit_code<<0`，hook 未触发，debug log 全空）；全量回滚到 6 月 4 日版本后启动成功。
- 改动：`tools/dingtalk-wayland-screenshare/` 4 个文件（`hook.cpp`/`payload.cpp`/`payload.hpp`/`CMakeLists.txt`）checkout 回 commit `13537e2`（6 月 4 日版本）；`tests/dingtalk_hook_test.sh` 调整断言匹配 6 月 4 日契约（XShmAttach `return false`、无 `create_cancellable`、无 `kPortalCreateTimeout`、portal init 由内部 `XShmAttachInner` 触发）；`memory/dingtalk.md` 和 `niri/README.md` 记录 x86_64 必须走 hook 回退、必须用 6 月 4 日 hook 版本的约束，以及 8 月 14 日改动的具体差异和失败模式。
- 验证：`./tests/dingtalk_hook_test.sh` PASS；`./tests/run.sh fast` 全部 PASS（43 PASS / 0 FAIL / 0 SKIP）；`git diff --check` 通过；重新编译 `libdingtalkhook.so`（SHA-256 `744821ac0dabd7fd787e0093dea299ce6e8590b5fd0567bf7460fb03cafbc519`）并部署到 `~/.local/lib/dingtalk-wayland-screenshare/build/`；用户实测 `DINGTALK_FORCE_X11_CAPTURE=1 ~/.config/scripts/dingtalk-wayland restart` 后共享正常工作。
- live 同步与运行态：已同步 hook .so 到 live（repo/live SHA-256 一致）；已用 hook 路径重启钉钉并实测共享成功；未重载 niri，未同步其它 live 配置（脚本本身未改动）。
- 提交推送：未提交、未推送。
- 后续可能方向：aarch64 与 x86_64 的 hook 源码约束目前冲突（aarch64 需要 8 月 14 日版本的 cancellable/超时逻辑避免 tblive 卡死，x86_64 必须用 6 月 4 日版本否则启动即崩）。若要统一源码，需在 hook 内按架构或运行时探测分支处理；当前以 x86_64 实测可用为准，aarch64 走原生捕获不需要 hook。


## 2026-08-17 — dingtalk-wayland 脚本按架构自动默认 hook 路径

- 目的：x86_64 上不想每次手动输入 `DINGTALK_FORCE_X11_CAPTURE=1`；脚本应基于架构自动判断默认值。
- 改动：`.config/scripts/dingtalk-wayland` 的 `force_x11_capture` 赋值改为按 `uname -m` 判断 —— x86_64 默认 1（hook 回退），其它架构默认 0（原生捕获）；显式 `DINGTALK_FORCE_X11_CAPTURE=0/1` 优先级最高。同步更新 `print_usage` 帮助文本、`tests/dingtalk_hook_test.sh` 断言、`memory/dingtalk.md` 和 `niri/README.md` 的启动命令描述。
- 验证：`sh -n` 脚本和测试语法通过；`./tests/dingtalk_hook_test.sh` PASS；`git diff --check` 无告警；`sh .config/scripts/dingtalk-wayland usage` 输出正确；live 同步后 `diff` repo/live 一致。
- live 同步与运行态：已同步脚本到 `~/.config/scripts/dingtalk-wayland`（repo/live SHA-256 一）；未重启钉钉（用户当前钉钉已在运行，下次 restart 即生效）；未重载 niri。
- 提交推送：未提交、未推送。
- 后续可能方向：若 aarch64 也需要用脚本启动且原生路径不可用，可扩展架构判断逻辑；当前 aarch64 日常走 Mod+C 系统入口，不依赖此脚本。


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


## 2026-08-17 — 钉钉 hook 等待循环加超时上限并修复取消路径死锁风险

- 目的：消除 x86_64 hook（6月4日版本基线）中三处无限忙等（session 创建、pipewire_fd 获取）导致 payload 线程可能永久卡死的问题，并修复取消路径 join sanitizer 前未置 stop_flag 的死锁隐患。
- 改动：`tools/dingtalk-wayland-screenshare/payload.cpp` 引入 `PORTAL_WAIT_TIMEOUT_MS`（60s 计数式超时，非 GCancellable，不违反 6月4日版本契约）；session 等待与 pipewire_fd 等待均改为有界轮询，超时后退出并清理线程；`payload_main` 新增 session 为 null 的早退分支；两处 `x11_sanitizer_thread.join()` 前均先 `x11_sanitizer_stop_flag.store(true)`。`tests/dingtalk_hook_test.sh` 先行新增 `test_portal_waits_are_bounded_with_polling_timeouts` 断言。
- 验证：`tests/dingtalk_hook_test.sh` PASS；`cmake -S tools/dingtalk-wayland-screenshare -B /tmp/... && cmake --build` 编译链接成功。用户将做运行时验证（安装 .so + `dingtalk-wayland restart` + 实际共享屏幕）。
- live 同步与运行态：未同步 live `~/.local/lib/dingtalk-wayland-screenshare/`，未重启钉钉；未提交、未推送。
- 后续可能方向：PipeWire 线程忙轮询（`pw_loop_iterate` + sleep）可改为事件驱动；`XdpScreencastPortalStatus` 可增加 kError 状态区分创建失败与用户取消。
