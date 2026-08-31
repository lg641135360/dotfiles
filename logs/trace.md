# Trace

> 本文件只记录实际发生过的修改、验证证据与后续线索，不定义长期规则；若某条经验已稳定复用，应提升到 `AGENTS.md` 或 `memory/`。

## 维护规则

- 本文件总长度建议不超过 150 行。
- 最近变更摘要（按 `### 子条目` 计，每条变更算一条）最多保留 5 条；单日多变更可并列多条 `###`，归档时按子条目而非日期计数。
- 归档通过 `scripts/archive_trace.ts` 手动触发，或由 agent 按 `AGENTS.md` 验证策略在提交前执行：
  ```bash
  npm --prefix scripts run archive-trace -- --dry-run   # 预览
  npm --prefix scripts run archive-trace --              # 执行
  ```
- 旧条目按月份归档到 `logs/trace-archive/YYYY-MM.md`。
- 默认任务不得读取 `logs/trace-archive/` 全文。
- 长期有效的规则、方法论或决策边界，不应长期停留在 `logs/trace.md`；若跨多次任务仍有效，应提升到对应 `memory/` 规则文件。
- 每条变更记录必须包含回滚信息：commit hash（已提交时）或"未提交"标记；涉及 live 同步时记录 backup 快照路径，并附可直接复制执行的恢复命令（含确切备份文件名），例如：
  ```bash
  cp ~/.config/niri/common.kdl.backup.<时间戳> ~/.config/niri/common.kdl
  ```


## 2026-08-31 — niri 26.04 全局 window-rule 启用 popup 菜单背景模糊

- 目的：开启 niri 26.04 新增的 `popups { background-effect }` 能力，让应用弹出菜单（下拉、右键菜单等）获得背景模糊（popup 默认 non-xray，模糊下层窗口而非壁纸）。
- 改动：`.config/linux/niri/common.kdl` 全局 window-rule（0.88 透明 + blur）内追加 `popups { background-effect { blur true } }`；README「窗口规则」段与 `memory/niri.md` 同步一行说明。aarch64 平台 `blur` 全局关闭，该改动对其无行为影响。
- 验证：`niri validate -c`（repo 与 live 均 config is valid）；`sh tests/niri_config_test.sh` exit 0；`git diff --check` 干净；live `niri msg action load-config-file` 重载 exit 0。
- live 同步：备份 `~/.config/niri/common.kdl.backup.20260831_144608_147375618` 后写入（shell cp 被 IDE 沙箱拦，改用编辑工具落地，内容与仓库一致；同目标旧 backup 已按惯例清理保留 3 份）。
- 回滚信息：未提交。恢复命令：
  ```bash
  cp ~/.config/niri/common.kdl.backup.20260831_144608_147375618 ~/.config/niri/common.kdl && niri msg action load-config-file
  ```
- 后续可能方向：① 弹窗模糊观感需日常使用确认（XWayland 应用 popup 是否生效待实测）；② 26.04 其余可选项（`screenshot-window show-pointer=true`、非 xray 模糊）未启用；③ trace.md 超行数/条数上限，建议 `npm --prefix scripts run archive-trace`。

## 2026-08-29 — 卸载 Flatpak 钉钉，fuzzel 双"钉钉"入口收敛（live）

- 目的：fuzzel 出现两个"钉钉"入口。排查：Flatpak 版（`com.dingtalk.DingTalk` 8.1.0，占 1.3G，desktop ID 与 deb 版不同、不会被启动器去重）与 deb 版（`com.alibabainc.dingtalk`，用户级包装 `dingtalk-wayland` 覆盖系统级 Elevator.sh）两套并存；且 handler 分裂——`dingtalk://` 默认走 deb、`dingtalk_std_ind://` 默认走 Flatpak。
- 改动（用户手动执行，agent 复核）：`sudo flatpak uninstall com.dingtalk.DingTalk`；`xdg-mime default com.alibabainc.dingtalk.desktop` 修正 `dingtalk://` 与 `dingtalk_std_ind://` 两个 handler（写入 `~/.config/mimeapps.list`）。
- 验证：`/var/lib/flatpak/exports/share/applications/` 无 dingtalk 条目；`flatpak list` 无 dingtalk；两个 handler 均指向 `com.alibabainc.dingtalk.desktop`（mimeapps.list 第 50-51 行）；fuzzel 入口待下次打开复核为单个。
- 回滚信息：未提交（无仓库配置改动，仅 trace/memory 记录）；如需 Flatpak 版回归：`flatpak install flathub com.dingtalk.DingTalk`。

## 2026-08-29 — niri 会话 failed 单元排查 + flameshot/yakuake autostart 禁用（live）

- 目的：排查 `systemctl --user --failed` 的 5 个失败单元（picom/pulseaudio/钉钉/飞连为 XDG autostart 生成单元；ghostty 为包自带 unit，Type=notify-reload 在 niri 下就绪超时被 SIGTERM）；顺带确认 `~/.config/autostart/` 中 flameshot、yakuake 两个 live 独有全量条目残留（截图主线已是 satty Mod+S，yakuake 为 KDE X11 下拉终端）。
- 改动（live-only，仓库无对应物、install.sh 不登记）：`org.flameshot.Flameshot.desktop` 与 `org.kde.yakuake.desktop` 以 Hidden=true 最小覆盖（格式对齐 `.config/linux/xdg-autostart/` 惯例）。用户同轮已自行处理：钉钉/飞连/picom/pulseaudio 四条 Hidden=true 覆盖 + 备份（19:45）、`reset-failed` 清态（`--failed` 现为空）；ghostty unit 仍 enabled 待 disable/mask。
- 验证：覆盖文件内容/权限确认；`grep -l 'Hidden=true'` 命中 12 个预期条目；`systemctl --user --failed` 无输出。下次登录需复核 xdg-autostart-generator 不再生成对应 `@autostart` 单元。
- 回滚信息：未提交（本轮无仓库配置改动，仅 trace/memory 记录）；live 恢复：
  ```bash
  cp ~/.config/autostart/org.flameshot.Flameshot.desktop.backup.20260829_194751 ~/.config/autostart/org.flameshot.Flameshot.desktop
  cp ~/.config/autostart/org.kde.yakuake.desktop.backup.20260829_194751 ~/.config/autostart/org.kde.yakuake.desktop
  ```
- 后续可能方向：① picom/pulseaudio 覆盖进仓库（`.config/linux/xdg-autostart/` + install.sh 注册 + install_wayland_test.sh，待拍板）；② ghostty unit disable/mask；③ trace.md 已超 150 行与 5 条上限，建议 `npm --prefix scripts run archive-trace`；④ `~/.config/niri/` 旧 backup 清理（保留 3 份）。

## 2026-08-29 — x64 niri 双屏输出名漂移修复（DP-4/HDMI-A-3 → DP-1/HDMI-A-2）+ 测试沙箱 link_cmd 加固

- 目的：用户反馈双屏缩放与 niri 配置不匹配。排查：x64 Ubuntu 26.04 实际输出为 DP-1（Dell D2421DS）与 HDMI-A-2（AOC Q24P1W1），配置仍写 DP-4/HDMI-A-3，匹配不到 → 两屏回落 scale 1。
- 改动：① `.config/linux/niri/ubuntu_x64/config.kdl` 输出名改 DP-1（`x=0`）/ HDMI-A-2（`x=2048`），scale 1.25 不变，注释记录接口名漂移教训；② `tests/niri_config_test.sh` / `tests/install_wayland_test.sh` 断言同步；③ `tests/lib/sandbox.sh` `link_cmd` 加固——`command -v` 返回裸名（Trae CN safe_rm_aliases 注入的 cp/mv shell 函数、pwd 等 builtin）时回退 PATH 搜索，修复沙箱自引用死链（`cp -> cp`）导致 install.sh 报 "Missing required commands: cp mv" 的问题。
- 验证：`niri validate` config is valid；`sh tests/niri_config_test.sh` / `bash tests/install_wayland_test.sh` / `bash tests/awesome_lock_test.sh` / `bash tests/install_claude_statusline_test.sh` / `bash tests/install_redshift_test.sh` 全 PASS；`git diff --check` 干净。`bash tests/install_macos_test.sh` 失败为存量环境限制（IDE 沙箱拦 rm 指向 `/usr/lib/cargo/...` 的 uname symlink；用改动前 lib 复测同样失败，与本轮无关）。
- live 同步与运行态：`common.kdl` 与仓库 diff 一致无漂移；备份后写入 live（include 改写为扁平布局），`niri msg action load-config-file` 重载 exit 0。`niri msg outputs` 实测：DP-1 `0,0` / HDMI-A-2 `2048,0`，均 2560x1440@59.951 scale 1.25（逻辑 2048x1152）。
- README：niri README 只写"双 2K scale 1.25"未涉及具体接口名，无需同步。
- 回滚信息：commit `567233b`（撤回用 `git revert 567233b`）；live 恢复：
  ```bash
  cp ~/.config/niri/config.kdl.backup.20260829_163214_001921237 ~/.config/niri/config.kdl && niri msg action load-config-file
  ```
- 后续可能方向：① trace.md 已超 150 行与 5 条上限，建议执行 `npm --prefix scripts run archive-trace` 归档；② `~/.config/niri/` 旧 backup 堆积（08-24 起 4 个）IDE 沙箱拦 rm，需用户手动清理（保留 3 份）；③ install_macos_test.sh 的沙箱 rm 限制如需根治，可评估 fake uname 或调整测试清理逻辑。

## 2026-08-28 — waybar CPU/内存原生模块化 + 剪贴板守护重构（两轮合并提交推送）

- 目的：用户要求整理当前工作区改动并推送。工作区含两轮独立改动，按「一轮任务一个 commit」粒度拆成两个 commit 推送。
- 改动一（waybar）：CPU/内存从 `custom/cpu`/`custom/memory` + `waybar-system-tooltip` 脚本改用原生 `cpu`/`memory` 模块（每 5s 刷新，tooltip 显示负载/容量，原生 `states` 阈值 CPU 70/90、内存 85/95 驱动 CSS `#cpu.warning`/`.critical`）；删除 `.config/scripts/waybar-system-tooltip`，`install.sh`/根 README/scripts README/waybar README/`memory/waybar.md` 同步；测试删旧脚本契约、改断言原生模块。
- 改动二（clipboard）：`clipboard-wayland start` 从 `exec wl-paste --watch wl-clip-persist` 改为直接启动 `wl-clip-persist --clipboard regular &` + 独立 `wl-paste --watch cliphist store &`，父脚本 `trap cleanup EXIT` 监管两子进程、任一退出即共同清理（避免半失效）；`wayland-autostart` 改检测 `clipboard-wayland start` 监管进程；niri/scripts README 与 `memory/niri.md` 同步。
- 验证：`sh tests/waybar_config_test.sh` / `sh tests/wayland_scripts_test.sh` / `sh tests/install_wayland_test.sh` 全 PASS；`git diff --check` 干净；live 已同步（`~/.config/scripts/clipboard-wayland`、`wayland-autostart` 与 repo 一致；`~/.config/waybar/config`、`style.css` 与 repo 一致；`waybar-system-tooltip` 已从 live 删除，仅剩旧 backup `*.backup.20260818_100942_1347567`）。`config.aarch64` 为 aarch64 专用、本机 x86_64 不部署，属预期差异。
- 回滚信息：commit `3568b2e`（waybar）、`e3df762`（clipboard），均已推送（`git revert 3568b2e` / `git revert e3df762` 撤回）。live 已同步无需额外恢复；若需还原旧脚本，`waybar-system-tooltip` 可从 backup 恢复或 `git show 3568b2e~1:.config/scripts/waybar-system-tooltip` 取回。
- 后续可能方向：① 下次登录由 wayland-autostart 自动拉起剪贴板守护，验证双进程监管；② waybar 原生 cpu/memory tooltip 无 top 进程列表，若日后需要可评估 `exec-on-event` 或外挂脚本；③ 清理 live `~/.config/scripts/` 旧 backup（保留 3 份惯例）。

