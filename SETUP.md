# SETUP — 全新机器依赖安装指引

本指南面向技术和非技术人员，目标是在一台干净机器上把本仓库（`dotfiles`）所需的所有软件依赖安装配置到位。文档按"环境准备 → 分平台安装 → 验证 → 常见问题"组织，命令均可直接复制执行。

> 仓库本体安装方式见根目录 [README.md](README.md)。本文件只覆盖**外部依赖**。

---

## 1. 环境准备要求

### 1.1 操作系统兼容性

| 平台 | 状态 | 说明 |
|------|------|------|
| Ubuntu 24.04+ (x86_64) | ✅ 主力 | **首选 niri (Wayland)**；AwesomeWM (X11) 进入维护模式，仅作回退 |
| Ubuntu 24.04+ (aarch64 / ARM64) | ✅ 主力 | **X11 + AwesomeWM 仍为主要图形显示服务器**，需确保 X11 配置与依赖完整可用 |
| Arch Linux (x86_64) | ✅ 主力 | **首选 niri (Wayland)**；AwesomeWM (X11) 进入维护模式，仅作回退 |
| macOS 13+ (Apple Silicon) | ✅ 主力 | AeroSpace + Alacritty + Homebrew 工具链 |
| 其它 Linux 发行版 | ⚠️ 社区支持 | 安装脚本可运行，但 autostart 平台分发不会命中，需手动补齐 |
| Windows | ❌ 不支持 | 仓库不提供 Windows 配置 |

> **桌面环境策略（按架构区分）**：
> - **x86_64**：niri + Wayland 为首选与积极演进方向；AwesomeWM + X11 进入维护模式，仅作回退。
> - **aarch64**：X11 + AwesomeWM 仍为主要图形显示服务器，相关配置（Xresources / xsessionrc / autostart 屏幕布局）需保持完整可用；niri + Wayland 在该架构暂不作为首选。
> - **macOS**：AeroSpace + Alacritty。

> 安装脚本通过 `uname -s` / `uname -m` / `/etc/os-release` 自动识别平台，无需手动指定。

### 1.2 aarch64 默认显示配置

Ubuntu aarch64 架构系统上，X11 为主要图形显示服务器，默认采用双屏幕布局，**主屏位于左侧**。相关参数由 `install.sh` 按平台自动部署（Xresources、xsessionrc.d/cursor、autostart 屏幕布局脚本），无需手动配置。

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| 主屏（内屏） | `2880x1800@120Hz` | 笔记本内屏，位于左侧，设为 primary |
| 外接屏 | 右侧扩展 | 位于主屏右侧，由 autostart 的 `apply_display_layout` 固定布局 |
| 显示缩放 (scale) | `Xft.dpi: 192`（即 2x） | 部署自 [xresources/ubuntu_aarch64](.config/linux/x11/xresources/ubuntu_aarch64)，影响终端/GTK 字体与 Awesome `dpi()` 尺寸 |
| 光标大小 | `XCURSOR_SIZE=48` | 部署自 [xsessionrc.d/cursor.2x](.config/linux/x11/xsessionrc.d/cursor.2x)，适配 2x HiDPI，避免 Electron 应用光标过小 |
| 触摸板 | 自然滚动 / 点击轻触 / 加速度 0.5 / 打字时禁用 | autostart 通过 `xinput` 自动应用 |
| 输入法环境 | `GTK_IM_MODULE=fcitx` / `QT_IM_MODULE=fcitx` / `XMODIFIERS=@im=fcitx` 等 | 部署自 [xsessionrc](.config/linux/x11/xsessionrc)，见 [x11 README](.config/linux/x11/README.md) |
| X 主题 | One Dark 调色板 | 部署自 `xresources/ubuntu_aarch64` |

> x86_64 平台（`ubuntu_x64` / `arch_x64`）的默认 DPI 与 scale 不同：`ubuntu_x64` 为 `Xft.dpi: 124`（约 1.25x，`XCURSOR_SIZE=32`），`arch_x64` 为 `Xft.dpi: 192`（2x，`XCURSOR_SIZE=48`）。niri/Wayland 下对应 `scale 1.25`（ubuntu_x64）与 `scale 2`（arch_x64）。详见 [x11 README](.config/linux/x11/README.md) 与 [niri README](.config/linux/niri/README.md)。

### 1.3 网络与镜像

- 需要能访问 GitHub（克隆 zinit、TPM、collision、alacritty-themes 等子模块/插件）。
- 中国大陆网络环境下，zsh 配置已默认注入 USTC Homebrew 镜像（见 [.config/shared/zsh/env.zsh](.config/shared/zsh/env.zsh)）；如自行更换镜像，请同步修改该文件。
- Neovim 插件首次启动会从 GitHub 拉取，建议预留稳定网络。

### 1.4 必备基础工具

以下工具是 `install.sh` 的硬性依赖，缺失会直接退出：

```
find cp mv diff date dirname basename sort grep tail
```

几乎所有 POSIX 系统均自带。macOS 用户建议先安装 Command Line Tools：

