#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVIM_CONFIG="$ROOT/.config/shared/nvim"
MISC="$ROOT/.config/shared/nvim/lua/plugins/misc.lua"
toml_file="$(mktemp --suffix=.toml)"
yaml_file="$(mktemp --suffix=.yaml)"
jsonc_file="$(mktemp --suffix=.jsonc)"
json_file="$(mktemp --suffix=.json)"
nvim_data="$(mktemp -d)"
nvim_state="$(mktemp -d)"
nvim_cache="$(mktemp -d)"
nvim_output="$(mktemp)"

cleanup() {
  rm -f "$toml_file" "$yaml_file" "$jsonc_file" "$json_file"
  rm -rf "$nvim_data" "$nvim_state" "$nvim_cache" "$nvim_output"
}
trap cleanup EXIT

mkdir -p "$nvim_data/nvim"
if [[ -d "$HOME/.local/share/nvim/lazy" ]]; then
  ln -s "$HOME/.local/share/nvim/lazy" "$nvim_data/nvim/lazy"
fi

assert_clean_nvim_output() {
  if rg -n "Error in command line|Error detected while processing|stack traceback|EPERM|E5113|module .* not found" "$nvim_output"; then
    cat "$nvim_output"
    exit 1
  fi
}

if grep -Eq 'Comment.nvim|numToStr/Comment|require\("Comment"\)' "$MISC"; then
  echo "Comment.nvim should be removed from misc.lua"
  exit 1
fi

if grep -q 'line = "gcc"' "$MISC"; then
  echo "Comment.nvim must not define gcc"
  exit 1
fi

if grep -q 'line = "gc"' "$MISC"; then
  echo "Comment.nvim must not define gc"
  exit 1
fi

set +e
XDG_CONFIG_HOME="$ROOT/.config/shared" \
  XDG_DATA_HOME="$nvim_data" \
  XDG_STATE_HOME="$nvim_state" \
  XDG_CACHE_HOME="$nvim_cache" \
  nvim --headless -i NONE -u "$NVIM_CONFIG/init.lua" \
    --cmd 'set noswapfile' \
    '+verbose nmap gcc' \
    '+quitall!' >"$nvim_output" 2>&1
nvim_rc=$?
set -e

if [[ "$nvim_rc" -ne 0 ]]; then
  cat "$nvim_output"
  exit 1
fi

assert_clean_nvim_output

if grep -q 'Comment.nvim' "$nvim_output"; then
  echo "gcc should not be mapped by Comment.nvim"
  exit 1
fi

if ! grep -q 'vim/_core/defaults.lua' "$nvim_output"; then
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
