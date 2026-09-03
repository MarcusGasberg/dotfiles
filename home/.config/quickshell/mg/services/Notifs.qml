pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// The notification server, plus history and do-not-disturb.
//
// On the handover from HyprPanel: NotificationServer registers the D-Bus
// OBJECT PATH unconditionally and the NAME opportunistically, with a
// QDBusServiceWatcher armed BEFORE the first attempt, and it never passes
// REPLACE_EXISTING. So it cannot steal the name, and it re-acquires
// automatically the instant the incumbent releases it. Therefore: start mg
// FIRST, then `hyprpanel -q`. The log line "Could not register notification
// server... presumably because one is already registered" is SUCCESS - it
// means the deferred-registration watcher is armed.
//
// A bug here is SILENT: the server accepts a notification, marks it
// delivered, and nothing appears. That is why every notification is appended
// to an audit log regardless of whether the UI renders it.
Singleton {
    id: root

    property list<var> items: []
    readonly property var popups: root.items.filter(i => i.popup)
    property bool loaded: false
    readonly property alias dnd: persist.dnd

    NotificationServer {
        id: server
        // keepOnReload false, or every QML save re-pops every open notification.
        keepOnReload: false
        // Capabilities default conservative; opt in explicitly.
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: false
        bodyHyperlinksSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            const item = itemComp.createObject(root, {
                notification: n,
                time: new Date(),
                popup: !persist.dnd
            });
            root.items = [item, ...root.items];
            root.audit(n);
        }
    }

    // Append-only record of everything the SERVER received, independent of
    // what the UI drew. The only way to notice a renderer that silently drops
    // notifications is to compare this against what you actually saw.
    function audit(n: var): void {
        const line = [new Date().toISOString(), n.appName || "?", n.summary || ""]
            .join(" | ").replace(/\n/g, " ");
        auditProc.command = ["sh", "-c",
            "printf '%s\\n' " + JSON.stringify(line) +
            " >> \"${XDG_STATE_HOME:-$HOME/.local/state}/mg/notif-audit.log\""];
        auditProc.running = true;
    }
    Process { id: auditProc }

    function dismissAll(): void {
        for (const i of root.items.slice()) i.close();
    }

    PersistentProperties {
        id: persist
        reloadableId: "mg-notifs"
        // Survives a QML reload but NOT a restart, deliberately: waking up
        // silently muted after a reboot is its own bug.
        property bool dnd: false
    }

    IpcHandler {
        target: "notifs"
        function toggleDnd(): void { persist.dnd = !persist.dnd; }
        function isDnd(): bool { return persist.dnd; }
        function clear(): void { root.dismissAll(); }
        function count(): int { return root.items.length; }
    }

    Component { id: itemComp; NotifItem {} }
}
