# 桌面与工具偏好

## macOS 窗口管理器（2026-09-30 决策）
- 按机型二选一：**黑苹果 x86_64（i5-8250U / macOS 15.x）首选 yabai + skhd**；**白苹果（Apple Silicon / 官方硬件）首选 AeroSpace**。两者都用 `alt` 作 Mod，**不要同机同跑**；配置分别在 `.config/macos/yabai/` 与 `.config/macos/aerospace/`，`install.sh` 按命令可用性分别部署。
- yabai 走官方预编译 release 装到 `~/.local/bin`（skhd 无预编译产物，走 MacPorts）。预编译二进制已由维护者自签（`Authority=yabai-cert`、`Identifier=com.asmvik.yabai`），**不需要本机建证书/重签**，TCC 辅助功能授权能跨 yabai 升级保留；`spctl` 判 `rejected` 无害，但只能用 `curl` 下载（浏览器会加 quarantine 被 Gatekeeper 拦）。MacPorts 版 yabai 是源码编译，必须自建 `yabai-cert` 签名且每次 `port upgrade` 后重签 + 重算 sudoers 哈希，故不采用。
- macOS 系统升级**不需要重新签名**（签名在二进制上）；但 SA 载荷与系统版本绑定，点版本升级后通常要配套升级 yabai 并重跑 `sudo yabai --load-sa`；报 `failed to inject payload` 时先升级 yabai，再怀疑 SIP/签名。
- 黑苹果 SIP 状态由 OpenCore `csr-active-config` 决定（当前 `0x0FFF` 全关），**不要**用 `csrutil` 调整（会破坏 OCLP-Mod root patch）；SA 免密条目在 `/private/etc/sudoers.d/yabai`，绑的是 yabai 二进制的 sha256，只有换 yabai 版本时才需要更新。
- **yabai 工作区模型（2026-09-30 用户决策）：只有 index 1..5，不用命名工作区。** 直接用 mission-control index 寻址，**不对空间打任何标签**；原来沿袭 AeroSpace 的 `C(ode)/B(rowser)/N(ote)/W(echat)` 已取消（`Mod+C/B/N/W` 随之释放），也不再有 `space=` 规则。`yabairc` 的 `ensure_spaces` 只保证空间数 ≥ 5（只建不删）。
- **焦点/插入反馈色统一用 Catppuccin Mocha 蓝 `0xff89b4fa`**（2026-09-30 对齐决策）：仓库 Linux 两侧也是蓝（niri `focus-ring active-color`、awesome `border_focus`/`fg_focus`），仅 aerospace 的 JankyBorders `active_color` 还是 mauve `0xffcba6f7`（待对齐）。
- **焦点边框 JankyBorders（2026-10-01 落地）**：yabai 6.0+ 已移除内置窗口边框，黑苹果用 JankyBorders 补：不需要 TCC 授权（不依赖辅助功能 API）；MacPorts 无端口、本机无 brew ⇒ 源码编译（`~/.cache/jankyborders-src` + `make`，装 `~/.local/bin/borders` 与 man 页 `~/.local/share/man/man1/borders.1`）。`yabairc` 末尾以 `command -v borders` 守卫启动（`active_color=0xff89b4fa` 焦点蓝、`inactive_color=0x00494d64` 透明、`width=5.0` 对齐 aerospace）；重复启动只更新已有实例属性，不堆进程；验证 `pgrep -x borders`。
- **按键扩展（2026-10-01）**：`Mod+N` 最小化（对齐 awesome）、`Mod+Ctrl+h/j/k/l` warp（重新插入、不交换）、`Mod+Ctrl+s` 切换当前分割轴（源码 `space_manager_toggle_window_split`：仅 BSP 且窗口是中间节点，否则 no-op）、`Mod+Ctrl+r` 重载（`yabai --restart-service`，对齐 awesome 的 `Mod+Ctrl+R`）；`Mod+C/B/W` 仍空闲。Alacritty 是 `Mod+Return` 的依赖（本机走 MacPorts，`darwin_24.x86_64` 有二进制归档）；主题自动 clone 只在 install.sh 的 Linux 分支，macOS 手动 clone。
- **键盘映射 Karabiner-Elements（2026-10-01 落地）**：Caps Lock 按住 = Control（`to` 里 `lazy: true`，单独按不发键）、单击 = Escape（`to_if_alone`）；配置纳入仓库 `.config/macos/karabiner/karabiner.json`（唯一事实来源，GUI 改动会被下次部署覆盖，需回填），install.sh 以 `/Applications/Karabiner-Elements.app` 存在为门控部署到 `~/.config/karabiner/`。本机 16.3.0，DriverKit 扩展在 SIP 全关（OpenCore 0x0FFF）下实测 `activated enabled`，授权后 `core_service` 正常；Karabiner 监听配置文件热重载，覆盖后无需重启。MacPorts 无端口，黑苹果走官网 dmg（白苹果可 `brew install --cask karabiner-elements`，未收录 Brewfile）。**另：本机内置键盘是 Windows 布局**（HID 报 vendor 1452 / product 65535，VoodooPS2 伪装）：Win/Alt 互换（`left/right_command` ↔ `left/right_option`）写在 **profile 的 `devices[]` 设备条目**（设备级 `simple_modifications`，Karabiner 自动附加 device_if；**⚠ profile 级 `simple_modifications` 条目不支持 `conditions`**——16.3.0 实测报 `json error: Unknown key: conditions` 并整条丢弃）；`escape → caps_lock` 则**必须写成 complex modification + 手写 `device_if`**——Karabiner 流水线是 `device_key_code → simple_modifications → complex_modifications → fn_function_keys → 虚拟键盘`（`device_grabber` 的 `manipulator_managers_connector` 串联），simple 层输出会再进 complex 层被 Caps 规则（`caps_lock → Ctrl/Esc`）吃掉，实测症状是"按 Esc 没反应"（等同又发一个 Esc）。互换后 **Option（skhd Mod）在物理 Win 键、Command 在物理 Alt 键**，物理 Esc = 大写锁定；外接 Apple 布局键盘与白苹果（product id 不同）不受影响；改全局 = 把映射挪到 profile 级条目（无设备限定）。
- yabai 实机踩坑（2026-09-30 v7.1.25 / macOS 15.8 / AppleLocale=zh_CN 实测，写配置前必读）：① **纯数字不能当标签**（`space --label 1` → `'1' cannot be used as a label.`；label 必须是字符串 token，否则与 mission-control index 在 `SPACE_SEL` 里撞车）——这是本配置彻底不用标签的直接原因；② `space --create` **不会**把焦点移到新空间，且新建后 `query --spaces` 不一定马上反映 ⇒ 补空间的循环必须用本地计数推进；③ `space --label` 不带 SPACE_SEL 时作用于**当前聚焦空间**（若以后重新引入标签，①②③叠加会把所有标签反复打在同一个空间上——首版实测 7 个空间全建好、标签只剩最后一个 `W` 落在 index 1）；④ yabai 在**注册规则时**就校验 `SPACE_SEL`，标签不存在会整条拒掉（日志 `value 'C' is not a valid option for SPACE_SEL`），加 `space=` 规则前必须先确认目标空间/标签存在。
- yabai 规则的另外两条硬约束：① **`app=` 匹配的是本地化应用名**（yabai 取进程名 `CopyProcessName`，本机 zh_CN 下 Finder 报「访达」、Spotlight 报「聚焦」、微信报「微信」、系统设置报「系统设置」），只写英文名会**静默不匹配**；离线核对用 `mdls -name kMDItemDisplayName -raw <App.app>`，在线核对用 `yabai -m query --windows` 的 `app` 字段；规则也不支持 bundle-id，只能用中英 alternation（2026-10-02 修正：首版 `^Finder$`/`^Spotlight$` 从未命中，Finder 窗口被平铺而非浮动）；② **规则只对注册之后新出现的窗口生效**，已开着的窗口需要 `yabai -m rule --apply` 回放（当前只剩浮动规则，回放没有跨空间搬窗口的副作用）。
- **yabai 的窗口 sub-layer 是“窗口总在后面/总在前面”类症状的根因（2026-10-02 定位）**：托管（平铺）窗口被 SA 设成 sub-level `-20`（`below` = `kCGBackstopMenuLevel`，实现为 `SLSSetWindowSubLevel`，设计见上游 issue #1887），浮动 / `manage=off` / yabai 未跟踪的窗口留在 `normal`(`0`)；**层级优先于焦点**，所以 below 的窗口无论如何激活都在后面，normal 的窗口则永远盖住平铺窗口（如 `Mod+e` 打开的资源库窗口“在后面”）。排障：`yabai -m query --windows` 看 `sub-layer`/`has-ax-reference`；`--window <id>` 报 `could not locate window with the specified id` ⇒ 孤儿窗口（不在窗口表里，只能关掉重开该窗口恢复托管，`rule --apply` 无效）；真要平铺窗口盖住未托管窗口可用 `rule --add app=".*" sub-layer=normal`（代价 = stack 里最上面的窗口永远最前，issue #2402，默认不采用）。
- yabai 配置验证手段（skhd 无 dry-run，没有 `niri validate` 那种入口）：`sh -n ~/.config/yabai/yabairc`、`yabai -m query --spaces`（能跑 ⇒ SA 已加载）、`yabai -m rule --list`、`yabai -m signal --list`，日志在 `/tmp/{yabai,skhd}_rikoo.{out,err}.log`；`tests/yabai_config_test.sh` 会解析 skhdrc 并与期望绑定表**逐条比对**（缺/重复/未登记的额外绑定都会失败），改绑定时必须同步**配置、README 键位表、测试表**三处。
- yabai `--resize` 的 handle 语义（`src/window_manager.c` 的 `window_manager_resize_window_relative`）：handle 指的是**被拖动的 fence**——`first_child`（左/上）只有东/南 fence，`second_child`（右/下）只有西/北 fence；占满整屏的单窗口两边都没有 fence。因此单个 handle 有**半数情况**报 `cannot locate a bsp node fence`，配置里要按 右→左→下→上 依次尝试（等效 AeroSpace 的 `resize smart`），并 `2>/dev/null` 避免失败尝试刷进 `/tmp/skhd_*.err.log`。
- `--load-sa` 的语义是 **Install** and load：会把 SA 装到 `/Library/ScriptingAdditions/yabai.osax`（loader + payload.bundle），每次开机/Dock 重启都要重新注入（由 `yabairc` 的 `dock_did_restart` signal 负责）；所有失败情形都会打 stderr（`src/osax/loader.m`），**退出码 0 且无输出即成功**；卸载用 `sudo yabai --uninstall-sa`。skhd 没有 dry-run，未授权辅助功能时直接 `must be run with accessibility access! abort..`，所以 skhdrc 的键位只能等授权后由 skhd 自己解析验证（解析错误会进 `/tmp/skhd_<user>.err.log`）。

