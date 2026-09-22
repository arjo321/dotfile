-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = 8,

        border_size = 1,

        col = {
            active_border   = { colors = {"rgba(33ccffee)"}},
            inactive_border = "rgba(595959aa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

    },

    decoration = {
        rounding       = 1,
        rounding_power = 1,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 0.9,
        inactive_opacity = 1,

        shadow = {
            enabled      = true,
            range        = 20,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
            size      = 20,
            passes    = 3,
            vibrancy  = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- ─────────────────────────────────────────────
-- Bézier Curves
-- ─────────────────────────────────────────────
hl.curve("overshot",  { type = "bezier", points = { {0.05, 0.9},   {0.1, 1.05}   } })
hl.curve("smoothOut", { type = "bezier", points = { {0.36, 0},     {0.66, -0.56} } })
hl.curve("smoothIn",  { type = "bezier", points = { {0.25, 1},     {0.5, 1}      } })
hl.curve("fluid",     { type = "bezier", points = { {0.4, 0},      {0.2, 1}      } })
hl.curve("bounce",    { type = "bezier", points = { {0.175, 0.885},{0.32, 1.275} } })
hl.curve("1",         { type = "bezier", points = { {0.5, 0.0},    {0.357, 1.0}  } })
hl.curve("rofiCurve", { type = "bezier", points = { {0.05, 0.9},   {0.1, 1.05}   } })

-- ─────────────────────────────────────────────
-- Window Animations
-- ─────────────────────────────────────────────
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 4.0, bezier = "default", style = "slide" })
-- hl.animation({ leaf = "windowsIn",   enabled = true, speed = 5,   bezier = "overshot", style = "slide" })

hl.animation({ leaf = "windowsOut",  enabled = true, speed = 4.0, bezier = "1",       style = "popin 80%" })
-- hl.animation({ leaf = "windowsOut",  enabled = true, speed = 4,   bezier = "smoothIn", style = "popin 80%" })

hl.animation({ leaf = "windowsMove", enabled = true, speed = 4,   bezier = "fluid" })

-- ─────────────────────────────────────────────
-- Fade Animations
-- ─────────────────────────────────────────────
hl.animation({ leaf = "fade",       enabled = true, speed = 4, bezier = "fluid" })
hl.animation({ leaf = "fadeIn",     enabled = true, speed = 5, bezier = "smoothIn" })
hl.animation({ leaf = "fadeOut",    enabled = true, speed = 4, bezier = "smoothOut" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 5, bezier = "fluid" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 6, bezier = "fluid" })
hl.animation({ leaf = "fadeDim",    enabled = true, speed = 5, bezier = "fluid" })

-- ─────────────────────────────────────────────
-- Border & Decorations
-- ─────────────────────────────────────────────
hl.animation({ leaf = "border",      enabled = true, speed = 10, bezier = "fluid" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "fluid", style = "loop" })

-- ─────────────────────────────────────────────
-- Workspace Transitions
-- ─────────────────────────────────────────────
hl.animation({ leaf = "workspaces",       enabled = true, speed = 5,   bezier = "fluid",  style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 6,   bezier = "bounce", style = "slidevert" })
hl.animation({ leaf = "workspacesIn",     enabled = true, speed = 4.5, bezier = "1",      style = "slide" })
hl.animation({ leaf = "workspacesOut",    enabled = true, speed = 4.5, bezier = "1",      style = "slide" })

-- ─────────────────────────────────────────────
-- Layers Transitions
-- ─────────────────────────────────────────────
hl.animation({ leaf = "layersIn",  enabled = true, speed = 3.5, bezier = "1" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 8.0, bezier = "1" })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
