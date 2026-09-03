pragma ComponentBehavior: Bound
import QtQuick
import qs.services

// NumberAnimation preconfigured with an M3 duration + easing pair. Every
// animation in the shell goes through this or CAnim, so motion is consistent
// and no duration is ever hardcoded.
NumberAnimation {
    id: root
    enum Type {
        StandardSmall, Standard, StandardLarge, StandardExtraLarge,
        EmphasizedSmall, Emphasized, EmphasizedLarge, EmphasizedExtraLarge,
        FastSpatial, DefaultSpatial, SlowSpatial,
        FastEffects, DefaultEffects, SlowEffects
    }
    property int type: Anim.DefaultSpatial

    duration: {
        const d = Tokens.anim.durations;
        switch (root.type) {
        case Anim.FastSpatial: return d.expressiveFastSpatial;
        case Anim.DefaultSpatial: return d.expressiveDefaultSpatial;
        case Anim.SlowSpatial: return d.expressiveSlowSpatial;
        case Anim.FastEffects: return d.expressiveFastEffects;
        case Anim.DefaultEffects: return d.expressiveDefaultEffects;
        case Anim.SlowEffects: return d.expressiveSlowEffects;
        }
        return [d.small, d.normal, d.large, d.extraLarge][root.type % 4];
    }

    easing.type: Easing.Bezier
    easing.bezierCurve: {
        const a = Tokens.anim;
        switch (root.type) {
        case Anim.FastSpatial: return a.expressiveFastSpatial;
        case Anim.DefaultSpatial: return a.expressiveDefaultSpatial;
        case Anim.SlowSpatial: return a.expressiveSlowSpatial;
        case Anim.FastEffects: return a.expressiveFastEffects;
        case Anim.DefaultEffects: return a.expressiveDefaultEffects;
        case Anim.SlowEffects: return a.expressiveSlowEffects;
        }
        return (root.type >= Anim.EmphasizedSmall && root.type <= Anim.EmphasizedExtraLarge)
            ? a.emphasized : a.standard;
    }
}
