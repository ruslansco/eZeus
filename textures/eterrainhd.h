#ifndef ETERRAINHD_H
#define ETERRAINHD_H

#include <memory>
#include <string>
#include <vector>
#include <unordered_map>

#include <SDL2/SDL.h>

class eTexture;
class eTileBase;
enum class eWorldDirection;

// Remastered base terrain (art/terrain in the workspace).
//
// Plain sand, grass and open water are not drawn from the tile sprite sheets
// but cut, tile by tile, out of large seamless "plates": pre-rendered images
// of the ground that repeat every P tiles along both map axes. Each tile's
// diamond samples the plate at its own map position, so neighbouring tiles
// continue each other and no tiling seams show. Grass is blended over sand
// and shallow water over deep water with per-corner weights, which gives
// smooth transitions across tile corners.
//
// Plates live in Textures/Terrain/<tileH>/ (<name>@2x.png = double density):
//   sand, scrub, scrub_sparse (optional), shallow,
//   water_00 .. water_NN (animation frames)
// When a plate set is missing the game falls back to the original sprites.
class eTerrainHD {
public:
    // Plates for the given tile size, or nullptr when not installed / disabled.
    static eTerrainHD* get(SDL_Renderer* const r,
                           const int tileW, const int tileH);

    static bool sEnabled;
    // Shallow-water weight on and next to shore tiles.
    static const float sShoreShallow;
    // Optional explicit timestamp for deterministic previews. Normal drawing calls
    // this automatically once per presented frame; no simulation state changes.
    void prepareFrame(SDL_Renderer* r, Uint64 milliseconds) const;
    // Visual depth from nearby land. Cached per displayed frame, so editor
    // changes are visible immediately and rotated views share the same depth.
    float shallowWeight(const eTileBase* tile) const;
    // Shared perimeter plus independent center keeps isolated farmable tiles
    // readable without a discontinuity at their borders. Refreshed each frame.
    void fertileWeights(const eTileBase* tile, eWorldDirection direction, float weights[5]) const;

    // x, y: screen position of the tile's bounding box (top-left);
    // u, v: rotated tile coordinates; corner weights in order top, right,
    // bottom, left; mod: colour modulation (fog of war, highlights).
    void drawGround(SDL_Renderer* const r,
                    const double x, const double y,
                    const int u, const int v,
                    const float scrub[4],
                    const SDL_Color& mod) const;
    void drawWater(SDL_Renderer* const r,
                   const double x, const double y,
                   const int u, const int v,
                   const float shallow[4],
                   const SDL_Color& mod) const;

    // Shore tiles (water-to-land sprites of zeusLand1): HD sand, then the
    // animated HD water through the tile's water mask, then translucent
    // wet sand, submerged sand and a restrained meniscus. `legacy` is the original sprite; its rect
    // addresses the same sprite in the HD mask / decoration sheets, and
    // (sx, sy) is where the original sprite would be drawn.
    bool hasShores() const { return mShoreMask && mShoreDeco; }
    void drawShore(SDL_Renderer* const r,
                   const double x, const double y,
                   const int u, const int v,
                   const eTexture& legacy,
                   const int sx, const int sy,
                   const SDL_Color& mod) const;

    // Forest tiles: the seamless grass (weights as drawGround), then the HD
    // tree cluster rendered for the original sprite `legacy` of sheet
    // `sheet` (0 zeusLand1, 1 zeusTrees, 2 poseidonTrees).
    bool hasTrees(const int sheet) const;
    void drawForest(SDL_Renderer* const r,
                    const double x, const double y,
                    const int u, const int v,
                    const float scrub[4],
                    const eTexture& legacy, const int sheet,
                    const int sx, const int sy,
                    const SDL_Color& mod) const;

    // Rock outcrops (flat stones, copper, silver, tall stones of zeusLand1): the
    // HD rock sprite rendered for the original sprite `legacy`, drawn at the
    // original's position (sx, sy). The ground beneath is drawn separately per
    // tile (drawGround), since 2x2 / 3x3 outcrops are drawn in clipped strips.
    bool hasRocks() const { return mRocks != nullptr; }
    void drawRocks(SDL_Renderer* const r, const eTexture& legacy,
                   const int sx, const int sy, const SDL_Color& mod) const;

