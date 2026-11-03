#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"

MARKERS="$XDG_STATE_HOME/nixos-dotfiles/migrations"
count="$(ls "$DOTFILES"/scripts/migrations/*.sh | wc -l)"

check "migrations run on a fresh home" bash "$DOTFILES/scripts/migrate.sh"
check "every migration is marked" [ "$(ls "$MARKERS" | wc -l)" -eq "$count" ]
check "second run is a no-op" bash -c "[ -z \"\$(bash '$DOTFILES/scripts/migrate.sh')\" ]"

mkdir -p "$XDG_CONFIG_HOME/starship"
rm -f "$MARKERS"/*replace-starship-dir.sh
bash "$DOTFILES/scripts/migrate.sh" >/dev/null
check "starship dir migration replaces a real directory" [ ! -d "$XDG_CONFIG_HOME/starship" ]

fake="$TEST_ROOT/dotfiles"
mkdir -p "$fake/config/hooks/demo.d"
printf '#!/bin/sh\necho ran >"%s/ran"\n' "$TEST_ROOT" >"$fake/config/hooks/demo.d/10-ok"
printf '#!/bin/sh\nexit 1\n' >"$fake/config/hooks/demo.d/20-fail"
printf '#!/bin/sh\necho bad >"%s/sample"\n' "$TEST_ROOT" >"$fake/config/hooks/demo.d/30.sample"
chmod +x "$fake/config/hooks/demo.d/10-ok" "$fake/config/hooks/demo.d/20-fail"

check "failing hook makes the run fail" bash -c "! DOTFILES='$fake' bash '$DOTFILES/scripts/hook.sh' demo 2>/dev/null"
check "other hooks still run" [ -f "$TEST_ROOT/ran" ]
check "non-executable samples are skipped" [ ! -f "$TEST_ROOT/sample" ]
check "path-like event names are rejected" bash -c "! bash '$DOTFILES/scripts/hook.sh' ../x 2>/dev/null"
check "missing event dir is fine" bash "$DOTFILES/scripts/hook.sh" nothing-here

finish
