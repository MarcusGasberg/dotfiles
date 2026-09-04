pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.components

// The vertical bar's hardest small problem: a horizontal "22:08" does not fit
// in 40px. Rotating the text is unreadable at a glance, so the hours and
// minutes are STACKED instead, which reads naturally and keeps the glyphs
// upright. The date follows the same idea, and can be turned off.
Column {
    id: root
    spacing: 0

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Time.hours
        font.family: Tokens.font.mono
        font.pointSize: Tokens.font.size.larger
        font.variableAxes: ({ "wght": 600 })
        color: Colours.palette.on_surface
    }
    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Time.minutes
        font.family: Tokens.font.mono
        font.pointSize: Tokens.font.size.larger
        font.variableAxes: ({ "wght": 400 })
        color: Colours.palette.on_surface_variant
    }

    Item { width: 1; height: Tokens.spacing.extraSmall; visible: Config.bar.showDate }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: Config.bar.showDate
        text: Time.dayNum
        font.pointSize: Tokens.font.size.small
        color: Colours.palette.outline
    }
    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: Config.bar.showDate
        text: Time.monthName
        font.pointSize: Tokens.font.size.small
        color: Colours.palette.outline
    }
}
