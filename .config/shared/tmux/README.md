# Tmux 配置

## 依赖

- [TPM](https://github.com/tmux-plugins/tpm) — 插件管理器
  ```bash
  git clone https://github.com/tmux-plugins/tpm.git ~/.tmux/plugins/tpm
  ```

## 安装位置

- `~/.tmux.conf`

## 主题

Catppuccin Mocha，与桌面主题保持一致。

## 状态栏

- 左侧隐藏 session 名，避免 OMX / 自动生成的长 session 名挤占 tab 区域。
- 右侧显示 Prefix/Copy 状态和日期时间，不显示当前 shell 或命令名。
- 窗口列表标题显示短路径；如果当前 pane 是远程连接（SSH）或终端标题提供 `host:path`，优先显示 `远程名:路径`。
- 标题会自动截断，避免单个 tab 过长挤占其它窗口。
- 远程当前目录的准确度取决于远端 shell 是否通过终端标题或 OSC 7 上报路径；否则会退回 tmux 当前能看到的路径信息。
- 暂不引入 CPU / RAM / Battery 状态栏模块，避免为了状态栏额外增加 tmux 插件依赖。

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+a` | 前缀键 |
| `Ctrl+a + Ctrl+a` | 向嵌套 tmux / 远程 tmux 发送前缀键 |
| `Ctrl+a + w` | 打开 session / window / pane 树状选择器 |
| `Ctrl+a + Tab` | 回到上一个窗口 |
| `Ctrl+a + h/j/k/l` | 切换到左/下/上/右窗格 |
| `Ctrl+a + H/J/K/L` | 按 vim 方向调整 pane 大小 |
| `Ctrl+a + \|` | 水平分割窗格 |
| `Ctrl+a + -` | 垂直分割窗格 |
| `Ctrl+a + c` | 在当前 pane 目录中新建窗口 |
| `Ctrl+a + r` | 重新加载配置 |
| `Ctrl+a + [` | 进入复制/滚动模式（vim 键绑定） |
| `Ctrl+a + s` | 切换窗格同步输入 |
| `Ctrl+a + Space` | 切换窗格布局 |

`Ctrl+a + w` 使用 tmux 内置树状选择器快速跳转 session / window / pane，`Ctrl+a + Tab` 用于在当前窗口和上一个窗口之间快速来回切换。分屏和新窗口默认继承当前 pane 的目录，减少在项目内重复 `cd` 的操作。复制模式启用 `set-clipboard on`，优先让 tmux 复制内容同步到终端剪贴板。

## 会话管理

| 命令 | 功能 |
|------|------|
| `tmux a -t <name>` | 连接到指定会话 |
| `tmux new -s <name>` | 创建新会话 |
| `tmux ls` | 列出所有会话 |

## 插件

### 已安装

| 插件 | 功能 |
|------|------|
| `tmux-sensible` | 合理默认设置 |
| `tmux-prefix-highlight` | 前缀键激活时高亮状态栏 |
| `catppuccin/tmux` | Catppuccin Mocha 主题 |
| `tmux-resurrect` | 手动保存/恢复会话状态 |
| `tmux-continuum` | 每 15 分钟自动保存，不自动恢复（防止误删 session 恢复） |

### Resurrect 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+a + Ctrl+s` | 保存当前所有会话、窗口、窗格布局 |
| `Ctrl+a + Ctrl+r` | 恢复到上次保存的状态 |

## 插件安装

首次启动或添加插件后，按 `Ctrl+a + I` 安装插件。

## 常见问题

**自动恢复导致已删 session 反复出现？**

`@continuum-restore` 已设为 `off`，不会自动恢复。如需手动恢复上次保存的状态，按 `Ctrl+a + Ctrl+r`。

**彻底清除保存的状态：**
```bash
rm -rf ~/.local/share/tmux/resurrect/
```
