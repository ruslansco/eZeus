#ifndef EGAMEWIDGET_H
#define EGAMEWIDGET_H

#include <deque>
#include <optional>
#include <chrono>

#include "emainwidget.h"
#include "eframedlabel.h"

#include "engine/etile.h"

#include "textures/eterraintextures.h"
#include "textures/ebuildingtextures.h"

#include "buildings/epatrolbuilding.h"

#include "widgets/egamemenu.h"
#include "widgets/earmymenu.h"
#include "egamemainmenu.h"
#include "etopbarwidget.h"

#include "eviewmode.h"
#include "emessage.h"
#include "echeckbox.h"

#include "engine/eeventdata.h"

class eTerrainEditMenu;
class eDomesticatedAnimal;
struct eSanctBlueprint;
class eWorldWidget;
struct eGodMessages;
struct eHeroMessages;
class eMessageBox;
class eGameBoard;
class eAgoraBase;
class eInfoWidget;
class eFramedButton;
class eObjectiveTrackerWidget;
class eMessageToast;
class eHouseHoverCard;

enum class eAgoraOrientation;
enum class eGodType;
enum class eHeroType;
enum class eGodQuestId;
enum class eWorldDirection;

using eBuildingCreator = std::function<stdsptr<eBuilding>()>;

struct eSavedMessage {
    eEventData fEd;
    eMessage fMsg;
    bool fReplay = false;   // re-opened from the message list: not logged again
};

// A message the player was sent, kept for the side panel's message list.
struct eLoggedMessage {
    eEventData fEd;
    eMessage fMsg;
    int fId = 0;
};

struct eGameWidgetSettings {
    bool fPaused = false;
    int fSpeedId = 1;
    int fSpeed = 10;
    int fDX = 0;
    int fDY = 0;
    eTileSize fTileSize = eTileSize::s30;
    eWorldDirection fDir = eWorldDirection::N;
    std::map<int, std::pair<int, int>> fBookmarks;

    void read(eReadStream& src) {
        src >> fPaused;
        src >> fSpeedId;
        src >> fSpeed;
        src >> fDX;
        src >> fDY;
        src >> fTileSize;
        src >> fDir;

        int n;
        src >> n;
        for(int i = 0; i < n; i++) {
            int id;
            src >> id;
            auto& b = fBookmarks[id];
            src >> b.first;
            src >> b.second;
        }
    }

    void write(eWriteStream& dst) const {
        dst << fPaused;
        dst << fSpeedId;
        dst << fSpeed;
        dst << fDX;
        dst << fDY;
        dst << fTileSize;
        dst << fDir;

        dst << fBookmarks.size();
        for(const auto& b : fBookmarks) {
            dst << b.first;
            dst << b.second.first;
            dst << b.second.second;
        }
    }
};

class eGameWidget : public eMainWidget {
public:
    eGameWidget(eMainWindow* const window);
    ~eGameWidget();

    void initialize();

    void pixToId(const int pixX, const int pixY,
                 int& idX, int& idY) const;

    void setViewMode(const eViewMode m);
    void toggleViewMode(const eViewMode m, const std::string& nameKey);
    void resetViewMode();
    eViewMode viewMode() const { return mViewMode; }

    double zoomScale() const { return mZoomScale; }
    int currentZoomIndex() const;
    void zoomSteps(const int steps, const int x, const int y);
private:
    void updateZoomAnimation(const double dt = 0.0);
public:

    void viewFraction(const double fx, const double fy);
    void viewTile(eTile* const tile);
    eTile* viewedTile() const;
    bool tileVisible(eTile* const tile) const;
    eCityId viewedCity() const;

    void showBuyCity(const eCityId cid);
    void hideBuyCity();

    void setBoard(eGameBoard* const board);

    eGameWidgetSettings settings() const;
    void setSettings(const eGameWidgetSettings& s);

    void updateRequestButtons();
    // Every message shown to the player this session, oldest first.
    const std::vector<eLoggedMessage>& messageLog() const { return mMessageLog; }
    // Messages that arrived since the list was last opened.
    int unseenMessages() const { return static_cast<int>(mMessageLog.size()) - mMessagesSeen; }
    void showMessageLog();
    // The viewed city's monthly record as charts (eCityHistoryWidget).
    void showCityHistory();
    // Trade per partner this year and last, and unsold stock (eTradeSummaryWidget).
    void showTradeSummary();
    // Screenshot aid (EZEUS_SHOT_PANEL=messages|badge): sample log entries.
    void debugFillMessageLog();
    // Opens a logged message again, read-only (its choices already happened).
    void replayMessage(const int i);
    // Screenshot aid (EZEUS_SHOT_PANEL=toasts): sample minor-message cards.
    void debugShowToasts();
    // Screenshot aid (EZEUS_SHOT_PANEL=history): the chart with ten sample years.
    void debugShowCityHistory();
    // Screenshot aid (EZEUS_SHOT_PANEL=house): rests the mouse on a house.
    void debugHoverHouse();
    // Screenshot aid (EZEUS_SHOT_PANEL=place|road): a fountain being placed
    // next to a road, or a road being dragged.
    void debugPlacePreview(const bool road);

