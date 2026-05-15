#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVIM="$ROOT/.config/shared/nvim"
fixture="$(mktemp -d)"
out_file="$(mktemp)"
poc_lua="$(mktemp)"

cleanup() {
  rm -rf "$fixture" "$out_file" "$poc_lua"
}
trap cleanup EXIT

cd "$fixture"
git init -q
git config user.name "nvim-poc"
git config user.email "nvim-poc@example.invalid"
printf 'tracked\n' > tracked.txt
git add tracked.txt
git commit -q -m init
printf 'changed\n' >> tracked.txt
printf 'ignored.log\n' > .gitignore
printf 'ignored\n' > ignored.log
printf 'hidden\n' > .hidden
printf 'new\n' > untracked.txt
mkdir -p nested
printf 'current\n' > nested/current.txt

cat >"$poc_lua" <<'LUA'
local function find_line(lines, needle)
  for _, line in ipairs(lines) do
    if line:find(needle, 1, true) then
      return line
    end
  end
  return ""
end

vim.g.netrw_liststyle = 3
vim.o.columns = 120
vim.o.lines = 40
vim.cmd("edit nested/current.txt")
vim.cmd("Lexplore")

local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
local joined = table.concat(lines, "\n")
local current_line = vim.api.nvim_get_current_line()
local tracked_line = find_line(lines, "tracked.txt")
local untracked_line = find_line(lines, "untracked.txt")
local hidden_visible = joined:find(".hidden", 1, true) ~= nil
local gitignored_visible = joined:find("ignored.log", 1, true) ~= nil
local follow_current = current_line:find("current.txt", 1, true) ~= nil

-- Netrw lists files but does not decorate file lines with Neo-tree-like Git status.
-- Keep this prefix-based check narrow so file names containing M/? do not count as status.
local git_status_markers = tracked_line:match("^%s*[M?%!%+%-%*]") ~= nil
  or untracked_line:match("^%s*[M?%!%+%-%*]") ~= nil

print("NETRW_FILETYPE=" .. tostring(vim.bo.filetype))
print("NETRW_WINDOW_COUNT=" .. tostring(#vim.api.nvim_list_wins()))
print("NETRW_HIDDEN_VISIBLE=" .. tostring(hidden_visible))
print("NETRW_GITIGNORED_VISIBLE=" .. tostring(gitignored_visible))
print("NETRW_TRACKED_LINE=" .. tracked_line)
print("NETRW_UNTRACKED_LINE=" .. untracked_line)
print("NETRW_CURRENT_LINE=" .. current_line)
print("NETRW_FOLLOW_CURRENT=" .. tostring(follow_current))
print("NETRW_GIT_STATUS_MARKERS=" .. tostring(git_status_markers))
print("NETRW_PARITY_GAP=follow-current-file,git-status")

if not hidden_visible then
  error("netrw POC should at least show hidden dotfiles for this comparison")
end
if not gitignored_visible then
  error("netrw POC should at least show gitignored files for this comparison")
end
if follow_current or git_status_markers then
  error("netrw parity unexpectedly improved; revisit Neo-tree keep/replacement decision")
end
print("NATIVE_POC_DECISION=keep-neo-tree")
LUA

nvim --headless --clean \
  --cmd 'set noswapfile' \
  "+luafile $poc_lua" \
  '+qa!' >"$out_file" 2>&1

if rg -n "Error detected while processing|stack traceback|E5113" "$out_file"; then
  cat "$out_file"
  exit 1
fi

for pattern in \
  'NETRW_FILETYPE=netrw' \
  'NETRW_WINDOW_COUNT=2' \
  'NETRW_HIDDEN_VISIBLE=true' \
  'NETRW_GITIGNORED_VISIBLE=true' \
  'NETRW_FOLLOW_CURRENT=false' \
  'NETRW_GIT_STATUS_MARKERS=false' \
  'NETRW_PARITY_GAP=follow-current-file,git-status' \
  'NATIVE_POC_DECISION=keep-neo-tree'; do
  if ! rg -q -- "$pattern" "$out_file"; then
    echo "missing expected POC evidence: $pattern"
    cat "$out_file"
    exit 1
  fi
done

# The active repo config should still keep Neo-tree and netrw disabled.
rg -q 'nvim-neo-tree/neo-tree.nvim' "$NVIM/lua/plugins/neo-tree.lua"
rg -q 'vim\.g\.loaded_netrw = 1' "$NVIM/lua/config/options"
rg -q 'vim\.g\.loaded_netrwPlugin = 1' "$NVIM/lua/config/options"

echo "nvim-neo-tree-native-poc-ok"
