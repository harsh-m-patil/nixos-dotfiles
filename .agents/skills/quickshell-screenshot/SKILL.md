---
name: quickshell-screenshot
description: >-
  Screenshots quickshell bar popups and the F1 hub forced open in a throwaway
  config copy, so you can see layout changes yourself. Use when editing
  ~/nixos-dotfiles/config/quickshell and you need to verify or inspect how a
  popup, island or hub page renders.
---

# Quickshell screenshots

Both scripts copy the config to `/tmp`, patch the copy so the UI is forced open, run a second `qs` instance for ~16s, capture it with `grim`, and print QML errors from that instance. The live daemon and the real config are not touched.

## F1 hub (expanded F1 island)

```bash
~/nixos-dotfiles/.agents/skills/quickshell-screenshot/hub.sh <page> /tmp/h<page>.png ["x,y WxH"]
```

Pages: 0 Overview, 1 My Team, 2 Results, 3 Standings, 4 Circuit, 5 Season. `hub.sh` sets `F1Hub.open`, `screen` (focused monitor) and `page` in the copy. The default crop `650,0 890x700` frames the hub on the 1920×1080 eDP-1; the island sits under the F1 chip, not centred on screen.

## Bar popups

```bash
~/nixos-dotfiles/.agents/skills/quickshell-screenshot/shot.sh <Trigger.qml> /tmp/shot.png ["x,y WxH"] [-e 'sed expr' ...]
```

The trigger is the component whose root item is the popup's `trigger`. `shot.sh` rewrites `BarPopup.wanted` so only that popup is open. `-e` tweaks the trigger file in the copy (repeatable). It does **not** open the F1 hub; use `hub.sh` for that.

Read the PNG with the Read tool afterwards.

**Done when:** the image shows the intended view and no QML errors were printed.

## Gotchas

- **Blank page = load error.** If a hub page or popup renders empty, a QML error killed that file. Errors that only warn don't stop the screenshot, so read the printed log lines. Seen in practice:
  - `Cannot override FINAL property`: a custom property named like a built-in (`top`, `left`, `width`…). Rename it.
  - `Duplicate property name` / `Property value set multiple times`: usually a scripted edit left an old line behind.
- **Noise:** `IslandClickMask … Cannot read property 'width' of null` is pre-existing in the test instance; `hub.sh` filters it.
- **Nested layouts fill by default.** A `RowLayout`/`ColumnLayout` inside a `ColumnLayout` gets `fillHeight` implicitly; set `Layout.fillHeight: false` on fixed-height rows or they steal space and collapse siblings.
- **Check data before blaming layout.** When a list looks cut off or short, log it: add `console.log("QSDBG", …)` (the scripts print `QSDBG` lines), then remove it. The cache may simply hold fewer rows.
- **Stale capture:** if the image shows the previous state, the earlier instance was still fading out. Rerun.
- **Hover artifacts:** the real cursor can highlight rows or open other islands in the shot; ignore them.
- **Live reload:** after editing the real config, restart the daemon with `quickshell -d -p ~/nixos-dotfiles/config/quickshell`. `pkill -f "quickshell -d -p"` also kills the shell running it, so start the daemon in a separate command.
