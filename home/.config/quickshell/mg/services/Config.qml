pragma Singleton

// User configuration, read from config.json in this directory.
//
// Deliberately READ-ONLY: no writeAdapter(). This file lives in the git repo,
// so a shell that wrote defaults back on startup would dirty the working tree
// on every launch. That was the specific complaint about HyprPanel - its real
// config sat unversioned in ~/.config/hyprpanel. Here the config is versioned,
// diffable, hand-edited, and reloaded on save.
//
// It governs BEHAVIOUR, not layout. Caelestia drives its bar from a JSON entry
// list so users can reorder modules; for a shell with exactly one user that is
// indirection with no payoff, so BarContent.qml names its children literally.

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property alias bar: adapter.bar
    readonly property alias launcher: adapter.launcher
    readonly property alias notifs: adapter.notifs
    readonly property alias appearance: adapter.appearance
    readonly property alias apps: adapter.apps
    readonly property alias services: adapter.services

    FileView {
        path: Qt.resolvedUrl("../config.json").toString().replace("file://", "")
        watchChanges: true
        onFileChanged: reload()
        // Sanctioned by the FileView docs for exactly this case: config that
        // must exist before any window is constructed.
        blockLoading: true

        JsonAdapter {
            id: adapter

            property JsonObject bar: JsonObject {
                property int workspaceCount: 5
                property bool workspaceOccupiedBg: true
                property bool showTray: true
                property int trayMaxVisible: 6
                property bool showDate: true
                property bool twentyFourHour: true
            }

            property JsonObject launcher: JsonObject {
                property string actionPrefix: ">"
                property string calcPrefix: "="
                property string clipPrefix: ";"
                property int maxShown: 8
                property list<string> hiddenApps: []
            }

            property JsonObject notifs: JsonObject {
                property int defaultTimeout: 5000
                property int lowTimeout: 4000
                // 0 = never auto-expire. Critical notifications should not
                // vanish while you are away from the machine.
                property int criticalTimeout: 0
                property int maxPopups: 4
                property int groupWindowMs: 30000
                property int groupThreshold: 3
            }

            property JsonObject appearance: JsonObject {
                property bool transparency: true
                property real transparencyBase: 0.78
                property real transparencyLayers: 0.58
                property bool blur: true
                property bool barXray: true
            }

            property JsonObject apps: JsonObject {
                property list<string> terminal: ["alacritty"]
                property list<string> explorer: ["nautilus"]
                property list<string> audio: ["pavucontrol"]
            }

            property JsonObject services: JsonObject {
                property int volumeStep: 5
                property int brightnessStep: 10
            }
        }
    }
}
