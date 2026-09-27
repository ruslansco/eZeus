#ifndef EBITMAPWIDGET_H
#define EBITMAPWIDGET_H

#include "ewidget.h"

class eBitmapWidget : public eWidget {
public:
    using eWidget::eWidget;

    void setBitmap(const int b) {
        mBitmap = b;
    }

    void setScaling(const double s) {
        mScaling = s;
    }

    // Adventure picture number b at a UI scale.
    static std::shared_ptr<eTexture> sTexture(const int b, const eUIScale scale);
protected:
    void sizeHint(int& w, int& h);

    void paintEvent(ePainter& p);
private:
    std::shared_ptr<eTexture> texture() const;

    int mBitmap = 0;
    double mScaling = 1.;
};

#endif // EBITMAPWIDGET_H
