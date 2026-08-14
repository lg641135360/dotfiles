# 桌面与工具偏好

## Picom
- 给 `utility/dialog` 恢复轻阴影，在 `shadow-exclude` 里排除 `tblive` 等辅助条窗口。
- Ubuntu x64 + picom v10 环境：`shadow-exclude` 里的 `_GTK_FRAME_EXTENTS@` 会触发 `c2_parse_target` 解析错误；不在 Ubuntu x64 配置里保留它。
- 不使用 `opacity-rule` 把 Alacritty/kitty 强制拉回 100% opacity；终端使用自身透明度使 blur 可见；浏览器/Thunderbird 等窗口按需保持 100%。
- 美观调优优先只改当前平台，不强求 `ubuntu_x64`/`arch_x64`/`arch_aarch64` 三份配置同步收口，除非用户明确要求。
- Ubuntu aarch64 为降负载已走低占用方案：关 blur（`method = "none"`）、阴影 radius 6/opacity 0.3、圆角 8px；经实测 picom CPU 从 15.2% 降到 6.7%。

## 锁屏
- AwesomeWM（X11）锁屏脚本与自动锁屏细节见 `memory/awesome.md`；niri/Wayland 锁屏使用 `swaylock`，相关偏好见下文「niri / Wayland 试用」章节。

## Snipaste
- Snipaste 候选路径、裸 `F1` 热键、KDE kglobalshortcutsrc 修复等与 Awesome 桌面强相关的细节见 `memory/awesome.md`。

## Ubuntu aarch64 外接屏
- 内屏 `2880x1800@120Hz` 主屏；外接屏在 Ubuntu aarch64 上默认显式固定为 `2560x1440@59.95Hz` 放笔记本右侧，避免误落到 `3840x2160@30` 或 `1920x2160` 这类特殊模式。
- `Xft.dpi: 192` 是合适基线；不为了外接屏降低全局 DPI。
- 外接屏方案不要改 Awesome per-screen DPI 或 rofi focused-screen `ROFI_SCALE`。

## 其它
- redshift 处理、Ubuntu aarch64 系统二进制优先、Linuxbrew 遮蔽处理、scripts/ helper 部署等通用工作流与环境偏好见 `memory/organizing_preferences.md`。

## fcitx / GTK_IM_MODULE 排查
- fcitx "建议取消设置 GTK_IM_MODULE" 警告的原因是 Wayland 下 GTK 自带 text-input 协议，不需要 `GTK_IM_MODULE=fcitx`
- 注入链排查步骤：
  1. `systemctl --user show-environment` 查看 systemd 用户环境
  2. `~/.config/environment.d/*.conf` — systemd generator 自动加载
  3. `~/.xprofile` — 登录管理器导入
  4. `niri-session` 中的 `systemctl --user import-environment` — 将 shell 环境导入 systemd
- 修复方法：
  - `environment.d/` 文件中移除或注释 GTK_IM_MODULE 行
  - `.conf` 后缀的备份文件必须重命名为 `.bak`，否则被 systemd generator 误解析
  - 当前会话通过 `dbus-update-activation-environment --systemd GTK_IM_MODULE=` 将值设空
- niri/Wayland 下 Satty 启动前应 `unset GTK_IM_MODULE`，让 GTK4 走 Wayland text-input/fcitx 路径
- Wayland autostart 中统一 `unset GTK_IM_MODULE`，`export QT_IM_MODULE=fcitx` 等 Qt 应用仍需

