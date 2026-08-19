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


## 2026-08-19 — 提示词系统新增回滚锚点规则

- 目的：用户要求每个修改可追溯、可撤回，出现回退时能及时恢复。将 AGENTS.md"安全/可回退"原则落实为机制，填补两个真实缺口：live 手动同步无备份（niri/waybar/scripts 等 IDE 白名单外手动 cp 场景）、trace 无回滚锚点（waybar tooltip 三轮连续修复均在未提交状态推进）。
- 改动：① `AGENTS.md` 三处——快速参考 checklist 加"回滚锚点已记录"项；执行中约束加"手动同步 live 前必须先创建 `*.backup.<时间戳>` 快照并在 trace 记录 backup 路径"；操作后约束加"收尾总结附 commit message 草稿，建议一轮任务一个 commit 粒度（提交时机由用户掌控）"+"trace 每条记录必须包含回滚信息（commit hash / 未提交标记 / live backup 快照路径）"。② `logs/trace.md` 维护规则同步补回滚信息字段约定。③ `tests/repo_docs_test.sh` 新增 5 条断言锁定新规则措辞，防漂移。
- 验证：`sh tests/repo_docs_test.sh` PASS（含新断言）；`git diff --check` 干净；归档后 `sh tests/archive_trace_test.sh` PASS。
- live 同步与运行态：纯仓库文档修改，无需同步 live；已提交并推送。
- 回滚信息：commit `1a43134`（与"评估与事实漂移修复""回滚规则补齐"合并为一个 commit，撤回用 `git revert 1a43134`）。
- 后续可能方向：① 规则生效后观察 agent 是否稳定执行 live 备份与收尾提交建议，若执行不到位再考虑收紧措辞；② AGENTS.md 规则已近饱和，后续新增规则应优先考虑合并进现有条目而非新开条目。


## 2026-08-19 — 对齐 niri 文档与实现，不改会话行为

- 目的：niri 实现已演进到 Ubuntu x86_64/aarch64 双平台、钉钉 window-rule、`Mod+s` 截图，但 `memory/niri.md`、README 验证命令和若干注释仍停留在旧决策；按用户要求只做文档对齐。
- 改动：① `memory/niri.md` 改为维护 `ubuntu_x64` + `ubuntu_aarch64`、记录钉钉 2/3 列宽与不透明、aarch64 `0.90`/`blur false` 覆盖、截图入口 `Mod+s`。② `.config/linux/niri/README.md` 验证段改用 `niri_config_test.sh` 并补 aarch64 validate；平台说明改为允许 include 后的硬件覆盖；终端表对齐实现。③ `common.kdl` 修正“不设置 ZDOTDIR”注释；aarch64 注释改为说明 `0.90` 覆盖；`screenshot-wayland` 注释 `F1` → `Mod+s`；scripts README 补终端/截图实际策略。④ `tests/niri_config_test.sh` 把 aarch64 透明度断言从注释里的 `0.88` 改为真实 `0.90`，并锁定新的验证命令。⑤ 随后确认 niri 26.04 自带 config watcher，撤销“补 `Mod+Ctrl+r`”方向：memory / README 改为依赖自动重载，`load-config-file` 只留给脚本。
- 验证：`sh tests/niri_config_test.sh` PASS；`sh tests/wayland_scripts_test.sh` PASS；`sh tests/repo_docs_test.sh` PASS；`sh tests/archive_trace_test.sh` PASS；`git diff --check` 干净。提交前已执行 `npm --prefix scripts run archive-trace --`，将 2026-08-17 的 waybar CPU 自差分条目归档到 `logs/trace-archive/2026-08.md`。
- live 同步与运行态：未同步 live，未重载 niri；提交并推送到 `origin/main`。
- 后续可能方向：① 安装器补 Ubuntu aarch64 部署测试；② 两边 `niri validate` 纳入测试。


## 2026-08-19 — 提示词系统评估与事实漂移修复

- 目的：用户要求评估提示词系统（AGENTS.md / USER.md / SOUL.md / memory/ / logs/trace.md / .github/copilot-instructions.md / tests/repo_docs_test.sh）。评估结论：分层职责、单一权威源 + 薄入口、契约测试（memory 索引防漂移）、意图门控五级分层、trace 自律均为健康设计，架构不动；但发现 3 处事实漂移，按用户确认（aarch64 已以 niri 为主）修复。
- 改动：① `USER.md` 窗口管理器事实改为"全平台以 niri (Wayland) 为主力（Ubuntu aarch64 已迁移并接入 GDM）；AwesomeWM (X11) 保留为可回退桌面"。② `memory/niri.md` 平台首选项改为"x86_64 与 aarch64 均以 niri + Wayland 为首选"，消除与同文件 aarch64 niri 终端 foot 特化、aarch64 config.kdl 维护内容的自相矛盾。③ `README.md` 提示词系统段把 `CLAUDE.md` 精确表述为 gitignored 本地可选入口（该文件不存在且被 .gitignore 排除，原文"只作为薄入口"易误导）。
- 验证：`sh tests/repo_docs_test.sh` PASS；`git diff --check` 干净；归档后 `sh tests/archive_trace_test.sh` PASS。
- live 同步与运行态：纯仓库文档修改，无需同步 live，无运行态变更；已提交并推送。
- 回滚信息：commit `1a43134`（与"回滚锚点规则""回滚规则补齐"合并为一个 commit，撤回用 `git revert 1a43134`）。
- 后续可能方向：① `USER.md` "主力 IDE 为 VS Code" 与当前实际使用 Trae 可能不符，待用户确认后再改；② 评估中确认 `.github/copilot-instructions.md` 一行薄入口为最优形态，无需扩展。


