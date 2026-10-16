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
- live/提交：已覆盖 `~/.config/scripts/clipboard-wayland`，备份 `~/.config/scripts/clipboard-wayland.backup.20261008_170001_436926321`，旧 backup 按保留 3 份清理。旧守护已停，新守护 PID 3290414。仓库已提交 `26f905f`，未推送。
- 回滚信息：commit `26f905f`。仓库 `git revert 26f905f`。live 恢复：
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

## 2026-10-11 — Fedora x64 DMS 机器：屏幕入库（2x）+ GNOME 桌面身份伪装（代理用）

- 目的：把当前 Fedora x86_64 DMS 桌面的屏幕配置入库，缩放 2x；为让代理/网络工具识别 GNOME 会话，在 DMS 机器上伪装 `XDG_CURRENT_DESKTOP=niri:GNOME`。
- 改动（仓库）：
  1. 新增 `.config/linux/niri/fedora_x64/outputs.kdl`：DP-3 `3840x2160@59.997`、scale 2（逻辑 1920x1080）、`x=0`。
  2. `install.sh`：`niri_platform_key()` 映射 `fedora_x86_64|fedora_amd64` → `fedora_x64`。
  3. `.config/linux/dms/niri-repo.kdl`：新增 `environment { XDG_CURRENT_DESKTOP "niri:GNOME"; XDG_SESSION_DESKTOP "niri" }`。
  4. `.config/linux/niri/common.kdl`：`XDG_CURRENT_DESKTOP` 还原为 `"niri"`（之前未提交的 `niri:GNOME` 改动撤回，原因：DMS 机器的 live `config.kdl` 不 include `common.kdl`，该改动不生效；且 Ubuntu 机器共用此文件）。
  5. 测试（先红后绿）：`tests/niri_config_test.sh` 新增 Fedora 屏幕与 DMS 片段 GNOME 身份断言；`tests/install_wayland_test.sh` 新增 Fedora DMS 部署用例，scale 断言为 2。
  6. 文档：`.config/linux/niri/README.md`、`.config/linux/dms/README.md`、`memory/niri.md` 同步。
- 验证：`sh tests/niri_config_test.sh` PASS；`bash tests/install_wayland_test.sh` PASS；`./tests/run.sh fast` PASS=52 FAIL=0 SKIP=1；`niri validate` 对仓库 fedora_x64 与 live config.kdl 均通过；`git diff --check` OK。
- live 同步（已执行）：
  - 备份：`~/.config/niri/niri-repo.kdl.backup.20261011_082826`（改动前快照）；`dms-niri-setup` 自动备份 `~/.config/niri/config.kdl.backup.20261011_082826_102848`。
  - 复制：仓库 `niri-repo.kdl` → live；仓库 `fedora_x64/outputs.kdl` → `~/.config/niri/outputs.kdl`。
  - 接线：`dms-niri-setup` 补入 `include "outputs.kdl"`（位于 `dms/outputs.kdl` 之前）；`niri validate` 通过。
  - 生效验证：`niri msg outputs` 显示 scale 2、逻辑 1920x1080；niri 拉起的子进程环境 `XDG_CURRENT_DESKTOP=niri:GNOME`。
  - systemd 用户环境仍为 `niri`（登录时导入，未随重载更新），需要重新登录后才会对 systemd 拉起的服务生效。
- 回滚：
  - `cp ~/.config/niri/niri-repo.kdl.backup.20261011_082826 ~/.config/niri/niri-repo.kdl`
  - `cp ~/.config/niri/config.kdl.backup.20261011_082826_102848 ~/.config/niri/config.kdl`
  - `rm ~/.config/niri/outputs.kdl`；屏幕恢复为 scale 1.5 需同时 `git checkout` 对应版本。
  - 仓库：本轮未提交，回滚为 `git checkout -- <file>` 与删除 `fedora_x64/`。
- 未提交，待用户确认后提交。
- 后续可能方向：重新登录后确认 systemd 拉起的代理服务也拿到 `niri:GNOME`；如代理工具依赖 `GNOME_DESKTOP_SESSION_ID` 等其它变量，需再补。

## 2026-10-11 — 去掉 Fedora x64 DMS 的 GNOME 桌面身份伪装（第 2、3 步）

