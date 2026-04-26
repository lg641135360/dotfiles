# Trace

## 2026-04-26

- 目的：按用户确认直接隐藏 tmux 状态栏左侧的 session 名，避免 OMX 自动生成的长 session 名出现在 tab 列表左边。
- 已做：先按项目约束读取 `memory/organizing_preferences.md` 与 `logs/trace.md`，再按 TDD 修改 `tests/tmux_status_test.sh`，要求 `status-left` 为空、`status-left-length` 为 0，并且隐藏配置必须放在 TPM 之后以覆盖 Catppuccin 默认 session 模块；确认旧配置因缺少 `set -g status-left ""` 失败。随后修改 `.config/shared/tmux/.tmux.conf`，移除前置 `@catppuccin_status_session` 左侧模块，改为在 TPM 后设置 `status-left ""` 与 `status-left-length 0`；同步更新 `.config/shared/tmux/README.md` 和 `memory/organizing_preferences.md`，记录“左侧隐藏 session 名”的偏好。
- 后续：如果后续仍觉得 tab 区域拥挤，优先继续缩短单个 tab 的路径显示长度，而不是重新启用左侧 session 名。

- 目的：按用户反馈继续优化 tmux 状态栏，让每个 tab 标题更短、更有用，并去掉当前 shell/application 这类噪音信息。
- 已做：先按项目约束读取 `memory/organizing_preferences.md` 与 `logs/trace.md`，再用 TDD 扩展 `tests/tmux_status_test.sh`，新增对“右侧不显示 application、tab 标题走短路径/远程辅助脚本、helper 可格式化本地路径与远程名路径、README 文档同步”的断言，并确认旧配置先失败。随后新增 `.config/shared/tmux/tmux-tab-title`：本地 pane 显示截断短路径，SSH/终端标题能提供远程上下文时显示 `远程名:路径`，并通过 `TMUX_TAB_TITLE_MAX` 控制最大长度；修改 `.config/shared/tmux/.tmux.conf` 让 Catppuccin window text 调用该 helper，同时把 `status-right` 收敛为 Prefix/Copy 状态 + 日期时间，移除 `@catppuccin_status_application`。同步更新 `install.sh`，确保 helper 会随 tmux 配置安装到 `~/.config/tmux/tmux-tab-title`，并更新 README 与记忆文件记录新的状态栏偏好。
- 后续：如果还要继续提高远程路径准确度，可在远程 shell 侧补 OSC 7 / 终端标题更新；当前本地仅能稳定识别 SSH 目标名和 tmux 已收到的路径信息，无法凭空读取远程 shell 当前目录。

- 目的：继续细调 tmux 的日常导航体验，在不增加插件、不改变现有状态栏显示效果的前提下补齐 session/window/pane 跳转入口。
- 已做：按 TDD 先扩展 `tests/tmux_status_test.sh`，新增对 `bind w choose-tree -Zw`、`bind Tab last-window` 以及 README 快捷键说明的断言，并确认旧配置因缺少 `choose-tree` 绑定而失败。随后修改 `.config/shared/tmux/.tmux.conf`，新增 `C-a w` 打开 tmux 内置树状选择器、`C-a Tab` 回到上一个窗口；同步更新 `.config/shared/tmux/README.md` 和 `memory/organizing_preferences.md`，记录“优先使用 tmux 内置导航能力，不增加插件”的偏好。
- 后续：如果继续优化 tmux 观感/体验，可考虑是否增加一个轻量 popup 命令菜单或常用会话 attach helper，但应先保持当前内置快捷键基线稳定，并避免一次引入过多新交互。

- 目的：继续按用户确认落地 tmux 日常体验增强，在不增加插件、不继续堆状态栏信息的前提下提升分屏、嵌套 tmux、复制和 pane 调整手感。
- 已做：基于上一轮已确认的“低风险 tmux 日常体验增强”设计，按 TDD 扩展 `tests/tmux_status_test.sh`，新增对 `set-clipboard on`、`C-a C-a` 发送 prefix、分屏/新窗口继承 `#{pane_current_path}`、`H/J/K/L` 调整 pane 大小，以及 Catppuccin pane 边框颜色配置的断言，并先运行确认旧配置会失败。随后修改 `.config/shared/tmux/.tmux.conf`：启用 `set-clipboard on`，新增 `bind C-a send-prefix`，让 `bind c`、`bind |`、`bind -` 都带 `-c "#{pane_current_path}"`，新增 `H/J/K/L` 每次 5 格 resize，并通过 `@catppuccin_pane_border_style` / `@catppuccin_pane_active_border_style` 让普通/活动 pane 边框使用 Catppuccin 主题色。同步更新 `.config/shared/tmux/README.md` 与 `memory/organizing_preferences.md` 记录新的 tmux 交互偏好。最后把仓库 tmux 配置同步到 live `~/.tmux.conf` 并执行 `tmux source-file`，确认 live 里 `set-clipboard=on`、pane border 颜色、以及新增 key binding 都已经生效。
- 后续：如果继续优化 tmux，可以优先考虑内置 `choose-tree -Zw` / popup 形式的 session-window-pane 跳转；这会改变交互模型，适合单独一轮，不和当前无插件基础体验增强混在一起。

- 目的：按用户要求开始优化 tmux 状态栏，让当前 Catppuccin 状态栏信息更均衡并减少旧配置项带来的失效风险。
- 已做：先按仓库约束完整读取 `memory/organizing_preferences.md` 与 `logs/trace.md`，再用只读检查确认 tmux 状态栏集中在 `.config/shared/tmux/.tmux.conf`。随后按 TDD 新增 `tests/tmux_status_test.sh`，先锁定失败预期：Catppuccin 配置需使用新版 `@catppuccin_flavor` / `@catppuccin_window_flags` / `@catppuccin_window_text` 等变量，状态栏左侧需使用 `session` 模块，右侧需保留 Prefix/Copy 状态并加入 `application + date_time`，且不引入 CPU/RAM/Battery 额外插件依赖。确认测试先失败后，修改 `.config/shared/tmux/.tmux.conf`：清理旧变量，统一窗口列表为手动窗口名 `#W`，把日期时间收成 `%m/%d %H:%M`，补上 `status-left`，并将 `status-interval 15` 放到 TPM 加载之后，避免被 `tmux-sensible` 重置回 5 秒。同时更新 `.config/shared/tmux/README.md` 和 `memory/organizing_preferences.md` 记录新的状态栏策略。最后把仓库 tmux 配置同步到 live `~/.tmux.conf` 并执行 `tmux source-file`，确认 live 中 `status-interval=15`、`status-left` 与 `status-right` 已按新配置生效。
- 后续：如果后面继续打磨 tmux 状态栏，优先在现有 `session / application / date_time` 轻量模块上微调间距、图标和时间格式；只有明确需要系统监控时，再单独评估是否引入 `tmux-cpu` 或 `tmux-battery` 这类额外插件。

## 2026-04-24

- 目的：按用户要求把当前已验证的 rofi 系统缩放改动提交到 GitHub 远端。
- 已做：先按既有偏好复核工作树与 live 配置同步状态，确认 `.config/linux/rofi/config.rasi`、`.config/linux/rofi/theme.rasi`、`.config/scripts/rofi-launch`、`.config/linux/awesome/actions.lua` 都已经同步到 live `~/.config`；随后重新执行 `tests/rofi_config_test.sh`、`sh -n .config/scripts/rofi-launch`、`bash -n install.sh`、`luajit -e 'assert(loadfile(".config/linux/awesome/actions.lua"))'`，并实际运行 `~/.config/scripts/rofi-launch -dump-theme` 确认 runtime theme 仍可生成。验证通过后，准备按 Lore 协议在 `main` 分支提交并推送到 `origin/main`。
- 后续：推送完成后，这套“rofi 跟随 `Xft.dpi`，并让字体/容器同步缩放”的实现就会成为新的远端基线；如果后面还要继续调观感，优先在 launch script 的倍率策略上微调，而不是再退回固定 `dpi: 1`。

