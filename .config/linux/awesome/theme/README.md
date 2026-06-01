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
- **圆角浮层** - 整条 wibar、tooltip/menu、fallback titlebar 等浮层使用圆角；状态栏单项默认保持扁平透明，不单独绘制 widget 背景胶囊
- **回退标题栏** - 仅显式 class 白名单中的少数配置类工具窗会显示紧凑 fallback titlebar；默认普通窗口仍无 titlebar，普通 `utility` 和通用 role 都不会自动启用。fallback titlebar 使用单独的 `titlebar_bg_*` / `titlebar_fg_*` / `titlebar_radius` / `titlebar_size` 配色与尺寸变量，并通过 `titlebar_button_*` token 把右侧按钮改成更轻的文字胶囊控件，而不是默认 PNG 图标

## 使用方法

### 方式 1：运行安装脚本
```bash
./install.sh
```
这会自动安装 Catppuccin 主题和 picom 配置。

### 方式 2：使用 Picom 增强效果
```bash
# 使用 install.sh 部署后的平台 Picom 配置
picom --config ~/.config/picom.conf
```

## 启用动画效果

Picom 配置由 `.config/linux/picom/` 维护，并由 `install.sh` 按平台部署到 `~/.config/picom.conf`。当前 Ubuntu x64 配置已启用 `dual_kawase` blur；如需调整模糊强度，请修改对应平台的 `picom-*.conf` 后重新安装或同步。

```conf
blur-method = "dual_kawase"
blur-strength = 12
blur-background = true
blur-background-frame = true
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