```bash
xcode-select --install
```

---

## 2. 依赖总览

依赖按"核心运行时 / 平台桌面环境 / 开发工具链 / 可选增强"四类组织。✅=必装，⚠️=可选。

### 2.1 跨平台核心（Linux + macOS 共用）

| 工具 | 用途 | Linux | macOS |
|------|------|-------|-------|
| `git` | 仓库克隆、子模块、插件管理 | ✅ | ✅ |
| `zsh` | 默认 shell | ✅ | ✅（系统自带，建议 brew 版） |
| `tmux` | 终端复用 | ✅ | ✅ |
| `alacritty` | 主终端 | ✅ | ✅ |
| `neovim` ≥ 0.12 | 编辑器 | ✅ | ✅ |
| `fzf` | 模糊搜索 / 补全 | ✅ | ✅ |
| `zoxide` | 智能 cd | ✅ | ✅ |
| `bat` | cat 替代 / man pager | ✅ | ✅ |
| `lsd` | ls 替代（图标+颜色） | ✅ | ✅ |
| `ripgrep` | 项目内 grep | ✅ | ✅ |
| `fd` | 文件查找 | ✅ | ✅ |
| `yazi` | 终端文件管理器 | ⚠️ | ⚠️ |
| `rsync` | `cpp` 函数进度条复制 | ⚠️ | ⚠️ |
| `jq` | Claude Code statusline 配置 | ⚠️ | ⚠️ |
| `claude` (Claude Code CLI) | statusline 自动配置 | ⚠️ | ⚠️ |
| Nerd Font (MesloLGS) | Alacritty / p10k 图标 | ✅ | ✅ |

> `zinit` 插件管理器、`TPM` (tmux plugin manager)、AwesomeWM `collision`、`alacritty-themes` 由 `install.sh` 在首次运行时自动 clone，无需手动安装。

> **Claude Code / Codex 安装方式**：优先使用 **npm** 安装（`npm install -g @anthropic-ai/claude-code` / `npm install -g @openai/codex`）。原因：通过 Homebrew 安装此类工具时通常需要从 GitHub 拉取资源，国内网络环境下若未配置代理（🪜）易导致下载缓慢或安装失败；npm 走 npm registry（可配国内镜像），更稳定。安装后 zsh PATH 已覆盖 `/usr/local/nodejs/bin`、`$HOME/.npm-global/bin`、`$HOME/.local/opt/node-current/bin` 等 npm 全局前缀（见 [path.zsh](.config/shared/zsh/path.zsh)）。

> **zsh 增强插件安装方式**：`zsh-completions` / `zsh-autosuggestions` / `zsh-syntax-highlighting` 三个插件推荐统一通过 **zinit 插件管理器**从官方仓库安装，**不建议**额外用 brew / apt 单独装。原因：[plugins.zsh](.config/shared/zsh/plugins.zsh) 已通过 `zinit light zsh-users/zsh-syntax-highlighting` / `zsh-users/zsh-completions` / `zsh-users/zsh-autosuggestions` 从各自官方仓库加载，跨 Linux / macOS 一致；额外用系统包管理器安装同款插件会导致重复加载或补全冲突。具体来源：

