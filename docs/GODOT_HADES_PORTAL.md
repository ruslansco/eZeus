# Hades portal menu art

The 10 October 2026 reference calls for living lime-green flames, pale blue-green
depths and a hooded stone guardian. Normal menu scenery now combines four
registered 3D planes: the retained photographic backdrop, procedural portal,
detailed transparent guardian artwork and foreground mist. The stone guardian
stays still while its green eye/rim light, flames, motes and mist move.

The final guardian is generated painted artwork on a depth layer. It is not a
fully sculpted runtime character. An original editable geometry draft remains
outside the runtime directory for later refinement; its first smooth/simple
presentation did not match the photographic scene and is not loaded by the menu.

## Runtime contract

`scripts/cinematic_menu_world.gd` retains the common source-image cover/crop/drift
transform. The aperture remains `(1194,204,268,468)` on the 1672×941 backdrop.
`aegean_portal_distance.png` is unchanged, with its two-channel packed signed
distance, lossless linear-data import and no mipmaps or automatic 3D compression.
The guardian uses source rectangle `(1188,294,240,368)` and clips against that
same aperture. Its RGBA art uses lossless mipmaps; preserve the generated alpha.

- `shaders/hades_portal.gdshader` draws domain-warped rising green flame tongues,
  shifting cyan mist/depths and sparse deterministic upward motes.
- `shaders/hades_guardian_art.gdshader` displays the stationary cutout and applies
  a small animated emission only to its existing green eyes/rim. Feet fade into
  the mist instead of ending with a sharp sticker edge.
- `shaders/hades_portal_mist.gdshader` is the nearer translucent mist layer.

All three materials receive the existing menu `scene_time`; they do not use
Godot's wall-clock `TIME`. Reduced interface motion and fixed review times freeze
them together with scenic drift. No simulation, model/VAT, native RNG, city map,
save, gameplay or menu callback changes are involved. The older
`login_portal.gdshader` and original guardian assets remain available to historical
procedural scenes. Runtime backdrop geometry is eight triangles/four planes.

## Art and editable sources

The built-in image generation tool produced
`assets/menu/hades_guardian_cutout_v1.png` at 1024×1536 RGBA. Its exact prompt,
source/reference hashes and scope are in the adjacent `.prompt.txt` and
`.provenance.json`. The user screenshot provides hood/sword/green-eye motifs;
the generated Greek chiton, mantle, meander borders and leaf-shaped sword are new
art, and the screenshot is not embedded in the scene.

Separate parent-workspace sources:

- `art/menu/hades-portal/hades-portal-menu-v1.blend`: three packed images on three
  registered planes plus a camera. The animated green aperture material is an
  approximate Blender preview; the Godot shaders are authoritative.
- `hades-portal-guardian-v1.blend`: editable original geometry draft, with
  `hades-portal-guardian-draft-v1.glb/.json` retained alongside it. It has four
  surfaces, both UV sets and 15,874 triangles, and needs further geometry/drapery
  refinement before runtime use.

Rebuild only these separate sources using background factory-startup Blender and
`tools/build_hades_portal_reference.py` / `build_hades_portal_guardian.py`. Never
overwrite the older cinematic reference or the interactive port-9876 document.
Provenance records distinguish generated runtime art from the geometry draft;
neither artifact is user visual acceptance or release-rights clearance.

## Review

Run owned visible reviews sequentially with disposable profiles:

```sh
python3 tools/review_main_menu.py --lang en --menu-only --tag hades-menu
python3 tools/review_main_menu.py --lang ru --menu-only --tag hades-menu
python3 tools/review_main_menu.py --lang en --art-only --portal --tag hades-live
python3 tools/review_main_menu.py --lang ru --art-only --portal --tag hades-live
```

The portal review records 24 actual fixed-time GPU frames, compares changing and
held frames, checks layer/geometry budgets and confirms source registration at
1280×720, 1280×800 and 1600×1000 with enlarged UI/text. Captures under the chosen
tag avoid other chats' files. Current validation records results and limits.
