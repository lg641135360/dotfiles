# Alacritty 终端配置

## 文件结构

```
.config/shared/alacritty/
├── alacritty.toml        # 主配置（字体/滚动/光标）
├── keys.linux.toml       # Linux 快捷键（Alt 前缀）
├── keys.macos.toml       # macOS 快捷键（Command / Option 前缀）
├── window.linux.toml     # Linux 窗口设置（全边框装饰）
└── window.macos.toml     # macOS 窗口设置（无边框 + Option 作为 Alt）
```

安装时 `keys.toml` 和 `window.toml` 会根据 OS 自动选择对应版本。

## 窗口设置

| 特性 | Linux | macOS |
|------|-------|-------|
| 窗口装饰 | `none`（无边框，由 AwesomeWM 管理边框） | `buttonless`（无边框标题栏） |
| 背景模糊 | 是 | 是 |
| 透明度 | 70% | 70% |
| 内边距 | 12px | 12px |
| Option 作为 Alt | — | 是（Both） |

## 字体

全部使用 **MesloLGS Nerd Font Mono**：

| 样式 | 字重 |
|------|------|
| 常规 | Regular |
| 粗体 | Heavy |
| 斜体 | Medium Italic |
| 粗斜体 | Heavy Italic |

字号 12px，光标为闪烁竖线（Beam）。

## 其他功能

- **打字时隐藏鼠标** — 输入时光标自动消失，避免遮挡
- **OSC52 剪贴板** — 终端程序（nvim/tmux）可通过 OSC52 协议直接写入系统剪贴板

## 主题

使用 [alacritty-themes](https://github.com/alacritty-theme/alacritty-themes) 仓库中的 **Catppuccin Mocha** 主题，与 AwesomeWM 桌面主题保持一致：

```bash
# 安装主题仓库
git clone https://github.com/alacritty-theme/alacritty-themes.git ~/.config/alacritty/themes
```

## 快捷键

### Tmux 风格窗口切换（通过 Tmux 代理）

| 快捷键 (Linux) | 快捷键 (macOS) | 功能 |
|----------------|----------------|------|
| `Alt+h` | `Command+h` | Tmux 切换到左窗格 |
| `Alt+j` | `Command+j` | Tmux 切换到下窗格 |
| `Alt+k` | `Command+k` | Tmux 切换到上窗格 |
| `Alt+l` | `Command+l` | Tmux 切换到右窗格 |

这四个快捷键将终端窗格切换映射为 vim-style 的 hjkl 导航，避免在不同平台间切换时肌肉记忆冲突。

### Neovim 行移动 / 复制

Linux 与 macOS 下都显式为 Neovim 发送 xterm 风格方向键修饰序列；macOS 物理按键为 Option，因为 `window.macos.toml` 已设置 `option_as_alt = "Both"`。

| Neovim 快捷键 | Linux 物理按键 | macOS 物理按键 | 发送序列 | Neovim 行为 |
|---------------|----------------|----------------|----------|-------------|
| `<A-Up>` | `Alt+Up` | `Option+Up` | `ESC [ 1 ; 3 A` | 当前行或 visual 选区上移 |
| `<A-Down>` | `Alt+Down` | `Option+Down` | `ESC [ 1 ; 3 B` | 当前行或 visual 选区下移 |
| `<S-A-Up>` | `Shift+Alt+Up` | `Shift+Option+Up` | `ESC [ 1 ; 4 A` | 复制当前行或 visual 选区到上方 |
| `<S-A-Down>` | `Shift+Alt+Down` | `Shift+Option+Down` | `ESC [ 1 ; 4 B` | 复制当前行或 visual 选区到下方 |

这些绑定只补齐 Alacritty -> Neovim 的按键传递，不改变 Neovim 端的实际编辑逻辑。
