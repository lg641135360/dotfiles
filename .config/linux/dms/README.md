# DMS（DankMaterialShell）机器上的 niri 接入

本目录是仓库在 **DMS 自管 niri 会话**里的唯一入口：DMS 会重写
`~/.config/niri/config.kdl` 并只 include 自己的 `dms/*.kdl` 片段，仓库的
`.config/linux/niri/common.kdl` 不再生效，`wayland-autostart` 也不会被拉起。

## 文件与职责

| 文件 | 部署位置 | 作用 |
| --- | --- | --- |
| `niri-repo.kdl` | `~/.config/niri/niri-repo.kdl` | 仓库补回的 niri 片段：**只含仓库肌肉记忆键位**（不 spawn 仓库 autostart，理由见下） |
| `settings.txt` | `~/.config/dms/settings.txt` | DMS 设置清单（key=value），由接线脚本幂等下发到 `dms ipc call settings set` / `night` |
| `.config/scripts/dms-niri-setup` | `~/.config/scripts/dms-niri-setup` | 幂等接线脚本：下发 DMS 设置、补齐 DMS 默认键位、补 `dms/*.kdl` include、保证顺序、重建钉钉窗口规则 |

`install.sh` 检测到 `niri` + `dms` 时自动部署片段并运行接线脚本；脚本本身在
非 niri / 非 DMS 机器上是 no-op，也可以随时手动跑：

```bash
dms-niri-setup            # 应用（改动前备份 config.kdl，同类备份保留 3 份）
dms-niri-setup --check    # 巡检；有待补项时退出码 1
dms-niri-setup --dry-run  # 只打印将做的改动
```

## DMS 默认键位的生成方式

DMS 首次运行只会把 `~/.config/niri/dms/binds.kdl` 建成 0 字节，键位需要额外生成；而
`dms setup binds` 是**交互式**命令（在无 TTY 的脚本里会因 “Choose one / Choice” 报
`FATAL ... invalid choice`）。所以接线脚本改用非交互入口：在临时 HOME 里跑
`dms setup headless --compositor niri --skip-existing`（已装 alacritty 时加
`--terminal alacritty`），**只取生成的 `binds.kdl`** 复制到 `~/.config/niri/dms/`，
不碰真实的 `config.kdl`（headless 模式在 config.kdl 不存在时会写一份完整配置）。
因此 `Mod+T` 默认落到 alacritty；想换成别的终端就在 DMS 设置 → Keybinds 里改，
或用仓库的 `Mod+Return`（优先 foot）。

## DMS 设置的下发（`settings.txt`）

DMS 的设置面很宽（30 个设置页、600+ 设置键），但绝大多数在本机仍处于 DMS 默认值，
不值得全部固化。仓库只声明**跨机器稳定、与机器无关**的少数决策：

```
<SettingsData 键>=<值>        → dms ipc call settings set <键> <值>
night.temperature=<K>         → dms ipc call night setTargetTemp <K>
night.enabled=<true|false>    → dms ipc call night enable|disable
```

当前内容与理由（2026-10-06 在 Fedora 44 + DMS 1.6.2 上逐项对照过默认值）：

| 键 | 值 | 理由 |
| --- | --- | --- |
| `acLockTimeout` | 600 | DMS 默认 0 = **永不自动锁屏**，与仓库 Wayland 基线（swayidle 空闲 10 分钟锁屏）不符 |
| `acMonitorTimeout` | 900 | 同上，基线是 15 分钟关屏 |
| `useAutoLocation` | false | 本机 GeoClue2 不可用（`dms` 日志 `WARN GeoClue2 unavailable`），关掉避免反复重试 |
| `touchpadDragLock` | true | 对齐仓库 niri input 基线（`common.kdl` 的 `drag-lock`） |
| `night.temperature` | 5500 | 对齐仓库 gammastep 基线（4800/4500K 会把屏压得过暗） |
| `night.enabled` | true | 基线里色温一直生效（session 状态，不属于 SettingsData） |

