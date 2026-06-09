# Alacritty 偏好

## 跨平台
- 当前仓库同时维护 Linux 与 macOS 的 Alacritty 配置。
- Neovim `Alt+上下` / `Shift+Alt+上下` 行移动/复制快捷键分别在 `keys.linux.toml` 与 `keys.macos.toml` 显式发送 xterm modifier 方向键序列。
- macOS 物理按键按 `option_as_alt = "Both"` 使用 Option。
- Neovim 位置历史导航 `Alt+Left`/`Alt+Right` 也在 Linux/macOS 配置中显式发送 xterm Alt 左右方向键序列。

## 字体
- 当前 Alacritty 主字体继续使用 `MesloLGS Nerd Font Mono`；Linux 当前系统可精确匹配的样式为 `Regular`、`Bold`、`Italic`、`Bold Italic`，不要再配置未安装的 `Heavy` / `Medium Italic` / `Heavy Italic`，避免 fontconfig 回退到 Regular 导致粗体/斜体显示异常。
- niri / Wayland 的终端入口也优先调用 Alacritty；否则 `Mod+Return` 可能回退到 kitty，导致 shared Alacritty 字体/主题改动看起来“没有变化”。
