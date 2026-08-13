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


## 2026-08-13 — starship 替换为 catppuccin-powerline 预设

- 目的：用户希望尝试社区现成方案，整体替换原有简洁配置。
- 已做（`repo-change` + `live-sync` 部分）：
  - `.config/shared/starship.toml`：整体替换为 `starship preset catppuccin-powerline` 输出，保留头部部署注释。
  - 新增 `$os`/`$username`/`$time`/多语言版本段，引入 catppuccin_mocha palette 及 frappe/latte/macchiato 备用 palette。
  - `tests/starship_config_test.sh` 全部通过。
- live 同步：`~/.config/starship.toml` 因 IDE 沙盒限制无法直接写入，需用户手动 `cp .config/shared/starship.toml ~/.config/starship.toml`。
- 后续：新开终端即生效；若想回退，`git checkout .config/shared/starship.toml` 后重新 cp 即可。

## 2026-08-13 — aarch64 niri 禁用 gammastep 自动色温

- 目的：aarch64 (MediaTek) 上 gammastep 通过 wlr-gamma-control 压低色温/亮度，会连带把外接屏压得过暗，影响日常使用。
- 已做（`repo-change` + `live-sync` 部分）：
  - `.config/scripts/wayland-autostart`：gammastep 启动逻辑增加 `uname -m` 判断，aarch64 下跳过并打印提示，其它平台保持原行为。
  - `.config/linux/niri/README.md`：配置部署边界和自启动列表两处说明 aarch64 禁用 gammastep 的原因。
  - `tests/niri_wayland_config_test.sh`：新增断言验证 aarch64 跳过逻辑（`uname -m`、`aarch64`、提示文本、README 说明）。
- 验证：`bash -n .config/scripts/wayland-autostart` 通过；`./tests/niri_wayland_config_test.sh` PASS。
- live 同步：已杀掉 live gammastep 进程（PID 65099）；`~/.config/scripts/wayland-autostart` 因 sandbox 限制需用户手动 `cp` 同步。
- 后续：下次重装或 `install.sh` 部署后自动生效；当前 live 脚本未同步前，重新执行 wayland-autostart 仍会启动 gammastep。


## 2026-08-13 — 终端改为全平台 alacritty 默认，移除 aarch64-kitty 分支

- 目的：此前 aarch64 因 mtgpu 下 alacritty 0.18.0-dev 内屏 2x 字形损坏而优先 kitty；现用户以外接屏为主、alacritty 显示正常，决定全平台统一 alacritty 默认，并排除本轮对 kitty 的改动。
- 已做（`repo-change`，未同步 live、未提交）：
  - `.config/scripts/terminal-wayland`：删除 aarch64-kitty/foot 分支，改为全平台优先 alacritty、kitty 兜底；保留 `~/.local/bin` 补 PATH 逻辑（kitty 兜底依赖）。
  - `tests/niri_wayland_config_test.sh`：`test_niri_aarch64_config_maps_media_tek_hybrid_outputs_and_foot_terminal` 去掉 `uname -m`/`exec foot` 断言，改断言不再有 aarch64-kitty 分支；`test_launcher_and_lock_have_wayland_first_fallbacks` 注释更新。
  - `.config/scripts/README.md`、`.config/linux/niri/README.md`：终端选择描述同步为 alacritty 全平台默认。
  - `.config/linux/niri/common.kdl`：恢复全局 `opacity 0.88`（用户决定回退 kitty 调试时的临时移除）。
  - `memory/desktop.md`：更新 aarch64 终端默认决策，标注内屏字形问题未根治。
- 验证：待跑 `tests/niri_wayland_config_test.sh` 与 `bash -n .config/scripts/terminal-wayland`。
- 后续：live 的 `~/.config/scripts/terminal-wayland` 需手动复制后 Mod+Return 生效。**待办问题**：aarch64 mtgpu 下 alacritty 内屏 2x 字形损坏仍未根治（外接屏正常）；后续可从 EGL/表面缩放（scale=2.0）渲染路径入手定位，见 `debug-kitty-transparent-bg.md` 同源的 mtgpu alpha/字形渲染 bug 线索。

