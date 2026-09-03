pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.components

// Popups anchor TOP-RIGHT. The bar owns the left edge, and putting popups
// there would make every entry animation fight the bar's exclusive zone.
PanelWindow {
    id: root
    required property ShellScreen modelData
    screen: modelData

    WlrLayershell.namespace: "mg-notifs"
    // Overlay so notifications appear over fullscreen windows too.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Tokens.sizes.notifWidth + Tokens.padding.large * 2
    color: "transparent"

    // Only the stack is clickable and composited; the rest of this tall
    // surface passes clicks through and is not rendered. Without visibleMask
    // Hyprland's layer blur would also blur the whole empty column.
    mask: Region { item: stack }
    HyprlandWindow.visibleMask: Region { item: stack }

    Column {
        id: stack
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium
        width: Tokens.sizes.notifWidth

        Repeater {
            model: ScriptModel {
                values: Notifs.popups.slice(0, Config.notifs.maxPopups)
            }
            delegate: NotifCard {}
        }

        add: Transition {
            Anim { properties: "opacity,scale"; from: 0; to: 1; type: Anim.DefaultSpatial }
        }
        move: Transition {
            Anim { properties: "y"; type: Anim.Emphasized }
        }
    }
}
