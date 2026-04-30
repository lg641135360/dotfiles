#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$ROOT/.config/shared/git/config"
README="$ROOT/.config/shared/git/README.md"

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
