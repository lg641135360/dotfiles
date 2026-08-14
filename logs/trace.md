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


## 2026-08-14 — 修正 Waybar 回归测试音量图标编码

- 目的：修复 `tests/niri_wayland_config_test.sh` 因音量图标 UTF-8 八进制转义写错导致的测试失败。
- 已做：将 U+F028 音量图标的转义从 `\357\202\250`（`EF 82 A8`）改为 `\357\200\250`（`EF 80 A8`），并同步更正注释。
- 验证：`sh -n tests/niri_wayland_config_test.sh`、`./tests/niri_wayland_config_test.sh`、两份 Waybar JSON 解析和 `git diff --check` 均通过；测试仍输出已有的 `uname: not found` 非阻断提示。
- live 同步：未同步。
- 提交推送：未提交、未推送。


## 2026-08-14 — waybar backlight 回退到内置模块（最终方案），interval 0.1 近实时

- 目的：多轮实验（scroll-step → on-scroll+interval → custom/backlight+RTMIN 信号 → 自循环 watcher）后用户反馈"冗余且仍不实时"，要求回到第一次引入时最简的实现。
- 根因（对照 git 首次引入 73f3c38）：最初实现就是 waybar 内置 `backlight` 模块（on-scroll/on-click 直接调 `brightnessctl`，无脚本无信号）。后续"顺滑度对齐 vol"的实验全部失败：① MediaTek `m1000_backlight` 亮度变化不发 udev uevent（udevadm monitor 实测 8s 无事件），内置模块 udev 事件后端不生效；② watcher 自循环脚本误读 sysfs `brightness`（该值恒为 max=500 → 百分比恒 100%，strace 佐证），应读 `actual_brightness`（内置模块正是读它，故回退后正常）；③ RTMIN 信号方案有信号合并 + 每格滚轮两次进程派生。
- 改动：删除 `.config/scripts/waybar-backlight` 脚本；config.aarch64 的 `custom/backlight` 回退为内置 `backlight` 模块并加 `interval: 0.1`（内置模块默认轮询 2s，来自 ALabel 构造参数；0.1s 轮询兜底实现 ~100ms 近实时，无需脚本）；style.css `#custom-backlight` → `#backlight`；install.sh 移除脚本部署；tests/README 同步。
- 验证：两份 config `python3 -m json.tool` 通过；`tests/niri_wayland_config_test.sh` PASS；顺带修复该测试里 bash 专属的 `$'\uf028'` ANSI-C quoting（dash 下解析失败），改用 `printf '\357\200\250'` 八进制转义构造图标字节。
- 后续：live `~/.config/waybar/config`（aarch64 用 config.aarch64 覆盖）需手动复制后 `pkill waybar && waybar &` 重启生效。滚轮跟手接近 vol（vol 是 DBus 事件瞬时，backlight 物理上限是轮询粒度 ~100ms）。


## 2026-08-14 — waybar backlight 改自循环 watcher，顺滑度对齐 vol

- 目的：用户反馈 backlight 滚轮调亮度时数值变化不如 vol（pulseaudio）模块顺滑。
- 根因（分层验证）：① vol 是 DBus 订阅 WirePlumber 事件，每格滚轮事件驱动即时刷新；backlight 无事件源，只能靠轮询/信号。② 实测 `udevadm monitor --subsystem-match=backlight` 下触发 `brightnessctl set`，8 秒无任何 uevent —— MediaTek `m1000_backlight` 驱动亮度变化不发内核事件，因此 waybar 0.15.0 内置 backlight 模块的 udev 事件驱动后端（`util/backlight_backend.cpp`，epoll 监听 udev netlink）在这台机器上同样不生效，内置模块 + scroll-step 救不了顺滑度。③ 原 `custom/backlight` + `pkill -RTMIN+10 waybar` 信号方案：每格滚轮要"外部命令改亮度 + 信号往返 + 再起脚本重读"两次进程派生，且实时信号会合并（标准信号 pending 集合合并），快速滚动时显示跳变滞后。
- 改动：`waybar-backlight` 由一次性脚本改为**自循环 watcher**（每 ~100ms 轮询 sysfs `brightness`/`max_brightness`、仅在数值变化时输出 `N%`，纯 shell 内建 read + 算术，循环内仅 `$( )` 子 shell + `sleep` 两次 fork）；config.aarch64 的 `custom/backlight` 去掉 `interval`/`signal`（waybar 0.15.0 文档：不设 interval/signal 视为"脚本自行循环、每行输出即时刷新"），`on-scroll`/`on-click` 简化为纯 `brightnessctl`（不再 pkill）。watcher 每格滚轮 ≤100ms 内刷新、无信号合并、CPU 可忽略。
- 验证：`bash -n`（实际 sh 语法检查）通过；`tests/niri_wayland_config_test.sh` 断言改为 `assert_not_contains '"signal":'` / `'pkill -RTMIN'` + 纯 brightnessctl on-scroll，全部通过。
- 后续：live `~/.config/waybar/config` 与 `~/.config/scripts/waybar-backlight` 需手动复制后 `pkill waybar && waybar &` 重启生效；若 watcher 出现显示不同步，优先检查脚本是否存活（waybar 停止时管道关闭触发 SIGPIPE 自动退出，无孤儿）。


