#!/usr/bin/env bash
# render-bar.sh - render the bar's layout + real palette to a PNG, offscreen.
#
# Lets you iterate on bar geometry without quickshell installed and without
# restarting a live shell. It is NOT the shell: no layer surface, no exclusive
# zone, no live services - it verifies geometry, colour application and the
# stacked vertical clock, which parsing alone cannot tell you.
#
# The palette is baked in from the generated scheme.json at render time
# (QML's XMLHttpRequest cannot read local files here).
set -euo pipefail
SCHEME="${1:-$HOME/.local/state/theme/scheme.json}"
OUT="${2:-$HOME/.dotfiles/test/out/bar.png}"
QML=$(command -v qml || echo /usr/lib/qt6/bin/qml)
TMP=$(mktemp /tmp/mg-render-XXXXXX.qml)
trap 'rm -f "$TMP"' EXIT

get() { jq -r --arg k "$1" '.colours[$k] // "#ff00ff"' "$SCHEME"; }

cat > "$TMP" <<EOF
import QtQuick
import QtQuick.Layouts
Window {
    id: win
    width: 220; height: 1080; visible: true
    color: "#05070a"
    readonly property int barInner: 40
    readonly property int barPad: 8
    readonly property int barWidth: barInner + barPad * 2
    readonly property int wsDot: 8
    readonly property int wsCell: 22
    readonly property int rFull: 1000
    readonly property int spSmall: 8
    readonly property int spMedium: 12
    readonly property int padMedium: 12

    readonly property color cSurface:    "$(get surface)"
    readonly property color cContHigh:   "$(get surface_container_high)"
    readonly property color cOnSurface:  "$(get on_surface)"
    readonly property color cOnSurfVar:  "$(get on_surface_variant)"
    readonly property color cOutline:    "$(get outline)"
    readonly property color cOutlineVar: "$(get outline_variant)"
    readonly property color cPrimary:    "$(get primary)"
    readonly property color cOnPrimary:  "$(get on_primary)"
    readonly property color cSecondary:  "$(get secondary)"
    readonly property color cError:      "$(get error)"

    function lay(c, l) {
        if (l === 0) return Qt.alpha(c, 0.78);
        const lum = Math.sqrt(0.299*c.r*c.r + 0.587*c.g*c.g + 0.114*c.b*c.b);
        if (lum <= 0.0001) return Qt.rgba(0.06*l, 0.06*l, 0.07*l, 0.58);
        const s = (lum + 0.3*(1-0.78)) / lum;
        return Qt.rgba(Math.min(1,c.r*s), Math.min(1,c.g*s), Math.min(1,c.b*s), 0.58);
    }

    Rectangle {
        id: bar
        width: win.barWidth; height: parent.height
        color: win.lay(win.cSurface, 0)
        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: win.padMedium
            anchors.bottomMargin: win.padMedium
            spacing: win.spMedium

            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: win.wsCell
                implicitHeight: win.wsCell * 5 + win.spSmall * 4
                Rectangle {
                    width: win.wsCell; height: win.wsCell; radius: win.rFull
                    color: win.cPrimary; y: 1 * (win.wsCell + win.spSmall)
                }
                Column {
                    spacing: win.spSmall
                    Repeater { model: 5
                        delegate: Item {
                            required property int index
                            width: win.wsCell; height: win.wsCell
                            Rectangle {
                                anchors.centerIn: parent
                                width: index === 1 ? win.wsDot * 0.8 : win.wsDot
                                height: width; radius: width/2
                                color: index === 1 ? win.cOnPrimary
                                     : (index === 0 || index === 2) ? win.cOnSurfVar
                                     : win.cOutlineVar
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: win.barInner; implicitHeight: win.barInner
                radius: win.rFull
                color: win.lay(win.cContHigh, 2)
                Rectangle { anchors.centerIn: parent; width: 22; height: 22
                            radius: 4; color: win.cSecondary }
            }

            Item { Layout.fillHeight: true }

            Column {
                Layout.alignment: Qt.AlignHCenter
                spacing: win.spSmall
                Repeater { model: 4
                    delegate: Item {
                        required property int index
                        width: win.barInner; height: win.barInner
                        Rectangle { anchors.centerIn: parent
                            width: 18; height: 18; radius: 3
                            color: index === 3 ? win.cError : win.cOnSurfVar }
                    }
                }
            }

            Column {
                Layout.alignment: Qt.AlignHCenter
                spacing: 0
                Text { anchors.horizontalCenter: parent.horizontalCenter
                       text: "22"; font.pointSize: 15; font.bold: true
                       font.family: "monospace"; color: win.cOnSurface }
                Text { anchors.horizontalCenter: parent.horizontalCenter
                       text: "34"; font.pointSize: 15
                       font.family: "monospace"; color: win.cOnSurfVar }
                Item { width: 1; height: 4 }
                Text { anchors.horizontalCenter: parent.horizontalCenter
                       text: "03"; font.pointSize: 11; color: win.cOutline }
                Text { anchors.horizontalCenter: parent.horizontalCenter
                       text: "Sep"; font.pointSize: 11; color: win.cOutline }
            }

            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: win.barInner; implicitHeight: win.barInner
                Rectangle { anchors.centerIn: parent
                    width: 14; height: 16; radius: 3; color: win.cOutline }
            }
        }
    }

    Timer {
        running: true; interval: 500
        onTriggered: bar.grabToImage(function(r) {
            Qt.exit(r.saveToFile("$OUT") ? 0 : 3);
        })
    }
}
EOF

QT_QPA_PLATFORM=offscreen "$QML" "$TMP"
rc=$?
[ $rc -eq 0 ] && echo "rendered: $OUT" || echo "render failed (rc=$rc)"
exit $rc
