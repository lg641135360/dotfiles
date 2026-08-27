# herdr 偏好

## 使用约定（workspace / tab / pane）
- 层级映射（区别于 tmux）：session ≈ workspace（项目/任务容器）、window ≈ tab（视图分层）、pane ≈ pane（真实终端分屏）。
- 使用优先级：workspace 隔离 > tab 分层 > pane 克制。
- 每个 repo / 任务 / 调查 = 一个 workspace（第一优先级）；sidebar 按 workspace 汇总所有 agent 状态（working / blocked / done / idle / unknown），靠它掌握跨项目全局视野，而非把 pane 铺满屏。
- workspace 内用 tab 分视图（如 agents / logs / server），tab 间 prefix+n / prefix+p 切换。
- pane 分屏仅用于「需要同一屏并排看两个实时输出」时（如左 agent、右 tail -f 日志），不追求平铺一堆 pane。
- herdr 是 mouse-first + agent-aware：默认鼠标即可（点 pane/tab、拖分屏边框、右键菜单），键盘为可选增强。

## 同步输入
- herdr 无 tmux synchronize-panes（prefix+s 广播输入）等价功能：官方全部 keys 动作列表无多 pane 输入注入类动作，`[[keys.command]]` 的 type 只有 popup / pane / shell / plugin_action，也无 broadcast。
- 定位差异：tmux 是通用终端复用器（pane 跑普通 shell，同步输入用于批量运维）；herdr 是 AI agent 复用器（pane 跑 agent 会话，广播输入给多个 agent 有副作用风险）。
- 结论：同步输入需求继续用 tmux；herdr 专注 agent 会话管理，两者共存、各司其职。

## 配置要点
- 配置文件 `~/.config/herdr/config.toml`，零配置可跑；仓库草稿在 `.config/shared/herdr/config.toml`（对齐 tmux 键位 + Catppuccin，prefix 同 tmux 用 ctrl+a）。
- 键名以官方 config-reference 为准；CSDN 文章中的 session_dir / max_workers / socket_path 等键是编造的，勿照抄。
- 通知 `ui.toast.delivery = "system"`（niri + mako 通知守护，走 freedesktop notification）；SSH 无图形会话时再考虑 `terminal`。

## Trae CLI 状态监控接入（hooks 桥接，2026-08-27）
- herdr 原生 agent 列表不含 trae（`agent start --kind` 枚举无），但提供自定义上报通道：pane 内进程自动继承 `HERDR_ENV`/`HERDR_PANE_ID`/`HERDR_BIN_PATH`，可用 `herdr pane report-agent <pane> --source custom:trae --agent trae --state idle|working|blocked` 上报，状态进 sidebar/waits/通知/rollup。
- 桥接脚本 `~/.config/scripts/herdr-report`（仓库 `.config/scripts/herdr-report`）：按参数 working/idle/notify/release 上报，notify 模式按 stdin JSON 的 notification_type 细分（permission_prompt→blocked）；`HERDR_ENV != 1` 时完全 no-op，用 sed 而非 jq 提取 JSON（live 不保证装 jq）。
- Trae CLI hooks 配置 `~/.trae/trae_cli.yaml`（仓库 `.config/shared/trae-cli/trae_cli.yaml`）：user_prompt_submit/pre_tool_use→working、session_start/stop→idle、notification→notify、session_end→release（释放生命周期权限）。`--source` 必须稳定唯一（custom:trae），否则权限被抢。
- 限制：`agent start --kind trae` 自动拉起与会话恢复不可用（需 herdr 二进制更新支持），需手动在 pane 启动 trae-cli；状态权威来自上报（hooks 优先于屏幕检测，无双源冲突）。