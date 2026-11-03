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


## 2026-11-03 — 钉钉 desktop entry 局部注入 GTK_IM_MODULE=fcitx（修复 CEF 界面无法输入中文）

- 目的：解决钉钉内部分界面（Qt 搜索框正常，CEF 聊天框/内嵌文档无法唤起 fcitx5）无法输入中文的问题。
- 根因：钉钉保持 XWayland 模式（`QT_QPA_PLATFORM=xcb` / CEF 109 `ozone=x11`），Qt 控件走自带 `libfcitx5platforminputcontextplugin.so`（D-Bus），而 CEF 109 通过系统 `libgtk-3.so.0`（GDK X11 后端）创建 `GtkIMContext`。Wayland 会话全局清除 `GTK_IM_MODULE` 后，CEF 回退加载 `im-xim.so`（XIM 协议）。当 `xwayland-satellite` 0.8.3 在 `src/server/mod.rs:1610`（`create_popup` 对父窗口 `&SurfaceRole` 直接 `.unwrap()`，上游 issue #188 Open，`main` 未修）因钉钉 tooltip panic 重启后，niri 按需重拉 `:1` 但不通知 fcitx5 重连（`Disconnected from X11 Display :1`，`XIM_SERVERS` 丢失），导致 CEF 界面完全无法输入中文；同时 `im-xim.so` 还受 `fcitx5#1641` XIM sync 死锁影响。
- 改动（仓库，测试先行）：
  1. 新增 `.config/linux/desktop-entries/com.alibabainc.dingtalk.desktop`：`Exec=env GTK_IM_MODULE=fcitx /opt/apps/com.alibabainc.dingtalk/files/Elevator.sh %u`，让钉钉 CEF 加载 `im-fcitx5.so` 走 D-Bus，与 Qt 层统一，且不污染全局/systemd 环境。
  2. `install.sh`：`linux_wayland_configs` 新增 `com.alibabainc.dingtalk.desktop` 部署项。
  3. `tests/dingtalk_wayland_test.sh`、`tests/install_wayland_test.sh`、`tests/wayland_scripts_test.sh`：新增 desktop entry 存在性、`Exec=env GTK_IM_MODULE=fcitx ...` 及安装部署断言。
  4. `.config/linux/desktop-entries/README.md`、`.config/linux/niri/README.md`、`memory/dingtalk.md`：同步记录双通道机制与修复方案。
- 改动（live）：
  - 备份：`~/.local/share/applications/com.alibabainc.dingtalk.desktop.backup.20261103_113013`（同目标共 3 份 backup，无需清理）。
  - 同步：`.config/linux/desktop-entries/com.alibabainc.dingtalk.desktop` → `~/.local/share/applications/com.alibabainc.dingtalk.desktop`。
  - 运行态恢复：执行 `busctl --user call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 OpenX11Connection s ":1"`，`DISPLAY=:1 xprop -root XIM_SERVERS` 恢复为 `@server=fcitx`。
- 验证：`bash -n install.sh`、`sh -n tests/dingtalk_wayland_test.sh`、`sh -n tests/install_wayland_test.sh`、`sh -n tests/wayland_scripts_test.sh` OK；`sh tests/dingtalk_wayland_test.sh`、`sh tests/install_wayland_test.sh`、`sh tests/wayland_scripts_test.sh`、`sh tests/niri_config_test.sh`、`sh tests/repo_docs_test.sh` PASS；`git diff --check` OK。
- 运行态验证：调用 `OpenX11Connection(":1")` 后，GTK3 的 `im-xim.so` 通过 `XRegisterIMInstantiateCallback` 自动感知 `XIM_SERVERS` 重建了 `Group [x11::1]` 的 `frontend:xim` IC，用户确认无需重启钉钉已立即恢复中文输入；下次通过 `Mod+C` 重启钉钉后 CEF 将切换为加载 `im-fcitx5.so`（D-Bus）。
- 回滚信息：未提交（基线 commit `798f7a0`）。live 恢复命令（可直接复制执行）：
  ```bash
  cp ~/.local/share/applications/com.alibabainc.dingtalk.desktop.backup.20261103_113013 ~/.local/share/applications/com.alibabainc.dingtalk.desktop
  ```
  仓库回滚：`rm -f .config/linux/desktop-entries/com.alibabainc.dingtalk.desktop && git checkout -- install.sh .config/linux/desktop-entries/README.md .config/linux/niri/README.md memory/dingtalk.md tests/dingtalk_wayland_test.sh tests/install_wayland_test.sh tests/wayland_scripts_test.sh logs/trace.md`。


