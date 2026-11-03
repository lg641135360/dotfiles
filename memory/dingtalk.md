# 钉钉 Wayland 屏幕共享

## 启动入口
- 日常通过 `Mod+C` 选择钉钉，由用户级 desktop entry（`.config/linux/desktop-entries/com.alibabainc.dingtalk.desktop`）以 `env GTK_IM_MODULE=fcitx /opt/apps/com.alibabainc.dingtalk/files/Elevator.sh %u` 调用官方 `Elevator.sh`；无需仓库启动脚本
- `~/.config/scripts/dingtalk-wayland` 只做排障：`status` 检查会话 / PipeWire / ScreenCast portal / 钉钉进程，`stop|kill` 精确清理当前用户的钉钉/tblive。不再启动钉钉
- **aarch64 + 8.1.1 已实测通过**：保留真实 Wayland 会话环境后，会议 SDK 可以直接使用原生 Wayland/PipeWire 捕获；Qt/CEF 界面仍以 `QT_QPA_PLATFORM=xcb` / ozone=x11 运行在 XWayland
- **x86_64 + 8.2.8.260904001 已实测通过**：`libmeeting_sdk.so` 已编入 WebRTC Wayland/PipeWire capturer（`base_capturer_pipewire.cc` / `screencast_portal.cc`，运行时 `dlopen libpipewire-0.3.so.0`），保留 `XDG_SESSION_TYPE=wayland` 即可弹出系统选屏框并正常共享。旧版 `8.1.0` / `8.2.8.260818002` 只编译了 X11 capturer，那才需要 hook；当前仓库已删除 `tools/dingtalk-wayland-screenshare`
- 可用性关键是 niri 启动后由 `wayland-autostart` 等待 ScreenCast D-Bus 服务，再按顺序重启 portal backend/frontend；仅启动钉钉或仅保证 portal 进程存在不足以解决黑屏
- 不要让排障脚本重启 portal，服务生命周期统一由 `wayland-autostart` 管理
- 官方 `Elevator.sh` 会 preload 钉钉自带的 `libgbm.so` 和 `plugins/dtwebview/libcef.so`；部分包未附带 `libgbm.so` 时 `ld.so` 报 `cannot be preloaded ... ignored` 属无害告警

## 8.2.8 execstack
- 现象（2026-08-29，旧包 `8.2.8.260818002`）：点加入会议无反应；日志 `[tblive] media app occur exception` → `tblive can't be launched beyond 10s`，tblive 子进程报 `GetLibEntry instance failed` / `error: entry is null`
- 根因：旧包 `libconference_new.so` ELF `GNU_STACK` 标记为 **RWE**；内核 `7.0.0-30-generic` 拒绝为共享库启用可执行栈 → dlopen 失败
- `8.2.8.260904001` 官方已修：关键库 `GNU_STACK` 为 **RW**，并附带 `clear_execstack.sh`。新包无需再手工打补丁

## CEF 网页界面无法输入中文 / 输入法随机失效（已通过进程级 `GTK_IM_MODULE=fcitx` 走 D-Bus 根治）
- 架构分流（2026-11-03 实测定位）：钉钉主进程混合了 **Qt5 原生组件**（顶部搜索框等，加载自带 `platforminputcontexts/libfcitx5platforminputcontextplugin.so` 走 D-Bus）与 **CEF 109 网页视图**（聊天输入框、内嵌文档等，X11 下通过系统 `libgtk-3.so.0` 的 `ui/gtk/input_method_context_impl_gtk.cc` 创建 `GtkIMContext`）。
- 根因：Wayland 会话全局清除了 `GTK_IM_MODULE`（且 `gsettings` `gtk-im-module` 为空），导致运行在 XWayland（GDK X11 后端）下的 CEF 无法加载 `im-fcitx5.so`，按 `zh_CN` locale 回退加载了 `/usr/lib/x86_64-linux-gnu/gtk-3.0/3.0.0/immodules/im-xim.so`（XIM 协议）。走 `im-xim.so` 有两个严重缺陷：
  1. **`xwayland-satellite` 崩溃重启后 XIM 永久断连**：`xwayland-satellite` 0.8.3（及最新 `main`）在 `src/server/mod.rs:1610`（`create_popup` 对父窗口 `&SurfaceRole` 直接 `.unwrap()`，上游 issue #188 Open）遇到钉钉会议关闭时的 tooltip 弹窗会 panic 退出（exit 101）；niri 随后按需重拉新的 `xwayland-satellite :1`，但不会通知已运行的 fcitx5 重连 `:1`（fcitx5 日志 `Disconnected from X11 Display :1` 后无 X11 连接，`DISPLAY=:1 xprop -root XIM_SERVERS` 为空），导致之后启动的钉钉 CEF 界面完全无法输入中文，而走 D-Bus 的 Qt 搜索框仍正常。
  2. **fcitx5#1641 XIM sync 竞争死锁**：`XIM_DESTROY_IC` 与在途 `XIM_SYNC_REPLY` 微秒级竞争会导致 `client->sync` 永不复位，聊天框所有按键被吞。