- 目的：撤回 `XDG_CURRENT_DESKTOP=niri:GNOME` 的两处注入（niri 片段 + dms.service drop-in），代理变量改由 `environment.d` 提供，GNOME 代理由 gsettings 提供。
- 改动（仓库）：
  1. `.config/linux/dms/niri-repo.kdl`：删除 `environment { XDG_CURRENT_DESKTOP "niri:GNOME" ... }` 及注释。
  2. `tests/niri_config_test.sh`：删除 `test_dms_fragment_sets_gnome_desktop_identity_for_proxy_apps`。
  3. `memory/niri.md`：删除 Fedora 条目中关于 `niri:GNOME` 的说明。
- 改动（live）：
  - `cp` 仓库 `niri-repo.kdl` → `~/.config/niri/niri-repo.kdl`。
  - 删除 `~/.config/systemd/user/dms.service.d/override.conf`。
  - 备份：`~/.config/niri/niri-repo.kdl.backup.20261011_084554`、`~/.config/systemd/user/dms.service.d/override.conf.backup.20261011_084554`。
- 验证：`niri validate` 通过；`sh tests/niri_config_test.sh` PASS；`./tests/run.sh fast` PASS=52 FAIL=0 SKIP=1；`git diff --check` OK。
- 未提交。
- 回滚：
  - `cp ~/.config/niri/niri-repo.kdl.backup.20261011_084554 ~/.config/niri/niri-repo.kdl`
  - `cp ~/.config/systemd/user/dms.service.d/override.conf.backup.20261011_084554 ~/.config/systemd/user/dms.service.d/override.conf && systemctl --user daemon-reload`
  - 仓库：`git checkout -- .config/linux/dms/niri-repo.kdl tests/niri_config_test.sh memory/niri.md`
- 后续：重新登录 niri 后确认 foot 与代理工具表现；若有工具依赖 GNOME 身份，再评估是否恢复。

## 2026-10-11 — 清除 systemd 用户环境中的 GTK_IM_MODULE（fcitx5 提示）

- 目的：消除 fcitx5 "建议取消设置 GTK_IM_MODULE" 提示。
- 根因：`/etc/profile.d/fcitx5.sh`（系统包 `fcitx5-autostart`）在 GUI 会话设置 `GTK_IM_MODULE=fcitx`，niri-session 将其导入 systemd 用户环境。仓库 `wayland-autostart` 中的 `unset-environment` 在 DMS 机器上不执行。
- 改动（仓库）：
  1. `.config/linux/dms/niri-repo.kdl`：新增 `spawn-sh-at-startup "systemctl --user unset-environment GTK_IM_MODULE"`。
  2. `tests/niri_config_test.sh`：新增 `test_dms_fragment_unsets_gtk_im_module_from_systemd_env`（先红后绿）。
  3. `tests/dms_niri_setup_test.sh`、`tests/install_wayland_test.sh`：原断言禁止 `niri-repo.kdl` 出现任何 `spawn-sh-at-startup`，仅为防止仓库 autostart 重复拉起；收窄为只禁止 `wayland-autostart`。
- 改动（live）：
  - 备份：`~/.config/niri/niri-repo.kdl.backup.20261011_085902`
  - 复制仓库 `niri-repo.kdl` → live；`niri validate` 通过。
  - 当前会话已执行 `systemctl --user unset-environment GTK_IM_MODULE`。
- 验证：`sh tests/niri_config_test.sh` PASS；`./tests/run.sh fast` PASS=52 FAIL=0 SKIP=1；`git diff --check` 待执行。
- 未提交。
- 回滚：
  - `cp ~/.config/niri/niri-repo.kdl.backup.20261011_085902 ~/.config/niri/niri-repo.kdl`
  - 仓库：`git checkout -- .config/linux/dms/niri-repo.kdl tests/niri_config_test.sh tests/dms_niri_setup_test.sh tests/install_wayland_test.sh logs/trace.md`（注意：logs/trace.md 本条之前的内容不可用此命令还原）
- 后续：重新登录后确认 `GTK_IM_MODULE` 不再回来、fcitx5 提示消失；测试一个 GTK 应用与一个 Flatpak 应用的中文输入。

## 2026-10-11 — 恢复 niri:GNOME 桌面身份（Chrome 代理）

- 目的：去掉 `XDG_CURRENT_DESKTOP=niri:GNOME` 后，Chrome 不再读取 gsettings 代理，无法访问外网；恢复该身份，让 Chrome 识别 GNOME 会话。
- 根因：Chrome 在 Linux 下通过桌面身份决定读取 gsettings 还是环境变量；环境变量不被其读取。Firefox 默认读取环境变量，因此不受影响。
- 改动（仓库）：
  1. `.config/linux/dms/niri-repo.kdl`：恢复 `environment { XDG_CURRENT_DESKTOP "niri:GNOME"; XDG_SESSION_DESKTOP "niri" }`。
  2. `tests/niri_config_test.sh`：恢复 `test_dms_fragment_sets_gnome_desktop_identity_for_proxy_apps`（先红后绿）。
  3. `memory/niri.md`：Fedora 条目补充该身份的用途与恢复原因。
