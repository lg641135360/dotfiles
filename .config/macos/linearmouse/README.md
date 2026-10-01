# LinearMouse（macOS 鼠标/触控板定制）

用 [LinearMouse](https://linearmouse.app/) 对**每个指针设备单独**配置滚动方向、指针速度/加速度与按钮行为（macOS 系统设置只能全局生效，无法区分鼠标与触控板）。本目录是配置的**唯一事实来源**，`install.sh` 在检测到 `/Applications/LinearMouse.app` 时把 `linearmouse.json` 复制到 `~/.config/linearmouse/linearmouse.json`（已有文件先备份，保留 3 份）。

## 当前配置

单个 scheme，仅作用于 Razer Viper V2 Pro（`vendorID 0x1532` / `productID 0xa6` / `category mouse`）：

| 配置 | 行为 |
|------|------|
| `scrolling.reverse.vertical: true` | 鼠标垂直滚动反向：系统保持默认自然滚动，**触控板不受影响**，鼠标单独用传统滚轮方向 |
| `buttons.universalBackForward: true` | 侧键 → 后退/前进手势（修复 Safari/Xcode 等不认侧键的应用） |

方案内其余字段（`acceleration: 1`、`speed: 0`、`distance: "auto"`、`smoothed`/`gesture` 关闭、`clickDebouncing timeout: 0`、`pointer` 为 `"unset"`/`false`）是 GUI 写入的默认值，**不产生实际效果**——源码语义：`acceleration != 1`、`speed != 0`、`distance != "auto"` 才会应用变换。

## 机制要点

- **设备匹配 = 字段全等**（`DeviceMatcher.isSatisfied`）：条件里写了哪几个字段，哪几个就必须精确相等；未写 = 通配。**不要写 `serialNumber`**：Razer 固件上报的是假序列号 `000000000000`，换连接方式（有线 / HyperSpeed 无线）时 productID 或序列号可能变化，会导致方案**静默失配**（表现为滚动方向悄悄变回系统行为）。当前条件只保留 `category + vendorID + productID + productName`。
- **热重载**：LinearMouse 用 `FileWatcher` 监视配置文件（0.25s 防抖），保存后自动生效，并弹出「Configuration Reloaded / Your configuration changes are now active.」系统通知，无需重启 app。
- **配置优先级**：先找 `~/Library/Application Support/linearmouse/linearmouse.json`，其次才是 `~/.config/linearmouse/linearmouse.json`（本机无前者）。
- GUI 改动会直接重写 live 文件；**改完记得回填本目录**，否则下次 `install.sh` 会以仓库版本覆盖 live。

## 验证滚动方向

1. 保存文件后先看是否出现「Configuration Reloaded」通知（0.25s 内）。
2. GUI：菜单栏 LinearMouse 图标 → 选中 Razer 设备 → Scrolling 面板，Reverse 开关应为开（面板反映当前配置）。
3. 实按：鼠标滚轮向下滚，页面向**下**走（传统方向）；同时触控板双指上滑仍是自然方向（内容跟手指）——两者方向相反即符合预期。
4. 对照（可选）：GUI 里临时关掉 Reverse，鼠标方向应立刻反转，再打开恢复。

## 安装 LinearMouse

- 本机（黑苹果 x86_64）：从官网 dmg 安装（无 Homebrew）。
- 白苹果可 `brew install --cask linearmouse`（未加入 `.config/macos/Brewfile`，与 Karabiner 同理）。

## 回滚

```sh
cp -p ~/.config/linearmouse/linearmouse.json.backup.<时间戳> ~/.config/linearmouse/linearmouse.json
# 或删除本目录后重跑 install.sh（保证先备份再覆盖）
```