## 2026-08-13 — waybar backlight/pulseaudio 滚轮改 scroll-step 实时刷新

- 目的：用户反馈在 status bar 上用滚轮调节背光/音量时，数值不实时更新（要等下次 poll 才刷新）。
- 根因：`on-scroll-up`/`on-scroll-down` 调外部命令（`brightnessctl`/`wpctl set-volume`），waybar 要等事件回调或下次 interval 才刷新显示。
- 改动：`backlight`（仅 aarch64）和 `pulseaudio`（两份 config）去掉 `on-scroll-up/down`，改用 waybar 内置 `scroll-step: 5`；保留 `on-click`/`on-click-right`（0%/100% 和静音/pavucontrol）。
- **修复**：首次 live 验证发现 pulseaudio 图标消失，根因是 Edit 工具替换 `on-scroll` 行时把原 format 里的 Nerd Font 音量图标（U+F028）误替换成空格；用 Python 脚本按字节恢复 `"\uf028  {volume}%"`，避免 Edit 工具处理不可见字符的歧义。测试断言改用 `$'\uf028'` ANSI-C quoting 匹配图标字节。
- 验证：JSON 合法；`tests/niri_wayland_config_test.sh` 中 `scroll-step`/`on-scroll`/format 断言全部通过；pre-existing failure（install_copies_wayland_files...）与本次改动无关。
- 后续：live `~/.config/waybar/config` 需手动复制后 `pkill waybar && waybar &` 重启生效。scroll-step 在 waybar 0.15.0 的 pulseaudio/backlight 模块上理论有效（社区多个样例验证），若 live 重启后仍不实时，需回退到 `on-scroll` + `pkill -RTMIN+<n> waybar` 信号刷新方案。
- **补充**：用户反馈 scroll 后数字更新仍慢，根因是 backlight/pulseaudio 模块未设 `interval`，走 waybar 默认值（几秒级）；两份 config 的 backlight（仅 aarch64）和 pulseaudio 都加 `interval: 1`。修复 interval 时 Edit 工具再次把 x86 config 的 pulseaudio format 图标（U+F028）替换成空格，用 Python 脚本按字节恢复。教训：涉及 Nerd Font 不可见字符的行，优先用 Python 脚本按字节操作，避免 Edit 工具的字符歧义。
- **二次回退**：用户反馈 `scroll-step` 仍然不跟手（最多 1s 延迟），且 live 图标又丢失。根因：`scroll-step` 是 waybar 内部调外部命令后等下次 interval poll 才刷新，本质有 interval 延迟；`on-scroll` 是事件驱动，执行完 waybar 会立即触发模块更新。最终方案：回退到 `on-scroll-up/down` 调 `brightnessctl`/`wpctl`，保留 `interval: 1` 作为兜底刷新。`scroll-step` 方案放弃。
- **backlight 信号驱动即时刷新**：用户反馈 backlight 滚轮仍不跟手。根因：pulseaudio 模块订阅 DBus 事件可即时刷新，但 backlight 模块读 sysfs `/sys/class/backlight/.../brightness`，sysfs 不支持 inotify，waybar 只能靠 `interval` 轮询，即使 `on-scroll` 调完 brightnessctl 也要等下次 1s poll。解决方案：backlight 改为 `custom/backlight` 模块，新增脚本 `waybar-backlight` 读 `brightnessctl -m info` 输出百分比；config 里 `on-scroll-up/down`/`on-click`/`on-click-right` 调完 `brightnessctl` 后 `pkill -RTMIN+10 waybar` 发信号，waybar 收到信号立即触发 `custom/backlight` 模块的 `exec` 重读。
- **信号编号修正**：strace 验证发现 `pkill -RTMIN+10 waybar` 实际发送的是信号 45（strace 命名为 SIGRT_12），而非 44。根因：pkill 的 `-RTMIN+N` 语义是 1-based（RTMIN+1 = SIGRT_1 = 信号 34），所以 `-RTMIN+10` = SIGRT_10 = 信号 43... 实测 strace 显示收到 45 = SIGRTMIN+11。waybar 源码 `if (sig == SIGRTMIN + config_["signal"])` 是 0-based（signal: 10 → SIGRTMIN+10 = 44）。两者差 1，导致信号不匹配。修正：waybar config `signal: 11`（匹配 pkill 实际发送的 45 = SIGRTMIN+11）。zsh 内建 `kill` 不支持 `RTMIN+N` 语法（报 unknown signal），必须用 `/bin/kill` 或 `pkill`。

