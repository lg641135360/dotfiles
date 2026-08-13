# Kitty 终端配置

## 定位

在 aarch64（MediaTek M1000）的 niri 会话中使用。原 alacritty 0.18.0-dev 在 GPU 缩放输出（内屏 2x）下字形渲染损坏（文字丢失），而 kitty / foot 正常。kitty 作为首选终端接入 [terminal-wayland](../scripts/terminal-wayland)。

## 文件结构

```
.config/linux/kitty/
├── kitty.conf   # 主配置
└── README.md
```

安装时由 `install.sh` 的 `linux_wayland_dir_configs` 复制到 `~/.config/kitty/`（需 `command -v kitty`）。

## 设计原则

配置**镜像 `.config/shared/alacritty` 的观感**，保证 X11/Awesome 与 Wayland/niri 会话终端体验一致：

| 特性 | alacritty | kitty |
|------|-----------|-------|
| 字体 | MesloLGS Nerd Font Mono | 同左 |
| 字号 | 13 | 13 |
| 主题 | Catppuccin Mocha（外置 import） | Catppuccin Mocha（内嵌 palette） |
| 窗口装饰 | `none` | `hide_window_decorations yes` |
| 内边距 | 12px | 12px |
| 透明度 | 0.82 | 1.0（见下方「与 alacritty 的差异」） |
| 光标 | Beam + 闪烁 | Beam + 闪烁 |
| 打字隐藏鼠标 | `hide_when_typing = true` | `mouse_hide_wait -3` |
| 滚动历史 | 50000 | 50000 |

kitty 配置自包含（palette 内嵌），无需像 alacritty 那样 clone 外置主题仓库。

## 快捷键

镜像 alacritty 的 `keys.linux.toml`，通过 `send_text` 发送等价的转义序列：

| 按键 | 行为 |
|------|------|
| `Alt+h/j/k/l` | 发送 `Ctrl-a h/j/k/l`（tmux 窗格切换） |
| `Alt+←/→/↑/↓` | 发送 `ESC [1;3D/C/A/B`（Neovim 位置历史 / 行移动） |
| `Shift+Alt+↑/↓` | 发送 `ESC [1;4A/B`（Neovim 复制当前行/选区） |

## 与 alacritty 的差异

- **无 `TERM` 覆盖**：保留 kitty 默认 `TERM=kitty`（启用 kitty 键盘协议与图形能力），不照搬 alacritty 的 `xterm-256color`。
- **主题内嵌**：`kitty.conf` 直接写 Catppuccin Mocha palette，不依赖外置主题文件。
- **背景不透明（`background_opacity 1.0`）**：aarch64 mtgpu 驱动对半透明窗口的 alpha 合成有 bug，会把 kitty 的 0.82 半透明背景错误渲染成"全透明、看不清字体"；故 kitty 改为完全不透明，透明观感只在 X11/Awesome 会话由 alacritty 保留。

alacritty 可映射的体验项均已对齐：`scrolling.multiplier=3` → `wheel_scroll_multiplier 3.0`，`terminal.osc52="OnlyCopy"` → `clipboard_control write-clipboard write-primary`，`hide_when_typing=true` → `mouse_hide_wait -3`（kitty 0.32.2 默认 `0.0` 不隐藏，需显式设为 `-3`）。窗口级 `blur` 为 kitty 平台能力缺失，无法对齐。

## 社区常用项

- **多窗口布局**：`enabled_layouts tall,splits,stack`（kitty 此选项为逗号分隔），在 kitty 默认 `tall` 之外启用 `splits`/`stack`，`Ctrl+Shift+Enter` 可在当前窗口旁新开窗口。镜像 alacritty 的单窗口观感不受影响。
- **滚动分页**：`scrollback_pager less --clear-screen -R`，用 less 分页回看历史（`Ctrl+Shift+H` 打开、`Ctrl+Shift+G` 关闭），取代内置分页器。
- 其余未显式配置的项保持 kitty 默认（如 `kitty_mod=Ctrl+Shift`、`scrollback_lines` 以上均按需覆盖）。

## 启动方式：普通冷启动

[terminal-wayland](../scripts/terminal-wayland) 在 aarch64 分支直接用 `exec kitty "$@"` 冷启动，`kitty.conf` 未开启 `allow_remote_control`，[wayland-autostart](../scripts/wayland-autostart) 也不预启动常驻实例。

历史上曾尝试**常驻单实例 + 控制端快速开窗**（`allow_remote_control socket-only`、wayland-autostart 预启动 daemon、`kitty @ launch --type=os-window`）把开窗从约 1.5s 压到 0.08s，但代价是：登录多开一个常驻窗口、残留 socket 导致 bind 失败、daemon 崩溃需自愈兜底，维护成本大于提速收益，已于 2026-08-13 整体移除。

当前取舍：保留普通冷启动的简单与可靠，牺牲少量开窗速度。若后续 zsh 已成为瓶颈，可再评估是否重引入常驻方案。
