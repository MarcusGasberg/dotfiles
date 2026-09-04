pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.components

// Volume / network / bluetooth / battery, stacked. Each is a plain glyph with
// a state layer; clicking opens the relevant tool, since a full picker is
// dashboard scope and deliberately out of this shell's remit.
Column {
    id: root
    spacing: Tokens.spacing.small

    component StatusItem: Item {
        id: item
        property string icon: ""
        property color tint: Colours.palette.on_surface_variant
        property bool alert: false
        signal activated
        width: Tokens.sizes.barInnerWidth
        height: Tokens.sizes.barInnerWidth

        MaterialIcon {
            anchors.centerIn: parent
            text: item.icon
            color: item.alert ? Colours.palette.error : item.tint
            fill: item.alert ? 1 : 0
        }
        StateLayer { onClicked: item.activated() }
    }

    StatusItem {
        icon: Audio.icon
        alert: Audio.muted
        onActivated: Audio.toggleMute()
    }

    StatusItem {
        icon: Net.icon
        alert: !Net.connected
        onActivated: Quickshell.execDetached(
            Config.apps.terminal.concat(["-e", "nmtui"]))
    }

    StatusItem {
        icon: Bt.icon
        onActivated: Quickshell.execDetached(
            Config.apps.terminal.concat(["-e", "bluetoothctl"]))
    }

    StatusItem {
        visible: Batt.available
        icon: Batt.icon
        alert: Batt.low
        tint: Batt.charging ? Colours.palette.tertiary : Colours.palette.on_surface_variant
    }
}
