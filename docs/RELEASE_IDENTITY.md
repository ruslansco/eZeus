# Independent release direction — 7 October 2026

## Confirmed by the user

The intended Steam product is an independently branded ancient city-builder.
The licensed Zeus/Poseidon remake route is not the chosen direction. A final
product name, price, release date and supported shipping platforms are not yet
approved by this decision.

The user plans to create campaigns based on existing ones, including modifying
maps, texts and objectives, and reports that custom music tracks are already
implemented. New effects and other audio are planned. This records the user's
direction; it does not certify the ownership or runtime coverage of those tracks.
The existing optional synthesized soundscape is a separate verified development
asset with its own generator/output provenance.

## Campaign and audio workflow

On 8 October the user also approved evaluating popular Zeus Heaven fan maps as
starting points. Six downloads and an independent Alexandria working copy are
prepared; its author invites editing and includes map/settings sources. Use
`CUSTOM_ADVENTURE_RESEARCH.md` and the fan provenance register for this route.
A permitted adaptation may supply retained terrain once the necessary commercial
rights are established. Archive integrity is verified; native import, a playable
adaptation and commercial permission are not yet verified.

Preserve the original installation and campaign sources. Author/edit copies with
new campaign identities and record source inputs. Existing maps and mission
structures can remain development references or adaptation prototypes. A modified
original file is still recorded as an adaptation until its retained expressive
content has been assessed and the necessary permission or replacement documented.
Do not classify it as independently authored merely because layouts, prose or
objective values changed.

For independent shipping scenarios, prefer newly authored terrain layouts,
mission writing, dialogue, objective combinations and pacing. Historical/mythic
ideas and generic city-building challenges can inform the design; the original
game's particular expression is assessed separately. When an actual original
map/story/audio input is retained, document its source and distribution permission
or replace it. New additions do not themselves clear underlying protected work.
[U.S. Copyright Office: derivative works](https://www.copyright.gov/circs/circ14.pdf)

For sound replacement, keep the functional event mapping while recording or
synthesizing new sounds from general action descriptions and permitted inputs.
Remixing, sampling, voice imitation or regeneration using an original recording
as input is not automatically an independent replacement. Record composer,
performer/voice consent where relevant, samples, generation tool/terms, source
inputs and final file hashes. The user-reported custom music needs file-level
provenance/runtime review before it is marked cleared for the release package.

## Engine and packaging boundaries

Retain the existing C++ simulation, native rules, save identifiers and required
upstream GPL/author/dependency notices. Independent branding does not change the
engine license. Do not blindly rename technical Zeus/Poseidon serialization keys
or overwrite the user's saves to change public branding.

Steamworks SDK integration remains a separate unresolved license question. Keep
SDK features out of this milestone until the intended code/distribution
arrangement is reviewed. Valve explicitly identifies copyleft/GPL combinations
with the SDK as problematic and requires the necessary distribution rights.
[Valve: distributing open-source applications](https://partner.steamgames.com/doc/sdk/uploading/distributing_opensource)

The shipping build needs an explicit content allowlist and a tested content
provider that starts without the original DATA, XML, campaign, audio or installation
folders. Development compatibility assets may remain in this workspace without
being approved for packaging. This decision neither deletes them nor authorizes
publication or a store submission.

## Current production status and next work

- First content prototype: **First Light Harbor implemented; scoped EN/RU checks
  pass**. A separate Mac launcher retains fan terrain/roads with new narrative/goals.
  Natural playthrough/pacing and commercial rights remain pending. See
  `FIRST_LIGHT_HARBOR.md`; it is not a cleared independent shipping scenario.
- Release route: **independent brand confirmed**; final brand and content rights
  evidence remain open.
- City explanations, warning navigation, settlement guide, shared architectural
  finish, smoother work, slope clearance/supports and construction reveal are
  implemented and scoped EN/RU checks pass. Painted materials, full foot IK,
  finished audio and a complete first-settlement playthrough remain pending.
- User custom music: **reported implemented**; installed-path and ownership audit
  are not completed by this decision.
- Recommended next engineering milestone: interrupted-save/recovery/corruption
  and update compatibility, including persistent building facing.
- Recommended next content milestone: one original 30–60-minute scenario, using
  the reference campaigns to identify useful challenges while authoring the
  shipping layout, narrative and progression independently.

Use `PRODUCTION_ROADMAP.md`, `provenance-register.template.json` and current
migration/validation documents as the implementation and release evidence trail.
