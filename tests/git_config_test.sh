#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$ROOT/.config/shared/git/config"
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

assert_contains 'core.editor = vim' "$MEMORY"
assert_not_contains 'core.editor = nvim' "$MEMORY"

require_config alias.subinit "submodule update --init --recursive"
require_config alias.subs "submodule status"
require_config alias.cs "commit --signoff"

# [log] 区块与 abbrevCommit 不应重复定义。
log_section_count="$(grep -c '^\[log\]$' "$CONFIG")"
if [[ "$log_section_count" -ne 1 ]]; then
  echo "expected exactly one [log] section in $CONFIG, got: $log_section_count"
  exit 1
fi
abbrev_count="$(grep -c '^[[:space:]]*abbrevCommit[[:space:]]*=' "$CONFIG")"
if [[ "$abbrev_count" -ne 1 ]]; then
  echo "expected abbrevCommit to appear once in $CONFIG, got: $abbrev_count"
  exit 1
fi
require_config log.abbrevCommit "true"
require_config log.date "relative"
require_config log.graph "true"
require_config log.decorate "true"