- 目的：修正刚切到“跟随系统缩放”后 rofi 字体相对过小的问题，让运行时缩放同时覆盖字体和 px 距离。
- 已做：收到用户反馈“字体小了”后，先复核当前 runtime scaling 实现，确认 `~/.config/scripts/rofi-launch` 只会把主题里的 `Npx` 值按 `Xft.dpi / 96` 放大，而不会同步改写字体大小，导致容器和图标已经按 2x 放大时，字体仍停留在基础主题的 `11.5 / 12`。随后按 TDD 扩展 `tests/rofi_config_test.sh`，新增一个临时 `XDG_CONFIG_HOME/XDG_CACHE_HOME + fake xrdb(Xft.dpi=192)` 的运行时验证，要求 launch script 生成的 `theme.scaled.rasi` 里不仅 `width` 要从 `680px` 变成 `1360px`，而且基础字体也必须同步缩放为 `JetBrainsMono Nerd Font Mono 23`、`JetBrainsMono Nerd Font Bold 24`、`Noto Sans CJK SC 23`；确认测试先失败后，再修改 `.config/scripts/rofi-launch` 里的 Python 生成逻辑，在缩放 `px` 之后继续按同一倍率改写 `font: "... <size>"` 尾部字号。最后重新执行 `tests/rofi_config_test.sh`，并把更新后的脚本同步到 live `~/.config/scripts/rofi-launch` 后实际运行 `~/.config/scripts/rofi-launch -dump-theme`，确认生成主题中的字体与 `width` 都已经一起放大。
- 后续：当前这套 rofi runtime scaling 已经做到“容器 + 图标 + 字体”同倍率缩放；如果用户接下来觉得 2x 过大或过小，下一轮优先在 launch script 里给 `scale = dpi / 96` 加一个可调系数或上下限，而不是再回退到固定 `dpi: 1`。

- 目的：按用户要求把 rofi 从“固定基线”切回尽量跟随系统缩放的方案，同时避开 rofi 1.7.1 在当前环境里对 `em/ch` 单位的已知问题。
- 已做：先重新核对当前环境，确认系统 `Xft.dpi` 仍是 `192`，并再次用 `rofi -no-config -theme-str ... -dump-theme` 验证 `em/ch` 在 rofi 1.7.1 下依旧会触发 `GLib-CRITICAL g_ascii_formatd` 且导出非法字节，因此没有直接把仓库主题切回相对单位。随后改走运行时缩放路线：先按 TDD 扩展 `tests/rofi_config_test.sh`，把新预期锁定为 `config.rasi` 不再固定 `dpi: 1`、Awesome 改为调用 `~/.config/scripts/rofi-launch`、新增 launch script 需要读取 `xrdb` 里的 `Xft.dpi`、计算 `scale = dpi / 96`、生成缩放后的 runtime theme，并通过 `-theme` 拉起 rofi；确认测试先在旧实现上失败后，再修改 `.config/linux/rofi/config.rasi`、`.config/linux/awesome/actions.lua`、`install.sh`，新增 `.config/scripts/rofi-launch`。脚本里保留 locale/fcitx 注入，同时用 Python 把基础主题里的所有 `Npx` 按当前缩放倍率重写到 `~/.cache/rofi/theme.scaled.rasi`。最后重新执行 `tests/rofi_config_test.sh`、`sh -n .config/scripts/rofi-launch`、`bash -n install.sh`、`luajit -e 'assert(loadfile(".config/linux/awesome/actions.lua"))'`，并实际运行 `~/.config/scripts/rofi-launch -dump-theme` 验证 runtime theme 已生成；在当前 `Xft.dpi: 192` 下，关键值已翻倍为 `width: 1360px`、`mainbox padding: 40px`、`element-icon size: 64px`。随后把新的 rofi config/theme、launch script 和 `actions.lua` 同步到 live `~/.config`，并通过 `awesome-client` 触发 reload，重载前后 `awesome.startup_errors` 都仍为 `"ok"`。
- 后续：当前通过 Awesome 的 rofi 入口已经会跟随 `Xft.dpi` 生成缩放后的 runtime theme；如果还要继续打磨，下一轮优先做真实 GUI 观感复核，并决定这套 `dpi / 96` 线性放大是否需要上限/下限钳制。中文输入问题仍与这一轮分离，继续维持现有版本边界判断。

- 目的：继续把 rofi 的紧凑化往辅助区域推进，在不减少可见行数和不碰窗口外框的前提下再收一轮 message/textbox 内边距。
- 已做：延续上一轮的低风险 rofi 收紧策略，先按 TDD 扩展 `tests/rofi_config_test.sh`，新增对 `message` 区块 `padding: 8px` 和 `textbox` 区块 `padding: 6px 11px` 的预期，并先执行测试确认旧主题下会失败。随后只修改 `.config/linux/rofi/theme.rasi` 这两个辅助区域的 padding：`message` 从 `10px` 收到 `8px`，`textbox` 从 `8px 13px` 收到 `6px 11px`，其余字体、宽度、listview 行数和输入法相关配置保持不变。最后重新执行 `tests/rofi_config_test.sh`，并在把 repo 文件同步到 live `~/.config/rofi/` 后用 `rofi -config ~/.config/rofi/config.rasi -dump-theme` 复核，确认当前 rofi 1.7.1 实际解析出来的 `message/textbox` padding 已更新为新值。
- 后续：如果还要继续压 rofi，下一轮优先考虑 `message` / `textbox` 之外的次级 spacing 或 icon/text 对齐细节；只有这些都收完仍嫌松时，再评估是否要减少 listview 可见行数，暂时不要先缩窗口宽度。

- 目的：继续打磨 rofi 1.7.1 的当前基线，在不碰窗口宽度和输入法边界判断的前提下先做一轮低风险紧凑化与文案降噪。
- 已做：先基于仓库里的 rofi 配置、回归测试和既有偏好做只读分析，确认这一轮优先级应当是“图标/spacing/padding 收紧 + window 模式信息简化 + launcher 文案统一”，而不是继续改 `dpi`、回退到 `em`，或再碰中文输入问题。随后按 TDD 先扩展 `tests/rofi_config_test.sh`，把新预期锁定为：launcher 标签改成中文短标签 `应用 / 窗口 / 命令`、`window-format` 从 `{w} · {c} · {t}` 收到 `{w} · {c}`、`mainbox`/`inputbar`/`element` 的 spacing 与 padding 进一步收紧、列表图标从 `36px` 收到 `32px`；确认测试先在旧配置上失败后，再修改 `.config/linux/rofi/config.rasi` 与 `.config/linux/rofi/theme.rasi` 落地这些调整。最后重新执行 `tests/rofi_config_test.sh`，并用 `rofi -config ... -dump-theme` 做真实解析检查，确认新主题仍能被当前系统的 rofi 1.7.1 正常读取；随后把更新后的 `config.rasi` 与 `theme.rasi` 同步到 live `~/.config/rofi/`，这样下一次直接拉起 rofi 就会吃到新配置。
- 后续：如果用户实际使用后还觉得 rofi 偏松，下一轮仍应先从局部 spacing / icon size 继续细调，必要时再考虑 `message` / `textbox` 的 padding；只有这些都不够时，才回头讨论窗口宽度。中文输入问题继续维持现有判断，不和这一轮视觉紧凑化混在一起。

- 目的：修复新的 Awesome 重构后在运行时触发的 `wibar.lua:101: attempt to call a nil value (method 'count')` 崩溃。
- 已做：先重新核对 `ui/wibar.lua` 和 `widgets/system.lua` 的当前实现，确认根因是第二轮重构后 `create_sysinfo_bundle()` 仍然把 `widgets.system.create(config)` 返回的 `sysinfo_widget` 外层 margin 容器当成可插入子项的 layout，继续调用了旧的 `:count()` / `:insert()` 路径；随后按 TDD 扩展 `tests/awesome_ui_architecture_test.sh`，要求 `ui/wibar.lua` 不再对 `sysinfo_widget` 调用 `count/insert`，并要求 `widgets/system.lua` 显式暴露 `system_row` 给上层扩展；确认测试先失败后，修改 `widgets/system.lua` 返回 `system_row`，再把 `ui/wibar.lua` 中给 volume widget 追加分隔符和音量组件的逻辑改到 `system_row:add(...)`，从正确的 layout 层插入。最后重新执行 Awesome 相关 shell 回归测试、autostart shell 语法检查和 `luajit` 语法检查，全部通过。
- 后续：如果还要继续给 sysinfo 区块加更多可选组件，优先延续“内部 layout 暴露、外层容器只负责包裹样式”的边界，避免再次把 margin/container 当作可变布局来操作。