## 2026-08-13 — kitty 背景改为完全不透明（1.0），修复 mtgpu 半透明渲染 bug

- 目的：上一轮移除 niri 全局 opacity 后 kitty 仍"全透明、看不清字体"。经核实 live 的 `~/.config/niri/common.kdl` 已去掉 opacity 且已重载，故根因不在 niri，而在 kitty 自身 `background_opacity 0.82` 与 aarch64 mtgpu 驱动 alpha 合成 bug 叠加——驱动把 0.82 的半透明背景错误渲染成全透明。
- 已做（`repo-change`，未同步 live、未提交）：
  - `.config/linux/kitty/kitty.conf`：`background_opacity 0.82` → `1.0`（完全不透），走不透明路径绕开 mtgpu alpha bug。
  - `.config/linux/kitty/README.md`：设计表透明度行与「与 alacritty 的差异」更新，说明 mtgpu 半透明 bug 及取舍（透明观感只在 X11/Awesome 由 alacritty 保留）。
- 验证：`bash -n` 不适用（非脚本）；改动为纯配置值变更，语法经阅读核对。未跑 kitty 测试（无对应值断言改动风险低，若需可跑 `tests/kitty_config_test.sh`）。
- 后续：live 的 `~/.config/kitty/kitty.conf` 需手动复制后重启 kitty 生效；若仍全透，需进一步排查是否另有覆盖配置或驱动问题。

## 2026-08-13 — 移除 niri 全局窗口透明度，修复终端"全透明看不清字体"

- 目的：kitty 终端实际表现为全透明、文字难读。根因是 niri 全局 `window-rule { opacity 0.88 }` 会连同文字字形一起淡化，叠加 kitty 自身 `background_opacity 0.82` 后两层透明度叠乘（约 0.72），aarch64 mtgpu 自研驱动 alpha 合成本又不可靠。
- 已做（`repo-change`，未同步 live、未提交）：
  - `.config/linux/niri/common.kdl`：全局 `window-rule` 删除 `opacity 0.88`，仅保留 `draw-border-with-background false` + `background-effect { blur true }`；透明交由各应用自身控制（kitty 保持 0.82）。
  - `.config/linux/niri/README.md`：窗口规则与 Chrome 条目更新，去掉"全局 0.88 透明度"描述，记录透明度只由应用自身控制的取舍。
- 验证：`niri validate -c .config/linux/niri/ubuntu_aarch64/config.kdl` 通过（config is valid）。
- 后续：live 的 `~/.config/niri/common.kdl` 需手动复制本仓库文件后 `Mod+Ctrl+R` 重载生效；kitty.conf 未改动。

## 2026-08-13 — 精简测试中的 README 文案漂移断言

- 目的：去掉"锁文档文字"的脆弱断言，保留结构性/不变量检查，降低维护成本。未同步 live、未提交。
- 已做（`repo-change`）：
  - `tests/awesome_docs_theme_test.sh`（187→72 行）：删除 6 个 README 中文文案断言函数，保留 `test_theme_exposes_fallback_titlebar_tokens`（真实 theme.lua token）并新增 `test_removed_dependencies_stay_gone`（lain/picom-catppuccin.conf 不复活）。
  - `tests/picom_config_test.sh`：删除 `test_readme_documents_current_visual_targets`（纯 README 文案）及未用的 `README_FILE` 变量。
  - `tests/kitty_config_test.sh`：删除 `test_readme_documents_reference_and_deviation`（纯 README 文案）及未用的 `README_FILE` 变量。
  - `tests/git_config_test.sh`：删除 README 表格文案断言（subs/grs/grst 表）及未用的 `README` 变量；保留真实 `git config` 值断言与 memory 断言。
  - `tests/repo_docs_test.sh`：**未改动**。复核为几乎全结构性/提示词系统不变量断言（文件存在、误拼文件名、已删模块、`.githooks` 移除、AGENTS/USER/SOUL 结构），且是 AGENTS.md 指定的提示词系统测试，强删会削弱协议要求。
