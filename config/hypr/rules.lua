-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- "Smart borders": no border when only one window is on the workspace
hl.window_rule({
    name  = "no-border-wtv1",
    match = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding    = 4,
})
hl.window_rule({
    name  = "no-border-f1",
    match = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding    = 0,
})

hl.window_rule({
    -- Ignore maximize requests from all apps
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.layer_rule({
    name         = "blur-quickshell-bar",
    match        = { namespace = "^quickshell-bar$" },
    blur         = true,
    ignore_alpha = 0.3,
})

hl.layer_rule({
    name         = "blur-quickshell-f1",
    match        = { namespace = "^quickshell-f1$" },
    blur         = true,
    -- Above IslandBackdrop's 0.42 dim, so only the island itself is blurred.
    ignore_alpha = 0.5,
})

hl.window_rule({
    name   = "float-quickshell-sysmon",
    match  = { class = "^org\\.quickshell$", title = "^System Monitor$" },
    float    = true,
    size     = { 1240, 780 },
    center   = true,
    rounding = 10,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})
