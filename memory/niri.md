# niri / Wayland

## 平台与部署
- 桌面首选：x86_64 与 aarch64 均以 niri + Wayland 为首选与积极演进方向；aarch64 显示会话已迁移到 niri 并接入 GDM（解决双屏混 DPI），AwesomeWM + X11 进入维护模式仅作回退（mtgpu 驱动异常时的逃生路径）。
- 仅 Ubuntu 由 `install.sh` 部署本仓库的 `~/.config/niri`；Arch 保留 live Niri 配置，openSUSE 则由 DMS 接管 `~/.config/niri` 与 `~/.config/alacritty`，必须跳过这两类配置复制，保留 DMS 的生成文件和动态主题。
- niri 配置不复用 `picom`、`xrandr`、`xinput`、`feh`、`xautolock`；分别由 niri output/input、Wayland 合成、`swaybg`、`swayidle`/`swaylock` 等替代。
- niri 配置维护 `.config/linux/niri/ubuntu_x64/config.kdl` 与 `.config/linux/niri/ubuntu_aarch64/config.kdl`；公共部分（input/layout/blur/window-rule/binds 等）抽到 `.config/linux/niri/common.kdl`，平台文件只保留 output 段、`include "../common.kdl"`，以及必要的硬件覆盖。安装器仅在 Ubuntu（x86_64 / aarch64）按 `niri_platform_key()` 把对应平台 KDL 复制为 `~/.config/niri/config.kdl`、把 `common.kdl` 复制到 `~/.config/niri/common.kdl`，并把 include 路径从仓库的 `../common.kdl` 改写成 live 扁平布局的 `common.kdl`；不要把 README 或整个平台目录复制到 live。

## output / 外接屏
- Ubuntu aarch64 双屏（niri/Wayland）布局：内屏 eDP-1 `2880x1800@120` scale 2.0（逻辑 1440x900）放左侧 `x=0`；外接屏 DP-2 scale 1.25（逻辑 2048x1152）放右侧 `x=1440`。
- Ubuntu x64 双屏（2026-08-29）：DP-1 (Dell D2421DS) 左 `x=0`、HDMI-A-2 (AOC Q24P1W1) 右 `x=2048`，均 2560x1440@59.951、scale 1.25（逻辑 2048x1152）。接口名会随显卡/接线漂移（此前为 DP-4 / HDMI-A-3），配置匹配不到输出时 niri 全部回落 scale 1——排查缩放异常先对比 `niri msg outputs` 实际接口名与配置。
- 外接屏现为 Dell S2721DGF（2560x1440，上限 165Hz）。MediaTek mtdisp 驱动只从 EDID 基块暴露 `2560x1440@59.951`（preferred），不暴露 CEA 扩展块的 120Hz，故 120Hz 必须用 niri `modeline`（Since 25.11）强制：`modeline 497.75 2560 2608 2640 2720 1440 1445 1448 1525 "+hsync" "-vsync"`（取自 EDID CEA 扩展块 DTD，实测 119.998Hz）。不要用 `mode "2560x1440@120"`——该刷新率不在 `niri msg outputs` 列表里时 niri 无法匹配。
- modeline 失败时 niri 回落到 preferred 59.951Hz，不损坏显示；120Hz 在 165Hz 上限内为官方时序，安全。

