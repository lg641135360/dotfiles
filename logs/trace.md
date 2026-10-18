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


## 2026-10-15 — 同时清除 systemd 用户环境中的 QT_IM_MODULE（fcitx5 提示复发）

- 目的：消除 fcitx5 5.1.23 弹出的"检测到设置了 GTK_IM_MODULE 和 QT_IM_MODULE … 推荐不设置"提示（用户描述为"只设一个变量就行"——即 Wayland 下只留 `XMODIFIERS`，GTK/Qt 走 text-input-v3）。
- 根因：与 2026-10-11 那次同源。`/etc/profile.d/fcitx5.sh`（Fedora `fcitx5-autostart` 包）在登录时 export 全部 4 个变量（`INPUT_METHOD`/`GTK_IM_MODULE`/`QT_IM_MODULE`/`XMODIFIERS`），niri-session 的 `import-environment` 把它们带入 systemd 用户会话。上一轮只清了 `GTK_IM_MODULE`，`QT_IM_MODULE=fcitx` 残留，触发本轮提示。
- 改动（仓库，测试先红后绿）：
  1. `.config/linux/dms/niri-repo.kdl`：`spawn-sh-at-startup` 的 `unset-environment` 扩展为 `GTK_IM_MODULE QT_IM_MODULE`（一行两变量）。
  2. `.config/scripts/wayland-autostart`：`unset GTK_IM_MODULE QT_IM_MODULE`；`systemctl --user unset-environment GTK_IM_MODULE QT_IM_MODULE`；注释同步说明。
  3. `tests/niri_config_test.sh`：原 `test_dms_fragment_unsets_gtk_im_module_from_systemd_env` 改名 `test_dms_fragment_unsets_im_modules_from_systemd_env`，断言一行两变量。
  4. `tests/wayland_scripts_test.sh`：断言 `unset GTK_IM_MODULE QT_IM_MODULE` 与 `unset-environment GTK_IM_MODULE QT_IM_MODULE` 两条。
  5. `memory/niri.md`："Wayland 输入法变量"条目更新为"GTK/Qt 都走 text-input-v3，只留 XMODIFIERS 给 XWayland/XIM"。
- 未改动：`.config/linux/x11/xsessionrc` 与 `rofi-launch` 中的 `GTK_IM_MODULE=fcitx` / `QT_IM_MODULE=fcitx`——X11/Awesome 会话仍需要这些变量，fcitx5 的提示只针对 Wayland。
- 改动（live）：
  - 备份：`~/.config/niri/niri-repo.kdl.backup.20261015_092243`、`~/.config/scripts/wayland-autostart.backup.20261015_092243`。
  - 仓库版本覆盖 live；`chmod +x wayland-autostart`；`niri validate -c ~/.config/niri/config.kdl` OK。
  - 当前会话执行 `systemctl --user unset-environment QT_IM_MODULE GTK_IM_MODULE`；`systemctl --user show-environment` 仅剩 `INPUT_METHOD=fcitx` 与 `XMODIFIERS=@im=fcitx`。
  - 老备份按保留 3 份清理：删除 `niri-repo.kdl.backup.20261011_084554` 与 `niri-repo.kdl.backup.20261011_082826`。
- 验证：`sh -n .config/scripts/wayland-autostart` OK；`niri validate -c .config/linux/dms/niri-repo.kdl` OK；`sh tests/niri_config_test.sh` PASS；`sh tests/wayland_scripts_test.sh` PASS；`./tests/run.sh fast` PASS=52 FAIL=0 SKIP=1；`git diff --check` OK。
- 运行态验证（同日 09:30 补做）：`fcitx5 -d --replace` 重启（旧 PID 4418 → 新 PID 98964），`fcitx5-remote -n` 返回 `keyboard-us`；`waylandim` addon 加载，`Using Wayland native input method protocol: 1`；`dbus-monitor` 抓 12 秒桌面通知共 0 条，**Wayland 提示未再弹**。顺带实证：fcitx5 的提示判定**只读 systemd 用户环境、不读自身进程 env**——新 fcitx5 进程因从 Trae 终端 fork 仍带着 `GTK_IM_MODULE=fcitx QT_IM_MODULE=fcitx`（self diagnose 已打印），但只要 systemd 用户环境干净就不发提示。
- 未提交。
- 回滚：
  ```bash
  cp ~/.config/niri/niri-repo.kdl.backup.20261015_092243 ~/.config/niri/niri-repo.kdl
  cp ~/.config/scripts/wayland-autostart.backup.20261015_092243 ~/.config/scripts/wayland-autostart
  chmod +x ~/.config/scripts/wayland-autostart
  niri validate -c ~/.config/niri/config.kdl
  ```
  仓库：`git checkout -- .config/linux/dms/niri-repo.kdl .config/scripts/wayland-autostart tests/niri_config_test.sh tests/wayland_scripts_test.sh memory/niri.md logs/trace.md`（会丢失这些文件中本轮之前的未提交改动，请先确认）。
