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

cat >"$fixture/render-markdown.md" <<'EOF'
# Demo

```lua
local x = 1
print(x)
```
EOF

cat >"$probe_lua" <<'LUA'
local file = vim.env.NVIM_RENDER_MD_TEST_FILE

vim.cmd("edit " .. vim.fn.fnameescape(file))
vim.wait(300)

local bufnr = vim.api.nvim_get_current_buf()
local win = vim.api.nvim_get_current_win()
local manager = require("render-markdown.core.manager")
local ui = require("render-markdown.core.ui")
local api = require("render-markdown")

api.enable()

print("RENDER_MD_FILETYPE=" .. tostring(vim.bo[bufnr].filetype))
print("RENDER_MD_PATCH_APPLIED=" .. tostring(vim.g.nvim_treesitter_query_predicates_compat_applied))
print("RENDER_MD_ATTACHED_INITIAL=" .. tostring(manager.attached(bufnr)))

ui.update(bufnr, win, "UserCommand", true)
vim.wait(500)

local marks = vim.api.nvim_buf_get_extmarks(bufnr, ui.ns, 0, -1, {})

print("RENDER_MD_ATTACHED_FINAL=" .. tostring(manager.attached(bufnr)))
print("RENDER_MD_EXTMARK_COUNT=" .. tostring(#marks))
print("RENDER_MD_FORCE_UPDATE_OK=true")

if not manager.attached(bufnr) then
  error("render-markdown should attach to markdown buffers")
end
if #marks == 0 then
  error("render-markdown should produce extmarks for a fenced-code markdown buffer")
end
LUA

NVIM_RENDER_MD_TEST_FILE="$fixture/render-markdown.md" \
XDG_CONFIG_HOME="$ROOT/.config/shared" \
XDG_DATA_HOME="$nvim_data" \
XDG_STATE_HOME="$nvim_state" \
XDG_CACHE_HOME="$nvim_cache" \
nvim --headless -i NONE -u "$NVIM/init.lua" \
  --cmd 'set noswapfile' \
  "+luafile $probe_lua" \
  '+qa!' >"$out_file" 2>&1

if rg -n "Error detected while processing|stack traceback|E5108|E5113|attempt to call method 'range'|module .* not found" "$out_file"; then
  cat "$out_file"
  exit 1
fi

for pattern in \
  'RENDER_MD_FILETYPE=markdown' \
  'RENDER_MD_PATCH_APPLIED=true' \
  'RENDER_MD_ATTACHED_INITIAL=true' \
  'RENDER_MD_ATTACHED_FINAL=true' \
  'RENDER_MD_EXTMARK_COUNT=[1-9]' \
  'RENDER_MD_FORCE_UPDATE_OK=true'; do
  if ! rg -q -- "$pattern" "$out_file"; then
    echo "missing expected render-markdown compatibility evidence: $pattern"
    cat "$out_file"
    exit 1
  fi
done

echo "nvim-render-markdown-treesitter-compat-ok"
