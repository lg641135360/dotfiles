#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
README_FILE=$REPO_ROOT/.config/linux/awesome/README.md
THEME_FILE=$REPO_ROOT/.config/linux/awesome/theme/catppuccin.lua
THEME_README_FILE=$REPO_ROOT/.config/linux/awesome/theme/README.md

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_contains() {
    needle=$1
    file=$2

    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        fail "expected '$needle' in $file"
    fi
}

assert_not_contains() {
    needle=$1
    file=$2

    if grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        fail "did not expect '$needle' in $file"
    fi
}

test_readme_documents_current_awesome_modules() {
    assert_contains 'actions.lua' "$README_FILE"
    assert_contains 'bindings.lua' "$README_FILE"
    assert_contains 'client.lua' "$README_FILE"
    assert_contains 'menu.lua' "$README_FILE"
    assert_contains 'autostart.sh' "$README_FILE"
    assert_contains 'ui/wibar.lua' "$README_FILE"
    assert_contains 'widgets/system.lua' "$README_FILE"
    assert_contains 'widgets/brightness.lua' "$README_FILE"
    assert_contains 'widgets/volume.lua' "$README_FILE"
    assert_contains 'CPU/MEM 直接读取 `/proc/stat` 与 `/proc/meminfo`' "$README_FILE"
    assert_contains 'aarch64/arm64 的笔记本 Awesome 配置会额外启用 BRI' "$README_FILE"
    assert_contains '直接读取 `/sys/class/backlight`' "$README_FILE"
    assert_contains '可选外部依赖' "$README_FILE"
    assert_not_contains 'git clone https://github.com/lcpz/lain.git' "$README_FILE"
}

test_readme_documents_wibar_visual_tuning() {
    assert_contains '聚焦窗口会使用圆角背景、蓝色文字和左侧细条高亮' "$README_FILE"
    assert_contains '只有主屏显示 NET / CPU / MEM / BAT / VOL 与系统托盘' "$README_FILE"
    assert_contains '其他屏幕右侧只保留时钟' "$README_FILE"
    assert_contains '次屏左侧只保留标签与布局' "$README_FILE"
    assert_contains '锁屏按钮悬浮会提示用途' "$README_FILE"
    assert_contains '布局指示器悬浮会提示当前布局和切换方式' "$README_FILE"
    assert_contains 'lock / layout / tasklist 的 tooltip 文案也统一成标题 + 字段行' "$README_FILE"
    assert_contains '主屏右侧状态区会继续统一收紧 spacing' "$README_FILE"
    assert_contains 'sysinfo / clock / systray 的胶囊权重会一起再压一档' "$README_FILE"
    assert_contains 'sysinfo / clock / systray 的胶囊权重会一起再压一档' "$README_FILE"
    assert_contains '托盘只放在主屏，并使用更小图标、深色胶囊背景和细边框' "$README_FILE"
    assert_contains '只在 Linux aarch64/arm64 的 Awesome 配置里尝试启用' "$README_FILE"
    assert_contains '只有检测到背光设备时才显示' "$README_FILE"
    assert_contains '全量模式使用 `CPU/MEM/BAT/VOL` 完整标签' "$README_FILE"
    assert_contains '外接屏热插拔、`xrandr` 改变几何或主屏切换后' "$README_FILE"
    assert_contains '重新判断主屏状态区和 full/compact 模式' "$README_FILE"
    assert_contains '时钟使用独立胶囊背景作为右端视觉终点' "$README_FILE"
    assert_contains '整条顶栏使用悬浮圆角容器' "$README_FILE"
    assert_contains '顶部留出少量空隙' "$README_FILE"
    assert_contains '长窗口标题会在单个任务项内尾部省略' "$README_FILE"
    assert_contains 'tasklist 项在 compact 屏上也会进一步收紧 padding 与 item spacing' "$README_FILE"
    assert_contains 'NET 保持短显示，悬停时显示网卡接口名和带 `/s` 单位的上下行速率' "$README_FILE"
    assert_contains 'NET/CPU/MEM 不绑定点击动作，只在鼠标悬浮时显示内置 detail' "$README_FILE"
    assert_contains '找不到匹配接口时主栏显示 `NET:N/A` 且 hover 显示离线' "$README_FILE"
    assert_contains 'NET/CPU/MEM/VOL/BAT 的 tooltip 使用统一中文文案' "$README_FILE"
    assert_contains 'CPU/MEM detail 使用各自精简内容' "$README_FILE"
    assert_contains 'CPU 显示 CPU 使用率、负载（load average）和 top CPU 进程' "$README_FILE"
    assert_contains 'MEM 显示内存使用率和 top MEM 进程' "$README_FILE"
    assert_contains 'BAT hover 显示充放电状态、当前电量、功率和可估算的剩余/充满时间' "$README_FILE"
    assert_contains '检测到多个电池时会聚合成一个 BAT 读数' "$README_FILE"
    assert_contains '在 Linux aarch64/arm64 且检测到背光设备时，BRI hover 会显示当前亮度百分比、背光设备名与原始亮度值' "$README_FILE"
    assert_contains '安装 `brightnessctl` 且当前用户对背光设备有写权限时，可在 BRI 上用滚轮加减亮度' "$README_FILE"
    assert_contains '未安装时滚轮会提示缺少 `brightnessctl` 并给出安装命令' "$README_FILE"
    assert_contains '若 `brightnessctl` 已安装但当前用户没有写权限，则会提示把用户加入对应设备组' "$README_FILE"
    assert_contains '使用 5 秒后台缓存，hover 时不临时执行 `ps`' "$README_FILE"
    assert_contains '右键 VOL 会尝试打开 `pavucontrol`' "$README_FILE"
    assert_contains '缺少 `pavucontrol` 或启动失败时会提示' "$README_FILE"
    assert_contains '静音后只显示 `MUTE`' "$README_FILE"
    assert_contains '悬浮 VOL 会提示左键/右键/滚轮的具体作用' "$README_FILE"
    assert_contains '时钟不绑定点击或滚轮动作' "$README_FILE"
    assert_contains '悬浮时显示完整日期、星期和时间' "$README_FILE"
    assert_contains '执行 Rofi、Dolphin、截图 OCR 与锁屏前检查关键命令或脚本是否可用' "$README_FILE"
    assert_contains '缺少依赖或执行失败时会通过 Awesome 通知提示' "$README_FILE"
}

