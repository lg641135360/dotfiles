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


## 2026-09-09 — 关闭 Starship Python 版本模块

- 目的：用户确认提示符里的 ` v3.14.4` 无实际价值（TypeScript 优先、目录有 `.py` 就会冒出版本），要求关掉。
- 改动：`.config/shared/starship.toml` 的 `[python]` 设 `disabled = true`；`tests/starship_config_test.sh` 新增段落断言；`.config/shared/zsh/README.md` 去掉 Python 模块说明；`memory/organizing_preferences.md` 记录该决策。
- 验证：先补测试确认失败，再改配置后 `sh tests/starship_config_test.sh` PASS；`git diff --check` 干净。带 `.py` 的临时目录下 `starship explain` / `starship prompt` 均无 python 版本。
- live 同步：用户执行 `./install.sh`，已同步 `~/.config/starship.toml`；备份为 `~/.config/starship.toml.backup.20260909_163316_447240`。已打开的 shell 需新开才加载。
- 回滚信息：提交后见 `git log -1`。仓库 `git revert HEAD`；live 恢复：
  ```bash
  cp ~/.config/starship.toml.backup.20260909_163316_447240 ~/.config/starship.toml
  ```


## 2026-09-09 — foot 字号从 12 调回 13

- 目的：用户觉得 Starship 图标偏小。Starship 无独立字号，跟 foot 单元格走；当时为 aarch64 内屏 2x 紧凑把 foot 降到 12，x64 scale 1.25 上图标偏小。
- 改动：`foot.ini` 四条 `font*` 的 `:size=12` 改为 `:size=13`（与 alacritty 对齐）；`tests/foot_config_test.sh` 断言同步；`memory/foot.md` 记录撤回 12pt 实验。foot README / niri.md 原本已写 13，未改。
- 验证：先改测试确认失败，再改配置后 `sh tests/foot_config_test.sh` PASS；`foot -c .config/linux/foot/foot.ini -C` exit 0；`git diff --check` 干净。
- live 同步：用户执行 `./install.sh`，已同步 `~/.config/foot/`；备份为 `~/.config/foot.backup.20260909_164503_459173`。已打开的 foot 窗口仍用 12，需关掉重开。
- 回滚信息：提交后见 `git log -1`。仓库 `git revert HEAD`；live 恢复：
  ```bash
  cp ~/.config/foot.backup.20260909_164503_459173/foot.ini ~/.config/foot/foot.ini
  ```


## 2026-09-08 — 优化 Starship 提示符信息辨识度

- 目的：落实提示符优化建议，提升开发环境、Git 状态与后台任务的可读性。
- 改动：`.config/shared/starship.toml` 为 Node/Bun/Rust/Python/Docker 增加 Nerd Font 图标，Git 修改状态改为 `~`，新增后台作业数模块，并将命令耗时阈值从 5 秒降至 2 秒；`.config/shared/zsh/README.md` 同步说明。
- 验证：`sh tests/starship_config_test.sh` PASS；`starship explain`、`starship prompt` 均正常；`git diff --check` PASS。
- live 同步：用户随后运行 `./install.sh`，已同步 `~/.config/starship.toml`；备份为 `~/.config/starship.toml.backup.20260908_204519_3469228`，未重载 shell。
- 回滚信息：未提交；仓库可用 `git checkout -- .config/shared/starship.toml .config/shared/zsh/README.md logs/trace.md` 回退，live 可执行 `cp ~/.config/starship.toml.backup.20260908_204519_3469228 ~/.config/starship.toml` 恢复。


## 2026-09-07 — ChatGPT 桌面版迁原生 Wayland（live 实测通过后按 obsidian 链路入仓库）

