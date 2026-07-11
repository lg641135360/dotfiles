# niri / Wayland 试用配置

目标：在 Linux 上按平台并行试用 niri，不删除 AwesomeWM；优先保留当前 Awesome 的常用肌肉记忆，同时接受 niri 的 scrollable columns 模型。

## 当前定位

- 当前本机已通过上游 flake 重新构建并切到 `niri 26.04 (3819182)`。
- AwesomeWM 仍是可回退桌面；本目录只提供 niri 试用配置。
- Niri 配置仅维护 Ubuntu x86_64 平台；公共部分（input/layout/blur/window-rule/binds 等）抽到 `.config/linux/niri/common.kdl`，平台文件只保留 output 段和 `include "../common.kdl"`。检测到 Ubuntu x86_64 的 niri 后，`install.sh` 复制平台 KDL 为 `~/.config/niri/config.kdl`，同时部署 `common.kdl` 并将 include 路径改写成 live 布局使用的 `common.kdl`；不会把 README 或整个平台目录复制到 live。仅 Ubuntu 部署本仓库的 Niri 配置；Arch 保留现有 live 配置，openSUSE 同时保留 DMS 管理的 Niri 与 Alacritty 配置。
- Waybar / Mako 第一版沿用 Catppuccin Mocha 色系，便于和现有 Awesome 外观保持接近。
- Fuzzel 是 niri 会话下的首选 launcher，使用 CJK 字体、fuzzy match 与更清晰的深色主题；Rofi 仅作为 fallback。
- `picom`、`xrandr`、`xinput`、`feh`、`xautolock` 不进入 niri 配置：Wayland 下分别由 niri/output/input、`swaybg`、`swayidle`/`swaylock` 等替代。
- 当前 Ubuntu x86_64 双 2K 外接屏按旧 X11 `Xft.dpi=124` 的观感近似设置为 niri `scale 1.25`，并沿用 `cursor.1x` 的 `XCURSOR_SIZE=32`。
- niri 的多屏 workspace 不是 i3/Sway 式全局编号列表；每个显示器都有自己的一条垂直 workspace 轨道。需要跨屏时，用 monitor 级快捷键移动焦点、列或整个 workspace。
- `xwayland-satellite` 已放入 Nix profile；niri 26.04 会在需要运行 X11 应用时按需自动拉起它，因此本仓库不手动 autostart 该进程。
- Portal 偏好由 `.config/linux/xdg-desktop-portal/niri-portals.conf` 维护，安装到 `~/.local/share/xdg-desktop-portal/niri-portals.conf`；其中 `FileChooser=gtk` 用来避免 GNOME portal 在缺少 Nautilus 时影响文件选择器。
- **Overview 美化**（Mod+O）：`layout { background-color "transparent" }` 保持日常桌面干净，`overview {}` 使用暗底色 `#1e1e2e` 压暗 overview 背景并加 workspace 卡片阴影。`place-within-backdrop` 经测试在 niri 26.04 上 `load-config-file` 后不生效（含新 surface），待 niri 更新后重新评估 awall 双壁纸方案。

## 配置部署边界

本仓库不负责安装 niri 或其它桌面软件，也不检测显示管理器、desktop entry 或系统服务。`install.sh` 只通过 `command -v` 判断 niri 是否存在，并仅在 Ubuntu x86_64 上部署已维护的平台 KDL；Arch 与 openSUSE 始终保留现有 live Niri 配置，后者由 DMS 管理。Waybar、Mako、Fuzzel 分别在自身命令存在时部署配置。当前是否处于 Wayland 会话不会影响部署。

Wayland 自动色温固定使用 `gammastep`；命令缺失时自启动脚本打印提示并跳过，不回退其它色温程序。

## 平台配置

公共配置（input/layout/blur/window-rule/binds 等）放在 `.config/linux/niri/common.kdl`，Ubuntu x86_64 平台文件只保留 output 段和 `include "../common.kdl"`。安装时 `install.sh` 复制该平台的 `config.kdl` 为 `~/.config/niri/config.kdl`，同时部署 `common.kdl` 并将 include 路径改写为 live 布局的 `common.kdl`。

| 平台 key | 仓库路径 | 状态 |
| --- | --- | --- |
| `ubuntu_x64` | `.config/linux/niri/ubuntu_x64/config.kdl` | 已落地；Ubuntu x86_64 双 2K 外接屏 |

新增平台时先增加对应平台 KDL 与安装器映射，只调整 output 段（接口名/分辨率/scale/位置）；公共行为改动统一在 `common.kdl` 里完成，并用 `niri validate -c <path>` 验证。

## 配置验证

仓库只负责配置部署，不创建或检查显示管理器的 niri 会话入口。配置可使用以下命令验证：

```bash
command -v niri
niri --version
niri validate -c ~/.config/niri/config.kdl
```

## 快捷键映射

