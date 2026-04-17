# Picom Configuration

Three platform-specific configs, deployed by `install.sh` to `~/.config/picom.conf`.

| File | Target |
|------|--------|
| `picom-arch_x64.conf` | Arch Linux x86_64 |
| `picom-ubuntu_x64.conf` | Ubuntu x86_64 |
| `picom-arch_aarch64.conf` | Ubuntu ARM64 (aarch64) |

## Features

- **Backend**: glx with `--experimental-backends` (required for dual_kawase blur)
- **Blur**: dual_kawase strength 8 with background exclusions
- **Shadows**: 10px radius, 0.4 opacity, GTK CSD excluded
- **Rounded corners**: 16px for normal, tooltip, menu, dialog windows
- **Opacity**: 0.9 inactive, 0.95 menus, 1.0 for Alacritty/kitty/firefox/Thunderbird
- **Fading**: 0.03 step in/out with 5ms delta

## Autostart

AwesomeWM calls picom via `autostart.sh` which maps to the platform-specific script:

- Arch: `run picom`
- Ubuntu aarch64: `run picom --experimental-backends` (with linuxbrew PATH injected)
- Ubuntu x64: `run picom --experimental-backends`

## Known Issues

- `_GTK_FRAME_EXTENTS@` in shadow-exclude causes `c2_parse_target` errors on some picom versions. Kept only in x64 configs where it works; removed from aarch64 config.
