# Sourced by tests: isolated HOME/XDG dirs and stubs so nothing touches the live session.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES

TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

export HOME="$TEST_ROOT/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
unset HYPRLAND_INSTANCE_SIGNATURE TMUX
mkdir -p "$XDG_CONFIG_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

mkdir -p "$TEST_ROOT/bin"
for stub in hyprctl tmux qs swaybg; do
  printf '#!/bin/sh\nexit 0\n' >"$TEST_ROOT/bin/$stub"
  chmod +x "$TEST_ROOT/bin/$stub"
done
export PATH="$TEST_ROOT/bin:$PATH"

failures=0
pass() { echo "  ok   $1"; }
fail() { echo "  FAIL $1" >&2; failures=$((failures + 1)); }
check() { local name="$1"; shift; if "$@"; then pass "$name"; else fail "$name"; fi; }
finish() { [[ "$failures" -eq 0 ]]; }