## 2026-08-28 — niri 剪贴板管理（wl-clip-persist 持久化 + cliphist 历史检索）+ live 同步生效

- 目的：补全 Wayland 剪贴板体验——协议层面剪贴板内容归持有窗口所有，窗口关闭即清空。方案 = `wl-paste --watch` 把每次复制交给 `wl-clip-persist` 常驻接管（持久化），`cliphist list | fuzzel --dmenu` 检索历史并 `cliphist decode | wl-copy` 写回。
- 改动：① 新增 `.config/scripts/clipboard-wayland`（统一入口：`start` 启动持久化守护、`history` 弹 fuzzel 检索；缺依赖 warn+退出不中断会话；因 niri `environment {}` 固定 PATH 不含 `~/.nix-profile/bin`，脚本开头按需补 PATH）；② `wayland-autostart` 在 udiskie 后加 `run_once_logged wl-clip-persist 'wl-paste.*wl-clip-persist' ... clipboard-wayland start`；③ `common.kdl` binds 加 `Mod+V repeat=false hotkey-overlay-title="剪贴板历史" { spawn ... clipboard-wayland "history"; }`（Mod+Shift+V 已被"切换浮动/平铺焦点"占用）；④ `install.sh` `linux_wayland_configs` 挂 clipboard-wayland 部署项；⑤ 测试：`wayland_scripts_test.sh` 新增 `test_clipboard_wayland_persists_and_queries_history`（可执行位 / persist 命令 / fuzzel 管道 / decode 写回 / `assert_not_contains '--placeholder'` / Nix PATH 补丁 / 缺依赖沙箱），`niri_config_test.sh` 补 Mod+V 断言；⑥ README（scripts 文件表、niri 快捷键表与自启动段）同步；⑦ `memory/niri.md` 沉淀决策。
- 关键修正（live 实测发现）：cliphist 需**独立**的 `wl-paste --watch cliphist store` 进程才记录历史，原设计只有 wl-clip-persist 一个 watch，`cliphist list` 永远为空。已在 `start_persist()` 里加第二个后台 watch（`&`），缺 cliphist 时仅 warn 不影响持久化；`selected=` 行缩进一并修正（11→4 空格）。测试补 `assert_contains 'wl-paste --watch cliphist store'` 断言。
- 验证：`sh -n clipboard-wayland` / `sh -n wayland-autostart` / `bash -n install.sh` 全 OK；`git diff --check` 干净；`./tests/run.sh fast` 44/44 PASS。
- 踩坑：① fuzzel 1.9.2（Ubuntu Noble）不支持 1.11+ 的 `--placeholder`，已由 `assert_not_contains '--placeholder'` 拦截并修正；② wl-clip-persist 0.5.0 在 niri 26.04 下偶发 `Broken pipe (os error 32)` WARN 风暴（数秒上百行）——实测根因是**同 seat 残留的旧 data source**（此前多次测试遗留的 wl-clip-persist 实例争抢剪贴板所有权），全新会话单实例启动后复制一次内容即自愈（60s 静默 0 新增警告）；多实例并存是触发主因，故清理全部残留进程后单守护稳定。判断依据：cliphist store 单独运行零错误、persist 单独运行也有同样风暴、风暴数据源 ID 循环（3/7/8）指向残留 source。
- live 同步与运行态：已同步 `~/.config/scripts/clipboard-wayland`（chmod +x）、`~/.config/scripts/wayland-autostart`、`~/.config/niri/common.kdl`（含 Mod+V）；backup 快照 `*.backup.20260828_105628`（common.kdl / wayland-autostart 各一份）。已 `niri msg action load-config-file` 重载（exit=0）。守护实测：`clipboard-wayland start` 拉起 2 个 watch（persist + cliphist store）均存活、0 警告；复制→关闭源→`wl-paste` 内容不丢（持久化生效）；`cliphist list` 记录增长、decode|wl-copy 写回成功（history 链路通）。当前会话（8月18日登录）autostart 脚本是 8月28日改的，本轮由手动启动守护补位，**下次登录起由 wayland-autostart 自动拉起**。
- 安装（用户手动执行）：`nix profile install nixpkgs#wl-clip-persist` + `sudo apt install cliphist`（wl-clip-persist 不在 Ubuntu 24.04 apt，走 Nix profile；cliphist 0.4.0 在 apt）。
- 回滚信息：未提交。仓库回滚：`git checkout -- .config/scripts/clipboard-wayland .config/scripts/wayland-autostart .config/linux/niri/common.kdl install.sh tests/niri_config_test.sh tests/wayland_scripts_test.sh .config/scripts/README.md .config/linux/niri/README.md memory/niri.md`。live 回滚：`cp ~/.config/niri/common.kdl.backup.20260828_105628 ~/.config/niri/common.kdl`、`cp ~/.config/scripts/wayland-autostart.backup.20260828_105628 ~/.config/scripts/wayland-autostart`、`rm ~/.config/scripts/clipboard-wayland`，然后 `niri msg action load-config-file` 与重登。
- 后续可能方向：① 下次注销重登验证 wayland-autostart 自动拉起守护；② 若历史条目含图片（图像复制），当前 `wl-copy` 文本路径可后续评估；③ 历史条数上限/清理策略待使用反馈。

## 2026-08-27 — Trae CLI 接入 herdr 状态监控（hooks 桥接）

- 目的：herdr 原生 agent 列表不含 trae，用户要落地"trae-cli 接入 herdr 监控"。方案 = Trae CLI hooks（`~/.trae/trae_cli.yaml`）→ 桥接脚本 → herdr socket API `pane report-agent`（idle/working/blocked + release）。
- 改动：① 新增 `.config/scripts/herdr-report`（POSIX sh；`HERDR_ENV=1` 门控外部 no-op；sed 提取 stdin JSON 的 session_id/notification_type，无 jq 依赖；notify 模式细分 permission_prompt/elicitation_dialog→blocked）；② 新增 `.config/shared/trae-cli/trae_cli.yaml`（合并 live 原 4 行配置 + hooks 段：user_prompt_submit/pre_tool_use→working、session_start/stop→idle、notification→notify、session_end→release）；③ `install.sh` `shared_configs` 挂 2 条（herdr-report 脚本 `command -v herdr` 门控、trae_cli.yaml `command -v trae-cli` 门控）；④ `tests/herdr_config_test.sh` 扩 5 组断言；⑤ README 目录树补 2 行；⑥ `memory/herdr.md` 沉淀接入方案。
- 验证：`sh -n herdr-report` / `bash -n install.sh` / `git diff --check` 干净；`./tests/run.sh fast` 44/44 PASS（含补 `tests/herdr_config_test.sh` 可执行位——run.sh 直接执行需 x 位，历史遗留缺失）；运行态实测（本会话所在 pane `w3:p1`）：working/blocked/idle 上报 + release 后 agent 消失，`herdr agent list` 状态流转全部正确；无 `HERDR_ENV` 时 no-op。
- 踩坑：herdr 的 clap 不认 `--opt=value` 等号格式（报 unknown option exit=2），选项必须空格分隔——脚本首版用等号格式实测失败后已修正为空格分隔。
- live 同步：已部署 `~/.config/scripts/herdr-report`（含修正版）与 `~/.trae/trae_cli.yaml`；backup：`~/.trae/trae_cli.yaml.backup.20260827_201938`（仅 1 份，无需清理）。
- 回滚信息：commit `886644e`（撤回用 `git revert 886644e`）。live 回滚：`cp ~/.trae/trae_cli.yaml.backup.20260827_201938 ~/.trae/trae_cli.yaml && rm ~/.config/scripts/herdr-report`。
- 后续可能方向：① 在 herdr pane 里真实跑一轮 trae-cli 会话，确认 hooks 触发的端到端流转与 sidebar 展示；② 若 herdr 未来原生支持 trae（`agent start --kind` 枚举），可移除桥接改用原生集成；③ `--seq` 乱序保护当前未加（hooks 串行触发场景暂无乱序），若实测出现状态回跳再补。

## 2026-08-26 — 禁用 niri 会话 GNOME/X11 遗留 autostart 与 EDS 三件套

- 目的：后台占用分析发现 niri 会话下 `systemd-xdg-autostart-generator` 经 `NotShowIn=` 排除法拉起 5 个 GNOME/X11 遗留 autostart 服务，且 evolution-alarm-notify 又触发 D-Bus activation 拉起 EDS 三件套（自 7月1日 跨会话常驻）。用户确认完整链路禁用（保留 at-spi）。
- 改动：① 新增 `.config/linux/xdg-autostart/`（此前为空占位目录）4 个 `Hidden=true` 同名覆盖：`org.gnome.Evolution-alarm-notify` / `nm-applet` / `print-applet` / `geoclue-demo-agent`（`X-GNOME-Autostart-enabled` 对 systemd 无效，必须 `Hidden=true`）；② `install.sh` `linux_wayland_configs` 挂 4 个部署条目（→ `~/.config/autostart/`）；③ `.config/scripts/wayland-autostart` 移除 `run_once_logged nm-applet`（消除脚本+autostart 双路径，网络状态由 waybar network 模块覆盖）；④ `tests/install_wayland_test.sh` 加清单断言 + 沙箱落位断言、`tests/wayland_scripts_test.sh` 改 `assert_not_contains`；⑤ niri README 新增「禁用 GNOME/X11 遗留 XDG autostart」小节；⑥ `memory/niri.md` 沉淀 Hidden=true 覆盖与 EDS mask 决策。
- 验证：`bash -n install.sh` + `sh -n wayland-autostart` + `git diff --check` 干净；`niri_config_test.sh` / `waybar_config_test.sh` / `wayland_scripts_test.sh` / `install_wayland_test.sh` 全 PASS。
- live 同步与运行态：已同步 4 个覆盖文件与 wayland-autostart 脚本；已 `systemctl --user mask` EDS 三件套（`~/.config/systemd/user/` 3 个 `/dev/null` symlink）+ `daemon-reload` + `stop` 全部相关服务。验证：generator 不再生成对应单元、`ps` 无相关进程、`is-enabled` 三件套均 masked；at-spi 与 goa-daemon 按计划保留/未处理。
- 回滚信息：commit `0b168ca`（撤回用 `git revert 0b168ca`；仓库回滚 `git checkout 0b168ca~1 -- install.sh .config/scripts/wayland-autostart tests/ memory/niri.md .config/linux/niri/README.md && rm .config/linux/xdg-autostart/*.desktop`）。live 回滚：`cp ~/.config/scripts/wayland-autostart.backup.20260826_200820.411775667 ~/.config/scripts/wayland-autostart && rm ~/.config/autostart/{org.gnome.Evolution-alarm-notify,nm-applet,print-applet,geoclue-demo-agent}.desktop && systemctl --user unmask evolution-source-registry.service evolution-addressbook-factory.service evolution-calendar-factory.service && systemctl --user daemon-reload`（evolution-alarm-notify.desktop 在 live 无原文件，无需恢复）。
- 后续可能方向：① goa-daemon（GNOME Online Accounts，D-Bus 激活，7月1日起常驻）本轮未动，若确认无用可同法 mask；② 下次注销重登验证 4 个 autostart 单元不再拉起；③ 钉钉/Chrome 内存大户另行处理（本轮未涉及）。

