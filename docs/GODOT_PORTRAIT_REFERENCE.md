# Elder curator: Character-panel reference — 4 October 2026

**One-character candidate, awaiting user visual acceptance.** The user rejected the
previous curled, doll-like portraits and requested more realistic older faces,
hair, eyebrows and beards, confined to the Character panel. Do not interpret this
reference or passing tests as approval to change the catalog or city walkers.

## Identity and visual decisions

An invented 68-year-old curator in the retained Roman-inspired cream tunic, red
clavi and mantle, carrying his catalog and scroll. Age is an art choice in the
portrait manifest, not new native character data. Preserve his native name,
occupation, words and voice. This is a historical-inspired design, not a claim
that facial shape determines Greek or Roman ancestry.

- Mature receding hairline, swept-back salt-and-pepper hair with darker roots.
- Short fitted beard, individual tapered fibers, unobstructed lips, fine moustache.
- Short, full eyebrows with scattered grey hairs, a broad body and tapered outer
  tails. The user rejected the first candidate’s thin, overlong brows.
- Cheekbone definition, hollow cheeks, lower orbital pads, tear troughs, slight
  asymmetric jowls, forehead creases and folds beside the nose.
- Warm muted skin, painted cavity/colour variation, ivory sclera and brown irises.
- No snail-shell coils, corkscrew ropes or opaque hanging beard shell.

The current candidate still uses a static held pose, vertex-painted skin and
procedural microrelief. It is not a scan or a photorealistic texture bake. Blinking,
facial acting, individual per-walker faces, high-resolution skin texture painting
and minimum-hardware profiling remain open. Judge stills in the actual panel;
Blender lighting is only a geometry/groom diagnostic.

## Source and isolation

`tools/godot_curator_portrait.py` owns the one-character sculpt, skin and groom.
`godot_portrait_faces.adapt()` calls it **only for `Curator`**, after removing the
old head accessories from the disposable export. No shared anatomy cache,
identity profile, native sprite atlas, live Blender scene, crowd GLB, physician
benchmark or C++ simulation is edited.

The local anatomical base is the retained Blender Foundation human mesh derivative;
see `art/characters/identities/DESIGN_REFERENCE.md` in the parent workspace.
New sculpt and fiber geometry are original procedural work. No screenshot pixels,
external hair packs or new libraries are used. Upstream provenance remains
`needs_evidence`; this work does not clear the production roadmap's release gate.

The source pair is `build-portraits/walker_curator.{glb,json}` (outside the project; the game ships only
`godot/assets/portraits/walker_curator.png`; since 4 October that file is the painted portrait from
`art/ai_portraits`, and a render of this model goes to `build-portraits/renders`). The renderer
loads it, then duplicates the cached role material and enables
`elder_portrait` **on that private material only**, selected by manifest finish
`elder_portrait_v2`. The city finish and crowd asset remain unchanged. Only this portrait uses full
mesh detail, 1.5× render scale, a softer key light and 2.25-head bust framing;
selecting another role restores the ordinary settings. Missing
portraits still use the existing crowd fallback. Other portrait finishes are intact.

## Anatomy and groom contract

Coordinates are Blender +Y forward, +Z up; 1 unit = 2 metres. Export converts to
Godot once. On this base the mouth is approximately `eye_z - .036`, nose wings
`-.022`, and chin `-.052`. The older statue template assumed a mouth at `-.0485`;
reusing it painted false nostrils on the philtrum and put the moustache below the
mouth. Do not copy those offsets blindly to another base.

Groom roots sample triangle area with barycentric interpolation and a local seeded
NumPy generator. Sampling only mesh vertices caused sparse rows and jagged edges.
11,000 scalp and 10,000 beard fibers follow the surface before their tips separate;
420 moustache and 2,000 brow fibers use smaller radii. Fibers taper and vary in
length, direction and colour; no native random generator is called. Names begin
`Portrait ` to survive export simplification. Name eyebrows `brow hair`, not
`eyebrow`: the legacy material classifier matches ` eye` before hair.

Keep both rest-coordinate UV sets, `CityPalette`, normals, eye framing metadata,
three compatible material surfaces, and no morph clips/skeleton for this held
portrait. The benchmark ceiling is 600,000 exported vertices and 40 MiB (one
on-demand panel specimen, not a crowd budget). Do not apply this budget to walkers.

## Rebuild and verify

From `eZeus/`, run background Blender, leaving the user's live scene alone:

```sh
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python-exit-code 1 -P tools/godot_portrait_export.py -- --asset walker_curator --preview godot/captures/curator-reference --views front,three,side --size 900
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python-exit-code 1 -P tools/godot_portrait_export.py -- --asset walker_curator
python3 tools/render_portraits.py --only walker_curator
python3 tools/validate_curator_portrait.py
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --editor --path godot --import
python3 tools/review_character_panel.py --lang en
python3 tools/review_character_panel.py --lang ru
```

Run visible reviews sequentially. They use only the designated city and temporary
preferences, verify panel behaviour, native state preservation and material
isolation, and capture `godot/captures/character-curator-{en,ru}.png`. Front/side diagnostics come from `--preview`.
GLBs and captures are ignored generated artifacts: retain them locally with the
source and paired manifest, and explicitly account for them when transferring a
reference to another machine. Rebuilding the crowd or baking walker VAT is not
part of this workflow.

For the next character, first select its age, facial proportions, hairline and
occupation cues; create a separate adapter and landmark map. Preview front,
three-quarter, profile and full figure. Check for floating hairs, eye exposure,
painted marks off their anatomical features, and hair/ear intersections. Obtain
visual acceptance of this curator candidate before treating it as the art standard.
