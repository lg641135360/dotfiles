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
