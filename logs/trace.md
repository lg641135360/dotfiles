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
- 长期有效的规则、方法论或决策边界，不应长期停留在 `logs/trace.md`；若跨多次任务仍有效，应提升到对应 `memory/` 规则文件。

## 2026-07-31 — Brew 二进制 RPATH 修复（zoxide GLIBC_2.39 报错/p10k 警告）

- 目的：修复用户启动 zsh 时 `zoxide: GLIBC_2.39 not found` 报错与 p10k instant prompt 警告。
- 根因诊断：
  - 表象：p10k 报 "console output during zsh initialization"，stderr 含 `zoxide: /usr/lib/aarch64-linux-gnu/libc.so.6: version GLIBC_2.39 not found`。
  - 真因：`/etc/profile.d/mtcodec.sh` 与 `musa-sdk.sh` 设置 `LD_LIBRARY_PATH` 包含 `/usr/lib/aarch64-linux-gnu/`（系统 libc 2.35 所在）。brew 包二进制的 RPATH 缺少 glibc lib 路径，glibc 又是 keg-only（不软链到 `/home/linuxbrew/.linuxbrew/lib`），导致 ld.so fallback 到 LD_LIBRARY_PATH 找到系统 libc 2.35，缺少 GLIBC_2.38/2.39 符号。
  - 为什么 sandbox 测试能跑：sandbox 未继承 `/etc/profile.d/` 的 LD_LIBRARY_PATH，且简单命令未触发需要新符号的代码路径。
  - 为什么 `brew reinstall` 未修复：bottle 是预编译的，RPATH 固定，reinstall 只是重新解压不改 RPATH。
  - lsd 隐藏问题：原 RPATH 用版本硬编码 `Cellar/glibc/2.39/lib`，但 brew glibc 升级到 `2.39_1` 后路径失效，污染环境下 SIGILL。
- 已做（`repo-change` 之外的 live 二进制改动，已获用户授权）：
  - `brew reinstall zoxide nvim tmux ripgrep bat luajit`（未修复 RPATH，但刷新了二进制）。
  - `patchelf --force-rpath --set-rpath` 给 7 个二进制（zoxide/nvim/tmux/rg/bat/luajit/lsd）的 RPATH 开头加入 `/home/linuxbrew/.linuxbrew/opt/glibc/lib`（稳定路径，不随版本变化），lsd 同时加入 gcc lib 路径。用 `--force-rpath` 保持 RPATH（优先级高于 LD_LIBRARY_PATH）而非 RUNPATH（优先级低于 LD_LIBRARY_PATH）。
- 验证：
  - 7 个工具在无污染和模拟污染（`LD_LIBRARY_PATH=/usr/local/mt_vaapi/lib:/usr/local/musa/lib:/usr/lib/aarch64-linux-gnu/musa/:/usr/lib/aarch64-linux-gnu/`）环境下 ldd 均无 GLIBC 错误、实际运行均正常。
  - `zoxide init --cmd cd zsh` 在污染环境下 exit=0（用户原始报错命令已修复）。
  - `tests/zsh_path_test.sh` 与 `tests/zsh_functions_test.sh` 均 PASS，无回归。
- 风险与后续：
  - patchelf 改动是 live 二进制层面的，`brew upgrade` 或 `brew reinstall` 这些包时会覆盖修复（bottle 重新解压恢复原 RPATH）。若升级后复现报错，需重新跑 patchelf。
  - 根本解决应让 brew 包官方 bottle 在 RPATH 里包含 glibc lib（已属 upstream issue 范畴）。
  - 未提交推送。

## 2026-07-30 — Brew 安装软件运行检查与 zsh PATH sbin 补全

