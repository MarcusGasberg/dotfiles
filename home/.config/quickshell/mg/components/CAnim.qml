import QtQuick
import qs.services

// Colour transition. Every themed surface carries one of these, which is why
// a wallpaper change animates instead of snapping.
ColorAnimation {
    duration: Tokens.anim.durations.normal
    easing.type: Easing.Bezier
    easing.bezierCurve: Tokens.anim.standard
}
