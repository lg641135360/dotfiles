# Fuzzel（Wayland 应用启动器）

`fuzzel.ini` 是 niri / Wayland 会话下的启动器配置，部署到 `~/.config/fuzzel/fuzzel.ini`。

- 选中项配色与 rofi fallback 主题对齐（Catppuccin Mocha 蓝 `#89b4fa` 背景 + `#1e1e2e` 深色文字）。
- 图标主题统一为 `Papirus-Dark`，与 rofi 一致。
- niri `common.kdl` 中 `layer-rule { match namespace="^fuzzel$" }` 为启动器启用背景模糊，视觉焦点集中。
