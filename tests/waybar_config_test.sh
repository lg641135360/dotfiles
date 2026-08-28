#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

WAYBAR_CONFIG=$REPO_ROOT/.config/linux/waybar/config
WAYBAR_AARCH64_CONFIG=$REPO_ROOT/.config/linux/waybar/config.aarch64
WAYBAR_STYLE=$REPO_ROOT/.config/linux/waybar/style.css
WAYBAR_MOCHA=$REPO_ROOT/.config/linux/waybar/mocha.css

test_waybar_drops_dead_battery_module_on_desktop_platform() {
    # Ubuntu x64 target is a desktop without battery; the shared config must
    # not enable a battery module in modules-right. Battery CSS in style.css
    # is shared with aarch64 (which does use the module) and thus not dead.
    assert_not_contains '"battery"' "$WAYBAR_CONFIG"
}

test_waybar_aarch64_has_battery_module() {
    # aarch64 is a MediaTek laptop with a battery; the backlight-enabled
    # config.aarch64 variant also exposes a battery module in modules-right.
    assert_file_exists "$WAYBAR_AARCH64_CONFIG"
    assert_contains '"battery"' "$WAYBAR_AARCH64_CONFIG"
    assert_contains '"modules-right": ["network", "cpu", "memory", "backlight", "pulseaudio", "battery", "privacy", "tray"]' "$WAYBAR_AARCH64_CONFIG"
    # Battery styles live in the shared style.css (deployed to both platforms).
    assert_contains '#battery' "$WAYBAR_STYLE"
    assert_contains '#battery.charging' "$WAYBAR_STYLE"
    assert_contains '#battery.warning' "$WAYBAR_STYLE"
    assert_contains '#battery.critical' "$WAYBAR_STYLE"
    # AwesomeWM convention: charging green, <=35% yellow, <=15% red.
    assert_contains '"warning": 35' "$WAYBAR_AARCH64_CONFIG"
    assert_contains '"critical": 15' "$WAYBAR_AARCH64_CONFIG"
    # 背光回退到 waybar 内置 backlight 模块（最简实现）：on-scroll/on-click 直接调
    # brightnessctl，waybar 事件驱动 dp.emit() 立即重读 sysfs 刷新，不再需要 custom
    # 脚本 + 信号/watcher 的冗余方案（曾因 sandbox 里 brightnessctl 被拦截误判为
    # "无法实时更新" 而引入，实测 live 无此问题）。
    assert_contains '"backlight": {' "$WAYBAR_AARCH64_CONFIG"
    assert_contains '{percent}%' "$WAYBAR_AARCH64_CONFIG"
    assert_not_contains '"custom/backlight"' "$WAYBAR_AARCH64_CONFIG"
    assert_not_contains 'waybar-backlight' "$WAYBAR_AARCH64_CONFIG"
    assert_contains '"on-scroll-up": "brightnessctl set 5%+"' "$WAYBAR_AARCH64_CONFIG"
    assert_contains '"on-scroll-down": "brightnessctl set 5%-"' "$WAYBAR_AARCH64_CONFIG"
    # MediaTek m1000_backlight 不发出 uevent，内置模块只能靠 interval 轮询兜底；
    # 默认轮询 2s（waybar ALabel 构造参数），interval 0.1 缩到 ~100ms 贴近 vol 跟手。
    assert_contains '"interval": 0.1,' "$WAYBAR_AARCH64_CONFIG"
    assert_contains '#backlight' "$WAYBAR_STYLE"
}

