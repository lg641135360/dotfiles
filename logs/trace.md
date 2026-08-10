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
- 长期有效的规则、方法论或决策边界，不应长期停留在 `logs/trace.md`；若跨多次任务仍有效，应提升到对应 `memory/` 规则文件。

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

### picom 低占用优化（降负载）

- 目的：降低 picom 在 aarch64 上的 CPU 占用，缓解系统卡顿。
- 背景：负载常驻 ~10/12 核，picom 占 15.2% CPU；`dual_kawase` blur 是主要开销。
- 已做（`repo-change` + live 同步 `~/.config/picom.conf`；未提交）：
  - `picom-arch_aarch64.conf`：blur 改 `method = "none"`（关模糊）、shadow-radius 10→6、shadow-opacity 0.4→0.3、corner-radius 16→8。
  - 同步 live 并重启 picom（`pkill -x picom; picom --experimental-backends`）。
  - README、`memory/desktop.md` 同步更新。
  - 顺带修复 `actions.lua` 第 86 行 `Function` 误大写为 `function` 的语法错误。
- 验证：picom CPU 15.2% → 6.7%（降幅超一半）；`tests/awesome_config_test.sh` PASS；配置解析无错。
- 后续方向：剩余负载大头是 CherryStudio（~35%）与 Trae IDE（~30%），与配置无关；如需进一步降负载应处理这两个应用。

### 内置屏黑屏排查（eDP 链路重初始化）

- 目的：解决内置屏物理不亮的问题。
- 排查：软件全部正常——xrandr 里 eDP-1 connected/active 主屏、背光 `m1000_backlight` brightness 423/500 且 `bl_power=0`、DPMS On、`/proc/acpi/button/lid` 为 open、AC 供电。据此判断为 **eDP 链路卡住**而非背光/DPMS/合盖问题。
- 修复：`xrandr --output eDP-1 --off && sleep 3 && xrandr --output eDP-1 --auto --primary --mode 2880x1800 --rate 120` 强制重建 eDP 链路，内置屏恢复点亮。
- 注意：关屏重开会导致外接 DP-2 重排回 `+0+0` 与内置屏重叠，需手动 `xrandr --output DP-2 --mode 2560x1440 --rate 59.95 --right-of eDP-1` 恢复右侧布局（总尺寸 5440x1800）。
- 验证：用户确认内置屏已亮；布局已恢复外接在右侧。
- 后续方向：若黑屏复现，可考虑在相关脚本加入 eDP-1 检测/重初始化逻辑；此问题多为偶发链路状态，非配置所致。

## 2026-08-04

### niri / Waybar 网络提示与认证窗口优化

- 目的：让网络 tooltip 按连接类型提供有效信息，并提高认证窗口可读性。
- 已做（`repo-change`，未同步 live、未提交）：
  - 网络模块保留常驻实时上下行带宽；tooltip 拆分为 Wi-Fi、有线和断开三种状态，Wi-Fi 增加信号强度，有线不再显示无意义 SSID。实测 Waybar 0.15 中相同带宽占位符在主模块与 tooltip 的单位换算不一致，因此 tooltip 不再重复显示速率，只保留连接元数据，以顶栏常驻速率为准。
  - `#network.disconnected` 使用 Catppuccin 红色显示断网状态。
  - Polkit、`pinentry`、`ssh-askpass` 认证窗口在保留浮动的同时覆盖为 `opacity 1.0`，README 与回归断言同步更新。
- 验证：Waybar JSON 解析、`niri validate -c .config/linux/niri/ubuntu_x64/config.kdl`、`tests/niri_wayland_config_test.sh`、`tests/repo_docs_test.sh`、`git diff --check` 均通过。

### Waybar 第三批样式整理

