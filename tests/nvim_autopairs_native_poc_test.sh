#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVIM="$ROOT/.config/shared/nvim"
out_file="$(mktemp)"
script_file="$(mktemp --suffix=.lua)"
state_home="$(mktemp -d)"
cache_home="$(mktemp -d)"

cleanup() {
  rm -f "$out_file" "$script_file"
  rm -rf "$state_home" "$cache_home"
}
trap cleanup EXIT

require_pattern() {
  local pattern="$1"
  local file="$2"
  local message="$3"

  if ! rg -q -- "$pattern" "$file"; then
    echo "$message"
    exit 1
  fi
}

reject_pattern() {
  local pattern="$1"
  local file="$2"
  local message="$3"

  if rg -q -- "$pattern" "$file"; then
    echo "$message"
    exit 1
  fi
}

require_pattern 'require\("config.autopairs"\)\.setup\(\)' "$NVIM/init.lua" "init.lua should load the native pairs helper"
require_pattern 'local open_to_close = \{' "$NVIM/lua/config/autopairs.lua" "native pairs helper should keep an explicit pair matrix"
require_pattern 'blink\.is_visible\(\)' "$NVIM/lua/config/autopairs.lua" "native pairs helper should detect visible blink completion before handling Enter"
require_pattern 'blink\.accept\(\)' "$NVIM/lua/config/autopairs.lua" "native pairs helper should delegate completion acceptance to blink"
reject_pattern 'windwp/nvim-autopairs|nvim%-autopairs|nvim-autopairs' "$NVIM/lua/plugins" "nvim-autopairs plugin spec should be removed on the replacement branch"
reject_pattern '"nvim-autopairs"' "$NVIM/lazy-lock.json" "nvim-autopairs should be removed from lazy-lock on the replacement branch"
require_pattern '"<Tab>"' "$NVIM/lua/plugins/blink-cmp.lua" "blink.cmp should still own Tab completion/snippet behavior"
require_pattern '"<S-Tab>"' "$NVIM/lua/plugins/blink-cmp.lua" "blink.cmp should still own Shift-Tab completion/snippet behavior"
require_pattern '"<CR>"\] = \{ "accept", "fallback" \}' "$NVIM/lua/plugins/blink-cmp.lua" "blink.cmp should keep its Enter accept/fallback contract"
require_pattern 'rafamadriz/friendly-snippets' "$NVIM/lua/plugins/blink-cmp.lua" "friendly-snippets should remain protected"
require_pattern 'L3MON4D3/LuaSnip' "$NVIM/lua/plugins/blink-cmp.lua" "LuaSnip should remain protected"
require_pattern 'native pairs helper' "$NVIM/README.md" "README should document the native pairs replacement"
reject_pattern 'Editing.*nvim-autopairs|nvim-autopairs.*Editing' "$NVIM/README.md" "README editing table should not list nvim-autopairs as active"

cat >"$script_file" <<'LUA'
local nvim_config = assert(vim.env.NVIM_CONFIG, "NVIM_CONFIG missing")
package.path = nvim_config .. "/lua/?.lua;" .. nvim_config .. "/lua/?/init.lua;" .. package.path

local function termcodes(keys)
  return vim.api.nvim_replace_termcodes(keys, true, false, true)
end

local function feed(keys)
  vim.api.nvim_feedkeys(termcodes(keys), "xt", false)
  vim.cmd("redraw")
end

local function assert_equal(actual, expected, label)
  if actual ~= expected then
    error(("%s: expected %q, got %q"):format(label, tostring(expected), tostring(actual)))
  end
end

local function assert_lines(expected, label)
  local actual = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  assert_equal(actual, table.concat(expected, "\n"), label)
end

local function reset()
  feed("<Esc>")
  vim.cmd("enew!")
  vim.bo.buftype = ""
  vim.bo.modifiable = true
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "" })
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

require("config.autopairs").setup()

local function assert_pair(open, expected)
  reset()
  feed("i" .. open .. "x")
  assert_lines({ expected }, "basic pair " .. open)
end

assert_pair("(", "(x)")
assert_pair("[", "[x]")
assert_pair("{", "{x}")
assert_pair("'", "'x'")
assert_pair('"', '"x"')

