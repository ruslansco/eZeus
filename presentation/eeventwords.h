#pragma once
// The words of the events that the SDL view writes in its own handlers (eGameWidget::handleEvent and the handle*Event
// helpers in widgets/egamewidgetevents.cpp) from the god, monster, hero and city data an event carries, and that the
// message catalogue (eeventmessages.h) therefore has no entry for: the gods' visits, invasions, help, quests, disasters
// and trade resumptions, the monster timeline, the invasion timeline, the heroes' arrival, the completion of
// sanctuaries, pyramids, monuments and shrines, and the comply / too-late / refuse replies to the requests of other
// cities (which raise or lower their favour). This is the embedded core's copy of that wording, from the same
// eMessages tables with the same substitutions, so a message reads the same in both views and follows the core's
// language; keep the two in step (validate_events.gd reads both). The god, monster and hero voices that go with a
// message are asked for as the SDL view asks for them (they reach the front end as file names, see `sounds`).
// playerInvasion and playerGodAttack are alerts only in the SDL view (a red tile in the event list, no message box):
// they are handled here as silent. Nothing here changes the simulation: the god-visit message cycle is the same
// presentation counter (eGodMessages::fLastMessage) that the SDL view keeps.
#include <string>
#include "emessages.h"
#include "estringhelpers.h"
#include "audio/esounds.h"
#include "characters/gods/egod.h"
#include "characters/heroes/ehero.h"
#include "characters/monsters/emonster.h"
#include "engine/eevent.h"
#include "engine/eeventdata.h"

