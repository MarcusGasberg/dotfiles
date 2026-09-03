import QtQuick
import qs.services

// Material Symbols Rounded, driven through the font's four variable axes
// rather than by swapping glyphs. `fill` is animatable, which is what gives
// the M3 "fills in on select" motion.
StyledText {
    id: root
    property real fill: 0
    property int weight: 400
    // GRAD compensates optically for light-on-dark: M3 specifies -25 on dark.
    property int grade: Colours.light ? 0 : -25
    property int opsz: 20

    font.family: Tokens.font.icon
    font.pointSize: Tokens.font.size.larger
    font.variableAxes: ({
        "FILL": root.fill, "wght": root.weight,
        "GRAD": root.grade, "opsz": root.opsz
    })

    Behavior on fill { Anim { type: Anim.DefaultEffects } }
}
