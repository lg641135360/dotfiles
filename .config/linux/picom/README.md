# Picom Configuration

Three platform-specific configs, deployed by `install.sh` to `~/.config/picom.conf`.

| File | Target |
|------|--------|
| `picom-arch_x64.conf` | Arch Linux x86_64 |
| `picom-ubuntu_x64.conf` | Ubuntu x86_64 |
| `picom-arch_aarch64.conf` | Ubuntu ARM64 (aarch64) |

当前不强求三平台使用完全相同的参数；应优先围绕**当前平台**调优，确认视觉目标稳定后再决定是否推广到其它平台。

## Features

- **Backend**: glx compositor baseline
- **Blur**: Ubuntu x64 当前使用 dual_kawase strength 12，并保留背景和窗口 frame 模糊；其它平台仍按各自原始基线
- **Shadows**: Ubuntu x64 当前使用 12px radius、0.28 opacity、`-6/-6` offset，并让 `utility/dialog` 恢复轻阴影同时排除 `tblive`；其它平台继续保留各自原始策略
- **Rounded corners**: Ubuntu x64 当前收口到 12px，与 Awesome 窗口 `border_radius = 12` 对齐；其它平台仍保持原始半径
- **Opacity**: Ubuntu x64 当前使用 0.90 inactive、0.98 active、0.92 frame、0.95 menus；Alacritty/kitty 不再被 picom 强制拉回 100% opacity，而是交回终端自己的透明度设置
- **Fading**: 0.03 step in/out with 5ms delta

## Autostart

AwesomeWM calls picom via `autostart.sh` which maps to the platform-specific script:

- Arch: `run picom`
- Ubuntu aarch64: `run picom --experimental-backends` (with linuxbrew PATH injected)
- Ubuntu x64: `run picom`

## Known Issues

- `_GTK_FRAME_EXTENTS@` in `shadow-exclude` can trigger `c2_parse_target` errors on some picom builds. On the current Ubuntu x64 + picom v10 path it must stay removed; keep or reintroduce it only on environments where you have re-verified that the parser accepts it.
