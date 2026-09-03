pragma Singleton
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root
    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool available: device?.isLaptopBattery ?? false
    readonly property real percent: (device?.percentage ?? 0) * 100
    readonly property bool charging: (device?.state ?? 0) === UPowerDeviceState.Charging
    readonly property bool full: (device?.state ?? 0) === UPowerDeviceState.FullyCharged
    readonly property bool low: available && !charging && percent <= 15
    readonly property bool critical: available && !charging && percent <= 5

    // Material Symbols has discrete battery glyphs; pick by decile.
    readonly property string icon: {
        if (!available) return "power";
        if (charging) return "battery_charging_full";
        if (full || percent >= 95) return "battery_full";
        const steps = ["battery_alert", "battery_1_bar", "battery_2_bar",
                       "battery_3_bar", "battery_4_bar", "battery_5_bar",
                       "battery_6_bar"];
        return steps[Math.min(steps.length - 1, Math.floor(percent / 100 * steps.length))];
    }
}
