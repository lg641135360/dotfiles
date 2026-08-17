# niri / Wayland 试用配置

目标：在 Linux 上按平台并行试用 niri，不删除 AwesomeWM；优先保留当前 Awesome 的常用肌肉记忆，同时接受 niri 的 scrollable columns 模型。

## 当前定位

- 当前本机已通过上游 flake 重新构建并切到 `niri 26.04 (3819182)`。
- AwesomeWM 仍是可回退桌面；本目录只提供 niri 试用配置。
- Niri 配置维护 Ubuntu x86_64 与 aarch64 两个平台；公共部分（input/layout/blur/window-rule/binds 等）抽到 `.config/linux/niri/common.kdl`，平台文件只保留 output 段和 `include "../common.kdl"`。检测到 Ubuntu x86_64 / aarch64 的 niri 后，`install.sh` 复制平台 KDL 为 `~/.config/niri/config.kdl`，同时部署 `common.kdl` 并将 include 路径改写成 live 布局使用的 `common.kdl`；不会把 README 或整个平台目录复制到 live。仅 Ubuntu 部署本仓库的 Niri 配置；Arch 保留现有 live 配置，openSUSE 同时保留 DMS 管理的 Niri 与 Alacritty 配置。
- Waybar / Mako 第一版沿用 Catppuccin Mocha 色系，便于和现有 Awesome 外观保持接近。
- Fuzzel 是 niri 会话下的首选 launcher，使用 CJK 字体、fuzzy match 与更清晰的深色主题；Rofi 仅作为 fallback。
- `picom`、`xrandr`、`xinput`、`feh`、`xautolock` 不进入 niri 配置：Wayland 下分别由 niri/output/input、`swaybg`、`swayidle`/`swaylock` 等替代。
- 当前 Ubuntu x86_64 双 2K 外接屏按旧 X11 `Xft.dpi=124` 的观感近似设置为 niri `scale 1.25`，并沿用 `cursor.1x` 的 `XCURSOR_SIZE=32`。
- niri 的多屏 workspace 不是 i3/Sway 式全局编号列表；每个显示器都有自己的一条垂直 workspace 轨道。需要跨屏时，用 monitor 级快捷键移动焦点、列或整个 workspace。
- `xwayland-satellite` 已放入 Nix profile；niri 26.04 会在需要运行 X11 应用时按需自动拉起它，因此本仓库不手动 autostart 该进程。
- Portal 偏好由 `.config/linux/xdg-desktop-portal/niri-portals.conf` 维护，安装到 `~/.local/share/xdg-desktop-portal/niri-portals.conf`；其中 `FileChooser=gtk` 用来避免 GNOME portal 在缺少 Nautilus 时影响文件选择器。
- **Overview 美化**（Mod+O）：`layout { background-color "transparent" }` 保持日常桌面干净，`overview {}` 使用暗底色 `#1e1e2e` 压暗 overview 背景并加 workspace 卡片阴影。`place-within-backdrop` 经测试在 niri 26.04 上 `load-config-file` 后不生效（含新 surface），待 niri 更新后重新评估 awall 双壁纸方案。
- **环境变量**：`common.kdl` 顶部的 `environment {}` 块声明 `QT_IM_MODULE`/`XMODIFIERS`/`SDL_IM_MODULE`/`GLFW_IM_MODULE`/`INPUT_METHOD`/`LC_CTYPE`/`XCURSOR_SIZE`/`ZDOTDIR` 等，niri 直接 spawn 的进程会继承；`wayland-autostart` 仍保留 `export` 与 `dbus-update-activation-environment`/`systemctl --user import-environment` 把这些变量同步到 DBus 和 systemd 用户会话。`GTK_IM_MODULE` 故意不设置，让 Wayland GTK 走 text-input 协议（fcitx5 偏好）；但 sddm/niri-session 的 `systemctl --user import-environment`（无参数）会把 im-config 在登录环境注入的 `GTK_IM_MODULE=fcitx` 导入 systemd 用户会话，因此 `wayland-autostart` 在 import 之后显式 `systemctl --user unset-environment GTK_IM_MODULE` 把它单独清掉，否则 fcitx5 会持续弹出"建议取消设置 GTK_IM_MODULE"的 Wayland 检测提示。`ZDOTDIR=/home/rikoo/.config/zsh`（niri 的 `environment {}` 不展开 `~`，须用绝对路径）让 niri spawn 的 shell（含 `Mod+Return` 拉起的终端）也走优化后的 zsh 配置：否则 zsh 落到默认 `~/.zshrc` 且没有 `.zshenv` 的 `skip_global_compinit`，会跑 Ubuntu 全局 compinit，交互启动实测 4.2s（优化配置 0.18s）。同时 `environment {}` 强制设置 `XDG_SESSION_TYPE=wayland`、`XDG_CURRENT_DESKTOP=niri`、`XDG_SESSION_DESKTOP=niri`：从 shell 手动启动 niri 时会继承错误的会话环境（`XDG_SESSION_TYPE=tty`、`XDG_CURRENT_DESKTOP=awesome`），会导致应用/toolkit 无法走 text-input-v3 接入 fcitx5、输入法无法输入中文；强制覆盖后会话按纯 Wayland/niri 身份运行。
- **光标**：`cursor { xcursor-size 32; hide-when-typing }` 让 niri 在 autostart 执行前就使用正确尺寸，并在键盘输入时自动隐藏鼠标；与 `XCURSOR_SIZE=32` 环境变量互补。
- **焦点环**：`focus-ring` 使用 Catppuccin Mocha 蓝 `#89b4fa`（活动）/灰 `#45475a`（非活动）/红 `#f38ba8`（紧急，用于 IM 闪动等需要注意的窗口）。
- **动画**：`animations {}` 按 `workspace-switch`/`window-open`/`window-close`/`window-resize` 分别配置 spring 参数（damping-ratio 0.7-0.8、stiffness 700-800），过渡更顺滑。

