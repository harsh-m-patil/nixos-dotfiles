# ~/.config/starship was once a real directory; stow needs to replace it with a link.
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
if [[ -d "$CONF/starship" && ! -L "$CONF/starship" ]]; then
  rm -rf "$CONF/starship"
fi
