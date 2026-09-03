pragma Singleton
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root
    readonly property var adapter: Bluetooth.defaultAdapter ?? null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var connectedDevices:
        (Bluetooth.devices?.values ?? []).filter(d => d.connected)
    readonly property int connectedCount: connectedDevices.length
    readonly property string icon: !enabled ? "bluetooth_disabled"
        : (connectedCount > 0 ? "bluetooth_connected" : "bluetooth")
}
