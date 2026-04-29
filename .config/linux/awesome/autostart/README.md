# AwesomeWM Autostart Scripts

平台特定的开机自启脚本，由 AwesomeWM `rc.lua` 在启动时根据系统架构和发行版自动调用。

## 文件说明

| 文件 | 目标平台 | 说明 |
|------|----------|------|
| `common.sh` | 全平台共享 | 公共 helper、Xresources 初始化与公共后台服务启动函数 |
| `arch_x64.sh` | Arch Linux x86_64 | 桌面端，使用 Snipaste + greenclip |
| `ubuntu_aarch64.sh` | Ubuntu ARM64 | ARM 笔记本，设置 120Hz 分辨率 + 触摸板 |
| `ubuntu_x64.sh` | Ubuntu x86_64 | 桌面端，使用 Snipaste + greenclip |

## 被调用的方式

在 `install.sh` 中，根据 `uname -m` 和 `/etc/os-release` 判断使用哪个脚本：

```
Arch Linux x86_64  → arch_x64.sh
Ubuntu ARM64       → ubuntu_aarch64.sh
Ubuntu x86_64      → ubuntu_x64.sh
```

## 公共功能

三份平台脚本都会先加载 `common.sh`，由它提供 `run()` / `run_custom()`、`prepare_xresources()`、显示器检测/布局 helper 以及公共服务启动函数。`run()` / `run_custom()` 会先检查目标命令或可执行路径是否存在；缺失的可选服务会被静默跳过，避免 Awesome 自启动阶段输出 `not found` 噪音。

所有脚本都会按需尝试启动以下服务：

- `picom` — 窗口合成器（圆角/阴影/模糊）
- `fcitx5` — 中文输入法
- `redshift` — 自动色温调节（护眼模式）
- `nm-applet` — 网络管理托盘
- `blueman-applet` — 蓝牙托盘
- `pasystray` — 音量控制托盘
- `udiskie` — USB 自动挂载
- `feh` — 壁纸设置

## 平台差异

平台脚本现在只保留各自的差异逻辑，例如壁纸路径、分辨率/触摸板、Snipaste/greenclip/flameshot 等。


### ubuntu_aarch64.sh

- **显示器**：运行时检测内屏（`eDP`/`LVDS`/`DSI`）和首个外接屏；内屏设置为 `2880x1800@120Hz` 主屏，外接屏读取首选物理模式（当前 Dell P2722H 为 `1920x1080`）后用 `1.5x1.5` XRandR scaling 放在笔记本屏幕左侧，并显式设置 framebuffer/position，避免缩放后与内屏重叠；全局 `Xft.dpi` 不在这里调整
- **触摸板**：动态检测 Touchpad 设备 ID，配置自然滚动、轻触点击、clickfinger 模式、光标加速、打字时禁用
- **壁纸**：`/usr/share/backgrounds/*`
- **壁纸选择**：每次执行 autostart 时通过 `feh --no-fehbg --bg-fill --randomize` 从候选目录重新随机选择，不再优先恢复 `~/.fehbg`

### arch_x64.sh / ubuntu_x64.sh

- **截图**：Snipaste
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
