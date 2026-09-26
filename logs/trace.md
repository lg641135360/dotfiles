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
