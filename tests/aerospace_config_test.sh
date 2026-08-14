#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/tests/lib/assert.sh"
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

assert_contains '`Mod+q` | 关闭当前窗口' "$README"
assert_contains '`close --quit-if-last-window`' "$README"
