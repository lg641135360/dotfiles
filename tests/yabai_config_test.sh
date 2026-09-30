#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tests/lib/assert.sh"

YAIRC=$ROOT/.config/macos/yabai/yabairc
SKHDRC=$ROOT/.config/macos/yabai/skhdrc
README=$ROOT/.config/macos/yabai/README.md
ROOT_README=$ROOT/README.md
AEROSPACE_README=$ROOT/.config/macos/aerospace/README.md
INSTALL_FILE=$ROOT/install.sh
DEFAULTS_SH=$ROOT/.config/macos/defaults.sh

# yabairc is a POSIX sh script executed by yabai; keep it parseable.
sh -n "$YAIRC" || fail "yabairc should be valid POSIX sh"

# --- scripting addition ----------------------------------------------------
# Space create/destroy and sticky/pip depend on the SA; it must be loaded from
# the config and re-loaded whenever Dock restarts.
assert_contains 'sudo yabai --load-sa' "$YAIRC"
assert_contains 'event=dock_did_restart' "$YAIRC"

# --- global config ---------------------------------------------------------
assert_matches 'window_gap[[:space:]]+5' "$YAIRC"
assert_matches 'layout[[:space:]]+bsp' "$YAIRC"
assert_matches 'window_shadow[[:space:]]+on' "$YAIRC"
# Windows must stay fully opaque: terminals bring their own transparency
# (matches memory/desktop.md, which forbids forcing opacity back to 100%).
assert_matches 'window_opacity[[:space:]]+off' "$YAIRC"
# Focus/insert feedback must use the repository-wide focus colour — Catppuccin
# Mocha blue (#89b4fa), same as niri's focus-ring and awesome's border_focus.
assert_matches 'insert_feedback_color[[:space:]]+0xff89b4fa' "$YAIRC"

# --- window rules ----------------------------------------------------------
assert_contains 'app="^Finder$"' "$YAIRC"
assert_contains 'manage=off' "$YAIRC"
# app= matches the *localized* application name (AppleLocale=zh_CN here), so the
# rules must carry the Chinese names as well or they silently never match.
assert_contains 'app="^(WeChat|微信)$"' "$YAIRC"
assert_contains '系统设置' "$YAIRC"
# yabai rules only affect windows spawned after registration; --apply replays
# them onto already-open windows at startup.
assert_contains 'yabai -m rule --apply' "$YAIRC"
# Named workspaces were dropped in favour of index-addressed 1..5, so no rule
# may reference a space label any more (yabai would reject them at
# registration time once the labels stop existing).
assert_not_contains 'space=C' "$YAIRC"
assert_not_contains 'space=N' "$YAIRC"

# yabai lives in ~/.local/bin, which only path.zsh adds to PATH. install.sh runs
# under bash, so it must add that directory itself or the yabai configuration is
# silently skipped whenever the script is not started from the interactive shell.
assert_contains 'export PATH="$HOME/.local/bin:$PATH"' "$INSTALL_FILE"
# --- spaces ----------------------------------------------------------------
# Exactly 5 spaces, addressed by mission-control index. yabai rejects purely
# numeric labels ('1' cannot be used as a label.), so the config must not try to
# label anything.
assert_contains 'ensure_spaces' "$YAIRC"
assert_contains 'while [ "${_count:-0}" -lt 5 ]' "$YAIRC"
# No *executable* space --label call: the only mention may be the explanatory
# comment (comments start with '#').
assert_not_matches '^[^#]*space --label' "$YAIRC"

# --- skhd bindings ---------------------------------------------------------
# skhd has no config-validation or dry-run mode (unlike `niri validate`), so
# parse the config here: the binding table must match exactly. Missing,
# duplicate and unexpected bindings all fail, which keeps the README table and
# the config from drifting apart.
resolve_python || exit $?
"$PYTHON_BIN" - "$SKHDRC" <<'PY'
import sys
from pathlib import Path

# alt = Mod. Keep in sync with the "常用快捷键" table in README.md.
expected = {
    "alt - return": "open -na Alacritty",
    "alt - e": "open -a Finder",
    "alt - q": "yabai -m window --close",
    "alt - f": "yabai -m window --toggle zoom-fullscreen",
    "alt + ctrl - f": "yabai -m window --toggle float",
    "alt + ctrl - d": "yabai -m window --toggle zoom-parent",
    "alt + ctrl - b": "yabai -m space --balance",
    "alt + ctrl - t": "yabai -m window --toggle sticky",
    "alt + ctrl - p": "yabai -m window --toggle pip",
    "alt - 0x2C": "yabai -m space --layout bsp",
    "alt - 0x2B": "yabai -m space --layout stack",
    "alt - h": "yabai -m window --focus west",
    "alt - j": "yabai -m window --focus south",
    "alt - k": "yabai -m window --focus north",
    "alt - l": "yabai -m window --focus east",
    "alt + shift - h": "yabai -m window --swap west",
    "alt + shift - j": "yabai -m window --swap south",
    "alt + shift - k": "yabai -m window --swap north",
    "alt + shift - l": "yabai -m window --swap east",
    "alt - 1": "yabai -m space --focus 1",
    "alt - 2": "yabai -m space --focus 2",
    "alt - 3": "yabai -m space --focus 3",
    "alt - 4": "yabai -m space --focus 4",
    "alt - 5": "yabai -m space --focus 5",
    "alt + shift - 1": "yabai -m window --space 1 && yabai -m space --focus 1",
    "alt + shift - 2": "yabai -m window --space 2 && yabai -m space --focus 2",
    "alt + shift - 3": "yabai -m window --space 3 && yabai -m space --focus 3",
    "alt + shift - 4": "yabai -m window --space 4 && yabai -m space --focus 4",
    "alt + shift - 5": "yabai -m window --space 5 && yabai -m space --focus 5",
    "alt - tab": "yabai -m space --focus recent",
    "alt + shift - tab": "yabai -m display --focus next",
}

