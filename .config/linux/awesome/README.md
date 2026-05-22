# AwesomeWM 配置

基于 Catppuccin Mocha 主题的 AwesomeWM 配置，支持自动平台检测。

## 目录结构

```
.config/awesome/
├── rc.lua              # 主配置入口（自动检测平台）
├── config.lua          # 平台特定设置
├── actions.lua         # rofi / 文件管理器 / OCR / 锁屏等桌面动作
├── bindings.lua        # 全局与窗口快捷键
├── client.lua          # 窗口规则、titlebar 与焦点边框
├── menu.lua            # 主菜单与 freedesktop / Debian fallback
├── autostart.sh        # runtime 平台分发 wrapper
├── display-layout.sh   # runtime 显示布局 wrapper（热插拔后重算）
├── ui/
│   └── wibar.lua       # ui/wibar.lua：顶栏、taglist、tasklist、托盘、时钟
├── widgets/
│   ├── system.lua      # widgets/system.lua：CPU / MEM / NET 监控组件
│   ├── brightness.lua  # widgets/brightness.lua：亮度读数（可选 brightnessctl 滚轮调节）
│   └── volume.lua      # widgets/volume.lua：音量控制组件
├── theme/
│   └── catppuccin.lua  # Catppuccin Mocha 主题
├── autostart/          # 各平台自启脚本
│   ├── arch_x64.sh
│   ├── ubuntu_x64.sh
│   └── ubuntu_aarch64.sh
└── collision/          # 可选外部依赖（浮动窗口管理）
```

## 外部依赖

Awesome 顶栏的 CPU / MEM / NET / BAT / VOL 组件不再依赖 `lain`，其中 CPU/MEM 直接读取 `/proc/stat` 与 `/proc/meminfo`；aarch64/arm64 的笔记本 Awesome 配置会额外启用 BRI，直接读取 `/sys/class/backlight`。当前仅保留一个可选外部依赖：

```bash
git clone https://github.com/Elv13/collision.git ~/.config/awesome/collision
```

- **collision** — 可选的浮动窗口智能布局，防止浮动窗口超出屏幕边界；缺失时 Awesome 仍会继续启动。

## Wibar 布局

```
主屏: ┌─[标签]─[布局]─[锁屏]─│─────────[任务列表]─────────│[NET│CPU│MEM│BAT│(BRI)│VOL]─[托盘]─[时钟]─┐
副屏: ┌─[标签]─[布局]─────────[任务列表]─────────│[时钟]─┐
```

