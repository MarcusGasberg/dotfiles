pragma Singleton
pragma ComponentBehavior: Bound

// The Material 3 palette, read live from the file matugen generates.
//
// Contract with the pipeline (see ~/.dotfiles/home/.config/matugen/):
//   path   $XDG_STATE_HOME/theme/scheme.json
//   shape  { mode, source, wallpaper, colours: { <snake_case_role>: "#rrggbb" } }
//   hex WITH the leading #, so values assign straight to a QML `color`.
//
// The palette/t split is the least obvious idea here and the most important.
// Transparency is not a property of a colour - it is a property of a painted
// surface at a given DEPTH. Applying one alpha to every container gives muddy
// stacked translucency. So:
//     backgrounds read  Colours.t.*     (alpha + luminance lift per layer)
//     text and icons read Colours.palette.*   (fully opaque)
// A component that paints a background with palette.* instead of t.* will look
// subtly wrong rather than obviously broken, so it is worth being strict.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool light: mode === "light"
    property string mode: "dark"
    property string schemeSource: ""
    property string wallpaper: ""

    readonly property Palette palette: Palette {}
    readonly property TPalette t: TPalette {}

    // ---------------------------------------------------------------------
    // Alpha-composite a token for an elevation layer.
    //   layer 0  the window's own surface - gets the full base alpha, and is
    //            what the compositor blurs behind.
    //   layer 1+ containers stacked on top - a LIGHTER alpha plus a luminance
    //            lift, so a raised pill still reads as raised against a
    //            translucent surface rather than dissolving into it.
    function layer(c: color, l: int): color {
        if (!Tokens.transparency.enabled)
            return c;
        if (l === 0)
            return Qt.alpha(c, Tokens.transparency.base);
        return lift(c, Tokens.transparency.layers, l);
    }

    // Perceptual-ish luminance. Weights are the sRGB luma coefficients; the
    // sqrt keeps the lift from blowing out already-bright surfaces.
    function luminance(c: color): real {
        const v = 0.299 * c.r * c.r + 0.587 * c.g * c.g + 0.114 * c.b * c.b;
        return Math.sqrt(v);
    }

    function lift(c: color, a: real, l: int): color {
        const lum = luminance(c);
        if (lum <= 0.0001)
            // Pure black cannot be scaled multiplicatively; nudge additively.
            return Qt.rgba(0.06 * l, 0.06 * l, 0.07 * l, a);
        const dir = (!light || l === 1) ? 1 : -l / 2;
        const off = dir * (light ? 0.2 : 0.3) * (1 - Tokens.transparency.base);
        const s = (lum + off) / lum;
        return Qt.rgba(Math.min(1, c.r * s), Math.min(1, c.g * s), Math.min(1, c.b * s), a);
    }

    // Pick a legible foreground for an arbitrary colour - used for tinting
    // tray icons, whose colours we do not control.
    function on(c: color): color {
        return c.hslLightness < 0.5
            ? Qt.hsla(c.hslHue, c.hslSaturation, 0.92, 1)
            : Qt.hsla(c.hslHue, c.hslSaturation, 0.08, 1);
    }

    // ---------------------------------------------------------------------
    property int retries: 0

    function load(raw: string): void {
        let scheme;
        try {
            scheme = JSON.parse(raw);
        } catch (e) {
            // Almost always a non-atomic write caught mid-flight. matugen
            // should render to .tmp and rename; retry briefly regardless so a
            // torn read never leaves the shell on default colours.
            if (root.retries++ < 3) {
                retryTimer.restart();
            } else {
                console.warn("mg/Colours: scheme.json unparseable, keeping previous palette:", e);
            }
            return;
        }
        root.retries = 0;

        root.mode = scheme.mode ?? "dark";
        root.schemeSource = scheme.source ?? "";
        root.wallpaper = scheme.wallpaper ?? "";

        const cols = scheme.colours ?? {};
        for (const key in cols) {
            // background -> background; on_surface_variant -> on_surface_variant
            const prop = key.replace(/_([a-z])/g, (m, ch) => ch.toUpperCase());
            if (root.palette.hasOwnProperty(prop))
                root.palette[prop] = cols[key];
        }
    }

    // Called by `retheme` over IPC as belt-and-braces. The FileView below
    // already watches the file, so this is a redundant path by design.
    function reloadNow(): void {
        file.reload();
    }

    Timer {
        id: retryTimer
        interval: 50
        onTriggered: file.reload()
    }

    FileView {
        id: file
        // NOT Quickshell.statePath(): that resolves under this shell's own
        // StateDir (~/.local/state/mg), but scheme.json is a CROSS-TOOL
        // contract written by matugen into ~/.local/state/theme alongside the
        // alacritty/tmux/nvim outputs. Pointing at statePath() meant the
        // FileView silently never loaded and the shell ran on the hardcoded
        // defaults below - invisible, because those defaults happen to be the
        // palette of the default wallpaper.
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
              + "/theme/scheme.json"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.load(text())
        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound)
                console.warn("mg/Colours: cannot read scheme.json:", err);
        }
    }

    // Defaults keep the shell renderable before the first scheme lands, and
    // after a failed matugen run. They are the M3 scheme this machine's
    // default wallpaper produces, so first paint is never jarring.
    component Palette: QtObject {
        property color background: "#111318"
        property color on_background: "#e1e2e8"
        property color surface: "#111318"
        property color on_surface: "#e1e2e8"
        property color surface_variant: "#43474e"
        property color on_surface_variant: "#c3c6cf"
        property color surface_dim: "#111318"
        property color surface_bright: "#37393e"
        property color surface_container_lowest: "#0c0e13"
        property color surface_container_low: "#191c20"
        property color surface_container: "#1d2024"
        property color surface_container_high: "#272a2f"
        property color surface_container_highest: "#32353a"
        property color inverse_surface: "#e1e2e8"
        property color inverse_on_surface: "#2e3035"
        property color primary: "#a4c9fe"
        property color on_primary: "#00315c"
        property color primary_container: "#1f4876"
        property color on_primary_container: "#d3e3ff"
        property color secondary: "#bcc7db"
        property color on_secondary: "#263141"
        property color secondary_container: "#3c4858"
        property color on_secondary_container: "#d8e3f8"
        property color tertiary: "#d9bde3"
        property color on_tertiary: "#3c2947"
        property color tertiary_container: "#543f5e"
        property color on_tertiary_container: "#f6d9ff"
        property color error: "#ffb4ab"
        property color on_error: "#690005"
        property color error_container: "#93000a"
        property color on_error_container: "#ffdad6"
        property color outline: "#8d9199"
        property color outline_variant: "#43474e"
        property color shadow: "#000000"
        property color scrim: "#000000"
        property color surface_tint: "#a4c9fe"
    }

    // Only roles that are ever PAINTED AS A BACKGROUND need a T variant.
    component TPalette: QtObject {
        readonly property color surface: root.layer(root.palette.surface, 0)
        readonly property color background: root.layer(root.palette.background, 0)
        readonly property color surface_container_lowest: root.layer(root.palette.surface_container_lowest, 1)
        readonly property color surface_container_low: root.layer(root.palette.surface_container_low, 1)
        readonly property color surface_container: root.layer(root.palette.surface_container, 1)
        readonly property color surface_container_high: root.layer(root.palette.surface_container_high, 2)
        readonly property color surface_container_highest: root.layer(root.palette.surface_container_highest, 2)
        readonly property color primary_container: root.layer(root.palette.primary_container, 1)
        readonly property color secondary_container: root.layer(root.palette.secondary_container, 1)
        readonly property color tertiary_container: root.layer(root.palette.tertiary_container, 1)
        readonly property color error_container: root.layer(root.palette.error_container, 1)
    }
}
