#!/usr/bin/env bash
# Set up this desktop on a NixOS machine:
#   bash <(curl -fsSL https://raw.githubusercontent.com/harsh-m-patil/nixos-dotfiles/main/scripts/install.sh)
# or, from a clone:  ./scripts/install.sh [--yes] [--no-switch]
#
# Creates hosts/<hostname>/ from templates/host, copies the hardware config, and switches.
set -euo pipefail

REPO_URL="${DOTFILES_REPO:-https://github.com/harsh-m-patil/nixos-dotfiles.git}"
DOTFILES="${DOTFILES:-$HOME/nixos-dotfiles}"
YES=false
SWITCH=true
for arg in "$@"; do
  case "$arg" in
    --yes|-y) YES=true ;;
    --no-switch) SWITCH=false ;;
    -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
    *) echo "install: unknown option $arg" >&2; exit 2 ;;
  esac
done

export NIX_CONFIG="experimental-features = nix-command flakes"
say() { printf '\033[1m==>\033[0m %s\n' "$*"; }
die() { printf 'install: %s\n' "$*" >&2; exit 1; }
ask() { # ask <var> <prompt> <default>
  local reply=""
  if ! $YES; then read -rp "$2 [$3]: " reply </dev/tty; fi
  printf -v "$1" '%s' "${reply:-$3}"
}

[[ -f /etc/NIXOS ]] || die "this installer only runs on NixOS"
[[ "$EUID" -ne 0 ]] || die "run as your normal user, not root (sudo is used when needed)"

git() { if command -v git >/dev/null; then command git "$@"; else nix run nixpkgs#git -- "$@"; fi; }

if [[ ! -d "$DOTFILES/.git" ]]; then
  say "Cloning $REPO_URL into $DOTFILES"
  git clone "$REPO_URL" "$DOTFILES"
fi
cd "$DOTFILES"

default_tz="$(timedatectl show -p Timezone --value 2>/dev/null || true)"
default_locale="${LANG:-en_US.UTF-8}"
default_state="$(nixos-version | cut -d. -f1-2)"
default_kb="$(localectl status 2>/dev/null | sed -n 's/.*X11 Layout: *//p')"

ask HOST "Hostname" "$(hostname)"
ask USER_NAME "User" "$USER"
ask TIMEZONE "Timezone" "${default_tz:-UTC}"
ask LOCALE "Locale" "$default_locale"
ask KB_LAYOUT "Keyboard layout" "${default_kb:-us}"

[[ "$HOST" =~ ^[a-zA-Z0-9-]+$ ]] || die "hostname may only contain letters, digits and '-'"
[[ "$USER_NAME" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "invalid user name: $USER_NAME"
[[ "$USER_NAME" == "$USER" ]] || say "Note: the repo stays in $DOTFILES; set dotfiles.path if $USER_NAME's home differs"

HOST_DIR="hosts/$HOST"
if [[ -e "$HOST_DIR" ]]; then
  say "$HOST_DIR already exists; keeping it"
else
  [[ -d /sys/firmware/efi ]] || die "template uses systemd-boot (UEFI); this machine boots BIOS. Create $HOST_DIR by hand from templates/host."
  say "Creating $HOST_DIR"
  mkdir -p "$HOST_DIR"
  for f in templates/host/*.nix; do
    sed -e "s|@USER@|$USER_NAME|g" -e "s|@TIMEZONE@|$TIMEZONE|g" -e "s|@LOCALE@|$LOCALE|g" \
        -e "s|@KB_LAYOUT@|$KB_LAYOUT|g" -e "s|@STATE_VERSION@|$default_state|g" \
        "$f" >"$HOST_DIR/$(basename "$f")"
  done
  if [[ -f /etc/nixos/hardware-configuration.nix ]]; then
    cp /etc/nixos/hardware-configuration.nix "$HOST_DIR/"
  else
    nixos-generate-config --show-hardware-config >"$HOST_DIR/hardware-configuration.nix"
  fi
fi

# Flakes only see files git knows about.
git add "$HOST_DIR"

say "Checking the configuration evaluates"
nix eval --raw ".#nixosConfigurations.$HOST.config.system.build.toplevel.drvPath" >/dev/null

if $SWITCH; then
  ask GO "Switch to it now? (y/n)" "y"
  if [[ "$GO" == y* ]]; then
    sudo env NIX_CONFIG="$NIX_CONFIG" nixos-rebuild switch --flake ".#$HOST"
    say "Done. Log out and pick Hyprland at the login screen, then run: dotfiles doctor"
    exit 0
  fi
fi
say "Ready. Switch with: sudo nixos-rebuild switch --flake $DOTFILES#$HOST"
