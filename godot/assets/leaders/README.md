# Painted city rulers

The world map displays these installed painted portraits in the wood-and-gold
`AtlasPortrait` frame. `ui/envoy_portrait.gd` resolves an exact normalized leader
name first, then an exact city name. English/Russian aliases identify the same
artwork. This is presentation metadata, not a native city/ruler ID replacement.

For an owned city, `player_ruler.png` can provide the player's generic portrait
when no exact leader/city image is supplied. The complete generated portrait
folder is pending the user's location; do not label unrelated art as that ruler.
Missing map artwork shows the neutral civic seal, never a rendered envoy model
or city landscape. Historical envoy renders and correspondence remain separate.

Retain supplied masters, attribution/provenance and hashes when installing further
images. No new ruler artwork was generated for this frame/routing pass.
