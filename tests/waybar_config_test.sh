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
    assert_contains '"modules-right": ["network", "custom/cpu", "custom/memory", "backlight", "pulseaudio", "battery", "privacy", "tray"]' "$WAYBAR_AARCH64_CONFIG"
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
    assert_contains '"modules-right": ["network", "custom/cpu", "custom/memory", "pulseaudio", "privacy", "tray"]' "$WAYBAR_CONFIG"
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
    # custom 模块（waybar 内置 cpu/memory 的 tooltip-format 占位符无法注入动态
    # 进程列表）；后端 ~/.config/scripts/waybar-system-tooltip 单次调用内自差分
    # （间隔 sleep 1 两次采样 /proc/stat），规避 state 文件多 bar 并发 / reload
    # 串扰；return-type=json 模式 tooltip-exec 被忽略，tooltip 必须由 JSON 字段
    # 提供；exec-on-click 让单击立即刷新绕过 5s interval 等待。
    assert_contains '"custom/cpu": {' "$WAYBAR_CONFIG"
    assert_contains '"custom/memory": {' "$WAYBAR_CONFIG"
    assert_not_contains '"cpu": {' "$WAYBAR_CONFIG"
    assert_not_contains '"memory": {' "$WAYBAR_CONFIG"
    assert_contains "\"format\": \"$cpu_icon {}\"" "$WAYBAR_CONFIG"
    assert_contains "\"format\": \"$mem_icon {}\"" "$WAYBAR_CONFIG"
    assert_contains '"exec": "$HOME/.config/scripts/waybar-system-tooltip cpu"' "$WAYBAR_CONFIG"
    assert_contains '"exec": "$HOME/.config/scripts/waybar-system-tooltip mem"' "$WAYBAR_CONFIG"
    assert_contains '"exec-on-click": "true"' "$WAYBAR_CONFIG"
    assert_contains '"return-type": "json"' "$WAYBAR_CONFIG"
    assert_contains '"tooltip": true' "$WAYBAR_CONFIG"
    assert_contains '"escape": false' "$WAYBAR_CONFIG"
    assert_contains '"interval": 5,' "$WAYBAR_CONFIG"
    assert_contains '"on-click": "foot -- htop -s PERCENT_CPU"' "$WAYBAR_CONFIG"
    assert_contains '"on-click": "foot -- htop -s PERCENT_MEM"' "$WAYBAR_CONFIG"
    # states 配色由 JSON class 字段驱动（脚本内 emit_class：CPU 70/90，内存 85/95）；
    # 内存阈值比 CPU 高，避免 Linux 缓存常态占用高导致 80% 误报。
    assert_contains '#custom-cpu.warning' "$WAYBAR_STYLE"
    assert_contains '#custom-cpu.critical' "$WAYBAR_STYLE"
    assert_contains '#custom-memory.warning' "$WAYBAR_STYLE"
    assert_contains '#custom-memory.critical' "$WAYBAR_STYLE"
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

