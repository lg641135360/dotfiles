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


## 2026-10-08 — 剪贴板桥有图片时不再同步文本，避免钉钉贴出路径

- 目的：DMS 截图复制后，钉钉贴出来的是 `~/.cache/dms/clipboard/<id>.png` 路径，而不是图片。
- 根因：DMS 的选区同时带 `image/png` 和缓存路径文本。`clipboard-wayland` 先把图片同步到 X11，随后文本分支的 `xclip -i` / `wl-copy` 替换整个 selection，路径把 `image/png` 清掉。钉钉（CEF 109 / XWayland）只读到这段路径。
- 已做（仓库）：图片分支仍双向同步；文本分支在本侧 TARGETS / list-types 含 `image/png|jpeg|gif` 时整段跳过。测试先红后绿，README 与 `memory/niri.md` 同步。
- 验证：`sh -n .config/scripts/clipboard-wayland`、`sh tests/wayland_scripts_test.sh` PASS、`git diff --check`。纯 `image/png` 经新桥后两侧都是 `image/png`（70 字节一致）；纯文本两侧仍同步。未重跑 `./tests/run.sh fast`。
- live/提交：已覆盖 `~/.config/scripts/clipboard-wayland`，备份 `~/.config/scripts/clipboard-wayland.backup.20261008_170001_436926321`，旧 backup 按保留 3 份清理。旧守护已停，新守护 PID 3290414。仓库未提交。
- 回滚信息：未提交。仓库 `git checkout -- .config/scripts/clipboard-wayland tests/wayland_scripts_test.sh .config/linux/niri/README.md .config/scripts/README.md memory/niri.md logs/trace.md`。live 恢复：
  ```bash
  cp ~/.config/scripts/clipboard-wayland.backup.20261008_170001_436926321 ~/.config/scripts/clipboard-wayland
  pkill -f '/clipboard-wayland start'
  nohup "$HOME/.config/scripts/clipboard-wayland" start >>/tmp/clipboard-wayland.log 2>&1 &
  ```

## 2026-10-08 — DMS 屏幕接线采用方案 B：仓库 outputs.kdl 优先

- 目的：用户选择方案 B，让仓库按机器维护的 `outputs.kdl` 成为 DMS 机器的权威屏幕配置；同时保留 DMS 生成的 `dms/outputs.kdl`，不直接改写它。
- 根因修正：niri 26.04 的 `output` 是 multipart 配置，解析后按首个匹配项查找；与 `binds` 的后出现覆盖不同。因此 `outputs.kdl` 必须排在所有 `dms/*.kdl` 之前，`niri-repo.kdl` 仍排在所有 DMS 片段之后。
- 已做（仓库）：`dms-niri-setup` 新增屏幕 include 缺失/重复/顺序错误检测与修复；方案 B 下修复时会先备份 `config.kdl`，`--check` 返回漂移，`--dry-run` 不写文件，并保持 `dms/outputs.kdl` 内容不变。DMS README、根 README、niri README、`memory/niri.md` 和安装器注释同步了两个 include 顺序的不同语义。
- 测试：新增 DMS 屏幕冲突、错误顺序修复、重复 include 去重、无 outputs 文件不接线、无既有 DMS include 时插入顺序等回归；安装测试增加 `dms/outputs.kdl` 保留断言。
- 验证：`bash -n install.sh`、相关 `sh -n`、`git diff --check`；`tests/dms_niri_setup_test.sh`、`tests/install_wayland_test.sh`、`tests/niri_config_test.sh`、`tests/waybar_config_test.sh`、`tests/wayland_scripts_test.sh`、`tests/repo_docs_test.sh` 均 PASS；三份仓库 KDL（x64、aarch64、DMS 片段）均通过 `niri validate`。提交前补跑 `./tests/run.sh fast`：**PASS=52 FAIL=0 SKIP=1**。
- live/提交：live 未在本轮重新同步（`~/.config/niri/outputs.kdl` 与 `niri-repo.kdl` 已与仓库一致；live `config.kdl` 仍内联两块 output，并已把 `include "outputs.kdl"` 排在 `dms/*.kdl` 之前）。仓库已提交 `ad9ea0e`（与「屏幕配置按机器拆开」合并，未推送）。回滚：`git revert ad9ea0e`；本轮没有新的 live backup。


## 2026-10-08 — 屏幕配置按机器拆开

