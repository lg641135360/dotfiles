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
│   │   ├── Brewfile     # Linux brew 依赖清单
│   │   ├── desktop-entries/ # 覆盖系统 desktop entry（fuzzel 菜单走 Wayland 包装脚本）
│   │   ├── fuzzel/      # Wayland 启动器
│   │   ├── foot/        # foot 终端模拟器配置（Alacritty 的 Wayland 兜底）
│   │   ├── mako/        # Wayland 通知守护进程
│   │   ├── niri/        # Wayland 合成器（平行试用）
│   │   ├── picom/       # X11 合成器
│   │   ├── rofi/        # 应用启动器
│   │   ├── waybar/      # Wayland 状态栏
│   │   ├── x11/         # X11 会话配置（resources / xsessionrc）
│   │   └── xdg-desktop-portal/ # 桌面门户配置
│   ├── macos/           # macOS 桌面环境配置
│   │   ├── aerospace/   # 窗口管理器
│   │   ├── Brewfile     # macOS brew 依赖清单
│   │   ├── defaults.sh  # macOS 系统默认值（键重复 / Dock 等）
│   │   └── ssh/         # SSH 配置（macOS 覆盖）
│   └── scripts/         # 辅助脚本
│       ├── lock/              # X11 锁屏
│       ├── lock-wayland/      # Wayland 锁屏
│       ├── corplink-service/  # 飞连服务临时管理
│       ├── rofi-launch/       # Rofi 启动脚本
│       ├── wayland-autostart/ # Wayland 自启动
│       ├── dingtalk-wayland/  # 钉钉 Wayland 屏幕共享
│       ├── terminal-wayland/  # Wayland 终端
│       ├── file-manager-wayland/ # Wayland 文件管理器选择
│       ├── launcher-wayland/  # Wayland 启动器
│       ├── screenshot-wayland/ # Wayland 截图
│       ├── wallpaper-wayland/ # Wayland 壁纸
│       ├── wallpaper-wayland-next/ # Wayland 壁纸（下一张）
│       ├── browser-wayland/   # Wayland Chrome 启动器
│       ├── trae-cn-wayland/   # Wayland Trae CN 启动器
│       ├── waybar-system-tooltip/  # Waybar CPU/MEM tooltip 脚本
├── scripts/          # TypeScript 工具（trace 归档等）
├── tests/            # 回归测试
│   ├── run.sh        # 测试运行器
│   └── lib/          # 测试工具库（assert.sh / sandbox.sh）
├── tools/            # 构建工具源码（钉钉 Wayland 屏幕共享 hook）
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

安装脚本采用复制部署，不会创建符号链接；目标文件已存在时会先备份再覆盖。脚本通过自身路径定位仓库，因此可从任意工作目录执行。它不会自动安装桌面软件：仅在对应命令可用时复制配置，缺失时打印提示并跳过；例外是已安装 `tmux` 或 Alacritty 时，可通过 Git 获取缺失的 TPM 或 Alacritty 主题。Linux 上检测到 `niri` 后会部署 Wayland 辅助脚本，以及已安装的 Waybar、Mako、Fuzzel 配置，不判断当前会话类型；仅 Ubuntu 会复制本仓库的 Niri KDL，Arch 保留现有 Niri 配置，openSUSE 还会跳过 Alacritty 配置复制以保留 DMS 管理。

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
