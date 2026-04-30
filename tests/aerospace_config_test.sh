#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$ROOT/.config/macos/aerospace/aerospace.toml"
README="$ROOT/.config/macos/aerospace/README.md"

python3 - "$CONFIG" <<'PY'
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8")
main = re.search(r"\[mode\.main\.binding\]\n(?P<body>.*?)(?=\n\[|\Z)", text, re.S)
if not main:
    raise SystemExit("AeroSpace config should define [mode.main.binding]")

bindings = dict(re.findall(r"^([a-z0-9-]+)\s*=\s*'([^']+)'", main.group("body"), re.M))

if bindings.get("alt-q") != "close":
    raise SystemExit(f"alt-q should close the focused window, got {bindings.get('alt-q')!r}")

if bindings.get("alt-f") != "fullscreen":
    raise SystemExit("alt-f fullscreen binding should remain unchanged")

if bindings.get("alt-enter") != "exec-and-forget alacritty":
    raise SystemExit("alt-enter terminal binding should remain unchanged")
PY

grep -q '`Mod+q` | 关闭当前窗口' "$README" || {
  echo "AeroSpace README should document Mod+q close-window behavior"
  exit 1
}

grep -q '`close --quit-if-last-window`' "$README" || {
  echo "AeroSpace README should document the optional app-quit variant"
  exit 1
}