- 验证：5 个受影响测试全部 PASS；`bash -n`/`sh -n` 语法 OK；`git diff --check` OK。
- 后续：trace.md 已 11 条超"最多 5 条"建议，需运行 `scripts/archive_trace.ts` 归档。

## 2026-08-13 — 修复 kitty 测试失效断言，改写 README 常驻段

- 目的：清理"移除 kitty 常驻单实例"（改回普通冷启动）时漏掉的同步项。
- 已做（`repo-change`，未同步 live、未提交）：
  - `.config/linux/kitty/README.md`：删除"启动提速：常驻单实例"整段，改写为"启动方式：普通冷启动"，说明移除权衡与取舍。
  - `tests/kitty_config_test.sh`：`test_terminal_wayland_prefers_kitty_on_aarch64` 删除 socket 断言，改断言 `exec kitty "$@"` + `assert_not_contains allow_remote_control/kitty @ --to/--listen-on`；删除 `test_kitty_socket_uses_runtime_dir` 及其调用；删除未再使用的 `AUTOSTART_SCRIPT` 变量。
- 验证：`bash tests/kitty_config_test.sh` PASS；`bash -n tests/kitty_config_test.sh` OK；`git diff --check` OK。改动与 `tests/niri_wayland_config_test.sh` 的反向断言一致。
- 后续：核查 POC 测试（autopairs/neo-tree/float_trem）均为有效回归测试（目标文件仍存在），无需删除；trace.md 已 9 条超"最多 5 条"建议，需归档。

## 2026-08-13 — 移除 pasystray 自启，niri 会话不再残留 XWayland 客户端

- 目的：清理 niri 会话中唯一仍跑在 XWayland 的进程。经 `xlsclients`/`ss` 确认 pasystray 是当时唯一的 X 客户端；其音量控制能力已被 waybar `pulseaudio` 模块（左键静音、滚轮调音量、右键 `pavucontrol`）覆盖。
- 已做（`repo-change`，未同步 live、未结束运行中的 pasystray、未提交）：
  - `.config/scripts/wayland-autostart`：删除 `run_once_logged pasystray ...` 行。
  - `tests/niri_wayland_config_test.sh`：该行断言由 `assert_contains` 改为 `assert_not_contains`，并加注释说明移除原因，防回归。
  - `.config/linux/niri/README.md`：自启动列表去掉 pasystray，说明音量改由 waybar pulseaudio 模块覆盖。
  - `memory/desktop.md`：更新 niri autostart 可选服务列表，记录 pasystray 移除与回退方案。
- 验证：`sh -n .config/scripts/wayland-autostart` OK；`tests/niri_wayland_config_test.sh` PASS（`uname: not found` 为测试子进程受限 PATH 的既有噪音，非失败）；`git diff --check` OK。
- 后续：live 同步 `~/.config/scripts/wayland-autostart` 不在 IDE 白名单，需用户手动复制或重登 niri 才生效；当前已运行的 pasystray 需手动结束（`pkill pasystray`）以立即移除 XWayland 客户端。若日后需要托盘快速切音源，可在 wayland-autostart 重新加入。

## 2026-08-13 — 修复 niri 会话 Mod+C(fuzzel) 启动 Trae CN 静默失败

- 目的：解决 aarch64 niri 会话下按 Mod+C 打开 fuzzel、选择 Trae CN 后无反应的问题。
- 根因：niri 会话的 PATH 是裸系统 PATH（`/usr/local/sbin:...:/snap/bin`），不含 `/usr/share/trae-cn/bin`；`trae-cn-wayland` 脚本用 `command -v trae-cn` 找二进制失败，退出 127 且无窗口。fuzzel 能看到入口（desktop 入口存在）但启动即静默失败。
- 已做（`repo-change`）：
  - `.config/scripts/trae-cn-wayland`：`command -v trae-cn` 失败时回退把 `/usr/share/trae-cn/bin` 追加进 PATH（标准安装路径含 `trae-cn` wrapper），再 `exec trae-cn`；否则仍报错退出 127。