## LinearMouse（macOS 指针设备定制，2026-10-01 纳入仓库）
- 配置 `.config/macos/linearmouse/linearmouse.json` 为唯一事实来源，`install.sh` 以 `/Applications/LinearMouse.app` 门控部署到 `~/.config/linearmouse/linearmouse.json`；GUI 改动会直接重写 live 文件，改完需回填仓库（同 Karabiner 惯例）。
- 唯一 scheme 只作用 Razer Viper V2 Pro（`0x1532/0xa6`）：`scrolling.reverse.vertical=true`（鼠标反向、系统保持自然滚动、触控板不受影响）+ `universalBackForward=true`（侧键后退/前进）；原两条 trackpad no-op 方案已删。
- 设备匹配 = 字段全等、未写字段通配（`DeviceMatcher.isSatisfied`），**不要写 `serialNumber`**（Razer 假序列号 `000000000000`，换有线/无线连接方式会静默失配）；`acceleration=1` / `speed=0` / `distance=auto` 经源码确认是不生效的 GUI 默认值。
- 生效路径：FileWatcher 热重载（0.25s 防抖）+「Configuration Reloaded」通知；配置优先级 `~/Library/Application Support/linearmouse/` > `~/.config/linearmouse/`（本机无前者）。

## Picom
- 给 `utility/dialog` 恢复轻阴影，在 `shadow-exclude` 里排除 `tblive` 等辅助条窗口。
- Ubuntu x64 + picom v10 环境：`shadow-exclude` 里的 `_GTK_FRAME_EXTENTS@` 会触发 `c2_parse_target` 解析错误；不在 Ubuntu x64 配置里保留它。
- 不使用 `opacity-rule` 把 Alacritty/foot 强制拉回 100% opacity；终端使用自身透明度使 blur 可见；浏览器/Thunderbird 等窗口按需保持 100%。
- 美观调优优先只改当前平台，不强求 `ubuntu_x64`/`arch_x64`/`arch_aarch64` 三份配置同步收口，除非用户明确要求。
- Ubuntu aarch64 为降负载已走低占用方案：关 blur（`method = "none"`）、阴影 radius 6/opacity 0.3、圆角 8px；经实测 picom CPU 从 15.2% 降到 6.7%。

