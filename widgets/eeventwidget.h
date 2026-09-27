#ifndef EEVENTWIDGET_H
#define EEVENTWIDGET_H

#include "ewidget.h"
#include "ebutton.h"

#include "characters/echaracter.h"

class eGameBoard;
class eTile;
enum class eEvent;
struct eEventData;

class eEventButton : public eButton {
public:
    eEventButton(const eEvent e,
                 eMainWindow* const window);
protected:
    void paintEvent(ePainter& p) override;
private:
    double mBorn = -1;
};

struct eEventItem {
    eEventButton* fButton = nullptr;
    int fRemainingFrames = 420; // ~7 seconds at 60 FPS
    eEvent fEvent{};
    eTile* fTile = nullptr;
    stdptr<eCharacter> fChar;
};

class eEventWidget : public eWidget {
public:
    using eWidget::eWidget;
    ~eEventWidget();

    void pushEvent(const eEvent e, const eEventData& ed);
    void tick();
    void clear();

    using eViewTileHandler = std::function<void(eTile*)>;
    void setViewTileHandler(const eViewTileHandler& h);
private:
    void relayout();
    void removeEventItem(eEventItem& item);

    eViewTileHandler mViewTileHandler;
    std::vector<eEventItem> mEvents;
};

#endif // EEVENTWIDGET_H