## autostart / launcher
- Wayland 启动入口保持脚本化：`wayland-autostart` 只静默启动存在的 Waybar、Mako、fcitx5、壁纸、idle lock 和 polkit agent；`launcher-wayland` 优先 fuzzel，rofi 仅作 fallback。
- Wayland 色温固定使用更接近 Redshift 继承者、发行版覆盖更广的 `gammastep`；缺失时打印提示并跳过，不回退 `wlsunset`，也不在 niri autostart 里沿用 X11 主线的 `redshift`。
- gammastep 只跑后台守护进程，不启用托盘指示器：`gammastep-indicator.service` 需 mask（该 unit 全局 enabled，仅 disable 无效；用 `systemctl --user mask gammastep-indicator.service`）。原因：niri 纯 Wayland 无 XSETTINGS 时其 `Gtk.IconTheme.get_default()` 返回 `None` 导致崩溃循环、空耗 CPU，且用户不想要托盘图标。
- aarch64 恢复 gammastep 自动夜览（2026-08-23）：曾因 4800K 夜览经 wlr-gamma-control 压低色温把外接屏压得过暗而禁用；现改用温和夜间色温 5500K 减小蓝通道衰减、降低变暗幅度，并把亮度保持上限 `-b 1.0:1.0`（gammastep 亮度范围 0.1~1.0，无法用它提亮补偿），全平台统一启用。
- niri 会话下 launcher 主线为 Fuzzel + Catppuccin Mocha + CJK 字体；Rofi 保留为 fallback，不作为 Wayland 主力入口。
- niri autostart 可启动与 Awesome 对齐的可选托盘/辅助服务：`blueman-applet`、`udiskie -t`；缺命令时由 `run_once` 静默跳过；`pot` 不再默认自启动。`pasystray` 自启已移除（2026-08-13）：其音量控制由 waybar `pulseaudio` 模块 + 右键 `pavucontrol` 覆盖，移除后 niri 会话不再残留 XWayland 客户端；若日后需要托盘快速切音源，可重新加入。
- niri 会话下禁用 GNOME/X11 遗留 XDG autostart（2026-08-26）：niri 经 systemd 集成拉起 `xdg-desktop-autostart.target`，发行版条目用 `NotShowIn=` 排除法（排除 KDE/GNOME 等）时 niri 会被命中。仓库以 `Hidden=true` 同名覆盖文件（`.config/linux/xdg-autostart/` → `~/.config/autostart/`）禁用 `evolution-alarm-notify`、`nm-applet`、`print-applet`、`geoclue-demo-agent`；`X-GNOME-Autostart-enabled=false` 对 systemd 无效，必须用 `Hidden=true`。`nm-applet` 脚本侧启动行一并移除（waybar network 模块覆盖，不留双路径）。`at-spi-dbus-bus` 保留：freedesktop 无障碍总线，有 D-Bus 二次激活路径，硬禁需 mask 两个单元且伤及 GTK/Chromium 无障碍功能。
- EDS 三件套（evolution-source-registry / addressbook-factory / calendar-factory）是 D-Bus activated 的 static 单元（`/usr/share/dbus-1/services/*.service` 指向），disable 无效、只 stop 会被任意 EDS 客户端再次激活，须 `systemctl --user mask` + stop；主要触发源是 evolution-alarm-notify autostart，禁用覆盖文件是组合拳的前半段。
- 剪贴板管理（2026-08-28）：`wl-clip-persist` 持久化 + `cliphist` 历史检索，入口统一为 `clipboard-wayland`。`start` 直接启动 `wl-clip-persist --clipboard regular`，并独立运行 `wl-paste --watch cliphist store`；父脚本监管两个子进程，任一异常退出时共同清理，避免半失效状态。`wayland-autostart` 检测 `clipboard-wayland start` 监管进程，niri 用 `Mod+V`（V=粘贴直觉，当时空余）调 `clipboard-wayland history`，`Mod+Shift+V` 已固定给「切换浮动/平铺焦点」不得占用。`history` 使用 `cliphist list | fuzzel --dmenu --prompt "剪贴板 >"` → `cliphist decode | wl-copy`。`wl-clip-persist` 不在 Ubuntu 24.04 apt 源，走 Nix（nix-profile）；`cliphist` 用 apt（0.4.0）。`clipboard-wayland` 顶部对 Nix profile PATH 做补丁（niri environment{} 固定环境不含 `~/.nix-profile/bin`）。fuzzel 1.9.2 勿引入 1.11+ 专属选项（如 placeholder）。

## portal / polkit
- niri portal 偏好使用用户级 `~/.local/share/xdg-desktop-portal/niri-portals.conf`，默认 `gnome;gtk`，但 `FileChooser` 显式指定 `gtk`，避免缺少 Nautilus 时文件选择器失效；polkit agent 候选需覆盖 Ubuntu 的 `/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1`。

## 窗口规则 / 视觉
- niri 钉钉主窗口由 `window-rule` 管理列宽与不透明度：匹配 `com.alibabainc.dingtalk`，默认 2/3 列宽并覆盖为 1.0 不透明，避免 Qt/CEF 经 XWayland 在 mtgpu 上叠透明出黑块；不强制浮动、不强制聚焦、不固定输出，会议窗口和对话框仍由应用自身管理。不匹配 `tblive`。
- niri 全局窗口效果使用 `opacity 0.88` + `background-effect { blur true }`，并配合 `draw-border-with-background false` 避免半透明窗口聚焦时透出蓝色 focus ring 背景；Chrome 不再单独覆盖透明度或背景模糊，保持全局统一。
- aarch64 平台在 include `common.kdl` 之后覆盖全局为 `opacity 0.90` + `blur false`（mtgpu 模糊几乎不可见），并再次把钉钉覆盖为 1.0，避免被后置全局透明规则盖掉。