test_theme_exposes_fallback_titlebar_tokens() {
    assert_contains 'theme.titlebar_size = dpi(26)' "$THEME_FILE"
    assert_contains 'theme.titlebar_radius = dpi(8)' "$THEME_FILE"
    assert_contains 'theme.titlebar_spacing = dpi(3)' "$THEME_FILE"
    assert_contains 'theme.titlebar_bg_normal = palette.mantle' "$THEME_FILE"
    assert_contains 'theme.titlebar_bg_focus = palette.surface0' "$THEME_FILE"
    assert_contains 'theme.titlebar_fg_normal = palette.subtext0' "$THEME_FILE"
    assert_contains 'theme.titlebar_fg_focus = palette.text' "$THEME_FILE"
    assert_contains 'theme.titlebar_font = "Maple Mono NF CN 10.5"' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_font = "Maple Mono NF CN 10.5"' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_radius = dpi(6)' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_bg_active = palette.surface1' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_fg_active = palette.blue' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_bg_close = palette.base' "$THEME_FILE"
    assert_contains 'theme.titlebar_button_fg_close = palette.red' "$THEME_FILE"
    assert_contains '回退标题栏' "$THEME_README_FILE"
    assert_contains 'titlebar_bg_*' "$THEME_README_FILE"
    assert_contains 'titlebar_button_*' "$THEME_README_FILE"
}

test_readme_documents_snipaste_f1_conflict() {
    assert_contains 'Snipaste 自己接管裸 `F1` 截图；Awesome 不绑定 `F1`' "$README_FILE"
    assert_contains '[org.flameshot.Flameshot.desktop]' "$README_FILE"
    assert_contains 'Capture` 应为 `none,none,进行截图`' "$README_FILE"
    assert_contains 'Unable to register global hotkey' "$README_FILE"
}

test_readme_documents_plain_i3lock_theme_fallback() {
    assert_contains 'i3lock-catppuccin-<宽>x<高>-<布局>.png' "$README_FILE"
    assert_contains '普通 `i3lock` 路径没有真实模糊/时钟能力' "$README_FILE"
    assert_contains '在每个屏幕中心各画一份卡片/锁图标' "$README_FILE"
    assert_contains '生成失败时才降级到纯色 `i3lock -n -e -f -c 11111b`' "$README_FILE"
}

test_readme_documents_current_awesome_modules
test_readme_documents_wibar_visual_tuning
test_theme_exposes_fallback_titlebar_tokens
test_readme_documents_snipaste_f1_conflict
test_readme_documents_plain_i3lock_theme_fallback

printf 'PASS: awesome docs/theme tests\n'
