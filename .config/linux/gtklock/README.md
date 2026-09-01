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
- 双屏输入表单定位：gtklock 输入框只显示在一块屏上，而 niri 锁屏键盘焦点跟随
  指针——表单与指针不同屏时按键落空（曾必须挪鼠标到副屏才能输密码）。
  `monitor-priority=DP-1;eDP-1` 按序钉主屏（x64 命中 DP-1，aarch64 无 DP-1 落
  eDP-1，一份配置跨机器）；`follow-focus=true` 让表单跟随指针跨屏（man 注明
  "may not work for all compositors"，niri 上若表单跳动/不生效则删除该行）。
  注意 `monitor-priority` 必须用单行 `;` 列表：glib key file 同名 key 重复写
  只保留最后一条（gtklock 经 `g_key_file_get_string_list` 读取，man 页的
  "可多次指定"指命令行 `-M`）。
- 兜底：lock-wayland 保留 swaylock 分支，gtklock 缺失/异常时回退 swaylock。
