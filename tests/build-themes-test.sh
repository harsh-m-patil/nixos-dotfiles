#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"

BUILD="$DOTFILES/scripts/build-themes.sh"
OUT="$TEST_ROOT/themes.json"
SETTINGS="$XDG_CONFIG_HOME/dotfiles/settings.json"
USER_THEMES="$XDG_CONFIG_HOME/dotfiles/themes"
mkdir -p "$XDG_CONFIG_HOME/dotfiles" "$USER_THEMES"
build() { THEMES_OUT="$OUT" bash "$BUILD" "$@"; }

check "every shipped theme is valid" build --check

build
check "core is the default pack" [ "$(jq '[.themes[] | select(.id | startswith("f1-"))] | length' "$OUT")" -eq 0 ]
check "pack order file is respected" [ "$(jq -r '.themes[0].id' "$OUT")" = "rose-pine" ]

echo '{"themes":{"packs":["core","f1"]}}' >"$SETTINGS"
build
check "f1 pack adds team themes" [ "$(jq '[.themes[] | select(.id == "f1-ferrari")] | length' "$OUT")" -eq 1 ]

jq '.name = "My Rosé" | .colors.iris = "#ff0000"' "$DOTFILES/themes/core/rose-pine.json" >"$USER_THEMES/rose-pine.json"
build
check "user theme overrides a pack theme by id" [ "$(jq -r '.themes[] | select(.id == "rose-pine") | .name' "$OUT")" = "My Rosé" ]
check "override does not duplicate the id" [ "$(jq '[.themes[] | select(.id == "rose-pine")] | length' "$OUT")" -eq 1 ]

echo '{"themes":{"packs":["../etc"]}}' >"$SETTINGS"
check "path-like pack names are rejected" bash -c "! THEMES_OUT='$OUT' bash '$BUILD' 2>/dev/null"
echo '{"themes":{"packs":["core"]}}' >"$SETTINGS"

jq '.colors.iris = "red" | .script = "rm -rf ~"' "$DOTFILES/themes/core/rose-pine.json" >"$USER_THEMES/rose-pine.json"
cp "$OUT" "$TEST_ROOT/before.json"
check "invalid user theme fails the build" bash -c "! THEMES_OUT='$OUT' bash '$BUILD' 2>/dev/null"
check "failed build keeps the previous output" cmp -s "$OUT" "$TEST_ROOT/before.json"
errors="$(build 2>&1 || true)"
check "unknown keys are reported" grep -q "unknown key 'script'" <<<"$errors"
check "bad colours are reported" grep -q "colors.iris must be" <<<"$errors"

finish
