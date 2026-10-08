# dotfiles

个人跨平台配置仓库。安装脚本采用复制部署，不使用 symlink；已有目标会先备份。

## 仓库结构

```text
.
├── .config/
│   ├── shared/          # 跨平台共享配置
│   │   ├── alacritty/   # 终端模拟器（Linux/Mac 分 keys/window 配置）
│   │   ├── cc/          # Claude Code statusline 脚本
│   │   ├── git/         # git 别名和模板
│   │   ├── herdr/       # AI agent 多路复用器配置（对齐 tmux 键位 + Catppuccin）
│   │   ├── nvim/        # Neovim 配置（submodule → lg641135360/neovim）
│   │   ├── ssh/         # SSH base 配置
│   │   ├── starship.toml # 跨平台 shell 提示符
│   │   ├── tmux/        # tmux 配置和 tab 标题脚本
│   │   └── zsh/         # zsh 模块化配置（.zshrc / aliases / path / env 等）
│   ├── linux/           # Linux 桌面环境配置
│   │   ├── awesome/     # AwesomeWM 窗口管理器
│   │   ├── Brewfile     # Linux brew 依赖清单（跨发行版纯 CLI 层）
│   │   ├── desktop-entries/ # 覆盖系统 desktop entry（fuzzel 菜单走 Wayland 包装脚本）
│   │   ├── dms/         # DMS 机器的 niri 接入（仓库片段 + 接线脚本说明）
│   │   ├── fuzzel/      # Wayland 启动器
│   │   ├── foot/        # foot 终端模拟器配置（Wayland 默认终端，Alacritty 兜底）
│   │   ├── mako/        # Wayland 通知守护进程
│   │   ├── niri/        # Wayland 合成器（主力桌面，AwesomeWM 为回退）
│   │   ├── packages/    # 系统层包清单（apt.txt Ubuntu / dnf.txt Fedora）
│   │   ├── picom/       # X11 合成器
│   │   ├── rofi/        # 应用启动器
│   │   ├── swaylock/    # Wayland 锁屏
│   │   ├── waybar/      # Wayland 状态栏
│   │   ├── x11/         # X11 会话配置（resources / xsessionrc）
│   │   ├── xdg-autostart/ # 覆盖 XDG autostart 入口（禁用 GNOME/X11 遗留项）
│   │   └── xdg-desktop-portal/ # 桌面门户配置
│   ├── macos/           # macOS 桌面环境配置
│   │   ├── aerospace/   # 窗口管理器（白苹果首选）
│   │   ├── yabai/       # 窗口管理器 + skhd 热键（黑苹果 x86_64 首选）
│   │   ├── karabiner/   # 键盘映射（Caps Lock：按住 Ctrl / 单击 Esc）
│   │   ├── linearmouse/ # 鼠标/触控板滚动与指针定制（LinearMouse）
│   │   ├── Brewfile     # macOS brew 依赖清单
│   │   ├── defaults.sh  # macOS 系统默认值（键重复 / Dock / 窗口管理前提等）
│   │   └── ssh/         # SSH 配置（macOS 覆盖）
│   └── scripts/         # 辅助脚本
│       ├── lock/              # X11 锁屏
│       ├── lock-wayland/      # Wayland 锁屏
│       ├── corplink-service/  # 飞连服务临时管理
│       ├── rofi-launch/       # Rofi 启动脚本
│       ├── wayland-autostart/ # Wayland 自启动
│       ├── dingtalk-wayland/  # 钉钉排障入口（启动走官方 Elevator.sh）
│       ├── terminal-wayland/  # Wayland 终端
│       ├── file-manager-wayland/ # Wayland 文件管理器选择
│       ├── launcher-wayland/  # Wayland 启动器
│       ├── clipboard-wayland/ # Wayland/X11 剪贴板持久化与桥接
│       ├── dms-niri-setup/    # DMS 机器 niri 接入（include 顺序 / 键位 / 钉钉规则）
│       ├── screenshot-wayland/ # Wayland 截图
│       ├── wallpaper-wayland/ # Wayland 壁纸
│       ├── wallpaper-wayland-next/ # Wayland 壁纸（下一张）
│       ├── browser-wayland/   # Wayland Chrome 启动器
│       ├── trae-cn-wayland/   # Wayland Trae CN 启动器
│       ├── chatgpt-wayland/   # Wayland ChatGPT 启动器
│       ├── obsidian-wayland/  # Wayland Obsidian 启动器
│       ├── herdr-report/      # Trae CLI 生命周期 → herdr 状态上报桥接
├── scripts/          # TypeScript 工具（trace 归档等）
├── tests/            # 回归测试
│   ├── run.sh        # 测试运行器
│   └── lib/          # 测试工具库（assert.sh / sandbox.sh）
├── memory/           # 长期偏好和模块特化记录
└── logs/             # 操作日志
```

