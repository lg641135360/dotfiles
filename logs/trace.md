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


## 2026-11-19 — 优化 tmux 配置（tmux-256color + usstyle / swap-window 跟随 / allow-passthrough / Wayland env）

- 目的：优化 tmux 3.8 下的 Neovim 斜体与波浪下划线支持、窗口移动手感、yazi 图片透传及重连后的 Wayland/niri 环境变量同步，并减少 `tmux-tab-title` ASCII 长度计算的外部进程开销。
- 改动（仓库，测试先行）：
  1. `.config/shared/tmux/.tmux.conf`：在 TPM 之后显式设 `default-terminal "tmux-256color"`（防止 `tmux-sensible` 重置为 `screen-256color`）；`terminal-features` 补充 `:usstyle`；开启 `allow-passthrough on`；`update-environment` 追加 `NIRI_SOCKET`（实测 tmux 3.8 已内置 `WAYLAND_DISPLAY`，避免重复项）；`bind -r <` / `bind -r >` 改为 `swap-window -d -t -1/+1`（焦点跟随 + 可连按）；合并重复的 `# Window settings` 注释并修正节编号 `8 → 7`。
  2. `.config/shared/tmux/tmux-tab-title`：`strlen()` 对纯 ASCII 字符串改用 POSIX 内置 `${#1}`，仅含非 ASCII 字符时回落 `awk`。
  3. `.config/shared/tmux/README.md`、`memory/tmux.md`、`tests/tmux_status_test.sh`：同步文档、长期记忆与回归断言（含 `default-terminal` 位于 TPM 之后的顺序守卫）。
- 改动（live）：无（`~/.tmux.conf` 在 IDE 沙箱白名单外，同步命令交用户手动执行）。
- 验证：先红后绿；`sh -n .config/shared/tmux/tmux-tab-title`、`./tests/tmux_status_test.sh`、隔离 socket `tmux -L test-config-check -f .config/shared/tmux/.tmux.conf start-server` 语法加载测试、`git diff --check` 均通过。
- 回滚信息：未提交（基线 `7cd7167`）。仓库回滚可执行 `git checkout -- .config/shared/tmux/ memory/tmux.md tests/tmux_status_test.sh logs/trace.md`。


## 2026-11-19 — 修复高优先级配置优化项（非 DMS swayidle 防 OOM / Zsh 去 fork 与 TERMINAL / Git 去重 / install.sh 去 eval）

- 目的：落地全仓库只读审查识别出的 4 类高优先级配置优化，统一非 DMS 与 DMS 侧防 DPMS OOM 基线、压低 Zsh 启动 fork、清理 Git 重复配置及收紧 `install.sh` 安全与一致性。
- 改动（仓库，测试先行）：
  1. 非 DMS Wayland 防 DPMS OOM：`.config/scripts/wayland-autostart` 移除 `swayidle` 的 `timeout 900 'niri msg action power-off-monitors'` 与 `resume`（与 DMS 侧 `acMonitorTimeout=0` 对齐，避免 niri 在 DPMS off 期间持续积压 dmabuf/shmem）；同步 `.config/linux/niri/README.md`、`memory/niri.md`、`tests/wayland_scripts_test.sh`。
  2. Zsh 启动与环境变量：`.config/shared/zsh/env.zsh` 与 `.config/shared/zsh/aliases.zsh` 将 `[[ -x "$(command -v ...)" ]]` 替换为零 fork 的 `(( $+commands[...] ))`；`TERMINAL` 改为 Linux 下优先 `foot`、缺失回退 `alacritty`；`FZF_DEFAULT_OPTS` 改为幂等直接赋值（去前导空格、避免重复 source 叠加）；同步 `.config/shared/zsh/README.md`、`memory/alacritty.md`、`tests/zsh_plugins_test.sh`、`tests/zsh_path_test.sh`。
  3. Git 配置去重：`.config/shared/git/config` 合并重复的 `[log]` 区块与重复的 `abbrevCommit = true`；`tests/git_config_test.sh` 增加唯一性回归断言。
  4. `install.sh` / `dms-niri-setup` / `dnf.txt` 一致性：`install.sh` 用 `check_config_available` 取代 `eval "$check_cmd"`，macOS 分支改用 `"$BASH"` 调用 `defaults.sh`；`.config/scripts/dms-niri-setup` 生成 DMS 默认键位时改为优先 `--terminal foot`、回退 `alacritty`；`.config/linux/packages/dnf.txt` 头部用途注释同步为 `niri + DMS 主力`；同步 `tests/install_macos_test.sh`、`tests/dms_niri_setup_test.sh`。
