#include "egamewidget.h"

#include "eiteratesquare.h"
#include "engine/egameboard.h"

#include "eterraineditmenu.h"
#include "engine/eterrainedit.h"

#include "buildings/allbuildings.h"

#include "characters/esheep.h"
#include "characters/egoat.h"
#include "characters/ecattle.h"

#include "evectorhelpers.h"
#include "spawners/eboarspawner.h"
#include "spawners/edeerspawner.h"
#include "spawners/eentrypoint.h"
#include "spawners/eexitpoint.h"
#include "spawners/emonsterpoint.h"
#include "spawners/elandinvasionpoint.h"
#include "spawners/eseainvasionpoint.h"
#include "spawners/edisembarkpoint.h"
#include "spawners/edisasterpoint.h"
#include "spawners/elandslidepoint.h"

#include "ebuildingstoerase.h"
#include "engine/eagoraplacement.h"
#include "engine/eshoreplacement.h"
#include "engine/ebuildplacement.h"

#include "elanguage.h"
#include "estringhelpers.h"
#include "audio/esounds.h"

#include <algorithm>

std::vector<eTile*> eGameWidget::agoraBuildPlaceIter(
        eTile* const tile, const bool grand,
        eAgoraOrientation& bt, const eCityId cid,
        const ePlayerId pid) const {
    return eAgoraPlacement::find(*mBoard, tile, grand, bt, cid, pid, mEditorMode);
}

template <class T>
bool buildVendor(eGameBoard& brd, const int tx, const int ty,
                 const eResourceType resType, const eCityId cid) {
    return eAgoraPlacement::placeVendor(brd, tx, ty, resType, cid,
        [](eGameBoard& b, const eCityId c) -> stdsptr<eVendor> { return e::make_shared<T>(b, c); });
}

eGameWidget::eApply eGameWidget::editFunc() {
    // The tools' changes are shared with the Godot editor (engine/eterrainedit).
    const auto pressed = mBoard->tile(mPressedTX, mPressedTY);
    return eTerrainEdit::apply(*mBoard, mTem->mode(), mTem->modeId(), mInflTiles, pressed, mViewedCityId);
}

