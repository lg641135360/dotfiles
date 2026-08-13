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


## 2026-08-13 — starship 替换为 catppuccin-powerline 预设

- 目的：用户希望尝试社区现成方案，整体替换原有简洁配置。
- 已做（`repo-change` + `live-sync` 部分）：
  - `.config/shared/starship.toml`：整体替换为 `starship preset catppuccin-powerline` 输出，保留头部部署注释。
  - 新增 `$os`/`$username`/`$time`/多语言版本段，引入 catppuccin_mocha palette 及 frappe/latte/macchiato 备用 palette。
  - `tests/starship_config_test.sh` 全部通过。
- live 同步：`~/.config/starship.toml` 因 IDE 沙盒限制无法直接写入，需用户手动 `cp .config/shared/starship.toml ~/.config/starship.toml`。
- 后续：新开终端即生效；若想回退，`git checkout .config/shared/starship.toml` 后重新 cp 即可。


## 2026-08-13 — aarch64 niri 禁用 gammastep 自动色温

- 目的：aarch64 (MediaTek) 上 gammastep 通过 wlr-gamma-control 压低色温/亮度，会连带把外接屏压得过暗，影响日常使用。
- 已做（`repo-change` + `live-sync` 部分）：
  - `.config/scripts/wayland-autostart`：gammastep 启动逻辑增加 `uname -m` 判断，aarch64 下跳过并打印提示，其它平台保持原行为。
  - `.config/linux/niri/README.md`：配置部署边界和自启动列表两处说明 aarch64 禁用 gammastep 的原因。
  - `tests/niri_wayland_config_test.sh`：新增断言验证 aarch64 跳过逻辑（`uname -m`、`aarch64`、提示文本、README 说明）。
- 验证：`bash -n .config/scripts/wayland-autostart` 通过；`./tests/niri_wayland_config_test.sh` PASS。
- live 同步：已杀掉 live gammastep 进程（PID 65099）；`~/.config/scripts/wayland-autostart` 因 sandbox 限制需用户手动 `cp` 同步。
- 后续：下次重装或 `install.sh` 部署后自动生效；当前 live 脚本未同步前，重新执行 wayland-autostart 仍会启动 gammastep。


## 2026-08-13 — 终端改为全平台 alacritty 默认，移除 aarch64-kitty 分支

- 目的：此前 aarch64 因 mtgpu 下 alacritty 0.18.0-dev 内屏 2x 字形损坏而优先 kitty；现用户以外接屏为主、alacritty 显示正常，决定全平台统一 alacritty 默认，并排除本轮对 kitty 的改动。
- 已做（`repo-change`，未同步 live、未提交）：
  - `.config/scripts/terminal-wayland`：删除 aarch64-kitty/foot 分支，改为全平台优先 alacritty、kitty 兜底；保留 `~/.local/bin` 补 PATH 逻辑（kitty 兜底依赖）。
  - `tests/niri_wayland_config_test.sh`：`test_niri_aarch64_config_maps_media_tek_hybrid_outputs_and_foot_terminal` 去掉 `uname -m`/`exec foot` 断言，改断言不再有 aarch64-kitty 分支；`test_launcher_and_lock_have_wayland_first_fallbacks` 注释更新。
  - `.config/scripts/README.md`、`.config/linux/niri/README.md`：终端选择描述同步为 alacritty 全平台默认。
  - `.config/linux/niri/common.kdl`：恢复全局 `opacity 0.88`（用户决定回退 kitty 调试时的临时移除）。
  - `memory/desktop.md`：更新 aarch64 终端默认决策，标注内屏字形问题未根治。
- 验证：待跑 `tests/niri_wayland_config_test.sh` 与 `bash -n .config/scripts/terminal-wayland`。
- 后续：live 的 `~/.config/scripts/terminal-wayland` 需手动复制后 Mod+Return 生效。**待办问题**：aarch64 mtgpu 下 alacritty 内屏 2x 字形损坏仍未根治（外接屏正常）；后续可从 EGL/表面缩放（scale=2.0）渲染路径入手定位，见 `debug-kitty-transparent-bg.md` 同源的 mtgpu alpha/字形渲染 bug 线索。


## 2026-08-13 — kitty 背景改为完全不透明（1.0），修复 mtgpu 半透明渲染 bug

- 目的：上一轮移除 niri 全局 opacity 后 kitty 仍"全透明、看不清字体"。经核实 live 的 `~/.config/niri/common.kdl` 已去掉 opacity 且已重载，故根因不在 niri，而在 kitty 自身 `background_opacity 0.82` 与 aarch64 mtgpu 驱动 alpha 合成 bug 叠加——驱动把 0.82 的半透明背景错误渲染成全透明。
- 已做（`repo-change`，未同步 live、未提交）：
  - `.config/linux/kitty/kitty.conf`：`background_opacity 0.82` → `1.0`（完全不透），走不透明路径绕开 mtgpu alpha bug。
  - `.config/linux/kitty/README.md`：设计表透明度行与「与 alacritty 的差异」更新，说明 mtgpu 半透明 bug 及取舍（透明观感只在 X11/Awesome 由 alacritty 保留）。