- 改动（live）：无（仅 `repo-change`，未同步 live `~/.config`、未重载服务、未提交推送）。
- 验证：先红（6 个目标测试均按预期失败）后绿；`bash -n install.sh`、`sh -n .config/scripts/wayland-autostart`、`sh -n .config/scripts/dms-niri-setup`、`zsh -n .config/shared/zsh/env.zsh .config/shared/zsh/aliases.zsh`、`git diff --check` 均通过；`./tests/run.sh fast` **PASS=54 FAIL=0 SKIP=1**。
- 回滚信息：未提交（基线 `7cd7167`）。仓库回滚可执行 `git checkout -- install.sh .config/ memory/ tests/ logs/trace.md`。


## 2026-11-11 — 新增 GitHub Actions CI 门禁（fast 套件 + whitespace / 语法检查）

- 目的：此前测试只在本地手动跑，推送前漏跑 `./tests/run.sh fast` 就会把回归带到 `origin/main`；补远端兜底。
- 改动（仓库）：
  1. 新增 `.github/workflows/ci.yml`：push(main) / PR / workflow_dispatch 触发；`actions/checkout@v4`（`submodules: recursive` + `fetch-depth: 2`）；Node 22 并 `npm --prefix scripts install`（`archive_trace_test.sh` 走 `npx tsx`，且 `scripts/package-lock.json` 被 gitignore）；apt 补装 zsh（缺失时 `zsh_path_test` 会退化为 SKIP）；`git diff --check HEAD^..HEAD`；按 shebang 选择 `sh -n` / `bash -n`；最后 `./tests/run.sh fast`。
  2. 新增 `tests/ci_workflow_test.sh`：断言工作流存在、含 push/PR 触发、跑 fast、做 range 形式 whitespace 检查、初始化 submodule，并要求 README 记录 CI。
  3. `README.md`：结构树补 `.github/`，「运行测试」补 CI 说明（明确 nvim 测试不在 CI 中跑）。
  4. 首跑失败后的修复 `tests/oom_watch_test.sh`：`assert_output_contains 'tmpfs mount=/tmp'` 把主机布局写死，改为钉行格式 `ts=… tmpfs mount=<path> used_kb=N avail_kb=N total_kb=N` 并要求至少上报一行，不再钉具体挂载点。
- 改动（live）：无。
- 验证：本地 `./tests/run.sh fast` PASS=54 FAIL=0 SKIP=1；`tests/ci_workflow_test.sh`、`tests/repo_docs_test.sh`、`tests/oom_watch_test.sh` PASS；`python3 -c 'yaml.safe_load(...)'` 解析通过；74 个 shell 文件 shebang 语法检查通过；`git diff --check` OK。
- CI 首跑（run 42939995673 / `83bf9e2`）失败在 `tests/oom_watch_test.sh`：runner 的 `/tmp` 落在根分区，`df -kP /tmp` 报 `mount=/` 而不是 `/tmp`。用 `ubuntu:24.04` 容器以非 root（uid 1001）复现并验证修复，容器内整套 fast 为 PASS=49 FAIL=0 SKIP=6（缺 lua/luajit 等环境项）。
- CI 二跑（run 42944078425 / `a41e49c`）通过：job step 全绿、无 annotation，badge 转为 `CI - passing`。
- 未验证：真机（Ubuntu 26.04 桌面 / Fedora DMS）上的 CI 等价环境未单独复跑，仅覆盖本机与容器。
- 附带发现（本轮不修）：容器内以 root 跑 `install.sh` 时，`process_config` 的 `cp -p` 会把源文件属主/权限带到 `mktemp` 临时文件，配合 `fs.protected_regular` 在写回 `__HOME__` 渲染结果时报 `Permission denied`；线上 runner 以非 root 运行不触发，`tests/install_wayland_test.sh` 在 runner 身份下通过。后续可把该 `cp -p` 改为不保留权限。
- 提交：CI 门禁 `83bf9e2`，测试修复 `a41e49c`（均已推送 `origin/main`）。
- 回滚：`git revert a41e49c`（仅撤销 tmpfs 断言修复）；`git revert 83bf9e2`（撤销 CI 门禁；会与本条 trace 冲突，优先用 `git revert -n` 后手工处理 trace）；未提交时 `git checkout -- tests/oom_watch_test.sh`。


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
