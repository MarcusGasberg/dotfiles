pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.components

// Fixed-count workspace indicators with a single morphing pill that slides to
// the focused one. One pill that MOVES, rather than per-dot highlighting, is
// what makes the transition read as motion instead of a flicker.
Item {
    id: root
    readonly property int count: Config.bar.workspaceCount
    readonly property int spacingPx: Tokens.spacing.small
    readonly property int dot: Tokens.sizes.workspaceDot
    readonly property int cell: Tokens.sizes.workspacePill

    // Hyprland numbers workspaces globally; map to a 1..count strip.
    readonly property int focused: {
        const id = Hyprland.focusedWorkspace?.id ?? 1;
        return Math.max(1, Math.min(root.count, id));
    }

    implicitWidth: root.cell
    implicitHeight: root.cell * root.count + root.spacingPx * (root.count - 1)

    // occupancy, so you can see where windows are without switching
    function occupied(i: int): bool {
        const ws = Hyprland.workspaces?.values ?? [];
        for (const w of ws)
            if (w.id === i && (w.toplevels?.values?.length ?? 0) > 0)
                return true;
        return false;
    }

    // the moving pill
    StyledRect {
        id: pill
        width: root.cell
        height: root.cell
        radius: Tokens.rounding.full
        color: Colours.palette.primary
        y: (root.focused - 1) * (root.cell + root.spacingPx)
        Behavior on y { Anim { type: Anim.DefaultSpatial } }
    }

    Column {
        spacing: root.spacingPx
        Repeater {
            model: root.count
            delegate: Item {
                required property int index
                width: root.cell
                height: root.cell

                readonly property int wsId: index + 1
                readonly property bool isFocused: wsId === root.focused
                readonly property bool isOccupied: root.occupied(wsId)

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.isFocused ? root.dot * 0.8 : root.dot
                    height: width
                    radius: width / 2
                    color: parent.isFocused ? Colours.palette.on_primary
                        : (parent.isOccupied ? Colours.palette.on_surface_variant
                                             : Colours.palette.outline_variant)
                    Behavior on width { Anim { type: Anim.FastEffects } }
                    Behavior on color { CAnim {} }
                }

                StateLayer {
                    radius: Tokens.rounding.full
                    // Hyprland 0.55 uses a Lua config, and Hyprland.usingLua
                    // exists precisely because the dispatch payload differs:
                    // it must be a Lua EXPRESSION, not "workspace 3".
                    onClicked: Hyprland.dispatch(
                        Hyprland.usingLua
                            ? `hl.dsp.focus({ workspace = "${parent.wsId}" })`
                            : `workspace ${parent.wsId}`)
                }
            }
        }
    }

    // scroll anywhere on the strip to step workspaces
    WheelHandler {
        onWheel: event => {
            const dir = event.angleDelta.y > 0 ? -1 : 1;
            const target = Math.max(1, Math.min(root.count, root.focused + dir));
            if (target !== root.focused)
                Hyprland.dispatch(Hyprland.usingLua
                    ? `hl.dsp.focus({ workspace = "${target}" })`
                    : `workspace ${target}`);
        }
    }
}
