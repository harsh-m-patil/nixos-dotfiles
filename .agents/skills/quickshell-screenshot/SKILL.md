---
name: quickshell-screenshot
description: >-
  Screenshots quickshell bar popups (F1 stats, clock, etc.) forced open in a
  throwaway config copy, so you can see layout changes yourself. Use when
  editing ~/nixos-dotfiles/config/quickshell and you need to verify or inspect
  how a popup or tab renders.
---

# Quickshell screenshots

Popups only show on hover, so `shot.sh` copies the config to `/tmp/qs-shot`, rewrites `BarPopup.wanted` so the popup is always open, tags the trigger component's root item, runs a second `qs` instance for ~14s, and captures it with `grim`. The live daemon and the real config are not touched.

## Steps

1. Run the script with the component whose root item is the popup's `trigger`:

   ```bash
   ~/nixos-dotfiles/.agents/skills/quickshell-screenshot/shot.sh F1Chip.qml /tmp/shot.png "380,40 1100x620"
   ```

   Pass `-e 'sed expr'` (repeatable) to tweak the trigger file in the copy, e.g. to pin a tab. F1 popup:

   ```bash
   shot.sh F1Chip.qml /tmp/shot2.png "380,40 1100x620" \
     -e 's/^    property int page: 0/    property int page: 2/' \
     -e 's/running: popup.wanted \&\& !popup.hovered/running: false/'
   ```

   F1 pages: 0 Weekend, 1 Circuit, 2 Last Race, 3 Standings. The second `-e` stops autoplay from switching tabs.

2. Read the PNG with the Read tool. Any QML errors from the test instance are printed before `saved …`.

**Done when:** the image shows the intended popup and tab and no QML errors were printed.

## Gotchas

- **Stale capture:** if the image shows the wrong tab or popup, the previous test instance was still fading out. Rerun; the script already waits between runs.
- **Geometry:** the F1 popup sits around `380,40 1100x620` on this monitor. Shoot the full screen (omit geometry) first if unsure, then crop.
- **Hover artifacts:** the real cursor can highlight rows under it; ignore or move the mouse.
- **Live reload:** after editing the real config, restart the daemon with `quickshell -d -p ~/nixos-dotfiles/config/quickshell`. `pkill -f "quickshell -d -p"` also kills the shell running it, so start the daemon in a separate command.