不写进清单的东西：`bar`/`dock`/`island`/主题/壁纸这类界面偏好在 DMS GUI（`Mod+Comma`）里调；
需要整机搬运时用 `dms backup create -o <file>` / `dms backup restore`（含 settings/plugins/themes）。

注意：

- **键名随版本变**：`settings get` 读不到（`undefined`/空）时脚本会警告并跳过该行，不会乱写；
- **`settings set` 只管 `settings.json`**：`wallpaperCyclingEnabled`（session.json）、
  `nightMode*`/`displayGamma`（session.json）这类不在 SettingsData 里，只能用 `dms ipc call night`
  或 GUI；脚本已为 `night.temperature` / `night.enabled` 单独走 `night` 通道；
- **单独回退一项**：`dms ipc call settings set <键> <原值>`（例如 `dms ipc call settings set acLockTimeout 0`），
  或 `dms ipc call night disable`；
- `--check` 会把这些项当成漂移一并报告（退出码 1）。

## 接线机制（两条硬约束）

1. **include 顺序决定键位归谁**：niri 的 `binds {}` 合并规则是「后出现的同键绑定
   覆盖先出现的」（`niri-config/src/lib.rs`，注释明确是为了"先 import 公共配置、
   再覆盖若干键位"这一用法）。所以 `include "niri-repo.kdl"` **必须排在所有
   `include "dms/*.kdl"` 之后**；脚本会在顺序不对时重写尾部的 include 块。
2. **只补仓库自己的一层**：DMS 自管的 bar / 通知 / 锁屏 / idle / 壁纸 / 配色 /
   `layout` / `input` / 窗口规则 / **剪贴板**都不在本目录重复声明。DMS 机器上需要仓库
   配的东西实际只剩**仓库肌肉记忆键位**。

**为什么不在 DMS 机器上 spawn 仓库的 `wayland-autostart`**（2026-10-06 Fedora 44 实测）：

| 仓库 autostart 原职责 | DMS 机器上实际由谁承担 |
| --- | --- |
| 环境导入（systemd/dbus） | `niri-session` 自己完成（`systemctl --user import-environment` + `dbus-update-activation-environment --all`） |
| 状态栏 waybar / 通知 mako | DMS（且两者不安装） |
| 锁屏 swaylock / idle swayidle | DMS（`dms ipc call lock lock`、DMS idle） |
| 壁纸 swaybg | DMS 壁纸模块 |
| 色温 gammastep | DMS night light（`dms ipc call night …`） |
| polkit agent | DMS 自带 polkit（`dms doctor` 显示 Polkit Available） |
| 剪贴板链（clipboard-wayland + wl-clip-persist + cliphist） | DMS 自带剪贴板服务（`dms clipboard history` / `copy` / `paste`；还有 `cliphist-migrate` 迁移旧历史） |
| fcitx5 | XDG autostart（`~/.config/autostart/fcitx5.desktop`，niri.service → `xdg-desktop-autostart.target`） |
| `GTK_IM_MODULE` 清理 | Fedora 的 `/etc/environment` 不含该变量，不需要清理 |
| 应用包装脚本（browser/terminal/launcher…） | 这些是**按键按需 spawn**，不靠 autostart |

所以 DMS 机器上 spawn 它只会重复职责（而且一旦以后装了 blueman/udiskie/polkit-gnome
就会出现双份）。真要其中某一项（例如 X11↔Wayland 剪贴板桥 `clipboard-wayland`、
或 gammastep），在 `niri-repo.kdl` 里把 `spawn-sh-at-startup "~/.config/scripts/wayland-autostart"`
加回去，并确认不与 DMS 同类服务重复。

## 键位决策（2026-10-06，按 DMS 默认键位逐条对照）

