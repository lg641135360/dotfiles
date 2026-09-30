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


## 2026-09-29 — 黑苹果全组件健康检查 + 记录电池已拆除为预期

- 目的：用户要求检查黑苹果各类组件；检查中 `BatteryInstalled = No` 先报为异常，用户确认电池已物理拆除，记录为机器事实避免后续误报。
- 结果：硬件全绿（UHD620 Metal3 / AppleALC 音频 / itlwm WiFi 5GHz / Intel BT / USB 映射 / TRIM / Lilu+VirtualSMC+VoodooI2C 等 kext 全链加载）；`./tests/run.sh fast` PASS=41 FAIL=7 SKIP=1，7 个 FAIL 均为 Linux 导向测试的 macOS 可移植性问题（py3.9 无 tomllib / BSD awk / source 路径下 bash 3.2 无 mapfile / 沙箱缺 defaults+killall），不影响 live；live 与仓库工作区无漂移。
- 改动：`memory/organizing_preferences.md` 系统环境新增"黑苹果电池已拆除属预期"一条。
- 验证：`git diff --check` OK；测试套件未触碰 live（依赖 defaults 的用例在沙箱 PATH 下安全失败）。
- live/提交：无 live 变更；已提交 `c0d1f9d`（fix(macos): re-exec modern bash in install.sh; make defaults.sh idempotent; fix path.zsh syntax，9 文件，未推送；与同日另外两轮合并为同一 commit）。回滚：`git revert c0d1f9d`，或从改动前锚点 `bade84f` 逐文件 `git checkout`。
- 后续：① 测试可移植性加固（source 型 install 测试解析现代 bash 或 bash<4 SKIP；tomllib/awk 缺失 SKIP）；② 本文件已 24 条超维护上限（5 条/150 行），提交前宜跑 `npm --prefix scripts run archive-trace`。

## 2026-09-29 — 修 path.zsh 语法错误 + macOS defaults 幂等

- 目的：装完配置后新开 zsh 报 `~/.config/zsh/path.zsh:43: parse error near 'elif'`；并追问为何 `install.sh` 每次都重设 macOS 偏好。
- 根因：工作区 `.config/shared/zsh/path.zsh` 有未提交改动（12:37），在 Darwin 分支补 `/opt/local/bin`、`/opt/local/sbin`、`$HOME/.npm-global/bin` 时于 `elif` 前多写一个 `fi`，形成 `if…fi / elif…fi`（HEAD 版本本身合法）；坏文件被 install.sh 复制到 live，故每个新 shell 都报错。`tests/zsh_path_test.sh` 全为 Linux-only 且无语法检查，未拦住。defaults 每次重设是因为 `install.sh` 无条件执行 `.config/macos/defaults.sh`，原脚本无幂等判断，每次全量 `defaults write` + `killall Finder/Dock`。
- 改动：`path.zsh` 删除多余 `fi`（保留用户新增的 MacPorts / npm-global 路径）；`.config/macos/defaults.sh` 重写为按值幂等——`set_bool`/`set_value` 先 `defaults read` 比对，仅不同才写，仅当有变化才 `killall`，并打印 `macOS defaults set (N change(s))` 或 `already up to date; nothing changed`；`tests/zsh_path_test.sh` 新增跨平台 `test_zsh_configs_are_syntactically_valid`（`.zshenv`/`.zshrc`/`.zshrc.pre`/`*.zsh` 跑 `zsh -n`）；新增 `tests/macos_defaults_test.sh`（stub `defaults`/`killall`，断言首跑全写+重启、二次 no-op、仅改动键重写）；README/memory 同步。
- 验证：改动前 `sh tests/zsh_path_test.sh` FAIL、`sh tests/macos_defaults_test.sh` 复现“第二次仍写 18 键”FAIL；实现后两者 PASS；`repo_docs_test.sh` PASS；`zsh -n` 手工确认 macOS PATH 正确前置 `/opt/local/bin`、`/opt/local/sbin`、`~/.npm-global/bin`；`bash -n defaults.sh`、`sh -n` 两个测试、`git diff --check` 均 OK。
- live/提交：记录时 live `~/.config/zsh/path.zsh` 仍是坏的（与工作区 12:37 同版本），待复跑 install.sh 同步；已提交 `c0d1f9d`（未推送，三轮合并）。回滚：`git revert c0d1f9d`，或 `git checkout bade84f -- .config/shared/zsh/path.zsh .config/macos/defaults.sh README.md memory/organizing_preferences.md tests/zsh_path_test.sh` 并删除 `tests/macos_defaults_test.sh`。

## 2026-09-29 — macOS x86：install.sh 检测过旧 Bash 时 re-exec MacPorts Bash

- 目的：macOS 自带 `/bin/bash` 为 3.2，而 `install.sh` 用了 Bash ≥ 4.3 的 `local -n`（`process_configs`）与 `mapfile`（`clean_old_backups`），导致 `./install.sh` 在部署任何文件前就以 `local: -n: invalid option` 退出（沙箱实测 exit 2，临时 HOME 零文件）。为 macOS x86 补兼容。
- 改动：`install.sh` 新增 `ensure_modern_bash()`，在执行入口（`BASH_SOURCE==$0` 分支内、`main` 之前）检测 `BASH_VERSINFO[0] < 4` 时，按 `DOTFILES_BASH` → `/opt/local/bin/bash` → `/usr/local/bin/bash` → `/opt/homebrew/bin/bash` 顺序找现代 Bash 并 `exec` 重跑；都没有则打印含 `sudo port install bash` 的错误并 exit 1。新增 `tests/install_bash_reexec_test.sh`（用 stub 冒充现代 Bash，在只有 Bash 3.2 的机器上断言 re-exec 分派；Bash ≥ 4 主机 SKIP 77）。README「使用方式」与 `memory/organizing_preferences.md` 系统环境同步说明。
- 验证：先写测试在 Bash 3.2 下复现 FAIL；实现后 `./tests/install_bash_reexec_test.sh` PASS、`./tests/repo_docs_test.sh` PASS、`./tests/install_submodule_test.sh` PASS（确认 source install.sh 不触发 re-exec）、`/bin/bash -n install.sh`、`sh -n tests/install_bash_reexec_test.sh`、`git diff --check` 均 PASS。手工 stub 实测 re-exec 与缺 Bash 报错两条路径输出符合预期。
- 后续/未验证：① 用户已 `sudo port install bash`（`/opt/local/bin/bash` 5.3.15）并补跑验证：临时副本 + 临时 HOME + stub `defaults.sh` 端到端 `HOME=… DOTFILES_OS=Darwin /bin/bash install.sh` → 自动 re-exec、exit 0、配置落入临时 HOME（未碰 live）。② install 系列用 `/opt/local/bin/bash` 复跑：`install_backup`/`install_redshift`/`install_submodule`/`install_tpm`/`install_wayland` PASS；`install_macos_test` SKIP（仅 Linux）；`install_claude_statusline` 与 `install_zshenv` 仍 FAIL，属测试自身的 macOS 移植问题（前者 macOS 分支会真跑 `defaults.sh`，沙箱 PATH 缺 `defaults`/`killall` → `set -e` 退出；后者 BSD `wc -l` 输出带前导空格），均非本轮安装器改动引入，本次未处理。
- live 同步（用户授权“1”，黑苹果 x86 真机）：执行 `./install.sh`，自动 re-exec `/opt/local/bin/bash`，exit 0。首次部署，新建：`~/.config/zsh/`（11 个 zsh 文件）、`~/.config/git/`、`~/.config/scripts/update-ai-clis`、`~/.ssh/config`、`~/.ssh/config.base`、`~/.zshenv`（含 `ZDOTDIR`/`skip_global_compinit`）；以上目标部署前均不存在，按 install.sh 惯例仅在已存在时才备份，故本轮无 `*.backup.*`。二次运行 15 项 `identical` 跳过、无新备份；live 与仓库 diff 为空（仅 `.zshrc.pre`/`README.md` 按设计未部署）。`~/.config/macos/defaults.sh` 已真实执行（键重复/Dock/Finder/截图/触控板等 + `killall Finder/Dock/SystemUIServer`），未预存旧值快照。非交互 `zsh -c` 验证已继承 `ZDOTDIR`/`skip_global_compinit`。
- 回滚：仓库已提交 `c0d1f9d`（未推送，三轮合并；`logs/trace.md` 由紧随其后的回填提交入库），`git revert c0d1f9d` 或 `git checkout bade84f -- install.sh README.md memory/organizing_preferences.md` 并删除 `tests/install_bash_reexec_test.sh`。live（新建文件、原本不存在，无备份可还原）：
  ```bash
  rm -rf ~/.config/zsh ~/.config/git ~/.config/scripts/update-ai-clis ~/.ssh/config ~/.ssh/config.base ~/.zshenv
  # defaults 无快照，逐项回退或到“系统设置”手动改回，例如：
  defaults delete com.apple.dock autohide; defaults delete NSGlobalDomain KeyRepeat
  ```

## 2026-09-19 — 同步仓库结构文档并整理 niri/DMS memory

- 目的：修复 README 仍引用已删除的 `tools/` 钉钉 hook 目录，并收敛 niri/DMS 当前基线与历史决策，避免把已废弃方案误当现行配置。
- 改动：README 删除 `tools/`，补齐当前 Wayland 脚本清单，并说明钉钉日常启动走官方 `Elevator.sh`、仓库脚本只用于排障；`memory/niri.md` 重组为当前有效基线、会话组件与运行规则、键位/视觉约定、历史决策/废弃方案、排障入口；`tests/repo_docs_test.sh` 增加 README 结构、脚本清单和 `tools/` 不存在的回归断言。
- 验证：`sh tests/repo_docs_test.sh`、`sh tests/niri_config_test.sh`、`git diff --check` 均 PASS。
- live/提交：未同步 live，未提交；回滚信息：仓库执行 `git checkout -- README.md memory/niri.md tests/repo_docs_test.sh logs/trace.md`。

## 2026-09-16 — dingtalk-wayland 改为只排障、不再启动钉钉

- 目的：日常启动已走官方 `Elevator.sh`；用户确认不再用仓库脚本启动钉钉，只留排障入口。
- 改动：`dingtalk-wayland` 去掉启动/preload/restart 路径，仅保留 `status` 与 `stop|kill`；无参数或未知子命令打印帮助并退出 2。同步 `install.sh` 部署说明、niri/scripts README、`memory/dingtalk.md` 与两组测试。
- 验证：先改测试确认失败，再改实现后 `sh tests/dingtalk_wayland_test.sh`、`tests/wayland_scripts_test.sh`、`tests/install_wayland_test.sh`、`tests/niri_config_test.sh`、`tests/repo_docs_test.sh`、`sh -n`、`git diff --check` 均 PASS。无参数 / `restart` 现返回 2。
- live 同步：已覆盖 `~/.config/scripts/dingtalk-wayland`，备份 `~/.config/scripts/dingtalk-wayland.backup.20260916_105709_873739`；旧 backup 按保留 3 份清理。autostart 覆盖仍 `Hidden=true`，Comment 改为不再指向仓库启动脚本，备份 `~/.config/autostart/com.alibabainc.dingtalk.desktop.backup.20260916_105730_873953`。
- 回滚信息：commit `c830724`（已提交，未推送）。live 恢复：
  ```bash
  cp ~/.config/scripts/dingtalk-wayland.backup.20260916_105709_873739 ~/.config/scripts/dingtalk-wayland
  ```

## 2026-09-16 — 钉钉官方原生 Wayland 捕获可用，删除 hook