- 目的：用户要求当前屏幕配置分开入库，不再放进共享配置。Ubuntu x64 桌面是当前环境的双 2K；Ubuntu aarch64 是笔记本 + 外接 4K 27 寸；Fedora 笔记本的屏幕尚未入库。
- 已做（仓库）：新增 `ubuntu_x64/outputs.kdl`（DP-1 左、HDMI-A-2 右，`2560x1440@59.951`、scale 1.25、`x=2048`）和 `ubuntu_aarch64/outputs.kdl`（eDP-1 `2880x1800@120` scale 2.0 + DP-2 `3840x2160@59.997` scale 2.0）。两份平台 `config.kdl` 改为 `include "outputs.kdl"`，`common.kdl` 明确不含 output。`install.sh` 非 DMS 路径同时部署 `outputs.kdl`；DMS 路径只部署本机 `~/.config/niri/outputs.kdl`，不覆盖 `config.kdl` 与 `dms/outputs.kdl`。`dms-niri-setup` 把 `include "outputs.kdl"` 插到第一个 `dms/*.kdl` 之前。无平台映射的机器（Fedora）跳过。
- 验证：`niri validate` 两份平台 config；`sh tests/niri_config_test.sh`、`sh tests/install_wayland_test.sh`、`sh tests/dms_niri_setup_test.sh`；`bash -n install.sh`、`sh -n .config/scripts/dms-niri-setup`、`git diff --check`。提交前 `./tests/run.sh fast` **PASS=52 FAIL=0 SKIP=1**。
- live/提交：live 未在本轮重新同步；仓库已提交 `ad9ea0e`（与方案 B 接线合并，未推送）。回滚：`git revert ad9ea0e`。


## 2026-10-08 — trae_cli.yaml 移出仓库管理

- 目的：用户明确 `trae_cli.yaml` 不应由本仓库管理。上一轮只读对照已看到 live `~/.trae/trae_cli.yaml`（模型 `Kimi-K3`、新 hook 结构）比仓库稿（`GLM-5.3`、旧 hook 结构）新，直接跑 `install.sh` 会覆盖 live。
- 已做（仓库）：删除 `.config/shared/trae-cli/trae_cli.yaml`；`install.sh` 去掉该部署项；`README.md` 结构树去掉 `trae-cli/`；`tests/herdr_config_test.sh` 改为断言 install.sh **不再**部署 `trae_cli.yaml`，herdr 配置与 `herdr-report` 部署保留；`memory/herdr.md` 记下 hooks 文件只留本机。
- 验证：`sh tests/herdr_config_test.sh` PASS；`sh tests/repo_docs_test.sh` PASS；`bash -n install.sh`、`sh -n tests/herdr_config_test.sh`、`git diff --check` 通过。提交前 `./tests/run.sh fast` **PASS=52 FAIL=0 SKIP=1**。
- live/提交：未同步 live（`~/.trae/trae_cli.yaml` 保持本机版本）；仓库已提交 `9bf3b1c`（未推送）。回滚：`git revert 9bf3b1c`。
- 后续可能方向：本机 Ubuntu x64 的 `~/.config/niri/dms/binds.kdl` 已手写吸收仓库键位（动作用 DMS IPC），与 `.config/linux/dms/niri-repo.kdl` 按「空白 DMS 默认键位」设计的覆盖层冲突；接 DMS 层前需要先决定以哪边为准。


## 2026-10-06 — aarch64 外屏 DP-2 从 4K30 切到 4K60，测试与 memory 同步

- 目的：把用户在 live 上已实测可行的 DP-2 4K60（`3840x2160@59.997`）回填到仓库，并修复两个回归测试失败。
- 背景：仓库与 live 的 `config.kdl` 仅差 include 路径改写；`niri msg outputs` 实测 DP-2 `3840x2160@59.997` 为 preferred 且当前稳定运行（VRR 不支持），推翻了 memory/niri.md 里「AOC U27U2G6R4B 只稳定提供 4K30」的旧记录。
- 改动（仓库）：
  1. `.config/linux/niri/ubuntu_aarch64/config.kdl`：DP-2 mode `3840x2160@29.981` → `3840x2160@59.997`（本轮之前已由用户改好，未提交）。
  2. `tests/niri_config_test.sh`：aarch64 外屏断言从 `@29.981` 改为 `@59.997`，注释补 2026-10-06 实测依据（推翻 4K30 结论）。
  3. `memory/niri.md`：输出布局条目更新为 4K60 已稳定可用，注明 4K30 旧记录已被实测推翻；保留「不要复用旧 Dell 120Hz modeline」的警告。
  4. 删除空目录残留 `.config/linux/swaync/`（8 月 31 日遗留、无文件、git 未跟踪）：它触发 `repo_docs_test.sh` 的 README 结构树漂移守卫报 `swaync/` 缺失。
- 验证：`./tests/run.sh fast` **PASS=52 FAIL=0 SKIP=1**（修复前为 PASS=50 FAIL=2：niri_config_test 的 4K30 硬编码断言、repo_docs_test 的 swaync 漂移守卫）；`niri msg outputs` 确认 DP-2 当前 mode `3840x2160@59.997 (current, preferred)`。
- live/提交：live **本就同步**（live 的 config.kdl 早已是 4K60，仅 include 路径为 live 布局；无本轮新增 live 同步动作，无 backup 快照）。仓库已提交并推送 `e86086e`。回滚：`git revert e86086e`。
- 后续可能方向：无；若外屏再次降回 4K30，反向执行上述回滚即可。


## 2026-10-06 — DMS 设置声明式下发（settings.txt + 幂等 apply）并落盘到 live