## 配置部署边界

本仓库不负责安装 niri 或其它桌面软件，也不检测显示管理器、desktop entry 或系统服务。`install.sh` 只通过 `command -v` 判断 niri 是否存在，并仅在 Ubuntu x86_64 / aarch64 上部署已维护的平台 KDL；Arch 与 openSUSE 始终保留现有 live Niri 配置，后者由 DMS 管理。Waybar、Mako、Fuzzel 分别在自身命令存在时部署配置。当前是否处于 Wayland 会话不会影响部署。

Wayland 自动色温固定使用 `gammastep`；命令缺失时自启动脚本打印提示并跳过，不回退其它色温程序。aarch64 (MediaTek) 例外：`gammastep` 通过 `wlr-gamma-control` 压低色温/亮度会连带把外接屏压得过暗，因此 aarch64 跳过 `gammastep`，不启用自动色温。

Waybar 亮度模块（`backlight`）仅用于 aarch64（MediaTek 笔记本有背光设备）：共享的 `.config/linux/waybar/config` 不含该模块（x86/桌面无背光不显示），aarch64 专用变体 `.config/linux/waybar/config.aarch64` 在 `modules-right` 加入 `backlight`。`install.sh` 通过 `install_waybar_config_for_platform()` 按 `arch` 选择部署对应版本（其余 `style.css`/`mocha.css`/`README.md` 两平台共用）。

## 平台配置

公共配置（input/layout/blur/window-rule/binds 等）放在 `.config/linux/niri/common.kdl`，Ubuntu x86_64 平台文件只保留 output 段和 `include "../common.kdl"`。安装时 `install.sh` 复制该平台的 `config.kdl` 为 `~/.config/niri/config.kdl`，同时部署 `common.kdl` 并将 include 路径改写为 live 布局的 `common.kdl`。

