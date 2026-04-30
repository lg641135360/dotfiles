# AeroSpace

macOS 上的平铺窗口管理器配置，目标是尽量对齐 Linux AwesomeWM 的桌面肌肉记忆。

## Mod 键

当前 AeroSpace 配置使用 `alt` 作为 `Mod`，对应物理键盘上的 Option 键。

## 常用快捷键

| 快捷键 | 功能 |
|--------|------|
| `Mod+Return` | 打开 Alacritty |
| `Mod+e` | 打开 Finder |
| `Mod+q` | 关闭当前窗口 |
| `Mod+f` | 切换全屏 |
| `Mod+Ctrl+f` | 切换浮动 / 平铺 |
| `Mod+h/j/k/l` | 按方向聚焦窗口 |
| `Mod+Shift+h/j/k/l` | 按方向移动窗口 |
| `Mod+1/2/3` | 切换数字工作区 |
| `Mod+c/b/n/w` | 切换 Code / Browser / Note / WeChat 工作区 |
| `Mod+Shift+1/2/3/c/b/n/w` | 将当前窗口移到对应工作区并跟随聚焦 |
| `Mod+Tab` | 切回上一个工作区 |
| `Mod+Shift+Tab` | 将工作区移动到下一个显示器 |
| `Mod+r` | 进入 service 模式 |

## 关闭窗口语义

`Mod+q` 绑定到 AeroSpace 的 `close` 命令，语义是关闭当前聚焦窗口，接近 macOS 原生 `Cmd+w` / AwesomeWM `Mod+q` 的“关当前窗口”。它不会默认退出整个应用；如果以后希望最后一个窗口时退出应用，可单独改成 `close --quit-if-last-window`。