- 目的：继续把 Awesome 的平台抽象往 capability detection 推进，先处理 `config.lua` 里最明显的 volume/distro 硬编码。
- 已做：先新增 `tests/awesome_config_test.sh`，要求 `.config/linux/awesome/config.lua` 提供 `command_exists()` helper、`has_volume` 改成基于 `pactl` 是否存在的能力检测、以及已收敛完成的 `net_interfaces` 常量化；确认测试先失败后，重构 `config.lua`：新增 `read_command_output()` 与 `command_exists()`，用前者替代裸 `io.popen(...):read()`，让 `has_volume` 从“Ubuntu 才开启”改成“Linux 且存在 `pactl` 就开启”，并把 `net_interfaces` 退化分支直接收平成常量；同时把 distro 正则放宽到支持连字符/下划线。随后调整 `tests/awesome_net_test.sh` 以匹配新的常量写法，并重新执行 Awesome 相关 shell 回归测试、autostart shell 语法检查和 `luajit` 语法检查，全部通过。
- 后续：下一轮如果继续推进 capability detection，更值得处理的是 `menu_style` / freedesktop 菜单 fallback 和 volume widget 对 `pactl` 命令失败时的降级行为；结构性收口已经比较完整，后面适合转向异常路径与能力缺失场景。

- 目的：继续压缩 Ubuntu aarch64 Awesome autostart 的硬编码风险，先处理显示输出名写死和 Linuxbrew PATH 前置这两个最容易复发的平台问题。
- 已做：先扩展 `tests/awesome_autostart_test.sh`，要求 `common.sh` 提供 `append_path_if_exists()`，并要求 `ubuntu_aarch64.sh` 改为显式定义 `detect_laptop_display()`、运行时探测内部屏后再执行 `xrandr`，同时不再使用 `PATH=...:$PATH` 的 Linuxbrew 前置写法；确认测试先失败后，修改 `.config/linux/awesome/autostart/common.sh` 新增 `append_path_if_exists()`，并重写 `ubuntu_aarch64.sh`：先加载 `common.sh`，再把 `/home/linuxbrew/.linuxbrew/bin` 追加到 PATH 末尾，新增 `detect_laptop_display()` 通过 `xrandr --query` 探测 `eDP/LVDS/DSI` 内部屏，只有探测成功时才应用 2880x1800@120Hz 模式，原有 touchpad、壁纸、gestures、flameshot 与公共后台服务逻辑保持不变。最后重新执行 autostart 结构测试、Awesome 相关 shell 回归测试、autostart shell 语法检查和 `luajit` 语法检查，全部通过。
- 后续：下一轮如果继续收口 Awesome，最值得推进的是把 `config.lua` 中的 `has_volume` 等 distro 判断改成更细的 capability 检测；对于 autostart 本身，显示器模式也许还可以继续从“固定分辨率+刷新率”升级为“探测支持后再应用”，但那会改变更多运行时策略，适合单独一轮。

- 目的：继续 Awesome 下一轮收口，把三份 autostart 脚本中的公共 helper 与公共后台服务启动逻辑抽到共享脚本里，降低平台脚本漂移。
- 已做：先新增 `tests/awesome_autostart_test.sh`，要求存在 `.config/linux/awesome/autostart/common.sh`，三份平台脚本都改为 `source` 该共享脚本、不再各自定义 `run()`，并且仍显式保留各自的平台差异行为；确认测试先失败后，新增 `.config/linux/awesome/autostart/common.sh`，集中提供 `run()`、`run_custom()`、`prepare_xresources()`、`run_common_tray_services()`、`run_common_desktop_services()`；随后重写 `arch_x64.sh`、`ubuntu_aarch64.sh`、`ubuntu_x64.sh`，让它们只保留 sleep、PATH、xrandr/xinput、壁纸、Snipaste/greenclip/flameshot 等差异项，并调用共享入口启动公共服务。最后同步更新 `.config/linux/awesome/autostart/README.md` 说明新的 `common.sh` 结构，并重新执行 autostart 结构测试、Awesome 相关 shell 回归测试、autostart shell 语法检查和 `luajit` 语法检查，全部通过。
- 后续：下一轮如果继续清理 Awesome，最值得处理的是 Ubuntu aarch64 autostart 里的显示输出名与 PATH 硬编码，或者把 `config.lua`/`widgets.volume.lua` 从 distro 判断继续推进到更细的 capability 检测；这两项都比继续细拆当前 autostart 更有收益。

- 目的：按计划继续处理 Awesome 的 volume widget，让音量组件不再只在点击自身后更新，并显式展示静音态。
- 已做：先新增 `tests/awesome_volume_test.sh`，要求 `.config/linux/awesome/widgets/volume.lua` 同时查询 `pactl get-sink-volume` 和 `pactl get-sink-mute`、提供 2 秒周期刷新定时器、并在代码中显式渲染 `MUTE` 状态；确认测试先失败后，重构 `widgets/volume.lua`，新增 `render_volume_markup()`、把刷新逻辑改为同时解析音量和静音状态，并保留点击滚轮/左键后的 0.2 秒延迟刷新。最后重新执行 Awesome 相关 shell 回归测试和 `luajit` 语法检查，全部通过。
- 后续：如果继续打磨 Awesome，下一步更值得处理的是 `autostart/*.sh` 的公共逻辑收口和 Ubuntu aarch64 自启动硬编码；当前 volume widget 虽然已经更稳，但仍是轮询方案，如果未来要再提体验，可以再考虑基于 PulseAudio/PipeWire 事件做真正事件驱动刷新。

- 目的：继续 Awesome 第三轮调整，先处理 `widgets/system.lua` 里 NET 组件的热路径，把 2 秒一次的 shell pipeline 轮询改成 Lua 直接解析 `/proc/net/dev`。
- 已做：先扩展 `tests/awesome_net_test.sh`，要求 NET 组件不再使用 `cat /proc/net/dev | grep -E ... | awk ...`，而是提供 `read_network_totals()` 直接读取 `/proc/net/dev`，并在首次刷新时先初始化上一轮计数再显示 `0B` 速率；确认测试先失败后，重构 `.config/linux/awesome/widgets/system.lua`，新增 `interface_matches()` 与 `read_network_totals()`，在 Lua 中按字段解析网络计数，并把首轮刷新改成只播种 `net_prev`、避免把开机累计字节数误当作瞬时速度；随后修正发送字节解析实现，改为显式拆分 `/proc/net/dev` 行字段，避免使用不可靠的模式表达式。最后重新执行 Awesome 相关 shell 回归测试和 `luajit` 语法检查，全部通过。
- 后续：下一轮如果继续优化 Awesome，优先处理 `widgets/volume.lua` 的外部音量变化不同步问题，或者开始收口 `autostart/*.sh` 的公共逻辑；这两项都比继续微调当前 NET 实现的收益更高。

- 目的：继续 Awesome 第二轮结构收口，把顶部栏 widget 的创建职责从 `rc.lua` 继续下沉到 `ui/wibar.lua`，并顺手消除共享实例边界。
- 已做：先扩展 `tests/awesome_ui_architecture_test.sh`，要求 `rc.lua` 不再本地创建 `lock_button` / `mytextclock` / `systray_widget` / `widgets.system`，同时要求 `ui/wibar.lua` 接管 `config`、`actions`、`lain_ok` 注入并负责创建 lock button、clock、systray 与 sysinfo bundle；确认测试先失败后，再重构 `.config/linux/awesome/ui/wibar.lua`，新增 `create_lock_button`、`create_textclock`、`create_systray_widget`、`create_sysinfo_bundle`，让每个 screen 在 wibar setup 内部创建自己的 lock button、clock、sysinfo，而 systray 只保留一个 primary 实例；同步收窄 `.config/linux/awesome/rc.lua`，让它只负责能力检测、theme 初始化、主菜单与 bindings 装配。最后重新执行 Awesome 相关 shell 回归测试和 `luajit` 语法检查，全部通过。
- 后续：下一轮如果继续改 Awesome，优先进入 `widgets/system.lua`，把网络监控从 2 秒一次的 shell pipeline 改成 Lua 直接解析 `/proc/net/dev`，再决定是否继续把 autostart 公共逻辑做合并，避免同时扩大 UI 和平台脚本两个变更面。