namespace eEventWords {

enum class eResult { notHandled, silent, worded };

// A message with the event's reason in place of [reason_phrase] (or the message's own "no reason" text): what
// eGameWidget::showMessage does with an eEventMessageType.
inline eMessageType withReason(const eEventData& ed, const eEventMessageType& m) {
    eMessageType r = m;
    const auto reason = ed.fReason.empty() ? m.fNoReason : ed.fReason;
    eStringHelpers::replaceAll(r.fFull.fText, "[reason_phrase]", reason);
    eStringHelpers::replaceAll(r.fCondensed.fText, "[reason_phrase]", reason);
    return r;
}

// Title and text (and the condensed text the SDL view shows on its pop-up cards) for one of these events. `dry` only asks whether the event is one of them (nothing is played or
// counted and the event's data is not read). worded: title and text are set; silent: handled, nothing to show.
inline eResult eventText(const eEvent kind, eEventData& ed, std::string& title, std::string& text, const bool dry = false, std::string* brief = nullptr) {
    const auto& inst = eMessages::instance;
    eMessageType msg;
    const auto god = [&]() -> const eGodMessages* { return inst.godMessages(ed.fGod); };
    const auto monster = [&]() -> const eMonsterMessages* { return inst.monsterMessages(ed.fMonster); };
    switch(kind) {
    case eEvent::playerInvasion:
    case eEvent::playerGodAttack:
        return eResult::silent;

    case eEvent::godVisit: {
        if(dry) return eResult::worded;
        const auto gm = god(); if(!gm) return eResult::silent;
        int& lm = gm->fLastMessage;
        lm = lm > 2 ? 0 : (lm + 1);
        if(lm == 0) { eSounds::playGodSound(ed.fGod, eGodSound::wooing0); msg = gm->fWooing0; }
        else if(lm == 1) { eSounds::playGodSound(ed.fGod, eGodSound::jealousy1); msg = gm->fJealousy1; }
        else { eSounds::playGodSound(ed.fGod, eGodSound::jealousy2); msg = gm->fJealousy2; }
    } break;
    case eEvent::godInvasion: {
        if(dry) return eResult::worded;
        const auto gm = god(); if(!gm) return eResult::silent;
        msg = gm->fInvades;
        eSounds::playGodSound(ed.fGod, eGodSound::invade);
    } break;
    case eEvent::godHelp: {
        if(dry) return eResult::worded;
        const auto gm = god(); if(!gm) return eResult::silent;
        msg = withReason(ed, gm->fHelps);
        eSounds::playGodSound(ed.fGod, eGodSound::help);
    } break;
    case eEvent::godMonsterUnleash: {
        if(dry) return eResult::worded;
        const auto gm = god(); if(!gm) return eResult::silent;
        eSounds::playGodSound(ed.fGod, eGodSound::monster);
        msg = withReason(ed, gm->fMonster);
    } break;
    case eEvent::godQuest:
    case eEvent::godQuestFulfilled: {
        if(dry) return eResult::worded;
        const auto gm = god(); if(!gm) return eResult::silent;
        const bool fulfilled = kind == eEvent::godQuestFulfilled;
        eSounds::playGodSound(ed.fGod, fulfilled ? eGodSound::questFinished : eGodSound::quest);
        const eQuestMessages* qm = nullptr;
        switch(ed.fQuestId) {
        case eGodQuestId::godQuest1: qm = &gm->fQuest1; break;
        case eGodQuestId::godQuest2: qm = &gm->fQuest2; break;
        }
        if(!qm) return eResult::silent;
        msg = withReason(ed, fulfilled ? qm->fFulfilled : qm->fQuest);
        const auto hero = eHero::sHeroName(ed.fHero);
        for(auto* str : {&msg.fFull.fTitle, &msg.fFull.fText, &msg.fCondensed.fTitle, &msg.fCondensed.fText}) {
            eStringHelpers::replaceAll(*str, "[hero_needed]", hero);
        }
    } break;
    case eEvent::sanctuaryComplete: {
        if(dry) return eResult::worded;
        const auto gm = god(); if(!gm) return eResult::silent;
        msg = gm->fSanctuaryComplete;
    } break;
    case eEvent::godDisaster: {
        if(dry) return eResult::worded;
        const auto gm = god(); if(!gm) return eResult::silent;
        msg = gm->fDisaster;
    } break;
    case eEvent::godDisasterEnds: {
        if(dry) return eResult::worded;
        const auto gm = god(); if(!gm) return eResult::silent;
        msg = gm->fDisasterEnds;
    } break;
    case eEvent::godTradeResumes: {
        if(dry) return eResult::worded;
        if(ed.fGod == eGodType::zeus) msg = inst.fZeusTradeResumes;
        else if(ed.fGod == eGodType::poseidon) msg = inst.fPoseidonTradeResumes;
        else if(ed.fGod == eGodType::hermes) msg = inst.fHermesTradeResumes;
        else return eResult::silent;
    } break;
    case eEvent::heroArrival: {
        if(dry) return eResult::worded;
        const auto gm = inst.heroMessages(ed.fHero); if(!gm) return eResult::silent;
        eSounds::playHeroSound(ed.fHero, eHeroSound::arrived);
        msg = withReason(ed, gm->fArrival);
    } break;

    case eEvent::monsterInCity: {
        if(dry) return eResult::worded;
        const auto mm = monster(); if(!mm) return eResult::silent;
        eSounds::playMonsterSound(ed.fMonster, eMonsterSound::voice);
        msg = mm->fInCity;
    } break;
    case eEvent::monsterInvasionInitial: {
        if(dry) return eResult::worded;
        const auto mm = monster(); if(!mm) return eResult::silent;
        msg = mm->fInvasion36;
        const auto reason = ed.fReason.empty() ? mm->fMonsterAttackReason : ed.fReason;
        const auto time = std::to_string(ed.fTime);
        // Every occurrence: the chimera's text names the reason twice, and the SDL view's single replace leaves the second.
        eStringHelpers::replaceAll(msg.fFull.fText, "[reason_phrase]", reason);
        eStringHelpers::replaceAll(msg.fFull.fText, "[time_until_attack]", time);
        eStringHelpers::replaceAll(msg.fCondensed.fText, "[time_until_attack]", time);
    } break;
    case eEvent::monsterInvasion24: if(dry) return eResult::worded; if(const auto mm = monster()) msg = mm->fInvasion24; else return eResult::silent; break;
    case eEvent::monsterInvasion12: if(dry) return eResult::worded; if(const auto mm = monster()) msg = mm->fInvasion12; else return eResult::silent; break;
    case eEvent::monsterInvasion6: if(dry) return eResult::worded; if(const auto mm = monster()) msg = mm->fInvasion6; else return eResult::silent; break;
    case eEvent::monsterInvasion1: if(dry) return eResult::worded; if(const auto mm = monster()) msg = mm->fInvasion1; else return eResult::silent; break;
    case eEvent::monsterInvasion: {
        if(dry) return eResult::worded;
        const auto mm = monster(); if(!mm) return eResult::silent;
        eSounds::playMonsterSound(ed.fMonster, eMonsterSound::voice);
        msg = mm->fInvasion;
    } break;
    case eEvent::monsterSlain: if(dry) return eResult::worded; if(const auto mm = monster()) msg = mm->fSlain; else return eResult::silent; break;

    case eEvent::invasionInitial: if(dry) return eResult::worded; msg = eMessages::invasionMessage(inst.fInvasionInitial, ed.fReason, ed.fTime); break;
    case eEvent::invasion24: if(dry) return eResult::worded; msg = eMessages::invasionMessage(inst.fInvasion24, ed.fReason, 24); break;
    case eEvent::invasion12: if(dry) return eResult::worded; msg = eMessages::invasionMessage(inst.fInvasion12, ed.fReason, 12); break;
    case eEvent::invasion6: if(dry) return eResult::worded; msg = eMessages::invasionMessage(inst.fInvasion6, ed.fReason, 6); break;
    case eEvent::invasion1: if(dry) return eResult::worded; msg = eMessages::invasionMessage(inst.fInvasion1, ed.fReason, 1); break;
    case eEvent::invasion: if(dry) return eResult::worded; msg = eMessages::invasionMessage(inst.fInvasion, ed.fReason, 0); break;

    // Sanctuaries aside, the monuments' completion messages.
    case eEvent::modestPyramidComplete1: msg = inst.fModestPyramidComplete1; break;
    case eEvent::pyramidComplete2: msg = inst.fPyramidComplete2; break;
    case eEvent::greatPyramidComplete3: msg = inst.fGreatPyramidComplete3; break;
    case eEvent::majesticPyramidComplete4: msg = inst.fMajesticPyramidComplete4; break;
    case eEvent::smallMonumentToTheSkyComplete5: msg = inst.fSmallMonumentToTheSkyComplete5; break;
    case eEvent::monumentToTheSkyComplete6: msg = inst.fMonumentToTheSkyComplete6; break;
    case eEvent::grandMonumentToTheSkyComplete7: msg = inst.fGrandMonumentToTheSkyComplete7; break;
    case eEvent::minorShrineComplete8: msg = inst.fMinorShrineComplete8; break;
    case eEvent::shrineComplete9: msg = inst.fShrineComplete9; break;
    case eEvent::majorShrineComplete10: msg = inst.fMajorShrineComplete10; break;
    case eEvent::pyramidOfThePantheonComplete11: msg = inst.fPyramidOfThePantheonComplete11; break;
    case eEvent::altarOfOlympusComplete12: msg = inst.fAltarOfOlympusComplete12; break;
    case eEvent::templeOfOlympusComplete13: msg = inst.fTempleOfOlympusComplete13; break;
    case eEvent::observatoryKosmikaComplete14: msg = inst.fObservatoryKosmikaComplete14; break;
    case eEvent::museumAtlantikaComplete15: msg = inst.fMuseumAtlantikaComplete15; break;

    // Replies to the requests of other cities: the favour they bring or cost, with the reply as its reason.
    case eEvent::generalRequestAllyComply: msg = eMessages::favorMessage(inst.fGeneralRequestAllyS.fComply); break;
    case eEvent::generalRequestAllyTooLate: msg = eMessages::dfavorMessage(inst.fGeneralRequestAllyS.fTooLate); break;
    case eEvent::generalRequestAllyRefuse: msg = eMessages::dfavorMessage(inst.fGeneralRequestAllyS.fRefuse); break;
    case eEvent::generalRequestRivalComply: msg = eMessages::favorMessage(inst.fGeneralRequestRivalD.fComply); break;
    case eEvent::generalRequestRivalTooLate: msg = eMessages::dfavorMessage(inst.fGeneralRequestRivalD.fTooLate); break;
    case eEvent::generalRequestRivalRefuse: msg = eMessages::dfavorMessage(inst.fGeneralRequestRivalD.fRefuse); break;
    case eEvent::generalRequestSubjectComply: msg = eMessages::favorMessage(inst.fGeneralRequestSubjectP.fComply); break;
    case eEvent::generalRequestSubjectTooLate: msg = eMessages::dfavorMessage(inst.fGeneralRequestSubjectP.fTooLate); break;
    case eEvent::generalRequestSubjectRefuse: msg = eMessages::dfavorMessage(inst.fGeneralRequestSubjectP.fRefuse); break;
    case eEvent::generalRequestParentComply: msg = eMessages::favorMessage(inst.fGeneralRequestParentR.fComply); break;
    case eEvent::generalRequestParentTooLate: msg = eMessages::dfavorMessage(inst.fGeneralRequestParentR.fTooLate); break;
    case eEvent::generalRequestParentRefuse: msg = eMessages::dfavorMessage(inst.fGeneralRequestParentR.fRefuse); break;
    case eEvent::generalRequestTributeComply: msg = eMessages::favorMessage(inst.fTributeRequest.fComply); break;
    case eEvent::generalRequestTributeTooLate: msg = eMessages::dfavorMessage(inst.fTributeRequest.fTooLate); break;
    case eEvent::generalRequestTributeRefuse: msg = eMessages::dfavorMessage(inst.fTributeRequest.fRefuse); break;
    case eEvent::famineAllyComply: msg = eMessages::favorMessage(inst.fFamineAllyS.fComply); break;
    case eEvent::famineAllyTooLate: msg = eMessages::dfavorMessage(inst.fFamineAllyS.fTooLate); break;
    case eEvent::famineAllyRefuse: msg = eMessages::dfavorMessage(inst.fFamineAllyS.fRefuse); break;
    case eEvent::famineRivalComply: msg = eMessages::favorMessage(inst.fFamineRivalD.fComply); break;
    case eEvent::famineRivalTooLate: msg = eMessages::dfavorMessage(inst.fFamineRivalD.fTooLate); break;
    case eEvent::famineRivalRefuse: msg = eMessages::dfavorMessage(inst.fFamineRivalD.fRefuse); break;
    case eEvent::famineSubjectComply: msg = eMessages::favorMessage(inst.fFamineSubjectP.fComply); break;
    case eEvent::famineSubjectTooLate: msg = eMessages::dfavorMessage(inst.fFamineSubjectP.fTooLate); break;
    case eEvent::famineSubjectRefuse: msg = eMessages::dfavorMessage(inst.fFamineSubjectP.fRefuse); break;
    case eEvent::famineParentComply: msg = eMessages::favorMessage(inst.fFamineParentR.fComply); break;
    case eEvent::famineParentTooLate: msg = eMessages::dfavorMessage(inst.fFamineParentR.fTooLate); break;
    case eEvent::famineParentRefuse: msg = eMessages::dfavorMessage(inst.fFamineParentR.fRefuse); break;
    case eEvent::projectAllyComply: msg = eMessages::favorMessage(inst.fProjectAllyS.fComply); break;
    case eEvent::projectAllyTooLate: msg = eMessages::dfavorMessage(inst.fProjectAllyS.fTooLate); break;
    case eEvent::projectAllyRefuse: msg = eMessages::dfavorMessage(inst.fProjectAllyS.fRefuse); break;
    case eEvent::projectRivalComply: msg = eMessages::favorMessage(inst.fProjectRivalD.fComply); break;
    case eEvent::projectRivalTooLate: msg = eMessages::dfavorMessage(inst.fProjectRivalD.fTooLate); break;
    case eEvent::projectRivalRefuse: msg = eMessages::dfavorMessage(inst.fProjectRivalD.fRefuse); break;
    case eEvent::projectSubjectComply: msg = eMessages::favorMessage(inst.fProjectSubjectP.fComply); break;
    case eEvent::projectSubjectTooLate: msg = eMessages::dfavorMessage(inst.fProjectSubjectP.fTooLate); break;
    case eEvent::projectSubjectRefuse: msg = eMessages::dfavorMessage(inst.fProjectSubjectP.fRefuse); break;
    case eEvent::projectParentComply: msg = eMessages::favorMessage(inst.fProjectParentR.fComply); break;
    case eEvent::projectParentTooLate: msg = eMessages::dfavorMessage(inst.fProjectParentR.fTooLate); break;
    case eEvent::projectParentRefuse: msg = eMessages::dfavorMessage(inst.fProjectParentR.fRefuse); break;
    case eEvent::festivalAllyComply: msg = eMessages::favorMessage(inst.fFestivalAllyS.fComply); break;
    case eEvent::festivalAllyTooLate: msg = eMessages::dfavorMessage(inst.fFestivalAllyS.fTooLate); break;
    case eEvent::festivalAllyRefuse: msg = eMessages::dfavorMessage(inst.fFestivalAllyS.fRefuse); break;
    case eEvent::festivalRivalComply: msg = eMessages::favorMessage(inst.fFestivalRivalD.fComply); break;
    case eEvent::festivalRivalTooLate: msg = eMessages::dfavorMessage(inst.fFestivalRivalD.fTooLate); break;
    case eEvent::festivalRivalRefuse: msg = eMessages::dfavorMessage(inst.fFestivalRivalD.fRefuse); break;
    case eEvent::festivalSubjectComply: msg = eMessages::favorMessage(inst.fFestivalSubjectP.fComply); break;
    case eEvent::festivalSubjectTooLate: msg = eMessages::dfavorMessage(inst.fFestivalSubjectP.fTooLate); break;
    case eEvent::festivalSubjectRefuse: msg = eMessages::dfavorMessage(inst.fFestivalSubjectP.fRefuse); break;
    case eEvent::festivalParentComply: msg = eMessages::favorMessage(inst.fFestivalParentR.fComply); break;
    case eEvent::festivalParentTooLate: msg = eMessages::dfavorMessage(inst.fFestivalParentR.fTooLate); break;
    case eEvent::festivalParentRefuse: msg = eMessages::dfavorMessage(inst.fFestivalParentR.fRefuse); break;
    case eEvent::financialWoesAllyComply: msg = eMessages::favorMessage(inst.fFinancialWoesAllyS.fComply); break;
    case eEvent::financialWoesAllyTooLate: msg = eMessages::dfavorMessage(inst.fFinancialWoesAllyS.fTooLate); break;
    case eEvent::financialWoesAllyRefuse: msg = eMessages::dfavorMessage(inst.fFinancialWoesAllyS.fRefuse); break;
    case eEvent::financialWoesRivalComply: msg = eMessages::favorMessage(inst.fFinancialWoesRivalD.fComply); break;
    case eEvent::financialWoesRivalTooLate: msg = eMessages::dfavorMessage(inst.fFinancialWoesRivalD.fTooLate); break;
    case eEvent::financialWoesRivalRefuse: msg = eMessages::dfavorMessage(inst.fFinancialWoesRivalD.fRefuse); break;
    case eEvent::financialWoesSubjectComply: msg = eMessages::favorMessage(inst.fFinancialWoesSubjectP.fComply); break;
    case eEvent::financialWoesSubjectTooLate: msg = eMessages::dfavorMessage(inst.fFinancialWoesSubjectP.fTooLate); break;
    case eEvent::financialWoesSubjectRefuse: msg = eMessages::dfavorMessage(inst.fFinancialWoesSubjectP.fRefuse); break;
    case eEvent::financialWoesParentComply: msg = eMessages::favorMessage(inst.fFinancialWoesParentR.fComply); break;
    case eEvent::financialWoesParentTooLate: msg = eMessages::dfavorMessage(inst.fFinancialWoesParentR.fTooLate); break;
    case eEvent::financialWoesParentRefuse: msg = eMessages::dfavorMessage(inst.fFinancialWoesParentR.fRefuse); break;
    default:
        return eResult::notHandled;
    }
    if(dry) return eResult::worded;
    title = msg.fFull.fTitle;
    text = msg.fFull.fText;
    if(brief) *brief = msg.fCondensed.fText;
    return eResult::worded;
}

// True for the events this file words (or deliberately leaves silent).
inline bool handles(const eEvent kind) {
    eEventData none;
    std::string title, text;
    return eventText(kind, none, title, text, true) != eResult::notHandled;
}

}
