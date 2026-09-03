pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.services

// Quickshell's own docs are candid that SNI is "roughly conforming to the
// kde/freedesktop spec (there is no real spec, we just implemented whatever
// seemed to actually be used)". Two consequences are handled here:
//   * pixmap-only items arrive at whatever size the app sent, often 16-22px,
//     so IconImage gets mipmap: true.
//   * overflow is capped rather than letting the column run off a 1080p screen.
//
// Note for the handover: mg registers as an ADDITIONAL StatusNotifierHost
// (its host name is per-pid), so it shows the same items as HyprPanel while
// both run - a free A/B oracle during development.
Column {
    id: root
    readonly property var items: SystemTray.items?.values ?? []
    readonly property int max: Config.bar.trayMaxVisible
    readonly property int overflow: Math.max(0, items.length - max)
    spacing: Tokens.spacing.small
    visible: items.length > 0

    Repeater {
        model: root.items.slice(0, root.max)
        delegate: TrayItem {}
    }

    // overflow indicator - clicking is not wired to a submenu on purpose:
    // that is a popup surface, and raising the cap is the simpler fix.
    Item {
        visible: root.overflow > 0
        width: Tokens.sizes.barInnerWidth
        height: Tokens.sizes.barInnerWidth
        StyledText {
            anchors.centerIn: parent
            text: "+" + root.overflow
            font.pointSize: Tokens.font.size.small
            color: Colours.palette.outline
        }
    }
}
