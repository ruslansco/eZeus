#ifndef EMENUSCENE_H
#define EMENUSCENE_H

#include <SDL2/SDL.h>

#include <random>
#include <vector>

// Framing of the front-end backdrop for each screen. The camera glides
// between them, so screen changes read as one continuous shot.
enum class eMenuShot {
    main,       // wide establishing view, sharp
    adventures, // pushed in toward the acropolis, background out of focus
    settings,   // drifted toward the mountain, out of focus
    roster,
    loading,
    dialog      // a modal dialog over the main menu
};

// The living 2.5D backdrop behind every front-end screen, built from
// Textures/Menu/ (art/menu/make_scene.py): sky, land and foreground-tree
// layers displaced by a depth map for mouse parallax and camera moves,
// plus drifting haze, gulls, lightning, pollen, light shafts and a
// depth-of-field blur for sub-screens. One instance for the session so the
// animation carries across screen changes.
class eMenuScene {
public:
    static eMenuScene& instance();

    void setShot(const eMenuShot shot);
    eMenuShot shot() const { return mShot; }

    // Opening camera move for the first main menu of a session.
    void playIntro();
    void skipIntro();
    // Seconds since playIntro(), or a large value when no intro ran.
    double introTime() const { return mIntroT; }

    // Lightning behind the mountains with a sky flash.
    void strike(const bool sound);

    // Advances the animation and draws the backdrop over w x h.
    void paint(SDL_Renderer* const r, const int w, const int h);

    double time() const { return mTime; }
    // Smoothed pointer (plus idle drift), roughly -1..1.
    double lookX() const { return mLookX; }
    double lookY() const { return mLookY; }
    // Screen offset of something floating at depth d (0 sky .. 1 foreground,
    // above 1 = in front of the scene, e.g. UI).
    void parallax(const double d, float& dx, float& dy) const;
    // 0..1 brightness of the current lightning flash.
    double flash() const { return mFlash; }
    // Mouse position for the menus; screenshots can pin it (EZEUS_MENU_SHOT).
    void mouseState(int& x, int& y) const;
    void setPointerOverride(const int x, const int y);
    // Out-of-focus amount of the backdrop (0 sharp .. 1 blurred).
    double blur() const { return mBlur.fX; }

    // A small soft white dot (additive glows), a white pixel and the
    // radial vignette, shared with the menus.
    SDL_Texture* glowTexture() const { return mDot; }
    SDL_Texture* whiteTexture() const { return mWhite; }
private:
    eMenuScene() {}

    struct eSpring {
        double fX = 0;
        double fV = 0;
        double fTarget = 0;
        void update(const double dt, const double omega);
    };

    struct eLayer {
        SDL_Texture* fSharp = nullptr;
        SDL_Texture* fBlurred = nullptr;
    };

    struct eCloud {
        double fX, fY, fW, fH, fSpeed;
        int fTex;
        Uint8 fAlpha;
    };

    struct eBird {
        double fX, fY, fPhase, fSize;
    };

    struct eMote {
        double fX, fY, fD, fSize, fPhase, fVX, fVY;
    };

    struct eBolt {
        std::vector<SDL_FPoint> fPts; // image space
        double fWidth;
    };

    bool initialize(SDL_Renderer* const r);
    void loadLayer(SDL_Renderer* const r, const std::string& path,
                   eLayer& layer, const bool keepDepth);
    void update(const double dt, const int w, const int h);
    void spawnFlock();
    void makeBolt();

    // image (1920x1080) space -> screen for depth d
    SDL_FPoint project(const double ix, const double iy, const double d) const;
    void drawMesh(SDL_Renderer* const r, SDL_Texture* const tex,
                  const int kind, const Uint8 alpha);
    void drawImageQuad(SDL_Renderer* const r, SDL_Texture* const tex,
                       const double ix, const double iy,
                       const double iw, const double ih,
                       const double d, const SDL_Color c) const;
    void drawBolts(SDL_Renderer* const r, const Uint8 alpha);

    SDL_Renderer* mRenderer = nullptr;
    bool mInitialized = false;
    bool mHasLayers = false;
    bool mSunRight = false;

    eLayer mSky;
    eLayer mLand;
    eLayer mTrees;
    SDL_Texture* mFallback = nullptr;
    std::vector<float> mDepth; // 480x270 land depth 0..1
    std::vector<float> mSway;  // 480x270 tree sway weight
    std::vector<SDL_Texture*> mCloudTex;
    SDL_Texture* mDot = nullptr;
    SDL_Texture* mWhite = nullptr;
    SDL_Texture* mVignette = nullptr;
    SDL_Texture* mRay = nullptr;
    SDL_Texture* mBeam = nullptr;

    std::vector<SDL_Vertex> mVerts;
    std::vector<int> mIndices;

    int mW = 0;
    int mH = 0;
    double mScale = 1; // cover scale image -> screen

    Uint64 mLastCounter = 0;
    double mTime = 0;

    eMenuShot mShot = eMenuShot::main;
    eSpring mZoom;
    eSpring mCamX;
    eSpring mCamY;
    eSpring mBlur;
    eSpring mDim;

    bool mPointerOverride = false;
    int mOverrideX = 0;
    int mOverrideY = 0;
    double mLookX = 0;
    double mLookY = 0;
    double mPtrX = 0;
    double mPtrY = 0;

    double mIntroT = 1e9;
    bool mIntroStruck = true;

    double mFlash = 0;
    double mBoltT = 1e9;
    double mNextStrike = 14;
    bool mBoltRight = true;
    std::vector<eBolt> mBolts;

    std::vector<eCloud> mClouds;
    std::vector<eBird> mBirds;
    double mFlockX = 0;
    double mFlockY = 0;
    double mFlockDir = 1;
    double mNextFlock = 3;
    std::vector<eMote> mMotes;

    std::mt19937 mRng{20260925};
};

#endif // EMENUSCENE_H
