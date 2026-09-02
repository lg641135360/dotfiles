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


## 2026-09-01 — niri 浮动切换改绑 Mod+Ctrl+F

- 目的：回答用户对 niri 键位配置的合理性审查（Mod+`/Mod+Tab 无重复、waybar 左侧是 workspace 指示器 + 分隔符 + 窗口标题、J/K 双职保留），并按用户确认把浮动切换从 `Mod+Ctrl+Space` 改到 `Mod+Ctrl+F`。
- 改动：① `.config/linux/niri/common.kdl` 的 `toggle-window-floating` 从 `Mod+Ctrl+Space` 改为 `Mod+Ctrl+F`（原 `Mod+Ctrl+F` 因与 `Mod+F` 重复于 2026-08-31 释放，现复用于浮动，无冲突）；② README 键位表同步；③ `tests/niri_config_test.sh` 两处断言更新（`assert_contains Mod+Ctrl+F`、`assert_not_contains Mod+Ctrl+F { expand-column... }`）；④ `memory/niri.md` 键位条同步补记复用缘由。
- 验证：`./tests/niri_config_test.sh` PASS；`git diff --check` 干净。
- 回滚信息：未提交。repo 侧改动均可 `git checkout -- <file>` 或后续 `git revert` 回滚；live `~/.config/niri/common.kdl` 未同步（niri 26.04 自动监视配置文件，如需热生效需手动把 common.kdl 复制到 live，复制前先做 `*.backup.<TS>` 快照）。
- 后续可能方向：无。


## 2026-09-01 — foot.ini 实用配置与微优化（selection-target / bell / url style / alpha-mode / indicator-format / word-delimiters）

- 目的：升级 1.27 后补充实用配置——框选同时进剪贴板历史（配合 wl-clip-persist/cliphist）、后台响铃 urgent、URL 实线下划线、整窗均匀透明、滚动位置百分比、双击选词追加代码字符；并纠正 memory/README 中"foot 无模糊能力"的过时描述（1.27 `+blur` 构建已支持 `ext-background-effect-v1`，但 niri 全局 window-rule 已对 foot 启用 blur，重复开启无额外效果；且经核实 niri 26.04 未实现 `xdg-toplevel-tag-v1`，故 blur / toplevel-tag 均不配置）。
- 改动：① `.config/linux/foot/foot.ini` 新增 `selection-target=both`、`[bell] urgent=yes`、`[url] style=single`、`alpha-mode=all`、`indicator-format=percentage`、`word-delimiters`（默认集追加 `./=+-*%$@!?~^`，避开 `;`/`#` 注释语义冲突）；② `tests/foot_config_test.sh` 的 `test_practical_additions` 断言六项；③ foot README 与 `memory/foot.md` 同步（新增说明 + 修正 blur 描述）。
- 验证：`foot -c .config/linux/foot/foot.ini -C` exit 0（1.27 校验）；`bash tests/foot_config_test.sh` PASS；`git diff --check` 干净。注：本终端 `sh`/dash 执行任何脚本均零输出（含 `echo hi`，rc=0），为终端环境既有怪癖，故用 bash 验证；若影响 `./tests/run.sh` 聚合需单独排查。
- 回滚信息：已提交 `e28819a`（含本条目仓库侧全部改动）；live 同步走 `./install.sh`（检测 `command -v foot` 通过后复制 `.config/linux/foot/` → `~/.config/foot/`，自动 `mv` 备份为 `~/.config/foot.backup.<TS>` 并保留 3 份）；agent 终端因 IDE 白名单不能直接写 `~/.config/foot`，故由用户执行同步。恢复命令：
  ```bash
  cp -a ~/.config/foot.backup.<TS> ~/.config/foot
  ```
  repo 侧 `git revert e28819a` 即回滚。
- 后续可能方向：① 日常观察 selection-target=both 是否让框选内容进入 cliphist 历史、bell urgent 是否按预期在 niri 指示器提示；② dash 零输出问题若影响 run.sh 聚合，需单独定位。