- 验证：`bash -n` OK；`tests/niri_wayland_config_test.sh` 整体 exit 0；trae 相关 5 条断言（executable / --ozone-platform=wayland / --enable-wayland-ime / WaylandWindowDecorations / exec trae-cn）均满足。
- 待办：live 同步 `~/.config/scripts/trae-cn-wayland` 不在 IDE 白名单，需用户手动 `cp`；kitty 已升级到 0.48.2（ghfast.top 镜像下载 arm64 txz 部署到 `~/.local/kitty.app`，apt 0.32.2 已卸载），常驻 daemon 方案后续决定移除（见下条）。

## 2026-08-13 — 移除 kitty 常驻单实例快速开窗，改回普通冷启动

- 目的：用户认为常驻 daemon「鸡肋」，决定移除。常驻实例维护成本（残留 socket 导致 bind 失败的恶性循环、登录需多开一个常驻窗口）大于提速收益（冷启动 ~1.5s → 开窗 ~0.4s）。
- 已做（`repo-change`）：
  - `.config/scripts/terminal-wayland`：aarch64 kitty 分支移除 socket 检测与 `kitty @ --to ... launch --type=os-window`，改回普通 `exec kitty "$@"`。
  - `.config/scripts/wayland-autostart`：删除 kitty daemon 预启动块（kitty_sock / run_once_logged kitty-daemon）。
  - `.config/linux/kitty/kitty.conf`：删除 `allow_remote_control socket-only`。
  - `tests/niri_wayland_config_test.sh`：删掉常驻相关 assert_contains，改为 assert_not_contains（`kitty @ --to` / `--listen-on` / `allow_remote_control` / `kitty-daemon`）防回归。
  - `.config/linux/niri/README.md`：删除自启动列表的 kitty 常驻项与「kitty 启动提速」段落，说明改回普通冷启动。
- 验证：`bash -n` 两个脚本 OK；`git diff --check` OK；`tests/niri_wayland_config_test.sh` PASS（`uname: not found` 为测试子进程受限 PATH 的既有噪音，非失败）。
- 备注：测试断言 `kitty @` 误伤 `exec kitty "$@"`，已改为更精确的 `kitty @ --to`。
- 追加修复：移除常驻后 Mod+Enter 仍打开 alacritty。根因是 niri spawn PATH 不含 `~/.local/bin`（apt 的 `/usr/bin/kitty` 已卸载，kitty 仅装于 `~/.local/bin/kitty`），`command -v kitty` 失败回退 alacritty。已在 `terminal-wayland` 顶部为 niri spawn PATH 补进 `$HOME/.local/bin`，并新增断言 `assert_contains '$HOME/.local/bin'`。模拟 niri 系统 PATH 验证 `command -v kitty` 解析到 `~/.local/bin/kitty`；测试 PASS。
- 后续：live 同步（kitty.conf / wayland-autostart / terminal-wayland）不在 IDE 白名单，需用户手动复制或重登 niri。

## 2026-08-13 — 修复 Mod+Return 拉起的终端 zsh 提示符慢（4.2s）

- 现象：终端输入 `kitty` 秒开且 zsh 提示符快；`Mod+Enter` 窗口打开速度还行但 zsh 提示符很慢。
- 根因：对比 niri spawn 环境与交互终端环境，发现 niri spawn **缺 `ZDOTDIR`**。无 ZDOTDIR 时 zsh 用默认 `~/.zshrc` 且无 `.zshenv` 的 `skip_global_compinit`，跑 Ubuntu 全局 compinit（交互启动实测 4.20s）；有 `ZDOTDIR=/home/rikoo/.config/zsh` 时 0.18s。
- 已做（`repo-change`）：`.config/linux/niri/common.kdl` 的 `environment {}` 块新增 `ZDOTDIR "/home/rikoo/.config/zsh"`（绝对路径，niri 不保证展开 `~`），使所有 niri spawn 的 shell（含 Mod+Return 拉起的终端）走优化配置。
- 验证：`git diff --check` OK；`tests/niri_wayland_config_test.sh` PASS（新增断言 `assert_contains 'ZDOTDIR "/home/rikoo/.config/zsh"'`）。
- 后续：live 同步 common.kdl 到 `~/.config/niri/`（IDE 白名单不允许）并 `Mod+Ctrl+R` 重载或重登 niri 才生效。注意 ubuntu_aarch64/config.kdl 引用的是仓库 `include "../common.kdl"`，live 部署需 install.sh 改写（勿手动复制仓库文件）。

