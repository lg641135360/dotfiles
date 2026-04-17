# AwesomeWM Autostart Scripts

平台特定的开机自启脚本，由 AwesomeWM `rc.lua` 在启动时根据系统架构和发行版自动调用。

## 文件说明

| 文件 | 目标平台 | 说明 |
|------|----------|------|
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

所有脚本都启动以下服务：

- `picom` — 窗口合成器（圆角/阴影/模糊）
- `fcitx5` — 中文输入法
- `redshift` — 自动色温调节（护眼模式）
- `nm-applet` — 网络管理托盘
- `blueman-applet` — 蓝牙托盘
- `pasystray` — 音量控制托盘
- `udiskie` — USB 自动挂载
- `feh` — 壁纸设置

## 平台差异

### ubuntu_aarch64.sh

- **分辨率**：`xrandr --output eDP-1 --mode 2880x1800 --rate 120`
- **触摸板**：动态检测 Touchpad 设备 ID，配置自然滚动、轻触点击、clickfinger 模式、光标加速、打字时禁用
- **壁纸**：`/usr/share/backgrounds/*`

### arch_x64.sh / ubuntu_x64.sh

- **截图**：Snipaste
- **剪贴板**：greenclip daemon
- **壁纸**：`~/Pictures/*` 或 `~/Pictures/*`

## 依赖

以下包需要手动或通过 `install.sh` 安装：

- `xorg-xrandr` / `xorg-xinput` — 分辨率和触摸板配置
- `redshift` — 色温调节（Ubuntu: `sudo apt install redshift`）
- `picom` — 窗口合成器
- `fcitx5` — 中文输入法
- `feh` — 壁纸工具
- `udiskie` — USB 自动挂载