| 平台 key | 仓库路径 | 状态 |
| --- | --- | --- |
| `ubuntu_x64` | `.config/linux/niri/ubuntu_x64/config.kdl` | 已落地；Ubuntu x86_64 双 2K 外接屏 |
| `ubuntu_aarch64` | `.config/linux/niri/ubuntu_aarch64/config.kdl` | 已落地；Ubuntu aarch64 (MediaTek) 内屏 eDP-1 2x + 外接 DP-2 1.25x |

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
| `Mod+Return` | 打开终端：优先 Alacritty，缺失时回退 foot |
| `Mod+e` | 打开文件管理器：Dolphin → 系统默认 → Nautilus/Thunar/PCManFM → Yazi |
| `Mod+c` | 启动 launcher：优先 `fuzzel`，缺失时回退 `rofi-launch` |
| `Mod+q` | 关闭当前窗口 |
| `Mod+Alt+l` | 锁屏：优先 `swaylock` |
| `Mod+Shift+w` | 随机切换 Wayland 壁纸 |
| `Mod+o` | 显示/关闭 niri overview 总览 |
| `Mod+Tab` | 切换到焦点历史中的上一个窗口 |
| `Mod+h/l` | 左/右聚焦窗口列（到边界后切到左/右显示器） |
| `Mod+j/k` | 下/上聚焦窗口（到边界后切 workspace） |
| `Mod+Minus/Equal` | 缩小/放大当前列宽 |
| `Mod+Shift+Minus/Equal` | 缩小/放大当前窗口高度 |
| `Mod+Shift+j/k` | 当前列内上下移动窗口 |
| `Mod+Shift+h/l` | 移动当前列到左/右（到边界后自动移到左/右显示器） |
| `Mod+a/d` | 左/右聚焦显示器 |
| `Mod+1..9` | 聚焦指定 workspace |
| `Mod+Shift+1..9` | 移动当前窗口到指定 workspace |
| `Mod+Ctrl+Shift+a/d` | 移动当前 workspace 到左/右显示器 |
| `Mod+Ctrl+Space` | 切换浮动 |
| `Mod+f` | 全屏当前窗口 |
| `Mod+m` | 最大化到屏幕边缘 |
| `Mod+s` | 截图标注（slurp 选区 → grim → Satty 标注） |
| `Mod+Shift+q` | 退出 niri，会有确认 |

终端、文件管理器、launcher、锁屏、壁纸切换、overview、退出、截图标注等一次性动作均禁用按键重复，避免长按时重复启动或连续切换。窗口/ workspace 间垂直切换使用 `Mod+j/k`（优先切窗口，到边界后切 workspace），workspace 间直接跳转用数字键或 `Mod+滚轮`，不再保留 `Page_Up/Page_Down` 及其 Shift 组合；左右切列统一使用 `Mod+h/l`（到边界后切到左/右显示器）或 `Mod+横向滚轮`，不再保留重复的 `Mod+Alt+h/l`；`Mod+a/d` 仍可作为「显式只切显示器」的补充。

浮动切换、浮动/平铺焦点切换、列标签模式以及窗口并入/移出列等不易从按键直接判断的操作，已在 `Mod+Shift+/` 热键面板中补充中文说明。

## 自启动

niri 只调用一个入口：

```kdl
spawn-sh-at-startup "~/.config/scripts/wayland-autostart"
```

该脚本会逐项检查命令是否存在；缺失时向 stderr 打印提示并继续。实际启动的应用会把最近一次启动的 stdout、stderr 和退出码分别写入 `~/.local/state/niri/autostart/<app>.log`，每次重新启动覆盖对应日志，避免持续累积：

- `waybar`
- `mako`
- `fcitx5`
- `swaybg` 随机壁纸（优先 `~/Pictures/wall`，回退系统 `/usr/share/backgrounds`，镜像 Awesome 会话的 `randomize_wallpaper` 来源）
- `gammastep` 自动色温（`~/.local/state/niri/autostart/gammastep.log`；aarch64 禁用，见「配置部署边界」）
- `swayidle`：空闲 10 分钟锁屏、30 分钟自动挂起；系统主动睡眠前也调用 `lock-wayland`
- KDE 或 GNOME polkit agent（若存在）
- `nm-applet`、`blueman-applet`、`udiskie -t` 等托盘/辅助服务（若存在）。音量控制不再依赖 `pasystray`：由 waybar `pulseaudio` 模块（左键静音、滚轮调音量、右键 `pavucontrol`）覆盖，因此 niri 会话不残留 XWayland 客户端。

