#!/usr/bin/env bash
# Run each scripts/migrations/*.sh once, in filename order.
# A marker in ~/.local/state/nixos-dotfiles/migrations/ records each success.
# Migrations must be idempotent: a fresh machine runs all of them.
set -uo pipefail

DOTFILES="${DOTFILES:-$HOME/nixos-dotfiles}"
MIGRATIONS="$DOTFILES/scripts/migrations"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/nixos-dotfiles/migrations"

mkdir -p "$STATE"
[[ -d "$MIGRATIONS" ]] || exit 0

shopt -s nullglob
for file in "$MIGRATIONS"/*.sh; do
  name="$(basename "$file")"
  [[ -f "$STATE/$name" ]] && continue
  echo "migrate: running $name"
  if bash "$file"; then
    touch "$STATE/$name"
  else
    echo "migrate: $name failed; later migrations skipped until it succeeds" >&2
    exit 1
  fi
done
