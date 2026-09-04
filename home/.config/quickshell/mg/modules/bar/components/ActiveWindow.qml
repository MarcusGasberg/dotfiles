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
            // Guarded: iconPath("") yields "?fallback=..." which cannot
            // resolve and logs a warning on every focus change. The two-arg
            // form is still used for real ids so an unknown app degrades to
            // the generic icon rather than a missing-texture placeholder.
            source: root.appId === ""
                ? "" : Quickshell.iconPath(root.appId, "application-x-executable")
            mipmap: true
        }
    }
}
