# Foot 偏好

## 定位
- foot 是 niri/Wayland 会话的默认终端（2026-08-31 起全平台统一，含 x86_64）：
  - 历史：aarch64 曾因 mtgpu 下 alacritty 0.18.0-dev 在缩放输出内屏 2x 字形损坏、foot 渲染正常而优先 foot；现全平台统一 foot 优先，aarch64 行为不变
  - `alacritty` 仅在 foot 缺失时由 `terminal-wayland` 回退冷启动（`exec alacritty "$@"`）
- `terminal-wayland` 顺序：foot 优先 → alacritty 兜底；已移除 aarch64+Wayland 专用分支与 `uname -m` / `WAYLAND_DISPLAY` 特判
- 不再维护 kitty 配置；原 `.config/linux/kitty/` 已移除，`terminal-wayland` 的兜底分支由 kitty 改为 foot，再于 2026-08-31 将默认终端由 alacritty 改为 foot
- foot 是 Wayland-only 终端（无 X11 / macOS 版本），配置仅放 `.config/linux/foot/`，由 `install.sh` 的 `linux_wayland_dir_configs` 在 `command -v foot` 通过时复制到 `~/.config/foot/`

## 观感对齐
- foot.ini 镜像 `.config/shared/alacritty` 的观感：MesloLGS Nerd Font Mono 13、Catppuccin Mocha 内嵌 palette、`csd.preferred=none`、`pad=12x12`、`colors.alpha=0.82`、`cursor.style=beam` + `blink=yes`、`mouse.hide-when-typing=yes`、`scrollback.lines=50000`、`scrollback.multiplier=3.0`、`term=xterm-256color`。
- `[text-bindings]` 镜像 alacritty 的 `keys.linux.toml`：`Alt+hjkl` 发送 `Ctrl-a hjkl`（tmux 窗格切换），`Alt+方向键` / `Shift+Alt+上下` 发送 xterm 修饰序列供 Neovim 使用。foot 要求 modifier 用 XKB 名称，`Alt` 必须写成 `Mod1`（不能用字面量 `Alt`）。

## 与 alacritty 的差异
- **主题内嵌**：`foot.ini` 直接写 Catppuccin Mocha palette，不依赖外置主题文件（alacritty 需要 clone `alacritty-theme`）。
- **cursor color**：foot 显式 `colors.cursor = 1e1e2e f5e0dc`（text/cursor，foot 1.25 起 `colors.cursor` 取代废弃的 `cursor.color`）以对齐 Catppuccin Mocha；alacritty 走主题默认反转。
- **OSC52**：foot 默认仅允许写剪贴板方向，与 alacritty 的 `terminal.osc52 = "OnlyCopy"` 等价，无需显式配置。
- **窗口模糊**：alacritty 在 Linux 启用 `blur = true`；foot 1.27 `+blur` 构建已支持 `colors.blur=yes`（`ext-background-effect-v1`），但 niri 全局 window-rule 已对 foot 启用 `background-effect { blur true }`，重复开启无额外效果，故 foot 自身不配 blur；透明度由 `colors.alpha = 0.82` 提供（与 alacritty 在 niri 下的实际表现一致）。
- **选中与剪贴板**（2026-09-04 改回 primary）：框选只写 PRIMARY，不覆盖 CLIPBOARD，避免 Chrome `Ctrl+C` 后切到 foot 框选就把内容冲掉。跨应用复制用 `Ctrl+Shift+C`；中键 / `Shift+Insert` 仍可贴刚选内容。框选不再自动进 cliphist。2026-09-01 曾用 `both` 换「选中即入历史」，该代价已撤回。
- **响铃**（2026-09-01）：`[bell] urgent=yes` 后台窗口响铃触发 urgent（niri 指示器提示）。
- **URL 下划线**（2026-09-01）：1.27 起默认点线 `dotted`，`[url] style=single` 改回实线保持旧观感。
- **透明度应用范围**（2026-09-01）：`alpha-mode=all` 整窗均匀半透明，镜像 alacritty opacity（foot 默认仅"默认背景"单元格透明，彩色背景不透明）；代价是彩色高亮也变透。
- **滚动指示**（2026-09-01）：`indicator-format=percentage` 滚动时显示位置百分比。
- **选词边界**（2026-09-01）：`word-delimiters` 默认集追加代码字符 `./=+-*%$@!?~^`（不加入 `;`/`#` 避免 INI 注释语义冲突），双击按标识符整选。