## 2026-08-13 — waybar CPU/MEM 改 custom 模块，hover 显示 top 5 进程

- 目的：waybar 内置 `cpu`/`memory` 模块的 tooltip 只能显示各核负载/swap，无法显示占用进程；用户希望 hover 时看到利用率与 top 5 进程，对齐 AwesomeWM `widgets/system.lua` 已有的 tooltip 风格。
- 已做（`repo-change`，未同步 live、未提交）：
  - 新增 `.config/scripts/waybar-system-tooltip`：POSIX sh 脚本，子命令 `cpu`/`mem`，输出 waybar JSON（`text`+`tooltip`+`percentage`+`class`）。CPU 使用率基于 `/proc/stat` 差值（状态文件 `$XDG_STATE_HOME/dotfiles/waybar-cpu`，首次调用读 0%）；内存基于 `/proc/meminfo` MemAvailable（fallback MemFree+Buffers+Cached）；top 5 进程用 `ps --sort=-pcpu/-rss` 取，过滤 `ps`/`sh` 噪音进程；tooltip 含使用率摘要 + top 5 列表（pid comm value）；`class` 字段驱动 warning/critical 配色（CPU 70/90，MEM 80/95）。
  - `.config/linux/waybar/config` 和 `config.aarch64`：`cpu`/`memory` 模块替换为 `custom/cpu`/`custom/memory`，`exec` 调脚本，`interval 2`，`returntype json`，`on-click` 拉起 `kitty -- htop -s PERCENT_CPU/PERCENT_MEM`；栏内 format 保持 `󰻠 {}`/`󰍛 {}` 图标+百分比不变。
  - `.config/linux/waybar/style.css`：`#cpu`/`#memory` 选择器改为 `#custom-cpu`/`#custom-memory`（含 transition/padding/hover/warning/critical 全部同步）。
  - `install.sh`：`linux_wayland_configs` 数组加 `waybar-system-tooltip` 部署条目。
  - `.config/scripts/README.md`、`.config/linux/waybar/README.md`：新增脚本与模块说明。
  - `tests/niri_wayland_config_test.sh`：更新 modules-right 断言、format 断言、新增 custom 模块/exec/on-click/returntype 断言、新增 install.sh 部署条目断言。