## 提示词系统

本仓库的权威行为协议是 `AGENTS.md`；`.github/copilot-instructions.md` 是仓库内的薄入口，
`CLAUDE.md` 是 gitignored 的本地可选入口（使用 Claude Code 时本地创建），两者都要求
agent 先读取并遵循同一份协议，避免多份规则漂移。

`memory/` 记录长期偏好和模块特化经验，`logs/trace.md` 只记录实际修改、验证证据与后续线索；稳定规则应提升到 `AGENTS.md` 或 `memory/`，不要长期只留在 trace 里。

`.omx/` 是本地工作流状态、访谈、规格和计划产物目录，已通过 `.gitignore` 排除，默认不提交。只有在任务明确需要恢复 OMX 历史规划、评估本地工作流状态，或用户点名相关文件时，才读取其中内容；普通仓库修改不应把 `.omx/` 当作权威配置来源。

## 使用方式

```shell
chmod +x install.sh
./install.sh
```

Linux 依赖按三层分开维护：纯 CLI 走 `brew bundle --file ~/.config/linux/Brewfile`；系统层按发行版执行 `sudo apt install $(grep -v '^#' ~/.config/linux/packages/apt.txt)`（Ubuntu）或 `sudo dnf install $(grep -v '^#' ~/.config/linux/packages/dnf.txt)`（Fedora）。同一台机器同一工具只保留一个渠道——桌面/服务/输入法/字体/构建工具一律走系统包，系统层已满足时不要再用 brew 重复（linuxbrew 位于 zsh PATH 之后，重复时系统版生效）。PPA / COPR / 源码编译等例外写在两份清单的注释里，执行前先按注释启用对应源。

macOS 自带 Bash 为 3.2，而 `install.sh` 需要 Bash ≥ 4.3（`process_configs` 的 `local -n`、`clean_old_backups` 的 `mapfile`）；脚本检测到过旧 Bash 时，会自动改用 `/opt/local/bin/bash`（MacPorts）或 `/usr/local/bin/bash`、`/opt/homebrew/bin/bash`（Homebrew）重新执行，都没有则报错退出。Intel macOS 上用 MacPorts 装一次即可：`sudo port install bash`。Bash 版本由脚本 shebang 决定，与登录 shell 是 zsh 还是 bash 无关。macOS 分支还会执行 `.config/macos/defaults.sh` 应用系统偏好（键重复/Dock/Finder/截图/触控板等）；该脚本按当前值幂等，仅当值不同才写入、且仅在确有变化时才重启 Finder/Dock，因此重复运行 `install.sh` 不会反复重设。

升级已安装的工具：npm 全局安装的 CLI 优先用各自的自带 updater——`pi update --self`、`claude update`、`codex update`（实测均可）；也可用 `npm update -g <包名>` 显式列出升级。注意**不要用裸 `npm update -g`**：MacPorts 的 npm10 打了补丁，无包名时会拒绝执行（它会顺带升级 npm 自身）。herdr 用自带 `herdr update`。yabai 走官方预编译 release：重跑安装脚本覆盖二进制（目录参数须与首次一致，即 `~/.local/bin` 与 `~/.local/share/man/man1`），并**刷新 `/private/etc/sudoers.d/yabai` 的 sha256**（二进制变了旧哈希就失效），再 `yabai --start-service` 与 `sudo yabai --load-sa`；JankyBorders（焦点边框）为源码安装，更新 = `git pull && make` 后覆盖 `~/.local/bin/borders`——完整命令见 `.config/macos/yabai/README.md`。skhd 及其余由 MacPorts 管理的工具（node/npm、neovim、yazi、starship、bash、tmux、fzf 等）用 `sudo port selfupdate && sudo port upgrade outdated`。

