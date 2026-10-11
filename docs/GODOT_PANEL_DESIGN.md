# In-game panel design — 10 October 2026

## Game-menu information hierarchy

The root has six choices: Return to city, Saved games, Settings, City views,
Help and Main menu. Resume is the primary full-width action; the four category
choices form a compact grid, and the confirmed exit sits below a divider.
Subpages have the same title/content/Back order. Settings uses concise category
names; Interface owns language and Gameplay contains only its own options.

Navigation pages never scroll or shrink their text. At the supported 720p and
larger sizes, 52-pixel enamel actions, 18-pixel baseline labels and measured
columns protect complete wording. Detailed forms use quieter slate interiors
and 48-pixel footer actions. Long key lists remain bounded reading areas.
Back/Escape returns one level, dialog dismissal restores opener focus and Tab
wraps within visible controls. Native pause/commands remain held throughout.

This hierarchy is informed by [Xbox Accessibility Guideline 112: UI navigation](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/112):
consistent navigation, predictable focus and layouts that accommodate enlarged
text. This design/reference review does not establish full gamepad, screen-reader,
platform or accessibility conformance; those remain separate acceptance work.


The approved main menu establishes the game's visual language: dark walnut,
aged gold/bronze Greek-key trim, warm ivory carving and blue enamel controls.
In-game panels should carry these materials while leaving the city readable and
preserving the meaning of every native control.

## Panel audit and design roles

| Role | Existing panels | Treatment |
|---|---|---|
| Focused windows | Escape menu, City/Advisor/History/Trade, Mythology, settings and save/load forms | Walnut-and-gold outer frame, ivory serif title, dark blue reading/forms surface, clear primary action |
| Character and campaign focus | Character/hero/god/monster window; briefing, victory, colony and campaign results | Matching wood frame, protected portrait/story areas, native narration and action hierarchy |
| Live inspectors | Buildings/storage/production, houses, army, monsters, overlays, objectives, attention/guide | Slim bronze frame, quiet dark reading surface, compact status colors; preserve map visibility and drafts |
| Persistent HUD | Resources, category dock, time, minimap, journal/urgent chips | Lighter bronze accents and consistent type; keep their current size, native semantics and input pass-through |

The first implementation pass covers the focused window families. Live inspectors
and persistent HUD remain the next design layer, so the city does not become a
wall of oversized ornament.

## Reading and interaction rules

- Decorations stay outside the title, values and full button labels. Small key
  caps and quantity controls keep clean surfaces.
- Use the shared Theme generator and baseline text scaling. Never save a scaled
  runtime Theme or reset a draft to rebuild artwork.
- Use navy/slate for dense data and controls; parchment belongs to story prose.
- Primary actions are brighter blue enamel; secondary actions are quieter. Keep
  existing explicit confirmations for destructive actions.
- Keep established Escape/Back, focus, pause/queue restoration, exact native
  commands and required-decision callbacks. Folding a decision never answers it.
- Large windows fit inside the viewport. Long data lists keep bounded reading
  areas; artwork cannot force an inaccessible footer.
- Bake scalable artwork once; no live 3D viewport or per-frame panel regeneration
  is needed for a decorative frame.

`assets/ui/greek_panel_v1.png` is a new original in-game frame made from the main
menu's materials, with smaller ornament and no crest crowding the content. Its
exact built-in image-generation prompt and provenance are retained alongside it.
Current validation distinguishes visual implementation, native review coverage
and the existing renderer/texture teardown limitations.

The reusable frame uses [Godot's nine-patch StyleBoxTexture](https://docs.godotengine.org/en/stable/classes/class_styleboxtexture.html)
with protected reading insets. Dense City data has a slate ledger inset and
campaign prose reuses the existing aged parchment. Native windows reserve a
separate title band rather than placing text on the gold rail.
