#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVIM="$ROOT/.config/shared/nvim"
out_file="$(mktemp)"
probe_lua="$(mktemp)"
nvim_data="$(mktemp -d)"
nvim_state="$(mktemp -d)"
nvim_cache="$(mktemp -d)"

cleanup() {
  rm -rf "$out_file" "$probe_lua" "$nvim_data" "$nvim_state" "$nvim_cache"
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

if [[ -e "$NVIM/lua/colors/color1.lua" ]]; then
  echo "legacy colors/color1.lua should be removed after Catppuccin highlight cleanup"
  exit 1
fi

if rg -q 'require\("colors\.color1"\)|NormalFloat".*NONE|Pmenu".*NONE|FloatBorder".*NONE|mint_cream|ice_white' "$NVIM/lua/config/autocmds.lua"; then
  echo "autocmds.lua should no longer force transparent float/menu highlights or use the stale local palette"
  exit 1
fi

cat >"$probe_lua" <<'LUA'
local palette = require("catppuccin.palettes").get_palette("mocha")

local function hex(value)
  return value and string.format("#%06x", value) or "NONE"
end

local function dump(group)
  local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
  print(("HL_%s_FG=%s"):format(group:upper(), hex(hl.fg)))
  print(("HL_%s_BG=%s"):format(group:upper(), hex(hl.bg)))
  print(("HL_%s_BOLD=%s"):format(group:upper(), tostring(hl.bold == true)))
  return hl
end

print("COLORSCHEME=" .. tostring(vim.g.colors_name))
local normal_float = dump("NormalFloat")
local pmenu = dump("Pmenu")
local pmenu_sel = dump("PmenuSel")
local float_border = dump("FloatBorder")
local cur_search = dump("CurSearch")
local visual = dump("Visual")

print("PALETTE_MANTLE=" .. palette.mantle)
print("PALETTE_SURFACE0=" .. palette.surface0)
print("PALETTE_SURFACE1=" .. palette.surface1)
print("PALETTE_RED=" .. palette.red)

if hex(normal_float.bg) ~= palette.mantle then
  error("NormalFloat should follow Catppuccin Mocha mantle background")
end
if hex(pmenu.bg) ~= palette.mantle then
  error("Pmenu should follow Catppuccin Mocha mantle background")
end
if hex(float_border.bg) ~= hex(normal_float.bg) then
  error("FloatBorder background should match NormalFloat background")
end
if hex(pmenu_sel.bg) ~= palette.surface0 then
  error("PmenuSel should follow Catppuccin Mocha surface0 background")
end
if hex(cur_search.bg) ~= palette.red or hex(cur_search.fg) ~= palette.mantle then
  error("CurSearch should follow Catppuccin Mocha defaults")
end
if hex(visual.bg) ~= palette.surface1 then
  error("Visual should follow Catppuccin Mocha surface1 background")
end
LUA

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
  'COLORSCHEME=catppuccin-mocha' \
  'HL_NORMALFLOAT_BG=#181825' \
  'HL_PMENU_BG=#181825' \
  'HL_PMENUSEL_BG=#313244' \
  'HL_CURSEARCH_BG=#f38ba8' \
  'HL_CURSEARCH_FG=#181825' \
  'HL_VISUAL_BG=#45475a' \
  'PALETTE_MANTLE=#181825' \
  'PALETTE_SURFACE0=#313244' \
  'PALETTE_SURFACE1=#45475a' \
  'PALETTE_RED=#f38ba8'; do
  if ! rg -q -- "$pattern" "$out_file"; then
    echo "missing expected Catppuccin highlight evidence: $pattern"
    cat "$out_file"
    exit 1
  fi
done

echo "nvim-theme-highlight-consistency-ok"
