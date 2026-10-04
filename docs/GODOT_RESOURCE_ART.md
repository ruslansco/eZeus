# Resource header and original 3D icon art — 3 October 2026

The compact `ResourceRibbon` contains the city name, native treasury/population/
work shortcut and a resource disclosure arrow. The separate `ResourcesPanel` starts
folded below it. Its `ResourceGrid` wraps into balanced rows from
its actual translated/scaled minimum widths; it never scrolls away or filters
zero stocks. Welfare shortcuts remain below the surface. Long titles retain
full tooltips, and stock labels/tooltips retain exact native counts.

`city_header.stock` now observes the 23 individual native resource bits from
sea urchins through silver, plus the existing aggregate food total. Drachmas are
already the treasury, so they are not repeated as a stock item. This includes
all eight foods, grapes, olives, wine, oil, fleece, timber, bronze, marble,
armor, sculptures, orichalcum, black marble, horses, chariots and silver.
These are the native **stored-stock cache**, not deposit quantities or prospective
production. Silver/other types without stored inventory correctly show zero.
Non-giftable resources must not be compared against missing world-gift entries
as if those entries were zero; the independent gift query covers its own subset.
The C++ observation reads the same cache without refresh, tile scans, RNG,
extra polling, economic changes or changes to simulation timing.

`godot/ui/resource_art/resource_models.gd` authors original primitive-mesh art:
food basket, individual foods, wheat heads, amphorae, fleece, timber ends,
metal ingots, veined stone blocks, helmet, bust, horse and spoked chariot.
`godot/scripts/render_resource_icons.gd` saves 24 reusable model scenes under
`ui/resource_art/models/` and 128×128 transparent PNGs using an orthographic
camera and two studio lights. Run it in an owned Metal Godot art preview with
an absolute log path, then import the PNGs. `manifest.json` records model paths,
triangle counts and original procedural provenance. No original commercial or
reference screenshot artwork was extracted; normal repository GPL notices apply.

The largest offline model is the wheat at 7,344 triangles; each is bounded to
8,192. These meshes do not load into the live city or HUD. The interface uses
only their static imported textures (24 RGBA images, about 1.5 MiB uncompressed
before mipmaps); it creates no additional live thumbnail SubViewports, lights,
physics, navigation or simulation entities. Keep the main city asset manifest
and converted building/walker counts separate from this offline UI art.

`tools/review_resource_bar.py --lang en` (or `ru`) uses only the designated save,
scratch preferences and an owned preview. It validates native type completeness,
zero-stock availability, independent giftable stocks, model/texture contracts,
all-item bounds at three resolutions with independent text/UI scaling, real
native overlay clicks, long values/title tooltips and unchanged native state.
It terminates its own child promptly if repeated null-material renderer errors
appear, avoiding another unbounded log. Hardware input is blocked only in the
owned review; tagged test events still follow the real GUI input path.

Actual captures, passing counts and renderer/whole-game limits are recorded in
`GODOT_VALIDATION.md`. UI art acceptance and wider campaign/minimum-Mac profiling
remain pending; this pass does not extend resource rules or clear those gates.

## Foldable resource panel — 3 October 2026

The overview bar contains city, treasury, population and jobs plus a disclosure
arrow immediately after jobs. All 24 stock items now live in a separate panel
below it, folded on every new city launch. The arrow opens/closes a clipped
0.24-second reveal with opacity easing; rapid reversal cancels the previous
tween. Reduce interface motion applies the final state immediately. Welfare,
inspectors and other bounded panels follow the revealed height. Folded space
passes input to the city. Native cached stock updates and resource shortcuts
remain unchanged; no preference writes or extra polling are added.
