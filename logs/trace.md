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


## 2026-11-05 — 定位 niri + DMS 锁屏关屏（DPMS off）期间 Shmem 暴涨导致每日 OOM 根因，并增强 oom-watch

- 目的：分析 2026-11-04 16:07 启动的 `oom-watch` 隔夜采样日志，定位每日凌晨 OOM 根因，并补充 `oom-watch` 对 `niri.service` / `dms.service` cgroup 与 `/proc/<pid>/fdinfo` DRM 显存的采样。
- 诊断结论（实证）：
  1. `oom-watch.log.1` 在 `2026-11-05 02:05:06` 捕获 `EVENT oom_kill_incremented from=2 to=3`（`app-dms-trae\x2dcn-mw1pb0nxku5y.scope` 被内核 OOM killer 杀掉）。
  2. 对齐 3 个锁屏周期（`11-04 18:02→18:54`、`11-04 19:54→11-05 02:05`、`11-05 02:05→07:39` 与 `07:39→09:56`）发现：空闲 600s 仅锁屏（`acLockTimeout=600`）时 `Shmem` 完全平稳（~2.6 GiB）；**精确在空闲 900s（锁屏后 +300s，`acMonitorTimeout=900`）触发 `niri` 的 `PowerOffMonitors`（DPMS 关屏）那一刻**，`Shmem` 开始以 **~3.6 GiB/h（~1.02 MiB/s）** 线性上涨，且全部记在 `session.slice/niri.service`（`memory.peak` 24.98 GiB，`app.slice` 合计仅 ~1.4–1.8 GiB）；当显示器 DPMS 唤醒或解锁屏幕时，积压的 15–26 GiB `Shmem` 在 15s 内一次性释放回 ~1.4 GiB。
  3. 根因机制：DMS 的 `DBarWindow`（状态栏，含 `DgopService` 每 3s 轮询更新的 `network_speed_monitor`/`cpuUsage`/`memUsage`）未设置 `updatesEnabled` 门控；当 `niri` 执行 `power-off-monitors` 关闭输出 CRTC 后，vblank 停止，但 Quickshell 仍每 3s 提交新缓冲区，导致 `niri` 合成器在 DPMS off 期间持续积压 i915 GEM/shmem buffer。
- 改动（仓库）：
  1. `.config/scripts/oom-watch`：新增 `niri_service`（`session.slice/niri.service`）与 `dms_service`（`app.slice/dms.service`）的 cgroup 采样；新增 `top_drm` 采样 `/proc/<pid>/fdinfo/*` 中 `drm-total-system0` 最大的 DRM/GPU 客户端。
  2. `tests/oom_watch_test.sh`：新增 `niri_service`、`dms_service` 与 `drm` 行回归断言。
  3. `.config/scripts/README.md`、`memory/desktop.md`：同步 `oom-watch` 采样项说明与 DPMS off `Shmem` 泄漏根因/规避经验。
- 改动（live）：暂未同步更新后的 `~/.config/scripts/oom-watch`，也未修改 live DMS `acMonitorTimeout`（待用户确认）。
- 验证：`sh -n .config/scripts/oom-watch`、`./tests/oom_watch_test.sh`、`./tests/install_wayland_test.sh`、`./tests/repo_docs_test.sh`、`git diff --check` 均 PASS。
- 回滚信息：已提交 `39c5310`（main，已推送 `origin/main`；基线 `4c57654`）。仓库回滚可运行 `git revert 39c5310`。


## 2026-11-05 — 落地 OOM 止血：DMS 不再自动关屏（acMonitorTimeout=0）+ oom-watch 增强版入库并按需启用

- 目的：用户拍板「1+2」——① 把 DMS `acMonitorTimeout` 从 900 改为 0（不再触发 `power-off-monitors`，止住 niri 在 DPMS off 期间的 dmabuf/shmem 积压）；② 增强版 `oom-watch` 同步 live，但**默认不常开**（问题已定位，只在怀疑内存异常/OOM 复现时手动 `start`）。
- 改动（仓库，测试先行）：
  1. `tests/dms_niri_setup_test.sh`：`acMonitorTimeout` 期望 900→0，改成断言「目标值等于 DMS 默认值 ⇒ 幂等跳过写、有效值仍为 0」（`assert_file_not_exists` + stub `settings get` 读值）；新增 README 必须保留 `power-off-monitors` 理由的守卫。
  2. `.config/linux/dms/settings.txt`：`acMonitorTimeout=0`，注释写明 DPMS off 积压 dmabuf 根因与替代暗屏手段（显式写 0 而非删行，是为了把旧机器上已下发过的 900 纠正回来）。
  3. `.config/linux/dms/README.md`：设置表该行改 0 + 理由；验证段补 `settings get acMonitorTimeout # 应为 0`。
  4. `memory/niri.md`（DMS 设置基线）、`memory/desktop.md`（规避方案改为「已落地」，并补「任何 `power-off-monitors` 路径都可能复现，含非 DMS 机器的 swayidle `timeout 900`」）、`.config/scripts/README.md`（`oom-watch` 标注默认不常开）。`oom-watch` 脚本本体沿用上一轮未提交的增强版。
