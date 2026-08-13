# ZSH Configuration

模块化 ZSH 配置，基于 [zinit](https://github.com/zdharma-continuum/zinit) 插件管理器。

## 安装

```bash
chmod +x install.sh
./install.sh
```

安装器会在检测到 Zsh 时向 `~/.zshenv` 写入 `export ZDOTDIR=$HOME/.config/zsh`；已有相同行时跳过，不会重复追加。

## 依赖

### 核心依赖（必装）

| 工具 | 用途 | 安装方式 |
|------|------|----------|
| [fzf](https://github.com/junegunn/fzf) | 模糊搜索 + 补全 UI | `brew install fzf` / `pacman -S fzf` |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | 智能 cd 替换 | `brew install zoxide` / `pacman -S zoxide` |
| [bat](https://github.com/sharkdp/bat) | cat 替代品（语法高亮） | `brew install bat` / `pacman -S bat` |
| [lsd](https://github.com/lsd-rs/lsd) | ls 替代品（图标+颜色） | `brew install lsd` / `pacman -S lsd` |
| [starship](https://starship.rs) | 提示符（替代 p10k） | `cargo install starship` |

### 可选依赖

| 工具 | 用途 | 安装方式 |
|------|------|----------|
| [yazi](https://github.com/sxyazi/yazi) | 终端文件管理器（`y` 函数） | `brew install yazi` / `pacman -S yazi` |
| tmuxifier | tmux 会话布局 | `git clone https://github.com/jimeh/tmuxifier.git ~/.config/tmux/plugins/tmuxifier` |
| rsync | 带进度条的文件复制（`cpp` 函数） | 系统通常自带 |

## 插件

| 插件 | 功能 |
|------|------|
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | 命令语法高亮 |
| [zsh-completions](https://github.com/zsh-users/zsh-completions) | 扩展补全 |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | 自动建议（按 → 接受） |
| [fzf-tab](https://github.com/Aloxaf/fzf-tab) | fzf 风格的补全菜单 |
| [zsh-vi-mode](https://github.com/jeffreytse/zsh-vi-mode) | Vi 模式（ESC 进入 normal 模式） |
| [zsh-autopair](https://github.com/hlissner/zsh-autopair) | 括号/引号自动配对（延迟加载） |
| [zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use) | 输入长命令时提醒已有别名（延迟加载） |

> 提示符由 [starship](https://starship.rs) 提供（单一 Rust 二进制，配置见 `~/.config/starship.toml`）。早期用 powerlevel10k，但 aarch64 平台 gitstatus 二进制版本不匹配导致初始化失败，拖慢提示符渲染，故弃用。

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

`path.zsh` 会在目录存在且未重复时再写入 PATH。Linux 环境会**追加**（`pathappend`，不遮蔽系统二进制）`/home/linuxbrew/.linuxbrew/bin`、`/home/linuxbrew/.linuxbrew/sbin`、`$HOME/.local/opt/node-current/bin`、`$HOME/.npm-global/bin` 和 `/usr/local/nodejs/bin`，覆盖 Homebrew CLI 工具与 sbin 工具、本地 Node 前缀以及常见 `npm install -g` CLI 安装位置。

> 注：故意用 `pathappend` 而非 `pathprepend`，让系统 `/usr/bin` 的 `python3`/`git`/`curl`/`openssl` 等优先于 brew 版本，符合"Linuxbrew 仅作纯用户级 CLI 工具补充、不遮蔽工作系统二进制"的策略。brew doctor 关于此的 PATH 顺序警告属于可接受的误报。

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
| `cpp` | 带进度条的文件复制（优先 rsync，无 rsync 时 `cp -v`） | `cpp source.tar.gz /backup/` |
| `cpg` | 复制后跳转到目标目录 | `cpg file.txt /tmp` |
| `mvg` | 移动后跳转到目标目录 | `mvg file.txt /tmp` |
| `mkdirg` | 创建目录并进入 | `mkdirg new-project` |
| `random_bars` | 打印随机高度分隔条（搭配 lolcat） | `random_bars \| lolcat` |

## 模块结构

```
.zshenv             ← 系统级设置（skip_global_compinit=1，见下）
.zshrc              ← 入口（17 行）
├── plugins.zsh     ← zinit + 8 个插件 + compinit
├── options.zsh     ← setopt 选项（autocd, correct 等）
├── path.zsh        ← PATH 管理（pathappend/prepend）
├── env.zsh         ← 环境变量（EDITOR, FZF_OPTS, PAGER）
├── keybindings.zsh ← 历史搜索绑定（↑↓ 键）
├── history.zsh     ← 历史配置（HISTSIZE, 去重规则）
├── aliases.zsh     ← 命令别名（条件加载）
├── functions.zsh   ← 工具函数（y, cpp, mkdirg 等）
└── integrations.zsh← 第三方工具集成（zoxide, conda, starship）
```

## 启动提速：跳过全局 compinit

`.zshenv` 中的 `skip_global_compinit=1` 用于跳过 Ubuntu 系统级 `/etc/zsh/zshrc` 里的 `compinit`（该开关是 `/etc/zsh/zshrc` 官方注释指定的退出机制）。

原因：全局 `compinit` 会先用默认 fpath 跑一次，随后 [plugins.zsh](.config/shared/zsh/plugins.zsh) 加载 zinit 改变 fpath 后又跑一次，导致每次启动都全量重建完成缓存（实测约 3.4s 惩罚）。跳过全局那次、只保留 `plugins.zsh` 里 fpath 就绪后的 `compinit`，可使交互式启动从 ~4.7s 降到 ~0.35s。

## 启动提速：compinit 跳过 compaudit + 插件延迟加载

[plugins.zsh](.config/shared/zsh/plugins.zsh) 进一步两项优化，将启动从 ~0.35s 降到 ~0.2s：

1. **`compinit -u` 跳过 compaudit**：compinit 默认跑 compaudit 检查 fpath 目录权限，实测占 ~0.15s（0.20s → 0.05s）。单用户桌面环境下 fpath 目录均由 zinit 管理（用户自己控制），权限检查无实际安全价值。
2. **zsh-autopair / zsh-you-should-use 延迟加载**：这两个插件合计占 plugins.zsh 约 73% 耗时（autopair ~0.22s, you-should-use ~0.12s），但功能仅在按键时才需要。用 `zinit ice wait lucid` 延迟到首次提示符后异步加载，不阻塞首次提示符渲染。

延迟加载的权衡：autopair 的括号配对、you-should-use 的别名提醒在首次提示符后约 50ms 才激活，极少数场景下首次按键可能未触发配对。实际无感知。

## 启动提速：弃用 p10k 改用 starship

早期用 powerlevel10k，但在 aarch64 平台 gitstatus 二进制版本不匹配（cache 中 2022 年的 v1.5.4 与 p10k 期望版本不一致），导致每次启动报 `gitstatus failed to initialize` 并回退到同步 git 调用，严重拖慢提示符渲染。

改用 [starship](https://starship.rs)（单一 Rust 二进制，无 gitstatus 版本依赖问题）后：
- 提示符渲染从「p10k 失败回退同步 git」的数百毫秒降到 starship 的几毫秒
- 配置更简洁（starship.toml ~80 行 vs .p10k.zsh ~2000 行）
- 跨平台一致（macOS/Linux 共用 `.config/shared/starship.toml`）

starship 通过 `integrations.zsh` 的 `eval "$(starship init zsh)"` 接入，配置部署由 `install.sh` 的 `shared_configs` 完成。

## 自定义

- **提示符**：编辑 `~/.config/starship.toml`（仓库对应 `.config/shared/starship.toml`），参考 [starship 文档](https://starship.rs/config/)
- **别名**：编辑 `~/.config/zsh/aliases.zsh`
- **函数**：编辑 `~/.config/zsh/functions.zsh`
- **插件**：编辑 `~/.config/zsh/plugins.zsh`，添加 `zinit light` 或 `zinit snippet`

## Conda 懒加载

Conda 初始化被延迟到首次调用 `conda` 命令时，避免拖慢 shell 启动速度。安装路径硬编码为 `/opt/miniforge`，如需更改请编辑 `integrations.zsh`。
