# DMS（DankMaterialShell）机器上的 niri 接入

本目录是仓库在 **DMS 自管 niri 会话**里的唯一入口：DMS 会重写
`~/.config/niri/config.kdl` 并只 include 自己的 `dms/*.kdl` 片段，仓库的
`.config/linux/niri/common.kdl` 不再生效，`wayland-autostart` 也不会被拉起。

## 文件与职责

| 文件 | 部署位置 | 作用 |
| --- | --- | --- |
| `niri-repo.kdl` | `~/.config/niri/niri-repo.kdl` | 仓库补回的 niri 片段：**只含键位**（不 spawn 仓库 autostart，理由见下） |
| `../niri/<平台>/outputs.kdl` | `~/.config/niri/outputs.kdl` | 本机屏幕；按方案 B 作为 DMS 机器的权威 output 配置，include 在所有 `dms/*.kdl` 之前；不改写 `dms/outputs.kdl`。没有该平台文件的机器（当前 Fedora）跳过 |
| `settings.txt` | `~/.config/dms/settings.txt` | DMS 设置清单（key=value），由接线脚本幂等下发到 `dms ipc call settings set` / `night` |
| `.config/scripts/dms-niri-setup` | `~/.config/scripts/dms-niri-setup` | 幂等接线脚本：下发 DMS 设置、补齐 DMS 默认键位、补 `dms/*.kdl` include、保证顺序、重建钉钉窗口规则 |

`install.sh` 检测到 `niri` + `dms` 时自动部署片段、对应平台的 `outputs.kdl` 与 `settings.txt`，并运行接线脚本；脚本本身在
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

## 接线机制（三条硬约束）

1. **include 顺序决定键位归谁**：niri 的 `binds {}` 合并规则是「后出现的同键绑定
   覆盖先出现的」（`niri-config/src/lib.rs`，注释明确是为了"先 import 公共配置、
   再覆盖若干键位"这一用法）。所以 `include "niri-repo.kdl"` **必须排在所有
   `include "dms/*.kdl"` 之后**；脚本会在顺序不对时重写尾部的 include 块。
2. **本机屏幕由仓库负责**：niri 的 `output` 是按解析顺序取首个匹配项的 multipart 配置，因此方案 B 要求仓库的 `outputs.kdl` include 在所有 `dms/*.kdl` 之前，作为 DMS 机器的权威屏幕配置。DMS 仍可生成并保留 `dms/outputs.kdl`，但接线脚本不修改它，也不会让它覆盖仓库配置。
3. **只补仓库自己的一层**：DMS 自管的 bar / 通知 / 锁屏 / idle / 壁纸 / 配色 /
   `layout` / `input` / 窗口规则 / **剪贴板**都不在本目录重复声明。DMS 机器上需要仓库
   配的东西实际只剩**仓库肌肉记忆键位和本机屏幕**。

接线后的顺序示例：

```kdl
include "outputs.kdl"        // 仓库屏幕优先：output 首个匹配项生效
include "dms/outputs.kdl"    // 保留 DMS 文件；只为仓库未声明的屏幕提供配置
include "dms/binds.kdl"
// 其余 dms/*.kdl……
include "niri-repo.kdl"      // 仓库键位优先：binds 后出现的同键覆盖
```

仓库已声明屏幕的 mode / scale / position 应修改平台 `outputs.kdl`；DMS 显示设置写入
`dms/outputs.kdl` 的同屏配置不会替代它。`--check` 检测屏幕 include 缺失、重复或顺序错误；
应用时先备份 `config.kdl` 再修复，`--dry-run` 不写文件。
以上顺序针对配置文件；通过 IPC 临时修改显示设置的行为不由本脚本限制。

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

## 键位决策（2026-10-08，按本机 Ubuntu x64 的 live `dms/binds.kdl` 修订）

`niri-repo.kdl` 排在所有 `dms/*.kdl` 之后，写进去的同键会盖掉 live。
所以和本机已经一致的键**不写进片段**。非 DMS 机器仍用 `common.kdl`，不受这张表影响。

### 片段里会改 live 的键

