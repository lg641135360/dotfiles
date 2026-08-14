# desktop-entries/

覆盖系统 `/usr/share/applications/` 中的 desktop entry，目的是让 fuzzel 的 `filter-desktop=yes`（drun 模式）启动应用时走本仓库的 Wayland 包装脚本，而不是直接执行系统二进制。

## 为什么需要覆盖

- Chrome 不会自动检测 Wayland 会话，直接执行 `google-chrome-stable` 会回退到 X11 后端，在 niri 下报 `Missing X server or $DISPLAY`。
- `browser-wayland` 包装脚本在 Wayland 会话中追加 `--ozone-platform=wayland --enable-wayland-ime`，在 X11 会话中原样透传参数，因此同一份 desktop entry 在 Awesome 和 niri 会话下都安全。
- Trae CN 同理：`trae-cn-wayland` 强制 Wayland 后端并启用 fcitx5 IME。

## `__HOME__` 占位符

desktop entry 中的 `Exec` 路径使用 `__HOME__` 占位符，由 `install.sh` 在部署时替换为真实的 `$HOME`。这样 entry 可跨机器/用户移植，无需硬编码绝对路径。

## 部署

`install.sh` 的 `linux_wayland_configs` 数组收录这些 entry，部署目标为 `~/.local/share/applications/`。fuzzel / GNOME Shell 等会优先读取用户级 `~/.local/share/applications/`，覆盖系统级同名 entry。

## 收录

- `google-chrome.desktop` — 走 `browser-wayland`
- `trae-cn.desktop` — 走 `trae-cn-wayland`