| Awesome 习惯 | niri 动作 |
| --- | --- |
| `Mod+Return` | 打开终端：优先 Alacritty，缺失时回退 kitty |
| `Mod+e` | 打开文件管理器：Dolphin → 系统默认 → Nautilus/Thunar/PCManFM → Yazi |
| `Mod+c` | 启动 launcher：优先 `fuzzel`，缺失时回退 `rofi-launch` |
| `Mod+q` | 关闭当前窗口 |
| `Mod+Shift+l` | 锁屏：优先 `swaylock` |
| `Mod+Shift+w` | 随机切换 Wayland 壁纸 |
| `Mod+o` | 显示/关闭 niri overview 总览 |
| `Mod+h/l` | 左/右聚焦窗口列 |
| `Mod+j/k` | 下/上聚焦 workspace |
| `Mod+Minus/Equal` | 缩小/放大当前列宽 |
| `Mod+Shift+j/k` | 当前列内上下移动窗口 |
| `Mod+Ctrl+h/l` | 移动当前列到左/右 |
| `Mod+Shift+a/d` | 移动当前列到左/右显示器 |
| `Mod+a/d` | 左/右聚焦显示器 |
| `Mod+Page_Up/Page_Down` | 上/下聚焦 workspace |
| `Mod+1..9` | 聚焦指定 workspace |
| `Mod+Shift+1..9` | 移动当前窗口到指定 workspace |
| `Mod+Ctrl+Shift+a/d` | 移动当前 workspace 到左/右显示器 |
| `Mod+Ctrl+Space` | 切换浮动 |
| `Mod+f` | 全屏当前窗口 |
| `Mod+m` | 最大化到屏幕边缘 |
| `Mod+Shift+q` | 退出 niri，会有确认 |

## 自启动

niri 只调用一个入口：

```kdl
spawn-sh-at-startup "~/.config/scripts/wayland-autostart"
```

该脚本会逐项检查命令是否存在；缺失时向 stderr 打印提示并继续。实际启动的应用会把最近一次启动的 stdout、stderr 和退出码分别写入 `~/.local/state/niri/autostart/<app>.log`，每次重新启动覆盖对应日志，避免持续累积：

- `waybar`
- `mako`
- `fcitx5`
- `swaybg` 随机壁纸（只从 `~/Pictures/wall` 选择）
- `gammastep` 自动色温（`~/.local/state/niri/autostart/gammastep.log`）
- `swayidle`：空闲 10 分钟锁屏、30 分钟自动挂起；系统主动睡眠前也调用 `lock-wayland`
- KDE 或 GNOME polkit agent（若存在）
- `nm-applet`、`pasystray`、`blueman-applet`、`udiskie -t` 等托盘/辅助服务（若存在）

缺依赖不会中断 niri 启动。

`Mod+Shift+w` 调用 `wallpaper-wayland-next`，先结束当前 `swaybg`，再复用 `wallpaper-wayland` 重新随机选择壁纸；新壁纸路径仍会写入 `~/.local/state/dotfiles/current-wayland-wallpaper`，供锁屏背景复用。

如果 `gammastep` 进程存在但屏幕色温没有变化，先看日志：

```bash
tail -n 80 ~/.local/state/niri/autostart/gammastep.log
gammastep -m drm -p -l 30.6:114.3 -t 6500:4000
```

`lock-wayland` 使用 `swaylock`，解锁密码来自系统 PAM 账户认证；它不是 GNOME Keyring/KWallet/浏览器保存密码。脚本会优先调用 `/usr/bin/swaylock`，避免 Nix profile 里的 `swaylock` 与系统 PAM 配置格式不兼容。锁屏背景优先复用 `wallpaper-wayland` 记录的当前壁纸；若记录缺失，会尝试从当前 `swaybg -i <图片>` 进程解析图片路径；两者都不可用时才退回 Catppuccin Mocha 的纯色背景 `11111b`。若手动补 `/etc/pam.d/swaylock`，使用 PAM 的 `include` 控制语法：

```pam
auth include common-auth
account include common-account
session include common-session
```

## 终端入口

`Mod+Return` 调用 `~/.config/scripts/terminal-wayland`，优先使用 `~/.nix-profile/bin/alacritty`，其次使用系统 `alacritty`，最后回退 kitty。当前系统 `alacritty 0.17.0` 已可在 niri/Wayland 会话下启动；保持 Alacritty 优先可以复用 shared Alacritty 字体、透明度、快捷键和主题配置。

## 窗口规则

- 全局窗口默认启用 0.88 透明度和 niri 背景模糊，并设置 `draw-border-with-background false`，避免半透明窗口聚焦时把蓝色 focus ring 背景透出来。
- 钉钉不再由 niri window-rule 管理；会议窗口、浮动状态和位置交给应用自身或手动切换，避免仓库配置强行干预钉钉行为。
- Cherry Studio 默认列宽为 2/3 屏，保留较宽的对话阅读区域，同时还能露出相邻列。
- Chrome 默认列宽为 2/3 屏，适合网页阅读和文档页面；透明度和背景模糊不做 Chrome 特例，统一使用全局窗口效果。
- VS Code 默认列宽为 1.0，适合代码、终端和侧边栏同时展开。

