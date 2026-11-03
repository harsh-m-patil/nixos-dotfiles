# Changelog

## Unreleased

First public release.

- Flake exports `nixosModules.default` and `homeManagerModules.default`; every `hosts/<name>/` is picked up automatically.
- `dotfiles.settings` (apps, input, monitor scale, theme packs, bar widgets, wallpaper dir) drives Hyprland and the bar.
- Hyprland config split into modules with an optional, untracked `local.lua`.
- Bar widgets are configurable per section; unused widgets are never loaded.
- Themes are one JSON file each in packs (`core`, `f1`), validated on build; user themes go in `~/.config/dotfiles/themes/`.
- `dotfiles` command: `install`, `doctor`, `switch`, `theme`, `bar`, `hypr`, `migrate`, `hook`, `test`.
- One-time migrations and `post-switch` hooks run during activation.