## 2026-08-19 — 回滚规则补齐：备份清理与恢复命令

- 目的：从使用角度评估回滚便利度后发现两个摩擦点——手动备份无清理机制会堆积、live 恢复需自己翻文件拼命令。本轮把此前的改进建议 1+2 落成规则。
- 改动：① `AGENTS.md` 执行中约束新增两条：手动同步时按"保留 3 份"清理同目标旧 backup（对齐 `install.sh` 的 `clean_old_backups`）；trace 记录 live 同步时必须写好可直接复制执行的恢复命令（含确切备份文件名）。② `logs/trace.md` 维护规则同步补恢复命令要求并附示例。③ `tests/repo_docs_test.sh` 新增 3 条断言（`保留 3 份` / `恢复命令` 两处）锁定措辞。
- 验证：`sh tests/repo_docs_test.sh` PASS（含新断言）；`git diff --check` 干净；归档后 `sh tests/archive_trace_test.sh` PASS。
- live 同步与运行态：纯仓库文档修改，无需同步 live；已提交并推送。
- 回滚信息：commit `1a43134`（与"回滚锚点规则""评估与事实漂移修复"合并为一个 commit，撤回用 `git revert 1a43134`）。
- 后续可能方向：① `scripts/rollback.sh` 一键恢复工具暂不落地，观察恢复命令写入 trace 的实际体验后再评估；② 多轮未提交叠加的中间轮撤回仍是弱项，依赖用户控制提交节奏。


## 2026-08-18 — waybar CPU top 进程瞬时化（与栏内使用率口径一致）

- 目的：解决上次 trace 中长期记录的"ps `%CPU` 为生命周期平均、与栏内即时使用率口径不一致"问题——长跑进程（chrome）`%CPU` 被 elapsed 稀释偏低、新进程偏高，与栏内 1s 平均使用率语义不一致。复用 `read_cpu_usage` 的 sleep 1 窗口同步采样两次 `/proc/<pid>/stat`，不增加额外阻塞时间。
- 改动：① `.config/scripts/waybar-system-tooltip` 新增 `sample_proc_cpu`（`/proc/[0-9]*/stat` glob walk，awk 内 `index($0, ")")` + `substr` 剥掉 `pid (comm)` 段后从 state 字段 3 起重数，utime=rest[12]/stime=rest[13]；按 pid 排除自身 `$$`）和 `compute_top_cpu`（关联两次 sample 求差，瞬时 %CPU = `(delta_utime+delta_stime)*100/delta_total_jiffies`，选择排序取 top 5，awk 外 `cat /proc/<pid>/comm` 读 comm）。② 重构 `read_cpu_usage` → `read_cpu_usage_and_top`，同一 sleep 1 窗口内同时采样 `/proc/stat` 和 `/proc/<pid>/stat`，`eval "$(...)"` 取 `usage` 和 `delta_total`（awk %d 强制整数输出，eval 安全）。③ 重构 `emit_cpu` 拆 `output` 第一行为 `usage`、后续行为 `top` 列表。④ 删除 `top_cpu_processes`（被 `compute_top_cpu` 取代）。⑤ 头部注释 L7-13 改写说明瞬时化与 sleep 1 复用。⑥ `top_mem_processes` 不动（ps RSS 瞬时值已准确，无需差分）。⑦ `.config/linux/waybar/README.md` CPU/内存条目补充 top 进程瞬时化说明。⑧ `tests/waybar_config_test.sh` `test_waybar_system_tooltip_script_contract` 新增 `sample_proc_cpu`/`compute_top_cpu`/`/proc/[0-9]*/stat`/`utime1[f[1]]`/`stime1[f[1]]` 断言，新增 `assert_not_contains 'ps --sort=-pcpu'`（CPU 已不用 ps 排序；mem 仍用 `ps --sort=-rss`，新增正向断言）。⑨ `memory/waybar.md` CPU/内存模块章节追加瞬时化偏好（包括 awk 不能用 `close` 作变量名、comm 含空格的字段定位陷阱）。
- 验证：`sh tests/waybar_config_test.sh` PASS（含 `test_waybar_system_tooltip_script_contract`，新增 7 条断言 + JSON schema 校验保留）；手工 `.config/scripts/waybar-system-tooltip cpu` 输出 chrome 12-13%（瞬时，1s 内平均），对比旧版 ps %CPU 的 130%（生命周期平均，多核累加被 elapsed 稀释后看似很大）——长跑进程的瞬时值明显更合理；`mem` 子命令输出 trae-cn 795M（瞬时 RSS），未受影响；并发调用两次 cpu 子命令无 0%（沿用 trace 验证方法）。
- live 同步与运行态：未同步 live `~/.config/scripts/waybar-system-tooltip`，未重载 waybar；未提交、未推送。同步后下个 5s interval 自动生效，hover tooltip top CPU 进程显示瞬时值。
- 后续可能方向：① 内存 top 进程若要对齐 AwesomeWM 用 `/proc/<pid>/status` 的 `VmRSS:` 字段（不再 fork ps），可单独迭代；② `/proc/[0-9]*/stat` glob 在进程数极多时（>1000）可能让 awk `-v` 字符串超过 mawk 限制，需切到临时文件方案（但当前几百进程稳）；③ `index($0, ")")` 取首个 `)` 近似，comm 内含 `)` 极罕见（内核允许 `()` 但进程名一般不含），可接受；④ `eval "$(...)"` 依赖 awk `%d` 强制整数输出，若 awk 实现异常可能引入注入风险，可改为临时文件方式更严格（当前 mawk/gawk 都安全）。
