-------------------
---- ENV VARS ----
-------------------
hl.env("XCURSOR_SIZE", cursorSize)
hl.env("HYPRCURSOR_SIZE", cursorSize)

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
  hl.exec_cmd("hyprpanel")
  hl.exec_cmd("hyprpaper")
  -- Re-apply the generated palette once the compositor is up, so a login
  -- always matches the current wallpaper even if the state predates this boot.
  -- --apply-only skips the matugen run, keeping it off the login critical path.
  hl.exec_cmd(binDir .. "/retheme --apply-only")
end)

--------------------------
---- GENERAL SETTINGS ----
--------------------------
hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 20,
    border_size = 2,
    col = {
      active_border = activeBorder,
      inactive_border = inactiveBorder,
    },
    resize_on_border = false,
    allow_tearing = false,
    layout = "dwindle",
  },

  decoration = {
    rounding = 10,
    active_opacity = 1.0,
    inactive_opacity = 0.85,
    blur = {
      enabled = true,
      size = 3,
      passes = 1,
      vibrancy = 0.1696,
    },
  },

  dwindle = {
    preserve_split = true,
  },


  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
    background_color = "rgba(1D1011FF)",
  },

  input = {
    kb_layout = "us,dk",
    kb_options = "caps:swapescape,grp:win_space_toggle",
    follow_mouse = 1,
    sensitivity = 0,
    touchpad = {
      natural_scroll = true,
    },
  },

  device = {
    {
      name = "epic-mouse-v1",
      sensitivity = -0.5,
    },
  },
})

--------------------------
-------- Gestures --------
--------------------------
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({
  fingers = 4,
  direction = "left",
  action = function()
    hl.dsp.window.move({ monitor = "-1" })
  end,
})
hl.gesture({
  fingers = 4,
  direction = "right",
  action = function()
    hl.dsp.window.move({ monitor = "+1" })
  end,
})