- **左侧**: 主屏保留 5 个标签页（Nerd Font 图标）+ 布局指示器 + 锁屏按钮 + 提示框；次屏左侧只保留标签与布局，不再重复显示锁屏按钮、分隔符和空 prompt 区域，减少重复入口和留白。
- **左侧细节**：锁屏按钮悬浮会提示用途与快捷键；布局指示器悬浮会提示当前布局和切换方式。次屏左侧 spacing 和 taglist 右侧 margin 也会更紧一点，避免只剩标签/布局时仍显得空。
- **tooltip 风格**：lock / layout / tasklist 的 tooltip 文案也统一成标题 + 字段行，和时钟、音量、状态项保持更接近的阅读节奏。
- **中间**: 当前标签的窗口列表；聚焦窗口会使用圆角背景、蓝色文字和左侧细条高亮，扫视时更容易确认当前输入目标。
- **右侧**: 只有主屏显示 NET / CPU / MEM / BAT / VOL 与系统托盘；其他屏幕右侧只保留时钟，减少多屏状态重复和视觉噪音。托盘只放在主屏，并使用更小图标、深色胶囊背景和细边框。`BRI` 只在 Linux aarch64/arm64 的 Awesome 配置里尝试启用，并且只有检测到背光设备时才显示；没有 `/sys/class/backlight/*` 时会完全隐藏，不占位置。
- **右侧细节**：主屏右侧状态区会继续统一收紧 spacing；systray 与时钟外侧 margin 更紧，sysinfo / clock / systray 的胶囊权重会一起再压一档，尽量把空间留给 tasklist。
- **整体视觉**：整条顶栏使用悬浮圆角容器，外层 wibar 保持透明并继续预留工作区高度；顶部留出少量空隙，左右也留出边距，让状态栏不再贴住屏幕边缘。
- **窗口圆角**：普通/对话框等 managed 窗口使用 `theme.border_radius` 圆角；全屏或最大化窗口会自动退回矩形，避免边角露出桌面背景。picom 继续负责阴影、透明和 compositor 层圆角。
- **回退标题栏**：日常主体验默认不显示 titlebar；只有显式 class 白名单中的少数配置类工具窗会启用一条紧凑的 fallback titlebar，用于拖动和关闭窗口。该 titlebar 进一步收紧成更矮的条带、左对齐标题和低噪音 Catppuccin 胶囊按钮，不再使用 Awesome 默认 PNG 按钮；右侧只保留 `floating / maximized / close` 三个文字按钮，其中激活态改成更克制的 `surface1` 底 + 蓝字，关闭按钮保持低噪音深底 + 红字，让窗口焦点的主信号重新回到蓝色边框本身。普通 `utility` 窗口不会因为类型本身就自动启用它，像 `tblive` 这类辅助条窗口也会继续排除在外。
- **右侧视觉**：系统信息分隔符使用更弱的主题色，时钟使用独立胶囊背景作为右端视觉终点，避免状态区显得过散。
- **长标题 / 网络细节**：长窗口标题会在单个任务项内尾部省略，避免浏览器或笔记窗口挤压右侧状态区；tasklist 标题最大宽度会按当前屏幕宽度、compact/full 规格以及当前标签页窗口数量自适应，不再固定死一个像素值；窗口较多时 tasklist 会进一步收紧标题宽度与条目间距，优先保护右侧状态区空间；tasklist 悬浮会显示完整窗口标题和应用名，方便在省略后补看全名；tasklist 项在 compact 屏上也会进一步收紧 padding 与 item spacing；NET 保持短显示，悬停时显示网卡接口名和带 `/s` 单位的上下行速率。
- **状态项交互**：NET/CPU/MEM 不绑定点击动作，只在鼠标悬浮时显示内置 detail；NET/CPU/MEM/VOL/BAT 的 tooltip 使用统一中文文案。NET detail 展示网卡接口名和带 `/s` 单位的上下行速率，并优先显示默认路由对应的活跃网卡；找不到匹配接口时主栏显示 `NET:N/A` 且 hover 显示离线；CPU/MEM detail 使用各自精简内容：CPU 显示 CPU 使用率、负载（load average）和 top CPU 进程，MEM 显示内存使用率和 top MEM 进程，并使用 5 秒后台缓存，hover 时不临时执行 `ps`；BAT hover 显示充放电状态、当前电量、功率和可估算的剩余/充满时间，检测到多个电池时会聚合成一个 BAT 读数并在 tooltip 中标出电池数量；在 Linux aarch64/arm64 且检测到背光设备时，BRI hover 会显示当前亮度百分比、背光设备名与原始亮度值；安装 `brightnessctl` 且当前用户对背光设备有写权限时，可在 BRI 上用滚轮加减亮度；未安装时滚轮会提示缺少 `brightnessctl` 并给出安装命令；若 `brightnessctl` 已安装但当前用户没有写权限，则会提示把用户加入对应设备组（如 `video`）后重新登录；VOL 保留左键静音和滚轮调音量，静音后只显示 `MUTE`（如 `VOL:MUTE`），右键 VOL 会尝试打开 `pavucontrol`，缺少 `pavucontrol` 或启动失败时会提示；悬浮 VOL 会提示左键/右键/滚轮的具体作用。音量与亮度组件继续使用周期刷新，并保留用户交互后的短延迟补刷新；空闲轮询频率相较旧版本更低，以减少后台刷新噪音。本轮未引入新的事件订阅机制，也未切换到纯图标 tasklist 模式。
- **全量 / 紧凑模式**：主屏系统信息优先读取 Awesome `screen.outputs` 里的物理尺寸；检测到屏幕物理对角线 **超过 15 英寸** 时使用全量模式，保留完整日期与 MEM 等状态项。全量模式使用 `CPU/MEM/BAT/VOL` 完整标签；在 Linux aarch64/arm64 且检测到背光设备时，会额外插入 `BRI`。只有检测不到物理尺寸时，才回退到 `compact_wibar_max_width = 3000` 的逻辑宽度阈值。
- **紧凑模式**：主要给 15 英寸及以下内屏的主屏状态区使用，会缩短日期并隐藏 MEM，优先保留 NET / CPU / BAT / VOL / 时钟；在 Linux aarch64/arm64 且检测到背光设备时，会额外保留 BRI；非主屏始终只显示时钟。
- **屏幕拓扑刷新**：外接屏热插拔、`xrandr` 改变几何或主屏切换后，会延迟重建各屏 wibar 内容，重新判断主屏状态区和 full/compact 模式；tag 和 prompt 继续复用，tasklist 只有在标题宽度规格变化时才重建。主屏右侧的 sysinfo / VOL / systray 也会优先复用已有 widget；若当前是 Linux aarch64/arm64 且有背光设备，则 BRI 也会一起复用，只有规格从 full/compact 切换时才重建，避免重复后台轮询。
- **显示布局刷新**：`rc.lua` 还会在屏幕新增/移除或 Awesome 收到 `screen::change` 后，延迟调用 `~/.config/awesome/display-layout.sh` 重算平台布局；这样 aarch64 笔记本在外接屏热插拔后不必重新登录就能重新应用主屏、位置和缩放策略。
- **时钟交互**：时钟不绑定点击或滚轮动作，避免鼠标经过或误点时弹出月历；悬浮时显示完整日期、星期和时间。

