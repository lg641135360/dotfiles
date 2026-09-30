# yabai + skhd

macOS x86_64（黑苹果）上的**首选**窗口管理器组合。

| 机器类型 | 首选 | 原因 |
|---|---|---|
| **黑苹果 x86_64**（本机 MacBookPro15,2 / i5-8250U / macOS 15.x） | **yabai + skhd** | 本机无 Homebrew，CLI 走 MacPorts；且 SIP 已由 OpenCore 关闭（`csr-active-config`），scripting addition 装完即用；Intel 不需要 Apple Silicon 的 `-arm64e_preview_abi` |
| **白苹果**（Apple Silicon / 官方硬件） | **AeroSpace**（见 `../aerospace/`） | 纯用户态窗口管理器，无需关闭 SIP，安装/升级链路更简单 |

两者都用 `alt` 作为 `Mod`，**不要同机同跑**。本仓库同时保留两套配置，`install.sh` 按 `command -v yabai` / `command -v aerospace` 分别部署，互不干扰。

## 安装

yabai 走**官方预编译 release**（`scripts/install.sh`）：二进制已经用维护者的自签证书签好（`Authority=yabai-cert`、`Identifier=com.asmvik.yabai`），**不需要在本机再建证书/重新签名**，升级时无障碍授权也不会被系统丢弃。

```sh
# yabai → ~/.local/bin（已在 PATH 中，且与 herdr/nvim/starship/yazi 同级）
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/man/man1"
curl -L https://raw.githubusercontent.com/asmvik/yabai/master/scripts/install.sh \
  | sh /dev/stdin "$HOME/.local/bin" "$HOME/.local/share/man/man1"

# 热键守护：skhd 没有预编译产物，走 MacPorts
sudo port install skhd

command -v yabai && yabai -v   # 期望 yabai-v7.1.25 或更新
```

- 不要用浏览器下载 yabai：预编译是自签名，`spctl` 会判 `rejected`，浏览器会带上 quarantine 属性而被 Gatekeeper 拦下；`curl` 不会（已实测无 quarantine）。
- 若不指定目录，脚本默认写 `/usr/local/bin`（root:admin，普通用户不可写），需要 `sudo`。
- 该机器不走 `.config/macos/Brewfile`（无 Homebrew）；也可以用 `sudo port install yabai`（MacPorts 版为源码编译，**必须**自建 `yabai-cert` 证书并 `codesign -fs 'yabai-cert' /opt/local/bin/yabai`，且每次 `port upgrade` 后要重签 + 重算 sudoers 哈希）。

## Scripting addition（SA）

移动/创建/销毁空间、窗口阴影、`sticky`/`pip`/`scratchpad` 等依赖 SA 注入 Dock.app，要求 SIP 部分关闭（本机已满足）且配置免密 sudo：

```sh
echo "$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 "$(command -v yabai)" | cut -d' ' -f1) $(command -v yabai) --load-sa" \
  | sudo tee /private/etc/sudoers.d/yabai
sudo visudo -c          # 语法校验

sudo yabai --load-sa    # 期望无 "failed to inject payload"
```

`yabairc` 顶部已包含 `sudo yabai --load-sa` 与 `dock_did_restart` 信号，Dock 重启后会自动重载。

`--load-sa` 不只是内存注入：它会把 SA 装成 `/Library/ScriptingAdditions/yabai.osax`（`Contents/MacOS/loader` + `Contents/Resources/payload.bundle`，root 拥有），再把 payload 注入 Dock.app，所以**每次开机/Dock 重启都要重新注入**（由 `yabairc` 的 `signal` 负责）。注入失败的每一种情形都会往 stderr 打 `could not ...` / `failed to inject payload`；**退出码 0 且无输出即成功**。

## 权限（一次性 GUI 操作）

1. **系统设置 → 隐私与安全性 → 辅助功能**：勾选 `yabai` 与 `skhd`（`yabai --start-service` 会弹窗引导，勾选后需重启该进程）。
2. **录屏权限**：只有当 `window_animation_duration > 0`（窗口动画）时才需要；本配置保持 `0.0`，不需要。

启动：

```sh
yabai --start-service
skhd --start-service
```

## 系统设置前提

