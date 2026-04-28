#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVIM="$ROOT/.config/shared/nvim"
out_file="$(mktemp)"
data_home="$(mktemp -d)"
state_home="$(mktemp -d)"
cache_home="$(mktemp -d)"
keymap_check="$(mktemp)"
lsp_check="$(mktemp)"
ui_check="$(mktemp)"
lock_file="$NVIM/lazy-lock.json"
lock_backup="$(mktemp)"

cp "$lock_file" "$lock_backup"

cleanup() {
  cp "$lock_backup" "$lock_file"
  rm -rf "$out_file" "$data_home" "$state_home" "$cache_home" "$keymap_check" "$lsp_check" "$ui_check"
  rm -f "$lock_backup"
}
trap cleanup EXIT

mkdir -p "$data_home/nvim"
if [[ -d "$HOME/.local/share/nvim/lazy" ]]; then
  ln -s "$HOME/.local/share/nvim/lazy" "$data_home/nvim/lazy"
fi

cat >"$keymap_check" <<'LUA'
for _, lhs in ipairs({ "gr", "grn", "gra", "grr", "gri", "grt", "grx", "gO" }) do
  local mapping = vim.fn.maparg(lhs, "n", false, true)
  print(
    ("KEYMAP %s lhs=%s rhs=%s callback=%s nowait=%s sid=%s"):format(
      lhs,
      tostring(mapping.lhs),
      tostring(mapping.rhs),
      tostring(mapping.callback ~= nil),
      tostring(mapping.nowait),
      tostring(mapping.sid)
    )
  )
end
LUA

cat >"$lsp_check" <<'LUA'
vim.api.nvim_exec_autocmds("BufReadPre", { modeline = false })

local servers = { "lua_ls", "clangd", "pyright", "ts_ls" }
for _, name in ipairs(servers) do
  local config = vim.lsp.config[name]
  print(
    ("LSP_CONFIG %s enabled=%s has_config=%s"):format(
      name,
      tostring(vim.lsp.is_enabled(name)),
      tostring(config ~= nil)
    )
  )
end

local capabilities = vim.lsp.config.lua_ls and vim.lsp.config.lua_ls.capabilities
local completion_item = capabilities
  and capabilities.textDocument
  and capabilities.textDocument.completion
  and capabilities.textDocument.completion.completionItem
print("LSP_CAP_SNIPPET=" .. tostring(completion_item and completion_item.snippetSupport))

local lua_ls = vim.lsp.config.lua_ls
print(
  "LSP_LUA_CHECK_THIRD_PARTY="
    .. tostring(
      lua_ls
        and lua_ls.settings
        and lua_ls.settings.Lua
        and lua_ls.settings.Lua.workspace
        and lua_ls.settings.Lua.workspace.checkThirdParty
    )
)

local lua_settings = lua_ls and lua_ls.settings and lua_ls.settings.Lua or {}
print("LSP_LUA_RUNTIME=" .. tostring(lua_settings.runtime and lua_settings.runtime.version))

local has_vim_global = false
local globals = lua_settings.diagnostics and lua_settings.diagnostics.globals or {}
for _, global in ipairs(globals) do
  if global == "vim" then
    has_vim_global = true
  end
end
print("LSP_LUA_GLOBAL_VIM=" .. tostring(has_vim_global))

local library_count = 0
local has_vimruntime = false
local library = lua_settings.workspace and lua_settings.workspace.library or {}
for _, path in pairs(library) do
  library_count = library_count + 1
  if path == vim.env.VIMRUNTIME then
    has_vimruntime = true
  end
end
print("LSP_LUA_LIBRARY_COUNT=" .. tostring(library_count))
print("LSP_LUA_LIBRARY_VIMRUNTIME=" .. tostring(has_vimruntime))

local clangd_cmd = vim.lsp.config.clangd and table.concat(vim.lsp.config.clangd.cmd or {}, " ") or ""
print("LSP_CLANGD_CMD=" .. clangd_cmd)

