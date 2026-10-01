# Karabiner-Elements（macOS 键盘映射）

用 [Karabiner-Elements](https://karabiner-elements.pqrs.org/) 做**物理键改键**（skhd 只做「组合键 → 命令」，改不了按键本身）。本目录是配置的**唯一事实来源**，`install.sh` 在检测到 `/Applications/Karabiner-Elements.app` 时把 `karabiner.json` 复制到 `~/.config/karabiner/karabiner.json`（已有文件先备份，保留 3 份）。

## 当前映射

### Caps Lock（全部键盘）

| 触发 | 行为 |
|------|------|
| `Caps` 按住 + 其他键 | **Control**（如 `Caps+C` = `Ctrl+C`；tmux 前缀 `C-a` 变成 `Caps+a`） |
| `Caps` 单击（未与其他键组合） | **Escape** |

规则用 `to` 里的 `{"key_code": "left_control", "lazy": true}`（按下 Caps 本身不发 Ctrl，只有组合时才发）+ `to_if_alone`（单独按下松开 → Esc）。判定窗口是 Karabiner 默认的 `to_if_alone_timeout`（约 1s 内有其他按键则不触发 Esc）。

### Win/Alt 互换（仅内置键盘）

本机内置键盘是 **Windows 布局**（靠空格键的键印着 `Alt`、第二个印着 `Win`），macOS 默认把 `Win` 报成 Command、`Alt` 报成 Option。互换后按键**位置**与 Mac 布局一致：

| 物理键 | 互换前 | 互换后 |
|--------|--------|--------|
| `Win`（第二排） | ⌘ Command | **⌥ Option（yabai/skhd 的 Mod）** |
| `Alt`（紧邻空格键） | ⌥ Option | **⌘ Command** |

- 实现：写在 profile 的 `devices[]` 里、该设备条目的 `simple_modifications`（`left/right_command` ↔ `left/right_option` 四条互换）。Karabiner 会**自动**给设备级条目附加 `device_if`（`vendor_id: 1452`、`product_id: 65535`、`is_keyboard`），因此**只作用于内置键盘**——外接 Apple 布局键盘与白苹果整机都不受影响。
- ⚠ 陷阱：profile 级 `simple_modifications` 条目**不支持** `conditions`（16.3.0 实测报 `json error: Unknown key: conditions` 并**整条丢弃**）；设备限定必须用 `devices[]` 条目。改完可用 `grep -i 'json error' ~/.local/share/karabiner/log/console_user_server.log` 复核是否被拒。
- 副作用：互换后 skhd 的 `Mod+…` 组合由物理 `Win` 键触发；Alacritty 里 `Command` 前缀的快捷键（如 `Command+h/j/k/l`）由物理 `Alt` 键触发。
- 想作用于**所有键盘**：把这几条映射从 `devices[]` 挪到 profile 级 `simple_modifications`（去掉设备限定）即可（不建议——会把外接 Mac 布局键盘也换掉）。
- 内置键盘的 vendor/product 由 VoodooPS2 伪装而来；若日后换驱动/键盘导致 `hidutil list` / `karabiner_cli --list-connected-devices` 里的 ID 变化，互换会静默失效，需要同步更新这里的数字。

### Esc → 大写锁定（仅内置键盘）

物理 `Esc` 键改为**大写锁定开关**（大小写切换）。此后 `Esc` 没有物理键，改由 `Caps` 单击提供（见上）；用 complex modification + `device_if` 限定内置键盘——外接 Apple 布局键盘自带真实 Caps Lock，不需要这条。

- ⚠ **为什么不做成 simple modification**：Karabiner 的流水线是 **`device_key_code → simple_modifications → complex_modifications → fn_function_keys → 虚拟键盘`**（`device_grabber` 里 `manipulator_managers_connector` 依次串联各 manager）。`Esc → caps_lock` 若写在 simple 层，输出会**再进 complex 层**、被上面的 Caps 规则（`caps_lock → Ctrl/Esc`）吃掉——按 Esc 只会又发出一个 Esc（实测症状）。写成 complex 规则后，输出直接进后续阶段，不再被拦截。
- 键盘闭环：`Caps` 按住 = Ctrl（按住 + 空格即 `Ctrl+Space` 切输入法）、`Caps` 单击 = Esc、物理 `Esc` = 大小写切换。
- 系统未启用「使用 Caps Lock 切换输入法」（`defaults read com.apple.HIToolbox` 无相关设置），所以 `caps_lock` 就是纯大小写开关。
- 输入法切换保持系统默认快捷键 `Ctrl+Space`（已启用），本次未加额外映射。

## 安装 Karabiner-Elements

- 本机（黑苹果）从官网装 dmg：MacPorts 没有 `karabiner` 端口，也没有 Homebrew。首次启动按向导完成：批准 **系统扩展**（DriverKit VirtualHIDDevice）+ **输入监控** 权限。
- 白苹果可 `brew install --cask karabiner-elements`（未加入 `.config/macos/Brewfile`，避免在没打算用它的机器上强装系统扩展）。
- 已实测：本机 SIP 被 OpenCore 全关（`csr-active-config=0x0FFF`）时 DriverKit 扩展仍可 `activated enabled`，权限授权后 `core_service` 正常工作。

## 编辑与验证

- Karabiner **监听配置文件热重载**：覆盖 `~/.config/karabiner/karabiner.json` 后立即生效，无需重启（日志 `~/.local/share/karabiner/log/` 里会打印 `core_configuration is updated`）。
- 用 **Karabiner-EventViewer** 验证按键事件；映射不生效时先看 EventViewer 是否收到键，再看「输入监控」权限。
- 在 Karabiner GUI 里改完记得**回填本目录**，否则下次 `install.sh` 会以仓库版本覆盖 live。

## 回滚

```sh
rm ~/.config/karabiner/karabiner.json   # Karabiner 重启后会重建默认空配置
# 或从备份恢复：cp -p ~/.config/karabiner/karabiner.json.backup.<时间戳> ~/.config/karabiner/karabiner.json
```