## 2026-09-01 — 清理陈旧 wayland-protocols 残留（修复 pkg-config 误报 1.32）

- 目的：删除 4 月手工安装遗留的 wayland-protocols 1.32 残留，消除其对 apt 1.47 的 pkg-config 遮蔽（此前导致 foot 编译回退捆绑 1.49 子工程、DTD 校验失败）。
- 改动（用户执行）：`sudo rm /usr/local/share/pkgconfig/wayland-protocols.pc` + `sudo rm -r /usr/local/share/wayland-protocols`（同源陈旧数据目录一并清理）。
- 验证：两路径均已不存在；`pkg-config --modversion wayland-protocols` 默认返回 **1.47**（无需 `PKG_CONFIG_PATH` 覆盖）；系统 1.47 数据 `/usr/share/wayland-protocols`（含 ext-background-effect/xdg-toplevel-tag）完整；`foot --version` = 1.27.0 正常。
- 回滚信息：纯系统变更（删的是旧手工安装残留、无保留价值），仓库侧已随 `e28819a` 提交。还原入口：`sudo apt-get reinstall wayland-protocols`（提供系统 1.47，无需还原 1.32 残留）。repo 侧 `git revert e28819a` 即回滚。
- 后续可能方向：foot 后续升级编译不再需要 `PKG_CONFIG_PATH` 覆盖，直接用 memory/foot.md 中的简化命令即可。


## 2026-09-01 — 编译安装 foot 1.27.0 到 /usr/local（resolute 机器，系统 fcft 3.3.2）

- 目的：本机（Ubuntu resolute/26.04）apt foot 仅 1.25.0-1（resolute/universe，中科大镜像），上游最新 1.27.0；用户确认源码编译安装到 `/usr/local`，apt 1.25.0 保留作回退。
- 系统改动：① `sudo apt-get install -y libfcft-dev libutf8proc-dev scdoc`（resolute `libfcft-dev` 已 3.3.2 满足 fcft≥3.3.1，无需再 clone fcft/tllist 子工程）；② `git clone --branch 1.27.0` 到 `~/build/foot`；③ **踩坑**：pkg-config 误报 wayland-protocols 1.32 致 meson 回退捆绑 1.49 子工程，其新 XML 超出系统 wayland-scanner 1.24.0 DTD 校验失败——根因 `/usr/local/share/pkgconfig/wayland-protocols.pc`（1.32 陈旧残留）优先级高于 apt 1.47；修复：`PKG_CONFIG_PATH=/usr/share/pkgconfig meson setup --wipe build --buildtype=release -Dime=true -Dgrapheme-clustering=enabled -Ddocs=enabled -Dthemes=true`（系统 wayland-protocols 1.47 含 toplevel-tag/background-effect，1.24.0 scanner 可处理），`ninja -C build` 全过；④ `sudo meson install -C build` → `/usr/local/bin/foot`。
- 验证：`which foot` = `/usr/local/bin/foot`；`foot --version` = `1.27.0 +ime +graphemes +toplevel-tag +blur -assertions`（本次未做 PGO，故无 `+pgo`）；`/usr/bin/foot` 1.25.0 仍在作回退；footclient/docs 就位；`foot -c .config/linux/foot/foot.ini -C` exit 0（1.27 `[colors-dark]` 兼容，仓库配置无需改动）。
- 回滚信息：仓库侧已随 `e28819a` 提交（trace 归档/memory 更新）；系统变更部分恢复命令：
  ```bash
  sudo meson uninstall -C ~/build/foot/build   # 移除全部 /usr/local 产物，回落 apt 1.25.0
  ```
  repo 侧 `git revert e28819a` 即回滚。
- 后续可能方向：① 建议清理陈旧残留 `/usr/local/share/pkgconfig/wayland-protocols.pc`（1.32），否则其它构建项目仍会误判 wayland-protocols 版本；② 用户实测 niri 下 1.27 渲染/透明度/IME；③ 日后升级：`~/build/foot` 更新 tag 后 `PKG_CONFIG_PATH=/usr/share/pkgconfig ninja -C build && sudo meson install -C build`。


