-- Globals shared across all required modules (no `local` keyword)
mod = "SUPER"

terminal = "alacritty"
fileManager = "nautilus"
menu = "rofi -show drun"

cursorSize = "16"

-- Our own scripts live here. Hyprland (GDM-launched) has a minimal PATH, so
-- binds and autostart entries must reference them absolutely.
binDir = os.getenv("HOME") .. "/.config/bin"

-- Catppuccin Mocha palette (subset actually referenced)
sky = "rgb(89dceb)"
skyAlpha76 = "rgba(89dceb76)"
