# 钉钉 Wayland 屏幕共享

## 启动入口
- 日常通过 `Mod+C` 选择钉钉，使用系统 desktop entry 的官方 `Elevator.sh`；该路径已验证无需仓库启动脚本
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

## 输入法随机失效（fcitx5#1641，XIM sync 死锁）
- 症状：钉钉运行一段时间后随机"键盘失灵"——聊天框（CEF）所有按键（含纯英文）被吞、候选框不再弹出，重启钉钉才恢复；Qt 层（搜索框等，走自带 fcitx5 DBus 插件）不受影响。
- 归属：社区同款 issue fcitx5#1641（2026-08-12，Open）：xcb-imdkit 1.0.6 XIM sync mode 下，`XIM_DESTROY_IC` 与在途 `XIM_SYNC_REPLY` 微秒级竞争（实测仅差 134µs）→ `_xcb_im_handle_sync_reply` 找不到 IC 提前退出 → `client->sync` 永不复位、后续按键全部入队不派发。钉钉 CEF 109 走 XWayland/XIM（`XMODIFIERS=@im=fcitx`），正好命中；本地 fcitx5 5.1.7（apt）早于且不包含修复，上游 xcb-imdkit 修复尚未合并。
- 临时缓解：失效时重启 fcitx5（死锁状态在 fcitx5 进程内，重启即清零，影响面比重启钉钉小）。
- Workaround（issue 作者实测）：fcitx5 XIM 前端关 sync mode（`xim.cpp:163` `xcb_im_set_use_sync_mode` 改 `false` 重编译）；apt 包本地替换后升级会被覆盖，维护成本高，未采用。
- 实锤手段（下次失效时）：`fcitx5 -d --replace --verbose xim=4` 后观察日志是否出现"连续 `FORWARD_EVENT` 无处理行"特征。
- 后续：等 xcb-imdkit 上游修复合并随发行版更新；届时验证钉钉不再随机失效即可关闭本条。

## @ 候选框出现后立即消失（已修复：弹窗不抢焦点，2026-08-29 定案）
- 症状：钉钉聊天输入 `@` 后成员候选框出现即消失；鼠标悬停在候选框上/完全不动鼠标都一样，与鼠标无关。曾怀疑 niri `focus-follows-mouse`，禁用后问题依旧（无关）。
- 根因（`niri msg event-stream` 实测）：@ 弹窗是**受管 XWayland 窗口**（非 override-redirect）。niri 对新 map 窗口默认给键盘焦点 → 钉钉弹窗（Qt/CEF）收到意外 FocusIn 后自毁（伴随弹窗重建/乒乓），表现为候选框闪现即消失。**修复：niri window-rule 对钉钉 app-id 整体 `open-focused false`**——该属性只作用于新 map 窗口，已开主窗口不受影响；所有新弹窗从出生起不持有焦点（`is_focused: false` + `focus_timestamp: None`，X11 弹窗「不带输入焦点」的正常模式），候选框稳定显示。
- 实验迭代记录：第一版按 title 匹配 `MainMenuPanelView` 无效——钉钉弹窗的 X 窗口标题不稳定（实测同一场景轮换 MainMenuPanelView / Form / com.alibabainc.dingtalk / 钉钉 / 分享的图片），必须用 app-id 级匹配。代价：重启钉钉或新开钉钉窗口时不自动聚焦，需手动点一下。
- 判别工具：`niri msg event-stream` 后台记录到 /tmp 后复现，看弹窗 `is_focused` 与开/关时序即可区分 niri 焦点行为与应用层自毁；日志为纯文本格式（事件名形如 `Window opened or changed:`，非 JSON）。

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