- 目的：启动 Awesome 配置第一轮结构收口，在不改变已验证桌面行为的前提下先降低隐式耦合和 UI 运行时风险。
- 已做：先新增 `tests/awesome_ui_architecture_test.sh`，锁定本轮结构目标：新增 `actions.lua`、`bindings.lua` 不再直接读取 `awful.screen.focused().mypromptbox`、`ui/wibar.lua` 需要暴露显式 prompt runner 且 tasklist 标题必须走 `gears.string.xml_escape`。确认测试先失败后，新增 `.config/linux/awesome/actions.lua` 收口锁屏、rofi、截图 OCR、文件管理器动作；修改 `.config/linux/awesome/bindings.lua`，改为消费注入的 `actions` / `run_prompt` / `run_lua_prompt`；修改 `.config/linux/awesome/ui/wibar.lua`，补上 tasklist 文本渲染 helper 与 prompt runner 返回值；同步修改 `.config/linux/awesome/rc.lua` 完成装配；同时更新 `tests/rofi_config_test.sh` 以跟随新的 rofi action 位置，并补上 `tests/install_redshift_test.sh` 的可执行位。最后重新执行 `tests/*.sh` 与 `luajit` 语法检查，全部通过。
- 后续：下一轮如果继续清理 Awesome，优先把 `rc.lua` 中残留的 bar/widget 创建职责继续回收到 `ui/wibar.lua`，再处理 `widgets/system.lua` 的网络轮询 shell pipeline 与 autostart 公共逻辑收口，避免这次把运行时行为改动铺得过大。

- 目的：将本轮 zsh PATH 修复和回归测试提交到仓库并推送到 GitHub。
- 已做：复核工作树，确认当前只包含 `.config/shared/zsh/path.zsh`、新增的 `tests/zsh_path_test.sh`、`memory/organizing_preferences.md` 与 `logs/trace.md` 这四处本轮相关改动；同时确认 live `~/.config/zsh/path.zsh` 已与仓库同步，并重新执行 `tests/zsh_path_test.sh`，再用隔离 zsh 环境验证 `command -v omx` 可解析到 `/usr/local/nodejs/bin/omx`。随后准备在 `main` 分支提交并推送到 `origin/main`。
- 后续：推送完成后，新的 zsh 会话就会稳定带上 `/usr/local/nodejs/bin`；如果后面还遇到其它 npm 全局 CLI 只安装未暴露的问题，可以继续沿用这条 PATH 回归测试，而不必再逐个手动排查。

- 目的：修复通过 `npm install -g @openai/codex oh-my-codex` 安装后，`codex` 可用但 `omx` 在 zsh 中找不到的问题。
- 已做：先按调试流程核对全局 npm 前缀与可执行文件，确认 `oh-my-codex` 实际安装在 `/usr/local/nodejs/lib/node_modules/oh-my-codex`，`omx` 符号链接位于 `/usr/local/nodejs/bin/omx`，而当前 zsh `PATH` 缺少 `/usr/local/nodejs/bin`，`codex` 之所以可用是因为命中了已有的 Homebrew 版本。随后按 TDD 新增 `tests/zsh_path_test.sh`，在隔离环境里只加载 `.config/shared/zsh/path.zsh` 并验证 `/usr/local/nodejs/bin` 必须进入 `PATH`；确认测试先失败后，再修改 `.config/shared/zsh/path.zsh`，在 Linux 分支中追加 `/usr/local/nodejs/bin`，同时把这条 PATH 偏好补入 `memory/organizing_preferences.md`。
- 后续：重新载入 zsh 配置后，`omx` 应该可以直接命中 `/usr/local/nodejs/bin/omx`；如果之后还想让 `codex` 也优先走 npm 全局安装版本，再单独评估是否调整 `/usr/local/nodejs/bin` 与 Homebrew 目录的先后顺序，避免在这次修复里顺手改变现有 `codex` 来源。

## 2026-04-22

- 目的：将本轮 rofi/Awesome 调整和对应回归测试提交到仓库并推送到 GitHub。
- 已做：复核工作树，确认当前只包含 rofi/Awesome 绑定、rofi 配置、`tests/rofi_config_test.sh` 以及 `memory/`、`logs/trace.md` 的本轮相关改动；同时把“提交到 GitHub 前优先复跑轻量回归测试并确认 live 配置已同步”的偏好补入 `memory/organizing_preferences.md`。随后准备重新执行 rofi 回归测试和 Lua 语法检查，确认无误后在 `main` 分支提交并推送到 `origin/main`。
- 后续：推送完成后，继续用当前提交作为 rofi 1.7.1 的基线；如果之后还要处理中文输入，就在此基础上另开一轮，避免把系统 rofi 版本替换和当前配置回归混进同一个提交。

- 目的：在保留当前已验证缩放方案的前提下，把 rofi 字体再缩小一档。
- 已做：用户确认选择“只降字体、不动宽度和间距”的方案后，先按 TDD 修改 `tests/rofi_config_test.sh`，把提示字体预期改为 `JetBrainsMono Nerd Font Bold 12`，把 `entry`、`element-text`、`textbox` 的 CJK 字体预期改为 `Noto Sans CJK SC 11.5`，并先执行测试确认在旧配置上失败。随后只修改 `.config/linux/rofi/theme.rasi` 的字体档位：基础 monospace 从 `12.5` 调到 `11.5`，提示粗体从 `13` 调到 `12`，CJK 字体从 `12.5` 调到 `11.5`；窗口宽度、padding、spacing、圆角和图标尺寸保持不变。最后重新执行 `tests/rofi_config_test.sh`，确认通过，并将更新后的 `theme.rasi` 同步到 live `~/.config/rofi/theme.rasi`。
- 后续：当前 live rofi 主题已经更新，下一次按 `Mod+c` 就会使用更小一档的字体；如果仍嫌大，再考虑进一步把列表图标和部分间距一起收紧，而不是继续单独压缩窗口宽度。

- 目的：把 rofi 问题拆分成“缩放异常”和“中文输入失败”两条链路，并先固化可本地验证的缩放修复。
- 已做：先用 Awesome 会话里的 `rofi -dump-theme` 抓真实主题，发现当前系统 `/usr/bin/rofi` 1.7.1 在解析 theme 中的实数 `em` 距离值时会把 `width`、`padding`、`spacing`、`border-radius`、`size` 等字段导成非法字节，同时 stderr 连续报 `GLib-CRITICAL g_ascii_formatd`，这与实际窗口缩放失真相互印证。随后构造一次性对照实例：把 theme 改回 `px` 距离、显式 `-dpi 1`、并强制 `LANG/LC_ALL/LC_CTYPE=zh_CN.UTF-8` 与 fcitx 环境；用户反馈结果为“中文仍不能输入，但缩放正常”，从而确认缩放和中文输入不是同一个根因。基于这条证据链，先按 TDD 修改 `tests/rofi_config_test.sh`，让其改为检查 `config.rasi` 中必须固定 `dpi: 1`、Awesome 拉起 rofi 时必须显式传递 `LANG/LC_ALL/LC_CTYPE` 与 fcitx 环境、theme 中关键距离值必须回到 rofi 1.7.1 兼容的 `px`；确认测试先在旧配置上失败后，再修改 `.config/linux/rofi/config.rasi`、`.config/linux/rofi/theme.rasi`、`.config/linux/awesome/bindings.lua`，并重新执行 `tests/rofi_config_test.sh` 与 `luajit -e 'assert(loadfile(".config/linux/awesome/bindings.lua"))'`，全部通过。最后把三处更新后的文件同步到 live `~/.config`，并通过 `awesome-client` 重载 Awesome，会话启动错误仍为 `"ok"`。
- 后续：当前 live 会话已经加载新的缩放配置，接下来只需要用户再次按 `Mod+c` 确认缩放保持正常。至于中文输入，现有对照实验已经表明它不再是 theme/DPI/locale 参数问题；如果要继续解决，需要把方向转到升级或自编译带更完整 IME/XIM 支持的新 rofi，而不是继续修改当前 1.7.1 的仓库配置。

- 目的：继续完成上一轮 rofi/Awesome 调整的部署收尾，确保当前会话真正加载新的 rofi 启动链。
- 已做：先核对仓库与 live `~/.config/rofi/config.rasi`、`~/.config/rofi/theme.rasi`、`~/.config/awesome/bindings.lua`，确认三处文件已经同步；随后发现 `tests/rofi_config_test.sh` 缺少执行位，直接运行会报“权限不够”，于是补上 `+x` 并重新执行 `tests/rofi_config_test.sh` 与 `luajit -e 'assert(loadfile(".config/linux/awesome/bindings.lua"))'`，两者都通过。最后通过 `awesome-client` 连到当前 Awesome 会话，先确认 `awesome.startup_errors` 返回 `"ok"`，再执行 `awesome.restart()`；断线后重新连接并再次确认 `awesome.startup_errors` 仍为 `"ok"`，说明新的 rofi 绑定已经进入运行中的 Awesome 会话。
- 后续：仓库和 live 配置现在都已一致，Awesome 也已 reload；还需要在图形界面里实际按 `Mod+c` 观察 rofi 窗口比例，并验证中文输入、候选词和已输入文本显示是否正常。如果仍有异常，再继续从 rofi 运行时 locale、fcitx 注入和字体可用性排查。

