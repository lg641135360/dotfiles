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


## 2026-08-19 — 对齐 niri 文档与实现，不改会话行为

- 目的：niri 实现已演进到 Ubuntu x86_64/aarch64 双平台、钉钉 window-rule、`Mod+s` 截图，但 `memory/niri.md`、README 验证命令和若干注释仍停留在旧决策；按用户要求只做文档对齐。
- 改动：① `memory/niri.md` 改为维护 `ubuntu_x64` + `ubuntu_aarch64`、记录钉钉 2/3 列宽与不透明、aarch64 `0.90`/`blur false` 覆盖、截图入口 `Mod+s`。② `.config/linux/niri/README.md` 验证段改用 `niri_config_test.sh` 并补 aarch64 validate；平台说明改为允许 include 后的硬件覆盖；终端表对齐实现。③ `common.kdl` 修正“不设置 ZDOTDIR”注释；aarch64 注释改为说明 `0.90` 覆盖；`screenshot-wayland` 注释 `F1` → `Mod+s`；scripts README 补终端/截图实际策略。④ `tests/niri_config_test.sh` 把 aarch64 透明度断言从注释里的 `0.88` 改为真实 `0.90`，并锁定新的验证命令。⑤ 随后确认 niri 26.04 自带 config watcher，撤销“补 `Mod+Ctrl+r`”方向：memory / README 改为依赖自动重载，`load-config-file` 只留给脚本。
- 验证：`sh tests/niri_config_test.sh` PASS；`sh tests/wayland_scripts_test.sh` PASS；`sh tests/repo_docs_test.sh` PASS；`sh tests/archive_trace_test.sh` PASS；`git diff --check` 干净。提交前已执行 `npm --prefix scripts run archive-trace --`，将 2026-08-17 的 waybar CPU 自差分条目归档到 `logs/trace-archive/2026-08.md`。
- live 同步与运行态：未同步 live，未重载 niri；提交并推送到 `origin/main`。
- 后续可能方向：① 安装器补 Ubuntu aarch64 部署测试；② 两边 `niri validate` 纳入测试。


## 2026-08-18 — waybar-system-tooltip 修复 CPU top 进程显示被截断成 0%

- 目的：用户反馈 CPU 模块 tooltip 中部分 top 进程显示 0%。用独立 Python 差分实现对照验证：排序与筛选正确（选择排序用完整浮点值、`delta > 0` 过滤），根因是 `compute_top_cpu` awk 输出用 `%d` 截断，叠加外层 shell `printf '%.0f%%'` 二次取整——1s 窗口下低占用进程瞬时值多在 0.2~0.7%，截断后显示为 0%（实测对照：raw 0.56% → 显示 0%）。mem 模块同步验证无问题：RSS 瞬时值准确（与同时刻 ps 对照差异仅为采样间隙的正常波动），使用率与 `/proc/meminfo`/`free` 一致。
- 改动：① `.config/scripts/waybar-system-tooltip` `compute_top_cpu` awk 输出 `%d` → `%.1f`，外层 shell `printf '%s  %s  %.0f%%'` → `%.1f%%`（两处必须同步，外层退回 `%.0f%%` 会二次取整重新截成 0），函数头注释同步改 `NN.N%` 并说明防截断动机。② `tests/waybar_config_test.sh` 契约测试新增两处 `%.1f` 静态断言 + 运行时断言（python 解析 tooltip 中 CPU top 值必须均为一位小数）；先改测试确认失败再改实现（测试先行）。③ `.config/linux/waybar/README.md` CPU 条目补"显示一位小数"说明。④ `memory/waybar.md` 瞬时化条目补 `%.1f` 两处联动陷阱。
- 验证：`sh tests/waybar_config_test.sh` PASS（新断言在实现修改前先失败一次，确认测试有效）；实测 `cpu` 子命令 tooltip top 值为 3.1%/0.7%/0.5% 等，无 0% 截断；`./tests/run.sh fast` 43 PASS 0 FAIL；`git diff --check` clean。
- live 同步与运行态：未同步 live `~/.config/scripts/waybar-system-tooltip`，未重载 waybar；未提交、未推送。
- 后续可能方向：① `logs/trace.md` 已达 166 行超建议上限且近期条目超 5 条，下次提交前应执行归档（`npm --prefix scripts run archive-trace --`）；② top 5 阈值过滤（如只显示 ≥0.5% 的进程）可作为备选方案，当前一位小数已足够清晰，不引入。


## 2026-08-18 — waybar CPU top 进程瞬时化（与栏内使用率口径一致）

