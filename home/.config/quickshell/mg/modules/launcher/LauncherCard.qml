pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components

StyledRect {
    id: root
    signal dismiss

    color: Colours.t.surface_container
    radius: Tokens.rounding.extraLarge
    implicitWidth: Tokens.sizes.launcherWidth
    implicitHeight: content.implicitHeight + Tokens.padding.large * 2

    border.width: Tokens.sizes.hairline
    border.color: Colours.palette.outline_variant

    // Reset every time it opens, so it never reopens mid-query.
    onVisibleChanged: if (visible) { search.text = ""; results.index = 0; }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: results.mode === "calc" ? "calculate"
                    : results.mode === "action" ? "bolt"
                    : results.mode === "clip" ? "content_paste" : "search"
                color: Colours.palette.primary
                font.pointSize: Tokens.font.size.large
            }

            TextInput {
                id: search
                Layout.fillWidth: true
                focus: true
                color: Colours.palette.on_surface
                font.family: Tokens.font.sans
                font.pointSize: Tokens.font.size.larger
                selectionColor: Colours.palette.primary_container
                selectedTextColor: Colours.palette.on_primary_container
                onTextChanged: results.index = 0

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: search.text === ""
                    text: "Search apps, = calculate, > actions, ; clipboard"
                    color: Colours.palette.outline
                    font.pointSize: Tokens.font.size.larger
                }

                Keys.onEscapePressed: root.dismiss()
                Keys.onDownPressed: results.move(1)
                Keys.onUpPressed: results.move(-1)
                Keys.onReturnPressed: results.activate()
                Keys.onEnterPressed: results.activate()
                Keys.onTabPressed: results.move(1)
            }
        }

        ResultList {
            id: results
            Layout.fillWidth: true
            query: search.text
            onDismiss: root.dismiss()
        }
    }
}