# waybar-system-tooltip 脚本契约：单次自差分（无 state 文件）、self=$$ 排除、
# tr -d 控制字符、emit_class 阈值、AwesomeWM 风格 tooltip 标题、CPU top 进程
# 瞬时化（/proc/<pid>/stat 两次采样 utime+stime 差值，非 ps %CPU 生命周期平均）；
# 实际执行返回合法 JSON。
test_waybar_system_tooltip_script_contract() {
    SCRIPT=$REPO_ROOT/.config/scripts/waybar-system-tooltip
    assert_file_exists "$SCRIPT"
    # sh 语法检查
    sh -n "$SCRIPT" || fail "waybar-system-tooltip 语法错误"
    # 单次调用内自差分（间隔 sleep 1 两次采样 /proc/stat）
    assert_contains 'sleep 1' "$SCRIPT"
    # 无 state 文件残留（旧方案在多 bar 并发 / reload 时会偶发 0%）
    assert_not_contains 'state_dir' "$SCRIPT"
    assert_not_contains 'XDG_STATE_HOME' "$SCRIPT"
    # top 进程按 pid 排除自身（$$），不再按 comm "sh" 过滤（误伤真实 sh 进程）
    assert_contains 'self=$$' "$SCRIPT"
    assert_not_contains '!= "sh"' "$SCRIPT"
    # json_escape 前置 tr -d 清除 \r 及其它控制字符，防止异常 comm 产生非法 JSON
    assert_contains 'tr -d' "$SCRIPT"
    # emit_class 阈值：CPU 70/90（瞬时使用率），内存 85/95（避免缓存常态占用高误报）
    assert_contains 'emit_class "$usage" 70 90' "$SCRIPT"
    assert_contains 'emit_class "$usage" 85 95' "$SCRIPT"
    # tooltip 标题对齐 AwesomeWM widgets/system.lua 风格
    assert_contains 'Top CPU 进程' "$SCRIPT"
    assert_contains 'Top 内存进程' "$SCRIPT"
    # CPU top 进程瞬时化：用 /proc/<pid>/stat utime+stime 差值（非 ps %CPU 生命周期平均）
    # 复用 sleep 1 窗口不增加阻塞；内存 top 进程仍用 ps RSS 瞬时值（已准确）
    assert_contains 'sample_proc_cpu' "$SCRIPT"
    assert_contains 'compute_top_cpu' "$SCRIPT"
    assert_contains '/proc/[0-9]*/stat' "$SCRIPT"
    assert_contains 'utime1[f[1]]' "$SCRIPT"
    assert_contains 'stime1[f[1]]' "$SCRIPT"
    assert_not_contains 'ps --sort=-pcpu' "$SCRIPT"
    # top 进程 %CPU 显示一位小数（%.1f），避免低占用进程被 %d 截断显示为 0%
    # （1s 窗口下 <1% 的瞬时值很常见）；外层 shell printf 必须与 awk 一致用
    # %.1f%%，若退回 %.0f%% 会被二次取整重新截成 0。
    assert_contains 'printf "%s %.1f\n"' "$SCRIPT"
    assert_contains "printf '%s  %s  %.1f%%" "$SCRIPT"
    # 内存 top 仍用 ps RSS 瞬时值（不依赖生命周期平均，准确性无问题）
    assert_contains 'ps --sort=-rss' "$SCRIPT"

    # 实际执行：返回合法 JSON，schema 含 text/tooltip/percentage/class 字段。
    # 依赖 live /proc 访问；sandbox 内 /proc 不可读时跳过。
    skip_unless python3 || return $?
    skip_unless test -r /proc/stat || return $?
    skip_unless test -r /proc/meminfo || return $?
    python3 - "$SCRIPT" <<'PY'
import json, subprocess, sys
script = sys.argv[1]
for sub in ["cpu", "mem"]:
    out = subprocess.check_output([script, sub], text=True, timeout=10)
    obj = json.loads(out)
    for key in ("text", "tooltip", "percentage", "class"):
        if key not in obj:
            sys.exit(f"{sub} missing field: {key}")
    title = "Top CPU 进程" if sub == "cpu" else "Top 内存进程"
    if title not in obj["tooltip"]:
        sys.exit(f"{sub} tooltip missing '{title}'")
    if not obj["text"].endswith("%"):
        sys.exit(f"{sub} text not percentage: {obj['text']}")
    if obj["class"] not in ("", "warning", "critical"):
        sys.exit(f"{sub} invalid class: {obj['class']}")
    if sub == "cpu":
        # top 进程值必须是一位小数（防 %d 截断把 <1% 显示成 0%）
        import re
        vals = re.findall(r"\d+\s+\S+\s+(\d+(?:\.\d)?)%", obj["tooltip"])
        if not vals or any("." not in v for v in vals):
            sys.exit(f"cpu top values not one-decimal: {vals}")
PY
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
test_waybar_system_tooltip_script_contract
test_waybar_aarch64_only_adds_backlight_and_battery

printf 'PASS: waybar config tests\n'