local pyright = vim.lsp.config.pyright
print(
  "LSP_PYRIGHT_TYPECHECK="
    .. tostring(
      pyright
        and pyright.settings
        and pyright.settings.python
        and pyright.settings.python.analysis
        and pyright.settings.python.analysis.typeCheckingMode
    )
)
LUA

cat >"$ui_check" <<'LUA'
local diagnostic = vim.diagnostic.config()
local float = diagnostic.float or {}

print("UI_WINBORDER=" .. vim.o.winborder)
print("UI_PUMBORDER=" .. vim.o.pumborder)
print("UI_DIAGNOSTIC_SIGNS=" .. tostring(diagnostic.signs))
print("UI_DIAGNOSTIC_FLOAT_BORDER=" .. tostring(float.border))
print("UI_DIAGNOSTIC_FLOAT_SOURCE=" .. tostring(float.source))
LUA

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
require_pattern 'vim\.opt\.winborder = "rounded"' "$NVIM/lua/config/options.lua" "winborder should be configured through Neovim 0.12 option defaults"
require_pattern 'vim\.opt\.pumborder = "rounded"' "$NVIM/lua/config/options.lua" "pumborder should be configured through Neovim 0.12 option defaults"
require_pattern 'float = \{' "$NVIM/lua/config/options.lua" "diagnostic float config should be explicit"
require_pattern 'border = "rounded"' "$NVIM/lua/config/options.lua" "diagnostic floating windows should use the rounded border default"
require_pattern 'source = "if_many"' "$NVIM/lua/config/options.lua" "diagnostic floating windows should show source only when useful"

