# AwesomeWM Catppuccin Theme

Catppuccin Mocha 主题的 AwesomeWM 配置，提供现代化的圆角、阴影和配色方案。

## 配色方案

基于 [Catppuccin Mocha](https://github.com/catppuccin/catppuccin) 配色：

| 颜色 | 色值 | 用途 |
|------|------|------|
| Rosewater | #f5e0dc | 文本高亮 |
| Pink | #f5c2e7 | 强调色 |
| Mauve | #cba6f7 | 布局指示器 |
| Red | #f38ba8 | 错误/紧急 |
| Peach | #fab387 | 上传速度 |
| Yellow | #f9e2af | 警告 |
| Green | #a6e3a1 | 内存/成功 |
| Teal | #94e2d5 | 网络图标 |
| Sky | #89dceb | 辅助色 |
| Blue | #89b4fa | 主强调色/CPU |
| Lavender | #b4befe | 时钟 |
| Text | #cdd6f4 | 主文本 |
| Base | #1e1e2e | 背景 |
| Mantle | #181825 | 深色背景 |
| Crust | #11111b | 最深层背景 |

## 视觉效果

- **圆角窗口** - `theme.border_radius` 控制 managed 窗口圆角，普通/对话框窗口默认 12px；全屏或最大化时由 `client.lua` 自动退回矩形
- **阴影效果** - 柔和的窗口阴影
- **淡入淡出** - 窗口打开/关闭动画
- **无间隙** - 8px 窗口间隙 (useless gap)
- **圆角面板** - wibar 和 widget 圆角背景

## 使用方法

### 方式 1：运行安装脚本
```bash
./install.sh
```
这会自动安装 Catppuccin 主题和 picom 配置。

### 方式 2：使用 Picom 增强效果
```bash
# 使用 Catppuccin Picom 配置
picom --config ~/.config/picom/picom-catppuccin.conf
```

## 启用动画效果

如果要启用窗口模糊效果，编辑 `~/.config/picom/picom-catppuccin.conf`，取消注释 blur 部分：

```conf
blur:
{
  method = "dual_kawase";
  strength = 8;
  background = false;
  background-frame = false;
  background-fixed = false;
}
```

## 自定义

### 修改壁纸
壁纸由 Awesome autostart 中的 `feh --no-fehbg --bg-fill --randomize` 管理，不在主题文件中设置 `theme.wallpaper`。要调整壁纸候选目录，请修改 `.config/linux/awesome/autostart/*.sh` 中传给 `randomize_wallpaper` 的路径。

### 调整圆角大小
在主题文件中修改：
```lua
theme.border_radius = dpi(12)  -- 改为 0-20 之间的值
```
该值会被 `client.lua` 用作普通/对话框等 managed 窗口的 `c.shape` 半径；全屏或最大化窗口会保持矩形，避免边角露出桌面背景。

### 调整窗口间隙
在主题文件中修改：
```lua
theme.useless_gap = dpi(8)  -- 改为 0-16 之间的值
```

## 截图

Catppuccin 主题配合以下工具效果更佳：
- 终端：Alacritty / Kitty (Catppuccin 主题)
- Shell：Zsh (Powerlevel10k Catppuccin 主题)
- 编辑器：Neovim (Catppuccin 主题)
- 应用启动器：Rofi (Catppuccin 主题)

## 主题入口

当前主题入口由 `.config/linux/awesome/config.lua` 的 `theme_path = "~/.config/awesome/theme/catppuccin.lua"` 统一控制。若未来要切换主题，应先在仓库中更新 `config.lua` 和对应 README，再按 `Mod4 + Control + r` 重启 AwesomeWM。
