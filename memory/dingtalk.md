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
- x86_64 + 钉钉 8.1.0/8.2.8 必须使用修复后的 hook 源码（8.2.8 的 `libmeeting_sdk.so` 同样只编译了 X11 capturer：`ldd` 无 wayland/portal/pipewire 依赖、`nm -D` 无 `wl_display`/`pw_main`/`xdp_session` 符号，2026-08-29 实测），脚本按 `uname -m` 默认走 hook
- **2026-08-29 修复（必须保留）**：① `payload.hpp` `on_param_changed` 里 `spa_debug_type_find_name()` 对未知 param id 返回 NULL，直接构造 `std::string` 会 abort（`basic_string: construction from null is not valid`）→ tblive 崩溃、共享即退会；apt niri 26.04 的 pipewire 流会发送 hook 不认识的 param id 才踩中。修复为 null 检查 + 回退 `unknown param id: <id>`。② pw 资源销毁移入 loop 线程 + `request_close_session` 在 gio quit 前调度 `xdp_session_close`（详见下方"停止共享后图标不灭"条目——两层时序 bug）
- 6 月 4 日 commit `13537e2` 为旧稳定基线；8 月 14 日 commit `3323b5e` 在 x86_64 上钉钉启动即崩不可用；后续 `f787a48`（x86_64 稳定版）、`e1c9686`（PipeWire 线程事件驱动化）是当前 live 在用版本，但需叠加上面 2026-08-29 的两处时序修复（null 保护 + 销毁/close 时序）
- live .so SHA-256（e1c9686 + 2026-08-29 三处修复）：`903fc7abf1cef6a0bd081e8a5c411d011a87db0b8b9b07d3625919fa50ee0c37`
- 重新编译部署：见上方"构建 hook"；构建依赖 `libportal-dev` 已由 apt 提供（0.9.1，原 Nix 迁移后补装），OpenCV dev 用 apt `libopencv-dev` 4.10.0
- 从 dotfiles 根目录一次性 `cmake -S ... -B /tmp/... && cmake --build ... && install ...`

## 8.2.8 execstack 补丁（内核 7.0.0-30 必须）
- 现象（2026-08-29）：点加入会议无反应；日志 `[tblive] media app occur exception` → `tblive can't be launched beyond 10s`，tblive 子进程报 `GetLibEntry instance failed` / `error: entry is null`
- 根因：钉钉 8.2.8 的 `libconference_new.so` ELF `GNU_STACK` 标记为 **RWE**（可执行栈，打包缺陷）；8 月 29 日 Nix→apt 迁移期间安装的新内核 `7.0.0-30-generic` 拒绝为共享库启用可执行栈 → dlopen 失败。与 hook、启动脚本无关（无 hook、官方 Elevator.sh 同样失败）
- 修复：python 字节补丁把 PT_GNU_STACK 的 PROT_EXEC 位清零（RWE→RW），备份在 `/opt/apps/com.alibabainc.dingtalk/files/8.2.8-Release.260818002/libconference_new.so.bak-20260829`
- **钉钉包更新/重装后补丁会被覆盖，需重新执行**（脚本模式同 memory）：定位 `Elf64_Phdr` 中 `p_type == 0x6474e551 (PT_GNU_STACK)`，将 `p_flags` 的最低位清零；补丁脚本曾存于 `/tmp/fix_execstack.py`（临时文件，可能已清理，按此描述可重写）
- 验证：`readelf -lW` 显示 `GNU_STACK ... RW`；`LD_LIBRARY_PATH=<钉钉目录> python3 -c "import ctypes; ctypes.CDLL('./libconference_new.so')"` 成功

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
- **停止共享后 waybar privacy 图标不灭 / tblive 残留——已修复（2026-08-29，两层 hook 时序 bug）**：
  - 现象链：停止共享（或结束会议）后 tblive 残留、portal 代理的 pipewire 流不回收（client `app=tblive` + `Stream/Input/Video` node + niri `Stream/Output/Video` 持续推帧）、waybar `privacy` 模块 `screenshare`/`audio-in` 图标不灭；portal 流甚至跨 tblive 重启残留（session 未关时 portal 侧持续持有）
  - 根因 A（pw 销毁死锁）：`e1c9686` 事件驱动化把 `pw_thread_loop` 换成裸 `pw_main_loop` 后，`PipewireScreenCast` 析构（pw_stream_disconnect/destroy/core_disconnect 需与 mainloop 线程同步）被推迟到 loop 线程已退出的 hook 清理阶段执行 → 死锁 → tblive 退出流程卡死（主线程 futex，23 线程 sleeping，`module-rt` 悬挂）
  - 根因 B（session close 丢失）：`xdp_session_close` 是 GDBus 异步调用，旧顺序先 `g_main_loop_quit` 杀 gio mainloop、后（析构）close → 消息在无人迭代的 GMainContext 上永远发不出去 → portal session 永不关闭 → 流持续存在
  - 修复：① pw 资源销毁移入 loop 线程（stop 循环退出后、线程 return 前调 `destroy_pw_objects_in_loop_thread()`，各原子指针置 null；析构改判空跳过防死锁）；② `request_close_session()` 在 `StopGIOLoop` **之前**经 `g_main_context_invoke` 调度到 gio 线程执行 `xdp_session_close`，并以 `session_close_done` 原子做 1s 有界等待（实测 10ms 完成）
  - 修复后验证：debug log `pw objects destroyed in loop thread` → `xdp_session_close invoked in gio context` → `waited 10ms, done=true`；pw 层残留 0、tblive 正常退出、图标熄灭
  - **钉钉侧遗留（hook 无抓手）**：8.2.8 停止共享按钮有时不触发捕获清理（连 `StopShareScreen`/`export XShmDetach called` 日志都没有，SDK 信令链路断裂），此时只能结束会议（static 析构 → XShmDetach → hook 完整清理）或精确 kill tblive 兜底；建议向钉钉反馈
  - 诊断技巧：此类问题用 `pw-dump` 对比干净基线看 portal 代理对象（client 带 `pipewire.access.portal.app_id`），`/proc/<tblive-pid>/task/*/comm` 看 pw 线程是否已退出判断卡点

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