### 桌面动作入口

`actions.lua` 会在执行 Rofi、Dolphin、截图 OCR 与锁屏前检查关键命令或脚本是否可用；缺少依赖或执行失败时会通过 Awesome 通知提示，而不是让快捷键静默无效。截图 OCR 仍使用 `maim` 截图并调用本机 Pot OCR 服务，取消截图选择不会弹失败提示。

## 锁屏

- 快捷键：`Mod+Shift+l`，左侧 wibar 的锁屏按钮也调用同一个动作。
- 脚本：`~/.config/scripts/lock`。优先使用 `i3lock-color`；若只有支持 `--blur` 的 `i3lock`，则使用同一套模糊、时钟和主题配色；若只有普通 `i3lock`，则自动生成 `~/.cache/lock/i3lock-catppuccin-<宽>x<高>-<布局>.png` 这类 Catppuccin Mocha 静态背景并执行 `i3lock -n -e -f -i <image> -c 11111b`。生成失败时才降级到纯色 `i3lock -n -e -f -c 11111b`，避免传入不兼容的 `--blur` 参数。
- 普通 `i3lock` 路径没有真实模糊/时钟能力；这里用缓存 PNG 提升观感，安装 `i3lock-color` 后会自动切回主题化模糊锁屏。
- 多屏：主题化路径不再固定 `--screen 1`，让锁屏器自己处理当前 X11 屏幕布局；普通 `i3lock` 静态背景会读取 `xrandr --current` 的已启用输出，在每个屏幕中心各画一份卡片/锁图标，避免一张图跨双屏只在总画布中心显示一次。
- 自动锁屏：autostart 会在 `xautolock` 与 `~/.config/scripts/lock` 都可用时启动 `xautolock -time 10 -locker ~/.config/scripts/lock -detectsleep`，空闲 10 分钟后自动锁屏；缺少 `xautolock` 时静默跳过。

## 快捷键

`Mod4` = Super 键（键盘上的 Windows 徽标键）

### 基础操作

| 快捷键 | 功能 |
|--------|------|
| `Mod+Return` | 打开终端 (alacritty) |
| `Mod+e` | 打开文件管理器 (dolphin) |
| `Mod+w` | 显示主菜单 |
| `Mod+c` | 显示 Rofi 应用启动器 |
| `Mod+r` | 运行命令提示框 |
| `Mod+s` | 截图 + OCR 翻译 |
| `Mod+Shift+s` | 显示快捷键帮助 |
| `Mod+Ctrl+r` | 重启 AwesomeWM |
| `Mod+Shift+q` | 退出 AwesomeWM |
| `Mod+Shift+l` | 锁屏 |

