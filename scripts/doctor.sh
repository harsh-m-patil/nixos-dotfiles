#!/usr/bin/env bash
# Check that the desktop is wired up; prints one line per check and exits non-zero on failures.
set -uo pipefail

DOTFILES="${DOTFILES:-$HOME/nixos-dotfiles}"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
fails=0 warns=0

ok()   { printf '  \033[32mok\033[0m    %s\n' "$1"; }
warn() { printf '  \033[33mwarn\033[0m  %s\n' "$1"; warns=$((warns + 1)); }
bad()  { printf '  \033[31mfail\033[0m  %s\n' "$1"; fails=$((fails + 1)); }

echo "Repo"
[[ -d "$DOTFILES/.git" ]] && ok "repo at $DOTFILES" || bad "no git repo at $DOTFILES (set dotfiles.path)"
host="$(hostname)"
[[ -f "$DOTFILES/hosts/$host/host.nix" ]] && ok "host config hosts/$host" || bad "no hosts/$host/host.nix (run scripts/install.sh)"
if [[ -d "$DOTFILES/hosts/$host" ]] && git -C "$DOTFILES" ls-files --error-unmatch "hosts/$host/host.nix" >/dev/null 2>&1; then
  ok "hosts/$host is tracked by git"
else
  warn "hosts/$host is not git-added; flakes will not see it"
fi

echo "Config links"
for pkg in hypr quickshell ghostty starship fastfetch; do
  target="$(readlink -f "$CONF/$pkg" 2>/dev/null)"
  [[ "$target" == "$DOTFILES/config/$pkg" ]] && ok "~/.config/$pkg" || bad "~/.config/$pkg does not point into $DOTFILES/config (run dotfiles switch)"
done
for f in settings.json settings.lua; do
  [[ -f "$CONF/dotfiles/$f" ]] && ok "~/.config/dotfiles/$f" || bad "missing ~/.config/dotfiles/$f (run dotfiles switch)"
done

echo "Commands"
for cmd in hyprctl qs jq stow python3 ghostty starship swaybg hyprlock grim slurp wl-copy wpctl brightnessctl playerctl; do
  command -v "$cmd" >/dev/null && ok "$cmd" || bad "$cmd not found"
done

echo "Themes"
if out="$(bash "$DOTFILES/scripts/build-themes.sh" --check 2>&1)"; then ok "$out"; else bad "theme validation failed:"; echo "$out" | sed 's/^/          /'; fi
themes="$DOTFILES/config/quickshell/themes.json"
active="$(jq -r '.id // empty' "$STATE/quickshell/theme-state.json" 2>/dev/null)"
if [[ ! -f "$themes" ]]; then
  bad "themes.json not built (run dotfiles theme build)"
elif [[ -n "$active" ]] && jq -e --arg id "$active" '.themes[] | select(.id == $id)' "$themes" >/dev/null; then
  ok "active theme $active"
else
  warn "active theme '${active:-none}' is not in an enabled pack"
fi
walls="$(jq -r '.wallpapers.dir // empty' "$CONF/dotfiles/settings.json" 2>/dev/null)"
walls="${walls:-$HOME/Walls}"
[[ -d "$walls" ]] && ok "wallpapers in $walls" || warn "wallpaper dir $walls missing (themes still work, without wallpapers)"

echo "Migrations"
pending=0
for m in "$DOTFILES"/scripts/migrations/*.sh; do
  [[ -f "$STATE/nixos-dotfiles/migrations/$(basename "$m")" ]] || pending=$((pending + 1))
done
[[ "$pending" -eq 0 ]] && ok "all applied" || warn "$pending pending (run dotfiles migrate)"

echo "Session"
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  errors="$(hyprctl configerrors 2>/dev/null | grep -v '^\s*$')"
  [[ -z "$errors" ]] && ok "Hyprland config has no errors" || { bad "Hyprland config errors:"; echo "$errors" | sed 's/^/          /'; }
  qs ipc call theme get >/dev/null 2>&1 && ok "bar is running and answers IPC" || bad "bar not responding (run dotfiles bar restart)"
else
  warn "not inside Hyprland; skipped session checks"
fi

echo
echo "$fails failed, $warns warnings"
[[ "$fails" -eq 0 ]]