缺依赖不会中断 niri 启动。

`Mod+Shift+w` 调用 `wallpaper-wayland-next`，先结束当前 `swaybg`，再复用 `wallpaper-wayland` 重新随机选择壁纸；新壁纸路径仍会写入 `~/.local/state/dotfiles/current-wayland-wallpaper`，供锁屏背景复用。

如果 `gammastep` 进程存在但屏幕色温没有变化，先看日志：

```bash
tail -n 80 ~/.local/state/niri/autostart/gammastep.log
gammastep -m drm -p -l 30.6:114.3 -t 6500:4800
```

`gammastep` 通过 `wlr-gamma-control` 协议为每个输出注册 gamma 表，但进程启动后不会自动为新接入的输出补注册。`wayland-autostart` 在启动 `gammastep` 时会记录当前 niri 输出数量到 `~/.local/state/niri/autostart/gammastep.outputs`；再次执行时若输出数量变化（热插拔）则自动重启 `gammastep`。热插拔显示器后色温未生效时，手动重新执行 `~/.config/scripts/wayland-autostart` 即可修复。

`lock-wayland` 使用 `swaylock`，解锁密码来自系统 PAM 账户认证；它不是 GNOME Keyring/KWallet/浏览器保存密码。脚本会优先调用 `/usr/bin/swaylock`，避免 Nix profile 里的 `swaylock` 与系统 PAM 配置格式不兼容。锁屏背景优先复用 `wallpaper-wayland` 记录的当前壁纸；若记录缺失，会尝试从当前 `swaybg -i <图片>` 进程解析图片路径；两者都不可用时才退回 Catppuccin Mocha 的纯色背景 `11111b`。若手动补 `/etc/pam.d/swaylock`，使用 PAM 的 `include` 控制语法：

```pam
auth include common-auth
account include common-account
session include common-session
```

## 终端入口

`Mod+Return` 调用 `~/.config/scripts/terminal-wayland`：

- **aarch64 + Wayland** — 优先使用 `foot`（mtgpu 下 alacritty 0.18.0-dev 在缩放输出内屏 2x 字形损坏，foot 渲染正常）；foot 不可用时回退到下面的通用顺序
- **其他平台（x86_64 / X11）** — 优先使用 `~/.nix-profile/bin/alacritty`，其次系统 `alacritty`，最后回退 `foot`

非 aarch64+Wayland 场景保持 Alacritty 优先可以复用 shared Alacritty 字体、透明度、快捷键和主题配置。

历史上 aarch64 终端优先级历经多次调整：曾因 mtgpu 字形问题优先 `kitty`（foot 兜底），后因用户以外接屏为主、alacritty 显示正常而改回 alacritty 全平台默认；现因 foot 字体配置已对齐 alacritty 观感、且 foot 在该硬件上渲染更稳定，恢复 aarch64+Wayland 优先 foot。

兜底终端采用 foot（普通冷启动，Wayland-only）。历史上曾用 kitty 作兜底，并实现「常驻单实例 + `kitty @ launch --type=os-window`」快速开窗（冷启动 ~1.5s → 开窗 ~0.4s），但常驻实例维护成本高（残留 socket 导致 bind 失败的恶性循环、登录需多开一个常驻窗口）价值有限，已整体移除 kitty 改回 foot 兜底：`terminal-wayland` 直接 `exec foot`。

## 浏览器入口

Google Chrome 不会自动检测 Wayland，默认走 X11（ozone/x11）平台，在纯 Wayland 会话（无 `$DISPLAY`）里直接运行会报 `Missing X server or $DISPLAY`。用 `~/.config/scripts/browser-wayland` 启动浏览器：Wayland 会话下会自动追加 `--ozone-platform=wayland --enable-wayland-ime` 走原生 Wayland（保留 HiDPI 缩放，`--enable-wayland-ime` 让 Chrome 接入 fcitx5 的 text-input-v3 以支持中文输入），X11 会话下则原样透传、不加这些 flag。脚本自动在 `google-chrome-stable` / `google-chrome` 之间选择可用二进制；两者都缺失时通知并报错。另外，MediaTek mtgpu 驱动在缩放输出下会让 Chrome 合成时整屏横向撕裂，因此 aarch64（`uname -m`）下额外追加 `--disable-gpu-compositing` 关闭 GPU 合成（其它平台保留 GPU 合成以保性能）。