### Rime（fcitx5-rime）在 MediaTek 定制 librime 上
- MediaTek 定制 librime **不支持 lua 插件**（`lua_processor`/`lua_translator`/`lua_filter` 均无法创建），而 rime-ice 全系 schema（`rime_ice`/`double_pinyin_*`）都依赖 lua 组件 → 启动即报错。
- 已按「方案 3a 剥离 lua」处理 live `~/.local/share/fcitx5/rime/rime_ice.schema.yaml`：engine 移除全部 lua 组件与对应配置块/recognizer 规则/开关，并去掉 corrector 用的 `［］comment_format`。基本拼音、词库、候选排序正常；失去以词定字、日期/农历/大写数字/计算器、错音提示、英文自动大写、v 模式、长词优先、部件拆字辅码、置顶候选项等 lua 扩展。
- **改完 schema 必须重建过期 .bin**：`rime_deployer --build` 只更新 prism/schema，`table.bin`/`reverse.bin` 可能仍是旧文件 → prism 与字典 .bin 不一致会导致 fcitx5 加载 rime 时 SIGSEGV 崩溃（栈在 `SchemaUpdate::Run → Config::GetString → ConfigData::Traverse`）。安全做法：删除 `build/` 下对应 schema 的 `{prism,table,reverse}.bin` 再 `rime_deployer --build`，最后 `pkill fcitx5 && fcitx5 -d --replace`。
- 该 Rime 目录是 rime-ice 的独立 git clone，**不属于 dotfiles 仓库**；改动需直接在 live 做并自行管理 git。若日后换带 lua 的 librime 可 `git checkout` 恢复。
- 备选方案 B：Flatpak 版 Fcitx5+Rime（官方维护、自带 librime-lua）可完整跑 rime-ice，但需迁移配置路径并改动 `wayland-autostart`/niri 环境，联动大，当前未采用。