- 目的：让 rofi 的窗口尺寸和间距跟随当前 Xresources 中的缩放比例，而不是继续写死像素值。
- 已做：先重新读取 rofi 配置、`~/.Xresources` 与本机 rofi 手册，确认当前 `Xft.dpi: 192`，同时 rofi theme 里窗口宽度、内边距、圆角、图标尺寸等关键尺寸仍是固定 `px`，这是缩放观感失真的根因。随后把 `tests/rofi_config_test.sh` 扩展为检查“窗口和主要布局尺寸必须使用基于字体度量的相对单位”，先让测试在 `width: 680px` 等旧写法上失败，再把 `.config/linux/rofi/theme.rasi` 的窗口宽度、主容器 padding/spacing、输入栏 padding/spacing、列表 spacing、条目 padding/spacing、圆角和图标尺寸改成 `em`；这样 rofi 会跟着字体度量变化，而字体本身又会受 `Xft.dpi` 影响。最后重新执行 `tests/rofi_config_test.sh`，确认通过。
- 后续：仓库里的 rofi 缩放逻辑已经改成跟随字体度量，但当前 live `~/.config/rofi` 和运行中的 Awesome 会话还没同步；如果要立刻看到效果，需要把更新后的 rofi/Awesome 文件同步到 live 配置并 reload Awesome，再实际观察 `Xft.dpi: 192` 下的窗口比例是否合适。

- 目的：修复 rofi 打开后中文输入不可用且输入内容不可见的问题。
- 已做：先排查 repo/live 的 rofi 配置、Awesome 启动链和 fcitx5 运行状态，确认当前使用的是系统 `/usr/bin/rofi`，Awesome 会话里已有 `GTK_IM_MODULE`/`QT_IM_MODULE`/`XMODIFIERS`，但 `LC_CTYPE` 缺失；同时定位到 rofi 主题在最近改版后把 `width` 放进了全局 `*`，并删掉了输入框相关的显式布局配置。随后新增 `tests/rofi_config_test.sh`，先让其在“`config.rasi` 不引用单独主题文件、Awesome 启动 rofi 时不显式传递 locale/fcitx 环境、theme 中缺少显式输入框布局与 CJK 字体”这些条件下失败，再据此修改 `.config/linux/rofi/config.rasi`、`.config/linux/rofi/theme.rasi`、`.config/linux/awesome/bindings.lua`：将样式收敛到 `theme.rasi`，把窗口宽度移回 `window`，补回 `mainbox`/`inputbar` 的 `children`，为 `entry` 增加 `expand`、`cursor`、`placeholder-color` 和 `Noto Sans CJK SC` 字体，并让 Awesome 用带 `LC_CTYPE=zh_CN.UTF-8` 与 fcitx 环境变量的命令启动 rofi。最后重新执行 `tests/rofi_config_test.sh`，并用 `luajit -e 'assert(loadfile(...))'` 校验 `bindings.lua` 语法通过。
- 后续：当前改动还只在仓库中，尚未把 rofi/awesome 文件再次同步到 live `~/.config` 并重载 Awesome；如需立刻在当前桌面生效，后续要部署更新后的配置并 reload Awesome，再实际验证中文输入与文本显示。

- 目的：将本次 `redshift` 安装器调整提交到仓库并推送到 GitHub。
- 已做：复核 `install.sh`、新增回归测试及持久化记录的 diff，确认当前工作树只包含本轮 `redshift` 相关变更，并准备在 `main` 分支上提交后推送到 `origin/main`。
- 后续：推送完成后，如果还要继续优化安装器，可再把不同依赖的“检查并提示安装”逻辑做统一抽象，减少平台分支里的重复判断。

- 目的：调整 `install.sh` 中 `redshift` 的处理方式，避免安装脚本自动执行 `sudo apt-get install`。
- 已做：先新增 `tests/install_redshift_test.sh`，用伪造的 `dpkg` 和 `sudo` 复现 Ubuntu 下缺少 `redshift` 的场景，并通过红绿测试确认旧逻辑会触发 `sudo`。随后修改 `install.sh` 的 Ubuntu 分支，保留 `dpkg` 检查，但把自动安装改成明确的手动安装提示 `sudo apt-get install -y redshift`；同时补充 `memory/organizing_preferences.md`，记录“只检查、不自动安装”的新偏好。最后重新执行 `tests/install_redshift_test.sh`、`tests/awesome_lock_test.sh`，确认通过。
- 后续：如果之后还要进一步优化安装脚本，可考虑把这类“检查依赖并提示安装”的行为抽成统一函数，避免不同软件各自散落一段平台判断与提示文案。

## 2026-04-20

- 目的：将本轮 AwesomeWM 相关修复及回归测试目录一起提交并推送到 GitHub。
- 已做：确认用户选择保留 `tests/` 目录中的轻量 shell 回归测试，并将该偏好写入 `memory/organizing_preferences.md`，随后准备对 Awesome 的网络、电量、锁屏相关改动及对应测试进行验证、提交与推送。
- 后续：重新执行回归测试，只提交本轮相关文件到 `main`，推送到 `origin/main`，并保留 `tests/` 目录继续作为 AwesomeWM 行为回归检查入口。

- 目的：记录用户对持久化文档语言的要求。
- 已做：将“`memory/` 和 `logs/trace.md` 的新增记录统一使用中文”写入 `memory/organizing_preferences.md`，并从本条开始按该要求记录。
- 后续：后续在本仓库中更新 `memory/` 与 `logs/trace.md` 时默认使用中文；如需回写翻译历史英文记录，再单独处理。

- 目的：将现有英文 trace 历史记录统一回写为中文。
- 已做：把 `logs/trace.md` 中已有的英文历史记录整理并翻译为中文，同时把“优先将历史 trace 一并回写成中文”的偏好补入 `memory/organizing_preferences.md`。
- 后续：后续新增记录继续默认使用中文；如需统一翻译 `memory/` 中旧的英文偏好，再单独处理。

- 目的：排查为何仓库里已经补上的 AwesomeWM 电量组件在实际桌面中仍未显示。
- 已做：确认 shell 中 `/sys/class/power_supply/BAT0` 读数正常，再用 `awesome-client` 检查运行中的 Awesome 会话。发现 live 模块仍使用旧的 `find /sys/class/power_supply` 探测逻辑，因为最新仓库改动尚未再次同步到 `~/.config/awesome`。随后重新执行 `install.sh`，确认 live 文件已切换为基于 glob 的电源目录扫描，并验证 `widgets.system.create(config)` 可以正确构建 `battery_widget`，最后重启 Awesome 让运行会话加载同步后的代码。
- 后续：如果电量文本后续仍偶发消失，继续检查会话日志中反复出现的 Awesome markup 解析报错；那个问题与电池探测无关，但可能影响其他组件显示。

- 目的：在 AwesomeWM 状态栏中加入电量百分比显示，同时不影响没有电池的台式机。
- 已做：确认笔记本提供 `/sys/class/power_supply/BAT0` 且能读取 `capacity`，随后更新 `widgets/system.lua`，让其动态发现 Battery 设备，仅在检测到电池时渲染 `BAT` 百分比组件，在无电池系统上则完全跳过该组件。新增 `tests/awesome_battery_test.sh`，重新执行电量、网络、锁屏回归测试以及 Lua 语法检查，并将更新后的 Awesome 配置同步到 `/home/rikoo/.config/awesome`。
- 后续：通过 `Mod+Ctrl+r` 重载 Awesome 或重新登录，确认 aarch64 笔记本显示新的 BAT 百分比，Ubuntu/Arch 台式机仍然不显示该组件；如果状态栏间距不合适，优先微调分隔符位置，而不是为台式机单独硬编码一套分支。

- 目的：修复 Ubuntu aarch64 下 AwesomeWM 状态栏 NET 组件在活跃网卡名为 `wlp*` 时始终显示 0 的问题。
- 已做：沿着 `widgets/system.lua` 到 `config.lua` 追踪组件数据流，确认 NET 组件通过 `config.net_interfaces` 去 grep `/proc/net/dev`，并核实这台机器的活跃网卡为 `wlp129s0`，而原先的 Ubuntu 模式只匹配 `wlan0|eth0|enp`。新增 `tests/awesome_net_test.sh` 作为回归检查，将 Ubuntu/默认分支的接口匹配补上 `wlp`，重新运行测试，并把修复后的 Awesome 配置同步回 `/home/rikoo/.config/awesome`。
- 后续：通过 `Mod+Ctrl+r` 重载 Awesome 或重新登录，确认 NET 组件开始显示非 0 的流量；如果重载后仍为 0，再评估是否要把 `/proc/net/dev` 轮询切换成更稳健的接口自动探测方案。

