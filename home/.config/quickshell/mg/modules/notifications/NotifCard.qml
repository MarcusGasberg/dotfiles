pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.components

StyledRect {
    id: root
    required property var modelData
    readonly property var n: modelData

    width: Tokens.sizes.notifWidth
    implicitHeight: body.implicitHeight + Tokens.padding.large * 2
    radius: Tokens.rounding.extraLarge
    color: n.critical ? Colours.t.error_container : Colours.t.surface_container
    border.width: n.critical ? 1 : 0
    border.color: Colours.palette.error

    HoverHandler {
        onHoveredChanged: root.n.hovered = hovered
    }

    ColumnLayout {
        id: body
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        // --- header ---------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            IconImage {
                implicitSize: 18
                // Quickshell already falls back to the desktop entry's icon
                // when appIcon is empty, and the two-arg iconPath form cannot
                // yield a missing-texture placeholder.
                source: Quickshell.iconPath(root.n.appIcon, "application-x-executable")
                mipmap: true
            }
            StyledText {
                Layout.fillWidth: true
                text: root.n.appName
                font.pointSize: Tokens.font.size.small
                color: Colours.palette.on_surface_variant
                elide: Text.ElideRight
            }
            StyledText {
                text: Time.ago(root.n.time)
                font.pointSize: Tokens.font.size.small
                color: Colours.palette.outline
            }
            Item {
                // implicit*, not width/height: this Item is managed by the
                // RowLayout above, and setting width/height on a
                // layout-managed item is undefined behaviour.
                implicitWidth: Tokens.sizes.trayIcon
                implicitHeight: Tokens.sizes.trayIcon
                MaterialIcon {
                    anchors.centerIn: parent
                    text: "close"
                    font.pointSize: Tokens.font.size.smaller
                    color: Colours.palette.outline
                }
                StateLayer { onClicked: root.n.close() }
            }
        }

        // --- content --------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            // Big image slot: chat apps send avatars via the image-data hint,
            // which Quickshell exposes as a directly usable image:// URL.
            ClippingRectangle {
                visible: root.n.image !== ""
                implicitWidth: Tokens.sizes.notifImage
                implicitHeight: Tokens.sizes.notifImage
                radius: Tokens.rounding.full
                color: "transparent"
                Image {
                    anchors.fill: parent
                    source: root.n.image
                    fillMode: Image.PreserveAspectCrop
                    mipmap: true
                    asynchronous: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    Layout.fillWidth: true
                    text: root.n.summary
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.variableAxes: ({ "wght": 500 })
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: root.n.body !== ""
                    text: root.n.body
                    color: Colours.palette.on_surface_variant
                    font.pointSize: Tokens.font.size.smaller
                    wrapMode: Text.Wrap
                    // StyledText, NEVER RichText: markup arrives whether or
                    // not we advertise support, so textFormat is the only real
                    // defence against an app's <table> wrecking the layout.
                    textFormat: Text.StyledText
                    maximumLineCount: root.n.expanded ? 20 : 2
                    elide: Text.ElideRight

                    Behavior on maximumLineCount { Anim { type: Anim.Emphasized } }
                }
            }
        }

        // --- actions --------------------------------------------------
        Flow {
            Layout.fillWidth: true
            visible: root.n.actions.length > 0
            spacing: Tokens.spacing.small

            Repeater {
                model: root.n.actions.slice(0, 3)
                delegate: StyledRect {
                    required property var modelData
                    required property int index
                    radius: Tokens.rounding.full
                    color: Colours.t.secondary_container
                    implicitWidth: label.implicitWidth + Tokens.padding.large
                    implicitHeight: label.implicitHeight + Tokens.padding.small

                    StyledText {
                        id: label
                        anchors.centerIn: parent
                        // hasActionIcons means `identifier` is an icon name
                        // rather than a label; without this branch you render
                        // raw icon names as button text.
                        text: modelData.text || modelData.identifier
                        font.pointSize: Tokens.font.size.small
                        color: Colours.palette.on_secondary_container
                    }
                    StateLayer {
                        radius: Tokens.rounding.full
                        onClicked: { root.n.invoke(index); root.n.close(); }
                    }
                }
            }
        }
    }

    // Click the body to expand/collapse a long message.
    StateLayer {
        radius: root.radius
        onClicked: root.n.expanded = !root.n.expanded
        z: -1
    }
}
