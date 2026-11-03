#!/usr/bin/env bash
# Validate theme files and merge them into config/quickshell/themes.json.
#   Packs:       themes/<pack>/*.json, enabled by settings.json `themes.packs` (default: core)
#   User themes: ~/.config/dotfiles/themes/*.json (always included, override packs by id)
# Usage: build-themes.sh [--check]   (--check validates without writing)
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/nixos-dotfiles}"
SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/settings.json"
USER_THEMES="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/themes"
OUT="${THEMES_OUT:-$DOTFILES/config/quickshell/themes.json}"
CHECK=false
[[ "${1:-}" == "--check" ]] && CHECK=true

if $CHECK; then
  mapfile -t packs < <(find "$DOTFILES/themes" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
elif [[ -f "$SETTINGS" ]]; then
  mapfile -t packs < <(jq -r '.themes.packs // ["core"] | .[]' "$SETTINGS")
else
  packs=(core)
fi

files=()
for pack in "${packs[@]}"; do
  [[ "$pack" =~ ^[a-z0-9-]+$ && -d "$DOTFILES/themes/$pack" ]] || { echo "build-themes: unknown pack '$pack'" >&2; exit 1; }
  # Ids listed in the pack's `order` file come first, in that order; the rest follow alphabetically.
  listed=()
  [[ -f "$DOTFILES/themes/$pack/order" ]] && mapfile -t listed < <(grep -v '^\s*$' "$DOTFILES/themes/$pack/order")
  for id in "${listed[@]}"; do
    [[ -f "$DOTFILES/themes/$pack/$id.json" ]] && files+=("$DOTFILES/themes/$pack/$id.json")
  done
  for f in "$DOTFILES/themes/$pack"/*.json; do
    printf '%s\n' "${listed[@]}" | grep -qx "$(basename "$f" .json)" || files+=("$f")
  done
done
shopt -s nullglob
files+=("$USER_THEMES"/*.json)

# Themes are data only: anything outside these keys is rejected rather than passed through.
read -r -d '' VALIDATE <<'JQ' || true
def hex: type == "string" and test("^#[0-9a-fA-F]{6}$");
def required_colors: ["background","foreground","surface","overlay","muted","subtle","iris","foam","pine","gold","love","rose","highlightLow","highlightMed","highlightHigh"];
[
  (if (.id | type) == "string" and (.id | test("^[a-z0-9-]+$")) then empty else "id must match [a-z0-9-]+" end),
  (if .id == $file then empty else "id '\(.id)' must match file name '\($file)'" end),
  (if (.name | type) == "string" then empty else "name is required" end),
  (required_colors[] as $c | if (.colors[$c] | hex) then empty else "colors.\($c) must be #rrggbb" end),
  ((.starship // {}) | to_entries[] | select((.value | hex) | not) | "starship.\(.key) must be #rrggbb"),
  (keys - ["id","name","colors","ghostty","starship","tmux","wallpaper","f1"] | .[] | "unknown key '\(.)'")
] | .[]
JQ

errors=0
for f in "${files[@]}"; do
  name="$(basename "$f" .json)"
  if ! out="$(jq -r --arg file "$name" "$VALIDATE" "$f" 2>&1)"; then
    echo "build-themes: $f: invalid JSON" >&2; errors=$((errors + 1)); continue
  fi
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    echo "build-themes: $f: $line" >&2; errors=$((errors + 1))
  done <<<"$out"
done
[[ "$errors" -eq 0 ]] || exit 1
$CHECK && { echo "build-themes: ${#files[@]} themes valid"; exit 0; }

tmp="$(mktemp)"
jq -s '{version: 1, themes: (reduce .[] as $t ([]; map(select(.id != $t.id)) + [$t]))}' "${files[@]}" >"$tmp"
if ! cmp -s "$tmp" "$OUT"; then mv "$tmp" "$OUT"; else rm -f "$tmp"; fi
