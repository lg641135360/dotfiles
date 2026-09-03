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

## 2026-09-03 — zoxide 补全改包装、关闭 autocd、清理 live 死文件

- 目的：收维护债。① zoxide 补全不要整函数复制；② live 残留不加载的 keybindings/p10k/旧主题；③ 关掉极少用的 `setopt autocd`。
- 改动：`integrations.zsh` 备份官方 `__zoxide_z_complete` 为 `_zoxide_z_complete_orig`，仅在「cd + 一个词」时本地 `_cd` 无匹配才 `query --list`，其余走 orig。`options.zsh` 去掉 `setopt autocd`。live 删除 `keybindings.zsh`、`.p10k.zsh`、两份 tokyonight 主题（先 backup）。README 与 tests 同步。
- 验证：`zsh_functions_test.sh` / `zsh_plugins_test.sh` / `zsh_history_test.sh` PASS。live：`autocd=off`，`_zoxide_z_complete_orig` 存在，`_comps[cd]=__zoxide_z_complete`。
- 回滚信息：本轮 commit（见 `git log -1`，未推送）。live 同步备份时间戳 `20260903_152406_891525015`。恢复命令：
  ```bash
  cp ~/.config/zsh/integrations.zsh.backup.20260903_152406_891525015 ~/.config/zsh/integrations.zsh
  cp ~/.config/zsh/options.zsh.backup.20260903_152406_891525015 ~/.config/zsh/options.zsh
  cp ~/.config/zsh/keybindings.zsh.backup.20260903_152406_891525015 ~/.config/zsh/keybindings.zsh
  cp ~/.config/zsh/.p10k.zsh.backup.20260903_152406_891525015 ~/.config/zsh/.p10k.zsh
  cp ~/.config/zsh/zsh-syntax-highlighting-tokyonight.zsh.backup.20260903_152406_891525015 ~/.config/zsh/zsh-syntax-highlighting-tokyonight.zsh
  cp ~/.config/zsh/zsh-syntax-highlightin-tokyonight.zsh.backup.20260903_152406_891525015 ~/.config/zsh/zsh-syntax-highlightin-tokyonight.zsh
  ```
- 后续：新开 foot 窗口生效。敲目录名不会再自动 cd，需 `cd` 或 zoxide。死文件已不加载，恢复它们也不会改变行为，除非重新 source。

## 2026-09-03 — fzf 别名改名、fd 接 Ctrl-T、fzf-tab zstyle、关闭 correct

- 目的：收掉「完美」清单里的 2–4 和 6：`alias fzf=` 污染集成路径；`Ctrl+T` 未接 `fd`；fzf-tab 缺少推荐 zstyle；`setopt correct` 和补全抢注意力。
- 改动：① `aliases.zsh` 改为 `fzfp`，`preview()` 走 `command fzf`；② `env.zsh` 在 `fd` 存在时设 `FZF_CTRL_T_COMMAND` / `FZF_ALT_C_COMMAND`（当前机器未装 fd，保持 unset）；③ `plugins.zsh` 增加 git-checkout 不排序、`menu no`、`cd` 用 `lsd` 预览，并因不再 alias `fzf` 而改回 `source <(fzf --zsh)`；④ `options.zsh` 去掉 `setopt correct`。README 与 `tests/zsh_plugins_test.sh` 同步。
- 验证：`sh tests/zsh_plugins_test.sh` PASS；`zsh_history` / `zsh_functions` / `zsh_path` PASS（path 三项 SKIP 为目录不存在）。live `zvm_init`：Tab=`fzf-tab-complete`，`fzfp` 别名存在，`alias fzf` 无，`correct=off`，`FZF_CTRL_T_COMMAND` unset。
- 回滚信息：本轮 commit（见 `git log -1`，未推送）。live 已同步（备份时间戳 `20260903_144840_195949302`）。恢复命令：
  ```bash
  cp ~/.config/zsh/plugins.zsh.backup.20260903_144840_195949302 ~/.config/zsh/plugins.zsh
  cp ~/.config/zsh/env.zsh.backup.20260903_144840_195949302 ~/.config/zsh/env.zsh
  cp ~/.config/zsh/aliases.zsh.backup.20260903_144840_195949302 ~/.config/zsh/aliases.zsh
  cp ~/.config/zsh/options.zsh.backup.20260903_144840_195949302 ~/.config/zsh/options.zsh
  ```
- 后续：新开 foot 窗口生效。带预览搜索改敲 `fzfp`。`Ctrl+T` 要用 `fd` 需先 `brew install fd`。locale 警告仍需本机 `locale-gen`。

## 2026-09-03 — cd Tab 在本地无匹配时回落到 zoxide 历史

- 目的：`cd ss` 按 Tab 仍无补全。根因是 `zoxide init --cmd cd` 的 `__zoxide_z_complete` 对「cd + 一个词」只跑 `_cd -/`（当前目录）；本地没有 `ss*` 时直接 return 0，fzf-tab 拿不到候选。zoxide 历史只在 `cd ss `（末尾空格）再 Tab 时走 `--interactive`。
- 改动：`integrations.zsh` 在 zoxide init 之后覆盖 `__zoxide_z_complete`：本地 `_cd -/` 有匹配则用本地；否则 `zoxide query --list`，`compadd` 给 fzf-tab。空格后再 Tab 仍走 zoxide 交互选择。README 与 `tests/zsh_functions_test.sh` 同步。
- 验证：`sh tests/zsh_functions_test.sh` PASS；live 加载后 `_comps[cd]=__zoxide_z_complete` 且函数含 `--list`。未在真实 TTY 里按 Tab 冒烟（zle 仅在交互行编辑中可用）。
- 回滚信息：本轮 commit（见 `git log -1`，未推送）。live 已同步 `~/.config/zsh/integrations.zsh`（备份 `integrations.zsh.backup.20260903_140217_662706658`）。恢复命令：
  ```bash
  cp ~/.config/zsh/integrations.zsh.backup.20260903_140217_662706658 ~/.config/zsh/integrations.zsh
  ```
