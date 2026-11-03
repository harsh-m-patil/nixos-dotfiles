local palette = hypr_module("palette")
local workspace_anim = hypr_module("workspace_anim")

local apps = hypr_module("settings").apps
local terminal    = apps.terminal
local fileManager = apps.fileManager
local menu        = apps.launcher
local browser     = apps.browser

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- See https://wiki.hypr.land/Configuring/Basics/Binds/
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit"))    -- dwindle only
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs ipc call bar toggle || qs -d"))
-- F1 team themes (quickshell): quick cycle, visual picker, wallpaper within pool (Omarchy-style)
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("qs ipc call theme togglePicker"))
hl.bind(mainMod .. " + CTRL + SPACE", hl.dsp.exec_cmd("qs ipc call theme toggleWallpaperPicker"))
hl.bind(mainMod .. " + ALT + SPACE", hl.dsp.exec_cmd("qs ipc call theme cycleWallpaper"))
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.exec_cmd("hyprlock"))

local function isScrolling()
    return hl.get_config("general.layout") == "scrolling"
end

hl.bind(mainMod .. " + SHIFT + T", function()
    local layout = isScrolling() and "dwindle" or "scrolling"
    hl.config({ general = { layout = layout } })
    workspace_anim.apply(layout == "scrolling")
    hl.notification.create({ text = "Layout: " .. layout, timeout = 1500, color = palette.rgb(palette.colors.iris) })
end)

-- Scrolling layout: column width presets and fitting
hl.bind(mainMod .. " + equal", hl.dsp.layout("colresize +conf"))
hl.bind(mainMod .. " + minus", hl.dsp.layout("colresize -conf"))
hl.bind(mainMod .. " + C",     hl.dsp.layout("fit active"))

-- i3-style vim navigation:
--   mainMod + hjkl                focus
--   mainMod + SHIFT + hjkl        move window
--   mainMod + ALT + hjkl          resize
--   mainMod + CTRL + hjkl         dwindle:   choose where the next window splits
--                                 scrolling: h/l scroll the view, j/k change row (workspace)
--   mainMod + CTRL + SHIFT + j/k  carry the window to the row below/above
local directions = {
    h = { dir = "left",  pre = "l", dx = -40, dy = 0,   scroll = hl.dsp.layout("move -col") },
    j = { dir = "down",  pre = "d", dx = 0,   dy = 40,  scroll = hl.dsp.focus({ workspace = "+1" }) },
    k = { dir = "up",    pre = "u", dx = 0,   dy = -40, scroll = hl.dsp.focus({ workspace = "-1" }) },
    l = { dir = "right", pre = "r", dx = 40,  dy = 0,   scroll = hl.dsp.layout("move +col") },
}
for key, d in pairs(directions) do
    local preselect = hl.dsp.layout("preselect " .. d.pre)
    hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ direction = d.dir }))
    hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ direction = d.dir }))
    hl.bind(mainMod .. " + ALT + " .. key,     hl.dsp.window.resize({ x = d.dx, y = d.dy, relative = true }), { repeating = true })
    hl.bind(mainMod .. " + CTRL + " .. key, function()
        hl.dispatch(isScrolling() and d.scroll or preselect)
    end)
end
hl.bind(mainMod .. " + CTRL + SHIFT + j", hl.dsp.window.move({ workspace = "+1" }))
hl.bind(mainMod .. " + CTRL + SHIFT + k", hl.dsp.window.move({ workspace = "-1" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl s 5%+"),                            { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl s 5%-"),                            { locked = true, repeating = true })

-- Screenshots (hyprshot): copy to clipboard
-- Print               = select region
-- Super + Print       = active window
-- Super + Shift+Print = full monitor
hl.bind("Print",                       hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(mainMod .. " + Print",         hl.dsp.exec_cmd("hyprshot -m window -m active"))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd("hyprshot -m output -m active"))

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