| 键 | 接上片段后 | 本机现在 |
| --- | --- | --- |
| `Mod+E` | `spawn "thunar"` | `dms ipc call defaultApp fileManager` |
| `Mod+S` | `dms ipc call quickCapture screenshot region edit`（与本机相同） | 同左 |
| `Mod+Tab` | 上一个窗口（`focus-window-previous`） | 切换 overview |
| `Mod+Ctrl+F` | 切换浮动 | 扩展列宽（浮动现在在 `Mod+Shift+T`） |
| `Mod+Shift+1..9` | 移动**窗口**到 workspace N | 移动**整列** |
| `Mod+Shift+A` / `Mod+Shift+D` | 把**窗口**搬到左/右显示器（`move-window-to-monitor-*`） | 未绑定 |

`Mod+S` 即使动作相同也写进片段：否则下次 `dms setup binds` 把 `binds.kdl` 刷回出厂默认时，会掉回仓库旧的 satty 脚本。

### 片段里有、且本机 `binds.kdl` 已经相同的键

`Mod+Return`（`terminal-wayland`，本机落到 foot；本机另有 `Mod+T` 直接开 foot）、`Mod+grave`、`Mod+A` / `Mod+D`（焦点切屏）、`Mod+Ctrl+Shift+A` / `Mod+Ctrl+Shift+D`（整个 workspace 换屏）、`Mod+Ctrl+1..9`（整列换 workspace）、`Mod+Shift+Space`、`Mod+Ctrl+M`、`Mod+Shift+Q`。

### 故意不写进片段（沿用本机 `binds.kdl`）

| 键 | 保持的动作 | 不写的原因 |
| --- | --- | --- |
| `Mod+F` | `maximize-column` | 用户要求继续最大化列。扩展列宽仍是本机的 `Mod+Ctrl+F`，接上片段后会被浮动切换占用 |
| `Mod+H` / `Mod+L` | `focus-column-left` / `focus-column-right` | 到屏幕边缘停下，不跨显示器 |
| `Mod+J` / `Mod+K` | `focus-window-down` / `focus-window-up` | 到边缘停下，不切 workspace |
| `Mod+Shift+H` / `Mod+Shift+L` | `move-column-left` / `move-column-right` | 列只在本屏内移动 |
| `Mod+Shift+N` | DMS 记事本 | 不改成免打扰 |

跨屏三档因此是：`Mod+A/D` 只移动焦点，`Mod+Shift+A/D` 搬当前窗口，`Mod+Ctrl+Shift+A/D` 搬整个 workspace。本机已有的 `Mod+Shift+Ctrl+H/L` 仍是搬**整列**到另一块屏，片段不碰它。

### 继续让给 DMS

| 键 | DMS 动作 |
| --- | --- |
| `Mod+Space` | spotlight 启动器（列宽正向循环用 `Mod+R`） |
| `Mod+M` | 任务管理器 |
| `Mod+C` | `center-column` |
| `Mod+Ctrl+C` | `center-visible-columns` |
| `Mod+Shift+W` | 创建窗口规则 |
| `Mod+Alt+L` | DMS 锁屏 |
| `Mod+V` | DMS 剪贴板面板 |
| `XF86Audio*`、`XF86MonBrightness*` | DMS 音量 / 亮度 |
| `Ctrl+Print` / `Alt+Print` | `dms screenshot full/window` |

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
要在 DMS UI 里看真实归属，可实按验证（例：按 `Mod+Tab` —— 打开总览说明 live `binds.kdl` 赢、
切到上一个窗口说明仓库片段赢）。`Mod+Shift+N` 自 2026-10-08 起固定为 DMS 记事本，片段不再声明它。

## 回退

- 接线层：`~/.config/niri/config.kdl.backup.<时间戳>`（脚本与 `install.sh` 生成，
  保留最近 3 份）；把末尾的仓库 include/注释块删掉即可停用仓库片段。
- 键位层：删掉 `~/.config/niri/niri-repo.kdl` 里的对应 `binds` 条目，或整文件
  移走后重跑 `dms-niri-setup`（它会撤销 include）。
- 屏幕层：从 `config.kdl` 移除 `include "outputs.kdl"` 和对应注释，恢复 DMS output 配置；
  再跑 `install.sh` / `dms-niri-setup` 会重新接回仓库屏幕层。只改仓库 screen 文件也可逐项回退。
- 窗口规则：`dms config windowrules remove niri <id>`。
