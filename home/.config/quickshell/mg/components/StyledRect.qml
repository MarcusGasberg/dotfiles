import QtQuick
import qs.services

Rectangle {
    // Backgrounds must come from Colours.t.* (transparency-adjusted), never
    // from Colours.palette.*. See the palette/t note in Colours.qml.
    color: Colours.t.surfaceContainer
    Behavior on color { CAnim {} }
}