- 改动（live）：
  - 备份：`~/.config/niri/niri-repo.kdl.backup.20261011_090713`
  - 复制仓库 `niri-repo.kdl` → live；`niri validate` 通过。
- 验证：`sh tests/niri_config_test.sh` PASS；`./tests/run.sh fast` PASS=52 FAIL=0 SKIP=1；`git diff --check` OK。
- 未提交。
- 回滚：
  - `cp ~/.config/niri/niri-repo.kdl.backup.20261011_090713 ~/.config/niri/niri-repo.kdl`（回到恢复前状态）
  - 仓库：`git checkout -- .config/linux/dms/niri-repo.kdl tests/niri_config_test.sh memory/niri.md`（注意：会丢失本仓库未提交的其它改动，请先确认）
- 后续：完全关闭并重新打开 Chrome 后确认可以访问外网；`XDG_CURRENT_DESKTOP` 由 niri 拉起的进程继承，已在运行的进程需要重启。

## 2026-10-11 — DMS 拉起的进程补充 GNOME 桌面身份（dms.service drop-in）

- 目的：Mod+Space（`dms ipc call spotlight toggle`）启动的应用由 DMS 拉起，不继承 niri 配置片段中的 `niri:GNOME`，因此 Chrome 等仍读不到 gsettings 代理。
- 改动（仓库）：
  1. 新增 `.config/linux/dms/dms.service.d/override.conf`：`[Service] Environment=XDG_CURRENT_DESKTOP=niri:GNOME`。
  2. `install.sh`：DMS 分支中部署该 drop-in 到 `~/.config/systemd/user/dms.service.d/override.conf`。只按 DMS 判断，不区分平台。
  3. `tests/install_wayland_test.sh`：新增 `test_install_deploys_dms_service_gnome_identity_on_dms` 与 `test_install_skips_dms_service_drop_in_without_dms`。
- 改动（live）：
  - 备份：`~/.config/systemd/user/dms.service.d/override.conf.backup.20261011_084554` 为旧 drop-in 的备份；本轮 live 无旧 `override.conf`，未额外备份。
  - 复制仓库 drop-in 到 live；`systemctl --user daemon-reload`；`systemctl --user restart dms`。
  - 验证：dms 进程（pid 90095）`XDG_CURRENT_DESKTOP=niri:GNOME`。
- 验证：`bash tests/install_wayland_test.sh` PASS；`./tests/run.sh fast` PASS=52 FAIL=0 SKIP=1；`bash -n install.sh` 通过。
- 未提交。
- 回滚：
  - 删除 live drop-in：`rm ~/.config/systemd/user/dms.service.d/override.conf && systemctl --user daemon-reload && systemctl --user restart dms`
  - 仓库：`rm .config/linux/dms/dms.service.d/override.conf`，并 `git checkout -- install.sh tests/install_wayland_test.sh`（注意：会丢失这两个文件中本轮之外的未提交改动，请先确认）。
- 后续：用 Mod+Space 启动 Chrome，确认能访问外网；README 尚未补充该 drop-in 说明。

## 2026-10-11 — Fedora x64 代理环境变量落盘（environment.d/proxy.conf）

- 目的：把 live 中手工创建的 `~/.config/environment.d/proxy.conf` 纳入仓库，仅在 Fedora x64 部署，使 niri 会话（含 foot、systemd 拉起的进程）继承代理变量。
- 改动（仓库）：
  1. 新增 `.config/linux/niri/fedora_x64/proxy.conf`（8 个代理变量，与 live 内容一致）。
  2. `install.sh`：仅当 `niri_platform_key` 为 `fedora_x64` 时部署到 `~/.config/environment.d/proxy.conf`。
  3. `tests/install_wayland_test.sh`：新增 `test_install_deploys_proxy_environment_on_fedora_x64` 与 `test_install_skips_proxy_environment_on_other_platforms`（先红后绿）。
