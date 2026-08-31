# Swaylock（Wayland 锁屏）

`config` 是 niri / Wayland 会话下的锁屏解锁环配色，部署到 `~/.config/swaylock/config`。

- swaylock 1.8（apt 主线版）自 2026-08-29 起替代 Nix 的 swaylock-effects。主线版
  支持配置文件（`long-option=value` 格式）与完整解锁环配色（ring/inside/line/
  key-hl/bs-hl 及其 ver/wrong 变体），但不支持 `--effect-blur` 背景模糊
  （swaylock-effects fork 功能）。
- 配色使用 Catppuccin Mocha：解锁环默认 `#89b4fa`（blue，与 niri focus-ring 对齐）、
  验证中 `#a6e3a1`（green）、密码错误 `#f38ba8`（red）、按键高亮 `#f9e2af`（yellow）。
- 壁纸/纯色兜底仍由 `~/.config/scripts/lock-wayland` 命令行控制（`-i`/`-s fill`/
  `-c 11111b`），本配置文件只负责解锁环视觉，不与命令行 background 逻辑重复。
- 解锁环尺寸 `indicator-radius=80` / `indicator-thickness=8`，字体 `Maple Mono NF CN`
  与 waybar/mako 观感对齐。