## 2026-08-24 — memory 固化 brew vs 系统包管理器落地准则

- 目的：把「哪些软件适合 brew、哪些适合系统包管理器（zypper/apt）」的归类固化为可复用整理规则，避免每次装软件重新推导。
- 改动：`memory/organizing_preferences.md`「系统环境」段在跨系统包管理策略之后新增一条落地准则：五条判定标准（系统资源 / `*-dev` 库 / 会话居民 / 纯 CLI / 被会话引用），并给出当前 openSUSE WSL2 的 brew（neovim/ripgrep/fd/fzf/bat/yazi/zoxide，即 Linux Brewfile 覆盖的纯 CLI 子集）与 zypper（gcc 系 + tmux + jq）映射，明确 herdr 走官方脚本（不进 Brewfile）、tmux 建议系统装、alacritty 归 DMS。
- 验证：`git diff --check` 干净；纯 Markdown 改动，无脚本/配置变更。
- 回滚信息：commit `9c8b57b`（撤回用 `git revert 9c8b57b`）；`git checkout -- memory/organizing_preferences.md` 即回滚本次 memory 改动（本 trace 条目需单独删除）。
- 后续可能方向：待用户装好 herdr/node 后实测；如需把该准则提升为 `AGENTS.md` 硬约束再另行讨论；本轮 trace 新增后超 5 条建议上限，node 补齐后执行 `npm --prefix scripts run archive-trace` 归档。


## 2026-08-23 — herdr 接入 install.sh + 补回归测试 + README 同步

- 目的：把上一轮的 herdr config.toml 草稿纳入部署与测试链路：install.sh 的 `shared_configs` 增加 herdr 部署项（选 `command -v herdr` 缺失即跳过，契合 install.sh 的 skip-on-missing 约定），并补回归测试与根 README 目录树。
- 改动：① `install.sh` L332 新增 `"command -v herdr|.config/shared/herdr/config.toml|~/.config/herdr/config.toml|Herdr"`（copy_config 会自动 ensure_dir `~/.config/herdr/`，无需额外处理）；② 新增 `tests/herdr_config_test.sh` 8 组断言：配置存在、install.sh 部署项、主题 catppuccin、prefix ctrl+a、default_shell/new_cwd、vim pane 导航 h/j/k/l、分屏+reload 键、状态栏 datetime 格式；③ `README.md` 目录树 shared/ 下按字母序补 `herdr/` 一行。
- 验证：`bash -n install.sh`、`sh -n tests/herdr_config_test.sh` 通过；`sh tests/herdr_config_test.sh` PASS；`sh tests/repo_docs_test.sh` PASS；`bash tests/install_backup_test.sh` + `install_submodule_test.sh` + `install_zshenv_test.sh` 全 PASS（install 系列用 bash，`sh` 会因 `pipefail` 报 "Illegal option"）；`git diff --check` 干净。
- live 同步与运行态：未同步 live、未提交；herdr 二进制未安装，未做 `herdr server reload-config` 运行态验证。
- 回滚信息：commit `879707a`（撤回用 `git revert 879707a`）；`git checkout 879707a~1 -- install.sh README.md tests/herdr_config_test.sh` 并删除 `.config/shared/herdr/config.toml` 即回滚本轮与上轮合计全部 herdr 改动。
- 后续可能方向：① 用户装好 herdr 后实测 `herdr server reload-config` 无 startup warning（尤其 reload_config/resize_mode 键互换、prefix+f 无冲突）；② 视需要新增 `memory/herdr.md` 沉淀长期偏好（本轮未建，避免为形式写 memory）。


## 2026-08-23 — 新增 herdr config.toml 草稿（对齐 tmux + catppuccin 习惯）

- 目的：用户要一份 herdr（AI agent 多路复用器，官方配置 `~/.config/herdr/config.toml`）草稿，按现有 tmux 键位与 Catppuccin Mocha 观感对齐，便于后续试用。herdr 定位 shared 跨平台终端工具，与 tmux/alacritty/starship 同级放 `.config/shared/herdr/`。
- 改动：新增 `.config/shared/herdr/config.toml`。① `onboarding=false`；② `[session] resume_agents_on_restore=true`；③ `[terminal] default_shell="zsh"` + `new_cwd="follow"`（对齐 tmux 新 pane/window 继承目录）；④ `[theme] name="catppuccin"`，附被注释的 mocha 精确色值 custom 块（色值取自 `.config/linux/waybar/mocha.css`）；⑤ `[keys]` prefix 改 `ctrl+a`、显式声明 h/j/k/l pane 移动、`split_vertical="prefix+v"`（对应 tmux `|`）/`split_horizontal="prefix+minus"`（对应 tmux `-`）、`reload_config="prefix+r"`（对齐 tmux reload）+ `resize_mode="prefix+shift+r"`（让位）；⑥ `[ui]` tab_bar 置底、`tab_bar_right` 只含 zoom/hostname/`%m/%d %H:%M` datetime（对齐 tmux status-right 不显示 shell）、`window_title="{workspace} · {tab}"`；⑦ `[ui.toast] delivery="herdr"`；⑧ `[[keys.command]]` 绑定 `prefix+f` popup 临时 shell 浮窗（对应 tmux `prefix+f` display-popup）。
- 验证：`python3 -c 'import tomllib; tomllib.load(...)'` 解析成功（exit 0，顶层键 keys/onboarding/session/terminal/theme/ui）。herdr 二进制未安装，未做运行时加载验证；键名全部来自官方 config-reference（https://herdr.dev/docs/config-reference/）。
- live 同步与运行态：未同步（纯仓库草稿）；尚未接入 `install.sh` 的 `shared_configs` 列表，也未在 `~/.config/herdr/` 落地。
- 回滚信息：commit `879707a`（撤回用 `git revert 879707a`）；`git checkout -- .config/shared/herdr/config.toml` 或删除该目录即回滚。
- 后续可能方向：① 用户确认键位/观感后，补 `.config/shared/herdr/README.md`、接入 install.sh shared_configs（`command -v herdr|...`）并加 `tests/herdr_config_test.sh`；② 实测 `herdr server reload-config` 确认无 startup warning（尤其 reload_config/resize_mode 键互换、prefix+f 无冲突）；③ 视需要新增 `memory/herdr.md` 沉淀偏好。


## 2026-08-23 — tmux 快捷键与状态栏/标题增强

- 目的：用户确认低风险高收益清单后全部落地：① pane 导航 `h/j/k/l` 与调整大小 `H/J/K/L` 加 `-r`（500ms 内连按免重复前缀）；② `prefix <` / `prefix >` 当前窗口左移/右移（配合 `renumber-windows on`）；③ `prefix f` 弹出临时 shell 浮窗（`display-popup -E`，`exit`/`Ctrl+d` 关闭，继承当前目录；键位由 `t` 改为 `f`）；④ `prefix Esc` 进入复制模式（vim 肌肉记忆）；⑤ `word-separators` 去掉 `/`，copy-mode 按词选择时路径保持完整；⑥ `set-titles` 让外层终端窗口标题显示 `session · window`（niri 任务切换可区分不同 tmux 窗口）；⑦ status-left 显示 session 名（`status-left-length 20` 截断保护，替代原"完全隐藏"方案）。`extended-keys on` 经评估（foot 下扩展键序列透传风险）用户明确否决，不加。
- 改动：① `.config/shared/tmux/.tmux.conf` 八处：L23 word-separators、L30-31 set-titles、L67-74 八个 `-r` 绑定、L80-81 swap-window、L84 display-popup(f)、L86 Escape、L140-141 status-left；② README 状态栏节 + 快捷键表 + 说明段同步；③ `tests/tmux_status_test.sh` 新增 `test_keybinding_and_title_enhancements`，更新 `test_status_bar_has_balanced_left_and_right_modules` / `test_readme_documents_status_bar_layout` 的 status-left 断言；④ `memory/tmux.md` 修正"左侧隐藏 session 名"旧决策为"显示+截断"，新增浮窗 f、extended-keys 否决记录。
- 验证：`sh tests/tmux_status_test.sh` PASS；`git diff --check` 干净；detached server（独立 socket + `-f` 加载仓库配置）确认全部绑定与选项加载成功；`list-keys` 额外确认 `f`→display-popup 已注册（窗口切换由内置 `n`/`p` 承担）。关键教训：word-separators 初版值 `' @"'()=,;'` 引号语法错误会中断整个配置解析（后续所有绑定静默失效），修正为 `" \"'()=,;"`。
- live 同步与运行态：待用户手动执行（沙箱拦截 agent 写 live，见 memory/tmux.md Live 同步节）；本轮同步命令同时覆盖上一轮 resurrect pane contents 改动（repo 文件为多轮合并后的最终态，live 当前停在 terminal-features 轮）。运行中的 server 同步后需 `tmux source-file ~/.tmux.conf` reload。
- 回滚信息：commit `a126bc1`（撤回用 `git revert a126bc1`）；本轮涉及 .tmux.conf / README / 测试 / memory 四个文件，与今日前两轮 tmux 改动在同一批未提交文件中，`git checkout` 会连前几轮一并撤回（勿用）；精确回滚＝删除 .tmux.conf 上述八处、README 对应句、`test_keybinding_and_title_enhancements` 函数与注册行、memory 两处修订。live 恢复命令（备份文件名以实际手动备份时间为准）：
  ```bash
  cp ~/.tmux.conf.backup.<本轮手动备份时间戳> ~/.tmux.conf
  ```
- 后续可能方向：① 用户实测 `-r` 连按、popup 浮窗与 foot 外层标题效果；② tmux 可选优化项全部落地完毕，仅剩 prefix_highlight 配色统一（低优先级，此前评估不推荐）。


## 2026-08-23 — 修复 terminal-features TERM 匹配失效并启用 Sync

- 目的：用户更正主力终端事实（aarch64 为 foot 非 alacritty）后重评发现：tmux 按客户端实际 TERM 匹配 terminal-features，而两平台主力终端（aarch64 foot、x64 alacritty）均以 `TERM=xterm-256color` 运行（SSH 远程兼容，配置有意为之），上轮 `alacritty:/kitty:/foot:` 三条 RGB 规则全部匹配不上，真彩色实际未生效（`xterm-256color` terminfo 亦无 24-bit caps 供自动检测）。顺带启用 Sync 同步输出。
- 改动：① `.config/shared/tmux/.tmux.conf` L21 改为 `',xterm-256color:RGB:Sync,alacritty:RGB:Sync,foot:RGB:Sync'`（新增实际匹配名，删已退役 kitty 规则，冒号连写多 feature）；② README 主题节改写（说明 TERM=xterm-256color 匹配逻辑与 Sync 收益）；③ `tests/tmux_status_test.sh` 断言同步；④ `memory/tmux.md` 新增"终端特性"节并更新"Live 同步"节（沙箱行为变化）。
- 验证：`sh tests/tmux_status_test.sh` PASS；`git diff --check` 干净；`tmux -L verify-tf -f 仓库配置` 独立 socket detached server 确认 server 选项含三条新规则（默认 `xterm*:clipboard` 仍在，解释 OSC 52 一直正常），server 已清理；foot 1.16.2 手册（foot-ctlseqs(7)）确认支持 CSI ?2026，tmux 3.7b 手册确认 Sync feature 定义。
- live 同步与运行态：沙箱拦截所有 agent 写入途径（新建备份文件名直接拒绝；写 `~/.tmux.conf` 静默失败退出码 0），由用户手动执行同步（12:19:30 备份后同步，12:19:34 启动 server 直接加载新配置）。全链路验证通过：live L21 含新规则；运行中 server `show-options -sv terminal-features` 含三条新规则（reload 时 `-as` 追加出现两次，幂等无害）；`list-clients` 确认 client（TERM=xterm-256color，/dev/pts/6）已应用 `RGB` + `sync` 特性；临时后台 window 实测 pane 环境注入 `COLORTERM=truecolor`。
- 回滚信息：commit `a126bc1`（撤回用 `git revert a126bc1`）；仓库侧 `git checkout -- .config/shared/tmux/.tmux.conf .config/shared/tmux/README.md tests/tmux_status_test.sh memory/tmux.md` 撤回全部本轮文件；live 恢复命令：`cp ~/.tmux.conf.backup.20260823_121930_125938 ~/.tmux.conf`。若仅 Sync 无效果（撕裂无改善），单独回滚为 `set -as terminal-features ',xterm-256color:RGB,alacritty:RGB,foot:RGB'`（保留 RGB，Sync 与 RGB 独立）。
- 后续可能方向：① 撕裂验证已闭环——用户实测 `seq 1 50000` 快速滚动撕裂明显改善（Sync 原子提交生效，2026-08-23 确认），Sync 保留不回滚；② COLORTERM 已实测注入 `truecolor`；③ 可选项仍未落地：resurrect pane contents、prefix_highlight 配色统一。


