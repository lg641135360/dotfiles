# niri / Wayland

## 当前有效基线

### 平台与部署

- 桌面主线是 niri + Wayland，覆盖 x86_64 与 aarch64；AwesomeWM + X11 进入维护模式，仅作 mtgpu 或 Wayland 故障时的回退路径。
- `install.sh` 的部署矩阵：
  - 检测到 `niri` 的机器：部署 Wayland 辅助脚本、desktop entry、portal 偏好、XDG autostart 覆盖和 Foot 配置；这些属于应用包装/会话辅助，不等同于外壳栈。
  - Ubuntu 且未检测到 `dms`：额外部署仓库维护的 niri KDL、Waybar、Mako、Fuzzel、Swaylock 外壳栈。
  - 检测到 `dms` 的 Ubuntu，以及非 Ubuntu 发行版：保留现有 live 的 niri/外壳栈配置，避免覆盖 DMS 或发行版自管文件；Alacritty 同样由 DMS/openSUSE 自管时跳过复制。
  - DMS 机器（不限发行版）额外走仓库的 DMS 接入层：部署 `.config/linux/dms/niri-repo.kdl` 为 `~/.config/niri/niri-repo.kdl`，并运行幂等脚本 `dms-niri-setup`（补 `dms/*.kdl` 的 include、把仓库片段排到最后、`dms setup binds`、重建钉钉窗口规则）。2026-10-06 起有效；逐键取舍与「不安装清单」见 `.config/linux/dms/README.md`。
  - Foot 始终按单文件部署（`foot.ini`、`README.md`），保留 `~/.config/foot` 内第三方文件，例如 DMS 的 `dank-colors.ini`。
- niri 配置维护 `.config/linux/niri/ubuntu_x64/config.kdl`、`.config/linux/niri/ubuntu_aarch64/config.kdl` 和公共 `.config/linux/niri/common.kdl`。平台文件主要保存 output 与硬件覆盖；安装器将平台文件复制为 `~/.config/niri/config.kdl`，并把仓库中的 `../common.kdl` 改写为 live 布局的 `common.kdl`。
- 仓库只负责配置部署，不安装 niri、DMS 或其它桌面软件，也不创建显示管理器 session entry。当前会话类型不影响安装器是否部署 niri 辅助文件。

### 包来源与组件边界

- Ubuntu x64 当前 niri / xwayland-satellite 走 avengemedia/danklinux PPA；niri session entry 使用绝对路径 `/usr/bin/niri-session`，避免 PATH 命中旧 Nix 版本。
- niri 不复用 `picom`、`xrandr`、`xinput`、`feh`、`xautolock`；对应职责由 niri output/input、Wayland 合成、`swaybg`、`swayidle`/`swaylock` 承担。
- Wayland 主线使用 Fuzzel + Catppuccin Mocha + CJK 字体，Rofi 仅作 fallback。终端统一优先 Foot，缺失时回退 Alacritty。
- Satty 通过 `cargo install --git https://github.com/Satty-org/Satty --locked` 安装；`wl-clip-persist` 以源码方式安装到 `/usr/local/bin`，`cliphist` 使用系统包。仓库不再依赖 Nix profile 提供 niri 链路组件。

### 输出布局

- aarch64：内屏 eDP-1 为 `2880x1800@120`、scale 2.0、逻辑坐标左侧 `x=0`；外接 DP-2 当前使用 `3840x2160@29.981`、scale 2.0、逻辑坐标 `x=1440`。
- x86_64：当前双屏配置为 DP-1 左、HDMI-A-2 右，均为 `2560x1440@59.951`、scale 1.25，右屏逻辑坐标 `x=2048`。接口名漂移时先用 `niri msg outputs` 对照实际名称。
- 当前 aarch64 外屏 AOC U27U2G6R4B 只稳定提供 4K30；不要复用旧 Dell S2721DGF 的 120Hz modeline，否则可能黑屏或无信号。若需要 4K60，先排查 DP 线缆和接口带宽。

