# An old `stow -t ~/.config` run linked hypr/quickshell files straight into ~/.config.
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
for f in apply-theme.sh base.ghostty base.toml components dw-quote.sh dw-quotes.txt \
  hyprland.lua hyprlock.conf hyprpaper.conf shell.qml themes.json; do
  if [[ -L "$CONF/$f" ]] && readlink "$CONF/$f" | grep -q 'nixos-dotfiles/config/'; then
    rm -f "$CONF/$f"
  fi
done