## 2026-08-31 — 激进瘦身：卸载 rust + llvm@22（合计释放约 3.3G）

- 目的：用户确认激进瘦身——删除 Rust 工具链（rust 1.98.0 + 其依赖 llvm@22 2.6G），预期仅失去 cargo/rustc 等，starship 与 clangd 不受影响。
- 已做：① `brew uninstall rust`（1.98.0，7,328 文件，502.4MB）——Homebrew 6.0.20 在 uninstall 时自动触发 autoremove，顺带移除 20 个孤儿依赖：llvm@22（9,051 文件，2.7GB）、curl、brotli、cyrus-sasl、keyutils、krb5、libedit、libffi、libidn2、libnghttp2、libnghttp3、libngtcp2、libpsl、libunistring、libxcrypt、openldap、pkgconf、readline、sqlite、util-linux（合计约 300MB）；② `brew autoremove` 收尾清理 autoremove 遗留的旧版孤儿 libpsl 0.23.1 + pkgconf 3.0.5（约 2MB）。
- 验证：`brew missing` 无缺失（exit 0）；剩余 formula 36 个、叶子包 7 个（bat fzf herdr lsd neovim tmux zoxide）；冒烟测试 starship 1.26.0（`~/.cargo/bin/starship`，独立二进制，exit 0）/nvim/tmux/bat/fzf/lsd/zoxide/herdr 全部正常，git/gcc 走系统 `/usr/bin` 不受影响；`cargo`/`rustc` 已按预期移除；`Cellar/rust` 与 `Cellar/llvm@22` 目录已删，Cellar 总量降至 1.3G。
- 回滚信息：未提交（仓库仅 trace 记录，纯系统变更）。恢复命令：`brew install rust`（llvm@22 作为依赖自动装回）。本会话累计释放：gcc@14 372MB + rust 清理 646MB + 本轮 ~3.3G ≈ **4.3G**。
- 后续可能方向：① 日常观察无 cargo/rustc 后是否有遗漏引用（path.zsh 的 `~/.cargo/bin` 保留，starship 仍可从此加载）；② Linux Brewfile 与当前实际安装不一致（Brewfile 声明 fd/ripgrep/yazi 未安装，且未含 lsd/tmux/herdr），可择机同步；③ `brew outdated` 有 neovim/tree-sitter/unibilium 可升级；④ 若日后需要 Rust（cargo install 等），`brew install rust` 即回。


## 2026-08-31 — brew cleanup rust 清理旧版残留 1.97.1（释放 515.3MB）

- 目的：brew 体检发现 rust 在 Cellar 有新旧两版（1.98.0 在用 + 1.97.1 旧残留）。先干跑 `brew cleanup -n rust` 确认删除范围与无风险后，经用户确认执行清理。
- 干跑确认：`brew cleanup -n rust` 将删除 ① `Cellar/rust/1.97.1`（7,256 文件，515.3MB）、② 缓存 `~/.cache/Homebrew/rust--1.97.1.arm64_linux.bottle.tar.gz`（131.1MB）、③ `rust_bottle_manifest--1.97.1`（154KB），合计约 646.6MB。风险核对：`opt/rust` → `Cellar/rust/1.98.0`、`bin/rustc`/`bin/cargo` 均链接 1.98.0，无任何包依赖 rust，starship（`~/.cargo/bin` 独立二进制）不受影响。
- 已做：`brew cleanup rust` 执行成功（"This operation has freed approximately 515.3MB"——实际只报了 Cellar 部分，缓存另有 ~131MB 一并清除）。
- 验证：`Cellar/rust/` 仅剩 1.98.0；`brew list --versions rust` = `rust 1.98.0`；`rustc 1.98.0` / `cargo 1.98.0` 运行正常；缓存中 `rust--1.97.1.*` 已消失（`rust_bottle_manifest--1.98.0` 为当前版，保留）。
- 回滚信息：未提交（仓库仅 trace 记录，纯系统变更）。恢复命令：`brew install rust`（装回当前 1.98.0；1.97.1 为旧版残留无需还原）。
- 后续可能方向：① rust（1.98.0 约 497M）+ llvm@22（2.6G，rust 依赖）仍是激进瘦身候选（合计约 3.6G），删除影响仅失去 Rust 工具链（starship/clangd 均不受影响），待用户决定；② `brew cleanup`（不带参数）可再清理其它旧版本残留与缓存（如 gcc@14 遗留 manifest 等）。


