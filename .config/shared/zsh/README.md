# Zsh Configuration

基于 [zap](https://github.com/zap-zsh/zap) 插件管理器的 Zsh 配置。

## 插件列表

| 插件 | 说明 |
|------|------|
| `zap-zsh/supercharge` | 增强补全、自动 cd、Ctrl+X 重载配置 |
| `zap-zsh/vim` | Vim 键位绑定 |
| `rupa/z` | 智能目录跳转 |
| `hlissner/zsh-autopair` | 自动闭合引号、括号 |
| `zsh-users/zsh-autosuggestions` | 基于历史的命令建议 |
| `zap-zsh/fzf` | Fzf 模糊搜索集成 |
| `Aloxaf/fzf-tab` | Fzf 驱动的补全菜单 |
| `wfxr/forgit` | 交互式 Git 操作 (fzf) |
| `kutsan/zsh-system-clipboard` | 系统剪贴板集成 |
| `MichaelAquilina/zsh-you-should-use` | 别名建议 |
| `zsh-users/zsh-history-substring-search` | 历史子串搜索 |
| `wintermi/zsh-brew` | Homebrew 集成 |
| `wintermi/zsh-starship` | Starship 提示符 |
| `zsh-users/zsh-syntax-highlighting` | 语法高亮 (必须最后加载) |

## 配置项

### 历史配置
- 历史文件大小：20000 条
- 多会话共享历史
- 自动去重、减少空白

### 键位绑定
- `Ctrl+P` / `Ctrl+N`: 历史子串搜索上/下

### 平台特定配置 (Linux)
- Conda 环境 (Lazy 加载)
- CUDA 路径
- Rust/Cargo 路径
- npm 全局包路径
- Homebrew 镜像 (USTC)

## 自定义扩展
- `~/.config/zsh/aliases.zsh` - 别名配置
- `~/.config/zsh/exports.zsh` - 环境变量
