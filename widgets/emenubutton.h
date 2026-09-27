#ifndef EMENUBUTTON_H
#define EMENUBUTTON_H

#include "ebuttonbase.h"

// Button of the front-end screens, in the style of the main menu tablets:
// Aegean stone (or bronze for the primary action) with a gold frame that
// warms and glows under the cursor.
class eMenuButton : public eButtonBase {
public:
    enum class eStyle { primary, secondary };

    using eButtonBase::eButtonBase;

    // Text, font and a size with comfortable padding (at least minWidth).
    void setup(const std::string& text, const eStyle style,
               const int minWidth = 0);
    void setStyle(const eStyle s) { mStyle = s; }
    // Toggle state (the chosen language, resolution ...).
    void setSelected(const bool s);
    bool selected() const { return mSelected; }
protected:
    void paintEvent(ePainter& p) override;
private:
    eStyle mStyle = eStyle::secondary;
    bool mSelected = false;
    double mHover = 0;
    Uint64 mLast = 0;
    int mColorState = -1;
};

#endif // EMENUBUTTON_H