## 2026-08-31 — foot.ini 迁移 [colors] → [colors-dark]（消除 1.27 deprecation 警告）

- 目的：升级 foot 1.27.0 后旧 `[colors]` 区块弃用，每开一个窗口打印多行 `deprecated: foot: [colors]: use [colors-dark] instead`。
- 改动（仓库）：① `.config/linux/foot/foot.ini`：`[colors]` → `[colors-dark]`（foot 1.27 默认主题即 colors-dark，键名含 alpha 全部不变），加注释；② `tests/foot_config_test.sh`：`test_catppuccin_mocha_palette` 补 `assert_matches '^\[colors-dark\]$'` + `assert_not_matches '^\[colors\]$'` 防回归；③ `.config/linux/foot/README.md`：新增「palette 区块」说明（dark/light 切换方式）；④ `memory/foot.md`：安装与升级节补 1.27 主题迁移经验。
- 验证：`bash tests/foot_config_test.sh` PASS；`foot -c .config/linux/foot/foot.ini -C` exit 0 且无 warn（live 旧配置 `foot -C` 复现 deprecated 警告，确证根因）；`git diff --check` 干净。
- live 同步：IDE 沙箱不允许写 `~/.config/foot/foot.ini`（不在白名单，与 niri common.kdl / waybar 同类），需用户手动复制。备份：`~/.config/foot/foot.ini.backup.20260831_224246`（旧版快照，同步后按保留 3 份惯例清理更旧者）。恢复命令：`cp ~/.config/foot/foot.ini.backup.20260831_224246 ~/.config/foot/foot.ini`。同步命令：`cp ~/Documents/dotfiles/.config/linux/foot/foot.ini ~/.config/foot/foot.ini`。
- 回滚信息：未提交；repo 侧 `git checkout -- .config/linux/foot/foot.ini tests/foot_config_test.sh .config/linux/foot/README.md memory/foot.md logs/trace.md` 即回滚。
- 后续可能方向：① 用户手动同步 live 后新开 foot，应不再出现 deprecation 警告；② 若想用浅色主题，可加 `[colors-light]` 并用 `color-theme-toggle` 键位或 `SIGUSR1/2` 切换；③ live 同步受 IDE 白名单限制，后续 foot.ini 改动手动 cp 即可。


## 2026-08-31 — foot 1.27.0 源码编译安装到 /usr/local（放弃 Linuxbrew 路线）