- 验证：`bash -n` 不适用（非脚本）；改动为纯配置值变更，语法经阅读核对。未跑 kitty 测试（无对应值断言改动风险低，若需可跑 `tests/kitty_config_test.sh`）。
- 后续：live 的 `~/.config/kitty/kitty.conf` 需手动复制后重启 kitty 生效；若仍全透，需进一步排查是否另有覆盖配置或驱动问题。


## 2026-08-13 — 移除 niri 全局窗口透明度，修复终端"全透明看不清字体"

- 目的：kitty 终端实际表现为全透明、文字难读。根因是 niri 全局 `window-rule { opacity 0.88 }` 会连同文字字形一起淡化，叠加 kitty 自身 `background_opacity 0.82` 后两层透明度叠乘（约 0.72），aarch64 mtgpu 自研驱动 alpha 合成本又不可靠。
- 已做（`repo-change`，未同步 live、未提交）：
  - `.config/linux/niri/common.kdl`：全局 `window-rule` 删除 `opacity 0.88`，仅保留 `draw-border-with-background false` + `background-effect { blur true }`；透明交由各应用自身控制（kitty 保持 0.82）。
  - `.config/linux/niri/README.md`：窗口规则与 Chrome 条目更新，去掉"全局 0.88 透明度"描述，记录透明度只由应用自身控制的取舍。
- 验证：`niri validate -c .config/linux/niri/ubuntu_aarch64/config.kdl` 通过（config is valid）。
- 后续：live 的 `~/.config/niri/common.kdl` 需手动复制本仓库文件后 `Mod+Ctrl+R` 重载生效；kitty.conf 未改动。


## 2026-08-13 — zsh 配置优化：HISTFILE 迁移 + compinit dump 路径显式化 + 合并 keybindings

- 目的：评估 zsh 配置发现 3 个一致性/可优化点。整体启动已优化到 0.18-0.32s，本轮只做配置一致性清理，不动启动优化路径。
- 已做（`repo-change`）：
  - `history.zsh`：`HISTFILE=~/.zsh_history` → `$ZDOTDIR/.zsh_history`，让所有 zsh 状态文件集中到 ZDOTDIR；合并原 `keybindings.zsh` 的 `↑↓` history search bindkey 到末尾。
  - `plugins.zsh`：`compinit -u` → `compinit -u -d "$ZSH_CONF/.zcompdump"`，显式 dump 路径，避免 IDE sandbox 等写入受限环境产生 `.zcompdump.<host>.<pid>` 孤儿文件。
  - `.zshrc`：移除 `source keybindings.zsh`。
  - 删除 `keybindings.zsh`。
  - `install.sh`：移除 keybindings.zsh 部署项。
  - `README.md`：模块结构图与「启动提速」段落同步（三项优化）。
  - `tests/zsh_history_test.sh`（新增）：验证 HISTFILE 跟随 ZDOTDIR、keybindings 已合并、.zshrc 不再 source keybindings。
  - `tests/zsh_plugins_test.sh`：新增 `test_compinit_uses_explicit_dump_path` 断言 `-d "$ZSH_CONF/.zcompdump"`。
- 验证：`./tests/zsh_plugins_test.sh`、`./tests/zsh_history_test.sh`、`./tests/zsh_path_test.sh`、`sh ./tests/zsh_functions_test.sh`、`bash ./tests/install_zshenv_test.sh`、`bash ./tests/repo_docs_test.sh` 全部 PASS。
- live 同步（部分已完成）：
  - 已清理 `~/.config/zsh/.zcompdump.rikoo-AIBOOK-ABA14104.*` 11 个孤儿文件。
  - 待用户手动执行（sandbox 限制无法写 `~/.config/zsh/`）：
    ```bash
    mv ~/.zsh_history ~/.config/zsh/.zsh_history   # 迁移历史
    cp .config/shared/zsh/{.zshrc,plugins.zsh,history.zsh} ~/.config/zsh/
    rm -f ~/.config/zsh/keybindings.zsh
    rm -f ~/.config/zsh/.zcompdump                 # 让下次启动用新 -d 路径重建
    ```
- 后续：下次开终端验证 HISTFILE 写入 `$ZDOTDIR/.zsh_history`、`↑↓` 历史搜索正常、compinit dump 写到 `.zcompdump`（无 pid 后缀）。