## 透明度取舍
- foot 的 `colors.alpha` 直接采用 0.82，与 alacritty Linux 一致；不再沿用 kitty 之前因 aarch64 mtgpu alpha 合成 bug 而走的 1.0 不透明路径。若后续在 aarch64 内屏 2x 下复现 mtgpu 半透明渲染 bug，再单独评估是否在该硬件上降回不透明。

## 安装与升级（2026-08-31 起，源码编译 /usr/local）
- foot 1.27.0 由源码编译安装到 `/usr/local`（`foot --version` = `1.27.0 -pgo +ime +graphemes +toplevel-tag +blur`），`/usr/bin/foot` 1.16.2（apt）保留作回退；PATH 中 `/usr/local/bin`（第 5 位）在 `/usr/bin`（第 7 位）前，`foot` 天然解析到新版，无需改 PATH。
- 曾试 Linuxbrew 路线后放弃：brew foot 的 bin 在 `path.zsh` 里是 `pathappend`（PATH 末尾），`foot` 被 `/usr/bin/foot` 遮蔽用不上；且 foot 属 GUI/桌面组件，按分层原则应走系统源。已 `brew uninstall foot` + `brew autoremove`。
- 编译踩坑（可复用）：
  - noble 的 `libfcft-dev` 仅 3.1.8，不满足 foot 1.27 的 fcft>=3.3.1，必须源码子工程：`git clone` fcft、tllist 到 `subprojects/`，meson 自动 fallback 静态链接（fcft 3.3.3）。
  - meson 选项类型：`-Dime` 是 **boolean** 只能 `-Dime=true`（传 `enabled` 报 `Value enabled is not boolean`）；`-Dgrapheme-clustering` 是 feature 可传 `enabled`；fcft 的 `-Dfcft:grapheme-shaping=enabled -Dfcft:run-shaping=enabled` 为 feature 类型 OK。
  - 编译依赖仅需补装 `libutf8proc-dev`（grapheme 聚类，pkg-config 名 `libutf8proc`），其余 pixman/fontconfig/freetype/harfbuzz/wayland dev、wayland-protocols、tic、python3 系统自带。
  - brew 偶发 `Refusing to write insecure trust store`：`~/.homebrew` 目录 group/world 可写导致，`chmod 700 ~/.homebrew` 修复。
- 源码/构建目录：`~/build/foot`（含 subprojects/fcft、tllist）。日后升级：更新 tag 覆盖源码 → `ninja -C build` → `sudo meson install -C build`。
- 卸载/回退：`sudo meson uninstall -C ~/build/foot/build` 即移除全部 `/usr/local` 产物，回落系统 apt 版本（noble 1.16.2 / resolute 1.25.0）。
- **resolute 机器（2026-09-01）**：apt foot 为 1.25.0-1，已源码编译 1.27.0 到 `/usr/local`（产物 `1.27.0 +ime +graphemes +toplevel-tag +blur`，未做 PGO）。与 noble 差异：resolute `libfcft-dev` 3.3.2 直接满足 fcft≥3.3.1，**无需 clone fcft/tllist 子工程**。**踩过的坑（已修复 2026-09-01）**：`/usr/local/share/pkgconfig/wayland-protocols.pc`（1.32 陈旧残留）优先级高于 apt 的 1.47，致 pkg-config 误报 1.32、meson 回退捆绑 1.49 子工程后 DTD 校验失败（系统 wayland-scanner 1.24.0 不认其新 XML）；当时以 `PKG_CONFIG_PATH=/usr/share/pkgconfig` 绕过，后连同数据目录 `/usr/local/share/wayland-protocols` 一并删除，现默认即 1.47，编译无需再带覆盖。构建配置：`meson setup --wipe build --buildtype=release -Dime=true -Dgrapheme-clustering=enabled -Ddocs=enabled -Dthemes=true`；升级命令：`ninja -C ~/build/foot/build && sudo meson install -C ~/build/foot/build`。
- **1.27 主题迁移**：foot 1.27 起旧 `[colors]` 区块弃用（每窗口打印 `deprecated: use [colors-dark] instead`），palette 需放 `[colors-dark]`（默认主题）/`[colors-light]`（可配 `color-theme-toggle` 键位或 `SIGUSR1/2` 切换）；键名含 `alpha` 全部不变。已迁移（2026-08-31）。校验配置：`foot -c <file> -C`（exit 0 通过）。live 同步走 `./install.sh`（自动备份 + 保留 3 份）；agent 终端受 IDE 白名单限制不能直接写 `~/.config/foot`。
