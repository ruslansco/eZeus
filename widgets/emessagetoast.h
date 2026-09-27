#ifndef EMESSAGETOAST_H
#define EMESSAGETOAST_H

#include "ebuttonbase.h"

// A minor message (fire, workers, world news ...) as a small card at the top
// right of the map instead of a box that stops the game. It slides in, waits
// a few seconds (the clock stops while it is hovered) and fades out; the full
// message stays in the side panel's message list. Left click runs the press
// action (go to the site, or open the full message), right click or the
// cross dismisses it.
class eMessageToast : public eButtonBase {
public:
    using eButtonBase::eButtonBase;
    ~eMessageToast();

    enum class eTone { news, alarm, good };

    void initialize(const std::string& icon, const eTone tone,
                    const std::string& title, const std::string& text,
                    const std::string& meta, const int width);

    // Places the card at y; later moves glide there.
    void setStackY(const int y);
    void dismiss();
    // Skips the slide-in (screenshots).
    void settle() { mIn = 1; }
    bool leaving() const { return mLeaving; }
    // Faded out; the game widget then deletes it.
    bool finished() const { return mGone; }
    // A new card with the same key replaces this one (a second fire ...).
    void setKey(const std::string& k) { mKey = k; }
    const std::string& key() const { return mKey; }
protected:
    void paintEvent(ePainter& p) override;
    bool mouseReleaseEvent(const eMouseEvent& e) override;
    bool mouseMoveEvent(const eMouseEvent& e) override;
    bool mouseLeaveEvent(const eMouseEvent& e) override;
private:
    bool overClose(const int x, const int y) const;

    std::string mIcon;
    std::string mKey;
    eTone mTone = eTone::news;

    SDL_Surface* mSurf[3] = {nullptr, nullptr, nullptr}; // title, text, meta
    SDL_Texture* mTex[3] = {nullptr, nullptr, nullptr};
    int mTW[3] = {0, 0, 0};
    int mTH[3] = {0, 0, 0};

    int mPad = 0;
    int mDisc = 0;
    int mTextX = 0;

    double mLast = -1;
    double mIn = 0;        // 0..1 slide in
    double mOut = 0;       // 0..1 fade out
    double mShown = 0;     // seconds shown, not counting hover
    double mLife = 7;
    double mHover = 0;
    double mCloseHover = 0;
    double mYOffset = 0;   // glide to a new stack position
    bool mPlaced = false;
    bool mLeaving = false;
    bool mGone = false;
    int mMouseX = -1;
    int mMouseY = -1;
};

#endif // EMESSAGETOAST_H