## Portal

`niri-portals.conf` 使用 GNOME/GTK portal 组合：

```ini
[preferred]
default=gnome;gtk;
org.freedesktop.impl.portal.Access=gtk;
org.freedesktop.impl.portal.Notification=gtk;
org.freedesktop.impl.portal.Secret=gnome-keyring;
org.freedesktop.impl.portal.FileChooser=gtk;
```

这样可以继续使用 GNOME portal 的截图/屏幕共享等能力，同时把文件选择器固定到 GTK backend，避免当前机器缺少 Nautilus 时出现文件选择器不可用。

## 钉钉屏幕共享

Wayland 下钉钉会议共享只显示鼠标、画面全黑时，优先确认 PipeWire / WirePlumber / xdg-desktop-portal 正常运行。钉钉本身仍通过 XWayland 的 X11 抓屏接口取画面，因此需要用 `dingtalk-wayland-screenshare` 的 `libdingtalkhook.so` 把 X11 抓屏结果替换为 portal/PipeWire 捕获的画面。

本仓库在 `tools/dingtalk-wayland-screenshare` 保留了一份最小化、已修好的 hook 源码。它不随 `install.sh` 复制到 niri 配置目录，也不在仓库里保留 build 目录；需要更新 hook 时，从 dotfiles 根目录一次性编译并安装到 `~/.local/lib`：

```bash
cmake -S tools/dingtalk-wayland-screenshare -B /tmp/dingtalk-wayland-screenshare-build -GNinja -DCMAKE_BUILD_TYPE=Release
cmake --build /tmp/dingtalk-wayland-screenshare-build
install -Dm755 /tmp/dingtalk-wayland-screenshare-build/libdingtalkhook.so ~/.local/lib/dingtalk-wayland-screenshare/build/libdingtalkhook.so
```

当前 niri/PipeWire 截屏流需要两个兼容点：第一，format negotiation 必须把 `SPA_FORMAT_VIDEO_modifier` 声明为 mandatory `DRM_FORMAT_MOD_LINEAR`，否则 niri 日志会出现 `no more input formats`；第二，niri 提供的是 linear `DmaBuf`，PipeWire 不会把它映射成普通 `data` 指针，hook 必须对 `spa_data.fd` 做 `mmap` 后再复制到 framebuffer。仅强行请求 `SPA_PARAM_Buffers` 的 `MemFd` 会触发 `error alloc buffers: 无效的参数`，不要走这条路。

构建完成后默认 hook 路径是：

```bash
~/.local/lib/dingtalk-wayland-screenshare/build/libdingtalkhook.so
```

启动钉钉时使用：

```bash
~/.config/scripts/dingtalk-wayland
```

脚本会优先使用 `~/.local/lib/dingtalk-wayland-screenshare/build/libdingtalkhook.so`，把它放在 `LD_PRELOAD` 最前面，同时保留钉钉原本依赖的 `libgbm.so` 和 `plugins/dtwebview/libcef.so` preload；如果 hook 库放在其它位置，可用 `DINGTALK_WAYLAND_HOOK=/path/to/libdingtalkhook.so ~/.config/scripts/dingtalk-wayland` 指定。排障时可查看 `/tmp/dingtalk-wayland-debug.log`，正常路径会看到 `stream state changed from paused to streaming` 以及前几帧的 `process frame type=3` / `mmap frame` 记录。

## 截图标注

`F1` 调用 `~/.config/scripts/screenshot-wayland`：先用 `slurp` 选取区域，再用 `grim -t ppm` 截图，随后打开 Satty 做涂鸦、箭头、文字等标注，并默认把输出文件名指向 `~/Pictures/Screenshots`。Satty 分支里 `Enter` 保存到文件，复制命令使用 `wl-copy`，文字标注字体显式使用 `Noto Sans CJK SC`，避免 Satty 没有字体 fallback 时中文标注不可见。脚本启动 Satty 前会清掉 `GTK_IM_MODULE`，让 GTK4/Wayland 使用 text-input 输入法路径；不要在这里强制 `GTK_IM_MODULE=fcitx`。Satty 官方 README 说明 IME 已支持，但字体必须覆盖目标字符；如果缺少 `satty`、`grim`、`slurp` 或 `wl-copy`，脚本会直接失败并用通知提示缺少的依赖，不再回退到其它标注工具。`Ctrl+Print` 和 `Alt+Print` 继续保留 niri 原生的整屏/当前窗口截图。

## 验证

```bash
niri validate -c .config/linux/niri/ubuntu_x64/config.kdl
./tests/niri_wayland_config_test.sh
```

进入 niri 后：

```bash
niri msg outputs
niri msg workspaces
```

## 回退

在登录界面重新选择 AwesomeWM 即可。这个试用配置不删除 Awesome、picom 或 X11 配置。