## 锁屏
- AwesomeWM（X11）锁屏脚本与自动锁屏细节见 `memory/awesome.md`；niri/Wayland 锁屏使用 `swaylock`，相关偏好见 `memory/niri.md`。

## Snipaste
- Snipaste 候选路径、裸 `F1` 热键、KDE kglobalshortcutsrc 修复等与 Awesome 桌面强相关的细节见 `memory/awesome.md`。

## Ubuntu aarch64 外接屏
- 内屏 `2880x1800@120Hz` 主屏；外接屏在 Ubuntu aarch64 上默认显式固定为 `2560x1440@59.95Hz` 放笔记本右侧，避免误落到 `3840x2160@30` 或 `1920x2160` 这类特殊模式。
- `Xft.dpi: 192` 是合适基线；不为了外接屏降低全局 DPI。
- 外接屏方案不要改 Awesome per-screen DPI 或 rofi focused-screen `ROFI_SCALE`。

## 其它
- redshift 处理、Ubuntu aarch64 系统二进制优先、Linuxbrew 遮蔽处理、scripts/ helper 部署等通用工作流与环境偏好见 `memory/organizing_preferences.md`。

## fcitx / GTK_IM_MODULE 排查
- fcitx "建议取消设置 GTK_IM_MODULE" 警告的原因是 Wayland 下 GTK 自带 text-input 协议，不需要 `GTK_IM_MODULE=fcitx`
- 注入链排查步骤：
  1. `systemctl --user show-environment` 查看 systemd 用户环境
  2. `~/.config/environment.d/*.conf` — systemd generator 自动加载
  3. `~/.xprofile` — 登录管理器导入
  4. `niri-session` 中的 `systemctl --user import-environment` — 将 shell 环境导入 systemd