## niri / Wayland 试用
- 桌面首选按架构区分：x86_64 上 niri + Wayland 为首选与积极演进方向，AwesomeWM + X11 进入维护模式仅作回退；aarch64 上 X11 + AwesomeWM 仍为主要图形显示服务器（保持可回退，不直接删除），niri + Wayland 在该架构暂不作为首选。
- 仅 Ubuntu 由 `install.sh` 部署本仓库的 `~/.config/niri`；Arch 保留 live Niri 配置，openSUSE 则由 DMS 接管 `~/.config/niri` 与 `~/.config/alacritty`，必须跳过这两类配置复制，保留 DMS 的生成文件和动态主题。
- niri 配置不复用 `picom`、`xrandr`、`xinput`、`feh`、`xautolock`；分别由 niri output/input、Wayland 合成、`swaybg`、`swayidle`/`swaylock` 等替代。
- Wayland 启动入口保持脚本化：`wayland-autostart` 只静默启动存在的 Waybar、Mako、fcitx5、壁纸、idle lock 和 polkit agent；`launcher-wayland` 优先 fuzzel，rofi 仅作 fallback。
- Wayland 色温固定使用更接近 Redshift 继承者、发行版覆盖更广的 `gammastep`；缺失时打印提示并跳过，不回退 `wlsunset`，也不在 niri autostart 里沿用 X11 主线的 `redshift`。
- gammastep 只跑后台守护进程，不启用托盘指示器：`gammastep-indicator.service` 需 mask（该 unit 全局 enabled，仅 disable 无效；用 `systemctl --user mask gammastep-indicator.service`）。原因：niri 纯 Wayland 无 XSETTINGS 时其 `Gtk.IconTheme.get_default()` 返回 `None` 导致崩溃循环、空耗 CPU，且用户不想要托盘图标。
- niri 会话下 launcher 主线为 Fuzzel + Catppuccin Mocha + CJK 字体；Rofi 保留为 fallback，不作为 Wayland 主力入口。
- niri portal 偏好使用用户级 `~/.local/share/xdg-desktop-portal/niri-portals.conf`，默认 `gnome;gtk`，但 `FileChooser` 显式指定 `gtk`，避免缺少 Nautilus 时文件选择器失效；polkit agent 候选需覆盖 Ubuntu 的 `/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1`。
- niri autostart 可启动与 Awesome 对齐的可选托盘/辅助服务：`nm-applet`、`blueman-applet`、`udiskie -t`；缺命令时由 `run_once` 静默跳过；`pot` 不再默认自启动。`pasystray` 自启已移除（2026-08-13）：其音量控制由 waybar `pulseaudio` 模块 + 右键 `pavucontrol` 覆盖，移除后 niri 会话不再残留 XWayland 客户端；若日后需要托盘快速切音源，可重新加入。
- niri 钉钉窗口保持不由 `window-rule` 管理；会议窗口、浮动状态和位置交给应用自身或手动切换，不在仓库配置里强制匹配 `com.alibabainc.dingtalk` / `tblive`。
- niri 全局窗口效果使用 `opacity 0.88` + `background-effect { blur true }`，并配合 `draw-border-with-background false` 避免半透明窗口聚焦时透出蓝色 focus ring 背景；Chrome 不再单独覆盖透明度或背景模糊，保持全局统一。
- niri 主导航偏好使用 `Mod+h/l` 左右聚焦窗口列、`Mod+j/k` 下/上聚焦 workspace；不要保留 `Mod+Left/Right/Up/Down` 方向键替代绑定。
- niri workspace 导航只保留 `Mod+j/k`、数字键和 `Mod+滚轮`，不保留 `Page_Up/Page_Down` 及其 Shift 组合；左右切列只保留 `Mod+h/l` 和 `Mod+横向滚轮`，不保留重复的 `Mod+Alt+h/l`。
- niri 使用 `Mod+Tab` 切换到焦点历史中的上一个窗口；暂不为不常用的列内上下窗口聚焦单独设置快捷键。
- niri 使用 `Mod+Ctrl+r` 重载配置（等效 `niri msg action load-config-file`），无需重启会话即可热更新配置。
- niri 使用 `Mod+Shift+h/l` 左右移动当前列，以便调整同一 workspace 中窗口列的位置；锁屏使用 `Mod+Alt+l`，不再占用 `Mod+Shift+l`。
- niri 中启动程序、壁纸切换、overview、退出、截图标注和关闭显示器等一次性动作应设置 `repeat=false`，音量、亮度和尺寸调整等连续动作继续允许按键重复。
- niri overview 使用 `Mod+o` 打开/关闭，作为查看全局窗口/workspace 的主入口。
- niri overview 美化：`layout { background-color "transparent" }` 保持日常桌面干净无毛玻璃；`overview {}` 用暗底色 `#1e1e2e` + workspace 卡片阴影制造 overview 层次。`place-within-backdrop` 在 niri 26.04 上 `load-config-file` 后不生效（无论存量还是新 surface），双壁纸方案（awww+swaybg）暂不可行，待 niri 更新后重试。
- niri 配置仅维护 `.config/linux/niri/ubuntu_x64/config.kdl`；公共部分（input/layout/blur/window-rule/binds 等）抽到 `.config/linux/niri/common.kdl`。安装器仅在 Ubuntu x86_64 把该配置复制到 `~/.config/niri/config.kdl`、把 `common.kdl` 复制到 `~/.config/niri/common.kdl`，并把 include 路径从仓库的 `../common.kdl` 改写成 live 扁平布局的 `common.kdl`；不要把 README 或整个平台目录复制到 live。
- Wayland 壁纸来源优先 `~/Pictures/wall`，回退系统 `/usr/share/backgrounds`（镜像 Awesome 会话的 `randomize_wallpaper` 来源，保证两会话壁纸一致）；不纳入 `~/Pictures`（只含截图）。
- Wayland 锁屏使用 `swaylock` 时优先复用当前 `wallpaper-wayland` 记录或正在运行的 `swaybg -i` 壁纸，并用 `-s fill` 填充；找不到当前壁纸时才回退纯色 `11111b`。
- niri/Wayland 选区截图标注入口使用 `F1`，并只使用 Satty；缺少 `satty`、`grim`、`slurp` 或 `wl-copy` 时脚本直接失败提示，不回退到 `swappy` / `ksnip`。
- Satty 文字标注显式使用 `Noto Sans CJK SC`；Satty 支持 IME，但没有可靠字体 fallback，未指定 CJK 字体时中文标注可能看起来像无法输入。
- Satty 在 niri/Wayland 下启动前应显式 `unset GTK_IM_MODULE`，让 GTK4 走 Wayland text-input/fcitx 路径；不要为 Satty 强制 `GTK_IM_MODULE=fcitx`。
- Waybar 视觉偏好：niri 主线状态栏优先做整条连续顶栏，避免左/中/右三段独立胶囊导致一体感不足；配色使用 Catppuccin Mocha GTK CSS token，模块内部只用弱分隔、hover 和少量图标化文字降噪。
- Waybar 网络模块应常驻显示实时上下行带宽；只显示 SSID 或接口名会失去监控价值，不要把带宽隐藏到点击切换的 `format-alt`。
- Waybar 版本约束：Ubuntu Noble 仓库的 waybar 0.9.24 不支持 `niri/workspaces`、`niri/window`、`niri/language`、`privacy` 模块（启动报 `Unknown module`）；niri 模块在 waybar 0.11.0 才合入主分支，0.13.0 补全 empty icon + urgency，0.15.0 为当前推荐稳定版。Ubuntu 上需源码编译安装到 `/usr/local`（`meson setup build --prefix=/usr/local --buildtype=release && ninja -C build && sudo ninja -C build install`），并 `apt remove waybar` 防止 apt 版覆盖。升级路径：`cd ~/src/waybar && git fetch --tags && git checkout <new-tag> && ninja -C build && sudo ninja -C build install`。构建依赖在 Noble 仓库均齐全（meson/ninja-build/pkgconf/scdoc + libdbusmenu-gtk3-dev/libfmt-dev/libgtk-layer-shell-dev/libgtkmm-3.0-dev/libhowardhinnant-date-dev/libinput-dev/libjack-jackd2-dev/libjsoncpp-dev/libmpdclient-dev/libnl-3-dev/libnl-genl-3-dev/libplayerctl-dev/libpulse-dev/libsigc++-2.0-dev/libsndio-dev/libspdlog-dev/libupower-glib-dev/libwayland-dev/libwireplumber-0.4-dev/libwlroots-dev/libxkbregistry-dev）。源码保留在 `~/src/waybar/`。`Waybar has been built without rfkill support.` 警告可忽略（未使用 bluetooth 模块）。`Item '': No icon name or pixmap given.` 是 tray 内 StatusNotifierItem 应用侧问题，不影响 niri 模块。
- aarch64 niri 终端默认 alacritty（2026-08-13 起全平台统一）：曾因 MediaTek mtgpu 下 alacritty 0.18.0-dev 在缩放输出（内屏 2x）字形渲染损坏（文字丢失）而让 aarch64 优先 kitty；现用户以外接屏为主、alacritty 显示正常，已移除 `terminal-wayland` 的 aarch64-kitty 分支，全平台优先 alacritty、kitty 兜底。内屏 2x 下 alacritty 的字形问题未根治，留待后续定位（见 logs/trace.md）。kitty 配置 `.config/linux/kitty/kitty.conf` 仍镜像 `.config/shared/alacritty` 观感（MesloLGS Nerd Font Mono 13、Catppuccin Mocha 内嵌 palette、无边框、padding 12、opacity 1.0、Beam 闪烁光标、滚动 50000、Alt 导航键），并由 install.sh 的 `linux_wayland_dir_configs` 复制到 `~/.config/kitty/`；aarch64 mtgpu 驱动对半透明背景 alpha 合成有 bug，故 kitty 走完全不透路径绕开。
- Waybar 亮度模块（backlight）仅用于 aarch64（MediaTek 笔记本有背光设备），x86/桌面不显示。waybar 配置按 arch 拆分：共享 `.config/linux/waybar/config` 不含 backlight 模块，aarch64 变体 `.config/linux/waybar/config.aarch64` 在 `modules-right` 加入 backlight（滚轮 ±5%、左键 0%、右键 100%）；`install.sh` 用 `install_waybar_config_for_platform()` 按 `arch` 选择部署对应版本，`style.css`/`mocha.css`/`README.md` 两平台共用。
