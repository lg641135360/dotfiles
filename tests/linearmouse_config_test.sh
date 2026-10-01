#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tests/lib/assert.sh"

LINEARMOUSE_DIR=$ROOT/.config/macos/linearmouse
LINEARMOUSE_JSON=$LINEARMOUSE_DIR/linearmouse.json
LINEARMOUSE_README=$LINEARMOUSE_DIR/README.md
INSTALL_FILE=$ROOT/install.sh
ROOT_README=$ROOT/README.md

# The active configuration must be the single Razer scheme: reverse vertical
# scrolling plus universal back/forward. The two duplicate no-op trackpad
# schemes and the fake Razer serialNumber were removed on 2026-10-01 — the
# matcher requires exact equality on every listed field, so a stale serial
# silently disables the scheme when the connection mode changes.
resolve_python || exit $?
"$PYTHON_BIN" - "$LINEARMOUSE_JSON" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))

schemes = data["schemes"]
assert isinstance(schemes, list) and len(schemes) == 1, schemes
scheme = schemes[0]

raw = json.dumps(data)
assert "serialNumber" not in raw, "serialNumber must stay out: exact match on the fake Razer serial breaks on connection-mode changes"
assert "trackpad" not in raw, "trackpad no-op schemes were removed on 2026-10-01"

device = scheme["if"]["device"]
assert device == {
    "category": "mouse",
    "productID": "0xa6",
    "productName": "Razer Viper V2 Pro",
    "vendorID": "0x1532",
}, device

assert scheme["scrolling"]["reverse"]["vertical"] is True, scheme["scrolling"]
assert scheme["buttons"]["universalBackForward"] is True, scheme["buttons"]
print("linearmouse.json shape OK")
PY

# Deployment is gated on the LinearMouse app being installed; the module must
# be listed in the root README tree (repo_docs_test guards the tree too).
assert_contains '[ -d /Applications/LinearMouse.app ]' "$INSTALL_FILE"
assert_contains 'linearmouse/linearmouse.json|~/.config/linearmouse/linearmouse.json|LinearMouse' "$INSTALL_FILE"
assert_contains 'linearmouse/' "$ROOT_README"
assert_file_exists "$LINEARMOUSE_README"
assert_contains 'Razer Viper V2 Pro' "$LINEARMOUSE_README"
assert_contains 'serialNumber' "$LINEARMOUSE_README"
assert_contains '热重载' "$LINEARMOUSE_README"
assert_contains '回填' "$LINEARMOUSE_README"

printf 'PASS: linearmouse config tests\n'