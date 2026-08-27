# 钉钉 Wayland 屏幕共享

## 构建 hook
- 使用 `lzl200110/dingtalk-wayland-screenshare` 项目
- 在 `/tmp` 下构建，不污染仓库：
  ```bash
  cmake -S tools/dingtalk-wayland-screenshare -B /tmp/dingtalk-wayland-screenshare-build \
    -GNinja -DCMAKE_BUILD_TYPE=Release
  cmake --build /tmp/dingtalk-wayland-screenshare-build
  install -Dm755 /tmp/dingtalk-wayland-screenshare-build/libdingtalkhook.so \
    ~/.local/lib/dingtalk-wayland-screenshare/build/libdingtalkhook.so
  ```

## 启动入口
- aarch64 日常通过 `Mod+C` 选择钉钉，使用系统 desktop entry 的官方 `Elevator.sh`；该路径已验证无需仓库启动脚本和 hook
- `~/.config/scripts/dingtalk-wayland` 仅作为维护/兼容入口，用于 portal 检查、集中日志、安全 restart 和显式 hook 回退，不是 aarch64 可用性基线
- **aarch64 已实测通过**：保留真实 Wayland 会话环境后，钉钉 8.1.1 会议 SDK 可以直接使用原生 Wayland/PipeWire 捕获，无需注入 `libdingtalkhook.so`；Qt/CEF 界面仍以 `QT_QPA_PLATFORM=xcb` / ozone=x11 运行在 XWayland
- **x86_64 已实测：原生捕获路径不可用，必须走 hook 回退**：钉钉 8.1.0-Release.6021101 的 `libmeeting_sdk.so` 只编译了 X11 capturer（`ldd` 无 wayland/portal/pipewire 依赖，`nm -D` 无 `wl_display`/`pw_main`/`xdp_session` 符号），保留 `XDG_SESSION_TYPE=wayland` 时 tblive 不发 portal CreateSession、pipewire 无 video 节点，共享黑屏只有鼠标；脚本在 x86_64 上默认就走 hook 路径（`uname -m` 判断），无需显式设置 `DINGTALK_FORCE_X11_CAPTURE=1`，直接 `~/.config/scripts/dingtalk-wayland restart` 即可
- aarch64 的可用性关键是 niri 启动后由 `wayland-autostart` 等待 ScreenCast D-Bus 服务，再按顺序重启 portal backend/frontend；仅启动钉钉或仅保证 portal 进程存在不足以解决黑屏
- 启动器本身只等待最多 5 秒并检查 ScreenCast 接口，超时告警后继续启动；不要让应用启动器重启 portal，服务生命周期统一由 `wayland-autostart` 管理
- 默认只 preload 钉钉自带的 `libgbm.so` 和 `plugins/dtwebview/libcef.so`；x86_64 上 8.1.0 包未附带 `libgbm.so`，`ld.so` 报 `cannot be preloaded ... ignored` 属无害告警（官方 `Elevator.sh` 同样会报）
- hook 路径会伪装 `XDG_SESSION_TYPE=x11` 并清除 `WAYLAND_DISPLAY`；x86_64 上脚本默认启用 hook（基于 `uname -m` 判断），aarch64 上默认不启用；可用 `DINGTALK_FORCE_X11_CAPTURE=0/1` 显式覆盖架构默认（优先级最高）

## hook 源码版本约束（x86_64 关键）
- x86_64 + 钉钉 8.1.0 必须使用 6 月 4 日 hook 源码版本（commit `13537e2`，`tools/dingtalk-wayland-screenshare/` 全部 4 个文件）
- 8 月 14 日 commit `3323b5e` 为解决 aarch64 tblive 内嵌 GLib main context 问题改动了 hook 源码，但在 x86_64 上会导致钉钉启动即崩（`CefExecuteProcess exit_code<<0`，hook 未触发，debug log 全空），不可用
- 两版本关键差异（6 月 4 日 → 8 月 14 日）：
  - `hook.cpp` 导出 `XShmAttach`：`return false;` → `XShmAttachHook(); return XShmAttachFunc(dpy, shminfo);`
  - `payload.hpp` mainloop 时序：`create_screencast_session` **之后** `g_main_loop_new` → **之前** `g_main_loop_new`
  - `payload.hpp` 引入 `create_cancellable` + 失败时 `g_main_loop_quit`
  - `payload.cpp` 引入 `kPortalCreateTimeout = 60s` + 超时 `g_cancellable_cancel`
- 6 月 4 日版本机制：导出 `XShmAttach` 返回 false 让钉钉 XShm 初始化失败、回退到 `XGetImage`/`XShmGetImage` hook；portal 初始化由内部 `XShmAttachInner` 在 XShmGetImage 的线程上下文中触发
- live .so SHA-256（6 月 4 日版本）：`744821ac0dabd7fd787e0093dea299ce6e8590b5fd0567bf7460fb03cafbc519`
- 重新编译部署：见上方"构建 hook"，从 dotfiles 根目录一次性 `cmake -S ... -B /tmp/... && cmake --build ... && install ...`

## 排障日志
- 查看 `/tmp/dingtalk-wayland-debug.log`
- 仅在显式启用 hook 的排障路径中，成功日志通常包含：
  - `stream state changed from paused to streaming`
  - `process frame type=3`
  - `mmap frame`
- aarch64 默认原生捕获路径不加载 hook，因此不应以这些 hook 日志判断共享是否成功