- 后续：必须新开 foot 窗口；`cd ss` + Tab 应列出 zoxide 库里匹配 `ss` 的目录（当前库里是 `.../zsh-autopair`）。当前目录若已有 `ss*` 仍优先本地。

## 2026-09-03 — 修复 zsh Tab 补全被 fzf --zsh / zsh-vi-mode 抢走

- 目的：foot 新开 zsh 按 Tab 无菜单、无反应。根因是 `fzf-tab` 在 `compinit` 之前加载，随后 `env.zsh` 的 `source <(fzf --zsh)` 把 Tab 绑成只认 `**` 的 `fzf-completion`，`zsh-vi-mode` 首次提示符再 `bindkey -v` 覆盖先前绑定；`aliases.zsh` 的 `fzf --preview` 别名还会让裸 `fzf --zsh` 失败。
- 改动：① `plugins.zsh` 把 `fzf-tab` 挪到 `compinit` 之后、autosuggestions/syntax-highlighting 之前；② `zvm_after_init` 用 `whence -p fzf` 加载 `--zsh`，再 `enable-fzf-tab` 把 Tab 抢回，并 `zstyle ':fzf-tab:*' fzf-command` 指向真实二进制；③ `env.zsh` 不再提前 source `fzf --zsh`；④ README 与 `tests/zsh_plugins_test.sh` 同步加载顺序断言。
- 验证：`sh tests/zsh_plugins_test.sh` PASS；`sh tests/zsh_history_test.sh` / `zsh_functions_test.sh` / `zsh_path_test.sh` PASS（path 三项 SKIP 为目录不存在）；`git diff --check` 干净。隔离 `ZDOTDIR` 与 live 同步后 `zvm_init`：viins/emacs/main 的 `^I` 均为 `fzf-tab-complete`，`^R`/`^T` 为 fzf widget，`fzf_default_completion=expand-or-complete`。
- 回滚信息：本轮 commit（见 `git log -1`，未推送）。live 已同步（备份时间戳 `20260903_115416_514571439`）。恢复命令：
  ```bash
  cp ~/.config/zsh/plugins.zsh.backup.20260903_115416_514571439 ~/.config/zsh/plugins.zsh
  cp ~/.config/zsh/env.zsh.backup.20260903_115416_514571439 ~/.config/zsh/env.zsh
  cp ~/.config/zsh/.zshrc.backup.20260903_115416_514571439 ~/.config/zsh/.zshrc
  ```
- 后续：已打开的 zsh 需新开窗口才加载新配置；在 foot 输入 `ls ` 再按 Tab 应弹出 fzf-tab 菜单。Grok 输入框的 Tab 仍是切焦点，与本次无关。

## 2026-09-02 — Obsidian 迁移 deb 后修复 fuzzel 双入口与启动失效

- 目的：fuzzel 出现两个 Obsidian 入口（系统 `md.obsidian.Obsidian.desktop` + 自建 `obsidian.desktop`）；且上午清理 AppImage 后，自建入口的 `obsidian-wayland` 仍指向已删除的 `~/Applications/Obsidian-*.AppImage`（exit 127），系统入口裸 exec `/opt/Obsidian/obsidian` 在 niri 下因 Vulkan 与 Wayland surface factory 不兼容而启动即退出（均实测复现）。
- 改动：① `.config/scripts/obsidian-wayland` 重写为 deb 版入口：Wayland 会话 `exec /opt/Obsidian/obsidian --ozone-platform=wayland --enable-wayland-ime --disable-vulkan`（`--disable-vulkan` 必需否则不弹窗；新 Chromium 默认 text-input v3，去掉旧 `--wayland-text-input-version=3`），X11 透传；② `desktop-entries/obsidian.desktop` 更新注释、`StartupWMClass` 改为 `md.obsidian.Obsidian`（对齐实测 WM class）；③ `tests/wayland_scripts_test.sh` 重写 obsidian 用例为 `test_obsidian_wayland_forces_native_wayland_gl`；④ 文档：`desktop-entries/README.md` 收录补 obsidian、`niri/README.md` Obsidian 段改 deb、`memory/desktop.md` text-input 矩阵与落地记录更新。
- 验证：`bash -n .config/scripts/obsidian-wayland` OK；`bash tests/wayland_scripts_test.sh` PASS；`./tests/run.sh fast` PASS=46 FAIL=0 SKIP=0；`git diff --check` 干净；实测 `/opt/Obsidian/obsidian --ozone-platform=wayland --enable-wayland-ime --disable-vulkan` 出窗口（niri App ID `md.obsidian.Obsidian`），裸 exec 与旧 wrapper 均失败。
- 回滚信息：未提交；live 已同步桌面入口 `~/.local/share/applications/obsidian.desktop`（备份 `obsidian.desktop.backup.20260902_104905_3745355`），脚本 `~/.config/scripts/obsidian-wayland` 因沙箱限制未同步。恢复命令：
  ```bash
  cp ~/.local/share/applications/obsidian.desktop.backup.20260902_104905_3745355 ~/.local/share/applications/obsidian.desktop
  ```
- 后续：live 侧 `~/.config/scripts/obsidian-wayland` 仍是旧 AppImage 版（失效），需用户执行脚本同步命令（见收尾总结）；fuzzel 双入口去重已落地——新增 `.config/linux/desktop-entries/md.obsidian.Obsidian.desktop`（内容仅 `Hidden=true`）隐藏系统入口，同步 live `~/.local/share/applications/md.obsidian.Obsidian.desktop`（原无此文件，无需备份），并接入 install.sh 与 install_wayland_test.sh 断言。