    // frames: how long it stays (20 per second)
    void showTip(const ePlayerCityTarget& target,
                 const std::string& tip,
                 const int frames = 200);
    void showQuestion(const std::string& title,
                      const std::string& q,
                      const eAction& action);

    void updateViewBoxSize();
    void updateTopBottomAltitude();
    void updateMinMaxAltitude();
    void updateMaps(const bool totalUpdate);
    void updateMaps(const std::vector<eTile*>& tiles);
    void updateCitiesOnBoard();

    void setWorldDirection(const eWorldDirection dir);

    void centerDialog(eWidget* const d);
    void openDialog(eWidget* const d) override;
protected:
    void paintEvent(ePainter& p) override;

    bool keyPressEvent(const eKeyPressEvent& e) override;
    bool mousePressEvent(const eMouseEvent& e) override;
    bool mouseMoveEvent(const eMouseEvent& e) override;
    bool mouseLeaveEvent(const eMouseEvent& e) override;
    bool mouseReleaseEvent(const eMouseEvent& e) override;
    bool mouseWheelEvent(const eMouseWheelEvent& e) override;
private:
    void renderTargetsReset() override;
    void initializeNumbers();

    void drawXY(int tx, int ty,
                double& rx, double& ry,
                const int wSpan, const int hSpan,
                const int a);

    void setDX(const int dx);
    void setDY(const int dy);
    void clampViewBox();

    void setBookmark(const int id);
    void viewBookmark(const int id);

    using eApply = std::function<void(eTile* const)>;
    eApply editFunc();

    using eTileAction = std::function<void(eTile* const)>;
    void iterateOverVisibleTiles(const eTileAction& a);

    void setTileSize(const eTileSize size);

    using eSpecialRequirement = std::function<bool(eTile*)>;
    bool canBuildVendor(const int tx, const int ty,
                        const eResourceType resType) const;
    bool canBuildFishery(const int tx, const int ty,
                         eDiagonalOrientation& o) const;
    bool waterTileHasAccessToSea(const int tx, const int ty) const;
    bool canBuildTriremeWharf(const int tx, const int ty,
                              eDiagonalOrientation& o) const;
    bool canBuildPier(const int tx, const int ty,
                      eDiagonalOrientation& o, const eCityId cid,
                      const ePlayerId pid, const bool forestAllowed) const;

    std::vector<eTile*> agoraBuildPlaceBR(eTile* const tile,
                                          const eCityId cid,
                                          const ePlayerId pid) const;
    std::vector<eTile*> agoraBuildPlaceTL(eTile* const tile,
                                          const eCityId cid,
                                          const ePlayerId pid) const;
    std::vector<eTile*> agoraBuildPlaceBL(eTile* const tile,
                                          const eCityId cid,
                                          const ePlayerId pid) const;
    std::vector<eTile*> agoraBuildPlaceTR(eTile* const tile,
                                          const eCityId cid,
                                          const ePlayerId pid) const;
    std::vector<eTile*> agoraBuildPlaceIter(
            eTile* const tile, const bool grand,
            eAgoraOrientation& bt,
            const eCityId cid,
            const ePlayerId pid) const;

    std::vector<ePatrolGuide>::iterator
        findGuide(const int tx, const int ty);

    void handleEvent(const eEvent e, eEventData& ed);
    void handleGodQuestEvent(eEventData& ed,
                             const bool fulfilled);
    void handleGodVisitEvent(eEventData& ed);
    void handleGodInvasionEvent(eEventData& ed);
    void handleGodHelpEvent(eEventData& ed);
    void handleSanctuaryComplete(eEventData& ed);
    void handleMonsterUnleashEvent(eEventData& ed);
    void handleMonsterInvasionInitialEvent(eEventData& ed);
    void handleMonsterInvasion24Event(eEventData& ed);
    void handleMonsterInvasion12Event(eEventData& ed);
    void handleMonsterInvasion6Event(eEventData& ed);
    void handleMonsterInvasion1Event(eEventData& ed);
    void handleMonsterInvasionEvent(eEventData& ed);
    void handleMonsterSlainEvent(eEventData& ed);
    void handleHeroArrivalEvent(eEventData& ed);

    void handleMonsterInCityEvent(eEventData& ed);