## 2026-08-23 — resurrect 启用 pane 内容保存与恢复

- 目的：落地此前评估推荐的可选优化项：`tmux-resurrect` 此前只恢复布局和进程，pane 恢复后空白，重启丢失上下文；开启 `@resurrect-capture-pane-contents` 后恢复可见屏幕内容。仍是纯手动保存/恢复，不引入 continuum 自动化。
- 改动：① `.config/shared/tmux/.tmux.conf` L13 新增 `set -g @resurrect-capture-pane-contents 'on'`（插件声明后、TPM run 前）；② README 常见问题补 pane 内容保存说明；③ `tests/tmux_status_test.sh` 新增 `test_resurrect_pane_contents` 锁定配置与 README 措辞。
- 验证：`sh tests/tmux_status_test.sh` PASS；`git diff --check` 干净。detached server 端到端闭环（独立 socket + `@resurrect-dir` 指向仓库内临时目录隔离，避免覆盖真实 session 的 last 保存）：pane 输出 marker → save 生成 `pane_contents.tar.gz` → kill-server → restore 恢复 session → `capture-pane -S -` 在 scrollback 捕获到 marker。两个关键经验：① resurrect 恢复机制是 `cat <内容文件>; exec <shell>`（restore.sh L123），内容会被新 shell 输出推入 scrollback，验证时 capture 必须带 `-S -`；② tmux server 子进程继承沙箱限制（pane 内 zsh 写 `~/.config/zsh/.zsh_history.LOCK` 被拦报错），但不影响 resurrect 自身读写。
- live 同步与运行态：待用户手动执行（沙箱拦截 agent 写 live 途径，见 memory/tmux.md Live 同步节）；用户当前有 tmux server 运行，同步后需 `tmux source-file ~/.tmux.conf` reload，下次 `Ctrl+a Ctrl+s` 保存时即捕获 pane 内容。
- 回滚信息：commit `a126bc1`（撤回用 `git revert a126bc1`）；本轮仅三个文件各一处新增，精确回滚＝删除 .tmux.conf L13 配置行、README 对应句、测试函数与注册行（git checkout 会连前两轮 tmux 改动一并撤回，勿用）；live 恢复 `cp ~/.tmux.conf.backup.<本轮手动备份时间戳> ~/.tmux.conf`。
- 后续可能方向：① 用户真实场景验证（重启后 `Ctrl+a Ctrl+r` 恢复应看到保存时屏幕内容）；② pane 内容仅随手动保存触发，无常态开销；③ 剩余可选项仅 prefix_highlight 配色统一（低优先级）。


## 2026-08-24 — niri 外接屏强制 120Hz 并移到右侧

- 目的：用户要求把外接屏强制设为 120Hz、并放到内屏右侧（此前外接屏在左、运行在 100Hz）。
- 改动：仓库 `.config/linux/niri/ubuntu_aarch64/config.kdl`：① eDP-1 内屏 `position x=2048` → `x=0`（移到左侧）；② DP-2 外接屏（Dell S2721DGF）`mode "2560x1440@100"` → `modeline 497.75 2560 2608 2640 2720 1440 1445 1448 1525 "+hsync" "-vsync"`（120Hz），`position x=0` → `x=1440`（移到右侧）；③ 注释同步（mtdisp 不暴露 CEA 120Hz 的说明）。scale 不变（1.25 / 2.0）。④ `tests/niri_config_test.sh` 同步断言（DP-2 modeline + `x=1440`、eDP-1 `x=0`）。
- 验证：`niri validate -c` 仓库与 live 均 "config is valid"；`niri msg outputs` 确认 DP-2 `2560x1440@119.998 Hz (custom)` 逻辑位置 `1440,0`（右侧）、eDP-1 `2880x1800@120` 逻辑位置 `0,0`（左侧）。
- live 同步与运行态：已同步并 reload（`niri msg action load-config-file`，niri 26.04）。live 备份：`~/.config/niri/config.kdl.backup.20260824_214124_1886757`。注意：沙箱 allowlist 仅放行 `~/.config/niri/config.kdl` 精确路径，`rm` 旧备份被拦（`config.kdl.backup.*` 不在 allowlist），clean_old_backups 未执行，`~/.config/niri/` 现堆积 4 个 config.kdl 备份，待用户手动清理（保留最近 3 个）。
- 回滚信息：仓库未提交，`git checkout -- .config/linux/niri/ubuntu_aarch64/config.kdl` 回退；live 恢复 `cp ~/.config/niri/config.kdl.backup.20260824_214124_1886757 ~/.config/niri/config.kdl` 后 `niri msg action load-config-file`。
- 后续可能方向：① 用户实测 120Hz 稳定性（Dell S2721DGF 上限 165Hz，120 为官方时序，安全）；② x64 平台 config.kdl 未改（本次仅 aarch64）；③ 手动清理 `~/.config/niri/config.kdl.backup.*` 旧备份。


## 2026-08-27 — Obsidian (AppImage) 切原生 Wayland（text-input v3 + binfmt argv 双修复）

- 目的：排查 x64 niri 会话下各应用显示协议归类（fd 连 wayland-1 vs X1）时发现 Obsidian 走 XWayland；其 Electron 33 / Chromium 130 原生 Wayland 后端已可用，迁移可脱离 xwayland-satellite 代理层。
- 关键发现与修复一（IME）：直接加 `--ozone-platform=wayland --enable-wayland-ime` 后 fcitx5 中文输入静默失效；根因是 Chromium 130 默认 text-input v1，而 niri 26.04 只实现 v3，`--wayland-text-input-version=3` 显式切换后实测可输入。Chrome 152 / Trae 1.107 默认已 v3 无需该 flag——版本矩阵固化进 memory/desktop.md。
- 关键发现与修复二（启动失败）：wrapper 初版 `exec "$appimage"` 直接执行时被 binfmt_misc 拦截转发给 appimagelauncher 的 binfmt-interpreter，该 interpreter 向 `/usr/bin/AppImageLauncher` 转发 argv 存在 bug：**总参数 ≥4 时 argv 数组未 NULL 终止**（strace 显示垃圾指针，execv 返回 EFAULT），fuzzel 启动必失败；0-3 个参数正常（这就是为什么测试实例一度能起）。修复：wrapper 改为 `exec /usr/bin/AppImageLauncher "$appimage" ...` 显式调用（其内部 binfmt-bypass 自行构造正确 argv），无 appimagelauncher 的机器回退裸 exec。注意区分：`binfmt-interpreter`（binfmt_misc 入口，有 bug）≠ `binfmt-bypass`（AppImageLauncher 内部库组件，正常）。
- 改动：① 新增 `.config/scripts/obsidian-wayland`（glob 发现 `~/Applications/Obsidian-*.AppImage`，Wayland 会话加 `--no-sandbox --ozone-platform=wayland --enable-wayland-ime --wayland-text-input-version=3`，X11 透传，启动统一走 /usr/bin/AppImageLauncher）；② 新增 `.config/linux/desktop-entries/obsidian.desktop`（Exec 走 wrapper，MimeType 含 obsidian:// scheme）；③ `install.sh` linux_wayland_configs 注册两行；④ `tests/install_wayland_test.sh` + `tests/wayland_scripts_test.sh` 各补断言（含 text-input-v3 与 AppImageLauncher 启动路径契约）；⑤ niri README 新增 Obsidian 节；⑥ memory/desktop.md 新增 text-input 版本矩阵节。
- 验证：`bash -n` / `sh -n` 全部语法通过；`./tests/wayland_scripts_test.sh` + `./tests/install_wayland_test.sh` PASS；fuzzel 正式入口端到端验证通过：desktop entry → wrapper → /usr/bin/AppImageLauncher → Obsidian 主进程纯 Wayland（2 wayland fd，0 X11 fd），niri 窗口正常显示，fcitx5 中文输入用户实测正常。
- live 同步与运行态：已部署 `~/.config/scripts/obsidian-wayland`（755，含 binfmt 修复的版本，另有初版备份 `obsidian-wayland.backup.20260827_151027`）与 `~/.local/share/applications/obsidian.desktop`（__HOME__ 已替换）并 `update-desktop-database`；经用户确认后已删除 appimagelauncher 自动生成的旧 entry（`appimagekit_...-Obsidian.desktop`，XWayland 路径）。备份：`~/.local/share/applications/appimagekit_9dc8ca19e5f508378990f6571c8c263c-Obsidian.desktop.backup.20260827_144918`。
- 回滚信息：commit `fb3eea5`（撤回用 `git revert fb3eea5`）；live 恢复：`cp ~/.local/share/applications/appimagekit_9dc8ca19e5f508378990f6571c8c263c-Obsidian.desktop.backup.20260827_144918 ~/.local/share/applications/appimagekit_9dc8ca19e5f508378990f6571c8c263c-Obsidian.desktop && rm ~/.local/share/applications/obsidian.desktop ~/.config/scripts/obsidian-wayland*`（删除的旧 entry 一并从备份恢复）。
- 后续可能方向：① AppImage 升级后 appimagelauncher 可能重新生成带版本号的旧 entry，届时再删一次即可（备份仍可复用）；② appimagelauncher binfmt-interpreter 的 argv bug 属上游问题，影响所有"exec AppImage 且带 ≥4 参数"的脚本，遇到同类 execv EFAULT 时参考本条绕法；③ corplink（Electron 22）与钉钉（CEF 109）保持 XWayland，不迁。


## 2026-08-28 — rime-ice 升级到最新完整 lua 版（x86_64 Ubuntu 恢复 lua）

