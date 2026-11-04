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
- Quickshell bar islands (compact / peek / full) for workspaces, clock, media, F1, agent usage, and Control Center.
- F1 hub: six pages (Overview, My Team, Results, Standings, Circuit, Season), live weekend modes, Jolpica + OpenF1 data.
- Agent usage island: Cursor limits plus local provider rollups via `usage-snapshot.py`.
- CarPlay-style F1 peek and hub visuals; system monitor floating window with gauge tiles and connectivity pickers.
