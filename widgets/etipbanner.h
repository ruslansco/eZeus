#ifndef ETIPBANNER_H
#define ETIPBANNER_H

#include "ebuttonbase.h"

// A short notice at the top middle of the map ("Population goal has been
// achieved!", "Game saved" ...): a lapis pill with a gold rim that drops in,
// and fades out when it is dismissed (its time is up, or it was clicked).
class eTipBanner : public eButtonBase {
public:
    using eButtonBase::eButtonBase;
    ~eTipBanner();

    void initialize(const std::string& text);

    // Places the banner at y; later moves glide there.
    void setStackY(const int y);
    void dismiss() { mLeaving = true; }
    bool leaving() const { return mLeaving; }
    // Faded out; the game widget then deletes it.
    bool finished() const { return mGone; }
    // Skips the drop in (screenshots).
    void settle() { mIn = 1; }
protected:
    void paintEvent(ePainter& p) override;
private:
    SDL_Surface* mSurf = nullptr;
    SDL_Texture* mTex = nullptr;
    int mTW = 0;
    int mTH = 0;
    int mPadX = 0;
    int mTextX = 0;

    double mLast = -1;
    double mIn = 0;
    double mOut = 0;
    double mHover = 0;
    bool mLeaving = false;
    bool mGone = false;
    bool mPlaced = false;
    double mYOffset = 0;
};

#endif // ETIPBANNER_H
