#!/usr/bin/env bash
# Screenshot a quickshell BarPopup forced open, using a throwaway copy of the config.
# Usage: shot.sh <TriggerFile.qml> <out.png> [grim geometry] [-e 'sed expr' ...]
#   TriggerFile.qml  component (in components/) whose root item is the popup's `trigger`
#   geometry         grim -g region, e.g. "380,40 1100x620" (default: whole screen)
#   -e expr          extra sed expression applied to TriggerFile.qml (repeatable)
set -euo pipefail

src="$HOME/nixos-dotfiles/config/quickshell"
tmp=/tmp/qs-shot
trigger="$1"; out="$2"; shift 2
geom=""
[[ $# -gt 0 && $1 != -e ]] && { geom="$1"; shift; }
exprs=()
while [[ $# -gt 0 ]]; do [[ $1 == -e ]] && { exprs+=(-e "$2"); shift 2; } || shift; done

pkill -f "qs -p $tmp" 2>/dev/null || true
sleep 2
rm -rf "$tmp" && cp -r "$src" "$tmp"

sed -i 's/readonly property bool wanted: .*/readonly property bool wanted: popup.trigger.objectName === "qs-shot"/' \
  "$tmp/components/BarPopup.qml"
sed -i '0,/^[A-Z][A-Za-z]* {$/s//&\n    objectName: "qs-shot"/' "$tmp/components/$trigger"
[[ ${#exprs[@]} -gt 0 ]] && sed -i "${exprs[@]}" "$tmp/components/$trigger"

(timeout 14 qs -p "$tmp" >"$tmp.log" 2>&1 &)
sleep 11
if [[ -n $geom ]]; then grim -g "$geom" "$out"; else grim "$out"; fi
sleep 3
rg "TypeError|ReferenceError|SyntaxError|is not a type|\.qml:[0-9]+" "$tmp.log" | rg -v "DBus|portal|mpris" || true
rm -rf "$tmp" "$tmp.log"
echo "saved $out"
