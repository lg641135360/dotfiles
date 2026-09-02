# 辅助脚本

## 文件清单

| 脚本 | 用途 |
|------|------|
| `lock` | X11 锁屏（i3lock-color → i3lock --blur → i3lock 纯色降级） |
| `lock-wayland` | Wayland 锁屏（gtklock 优先，swaylock 兜底） |
| `corplink-service` | 临时管理飞连 `corplink.service`；支持查看状态、停止到下次重启、立即恢复 |
| `rofi-launch` | Rofi 应用启动器包装 |
| `wayland-autostart` | Wayland 会话自启动；同步会话环境，等待 niri ScreenCast D-Bus 服务后修复 portal 启动顺序，并启动桌面组件；日志写入 `~/.local/state/niri/autostart/` |
| `dingtalk-wayland` | 钉钉维护/兼容入口；aarch64 日常通过 Mod+C 调用官方 `Elevator.sh`，无需该脚本或 hook。脚本用于 portal 检查、集中日志、按 `/proc/<pid>/exe` 精确清理钉钉/tblive，以及显式 hook 回退 |
| `terminal-wayland` | Wayland 终端启动器；默认 foot，缺失时回退 Alacritty |
| `file-manager-wayland` | Wayland 文件管理器选择器（Dolphin → 系统默认 → 常见文件管理器） |
| `launcher-wayland` | Wayland 应用启动器 |
| `clipboard-wayland` | Wayland 剪贴板管理：`start` 启动 wl-clip-persist 持久化守护（窗口关闭后内容不丢），`history` 用 cliphist + fuzzel 检索并写回剪贴板（Mod+V） |
| `screenshot-wayland` | Wayland 选区截图（Mod+s：slurp → grim → Satty） |
| `wallpaper-wayland` | Wayland 壁纸设置 |
| `browser-wayland` | Google Chrome Wayland 启动器（Wayland 会话加 `--ozone-platform=wayland`，X11 原样透传） |
| `trae-cn-wayland` | Trae CN (Electron) Wayland 启动器（Wayland 会话加 ozone-wayland + Wayland IME，X11 原样透传） |
| `update-ai-clis` | 一键更新 npm 全局安装的 AI CLI（claude-code / codex） |

## 临时停止飞连系统服务

`corplink-service` 默认只读查看状态。`disable` 会通过 sudo 执行
`systemctl stop corplink.service`：显式停止不会触发单元的 `Restart=always`。由于厂商单元使用
`KillMode=process`，脚本随后会针对该单元整个 cgroup 依次发送 SIGTERM 和 SIGKILL，清理仍存活的
`corplink-uc` 子进程并验证 cgroup 已为空。脚本不执行 `disable` 或 `mask`，所以不会修改开机启动状态，
下次重启时服务会按原配置恢复。
需要在重启前恢复时执行 `enable`，它只会立即启动服务，同样不改变开机启动状态。

```sh
~/.config/scripts/corplink-service status
~/.config/scripts/corplink-service disable
~/.config/scripts/corplink-service enable
```

飞连可能承担公司 VPN、终端安全或访问控制功能；禁用前应确认当前不依赖相关内网与合规能力。

## 一键更新 AI CLI（claude-code / codex）

claude-code 与 codex 均通过 npm 全局安装（不走 brew cask：claude-code 的原生二进制源
`downloads.claude.ai` 在国内被阻断，且两者统一走 npm 便于同步更新），因此用 `update-ai-clis`
作为一键升级入口，内部执行 `npm update -g @anthropic-ai/claude-code @openai/codex`。

```sh
~/.config/scripts/update-ai-clis            # 更新两个包到最新
~/.config/scripts/update-ai-clis --check    # 仅查看当前版本
```
