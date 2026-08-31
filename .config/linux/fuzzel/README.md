# Fuzzel（Wayland 应用启动器）

`fuzzel.ini` 是 niri / Wayland 会话下的启动器配置，部署到 `~/.config/fuzzel/fuzzel.ini`。

- 选中项配色与 rofi fallback 主题对齐（Catppuccin Mocha 蓝 `#89b4fa` 背景 + `#1e1e2e` 深色文字）。
- 图标主题统一为 `Papirus-Dark`，与 rofi 一致。
- `icons-enabled=yes`（2026-08-31 恢复）：此前因 fuzzel 1.9.2（Ubuntu Noble）打开时扫描图标主题（Papirus 图标量大）偶发卡顿而关闭；live 已升级到 fuzzel 1.12.0（Ubuntu 26.04 apt），卡顿前提消除后恢复应用图标。若在 1.12.0 上实测仍复现打开卡顿/输入无响应/ESC 无效，可临时改回 `no` 并在本处注释原因。
- niri `common.kdl` 中 `layer-rule { match namespace="^fuzzel$" }` 为启动器启用背景模糊，视觉焦点集中。
