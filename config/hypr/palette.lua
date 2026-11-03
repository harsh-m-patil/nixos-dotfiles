-- Theme palette written by apply-theme.sh to ~/.local/state/quickshell/hypr-colors.lua.
-- Falls back to Rosé Pine when the state file is missing or broken.

local M = {}

local fallback = {
    base           = "191724",
    surface        = "1f1d2e",
    overlay        = "26233a",
    muted          = "6e6a86",
    subtle         = "908caa",
    text           = "e0def4",
    love           = "eb6f92",
    gold           = "f6c177",
    rose           = "ebbcba",
    pine           = "31748f",
    foam           = "9ccfd8",
    iris           = "c4a7e7",
    highlight_low  = "2a283e",
    highlight_med  = "403d52",
    highlight_high = "524f67",
}

local function load()
    local path = (os.getenv("HOME") or "") .. "/.local/state/quickshell/hypr-colors.lua"
    local chunk = loadfile(path)
    if chunk then
        local ok, t = pcall(chunk)
        if ok and type(t) == "table" then
            return t
        end
    end
    return fallback
end

M.colors = load()

function M.rgb(hex, alpha)
    return alpha and ("rgba(" .. hex .. alpha .. ")") or ("rgb(" .. hex .. ")")
end

return M