fuzzel（`Mod+c`）走 drun 模式，读的是 desktop 入口而不是直接调包装脚本，因此 `.config/linux/desktop-entries/google-chrome.desktop` 覆盖了系统入口，把 `Exec` 改为调用 `browser-wayland`（含「新建窗口/隐身窗口」子动作），部署到 `~/.local/share/applications/google-chrome.desktop`。这样从 fuzzel 菜单启动的 chrome 同样走原生 Wayland；该覆盖在 X11 Awesome 会话下也会命中，但因为 `browser-wayland` 会按会话透传，X11 下行为不变。`install.sh` 会把脚本与 desktop 入口随其它 Wayland 辅助文件一起部署。

### Trae CN（Electron IDE）

Trae CN 是 Electron 应用，与 Chrome 同类：默认走 X11 平台，纯 Wayland 会话下直接启动报 `Missing X server or $DISPLAY`。`~/.config/scripts/trae-cn-wayland` 包装脚本在 Wayland 会话下追加 `--ozone-platform=wayland --enable-wayland-ime --enable-features=WaylandWindowDecorations`（`--enable-wayland-ime` 提供 Fcitx5/Rime 输入法支持，`WaylandWindowDecorations` 让合成器绘制标题栏），X11 会话原样透传。同样用 `.config/linux/desktop-entries/trae-cn.desktop` 覆盖系统入口，`Exec` 改调 `trae-cn-wayland`，部署到 `~/.local/share/applications/`，fuzzel 菜单即走 Wayland。

## 窗口规则

- 全局窗口默认启用 0.88 透明度和 niri 背景模糊，并设置 `draw-border-with-background false`，避免半透明窗口聚焦时把蓝色 focus ring 背景透出来。透明由各应用自身透明度（如 alacritty 的 `background_opacity 0.82`）与全局 0.88 叠加。
- Polkit、`pinentry`、`ssh-askpass` 等认证窗口强制浮动并覆盖为 1.0 不透明度，确保密码提示清晰且边界明确。
- `layer-rule` 为 waybar 和 fuzzel 启用背景模糊（`background-effect { blur true }`），弹出层视觉焦点集中。
- 钉钉主窗口默认使用 2/3 列宽并覆盖为 1.0 不透明度，减少 Qt/CEF 经 XWayland 在 mtgpu 上叠加透明合成产生黑块或重绘异常的风险；不强制浮动、不强制聚焦，也不固定输出，会议窗口和对话框仍由应用自身管理。aarch64 平台配置在后置的全局 0.90 透明规则之后再次覆盖钉钉为 1.0，确保最终生效。
- Cherry Studio 默认列宽为 2/3 屏，保留较宽的对话阅读区域，同时还能露出相邻列。
- Chrome 默认列宽为 2/3 屏，适合网页阅读和文档页面；透明度和背景模糊不做 Chrome 特例，统一使用全局窗口效果。
- VS Code 默认列宽为 1.0，适合代码、终端和侧边栏同时展开。
- Trae（`trae-cn`）默认列宽为 1.0，与 VS Code 一致，占满整个 workspace 宽度。

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

主 niri 会话必须通过 `niri --session` 启动；该参数会把会话环境导入 systemd/D-Bus 并启动 niri 需要的 D-Bus 服务。仅使用 `Exec=niri` 会让 GNOME portal 只注册 Settings、缺少 ScreenCast 接口，表现为 `CreateSession failed`，钉钉 hook 也无法取得 PipeWire 流。修改 display manager 的 session entry 后需要注销并重新登录才能生效。

