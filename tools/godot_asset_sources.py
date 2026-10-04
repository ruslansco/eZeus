"""Geometry export recipes. Names are presentation IDs, never save-file enums."""
PEOPLE = ['grower','shepherd','trader','porter','hunter','marbleminer','lumberjack',
          'bronzeminer','artisan','scholar','astronomer','inventor','curator',
          'taxcollector','watchman','waterdistributor','firefighter','aphrodite','theseus',
          'oxhandler','peddler','sick','gymnast','actor','competitor','orangetender','urchin','archer',
          'archerposeidon','hopliteposeidon','greekhoplite','greekrockthrower','greekhorseman','chariotposeidon',
          'hoplite','rockthrower','horseman',
          'trojanhoplite','trojanspearthrower','trojanhorseman','centaurhorseman','centaurarcher',
          'persianhoplite','persianarcher','persianhorseman','oceanidhoplite','oceanidspearthrower',
          'egyptianhoplite','egyptianarcher','egyptianchariot','atlanteanhoplite','atlanteanarcher','atlanteanchariot',
          'phoenicianhorseman','phoenicianarcher','mayanhoplite','mayanarcher','amazonspear','amazonarcher','areswarrior']
GODS = ['apollo','ares','artemis','athena','atlas','demeter','dionysus','hades','hephaestus','hera','hermes','poseidon','zeus']
HEROES = ['achilles','atalanta','hercules','jason','odysseus','perseus','bellerophon']
# Monsters. The person-based ones (a man, a woman, a pair of harpies) go through the natural-people adapter like the soldiers; the beasts and the
# sea monsters are built on the animal kit and are exported like animals: no character manifest, a larger vertex allowance.
MONSTER_PEOPLE = ['cyclops','talos','hector','minotaur','satyr','medusa','maenads','harpies']
MONSTER_BEASTS = ['calydonianboar','cerberus','chimera','sphinx','hydra','dragon','echidna','scylla','kraken']
# The priestess of a sanctuary's altar (art/characters/people/people11.py): shown with a rite on the altar, never walking the city.
RITE_PEOPLE = ['priestess']
# The Greek war chariot, the hippodrome's four racing teams and the silver and orichalc miners (3 October).
RACERS = ['racechariot0','racechariot1','racechariot2','racechariot3']
PEOPLE += ['greekchariot','silverminer','orichalcminer'] + RACERS
PEOPLE += GODS + HEROES + MONSTER_PEOPLE + RITE_PEOPLE
CREATURES = MONSTER_BEASTS
# Soldiers (the player's, the allies' and every invading nationality): their models also carry the fight, fight2 and die clips of
# the people kit as shape keys (see export_godot_pilot.py), which bake_walker_vat.py turns into poses the presentation plays.
COMBAT = ['archer','archerposeidon','hopliteposeidon','chariotposeidon','greekhoplite','greekrockthrower','greekhorseman',
          'hoplite','rockthrower','horseman',
          'trojanhoplite','trojanspearthrower','trojanhorseman','centaurhorseman','centaurarcher',
          'persianhoplite','persianarcher','persianhorseman','oceanidhoplite','oceanidspearthrower',
          'egyptianhoplite','egyptianarcher','egyptianchariot','atlanteanhoplite','atlanteanarcher','atlanteanchariot',
          'phoenicianhorseman','phoenicianarcher','mayanhoplite','mayanarcher','amazonspear','amazonarcher','areswarrior']
# The gods and heroes fight beside them (the gods also bless, vanish and appear); aphrodite and theseus were exported before the clips existed.
COMBAT += ['aphrodite','theseus'] + GODS + HEROES + MONSTER_PEOPLE + MONSTER_BEASTS + RITE_PEOPLE
COMBAT += ['greekchariot']
# Riders, charioteers and centaurs carry their horses: a larger vertex allowance than a person on foot.
MOUNTED = ['walker_' + n for n in ['chariotposeidon','greekhorseman','horseman','trojanhorseman','centaurhorseman','centaurarcher',
                                    'persianhorseman','egyptianchariot','atlanteanchariot','phoenicianhorseman','bellerophon',
                                    'greekchariot'] + RACERS]
DECORATIONS = ['hedge_maze','fish_pond','shell_garden','sundial','dolphin','orrery','spring','topiary','stone_circle',
               'bench','birdbath','short_obelisk','tall_obelisk','flower_garden','gazebo','water_park']