窗口管理器按机型二选一：**黑苹果 x86_64（本机）用 yabai + skhd**——yabai 走官方预编译 release（二进制已带维护者自签证书，装到 `~/.local/bin`，不依赖 Homebrew 也不需要在系统目录写文件），skhd 走 MacPorts；**白苹果（Apple Silicon / 官方硬件）用 AeroSpace**（Brewfile 里的 `nikitabobko/tap/aerospace`）。两者都用 `alt` 作 Mod、不能同机同跑；配置分别在 `.config/macos/yabai/` 和 `.config/macos/aerospace/`，`install.sh` 按对应命令是否可用分别部署。

安装脚本采用复制部署，不会创建符号链接；目标文件已存在时会先备份再覆盖（同类备份保留最近 3 份）。对 `~/.zshenv` 追加 `ZDOTDIR` / `skip_global_compinit` 前也会先建时间戳备份。桌面入口中的 `__HOME__` 占位符在复制前展开，因此重复运行不会产生多余备份。脚本通过自身路径定位仓库，因此可从任意工作目录执行。它不会自动安装桌面软件：仅在对应命令可用时复制配置，缺失时打印提示并跳过；例外是已安装 `tmux` 时可通过 Git 获取缺失的 TPM，以及 Linux 上已安装 Alacritty 时会自动 clone 主题仓库（macOS 需手动 clone，见 `.config/macos/yabai/README.md`）。TPM 只装插件管理器，声明在 `~/.tmux.conf` 的插件（catppuccin 主题、tmux-resurrect 等）需在 tmux 内按 `Ctrl+a + I` 才会克隆，因此检测到插件目录只有 TPM 时脚本会打印该按键提示。Linux 上检测到 `niri` 后会部署 Wayland 辅助脚本、桌面入口、portal 偏好与 XDG autostart 覆盖，不判断当前会话类型；检测到 `foot` 时部署 Foot 终端配置（niri 与 GNOME 等 Wayland 环境均适用），按单文件部署，保留 `~/.config/foot` 中其它第三方文件（如 DMS 的 `dank-colors.ini`）。Niri KDL 与 Waybar、Mako、Fuzzel、Swaylock 桌面外壳栈仅在 Ubuntu 且未检测到 DMS 时部署——DMS（`command -v dms`）机器保留其自管的 Niri 配置与外壳栈，非 Ubuntu 发行版保留现有 live 配置；Alacritty 配置在 openSUSE 与 DMS 机器上跳过复制以保留 DMS 管理。钉钉日常启动使用官方 `Elevator.sh`，仓库中的 `dingtalk-wayland` 只保留排障功能。

### DMS 机器（niri + DankMaterialShell）

DMS 会接管 niri 配置与整个外壳栈（状态栏 / 通知 / launcher / 锁屏 / idle / 壁纸 /
色温 / 剪贴板 / 窗口规则），所以 DMS 机器上仓库只负责两类东西：**应用包装与会话辅助**
（已有的 Wayland 脚本、desktop entry、portal 偏好、foot；按需按键 spawn，不靠 autostart），
以及**仓库自己的一层 niri 片段** `.config/linux/dms/niri-repo.kdl`（2026-10-08 起按本机 Ubuntu x64 的 live 键位取舍：`Mod+E` 开 Thunar、`Mod+S` 走 DMS 区域截图、`Mod+Tab` 回上一个窗口、`Mod+Shift+A/D` 把窗口搬到另一块屏；与 live 已经一致的键不写入片段）。同时部署对应平台的 `outputs.kdl` 到 `~/.config/niri/outputs.kdl`；按方案 B，它是 DMS 机器的权威屏幕配置，接线时排在所有 `dms/*.kdl` 之前，键位片段仍排在它们之后。
`install.sh` 检测到 `niri` + `dms` 时会部署该片段、对应平台的 `outputs.kdl` 与 `settings.txt`（DMS 设置清单，
`~/.config/dms/settings.txt`）并运行幂等接线脚本 `dms-niri-setup`（下发设置、补齐 DMS 默认键位、
补 `dms/*.kdl` 的 include、把仓库屏幕 include 排在所有 DMS 片段之前、把仓库键位片段排到所有 `dms/*.kdl` 之后、通过 DMS 通道重建钉钉窗口规则）；
细节、逐键取舍与设置清单见 `.config/linux/dms/README.md`。