- 修复方法：
  - `environment.d/` 文件中移除或注释 GTK_IM_MODULE 行
  - `.conf` 后缀的备份文件必须重命名为 `.bak`，否则被 systemd generator 误解析
  - 当前会话通过 `dbus-update-activation-environment --systemd GTK_IM_MODULE=` 将值设空
- niri/Wayland 下 Satty 启动前应 `unset GTK_IM_MODULE`，让 GTK4 走 Wayland text-input/fcitx 路径
- Wayland autostart 中统一 `unset GTK_IM_MODULE`，`export QT_IM_MODULE=fcitx` 等 Qt 应用仍需
- fuzzel（≤1.12.0，含 apt 版）不实现 text-input/input-method 协议，niri 下无法接入 fcitx5，launcher 中文输入属上游能力边界（rofi 同类）；判别方法：`strings <launcher 二进制> | grep -E 'text_input|input_method'` 为空即不支持
- `/proc/<pid>/environ` 是 NUL 分隔的单行数据，脚本判断某环境变量是否存在必须 `grep -z`（或先 `tr '\0' '\n'`）；裸 `^VAR=` 只命中首变量。典型翻车：launcher-wayland 曾据此永远误判 fcitx5 未运行，每次拉起 launcher 都 `--replace` 重启、托盘图标反复消失（2026-08-29 已修）