bool eGameWidget::buildMouseRelease() {
    const auto cid = (mViewedCityId != eCityId::neutralFriendly) ? mViewedCityId : mBoard->currentCityId();
    const auto pid = mBoard->personPlayer();

    const auto& wrld = mBoard->world();
    const auto ppid = mBoard->personPlayer();
    eApply apply;
    bool r = false;
    const auto mode = mGm->mode();
    if(mTem->visible()) {
//        const auto brushType = mTem->brushType();
//        if(brushType != eBrushType::apply) return true;
        apply = editFunc();
        if(!apply) {
            mInflTiles.clear();
            return true;
        }
    } else {
        const int d = mBoard->drachmas(ppid);
        if(mode != eBuildingMode::none && d < -1000) {
            showTip(pid, eLanguage::zeusText(19, 19)); // out of credit
            return false;
        }
        switch(mode) {
        case eBuildingMode::none: {
            return false;
        } break;
        case eBuildingMode::erase: {
            eBuildingsToErase eraser;

            const int minX = std::min(mPressedTX, mHoverTX);
            const int minY = std::min(mPressedTY, mHoverTY);
            const int maxX = std::max(mPressedTX, mHoverTX);
            const int maxY = std::max(mPressedTY, mHoverTY);

            const auto diff = mBoard->difficulty(ppid);
            const int cost = eDifficultyHelpers::buildingCost(
                                 diff, eBuildingType::erase);
            int totalCost = 0;
            for(int x = minX; x <= maxX; x++) {
                for(int y = minY; y <= maxY; y++) {
                    const auto tile = mBoard->tile(x, y);
                    if(!tile) continue;
                    const auto cid = tile->cityId();
                    const auto pid = mBoard->cityIdToPlayerId(cid);
                    if(pid != ppid && !mEditorMode) continue;
                    if(const auto b = tile->underBuilding()) {
                        if(b->isOnFire()) continue;
                        eraser.addBuilding(b);
                    } else {
                        const auto t = tile->terrain();
                        if(t == eTerrain::forest || t == eTerrain::choppedForest) {
                            tile->setTerrain(eTerrain::dry);
                            const auto c = mBoard->boardCityWithId(cid);
                            if(c) c->incForestsState();
                            totalCost += cost;
                        }
                    }
                }
            }

            const int nErased = eraser.erase(false);
            totalCost += cost*nErased;
            if(!mEditorMode) mBoard->incDrachmas(ppid, -totalCost, eFinanceTarget::construction);
            mBoard->scheduleTerrainUpdate();

            std::string title;
            std::string text;
            if(eraser.hasImportantBuildings()) {
                title = eLanguage::zeusText(5, 104);
                text = eLanguage::zeusText(5, 105);
            } else if(eraser.hasNonEmptyAgoras()) {
                title = eLanguage::zeusText(5, 16);
                text = eLanguage::zeusText(5, 17);
            } else {
                return false;
            }
            const auto acceptA = [this, ppid, cost, eraser]() {
                auto e = eraser;
                const int nErased = e.erase(true);
                const int totalCost = cost*nErased;
                if(!mEditorMode) mBoard->incDrachmas(ppid, -totalCost, eFinanceTarget::construction);
            };
            showQuestion(title, text, acceptA);
        } break;
        case eBuildingMode::commonAgora:
        case eBuildingMode::grandAgora: {
            const bool grand = mode == eBuildingMode::grandAgora;
            const auto t = mBoard->tile(mHoverTX, mHoverTY);
            if(!t) return false;
            eAgoraOrientation bt;
            const auto p = eAgoraPlacement::find(*mBoard, t, grand, bt, cid, pid, mEditorMode);
            if(p.empty()) return false;
            const auto b = eAgoraPlacement::build(*mBoard, p, grand, bt, mViewedCityId);
            r = true;
            if(!mEditorMode) {
                const auto diff = mBoard->difficulty(ppid);
                const int cost = eDifficultyHelpers::buildingCost(diff, b->type());
                mBoard->incDrachmas(ppid, -cost, eFinanceTarget::construction);
            }
            showTip(cid, eLanguage::zeusText(19, 228)); // add vendors
        } break;
        case eBuildingMode::road: {
            const auto startTile = mBoard->tile(mHoverTX, mHoverTY);
            if(!startTile) return false;
            std::vector<eOrientation> path;
            const bool r = roadPath(path);
            if(r) {
                eTile* t = startTile;
                for(int i = path.size() - 1; i >= 0; i--) {
                    if(!t) break;
                    mBoard->build(t->x(), t->y(), 1, 1, cid, pid, mEditorMode,
                          [this]() { return e::make_shared<eRoad>(*mBoard, mViewedCityId); },
                          false, true);
                    t = t->neighbour<eTile>(path[i]);
                }
                if(t) {
                    mBoard->build(t->x(), t->y(), 1, 1, cid, pid, mEditorMode,
                          [this]() { return e::make_shared<eRoad>(*mBoard, mViewedCityId); },
                          false, true);
                }
            } else {
                mBoard->build(startTile->x(), startTile->y(), 1, 1, cid, pid, mEditorMode,
                      [this]() { return e::make_shared<eRoad>(*mBoard, mViewedCityId); },
                      false, true);
            }
        } break;
        case eBuildingMode::roadblock: {
            eBuildPlacement::placeRoadblock(mBoard->tile(mHoverTX, mHoverTY));
        } break;
        case eBuildingMode::bridge: {
            const auto startTile = mBoard->tile(mHoverTX, mHoverTY);
            if(!startTile) return false;
            std::vector<eTile*> path;
            bool rotated;
            bool r = bridgeTiles(startTile, eTerrain::water, path, rotated);
            if(!r) r = bridgeTiles(startTile, eTerrain::quake, path, rotated);
            if(r) eBuildPlacement::buildBridge(*mBoard, path, mViewedCityId, ppid, mEditorMode);
        } break;
        case eBuildingMode::commonHousing: {
            if(mPressedTX == mHoverTX && mPressedTY == mHoverTY) {
                const auto t = mBoard->tile(mHoverTX, mHoverTY);
                if(t && mBoard->canBuild(t->x(), t->y(), 2, 2, mEditorMode, cid, pid)) {
                    r = mBoard->build(t->x(), t->y(), 2, 2, cid, pid, mEditorMode,
                          [this, cid]() { return e::make_shared<eSmallHouse>(*mBoard, cid); });
                }
            } else {
                const int dxStep = (mHoverTX >= mPressedTX ? 2 : -2);
                const int dyStep = (mHoverTY >= mPressedTY ? 2 : -2);
                for(int x = mPressedTX; (dxStep > 0 ? x <= mHoverTX : x >= mHoverTX); x += dxStep) {
                    for(int y = mPressedTY; (dyStep > 0 ? y <= mHoverTY : y >= mHoverTY); y += dyStep) {
                        const int d = mBoard->drachmas(ppid);
                        if(!mEditorMode && d < -1000) break;
                        const auto t = mBoard->tile(x, y);
                        if(t && mBoard->canBuild(x, y, 2, 2, mEditorMode, cid, pid)) {
                            r = mBoard->build(x, y, 2, 2, cid, pid, mEditorMode,
                                  [this, cid]() { return e::make_shared<eSmallHouse>(*mBoard, cid); }) || r;
                        }
                    }
                }
            }
        } break;
        case eBuildingMode::gymnasium: {
            r = mBoard->build(mHoverTX, mHoverTY, 3, 3, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eGymnasium>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::podium: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<ePodium>(*mBoard, mViewedCityId); });

            if(!mBoard->hasBuilding(mViewedCityId, eBuildingType::college)) {
                showTip(cid, eLanguage::zeusText(19, 223)); // build college
            }
        } break;


        case eBuildingMode::bibliotheke: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eBibliotheke>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::observatory: {
            r = mBoard->build(mHoverTX, mHoverTY, 5, 5, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eObservatory>(*mBoard, mViewedCityId); });

            if(!mBoard->hasBuilding(mViewedCityId, eBuildingType::university)) {
                showTip(cid, eLanguage::zeusText(19, 244)); // build university
            }
        } break;
        case eBuildingMode::university: {
            r = mBoard->build(mHoverTX, mHoverTY, 3, 3, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eUniversity>(*mBoard, mViewedCityId); });

            if(!mBoard->hasBuilding(mViewedCityId, eBuildingType::observatory)) {
                showTip(cid, eLanguage::zeusText(19, 243)); // build observatory
            }
        } break;
        case eBuildingMode::laboratory: {
            r = mBoard->build(mHoverTX, mHoverTY, 4, 4, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eLaboratory>(*mBoard, mViewedCityId); });

            if(!mBoard->hasBuilding(mViewedCityId, eBuildingType::inventorsWorkshop)) {
                showTip(cid, eLanguage::zeusText(19, 247)); // build inventors' workshop
            }
        } break;
        case eBuildingMode::inventorsWorkshop: {
            r = mBoard->build(mHoverTX, mHoverTY, 3, 3, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eInventorsWorkshop>(*mBoard, mViewedCityId); });

            if(!mBoard->hasBuilding(mViewedCityId, eBuildingType::laboratory)) {
                showTip(cid, eLanguage::zeusText(19, 246)); // build laboratory
            }
        } break;
        case eBuildingMode::museum: {
            r = mBoard->build(mHoverTX, mHoverTY, 6, 6, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eMuseum>(*mBoard, mViewedCityId); });

            if(!mBoard->hasBuilding(mViewedCityId, eBuildingType::university)) {
                showTip(cid, eLanguage::zeusText(19, 248)); // build universities
            }
            mGm->clearMode();
        } break;

        case eBuildingMode::fountain: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eFountain>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::watchpost: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eWatchpost>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::maintenanceOffice: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eMaintenanceOffice>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::college: {
            r = mBoard->build(mHoverTX, mHoverTY, 3, 3, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eCollege>(*mBoard, mViewedCityId); });

            if(!mBoard->hasBuilding(mViewedCityId, eBuildingType::podium)) {
                showTip(cid, eLanguage::zeusText(19, 222)); // build podiums
            }
        } break;
        case eBuildingMode::dramaSchool: {
            r = mBoard->build(mHoverTX, mHoverTY, 3, 3, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eDramaSchool>(*mBoard, mViewedCityId); });

            if(!mBoard->hasBuilding(mViewedCityId, eBuildingType::theater)) {
                showTip(cid, eLanguage::zeusText(19, 225)); // build theater
            }
        } break;
        case eBuildingMode::theater: {
            r = mBoard->build(mHoverTX, mHoverTY, 5, 5, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eTheater>(*mBoard, mViewedCityId); });

            if(!mBoard->hasBuilding(mViewedCityId, eBuildingType::dramaSchool)) {
                showTip(cid, eLanguage::zeusText(19, 226)); // build a drama school
            }
        } break;
        case eBuildingMode::hospital: {
            r = mBoard->build(mHoverTX, mHoverTY, 4, 4, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eHospital>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::stadium: {
            if(mBoard->hasStadium(mViewedCityId)) return true;
            if(!eBuildPlacement::canBuildStadium(*mBoard, mHoverTX, mHoverTY, mRotate, cid, pid, mEditorMode)) return true;
            r = eBuildPlacement::buildStadium(*mBoard, mHoverTX, mHoverTY, mRotate, mViewedCityId, pid, mEditorMode);
            mGm->clearMode();

            if(!mBoard->hasBuilding(mViewedCityId, eBuildingType::gymnasium)) {
                showTip(cid, eLanguage::zeusText(19, 227)); // build gymnsaium
            }
        } break;
        case eBuildingMode::palace: {
            if(mBoard->hasPalace(mViewedCityId)) return true;
            if(mBoard->hasActiveInvasions(mViewedCityId)) {
                showTip(cid, eLanguage::zeusText(19, 33)); // too close to enemy
                return true;
            }
            if(!eBuildPlacement::canBuildPalace(*mBoard, mHoverTX, mHoverTY, mRotate, cid, pid, mEditorMode)) return true;
            r = eBuildPlacement::buildPalace(*mBoard, mHoverTX, mHoverTY, mRotate, mViewedCityId, pid, mEditorMode);

            mGm->clearMode();
        } break;
        case eBuildingMode::eliteHousing: {
            if(mPressedTX == mHoverTX && mPressedTY == mHoverTY) {
                const auto t1 = mBoard->tile(mHoverTX, mHoverTY);
                if(!t1) return true;
                const bool cb = mBoard->canBuild(t1->x() + 1, t1->y() + 1, 4, 4, mEditorMode, cid, pid);
                if(!cb) return true;
                r = mBoard->build(t1->x() + 1, t1->y() + 1, 4, 4, cid, pid, mEditorMode, [&, cid]() {
                    return e::make_shared<eEliteHousing>(*mBoard, cid);
                });
            } else {
                const int dxStep = (mHoverTX >= mPressedTX ? 4 : -4);
                const int dyStep = (mHoverTY >= mPressedTY ? 4 : -4);
                for(int x = mPressedTX; (dxStep > 0 ? x <= mHoverTX : x >= mHoverTX); x += dxStep) {
                    for(int y = mPressedTY; (dyStep > 0 ? y <= mHoverTY : y >= mHoverTY); y += dyStep) {
                        const int d = mBoard->drachmas(ppid);
                        if(!mEditorMode && d < -1000) break;
                        const auto t = mBoard->tile(x, y);
                        if(t && mBoard->canBuild(x + 1, y + 1, 4, 4, mEditorMode, cid, pid)) {
                            r = mBoard->build(x + 1, y + 1, 4, 4, cid, pid, mEditorMode, [&, cid]() {
                                return e::make_shared<eEliteHousing>(*mBoard, cid);
                            }) || r;
                        }
                    }
                }
            }
        } break;
        case eBuildingMode::taxOffice: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eTaxOffice>(*mBoard, mViewedCityId); });
            if(!mBoard->hasPalace(mViewedCityId)) {
                showTip(cid, eLanguage::zeusText(19, 221));
            }
        } break;
        case eBuildingMode::mint: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eMint>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::foundry: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eFoundry>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::timberMill: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eTimberMill>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::masonryShop: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eMasonryShop>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::refinery: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eRefinery>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::blackMarbleWorkshop: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eBlackMarbleWorkshop>(*mBoard, mViewedCityId); });
        } break;


        case eBuildingMode::oliveTree:
            apply = [this, cid, pid](eTile* const tile) {
                mBoard->build(tile->x(), tile->y(), 1, 1, cid, pid, mEditorMode,
                      [this]() { return e::make_shared<eResourceBuilding>(
                                *mBoard, eResourceBuildingType::oliveTree, mViewedCityId); },
                      true, true);
            };
            break;
        case eBuildingMode::vine:
            apply = [this, cid, pid](eTile* const tile) {
                mBoard->build(tile->x(), tile->y(), 1, 1, cid, pid, mEditorMode,
                      [this]() { return e::make_shared<eResourceBuilding>(
                                *mBoard, eResourceBuildingType::vine, mViewedCityId); },
                      true, true);
            };
            break;
        case eBuildingMode::orangeTree:
            apply = [this, cid, pid](eTile* const tile) {
                mBoard->build(tile->x(), tile->y(), 1, 1, cid, pid, mEditorMode,
                      [this]() { return e::make_shared<eResourceBuilding>(
                                *mBoard, eResourceBuildingType::orangeTree, mViewedCityId); },
                      true, true);
            };
            break;


        case eBuildingMode::huntingLodge: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eHuntingLodge>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::corral: {
            r = mBoard->build(mHoverTX, mHoverTY, 4, 4, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eCorral>(*mBoard, mViewedCityId); });

            if(!mBoard->hasBuilding(mViewedCityId, eBuildingType::cattle)) {
                showTip(cid, eLanguage::zeusText(19, 255));
                showTip(cid, eLanguage::zeusText(19, 256));
            }
        } break;


        case eBuildingMode::urchinQuay:
        case eBuildingMode::fishery: {
            eDiagonalOrientation o;
            const bool c = canBuildFishery(mHoverTX, mHoverTY, o);
            if(c) {
                r = true;
                const auto type = mode == eBuildingMode::urchinQuay ? eBuildingType::urchinQuay : eBuildingType::fishery;
                eBuildPlacement::placeShoreBuilding(*mBoard, type, mHoverTX, mHoverTY, o, mViewedCityId, ppid, mEditorMode);
            }
        } break;
        case eBuildingMode::triremeWharf: {
            eDiagonalOrientation o;
            const bool c = canBuildTriremeWharf(mHoverTX, mHoverTY, o);
            if(c) {
                r = true;
                if(eBuildPlacement::triremeWharfSeaAccess(*mBoard, mHoverTX, mHoverTY, mViewedCityId)) {
                    eBuildPlacement::placeShoreBuilding(*mBoard, eBuildingType::triremeWharf, mHoverTX, mHoverTY, o, mViewedCityId, ppid, mEditorMode);
                } else {
                    showTip(cid, eLanguage::zeusText(19, 25));
                }
            }
        } break;


        case eBuildingMode::pier: {
            eDiagonalOrientation o;
            const bool c = canBuildPier(mHoverTX, mHoverTY, o, cid, pid, mEditorMode);
            if(c) {
                r = true;
                if(eShorePlacement::pierHasSeaAccess(*mBoard, mHoverTX, mHoverTY, mViewedCityId)) {
                    const int ctid = mGm->tradeCityId();
                    const auto& cts = wrld.cities();
                    const auto ct = cts[ctid];
                    eShorePlacement::placePier(*mBoard, mHoverTX, mHoverTY, o, *ct, mViewedCityId, pid, mEditorMode);
                    mGm->clearMode();
                } else {
                    showTip(cid, eLanguage::zeusText(19, 25));
                }
            }
        } break;


        case eBuildingMode::dairy: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eDairy>(*mBoard, mViewedCityId); });

            if(!mBoard->hasBuilding(mViewedCityId, eBuildingType::goat)) {
                showTip(cid, eLanguage::zeusText(19, 219));
                showTip(cid, eLanguage::zeusText(19, 220));
            }
        } break;
        case eBuildingMode::cardingShed: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eCardingShed>(*mBoard, mViewedCityId); });

            if(!mBoard->hasBuilding(mViewedCityId, eBuildingType::sheep)) {
                showTip(cid, eLanguage::zeusText(19, 217));
                showTip(cid, eLanguage::zeusText(19, 218));
            }
        } break;

        case eBuildingMode::sheep: {
            const auto skip = std::make_shared<bool>(false);
            apply = [this, skip, pid, cid, &r](eTile* const tile) {
                if(*skip) return;
                const int allowed = mBoard->countAllowed(mViewedCityId, eBuildingType::sheep);
                if(allowed <= 0) {
                    showTip(cid, eLanguage::zeusText(19, 211));
                    showTip(cid, eLanguage::zeusText(19, 212));
                    *skip = true;
                    return;
                }
                r = mBoard->buildAnimal(tile, eBuildingType::sheep,
                            [](eGameBoard& board) {
                    return e::make_shared<eSheep>(board);
                }, mViewedCityId, pid, mEditorMode) || r;
            };
        } break;
        case eBuildingMode::goat: {
            const auto skip = std::make_shared<bool>(false);
            apply = [this, skip, pid, cid, &r](eTile* const tile) {
                if(*skip) return;
                const int allowed = mBoard->countAllowed(mViewedCityId, eBuildingType::goat);
                if(allowed <= 0) {
                    showTip(cid, eLanguage::zeusText(19, 215));
                    showTip(cid, eLanguage::zeusText(19, 216));
                    *skip = true;
                    return;
                }
                r = mBoard->buildAnimal(tile, eBuildingType::goat,
                            [](eGameBoard& board) {
                    return e::make_shared<eGoat>(board);
                }, mViewedCityId, pid, mEditorMode) || r;
            };
        } break;
        case eBuildingMode::cattle: {
            const auto skip = std::make_shared<bool>(false);
            apply = [this, skip, pid, cid, &r](eTile* const tile) {
                if(*skip) return;
                const int allowed = mBoard->countAllowed(mViewedCityId, eBuildingType::cattle);
                if(allowed <= 0) {
                    showTip(cid, eLanguage::zeusText(19, 252));
                    showTip(cid, eLanguage::zeusText(19, 253));
                    *skip = true;
                    return;
                }
                r = mBoard->buildAnimal(tile, eBuildingType::cattle,
                            [](eGameBoard& board) {
                    return e::make_shared<eCattle>(
                                board, eCharacterType::cattle2);
                }, mViewedCityId, pid, mEditorMode) || r;
            };
        } break;

        case eBuildingMode::wheatFarm: {
            r = mBoard->build(mHoverTX, mHoverTY, 3, 3, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eWheatFarm>(*mBoard, mViewedCityId); },
                  true);
        } break;
        case eBuildingMode::onionFarm: {
            r = mBoard->build(mHoverTX, mHoverTY, 3, 3, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eOnionFarm>(*mBoard, mViewedCityId); },
                  true);
        } break;
        case eBuildingMode::carrotFarm: {
            r = mBoard->build(mHoverTX, mHoverTY, 3, 3, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eCarrotFarm>(*mBoard, mViewedCityId); },
                  true);
        } break;
        case eBuildingMode::growersLodge: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eGrowersLodge>(
                            *mBoard, eGrowerType::grapesAndOlives, mViewedCityId); });
            if(mBoard->supportsBuilding(mViewedCityId, eBuildingMode::oliveTree) &&
               !mBoard->hasBuilding(mViewedCityId, eBuildingType::oliveTree)) {
                showTip(cid, eLanguage::zeusText(19, 200));
            }

            if(mBoard->supportsBuilding(mViewedCityId, eBuildingMode::vine) &&
               !mBoard->hasBuilding(mViewedCityId, eBuildingType::vine)) {
                showTip(cid, eLanguage::zeusText(19, 198));
            }
        } break;
        case eBuildingMode::orangeTendersLodge: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eGrowersLodge>(
                            *mBoard, eGrowerType::oranges, mViewedCityId); });
        } break;

        case eBuildingMode::granary: {
            r = mBoard->build(mHoverTX, mHoverTY, 4, 4, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eGranary>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::warehouse: {
            r = mBoard->build(mHoverTX, mHoverTY, 3, 3, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eWarehouse>(*mBoard, mViewedCityId); });
        } break;

        case eBuildingMode::tradePost: {
            const int ctid = mGm->tradeCityId();
            const auto cts = wrld.cities();
            const auto ct = cts[ctid];
            r = mBoard->build(mHoverTX, mHoverTY, 4, 4, cid, pid, mEditorMode,
                  [this, ct]() {
                const auto tp = e::make_shared<eTradePost>(*mBoard, *ct, mViewedCityId);
                return tp;
            });
            mGm->clearMode();
        } break;


        case eBuildingMode::wall: {
            const int minX = std::min(mPressedTX, mHoverTX);
            const int maxX = std::max(mPressedTX, mHoverTX);
            const int minY = std::min(mPressedTY, mHoverTY);
            const int maxY = std::max(mPressedTY, mHoverTY);
            const bool fill = (SDL_GetModState() & KMOD_SHIFT) != 0;

            for(int x = minX; x <= maxX; x++) {
                for(int y = minY; y <= maxY; y++) {
                    if(!fill && x != minX && x != maxX && y != minY && y != maxY) {
                        continue;
                    }
                    const int d = mBoard->drachmas(ppid);
                    if(!mEditorMode && d < -1000) break;

                    const auto t = mBoard->tile(x, y);
                    if(!t) continue;
                    r = mBoard->build(x, y, 1, 1, cid, pid, mEditorMode,
                          [this, cid]() { return e::make_shared<eWall>(*mBoard, cid); }) || r;
                }
            }
        } break;
        case eBuildingMode::tower: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eTower>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::gatehouse: {
            int dx;
            int dy;
            int sw;
            int sh;
            if(mRotate) {
                dx = 0;
                dy = 3;
                sw = 2;
                sh = 5;
            } else {
                dx = 3;
                dy = 0;
                sw = 5;
                sh = 2;
            }
            const int tx = mHoverTX;
            const int ty = mHoverTY - 1;
            int ttx = tx;
            int tty = ty;
            const bool cb1 = mBoard->canBuildBase(ttx, ttx + 2, tty, tty + 2,
                                                  mEditorMode, cid, pid);
            if(!cb1) return true;
            std::vector<eTile*> roadTiles;

            if(sw == 2) {
                const auto t2 = mBoard->tile(tx, ty + 2);
                if(!t2) return true;
                roadTiles.push_back(t2);
                const auto t3 = t2->tileRel<eTile>(1, 0);
                if(!t3) return true;
                roadTiles.push_back(t3);
            } else {
                const auto t2 = mBoard->tile(tx + 2, ty);
                if(!t2) return true;
                roadTiles.push_back(t2);
                const auto t3 = t2->tileRel<eTile>(0, 1);
                if(!t3) return true;
                roadTiles.push_back(t3);
            }

            for(const auto t : roadTiles) {
                if(!t) return true;
                if(t->hasRoad()) continue;
                const bool cb = mBoard->canBuildBase(t->x(), t->x() + 1, t->y(), t->y() + 1,
                                                     mEditorMode, cid, pid);
                if(!cb) return true;
            }

            ttx = tx + dx;
            tty = ty + dy;
            const bool cb2 = mBoard->canBuildBase(ttx, ttx + 2, tty, tty + 2,
                                                  mEditorMode, cid, pid);
            if(!cb2) return true;
            const auto b1 = e::make_shared<eGatehouse>(*mBoard, mRotate, mViewedCityId);

            b1->setTileRect({tx, ty, sw, sh});
            const int minX = tx;
            const int maxX = tx + sw;
            const int minY = ty;
            const int maxY = ty + sh;
            for(int x = minX; x < maxX; x++) {
                for(int y = minY; y < maxY; y++) {
                    const auto t = mBoard->tile(x, y);
                    if(t) {
                        t->setUnderBuilding(b1);
                        b1->setCenterTile(t);
                        b1->addUnderBuilding(t);
                    }
                }
            }

            for(const auto r : roadTiles) {
                const auto r2 = e::make_shared<eRoad>(*mBoard, mViewedCityId);
                r2->setTileRect({r->x(), r->y(), 1, 1});
                r2->setUnderGatehouse(b1.get());
                r2->addUnderBuilding(r);
                r->setUnderBuilding(r2);
                r2->setCenterTile(r);
            }
            r = true;
            if(!mEditorMode) {
                const auto diff = mBoard->difficulty(ppid);
                const int cost = eDifficultyHelpers::buildingCost(
                                     diff, eBuildingType::gatehouse);
                mBoard->incDrachmas(ppid, -cost, eFinanceTarget::construction);
            }
        } break;

        case eBuildingMode::armory: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eArmory>(*mBoard, mViewedCityId); });
            showTip(cid, eLanguage::zeusText(19, 194));
            if(mBoard->supportsBuilding(mViewedCityId, eBuildingMode::foundry) &&
               !mBoard->hasBuilding(mViewedCityId, eBuildingType::foundry)) {
                showTip(cid, eLanguage::zeusText(19, 195));
            }
        } break;
        case eBuildingMode::horseRanch: {
            if(!eBuildPlacement::canBuildHorseRanch(*mBoard, mHoverTX, mHoverTY, mRotateId, cid, pid, mEditorMode)) return true;
            r = eBuildPlacement::buildHorseRanch(*mBoard, mHoverTX, mHoverTY, mRotateId, mViewedCityId, pid, mEditorMode);
            showTip(cid, eLanguage::zeusText(19, 187));
            if(mBoard->supportsBuilding(mViewedCityId, eBuildingMode::wheatFarm) &&
               !mBoard->hasBuilding(mViewedCityId, eBuildingType::wheatFarm)) {
                showTip(cid, eLanguage::zeusText(19, 188));
            }
        } break;
        case eBuildingMode::chariotFactory: {
           r = mBoard->build(mHoverTX, mHoverTY, 4, 4, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eChariotFactory>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::olivePress: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eOlivePress>(*mBoard, mViewedCityId); });
            showTip(cid, eLanguage::zeusText(19, 199));
            if(mBoard->supportsBuilding(mViewedCityId, eBuildingMode::oliveTree) &&
               !mBoard->hasBuilding(mViewedCityId, eBuildingType::oliveTree)) {
                showTip(cid, eLanguage::zeusText(19, 200));
            }
        } break;
        case eBuildingMode::winery: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eWinery>(*mBoard, mViewedCityId); });
            showTip(cid, eLanguage::zeusText(19, 197));
            if(mBoard->supportsBuilding(mViewedCityId, eBuildingMode::vine) &&
               !mBoard->hasBuilding(mViewedCityId, eBuildingType::vine)) {
                showTip(cid, eLanguage::zeusText(19, 198));
            }
        } break;
        case eBuildingMode::sculptureStudio: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eSculptureStudio>(*mBoard, mViewedCityId); });
            showTip(cid, eLanguage::zeusText(19, 196));
            if(mBoard->supportsBuilding(mViewedCityId, eBuildingMode::foundry) &&
               !mBoard->hasBuilding(mViewedCityId, eBuildingType::foundry)) {
                showTip(cid, eLanguage::zeusText(19, 195));
            }
        } break;

        case eBuildingMode::artisansGuild: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eArtisansGuild>(*mBoard, mViewedCityId); });
        } break;

        case eBuildingMode::foodVendor: {
            r = buildVendor<eFoodVendor>(*mBoard, mHoverTX, mHoverTY,
                                            eResourceType::food, mViewedCityId);
        } break;
        case eBuildingMode::fleeceVendor: {
            r = buildVendor<eFleeceVendor>(*mBoard, mHoverTX, mHoverTY,
                                              eResourceType::fleece, mViewedCityId);
        } break;
        case eBuildingMode::oilVendor: {
            r = buildVendor<eOilVendor>(*mBoard, mHoverTX, mHoverTY,
                                           eResourceType::oliveOil, mViewedCityId);
        } break;
        case eBuildingMode::wineVendor: {
            r = buildVendor<eWineVendor>(*mBoard, mHoverTX, mHoverTY,
                                            eResourceType::wine, mViewedCityId);
        } break;
        case eBuildingMode::armsVendor: {
            r = buildVendor<eArmsVendor>(*mBoard, mHoverTX, mHoverTY,
                                            eResourceType::armor, mViewedCityId);
        } break;
        case eBuildingMode::horseTrainer: {
            r = buildVendor<eHorseVendor>(*mBoard, mHoverTX, mHoverTY,
                                             eResourceType::horse, mViewedCityId);
        } break;
        case eBuildingMode::chariotVendor: {
            r = buildVendor<eChariotVendor>(*mBoard, mHoverTX, mHoverTY,
                                               eResourceType::chariot, mViewedCityId);
        } break;

        case eBuildingMode::park: {
            const int minX = std::min(mPressedTX, mHoverTX);
            const int maxX = std::max(mPressedTX, mHoverTX);
            const int minY = std::min(mPressedTY, mHoverTY);
            const int maxY = std::max(mPressedTY, mHoverTY);
            for(int x = minX; x <= maxX; x++) {
                for(int y = minY; y <= maxY; y++) {
                    const int d = mBoard->drachmas(ppid);
                    if(!mEditorMode && d < -1000) break;
                    r = mBoard->build(x, y, 1, 1, cid, pid, mEditorMode,
                          [this]() { return e::make_shared<ePark>(*mBoard, mViewedCityId); },
                          false, true) || r;
                }
            }
            mBoard->scheduleTerrainUpdate();
        } break;
        case eBuildingMode::doricColumn:
        case eBuildingMode::ionicColumn:
        case eBuildingMode::corinthianColumn: {
            switch(mode) {
            case eBuildingMode::doricColumn:
                apply = [this, cid, pid](eTile* const tile) {
                    mBoard->build(tile->x(), tile->y(), 1, 1, cid, pid, mEditorMode,
                          [this]() { return e::make_shared<eDoricColumn>(*mBoard, mViewedCityId); });
                };
                break;
            case eBuildingMode::ionicColumn:
                apply = [this, cid, pid](eTile* const tile) {
                    mBoard->build(tile->x(), tile->y(), 1, 1, cid, pid, mEditorMode,
                          [this]() { return e::make_shared<eIonicColumn>(*mBoard, mViewedCityId); });
                };
                break;
            case eBuildingMode::corinthianColumn:
            default:
                apply = [this, cid, pid](eTile* const tile) {
                    mBoard->build(tile->x(), tile->y(), 1, 1, cid, pid, mEditorMode,
                          [this]() { return e::make_shared<eCorinthianColumn>(*mBoard, mViewedCityId); });
                };
                break;
            }

            const auto startTile = mBoard->tile(mHoverTX, mHoverTY);
            if(!startTile) return false;
            std::vector<eOrientation> path;
            const bool r = columnPath(path);
            if(r) {
                eTile* t = startTile;
                for(int i = path.size() - 1; i >= 0; i--) {
                    if(!t) break;
                    apply(t);
                    t = t->neighbour<eTile>(path[i]);
                }
                if(t) apply(t);
            } else {
                apply(startTile);
            }
            return true;
        } break;
        case eBuildingMode::avenue:
        case eBuildingMode::boulevard: {
            const auto startTile = mBoard->tile(mHoverTX, mHoverTY);
            if(!startTile) return false;
            std::vector<eOrientation> path;
            const bool hasPath = roadPath(path);
            const bool boulevard = mode == eBuildingMode::boulevard;
            const auto plan = eBuildPlacement::avenuePlan(startTile, path, hasPath);
            r = eBuildPlacement::buildAvenue(*mBoard, plan, boulevard, cid, pid, mEditorMode) || r;
        } break;


        case eBuildingMode::populationMonument:
        case eBuildingMode::victoryMonument:
        case eBuildingMode::colonyMonument:
        case eBuildingMode::athleteMonument:
        case eBuildingMode::conquestMonument:
        case eBuildingMode::happinessMonument:
        case eBuildingMode::heroicFigureMonument:
        case eBuildingMode::diplomacyMonument:
        case eBuildingMode::scholarMonument: {
            int id = -1;
            switch(mode) {
            case eBuildingMode::populationMonument:
                id = 0;
                break;
            case eBuildingMode::victoryMonument:
                id = 1;
                break;
            case eBuildingMode::colonyMonument:
                id = 2;
                break;
            case eBuildingMode::athleteMonument:
                id = 3;
                break;
            case eBuildingMode::conquestMonument:
                id = 4;
                break;
            case eBuildingMode::happinessMonument:
                id = 5;
                break;
            case eBuildingMode::heroicFigureMonument:
                id = 6;
                break;
            case eBuildingMode::diplomacyMonument:
                id = 7;
                break;
            case eBuildingMode::scholarMonument:
                id = 8;
                break;
            default:
                id = -1;
                break;
            }
            const auto builder = [this, id]() {
                return e::make_shared<eCommemorative>(id, *mBoard, mViewedCityId);
            };
            const bool r = mBoard->build(mHoverTX, mHoverTY, 3, 3, cid, pid, mEditorMode, builder);
            if(r) {
                mBoard->built(mViewedCityId, eBuildingType::commemorative, id);
                const bool s = mBoard->supportsBuilding(mViewedCityId, mode);
                if(!s) mGm->clearMode();
            }
        } break;

        case eBuildingMode::aphroditeMonument:
        case eBuildingMode::apolloMonument:
        case eBuildingMode::aresMonument:
        case eBuildingMode::artemisMonument:
        case eBuildingMode::athenaMonument:
        case eBuildingMode::atlasMonument:
        case eBuildingMode::demeterMonument:
        case eBuildingMode::dionysusMonument:
        case eBuildingMode::hadesMonument:
        case eBuildingMode::hephaestusMonument:
        case eBuildingMode::heraMonument:
        case eBuildingMode::hermesMonument:
        case eBuildingMode::poseidonMonument:
        case eBuildingMode::zeusMonument: {
            if(!eBuildPlacement::canBuildGodMonument(*mBoard, mHoverTX, mHoverTY, cid, pid, mEditorMode)) return true;

            const auto am = eBuildingMode::aphroditeMonument;
            const int id = static_cast<int>(mode) -
                           static_cast<int>(am);
            const auto gt = static_cast<eGodType>(id);
            const bool b = eBuildPlacement::buildGodMonument(*mBoard, mHoverTX, mHoverTY, gt, cid, pid, mEditorMode);
            if(b) {
                mBoard->built(mViewedCityId, eBuildingType::godMonument, id);
                const bool ss = mBoard->supportsBuilding(mViewedCityId, mode);
                if(!ss) mGm->clearMode();
            }
        } break;

        case eBuildingMode::bench: {
            r = mBoard->build(mHoverTX, mHoverTY, 1, 1, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eBench>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::flowerGarden: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eFlowerGarden>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::gazebo: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eGazebo>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::hedgeMaze: {
            r = mBoard->build(mHoverTX, mHoverTY, 3, 3, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eHedgeMaze>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::fishPond: {
            r = mBoard->build(mHoverTX, mHoverTY, 4, 4, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eFishPond>(*mBoard, mViewedCityId); });
        } break;

        case eBuildingMode::waterPark: {
            r = mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode, [this]() {
                const auto b = e::make_shared<eWaterPark>(*mBoard, mViewedCityId);
                b->setId(rotationId());
                return b;
            });
        } break;

        case eBuildingMode::hippodromePiece: {
            updateHippodromeIds();
            const int hid = hippodromeId();
            if(hid == -1) {
                showTip(cid, eLanguage::zeusText(19, 257));
            } else {
                r = eBuildPlacement::buildHippodromePiece(*mBoard, mHoverTX, mHoverTY, hid, cid, pid, mEditorMode);
            }
        } break;

        case eBuildingMode::crosswalk: {
            if(!eBuildPlacement::buildCrosswalk(*mBoard, mHoverTX, mHoverTY, mViewedCityId, ppid, mEditorMode)) return true;
        } break;

        case eBuildingMode::birdBath: {
            r = mBoard->build(mHoverTX, mHoverTY, 1, 1, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eBirdBath>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::shortObelisk: {
            mBoard->build(mHoverTX, mHoverTY, 1, 1, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eShortObelisk>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::tallObelisk: {
            mBoard->build(mHoverTX, mHoverTY, 1, 1, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eTallObelisk>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::shellGarden: {
            mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eShellGarden>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::sundial: {
            mBoard->build(mHoverTX, mHoverTY, 2, 2, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eSundial>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::dolphinSculpture: {
            mBoard->build(mHoverTX, mHoverTY, 3, 3, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eDolphinSculpture>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::orrery: {
            mBoard->build(mHoverTX, mHoverTY, 3, 3, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eOrrery>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::spring: {
            r = mBoard->build(mHoverTX, mHoverTY, 3, 3, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eSpring>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::topiary: {
            r = mBoard->build(mHoverTX, mHoverTY, 3, 3, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eTopiary>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::baths: {
            r = mBoard->build(mHoverTX, mHoverTY, 4, 4, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eBaths>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::stoneCircle: {
            r = mBoard->build(mHoverTX, mHoverTY, 4, 4, cid, pid, mEditorMode,
                  [this]() { return e::make_shared<eStoneCircle>(*mBoard, mViewedCityId); });
        } break;
        case eBuildingMode::achillesHall:
        case eBuildingMode::atalantaHall:
        case eBuildingMode::bellerophonHall:
        case eBuildingMode::herculesHall:
        case eBuildingMode::jasonHall:
        case eBuildingMode::odysseusHall:
        case eBuildingMode::perseusHall:
        case eBuildingMode::theseusHall: {
            const auto hallType = eBuildingModeHelpers::toBuildingType(mode);
            const auto heroType = eHerosHall::sHallTypeToHeroType(hallType);
            const auto builder = [this, heroType]() {
                return e::make_shared<eHerosHall>(heroType, *mBoard, mViewedCityId);
            };
            const bool r = mBoard->build(mHoverTX, mHoverTY, 4, 4, cid, pid, mEditorMode, builder);
            if(r) {
                mBoard->built(mViewedCityId, hallType);
                mGm->clearMode();
            }
        } break;
        case eBuildingMode::templeAphrodite:
        case eBuildingMode::templeApollo:
        case eBuildingMode::templeAres:
        case eBuildingMode::templeArtemis:
        case eBuildingMode::templeAthena:
        case eBuildingMode::templeAtlas:
        case eBuildingMode::templeDemeter:
        case eBuildingMode::templeDionysus:
        case eBuildingMode::templeHades:
        case eBuildingMode::templeHephaestus:
        case eBuildingMode::templeHera:
        case eBuildingMode::templeHermes:
        case eBuildingMode::templePoseidon:
        case eBuildingMode::templeZeus: {
            const int maxSancts = mBoard->maxSanctuaries(cid);
            const auto sancts = mBoard->sanctuaries(cid);
            const int nBuilt = sancts.size();
            if(!mEditorMode && nBuilt >= maxSancts) {
                if(maxSancts < 2) showTip(cid, eLanguage::zeusText(19, 230));
                if(maxSancts == 2) showTip(cid, eLanguage::zeusText(19, 231));
                if(maxSancts == 3) showTip(cid, eLanguage::zeusText(19, 232));
                if(maxSancts == 4) showTip(cid, eLanguage::zeusText(19, 233));
                return false;
            }

            const auto bt = eBuildingModeHelpers::toBuildingType(mode);
            const int m = eBuilding::sInitialMarbleCost(bt);
            const int hasM = mBoard->resourceCount(mViewedCityId, eResourceType::marble);
            if(!mEditorMode && hasM < m) {
                auto text = eLanguage::zeusText(19, 201);
                const auto mStr = std::to_string(m);
                eStringHelpers::replace(text, "[warning_amount]", mStr);
                showTip(cid, text);
                if(mBoard->supportsBuilding(mViewedCityId, eBuildingMode::masonryShop)) {
                    showTip(cid, eLanguage::zeusText(19, 202));
                }
                return false;
            }

            const auto h = eSanctBlueprints::sSanctuaryBlueprint(bt, mRotate);

            const int sw = h->fW;
            const int sh = h->fH;

            const int minX = mHoverTX - sw/2;
            const int maxX = minX + sw;
            const int minY = mHoverTY - sh/2;
            const int maxY = minY + sh;

            r = mBoard->buildSanctuary(
                minX, maxX, minY, maxY,
                bt, mRotate, mViewedCityId, pid, mEditorMode);
            if(r) mGm->clearMode();
        } break;
        case eBuildingMode::modestPyramid:
        case eBuildingMode::pyramid:
        case eBuildingMode::greatPyramid:
        case eBuildingMode::majesticPyramid:

        case eBuildingMode::smallMonumentToTheSky:
        case eBuildingMode::monumentToTheSky:
        case eBuildingMode::grandMonumentToTheSky:

        case eBuildingMode::minorShrineAphrodite:
        case eBuildingMode::minorShrineApollo:
        case eBuildingMode::minorShrineAres:
        case eBuildingMode::minorShrineArtemis:
        case eBuildingMode::minorShrineAthena:
        case eBuildingMode::minorShrineAtlas:
        case eBuildingMode::minorShrineDemeter:
        case eBuildingMode::minorShrineDionysus:
        case eBuildingMode::minorShrineHades:
        case eBuildingMode::minorShrineHephaestus:
        case eBuildingMode::minorShrineHera:
        case eBuildingMode::minorShrineHermes:
        case eBuildingMode::minorShrinePoseidon:
        case eBuildingMode::minorShrineZeus:

        case eBuildingMode::shrineAphrodite:
        case eBuildingMode::shrineApollo:
        case eBuildingMode::shrineAres:
        case eBuildingMode::shrineArtemis:
        case eBuildingMode::shrineAthena:
        case eBuildingMode::shrineAtlas:
        case eBuildingMode::shrineDemeter:
        case eBuildingMode::shrineDionysus:
        case eBuildingMode::shrineHades:
        case eBuildingMode::shrineHephaestus:
        case eBuildingMode::shrineHera:
        case eBuildingMode::shrineHermes:
        case eBuildingMode::shrinePoseidon:
        case eBuildingMode::shrineZeus:

        case eBuildingMode::majorShrineAphrodite:
        case eBuildingMode::majorShrineApollo:
        case eBuildingMode::majorShrineAres:
        case eBuildingMode::majorShrineArtemis:
        case eBuildingMode::majorShrineAthena:
        case eBuildingMode::majorShrineAtlas:
        case eBuildingMode::majorShrineDemeter:
        case eBuildingMode::majorShrineDionysus:
        case eBuildingMode::majorShrineHades:
        case eBuildingMode::majorShrineHephaestus:
        case eBuildingMode::majorShrineHera:
        case eBuildingMode::majorShrineHermes:
        case eBuildingMode::majorShrinePoseidon:
        case eBuildingMode::majorShrineZeus:

        case eBuildingMode::pyramidToThePantheon:
        case eBuildingMode::altarOfOlympus:
        case eBuildingMode::templeOfOlympus:
        case eBuildingMode::observatoryKosmika:
        case eBuildingMode::museumAtlantika: {
            const auto type = eBuildingModeHelpers::toBuildingType(mode);
            const int m = eBuilding::sInitialMarbleCost(type);
            const int hasM = mBoard->resourceCount(mViewedCityId, eResourceType::marble);
            if(!mEditorMode && hasM < m) {
                auto text = eLanguage::zeusText(19, 201);
                const auto mStr = std::to_string(m);
                eStringHelpers::replace(text, "[warning_amount]", mStr);
                showTip(cid, text);
                if(mBoard->supportsBuilding(mViewedCityId, eBuildingMode::masonryShop)) {
                    showTip(cid, eLanguage::zeusText(19, 202));
                }
                return false;
            }

            int sw;
            int sh;
            ePyramid::sDimensions(type, sw, sh);

            const int minX = mHoverTX - sw/2;
            const int maxX = minX + sw;
            const int minY = mHoverTY - sh/2;
            const int maxY = minY + sh;

            const bool r = mBoard->buildPyramid(
                               minX, maxX, minY, maxY,
                               type, mRotate, mViewedCityId, pid,
                               mEditorMode);
            if(!r) return true;
            mGm->clearMode();
        } break;
        default:
            break;
        }
    }

    if(apply) {
        if(!mTem->visible() || mTem->brushType() == eBrushType::apply) {
            mInflTiles.clear();
            const int minX = std::min(mPressedTX, mHoverTX);
            const int minY = std::min(mPressedTY, mHoverTY);
            const int maxX = std::max(mPressedTX, mHoverTX);
            const int maxY = std::max(mPressedTY, mHoverTY);

            for(int x = minX; x <= maxX; x++) {
                for(int y = minY; y <= maxY; y++) {
                    const auto tile = mBoard->tile(x, y);
                    if(!tile) continue;
                    mInflTiles.push_back(tile);
                }
            }
        }
        for(const auto tile : mInflTiles) {
            apply(tile);
        }
        updateMaps(mInflTiles);
        mInflTiles.clear();
    }
    if(mTem->visible()) {
        if(eTerrainEdit::finish(*mBoard, mTem->mode())) {
            updateTopBottomAltitude();
            updateMinMaxAltitude();
        }
    }
    if(r) {
        const auto type = eBuildingModeHelpers::toBuildingType(mode);
        if(type != eBuildingType::road) {
            eSounds::playPlaceBuildingSound();
        }
        // eSounds::playSoundForBuilding(type);
    }
    return true;
}
