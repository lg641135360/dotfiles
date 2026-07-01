# Waybar（Wayland 状态栏）

## 文件结构

```text
.config/linux/waybar/
├── config     # Waybar 布局和模块配置
├── mocha.css  # Catppuccin Mocha GTK CSS 颜色变量
└── style.css  # 一体化顶栏样式
```

部署到 `~/.config/waybar/`。

## 模块布局

```
左: [工作区 │ 窗口标题]
中: [时钟]
右: [网络 CPU 内存 音量 系统托盘]
```

## 当前配置要点

- **工作区**：使用图标（聚焦/活动/紧急/空），无数字编号，适配 niri 动态工作区
- **窗口标题**：保留当前输出的 niri 窗口标题，并清理常见 VS Code / Chrome / Alacritty 标题
- **网络**：图标化显示实时带宽（↓↑），tooltip 含 SSID/IP/接口
- **音量**：图标化显示音量；单击静音切换，右击打开 pavucontrol，滚轮调音量（步长 5%）
- **样式**：`style.css` 顶部导入 `mocha.css`，使用 Catppuccin Mocha 颜色变量；整条 Waybar 作为连续半透明顶栏，内部模块只保留弱分隔和 hover 层级
