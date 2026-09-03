pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

// Fixed vertical bar on the left edge, with a reserved exclusive zone.
// No auto-hide, no hover-to-expand: windows tile beside it and nothing ever
// overlaps.
//
// exclusiveZone needs exactly 1 or 3 anchors. left+top+bottom gives
// hasHEdge = (left XOR right) = true, hasVEdge = (top XOR bottom) = false,
// which resolves to LeftEdge. Anchoring both top and bottom also makes the
// height the screen height for free.
PanelWindow {
    id: root
    required property ShellScreen modelData
    screen: modelData

    WlrLayershell.namespace: "mg-bar"
    WlrLayershell.layer: WlrLayer.Top
    // None, not OnDemand: the bar never wants the keyboard, and OnDemand is
    // documented to sometimes retain focus over other windows.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { left: true; top: true; bottom: true }
    implicitWidth: Tokens.sizes.barWidth
    exclusiveZone: Tokens.sizes.barWidth
    color: "transparent"

    StyledRect {
        anchors.fill: parent
        color: Colours.t.surface
        radius: 0
        BarContent { anchors.fill: parent }
    }
}