## 2026-10-29 — 修复 DMS+niri 启动时 Fcitx5 输入法变量通知竞态

- 目的：用户反馈每次全新重启进入 niri 后，DMS 都收到 Fcitx5“推荐取消设置 GTK_IM_MODULE/QT_IM_MODULE”的通知；确认不是旧进程残留。
- 根因：`/etc/profile.d/fcitx5.sh` 在 niri-session 导入前设置两个变量；DMS 的 `app-org.fcitx.Fcitx5@autostart.service` 与 niri 的 `spawn-sh-at-startup` 并行，Fcitx5 先启动并继承变量。核对 Fcitx5 5.1.23 上游 `waylandmodule.cpp::selfDiagnose()` 后确认通知读取 Fcitx5 自身进程环境，不是 systemd 当前环境。
- 改动（仓库，尚未同步 live）：
  1. 新增 `.config/linux/dms/niri.service.d/10-input-method.conf`：通过 `ExecStartPre` 在 niri 启动前清理 systemd 用户环境，并以 `UnsetEnvironment` 防止 niri 进程继承 GTK/Qt 旧式变量。
  2. `install.sh`：DMS 分支部署该 drop-in，内容变化时只执行 `systemctl --user daemon-reload`，不重启当前 niri 或 DMS；reload 失败时输出可直接执行的恢复命令，并明确说明重跑安装器不会自动重试。
  3. `.config/linux/dms/README.md`、`niri-repo.kdl`、`memory/niri.md`：同步启动顺序、验证和回滚说明，并区分输入法 drop-in 与原有 DMS 身份 drop-in 的重启行为。
  4. `tests/install_wayland_test.sh`：增加部署/非 DMS 不部署断言，以及仅输入法 drop-in 变更、reload 失败和手动恢复场景的回归测试。
- 验证：`bash -n install.sh`、`sh -n tests/install_wayland_test.sh` PASS；`sh tests/install_wayland_test.sh`、`sh tests/repo_docs_test.sh`、`sh tests/niri_config_test.sh`、`sh tests/waybar_config_test.sh`、`sh tests/wayland_scripts_test.sh`、`sh tests/dms_niri_setup_test.sh` PASS；`git diff --check` PASS。测试先验证失败场景，再补实现后通过。
- 本轮评审修复回滚锚点：已提交 `0cad84f`，进入本轮时已有未提交的输入法修复；如需仅撤销本轮修复，使用 `git revert 0cad84f` 会连同本条目一起回滚。后续可在用户授权后同步 live 并验证重新登录效果。
- 未做：未同步 live，未重启 niri/DMS，未验证下一次登录后的 Fcitx5 `/proc/<pid>/environ`。
- 已提交并推送：`0cad84f`（`origin/main`）；回滚：`git revert 0cad84f`。 `.config/linux/dms/niri.service.d/10-input-method.conf`，并回退 `install.sh`、`.config/linux/dms/README.md`、`.config/linux/dms/niri-repo.kdl`、`memory/niri.md`、`tests/install_wayland_test.sh` 的本轮改动。


## 2026-10-18 — Fedora 桌面双屏：DP-2 移到 AOC 正下方