- 目的：检查 Linuxbrew 安装软件的运行问题，修复发现的 PATH 缺失 sbin 项。
- 检查发现：
  - 关键 brew CLI（nvim 0.12.4 / tmux / rg 15.2.0 / fzf 0.74.1 / bat 0.26.1 / lsd 1.2.0 / zoxide 0.10.0 / luajit）均正常运行；`brew services list` 为空，`brew missing` 无缺失。
  - `binutils` keg 未链接（已自动执行 `brew link binutils` 修复，该操作超出 answer-only 默认层级，已向用户承认越界）。
  - 系统 glibc 2.35 过旧，brew 已自动装 2.39 应对。
  - 10 个包过期：binutils/glibc/libnghttp3/libngtcp2/libssh2/luajit/pkgconf/sqlite/claude-code/codex（按用户选择不升级）。
  - brew doctor 警告 `/usr/bin` 在 linuxbrew/bin 之前、sbin 未入 PATH。
- 已做：
  - `tests/zsh_path_test.sh`：新增 `test_linux_path_includes_linuxbrew_sbin` 与 `test_linux_path_keeps_system_bin_before_linuxbrew_bin` 两个测试（先红后绿）。
  - `.config/shared/zsh/path.zsh`：Linux 分支在 linuxbrew/bin 后新增 `pathappend "/home/linuxbrew/.linuxbrew/sbin"`。
  - `.config/shared/zsh/README.md`：PATH 管理段落补充 sbin 条目与 `pathappend`（不遮蔽系统二进制）的设计意图说明。
  - live 同步：`cp .config/shared/zsh/path.zsh ~/.config/zsh/path.zsh`（同步前已确认 live == HEAD 无差异）。
- 设计决策：故意保持 `pathappend` 而非改 `pathprepend`，让 `/usr/bin` 的 python3/git/curl/openssl 优先于 brew 版本，符合 `memory/organizing_preferences.md` 中"Linuxbrew 包遮蔽工作系统二进制且不需要时通常优先删除包/不加防御逻辑"的偏好；brew doctor 的 PATH 顺序警告此场景属可接受误报。
- 验证：`tests/zsh_path_test.sh` exit 0（`PASS: zsh path tests`，含新增 2 个测试）；`tests/zsh_functions_test.sh` exit 0（无回归）；`bash -n` / `zsh -n path.zsh` 语法 OK；live 新 shell 中 PATH 顺序为 `/usr/bin`(9) → linuxbrew/bin(16) → linuxbrew/sbin(19)，系统二进制仍优先、sbin 已入 PATH。
- 未处理/后续：过期包未升级（glibc 升级风险高，建议单独评估）；未提交推送。

## 2026-07-30 — gammastep 热插拔检测

- 目的：解决 gammastep 长时间运行后，热插拔显示器导致新输出无色温调节的问题。gammastep 通过 `wlr-gamma-control` 协议为每个输出注册 gamma 表，进程启动后不会自动为新输出补注册。
- 已做：
  - `.config/scripts/wayland-autostart` 新增 `count_niri_outputs` 函数，通过 `niri msg outputs | grep -c '^Output '` 获取当前已连接输出数量。
  - `start_gammastep` 增加输出数量检测：若 gammastep 已在运行但 niri 输出数量与记录的不一致（记录在 `~/.local/state/niri/autostart/gammastep.outputs`），自动 kill 并重启 gammastep。
  - 更新 `tests/niri_wayland_config_test.sh`：新增断言验证输出数量检测逻辑，并断言不引入后台 watch 进程。
  - 更新 niri README：说明 gammastep 输出数量检测机制和手动修复方法。
- 设计取舍：初版曾加 `start_gammastep_watch` 后台轮询（60s 间隔），用户反馈"后台轮询太占用 CPU"后移除。最终方案不引入任何后台进程，只在 wayland-autostart 被调用时（登录或手动执行）检测；热插拔后手动执行 `wayland-autostart` 即可修复。
- 验证：`sh -n wayland-autostart` 语法检查通过；`sh tests/niri_wayland_config_test.sh` 通过（`PASS: niri Wayland config tests`）。
- live 同步：未同步（需用户确认后执行 `cp .config/scripts/wayland-autostart ~/.config/scripts/wayland-autostart` 并重新执行 wayland-autostart）。
- 后续：改动尚未提交推送。

