# nixos-dotfiles

A Hyprland + Quickshell desktop for NixOS: a themeable bar, runtime theme switching without rebuilds,
and configs you can edit live while Nix keeps the system reproducible.

<!-- Add a screenshot: ![desktop](docs/screenshot.png) -->

## Install

On an existing NixOS install (UEFI), as your normal user:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/harsh-m-patil/nixos-dotfiles/main/scripts/install.sh)
```

This clones the repo to `~/nixos-dotfiles`, asks for hostname, user, timezone, locale and keyboard layout,
creates `hosts/<hostname>/` with your hardware config, and switches. Log out, pick Hyprland, then run `dotfiles doctor`.

Already cloned? Run `./scripts/install.sh`.

## Customize

Your machine lives in `hosts/<hostname>/`:

- `home.nix`: `dotfiles.settings` (apps, keyboard, scale, themes, bar widgets) and your user packages
- `configuration.nix`: boot, locale, system packages and services

```nix
dotfiles.settings = {
  apps.browser = "chromium";
  input.kbOptions = "caps:escape";
  monitor.scale = 1.5;
  theme.packs = [ "core" "f1" ];
  bar.right = [ "agentUsage" "tray" "status" ];
};
```

All options are in [`modules/home.nix`](modules/home.nix). Apply with `dotfiles switch`.

Without a rebuild:

| Change | How |
|--------|-----|
| Theme | `Super+Shift+G`, or `dotfiles theme set <id>` |
| Keybinds, look, rules | edit `config/hypr/*.lua`, then `dotfiles hypr reload` |
| Machine-only Hyprland tweaks | `config/hypr/local.lua` (gitignored) |
| Your own theme | drop `<id>.json` in `~/.config/dotfiles/themes/`, then `dotfiles theme build` |

Bar widgets: `workspaces`, `windowTitle`, `media`, `clock`, `f1`, `agentUsage`, `tray`, `status`.

## Keybinds

| Keys | Action |
|------|--------|
| `Super+Return` / `B` / `E` / `R` | terminal / browser / files / launcher |
| `Super+Q` | close window |
| `Super+h/j/k/l` | focus; `+Shift` move, `+Alt` resize |
| `Super+1..0` | workspace; `+Shift` move window there |
| `Super+Shift+T` | toggle dwindle / scrolling layout |
| `Super+F` / `V` | fullscreen / float |
| `Super+W` | toggle bar |
| `Super+Shift+G` | theme picker |
| `Super+Ctrl+Space` / `Super+Alt+Space` | wallpaper picker / next wallpaper |
| `Super+Shift+X` | lock |
| `Print`, `Super+Print`, `Super+Shift+Print` | screenshot region / window / monitor |

Full list: [`config/hypr/bindings.lua`](config/hypr/bindings.lua).

## Extend

- **Themes**: add a pack folder under `themes/` (one JSON per theme, optional `order` file). `dotfiles theme build --check` validates them.
- **Hooks**: executables in `config/hooks/post-switch.d/` run after each switch.
- **Migrations**: one-time fixes for existing installs in `scripts/migrations/`.
- **As a flake input**: import `nixosModules.default` and `homeManagerModules.default` into your own flake.

How the pieces fit together: [docs/guide.md](docs/guide.md).

## License

[MIT](LICENSE)
