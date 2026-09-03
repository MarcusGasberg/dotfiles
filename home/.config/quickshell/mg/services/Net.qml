pragma Singleton
import Quickshell
import Quickshell.Networking

// Native NetworkManager binding. Caelestia shells out to `nmcli` only because
// Quickshell.Networking did not exist when it was written - there is no need
// for a subprocess layer here.
Singleton {
    id: root
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property var active: Networking.activeConnection ?? null
    readonly property bool connected: active !== null
    readonly property bool isWifi: (active?.type ?? "") === "wifi"
    readonly property int strength: active?.strength ?? 0
    readonly property string name: active?.name ?? "Offline"

    readonly property string icon: {
        if (!connected) return wifiEnabled ? "signal_wifi_off" : "wifi_off";
        if (!isWifi) return "lan";
        if (strength >= 75) return "signal_wifi_4_bar";
        if (strength >= 50) return "network_wifi_3_bar";
        if (strength >= 25) return "network_wifi_2_bar";
        return "network_wifi_1_bar";
    }
}
