# Alacritty 偏好

## 跨平台
- 当前仓库同时维护 Linux 与 macOS 的 Alacritty 配置。
- Neovim `Alt+上下` / `Shift+Alt+上下` 行移动/复制快捷键分别在 `keys.linux.toml` 与 `keys.macos.toml` 显式发送 xterm modifier 方向键序列。
- macOS 物理按键按 `option_as_alt = "Both"` 使用 Option。
- Neovim 位置历史导航 `Alt+Left`/`Alt+Right` 也在 Linux/macOS 配置中显式发送 xterm Alt 左右方向键序列。