require_pattern '<leader>rn' "$NVIM/lua/plugins/lsp.lua" "LSP rename alias must remain"
require_pattern '<leader>ca' "$NVIM/lua/plugins/lsp.lua" "LSP code action alias must remain"
require_pattern 'map\("K"' "$NVIM/lua/plugins/lsp.lua" "LSP hover alias must remain"
require_pattern 'vim\.api\.nvim_create_autocmd\("LspAttach"' "$NVIM/lua/plugins/lsp.lua" "LSP aliases should be attached through LspAttach"
require_pattern "vim\\.lsp\\.config\\([\"']\\*[\"']" "$NVIM/lua/plugins/lsp.lua" "LSP defaults should use vim.lsp.config('*', ...)"
require_pattern 'vim\.lsp\.config\("lua_ls"' "$NVIM/lua/plugins/lsp.lua" "lua_ls should use vim.lsp.config"
require_pattern 'vim\.lsp\.config\("clangd"' "$NVIM/lua/plugins/lsp.lua" "clangd should use vim.lsp.config"
require_pattern 'vim\.lsp\.config\("pyright"' "$NVIM/lua/plugins/lsp.lua" "pyright should use vim.lsp.config"
require_pattern 'vim\.lsp\.config\("ts_ls"' "$NVIM/lua/plugins/lsp.lua" "ts_ls should use vim.lsp.config"
require_pattern 'vim\.lsp\.enable' "$NVIM/lua/plugins/lsp.lua" "LSP servers should be enabled with vim.lsp.enable"
reject_pattern 'require\("lspconfig"\)' "$NVIM/lua/plugins/lsp.lua" "lspconfig framework require should not remain in the LSP migration path"
reject_pattern 'lspconfig\.(lua_ls|clangd|pyright|ts_ls)\.setup' "$NVIM/lua/plugins/lsp.lua" "server setup should not use lspconfig.SERVER.setup"
reject_pattern 'lspconfig\.util\.default_config' "$NVIM/lua/plugins/lsp.lua" "LSP defaults should not mutate lspconfig.util.default_config"
reject_pattern 'folke/neodev\.nvim' "$NVIM/lua/plugins/lsp.lua" "neodev.nvim should not remain after native LSP config migration"
require_pattern 'blink\.get_lsp_capabilities' "$NVIM/lua/plugins/lsp.lua" "blink capabilities must remain in LSP defaults"
require_pattern 'williamboman/mason\.nvim' "$NVIM/lua/plugins/lsp.lua" "LSP path must keep mason.nvim dependency"
require_pattern 'williamboman/mason-lspconfig\.nvim' "$NVIM/lua/plugins/lsp.lua" "LSP path must keep mason-lspconfig dependency"
require_pattern 'automatic_enable = false' "$NVIM/lua/plugins/lsp.lua" "mason-lspconfig automatic enable should stay disabled when vim.lsp.enable is explicit"
require_pattern 'completion = \{ callSnippet = "Replace" \}' "$NVIM/lua/plugins/lsp.lua" "lua_ls completion settings must remain"
require_pattern 'runtime = \{ version = "LuaJIT" \}' "$NVIM/lua/plugins/lsp.lua" "lua_ls should explicitly use the Neovim LuaJIT runtime"
require_pattern 'diagnostics = \{ globals = \{ "vim" \} \}' "$NVIM/lua/plugins/lsp.lua" "lua_ls should explicitly accept the vim global without neodev"
require_pattern 'checkThirdParty = false' "$NVIM/lua/plugins/lsp.lua" "lua_ls workspace checkThirdParty setting must remain"
require_pattern 'library = vim\.api\.nvim_get_runtime_file\("", true\)' "$NVIM/lua/plugins/lsp.lua" "lua_ls should explicitly expose Neovim runtime files without neodev"
require_pattern 'telemetry = \{ enable = false \}' "$NVIM/lua/plugins/lsp.lua" "lua_ls telemetry settings must remain"
require_pattern '--compile-commands-dir=build' "$NVIM/lua/plugins/lsp.lua" "clangd compile commands flag must remain"
require_pattern '--clang-tidy' "$NVIM/lua/plugins/lsp.lua" "clangd clang-tidy flag must remain"
require_pattern 'typeCheckingMode = "basic"' "$NVIM/lua/plugins/lsp.lua" "pyright type checking setting must remain"
require_pattern 'diagnosticMode = "workspace"' "$NVIM/lua/plugins/lsp.lua" "pyright diagnostic mode setting must remain"
require_pattern 'run_on_start = not is_headless\(\)' "$NVIM/lua/plugins/mason.lua" "Mason tools should auto-install outside headless runs"
require_pattern 'start_delay = 3000' "$NVIM/lua/plugins/mason.lua" "Mason tools auto-install should be delayed after startup"
reject_pattern 'cmd = .*MasonToolsInstall' "$NVIM/lua/plugins/mason.lua" "mason-tool-installer should not be command-gated"
require_pattern 'inc_rename' "$NVIM/lua/plugins/renamer.lua" "IncRename setup must remain"
require_pattern '<leader>rn' "$NVIM/lua/plugins/renamer.lua" "IncRename global rename mapping must remain"
reject_pattern '"gr"' "$NVIM/lua/plugins/snacks.lua" "bare gr mapping should be removed to avoid gr* prefix conflicts"
require_pattern '"grr"' "$NVIM/lua/plugins/snacks.lua" "Snacks references mapping should move to Neovim 0.12 grr"
require_pattern 'Snacks\.picker\.lsp_references' "$NVIM/lua/plugins/snacks.lua" "Snacks references picker should stay available on grr"
reject_pattern 'nowait = true' "$NVIM/lua/plugins/snacks.lua" "LSP gr* mappings should not rely on nowait after grr migration"
reject_pattern 'nowait' "$NVIM/Readme.md" "README should no longer document the old gr nowait boundary"
reject_pattern '当前 `gr` 仍' "$NVIM/Readme.md" "README should not say bare gr still owns references"
require_pattern '`grr`' "$NVIM/Readme.md" "README should document grr references"
require_pattern '`grn`' "$NVIM/Readme.md" "README should document Neovim 0.12 LSP defaults"
require_pattern '<leader>rn' "$NVIM/Readme.md" "README should document rename mapping boundary"
require_pattern 'vim\.lsp\.config\(\)' "$NVIM/Readme.md" "README should document Neovim 0.12 LSP config shape"
require_pattern 'vim\.lsp\.enable\(\)' "$NVIM/Readme.md" "README should document Neovim 0.12 LSP enable shape"
require_pattern '`winborder`' "$NVIM/Readme.md" "README should document Neovim 0.12 winborder default"
require_pattern '`pumborder`' "$NVIM/Readme.md" "README should document Neovim 0.12 pumborder default"

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
    "+luafile $keymap_check" \
    '+qa!' >"$out_file" 2>&1
