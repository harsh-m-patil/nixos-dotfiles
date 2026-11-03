#!/usr/bin/env bash
# Apply a desktop theme at runtime (no Nix rebuild). Called from Quickshell or: apply-theme.sh <id>
set -euo pipefail

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
QS="$CONFIG/quickshell"
THEMES_JSON="$QS/themes.json"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
STATE="$STATE_DIR/theme-state.json"
HYPR_COLORS="$STATE_DIR/hypr-colors.lua"
STAR_PALETTE="$STATE_DIR/starship-palette.toml"
FASTFETCH_BASE="$CONFIG/fastfetch/base.jsonc"
FASTFETCH_OUT="$CONFIG/fastfetch/config.jsonc"
TEAM_LOGO_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/team-logos"
SETTINGS="$CONFIG/dotfiles/settings.json"
if [[ -z "${WALLS_DIR:-}" && -f "$SETTINGS" ]]; then
  WALLS_DIR="$(jq -r '.wallpapers.dir // empty' "$SETTINGS" 2>/dev/null || true)"
fi
WALLS_DIR="${WALLS_DIR:-$HOME/Walls}"
WALL_LINK="$WALLS_DIR/.theme-wallpaper"
WALL_STATE="$STATE_DIR/wallpaper-path"
WALL_GEOM="$QS/wallpaper-geometry.py"

wallpaper_is_desktop_landscape() {
  local f="$1"
  [[ -f "$WALL_GEOM" ]] || return 0
  python3 "$WALL_GEOM" check "$f" &>/dev/null
}

wallpaper_image_ext() {
  local bn="$1"
  [[ "$bn" =~ \.(jpg|jpeg|png|webp)$ ]] || return 1
  return 0
}

wallpaper_is_mercedes() {
  local bn="$1"
  [[ "$bn" =~ ^download\([0-9]+\). ]] && return 0
  [[ "${bn,,}" == *mercedes* ]] && return 0
  return 1
}

wallpaper_is_excluded() {
  local bn="$1"
  [[ "${bn,,}" == wallhaven* ]] && return 0
  [[ "${bn,,}" == *wec* ]] && return 0
  [[ "${bn,,}" == *cota* ]] && return 0
  return 1
}

wallpaper_in_ferrari_pool() {
  local bn="$1"
  wallpaper_image_ext "$bn" || return 1
  wallpaper_is_excluded "$bn" && return 1
  wallpaper_is_mercedes "$bn" && return 1
  return 0
}

wallpaper_in_mercedes_pool() {
  local bn="$1"
  wallpaper_image_ext "$bn" || return 1
  wallpaper_is_mercedes "$bn" && return 0
  return 1
}

wallpaper_pool_for_path() {
  local path="$1" pool prefix="$WALLS_DIR/f1/"
  path="$(readlink -f "$path" 2>/dev/null || true)"
  [[ -n "$path" && "$path" == "$prefix"* ]] || return 1
  pool="${path#"$prefix"}"
  pool="${pool%%/*}"
  [[ -n "$pool" ]] && printf '%s' "$pool"
}

wallpaper_current_pool() {
  local id theme
  [[ -f "$STATE" && -f "$THEMES_JSON" ]] || return 1
  id="$(jq -r '.id // empty' "$STATE" 2>/dev/null)"
  [[ -n "$id" ]] || return 1
  theme="$(jq -c --arg id "$id" '.themes[] | select(.id == $id)' "$THEMES_JSON")"
  jq -r '.wallpaper.pool // empty' <<<"$theme"
}

wallpaper_find_default_in_dir() {
  local dir="$1" f bn
  shopt -s nullglob
  for f in "$dir"/default.*; do
    [[ -f "$f" ]] || continue
    bn="$(basename "$f")"
    wallpaper_image_ext "$bn" || continue
    wallpaper_is_desktop_landscape "$f" || continue
    shopt -u nullglob
    printf '%s' "$f"
    return 0
  done
  shopt -u nullglob
  return 1
}