- 改动（live）：
  - `~/.config/dms/settings.txt` ← 仓库版，备份 `~/.config/dms/settings.txt.backup.20261105_103738`；随后只做一条 `dms ipc call settings set acMonitorTimeout 0`（未跑全量 `dms-niri-setup` apply，避免连带重写 niri 配置）。
  - `~/.config/scripts/oom-watch` ← 仓库版（md5 `a3e826ff…`），备份 `~/.config/scripts/oom-watch.backup.20261105_103802`；备份总数 2 份，未触发「保留 3 份」清理。
  - 已 `oom-watch stop`（原 pid 2298622），现不常驻；日志保留 `~/.local/state/oom-watch/oom-watch.log`（5.3 MB，含 11-05 02:05 OOM 现场）。
- 验证：
  - `./tests/dms_niri_setup_test.sh` 先红（`setting.acMonitorTimeout` 仍被写 900）后绿；`./tests/oom_watch_test.sh`、`./tests/repo_docs_test.sh`、`./tests/install_wayland_test.sh` PASS；`./tests/run.sh fast` **PASS=53 FAIL=0 SKIP=1**；`git diff --check` OK。
  - live `dms ipc call settings get acMonitorTimeout` = `0`、`acLockTimeout` = `600`；`~/.config/dms/settings.json` 已落盘（`"acMonitorTimeout": 0`）。
  - 新采样实测（`oom-watch once`）：`cgroup label=niri_service current_kb=641765376 peak_kb=26190098432 swap_kb=168263680 shmem_kb=364470272`、`cgroup label=dms_service current_kb=1194409984`、`drm pid=4422 name=niri client_id=14 total_kb=1205576 shared_kb=1001904`。
- 未验证：锁屏 15 分钟后确实不再 `power-off-monitors`（需空闲实证，可 `journalctl --user -u dms.service -f | grep -iE "power|idle"`，或次日看 `niri.service memory.peak` 是否仍停在 ~0.7 GiB）。
- 既有漂移（本轮发现并已修）：live `~/.config/niri/config.kdl`（mtime 原为 2026-10-08）缺 `include optional=true "dms/binds-next.kdl"`，`dms doctor` 报 1 warning、`dms-niri-setup --check` 退出 1。用户随后执行 `~/.config/scripts/dms-niri-setup`（apply，自动备份 `~/.config/niri/config.kdl.backup.20261105_104414_3294177`）：include 已补齐（`outputs.kdl` → `dms/binds-next.kdl` → `dms/binds.kdl` → 其余 dms → `niri-repo.kdl`），`--check` exit=0「已是最新」，`niri validate` PASS，`dms doctor` 全绿。
- 回滚信息：已提交 `39c5310`（main，已推送 `origin/main`；基线 `4c57654`）。live 恢复可直接复制执行：
  ```bash
  cp ~/.config/dms/settings.txt.backup.20261105_103738 ~/.config/dms/settings.txt
  dms ipc call settings set acMonitorTimeout 900
  cp ~/.config/scripts/oom-watch.backup.20261105_103802 ~/.config/scripts/oom-watch
  ~/.config/scripts/oom-watch start   # 仅在想恢复常驻监控时
  cp ~/.config/niri/config.kdl.backup.20261105_104414_3294177 ~/.config/niri/config.kdl   # 需要回退 binds-next include 时
  ```


## 2026-11-04 — DMS 2.1 niri 接线修复：binds-next 顺序与 DMS 快捷键面板

