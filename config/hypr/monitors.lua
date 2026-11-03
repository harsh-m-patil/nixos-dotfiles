-- Monitor defaults. The Quickshell display panel can change mode, scale, and
-- arrangement at runtime; these apply after a Hyprland restart.
-- The default scale comes from dotfiles.settings.monitor.scale.

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = hypr_module("settings").monitor.scale,
})

-- For a display that needs a fixed position or scale, add a rule to
-- config/hypr/local.lua. Use `hyprctl monitors all` to find output names.
-- Examples:
-- hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = 1.25 })
-- hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.5 })