## 会话组件与运行规则

### 自启动与外壳

- niri 只调用 `~/.config/scripts/wayland-autostart`。该脚本按命令存在性启动 Waybar、Mako、fcitx5、壁纸、gammastep、swayidle、polkit agent、可选的 blueman/udiskie，并把最近一次启动日志写入 `~/.local/state/niri/autostart/`。
- gammastep 使用 5500K 的温和夜间色温和 `-b 1.0:1.0`；不启用托盘 indicator。`gammastep-indicator.service` 若全局 enabled，需用 `systemctl --user mask`，仅 disable 不足以阻止冲突。
- swayidle 在空闲 600 秒后锁屏，900 秒后用 `niri msg action power-off-monitors` 关屏，恢复输入时重新打开显示器；waybar idle inhibitor 会整体抑制这条链。自动挂起不作为当前方案。
- niri 通过 systemd 集成拉起 XDG autostart，因此仓库用 `Hidden=true` 覆盖 GNOME/X11 遗留入口。当前仓库覆盖 Evolution alarm、nm-applet、print-applet 和 geoclue demo agent；`at-spi-dbus-bus` 保留。EDS 的 D-Bus activated 单元需要 live 侧 mask + stop，单纯 disable/stop 不可靠。

### 剪贴板与输入法

- `clipboard-wayland start` 统一管理 `wl-clip-persist`、`cliphist` watcher 和 X11 轮询桥；`Mod+V` 打开历史，`Mod+Shift+V` 保留给浮动/平铺焦点切换。
- 在有 `xclip` 和 `DISPLAY` 时，轮询桥每 0.5 秒双向同步文本及 PNG/JPEG/GIF，使用内容哈希去抖；读写统一套 `timeout --foreground 2`，防止 X11 selection owner 失联时无限阻塞。纯 Wayland 或缺依赖时桥自动跳过。
- Wayland 输入法变量主要由 im-config 写入 `/etc/environment`，经 `niri-session` 导入 systemd 用户环境；仓库不再重复注入 `QT_IM_MODULE` 等变量。`GTK_IM_MODULE` 由 `wayland-autostart` 从 systemd 用户环境清除，让 GTK 走 Wayland text-input；Satty 启动前也必须 `unset GTK_IM_MODULE`。
- `ZDOTDIR` 和 `skip_global_compinit=1` 由安装器幂等写入 `~/.zshenv`，避免 niri spawn 的终端触发 Ubuntu 全局 compinit。

### 应用包装与入口

