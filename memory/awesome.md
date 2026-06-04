# AwesomeWM 偏好

## 调试与同步
- 调试 AwesomeWM 行为时，必须同时检查仓库副本和 live `~/.config/awesome` 副本；仓库修复不会影响运行中会话，直到同步并重载 Awesome。
- 屏幕几何、主屏或 RandR 拓扑变化后延迟重建 wibar 内容，重新判断主屏状态区与 full/compact 模式；重建时复用已有 tag/tasklist/prompt，避免破坏标签状态。

## 架构
- 优先把可复用桌面动作收口到独立 `actions.lua`，`bindings.lua` 通过显式注入消费 prompt runner，不直接读取 `screen.mypromptbox` 等隐式字段。
- `ui/wibar.lua` 自己创建每屏 widget（lock button、clock、sysinfo），只把 `actions`、`config`、能力标志从 `rc.lua` 注入。
- 顶栏使用悬浮圆角容器：外层 wibar 透明并预留工作区高度，内层状态栏顶部和左右留少量空隙。
- 单个状态项保持扁平透明：锁屏、布局、sysinfo、时钟、托盘等只保留文字、图标、分隔符和必要 padding，不再为每个项目单独加背景色或胶囊。

## 右侧状态区
- 主屏右侧显示 NET/CPU/MEM/BAT/VOL 与 systray；非主屏只保留时钟。
- 弱化竖线分隔符；时钟与托盘保持扁平透明，时钟文字作为右端视觉终点。
- full 模式使用 `CPU/MEM/BAT/VOL` 完整标签，compact 模式使用 `C/M/B/V` 短标签；标签和值之间使用冒号分隔（如 `C:12%`）。
- NET/CPU/MEM 保持不可点击，只在 hover 显示 detail；VOL 左键静音、滚轮调音量、右键 `pavucontrol`。
- CPU/MEM hover detail 展示使用率、load average 和 top 进程；top 进程列表由 5 秒后台异步缓存刷新，hover 时只读缓存。
- VOL 左键静音后只显示 `MUTE`，取消静音后恢复音量值。
- NET 找不到匹配接口时显示 `NET:N/A`/offline，清掉旧速率计数。
- 时钟不绑定点击或滚轮动作，只在 hover tooltip 显示完整日期、星期和时间。

## Sysinfo 紧凑化
- 压缩优先级：内部 spacing → 左右 padding；基线 `system_row.spacing = 4`、容器 `left/right = 6`。
- 紧凑基线：CPU/MEM/BAT 用短标签 `C/M/B`，NET 用箭头速率，`system_row.spacing = 2`，容器 `left/right = 4`，右侧 wibar spacing = 6。
- 紧凑顺序：`NET → CPU → MEM → BAT`。
- CPU/BAT/VOL 标签和值之间用冒号分隔。

## 屏幕检测与模式
- compact/full 判定优先读取 `screen.outputs` 物理尺寸；物理对角线 >15" 切 full 模式，≤15" compact 用短时钟。
- 检测不到物理尺寸时回退到 `screen.geometry.width <= compact_wibar_max_width`。

## Tasklist
- 每屏 tasklist 只显示该屏当前标签上的一个普通可见窗口：优先全局当前焦点，非聚焦屏回退到该屏 focus history 最近窗口或第一个可见窗口；同一标签页其它窗口不在顶栏列出。
- 隐藏/最小化窗口通过独立"隐藏窗口"提示保留入口；只统计普通任务窗口，排除 `skip_taskbar`/dock/desktop/splash。
- 隐藏窗口右键菜单在列表变化、焦点切换或标签切换时自动关闭。
- 任务项背景透明透出状态栏底色，焦点识别靠蓝色标题文字与左侧细条。
- 自定义透明容器不使用内置 `background_role` 名称（会被 Awesome 自动重新上色），用 `task_background_role` 等非内置 id。
- 单标签页只有一个可见窗口时，标题使用顶栏中间区可用空间尽量完整显示；多窗口时回到保守宽度与尾部省略。
- 限制单个 tasklist 长标题最大宽度并用尾部省略保护状态区。

## 工作区
- 工作区顺序：开发第 1、浏览器第 2，后续文档/沟通/杂项依次排列。
- 当前工作区蓝色图标主焦点；非当前有窗口的工作区在右上角 overlay 淡紫小点；urgent 红色小圆点。
- 使用 `wibox.widget.separator` 绘制 overlay 小圆点，不用无 child 的 `wibox.container.background`。

