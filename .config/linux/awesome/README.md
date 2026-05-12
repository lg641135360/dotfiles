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
├── ui/
│   └── wibar.lua       # ui/wibar.lua：顶栏、taglist、tasklist、托盘、时钟
├── widgets/
│   ├── system.lua      # widgets/system.lua：CPU / MEM / NET 监控组件
│   └── volume.lua      # widgets/volume.lua：音量控制组件
├── theme/
│   └── catppuccin.lua  # Catppuccin Mocha 主题
├── autostart/          # 各平台自启脚本
│   ├── arch_x64.sh
│   ├── ubuntu_x64.sh
│   └── ubuntu_aarch64.sh
└── collision/          # 外部依赖（浮动窗口管理）
└── lain/               # 外部依赖（系统监控库）
```

## 外部依赖

以下两个库需要在安装时手动 clone（install.sh 会自动检测并安装）：

```bash
git clone https://github.com/lcpz/lain.git ~/.config/awesome/lain
git clone https://github.com/Elv13/collision.git ~/.config/awesome/collision
```

- **lain** — 系统监控（CPU/内存占用），用于 wibar 的 CPU 和 MEM widget
- **collision** — 浮动窗口智能布局，防止浮动窗口超出屏幕边界

## Wibar 布局

```
┌─[标签]─[布局]─[锁屏]─│─────────[任务列表]─────────│[NET│CPU│MEM│BAT│VOL]─[托盘]─[时钟]─┐
```

- **左侧**: 5 个标签页（Nerd Font 图标）+ 布局指示器 + 锁屏按钮 + 提示框
- **中间**: 当前标签的窗口列表；聚焦窗口会使用圆角背景、蓝色文字和左侧细条高亮，扫视时更容易确认当前输入目标。
- **右侧**: 系统监控 + 系统托盘 + 时钟；托盘只放在主屏，并使用更小图标、深色胶囊背景和细边框降低视觉噪音。
- **右侧视觉**：系统信息分隔符使用更弱的主题色，时钟使用独立胶囊背景作为右端视觉终点，避免状态区显得过散。
- **长标题 / 网络细节**：长窗口标题会在单个任务项内尾部省略，避免浏览器或笔记窗口挤压右侧状态区；NET 保持短显示，悬停时显示网卡接口名和带 `/s` 单位的上下行速率。
- **状态项交互**：点击 NET 会打开网络状态终端面板；点击 CPU/MEM 会打开 `btop`/`htop`/`top` 系统监控；VOL 保留左键静音和滚轮调音量，右键 VOL 会打开 `pavucontrol`。
- **全量 / 紧凑模式**：优先读取 Awesome `screen.outputs` 里的物理尺寸；检测到屏幕物理对角线 **超过 15 英寸** 时使用全量模式，保留完整日期与 MEM 等状态项。全量模式使用 `CPU/MEM/BAT/VOL` 完整标签；只有检测不到物理尺寸时，才回退到 `compact_wibar_max_width = 3000` 的逻辑宽度阈值。
- **紧凑模式**：主要给 15 英寸及以下内屏使用，会缩短日期并隐藏 MEM，优先保留 NET / CPU / BAT / VOL / 时钟。
- **时钟交互**：左键点击时钟会在右上角弹出月历；再次点击关闭。鼠标不进入日历时，月历会在 5 秒后自动隐藏；进入日历会取消倒计时，离开日历后再等待 5 秒隐藏；鼠标滚轮可切换上 / 下个月。

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
| `Mod+c` | 显示应用菜单 (menubar) |
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
