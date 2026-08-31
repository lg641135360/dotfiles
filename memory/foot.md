# Foot 偏好

## 定位
- foot 是 niri/Wayland 会话的默认终端（2026-08-31 起全平台统一，含 x86_64）：
  - 历史：aarch64 曾因 mtgpu 下 alacritty 0.18.0-dev 在缩放输出内屏 2x 字形损坏、foot 渲染正常而优先 foot；现全平台统一 foot 优先，aarch64 行为不变
  - `alacritty` 仅在 foot 缺失时由 `terminal-wayland` 回退冷启动（`exec alacritty "$@"`）
- `terminal-wayland` 顺序：foot 优先 → alacritty 兜底；已移除 aarch64+Wayland 专用分支与 `uname -m` / `WAYLAND_DISPLAY` 特判
- 不再维护 kitty 配置；原 `.config/linux/kitty/` 已移除，`terminal-wayland` 的兜底分支由 kitty 改为 foot，再于 2026-08-31 将默认终端由 alacritty 改为 foot
- foot 是 Wayland-only 终端（无 X11 / macOS 版本），配置仅放 `.config/linux/foot/`，由 `install.sh` 的 `linux_wayland_dir_configs` 在 `command -v foot` 通过时复制到 `~/.config/foot/`

## 观感对齐
- foot.ini 镜像 `.config/shared/alacritty` 的观感：MesloLGS Nerd Font Mono 13、Catppuccin Mocha 内嵌 palette、`csd.preferred=none`、`pad=12x12`、`colors.alpha=0.82`、`cursor.style=beam` + `blink=yes`、`mouse.hide-when-typing=yes`、`scrollback.lines=50000`、`scrollback.multiplier=3.0`、`term=xterm-256color`。
- `[text-bindings]` 镜像 alacritty 的 `keys.linux.toml`：`Alt+hjkl` 发送 `Ctrl-a hjkl`（tmux 窗格切换），`Alt+方向键` / `Shift+Alt+上下` 发送 xterm 修饰序列供 Neovim 使用。foot 要求 modifier 用 XKB 名称，`Alt` 必须写成 `Mod1`（不能用字面量 `Alt`）。

## 与 alacritty 的差异
- **主题内嵌**：`foot.ini` 直接写 Catppuccin Mocha palette，不依赖外置主题文件（alacritty 需要 clone `alacritty-theme`）。
- **cursor color**：foot 显式 `colors.cursor = 1e1e2e f5e0dc`（text/cursor，foot 1.25 起 `colors.cursor` 取代废弃的 `cursor.color`）以对齐 Catppuccin Mocha；alacritty 走主题默认反转。
- **OSC52**：foot 默认仅允许写剪贴板方向，与 alacritty 的 `terminal.osc52 = "OnlyCopy"` 等价，无需显式配置。
- **窗口模糊**：alacritty 在 Linux 启用 `blur = true`；foot 无对应能力，透明度由 `colors.alpha = 0.82` 提供，模糊交给 niri 全局 `background-effect { blur true }`（与 alacritty 在 niri 下的实际表现一致）。

## 透明度取舍
- foot 的 `colors.alpha` 直接采用 0.82，与 alacritty Linux 一致；不再沿用 kitty 之前因 aarch64 mtgpu alpha 合成 bug 而走的 1.0 不透明路径。若后续在 aarch64 内屏 2x 下复现 mtgpu 半透明渲染 bug，再单独评估是否在该硬件上降回不透明。