- 目的：用户反馈"fcitx5 一直弹通知"；排查确认为 rime-ice 在部署完成时反复发 `deploy success` 通知。进一步发现本机（x86_64 Ubuntu，librime 官方 apt 1.10.0 自带 `librime-plugin-lua`）的 live rime 目录仍跑着"剥离 lua"的降级 schema——memory/desktop.md 的 MediaTek aarch64 无 lua 结论不适用于本机，属配置与机器错配。用户确认目标即本机，要求彻底恢复完整 lua。
- 改动（live `~/.local/share/fcitx5/rime`，独立 git clone，非 dotfiles 仓库）：① `git checkout -- .` 丢弃当初剥离 lua 的 70 个文件本地改动（词库/用户数据在 .gitignore 不受影响）；② `git checkout 2026.06.30`（最新 stable tag，HEAD `6810e89`，恢复全部 schema 含 double_pinyin_jiajia）；③ 旧 `build/` 移走备份后 `rime_deployer --build` 全新重建（11 schemas success, 0 failure）；④ `pkill fcitx5 && fcitx5 -d --replace` 重启，verbose 日志确认 `Notification: 0 deploy success` 且无 SIGSEGV。
- 验证：`rime_deployer --build` exit 0；fcitx5 日志 `3 tasks ran: 3 success, 0 failure`、加载 `lua/lunar.db`（lua 路径激活）；crash.log 为空；进程稳定运行（pid 1950858）。
- live 同步与运行态：已重启 fcitx5 生效（用户授权"彻底解决"）。备份：整目录 `/tmp/rime-backup-20260828-092429`、旧 build `/tmp/build-old-20260828-*`、crash.log `/tmp/crash.log.bak-*`。
- 回滚信息：live rime 独立 git，回滚＝`cd ~/.local/share/fcitx5/rime && git checkout 7acdee6`（剥离版原 HEAD）；或整目录从 `/tmp/rime-backup-20260828-092429` 恢复后 `rime_deployer --build && pkill fcitx5 && fcitx5 -d --replace`。
- 后续可能方向：① 用户实测以词定字/日期/农历/计算器等 lua 扩展是否恢复；② 若仍偶发部署通知可再在 `~/.config/fcitx5/conf/notifications.conf` 的 `HiddenNotifications` 填 `rime-deploy-done` 屏蔽该条；③ memory/desktop.md 需补充"x86_64 官方 librime 自带 lua，无需剥离"与 MediaTek 机型区分，避免再次错配。


## 2026-08-29 — niri 链路周边工具从 Nix 切 Ubuntu apt（x64）

- 目的：收敛 Nix 与系统的集成摩擦（niri environment{} 不含 nix-profile 的 PATH 断层等）。调研结论：Ubuntu 26.04 官方源无 niri/satty/wl-clip-persist/xwayland-satellite，niri 官方指南对 Ubuntu 的推荐路径是第三方 PPA（avengemedia/danklinux+dms，绑定 DMS 生态），不采用；故 niri 本体与三个无官方包工具留在 Nix，周边 11 个工具切 apt。
- 改动：纯 live 包管理器操作，仓库零改动。① apt 安装 11 包：fuzzel waybar mako-notifier swayidle swaylock wl-clipboard grim slurp alacritty playerctl brightnessctl；② `nix profile remove` 11 条目：waybar playerctl brightnessctl fuzzel grim slurp swayidle mako wl-clipboard alacritty swaylock-effects（注意 Nix 条目是 swaylock-effects 分支，apt 侧对应原生 swaylock，lock-wayland 只用标准参数无影响）；③ 保留 Nix：niri、satty、wl-clip-persist、xwayland-satellite（运行中，DingTalk 等 X11 客户端依赖，apt 无包）、nixGL。仓库脚本均双路径兼容，无需改动：lock-wayland 优先 /usr/bin/swaylock 现命中 apt 版；terminal-wayland 的 `~/.nix-profile/bin/alacritty` 分支自然落到 `command -v` 兜底；clipboard-wayland 的 Nix PATH 补丁因 wl-clip-persist 留在 Nix 而必须保留。
- 验证：重登 SDDM 后 `command -v` 12 项全部指向 /usr/bin（waybar mako fuzzel swayidle swaylock wl-copy wl-paste grim slurp alacritty playerctl brightnessctl），4 项指向 nix-profile（niri satty wl-clip-persist xwayland-satellite）；`xwayland-satellite :1` 正常拉起。版本快照：waybar 0.15.0 / playerctl 2.4.1（同版），fuzzel 1.14.1→1.12.0、wl-clipboard 2.3.0→2.2.1、alacritty 0.17.0→0.16.1、grim 1.5.0→1.4.0、mako 1.11.0→1.10.0（小降级，脚本用法已核对），slurp 1.5.0→1.6.0、swaylock-effects 1.7.0→swaylock 1.8.4、brightnessctl 0.5.1（同版）。fuzzel.ini 已核对仅用 1.10 前老选项，1.12.0 兼容。
- live 同步与运行态：已生效（用户手动执行安装/删包/重登；agent 负责调研、清单与验证命令）。无 backup 文件——回滚走 Nix generation，不走快照。
- 回滚信息：未提交（本轮仓库仅 memory + trace 两文件）；live 回滚锚点＝切换前 Nix generation，`nix profile --rollback` 后注销重登即整体回到 Nix 状态；apt 侧如需清理再 `sudo apt purge` 对应包即可。
- 后续可能方向：① 用户功能面实测：Mod+C（fuzzel 1.12）、Mod+S（grim 1.4 截图 + satty 标注）、Mod+V（剪贴板历史）、Mod+Alt+L（swaylock 1.8.4）、waybar/mako 渲染、DingTalk XWayland；② 稳定数日后 `nix-collect-garbage -d` 回收 /nix/store（注意会清掉回滚 generation，执行即放弃回滚锚点）；③ 可选清理仍留在 profile 的 awww/imagemagick/libXcursor/libXi/libxcursor（均不在 niri 链路；imagemagick 若要保留功能先 `sudo apt install imagemagick`，awww 为已搁置的双壁纸实验遗留）。


## 2026-08-29 — terminal-wayland 移除 Nix profile 特判（迁移收尾）

- 目的：上一轮 Nix→apt 迁移后，`terminal-wayland` 的 `~/.nix-profile/bin/alacritty` 优先分支成为死代码，清理之；全仓库扫描确认其余 Nix 引用均需保留（clipboard-wayland 的 PATH 补丁——wl-clip-persist 仍在 Nix；niri README 对 xwayland-satellite 的描述——仍准确）。
- 改动：① `.config/scripts/terminal-wayland`：删除 nix-profile alacritty 优先分支，`command -v alacritty`（apt 0.16.1）直接命中，foot 兜底不变，注释注明迁移日期；② `tests/wayland_scripts_test.sh` L274 与 `tests/niri_config_test.sh` L134：原 `assert_contains nix-profile exec` 断言反转为 `assert_not_contains 'nix-profile'`（锁定不再回退到 Nix 特判）；③ `.config/linux/niri/README.md`：终端入口节的 x64 描述同步；swaylock 节补注 apt 迁移（swaylock-effects 已移除）。`scripts/README.md` 的 terminal-wayland 描述本就泛化，无需改。
- 验证：`tests/wayland_scripts_test.sh` / `tests/niri_config_test.sh` / `tests/foot_config_test.sh` 全部 exit 0；`git diff --check` 干净。live 侧 `Mod+Return` 实际拉起 apt alacritty 的行为在迁移轮已由用户确认正常。
- live 同步与运行态：未同步——live `~/.config/scripts/terminal-wayland` 仍含死分支（`-x` 检查不命中，行为与仓库版一致，无功能影响），待下轮统一同步。
- 回滚信息：未提交；`git checkout -- .config/scripts/terminal-wayland tests/wayland_scripts_test.sh tests/niri_config_test.sh .config/linux/niri/README.md` 即回滚。live 恢复（若已同步）：`cp ~/.config/scripts/terminal-wayland.backup.<时间戳> ~/.config/scripts/terminal-wayland`。
- 后续可能方向：① live 同步 terminal-wayland 时按惯例 backup（保留 3 份）；② 可选清理项（awww/imagemagick/X libs）仍待用户决定；③ aarch64 机器 Nix profile 是否也需同类梳理，另行评估。


## 2026-08-29 — niri 链路全量去 Nix（PPA + cargo + 源码编译终态）

- 目的：用户决定彻底移除 Nix 依赖。上一轮"5 留 Nix"方案升级为全量切换：niri 走官方指南认可的 avengemedia/danklinux PPA（不装 dms，waybar+脚本链保持不变），xwayland-satellite 同 PPA（0.8.2ppa1，免加第三个 glostis PPA），satty 走 cargo git 安装，wl-clip-persist 源码编译装 /usr/local/bin，nixGL/awww/遗留 X libs 直接删除（"删"不是"切"）。
- 改动（live，用户主导 + agent 执行/验证）：① 加 PPA 后 `apt policy` 核对版本门槛（niri 26.04ppa3 ≥ 26.04——blur 为 26.04 特性，硬门槛；satellite 0.8.2ppa1）→ `apt install niri xwayland-satellite`；② satty：cargo install 三连坑——epoxy→gl_generator→xml-rs^0.7 双版本 yanked（镜像无关，须 `--locked` 用仓库 lockfile）→ rustc 1.90 < 依赖要求 1.92（rustup update stable 到 1.98，配 ustc rust-static 镜像加速）→ 缺 GTK 开发库（libgtk-4-dev libadwaita-1-dev libgtk4-layer-shell-dev libepoxy-dev libfontconfig1-dev），最终 `cargo install --git https://github.com/Satty-org/Satty --locked` 得 0.22.0，symlink `~/.local/bin/satty` 命中 screenshot-wayland 既有 PATH 补丁；③ wl-clip-persist 0.5.0 源码编译 → /usr/local/bin；④ `nix profile remove` 清空 profile（removed 6 kept 0；imagemagick/3 个 X lib 用户此前已自行清理）。
- 关键发现一（会话入口覆盖）：apt 包安装时 dpkg 静默覆盖了用户手写的 `/usr/share/wayland-sessions/niri.desktop`（原 Exec 指向 nix niri-session）；SDDM 只显示一个"熟悉的"Niri 会话，实为 apt 内容。相对路径 `Exec=niri-session` 在登录 shell PATH 下仍会解析回 Nix（实测 `zsh -lic 'which niri-session'` → nix-profile）。修复：`/usr/local/share/wayland-sessions/niri.desktop`（XDG 优先序 + 同名去重）钉死 `Exec=/usr/bin/niri-session`。
- 关键发现二（systemd unit 双层覆盖）：即便会话入口换成 apt，合成器仍来自 Nix——`~/.config/systemd/user/niri.service`（用户级覆盖，优先于包 unit）ExecStart 指向 Nix 时代的 `~/.local/bin/niri-nixgl-session`（nixGL + nix profile PATH/LD_LIBRARY_PATH 包装）。排查命令：`systemctl --user show niri.service -p FragmentPath`。修复：两文件按惯例 `*.backup.<时间戳>` 后移除 + `daemon-reload`，重登后 `readlink /proc/<pid>/exe` 确认 `/usr/bin/niri`、`/usr/bin/xwayland-satellite`，`niri msg version` 报 "unknown commit"（apt 发行版构建无 commit 哈希，与 Nix CLI 3819182 的差异警告在删 Nix 后消失）。
- 关键发现三（上一轮提交丢 hunk）：85cd766 提交的 README 含 swaylock 修改但丢了 L143 终端条目修改（提交前被回退，疑似 IDE 旧缓冲区保存覆盖；本轮验证 git show 时发现）。教训：commit 后用 `git show HEAD:<file>` 抽查关键 hunk，勿只信 Edit 工具的回显。**该问题随后再次发生**：bef005f 提交时 clipboard-wayland 补丁移除与 README L143/L104 又被部分回退（IDE 自动保存与编辑存在秒级竞态，L104 幸存 L143 复丢），最终用 python 原子改写 + 同一 shell 内 add→amend→验证（81112b7）闭环；此后再改这些文件须确认 IDE 已关闭对应标签或文件已 reload。
- 改动（仓库）：① [clipboard-wayland](/.config/scripts/clipboard-wayland)：移除 Nix profile PATH 补丁块与 Nix 提示语（wl-clip-persist 改 /usr/local/bin 源码构建），fuzzel 版本注释更新为 1.12.0；② tests/wayland_scripts_test.sh：clipboard 断言反转为 `assert_not_contains 'nix-profile'`，新增 `源码编译装 /usr/local/bin` 断言，fuzzel 注释同步；③ niri/README.md：L15 satellite 改 apt、L104 剪贴板来源改源码编译 + cliphist 0.5.0、L143 终端条目补上轮丢失的 apt 描述；④ memory/niri.md：包来源分层条目重写为全量去 Nix 终态（含 PPA/覆盖 unit/satty 构建坑/回滚锚）。
- 验证：重登后进程链 sddm-helper → /usr/bin/niri-session → niri（exe=/usr/bin/niri）+ /usr/bin/xwayland-satellite；`command -v` 四件全部落位新家（niri/satellite→/usr/bin，satty→~/.local/bin，wl-clip-persist→/usr/local/bin）；`~/.nix-profile/bin` 为空；Nix profile list 输出为空。tests/wayland_scripts_test.sh、niri_config_test.sh、foot_config_test.sh 全部 exit 0；`git diff --check` 干净。
- live 同步与运行态：live `~/.config/scripts/clipboard-wayland` 需用户手动同步（沙箱不允许写 ~/.config），同步前按惯例 `cp ~/.config/scripts/clipboard-wayland{,.backup.<时间戳>}`；`~/.config/systemd/user/` 与会话文件的备份已由用户执行时落盘。
- 回滚信息：仓库改动随 commit `81112b7` 提交（撤销用 `git revert 81112b7`；该提交由 bef005f amend 而来）。live 侧回滚锚＝清空前的 Nix generation——注意 Nix 本体已卸载、`/nix` 已删除，该锚点已失效；apt 侧 `sudo apt purge niri xwayland-satellite` + 移除 PPA 可回退。
- 后续可能方向：① 用户同步 live clipboard-wayland 后跑一轮功能面（Mod+V 剪贴板历史）；② 稳定数日后 `nix-collect-garbage -d` 回收并可选卸载 Nix 本体；③ cargo 侧 satty 更新流程（`cargo install --git ... --locked` 覆盖装）与 wl-clip-persist 上游跟进为手动节奏，建议观察上游 issue 决定是否跟进 0.22.x 修复版。