- 目的：ChatGPT 桌面版（deb chatgpt 26.901.51231，Electron/Chromium 152）默认 `--ozone-platform=x11`，在 niri 下以 XWayland 运行，fcitx5 只能走 XIM；XIM preedit 不同步导致输入框"半道上屏 + 多出空格"。用户要求先只改 live 验证有效再入仓库。
- 改动（live 先落地，用户实测中文输入正常后入仓库）：
  1. live：新增 `~/.config/scripts/chatgpt-wayland` wrapper（Wayland 会话 `exec /usr/lib/chatgpt/ChatGPT --ozone-platform=wayland --enable-wayland-ime "$@"`，X11 透传；Chromium 152 默认 text-input v3，未加 `--wayland-text-input-version=3`，实测也无需 `--disable-vulkan`，与 Obsidian 不同）+ `~/.local/share/applications/chatgpt.desktop` 覆盖系统入口（仅改 Exec，其余字段照抄系统文件）。
  2. 仓库：`.config/scripts/chatgpt-wayland`（与 live 同内容）、`.config/linux/desktop-entries/chatgpt.desktop`（用 `__HOME__` 占位符 + 注释，按 obsidian.desktop 模式）、`install.sh` `linux_wayland_configs` 两条部署项、`tests/wayland_scripts_test.sh` 新增 `test_chatgpt_wayland_forces_native_wayland`、`tests/install_wayland_test.sh` 两条断言、`desktop-entries/README.md`/`scripts/README.md`/`niri/README.md` 收录、`memory/desktop.md` 矩阵补 XIM preedit 不同步根因条目。
- 验证：live 侧——退出旧 X11 实例后经 `gtk-launch chatgpt` 从新入口拉起，renderer 进程 3 个均带 `--ozone-platform=wayland`、`--enable-wayland-ime` 命中；niri App ID 由 `Chatgpt`（X11 WM_CLASS）变 `chatgpt`（原生 Wayland）；`xlsclients` 不再列出（脱离 XWayland）。**用户实测 ChatGPT 输入框打中文：候选框正常弹出、无多余空格、无提前上屏**。仓库侧——`bash -n` wrapper、`desktop-file-validate` 通过；`tests/wayland_scripts_test.sh` / `install_wayland_test.sh` / `run.sh fast` PASS。
- 回滚信息：未提交（仓库改动：`.config/scripts/chatgpt-wayland`、`.config/linux/desktop-entries/chatgpt.desktop`、`install.sh`、`tests/wayland_scripts_test.sh`、`tests/install_wayland_test.sh`、三份 README、`memory/desktop.md`）。`git checkout -- <file>` 即回滚；live 文件为新增（原 `~/.local/share/applications/chatgpt.desktop` 不存在、无旧备份），恢复命令：
  ```bash
  rm ~/.local/share/applications/chatgpt.desktop ~/.config/scripts/chatgpt-wayland
  # 删除后系统入口 /usr/share/applications/chatgpt.desktop 自动接管（Exec=chatgpt → X11）
  ```
- 后续可能方向：① 若日后 app 渲染/GPU 异常，按 Obsidian 先例试 `--disable-vulkan`；② 终端 `chatgpt` 命令仍走 X11（走 codex-launcher 透传），如需统一可后续调整；③ live `~/.local/share/applications/chatgpt.desktop` 是手写绝对路径版，重跑 install.sh 会换成仓库的 `__HOME__` 占位符版（部署时重写为同一路径，行为不变）。踩坑：`pkill -f '/usr/lib/chatgpt/ChatGPT'` 会匹配到自身 shell 命令行（`-f` 匹配完整 argv），把执行命令的 shell 一起杀掉，需避免用与命令文本相同的模式。


## 2026-09-07 — 钉钉等 X11 应用粘贴不到截图图片：根因定位 + X11 轮询剪贴板桥（clipboard-wayland）