## 键位 / 导航
- niri 主导航偏好使用 `Mod+h/l` 左右聚焦窗口列、`Mod+j/k` 下/上聚焦窗口（到边界后切 workspace）；不要保留 `Mod+Left/Right/Up/Down` 方向键替代绑定。
- niri workspace 导航只保留 `Mod+j/k`、数字键和 `Mod+滚轮`，不保留 `Page_Up/Page_Down` 及其 Shift 组合；左右切列只保留 `Mod+h/l` 和 `Mod+横向滚轮`，不保留重复的 `Mod+Alt+h/l`。
- niri 使用 `Mod+Tab` 切换到焦点历史中的上一个窗口；暂不为不常用的列内上下窗口聚焦单独设置快捷键。
- niri 26.04 默认监视配置文件，保存后自动重载；不要为热更新单独绑定 `Mod+Ctrl+r`。`niri msg action load-config-file` 只留给脚本，用来跳过 watcher 的短暂延迟。
- niri 使用 `Mod+Shift+h/l` 左右移动当前列，以便调整同一 workspace 中窗口列的位置；锁屏使用 `Mod+Alt+l`，不再占用 `Mod+Shift+l`。
- niri 中启动程序、壁纸切换、overview、退出、截图标注和关闭显示器等一次性动作应设置 `repeat=false`，音量、亮度和尺寸调整等连续动作继续允许按键重复。

## overview
- niri overview 使用 `Mod+o` 打开/关闭，作为查看全局窗口/workspace 的主入口。
- niri overview 美化：`layout { background-color "transparent" }` 保持日常桌面干净无毛玻璃；`overview {}` 用暗底色 `#1e1e2e` + workspace 卡片阴影制造 overview 层次。`place-within-backdrop` 在 niri 26.04 上 `load-config-file` 后不生效（无论存量还是新 surface），双壁纸方案（awwww+swaybg）暂不可行，待 niri 更新后重试。

## 壁纸 / 锁屏 / 截图
- Wayland 壁纸来源优先 `~/Pictures/wall`，回退系统 `/usr/share/backgrounds`（镜像 Awesome 会话的 `randomize_wallpaper` 来源，保证两会话壁纸一致）；不纳入 `~/Pictures`（只含截图）。
- Wayland 锁屏使用 `swaylock` 时优先复用当前 `wallpaper-wayland` 记录或正在运行的 `swaybg -i` 壁纸，并用 `-s fill` 填充；找不到当前壁纸时才回退纯色 `11111b`。
- niri/Wayland 选区截图标注入口使用 `Mod+s`，并只使用 Satty；缺少 `satty`、`grim`、`slurp` 或 `wl-copy` 时脚本直接失败提示，不回退到 `swappy` / `ksnip`。不要再绑定裸 `F1`。
- Satty 文字标注显式使用 `Noto Sans CJK SC`；Satty 支持 IME，但没有可靠字体 fallback，未指定 CJK 字体时中文标注可能看起来像无法输入。
- Satty 在 niri/Wayland 下启动前应显式 `unset GTK_IM_MODULE`，让 GTK4 走 Wayland text-input/fcitx 路径；不要为 Satty 强制 `GTK_IM_MODULE=fcitx`。

## 终端
- aarch64 niri 终端优先 foot（2026-08-15 起恢复特化）：曾因 MediaTek mtgpu 下 alacritty 0.18.0-dev 在缩放输出（内屏 2x）字形渲染损坏（文字丢失）而让 aarch64 优先 kitty；后改回 alacritty 全平台默认；现因 foot 字体配置已对齐 alacritty 观感、且 foot 在该硬件上渲染更稳定，恢复 aarch64+Wayland 优先 foot（`terminal-wayland` 顶部 `uname -m` + `WAYLAND_DISPLAY` 双条件分支）。其他平台仍优先 alacritty、foot 作最后兜底。内屏 2x 下 alacritty 的字形问题仍未根治，留待后续定位（见 logs/trace.md）。foot 配置 `.config/linux/foot/foot.ini` 镜像 `.config/shared/alacritty` 观感（MesloLGS Nerd Font Mono 13、Catppuccin Mocha 内嵌 palette、`csd.preferred=none`、`pad=12x12`、`colors.alpha=0.82`、Beam 闪烁光标、滚动 50000、`term=xterm-256color`、Alt 导航键），并由 install.sh 的 `linux_wayland_dir_configs` 复制到 `~/.config/foot/`。foot 的 0.82 透明度与 alacritty Linux 一致；若后续在 aarch64 内屏 2x 下复现 mtgpu 半透明渲染 bug，再单独评估是否在该硬件上降回不透明（参见 `memory/foot.md`）。
