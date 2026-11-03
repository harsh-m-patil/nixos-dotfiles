# ~/.config/fastfetch was a real directory with a copy of base.jsonc, which blocked stow.
# Remove it only if it holds nothing but an unmodified base.jsonc and the generated config.jsonc.
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
DIR="$CONF/fastfetch"
DOTFILES="${DOTFILES:-$HOME/nixos-dotfiles}"
[[ -d "$DIR" && ! -L "$DIR" ]] || exit 0

for f in "$DIR"/* "$DIR"/.[!.]*; do
  [[ -e "$f" ]] || continue
  case "$(basename "$f")" in
    config.jsonc) ;;
    base.jsonc) cmp -s "$f" "$DOTFILES/config/fastfetch/base.jsonc" || { echo "fastfetch: $f was edited; move your changes to $DOTFILES/config/fastfetch and delete $DIR" >&2; exit 1; } ;;
    *) echo "fastfetch: unexpected file $f; move it and delete $DIR" >&2; exit 1 ;;
  esac
done
rm -rf "$DIR"