- 目的：DP-2（BOE 0x0B17 笔记本屏，2560x1600@240 + scale 1.5 + VRR）此前只存在于 DMS 自动生成的 `dms/outputs.kdl`（右侧 x=1920），仓库权威 `fedora_x64/outputs.kdl` 未覆盖；用户要求改为放在 AOC 正下方并保持 240Hz + 1.5 缩放。
- 改动（仓库）：
  1. `.config/linux/niri/fedora_x64/outputs.kdl`：新增 `output "DP-2"`，`mode "2560x1600@240.000"`、`scale 1.5`、`position x=107 y=1080`（AOC 逻辑 1920 宽，BOE 逻辑 1706 宽，居中偏移 (1920-1706)/2=107，y 取 AOC 逻辑高 1080）、`variable-refresh-rate`；头部注释同步为双屏说明。仓库文件 include 在所有 `dms/*.kdl` 之前，first-match 覆盖 DMS 片段中的 DP-2。
  2. `tests/niri_config_test.sh`：`test_fedora_x64_outputs_match_this_pc_only` 增加 DP-2 的 mode/scale/position/VRR 断言。
  3. `.config/linux/niri/README.md`、`memory/niri.md`：Fedora 行从「单屏 DP-3」更新为双屏上下布局。
- 改动（live）：`~/.config/niri/outputs.kdl` 覆盖为仓库版本（备份见下）；niri 26.04 监视配置自动重载，未手动 reload。
- 验证：`niri validate -c ~/.config/niri/config.kdl` 通过；`niri msg outputs` 确认 DP-2 `Logical position: 107, 1080`、`2560x1600@240.000`、scale 1.5、VRR enabled，DP-3 保持 `0,0` scale 2；`tests/niri_config_test.sh`、`tests/install_wayland_test.sh`、`tests/dms_niri_setup_test.sh` PASS；`git diff --check` OK。
- 未验证：长时间使用下的鼠标跨屏手感；若想左对齐而非居中，把 DP-2 的 x 改为 0 即可。
- 提交：已提交 `e965560`（main，未推送）。
- 回滚：
  - live：`cp ~/.config/niri/outputs.kdl.backup.20261018_175911 ~/.config/niri/outputs.kdl`（niri 自动重载即恢复单屏仓库定义 + DMS 右侧 DP-2）。
  - 仓库：`git revert e965560`。


## 2026-10-17 — zsh 配置优化：brew 补全进 fpath、syntax-highlighting 延迟加载、死代码清理

- 目的：把"分析 zsh 配置"结论落地（用户选"1/2/4/5/8 全做 + live 残留清理"）。
- 已做（仓库，测试先行）：
  1. `.config/shared/zsh/plugins.zsh`：compinit 前把 Linuxbrew `/home/linuxbrew/.linuxbrew` 与 macOS Homebrew（`/opt/homebrew`、`/usr/local`）的 `share/zsh/site-functions` 按存在性 + `(Ie)` 去重加入 fpath——修掉 brew 装 CLI 全部无补全的缺陷（改前实测 `$fpath` 无 linuxbrew 条目，`_lsd`/`_bat`/`_brew`/`_codex` 未注册）；`zsh-syntax-highlighting` 改 `zinit ice wait lucid` 延迟加载（实测 ~50ms、占插件耗时 41%；它是最后一个包装 widget 的插件，延迟安全。fzf-tab / autosuggestions 保持同步：前者与 `zvm_after_init` 的 `enable-fzf-tab` 有顺序耦合且测试明确禁止延迟，后者参与每次按键渲染）。
  2. `.config/shared/zsh/zsh-syntax-highlighting-catppuccin-mocha.zsh`：开头补 `typeset -gA ZSH_HIGHLIGHT_STYLES`——延迟加载后主题文件先于插件执行，关联数组未声明时字符串下标赋值报 `assignment to invalid subscript range` 且样式全部失效（/tmp 副本实测复现后修复；插件加载时仅补未设置 key 的默认值，不覆盖主题）。
  3. `.config/shared/zsh/history.zsh`：删死代码 `HISTDUP=erase`（zsh 无此变量，tcsh `histdup` 残留，赋值被忽略）；`HISTSIZE` 10000→50000（SAVEHIST 跟随）。
  4. `.config/shared/zsh/path.zsh`：平台分支 `$(uname)` ×2 → zsh 内置 `$OSTYPE`（零 fork，与 env.zsh 同款写法）。
  5. `.config/shared/zsh/README.md`：删 `cat→bat` 漂移行（aliases.zsh 并无此别名）、"8 个插件"→"7 插件 + 4 OMZP snippet"、syntax-highlighting 标"延迟加载"、启动提速节三项→四项并补 brew fpath 小节。
  6. 测试：`tests/zsh_plugins_test.sh` 立即加载组移出 s-h 并补 autosuggestions 禁延迟守卫，新增 s-h 延迟、主题 `typeset -gA`、brew fpath 三组断言；`tests/zsh_history_test.sh` 新增 HISTDUP 死代码与 HISTSIZE=50000 断言；`tests/zsh_path_test.sh` 新增 `$OSTYPE` 断言（后两者只匹配非注释行，允许注释解释历史）。