keymap_rc=$?
set -e

if [[ "$keymap_rc" -ne 0 ]]; then
  cat "$out_file"
  exit 1
fi
assert_clean_nvim_output

require_pattern 'KEYMAP gr lhs=nil .*nowait=nil' "$out_file" "bare gr should not be mapped at runtime"
reject_pattern 'KEYMAP gr .*nowait=1' "$out_file" "bare gr should not use nowait at runtime"
require_pattern 'KEYMAP grr lhs=grr .*callback=true' "$out_file" "grr should invoke the references picker callback"
for lhs in grn gra grr gri grt grx gO; do
  require_pattern "KEYMAP $lhs " "$out_file" "runtime keymap output should include $lhs"
done

: >"$out_file"
set +e
XDG_CONFIG_HOME="$ROOT/.config/shared" \
  XDG_DATA_HOME="$data_home" \
  XDG_STATE_HOME="$state_home" \
  XDG_CACHE_HOME="$cache_home" \
  nvim --headless -i NONE -u "$NVIM/init.lua" \
    --cmd 'set noswapfile' \
    "+luafile $lsp_check" \
    '+qa!' >"$out_file" 2>&1
lsp_rc=$?
set -e

if [[ "$lsp_rc" -ne 0 ]]; then
  cat "$out_file"
  exit 1
fi
assert_clean_nvim_output

for server in lua_ls clangd pyright ts_ls; do
  require_pattern "LSP_CONFIG $server enabled=true has_config=true" "$out_file" "$server should be enabled through vim.lsp.enable"
done
require_pattern 'LSP_CAP_SNIPPET=true' "$out_file" "blink capabilities should reach vim.lsp.config defaults"
require_pattern 'LSP_LUA_CHECK_THIRD_PARTY=false' "$out_file" "lua_ls workspace setting should survive migration"
require_pattern 'LSP_LUA_RUNTIME=LuaJIT' "$out_file" "lua_ls should use LuaJIT runtime settings"
require_pattern 'LSP_LUA_GLOBAL_VIM=true' "$out_file" "lua_ls should know the vim global without neodev"
require_pattern 'LSP_LUA_LIBRARY_COUNT=[1-9]' "$out_file" "lua_ls should expose at least one runtime library path"
require_pattern 'LSP_LUA_LIBRARY_VIMRUNTIME=true' "$out_file" "lua_ls runtime library should include VIMRUNTIME"
require_pattern 'LSP_CLANGD_CMD=.*--clang-tidy' "$out_file" "clangd command flags should survive migration"
require_pattern 'LSP_PYRIGHT_TYPECHECK=basic' "$out_file" "pyright analysis settings should survive migration"

: >"$out_file"
set +e
XDG_CONFIG_HOME="$ROOT/.config/shared" \
  XDG_DATA_HOME="$data_home" \
  XDG_STATE_HOME="$state_home" \
  XDG_CACHE_HOME="$cache_home" \
  nvim --headless -i NONE -u "$NVIM/init.lua" \
    --cmd 'set noswapfile' \
    "+luafile $ui_check" \
    '+qa!' >"$out_file" 2>&1
ui_rc=$?
set -e

if [[ "$ui_rc" -ne 0 ]]; then
  cat "$out_file"
  exit 1
fi
assert_clean_nvim_output

require_pattern 'UI_WINBORDER=rounded' "$out_file" "winborder should be rounded at runtime"
require_pattern 'UI_PUMBORDER=rounded' "$out_file" "pumborder should be rounded at runtime"
require_pattern 'UI_DIAGNOSTIC_SIGNS=false' "$out_file" "diagnostic signs should stay disabled"
require_pattern 'UI_DIAGNOSTIC_FLOAT_BORDER=rounded' "$out_file" "diagnostic float border should be rounded at runtime"
require_pattern 'UI_DIAGNOSTIC_FLOAT_SOURCE=if_many' "$out_file" "diagnostic float source should be if_many at runtime"