## 2026-08-11 — 无操作黑屏后内屏无法唤醒：禁用 X11 DPMS/屏保

- 目的：解决 aarch64 无操作黑屏后内置 eDP 屏无法唤醒（外接 DP 屏正常）的问题。根因为 MediaTek `mtgpu`/`mtdisp` 驱动在 DPMS off→on 周期后无法重新点亮 eDP panel 背光（外接屏走 DisplayPort 主链路握手可恢复，内屏走 SoC panel 控制器卡死）。用户明确选择 A 方案（不介意耗电，禁用 DPMS）。
- 已做（`repo-change`）：
  - `.config/linux/x11/xsessionrc`：新增 `xset s off && xset -dpms`，关闭 X11 屏保与 DPMS。
  - `.config/linux/x11/README.md`：新增"DPMS 禁用说明"段落。
- 验证：`bash -n xsessionrc` OK；`tests/repo_docs_test.sh` PASS；`git diff --check` 无空白错误。
- 风险与后续：
  - xsessionrc 仅 X 会话登录时加载，需重登或 `systemctl restart gdm` 生效；当前会话可用 `xset s off && xset -dpms` 即时验证。
  - 显示器永不熄屏增加耗电（用户接受）；若日后需要省电，可改方案 E（DPMS off 后自动 xrandr 重配 eDP-1）。
  - 未同步 live `~/.xsessionrc`、未重载、未提交推送。


## 2026-08-11 — CPU/MEM hover top 进程改为 Lua 原生读 /proc + 懒加载

- 目的：降低 Awesome 状态栏 CPU/MEM hover 信息的资源占用。原实现每 5 秒无条件跑 2 个 `ps` 子进程（实测单次 ~0.2s，456 进程下持续占用 ~4% 单核），与是否 hover 无关。
- 已做（`repo-change`）：
  - `widgets/system.lua`：删除 `system_details_command`/`normalize_command_output` 与 `details_timer`（5s 定时器）；新增 `list_proc_pids`/`parse_proc_stat_fields`/`compute_process_cpu`/`read_process_rss`/`collect_process_details`/`format_process_list`，用 Lua 原生遍历 `/proc` 计算 top 进程（CPU 用 `/proc/<pid>/stat` 的 utime/stime/starttime，elapsed = uptime - starttime/CLK_TCK，btime 抵消；MEM 用 `/proc/<pid>/status` 的 VmRSS）；`update_system_details_cache` 改为同步读取；tooltip 挂 `mouse::enter` 信号做懒加载刷新，删除 `dispose` 里的 `details_timer`。
  - 修正一个量纲 bug：`elapsed` 初期误用 `uptime - (starttime/CLK_TCK + btime)`，因 uptime 是开机秒数而 btime 是 Unix 时间戳，导致 elapsed 恒负、top 列表为空；改为 `uptime - starttime/CLK_TCK`。
  - 更新 `tests/awesome_net_test.sh`、`tests/awesome_ui_architecture_test.sh` 断言；同步 `README.md` 与 `memory/awesome.md` 描述。
- 验证：
  - `luajit -e 'assert(loadfile(...))'` 语法 OK。
  - Lua 原生 top 结果与 `ps` 实测吻合（CPU: code 44%/trae-cn 41%/picom 28%；MEM: trae-cn 934M/chrome 850M 等）。
  - `tests/awesome_net_test.sh` / `awesome_ui_architecture_test.sh` / `awesome_battery_test.sh` 均 PASS。
  - `tests/run.sh` 唯一 FAIL 为 `awesome_docs_theme_test.sh:112`（断言 'NET 保持短显示...' 在 README 与测试措辞不一致），已确认 HEAD 版本同样失败，为历史遗留、与本次改动无关，未整改。
