pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.services
import qs.components

// The focused window, as its icon. A 40px-wide bar cannot show a title, and a
// rotated title is unreadable - so the icon carries the identity and the title
// lives in the tooltip.
Item {
    id: root
    readonly property HyprlandToplevel toplevel: Hyprland.activeToplevel
    readonly property string appId: toplevel?.wayland?.appId ?? ""
    visible: appId !== ""
    implicitWidth: Tokens.sizes.barInnerWidth
    implicitHeight: Tokens.sizes.barInnerWidth

    Pill {
        anchors.fill: parent
        color: Colours.t.surface_container_high

        IconImage {
            anchors.centerIn: parent
            implicitSize: Tokens.sizes.trayIcon + 4
            // Two-arg iconPath: the fallback form cannot produce a
            // missing-texture placeholder for an unknown app.
            source: Quickshell.iconPath(root.appId, "application-x-executable")
            mipmap: true
        }
    }
}
