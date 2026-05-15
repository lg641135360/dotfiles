#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVIM="$ROOT/.config/shared/nvim"
fixture="$(mktemp -d)"
out_file="$(mktemp)"
probe_lua="$(mktemp)"
nvim_data="$(mktemp -d)"
nvim_state="$(mktemp -d)"
nvim_cache="$(mktemp -d)"

cleanup() {
  rm -rf "$fixture" "$out_file" "$probe_lua" "$nvim_data" "$nvim_state" "$nvim_cache"
}
trap cleanup EXIT

mkdir -p "$fixture/project"
printf 'hello\n' > "$fixture/project/a.txt"

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

cat >"$probe_lua" <<'LUA'
local project = vim.env.NVIM_NEOTREE_TEST_PROJECT
local file = project .. "/a.txt"

vim.cmd("cd " .. vim.fn.fnameescape(project))
vim.cmd("edit " .. vim.fn.fnameescape(file))
vim.cmd("Neotree show")
vim.cmd("wincmd p")

local file_buf = vim.api.nvim_get_current_buf()
print("NEOTREE_TOGGLE_INITIAL_WINS=" .. #vim.api.nvim_list_wins())

vim.cmd("BufferClose")
print("NEOTREE_TOGGLE_POST_BUFFER_CLOSE_WINS=" .. #vim.api.nvim_list_wins())
print("NEOTREE_TOGGLE_FILE_BUFFER_LISTED=" .. tostring(vim.fn.buflisted(file_buf)))
print("NEOTREE_TOGGLE_POST_BUFFER_CLOSE_BUFTYPE=" .. tostring(vim.bo.buftype))
print("NEOTREE_TOGGLE_POST_BUFFER_CLOSE_BUFNAME=" .. tostring(vim.api.nvim_buf_get_name(0)))

vim.cmd("Neotree toggle")
print("NEOTREE_TOGGLE_STILL_RUNNING=true")
print("NEOTREE_TOGGLE_FINAL_WINS=" .. #vim.api.nvim_list_wins())
print("NEOTREE_TOGGLE_FINAL_EMPTY_BUF=" .. tostring(vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) == ""))
print("NEOTREE_TOGGLE_FINAL_FILETYPE=" .. tostring(vim.bo.filetype))

if vim.fn.buflisted(file_buf) ~= 0 then
  error("closing the file buffer should remove it from the listed set before toggling Neo-tree")
end
if #vim.api.nvim_list_wins() ~= 1 then
  error("toggling Neo-tree after closing the file should leave a single window")
end
if vim.bo.buftype ~= "" or vim.api.nvim_buf_get_name(0) ~= "" then
  error("toggling Neo-tree after closing the file should land on an empty unnamed buffer")
end

vim.cmd("Neotree show")
vim.cmd("Neotree focus")
print("NEOTREE_EMPTY_SESSION_OPEN_WINS=" .. #vim.api.nvim_list_wins())

vim.cmd("Neotree close")
print("NEOTREE_EMPTY_SESSION_STILL_RUNNING=true")
print("NEOTREE_EMPTY_SESSION_FINAL_WINS=" .. #vim.api.nvim_list_wins())
print("NEOTREE_EMPTY_SESSION_FINAL_EMPTY_BUF=" .. tostring(vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) == ""))

if #vim.api.nvim_list_wins() ~= 1 then
  error("closing Neo-tree from the empty session fallback should leave one window")
end
if vim.bo.buftype ~= "" or vim.api.nvim_buf_get_name(0) ~= "" then
  error("closing Neo-tree from the empty session fallback should keep the empty unnamed buffer")
end
LUA

NVIM_NEOTREE_TEST_PROJECT="$fixture/project" \
XDG_CONFIG_HOME="$ROOT/.config/shared" \
XDG_DATA_HOME="$nvim_data" \
XDG_STATE_HOME="$nvim_state" \
XDG_CACHE_HOME="$nvim_cache" \
nvim --headless -i NONE -u "$NVIM/init.lua" \
  --cmd 'set noswapfile' \
  "+luafile $probe_lua" \
  '+qa!' >"$out_file" 2>&1

if rg -n "Error detected while processing|stack traceback|E5108|E5113|module .* not found" "$out_file"; then
  cat "$out_file"
  exit 1
fi

for pattern in \
  'NEOTREE_TOGGLE_INITIAL_WINS=2' \
  'NEOTREE_TOGGLE_POST_BUFFER_CLOSE_WINS=2' \
  'NEOTREE_TOGGLE_FILE_BUFFER_LISTED=0' \
  'NEOTREE_TOGGLE_STILL_RUNNING=true' \
  'NEOTREE_TOGGLE_FINAL_WINS=1' \
  'NEOTREE_TOGGLE_FINAL_EMPTY_BUF=true' \
  'NEOTREE_EMPTY_SESSION_OPEN_WINS=1' \
  'NEOTREE_EMPTY_SESSION_STILL_RUNNING=true' \
  'NEOTREE_EMPTY_SESSION_FINAL_WINS=1' \
  'NEOTREE_EMPTY_SESSION_FINAL_EMPTY_BUF=true'; do
  if ! rg -q -- "$pattern" "$out_file"; then
    echo "missing expected Neo-tree close behavior evidence: $pattern"
    cat "$out_file"
    exit 1
  fi
done

echo "nvim-neo-tree-close-behavior-ok"