- 改动（live）：无。live 文件已存在且与仓库内容一致（`diff` 无差异）。
- 验证：`bash tests/install_wayland_test.sh` PASS；`./tests/run.sh fast` PASS=52 FAIL=0 SKIP=1；`git diff --check` OK。
- 未提交。
- 回滚：`rm .config/linux/niri/fedora_x64/proxy.conf`，并 `git checkout -- install.sh tests/install_wayland_test.sh`（注意会丢失这两个文件中其它未提交改动）；live 回滚为删除 `~/.config/environment.d/proxy.conf` 并重新登录。

## 2026-10-11 — dms drop-in 变化才重启；文档补全

- 目的：`install.sh` 部署 dms drop-in 后，仅在内容变化时执行 `daemon-reload` 与 `restart dms`，避免每次安装都重启 DMS 外壳；补全 README 对桌面身份、代理与 GTK 清理的说明。
- 改动（仓库）：
  1. `install.sh`：DMS 分支中部署 drop-in 前后比较内容（`$(< file)`），变化才 `systemctl --user daemon-reload && restart dms`。
  2. `tests/install_wayland_test.sh`：新增 `test_install_restarts_dms_only_when_drop_in_changes`，首次部署重启、再次部署不重启。
  3. `.config/linux/dms/README.md`：文件职责表新增 drop-in 与 `proxy.conf` 两行；新增「桌面身份与代理」一节；回退一节补充两项。
  4. `.config/linux/niri/README.md`：平台表下补充 Fedora x64 的 `proxy.conf` 说明。
- 过程中的问题：首版用 `cksum`/`cat` 比较内容，测试沙箱 PATH 下 `cat` 不可用，且 `set -e` 不会因命令替换失败中止，导致判定误为"无变化"。改用 bash 内置 `$(< file)`，不依赖外部命令。
- 验证：`bash tests/install_wayland_test.sh` PASS；`./tests/run.sh fast` PASS=52 FAIL=0 SKIP=1；`bash -n install.sh` 通过；`git diff --check` OK。
- live：本轮未改动 live 文件（drop-in 与 proxy.conf 已在前面同步）。
- 未提交。
- 回滚：`git checkout -- install.sh tests/install_wayland_test.sh .config/linux/dms/README.md .config/linux/niri/README.md`（注意会丢失这些文件中本轮之前的未提交改动，请先确认）。
- 后续：实际运行一次 `./install.sh`（真机）确认重启只在 drop-in 变化时触发。

## 2026-10-11 — 代理地址按机器注入（~/.config/dotfiles/proxy_env）

- 目的：`fedora_x64/proxy.conf` 中写死的内网代理地址不入库；每台机器在本机文件中配置。
- 改动（仓库）：
  1. `.config/linux/niri/fedora_x64/proxy.conf`：改为占位符模板（`__PROXY_HOST__`、`__PROXY_PORT__`、`__SOCKS_PORT__`）。
  2. `install.sh`：新增 `deploy_fedora_proxy_environment`，读取 `~/.config/dotfiles/proxy_env` 的 `PROXY_HOST`、`PROXY_PORT`（默认 7890）、`SOCKS_PORT`（默认 7891），渲染到临时文件后经 `copy_config` 部署。文件缺失或缺 `PROXY_HOST` 时警告并跳过。
  3. `tests/install_wayland_test.sh`：`test_install_deploys_proxy_environment_on_fedora_x64` 改为基于 `proxy_env` 渲染的断言；新增 `test_install_skips_proxy_environment_without_proxy_env_file`。
  4. `.config/linux/dms/README.md`、`.config/linux/niri/README.md`：说明 `proxy_env` 的格式与缺失行为。
- 改动（live）：
  - 新增 `~/.config/dotfiles/proxy_env`（权限 600）。
  - 备份：`~/.config/environment.d/proxy.conf.backup.20261011_093913`
  - 重写 `~/.config/environment.d/proxy.conf` 为渲染结果，内容与模板渲染一致（`diff` 无差异）。
- 验证：`bash tests/install_wayland_test.sh` PASS；`./tests/run.sh fast` PASS=52 FAIL=0 SKIP=1；`bash -n install.sh` 通过；`git diff --check` OK。
- 未提交。
- 回滚：
  - live：`cp ~/.config/environment.d/proxy.conf.backup.20261011_093913 ~/.config/environment.d/proxy.conf` 并重新登录。
  - 仓库：`git checkout -- .config/linux/niri/fedora_x64/proxy.conf install.sh tests/install_wayland_test.sh .config/linux/dms/README.md .config/linux/niri/README.md`（会丢失这些文件中本轮之前的未提交改动，请先确认）。
- 后续：提交前确认 `logs/trace.md` 中历史记录不含内网地址；`~/.config/dotfiles/` 不入库。

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