- 目的：用户实测 `DINGTALK_FORCE_X11_CAPTURE=0 ~/.config/scripts/dingtalk-wayland restart` 后，钉钉 `8.2.8.260904001` 在 x86_64 + niri 上可正常共享；仓库不再需要 X11 LD_PRELOAD hook。
- 改动：删除 `tools/dingtalk-wayland-screenshare/` 与 `tests/dingtalk_hook_test.sh`；`dingtalk-wayland` 去掉 hook 注入和 `XDG_SESSION_TYPE=x11` 伪装，默认保留真实 Wayland 会话走会议 SDK 原生 PipeWire 捕获。测试改为 `tests/dingtalk_wayland_test.sh`，并同步 niri/scripts README、`memory/dingtalk.md`、`AGENTS.md`、`.gitignore`。
- 验证：先改测试确认失败，再改实现后 `sh tests/dingtalk_wayland_test.sh`、`tests/wayland_scripts_test.sh`、`tests/niri_config_test.sh`、`tests/install_wayland_test.sh`、`tests/repo_docs_test.sh`、`sh -n .config/scripts/dingtalk-wayland`、`git diff --check` 均 PASS；提交前补跑 `tests/run.sh fast` PASS=46 FAIL=0。`tests/install_backup_test.sh` 用 bash（其 shebang）跑 PASS，此前用 `sh` 调用产生的 `Bad substitution` 是 dash 解析不了 bash 版 `install.sh` 的假失败。
- live 同步：已同步 `~/.config/scripts/dingtalk-wayland`；备份 `~/.config/scripts/dingtalk-wayland.backup.20260916_100940_826682`；旧 backup 已按保留 3 份清理。已删除 `~/.local/lib/dingtalk-wayland-screenshare/`（含 `libdingtalkhook.so`）。live 脚本与仓库 diff 为空，无 hook 引用。live desktop entry `~/.local/share/applications/com.alibabainc.dingtalk.desktop` 已改回官方 `Exec=/opt/apps/com.alibabainc.dingtalk/files/Elevator.sh %u`（与系统入口一致），备份 `...desktop.backup.20260916_102452_856277` 与更早的 Comment 备份 `...desktop.backup.20260916_102211_855500`。仓库无对应 desktop entry，未纳入 install.sh。未重启钉钉。
- 回滚信息：commit `c830724`（已提交，未推送）。仓库 `git checkout --` 上述文件即可回退；hook 源码需从 `git checkout HEAD -- tools/dingtalk-wayland-screenshare tests/dingtalk_hook_test.sh` 恢复。live 恢复：
  ```bash
  cp ~/.config/scripts/dingtalk-wayland.backup.20260916_100940_826682 ~/.config/scripts/dingtalk-wayland
  cp ~/.local/share/applications/com.alibabainc.dingtalk.desktop.backup.20260916_102452_856277 ~/.local/share/applications/com.alibabainc.dingtalk.desktop
  ```
  hook 库已删除，仓库回退后需重新编译 `libdingtalkhook.so` 才能恢复 hook 路径。
- 后续可能方向：下次启动钉钉会走官方原生捕获。

## 2026-09-09 — foot 字号从 12 调回 13

- 目的：用户觉得 Starship 图标偏小。Starship 无独立字号，跟 foot 单元格走；当时为 aarch64 内屏 2x 紧凑把 foot 降到 12，x64 scale 1.25 上图标偏小。
- 改动：`foot.ini` 四条 `font*` 的 `:size=12` 改为 `:size=13`（与 alacritty 对齐）；`tests/foot_config_test.sh` 断言同步；`memory/foot.md` 记录撤回 12pt 实验。foot README / niri.md 原本已写 13，未改。
- 验证：先改测试确认失败，再改配置后 `sh tests/foot_config_test.sh` PASS；`foot -c .config/linux/foot/foot.ini -C` exit 0；`git diff --check` 干净。
- live 同步：用户执行 `./install.sh`，已同步 `~/.config/foot/`；备份为 `~/.config/foot.backup.20260909_164503_459173`。已打开的 foot 窗口仍用 12，需关掉重开。
- 回滚信息：提交后见 `git log -1`。仓库 `git revert HEAD`；live 恢复：
  ```bash
  cp ~/.config/foot.backup.20260909_164503_459173/foot.ini ~/.config/foot/foot.ini
  ```


## 2026-09-09 — 关闭 Starship Python 版本模块

- 目的：用户确认提示符里的 ` v3.14.4` 无实际价值（TypeScript 优先、目录有 `.py` 就会冒出版本），要求关掉。
- 改动：`.config/shared/starship.toml` 的 `[python]` 设 `disabled = true`；`tests/starship_config_test.sh` 新增段落断言；`.config/shared/zsh/README.md` 去掉 Python 模块说明；`memory/organizing_preferences.md` 记录该决策。
- 验证：先补测试确认失败，再改配置后 `sh tests/starship_config_test.sh` PASS；`git diff --check` 干净。带 `.py` 的临时目录下 `starship explain` / `starship prompt` 均无 python 版本。
- live 同步：用户执行 `./install.sh`，已同步 `~/.config/starship.toml`；备份为 `~/.config/starship.toml.backup.20260909_163316_447240`。已打开的 shell 需新开才加载。
- 回滚信息：提交后见 `git log -1`。仓库 `git revert HEAD`；live 恢复：
  ```bash
  cp ~/.config/starship.toml.backup.20260909_163316_447240 ~/.config/starship.toml
  ```


## 2026-09-09 — X11 剪贴板桥给 xclip/wl-copy 加 timeout，避免无限阻塞

- 目的：钉钉再次贴不到刚复制的图片。现场 X11 桥从 9 月 8 日 15:12 起卡在 `xclip -t TARGETS -o`（PID 3082973，超过一天），Wayland 侧已有 `image/png`，X11 侧只剩 `UTF8_STRING`。
- 改动：`clipboard-wayland` 的桥读写全部套 `timeout --foreground 2`（缺 timeout 则跳过桥）；超时当本轮空选区跳过。`--foreground` 避免 timeout 把已经 fork 出去持有剪贴板的 xclip/wl-copy 子进程一起杀掉。测试、scripts README、niri README、`memory/niri.md` 同步。
- 验证：先改测试确认失败，再改脚本后 `bash -n` + `bash tests/wayland_scripts_test.sh` PASS。live 重启守护后 `wl-copy -t image/png` 1x1 PNG，X11 `TARGETS` 含 `image/png`，两侧 sha256 与源文件一致。
- live 同步：已备份并覆盖 `~/.config/scripts/clipboard-wayland`，杀掉卡住的旧守护后重启。备份 `~/.config/scripts/clipboard-wayland.backup.20260909_170550_001263132`，旧 backup 已按保留 3 份清理。
- 回滚信息：提交后见 `git log -1`。仓库 `git revert HEAD`；live 恢复：
  ```bash
  cp ~/.config/scripts/clipboard-wayland.backup.20260909_170550_001263132 ~/.config/scripts/clipboard-wayland
  pkill -f 'clipboard-wayland start'; nohup "$HOME/.config/scripts/clipboard-wayland" start >>/tmp/clipboard-wayland.log 2>&1 &
  ```


## 2026-09-08 — 优化 Starship 提示符信息辨识度

- 目的：落实提示符优化建议，提升开发环境、Git 状态与后台任务的可读性。
- 改动：`.config/shared/starship.toml` 为 Node/Bun/Rust/Python/Docker 增加 Nerd Font 图标，Git 修改状态改为 `~`，新增后台作业数模块，并将命令耗时阈值从 5 秒降至 2 秒；`.config/shared/zsh/README.md` 同步说明。
- 验证：`sh tests/starship_config_test.sh` PASS；`starship explain`、`starship prompt` 均正常；`git diff --check` PASS。
- live 同步：用户随后运行 `./install.sh`，已同步 `~/.config/starship.toml`；备份为 `~/.config/starship.toml.backup.20260908_204519_3469228`，未重载 shell。
- 回滚信息：未提交；仓库可用 `git checkout -- .config/shared/starship.toml .config/shared/zsh/README.md logs/trace.md` 回退，live 可执行 `cp ~/.config/starship.toml.backup.20260908_204519_3469228 ~/.config/starship.toml` 恢复。


## 2026-09-07 — 钉钉等 X11 应用粘贴不到截图图片：根因定位 + X11 轮询剪贴板桥（clipboard-wayland）