- **修复（2026-11-03 落地）**：新增用户级 `.config/linux/desktop-entries/com.alibabainc.dingtalk.desktop`，以 `Exec=env GTK_IM_MODULE=fcitx /opt/apps/com.alibabainc.dingtalk/files/Elevator.sh %u` 启动钉钉。
  - CEF 的 `libgtk-3` 改加载系统 `fcitx5-frontend-gtk3` 的 `im-fcitx5.so`（链接 `libFcitx5GClient.so.2`），与 Qt 层一样**全链路走 D-Bus（`org.fcitx.Fcitx5`）**，彻底脱离 X11/XIM，不受 `xwayland-satellite` 重启或 XIM sync 死锁影响。
  - `GTK_IM_MODULE=fcitx` 仅限于钉钉进程环境，不污染 systemd 用户环境或 fcitx5 自身进程环境，不会触发 fcitx5 的 Wayland 自检警告。
- 若其它纯 XIM 应用因 `xwayland-satellite` 重启丢失连接，可免重启恢复 fcitx5 的 X11 连接：`busctl --user call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 OpenX11Connection s ":1"`。

## @ 候选框出现后立即消失（已修复：弹窗不抢焦点，2026-08-29 定案；DMS 机器见 2026-09-28 条目）
- 症状：钉钉聊天输入 `@` 后成员候选框出现即消失；鼠标悬停在候选框上/完全不动鼠标都一样，与鼠标无关。曾怀疑 niri `focus-follows-mouse`，禁用后问题依旧（无关）。
- 根因（`niri msg event-stream` 实测）：@ 弹窗是**受管 XWayland 窗口**（非 override-redirect）。niri 对新 map 窗口默认给键盘焦点 → 钉钉弹窗（Qt/CEF）收到意外 FocusIn 后自毁（伴随弹窗重建/乒乓），表现为候选框闪现即消失。**修复：niri window-rule 对钉钉 app-id 整体 `open-focused false`**——该属性只作用于新 map 窗口，已开主窗口不受影响；所有新弹窗从出生起不持有焦点（`is_focused: false` + `focus_timestamp: None`，X11 弹窗「不带输入焦点」的正常模式），候选框稳定显示。
- 实验迭代记录：第一版按 title 匹配 `MainMenuPanelView` 无效——钉钉弹窗的 X 窗口标题不稳定（实测同一场景轮换 MainMenuPanelView / Form / com.alibabainc.dingtalk / 钉钉 / 分享的图片），必须用 app-id 级匹配。代价：重启钉钉或新开钉钉窗口时不自动聚焦，需手动点一下。
- 判别工具：`niri msg event-stream` 后台记录到 /tmp 后复现，看弹窗 `is_focused` 与开/关时序即可区分 niri 焦点行为与应用层自毁；日志为纯文本格式（事件名形如 `Window opened or changed:`，非 JSON）。
- **2026-09-28 回归与再修复（x64 DMS）**：DMS 重新生成的 live `~/.config/niri/config.kdl` 只 include `dms/*.kdl`，上面这条仓库 `common.kdl` 规则不再被加载，@ 候选框再次闪现即消失；`dms config windowrules list niri` 的生效规则集里当时没有任何 dingtalk 条目。钉钉同期已升到 `8.3.1-Release.260917001`，规则恢复后 @ 正常，排除版本因素。修复走 DMS 自管通道（不会被子系统重生成覆盖）：`dms config windowrules add niri '{"name":"DingTalk popups keep keyboard focus","matchCriteria":{"appId":"^com\\.alibabainc\\.dingtalk$"},"actions":{"openFocused":false},"enabled":true}'` → id `wr_1790561384874988781`，写入 `~/.config/niri/dms/windowrules.kdl`；撤销用 `dms config windowrules remove niri wr_1790561384874988781`。实测 9 个钉钉弹窗（title `Form`）全部 `is_focused: false` + `focus_timestamp: None`，主窗口焦点不变。同日补回弹窗浮动（仓库 `exclude title` 语义）：`wr_1790561738805679306`（appId → `open-floating true`）+ `wr_1790561738813023192`（appId + title `^钉钉|钉钉$` → `open-floating false`，必须排在通用浮动规则之后，后者覆盖前者）；实测弹窗 `is_floating: true`、浮层位置 `(852, 383)`，主窗口保持平铺，`Mod+F` 展开主窗口后 @ 候选框仍作为浮层可见。
- **2026-10-06 起三条规则由仓库脚本幂等重建**：`dms-niri-setup`（`install.sh` 在 `niri` + `dms` 机器上自动调用）按 appId + action 查重后补 `dms config windowrules add niri`，顺序固定为「弹窗不抢焦点 → 弹窗浮动 → 主窗口平铺」；新增机器不再需要手工敲三条命令。规则集状态用 `dms config windowrules list niri` 的 `dmsStatus.included` 判断（false 说明 `dms/windowrules.kdl` 没被 config.kdl include）。

