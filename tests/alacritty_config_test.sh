#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEYS_LINUX="$ROOT/.config/shared/alacritty/keys.linux.toml"
KEYS_MACOS="$ROOT/.config/shared/alacritty/keys.macos.toml"
ALACRITTY="$ROOT/.config/shared/alacritty/alacritty.toml"
README="$ROOT/.config/shared/alacritty/README.md"

python3 - "$ALACRITTY" <<'PY'
import sys
import tomllib

with open(sys.argv[1], "rb") as handle:
    config = tomllib.load(handle)

actual_term = config.get("env", {}).get("TERM")
if actual_term != "xterm-256color":
    raise SystemExit(
        "Alacritty TERM should use portable xterm-256color for remote compatibility, "
        f"got {actual_term!r}"
    )

font = config["font"]
expected_styles = {
    "normal": "Regular",
    "bold": "Bold",
    "italic": "Italic",
    "bold_italic": "Bold Italic",
}

for section, style in expected_styles.items():
    actual_family = font[section]["family"]
    actual_style = font[section]["style"]
    if actual_family != "MesloLGS Nerd Font Mono" or actual_style != style:
        raise SystemExit(
            f"Alacritty font.{section} should use MesloLGS Nerd Font Mono {style}, "
            f"got {actual_family} {actual_style}"
        )
PY

python3 - "$KEYS_LINUX" "$KEYS_MACOS" <<'PY'
import sys
import re

def norm_mods(value):
    return "|".join(sorted(part.strip() for part in value.split("|") if part.strip()))

def read_bindings(path):
    with open(path, "r", encoding="utf-8") as handle:
        text = handle.read()

    lookup = {}
    for match in re.finditer(r'\{\s*key\s*=\s*"([^"]+)"\s*,\s*mods\s*=\s*"([^"]+)"\s*,\s*chars\s*=\s*"((?:\\.|[^"])*)"', text):
        key, mods, chars = match.groups()
        lookup[(key, norm_mods(mods))] = chars.encode("utf-8").decode("unicode_escape")
    return lookup

line_movement = {
    ("Left", norm_mods("Alt")): "\x1b[1;3D",
    ("Right", norm_mods("Alt")): "\x1b[1;3C",
    ("Up", norm_mods("Alt")): "\x1b[1;3A",
    ("Down", norm_mods("Alt")): "\x1b[1;3B",
    ("Up", norm_mods("Shift|Alt")): "\x1b[1;4A",
    ("Down", norm_mods("Shift|Alt")): "\x1b[1;4B",
}

expected_by_file = {
    "Linux": {
        **line_movement,
        ("H", norm_mods("Alt")): "\x01h",
        ("J", norm_mods("Alt")): "\x01j",
        ("K", norm_mods("Alt")): "\x01k",
        ("L", norm_mods("Alt")): "\x01l",
    },
    "macOS": {
        **line_movement,
        ("H", norm_mods("Command")): "\x01h",
        ("J", norm_mods("Command")): "\x01j",
        ("K", norm_mods("Command")): "\x01k",
        ("L", norm_mods("Command")): "\x01l",
    },
}

lookups = {
    "Linux": read_bindings(sys.argv[1]),
    "macOS": read_bindings(sys.argv[2]),
}

for platform, expected in expected_by_file.items():
    lookup = lookups[platform]
    for key, chars in expected.items():
        actual = lookup.get(key)
        if actual != chars:
            raise SystemExit(
                f"Alacritty {platform} binding {key} should send {chars.encode()!r}, got {actual.encode() if actual is not None else None!r}"
            )

unexpected_macos_alt_hjkl = {
    ("H", norm_mods("Alt")): "\x01h",
    ("J", norm_mods("Alt")): "\x01j",
    ("K", norm_mods("Alt")): "\x01k",
    ("L", norm_mods("Alt")): "\x01l",
}
for key in unexpected_macos_alt_hjkl:
    if key in lookups["macOS"]:
        raise SystemExit(f"macOS tmux pane navigation should stay on Command, found unexpected {key}")
PY

grep -q '<A-Up>' "$README" || {
  echo "README should document Alt-Up for Neovim line movement"
  exit 1
}

grep -q '<A-Left>' "$README" || {
  echo "README should document Alt-Left for Neovim jump history"
  exit 1
}

grep -q '<S-A-Down>' "$README" || {
  echo "README should document Shift-Alt-Down for Neovim line duplication"
  exit 1
}

grep -q 'Option+Right' "$README" || {
  echo "README should document macOS Option-Right for Neovim jump history"
  exit 1
}

grep -q 'Option+Up' "$README" || {
  echo "README should document macOS Option-Up for Neovim line movement"
  exit 1
}

grep -q 'TERM=xterm-256color' "$README" || {
  echo "README should document the portable TERM setting"
  exit 1
}

grep -q '| 粗体 | Bold |' "$README" || {
  echo "README should document the installed MesloLGS Bold style"
  exit 1
}

grep -q '| 斜体 | Italic |' "$README" || {
  echo "README should document the installed MesloLGS Italic style"
  exit 1
}

grep -q '| 粗斜体 | Bold Italic |' "$README" || {
  echo "README should document the installed MesloLGS Bold Italic style"
  exit 1
}
