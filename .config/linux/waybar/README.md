# Waybar（Wayland 状态栏）

## 文件结构

```text
.config/linux/waybar/
├── config    # Waybar 布局和模块配置
└── style.css # Catppuccin Mocha 主题样式
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
- **网络**：显示实时带宽（↓↑），tooltip 含 SSID/IP/接口
- **音量**：单击静音切换，右击打开 pavucontrol，滚轮调音量（步长 5%）
- **样式**：Catppuccin Mocha 配色，模块带圆角背景和 hover 高亮效果