STANDARD = ['bibliotheke','observatory','university','laboratory','inventors_workshop','museum',
            'hunting_lodge','fishery','carding_shed','growers_lodge','orange_tenders_lodge',
            'trade_post','harbour','timber_mill','masonry_shop','foundry','winery',
            'sculpture_studio','artisans_guild','palace','park','baths','refinery','black_marble_workshop']
RECIPES = {n:(f'art/{n}/build_sprites.py',[]) for n in STANDARD}
# Native park records are 1x1 cells; select a full-height module instead of
# exporting the source loop's last 3x3 tholos and shrinking it into every tile.
RECIPES['park'] = ('art/park/build_sprites.py', ['--only', 'pine'])
RECIPES.update({f'deco_{n}':('art/decorations/build_sprites.py',['--kind',n]) for n in DECORATIONS})
RECIPES.update({f'{n}_vendor':('art/agora/build_stall.py',['--kind',n]) for n in ['food','fleece','oil','wine','arms','horse','chariot']})
RECIPES.update({f'hero_hall_{n}':('art/hero_hall/build_sprites.py',['--hero',n]) for n in ['achilles','atalanta','bellerophon','hercules','jason','odysseus','perseus','theseus']})
RECIPES.update({f'commemorative_{n}':('art/commemorative/build_sprites.py',['--id',str(n)]) for n in range(9)})
RECIPES.update({f'{n}_{s}':('art/orchard/build_sprites.py',['--only',f'{n}_{s}']) for n in ['olive','orange','vine'] for s in range(6)})
RECIPES.update({f'wall_{s}':('art/walls/build_sprites.py',['--only',str(s)]) for s in range(16)})
RECIPES.update({f'palace_tile_{n}':('art/palace_tiles/build_tiles.py',[]) for n in ['plain','lamp']})
RECIPES.update({f'sanctuary_court_{n}':('art/sanctuary_court/build_tiles.py',[]) for n in range(6)})
RECIPES.update({f'sanctuary_temple_{n}':('art/sanctuary_temple/build_sprites.py',[]) for n in range(4)})
RECIPES.update({f'sanctuary_{kind}_{god}':('art/sanctuary_statues/build_sprites.py',['--god',god]+(['--monument'] if kind=='monument' else [])) for kind in ['statue','monument'] for god in ['aphrodite','apollo','ares','artemis','athena','atlas','demeter','dionysus','hades','hephaestus','hera','hermes','poseidon','zeus']})
RECIPES['sanctuary_altar']=('art/sanctuary_altar/build_sprites.py',[])
RECIPES['tower']=('art/tower/build_sprites.py',[])
RECIPES['gatehouse']=('art/tower/build_sprites.py',['--gate'])
RECIPES['harbour']=('art/harbour/build_sprites.py',['--kind','pier'])
RECIPES.update({f'pyramid_p1_{n}':('art/pyramid/build_sprites.py',['--only',f'p1_{n}']) for n in range(34)})
RECIPES.update({f'pyramid_p2_{n}':('art/pyramid/build_sprites.py',['--only',f'p2_{n}']) for n in range(38)})
RECIPES['farm']=('art/farm/build_sprites.py',['--only','base'])
RECIPES['trailer']=('art/characters/trailer/build_sprites.py',['--only','empty'])
# The rest of the SDL game's build menu (3 October): the stadium (one 10x5 model of both halves), the horse ranch and its paddock,
# the shore buildings, the three honorific columns (the column alone; the architraves between neighbours are not exported) and the
# eight hippodrome plates.
RECIPES['stadium']=('art/stadium/build_sprites.py',[])
RECIPES['horse_ranch']=('art/horse_ranch/build_sprites.py',[])
RECIPES['horse_ranch_enclosure']=('art/enclosure/build_sprites.py',[])
RECIPES['urchin_quay']=('art/urchin_quay/build_sprites.py',[])
RECIPES['trireme_wharf']=('art/harbour/build_sprites.py',['--kind','wharf'])
RECIPES.update({f'column_{k}':('art/columns/build_sprites.py',['--only',k]) for k in ['doric','ionic','corinthian']})
RECIPES.update({f'hippodrome_{k}':('art/hippodrome/build_sprites.py',['--only',str(k)]) for k in range(8)})
RECIPES['roadblock']=('art/roadblock/build_sprites.py',[])
