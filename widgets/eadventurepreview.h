#ifndef EADVENTUREPREVIEW_H
#define EADVENTUREPREVIEW_H

#include "ewidget.h"
#include "emenu3d.h"

// The chosen adventure's picture as a gilded 3D card: it keeps the picture's
// own aspect, leans toward the cursor, crossfades on change and catches a
// passing glint.
class eAdventurePreview : public eWidget {
public:
    using eWidget::eWidget;

    void setBitmap(const int b);
protected:
    void paintEvent(ePainter& p) override;
private:
    int mBitmap = -1;
    int mPrevious = -1;
    double mFade = 1;
    double mYaw = 0;
    double mPitch = 0;
    Uint64 mLast = 0;
    double mTime = 0;
    eMenu3D::eSupersample mSuper;
};

#endif // EADVENTUREPREVIEW_H