- 目的：解决上次 trace 中长期记录的"ps `%CPU` 为生命周期平均、与栏内即时使用率口径不一致"问题——长跑进程（chrome）`%CPU` 被 elapsed 稀释偏低、新进程偏高，与栏内 1s 平均使用率语义不一致。复用 `read_cpu_usage` 的 sleep 1 窗口同步采样两次 `/proc/<pid>/stat`，不增加额外阻塞时间。
- 改动：① `.config/scripts/waybar-system-tooltip` 新增 `sample_proc_cpu`（`/proc/[0-9]*/stat` glob walk，awk 内 `index($0, ")")` + `substr` 剥掉 `pid (comm)` 段后从 state 字段 3 起重数，utime=rest[12]/stime=rest[13]；按 pid 排除自身 `$$`）和 `compute_top_cpu`（关联两次 sample 求差，瞬时 %CPU = `(delta_utime+delta_stime)*100/delta_total_jiffies`，选择排序取 top 5，awk 外 `cat /proc/<pid>/comm` 读 comm）。② 重构 `read_cpu_usage` → `read_cpu_usage_and_top`，同一 sleep 1 窗口内同时采样 `/proc/stat` 和 `/proc/<pid>/stat`，`eval "$(...)"` 取 `usage` 和 `delta_total`（awk %d 强制整数输出，eval 安全）。③ 重构 `emit_cpu` 拆 `output` 第一行为 `usage`、后续行为 `top` 列表。④ 删除 `top_cpu_processes`（被 `compute_top_cpu` 取代）。⑤ 头部注释 L7-13 改写说明瞬时化与 sleep 1 复用。⑥ `top_mem_processes` 不动（ps RSS 瞬时值已准确，无需差分）。⑦ `.config/linux/waybar/README.md` CPU/内存条目补充 top 进程瞬时化说明。⑧ `tests/waybar_config_test.sh` `test_waybar_system_tooltip_script_contract` 新增 `sample_proc_cpu`/`compute_top_cpu`/`/proc/[0-9]*/stat`/`utime1[f[1]]`/`stime1[f[1]]` 断言，新增 `assert_not_contains 'ps --sort=-pcpu'`（CPU 已不用 ps 排序；mem 仍用 `ps --sort=-rss`，新增正向断言）。⑨ `memory/waybar.md` CPU/内存模块章节追加瞬时化偏好（包括 awk 不能用 `close` 作变量名、comm 含空格的字段定位陷阱）。
- 验证：`sh tests/waybar_config_test.sh` PASS（含 `test_waybar_system_tooltip_script_contract`，新增 7 条断言 + JSON schema 校验保留）；手工 `.config/scripts/waybar-system-tooltip cpu` 输出 chrome 12-13%（瞬时，1s 内平均），对比旧版 ps %CPU 的 130%（生命周期平均，多核累加被 elapsed 稀释后看似很大）——长跑进程的瞬时值明显更合理；`mem` 子命令输出 trae-cn 795M（瞬时 RSS），未受影响；并发调用两次 cpu 子命令无 0%（沿用 trace 验证方法）。
- live 同步与运行态：未同步 live `~/.config/scripts/waybar-system-tooltip`，未重载 waybar；未提交、未推送。同步后下个 5s interval 自动生效，hover tooltip top CPU 进程显示瞬时值。
- 后续可能方向：① 内存 top 进程若要对齐 AwesomeWM 用 `/proc/<pid>/status` 的 `VmRSS:` 字段（不再 fork ps），可单独迭代；② `/proc/[0-9]*/stat` glob 在进程数极多时（>1000）可能让 awk `-v` 字符串超过 mawk 限制，需切到临时文件方案（但当前几百进程稳）；③ `index($0, ")")` 取首个 `)` 近似，comm 内含 `)` 极罕见（内核允许 `()` 但进程名一般不含），可接受；④ `eval "$(...)"` 依赖 awk `%d` 强制整数输出，若 awk 实现异常可能引入注入风险，可改为临时文件方式更严格（当前 mawk/gawk 都安全）。


## 2026-08-18 — waybar CPU/内存恢复 custom 模块以支持 hover 显示 top 5 进程