- 目的：适配当前 DMS 2.1.0 新增的 `dms/binds-next.kdl`，消除 DMS doctor 的键位 include 顺序警告；用户明确选择 `Mod+Shift+Slash` 使用 DMS 快捷键面板。
- 改动（仓库）：
  1. `.config/scripts/dms-niri-setup`：保证 `dms/binds-next.kdl` 排在 `dms/binds.kdl` 之前，并保持仓库 `niri-repo.kdl` 最后覆盖；补充幂等重排逻辑。
  2. `.config/linux/dms/niri-repo.kdl`：固定 `Mod+Shift+Slash` 调用 `dms ipc call keybinds toggle niri`。
  3. `.config/linux/dms/README.md`、`README.md`、`memory/niri.md`：同步 DMS 2.1 键位层和快捷键面板决策；`install.sh` 注释同步。
  4. `tests/dms_niri_setup_test.sh`、`tests/install_wayland_test.sh`：增加 `binds-next` 顺序和 DMS 快捷键面板回归断言。
- 改动（live）：已先备份并同步：
  - `~/.config/scripts/dms-niri-setup.backup.20261104_130300`
  - `~/.config/niri/niri-repo.kdl.backup.20261104_130300`
  - 接线脚本生成：`~/.config/niri/config.kdl.backup.20261104_130300_53225`
  - 当前 include 顺序为 `outputs.kdl` → `dms/binds-next.kdl` → `dms/binds.kdl` → 其余 DMS 片段 → `niri-repo.kdl`。
- 验证：`bash -n install.sh`、相关 shell 语法检查、`./tests/dms_niri_setup_test.sh`、`./tests/install_wayland_test.sh`、`./tests/niri_config_test.sh`、`./tests/repo_docs_test.sh`、`git diff --check` 均 PASS；live `dms-niri-setup --check` 报「已是最新」；`niri validate -c ~/.config/niri/config.kdl` PASS；`dms doctor` 已无 binds-next/repository warning，仅保留可选能力提示（cava、khal、dux-search、dux-calendar、dux-files、adw-gtk3 等未安装）。
- 运行态：未重启 niri 或 DMS；niri 已自动/现有配置验证通过，快捷键将在当前配置加载后按仓库片段生效。
- 回滚信息：本轮提交前基线 `e7bd75e`；仓库回滚可用 `git revert <本轮提交>`；live 恢复命令：
  ```bash
  cp ~/.config/scripts/dms-niri-setup.backup.20261104_130300 ~/.config/scripts/dms-niri-setup
  cp ~/.config/niri/niri-repo.kdl.backup.20261104_130300 ~/.config/niri/niri-repo.kdl
  cp ~/.config/niri/config.kdl.backup.20261104_130300_53225 ~/.config/niri/config.kdl
  ```


## 2026-11-04 — 新增 oom-watch 常驻内存/OOM 监控

- 目的：用户反馈每天复现 OOM；2026-11-04 07:38 的内核日志显示 `shmem` 约 24G、i915 报 `Purging GPU memory, 0 pages freed`，普通进程 RSS 抓不到现场。新增常驻采样脚本，记录 meminfo/PSI/cgroup/app scope shmem/top 进程/tmpfs，供下一次复现定位。
- 改动（仓库）：
  1. `.config/scripts/oom-watch`：POSIX sh；`start [--interval N]` / `stop` / `status` / `once` / `tail`；日志默认 `~/.local/state/oom-watch/oom-watch.log`，8MiB × 5 轮转；记录 `MemAvailable`、`Shmem`、`ShmemHugePages`、PSI、user/app.slice cgroup、anon+shmem 最大的 app scope、RssShmem 最大的进程、`/tmp` 与 `/dev/shm`。
  2. `install.sh`、`.config/scripts/README.md`、`README.md`、`memory/desktop.md`：部署项、脚本清单与长期排查经验同步；明确 **不接入 autostart**，需要时手动 `oom-watch start`。
  3. `tests/oom_watch_test.sh` 新增；`tests/install_wayland_test.sh`、`tests/repo_docs_test.sh` 增加断言。
- 改动（live）：用户确认后已备份并同步：
  - `~/.config/scripts/oom-watch.backup.20261104_160722`（首版脚本，不含 `EVENT oom_kill_incremented`）
  - `~/.config/niri/niri-repo.kdl.backup.20261104_160557`（改动前）与 `~/.config/niri/niri-repo.kdl.backup.20261104_161552`（含临时自启行的中间态）
  - 新增 `~/.config/scripts/oom-watch`（755，当前版本含 `EVENT oom_kill_incremented`）。
  - 已手动启动 `~/.config/scripts/oom-watch start`：pid 2298622（`/bin/sh ~/.config/scripts/oom-watch run`），日志 `~/.local/state/oom-watch/oom-watch.log`；验证 running 且日志持续增长。
  - 用户明确不需要自启：已移除临时加入 live `niri-repo.kdl` 的 `spawn-sh-at-startup "~/.config/scripts/oom-watch start"`，最终恢复为改动前内容；`niri validate` PASS，`dms-niri-setup --check` 报「已是最新」，live 片段中无 oom-watch 行。
  - `~/.config/scripts/wayland-autostart` 未同步 live（最终仓库也不含 oom-watch 自启）。