## 已知问题
- 共享屏幕时必须接受 portal 选择窗口/屏幕的对话框，不能取消
- 依赖 PipeWire、WirePlumber、xdg-desktop-portal
- niri 主会话必须用 `niri --session` 启动；仅 `Exec=niri` 时 `xdg-desktop-portal-gnome` 不会提供 ScreenCast 接口
- `wayland-autostart` 必须等待 `org.gnome.Mutter.ScreenCast` 注册后再按 GNOME backend → portal frontend 顺序重启服务；仅检查 portal 进程存在会保留跨会话的 Settings-only 失效状态
- niri 对钉钉设置 2/3 默认列宽和 1.0 不透明度；除主窗口（标题「钉钉」，`exclude ^钉钉|钉钉$`）外其余钉钉 XWayland 窗口全部 `open-floating true` 浮动（2026-08-29 四次迭代定稿：表情面板等 resizable 弹窗平铺成新列后恢复 exclude 方案，Wayland 不翻译 X11 EWMH 类型提示是根因）；不强制聚焦或固定输出。niri 侧已对钉钉 app-id 整体 `open-focused false`（修复 @ 候选框自毁，见上节）
- `dingtalk-wayland stop` 通过 `/proc/<pid>/exe` 精确匹配当前用户的钉钉与 tblive，禁止恢复宽泛的 `pkill -f` 命令行匹配

## 钉钉保持 XWayland 模式（不切原生 Wayland）
- 钉钉 CEF 109 默认 ozone=x11，在 niri Wayland 双屏混 DPI（DP-2 1.25 / eDP-1 2.0）下走 XWayland 会坐标错位，表现为鼠标双光标、点击落不到窗口
- 曾尝试在 Wayland 会话下切原生 Wayland 后端，但实测 CEF 109 Wayland 后端有两个不可接受的缺陷：
  1. **搜索崩溃**：点击搜索创建新 webview 时渲染进程必崩，crash dump 在 `~/.config/DingTalk/dump/8.1.1-Release.6020301/`，日志 `CefExecuteProcess exit_code<<0` + `active_to_render_terminated`
  2. **缩放不动态更新**：多 output 混 DPI 下 `deviceScaleFactor` 不动态更新，内屏 scale 2.0 不生效，`--force-device-scale-factor` 在 Wayland 下无效
- 结论：保持 XWayland 模式，不追加 ozone/wayland 相关 flag；坐标错位通过使用习惯规避（避免窗口跨屏）
- aarch64 与 x86_64 屏幕共享均已验证可默认走会议 SDK 的原生 Wayland/PipeWire 捕获
- aarch64 保留 `--disable-gpu-compositing`（与 Chrome 一致，规避 mtgpu 缩放输出撕裂，XWayland 下同样有效）
- Qt 模块（托盘、文件选择器、通知）必须保留 `QT_QPA_PLATFORM=xcb`，钉钉自带 Qt 插件依赖 xcb，切 wayland 会失效
- 测试契约（`tests/wayland_scripts_test.sh` / `tests/dingtalk_wayland_test.sh`）：排障脚本不得启动钉钉、不得出现 `--ozone-platform=wayland` / `--enable-wayland-ime`；XWayland 约束写在 niri README（`CEF 109` / `active_to_render_terminated` / `deviceScaleFactor` / `--disable-gpu-compositing`）

## 排障命令
```bash
~/.config/scripts/dingtalk-wayland status       # 检查会话 / PipeWire / ScreenCast / 钉钉进程
~/.config/scripts/dingtalk-wayland stop         # 精确清理当前用户的钉钉/tblive
~/.config/scripts/dingtalk-wayland usage        # 显示帮助
```

钉钉长期运行存在内存累积（主进程可达 3GB+、占用大量 swap）。需要清进程时用 `stop`：先发 SIGTERM，5 秒未退出则 SIGKILL 强杀。清理后用 Mod+C / 官方 `Elevator.sh` 重新启动。