local function assert_backspace(open)
  reset()
  feed("i" .. open .. "<BS>")
  assert_lines({ "" }, "empty pair backspace " .. open)
end

assert_backspace("(")
assert_backspace("[")
assert_backspace("{")
assert_backspace("'")
assert_backspace('"')

local function assert_skip(open, close, expected)
  reset()
  feed("i" .. open .. close .. "x")
  assert_lines({ expected }, "skip closing " .. close)
end

assert_skip("(", ")", "()x")
assert_skip("[", "]", "[]x")
assert_skip("{", "}", "{}x")
assert_skip("'", "'", "''x")
assert_skip('"', '"', '""x')

local function assert_enter(open, expected_lines)
  reset()
  feed("i" .. open .. "<CR>x")
  assert_lines(expected_lines, "pair enter newline " .. open)
end

assert_enter("(", { "(", "x", ")" })
assert_enter("[", { "[", "x", "]" })
assert_enter("{", { "{", "x", "}" })

local blink_accepts = 0
package.loaded["blink.cmp"] = {
  is_visible = function()
    return true
  end,
  accept = function()
    blink_accepts = blink_accepts + 1
    return true
  end,
}

reset()
feed("i(<CR>x")
assert_lines({ "(x)" }, "visible blink menu should prevent native pair newline")
assert_equal(blink_accepts, 1, "visible blink menu should receive Enter")

local blink_fallbacks = 0
package.loaded["blink.cmp"] = {
  is_visible = function()
    return true
  end,
  accept = function()
    blink_fallbacks = blink_fallbacks + 1
    return false
  end,
}

reset()
feed("i(<CR>x")
assert_lines({ "(", "x)" }, "visible blink menu without an accepted item should fall back to a plain Enter")
assert_equal(blink_fallbacks, 1, "visible blink menu fallback should still call blink.accept once")

local cr_mapping = vim.fn.maparg("<CR>", "i", false, true)
local tab_mapping = vim.fn.maparg("<Tab>", "i", false, true)
local stab_mapping = vim.fn.maparg("<S-Tab>", "i", false, true)
print("NATIVE_AUTOPAIRS_CR_DESC=" .. tostring(cr_mapping.desc))
print("NATIVE_AUTOPAIRS_TAB_DESC=" .. tostring(tab_mapping.desc))
print("NATIVE_AUTOPAIRS_STAB_DESC=" .. tostring(stab_mapping.desc))
print("NATIVE_AUTOPAIRS_BLINK_ACCEPTS=" .. tostring(blink_accepts))
print("NATIVE_AUTOPAIRS_BLINK_FALLBACKS=" .. tostring(blink_fallbacks))
print("nvim-autopairs-native-poc-ok")
LUA

set +e
NVIM_CONFIG="$NVIM" \
XDG_STATE_HOME="$state_home" \
XDG_CACHE_HOME="$cache_home" \
  nvim --clean --headless -i NONE \
    --cmd 'set noswapfile' \
    "+luafile $script_file" \
    '+qa!' >"$out_file" 2>&1
rc=$?
set -e

if [[ "$rc" -ne 0 ]]; then
  cat "$out_file"
  exit 1
fi

if rg -n "Error in command line|Error detected while processing|stack traceback|EPERM|E5113|module .* not found" "$out_file"; then
  cat "$out_file"
  exit 1
fi

require_pattern 'NATIVE_AUTOPAIRS_CR_DESC=Native pairs: newline inside empty pair' "$out_file" "Enter should be handled by the native pairs helper"
reject_pattern 'NATIVE_AUTOPAIRS_TAB_DESC=Native pairs' "$out_file" "native pairs helper must not map Tab"
reject_pattern 'NATIVE_AUTOPAIRS_STAB_DESC=Native pairs' "$out_file" "native pairs helper must not map Shift-Tab"
require_pattern 'NATIVE_AUTOPAIRS_BLINK_ACCEPTS=1' "$out_file" "native pairs helper should delegate visible-menu Enter to blink"
require_pattern 'NATIVE_AUTOPAIRS_BLINK_FALLBACKS=1' "$out_file" "native pairs helper should keep a plain Enter fallback when blink cannot accept"
require_pattern 'nvim-autopairs-native-poc-ok' "$out_file" "native autopairs POC smoke should finish"

echo "nvim-autopairs-native-poc-ok"
