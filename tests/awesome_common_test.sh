#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
COMMON_FILE=$REPO_ROOT/.config/linux/awesome/lib/common.lua

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

[ -f "$COMMON_FILE" ] || fail "expected common helper module to exist"

lua - "$COMMON_FILE" <<'LUA' || fail "expected common helper module behavior to match contract"
local common_file = arg[1]
local common = assert(loadfile(common_file))()

assert(type(common.command_exists) == "function")
assert(type(common.read_command_output) == "function")
assert(type(common.stop_timer) == "function")
assert(type(common.truncate_message) == "function")
assert(type(common.shell_quote) == "function")

assert(common.truncate_message("  hello  ") == "hello")
assert(common.truncate_message("") == nil)
assert(common.truncate_message(string.rep("a", 241)):match("%.%.%.$"))
assert(common.shell_quote("a'b") == "'a'\\''b'")
assert(common.command_exists("sh") == true)
assert(common.command_exists("definitely-not-a-real-command") == false)
assert(common.read_command_output("printf 'ok'") == "ok")
assert(common.read_command_output("printf ''") == nil)

local timer = {
    stopped = false,
    stop = function(self)
        self.stopped = true
    end,
}
common.stop_timer(timer)
assert(timer.stopped == true)

local fallback_timer = { started = true }
common.stop_timer(fallback_timer)
assert(fallback_timer.started == false)
LUA

printf 'PASS: awesome common helper tests\n'
