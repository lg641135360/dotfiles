# 桌面与工具偏好

## Picom
- 给 `utility/dialog` 恢复轻阴影，在 `shadow-exclude` 里排除 `tblive` 等辅助条窗口。
- Ubuntu x64 + picom v10 环境：`shadow-exclude` 里的 `_GTK_FRAME_EXTENTS@` 会触发 `c2_parse_target` 解析错误；不在 Ubuntu x64 配置里保留它。
- 不使用 `opacity-rule` 把 Alacritty/kitty 强制拉回 100% opacity；终端使用自身透明度使 blur 可见；浏览器/Thunderbird 等窗口按需保持 100%。
- 美观调优优先只改当前平台，不强求 `ubuntu_x64`/`arch_x64`/`arch_aarch64` 三份配置同步收口，除非用户明确要求。
- Ubuntu aarch64 为降负载已走低占用方案：关 blur（`method = "none"`）、阴影 radius 6/opacity 0.3、圆角 8px；经实测 picom CPU 从 15.2% 降到 6.7%。

## 锁屏
- AwesomeWM（X11）锁屏脚本与自动锁屏细节见 `memory/awesome.md`；niri/Wayland 锁屏使用 `swaylock`，相关偏好见 `memory/niri.md`。

## Snipaste
- Snipaste 候选路径、裸 `F1` 热键、KDE kglobalshortcutsrc 修复等与 Awesome 桌面强相关的细节见 `memory/awesome.md`。

## Ubuntu aarch64 外接屏
- 内屏 `2880x1800@120Hz` 主屏；外接屏在 Ubuntu aarch64 上默认显式固定为 `2560x1440@59.95Hz` 放笔记本右侧，避免误落到 `3840x2160@30` 或 `1920x2160` 这类特殊模式。
- `Xft.dpi: 192` 是合适基线；不为了外接屏降低全局 DPI。
- 外接屏方案不要改 Awesome per-screen DPI 或 rofi focused-screen `ROFI_SCALE`。

## 其它
- redshift 处理、Ubuntu aarch64 系统二进制优先、Linuxbrew 遮蔽处理、scripts/ helper 部署等通用工作流与环境偏好见 `memory/organizing_preferences.md`。

## fcitx / GTK_IM_MODULE 排查
- fcitx "建议取消设置 GTK_IM_MODULE" 警告的原因是 Wayland 下 GTK 自带 text-input 协议，不需要 `GTK_IM_MODULE=fcitx`
- 注入链排查步骤：
  1. `systemctl --user show-environment` 查看 systemd 用户环境
  2. `~/.config/environment.d/*.conf` — systemd generator 自动加载
  3. `~/.xprofile` — 登录管理器导入
  4. `niri-session` 中的 `systemctl --user import-environment` — 将 shell 环境导入 systemd
- 修复方法：
  - `environment.d/` 文件中移除或注释 GTK_IM_MODULE 行
  - `.conf` 后缀的备份文件必须重命名为 `.bak`，否则被 systemd generator 误解析
  - 当前会话通过 `dbus-update-activation-environment --systemd GTK_IM_MODULE=` 将值设空
- niri/Wayland 下 Satty 启动前应 `unset GTK_IM_MODULE`，让 GTK4 走 Wayland text-input/fcitx 路径
- Wayland autostart 中统一 `unset GTK_IM_MODULE`，`export QT_IM_MODULE=fcitx` 等 Qt 应用仍需

### Rime（fcitx5-rime）在 MediaTek 定制 librime 上
- MediaTek 定制 librime **不支持 lua 插件**（`lua_processor`/`lua_translator`/`lua_filter` 均无法创建），而 rime-ice 全系 schema（`rime_ice`/`double_pinyin_*`）都依赖 lua 组件 → 启动即报错。
- 已按「方案 3a 剥离 lua」处理 live `~/.local/share/fcitx5/rime/rime_ice.schema.yaml`：engine 移除全部 lua 组件与对应配置块/recognizer 规则/开关，并去掉 corrector 用的 `［］comment_format`。基本拼音、词库、候选排序正常；失去以词定字、日期/农历/大写数字/计算器、错音提示、英文自动大写、v 模式、长词优先、部件拆字辅码、置顶候选项等 lua 扩展。
- **改完 schema 必须重建过期 .bin**：`rime_deployer --build` 只更新 prism/schema，`table.bin`/`reverse.bin` 可能仍是旧文件 → prism 与字典 .bin 不一致会导致 fcitx5 加载 rime 时 SIGSEGV 崩溃（栈在 `SchemaUpdate::Run → Config::GetString → ConfigData::Traverse`）。安全做法：删除 `build/` 下对应 schema 的 `{prism,table,reverse}.bin` 再 `rime_deployer --build`，最后 `pkill fcitx5 && fcitx5 -d --replace`。
- 该 Rime 目录是 rime-ice 的独立 git clone，**不属于 dotfiles 仓库**；改动需直接在 live 做并自行管理 git。若日后换带 lua 的 librime 可 `git checkout` 恢复。
- 备选方案 B：Flatpak 版 Fcitx5+Rime（官方维护、自带 librime-lua）可完整跑 rime-ice，但需迁移配置路径并改动 `wayland-autostart`/niri 环境，联动大，当前未采用。


niri / Wayland 与 Waybar 相关偏好已拆分到 `memory/niri.md` 和 `memory/waybar.md`。