- 目的：将 AwesomeWM 锁屏修复及其回归测试持久化到 GitHub。
- 已做：复核锁屏脚本 fallback、安装器执行位修复、新增的 `tests/awesome_lock_test.sh`，以及更新后的 memory/trace 记录，准备将这批改动在 `main` 分支上提交并推送。
- 后续：把锁屏修复提交到 `main` 并推送到 `origin/main`；如果仓库策略未来不允许保留这种轻量 shell 回归测试，再单独处理 `tests/` 目录。

- 目的：修复 Ubuntu aarch64 下 AwesomeWM 锁屏脚本无法实际执行的问题，使快捷键和锁屏按钮都能工作。
- 已做：从 Awesome 绑定和 wibar 一路追到 `~/.config/scripts/lock`，确认系统里未安装 `i3lock` 时脚本根本不会被安装；随后又发现另一个部署问题：已有脚本即使内容相同，只要执行位错误，`install.sh` 也会直接跳过，导致保留错误的 `0644` 权限。为此更新 `.config/scripts/lock`，使其在不支持 `--blur` 时回退到普通 `i3lock`；同时修改 `install.sh`，让其始终安装锁屏脚本，并在执行位不一致时重新复制。新增 `tests/awesome_lock_test.sh`，设置仓库脚本为可执行，重新执行安装器，并确认 `/home/rikoo/.config/scripts/lock` 当前权限为 `775`，系统中 `/usr/bin/i3lock` 可用。
- 后续：如果还需要空闲或休眠后自动锁屏，再为 Ubuntu aarch64 的 Awesome 自启动链路补上 `xss-lock` 或 `xautolock`；否则手动锁屏 `Mod+Ctrl+l` 已可直接使用。

- 目的：排查 Ubuntu aarch64 下 AwesomeWM 自启动为何没有拉起 `redshift`。
- 已做：确认自启动脚本把 Linuxbrew 放到了 `PATH` 前面，导致 Awesome 选中了 `/home/linuxbrew/.linuxbrew/bin/redshift`；而这个构建只支持 `dummy` 模式，无法驱动 X11 显示栈。随后更新 Ubuntu ARM 自启动脚本，使其解析到可用的 `redshift` 二进制，并补了一条回归测试，同时创建了所需的 `memory/` 与 `logs/` 记录，并把修复后的脚本同步到 `~/.config/awesome/autostart.sh`。
- 后续：重新登录或从新会话重启 Awesome，确认色温变化已恢复；如果仍有问题，再把同样的可执行文件选择保护逻辑加到其他可能调用 `redshift` 的桌面自启动入口。

- 目的：保持原始 Awesome 自启动脚本不变，通过清理环境冲突来解决 `redshift` 问题。
- 已做：确认直接卸载 Linuxbrew 的 `redshift` 已足够，因为系统版本 `/usr/bin/redshift` 已安装且 brew 公式没有其他依赖。随后回退了脚本层面的兼容补丁，移除对应回归测试，更新持久化偏好以反映“优先清理环境而不是加脚本防御逻辑”的倾向，卸载了 brew 的 `redshift`，并把回退后的脚本重新同步到 `~/.config/awesome/autostart.sh`。
- 后续：重新启动 Awesome 或重新登录，确认自启动现在会拉起系统版 `redshift`；如果 fresh login 后仍失败，再检查真实 X 会话环境和 `~/.xsession-errors` 或 Awesome 日志，而不是先改脚本。

- 目的：将 `redshift` 处理结果持久化到仓库和 GitHub。
- 已做：检查工作树，确认本次仅包含 Awesome 自启动回退以及新增的 `memory/`、`logs/` 记录，并据此准备在 `main` 分支上提交和推送。
- 后续：把这些变更提交并推送到 `origin/main`；只有在 fresh login 后 `redshift` 仍然不起作用时，才重新回头修改 Awesome 脚本。

- 目的：继续把 Awesome 的 capability detection 从 `config.lua` 往菜单构建链路推进，减少 `menu_style` 对发行版标签的依赖并补安全 fallback。
- 已做：先新增 `tests/awesome_menu_test.sh`，锁定两件事：`config.lua` 的 `menu_style` 默认改成 `auto`，以及 `menu.lua` 在 `freedesktop` 缺失时必须安全退回 `debian.menu` 再退回基础菜单，不能再直接裸 `require("debian.menu")`；确认测试先失败后，重构 `.config/linux/awesome/menu.lua`，抽出 `build_basic_menu()`、`build_debian_menu()`、`build_auto_menu()` 三层 helper，并把 `.config/linux/awesome/config.lua` 的菜单样式从 Ubuntu 专属的 `freedesktop` 改成 capability-oriented 的 `auto`。最后重新执行 Awesome 相关 shell 回归测试（含新增 menu 测试）、rofi/install/zsh 轻量回归，以及相关 Awesome Lua 文件的 `loadfile` 语法检查，全部通过。
- 后续：如果继续推进异常路径，下一轮更值得处理的是 volume widget 在 `pactl` 存在但命令失败、默认 sink 缺失或输出异常时的降级逻辑；菜单链路目前已经从“按 distro 猜测”收敛到了“按能力探测 + 分层 fallback”。

- 目的：继续补齐 Awesome volume widget 的异常路径，让 `pactl` 存在但查询失败时也能稳定降级，而不是显示含糊的占位值或保留旧状态。
- 已做：先扩展 `tests/awesome_volume_test.sh`，要求 `.config/linux/awesome/widgets/volume.lua` 新增 `parse_volume_percent()`、`parse_mute_state()`、`render_unavailable_markup()`，并要求 `pactl` 查询显式吞掉 stderr 后在无有效输出时走 `N/A` 降级；确认测试先失败后，重构 volume widget：把音量与静音解析 helper 提到独立函数，初始化与异常路径统一显示 `V N/A`，并将 `update_volume()` 改成分别抓取 `get-sink-volume` / `get-sink-mute` 原始输出再做 Lua 侧解析。这样默认 sink 缺失、命令失败或输出格式异常时不会继续渲染误导性的百分比；静音态仍然优先显示 `MUTE`。最后重新执行 Awesome 相关 shell 回归测试和相关 Lua 文件的 `loadfile` 语法检查，全部通过。
- 后续：如果继续打磨 volume 组件，下一轮更值得处理的是把点击后的 `pactl set-sink-*` 操作也补上失败兜底或事件驱动刷新；当前读路径已经从“命令存在即可乐观展示”收敛到了“解析成功才展示数值”。

- 目的：继续补齐 Awesome volume widget 的写路径异常处理，避免滚轮调音或左键静音失败后仍保留旧的显示状态。
- 已做：先扩展 `tests/awesome_volume_test.sh`，要求 `.config/linux/awesome/widgets/volume.lua` 新增 `run_volume_action()` helper，并要求点击后的 `pactl set-sink-volume` / `set-sink-mute` 改为走 `easy_async_with_shell` 回调拿到 `exit_code`，失败时立即回退 `V N/A`；确认测试先失败后，重构 volume widget 的按钮处理逻辑：把三个写操作统一收口到 `run_volume_action()`，在回调里对非 0 退出码先显示 `render_unavailable_markup()`，再执行原有的 0.2 秒延迟读刷新。这样默认 sink 消失、PulseAudio/PipeWire 临时不可用或命令执行失败时，不会继续把旧百分比误当成最新状态。最后重新执行 Awesome 相关 shell 回归测试和相关 Lua 文件的 `loadfile` 语法检查，全部通过。
- 后续：如果继续深挖 volume 组件，下一轮更值得评估的是是否改成基于 `pactl subscribe` / PipeWire 事件的真正事件驱动刷新；当前读写两条路径都已经具备明确的失败降级，但仍然是轮询 + 操作后延迟刷新模式。