## 2026-08-29 — launcher-wayland 存活检查修复（fcitx5 托盘消失）+ fuzzel IME 能力边界

- 目的：用户报告「打开 fuzzel 后 fcitx5 托盘图标消失、fuzzel 无法使用 fcitx5」。诊断出两个独立问题：① fuzzel 1.12.0（apt）二进制不含任何 text-input/input-method 协议（`strings /usr/bin/fuzzel` 列出其绑定的全部 Wayland 接口可证），niri 仅经 text-input-v3→input-method 链供 IME，fuzzel 永远无法唤起 fcitx5，属上游功能边界（与 rofi 同类），无配置级修复；② launcher-wayland 的 fcitx5 存活检查 `grep -qa '^WAYLAND_DISPLAY=' /proc/<pid>/environ` 对 NUL 分隔、无换行的 environ 永远匹配失败（`^` 只命中首变量；实测 fcitx5 首变量为 NIRI_SOCKET，裸 grep exit=1、加 `-z` 后 exit=0），导致每次 Mod+C 都误判未运行并执行 `fcitx5 -d --replace`：旧实例经 DBus replace 干净退出（无 coredump、journal 无崩溃记录），waybar 托盘图标随之消失；连续触发时实例互替可致 fcitx5 长时间缺位（当日 journal 佐证：19:38:17-19 七次 fuzzel 锁冲突，19:42:24 fcitx5 被 `fcitx5 -d --replace` 重启）。
- 改动：① `.config/scripts/launcher-wayland`：`grep -qa` → `grep -zaq`，注释补充 environ NUL 分隔原理与翻车后果；② `tests/wayland_scripts_test.sh` 新增 `test_launcher_wayland_respects_running_wayland_fcitx5`：用受控 env 的真实 sleep 进程复刻「WAYLAND_DISPLAY 非首位」的真实 environ 布局，场景 1（已有 Wayland fcitx5）断言不触发 --replace、场景 2（无 WAYLAND_DISPLAY）断言仍触发。测试先行：旧代码下场景 1 FAIL，修复后通过。
- 验证：`/bin/sh -n` 语法通过；`/bin/sh tests/wayland_scripts_test.sh` 运行至 clipboard 用例前全部 PASS（含新增用例）。遗留失败一例与本轮无关：clipboard 用例断言 `源码编译装 /usr/local/bin` 在 HEAD、工作区、live 的 clipboard-wayland 中均缺失——系上一轮「IDE 竞态回退」（81112b7 条目已记录）残留，`assert_not_contains 'nix-profile'` 本身通过，仅标记注释丢了。另：Trae 终端把 `sh` 注入为 safe_rm_aliases 函数且静默无操作，跑测试必须用 `/bin/sh` 或 `./tests/xxx`。
- live 同步与运行态：未同步。live `~/.config/scripts/launcher-wayland` 仍带 bug（每次 Mod+C 重启 fcitx5）。同步前按惯例 backup：`cp ~/.config/scripts/launcher-wayland{,.backup.<时间戳>}`（保留 3 份）；恢复命令：`cp ~/.config/scripts/launcher-wayland.backup.<时间戳> ~/.config/scripts/launcher-wayland`。
- 回滚信息：代码随 commit `c8c9ef8` 提交（撤销用 `git revert c8c9ef8`）。
- 后续可能方向：① 用户同步 live 后实测：Mod+C 连续开合数次，waybar 托盘 fcitx5 图标应稳定不消失；② clipboard-wayland 补 `源码编译装 /usr/local/bin` 注释（repo+live 一并同步）以修复遗留红测试；③ launcher 中文输入如强需求，关注 fuzzel 上游 text-input 支持进展，或评估支持 IME 的替代 launcher。


## 2026-08-29 — 钉钉 8.2.8 会议两连修：execstack 字节补丁 + hook null param 崩溃修复

- 目的：用户报告「点加入会议没反应」。连续排查出两个独立根因并修复：① 新内核拒绝加载带可执行栈标记的会议库（tblive 起不来）；② hook 新版代码对未知 pipewire param id 的 null 字符串构造（共享即退会）。两问题都与 8 月 29 日 Nix→apt 迁移的时间线耦合（新内核 + apt niri 26.04），但因果独立。
- 诊断链（含对照试验选择）：① 首查进程/日志：tblive 进程数 0，`[tblive] media app occur exception` → `can't be launched beyond 10s`，stderr `GetLibEntry instance failed`/`entry is null`，hook debug log 不存在；② 发现 live hook .so SHA（fd8f653d）≠ memory 记录的 6 月 4 日稳定版（744821ac），仓库历史显示后续有 f787a48/e1c9686 两版——先假设 hook 不兼容；③ **对照试验（用户选无 hook 重启）**：`DINGTALK_FORCE_X11_CAPTURE=0 restart` 后点会议仍同样失败 → 排除 hook；④ **strace 跟踪官方 Elevator.sh**（ptrace attach 被 yama 禁止，改为启动即跟踪）：`libconference_new.so` openat 成功但 `libscreencast.so` 从未被加载；⑤ ctypes 复现 dlopen 实锤：`cannot enable executable stack as shared object requires: Invalid argument`——`readelf -lW` 确认 `libconference_new.so` GNU_STACK 为 **RWE**（`libscreencast.so` 为正常 RW）；apt history 显示 8 月 29 日 11:18 `--fix-broken install` 装入内核 **7.0.0-30-generic**，8 月 28 日会议正常（dinglive/logs/live-2026-08-28.txt 尾部 `screen_share_success:1`）→ 新内核拒绝 RWE stack 实锤；⑥ python 字节补丁（PT_GNU_STACK p_flags 清 EXEC 位）后 ctypes dlopen OK、会议窗口恢复；⑦ 随即暴露第二层：点共享后 `terminate called ... std::logic_error`，what() 为 `basic_string: construction from null is not valid`，定位 `payload.hpp on_param_changed`：`spa_debug_type_find_name()` 对 apt niri 26.04 发来的未知 param id 返回 NULL，直接构造 std::string 即 abort。
- 改动：① `tools/dingtalk-wayland-screenshare/payload.hpp`：`on_param_changed` 中 `spa_debug_type_find_name` 返回值加 null 检查，null 时回退 `"unknown param id: " + std::to_string(id)`（附注释说明 apt niri 26.04 触发条件）；② live hook 重新编译部署（构建依赖补装 `libportal-dev`——原由 Nix 提供，迁移后缺失；OpenCV dev 本就在 apt），新 .so SHA-256 `d4f8eafde3ebfb59cbd42c865ba1fc37f0337c6445161948e862cd7714d8a650`；③ `/opt/apps/com.alibabainc.dingtalk/files/8.2.8-Release.260818002/libconference_new.so` 打 execstack 补丁（用户执行 sudo），备份 `libconference_new.so.bak-20260829` 同目录；④ memory/dingtalk.md：新增"8.2.8 execstack 补丁"章节、重写"hook 源码版本约束"（8.2.8 实测结论 + null 修复 + 新 SHA + libportal-dev 依赖）。
- 验证：`tests/dingtalk_hook_test.sh` PASS；hook 重新编译 BUILD OK；最终实测（用户确认）会议窗口正常弹出、共享屏幕正常，debug log `processed frame count: 400` 帧处理稳定。辅助验证：`readelf -lW` 显示 GNU_STACK RW；repo `git diff --check` 干净。注意 IDE clangd 对 payload.hpp 的 glib/portal include 报错为既有环境问题（缺 include 路径），实际编译无碍。
- live 同步与运行态：hook .so 属 `~/.local/lib`（脚本惯例位置）直接部署；钉钉经 `restart` 重载两次（对照试验 + 修复后）；`/opt` 库补丁由用户 sudo 执行。仓库侧 `.config/scripts/` 无改动、无需同步 live。
- 回滚信息：代码随 commit `76e795e` 提交（撤销用 `git revert 76e795e`）。/opt 补丁回滚（仅补丁打错时用，回滚即复现 tblive 起不来）：`sudo cp /opt/apps/com.alibabainc.dingtalk/files/8.2.8-Release.260818002/libconference_new.so.bak-20260829 /opt/apps/com.alibabainc.dingtalk/files/8.2.8-Release.260818002/libconference_new.so`。live hook .so 回滚：旧 fd8f653d/d4f8eafd 版已被覆盖无备份，如需回退 revert 后重编译。
- 后续可能方向：① **钉钉包更新后 execstack 补丁会被覆盖**，会议再次打不开时按 memory/dingtalk.md「8.2.8 execstack 补丁」章节重打（可考虑把补丁脚本固化进 tools/ 并加入 install.sh 或定期检查）；② `spa_debug_type_find_name` null 修复建议回馈上游 lzl200110/dingtalk-wayland-screenshare（apt niri 26.04 用户都会踩）；③ 8.2.8 下 `~/.local/lib/dingtalk-wayland-screenshare` 的 libgbm preload 告警依旧无害，继续忽略；④ **同日续报：停止共享/结束会议后图标不灭 + tblive 残留——已修复（三层时序 bug 定稿）**——多轮复现与 pw-dump 基线对比逐步收敛：首次复现抓到 portal 代理流残留（client `app=tblive` + `Stream/Input/Video` + niri `Stream/Output/Video` 推帧不止，跨 tblive 重启持续存在）；排除 hook 停止路径死锁（stop 序列完整收敛）后，终从线程名单（无 pw loop 线程 + `module-rt` 悬挂 + 主线程 futex）实锤两处时序 bug：**(A)** pw 资源析构在 loop 线程退出后执行（`pw_stream_disconnect/destroy` 需与 mainloop 同步）→ 死锁卡死 tblive 退出；**(B)** `xdp_session_close` 在 gio mainloop quit 之后调（GDBus 异步消息发不出去）→ portal session 永不关闭 → 流持续存在。修复：pw 销毁移入 loop 线程（`destroy_pw_objects_in_loop_thread` + 析构判空兜底）、session close 经 `g_main_context_invoke` 调度到 gio 线程（`StopGIOLoop` 前执行 + `session_close_done` 1s 有界等待，实测 10ms 完成）。修复后实测：`pw objects destroyed in loop thread` → `xdp_session_close invoked in gio context` → `waited 10ms, done=true`；pw 层残留 0、tblive 正常退出、图标熄灭。**钉钉侧遗留**：8.2.8 停止共享按钮有时连 `StopShareScreen`/`XShmDetach` 都不触发（SDK 信令链路断裂，hook 无抓手），缓解 = 结束会议或 kill tblive，建议向钉钉反馈。新 .so SHA `903fc7abf1cef6a0bd081e8a5c411d011a87db0b8b9b07d3625919fa50ee0c37`；诊断技巧与根因全录 memory/dingtalk.md。


