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
- 使用 `~/.config/scripts/dingtalk-wayland` 启动钉钉
- 通过 `LD_PRELOAD` 注入 hook 库，截获 XWayland 的 `XGetImage`/`XShmGetImage`
- 同时 preload 钉钉自带的 `libgbm.so` 和 `plugins/dtwebview/libcef.so`

## 排障日志
- 查看 `/tmp/dingtalk-wayland.log`
- 成功路径日志应包含：
  - `stream state changed from paused to streaming`
  - `process frame type=3`
  - `mmap frame`

## 已知问题
- 共享屏幕时必须接受 portal 选择窗口/屏幕的对话框，不能取消
- 依赖 PipeWire、WirePlumber、xdg-desktop-portal
- hook 需要 `DRM_FORMAT_MOD_LINEAR` 作为 modifier（否则遇到 `no more input formats`）
- niri 提供 `SPA_DATA_DmaBuf` 时需要对 `spa_data.fd` 做 `mmap` 并复制到 framebuffer

## 钉钉保持 XWayland 模式（不切原生 Wayland）
- 钉钉 CEF 109 默认 ozone=x11，在 niri Wayland 双屏混 DPI（DP-2 1.25 / eDP-1 2.0）下走 XWayland 会坐标错位，表现为鼠标双光标、点击落不到窗口
- 曾尝试在 Wayland 会话下切原生 Wayland 后端，但实测 CEF 109 Wayland 后端有两个不可接受的缺陷：
  1. **搜索崩溃**：点击搜索创建新 webview 时渲染进程必崩，crash dump 在 `~/.config/DingTalk/dump/8.1.1-Release.6020301/`，日志 `CefExecuteProcess exit_code<<0` + `active_to_render_terminated`
  2. **缩放不动态更新**：多 output 混 DPI 下 `deviceScaleFactor` 不动态更新，内屏 scale 2.0 不生效，`--force-device-scale-factor` 在 Wayland 下无效
- 结论：保持 XWayland 模式，不追加 ozone/wayland 相关 flag；坐标错位通过使用习惯规避（避免窗口跨屏）
- `libdingtalkhook.so` 在 XWayland 下仍可截获 `XGetImage`/`XShmGetImage`，屏幕共享在 niri 会话下继续生效（无需切到 X11 会话）
- aarch64 保留 `--disable-gpu-compositing`（与 Chrome 一致，规避 mtgpu 缩放输出撕裂，XWayland 下同样有效）
- Qt 模块（托盘、文件选择器、通知）必须保留 `QT_QPA_PLATFORM=xcb`，钉钉自带 Qt 插件依赖 xcb，切 wayland 会失效
- 测试契约（`tests/niri_wayland_config_test.sh`）：脚本不得出现 `--ozone-platform=wayland` / `--enable-wayland-ime`（`assert_not_contains` 全文件匹配，注释里也不能出现完整 flag 字符串）；必须包含 `CEF 109` / `active_to_render_terminated` / `deviceScaleFactor` / `gpu_flags` / `uname -m` / `--disable-gpu-compositing` 关键字

## 启动命令
```bash
~/.config/scripts/dingtalk-wayland              # 启动（不检查已有实例）
~/.config/scripts/dingtalk-wayland restart      # 重启：先 pkill 当前用户名下钉钉进程再启动
~/.config/scripts/dingtalk-wayland usage        # 显示帮助
```

钉钉长期运行存在内存累积（主进程可达 3GB+、占用大量 swap），通过 `restart` 子命令定期重启缓解。restart 时先发 SIGTERM，5 秒未退出则 SIGKILL 强杀，然后启动新实例。
