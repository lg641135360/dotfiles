# Foot 终端配置

## 定位

在 niri 等 Wayland 会话中作为 Alacritty 的兜底终端。当 `alacritty` 不可用时，由 [terminal-wayland](../../scripts/terminal-wayland) 自动调用 `exec foot "$@"`。

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
- **cursor color**：foot 显式设置 `cursor.color = 1e1e2e f5e0dc`（text/cursor），与 Catppuccin Mocha 主题一致；alacritty 走主题默认反转。
- **OSC52**：foot 默认行为即仅允许写剪贴板方向，与 alacritty 的 `osc52 = "OnlyCopy"` 等价，无需显式配置。
- **窗口模糊**：alacritty 在 Linux 启用 `blur = true`；foot 无对应能力，透明度由 `colors.alpha = 0.82` 提供，模糊由 niri 全局 `background-effect { blur true }` 负责（与 alacritty 在 niri 下的实际表现一致）。

## 启动方式：普通冷启动

[terminal-wayland](../../scripts/terminal-wayland) 在 alacritty 不可用时 `exec foot "$@"` 冷启动，不依赖常驻实例或远程控制。