# Remember the chosen wallpaper per team as ~/Walls/f1/<pool>/default.<ext>
wallpaper_promote_as_default() {
  local path="$1" pool="${2:-}" team_dir bn ext old new legacy
  path="$(readlink -f "$path" 2>/dev/null || true)"
  [[ -n "$path" && -f "$path" ]] || return 1

  if [[ -z "$pool" ]]; then
    pool="$(wallpaper_pool_for_path "$path" || true)"
    [[ -n "$pool" ]] || pool="$(wallpaper_current_pool || true)"
  fi
  [[ -n "$pool" ]] || return 1

  team_dir="$WALLS_DIR/f1/$pool"
  [[ -d "$team_dir" && "$path" == "$team_dir"/* ]] || return 1

  bn="$(basename "$path")"
  if [[ "$bn" == default.* ]]; then
    printf '%s' "$path"
    return 0
  fi

  ext="${bn##*.}"
  new="$team_dir/default.$ext"

  if old="$(wallpaper_find_default_in_dir "$team_dir")"; then
    if [[ "$old" == "$path" ]]; then
      printf '%s' "$path"
      return 0
    fi
    legacy="legacy-$(printf '%s' "$old" | cksum | awk '{print $1}')-${RANDOM}.${old##*.}"
    mv -f -- "$old" "$team_dir/$legacy"
  fi

  if [[ "$path" != "$new" ]]; then
    mv -f -- "$path" "$new"
    path="$new"
  fi
  printf '%s' "$path"
}

pick_wallpaper_from_pool() {
  local pool="$1" theme_id="$2"
  local -a files=()
  local f bn team_dir="$WALLS_DIR/f1/$pool"

  [[ -d "$WALLS_DIR" ]] || return 1

  if [[ -d "$team_dir" ]]; then
    if f="$(wallpaper_find_default_in_dir "$team_dir")"; then
      printf '%s' "$f"
      return 0
    fi
  fi

  shopt -s nullglob
  if [[ -d "$team_dir" ]]; then
    for f in "$team_dir"/*; do
      [[ -f "$f" ]] || continue
      bn="$(basename "$f")"
      wallpaper_image_ext "$bn" || continue
      wallpaper_is_desktop_landscape "$f" || continue
      files+=("$f")
    done
  fi
  if ((${#files[@]} == 0)); then
    for f in "$WALLS_DIR"/*; do
      [[ -f "$f" ]] || continue
      bn="$(basename "$f")"
      case "$pool" in
        mercedes) wallpaper_in_mercedes_pool "$bn" || continue ;;
        ferrari) wallpaper_in_ferrari_pool "$bn" || continue ;;
        *) continue ;;
      esac
      wallpaper_is_desktop_landscape "$f" || continue
      files+=("$f")
    done
  fi
  shopt -u nullglob

  ((${#files[@]} > 0)) || return 1
  mapfile -t files < <(printf '%s\n' "${files[@]}" | LC_ALL=C sort)

  local idx=0
  if ((${#files[@]} > 1)); then
    idx="$(printf '%s' "$theme_id" | cksum | awk '{print $1 % '"${#files[@]}"'}')"
  fi
  printf '%s' "${files[$idx]}"
}

list_wallpapers_in_pool() {
  local pool="$1"
  local -a files=()
  local f bn team_dir="$WALLS_DIR/f1/$pool"

  [[ -d "$WALLS_DIR" ]] || return 1

  shopt -s nullglob
  if [[ -d "$team_dir" ]]; then
    for f in "$team_dir"/*; do
      [[ -f "$f" ]] || continue
      bn="$(basename "$f")"
      wallpaper_image_ext "$bn" || continue
      wallpaper_is_desktop_landscape "$f" || continue
      files+=("$f")
    done
  fi
  if ((${#files[@]} == 0)); then
    for f in "$WALLS_DIR"/*; do
      [[ -f "$f" ]] || continue
      bn="$(basename "$f")"
      case "$pool" in
        mercedes) wallpaper_in_mercedes_pool "$bn" || continue ;;
        ferrari) wallpaper_in_ferrari_pool "$bn" || continue ;;
        *) continue ;;
      esac
      wallpaper_is_desktop_landscape "$f" || continue
      files+=("$f")
    done
  fi
  shopt -u nullglob

  ((${#files[@]} > 0)) || return 1
  printf '%s\n' "${files[@]}" | LC_ALL=C sort
}

cmd_preview_map() {
  [[ -f "$THEMES_JSON" ]] || {
    echo '{}'
    return 0
  }
  local theme id pool path
  local -a chunks=()
  while IFS= read -r theme; do
    [[ -n "$theme" ]] || continue
    id="$(jq -r '.id' <<<"$theme")"
    pool="$(jq -r '.wallpaper.pool // empty' <<<"$theme")"
    [[ -n "$pool" ]] || continue
    path="$(pick_wallpaper_from_pool "$pool" "$id")" || continue
    chunks+=("$(jq -nc --arg id "$id" --arg path "$path" '{($id):$path}')")
  done < <(jq -c '.themes[] | select(.wallpaper.pool != null)' "$THEMES_JSON")
  if ((${#chunks[@]} == 0)); then
    echo '{}'
  else
    jq -s 'add' <<<"$(printf '%s\n' "${chunks[@]}")"
  fi
}

cmd_set_wallpaper() {
  local path="$1" promote="${2:-false}"
  [[ -n "$path" && -f "$path" ]] || return 1
  if [[ "$promote" == true ]]; then
    path="$(wallpaper_promote_as_default "$path" || true)"
    [[ -n "$path" && -f "$path" ]] || return 1
  fi
  apply_desktop_wallpaper "$path"
  basename "$path"
}

cmd_wallpaper_data() {
  local previews pools pool chunk
  previews="$(cmd_preview_map)"
  pools='{}'
  while IFS= read -r pool; do
    [[ -n "$pool" ]] || continue
    mapfile -t files < <(list_wallpapers_in_pool "$pool" || true)
    ((${#files[@]} > 0)) || continue
    chunk="$(printf '%s\n' "${files[@]}" | jq -R -s --arg pool "$pool" '{($pool): (split("\n") | map(select(length > 0)))}')"
    pools="$(jq -s '.[0] * .[1]' <<<"$pools"$'\n'"$chunk")"
  done < <(jq -r '.themes[] | select(.wallpaper.pool != null) | .wallpaper.pool' "$THEMES_JSON" 2>/dev/null | LC_ALL=C sort -u)
  jq -nc --argjson previews "$previews" --argjson pools "$pools" '{previews:$previews, pools:$pools}'
}

cmd_cycle_wallpaper() {
  local id theme wall_pool current
  local -a files
  [[ -f "$THEMES_JSON" ]] || return 1
  id="$(jq -r '.id // empty' "$STATE" 2>/dev/null)"
  [[ -n "$id" ]] || return 1
  theme="$(jq -c --arg id "$id" '.themes[] | select(.id == $id)' "$THEMES_JSON")"
  wall_pool="$(jq -r '.wallpaper.pool // empty' <<<"$theme")"
  [[ -n "$wall_pool" ]] || {
    echo "apply-theme: theme has no wallpaper pool" >&2
    return 1
  }
  mapfile -t files < <(list_wallpapers_in_pool "$wall_pool" || true)
  ((${#files[@]} > 0)) || {
    echo "apply-theme: no wallpapers in pool '$wall_pool'" >&2
    return 1
  }
  current=""
  if [[ -f "$WALL_STATE" ]]; then
    current="$(<"$WALL_STATE")"
  fi
  if [[ -z "$current" && -L "$WALL_LINK" ]]; then
    current="$(readlink -f "$WALL_LINK" 2>/dev/null || true)"
  fi
  local i next=0
  if [[ -n "$current" ]]; then
    for i in "${!files[@]}"; do
      if [[ "${files[$i]}" == "$current" ]]; then
        next=$(( (i + 1) % ${#files[@]} ))
        break
      fi
    done
  fi
  local chosen="${files[$next]}"
  if chosen="$(wallpaper_promote_as_default "$chosen" "$wall_pool")"; then
    apply_desktop_wallpaper "$chosen"
    basename "$chosen"
  else
    apply_desktop_wallpaper "${files[$next]}"
    basename "${files[$next]}"
  fi
}

apply_desktop_wallpaper() {
  local path="$1"
  [[ -n "$path" && -f "$path" ]] || return 0

  mkdir -p "$STATE_DIR" "$WALLS_DIR"
  ln -sfn "$path" "$WALL_LINK"
  printf '%s\n' "$path" >"$WALL_STATE"

  if [[ -f "$THEMES_JSON" && -f "$STATE" ]]; then
    local tid tjson py
    tid="$(jq -r '.id // empty' "$STATE" 2>/dev/null)"
    if [[ -n "$tid" ]]; then
      tjson="$(jq -c --arg id "$tid" '.themes[] | select(.id == $id)' "$THEMES_JSON" 2>/dev/null)"
      if [[ -n "$tjson" && "$tjson" != "null" ]]; then
        py="$(find_python || true)"
        write_fastfetch_config "$py" "$tjson"
      fi
    fi
  fi

  if command -v swaybg >/dev/null; then
    # Nix wraps swaybg, so the process name is .swaybg-wrapped; match the command line.
    local old
    old="$(pgrep -f '^swaybg ' || true)"
    setsid swaybg -i "$path" -m fill &>/dev/null &
    if [[ -n "$old" ]]; then
      sleep 0.25
      kill $old 2>/dev/null || true
    fi
  fi

  if command -v hyprctl >/dev/null; then
    hyprctl hyprpaper preload "$path" &>/dev/null || true
    hyprctl hyprpaper wallpaper ",$path" &>/dev/null || true
  fi
}

find_python() {
  local c
  for c in /run/current-system/sw/bin/python3 /usr/bin/python3 python3; do
    if command -v "$c" &>/dev/null; then
      command -v "$c"
      return 0
    fi
  done
  return 1
}

is_accent_theme() {
  [[ "$(jq -r '.f1 != null' <<<"$theme")" == true ]]
}

assemble_ghostty_config() {
  local gtheme gbg base theme_frag out
  gtheme="$(jq -r '.ghostty.theme // empty' <<<"$theme")"
  gbg="$(jq -r '.ghostty.background // empty' <<<"$theme")"
  base="$CONFIG/ghostty/base.ghostty"
  theme_frag="$STATE_DIR/ghostty-theme.ghostty"
  out="$CONFIG/ghostty/config.ghostty"
  if is_accent_theme; then
    gtheme="Rose Pine"
    gbg="#191724"
  fi
  [[ -n "$gtheme" && -n "$gbg" && -f "$base" ]] || return 0
  mkdir -p "$STATE_DIR" "$(dirname "$out")"
  printf 'theme = "%s"\nbackground = %s\n' "$gtheme" "$gbg" >"$theme_frag"
  if is_accent_theme; then
    # Rosé Pine slots: 3/11 gold, 5/13 iris, 6/14 rose; cursor follows readable team accent
    APPLY_THEME_JSON="$theme" GHOSTTY_FRAG_PATH="$theme_frag" python3 <<'PY'
import json, os

def rel_luminance(hex_color):
    h = hex_color.lstrip("#")
    if len(h) != 6:
        return 0.0
    channels = [int(h[i : i + 2], 16) / 255.0 for i in (0, 2, 4)]

    def linear(c):
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = (linear(c) for c in channels)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def too_bright(hex_color, threshold=0.72):
    return rel_luminance(hex_color) >= threshold

def first_readable(*candidates):
    for c in candidates:
        if c and isinstance(c, str) and c.startswith("#") and not too_bright(c):
            return c
    return None

theme = json.loads(os.environ["APPLY_THEME_JSON"])
path = os.environ["GHOSTTY_FRAG_PATH"]
c = theme.get("colors") or {}
gold = first_readable(c.get("gold"), c.get("pine"), c.get("rose"), c.get("foam")) or c.get("gold")
iris = first_readable(c.get("iris"), c.get("foam"), c.get("pine"), c.get("rose"), c.get("gold")) or c.get("iris")
rose = c.get("rose") or iris
lines = [
    f"palette = 3={gold}",
    f"palette = 11={gold}",
    f"palette = 5={iris}",
    f"palette = 13={iris}",
    f"palette = 6={rose}",
    f"palette = 14={rose}",
    f"cursor-color = {iris}",
    "selection-background = #403d52",
    "selection-foreground = #e0def4",
    "",
]
with open(path, "a", encoding="utf-8") as f:
    f.write("\n".join(lines))
PY
  fi
  rm -f "$out"
  cat "$base" "$theme_frag" >"$out"
  chmod 644 "$out"
  gdbus call --session --dest com.mitchellh.ghostty \
    --object-path /com/mitchellh/ghostty \
    --method org.gtk.Actions.Activate reload-config "@as []" "@a{sv} {}" \
    &>/dev/null || true
}

assemble_starship_config() {
  local base out
  base="$CONFIG/starship/base.toml"
  out="$CONFIG/starship.toml"
  [[ -f "$base" && -f "$STAR_PALETTE" ]] || return 0
  mkdir -p "$(dirname "$out")"
  rm -f "$out"
  # Palette must come after base.toml: otherwise format/modules nest under [palettes.rose].
  cat "$base" "$STAR_PALETTE" >"$out"
  chmod 644 "$out"
}

write_fastfetch_config() {
  local python="$1" theme_json="$2"
  [[ -n "$python" && -f "$FASTFETCH_BASE" ]] || return 0
  mkdir -p "$(dirname "$FASTFETCH_OUT")"
  local wall_path=""
  if [[ -f "$WALL_STATE" ]]; then
    wall_path="$(<"$WALL_STATE")"
  elif [[ -L "$WALL_LINK" ]]; then
    wall_path="$(readlink -f "$WALL_LINK" 2>/dev/null || true)"
  fi
  APPLY_THEME_JSON="$theme_json" \
    FASTFETCH_BASE_PATH="$FASTFETCH_BASE" \
    FASTFETCH_OUT_PATH="$FASTFETCH_OUT" \
    TEAM_LOGO_DIR="$TEAM_LOGO_DIR" \
    WALLS_DIR="$WALLS_DIR" \
    WALLPAPER_PATH="$wall_path" \
    "$python" <<'PY'
import json, os, re
from pathlib import Path

theme = json.loads(os.environ["APPLY_THEME_JSON"])
base_path = Path(os.environ["FASTFETCH_BASE_PATH"])
out_path = Path(os.environ["FASTFETCH_OUT_PATH"])
logo_dir = Path(os.environ["TEAM_LOGO_DIR"])
walls = Path(os.environ["WALLS_DIR"])
wallpaper_path = os.environ.get("WALLPAPER_PATH", "").strip()

config = json.loads(base_path.read_text(encoding="utf-8"))
colors = theme.get("colors") or {}
iris = colors.get("iris")
if iris:
    config.setdefault("display", {}).setdefault("color", {})["keys"] = iris

def team_slug(constructor: str) -> str:
    return re.sub(r"[^a-z]", "", (constructor or "").lower())

def pick_f1_team_logo():
    f1 = theme.get("f1")
    if not f1:
        return None
    slug = team_slug(f1.get("constructor", ""))
    if not slug:
        return None
    team_logo = logo_dir / f"{slug}.png"
    if team_logo.is_file() and team_logo.stat().st_size > 0:
        return team_logo
    return None

team_logo = pick_f1_team_logo()
if team_logo:
    # PNG team marks via Kitty graphics (crisp in Ghostty); not chafa/car photos.
    config["logo"] = {
        "type": "kitty-direct",
        "source": str(team_logo),
        "width": 30,
        "height": 12,
        "padding": {"right": 2},
    }
else:
    config["logo"] = {"type": "small", "padding": {"right": 2}}

out_path.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
PY
  chmod 644 "$FASTFETCH_OUT"
}

write_hypr_colors() {
  local python="$1"
  [[ -n "$python" ]] || return 0
  mkdir -p "$STATE_DIR"
  APPLY_THEME_JSON="$theme" HYPR_COLORS_PATH="$HYPR_COLORS" "$python" <<'PY'
import json, os, sys

theme = json.loads(os.environ["APPLY_THEME_JSON"])
path = os.environ["HYPR_COLORS_PATH"]
c = theme["colors"]

def hx(key):
    return c[key].lstrip("#")

lua_keys = {
    "base": hx("background"),
    "surface": hx("surface"),
    "overlay": hx("overlay"),
    "muted": hx("muted"),
    "subtle": hx("subtle"),
    "text": hx("foreground"),
    "love": hx("love"),
    "gold": hx("gold"),
    "rose": hx("rose"),
    "pine": hx("pine"),
    "foam": hx("foam"),
    "iris": hx("iris"),
    "highlight_low": hx("highlightLow"),
    "highlight_med": hx("highlightMed"),
    "highlight_high": hx("highlightHigh"),
}
lines = ["return {"]
for k, v in lua_keys.items():
    lines.append(f'    {k:<15} = "{v}",')
lines.append("}")
open(path, "w", encoding="utf-8").write("\n".join(lines) + "\n")
PY
}

write_starship_palette() {
  local python="$1"
  [[ -n "$python" ]] || return 0
  mkdir -p "$STATE_DIR"
  APPLY_THEME_JSON="$theme" STAR_PALETTE_PATH="$STAR_PALETTE" "$python" <<'PY'
import json, os

def rel_luminance(hex_color):
    h = hex_color.lstrip("#")
    if len(h) != 6:
        return 0.0
    channels = [int(h[i : i + 2], 16) / 255.0 for i in (0, 2, 4)]

    def linear(c):
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = (linear(c) for c in channels)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def too_bright(hex_color, threshold=0.72):
    return rel_luminance(hex_color) >= threshold

def first_readable(*candidates):
    for c in candidates:
        if c and isinstance(c, str) and c.startswith("#") and not too_bright(c):
            return c
    return None

theme = json.loads(os.environ["APPLY_THEME_JSON"])
path = os.environ["STAR_PALETTE_PATH"]
pal = dict(theme.get("starship", {}))
if theme.get("f1"):
    pal.update(rose_base="#191724", rose_text="#e0def4", rose_muted="#6e6a86", rose_subtle="#908caa")
    colors = theme.get("colors") or {}
    iris = pal.get("rose_iris") or colors.get("iris")
    foam = pal.get("rose_foam") or colors.get("foam")
    gold = pal.get("rose_gold") or colors.get("gold")
    pine = colors.get("pine")
    rose = colors.get("rose")
    pick_iris = first_readable(iris, foam, pine, rose, gold)
    if pick_iris:
        pal["rose_iris"] = pick_iris
    pick_gold = first_readable(gold, pine, rose, foam, pick_iris)
    if pick_gold:
        pal["rose_gold"] = pick_gold
lines = ['palette = "rose"', "", "[palettes.rose]"]
for k, v in pal.items():
    lines.append(f'{k} = "{v}"')
lines.append("")
open(path, "w", encoding="utf-8").write("\n".join(lines))
PY
}

case "${1:-}" in
  --preview-map)
    cmd_preview_map
    exit 0
    ;;
  --wallpaper-data)
    cmd_wallpaper_data
    exit 0
    ;;
  --set-wallpaper)
    shift
    path=""
    promote=true
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --no-promote) promote=false; shift ;;
        --promote) promote=true; shift ;;
        *)
          path="$1"
          shift
          break
          ;;
      esac
    done
    cmd_set_wallpaper "$path" "$promote"
    exit 0
    ;;
  --cycle-wallpaper)
    cmd_cycle_wallpaper
    exit 0
    ;;
  --ensure)
    [[ -f "$HYPR_COLORS" ]] || exit 0
    id="$(jq -r '.id // "rose-pine"' "$STATE" 2>/dev/null || echo rose-pine)"
    want_base="$(jq -r --arg id "$id" '.themes[] | select(.id == $id) | .colors.background' "$THEMES_JSON" 2>/dev/null | tr -d '#')"
    want_iris="$(jq -r --arg id "$id" '.themes[] | select(.id == $id) | .colors.iris' "$THEMES_JSON" 2>/dev/null | tr -d '#')"
    have_base="$(sed -n 's/.*base[[:space:]]*=[[:space:]]*"\([0-9a-fA-F]*\)".*/\1/p' "$HYPR_COLORS" | head -1)"
    have_iris="$(sed -n 's/.*iris[[:space:]]*=[[:space:]]*"\([0-9a-fA-F]*\)".*/\1/p' "$HYPR_COLORS" | head -1)"
    [[ "${want_base,,}" == "${have_base,,}" && "${want_iris,,}" == "${have_iris,,}" ]] && exit 0
    set -- "$id"
    ;;
esac

SKIP_WALLPAPER=false
theme_args=()
for arg in "$@"; do
  if [[ "$arg" == "--no-wallpaper" ]]; then
    SKIP_WALLPAPER=true
  else
    theme_args+=("$arg")
  fi
done

id="${theme_args[0]:-}"
if [[ -z "$id" ]]; then
  id="$(jq -r '.id // "rose-pine"' "$STATE" 2>/dev/null || echo rose-pine)"
fi

if [[ ! -f "$THEMES_JSON" ]]; then
  echo "apply-theme: missing $THEMES_JSON" >&2
  exit 1
fi

theme="$(jq -c --arg id "$id" '.themes[] | select(.id == $id)' "$THEMES_JSON")"
if [[ -z "$theme" || "$theme" == "null" ]]; then
  echo "apply-theme: unknown theme id: $id" >&2
  exit 1
fi

PYTHON="$(find_python || true)"
write_hypr_colors "$PYTHON"
write_starship_palette "$PYTHON"
write_fastfetch_config "$PYTHON" "$theme"

mkdir -p "$STATE_DIR"
printf '%s\n' "{\"id\":\"$id\"}" >"$STATE"

assemble_ghostty_config
assemble_starship_config

wall_pool="$(jq -r '.wallpaper.pool // empty' <<<"$theme")"
if [[ "$SKIP_WALLPAPER" != true && -n "$wall_pool" ]]; then
  if wall_path="$(pick_wallpaper_from_pool "$wall_pool" "$id")"; then
    apply_desktop_wallpaper "$wall_path"
  else
    echo "apply-theme: no wallpaper in pool '$wall_pool' under $WALLS_DIR" >&2
  fi
fi

variant="$(jq -r '.tmux.variant // empty' <<<"$theme")"
if [[ -n "$variant" ]] && command -v tmux >/dev/null && tmux info &>/dev/null 2>&1; then
  tmux set -g @rose_pine_variant "$variant" 2>/dev/null || true
  for sock in $(tmux list-sockets -F '#{socket_path}' 2>/dev/null); do
    tmux -S "$sock" set -g @rose_pine_variant "$variant" 2>/dev/null || true
  done
  tpm="${TMUX_PLUGIN_MANAGER_PATH:-$HOME/.tmux/plugins}"
  rp="$tpm/tmux-plugins/rose-pine/rose-pine.tmux"
  if [[ -f "$rp" ]]; then
    tmux run-shell "bash '$rp'" 2>/dev/null || true
  fi
fi

hyprctl reload 2>/dev/null || true

echo "apply-theme: applied $id"