`wayland-autostart` 不再直接按进程是否存在来启动 portal：旧 portal 可能跨会话存活，或者在 niri 注册 ScreenCast 兼容服务前过早启动并永久停留在 Settings-only 状态。脚本会等待 `org.gnome.Mutter.ScreenCast` D-Bus 名称出现，再依次重启 `xdg-desktop-portal-gnome.service` 和 `xdg-desktop-portal.service`，最后确认 backend 已暴露 ScreenCast 接口。处理结果按 `NIRI_SOCKET` 记录在 `~/.local/state/niri/autostart/portal.niri-session`，同一 niri 会话重复执行脚本时不会无故中断正在使用的 portal；详细日志在同目录的 `portal.log`。

## 钉钉屏幕共享

Wayland 下钉钉会议共享只显示鼠标、画面全黑时，优先确认 PipeWire / WirePlumber / xdg-desktop-portal 正常运行。两条共享路径在不同架构上可用性不同：

- **aarch64 + 钉钉 8.1.1**：会议 SDK `libmeeting_sdk.so` 同时内置 X11 和原生 Wayland/PipeWire 捕获后端。`dingtalk-wayland` 默认保留真实 `XDG_SESSION_TYPE=wayland` 与 `WAYLAND_DISPLAY`，让会议 SDK 直接使用原生 portal/PipeWire 捕获。该路径已实测通过，不需要注入 `libdingtalkhook.so`。
- **x86_64 + 钉钉 8.1.0**：会议 SDK `libmeeting_sdk.so` 只编译了 X11 capturer（`ldd` 无 wayland/portal/pipewire 依赖），原生 Wayland 捕获路径不可用（tblive 不发 portal CreateSession，pipewire 无 video 节点，共享黑屏只有鼠标）。脚本在 x86_64 上默认就走 hook 回退路径（基于 `uname -m` 判断），直接 `~/.config/scripts/dingtalk-wayland restart` 即可，无需显式设置 `DINGTALK_FORCE_X11_CAPTURE=1`。

Qt/CEF 界面在两种架构下都由 `QT_QPA_PLATFORM=xcb` 和默认 ozone=x11 保持在 XWayland，不会切换 CEF 的原生 Wayland 后端。

旧 `libdingtalkhook.so` 路径在 x86_64 + 8.1.0 是默认且唯一可用共享路径（脚本基于 `uname -m` 自动启用），在 aarch64 + 8.1.1 仅作显式排障回退（`DINGTALK_FORCE_X11_CAPTURE=1`）。可用 `DINGTALK_FORCE_X11_CAPTURE=0/1` 显式覆盖架构默认。

### hook 源码版本约束（x86_64 关键）

x86_64 + 钉钉 8.1.0 必须使用 6 月 4 日 hook 源码版本（commit `13537e2`）。8 月 14 日 commit `3323b5e` 为解决 aarch64 tblive 内嵌 GLib main context 问题改动了 hook 源码（XShmAttach 从 `return false` 改为委托真实函数、mainloop 创建时序调整、引入 cancellable 和 60 秒超时），但在 x86_64 上会导致钉钉启动即崩（`CefExecuteProcess exit_code<<0`，hook 未触发）。详细差异和约束见 `memory/dingtalk.md`。

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

当前 aarch64 日常启动直接使用 `Mod+C` 打开应用启动器并选择钉钉。系统 desktop entry 会执行官方 `/opt/apps/com.alibabainc.dingtalk/files/Elevator.sh`；该入口已经设置 `QT_QPA_PLATFORM=xcb`、钉钉运行库路径及自带 `libgbm.so`/`libcef.so` preload，实测可配合上述 niri portal 时序修复完成原生 Wayland/PipeWire 共享，不需要仓库脚本参与。

`dingtalk-wayland` 仅保留为维护与兼容入口：需要安全清理残留进程、检查 portal、集中记录启动日志或显式复现旧 hook 路径时再使用：

```bash
~/.config/scripts/dingtalk-wayland
```

钉钉长期运行会出现内存累积（主进程可达数 GB），需要重启时执行 `~/.config/scripts/dingtalk-wayland restart`：脚本会通过 `/proc/<pid>/exe` 精确查找当前用户的 `com.alibabainc.dingtalk` 与 `tblive`，先发送 SIGTERM 并最多等待 5 秒；仍存活时再发送 SIGKILL（钉钉作为 Electron 应用常响应慢）。无参数时仅启动，不检查已有实例。执行 `~/.config/scripts/dingtalk-wayland usage` 可查看帮助。

