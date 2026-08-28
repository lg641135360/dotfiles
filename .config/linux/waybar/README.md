# Waybar（Wayland 状态栏）

## 文件结构

```text
.config/linux/waybar/
├── config            # Waybar 布局和模块配置（不含 backlight/battery，用于桌面/无电池设备）
├── config.aarch64    # aarch64 变体：modules-right 加入 backlight 与 battery（MediaTek 笔记本）
├── mocha.css         # Catppuccin Mocha GTK CSS 颜色变量
└── style.css         # 一体化顶栏样式
```

部署到 `~/.config/waybar/`；由 `install.sh` 的 `install_waybar_config_for_platform()` 按架构挑选 `config` 或 `config.aarch64`，`style.css`/`mocha.css`/`README.md` 两平台共用。

## 模块布局

```
桌面/无电池设备（共享 config）
左: [工作区 │ 窗口标题]
中: [时钟]
右: [网络 CPU 内存 音量 隐私状态 系统托盘]

aarch64（config.aarch64，含背光与电池）
左: [工作区 │ 窗口标题]
中: [时钟]
右: [网络 CPU 内存 背光 音量 电池 隐私状态 系统托盘]
```

## 当前配置要点

- **工作区**：使用图标（聚焦/活动/紧急/空），无数字编号，适配 niri 动态工作区
- **窗口标题**：保留当前输出的 niri 窗口标题，并清理常见 VS Code / Chrome / Alacritty 标题
- **网络**：常驻显示实时上下行带宽（↓↑），单击打开网络连接编辑器；Wi-Fi、有线和断开状态使用独立 tooltip，按场景显示 SSID、信号、接口和 IP；Waybar 0.15 的带宽占位符在 tooltip 中存在单位换算问题，因此 tooltip 不重复显示速率
- **时钟**：保持紧凑日期时间，悬停显示按 ISO 8601（周一起始）排列的月历
- **音量**：图标化显示音量，静音状态使用中文；单击静音切换，右击打开 pavucontrol，滚轮调音量（步长 5%，`on-scroll` 调 `wpctl` + `interval 1` 保持显示刷新）
- **背光（仅 aarch64）**：使用 waybar 内置 `backlight` 模块，图标化显示亮度百分比；滚轮 ±5%、左键 0%、右键 100%（`on-scroll`/`on-click` 直接调 `brightnessctl`）。内置模块靠 udev 事件驱动刷新，但 MediaTek `m1000_backlight` 亮度变化不发 uevent，故加 `interval: 0.1`（约 100ms 轮询兜底）实现近实时更新，无需外部脚本或信号；该模块读 `actual_brightness`，勿自己写脚本读 `brightness`（该值恒为最大值导致百分比恒 100%）
- **电池（仅 aarch64）**：Nerd Font 图标 + 容量百分比，按容量档位变色；充电中/已接电源显示 `󰂄`，警告阈值 35% 变黄，临界 15% 变红，常态使用 subtext0；阈值与颜色对齐 AwesomeWM `widgets/system.lua` 的电池约定
- **CPU/内存**：使用 Waybar 原生 `cpu`、`memory` 模块，栏内每 5 秒刷新利用率，悬停显示 CPU 负载或内存已用/总量/可用容量；CPU warning 70%/critical 90%，内存 warning 85%/critical 95%。单击分别打开按 CPU/内存排序的 `htop`。原先的自定义脚本会在每个输出上重复遍历 `/proc` 并进行 1 秒双采样，已移除以降低常态 CPU 开销和避免子进程残留。
- **隐私状态**：仅在 PipeWire 检测到屏幕共享或麦克风采集时显示图标和应用 tooltip
- **样式**：`style.css` 顶部导入 `mocha.css`，使用 Catppuccin Mocha 颜色变量；整条 Waybar 作为连续半透明顶栏，内部模块只保留弱分隔和 hover 层级，颜色过渡仅应用于存在交互或状态变化的模块
