# tmux 偏好

## 状态栏
- 左侧显示当前 session 名（`status-left-length 20` 截断保护，避免 OMX/自动生成长 session 名挤占 tab 区域）。
- 右侧只保留 Prefix/Copy 状态和日期时间，不显示当前 shell/application。
- 不要为了状态栏额外引入 CPU/RAM/Battery 插件依赖。

## Tab 标题
- 以易用和扫读辨识度优先。
- 本地只显示项目名或最短必要路径，不加 `L:` 前缀。
- 远程 SSH：优先保留 `~/.ssh/config` 中的远程别名；没有别名且是 IPv4 时显示最后两段（如 `192.168.1.1` → `1.1`）。
- 牺牲路径细节来避免 tab 过长。

## 交互增强
- 不增加插件：分屏/新窗口继承当前 pane 目录、保留 `C-a C-a` 发送 prefix。
- 用 `H/J/K/L` 调整 pane 大小。
- 复制模式尽量走终端剪贴板。
- 窗口/会话导航使用内置能力：`C-a w` → `choose-tree -Zw` 树状选择器，`C-a n` / `C-a p` → 下一个 / 上一个窗口（tmux 内置默认键，保留 h/j/k/l 做 pane 移动），`C-a Tab` → 上一个窗口。
- 临时 shell 浮窗绑定 `C-a f`（2026-08-23 由 `t` 改为 `f`），`exit` / `Ctrl+d` 关闭。
- 不启用 `extended-keys on`（2026-08-23 评估后用户否决）：foot 终端下有扩展键序列不被识别/透传的风险。

## 终端特性（terminal-features）
- tmux 按客户端实际 TERM 匹配 terminal-features 规则；两平台主力终端（aarch64 foot、x64 alacritty）均以 `TERM=xterm-256color` 运行（SSH 远程兼容，foot.ini `term=` / alacritty.toml `env.TERM` 有意为之），规则必须写 `xterm-256color:`，写 `foot:`/`alacritty:` 匹配不上。
- 当前规则：`',xterm-256color:RGB:Sync,alacritty:RGB:Sync,foot:RGB:Sync'`；RGB 真彩色（tmux 为 pane 注入 `COLORTERM=truecolor`），Sync 同步输出（foot 1.16.2 与 alacritty 0.13+ 均支持 CSI ?2026）。多个 feature 用冒号连写（tmux 默认值同款语法）。
- Sync 实测有效：mtgpu 驱动下 tmux 内快速滚动（如 `seq 1 50000`）的撕裂明显改善（2026-08-23 用户确认），Sync 规则保留，勿因"理论收益小"移除。
- kitty 已退役（配置移除），不再写 kitty 规则。

## Live 同步
- `~/.tmux.conf` 在 IDE 路径白名单外：直接 cp 会被拒绝；通过 `/tmp` 脚本中转的 cp 会被静默拦截（退出码 0 但目标文件不变，勿用）。
- 2026-08-23 复测：requires_approval + 新终端的 cp 同样失败——新建备份文件名（`~/.tmux.conf.backup.*`）被沙箱直接拒绝；写 `~/.tmux.conf` 静默失败（退出码 0 但文件不变）。此前"单独 cp 命令经用户授权可成功"的方式已失效；live 同步（含备份）应直接把命令交给用户手动执行。

## Session 管理
- 只保留 `tmux-resurrect` 的手动保存/恢复；不启用 `tmux-continuum` 自动保存。
- 销毁行为：`detach-on-destroy` 保持 `on`，退出当前 session 后 detach 当前客户端，不自动切回其它 session。
