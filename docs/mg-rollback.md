# Rolling back the mg shell

`mg` replaced HyprPanel as the bar, launcher and notification daemon.
`ags-hyprpanel-git` is deliberately still installed.

## Instant, one keypress

    SUPER + SHIFT + ESCAPE      →  ~/.config/bin/mg-panic

Kills `mg`, waits for D-Bus to process the name release, restarts HyprPanel.
Tested live: `reserved` goes from `56 0 0 0` back to `0 47 0 0` and bus
ownership transfers. The `sleep 0.3` is load-bearing — starting HyprPanel
before D-Bus has processed `mg`'s ReleaseName leaves both deferring and
nobody serving notifications.

## Permanent

In `home/.config/hypr/settings.lua`, uncomment the `hyprpanel` line in the
autostart block, comment out the `qs -c mg -d -n` line, then `hyprctl reload`.
The rollback line is left in place, commented, for exactly this.

Rebind `SUPER+R` back to `rofi -show drun` in `binds.lua` — rofi is still
installed and its config still works.

## Why the handover order matters

Quickshell's `NotificationServer` registers the D-Bus *object path*
unconditionally but the *name* opportunistically, with a watcher armed
before the first attempt, and never passes `REPLACE_EXISTING`. So it cannot
steal the name and re-acquires the moment the incumbent releases it.

**Start `mg` first, then stop HyprPanel.** The reverse leaves a window with
no daemon. The log line

    Could not register notification server at org.freedesktop.Notifications,
    presumably because one is already registered.

is SUCCESS — it means the watcher is armed.

## Tray icons after a handover

Electron apps (Discord, Slack, Element) register their StatusNotifierItem
with whichever watcher owns the name at *their* startup and never retry, so
their icons vanish when the watcher changes. Restart those apps once. This
is not a bug in `mg`.

## Verifying notifications actually render

A broken notification renderer fails *silently* — the server accepts the
notification, marks it delivered, and nothing appears. `mg` therefore appends
every notification the server receives to

    ~/.local/state/mg/notif-audit.log

independent of what the UI drew. Compare it against what you actually saw.
