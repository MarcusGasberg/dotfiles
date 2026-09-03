-- Catch-all FIRST. Hyprland applies the last matching rule, so this must be
-- declared before the specific outputs or it would override them.
--
-- This rule was lost in the hyprlang -> Lua migration, which is why plugging a
-- display into any of this laptop's three USB-C ports currently leaves it
-- unconfigured.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Internal panel. Pinned to @60: `hyprctl monitors all` advertises only
-- 1920x1080@60 and @48, and we never want @48 picked.
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })

-- Docked / projector outputs, carried over from the pre-migration config.
hl.monitor({ output = "DP-1", mode = "1920x1080", position = "auto", scale = 1 })
hl.monitor({ output = "DP-5", mode = "1920x1080", position = "auto", scale = 1, mirror = "eDP-1" })
hl.monitor({ output = "DP-6", mode = "1920x1080", position = "auto", scale = 1 })
