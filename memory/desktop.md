# 桌面与工具偏好

## Picom
- 给 `utility/dialog` 恢复轻阴影，在 `shadow-exclude` 里排除 `tblive` 等辅助条窗口。
- Ubuntu x64 + picom v10 环境：`shadow-exclude` 里的 `_GTK_FRAME_EXTENTS@` 会触发 `c2_parse_target` 解析错误；不在 Ubuntu x64 配置里保留它。
- 不使用 `opacity-rule` 把 Alacritty/kitty 强制拉回 100% opacity；终端使用自身透明度使 blur 可见；浏览器/Thunderbird 等窗口按需保持 100%。
- 美观调优优先只改当前平台，不强求 `ubuntu_x64`/`arch_x64`/`arch_aarch64` 三份配置同步收口，除非用户明确要求。

## 锁屏
- 锁屏脚本优先 `i3lock-color`/带 `--blur` 的 `i3lock`；不硬编码 `--screen 1`。
- 普通 `i3lock` fallback：Python 生成缓存的 Catppuccin Mocha 静态 PNG 背景，按 `xrandr --current` 每个输出画居中卡片/锁图标；生成失败时退纯色 `i3lock -n -e -f -c 11111b`。
- 自动锁屏由 autostart 用 `xautolock -time 10 -locker ~/.config/scripts/lock -detectsleep` 启动，缺依赖时静默跳过。

## Snipaste
- 在 `~/Applications/Snipaste-*.AppImage`、`~/Downloads/Snipaste-*.AppImage` 和 `~/Documents/Snipaste-*.AppImage` 等候选里按版本号选择最新可执行 AppImage。
- Snipaste 裸 `F1` 截图由 Snipaste 自己注册全局热键；Awesome 不绑定裸 `F1`。
- KDE `kglobalaccel5`/`~/.config/kglobalshortcutsrc` 中 `[org.flameshot.Flameshot.desktop] Capture` 为 `F1` 时应改为 `none,none,进行截图`。

## Ubuntu aarch64 外接屏
- 内屏 `2880x1800@120Hz` 主屏；外接屏在 Ubuntu aarch64 上默认显式固定为 `2560x1440@59.95Hz` 放笔记本右侧，避免误落到 `3840x2160@30` 或 `1920x2160` 这类特殊模式。
- `Xft.dpi: 192` 是合适基线；不为了外接屏降低全局 DPI。
- 外接屏方案不要改 Awesome per-screen DPI 或 rofi focused-screen `ROFI_SCALE`。

## 其它
- `install.sh` 里的 `redshift` 保留缺失检查；缺失时只提示手动安装，不自动提权安装。
- Ubuntu aarch64 上 X11-sensitive 桌面工具优先用系统二进制（尤其是 `redshift`）。
- Linuxbrew 包遮蔽工作系统二进制且不需要时，优先删除包而不是加防御逻辑。
- scripts/ 目录下的 helper 优先始终安装并保留可执行位，即使 runtime backend 未安装。

## niri / Wayland 试用
- niri 迁移先作为与 AwesomeWM 并行的 Wayland 试用桌面纳入 dotfiles；Awesome/X11 保持可回退，不直接删除或替换。
- niri 配置不复用 `picom`、`xrandr`、`xinput`、`feh`、`xautolock`；分别由 niri output/input、Wayland 合成、`swaybg`、`swayidle`/`swaylock` 等替代。
- Wayland 启动入口保持脚本化：`wayland-autostart` 只静默启动存在的 Waybar、Mako、fcitx5、壁纸、idle lock 和 polkit agent；`launcher-wayland` 优先 fuzzel，rofi 仅作 fallback。
- Wayland 色温优先使用更接近 Redshift 继承者、发行版覆盖更广的 `gammastep`，缺失时回退轻量 wlroots 专用的 `wlsunset`；不要在 niri autostart 里继续沿用 X11 主线的 `redshift`。
- niri 会话下 launcher 主线为 Fuzzel + Catppuccin Mocha + CJK 字体；Rofi 保留为 fallback，不作为 Wayland 主力入口。
- niri portal 偏好使用用户级 `~/.local/share/xdg-desktop-portal/niri-portals.conf`，默认 `gnome;gtk`，但 `FileChooser` 显式指定 `gtk`，避免缺少 Nautilus 时文件选择器失效；polkit agent 候选需覆盖 Ubuntu 的 `/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1`。
- niri autostart 可启动与 Awesome 对齐的可选托盘/辅助服务：`nm-applet`、`pasystray`、`blueman-applet`、`pot`、`udiskie -t`；缺命令时由 `run_once` 静默跳过。
- niri 钉钉窗口保持不由 `window-rule` 管理；会议窗口、浮动状态和位置交给应用自身或手动切换，不在仓库配置里强制匹配 `com.alibabainc.dingtalk` / `tblive`。
- niri 主导航偏好使用 `Mod+h/l` 左右聚焦窗口列、`Mod+j/k` 下/上聚焦 workspace；不要保留 `Mod+Left/Right/Up/Down` 方向键替代绑定。
- niri overview 使用 `Mod+o` 打开/关闭，作为查看全局窗口/workspace 的主入口。
