import QtQuick
import qs.services
import qs.components
import Quickshell

// Session seam. Deliberately just a lock button: the session menu, power
// options and the lockscreen itself are out of this shell's scope, and
// hyprlock stays the lock implementation.
Item {
    implicitWidth: Tokens.sizes.barInnerWidth
    implicitHeight: Tokens.sizes.barInnerWidth

    MaterialIcon {
        anchors.centerIn: parent
        text: "lock"
        color: Colours.palette.outline
        font.pointSize: Tokens.font.size.normal
    }
    StateLayer { onClicked: Quickshell.execDetached(["hyprlock"]) }
}