- 目的：收窄不必要的 GTK CSS 动画作用域并统一用户可见文案。
- 已做（`repo-change`，未同步 live、未提交）：
  - 移除全局 `*` 选择器上的 transition，仅对 workspace 按钮、时钟、网络、音量、CPU 和内存模块保留颜色/背景色过渡；删除未使用的边框色和透明度 transition。
  - 音量静音文案由英文 `mute` 统一为中文“静音”，README 与回归断言同步更新。
  - 保留现有模块 padding：当前 36px 顶栏与各模块 `0 7px` 间距一致，缺少 live 视觉证据时不做无依据压缩。
- 验证：Waybar JSON 解析与 `tests/niri_wayland_config_test.sh` 通过；后续完整验证见本轮收尾记录。

### niri / Waybar 第二批信息降噪与隐私提示

- 目的：补充屏幕共享/麦克风使用提示和时钟月历；网络模块原计划降噪，后按用户反馈保留其监控价值。
- 已做（`repo-change`，未同步 live、未提交）：
  - 新增 Waybar `privacy` 模块，仅监测 PipeWire 屏幕共享和麦克风采集，并用 Catppuccin 红/紫状态样式突出显示。
  - 时钟悬停新增 ISO 8601 月历，README 与回归断言同步更新。
  - 网络模块曾改为默认显示 SSID/接口、点击切换带宽；用户指出这会使模块失去意义，现已恢复常驻实时上下行带宽、2 秒刷新和单击打开网络编辑器，并将该偏好记录到 `memory/desktop.md`。
- 验证：Waybar JSON 解析、`tests/niri_wayland_config_test.sh`、`tests/repo_docs_test.sh`、`git diff --check` 均通过；`ldd` 确认 Waybar 0.15.0 本体链接 `libpipewire-0.3.so.0`，具备 privacy 模块所需的 PipeWire 支持。未启动第二个 Waybar 实例，privacy 的实际捕获状态识别与月历观感留待同步 live 后验证。

### niri / Waybar 第一批一致性整理

- 目的：落实 niri / Waybar 配置分析中的第一批一致性修复。
- 已做（`repo-change`，未同步 live、未提交）：
  - Waybar `niri/window` 增加 VS Code、Chrome、Alacritty 常见标题后缀 rewrite，并补充对应回归断言，使配置兑现现有 README 描述。
  - 修正 `common.kdl` 中已过期的 awww 双壁纸 Overview 注释，改为描述当前 `backdrop-color` + workspace 卡片阴影方案。
  - 删除未被调用且要求无效 `workspace-wrap-around` 节点的死测试；实测 niri 26.04 将该节点放入 `layout` 会报 `unexpected node`，因此不引入不受支持的行为。
- 验证：Waybar JSON 解析、`niri validate -c .config/linux/niri/ubuntu_x64/config.kdl`、`tests/niri_wayland_config_test.sh`、`tests/repo_docs_test.sh`、`git diff --check` 均通过。

### 新增飞连临时停止脚本

- 目的：为持续占用单核 CPU 的 `corplink-uc` 提供临时停止入口，当前会话停止、下次重启按原开机配置自动恢复；该进程由 `corplink.service` 拉起，单元配置为 `Restart=always`。
- 已做（`repo-change` + 用户同步 live 并执行临时停止，未提交）：
  - 新增 `.config/scripts/corplink-service`，支持 `status`、`disable`、`enable` 和帮助；默认状态查询不提权，变更操作才通过 sudo 获取 root 权限。
  - `disable` 先用 `systemctl stop` 临时停止服务；因厂商单元使用 `KillMode=process`、实测会残留 5 个 `corplink-uc`，随后对该单元整个 cgroup 依次发送 SIGTERM/SIGKILL，并同时验证单元 inactive、cgroup 无残留进程。不执行 `disable`、`mask` 或 `daemon-reload`，保留原开机启动关系。`enable` 仅立即启动服务。
  - `install.sh` 将脚本纳入 Linux 通用配置，安装到 `~/.config/scripts/corplink-service`；`.config/scripts/README.md` 补充用法和企业 VPN/终端安全风险说明。
  - 新增 `tests/corplink_service_test.sh`，以临时假的 `systemctl`、`sudo` 和 `id` 覆盖默认状态、stop→SIGTERM→SIGKILL 顺序、单元仍 active/cgroup 仍有进程的失败路径、启用、非 root 提权、非法参数、安装器与文档契约；测试不会操作真实服务。
