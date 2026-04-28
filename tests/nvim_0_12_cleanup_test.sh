#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVIM="$ROOT/.config/shared/nvim"
out_file="$(mktemp)"
data_home="$(mktemp -d)"
state_home="$(mktemp -d)"
cache_home="$(mktemp -d)"

cleanup() {
  rm -rf "$out_file" "$data_home" "$state_home" "$cache_home"
}
trap cleanup EXIT

mkdir -p "$data_home/nvim"
if [[ -d "$HOME/.local/share/nvim/lazy" ]]; then
  ln -s "$HOME/.local/share/nvim/lazy" "$data_home/nvim/lazy"
fi

require_pattern() {
  local pattern="$1"
  local file="$2"
  local message="$3"

  if ! rg -q "$pattern" "$file"; then
    echo "$message"
    exit 1
  fi
}

reject_pattern() {
  local pattern="$1"
  local file="$2"
  local message="$3"

  if rg -q "$pattern" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_clean_nvim_output() {
  if rg -n "Error in command line|Error detected while processing|stack traceback|EPERM|E5113|module .* not found" "$out_file"; then
    cat "$out_file"
    exit 1
  fi
}

require_pattern 'saghen/blink.cmp' "$NVIM/lua/plugins/blink-cmp.lua" "blink.cmp must remain"
require_pattern 'folke/snacks.nvim' "$NVIM/lua/plugins/snacks.lua" "snacks.nvim must remain"
require_pattern 'nvim-neo-tree/neo-tree.nvim' "$NVIM/lua/plugins/neo-tree.lua" "neo-tree.nvim must remain"
require_pattern 'akinsho/bufferline.nvim' "$NVIM/lua/plugins/bufferline.lua" "bufferline.nvim must remain"
require_pattern 'nvim-lualine/lualine.nvim' "$NVIM/lua/plugins/ui.lua" "lualine.nvim must remain"
require_pattern 'rachartier/tiny-inline-diagnostic.nvim' "$NVIM/lua/plugins/inline-diagno.lua" "tiny-inline-diagnostic.nvim must remain"
require_pattern 'smjonas/inc-rename.nvim' "$NVIM/lua/plugins/renamer.lua" "inc-rename.nvim must remain"
require_pattern 'folke/lazy.nvim.git' "$NVIM/lua/config/lazy.lua" "lazy.nvim must remain the plugin manager"
reject_pattern 'vim\.pack\.add' "$NVIM/lua/config/lazy.lua" "vim.pack must not manage plugins in phase one"

if [[ -e "$NVIM/lazyvim.json" ]]; then
  echo "obsolete lazyvim.json should be removed"
  exit 1
fi

reject_pattern 'LazyVim|lazyvim_' "$NVIM/lua/config/options.lua" "options.lua should not reference LazyVim defaults"
reject_pattern 'LazyVim|lazyvim_' "$NVIM/lua/config/keymaps.lua" "keymaps.lua should not reference LazyVim defaults"
reject_pattern 'LazyVim|lazyvim_' "$NVIM/lua/config/autocmds.lua" "autocmds.lua should not reference LazyVim defaults"
reject_pattern 'LazyVim|lazyvim\.plugins|add LazyVim' "$NVIM/lua/config/lazy.lua" "lazy.lua should not keep LazyVim import comments"
reject_pattern 'lazyvim\.json|LazyVim' "$NVIM/Readme.md" "README should not describe LazyVim residue"

require_pattern '<leader>rn' "$NVIM/lua/plugins/lsp.lua" "LSP rename alias must remain"
require_pattern '<leader>ca' "$NVIM/lua/plugins/lsp.lua" "LSP code action alias must remain"
require_pattern 'map\("K"' "$NVIM/lua/plugins/lsp.lua" "LSP hover alias must remain"
require_pattern 'williamboman/mason\.nvim' "$NVIM/lua/plugins/lsp.lua" "LSP path must keep mason.nvim dependency"
require_pattern 'williamboman/mason-lspconfig\.nvim' "$NVIM/lua/plugins/lsp.lua" "LSP path must keep mason-lspconfig dependency"
require_pattern 'run_on_start = not is_headless\(\)' "$NVIM/lua/plugins/mason.lua" "Mason tools should auto-install outside headless runs"
require_pattern 'start_delay = 3000' "$NVIM/lua/plugins/mason.lua" "Mason tools auto-install should be delayed after startup"
reject_pattern 'cmd = .*MasonToolsInstall' "$NVIM/lua/plugins/mason.lua" "mason-tool-installer should not be command-gated"
require_pattern 'inc_rename' "$NVIM/lua/plugins/renamer.lua" "IncRename setup must remain"
require_pattern '<leader>rn' "$NVIM/lua/plugins/renamer.lua" "IncRename global rename mapping must remain"
require_pattern '"gr"' "$NVIM/lua/plugins/snacks.lua" "Snacks references mapping must remain"
require_pattern 'nowait = true' "$NVIM/lua/plugins/snacks.lua" "Snacks gr nowait risk should stay visible in phase one"
require_pattern 'nowait' "$NVIM/Readme.md" "README should document the gr nowait boundary"
require_pattern '`gr`' "$NVIM/Readme.md" "README should document the gr mapping boundary"
require_pattern '`grn`' "$NVIM/Readme.md" "README should document Neovim 0.12 LSP defaults"
require_pattern '<leader>rn' "$NVIM/Readme.md" "README should document rename mapping boundary"

set +e
XDG_CONFIG_HOME="$ROOT/.config/shared" \
  XDG_DATA_HOME="$data_home" \
  XDG_STATE_HOME="$state_home" \
  XDG_CACHE_HOME="$cache_home" \
  nvim --headless -i NONE -u "$NVIM/init.lua" \
    --cmd 'set noswapfile' \
    '+lua print("nvim-cleanup-ok")' \
    '+qa!' >"$out_file" 2>&1
startup_rc=$?
set -e

if [[ "$startup_rc" -ne 0 ]]; then
  cat "$out_file"
  exit 1
fi
assert_clean_nvim_output

: >"$out_file"
set +e
XDG_CONFIG_HOME="$ROOT/.config/shared" \
  XDG_DATA_HOME="$data_home" \
  XDG_STATE_HOME="$state_home" \
  XDG_CACHE_HOME="$cache_home" \
  nvim --headless -i NONE -u "$NVIM/init.lua" \
    --cmd 'set noswapfile' \
    '+lua for _, lhs in ipairs({ "gr", "grn", "gra", "grr", "gri", "grt", "grx", "gO" }) do local m = vim.fn.maparg(lhs, "n", false, true); print(("KEYMAP %s lhs=%s rhs=%s callback=%s nowait=%s sid=%s"):format(lhs, tostring(m.lhs), tostring(m.rhs), tostring(m.callback ~= nil), tostring(m.nowait), tostring(m.sid))) end' \
    '+qa!' >"$out_file" 2>&1
keymap_rc=$?
set -e

if [[ "$keymap_rc" -ne 0 ]]; then
  cat "$out_file"
  exit 1
fi
assert_clean_nvim_output

require_pattern 'KEYMAP gr .*nowait=1' "$out_file" "runtime keymap output should record gr nowait"
for lhs in grn gra grr gri grt grx gO; do
  require_pattern "KEYMAP $lhs " "$out_file" "runtime keymap output should include $lhs"
done