- 目的：解决"截图后 Ctrl+V 图片无法粘贴到钉钉等 X11 应用"。上一轮修改（persist `--ignore-event-on-error`、`wl-copy -t image/png`）只修了 Wayland 侧旧文本回写，与 X11 桥无关，故"还是有问题"。
- 根因（运行时证据）：① Wayland 剪贴板有 `image/png`（Chrome 等 Wayland 应用可贴）✓；② 钉钉 App ID `com.alibabainc.dingtalk`、PID 即 xwayland-satellite 进程 = X11 应用（CEF 109，仓库 dingtalk-wayland 已记录原生 Wayland 会崩，不可行）✓；③ X11 侧 `xclip -t TARGETS` 只有 `UTF8_STRING`，无 image/png，内容停留在陈旧"支"✓；④ 全新 :3 卫星实例（RUST_LOG=debug）wl-copy 后无任何反应，日志从未出现 "Clipboard set from Wayland"，只响应 X11 侧 → 卫星收不到/不处理 Wayland 剪贴板事件，双向均失效；⑤ 卫星源码为通用 MIME 透传（非纯文本），失败在事件送达；⑥ 社区共识：niri 不做 X11↔Wayland 剪贴板同步，QQ/微信等需自写轮询同步脚本。
- 改动：① `clipboard-wayland` `start` 守护新增 `start_x11_bridge`：每 0.5s 轮询两侧，双向同步文本与 image/png、jpeg、gif，内容哈希去抖防回环；文本方向带目标守卫（X11 需 UTF8_STRING/STRING/TEXT/text/plain，Wayland 需 text/*），避免图片字节被当文本推回覆盖；仅在有 `xclip` + `DISPLAY` 时启动，纳入父脚本 cleanup/监管（bridge_pid），缺依赖降级跳过。② **两轮守卫迭代 + 快照单次读取**：图片分支加字节数守卫（sha256 对空输入仍输出非空哈希，复制瞬间读到空选区会误推空图并污染去抖状态）；文本分支从命令替换 `$(...)` 改为管道读取（命令替换会剥离尾部换行、丢弃 NUL，导致跨桥文本不保真）；随后统一改为**快照单次读取**——每轮把源内容落到 `/tmp/clipboard-wayland-bridge.snap.$$` 临时文件 1 次，`-s` 判空/`sha256sum < snap` 哈希/`cat snap` 推送全部复用同一份（`trap` 清理），源读取从每轮 2~3 次降到 1 次，判空与哈希不再有 TOCTOU。③ `tests/wayland_scripts_test.sh` 同步断言（含桥与两处守卫）。④ `niri/README.md`、`scripts/README.md`、`memory/niri.md` 同步。
- 验证：`bash -n` + `./tests/wayland_scripts_test.sh` PASS；live 运行时实测：文本四向（含字节保真）、图片 hash 与原图一致；imgA/imgB/imgA 连续复制发现"空选区→空哈希→误推空图"竞态，加守卫后修复（该轮实测中 X11 侧曾短暂出现空图，根因即空哈希误判）。踩坑：`xclip -i` 内部 exec `cat`，测试桥时最小 PATH 必须含 cat；去抖把"已同步的同一图片"正确判为无需再推。
- 回滚信息：未提交（仓库侧改动：`.config/scripts/clipboard-wayland`、`tests/wayland_scripts_test.sh`、`.config/linux/niri/README.md`、`.config/scripts/README.md`、`memory/niri.md`）。`git checkout -- <file>` 即回滚。live 同步被 IDE 白名单拦截，须用户手动执行（agent 已先创建 live 快照 `~/.config/scripts/clipboard-wayland.backup.20260907_152452_2678492`）。同步命令：
  ```bash
  cp .config/scripts/clipboard-wayland ~/.config/scripts/clipboard-wayland
  # 重启守护使桥生效（旧守护 PID 1971930 无桥）
  pkill -f 'clipboard-wayland start'; sleep 1
  nohup "$HOME/.config/scripts/clipboard-wayland" start >>/tmp/clipboard-wayland.log 2>&1 &
  # 验证桥进程在跑
  ps -ef | grep -E 'clipboard-wayland start|wl-clip-persist|wl-paste --watch'
  ```
  恢复命令（live 出问题时从快照恢复）：
  ```bash
  cp -a ~/.config/scripts/clipboard-wayland.backup.20260907_152452_2678492 ~/.config/scripts/clipboard-wayland
  pkill -f 'clipboard-wayland start'; nohup "$HOME/.config/scripts/clipboard-wayland" start >>/tmp/clipboard-wayland.log 2>&1 &
  ```
  旧 live 备份按"保留 3 份"清理（`ls -1t ~/.config/scripts/clipboard-wayland.backup.* | tail -n +4 | xargs rm -f`），agent 已尝试清理但同样被白名单拦截，需用户执行。
- 后续可能方向：① live 重启守护后实测钉钉粘贴；② 观察桥轮询 CPU/功耗（0.5s 间隔，进程开销集中在 xclip/wl-paste 轮询）；③ 若卫星后续版本修复事件送达，可评估移除轮询桥。