## Chromium/Electron 应用的 Wayland text-input 版本矩阵（x86_64 niri 26.04 实测）
- niri 只实现 text-input v3；Chromium 系应用需显式或默认 v3，否则 fcitx5 中文输入**静默失效**（无报错，就是不响应）
- 版本分界：Chromium 130（Electron 33，旧 AppImage 版 Obsidian）默认 text-input v1 → 必须 `--wayland-text-input-version=3`；Chrome 152 / Trae 1.107 默认已 v3，无需该 flag；Obsidian 1.13.7（Chromium 150 官方构建，x86_64 deb / aarch64 tar.gz 都落在 `/opt/Obsidian`）同样默认 v3，无需该 flag
- 判断某 Electron 应用是否需要：`strings <binary> | grep 'Chrome/[0-9]'` 查 Chromium 版本，≥ 大约 13x 默认 v3；不确定就直接加，新 Chromium 会忽略无害
- 排障入口：先确认 `--ozone-platform=wayland --enable-wayland-ime` 已带，再怀疑 text-input 版本
- 2026-08-27 落地并 2026-09-02 迁移（均在 x86_64 机器）：Obsidian 原 AppImage（glob 发现）经 `obsidian-wayland` 切原生 Wayland，后清 AppImage 改 deb（`/opt/Obsidian`，1.13.7），wrapper 改为加 `--ozone-platform=wayland --enable-wayland-ime --disable-vulkan`（Vulkan 与 Wayland surface factory 不兼容，裸 exec 不弹窗）；钉钉（CEF 109）与 corplink（Electron 22）保持 XWayland 不迁。2026-09-26 更正：**aarch64 上游不发 deb**（obsidian-releases 的 arm64 只有 AppImage/tar.gz），本机（aarch64）用官方 `obsidian-1.13.7-arm64.tar.gz` 解压到同一 `/opt/Obsidian` 路径；`/opt` 在该机属主是 rikoo，解压无需 sudo
- **跨机器部署的 wrapper 必须自带"目标二进制缺失"守卫**（2026-09-26 实测定位）：`obsidian-wayland` 在 x86_64 改成 `exec /opt/Obsidian/obsidian` 后由 `install.sh` 铺到 aarch64 笔记本（2026-09-04 起），fuzzel 点开只得到 `exec: /opt/Obsidian/obsidian: not found` + exit 127；entry 的 `StartupNotify=false` 让失败完全不可见，只有手动 `sh -x ~/.config/scripts/obsidian-wayland` 才能看到。现 wrapper 在 exec 前 `[ ! -x "$obsidian_bin" ]` → `notify-send` + stderr + exit 127，并留 `OBSIDIAN_WAYLAND_BIN` 测试钩子（对齐 `corplink-service` 的 `CORPLINK_SYSTEMCTL` 惯例）；回归测试用 stub 二进制断言 Wayland/X11 参数与 127 分支。同源教训：凡是硬编码绝对路径的 wrapper（observed: zed 指向不存在的 `/usr/bin/zed`），都应先检查再 exec
- **mtgpu（aarch64 MediaTek）上旧 Electron 直接起不来，新 Electron 能回退**：ANGLE 报 `eglCreateContext failed` / `EGL_BAD_MATCH`（eglInitialize OpenGL/OpenGLES 全失败）→ GPU 进程反复崩溃。Electron 33 / Chromium 130 的老构建（4 月旧 AppImage，asar 虽被自动更新到 1.13.7）直接 `FATAL: GPU process isn't usable. Goodbye.` 退出，无窗口；换 Chromium 150 的官方构建后同样报 EGL 错，但会回退软件渲染、窗口正常（2026-09-26 实测）。换 flag 无效：原生 Wayland / XWayland / `--disable-gpu-compositing` / `--use-angle=gl|swiftshader` / `--disable-gpu` / `--no-sandbox` / `--in-process-gpu` / Mesa EGL 覆盖 / `--render-node-override` 全部无窗口。参考：同机 Chrome（Chromium 139）能正常拉起 GPU 进程（带 `--render-node-override=/dev/dri/renderD128`），说明是 Chromium/ANGLE 版本差异而非驱动整体不可用；`/dev/dri/renderD128` 权限正常（ACL 给 rikoo rw，userns 未被 AppArmor 限制，`/etc/apparmor.d/obsidian` 只是镜像 apparmor 包自带的 unconfined profile）
- **XWayland 应用（Electron 默认 X11）走 XIM：preedit 不同步 = "输入一半就上屏 + 多余空格"**（2026-09-07 ChatGPT 桌面版实测定位）。判别：renderer/gpu 进程 cmdline 带 `--ozone-platform=x11` → 应用在 XWayland；XIM 的 preedit 与 app 侧 composition 状态不同步，React 类页面（textarea 自动增高/重渲染）触发 IC 重置时拼音被刷进输入框，提交时空格键被转发多插一次。修复：wrapper 强制 `--ozone-platform=wayland --enable-wayland-ime` 走 text-input-v3（Chromium 152 默认 v3）。2026-09-07 已给 ChatGPT 桌面版（`/usr/lib/chatgpt/ChatGPT`，deb 26.901）落地 `chatgpt-wayland` wrapper + desktop entry 覆盖，实测无需 `--disable-vulkan`（与 Obsidian 不同）；用户确认中文输入恢复正常后入仓库

