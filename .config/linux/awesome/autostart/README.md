# AwesomeWM Autostart Scripts

平台特定的开机自启脚本，由 AwesomeWM `rc.lua` 在启动时调用根级 wrapper，再由 wrapper 根据系统架构和发行版分发到对应平台脚本。

## 文件说明

| 文件 | 目标平台 | 说明 |
|------|----------|------|
| `../autostart.sh` | runtime wrapper | 由 `rc.lua` 启动，负责选择 `autostart/<platform>.sh` |
| `../display-layout.sh` | runtime wrapper | 在热插拔后只重算显示布局，不重跑整套自启动 |
| `common.sh` | 全平台共享 | 公共 helper、Xresources 初始化与公共后台服务启动函数 |
| `arch_x64.sh` | Arch Linux x86_64 | 桌面端，使用 Snipaste + greenclip |
| `ubuntu_aarch64.sh` | Ubuntu ARM64 | ARM 笔记本，设置 120Hz 分辨率 + 触摸板 |
| `ubuntu_x64.sh` | Ubuntu x86_64 | 桌面端，使用 Snipaste + greenclip |

## 被调用的方式

当前运行时调用链：

```text
rc.lua -> ~/.config/awesome/autostart.sh -> autostart/<platform>.sh
rc.lua -> ~/.config/awesome/display-layout.sh -> autostart/<platform>.sh --display-layout
```

`autostart.sh` 根据 `uname -s`、`uname -m` 和 `/etc/os-release` 选择平台脚本：

```
Arch Linux x86_64  → arch_x64.sh
Ubuntu ARM64       → ubuntu_aarch64.sh
Ubuntu x86_64      → ubuntu_x64.sh
```

## 公共功能

三份平台脚本都会先加载 `common.sh`，由它提供 `run()` / `run_custom()` / `run_first_custom()` / `run_latest_custom()`、`start_background()`、`prepare_xresources()`、显示器检测/布局 helper、随机壁纸 helper、自动锁屏 helper 以及公共服务启动函数。`run()` / `run_custom()` / `run_first_custom()` / `run_latest_custom()` 会先检查目标命令或可执行路径是否存在，再通过 `start_background()` 优先用 `setsid -f` 分离后台进程；`run_first_custom()` 用于“候选顺序本身就是优先级”的场景，`run_latest_custom()` 用于 AppImage 这类可能在多个目录并存多个版本的应用，会在所有可执行候选里按版本号选择最新一项。`prepare_xresources()` 只在 `xrdb` 和 `~/.Xresources` 都存在时合并；`randomize_wallpaper()` 在 `feh`、壁纸目录或候选图片缺失时静默跳过，避免 Awesome 自启动阶段输出 `not found` 噪音或中断后续服务。显示器 helper 现在会列出所有已连接外接屏，并在需要时按位置参数链式排列多个外接屏；带缩放时会为每个外接屏读取首选模式并统一计算 framebuffer/position。`run_idle_lock_service()` 只在 `xautolock` 与 `~/.config/scripts/lock` 都可用时启动 `xautolock -time 10 -locker ~/.config/scripts/lock -detectsleep`，空闲 10 分钟后自动锁屏，缺少依赖时静默跳过。

所有脚本都会按需尝试启动以下服务：

- `picom` — 窗口合成器（圆角/阴影/模糊）
- `fcitx5` — 中文输入法
- `redshift` — 自动色温调节（护眼模式）
- `nm-applet` — 网络管理托盘
- `blueman-applet` — 蓝牙托盘
- `pasystray` — 音量控制托盘
- `udiskie` — USB 自动挂载
- `feh` — 壁纸设置
- `xautolock` — 空闲 10 分钟后调用 `~/.config/scripts/lock` 自动锁屏（带 `-detectsleep`）

## 平台差异

平台脚本现在只保留各自的差异逻辑，例如壁纸路径、分辨率/触摸板、Snipaste/greenclip/flameshot 等。


### ubuntu_aarch64.sh

- **显示器**：运行时检测内屏（`eDP`/`LVDS`/`DSI`）和所有已连接外接屏；内屏设置为 `2880x1800@120Hz` 主屏，外接屏读取各自首选物理模式后用 `1.5x1.5` XRandR scaling 按顺序放在笔记本屏幕左侧，并显式设置 framebuffer/position，避免缩放后与内屏重叠；`display-layout.sh` 会在热插拔后再次调用同一策略；全局 `Xft.dpi` 不在这里调整
- **触摸板**：动态检测 Touchpad 设备 ID，配置自然滚动、轻触点击、clickfinger 模式、光标加速、打字时禁用
- **壁纸**：`/usr/share/backgrounds/*`
- **壁纸选择**：每次执行 autostart 时通过 `feh --no-fehbg --bg-fill --randomize` 从候选目录重新随机选择，不再优先恢复 `~/.fehbg`

### arch_x64.sh / ubuntu_x64.sh

- **截图**：Snipaste
- **Ubuntu x86_64 Snipaste**：通过 `run_latest_custom` 在 `~/Applications/Snipaste-*.AppImage`、`~/Downloads/Snipaste-*.AppImage` 和 `~/Documents/Snipaste-*.AppImage` 这些可执行候选里按版本号选择最新一项启动；例如同时存在 `2.11.2` 和 `2.11.3` 时，会优先启动 `2.11.3`
- **剪贴板**：greenclip daemon
- **壁纸**：`~/Pictures/*` 或 `~/Pictures/*`
- **壁纸选择**：每次执行 autostart 时通过 `feh --no-fehbg --bg-fill --randomize` 从候选目录重新随机选择，不再优先恢复 `~/.fehbg`

## 依赖

以下包需要手动或通过 `install.sh` 安装：

- `xorg-xrandr` / `xorg-xinput` — 分辨率和触摸板配置（仅相关平台需要）
- `redshift` — 色温调节（Ubuntu: `sudo apt install redshift`）
- `picom` — 窗口合成器
- `fcitx5` — 中文输入法
- `feh` — 壁纸工具
- `udiskie` — USB 自动挂载
- `xautolock` — 自动锁屏（可选；缺失时跳过）