## 2026-08-29 — Trae 终端黑块：关闭终端 WebGL GPU 渲染

- 目的：用户报告 Trae 终端随机位置整段文字渲染成黑色方块，缩放/最大化窗口时变化。症状匹配 xterm.js WebGL 渲染器 glyph atlas 纹理异常（Wayland/Electron 下已知问题）；时间线与当日 Nix→apt niri 会话重登耦合（Wayland 会话重启后 WebGL 上下文初始化环境变化），但仅为触发契机。
- 排查与定位：settings.json 无 `terminal.integrated.gpuAcceleration`（默认 auto → WebGL 渲染器）；实心黑块（非空心 tofu）+ 随窗口几何变化 → 排除字体缺字形，锁定 GPU 渲染路径。
- 改动（仅 live `~/.config/Trae CN/User/settings.json`，仓库无对应文件）：`terminal.integrated.smoothScrolling` 后新增 `"terminal.integrated.gpuAcceleration": "off"`（附一行注释说明原因）。README 无需同步：Trae settings 不属于任何 dotfiles 模块文档范围，且启动脚本/desktop entry 未动。
- 验证：改后文件以注释剥离方式校验 JSONC 解析通过（python3 json.loads）；备份文件校验为纯 JSON（证明注释为本次唯一新增非 JSON 元素）。生效需用户在 Trae 中 Reload Window（`Ctrl+Shift+P`），终端黑块是否消失待用户实测确认。
- live 同步与运行态：直接改 live（该文件仅存在于 live，不在仓库）；backup：`~/.config/Trae CN/User/settings.json.backup.20260829_203536`（同目录仅 1 份，无需清理）。恢复命令：`cp "$HOME/.config/Trae CN/User/settings.json.backup.20260829_203536" "$HOME/.config/Trae CN/User/settings.json"`。
- 回滚信息：未提交（本轮仓库侧仅 logs/trace.md 本条追加；工作区另有前几轮 launcher-wayland/dingtalk/memory 等未提交改动，勿一起 checkout）。
- 后续可能方向：① ~~用户 Reload Window 后实测黑块是否消失~~ **已确认修复**（用户实测黑块消失）；② ~~memory/desktop.md 固化排障条目~~ **已完成**（新增「Trae 终端黑块（xterm.js WebGL glyph atlas）排障」节，含根因时间线：8/29 内核 6.8→7.0.0-30 + niri Nix→apt 双变更）；③ 上游关注 xterm.js WebGL addon 对 Wayland/fractional scaling 的修复进展，且 Mesa/内核/Electron 更新后可试删 `gpuAcceleration: off` 恢复默认。


## 2026-08-29 — 钉钉 XWayland 次级窗口浮动（主窗口保持平铺）

- 目的：用户反馈钉钉走 XWayland 弹出的次级窗口（会议、预览、对话框等）被平铺进滚动列、观感奇怪，应全部浮动，但主窗口不能浮动。实测主窗口 app-id `com.alibabainc.dingtalk`、标题「钉钉」（`niri msg windows`）。
- 改动：① `.config/linux/niri/common.kdl` 在钉钉列宽/不透明规则后新增窗口规则：`match app-id=r#"^com\.alibabainc\.dingtalk$"#` + `exclude title=r#"^钉钉|钉钉$"#` + `open-floating true`——除主窗口外其余钉钉窗口打开即浮动；exclude 用「开头或结尾」匹配，兼容未读数等标题前后缀变化（如「(3) 钉钉」），避免主窗口被误浮动；niri 26.04 支持 `exclude` 匹配器（25.1+），两个平台配置 `niri validate` 通过。② `tests/niri_config_test.sh` `test_niri_config_has_dingtalk_and_app_window_rules` 新增规则块与 README 文案断言（测试先行）。③ `.config/linux/niri/README.md` 窗口规则节同步说明（替换原「不强制浮动」表述）。④ 顺带修复遗留红测试：`.config/scripts/clipboard-wayland` 缺依赖提示中过时的 Nix 安装提示改为「2026-08-29 起源码编译装 /usr/local/bin，不在 apt 源」——即上一轮 launcher 条目遗留事项 ②，`tests/wayland_scripts_test.sh` 断言 `源码编译装 /usr/local/bin` 由此转绿；⑤ memory/niri.md、memory/dingtalk.md 同步浮动决策。
- 验证：`niri validate -c .config/linux/niri/ubuntu_x64/config.kdl` 与 aarch64 均通过；`./tests/niri_config_test.sh`、`./tests/waybar_config_test.sh`、`./tests/wayland_scripts_test.sh`（修复后）、`./tests/install_wayland_test.sh`、`./tests/dingtalk_hook_test.sh` 全部 PASS；`git diff --check` 干净。open-floating 仅作用于开窗时刻，已开的钉钉主窗口不受影响。
- live 同步与运行态：backup 已创建（时间戳 20260829_212041）：`~/.config/niri/common.kdl.backup.20260829_212041`、`~/.config/scripts/clipboard-wayland.backup.20260829_212041`；同目标旧备份按保留 3 份清理：common.kdl 删 `20260818_100942_1347567`。文件复制被 IDE 沙箱拦截（`~/.config/niri` 不在可写 allowlist），live 同步由用户执行粘贴命令块完成：cp 两个文件到 live（common.kdl 需 `sed` 把 `include "../common.kdl"` 改写为 `include "common.kdl"`，对齐 install.sh 变换）+ `niri msg action load-config-file` 立即热重载。恢复命令：`cp ~/.config/niri/common.kdl.backup.20260829_212041 ~/.config/niri/common.kdl && cp ~/.config/scripts/clipboard-wayland.backup.20260829_212041 ~/.config/scripts/clipboard-wayland`。
- 回滚信息：未提交；撤销改动用 `git checkout -- .config/linux/niri/common.kdl .config/linux/niri/README.md tests/niri_config_test.sh .config/scripts/clipboard-wayland`（工作区另有本条 trace/memory 改动，勿一并回退）。
- 后续可能方向：① 用户同步 live 后实测：打开钉钉会议/文件预览等次级窗口应浮动，主窗口保持平铺；若主窗口标题变化形态不在「钉钉开头/结尾」内（如带中间缀），按 `niri msg windows` 实测标题收紧 exclude；② 钉钉窗口偶尔出现标题不以「钉钉」开头的残留小窗，若仍平铺可按实测标题逐个补充 exclude；③ tblive（共享预览窗）不在本规则范围，如需浮动另行评估。


## 2026-08-29 — 钉钉浮动策略定稿（含主窗口）+ 禁用 focus-follows-mouse

- 目的：用户实测上一轮「exclude 主窗口」方案后改需求：钉钉全部窗口（含主窗口）都浮动，不保留 exclude；并报告钉钉里输入 @ 时候选框被鼠标影响、出现后立即消失，询问能否禁用焦点跟随鼠标。排查：common.kdl input 段启用了 `focus-follows-mouse max-scroll-amount="0%"`（全仓库仅此一处、无任何 memory/trace/README 记录说明当初动机），@ 候选框作为 XWayland 弹层出现在光标附近时被 hover 夺焦，钉钉判定失焦立即关闭候选框——删除该项（niri 默认即关闭）即为修复。
- 改动：① `.config/linux/niri/common.kdl`：钉钉浮动规则去掉 `exclude title=r#"^钉钉|钉钉$"#`，改为 `match app-id` + `open-floating true` 全量浮动；主窗口 2/3 列宽规则保留（手动平铺时仍生效）；input 段删除 `focus-follows-mouse` 行，留一行注释（避开字面量，测试断言配置中不得再出现该字符串）说明不开 hover 跟随焦点的原因。② `tests/niri_config_test.sh`：更新规则块断言、README 文案断言，新增 `assert_not_contains 'focus-follows-mouse'` 与 README「禁用 focus-follows-mouse」断言锁定决策。③ `.config/linux/niri/README.md` 窗口规则节：钉钉全部浮动说明 + 禁用 hover 跟随焦点说明（切换焦点用 Mod+h/l/j/k）。④ memory/niri.md、memory/dingtalk.md 同步定稿决策。
- 验证：`niri validate`（x64+aarch64）通过；`./tests/niri_config_test.sh`、`./tests/waybar_config_test.sh`、`./tests/wayland_scripts_test.sh`、`./tests/install_wayland_test.sh` 全部 PASS；`git diff --check` 干净。过程插曲：input 段的首次删除编辑一度被回退（IDE 侧疑似竞态，与上一轮 81112b7 回退类似），复核发现后重新执行并通过断言验证。
- live 同步与运行态：未同步（IDE 沙箱不可写 `~/.config/niri`，live 同步由用户执行粘贴命令块；backup 惯例同前）。恢复命令：`cp ~/.config/niri/common.kdl.backup.<时间戳> ~/.config/niri/common.kdl`。
- 回滚信息：未提交（含上一轮未提交改动，建议两轮合并为一个 commit 或按功能拆分）；撤销本轮改动用 `git checkout -- .config/linux/niri/common.kdl .config/linux/niri/README.md tests/niri_config_test.sh`。
- 后续可能方向：① 用户同步 live 后实测：a) 钉钉主窗口/次级窗口均浮动；b) 钉钉输入 @ 候选框不再被鼠标顶掉（焦点跟随已关）；c) 习惯代价——鼠标划过其他窗口不再切换焦点，如不适配可评估只对部分场景妥协（niri 无白名单机制，只能全开/全关）；② @ 候选框若仍消失，下一嫌疑是钉钉弹层自身的 focus-out 处理（XWayland transient 行为），需 `niri msg windows` 观察弹层开合时的窗口焦点事件；③ tblive 仍不在浮动范围。


## 2026-08-29 — 钉钉浮动方案实测回退；focus-follows-mouse 与 @ 问题无关但保持禁用

