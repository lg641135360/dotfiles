# tmux 偏好

## 状态栏
- 左侧隐藏 session 名，避免 OMX/自动生成长 session 名挤占 tab 区域。
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
- 窗口/会话导航使用内置能力：`C-a w` → `choose-tree -Zw` 树状选择器，`C-a Tab` → 上一个窗口。

## Session 管理
- 只保留 `tmux-resurrect` 的手动保存/恢复；不启用 `tmux-continuum` 自动保存。
- 销毁行为：`detach-on-destroy` 保持 `on`，退出当前 session 后 detach 当前客户端，不自动切回其它 session。
