import QtQuick
import qs.services

Text {
    // PlainText by default: notification bodies are the only place markup is
    // wanted, and they opt in explicitly with StyledText (never RichText).
    textFormat: Text.PlainText
    renderType: Text.NativeRendering
    color: Colours.palette.onSurface
    font.family: Tokens.font.sans
    font.pointSize: Tokens.font.size.normal
    font.variableAxes: ({ "wght": 400 })
    Behavior on color { CAnim {} }
}