- 后续：下次登录 niri 时 `niri-repo.kdl` 的 `spawn-sh-at-startup` 会再次从 systemd 用户环境清掉两个变量（`/etc/profile.d/fcitx5.sh` 每次登录都会重新注入），提示不应复发。若复发，排查路径见 `memory/niri.md` 排障入口"fcitx/GTK"。


## 2026-10-11 — install.sh 配套 GNOME 代理设置（gsettings）

- 目的：`environment.d` 只覆盖终端与命令行，GNOME 原生应用与 Chrome 依赖 gsettings 中的系统代理；此前这部分只存在于 live 手动设置，未入库。
- 改动（仓库）：
  1. `install.sh`：新增 `apply_gnome_proxy_settings`，在 `deploy_fedora_proxy_environment` 中调用，写入 `mode manual`、`http`/`https` 的 host 与 port、`ignore-hosts`。使用与 `proxy_env` 相同的 `PROXY_HOST`/`PROXY_PORT`。`gsettings` 缺失或写入失败只警告。
  2. `tests/install_wayland_test.sh`：新增 `test_install_applies_gnome_proxy_settings_from_proxy_env`（假 gsettings 记录调用，断言 6 条设置）与 `test_install_skips_gnome_proxy_without_proxy_env_file`。
  3. `.config/linux/dms/README.md`：补充 gsettings 写入的说明。
- 改动（live）：无。live 中 gsettings 已是 `manual`、`<PROXY_HOST>:7890`，与 `proxy_env` 一致；本轮不重新写入。
- 验证：`bash tests/install_wayland_test.sh` PASS；`tests/niri_config_test.sh` PASS；`tests/dms_niri_setup_test.sh` PASS；`./tests/run.sh fast` PASS=52 FAIL=0 SKIP=1；`git diff --check` OK。
- 未验证：未在真机运行 `install.sh` 写入 gsettings（沙箱使用假 gsettings）。
- 未提交。
- 回滚：`git checkout -- install.sh tests/install_wayland_test.sh .config/linux/dms/README.md logs/trace.md`（会丢失这些文件中本轮之前的未提交改动，请先确认）；live gsettings 回滚为 `gsettings set org.gnome.system.proxy mode 'none'`（如需）。


## 2026-10-11 — install.sh 优化（高/中/低优先级）

- 目的：按《install.sh 处理逻辑梳理》中的建议优化 DMS 分支与代理部署，提高可读性并补齐校验。
- 改动（仓库，`install.sh`）：
  1. 高：新增 `deploy_dms_service_drop_in`，用 `cmp -s` 判断内容是否变化，变化才 `daemon-reload` 与 `restart dms`；替代原来的 `$(< file)` 比较。
  2. 高：drop-in 逻辑从 `main()` 抽出为函数。
  3. 中：新增 `render_template`，`deploy_fedora_proxy_environment` 复用它做占位符替换。
  4. 中：`PROXY_PORT`、`SOCKS_PORT` 必须为数字，否则警告并跳过。
  5. 低：`log_warn` 计数，结尾汇总 `Installation completed with N warning(s)`。
  6. 第 4 条（备份清理）经检查 `clean_old_backups` 按目标文件名统计，`environment.d` 的备份已覆盖，无需改代码。
- 改动（测试，`tests/install_wayland_test.sh`）：
  - 新增 `test_install_rejects_non_numeric_proxy_port`、`test_proxy_env_template_has_no_unrendered_placeholders_after_install`、`test_install_summarizes_warnings_at_end`。
  - drop-in 测试的沙箱额外链接 `cmp`（`install_extra_cmds`）。
  - 验证“强制判定为变化”时 `test_install_restarts_dms_only_when_drop_in_changes` 会失败，恢复后通过。
- 改动（live）：无。
- 验证：`bash tests/install_wayland_test.sh` PASS；`tests/niri_config_test.sh`（bash 与 sh）PASS；`tests/dms_niri_setup_test.sh` PASS；`tests/zsh_path_test.sh` PASS；`./tests/run.sh fast` PASS=52 FAIL=0 SKIP=1；`bash -n install.sh` 通过；`git diff --check` OK；沙箱完整运行 `install.sh` 退出码 0。
- 未验证：shellcheck 未安装，未做静态检查；未在真机运行 `install.sh`。
- 未提交。
- 回滚：`git checkout -- install.sh tests/install_wayland_test.sh logs/trace.md`（会丢失这些文件中本轮之前的未提交改动，请先确认）。


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