- 目的：排查并修复 Awesome 会话里壁纸始终停留在主题默认背景、`feh` 设置看起来不生效的问题。
- 已做：先沿着 `rc.lua -> ui/wibar.lua -> theme/catppuccin.lua -> autostart/*.sh` 核对壁纸链路，确认根因不是 `feh` 路径本身，而是 `ui/wibar.lua` 在每个 screen 初始化和 geometry 变化时都会调用 `gears.wallpaper.maximized()`，而 `theme/catppuccin.lua` 又把 `theme.wallpaper` 固定成 `palette.crust` 纯色，导致 Awesome 持续把外部 `feh` 壁纸覆盖回主题背景。随后按 TDD 新增 `tests/awesome_wallpaper_test.sh`，锁定“theme 不再强制内建壁纸、wibar 不再接管 wallpaper”；确认测试先失败后，删除 `theme/catppuccin.lua` 中的 `theme.wallpaper` 纯色函数，并从 `ui/wibar.lua` 去掉 `set_wallpaper()`、`gears.wallpaper.maximized()` 和 `property::geometry` 壁纸 hook，让壁纸所有权回到 autostart 里的 `feh`。最后重新执行 Awesome 相关 shell 回归测试、相关 Lua 文件 `loadfile` 语法检查，并把 `ui/wibar.lua` 与 `theme/catppuccin.lua` 同步到 live `~/.config/awesome` 后通过 `awesome-client` 触发重载。
- 后续：如果后面还想支持“主题自带壁纸”和“外部 feh 壁纸”两种模式，优先显式做成可切换配置，而不要再让 theme/wibar 和 autostart 同时抢占 wallpaper 所有权。

- 目的：继续修复 Awesome 壁纸行为，解决“放开主题纯色覆盖后，又因为平台脚本始终随机 `/usr/share/backgrounds` 而丢掉用户之前壁纸”的问题。
- 已做：先检查 live `~/.config/awesome/autostart.sh`、`~/.fehbg` 和家目录壁纸候选目录，确认当前 Ubuntu aarch64 会话确实直接执行 `feh --bg-fill --randomize /usr/share/backgrounds/*`，而 `~/Pictures`、`~/Pictures/wall`、`~/.local/share/backgrounds` 目前都是空的，所以一旦取消 Awesome 自己的纯色覆盖，就只会回退到系统壁纸。随后按 TDD 扩展 `tests/awesome_autostart_test.sh`，要求 `common.sh` 新增 `restore_or_randomize_wallpaper()`，并要求平台脚本改为通过该 helper 恢复 `~/.fehbg` 或在用户目录/系统目录之间分层回退；确认测试先失败后，修改 `.config/linux/awesome/autostart/common.sh`，新增 `has_wallpaper_files()` 与 `restore_or_randomize_wallpaper()`，并把三份平台脚本的裸 `feh --bg-fill --randomize ...` 调用改成 helper。最后重新执行 Awesome/autostart 回归测试与 shell 语法检查，并把 `common.sh` 与 live `~/.config/awesome/autostart.sh` 同步到当前会话。
- 后续：当前 `~/.fehbg` 已经在前一轮被系统壁纸覆盖，所以旧的那张“以前的壁纸”如果不在别的目录里，已经无法从现有状态自动反推；后续如果要彻底固定某一张图，优先显式给 autostart 增加单文件壁纸配置，而不要再只靠随机目录。

- 目的：修复 Awesome 默认 `tile.left` 布局下，左侧主区域有时被应用最小宽度卡住、导致 `mod+h` / `mod+l` 看起来失效的问题。
- 已做：先核对 `.config/linux/awesome/bindings.lua`，确认 `mod+h` / `mod+l` 仍然正确绑定到 `awful.tag.incmwfact(-0.05 / +0.05)`，再检查 `.config/linux/awesome/client.lua` 的默认规则，发现当前并没有关闭 `size_hints_honor`。结合用户描述的“左边窗口固定最小宽度、右边无法继续扩张”的现象，根因可归到某些应用把最小尺寸 hint 强加给平铺布局。随后按 TDD 新增 `tests/awesome_layout_test.sh`，锁定默认布局仍是 `tile.left`、布局快捷键仍调用 `incmwfact`，且默认 client 规则必须包含 `size_hints_honor = false`；确认测试先失败后，在 `client.lua` 的默认 rule properties 中补上 `size_hints_honor = false`。最后重新执行 Awesome 相关 shell 回归测试、`client.lua` 的 `loadfile` 语法检查，并把修改后的 `client.lua` 同步到 live `~/.config/awesome` 后触发 Awesome reload。
- 后续：如果后面还遇到个别应用在平铺时行为特殊，可以再单独为它们做例外 rule；默认全局忽略 size hints 更符合当前这套以 `tile.left` 为主的桌面操作习惯。

- 目的：继续修复 Awesome 默认平铺布局下钉钉主窗口默认比半屏更宽、且分栏观感异常的问题。
- 已做：在上一轮全局关闭 `size_hints_honor` 后继续做运行时取证：先通过 `xwininfo`/`xprop` 抓到钉钉主窗口 `WM_NORMAL_HINTS`，确认它会主动上报 `program specified minimum size: 1966 by 1200`；再通过 `awesome-client` 检查钉钉所在 tag，确认当时该 tag 运行在 `tileleft`，但 `master_width_factor` 已经漂到 `0.75`，因此钉钉默认宽度明显大于半屏。随后按 TDD 扩展 `tests/awesome_layout_test.sh`，要求 `client.lua` 新增 `maybe_reset_master_width_for_dingtalk()`，在钉钉主窗口（`class=com.alibabainc.dingtalk`、`type=normal`、`min_width >= 1600`）manage 时把所在 tag 的 `master_width_factor` 重置为 `0.5`，并立即调用 `awful.layout.arrange()`；确认测试先失败后，在 `.config/linux/awesome/client.lua` 落地该 helper，并接入 `client.connect_signal("manage", ...)`。最后重新执行 Awesome 相关 shell 回归测试与 `client.lua` 语法检查，同步 live `~/.config/awesome/client.lua`，并通过 `awesome-client` 把当前钉钉 tag 的 `mwfact` 直接拉回 `0.5` 后重载 Awesome。
- 后续：如果后面发现不是只有钉钉会把分栏挤偏，可以再把这个“异常大最小宽度 -> 回正 mwfact”的策略抽成更通用的 helper；当前先对钉钉做精准兜底，避免影响其它正常应用的个性化布局。

- 目的：按用户要求移除 Awesome 中对钉钉的单独处理，回到只保留通用布局规则的状态。
- 已做：删除 `.config/linux/awesome/client.lua` 中上一轮新增的 `maybe_reset_master_width_for_dingtalk()` 及其 `manage` hook 接入，保留通用的 `size_hints_honor = false`；同步改写 `tests/awesome_layout_test.sh`，不再要求存在钉钉专项逻辑，转而锁定“默认平铺布局仍是 `tile.left`、`mod+h/mod+l` 仍调用 `incmwfact`、且 `client.lua` 不含 DingTalk 专项分支”。随后重新执行 Awesome 相关 shell 回归测试和 `client.lua` 的 `loadfile` 语法检查，并把更新后的 `client.lua` 同步到 live `~/.config/awesome` 后重载 Awesome。
- 后续：当前已完全移除钉钉专项兜底；如果后续还要继续解决钉钉宽度异常，只能从更通用的 Awesome 布局/规则策略入手，不能再回到应用特判。

- 目的：优化小屏笔记本上 Awesome 状态栏里 NET 项的横向占用，避免固定 `NET` 标签挤压任务列表和其它状态项。
- 已做：先检查 `.config/linux/awesome/widgets/system.lua` 当前渲染方式，确认 NET 组件一直输出 `NET ↓x ↑y`，在窄屏上属于固定冗余文本；随后按 TDD 扩展 `tests/awesome_net_test.sh`，要求 system widget 新增 `render_net_markup()`，保留 `↓/↑` 与速率值，同时去掉硬编码的 `NET` 文本标签。确认测试先失败后，重构 `widgets/system.lua`：把 `format_speed()` 前置，新增 `render_net_markup(recv_speed, sent_speed)`，让初始态和定时刷新都走紧凑箭头样式（例如 `↓12.3K ↑1.2K`），不再额外占用 `NET` 三个字符和相关前缀间距。最后重新执行 Awesome 相关 shell 回归测试、`widgets/system.lua` 的 `loadfile` 语法检查，并把更新后的文件同步到 live `~/.config/awesome/widgets/system.lua` 后重载 Awesome。
- 后续：如果后面还觉得 sysinfo 区块偏宽，可以继续从更通用的压缩策略入手，例如缩小 system_row spacing、在低流量时收敛小数位，或给 CPU/MEM/NET 做可切换的 icon-only 模式；当前这一轮先做最小风险的 NET 文本压缩。