## 输入法随机失效（fcitx5#1641，XIM sync 死锁）
- 症状：钉钉运行一段时间后随机"键盘失灵"——聊天框（CEF）所有按键（含纯英文）被吞、候选框不再弹出，重启钉钉才恢复；Qt 层（搜索框等，走自带 fcitx5 DBus 插件）不受影响。
- 归属：社区同款 issue fcitx5#1641（2026-08-12，Open）：xcb-imdkit 1.0.6 XIM sync mode 下，`XIM_DESTROY_IC` 与在途 `XIM_SYNC_REPLY` 微秒级竞争（实测仅差 134µs）→ `_xcb_im_handle_sync_reply` 找不到 IC 提前退出 → `client->sync` 永不复位、后续按键全部入队不派发。钉钉 CEF 109 走 XWayland/XIM（`XMODIFIERS=@im=fcitx`），正好命中；本地 fcitx5 5.1.7（apt）早于且不包含修复，上游 xcb-imdkit 修复尚未合并。
- 临时缓解：失效时重启 fcitx5（死锁状态在 fcitx5 进程内，重启即清零，影响面比重启钉钉小）。
- Workaround（issue 作者实测）：fcitx5 XIM 前端关 sync mode（`xim.cpp:163` `xcb_im_set_use_sync_mode` 改 `false` 重编译）；apt 包本地替换后升级会被覆盖，维护成本高，未采用。
- 实锤手段（下次失效时）：`fcitx5 -d --replace --verbose xim=4` 后观察日志是否出现"连续 `FORWARD_EVENT` 无处理行"特征。
- 后续：等 xcb-imdkit 上游修复合并随发行版更新；届时验证钉钉不再随机失效即可关闭本条。

## 已知问题
- 共享屏幕时必须接受 portal 选择窗口/屏幕的对话框，不能取消
- 依赖 PipeWire、WirePlumber、xdg-desktop-portal
- niri 主会话必须用 `niri --session` 启动；仅 `Exec=niri` 时 `xdg-desktop-portal-gnome` 不会提供 ScreenCast 接口，libportal 返回 `CreateSession failed`
- `wayland-autostart` 必须等待 `org.gnome.Mutter.ScreenCast` 注册后再按 GNOME backend → portal frontend 顺序重启服务；仅检查 portal 进程存在会保留跨会话的 Settings-only 失效状态
- niri 对钉钉设置 2/3 默认列宽和 1.0 不透明度；不强制浮动、聚焦或固定输出，避免影响会议窗口和托盘恢复
- `restart` 通过 `/proc/<pid>/exe` 精确匹配当前用户的钉钉与 tblive，禁止恢复宽泛的 `pkill -f` 命令行匹配
- hook 需要 `DRM_FORMAT_MOD_LINEAR` 作为 modifier（否则遇到 `no more input formats`）
- niri 提供 `SPA_DATA_DmaBuf` 时需要对 `spa_data.fd` 做 `mmap` 并复制到 framebuffer

## 钉钉保持 XWayland 模式（不切原生 Wayland）
- 钉钉 CEF 109 默认 ozone=x11，在 niri Wayland 双屏混 DPI（DP-2 1.25 / eDP-1 2.0）下走 XWayland 会坐标错位，表现为鼠标双光标、点击落不到窗口
- 曾尝试在 Wayland 会话下切原生 Wayland 后端，但实测 CEF 109 Wayland 后端有两个不可接受的缺陷：
  1. **搜索崩溃**：点击搜索创建新 webview 时渲染进程必崩，crash dump 在 `~/.config/DingTalk/dump/8.1.1-Release.6020301/`，日志 `CefExecuteProcess exit_code<<0` + `active_to_render_terminated`
  2. **缩放不动态更新**：多 output 混 DPI 下 `deviceScaleFactor` 不动态更新，内屏 scale 2.0 不生效，`--force-device-scale-factor` 在 Wayland 下无效
- 结论：保持 XWayland 模式，不追加 ozone/wayland 相关 flag；坐标错位通过使用习惯规避（避免窗口跨屏）
- aarch64 屏幕共享已验证可默认走会议 SDK 的原生 Wayland/PipeWire 捕获；`libdingtalkhook.so` 仅保留为显式回退，不作为该架构的可用性基线；x86_64 尚未据此确认
- aarch64 保留 `--disable-gpu-compositing`（与 Chrome 一致，规避 mtgpu 缩放输出撕裂，XWayland 下同样有效）
- Qt 模块（托盘、文件选择器、通知）必须保留 `QT_QPA_PLATFORM=xcb`，钉钉自带 Qt 插件依赖 xcb，切 wayland 会失效
- 测试契约（`tests/niri_wayland_config_test.sh`）：脚本不得出现 `--ozone-platform=wayland` / `--enable-wayland-ime`（`assert_not_contains` 全文件匹配，注释里也不能出现完整 flag 字符串）；必须包含 `CEF 109` / `active_to_render_terminated` / `deviceScaleFactor` / `gpu_flags` / `uname -m` / `--disable-gpu-compositing` 关键字

## 启动命令
```bash
~/.config/scripts/dingtalk-wayland              # 启动（不检查已有实例）
~/.config/scripts/dingtalk-wayland restart      # 重启：精确清理当前用户的钉钉/tblive 后再启动
~/.config/scripts/dingtalk-wayland usage        # 显示帮助
```

钉钉长期运行存在内存累积（主进程可达 3GB+、占用大量 swap），通过 `restart` 子命令定期重启缓解。restart 时先发 SIGTERM，5 秒未退出则 SIGKILL 强杀，然后启动新实例。
