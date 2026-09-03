pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.bar.components

// Literal layout, named children - deliberately not a config-driven entry
// model. Reordering is a code edit, which for a one-user shell is simpler to
// read than the indirection.
Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: Tokens.padding.medium
        anchors.bottomMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        // --- top: workspaces ------------------------------------------
        Workspaces { Layout.alignment: Qt.AlignHCenter }

        // --- middle: the focused window's icon ------------------------
        ActiveWindow { Layout.alignment: Qt.AlignHCenter }

        Item { Layout.fillHeight: true }   // spacer

        // --- bottom cluster: tray, then status, then clock ------------
        Tray {
            Layout.alignment: Qt.AlignHCenter
            visible: Config.bar.showTray
        }
        StatusIcons { Layout.alignment: Qt.AlignHCenter }
        Clock { Layout.alignment: Qt.AlignHCenter }
        LockButton { Layout.alignment: Qt.AlignHCenter }
    }
}