| 设置 | 位置 | 本机状态 |
|---|---|---|
| "显示器具有单独的空间" 开启 | 桌面与程序坞 → 调度中心 | 已满足（`com.apple.spaces spans-displays` 未设置 = 开启） |
| "根据最近使用情况自动重新排列空间" 关闭 | 同上 | `defaults.sh` 会写入 `com.apple.dock mru-spaces=false` |
| "点按墙纸以显示桌面" 设为"仅在台前调度时" | 桌面与程序坞 → 桌面与台前调度 | `defaults.sh` 会写入 `EnableStandardClickToShowDesktop=false` |
| 不要关闭 Finder 桌面 | — | `CreateDesktop` 未设置 = 显示，保持 |

## 常用快捷键（Mod = alt）

| 快捷键 | 功能 |
|--------|------|
| `Mod+Return` | 打开 Alacritty |
| `Mod+e` | 打开 Finder |
| `Mod+q` | 关闭当前窗口 |
| `Mod+f` | 切换全屏（zoom-fullscreen） |
| `Mod+Ctrl+f` | 切换浮动 / 平铺 |
| `Mod+Ctrl+d` | 切换 zoom-parent |
| `Mod+Ctrl+b` | 平衡窗口大小 |
| `Mod+Ctrl+t` / `Mod+Ctrl+p` | 切换 sticky / 画中画（需 SA） |
| `Mod+/` `Mod+,` | 切换 bsp / stack 布局（keycode 0x2C / 0x2B） |
| `Mod+h/j/k/l` | 按方向聚焦窗口 |
| `Mod+Shift+h/j/k/l` | 按方向交换窗口位置 |
| `Mod+Shift+-` `Mod+Shift+=` | 缩小 / 放大窗口（keycode 0x1B / 0x18；按 右→左→下→上 依次尝试 fence，等效 AeroSpace 的 `resize smart`） |
| `Mod+1/2/3/4/5` | 切换数字工作区 1-5 |
| `Mod+Shift+1/2/3/4/5` | 将当前窗口移到对应工作区并跟随聚焦 |
| `Mod+Tab` | 切回上一个空间（`space --focus recent`） |
| `Mod+Shift+Tab` | 聚焦下一个显示器 |

标点键在 skhd 里没有字面量名，只能用物理 keycode（`0x1B`/`0x18`/`0x2C`/`0x2B` 对应 ANSI 键盘的 `-`/`=`/`/`/`,`），十六进制字母必须大写。

## 鼠标操作

由 `yabairc` 的 `mouse_modifier` / `mouse_action1` / `mouse_action2` / `mouse_drop_action` 定义（对齐 awesome 的 `Mod+拖拽`，但换了个不冲突的修饰键）：

| 操作 | 功能 |
|------|------|
| `fn` + 左键拖拽 | 移动窗口（`mouse_action1 move`） |
| `fn` + 右键拖拽 | 调整窗口大小（`mouse_action2 resize`） |
| `fn` + 拖到另一个窗口上 | 交换位置（`mouse_drop_action swap`） |

用 `fn` 而不是 `alt` 是刻意选择：`alt`（Option）拖拽在 Finder 等应用里有原生含义。yabai 7.0.0 已修复「`alt` 作 `mouse_modifier` 会触发 macOS 隐藏全部窗口」的老 bug，若想和 awesome 完全一致，可把 `mouse_modifier` 改成 `alt`。

## 配置验证

yabai 和 skhd 都没有 `niri validate` 那样的独立校验命令（skhd 甚至不提供 `--help`/dry-run），可用的手段：

```bash
sh -n ~/.config/yabai/yabairc   # yabairc 是 POSIX sh，先保证语法
yabai -m query --spaces         # 空间命令可用 ⇒ SA 已加载
yabai -m rule --list            # 规则都应注册成功（当前 5 条浮动规则）
yabai -m signal --list          # dock_did_restart 信号应在
```

- 回归测试：`./tests/yabai_config_test.sh` —— 它会解析 `skhdrc` 后与期望绑定表**逐条比对**（缺绑定 / 重复绑定 / 未登记的额外绑定都会失败），并断言 README 键位表覆盖到每条绑定。
- 运行日志：`/tmp/yabai_<user>.err.log` 与 `/tmp/skhd_<user>.err.log`（launchd 服务的 stdout/stderr）。
- **skhd 的键位语法错误只能在启动时进 err 日志**，所以改完 skhdrc 后必须 `skhd --restart-service` 并实按一下，无法离线确认。

## 与 AeroSpace 的差异

