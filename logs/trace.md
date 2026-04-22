# Trace

## 2026-04-22

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
