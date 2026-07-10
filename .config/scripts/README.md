# 辅助脚本

## 文件清单

| 脚本 | 用途 |
|------|------|
| `lock` | X11 锁屏（i3lock-color → i3lock --blur → i3lock 纯色降级） |
| `lock-wayland` | Wayland 锁屏（swaylock） |
| `rofi-launch` | Rofi 应用启动器包装 |
| `wayland-autostart` | Wayland 会话自启动；启动前检查应用，日志按应用写入 `~/.local/state/niri/autostart/` |
| `dingtalk-wayland` | 钉钉 Wayland 屏幕共享（LD_PRELOAD hook） |
| `terminal-wayland` | Wayland 终端启动器 |
| `file-manager-wayland` | Wayland 文件管理器选择器（Dolphin → 系统默认 → 常见文件管理器） |
| `launcher-wayland` | Wayland 应用启动器 |
| `screenshot-wayland` | Wayland 截图 |
| `wallpaper-wayland` | Wayland 壁纸设置 |
