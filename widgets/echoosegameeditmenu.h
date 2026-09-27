#ifndef ECHOOSEGAMEEDITMENU_H
#define ECHOOSEGAMEEDITMENU_H

#include "emainmenubase.h"

#include "engine/ecampaign.h"

class eAdventurePreview;
class eAdventureRow;
class eScrollWidgetComplete;

// New Adventure / Adventure Editor: the campaign list beside a 3D preview
// card and the introduction. Arrow keys or W S move through the list, Enter
// or a double-click begins, Escape goes back.
class eChooseGameEditMenu : public eMainMenuBase {
public:
    using eMainMenuBase::eMainMenuBase;
    void initialize(const bool editor);

    void setGlossary(const eCampaignGlossary& g);
protected:
    void paintEvent(ePainter& p) override;
    bool keyPressEvent(const eKeyPressEvent& e) override;
private:
    void select(const int id, const bool scroll);
    void rowPressed(const int id);
    void proceed();
    bool dialogOpen() const;

    bool mEditor = false;
    std::vector<eCampaignGlossary> mGlossaries;
    std::vector<eAdventureRow*> mRows;
    int mSelectedId = -1;
    int mLastPressId = -1;
    Uint64 mLastPressTime = 0;
    eCampaignGlossary mSelected;
    eAdventurePreview* mPreview = nullptr;
    eScrollWidgetComplete* mScroll = nullptr;
    eLabel* mTitle = nullptr;
    eLabel* mDesc = nullptr;
};

#endif // ECHOOSEGAMEEDITMENU_H
