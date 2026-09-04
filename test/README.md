# test/

Verification that works **without quickshell installed**.

## `render-bar.sh`

Renders the bar's geometry and the real generated palette to `out/bar.png`,
offscreen. Use it to iterate on layout without restarting a live shell.

    ./render-bar.sh [scheme.json] [out.png]

It is **not** the shell: no layer surface, no exclusive zone, no live
services. What it does verify is geometry, colour application and the stacked
vertical clock — none of which parsing can tell you. The palette is baked in
from `scheme.json` at render time because QML's `XMLHttpRequest` cannot read
local files here. The grab preserves alpha, so the background appears over
whatever your viewer composites with; in the real shell that is compositor
blur over the wallpaper.

## `../bin/qml-lint`

Parse plus design-discipline gates: no hardcoded colour, dimension or font in
`modules/`/`components/`, no `width`/`height` on layout-managed items, and
`pragma ComponentBehavior: Bound` on every file containing a delegate.

Both caught real bugs while the shell was being written — nested inline
components (which QML forbids outright), a literal `spacing: 2`, and
`width`/`height` on an item inside a `RowLayout`.
