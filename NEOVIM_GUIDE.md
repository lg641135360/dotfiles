# Neovim 快速上手指南 (VS Code 用户版)

这份指南是为你当前高度定制的 Neovim 配置量身打造的。它将帮助你利用肌肉记忆的映射，快速从 VS Code 过渡到 Neovim。

## 🧠 核心概念转变

| 概念 | VS Code | Neovim |
| :--- | :--- | :--- |
| **光标移动** | 鼠标 / 方向键 | `h` (左) `j` (下) `k` (上) `l` (右) |
| **编辑模式** | 始终处于编辑状态 | **Normal 模式** (默认，用于移动/浏览) <br> **Insert 模式** (按 `i` 进入，用于打字) <br> **Visual 模式** (按 `v` 进入，用于选择) |
| **命令面板** | `Ctrl+Shift+P` | `:` (进入命令行模式) |
| **快捷键前缀** | `Ctrl` / `Alt` | **`<leader>` 键** (你的配置中是 **空格键 `Space`**) |

---

## ⚡️ VS Code 功能映射表

这是你最常用的功能在当前配置中的对应快捷键：

| 功能 | VS Code 快捷键 | Neovim 快捷键 (当前配置) | 对应插件 |
| :--- | :--- | :--- | :--- |
| **文件查找** | `Ctrl+P` | **`<Space>ff`** (Find Files) | Snacks.picker |
| **全局搜索** | `Ctrl+Shift+F` | **`<Space>fg`** (Find Grep) | Snacks.picker |
| **文件资源管理器** | `Ctrl+Shift+E` | **`<Space>e`** (Explorer) | Neo-tree |
| **最近打开的文件** | `Ctrl+R` | **`<Space>fr`** (Find Recent) | Snacks.picker |
| **已打开的编辑器** | *Tab 列表* | **`<Space>fb`** (Find Buffers) | Snacks.picker |
| **终端** | `Ctrl+` ` | **`<Space>ft`** (Float Term) | custom |
| **保存文件** | `Ctrl+S` | **`<Space>w`** | keymaps.lua |
| **关闭文件** | `Ctrl+W` | **`<Space>c`** (Close Buffer) | keymaps.lua |
| **退出编辑器** | - | **`<Space>q`** (Quit) | keymaps.lua |

---

## 🧭 代码导航与智能感应 (LSP)

你的配置集成了强大的 LSP 功能，体验接近甚至超越 VS Code。

| 功能 | VS Code | Neovim | 说明 |
| :--- | :--- | :--- | :--- |
| **跳转定义** | `F12` | **`gd`** | Go to Definition |
| **查看引用** | `Shift+F12` | **`gr`** | Goto References (弹窗列表) |
| **查看实现** | `Ctrl+F12` | **`gI`** | Goto Implementation |
| **悬停提示** | *鼠标悬停* | **`K`** | 在光标处按大写 K (Kernel) |
| **重命名符号** | `F2` | **`<Space>rn`** | Rename |
| **代码修复** | `Ctrl+.` | **`<Space>ca`** | Code Action |
| **大纲视图** | *Outline 面板* | **`<Space>o`** | Aerial (大纲插件) |
| **诊断问题** | *波浪线* | **`<Space>xx`** | Trouble (问题面板) |

---

## 🪟 窗口与标签页管理

Neovim 的 "Buffer" 类似于 VS Code 的 "Tab"，而 "Window" 是分屏。

### 分屏操作
*   **向左移动焦点**: `<Space><Left>`
*   **向下移动焦点**: `<Space><Down>`
*   **向上移动焦点**: `<Space><Up>`
*   **向右移动焦点**: `<Space><Right>`

### 标签页 (Buffer) 操作
*   **下一个标签**: `<Space><PageDown>`
*   **上一个标签**: `<Space><PageUp>`
*   **跳转到标签 1-9**: `<Space>1` 到 `<Space>9`
*   **关闭当前标签**: `<Space>c`

---

## 📝 编辑技巧 (生存必备)

这些是 Vim 的原生操作，是效率的核心：

*   **撤销**: `u` (Undo)
*   **重做**: `Ctrl+r` (Redo)
*   **复制 (Yank)**:
    *   `yy` (复制整行)
    *   `yw` (复制一个单词)
    *   **`<Ctrl>c`**: 你配置了在 Visual 模式下复制到系统剪贴板
*   **粘贴**: `p` (Paste)
    *   **`<Ctrl>v`**: 你配置了直接粘贴系统剪贴板内容
*   **删除 (Cut)**:
    *   `dd` (删除/剪切整行)
    *   `dw` (删除/剪切一个单词)
    *   `x` (删除当前字符)
*   **选择**:
    *   `v` (字符选择)
    *   `V` (行选择)
    *   **`<Ctrl>a`**: 全选 (你的自定义配置)
    *   **`vv`**: 智能选择当前区域 (你的自定义配置)

---

## 🚀 进阶功能 (你的特色配置)

1.  **Git 集成**:
    *   查看 Git 状态: `<Space>gs`
    *   查看 Git 差异: `<Space>gd` (注意这里 `gd` 在 Normal 模式是跳转定义，`<Space>gd` 是 Git Diff)

2.  **Inlay Hints (内嵌提示)**:
    *   切换参数类型提示: `<Space>th`

3.  **快捷键辅助**:
    *   如果你忘记了 `<Space>` 后面能接什么，**按下空格键并等待一秒**，屏幕底部会弹出一个菜单 (WhichKey)，告诉你所有可用的后续按键。这是最好的老师！

---

## 💡 遇到困难怎么办？

1.  **不知道某个键是干嘛的？**
    *   运行 `:verbose map <快捷键>` 查看定义来源。
2.  **插件出问题了？**
    *   运行 `:checkhealth` 查看诊断信息。
    *   运行 `:Lazy` 管理插件更新。
