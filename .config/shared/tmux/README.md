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

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+a` | 前缀键 |
| `Ctrl+a + h/j/k/l` | 切换到左/下/上/右窗格 |
| `Ctrl+a + \|` | 水平分割窗格 |
| `Ctrl+a + -` | 垂直分割窗格 |
| `Ctrl+a + r` | 重新加载配置 |
| `Ctrl+a + [` | 进入复制/滚动模式（vim 键绑定） |
| `Ctrl+a + s` | 切换窗格同步输入 |
| `Ctrl+a + Space` | 切换窗格布局 |

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