## Trae 终端黑块（xterm.js WebGL glyph atlas）排障（x86_64 niri 实测）
- 症状：终端随机位置整段文字渲染成**实心**黑色方块，缩放/最大化窗口时黑块分布变化（atlas 重新分页所致）；实心黑块 ≠ 空心 tofu，可排除字体缺字形
- 根因时间线（2026-08-29）：同日内核 6.8 → 7.0.0-30-generic（11:18 `--fix-broken install` 装入，6.8 同刻被卸载，i915 / Alder Lake UHD 730）+ niri Nix→apt 26.04ppa3 重登会话——底层栈双变更踩中 WebGL 渲染路径。同日钉钉 execstack 问题亦为该内核行为变化实锤，内核嫌疑最大，但 6.8 已卸载无法对照，无法精确归因单一层
- 修复：Trae settings.json 加 `"terminal.integrated.gpuAcceleration": "off"`（CPU/DOM 渲染，肉眼无性能差异），实测黑块消失；注意该文件仅存于 live（仓库无对应）
- 后续：Mesa/内核/Electron 任一层更新后可试删该配置恢复 GPU 渲染；若整窗级 GPU 异常（不只终端），改走 wrapper 加 `--disable-gpu` 对照

## appimagelauncher binfmt argv bug（x86_64 实测）
- 直接 `exec AppImage`（带 ≥4 个总参数）时被 binfmt_misc 拦给 `/opt/appimagelauncher.AppDir/.../binfmt-interpreter`，它向 `/usr/bin/AppImageLauncher` 转发 argv 时数组未 NULL 终止 → `execv EFAULT`，启动失败；0-3 个参数正常（易误判为随机故障）
- 稳定绕法：脚本显式 `exec /usr/bin/AppImageLauncher <AppImage> <args...>`，其内部 binfmt-bypass 组件自行构造正确 argv；无 appimagelauncher 的机器回退裸 exec
- 排障手法：`strace -f -e trace=execve` 看 interpreter 转发时的 argv 尾部是否跟垃圾指针；`AppImageLauncher` 包装进程退出（SIGTERM code 15）≠ Obsidian 退出，它挂载后会 fork 独立进程