DMS 默认键位用 `dms setup binds` 生成到 `~/.config/niri/dms/binds.kdl`，
可以在 DMS 设置 → Keybinds 查看/编辑（`dms keybinds show niri`）。
下面只列**与 DMS 默认不同**的键；完全一致的（`Mod+Q`、`Mod+O`、`Mod+W`、
`Mod+Shift+V`、`Mod+Minus/Equal`、`Mod+BracketLeft/Right`、`Mod+Shift+J/K`、
`Mod+1..9`、`Mod+Escape`、`Mod+Shift+Slash`、`Mod+Wheel*` 等）不重复声明。

### 仓库独有键位（DMS 未占用，直接恢复）

| 键 | 动作 |
| --- | --- |
| `Mod+Return` | 终端（`terminal-wayland`，优先 foot） |
| `Mod+E` | 文件管理器（`file-manager-wayland`） |
| `Mod+grave` | 聚焦上一个 workspace |
| `Mod+A` / `Mod+D` | 焦点切到左/右显示器 |
| `Mod+Ctrl+Shift+A` / `Mod+Ctrl+Shift+D` | 当前 workspace 移到左/右显示器 |
| `Mod+Ctrl+1..9` | 把当前列送到 workspace N |
| `Mod+Shift+Space` | 反向循环列宽（DMS 只有 `Mod+R` 正向） |
| `Mod+Ctrl+M` | 当前列最大化（DMS 的 `Mod+M` 被任务管理器占用） |
| `Mod+S` | 截图（`screenshot-wayland` + satty） |
| `Mod+Shift+Q` | 退出 niri（DMS 默认是 `Mod+Shift+E`，两者都保留） |

### 同键覆盖 DMS 默认（仓库语义优先）

| 键 | 仓库动作 | DMS 默认 | 取舍理由 |
| --- | --- | --- | --- |
| `Mod+Tab` | 焦点历史窗口（`focus-window-previous`） | 切换 overview | overview 已有 `Mod+O`，不占用 Tab |
| `Mod+F` | 扩展当前列到可用宽度 | `maximize-column` | 保留仓库语义；DMS 的把 expand 放在 `Mod+Ctrl+F` |
| `Mod+Ctrl+F` | 切换窗口浮动 | `expand-column-to-available-width` | 浮动切换更常用（DMS 默认在 `Mod+Shift+T`，仍可用） |
| `Mod+H/L`、`Mod+J/K` | `focus-column-or-monitor-*` / `focus-window-or-workspace-*` | `focus-column-*` / `focus-window-*` | 仓库版在边界会跨显示器/跨 workspace |
| `Mod+Shift+H/L` | `move-column-*-or-to-monitor-*` | `move-column-*` | 同上，支持跨屏搬列 |
| `Mod+Shift+1..9` | 移动**窗口**到 workspace N | 移动**列**到 workspace N | 与 `Mod+Ctrl+1..9`（移动列）构成一组；DMS 的列语义由 Ctrl 组承担 |
| `Mod+Shift+N` | 免打扰 | 记事本（notepad） | 保留仓库肌肉记忆，动作用 DMS 的 `dms ipc call notifications toggleDoNotDisturb`（DMS 机器没有 mako） |

### 让给 DMS（仓库不声明，用 DMS 默认）

| 键 | DMS 动作 | 仓库原动作 |
| --- | --- | --- |
| `Mod+Space` | spotlight 启动器 | 循环列宽（改用 DMS 的 `Mod+R`） |
| `Mod+M` | 任务管理器 | `maximize-window-to-edges`（用 `Mod+Ctrl+M` 代替） |
| `Mod+C` | `center-column` | `launcher-wayland`（启动器已有 `Mod+Space`） |
| `Mod+Ctrl+C` | `center-visible-columns` | `center-column` |
| `Mod+Shift+W` | 创建窗口规则 | 切换壁纸（用 `Mod+Y` 或 `dms ipc call wallpaper next`） |
| `Mod+Shift+N` | 记事本 | 见上表，仓库覆盖成免打扰 |
| `Mod+Alt+L` | DMS 锁屏 | `lock-wayland`（swaylock） |
| `Mod+V` | DMS 剪贴板面板 | `clipboard-wayland history` |
| `XF86Audio*`、`XF86MonBrightness*` | DMS audio/mpris/brightness（带 OSD） | `wpctl` / `playerctl` / `brightnessctl` |
| `Ctrl+Print` / `Alt+Print` | `dms screenshot full/window` | niri 内建截图 |