Snipaste 自己接管裸 `F1` 截图；Awesome 不绑定 `F1`。如果 Snipaste 已运行但 `F1` 无效，优先检查 KDE 全局快捷键服务是否还在运行并抢占了该键：`~/.config/kglobalshortcutsrc` 中 `[org.flameshot.Flameshot.desktop]` 的 `Capture` 应为 `none,none,进行截图`，否则 `kglobalaccel5` 会把 `F1` 交给 Flameshot，Snipaste 日志会出现 `Unable to register global hotkey`。

### 窗口焦点

| 快捷键 | 功能 |
|--------|------|
| `Mod+j` | 聚焦下一个窗口 |
| `Mod+k` | 聚焦上一个窗口 |
| `Mod+Tab` | 切换到上一个聚焦的窗口 |
| `Mod+[` | 切换到左侧屏幕 |
| `Mod+]` | 切换到右侧屏幕 |
| `Mod+u` | 跳转到紧急窗口 |

### 窗口操作

| 快捷键 | 功能 |
|--------|------|
| `Mod+q` | 关闭当前窗口 |
| `Mod+f` | 切换全屏 |
| `Mod+m` | 切换最大化 |
| `Mod+t` | 切换置顶 |
| `Mod+n` | 最小化窗口 |
| `Mod+Ctrl+n` | 恢复最小化窗口 |
| `Mod+Ctrl+Space` | 切换浮动模式 |
| `Mod+Ctrl+Return` | 移到主区域 |
| `Mod+Shift+j` | 与下一个窗口交换位置 |
| `Mod+Shift+k` | 与上一个窗口交换位置 |
| `Mod+o` | 移动到其他屏幕 |

### 布局调整

| 快捷键 | 功能 |
|--------|------|
| `Mod+h` | 缩小主区域宽度 |
| `Mod+l` | 扩大主区域宽度 |
| `Mod+Shift+h` | 增加主区域窗口数量 |
| `Mod+Ctrl+Shift+l` | 减少主区域窗口数量 |
| `Mod+Ctrl+h` | 增加列数 |
| `Mod+Ctrl+l` | 减少列数 |
| `Mod+Space` | 切换到下一个布局 |
| `Mod+Shift+Space` | 切换到上一个布局 |

### 标签页 (Tag)

| 快捷键 | 功能 |
|--------|------|
| `Mod+1` ~ `9` | 切换到指定标签 |
| `Mod+Ctrl+1` ~ `9` | 显示/隐藏指定标签 |
| `Mod+Shift+1` ~ `9` | 将当前窗口移至指定标签 |
| `Mod+Shift+Ctrl+1` ~ `9` | 在当前标签上叠加/移除指定标签 |
| `Mod+a` | 切换到前一个**有窗口**的标签 |
| `Mod+d` | 切换到后一个**有窗口**的标签 |
| `Mod+Escape` | 回到上一个标签 |

### 鼠标操作

| 操作 | 功能 |
|------|------|
| 右键 | 切换主菜单 |
| 滚轮上/下 | 切换下一个/上一个标签 |
| `Mod+左键拖拽` | 移动窗口 |
| `Mod+右键拖拽` | 调整窗口大小 |

### 窗口规则

以下应用自动以**浮动模式**打开：

- Arandr, Blueman-manager, Gpick, Kruler, Sxiv, Tor Browser
- Wpa_gui, veromix, xtightvncviewer, Pot（翻译工具）
- pinentry, copyq

默认 Awesome 示例里的 `DTA`（Firefox / DownThemAll 历史规则）不保留；当前不用 Firefox，且该 instance 名容易把历史浏览器扩展规则混进钉钉等 Electron/Qt 窗口判断。

钉钉会议会额外创建多个 `tblive` / `utility` 辅助窗口（例如会控条、状态条等）。这些辅助窗口不代表独立应用窗口，因此规则只对 `class = tblive` 且 `type = utility` 的窗口设置 `skip_taskbar = true` 并保持浮动；真正的 `tblive` 普通会议窗口仍会保留在任务列表中。

普通 `normal` / `dialog` 窗口继续默认不显示 titlebar；只有显式 class 白名单里的少数配置类浮动工具窗才会启用紧凑 fallback titlebar，主要用于拖动与快速关闭；普通 `utility` 窗口不会仅因为 `type=utility` 就自动出现标题栏，也不会再因为通用 role 自动命中 fallback titlebar。