- 目的：解决"截图后 Ctrl+V 图片无法粘贴到钉钉等 X11 应用"。上一轮修改（persist `--ignore-event-on-error`、`wl-copy -t image/png`）只修了 Wayland 侧旧文本回写，与 X11 桥无关，故"还是有问题"。
- 根因（运行时证据）：① Wayland 剪贴板有 `image/png`（Chrome 等 Wayland 应用可贴）✓；② 钉钉 App ID `com.alibabainc.dingtalk`、PID 即 xwayland-satellite 进程 = X11 应用（CEF 109，仓库 dingtalk-wayland 已记录原生 Wayland 会崩，不可行）✓；③ X11 侧 `xclip -t TARGETS` 只有 `UTF8_STRING`，无 image/png，内容停留在陈旧"支"✓；④ 全新 :3 卫星实例（RUST_LOG=debug）wl-copy 后无任何反应，日志从未出现 "Clipboard set from Wayland"，只响应 X11 侧 → 卫星收不到/不处理 Wayland 剪贴板事件，双向均失效；⑤ 卫星源码为通用 MIME 透传（非纯文本），失败在事件送达；⑥ 社区共识：niri 不做 X11↔Wayland 剪贴板同步，QQ/微信等需自写轮询同步脚本。
- 改动：① `clipboard-wayland` `start` 守护新增 `start_x11_bridge`：每 0.5s 轮询两侧，双向同步文本与 image/png、jpeg、gif，内容哈希去抖防回环；文本方向带目标守卫（X11 需 UTF8_STRING/STRING/TEXT/text/plain，Wayland 需 text/*），避免图片字节被当文本推回覆盖；仅在有 `xclip` + `DISPLAY` 时启动，纳入父脚本 cleanup/监管（bridge_pid），缺依赖降级跳过。② **两轮守卫迭代 + 快照单次读取**：图片分支加字节数守卫（sha256 对空输入仍输出非空哈希，复制瞬间读到空选区会误推空图并污染去抖状态）；文本分支从命令替换 `$(...)` 改为管道读取（命令替换会剥离尾部换行、丢弃 NUL，导致跨桥文本不保真）；随后统一改为**快照单次读取**——每轮把源内容落到 `/tmp/clipboard-wayland-bridge.snap.$$` 临时文件 1 次，`-s` 判空/`sha256sum < snap` 哈希/`cat snap` 推送全部复用同一份（`trap` 清理），源读取从每轮 2~3 次降到 1 次，判空与哈希不再有 TOCTOU。③ `tests/wayland_scripts_test.sh` 同步断言（含桥与两处守卫）。④ `niri/README.md`、`scripts/README.md`、`memory/niri.md` 同步。
- 验证：`bash -n` + `./tests/wayland_scripts_test.sh` PASS；live 运行时实测：文本四向（含字节保真）、图片 hash 与原图一致；imgA/imgB/imgA 连续复制发现"空选区→空哈希→误推空图"竞态，加守卫后修复（该轮实测中 X11 侧曾短暂出现空图，根因即空哈希误判）。踩坑：`xclip -i` 内部 exec `cat`，测试桥时最小 PATH 必须含 cat；去抖把"已同步的同一图片"正确判为无需再推。
- 回滚信息：未提交（仓库侧改动：`.config/scripts/clipboard-wayland`、`tests/wayland_scripts_test.sh`、`.config/linux/niri/README.md`、`.config/scripts/README.md`、`memory/niri.md`）。`git checkout -- <file>` 即回滚。live 同步被 IDE 白名单拦截，须用户手动执行（agent 已先创建 live 快照 `~/.config/scripts/clipboard-wayland.backup.20260907_152452_2678492`）。同步命令：
  ```bash
  cp .config/scripts/clipboard-wayland ~/.config/scripts/clipboard-wayland
  # 重启守护使桥生效（旧守护 PID 1971930 无桥）
  pkill -f 'clipboard-wayland start'; sleep 1
  nohup "$HOME/.config/scripts/clipboard-wayland" start >>/tmp/clipboard-wayland.log 2>&1 &
  # 验证桥进程在跑
  ps -ef | grep -E 'clipboard-wayland start|wl-clip-persist|wl-paste --watch'
  ```
  恢复命令（live 出问题时从快照恢复）：
  ```bash
  cp -a ~/.config/scripts/clipboard-wayland.backup.20260907_152452_2678492 ~/.config/scripts/clipboard-wayland
  pkill -f 'clipboard-wayland start'; nohup "$HOME/.config/scripts/clipboard-wayland" start >>/tmp/clipboard-wayland.log 2>&1 &
  ```
  旧 live 备份按"保留 3 份"清理（`ls -1t ~/.config/scripts/clipboard-wayland.backup.* | tail -n +4 | xargs rm -f`），agent 已尝试清理但同样被白名单拦截，需用户执行。
- 后续可能方向：① live 重启守护后实测钉钉粘贴；② 观察桥轮询 CPU/功耗（0.5s 间隔，进程开销集中在 xclip/wl-paste 轮询）；③ 若卫星后续版本修复事件送达，可评估移除轮询桥。

## 2026-09-11 环境变量收敛
- 目的：集中 Wayland fcitx 环境并减少重复导出。
- 已做：安装器新增幂等 `ensure_fcitx_environment`，为 `~/.config/environment.d/fcitx.conf` 确保 `XMODIFIERS=@im=fcitx` 与 `QT_IM_MODULE=fcitx`；Wayland niri 配置和 launcher/autostart 删除重复输入法变量；保留 Wayland 下清除 `GTK_IM_MODULE`；共享 zsh 将 `GTK_USE_PORTAL=1` 作为 Linux 通用变量，并仅在 X11 图形会话设置 Awesome 标识；移除 niri 中硬编码 `ZDOTDIR`，继续由安装器写入 `~/.zshenv`。
- 验证：`bash -n install.sh .config/scripts/wayland-autostart .config/scripts/launcher-wayland`、`tests/niri_config_test.sh`、`tests/wayland_scripts_test.sh`、`tests/install_zshenv_test.sh`、`git diff --check` 通过。
- live/提交：未同步 live；本轮未单独提交（2026-09-23 更正：与 2026-09-11 收尾、2026-09-12 两轮最终合并提交为 `4302f3b`，已推送）；回滚：`git revert 4302f3b`。

## 2026-09-11 环境变量收敛（收尾）
- 目的：进一步收敛——删除 `ensure_fcitx_environment` 与 `environment.d` 注入。分析确认正常登录路径下 fcitx 变量由 im-config 写入 `/etc/environment`，经 niri-session 的 `import-environment`（无参数）进入 systemd 用户环境，仓库侧不再需要任何 fcitx 变量注入点。
- 已做：`install.sh` 删除 `ensure_fcitx_environment()` 函数与其在 `main()` 的调用；`.config/scripts/wayland-autostart` 的 dbus/systemd 同步列表删除 `QT_IM_MODULE XMODIFIERS`（保留 XDG 会话标识同步与 `unset-environment GTK_IM_MODULE`）；`.config/linux/niri/README.md` 环境变量小节重写为当前实现（fcitx 变量走 `/etc/environment` + niri-session 注入，`environment {}` 仅保留 `XCURSOR_SIZE` 与会话标识，`ZDOTDIR` 由安装器写 `~/.zshenv`）。
- 验证：`bash -n`、`git diff --check` 通过；`tests/niri_config_test.sh`、`tests/install_zshenv_test.sh` 通过。
- 遗留失败（非本轮引入，需用户决策）：
  - `tests/install_wayland_test.sh`：`is_repo_niri_platform` 收紧为 ubuntu+aarch64 后，测试 6 个场景仍用 x86_64/arch/fedora mock，断言 niri 文件应部署不再成立；与 README「Ubuntu x86_64 / aarch64 部署」描述矛盾，疑似上轮误改，需回退收紧或同步改测试+README。
  - `tests/wayland_scripts_test.sh` 的 `test_launcher_wayland_respects_running_wayland_fcitx5` 场景1：`git stash` 后 HEAD 版通过、工作区版失败；HEAD 与工作区 launcher 唯一差异是删除的 6 行 fcitx exports（逻辑上不影响 fcitx5 存活检测），疑为 `/proc/<pid>/environ` 读取的测试环境敏感问题（Yama ptrace_scope / 容器），待确认。
- live/提交：未同步 live；本轮未单独提交（2026-09-23 更正：与 2026-09-11 环境变量收敛轮、2026-09-12 仓库适配轮最终合并提交为 `4302f3b`，已推送）；回滚：`git revert 4302f3b`。

## 2026-09-12 DMS 落地：mako 总线冲突修复（live 运行态）
- 目的：用户在 x64 Ubuntu 26.04 安装 dms 1.6.1ppa1（avengemedia/danklinux PPA）后 shell 未生效，定位并修复。
- 根因：`/usr/lib/systemd/user/dms.service` 与 `mako.service` 同抢 `BusName=org.freedesktop.Notifications`，systemd 拒绝加载 dms（"Two services allocated for the same bus name"），会话只剩裸 niri。
- 已做（live 运行态）：`systemctl --user disable --now mako.service`（提示 mako 为全局 enabled，仅 user-scope disable 不足以阻止下次自启）→ `systemctl --user mask mako.service`（symlink → /dev/null，同 gammastep-indicator 手法）→ `daemon-reload` → `start dms.service`。
- 验证：`dms.service` active (running)（PID 12377，quickshell `qs -p /run/user/1001/danklinux-shell/...` 子进程在位）；mako 无进程；fcitx5 正常运行（PID 12563）。
- 现场变化：DMS 当日 10:22 重新生成 live `~/.config/niri/config.kdl`（内联 DMS 默认配置 + `include optional=true "dms/*.kdl"` 片段；旧 708B 仓库版已备份 `~/.config/niri/config.kdl.backup.2026-09-12_10-22-31`）。新配置无任何 `spawn-at-startup`，仓库 `wayland-autostart` 链（swaybg/swayidle/clipboard/polkit）不再自启，由 DMS 模块接管壁纸/锁屏/剪贴板/polkit；live `common.kdl`（仓库版）不再被 include。
- 恢复命令（完整回退到 mako + waybar 链）：
  ```
  systemctl --user disable --now dms.service
  systemctl --user unmask mako.service && systemctl --user daemon-reload && systemctl --user start mako.service
  ```
- 后续可能方向：① 仓库侧 mako/waybar 链清理（wayland-autostart 的 mako 行、install.sh mako 配置部署、对应测试与 README）待用户决策；② `memory/niri.md` 2026-08-29「不装 dms，waybar+脚本链不变」决策已被本轮实际安装推翻，待 DMS 稳定后更新；③ DMS 生成的 config.kdl 未含仓库键位/窗口规则（Mod+hjkl、钉钉浮动等），需评估 DMS 设置内重建或改回 include 仓库 common.kdl。
- live/提交：仅运行态变更（mask/启停服务），仓库文件未同步 live；回滚信息：见上恢复命令。

## 2026-09-12 仓库适配 niri + DMS 环境
- 目的：x64 Ubuntu 已切 niri + DMS，调整 dotfiles 部署边界——DMS 机器保留 DMS 自管的外壳栈，仓库只部署与外壳无关的部分。
- 已做：
  - `install.sh`：`uses_dms_shell()` 改为 `command -v dms` 真探测（替换 2026-09-11 误收紧的 aarch64-only `is_repo_niri_platform`）；`is_repo_niri_platform = ubuntu && !dms`。部署拆两块：块1（Wayland 辅助脚本、桌面入口、portal 偏好、XDG autostart 覆盖 + 新数组 `linux_wayland_terminal_dir_configs`（foot，DMS 不改写 foot.ini））任何 niri 机器都部署；块2（niri 平台 KDL/common.kdl、waybar、mako、fuzzel、swaylock）仅 repo niri 平台部署，DMS/非 Ubuntu 走 elif 提示保留 live 配置。alacritty 跳过条件从仅 openSUSE 扩为 openSUSE||DMS（DMS 会重写 alacritty 主题导入）。
  - `tests/install_wayland_test.sh`：静态断言更新（两块 gate、`uses_dms_shell`、foot 数组、DMS 跳过消息）；新增 `test_install_preserves_dms_configs_on_ubuntu_x64`（stub dms/waybar/foot/mako/fuzzel/swaylock，断言脚本/入口/portal/覆盖/foot 部署且 DMS 配置全保留）。
  - `tests/lib/sandbox.sh`：baseline PATH 增补 `ls`——`copy_config` 空目录守卫调用 `ls`，旧沙箱缺它导致 foot 目录部署在最小 PATH 下误报"empty submodule"；此前无测试 stub 过 foot 所以未暴露。
  - `tests/wayland_scripts_test.sh`：修复 `test_launcher_wayland_respects_running_wayland_fcitx5` 偶发失败（trace 2026-09-11 遗留项）。根因实证：`env ... sleep &` 后立即读 `/proc/$pid/environ`，env(1) 未 exec sleep 前读到旧环境（无 WAYLAND_DISPLAY），300/300 复现；launcher 误判为 X11 实例触发 `--replace`。修复：两个场景 spawn 后加 exec 就绪等待循环（≤2s）。
  - `tests/niri_config_test.sh`：README 部署边界断言同步新措辞。
  - 文档：`README.md` 使用方式段、`.config/linux/niri/README.md` 定位/部署边界段、`memory/niri.md` 平台与部署规则、`memory/organizing_preferences.md` alacritty 归 DMS 说明，均改为「Ubuntu 且无 dms 才部署外壳栈，DMS 机器全保留」。
- 验证：`bash -n install.sh`、`git diff --check` 通过；`./tests/run.sh fast` PASS=46 FAIL=0（含新 DMS 用例与 wayland scripts 连跑 5 次稳定）。
- live/提交：未同步 live（本轮只改仓库部署逻辑，live DMS 配置已是目标态，无需动）；本轮未单独提交（2026-09-23 更正：连同 2026-09-11 环境变量收敛两轮与 foot 轮合并提交为 `4302f3b`，已推送，未按原计划拆分）；回滚：`git revert 4302f3b`。
- 后续可能方向：① 工作区另有 2026-09-11 环境变量收敛轮未提交，提交时先提交该轮再提交本轮；② DMS 键位未含仓库肌肉记忆键（Mod+hjkl 等）且 Mod+T spawn 未安装的 ghostty，待用户在 DMS 设置内调整；③ waybar/wayland-autostart 链的仓库清理（或保留为 aarch64 回退）待 DMS 稳定使用后决策；④ `memory/niri.md` 2026-08-29 包来源条目「不装 dms」已成历史，随下轮 memory 整理更新。

## 2026-09-12 foot 目录改单文件部署（保留第三方文件）
- 目的：规避整目录复制把 live `~/.config/foot` 中 DMS 放入的 `dank-colors.ini` 归档/替换掉的问题；用户决策：仅 foot 改逐文件部署，其它目录部署（git/nvim/awesome/mako/fuzzel/swaylock）保持整目录替换不变。
- 已做：
  - `install.sh`：`linux_wayland_terminal_dir_configs`（整目录）改为 `linux_wayland_terminal_configs` 逐文件数组（`foot.ini` + `README.md`），`main()` 对应调用更新；块1 任何 niri 机器部署不变。
  - `tests/install_wayland_test.sh`：静态断言改为逐文件条目；DMS 用例预置 `~/.config/foot/dank-colors.ini` 并断言安装后保留 + `foot.ini` 部署。
  - `tests/foot_config_test.sh`：install 行断言同步。
  - 文档：`README.md` 安装说明、`.config/linux/niri/README.md` 部署边界段、`memory/niri.md` 部署段补充 foot 单文件部署说明。
- 验证：`bash -n`、`tests/install_wayland_test.sh`、`tests/foot_config_test.sh`、`tests/install_submodule_test.sh` 通过；`./tests/run.sh fast` PASS=46 FAIL=0。
- live/提交：未同步 live；本轮未单独提交（2026-09-23 更正：实际以 `4302f3b` 与 2026-09-11/12 各轮合并提交，已推送）；回滚：`git revert 4302f3b`。
- 后续可能方向：① 若 DMS 的 `dank-colors.ini` 需要纳入仓库配色，可后续引入；② 其它目录若也出现第三方文件冲突，可评估通用合并部署。

## 2026-09-13 Mod+Enter 开 foot 加载 zsh 慢：skip_global_compinit 回归修复
- 目的：aarch64 niri 会话 Mod+Return 拉起的 foot 里 zsh 交互启动实测 4.8s（优化基线 ~0.3s），定位并修复。
- 根因：4302f3b（2026-09-12 环境变量收敛）从 niri `common.kdl` 的 `environment {}` 删掉预置 `ZDOTDIR`，注释却保留。zsh 只在启动最初读一次 `${ZDOTDIR:-$HOME}/.zshenv`：环境无 ZDOTDIR 时读 `~/.zshenv`（当时仅一行 `export ZDOTDIR`），随后 Ubuntu `/etc/zsh/zshrc` 检查 `skip_global_compinit` 时该变量为空（`$ZDOTDIR/.zshenv` 永远不会再被读）→ 全局 compinit 用默认 fpath 跑（xtrace 实证单次的 3.9s），并与 `plugins.zsh` 的 `compinit -u -d` 写同一 `$ZDOTDIR/.zcompdump`、fpath 不同互判过期，每次启动双重重整。
- 已做：
  - `install.sh` `ensure_zdotdir()`：改为逐行幂等确保 `~/.zshenv` 含 `export ZDOTDIR=$HOME/.config/zsh` 和 `skip_global_compinit=1` 两条（原逻辑 export 已存在即整体 return，不会补 skip 行）。
  - `tests/install_zshenv_test.sh`：新增 `test_ensure_zdotdir_backfills_skip_global_compinit` 回归用例（单行 ~/.zshenv 补 skip），既有用例补 skip 行幂等断言。
  - 文档：`.config/shared/zsh/README.md` 安装段与「跳过全局 compinit」段（补 2026-09-13 回归说明）；`memory/organizing_preferences.md` 「~/.zshenv 只含一条」旧偏好改为两条及理由。
  - live：备份后更新 `/home/rikoo/.zshenv`（追加 `skip_global_compinit=1`），备份 `/home/rikoo/.zshenv.backup.20260913_095528_1754579`（无更旧备份，保留 3 份规则无需清理）；删除 `~/.config/zsh/.zcompdump.rikoo-AIBOOK-ABA14104.1627485` 孤儿 dump。
- 验证：`bash -n install.sh` 通过；`tests/install_*_test.sh` 全部 7 个 PASS；模拟 niri spawn 干净环境 `env -i ... zsh -i -c exit` 从 4.8s 降到 0.275s；`git diff --check` 通过。
- 未完成（需用户执行）：Trae CN 内置 ripgrep 再次丢失可执行位（Grep/Glob 全报 EACCES，文件日期 2026-09-08），agent 无 sudo 密码，需用户跑：`sudo chmod 755 /usr/share/trae-cn/resources/app/node_modules/@vscode/ripgrep/bin/rg /usr/share/trae-cn/resources/app/node_modules/@byted-fe/ripgrep-linux-arm64/bin/rg`（无需重启 Trae）。
- 恢复命令（live ~/.zshenv 出问题时）：
  ```bash
  cp -p ~/.zshenv.backup.20260913_095528_1754579 ~/.zshenv
  ```
- live/提交：live ~/.zshenv 已同步（见上备份）；本轮已提交 `7d1a102`（fix(install): backfill skip_global_compinit into ~/.zshenv，5 文件，已推送）。原记录 hash f478738 因后续 rebase 被改写而失效（2026-09-23 按实际仓库历史更正）；回滚：`git revert 7d1a102` 或从备份恢复 ~/.zshenv。
- 后续可能方向：① 若其它机器（x64 DMS/macOS）曾跑过旧安装器，重跑 `./install.sh` 即可幂等补 skip 行；② niri README 环境变量段的「否则没有 skip_global_compinit」描述与现状一致（~/.zshenv 现含该行），未改。

## 2026-09-17 zed 命令无法启动：wrapper 指向不存在的 /usr/bin/zed
- 目的：`zed` 报 `exec: /usr/bin/zed: not found`，终端与桌面图标均无法启动；定位并修复。
- 根因：`~/.local/bin/zed`（自写 wrapper，含 fcitx/EGL 环境变量，非仓库管理）末行 `exec /usr/bin/zed`；apt 包 `zed` 1.17.2 的命令名是 `zeditor`（主程序 `/usr/libexec/zed-editor`，`/usr/bin/zed.app` 只是空目录），`/usr/bin/zed` 从未存在。用户级 `~/.local/share/applications/dev.zed.Zed.desktop` 也指向该 wrapper，故桌面入口同样失败。
- 改动（live-only）：wrapper 末行改为 `exec /usr/bin/zeditor "$@"`，其余环境变量不变；备份 `~/.local/bin/zed.backup.20260917095351`（首个备份，无需清理）。仓库无对应文件，未做仓库改动。
- 验证：`sh -n ~/.local/bin/zed` 通过；`zed --version` → `Zed 1.17.2`（修复前为 `exec: /usr/bin/zed: not found`）。GUI 实际启动未由 agent 触发，待用户点开验证。
- 回滚信息：未提交（仅 live 文件）。live 恢复：
  ```bash
  cp -p ~/.local/bin/zed.backup.20260917095351 ~/.local/bin/zed
  ```
- 后续可能方向：① `~/.local/zed.app`（1.12.0）与 `~/.local/zed-preview.app`（1.14.1）两套旧版安装仍在，若确认不再使用可清理；② 若后续 apt 包再改命令名，wrapper 会再次失效，可考虑改为 `command -v zeditor` 兜底探测。

## 2026-09-23 — 修复 trace 失效锚点、README 结构漂移与回归测试可移植性
- 目的：把上一轮只读分析发现的四类问题全部落到仓库：① trace 中失效的提交 hash 破坏可回滚承诺；② README 结构树漂移（缺 `swaylock/`、`xdg-autostart/`，niri 定位过时）；③ 文档测试没有覆盖结构树漂移；④ 回归测试硬编码 `python`/`lua` 且隐式依赖 `DISPLAY`，在无头/精简环境误报失败。
- 已做：
  - `logs/trace.md`：2026-09-13 条目回滚 hash `f478738`（rebase 后被改写、已失效）更正为实际提交 `7d1a102`，并标注已推送；2026-09-11 环境变量收敛两轮、2026-09-12 仓库适配轮与 foot 轮的「未提交」更正为实际合并提交 `4302f3b`（各附 `git revert` 回滚命令）。
  - `README.md`：Linux 结构树补 `swaylock/`、`xdg-autostart/`；`niri/` 注释由「Wayland 合成器（平行试用）」改为「Wayland 合成器（主力桌面，AwesomeWM 为回退）」。
  - `tests/repo_docs_test.sh`：新增结构树漂移守卫——遍历 `.config/{shared,linux,macos,scripts}` 的实际条目（子目录用 `名字/` 匹配、顶层文件用名字匹配，跳过 `README.md`），要求 README 全部列出（与既有 memory 索引守卫同思路）。验证时发现 `.config/scripts/` 下实为单文件可执行脚本而非目录，初版只看目录会漏掉 scripts，已改为同时校验文件并补负向用例。
  - `tests/lib/assert.sh`：新增 `resolve_tool <var> <candidates...>` / `resolve_python`（`python3`→`python`）/ `resolve_lua`（`lua`→`luajit`），缺失时打印 SKIP 并返回 exit 77。
  - `tests/awesome_{battery,brightness,common,layout,net,ui_architecture}_test.sh`：头部改用 `resolve_python`/`resolve_lua`，全部裸 `python`/`lua` 调用改为 `"$PYTHON_BIN"` / `"$LUA_BIN"`（含 `if ! python` 变体）。
  - `tests/zsh_path_test.sh`：`run_env_zsh` 显式设 `DISPLAY=:0`，不再隐式依赖运行环境的环境变量。
  - `memory/organizing_preferences.md`：仓库管理段补两条可复用规则（测试解释器解析 + 无头环境不得隐式依赖环境变量；README 结构树漂移守卫）。
- 验证：`sh -n` 全部改动测试 + `tests/lib/assert.sh` 通过；`git diff --check` 通过；`tests/repo_docs_test.sh` PASS；`./tests/run.sh fast` 从改动前 PASS=39 FAIL=7 变为 PASS=46 FAIL=0；逐个复跑原 7 个失败测试全部 PASS；trace 中带反引号的 commit hash 全部可在仓库解析。
- live/提交：未同步 live（本轮只改仓库文档/测试/memory）；已提交并推送 `a498742`（与下一轮 install.sh A 组因改同一批文件合并为一个 commit）。回滚：`git revert a498742`，或从改动前锚点 `0b9a80b` 逐文件 `git checkout`。
- 后续可能方向：① 若希望严格保留历史修订痕迹，可考虑把 trace 更正改为追加勘误条目而非就地改写，但当前就地更正便于 `git revert` 直接可用；② 其它模块 README（如 `.config/linux/niri/README.md`）未纳入结构树守卫，如需可扩展；③ nvim 启动类测试未在 `fast` 中执行，本轮未触及 nvim 逻辑，`./tests/run.sh full` 待需要时全量回归。

## 2026-09-23 — install.sh A 组修复：desktop entry 幂等、末尾换行、作用域与 ~/.zshenv 备份
- 目的：修只读分析列出的 A1–A4：① desktop entry 每次安装都备份+覆盖（identical 短路失效）；② `__HOME__` 替换丢末尾换行；③ 替换循环误改非仓库的 `~/.local/share/applications/*.desktop`；④ `ensure_zdotdir` 直接改 live `~/.zshenv` 无备份。
- 已做：
  - `install.sh` `process_config()`：在 `copy_config` **之前**把含 `__HOME__` 的源写入临时副本（`mktemp` + `cp -p` 保模式 + `printf '%s\n'` 恢复单个尾换行）再复制；同时覆盖 A1（幂等）、A2（换行）、A3（只处理受管源）。
  - `install.sh` main：删除原先遍历 `~/.local/share/applications/*.desktop` 的后置替换循环。
  - `install.sh` `ensure_zdotdir()`：追加前先 `cp -p` 时间戳备份 + `clean_old_backups`；无变更时直接返回，不产生备份。
  - `install.sh` `check_dependencies`：补 `mktemp`（新路径在前置阶段使用）。
  - 测试：`tests/install_wayland_test.sh` 新增 `test_install_desktop_entries_are_idempotent`（二次运行无备份、保留尾换行）与 `test_install_preserves_unmanaged_desktop_entries`；`tests/install_zshenv_test.sh` 新增备份/幂等/缺失文件三例；`tests/lib/sandbox.sh` baseline 补 `mktemp`；`tests/awesome_lock_test.sh`、`tests/install_redshift_test.sh` 的硬编码 PATH 列表补 `mktemp`。
  - 文档：`README.md` 使用方式段补「同类备份保留 3 份 + `~/.zshenv` 先备份 + `__HOME__` 复制前展开」；`.config/linux/desktop-entries/README.md` 说明替换时机与幂等/换行/作用域；`memory/organizing_preferences.md` 补「占位符替换应在 copy 之前」规则。
- 验证：改动前两个新测试用例已复现失败（备份 churn / 未生成备份）；`bash -n install.sh`、`sh -n` 改动测试通过；`git diff --check` clean；`tests/install_*_test.sh` 全部 PASS（含新用例）；`./tests/run.sh fast` PASS=46 FAIL=0。
- live/提交：未同步 live（只改仓库）；已提交并推送 `a498742`（与上一轮文档/测试轮合并）。回滚：`git revert a498742`。
- 后续可能方向：① 同属分析结论的 B/C/D 组（bash≥4.3 守卫、未用依赖 `tail`、重复 `command -v` 缓存、分支失败不中止、`--dry-run` 等）尚未处理；② 若将 desktop entry 收集改为数组驱动，可进一步消除 `process_config` 中的魔数探测。

## 2026-09-23 — install.sh 提示用户按 C-a I 安装 tmux 插件
- 目的：修「新机器 tmux 无主题」的根因链条——`install.sh` 只 clone TPM 本体，从不触发插件安装；插件（catppuccin/tmux、tmux-resurrect 等）只有用户在 tmux 内按 `C-a I` 才会克隆，导致状态栏退回 tmux 默认绿底且 resurrect 快捷键为空绑定。本轮只补提示，不自动联网装插件。
- 已做：
  - `install.sh` 新增 `tmux_plugins_missing()`（`~/.tmux/plugins` 下除 `tpm` 外无目录即视为未装；TPM 按仓库 basename 落盘，`catppuccin/tmux` → `plugins/tmux`）。
  - `install.sh` main 的 TPM 块末尾：TPM 已就位且插件缺失时打印 `log_warn`（提示 `C-a I` / `prefix + I`）+ `log_info`（说明主题与 resurrect 未生效）；无 tmux 或插件已装时不打印。
  - 测试：新增 `tests/install_tpm_test.sh`（沙箱 `link_core_utils` + fake `tmux`）：① 只有 TPM → 必须出现 `C-a I`；② `plugins/tmux` 存在 → 不得出现；③ 无 tmux → 不得出现。
  - 文档：`README.md` 使用方式段补「TPM 只装管理器、插件需 `Ctrl+a + I`、脚本会在只剩 TPM 时提示」；`.config/shared/tmux/README.md` 已有「插件安装 → `Ctrl+a + I`」章节，无需改动；`memory/tmux.md` 新增「插件」小节记录该环境事实与 basename 落盘规则。
- 验证：改动前 `tests/install_tpm_test.sh` 复现失败（expected 'C-a I' in install.output）；实现后 PASS；沙箱实跑输出确认为 `[WARN] tmux plugins are not installed yet — start tmux and press C-a I (prefix + I) to install them` + 后续 INFO 行；`bash -n install.sh`、`sh -n tests/install_tpm_test.sh` 通过；`git diff --check` clean；`./tests/run.sh fast`（见本轮结论）。未在 live 真机执行 `C-a I`（联网装插件属用户操作）。
- live/提交：未同步 live（只改仓库，live `~/.tmux.conf` 与仓库一致，无需同步）；未提交。回滚：`git checkout -- install.sh README.md memory/tmux.md && rm tests/install_tpm_test.sh`（或提交后 `git revert <hash>`）。
- 后续可能方向：① 当前环境 `~/.tmux/plugins` 只有 tpm，需用户按一次 `C-a I` 才会出现主题；② 可选：install.sh 在用户明确授权下直接调 `~/.tmux/plugins/tpm/bin/install_plugins` 免按键安装（本轮刻意未做自动化）。

## 2026-09-26 — Obsidian 打不开：wrapper 指向本机不存在的 /opt/Obsidian，改为安装官方 arm64 构建 + 缺失守卫

- 目的：用户报"现在无法打开 Obsidian"；定位根因、恢复可用，并把"静默失败"这一类回归堵掉。
- 根因（实测）：`~/.local/share/applications/obsidian.desktop` → `~/.config/scripts/obsidian-wayland` → `exec /opt/Obsidian/obsidian`，本机（aarch64）该二进制不存在 → 点开即 `exec: /opt/Obsidian/obsidian: not found` + exit 127；entry 的 `StartupNotify=false` 让失败完全不可见（只能靠 `sh -x` 手动复现）。该 wrapper 是 2026-09-02 在 **x86_64 机器**上按 deb 口径改写的（该轮 trace 明写"x64 niri 会话"），2026-09-04 起被 `install.sh` 铺到本机 arm64 笔记本；而上游 arm64 **根本不发 deb**（v1.13.7 资产只有 `obsidian_1.13.7_amd64.deb` + `Obsidian-1.13.7-arm64.AppImage` + `obsidian-1.13.7-arm64.tar.gz`），本机从未有过该安装（dpkg/apt 全量日志无 obsidian 记录；`/opt` 目录项最后变更停在 2026-08-11；`/etc/apparmor.d/obsidian` 是镜像 apparmor 包自带的 unconfined profile）。
- 次要发现：本机遗留的 `~/AppImages/obsidian.appimage`（4 月旧构建，Electron 33 / Chromium 130，asar 虽被自更新到 1.13.7）在当前 mtgpu EGL 上必崩：ANGLE `eglCreateContext failed`（EGL_BAD_MATCH）→ GPU 进程反复崩 → `FATAL: GPU process isn't usable. Goodbye.`，无窗口。共试 11 组参数（原生 Wayland、XWayland、`--disable-gpu-compositing`、`--use-angle=gl|swiftshader`、`--disable-gpu`、`--no-sandbox`、`--in-process-gpu`、Mesa EGL 覆盖、`--render-node-override=/dev/dri/renderD128`）全部无窗口，X11 路径还 core dump；故"把 wrapper 指回旧 AppImage"不成立，必须换新构建。
- 已做（live/system）：
  - 下载官方 `obsidian-1.13.7-arm64.tar.gz`（127,754,080 B，与上游 size 一致）并解压安装到 `/opt/Obsidian`（Chromium 150；`/opt` 属主 rikoo，无需 sudo）。
  - 同步新 wrapper 到 live：备份 `~/.config/scripts/obsidian-wayland.backup.20260926_102547_909478`（替换前内容，1024 前另有 `backup.20260904_234146_7663`；保留 2 份，未触发清理）。
- 已做（仓库）：
  - `.config/scripts/obsidian-wayland`：exec 前加 `[ ! -x "$obsidian_bin" ]` 守卫 → `notify-send` + stderr + `exit 127`；加 `OBSIDIAN_WAYLAND_BIN` 测试钩子（对齐 `corplink-service` 的 `CORPLINK_SYSTEMCTL` 惯例）；头注释改 x86_64 deb / aarch64 官方 tar.gz 口径。
  - `tests/wayland_scripts_test.sh`：obsidian 用例从纯文本断言升级为行为测试——stub 二进制断言 Wayland 下追加 `--ozone-platform=wayland --enable-wayland-ime --disable-vulkan` 且透传参数、X11 下不加 flag、二进制缺失时 stderr 含 `Obsidian unavailable` 且 rc=127。
  - 文档：`.config/scripts/README.md` 补 `obsidian-wayland` 行；`.config/linux/desktop-entries/README.md` 两行改口径；`.config/linux/niri/README.md` §Obsidian 重写并补 arm64 安装命令；`memory/desktop.md` 更新 text-input 矩阵版本号 + 新增"跨机器 wrapper 必须自带目标缺失守卫"与"mtgpu 上旧 Electron 必崩、新 Electron 回退软件渲染"两条长期事实。
- 验证：`sh -n .config/scripts/obsidian-wayland tests/wayland_scripts_test.sh` 通过；守卫行为用 `unshare -rm` + tmpfs 覆盖 `/opt/Obsidian` 复现——新 wrapper 输出 `Obsidian unavailable: /opt/Obsidian/obsidian not found.` rc=127，`git show HEAD:` 的旧 wrapper 同条件只有 `exec: /opt/Obsidian/obsidian: not found`（证明新增断言能抓住回归）；`sh tests/wayland_scripts_test.sh` PASS；`strings /opt/Obsidian/obsidian | grep Chrome/` → `Chrome/150.0.7871.212`；live 实跑 `~/.config/scripts/obsidian-wayland` → `niri msg windows` 出现 `md.obsidian.Obsidian`（标题 `obs_dir - Obsidian 1.13.7`），t=20s/40s 复核窗口与 8 个进程仍在（GPU 进程仍在 EGL 初始化失败后回退软件渲染，不再致命）。
- 未通过项（与本轮无关，按既有约定只报告不批量修）：本机 `./tests/run.sh fast` = PASS=46 FAIL=1，唯一 FAIL 为 `tests/repo_docs_test.sh` 报 `expected 'swaync/' in README.md`——原因是工作树里存在 2026-08-31 遗留的**空目录** `.config/linux/swaync`（未跟踪、无内容）被 README 结构树守卫扫到；把本轮 6 个改动文件复制进 HEAD 干净 clone 后 `./tests/run.sh fast` 为 PASS=47 FAIL=0 SKIP=0（含 `repo_docs_test.sh` PASS）。
- live/提交：live wrapper 已同步（备份见上）；本轮已提交 `8c7e118`（fix(obsidian): guard missing /opt/Obsidian, document arm64 install，6 文件，已推送；`logs/trace.md` 由紧随其后的回填提交入库）。回滚：`git revert 8c7e118`，或 `git checkout 5cd5ee1 -- .config/scripts/obsidian-wayland .config/scripts/README.md .config/linux/desktop-entries/README.md .config/linux/niri/README.md memory/desktop.md tests/wayland_scripts_test.sh`；live wrapper 恢复：
  ```bash
  cp -p ~/.config/scripts/obsidian-wayland.backup.20260926_102547_909478 ~/.config/scripts/obsidian-wayland
  ```
  如需回到"本机没有 /opt/Obsidian"的原状：`rm -rf /opt/Obsidian`（安装物可随时用官方 tar.gz 重解压）。
- 后续可能方向：① 空目录 `.config/linux/swaync` 要么 `rmdir`，要么补进仓库并列进 README 结构树，否则 fast 套件在本机常红；② 4 月旧 AppImage（`~/AppImages/obsidian.appimage`，Chromium 130 已确认在本机起不来）可清理，避免下次误用；③ mtgpu EGL 与旧 Chromium 的不兼容目前靠"换新构建"绕过，若将来再遇 Electron 应用无窗口，先 `strings <binary> | grep Chrome/` 比版本，再怀疑 wrapper 路径。

## 2026-09-28 — 钉钉 @ 候选框回归：DMS 接管 niri 后 common.kdl 失联，改用 DMS 窗口规则修复
- 目的：x64 Ubuntu niri + DMS 会话里钉钉聊天输入 `@` 的成员候选框再次「闪现即消失」；定位并修复。
- 根因（静态证据链）：DMS 于 2026-09-12 重新生成的 `~/.config/niri/config.kdl` 只 include `dms/*.kdl`，不含仓库 `common.kdl`；而 2026-08-29 定案的钉钉 `open-focused false` 规则只存在于 `~/.config/niri/common.kdl`。`dms config windowrules list niri` 的生效规则集（`dmsStatus.effective=true`）里没有任何 dingtalk 条目；`niri validate -c ~/.config/niri/config.kdl` 通过但规则缺席；`niri msg windows` 确认 app-id 仍为 `com.alibabainc.dingtalk`（DMS `appIdSubstitutions` 为空）。即 2026-09-12 trace 已标注的隐患（DMS 生成配置未含仓库窗口规则）实际发作。
- 已做（live）：备份 `~/.config/niri/dms/windowrules.kdl` → `windowrules.kdl.backup.20260928_100943_3398336`（该目标首个备份，无需清理）；`dms config windowrules add niri '{"name":"DingTalk popups keep keyboard focus","matchCriteria":{"appId":"^com\\.alibabainc\\.dingtalk$"},"actions":{"openFocused":false},"enabled":true}'` → id `wr_1790561384874988781`，niri 于 10:09:45 自动重载配置（journal `niri_config: loaded config`）。仓库文档同步：`.config/linux/niri/README.md`（窗口规则段增 DMS 例外与命令）、`memory/niri.md`（钉钉规则与排障入口）、`memory/dingtalk.md`（回归条目）。
- 验证：`dms config windowrules list niri` 含该规则且 `open-focused false` 已写入 KDL；用户实机确认 `@` 候选框正常显示不再消失；`niri msg event-stream` 抓取显示 9 个钉钉弹窗（title `Form`）全部 `is_focused: false`、`focus_timestamp: None`，主窗口焦点全程保持。次要变量：钉钉已由 `8.2.8.260904001` 升到 `8.3.1-Release.260917001`，规则恢复后 @ 正常，排除版本因素。
- 回滚信息：已提交并推送 `69af4fc`（docs(niri): DMS 机器重建钉钉窗口规则；与下一条合并为同一个 commit）；仓库回滚 `git revert 69af4fc`；live 恢复：
  ```bash
  dms config windowrules remove niri wr_1790561384874988781
  # 或整文件恢复
  cp -p ~/.config/niri/dms/windowrules.kdl.backup.20260928_100943_3398336 ~/.config/niri/dms/windowrules.kdl
  ```
- 后续可能方向：① DMS 规则模型暂无 `exclude` 编辑入口（上游 #2996 仅做透传），钉钉「主窗口平铺、其余弹窗浮动」规则在 DMS 机器上暂缺——同日已用两条正向规则补回，见下一条；② 仓库 `common.kdl` 的其它规则（键位等）在 DMS 机器同样缺席，DMS 侧重建属长期事项。

## 2026-09-28 — 钉钉弹窗平铺：DMS 机器重建浮动策略（主窗口保持平铺）
- 目的：用户反馈钉钉弹窗（@ 候选框、表情面板等）全部平铺，主窗口 `Mod+F` 展开后弹窗落到可视区外；恢复仓库原有的「除主窗口外全部浮动」策略。
- 根因：同上一条——DMS 机器 `common.kdl` 不参与，仓库 `exclude title=... + open-floating true` 缺失；DMS 规则模型无 `exclude` 编辑入口。
- 已做（live）：再次备份 `~/.config/niri/dms/windowrules.kdl` → `windowrules.kdl.backup.20260928_101538_3405249`；新增 `wr_1790561738805679306`（appId dingtalk → `open-floating true`）与 `wr_1790561738813023192`（appId + title `^钉钉|钉钉$` → `open-floating false`）。利用 niri「规则按顺序处理、后者覆盖前者」语义表达仓库的 exclude 语义；同一 `match` 节点内 `app-id`+`title` 为 AND（`niri-config/src/window_rule.rs` 的 `Match` 结构体按属性解码，已核对源码）。
- 验证：`niri msg event-stream` 抓取到钉钉弹窗（title `Form`）`is_floating: true`、`is_focused: false`、浮层位置 `(852, 383)`，主窗口 1349 保持 `is_floating: false`；用户实机确认 `Mod+F` 展开主窗口后 @ 候选框作为浮层可见。
- 仓库文档同步：`.config/linux/niri/README.md`（三条命令与语义说明）、`memory/niri.md`、`memory/dingtalk.md`。
- 回滚信息：已提交并推送 `69af4fc`（与上一条合并为同一个 commit，live 规则由 DMS CLI 写入、不在仓库内）；仓库回滚 `git revert 69af4fc`；live 恢复：
  ```bash
  dms config windowrules remove niri wr_1790561738805679306
  dms config windowrules remove niri wr_1790561738813023192
  # 或整文件恢复
  cp -p ~/.config/niri/dms/windowrules.kdl.backup.20260928_101538_3405249 ~/.config/niri/dms/windowrules.kdl
  ```
- 后续可能方向：① 标题以「钉钉」开头/结尾的弹窗仍会平铺（与仓库配置同残余），若 DMS 后续支持 `exclude` 编辑入口可换成单条 exclude 规则；② 仓库 `common.kdl` 的其它规则（键位等）在 DMS 机器仍缺席，DMS 侧重建属长期事项。

## 2026-09-30 — 黑苹果 macOS 装 Nerd Font（MesloLGS Nerd Font Mono）
- 目的：本机（macOS 15.8 / Apple Terminal / port 版 CLI）starship、tmux、nvim、lsd、yazi 的 Nerd Font 图标全缺字，补齐终端图标字体。
- 根因：该机无 brew（黑苹果 x86_64 走 MacPorts），MacPorts 只有 `ttf-nerd-fonts-symbols`（纯图标字体，Terminal.app 不保证回退命中），从未装过任何 Nerd Font；`fc-list ':charset=f02dc'` 等图标码位仅命中 `.LastResort`。Terminal.app `Basic` 描述符当前字体为 `SFMono-Regular`。
- 已做（live/system，仓库外）：从官方 Nerd Fonts v3.5.1 下载 `Meslo.tar.xz`（5 MB；`Meslo.zip` 111 MB 多打 OTF，不必下），解压后取 4 个 `MesloLGSNerdFontMono-{Regular,Bold,Italic,BoldItalic}.ttf` 复制进 `~/Library/Fonts/`（原目录为空，无覆盖、无需备份）。
- 验证：`fc-list | grep MesloLGS` 列出 4 个 face；`fc-scan` 确认 family 为 `MesloLGS Nerd Font Mono`（与 `.config/shared/alacritty` 一致）；`fc-list ':charset=f02dc|f03d8|f051c|f0734'` 命中新字体；`system_profiler SPFontsDataType` 可见，CoreText 已注册。未改 Terminal.app 描述符（字体是 NSKeyedArchiver blob，无 AppleScript / `defaults` 安全入口），字体切换留待 GUI。
- live/提交：仅本机 `~/Library/Fonts` 变更；未动仓库、未同步 `~/.config`、未提交；trace 随下次仓库改动入库。
- 回滚：`rm ~/Library/Fonts/MesloLGSNerdFontMono-*.ttf`；若已切 Terminal 字体，在「设置 → 描述文件 → 文本 → 字体」改回 `SF Mono`。
- 后续可能方向：① 在 Terminal.app 手动把 Basic 描述符字体改为 `MesloLGS Nerd Font Mono`（建议 13pt），新开窗口验证图标；② 该机无 brew，字体进不了 `.config/macos/Brewfile`，如需可复现可补一段 `~/Library/Fonts` 下载脚本；③ `memory/organizing_preferences.md` 已由用户补记「黑苹果走 MacPorts」，是否再记「Nerd Font 手动装 `~/Library/Fonts`」待定。

## 2026-09-30 — macOS 窗口管理器按机型分治：黑苹果 yabai + skhd，白苹果 AeroSpace
- 目的：用户确认「yabai + skhd 是 mac x86（黑苹果）首选，白苹果依旧 AeroSpace 首选」，并在仓库落地 yabai/skhd 配置与部署/测试链路（此前仓库只有 AeroSpace 一套）。
- 环境结论（只读勘察）：macOS 15.8 / Intel x86_64 黑苹果（MacBookPro15,2，i5-8250U）；无 Homebrew，MacPorts 2.12.6 在 `/opt/local`；`nvram csr-active-config=%ff%0f%00%00`（0x0FFF 全关，`csrutil status` 报 `unknown (Custom Configuration)`）→ yabai scripting addition 前提已满足，不需改 SIP；`com.apple.spaces spans-displays` 未设置（分离空间已开）；`mru-spaces` 与 `EnableStandardClickToShowDesktop` 未设置，需补默认值。
- 关键实测（决定走官方预编译而非 MacPorts）：下载 `yabai-v7.1.25.tar.gz` 校验 sha256 与官方脚本一致；`codesign -dvvv` 得 `Identifier=com.asmvik.yabai` / `Authority=yabai-cert` / `TeamIdentifier=not set`；`codesign -v` = valid on disk + satisfies its Designated Requirement；`spctl -a` = rejected（自签名，无 quarantine 时无害，`curl` 不写 quarantine）。故本机无需自建证书/重签，TCC 辅助功能授权可跨 yabai 升级保留；MacPorts 版（7.1.24，源码编译未签名）要求每次 `port upgrade` 后重签 + 重算 sudoers 哈希，故不采用。
- 已做（仓库，未提交）：新增 `.config/macos/yabai/{yabairc,skhdrc,README.md}`（SA 加载 + dock_did_restart 信号、全局配置对齐 AeroSpace 的 gaps 5 与主题色、浮动窗口规则、幂等空间标签 1/2/3/C/B/N/W、alt=Mod 键位表；标点键用大写十六进制 keycode，因 skhd 字面量只认 return/tab/escape/方向键等，依据 `src/tokenize.h`）；`install.sh` 的 `macos_configs` 增 `command -v yabai`/`skhd` 两条部署项；`.config/macos/defaults.sh` 补 `mru-spaces=false`、`EnableStandardClickToShowDesktop=false`、`StandardHideDesktopIcons=false`；`.config/macos/aerospace/README.md` 与根 `README.md`（结构树 + 机型分治段 + 「升级已安装的工具」段的 yabai 升级入口）标注首选关系与升级路径；`memory/desktop.md` 新增「macOS 窗口管理器」决策段，`memory/organizing_preferences.md` 同步包管理例外条款。
- 验证：新增 `tests/yabai_config_test.sh`（yabairc `sh -n`、SA/配置/规则/幂等守卫断言、skhd 绑定断言、标点键不得写 `minus/equal/esc/slash/comma` 且十六进制不得小写、README 机型分治与 install.sh 部署项断言、根 README 升级入口断言）；`tests/install_macos_test.sh` 增 yabai/skhd stub 与部署断言；实测 `./tests/run.sh fast` 得 `PASS=41 FAIL=7 SKIP=1`（同日 `c8e393f` 删除 `update_ai_clis_test.sh` 后复测；该 commit 前为 PASS=43），7 个 FAIL 与本机既有 macOS 可移植性基线一致（无新增失败）；`repo_docs_test`/`macos_defaults_test`/`aerospace_config_test`/`yabai_config_test` 单跑均 PASS；`sh -n`/`bash -n`/`git diff --check` 均 OK。
- live/提交（用户二次确认「把 yabai+skhd 这套部署落地」后执行，**已提交 `c4e41cb` 并推送 `origin/main`**）：① 官方安装脚本装 yabai v7.1.25 → `~/.local/bin/yabai`（sha256 `372ad557a7c54a6199a78dcbcefe5b60fd0224e5c1f5139cfaed00dfdaa44501`，`codesign -dvvv` 复核 `Identifier=com.asmvik.yabai` / `Authority=yabai-cert` / `TeamIdentifier=not set`）+ man 页 → `~/.local/share/man/man1/yabai.1`（该目录本轮新建）；② 手工部署 `~/.config/yabai/yabairc` 与 `~/.config/skhd/skhdrc`（两个目标均不存在 → 按惯例无 `*.backup.*`；`diff` 确认与仓库逐字节一致）；③ `bash .config/macos/defaults.sh` 写入 3 个 WM 前提键（`com.apple.dock mru-spaces=0`、`com.apple.WindowManager EnableStandardClickToShowDesktop=0`、`StandardHideDesktopIcons=0`，输出 `3 change(s)`，其余键已幂等跳过）并重启 Finder/Dock/SystemUIServer；④ 用户写入 `/private/etc/sudoers.d/yabai`（哈希与实测一致：`372ad557…`；`visudo -c` 报 `/etc/sudoers: parsed OK` + `bad permissions, should be mode 0440`——`sudo tee` 按 umask 022 建出 0644，但 sudo 1.9.13p2 只拒绝 g/o **可写**的文件，`sudo -n -l` 仍列出该 NOPASSWD 条目，建议 `chmod 0440` 符合约定）；⑤ `sudo yabai --load-sa` 执行成功（rc=0 且无 stderr；对照 `src/osax/loader.m`，所有失败情形都会 `fprintf(stderr, "could not …")`），并实测**确实落盘 SA**：`/Library/ScriptingAdditions/yabai.osax`（`Contents/MacOS/loader` + `Contents/Resources/payload.bundle`，root 拥有，时间戳 20:58）；⑥ 用户并行执行 `sudo port install skhd` → `/opt/local/bin/skhd` 0.3.9_1（active），随即部署 `~/.config/skhd/skhdrc`（目标不存在 → 无 backup；`diff` identical）。配置路径实测：`strings skhd` 含 `%s/.config/skhd/%s`，与 XDG_CONFIG_HOME 未设置相匹配（同 yabai）。注：`skhd --help` 不可用且无 dry-run——未授权辅助功能时 skhd 直接 `must be run with accessibility access! abort..`，因此 **skhdrc 的语法/键位解析只能等 GUI 授权后由 skhd 自己验证**（我的静态依据：`src/tokenize.h` 的 modifier/literal 白名单 + `parse.c` 对 Token_Key_Hex 的处理）。验证：交互登录 shell（`zsh -lic`）里 `command -v yabai` → `~/.local/bin/yabai`、`yabai -v` = `yabai-v7.1.25`（`~/.local/bin` 在登录 PATH 中排第一，agent 工具的 bash 环境不含该目录，属工具环境差异而非部署问题）；`XDG_CONFIG_HOME` 未设置、`strings yabai` 含 `%s/.config/yabai/%s` → 确认读的就是 `~/.config/yabai/yabairc`；`com.apple.spaces spans-displays` 仍未设置（分离空间保持开启）；注入后 `pgrep -x Dock` 健在（pid 58628），无 Dock 崩溃。**待用户执行**（需 sudo / GUI）：`sudo chmod 0440 /private/etc/sudoers.d/yabai`、辅助功能勾选 `yabai`/`skhd`、`yabai --start-service` + `skhd --start-service`；**顺序不可颠倒**：yabairc 首行即 `sudo yabai --load-sa`，sudoers 未配前起服务会卡在密码提示。
- 回滚信息：**已提交 `c4e41cb`**；丢弃仓库改动：`git checkout -- .config/macos install.sh README.md memory/desktop.md memory/organizing_preferences.md tests/install_macos_test.sh && rm -rf .config/macos/yabai tests/yabai_config_test.sh`（trace 本条目一并丢弃）。live 本轮为新建（无旧文件可比对，故无 backup 快照），恢复/卸载：
  ```bash
  sudo yabai --uninstall-sa    # 移除 /Library/ScriptingAdditions/yabai.osax
  sudo rm -f /private/etc/sudoers.d/yabai
  rm -f ~/.local/bin/yabai ~/.local/share/man/man1/yabai.1
  rmdir ~/.local/share/man/man1 ~/.local/share/man 2>/dev/null || true
  rm -rf ~/.config/yabai ~/.config/skhd
  defaults delete com.apple.dock mru-spaces
  defaults delete com.apple.WindowManager EnableStandardClickToShowDesktop
  defaults delete com.apple.WindowManager StandardHideDesktopIcons
  killall Dock
  ```
- 后续可能方向：① 待用户装好 skhd、授权辅助功能并 `--start-service` 后做真机回归，重点验证 `ensure_space` 里 `space --create` 是否聚焦新空间（未真机验证；若否则改为按索引打标签）；② AeroSpace 的 `Mod+r` service mode 暂无对应实现（skhd 的模式语法没有「执行命令并返回」的无歧义写法），SA 专属的 sticky/pip 已直接绑到 `Mod+Ctrl+*`。

## 2026-09-30 — 黑苹果用户级 CLI 迁移尝试并回退；删除 update-ai-clis
- 目的：用户先问「哪些包能像 pi 一样迁到用户目录」，据此把纯 CLI 工具从 MacPorts 迁到 `~/.local` 并配套统一升级脚本；实施后用户质疑「有些 app 用 port 升级才是正解」「仓库里放 update 脚本不常规」，故全量回退，升级方式改回各工具自带 updater。
- 环境结论（只读勘察）：port vs 上游——neovim 0.12.4/0.12.5、yazi 26.9.1/=、starship 1.26.0/=、nodejs22 22.22.2；`pi-coding-agent` port 仅 0.87.1（npm 已 0.99.1），`herdr` port 仅 0.8.2（官方 0.9.3）且 `depends_build {zig-0.15 rust cargo}` 需源码编译。结论：常规 CLI 交回 port；只有 npm 分发的 AI CLI 与 herdr 值得用户级。
- 关键发现（本机实测）：**裸 `npm update -g` 不可用**——MacPorts 给 npm10 打了补丁（`/opt/local/lib/node_modules/npm/lib/commands/update.js`），无包名（或参数含 `npm`）时直接 `throw` 退出（避免顺带升级 npm 自身）；显式列包 `npm update -g <pkgs>` 可用。三个 AI CLI 自带 updater 实测均 rc=0：`pi update --self`（already up to date）、`claude update`（Installation method set to: global / up to date）、`codex update`（内部执行 `npm install -g @openai/codex`）。
- 已做（仓库，未提交）：先新增 `path.zsh` Darwin `node-current` + 用户级优先、`.config/scripts/update-user-clis`、install 项、测试、README/memory；随后回退——`git checkout HEAD -- .config/shared/zsh/path.zsh tests/zsh_path_test.sh`，删除 `.config/scripts/{update-ai-clis,update-user-clis}` 与 `tests/{update_ai_clis,update_user_clis}_test.sh`，从 `install.sh`/`README.md`/`memory/organizing_preferences.md` 移除对应内容。按用户要求把 `update-ai-clis`（硬编码 claude-code+codex）一并删除，改为文档化「各 CLI 自带 updater」；`tests/repo_docs_test.sh` 的 `update-ai-clis` 断言换成 `npm update -g`；`memory/herdr.md` 新增「安装与升级」段（port 0.8.2 stale + 源码编译，走官方 installer + `herdr update`）。
- live（本机）：曾装用户级 node v22.23.3 / nvim 0.12.5 / yazi 26.9.1 / starship 1.26.0，回退时已全部删除；`~/.local/bin/herdr`（0.9.3）保留。`~/.config/scripts/update-ai-clis` 移为 `~/.config/scripts/update-ai-clis.backup.20260930192118`。port 包一个都未卸载（六个仍 active）；live `~/.config/zsh/path.zsh` 与仓库一致。
- 验证：`bash -n install.sh`、`git diff --check` OK；`repo_docs_test`/`zsh_path_test`/`zsh_plugins`/`zsh_functions`/`zsh_history`/`macos_defaults`/`herdr_config` PASS；`install_backup`/`install_bash_reexec`/`install_zshenv` 以 `sh` 跑 PASS；`./tests/run.sh fast` = PASS=41 FAIL=7 SKIP=1，7 个 FAIL 与既有 macOS 可移植性基线一致（`install_macos_test` 为平台 SKIP）。
- 回滚信息：**未提交**。仓库被删脚本可 `git checkout HEAD -- .config/scripts/update-ai-clis tests/update_ai_clis_test.sh` 恢复；live 脚本恢复 `mv ~/.config/scripts/update-ai-clis.backup.20260930192118 ~/.config/scripts/update-ai-clis`；live 用户级二进制已删，无 backup 目录（按需重装）。
- 未完成（可选，需用户 sudo）：卸载陈旧 port `pi-coding-agent`（0.87.1）——`sudo port uninstall pi-coding-agent`（`nodejs22`/`npm10` 保留作 npm 宿主）。
- 注意：本轮与另一会话的「yabai/skhd」改动共存于同一工作区（对方改 `install.sh`/`defaults.sh`/`aerospace/README.md`/`memory/desktop.md`/`tests/install_macos_test.sh`，新增 `.config/macos/yabai/*`、`tests/yabai_config_test.sh`），提交时建议按主题分开。
- 后续可能方向：① `path.zsh` 的「个人 bin 应晚于平台分支 prepend」本轮回退后仍是潜在遮蔽点（`~/.local/bin` 排在 `/opt/local/bin` 之后），若日后出现同名 port（如 herdr/yabai）再处理；② 是否把「黑苹果不用裸 `npm update -g`」提升到 `memory/`（现已写入）。

## 2026-09-30 — yabai 首次启动实机回归：空间标签与规则两处修复
- 目的：用户完成 GUI 授权并 `--start-service` 后做真机回归，修掉 `ensure_space` 那套未经实机验证的标签引导逻辑。
- 现象与根因（均为 yabai v7.1.25 / macOS 15.8 实测）：① 7 个空间都建对了，但**标签只剩最后一个 `W` 落在 index 1**、其余为空——`space --create` 不会把焦点移到新空间，而裸 `space --label` 作用于“当前聚焦空间”，两者叠加使 7 次 label 全打在同一个空间上；② `space=C` / `space=N` 两条规则被拒（规则数 6 而非 8），日志 `value 'C' is not a valid option for SPACE_SEL`——yabai 在**注册规则时**就校验 `SPACE_SEL`；③ 想改用数字标签也不行：`space --label 1` → `'1' cannot be used as a label.`（`src/message.c` 的 `parse_label` 要求 label 是字符串 token，否则与 mission-control index 在 `SPACE_SEL` 里撞车）。
- 改动：`.config/macos/yabai/yabairc` 把 `ensure_space` 换成 `label_spaces`——先按 `grep -c '"index"'` 计数补齐到 7（`space --create` 后 `query` 有延迟，用本地计数推进避免多建一个，create 非 0 就停手），再**按空间索引显式**打标签，且只打 `C/B/N/W` 给 index 4..7（1/2/3 用 index 寻址，`mru-spaces=false` 保顺序稳定）；`space=` 两条规则加标签存在性守卫。同步 `.config/macos/yabai/skhdrc`（注释说明 1/2/3 用 index）、`README.md`（与 AeroSpace 的差异段）、`tests/yabai_config_test.sh`（改断言 `label_spaces` / `while … -lt 7` / `for _label in C B N W` / 标签守卫）、`memory/desktop.md`（把上述硬规则沉淀为长期约束）。
- 验证（live，两次 `--restart-service`）：空间数 `7 → 7` 不增长（幂等）；标签为 `1/2/3` 空 + `4=C 5=B 6=N 7=W`；规则数 **8**（6 浮动 + 2 空间，两条 app→空间规则已注册）；`space --focus C`（label）与 `space --focus 1`（index）均成功；`/tmp/yabai_rikoo.err.log` 除三条历史行（授权前的 accessibility abort、上一轮的 C/N 报错）外**无新错误**，`.out.log` 为 4× `yabai configuration loaded..`；`/tmp/skhd_rikoo.err.log` 无解析错误（只有授权前那次 abort 与正常的热键响应），说明含十六进制 keycode 的 skhdrc 已被 skhd 接受。
- live/提交：**已提交 `c4e41cb` 并推送 `origin/main`**。本轮 live 同步（目标已存在，按惯例先备份）：`~/.config/yabai/yabairc.backup.20260930_211003_842225000`（另有更早一份 `yabairc.backup.20260930_210715_116648000`）、`~/.config/skhd/skhdrc.backup.20260930_211003_842225000`；已按保留 3 份的惯例清理更旧的。
- 回滚信息：**已提交 `c4e41cb`**；live 回滚（含上一轮的完整卸载）：
  ```bash
  cp -p ~/.config/yabai/yabairc.backup.20260930_211003_842225000 ~/.config/yabai/yabairc
  cp -p ~/.config/skhd/skhdrc.backup.20260930_211003_842225000 ~/.config/skhd/skhdrc
  yabai --restart-service
  # 彻底卸载：
  # yabai --uninstall-service; skhd --uninstall-service; sudo yabai --uninstall-sa
  # sudo rm -f /private/etc/sudoers.d/yabai; rm -f ~/.local/bin/yabai ~/.local/share/man/man1/yabai.1
  # rm -rf ~/.config/yabai ~/.config/skhd
  ```
- 后续可能方向：① skhd 的十六进制 keycode 绑定（`0x1B`/`0x18`/`0x2C`/`0x2B`）已被 skhd 解析接受，但**未经实际按键触发**（日志里只有 focus/swap 类响应），需按下 `Mod+Shift+-`、`Mod+/` 后才能确认；② `space 1/2/3` 靠 index 寻址，若日后手动调序（如 `space --move`）会错位——需要时改成给它们也打非数字 label（yabai 不接受 `1`，但非纯数字 token 可以，如 `n1`）。

## 2026-09-30 — yabai 按键实测确认 + 规则/resize 三处修正
- 目的：用户报告已按过 `Mod+Shift+-` 与 `Mod+/`，验证这两条十六进制 keycode 绑定是否真的派发，并复核运行期状态。
- 实测结论（`/tmp/skhd_rikoo.err.log` 23 → 50 行）：① `0x1B`（minus）**确实派发**——新增 20 行 `cannot locate a bsp node fence.`，是 yabai 对 `window --resize right:-50:0` 的真实回应，证明 skhd 的 `0x..` 物理 keycode 路径端到端可用；② 报错本身是预期：当时聚焦窗口是空间 1 唯一的 Chrome（`split-child: second_child` 且 `split-type: none`，占满整屏），两侧都没有 fence；③ `0x2C`（slash → `space --layout bsp`）无报错、空间 type 仍为 `bsp`，与预期一致但不可区分（bsp→bsp 是幂等操作）。
- 顺带挖出并修掉三处真问题：
  1. **resize handle 不对称**（源码 `src/window_manager.c:368` 的 `window_manager_resize_window_relative`：`HANDLE_LEFT/RIGHT` 分别取 `DIR_WEST/DIR_EAST` 的 fence）——`first_child`（左/上）只有东/南 fence、`second_child`（右/下）只有西/北 fence，我两条都写 `right:` 对 `second_child` 必然失败。改为 `skhdrc` 里按 右→左→下→上 依次尝试（4 段 `||` 链，每段 `2>/dev/null`），等效 AeroSpace 的 `resize smart`，且失败尝试不再刷 skhd 日志。
  2. **`app=` 匹配本地化应用名**：本机 `AppleLocale=zh_CN`，微信窗口的 app 名是「微信」，`app="^WeChat$"` 静默不匹配 → 微信被平铺（query 里 `is-floating:false`）。改为 `^(WeChat|微信)$`，系统设置同理合并为中英 alternation（顺带把重复的 System Preferences 行合并）。yabai 规则不支持 bundle-id（AeroSpace 用的是 `com.tencent.xinWeChat`，无法照搬）。
  3. **规则只对新窗口生效**：yabai 规则不作用于注册前已存在的窗口 → `yabairc` 末尾加 `yabai -m rule --apply`，登录/重启即让现有 Finder/微信/VSCode/Obsidian 到位；代价是每次 yabai 启动会把匹配 `space=` 的窗口移回对应空间（已写入 README，不想要删一行即可）。
- 验证（live）：`yabai --restart-service` 连续两次空间数恒为 7（幂等）；标签仍为 1/2/3 空 + `4=C 5=B 6=N 7=W`；规则数 **7**（5 浮动 + 2 空间，`space:` 分别解析为 4/6）；**微信 `is-floating` 由 false 变 true**（证明本地化规则与 `--apply` 均生效）；`skhd --restart-service` 换新 pid 且 err 日志**零新增**（= 含 `\` 续行 `||` 链的 skhdrc 解析通过）；yabai err 日志除 3 条历史行外无新增。
- live/提交：**已提交 `c4e41cb` 并推送 `origin/main`**。本轮备份：`~/.config/yabai/yabairc.backup.20260930_212449_883986000`、`~/.config/skhd/skhdrc.backup.20260930_212449_883986000`（已按保留 3 份清理更旧）。
- 回滚信息：**已提交 `c4e41cb`**；live 回滚：
  ```bash
  cp -p ~/.config/yabai/yabairc.backup.20260930_212449_883986000 ~/.config/yabai/yabairc
  cp -p ~/.config/skhd/skhdrc.backup.20260930_212449_883986000  ~/.config/skhd/skhdrc
  yabai --restart-service; skhd --restart-service
  ```
- 后续可能方向：① resize 回退链的**“两窗口同空间”场景尚未被实际按键验证**（当前没有任何空间有 2 个管理窗口，只有源码级依据）——开两个 Chrome 窗口后按 `Mod+Shift+-` 即可确认；② 验证布局切换建议按 `Mod+,`（stack）再 `Mod+/`（bsp），空间 `type` 会明显变化，比单独按 `Mod+/` 可观测；③ `yabai -m rule --apply` 是否保留（每次启动把 VSCode/Obsidian 拉回 C/N）待用户实际体验后决定。

## 2026-09-30 — yabai/skhd 对齐仓库约定：工作区收敛到 1-5 + 四处工程改进
- 目的：按用户要求落地「第一档」优化（焦点色对齐、README 补两节、测试补全每条绑定、`install.sh` 的 borders 提示门控），并**取消命名工作区，只保留 1-5**。
- 已做（仓库，未提交）：
  1. `yabairc`：`insert_feedback_color` 由 mauve `0xffcba6f7`（沿袭 aerospace）改为 **Catppuccin 蓝 `0xff89b4fa`**（与 niri `focus-ring active-color`、awesome `border_focus` 一致）：`label_spaces`（7 空间 + C/B/N/W 标签）→ `ensure_spaces`（只补到 5、不打任何标签）；删除 `space=C` / `space=N` 两条 app→工作区规则及其存在性守卫；`rule --apply` 保留（现在只剩浮动规则，无跨空间搬窗口副作用）。
  2. `skhdrc`：改为 `Mod+1..5` 聚焦、`Mod+Shift+1..5` 移动并跟随；删除 `Mod+c/b/n/w` 与 `Mod+Shift+c/b/n/w` 共 8 条绑定（`Mod+C/B/N/W` 现全部空闲）。
  3. `README.md`：新增**「鼠标操作」**（`fn`+左/右键拖拽 + 为何不用 `alt`）与**「配置验证」**两节；键位表工作区改 1..5；「与 AeroSpace 的差异」重写（说明弃用命名工作区的理由 + 释放的按键）；「实机踩到的坑」按新模型重排为 6 条。
  4. `tests/yabai_config_test.sh`：新增 python3 结构化校验——把 skhdrc 按「续行合并 → 首个 `:` 切分」解析成绑定表，与 31 条期望绑定**逐条比对**，并检查重复绑定、未登记的额外绑定、resize 链是否覆盖四个 fence、是否用 `2>/dev/null`、是否误用 `;`（skhd 的 `;` 是切模式）、十六进制 keycode 是否全大写；另断言焦点色/`ensure_spaces`/无标签/README 两个新节/`install.sh` 门控。解释器缺失时经 `resolve_python` 走 SKIP。
  5. `install.sh`：JankyBorders 提示改为 `command -v aerospace && ! command -v borders` 才打印（yabai 6.0+ 无内置边框、MacPorts 无 JankyBorders、本机也无 brew，原来的提示只会误导）。
  6. `tests/install_macos_test.sh`：抽出 `build_macos_sandbox`（可指定 stub 集合，默认不 stub `borders`），新增 `test_borders_hint_is_gated_on_aerospace`（有 aerospace 无 borders → 有提示；只有 yabai → 无提示）。
  7. `memory/desktop.md`：记录工作区模型与焦点色两个决策，把「踩坑」条目按新模型重写，并补「配置验证手段」一条。
- 验证：① **负向自测**（把测试内的 python 片段抠出，在配置副本上跑）——多一条未登记绑定 → `bindings not covered by the README/tests`；重复绑定 → `duplicate skhdrc binding`；`0x1b` 小写 → 被额外绑定检查拦下；删掉 resize 的 `2>/dev/null` → `failing attempts would spam the skhd log`；② `./tests/yabai_config_test.sh` PASS，`sh -n`（yabairc/两个测试）、`bash -n install.sh` 均 OK；③ live 复核：空间恒为 **5 且无标签**，`insert_feedback_color` = `0xff89b4fa`，规则 **5 条**（全浮动），`dock_did_restart` signal 在，两个进程均在，重启后 yabai err / skhd err **无新增**、out 只 +1 行 `yabai configuration loaded..`，微信仍 `is-floating:true`（`rule --apply` 生效）。
- live/提交：**已提交 `c4e41cb` 并推送 `origin/main`**。live 同步（目标已存在，先备份）：`~/.config/yabai/yabairc.backup.20260930_215333_090108000`、`~/.config/skhd/skhdrc.backup.20260930_215333_090108000`；清理旧配置遗留：清除 4/5/6/7 的陈旧标签，仅当窗口数为 0 时 `space --destroy` 掉 6、7（回到 5 个）。
- 回滚信息：**已提交 `c4e41cb`**；live 回滚：
  ```bash
  cp -p ~/.config/yabai/yabairc.backup.20260930_215333_090108000 ~/.config/yabai/yabairc
  cp -p ~/.config/skhd/skhdrc.backup.20260930_215333_090108000  ~/.config/skhd/skhdrc
  yabai --restart-service; skhd --restart-service
  # 被销毁的两个空空间与被清除的标签不自动恢复（都是空空间/元数据，无窗口损失）
  ```
- 后续可能方向：① 第二档功能绑定待用户挑（重载 WM、`--warp` 并入/移出、`--toggle split`、最小化）；② `Mod+C/B/N/W` 现已空闲，可考虑 launcher（niri/awesome 都用 `Mod+C`）；③ aerospace 的 JankyBorders `active_color` 仍是 mauve `0xffcba6f7`，未与仓库蓝对齐。

## 2026-09-30 — install.sh 部署 yabai/skhd 的 PATH 门控 bug（已修）+ live 被回退排查
- 目的：回答「当前 install 脚本会不会部署 yabai/skhd 配置」，并顺带排查为何 live 与仓库不一致。
- 发现 ①（真 bug，已修）：`~/.local/bin` 只由 `path.zsh` 加进 **zsh** 的 PATH，而 `install.sh` 跑在 **bash** 下且自己没补 PATH ⇒ 从 bash / 非交互 shell 启动时 `command -v yabai` 失败，`yabairc` 被**静默跳过**（只有一行 WARN）。同批被跳过的还有 `herdr` / `herdr-report` / `trae-cli`。修复：`install.sh` 顶部加 `export PATH="$HOME/.local/bin:$PATH"`（与 `path.zsh` 的「用户级优先」一致）。
  证据（假 HOME + 假 `$HOME/.local/bin/yabai` + PATH 不含该目录）：修复前 `[WARN] yabai not found; skipping its configuration` 且文件不存在；修复后 `Successfully copied file yabai -> …/yabairc` 且与仓库 identical（exit 0）。对照实验用剥掉该行的临时副本 `.prefix-check.sh` 复现（跑完即删，仓库无残留）。
  测试：`tests/install_macos_test.sh` 新增 `test_user_level_bin_is_on_the_gate_path`（yabai 只放 `$HOME/.local/bin`，断言仍部署）+ `tests/yabai_config_test.sh` 静态断言该 PATH 行。
- 发现 ②（告警，未处置）：live `~/.config/yabai/yabairc` 与 `yabairc.backup.20260930_215333_090108000` **逐字节相同**（21:24 的上一轮版本：mauve + `label_spaces` + 7 空间 + C/B/N/W），mtime 同为 `21:24:32` ⇒ 是 `cp -p`（保留 mtime）从 backup 拷回，而非 install.sh（`cp -a` 会带 21:52 的仓库 mtime）；运行时同步印证：焦点色 `0xffcba6f7`、7 空间、标签 `4=C 5=B 6=N 7=W`、规则 7 条、skhdrc 无 `Mod+5`。效果等于仓库文档里那条回滚命令（`cp -p <backup> …` + `yabai --restart-service`）。
  排查：仓库测试不可能造成（`install_backup_test.sh` 只 `source install.sh` 调 `clean_old_backups` 且跑临时目标；所有 install 测试用假 HOME；无测试调用 `yabai --restart-service`），shell history 无匹配记录 ⇒ 疑为人工/并发会话执行了回滚。**已向用户提问确认，未擅自改回 live。**
- 变更文件：`install.sh`、`tests/install_macos_test.sh`、`tests/yabai_config_test.sh`、`logs/trace.md`。
- 验证：`./tests/yabai_config_test.sh` PASS；`./tests/run.sh fast` = `PASS=41 FAIL=7 SKIP=1`（FAIL 集合与既有基线一致）；`sh -n` / `bash -n` / `git diff --check` OK；端到端部署实验如发现 ①。`tests/install_macos_test.sh` 在本机是平台 SKIP（要求 Linux），只有 `sh -n` 层面的检查。
- live/提交：live **未同步**（见发现 ②，等用户确认后再重新应用新版）；仓库改动已提交 `c4e41cb`（本行为提交后回填）。
- 回滚信息：**已提交 `c4e41cb`**；本轮只需 `git checkout -- install.sh tests/install_macos_test.sh tests/yabai_config_test.sh logs/trace.md` 即可丢弃（但与同任务其它改动同属一个 commit，整轮回滚见上条）。
- 后续可能方向：① 待用户确认 live 回退来源后，重新 `./install.sh`（附带真机验证该 PATH 修复）+ 清掉多出的 2 个空间与 4 个标签 + 重启；② `~/.npm-global/bin`、`~/.local/opt/node-current/bin` 等平台专属目录在 bash 下同样不在 PATH，install.sh 目前只补了共享的 `~/.local/bin`，需要时再扩。

## 2026-09-30 — live 重新应用新版 yabai 配置 + 清掉多余空空间（收尾）
- 目的：按用户「执行吧」完成上个条目的遗留项——把 live 从被回退的旧版恢复成仓库新版、清理旧配置遗留的空空间，并用真机验证 `install.sh` 的 PATH 修复。
- 执行前惊发现：live **已是新版且与仓库 `diff -q` identical** —— 是**用户在 22:16:47 自己跑过 `./install.sh`**：live 目录多出一对 `*.backup.20260930_221647_2477`，末尾 `_2477` 是 **PID 后缀**，正是 install.sh 的时间戳格式（`date +%Y%m%d_%H%M%S)_$$`；我手工同步用的是 `_<纳秒>`（9 位数字）⇒ **可据此区分 live 改动是 install.sh 还是手工同步**。运行时也已是新配置（焦点色 `0xff89b4fa`、规则 5 条），标签已清空，只剩 6/7 两个空空间（旧 `label_spaces` 建到 7 的遗留）。
- 已做（live/运行态）：
  1. **真机验证 PATH 修复**：`env -u PATH PATH="/usr/bin:/bin:/usr/sbin:/sbin" HOME=$HOME /bin/bash install.sh` → 输出 `[INFO] Skipping yabai: Target is identical to source`（修复前此处是 `[WARN] yabai not found; skipping its configuration`），且 **Backed up 次数 0、零改动**。注：该最小 PATH 同时排除了 `/opt/local/bin`，所以 skhd/tmux/nvim/starship 报 not found 是预期，本实验只用来隔离 `~/.local/bin` 这一项。
  2. 逐个确认窗口数后 `space --destroy` 掉空空间 7、6 → 空间回到 **5 个**（1/2/3 各有 1 个窗口：Chrome / 微信 / cmux；4/5 空）。
  3. `yabai --restart-service` + `skhd --restart-service`：空间恒 5、焦点色 `0xff89b4fa`、规则 5 条、`dock_did_restart` signal 在、微信 `is-floating=true`、yabai out 新增 1 行 `yabai configuration loaded..`、yabai err 无新增。
- 排查（重要）：`/tmp/skhd_rikoo.err.log` 里有一条 `skhd: could not open file '~/.config/skhd/skhdrc'`。再重启一次 skhd **新增 0 行** ⇒ 该错误是历史，时间点只能是 install.sh 备份+覆盖的那一瞬间：`copy_config` 先 `mv` 目标为 backup 再 `cp` 回来，文件短暂不存在，而 skhd 会监视配置文件并热重载。**不是配置损坏**，当前 skhd 已正常加载。
- 提交：本轮只有 live 与运行态变更，**仓库侧无改动**（trace 本条除外）；未提交。
- 回滚信息：本轮**无仓库改动需回滚**（trace 本条除外）。live 侧现为期望状态（5 个空间）不需回退；若要回到「7 空间 + C/B/N/W 标签」的旧模型，可 `cp -p ~/.config/yabai/yabairc.backup.20260930_215333_090108000 ~/.config/yabai/yabairc` + `cp -p ~/.config/skhd/skhdrc.backup.20260930_215333_090108000 ~/.config/skhd/skhdrc` 后重启（仍需手动把空间补回 7 个）。
- 后续可能方向：① `logs/trace.md` 已超 430 行，远超文件内建议的 ≤150 行，归档（`npm --prefix scripts run archive-trace`）仍未做；② trace 里 `c8e393f` 那条（他人 entry）仍写「未提交」，实际已提交，未擅自改；③ live 已与仓库一致，yabai/skhd 这套部署至此完整落地。
