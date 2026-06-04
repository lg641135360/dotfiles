#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$ROOT/.config/shared/git/config"
README="$ROOT/.config/shared/git/README.md"
MEMORY="$ROOT/memory/git.md"

source "$ROOT/tests/lib/assert.sh"

require_config() {
  local key="$1"
  local expected="$2"
  local actual

  actual="$(git config --file "$CONFIG" --get "$key")"
  if [[ "$actual" != "$expected" ]]; then
    echo "git $key should be $expected, got: $actual"
    exit 1
  fi
}

editor="$(git config --file "$CONFIG" --get core.editor)"
if [[ "$editor" != "vim" ]]; then
  echo "git core.editor should be vim, got: $editor"
  exit 1
fi

template="$(git config --file "$CONFIG" --get commit.template)"
if [[ "$template" != "~/.config/git/template" ]]; then
  echo "git commit.template should stay ~/.config/git/template, got: $template"
  exit 1
fi

assert_matches 'core.editor.*vim|默认编辑器.*Vim|Git 默认编辑器' "$README"
assert_contains 'core.editor = vim' "$MEMORY"
assert_not_contains 'core.editor = nvim' "$MEMORY"

require_config alias.subinit "submodule update --init --recursive"
require_config alias.subs "submodule status"
require_config alias.cs "commit --signoff"

assert_matches '\| `subs` \| `submodule status` \| `git subs` \|' "$README"
assert_matches '\| `grs` \| `git restore` \|' "$README"
assert_matches '\| `grst` \| `git restore --staged` \|' "$README"
assert_not_matches '\| `gres` \|' "$README"
assert_not_matches '\| `grest` \|' "$README"
assert_not_matches '\| `subs` \| `git submodule status` \|' "$README"
