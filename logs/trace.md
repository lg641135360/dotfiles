# Trace

> 本文件只记录实际发生过的修改、验证证据与后续线索，不定义长期规则；若某条经验已稳定复用，应提升到 `AGENTS.md` 或 `memory/`。

## 维护规则

- 本文件总长度建议不超过 150 行。
- 最近变更摘要（按 `## YYYY-MM-DD` 标题计）最多保留 5 条。
- 归档通过 `scripts/archive_trace.ts` 手动触发，或由 agent 按 `AGENTS.md` 验证策略在提交前执行：
  ```bash
  npm --prefix scripts run archive-trace -- --dry-run   # 预览
  npm --prefix scripts run archive-trace --              # 执行
  ```
- 旧条目按月份归档到 `logs/trace-archive/YYYY-MM.md`。
- 默认任务不得读取 `logs/trace-archive/` 全文。
- 只有用户明确要求，或任务确实依赖历史背景时，才按需读取相关月份归档。
- 长期有效的规则、方法论或决策边界，不应长期停留在 `logs/trace.md`；若跨多次任务仍有效，应提升到对应 `memory/` 规则文件。

## 2026-07-10 — openSUSE Tumbleweed x64 niri 配置

- 目的：为 openSUSE Tumbleweed x86_64 提供可由安装器自动部署的 Niri 平台配置。
- 已做：新增 `opensuse_tumbleweed_x64/config.kdl`，配置文本复用 Arch x64 单 4K output 布局；`install.sh` 将 `opensuse-tumbleweed` 的 x86_64/amd64 映射到该平台；同步 README 与 Niri 回归覆盖。
- 验证：`./tests/niri_wayland_config_test.sh` 通过，包含 Tumbleweed 模拟安装与 KDL 条件校验。
- 后续：未同步 live、未重载 niri、未提交推送。

## 2026-07-10 — niri 定时自动挂起

- 目的：在所有 Niri 会话中统一启用空闲自动睡眠，同时保证进入睡眠前已锁屏。
- 已做：`wayland-autostart` 的 `swayidle` 增加空闲 30 分钟执行 `systemctl suspend`；保留空闲 10 分钟锁屏和 `before-sleep` 锁屏，并在缺少 `systemctl` 时跳过该服务并提示。
- 验证：`./tests/niri_wayland_config_test.sh` 通过。
- 后续：未同步 live、未重载 niri、未触发实际 suspend、未提交推送。

## 2026-07-10 — niri 平台输出配置恢复

- 目的：让仓库中 Ubuntu/Arch 的显示器缩放和 output 规则能随 `install.sh` 部署，而不增加额外 profile 参数。
- 已做：恢复按发行版和架构选择 Niri 平台 KDL；匹配平台部署 output 配置与 `common.kdl`，未知平台保留现有 live Niri 配置；Ubuntu x64 缩放保持 `1.25`。
- 验证：`./tests/niri_wayland_config_test.sh` 通过，覆盖 Ubuntu/Arch 平台输出部署和未知平台保留配置。
- 后续：未同步 live、未重载 niri、未提交推送。

## 2026-07-10 — install.sh 备份清理计数

- 目的：修正清理旧配置备份后日志未显示删除数量的问题。
- 已做：`clean_old_backups()` 将读取待删除项的循环移出管道子 shell，使 `removed` 计数能在当前 shell 中累加；新增 `tests/install_backup_test.sh` 覆盖保留三份最新备份、删除最旧项及日志计数。
- 验证：`bash tests/install_backup_test.sh`、`bash -n install.sh` 和 `./tests/niri_wayland_config_test.sh` 均通过。
- 后续：未同步 live、未重载服务、未提交推送。

## 2026-07-10 — niri 通用配置部署

- 目的：避免安装器按发行版和架构选择固定显示器 output 规则，确保任意安装了 niri 的 Linux 环境都能部署公共配置。
- 已做：新增不含 output 的 `.config/linux/niri/config.kdl`；`install.sh` 检测到 niri 后直接复制该入口和 `common.kdl`，不再进行平台映射或 KDL 路径重写；平台 KDL 继续仅作本机显示器规则参考。
- 验证：`./tests/niri_wayland_config_test.sh` 通过，覆盖 Ubuntu、Arch 和 Fedora 模拟环境。
- 后续：未同步 live、未重载 niri、未提交推送。