## 2026-09-02 — 锁屏回退 swaylock，整体移除 gtklock 模块

- 目的：用户决策锁屏回退 swaylock 简单版，放弃 gtklock 方案（2026-08-31 迁入的时钟/日期 + Mocha CSS 主题），并彻底移除 gtklock 模块痕迹。
- 改动：① `lock-wayland` 删除 gtklock 优先分支（`lock_with_gtklock()` 与 `command -v gtklock` 分发），直接用 swaylock 分支；② 删除 `.config/linux/gtklock/{README.md,config.ini,style.css}` 与 `tests/gtklock_config_test.sh`；③ `install.sh` `linux_wayland_dir_configs` 移除 gtklock 部署项；④ 测试：`wayland_scripts_test.sh` 删两条 gtklock 相关测试（prefers_gtklock / falls_back_without_gtklock）与 `test_launcher_and_lock_have_wayland_first_fallbacks` 内 4 条断言、`install_wayland_test.sh` 删 gtklock 部署断言、`repo_docs_test.sh` 删 gtklock README 存在断言；⑤ 文档：`.config/scripts/README.md` 锁屏描述、`.config/linux/niri/README.md` 快捷键表 + 锁屏段、`memory/niri.md` 锁屏决策改为回退 swaylock。
- 验证：`sh -n .config/scripts/lock-wayland` OK；`bash tests/wayland_scripts_test.sh`、`swaylock_config_test.sh`、`install_wayland_test.sh`、`repo_docs_test.sh` 均 PASS；`./tests/run.sh fast` PASS=46 FAIL=0 SKIP=0；`git diff --check` 干净。全仓库 grep 无功能代码残留 gtklock（仅 trace 历史、memory/niri.md 与 niri README 的回退说明）。
- 回滚信息：未提交；未同步 live。若需回滚到 gtklock 方案：`git revert <本轮 commit>`（提交后）即恢复 lock-wayland/install.sh/测试，再恢复 `.config/linux/gtklock/` 与 `tests/gtklock_config_test.sh`（0b0d049 引入，可从该 commit 检出）。
- 后续：若 live 侧 `~/.config/scripts/lock-wayland` 仍是 gtklock 版或 `~/.config/gtklock/` 存在，重跑 `./install.sh` 即回退（install.sh 自动备份 `~/.config/gtklock`）；apt 的 gtklock 包是否卸载由用户决定。

## 2026-09-02 — 解决 main 变基冲突（memory/niri.md 键位段合并）

- 目的：main 在变基到 origin/main（6f661ff）时 `memory/niri.md` 键位段冲突（UU）。
- 改动：按实际 `common.kdl` 事实合并双方——保留 HEAD 侧最新的「`Mod+Ctrl+F` 复用于 `toggle-window-floating`（2026-09-01）」表述，并入 bef5e89 侧新增的 `Mod+grave`（focus-workspace-previous）、`Mod+Shift+N`（mako 免打扰）、`repeat-delay 300`/`repeat-rate 40` 三条；原 bef5e89 侧「`Mod+Ctrl+F` 已释放」为旧状态，弃用。无其它冲突文件。
- 验证：`grep '^(<<<<<<<|=======|>>>>>>>)' memory/niri.md` 无匹配；`GIT_EDITOR=true git rebase --continue` 成功，rebase 完成；`git log --oneline -1` 为新提交 52826ea，`git status` 干净。
- 回滚信息：52826ea（rebase 产出，HEAD 指向该提交）；未同步 live。main 领先 origin/main 1，是否推送由用户决定。

## 2026-09-01 — gtklock 双屏输入表单定位（monitor-priority + follow-focus）

- 目的：修复"锁屏后必须挪鼠标到副屏才能输密码"——gtklock 输入框只显示在一块屏上（落在副屏 HDMI-A-2），niri 锁屏键盘焦点跟随指针（常在主屏 DP-1），按键落空。
- 改动：`gtklock/config.ini` 新增 `monitor-priority=DP-1;eDP-1`（x64 钉主屏，aarch64 无 DP-1 落 eDP-1）+ `follow-focus=true`（表单跟指针，niri 异常则删）。**关键排坑**：glib key file 同名 key 重复写只保留最后一条（python3 GLib 实测 + gtklock `src/config.c` 用 `g_key_file_get_string_list` 证实），man 页"可多次指定"仅指命令行 `-M`，故必须用单行 `;` 列表。`tests/gtklock_config_test.sh` 新增 `test_gtklock_monitor_priority_is_single_line_list`（含"恰好一行"计数断言）；gtklock README、`memory/niri.md` 同步。
- 验证：`bash tests/gtklock_config_test.sh` PASS；python3 GLib 按 gtklock 同一代码路径解析实际 config.ini，`monitor-priority` 读出 `['DP-1','eDP-1']`、`follow-focus` 读出 True。未触发实际锁屏（属告警操作，留用户实测：锁屏后指针在任意屏应可直接输密码）。
- 回滚信息：未提交（并入当日未提交批次）；未同步 live。同步走 `./install.sh`（自动备份 `~/.config/gtklock`）。

## 2026-09-01 — Chrome PiP 浮动规则补中文标题匹配（画中画）

- 目的：当日六项优化中的 Chrome PiP 规则 `title=r#"^Picture in picture$"#` 在本机 zh_CN 环境（Chrome 跟随系统 locale、无 app_locale 覆盖）下永远匹配不到——中文 UI 的 PiP 窗口标题为「画中画」（`aerospace.toml` 的 `(Picture-in-Picture|画中画)` 为同款先例）。
- 改动：`common.kdl` 标题正则改为 `^(Picture in picture|画中画)$`；`niri_config_test.sh` 断言、niri README、`memory/niri.md` 同步（含 map 时标题未就绪则留在平铺态的残余风险与 `niri msg windows` 排查法）。
- 验证：`niri validate -c` 两平台通过；`bash tests/niri_config_test.sh` PASS。
- 回滚信息：未提交（并入当日未提交的 niri 优化批次）；未同步 live。实测确认：在 Chrome 开一次画中画，应浮动；若仍平铺，`niri msg windows` 看实际标题再调正则。

