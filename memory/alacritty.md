# Alacritty 偏好

## 跨平台
- 当前仓库同时维护 Linux 与 macOS 的 Alacritty 配置。
- Alacritty 的 `TERM` 统一使用兼容性更广的 `xterm-256color`，避免 SSH 远程端缺少 `alacritty` terminfo，或 Ubuntu 默认 Bash 不识别 `TERM=alacritty` 而关闭彩色提示符。
- Neovim `Alt+上下` / `Shift+Alt+上下` 行移动/复制快捷键分别在 `keys.linux.toml` 与 `keys.macos.toml` 显式发送 xterm modifier 方向键序列。
- macOS 物理按键按 `option_as_alt = "Both"` 使用 Option。
- Neovim 位置历史导航 `Alt+Left`/`Alt+Right` 也在 Linux/macOS 配置中显式发送 xterm Alt 左右方向键序列。

## 字体
- 主字体统一 `Maple Mono NF CN`（2026-10-06 决策，替换 MesloLGS，与 waybar/mako/swaylock 等桌面组件一致）；Fedora 机已用 `fc-match` 验证 `Regular` / `Bold` / `Italic` / `Bold Italic` 四样式逐一命中 `MapleMono-NF-CN-*.ttf`。不要再配置未安装的 `Heavy` / `Medium Italic` / `Heavy Italic`，避免 fontconfig 回退到错误样式。注意 `alacritty.toml` 是跨平台 shared 配置：macOS 黑苹果当前只装了 MesloLGS，需另装 Maple Mono NF CN（或后续拆平台字体文件），否则会回退默认等宽字体。
- niri / Wayland 的终端入口在非 aarch64 平台优先调用 Alacritty；aarch64 + Wayland 因 mtgpu 字形问题改为优先 foot。否则 `Mod+Return` 可能回退到 foot，导致 shared Alacritty 字体/主题改动看起来“没有变化”。
