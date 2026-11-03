# Configs used to be linked from the Nix store by home-manager; stow now owns them.
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
for pkg in hypr quickshell ghostty starship fastfetch; do
  dest="$CONF/$pkg"
  if [[ -L "$dest" ]] && readlink "$dest" | grep -q '/nix/store/'; then
    rm -f "$dest"
  fi
done