    void mapDimensions(int& mdx, int& mdy) const;
    void viewBoxSize(double& fx, double& fy) const;
    void viewedFraction(double& fx, double& fy) const;
    void tileViewFraction(eTile* const tile,
                          double& xf, double& yf) const;

    void updateMinimap();
    void updateSmoothCamera(const double dt = 0.0);
    bool stepSimulation();

    int rotationId() const;
    int hippodromeId() const;
    void updateHippodromeIds();

    void showMessage(eEventData& ed, const eMessage& msg,
                     const bool prepend = false);
    void showMessage(eEventData& ed, const eMessageType& msg,
                     const bool prepend = false);
    void showMessage(eEventData& ed, const eEventMessageType& msg,
                     const bool prepend = false);

    void updateTipPositions();

    bool roadPath(std::vector<eOrientation>& path);
    bool columnPath(std::vector<eOrientation>& path);
    bool bridgeTiles(eTile* const t, const eTerrain terr,
                     std::vector<eTile*>& tiles,
                     bool& rotated);
    bool canBuildAvenue(eTile* const t, const eCityId cid,
                        const ePlayerId pid,
                        const bool forestAllowed) const;

    bool inErase(const int tx, const int ty);
    bool inErase(const SDL_Rect& rect);
    bool inErase(eAgoraBase* const a);
    bool inErase(eBuilding* const b);

    bool inPatrolBuildingHover(eBuilding* const b);

    void setArmyMenuVisible(const bool v);

    void scheduleConnectedTerrainUpdate(eTile* const startTile);
    void updateTerrainTextures(eTile* const tile,
                               const eTerrainTextures& trrTexs,
                               const eBuildingTextures& builTexs);
    void updateTerrainTextures();

    void updatePatrolPath();
    void setPatrolBuilding(ePatrolBuildingBase* const pb);

    eInfoWidget* openInfoWidget(eBuilding* const b);
    eInfoWidget* openInfoWidget(const std::vector<eCharacter *> chars);

public:
    void switchPause();
    bool isPaused() const { return mPaused; }
    bool hasModalDialog() const;
    bool isSimulationRunning() const { return !mPaused && !hasModalDialog(); }
    int speedId() const { return mSpeedId; }
    int maxSpeedId() const { return sMaxSpeedId; }
    void setSpeedId(int id);
    void updateSpeedDisplay();
    void showSpeedToast();

    int topBarHeight() const;
    void showGoals();
    void toggleObjectivesTracker();
    eObjectiveTrackerWidget* objectivesTracker() const { return mObjectivesTracker; }

    void openInGameMenu();
    void cloneHoveredBuilding();
    void toggleQuickDemolish();
    void quickSaveGame();
    void updateTimedAutosave(const double ms);
    void timedAutosave(const int slots);

    bool buildMouseRelease();
    bool buildMouseReleaseRecorded();
    bool undoAvailable() const;
    void undoLastBuild();
    void clearUndo();
    void setPressedTileForTest(const int x, const int y) { mPressedTX = x; mPressedTY = y; mLeftPressed = true; }
    void setHoverTileForTest(const int x, const int y) { mHoverTX = x; mHoverTY = y; }
    eGameMenu* gameMenu() const { return mGm; }
    void setGameMenuForTest(eGameMenu* const gm) { mGm = gm; }

private:
    stdsptr<eTexture> getBasementTexture(
            const int tx, const int ty, eBuilding* const d,
            const eTerrainTextures& trrTexs, const eWorldDirection dir,
            const int boardw, const int boardh);

    std::vector<eTile*> selectedTiles() const;

    eMouseButton mPressedButtons = eMouseButton::none;

    bool mEditorMode = false;
    bool mEditorShowBuildings = false;
    bool mTerrainEditMode = false;

    bool mRotate = false;
    int mRotateId = 0;

    const int sSpeeds[6] = {2, 10, 25, 50, 100, 100};
    const int sMaxSpeedId = int(std::size(sSpeeds)) - 1;

    bool mPaused = false;
    bool mLocked = false;
    int mFrame{0};
    int mRotateFrame{0};
    std::vector<int> mValiableHippodromePieces;
    int mTime{0};
    int mSpeedId = 1;
    int mSpeed = sSpeeds[mSpeedId];
    std::map<int, std::pair<int, int>> mBookmarks;

    int mWheel = 0;

    int mMinAltitude = 0;
    int mMaxAltitude = 0;

    int mTopMinAltitude = 0;
    int mBottomMaxAltitude = 0;

    int mDX = 0;
    int mDY = 0;
    double mPreciseDX = 0.0;
    double mPreciseDY = 0.0;
    double mPanVX = 0.0;
    double mPanVY = 0.0;
    std::chrono::high_resolution_clock::time_point mLastFrameTime{};
    std::chrono::high_resolution_clock::time_point mLastCameraTime{};
    double mSimAccumulatorMs = 0.0;