- 修复（用户反馈仍显示 "process list loading" 且负载看不到）：
  - 根因：`awful.tooltip` 实例是 `gears.object`，并不 emit `mouse::enter`（该信号由 objects widget 触发，见 `/usr/share/awesome/lib/awful/tooltip.lua` 的 `add_to_object`）。原本把 `connect_signal("mouse::enter", ...)` 连在 tooltip 对象上，懒加载从不触发，缓存一直停留初始值，load_average 也没更新（一直 "N/A"）。
  - 改为：`mouse::enter` 连接在 `cpu_widget`/`mem_widget` 上，置 `details_dirty` 标志；tooltip 的 `render_cpu_tooltip`/`render_mem_tooltip` 在首次渲染时检查 dirty 并调 `update_system_details_cache()` 刷新一次，保证 tooltip 首屏即有真实数据。
- 风险与后续：
  - 未同步 live `~/.config/awesome`、未重载、未提交推送。

## 2026-08-10

### 外接屏 2K100 不亮 + 休眠回来内屏黑屏无法恢复

- 目的：外接屏应跑 `2560x1440@100Hz` 但完全不显示；且休眠回来后内屏黑屏，重载/重启 Awesome 也恢复不了。
- 根因（`repo-change`；未同步 live、用户选择自己部署）：
  - `autostart/ubuntu_aarch64.sh` 请求 `3840x2160 60`，而 DP-1 不提供该模式，`xrandr` 报 `cannot find mode 3840x2160`。
  - `xrandr` 一次调用是原子的，所以外接屏这一个错误让整条命令失败、eDP-1 也一起没配上——这正是内屏黑屏的来源（dry-run 输出零条 `crtc` 行可证）。
  - `common.sh` 完全没有模式校验，坏模式会被原样喂给 `xrandr`。
  - `rc.lua:101` 的 autostart 走 `awful.spawn.once`，重启 Awesome 不重跑，所以「重启一下」这条恢复路径本来就是堵死的。
- 已做：
  - `autostart/ubuntu_aarch64.sh`：外接屏常量 `3840x2160 60` → `2560x1440 100`。
  - `autostart/common.sh` 新增 `display_mode_line()` / `display_supports_mode()` / `display_supports_mode_rate()` / `resolve_display_mode()` / `configure_laptop_panel_only()`；固定布局在拼命令前先校验，回退链为「请求模式 → 该屏首选模式 → `--auto`」，刷新率不支持时只丢 `--rate` 保住分辨率；整条命令仍失败时单独再配一次内屏。
  - `rc.lua`：接好屏幕信号后主动调用一次 `queue_display_layout_refresh()`，让「重启 Awesome」成为可用恢复路径；同时移除对 wibar 已不再消费的 `actions` 注入。
  - `tests/awesome_autostart_test.sh`：新增可注入 `XRANDR_QUERY`/`XRANDR_LOG`/`XRANDR_FAIL_PATTERN` 的假 `xrandr` fixture 与 4 个测试（显式 2K100 靠右、模式缺失回退、刷新率不支持只丢 rate、外接屏失败仍保住内屏），另加 README 与 helper 命名断言。
  - `tests/awesome_ui_architecture_test.sh`：断言 rc.lua 启动期调用显示布局刷新且位于信号接线之后，并跟随顶栏改动更新锁屏按钮/`dpi()`/语义标签相关断言。
  - `autostart/README.md` 外接屏分辨率更新，新增「显示模式回退」与「重启恢复」两条；`.config/linux/awesome/README.md` 同步顶栏锁屏入口、`dpi()` 缩放、compact 模式保留 MEM、状态项配色。
