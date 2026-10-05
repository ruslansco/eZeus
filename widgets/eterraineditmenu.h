#ifndef ETERRAINEDITMENU_H
#define ETERRAINEDITMENU_H

#include "egamemenubase.h"

#include "engine/etile.h"
#include "engine/eterrainedit.h"
#include "echeckablebutton.h"

class eRotateButton;
class eMiniMap;
class eGameWidget;
class eActionListWidget;

class eTerrainEditMenu : public eGameMenuBase {
public:
    using eGameMenuBase::eGameMenuBase;

    void initialize(eGameWidget* const gw,
                    eGameBoard* const board);

    eTerrainEditMode mode() const;
    int modeId() const { return mModeId; }

    eMiniMap* miniMap() const { return mMiniMap; }

    void setWorldDirection(const eWorldDirection dir);

    eBrushType brushType() const;
    int brushSize() const;

    void updateCitiesOnBoard(eGameBoard& board);
protected:
    // lapis and gold, like the city's side panel (eGameMenu)
    void paintEvent(ePainter& p) override;
private:
    int mMult = 1;
    eBrushType mBrushType = eBrushType::apply;
    int mBrushSize = 1;
    eTerrainEditMode mMode = eTerrainEditMode::dry;
    int mModeId = 0;
    int mSpacing = 0;

    eCheckableButton* mB1 = nullptr;
    eCheckableButton* mB4 = nullptr;

    std::map<eCityId, eWidget*> mTerrioryButtons;
    eActionListWidget* mW12 = nullptr;

    eRotateButton* mRotateButton = nullptr;
    eMiniMap* mMiniMap = nullptr;

    std::vector<eWidget*> mWidgets;
};

#endif // ETERRAINEDITMENU_H