| 插件 | 推荐来源 | 安装方式 |
|------|----------|----------|
| `zsh-completions` | [zsh-users/zsh-completions](https://github.com/zsh-users/zsh-completions)（官方仓库） | zinit 自动 clone，无需手动 |
| `zsh-autosuggestions` | [zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)（官方仓库） | zinit 自动 clone，无需手动 |
| `zsh-syntax-highlighting` | [zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)（官方仓库） | zinit 自动 clone，无需手动 |

> macOS `Brewfile` 已移除上述三个 zsh 插件的 brew 版，统一由 zinit 加载，避免重复加载与补全冲突。

#### zinit 加载的完整插件清单

[plugins.zsh](.config/shared/zsh/plugins.zsh) 通过 zinit 加载以下插件，首次启动 zsh 时自动从 GitHub clone，无需手动安装：

| 插件 | 来源 | 用途 |
|------|------|------|
| `powerlevel10k` | [romkatv/powerlevel10k](https://github.com/romkatv/powerlevel10k) | 主题提示符（运行 `p10k configure` 自定义） |
| `zsh-syntax-highlighting` | [zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | 命令语法高亮 |
| `zsh-completions` | [zsh-users/zsh-completions](https://github.com/zsh-users/zsh-completions) | 扩展补全 |
| `zsh-autosuggestions` | [zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | 自动建议（按 → 接受） |
| `fzf-tab` | [Aloxaf/fzf-tab](https://github.com/Aloxaf/fzf-tab) | fzf 风格的补全菜单 |
| `zsh-vi-mode` | [jeffreytse/zsh-vi-mode](https://github.com/jeffreytse/zsh-vi-mode) | Vi 模式（ESC 进入 normal） |
| `zsh-autopair` | [hlissner/zsh-autopair](https://github.com/hlissner/zsh-autopair) | 括号/引号自动配对 |
| `zsh-you-should-use` | [MichaelAquilina/zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use) | 输入长命令时提醒已有别名 |

此外通过 `zinit snippet OMZP::*` 加载 Oh-My-Zsh 的 `git` / `sudo` / `docker` / `command-not-found` 片段。

#### 其他 zsh 配置要点

| 项目 | 说明 |
|------|------|
| `ZDOTDIR` | 需设置 `ZDOTDIR=~/.config/zsh`（由系统或 `~/.zshenv` 定义），zsh 才能从 `~/.config/zsh` 而非 `~` 加载模块化配置 |
| `tmuxifier`（可选） | tmux 会话布局管理，git clone 安装：`git clone https://github.com/jimeh/tmuxifier.git ~/.config/tmux/plugins/tmuxifier`；[path.zsh](.config/shared/zsh/path.zsh) 与 [integrations.zsh](.config/shared/zsh/integrations.zsh) 已预留集成 |
| `fzf --zsh` 集成 | [env.zsh](.config/shared/zsh/env.zsh) 通过 `source <(fzf --zsh)` 启用 fzf 的 Ctrl+R 历史搜索与 Ctrl+S 文件搜索，需要较新版本 fzf |
| Conda | 安装路径硬编码为 `/opt/miniforge`（[integrations.zsh](.config/shared/zsh/integrations.zsh)），懒加载至首次调用 `conda` 时初始化；如改路径需同步编辑该文件 |
| Homebrew 镜像 | [env.zsh](.config/shared/zsh/env.zsh) 默认注入 USTC 镜像（`HOMEBREW_BREW_GIT_REMOTE` / `HOMEBREW_BOTTLE_DOMAIN` / `HOMEBREW_API_DOMAIN`） |
| 环境变量 | `EDITOR`/`VISUAL`/`SUDO_EDITOR`/`FCEDIT`=`nvim`，`TERMINAL`=`alacritty`；`bat` 存在时设为 `MANPAGER`/`PAGER` |

> 完整别名、函数、快捷键与模块结构见 [.config/shared/zsh/README.md](.config/shared/zsh/README.md)。

### 2.2 Linux X11 桌面（AwesomeWM）

> **按架构区分**：
> - **aarch64**：X11 + AwesomeWM 为主要图形显示服务器，本节依赖为**必装**。
> - **x86_64**：X11 + AwesomeWM 进入维护模式，仅作回退；本节依赖仅在需要回退到 AwesomeWM 时安装，新机器部署 niri + Wayland 可跳过（见 [2.3](#23-linux-wayland-桌面niri)）。

| 工具 | 用途 | 必装？ |
|------|------|--------|
| `awesome` | 窗口管理器 | ✅ |
| `picom` | 合成器（圆角/阴影/模糊） | ✅ |
| `rofi` | 应用启动器 | ✅ |
| `feh` | 壁纸 | ✅ |
| `xautolock` | 空闲自动锁屏 | ⚠️ |
| `i3lock-color` 或 `i3lock`（支持 `--blur`） | 主题化锁屏 | ✅（缺失会降级纯色） |
| `xrandr` / `xinput` (`xorg-xrandr` / `xorg-xinput`) | 分辨率/触摸板 | ✅（笔记本） |
| `xrdb` (`xorg-xrdb`) | Xresources 合并 | ⚠️ |
| `xdpyinfo` (`xorg-xdpyinfo`) | 锁屏画布尺寸探测 | ⚠️ |
| `redshift` | 自动色温 | ⚠️（Ubuntu：`sudo apt install redshift`） |
| `fcitx5` + `fcitx5-chinese-addons` | 中文输入法 | ✅ |
| `nm-applet` | 网络托盘 | ⚠️ |
| `blueman-applet` | 蓝牙托盘 | ⚠️ |
| `pasystray` | 音量托盘 | ⚠️ |
| `pavucontrol` | 音量混音器（VOL 右键） | ⚠️ |
| `udiskie` | USB 自动挂载 | ⚠️ |
| `maim` | 截图 OCR | ⚠️（用 `Mod+s` 时需要） |
| `curl` | OCR HTTP 调用 | ⚠️ |
| `dolphin` | 文件管理器（`Mod+e`） | ⚠️ |
| `greenclip` | 剪贴板历史（x64） | ⚠️ |
| `flameshot` | 截图（aarch64） | ⚠️ |
| `Snipaste` (AppImage) | 截图标注（x64） | ⚠️ |
| `python3` | 锁屏 PNG 生成 / rofi 主题缩放 | ✅ |
| `notify-send` (`libnotify`) | 桌面通知 | ⚠️ |
| `brightnessctl` | 亮度滚轮调节（aarch64） | ⚠️ |
| `pot` | Pot OCR 翻译服务 | ⚠️ |

### 2.3 Linux Wayland 桌面（niri）

| 工具 | 用途 | 必装？ |
|------|------|--------|
| `niri` ≥ 26.04 | 滚动平铺合成器 | ✅ |
| `waybar` | 状态栏（需含 niri 模块） | ✅ |
| `mako` | 通知守护 | ✅ |
| `fuzzel` | 应用启动器（首选） | ✅ |
| `swaybg` | 壁纸 | ✅ |
| `swayidle` | 空闲锁屏触发 | ✅ |
| `swaylock` | Wayland 锁屏 | ✅ |
| `gammastep` | 自动色温（Wayland 主线） | ⚠️（缺失回退 `wlsunset`） |
| `wl-clipboard` (`wl-copy`) | 剪贴板 | ✅（截图复制） |
| `grim` | 截图 | ✅（`F1` 截图标注） |
| `slurp` | 区域选择 | ✅（`F1` 截图标注） |
| `satty` | 截图标注 | ✅（`F1` 截图标注） |
| `brightnessctl` | 亮度 | ⚠️ |
| `playerctl` | 媒体键 | ⚠️ |
| `pavucontrol` | 音量混音器 | ⚠️ |
| `xwayland-satellite` | X11 应用兼容（niri 26.04 自动拉起） | ⚠️ |
| `xdg-desktop-portal` + `-gtk` + `-gnome` | 文件选择/截图/屏幕共享 | ✅ |
| `gnome-keyring` | Secret portal | ⚠️ |
| `policykit-1-gnome` 或 `polkit-kde-authentication-agent-1` | polkit agent | ⚠️ |
| `pipewire` + `wireplumber` | 音频/屏幕共享 | ✅（钉钉 Wayland 共享必需） |
| `Noto Sans CJK SC` | Satty 中文标注字体 | ✅ |
| `nm-applet` / `pasystray` / `blueman-applet` / `udiskie` | 托盘辅助 | ⚠️ |
| `rofi`（Wayland 版） | launcher fallback | ⚠️ |
| `kitty` | terminal fallback | ⚠️ |

#### 钉钉 Wayland 屏幕共享 hook（可选）

仅在 niri/Wayland 下需要钉钉会议共享屏幕时构建：

| 依赖 | 用途 |
|------|------|
| `cmake` ≥ 3.16 | 构建 |
| `ninja-build` | 构建后端 |
| `libportal-dev` | PipeWire portal |
| `libpipewire-0.3-dev` | PipeWire |
| `libopencv-dev` | 帧处理 |
| `libx11-dev` / `libxrandr-dev` / `libxext-dev` / `libxdamage-dev` | X11 抓屏接口 |

### 2.4 macOS 桌面

| 工具 | 用途 | 必装？ |
|------|------|--------|
| `aerospace` | 平铺窗口管理器 | ✅ |
| `borders` (`felixkratz/formulae/borders`) | 焦点边框 | ⚠️ |
| `homebrew` | 包管理器 | ✅ |
| `zsh-completions` / `zsh-autosuggestions` / `zsh-syntax-highlighting` | zsh 增强 | ⚠️ |

### 2.5 开发工具链（按语言需要）

| 语言 | 工具 | 用途 |
|------|------|------|
| Lua | `stylua` | 格式化（nvim `conform.nvim`） |
| Python | `black`, `isort` | 格式化 |
| JS/TS/JSONC/HTML/CSS | `prettier` | 格式化 |
| JSON | `jq` | 格式化 |
| Shell | `shfmt` | 格式化 |
| C/C++ | `clang-format`, `clangd` | 格式化 + LSP |
| TeX | `tex-fmt` | 格式化 |
| Lua (LSP) | `lua-language-server` (`lua_ls`) | nvim LSP |
| Python (LSP) | `pyright` | nvim LSP |
| TS/JS (LSP) | `typescript-language-server` (`ts_ls`) | nvim LSP |
| Rust | `cargo` (rustup) | `satty` 等cargo 安装项 |
| Node | Node.js ≥ 20 | `tsx` / `typescript`（见 [scripts/package.json](scripts/package.json)） |
| Conda | Miniforge (`/opt/miniforge`) | Python 环境（懒加载） |

> `clangd` 入口约定：优先在 `~/.local/bin/clangd` 建软链指向具体版本，不要把机器路径写进共享配置。详见 [.config/shared/nvim/README.md](.config/shared/nvim/README.md)。

### 2.6 测试与文档脚本

| 工具 | 用途 |
|------|------|
| `bash` / `sh` | 运行 [tests/run.sh](tests/run.sh) |
| `luajit` | nvim / awesome Lua 语法检查 |
| `git` | 测试脚本依赖 git 命令 |
| Node.js + `npx tsx` | 归档 [logs/trace.md](logs/trace.md)（见 [scripts/archive_trace.ts](scripts/archive_trace.ts)） |

---

## 3. 分步安装流程

> **跨系统包管理策略**
>
> - **macOS**：统一使用 Homebrew，`brew bundle --file .config/macos/Brewfile` 一键安装全部依赖（CLI 工具 + GUI cask）。
> - **Linux**：采用分层策略，区分两类软件包——
>   - **系统原生包管理器（apt / pacman / dnf）**：安装桌面环境（awesome / niri / waybar / mako / fuzzel 等）、系统服务（pipewire / wireplumber / xdg-desktop-portal / polkit / gnome-keyring）、输入法（fcitx5）、构建依赖（libportal-dev / libpipewire-dev / libopencv-dev 等）与字体（fonts-noto-cjk）。这些组件需要系统集成、会话管理或 PAM 认证，**不适合**通过 Homebrew 安装。
>   - **Homebrew**：安装用户级 CLI 工具（neovim / tmux / alacritty / fzf / zoxide / bat / lsd / ripgrep / fd / yazi）。Homebrew 版本更新、跨发行版一致，且不污染系统包管理器。[Linux Brewfile](.config/linux/Brewfile) 已只包含这些纯 CLI 工具。
>
> 简言之：**Linux 上 GUI/桌面/系统/库走 apt（或 pacman），纯 CLI 工具走 brew**；macOS 全部走 brew。

### 3.1 通用前置（所有平台）

```bash
# 1. 克隆仓库（含子模块）
git clone --recurse-submodules https://github.com/<your-fork>/dotfiles.git ~/Documents/dotfiles
cd ~/Documents/dotfiles

# 若已克隆但未带子模块：
git submodule update --init --recursive

# 2. 赋予安装脚本可执行权限
chmod +x install.sh
```

### 3.2 Ubuntu / Debian（x86_64 与 aarch64）

#### 3.2.1 系统包

```bash
sudo apt update

# 基础工具（系统自带，确保存在；brew 自身依赖 git）
sudo apt install -y git zsh python3 python3-pip curl

# X11 / AwesomeWM 桌面
# - aarch64：X11 为主要图形显示服务器，必装
# - x86_64：维护模式，仅回退 AwesomeWM 时才需要
sudo apt install -y \
  awesome picom rofi feh xautolock i3lock \
  x11-xserver-utils \
  redshift \
  fcitx5 fcitx5-chinese-addons \
  network-manager-gnome blueman pasystray pavucontrol \
  udiskie maim libnotify-bin brightnessctl dolphin

# Wayland / niri 桌面（首选；niri 本身需通过 Nix 或源码安装，见 3.2.3）
sudo apt install -y \
  waybar mako fuzzel swaybg swayidle swaylock \
  wl-clipboard grim slurp brightnessctl playerctl pavucontrol \
  xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome \
  gnome-keyring policykit-1-gnome \
  pipewire wireplumber \
  libportal-dev libpipewire-0.3-dev libopencv-dev \
  libx11-dev libxrandr-dev libxext-dev libxdamage-dev cmake ninja-build \
  gammastep fonts-noto-cjk
```

> Ubuntu 下 `xrandr` / `xinput` / `xrdb` / `xdpyinfo` 均包含在 `x11-xserver-utils` 包中；请按报错信息调整。CLI 工具（neovim / tmux / alacritty / fzf / zoxide / bat / lsd / ripgrep / fd / yazi）改由 Homebrew 安装，见 [3.2.4](#324-homebrewcli-工具推荐)。

#### 3.2.2 Satty（截图标注）

```bash
# 若 Ubuntu 仓库没有 satty
cargo install satty
```

#### 3.2.3 niri（Wayland 合成器）

Ubuntu 24.04 apt 没有 niri，建议用 Nix：

```bash
# 安装 Nix（多用户）
sh <(curl -L https://nixos.org/nix/install) --daemon

# 通过 nix profile 安装 niri 与配套 Wayland 工具
nix profile install github:YaLTeR/niri
nix profile install nixpkgs#waybar nixpkgs#fuzzel nixpkgs#mako \
  nixpkgs#swayidle nixpkgs#swaylock nixpkgs#wl-clipboard \
  nixpkgs#grim nixpkgs#slurp nixpkgs#brightnessctl nixpkgs#playerctl \
  nixpkgs#xwayland-satellite
```

> 仓库的 Waybar 配置使用 `niri/workspaces` 与 `niri/window` 模块，需要较新版本 Waybar；Ubuntu 24.04 apt 的 `0.9.24` 不含这些模块，建议用 Nix 或源码安装。

#### 3.2.4 Homebrew（CLI 工具推荐）

Linux 上 neovim / tmux / alacritty / fzf / zoxide / bat / lsd / ripgrep / fd / yazi 等纯 CLI 工具推荐通过 Homebrew 安装：版本更新、跨发行版一致。

**适用系统**：Ubuntu / Debian / Arch 等 Linux 发行版（x86_64 与 aarch64）。
**Brewfile 路径**：[`.config/linux/Brewfile`](.config/linux/Brewfile)
**筛选原则**：仅收录可通过 Linuxbrew 安全安装、来源可靠的纯用户级 CLI 工具；桌面环境 / 系统服务 / 输入法 / 系统级工具（redshift 等）/ 构建库 / 字体均不走 brew，详见 Brewfile 顶部注释。

```bash
# 1. 安装 Linuxbrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# 2. 通过 Linux Brewfile 安装 CLI 工具
brew bundle --file .config/linux/Brewfile
```

#### 3.2.5 将默认 shell 改为 zsh

```bash
chsh -s "$(command -v zsh)"
```

退出重新登录后，zinit 会在首次启动 zsh 时自动 clone 安装。

### 3.3 Arch Linux

```bash
sudo pacman -Syu

# 基础工具（系统自带，确保存在；brew 自身依赖 git）
sudo pacman -S --needed git zsh python python-pip curl

# X11 / AwesomeWM 桌面（⚠️ 维护模式，首选 niri+wayland；仅回退 AwesomeWM 时才需要）
sudo pacman -S --needed \
  awesome picom rofi feh xautolock \
  i3lock xorg-xrandr xorg-xinput xorg-xrdb xorg-xdpyinfo \
  redshift \
  fcitx5-im fcitx5-chinese-addons \
  network-manager-applet blueman pasystray pavucontrol \
  udiskie maim libnotify brightnessctl \
  dolphin

# Wayland / niri 桌面（首选）
sudo pacman -S --needed \
  niri waybar mako fuzzel swaybg swayidle swaylock \
  wl-clipboard grim slurp brightnessctl playerctl \
  xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome \
  gnome-keyring polkit-gnome \
  pipewire wireplumber \
  cmake ninja libportal pipewire opencv \
  libx11 libxrandr libxext libxdamage \
  gammastep noto-fonts-cjk

# Satty（AUR 或 cargo）
cargo install satty
# 或 paru -S satty
```

CLI 工具（neovim / tmux / alacritty / fzf / zoxide / bat / lsd / ripgrep / fd / yazi）同样推荐通过 Homebrew 安装，与 Ubuntu 流程一致：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew bundle --file .config/linux/Brewfile
```

```bash
chsh -s "$(command -v zsh)"
```

### 3.4 macOS

**适用系统**：macOS 13+ (Apple Silicon)。
**Brewfile 路径**：[`.config/macos/Brewfile`](.config/macos/Brewfile)
**筛选原则**：仅收录 macOS 系统默认未预装、且必要的第三方应用；`zsh`（Catalina+ 默认 shell）、`git`（Command Line Tools 自带）、三个 zsh 增强插件（zinit 加载）均不列入。

```bash
# 1. 安装 Command Line Tools（自带 git，也是 Homebrew 前置依赖）
xcode-select --install

# 2. 安装 Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# 3. 通过 macOS Brewfile 一键安装第三方依赖
brew bundle --file .config/macos/Brewfile

# 4. 设置 macOS 系统默认（键重复、Dock、Finder、截图等）
bash .config/macos/defaults.sh

# 5. 将默认 shell 改为系统自带 zsh（/bin/zsh，无需 brew 版）
chsh -s /bin/zsh
```

`Brewfile` 已包含 `alacritty`（cask）、`aerospace`、`borders` 以及 CLI 工具 `bat`、`fd`、`fzf`、`lsd`、`neovim`、`ripgrep`、`rsync`、`tmux`、`yazi`、`zoxide`。`zsh` / `git` 由系统提供，zsh 增强插件（completions/autosuggestions/syntax-highlighting）统一由 zinit 从官方仓库加载（见 [2.1](#21-跨平台核心linux--macos-共用)）。

### 3.5 Nerd Font（MesloLGS）安装

Alacritty、p10k 主题、lsd 图标依赖 Nerd Font：

```bash
# Linux
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
fc-cache -fv

# macOS：上述 ttf 下载完成后双击安装，或在 Alacritty 里改用 Homebrew cask：
brew install --cask font-meslo-lg-nerd-font
```

### 3.6 运行安装脚本

完成依赖安装后，回到仓库根目录执行：

```bash
cd ~/Documents/dotfiles
./install.sh
```

脚本行为：

- 自动识别 OS / 架构 / 发行版；
- 复制配置到 `~/.config`、`~/.tmux.conf`、`~/.ssh/config.base` 等，**不创建 symlink**；
- 目标已存在时先备份（保留最近 3 份），再覆盖；
- 检测到 `tmux` 时自动 clone [TPM](https://github.com/tmux-plugins/tpm)；
- 检测到 `awesome` 时自动 clone [collision](https://github.com/Elv13/collision)；
- 检测到 `alacritty` 时自动 clone [alacritty-themes](https://github.com/alacritty-theme/alacritty-themes)；
- 检测到 Wayland 会话时额外部署 waybar / mako / fuzzel / niri 配置与 Wayland 辅助脚本；
- `claude` + `jq` 同时可用时，自动配置 `~/.claude/settings.json` 的 statusline。

### 3.7 首次启动后的插件安装

```bash
# 1. 打开 tmux，按前缀键 + 大写 I 安装 TPM 插件
tmux
# 在 tmux 内：Ctrl+a 然后按 Shift+I

# 2. 首次打开 nvim，lazy.nvim 会自动拉取所有插件；
#    交互式启动后 mason-tool-installer 会补齐 stylua/black/isort/prettier/clang-format/jq/shfmt/tex-fmt。
nvim

# 3. 首次打开 zsh，zinit 自动 clone 并加载插件；
#    之后可运行 p10k configure 个性化提示符。
```

### 3.8 钉钉 Wayland 屏幕共享 hook（可选）

仅 niri/Wayland 下需要钉钉会议共享屏幕时构建：

```bash
cmake -S tools/dingtalk-wayland-screenshare -B /tmp/dingtalk-wayland-screenshare-build -GNinja -DCMAKE_BUILD_TYPE=Release
cmake --build /tmp/dingtalk-wayland-screenshare-build
install -Dm755 /tmp/dingtalk-wayland-screenshare-build/libdingtalkhook.so ~/.local/lib/dingtalk-wayland-screenshare/build/libdingtalkhook.so
```

启动钉钉使用 `~/.config/scripts/dingtalk-wayland`，排障日志在 `/tmp/dingtalk-wayland-debug.log`。

---

## 4. 验证安装成功

### 4.1 仓库自带回归测试

```bash
cd ~/Documents/dotfiles

# 全部测试
./tests/run.sh

# 按分类
./tests/run.sh docs       # 文档完整性
./tests/run.sh awesome    # AwesomeWM 配置
./tests/run.sh nvim       # Neovim 配置
./tests/run.sh fast       # 除 nvim 外的所有快速测试
```

### 4.2 关键命令自检

```bash
# Shell 与终端
echo $SHELL                      # 应为 zsh
command -v fzf zoxide bat lsd    # 全部有输出
command -v nvim && nvim --version | head -1   # ≥ 0.12

# Tmux
tmux -V
ls ~/.tmux/plugins/tpm           # 应存在

# Git
git --version
git config --get core.editor     # 应为 vim

# 桌面（Linux）
command -v awesome picom rofi feh          # X11
command -v niri waybar mako fuzzel swaybg  # Wayland
command -v swaylock swayidle grim slurp satty wl-copy

# macOS
command -v aerospace borders alacritty
defaults read com.apple.dock autohide       # 应为 1
```

### 4.3 Neovim LSP 自检

打开任意代码文件后：

```vim
:lua =vim.lsp.get_clients({bufnr=0})
:lua print(vim.fn.executable("clangd"), vim.fn.exepath("clangd"))
:checkhealth
```

### 4.4 桌面功能验证

| 场景 | 快捷键 / 命令 | 预期 |
|------|--------------|------|
| AwesomeWM 启动 | 登录会话选 Awesome | 顶栏显示标签/布局/时钟 |
| Rofi 启动器 | `Mod+c` | 弹出应用列表 |
| 锁屏 | `Mod+Shift+l` | 进入锁屏界面 |
| 截图 OCR | `Mod+s` | 区域选择 → OCR 翻译 |
| niri 启动 | 登录会话选 niri | Wayland 桌面 + Waybar |
| niri 验证 | `niri validate -c ~/.config/niri/config.kdl` | 无报错 |
| niri overview | `Mod+o` | 显示 workspace 总览 |
| Wayland 截图 | `F1` | slurp 选区 → Satty 标注 |
| Wayland 壁纸切换 | `Mod+Shift+w` | 随机切换壁纸 |

---

## 5. 常见问题

### Q1：`install.sh` 报错 "Missing required dependencies"

脚本退出前会列出缺失命令。通常是 `find` / `cp` / `mv` / `diff` / `sort` / `grep` / `tail` 之一。这些命令默认在所有 Linux/macOS 自带；若在极简容器内运行，请安装 `coreutils` / `findutils` / `diffutils` / `grep`。

### Q2：zsh 启动很慢或 zinit clone 失败

- zinit 首次启动会从 GitHub 克隆，网络不畅时慢属正常。
- 仓库已配置 USTC Homebrew 镜像，但 zinit 走 GitHub，必要时请配置代理或 GitHub 镜像。
- 可手动 clone：`git clone https://github.com/zdharma-continuum/zinit.git ~/.local/share/zinit/zinit.git`

### Q3：Alacritty 图标/字体显示为方框

未安装 Nerd Font。按 [3.5 Nerd Font 安装](#35-nerd-fontmeslolgs安装) 操作，并在终端设置里把字体改为 `MesloLGS Nerd Font Mono`。

### Q4：AwesomeWM 启动后顶栏图标缺失或乱码

同 Q3，安装 Nerd Font 后重启 Awesome（`Mod+Ctrl+r`）。

### Q5：Waybar 报错 "Unknown module: niri/workspaces"

Waybar 版本过旧，缺少 niri 专用模块。Ubuntu 24.04 apt 的 `0.9.24` 不含该模块，请用 Nix 或源码安装较新版本（见 [3.2.3](#323-niriwayland-合成器)）。

### Q6：niri 下 `Mod+Return` 无反应

检查 `~/.config/scripts/terminal-wayland` 是否存在且可执行，以及 Alacritty 是否安装。脚本回退顺序：`~/.nix-profile/bin/alacritty` → 系统 `alacritty` → `kitty`。三者都缺失会通过 `notify-send` 提示。

### Q7：`F1` 截图标注报 "缺少依赖：satty / grim / slurp / wl-copy"

`~/.config/scripts/screenshot-wayland` 显式要求这四个命令全部存在，不会回退到 `swappy` / `ksnip`。安装缺失项即可：

```bash
sudo apt install grim slurp wl-clipboard
cargo install satty   # 或 paru -S satty
```

### Q8：Wayland 锁屏密码不正确

`~/.config/scripts/lock-wayland` 优先调用 `/usr/bin/swaylock` 走系统 PAM。若你用 Nix 安装的 `swaylock` 与系统 PAM 不兼容，请确保 `/usr/bin/swaylock` 存在；必要时补 `/etc/pam.d/swaylock`：

```pam
auth include common-auth
account include common-account
session include common-session
```

### Q9：钉钉 Wayland 共享屏幕全黑

需要构建并 preload `libdingtalkhook.so`（见 [3.8](#38-钉钉-wayland-屏幕共享-hook可选)）。同时确认 PipeWire / WirePlumber / xdg-desktop-portal 正常运行：

```bash
systemctl --user status pipewire wireplumber
pgrep -a xdg-desktop-portal
```

排障日志：`/tmp/dingtalk-wayland-debug.log`，正常路径会看到 `stream state changed from paused to streaming`。

### Q10：fcitx5 在 GTK 应用里输入法不生效

- Wayland 下 GTK4 走 text-input 协议，**不应**设置 `GTK_IM_MODULE=fcitx`。仓库的 `wayland-autostart` 已显式 `unset GTK_IM_MODULE`。
- 若仍异常，排查：`systemctl --user show-environment`、`~/.config/environment.d/*.conf`、`~/.xprofile`、niri-session 的 `import-environment`。
- Qt 应用仍需 `QT_IM_MODULE=fcitx`（仓库已设置）。

### Q11：`redshift` 在 Ubuntu aarch64 上不工作

aarch64 优先使用系统二进制 `redshift`。若系统包缺失，`install.sh` 仅提示手动安装，不自动提权：

```bash
sudo apt install redshift
```

### Q12：`git commit` 打开的是 vi 而不是 nvim

这是有意为之。仓库 [memory/git.md](memory/git.md) 与 [.config/shared/git/README.md](.config/shared/git/README.md) 明确：`core.editor = vim`，以规避 VSCode 集成终端里 nvim 的输入兼容问题。如需改回 nvim，编辑 `~/.config/git/config`。

### Q13：Ubuntu x64 picom 报 `c2_parse_target` 错误

`_GTK_FRAME_EXTENTS@` 在 Ubuntu x64 + picom v10 上会触发解析错误，仓库配置已移除该规则。若你手动改回该配置并报错，请再次移除。详见 [.config/linux/picom/README.md](.config/linux/picom/README.md)。

### Q14：Clangd LSP 不 attach

按顺序排查：

```vim
:lua print(vim.lsp.is_enabled("clangd"))
:lua print(vim.fn.executable("clangd"), vim.fn.exepath("clangd"))
:lua =vim.fs.root(0, {"CMakeLists.txt", "CMakePresets.json", "CMakeUserPresets.json", "compile_commands.json", ".git"})
```

若 `executable("clangd") = 0`，安装 clangd 并在 `~/.local/bin/clangd` 建软链，重启 nvim 或对文件执行 `:edit`。

### Q15：如何彻底清除 tmux resurrect 状态

```bash
rm -rf ~/.local/share/tmux/resurrect/
```

---

## 6. 卸载与回退

`install.sh` 采用复制部署，不创建 symlink。卸载只需删除 `~/.config/` 下对应目录与 `~/.tmux.conf`、`~/.zshrc` 等。每个被覆盖的文件都保留最近 3 份带时间戳的备份（形如 `xxx.backup.YYYYMMDD_HHMMSS`），可手动恢复。

回退到系统默认 shell：

```bash
chsh -s /bin/bash   # Linux
chsh -s /bin/zsh    # macOS（系统自带 zsh）
```

---

## 7. 参考文档

- 根目录 [README.md](README.md) — 仓库总览与使用方式
- [AGENTS.md](AGENTS.md) — 强制行为协议（修改仓库前必读）
- [USER.md](USER.md) — 用户偏好
- 模块 README：[awesome](.config/linux/awesome/README.md) / [niri](.config/linux/niri/README.md) / [nvim](.config/shared/nvim/README.md) / [tmux](.config/shared/tmux/README.md) / [zsh](.config/shared/zsh/README.md) / [alacritty](.config/shared/alacritty/README.md) / [rofi](.config/linux/rofi/README.md) / [waybar](.config/linux/waybar/README.md) / [picom](.config/linux/picom/README.md) / [aerospace](.config/macos/aerospace/README.md) / [x11](.config/linux/x11/README.md) / [scripts](.config/scripts/README.md)
- 模块 memory：[organizing_preferences](memory/organizing_preferences.md) / [desktop](memory/desktop.md) / [nvim](memory/nvim.md) / [awesome](memory/awesome.md) / [tmux](memory/tmux.md) / [rofi](memory/rofi.md) / [alacritty](memory/alacritty.md) / [git](memory/git.md)
