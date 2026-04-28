#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MISC="$ROOT/.config/shared/nvim/lua/plugins/misc.lua"
toml_file="$(mktemp --suffix=.toml)"
yaml_file="$(mktemp --suffix=.yaml)"
jsonc_file="$(mktemp --suffix=.jsonc)"
json_file="$(mktemp --suffix=.json)"
nvim_state="$(mktemp -d)"
nvim_cache="$(mktemp -d)"

cleanup() {
  rm -f "$toml_file" "$yaml_file" "$jsonc_file" "$json_file"
  rm -rf "$nvim_state" "$nvim_cache"
}
trap cleanup EXIT

if grep -q 'line = "gcc"' "$MISC"; then
  echo "Comment.nvim must not define gcc"
  exit 1
fi

if grep -q 'line = "gc"' "$MISC"; then
  echo "Comment.nvim must not define gc"
  exit 1
fi

grep -q 'mappings = false' "$MISC" || {
  echo "Comment.nvim mappings should be disabled"
  exit 1
}

map_output="$(
  XDG_STATE_HOME="$nvim_state" XDG_CACHE_HOME="$nvim_cache" nvim --headless -i NONE -u NONE \
    --cmd "set runtimepath^=$ROOT/.config/shared/nvim" \
    "+luafile $ROOT/.config/shared/nvim/init.lua" \
    '+verbose nmap gcc' \
    '+quitall!' 2>&1
)"

if grep -q 'Comment.nvim' <<<"$map_output"; then
  echo "gcc should not be mapped by Comment.nvim"
  exit 1
fi

if ! grep -q 'vim/_core/defaults.lua' <<<"$map_output"; then
  echo "gcc should come from Neovim built-in defaults"
  exit 1
fi

printf 'name = "rikoo"\n' > "$toml_file"
printf 'name: rikoo\n' > "$yaml_file"
printf '{ "name": "rikoo" }\n' > "$jsonc_file"
printf '{ "name": "rikoo" }\n' > "$json_file"

XDG_STATE_HOME="$nvim_state" XDG_CACHE_HOME="$nvim_cache" nvim --clean --headless -i NONE \
  --cmd 'set noswapfile' "$toml_file" \
  '+normal gcc' \
  '+write' \
  '+quitall!'

grep -q '^# name = "rikoo"$' "$toml_file" || {
  echo "Neovim built-in gcc should comment TOML with #"
  exit 1
}

XDG_STATE_HOME="$nvim_state" XDG_CACHE_HOME="$nvim_cache" nvim --clean --headless -i NONE \
  --cmd 'set noswapfile' "$yaml_file" \
  '+normal gcc' \
  '+write' \
  '+quitall!'

grep -q '^# name: rikoo$' "$yaml_file" || {
  echo "Neovim built-in gcc should comment YAML with #"
  exit 1
}

XDG_STATE_HOME="$nvim_state" XDG_CACHE_HOME="$nvim_cache" nvim --clean --headless -i NONE \
  --cmd 'set noswapfile' "$jsonc_file" \
  '+normal gcc' \
  '+write' \
  '+quitall!'

grep -q '^// { "name": "rikoo" }$' "$jsonc_file" || {
  echo "Neovim built-in gcc should comment JSONC with //"
  exit 1
}

XDG_STATE_HOME="$nvim_state" XDG_CACHE_HOME="$nvim_cache" nvim --clean --headless -i NONE \
  --cmd 'set noswapfile' "$json_file" \
  '+normal gcc' \
  '+write' \
  '+quitall!' >/dev/null 2>&1 || true

if grep -q '^//' "$json_file"; then
  echo "Standard JSON should not gain forced // comment support"
  exit 1
fi