- 目的：用户选方案 B——把「适合当前环境」的 DMS 设置做掉，并把可复现部分写进仓库（而不是整机 `dms backup`）。
- 调研（只读）：DMS 设置面 = 30 个设置页；`dms ipc call settings get/set` 只作用于 **SettingsData → `~/.config/DankMaterialShell/settings.json`**（该文件当时只有 12 个顶层键 ⇒ 基本全处于 DMS 默认值）；`wallpaperCyclingEnabled` / `nightMode*` / `displayGamma` 等在 **`~/.local/state/DankMaterialShell/session.json`**（SessionData），`settings set` 改不到，只能用 GUI 或专用 IPC（`dms ipc call night …`）。
- 逐项核对后确定的真缺口（其余保持默认）：
  1. `acLockTimeout=0` / `acMonitorTimeout=0` = **Never**（`PowerSleepTab` 的 timeoutValues：0 即永不），而仓库 Wayland 基线是空闲 10 分钟锁屏、15 分钟关屏；`Services/IdleService.qml` 正是读 `SettingsData.acLockTimeout`/`acMonitorTimeout`。
  2. `useAutoLocation=true` 但本机 GeoClue2 不可用（dms 日志 `WARN GeoClue2 unavailable`）。
  3. 仓库 niri input 基线里的 `drag-lock` 在 DMS 里 `touchpadDragLock` 默认 false。
  4. 夜灯：DMS 默认 disabled / 4500K，仓库 gammastep 基线是 5500K（记录：4800K 会把外接屏压得过暗）。
- 有意不改：`reduceMotion`（macOS 上实测后已回滚，保留动画）、`enableRippleEffects`/`audioVisualizerEnabled`/`wallpaperCyclingEnabled`/`weatherEnabled`（口味或非 SettingsData 键）、`battery*` 超时（本机无电池）、`cursorSettings.size`（1080p 下 24 比仓库 HiDPI 用的 32 合适）。
- 已做（仓库，test-first）：
  1. 新增 `.config/linux/dms/settings.txt`：6 行 + 注释；格式 `<SettingsData 键>=<值>`、`night.temperature=<K>`、`night.enabled=<true|false>`。
  2. `.config/scripts/dms-niri-setup` 新增 `read_setting()` / `apply_settings()`：逐行读当前值 → 相等则跳过；读不到（`undefined`/空）只警告不写（防 DMS 版本漂移写脏数据）；改动后回读校验，失败告警；`--check` 计入漂移，`--dry-run` 不写。
  3. `install.sh`：DMS 分支新增部署 `settings.txt` → `~/.config/dms/settings.txt`。
  4. 测试：stub `dms` 增加 `ipc call settings get/set` 与 `night getTargetTemp/status/enable/disable/setTargetTemp`（含默认值表）；新增 `test_applies_dms_settings_idempotently`（值落盘、默认值不产生写、二次运行零 set）、`test_settings_manifest_format`（一行一 key=value、必备键齐全）；`test_dry_run_changes_nothing` 补设置不落盘断言；`install_wayland_test.sh` 补 manifest 部署断言。
  5. 文档：`.config/linux/dms/README.md` 新增「DMS 设置的下发」一节（格式、当前 6 项与理由表、不写清单的东西、回退方式、`settings set` 的边界）；根 README DMS 一节同步。
- 验证：`./tests/run.sh fast` **PASS=52 FAIL=0 SKIP=1**；`bash -n install.sh`、`sh -n .config/scripts/dms-niri-setup` 通过；`git diff --check` OK。
- live/提交：live **已下发**（`./install.sh`）。改动前快照：`~/.config/DankMaterialShell/settings.json.manual-backup.20261006_122603_102340` + 整目录 `/tmp/dms-config-before-20261006_122603_102340.tar.gz`。应用 6 项后回读：`acLockTimeout=600`、`acMonitorTimeout=900`、`useAutoLocation=false`、`touchpadDragLock=true`、夜灯 `Night mode: enabled` + `target 5500K`；`settings.json` diff = `+touchpadDragLock/acMonitorTimeout/acLockTimeout`、`-useAutoLocation`（等于默认值会被 DMS 自动移除）；夜灯状态落在 `~/.local/state/DankMaterialShell/session.json`（`nightModeEnabled=true, nightModeTemperature=5500`）；`dms-niri-setup --check` = **0**；`dms doctor` ✓ All checks passed。
- 回滚：逐项反向 = `dms ipc call settings set acLockTimeout 0`、`dms ipc call settings set acMonitorTimeout 0`、`dms ipc call settings set useAutoLocation true`、`dms ipc call settings set touchpadDragLock false`、`dms ipc call night setTargetTemp 4500`、`dms ipc call night disable`；整目录回滚 = `rm -rf ~/.config/DankMaterialShell && tar xzf /tmp/dms-config-before-20261006_122603_102340.tar.gz -C ~/.config && systemctl --user restart dms`（session.json 需另用上面的 night 反向命令）。仓库已提交并推送 `758ca81`。回滚：`git revert 758ca81`。
- 后续可能方向：① 等 10 分钟空闲实测自动锁屏（配置层已确认 `IdleService` 读该键）；② 天气/位置需要手动指定城市（本机无 GeoClue，`weatherEnabled` 仍为默认 true）；③ 如需整机搬运界面偏好，`dms backup create -o <file>`（可另存，不入库）。