- 目的：继续压缩小屏笔记本上的 Awesome sysinfo 区块，在去掉 `NET` 文本标签后再收紧 CPU/MEM/NET/BAT 之间的空白。
- 已做：按上一轮思路继续从通用压缩策略入手，先扩展 `tests/awesome_net_test.sh`，要求 `.config/linux/awesome/widgets/system.lua` 把 `system_row.spacing` 从 8 缩到 4，并把 sysinfo 外层容器左右 padding 从 8 缩到 6；确认测试先失败后，修改 `widgets/system.lua`，收紧 system row 的内部 spacing 和 margin。最后重新执行 Awesome 相关 shell 回归测试、`widgets/system.lua` 的 `loadfile` 语法检查，并把更新后的文件同步到 live `~/.config/awesome/widgets/system.lua` 后重载 Awesome。
- 后续：如果后面还需要继续压缩状态栏，可再评估是否把 CPU/MEM 也改成 icon-only、低流量时减少速率小数位，或让 systray/clock 的 margin 跟着屏宽进一步自适应；当前这一轮先维持文本可读性不变，只减少空白占用。

- 目的：按用户要求继续压缩小屏上的 Awesome 右侧状态栏，把 sysinfo 改成短标签并把还能安全收紧的空白一起收掉。
- 已做：先扩展 `tests/awesome_net_test.sh`，锁定几项新预期：CPU/MEM/BAT 要改成短标签 `C/M/B`，`format_speed()` 在较高 K/M 速率时改用整数格式以缩短文本，`system_row.spacing` 从 4 继续缩到 2，sysinfo 容器左右 padding 从 6 缩到 4，同时 `ui/wibar.lua` 右侧 `right_widgets.spacing` 从 8 缩到 6，并收紧 systray/clock margin。确认测试先失败后，重构 `.config/linux/awesome/widgets/system.lua`：新增 `render_metric_markup()`，把 CPU/MEM/BAT 统一收口到短标签渲染；将 NET 的速率格式改成“低速保留一位小数、高速用整数”的更紧凑模式；再同步收紧 `.config/linux/awesome/ui/wibar.lua` 右侧 spacing 与 margin。最后重新执行 Awesome 相关 shell 回归测试、`widgets/system.lua`/`ui/wibar.lua` 的 `loadfile` 语法检查，并把两个文件同步到 live `~/.config/awesome` 后重载 Awesome。
- 后续：这一轮已经把我认为低风险且普适的小屏压缩项基本做完；如果后面还想继续极限压缩，就该进入更强取舍的模式，例如给 CPU/MEM/BAT 换成 Nerd Font 图标、低流量时隐藏上传速率、或让时钟在小屏切到更短日期格式，但这些都会更明显影响辨识度。

- 目的：继续按用户反馈微调小屏状态栏，把 NET 挪到 CPU 左边，并进一步收紧 CPU/BAT/VOL 标签和值之间的空隙。
- 已做：先扩展 `tests/awesome_net_test.sh` 与 `tests/awesome_volume_test.sh`，锁定两类新预期：`widgets/system.lua` 里的 `system_items` 顺序改成 `net_widget -> cpu_widget -> mem_widget`，并且通用 `render_metric_markup()` 以及 `widgets/volume.lua` 的可用/静音/不可用渲染都不再在标签和值之间插入前导空格。确认测试先失败后，修改 `.config/linux/awesome/widgets/system.lua`：把 `render_metric_markup()` 改成紧贴数值输出，并调整 sysinfo 顺序为 `NET -> CPU -> MEM -> BAT`；同时修改 `.config/linux/awesome/widgets/volume.lua`，去掉 `V` 与 `N/A` / `MUTE` / 百分比之间的前导空格。最后重新执行 Awesome 相关 shell 回归测试、`widgets/system.lua`/`widgets/volume.lua` 的 `loadfile` 语法检查，并把两个文件同步到 live `~/.config/awesome` 后重载 Awesome。
- 后续：当前右侧 sysinfo 已经进入非常紧凑的文本布局；如果后面还要继续压缩，下一步就只剩更激进的 UI 取舍，例如把 `V` 静音态改成单字母、让 BAT 低电量时才显示，或把 clock 日期部分进一步裁短。

- 目的：按用户反馈微调紧凑 sysinfo 的可读性，把过于贴紧的 `C12%` / `B87%` / `V35%` 改成更平衡的 `标签:数值` 形式。
- 已做：修改 `.config/linux/awesome/widgets/system.lua` 的 `render_metric_markup()`，让 CPU/MEM/BAT 从无分隔的紧贴样式改成带冒号分隔的紧凑样式（如 `C:12%`）；同时修改 `.config/linux/awesome/widgets/volume.lua`，把 `V` 与 `N/A` / `MUTE` / 百分比也统一改成 `V:` 前缀。随后重新执行 `tests/awesome_net_test.sh`、`tests/awesome_volume_test.sh` 与相关 Lua `loadfile` 语法检查，并把更新后的 widget 文件同步到 live `~/.config/awesome` 后重载 Awesome。
- 后续：当前右侧 sysinfo 的信息密度和可读性已经比较均衡；如果还要继续调整，优先做视觉细调（颜色、separator 明度、clock 格式），而不是继续压缩标签和值之间的可读分隔。

- 目的：继续优化 Awesome 小屏状态栏，在不做应用特判的前提下加入更通用的 compact 自适应，进一步压缩右侧信息区。
- 已做：先读取 `memory/organizing_preferences.md` 与 `logs/trace.md`，确认当前偏好已经收敛到“紧凑 sysinfo + 冒号分隔 + 不再询问直接推进”；随后沿用 TDD，先运行新扩展的 `tests/awesome_config_test.sh`，确认缺少 `compact_wibar_max_width` / `compact_date_format` 配置而失败，再补齐 `.config/linux/awesome/config.lua`。接着修改 `.config/linux/awesome/ui/wibar.lua`：新增 `is_compact_screen(screen, config)`、让 `create_textclock()` 按屏宽在普通日期格式与短日期格式之间切换，并让 `create_sysinfo_bundle()` 把 `compact` 显式下传给 `widgets.system.create(...)`；同时在 compact 下继续收紧右侧 spacing 与 systray/clock margin。最后修改 `.config/linux/awesome/widgets/system.lua`，将签名升级为 `create(config, options)`，读取 `local compact = options and options.compact`，并在 compact 模式下隐藏 MEM，只保留 `NET -> CPU -> BAT` 这一更高价值的信息顺序。完成后重新执行 Awesome 相关 shell 回归测试与 Lua `loadfile` 语法检查，全部通过，并已同步 repo 文件到 live `~/.config/awesome` 后触发 Awesome reload。
- 后续：如果用户继续觉得右侧仍偏宽，下一步优先考虑让 compact 模式按电量/网络活跃度动态显示 BAT 或上传速率，或者继续缩短 tasklist 文本，而不是重新引入应用专项特判。

- 目的：继续修复 Awesome 壁纸仍未生效的问题，定位并修正实际自启动链路中的断点。
- 已做：先检查 repo 与 live 配置，确认 `rc.lua` 始终执行的是根目录 `~/.config/awesome/autostart.sh`，但当前 live 的这个文件其实被安装脚本直接替换成了 `ubuntu_aarch64.sh` 内容；该脚本内部又使用 `. "$(dirname "$0")/common.sh"`，于是运行时会错误地去找 `~/.config/awesome/common.sh`，而真实文件在 `~/.config/awesome/autostart/common.sh`，导致整个自启动链路在壁纸步骤之前就断掉。随后按 TDD 扩展 `tests/awesome_autostart_test.sh`，新增根级 `autostart.sh` wrapper 的结构要求，并锁定 `install.sh` 不能再把平台脚本直接覆盖到 `~/.config/awesome/autostart.sh`。确认测试先失败后，新增 `.config/linux/awesome/autostart.sh`，让它按 `OS+distro+arch` 分发到 `autostart/ubuntu_aarch64.sh` / `ubuntu_x64.sh` / `arch_x64.sh`，并删除 `install.sh` 中三条会覆盖 root wrapper 的平台脚本安装项。完成后重新执行 Awesome/autostart/wallpaper 相关回归测试与 shell 语法检查，全部通过；再把新的 wrapper 同步到 live `~/.config/awesome/autostart.sh` 并手动执行一次，随后通过 `xprop -root _XROOTPMAP_ID ESETROOT_PMAP_ID` 看到 pixmap id 已存在，说明 feh 已成功把壁纸写到 X root。
- 后续：如果用户后面要恢复“以前那张壁纸”，还需要重新提供或放回具体图片文件；当前这次修复解决的是“壁纸设置链路失效”，不是自动找回已不存在的旧图片。
