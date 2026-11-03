#!/usr/bin/env bash
# Screenshot the F1 hub (the expanded F1 island) on a given page, using a throwaway config copy.
# Usage: hub.sh <page 0-4> <out.png> [grim geometry]
#   pages: 0 Overview, 1 Results, 2 Standings, 3 Circuit, 4 Season
set -euo pipefail

src="$HOME/nixos-dotfiles/config/quickshell"
tmp=/tmp/qs-hub
page="$1"; out="$2"; geom="${3:-650,0 890x700}"

pkill -f "qs -p $tmp" 2>/dev/null || true
sleep 1.5
rm -rf "$tmp" && cp -r "$src" "$tmp"

mon=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
sed -i -e 's/property bool open: false/property bool open: true/' \
  -e "s/property string screen: \"\"/property string screen: \"$mon\"/" \
  -e "s/property int page: 0/property int page: $page/" "$tmp/components/F1Hub.qml"

(timeout 16 qs -p "$tmp" >"$tmp.log" 2>&1 &)
sleep 12
grim -g "$geom" "$out"
sleep 4
# IslandClickMask null warnings are pre-existing noise in the test instance.
rg "TypeError|ReferenceError|SyntaxError|is not a type|Cannot|Duplicate|multiple times|FINAL|QSDBG" "$tmp.log" \
  | rg -v "DBus|portal|mpris|IslandClickMask" || true
rm -rf "$tmp" "$tmp.log"
echo "saved $out"
