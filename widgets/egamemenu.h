#ifndef EGAMEMENU_H
#define EGAMEMENU_H

#include "egamemenubase.h"
#include "ebuildingmode.h"

class eCheckableButton;
class eTextureCollection;
class eInterfaceTextures;
class eButton;
class eGameBoard;
class ePopulationDataWidget;
class eEmploymentDataWidget;
class eAdminDataWidget;
class eStorageDataWidget;
class eAppealDataWidget;
class eHygieneSafetyDataWidget;
class eHusbandryDataWidget;
class eMythologyDataWidget;
class eCultureDataWidget;
class eScienceDataWidget;
class eMilitaryDataWidget;
class eOverviewDataWidget;
class eMiniMap;
class eGameWidget;
class eEventWidget;
class eBuildButton;
class eBuildWidget;
class eFramedLabel;
enum class eEvent;
struct eEventData;
class eRotateButton;
class eDataWidget;

struct eSubButtonData;

class eSubButton;

struct eSPR {
    eBuildingMode fMode;
    std::string fName;
    int fMarbleCost = 0;
    int fCity = -1;
};

class eGameMenu : public eGameMenuBase {
public:
    using eGameMenuBase::eGameMenuBase;
    ~eGameMenu();
    void initialize(eGameBoard* const b,
                    const eAction& goalsView);

    int tradeCityId() const { return mTradeCityId; }
    eBuildingMode mode() const { return mMode; }
    void clearMode() { mMode = eBuildingMode::none; }
    void setMode(const eBuildingMode mode);

    void setGameWidget(eGameWidget* const gw);

    eMiniMap* miniMap() const;

    void pushEvent(const eEvent e, const eEventData& ed);
    void tickEvents();

    using eViewTileHandler = std::function<void(eTile*)>;
    void setViewTileHandler(const eViewTileHandler& h);

    void closeBuildWidget();
    void setBuildWidget(eBuildWidget* const bw);

    void updateButtonsVisibility();
    void viewedCityChanged();
    void openBuildWidget(const int cmx, const int cmy,
                         const std::vector<eSPR>& cs);

    void setModeChangedAction(const eAction& func);
    void setUndoAction(const eAction& func);
    void setUndoEnabled(const bool e);

    void updateRequestButtons();

    void setWorldDirection(const eWorldDirection dir);

    void update();

    void setShowAllPossibleBuildings(const bool b);

    // The open category, as an index into categoryButtons() (-1 none).
    int currentCategory() const;
    // Opens a category by its index (6 is culture or science, whichever the
    // city has); false when that category is hidden or disabled.
    bool openCategory(const int i);
    // The Info / Map switch at the top.
    bool mapTab() const { return mMapMode; }
    void setMapTab(const bool m);
protected:
    bool mousePressEvent(const eMouseEvent& e);
    void paintEvent(ePainter& p) override;
    void categoryChanged(const int i) override;
private:
    // Map tab: the minimap fills the content card (and back).
    void setMapMode(const bool m);
    // Panel geometry, in the 1/mult units the original art was laid out in.
    float u(const double v) const { return static_cast<float>(v*mMult); }

    using eButtonsDataVec = std::vector<eSubButtonData>;
    eWidget* createSubButtons(const int resoltuionMult,
                              const eButtonsDataVec& buttons);
    eBuildButton* createBuildButton(const eSPR& c);

    void displayPrice(const int price, const int loc);
    eWidget* createPriceWidget(const eInterfaceTextures& coll);

    eGameBoard* mBoard{nullptr};
    eGameWidget* mGW = nullptr;

    eBuildWidget* mBuildWidget = nullptr;

    eFramedLabel* mNameLabel = nullptr;

    eCheckableButton* mPopulationButton = nullptr;
    eCheckableButton* mHusbandryButton = nullptr;
    eCheckableButton* mIndustryButton = nullptr;
    eCheckableButton* mDistributionButton = nullptr;
    eCheckableButton* mHygieneSafetyButton = nullptr;
    eCheckableButton* mAdministrationButton = nullptr;
    eCheckableButton* mScienceButton = nullptr;
    eCheckableButton* mCultureButton = nullptr;
    eCheckableButton* mMythologyButton = nullptr;
    eCheckableButton* mMilitaryButton = nullptr;
    eCheckableButton* mAesthethicsButton = nullptr;
    eCheckableButton* mOverviewButton = nullptr;

    ePopulationDataWidget* mPopDataW = nullptr;
    eEmploymentDataWidget* mEmplDataW = nullptr;
    eHusbandryDataWidget* mHusbDataW = nullptr;
    eStorageDataWidget* mStrgDataW = nullptr;
    eAppealDataWidget* mApplDataW = nullptr;
    eHygieneSafetyDataWidget* mHySaDataW = nullptr;
    eAdminDataWidget* mAdminDataW = nullptr;
    eCultureDataWidget* mCultureDataW = nullptr;
    eScienceDataWidget* mScienceDataW = nullptr;
    eMythologyDataWidget* mMythDataW = nullptr;
    eMilitaryDataWidget* mMiltDataW = nullptr;
    eOverviewDataWidget* mOverDataW = nullptr;

    eRotateButton* mRotateButton = nullptr;
    eButton* mWorldButton = nullptr;

    eMiniMap* mMiniMap = nullptr;

    int mTradeCityId = -1;
    eBuildingMode mMode{eBuildingMode::none};

    std::vector<eWid> mWidgets;

    eEventWidget* mEventW = nullptr;

    std::vector<eWidget*> mPriceWidgets;
    std::vector<eLabel*> mPriceLabels;

    std::vector<eSubButton*> mSubButtons;

    eAction mModeChangeAct;
    eButton* mUndoButton = nullptr;

    bool mShowAllPossibleBuildings = false;

    int mMult = 2;
    int mTitleH = 0;
    class ePanelTabs* mTabs = nullptr;
    class ePanelVeil* mVeil = nullptr;
    bool mMapMode = false;
    eWidget* mMapHome = nullptr;      // the overview page that normally holds the minimap
    SDL_Rect mMapHomeRect{0, 0, 0, 0};
    eWidget* mPageBeforeMap = nullptr;
    eWidget* mLastPage = nullptr;
    double mRailY = -1;
    double mRailLast = -1;
    SDL_Texture* mCalmTex = nullptr;   // "all is calm" under an empty event list
    int mCalmW = 0;
    int mCalmH = 0;
    struct eKeyText { SDL_Texture* fTex; int fW; int fH; };
    std::vector<eKeyText> mKeyTex;    // map colour key labels
};

#endif // EGAMEMENU_H