## 窗口管理
- 默认 client 规则设置 `size_hints_honor = false`。
- managed 窗口圆角在 `client.lua` 用 `c.shape` 消费 `beautiful.border_radius`；全屏/最大化时退回 `gears.shape.rectangle`。
- titlebar 收口成显式 class 白名单中的少数配置类工具窗 fallback，只保留 `floating/maximized/close` 三个按钮。
- 钉钉 `tblive` type=utility 辅助窗口设为浮动并 `skip_taskbar=true`；普通会议窗口保留为可见任务。
- 当前不用 Firefox/DownThemAll；不应保留 `DTA` instance 自动浮动规则。

## 快捷键
- 锁屏使用 `Mod+Shift+l`；`Mod+Ctrl+l` 留给布局减少列数；`Mod+Ctrl+Shift+l` 减少主区域窗口数量。
- 桌面动作入口（Rofi、Dolphin、截图 OCR、锁屏等）在执行前检查关键命令/脚本能力，缺依赖或执行失败时用通知提示；用户主动取消不弹失败提示。

## Widget 实现
- NET 用 Lua 解析 `/proc/net/dev`，先初始化上一轮计数再显示速率；不依赖 `cat|grep|awk` shell pipeline。
- NET widget 空间紧张时去掉固定 `NET` 文本标签，保留彩色上下行箭头和速率值。
- NET 主栏保持短速率显示，接口名和 `/s` 单位放 hover tooltip。
- 所有 tooltip 文案使用统一中文格式。
- Volume widget 提供 2 秒级周期刷新与显式静音态展示；`pactl` 失败时降级为 `N/A`。
- 音量写操作失败时立即回退到 `N/A` 并再触发一次读刷新。
- CPU/MEM 用原生 `/proc/stat` 与 `/proc/meminfo` 读取，不再要求 `lain`。
- `collision` 仅作为可选浮动窗口辅助依赖保留，缺失时仍应启动。
- 硬件相关 widget 优先运行时检测并在设备缺失时完全隐藏。

## 壁纸
- 由 `autostart/*.sh` 里的 `feh` 管理；`theme/*.lua` 和 `ui/wibar.lua` 不写 `theme.wallpaper` 或 `gears.wallpaper.maximized()`。
- autostart 每次执行 `feh --no-fehbg --bg-fill --randomize` 从候选目录重新随机选择。

## Autostart
- 根目录 `autostart.sh` 保持为平台分发 wrapper，转发到 `autostart/*.sh`。
- 抽出共享 `common.sh` 收口 `run()`、Xresources 初始化和公共后台服务启动；平台脚本只保留差异逻辑。
- 可选服务在共享 `run()`/`run_custom()` 层做命令可用性检查，缺失时静默跳过。
- 后台服务通过共享 `start_background()` 用 `setsid -f` 分离进程。
- Xresources/壁纸 helper 缺失时静默跳过，不中断 autostart。
- lock 脚本：优先 `i3lock-color`/带 `--blur` 的 `i3lock`；普通 fallback 用 Python 生成 Catppuccin Mocha 静态 PNG；多屏按每个输出画居中卡片；生成失败时退纯色。自动锁屏由 `xautolock -time 10 -locker ~/.config/scripts/lock -detectsleep` 启动，缺依赖时静默跳过。

## 多屏
- Ubuntu aarch64 外接屏：内屏 `2880x1800@120Hz` 主屏，外接屏默认显式固定为 `2560x1440@59.95Hz` 放笔记本右侧，避免误选 `3840x2160@30` 或 `1920x2160` 这类不适合横向 16:9 桌面的特殊模式。
- `Xft.dpi: 192` 是内屏合适基线。
- Ubuntu aarch64 autostart 运行时探测内屏名（`eDP`/`LVDS`/`DSI`）。
- Snipaste 在候选路径里按版本号选择最新可执行 AppImage。
- Snipaste 裸 `F1` 由 Snipaste 自己注册全局热键；Awesome 不绑定裸 `F1`。

## 网络
- 匹配接口名同时覆盖 `enp*`（有线）和 `wlp*`（无线）。

## 锁屏快捷键
- `Mod+Shift+l` 锁屏；`Mod+Ctrl+l` 保留给布局减少列数；`Mod+Ctrl+Shift+l` 减少主区域窗口数量。