### Rime（fcitx5-rime）lua 支持按机型区分
- **机型判定**：先确认 librime 是否带 lua 插件，再决定是否走「剥离 lua」方案。x86_64 Ubuntu 官方 apt librime（如 1.10.0）自带 `librime-plugin-lua`（`/usr/lib/x86_64-linux-gnu/rime-plugins/librime-lua.so`），**无需剥离 lua**，rime-ice 全功能可直接跑；仅 MediaTek 定制 librime（aarch64）无 lua，才需要走下方「方案 3a 剥离 lua」。
- 2026-08-28 已把 x86_64 机器 live `~/.local/share/fcitx5/rime` 升级到 rime-ice 最新 stable tag `2026.06.30`（完整 lua）：`git checkout -- .` 丢弃旧剥离改动 → `git checkout 2026.06.30` → 旧 `build/` 移走备份后 `rime_deployer --build` 重建 → `pkill fcitx5 && fcitx5 -d --replace`。验证：`3 tasks success / 0 failure`、加载 `lua/lunar.db`（lua 路径激活）、无 SIGSEGV。回滚锚点见 `logs/trace.md` 2026-08-28 条（live rime 独立 git `git checkout 7acdee6` 或整目录 `/tmp/rime-backup-20260828-092429` 恢复）。
- MediaTek 定制 librime **不支持 lua 插件**（`lua_processor`/`lua_translator`/`lua_filter` 均无法创建），而 rime-ice 全系 schema（`rime_ice`/`double_pinyin_*`）都依赖 lua 组件 → 启动即报错。
- 已按「方案 3a 剥离 lua」处理 live `~/.local/share/fcitx5/rime/rime_ice.schema.yaml`：engine 移除全部 lua 组件与对应配置块/recognizer 规则/开关，并去掉 corrector 用的 `［］comment_format`。基本拼音、词库、候选排序正常；失去以词定字、日期/农历/大写数字/计算器、错音提示、英文自动大写、v 模式、长词优先、部件拆字辅码、置顶候选项等 lua 扩展。
- **改完 schema 必须重建过期 .bin**：`rime_deployer --build` 只更新 prism/schema，`table.bin`/`reverse.bin` 可能仍是旧文件 → prism 与字典 .bin 不一致会导致 fcitx5 加载 rime 时 SIGSEGV 崩溃（栈在 `SchemaUpdate::Run → Config::GetString → ConfigData::Traverse`）。安全做法：删除 `build/` 下对应 schema 的 `{prism,table,reverse}.bin` 再 `rime_deployer --build`，最后 `pkill fcitx5 && fcitx5 -d --replace`。
- 该 Rime 目录是 rime-ice 的独立 git clone，**不属于 dotfiles 仓库**；改动需直接在 live 做并自行管理 git。若日后换带 lua 的 librime 可 `git checkout` 恢复。
- 备选方案 B：Flatpak 版 Fcitx5+Rime（官方维护、自带 librime-lua）可完整跑 rime-ice，但需迁移配置路径并改动 `wayland-autostart`/niri 环境，联动大，当前未采用。


niri / Wayland 与 Waybar 相关偏好已拆分到 `memory/niri.md` 和 `memory/waybar.md`。
