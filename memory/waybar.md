# Waybar

## 视觉
- niri 主线状态栏优先做整条连续顶栏，避免左/中/右三段独立胶囊导致一体感不足；配色使用 Catppuccin Mocha GTK CSS token，模块内部只用弱分隔、hover 和少量图标化文字降噪。

## 网络模块
- Waybar 网络模块应常驻显示实时上下行带宽；只显示 SSID 或接口名会失去监控价值，不要把带宽隐藏到点击切换的 `format-alt`。

## 版本约束
- Ubuntu Noble 仓库的 waybar 0.9.24 不支持 `niri/workspaces`、`niri/window`、`niri/language`、`privacy` 模块（启动报 `Unknown module`）；niri 模块在 waybar 0.11.0 才合入主分支，0.13.0 补全 empty icon + urgency，0.15.0 为当前推荐稳定版。Ubuntu 上需源码编译安装到 `/usr/local`（`meson setup build --prefix=/usr/local --buildtype=release && ninja -C build && sudo ninja -C build install`），并 `apt remove waybar` 防止 apt 版覆盖。升级路径：`cd ~/src/waybar && git fetch --tags && git checkout <new-tag> && ninja -C build && sudo ninja -C build install`。构建依赖在 Noble 仓库均齐全（meson/ninja-build/pkgconf/scdoc + libdbusmenu-gtk3-dev/libfmt-dev/libgtk-layer-shell-dev/libgtkmm-3.0-dev/libhowardhinnant-date-dev/libinput-dev/libjack-jackd2-dev/libjsoncpp-dev/libmpdclient-dev/libnl-3-dev/libnl-genl-3-dev/libplayerctl-dev/libpulse-dev/libsigc++-2.0-dev/libsndio-dev/libspdlog-dev/libupower-glib-dev/libwayland-dev/libwireplumber-0.4-dev/libwlroots-dev/libxkbregistry-dev）。源码保留在 `~/src/waybar/`。`Waybar has been built without rfkill support.` 警告可忽略（未使用 bluetooth 模块）。`Item '': No icon name or pixmap given.` 是 tray 内 StatusNotifierItem 应用侧问题，不影响 niri 模块。

## 背光 / 电池模块（aarch64）
- Waybar 亮度模块（backlight）仅用于 aarch64（MediaTek 笔记本有背光设备），x86/桌面不显示。waybar 配置按 arch 拆分：共享 `.config/linux/waybar/config` 不含 backlight 模块，aarch64 变体 `.config/linux/waybar/config.aarch64` 在 `modules-right` 加入 backlight（滚轮 ±5%、左键 0%、右键 100%）；`install.sh` 用 `install_waybar_config_for_platform()` 按 `arch` 选择部署对应版本，`style.css`/`mocha.css`/`README.md` 两平台共用。

## CPU / 内存模块
- Waybar CPU/内存使用 `custom/cpu`、`custom/memory` 模块 + 后端 `~/.config/scripts/waybar-system-tooltip` 子命令 cpu/mem 输出 JSON（`text`+`tooltip`+`percentage`+`class`），不用 waybar 内置 `cpu`/`memory` 模块；根因是内置 `tooltip-format` 占位符无法注入动态进程列表，而 hover 显示 top 5 进程是核心需求（对齐 AwesomeWM `widgets/system.lua` 风格：首行模块名标题 `CPU`/`内存` + 摘要 `使用率：XX%` + CPU 多一行 `负载：X.X` + `Top CPU 进程`/`Top 内存进程` 标题 + `pid  comm  value` 两空格分隔的 5 行进程列表）。
- CPU 使用率用**单次调用内自差分**（两次 `/proc/stat` 间隔 `sleep 1`），**禁止用 state 文件方案**——多 bar 并发或 waybar reload 时共享 state 文件被覆盖会偶发 0%；代价是每次 exec 阻塞 ~1s（waybar custom 模块异步执行不阻塞 UI）+ 测量窗口从 5s 变 1s，interval 5s 下常态 CPU 开销 2-3%，可接受。
- waybar `return-type=json` 模式 `tooltip-exec` 被忽略，tooltip 必须由 JSON `tooltip` 字段提供，故每次 exec 都要计算 top 进程；`escape: false` 确保 `\n` 渲染为换行；`exec-on-click: true` 让单击立即刷新绕过 5s interval 等待。
- top 进程过滤按 pid 排除自身（`awk -v self=$$ '$1 != self'`），**不要按 comm "sh" 过滤**（误伤真实 sh 进程）；`json_escape` 前置 `tr -d` 清除 `\r` 及其它控制字符（防止异常 comm 产生非法 JSON）。
- **CPU top 进程瞬时化**：用 `sample_proc_cpu` 一次 `/proc/[0-9]*/stat` walk 收集 `pid utime stime`，与 `read_cpu_usage` 的 sleep 1 窗口同步两次采样，`compute_top_cpu` 按 `(delta_utime+delta_stime)*100/delta_total_jiffies` 算瞬时 %——**不依赖 `ps --sort=-pcpu` 的生命周期平均**（`(utime+stime)/elapsed*100`，长跑进程如 chrome 被 elapsed 稀释偏低、新进程偏高），与栏内 1s 平均使用率口径一致。**显示必须用一位小数（`%.1f`）**——1s 窗口下 <1% 的瞬时值常见，`%d`/`%.0f` 截断会把低占用 top 进程显示成 0%（排序本身用浮点值是对的，只是显示取整坑；awk 输出与外层 shell printf 两处都要用 `%.1f`，外层退回 `%.0f%%` 会二次取整重新截成 0）。**注意 awk 中不能用 `close` 作变量名**（awk 内置函数，关闭流），改用 `close_pos`。comm 字段含空格会让 `$14`/`$15` 偏移，必须先 `index($0, ")")` + `substr` 剥掉 `pid (comm)` 段再分字段，utime=rest[12]/stime=rest[13]（剥掉后从 state 字段 3 起重数）。
- **内存 top 进程用 ps RSS 瞬时值**（`ps --sort=-rss` 的 RSS 是当前常驻物理内存，瞬时值，已准确无需差分）；后续如要对齐 AwesomeWM 用 `/proc/<pid>/status` 的 `VmRSS:` 字段，再单独迭代。
- 内存 `states` 阈值用 85/95（CPU 70/90）——Linux 缓存常态占用高，80% 容易误报；阈值由脚本内 `emit_class(usage, warn, crit)` 输出 JSON `class` 字段驱动 CSS `#custom-cpu.warning`/`.critical`/`#custom-memory.warning`/`.critical`，config 中不写 `states` 字段。
- config 与 config.aarch64 中 `custom/cpu`、`custom/memory` 段完全重复（waybar 无 include 机制），靠 aarch64 superset 测试防漂移，维持现状。
- on-click 拉起 `foot -- htop -s PERCENT_CPU`/`PERCENT_MEM`（终端已统一用 foot，不再用 kitty）。
