#!/usr/bin/env bash
# Run every executable in config/hooks/<event>.d/ in filename order.
# A failing hook is reported but does not stop the others.
set -uo pipefail

event="${1:-}"
if [[ -z "$event" || "$event" == */* || "$event" == .* ]]; then
  echo "usage: hook.sh <event>" >&2
  exit 2
fi
shift

DOTFILES="${DOTFILES:-$HOME/nixos-dotfiles}"
dir="$DOTFILES/config/hooks/$event.d"
[[ -d "$dir" ]] || exit 0

status=0
shopt -s nullglob
for hook in "$dir"/*; do
  [[ -f "$hook" && -x "$hook" ]] || continue
  if ! "$hook" "$@"; then
    echo "hook: $event/$(basename "$hook") failed" >&2
    status=1
  fi
done
exit "$status"
