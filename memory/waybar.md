# Waybar

## 视觉
- niri 主线状态栏优先做整条连续顶栏，避免左/中/右三段独立胶囊导致一体感不足；配色使用 Catppuccin Mocha GTK CSS token，模块内部只用弱分隔、hover 和少量图标化文字降噪。

## 网络模块
- Waybar 网络模块应常驻显示实时上下行带宽；只显示 SSID 或接口名会失去监控价值，不要把带宽隐藏到点击切换的 `format-alt`。
- 左键点击用 `foot -- nmtui` 打开终端内 WiFi 扫描/选择界面（2026-08-31：从 `nm-connection-editor` 改来，连接编辑器无扫描列表、无法点选可用网络；nmtui 可直接列出并连接）。

## 版本约束
- Ubuntu Noble 仓库的 waybar 0.9.24 不支持 `niri/workspaces`、`niri/window`、`niri/language`、`privacy` 模块（启动报 `Unknown module`）；niri 模块在 waybar 0.11.0 才合入主分支，0.13.0 补全 empty icon + urgency，0.15.0 为当前推荐稳定版。Ubuntu 上需源码编译安装到 `/usr/local`（`meson setup build --prefix=/usr/local --buildtype=release && ninja -C build && sudo ninja -C build install`），并 `apt remove waybar` 防止 apt 版覆盖。升级路径：`cd ~/src/waybar && git fetch --tags && git checkout <new-tag> && ninja -C build && sudo ninja -C build install`。构建依赖在 Noble 仓库均齐全（meson/ninja-build/pkgconf/scdoc + libdbusmenu-gtk3-dev/libfmt-dev/libgtk-layer-shell-dev/libgtkmm-3.0-dev/libhowardhinnant-date-dev/libinput-dev/libjack-jackd2-dev/libjsoncpp-dev/libmpdclient-dev/libnl-3-dev/libnl-genl-3-dev/libplayerctl-dev/libpulse-dev/libsigc++-2.0-dev/libsndio-dev/libspdlog-dev/libupower-glib-dev/libwayland-dev/libwireplumber-0.4-dev/libwlroots-dev/libxkbregistry-dev）。源码保留在 `~/src/waybar/`。`Waybar has been built without rfkill support.` 警告可忽略（未使用 bluetooth 模块）。`Item '': No icon name or pixmap given.` 是 tray 内 StatusNotifierItem 应用侧问题，不影响 niri 模块。

## 背光 / 电池模块（aarch64）
- Waybar 亮度模块（backlight）仅用于 aarch64（MediaTek 笔记本有背光设备），x86/桌面不显示。waybar 配置按 arch 拆分：共享 `.config/linux/waybar/config` 不含 backlight 模块，aarch64 变体 `.config/linux/waybar/config.aarch64` 在 `modules-right` 加入 backlight（滚轮 ±5%、左键 0%、右键 100%）；`install.sh` 用 `install_waybar_config_for_platform()` 按 `arch` 选择部署对应版本，`style.css`/`mocha.css`/`README.md` 两平台共用。

## CPU / 内存模块
- Waybar CPU/内存使用原生 `cpu`、`memory` 模块，每 5 秒更新一次；不再用外部脚本遍历 `/proc` 和执行 1 秒双采样，避免多输出重复采样、常态 CPU 开销以及 Waybar 子进程残留。
- CPU tooltip 显示使用率与系统负载，内存 tooltip 显示使用率、已用/总量与可用容量；需要查看 top 进程时单击模块打开按 `PERCENT_CPU` / `PERCENT_MEM` 排序的 `htop`。
- 原生 `states` 阈值为 CPU 70/90、内存 85/95；CSS 使用 `#cpu.warning` / `.critical` 和 `#memory.warning` / `.critical`。内存阈值较高，避免 Linux 文件缓存造成常态误报。
- config 与 config.aarch64 中 `cpu`、`memory` 段保持一致，靠 aarch64 superset 测试防止漂移。

## 空闲抑制模块（2026-09-01）
- `idle_inhibitor` 加入两平台 modules-right（音量与隐私状态之间）：单击切换 swayidle 自动锁屏/关屏（看视频、演示场景）；眼睛图标两态（activated 󰈈 / deactivated 󰈉），激活时 `#idle_inhibitor.activated` 用 peach 醒目提示，tooltip 中文显示当前状态；该模块属共享段，aarch64 superset 测试继续只豁免 backlight/battery。