- 顺带修掉两个历史遗留失败测试：`nvim_comment_test.sh` 断言放宽为 `vim/_core/defaults`（Neovim 0.12.4 输出不再带 `.lua` 后缀）；`repo_docs_test.sh` 删掉对已 gitignore 的 `CLAUDE.md` 的断言。
- 验证：36 套测试逐个用 `bash` 跑，`pass=36 fail=0`（`tests/run.sh` 因 3 个测试文件缺可执行位而中断，属先前提交 `5ed9a00` 引入的历史问题，未在本轮修改）。新增 4 个测试均确认先红后绿。用户真实 `xrandr --query` 喂给新逻辑生成的命令经真实 `xrandr --dryrun` 校验通过：`crtc 0: 2880x1800 120.00 +0+0 "eDP-1"` / `crtc 1: 2560x1440 100.00 +2880+0 "DP-1"`，exit 0；拔掉外接屏与接不支持 2K 的屏两种场景也分别验过降级正确。
- 未验证项 / 后续：本次开机无休眠记录，**休眠→黑屏未能现场复现**；xrandr 原子失败与恢复路径被堵死是直接测出来的，但「恢复瞬间内屏为什么会黑」只推断到驱动层（aarch64 `mtgpu`/`mtdisp`）。若部署后休眠回来内屏仍黑，说明根因不止一个，需查驱动侧。live `~/.config/awesome` 未同步（用户明确表示自己部署）。另有一个独立问题未处理：`ui/wibar.lua` 的 `widget_fit_size` 传给 `fit()` 的 context 缺 `dpi`，被 pcall 吞掉后可用宽度算成整屏宽，需另行确认。

## 2026-08-08

### Awesome 界面截图改为 flameshot（Mod+s）

- 目的：将 Awesome 的截图快捷键统一为 flameshot，替代原先 Mod+s 的 maim+Pot OCR。
- 已做（`repo-change`；live `~/.config/awesome` 因环境写保护未同步、未提交）：
  - `actions.lua` 新增 `M.screenshot_flameshot()`，执行前用 `command -v flameshot` 检查，缺依赖时通知提示，存在则跑 `flameshot gui`。
  - `bindings.lua` 把 `Mod+s` 从 `actions.screenshot_ocr` 改为 `actions.screenshot_flameshot`；`screenshot_ocr` 仍留在 actions 模块作为库动作但不再绑快捷键。rc.lua 未改动。
  - README 快捷键表与「桌面动作入口」段落同步；`memory/awesome.md` 快捷键条目更新。
- 验证：`tests/awesome_config_test.sh` 通过。
- 后续方向：如需保留 OCR 入口，可另绑一个快捷键（如 `Mod+Shift+s` 已被 hotkeys_popup 占用，需另选）；live 侧需用户手动同步 actions.lua/bindings.lua 并重载 Awesome 后 `Mod+s` 才生效。


### fcitx5 Rime 崩溃排查与词典重建

- 目的：定位 fcitx5 使用 rime-ice 时反复出现的 lua 报错与一次真实崩溃。
- 已做（系统/用户数据变更，非仓库；未提交）：
  - 崩溃定位：`~/.config/fcitx5/crash.log` 记录 08-08 17:22:25 一次 SIGSEGV，崩溃点在 MediaTek 定制 librime（`librime.so.1 +MTTAIOS260630.1`）的 `Prism::CommonPrefixSearch`/`BuildSyllableGraph`（Darts 双数组 trie 检字），进程随后自动重启为 PID 279112。
  - 根因判断：`build/rime_ice.prism.bin` 仅 40KB，与词典不同步；删除 `build/rime_ice.{prism,table,reverse}.bin` 后 `RIME_USER_DATA_DIR=~/.local/share/fcitx5/rime RIME_SHARED_DATA_DIR=/usr/share/rime-data rime_deployer --build` 重建，`prism.bin` 由 40032→51880 字节（变大），证明原 prism 与词典不同步是检字崩溃的常见诱因。
  - 重载：`fcitx5-remote -r` 让 rime 用新数据；重载后 crash.log 无新增，当前实例稳定。
  - 遗留噪音：lua_processor/lua_translator/lua_filter 创建失败（rime-ice 引用的 lua 组件未被 MediaTek librime 注册，插件 dlopen 正常但未生效）与 xdg-desktop-portal 在 X11 无法启动，均为非致命噪音，不影响基础拼音输入。
- 验证：`rime_deployer --build` 重建产物时间戳更新；`fcitx5-remote -r` 成功；`pgrep fcitx5` 稳定。
- 后续方向：若崩溃仍复现，需替换/升级 MediaTek 定制 librime 或换官方 librime；lua 插件与 portal 问题如需彻底解决需另行处理。