- Chrome、Trae CN、Obsidian、ChatGPT 通过 Wayland wrapper 在 Wayland 会话添加 ozone/IME 参数；X11 会话原样透传。对应 desktop entry 也走 wrapper。
- 钉钉保持 CEF 109 的 XWayland 模式，以规避多屏混 DPI 下原生 Wayland 的坐标和缩放问题；会议 SDK 仍使用原生 portal/PipeWire 捕获。日常启动走官方 `Elevator.sh`，仓库的 `dingtalk-wayland` 只用于检查 ScreenCast/PipeWire 状态和精确清理残留进程。
- niri 侧对钉钉设置 2/3 列宽、1.0 不透明度和 `open-focused false`；除主窗口外的钉钉弹窗浮动。aarch64 关闭 blur 并使用 0.90 全局透明度，钉钉再次覆盖为 1.0。
- DMS 机器上 live `config.kdl` 由 DMS 重新生成、只 include `dms/*.kdl`，仓库 `common.kdl` 不参与；钉钉规则改用 DMS 自管通道维护（`dms config windowrules add niri ...`，落在 `~/.config/niri/dms/windowrules.kdl`），并由 `dms-niri-setup` 幂等重建（按 appId + action 查重，不重复添加）。
- **DMS 机器的键位靠 include 顺序决定归属**：niri 的 `binds {}` 合并规则是「后出现的同键绑定覆盖先出现的」（`niri-config/src/lib.rs` 的 include 合并分支），所以 `~/.config/niri/niri-repo.kdl` 必须排在所有 `dms/*.kdl` 之后。2026-10-06 决策：仓库独有键位直接恢复；与 DMS 默认冲突的按下表取舍（`Mod+Space`/`Mod+M`/`Mod+C`/`Mod+Ctrl+C`/`Mod+Shift+W`/`Mod+Alt+L`/`Mod+V`/媒体与亮度键让给 DMS，`Mod+Tab`/`Mod+F`/`Mod+Ctrl+F`/`Mod+HJKL`/`Mod+Shift+1..9`/`Mod+Shift+N` 保留仓库语义），完整表格见 `.config/linux/dms/README.md`。当日实测 `Mod+Space` 确实开 DMS spotlight（说明覆盖机制生效）。
- **DMS 机器不用 spawn 仓库 `wayland-autostart`**（2026-10-06 实测决策）：环境导入由 `niri-session` 做（`systemctl --user import-environment` + `dbus-update-activation-environment --all`），fcitx5 走 XDG autostart（`~/.config/autostart/fcitx5.desktop`），状态栏/通知/锁屏/idle/壁纸/色温/polkit/**剪贴板历史**均由 DMS 提供（`dms clipboard history`，并带 `cliphist-migrate`）；`wl-clip-persist`/`cliphist` 只在非 DMS 的 Wayland 会话需要，DMS 机器不装（Fedora 清单已同步）。需要回时在 `niri-repo.kdl` 加回 `spawn-sh-at-startup`。
- **DMS 机器设置基线（2026-10-06，由 `.config/linux/dms/settings.txt` + `dms-niri-setup` 幂等下发）**：`acLockTimeout=600` / `acMonitorTimeout=900`（DMS 默认 0=Never，会丢掉仓库的自动锁屏基线；`IdleService.qml` 读这两个键，AC 组）、`useAutoLocation=false`（本机 GeoClue2 不可用，避免反复重试）、`touchpadDragLock=true`（对齐仓库 input 的 drag-lock）、夜灯 `night.temperature=5500` + `night.enabled=true`（对齐 gammastep 5500K；它在 session 状态里，走 `dms ipc call night` 而不是 `settings set`）。其余界面偏好留在 DMS GUI / `dms backup create|restore`；`settings set` 只能改 `settings.json`（SettingsData），`wallpaperCyclingEnabled`/`nightMode*`/`displayGamma` 这类在 `session.json`，需 GUI 或专用 IPC。无电池机器不写 battery* 超时组。
- DMS 机器不安装 `waybar`/`mako`/`fuzzel`/`swaylock`/`swayidle`/`swaybg`/`gammastep`/`polkit-gnome`/`brightnessctl`/`playerctl`（均由 DMS 接管，双开会互相抢）：Fedora 的 `niri` 包会把 `waybar`/`swaylock`/`alacritty`/`fuzzel` 作为 weak dependency 拉进来，需 `sudo dnf install --setopt=install_weak_deps=False` 或事后 `dnf remove`。清单与「不安装清单」同步在 `.config/linux/packages/dnf.txt` 注释与根 README。
- 2026-09-28 已重建的钉钉三条（弹窗不抢焦点 `wr_1790561384874988781`（`open-focused false`）、窗口默认浮动 `wr_1790561738805679306`（`open-floating true`）、主窗口标题 `^钉钉|钉钉$` 改回平铺 `wr_1790561738813023192`）现由 `dms-niri-setup` 幂等重建（按 appId + action 查重）；顺序必须保持通用浮动规则在前、主窗口平铺在后（niri 按顺序处理、后者覆盖前者），DMS 无 `exclude` 编辑入口，用后两条正向规则表达仓库 `exclude title` 语义。

## 当前键位与视觉约定

- 主导航：`Mod+h/l` 切列，`Mod+j/k` 切窗口/到边界后切 workspace；`Mod+Tab` 返回焦点历史窗口，`Mod+grave` 返回焦点历史 workspace。
- `Mod+Space` 在 1/2 与 2/3 列宽间循环（**DMS 机器例外**：`Mod+Space` 是 DMS spotlight，列宽循环用 DMS 的 `Mod+R`）；`Mod+F` 扩展列宽；`Mod+Ctrl+F` 切换浮动；`Mod+Shift+h/l` 移动列；`Mod+Alt+l` 锁屏；`Mod+s` Satty 截图；`Mod+o` overview；`Mod+Shift+N` 切换免打扰（DMS 机器上调 `dms ipc call notifications toggleDoNotDisturb`）。
- niri 26.04 已默认监视配置文件并自动重载，不增加专用热重载键。一次性动作应设置 `repeat=false`，连续的音量、亮度和尺寸调整保留按键重复。
- 全局窗口默认 `opacity 0.88` + blur；弹出菜单、Waybar 和 Fuzzel 使用背景模糊。aarch64 平台关闭 blur，以降低 mtgpu 负担。
- 壁纸优先 `~/Pictures/wall`，回退 `/usr/share/backgrounds`；锁屏使用当前壁纸，找不到时回退 `11111b`。锁屏主线为 swaylock，不再使用 gtklock。

## 历史决策与已废弃方案

- DMS 适配前曾以“Ubuntu x64 不装 DMS、Waybar + Mako + 脚本链”为基线；该决策已被 2026-09 的实际 DMS 环境取代。现在应以“Ubuntu 且无 DMS 部署外壳，DMS 机器保留自管配置”为准。
- niri 链路曾依赖 Nix/nixGL；2026-08-29 已迁移到 Ubuntu 包/PPA 和手工安装的 Satty、wl-clip-persist。排查运行版本时优先检查 session entry 和 `systemctl --user show niri.service -p FragmentPath`。
- gtklock 方案曾短期加入，后因用户决策于 2026-09-02 整体回退到 swaylock；不要恢复 gtklock 的配置或测试。
- aarch64 外屏曾使用 Dell S2721DGF 的 120Hz modeline；显示器更换为 AOC U27U2G6R4B 后该 modeline 已废弃。
- `focus-follows-mouse` 曾因钉钉弹窗问题短暂关闭，实测与问题无关；当前按用户偏好重新启用，并用 `max-scroll-amount="0%"` 禁止 hover 导致视图滚动。
- 钉钉旧版本曾需要 X11 LD_PRELOAD 屏幕共享 hook；当前版本已内置 Wayland/PipeWire capturer，hook 源码已删除，不应重新加入排障主线。

## 排障入口

- niri 配置：`niri validate -c ~/.config/niri/config.kdl`。钉钉 @ 候选框闪现即消失时，先跑 `dms config windowrules list niri` 确认钉钉 `open-focused false` 规则在生效集里（DMS 机器规则在 `~/.config/niri/dms/windowrules.kdl`，仓库 `common.kdl` 已被 DMS 配置取代、不再被 include）。
- 输出缩放：`niri msg outputs`，确认接口名、当前 mode 和 scale 是否命中平台 KDL。
- portal/屏幕共享：确认 `niri --session`、PipeWire、WirePlumber 和 xdg-desktop-portal；钉钉排障使用 `~/.config/scripts/dingtalk-wayland status`，不要用它作为日常启动器。
- gammastep：查看 `~/.local/state/niri/autostart/gammastep.log`；热插拔输出后可重新执行 `~/.config/scripts/wayland-autostart`。
- 剪贴板：检查 `clipboard-wayland start`、`wl-clip-persist`、`cliphist` 和 X11 桥；桥只在 `xclip + DISPLAY` 条件满足时运行。
- fcitx/GTK：先查 `systemctl --user show-environment`、`/etc/environment` 和 `niri-session` 导入链，再确认 `GTK_IM_MODULE` 是否已由 autostart 清除。