# Split from the original test_waybar_and_mako_match_niri_trial_contract: the
# waybar-specific assertions cover modules, network tooltip format, custom
# CPU/MEM modules, pulseaudio, privacy, and the shared style.css / mocha.css
# theme contract.
test_waybar_matches_niri_trial_contract() {
    assert_file_exists "$WAYBAR_CONFIG"
    assert_file_exists "$WAYBAR_STYLE"
    assert_file_exists "$WAYBAR_MOCHA"

    assert_contains '"modules-left": ["niri/workspaces", "custom/separator", "niri/window"]' "$WAYBAR_CONFIG"
    # Nerd Font workspace glyphs (UTF-8 bytes via printf to survive editors
    # that strip unrenderable glyphs). See waybar config "niri/workspaces".
    focused_icon=$(printf '\357\206\222')
    active_icon=$(printf '\357\204\221')
    urgent_icon=$(printf '\357\201\252')
    empty_icon=$(printf '\357\204\214')
    assert_contains "\"focused\": \"$focused_icon\"" "$WAYBAR_CONFIG"
    assert_contains "\"active\": \"$active_icon\"" "$WAYBAR_CONFIG"
    assert_contains "\"urgent\": \"$urgent_icon\"" "$WAYBAR_CONFIG"
    assert_contains "\"empty\": \"$empty_icon\"" "$WAYBAR_CONFIG"
    assert_not_contains '"1":' "$WAYBAR_CONFIG"
    assert_not_contains '"2":' "$WAYBAR_CONFIG"
    assert_not_contains '"3":' "$WAYBAR_CONFIG"
    assert_not_contains '"4":' "$WAYBAR_CONFIG"
    assert_not_contains '"5":' "$WAYBAR_CONFIG"
    assert_contains '"modules-right": ["network", "cpu", "memory", "pulseaudio", "privacy", "tray"]' "$WAYBAR_CONFIG"
    # Nerd Font / Unicode glyphs (UTF-8 bytes via printf to survive editors
    # that strip unrenderable glyphs). Mirrors how the config file itself is
    # authored.
    wifi_icon=$(printf '\363\260\244\250')
    ethernet_icon=$(printf '\363\260\210\200')
    down_arrow=$(printf '\342\206\223')
    up_arrow=$(printf '\342\206\221')
    assert_contains "\"format-wifi\": \"$wifi_icon $down_arrow{bandwidthDownBytes} $up_arrow{bandwidthUpBytes}\"" "$WAYBAR_CONFIG"
    assert_contains "\"format-ethernet\": \"$ethernet_icon $down_arrow{bandwidthDownBytes} $up_arrow{bandwidthUpBytes}\"" "$WAYBAR_CONFIG"
    assert_not_contains '"format-alt":' "$WAYBAR_CONFIG"
    assert_contains '"on-click": "nm-connection-editor"' "$WAYBAR_CONFIG"
    assert_contains '"tooltip-format-wifi": "Wi-Fi\nSSID：{essid}\n信号：{signalStrength}%\n接口：{ifname}\n地址：{ipaddr}/{cidr}"' "$WAYBAR_CONFIG"
    assert_contains '"tooltip-format-ethernet": "有线网络\n接口：{ifname}\n地址：{ipaddr}/{cidr}"' "$WAYBAR_CONFIG"
    assert_not_contains '下载：{bandwidthDownBytes}' "$WAYBAR_CONFIG"
    assert_not_contains '上传：{bandwidthUpBytes}' "$WAYBAR_CONFIG"
    assert_contains '"tooltip-format-disconnected": "网络未连接"' "$WAYBAR_CONFIG"
    assert_contains '"max-length": 52' "$WAYBAR_CONFIG"
    assert_contains '"rewrite": {' "$WAYBAR_CONFIG"
    assert_contains '"(.*) - Visual Studio Code$": "$1"' "$WAYBAR_CONFIG"
    assert_contains '"(.*) - Google Chrome$": "$1"' "$WAYBAR_CONFIG"
    assert_contains '"(.*) - Alacritty$": "$1"' "$WAYBAR_CONFIG"
    cpu_icon=$(printf '\363\260\273\240')
    mem_icon=$(printf '\363\260\215\233')
    # 使用 Waybar 原生 CPU/内存模块，避免每个输出每 5 秒各自启动脚本、遍历
    # /proc 并阻塞 1 秒。保留原有阈值配色和点击 htop 的交互。
    assert_contains '"cpu": {' "$WAYBAR_CONFIG"
    assert_contains '"memory": {' "$WAYBAR_CONFIG"
    assert_not_contains '"custom/cpu": {' "$WAYBAR_CONFIG"
    assert_not_contains '"custom/memory": {' "$WAYBAR_CONFIG"
    assert_contains "\"format\": \"$cpu_icon {usage}%\"" "$WAYBAR_CONFIG"
    assert_contains "\"format\": \"$mem_icon {percentage}%\"" "$WAYBAR_CONFIG"
    assert_contains '"tooltip-format": "CPU 使用率：{usage}%\n负载：{load}"' "$WAYBAR_CONFIG"
    assert_contains '"tooltip-format": "内存使用率：{percentage}%\n已用：{used:0.1f} GiB / {total:0.1f} GiB\n可用：{avail:0.1f} GiB"' "$WAYBAR_CONFIG"
    assert_contains '"warning": 70' "$WAYBAR_CONFIG"
    assert_contains '"critical": 90' "$WAYBAR_CONFIG"
    assert_contains '"warning": 85' "$WAYBAR_CONFIG"
    assert_contains '"critical": 95' "$WAYBAR_CONFIG"
    assert_contains '"interval": 5,' "$WAYBAR_CONFIG"
    assert_contains '"on-click": "foot -- htop -s PERCENT_CPU"' "$WAYBAR_CONFIG"
    assert_contains '"on-click": "foot -- htop -s PERCENT_MEM"' "$WAYBAR_CONFIG"
    assert_contains '#cpu.warning' "$WAYBAR_STYLE"
    assert_contains '#cpu.critical' "$WAYBAR_STYLE"
    assert_contains '#memory.warning' "$WAYBAR_STYLE"
    assert_contains '#memory.critical' "$WAYBAR_STYLE"
    assert_not_contains '#custom-cpu' "$WAYBAR_STYLE"
    assert_not_contains '#custom-memory' "$WAYBAR_STYLE"
    # POSIX sh: 用 printf 八进制转义构造 Nerd Font 音量图标 U+F028（UTF-8 EF 80 A8），
    # 避免 bash 专属的 ANSI-C quoting（$'...'）在 dash 下解析失败。
    vol_icon=$(printf '\357\200\250')
    assert_contains "\"format\": \"$vol_icon  {volume}%\"" "$WAYBAR_CONFIG"
    muted_icon=$(printf '\363\260\235\237')
    assert_contains "\"format-muted\": \"$muted_icon 静音\"" "$WAYBAR_CONFIG"
    # pulseaudio uses on-scroll + external wpctl; interval 1 keeps display fresh
    assert_contains '"on-scroll-up": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.0"' "$WAYBAR_CONFIG"
    assert_contains '"on-scroll-down": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"' "$WAYBAR_CONFIG"
    assert_contains '"interval": 1,' "$WAYBAR_CONFIG"
    assert_contains '"privacy": {' "$WAYBAR_CONFIG"
    assert_contains '"type": "screenshare"' "$WAYBAR_CONFIG"
    assert_contains '"type": "audio-in"' "$WAYBAR_CONFIG"
    assert_contains '"tooltip-format": "<tt><small>{calendar}</small></tt>"' "$WAYBAR_CONFIG"
    assert_contains '"iso8601": true' "$WAYBAR_CONFIG"
    assert_contains '"tooltip": false' "$WAYBAR_CONFIG"
    assert_contains '@define-color base #1e1e2e;' "$WAYBAR_MOCHA"
    assert_contains '@define-color blue #89b4fa;' "$WAYBAR_MOCHA"
    assert_contains 'font-family: "Maple Mono NF CN", "JetBrainsMono Nerd Font", "Noto Sans CJK SC", sans-serif;' "$WAYBAR_STYLE"
    assert_contains '@import "mocha.css";' "$WAYBAR_STYLE"
    assert_contains 'background-color: alpha(@base, 0.72);' "$WAYBAR_STYLE"
    assert_contains 'border: 1px solid alpha(@surface1, 0.72);' "$WAYBAR_STYLE"
    assert_contains 'background: transparent;' "$WAYBAR_STYLE"
    assert_contains 'border-radius: 12px;' "$WAYBAR_STYLE"
    assert_contains '#workspaces button.empty' "$WAYBAR_STYLE"
    assert_contains '#workspaces button.focused' "$WAYBAR_STYLE"
    assert_contains 'transition: color 0.15s ease, background-color 0.15s ease;' "$WAYBAR_STYLE"
    assert_not_contains 'border-color 0.15s ease' "$WAYBAR_STYLE"
    assert_not_contains 'opacity 0.15s ease' "$WAYBAR_STYLE"
    assert_contains '#workspaces button:hover' "$WAYBAR_STYLE"
    assert_contains '#clock:hover,' "$WAYBAR_STYLE"
    assert_contains '#network.disconnected' "$WAYBAR_STYLE"
    assert_contains '#privacy-item.screenshare' "$WAYBAR_STYLE"
    assert_contains '#privacy-item.audio-in' "$WAYBAR_STYLE"
    assert_contains '#tray > .needs-attention' "$WAYBAR_STYLE"
}

