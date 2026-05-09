#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$ROOT/.config/shared/git/config"
README="$ROOT/.config/shared/git/README.md"

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

require_readme() {
  local pattern="$1"
  local message="$2"

  grep -qE "$pattern" "$README" || {
    echo "$message"
    exit 1
  }
}

reject_readme() {
  local pattern="$1"
  local message="$2"

  if grep -qE "$pattern" "$README"; then
    echo "$message"
    exit 1
  fi
}

editor="$(git config --file "$CONFIG" --get core.editor)"
if [[ "$editor" != "nvim" ]]; then
  echo "git core.editor should be nvim, got: $editor"
  exit 1
fi

template="$(git config --file "$CONFIG" --get commit.template)"
if [[ "$template" != "~/.config/git/template" ]]; then
  echo "git commit.template should stay ~/.config/git/template, got: $template"
  exit 1
fi

grep -q 'core.editor.*nvim\|默认编辑器.*nvim\|Git 默认编辑器' "$README" || {
  echo "Git README should document nvim as the default editor"
  exit 1
}

require_config alias.subinit "submodule update --init --recursive"
require_config alias.subs "submodule status"
require_config alias.cs "commit --signoff"

require_readme '\| `subs` \| `submodule status` \| `git subs` \|' "Git README should document git subs as a custom alias"
require_readme '\| `grs` \| `git restore` \|' "Git README should document the current OMZ git restore alias as grs"
require_readme '\| `grst` \| `git restore --staged` \|' "Git README should document the current OMZ unstaging alias as grst"
reject_readme '\| `gres` \|' "Git README should not document stale OMZ alias gres"
reject_readme '\| `grest` \|' "Git README should not document stale OMZ alias grest"
reject_readme '\| `subs` \| `git submodule status` \|' "Git README should not claim OMZ provides a direct subs alias"