- 验证：`sh -n .config/scripts/oom-watch`、`bash -n install.sh`、`./tests/oom_watch_test.sh`、`./tests/install_wayland_test.sh`、`./tests/niri_config_test.sh`、`./tests/dms_niri_setup_test.sh`、`./tests/repo_docs_test.sh`、`git diff --check` 均 PASS；`./tests/run.sh fast` **PASS=53 FAIL=0 SKIP=1**。
- 回滚信息：已提交 `39c5310`（main，已推送 `origin/main`；基线 `4c57654`）。live 恢复命令（可直接复制执行）：
  ```bash
  ~/.config/scripts/oom-watch stop
  rm -f ~/.config/scripts/oom-watch
  # live niri-repo.kdl 已是改动前内容；如需强制恢复：
  # cp ~/.config/niri/niri-repo.kdl.backup.20261104_160557 ~/.config/niri/niri-repo.kdl
  # niri validate -c ~/.config/niri/config.kdl
  ```
  仓库回滚：
  ```bash
  git checkout -- install.sh README.md .config/scripts/README.md memory/desktop.md tests/install_wayland_test.sh tests/repo_docs_test.sh logs/trace.md
  rm -f .config/scripts/oom-watch tests/oom_watch_test.sh
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
- 回滚信息：已提交 `e7bd75e`（main，已推送）。live 恢复命令（可直接复制执行）：
  ```bash
  cp ~/.local/share/applications/com.alibabainc.dingtalk.desktop.backup.20261103_113013 ~/.local/share/applications/com.alibabainc.dingtalk.desktop
  ```
  仓库回滚：`rm -f .config/linux/desktop-entries/com.alibabainc.dingtalk.desktop && git checkout -- install.sh .config/linux/desktop-entries/README.md .config/linux/niri/README.md memory/dingtalk.md tests/dingtalk_wayland_test.sh tests/install_wayland_test.sh tests/wayland_scripts_test.sh logs/trace.md`。

## 2026-11-11 — 新增 GitHub Actions CI 门禁（fast 套件 + whitespace / 语法检查）

- 目的：此前测试只在本地手动跑，推送前漏跑 `./tests/run.sh fast` 就会把回归带到 `origin/main`；补远端兜底。
- 改动（仓库）：
  1. 新增 `.github/workflows/ci.yml`：push(main) / PR / workflow_dispatch 触发；`actions/checkout@v4`（`submodules: recursive` + `fetch-depth: 2`）；Node 22 并 `npm --prefix scripts install`（`archive_trace_test.sh` 走 `npx tsx`，且 `scripts/package-lock.json` 被 gitignore）；apt 补装 zsh（缺失时 `zsh_path_test` 会退化为 SKIP）；`git diff --check HEAD^..HEAD`；按 shebang 选择 `sh -n` / `bash -n`；最后 `./tests/run.sh fast`。
  2. 新增 `tests/ci_workflow_test.sh`：断言工作流存在、含 push/PR 触发、跑 fast、做 range 形式 whitespace 检查、初始化 submodule，并要求 README 记录 CI。
  3. `README.md`：结构树补 `.github/`，「运行测试」补 CI 说明（明确 nvim 测试不在 CI 中跑）。
- 改动（live）：无。
- 验证：`./tests/run.sh fast` PASS=54 FAIL=0 SKIP=1；`tests/ci_workflow_test.sh`、`tests/repo_docs_test.sh` PASS；`python3 -c 'yaml.safe_load(...)'` 解析通过；74 个 shell 文件 shebang 语法检查通过；`git diff --check` OK。
- 未验证：GitHub Actions 首次运行结果待推送后确认。
- 提交：本轮随 `feat(ci)` 提交推送，hash 待回填。
- 回滚：`git revert <本轮 CI 提交>`；未提交时 `git checkout -- README.md logs/trace.md && rm -rf .github/workflows tests/ci_workflow_test.sh`。
