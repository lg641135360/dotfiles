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

## 启动命令
```bash
~/.config/scripts/dingtalk-wayland
```