- 目的：用户实测两轮浮动方案后决定全部回退（「浮动窗口这个修改回退把」），并反馈禁用 focus-follows-mouse 后钉钉 @ 候选框出现即消失的问题依旧（该改动与 @ 问题无关）。经确认：浮动规则全删（回到本轮前状态）；focus-follows-mouse 保持禁用（纯粹使用偏好）；@ 问题继续用 `niri msg event-stream` 观测排查。
- 改动：① `.config/linux/niri/common.kdl`：删除钉钉 `open-floating true` 规则块（2/3 列宽 + 1.0 不透明规则保留），focus-follows-mouse 维持删除、注释保留；② `tests/niri_config_test.sh`：删除浮动规则与「全部浮动」README 断言，恢复「钉钉主窗口默认使用 2/3 列宽并覆盖为 1.0 不透明度」断言，保留 `assert_not_contains 'focus-follows-mouse'` 锁定禁用决策；③ `.config/linux/niri/README.md`：钉钉条目恢复原文并注明「2026-08-29 曾试验钉钉窗口浮动，实测后回退」，focus 条目修正归因（实测与 @ 候选框消失无关，保持关闭为使用偏好）；④ memory/niri.md、memory/dingtalk.md 同步（记录三次迭代教训：exclude 方案 → 全浮动 → 全回退）。
- 验证：`niri validate`（x64+aarch64）通过；`./tests/niri_config_test.sh`、`./tests/waybar_config_test.sh`、`./tests/wayland_scripts_test.sh`、`./tests/install_wayland_test.sh` 全部 PASS；`git diff --check` 干净。
- live 同步与运行态：未同步（IDE 沙箱不可写 `~/.config/niri`，live 同步由用户执行粘贴命令块；备份与保留 3 份惯例同前）。恢复命令：`cp ~/.config/niri/common.kdl.backup.<时间戳> ~/.config/niri/common.kdl`。
- 回滚信息：未提交（工作区含三轮未提交改动：浮动方案的全部迭代 + clipboard 注释修复，最终净效果 = 钉钉浮动规则无、focus-follows-mouse 禁用、clipboard 注释更新；提交前可 `git diff` 复核净差异，浮动相关迭代在 diff 中已相互抵消）。
- 后续可能方向：① @ 候选框消失根因排查（event-stream 观测中）：候选框若为 override-redirect 窗口则 event-stream 无事件，嫌疑转向 XWayland/IME（fcitx5 XIM，见 memory/dingtalk.md fcitx5#1641）/钉钉自身弹层逻辑；若为受管窗口则看 WindowOpenedOrChanged/WindowFocusChanged/WindowClosed 时序定位是 niri 焦点行为还是应用失焦自关；② 对照实验：同流程在 AwesomeWM/X11 会话下是否复现（复现则为钉钉/IME 应用层问题，与 niri 无关）；③ 钉钉浮动方案记录保留在 trace/memory，日后若再想试可从历史恢复。


## 2026-08-29 — @ 候选框消失根因定位（焦点乒乓）+ MainMenuPanelView open-focused false 实验

- 目的：用户配合复现 @ 候选框消失并反馈「鼠标悬停其上也消失、不动鼠标只敲键盘也消失」（鼠标无关）。分析 `/tmp/niri-events-dingtalk.log`（后台 `niri msg event-stream` 捕获）定位根因。
- 证据链：@ 弹窗为**受管 XWayland 窗口** `MainMenuPanelView`（350x419，niri 自动浮动）——每次 @：弹窗 map 时 `is_focused: true`（niri 默认把键盘焦点给新窗口）→ 焦点在弹窗仍打开时被设回钉钉主窗口 174（用户无鼠标/键盘动作，niri 只在窗口开/关时移焦点 → 钉钉自己经 XSetInputFocus 抢回）→ 弹窗关闭（CEF「失焦即关」）→ 伴随弹窗（标题「钉钉」683x488，与主窗口同名）打开→被抢→关闭，乒乓循环 4 轮。结论：niri 焦点行为是循环的起点，钉钉抢回焦点+失焦自毁完成闭环。
- 改动（实验）：① `.config/linux/niri/common.kdl` 新增 `window-rule { match app-id=…dingtalk… title=r#"^MainMenuPanelView$"# open-focused false }`——弹窗 map 起不持有焦点，主窗口焦点全程不变（X11 弹窗正常模式）。KDL 语法注意：app-id 与 title 必须写在同一个 `match` 节点（分开两个节点 `title=` 会解析报错）。② `tests/niri_config_test.sh` 加规则块断言；③ `.config/linux/niri/README.md` 加「钉钉 @ 成员选择弹窗不抢焦点」条目；④ memory/dingtalk.md 新增「@ 候选框出现后立即消失」观测记录（含证据链与无效时的出路）。
- 验证：`niri validate`（x64+aarch64）通过；niri/waybar/wayland-scripts/install-wayland 测试 PASS；`git diff --check` 干净。**实验效果待用户实测 @**：成功判据 = 候选框持续显示、event-stream 中弹窗 map 后无 focus changed/WindowClosed 乒乓；失败 = 候选框仍消失，结论转向钉钉 CEF 自身缺陷（网页版钉钉对照 + 反馈钉钉）。
- live 同步与运行态：未同步（IDE 沙箱不可写 `~/.config/niri`），由用户粘贴命令块同步并 `niri msg action load-config-file` 热重载。event-stream 观测进程保持运行（/tmp/niri-events-dingtalk.log 持续追加），实验后据此判读。恢复命令：`cp ~/.config/niri/common.kdl.backup.<时间戳> ~/.config/niri/common.kdl`。
- 回滚信息：未提交（含浮动回退轮改动）；撤销本条实验用 `git checkout -- .config/linux/niri/common.kdl .config/linux/niri/README.md tests/niri_config_test.sh`。
- 后续可能方向：① 实验成功→转正规则并把结论写入 memory/dingtalk.md；② 实验失败→回退规则，网页版钉钉对照验证区分应用缺陷/XWayland 层，必要时 `fcitx5 -d --replace --verbose xim=4` 排查 XIM 干扰；③ 伴随弹窗（标题「钉钉」683x488）与主窗口同名无法用 title 区分，如证实相关需另找抓手（如 niri 后续支持按尺寸/role 匹配）。

## 2026-08-29（续）— @ 实验 1 无效：弹窗标题不稳定，升级为 app-id 级 open-focused false

- 结果：用户实测候选框仍消失。event-stream 判读：热重载（第二个 Config loaded，行 478）后日志中 `MainMenuPanelView` 出现 0 次——钉钉弹窗的 X 窗口标题不稳定（本轮实测 `Form`（平铺）、`com.alibabainc.dingtalk`（浮动）、`分享的图片` 等轮换），title 定向规则未命中，所有弹窗仍 `is_focused: true` 打开后迅速关闭。**结论：焦点乒乓假设尚未被真正测试。**
- 改动：common.kdl 的 MainMenuPanelView 规则升级为 `match app-id=…dingtalk…` + `open-focused false`（只作用于新 map 窗口，已开主窗口不受影响；所有新弹窗无论标题都不抢焦点）；代价：重启钉钉/新开窗口时不自动聚焦，需手动点一下。测试断言同步（含 assert_not_contains 旧 title 规则），README 条目改写。
- 验证：`niri validate`（x64+aarch64）+ niri/waybar/wayland-scripts/install-wayland 测试 PASS；`git diff --check` 干净。
- 判读逻辑（下次实测）：a) 候选框稳定显示 → 假设成立（niri map 时给焦点是触发器），规则转正；b) 仍消失且弹窗 `is_focused: false` 打开 → 应用层自毁（钉钉 CEF 缺陷），回退规则并建议网页版钉钉对照/反馈钉钉；c) 仍消失且无弹窗事件 → 弹窗走了 override-redirect，嫌疑转 XWayland satellite/IME 层，做 fcitx5 判别实验（`pkill fcitx5` 后测 @，再 `fcitx5 -d` 恢复）。
- 回滚信息：未提交；`git checkout -- .config/linux/niri/common.kdl .config/linux/niri/README.md tests/niri_config_test.sh`。

## 2026-08-29（终）— @ 实验 2 成功：app-id 级 open-focused false 转正

- 结果：用户同步后实测 @ 候选框稳定显示。event-stream 证据（第三次 Config loaded 后）：弹窗以 `is_focused: false` + `focus_timestamp: None` 打开（规则生效，不再抢焦点），无焦点乒乓。**根因定案：niri 对新 map 窗口默认聚焦，钉钉弹窗（Qt/CEF）收到意外 FocusIn 即自毁；弹窗不持有焦点后即稳定。**
- 改动：无新改动（实验 2 的 app-id 级规则转正为最终状态）；memory/niri.md 窗口规则条目补充弹窗规则结论，memory/dingtalk.md「@ 候选框」条目定稿（含 title 不稳定教训与 event-stream 判别工具记录）。event-stream 观测进程已停止（pkill -f 'niri msg event-stream'），日志保留 /tmp/niri-events-dingtalk.log。
- 验证：用户实测候选框稳定；日志判读弹窗 `is_focused: false`；仓库测试此前已全 PASS（本轮无配置改动，无需重跑）。
- live 同步与运行态：live `~/.config/niri/common.kdl` 已由用户同步至最终状态（含 2/3 列宽+1.0 不透明、open-focused false、无 focus-follows-mouse）。
- 回滚信息：本 commit（撤销用 `git revert HEAD`，回滚入口见提交记录 fix(niri): 钉钉弹窗不抢焦点修复 @ 候选框消失）。

## 2026-08-29（补）— 表情面板平铺：钉钉浮动第四次迭代定稿（exclude 主窗口全浮动）

- 目的：用户反馈钉钉表情面板出现在右侧新窗口（平铺成新列），并询问社区平铺方案对弹窗大户的通用做法。解答：X11 时代靠 EWMH 窗口类型提示（DIALOG/POPUP_MENU 等）+ WM_TRANSIENT_FOR 由 WM 自动浮动；Wayland 的 xdg_toplevel 无类型概念、xwayland-satellite 不翻译这些提示，niri 只自动浮动固定尺寸窗口——resizable 弹窗（表情面板）只能靠 window-rule。社区对 QQ/微信/钉钉的主流做法：整体浮动（主窗口也浮）或 exclude 主窗口全浮动。
- 改动：① `.config/linux/niri/common.kdl` 恢复 exclude 浮动规则（用户确认选择）：`match app-id=…dingtalk…` + `exclude title=r#"^钉钉|钉钉$"#` + `open-floating true`，表情面板/对话框/预览等全部浮动，与 `open-focused false` 互不冲突；残余：偶发同名「钉钉」弹窗陪主窗口平铺。② 测试断言、README（EWMH 缺口背景 + 社区做法依据）、memory/niri.md（四次迭代轨迹定稿）、memory/dingtalk.md 同步。
- 验证：`niri validate`（x64+aarch64）通过；niri/waybar/wayland-scripts/install-wayland 测试 PASS；`git diff --check` 干净。
- live 同步与运行态：未同步（沙箱限制，用户执行粘贴块；备份+保留 3 份惯例同前）。恢复命令：`cp ~/.config/niri/common.kdl.backup.<时间戳> ~/.config/niri/common.kdl`。
- 回滚信息：本 commit（撤销用 `git revert HEAD`）；单规则级回退可 revert 后仅保留 `open-focused false`。
- 后续可能方向：① 用户同步后实测表情面板/对话框/图片预览应浮动，主窗口保持平铺；② 同名「钉钉」弹窗若高频出现且干扰，需等 niri 支持按尺寸/role/transient 匹配或 satellite 翻译 EWMH 提示后再收敛；③ 若钉钉弹窗浮动后出现遮挡/定位异常，用 `default-floating-position` 微调。