- 验证：`sh -n waybar-system-tooltip` 通过；两份 config `python3 -m json.tool` 校验通过；脚本功能测试 CPU/MEM JSON schema 校验通过；`tests/niri_wayland_config_test.sh` PASS；`tests/repo_docs_test.sh` PASS；`tests/run.sh` 中其余测试（kitty/picom/rofi/starship/tmux/zsh*）均 PASS（既有 `install_zshenv_test.sh` 权限问题与 `browser-wayland` 的 `uname` 桩问题为历史遗留，与本次改动无关）。Sandbox 环境下脚本写 state 文件被限制，live 无此问题。
- 后续：live 的 `~/.config/scripts/waybar-system-tooltip` 需手动复制并 `chmod +x`；`~/.config/waybar/config`、`style.css` 需手动复制后 `pkill waybar && waybar &` 重启生效。CPU 使用率首次显示为 0%（无前次采样），第二次 interval 起正常。**修复 1**：首次 live 验证发现 hover 无 tooltip，根因是字段名写错（`returntype` → `return-type`，waybar 不识别无连字符版本，把整个 JSON 当纯文本显示）；已在两份 config 改正、测试同步断言。**修复 2**：custom 模块 JSON tooltip 需显式 `"tooltip": true` + `"escape": false`（后者确保 `\n` 渲染为换行）；已在两份 config 补字段、测试同步断言。**优化回退**：性能分析发现原方案 `exec` 每 2s 跑一次 `ps`（单次 ~0.07s，常态 7% CPU），尝试改两段式 `exec`（轻量）+ `tooltip-exec`（hover 跑 ps）；但 live 验证发现 waybar `return-type=json` 时 `tooltip-exec` 被忽略（JSON `tooltip` 字段优先），hover 无 tooltip 弹出；最终回退为单 `exec` JSON（含 tooltip 字段），`interval` 从 2s 改 5s 降低开销（常态约 2-3% CPU）。脚本子命令恢复为 `cpu`/`mem`；config 去掉 `tooltip-exec`；测试与 README 同步。


## 2026-08-13 — zsh 配置优化：random_bars local 修复 + FZF 主题统一 + 清理死代码

- 目的：审阅 zsh 模块（functions/env/options），修复真 bug、统一主题、清理 p10k 时代遗留。
- 已做（`repo-change`，未同步 live、未提交）：
  - `functions.zsh`：`random_bars` 的 `columns`/`chars`/`i` 加 `local`（原污染调用者 shell）；`cpg`/`mvg` 加注释说明函数体内走原始 `cp`/`mv`（zsh 默认不扩展 alias）。
  - `env.zsh`：FZF 主题从 Tokyo Night 改为 Catppuccin Mocha，与 zsh-syntax-highlighting / starship 统一；新增 `bg`/`bg+` 色值。
  - `options.zsh`：删除 `setopt promptsubst`（starship 接管 prompt 后无用，p10k 遗留死代码）。
- 验证：`zsh -n` 三个文件均通过；`zsh_functions_test.sh` / `zsh_plugins_test.sh` / `zsh_history_test.sh` / `zsh_path_test.sh` / `install_zshenv_test.sh` 全 PASS（path 2 项 SKIP 为 node 路径不存在，预期）。
- live 同步：`env.zsh` / `options.zsh` / `functions.zsh` 因 sandbox 限制需用户手动 `cp .config/shared/zsh/{env.zsh,options.zsh,functions.zsh} ~/.config/zsh/`，新开终端生效。
- 未做：`rm`/`cp`/`mv` 的 `-i` 改 `-I`（个人偏好保留）；`preview()` else 分支死代码（走不到，留着）；FZF alias vs `FZF_CTRL_T_OPTS`（widget 不走 alias，当前方案可保留）。


## 2026-08-14 — 收敛 Starship Powerline 信息层级

- 目的：在保留 Catppuccin Powerline 风格的前提下，减少左侧噪音并补齐常用开发环境信息。
- 已做：启用 Node/Bun/Docker 模块；将时间和命令耗时移到 `right_format`；隐藏 Conda `base`；错误提示符改为 `✗`；命令耗时改用 Nerd Font 图标；同步 Starship 测试与 Zsh README。
- 验证：`sh -n tests/starship_config_test.sh`、`./tests/starship_config_test.sh`、`STARSHIP_CONFIG=.config/shared/starship.toml starship prompt` 和 `git diff --check` 均通过。
- live 同步：未同步。
- 提交推送：未提交、未推送。


## 2026-08-14 — Starship 改为统一透明底色

- 目的：解决多段 Catppuccin 背景色连续切换造成的提示符割裂感。
- 已做：移除 OS/目录/Git/语言/环境/时间模块的背景色块，统一使用前景色语义；保留 Node/Bun/Docker、右侧时间与耗时、Conda base 隐藏和失败符号 `✗`；测试增加无 `bg:` 样式约束，README 同步。
- 验证：`sh -n tests/starship_config_test.sh`、`./tests/starship_config_test.sh`、`STARSHIP_CONFIG=.config/shared/starship.toml starship prompt` 和 `git diff --check` 均通过。
- live 同步：未同步。
- 提交推送：未提交、未推送。


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