- 验证：`sh -n .config/scripts/corplink-service`、`bash -n install.sh`、`tests/corplink_service_test.sh`、`tests/repo_docs_test.sh`、`git diff --check` 均通过；仓库脚本与 `~/.config/scripts/corplink-service` 内容一致。用户执行 `disable` 后，`corplink.service` 为 inactive，服务 cgroup 与 `corplink-uc` 进程均已清空。`tests/run.sh fast` 在未改动的 `awesome_autostart_test.sh` ARM 外接屏既有断言处失败，本轮涉及文件的针对性测试已通过；环境未安装 `shellcheck`，该项未运行。
- 运行态：飞连仅临时停止，未改变开机启动关系；下次重启会按原配置恢复。临时停止期间可能影响公司内网、访问控制或终端合规。

## 2026-07-31 — dingtalk-wayland 增加 restart 子命令

- 目的：钉钉长期运行存在内存累积（实测主进程 9 天达 3GB、占用 191MB swap，总 RSS 5.55GB/17 进程），需要可执行的重启入口缓解。
- 已做（`repo-change`，未同步 live、未提交）：
  - `.config/scripts/dingtalk-wayland`：
    - 在脚本开头加 `case "${1:-}" in restart)` 分支，先 `pkill -u "$(id -u)" -f 'com\.alibabainc\.dingtalk'`，再用 `pgrep` 轮询最多 5 秒等待退出，然后 `shift` 落入原启动流程；无参数时行为不变（不检查已有实例）。
    - 问题1修复：`restart` 分支前置 `for dep in pkill pgrep id` 检查，任一缺失则 `notify_problem` + `exit 127`，不再静默跳过导致新旧实例并存。
    - 问题2修复：等待循环结束后再做一次 `pgrep` 校验，仍命中则 `pkill -9` SIGKILL 强杀（钉钉作为 Electron 应用常响应慢），然后继续启动流程——restart 语义就是必须重启，不能因旧进程未退出而放弃。
    - 问题3修复：新增 `print_usage` 函数和 `usage|--help|-h` 子命令，列出用法、环境变量、示例。
    - 问题4修复：在子命令 case 之后加 `if [ "${1:-}" = "--" ]; then shift; fi`，兑现 usage 中承诺的 `--` 分隔符语义，使 `dingtalk-wayland -- --flag` 与 `dingtalk-wayland restart -- --flag` 行为一致。
    - 将 `notify_problem` 提到脚本开头（供 restart 分支复用）。
  - `tests/niri_wayland_config_test.sh`：在 `test_dingtalk_wayland_entrypoint_preserves_preload_contract` 内追加 `restart)`、`pkill`、`pgrep`、`缺少基础命令`、`for dep in pkill pgrep id`、`pkill -9`、`SIGKILL`、`print_usage`、`usage|--help|-h`、`dingtalk-wayland restart`、`显示此帮助`、`"${1:-}" = "--"`、`原样透传给钉钉` 共 13 条断言；保留原有 `nohup`/`exit 0`/preload 合约断言。
  - 文档同步：`.config/scripts/README.md` 表格行、`.config/linux/niri/README.md` 钉钉段落、`memory/dingtalk.md` 启动命令块均补充 `restart`/`usage` 子命令与 SIGTERM→SIGKILL 两段式 kill 说明。
