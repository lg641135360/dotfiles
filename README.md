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
│   │   ├── nvim/        # Neovim 配置（submodule → lg641135360/neovim）
│   │   ├── ssh/         # SSH base 配置
│   │   ├── tmux/        # tmux 配置和 tab 标题脚本
│   │   └── zsh/         # zsh 模块化配置（.zshrc / aliases / path / env 等）
│   ├── linux/           # Linux 桌面环境配置
│   │   ├── awesome/     # AwesomeWM 窗口管理器
│   │   ├── fuzzel/      # Wayland 启动器
│   │   ├── mako/        # Wayland 通知守护进程
│   │   ├── niri/        # Wayland 合成器（平行试用）
│   │   ├── picom/       # X11 合成器
│   │   ├── rofi/        # 应用启动器
│   │   ├── waybar/      # Wayland 状态栏
│   │   ├── x11/         # X11 会话配置（resources / xsessionrc）
│   │   └── xdg-desktop-portal/ # 桌面门户配置
│   ├── macos/           # macOS 桌面环境配置
│   │   ├── aerospace/   # 窗口管理器
│   │   ├── rift/        # 窗口管理器
│   │   └── ssh/         # SSH 配置（macOS 覆盖）
│   └── scripts/         # 辅助脚本
│       ├── lock/              # X11 锁屏
│       ├── lock-wayland/      # Wayland 锁屏
│       ├── rofi-launch/       # Rofi 启动脚本
│       ├── wayland-autostart/ # Wayland 自启动
│       ├── dingtalk-wayland/  # 钉钉 Wayland 屏幕共享
│       ├── terminal-wayland/  # Wayland 终端
│       ├── launcher-wayland/  # Wayland 启动器
│       ├── screenshot-wayland/ # Wayland 截图
│       └── wallpaper-wayland/ # Wayland 壁纸
├── tests/           # 回归测试
│   ├── run.sh       # 测试运行器
│   └── lib/         # 测试工具库
├── tools/           # 构建工具源码（钉钉 Wayland 屏幕共享 hook）
├── memory/          # 长期偏好和模块特化记录
└── logs/            # 操作日志
```

## 提示词系统

本仓库的权威行为协议是 `AGENTS.md`；`.github/copilot-instructions.md` 与
`CLAUDE.md` 只作为薄入口，要求不同 agent 先读取并遵循同一份协议，避免多份规则漂移。

`memory/` 记录长期偏好和模块特化经验，`logs/trace.md` 只记录实际修改、验证证据与后续线索；稳定规则应提升到 `AGENTS.md` 或 `memory/`，不要长期只留在 trace 里。

`.omx/` 是本地工作流状态、访谈、规格和计划产物目录，已通过 `.gitignore` 排除，默认不提交。只有在任务明确需要恢复 OMX 历史规划、评估本地工作流状态，或用户点名相关文件时，才读取其中内容；普通仓库修改不应把 `.omx/` 当作权威配置来源。

## 使用方式

```shell
chmod +x install.sh
./install.sh
```

安装脚本采用复制部署，不会创建符号链接；目标文件已存在时会先备份再覆盖。

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
