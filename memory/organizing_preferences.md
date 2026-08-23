# Organizing Preferences

> 通用/跨模块偏好与环境经验。本文件不定义通用硬约束；通用强制规则以 `AGENTS.md` 为准。模块特定偏好请参见对应分类文件：
> `awesome.md` / `nvim.md` / `tmux.md` / `rofi.md` / `alacritty.md` / `desktop.md` / `niri.md` / `waybar.md` / `git.md` / `codex.md` / `dingtalk.md` / `foot.md` / `herdr.md`

## 通用工作流
- 当用户要求把当前桌面配置改动提交到 GitHub 时，通常优先先复跑轻量回归测试，并确认仓库文件与 live `~/.config` 已同步，再执行提交和推送。
- 对 `install.sh` 里的 `redshift` 处理，通常保留缺失检查即可；缺失时只提示用户手动安装，不要在安装脚本里自动执行提权安装。
- 安装器在检测到 Zsh 时，应确保 `~/.zshenv` 包含且只包含一条 `export ZDOTDIR=$HOME/.config/zsh`，使模块化 Zsh 配置可被默认加载。

## 系统环境
- 在 Ubuntu aarch64 上，X11-sensitive 桌面工具通常优先使用系统二进制（尤其是 `redshift`）。
- 主力 AI 编辑器为 Trae CN（aarch64 + niri/Wayland）。已知问题：Trae CN 升级（如 2026-08-10）会丢失内置 ripgrep 二进制的可执行权限（变为 `-rw-r--r--`），导致 IDE 的 Grep 工具在任意路径（含单文件）均报「权限不够 (os error 13)」；rg 由每次搜索临时 spawn，修复后无需重启 Trae。修复：`sudo chmod 755 /usr/share/trae-cn/resources/app/node_modules/@vscode/ripgrep/bin/rg /usr/share/trae-cn/resources/app/node_modules/@byted-fe/ripgrep-linux-arm64/bin/rg`。Trae 升级后 Grep 失效时优先怀疑此问题。
- 当 Linuxbrew 包遮蔽工作系统二进制且不需要时，通常优先删除包，而不是加防御逻辑。
- Window manager helper 脚本（`~/.config/scripts/*`）通常保持始终安装并保留可执行位，即使 runtime backend 未安装。
- 对通过本地 Node current 前缀安装的全局 npm CLI，在共享 zsh PATH 中追加 `$HOME/.local/opt/node-current/bin`。
- 对通过 `npm install -g` 安装到 `/usr/local/nodejs` 前缀的 CLI，在共享 zsh PATH 中追加 `/usr/local/nodejs/bin`。
- 对通过 `npm install -g` 安装到用户级 `/home/rikoo/.npm-global` 前缀的 CLI，在共享 zsh PATH 中追加 `$HOME/.npm-global/bin`。
- 跨系统包管理策略：macOS 统一用 Homebrew（Brewfile 一键安装全部依赖）；Linux 分层——GUI/桌面环境（awesome/niri/waybar/mako/fuzzel 等）/系统服务（pipewire/wireplumber/xdg-desktop-portal/polkit）/输入法（fcitx5）/构建库（libportal-dev 等）/字体（fonts-noto-cjk）用系统原生包管理器（apt/pacman/dnf），纯用户级 CLI 工具（neovim/tmux/alacritty/fzf/zoxide/bat/lsd/ripgrep/fd/yazi）用 Homebrew。Linux Brewfile 只收录纯 CLI 工具，不收录 GUI/X11 工具。

## 仓库管理
- `.omx/` 属于本地 OMX 运行状态目录；按当前仓库惯例，通常放入 `.gitignore`，不进入远端仓库。
- Codex CLI 配置基线与版本特化经验见 `memory/codex.md`。
