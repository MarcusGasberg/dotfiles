pragma Singleton
import QtQuick
import Quickshell

// ONE clock for the whole shell. A Timer per widget is the classic way a bar
// ends up burning measurable CPU at idle on a laptop.
Singleton {
    id: root
    readonly property date now: clock.date

    readonly property string time: Qt.formatDateTime(now,
        Config.bar.twentyFourHour ? "HH:mm" : "hh:mm")
    readonly property string hours: Qt.formatDateTime(now,
        Config.bar.twentyFourHour ? "HH" : "hh")
    readonly property string minutes: Qt.formatDateTime(now, "mm")
    readonly property string dayName: Qt.formatDateTime(now, "ddd")
    readonly property string dayNum: Qt.formatDateTime(now, "dd")
    readonly property string monthName: Qt.formatDateTime(now, "MMM")

    // Relative age, for notification timestamps.
    function ago(d: date): string {
        const s = Math.floor((root.now.getTime() - d.getTime()) / 1000);
        if (s < 60) return "now";
        if (s < 3600) return Math.floor(s / 60) + "m";
        if (s < 86400) return Math.floor(s / 3600) + "h";
        return Math.floor(s / 86400) + "d";
    }

    SystemClock {
        id: clock
        // Minute precision: the bar shows HH:mm, so ticking per second would
        // wake the process 60x more often for no visible change.
        precision: SystemClock.Minutes
    }
}
