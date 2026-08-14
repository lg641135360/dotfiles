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
- aarch64 的可用性关键是 niri 启动后由 `wayland-autostart` 等待 ScreenCast D-Bus 服务，再按顺序重启 portal backend/frontend；仅启动钉钉或仅保证 portal 进程存在不足以解决黑屏
- 启动器本身只等待最多 5 秒并检查 ScreenCast 接口，超时告警后继续启动；不要让应用启动器重启 portal，服务生命周期统一由 `wayland-autostart` 管理
- 默认只 preload 钉钉自带的 `libgbm.so` 和 `plugins/dtwebview/libcef.so`
- `DINGTALK_FORCE_X11_CAPTURE=1` 才注入 hook、伪装 `XDG_SESSION_TYPE=x11` 并清除 `WAYLAND_DISPLAY`；该路径仅用于排障
- 上述“无需 hook”结论目前只在 aarch64 环境完成实际共享验证，不外推到 x86_64；其他架构应单独验证后再决定是否保留 hook

## 排障日志
- 查看 `/tmp/dingtalk-wayland-debug.log`
- 仅在显式启用 hook 的排障路径中，成功日志通常包含：
  - `stream state changed from paused to streaming`
  - `process frame type=3`
  - `mmap frame`
- aarch64 默认原生捕获路径不加载 hook，因此不应以这些 hook 日志判断共享是否成功

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