## 2026-09-01 — niri 环境高价值优化六项落地（键盘 repeat / workspace 回跳 / Chrome PiP / idle_inhibitor / DPMS 关屏 / mako 免打扰）

- 目的：落地 niri 环境评估（只读分析）确认的第 1–6 项高价值低风险优化，全部走"配置 → 测试断言 → README/memory 同步"链路。
- 改动：
  1. `common.kdl` keyboard 段加 `repeat-delay 300` + `repeat-rate 40`（默认 600ms/25 偏慢）；
  2. `common.kdl` binds 新增 `Mod+grave`→`focus-workspace-previous`（workspace 级回跳）、`Mod+Shift+N`→`makoctl mode -t do-not-disturb`；
  3. `common.kdl` 新增 Chrome 画中画 window-rule（app-id `^google-chrome$` + title `^Picture in picture$`，`open-floating true`）；
  4. waybar `config`/`config.aarch64` modules-right 加入 `idle_inhibitor`（音量与隐私之间），`style.css` 三处共享选择器列表追加 `#idle_inhibitor` 并新增 `#idle_inhibitor.activated` peach 态；
  5. `wayland-autostart` swayidle 追加 `timeout 900 'niri msg action power-off-monitors'` + `resume ... power-on-monitors`（DPMS 关屏不挂起）；
  6. mako config 新增 `[mode=do-not-disturb] invisible=1` + `[mode=do-not-disturb urgency=critical] invisible=0`。
  测试：`niri_config_test.sh`（repeat/键位/PiP 断言）、`waybar_config_test.sh`（modules-right 两行 + idle_inhibitor 断言）、`wayland_scripts_test.sh`（swayidle 关屏断言）、`mako_config_test.sh`（known keys 加 `invisible`、两个 awk 放行注释行、结构测试放行 `[mode=...]` 段、新增 DND 断言）。README：niri（快捷键表两行 + 锁屏行纠正为 gtklock 优先 + 键盘 bullet + Chrome PiP bullet + swayidle bullet）、waybar（布局图 + 空闲抑制要点）、mako（免打扰模式一节）。memory：`niri.md`（键位三条 + 窗口规则一条 + autostart 一条）、`waybar.md`（空闲抑制模块一节）。
- 验证：`niri validate -c` 两平台 KDL 均 valid（确认 `Mod+grave` 键名与 `focus-workspace-previous` action 受支持）；`bash -n wayland-autostart` 通过；四个目标测试文件单独 PASS；`./tests/run.sh fast` PASS=46 FAIL=0。
- 回滚信息：未提交（工作区 15 个文件修改，commit 时机由用户掌控）；未同步 live。live 同步走 `./install.sh`（自动备份 `~/.config` 对应目标并保留 3 份），niri 26.04 watcher 会自动重载 `common.kdl`，waybar/mako/swayidle 需重启会话或重跑 `~/.config/scripts/wayland-autostart`（mako 需 `makoctl reload`）。
- 后续方向（评估中未落地的中价值项）：`toggle-window-rule-opacity` 键位、portal 文件选择器浮动（需实测 app-id）、foot `[bell] notify=yes`、niri 内置交互式截图 UI 绑 `Print`；另有 niri README 两处文档腐化待修（"上游 flake 构建"已过时、平台表 DP-2 缩放仍写 1.25x）。

## 2026-09-02 — 新增 update-ai-clis 一键更新 AI CLI

- 目的：为 npm 全局安装的 claude-code/codex 提供统一升级入口（两者均不走 brew cask，见同日更早记录），避免手动敲 `npm update -g` 两个包名。
- 改动（仓库）：① 新增 `.config/scripts/update-ai-clis`（`#!/bin/sh`，支持默认更新、`--check` 只读查版本、`--help`；内部执行 `npm update -g @anthropic-ai/claude-code @openai/codex`，缺 npm 时报错退出）；② `install.sh` shared_configs 加部署项（条件 `command -v npm`，部署到 `~/.config/scripts/update-ai-clis`）；③ `.config/scripts/README.md` 文件清单表 + 用法段落；④ 新增 `tests/update_ai_clis_test.sh`（存在/可执行/目标包/子命令/部署/未知参数拒绝）。
- 验证：`sh -n` 语法 OK；`update-ai-clis --check` 正确列出 claude-code 2.1.258 + codex 0.152.1；`--help` 正常；`sh tests/update_ai_clis_test.sh` PASS；`tests/run.sh fast` PASS=47 FAIL=0；`git diff --cached --check` 干净。
- 回滚信息：已提交 `4d6f32d`（脚本 + README + install.sh + 测试）。`git revert 4d6f32d` 即回滚；live 未同步（脚本仅存仓库，install.sh 重跑或手动复制部署）。
- 后续可能方向：① live 同步走 `./install.sh`（检测 npm 后复制 `.config/scripts/update-ai-clis` → `~/.config/scripts/`）或手动 `cp` + chmod +x；② 若日后某包回到 brew 管理，需同步更新脚本包列表。


## 2026-09-02 — claude-code 升级源被墙，改由 npm 全局安装