# Both waybar configs are JSON; a syntax error would make waybar reject the
# entire file at startup. Smoke-test by parsing with python3 (skipped on
# hosts without python3).
test_waybar_configs_parse_as_valid_json() {
    skip_unless python3 || return $?
    python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$WAYBAR_CONFIG" ||
        fail "waybar config is not valid JSON: $WAYBAR_CONFIG"
    python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$WAYBAR_AARCH64_CONFIG" ||
        fail "waybar config.aarch64 is not valid JSON: $WAYBAR_AARCH64_CONFIG"
}

# config.aarch64 must be a strict superset of config: every shared top-level
# key must match byte-for-byte (modulo JSON formatting), and the only extras
# aarch64 is allowed are the backlight + battery modules (plus the
# modules-right entries that reference them). This guards against accidental
# drift where someone edits one config and forgets the other.
test_waybar_aarch64_only_adds_backlight_and_battery() {
    skip_unless python3 || return $?
    python3 - "$WAYBAR_CONFIG" "$WAYBAR_AARCH64_CONFIG" <<'PY'
import json, sys
with open(sys.argv[1]) as f: x64 = json.load(f)
with open(sys.argv[2]) as f: aarch = json.load(f)

# modules-right: aarch64 must add exactly backlight + battery, in order,
# between memory and pulseaudio (laptop brightness/volume ergonomics).
x64_right = x64["modules-right"]
aarch_right = aarch["modules-right"]
extra = [m for m in aarch_right if m not in x64_right]
if extra != ["backlight", "battery"]:
    sys.exit(f"aarch64 modules-right extras expected [backlight, battery], got {extra}")

# Every shared top-level key must match exactly (catches silent drift in
# clock, network, pulseaudio, workspaces, etc.).
common = set(x64.keys()) & set(aarch.keys())
for k in sorted(common):
    if k == "modules-right":
        continue
    if x64[k] != aarch[k]:
        sys.exit(f"shared module '{k}' differs between config and config.aarch64")

# aarch64 must have exactly 2 extra top-level keys: backlight + battery.
extra_keys = set(aarch.keys()) - set(x64.keys())
if extra_keys != {"backlight", "battery"}:
    sys.exit(f"aarch64 extra top-level keys expected {{backlight, battery}}, got {extra_keys}")
PY
}

test_waybar_drops_dead_battery_module_on_desktop_platform
test_waybar_aarch64_has_battery_module
test_waybar_matches_niri_trial_contract
test_waybar_configs_parse_as_valid_json
test_waybar_aarch64_only_adds_backlight_and_battery

printf 'PASS: waybar config tests\n'
