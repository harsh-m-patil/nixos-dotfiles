local palette = hypr_module("palette")
local rp, rgb = palette.colors, palette.rgb

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = 10,

        border_size = 1,

        col = {
            active_border   = { colors = { rgb(rp.iris), rgb(rp.foam) }, angle = 45 },
            inactive_border = rgb(rp.highlight_med),
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 5,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = rgb(rp.base, "ee"),
        },

        blur = {
            enabled   = true,
            size      = 3,
            passes    = 1,
            vibrancy  = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    group = {
        col = {
            border_active          = { colors = { rgb(rp.iris), rgb(rp.foam) }, angle = 45 },
            border_inactive        = rgb(rp.highlight_med),
            border_locked_active   = rgb(rp.gold),
            border_locked_inactive = rgb(rp.muted),
        },
        groupbar = {
            col = {
                active          = rgb(rp.iris),
                inactive        = rgb(rp.overlay),
                locked_active   = rgb(rp.gold),
                locked_inactive = rgb(rp.highlight_med),
            },
            text_color          = rgb(rp.base),
            text_color_inactive = rgb(rp.text),
        },
    },

    misc = {
        background_color = rgb(rp.base),
        col = { splash = rgb(rp.subtle) },
        force_default_wallpaper  = -1,   -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo    = true, -- Disable the random hyprland logo / anime girl background
        disable_splash_rendering = true, -- Disable the splash text drawn on startup
    },

    -- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
    dwindle = {
        force_split                  = 1,     -- new window goes on the left side of the split
        split_width_multiplier       = 100,   -- always split side by side, never top/bottom
        preserve_split               = true,  -- split direction doesn't flip on resize
        smart_split                  = false,
        permanent_direction_override = false, -- Super+Ctrl+hjkl preselect only applies to the next window
    },

    -- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
    master = {
        new_status = "master",
    },

    -- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- Default springs
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })
hypr_module("workspace_anim").apply(false)