- 验证：5 个 zsh 测试文件全 PASS；`tests/repo_docs_test.sh` PASS；`git diff --check` OK。/tmp 副本实测：`_comps[lsd]=_lsd`、`_comps[brew]=_brew`、主题 46 keys 生效、fpath 无重复、pty 实测延迟插件首个提示符后正常加载（`_zsh_highlight` 存在）；启动 0.20-0.22s → 0.14-0.15s（约 -30%）。
- 未验证：`./tests/run.sh fast` 未整跑（改动限 zsh 模块，相关测试已全跑）；高亮/配对在首提示符后 ~50ms 激活的权衡已写入 README，交由日常使用感知。
- live：已同步 4 个模块到 `~/.config/zsh/`（各自 `*.backup.20261017_132816`，旧 backup 按保留 3 份清理，pruned `path.zsh.backup.20260912_002741_3932`）；残留改名归档：`.p10k.zsh`（p10k 已弃用）、`.zcompdump.ubuntu.18364`（`compinit -d` 前的孤儿 dump）、`keybindings.zsh`（已并入 history.zsh）→ 各自 `*.backup.20261017_132816`；`~/.zshenv` 删冗余首行 `ZDOTDIR=~/.config/zsh`（未 export、被下行覆盖；守卫校验两条必需行在位后执行，用户显式确认，备份 `~/.zshenv.backup.20261017_132816`）。同步后 live 实测启动 0.14s，fpath/补全/主题/HISTSIZE 全部生效。
- 提交：已提交 `4916cd8`（main，已推送 `origin/main`），本条目与归档（14 条旧条目移入 `logs/trace-archive/2026-10.md`）同在该 commit。
- 回滚信息：commit `4916cd8`。仓库 `git revert 4916cd8`；live 恢复（可直接复制执行）：
  ```bash
  ts=20261017_132816
  cd ~/.config/zsh
  for f in plugins.zsh history.zsh path.zsh zsh-syntax-highlighting-catppuccin-mocha.zsh; do
      cp "$f.backup.$ts" "$f"
  done
  mv .p10k.zsh.backup.$ts .p10k.zsh
  mv .zcompdump.ubuntu.18364.backup.$ts .zcompdump.ubuntu.18364
  mv keybindings.zsh.backup.$ts keybindings.zsh
  cp ~/.zshenv.backup.$ts ~/.zshenv
  ```


## 2026-10-16 — tmux 外层标题补窗口序号（修掉"可区分"宣称落空）