### DMS 独有、仓库不干预

`Mod+T`（终端）、`Alt+Space`、`Mod+Comma`（设置）、`Mod+Y`（壁纸）、`Mod+N`
（通知中心）、`Super+X`（电源菜单）、`Mod+Shift+F/T/E`、方向键导航、`Mod+Home`、
`Mod+R`/`Mod+Shift+R`/`Mod+Ctrl+R`、`Mod+P`（显示配置）、`Mod+Shift+P`（关屏）、
`Mod+Period`、`Mod+Shift+Page_Up/Down`、`Mod+Shift+U/I`、`Ctrl+Shift+R`、
`Print` / `XF86Launch1` 截图三连等。

## 不接管（DMS 自管）

窗口规则（`dms config windowrules`，仓库只补钉钉三条）、配色（`dms/colors.kdl`）、
layout（`dms/layout.kdl`）、输入设备（`dms/input.kdl`）、光标、壁纸、idle/锁屏、
状态栏、通知、launcher、polkit agent、夜间色温（`dms ipc call night …`）。

钉钉三条规则由脚本通过 DMS 通道重建（顺序：弹窗不抢焦点 → 弹窗浮动 →
主窗口平铺，niri 按顺序处理、后者覆盖前者）：

```bash
dms config windowrules list niri          # 规则集 + dmsStatus
dms config windowrules remove niri <id>   # 回滚单条
```

## 依赖

Fedora 侧见 `.config/linux/packages/dnf.txt` 的「niri + DMS（Fedora）」一节：
`niri` / `xwayland-satellite` / `quickshell` / `dms` + `wl-clip-persist` / `cliphist`
（COPR：`avengemedia/dms`）；色温走 DMS 自带 night light，不装 gammastep。

## 验证

```bash
dms-niri-setup --check                       # 接线状态（0 = 已就绪）
dms config resolve-include niri binds.kdl    # 注意用文件名，不要带 dms/ 前缀
niri validate -c ~/.config/niri/config.kdl
dms doctor                                   # Compositor / Blur / dms.service
dms config windowrules list niri             # dmsStatus.included 应为 true
dms ipc call settings get acLockTimeout      # 应为 600（设置清单已下发）
dms ipc call night status                    # Night mode: enabled；target 5500K
```

⚠️ **DMS 设置里的 Keybinds 页面只读 `dms/binds.kdl`，不会反映 `niri-repo.kdl` 的覆盖**
（实测：`dms keybinds show niri` 里 `Mod+Tab` 仍显示 DMS 的 `toggle-overview`）。niri
运行时的合并规则是「后出现的同键替换先出现的」且有且仅有一条（`niri-config/src/lib.rs`
的 `binds` 分支：`retain` 掉同键旧绑定再 `extend`），而 `niri-repo.kdl` 排在所有
`dms/*.kdl` 之后，所以**生效的是仓库键位**。要改被覆盖的键就改 `niri-repo.kdl`；
要在 DMS UI 里看真实归属，可实按验证（例：按 `Mod+Shift+N` —— 开记事本说明 DMS 赢、
切换免打扰说明仓库赢，`dms ipc call notifications getDoNotDisturb` 可读状态）。

## 回退

- 接线层：`~/.config/niri/config.kdl.backup.<时间戳>`（脚本与 `install.sh` 生成，
  保留最近 3 份）；把末尾的仓库 include/注释块删掉即可停用仓库片段。
- 键位层：删掉 `~/.config/niri/niri-repo.kdl` 里的对应 `binds` 条目，或整文件
  移走后重跑 `dms-niri-setup`（它会撤销 include）。
- 窗口规则：`dms config windowrules remove niri <id>`。
