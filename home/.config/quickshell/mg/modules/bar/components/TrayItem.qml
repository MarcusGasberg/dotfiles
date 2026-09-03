pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.services
import qs.components

Item {
    id: root
    required property SystemTrayItem modelData
    width: Tokens.sizes.barInnerWidth
    height: Tokens.sizes.barInnerWidth
    visible: modelData?.status !== Status.Passive

    IconImage {
        anchors.centerIn: parent
        implicitSize: Tokens.sizes.trayIcon
        source: root.modelData?.icon ?? ""
        // Pixmaps often arrive smaller than we draw them; mipmap keeps the
        // downscale from looking gritty.
        mipmap: true
    }

    StateLayer {
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: mouse => {
            const item = root.modelData;
            if (!item) return;
            if (mouse.button === Qt.LeftButton) {
                // onlyMenu items have no activate action at all.
                if (item.onlyMenu) root.showMenu();
                else item.activate();
            } else if (mouse.button === Qt.MiddleButton) {
                item.secondaryActivate();
            } else {
                root.showMenu();
            }
        }
    }

    // Platform menu fallback. It looks out of place next to the rest of the
    // shell, but it always works - which matters, because DBusMenu is the
    // flakiest corner of SNI and one stubborn app should not block the bar.
    function showMenu(): void {
        if (modelData?.hasMenu)
            modelData.display(QsWindow.window, width, height / 2);
    }

    WheelHandler {
        onWheel: event => root.modelData?.scroll(event.angleDelta.y, false)
    }
}
