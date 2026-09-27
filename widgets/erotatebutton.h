#ifndef EROTATEBUTTON_H
#define EROTATEBUTTON_H

#include "elabel.h"

#include "engine/egameboard.h"

class eRotateButton : public eLabel {
    enum class eButtonHoverPortion {
        left, center, right
    };
public:
    eRotateButton(eMainWindow* const window);

    void setEnabled(const bool b);
    bool enabled() const;

    bool pressed() const;
    bool hovered() const;

    void setDirection(const eWorldDirection dir);

    using eDirectionSetter = std::function<void(eWorldDirection)>;
    void setDirectionSetter(const eDirectionSetter& s);

    // Draw as the side panel's rotate pill (arrows around a compass) instead
    // of the original sprites.
    void setModern(const bool m) { mModern = m; }
protected:
    void paintEvent(ePainter& p) override;
    bool mousePressEvent(const eMouseEvent& e);
    bool mouseReleaseEvent(const eMouseEvent& e);
    bool mouseMoveEvent(const eMouseEvent& e);
    bool mouseEnterEvent(const eMouseEvent& e);
    bool mouseLeaveEvent(const eMouseEvent& e);
private:
    void updateTexture();

    eButtonHoverPortion mHovered{eButtonHoverPortion::left};
    eWorldDirection mDirection{eWorldDirection::N};

    eDirectionSetter mSetter = nullptr;
    bool mEnabled = true;
    bool mPressed = false;
    bool mHover = false;
    bool mModern = false;
    double mHoverAnim[3] = {0, 0, 0};
    double mNeedle = 0;
    double mLast = -1;
};

#endif // EROTATEBUTTON_H
