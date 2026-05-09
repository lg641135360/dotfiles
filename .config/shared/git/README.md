# Git Aliases

本目录包含 git 相关配置。alias 分为两部分：

1. **自定义 alias** - 在 `config` 文件中定义，oh-my-zsh git 插件未提供的功能
2. **oh-my-zsh 标准 alias** - 通过 zsh 插件加载，无需在此重复

---

## 自定义 Alias

位于 `~/.config/git/config`，需要 `git` 前缀调用：

| Alias | 命令 | 用法 | 说明 |
|-------|------|------|------|
| `subinit` | `submodule update --init --recursive` | `git subinit` | 初始化子模块 |
| `subs` | `submodule status` | `git subs` | 查看子模块状态 |
| `cs` | `commit --signoff` | `git cs` | 提交并添加 signoff |

---

## oh-my-zsh Git 插件 Alias

通过 `zinit snippet OMZP::git` 加载，直接调用（无需 `git` 前缀）：

### 核心高频

| Alias | 命令 | 说明 |
|-------|------|------|
| `g` | `git` | git 本身 |
| `ga` | `git add` | 添加文件 |
| `gaa` | `git add --all` | 添加所有 |
| `gst` | `git status` | 查看状态 |
| `gss` | `git status --short` | 简短状态 |
| `gsb` | `git status --short --branch` | 带分支的简短状态 |
| `gb` | `git branch` | 分支操作 |
| `gco` | `git checkout` | 切换分支 |
| `gcb` | `git checkout -b` | 创建并切换分支 |
| `gsw` | `git switch` | 切换分支（新命令） |
| `gswc` | `git switch --create` | 创建并切换分支 |
| `gc` | `git commit --verbose` | 提交 |
| `gca` | `git commit --verbose --all` | 提交所有更改 |
| `gcmsg` | `git commit --message` | 提交带消息 |
| `gcs` | `git commit --gpg-sign` | GPG 签名提交 |
| `gd` | `git diff` | 查看差异 |
| `gdca` | `git diff --cached` | 查看暂存区差异 |
| `gl` | `git pull` | 拉取代码 |
| `gpr` | `git pull --rebase` | 拉取并 rebase |
| `gp` | `git push` | 推送代码 |
| `gpsup` | `git push --set-upstream origin` | 推送并设置上游 |
| `grb` | `git rebase` | 变基 |
| `grbi` | `git rebase --interactive` | 交互式变基 |
| `grs` | `git restore` | 恢复文件 |
| `grst` | `git restore --staged` | 取消暂存 |

### 子模块相关

| Alias | 命令 | 说明 |
|-------|------|------|
| `gsi` | `git submodule init` | 初始化子模块 |
| `gsu` | `git submodule update` | 更新子模块 |

> 子模块状态使用自定义 `git subs`，因为当前 oh-my-zsh git 插件未提供直接的 `subs` alias。

### 其他实用 Alias

| Alias | 命令 | 说明 |
|-------|------|------|
| `grt` | `cd $(git rev-parse --show-toplevel)` | 回到 git 根目录 |
| `gbl` | `git blame -w` | 忽略空格的 blame |
| `gclean` | `git clean --interactive -d` | 交互式清理 |
| `grh` | `git reset` | 重置 |
| `grhh` | `git reset --hard` | 硬重置 |
| `gstl` | `git stash list` | 查看 stash 列表 |
| `gstp` | `git stash pop` | 弹出 stash |
| `gta` | `git tag --annotate` | 创建注解标签 |
| `glog` | `git log --oneline --graph --decorate` | 图形化日志 |

> 完整 alias 列表参考：https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh

---

## 配置说明

- **自定义 alias** 放在 `~/.config/git/config` 中
- **Git 默认编辑器** 通过 `core.editor = nvim` 固定为 Neovim，供 `git commit`、`git rebase -i` 等交互式 Git 命令使用
- **oh-my-zsh alias** 通过 `~/.config/zsh/.zshrc` 中的 `zinit snippet OMZP::git` 加载
- 优先使用 oh-my-zsh 提供的标准 alias，只在必要时添加自定义 alias
