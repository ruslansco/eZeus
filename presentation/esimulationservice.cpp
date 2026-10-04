#include "esimulationservice.h"
#include "eeventnames.h"
#include "eeventmessages.h"
#include "eenginemessages.h"
#include "eeventwords.h"
#include "engine/egameboard.h"
#include "engine/ecampaign.h"
#include "engine/esimulationstep.h"
#include "engine/estatedigest.h"
#include "erand.h"
#include "characters/echaracter.h"
#include "characters/ecarttransporter.h"
#include "characters/edomesticatedanimal.h"
#include "characters/esheep.h"
#include "characters/egoat.h"
#include "characters/ecattle.h"
#include "characters/esoldierbanner.h"
#include "characters/esoldier.h"
#include "characters/eamazon.h"
#include "einvasionhandler.h"
#include "gameEvents/einvasionevent.h"
#include "gameEvents/eplayerraidevent.h"
#include "gameEvents/eplayerconquestevent.h"
#include "gameEvents/ereinforcementsevent.h"
#include "gameEvents/erequestaidevent.h"
#include "gameEvents/erequeststrikeevent.h"
#include "gameEvents/etroopsrequestevent.h"
#include "gameEvents/etroopsrequestfulfilledevent.h"
#include "gameEvents/earmyreturnevent.h"
#include "engine/emilitaryaid.h"
#include "characters/gods/egod.h"
#include "characters/etrailer.h"
#include "characters/heroes/ehero.h"
#include "characters/monsters/emonster.h"
#include "buildings/eheroshall.h"
#include "gameEvents/egodquestevent.h"
#include "engine/egodquest.h"
#include "characters/actions/emonsteraction.h"
#include "buildings/eresourcebuilding.h"
#include "buildings/eaestheticsbuilding.h"
#include "buildings/pyramids/epyramidwall.h"
#include "buildings/pyramids/epyramidtop.h"
#include "buildings/pyramids/epyramid.h"
#include "buildings/pyramids/epyramidstatue.h"
#include "buildings/pyramids/epyramidmonument.h"
#include "buildings/pyramids/epyramidtile.h"
#include "buildings/epalacetile.h"
#include "buildings/sanctuaries/esanctuary.h"
#include "buildings/sanctuaries/esanctuaryblueprint.h"
#include "buildings/sanctuaries/etemplebuilding.h"
#include "buildings/sanctuaries/etempletilebuilding.h"
#include "buildings/sanctuaries/etemplestatuebuilding.h"
#include "buildings/sanctuaries/etemplemonumentbuilding.h"
#include "buildings/sanctuaries/etemplealtarbuilding.h"
#include "buildings/esmallhouse.h"
#include "buildings/eroad.h"
#include "buildings/allbuildings.h"
#include "engine/epathfinder.h"
#include "engine/eagoraplacement.h"
#include "engine/eadventurelist.h"
#include "engine/eshoreplacement.h"
#include "engine/ebuildplacement.h"
#include "engine/etradepartners.h"
#include "engine/egifthelpers.h"
#include "engine/eworldboard.h"
#include "evectorhelpers.h"
#include "gameEvents/ereceiverequestevent.h"
#include <cstdio>
#include "buildings/etradepost.h"
#include "buildings/epier.h"
#include "audio/esoundvector.h"
#include "audio/emusic.h"
#include "widgets/eviewmode.h"
#include "engine/boardData/eheatmap.h"
#include "buildings/eelitehousing.h"
#include "engine/eepisode.h"
#include "engine/eepisodegoal.h"
#include "estringhelpers.h"
#include "buildings/ehospital.h"
#include "buildings/efountain.h"
#include "buildings/eemployingbuilding.h"
#include "buildings/ehousebase.h"
#include "buildings/ehouseneeds.h"
#include "buildings/estoragebuilding.h"
#include "buildings/eprocessingbuilding.h"
#include "buildings/eresourcecollectbuildingbase.h"
#include "buildings/egrowerslodge.h"
#include "buildings/egranary.h"
#include "buildings/ewarehouse.h"
#include "buildings/eolivepress.h"
#include "buildings/ewinery.h"
#include "buildings/esculpturestudio.h"
#include "engine/eemploymentdistributor.h"
#include "engine/ecitydata.h"
#include "engine/ebuildinginfotext.h"
#include "engine/echaracterinfotext.h"
#include "characters/etrireme.h"
#include "characters/eracinghorse.h"
#include "buildings/ehippodrome.h"
#include "buildings/etriremewharf.h"
#include "engine/boardData/eemploymentdata.h"
#include "engine/boardData/epopulationdata.h"
#include "engine/boardData/ehusbandrydata.h"
#include "engine/boardData/ecityfinances.h"
#include "engine/edifficulty.h"
#include "engine/eboardcity.h"
#include "widgets/ebuildingstoerase.h"
#include "widgets/egamewidget.h" // save view record only; no widget is instantiated
#include "widgets/emessagebox.h"
#include "fileIO/ereadstream.h"
#include "egamedir.h"
#include "audio/esounds.h"
#include "enumbers.h"
#include "elanguage.h"
#include "emessages.h"
#include "textures/egametextures.h"
#include <SDL2/SDL.h>
#include <algorithm>
#include <fstream>
#include <sstream>
#include <iomanip>
#include <deque>
#include <set>
#include <cmath>
#include <climits>
#include <filesystem>
// The enlisting the engine asked for (a raid, a conquest or a reinforcement, a troop request): what may be enlisted, and what to do with the choice.
struct eEnlistSession {
    std::string purpose; int city=-1; uint64_t event=0;
    eEnlistedForces forces; std::vector<eCityId> cids; std::vector<std::string> cnames; std::vector<eHeroType> heroesAbroad;
    std::function<void(const eEnlistedForces&,eResourceType)> action; std::vector<eResourceType> plunder;
};
namespace {
constexpr int speeds[] = {6,15,30,60};
using Creator = std::function<stdsptr<eBuilding>(eGameBoard&, eCityId)>;
// How a build command works: most buildings fill a rectangle, an agora is laid over a stretch of road found from the
// tile under the pointer, and a vendor replaces the empty space of an agora. A gatehouse is two towers laid around
// a passage whose road it adds. The other kinds are the special cases of the SDL build menu, whose rules live in
// engine/ebuildplacement (shared with the SDL view): the palace and its paving, the stadium, the horse ranch and its
// paddock, a god's monument and its tiles, the shore buildings, bridges, roadblocks, hippodrome plates and crosswalks,
// commemoratives (recorded as built), water parks (their variant), livestock (dragged, one animal a tile) and the columns
// and avenues dragged along a path.
enum class Kind { standard, agora, vendor, trade, gate, sanctuary, pyramid, palace, stadium, ranch, godMonument, shore,
                  bridge, roadblock, hippodrome, crosswalk, commemorative, waterPark, animal, path };
struct BuildSpec {
    eBuildingMode mode;
    eBuildingType type;
    int w, h;            // footprint, as the native constructors declare it
    const char* asset;   // Godot model, empty while the native building has no converted model
    bool fertile;        // farms need fertile land
    bool flat;           // roads and parks may be laid on any buildable ground
    Creator make;
    Kind kind = Kind::standard;
    eResourceType resource = eResourceType::none; // vendors: the good the stall sells
    bool grand = false;                           // agoras: the large form
    int variant = -1;                             // commemoratives: the monument's id; god monuments: the god
};
// Generated from the native build switch (widgets/egamewidgetbuild.cpp) and the building constructors; the types and
// footprints are static data, so asking about a building never constructs one (a constructor registers the object
// with its city and draws random numbers).
#define MAKE(Class) [](eGameBoard& b, eCityId c) -> stdsptr<eBuilding> { return e::make_shared<Class>(b, c); }
#define HALL(hero) [](eGameBoard& b, eCityId c) -> stdsptr<eBuilding> { return e::make_shared<eHerosHall>(eHeroType::hero, b, c); }
const std::map<std::string,BuildSpec> baseBuildSpecs{
    {"road", {eBuildingMode::road,eBuildingType::road,1,1,"road",false,true,MAKE(eRoad)}},
    {"house", {eBuildingMode::commonHousing,eBuildingType::commonHouse,2,2,"common_house_0a",false,false,MAKE(eSmallHouse)}},
    {"elite_house", {eBuildingMode::eliteHousing,eBuildingType::eliteHousing,4,4,"elite_house_0a",false,false,MAKE(eEliteHousing)}},
    {"gymnasium", {eBuildingMode::gymnasium,eBuildingType::gymnasium,3,3,"gymnasium",false,false,MAKE(eGymnasium)}},
    {"podium", {eBuildingMode::podium,eBuildingType::podium,2,2,"podium",false,false,MAKE(ePodium)}},
    {"bibliotheke", {eBuildingMode::bibliotheke,eBuildingType::bibliotheke,2,2,"bibliotheke",false,false,MAKE(eBibliotheke)}},
    {"observatory", {eBuildingMode::observatory,eBuildingType::observatory,5,5,"observatory",false,false,MAKE(eObservatory)}},
    {"university", {eBuildingMode::university,eBuildingType::university,3,3,"university",false,false,MAKE(eUniversity)}},
    {"laboratory", {eBuildingMode::laboratory,eBuildingType::laboratory,4,4,"laboratory",false,false,MAKE(eLaboratory)}},
    {"inventors_workshop", {eBuildingMode::inventorsWorkshop,eBuildingType::inventorsWorkshop,3,3,"inventors_workshop",false,false,MAKE(eInventorsWorkshop)}},
    {"museum", {eBuildingMode::museum,eBuildingType::museum,6,6,"museum",false,false,MAKE(eMuseum)}},
    {"fountain", {eBuildingMode::fountain,eBuildingType::fountain,2,2,"fountain",false,false,MAKE(eFountain)}},
    {"watchpost", {eBuildingMode::watchpost,eBuildingType::watchPost,2,2,"watch_post",false,false,MAKE(eWatchpost)}},
    {"maintenance_office", {eBuildingMode::maintenanceOffice,eBuildingType::maintenanceOffice,2,2,"maintenance_office",false,false,MAKE(eMaintenanceOffice)}},
    {"college", {eBuildingMode::college,eBuildingType::college,3,3,"college",false,false,MAKE(eCollege)}},
    {"drama_school", {eBuildingMode::dramaSchool,eBuildingType::dramaSchool,3,3,"drama_school",false,false,MAKE(eDramaSchool)}},
    {"theater", {eBuildingMode::theater,eBuildingType::theater,5,5,"theater",false,false,MAKE(eTheater)}},
    {"hospital", {eBuildingMode::hospital,eBuildingType::hospital,4,4,"hospital",false,false,MAKE(eHospital)}},
    {"tax_office", {eBuildingMode::taxOffice,eBuildingType::taxOffice,2,2,"tax_office",false,false,MAKE(eTaxOffice)}},
    {"mint", {eBuildingMode::mint,eBuildingType::mint,2,2,"mint",false,false,MAKE(eMint)}},
    {"foundry", {eBuildingMode::foundry,eBuildingType::foundry,2,2,"foundry",false,false,MAKE(eFoundry)}},
    {"timber_mill", {eBuildingMode::timberMill,eBuildingType::timberMill,2,2,"timber_mill",false,false,MAKE(eTimberMill)}},
    {"masonry_shop", {eBuildingMode::masonryShop,eBuildingType::masonryShop,2,2,"masonry_shop",false,false,MAKE(eMasonryShop)}},
    {"refinery", {eBuildingMode::refinery,eBuildingType::refinery,2,2,"refinery",false,false,MAKE(eRefinery)}},
    {"black_marble_workshop", {eBuildingMode::blackMarbleWorkshop,eBuildingType::blackMarbleWorkshop,2,2,"black_marble_workshop",false,false,MAKE(eBlackMarbleWorkshop)}},
    {"hunting_lodge", {eBuildingMode::huntingLodge,eBuildingType::huntingLodge,2,2,"hunting_lodge",false,false,MAKE(eHuntingLodge)}},
    {"corral", {eBuildingMode::corral,eBuildingType::corral,4,4,"corral",false,false,MAKE(eCorral)}},
    {"dairy", {eBuildingMode::dairy,eBuildingType::dairy,2,2,"dairy",false,false,MAKE(eDairy)}},
    {"carding_shed", {eBuildingMode::cardingShed,eBuildingType::cardingShed,2,2,"carding_shed",false,false,MAKE(eCardingShed)}},
    {"wheat_farm", {eBuildingMode::wheatFarm,eBuildingType::wheatFarm,3,3,"farm",true,false,MAKE(eWheatFarm)}},
    {"onion_farm", {eBuildingMode::onionFarm,eBuildingType::onionsFarm,3,3,"farm",true,false,MAKE(eOnionFarm)}},
    {"carrot_farm", {eBuildingMode::carrotFarm,eBuildingType::carrotsFarm,3,3,"farm",true,false,MAKE(eCarrotFarm)}},
    {"granary", {eBuildingMode::granary,eBuildingType::granary,4,4,"granary",false,false,MAKE(eGranary)}},
    {"warehouse", {eBuildingMode::warehouse,eBuildingType::warehouse,3,3,"warehouse",false,false,MAKE(eWarehouse)}},
    {"wall", {eBuildingMode::wall,eBuildingType::wall,1,1,"wall_0",false,false,MAKE(eWall)}},
    {"tower", {eBuildingMode::tower,eBuildingType::tower,2,2,"tower",false,false,MAKE(eTower)}},
    {"gatehouse", {eBuildingMode::gatehouse,eBuildingType::gatehouse,5,2,"gatehouse",false,false,nullptr,Kind::gate}},
    // The heroes' halls: a hall of each hero, 4x4, with the hero's requirements (`hall` in the inspection) and a summoning.
    {"hero_hall_achilles", {eBuildingMode::achillesHall,eBuildingType::achillesHall,4,4,"hero_hall_achilles",false,false,HALL(achilles)}},
    {"hero_hall_atalanta", {eBuildingMode::atalantaHall,eBuildingType::atalantaHall,4,4,"hero_hall_atalanta",false,false,HALL(atalanta)}},
    {"hero_hall_bellerophon", {eBuildingMode::bellerophonHall,eBuildingType::bellerophonHall,4,4,"hero_hall_bellerophon",false,false,HALL(bellerophon)}},
    {"hero_hall_hercules", {eBuildingMode::herculesHall,eBuildingType::herculesHall,4,4,"hero_hall_hercules",false,false,HALL(hercules)}},
    {"hero_hall_jason", {eBuildingMode::jasonHall,eBuildingType::jasonHall,4,4,"hero_hall_jason",false,false,HALL(jason)}},
    {"hero_hall_odysseus", {eBuildingMode::odysseusHall,eBuildingType::odysseusHall,4,4,"hero_hall_odysseus",false,false,HALL(odysseus)}},
    {"hero_hall_perseus", {eBuildingMode::perseusHall,eBuildingType::perseusHall,4,4,"hero_hall_perseus",false,false,HALL(perseus)}},
    {"hero_hall_theseus", {eBuildingMode::theseusHall,eBuildingType::theseusHall,4,4,"hero_hall_theseus",false,false,HALL(theseus)}},
    // The gods' sanctuaries: a footprint that depends on the god and on the turn (the layouts of eZeus/Sanctuaries), built through
    // eGameBoard::buildSanctuary; the model listed is the god's monument (the menu icon), the preview lists the pieces.
    {"temple_aphrodite", {eBuildingMode::templeAphrodite,eBuildingType::templeAphrodite,0,0,"sanctuary_monument_aphrodite",false,false,nullptr,Kind::sanctuary}},
    {"temple_apollo", {eBuildingMode::templeApollo,eBuildingType::templeApollo,0,0,"sanctuary_monument_apollo",false,false,nullptr,Kind::sanctuary}},
    {"temple_ares", {eBuildingMode::templeAres,eBuildingType::templeAres,0,0,"sanctuary_monument_ares",false,false,nullptr,Kind::sanctuary}},
    {"temple_artemis", {eBuildingMode::templeArtemis,eBuildingType::templeArtemis,0,0,"sanctuary_monument_artemis",false,false,nullptr,Kind::sanctuary}},
    {"temple_athena", {eBuildingMode::templeAthena,eBuildingType::templeAthena,0,0,"sanctuary_monument_athena",false,false,nullptr,Kind::sanctuary}},
    {"temple_atlas", {eBuildingMode::templeAtlas,eBuildingType::templeAtlas,0,0,"sanctuary_monument_atlas",false,false,nullptr,Kind::sanctuary}},
    {"temple_demeter", {eBuildingMode::templeDemeter,eBuildingType::templeDemeter,0,0,"sanctuary_monument_demeter",false,false,nullptr,Kind::sanctuary}},
    {"temple_dionysus", {eBuildingMode::templeDionysus,eBuildingType::templeDionysus,0,0,"sanctuary_monument_dionysus",false,false,nullptr,Kind::sanctuary}},
    {"temple_hades", {eBuildingMode::templeHades,eBuildingType::templeHades,0,0,"sanctuary_monument_hades",false,false,nullptr,Kind::sanctuary}},
    {"temple_hephaestus", {eBuildingMode::templeHephaestus,eBuildingType::templeHephaestus,0,0,"sanctuary_monument_hephaestus",false,false,nullptr,Kind::sanctuary}},
    {"temple_hera", {eBuildingMode::templeHera,eBuildingType::templeHera,0,0,"sanctuary_monument_hera",false,false,nullptr,Kind::sanctuary}},
    {"temple_hermes", {eBuildingMode::templeHermes,eBuildingType::templeHermes,0,0,"sanctuary_monument_hermes",false,false,nullptr,Kind::sanctuary}},
    {"temple_poseidon", {eBuildingMode::templePoseidon,eBuildingType::templePoseidon,0,0,"sanctuary_monument_poseidon",false,false,nullptr,Kind::sanctuary}},
    {"temple_zeus", {eBuildingMode::templeZeus,eBuildingType::templeZeus,0,0,"sanctuary_monument_zeus",false,false,nullptr,Kind::sanctuary}},
    {"armory", {eBuildingMode::armory,eBuildingType::armory,2,2,"armory",false,false,MAKE(eArmory)}},
    {"chariot_factory", {eBuildingMode::chariotFactory,eBuildingType::chariotFactory,4,4,"chariot_factory",false,false,MAKE(eChariotFactory)}},
    {"olive_press", {eBuildingMode::olivePress,eBuildingType::olivePress,2,2,"olive_press",false,false,MAKE(eOlivePress)}},
    {"winery", {eBuildingMode::winery,eBuildingType::winery,2,2,"winery",false,false,MAKE(eWinery)}},
    {"sculpture_studio", {eBuildingMode::sculptureStudio,eBuildingType::sculptureStudio,2,2,"sculpture_studio",false,false,MAKE(eSculptureStudio)}},
    {"artisans_guild", {eBuildingMode::artisansGuild,eBuildingType::artisansGuild,2,2,"artisans_guild",false,false,MAKE(eArtisansGuild)}},
    {"bench", {eBuildingMode::bench,eBuildingType::bench,1,1,"deco_bench",false,false,MAKE(eBench)}},
    {"flower_garden", {eBuildingMode::flowerGarden,eBuildingType::flowerGarden,2,2,"deco_flower_garden",false,false,MAKE(eFlowerGarden)}},
    {"gazebo", {eBuildingMode::gazebo,eBuildingType::gazebo,2,2,"deco_gazebo",false,false,MAKE(eGazebo)}},
    {"hedge_maze", {eBuildingMode::hedgeMaze,eBuildingType::hedgeMaze,3,3,"deco_hedge_maze",false,false,MAKE(eHedgeMaze)}},
    {"fish_pond", {eBuildingMode::fishPond,eBuildingType::fishPond,4,4,"deco_fish_pond",false,false,MAKE(eFishPond)}},
    {"bird_bath", {eBuildingMode::birdBath,eBuildingType::birdBath,1,1,"deco_birdbath",false,false,MAKE(eBirdBath)}},
    {"short_obelisk", {eBuildingMode::shortObelisk,eBuildingType::shortObelisk,1,1,"deco_short_obelisk",false,false,MAKE(eShortObelisk)}},
    {"tall_obelisk", {eBuildingMode::tallObelisk,eBuildingType::tallObelisk,1,1,"deco_tall_obelisk",false,false,MAKE(eTallObelisk)}},
    {"shell_garden", {eBuildingMode::shellGarden,eBuildingType::shellGarden,2,2,"deco_shell_garden",false,false,MAKE(eShellGarden)}},
    {"sundial", {eBuildingMode::sundial,eBuildingType::sundial,2,2,"deco_sundial",false,false,MAKE(eSundial)}},
    {"dolphin_sculpture", {eBuildingMode::dolphinSculpture,eBuildingType::dolphinSculpture,3,3,"deco_dolphin",false,false,MAKE(eDolphinSculpture)}},
    {"orrery", {eBuildingMode::orrery,eBuildingType::orrery,3,3,"deco_orrery",false,false,MAKE(eOrrery)}},
    {"spring", {eBuildingMode::spring,eBuildingType::spring,3,3,"deco_spring",false,false,MAKE(eSpring)}},
    {"topiary", {eBuildingMode::topiary,eBuildingType::topiary,3,3,"deco_topiary",false,false,MAKE(eTopiary)}},
    {"baths", {eBuildingMode::baths,eBuildingType::baths,4,4,"baths",false,false,MAKE(eBaths)}},
    {"stone_circle", {eBuildingMode::stoneCircle,eBuildingType::stoneCircle,4,4,"deco_stone_circle",false,false,MAKE(eStoneCircle)}},
    {"park", {eBuildingMode::park,eBuildingType::park,1,1,"park",false,true,MAKE(ePark)}},
    {"growers_lodge", {eBuildingMode::growersLodge,eBuildingType::growersLodge,2,2,"growers_lodge",false,false,[](eGameBoard& b, eCityId c) -> stdsptr<eBuilding> { return e::make_shared<eGrowersLodge>(b, eGrowerType::grapesAndOlives, c); }}},
    {"orange_tenders_lodge", {eBuildingMode::orangeTendersLodge,eBuildingType::orangeTendersLodge,2,2,"orange_tenders_lodge",false,false,[](eGameBoard& b, eCityId c) -> stdsptr<eBuilding> { return e::make_shared<eGrowersLodge>(b, eGrowerType::oranges, c); }}},
    {"trade_post", {eBuildingMode::tradePost,eBuildingType::tradePost,4,4,"trade_post",false,false,nullptr,Kind::trade}},
    {"pier", {eBuildingMode::pier,eBuildingType::pier,2,2,"harbour",false,false,nullptr,Kind::trade}},
    {"common_agora", {eBuildingMode::commonAgora,eBuildingType::commonAgora,6,3,"agora_space",false,false,nullptr,Kind::agora,eResourceType::none,false}},
    {"grand_agora", {eBuildingMode::grandAgora,eBuildingType::grandAgora,6,5,"agora_space",false,false,nullptr,Kind::agora,eResourceType::none,true}},
    {"food_vendor", {eBuildingMode::foodVendor,eBuildingType::foodVendor,2,2,"food_vendor",false,false,MAKE(eFoodVendor),Kind::vendor,eResourceType::food}},
    {"fleece_vendor", {eBuildingMode::fleeceVendor,eBuildingType::fleeceVendor,2,2,"fleece_vendor",false,false,MAKE(eFleeceVendor),Kind::vendor,eResourceType::fleece}},
    {"oil_vendor", {eBuildingMode::oilVendor,eBuildingType::oilVendor,2,2,"oil_vendor",false,false,MAKE(eOilVendor),Kind::vendor,eResourceType::oliveOil}},
    {"wine_vendor", {eBuildingMode::wineVendor,eBuildingType::wineVendor,2,2,"wine_vendor",false,false,MAKE(eWineVendor),Kind::vendor,eResourceType::wine}},
    {"arms_vendor", {eBuildingMode::armsVendor,eBuildingType::armsVendor,2,2,"arms_vendor",false,false,MAKE(eArmsVendor),Kind::vendor,eResourceType::armor}},
    {"horse_vendor", {eBuildingMode::horseTrainer,eBuildingType::horseTrainer,2,2,"horse_vendor",false,false,MAKE(eHorseVendor),Kind::vendor,eResourceType::horse}},
    {"chariot_vendor", {eBuildingMode::chariotVendor,eBuildingType::chariotVendor,2,2,"chariot_vendor",false,false,MAKE(eChariotVendor),Kind::vendor,eResourceType::chariot}},
};
// The pyramids, monuments to the sky and shrines of the expansion (the SDL game's pyramids menu, 54 buildings): the engine builds each as one
// ePyramid whose pieces ePyramid::sPlan lays out; a scenario grants each one (once) with the dark and light levels it asks for. The model listed
// is the menu's picture; the footprint is the engine's (ePyramid::sDimensions), never constructed here.
std::map<std::string,BuildSpec> withPyramids(std::map<std::string,BuildSpec> specs) {
    static const char* gods[]={"aphrodite","apollo","ares","artemis","athena","atlas","demeter","dionysus","hades","hephaestus","hera","hermes","poseidon","zeus"};
    const auto add=[&](const std::string& name,const eBuildingMode mode,const std::string& model) {
        const auto type=eBuildingModeHelpers::toBuildingType(mode); int w=0,h=0; ePyramid::sDimensions(type,w,h);
        static std::deque<std::string> kept; kept.push_back(model);
        specs.emplace(name,BuildSpec{mode,type,w,h,kept.back().c_str(),false,false,nullptr,Kind::pyramid});
    };
    add("pyramid_modest",eBuildingMode::modestPyramid,"pyramid_p1_8");
    add("pyramid_standard",eBuildingMode::pyramid,"pyramid_p1_8");
    add("pyramid_great",eBuildingMode::greatPyramid,"pyramid_p1_8");
    add("pyramid_majestic",eBuildingMode::majesticPyramid,"pyramid_p1_8");
    add("pyramid_sky_small",eBuildingMode::smallMonumentToTheSky,"pyramid_p1_8");
    add("pyramid_sky",eBuildingMode::monumentToTheSky,"pyramid_p1_8");
    add("pyramid_sky_grand",eBuildingMode::grandMonumentToTheSky,"pyramid_p1_8");
    for(int god=0;god<14;++god) {
        const std::string g=gods[god];
        add("shrine_minor_"+g,static_cast<eBuildingMode>(int(eBuildingMode::minorShrineAphrodite)+god),"sanctuary_statue_"+g);
        add("shrine_"+g,static_cast<eBuildingMode>(int(eBuildingMode::shrineAphrodite)+god),"sanctuary_monument_"+g);
        add("shrine_major_"+g,static_cast<eBuildingMode>(int(eBuildingMode::majorShrineAphrodite)+god),"sanctuary_monument_"+g);
    }
    add("pyramid_pantheon",eBuildingMode::pyramidToThePantheon,"pyramid_p1_8");
    add("pyramid_altar",eBuildingMode::altarOfOlympus,"sanctuary_altar");
    add("pyramid_temple",eBuildingMode::templeOfOlympus,"sanctuary_temple_0");
    add("pyramid_observatory",eBuildingMode::observatoryKosmika,"observatory");
    add("pyramid_museum",eBuildingMode::museumAtlantika,"museum");
    return specs;
}
// The rest of the SDL build menu: orchards, livestock, shore buildings, the palace, the stadium, the horse ranch, bridges,
// roadblocks, columns, avenues, the water park, the hippodrome and its crosswalks, and the monuments a scenario grants.
std::map<std::string,BuildSpec> withMenuRest(std::map<std::string,BuildSpec> specs) {
    static std::deque<std::string> kept;
    const auto text=[&](const std::string& value) { kept.push_back(value); return kept.back().c_str(); };
    const auto add=[&](const std::string& name,const BuildSpec& spec) { specs.emplace(name,spec); };
    const auto tree=[](const eResourceBuildingType kind) {
        return [kind](eGameBoard& b, eCityId c) -> stdsptr<eBuilding> { return e::make_shared<eResourceBuilding>(b, kind, c); };
    };
    add("vine",{eBuildingMode::vine,eBuildingType::vine,1,1,"vine_5",true,true,tree(eResourceBuildingType::vine)});
    add("olive_tree",{eBuildingMode::oliveTree,eBuildingType::oliveTree,1,1,"olive_5",true,true,tree(eResourceBuildingType::oliveTree)});
    add("orange_tree",{eBuildingMode::orangeTree,eBuildingType::orangeTree,1,1,"orange_5",true,true,tree(eResourceBuildingType::orangeTree)});
    add("goat",{eBuildingMode::goat,eBuildingType::goat,1,2,"animal_goat",true,true,nullptr,Kind::animal});
    add("sheep",{eBuildingMode::sheep,eBuildingType::sheep,1,2,"animal_sheep_fleeced",true,true,nullptr,Kind::animal});
    add("cattle",{eBuildingMode::cattle,eBuildingType::cattle,1,2,"animal_cattle",true,true,nullptr,Kind::animal});
    add("fishery",{eBuildingMode::fishery,eBuildingType::fishery,2,2,"fishery",false,false,nullptr,Kind::shore});
    add("urchin_quay",{eBuildingMode::urchinQuay,eBuildingType::urchinQuay,2,2,"urchin_quay",false,false,nullptr,Kind::shore});
    add("trireme_wharf",{eBuildingMode::triremeWharf,eBuildingType::triremeWharf,3,3,"trireme_wharf",false,false,nullptr,Kind::shore});
    add("horse_ranch",{eBuildingMode::horseRanch,eBuildingType::horseRanch,3,3,"horse_ranch",false,false,nullptr,Kind::ranch});
    add("palace",{eBuildingMode::palace,eBuildingType::palace,8,4,"palace",false,false,nullptr,Kind::palace});
    add("stadium",{eBuildingMode::stadium,eBuildingType::stadium,10,5,"stadium",false,false,nullptr,Kind::stadium});
    add("bridge",{eBuildingMode::bridge,eBuildingType::bridge,1,1,"road",false,false,nullptr,Kind::bridge});
    add("roadblock",{eBuildingMode::roadblock,eBuildingType::none,1,1,"roadblock",false,false,nullptr,Kind::roadblock});
    add("doric_column",{eBuildingMode::doricColumn,eBuildingType::doricColumn,1,1,"column_doric",false,false,MAKE(eDoricColumn),Kind::path});
    add("ionic_column",{eBuildingMode::ionicColumn,eBuildingType::ionicColumn,1,1,"column_ionic",false,false,MAKE(eIonicColumn),Kind::path});
    add("corinthian_column",{eBuildingMode::corinthianColumn,eBuildingType::corinthianColumn,1,1,"column_corinthian",false,false,MAKE(eCorinthianColumn),Kind::path});
    add("avenue",{eBuildingMode::avenue,eBuildingType::avenue,1,1,"road",false,true,nullptr,Kind::path});
    add("boulevard",{eBuildingMode::boulevard,eBuildingType::boulevard,1,1,"road",false,true,nullptr,Kind::path});
    add("water_park",{eBuildingMode::waterPark,eBuildingType::waterPark,2,2,"deco_water_park",false,false,MAKE(eWaterPark),Kind::waterPark});
    add("hippodrome",{eBuildingMode::hippodromePiece,eBuildingType::hippodromePiece,4,4,"hippodrome_0",false,false,nullptr,Kind::hippodrome});
    add("crosswalk",{eBuildingMode::crosswalk,eBuildingType::crosswalk,1,1,"road",false,false,nullptr,Kind::crosswalk});
    static const char* commemoratives[]={"population","victory","colony","athlete","conquest","happiness","heroic","diplomacy","scholar"};
    for(int id=0;id<9;++id) {
        const auto mode=static_cast<eBuildingMode>(int(eBuildingMode::populationMonument)+id);
        add(std::string("monument_")+commemoratives[id],{mode,eBuildingType::commemorative,3,3,text("commemorative_"+std::to_string(id)),false,false,
            [id](eGameBoard& b, eCityId c) -> stdsptr<eBuilding> { return e::make_shared<eCommemorative>(id, b, c); },Kind::commemorative,eResourceType::none,false,id});
    }
    static const char* gods[]={"aphrodite","apollo","ares","artemis","athena","atlas","demeter","dionysus","hades","hephaestus","hera","hermes","poseidon","zeus"};
    for(int god=0;god<14;++god) {
        const auto mode=static_cast<eBuildingMode>(int(eBuildingMode::aphroditeMonument)+god);
        add(std::string("god_monument_")+gods[god],{mode,eBuildingType::godMonument,4,4,text(std::string("sanctuary_monument_")+gods[god]),false,false,nullptr,
            Kind::godMonument,eResourceType::none,false,god});
    }
    return specs;
}
#undef MAKE
const std::map<std::string,BuildSpec> buildSpecs=withPyramids(withMenuRest(baseBuildSpecs));
// The native view modes (overlays), named as the Godot interface asks for them.
struct OverlayMode { const char* name; eViewMode mode; };
const OverlayMode overlayModes[] = {
    {"normal",eViewMode::defaultView},{"water",eViewMode::water},{"supplies",eViewMode::supplies},
    {"hygiene",eViewMode::hygiene},{"hazards",eViewMode::hazards},{"appeal",eViewMode::appeal},
    {"taxes",eViewMode::taxes},{"unrest",eViewMode::unrest},{"security",eViewMode::security},
    {"roads",eViewMode::roads},{"problems",eViewMode::problems},{"husbandry",eViewMode::husbandry},
    {"industry",eViewMode::industry},{"distribution",eViewMode::distribution},{"immortals",eViewMode::immortals},
    {"actors",eViewMode::actors},{"athletes",eViewMode::athletes},{"philosophers",eViewMode::philosophers},
    {"competitors",eViewMode::competitors},{"all_culture",eViewMode::allCulture},
    {"astronomers",eViewMode::astronomers},{"scholars",eViewMode::scholars},{"inventors",eViewMode::inventors},
    {"curators",eViewMode::curators},{"all_science",eViewMode::allScience},
};
std::string quote(const std::string& s) {
    std::ostringstream out; out << '"';
    for(unsigned char c : s) {
        if(c == '"' || c == '\\') out << '\\' << c;
        else if(c == '\n') out << "\\n";
        else if(c == '\r') out << "\\r";
        else if(c == '\t') out << "\\t";
        else if(c < 32) out << "\\u" << std::hex << std::setw(4) << std::setfill('0') << int(c) << std::dec;
        else out << c;
    }
    out << '"'; return out.str();
}
// Both kinds of trade post (land and sea pier) are charged as a trade post.
eBuildingType costType(const BuildSpec& spec) { return spec.kind==Kind::trade ? eBuildingType::tradePost : spec.type; }
std::string godAsset(eGodType god) {
    static const char* names[]={"aphrodite","apollo","ares","artemis","athena","atlas","demeter","dionysus","hades","hephaestus","hera","hermes","poseidon","zeus"};
    return names[static_cast<int>(god)];
}
// The god a sanctuary of this building type belongs to.
eGodType sanctuaryGod(const eBuildingType type) {
    switch(type) {
    case eBuildingType::templeAphrodite: return eGodType::aphrodite;
    case eBuildingType::templeApollo: return eGodType::apollo;
    case eBuildingType::templeAres: return eGodType::ares;
    case eBuildingType::templeArtemis: return eGodType::artemis;
    case eBuildingType::templeAthena: return eGodType::athena;
    case eBuildingType::templeAtlas: return eGodType::atlas;
    case eBuildingType::templeDemeter: return eGodType::demeter;
    case eBuildingType::templeDionysus: return eGodType::dionysus;
    case eBuildingType::templeHades: return eGodType::hades;
    case eBuildingType::templeHephaestus: return eGodType::hephaestus;
    case eBuildingType::templeHera: return eGodType::hera;
    case eBuildingType::templeHermes: return eGodType::hermes;
    case eBuildingType::templePoseidon: return eGodType::poseidon;
    default: return eGodType::zeus;
    }
}
// The index of a god in the SDL text tables (eSanctuaryInfoWidget's sTextGodId).
int sanctuaryTextId(const eGodType god) {
    switch(god) {
    case eGodType::zeus: return 0; case eGodType::poseidon: return 1; case eGodType::demeter: return 2; case eGodType::apollo: return 3;
    case eGodType::artemis: return 4; case eGodType::ares: return 5; case eGodType::aphrodite: return 6; case eGodType::hermes: return 7;
    case eGodType::athena: return 8; case eGodType::hephaestus: return 9; case eGodType::dionysus: return 10; case eGodType::hades: return 11;
    case eGodType::hera: return 12; case eGodType::atlas: return 13;
    }
    return 0;
}
// The god whose statue stands on a blueprint tile (the sanctuary's own god for the plain statue).
eGodType blueprintStatueGod(const eSanctEleType type,const eGodType own) {
    switch(type) {
    case eSanctEleType::aphroditeStatue: return eGodType::aphrodite; case eSanctEleType::apolloStatue: return eGodType::apollo;
    case eSanctEleType::aresStatue: return eGodType::ares; case eSanctEleType::artemisStatue: return eGodType::artemis;
    case eSanctEleType::athenaStatue: return eGodType::athena; case eSanctEleType::atlasStatue: return eGodType::atlas;
    case eSanctEleType::demeterStatue: return eGodType::demeter; case eSanctEleType::dionysusStatue: return eGodType::dionysus;
    case eSanctEleType::hadesStatue: return eGodType::hades; case eSanctEleType::hephaestusStatue: return eGodType::hephaestus;
    case eSanctEleType::heraStatue: return eGodType::hera; case eSanctEleType::hermesStatue: return eGodType::hermes;
    case eSanctEleType::poseidonStatue: return eGodType::poseidon; case eSanctEleType::zeusStatue: return eGodType::zeus;
    default: return own;
    }
}
// Which way the pieces of a sanctuary look in the 3D city, in quarter turns of the model (the snapshot's `orientation`). The temple stands at
// the back of the layout and the yard, the monument, the altar and the gate lie toward its high rows, so the front of an unturned layout is tile +x
// and that of a turned one (rows and columns swapped) is tile +y. The models are authored looking one way: the temple's pediment toward +x
// (pieces 0 and 2, the turned layout's) or toward +y (1 and 3), the statues and the monuments toward +y. Each piece is turned so that the
// temple's entrance and every god look to the front, along the long side of the rectangle. -1: not a piece that turns.
int sanctuaryQuarterTurns(const eBuildingType type,const int pieceId,const bool turned) {
    int authored; // 0: +x, 1: +y
    switch(type) {
    case eBuildingType::temple: authored=(pieceId==0 || pieceId==2)?0:1; break;
    case eBuildingType::templeStatue: case eBuildingType::templeMonument: authored=1; break;
    default: return -1;
    }
    const int front=turned?1:0;
    if(front==authored) return 0;
    return authored==0?1:3; // a quarter turn takes +x to +y, three take +y to +x
}
// One piece of a sanctuary about to be built, as eGameBoard::buildSanctuary will place it (the same offsets).
struct SanctPiece { std::string asset; int x, y, w, h; int turns; };
std::vector<SanctPiece> sanctuaryPieces(const eSanctBlueprint& blueprint,const eGodType god,const bool rotate,const int minX,const int minY) {
    std::vector<SanctPiece> pieces; const int d=rotate?1:0;
    for(const auto& row:blueprint.fTiles) for(const auto& t:row) {
        const int tx=minX+t.fX, ty=minY+t.fY;
        switch(t.fType) {
        case eSanctEleType::tile: pieces.push_back({"sanctuary_court_"+std::to_string(std::clamp(t.fId,0,5)),tx,ty,1,1,0}); break;
        case eSanctEleType::monument: pieces.push_back({"sanctuary_monument_"+godAsset(god),tx-d,ty+d,2,2,sanctuaryQuarterTurns(eBuildingType::templeMonument,0,rotate)}); break;
        case eSanctEleType::altar: pieces.push_back({"sanctuary_altar",tx-d,ty+d,2,2,0}); break;
        case eSanctEleType::sanctuary: pieces.push_back({"sanctuary_temple_"+std::to_string(t.fId),rotate?tx-2:tx+1,rotate?ty+2:ty-1,4,4,sanctuaryQuarterTurns(eBuildingType::temple,t.fId,rotate)}); break;
        case eSanctEleType::defaultStatue: case eSanctEleType::aphroditeStatue: case eSanctEleType::apolloStatue: case eSanctEleType::aresStatue:
        case eSanctEleType::artemisStatue: case eSanctEleType::athenaStatue: case eSanctEleType::atlasStatue: case eSanctEleType::demeterStatue:
        case eSanctEleType::dionysusStatue: case eSanctEleType::hadesStatue: case eSanctEleType::hephaestusStatue: case eSanctEleType::heraStatue:
        case eSanctEleType::hermesStatue: case eSanctEleType::poseidonStatue: case eSanctEleType::zeusStatue:
            pieces.push_back({"sanctuary_statue_"+godAsset(blueprintStatueGod(t.fType,god)),tx,ty,1,1,sanctuaryQuarterTurns(eBuildingType::templeStatue,0,rotate)}); break;
        default: break;
        }
    }
    return pieces;
}
// The line of the SDL text table (group 132) that describes a finished pyramid, monument or shrine; -1 for anything else.
int pyramidTextId(const eBuildingType type) {
    switch(type) {
    case eBuildingType::modestPyramid: return 114; case eBuildingType::pyramid: return 115;
    case eBuildingType::greatPyramid: return 116; case eBuildingType::majesticPyramid: return 117;
    case eBuildingType::smallMonumentToTheSky: return 118; case eBuildingType::monumentToTheSky: return 119; case eBuildingType::grandMonumentToTheSky: return 120;
    case eBuildingType::pyramidOfThePantheon: return 124; case eBuildingType::altarOfOlympus: return 125; case eBuildingType::templeOfOlympus: return 126;
    case eBuildingType::observatoryKosmika: return 127; case eBuildingType::museumAtlantika: return 128;
    default: break;
    }
    if(!ePyramid::sIsToGod(type)) return -1;
    int w=0,h=0; ePyramid::sDimensions(type,w,h);
    return w==3?121:(w==6?122:123);
}
// The enemy cities on the board that a finished sanctuary's god may be sent against, as the SDL inspector offers them ("God Invasion"):
// `,"attack":{"label","fraction" (how far the wait for the next attack has come, 0 to 1),"targets":[{"city","name"}]}`, or nothing when the
// sanctuary is not the player's, not finished, or no enemy city is on the board.
std::string attackInfo(eSanctuary* const sanctuary) {
    if(!sanctuary || !sanctuary->finished()) return std::string();
    auto& board=sanctuary->getBoard(); const auto pid=sanctuary->playerId();
    if(pid!=board.personPlayer()) return std::string();
    const auto enemies=board.enemyCidsOnBoard(board.playerIdToTeamId(pid));
    if(enemies.empty()) return std::string();
    std::ostringstream o; o << ",\"attack\":{\"label\":" << quote(eLanguage::zeusText(156,27)) << ",\"fraction\":" << std::clamp(sanctuary->helpAttackTimeFraction(),0.0,1.0) << ",\"targets\":[";
    bool first=true;
    for(const auto cid:enemies) {
        const auto city=board.world().cityWithId(cid);
        if(!first) o << ','; first=false;
        o << "{\"city\":" << int(cid) << ",\"name\":" << quote(city?city->name():std::string()) << '}';
    }
    o << "]}"; return o.str();
}
// A monument (a sanctuary here) as the SDL info widget words it: while it is being built the percent complete, what is still
// needed and the warnings (no road, construction halted, no artisans' guild); when it stands the god's description and the
// label and readiness of its help. The numbers are given as well, for the front end's own layout.
std::string monumentInfo(eMonument* const m) {
    auto& board=m->getBoard(); const auto sanctuary=dynamic_cast<eSanctuary*>(m);
    const auto name=eBuilding::sNameForBuilding(m); const bool finished=m->finished();
    std::vector<std::string> lines; std::string title=name, description, helpLabel;
    const auto cost=m->cost(), stored=m->stored(), used=m->used(), needed=cost-stored-used;
    const auto goodsJson=[](const eSanctCost& c) {
        std::ostringstream o; o << "{\"marble\":" << c.fMarble << ",\"wood\":" << c.fWood << ",\"sculpture\":" << c.fSculpture
            << ",\"orichalc\":" << c.fOrichalc << ",\"black_marble\":" << c.fBlackMarble << '}'; return o.str();
    };
    const int godText=sanctuary?sanctuaryTextId(sanctuary->godType()):0;
    const int pyramidText=sanctuary?-1:pyramidTextId(m->type());
    if(sanctuary && finished) {
        for(const int base:{66,80,94}) description+=(description.empty()?"":" ")+eLanguage::zeusText(132,base+godText);
        helpLabel=eLanguage::zeusText(132,10+godText);
    } else if(finished && pyramidText>=0) {
        // A finished pyramid, monument or shrine: its description (a shrine names its god).
        description=eLanguage::zeusText(132,pyramidText);
        if(ePyramid::sIsToGod(m->type())) { const auto god=eGod::sGodName(ePyramid::sGod(m->type())); eStringHelpers::replaceAll(description,"[god]",god); }
    } else if(!finished) {
        title=eLanguage::zeusText(178,2); eStringHelpers::replace(title,"[monument]",name);
        if(!m->accessToRoad()) lines.push_back(eLanguage::zeusText(69,4));
        if(m->constructionHalted()) lines.push_back(eLanguage::zeusText(132,130));
        if(board.countBuildings(m->cityId(),eBuildingType::artisansGuild)==0) lines.push_back(eLanguage::zeusText(178,0));
        const auto percent=std::to_string(m->progress())+"%";
        if(sanctuary) {
            auto complete=eLanguage::zeusText(178,23); eStringHelpers::replace(complete,"[god]",eGod::sGodName(sanctuary->godType()));
            eStringHelpers::replace(complete,"[percent_complete]",percent); lines.push_back(complete);
        } else {
            auto complete=name+" "+eLanguage::zeusText(178,24); eStringHelpers::replace(complete,"[percent_complete]",percent); lines.push_back(complete);
        }
        if(needed.fMarble>0 || needed.fWood>0 || needed.fSculpture>0 || needed.fOrichalc>0 || needed.fBlackMarble>0) {
            auto remaining=eLanguage::zeusText(178,25);
            const auto add=[&](const int amount,const int one,const int many) {
                if(amount<=0) return;
                auto line=eLanguage::zeusText(178,amount==1?one:many); eStringHelpers::replace(line,"[amount]",std::to_string(amount)); remaining+="\n"+line;
            };
            add(needed.fMarble,26,27); add(needed.fWood,30,31); add(needed.fSculpture,32,33); add(needed.fOrichalc,34,35); add(needed.fBlackMarble,28,29);
            lines.push_back(remaining);
        } else lines.push_back(eLanguage::zeusText(178,36));
    }
    std::ostringstream o;
    o << "{\"name\":" << quote(name) << ",\"title\":" << quote(title) << ",\"sanctuary\":" << (sanctuary?"true":"false") << ",\"pyramid\":" << (pyramidText>=0?"true":"false")
      << ",\"god\":" << (sanctuary?int(sanctuary->godType()):-1) << ",\"god_name\":" << quote(sanctuary?eGod::sGodName(sanctuary->godType()):std::string())
      << ",\"finished\":" << (finished?"true":"false") << ",\"progress\":" << m->progress() << ",\"halted\":" << (m->constructionHalted()?"true":"false")
      << ",\"road\":" << (m->accessToRoad()?"true":"false") << ",\"employees\":" << m->employed() << ",\"max_employees\":" << m->maxEmployees() << ",\"cost\":" << goodsJson(cost) << ",\"stored\":" << goodsJson(stored) << ",\"used\":" << goodsJson(used)
      << ",\"needed\":" << goodsJson(needed) << ",\"lines\":[";
    bool first=true; for(const auto& line:lines) { if(!first) o << ','; first=false; o << quote(line); }
    o << "],\"description\":" << quote(description) << ",\"help_label\":" << quote(helpLabel)
      << ",\"help_fraction\":" << (sanctuary&&finished?sanctuary->helpTimeFraction():0.0) << ",\"sacrificing\":" << (sanctuary&&sanctuary->sacrificing()?"true":"false")
      << ",\"god_abroad\":" << (sanctuary&&sanctuary->godAbroad()?"true":"false") << attackInfo(sanctuary) << '}';
    return o.str();
}
// The pieces of a pyramid. How many tiles on a side a piece covers (the tile of a larger piece is its far corner; its other tiles are
// filler parts that extend toward smaller x and y).
int pyramidPieceSize(const eBuildingType type) {
    switch(type) {
    case eBuildingType::pyramidMonument: case eBuildingType::pyramidAltar: return 2;
    case eBuildingType::pyramidTemple: return 4;
    case eBuildingType::pyramidObservatory: return 5;
    case eBuildingType::pyramidMuseum: return 6;
    default: return 1;
    }
}
// Whether a level of a pyramid is black marble (the engine does not check the index; a piece may stand on the level above the last).
bool pyramidDark(const ePyramid* pyramid,const int level) {
    return pyramid && level>=0 && level<ePyramid::sLevels(pyramid->type()) && pyramid->darkLevel(level);
}
// The model of a finished wall piece: the face or corner it is, with the stairs, eagle or wreath it carries, in light or dark marble.
std::string pyramidWallAsset(const eOrientation direction,const int special,const int elevation,const bool dark) {
    int tile=(int(direction)+1)%8;
    if(direction==eOrientation::bottomRight && special) tile=special==1?11:special==2?12:9;
    if(direction==eOrientation::bottomLeft && special) tile=special==1?14:special==2?13:16;
    if(dark) tile+=17;
    if(elevation==0) { if(tile>8) --tile; if(tile>25) --tile; }
    return std::string(elevation==0?"pyramid_p2_":"pyramid_p1_")+std::to_string(tile);
}
// The model of a finished piece of the given kind; `god` is the god of a statue or monument, `dark` the level the piece stands on.
std::string pyramidPieceAsset(const ePyramidPlan::eKind kind,const eOrientation direction,const int special,const int elevation,const bool dark,
                              const bool darkBelow,const eGodType god) {
    switch(kind) {
    case ePyramidPlan::eKind::wall: return pyramidWallAsset(direction,special,elevation,dark);
    case ePyramidPlan::eKind::top: return dark?"pyramid_p1_25":"pyramid_p1_8";
    case ePyramidPlan::eKind::tile:
        // The paving of the palace on a light level, black basalt on a dark one, and the two emblems.
        return special==0?(darkBelow?"pyramid_p2_32":"palace_tile_plain"):(special==1?"pyramid_p2_33":"pyramid_p2_34");
    case ePyramidPlan::eKind::statue: return "sanctuary_statue_"+godAsset(god);
    case ePyramidPlan::eKind::monument: return "sanctuary_monument_"+godAsset(god);
    case ePyramidPlan::eKind::altar: return "sanctuary_altar";
    case ePyramidPlan::eKind::temple: return "sanctuary_temple_0";
    case ePyramidPlan::eKind::observatory: return "observatory";
    case ePyramidPlan::eKind::museum: return "museum";
    }
    return "unconverted";
}
std::string asset(eBuilding* b) {
    switch(b->type()) {
    case eBuildingType::hospital: return "hospital";
    case eBuildingType::fountain: return "fountain";
    case eBuildingType::warehouse: return "warehouse";
    case eBuildingType::olivePress: return "olive_press";
    case eBuildingType::watchPost: return "watch_post";
    case eBuildingType::maintenanceOffice: return "maintenance_office";
    case eBuildingType::taxOffice: return "tax_office";
    case eBuildingType::gymnasium: return "gymnasium";
    case eBuildingType::granary: return "granary";
    case eBuildingType::commonHouse: return "common_house_" + std::to_string(std::clamp(static_cast<eSmallHouse*>(b)->level(),0,6)) + "a";
    // The remastered estate: five levels, two variants a household chooses by its seed (the SDL view's rule).
    case eBuildingType::eliteHousing: return "elite_house_" + std::to_string(std::clamp(static_cast<eEliteHousing*>(b)->level(),0,4)) + (((b->seed()%2)+2)%2?"b":"a");
    case eBuildingType::road: case eBuildingType::avenue: return "road";
    case eBuildingType::bibliotheke: return "bibliotheke";
    case eBuildingType::observatory: return "observatory";
    case eBuildingType::university: return "university";
    case eBuildingType::laboratory: return "laboratory";
    case eBuildingType::inventorsWorkshop: return "inventors_workshop";
    case eBuildingType::museum: return "museum";
    case eBuildingType::wheatFarm: return "farm";
    case eBuildingType::carrotsFarm: return "farm";
    case eBuildingType::onionsFarm: return "farm";
    case eBuildingType::huntingLodge: return "hunting_lodge";
    case eBuildingType::fishery: return "fishery";
    case eBuildingType::cardingShed: return "carding_shed";
    case eBuildingType::growersLodge: return "growers_lodge";
    case eBuildingType::orangeTendersLodge: return "orange_tenders_lodge";
    case eBuildingType::tradePost: return "trade_post";
    case eBuildingType::pier: return "harbour";
    case eBuildingType::agoraSpace: return "agora_space";
    case eBuildingType::foodVendor: return "food_vendor";
    case eBuildingType::fleeceVendor: return "fleece_vendor";
    case eBuildingType::oilVendor: return "oil_vendor";
    case eBuildingType::wineVendor: return "wine_vendor";
    case eBuildingType::armsVendor: return "arms_vendor";
    case eBuildingType::horseTrainer: return "horse_vendor";
    case eBuildingType::chariotVendor: return "chariot_vendor";
    case eBuildingType::timberMill: return "timber_mill";
    case eBuildingType::masonryShop: return "masonry_shop";
    case eBuildingType::foundry: return "foundry";
    case eBuildingType::winery: return "winery";
    case eBuildingType::sculptureStudio: return "sculpture_studio";
    case eBuildingType::artisansGuild: return "artisans_guild";
    case eBuildingType::palace: return "palace";
    case eBuildingType::park: return "park";
    case eBuildingType::commemorative: return "commemorative_"+std::to_string(static_cast<eCommemorative*>(b)->id());
    case eBuildingType::podium: return "podium";
    case eBuildingType::college: return "college";
    case eBuildingType::dramaSchool: return "drama_school";
    case eBuildingType::theater: return "theater";
    case eBuildingType::mint: return "mint";
    case eBuildingType::corral: return "corral";
    case eBuildingType::dairy: return "dairy";
    case eBuildingType::armory: return "armory";
    case eBuildingType::chariotFactory: return "chariot_factory";
    case eBuildingType::bench: return "deco_bench";
    case eBuildingType::flowerGarden: return "deco_flower_garden";
    case eBuildingType::gazebo: return "deco_gazebo";
    case eBuildingType::birdBath: return "deco_birdbath";
    case eBuildingType::shortObelisk: return "deco_short_obelisk";
    case eBuildingType::tallObelisk: return "deco_tall_obelisk";
    case eBuildingType::hedgeMaze: return "deco_hedge_maze";
    case eBuildingType::fishPond: return "deco_fish_pond";
    case eBuildingType::shellGarden: return "deco_shell_garden";
    case eBuildingType::sundial: return "deco_sundial";
    case eBuildingType::dolphinSculpture: return "deco_dolphin";
    case eBuildingType::orrery: return "deco_orrery";
    case eBuildingType::spring: return "deco_spring";
    case eBuildingType::topiary: return "deco_topiary";
    case eBuildingType::baths: return "baths";
    case eBuildingType::stoneCircle: return "deco_stone_circle";
    case eBuildingType::achillesHall: return "hero_hall_achilles";
    case eBuildingType::atalantaHall: return "hero_hall_atalanta";
    case eBuildingType::bellerophonHall: return "hero_hall_bellerophon";
    case eBuildingType::herculesHall: return "hero_hall_hercules";
    case eBuildingType::jasonHall: return "hero_hall_jason";
    case eBuildingType::odysseusHall: return "hero_hall_odysseus";
    case eBuildingType::perseusHall: return "hero_hall_perseus";
    case eBuildingType::theseusHall: return "hero_hall_theseus";
    case eBuildingType::refinery: return "refinery";
    case eBuildingType::blackMarbleWorkshop: return "black_marble_workshop";
    // Native livestock reservations and sanctuary owners have no independent geometry.
    // Their animals and modular components are represented separately in the snapshot.
    case eBuildingType::goat: case eBuildingType::sheep: case eBuildingType::cattle:
    case eBuildingType::templeAphrodite: case eBuildingType::templeApollo: case eBuildingType::templeAres:
    case eBuildingType::templeArtemis: case eBuildingType::templeAthena: case eBuildingType::templeAtlas:
    case eBuildingType::templeDemeter: case eBuildingType::templeDionysus: case eBuildingType::templeHades:
    case eBuildingType::templeHephaestus: case eBuildingType::templeHera: case eBuildingType::templeHermes:
    case eBuildingType::templePoseidon: case eBuildingType::templeZeus:
        return "native_marker";
    case eBuildingType::crosswalk: case eBuildingType::boulevard: return "terrain_road";
    case eBuildingType::oliveTree: case eBuildingType::vine: case eBuildingType::orangeTree: {
        const auto plant=static_cast<eResourceBuilding*>(b);
        const std::string kind=b->type()==eBuildingType::oliveTree?"olive":b->type()==eBuildingType::vine?"vine":"orange";
        return kind+"_"+std::to_string(std::clamp(plant->ripe(),0,5));
    }
    case eBuildingType::palaceTile: return static_cast<ePalaceTile*>(b)->other()?"palace_tile_lamp":"palace_tile_plain";
    case eBuildingType::wall: {
        const auto r=b->tileRect(); auto& board=b->getBoard(); int mask=0;
        const auto connected=[&](int x,int y) { const auto t=board.tile(x,y); if(!t || !t->underBuilding()) return false;
            const auto kind=t->underBuilding()->type(); return kind==eBuildingType::wall || kind==eBuildingType::tower || kind==eBuildingType::gatehouse; };
        if(connected(r.x-1,r.y)) mask|=1; if(connected(r.x+1,r.y)) mask|=2;
        if(connected(r.x,r.y-1)) mask|=4; if(connected(r.x,r.y+1)) mask|=8;
        return "wall_"+std::to_string(mask);
    }
    case eBuildingType::tower: return "tower";
    case eBuildingType::gatehouse: return "gatehouse";
    case eBuildingType::temple: return "sanctuary_temple_"+std::to_string(static_cast<eTempleBuilding*>(b)->pieceId());
    case eBuildingType::templeTile: return "sanctuary_court_"+std::to_string(std::clamp(static_cast<eTempleTileBuilding*>(b)->id(),0,5));
    case eBuildingType::templeStatue: return "sanctuary_statue_"+godAsset(static_cast<eTempleStatueBuilding*>(b)->godType());
    case eBuildingType::templeMonument: return "sanctuary_monument_"+godAsset(static_cast<eTempleMonumentBuilding*>(b)->godType());
    case eBuildingType::templeAltar: return "sanctuary_altar";
    case eBuildingType::pyramidPart: return "native_marker"; // a filler tile of a larger piece: its piece has the model
    case eBuildingType::pyramidWall: {
        const auto wall=static_cast<ePyramidWall*>(b); const auto pyramid=static_cast<ePyramid*>(wall->monument());
        return pyramidWallAsset(wall->orientation(),wall->special(),wall->elevation(),pyramidDark(pyramid,wall->elevation()));
    }
    case eBuildingType::pyramidTop: {
        const auto top=static_cast<ePyramidTop*>(b); const auto pyramid=static_cast<ePyramid*>(top->monument());
        return pyramidPieceAsset(ePyramidPlan::eKind::top,eOrientation::top,0,top->elevation(),pyramidDark(pyramid,top->elevation()),false,eGodType::zeus);
    }
    case eBuildingType::pyramidTile: {
        const auto tile=static_cast<ePyramidTile*>(b); const auto pyramid=static_cast<ePyramid*>(tile->monument());
        return pyramidPieceAsset(ePyramidPlan::eKind::tile,eOrientation::top,tile->type(),tile->elevation(),false,pyramidDark(pyramid,tile->elevation()-1),eGodType::zeus);
    }
    case eBuildingType::pyramidStatue: return pyramidPieceAsset(ePyramidPlan::eKind::statue,eOrientation::top,0,0,false,false,static_cast<ePyramidStatue*>(b)->type());
    case eBuildingType::pyramidMonument: return pyramidPieceAsset(ePyramidPlan::eKind::monument,eOrientation::top,0,0,false,false,static_cast<ePyramidMonument*>(b)->type());
    case eBuildingType::pyramidAltar: return "sanctuary_altar";
    case eBuildingType::pyramidTemple: return "sanctuary_temple_0";
    case eBuildingType::pyramidObservatory: return "observatory";
    case eBuildingType::pyramidMuseum: return "museum";
    // The rest of the SDL build menu (3 October).
    case eBuildingType::stadium: return "stadium";
    case eBuildingType::horseRanch: return "horse_ranch";
    case eBuildingType::horseRanchEnclosure: return "horse_ranch_enclosure";
    case eBuildingType::urchinQuay: return "urchin_quay";
    case eBuildingType::triremeWharf: return "trireme_wharf";
    case eBuildingType::doricColumn: return "column_doric";
    case eBuildingType::ionicColumn: return "column_ionic";
    case eBuildingType::corinthianColumn: return "column_corinthian";
    case eBuildingType::waterPark: return "deco_water_park";
    case eBuildingType::hippodromePiece: return "hippodrome_"+std::to_string(std::clamp(static_cast<eHippodromePiece*>(b)->id(),0,7));
    // A god's monument is the god's colossus (the sanctuary monument's model) on the palace's paving.
    case eBuildingType::godMonument: return "sanctuary_monument_"+godAsset(static_cast<eGodMonument*>(b)->god());
    case eBuildingType::godMonumentTile: return "palace_tile_plain";
    default: return "unconverted";
    }
}
// Archers patrol the tops of walls and towers: how far above the ground, in tiles, the figure stands on its tile
// (the walkway of a wall piece, the platform of a tower; the models are art/walls and art/tower).
double perch(eCharacter* c,eTile* t) {
    if(c->type()!=eCharacterType::archer && c->type()!=eCharacterType::archerPoseidon) return 0;
    switch(t->underBuildingType()) {
    case eBuildingType::wall: return .8;
    case eBuildingType::tower: return 2.57;
    default: return 0;
    }
}
std::string walkerAsset(eCharacter* c) {
    switch(c->type()) {
    case eCharacterType::healer: return "physician";
    case eCharacterType::philosopher: return "philosopher";
    case eCharacterType::settler: return "settlers1";
    case eCharacterType::boar: return "animal_boar";
    case eCharacterType::deer: return "animal_deer";
    case eCharacterType::wolf: return "animal_wolf";
    case eCharacterType::donkey: return "animal_donkey";
    case eCharacterType::ox: return "animal_ox";
    case eCharacterType::trailer: return "trailer";
    case eCharacterType::grower: return "walker_grower";
    case eCharacterType::shepherd: return "walker_shepherd";
    case eCharacterType::trader: return "walker_trader";
    case eCharacterType::porter: return "walker_porter";
    case eCharacterType::hunter: return "walker_hunter";
    case eCharacterType::marbleMiner: return "walker_marbleminer";
    case eCharacterType::lumberjack: return "walker_lumberjack";
    case eCharacterType::bronzeMiner: return "walker_bronzeminer";
    case eCharacterType::artisan: return "walker_artisan";
    case eCharacterType::scholar: return "walker_scholar";
    case eCharacterType::astronomer: return "walker_astronomer";
    case eCharacterType::inventor: return "walker_inventor";
    case eCharacterType::curator: return "walker_curator";
    case eCharacterType::taxCollector: return "walker_taxcollector";
    case eCharacterType::watchman: return "walker_watchman";
    case eCharacterType::waterDistributor: return "walker_waterdistributor";
    case eCharacterType::fireFighter: return "walker_firefighter";
    case eCharacterType::aphrodite: return "walker_aphrodite";
    case eCharacterType::apollo: return "walker_apollo";
    case eCharacterType::ares: return "walker_ares";
    case eCharacterType::artemis: return "walker_artemis";
    case eCharacterType::athena: return "walker_athena";
    case eCharacterType::atlas: return "walker_atlas";
    case eCharacterType::demeter: return "walker_demeter";
    case eCharacterType::dionysus: return "walker_dionysus";
    case eCharacterType::hades: return "walker_hades";
    case eCharacterType::hephaestus: return "walker_hephaestus";
    case eCharacterType::hera: return "walker_hera";
    case eCharacterType::hermes: return "walker_hermes";
    case eCharacterType::poseidon: return "walker_poseidon";
    case eCharacterType::zeus: return "walker_zeus";
    case eCharacterType::achilles: return "walker_achilles";
    case eCharacterType::atalanta: return "walker_atalanta";
    case eCharacterType::bellerophon: return "walker_bellerophon";
    case eCharacterType::hercules: return "walker_hercules";
    case eCharacterType::jason: return "walker_jason";
    case eCharacterType::odysseus: return "walker_odysseus";
    case eCharacterType::perseus: return "walker_perseus";
    case eCharacterType::theseus: return "walker_theseus";
    case eCharacterType::fishingBoat: return "fishing_boat";
    case eCharacterType::tradeBoat: return "trade_ship";
    case eCharacterType::peddler: return "walker_peddler";
    case eCharacterType::sick: return "walker_sick";
    case eCharacterType::gymnast: return "walker_gymnast";
    case eCharacterType::actor: return "walker_actor";
    case eCharacterType::competitor: return "walker_competitor";
    case eCharacterType::urchinGatherer: return "walker_urchin";
    case eCharacterType::homeless: return "settlers1";
    case eCharacterType::sheep: return static_cast<eDomesticatedAnimal*>(c)->canCollect()?"animal_sheep_fleeced":"animal_sheep_nude";
    // Goats of a dairy, cattle of a corral and the horses of a ranch's paddock; the goatherd is dressed as the shepherd.
    case eCharacterType::goat: return "animal_goat";
    case eCharacterType::cattle1: case eCharacterType::cattle2: case eCharacterType::cattle3: return "animal_cattle";
    case eCharacterType::horse: return "animal_horse";
    case eCharacterType::goatherd: return "walker_shepherd";
    // The navy and its enemies, the Greek war chariot, the herd's bull, the expansion's miners, the corral's butcher (dressed as the
    // hunter), the rioters (in a citizen's dress, the peddler's and the scholar's for the elite).
    case eCharacterType::trireme: return "trireme";
    case eCharacterType::enemyBoat: return "enemy_boat";
    case eCharacterType::chariot: return "walker_greekchariot";
    case eCharacterType::bull: return "animal_ox";
    case eCharacterType::silverMiner: return "walker_silverminer";
    case eCharacterType::orichalcMiner: return "walker_orichalcminer";
    case eCharacterType::butcher: return "walker_hunter";
    case eCharacterType::disgruntled: return "walker_peddler";
    case eCharacterType::eliteCitizen: return "walker_scholar";
    case eCharacterType::archer: return "walker_archer";
    case eCharacterType::archerPoseidon: return "walker_archerposeidon";
    case eCharacterType::hoplitePoseidon: return "walker_hopliteposeidon";
    case eCharacterType::chariotPoseidon: return "walker_chariotposeidon";
    // The player's soldiers (the Roman army of the Greek cities, the guard of the Poseidon cities) and every army the engine can field.
    case eCharacterType::hoplite: return "walker_hoplite";
    case eCharacterType::rockThrower: return "walker_rockthrower";
    case eCharacterType::horseman: return "walker_horseman";
    case eCharacterType::greekHoplite: return "walker_greekhoplite";
    case eCharacterType::greekRockThrower: return "walker_greekrockthrower";
    case eCharacterType::greekHorseman: return "walker_greekhorseman";
    case eCharacterType::trojanHoplite: return "walker_trojanhoplite";
    case eCharacterType::trojanSpearthrower: return "walker_trojanspearthrower";
    case eCharacterType::trojanHorseman: return "walker_trojanhorseman";
    case eCharacterType::centaurHorseman: return "walker_centaurhorseman";
    case eCharacterType::centaurArcher: return "walker_centaurarcher";
    case eCharacterType::persianHoplite: return "walker_persianhoplite";
    case eCharacterType::persianArcher: return "walker_persianarcher";
    case eCharacterType::persianHorseman: return "walker_persianhorseman";
    case eCharacterType::oceanidHoplite: return "walker_oceanidhoplite";
    case eCharacterType::oceanidSpearthrower: return "walker_oceanidspearthrower";
    case eCharacterType::egyptianHoplite: return "walker_egyptianhoplite";
    case eCharacterType::egyptianArcher: return "walker_egyptianarcher";
    case eCharacterType::egyptianChariot: return "walker_egyptianchariot";
    case eCharacterType::atlanteanHoplite: return "walker_atlanteanhoplite";
    case eCharacterType::atlanteanArcher: return "walker_atlanteanarcher";
    case eCharacterType::atlanteanChariot: return "walker_atlanteanchariot";
    case eCharacterType::phoenicianHorseman: return "walker_phoenicianhorseman";
    case eCharacterType::phoenicianArcher: return "walker_phoenicianarcher";
    case eCharacterType::mayanHoplite: return "walker_mayanhoplite";
    case eCharacterType::mayanArcher: return "walker_mayanarcher";
    case eCharacterType::amazon: return static_cast<eAmazon*>(c)->isArcher()?"walker_amazonarcher":"walker_amazonspear";
    case eCharacterType::aresWarrior: return "walker_areswarrior";
    // The seventeen monsters (all of eMonsterType): one model each, with fight, fight2 and die clips.
    case eCharacterType::calydonianBoar: return "walker_calydonianboar";
    case eCharacterType::cerberus: return "walker_cerberus";
    case eCharacterType::chimera: return "walker_chimera";
    case eCharacterType::cyclops: return "walker_cyclops";
    case eCharacterType::dragon: return "walker_dragon";
    case eCharacterType::echidna: return "walker_echidna";
    case eCharacterType::harpies: return "walker_harpies";
    case eCharacterType::hector: return "walker_hector";
    case eCharacterType::hydra: return "walker_hydra";
    case eCharacterType::kraken: return "walker_kraken";
    case eCharacterType::maenads: return "walker_maenads";
    case eCharacterType::medusa: return "walker_medusa";
    case eCharacterType::minotaur: return "walker_minotaur";
    case eCharacterType::scylla: return "walker_scylla";
    case eCharacterType::sphinx: return "walker_sphinx";
    case eCharacterType::talos: return "walker_talos";
    case eCharacterType::satyr: return "walker_satyr";
    case eCharacterType::cartTransporter: return static_cast<eCartTransporter*>(c)->cartType()==eCartTransporterType::ox?"walker_oxhandler":"transporter";
    default: return "unconverted";
    }
}

}
eSimulationService::~eSimulationService() { close(); }
// Lets go of the running city (handlers, caches, undo, events) but keeps the campaign: between two episodes of a game
// the session moves to another board, or back to the same one, without losing what the campaign remembers.
void eSimulationService::detach() {
    eSoundVector::setSink(nullptr);
    eMusic::setModeSink(nullptr);
    { std::lock_guard<std::mutex> lock(mSoundLock); mSounds.clear(); mMusicMode = "city"; }
    if(mBoard) {
        mBoard->waitUntilFinished();
        mBoard->setEventHandler(nullptr); mBoard->setMessageShower(nullptr);
        mBoard->setTipShower(nullptr); mBoard->setEpisodeFinishedHandler(nullptr); mBoard->setEnlistForcesRequest(nullptr);
    }
    mEvents.clear(); mEnlist.reset(); mBoard = nullptr;
    mTerrainState.clear(); mTerrainKnown.clear(); mBuildingCache.clear(); mIds.clear(); mSentTerrain = false; mAccumulator = 0; mProfile = Profile{}; mSentBanners.clear();
    mOrientations.clear(); mUndoBuildings.clear(); mUndoRefund = 0; mDemolitionTarget.clear(); mDemolitionToken = 0;
    mInspectionTarget.clear(); ++mInspectionToken;
    mPaused = true; mBlocked = false; mTerminal = false; mSequence = mTicks = 0; mNextId = mNextEvent = 1;
    mVictory = false; mAwaiting = false;
}
void eSimulationService::close() {
    detach();
    mCampaign.reset(); mView.reset();
}
void eSimulationService::setSaveDirectory(const std::string& directory) { mSaveDir = directory; }
std::string eSimulationService::save(const std::string& name) {
    namespace fs = std::filesystem;
    if(!mBoard || !mCampaign || !mView) return "{\"error\":\"city_not_loaded\"}";
    if(mSaveDir.empty()) return "{\"error\":\"save_directory_required\"}";
    if(mBlocked) return "{\"error\":\"pending_decision\"}";
    if(name.empty() || name.size() > 64 || name[0] == '.') return "{\"error\":\"invalid_save_name\"}";
    for(const unsigned char c : name) {
        if(!(std::isalnum(c) || c >= 0x80 || c == ' ' || c == '_' || c == '-' || c == '.')) return "{\"error\":\"invalid_save_name\"}";
    }
    std::error_code ec;
    fs::create_directories(mSaveDir, ec);
    const auto directory = fs::weakly_canonical(mSaveDir, ec);
    if(ec) return "{\"error\":\"save_directory_unavailable\"}";
    const auto target = directory / (name + ".ez");
    std::error_code same;
    if(!mDesignatedSave.empty() && fs::exists(target, same) && fs::equivalent(target, mDesignatedSave, same))
        return "{\"error\":\"designated_test_save_protected\"}";
    mBoard->waitUntilFinished();
    auto temporary = target; temporary += ".tmp";
    {
        std::ofstream file(temporary, std::ios::out | std::ios::binary | std::ios::trunc);
        if(!file) return "{\"error\":\"save_failed\"}";
        eWriteTarget sink(&file);
        eWriteStream dst(sink);
        dst.writeFormat("eZeus.ez");
        auto view = *mView; view.fPaused = mPaused;
        view.write(dst);
        mCampaign->write(dst);
        file.flush();
        if(!file) { fs::remove(temporary, ec); return "{\"error\":\"save_failed\"}"; }
    }
    const auto bytes = fs::file_size(temporary, ec);
    fs::rename(temporary, target, ec);
    if(ec) { fs::remove(temporary, ec); return "{\"error\":\"save_failed\"}"; }
    return "{\"saved\":" + quote(name) + ",\"bytes\":" + std::to_string(bytes) + "}";
}
// Everything a session needs before a campaign can be read or a city built: the game directories, the language
// tables, the number tables and the textures (without any SDL video or audio).
void eSimulationService::prepare(const std::string& engine, const std::string& lang) {
    const auto allowed = std::filesystem::path(engine) / "Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez";
    mDesignatedSave = std::filesystem::exists(allowed) ? std::filesystem::canonical(allowed).string() : "";
    eGameDir::initializeEmbedded(engine);
    // No SDL_Init(VIDEO/AUDIO), window, renderer, music object or native UI.
    static eSounds sounds;
    eNumbers::sLoad(); eLanguage::reload(lang); eMessages::reload();
    eSettings settings;
    settings.fTinyTextures = settings.fMediumTextures = settings.fLargeTextures = false;
    settings.fSmallTextures = true;
    eGameTextures::setSettings(settings);
    static bool textures = false;
    if(!textures) { eGameTextures::initialize(nullptr); textures = true; }
    // The sound tables (file names only: nothing is decoded here). The voices follow the language.
    eGameDir::setAudioLanguage(lang);
    static bool sounds_loaded = false;
    if(!sounds_loaded) { eSounds::load(); sounds_loaded = true; } else eSounds::reload();
    // The layouts of the sanctuaries (eZeus/Sanctuaries): a new one is previewed and built from them.
    eSanctBlueprints::load();
}
std::string eSimulationService::open(const std::string& engine, const std::string& save, const std::string& lang) {
    close();
    const auto openStart = std::chrono::steady_clock::now(); auto phaseStart = openStart;
    const auto phase = [&](int index) {
        const auto now = std::chrono::steady_clock::now();
        mOpenProfile[index] = std::chrono::duration<double,std::micro>(now-phaseStart).count(); phaseStart = now;
    };
    const auto allowed = std::filesystem::path(engine) / "Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez";
    std::error_code existing;
    if(!std::filesystem::exists(save, existing)) return "{\"error\":\"designated_test_save_required\"}";
    const auto requested = std::filesystem::canonical(save);
    const auto designated = std::filesystem::exists(allowed) ? std::filesystem::canonical(allowed).string() : "";
    bool permitted = requested == designated;
    if(!permitted && !mSaveDir.empty() && requested.extension() == ".ez") {
        std::error_code ignored;
        const auto directory = std::filesystem::weakly_canonical(mSaveDir, ignored);
        permitted = !ignored && requested.parent_path() == directory;
    }
    if(!permitted) return "{\"error\":\"designated_test_save_required\"}";
    prepare(engine, lang);
    phase(0);
    phase(1);
    std::ifstream file(save, std::ios::binary);
    eReadSource source(&file); eReadStream src(source); src.readFormat();
    if(src.format() != "eZeus.ez" || src.formatVersion() > eFileFormat::version)
        return "{\"error\":\"incompatible_save\"}";
    const auto readStart = std::chrono::steady_clock::now();
    const auto sub = [&](int index, std::chrono::steady_clock::time_point& from) {
        const auto now = std::chrono::steady_clock::now();
        mOpenProfile[index] = std::chrono::duration<double,std::micro>(now-from).count(); from = now;
    };
    auto subStart = readStart;
    eGameWidgetSettings view; view.read(src);
    mView = std::make_shared<eGameWidgetSettings>(view);
    sub(6,subStart);
    mCampaign = std::make_shared<eCampaign>(); mCampaign->read(src);
    sub(7,subStart);
    mCampaign->loadStrings(); mCampaign->loadNumbers();
    sub(8,subStart);
    src.handlePostFuncs();
    sub(9,subStart);
    phase(2);
    if(!file) { close(); return "{\"error\":\"invalid_city\"}"; }
    return enter(phase);
}
// The adventures a new game can start from (the same list as the SDL menu), in the language of the session.
std::string eSimulationService::adventures(const std::string& engine, const std::string& lang) {
    prepare(engine, lang);
    std::ostringstream out; out << "{\"kind\":\"adventures\",\"adventures\":[";
    bool first = true;
    for(auto glossary : eAdventureList::scan()) {
        eStringHelpers::replaceSpecial(glossary.fIntroduction);
        if(!first) out << ','; first = false;
        out << "{\"kind\":\"" << (glossary.fIsPak ? "pak" : "folder") << "\",\"ref\":" << quote(glossary.fIsPak ? glossary.fPakPath : glossary.fFolderName)
            << ",\"title\":" << quote(glossary.fTitle) << ",\"introduction\":" << quote(glossary.fIntroduction)
            << ",\"bitmap\":" << glossary.fBitmap << '}';
    }
    out << "]}"; return out.str();
}
// Starts a new game from one of the listed adventures: the campaign is read, its first episode begins paused.
std::string eSimulationService::openAdventure(const std::string& engine, const std::string& kind, const std::string& ref, const std::string& lang) {
    close();
    prepare(engine, lang);
    const bool pak = kind == "pak";
    if(!pak && kind != "folder") return "{\"error\":\"unknown_adventure\"}";
    // Only what the listing offers: a path or folder name supplied by anyone else is never opened.
    eCampaignGlossary chosen; bool found = false;
    for(const auto& glossary : eAdventureList::scan()) {
        if(glossary.fIsPak == pak && (pak ? glossary.fPakPath : glossary.fFolderName) == ref) { chosen = glossary; found = true; break; }
    }
    if(!found) return "{\"error\":\"unknown_adventure\"}";
    const auto began = std::chrono::steady_clock::now(); auto phaseStart = began;
    const auto phase = [&](int index) {
        const auto now = std::chrono::steady_clock::now();
        mOpenProfile[index] = std::chrono::duration<double,std::micro>(now-phaseStart).count(); phaseStart = now;
    };
    mView = std::make_shared<eGameWidgetSettings>(); mView->fPaused = true;
    mCampaign = std::make_shared<eCampaign>();
    if(pak) mCampaign->readPak(chosen.fTitle, chosen.fPakPath);
    else if(!mCampaign->load(chosen.fFolderName)) { close(); return "{\"error\":\"adventure_unreadable\"}"; }
    if(!mCampaign->currentEpisode() || !mCampaign->currentEpisode()->fBoard) { close(); return "{\"error\":\"invalid_adventure\"}"; }
    mCampaign->startEpisode();
    return enter(phase);
}
// From a read campaign to a running session: the board, the map extent, the event handlers and the first snapshot.
std::string eSimulationService::enter(const std::function<void(int)>& phase) {
    if(!mCampaign->currentEpisode() || !mCampaign->currentEpisode()->fBoard) { close(); return "{\"error\":\"invalid_city\"}"; }
    mVictory = false; mAwaiting = false;
    mBoard = mCampaign->currentEpisode()->fBoard;
    mBoard->updateAppealMapIfNeeded(); mBoard->waitUntilFinished();
    phase(3);
    mX = mY = 1000000; int maxX = -1000000, maxY = -1000000;
    eTile* focus = nullptr;
    const auto owner = mBoard->personPlayer();
    long long ownedX = 0, ownedY = 0, owned = 0;
    mBoard->iterateOverAllTiles([&](eTile* t) {
        mX = std::min(mX,t->x()); mY = std::min(mY,t->y());
        maxX = std::max(maxX,t->x()); maxY = std::max(maxY,t->y());
        if(mBoard->cityIdToPlayerId(t->cityId()) == owner) { ownedX += t->x(); ownedY += t->y(); ++owned; }
        if(auto b = t->underBuilding()) {
            if(!focus && b->type() == eBuildingType::commonHouse) focus = b->centerTile();
            if(b->type() == eBuildingType::hospital) focus = b->centerTile();
        }
    });
    mW = maxX-mX+1; mH = maxY-mY+1;
    // A saved city opens on its houses; a new one on the middle of the player's own land.
    mFocusX = focus ? focus->x() : (owned ? int(ownedX/owned) : mX+mW/2);
    mFocusY = focus ? focus->y() : (owned ? int(ownedY/owned) : mY+mH/2);
    phase(4);
    mBoard->setEventHandler([this](eEvent kind, eEventData& data) {
        // The engine's own events (monthly summary, early warnings) are worded here, as the SDL view words them.
        if(eEngineMessages::handles(kind)) {
            std::string title, text;
            if(eEngineMessages::eventText(*mBoard, kind, data, title, text)) notify(title, text, data, {}, eEventName(int(kind)));
            return;
        }
        // The gods', monsters', heroes', invasions' and requests' words, which the SDL view also writes in its own handlers.
        {
            std::string title, text, brief;
            const auto words = eEventWords::eventText(kind, data, title, text, false, &brief);
            if(words != eEventWords::eResult::notHandled) {
                if(words == eEventWords::eResult::worded) notify(title, text, data, brief, eEventName(int(kind)));
                return;
            }
        }
        const auto msg = eEventMessage(kind);
        notify(msg ? msg->fFull.fTitle : eEventName(int(kind)),
               msg ? msg->fFull.fText : data.fReason, data, msg ? msg->fCondensed.fText : std::string(), eEventName(int(kind)));
    });
    mBoard->setMessageShower([this](eEventData& data, const eMessageType& msg) {
        notify(msg.fFull.fTitle,msg.fFull.fText,data,msg.fCondensed.fText);
    });
    mBoard->setTipShower([this](const ePlayerCityTarget&, const std::string& text) { notify("City",text,eEventData()); });
    mBoard->setEnlistForcesRequest([this](const eEnlistedForces& forces,const std::vector<eCityId>& cids,const std::vector<std::string>& cnames,
                                          const std::vector<eHeroType>& heroesAbroad,const eGameBoard::eEnlistAction& action,const std::vector<eResourceType>& plunder) {
        auto session=std::make_shared<eEnlistSession>();
        session->forces=forces; session->cids=cids; session->cnames=cnames; session->heroesAbroad=heroesAbroad; session->action=action; session->plunder=plunder;
        mEnlist=session;
    });
    // The goals are fulfilled: the game stops here and the front end shows the result (see finish_episode).
    mBoard->setEpisodeFinishedHandler([this]() { mBlocked = mTerminal = mVictory = true; notify("Episode complete","The goals of this episode are fulfilled.",eEventData()); });
    // Test sessions never write saves or settings.
    mBoard->setAutosaver(nullptr);
    // Every sound the simulation asks for reaches the front end as a file name (see `sounds` in the snapshot).
    eSoundVector::setSink([this](const std::string& path) {
        std::lock_guard<std::mutex> lock(mSoundLock);
        if(mSounds.size() < 64) mSounds.push_back(path);
    });
    // The simulation chooses between peaceful and battle music (invasions, attacking gods and monsters).
    eMusic::setModeSink([this](const std::string& mode) {
        std::lock_guard<std::mutex> lock(mSoundLock);
        if(mode == "city" || mode == "battle") mMusicMode = mode;
    });
    auto first = snapshot(true);
    phase(5);
    return first;
}
void eSimulationService::notify(const std::string& title, const std::string& text, const eEventData& data, const std::string& brief, const std::string& kind) {
    const auto& target = data.fTarget;
    const auto pid = mBoard->personPlayer();
    if(target.isPlayerTarget() && target.playerTarget() != pid) return;
    if(target.isCityTarget() && mBoard->cityIdToPlayerId(target.cityTarget()) != pid) return;
    auto record = data; record.fDate = mBoard->date(); record.fPlayerName = "Hippodamus";
    // The SDL message box words these two itself, from the event's time.
    auto worded=eMessageBox::sFormatText(record,text);
    if(record.fType==eMessageEventType::generalRequestGranted) eStringHelpers::replaceAll(worded,"[time_allotted]",std::to_string(record.fTime));
    if(record.fType==eMessageEventType::troopsRequest) eStringHelpers::replaceAll(worded,"[travel_time]",std::to_string(record.fTime));
    // The condensed wording of the SDL view's pop-up cards: a toast shows it instead of the whole text (the log keeps the whole text).
    // A table entry with nothing useful in it ("n/a") is not offered.
    auto shortened=eMessageBox::sFormatText(record,brief);
    if(shortened.size()<12 || shortened==worded || shortened.find("[reason_phrase]")!=std::string::npos) shortened.clear();
    mEvents.emplace(mNextEvent++,Event{eMessageBox::sFormatTitle(record,title),worded,shortened,record,kind});
    if(data.fA0 || data.fA1 || data.fA2 || data.fCA0 || !data.fCCA0.empty()) mBlocked = true;
    // Keep pending decisions; only old informational notifications may be discarded.
    if(mEvents.size() > 100) for(auto it = mEvents.begin(); it != mEvents.end(); ++it) {
        const auto& d = it->second.data;
        if(!d.fA0 && !d.fA1 && !d.fA2 && !d.fCA0 && d.fCCA0.empty()) { mEvents.erase(it); break; }
    }
}
void eSimulationService::advance(double delta) {
    if(!mBoard || !std::isfinite(delta) || delta <= 0) return;
    const double ms = std::min(delta*1000.0,250.0);
    mBoard->advanceAnimTime(ms);
    mAccumulator += ms;
    int steps = 0;
    while(mAccumulator >= 50 && steps++ < 5) {
        mAccumulator -= 50;
        const auto began = std::chrono::steady_clock::now();
        if(!eSimulationStep(*mBoard,speeds[mSpeed],mSpeed==3,[this]() { return !mPaused && !mBlocked; })) {
            mBlocked = mTerminal = true; mVictory = false; notify("Episode lost","The native simulation ended this episode.",eEventData());
        }
        const double us = std::chrono::duration<double,std::micro>(std::chrono::steady_clock::now()-began).count();
        if(us > mProfile.tickMax) { mProfile.tickMax = us; mProfile.tickMaxAt = mTicks; } mProfile.tickSum += us; ++mProfile.ticks;
        ++mTicks;
    }
}
std::string eSimulationService::replay(const int ticks, const long long seed) {
    if(!mBoard) return "{\"error\":\"city_not_loaded\"}";
    if(ticks < 0 || ticks > 200000) return "{\"error\":\"invalid_replay\"}";
    if(seed >= 0) eRand::seed(static_cast<unsigned>(seed));
    eReplaySteps(*mBoard, ticks);
    std::string sections;
    const auto digest = eStateDigest(*mBoard, &sections);
    return "{\"digest\":\"" + digest + "\",\"sections\":\"" + sections + "\",\"off_thread_draws\":" +
           std::to_string(eRand::offThreadDraws()) + ",\"save\":\"" + eSaveDigest(*mBoard) + "\",\"ticks\":" +
           std::to_string(ticks) + ",\"seed\":" + std::to_string(seed) + "}";
}
std::string eSimulationService::diagnostics() const {
    std::ostringstream o;
    o << "{\"backend\":\"embedded_cpp\",\"loaded\":" << (mBoard?"true":"false")
      << ",\"sdl_video_initialized\":" << (SDL_WasInit(SDL_INIT_VIDEO)?"true":"false")
      << ",\"sdl_audio_initialized\":" << (SDL_WasInit(SDL_INIT_AUDIO)?"true":"false")
      << ",\"native_windows\":0,\"native_renderers\":0,\"ticks\":" << mTicks << ",\"step_ms\":50"
      << ",\"profile_us\":{\"snapshots\":" << mProfile.snapshots << ",\"tiles\":" << mProfile.tiles
      << ",\"buildings\":" << mProfile.buildings << ",\"walkers\":" << mProfile.walkers << ",\"events\":" << mProfile.events
      << ",\"total\":" << mProfile.total << ",\"max_total\":" << mProfile.maxTotal
      << ",\"ticks\":" << mProfile.ticks << ",\"tick_max\":" << mProfile.tickMax << ",\"tick_max_at\":" << mProfile.tickMaxAt
      << ",\"tick_mean\":" << (mProfile.ticks ? mProfile.tickSum/double(mProfile.ticks) : 0.0) << "}"
      << ",\"open_us\":{\"setup\":" << mOpenProfile[0] << ",\"textures\":" << mOpenProfile[1] << ",\"read\":" << mOpenProfile[2]
      << ",\"board\":" << mOpenProfile[3] << ",\"scan\":" << mOpenProfile[4] << ",\"snapshot\":" << mOpenProfile[5]
      << ",\"read_view\":" << mOpenProfile[6] << ",\"read_campaign\":" << mOpenProfile[7]
      << ",\"read_strings\":" << mOpenProfile[8] << ",\"read_post\":" << mOpenProfile[9] << "}}";
    return o.str();
}
// The sounds asked for since the last call, as paths relative to the game folder; the voice folders of every language
// are reported as Audio/Voice so the front end can pick the language it is showing.
std::vector<std::string> eSimulationService::takeSounds() {
    std::vector<std::string> taken;
    { std::lock_guard<std::mutex> lock(mSoundLock); taken.swap(mSounds); }
    const std::string root = eGameDir::path("");
    for(auto& path:taken) {
        if(path.rfind(root,0)==0) path.erase(0,root.size());
        for(const char* lang:{"Audio/Voice_en/","Audio/Voice_ru/"}) {
            const std::string prefix=lang;
            if(path.rfind(prefix,0)==0) path="Audio/Voice/"+path.substr(prefix.size());
        }
    }
    return taken;
}
std::string eSimulationService::snapshot(bool full) {
    if(!mBoard) return "{\"error\":\"city_not_loaded\"}";
    const auto clock = []() { return std::chrono::steady_clock::now(); };
    const auto micros = [](std::chrono::steady_clock::time_point a, std::chrono::steady_clock::time_point b) { return std::chrono::duration<double,std::micro>(b-a).count(); };
    const auto began = clock();
    auto& board = *mBoard; board.waitUntilFinished();
    full = full || !mSentTerrain; mSentTerrain = true;
    const auto pid = board.personPlayer(); std::ostringstream o; o << std::setprecision(7);
    o << "{\"protocol\":1,\"backend\":\"embedded_cpp\",\"sequence\":" << ++mSequence
      << ",\"time\":" << board.totalTime() << ",\"paused\":" << (mPaused?"true":"false")
      << ",\"running\":" << (!mPaused&&!mBlocked?"true":"false") << ",\"blocked\":" << (mBlocked?"true":"false")
      << ",\"undo_available\":" << (undoAvailable()?"true":"false")
      << ",\"speed\":" << mSpeed << ",\"money\":" << board.drachmas(pid) << ",\"population\":" << board.population(pid)
      << ",\"date\":[" << board.date().day() << ',' << int(board.date().month())+1 << ',' << board.date().year()
      << "],\"city_header\":{\"name\":" << quote(board.cityName(board.currentCityId())) << ",\"stock\":[";
    // Constant-size observations from native caches; no tile scan, resource refresh or simulation mutation.
    const auto cid = board.currentCityId();
    // Every native single resource through silver, plus the food total. Drachmas are already the treasury.
    // Counts remain the core's stored-stock cache (including zero); deposits are not stored goods.
    for(int i=-1;i<23;++i) {
        if(i>=0) o << ',';
        const auto resource = i<0 ? eResourceType::food : static_cast<eResourceType>(1 << i);
        o << "{\"resource\":" << int(resource) << ",\"count\":" << board.resourceCount(cid,resource) << '}';
    }
    const auto* employment = board.employmentData(cid);
    o << "],\"employment\":{\"employed\":" << (employment?employment->employed():0)
      << ",\"employable\":" << (employment?employment->employable():0)
      << ",\"vacancies\":" << (employment?employment->freeJobVacancies():0)
      << ",\"unemployed\":" << (employment?employment->unemployed():0) << "}}"
      << ",\"origin\":[" << mX << ',' << mY << "],\"extent\":[" << mW << ',' << mH << "],\"focus\":[" << mFocusX << ',' << mFocusY
      << "],\"size\":" << std::max(mW,mH) << ",\"" << (full?"tiles":"tile_changes") << "\":[";
    bool first = true; std::set<const void*> alive;
    const uint64_t generation = ++mGeneration;
    const size_t cells = size_t(mW)*size_t(mH);
    if(mTerrainState.size() != cells) { mTerrainState.assign(cells,{}); mTerrainKnown.assign(cells,0); }
    std::vector<BuildingRecord*> order; order.reserve(mBuildingCache.size()+16);
    // The altars of finished sanctuaries that have a rite on them now: each is shown as a scene (see the end of the walkers).
    struct AltarRite { const eTempleAltarBuilding* altar; int x, y, w, h, altitude; };
    std::vector<AltarRite> rites;
    bool buildingsChanged = full; size_t seenBuildings = 0; eBuilding* lastBuilding = nullptr;
    board.iterateOverAllTiles([&](eTile* t) {
        eBuilding* const b = t->underBuilding();
        const bool road = t->hasRoad();
        // Append read-only geometry observations; keep the original six tile
        // columns unchanged for reference/legacy consumers. No cosmetic RNG.
        const int geometry = (t->isElevationTile()?1:0) | (t->walkableElev()?2:0) |
            (t->isHalfSlope()?4:0) | (b && !road?8:0);
        // Appended column 8: the kind of road, so avenues and boulevards can be drawn apart
        // (0 none, 1 road, 2 avenue, 3 boulevard). Column 4 keeps its 0/1 meaning.
        const auto roadType = road ? t->underBuildingType() : eBuildingType::none;
        const int roadKind = !road ? 0 : roadType == eBuildingType::boulevard ? 3 : roadType == eBuildingType::avenue ? 2 : 1;
        const std::array<int,6> value{{t->doubleAltitude(),int(t->terrain()),road?1:0,geometry,t->characterDoubleAltitude(),roadKind}};
        const size_t index = size_t(t->y()-mY)*size_t(mW)+size_t(t->x()-mX);
        if(index < cells && (full || !mTerrainKnown[index] || mTerrainState[index] != value)) {
            if(!first) o << ','; first=false;
            o << '[' << t->x() << ',' << t->y() << ',' << value[0] << ',' << value[1] << ',' << value[2] << ','
              << (board.canBuild(t->x(),t->y(),1,1,false,t->cityId(),pid)?1:0) << ',' << value[3] << ',' << value[4] << ',' << value[5] << ']';
            mTerrainState[index] = value; mTerrainKnown[index] = 1;
        }
        if(!b || b == lastBuilding) return;
        lastBuilding = b;
        const auto type = b->type();
        // A street is terrain; a roadblock on it is drawn as its barrier (the model of `roadblock`).
        const bool roadblock = type == eBuildingType::road && static_cast<eRoad*>(b)->isRoadblock();
        if((type == eBuildingType::road && !roadblock) || type == eBuildingType::avenue) return;
        auto found = mBuildingCache.find(b);
        if(found == mBuildingCache.end()) { found = mBuildingCache.emplace(b,BuildingRecord{}).first; buildingsChanged = true; }
        auto& rec = found->second;
        if(rec.seen == generation) return;
        rec.seen = generation; ++seenBuildings;
        const auto centre = b->centerTile();
        if(!centre) { if(rec.emit) { rec.emit = false; buildingsChanged = true; } return; }
        auto name = roadblock ? std::string("roadblock") : asset(b); auto r = b->tileRect();
        // A piece of a pyramid that covers several tiles is registered at its far corner only (its other tiles are filler parts).
        if(const int size = pyramidPieceSize(type); size > 1) { r.x -= size-1; r.y -= size-1; r.w = size; r.h = size; }
        int orientation = mOrientations.count(b)?mOrientations.at(b):(type==eBuildingType::pier?int(static_cast<ePier*>(b)->orientation()):((type==eBuildingType::palace || type==eBuildingType::gatehouse) && r.w<r.h?1:0));
        // Shore buildings face the water the engine found, as a pier does (the models have the sea on their -x side).
        if(type == eBuildingType::fishery) orientation = int(static_cast<eFishery*>(b)->orientation());
        else if(type == eBuildingType::urchinQuay) orientation = int(static_cast<eUrchinQuay*>(b)->orientation());
        else if(type == eBuildingType::triremeWharf) orientation = int(static_cast<eTriremeWharf*>(b)->orientation());
        // The stadium's model runs along its y axis: a stadium laid along x is turned a quarter.
        else if(type == eBuildingType::stadium) orientation = r.w > r.h ? 1 : 0;
        // A roadblock's bar lies across the street: along y when the street runs along x.
        else if(roadblock) { const auto& board = b->getBoard(); const auto t1 = board.tile(r.x-1,r.y), t2 = board.tile(r.x+1,r.y);
            orientation = ((t1 && t1->hasRoad()) || (t2 && t2->hasRoad())) ? 1 : 0; }
        // The temple, statues and monuments of a sanctuary all look to its front (see sanctuaryQuarterTurns).
        if(type == eBuildingType::temple || type == eBuildingType::templeStatue || type == eBuildingType::templeMonument) {
            const auto monument = static_cast<const eSanctBuilding*>(b)->monument();
            const int turns = sanctuaryQuarterTurns(type, type == eBuildingType::temple ? static_cast<eTempleBuilding*>(b)->pieceId() : 0, monument && monument->rotated());
            if(turns >= 0) orientation = turns;
        }
        // The cult images and the temple of a pyramid look the way those of an unturned sanctuary do.
        if(type == eBuildingType::pyramidStatue || type == eBuildingType::pyramidMonument) orientation = sanctuaryQuarterTurns(eBuildingType::templeStatue, 0, false);
        else if(type == eBuildingType::pyramidTemple) orientation = sanctuaryQuarterTurns(eBuildingType::temple, 0, false);
        const int altitude = centre->doubleAltitude(); const bool active = b->enabled();
        const auto employer = dynamic_cast<const eEmployingBuilding*>(b);
        const int workers = employer ? employer->employed() : 0;
        // Use native overlay eligibility (including production inputs and patrol
        // availability). Storage overlays alone are always enabled, so staffing
        // and shutdown must also gate their authored workers.
        const bool working = active && b->overlayEnabled() && !b->isOnFire() &&
            (!employer || (workers > 0 && !employer->shutDown()));
        const int animationOffset = ((b->textureTime()-board.frame())/4)%8;
        // A piece of a sanctuary (or pyramid) rises as the workers build it: how much of it stands, in percent.
        int grow = 100; bool stretch = false;
        if(const auto piece = dynamic_cast<const eSanctBuilding*>(b)) if(piece->maxProgress() > 0) grow = std::clamp(100*piece->progress()/piece->maxProgress(),0,100);
        // Before the first stage a large piece (the temple, the monument, the altar) is only its foundation: a paved slab over its footprint.
        if(grow == 0 && (type == eBuildingType::temple || type == eBuildingType::templeMonument || type == eBuildingType::templeAltar)) { name = "sanctuary_court_0"; stretch = true; }
        // A piece of a pyramid first raises its ground (four steps for each level it stands above the ground, the tile rising with each) under a
        // paved slab, then is built: a piece of several stages (the temple, the monument) rises as those stages are done.
        if(const auto element = dynamic_cast<const ePyramidElement*>(b); element && name != "native_marker") {
            const int ground = 4*element->elevation(), built = element->progress()-ground, stages = element->maxProgress()-ground;
            if(built <= 0) { name = "sanctuary_court_0"; stretch = pyramidPieceSize(type) > 1; grow = 100; }
            else grow = stages > 0 ? std::clamp(100*built/stages,0,100) : 100;
        }
        if(type == eBuildingType::templeAltar) {
            const auto altar = static_cast<const eTempleAltarBuilding*>(b); const auto monument = altar->monument();
            if(altar->sacrificing() && monument && monument->finished() && grow == 100) rites.push_back({altar,r.x,r.y,r.w,r.h,centre->characterDoubleAltitude()});
        }
        std::string storageBays;
        if(const auto storage = dynamic_cast<const eStorageBuilding*>(b)) {
            std::ostringstream bs;
            bool firstBay = true;
            for(int i = 0; i < storage->spaceCount(); ++i) {
                const int count = storage->resourceCount(i);
                if(count <= 0) continue;
                const char* gname = nullptr;
                switch(storage->resourceType(i)) {
                case eResourceType::urchin: gname = "urchin"; break;
                case eResourceType::fish: gname = "fish"; break;
                case eResourceType::meat: gname = "meat"; break;
                case eResourceType::cheese: gname = "cheese"; break;
                case eResourceType::carrots: gname = "carrots"; break;
                case eResourceType::onions: gname = "onions"; break;
                case eResourceType::wheat: gname = "wheat"; break;
                case eResourceType::oranges: gname = "oranges"; break;
                case eResourceType::wood: gname = "wood"; break;
                case eResourceType::bronze: gname = "bronze"; break;
                case eResourceType::marble: gname = "marble"; break;
                case eResourceType::grapes: gname = "grapes"; break;
                case eResourceType::olives: gname = "olives"; break;
                case eResourceType::fleece: gname = "fleece"; break;
                case eResourceType::sculpture: gname = "sculpture"; break;
                case eResourceType::oliveOil: gname = "oliveOil"; break;
                case eResourceType::wine: gname = "wine"; break;
                case eResourceType::armor: gname = "armor"; break;
                case eResourceType::blackMarble: gname = "blackMarble"; break;
                case eResourceType::orichalc: gname = "orichalc"; break;
                default: break;
                }
                if(gname) {
                    if(!firstBay) bs << ',';
                    firstBay = false;
                    bs << "{\"bay\":" << i << ",\"good\":\"" << gname << "\",\"count\":" << count << "}";
                }
            }
            storageBays = bs.str();
        }
        if(!rec.emit || rec.grow != grow || rec.stretch != stretch || rec.asset != name || rec.type != int(type) || rec.x != r.x || rec.y != r.y || rec.w != r.w ||
           rec.h != r.h || rec.orientation != orientation || rec.altitude != altitude || rec.active != active ||
           rec.working != working || rec.workers != workers || rec.animationOffset != animationOffset ||
           rec.storageBays != storageBays) {
            if(!rec.id) rec.id = mNextId++;
            rec.asset = std::move(name); rec.type = int(type); rec.x = r.x; rec.y = r.y; rec.w = r.w; rec.h = r.h;
            rec.orientation = orientation; rec.altitude = altitude; rec.active = active; rec.emit = true;
            rec.working = working; rec.workers = workers; rec.animationOffset = animationOffset; rec.grow = grow; rec.stretch = stretch;
            rec.storageBays = std::move(storageBays);
            std::ostringstream item;
            item << "{\"id\":" << rec.id << ",\"asset\":" << quote(rec.asset) << ",\"type\":" << rec.type
                 << ",\"x\":" << rec.x << ",\"y\":" << rec.y << ",\"w\":" << rec.w << ",\"h\":" << rec.h
                 << ",\"orientation\":" << rec.orientation << ",\"altitude\":" << rec.altitude
                 << ",\"active\":" << (rec.active?"true":"false")
                 << ",\"working\":" << (rec.working?"true":"false") << ",\"workers\":" << rec.workers
                 << ",\"animation_offset\":" << rec.animationOffset << (rec.grow<100?",\"grow\":"+std::to_string(rec.grow):std::string()) << (rec.stretch?",\"stretch\":true":"");
            if(!rec.storageBays.empty()) item << ",\"bays\":[" << rec.storageBays << "]";
            item << '}';
            rec.json = item.str(); buildingsChanged = true;
        }
        order.push_back(&rec);
    });
    // Buildings that vanished from the map: forget them (and their session facing).
    if(seenBuildings != mBuildingCache.size()) {
        for(auto it = mBuildingCache.begin(); it != mBuildingCache.end();) {
            if(it->second.seen != generation) { mOrientations.erase(it->first); it = mBuildingCache.erase(it); buildingsChanged = true; }
            else ++it;
        }
    }
    const auto afterTiles = clock();
    const auto id = [&](const void* p) { alive.insert(p); auto it=mIds.find(p); if(it==mIds.end()) it=mIds.emplace(p,mNextId++).first; return it->second; };
    if(buildingsChanged) {
        o << "],\"buildings\":["; first=true;
        for(const auto* rec:order) { if(!first) o << ','; first=false; o << rec->json; }
    } else {
        o << "],\"buildings_unchanged\":true,\"buildings\":[";
    }
    const auto afterBuildings = clock();
    o << "],\"walkers\":["; first=true;
    for(auto c:board.characters()) {
        const auto t=c->tile(); if(!t || !c->visible()) continue;
        if(!first) o << ','; first=false;
        const auto name = walkerAsset(c);
        o << "{\"id\":" << id(c) << ",\"type\":" << int(c->type()) << ",\"asset\":" << quote(name)
          << ",\"orientation\":" << int(c->orientation()) << ",\"action\":" << int(c->actionType())
          << ",\"x\":" << c->absX() << ",\"y\":" << c->absY() << ",\"altitude\":" << t->characterDoubleAltitude();
        if(const double lift=perch(c,t)) o << ",\"lift\":" << lift;
        // The player's triremes that may be given orders (at home, the wharf working), as the SDL view lets one select them.
        if(c->type()==eCharacterType::trireme) {
            const auto trireme=static_cast<eTrireme*>(c);
            o << ",\"selectable\":" << (trireme->playerId()==board.personPlayer() && trireme->selectable()?"true":"false");
        }
        o << '}';
    }
    // The hippodrome's racing chariots are missiles running the track (eRacingHorse), not characters: they are sent with the
    // walkers, one of the four teams each (the SDL sprites' colours), found on the tiles of the city's hippodrome plates.
    for(const auto b:board.buildings(board.currentCityId(),eBuildingType::hippodromePiece)) {
        const auto r=b->tileRect();
        for(int ty=r.y;ty<r.y+r.h;++ty) for(int tx=r.x;tx<r.x+r.w;++tx) {
            const auto tile=board.tile(tx,ty); if(!tile) continue;
            for(const auto& missile:tile->missiles()) {
                if(!missile || missile->type()!=eMissileType::racingHorse) continue;
                const auto horse=static_cast<eRacingHorse*>(missile.get());
                // The same tile space as a walker's absolute position (the SDL view draws both alike).
                const double mx=horse->globalX(), my=horse->globalY();
                if(!first) o << ','; first=false;
                o << "{\"id\":" << id(horse) << ",\"type\":-1,\"asset\":\"walker_racechariot" << horse->team() << "\",\"orientation\":0,\"action\":1"
                  << ",\"x\":" << mx << ",\"y\":" << my << ",\"altitude\":" << tile->characterDoubleAltitude() << ",\"racing\":true}";
            }
        }
    }
    // A rite on an altar (the SDL view draws it as an overlay on the altar's sprite): a priestess in the walkers' list, stabbing the animal that lies on
    // the altar (action 4, "fight") or, for an offering of goods, raising her arms over them (action 5, "fight2"). The scene is presentation only: the
    // records stand at the altar's centre with a `scene`, a `role` and the altar's size, and the presentation places each part around it. Ids come from
    // the altar's address (and the byte after it), so a rite keeps its ids for as long as it lasts.
    for(const auto& rite:rites) {
        const auto kind = rite.altar->sacrifice();
        const double cx = rite.x+rite.w*.5, cy = rite.y+rite.h*.5;
        const auto part = [&](const void* key,const char* asset,const char* role,int orientation,int action) {
            if(!first) o << ','; first=false;
            o << "{\"id\":" << id(key) << ",\"type\":-1,\"asset\":" << quote(asset) << ",\"orientation\":" << orientation << ",\"action\":" << action
              << ",\"x\":" << cx << ",\"y\":" << cy << ",\"altitude\":" << rite.altitude << ",\"scene\":\"altar\",\"role\":\"" << role << "\",\"rite\":\""
              << (kind==eSacrifice::sheep?"sheep":(kind==eSacrifice::bull?"bull":"goods")) << "\",\"size\":[" << rite.w << ',' << rite.h << "]}";
        };
        const void* const second = reinterpret_cast<const char*>(rite.altar)+1;
        // The priestess stands on the altar's +y steps facing -y (orientation 0: the walkers' orientation 0 looks toward tile -y); the victim lies along the
        // altar's x axis, its head toward +x (orientation 2).
        part(rite.altar,"walker_priestess","priestess",0,kind==eSacrifice::goods?5:4);
        if(kind==eSacrifice::sheep) part(second,"animal_sheep_fleeced","victim",2,1);
        else if(kind==eSacrifice::bull) part(second,"animal_ox","victim",2,1);
        else part(second,"sacrifice_goods","offering",0,1);
    }
    for(auto it=mIds.begin();it!=mIds.end();) { if(!alive.count(it->first)) { mOrientations.erase(it->first); it=mIds.erase(it); } else ++it; }
    const auto afterWalkers = clock();
    // The banners are sent whole whenever they change (and in every full snapshot); a snapshot without them leaves the list as it was.
    { const auto banners=bannersJson(); o << "],"; if(full || banners!=mSentBanners) { mSentBanners=banners; o << "\"banners\":" << banners << ','; }
      // While an enemy force is in the city every snapshot says so, with how many invaders stand; peace says nothing.
      if(board.hasActiveInvasions(board.currentCityId())) { int ix=0,iy=0; const int n=invaderCount(&ix,&iy); o << "\"invasion\":true,\"invaders\":" << n << ",\"invader_at\":[" << ix << ',' << iy << "],"; }
      // A monster loose in the city is announced the same way: how many, what the first is, and where it stands.
      { int mx=0,my=0; std::string mname; const int m=monsterCount(&mx,&my,&mname); if(m>0) o << "\"monsters\":" << m << ",\"monster\":" << quote(mname) << ",\"monster_at\":[" << mx << ',' << my << "],"; }
      o << "\"sounds\":["; }
    first=true;
    for(const auto& path:takeSounds()) { if(!first) o << ','; first=false; o << quote(path); }
    { std::lock_guard<std::mutex> lock(mSoundLock); o << "],\"music\":" << quote(mMusicMode); }
    o << ",\"events\":["; first=true;
    for(const auto& item:mEvents) {
        const auto& e=item.second; if(!first) o << ','; first=false;
        // Sender identity is read-only, never inferred from translated message text.
        const auto sender = e.data.fCity;
        o << "{\"sender_index\":" << (sender ? worldIndex(sender) : -1)
          << ",\"sender_name\":" << quote(sender ? sender->name() : "")
          << ",\"sender_leader\":" << quote(sender ? sender->leader() : "")
          << ",\"id\":" << item.first << ",\"kind\":" << quote(e.kind) << ",\"title\":" << quote(e.title) << ",\"text\":" << quote(e.text) << (e.brief.empty()?std::string():",\"brief\":"+quote(e.brief)) << ",\"actions\":[";
        bool separator=false; const auto action=[&](int choice,const std::string& label) { if(separator) o << ','; separator=true; o << "{\"choice\":" << choice << ",\"label\":" << quote(label) << '}'; };
        const bool invasion = e.data.fType == eMessageEventType::invasion;
        if(e.data.fA0) action(0,eLanguage::zeusText(44,invasion?282:(e.data.fType==eMessageEventType::requestTributeGranted?209:275)));
        if(e.data.fA1) action(1,eLanguage::zeusText(44,invasion?281:211));
        if(e.data.fA2) action(2,eLanguage::zeusText(44,invasion?283:212));
        for(const auto& city:e.data.fCCA0) {
            const auto space=e.data.fCSpaceCount.find(city.first);
            if(space != e.data.fCSpaceCount.end() && space->second < e.data.fResourceCount) continue;
            const auto name=e.data.fCityNames.find(city.first);
            action(1000+int(city.first),eLanguage::zeusText(44,209)+" — "+(name!=e.data.fCityNames.end()?name->second:"City"));
        }
        // Forces/tribute UI uses richer contracts; do not silently consume those callbacks.
        if(e.data.fCA0) action(-2,eLanguage::zeusText(44,275));
        if(!separator) action(-1,"Dismiss"); o << "]}";
    }
    o << "]}"; auto text = o.str();
    const auto finished = clock();
    mProfile.tiles = micros(began,afterTiles); mProfile.buildings = micros(afterTiles,afterBuildings);
    mProfile.walkers = micros(afterBuildings,afterWalkers); mProfile.events = micros(afterWalkers,finished);
    mProfile.total = micros(began,finished); mProfile.maxTotal = std::max(mProfile.maxTotal,mProfile.total); ++mProfile.snapshots;
    return text;
}
bool eSimulationService::undoAvailable() const {
    if(!mBoard || mBlocked || mUndoBuildings.empty()) return false;
    if(mBoard->totalTime()-mUndoGameTime > 15*eNumbers::sDayLength &&
       std::chrono::steady_clock::now()-mUndoRealTime > std::chrono::seconds(5)) return false;
    for(const auto& b:mUndoBuildings) if(b && !b->deleteScheduled() && !b->isOnFire()) return true;
    return false;
}
// The SDL side panel's data pages for the city in view, worded by the core in its language with the verdicts of
// engine/ecitydata (shared with the SDL pages): each page's lines (a label, a value and how serious it is: 0 good, 1 needs an
// eye, 2 trouble, -1 plain) and its "See ..." overlays, and the settings the pages change: the tax and wage rates, the
// workforce priorities of the eight sectors (with the industries short of workers), the year's finances, the soldiers and
// towers. Reading never changes the city (no resource refresh, no allocation).
std::string eSimulationService::cityData() {
    mBoard->waitUntilFinished();
    const auto cid=mBoard->currentCityId();
    const auto text=[](int group,int string) { return eLanguage::zeusText(group,string); };
    const auto dr=text(8,1);
    std::ostringstream o; bool firstPage=true;
    o << "{\"kind\":\"city_data\",\"pages\":[";
    struct Line { std::string label, value; int severity=-1; };
    const auto page=[&](const std::string& id,const std::vector<std::pair<int,std::string>>& views,const std::vector<Line>& lines,const std::string& extra=std::string()) {
        if(!firstPage) o << ','; firstPage=false;
        o << "{\"id\":" << quote(id) << ",\"views\":[";
        bool first=true;
        for(const auto& view:views) { if(!first) o << ','; first=false; o << "{\"label\":" << quote(text(14,view.first)) << ",\"overlay\":" << quote(view.second) << '}'; }
        o << "],\"lines\":[";
        first=true;
        for(const auto& line:lines) {
            if(!first) o << ','; first=false;
            o << "{\"label\":" << quote(line.label) << ",\"value\":" << quote(line.value) << ",\"severity\":" << line.severity << '}';
        }
        o << ']' << extra << '}';
    };
    const auto verdict=[&](const std::string& label,const eCityVerdict& v) { return Line{label,v.text(),v.fSeverity}; };
    const int population=mBoard->population(cid);
    const auto husbandry=mBoard->husbandryData(cid);
    const auto employment=mBoard->employmentData(cid);
    const auto people=mBoard->populationData(cid);
    // Overview.
    {
        std::vector<Line> lines;
        lines.push_back(verdict(text(61,1),eCityData::popularity(mBoard->popularity(cid))));
        if(husbandry) lines.push_back(verdict(text(61,4),eCityData::foodLevel(husbandry->canSupport(),population)));
        if(employment) {
            const auto line=eCityData::employment(employment->freeJobVacancies(),employment->employable(),employment->unemployed());
            lines.push_back({text(61,line.fTitle),line.fValue,line.fSeverity});
        }
        lines.push_back(verdict(text(61,6),eCityData::hygiene(mBoard->health(cid))));
        lines.push_back(verdict(text(61,7),eCityData::unrest(mBoard->unrest(cid))));
        lines.push_back(verdict(text(61,8),eCityData::finances(mBoard->finances(cid).thisYear().netInOutFlow())));
        page("overview",{{18,"problems"},{19,"roads"}},lines);
    }
    // Population.
    if(people) {
        std::vector<Line> lines;
        lines.push_back({text(55,8)+" "+std::to_string(people->vacancies())+" "+text(55,9),""});
        const int direction=eCityData::peopleDirectionText(people->arrived(),people->left());
        if(direction) lines.push_back({text(55,direction),""});
        if(people->arrived()>0) lines.push_back({text(55,10),std::to_string(people->arrived())});
        else lines.push_back({text(55,12),text(55,eCityData::immigrationLimitText(people->vacancies(),mBoard->immigrationLimit(cid))),2});
        page("population",{{1,"supplies"}},lines);
    }
    // Employment: the wage rate, payroll, employed and unemployed or needed.
    const auto wage=mBoard->wageRate(cid);
    if(employment) {
        std::vector<Line> lines;
        lines.push_back({text(131,1),eWageRateHelpers::name(wage)});
        lines.push_back({text(50,16),std::to_string(employment->pensions())+" "+text(6,0)});
        lines.push_back({text(50,12),std::to_string(employment->employed())});
        if(employment->freeJobVacancies()>0) lines.push_back({text(61,13),std::to_string(employment->freeJobVacancies()),1});
        else {
            const int w=employment->employable(), u=employment->unemployed();
            const int per=w==0?0:std::clamp(int(std::round(100.*u/w)),0,100);
            lines.push_back({text(50,13),std::to_string(u)+(u>0?" ("+std::to_string(per)+"%)":""),u>0?(per>10?2:1):0});
        }
        page("employment",{{3,"industry"}},lines);
    }
    // Administration: the tax rate, what it yielded and how many the clerks reached.
    const auto tax=mBoard->taxRate(cid);
    {
        const int paid=mBoard->peoplePaidTaxesLastYear(cid);
        const int per=population==0?0:std::clamp(int(std::round(100.*paid/population)),0,100);
        page("administration",{{9,"taxes"}},{{text(131,0),eTaxRateHelpers::name(tax)},
             {text(60,4)+" "+std::to_string(mBoard->taxesPaidLastYear(cid))+" "+dr,""},{std::to_string(per)+"% "+text(60,5),""}});
    }
    // Husbandry.
    if(husbandry) {
        page("husbandry",{{2,"husbandry"}},{{text(57,1)+" "+std::to_string(husbandry->canSupport())+" "+text(57,2),""},
             verdict("",eCityData::foodOpinion(husbandry->canSupport(),population)),
             {text(57,27)+" "+std::to_string(husbandry->storedFood())+" "+text(57,28),""}});
    }
    // Storage: the basic goods in store (the cached counts).
    {
        std::ostringstream goods; goods << ",\"goods\":["; bool first=true;
        if(const auto stored=mBoard->resources(cid)) for(const auto& item:*stored) {
            if(!first) goods << ','; first=false;
            goods << "{\"resource\":" << int(item.first) << ",\"name\":" << quote(eResourceTypeHelpers::typeName(item.first)) << ",\"count\":" << item.second << '}';
        }
        goods << ']';
        page("storage",{{4,"distribution"}},{},goods.str());
    }
    // Hygiene and safety.
    page("hygiene",{{5,"water"},{6,"hygiene"},{7,"hazards"},{8,"unrest"}},
         {verdict(text(56,1),eCityData::hygieneLevel(mBoard->health(cid))),verdict(text(56,17),eCityData::unrestLevel(mBoard->unrest(cid)))});
    // Appeal: the commemorative monuments and gods' monuments, counted.
    {
        std::vector<Line> lines; std::map<int,int> commemoratives; std::map<int,int> gods;
        for(const auto b:mBoard->commemorativeBuildings(cid)) {
            if(b->type()==eBuildingType::commemorative) ++commemoratives[static_cast<eCommemorative*>(b)->id()];
            else if(b->type()==eBuildingType::godMonument) ++gods[int(static_cast<eGodMonument*>(b)->god())];
        }
        const auto named=[&](const std::string& name,int count) {
            auto title=text(133,count>1?4:3);
            eStringHelpers::replace(title,"[amount]",std::to_string(count));
            eStringHelpers::replace(title,"[commemorative_monument]",name);
            lines.push_back({title,""});
        };
        for(int id=0;id<9;++id) if(commemoratives.count(id)) named(text(133,eCityData::commemorativeText(id)),commemoratives[id]);
        for(const auto& god:gods) named(eGod::sGodName(static_cast<eGodType>(god.first)),god.second);
        if(lines.empty()) lines.push_back({text(133,2),""});
        lines.insert(lines.begin(),Line{text(133,1),"",-2});
        page("appeal",{{17,"appeal"}},lines);
    }
    // Culture: the four disciplines with the games they prepare for; science: the same coverage as the SDL science page.
    {
        const int philosophy=mBoard->philosophyResearchCoverage(cid), athletics=mBoard->athleticsLearningCoverage(cid);
        const int drama=mBoard->dramaAstronomyCoverage(cid), all=mBoard->allCultureScienceCoverage(cid);
        const auto coverage=[&](int games,int discipline,int value) {
            const int string=eCityData::coverageText(value);
            return Line{text(58,games)+" — "+text(58,discipline),text(58,string),string<=11?0:string==12?1:2};
        };
        page("culture",{{12,"philosophers"},{13,"athletes"},{14,"actors"},{11,"competitors"},{10,"all_culture"}},
             {{text(58,1),"",-2},coverage(2,3,philosophy),coverage(4,5,athletics),coverage(6,7,drama),coverage(8,9,all)});
        const auto science=[&](int label,int value) {
            const int string=eCityData::coverageText(value);
            return Line{text(58,label),text(58,string),string<=11?0:string==12?1:2};
        };
        const auto museum=mBoard->museum(cid);
        page("science",{{20,"astronomers"},{23,"scholars"},{22,"inventors"},{21,"curators"},{24,"all_science"}},
             {{text(58,75),"",-2},science(76,drama),science(77,philosophy),science(78,athletics),{text(58,79),text(18,museum&&museum->available()?1:0)}});
    }
    // Military: companies abroad, in the city and standing down; the soldiers' and towers' buttons.
    {
        int abroad=0, inCity=0, standingDown=0;
        for(const auto& banner:mBoard->banners(cid)) {
            if(banner->isAbroad()) ++abroad; else if(banner->isHome()) ++standingDown; else ++inCity;
        }
        const auto soldiers=eCityData::soldiers(inCity,standingDown);
        const int towers=int(mBoard->buildings(cid,eBuildingType::tower).size());
        const bool manning=mBoard->manTowers(cid);
        std::ostringstream extra;
        extra << ",\"soldiers\":{\"text\":" << quote(text(51,eCityData::soldiersText(soldiers))) << ",\"tooltip\":" << quote(text(68,eCityData::soldiersTooltip(soldiers)))
              << ",\"action\":" << quote(soldiers==eCityData::eSoldiers::none?"":soldiers==eCityData::eSoldiers::allCalled?"army_home":"army_call")
              << "},\"towers\":{\"text\":" << quote(text(51,eCityData::towersText(towers,manning))) << ",\"tooltip\":" << quote(text(68,eCityData::towersTooltip(towers,manning)))
              << ",\"count\":" << towers << ",\"manning\":" << (manning?"true":"false") << '}';
        page("military",{{16,"security"}},{{text(51,1),std::to_string(abroad)},{text(51,0),std::to_string(inCity)},{text(51,2),std::to_string(standingDown)}},extra.str());
    }
    // The tax rates in the order of their percentage (the enum's veryLow is 7%, low 3%), each with its id for set_tax.
    o << "],\"tax\":{\"rate\":" << int(tax) << ",\"label\":" << quote(text(131,0)) << ",\"options\":[";
    {
        bool first=true;
        for(const auto rate:eCityData::taxRatesInOrder()) {
            if(!first) o << ','; first=false;
            o << "{\"id\":" << int(rate) << ",\"name\":" << quote(eTaxRateHelpers::name(rate)) << ",\"percent\":" << int(std::round(100*eTaxRateHelpers::getRate(rate))) << '}';
        }
    }
    o << "]},\"wage\":{\"rate\":" << int(wage) << ",\"label\":" << quote(text(131,1)) << ",\"names\":[";
    for(int i=0;i<=int(eWageRate::veryHigh);++i) o << (i?",":"") << quote(eWageRateHelpers::name(static_cast<eWageRate>(i)));
    // Workforce allocation: each sector's priority, the workers it needs and has; the industries short of workers.
    o << "]},\"workforce\":{\"title\":" << quote(text(50,0)) << ",\"columns\":[" << quote(text(50,18)) << ',' << quote(text(50,19)) << ',' << quote(text(50,10)) << ',' << quote(text(50,11))
      << "],\"priorities\":[";
    for(int i=0;i<=int(ePriority::veryHigh);++i) o << (i?",":"") << quote(ePriorityHelpers::sName(static_cast<ePriority>(i)));
    o << "],\"sectors\":[";
    if(const auto distributor=mBoard->employmentDistributor(cid)) {
        const bool atlantean=mBoard->atlantean(cid);
        for(int i=int(eSector::husbandry);i<=int(eSector::military);++i) {
            const auto sector=static_cast<eSector>(i);
            o << (i?",":"") << "{\"sector\":" << i << ",\"name\":" << quote(eSectorHelpers::sName(sector,atlantean)) << ",\"priority\":" << int(distributor->priority(sector))
              << ",\"need\":" << distributor->maxEmployees(sector) << ",\"have\":" << distributor->employees(sector) << '}';
        }
    }
    o << "],\"industry_title\":" << quote(text(50,22)) << ",\"industries\":[";
    {
        bool first=true;
        for(const auto resource:eResourceTypeHelpers::extractResourceTypes(eResourceType::allTransportable)) {
            const int vacancies=mBoard->industryJobVacancies(cid,resource);
            if(vacancies==0) continue;
            if(!first) o << ','; first=false;
            o << "{\"resource\":" << int(resource) << ",\"name\":" << quote(eResourceTypeHelpers::typeName(resource)) << ",\"vacancies\":" << vacancies << '}';
        }
    }
    // The city's finances: last year and so far this year, the rows of the SDL finances window.
    const auto finances=mBoard->finances(cid);
    const auto& last=finances.lastYear(); const auto& now=finances.thisYear();
    o << "]},\"finances\":{\"title\":" << quote(text(60,0)) << ",\"last\":" << quote(text(60,6)) << ",\"this\":" << quote(text(60,7)) << ",\"rows\":[";
    {
        bool first=true;
        const auto row=[&](const char* kind,int label,int a,int b) {
            if(!first) o << ','; first=false;
            o << "{\"kind\":\"" << kind << "\",\"label\":" << quote(text(60,label)) << ",\"last\":" << a << ",\"this\":" << b << '}';
        };
        row("heading",10,0,0);
        row("row",8,last.fTaxesIn,now.fTaxesIn); row("row",9,last.fExports,now.fExports); row("row",20,last.fGiftsReceived,now.fGiftsReceived);
        row("row",24,last.fMinedSilver,now.fMinedSilver); row("row",16,last.fTributeReceived,now.fTributeReceived); row("row",27,last.fHippodrome,now.fHippodrome);
        row("total",25,last.totalIncome(),now.totalIncome());
        row("heading",17,0,0);
        row("row",11,last.fImportCosts,now.fImportCosts); row("row",12,last.fWages,now.fWages); row("row",13,last.fConstruction,now.fConstruction);
        row("row",21,last.fBribesTributePaid,now.fBribesTributePaid); row("row",22,last.fGiftsAndAidGiven,now.fGiftsAndAidGiven);
        row("total",26,last.totalExpenses(),now.totalExpenses());
        row("net",18,last.netInOutFlow(),now.netInOutFlow());
    }
    o << "]},\"mythology_view\":" << quote(text(14,15)) << '}';
    return o.str();
}
// One sheep, goat or head of cattle on a tile, as the SDL view places them (eGameBoard::buildAnimal, 1x2 of fertile ground).
static bool placeAnimal(eGameBoard& board,const eBuildingType type,eTile* const tile,const eCityId cid,const ePlayerId pid) {
    return board.buildAnimal(tile,type,[type](eGameBoard& b) -> stdsptr<eCharacter> {
        if(type==eBuildingType::sheep) return e::make_shared<eSheep>(b);
        if(type==eBuildingType::goat) return e::make_shared<eGoat>(b);
        return e::make_shared<eCattle>(b,eCharacterType::cattle2);
    },cid,pid,false);
}
// The name the SDL build menu gives a building: the native building name, except for those that share one native type
// (the commemoratives and the gods' monuments, named by the menu's own strings) and the roadblock, which has none.
static std::string menuLabel(const BuildSpec& spec) {
    if(spec.kind==Kind::commemorative) return eLanguage::zeusText(198,spec.variant+1);
    if(spec.kind==Kind::godMonument) {
        static const int texts[]={16,13,15,14,18,35,12,20,21,19,34,17,11,10};
        return eLanguage::zeusText(198,texts[std::clamp(spec.variant,0,13)]);
    }
    if(spec.kind==Kind::roadblock) return eLanguage::zeusText(67,27);
    return eBuilding::sNameForBuilding(spec.type);
}
// Everything the build menu needs: for each buildable name its display name, footprint, model, cost and whether
// this city may build it now.
std::string eSimulationService::buildable() {
    const auto pid=mBoard->personPlayer();
    const auto focus=mBoard->tile(mFocusX,mFocusY);
    const auto city=focus?focus->cityId():eCityId::neutralFriendly;
    std::ostringstream out; out << "{\"kind\":\"buildable\",\"buildings\":[";
    bool first=true;
    for(const auto& item:buildSpecs) {
        const auto& spec=item.second;
        if(!first) out << ','; first=false;
        int w=spec.w, h=spec.h, marble=0;
        if(spec.kind==Kind::sanctuary) {
            // A sanctuary's footprint is its layout's (the turned one swaps the sides); its marble is paid when it is founded.
            if(const auto* layout=eSanctBlueprints::sSanctuaryBlueprint(spec.type,false)) { w=layout->fW; h=layout->fH; }
            marble=eBuilding::sInitialMarbleCost(spec.type);
        }
        out << "{\"name\":" << quote(item.first) << ",\"label\":" << quote(menuLabel(spec)) << ",\"w\":" << w << ",\"h\":" << h
            << ",\"asset\":" << quote(spec.asset[0]?spec.asset:"unconverted") << ",\"cost\":" << eDifficultyHelpers::buildingCost(mBoard->difficulty(pid),costType(spec))
            << ",\"marble\":" << marble << ",\"available\":" << (mBoard->supportsBuilding(city,item.second.mode)?"true":"false") << '}';
    }
    out << "],\"sanctuaries\":{\"built\":" << int(mBoard->sanctuaries(city).size()) << ",\"max\":" << mBoard->maxSanctuaries(city)
        << ",\"marble\":" << mBoard->resourceCount(city,eResourceType::marble) << "}}"; return out.str();
}
// One overlay, as the SDL view draws it: which buildings and walker kinds stay visible (the others are shown flat or
// hidden), the value columns above houses and buildings (height in segments and a tone from 1 green to 4 red, 5 water),
// the supplies each house has, and for the appeal view a grid of ratings per tile. Read-only; the filters are the
// native eViewModeHelpers, the values are the ones eGameWidget::drawBuildingModes reads.
std::string eSimulationService::overlay(const std::string& name) {
    const OverlayMode* found=nullptr;
    for(const auto& item:overlayModes) if(name==item.name) { found=&item; break; }
    if(!found) return "{\"error\":\"unknown_overlay\"}";
    if(!mBoard) return "{\"error\":\"city_not_loaded\"}";
    mBoard->waitUntilFinished();
    const auto mode=found->mode;
    const auto pid=mBoard->personPlayer(); const auto diff=mBoard->difficulty(pid);
    std::ostringstream visible, columns, supplies;
    bool firstVisible=true, firstColumn=true, firstSupply=true;
    const auto column=[&](uint64_t id,int n,int tone) { if(!firstColumn) columns << ','; firstColumn=false; columns << '[' << id << ',' << n << ',' << tone << ']'; };
    const auto tone4=[](int n) { return n<2?1:(n<3?2:(n<4?3:4)); };
    std::set<const eBuilding*> seen;
    const bool appeal=mode==eViewMode::appeal;
    const auto& heat=mBoard->appealMap();
    std::string cells; if(appeal) cells.assign(size_t(mW)*size_t(mH),'.');
    mBoard->iterateOverAllTiles([&](eTile* t) {
        eBuilding* const b=t->underBuilding();
        const auto bt=b?b->type():eBuildingType::none;
        bool shown=false;
        if(b && bt!=eBuildingType::road && bt!=eBuildingType::avenue && seen.insert(b).second) {
            const auto record=mBuildingCache.find(b);
            if(record!=mBuildingCache.end() && record->second.emit) {
                const uint64_t id=record->second.id;
                shown=eViewModeHelpers::buildingVisible(mode,b);
                if(shown) { if(!firstVisible) visible << ','; firstVisible=false; visible << id; }
                const auto house=dynamic_cast<eHouseBase*>(b);
                const bool lived=house && house->people()>0;
                switch(mode) {
                case eViewMode::hazards: {
                    const int fr=eDifficultyHelpers::fireRisk(diff,bt), dr=eDifficultyHelpers::damageRisk(diff,bt);
                    if(house && !lived) break;
                    const int h=100-b->maintenance();
                    if((fr||dr) && h>5) column(id,h/15,tone4(h/15));
                } break;
                case eViewMode::taxes: if(lived) column(id,house->paidTaxes()?4:0,1); break;
                case eViewMode::water: if(lived && bt==eBuildingType::commonHouse) column(id,static_cast<eSmallHouse*>(b)->water()/2,5); break;
                case eViewMode::hygiene: if(lived && bt==eBuildingType::commonHouse) {
                    const int n=static_cast<eSmallHouse*>(b)->hygiene()/15;
                    column(id,n,n<2?4:(n<3?3:(n<4?2:1)));
                } break;
                case eViewMode::unrest: if(lived && bt==eBuildingType::commonHouse) {
                    const int n=(100-static_cast<eSmallHouse*>(b)->satisfaction())/15;
                    column(id,n,tone4(n));
                } break;
                case eViewMode::actors: case eViewMode::astronomers: if(lived) column(id,house->actorsAstronomers()/2,1); break;
                case eViewMode::philosophers: case eViewMode::inventors: if(lived) column(id,house->philosophersInventors()/2,1); break;
                case eViewMode::athletes: case eViewMode::scholars: if(lived) column(id,house->athletesScholars()/2,1); break;
                case eViewMode::competitors: case eViewMode::curators: if(lived) column(id,house->competitorsCurators()/2,1); break;
                case eViewMode::allCulture: case eViewMode::allScience: if(lived) column(id,house->allCultureScience(),1); break;
                case eViewMode::supplies: {
                    if(!lived) break;
                    int has=0, count=0;
                    const auto add=[&](bool low) { has|=(low?0:1)<<count; ++count; };
                    if(bt==eBuildingType::commonHouse) {
                        const auto h=static_cast<eSmallHouse*>(b); add(h->lowFood()); add(h->lowFleece()); add(h->lowOil());
                    } else if(bt==eBuildingType::eliteHousing) {
                        const auto h=static_cast<eEliteHousing*>(b); add(h->lowFood()); add(h->lowFleece()); add(h->lowOil());
                        add(h->lowWine()); add(h->lowArms()); add(h->lowHorses());
                    } else break;
                    if(!firstSupply) supplies << ','; firstSupply=false;
                    supplies << '[' << id << ',' << has << ',' << count << ']';
                } break;
                default: break;
                }
            }
        }
        if(appeal) {
            const auto terrain=t->terrain();
            const bool skip=terrain==eTerrain::stones || terrain==eTerrain::flatStones || terrain==eTerrain::tallStones ||
                terrain==eTerrain::copper || terrain==eTerrain::silver || terrain==eTerrain::orichalc || terrain==eTerrain::water;
            if(!skip && !t->isElevationTile()) {
                if(b && !shown) shown=eViewModeHelpers::buildingVisible(mode,b);
                const bool house=bt==eBuildingType::commonHouse || bt==eBuildingType::eliteHousing;
                if(!shown && (heat.enabled(t->dx(),t->dy()) || house || b)) {
                    const double app=heat.heat(t->dx(),t->dy());
                    const double signedPower=(app>0?1:-1)*std::pow(std::abs(app),0.75);
                    const int rating=std::clamp(int(std::round(signedPower+2.)),0,9);
                    const size_t index=size_t(t->y()-mY)*size_t(mW)+size_t(t->x()-mX);
                    if(index<cells.size()) cells[index]=char((house?'a':'0')+rating);
                }
            }
        }
    });
    std::ostringstream types; bool firstType=true;
    for(int c=0;c<256;++c) if(eViewModeHelpers::characterVisible(mode,static_cast<eCharacterType>(c))) {
        if(!firstType) types << ','; firstType=false; types << c;
    }
    std::ostringstream out;
    out << "{\"kind\":\"overlay\",\"mode\":" << quote(name) << ",\"visible\":[" << visible.str() << "],\"walker_types\":["
        << types.str() << "],\"columns\":[" << columns.str() << "],\"supplies\":[" << supplies.str() << ']';
    if(appeal) out << ",\"appeal\":{\"origin\":[" << mX << ',' << mY << "],\"extent\":[" << mW << ',' << mH << "],\"grid\":" << quote(cells) << '}';
    out << '}';
    return out.str();
}
// A sound path relative to the game folder, with every language's voice folder reported as Audio/Voice.
std::string eSimulationService::relativeSound(const std::string& path) {
    const std::string root=eGameDir::path("");
    std::string relative=path.rfind(root,0)==0?path.substr(root.size()):path;
    for(const char* lang:{"Audio/Voice_en/","Audio/Voice_ru/"}) {
        const std::string prefix=lang;
        if(relative.rfind(prefix,0)==0) relative="Audio/Voice/"+relative.substr(prefix.size());
    }
    return relative;
}
// The next episode as the briefing shows it, before it starts: titles, story and the goals' wording (no status yet).
std::string eSimulationService::previewEpisode() {
    if(!mCampaign) return "{\"error\":\"city_not_loaded\"}";
    const auto e=mCampaign->currentEpisode();
    if(!e || !e->fBoard) return "{\"error\":\"city_not_loaded\"}";
    const bool colony=mCampaign->currentEpisodeType()==eEpisodeType::colony;
    const auto capital=e->fBoard->boardCityWithId(e->fBoard->currentCityId());
    const bool atlantean=capital?capital->atlantean():false;
    auto introduction=e->fIntroduction; eStringHelpers::replaceSpecial(introduction);
    std::string voice;
    { const auto path=mCampaign->currentEpisodeAudioFilePath(true); std::error_code ec; if(!path.empty() && std::filesystem::exists(path,ec)) voice=relativeSound(path); }
    std::ostringstream out;
    out << "{\"kind\":\"episode_preview\",\"title\":" << quote(mCampaign->titleText()) << ",\"episode_title\":" << quote(e->fTitle)
        << ",\"introduction\":" << quote(introduction) << ",\"voice\":" << quote(voice) << ",\"colony\":" << (colony?"true":"false")
        << ",\"episode_number\":" << (mCampaign->currentEpisodeId()+1) << ",\"episode_count\":" << (colony?int(mCampaign->colonyEpisodes().size()):int(mCampaign->parentCityEpisodes().size()))
        << ",\"difficulty\":" << int(mCampaign->difficulty()) << ",\"goals\":[";
    bool first=true;
    for(const auto& g:e->fGoals) {
        if(!g) continue;
        if(!first) out << ','; first=false;
        out << "{\"text\":" << quote(g->text(colony,atlantean,*e->fBoard)) << ",\"status\":\"\",\"met\":false,\"progress\":0,\"set_aside\":false}";
    }
    out << "]}";
    return out.str();
}
// What follows a won episode: the end of the adventure, the next episode, or a choice of colony. The campaign has
// already booked the result (money, date, goods set aside); nothing starts until begin_episode.
std::string eSimulationService::nextStep() {
    std::ostringstream out;
    if(mCampaign->finished()) {
        auto complete=mCampaign->completeText(); eStringHelpers::replaceSpecial(complete);
        std::string voice;
        { const auto path=mCampaign->adventureVictoryAudioFilePath(); std::error_code ec; if(!path.empty() && std::filesystem::exists(path,ec)) voice=relativeSound(path); }
        out << "{\"kind\":\"campaign_step\",\"next\":\"complete\",\"title\":" << quote(mCampaign->titleText()) << ",\"complete\":" << quote(complete) << ",\"voice\":" << quote(voice) << '}';
        return out.str();
    }
    if(mCampaign->currentEpisodeType()==eEpisodeType::parentCity) {
        out << "{\"kind\":\"campaign_step\",\"next\":\"episode\",\"preview\":" << previewEpisode() << '}';
        return out.str();
    }
    out << "{\"kind\":\"campaign_step\",\"next\":\"colonies\",\"colonies\":[";
    bool first=true;
    const auto& all=mCampaign->colonyEpisodes();
    for(const auto* colony:mCampaign->remainingColonies()) {
        int index=0; for(const auto& episode:all) { if(episode.get()==colony) break; ++index; }
        if(!first) out << ','; first=false;
        out << "{\"index\":" << index << ",\"name\":" << quote(colony->fCity?colony->fCity->name():std::string("")) << '}';
    }
    out << "]}";
    return out.str();
}
std::string eSimulationService::finishEpisode() {
    if(!mCampaign || !mBoard) return "{\"error\":\"city_not_loaded\"}";
    if(!mVictory || mAwaiting) return "{\"error\":\"episode_not_won\"}";
    mBoard->waitUntilFinished();
    mCampaign->episodeFinished();
    mAwaiting=true; mColonyChosen=false;
    return nextStep();
}
std::string eSimulationService::chooseColony(const int index) {
    if(!mCampaign || !mAwaiting || mCampaign->finished() || mCampaign->currentEpisodeType()!=eEpisodeType::colony) return "{\"error\":\"no_colony_choice\"}";
    bool allowed=false;
    const auto& all=mCampaign->colonyEpisodes();
    for(const auto* colony:mCampaign->remainingColonies()) if(index>=0 && index<int(all.size()) && all[index].get()==colony) allowed=true;
    if(!allowed) return "{\"error\":\"invalid_colony\"}";
    mCampaign->setCurrentColonyEpisode(index);
    mColonyChosen=true;
    return previewEpisode();
}
// Starts the episode the campaign has moved to (its board may be another city) and opens it paused.
std::string eSimulationService::beginEpisode() {
    if(!mCampaign || !mAwaiting || mCampaign->finished()) return "{\"error\":\"no_episode_waiting\"}";
    if(mCampaign->currentEpisodeType()==eEpisodeType::colony && !mColonyChosen) return "{\"error\":\"no_colony_choice\"}";
    const auto settled=mCampaign;
    detach();
    mCampaign=settled;
    mCampaign->startEpisode();
    const auto phase=[](int) {};
    const auto first=enter(phase);
    if(first.find("\"error\"")!=std::string::npos) return first;
    if(!mSaveDir.empty()) save("autosave replay");
    return "{\"kind\":\"episode_started\",\"colony\":" + std::string(mCampaign->currentEpisodeType()==eEpisodeType::colony?"true":"false") + "}";
}
std::string eSimulationService::setAside(const int index) {
    if(!mBoard) return "{\"error\":\"city_not_loaded\"}";
    mBoard->waitUntilFinished();
    const auto& goals=mBoard->goals();
    if(index<0 || index>=int(goals.size()) || !goals[index]) return "{\"error\":\"invalid_goal\"}";
    const auto& g=goals[index];
    if(g->fType!=eEpisodeGoalType::setAsideGoods || g->met()) return "{\"error\":\"nothing_to_set_aside\"}";
    for(const auto cid:mBoard->personPlayerCitiesOnBoard()) mBoard->updateResources(cid);
    g->update(*mBoard);
    if(g->fPreviewCount<g->fRequiredCount) return "{\"error\":\"not_enough_goods\"}";
    // The same as the SDL goals window: the goods leave the city's stores and the goal counts as met.
    const auto resource=static_cast<eResourceType>(g->fEnumInt1);
    int remaining=g->fRequiredCount;
    for(const auto cid:mBoard->personPlayerCitiesOnBoard()) { remaining-=mBoard->takeResource(cid,resource,remaining); if(remaining<=0) break; }
    g->fStatusCount=g->fRequiredCount;
    return episode();
}
// The recorded introduction of the running episode (relative to the game folder), when the campaign has one on disk.
std::string eSimulationService::episodeVoice() {
    if(!mCampaign) return "";
    const auto path=mCampaign->currentEpisodeAudioFilePath(true);
    std::error_code ec;
    if(path.empty() || !std::filesystem::exists(path,ec)) return "";
    const std::string root=eGameDir::path("");
    std::string relative=path.rfind(root,0)==0?path.substr(root.size()):path;
    for(const char* lang:{"Audio/Voice_en/","Audio/Voice_ru/"}) {
        const std::string prefix=lang;
        if(relative.rfind(prefix,0)==0) relative="Audio/Voice/"+relative.substr(prefix.size());
    }
    return relative;
}
// The goal kinds by name, for the objectives panel's icons.
static const char* goalKind(const eEpisodeGoalType t) {
    switch(t) {
    case eEpisodeGoalType::population: return "population";
    case eEpisodeGoalType::treasury: return "treasury";
    case eEpisodeGoalType::sanctuary: return "sanctuary";
    case eEpisodeGoalType::support: return "support";
    case eEpisodeGoalType::quest: return "quest";
    case eEpisodeGoalType::slay: return "slay";
    case eEpisodeGoalType::rule: return "rule";
    case eEpisodeGoalType::housing: return "housing";
    case eEpisodeGoalType::setAsideGoods: return "set_aside";
    case eEpisodeGoalType::surviveUntil: return "survive";
    case eEpisodeGoalType::completeBefore: return "deadline";
    case eEpisodeGoalType::tradingPartners: return "trade";
    case eEpisodeGoalType::yearlyProduction: return "production";
    case eEpisodeGoalType::yearlyProfit: return "profit";
    case eEpisodeGoalType::pyramid: return "pyramid";
    case eEpisodeGoalType::hippodrome: return "hippodrome";
    }
    return "other";
}
// The houses of the player's cities below a housing goal's level: how many stand at each level (with the level's
// name), how many people live in them, and for each need how many of them lack it to reach the goal's level.
std::string eSimulationService::housingShortfall(const bool elite,const int level) {
    static const char* needNames[]={"food","water","fleece","oil","arms","wine","horse","venues","appeal"};
    const auto type=elite?eBuildingType::eliteHousing:eBuildingType::commonHouse;
    std::map<int,std::pair<int,int>> levels; // level -> houses, people
    std::map<int,int> lacking;               // need -> houses
    int houses=0, people=0;
    const auto wanted=eHouseNeeds::needs(elite,level);
    for(const auto cid:mBoard->personPlayerCitiesOnBoard()) {
        mBoard->buildings(cid,[&](eBuilding* const b) {
            if(b->type()!=type) return false;
            const auto h=static_cast<eHouseBase*>(b);
            if(h->level()>=level) return false;
            ++houses; people+=h->people();
            auto& at=levels[h->level()]; at.first++; at.second+=h->people();
            for(const auto need:eHouseNeeds::missing(wanted,eHouseNeeds::has(h))) lacking[int(need)]++;
            return false;
        });
    }
    std::ostringstream o;
    o << "{\"houses\":" << houses << ",\"people\":" << people << ",\"target\":" << quote(elite?eEliteHousing::sName(level):eSmallHouse::sName(level)) << ",\"levels\":[";
    bool first=true;
    for(const auto& [l,count]:levels) {
        if(!first) o << ','; first=false;
        o << "{\"level\":" << l << ",\"name\":" << quote(elite?eEliteHousing::sName(l):eSmallHouse::sName(l)) << ",\"houses\":" << count.first << ",\"people\":" << count.second << '}';
    }
    o << "],\"missing\":[";
    first=true;
    for(const auto& [need,count]:lacking) {
        if(need<0 || need>=int(std::size(needNames))) continue;
        if(!first) o << ','; first=false;
        o << "{\"need\":" << quote(needNames[need]) << ",\"houses\":" << count << '}';
    }
    o << "]}";
    return o.str();
}
// The running episode as the player reads it: adventure and episode titles, the introduction, and every goal with
// its live status (the same texts and progress rule as the SDL objectives tracker).
std::string eSimulationService::episode() {
    if(!mBoard || !mCampaign) return "{\"error\":\"city_not_loaded\"}";
    mBoard->waitUntilFinished();
    const auto e=mCampaign->currentEpisode();
    if(!e) return "{\"error\":\"city_not_loaded\"}";
    const bool colony=mCampaign->currentEpisodeType()==eEpisodeType::colony;
    const auto capital=mBoard->boardCityWithId(mBoard->currentCityId());
    const bool atlantean=capital?capital->atlantean():false;
    // The goods the goals count are totalled from the stores, as the SDL goals window does before it reads them.
    for(const auto cid:mBoard->personPlayerCitiesOnBoard()) mBoard->updateResources(cid);
    mBoard->checkGoalsFulfilled();
    auto introduction=e->fIntroduction; eStringHelpers::replaceSpecial(introduction);
    auto complete=e->fComplete; eStringHelpers::replaceSpecial(complete);
    std::ostringstream out;
    const auto voice=[&](const std::string& path) {
        std::error_code ec; if(path.empty() || !std::filesystem::exists(path,ec)) return std::string();
        return relativeSound(path);
    };
    out << "{\"kind\":\"episode\",\"victory\":" << (mVictory?"true":"false") << ",\"defeat\":" << (mTerminal&&!mVictory?"true":"false")
        << ",\"colony\":" << (colony?"true":"false") << ",\"episode_number\":" << (mCampaign->currentEpisodeId()+1)
        << ",\"episode_count\":" << (colony?int(mCampaign->colonyEpisodes().size()):int(mCampaign->parentCityEpisodes().size()))
        << ",\"difficulty\":" << int(mCampaign->difficulty()) << ",\"victory_voice\":" << quote(voice(mCampaign->currentEpisodeAudioFilePath(false)))
        << ",\"title\":" << quote(mCampaign->titleText()) << ",\"episode_title\":" << quote(e->fTitle)
        << ",\"voice\":" << quote(episodeVoice()) << ",\"introduction\":" << quote(introduction) << ",\"complete\":" << quote(complete) << ",\"finished\":" << (mTerminal?"true":"false") << ",\"goals\":[";
    bool first=true; int met=0, total=0;
    for(const auto& g:mBoard->goals()) {
        if(!g) continue;
        ++total; const bool done=g->met(); if(done) ++met;
        double progress=done?1.0:0.0;
        if(!done) switch(g->fType) {
        case eEpisodeGoalType::population: case eEpisodeGoalType::treasury: case eEpisodeGoalType::housing:
        case eEpisodeGoalType::support: case eEpisodeGoalType::yearlyProduction: case eEpisodeGoalType::yearlyProfit:
        case eEpisodeGoalType::tradingPartners:
            if(g->fRequiredCount>0) progress=std::clamp(double(g->fStatusCount)/g->fRequiredCount,0.0,1.0);
            break;
        case eEpisodeGoalType::sanctuary: case eEpisodeGoalType::pyramid:
            progress=g->fEnumInt1==-1 ? (g->fRequiredCount>0?std::clamp(double(g->fStatusCount)/g->fRequiredCount,0.0,1.0):0.0)
                                      : std::clamp(double(g->fStatusCount)/100.0,0.0,1.0);
            break;
        case eEpisodeGoalType::setAsideGoods:
            if(g->fRequiredCount>0) progress=std::clamp(double(g->fPreviewCount)/g->fRequiredCount,0.0,1.0);
            break;
        default: break;
        }
        if(!first) out << ','; first=false;
        // "Set aside" goods count only once the player reserves them; the button is offered when the stock is there.
        const bool aside=g->fType==eEpisodeGoalType::setAsideGoods && !done && g->fPreviewCount>=g->fRequiredCount;
        out << "{\"index\":" << (total-1) << ",\"text\":" << quote(g->text(colony,atlantean,*mBoard)) << ",\"status\":" << quote(g->statusText(*mBoard))
            << ",\"met\":" << (done?"true":"false") << ",\"progress\":" << progress << ",\"set_aside\":" << (aside?"true":"false")
            << ",\"kind\":" << quote(goalKind(g->fType)) << ",\"required\":" << g->fRequiredCount
            << ",\"current\":" << (g->fType==eEpisodeGoalType::setAsideGoods?g->fPreviewCount:g->fStatusCount);
        // A housing goal also says what holds the houses below the level back (eHouseNeeds, as the SDL house card).
        if(g->fType==eEpisodeGoalType::housing && !done) out << ",\"housing\":" << housingShortfall(g->fEnumInt1!=0,g->fEnumInt2);
        out << '}';
    }
    out << "],\"met\":" << met << ",\"total\":" << total << '}';
    return out.str();
}
// The partner a trade post may be opened with (the SDL panel's own list), by its position in the world's city list.
std::optional<eTradePartner> eSimulationService::tradePartner(const eCityId cid,const int index,const bool water) {
    for(const auto& item:eTradePartners::available(*mBoard,cid,false)) if(item.index==index && item.water==water) return item;
    return std::nullopt;
}
// Every city a trade post could serve, what it buys and sells, and whether one can be opened now.
std::string eSimulationService::tradePartners() {
    if(!mBoard) return "{\"error\":\"city_not_loaded\"}";
    mBoard->waitUntilFinished();
    const auto pid=mBoard->personPlayer();
    const auto focus=mBoard->tile(mFocusX,mFocusY);
    const auto cid=focus?focus->cityId():eCityId::neutralFriendly;
    const auto open=eTradePartners::available(*mBoard,cid,false);
    const auto goods=[&](const std::vector<eResourceTrade>& list) {
        std::ostringstream out; out << '['; bool first=true;
        for(const auto& trade:list) {
            if(!first) out << ','; first=false;
            out << "{\"resource\":" << int(trade.fType) << ",\"name\":" << quote(eResourceTypeHelpers::typeName(trade.fType))
                << ",\"price\":" << mBoard->price(trade.fType) << ",\"used\":" << trade.used(pid) << ",\"max\":" << trade.fMax << '}';
        }
        out << ']'; return out.str();
    };
    std::ostringstream out; out << "{\"kind\":\"trade_partners\",\"partners\":[";
    bool first=true; int index=-1;
    for(const auto& city:mBoard->world().cities()) {
        ++index;
        if(city->cityId()==cid || city->isRival() || !city->active() || !city->visible()) continue;
        const bool own=mBoard->boardCityWithId(city->cityId()) && mBoard->cityIdToPlayerId(city->cityId())==pid;
        if(city->buys().empty() && city->sells().empty() && !own) continue;
        bool available=false; for(const auto& item:open) available=available||item.index==index;
        if(!first) out << ','; first=false;
        out << "{\"index\":" << index << ",\"name\":" << quote(city->name()) << ",\"water\":" << (city->waterTrade(cid)?"true":"false")
            << ",\"own\":" << (own?"true":"false") << ",\"has_post\":" << (mBoard->hasTradePost(cid,*city)?"true":"false")
            << ",\"available\":" << (available?"true":"false") << ",\"trading\":" << (city->trades()?"true":"false")
            << ",\"sells\":" << goods(city->sells()) << ",\"buys\":" << goods(city->buys()) << '}';
    }
    out << "]}"; return out.str();
}
std::string eSimulationService::placement(const std::string& name,int x,int y,int orientation,int partner) {
    mBoard->waitUntilFinished();
    const auto pid=mBoard->personPlayer();
    auto t=(x>=mX && y>=mY && x<mX+mW && y<mY+mH)?mBoard->tile(x,y):nullptr;
    if(!t) return "{\"error\":\"out_of_map\"}";
    std::string reason;
    if(!t) reason="out_of_map";
    else if(mBlocked) reason="pending_decision";
    else if(mBoard->cityIdToPlayerId(t->cityId())!=pid) reason="not_owned";
    else if(mBoard->drachmas(pid)<-1000) reason="insufficient_funds";
    int width=1,height=1,cost=0,altitude=t?t->doubleAltitude():0;
    bool confirmation=false; std::string model="road", samplePieces;
    std::ostringstream cells;
    if(name=="demolish") {
        auto b=t?eBuildingsToErase::target(t->underBuilding()):nullptr;
        if(b) {
            if(b->isOnFire()) reason="on_fire";
            if(b->playerId()!=pid) reason="not_owned";
            const auto rect=b->tileRect(); x=rect.x; y=rect.y; width=rect.w; height=rect.h;
            if(auto center=b->centerTile()) altitude=center->doubleAltitude();
            eBuildingsToErase eraser; eraser.addBuilding(b);
            confirmation=eraser.hasImportantBuildings() || eraser.hasNonEmptyAgoras();
            if(mDemolitionTarget.get()!=b) { mDemolitionTarget=b; ++mDemolitionToken; }
        } else if(t && t->terrain()!=eTerrain::forest && t->terrain()!=eTerrain::choppedForest) reason="nothing_to_demolish";
        cost=eDifficultyHelpers::buildingCost(mBoard->difficulty(pid),eBuildingType::erase);
        model="";
        cells << '[' << x << ',' << y << ',' << altitude << ',' << (reason.empty()?"true":"false") << ',' << quote(reason) << ']';
    } else {
        const auto found=buildSpecs.find(name);
        if(found==buildSpecs.end()) return "{\"error\":\"unsupported_build\"}";
        const auto& spec=found->second;
        width=spec.w; height=spec.h; model=spec.asset[0]?spec.asset:"unconverted";
        cost=eDifficultyHelpers::buildingCost(mBoard->difficulty(pid),costType(spec));
        const auto cid=t?t->cityId():eCityId::neutralFriendly;
        if(t && reason.empty() && !mBoard->supportsBuilding(cid,spec.mode)) reason="building_not_available";
        // A trade post belongs to one partner city; a land post needs a land partner, a pier a sea partner.
        if(spec.kind==Kind::trade && t && reason.empty() && !tradePartner(cid,partner,name=="pier")) reason="trade_partner_unavailable";
        if(spec.kind==Kind::agora) {
            eAgoraOrientation lay=eAgoraOrientation::bottomRight;
            std::vector<eTile*> sites;
            if(t && reason.empty()) {
                sites=eAgoraPlacement::find(*mBoard,t,spec.grand,lay,cid,pid,false);
                if(sites.empty()) reason="no_agora_site";
            }
            if(sites.empty()) {
                cells << '[' << x << ',' << y << ',' << altitude << ",false," << quote(reason) << ']';
            } else {
                int minX=INT_MAX,minY=INT_MAX; bool first=true;
                // A grand agora lists its shared road strip once for each of its two halves.
                std::set<const eTile*> listed;
                for(const auto* tile:sites) { minX=std::min(minX,tile->x()); minY=std::min(minY,tile->y()); }
                const bool wide=lay==eAgoraOrientation::bottomLeft || lay==eAgoraOrientation::topRight;
                x=minX; y=minY; width=wide?6:(spec.grand?5:3); height=wide?(spec.grand?5:3):6;
                for(const auto* tile:sites) {
                    if(!listed.insert(tile).second) continue;
                    if(!first) cells << ','; first=false;
                    cells << '[' << tile->x() << ',' << tile->y() << ',' << tile->doubleAltitude() << ",true,\"\"]";
                }
            }
        } else if(spec.kind==Kind::gate) {
            // (x, y) is the corner of the whole footprint: 5x2 tiles, or 2x5 when turned a quarter.
            const bool turned=orientation%2==1;
            orientation=turned?1:0; width=turned?2:5; height=turned?5:2;
            const std::string globalReason=reason;
            bool first=true;
            for(int dx=0;dx<width;++dx) for(int dy=0;dy<height;++dy) {
                const int tx=x+dx,ty=y+dy;
                const auto tile=(tx>=mX && ty>=mY && tx<mX+mW && ty<mY+mH)?mBoard->tile(tx,ty):nullptr;
                std::string cellReason=globalReason;
                if(cellReason.empty()) cellReason=gateReason(tx,ty,turned?dy==2:dx==2,cid,pid);
                if(reason.empty() && !cellReason.empty()) reason=cellReason;
                if(!first) cells << ','; first=false;
                cells << '[' << tx << ',' << ty << ',' << (tile?tile->doubleAltitude():altitude) << ',' << (cellReason.empty()?"true":"false") << ',' << quote(cellReason) << ']';
            }
        } else if(spec.kind==Kind::trade && name=="pier") {
            // (x, y) is the pier's first tile; the SDL view names the shore tile one row further on.
            const int hx=x, hy=y+1; eDiagonalOrientation lay=eDiagonalOrientation::topLeft; bool fit=false;
            if(t && reason.empty()) {
                if(!eShorePlacement::canBuildFishery(*mBoard,hx,hy,lay)) reason="not_on_shore";
                else {
                    fit=true; int px,py; eShorePlacement::pierPostCorner(hx,hy,lay,px,py);
                    if(!mBoard->canBuildBase(px,px+4,py,py+4,false,cid,pid)) reason="blocked_terrain";
                    else if(!eShorePlacement::pierHasSeaAccess(*mBoard,hx,hy,cid)) reason="no_sea_access";
                }
            }
            orientation=int(lay); width=2; height=2;
            bool first=true;
            const auto cell=[&](int cx,int cy) {
                const auto tile=(cx>=mX && cy>=mY && cx<mX+mW && cy<mY+mH)?mBoard->tile(cx,cy):nullptr;
                if(!first) cells << ','; first=false;
                cells << '[' << cx << ',' << cy << ',' << (tile?tile->doubleAltitude():altitude) << ',' << (reason.empty()?"true":"false") << ',' << quote(reason) << ']';
            };
            for(int dy=0;dy<2;++dy) for(int dx=0;dx<2;++dx) cell(x+dx,y+dy);
            if(fit) { int px,py; eShorePlacement::pierPostCorner(hx,hy,lay,px,py); for(int dy=0;dy<4;++dy) for(int dx=0;dx<4;++dx) cell(px+dx,py+dy); }
        } else if(spec.kind==Kind::sanctuary) {
            // (x, y) is the tile under the pointer; the layout is centred on it, as the SDL view centres it.
            const bool turned=orientation%2==1; orientation=turned?1:0;
            const auto* layout=eSanctBlueprints::sSanctuaryBlueprint(spec.type,turned);
            if(!layout) return "{\"error\":\"unsupported_build\"}";
            width=layout->fW; height=layout->fH;
            const int minX=x-width/2, minY=y-height/2;
            if(t && reason.empty()) {
                if(!mBoard->boardCityWithId(cid)) reason="not_owned";
                else if(int(mBoard->sanctuaries(cid).size())>=mBoard->maxSanctuaries(cid)) reason="max_sanctuaries";
                else if(mBoard->resourceCount(cid,eResourceType::marble)<eBuilding::sInitialMarbleCost(spec.type)) reason="need_marble";
            }
            const std::string globalReason=reason; bool first=true;
            for(int dy=0;dy<height;++dy) for(int dx=0;dx<width;++dx) {
                const int tx=minX+dx,ty=minY+dy;
                auto tile=(tx>=mX && ty>=mY && tx<mX+mW && ty<mY+mH)?mBoard->tile(tx,ty):nullptr;
                std::string cellReason=globalReason;
                if(cellReason.empty()) {
                    if(!tile) cellReason="out_of_map";
                    else if(tile->cityId()!=cid) cellReason="other_district";
                    else if(tile->underBuilding()) cellReason="occupied";
                    else if(!mBoard->canBuildBase(tx,tx+1,ty,ty+1,false,cid,pid)) cellReason="blocked_terrain";
                }
                if(reason.empty() && !cellReason.empty()) reason=cellReason;
                if(!first) cells << ','; first=false;
                cells << '[' << tx << ',' << ty << ',' << (tile?tile->doubleAltitude():altitude) << ',' << (cellReason.empty()?"true":"false") << ',' << quote(cellReason) << ']';
            }
            if(t && reason.empty() && !mBoard->canBuildBase(minX,minX+width,minY,minY+height,false,cid,pid)) reason="native_placement_rejected";
            x=minX; y=minY; model="";
            std::ostringstream pieces; bool firstPiece=true;
            for(const auto& piece:sanctuaryPieces(*layout,sanctuaryGod(spec.type),turned,minX,minY)) {
                if(!firstPiece) pieces << ','; firstPiece=false;
                pieces << "{\"asset\":" << quote(piece.asset) << ",\"x\":" << piece.x << ",\"y\":" << piece.y << ",\"w\":" << piece.w << ",\"h\":" << piece.h << ",\"orientation\":" << piece.turns << '}';
            }
            samplePieces=pieces.str();
        } else if(spec.kind==Kind::pyramid) {
            // (x, y) is the tile under the pointer; the pyramid is centred on it, as the SDL view centres it, and does not turn.
            orientation=0; width=spec.w; height=spec.h;
            const int minX=x-width/2, minY=y-height/2;
            if(t && reason.empty() && !mBoard->boardCityWithId(cid)) reason="not_owned";
            const std::string globalReason=reason; bool first=true;
            for(int dy=0;dy<height;++dy) for(int dx=0;dx<width;++dx) {
                const int tx=minX+dx,ty=minY+dy;
                auto tile=(tx>=mX && ty>=mY && tx<mX+mW && ty<mY+mH)?mBoard->tile(tx,ty):nullptr;
                std::string cellReason=globalReason;
                if(cellReason.empty()) {
                    if(!tile) cellReason="out_of_map";
                    else if(tile->cityId()!=cid) cellReason="other_district";
                    else if(tile->underBuilding()) cellReason="occupied";
                    else if(!mBoard->canBuildBase(tx,tx+1,ty,ty+1,false,cid,pid)) cellReason="blocked_terrain";
                }
                if(reason.empty() && !cellReason.empty()) reason=cellReason;
                if(!first) cells << ','; first=false;
                cells << '[' << tx << ',' << ty << ',' << (tile?tile->doubleAltitude():altitude) << ',' << (cellReason.empty()?"true":"false") << ',' << quote(cellReason) << ']';
            }
            if(t && reason.empty() && !mBoard->canBuildBase(minX,minX+width,minY,minY+height,false,cid,pid)) reason="native_placement_rejected";
            x=minX; y=minY; model="";
            // The pieces as the finished pyramid will have them, each lifted by the ground its level raises (four steps a level).
            std::vector<bool> levels; if(const auto city=mBoard->boardCityWithId(cid)) levels=city->pyramidLevels(spec.type);
            const auto dark=[&](const int level) { return level>=0 && level<int(levels.size()) && levels[level]; };
            const auto god=ePyramid::sGod(spec.type);
            std::ostringstream pieces; bool firstPiece=true;
            for(const auto& piece:ePyramid::sPlan(spec.type)) {
                const auto pieceGod=piece.fSpecial>=0 && piece.fSpecial<14?static_cast<eGodType>(piece.fSpecial):god;
                int turns=0;
                if(piece.fKind==ePyramidPlan::eKind::statue || piece.fKind==ePyramidPlan::eKind::monument) turns=sanctuaryQuarterTurns(eBuildingType::templeStatue,0,false);
                else if(piece.fKind==ePyramidPlan::eKind::temple) turns=sanctuaryQuarterTurns(eBuildingType::temple,0,false);
                if(!firstPiece) pieces << ','; firstPiece=false;
                pieces << "{\"asset\":" << quote(pyramidPieceAsset(piece.fKind,piece.fOrientation,piece.fSpecial,piece.fElevation,dark(piece.fElevation),dark(piece.fElevation-1),pieceGod))
                       << ",\"x\":" << minX+piece.fX-(piece.fW-1) << ",\"y\":" << minY+piece.fY-(piece.fH-1) << ",\"w\":" << piece.fW << ",\"h\":" << piece.fH
                       << ",\"orientation\":" << turns << ",\"lift\":" << 4*piece.fElevation << '}';
            }
            samplePieces=pieces.str();
        } else if(spec.kind==Kind::palace || spec.kind==Kind::stadium || spec.kind==Kind::ranch || spec.kind==Kind::godMonument ||
                  spec.kind==Kind::shore || spec.kind==Kind::bridge || spec.kind==Kind::roadblock || spec.kind==Kind::hippodrome ||
                  spec.kind==Kind::crosswalk || (spec.kind==Kind::path && spec.type!=eBuildingType::doricColumn &&
                  spec.type!=eBuildingType::ionicColumn && spec.type!=eBuildingType::corinthianColumn)) {
            // The special cases of the SDL build menu (engine/ebuildplacement): (x, y) is the tile under the pointer, which is
            // the SDL view's anchor, except where noted. Each lists its tiles with a verdict and, when it has several models, its pieces.
            std::vector<std::pair<int,int>> footprint;
            std::ostringstream pieces; bool firstPiece=true;
            const auto piece=[&](const std::string& asset,int px,int py,int pw,int ph,int turns) {
                if(!firstPiece) pieces << ','; firstPiece=false;
                pieces << "{\"asset\":" << quote(asset) << ",\"x\":" << px << ",\"y\":" << py << ",\"w\":" << pw << ",\"h\":" << ph << ",\"orientation\":" << turns << '}';
            };
            const auto rect=[&](int rx,int ry,int rw,int rh) { for(int dy=0;dy<rh;++dy) for(int dx=0;dx<rw;++dx) footprint.emplace_back(rx+dx,ry+dy); };
            bool fits=false; bool multi=false; int cells_cost=-1;
            const bool rotate=orientation%2==1;
            if(spec.kind==Kind::palace) {
                if(reason.empty() && mBoard->hasPalace(cid)) reason="palace_exists";
                if(reason.empty() && mBoard->hasActiveInvasions(cid)) reason="enemy_near";
                int px,py,pw,ph; eBuildPlacement::palaceRect(x,y,rotate,px,py,pw,ph);
                rect(px,py,pw,ph); piece("palace",px,py,pw,ph,rotate?1:0);
                for(const auto& tile:eBuildPlacement::palaceTiles(x,y,rotate)) {
                    footprint.emplace_back(tile.fX,tile.fY); piece(tile.fOther?"palace_tile_lamp":"palace_tile_plain",tile.fX,tile.fY,1,1,0);
                }
                fits=eBuildPlacement::canBuildPalace(*mBoard,x,y,rotate,cid,pid,false); multi=true; orientation=rotate?1:0;
            } else if(spec.kind==Kind::stadium) {
                if(reason.empty() && mBoard->hasStadium(cid)) reason="stadium_exists";
                int sx,sy,sw,sh; eBuildPlacement::stadiumRect(x,y,rotate,sx,sy,sw,sh); rect(sx,sy,sw,sh);
                fits=eBuildPlacement::canBuildStadium(*mBoard,x,y,rotate,cid,pid,false);
                // The model runs along y (the turned form); the snapshot turns a stadium laid along x a quarter.
                orientation=rotate?0:1;
            } else if(spec.kind==Kind::ranch) {
                int rx,ry,qx,qy; eBuildPlacement::horseRanchRects(x,y,orientation,rx,ry,qx,qy);
                rect(rx,ry,3,3); rect(qx,qy,4,4); piece("horse_ranch",rx,ry,3,3,0); piece("horse_ranch_enclosure",qx,qy,4,4,0);
                fits=eBuildPlacement::canBuildHorseRanch(*mBoard,x,y,orientation,cid,pid,false); multi=true;
            } else if(spec.kind==Kind::godMonument) {
                rect(x-1,y-2,4,4); piece(spec.asset,x,y-1,2,2,0);
                for(int dy=0;dy<4;++dy) for(int dx=0;dx<4;++dx) { const int tx=x-1+dx,ty=y-2+dy; if(tx<x || tx>x+1 || ty<y-1 || ty>y) piece("palace_tile_plain",tx,ty,1,1,0); }
                fits=eBuildPlacement::canBuildGodMonument(*mBoard,x,y,cid,pid,false); multi=true; orientation=0;
            } else if(spec.kind==Kind::shore) {
                // As for the pier, (x, y) is the first tile of the building; the SDL view names the tile one row (and for the wharf one
                // column) further on.
                const bool wharf=spec.type==eBuildingType::triremeWharf;
                const int tx=wharf?x+1:x, ty=y+1; eDiagonalOrientation lay=eDiagonalOrientation::topLeft;
                rect(x,y,spec.w,spec.h);
                if(wharf) fits=eBuildPlacement::canBuildTriremeWharf(*mBoard,tx,ty,lay);
                else fits=eShorePlacement::canBuildFishery(*mBoard,tx,ty,lay);
                if(reason.empty() && !fits) reason="not_on_shore";
                if(reason.empty() && wharf && !eBuildPlacement::triremeWharfSeaAccess(*mBoard,tx,ty,cid)) { reason="no_sea_access"; fits=false; }
                orientation=int(lay);
            } else if(spec.kind==Kind::bridge) {
                std::vector<eTile*> path; bool turned=false;
                fits=eBuildPlacement::bridgeTiles(t,eTerrain::water,path,turned) || eBuildPlacement::bridgeTiles(t,eTerrain::quake,path,turned);
                if(!fits) path={t};
                for(auto* tile:path) if(tile) footprint.emplace_back(tile->x(),tile->y());
                if(reason.empty() && !fits) reason="no_bridge_site";
                cells_cost=cost*int(path.size()); model="";
            } else if(spec.kind==Kind::roadblock) {
                footprint.emplace_back(x,y);
                fits=eBuildPlacement::canPlaceRoadblock(t);
                if(reason.empty() && !fits) reason=(t->underBuildingType()==eBuildingType::road && static_cast<eRoad*>(t->underBuilding())->isRoadblock())?"roadblock_exists":"needs_road";
                const auto t1=mBoard->tile(x-1,y), t2=mBoard->tile(x+1,y);
                orientation=((t1 && t1->hasRoad()) || (t2 && t2->hasRoad()))?1:0;
            } else if(spec.kind==Kind::hippodrome) {
                // (x, y) is the plate's first tile, as for any 4x4 building; the plate is the one of those that fit beside the city's
                // other plates that the turn picks (the SDL view cycles through them as time passes).
                const int tx=x+1, ty=y+2;
                rect(x,y,4,4);
                const auto ids=eBuildPlacement::hippodromePieceIds(*mBoard,cid,tx,ty);
                if(ids.empty()) { if(reason.empty()) reason="no_hippodrome_fit"; }
                else model="hippodrome_"+std::to_string(ids[size_t(orientation)%ids.size()]);
                fits=!ids.empty() && mBoard->canBuild(tx,ty,4,4,false,cid,pid);
                orientation=0;
            } else if(spec.kind==Kind::crosswalk) {
                std::vector<eTile*> path;
                fits=eBuildPlacement::crosswalkTiles(*mBoard,x,y,path);
                if(!fits) path={t};
                for(auto* tile:path) if(tile) footprint.emplace_back(tile->x(),tile->y());
                if(reason.empty() && !fits) reason="needs_hippodrome_straight";
                model="";
            } else {
                // An avenue or boulevard clicked on one tile: its median there.
                footprint.emplace_back(x,y);
                fits=eBuildPlacement::canBuildAvenueMedian(*mBoard,t,spec.type==eBuildingType::boulevard,cid,pid,false);
                if(reason.empty() && !fits) reason=t->underBuildingType()==spec.type?"nothing_to_build":"blocked_terrain";
            }
            if(cells_cost>=0) cost=cells_cost;
            // Each tile's own verdict (the special tools that go on roads, water or a hippodrome judge only as a whole).
            const bool ownGround=spec.kind!=Kind::bridge && spec.kind!=Kind::roadblock && spec.kind!=Kind::crosswalk && spec.kind!=Kind::path && spec.kind!=Kind::shore;
            const std::string globalReason=reason; bool first=true;
            int minX=INT_MAX,minY=INT_MAX,maxX=INT_MIN,maxY=INT_MIN;
            for(const auto& cell:footprint) {
                const int tx=cell.first, ty=cell.second;
                minX=std::min(minX,tx); minY=std::min(minY,ty); maxX=std::max(maxX,tx); maxY=std::max(maxY,ty);
                auto tile=(tx>=mX && ty>=mY && tx<mX+mW && ty<mY+mH)?mBoard->tile(tx,ty):nullptr;
                std::string cellReason=globalReason;
                if(cellReason.empty() && ownGround) {
                    if(!tile) cellReason="out_of_map";
                    else if(tile->cityId()!=cid) cellReason="other_district";
                    else if(tile->underBuilding()) cellReason="occupied";
                    else if(tile->isElevationTile()) cellReason="needs_flat_ground";
                    else if(!mBoard->canBuildBase(tx,tx+1,ty,ty+1,false,cid,pid)) cellReason="blocked_terrain";
                }
                if(reason.empty() && !cellReason.empty()) reason=cellReason;
                if(!first) cells << ','; first=false;
                cells << '[' << tx << ',' << ty << ',' << (tile?tile->doubleAltitude():altitude) << ',' << (cellReason.empty()?"true":"false") << ',' << quote(cellReason) << ']';
            }
            if(reason.empty() && !fits) reason="native_placement_rejected";
            if(!footprint.empty()) { x=minX; y=minY; width=maxX-minX+1; height=maxY-minY+1; }
            if(multi) { model=""; samplePieces=pieces.str(); }
        } else if(spec.kind==Kind::vendor) {
            auto* const space=t?eAgoraPlacement::spaceAt(*mBoard,x,y):nullptr;
            if(reason.empty()) {
                if(!space) reason=(t && t->underBuilding() && dynamic_cast<eVendor*>(t->underBuilding()))?"occupied":"needs_agora_space";
                else if(static_cast<eAgoraSpace*>(space)->agora()->vendor(spec.resource)) reason="vendor_exists";
                else if(!space->centerTile()) reason="needs_agora_space";
            }
            if(space) {
                const auto rect=space->tileRect(); x=rect.x; y=rect.y; width=rect.w; height=rect.h;
                if(const auto centre=space->centerTile()) altitude=centre->doubleAltitude();
            }
            bool first=true;
            for(int dy=0;dy<height;++dy) for(int dx=0;dx<width;++dx) {
                const auto tile=mBoard->tile(x+dx,y+dy);
                if(!first) cells << ','; first=false;
                cells << '[' << x+dx << ',' << y+dy << ',' << (tile?tile->doubleAltitude():altitude) << ',' << (reason.empty()?"true":"false") << ',' << quote(reason) << ']';
            }
        } else {
            const std::string globalReason=reason;
            bool first=true;
            for(int dy=0;dy<height;++dy) for(int dx=0;dx<width;++dx) {
                const int tx=x+dx,ty=y+dy;
                auto tile=(tx>=mX && ty>=mY && tx<mX+mW && ty<mY+mH)?mBoard->tile(tx,ty):nullptr;
                std::string cellReason=globalReason;
                if(cellReason.empty()) {
                    if(!tile) cellReason="out_of_map";
                    else if(tile->cityId()!=cid) cellReason="other_district";
                    else if(tile->underBuilding()) cellReason="occupied";
                    else if(spec.type!=eBuildingType::road && tile->isElevationTile()) cellReason="needs_flat_ground";
                    else if(!mBoard->canBuildBase(tx,tx+1,ty,ty+1,false,cid,pid,spec.fertile,spec.flat)) cellReason="blocked_terrain";
                }
                if(reason.empty() && !cellReason.empty()) reason=cellReason;
                if(!first) cells << ','; first=false;
                cells << '[' << tx << ',' << ty << ',' << (tile?tile->doubleAltitude():altitude) << ',' << (cellReason.empty()?"true":"false") << ',' << quote(cellReason) << ']';
            }
            // Same inclusive/exclusive footprint and flags used by buildBase; no allocation/RNG draws.
            if(t && reason.empty() && !mBoard->canBuildBase(x,x+width,y,y+height,false,cid,pid,spec.fertile,spec.flat)) reason="native_placement_rejected";
        }
    }
    std::ostringstream out;
    out << "{\"kind\":\"placement\",\"tool\":" << quote(name) << ",\"x\":" << x << ",\"y\":" << y
        << ",\"w\":" << width << ",\"h\":" << height << ",\"altitude\":" << altitude << ",\"orientation\":" << orientation
        << ",\"asset\":" << quote(model) << ",\"cost\":" << cost << ",\"valid\":" << (reason.empty()?"true":"false")
        << ",\"reason\":" << quote(reason) << ",\"confirmation_required\":" << (confirmation?"true":"false")
        << ",\"target_token\":" << mDemolitionToken << ",\"tiles\":[" << cells.str() << ']'
        << (samplePieces.empty()?std::string():",\"pieces\":["+samplePieces+"],\"marble\":"+std::to_string(name=="demolish"?0:eBuilding::sInitialMarbleCost(buildSpecs.find(name)->second.type)))
        << '}';
    return out.str();
}
bool eSimulationService::roadPath(const int x1,const int y1,const int x2,const int y2,std::vector<eTile*>& tiles) {
    tiles.clear();
    const auto inside=[&](int x,int y) { return x>=mX && y>=mY && x<mX+mW && y<mY+mH; };
    if(!inside(x1,y1) || !inside(x2,y2)) return false;
    const auto start=mBoard->tile(x1,y1), end=mBoard->tile(x2,y2);
    if(!start || !end) return false;
    tiles.push_back(start);
    if(start==end) return true;
    // Exactly the SDL drag rule (eGameWidget::roadPath): orthogonal tile moves over buildable ground that
    // holds nothing but roads, and no climbing of unwalkable elevation.
    const auto allowed=eTerrain::buildable;
    ePathFinder finder([allowed](eTileBase* const t) {
        if(!static_cast<bool>(allowed & t->terrain())) return false;
        const auto bt=t->underBuildingType();
        const bool open=bt==eBuildingType::road || bt==eBuildingType::avenue || bt==eBuildingType::boulevard || bt==eBuildingType::none;
        if(!open) return false;
        if(!t->walkableElev() && t->isElevationTile()) return false;
        return true;
    }, [x2,y2](eTileBase* const t) { return t->x()==x2 && t->y()==y2; });
    const int w=mBoard->width(), h=mBoard->height();
    std::vector<eOrientation> path;
    if(!finder.findPath({0,0,w,h},start,100,true,w,h) || !finder.extractPath(path)) { tiles.clear(); return false; }
    eTile* t=start;
    for(int i=int(path.size())-1;i>=0 && t;--i) { t=t->neighbour<eTile>(path[i]); if(t) tiles.push_back(t); }
    return !tiles.empty() && tiles.back()==end;
}
std::string eSimulationService::roadReason(eTile* const tile,const int cityId,bool& existing) {
    existing=false;
    if(!tile) return "out_of_map";
    const auto pid=mBoard->personPlayer();
    const auto cid=static_cast<eCityId>(cityId);
    if(tile->cityId()!=cid) return "other_district";
    if(mBoard->cityIdToPlayerId(tile->cityId())!=pid) return "not_owned";
    const auto bt=tile->underBuildingType();
    if(bt==eBuildingType::road || bt==eBuildingType::avenue || bt==eBuildingType::boulevard) { existing=true; return ""; }
    if(tile->underBuilding()) return "occupied";
    if(!mBoard->canBuildBase(tile->x(),tile->x()+1,tile->y(),tile->y()+1,false,cid,pid,false,true)) return "blocked_terrain";
    return "";
}
std::string eSimulationService::roadPreview(const int x1,const int y1,const int x2,const int y2) {
    mBoard->waitUntilFinished();
    const auto pid=mBoard->personPlayer();
    std::vector<eTile*> tiles;
    const bool found=roadPath(x1,y1,x2,y2,tiles);
    const auto startTile=(x1>=mX && y1>=mY && x1<mX+mW && y1<mY+mH)?mBoard->tile(x1,y1):nullptr;
    if(!startTile) return "{\"error\":\"out_of_map\"}";
    const int cityId=static_cast<int>(startTile->cityId());
    const int unit=eDifficultyHelpers::buildingCost(mBoard->difficulty(pid),eBuildingType::road);
    std::string reason;
    if(mBlocked) reason="pending_decision";
    else if(!mBoard->supportsBuilding(startTile->cityId(),eBuildingMode::road)) reason="building_not_available";
    else if(!found) reason="no_path";
    int treasury=mBoard->drachmas(pid), fresh=0, existing=0, affordable=0;
    if(reason.empty() && treasury<-1000) reason="insufficient_funds";
    std::ostringstream cells;
    bool first=true;
    const auto list=found?tiles:std::vector<eTile*>{startTile};
    // A verdict for the whole drag; otherwise each tile is judged on its own (the build skips a blocked tile and goes on).
    const std::string globalReason=reason;
    for(auto* tile:list) {
        bool old=false; std::string why=globalReason.empty()?roadReason(tile,cityId,old):globalReason;
        if(why.empty() && !old) {
            // The native rule: building may run 1000 drachmas into debt, then stops.
            if(treasury-unit<-1000) why="insufficient_funds"; else { treasury-=unit; ++affordable; }
        }
        if(old) ++existing; else if(why.empty()) ++fresh;
        const auto alt=tile?tile->doubleAltitude():0;
        if(!first) cells << ','; first=false;
        cells << '[' << (tile?tile->x():x1) << ',' << (tile?tile->y():y1) << ',' << alt << ',' << (why.empty()?"true":"false")
              << ',' << quote(why) << ',' << (old?1:0) << ']';
        if(!why.empty() && reason.empty()) reason=why;
    }
    if(reason.empty() && fresh==0) reason="nothing_to_build";
    std::ostringstream out;
    out << "{\"kind\":\"road_path\",\"x1\":" << x1 << ",\"y1\":" << y1 << ",\"x2\":" << x2 << ",\"y2\":" << y2
        << ",\"path_found\":" << (found?"true":"false") << ",\"unit_cost\":" << unit << ",\"cost\":" << fresh*unit
        << ",\"new\":" << fresh << ",\"existing\":" << existing << ",\"valid\":" << (fresh>0?"true":"false")
        << ",\"complete\":" << (reason.empty()?"true":"false") << ",\"reason\":" << quote(reason) << ",\"tiles\":[" << cells.str() << "]}";
    return out.str();
}
// What can be dragged over an area, and the step of its grid: common housing 2x2, elite housing 4x4, parks, orchards and
// livestock on every tile (an animal takes a 1x2 of fertile ground, so neighbouring tiles are skipped as they fill).
static bool everyTile(const std::string& name) {
    return name=="park" || name=="vine" || name=="olive_tree" || name=="orange_tree" || name=="goat" || name=="sheep" || name=="cattle";
}
static bool areaTool(const std::string& name) { return name=="house" || name=="elite_house" || everyTile(name); }
// The SDL view stops a housing or park drag at 1000 drachmas of debt tile by tile; orchards and livestock only before they start.
static bool fundsEachTile(const std::string& name) { return name=="house" || name=="elite_house" || name=="park"; }
// The footprints a drag covers, as (x, y) corners in the SDL order: columns then rows, from the pressed tile toward the
// released one in steps of the building's size (a park fills every tile of the rectangle).
std::vector<std::pair<int,int>> eSimulationService::areaCells(const std::string& name,const int x1,const int y1,const int x2,const int y2) const {
    std::vector<std::pair<int,int>> cells;
    const auto found=buildSpecs.find(name);
    if(found==buildSpecs.end() || !areaTool(name)) return cells;
    const auto& spec=found->second;
    if(everyTile(name)) {
        for(int x=std::min(x1,x2);x<=std::max(x1,x2);++x) for(int y=std::min(y1,y2);y<=std::max(y1,y2);++y) cells.emplace_back(x,y);
        return cells;
    }
    const int dx=x2>=x1?spec.w:-spec.w, dy=y2>=y1?spec.h:-spec.h;
    for(int x=x1;dx>0?x<=x2:x>=x2;x+=dx) for(int y=y1;dy>0?y<=y2:y>=y2;y+=dy) cells.emplace_back(x,y);
    return cells;
}
std::string eSimulationService::areaPreview(const std::string& name,const int x1,const int y1,const int x2,const int y2) {
    mBoard->waitUntilFinished();
    const auto found=buildSpecs.find(name);
    if(found==buildSpecs.end() || !areaTool(name)) return "{\"error\":\"unsupported_build\"}";
    const auto& spec=found->second;
    const auto pid=mBoard->personPlayer();
    const auto inside=[&](int x,int y) { return x>=mX && y>=mY && x<mX+mW && y<mY+mH; };
    const auto startTile=inside(x1,y1)?mBoard->tile(x1,y1):nullptr;
    if(!startTile) return "{\"error\":\"out_of_map\"}";
    const auto cells=areaCells(name,x1,y1,x2,y2);
    const int unit=eDifficultyHelpers::buildingCost(mBoard->difficulty(pid),spec.type);
    std::string reason;
    if(mBlocked) reason="pending_decision";
    else if(!mBoard->supportsBuilding(startTile->cityId(),spec.mode)) reason="building_not_available";
    int treasury=mBoard->drachmas(pid), fresh=0;
    if(reason.empty() && !fundsEachTile(name) && treasury<-1000) reason="insufficient_funds";
    constexpr size_t listed=3000;
    std::ostringstream out; bool first=true, complete=!cells.empty(); size_t index=0;
    // Livestock: how many more animals the city's sheds, dairies and corrals allow, and the tiles the planned ones take.
    const bool animal=spec.kind==Kind::animal;
    int allowed=animal?mBoard->countAllowed(startTile->cityId(),spec.type):0;
    std::set<std::pair<int,int>> taken;
    // A verdict for the whole drag (a pending decision, an unavailable building); each plot is otherwise judged on its own.
    const std::string globalReason=reason;
    for(const auto& cell:cells) {
        const auto tile=inside(cell.first,cell.second)?mBoard->tile(cell.first,cell.second):nullptr;
        std::string cellReason=globalReason;
        if(cellReason.empty() && animal) {
            const int x=cell.first, y=cell.second;
            if(!tile) cellReason="out_of_map";
            else if(allowed<=0) cellReason="animal_limit";
            else if(taken.count({x,y}) || taken.count({x,y+1})) cellReason="occupied";
            else if(!mBoard->canBuild(x,y,1,2,false,tile->cityId(),pid,true,true)) cellReason=tile->underBuilding()?"occupied":"blocked_terrain";
            if(cellReason.empty()) { --allowed; taken.insert({x,y}); taken.insert({x,y+1}); }
        } else if(cellReason.empty()) {
            if(!tile) cellReason="out_of_map";
            else {
                const auto cid=tile->cityId();
                if(mBoard->cityIdToPlayerId(cid)!=pid) cellReason="not_owned";
                for(int dy=0;dy<spec.h && cellReason.empty();++dy) for(int dx=0;dx<spec.w && cellReason.empty();++dx) {
                    const int tx=cell.first+dx, ty=cell.second+dy;
                    const auto t=inside(tx,ty)?mBoard->tile(tx,ty):nullptr;
                    if(!t) cellReason="out_of_map";
                    else if(t->cityId()!=cid) cellReason="other_district";
                    else if(t->underBuilding()) cellReason="occupied";
                    else if(t->isElevationTile()) cellReason="needs_flat_ground";
                    else if(!mBoard->canBuildBase(tx,tx+1,ty,ty+1,false,cid,pid,spec.fertile,spec.flat)) cellReason="blocked_terrain";
                }
                // The native rule: building goes on while the treasury is no more than 1000 drachmas in debt.
                if(cellReason.empty() && fundsEachTile(name) && treasury<-1000) cellReason="insufficient_funds";
            }
        }
        if(cellReason.empty()) { treasury-=unit; ++fresh; } else { complete=false; if(reason.empty()) reason=cellReason; }
        if(index++<listed) {
            if(!first) out << ','; first=false;
            out << '[' << cell.first << ',' << cell.second << ',' << (tile?tile->doubleAltitude():0) << ',' << (cellReason.empty()?"true":"false") << ',' << quote(cellReason) << ']';
        }
    }
    if(reason.empty() && fresh==0) reason="nothing_to_build";
    std::ostringstream result;
    result << "{\"kind\":\"area_plan\",\"tool\":" << quote(name) << ",\"asset\":" << quote(spec.asset) << ",\"w\":" << spec.w << ",\"h\":" << spec.h << ",\"unit_cost\":" << unit
           << ",\"cost\":" << fresh*unit << ",\"new\":" << fresh << ",\"count\":" << cells.size() << ",\"valid\":" << (fresh>0?"true":"false")
           << ",\"complete\":" << (complete?"true":"false") << ",\"reason\":" << quote(reason) << ",\"truncated\":" << (cells.size()>listed?"true":"false")
           << ",\"tiles\":[" << out.str() << "]}";
    return result.str();
}
// Columns, avenues and boulevards are dragged along a path as the SDL view lays them: the path from the tile under the
// pointer (x2, y2) back to where the drag began (x1, y1), found by the SDL rules (columns over free ground or columns, avenues
// over buildable ground and streets), then built tile by tile; an avenue also lays the street beside each median tile (a
// boulevard both). With `build` false it answers the plan (as `preview_road` does); built, it answers "" or an error.
std::string eSimulationService::pathCommand(const std::string& name,const int x1,const int y1,const int x2,const int y2,const bool build) {
    mBoard->waitUntilFinished();
    const auto found=buildSpecs.find(name);
    if(found==buildSpecs.end() || found->second.kind!=Kind::path) return "{\"error\":\"unsupported_build\"}";
    const auto& spec=found->second;
    const auto inside=[&](int x,int y) { return x>=mX && y>=mY && x<mX+mW && y<mY+mH; };
    const auto start=inside(x1,y1)?mBoard->tile(x1,y1):nullptr, hover=inside(x2,y2)?mBoard->tile(x2,y2):nullptr;
    if(!start || !hover) return "{\"error\":\"out_of_map\"}";
    const auto pid=mBoard->personPlayer(); const auto cid=start->cityId();
    std::string reason;
    if(mBlocked) reason="pending_decision";
    else if(mBoard->cityIdToPlayerId(cid)!=pid) reason="not_owned";
    else if(!mBoard->supportsBuilding(cid,spec.mode)) reason="building_not_available";
    else if(mBoard->drachmas(pid)<-1000) reason="insufficient_funds";
    const bool column=spec.type==eBuildingType::doricColumn || spec.type==eBuildingType::ionicColumn || spec.type==eBuildingType::corinthianColumn;
    const bool boulevard=spec.type==eBuildingType::boulevard;
    std::vector<eOrientation> path;
    const bool pathFound=column?eBuildPlacement::columnPath(*mBoard,x2,y2,x1,y1,path):eBuildPlacement::roadPath(*mBoard,x2,y2,x1,y1,false,path);
    const auto diff=mBoard->difficulty(pid);
    const int unit=eDifficultyHelpers::buildingCost(diff,spec.type), roadUnit=eDifficultyHelpers::buildingCost(diff,eBuildingType::road);
    if(build) {
        if(!reason.empty()) return "{\"error\":"+quote(reason)+"}";
        const int before=mBoard->drachmas(pid);
        mBoard->startRecordingBuilt();
        bool built=false;
        if(column) {
            for(auto* tile:eBuildPlacement::pathTiles(hover,path,pathFound)) {
                eGameBoard::eBuildingCreator factory=[&]() { return spec.make(*mBoard,cid); };
                built=mBoard->buildBase(tile->x(),tile->y(),tile->x(),tile->y(),factory,pid,cid,false,false,false) || built;
            }
        } else {
            built=eBuildPlacement::buildAvenue(*mBoard,eBuildPlacement::avenuePlan(hover,path,pathFound),boulevard,cid,pid,false);
        }
        int erased=0; const auto created=mBoard->stopRecordingBuilt(erased);
        if(!built) return "{\"error\":\"native_placement_rejected\"}";
        eSounds::playPlaceBuildingSound();
        // One undo step covers the whole drag; an avenue that replaced streets is not undoable.
        mUndoBuildings.clear();
        for(auto b:created) mUndoBuildings.emplace_back(b);
        mUndoRefund=std::max(0,before-mBoard->drachmas(pid));
        mUndoGameTime=mBoard->totalTime(); mUndoRealTime=std::chrono::steady_clock::now();
        if(erased) mUndoBuildings.clear();
        return "";
    }
    // The plan: each tile with its verdict and whether it is there already (a column, or the avenue's median or street).
    std::ostringstream cells; bool first=true; int fresh=0, freshRoads=0, existing=0;
    std::set<const eTile*> listed;
    const auto cell=[&](eTile* tile,std::string why,bool old,bool road) {
        if(!tile || !listed.insert(tile).second) return;
        if(!reason.empty()) why=reason;
        if(old) ++existing; else if(why.empty()) { if(road) ++freshRoads; else ++fresh; }
        if(!first) cells << ','; first=false;
        cells << '[' << tile->x() << ',' << tile->y() << ',' << tile->doubleAltitude() << ',' << (why.empty()?"true":"false") << ',' << quote(why) << ',' << (old?1:0) << ']';
    };
    const auto groundReason=[&](eTile* tile) -> std::string {
        if(tile->cityId()!=cid) return "other_district";
        if(tile->underBuilding()) return "occupied";
        if(tile->isElevationTile()) return "needs_flat_ground";
        if(!mBoard->canBuildBase(tile->x(),tile->x()+1,tile->y(),tile->y()+1,false,cid,pid)) return "blocked_terrain";
        return "";
    };
    if(column) {
        for(auto* tile:eBuildPlacement::pathTiles(hover,path,pathFound)) {
            const bool old=tile->underBuildingType()==spec.type;
            cell(tile,old?"":groundReason(tile),old,false);
        }
    } else {
        const auto plan=eBuildPlacement::avenuePlan(hover,path,pathFound);
        for(auto* tile:plan.fMedians) {
            if(!tile) continue;
            const bool old=tile->underBuildingType()==spec.type;
            cell(tile,old || eBuildPlacement::canBuildAvenueMedian(*mBoard,tile,boulevard,cid,pid,false)?"":(tile->underBuilding()?"occupied":"blocked_terrain"),old,false);
            for(auto* flank:eBuildPlacement::avenueFlanks(plan,tile,boulevard)) {
                if(!flank) continue;
                const auto bt=flank->underBuildingType();
                const bool street=bt==eBuildingType::road || bt==eBuildingType::avenue || bt==eBuildingType::boulevard;
                if(street) { cell(flank,"",true,true); continue; }
                // A flank that cannot take a street is simply left as it is, as in the SDL view: listed, but not counted against the plan.
                if(eBuildPlacement::canBuildAvenueFlank(*mBoard,flank,cid,pid,false)) cell(flank,"",false,true);
            }
        }
    }
    if(reason.empty() && fresh==0 && freshRoads==0) reason=existing?"nothing_to_build":"blocked_terrain";
    const int total=fresh*unit+freshRoads*roadUnit;
    std::ostringstream out;
    out << "{\"kind\":\"road_path\",\"tool\":" << quote(name) << ",\"x1\":" << x1 << ",\"y1\":" << y1 << ",\"x2\":" << x2 << ",\"y2\":" << y2
        << ",\"path_found\":" << (pathFound?"true":"false") << ",\"unit_cost\":" << unit << ",\"cost\":" << total
        << ",\"new\":" << fresh+freshRoads << ",\"existing\":" << existing << ",\"valid\":" << (reason.empty() && fresh+freshRoads>0?"true":"false")
        << ",\"complete\":" << (reason.empty()?"true":"false") << ",\"reason\":" << quote(reason) << ",\"asset\":" << quote(spec.asset) << ",\"tiles\":[" << cells.str() << "]}";
    return out.str();
}
// The tiles a wall drag covers, in the SDL order (columns, then rows): the outline of the rectangle between the two
// tiles, or all of it when `fill` is set. Tiles off the map are left out.
std::vector<eTile*> eSimulationService::wallTiles(const int x1,const int y1,const int x2,const int y2,const bool fill) {
    std::vector<eTile*> tiles;
    const int minX=std::min(x1,x2), maxX=std::max(x1,x2), minY=std::min(y1,y2), maxY=std::max(y1,y2);
    for(int x=std::max(minX,mX);x<=std::min(maxX,mX+mW-1);++x) {
        for(int y=std::max(minY,mY);y<=std::min(maxY,mY+mH-1);++y) {
            if(!fill && x!=minX && x!=maxX && y!=minY && y!=maxY) continue;
            if(const auto tile=mBoard->tile(x,y)) tiles.push_back(tile);
        }
    }
    return tiles;
}
std::string eSimulationService::wallPreview(const int x1,const int y1,const int x2,const int y2,const bool fill) {
    mBoard->waitUntilFinished();
    const auto pid=mBoard->personPlayer();
    const auto startTile=(x1>=mX && y1>=mY && x1<mX+mW && y1<mY+mH)?mBoard->tile(x1,y1):nullptr;
    if(!startTile) return "{\"error\":\"out_of_map\"}";
    const auto tiles=wallTiles(x1,y1,x2,y2,fill);
    const int unit=eDifficultyHelpers::buildingCost(mBoard->difficulty(pid),eBuildingType::wall);
    std::string reason;
    if(mBlocked) reason="pending_decision";
    else if(!mBoard->supportsBuilding(startTile->cityId(),eBuildingMode::wall)) reason="building_not_available";
    // First the verdict for every tile, then the pieces' connections: a wall joins its neighbours, planned ones included.
    int treasury=mBoard->drachmas(pid), fresh=0;
    std::vector<std::string> why(tiles.size());
    std::set<std::pair<int,int>> planned;
    for(size_t i=0;i<tiles.size();++i) {
        const auto tile=tiles[i]; const auto cid=tile->cityId();
        std::string cell=reason;
        if(cell.empty()) {
            if(mBoard->cityIdToPlayerId(cid)!=pid) cell="not_owned";
            else if(tile->underBuilding()) cell="occupied";
            else if(tile->isElevationTile()) cell="needs_flat_ground";
            else if(!mBoard->canBuildBase(tile->x(),tile->x()+1,tile->y(),tile->y()+1,false,cid,pid)) cell="blocked_terrain";
            // The native rule: a wall is built while the treasury is no more than 1000 drachmas in debt.
            else if(treasury<-1000) cell="insufficient_funds";
        }
        if(cell.empty()) { treasury-=unit; ++fresh; planned.insert({tile->x(),tile->y()}); }
        why[i]=cell;
    }
    const auto joins=[&](const int x,const int y) {
        if(planned.count({x,y})) return true;
        if(x<mX || y<mY || x>=mX+mW || y>=mY+mH) return false;
        const auto tile=mBoard->tile(x,y); const auto b=tile?tile->underBuilding():nullptr;
        if(!b) return false;
        const auto kind=b->type();
        return kind==eBuildingType::wall || kind==eBuildingType::tower || kind==eBuildingType::gatehouse;
    };
    constexpr size_t listed=3000;
    std::ostringstream cells; bool first=true; bool complete=!tiles.empty();
    for(size_t i=0;i<tiles.size();++i) {
        const auto tile=tiles[i];
        if(!why[i].empty()) { complete=false; if(reason.empty()) reason=why[i]; }
        if(i>=listed) continue;
        const int x=tile->x(), y=tile->y();
        const int mask=(joins(x-1,y)?1:0)|(joins(x+1,y)?2:0)|(joins(x,y-1)?4:0)|(joins(x,y+1)?8:0);
        if(!first) cells << ','; first=false;
        cells << '[' << x << ',' << y << ',' << tile->doubleAltitude() << ',' << (why[i].empty()?"true":"false")
              << ',' << quote(why[i]) << ',' << mask << ']';
    }
    if(reason.empty() && fresh==0) reason="nothing_to_build";
    std::ostringstream out;
    out << "{\"kind\":\"wall_path\",\"x1\":" << x1 << ",\"y1\":" << y1 << ",\"x2\":" << x2 << ",\"y2\":" << y2
        << ",\"fill\":" << (fill?"true":"false") << ",\"unit_cost\":" << unit << ",\"cost\":" << fresh*unit
        << ",\"new\":" << fresh << ",\"valid\":" << (fresh>0?"true":"false") << ",\"complete\":" << (complete?"true":"false")
        << ",\"reason\":" << quote(reason) << ",\"truncated\":" << (tiles.size()>listed?"true":"false")
        << ",\"tiles\":[" << cells.str() << "]}";
    return out.str();
}
// One tile of a gatehouse. The passage is road: an ordinary street may carry it, but a street that already belongs to an
// agora, a gatehouse or a hippodrome (or an avenue) may not; every other tile needs free building ground.
std::string eSimulationService::gateReason(const int x,const int y,const bool road,const eCityId cid,const ePlayerId pid) {
    const auto tile=(x>=mX && y>=mY && x<mX+mW && y<mY+mH)?mBoard->tile(x,y):nullptr;
    if(!tile) return "out_of_map";
    if(tile->cityId()!=cid) return "other_district";
    if(road && tile->hasRoad()) {
        const auto b=tile->underBuilding();
        if(b->type()!=eBuildingType::road) return "occupied";
        const auto street=static_cast<eRoad*>(b);
        return (street->underAgora() || street->underGatehouse() || street->aboveHippodrome())?"occupied":"";
    }
    if(tile->underBuilding()) return "occupied";
    if(!mBoard->canBuildBase(x,x+1,y,y+1,false,cid,pid)) return "blocked_terrain";
    return "";
}
// The world screen's rules, as the SDL world menu and its dialogs apply them. What may be done with a city:
//  - ask for goods, give a gift, fulfil its requests: not for a distant city, the city being played, a colony on the board or a neutral
//    city on the board;
//  - raid and conquer need an army, which the embedded core cannot command yet, so they are reported as unavailable.
// Asking is refused while the city's regard is 50 or less (unless it is a rival, which can be made to give).
namespace {
std::string worldImage(const eWorldMap map) {
    const int n=int(map);
    char name[40];
    if(n<=int(eWorldMap::greece8)) std::snprintf(name,sizeof(name),"Zeus_MapOfGreece%02d.JPG",n+1);
    else std::snprintf(name,sizeof(name),"Poseidon_map%02d.jpg",n-int(eWorldMap::poseidon1)+1);
    return name;
}
const char* worldTypeKey(const eCityType type) {
    switch(type) {
    case eCityType::parentCity: return "parent";
    case eCityType::colony: return "colony";
    case eCityType::foreignCity: return "foreign";
    case eCityType::distantCity: return "distant";
    case eCityType::enchantedPlace: return "place";
    case eCityType::destroyedCity: return "ruins";
    }
    return "foreign";
}
const char* worldRelationKey(const eForeignCityRelationship rel) {
    switch(rel) {
    case eForeignCityRelationship::vassal: return "vassal";
    case eForeignCityRelationship::ally: return "ally";
    case eForeignCityRelationship::rival: return "rival";
    }
    return "ally";
}
}
namespace {
// The military buttons of the SDL world menu (eWorldMenu::updateButtonsEnabled) and the aid and strike offers of its request dialog.
struct eMilitaryFlags { bool raid=false, conquer=false, reinforce=false; std::string aid; };
eMilitaryFlags militaryFlags(eGameBoard& board,const stdsptr<eWorldCity>& city,const ePlayerId pid) {
    eMilitaryFlags flags;
    const auto type=city->type(); const bool current=city->isCurrentCity(), distant=type==eCityType::distantCity;
    const bool boardColony=city->isOnBoardColony(), boardNeutral=city->isOnBoardNeutral();
    const bool dealings=!distant && !current && !boardColony && !boardNeutral;
    const bool ownColony=boardColony && city->playerId()==pid, boardEnemyColony=boardColony && !ownColony;
    const auto relation=city->relationship();
    const bool vassalOrColony=(type==eCityType::foreignCity && relation==eForeignCityRelationship::vassal) || type==eCityType::colony;
    flags.raid=!vassalOrColony && !distant && !current && !city->isOnBoard();
    flags.reinforce=board.personPlayerCitiesOnBoard().size()>1 && (ownColony || current);
    flags.conquer=flags.reinforce || ((!vassalOrColony || city->conqueredByRival() || boardEnemyColony) && !distant && !current && !ownColony && !boardNeutral);
    if(dealings && !city->isRival()) {
        const int attitude=int(std::lround(city->attitude(pid)));
        if(attitude<=65) flags.aid="not_regarded"; else if(city->shields()<2) flags.aid="cant_spare";
        else if(board.militaryAid(board.currentCityId(),city)) flags.aid="present"; else flags.aid="ok";
    }
    return flags;
}
}
stdsptr<eWorldCity> eSimulationService::worldCity(const int index) const {
    if(!mBoard) return nullptr;
    const auto& cities=mBoard->world().cities();
    return index>=0 && index<int(cities.size())?cities[index]:nullptr;
}
std::string eSimulationService::worldInfo() {
    if(!mBoard) return "{\"error\":\"city_not_loaded\"}";
    mBoard->waitUntilFinished();
    const auto& world=mBoard->world();
    const auto pid=mBoard->personPlayer();
    const auto mine=mBoard->personPlayerCitiesOnBoard();
    const auto goods=[&](const std::vector<eResourceTrade>& list) {
        std::ostringstream out; out << '['; bool first=true;
        for(const auto& trade:list) {
            if(!first) out << ','; first=false;
            out << "{\"resource\":" << int(trade.fType) << ",\"name\":" << quote(eResourceTypeHelpers::typeName(trade.fType))
                << ",\"price\":" << mBoard->price(trade.fType) << ",\"used\":" << trade.used(pid) << ",\"max\":" << trade.fMax << '}';
        }
        out << ']'; return out.str();
    };
    std::ostringstream out;
    out << "{\"kind\":\"world\",\"map\":" << int(world.map()) << ",\"image\":" << quote(worldImage(world.map()))
        << ",\"treasury\":" << mBoard->drachmas(pid) << ",\"mine\":[";
    // The gifts the player could make from each of its cities: every basic good and drachmas has a base size (small, twice, three times).
    const auto giftable=eResourceTypeHelpers::extractResourceTypes(eResourceType::allBasic | eResourceType::drachmas);
    bool first=true;
    for(const auto cid:mine) {
        if(!first) out << ','; first=false;
        out << "{\"id\":" << int(cid) << ",\"name\":" << quote(mBoard->cityName(cid)) << ",\"current\":" << (cid==mBoard->currentCityId()?"true":"false") << ",\"stock\":[";
        bool firstStock=true;
        for(const auto resource:giftable) {
            const int step=eGiftHelpers::giftCount(resource);
            if(step<=0) continue;
            if(!firstStock) out << ','; firstStock=false;
            out << "{\"resource\":" << int(resource) << ",\"name\":" << quote(eResourceTypeHelpers::typeName(resource))
                << ",\"count\":" << mBoard->resourceCount(cid,resource) << ",\"step\":" << step << '}';
        }
        out << "]}";
    }
    out << "],\"regions\":[";
    first=true;
    for(const auto& region:world.regions()) {
        if(!first) out << ','; first=false;
        out << "{\"name\":" << quote(region.getName()) << ",\"x\":" << region.fX << ",\"y\":" << region.fY << '}';
    }
    out << "],\"cities\":[";
    first=true; int index=-1;
    for(const auto& city:world.cities()) {
        ++index;
        if(!city->visible()) continue;
        if(!city->active() && !city->isOnBoard()) continue;
        const auto type=city->type();
        const bool current=city->isCurrentCity();
        const bool distant=type==eCityType::distantCity;
        const bool boardColony=city->isOnBoardColony(), boardNeutral=city->isOnBoardNeutral();
        const bool dealings=!distant && !current && !boardColony && !boardNeutral;
        const bool ownColony=boardColony && city->playerId()==pid;
        const int attitude=int(std::lround(city->attitude(pid)));
        const bool regarded=attitude>50 || city->isRival();
        const auto military=militaryFlags(*mBoard,city,pid);
        const bool canRaid=military.raid, canConquer=military.conquer, reinforce=military.reinforce; const std::string& aid=military.aid;
        if(!first) out << ','; first=false;
        out << "{\"index\":" << index << ",\"id\":" << int(city->cityId()) << ",\"name\":" << quote(city->name()) << ",\"leader\":" << quote(city->leader())
            << ",\"type\":" << quote(worldTypeKey(type)) << ",\"nationality\":" << quote(eWorldCity::sNationalityName(city->nationality()))
            << ",\"nation\":" << int(city->nationality()) << ",\"relationship\":" << quote(type==eCityType::foreignCity?worldRelationKey(city->relationship()):"")
            << ",\"direction\":" << int(city->direction()) << ",\"x\":" << city->x() << ",\"y\":" << city->y()
            << ",\"active\":" << (city->active()?"true":"false") << ",\"current\":" << (current?"true":"false") << ",\"on_board\":" << (city->isOnBoard()?"true":"false")
            << ",\"mine\":" << (ownColony || current || mBoard->cityIdToPlayerId(city->cityId())==pid?"true":"false")
            << ",\"attitude\":" << attitude << ",\"attitude_name\":" << quote(current||boardColony||boardNeutral?std::string():eWorldCity::sAttitudeName(city->attitudeClass(pid)))
            << ",\"sells\":" << goods(city->sells()) << ",\"buys\":" << goods(city->buys())
            << ",\"tribute\":{\"resource\":" << int(city->tributeType()) << ",\"name\":" << quote(eResourceTypeHelpers::typeName(city->tributeType())) << ",\"count\":" << city->tributeCount() << '}'
            << ",\"can_request\":" << (dealings?"true":"false") << ",\"regarded\":" << (regarded?"true":"false") << ",\"can_gift\":" << (dealings?"true":"false")
            << ",\"can_fulfil\":" << (dealings?"true":"false") << ",\"military\":" << (canRaid||canConquer?"true":"false")
            << ",\"can_raid\":" << (canRaid?"true":"false") << ",\"can_conquer\":" << (canConquer?"true":"false") << ",\"reinforce\":" << (reinforce?"true":"false")
            << ",\"aid\":" << quote(aid) << ",\"troops\":" << city->troops() << ",\"shields\":" << city->shields() << '}';
    }
    out << "],\"requests\":[";
    first=true; int requestId=0;
    const auto requests=mBoard->cityRequests(pid);
    for(const auto* request:requests) {
        const auto& city=request->city();
        int cityIndex=-1, i=0;
        for(const auto& candidate:world.cities()) { if(candidate==city) cityIndex=i; ++i; }
        if(!first) out << ','; first=false;
        out << "{\"id\":" << requestId++ << ",\"city\":" << cityIndex << ",\"resource\":" << int(request->resourceType()) << ",\"name\":" << quote(eResourceTypeHelpers::typeName(request->resourceType()))
            << ",\"count\":" << request->count() << ",\"from\":[";
        bool firstFrom=true;
        for(const auto cid:mine) {
            if(mBoard->resourceCount(cid,request->resourceType())<request->count()) continue;
            if(!firstFrom) out << ','; firstFrom=false; out << int(cid);
        }
        out << "]}";
    }
    // The gods' quests: a hero to send (`ready` once his hall has seen him arrive, `hall` whether the city has the hall at all).
    out << "],\"quests\":[";
    first=true; { int questId=0;
        for(const auto* quest:mBoard->godQuests(pid)) {
            const auto asked=quest->godQuest(); eHerosHall* hall=nullptr;
            for(const auto cid:mine) { hall=mBoard->heroHall(cid,asked.fHero); if(hall) break; }
            if(!first) out << ','; first=false;
            out << "{\"id\":" << questId++ << ",\"god\":" << int(asked.fGod) << ",\"god_name\":" << quote(eGod::sGodName(asked.fGod)) << ",\"hero\":" << int(asked.fHero)
                << ",\"hero_name\":" << quote(eHero::sHeroName(asked.fHero)) << ",\"name\":" << quote(asked.name())
                << ",\"hall\":" << (hall?"true":"false") << ",\"ready\":" << (hall && hall->stage()==eHeroSummoningStage::arrived?"true":"false") << '}';
        } }
    out << "],\"troop_requests\":" << mBoard->cityTroopsRequests(pid).size() << ",\"rivals\":[";
    first=true; { int candidateIndex=-1; for(const auto& candidate:world.cities()) { ++candidateIndex; if(!candidate->visible() || !candidate->isRival()) continue; if(!first) out << ','; first=false; out << candidateIndex; } }
    out << "],\"armies\":" << armiesJson() << ",\"enlisting\":" << (mEnlist?"true":"false") << '}';
    return out.str();
}
// A trade post's own panel: the partner, what it can import (the partner sells) and export (the partner buys), each good's
// price, the post's stock, whether it is traded and the stock level to keep; and the year's quota already used.

namespace {
// The simulation step clears finished path tasks and discarded characters every tick. An order that arrives between two ticks does
// the same first: a soldier sent home straight after being called out is a tile-less husk until then, and calling the company out
// again would walk it into a null tile.
void settle(eGameBoard& board) {
    board.waitUntilFinished();
    board.handleFinishedTasks();
    board.emptyRubbish();
}
const char* bannerKind(eBannerType type) {
    switch(type) {
    case eBannerType::hoplite: return "hoplite";
    case eBannerType::horseman: return "horseman";
    case eBannerType::rockThrower: return "rock_thrower";
    case eBannerType::amazon: return "amazon";
    case eBannerType::aresWarrior: return "ares_warrior";
    case eBannerType::enemy: return "enemy";
    case eBannerType::trireme: return "trireme";
    }
    return "enemy";
}
}
// The banners of the player's cities on this board, in the order their cities list them.
std::string eSimulationService::bannersJson() {
    std::ostringstream out; out << '['; bool first=true;
    for(const auto cid:mBoard->personPlayerCitiesOnBoard()) {
        for(const auto& b:mBoard->banners(cid)) {
            const auto type=b->type(); const auto tile=b->tile();
            if(!first) out << ','; first=false;
            out << "{\"id\":" << b->id() << ",\"city\":" << int(cid) << ",\"type\":\"" << bannerKind(type) << "\",\"name\":" << quote(b->name())
                << ",\"kind_name\":" << quote(eSoldierBanner::sName(type,b->atlantean())) << ",\"count\":" << b->count()
                << ",\"placed\":" << (tile?"true":"false") << ",\"x\":" << (tile?tile->x():0) << ",\"y\":" << (tile?tile->y():0)
                << ",\"home\":" << (b->isHome()?"true":"false") << ",\"abroad\":" << (b->isAbroad()?"true":"false")
                << ",\"aid\":" << (b->militaryAid()?"true":"false") << ",\"fighting\":" << (b->fighting()?"true":"false")
                << ",\"atlantean\":" << (b->atlantean()?"true":"false") << '}';
        }
    }
    out << ']'; return out.str();
}
eSoldierBanner* eSimulationService::playerBanner(const int id) const {
    if(!mBoard) return nullptr;
    for(const auto cid:mBoard->personPlayerCitiesOnBoard())
        for(const auto& b:mBoard->banners(cid)) if(b->id()==id) return b.get();
    return nullptr;
}
// Soldiers of an enemy team standing in the player's cities (the invaders), alive; `at` is the tile of the invader nearest their middle.
int eSimulationService::invaderCount(int* atX,int* atY) const {
    int count=0; long sumX=0,sumY=0; const auto ptid=mBoard->playerIdToTeamId(mBoard->personPlayer());
    std::vector<eTile*> tiles;
    for(const auto c:mBoard->characters()) {
        const auto soldier=dynamic_cast<eSoldier*>(c);
        if(!soldier || soldier->dead() || !soldier->tile()) continue;
        const auto banner=soldier->banner();
        if(banner && banner->type()==eBannerType::enemy && eTeamIdHelpers::isEnemy(soldier->teamId(),ptid)) {
            ++count; tiles.push_back(soldier->tile()); sumX+=soldier->tile()->x(); sumY+=soldier->tile()->y();
        }
    }
    if(count>0 && atX && atY) {
        const double mx=double(sumX)/count,my=double(sumY)/count; double best=1e18; eTile* nearest=tiles[0];
        for(const auto t:tiles) { const double d=(t->x()-mx)*(t->x()-mx)+(t->y()-my)*(t->y()-my); if(d<best) { best=d; nearest=t; } }
        *atX=nearest->x(); *atY=nearest->y();
    }
    return count;
}
int eSimulationService::monsterCount(int* atX,int* atY,std::string* name) const {
    int count=0;
    for(const auto m:mBoard->monsters(mBoard->currentCityId())) {
        if(!m || m->dead() || !m->tile()) continue;
        if(count==0) {
            if(atX) *atX=m->tile()->x();
            if(atY) *atY=m->tile()->y();
            if(name) *name=eMonster::sMonsterName(eMonster::sCharacterToMonsterType(m->type()));
        }
        ++count;
    }
    return count;
}
std::string eSimulationService::armyInfo() {
    if(!mBoard) return "{\"error\":\"city_not_loaded\"}";
    mBoard->waitUntilFinished();
    const auto cid=mBoard->currentCityId(); const auto city=mBoard->boardCityWithId(cid);
    std::ostringstream out; out << "{\"kind\":\"army\",\"city\":" << int(cid) << ",\"palace\":" << (city&&city->hasPalace()?"true":"false")
        << ",\"capacity\":" << (city?city->maxPalaceBannerCount():0) << ",\"per_banner\":" << eNumbers::sSoldiersPerBanner
        << ",\"hoplites\":" << mBoard->countSoldiers(eBannerType::hoplite,cid) << ",\"horsemen\":" << mBoard->countSoldiers(eBannerType::horseman,cid)
        << ",\"rabble\":" << mBoard->countSoldiers(eBannerType::rockThrower,cid)
        << ",\"invasion\":" << (mBoard->hasActiveInvasions(cid)?"true":"false") << ",\"invaders\":" << invaderCount()
        << ",\"monsters\":" << monsterCount() << ",\"banners\":" << bannersJson() << '}';
    return out.str();
}

int eSimulationService::worldIndex(const stdsptr<eWorldCity>& city) const {
    int index=0;
    for(const auto& candidate:mBoard->world().cities()) { if(candidate==city) return index; ++index; }
    return -1;
}
// The armies on their way (the SDL map draws them as they travel): raids and conquests out, help out, armies home; `frac` is how far they are.
std::string eSimulationService::armiesJson() {
    const auto& world=mBoard->world(); const auto date=mBoard->date();
    std::ostringstream out; out << '['; bool first=true;
    const auto emit=[&](const char* reason,const stdsptr<eWorldCity>& from,const stdsptr<eWorldCity>& to,const stdsptr<eWorldCity>& origin,double frac,int size,const std::vector<eHeroType>& heroes) {
        if(!first) out << ','; first=false;
        out << "{\"reason\":\"" << reason << "\",\"from\":" << worldIndex(from) << ",\"to\":" << worldIndex(to) << ",\"origin\":" << worldIndex(origin) << ",\"frac\":" << frac << ",\"size\":" << size << ",\"heroes\":[";
        bool firstHero=true; for(const auto hero:heroes) { if(!firstHero) out << ','; firstHero=false; out << int(hero); }
        out << "]}";
    };
    for(const auto e:mBoard->armyEvents()) {
        const auto& forces=e->forces(); const auto split=forces.splitIntoCities();
        const bool reinforcement=dynamic_cast<eReinforcementsEvent*>(e)!=nullptr, home=dynamic_cast<eArmyReturnEvent*>(e)!=nullptr;
        const char* reason="conquest";
        if(home) reason="home"; else if(dynamic_cast<ePlayerRaidEvent*>(e)) reason="raid"; else if(dynamic_cast<eTroopsRequestFulfilledEvent*>(e)) reason="help";
        const int days=e->nextDate()-date, total=reinforcement?eNumbers::sReinforcementsTravelTime:eNumbers::sArmyTravelTime;
        const double frac=std::clamp(1.-(1.*days)/total,0.,1.);
        stdsptr<eWorldCity> toCity;
        if(reinforcement) { reason="help"; toCity=world.cityWithId(e->cityId()); } else toCity=e->city();
        for(const auto& part:split) {
            const auto from=world.cityWithId(part.first); const int size=part.second.fSoldiers.empty()?0:1+std::clamp(int(part.second.fSoldiers.size())/3,0,2);
            std::vector<eHeroType> heroes; for(const auto& hero:part.second.fHeroes) heroes.push_back(hero.second);
            if(home) emit(reason,toCity,from,from,frac,size,heroes); else emit(reason,from,toCity,from,frac,size,heroes);
        }
        for(const auto& ally:forces.fAllies) { if(home) emit(reason,toCity,ally,ally,frac,2,{}); else emit(reason,ally,toCity,ally,frac,2,{}); }
    }
    out << ']'; return out.str();
}
// What may be enlisted for the dealing now waiting, and the plunder a raid may ask for.
std::string eSimulationService::enlistInfo() {
    if(!mEnlist) return "{\"error\":\"no_enlistment\"}";
    const auto& session=*mEnlist;
    std::ostringstream out; out << "{\"kind\":\"enlist\",\"purpose\":" << quote(session.purpose) << ",\"city\":" << session.city << ",\"event\":" << session.event << ",\"cities\":[";
    for(size_t i=0;i<session.cids.size();++i) { if(i) out << ','; out << "{\"id\":" << int(session.cids[i]) << ",\"name\":" << quote(session.cnames[i]) << '}'; }
    out << "],\"soldiers\":[";
    bool first=true;
    for(const auto& banner:session.forces.fSoldiers) {
        if(!first) out << ','; first=false;
        out << "{\"id\":" << banner->id() << ",\"city\":" << int(banner->cityId()) << ",\"type\":\"" << bannerKind(banner->type()) << "\",\"name\":" << quote(banner->name())
            << ",\"kind_name\":" << quote(eSoldierBanner::sName(banner->type(),banner->atlantean())) << ",\"count\":" << banner->count() << ",\"abroad\":" << (banner->isAbroad()?"true":"false") << '}';
    }
    out << "],\"heroes\":[";
    first=true;
    for(const auto& hero:session.forces.fHeroes) {
        if(!first) out << ','; first=false;
        out << "{\"city\":" << int(hero.first) << ",\"hero\":" << int(hero.second) << ",\"name\":" << quote(eHero::sHeroName(hero.second)) << ",\"abroad\":"
            << (eVectorHelpers::contains(session.heroesAbroad,hero.second)?"true":"false") << '}';
    }
    out << "],\"allies\":[";
    first=true;
    for(const auto& ally:session.forces.fAllies) {
        if(!first) out << ','; first=false;
        out << "{\"index\":" << worldIndex(ally) << ",\"name\":" << quote(ally->name()) << ",\"troops\":" << ally->troops() << ",\"abroad\":" << (ally->abroad()?"true":"false") << '}';
    }
    out << "],\"plunder\":[";
    first=true;
    for(const auto resource:session.plunder) {
        if(!first) out << ','; first=false;
        out << "{\"resource\":" << (resource==eResourceType::none?-1:int(resource)) << ",\"name\":" << quote(resource==eResourceType::none?std::string():eResourceTypeHelpers::typeName(resource)) << '}';
    }
    out << "]";
    if(const auto target=worldCity(session.city)) out << ",\"target\":{\"index\":" << session.city << ",\"name\":" << quote(target->name()) << ",\"shields\":" << target->shields() << '}';
    out << '}'; return out.str();
}
std::string eSimulationService::tradeInfo(eTradePost* post) {
    const auto pid=mBoard->personPlayer();
    const auto& city=post->city();
    eResourceType imports,exports; post->getOrders(imports,exports);
    const bool twoWay=post->playerTwoWay();
    const auto row=[&](eResourceType resource,bool enabled,int used,int max) {
        const int step=resource==eResourceType::sculpture?1:4;
        const auto found=post->maxCount().find(resource);
        const int limit=found==post->maxCount().end()?step*post->spaceCount():found->second;
        std::ostringstream out;
        out << "{\"resource\":" << int(resource) << ",\"name\":" << quote(eResourceTypeHelpers::typeName(resource))
            << ",\"price\":" << mBoard->price(resource) << ",\"stock\":" << post->count(resource) << ",\"enabled\":" << (enabled?"true":"false")
            << ",\"quota\":" << limit << ",\"step\":" << step << ",\"max_quota\":" << step*post->spaceCount()
            << ",\"used\":" << used << ",\"max\":" << max << '}';
        return out.str();
    };
    std::ostringstream out;
    out << "{\"partner\":" << quote(city.name()) << ",\"water\":" << (post->tpType()==eTradePostType::pier?"true":"false")
        << ",\"two_way\":" << (twoWay?"true":"false") << ",\"trading\":" << (post->trades()?"true":"false") << ",\"imports\":[";
    bool first=true;
    if(!twoWay) for(const auto& trade:city.sells()) {
        if(!first) out << ','; first=false;
        out << row(trade.fType,static_cast<bool>(imports & trade.fType),trade.used(pid),trade.fMax);
    }
    out << "],\"exports\":["; first=true;
    if(twoWay) {
        // Trade with one's own colony: any good the city holds, or already exports.
        const auto home=mBoard->boardCityWithId(post->cityId());
        for(const auto resource:eResourceTypeHelpers::extractResourceTypes(eResourceType::allBasic)) {
            const bool on=static_cast<bool>(exports & resource);
            if(!home || (home->resourceCount(resource)<1 && !on)) continue;
            const int max=resource==eResourceType::sculpture?eNumbers::sTwoWayTradeMax:4*eNumbers::sTwoWayTradeMax;
            if(!first) out << ','; first=false;
            out << row(resource,on,home->exported(city.cityId(),resource),max);
        }
    } else for(const auto& trade:city.buys()) {
        if(!first) out << ','; first=false;
        out << row(trade.fType,static_cast<bool>(exports & trade.fType),trade.used(pid),trade.fMax);
    }
    out << "]}";
    return out.str();
}
std::string eSimulationService::inspect(int x,int y) {
    mBoard->waitUntilFinished();
    if(x<mX || y<mY || x>=mX+mW || y>=mY+mH) return "{\"error\":\"out_of_map\"}";
    const auto t=mBoard->tile(x,y);
    if(!t) return "{\"error\":\"out_of_map\"}";
    const auto b=t->underBuilding();
    if(mInspectionTarget.get()!=b) { mInspectionTarget=b; ++mInspectionToken; }
    std::ostringstream out;
    out << "{\"kind\":\"inspection\",\"x\":" << x << ",\"y\":" << y << ",\"altitude\":" << t->doubleAltitude()
        << ",\"city\":" << quote(mBoard->cityName(t->cityId())) << ",\"owned\":" << (mBoard->cityIdToPlayerId(t->cityId())==mBoard->personPlayer()?"true":"false");
    if(b) {
        std::string title,info,employment,additional;
        eBuilding::sInfoText(b,title,info,employment,additional);
        const auto r=b->tileRect();
        out << ",\"name\":" << quote(eBuilding::sNameForBuilding(b)) << ",\"info\":" << quote(info)
            << ",\"target_token\":" << mInspectionToken << ",\"type\":" << int(b->type())
            << ",\"can_edit\":" << (b->playerId()==mBoard->personPlayer() && !b->deleteScheduled() && !b->isOnFire() && !mBlocked?"true":"false")
            << ",\"employment_info\":" << quote(employment) << ",\"additional_info\":" << quote(additional)
            << ",\"footprint\":[" << r.x << ',' << r.y << ',' << r.w << ',' << r.h << ']'
            << ",\"maintenance\":" << b->maintenance() << ",\"enabled\":" << (b->enabled()?"true":"false")
            << ",\"on_fire\":" << (b->isOnFire()?"true":"false") << ",\"road_access\":" << (b->accessToRoad()?"true":"false");
        if(auto employer=dynamic_cast<eEmployingBuilding*>(b))
            out << ",\"employees\":" << employer->employed() << ",\"max_employees\":" << employer->maxEmployees()
                << ",\"shut_down\":" << (employer->shutDown()?"true":"false");
        if(auto storage=dynamic_cast<eStorageBuilding*>(b)) {
            int occupied=0;
            for(int i=0;i<storage->spaceCount();++i) if(storage->resourceCount(i)>0) ++occupied;
            out << ",\"storage\":{\"bays\":" << storage->spaceCount() << ",\"occupied_bays\":" << occupied << ",\"resources\":[";
            bool first=true;
            for(auto resource:eResourceTypeHelpers::extractResourceTypes(storage->canAccept())) {
                const int step=resource==eResourceType::sculpture?1:4;
                const auto found=storage->maxCount().find(resource);
                const int limit=found==storage->maxCount().end()?step*storage->spaceCount():found->second;
                const int order=storage->get(resource)?2:(storage->empties(resource)?3:(storage->accepts(resource)?1:0));
                if(!first) out << ','; first=false;
                out << "{\"resource\":" << int(resource) << ",\"name\":" << quote(eResourceTypeHelpers::typeName(resource))
                    << ",\"count\":" << storage->count(resource) << ",\"overflow\":" << storage->stashCount(resource)
                    << ",\"order\":" << order << ",\"limit\":" << limit << ",\"step\":" << step
                    << ",\"max_limit\":" << step*storage->spaceCount() << ",\"space_left\":" << storage->spaceLeft(resource) << '}';
            }
            out << "]}";
        }
        if(auto post=dynamic_cast<eTradePost*>(b)) out << ",\"trade\":" << tradeInfo(post);
        // The SDL inspector pages of the hippodrome (any of its plates) and of the trireme wharf, worded by engine/ebuildinginfotext;
        // the wharf has the SDL page's switch that shuts it down or sets it working.
        {
            std::vector<std::string> notes; std::string notesTitle;
            if(const auto piece=dynamic_cast<eHippodromePiece*>(b); piece && piece->hippodrome()) {
                const auto& h=*piece->hippodrome();
                notes=eBuildingInfoText::hippodrome(h); notesTitle=eLanguage::zeusText(167,0);
                out << ",\"hippodrome\":{\"closed\":" << (h.closed()?"true":"false") << ",\"length\":" << h.length() << ",\"racing\":" << (h.racing()?"true":"false")
                    << ",\"horses\":" << h.hasHorses() << ",\"needed\":" << h.neededHorses() << '}';
            } else if(const auto wharf=dynamic_cast<eTriremeWharf*>(b)) {
                notes=eBuildingInfoText::triremeWharf(*wharf);
                out << ",\"switch\":{\"working\":" << (wharf->shutDown()?"false":"true") << ",\"labels\":[" << quote(eBuildingInfoText::triremeWharfSwitch(false))
                    << ',' << quote(eBuildingInfoText::triremeWharfSwitch(true)) << "]}";
            }
            if(!notes.empty()) {
                out << ",\"notes_title\":" << quote(notesTitle) << ",\"notes\":[";
                for(size_t i=0;i<notes.size();++i) out << (i?",":"") << quote(notes[i]);
                out << ']';
            }
        }
        const auto industries=eIndustryHelpers::sIndustries(b->type());
        const auto producer=dynamic_cast<eResourceBuildingBase*>(b);
        if(producer || !industries.empty()) {
            auto outputs=industries;
            if(producer && producer->resourceType()!=eResourceType::none) outputs={producer->resourceType()};
            std::string status="operational";
            const auto employer=dynamic_cast<eEmployingBuilding*>(b);
            const auto processor=dynamic_cast<eProcessingBuilding*>(b);
            if(b->isOnFire()) status="on_fire";
            else if(employer && employer->shutDown()) status="industry_paused";
            else if(employer && employer->employed()==0) status="no_workers";
            else if(!b->accessToRoad()) status="no_road";
            else if(processor && processor->rawCount()<processor->rawUse()) status="waiting_input";
            else if(auto collector=dynamic_cast<eResourceCollectBuildingBase*>(b); collector && collector->noTarget()) status="no_target";
            else if(auto grower=dynamic_cast<eGrowersLodge*>(b); grower && grower->noTarget()) status="no_target";
            out << ",\"production\":{\"status\":" << quote(status) << ",\"outputs\":[";
            bool first=true;
            const auto goods=dynamic_cast<eBuildingWithResource*>(b);
            for(auto resource:outputs) {
                if(!first) out << ','; first=false;
                const int count=goods?goods->count(resource):0;
                out << "{\"resource\":" << int(resource) << ",\"count\":" << count
                    << ",\"capacity\":" << count+(goods?goods->spaceLeft(resource):0)
                    << ",\"overflow\":" << (goods?goods->stashCount(resource):0) << '}';
            }
            out << "],\"industries\":["; first=true;
            for(auto resource:industries) {
                if(!first) out << ','; first=false;
                out << "{\"resource\":" << int(resource) << ",\"shut_down\":" << (mBoard->isShutDown(b->cityId(),resource)?"true":"false") << '}';
            }
            out << ']';
            if(processor) out << ",\"input\":{\"resource\":" << int(processor->rawMaterial()) << ",\"count\":" << processor->rawCount()
                << ",\"capacity\":" << processor->maxRaw() << ",\"per_output\":" << processor->rawUse() << '}';
            out << '}';
        }
        if(auto hall=dynamic_cast<eHerosHall*>(b)) {
            // A hero's hall: what the hero asks of the city (each requirement with how far the city is from it, as the SDL
            // inspector lists them), the stage of the summoning and whether the hero is away on a quest.
            if(hall->stage()==eHeroSummoningStage::none) hall->updateRequirementsStatus();
            const auto city=mBoard->boardCityWithId(hall->cityId());
            int met=0; for(const auto& requirement:hall->requirements()) if(requirement.met()) ++met;
            const char* stage=hall->stage()==eHeroSummoningStage::none?"none":(hall->stage()==eHeroSummoningStage::summoned?"summoned":"arrived");
            out << ",\"hall\":{\"hero\":" << int(hall->heroType()) << ",\"hero_name\":" << quote(eHero::sHeroName(hall->heroType()))
                << ",\"stage\":\"" << stage << "\",\"on_quest\":" << (hall->heroOnQuest()?"true":"false")
                << ",\"can_summon\":" << (hall->stage()==eHeroSummoningStage::none && met==int(hall->requirements().size()) && !hall->requirements().empty()
                                          && b->playerId()==mBoard->personPlayer() && !mBlocked?"true":"false") << ",\"requirements\":[";
            bool firstRequirement=true;
            for(const auto& requirement:hall->requirements()) {
                if(!firstRequirement) out << ','; firstRequirement=false;
                out << "{\"text\":" << quote(city?eHerosHall::sHeroRequirementText(requirement,*city):std::string())
                    << ",\"status\":" << quote(city?eHerosHall::sHeroRequirementStatusText(requirement,*city):std::string())
                    << ",\"met\":" << (requirement.met()?"true":"false") << '}';
            }
            out << "]}";
        }
        {
            // A sanctuary's pieces are inspected as the sanctuary: the monument they belong to.
            eMonument* monument=dynamic_cast<eMonument*>(b);
            if(!monument) if(const auto piece=dynamic_cast<eSanctBuilding*>(b)) monument=piece->monument();
            if(monument) out << ",\"monument\":" << monumentInfo(monument)
                             << ",\"can_control\":" << (monument->playerId()==mBoard->personPlayer() && !mBlocked?"true":"false");
        }
        if(auto house=dynamic_cast<eHouseBase*>(b)) {
            const bool elite=eHouseNeeds::elite(house); const int supported=eHouseNeeds::supportedLevel(house);
            const int target=supported<house->level()?house->level():std::min(house->level()+1,eHouseNeeds::maxLevel(elite));
            const auto missing=eHouseNeeds::missing(eHouseNeeds::needs(elite,target),eHouseNeeds::has(house));
            out << ",\"residents\":" << house->people() << ",\"capacity\":" << house->people()+house->vacancies()
                << ",\"level\":" << house->level() << ",\"supported_level\":" << supported << ",\"target_level\":" << target << ",\"missing\":[";
            bool first=true; for(auto need:missing) { if(!first) out << ','; first=false; out << int(need); } out << ']';
        }
    }
    out << '}'; return out.str();
}
std::string eSimulationService::command(const std::string& text) {
    if(!mBoard) return "{\"error\":\"city_not_loaded\"}";
    std::istringstream in(text); std::string action; in >> action; int value;
    if(action=="snapshot") return snapshot(true);
    if(action=="pause" && in >> value && (value==0 || value==1)) mPaused=bool(value);
    else if(action=="speed" && in >> value && value>=0 && value<=3) mSpeed=value;
    else if(action=="event") {
        uint64_t id; int choice; if(!(in >> id >> choice)) return "{\"error\":\"invalid_event\"}";
        auto it=mEvents.find(id); if(it==mEvents.end()) return "{\"error\":\"event_expired\"}";
        const auto d=it->second.data;
        if(choice==-2) {
            // "Send troops": the engine asks for the forces to send (see `enlist`); the request closes when they are dispatched.
            if(!d.fCA0) return "{\"error\":\"decision_interface_required\"}";
            mBoard->waitUntilFinished(); mEnlist.reset();
            const uint64_t eventId=id;
            d.fCA0([this,eventId]() {
                mEvents.erase(eventId); mBlocked=mTerminal;
                for(const auto& item:mEvents) { const auto& v=item.second.data; if(v.fA0 || v.fA1 || v.fA2 || v.fCA0 || !v.fCCA0.empty()) mBlocked=true; }
            });
            if(!mEnlist) return "{\"error\":\"military_unavailable\"}";
            mEnlist->purpose="troops"; mEnlist->event=id;
            return enlistInfo();
        }
        eAction call=choice==0?d.fA0:(choice==1?d.fA1:(choice==2?d.fA2:nullptr));
        if(choice >= 1000) {
            const auto city = static_cast<eCityId>(choice-1000);
            const auto action = d.fCCA0.find(city);
            if(action != d.fCCA0.end()) call = action->second;
            const auto space = d.fCSpaceCount.find(city);
            if(space != d.fCSpaceCount.end() && space->second < d.fResourceCount) return "{\"error\":\"insufficient_city_space\"}";
        }
        if(!call && (choice!=-1 || d.fA0 || d.fA1 || d.fA2 || d.fCA0 || !d.fCCA0.empty())) return "{\"error\":\"decision_interface_required\"}";
        mEvents.erase(it); mBlocked=mTerminal; if(call) call();
        for(const auto& item:mEvents) { const auto& v=item.second.data; if(v.fA0 || v.fA1 || v.fA2 || v.fCA0 || !v.fCCA0.empty()) mBlocked=true; }
    } else if(action=="preview") {
        std::string name; int x,y,orientation,partner=-1;
        // The hippodrome's turn picks among up to eight plates (0-7); every other building turns four ways.
        if(!(in>>name>>x>>y>>orientation) || orientation<0 || orientation>(name=="hippodrome"?7:3)) return "{\"error\":\"invalid_preview\"}";
        in>>partner;
        return placement(name,x,y,orientation,partner);
    } else if(action=="buildable") {
        return buildable();
    } else if(action=="trade_partners") {
        return tradePartners();
    } else if(action=="episode") {
        return episode();
    } else if(action=="finish_episode") {
        return finishEpisode();
    } else if(action=="preview_episode") {
        return previewEpisode();
    } else if(action=="choose_colony") {
        int index; if(!(in>>index)) return "{\"error\":\"invalid_colony\"}";
        return chooseColony(index);
    } else if(action=="begin_episode") {
        return beginEpisode();
    } else if(action=="set_aside") {
        int index; if(!(in>>index)) return "{\"error\":\"invalid_goal\"}";
        return setAside(index);
    } else if(action=="difficulty") {
        if(!mCampaign) return "{\"error\":\"city_not_loaded\"}";
        int value; if(in>>value) {
            if(value<0 || value>4) return "{\"error\":\"invalid_difficulty\"}";
            mCampaign->setDifficulty(static_cast<eDifficulty>(value));
        }
        std::ostringstream out; out << "{\"kind\":\"difficulty\",\"value\":" << int(mCampaign->difficulty()) << ",\"names\":[";
        for(int i=0;i<=4;++i) { if(i) out << ','; out << quote(eDifficultyHelpers::name(static_cast<eDifficulty>(i))); }
        out << "]}"; return out.str();
    } else if(action=="test_request") {
        // Validators only: a pending request of a world city for `count` of a resource, as its event would register it when it triggers.
        int index,resource,count; if(!mAllowTestCommands || !mBoard || !(in>>index>>resource>>count)) return "{\"error\":\"unsupported_command\"}";
        mBoard->waitUntilFinished();
        const auto city=worldCity(index); if(!city) return "{\"error\":\"unknown_city\"}";
        const auto e=e::make_shared<eReceiveRequestEvent>(mBoard->currentCityId(),eGameEventBranch::root,*mBoard);
        e->initialize(0,static_cast<eResourceType>(resource),count,city,false);
        e->initializeDate(mBoard->date()+3650);
        mBoard->addRootGameEvent(e);
        mBoard->addCityRequest(e.get());
        return worldInfo();
    } else if(action=="test_event") {
        // Validators only: raises an engine-made event through the board's own event path, with the fields the monthly
        // check fills in. `test_event shortage <resource> <stock> <months>` or `test_event risk <kind 0-2> <count> [x y]`
        // (the building on that tile is the worst one named). The monthly summary comes from real months (replay).
        std::string kind; if(!mAllowTestCommands || !mBoard || !(in>>kind)) return "{\"error\":\"unsupported_command\"}";
        mBoard->waitUntilFinished();
        eEventData ed(mBoard->currentCityId());
        if(kind=="shortage") {
            int resource,stock,months; if(!(in>>resource>>stock>>months)) return "{\"error\":\"unsupported_command\"}";
            ed.fResourceType=static_cast<eResourceType>(resource); ed.fResourceCount=stock; ed.fTime=months;
            mBoard->event(eEvent::shortageWarning,ed);
        } else if(kind=="risk") {
            int risk,count; if(!(in>>risk>>count) || risk<0 || risk>2) return "{\"error\":\"unsupported_command\"}";
            ed.fTime=risk; ed.fResourceCount=count;
            int x,y; if(in>>x>>y) {
                const auto tile=(x>=mX && y>=mY && x<mX+mW && y<mY+mH)?mBoard->tile(x,y):nullptr;
                if(const auto b=tile?tile->underBuilding():nullptr) { ed.fTile=b->centerTile(); ed.fReason=eBuilding::sNameForBuilding(b); }
            }
            mBoard->event(eEvent::riskWarning,ed);
        } else return "{\"error\":\"unsupported_command\"}";
    } else if(action=="test_raise") {
        // Validators only: raises any event kind through the board's own event path with the data a caller names, so its words can
        // be checked. `test_raise <event name> [god <name>] [monster <kind>] [hero <name>] [time <n>] [quest <1|2>] [reason <word>] [city <world index>]`.
        std::string name; if(!mAllowTestCommands || !mBoard || !(in>>name)) return "{\"error\":\"unsupported_command\"}";
        int found=-1; for(int i=0;i<=int(eEvent::monthlySummary);++i) if(name==eEventName(i)) { found=i; break; }
        if(found<0) return "{\"error\":\"unsupported_command\"}";
        mBoard->waitUntilFinished();
        eEventData ed(mBoard->currentCityId());
        static const std::map<std::string,eGodType> gods{{"aphrodite",eGodType::aphrodite},{"apollo",eGodType::apollo},{"ares",eGodType::ares},{"artemis",eGodType::artemis},
            {"athena",eGodType::athena},{"atlas",eGodType::atlas},{"demeter",eGodType::demeter},{"dionysus",eGodType::dionysus},{"hades",eGodType::hades},
            {"hephaestus",eGodType::hephaestus},{"hera",eGodType::hera},{"hermes",eGodType::hermes},{"poseidon",eGodType::poseidon},{"zeus",eGodType::zeus}};
        static const std::map<std::string,eHeroType> heroes{{"achilles",eHeroType::achilles},{"atalanta",eHeroType::atalanta},{"bellerophon",eHeroType::bellerophon},
            {"hercules",eHeroType::hercules},{"jason",eHeroType::jason},{"odysseus",eHeroType::odysseus},{"perseus",eHeroType::perseus},{"theseus",eHeroType::theseus}};
        static const std::map<std::string,eMonsterType> monsters{{"calydonian_boar",eMonsterType::calydonianBoar},{"cerberus",eMonsterType::cerberus},{"chimera",eMonsterType::chimera},
            {"cyclops",eMonsterType::cyclops},{"dragon",eMonsterType::dragon},{"echidna",eMonsterType::echidna},{"harpies",eMonsterType::harpies},{"hector",eMonsterType::hector},
            {"hydra",eMonsterType::hydra},{"kraken",eMonsterType::kraken},{"maenads",eMonsterType::maenads},{"medusa",eMonsterType::medusa},{"minotaur",eMonsterType::minotaur},
            {"scylla",eMonsterType::scylla},{"sphinx",eMonsterType::sphinx},{"talos",eMonsterType::talos},{"satyr",eMonsterType::satyr}};
        std::string key;
        while(in>>key) {
            std::string value; if(!(in>>value)) return "{\"error\":\"unsupported_command\"}";
            if(key=="god") { const auto it=gods.find(value); if(it==gods.end()) return "{\"error\":\"unsupported_command\"}"; ed.fGod=it->second; }
            else if(key=="monster") { const auto it=monsters.find(value); if(it==monsters.end()) return "{\"error\":\"unsupported_command\"}"; ed.fMonster=it->second; }
            else if(key=="hero") { const auto it=heroes.find(value); if(it==heroes.end()) return "{\"error\":\"unsupported_command\"}"; ed.fHero=it->second; }
            else if(key=="time") ed.fTime=std::atoi(value.c_str());
            else if(key=="quest") ed.fQuestId=value=="2"?eGodQuestId::godQuest2:eGodQuestId::godQuest1;
            else if(key=="reason") ed.fReason=value;
            else if(key=="city") { const auto city=worldCity(std::atoi(value.c_str())); if(!city) return "{\"error\":\"unknown_city\"}"; ed.fCity=city; }
            else return "{\"error\":\"unsupported_command\"}";
        }
        mBoard->event(static_cast<eEvent>(found),ed);
    } else if(action=="event_texts") {
        // Validators only: the audit of what a core event arrives with. `without_text` names every event kind the front end
        // gets no title and text for (neither the game's message catalogue nor the engine's own wording above covers it:
        // the SDL view words those in its own handlers from god, monster, hero and city data); `engine_made` lists the
        // engine's own kinds, all of which must have words. The last kind of eEvent ends the list.
        if(!mAllowTestCommands) return "{\"error\":\"unsupported_command\"}";
        std::ostringstream out; out << "{\"kind\":\"event_texts\",\"count\":" << int(eEvent::monthlySummary)+1 << ",\"without_text\":[";
        bool firstName=true;
        for(int i=0;i<=int(eEvent::monthlySummary);++i) {
            const auto kind=static_cast<eEvent>(i);
            if(eEngineMessages::handles(kind) || eEventWords::handles(kind) || eEventMessage(kind)) continue;
            if(!firstName) out << ','; firstName=false; out << quote(eEventName(i));
        }
        out << "],\"engine_made\":[";
        firstName=true;
        for(int i=int(eEvent::areaCutOff)+1;i<=int(eEvent::monthlySummary);++i) { if(!firstName) out << ','; firstName=false; out << quote(eEventName(i)); }
        out << "]}"; return out.str();
    } else if(action=="test_fund") {
        // Validators only: puts into a monument (any of its pieces will do) all the materials it still needs, as if the carts had brought them;
        // the workers still build it. `test_fund <x> <y>`.
        int x,y; if(!mAllowTestCommands || !mBoard || !(in>>x>>y)) return "{\"error\":\"unsupported_command\"}";
        const auto tile=(x>=mX && y>=mY && x<mX+mW && y<mY+mH)?mBoard->tile(x,y):nullptr;
        if(!tile) return "{\"error\":\"out_of_map\"}";
        mBoard->waitUntilFinished();
        eMonument* monument=dynamic_cast<eMonument*>(tile->underBuilding());
        if(!monument) if(const auto piece=dynamic_cast<eSanctBuilding*>(tile->underBuilding())) monument=piece->monument();
        if(!monument) return "{\"error\":\"no_monument\"}";
        for(const auto resource:{eResourceType::marble,eResourceType::wood,eResourceType::sculpture,eResourceType::orichalc,eResourceType::blackMarble})
            if(const int room=monument->spaceLeft(resource); room>0) monument->add(resource,room);
        return inspect(x,y);
    } else if(action=="test_complete") {
        // Validators only: a monument (any of its pieces will do) is finished at once, every piece taking the materials it needs, as if the carts had brought
        // them and the workers had built them (the engine's own steps: `incProgress` of each piece, the completion message, the god of a sanctuary). `test_complete <x> <y>`.
        int x,y; if(!mAllowTestCommands || !mBoard || !(in>>x>>y)) return "{\"error\":\"unsupported_command\"}";
        const auto tile=(x>=mX && y>=mY && x<mX+mW && y<mY+mH)?mBoard->tile(x,y):nullptr;
        if(!tile) return "{\"error\":\"out_of_map\"}";
        mBoard->waitUntilFinished();
        eMonument* monument=dynamic_cast<eMonument*>(tile->underBuilding());
        if(!monument) if(const auto piece=dynamic_cast<eSanctBuilding*>(tile->underBuilding())) monument=piece->monument();
        if(!monument) return "{\"error\":\"no_monument\"}";
        for(const auto resource:{eResourceType::marble,eResourceType::wood,eResourceType::sculpture,eResourceType::orichalc,eResourceType::blackMarble})
            if(const int room=monument->spaceLeft(resource); room>0) monument->add(resource,room);
        std::set<eSanctBuilding*> pieces;
        mBoard->iterateOverAllTiles([&](eTile* t) { if(const auto piece=dynamic_cast<eSanctBuilding*>(t->underBuilding())) if(piece->monument()==monument) pieces.insert(piece); });
        // Lower levels first: a pyramid's pieces rise level by level.
        std::vector<eSanctBuilding*> ordered(pieces.begin(),pieces.end());
        for(const auto piece:ordered) while(piece->incProgress()) {}
        return inspect(x,y);
    } else if(action=="test_sacrifice") {
        // Validators only: begins a rite on an altar (the engine begins one by itself every hundred seconds or so): `test_sacrifice <x> <y> <sheep|bull|goods>`
        // with a tile of the altar. It lasts as long as the engine lets a rite last, and is shown once the altar's sanctuary is finished.
        int x,y; std::string kind; if(!mAllowTestCommands || !mBoard || !(in>>x>>y>>kind)) return "{\"error\":\"unsupported_command\"}";
        const auto tile=(x>=mX && y>=mY && x<mX+mW && y<mY+mH)?mBoard->tile(x,y):nullptr;
        if(!tile) return "{\"error\":\"out_of_map\"}";
        mBoard->waitUntilFinished();
        const auto altar=dynamic_cast<eTempleAltarBuilding*>(tile->underBuilding());
        if(!altar) return "{\"error\":\"no_altar\"}";
        altar->startSacrifice(kind=="bull"?eSacrifice::bull:(kind=="sheep"?eSacrifice::sheep:eSacrifice::goods));
        return "{\"kind\":\"sacrifice\",\"rite\":"+quote(kind)+"}";
    } else if(action=="test_stock") {
        // Validators only: puts `count` of a resource (its numeric type) into the first store of the player's city.
        int resource,count; if(!mAllowTestCommands || !mBoard || !(in>>resource>>count)) return "{\"error\":\"unsupported_command\"}";
        mBoard->waitUntilFinished();
        // The first store with room takes it; what does not fit there goes into the next stores.
        int added=0; const auto pid=mBoard->personPlayer();
        mBoard->iterateOverAllTiles([&](eTile* tile) {
            if(added>=count) return;
            auto* store=dynamic_cast<eStorageBuilding*>(tile->underBuilding());
            if(store && store->playerId()==pid) added+=store->add(static_cast<eResourceType>(resource),count-added);
        });
        // The city's own count of its goods is a cache the simulation refreshes once a second; refresh it so what was stocked counts at once.
        for(const auto cid:mBoard->personPlayerCitiesOnBoard()) mBoard->updateResources(cid);
        return "{\"kind\":\"stock\",\"added\":"+std::to_string(added)+"}";
    } else if(action=="test_win") {
        // Validators only (see enableTestCommands): the same path a fulfilled set of goals takes.
        if(!mAllowTestCommands || !mBoard) return "{\"error\":\"unsupported_command\"}";
        mBlocked = mTerminal = mVictory = true;
    } else if(action=="ambient" || action=="building_sound") {
        // The sound of a place, picked by the native rules (what is on the tile, else the terrain, else the wind).
        int x,y; if(!(in>>x>>y)) return "{\"error\":\"invalid_sound\"}";
        const auto tile=(x>=mX && y>=mY && x<mX+mW && y<mY+mH)?mBoard->tile(x,y):nullptr;
        if(!tile) return "{\"error\":\"out_of_map\"}";
        mBoard->waitUntilFinished();
        { std::lock_guard<std::mutex> lock(mSoundLock); mSounds.clear(); }
        if(action=="ambient") eSounds::playSoundForTile(tile);
        else if(const auto b=tile->underBuilding()) eSounds::playSoundForBuilding(b);
        std::ostringstream out; out << "{\"kind\":\"sounds\",\"sounds\":[";
        bool firstSound=true;
        for(const auto& path:takeSounds()) { if(!firstSound) out << ','; firstSound=false; out << quote(path); }
        out << "]}"; return out.str();
    } else if(action=="overlay") {
        std::string name; if(!(in>>name)) return "{\"error\":\"invalid_overlay\"}";
        return overlay(name);
    } else if(action=="preview_road") {
        int x1,y1,x2,y2; if(!(in>>x1>>y1>>x2>>y2)) return "{\"error\":\"invalid_preview\"}";
        return roadPreview(x1,y1,x2,y2);
    } else if(action=="army") {
        return armyInfo();
    } else if(action=="army_call" || action=="army_home") {
        // Every company of the player's cities that is in the city is called out to its banner, or sent home to the palace.
        settle(*mBoard);
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        mBoard->clearBannerSelection();
        for(const auto cid:mBoard->personPlayerCitiesOnBoard()) for(const auto& b:mBoard->banners(cid)) if(!b->isAbroad() || b->militaryAid()) mBoard->selectBanner(b.get());
        if(action=="army_call") mBoard->bannersBackFromHome(); else mBoard->bannersGoHome();
        mBoard->clearBannerSelection();
        return armyInfo();
    } else if(action=="banner_call" || action=="banner_home") {
        int id; if(!(in>>id)) return "{\"error\":\"invalid_banner_command\"}";
        settle(*mBoard);
        const auto banner=playerBanner(id); if(!banner) return "{\"error\":\"unknown_banner\"}";
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        if(banner->isAbroad() && !banner->militaryAid()) return "{\"error\":\"banner_abroad\"}";
        mBoard->clearBannerSelection(); mBoard->selectBanner(banner);
        if(action=="banner_call") mBoard->bannersBackFromHome(); else mBoard->bannersGoHome();
        mBoard->clearBannerSelection();
        return armyInfo();
    } else if(action=="banner_move") {
        // banner_move <id> <x> <y>: the company's banner goes to the tile, or the nearest free tile the soldiers can stand on (the palace area sends it home).
        int id,x,y; if(!(in>>id>>x>>y)) return "{\"error\":\"invalid_banner_command\"}";
        settle(*mBoard);
        const auto banner=playerBanner(id); if(!banner) return "{\"error\":\"unknown_banner\"}";
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        if(banner->isAbroad()) return "{\"error\":\"banner_abroad\"}";
        const auto tile=(x>=mX && y>=mY && x<mX+mW && y<mY+mH)?mBoard->tile(x,y):nullptr;
        if(!tile) return "{\"error\":\"out_of_map\"}";
        if(tile->cityId()!=banner->onCityId()) return "{\"error\":\"other_district\"}";
        const auto before=banner->tile();
        std::vector<eSoldierBanner*> placing{banner};
        eSoldierBanner::sPlace(placing,x,y,*mBoard,3,2);
        if(banner->tile()==before && before!=tile) return "{\"error\":\"no_room\"}";
        return armyInfo();
    } else if(action=="test_invasion") {
        // Validators only: an enemy force of a nationality (greek, trojan, persian, centaur, amazon, egyptian, mayan, phoenician,
        // oceanid, atlantean) lands at the city's entry point through the engine's own invasion handler; its soldiers are of a hostile team.
        std::string kind; int infantry,cavalry,archers;
        if(!mAllowTestCommands || !mBoard || !(in>>kind>>infantry>>cavalry>>archers) || infantry<0 || cavalry<0 || archers<0 || infantry+cavalry+archers<1 || infantry+cavalry+archers>64) return "{\"error\":\"unsupported_command\"}";
        static const std::map<std::string,eNationality> nations{{"greek",eNationality::greek},{"trojan",eNationality::trojan},{"persian",eNationality::persian},{"centaur",eNationality::centaur},
            {"amazon",eNationality::amazon},{"egyptian",eNationality::egyptian},{"mayan",eNationality::mayan},{"phoenician",eNationality::phoenician},{"oceanid",eNationality::oceanid},{"atlantean",eNationality::atlantean}};
        const auto nation=nations.find(kind); if(nation==nations.end()) return "{\"error\":\"unsupported_command\"}";
        mBoard->waitUntilFinished();
        const auto cid=mBoard->currentCityId(); const auto tile=mBoard->entryPoint(cid);
        if(!tile) return "{\"error\":\"unsupported_command\"}";
        auto raiders=std::make_shared<eWorldCity>(eCityType::foreignCity,eCityId::neutralAggresive,"Raiders",.5,.5);
        raiders->setNationality(nation->second);
        // The handler reports its outcome to its event (a won or defeated invasion), so it gets one, scheduled far in the future.
        const auto event=e::make_shared<eInvasionEvent>(cid,eGameEventBranch::root,*mBoard);
        event->initialize(raiders,infantry+cavalry+archers);
        event->initializeDate(mBoard->date()+3650);
        mBoard->addRootGameEvent(event);
        auto* handler=new eInvasionHandler(*mBoard,cid,raiders,event.get());
        handler->initializeLandInvasion(tile,infantry,cavalry,archers);
        return armyInfo();
    } else if(action=="test_monster") {
        // Validators only: one monster of a kind is loose in the city, set up as the engine's monster events do (registered, on the city,
        // of the aggressive neutral team, with a monster action that goes out to attack). Land monsters appear at the entry point, sea
        // monsters (the kraken and Scylla, the engine's `eWaterMonster`s) in the deep water nearest to it.
        std::string kind; if(!mAllowTestCommands || !mBoard || !(in>>kind)) return "{\"error\":\"unsupported_command\"}";
        static const std::map<std::string,eMonsterType> kinds{{"calydonian_boar",eMonsterType::calydonianBoar},{"cerberus",eMonsterType::cerberus},{"chimera",eMonsterType::chimera},
            {"cyclops",eMonsterType::cyclops},{"dragon",eMonsterType::dragon},{"echidna",eMonsterType::echidna},{"harpies",eMonsterType::harpies},{"hector",eMonsterType::hector},
            {"hydra",eMonsterType::hydra},{"kraken",eMonsterType::kraken},{"maenads",eMonsterType::maenads},{"medusa",eMonsterType::medusa},{"minotaur",eMonsterType::minotaur},
            {"scylla",eMonsterType::scylla},{"sphinx",eMonsterType::sphinx},{"talos",eMonsterType::talos},{"satyr",eMonsterType::satyr}};
        const auto kindIt=kinds.find(kind); if(kindIt==kinds.end()) return "{\"error\":\"unsupported_command\"}";
        mBoard->waitUntilFinished();
        const auto cid=mBoard->currentCityId(); const auto entry=mBoard->entryPoint(cid);
        if(!entry) return "{\"error\":\"unsupported_command\"}";
        // A land monster appears where the engine's monster events put one (the scenario's monster point), else at the entry point.
        eTile* spot=mBoard->monsterTile(cid,0); if(!spot) spot=entry;
        const bool sea=kindIt->second==eMonsterType::kraken || kindIt->second==eMonsterType::scylla;
        if(sea) {
            double best=1e18; spot=nullptr;
            for(int y=0;y<mBoard->height();++y) for(int x=0;x<mBoard->width();++x) {
                const auto t=mBoard->tile(x,y); if(!t || t->cityId()!=cid || !t->hasDeepWater() || t->underBuilding()) continue;
                const double d=double(x-entry->x())*(x-entry->x())+double(y-entry->y())*(y-entry->y());
                if(d<best) { best=d; spot=t; }
            }
            if(!spot) return "{\"error\":\"no_deep_water\"}";
        }
        const auto monster=eMonster::sCreateMonster(kindIt->second,*mBoard);
        mBoard->registerMonster(cid,monster.get());
        monster->setOnCityId(cid);
        monster->setCityId(eCityId::neutralAggresive);
        const auto act=e::make_shared<eMonsterAction>(monster.get());
        act->setAggressivness(eMonsterAggressivness::aggressive);
        monster->setAction(act);
        monster->changeTile(spot);
        act->increment(1);
        return armyInfo();
    } else if(action=="hero_summon") {
        // hero_summon <x> <y> <inspection token>: the summon button of a hero's hall, as the SDL inspector offers it (only when every
        // requirement is met); like every building control it is refused for a building other than the one that was inspected.
        int x,y; uint64_t token; if(!(in>>x>>y>>token)) return "{\"error\":\"invalid_hero_command\"}";
        in>>std::ws; if(!in.eof()) return "{\"error\":\"invalid_hero_command\"}";
        mBoard->waitUntilFinished();
        const auto tile=(x>=mX && y>=mY && x<mX+mW && y<mY+mH)?mBoard->tile(x,y):nullptr;
        const auto hall=tile?dynamic_cast<eHerosHall*>(tile->underBuilding()):nullptr;
        if(!hall) return "{\"error\":\"no_hall\"}";
        if(token!=mInspectionToken || mInspectionTarget.get()!=hall || hall->deleteScheduled()) return "{\"error\":\"inspection_target_changed\"}";
        if(hall->playerId()!=mBoard->personPlayer()) return "{\"error\":\"not_owned\"}";
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        if(hall->stage()!=eHeroSummoningStage::none) return "{\"error\":\"already_summoned\"}";
        hall->updateRequirementsStatus();
        for(const auto& requirement:hall->requirements()) if(!requirement.met()) return "{\"error\":\"requirements_not_met\"}";
        hall->summon();
        return inspect(x,y);
    } else if(action=="building_switch") {
        // building_switch <x> <y> <token> <0|1>: the trireme wharf's switch (0 shut down, 1 working), as on the SDL page.
        int x,y,on; uint64_t token; if(!(in>>x>>y>>token>>on) || (on!=0 && on!=1)) return "{\"error\":\"invalid_switch\"}";
        mBoard->waitUntilFinished();
        const auto tile=(x>=mX && y>=mY && x<mX+mW && y<mY+mH)?mBoard->tile(x,y):nullptr;
        const auto wharf=tile?dynamic_cast<eTriremeWharf*>(tile->underBuilding()):nullptr;
        if(!wharf) return "{\"error\":\"invalid_switch\"}";
        if(token!=mInspectionToken || mInspectionTarget.get()!=wharf || wharf->deleteScheduled()) return "{\"error\":\"inspection_target_changed\"}";
        if(wharf->playerId()!=mBoard->personPlayer()) return "{\"error\":\"not_owned\"}";
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        wharf->setShutDown(on==0);
        return inspect(x,y);
    } else if(action=="character_info") {
        // character_info <walker id>: the SDL character window (right click on a walker) as data, worded by engine/echaracterinfotext:
        // name, occupation, the line it speaks now with its voice file, a cart's errand, and the other people on its tile, whom the
        // window also offers. The voice is not played here; the front end plays `voice` itself, so a replay of the line is exact.
        int walker; if(!(in>>walker)) return "{\"error\":\"invalid_walker\"}";
        mBoard->waitUntilFinished();
        const auto find=[&](int wanted)->eCharacter* {
            for(const auto& entry:mIds) {
                if(entry.second!=uint64_t(wanted)) continue;
                for(const auto c:mBoard->characters()) if(static_cast<const void*>(c)==entry.first) return c;
            }
            return nullptr;
        };
        auto c=find(walker);
        // A cart's trailer speaks for its driver, as the SDL view never lists the trailer itself.
        if(c && c->type()==eCharacterType::trailer) if(const auto driver=static_cast<eTrailer*>(c)->follow()) c=driver;
        if(!c || c->dead() || !c->tile() || c->type()==eCharacterType::trailer) return "{\"error\":\"walker_gone\"}";
        const auto kind=[](eCharacter* ch) {
            bool v=false; const auto t=ch->type();
            eGod::sCharacterToGodType(t,&v); if(v) return "god";
            eHero::sCharacterToHeroType(t,&v); if(v) return "hero";
            eMonster::sCharacterToMonsterType(t,&v); if(v) return "monster";
            return "person";
        };
        const auto describe=[&](eCharacter* ch,std::ostringstream& o) {
            const auto it=mIds.find(ch);
            o << "\"id\":" << (it==mIds.end()?0:it->second) << ",\"type\":" << int(ch->type()) << ",\"asset\":" << quote(walkerAsset(ch))
              << ",\"kind\":" << quote(kind(ch)) << ",\"name\":" << quote(eCharacterInfoText::name(ch))
              << ",\"occupation\":" << quote(eCharacterInfoText::occupation(ch));
        };
        const auto msg=eCharacterInfoText::message(c);
        const auto path=msg.soundPath();
        std::error_code ec;
        std::ostringstream o; o << '{'; describe(c,o);
        o << ",\"text\":" << quote(msg.fText) << ",\"voice\":" << quote(!path.empty() && std::filesystem::exists(path,ec)?relativeSound(path):std::string())
          << ",\"errand\":" << quote(eCharacterInfoText::errand(c)) << ",\"x\":" << c->tile()->x() << ",\"y\":" << c->tile()->y() << ",\"others\":[";
        bool firstOther=true;
        for(const auto& other:c->tile()->characters()) {
            const auto oc=other.get();
            if(oc==c || oc->type()==eCharacterType::trailer || oc->dead() || !oc->visible() || !mIds.count(oc)) continue;
            if(eCharacterInfoText::name(oc).empty() && eCharacterInfoText::occupation(oc).empty()) continue;
            if(!firstOther) o << ','; firstOther=false;
            o << '{'; describe(oc,o); o << '}';
        }
        o << "]}";
        return o.str();
    } else if(action=="trireme_move") {
        // trireme_move <x> <y> <walker id> [<walker id> ...]: the selected triremes sail to the water around the tile, as a right
        // click does in the SDL view (eTrireme::sPlace); only the player's triremes that may be given orders are moved.
        int x,y; if(!(in>>x>>y)) return "{\"error\":\"invalid_trireme_order\"}";
        std::set<int> wanted; int walker; while(in>>walker) wanted.insert(walker);
        if(wanted.empty()) return "{\"error\":\"invalid_trireme_order\"}";
        mBoard->waitUntilFinished();
        const auto tile=(x>=mX && y>=mY && x<mX+mW && y<mY+mH)?mBoard->tile(x,y):nullptr;
        if(!tile) return "{\"error\":\"out_of_map\"}";
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        if(tile->cityId()!=mBoard->currentCityId()) return "{\"error\":\"other_district\"}";
        std::vector<eTrireme*> fleet;
        for(const auto& entry:mIds) {
            if(!wanted.count(entry.second)) continue;
            for(const auto c:mBoard->characters()) {
                if(static_cast<const void*>(c)!=entry.first || c->type()!=eCharacterType::trireme) continue;
                const auto trireme=static_cast<eTrireme*>(c);
                if(trireme->playerId()==mBoard->personPlayer() && trireme->selectable()) fleet.push_back(trireme);
            }
        }
        if(fleet.empty()) return "{\"error\":\"no_trireme\"}";
        eTrireme::sPlace(fleet,x,y,*mBoard,3,2);
        return snapshot();
    } else if(action=="city_data") {
        return cityData();
    } else if(action=="set_tax" || action=="set_wage" || action=="set_priority" || action=="man_towers") {
        // The settings of the SDL data pages: set_tax <0-6> (none ... outrageous), set_wage <0-5> (none ... very high),
        // set_priority <sector 0-7> <0-5> (no priority ... very high; the workers are then shared out again, as the SDL
        // allocation window does) and man_towers <0|1>. Each answers city_data.
        int a=-1,b=-1; if(!(in>>a)) return "{\"error\":\"invalid_city_setting\"}";
        if(action=="set_priority" && !(in>>b)) return "{\"error\":\"invalid_city_setting\"}";
        in>>std::ws; if(!in.eof()) return "{\"error\":\"invalid_city_setting\"}";
        mBoard->waitUntilFinished();
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        const auto cid=mBoard->currentCityId();
        if(mBoard->cityIdToPlayerId(cid)!=mBoard->personPlayer()) return "{\"error\":\"not_owned\"}";
        if(action=="set_tax") {
            if(a<0 || a>int(eTaxRate::outrageous)) return "{\"error\":\"invalid_city_setting\"}";
            mBoard->setTaxRate(cid,static_cast<eTaxRate>(a));
        } else if(action=="set_wage") {
            if(a<0 || a>int(eWageRate::veryHigh)) return "{\"error\":\"invalid_city_setting\"}";
            mBoard->setWageRate(cid,static_cast<eWageRate>(a));
        } else if(action=="set_priority") {
            if(a<int(eSector::husbandry) || a>int(eSector::military) || b<0 || b>int(ePriority::veryHigh)) return "{\"error\":\"invalid_city_setting\"}";
            const auto distributor=mBoard->employmentDistributor(cid); if(!distributor) return "{\"error\":\"invalid_city_setting\"}";
            distributor->setPriority(static_cast<eSector>(a),static_cast<ePriority>(b));
            mBoard->distributeEmployees(cid);
        } else {
            if(a!=0 && a!=1) return "{\"error\":\"invalid_city_setting\"}";
            mBoard->setManTowers(cid,a==1);
        }
        return cityData();
    } else if(action=="mythology") {
        // The SDL mythology page: the city's sanctuaries with their state (working, sacrificing, waiting for materials, being built),
        // the gods that are attacking it and the monsters at large in it.
        mBoard->waitUntilFinished();
        const auto cid=mBoard->currentCityId(); std::ostringstream o;
        o << "{\"kind\":\"mythology\",\"max\":" << mBoard->maxSanctuaries(cid) << ",\"titles\":{\"sanctuaries\":" << quote(eLanguage::zeusText(59,1))
          << ",\"gods\":" << quote(eLanguage::zeusText(59,16)) << ",\"monsters\":" << quote(eLanguage::zeusText(59,17)) << ",\"none\":" << quote(eLanguage::zeusText(283,12)) << "},\"sanctuaries\":[";
        bool first=true;
        for(const auto sanctuary:mBoard->sanctuaries(cid)) {
            const auto centre=sanctuary->centerTile(); const auto god=sanctuary->god(); const auto where=god&&god->tile()?god->tile():centre;
            const int textId=sanctuary->finished()?(sanctuary->sacrificing()?3:2):9;
            if(!first) o << ','; first=false;
            o << "{\"god\":" << int(sanctuary->godType()) << ",\"god_name\":" << quote(eGod::sGodName(sanctuary->godType())) << ",\"name\":" << quote(eBuilding::sNameForBuilding(sanctuary))
              << ",\"finished\":" << (sanctuary->finished()?"true":"false") << ",\"progress\":" << sanctuary->progress() << ",\"sacrificing\":" << (sanctuary->sacrificing()?"true":"false")
              << ",\"state\":" << quote(eLanguage::zeusText(59,textId)) << ",\"x\":" << (where?where->x():0) << ",\"y\":" << (where?where->y():0)
              << ",\"centre\":[" << (centre?centre->x():0) << ',' << (centre?centre->y():0) << "]}";
        }
        o << "],\"gods_attacking\":[";
        first=true;
        for(const auto god:mBoard->attackingGods(cid)) {
            if(!god || !god->tile()) continue;
            if(!first) o << ','; first=false;
            bool valid=false; const auto type=eGod::sCharacterToGodType(god->type(),&valid);
            o << "{\"name\":" << quote(valid?eGod::sGodName(type):std::string()) << ",\"x\":" << god->tile()->x() << ",\"y\":" << god->tile()->y() << '}';
        }
        o << "],\"monsters\":[";
        first=true;
        for(const auto monster:mBoard->monsters(cid)) {
            if(!monster || monster->dead() || !monster->tile()) continue;
            if(!first) o << ','; first=false;
            o << "{\"name\":" << quote(eMonster::sMonsterName(eMonster::sCharacterToMonsterType(monster->type()))) << ",\"x\":" << monster->tile()->x() << ",\"y\":" << monster->tile()->y() << '}';
        }
        o << "]}";
        return o.str();
    } else if(action=="monument_halt" || action=="sanctuary_help" || action=="sanctuary_attack") {
        // monument_halt <x> <y> <token> <0|1> stops or resumes the building of a monument; sanctuary_help <x> <y> <token> asks the god of
        // a finished sanctuary for its help, as the SDL inspector's button does (the answer's words are in `help`).
        // sanctuary_attack <x> <y> <token> <city> sends the god of a finished sanctuary against an enemy city on the board, as the SDL inspector's
        // "God Invasion" button does (the answer's words are in `attack_answer`).
        int x,y,flag=0,target=-1; uint64_t token;
        if(!(in>>x>>y>>token) || (action=="monument_halt" && !(in>>flag)) || (action=="sanctuary_attack" && !(in>>target))) return "{\"error\":\"invalid_monument_command\"}";
        in>>std::ws; if(!in.eof()) return "{\"error\":\"invalid_monument_command\"}";
        mBoard->waitUntilFinished();
        const auto tile=(x>=mX && y>=mY && x<mX+mW && y<mY+mH)?mBoard->tile(x,y):nullptr;
        const auto building=tile?tile->underBuilding():nullptr;
        eMonument* monument=dynamic_cast<eMonument*>(building);
        if(!monument) if(const auto piece=dynamic_cast<eSanctBuilding*>(building)) monument=piece->monument();
        if(!monument) return "{\"error\":\"no_monument\"}";
        if(token!=mInspectionToken || mInspectionTarget.get()!=building || building->deleteScheduled()) return "{\"error\":\"inspection_target_changed\"}";
        if(monument->playerId()!=mBoard->personPlayer()) return "{\"error\":\"not_owned\"}";
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        std::string help="null", attack="null";
        if(action=="monument_halt") {
            if(monument->finished()) return "{\"error\":\"already_finished\"}";
            monument->setConstructionHalted(flag!=0);
        } else if(action=="sanctuary_attack") {
            const auto sanctuary=dynamic_cast<eSanctuary*>(monument);
            if(!sanctuary || !sanctuary->finished()) return "{\"error\":\"not_finished\"}";
            const auto enemies=mBoard->enemyCidsOnBoard(mBoard->playerIdToTeamId(sanctuary->playerId()));
            if(std::find(enemies.begin(),enemies.end(),static_cast<eCityId>(target))==enemies.end()) return "{\"error\":\"not_an_enemy_city\"}";
            eHelpDenialReason reason; const bool granted=sanctuary->askForAttack(static_cast<eCityId>(target),reason);
            int string=25;
            if(!granted) { const int percent=std::clamp(int(std::floor(100*sanctuary->helpAttackTimeFraction())),0,100); string=19+percent/17; }
            attack="{\"granted\":"+std::string(granted?"true":"false")+",\"reason\":"+std::string(granted?"\"\"":"\"too_soon\"")
                +",\"text\":"+quote(eGod::sGodName(sanctuary->godType())+" "+eLanguage::zeusText(59,string))+"}";
        } else {
            const auto sanctuary=dynamic_cast<eSanctuary*>(monument);
            if(!sanctuary || !sanctuary->finished()) return "{\"error\":\"not_finished\"}";
            eHelpDenialReason reason; const bool granted=sanctuary->askForHelp(reason); const int godText=sanctuaryTextId(sanctuary->godType());
            int string=-1; if(granted) string=24+godText; else if(reason==eHelpDenialReason::tooSoon) string=52+godText; else if(reason==eHelpDenialReason::noTarget) string=38+godText;
            help="{\"granted\":"+std::string(granted?"true":"false")+",\"reason\":"+std::string(granted?"\"\"":(reason==eHelpDenialReason::tooSoon?"\"too_soon\"":(reason==eHelpDenialReason::noTarget?"\"no_target\"":"\"error\"")))
                +",\"text\":"+quote(string>=0?eLanguage::zeusText(132,string):std::string())+"}";
        }
        auto answer=inspect(x,y);
        if(!answer.empty() && answer.back()=='}') { answer.pop_back(); answer+=",\"help\":"+help+",\"attack_answer\":"+attack+"}"; }
        return answer;
    } else if(action=="world_quest") {
        // world_quest <quest index>: sends the hero a god asks for on his quest, as the SDL overview's quest button does (the hero must have arrived).
        int id; if(!(in>>id)) return "{\"error\":\"invalid_world_command\"}";
        mBoard->waitUntilFinished();
        const auto pid=mBoard->personPlayer(); const auto quests=mBoard->godQuests(pid);
        if(id<0 || id>=int(quests.size())) return "{\"error\":\"unknown_quest\"}";
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        const auto hero=quests[id]->godQuest().fHero; eHerosHall* hall=nullptr;
        for(const auto cid:mBoard->personPlayerCitiesOnBoard()) { hall=mBoard->heroHall(cid,hero); if(hall) break; }
        if(!hall) return "{\"error\":\"no_hall\"}";
        if(hall->stage()!=eHeroSummoningStage::arrived) return "{\"error\":\"hero_not_ready\"}";
        quests[id]->fulfill();
        return worldInfo();
    } else if(action=="test_allow") {
        // Validators only: lets the city build a building it is not offered (the scenario's rules decide what is offered; the
        // engine's own `allow`). `test_allow <building name>`.
        std::string name; if(!mAllowTestCommands || !mBoard || !(in>>name)) return "{\"error\":\"unsupported_command\"}";
        const auto found=buildSpecs.find(name); if(found==buildSpecs.end()) return "{\"error\":\"unsupported_command\"}";
        mBoard->waitUntilFinished();
        const auto city=mBoard->boardCityWithId(mBoard->currentCityId()); if(!city) return "{\"error\":\"unsupported_command\"}";
        if(found->second.kind==Kind::pyramid) {
            // A pyramid is granted with its levels: `test_allow <name> [0|1 for each level, 1 = black marble]` (light and dark by turns when none are given).
            std::string given; in>>given; std::vector<bool> levels;
            for(int level=0;level<ePyramid::sLevels(found->second.type);++level) levels.push_back(level<int(given.size())?given[level]=='1':level%2==1);
            city->allowPyramid(found->second.type,levels);
        } else {
            // A commemorative or a god's monument is granted by its id (the monument, the god).
            const auto kind=found->second.kind;
            city->allow(found->second.type,kind==Kind::commemorative || kind==Kind::godMonument?found->second.variant:-1);
        }
        // A scenario also limits the sanctuaries of a city: one more is let in, so the one named can be founded.
        if(found->second.kind==Kind::sanctuary && int(mBoard->sanctuaries(mBoard->currentCityId()).size())>=city->maxSanctuaries())
            city->setMaxSanctuaries(int(mBoard->sanctuaries(mBoard->currentCityId()).size())+1);
        return buildable();
    } else if(action=="test_trireme") {
        // Validators only: `test_trireme <x> <y>` stocks the trireme wharf there with wood and armour and has its workers finish a
        // trireme at once (the engine's build time and stages are set to 1 while the city steps, then restored).
        int x,y; if(!mAllowTestCommands || !mBoard || !(in>>x>>y)) return "{\"error\":\"unsupported_command\"}";
        mBoard->waitUntilFinished();
        const auto tile=(x>=mX && y>=mY && x<mX+mW && y<mY+mH)?mBoard->tile(x,y):nullptr;
        const auto wharf=tile?dynamic_cast<eTriremeWharf*>(tile->underBuilding()):nullptr;
        if(!wharf) return "{\"error\":\"unsupported_command\"}";
        const int time=eNumbers::sTriremeWharfBuildTime, stages=eNumbers::sTriremeWharfBuildStages;
        eNumbers::sTriremeWharfBuildTime=1; eNumbers::sTriremeWharfBuildStages=1;
        for(int step=0;step<400 && !wharf->hasTrireme();++step) {
            wharf->add(eResourceType::wood,2); wharf->add(eResourceType::armor,1);
            eReplaySteps(*mBoard,1);
        }
        eNumbers::sTriremeWharfBuildTime=time; eNumbers::sTriremeWharfBuildStages=stages;
        if(!wharf->hasTrireme()) return "{\"error\":\"no_workers\"}";
        return snapshot();
    } else if(action=="test_race") {
        // Validators only: the city's closed hippodrome gets the horses it needs and its chariots start a race (eHippodrome::spawnHorses).
        if(!mAllowTestCommands || !mBoard) return "{\"error\":\"unsupported_command\"}";
        mBoard->waitUntilFinished();
        for(const auto b:mBoard->buildings(mBoard->currentCityId(),eBuildingType::hippodromePiece)) {
            const auto h=static_cast<eHippodromePiece*>(b)->hippodrome();
            if(!h || !h->closed()) continue;
            if(h->hasHorses()<h->neededHorses()) h->addHorses(h->neededHorses()-h->hasHorses());
            h->spawnHorses();
            return snapshot();
        }
        return "{\"error\":\"hippodrome_not_closed\"}";
    } else if(action=="test_quest") {
        // Validators only: a god asks for a quest through the engine's own event (`trigger` lists it among the player's quests, raises
        // the event and lets the city build the hero's hall). `test_quest <god> <1|2>`.
        std::string name; int number; if(!mAllowTestCommands || !mBoard || !(in>>name>>number) || number<1 || number>2) return "{\"error\":\"unsupported_command\"}";
        static const std::map<std::string,eGodType> gods{{"aphrodite",eGodType::aphrodite},{"apollo",eGodType::apollo},{"ares",eGodType::ares},{"artemis",eGodType::artemis},
            {"athena",eGodType::athena},{"atlas",eGodType::atlas},{"demeter",eGodType::demeter},{"dionysus",eGodType::dionysus},{"hades",eGodType::hades},
            {"hephaestus",eGodType::hephaestus},{"hera",eGodType::hera},{"hermes",eGodType::hermes},{"poseidon",eGodType::poseidon},{"zeus",eGodType::zeus}};
        const auto found=gods.find(name); if(found==gods.end()) return "{\"error\":\"unsupported_command\"}";
        mBoard->waitUntilFinished();
        const auto id=number==2?eGodQuestId::godQuest2:eGodQuestId::godQuest1;
        const auto e=e::make_shared<eGodQuestEvent>(mBoard->currentCityId(),eGameEventBranch::root,*mBoard);
        e->setGod(found->second); e->setId(id); e->setHero(eGodQuest::sDefaultHero(found->second,id));
        e->initializeDate(mBoard->date()+3650);
        mBoard->addRootGameEvent(e);
        e->trigger();
        return worldInfo();
    } else if(action=="test_hero") {
        // Validators only: the hero of the player's hall arrives at once (the engine's own arrival: the hero appears, the event is raised).
        std::string name; if(!mAllowTestCommands || !mBoard || !(in>>name)) return "{\"error\":\"unsupported_command\"}";
        static const std::map<std::string,eHeroType> heroes{{"achilles",eHeroType::achilles},{"atalanta",eHeroType::atalanta},{"bellerophon",eHeroType::bellerophon},
            {"hercules",eHeroType::hercules},{"jason",eHeroType::jason},{"odysseus",eHeroType::odysseus},{"perseus",eHeroType::perseus},{"theseus",eHeroType::theseus}};
        const auto found=heroes.find(name); if(found==heroes.end()) return "{\"error\":\"unsupported_command\"}";
        mBoard->waitUntilFinished();
        eHerosHall* hall=nullptr; for(const auto cid:mBoard->personPlayerCitiesOnBoard()) { hall=mBoard->heroHall(cid,found->second); if(hall) break; }
        if(!hall) return "{\"error\":\"no_hall\"}";
        if(hall->stage()==eHeroSummoningStage::none) hall->summon();
        if(hall->stage()==eHeroSummoningStage::summoned) hall->arrive();
        const auto tile=hall->centerTile();
        return tile?inspect(tile->x(),tile->y()):std::string("{}");
    } else if(action=="test_soldiers") {
        // Validators only: `count` soldiers of a kind (hoplite, horseman or rock_thrower) join the city's companies, as housing would supply them.
        std::string kind; int count; if(!mAllowTestCommands || !mBoard || !(in>>kind>>count) || count<1 || count>200) return "{\"error\":\"unsupported_command\"}";
        mBoard->waitUntilFinished();
        const auto type=kind=="hoplite"?eCharacterType::hoplite:(kind=="horseman"?eCharacterType::horseman:(kind=="rock_thrower"?eCharacterType::rockThrower:eCharacterType::none));
        if(type==eCharacterType::none) return "{\"error\":\"unsupported_command\"}";
        const auto city=mBoard->boardCityWithId(mBoard->currentCityId()); if(!city) return "{\"error\":\"unsupported_command\"}";
        for(int i=0;i<count;++i) city->addSoldier(type);
        return armyInfo();
    } else if(action=="world_raid" || action=="world_conquer") {
        // world_raid <city> / world_conquer <city>: asks the engine for the forces to send (see `enlist`); `enlist_dispatch` sends them.
        int index; if(!(in>>index)) return "{\"error\":\"invalid_world_command\"}";
        mBoard->waitUntilFinished();
        const auto city=worldCity(index); if(!city) return "{\"error\":\"unknown_city\"}";
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        const auto flags=militaryFlags(*mBoard,city,mBoard->personPlayer());
        const bool raid=action=="world_raid";
        if(!city->visible() || !(raid?flags.raid:flags.conquer)) return "{\"error\":\"military_unavailable\"}";
        mEnlist.reset();
        if(raid) {
            const auto board=mBoard;
            std::vector<eResourceType> resources{eResourceType::none,eResourceType::drachmas};
            for(const auto& sells:city->sells()) resources.push_back(sells.fType);
            board->requestForces([board,city](const eEnlistedForces& forces,const eResourceType plunder) {
                board->enlistForces(forces);
                const auto e=e::make_shared<ePlayerRaidEvent>(board->currentCityId(),eGameEventBranch::root,*board);
                const int period=eNumbers::sArmyTravelTime;
                e->initializeDate(board->date()+period,period,1);
                e->initialize(forces,city,plunder);
                board->addRootGameEvent(e);
            },resources,{city});
        } else {
            const auto board=mBoard; const bool reinforcements=flags.reinforce;
            board->requestForces([board,city,reinforcements](const eEnlistedForces& forces,const eResourceType) {
                board->enlistForces(forces);
                if(reinforcements) {
                    const auto e=e::make_shared<eReinforcementsEvent>(city->cityId(),eGameEventBranch::root,*board);
                    const int period=eNumbers::sReinforcementsTravelTime;
                    e->initializeDate(board->date()+period,period,1);
                    e->initialize(forces,city);
                    board->addRootGameEvent(e);
                } else {
                    const auto e=e::make_shared<ePlayerConquestEvent>(board->currentCityId(),eGameEventBranch::root,*board);
                    const int period=eNumbers::sArmyTravelTime; const auto date=board->date()+period;
                    e->initializeDate(date,period,1);
                    e->initialize(date,forces,city);
                    board->addRootGameEvent(e);
                }
            },{},{city},reinforcements);
        }
        if(!mEnlist) return "{\"error\":\"military_unavailable\"}";
        mEnlist->purpose=raid?"raid":(flags.reinforce?"reinforce":"conquer"); mEnlist->city=index;
        return enlistInfo();
    } else if(action=="enlist") {
        return enlistInfo();
    } else if(action=="enlist_cancel") {
        mEnlist.reset(); return worldInfo();
    } else if(action=="enlist_dispatch") {
        // enlist_dispatch <plunder resource, -1 for any> [s:<banner ids>] [h:<city>:<hero>,...] [a:<ally city index>]
        if(!mEnlist) return "{\"error\":\"no_enlistment\"}";
        mBoard->waitUntilFinished();
        const auto session=mEnlist; int plunder; if(!(in>>plunder)) return "{\"error\":\"invalid_enlistment\"}";
        eEnlistedForces chosen; std::string token; int allies=0;
        const auto split=[](const std::string& text,const char separator) { std::vector<std::string> parts; std::istringstream stream(text); std::string part; while(std::getline(stream,part,separator)) if(!part.empty()) parts.push_back(part); return parts; };
        try {
            while(in>>token) {
                if(token.size()<2 || token[1]!=':') return "{\"error\":\"invalid_enlistment\"}";
                const auto body=token.substr(2);
                if(token[0]=='s') {
                    for(const auto& part:split(body,',')) {
                        const int id=std::stoi(part); stdsptr<eSoldierBanner> found;
                        for(const auto& banner:session->forces.fSoldiers) if(banner->id()==id) found=banner;
                        if(!found) return "{\"error\":\"not_enlistable\"}";
                        if(found->isAbroad()) return "{\"error\":\"already_abroad\"}";
                        if(!eVectorHelpers::contains(chosen.fSoldiers,found)) chosen.fSoldiers.push_back(found);
                    }
                } else if(token[0]=='h') {
                    for(const auto& part:split(body,',')) {
                        const auto fields=split(part,':'); if(fields.size()!=2) return "{\"error\":\"invalid_enlistment\"}";
                        const auto hero=std::make_pair(static_cast<eCityId>(std::stoi(fields[0])),static_cast<eHeroType>(std::stoi(fields[1])));
                        bool listed=false; for(const auto& candidate:session->forces.fHeroes) listed=listed || candidate==hero;
                        if(!listed) return "{\"error\":\"not_enlistable\"}";
                        if(eVectorHelpers::contains(session->heroesAbroad,hero.second)) return "{\"error\":\"already_abroad\"}";
                        if(!eVectorHelpers::contains(chosen.fHeroes,hero)) chosen.fHeroes.push_back(hero);
                    }
                } else if(token[0]=='a') {
                    for(const auto& part:split(body,',')) {
                        const auto ally=worldCity(std::stoi(part)); if(!ally || !eVectorHelpers::contains(session->forces.fAllies,ally)) return "{\"error\":\"not_enlistable\"}";
                        if(ally->abroad()) return "{\"error\":\"already_abroad\"}";
                        if(++allies>1) return "{\"error\":\"one_ally_only\"}";
                        chosen.fAllies.push_back(ally);
                    }
                } else return "{\"error\":\"invalid_enlistment\"}";
            }
        } catch(const std::exception&) { return "{\"error\":\"invalid_enlistment\"}"; }
        // The SDL dialog sends nothing without a soldier or a hero (an ally's troops alone are not a force).
        if(chosen.fSoldiers.empty() && chosen.fHeroes.empty()) return "{\"error\":\"no_forces\"}";
        eResourceType resource=eResourceType::none;
        if(plunder>=0) { resource=static_cast<eResourceType>(plunder); if(!eVectorHelpers::contains(session->plunder,resource)) return "{\"error\":\"not_offered\"}"; }
        mEnlist.reset();
        session->action(chosen,resource);
        return worldInfo();
    } else if(action=="world_aid") {
        // world_aid <city index> <own city>: the SDL request dialog's "request defensive aid".
        int index,cityValue; if(!(in>>index>>cityValue)) return "{\"error\":\"invalid_world_command\"}";
        mBoard->waitUntilFinished();
        const auto city=worldCity(index); const auto pid=mBoard->personPlayer(); const auto cid=static_cast<eCityId>(cityValue);
        if(!city) return "{\"error\":\"unknown_city\"}";
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        if(mBoard->cityIdToPlayerId(cid)!=pid || !eVectorHelpers::contains(mBoard->personPlayerCitiesOnBoard(),cid)) return "{\"error\":\"not_owned\"}";
        const auto flags=militaryFlags(*mBoard,city,pid);
        if(flags.aid.empty()) return "{\"error\":\"world_dealings_unavailable\"}";
        if(flags.aid!="ok") return "{\"error\":\""+flags.aid+"\"}";
        for(const auto& other:mBoard->world().cities()) if(!other->isCurrentCity()) other->incAttitude(-10,pid);
        city->incAttitude(-10,pid);
        mBoard->requestAid(city,cid);
        return worldInfo();
    } else if(action=="world_strike") {
        // world_strike <city index> <rival city index>: asks an ally to strike a rival; the engine answers in 30 days.
        int index,rivalIndex; if(!(in>>index>>rivalIndex)) return "{\"error\":\"invalid_world_command\"}";
        mBoard->waitUntilFinished();
        const auto city=worldCity(index), rival=worldCity(rivalIndex); const auto pid=mBoard->personPlayer();
        if(!city || !rival) return "{\"error\":\"unknown_city\"}";
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        if(!rival->visible() || !rival->isRival()) return "{\"error\":\"not_a_rival\"}";
        const auto flags=militaryFlags(*mBoard,city,pid);
        if(flags.aid.empty()) return "{\"error\":\"world_dealings_unavailable\"}";
        if(flags.aid=="not_regarded" || flags.aid=="cant_spare") return "{\"error\":\""+flags.aid+"\"}";
        const auto e=e::make_shared<eRequestStrikeEvent>(mBoard->currentCityId(),eGameEventBranch::root,*mBoard);
        e->setCity(city); e->setRivalCity(rival); e->initializeDate(mBoard->date()+30);
        mBoard->addRootGameEvent(e);
        return worldInfo();
    } else if(action=="test_relationship") {
        // Validators only: makes a world city an ally, a vassal or a rival (the test world has only allies).
        int index; std::string kind; if(!mAllowTestCommands || !mBoard || !(in>>index>>kind)) return "{\"error\":\"unsupported_command\"}";
        const auto city=worldCity(index); if(!city) return "{\"error\":\"unknown_city\"}";
        if(kind=="ally") city->setRelationship(eForeignCityRelationship::ally); else if(kind=="vassal") city->setRelationship(eForeignCityRelationship::vassal);
        else if(kind=="rival") city->setRelationship(eForeignCityRelationship::rival); else return "{\"error\":\"unsupported_command\"}";
        return worldInfo();
    } else if(action=="test_attitude") {
        // Validators only: a world city's regard for the player.
        int index,value; if(!mAllowTestCommands || !mBoard || !(in>>index>>value)) return "{\"error\":\"unsupported_command\"}";
        const auto city=worldCity(index); if(!city) return "{\"error\":\"unknown_city\"}";
        city->setAttitude(value,mBoard->personPlayer());
        return worldInfo();
    } else if(action=="test_troops") {
        // Validators only: the troops of a world city.
        int index,value; if(!mAllowTestCommands || !mBoard || !(in>>index>>value)) return "{\"error\":\"unsupported_command\"}";
        const auto city=worldCity(index); if(!city) return "{\"error\":\"unknown_city\"}";
        city->setTroops(value);
        return worldInfo();
    } else if(action=="test_troops_request") {
        // Validators only: an ally asks for troops against an attack by another city (the request waits as a decision with "send troops").
        int index,attacker; if(!mAllowTestCommands || !mBoard || !(in>>index>>attacker)) return "{\"error\":\"unsupported_command\"}";
        mBoard->waitUntilFinished();
        const auto city=worldCity(index), attacking=worldCity(attacker); if(!city || !attacking) return "{\"error\":\"unknown_city\"}";
        const auto e=e::make_shared<eTroopsRequestEvent>(mBoard->currentCityId(),eGameEventBranch::root,*mBoard);
        e->setType(eTroopsRequestEventType::cityUnderAttack); e->setSingleCity(city); e->setAttackingCity(attacking); e->initializeDate(mBoard->date()+1);
        mBoard->addRootGameEvent(e);
        return worldInfo();
    } else if(action=="world") {
        return worldInfo();
    } else if(action=="world_request") {
        // world_request <city index> <resource> <city that receives it>
        int index,resourceValue,cityValue; if(!(in>>index>>resourceValue>>cityValue)) return "{\"error\":\"invalid_world_command\"}";
        if(!mBoard) return "{\"error\":\"city_not_loaded\"}";
        mBoard->waitUntilFinished();
        const auto city=worldCity(index); const auto pid=mBoard->personPlayer(); const auto cid=static_cast<eCityId>(cityValue);
        if(!city) return "{\"error\":\"unknown_city\"}";
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        if(mBoard->cityIdToPlayerId(cid)!=pid || !eVectorHelpers::contains(mBoard->personPlayerCitiesOnBoard(),cid)) return "{\"error\":\"not_owned\"}";
        if(!city->visible() || city->type()==eCityType::distantCity || city->isCurrentCity() || city->isOnBoardColony() || city->isOnBoardNeutral()) return "{\"error\":\"world_dealings_unavailable\"}";
        if(city->attitude(pid)<=50 && !city->isRival()) return "{\"error\":\"not_regarded\"}";
        const auto resource=static_cast<eResourceType>(resourceValue);
        bool offered=resource==eResourceType::drachmas;
        for(const auto& trade:city->sells()) offered=offered || trade.fType==resource;
        if(!offered) return "{\"error\":\"not_offered\"}";
        mBoard->request(city,resource,cid);
        return worldInfo();
    } else if(action=="world_gift") {
        // world_gift <city index> <resource> <count> <city that gives>
        int index,resourceValue,count,cityValue; if(!(in>>index>>resourceValue>>count>>cityValue)) return "{\"error\":\"invalid_world_command\"}";
        if(!mBoard) return "{\"error\":\"city_not_loaded\"}";
        mBoard->waitUntilFinished();
        const auto city=worldCity(index); const auto pid=mBoard->personPlayer(); const auto cid=static_cast<eCityId>(cityValue);
        if(!city) return "{\"error\":\"unknown_city\"}";
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        if(mBoard->cityIdToPlayerId(cid)!=pid || !eVectorHelpers::contains(mBoard->personPlayerCitiesOnBoard(),cid)) return "{\"error\":\"not_owned\"}";
        if(!city->visible() || city->type()==eCityType::distantCity || city->isCurrentCity() || city->isOnBoardColony() || city->isOnBoardNeutral()) return "{\"error\":\"world_dealings_unavailable\"}";
        const auto resource=static_cast<eResourceType>(resourceValue);
        const int step=eGiftHelpers::giftCount(resource);
        if(step<=0 || count<step || count>3*step || count%step) return "{\"error\":\"invalid_gift\"}";
        if(!mBoard->giftTo(city,resource,count,cid)) return "{\"error\":\"not_enough_goods\"}";
        mBoard->updateResources(cid);
        return worldInfo();
    } else if(action=="world_fulfil") {
        // world_fulfil <request id> <city that sends the goods>
        int id,cityValue; if(!(in>>id>>cityValue)) return "{\"error\":\"invalid_world_command\"}";
        if(!mBoard) return "{\"error\":\"city_not_loaded\"}";
        mBoard->waitUntilFinished();
        const auto pid=mBoard->personPlayer(); const auto cid=static_cast<eCityId>(cityValue);
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        const auto requests=mBoard->cityRequests(pid);
        if(id<0 || id>=int(requests.size())) return "{\"error\":\"unknown_request\"}";
        if(mBoard->cityIdToPlayerId(cid)!=pid || !eVectorHelpers::contains(mBoard->personPlayerCitiesOnBoard(),cid)) return "{\"error\":\"not_owned\"}";
        const auto request=requests[id];
        if(mBoard->resourceCount(cid,request->resourceType())<request->count()) return "{\"error\":\"not_enough_goods\"}";
        request->dispatch(cid);
        return worldInfo();
    } else if(action=="preview_path" || action=="build_path") {
        std::string name; int x1,y1,x2,y2; if(!(in>>name>>x1>>y1>>x2>>y2)) return "{\"error\":\"invalid_preview\"}";
        if(action=="preview_path") return pathCommand(name,x1,y1,x2,y2,false);
        const auto result=pathCommand(name,x1,y1,x2,y2,true);
        return result.empty()?snapshot():result;
    } else if(action=="preview_area") {
        std::string name; int x1,y1,x2,y2; if(!(in>>name>>x1>>y1>>x2>>y2)) return "{\"error\":\"invalid_preview\"}";
        return areaPreview(name,x1,y1,x2,y2);
    } else if(action=="preview_wall") {
        int x1,y1,x2,y2,fill=0; if(!(in>>x1>>y1>>x2>>y2)) return "{\"error\":\"invalid_preview\"}";
        in>>fill;
        return wallPreview(x1,y1,x2,y2,fill!=0);
    } else if(action=="inspect") {
        int x,y; if(!(in>>x>>y)) return "{\"error\":\"invalid_inspection\"}";
        return inspect(x,y);
    } else if(action=="trade") {
        // trade x y token resource direction(0 import, 1 export) enabled quota
        int x,y,resourceValue,direction,enabled,quota; uint64_t token;
        if(!(in>>x>>y>>token>>resourceValue>>direction>>enabled>>quota)) return "{\"error\":\"invalid_building_control\"}";
        in>>std::ws; if(!in.eof()) return "{\"error\":\"invalid_building_control\"}";
        mBoard->waitUntilFinished();
        if(x<mX || y<mY || x>=mX+mW || y>=mY+mH) return "{\"error\":\"out_of_map\"}";
        const auto t=mBoard->tile(x,y); const auto b=t?t->underBuilding():nullptr;
        if(!b || token!=mInspectionToken || mInspectionTarget.get()!=b || b->deleteScheduled()) return "{\"error\":\"inspection_target_changed\"}";
        if(b->playerId()!=mBoard->personPlayer() || mBoard->cityIdToPlayerId(t->cityId())!=mBoard->personPlayer()) return "{\"error\":\"not_owned\"}";
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        const auto post=dynamic_cast<eTradePost*>(b);
        if(!post) return "{\"error\":\"unsupported_resource\"}";
        if(resourceValue<=0 || resourceValue>int(eResourceType::drachmas) || (resourceValue & (resourceValue-1)) || (direction!=0 && direction!=1) || (enabled!=0 && enabled!=1))
            return "{\"error\":\"invalid_resource\"}";
        const auto resource=static_cast<eResourceType>(resourceValue);
        bool tradable=false;
        if(direction==0) { for(const auto& item:post->city().sells()) tradable=tradable||item.fType==resource; tradable=tradable && !post->playerTwoWay(); }
        else if(post->playerTwoWay()) tradable=static_cast<bool>(eResourceType::allBasic & resource);
        else for(const auto& item:post->city().buys()) tradable=tradable||item.fType==resource;
        if(!tradable) return "{\"error\":\"unsupported_resource\"}";
        const int step=resource==eResourceType::sculpture?1:4;
        if(quota<0 || quota>step*post->spaceCount() || quota%step) return "{\"error\":\"invalid_storage_order\"}";
        eResourceType imports,exports; post->getOrders(imports,exports);
        auto& mask=direction==0?imports:exports;
        mask=enabled?(mask|resource):(mask & ~resource);
        post->setOrders(imports,exports);
        post->setMaxCount({{resource,quota}});
    } else if(action=="storage" || action=="industry") {
        int x,y,resourceValue,order,limit=0; uint64_t token;
        if(!(in>>x>>y>>token>>resourceValue>>order) || (action=="storage" && !(in>>limit))) return "{\"error\":\"invalid_building_control\"}";
        in>>std::ws; if(!in.eof()) return "{\"error\":\"invalid_building_control\"}";
        mBoard->waitUntilFinished();
        if(x<mX || y<mY || x>=mX+mW || y>=mY+mH) return "{\"error\":\"out_of_map\"}";
        const auto t=mBoard->tile(x,y); const auto b=t?t->underBuilding():nullptr;
        if(!b || token!=mInspectionToken || mInspectionTarget.get()!=b || b->deleteScheduled()) return "{\"error\":\"inspection_target_changed\"}";
        if(b->playerId()!=mBoard->personPlayer() || mBoard->cityIdToPlayerId(t->cityId())!=mBoard->personPlayer()) return "{\"error\":\"not_owned\"}";
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        if(b->isOnFire()) return "{\"error\":\"building_on_fire\"}";
        if(resourceValue<=0 || resourceValue>int(eResourceType::drachmas) || (resourceValue & (resourceValue-1))) return "{\"error\":\"invalid_resource\"}";
        const auto resource=static_cast<eResourceType>(resourceValue);
        if(action=="storage") {
            const auto storage=dynamic_cast<eStorageBuilding*>(b);
            if(!storage || !storage->canAccept(resource)) return "{\"error\":\"unsupported_resource\"}";
            const int step=resource==eResourceType::sculpture?1:4;
            if(order<0 || order>3 || limit<0 || limit>step*storage->spaceCount() || limit%step) return "{\"error\":\"invalid_storage_order\"}";
            auto get=storage->get() & ~resource; auto empty=storage->empties() & ~resource; auto accept=storage->accepts() & ~resource;
            if(order==1) accept=accept|resource;
            if(order==2) get=get|resource;
            if(order==3) empty=empty|resource;
            storage->setOrders(get,empty,accept);
            storage->setMaxCount({{resource,limit}});
        } else {
            const auto industries=eIndustryHelpers::sIndustries(b->type());
            if(std::find(industries.begin(),industries.end(),resource)==industries.end()) return "{\"error\":\"unsupported_industry\"}";
            if(order!=0 && order!=1) return "{\"error\":\"invalid_building_control\"}";
            // Match the native workforce panel: shutdown affects this city's industry.
            if(mBoard->isShutDown(b->cityId(),resource)!=bool(order)) {
                if(order) mBoard->addShutDown(b->cityId(),resource);
                else mBoard->removeShutDown(b->cityId(),resource);
            }
        }
    } else if(action=="undo") {
        mBoard->waitUntilFinished();
        if(!undoAvailable()) return "{\"error\":\"undo_unavailable\"}";
        eBuildingsToErase eraser;
        for(const auto& b:mUndoBuildings) if(b && !b->deleteScheduled() && !b->isOnFire()) eraser.addBuilding(b.get());
        eraser.erase(true);
        mBoard->incDrachmas(mBoard->personPlayer(),mUndoRefund,eFinanceTarget::construction);
        mBoard->scheduleTerrainUpdate(); mUndoBuildings.clear(); mUndoRefund=0;
    } else if(action=="demolish") {
        int x,y,confirmed; uint64_t token=0;
        if(!(in>>x>>y>>confirmed) || (confirmed!=0 && confirmed!=1)) return "{\"error\":\"invalid_demolition\"}";
        in>>token;
        mBoard->waitUntilFinished();
        auto t=mBoard->tile(x,y); const auto pid=mBoard->personPlayer();
        if(!t || mBoard->cityIdToPlayerId(t->cityId())!=pid) return "{\"error\":\"not_owned\"}";
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        if(mBoard->drachmas(pid)<-1000) return "{\"error\":\"insufficient_funds\"}";
        const int cost=eDifficultyHelpers::buildingCost(mBoard->difficulty(pid),eBuildingType::erase);
        auto b=eBuildingsToErase::target(t->underBuilding());
        if(b) {
            if(b->isOnFire()) return "{\"error\":\"on_fire\"}";
            if(b->playerId()!=pid) return "{\"error\":\"not_owned\"}";
            eBuildingsToErase eraser; eraser.addBuilding(b);
            if(eraser.hasImportantBuildings() || eraser.hasNonEmptyAgoras()) {
                if(!confirmed) return "{\"error\":\"confirmation_required\"}";
                if(token!=mDemolitionToken || mDemolitionTarget.get()!=b) return "{\"error\":\"demolition_target_changed\"}";
            }
            const int count=eraser.erase(true);
            mBoard->incDrachmas(pid,-cost*count,eFinanceTarget::construction);
        } else if(t->terrain()==eTerrain::forest || t->terrain()==eTerrain::choppedForest) {
            t->setTerrain(eTerrain::dry);
            if(auto city=mBoard->boardCityWithId(t->cityId())) city->incForestsState();
            mBoard->incDrachmas(pid,-cost,eFinanceTarget::construction);
        } else return "{\"error\":\"nothing_to_demolish\"}";
        mBoard->scheduleTerrainUpdate(); mUndoBuildings.clear(); mUndoRefund=0;
    } else if(action=="build") {
        std::string name; int x,y,orientation,partner=-1;
        if(!(in>>name>>x>>y>>orientation) || orientation<0 || orientation>(name=="hippodrome"?7:3)) return "{\"error\":\"invalid_build\"}";
        in>>partner;
        const auto found=buildSpecs.find(name); auto t=mBoard->tile(x,y);
        if(found==buildSpecs.end() || !t) return "{\"error\":\"unsupported_build\"}";
        mBoard->waitUntilFinished();
        const auto& spec=found->second; const auto cid=t->cityId(); const auto pid=mBoard->personPlayer();
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        if(!mBoard->supportsBuilding(cid,spec.mode)) return "{\"error\":\"building_not_available\"}";
        if(mBoard->drachmas(pid)<-1000) return "{\"error\":\"insufficient_funds\"}";
        if(spec.kind!=Kind::standard && mBoard->cityIdToPlayerId(cid)!=pid) return "{\"error\":\"not_owned\"}";
        eGameBoard::eBuildingCreator factory=[&]() { return spec.make(*mBoard,cid); };
        const int before=mBoard->drachmas(pid);
        mBoard->startRecordingBuilt();
        bool built=false, heroHall=false;
        if(spec.kind==Kind::agora) {
            // The same search as the preview: the road strip and the free ground beside it are found from the tile.
            eAgoraOrientation lay=eAgoraOrientation::bottomRight;
            const auto sites=eAgoraPlacement::find(*mBoard,t,spec.grand,lay,cid,pid,false);
            if(!sites.empty()) {
                eAgoraPlacement::build(*mBoard,sites,spec.grand,lay,cid);
                mBoard->incDrachmas(pid,-eDifficultyHelpers::buildingCost(mBoard->difficulty(pid),spec.type),eFinanceTarget::construction);
                built=true;
            }
        } else if(spec.kind==Kind::trade) {
            const auto chosen=tradePartner(cid,partner,name=="pier");
            if(!chosen) return "{\"error\":\"trade_partner_unavailable\"}";
            if(name=="trade_post") {
                eGameBoard::eBuildingCreator post=[&]() { return e::make_shared<eTradePost>(*mBoard,*chosen->city,cid); };
                built=mBoard->buildBase(x,y,x+3,y+3,post,pid,cid,false,false,false);
            } else {
                eDiagonalOrientation lay=eDiagonalOrientation::topLeft;
                if(eShorePlacement::canBuildPier(*mBoard,x,y+1,lay,cid,pid,false) && eShorePlacement::pierHasSeaAccess(*mBoard,x,y+1,cid))
                    built=eShorePlacement::placePier(*mBoard,x,y+1,lay,*chosen->city,cid,pid,false);
            }
        } else if(spec.kind==Kind::gate) {
            // The native gatehouse case: two 2x2 blocks and the passage between them are checked, the gatehouse takes
            // all ten tiles and the two passage tiles become road under it. A street already there is kept.
            const bool turned=orientation%2==1; const int w=turned?2:5, h=turned?5:2;
            bool fits=true;
            for(int dx=0;dx<w && fits;++dx) for(int dy=0;dy<h && fits;++dy) fits=gateReason(x+dx,y+dy,turned?dy==2:dx==2,cid,pid).empty();
            if(fits) {
                const auto gate=e::make_shared<eGatehouse>(*mBoard,turned,cid);
                gate->setTileRect({x,y,w,h});
                for(int dx=0;dx<w;++dx) for(int dy=0;dy<h;++dy) {
                    const auto tile=mBoard->tile(x+dx,y+dy);
                    const bool passage=turned?dy==2:dx==2;
                    gate->addUnderBuilding(tile);
                    if(!passage) { tile->setUnderBuilding(gate); gate->setCenterTile(tile); continue; }
                    if(tile->hasRoad()) { static_cast<eRoad*>(tile->underBuilding())->setUnderGatehouse(gate.get()); continue; }
                    const auto street=e::make_shared<eRoad>(*mBoard,cid);
                    street->setTileRect({tile->x(),tile->y(),1,1});
                    street->setUnderGatehouse(gate.get());
                    street->addUnderBuilding(tile);
                    tile->setUnderBuilding(street);
                    street->setCenterTile(tile);
                }
                mBoard->incDrachmas(pid,-eDifficultyHelpers::buildingCost(mBoard->difficulty(pid),eBuildingType::gatehouse),eFinanceTarget::construction);
                built=true;
            }
        } else if(spec.kind==Kind::sanctuary) {
            // The SDL rules: a limit on the sanctuaries of a city, the marble in the city's storage, a layout centred on the pointer.
            const bool turned=orientation%2==1;
            const auto* layout=eSanctBlueprints::sSanctuaryBlueprint(spec.type,turned);
            if(!layout) return "{\"error\":\"unsupported_build\"}";
            if(int(mBoard->sanctuaries(cid).size())>=mBoard->maxSanctuaries(cid)) return "{\"error\":\"max_sanctuaries\"}";
            if(mBoard->resourceCount(cid,eResourceType::marble)<eBuilding::sInitialMarbleCost(spec.type)) return "{\"error\":\"need_marble\"}";
            const int minX=x-layout->fW/2, minY=y-layout->fH/2;
            built=mBoard->buildSanctuary(minX,minX+layout->fW,minY,minY+layout->fH,spec.type,turned,cid,pid,false);
        } else if(spec.kind==Kind::pyramid) {
            // The engine's own buildPyramid: the pyramid centred on the pointer; its marble, wood and sculpture come in by cart as it is built.
            const int minX=x-spec.w/2, minY=y-spec.h/2;
            built=mBoard->buildPyramid(minX,minX+spec.w,minY,minY+spec.h,spec.type,false,cid,pid,false);
        } else if(spec.kind==Kind::palace) {
            if(mBoard->hasPalace(cid)) return "{\"error\":\"palace_exists\"}";
            if(mBoard->hasActiveInvasions(cid)) return "{\"error\":\"enemy_near\"}";
            built=eBuildPlacement::buildPalace(*mBoard,x,y,orientation%2==1,cid,pid,false);
        } else if(spec.kind==Kind::stadium) {
            if(mBoard->hasStadium(cid)) return "{\"error\":\"stadium_exists\"}";
            built=eBuildPlacement::buildStadium(*mBoard,x,y,orientation%2==1,cid,pid,false);
        } else if(spec.kind==Kind::ranch) {
            built=eBuildPlacement::buildHorseRanch(*mBoard,x,y,orientation,cid,pid,false);
        } else if(spec.kind==Kind::godMonument) {
            built=eBuildPlacement::buildGodMonument(*mBoard,x,y,static_cast<eGodType>(spec.variant),cid,pid,false);
            // As the SDL view does, the monument uses up the scenario's grant.
            if(built) mBoard->built(cid,eBuildingType::godMonument,spec.variant);
        } else if(spec.kind==Kind::shore) {
            const bool wharf=spec.type==eBuildingType::triremeWharf;
            const int tx=wharf?x+1:x, ty=y+1; eDiagonalOrientation lay=eDiagonalOrientation::topLeft;
            const bool fits=wharf?eBuildPlacement::canBuildTriremeWharf(*mBoard,tx,ty,lay):eShorePlacement::canBuildFishery(*mBoard,tx,ty,lay);
            if(fits && (!wharf || eBuildPlacement::triremeWharfSeaAccess(*mBoard,tx,ty,cid))) {
                eBuildPlacement::placeShoreBuilding(*mBoard,spec.type,tx,ty,lay,cid,pid,false);
                built=true;
            }
        } else if(spec.kind==Kind::bridge) {
            std::vector<eTile*> path; bool turned=false;
            if(eBuildPlacement::bridgeTiles(t,eTerrain::water,path,turned) || eBuildPlacement::bridgeTiles(t,eTerrain::quake,path,turned)) {
                eBuildPlacement::buildBridge(*mBoard,path,cid,pid,false);
                mBoard->scheduleTerrainUpdate();
                built=true;
            }
        } else if(spec.kind==Kind::roadblock) {
            built=eBuildPlacement::placeRoadblock(t);
        } else if(spec.kind==Kind::hippodrome) {
            const int tx=x+1, ty=y+2;
            const auto ids=eBuildPlacement::hippodromePieceIds(*mBoard,cid,tx,ty);
            if(ids.empty()) return "{\"error\":\"no_hippodrome_fit\"}";
            built=eBuildPlacement::buildHippodromePiece(*mBoard,tx,ty,ids[size_t(orientation)%ids.size()],cid,pid,false);
        } else if(spec.kind==Kind::crosswalk) {
            built=eBuildPlacement::buildCrosswalk(*mBoard,x,y,cid,pid,false);
        } else if(spec.kind==Kind::commemorative) {
            built=mBoard->buildBase(x,y,x+spec.w-1,y+spec.h-1,factory,pid,cid,false,false,false);
            if(built) mBoard->built(cid,eBuildingType::commemorative,spec.variant);
        } else if(spec.kind==Kind::waterPark) {
            // The SDL view picks one of its variants with the turn of the view; here the turn chosen with T does.
            eGameBoard::eBuildingCreator park=[&]() { const auto b=e::make_shared<eWaterPark>(*mBoard,cid); b->setId(orientation); return b; };
            built=mBoard->buildBase(x,y,x+spec.w-1,y+spec.h-1,park,pid,cid,false,false,false);
        } else if(spec.kind==Kind::animal) {
            if(mBoard->countAllowed(cid,spec.type)<=0) return "{\"error\":\"animal_limit\"}";
            built=placeAnimal(*mBoard,spec.type,t,cid,pid);
        } else if(spec.kind==Kind::path) {
            // A click is a path of one tile, recorded by the path command itself.
            int ignored=0; mBoard->stopRecordingBuilt(ignored);
            const auto result=pathCommand(name,x,y,x,y,true);
            return result.empty()?snapshot():result;
        } else if(spec.kind==Kind::vendor) {
            // Any tile of the space picks it; the native rule names the space by its centre tile.
            auto* const space=eAgoraPlacement::spaceAt(*mBoard,x,y);
            const auto centre=space?space->centerTile():nullptr;
            if(centre) built=eAgoraPlacement::placeVendor(*mBoard,centre->x(),centre->y(),spec.resource,cid,
                [&](eGameBoard& b,const eCityId c) -> stdsptr<eVendor> { return std::static_pointer_cast<eVendor>(spec.make(b,c)); });
        } else {
            built=mBoard->buildBase(x,y,x+spec.w-1,y+spec.h-1,factory,pid,cid,false,spec.fertile,spec.flat);
        }
        int erased=0; const auto created=mBoard->stopRecordingBuilt(erased);
        if(!built) return "{\"error\":\"native_placement_rejected\"}";
        // The SDL view records a hero's hall as built (its mode is then no longer offered for that hero).
        eHerosHall::sHallTypeToHeroType(spec.type,&heroHall);
        if(heroHall) mBoard->built(cid,spec.type);
        // The SDL view answers every construction but a road with the building sound.
        // (The SDL view stays silent for roadblocks, bridges and crosswalks.)
        if(spec.type!=eBuildingType::road && spec.kind!=Kind::roadblock && spec.kind!=Kind::bridge && spec.kind!=Kind::crosswalk) eSounds::playPlaceBuildingSound();
        mUndoBuildings.clear();
        for(auto b:created) {
            mUndoBuildings.emplace_back(b);
            if((spec.kind==Kind::standard || spec.kind==Kind::commemorative || spec.kind==Kind::waterPark) && name!="road" && name!="wall") mOrientations[b]=orientation;
        }
        mUndoRefund=std::max(0,before-mBoard->drachmas(pid));
        mUndoGameTime=mBoard->totalTime(); mUndoRealTime=std::chrono::steady_clock::now();
        // Founding a sanctuary also takes marble from the stores, which an undo would not give back: it is not undoable.
        // Nor is a monument a scenario granted (its grant is used up) or a crosswalk (it changes the plate under it).
        if(erased || spec.kind==Kind::sanctuary || spec.kind==Kind::pyramid || spec.kind==Kind::commemorative || spec.kind==Kind::godMonument ||
           spec.kind==Kind::crosswalk) mUndoBuildings.clear();
    } else if(action=="build_area") {
        std::string name; int x1,y1,x2,y2,orientation=0;
        if(!(in>>name>>x1>>y1>>x2>>y2)) return "{\"error\":\"invalid_build\"}";
        in>>orientation; if(orientation<0 || orientation>3) orientation=0;
        const auto found=buildSpecs.find(name);
        if(found==buildSpecs.end() || !areaTool(name)) return "{\"error\":\"unsupported_build\"}";
        mBoard->waitUntilFinished();
        const auto& spec=found->second;
        const auto start=(x1>=mX && y1>=mY && x1<mX+mW && y1<mY+mH)?mBoard->tile(x1,y1):nullptr;
        if(!start) return "{\"error\":\"out_of_map\"}";
        const auto pid=mBoard->personPlayer();
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        if(!mBoard->supportsBuilding(start->cityId(),spec.mode)) return "{\"error\":\"building_not_available\"}";
        if(mBoard->drachmas(pid)<-1000) return "{\"error\":\"insufficient_funds\"}";
        const int before=mBoard->drachmas(pid);
        mBoard->startRecordingBuilt();
        int built=0;
        for(const auto& cell:areaCells(name,x1,y1,x2,y2)) {
            if(fundsEachTile(name) && mBoard->drachmas(pid)<-1000) break;
            const auto tile=(cell.first>=mX && cell.second>=mY && cell.first<mX+mW && cell.second<mY+mH)?mBoard->tile(cell.first,cell.second):nullptr;
            if(!tile) continue;
            const auto cid=tile->cityId();
            if(spec.kind==Kind::animal) {
                // The SDL rule: once the city's sheds (dairies, corrals) allow no more, the rest of the drag is skipped.
                if(mBoard->countAllowed(cid,spec.type)<=0) break;
                if(placeAnimal(*mBoard,spec.type,tile,cid,pid)) ++built;
                continue;
            }
            eGameBoard::eBuildingCreator factory=[&]() { return spec.make(*mBoard,cid); };
            if(mBoard->buildBase(cell.first,cell.second,cell.first+spec.w-1,cell.second+spec.h-1,factory,pid,cid,false,spec.fertile,spec.flat)) ++built;
        }
        int erased=0; const auto created=mBoard->stopRecordingBuilt(erased);
        if(!built) return "{\"error\":\"native_placement_rejected\"}";
        if(name=="park") mBoard->scheduleTerrainUpdate();
        eSounds::playPlaceBuildingSound();
        // One undo step covers the whole drag.
        mUndoBuildings.clear();
        for(auto b:created) { mUndoBuildings.emplace_back(b); mOrientations[b]=orientation; }
        mUndoRefund=std::max(0,before-mBoard->drachmas(pid));
        mUndoGameTime=mBoard->totalTime(); mUndoRealTime=std::chrono::steady_clock::now();
        if(erased) mUndoBuildings.clear();
    } else if(action=="build_wall") {
        int x1,y1,x2,y2,fill=0;
        if(!(in>>x1>>y1>>x2>>y2)) return "{\"error\":\"invalid_build\"}";
        in>>fill;
        mBoard->waitUntilFinished();
        const auto start=(x1>=mX && y1>=mY && x1<mX+mW && y1<mY+mH)?mBoard->tile(x1,y1):nullptr;
        if(!start) return "{\"error\":\"out_of_map\"}";
        const auto pid=mBoard->personPlayer();
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        if(!mBoard->supportsBuilding(start->cityId(),eBuildingMode::wall)) return "{\"error\":\"building_not_available\"}";
        if(mBoard->drachmas(pid)<-1000) return "{\"error\":\"insufficient_funds\"}";
        const int before=mBoard->drachmas(pid);
        mBoard->startRecordingBuilt();
        int built=0;
        for(auto* tile:wallTiles(x1,y1,x2,y2,fill!=0)) {
            if(mBoard->drachmas(pid)<-1000) break;
            const auto cid=tile->cityId();
            eGameBoard::eBuildingCreator factory=[&]() { return e::make_shared<eWall>(*mBoard,cid); };
            if(mBoard->buildBase(tile->x(),tile->y(),tile->x(),tile->y(),factory,pid,cid,false,false,false)) ++built;
        }
        int erased=0; const auto created=mBoard->stopRecordingBuilt(erased);
        if(!built) return "{\"error\":\"native_placement_rejected\"}";
        eSounds::playPlaceBuildingSound();
        // One undo step covers the whole drag.
        mUndoBuildings.clear();
        for(auto b:created) mUndoBuildings.emplace_back(b);
        mUndoRefund=std::max(0,before-mBoard->drachmas(pid));
        mUndoGameTime=mBoard->totalTime(); mUndoRealTime=std::chrono::steady_clock::now();
        if(erased) mUndoBuildings.clear();
    } else if(action=="build_road") {
        int x1,y1,x2,y2;
        if(!(in>>x1>>y1>>x2>>y2)) return "{\"error\":\"invalid_build\"}";
        mBoard->waitUntilFinished();
        const auto start=(x1>=mX && y1>=mY && x1<mX+mW && y1<mY+mH)?mBoard->tile(x1,y1):nullptr;
        if(!start) return "{\"error\":\"out_of_map\"}";
        const auto cid=start->cityId(); const auto pid=mBoard->personPlayer();
        if(mBlocked) return "{\"error\":\"pending_decision\"}";
        if(!mBoard->supportsBuilding(cid,eBuildingMode::road)) return "{\"error\":\"building_not_available\"}";
        if(mBoard->drachmas(pid)<-1000) return "{\"error\":\"insufficient_funds\"}";
        std::vector<eTile*> tiles;
        if(!roadPath(x1,y1,x2,y2,tiles)) return "{\"error\":\"no_path\"}";
        eGameBoard::eBuildingCreator factory=[&]() { return e::make_shared<eRoad>(*mBoard,cid); };
        const int before=mBoard->drachmas(pid);
        mBoard->startRecordingBuilt();
        int built=0;
        for(auto* tile:tiles) {
            bool old=false;
            if(!roadReason(tile,static_cast<int>(cid),old).empty() || old) continue;
            if(mBoard->drachmas(pid)<-1000) break;
            if(mBoard->buildBase(tile->x(),tile->y(),tile->x(),tile->y(),factory,pid,cid,false,false,true)) ++built;
        }
        int erased=0; const auto created=mBoard->stopRecordingBuilt(erased);
        if(!built) return "{\"error\":\"native_placement_rejected\"}";
        // One undo step covers the whole drag.
        mUndoBuildings.clear();
        for(auto b:created) mUndoBuildings.emplace_back(b);
        mUndoRefund=std::max(0,before-mBoard->drachmas(pid));
        mUndoGameTime=mBoard->totalTime(); mUndoRealTime=std::chrono::steady_clock::now();
        if(erased) mUndoBuildings.clear();
    } else return "{\"error\":\"unsupported_command\"}";
    return snapshot();
}
