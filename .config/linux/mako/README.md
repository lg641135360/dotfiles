# Mako（Wayland 通知守护进程）

`config` 是 niri / Wayland 会话下的通知配置，部署到 `~/.config/mako/config`。

当前 Ubuntu 26.04 使用 `mako-notifier 1.10.0`，配置只使用该版本支持的选项
（`icon-border-radius` / `group-by` / `output` / `max-history` / `history` 等
1.10 已支持，但本配置暂不使用）。迁移自 Ubuntu 24.04 / mako 1.8 后，旧
「不得使用 1.9+ 新键」的兼容约束已失效（1.8 会因未知选项解析失败退出，导致
`org.freedesktop.Notifications` 无服务提供者）；`tests/mako_config_test.sh`
据此改为锁定「配置只使用 mako 1.10 支持的选项」。未来若升级 mako，先核对新
版本是否向后兼容当前选项，再决定是否放开。