    // Elevation cliffs and ramps (zeusElevationTiles = 0, zeusElevationTiles2 = 1):
    // the HD sprite rebuilt from terrain geometry, at the original's position.
    bool hasCliffs(const int sheet) const { return sheet >= 0 && sheet < 2 && mCliffs[sheet]; }
    void drawCliff(SDL_Renderer* const r, const eTexture& legacy, const int sheet,
                   const int sx, const int sy, const SDL_Color& mod) const;

    // Roads: seamless 3D paving (road / road_pretty plates) cut per tile, plus a
    // ragged verge (road_edges) on every side without a road neighbour.
    // open: bit 0 tl, 1 tr, 2 br, 3 bl (screen sides) that have no road.
    bool hasRoads() const { return mRoad && mRoadPretty && mRoadEdges; }
    void drawRoad(SDL_Renderer* const r,
                  const double x, const double y,
                  const int u, const int v,
                  const bool pretty, const int open,
                  const SDL_Color& mod) const;

    // Avenue decorations (planters, cypresses, trees, benches, statues) rebuilt in 3D,
    // drawn at the original avenue sprite's position over the paving.
    bool hasAvenue() const { return hasRoads() && mAvenueDeco; }
    void drawAvenueDeco(SDL_Renderer* const r, const eTexture& legacy,
                        const int sx, const int sy, const SDL_Color& mod) const;

    // Husbandry (fertile) land: a lush meadow over the ground. weights: per
    // corner share of fertile tiles (top, right, bottom, left). Scattered
    // tufts and flowers come first (fertile_sparse), the dense sward fills in,
    // so the land fades organically into sand instead of in tile diamonds.
    bool hasFertile() const { return mFertile != nullptr; }
    void drawFertile(SDL_Renderer* const r,
                     const double x, const double y,
                     const int u, const int v,
                     const float weights[5],
                     const SDL_Color& mod) const;

    // Shore drawing writes the stencil into the frame's alpha channel;
    // call once per frame before presenting to make the frame opaque again.
    static void sFinishFrame(SDL_Renderer* const r);
private:
    eTerrainHD(const int tileW, const int tileH);
    bool load(SDL_Renderer* const r);
    void drawPlate(SDL_Renderer* const r,
                   const eTexture& plate,
                   const double x, const double y,
                   const int u, const int v,
                   const float alpha[4],
                   const SDL_Color& mod,
                   const bool batched = true,
                   const float bleed = .75f,
                   const float centerAlpha = -1.f) const;
    float fertileField(const eTileBase* tile) const;

    const int mTileW;
    const int mTileH;
    std::shared_ptr<eTexture> mSand;
    std::shared_ptr<eTexture> mScrub;
    std::shared_ptr<eTexture> mScrubSparse;
    std::shared_ptr<eTexture> mFertile;
    std::shared_ptr<eTexture> mFertileSparse;
    std::shared_ptr<eTexture> mShallow;
    std::vector<std::shared_ptr<eTexture>> mWater;
    std::vector<std::shared_ptr<eTexture>> mShallowFrames;
    bool mBakedCoastal = false;
    mutable std::shared_ptr<eTexture> mWaterBlend;
    mutable std::shared_ptr<eTexture> mShallowBlend;
    mutable std::shared_ptr<eTexture> mCoastalBlend;
    mutable const eTexture* mCurrentWater = nullptr;
    mutable const eTexture* mCurrentShallow = nullptr;
    mutable const eTexture* mCurrentCoastal = nullptr;
    mutable Uint64 mPreparedFrame = ~Uint64(0);
    mutable Uint64 mFrameTime = 0;
    mutable Uint64 mDepthFrame = ~Uint64(0);
    mutable std::unordered_map<const eTileBase*, float> mDepthWeights;
    mutable Uint64 mFertileFrame = ~Uint64(0);
    mutable std::unordered_map<const eTileBase*, float> mFertileField;
    static Uint64 sFrameSerial;
    std::shared_ptr<eTexture> mShoreMask;
    std::shared_ptr<eTexture> mShoreDeco;
    std::shared_ptr<eTexture> mShoreFoam;
    std::shared_ptr<eTexture> mTrees[3];
    std::shared_ptr<eTexture> mRocks;
    std::shared_ptr<eTexture> mCliffs[2];
    std::shared_ptr<eTexture> mRoad;
    std::shared_ptr<eTexture> mRoadPretty;
    std::shared_ptr<eTexture> mRoadEdges;
    std::shared_ptr<eTexture> mAvenueDeco;
    static bool sAlphaDirty;
};

#endif // ETERRAINHD_H
