-- Entry point: loads the modules in this directory in order.
-- Put untracked per-machine tweaks in local.lua; it is loaded last if present.

local config_source = debug.getinfo(1, "S").source
local config_dir = config_source:match("^@(.*/)")
    or ((os.getenv("HOME") or "") .. "/.config/hypr/")

-- dofile (not require) so every Hyprland reload re-reads edited modules.
function hypr_module(name)
    return dofile(config_dir .. name .. ".lua")
end

local function optional_module(name)
    local path = config_dir .. name .. ".lua"
    local f = io.open(path, "r")
    if f then
        f:close()
        return dofile(path)
    end
end

hypr_module("monitors")
hypr_module("env")
hypr_module("autostart")
hypr_module("looknfeel")
hypr_module("input")
hypr_module("bindings")
hypr_module("rules")
optional_module("local")