- 目的：brew cask `claude-code` 无法升级（`brew outdated` 显示 2.1.220 → 2.1.236），排查发现 `downloads.claude.ai`（原生二进制唯一源，Google Cloud IP 35.190.46.17）TCP 443 被阻断——`claude.ai` 主页可达但下载 CDN 不可达；无本地代理可用；官方 npm registry 与 npmmirror 均可达。经用户确认切换 npm 方案。
- 改动（系统 + 仓库）：① `brew uninstall --cask claude-code`（移除 2.1.220 原生二进制，释放 271.8MB）；② `npm install -g @anthropic-ai/claude-code` → **2.1.258**（官方 registry 直装，22s；npm 包 `bin/claude.exe` 实为原生 ELF 二进制 215MB，非纯 Node 脚本）；③ `.config/linux/Brewfile` 移除 `cask "claude-code"` 并注释原因，保留 `cask "codex"`（其下载走 github 源可达）；④ `memory/organizing_preferences.md` 系统环境节补 claude-code 升级路径决策。
- 验证：`claude --version` = `2.1.258 (Claude Code)`；`type -a claude` → `/usr/local/nodejs/bin/claude`（brew 链接已移除，npm 版自然接管，linuxbrew bin 在前但无冲突）；`brew outdated` 无输出（claude-code 已不在 brew 管理）；`brew missing` 无缺失；`tests/run.sh fast` PASS=46 FAIL=0。
- 回滚信息：已提交 `b529c37`（Brewfile + memory）。恢复 brew 版：`brew install --cask claude-code` + `npm uninstall -g @anthropic-ai/claude-code`（并还原 Brewfile 的 `cask "claude-code"` 行）。
- 后续可能方向：① 日后升级用 `npm update -g @anthropic-ai/claude-code`（不再走 brew）；② 若网络恢复且想回原生 brew 版，先卸 npm 版再装 brew cask，二者勿共存（PATH 遮蔽）；③ `~/Pictures` 无相关，claude 配置（`~/.claude/`）与安装形态无关，无需迁移。


## 2026-09-02 — codex 改由 npm 全局安装（与 claude-code 对齐）

- 目的：用户确认把 codex 也换成 npm 安装，与 claude-code 方案统一（brew cask 依赖 github 原生二进制，npm 版更新更快）。
- 改动（系统 + 仓库）：① `brew uninstall --cask codex`（移除 0.152.0）；② 发现系统已存在被 brew 遮蔽的旧 npm 版 `@openai/codex@0.124.0`（170M），`npm install -g @openai/codex` 升级到 **0.152.1**；③ `.config/linux/Brewfile` 移除 `cask "codex"`（现无任何 cask），注释改为 claude-code/codex 均走 npm；④ `memory/organizing_preferences.md` 补 codex 升级路径决策。
- 验证：`type -a codex` → `/usr/local/nodejs/bin/codex`（唯一来源，brew 链接已移除）；`npm ls -g @openai/codex` = 0.152.1；`brew outdated` 无输出、`brew missing` 无缺失。注：codex npm 包 `bin/codex.js` 为 Node 脚本（依赖 node 运行时），与 claude-code 的原生 ELF 二进制形态不同，但均可用；IDE 沙箱内 `codex --version` 会被拦截（node 子进程限制，code=13），真实终端正常。
- 回滚信息：未提交（Brewfile + memory 待提交）。恢复 brew 版：`brew install --cask codex` + `npm uninstall -g @openai/codex`（并还原 Brewfile 的 `cask "codex"` 行）。
- 后续可能方向：① 日后升级用 `npm update -g @openai/codex`；② brew cask 与 npm 版勿共存（PATH 遮蔽），二选一。


## 2026-09-01 — niri 浮动切换改绑 Mod+Ctrl+F

- 目的：回答用户对 niri 键位配置的合理性审查（Mod+`/Mod+Tab 无重复、waybar 左侧是 workspace 指示器 + 分隔符 + 窗口标题、J/K 双职保留），并按用户确认把浮动切换从 `Mod+Ctrl+Space` 改到 `Mod+Ctrl+F`。
- 改动：① `.config/linux/niri/common.kdl` 的 `toggle-window-floating` 从 `Mod+Ctrl+Space` 改为 `Mod+Ctrl+F`（原 `Mod+Ctrl+F` 因与 `Mod+F` 重复于 2026-08-31 释放，现复用于浮动，无冲突）；② README 键位表同步；③ `tests/niri_config_test.sh` 两处断言更新（`assert_contains Mod+Ctrl+F`、`assert_not_contains Mod+Ctrl+F { expand-column... }`）；④ `memory/niri.md` 键位条同步补记复用缘由。
- 验证：`./tests/niri_config_test.sh` PASS；`git diff --check` 干净。
- 回滚信息：未提交。repo 侧改动均可 `git checkout -- <file>` 或后续 `git revert` 回滚；live `~/.config/niri/common.kdl` 未同步（niri 26.04 自动监视配置文件，如需热生效需手动把 common.kdl 复制到 live，复制前先做 `*.backup.<TS>` 快照）。
- 后续可能方向：无。


## 2026-09-01 — foot.ini 实用配置与微优化（selection-target / bell / url style / alpha-mode / indicator-format / word-delimiters）

- 目的：升级 1.27 后补充实用配置——框选同时进剪贴板历史（配合 wl-clip-persist/cliphist）、后台响铃 urgent、URL 实线下划线、整窗均匀透明、滚动位置百分比、双击选词追加代码字符；并纠正 memory/README 中"foot 无模糊能力"的过时描述（1.27 `+blur` 构建已支持 `ext-background-effect-v1`，但 niri 全局 window-rule 已对 foot 启用 blur，重复开启无额外效果；且经核实 niri 26.04 未实现 `xdg-toplevel-tag-v1`，故 blur / toplevel-tag 均不配置）。
- 改动：① `.config/linux/foot/foot.ini` 新增 `selection-target=both`、`[bell] urgent=yes`、`[url] style=single`、`alpha-mode=all`、`indicator-format=percentage`、`word-delimiters`（默认集追加 `./=+-*%$@!?~^`，避开 `;`/`#` 注释语义冲突）；② `tests/foot_config_test.sh` 的 `test_practical_additions` 断言六项；③ foot README 与 `memory/foot.md` 同步（新增说明 + 修正 blur 描述）。
- 验证：`foot -c .config/linux/foot/foot.ini -C` exit 0（1.27 校验）；`bash tests/foot_config_test.sh` PASS；`git diff --check` 干净。注：本终端 `sh`/dash 执行任何脚本均零输出（含 `echo hi`，rc=0），为终端环境既有怪癖，故用 bash 验证；若影响 `./tests/run.sh` 聚合需单独排查。
- 回滚信息：已提交 `e28819a`（含本条目仓库侧全部改动）；live 同步走 `./install.sh`（检测 `command -v foot` 通过后复制 `.config/linux/foot/` → `~/.config/foot/`，自动 `mv` 备份为 `~/.config/foot.backup.<TS>` 并保留 3 份）；agent 终端因 IDE 白名单不能直接写 `~/.config/foot`，故由用户执行同步。恢复命令：
  ```bash
  cp -a ~/.config/foot.backup.<TS> ~/.config/foot
  ```
  repo 侧 `git revert e28819a` 即回滚。
