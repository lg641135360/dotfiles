# 辅助脚本

## 文件清单

| 脚本 | 用途 |
|------|------|
| `lock` | X11 锁屏（i3lock-color → i3lock --blur → i3lock 纯色降级） |
| `lock-wayland` | Wayland 锁屏（swaylock，复用当前壁纸） |
| `corplink-service` | 临时管理飞连 `corplink.service`；支持查看状态、停止到下次重启、立即恢复 |
| `rofi-launch` | Rofi 应用启动器包装 |
| `wayland-autostart` | Wayland 会话自启动；同步会话环境，等待 niri ScreenCast D-Bus 服务后修复 portal 启动顺序，并启动桌面组件；日志写入 `~/.local/state/niri/autostart/` |
| `dingtalk-wayland` | 钉钉排障脚本：检查 ScreenCast/PipeWire 状态，并按 `/proc/<pid>/exe` 精确清理钉钉/tblive。日常启动用官方 `Elevator.sh` |
| `terminal-wayland` | Wayland 终端启动器；默认 foot，缺失时回退 Alacritty |
| `file-manager-wayland` | Wayland 文件管理器选择器（Dolphin → 系统默认 → 常见文件管理器） |
| `launcher-wayland` | Wayland 应用启动器 |
| `clipboard-wayland` | Wayland 剪贴板管理：`start` 启动 `wl-clip-persist --clipboard regular --ignore-event-on-error`（窗口关闭后内容不丢；读失败不写回旧文本），并启动 X11 轮询桥（`xclip` ↔ `wl-paste`/`wl-copy`，双向同步文本与 image/png、jpeg、gif，哈希去抖；同时有图片和文本时只同步图片，读写套 `timeout --foreground 2` 防止 xclip 在 owner 失联时无限阻塞，让钉钉等 X11 应用也能粘贴截图），`history` 用 cliphist + fuzzel 检索并写回剪贴板（Mod+V） |
| `screenshot-wayland` | Wayland 选区截图（Mod+s：slurp → grim → Satty；复制走 `wl-copy -t image/png`） |
| `wallpaper-wayland` | Wayland 壁纸设置 |
| `browser-wayland` | Google Chrome Wayland 启动器（Wayland 会话加 `--ozone-platform=wayland`，X11 原样透传） |
| `obsidian-wayland` | Obsidian (Electron) Wayland 启动器（Wayland 会话加 `--ozone-platform=wayland --enable-wayland-ime --disable-vulkan`，X11 原样透传）；二进制固定为 `/opt/Obsidian/obsidian`（x86_64 官方 deb；aarch64 上游无 deb，用官方 `obsidian-<ver>-arm64.tar.gz` 解压到同一路径），缺失时通知 + stderr + 退出 127 而非静默失败；`OBSIDIAN_WAYLAND_BIN` 可覆盖路径（测试钩子） |
| `trae-cn-wayland` | Trae CN (Electron) Wayland 启动器（Wayland 会话加 ozone-wayland + Wayland IME，X11 原样透传） |
| `chatgpt-wayland` | ChatGPT 桌面版 (Electron) Wayland 启动器（Wayland 会话加 `--ozone-platform=wayland --enable-wayland-ime`，X11 原样透传；否则 XWayland 下 fcitx5 走 XIM 会 preedit 不同步） |

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

## 更新 npm 全局安装的 CLI

claude-code / codex / pi 均通过 npm 全局安装（不走 brew cask：claude-code 的原生二进制源
`downloads.claude.ai` 在国内被阻断，且统一走 npm 便于同步更新）。升级优先用各自的自带
updater，不需要额外的仓库脚本：

```sh
pi update --self      # pi（`pi update` 还会更新扩展与模型目录）
claude update         # claude-code
codex update          # codex（内部会调 `npm install -g @openai/codex`）
npm ls -g --depth=0   # 查看当前版本
```

注意：**不要用裸 `npm update -g`**。MacPorts 的 npm10 在
`lib/commands/update.js` 里打了补丁：只要没带包名（或包含 `npm`）就直接报错退出，
因为无参数形式会顺带升级 npm 自身。确实要走 npm 时显式列包：

```sh
npm update -g @earendil-works/pi-coding-agent @anthropic-ai/claude-code @openai/codex @agegr/pi-web
```