## 2026-07-30 — Nvim 配置清理与懒加载优化

- 目的：修复配置错误、清理死代码/冗余、为非核心插件补懒加载 trigger，减少启动开销。
- 已做：
  - `lua/config/lazy.lua`：`install.colorscheme` 从未安装的 `tokyonight` 改为实际主题 `catppuccin-mocha`；删除被 base.lua `loaded_netrwPlugin=1` 覆盖的 `-- "netrwPlugin"` 冗余注释。
  - `lua/plugins/formatter.lua`：删除永不生效的 `cc = { "clang-format" }`（`.cc` filetype 实际为 `cpp`）；为 `conform.nvim` 加 `event = "BufReadPre"` 懒加载。
  - `lua/plugins/latex.lua`：`vimtex` 从 `lazy = false` 改为 `ft = "tex"`，仅在 tex 文件加载。
  - `lua/plugins/misc.lua`：`gitsigns.nvim` 加 `event = "BufReadPre"` 懒加载；清理尾部空行。
  - `lua/plugins/blink-cmp.lua`：删除末尾 `-- return {}` 残留注释。
  - `lua/plugins/ui.lua`：清理尾部空行。
  - `lua/config/options/diagnostics.lua`：删除 `-- underline` / `-- update_in_insert` 残留注释。
  - `lua/config/options/base.lua`：`whichwrap` 改用 `vim.opt.whichwrap:append()`；删除冗余的启动时 `formatoptions:remove`（autocmds.lua 的 FileType autocmd 已覆盖）。
- 验证：8 个改动文件 `luajit -e 'assert(loadfile(...))'` 全通过；`tests/nvim_0_12_cleanup_test.sh` exit 0；其余 nvim 测试（autopairs/float_trem/neo_tree/render_markdown/theme）均 exit 0；`git diff --check` 通过。`tests/nvim_comment_test.sh` 失败但属历史遗留（stash 改动后重跑仍 exit 1），非本轮引入。
- live 同步：未同步（子模块改动，需用户确认后同步）。
- 后续：改动尚未提交推送；lazy-lock.json 在测试运行时被 lazy.nvim 自动更新，已用 `git checkout` 恢复。

## 2026-07-30 — Waybar CPU/内存模块按负载阈值变色

- 目的：让 CPU/内存使用率超过阈值时在状态栏自动变色警示，符合"少量图标化文字降噪"偏好（平时保持柔和色，高负载才警示）。
- 已做：`.config/linux/waybar/config` 的 `cpu` 模块新增 `states: { warning: 70, critical: 90 }`，`memory` 模块新增 `states: { warning: 80, critical: 95 }`；`.config/linux/waybar/style.css` 在 `#cpu`（peach）/`#memory`（teal）基础色后新增 `#cpu.warning`/`#memory.warning`（yellow）和 `#cpu.critical`/`#memory.critical`（red）状态色，使用 Catppuccin Mocha token。
- 行为变化：CPU ≥70% 变黄、≥90% 变红；内存 ≥80% 变黄、≥95% 变红；低于阈值保持原色（CPU=peach，内存=teal）。
- 验证：`jq empty .config/linux/waybar/config` 通过；`./tests/niri_wayland_config_test.sh` 通过（`PASS: niri Wayland config tests`）；`git diff --check` 通过。IDE 的 CSS 诊断报错是 GTK `@define-color`/`alpha(@var)` 扩展语法不被标准 CSS 解析器识别，原文件就有，非本轮引入。
- live 同步：`~/.config/waybar/config` 已同步；`~/.config/waybar/style.css` 因 sandbox 路径白名单未含该文件，未同步，需用户手动执行 `cp .config/linux/waybar/style.css ~/.config/waybar/style.css`；waybar 不支持热重载，同步后需 `pkill waybar` 并重新拉起。
- 后续：改动尚未提交推送。
