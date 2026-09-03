pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.components

// Centred overlay. Full-screen surface with a small card, so:
//   * mask + visibleMask keep clicks and compositing to the card only -
//     without them the whole screen is a click target AND Hyprland's layer
//     blur would blur the entire screen.
//   * keyboardFocus is OnDemand, never Exclusive. Exclusive "locks out all
//     other windows", so a QML exception while it is active leaves no
//     keyboard and no way to type the fix.
PanelWindow {
    id: root
    required property ShellScreen modelData
    screen: modelData
    visible: ShellState.launcherOpen

    WlrLayershell.namespace: "mg-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.visible
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    mask: Region { item: card }
    HyprlandWindow.visibleMask: Region { item: card }

    // Dismiss on click outside. HyprlandFocusGrab is the right primitive here:
    // it detects outside clicks without the focus-retention quirk OnDemand can
    // exhibit on its own.
    HyprlandFocusGrab {
        active: root.visible
        windows: [root]
        onCleared: ShellState.closeLauncher()
    }

    // Scrim behind the card.
    Rectangle {
        anchors.fill: parent
        color: Colours.palette.scrim
        opacity: root.visible ? 0.4 : 0
        Behavior on opacity { Anim { type: Anim.FastEffects } }
    }

    LauncherCard {
        id: card
        anchors.centerIn: parent
        onDismiss: ShellState.closeLauncher()
    }
}