- 后续可能方向：① 日常观察 selection-target=both 是否让框选内容进入 cliphist 历史、bell urgent 是否按预期在 niri 指示器提示；② dash 零输出问题若影响 run.sh 聚合，需单独定位。


## 2026-09-01 — 清理陈旧 wayland-protocols 残留（修复 pkg-config 误报 1.32）

- 目的：删除 4 月手工安装遗留的 wayland-protocols 1.32 残留，消除其对 apt 1.47 的 pkg-config 遮蔽（此前导致 foot 编译回退捆绑 1.49 子工程、DTD 校验失败）。
- 改动（用户执行）：`sudo rm /usr/local/share/pkgconfig/wayland-protocols.pc` + `sudo rm -r /usr/local/share/wayland-protocols`（同源陈旧数据目录一并清理）。
- 验证：两路径均已不存在；`pkg-config --modversion wayland-protocols` 默认返回 **1.47**（无需 `PKG_CONFIG_PATH` 覆盖）；系统 1.47 数据 `/usr/share/wayland-protocols`（含 ext-background-effect/xdg-toplevel-tag）完整；`foot --version` = 1.27.0 正常。
- 回滚信息：纯系统变更（删的是旧手工安装残留、无保留价值），仓库侧已随 `e28819a` 提交。还原入口：`sudo apt-get reinstall wayland-protocols`（提供系统 1.47，无需还原 1.32 残留）。repo 侧 `git revert e28819a` 即回滚。
- 后续可能方向：foot 后续升级编译不再需要 `PKG_CONFIG_PATH` 覆盖，直接用 memory/foot.md 中的简化命令即可。


## 2026-09-01 — 编译安装 foot 1.27.0 到 /usr/local（resolute 机器，系统 fcft 3.3.2）

- 目的：本机（Ubuntu resolute/26.04）apt foot 仅 1.25.0-1（resolute/universe，中科大镜像），上游最新 1.27.0；用户确认源码编译安装到 `/usr/local`，apt 1.25.0 保留作回退。
- 系统改动：① `sudo apt-get install -y libfcft-dev libutf8proc-dev scdoc`（resolute `libfcft-dev` 已 3.3.2 满足 fcft≥3.3.1，无需再 clone fcft/tllist 子工程）；② `git clone --branch 1.27.0` 到 `~/build/foot`；③ **踩坑**：pkg-config 误报 wayland-protocols 1.32 致 meson 回退捆绑 1.49 子工程，其新 XML 超出系统 wayland-scanner 1.24.0 DTD 校验失败——根因 `/usr/local/share/pkgconfig/wayland-protocols.pc`（1.32 陈旧残留）优先级高于 apt 1.47；修复：`PKG_CONFIG_PATH=/usr/share/pkgconfig meson setup --wipe build --buildtype=release -Dime=true -Dgrapheme-clustering=enabled -Ddocs=enabled -Dthemes=true`（系统 wayland-protocols 1.47 含 toplevel-tag/background-effect，1.24.0 scanner 可处理），`ninja -C build` 全过；④ `sudo meson install -C build` → `/usr/local/bin/foot`。
- 验证：`which foot` = `/usr/local/bin/foot`；`foot --version` = `1.27.0 +ime +graphemes +toplevel-tag +blur -assertions`（本次未做 PGO，故无 `+pgo`）；`/usr/bin/foot` 1.25.0 仍在作回退；footclient/docs 就位；`foot -c .config/linux/foot/foot.ini -C` exit 0（1.27 `[colors-dark]` 兼容，仓库配置无需改动）。
- 回滚信息：仓库侧已随 `e28819a` 提交（trace 归档/memory 更新）；系统变更部分恢复命令：
  ```bash
  sudo meson uninstall -C ~/build/foot/build   # 移除全部 /usr/local 产物，回落 apt 1.25.0
  ```
  repo 侧 `git revert e28819a` 即回滚。
- 后续可能方向：① 建议清理陈旧残留 `/usr/local/share/pkgconfig/wayland-protocols.pc`（1.32），否则其它构建项目仍会误判 wayland-protocols 版本；② 用户实测 niri 下 1.27 渲染/透明度/IME；③ 日后升级：`~/build/foot` 更新 tag 后 `PKG_CONFIG_PATH=/usr/share/pkgconfig ninja -C build && sudo meson install -C build`。


## 2026-08-31 — 激进瘦身：卸载 rust + llvm@22（合计释放约 3.3G）

