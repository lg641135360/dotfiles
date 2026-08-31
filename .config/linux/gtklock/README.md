# Gtklock（Wayland 锁屏，时钟/日期）

`config.ini` + `style.css` 是 niri / Wayland 会话下的锁屏配置，部署到
`~/.config/gtklock/`。

- 背景：gtklock 4.0 基于 `ext-session-lock-v1`，niri 26.04 支持该协议（二进制含
  `ext_session_lock_manager_v1`）。Ubuntu apt 包自带 `/etc/pam.d/gtklock`，装包即用，
  无需手动写 PAM。
- 时钟/日期：`config.ini` 的 `time-format`/`date-format`（date(1) 语法）。
- 主题：`style.css`（GTK CSS，Catppuccin Mocha）。目标 widget 为 gtklock 默认 UI
  （`#clock-label`/`#input-field`/`#warning-label`/`#error-label`/`#unlock-button`）。
- 背景壁纸由 `~/.config/scripts/lock-wayland` 以 `--background` 命令行传入当前壁纸；
  `style` 路径也由 lock-wayland 以 `--style` 传绝对路径，避免相对路径歧义。
- 兜底：lock-wayland 保留 swaylock 分支，gtklock 缺失/异常时回退 swaylock。
