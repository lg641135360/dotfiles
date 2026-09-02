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
- Trae CN 终端 shell 集成会注入 `safe_rm_aliases.sh`（cp/mv 变为 shell 函数并渗入子 bash），使 `command -v cp` 返回裸名而非路径；依赖 `command -v` 解析真实二进制的测试沙箱会因此造出自引用死链（`tests/lib/sandbox.sh` 的 `link_cmd` 已于 2026-08-29 加 PATH 回退防护）。另：IDE 沙箱会拦截删除解析目标在 allowlist 外的 symlink（如 coreutils-rs 的 `uname → /usr/lib/cargo/...`），`install_macos_test.sh` 在 Trae 终端内因此无法完整运行，属环境限制而非仓库问题。
- 当 Linuxbrew 包遮蔽工作系统二进制且不需要时，通常优先删除包，而不是加防御逻辑。
- Window manager helper 脚本（`~/.config/scripts/*`）通常保持始终安装并保留可执行位，即使 runtime backend 未安装。
- 对通过本地 Node current 前缀安装的全局 npm CLI，在共享 zsh PATH 中追加 `$HOME/.local/opt/node-current/bin`。
- 对通过 `npm install -g` 安装到 `/usr/local/nodejs` 前缀的 CLI，在共享 zsh PATH 中追加 `/usr/local/nodejs/bin`。
- claude-code 不走 brew（2026-09-02 决策）：其原生二进制源 `downloads.claude.ai` 在国内被阻断，brew cask 无法升级；改用 `npm i -g @anthropic-ai/claude-code` 全局安装（官方 registry 或 npmmirror 均可达，npm 包内 `bin/claude.exe` 实为原生二进制，非纯 Node 脚本），升级用 `npm update -g @anthropic-ai/claude-code`。注意 linuxbrew bin 在共享 zsh PATH 中位于 `/usr/local/nodejs/bin` 之前，若两者并存会遮蔽 npm 版——故 brew cask 版与 npm 版二选一，勿共存。
- 对通过 `npm install -g` 安装到用户级 `/home/rikoo/.npm-global` 前缀的 CLI，在共享 zsh PATH 中追加 `$HOME/.npm-global/bin`。
- 跨系统包管理策略：macOS 统一用 Homebrew（Brewfile 一键安装全部依赖）；Linux 分层——GUI/桌面环境（awesome/niri/waybar/mako/fuzzel 等）/系统服务（pipewire/wireplumber/xdg-desktop-portal/polkit）/输入法（fcitx5）/构建库（libportal-dev 等）/字体（fonts-noto-cjk）用系统原生包管理器（apt/pacman/dnf），纯用户级 CLI 工具（neovim/tmux/alacritty/fzf/zoxide/bat/lsd/ripgrep/fd/yazi）用 Homebrew。Linux Brewfile 只收录纯 CLI 工具，不收录 GUI/X11 工具。
- brew vs 系统包管理器落地准则：Linux 上 brew 只装纯用户级 CLI，其余交系统包管理器。判定顺序——① 读写 GPU/亮度/色温/锁屏/音量/输入法等系统资源 → 系统装；② 依赖 `*-dev` 库或需链接系统库 → 系统装；③ 合成器 / WM / 状态栏 / 通知守护等会话居民 → 系统装；④ 纯 CLI、零系统依赖、用户空间可跑 → brew；⑤ 会被登录会话 / systemd / PAM 引用 → 系统装。当前 openSUSE WSL2 落地：brew 装 neovim / ripgrep / fd / fzf / bat / yazi / zoxide（即 Linux Brewfile 覆盖的纯 CLI 子集）；zypper 装 gcc gcc-c++ make file / tmux / jq；herdr 走官方脚本 `curl -fsSL https://herdr.dev/install.sh | sh`（用自带 `herdr update` 升级、不进 Brewfile）；node / claude 按需（node 走 brew 或 npm 前缀）。tmux 属纯 CLI 本可 brew，但建议系统装（libevent/ncurses 与系统一致、避免遮蔽），二选一勿重复；alacritty 在 openSUSE 由 DMS 管理，Linux 不走 brew、install.sh 也跳过部署。

## 仓库管理
- `.omx/` 属于本地 OMX 运行状态目录；按当前仓库惯例，通常放入 `.gitignore`，不进入远端仓库。
- Codex CLI 配置基线与版本特化经验见 `memory/codex.md`。
