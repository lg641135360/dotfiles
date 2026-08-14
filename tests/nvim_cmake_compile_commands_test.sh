#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVIM="$ROOT/.config/shared/nvim"
fixture="$(mktemp -d)"
out_file="$(mktemp)"
probe_lua="$(mktemp --suffix=.lua)"
nvim_data="$(mktemp -d)"
nvim_state="$(mktemp -d)"
nvim_cache="$(mktemp -d)"

cleanup() {
  rm -rf "$fixture" "$out_file" "$probe_lua" "$nvim_data" "$nvim_state" "$nvim_cache"
}
trap cleanup EXIT

project="$fixture/project"
mkdir -p "$project"
printf 'cmake_minimum_required(VERSION 3.16)\nproject(fixture C)\n' > "$project/CMakeLists.txt"

mkdir -p "$nvim_data/nvim"
if [[ -d "$HOME/.local/share/nvim/lazy" ]]; then
  ln -s "$HOME/.local/share/nvim/lazy" "$nvim_data/nvim/lazy"
fi
if [[ -d "$HOME/.local/share/nvim/mason" ]]; then
  ln -s "$HOME/.local/share/nvim/mason" "$nvim_data/nvim/mason"
fi
if [[ -f "$HOME/.cache/nvim/mason-registry-update" ]]; then
  mkdir -p "$nvim_cache/nvim"
  cp "$HOME/.cache/nvim/mason-registry-update" "$nvim_cache/nvim/mason-registry-update"
fi

cat > "$probe_lua" <<'LUA'
local project = assert(vim.env.NVIM_CMAKE_TEST_PROJECT)
local root_link = project .. "/compile_commands.json"
local database = project .. "/build/compile_commands.json"
local messages = {}

vim.notify = function(message)
  table.insert(messages, tostring(message))
end

vim.cmd("cd " .. vim.fn.fnameescape(project))
local cmake = require("config.cmake")

if vim.fn.exists(":CMakeCompileCommands") ~= 2 then
  error(":CMakeCompileCommands user command was not registered")
end

local function clear_messages()
  messages = {}
end

local function last_message()
  return messages[#messages] or ""
end

local function assert_contains(text, needle, label)
  if not text:find(needle, 1, true) then
    error(label .. ": expected " .. needle .. " in " .. text)
  end
end

local function assert_equal(actual, expected, label)
  if actual ~= expected then
    error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
  end
end

-- Missing database must report an actionable error and create nothing.
clear_messages()
assert_equal(cmake.link_compile_commands(), false, "missing database result")
assert_contains(last_message(), "Run :CMakeConfigure first.", "missing database message")
if vim.uv.fs_lstat(root_link) then
  error("missing database must not create compile_commands.json")
end

vim.fn.mkdir(project .. "/build", "p")
vim.fn.writefile({ "[]" }, database)

-- The first successful call creates a relative link.
clear_messages()
assert_equal(cmake.link_compile_commands(), true, "create link result")
local link_stat = vim.uv.fs_lstat(root_link)
assert_equal(link_stat and link_stat.type, "link", "created link type")
assert_equal(vim.uv.fs_readlink(root_link), "build/compile_commands.json", "created link target")
assert_contains(last_message(), "Created compile_commands.json", "create link message")

-- A correct existing link is safe and idempotent.
clear_messages()
assert_equal(cmake.link_compile_commands(), true, "existing link result")
assert_contains(last_message(), "already points", "existing link message")

-- A regular file must never be overwritten.
assert_equal(vim.uv.fs_unlink(root_link), true, "remove test link")
vim.fn.writefile({ "regular file" }, root_link)
clear_messages()
assert_equal(cmake.link_compile_commands(), false, "regular file result")
assert_contains(last_message(), "Refusing to overwrite", "regular file message")

-- A link that points elsewhere must also be preserved.
assert_equal(vim.uv.fs_unlink(root_link), true, "remove regular test file")
vim.fn.writefile({ "[]" }, project .. "/other.json")
assert_equal(vim.uv.fs_symlink("other.json", root_link, 0), true, "create conflicting test link")
clear_messages()
assert_equal(cmake.link_compile_commands(), false, "conflicting link result")
assert_contains(last_message(), "Refusing to replace", "conflicting link message")
assert_equal(vim.uv.fs_readlink(root_link), "other.json", "conflicting link preserved")

print("nvim-cmake-compile-commands-ok")
LUA

XDG_CONFIG_HOME="$ROOT/.config/shared" \
XDG_DATA_HOME="$nvim_data" \
XDG_STATE_HOME="$nvim_state" \
XDG_CACHE_HOME="$nvim_cache" \
NVIM_CMAKE_TEST_PROJECT="$project" \
nvim --headless -i NONE -u "$NVIM/init.lua" \
  "+luafile $probe_lua" \
  '+qa!' >"$out_file" 2>&1

if rg -n "Error detected while processing|stack traceback|E5108|E5113|module .* not found" "$out_file"; then
  cat "$out_file"
  exit 1
fi

rg -q -- 'nvim-cmake-compile-commands-ok' "$out_file" || {
  cat "$out_file"
  exit 1
}

echo "nvim-cmake-compile-commands-ok"
