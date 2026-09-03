pragma ComponentBehavior: Bound
import QtQuick
import qs.services

// M3 state layer: the hover/press tint that sits over a component without
// changing its own colour. Opacity values are the M3 spec's.
MouseArea {
    id: root
    property color tint: Colours.palette.onSurface
    property real radius: Tokens.rounding.full
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.tint
        opacity: root.pressed ? 0.12 : (root.containsMouse ? 0.08 : 0)
        Behavior on opacity { Anim { type: Anim.FastEffects } }
    }
}
