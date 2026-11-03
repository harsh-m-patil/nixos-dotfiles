---
name: update-grok-bot
description: >-
  Updates the Grok Bot Nix package in nixos-dotfiles from Cursor's stable
  linux-x64 download URL (prefetch hash, bump version, verify build, rebuild).
  Use when the user asks to update, refresh, or bump grok-bot, Grok Bot, or the
  grok-bot .deb / fetchurl hash in ~/nixos-dotfiles.
---

# Update Grok Bot (NixOS)

## Paths

| Item | Location |
|------|----------|
| Flake | `~/nixos-dotfiles` |
| Package | `~/nixos-dotfiles/packages/grok-bot/default.nix` |
| Update script | `~/nixos-dotfiles/packages/grok-bot/update.sh` |
| Home entry | `~/nixos-dotfiles/hosts/harshmpatil/home.nix` → `callPackage ../../packages/grok-bot { }` |

Default download URL (stable linux-x64):

`https://api2.cursor.sh/updates/download/stable/linux-x64/grok-bot-fb0a830618be0c54`

Redirects to a versioned `.deb` on `downloads.cursor.com`. If the user gives a different API URL, pass it to the script.

## Workflow

```
- [ ] Run update script (or manual prefetch if script fails)
- [ ] Build package
- [ ] Rebuild system (if user wants install applied)
```

### 1. Refresh `default.nix`

```bash
chmod +x ~/nixos-dotfiles/packages/grok-bot/update.sh
~/nixos-dotfiles/packages/grok-bot/update.sh
```

Optional custom URL:

```bash
~/nixos-dotfiles/packages/grok-bot/update.sh 'https://api2.cursor.sh/updates/download/stable/linux-x64/grok-bot-NEWID'
```

**Done when:** `version`, `url`, and `hash` in `default.nix` match the script output.

### 2. Verify build

```bash
cd ~/nixos-dotfiles
nix build --impure --expr '
  with import <nixpkgs> { config.allowUnfree = true; };
  callPackage ./packages/grok-bot {}
' --no-link
```

**Done when:** build exits 0. Do not run `grok-bot` for a version check (starts the GUI and hangs).

### 3. Apply to the system

Only if the user wants the new build installed:

```bash
sudo nixos-rebuild switch --flake ~/nixos-dotfiles#harshmpatil
```

## Manual fallback

If the script cannot run:

```bash
URL='https://api2.cursor.sh/updates/download/stable/linux-x64/grok-bot-fb0a830618be0c54'
curl -fsSIL "$URL" | tr -d '\r' | awk -F': ' '/^location:/ { print $2 }'
nix-prefetch-url "$URL"
nix hash to-sri --type sha256 <base32-from-prefetch>
```

Set `version` from the deb filename (`grok-bot_X.Y.Z_amd64.deb`).

## Constraints

- Package is **unfree**; `allowUnfree` is already set in `hosts/harshmpatil/configuration.nix`.
- Wrapper uses `--no-sandbox` (Electron on NixOS).
- Do not commit large `.deb` files; only `fetchurl` + hash in git.
