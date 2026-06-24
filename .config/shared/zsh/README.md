# ZSH Configuration

模块化 ZSH 配置，基于 [zinit](https://github.com/zdharma-continuum/zinit) 插件管理器。

## 安装

```bash
chmod +x install.sh
./install.sh
```

确保 `ZDOTDIR=~/.config/zsh` 已设置（由系统或 `~/.zshenv` 定义）。

## 依赖

### 核心依赖（必装）

| 工具 | 用途 | 安装方式 |
|------|------|----------|
| [fzf](https://github.com/junegunn/fzf) | 模糊搜索 + 补全 UI | `brew install fzf` / `pacman -S fzf` |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | 智能 cd 替换 | `brew install zoxide` / `pacman -S zoxide` |
| [bat](https://github.com/sharkdp/bat) | cat 替代品（语法高亮） | `brew install bat` / `pacman -S bat` |
| [lsd](https://github.com/lsd-rs/lsd) | ls 替代品（图标+颜色） | `brew install lsd` / `pacman -S lsd` |

### 可选依赖

| 工具 | 用途 | 安装方式 |
|------|------|----------|
| [yazi](https://github.com/sxyazi/yazi) | 终端文件管理器（`y` 函数） | `brew install yazi` / `pacman -S yazi` |
| [lazygit](https://github.com/jesseduffield/lazygit) | 终端 Git TUI（`lg` 别名） | `brew install lazygit` / `pacman -S lazygit` |
| tmuxifier | tmux 会话布局 | `git clone https://github.com/jimeh/tmuxifier.git ~/.config/tmux/plugins/tmuxifier` |
| rsync | 带进度条的文件复制（`cpp` 函数） | 系统通常自带 |

## 插件

| 插件 | 功能 |
|------|------|
| [powerlevel10k](https://github.com/romkatv/powerlevel10k) | 主题提示符（运行 `p10k configure` 自定义） |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | 命令语法高亮 |
| [zsh-completions](https://github.com/zsh-users/zsh-completions) | 扩展补全 |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | 自动建议（按 → 接受） |
| [fzf-tab](https://github.com/Aloxaf/fzf-tab) | fzf 风格的补全菜单 |
| [zsh-vi-mode](https://github.com/jeffreytse/zsh-vi-mode) | Vi 模式（ESC 进入 normal 模式） |
| [zsh-autopair](https://github.com/hlissner/zsh-autopair) | 括号/引号自动配对 |
| [zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use) | 输入长命令时提醒已有别名 |

## 快捷键

### Vi 模式

由 `zsh-vi-mode` 插件提供。

| 快捷键 | 模式 | 功能 |
|--------|------|------|
| `ESC` | 任意 → normal | 进入 normal 模式 |
| `i` | normal → insert | 进入 insert 模式 |
| `v` | normal | 在编辑器中编辑当前命令行 |
| `^` / `$` | normal | 跳到行首 / 行尾 |
| `dd` | normal | 删除整行 |
| `ci"` / `ci'` / `ci(` | normal | 修改引号/括号内的内容 |
| `y` + 移动 | normal | yank（复制到剪贴板） |

### 通用

| 快捷键 | 功能 |
|--------|------|
| `↑` / `↓` | 按当前输入前缀搜索历史命令 |
| `→` | 接受自动建议 |
| `Tab` | 触发 fzf-tab 补全菜单 |
| `Ctrl+R` | fzf 历史搜索 |
| `Ctrl+S` | fzf 文件搜索（需要 `fzf --zsh` 集成） |
| `Ctrl+C` | 取消当前输入 |

### 光标样式

| 模式 | 光标 |
|------|------|
| Insert | 闪烁竖线（beam） |
| Normal | 闪烁方块（block） |
| Operator pending | 闪烁下划线 |

## PATH 管理

`path.zsh` 会在目录存在且未重复时再写入 PATH。Linux 环境会追加 `/home/linuxbrew/.linuxbrew/bin`、`$HOME/.local/opt/node-current/bin`、`$HOME/.npm-global/bin` 和 `/usr/local/nodejs/bin`，覆盖本地 Node 前缀以及常见 `npm install -g` CLI 安装位置。

## Aliases

### 通用

| 别名 | 展开 | 说明 |
|------|------|------|
| `c` | `clear` | 清屏 |
| `q` | `exit` | 退出终端 |
| `..` | `cd ..` | 上一级目录 |

### 文件操作

| 别名 | 展开 | 说明 |
|------|------|------|
| `ls` | `lsd -F --group-dirs first` | 带图标和颜色的列表 |
| `ll` | `lsd --all --header --long --group-dirs first` | 长列表（含隐藏文件） |
| `tree` | `lsd --tree` | 树形目录 |
| `cat` | `bat` | 带语法高亮的文件查看 |
| `mkdir` | `mkdir -pv` | 创建目录（含父目录，显示过程） |
| `cp` / `mv` / `rm` | `cp -iv` / `mv -iv` / `rm -iv` | 交互式操作 |

### 开发工具

| 别名 | 展开 | 说明 |
|------|------|------|
| `nv` | `nvim` | 启动 Neovim |
| `snv` | `sudo nvim` | 以 root 启动 Neovim |
| `lg` | `lazygit` | 终端 Git TUI |

### 网络

| 别名 | 展开 | 说明 |
|------|------|------|
| `iplocal` | `ip -br -c a` | 查看本地 IP |
| `ipexternal` | `curl -s ifconfig.me` | 查看公网 IP |

### 其他

| 别名 | 展开 | 说明 |
|------|------|------|
| `open` | `runfree xdg-open` | 后台打开文件/URL |
| `pdf` | `runfree evince` | 后台打开 PDF |
| `fzf` | `fzf --preview "bat ..."` | 带预览的模糊搜索 |
| `preview` | 函数：`open $(fzf ...)` | fzf 搜索并打开文件 |
| `grep` / `fgrep` / `egrep` | 加 `--color=auto` | 彩色输出 |

## Functions

| 函数 | 说明 | 示例 |
|------|------|------|
| `y` | Yazi 文件管理器（退出时同步 cd） | `y /path/to/dir` |
| `runfree` | 后台运行程序并断开终端关联 | `runfree firefox` |
| `cpp` | 带进度条的文件复制（优先 rsync） | `cpp source.tar.gz /backup/` |
| `cpg` | 复制后跳转到目标目录 | `cpg file.txt /tmp` |
| `mvg` | 移动后跳转到目标目录 | `mvg file.txt /tmp` |
| `mkdirg` | 创建目录并进入 | `mkdirg new-project` |
| `random_bars` | 打印随机高度分隔条（搭配 lolcat） | `random_bars \| lolcat` |

## 模块结构

```
.zshrc              ← 入口（17 行）
├── plugins.zsh     ← zinit + 8 个插件 + compinit
├── options.zsh     ← setopt 选项（autocd, correct 等）
├── path.zsh        ← PATH 管理（pathappend/prepend）
├── env.zsh         ← 环境变量（EDITOR, FZF_OPTS, PAGER）
├── keybindings.zsh ← 历史搜索绑定（↑↓ 键）
├── history.zsh     ← 历史配置（HISTSIZE, 去重规则）
├── aliases.zsh     ← 命令别名（条件加载）
├── functions.zsh   ← 工具函数（y, cpp, mkdirg 等）
└── integrations.zsh← 第三方工具集成（zoxide, conda, p10k）
```

## 自定义

- **主题**：运行 `p10k configure` 或通过 `~/.config/zsh/.p10k.zsh` 手动编辑
- **别名**：编辑 `~/.config/zsh/aliases.zsh`
- **函数**：编辑 `~/.config/zsh/functions.zsh`
- **插件**：编辑 `~/.config/zsh/plugins.zsh`，添加 `zinit light` 或 `zinit snippet`

## Conda 懒加载

Conda 初始化被延迟到首次调用 `conda` 命令时，避免拖慢 shell 启动速度。安装路径硬编码为 `/opt/miniforge`，如需更改请编辑 `integrations.zsh`。
