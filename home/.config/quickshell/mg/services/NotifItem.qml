pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Notifications
import qs.services

// Fields are COPIED out of the Notification, which is owned by the server and
// destroyed when the notification closes - a history that referenced it would
// read null after the first dismissal.
QtObject {
    id: root
    property Notification notification: null
    property date time: new Date()
    property bool popup: false
    property bool expanded: false
    property bool hovered: false

    readonly property string summary: notification?.summary ?? ""
    readonly property string body: notification?.body ?? ""
    readonly property string appName: notification?.appName ?? ""
    readonly property string appIcon: notification?.appIcon ?? ""
    readonly property string image: notification?.image ?? ""
    readonly property int urgency: notification?.urgency ?? NotificationUrgency.Normal
    readonly property bool critical: urgency === NotificationUrgency.Critical
    readonly property var actions: notification?.actions ?? []

    readonly property int timeout: {
        const c = Config.notifs;
        const own = root.notification?.expireTimeout ?? 0;
        if (own > 0) return own * 1000;
        if (root.critical) return c.criticalTimeout;
        if (root.urgency === NotificationUrgency.Low) return c.lowTimeout;
        return c.defaultTimeout;
    }

    // Pausing the countdown while the pointer is over the card is the single
    // most-missed behaviour in hand-rolled notification daemons, and it costs
    // one binding.
    readonly property Timer expiry: Timer {
        running: root.popup && root.timeout > 0 && !root.hovered
        interval: root.timeout
        onTriggered: root.popup = false
    }

    function invoke(i: int): void {
        const a = root.notification?.actions?.[i];
        if (a) a.invoke();
    }
    function close(): void {
        root.popup = false;
        if (root.notification) root.notification.dismiss();
        Notifs.items = Notifs.items.filter(x => x !== root);
    }
}