- 目的：修掉 README / `memory/tmux.md` 宣称"外层终端标题可区分不同 tmux 窗口"但实测不成立的问题。
- 根因：`set-titles-string '#S · #W'` 只拼 session 名与窗口名；而 `allow-rename off` + `automatic-rename off`（`.tmux.conf:37-38`）让窗口名停在新窗口创建时的 shell 名。live 实测三个窗口名全是 `zsh`、session 名为 `0`，外层标题恒为 `0 · zsh`，niri 任务切换无法区分。
- 改动（仓库，先补断言再改配置）：
  1. `.config/shared/tmux/.tmux.conf`：`set-titles-string '#S · #W'` → `'#S · #I:#W'`（加窗口序号）。
  2. `.config/shared/tmux/README.md`：外层标题条目改写为 `session · 窗口序号:窗口名`（含"窗口名冻结"的原因说明）；快捷键表新增 `Ctrl+a + n` / `Ctrl+a + p` 行；表后段落补充 `n/p/q/z/d` 沿用内建绑定的说明。
  3. `tests/tmux_status_test.sh`：`test_keybinding_and_title_enhancements` 断言改为新串，并新增"旧串不存在"、"`automatic-rename off`"、README"窗口序号"三条守卫；`test_readme_documents_window_navigation` 新增 n/p 行与内建绑定说明两条断言。
- 未采纳（本轮评估后放弃）：① `tmux-tab-title` 的 `LC_ALL=C` 兜底（非 UTF-8 locale 下多字节截断会切出半个字符，实测可复现，但当前 tmux `#()` 环境是 `LANG=zh_CN.UTF-8`，无现实触发路径）；② `status-interval` 由 15 降到 5（tab 标签 `cd` 后最多滞后 15s，实测脚本每轮 3 窗口约 50ms、可忽略，但需用户现场观察后再定）。③ 脚本微优化（`strlen` 改 `${#}` 等，合计省约 5ms/窗口，且会触碰 `9e6a785` 刻意加的 `assert_not_contains 'pane_current_command'` 守卫）——收益小于风险，明确不动。
- 改动（live）：**未同步**。`~/.tmux.conf` 在沙箱保护路径内，写入会被静默拦截（退出码 0 但文件不变，见 `memory/tmux.md` 的 Live 同步条），故本轮只改仓库，同步命令交给用户手动执行。
- 验证：`tmux display-message -p '#S · #I:#W'` → `0 · 1:zsh` / `0 · 2:zsh` / `0 · 3:zsh`（格式可区分）；`tmux source-file -n .config/shared/tmux/.tmux.conf` OK；`sh -n tests/tmux_status_test.sh` OK；`./tests/tmux_status_test.sh` PASS；`./tests/repo_docs_test.sh` PASS；`git diff --check` OK。
- 未验证：真机外层终端标题（foot / alacritty 窗口标题、niri 任务切换）需同步 live 并新开窗口后肉眼确认。
- 已提交：`40fe273`（`main`，已推送 `origin/main`）。上一基线 `57842b4`。
- 回滚：`git revert 40fe273`（保留历史）；若要退回提交前状态，`git checkout 57842b4 -- .config/shared/tmux/.tmux.conf .config/shared/tmux/README.md tests/tmux_status_test.sh memory/tmux.md logs/trace.md`。
- live 同步命令（待用户执行，`!` 前缀可直接在本会话跑）：
  ```bash
  cd /data/rikoo/Documents/study/dotfiles
  ts=$(date +%Y%m%d_%H%M%S)
  cp -p ~/.tmux.conf ~/.tmux.conf.backup.$ts
  cp .config/shared/tmux/.tmux.conf ~/.tmux.conf
  echo "回滚: cp ~/.tmux.conf.backup.$ts ~/.tmux.conf && tmux source-file ~/.tmux.conf"
  ls -1t ~/.tmux.conf.backup.* 2>/dev/null   # 按 install.sh 惯例保留最近 3 份，更早的手动删除
  ```
- 后续：同步 live 后需新开窗口才会写新的外层标题（已 attach 的客户端下一次重绘即生效）；`logs/trace-archive/2026-08.md` 中旧记录（⑦ `session · window`）为历史存档，按惯例不改写。