复现顺序（Fedora 为例）：

```bash
brew bundle --file ~/.config/linux/Brewfile
sudo dnf copr enable avengemedia/dms
sudo dnf install --setopt=install_weak_deps=False $(grep -v '^#' ~/.config/linux/packages/dnf.txt)
./install.sh                 # 部署配置 + 接线（niri-repo.kdl / dms-niri-setup）
dms-niri-setup --check       # 巡检：0 = 接线就绪
```

登录 niri 后 DMS 才会生成 `~/.config/niri/dms/*.kdl`，所以首次应在登录过一次
niri 之后再跑 `./install.sh`（或单独跑 `dms-niri-setup`）。

**不安装清单**（DMS 机器装了会与 DMS 抢职责或双开，也是 `dnf install niri` 的
weak dependency 会顺手带来的东西）：

| 不装 | 原因 |
| --- | --- |
| `waybar` | DMS 自带状态栏；两者同时运行会出现两条 bar（Fedora 的 `niri` 把 waybar 作为 weak dependency 拉进来，已装则 `sudo dnf remove waybar`） |
| `mako` | 通知由 DMS 接管（`dms.service` 本身占用 `org.freedesktop.Notifications`） |
| `fuzzel` / `rofi` | launcher 由 DMS spotlight 提供（`Mod+Space`） |
| `swaylock` | 锁屏由 DMS 提供（`Mod+Alt+L` → `dms ipc call lock lock`） |
| `swayidle` | idle/自动锁屏由 DMS 接管 |
| `swaybg` | 壁纸由 DMS 接管 |
| `gammastep` | 色温由 DMS 自带 night light 提供，两个 gamma 客户端会互相打架 |
| `polkit-gnome` | polkit agent 由 DMS 提供 |
| `brightnessctl` | 亮度由 `dms ipc call brightness` 处理（带 OSD） |
| `playerctl` | 媒体键由 `dms ipc call mpris` 处理 |
| `cliphist` / `wl-clip-persist` | 剪贴板历史与持久化由 DMS 自带服务提供（`dms clipboard history`，另可从旧 cliphist 用 `dms clipboard cliphist-migrate` 迁移）；它们只属于非 DMS 的 Wayland 会话（仓库 `clipboard-wayland`） |

同理，DMS 机器上**不要**在 niri 里 `spawn-at-startup` 上面这些命令。仓库的
`wayland-autostart` 在 DMS 机器上**不会被 spawn**：环境导入由 `niri-session` 完成、
fcitx5 走 XDG autostart（`~/.config/autostart/fcitx5.desktop`），其余职责已列在上表；
需要其中某一项（例如 X11↔Wayland 剪贴板桥）时再在 `niri-repo.kdl` 里把
`spawn-sh-at-startup "~/.config/scripts/wayland-autostart"` 加回并确认不与 DMS 重复。

当 `claude` 和 `jq` 同时可用时，还会安装 `.config/shared/cc/statusline.sh` 到
`~/.config/cc/statusline.sh`，并配置 `~/.claude/settings.json` 指向该脚本。

## 运行测试

```shell
# 运行全部测试
./tests/run.sh

# 按分类运行
./tests/run.sh docs       # 文档完整性
./tests/run.sh awesome    # AwesomeWM 相关
./tests/run.sh nvim       # Neovim 相关
./tests/run.sh fast       # 除 nvim 外的所有快速测试

# 直接运行单个测试
./tests/awesome_config_test.sh
./tests/alacritty_config_test.sh
```
