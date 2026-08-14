# Mako（Wayland 通知守护进程）

`config` 是 niri / Wayland 会话下的通知配置，部署到 `~/.config/mako/config`。

当前 Ubuntu 24.04 使用 `mako-notifier 1.8.0`，配置只使用该版本支持的选项。
通知整体通过 `border-radius` 设置圆角；不要加入 1.8.0 不支持的
`icon-border-radius`，否则 mako 会因配置解析失败而退出，导致
`org.freedesktop.Notifications` 无服务提供者。