# The two resize bindings are long "try every fence" chains; they are checked
# structurally below instead of as exact strings.
resize_keys = {"alt + shift - 0x1B", "alt + shift - 0x18"}

logical = []
buffer = ""
for raw in Path(sys.argv[1]).read_text(encoding="utf-8").splitlines():
    code = raw.split("#", 1)[0].rstrip()
    if not code.strip():
        continue
    if code.endswith("\\"):
        buffer += code[:-1]
        continue
    logical.append(" ".join((buffer + code).split()))
    buffer = ""
if buffer:
    raise SystemExit("dangling line continuation in skhdrc")

bindings = {}
for line in logical:
    if ":" not in line:
        raise SystemExit(f"unparsable skhdrc line: {line!r}")
    key, command = line.split(":", 1)
    key = key.strip()
    if key in bindings:
        raise SystemExit(f"duplicate skhdrc binding for {key!r}")
    bindings[key] = command.strip()

missing = sorted(set(expected) - set(bindings))
unexpected = sorted(set(bindings) - set(expected) - resize_keys)
if missing:
    raise SystemExit(f"missing skhdrc bindings: {missing}")
if unexpected:
    raise SystemExit(
        f"skhdrc has bindings not covered by the README/tests: {unexpected}"
    )
for key, want in expected.items():
    if bindings[key] != want:
        raise SystemExit(f"{key}: expected {want!r}, got {bindings[key]!r}")

# Both resize directions must try every fence side (east/west for the first and
# second split child) and both axes, and must silence the attempts that fail.
for key, needles in (
    (
        "alt + shift - 0x1B",
        (
            "--resize right:-50:0",
            "--resize left:50:0",
            "--resize bottom:0:-50",
            "--resize top:0:50",
        ),
    ),
    (
        "alt + shift - 0x18",
        (
            "--resize right:50:0",
            "--resize left:-50:0",
            "--resize bottom:0:50",
            "--resize top:0:-50",
        ),
    ),
):
    command = bindings[key]
    for needle in needles:
        if needle not in command:
            raise SystemExit(f"{key}: missing {needle!r}")
    if "2>/dev/null" not in command:
        raise SystemExit(f"{key}: failing attempts would spam the skhd log")
    if ";" in command:
        raise SystemExit(f"{key}: ';' switches skhd modes; use '||' instead")

# skhd only knows the literal names return/tab/space/backspace/escape/delete/
# arrows/F1-F20/media keys. Punctuation must use uppercase hex keycodes.
for key in bindings:
    tail = key.rsplit(" ", 1)[-1]
    if tail in {"minus", "equal", "esc", "slash", "comma", "backslash", "period"}:
        raise SystemExit(f"{key}: skhd has no literal name {tail!r}")
    if "0x" in tail:
        digits = tail.rsplit("0x", 1)[1]
        if not digits or any(c in "abcdef" for c in digits):
            raise SystemExit(
                f"{key}: skhd's eat_hex only accepts uppercase A-F ({digits!r})"
            )
print("skhd bindings OK")
PY

# --- README ----------------------------------------------------------------
# The hackintosh-vs-white-Mac preference must be stated in both WM readmes.
assert_contains '黑苹果' "$README"
assert_contains '白苹果' "$README"
assert_contains 'yabai + skhd' "$README"
assert_contains 'Mod+Shift+1/2/3/4/5' "$README"
assert_contains 'scripting-addition failed to inject payload' "$README"
# Mouse bindings are configured (mouse_modifier/mouse_action*) and must be
# documented, like awesome's "鼠标操作" table.
assert_contains '## 鼠标操作' "$README"
assert_contains '拖拽' "$README"
# skhd cannot be validated offline, so the README must say how to verify a
# deployed config (mirrors niri's "配置验证" section).
assert_contains '## 配置验证' "$README"
assert_contains 'sh -n ~/.config/yabai/yabairc' "$README"
assert_contains 'yabai -m query --spaces' "$README"
assert_contains 'yabai + skhd' "$AEROSPACE_README"
assert_contains '黑苹果' "$AEROSPACE_README"

# --- root README -----------------------------------------------------------
# Root README documents the upgrade path alongside the other user-level tools
# (per-tool updaters section, no wrapper script).
assert_contains 'sudoers.d/yabai' "$ROOT_README"
assert_contains 'yabai --start-service' "$ROOT_README"

# --- install.sh deployment ------------------------------------------------
assert_contains 'command -v yabai|.config/macos/yabai/yabairc|~/.config/yabai/yabairc|yabai' "$INSTALL_FILE"
assert_contains 'command -v skhd|.config/macos/yabai/skhdrc|~/.config/skhd/skhdrc|skhd' "$INSTALL_FILE"
# JankyBorders only serves AeroSpace; the hint must be gated on it.
assert_contains 'command -v aerospace &> /dev/null && ! command -v borders' "$INSTALL_FILE"

# --- macOS prerequisites ---------------------------------------------------
assert_contains 'com.apple.dock mru-spaces false' "$DEFAULTS_SH"
assert_contains 'com.apple.WindowManager EnableStandardClickToShowDesktop false' "$DEFAULTS_SH"

printf 'PASS: yabai config tests\n'
