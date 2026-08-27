# Fuzzel（Wayland 应用启动器）

`fuzzel.ini` 是 niri / Wayland 会话下的启动器配置，部署到 `~/.config/fuzzel/fuzzel.ini`。

- 选中项配色与 rofi fallback 主题对齐（Catppuccin Mocha 蓝 `#89b4fa` 背景 + `#1e1e2e` 深色文字）。
- 图标主题统一为 `Papirus-Dark`，与 rofi 一致。
- `icons-enabled=no`：fuzzel 1.9.2 打开时扫描图标主题（Papirus 图标量大）可能偶发卡顿、输入无响应、ESC 无效；关掉图标加载缓解该卡顿，代价是列表不显示应用图标。若日后升级 fuzzel 到 1.11+ 或确认卡顿消除，可改回 `yes`。
- niri `common.kdl` 中 `layer-rule { match namespace="^fuzzel$" }` 为启动器启用背景模糊，视觉焦点集中。
