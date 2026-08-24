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


## 2026-08-24 — memory 固化 brew vs 系统包管理器落地准则

- 目的：把「哪些软件适合 brew、哪些适合系统包管理器（zypper/apt）」的归类固化为可复用整理规则，避免每次装软件重新推导。
- 改动：`memory/organizing_preferences.md`「系统环境」段在跨系统包管理策略之后新增一条落地准则：五条判定标准（系统资源 / `*-dev` 库 / 会话居民 / 纯 CLI / 被会话引用），并给出当前 openSUSE WSL2 的 brew（neovim/ripgrep/fd/fzf/bat/yazi/zoxide，即 Linux Brewfile 覆盖的纯 CLI 子集）与 zypper（gcc 系 + tmux + jq）映射，明确 herdr 走官方脚本（不进 Brewfile）、tmux 建议系统装、alacritty 归 DMS。
- 验证：`git diff --check` 干净；纯 Markdown 改动，无脚本/配置变更。
- 回滚信息：未提交；`git checkout -- memory/organizing_preferences.md` 即回滚本次 memory 改动（本 trace 条目需单独删除）。
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
