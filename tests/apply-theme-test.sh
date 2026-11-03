#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"

# Copies, not links: apply-theme.sh writes generated configs next to their bases.
for dir in quickshell ghostty starship fastfetch; do
  cp -r "$DOTFILES/config/$dir" "$XDG_CONFIG_HOME/$dir"
done
APPLY="$XDG_CONFIG_HOME/quickshell/apply-theme.sh"
THEMES="$XDG_CONFIG_HOME/quickshell/themes.json"
mkdir -p "$XDG_CONFIG_HOME/dotfiles"
echo '{"themes":{"packs":["core","f1"]}}' >"$XDG_CONFIG_HOME/dotfiles/settings.json"
THEMES_OUT="$THEMES" bash "$DOTFILES/scripts/build-themes.sh"
STATE="$XDG_STATE_HOME/quickshell"

while read -r id; do
  if ! "$APPLY" "$id" --no-wallpaper >/dev/null 2>"$TEST_ROOT/err"; then
    fail "$id: apply-theme exited non-zero ($(head -n1 "$TEST_ROOT/err"))"
    continue
  fi
  want="$(jq -r --arg id "$id" '.themes[] | select(.id == $id) | .colors.background' "$THEMES" | tr -d '#' | tr 'A-F' 'a-f')"
  have="$(sed -n 's/.*base[[:space:]]*=[[:space:]]*"\([0-9a-fA-F]*\)".*/\1/p' "$STATE/hypr-colors.lua" | head -n1 | tr 'A-F' 'a-f')"
  check "$id: state id recorded" [ "$(jq -r .id "$STATE/theme-state.json")" = "$id" ]
  check "$id: hypr base colour matches" [ "$want" = "$have" ]
  check "$id: starship palette written" [ -s "$STATE/starship-palette.toml" ]
done < <(jq -r '.themes[].id' "$THEMES")

check "unknown theme is rejected" bash -c "! '$APPLY' no-such-theme --no-wallpaper 2>/dev/null"
check "repo configs untouched" git -C "$DOTFILES" diff --quiet -- config/ghostty config/starship config/fastfetch

finish
