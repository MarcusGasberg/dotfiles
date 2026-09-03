pragma Singleton

// Material 3 design tokens. These numbers are the M3 expressive spec values,
// which is precisely why this shell needs no compiled plugin: the rounding
// ladder, spacing scale, durations and easing curves are all expressible in
// plain QML.
//
// Nothing in modules/ or components/ may hardcode a radius, a spacing value,
// a duration or a font. `make lint` greps for exactly that.

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property Rounding rounding: Rounding {}
    readonly property Scale spacing: Scale {}
    readonly property Scale padding: Scale {}
    readonly property FontTokens font: FontTokens {}
    readonly property AnimTokens anim: AnimTokens {}
    readonly property Sizes sizes: Sizes {}
    readonly property Transparency transparency: Transparency {}

    component Rounding: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 16
        readonly property int largeIncreased: 20
        readonly property int extraLarge: 28
        readonly property int extraLargeIncreased: 32
        readonly property int extraExtraLarge: 48
        // Any value >= half the smaller dimension gives a full pill.
        readonly property int full: 1000
    }

    component Scale: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 16
        readonly property int largeIncreased: 20
        readonly property int extraLarge: 28
        readonly property int extraLargeIncreased: 32
        readonly property int extraExtraLarge: 48
    }

    // NOTE: inline components must be declared at the top level of the file.
    // Nesting one inside another is a syntax error in QML.
    component FontSizes: QtObject {
        readonly property int small: 11
        readonly property int smaller: 12
        readonly property int normal: 13
        readonly property int larger: 15
        readonly property int large: 18
        readonly property int extraLarge: 28
    }

    component FontTokens: QtObject {
        // Family names, not package names. ttf-cascadia-code-nerd installs
        // "CaskaydiaCove Nerd Font" - getting this wrong fails silently
        // through fontconfig fallback.
        readonly property string sans: "Rubik"
        readonly property string mono: "CaskaydiaCove Nerd Font"
        readonly property string icon: "Material Symbols Rounded"
        readonly property FontSizes size: FontSizes {}
    }

    component Durations: QtObject {
        readonly property int small: 200
        readonly property int normal: 400
        readonly property int large: 600
        readonly property int extraLarge: 1000
        readonly property int expressiveFastSpatial: 350
        readonly property int expressiveDefaultSpatial: 500
        readonly property int expressiveSlowSpatial: 650
        readonly property int expressiveFastEffects: 150
        readonly property int expressiveDefaultEffects: 200
        readonly property int expressiveSlowEffects: 300
    }

    component AnimTokens: QtObject {
        readonly property Durations durations: Durations {}

        // QML easing.bezierCurve takes a flat [c1x,c1y,c2x,c2y,ex,ey, ...]
        // list ending at 1,1. `emphasized` is genuinely TWO cubic segments
        // (12 values) - that is how M3 specifies it, and QEasingCurve
        // supports multi-segment bezier splines.
        readonly property list<real> emphasized: [
            0.05, 0, 0.133333, 0.06, 0.166667, 0.4,
            0.208333, 0.82, 0.25, 1, 1, 1
        ]
        readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
        // The expressive curves deliberately overshoot (control y > 1). That
        // overshoot IS the springy M3 feel; it is not a typo.
        readonly property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.90, 1, 1]
        readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1.00, 1, 1]
        readonly property list<real> expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1]
        readonly property list<real> expressiveFastEffects: [0.31, 0.94, 0.34, 1.00, 1, 1]
        readonly property list<real> expressiveDefaultEffects: [0.34, 0.80, 0.34, 1.00, 1, 1]
        readonly property list<real> expressiveSlowEffects: [0.34, 0.88, 0.34, 1.00, 1, 1]
    }

    component Sizes: QtObject {
        // 1920x1080 laptop: horizontal pixels are the scarce ones, so the bar
        // is deliberately slim. 40 + 2*8 = 56px reserved.
        readonly property int barInnerWidth: 40
        readonly property int barPadding: 8
        readonly property int barWidth: barInnerWidth + barPadding * 2
        readonly property int trayIcon: 18
        readonly property int trayMenuWidth: 280
        readonly property int launcherWidth: 620
        readonly property int launcherItemHeight: 56
        readonly property int notifWidth: 400
        readonly property int notifImage: 42
        readonly property int workspaceDot: 8
        readonly property int workspacePill: 22
    }

    component Transparency: QtObject {
        readonly property bool enabled: Config.appearance.transparency
        readonly property real base: Config.appearance.transparencyBase
        readonly property real layers: Config.appearance.transparencyLayers
    }
}
