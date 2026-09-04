-- Globals shared across all required modules (no `local` keyword)
mod = "SUPER"

terminal = "alacritty"
fileManager = "nautilus"
menu = "rofi -show drun"

cursorSize = "16"

-- Our own scripts live here. Hyprland (GDM-launched) has a minimal PATH, so
-- binds and autostart entries must reference them absolutely.
binDir = os.getenv("HOME") .. "/.config/bin"
-- quickshell is installed to a user prefix (bin/install-user-prefix), which
-- is not on Hyprland's minimal PATH either.
qsIpc = os.getenv("HOME") .. "/.local/bin/qs -c mg ipc"

-- Border colours come from the generated theme, so a fresh login matches the
-- current wallpaper. retheme also applies them live via `hyprctl eval`; this
-- path only covers config load. Wrapped so a missing file can never error the
-- config - a fresh clone falls back to the old Catppuccin sky.
local function themeColours()
  local state = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
  local f = io.open(state .. "/theme/hypr-colors.conf", "r")
  if not f then return nil end
  local t = {}
  for line in f:lines() do
    local k, v = line:match("^(%w[%w_]*)=(.+)$")
    if k then t[k] = v end
  end
  f:close()
  if t.active_border and t.inactive_border then return t end
  return nil
end

local c = themeColours()
activeBorder   = c and c.active_border   or "rgba(89dcebff)"
inactiveBorder = c and c.inactive_border or "rgba(89dceb76)"