    struct eUndoEntry {
        std::vector<stdptr<eBuilding>> fBuildings;
        ePlayerId fPlayer;
        int fRefund = 0;
        int fGameTime = 0;
        std::chrono::steady_clock::time_point fRealTime;
    };
    std::optional<eUndoEntry> mUndo;
    double mAutosaveMs = 0.0;
    bool mTimingInitialized = false;

    bool mLeftPressed = false;
    bool mMovedSincePress = false;

    int mHoverX = -1;
    int mHoverY = -1;
    int mHoverTX = -1;
    int mHoverTY = -1;
    int mPressedX = -1;
    int mPressedY = -1;
    int mPressedTX = -1;
    int mPressedTY = -1;
    int mLastX = -1;
    int mLastY = -1;

    eViewMode mViewMode = eViewMode::defaultView;

    eTileSize mTileSize = eTileSize::s30;
    int mTileW = 60;
    int mTileH = 30;
    double mZoomScale = 1.0;
    double mTargetZoomScale = 1.0;
    int mZoomIndex = 1;

    // Fast, responsive smooth zoom with cursor-centric positioning
    bool mZoomAnimating = false;
    bool mZoomInstant = false;
    int mZoomAnchorX = 0;
    int mZoomAnchorY = 0;
    double mZoomMapX = 0.0;
    double mZoomMapY = 0.0;
    std::chrono::steady_clock::time_point mLastWheelTime{};

    int mUpdateRect = 0;
    std::vector<SDL_Rect> mUpdateRects;
    stdptr<eGameBoard> mBoard;

    bool mDrawElevation = true;
    stdptr<ePatrolBuildingBase> mPatrolBuilding;
    std::vector<eTile*> mPatrolPath;
    std::vector<eTile*> mExcessPatrolPath;
    std::vector<eTile*> mPatrolPath1;
    std::vector<eTile*> mExcessPatrolPath1;
    eWidget* mPatrolPathWid = nullptr;
    std::vector<ePatrolGuide> mSavedGuides;

    eFramedLabel* mPausedLabel = nullptr;

    eTopBarWidget* mTopBar = nullptr;
    eObjectiveTrackerWidget* mObjectivesTracker = nullptr;
    eInfoWidget* mInfoWidget = nullptr;
    eMessageBox* mMsgBox = nullptr;
    std::deque<eSavedMessage> mSavedMsgs;
    // log: record it for the message list (not for queued or re-opened ones);
    // replay: keep its original date and addressee
    void showMessageImpl(eEventData& ed, const eMessage& msg,
                         const bool prepend, const bool replay,
                         const bool log);
    std::vector<eLoggedMessage> mMessageLog;
    int mMessagesSeen = 0;
    int mNextMessageId = 0;

    // Minor events (fire, workers, world news ...) show as eMessageToast
    // cards instead of a message box; fTone < 0 means a full message box.
    struct eToastStyle {
        std::string fIcon;
        int fTone = -1;
    };
    static eToastStyle sToastStyle(const eEvent e);
    eToastStyle mToastStyle;         // of the event being handled
    std::string mCondensedText;      // its short text, for the card
    std::vector<eMessageToast*> mToasts;
    void showToast(const eEventData& ed, const eMessage& msg,
                   const eToastStyle& style, const int logId);
    void layoutToasts();

    // The card that says what a house needs, while the mouse rests on it.
    eHouseHoverCard* mHouseCard = nullptr;
    bool mMouseOnMap = false;
    const eBuilding* mCardHouse = nullptr;   // identity only
    double mCardSince = 0;
    void updateHouseCard();
    int mMiddlePressX = -1000;   // a middle click without a drag copies
    int mMiddlePressY = -1000;
    eTerrainEditMenu* mTem = nullptr;
    eGameMenu* mGm = nullptr;
    eArmyMenu* mAm = nullptr;

    eWorldWidget* mWW = nullptr;

    struct eTip {
        ePlayerCityTarget fTarget;
        std::string fText;
        eWidget* fWid = nullptr;
        int fLastFrame = 0;
    };

    std::deque<eTip> mTips;

    std::map<eTileSize, std::vector<stdsptr<eTexture>>> mNumbers;
    std::vector<eTile*> mInflTiles;
    std::vector<eTile*> mHoverTiles;

    eTile* mViewedTile = nullptr;
    eCityId mViewedCityId = eCityId::neutralFriendly;
    bool mUpdateViewedTileScheduled = true;

    eWidget* mBuyCityWidget = nullptr;
    eLabel* mBuyCityName = nullptr;
    eLabel* mBuyCityPrice = nullptr;
    eFramedButton* mBuyCityButton = nullptr;
    std::vector<eWidget*> mEditorWidgets;
};

#endif // EGAMEWIDGET_H