- 目的：用户确认激进瘦身——删除 Rust 工具链（rust 1.98.0 + 其依赖 llvm@22 2.6G），预期仅失去 cargo/rustc 等，starship 与 clangd 不受影响。
- 已做：① `brew uninstall rust`（1.98.0，7,328 文件，502.4MB）——Homebrew 6.0.20 在 uninstall 时自动触发 autoremove，顺带移除 20 个孤儿依赖：llvm@22（9,051 文件，2.7GB）、curl、brotli、cyrus-sasl、keyutils、krb5、libedit、libffi、libidn2、libnghttp2、libnghttp3、libngtcp2、libpsl、libunistring、libxcrypt、openldap、pkgconf、readline、sqlite、util-linux（合计约 300MB）；② `brew autoremove` 收尾清理 autoremove 遗留的旧版孤儿 libpsl 0.23.1 + pkgconf 3.0.5（约 2MB）。
- 验证：`brew missing` 无缺失（exit 0）；剩余 formula 36 个、叶子包 7 个（bat fzf herdr lsd neovim tmux zoxide）；冒烟测试 starship 1.26.0（`~/.cargo/bin/starship`，独立二进制，exit 0）/nvim/tmux/bat/fzf/lsd/zoxide/herdr 全部正常，git/gcc 走系统 `/usr/bin` 不受影响；`cargo`/`rustc` 已按预期移除；`Cellar/rust` 与 `Cellar/llvm@22` 目录已删，Cellar 总量降至 1.3G。
- 回滚信息：未提交（仓库仅 trace 记录，纯系统变更）。恢复命令：`brew install rust`（llvm@22 作为依赖自动装回）。本会话累计释放：gcc@14 372MB + rust 清理 646MB + 本轮 ~3.3G ≈ **4.3G**。
- 后续可能方向：① 日常观察无 cargo/rustc 后是否有遗漏引用（path.zsh 的 `~/.cargo/bin` 保留，starship 仍可从此加载）；② Linux Brewfile 与当前实际安装不一致（Brewfile 声明 fd/ripgrep/yazi 未安装，且未含 lsd/tmux/herdr），可择机同步；③ `brew outdated` 有 neovim/tree-sitter/unibilium 可升级；④ 若日后需要 Rust（cargo install 等），`brew install rust` 即回。


## 2026-08-31 — brew cleanup rust 清理旧版残留 1.97.1（释放 515.3MB）

- 目的：brew 体检发现 rust 在 Cellar 有新旧两版（1.98.0 在用 + 1.97.1 旧残留）。先干跑 `brew cleanup -n rust` 确认删除范围与无风险后，经用户确认执行清理。
- 干跑确认：`brew cleanup -n rust` 将删除 ① `Cellar/rust/1.97.1`（7,256 文件，515.3MB）、② 缓存 `~/.cache/Homebrew/rust--1.97.1.arm64_linux.bottle.tar.gz`（131.1MB）、③ `rust_bottle_manifest--1.97.1`（154KB），合计约 646.6MB。风险核对：`opt/rust` → `Cellar/rust/1.98.0`、`bin/rustc`/`bin/cargo` 均链接 1.98.0，无任何包依赖 rust，starship（`~/.cargo/bin` 独立二进制）不受影响。
- 已做：`brew cleanup rust` 执行成功（"This operation has freed approximately 515.3MB"——实际只报了 Cellar 部分，缓存另有 ~131MB 一并清除）。
- 验证：`Cellar/rust/` 仅剩 1.98.0；`brew list --versions rust` = `rust 1.98.0`；`rustc 1.98.0` / `cargo 1.98.0` 运行正常；缓存中 `rust--1.97.1.*` 已消失（`rust_bottle_manifest--1.98.0` 为当前版，保留）。
- 回滚信息：未提交（仓库仅 trace 记录，纯系统变更）。恢复命令：`brew install rust`（装回当前 1.98.0；1.97.1 为旧版残留无需还原）。
- 后续可能方向：① rust（1.98.0 约 497M）+ llvm@22（2.6G，rust 依赖）仍是激进瘦身候选（合计约 3.6G），删除影响仅失去 Rust 工具链（starship/clangd 均不受影响），待用户决定；② `brew cleanup`（不带参数）可再清理其它旧版本残留与缓存（如 gcc@14 遗留 manifest 等）。


## 2026-08-31 — foot.ini 迁移 [colors] → [colors-dark]（消除 1.27 deprecation 警告）

- 目的：升级 foot 1.27.0 后旧 `[colors]` 区块弃用，每开一个窗口打印多行 `deprecated: foot: [colors]: use [colors-dark] instead`。
- 改动（仓库）：① `.config/linux/foot/foot.ini`：`[colors]` → `[colors-dark]`（foot 1.27 默认主题即 colors-dark，键名含 alpha 全部不变），加注释；② `tests/foot_config_test.sh`：`test_catppuccin_mocha_palette` 补 `assert_matches '^\[colors-dark\]$'` + `assert_not_matches '^\[colors\]$'` 防回归；③ `.config/linux/foot/README.md`：新增「palette 区块」说明（dark/light 切换方式）；④ `memory/foot.md`：安装与升级节补 1.27 主题迁移经验。
- 验证：`bash tests/foot_config_test.sh` PASS；`foot -c .config/linux/foot/foot.ini -C` exit 0 且无 warn（live 旧配置 `foot -C` 复现 deprecated 警告，确证根因）；`git diff --check` 干净。
- live 同步：IDE 沙箱不允许写 `~/.config/foot/foot.ini`（不在白名单，与 niri common.kdl / waybar 同类），需用户手动复制。备份：`~/.config/foot/foot.ini.backup.20260831_224246`（旧版快照，同步后按保留 3 份惯例清理更旧者）。恢复命令：`cp ~/.config/foot/foot.ini.backup.20260831_224246 ~/.config/foot/foot.ini`。同步命令：`cp ~/Documents/dotfiles/.config/linux/foot/foot.ini ~/.config/foot/foot.ini`。
- 回滚信息：未提交；repo 侧 `git checkout -- .config/linux/foot/foot.ini tests/foot_config_test.sh .config/linux/foot/README.md memory/foot.md logs/trace.md` 即回滚。
- 后续可能方向：① 用户手动同步 live 后新开 foot，应不再出现 deprecation 警告；② 若想用浅色主题，可加 `[colors-light]` 并用 `color-theme-toggle` 键位或 `SIGUSR1/2` 切换；③ live 同步受 IDE 白名单限制，后续 foot.ini 改动手动 cp 即可。


