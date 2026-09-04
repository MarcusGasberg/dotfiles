pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.utils
import qs.components

// Mode is chosen by prefix, matching the config: "=" calculate, ">" actions,
// ";" clipboard, otherwise apps.
Column {
    id: root
    property string query: ""
    property int index: 0
    signal dismiss

    readonly property string calcP: Config.launcher.calcPrefix
    readonly property string actP: Config.launcher.actionPrefix
    readonly property string clipP: Config.launcher.clipPrefix

    readonly property string mode:
          query.startsWith(calcP) ? "calc"
        : query.startsWith(actP)  ? "action"
        : query.startsWith(clipP) ? "clip" : "app"
    readonly property string term:
        mode === "app" ? query : query.slice(1).trim()

    readonly property var entries: {
        switch (root.mode) {
        case "calc":   return root.calcResults;
        case "action": return Fuzzy.rank(root.term, root.actions, ["name"]);
        case "clip":   return root.clipResults;
        }
        return Fuzzy.rank(root.term, root.apps, ["name", "genericName"])
                    .slice(0, Config.launcher.maxShown);
    }

    // --- apps -----------------------------------------------------------
    readonly property var apps: {
        const hidden = Config.launcher.hiddenApps;
        return (DesktopEntries.applications?.values ?? [])
            .filter(a => !a.noDisplay && hidden.indexOf(a.id) === -1)
            .map(a => ({
                kind: "app", name: a.name, genericName: a.genericName ?? "",
                icon: a.icon ?? "", entry: a
            }));
    }

    // --- actions --------------------------------------------------------
    readonly property var actions: [
        { kind: "action", name: "Lock",      icon: "lock",        run: () => Quickshell.execDetached(["hyprlock"]) },
        { kind: "action", name: "Logout",    icon: "logout",      run: () => Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.exit()" : "exit") },
        { kind: "action", name: "Reboot",    icon: "restart_alt", run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
        { kind: "action", name: "Shutdown",  icon: "power_settings_new", run: () => Quickshell.execDetached(["systemctl", "poweroff"]) },
        { kind: "action", name: "Suspend",   icon: "bedtime",     run: () => Quickshell.execDetached(["systemctl", "suspend"]) },
        { kind: "action", name: "Random wallpaper", icon: "wallpaper", run: () => Quickshell.execDetached([Quickshell.env("HOME") + "/.config/bin/wallpaper", "--random"]) },
        { kind: "action", name: "Retheme",   icon: "palette",     run: () => Quickshell.execDetached([Quickshell.env("HOME") + "/.config/bin/retheme"]) }
    ]

    // --- calculator (libqalculate) --------------------------------------
    property var calcResults: []
    onTermChanged: if (root.mode === "calc" && root.term !== "") qalc.rerun()

    Process {
        id: qalc
        function rerun(): void {
            running = false;
            command = ["qalc", "-t", "-e", root.term];
            running = true;
        }
        stdout: SplitParser {
            onRead: line => root.calcResults = [{
                kind: "calc", name: line, icon: "calculate", value: line
            }]
        }
    }

    // --- clipboard (cliphist) -------------------------------------------
    property var clipResults: []
    onModeChanged: if (root.mode === "clip") clip.rerun()

    Process {
        id: clip
        property var acc: []
        function rerun(): void { running = false; acc = []; command = ["cliphist", "list"]; running = true; }
        stdout: SplitParser {
            onRead: line => {
                if (clip.acc.length < 50) clip.acc.push(line);
            }
        }
        onExited: root.clipResults = clip.acc
            .filter(l => root.term === "" || Fuzzy.score(root.term, l) >= 0)
            .slice(0, Config.launcher.maxShown)
            .map(l => ({ kind: "clip", name: l.replace(/^\d+\s+/, ""), icon: "content_paste", raw: l }));
    }

    // --- keyboard -------------------------------------------------------
    function move(d: int): void {
        const n = root.entries.length;
        if (n === 0) return;
        root.index = (root.index + d + n) % n;
    }

    function activate(): void {
        const e = root.entries[root.index];
        if (!e) return;
        switch (e.kind) {
        case "app":    e.entry.execute(); break;
        case "action": e.run(); break;
        case "calc":   Quickshell.clipboardText = e.value; break;
        case "clip":   decode.command = ["sh", "-c",
                          "cliphist decode " + JSON.stringify(e.raw.split(/\s+/)[0]) + " | wl-copy"];
                       decode.running = true; break;
        }
        root.dismiss();
    }

    Process { id: decode }

    spacing: Tokens.spacing.extraSmall

    Repeater {
        model: root.entries
        delegate: Item {
            required property var modelData
            required property int index
            width: root.width
            height: Tokens.sizes.launcherItemHeight

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.large
                color: index === root.index
                    ? Colours.t.primary_container : "transparent"
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.medium
                spacing: Tokens.spacing.medium

                Item {
                    width: Tokens.sizes.notifImage - 10
                    height: parent.height
                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 26
                        visible: modelData.kind === "app"
                        source: modelData.kind === "app"
                            ? Quickshell.iconPath(modelData.icon, "application-x-executable") : ""
                        mipmap: true
                    }
                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: modelData.kind !== "app"
                        text: modelData.icon ?? "chevron_right"
                        color: Colours.palette.primary
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    StyledText {
                        text: modelData.name
                        width: root.width - 100
                        elide: Text.ElideRight
                        color: index === root.index
                            ? Colours.palette.on_primary_container : Colours.palette.on_surface
                        font.variableAxes: ({ "wght": index === root.index ? 500 : 400 })
                    }
                    StyledText {
                        visible: (modelData.genericName ?? "") !== ""
                        text: modelData.genericName ?? ""
                        font.pointSize: Tokens.font.size.small
                        color: Colours.palette.outline
                    }
                }
            }

            StateLayer {
                radius: Tokens.rounding.large
                onClicked: { root.index = index; root.activate(); }
            }
        }
    }

    StyledText {
        visible: root.entries.length === 0 && root.query !== ""
        text: "No results"
        color: Colours.palette.outline
        leftPadding: Tokens.padding.medium
        topPadding: Tokens.padding.medium
    }
}