- 目的：落实上次回退内置模块后留下的后续方向之一——内置 `cpu`/`memory` 模块的 `tooltip-format` 占位符无法注入动态进程列表，用户希望 hover 时看到 top 5 占用进程（对齐 AwesomeWM `widgets/system.lua` 风格）；同时修复 tooltip 文案不一致（CPU "CPU 使用率：..." vs 内存 "内存：..."）与内存 `states` 阈值偏低（80/95 在 Linux 缓存常态占用高时易误报）。
- 改动：① 新建 `.config/scripts/waybar-system-tooltip`（mode 0755）——单次调用内自差分（两次 `/proc/stat` 间隔 `sleep 1`，规避 state 文件多 bar 并发 / waybar 重载串扰导致的偶发 0%）、`self=$$` 按 pid 排除自身（去掉 `!= "sh"` 误伤真实 sh 进程）、`json_escape` 前置 `tr -d` 清除控制字符、`emit_class` 阈值 CPU 70/90 内存 85/95、tooltip 对齐 AwesomeWM 风格（首行 `CPU`/`内存` 标题 + 摘要 `使用率：XX%`（CPU 多一行 `负载：X.X`）+ `Top CPU 进程`/`Top 内存进程` + `pid  comm  value` 两空格分隔的 5 行进程列表）。② `.config/linux/waybar/config` 与 `config.aarch64` 的 `cpu`/`memory` 段改为 `custom/cpu`/`custom/memory`（`format`/`exec`/`exec-on-click true`/`interval 5`/`return-type json`/`tooltip true`/`escape false`/`min-length 5`/`align 0.5`/`on-click foot -- htop -s PERCENT_CPU/PERCENT_MEM`）；`modules-right` 同步改名。③ `style.css` 选择器 `#cpu`/`#memory` → `#custom-cpu`/`#custom-memory`（含 `.warning`/`.critical`）。④ `.config/linux/waybar/README.md` CPU/内存条目改回 custom 描述。⑤ `install.sh` `linux_wayland_configs` 数组 `trae-cn-wayland` 后插入 `waybar-system-tooltip` 部署条目。⑥ `tests/waybar_config_test.sh` 主契约断言改为 custom 模块形态、新增 `test_waybar_system_tooltip_script_contract`（`sh -n` + `self=$$` + `tr -d` + 无 `state_dir`/`XDG_STATE_HOME` + `sleep 1` + `emit_class` 阈值 + python3 解析两子命令输出为合法 JSON 校验 schema + tooltip 标题校验）、aarch64 superset 测试不改（custom 段两份 config 字节级一致）。⑦ `tests/install_wayland_test.sh` 补回 `waybar-system-tooltip` 部署断言（4d78570 漏删的 `.config/scripts/README.md` L20 条目正好复用，无需改）。⑧ `README.md` 根文件结构图 L51 后补 `waybar-system-tooltip/` 条目（4d78570 已删）。
- 验证：`sh tests/waybar_config_test.sh` PASS（含新 `test_waybar_system_tooltip_script_contract`，实际执行 cpu/mem 子命令解析 JSON schema）；`sh tests/install_wayland_test.sh` PASS；`sh tests/niri_config_test.sh` PASS；`sh tests/wayland_scripts_test.sh` PASS；`./tests/run.sh fast` 全部 43 测试 PASS 无跨模块回归；手工 `.config/scripts/waybar-system-tooltip cpu/mem` 输出合法 JSON，含 CPU/内存 标题、使用率、负载、Top 进程 5 行；间隔 0.1s 并发调用两次 cpu 子命令均输出真实值（34%/34%）无 0%（trace 中验证过的单次自差分方案生效）。
- live 同步与运行态：未同步 live `~/.config/waybar/`、`~/.config/scripts/`，未重载 waybar；未提交、未推送。同步后下个 5s interval 自动生效，hover 即可看到 top 5 进程。
- 后续可能方向：① ps `%CPU` 为生命周期平均、与栏内即时使用率口径不一致（trace 已记录），可考虑差值法但复杂度高；② 1s 阻塞在 5s interval 下常态 CPU 2-3%（trace 已记录），如需进一步降频可考虑 top 进程独立 cache，但会重蹈 state 文件覆辙，不推荐；③ 测量窗口 1s 比 5s 平均敏感（trace 已记录），峰值可能比内置模块更显眼；④ config 与 config.aarch64 中 `custom/cpu`、`custom/memory` 段仍重复（waybar 无 include 机制，superset 测试已防漂移，维持现状）。


## 2026-08-17 — waybar-system-tooltip 修正注释与自排除逻辑、加固 JSON escape

- 目的：修复 CPU/MEM 模块脚本中注释与实现矛盾（state 文件并非按实例隔离）、`$2 != "sh"` 过滤误伤真实 sh 进程、json_escape 不处理其它控制字符三个问题。
- 改动：`.config/scripts/waybar-system-tooltip`：① 头部注释改为如实描述共享 state 文件的单 bar 前提与多 bar 串扰限制（waybar exec 不传 bar 身份，无法低成本隔离）；② top_cpu/top_mem_processes 改为 `-v self=$$` 按 pid 排除自身，去掉按 comm "sh" 的过滤（`ps` comm 过滤保留）；③ json_escape 前置 `tr -d` 清除 \r 及其它控制字符，防止异常 comm 产生非法 JSON。`tests/waybar_config_test.sh` 新增 `test_waybar_system_tooltip_script_contract`（sh -n + 断言无 `!= "sh"` 过滤 + python3 解析两子命令输出为合法 JSON）。
- 验证：`sh tests/waybar_config_test.sh` PASS（含新测试）。
- live 同步与运行态：未同步 live `~/.config/scripts/`，未重载 waybar；未提交、未推送。
- 后续可能方向：top 进程降频缓存以降低常态 CPU 开销（2-3%）；`ps` %CPU 为生命周期平均、与栏内即时使用率口径不一致，可考虑差值法；config 与 config.aarch64 中 custom/cpu、custom/memory 段重复（waybar 无 include 机制，现有 superset 测试已防漂移，维持现状）。
