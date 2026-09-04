-------------------
---- ENV VARS ----
-------------------
hl.env("XCURSOR_SIZE", cursorSize)
hl.env("HYPRCURSOR_SIZE", cursorSize)

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
  hl.exec_cmd("hyprpaper")
  -- The mg shell. -d detaches, -n refuses to start a second instance.
  -- Absolute path: Hyprland is GDM-launched with PATH=/usr/local/bin:/usr/bin
  -- only, and quickshell is installed to a user prefix (~/.local/bin).
  hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/qs -c mg -d -n")
  -- Clipboard history, for the launcher's ";" mode.
  hl.exec_cmd("wl-paste --watch cliphist store")
  -- ROLLBACK: ags-hyprpanel-git stays installed. To revert, uncomment the
  -- next line, comment out the qs line above, and `hyprctl reload`.
  -- hl.exec_cmd("hyprpanel")
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
------ LAYER RULES -------
--------------------------
-- Blur for the mg shell's surfaces.
--
-- Quickshell's own BackgroundEffect cannot do this: it needs
-- ext-background-effect-v1, which Hyprland does not implement, so it is a
-- silent no-op here. Compositor layer rules are the only route.
--
-- The catch: Hyprland blurs the whole RECTANGULAR layer surface, not the
-- rounded shape painted inside it.
--   * The bar's surface and its painted rect coincide, so plain blur is
--     right. xray makes it blur the wallpaper rather than the windows behind,
--     which reads better for a permanent bar and is cheaper.
--   * The launcher and notifications are full-screen transparent surfaces
--     with a small card floating in them, so naive blur would blur the entire
--     screen. ignore_alpha sits just under the card's base alpha (0.78), so
--     the transparent regions and the scrim fall below the threshold and stay
--     unblurred. These numbers are empirical - retune together.
hl.layer_rule({
  name = "mg-bar-blur",
  match = { namespace = "^mg-bar$" },
  blur = true,
  xray = true,
  ignore_alpha = 0.7,
})

hl.layer_rule({
  name = "mg-panel-blur",
  match = { namespace = "^mg-(launcher|notifs)$" },
  blur = true,
  ignore_alpha = 0.75,
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