- 目的：用户要 foot 最新版。Ubuntu noble apt 冻结 1.16.2、无 PPA（foot 冷门 + 依赖 fcft>=3.3.1 缺口，无人维护配对 PPA）。先试 Linuxbrew（brew foot 1.27.0 bottle 装成），但发现被 `/usr/bin/foot` 遮蔽用不上且违背"GUI 走系统源"分层原则，用户决定改源码编译装 `/usr/local`（其 PATH 中 `/usr/local/bin` 在 `/usr/bin` 前，天然生效）。
- 系统改动：① `brew uninstall foot`（keg 删除）+ `brew autoremove`（顺带清 expat / llvm 2.8G / python@3.14 / z3 四个孤儿依赖）；② `chmod 700 ~/.homebrew`（brew 报 `Refusing to write insecure trust store`，根因该目录 group 可写）；③ `sudo apt-get install -y libutf8proc-dev`（grapheme 聚类依赖，其余 dev 包系统已齐）；④ 源码编译 foot 1.27.0：`~/build/foot`（`git clone` fcft/tllist 到 subprojects 补 fcft 3.3.3，因 noble 系统 `libfcft-dev` 仅 3.1.8），`meson setup build --buildtype=release -Dime=true -Dgrapheme-clustering=enabled -Dfcft:grapheme-shaping=enabled -Dfcft:run-shaping=enabled -Dterminfo=enabled -Dthemes=true -Ddocs=enabled`（注意 `-Dime` 是 boolean 只能 `true`，传 `enabled` 报错），`ninja -C build`（165 目标全过），`sudo meson install -C build` → `/usr/local/bin/foot`。
- 验证：`which foot` = `/usr/local/bin/foot`；`foot --version` = `1.27.0 -pgo +ime +graphemes +toplevel-tag +blur`（较系统 1.16.2 多 `+toplevel-tag/+blur`，少 `+pgo`）；`/usr/bin/foot` 1.16.2 仍在作回退；`/usr/local/bin/footclient`、`/usr/local/share/terminfo/f/foot`、`/usr/local/share/man/man1/foot.1` 均就位。
- 回滚信息：未提交（本轮为系统变更 + 仓库 memory/trace 更新）。恢复命令：`sudo meson uninstall -C ~/build/foot/build`（移除全部 `/usr/local` 产物，回落 apt 1.16.2）；brew 侧如需还原 `brew install foot`。repo 侧 `git checkout -- memory/foot.md logs/trace.md` 即回滚。
- 后续可能方向：① 用户实测 niri 下新 foot 渲染/透明度（foot.ini `colors.alpha=0.82`，`+blur` 支持背景模糊）与 IME 中文输入；② 日后升级：`~/build/foot` 更新 tag 后 `ninja -C build && sudo meson install -C build`；③ 上一轮 brew 体检遗留候选（llvm@22 / rust）仍可考虑瘦身。


## 2026-08-31 — 卸载 Linuxbrew gcc@14（最小改动，释放 372MB）

- 目的：brew 包体检发现 gcc@14 为无依赖的"真叶子"（`brew uses --installed gcc@14` 为空），不在 Linux Brewfile 声明内，且系统已提供 gcc-12/13（`/usr/bin/gcc`），brew 的 gcc-14 未遮蔽系统二进制；用户确认仅卸载 gcc@14（最小改动），其余候选（llvm 2.6G / rust+llvm@22 3.6G）暂不动。
- 已做：`brew uninstall gcc@14`，移除 Cellar/gcc@14/14.4.0（1,897 文件，372.3MB）。
- 验证：`brew list --formula` 无 gcc@14（grep 计数 0）、`brew leaves` 不再含 gcc@14（现为 bat fzf herdr lsd neovim rust tmux zoxide）、`Cellar/gcc@14` 目录已删、冒烟 `command -v` bat/fzf/lsd/zoxide/gcc 全部 OK。brew 主 `gcc`（bat/lsd/zoxide 构建依赖）保留未动。
- 回滚信息：未提交（仓库零改动，纯系统变更）。恢复命令：
  ```bash
  brew install gcc@14
  ```
- 后续可能方向：① rust+llvm@22 仍是可删候选（合计约 3.6G）。**2026-08-31 复核纠正**：裸 `llvm` 公式实际未安装（`brew info llvm` = Not installed），系统仅有 llvm@22（22.1.8，2.6G，keg-only，作为 rust 依赖）；clangd 从未在 PATH（无 `~/.local/bin/clangd` 软链、llvm@22 未链接、无 apt clangd），删 rust+llvm@22 不影响 starship（`~/.cargo/bin/starship` 为独立二进制）也不改变 clangd 现状（本就不可用）。`brew cleanup rust` 可先白拿旧版 1.97.1 的 509M（零风险）。② Brewfile 声明但未安装的 fd/ripgrep/yazi 需确认是否有意移除；③ `brew outdated` 有 neovim/tree-sitter/unibilium 可升级。