- 验证：
  - `sh -n .config/scripts/dingtalk-wayland` 通过。
  - dingtalk 相关断言单独运行 PASS（含 13 条新断言）。
  - `tests/repo_docs_test.sh` PASS。
  - 实测 `dingtalk-wayland usage` 输出正确帮助文本。
  - 实测 `PATH` 缺 pkill 时 `dingtalk-wayland restart` 正确报错 `缺少基础命令 pkill` 并退出。
  - `tests/niri_wayland_config_test.sh` 中 `test_install_copies_wayland_files_when_niri_exists_outside_wayland_session` 失败，已确认是历史遗留（stash 后同样失败），非本轮引入。
- 后续：用户确认后同步 live（`cp .config/scripts/dingtalk-wayland ~/.config/scripts/`）并提交。

## 2026-07-31 — Brew 二进制 RPATH 修复（zoxide GLIBC_2.39 报错/p10k 警告）

- 目的：修复用户启动 zsh 时 `zoxide: GLIBC_2.39 not found` 报错与 p10k instant prompt 警告。
- 根因诊断：
  - 表象：p10k 报 "console output during zsh initialization"，stderr 含 `zoxide: /usr/lib/aarch64-linux-gnu/libc.so.6: version GLIBC_2.39 not found`。
  - 真因：`/etc/profile.d/mtcodec.sh` 与 `musa-sdk.sh` 设置 `LD_LIBRARY_PATH` 包含 `/usr/lib/aarch64-linux-gnu/`（系统 libc 2.35 所在）。brew 包二进制的 RPATH 缺少 glibc lib 路径，glibc 又是 keg-only（不软链到 `/home/linuxbrew/.linuxbrew/lib`），导致 ld.so fallback 到 LD_LIBRARY_PATH 找到系统 libc 2.35，缺少 GLIBC_2.38/2.39 符号。
  - 为什么 sandbox 测试能跑：sandbox 未继承 `/etc/profile.d/` 的 LD_LIBRARY_PATH，且简单命令未触发需要新符号的代码路径。
  - 为什么 `brew reinstall` 未修复：bottle 是预编译的，RPATH 固定，reinstall 只是重新解压不改 RPATH。
  - lsd 隐藏问题：原 RPATH 用版本硬编码 `Cellar/glibc/2.39/lib`，但 brew glibc 升级到 `2.39_1` 后路径失效，污染环境下 SIGILL。
- 已做（`repo-change` 之外的 live 二进制改动，已获用户授权）：
  - `brew reinstall zoxide nvim tmux ripgrep bat luajit`（未修复 RPATH，但刷新了二进制）。
  - `patchelf --force-rpath --set-rpath` 给 7 个二进制（zoxide/nvim/tmux/rg/bat/luajit/lsd）的 RPATH 开头加入 `/home/linuxbrew/.linuxbrew/opt/glibc/lib`（稳定路径，不随版本变化），lsd 同时加入 gcc lib 路径。用 `--force-rpath` 保持 RPATH（优先级高于 LD_LIBRARY_PATH）而非 RUNPATH（优先级低于 LD_LIBRARY_PATH）。
- 验证：
  - 7 个工具在无污染和模拟污染（`LD_LIBRARY_PATH=/usr/local/mt_vaapi/lib:/usr/local/musa/lib:/usr/lib/aarch64-linux-gnu/musa/:/usr/lib/aarch64-linux-gnu/`）环境下 ldd 均无 GLIBC 错误、实际运行均正常。
  - `zoxide init --cmd cd zsh` 在污染环境下 exit=0（用户原始报错命令已修复）。
  - `tests/zsh_path_test.sh` 与 `tests/zsh_functions_test.sh` 均 PASS，无回归。
- 风险与后续：
  - patchelf 改动是 live 二进制层面的，`brew upgrade` 或 `brew reinstall` 这些包时会覆盖修复（bottle 重新解压恢复原 RPATH）。若升级后复现报错，需重新跑 patchelf。
  - 根本解决应让 brew 包官方 bottle 在 RPATH 里包含 glibc lib（已属 upstream issue 范畴）。
  - 未提交推送。
