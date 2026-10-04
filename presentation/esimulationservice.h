#pragma once
#include <memory>
#include <map>
#include <unordered_map>
#include <string>
#include <array>
#include <cstdint>
#include <chrono>
#include <vector>
#include <functional>
#include <optional>
#include <mutex>
#include "buildings/ebuilding.h"
#include "characters/echaracter.h"
#include "engine/eeventdata.h"
#include "engine/etradepartners.h"
class eGameBoard;
class eCampaign;
class eTile;
class eTradePost;
class eSoldierBanner;
struct eEnlistSession;
struct eGameWidgetSettings;
class eSimulationService {
public:
    ~eSimulationService();
    std::string open(const std::string& engine, const std::string& save, const std::string& lang);
    // New game: the adventures a game can start from (title, introduction, kind and reference), and one started
    // paused from the listing's `kind` ("pak" or "folder") and `ref`. Only listed adventures can be opened.
    std::string adventures(const std::string& engine, const std::string& lang);
    std::string openAdventure(const std::string& engine, const std::string& kind, const std::string& ref, const std::string& lang);
    void close();
    // Validators only: switches on the `test_win` command (a fulfilled set of goals without playing the episode).
    void enableTestCommands() { mAllowTestCommands = true; }
    void advance(double delta);
    // Deterministic replay of `ticks` simulation steps after reseeding the random generator (seed < 0 keeps
    // it); returns {"digest":...,"ticks":...} of the resulting state. Test sessions only.
    std::string replay(int ticks, long long seed);
    // Per-user saves. Only files directly inside this directory may be written or opened besides the designated
    // test city, so a session can never touch the designated save or anyone's own saves.
    void setSaveDirectory(const std::string& directory);
    // Writes the city to "<save directory>/<name>.ez" in the native format (the SDL game opens it too). The name
    // is 1 to 64 bytes of letters (UTF-8 allowed), digits, spaces, '_', '-' or '.', never starting with '.'.
    std::string save(const std::string& name);
    std::string snapshot(bool full = false);
    std::string command(const std::string& command);
    std::string diagnostics() const;
private:
    void prepare(const std::string& engine, const std::string& lang);
    std::string enter(const std::function<void(int)>& phase);
    // The running episode: titles, introduction and the goals with their live status.
    std::string episode();
    std::string housingShortfall(bool elite,int level);
    std::string episodeVoice();
    // Campaign flow: finish_episode books a won episode and says what comes next; preview_episode, choose_colony and
    // begin_episode lead into it; set_aside reserves the goods of a goal.
    void detach();
    std::string relativeSound(const std::string& path);
    std::string previewEpisode();
    std::string nextStep();
    std::string finishEpisode();
    std::string chooseColony(int index);
    std::string beginEpisode();
    std::string setAside(int index);
    // Sound files the simulation asked for since the last call (see eSoundVector::setSink).
    std::vector<std::string> takeSounds();
    // One overlay (native view mode): visible buildings and walker kinds, value columns, supplies, appeal grid.
    std::string overlay(const std::string& name);
    std::string placement(const std::string& name, int x, int y, int orientation, int partner = -1);
    std::optional<eTradePartner> tradePartner(eCityId cid, int index, bool water);
    std::string tradePartners();
    // The world map: every city on it with what the player may ask of it, the player's own cities and their stock, the pending
    // requests, and the three economic dealings the SDL world screen offers (request goods, give a gift, fulfil a request).
    std::string worldInfo();
    stdsptr<eWorldCity> worldCity(int index) const;
    std::string tradeInfo(eTradePost* post);
    // The army: the player's soldier banners (company, kind, size, where it stands, called out or at home) and the commands that
    // call them out, send them home and place them. `bannersJson` is also part of the snapshot, sent when it changed.
    std::string bannersJson();
    std::string armyInfo();
    int invaderCount(int* atX=nullptr,int* atY=nullptr) const;
    int monsterCount(int* atX=nullptr,int* atY=nullptr,std::string* name=nullptr) const;
    // Military dealings of the world map: raids, conquest or reinforcement, defensive aid and strikes. The first two (and a troop request's
    // "send troops") need forces enlisted: the engine asks its front end for them (eGameBoard::requestForces), the service keeps that
    // request as a session, `enlistInfo` says what may be enlisted and `enlist_dispatch` answers it as the SDL dialog does.
    std::string enlistInfo();
    std::string armiesJson();
    int worldIndex(const stdsptr<eWorldCity>& city) const;
    eSoldierBanner* playerBanner(int id) const;
    // The build menu: display name, footprint, model, cost and availability of every buildable name.
    std::string buildable();
    // The SDL side panel's data pages, finances and workforce allocation for the city in view (`city_data`).
    std::string cityData();
    // The player's city the pages follow: the city in view when it is the player's, else the last of theirs in view.
    eCityId playerCity() const;
    // Every district of the board: owner, whether it can be bought and for how much, where it lies (`cities`).
    std::string citiesJson();
    std::string inspect(int x, int y);
    // Drag-to-place roads: the tiles of the native drag path (the same path finder and ground rules as the
    // SDL view) between two tiles, the placement verdict for each, and the one-step build.
    bool roadPath(int x1, int y1, int x2, int y2, std::vector<eTile*>& tiles);
    std::string roadReason(eTile* tile, int cityId, bool& existing);
    std::string roadPreview(int x1, int y1, int x2, int y2);
    // Walls are dragged as the SDL view does: the outline of the rectangle between two tiles (all of it when `fill`),
    // each tile built or skipped on its own, until the treasury is 1000 drachmas in debt.
    std::vector<eTile*> wallTiles(int x1, int y1, int x2, int y2, bool fill);
    std::string wallPreview(int x1, int y1, int x2, int y2, bool fill);
    // Housing and parks are dragged over an area as the SDL view does: common housing in 2x2 steps and elite housing in 4x4
    // steps from the pressed tile toward the released one, parks on every tile; each footprint is built or skipped on its own.
    std::vector<std::pair<int,int>> areaCells(const std::string& name, int x1, int y1, int x2, int y2) const;
    std::string areaPreview(const std::string& name, int x1, int y1, int x2, int y2);
    // Columns, avenues and boulevards are dragged along a path (see esimulationservice.cpp): the plan, or the build.
    std::string pathCommand(const std::string& name, int x1, int y1, int x2, int y2, bool build);
    // A gatehouse is two 2x2 towers around a one-tile passage; the verdict for one of its tiles (empty when it fits).
    std::string gateReason(int x, int y, bool road, eCityId cid, ePlayerId pid);
    bool undoAvailable() const;
    void notify(const std::string& title, const std::string& text, const eEventData& data, const std::string& brief = std::string(), const std::string& kind = std::string());
    std::shared_ptr<eCampaign> mCampaign;
    std::shared_ptr<eGameWidgetSettings> mView;
    std::string mSaveDir, mDesignatedSave;
    eGameBoard* mBoard = nullptr;
    bool mPaused = true, mBlocked = false, mSentTerrain = false, mTerminal = false;
    bool mVictory = false, mAwaiting = false, mColonyChosen = false, mAllowTestCommands = false;
    int mSpeed = 0, mX = 0, mY = 0, mW = 0, mH = 0, mFocusX = 0, mFocusY = 0;
    // The district under the middle of the view (the SDL view's viewed city) and the last of the player's own cities viewed:
    // the pages, the Build menu and the header follow the player's city in view. The leader's name fills the messages.
    eCityId mViewedCity = eCityId::neutralFriendly, mPlayerCity = eCityId::neutralFriendly;
    std::string mPlayerName = "Hippodamus";
    // Where the view should go once (the SDL view's viewTile on the player's own invasion or god attack of a city on the map).
    bool mViewRequest = false; int mViewRequestX = 0, mViewRequestY = 0;
    double mAccumulator = 0;
    uint64_t mSequence = 0, mNextId = 1, mTicks = 0, mNextEvent = 1;
    std::map<const void*, uint64_t> mIds;
    // Presentation facing for new square buildings; save-facing migration is pending.
    std::map<const void*, int> mOrientations;
    std::vector<stdptr<eBuilding>> mUndoBuildings;
    int mUndoRefund = 0, mUndoGameTime = 0;
    std::chrono::steady_clock::time_point mUndoRealTime;
    stdptr<eBuilding> mDemolitionTarget;
    uint64_t mDemolitionToken = 0;
    stdptr<eBuilding> mInspectionTarget;
    // Monotonic across city reloads: an old inspector must never edit a new owner.
    uint64_t mInspectionToken = 0;
    // Last tile columns sent (altitude, terrain, road, geometry flags, character altitude),
    // flat and indexed by (y-mY)*mW+(x-mX). The per-tile build-eligibility column is
    // deliberately not part of change detection: it flips whenever a walker steps onto
    // or off a tile and is only observed in full snapshots or when a tile is re-sent
    // for another reason. Authoritative placement uses the `preview` query.
    std::vector<std::array<int,6>> mTerrainState;
    std::vector<uint8_t> mTerrainKnown;
    // Serialized building records keyed by native object. A snapshot re-sends the
    // building list only when a record was added, changed or removed.
    struct BuildingRecord {
        std::string asset, json;
        int type = 0, x = 0, y = 0, w = 0, h = 0, orientation = 0, altitude = 0;
        int workers = 0, animationOffset = 0, grow = 100;
        bool stretch = false;
        bool active = false, working = false, emit = false;
        uint64_t id = 0, seen = 0;
        std::string storageBays;
    };
    std::unordered_map<const eBuilding*, BuildingRecord> mBuildingCache;
    uint64_t mGeneration = 0;
    // Microsecond timings of the most recent snapshot and the slowest native tick.
    // Read-only observations for the performance gate; they never affect state.
    struct Profile {
        double tiles = 0, buildings = 0, walkers = 0, events = 0, total = 0, maxTotal = 0;
        double tickMax = 0, tickSum = 0; uint64_t tickMaxAt = 0;
        uint64_t snapshots = 0, ticks = 0;
    } mProfile;
    // Microseconds spent in each phase of open(): setup, textures, read, board, scan, snapshot,
    // then the sub-phases of the save read: format, view, campaign, strings.
    std::array<double,10> mOpenProfile{};
    struct Event { std::string title, text, brief; eEventData data; std::string kind; };
    std::map<uint64_t, Event> mEvents;
    std::mutex mSoundLock;
    std::vector<std::string> mSounds;
    std::string mMusicMode = "city";
    std::string mSentBanners;
    std::shared_ptr<eEnlistSession> mEnlist;
};