## 2026-08-31 — foot 1.27.0 源码编译安装到 /usr/local（放弃 Linuxbrew 路线）

- 目的：用户要 foot 最新版。Ubuntu noble apt 冻结 1.16.2、无 PPA（foot 冷门 + 依赖 fcft>=3.3.1 缺口，无人维护配对 PPA）。先试 Linuxbrew（brew foot 1.27.0 bottle 装成），但发现被 `/usr/bin/foot` 遮蔽用不上且违背"GUI 走系统源"分层原则，用户决定改源码编译装 `/usr/local`（其 PATH 中 `/usr/local/bin` 在 `/usr/bin` 前，天然生效）。
- 系统改动：① `brew uninstall foot`（keg 删除）+ `brew autoremove`（顺带清 expat / llvm 2.8G / python@3.14 / z3 四个孤儿依赖）；② `chmod 700 ~/.homebrew`（brew 报 `Refusing to write insecure trust store`，根因该目录 group 可写）；③ `sudo apt-get install -y libutf8proc-dev`（grapheme 聚类依赖，其余 dev 包系统已齐）；④ 源码编译 foot 1.27.0：`~/build/foot`（`git clone` fcft/tllist 到 subprojects 补 fcft 3.3.3，因 noble 系统 `libfcft-dev` 仅 3.1.8），`meson setup build --buildtype=release -Dime=true -Dgrapheme-clustering=enabled -Dfcft:grapheme-shaping=enabled -Dfcft:run-shaping=enabled -Dterminfo=enabled -Dthemes=true -Ddocs=enabled`（注意 `-Dime` 是 boolean 只能 `true`，传 `enabled` 报错），`ninja -C build`（165 目标全过），`sudo meson install -C build` → `/usr/local/bin/foot`。
- 验证：`which foot` = `/usr/local/bin/foot`；`foot --version` = `1.27.0 -pgo +ime +graphemes +toplevel-tag +blur`（较系统 1.16.2 多 `+toplevel-tag/+blur`，少 `+pgo`）；`/usr/bin/foot` 1.16.2 仍在作回退；`/usr/local/bin/footclient`、`/usr/local/share/terminfo/f/foot`、`/usr/local/share/man/man1/foot.1` 均就位。
- 回滚信息：未提交（本轮为系统变更 + 仓库 memory/trace 更新）。恢复命令：`sudo meson uninstall -C ~/build/foot/build`（移除全部 `/usr/local` 产物，回落 apt 1.16.2）；brew 侧如需还原 `brew install foot`。repo 侧 `git checkout -- memory/foot.md logs/trace.md` 即回滚。
- 后续可能方向：① 用户实测 niri 下新 foot 渲染/透明度（foot.ini `colors.alpha=0.82`，`+blur` 支持背景模糊）与 IME 中文输入；② 日后升级：`~/build/foot` 更新 tag 后 `ninja -C build && sudo meson install -C build`；③ 上一轮 brew 体检遗留候选（llvm@22 / rust）仍可考虑瘦身。


## 2026-08-31 — 卸载 Linuxbrew gcc@14（最小改动，释放 372MB）

- 目的：brew 包体检发现 gcc@14 为无依赖的"真叶子"（`brew uses --installed gcc@14` 为空），不在 Linux Brewfile 声明内，且系统已提供 gcc-12/13（`/usr/bin/gcc`），brew 的 gcc-14 未遮蔽系统二进制；用户确认仅卸载 gcc@14（最小改动），其余候选（llvm 2.6G / rust+llvm@22 3.6G）暂不动。
- 已做：`brew uninstall gcc@14`，移除 Cellar/gcc@14/14.4.0（1,897 文件，372.3MB）。
- 验证：`brew list --formula` 无 gcc@14（grep 计数 0）、`brew leaves` 不再含 gcc@14（现为 bat fzf herdr lsd neovim rust tmux zoxide）、`Cellar/gcc@14` 目录已删、冒烟 `command -v` bat/fzf/lsd/zoxide/gcc 全部 OK。brew 主 `gcc`（bat/lsd/zoxide 构建依赖）保留未动。
- 回滚信息：未提交（仓库零改动，纯系统变更）。恢复命令：
  ```bash
  brew install gcc@14
  ```
- 后续可能方向：① rust+llvm@22 仍是可删候选（合计约 3.6G）。**2026-08-31 复核纠正**：裸 `llvm` 公式实际未安装（`brew info llvm` = Not installed），系统仅有 llvm@22（22.1.8，2.6G，keg-only，作为 rust 依赖）；clangd 从未在 PATH（无 `~/.local/bin/clangd` 软链、llvm@22 未链接、无 apt clangd），删 rust+llvm@22 不影响 starship（`~/.cargo/bin/starship` 为独立二进制）也不改变 clangd 现状（本就不可用）。`brew cleanup rust` 可先白拿旧版 1.97.1 的 509M（零风险）。② Brewfile 声明但未安装的 fd/ripgrep/yazi 需确认是否有意移除；③ `brew outdated` 有 neovim/tree-sitter/unibilium 可升级。