- `Mod+r` 的 service 模式没有对应实现（skhd 的模式语法里"执行命令并返回"有歧义，未在本机回归前不引入）；涉及 SA 的 sticky / PiP / zoom-parent 已直接绑到 `Mod+Ctrl+*`。
- AeroSpace 的 `join-with`（`Mod+Shift+方向`）在 yabai 里没有等价语义，改成 `window --swap`。
- 工作区：只有 **1..5** 五个，全部用 mission-control **index** 寻址，不再沿用 AeroSpace 的 `C(ode)/B(rowser)/N(ote)/W(echat)` 命名工作区。理由：yabai **不允许纯数字标签**（`space --label 1` → `'1' cannot be used as a label.`），而数字工作区用 index 寻址本来就够用；去掉标签顺带避开了 `space --label` 打错空间、`space=` 规则被拒等一堆坑。顺序稳定性靠 `mru-spaces=false`（见下）。
- AeroSpace 的 `C/B/N/W` 绑定释放后，`Mod+C`/`Mod+B`/`Mod+N`/`Mod+W` 在 macOS 上**全部空闲**（随时可换成 launcher / 最小化之类；注意 niri 的 `Mod+C` 是启动器、awesome 的 `Mod+N` 是最小化）。

## 实机踩到的坑（写配置前必读）

这些都是 2026-09-30 在 macOS 15.8 / Intel 上真机跑出来的，不是文档抄的：

1. **纯数字不能当标签**：`space --label 1` → `'1' cannot be used as a label.`（label 必须是字符串 token，否则会与 mission-control index 在 `SPACE_SEL` 里撞车）。因此本配置**彻底不用标签**，工作区全部用 index 寻址，靠 `mru-spaces=false` 保证 1..5 的顺序稳定。
2. **`space --create` 不会把焦点移到新空间**，且新建后 `query --spaces` 不一定马上反映；`ensure_spaces` 因此不依赖 query 的结果做循环条件，而是用本地计数推进（否则会多建一个空间或提前停手）。
3. **`app=` 匹配的是本地化应用名**（本机 `AppleLocale=zh_CN`）：微信报的是「微信」、系统设置报的是「系统设置」，只写英文名会**静默不匹配**（无报错，就是不生效）。yabai 规则也不支持 bundle-id，所以只能用中英并列的 alternation。
4. **规则只对注册之后新出现的窗口生效**，已开着的窗口不会自动归位；`yabairc` 末尾的 `yabai -m rule --apply` 会把规则回放到当前窗口（现在只剩浮动规则，没有跨空间搬窗口的副作用）。
5. **yabai 在注册规则时就校验 `SPACE_SEL`**：标签不存在会整条拒掉（日志 `value 'C' is not a valid option for SPACE_SEL`）。以后若要加 `space=` 规则，必须确认目标空间/标签当时已存在。
6. **`--resize` 的 handle 指的是被拖动的 fence**（`src/window_manager.c`）：`first_child`（左/上）只有东/南 fence，`second_child`（右/下）只有西/北 fence，占满整屏的单窗口两边都没有 fence。单个 handle 会有半数情况报 `cannot locate a bsp node fence`，所以 `skhdrc` 里按 右→左→下→上 依次尝试（`2>/dev/null` 避免失败尝试刷进 `/tmp/skhd_*.err.log`）。

## 升级

```sh
# 预编译：重跑安装命令即可（已签名，无需重签）
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/man/man1"
curl -L https://raw.githubusercontent.com/asmvik/yabai/master/scripts/install.sh \
  | sh /dev/stdin "$HOME/.local/bin" "$HOME/.local/share/man/man1"

# 二进制换了 → 更新 sudoers 哈希并重载 SA
echo "$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 "$(command -v yabai)" | cut -d' ' -f1) $(command -v yabai) --load-sa" \
  | sudo tee /private/etc/sudoers.d/yabai
yabai --restart-service
sudo yabai --load-sa
```

**macOS 系统升级后**：签名不需要重做（签名在二进制上，系统升级不会抹掉）；但 SA 载荷与系统版本绑定，点版本升级后常需配套升级 yabai 并重跑 `sudo yabai --load-sa`。若升级后报 `scripting-addition failed to inject payload` 或空间命令失灵，先升级 yabai，再怀疑 SIP/签名。

## 回滚

```sh
rm -f ~/.config/yabai/yabairc ~/.config/skhd/skhdrc
yabai --uninstall-service; skhd --uninstall-service
sudo yabai --uninstall-sa          # 移除 /Library/ScriptingAdditions/yabai.osax
rm -f ~/.local/bin/yabai ~/.local/share/man/man1/yabai.1
sudo rm -f /private/etc/sudoers.d/yabai
```
`install.sh` 部署时若目标已存在，会先备份为 `*.backup.<时间戳>`（同类保留最近 3 份）。
