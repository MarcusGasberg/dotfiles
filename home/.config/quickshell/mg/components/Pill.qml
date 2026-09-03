import QtQuick
import qs.services

// The bar's recurring rounded container. Caelestia's bar uses plain
// Rectangle.radius for exactly this - no squircle plugin required. At these
// sizes an arc and a superellipse are indistinguishable.
StyledRect {
    radius: Tokens.rounding.full
    implicitWidth: Tokens.sizes.barInnerWidth
    implicitHeight: Tokens.sizes.barInnerWidth
}
