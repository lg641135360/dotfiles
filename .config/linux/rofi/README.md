# Rofi 配置

这套 Rofi 配置用于 AwesomeWM 的 `Mod+c` 应用启动器，目标是保持和桌面主线一致的 **Catppuccin Mocha** 深色浮层观感。

## 文件结构

```text
.config/linux/rofi/
├── config.rasi  # 行为配置：模式、中文标签、排序和图标
└── theme.rasi   # 主题配置：Catppuccin Mocha 配色、尺寸、字体和布局
```

实际启动入口是 `~/.config/scripts/rofi-launch`，Awesome 会通过该脚本启动 Rofi。

## 主题策略

- `config.rasi` 只保留行为配置，并通过 `@theme "theme.rasi"` 引用主题。
- `theme.rasi` 使用 Catppuccin Mocha palette：`base` / `mantle` / `surface0` / `surface1` / `blue` / `lavender` / `text`。
- 尺寸继续使用 rofi 1.7.1 兼容的 `px`，不要直接切回实数 `em` 距离。
- `rofi-launch` 会读取 `Xft.dpi`，按 `Xft.dpi / 96` 生成 `~/.cache/rofi/theme.scaled.rasi`，并同时缩放字体和 px 距离。
- 中文输入与显示优先保留 `Noto Sans CJK SC`，启动脚本会注入 `zh_CN.UTF-8` 与 fcitx 环境变量。

## 当前视觉基线

- 主窗口：Mocha `base` 半透明背景，蓝色边框。
- 输入框 / message：Mocha `mantle` 背景。
- 选中项：Mocha `blue` 背景 + 深色文字。
- active 未选中项：Mocha `surface0` 背景 + `lavender` 文字。
