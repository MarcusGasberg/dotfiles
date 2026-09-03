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
    property string source: ""
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
        root.source = scheme.source ?? "";
        root.wallpaper = scheme.wallpaper ?? "";

        const cols = scheme.colours ?? {};
        for (const key in cols) {
            // background -> background; on_surface_variant -> onSurfaceVariant
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
        path: Quickshell.statePath("scheme.json")
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
        property color onBackground: "#e1e2e8"
        property color surface: "#111318"
        property color onSurface: "#e1e2e8"
        property color surfaceVariant: "#43474e"
        property color onSurfaceVariant: "#c3c6cf"
        property color surfaceDim: "#111318"
        property color surfaceBright: "#37393e"
        property color surfaceContainerLowest: "#0c0e13"
        property color surfaceContainerLow: "#191c20"
        property color surfaceContainer: "#1d2024"
        property color surfaceContainerHigh: "#272a2f"
        property color surfaceContainerHighest: "#32353a"
        property color inverseSurface: "#e1e2e8"
        property color inverseOnSurface: "#2e3035"
        property color primary: "#a4c9fe"
        property color onPrimary: "#00315c"
        property color primaryContainer: "#1f4876"
        property color onPrimaryContainer: "#d3e3ff"
        property color secondary: "#bcc7db"
        property color onSecondary: "#263141"
        property color secondaryContainer: "#3c4858"
        property color onSecondaryContainer: "#d8e3f8"
        property color tertiary: "#d9bde3"
        property color onTertiary: "#3c2947"
        property color tertiaryContainer: "#543f5e"
        property color onTertiaryContainer: "#f6d9ff"
        property color error: "#ffb4ab"
        property color onError: "#690005"
        property color errorContainer: "#93000a"
        property color onErrorContainer: "#ffdad6"
        property color outline: "#8d9199"
        property color outlineVariant: "#43474e"
        property color shadow: "#000000"
        property color scrim: "#000000"
        property color surfaceTint: "#a4c9fe"
    }

    // Only roles that are ever PAINTED AS A BACKGROUND need a T variant.
    component TPalette: QtObject {
        readonly property color surface: root.layer(root.palette.surface, 0)
        readonly property color background: root.layer(root.palette.background, 0)
        readonly property color surfaceContainerLowest: root.layer(root.palette.surfaceContainerLowest, 1)
        readonly property color surfaceContainerLow: root.layer(root.palette.surfaceContainerLow, 1)
        readonly property color surfaceContainer: root.layer(root.palette.surfaceContainer, 1)
        readonly property color surfaceContainerHigh: root.layer(root.palette.surfaceContainerHigh, 2)
        readonly property color surfaceContainerHighest: root.layer(root.palette.surfaceContainerHighest, 2)
        readonly property color primaryContainer: root.layer(root.palette.primaryContainer, 1)
        readonly property color secondaryContainer: root.layer(root.palette.secondaryContainer, 1)
        readonly property color tertiaryContainer: root.layer(root.palette.tertiaryContainer, 1)
        readonly property color errorContainer: root.layer(root.palette.errorContainer, 1)
    }
}
