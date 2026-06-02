# Rofi 偏好

> 当前环境: Ubuntu aarch64 / rofi 1.7.1

## 架构
- `config.rasi` 只保留行为配置并显式引用 `theme.rasi`。
- 输入框相关布局保持显式 `children`；中文环境下为 `entry`/`element-text`/`textbox` 指定可显示 CJK 的字体。
- Awesome 拉起 rofi 时显式传递 `LC_CTYPE` 与 fcitx 环境变量。

## 缩放策略演进
1. **初始方案**：使用 `em` 相对单位让窗口宽度/间距/圆角/图标尺寸跟随字体度量；`Xft.dpi` 控制字体缩放时不额外硬编码 DPI。
2. **当前方案（Ubuntu aarch64）**：rofi theme 的 `em` 实数距离值不可靠 → 回退到 `px` 距离，`config.rasi` 固定 `dpi: 1`。
3. **运行时缩放方案**：`config.rasi` 不再固定 `dpi: 1`；Awesome 通过 `~/.config/scripts/rofi-launch` 启动 rofi，脚本中注入 locale/fcitx 环境、按 `Xft.dpi / 96` 生成缩放后的 `~/.cache/rofi/theme.scaled.rasi` 再 `-theme` 拉起。
4. **字体缩放**：字体必须和 px 距离按同一倍率缩放；只放大 width/padding/spacing/icon size 而不放大字体会让观感失衡。

## 字体
- 基础/中文字体 `11.5`，提示粗体 `12`。

## 紧凑化
- 优先压列表图标和局部 spacing/padding，降低 window 模式文案噪音；不先动窗口宽度。
- 下一层细调从 `message`/`textbox` 等辅助区域的 padding 下手，不减可见行数或继续压窗口外框。

## 文案
- Launcher 统一用中文短标签（"应用 / 窗口 / 命令"）。
- Window 模式优先保留 `窗口名 + class` 的简版信息，不把 title 一起塞回去。

## 配色
- 使用 Catppuccin Mocha palette，与 Awesome/Tmux/Alacritty 主线保持一致。
- 不再混用 OneDark 风格色板（`#61afef`、`#21252b`、`#282c34` 等）。

## 已知限制
- 在 `LANG/LC_ALL/LC_CTYPE=zh_CN.UTF-8` 与 fcitx 环境下仍无法输入中文时，视为当前 rofi 版本能力边界。
