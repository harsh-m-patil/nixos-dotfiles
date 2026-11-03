# How it fits together

NixOS flake with home-manager as a NixOS module. Desktop configs that change at runtime are **stowed**, not built:
`~/.config/{hypr,quickshell,ghostty,starship,fastfetch}` are symlinks into `config/`, so edits apply without a rebuild.

## Layout

| Path | Role |
|------|------|
| `flake.nix` | Builds `nixosConfigurations.<name>` for every `hosts/<name>/host.nix` |
| `modules/nixos.nix` | System side of the desktop (`dotfiles.user`, Hyprland, audio, fonts, runtime tools) |
| `modules/home.nix` | User side (`dotfiles.settings`, `dotfiles.path`, GTK/Qt, stow + theme activation) |
| `hosts/<name>/` | One machine: `host.nix` (user, system), `configuration.nix`, `home.nix`, hardware config |
| `templates/host/` | What `scripts/install.sh` copies for a new machine |
| `config/` | Stowed, editable configs |
| `themes/<pack>/` | One JSON per theme; `order` sets picker order |
| `scripts/` | `dotfiles` command and the scripts it wraps |
| `tests/` | `*-test.sh`, run by `dotfiles test` |

## Edited vs generated

| Kind | Location | Edit it? |
|------|----------|----------|
| Settings | `dotfiles.settings` in `hosts/<name>/home.nix` | Yes, then `dotfiles switch` |
| Hyprland | `config/hypr/*.lua` | Yes, then `dotfiles hypr reload` |
| Per-machine Hyprland tweaks | `config/hypr/local.lua` (gitignored, loaded last) | Yes |
| Bar | `config/quickshell/` | Yes; Quickshell hot-reloads |
| Themes | `themes/<pack>/*.json`, `~/.config/dotfiles/themes/*.json` | Yes, then `dotfiles theme build` |
| Ghostty / Starship / Fastfetch bases | `config/ghostty/base.ghostty`, `config/starship/base.toml`, `config/fastfetch/base.jsonc` | Yes |
| Settings output | `~/.config/dotfiles/settings.{json,lua}` | **No**: generated from `dotfiles.settings` |
| Theme catalog | `config/quickshell/themes.json` | **No**: built from `themes/` |
| Themed app configs | `config/ghostty/config.ghostty`, `~/.config/starship.toml`, `config/fastfetch/config.jsonc` | **No**: base + active theme |
| Theme state | `~/.local/state/quickshell/` | **No**: written by `apply-theme.sh` and the bar |
| Migration markers | `~/.local/state/nixos-dotfiles/migrations/` | Delete one to re-run that migration |

## Settings flow

`dotfiles.settings` → home-manager writes `~/.config/dotfiles/settings.json` (read by the bar's `Settings` singleton and
`build-themes.sh`) and `settings.lua` (read by `config/hypr/settings.lua`, which fills in defaults).
Unknown keys pass through, so your own Hyprland modules or widgets can read new settings.

## Hyprland modules

`hyprland.lua` loads, in order: `monitors`, `env`, `autostart`, `looknfeel`, `input`, `bindings`, `rules`, then `local` if present.
Modules share code through `hypr_module(name)` (`settings`, `palette`, `workspace_anim`).
It uses `dofile`, so every reload re-reads edited files.

## Bar

`TopBar.qml` builds each section from `Settings.bar.{left,center,right}`. To add a widget: create the QML component,
register it in `qmldir`, add it to the `widgets` map in `TopBar.qml`, and add its id to the enum in `modules/home.nix`.

### IPC (`qs ipc call <target> <fn> [args]`)

| Target | Functions |
|--------|-----------|
| `bar` | `toggle` |
| `sysmon` | `toggle`, `tab <0-3>` |
| `theme` | `list`, `listF1`, `get`, `set <id>`, `cycle` (F1 only), `cycleAll`, `togglePicker`, `openPicker`, `cycleWallpaper`, `toggleWallpaperPicker` |

## Themes

Required: `id` (same as the file name), `name`, and `colors` with `background foreground surface overlay muted subtle iris
foam pine gold love rose highlightLow highlightMed highlightHigh` as `#rrggbb`. Optional: `ghostty`, `starship`, `tmux`,
`wallpaper.pool` (a folder under `<wallpapers.dir>/f1/`), `f1`. Other keys are rejected. Themes are data only.

## Migrations

One-time fixes for existing machines go in `scripts/migrations/<unix-timestamp>-<name>.sh` (`date +%s`).
They run in filename order during activation, before stow, and must be idempotent since a fresh machine runs them all.
A failure stops later migrations but never aborts activation; refuse rather than delete user data.

## Hooks

Executables in `config/hooks/<event>.d/` run in filename order via `dotfiles hook <event>`.
`post-switch` runs at the end of every activation. Files without the executable bit (like `*.sample`) are skipped.

## Tests

`dotfiles test` runs `tests/*-test.sh` against a temporary `HOME` with `hyprctl`, `tmux` and `qs` stubbed.
