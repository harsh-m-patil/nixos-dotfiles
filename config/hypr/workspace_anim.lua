local M = {}

-- Scrolling mode treats workspaces as rows of a 2D grid, so they slide vertically
function M.apply(scrolling)
    if scrolling then
        -- In and Out share one speed so the two rows move as a single strip
        for _, leaf in ipairs({ "workspaces", "workspacesIn", "workspacesOut" }) do
            hl.animation({ leaf = leaf, enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidevert" })
        end
    else
        hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
        hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
        hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
    end
end

return M
