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
- live/提交：未同步 live，未提交；回滚信息：工作区未提交。

## 2026-09-11 环境变量收敛（收尾）
- 目的：进一步收敛——删除 `ensure_fcitx_environment` 与 `environment.d` 注入。分析确认正常登录路径下 fcitx 变量由 im-config 写入 `/etc/environment`，经 niri-session 的 `import-environment`（无参数）进入 systemd 用户环境，仓库侧不再需要任何 fcitx 变量注入点。
- 已做：`install.sh` 删除 `ensure_fcitx_environment()` 函数与其在 `main()` 的调用；`.config/scripts/wayland-autostart` 的 dbus/systemd 同步列表删除 `QT_IM_MODULE XMODIFIERS`（保留 XDG 会话标识同步与 `unset-environment GTK_IM_MODULE`）；`.config/linux/niri/README.md` 环境变量小节重写为当前实现（fcitx 变量走 `/etc/environment` + niri-session 注入，`environment {}` 仅保留 `XCURSOR_SIZE` 与会话标识，`ZDOTDIR` 由安装器写 `~/.zshenv`）。
- 验证：`bash -n`、`git diff --check` 通过；`tests/niri_config_test.sh`、`tests/install_zshenv_test.sh` 通过。
- 遗留失败（非本轮引入，需用户决策）：
  - `tests/install_wayland_test.sh`：`is_repo_niri_platform` 收紧为 ubuntu+aarch64 后，测试 6 个场景仍用 x86_64/arch/fedora mock，断言 niri 文件应部署不再成立；与 README「Ubuntu x86_64 / aarch64 部署」描述矛盾，疑似上轮误改，需回退收紧或同步改测试+README。
  - `tests/wayland_scripts_test.sh` 的 `test_launcher_wayland_respects_running_wayland_fcitx5` 场景1：`git stash` 后 HEAD 版通过、工作区版失败；HEAD 与工作区 launcher 唯一差异是删除的 6 行 fcitx exports（逻辑上不影响 fcitx5 存活检测），疑为 `/proc/<pid>/environ` 读取的测试环境敏感问题（Yama ptrace_scope / 容器），待确认。
- live/提交：未同步 live，未提交；回滚信息：工作区未提交。

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
- live/提交：未同步 live（本轮只改仓库部署逻辑，live DMS 配置已是目标态，无需动）；未提交；回滚信息：工作区未提交（连同 2026-09-11 环境变量收敛轮，建议分两个 commit）。
- 后续可能方向：① 工作区另有 2026-09-11 环境变量收敛轮未提交，提交时先提交该轮再提交本轮；② DMS 键位未含仓库肌肉记忆键（Mod+hjkl 等）且 Mod+T spawn 未安装的 ghostty，待用户在 DMS 设置内调整；③ waybar/wayland-autostart 链的仓库清理（或保留为 aarch64 回退）待 DMS 稳定使用后决策；④ `memory/niri.md` 2026-08-29 包来源条目「不装 dms」已成历史，随下轮 memory 整理更新。

## 2026-09-12 foot 目录改单文件部署（保留第三方文件）
- 目的：规避整目录复制把 live `~/.config/foot` 中 DMS 放入的 `dank-colors.ini` 归档/替换掉的问题；用户决策：仅 foot 改逐文件部署，其它目录部署（git/nvim/awesome/mako/fuzzel/swaylock）保持整目录替换不变。
- 已做：
  - `install.sh`：`linux_wayland_terminal_dir_configs`（整目录）改为 `linux_wayland_terminal_configs` 逐文件数组（`foot.ini` + `README.md`），`main()` 对应调用更新；块1 任何 niri 机器部署不变。
  - `tests/install_wayland_test.sh`：静态断言改为逐文件条目；DMS 用例预置 `~/.config/foot/dank-colors.ini` 并断言安装后保留 + `foot.ini` 部署。
  - `tests/foot_config_test.sh`：install 行断言同步。
  - 文档：`README.md` 安装说明、`.config/linux/niri/README.md` 部署边界段、`memory/niri.md` 部署段补充 foot 单文件部署说明。
- 验证：`bash -n`、`tests/install_wayland_test.sh`、`tests/foot_config_test.sh`、`tests/install_submodule_test.sh` 通过；`./tests/run.sh fast` PASS=46 FAIL=0。
- live/提交：未同步 live、未提交；回滚信息：工作区未提交（与 2026-09-11/12 各轮同处工作区，建议分 commit）。
- 后续可能方向：① 若 DMS 的 `dank-colors.ini` 需要纳入仓库配色，可后续引入；② 其它目录若也出现第三方文件冲突，可评估通用合并部署。
