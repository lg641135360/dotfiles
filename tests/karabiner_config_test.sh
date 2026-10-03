#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tests/lib/assert.sh"

KARABINER_DIR=$ROOT/.config/macos/karabiner
KARABINER_JSON=$KARABINER_DIR/karabiner.json
KARABINER_README=$KARABINER_DIR/README.md
INSTALL_FILE=$ROOT/install.sh
ROOT_README=$ROOT/README.md

# The active profile must contain exactly the Caps Lock rule: hold -> Control
# (lazy, so pressing Caps alone sends nothing) and tap -> Escape.
resolve_python || exit $?
"$PYTHON_BIN" - "$KARABINER_JSON" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))

profiles = data["profiles"]
assert isinstance(profiles, list) and len(profiles) == 1, profiles
profile = profiles[0]
assert profile.get("selected") is True, "the single profile must be selected"
assert profile["virtual_hid_keyboard"]["keyboard_type_v2"] == "ansi"

rules = profile["complex_modifications"]["rules"]
assert len(rules) == 2, rules
for rule in rules:
    assert rule["description"], "every rule needs a description (shown in the GUI)"

caps_rule, escape_rule = rules

manipulators = caps_rule["manipulators"]
assert len(manipulators) == 1, manipulators
manipulator = manipulators[0]
assert manipulator["type"] == "basic"
assert manipulator["from"]["key_code"] == "caps_lock"
# With any optional modifiers held, Caps still acts as the mapping (Caps+Shift+C).
assert manipulator["from"]["modifiers"]["optional"] == ["any"]
assert manipulator["to"] == [{"key_code": "left_control", "lazy": True}]
assert manipulator["to_if_alone"] == [{"key_code": "escape"}]

# The escape -> caps_lock mapping MUST live in complex_modifications: simple
# modifications are applied BEFORE complex ones (device_grabber chains
# device_key_code -> simple -> complex -> fn_function_keys), so an entry in
# simple_modifications would be re-processed by the caps_lock rule above and
# come out as escape again (observed: pressing Esc did nothing).
escape_manipulators = escape_rule["manipulators"]
assert len(escape_manipulators) == 1, escape_manipulators
escape = escape_manipulators[0]
assert escape["type"] == "basic"
assert escape["from"]["key_code"] == "escape"
assert escape["from"]["modifiers"]["optional"] == ["any"]
assert escape["to"] == [{"key_code": "caps_lock"}]
assert escape["conditions"] == [
    {
        "type": "device_if",
        "identifiers": [{"vendor_id": 1452, "product_id": 65535, "is_keyboard": True}],
    }
], escape["conditions"]

# Win-layout internal keyboard: the Command/Option swap stays in the device's
# own simple_modifications (no complex rule touches command/option, so no
# stage-order issue). Per-device entries are the supported way to scope to one
# keyboard: Karabiner appends the device_if condition itself, and entries
# accept only `from`/`to` (a `conditions` key is rejected at load with
# "Unknown key: conditions").
assert "simple_modifications" not in profile, "profile-level entries can't carry conditions"
devices = profile["devices"]
assert len(devices) == 1, devices
device = devices[0]
assert device["identifiers"] == {"vendor_id": 1452, "product_id": 65535, "is_keyboard": True}, device

expected_simples = {
    "left_command": "left_option",
    "left_option": "left_command",
    "right_command": "right_option",
    "right_option": "right_command",
}
simples = device["simple_modifications"]
assert len(simples) == len(expected_simples), simples
mappings = {}
for entry in simples:
    assert set(entry) == {"from", "to"}, entry
    source = entry["from"]["key_code"]
    target = entry["to"]
    assert len(target) == 1 and set(target[0]) == {"key_code"}, target
    mappings[source] = target[0]["key_code"]
assert mappings == expected_simples, mappings
print("karabiner.json shape OK")
PY

# Deployment is gated on the Karabiner app being installed; the module must be
# listed in the root README tree (repo_docs_test guards the tree too).
assert_contains '[ -d /Applications/Karabiner-Elements.app ]' "$INSTALL_FILE"
assert_contains 'karabiner/karabiner.json|~/.config/karabiner/karabiner.json|Karabiner-Elements' "$INSTALL_FILE"
assert_contains 'karabiner/' "$ROOT_README"
# The README documents the mapping and the mechanism it relies on.
assert_file_exists "$KARABINER_README"
assert_contains 'Caps' "$KARABINER_README"
assert_contains 'to_if_alone' "$KARABINER_README"
assert_contains 'Win/Alt' "$KARABINER_README"
assert_contains '大写锁定' "$KARABINER_README"
assert_contains 'device_if' "$KARABINER_README"
# macOS rewrites caps_lock semantics while its "Use the Caps Lock key to switch"
# option is on (tap = switch input source, hold = toggle caps), which turns the
# escape -> caps_lock mapping into an input-source switcher. The prerequisite
# must stay documented.
assert_contains '使用大写锁定键切换' "$KARABINER_README"
assert_contains 'CapsLockDelayOverride' "$KARABINER_README"

printf 'PASS: karabiner config tests\n'