该辅助脚本默认不加载 hook，只保留钉钉依赖的 `libgbm.so` 和 `plugins/dtwebview/libcef.so` preload。需要复现旧 hook 路径时，使用 `DINGTALK_FORCE_X11_CAPTURE=1 ~/.config/scripts/dingtalk-wayland`；如 hook 位于其它位置，可同时设置 `DINGTALK_WAYLAND_HOOK=/path/to/libdingtalkhook.so`。hook 排障日志位于 `/tmp/dingtalk-wayland-debug.log`。

启动器在 Wayland 会话中会等待最多 5 秒，确认 GNOME portal backend 已暴露 ScreenCast 接口；超时只发送告警并继续启动钉钉，不会自行重启 portal。portal 的启动顺序仍由 `wayland-autostart` 统一管理，避免多个应用级脚本竞争桌面服务。`restart` 子命令通过 `/proc/<pid>/exe` 精确匹配当前用户的 `com.alibabainc.dingtalk` 与 `tblive`，不再使用可能误杀诊断 shell 的宽泛 `pkill -f`。

### 钉钉保持 XWayland 模式

钉钉基于 CEF 109（Chromium 109），默认 ozone=x11，在 niri Wayland 双屏混 DPI（DP-2 scale 1.25、eDP-1 scale 2.0）下走 XWayland 会出现坐标映射错位，表现为鼠标双光标、点击落不到窗口。曾尝试在 Wayland 会话下切原生 Wayland 后端解决该问题，但实测 CEF 109 的 Wayland 后端有两个不可接受的缺陷：

1. **搜索崩溃**：点击搜索创建新 webview 时渲染进程必崩，crash dump 在 `~/.config/DingTalk/dump/8.1.1-Release.6020301/`，日志表现为 `CefExecuteProcess exit_code<<0` + `active_to_render_terminated`。
2. **缩放不动态更新**：多 output 混 DPI 下 `deviceScaleFactor` 不动态更新，内屏 scale 2.0 不生效，钉钉内容在外屏正常、在内屏过小且 `--force-device-scale-factor` 在 Wayland 下无效。

因此钉钉保持 XWayland 模式（不追加 ozone/wayland 相关 flag），坐标错位问题改为通过使用习惯规避（避免窗口跨屏）。这不妨碍会议 SDK 在已验证的 aarch64 环境中使用原生 portal/PipeWire 捕获；`libdingtalkhook.so` 只在显式回退时截获 `XGetImage`/`XShmGetImage`。aarch64 额外保留 `--disable-gpu-compositing`（与 Chrome 一致，规避 mtgpu 缩放输出撕裂，XWayland 下同样有效）。

Qt 模块（系统托盘、文件选择器、通知）保留 `QT_QPA_PLATFORM=xcb`：钉钉自带的 Qt 插件依赖 xcb，切到 wayland 会导致托盘和文件对话框失效。

## 截图标注

`Mod+s` 调用 `~/.config/scripts/screenshot-wayland`：先用 `slurp` 选取区域，再用 `grim -t ppm` 截图，随后打开 Satty 做涂鸦、箭头、文字等标注，并默认把输出文件名指向 `~/Pictures/Screenshots`。Satty 分支里 `Enter` 保存到文件，复制命令使用 `wl-copy`，文字标注字体显式使用 `Noto Sans CJK SC`，避免 Satty 没有字体 fallback 时中文标注不可见。脚本启动 Satty 前会清掉 `GTK_IM_MODULE`，让 GTK4/Wayland 使用 text-input 输入法路径；不要在这里强制 `GTK_IM_MODULE=fcitx`。Satty 官方 README 说明 IME 已支持，但字体必须覆盖目标字符；如果缺少 `satty`、`grim`、`slurp` 或 `wl-copy`，脚本会直接失败并用通知提示缺少的依赖，不再回退到其它标注工具。`Ctrl+Print` 和 `Alt+Print` 继续保留 niri 原生的整屏/当前窗口截图。

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
