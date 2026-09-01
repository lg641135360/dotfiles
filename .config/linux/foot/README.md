# Foot 终端配置

## 定位

niri/Wayland 会话的默认终端（2026-08-31 起全平台统一，含 x86_64）。`Mod+Return` 与 fuzzel 经由 [terminal-wayland](../../scripts/terminal-wayland) 打开 foot；`alacritty` 仅在 foot 缺失时回退。

## 文件结构

```
.config/linux/foot/
├── foot.ini   # 主配置
└── README.md
```

安装时由 `install.sh` 的 `linux_wayland_dir_configs` 复制到 `~/.config/foot/`（需 `command -v foot`）。

## 设计原则

配置**镜像 `.config/shared/alacritty` 的观感**，保证 X11/Awesome 与 Wayland/niri 会话终端体验一致：

| 特性 | alacritty | foot |
|------|-----------|------|
| 字体 | MesloLGS Nerd Font Mono | 同左 |
| 字号 | 13 | 13 |
| 主题 | Catppuccin Mocha（外置 import） | Catppuccin Mocha（内嵌 palette） |
| 窗口装饰 | `decorations = "none"` | `csd.preferred = none` |
| 内边距 | 12px | 12px |
| 透明度 | 0.82 | 0.82 |
| 光标 | Beam + 闪烁 | Beam + 闪烁 |
| 打字隐藏鼠标 | `hide_when_typing = true` | `mouse.hide-when-typing = yes` |
| 滚动历史 | 50000 | 50000 |
| 滚动倍率 | 3 | 3.0 |
| TERM | `xterm-256color` | `xterm-256color` |
| OSC52 | `OnlyCopy` | 默认仅写剪贴板（等价） |

foot 配置自包含（palette 内嵌），无需像 alacritty 那样 clone 外置主题仓库。

## 快捷键

镜像 alacritty 的 `keys.linux.toml`，通过 `[text-bindings]` 发送等价的转义序列。foot 要求 modifier 用 XKB 名称（`Alt` → `Mod1`），不能用字面量 `Alt`。

| 按键 | 发送序列 | 行为 |
|------|----------|------|
| `Alt+h/j/k/l` | `Ctrl-a h/j/k/l` | tmux 窗格切换 |
| `Alt+←/→` | `ESC [1;3D/C` | Neovim 位置历史后退/前进 |
| `Alt+↑/↓` | `ESC [1;3A/B` | Neovim 当前行/选区上下移 |
| `Shift+Alt+↑/↓` | `ESC [1;4A/B` | Neovim 复制当前行/选区到上/下方 |

## 与 alacritty 的差异

- **主题内嵌**：`foot.ini` 直接写 Catppuccin Mocha palette，不依赖外置主题文件。
- **palette 区块**：foot 1.27 起 palette 放 `[colors-dark]`（默认主题，可配 `[colors-light]` 用 `SIGUSR1/2` 或 `color-theme-toggle` 切换）；旧 `[colors]` 已弃用，改用后消除 deprecation 警告。
- **cursor color**：foot 显式设置 `colors.cursor = 1e1e2e f5e0dc`（text/cursor，foot 1.25 起 `colors.cursor` 取代废弃的 `cursor.color`），与 Catppuccin Mocha 主题一致；alacritty 走主题默认反转。
- **OSC52**：foot 默认行为即仅允许写剪贴板方向，与 alacritty 的 `osc52 = "OnlyCopy"` 等价，无需显式配置。
- **窗口模糊**：alacritty 在 Linux 启用 `blur = true`；foot 1.27 `+blur` 构建已支持 `colors.blur=yes`（`ext-background-effect-v1`），但 niri 全局 window-rule 已对 foot 启用 `background-effect { blur true }`，无需重复开启；透明度仍由 `colors.alpha = 0.82` 提供（与 alacritty 在 niri 下的实际表现一致）。
- **选中/剪贴板**：`selection-target=both` 让框选同时写 PRIMARY + CLIPBOARD，配合 wl-clip-persist/cliphist 自动进入剪贴板历史；alacritty 默认仅写剪贴板（选中不自动入历史）。
- **响铃**：`[bell] urgent=yes` 后台窗口响铃时触发 niri urgent 提示（alacritty 无对应配置）。
- **URL 下划线**：foot 1.27 起默认改为点线（`dotted`），`[url] style=single` 改回实线以保持旧观感（对齐 alacritty 的 URL 下划线）。
- **透明度应用范围**：`alpha-mode=all` 让整窗均匀半透明（foot 默认只对"默认背景"单元格应用 alpha，彩色背景单元格会不透明），与 alacritty 的 `opacity` 行为一致；代价是彩色高亮区域也变透。
- **滚动指示**：`indicator-format=percentage` 滚动时显示位置百分比，配合 50000 行历史便于定位长输出。
- **选词边界**：`word-delimiters` 在默认基础上追加常用代码字符（`./=+-*%$@!?~^`），双击按标识符整选更贴合代码。

## 启动方式：普通冷启动

[terminal-wayland](../../scripts/terminal-wayland) 直接 `exec foot "$@"` 冷启动（默认），不依赖常驻实例或远程控制；`alacritty` 仅在 foot 缺失时回退。
