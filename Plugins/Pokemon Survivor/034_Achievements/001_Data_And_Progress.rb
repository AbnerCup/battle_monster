#===============================================================================
# Pokemon Survivor Achievements - data and progress checks
#===============================================================================
module PokemonSurvivorAchievements
  HUD_DIR = "Graphics/UI/Survivor Game/Menu HUD/Achievement"

  RARITY_NAMES = {
    1 => "Common",
    2 => "Uncommon",
    3 => "Rare",
    4 => "Super Rare",
    5 => "Epic",
    6 => "Legendary",
    7 => "Mythic"
  }

  RARITY_COLORS = {
    1 => Color.new(226, 232, 244),
    2 => Color.new(122, 255, 176),
    3 => Color.new(92, 188, 255),
    4 => Color.new(184, 138, 255),
    5 => Color.new(255, 224, 92),
    6 => Color.new(255, 156, 86),
    7 => Color.new(255, 92, 92)
  }

  ACHIEVEMENTS = [
    { id: :first_run, rarity: 1, name: "First Steps", desc: "Finish any run, won or lost.", group: :run },
    { id: :first_victory, rarity: 2, name: "First Victory", desc: "Win any game mode once.", group: :run },
    { id: :comeback_attempt, rarity: 1, name: "One More Run", desc: "Finish 3 runs in total.", group: :run },
    { id: :habit_forming, rarity: 2, name: "Survivor Habit", desc: "Finish 15 runs in total.", group: :run },
    { id: :run_regular, rarity: 3, name: "Run Regular", desc: "Finish 30 runs in total.", group: :run },
    { id: :run_obsessed, rarity: 4, name: "Just One More", desc: "Finish 50 runs in total.", group: :run },
    { id: :run_marathon, rarity: 5, name: "Survivor Marathon", desc: "Finish 100 runs in total.", group: :run },
    { id: :classic_clear, rarity: 2, name: "Classic Survivor", desc: "Validate a Classic run.", group: :classic },
    { id: :classic_ultra, rarity: 3, name: "Ultra Breaker", desc: "Defeat the Classic Ultra Boss.", group: :classic },
    { id: :classic_three, rarity: 4, name: "Classic Trio", desc: "Validate Classic Mode with 5 different Pokemon.", group: :classic },
    { id: :classic_rotation, rarity: 5, name: "Classic Rotation", desc: "Validate Classic Mode with 10 different Pokemon.", group: :classic },
    { id: :classic_ten, rarity: 6, name: "Classic Specialist", desc: "Validate Classic Mode with 20 different Pokemon.", group: :classic },
    { id: :classic_bulbasaur, rarity: 2, name: "Leafy First Clear", desc: "Validate Classic Mode with Bulbasaur.", group: :classic },
    { id: :classic_cyndaquil, rarity: 2, name: "Flame First Clear", desc: "Validate Classic Mode with Cyndaquil.", group: :classic },
    { id: :classic_mudkip, rarity: 2, name: "Bubble First Clear", desc: "Validate Classic Mode with Mudkip.", group: :classic },
    { id: :rush_clear, rarity: 3, name: "Rush Breaker", desc: "Clear Rush Mode.", group: :rush },
    { id: :rush_three_wins, rarity: 4, name: "Rush Streak", desc: "Clear Rush Mode with 3 different Pokemon.", group: :rush },
    { id: :rush_quick, rarity: 4, name: "Boss Sprint", desc: "Clear Rush Mode in under 12 minutes.", group: :rush },
    { id: :rush_blitz, rarity: 6, name: "Rush Blitz", desc: "Clear Rush Mode in under 10 minutes.", group: :rush },
    { id: :rush_three, rarity: 5, name: "Rush Rotation", desc: "Clear Rush Mode with 8 different Pokemon.", group: :rush },
    { id: :rush_veteran, rarity: 6, name: "Rush Veteran", desc: "Clear Rush Mode with 15 different Pokemon.", group: :rush },
    { id: :tower_floor_10, rarity: 2, name: "First Stair", desc: "Reach floor 10 in Tower Mode.", group: :tower },
    { id: :tower_floor_20, rarity: 2, name: "Steady Climb", desc: "Reach floor 20 in Tower Mode.", group: :tower },
    { id: :tower_floor_30, rarity: 3, name: "First Climb", desc: "Reach floor 30 in Tower Mode.", group: :tower },
    { id: :tower_halfway, rarity: 4, name: "Mid Tower", desc: "Reach floor 25 in Tower Mode.", group: :tower },
    { id: :tower_floor_75, rarity: 5, name: "Upper Tower", desc: "Reach floor 40 in Tower Mode.", group: :tower },
    { id: :tower_floor_90, rarity: 6, name: "Final Gate", desc: "Reach floor 50 in Tower Mode.", group: :tower },
    { id: :tower_clear, rarity: 6, name: "Tower Conqueror", desc: "Clear Tower Mode.", group: :tower },
    { id: :tower_careful, rarity: 5, name: "Careful Climber", desc: "Reach floor 40 in Tower Mode with less than 500 damage taken.", group: :tower },
    { id: :tower_precise, rarity: 7, name: "Untouched Summit", desc: "Clear Tower Mode with less than 1500 damage taken.", group: :tower },
    { id: :endless_entry, rarity: 3, name: "Endless Entry", desc: "Finish an Endless run with at least 100000 score.", group: :endless },
    { id: :endless_5_minutes, rarity: 3, name: "Endless Spark", desc: "Survive 5 minutes in Endless Mode.", group: :endless },
    { id: :endless_10_minutes, rarity: 4, name: "Endless Pulse", desc: "Survive 10 minutes in Endless Mode.", group: :endless },
    { id: :endless_15_minutes, rarity: 4, name: "Endless Flow", desc: "Survive 15 minutes in Endless Mode.", group: :endless },
    { id: :endless_20_minutes, rarity: 5, name: "Deep Endless", desc: "Survive 20 minutes in Endless Mode.", group: :endless },
    { id: :endless_30_minutes, rarity: 6, name: "Endless Wall", desc: "Survive 30 minutes in Endless Mode.", group: :endless },
    { id: :endless_45_minutes, rarity: 7, name: "Endless Legend", desc: "Survive 45 minutes in Endless Mode.", group: :endless },
    { id: :endless_60_minutes, rarity: 7, name: "Endless Myth", desc: "Survive 60 minutes in Endless Mode.", group: :endless },
    { id: :level_25, rarity: 1, name: "First Growth", desc: "Reach level 25 during a run.", group: :level },
    { id: :level_50, rarity: 1, name: "Getting Warm", desc: "Reach level 50 during a run.", group: :level },
    { id: :level_100, rarity: 3, name: "Limit Broken", desc: "Reach level 100 during a run.", group: :level },
    { id: :level_150, rarity: 4, name: "Beyond Training", desc: "Reach level 150 during a run.", group: :level },
    { id: :level_200, rarity: 4, name: "Power Curve", desc: "Reach level 200 during a run.", group: :level },
    { id: :level_300, rarity: 5, name: "Overlevel Mastery", desc: "Reach level 300 during a run.", group: :level },
    { id: :level_400, rarity: 6, name: "Rainbow Level", desc: "Reach level 400 during a run.", group: :level },
    { id: :level_500, rarity: 7, name: "Level Horizon", desc: "Reach level 500 during a run.", group: :level },
    { id: :level_700, rarity: 7, name: "Level Singularity", desc: "Reach level 700 during a run.", group: :level },
    { id: :score_250k, rarity: 1, name: "Score Seed", desc: "Reach 250000 score during a run.", group: :score },
    { id: :score_500k, rarity: 2, name: "Score Bloom", desc: "Reach 500000 score during a run.", group: :score },
    { id: :score_1m, rarity: 4, name: "Million Spark", desc: "Reach 1000000 score during a run.", group: :score },
    { id: :score_2m, rarity: 4, name: "Double Million", desc: "Reach 2000000 score during a run.", group: :score },
    { id: :score_3m, rarity: 5, name: "Heated Score", desc: "Reach 3000000 score during a run.", group: :score },
    { id: :score_5m, rarity: 6, name: "Score Inferno", desc: "Reach 5000000 score during a run.", group: :score },
    { id: :score_7m, rarity: 6, name: "Score Supernova", desc: "Reach 7000000 score during a run.", group: :score },
    { id: :score_9m, rarity: 7, name: "Rainbow Score", desc: "Reach 9000000 score during a run.", group: :score },
    { id: :leaderboard_open, rarity: 1, name: "Ranking Visitor", desc: "Open the leaderboard.", group: :leaderboard, hidden: true },
    { id: :leaderboard_sort, rarity: 1, name: "Different Angle", desc: "Change the leaderboard sorting once.", group: :leaderboard },
    { id: :leaderboard_my_runs, rarity: 2, name: "My Own Track", desc: "View only your own leaderboard runs.", group: :leaderboard },
    { id: :leaderboard_filter, rarity: 2, name: "Pokemon Lens", desc: "Open the Pokemon leaderboard filter.", group: :leaderboard },
    { id: :leaderboard_first_submit, rarity: 2, name: "Shared Result", desc: "Share one winning run online.", group: :leaderboard },
    { id: :leaderboard_three_submits, rarity: 3, name: "Regular Challenger", desc: "Share 10 winning runs online.", group: :leaderboard },
    { id: :leaderboard_25_submits, rarity: 4, name: "Known Challenger", desc: "Share 25 winning runs online.", group: :leaderboard },
    { id: :leaderboard_classic_submit, rarity: 2, name: "Classic Record", desc: "Share a Classic result online.", group: :leaderboard },
    { id: :leaderboard_rush_submit, rarity: 3, name: "Rush Record", desc: "Share a Rush result online.", group: :leaderboard },
    { id: :leaderboard_tower_submit, rarity: 4, name: "Tower Record", desc: "Share a Tower result online.", group: :leaderboard },
    { id: :leaderboard_endless_submit, rarity: 4, name: "Endless Record", desc: "Share an Endless result online.", group: :leaderboard },
    { id: :leaderboard_mode_set, rarity: 5, name: "All Boards Open", desc: "Share one online result in each game mode.", group: :leaderboard },
    { id: :options_opened, rarity: 1, name: "Careful Tinkerer", desc: "Open the Options menu.", group: :menu },
    { id: :achievements_opened, rarity: 1, name: "Medal Case", desc: "Open the Achievements menu.", group: :menu },
    { id: :kills_500, rarity: 1, name: "Crowd Control", desc: "Defeat 500 enemies during a run.", group: :combat },
    { id: :kills_1000, rarity: 1, name: "Clean Sweep", desc: "Defeat 1000 enemies during a run.", group: :combat },
    { id: :kills_2000, rarity: 2, name: "Swarm Breaker", desc: "Defeat 2000 enemies during a run.", group: :combat },
    { id: :kills_3000, rarity: 3, name: "Wave Cutter", desc: "Defeat 3000 enemies during a run.", group: :combat },
    { id: :kills_5000, rarity: 4, name: "Field Cleaner", desc: "Defeat 5000 enemies during a run.", group: :combat },
    { id: :kills_7000, rarity: 5, name: "Massive Sweep", desc: "Defeat 7000 enemies during a run.", group: :combat },
    { id: :kills_9000, rarity: 6, name: "Total Sweep", desc: "Defeat 9000 enemies during a run.", group: :combat },
    { id: :kills_10000, rarity: 7, name: "Screen Clearer", desc: "Defeat 12000 enemies during a run.", group: :combat },
    { id: :final_form, rarity: 2, name: "True Shape", desc: "Reach a final evolution or final boost during a run.", group: :evolution },
    { id: :alt_hisuian_typhlosion, rarity: 4, name: "Spirit Flame", desc: "Evolve Quilava into Hisuian Typhlosion during a run.", group: :evolution },
    { id: :alt_gallade, rarity: 4, name: "Blade Evolution", desc: "Evolve Kirlia into Gallade during a run.", group: :evolution },
    { id: :alt_alolan_raichu, rarity: 4, name: "Surfing Spark", desc: "Evolve Pikachu into Alolan Raichu during a run.", group: :evolution },
    { id: :alt_hisuian_goodra, rarity: 4, name: "Steel Shell Dragon", desc: "Evolve Goomy through its Hisuian evolution path during a run.", group: :evolution },
    { id: :alt_hisuian_decidueye, rarity: 4, name: "Arrow Stance", desc: "Evolve Dartrix into Hisuian Decidueye during a run.", group: :evolution },
    { id: :alt_forms_3, rarity: 5, name: "Branching Paths", desc: "Discover 3 alternate evolution forms across runs.", group: :evolution },
    { id: :alt_forms_all, rarity: 6, name: "Alternate Specialist", desc: "Discover every current alternate evolution form.", group: :evolution },
    { id: :final_level_100, rarity: 4, name: "Perfect Form", desc: "Reach final form and level 100 in the same run.", group: :evolution },
    { id: :full_build, rarity: 4, name: "No More Choices", desc: "Exhaust every available run bonus during a run.", group: :upgrade },
    { id: :reroll_empty, rarity: 2, name: "New Hand", desc: "Use every reroll during one run.", group: :upgrade },
    { id: :ban_empty, rarity: 2, name: "Strict Draft", desc: "Use every ban during one run.", group: :upgrade },
    { id: :unlock_10, rarity: 3, name: "Growing Roster", desc: "Unlock 15 playable Pokemon.", group: :collection },
    { id: :unlock_25_mid, rarity: 4, name: "Roster Builder", desc: "Unlock 25 playable Pokemon.", group: :collection },
    { id: :unlock_25, rarity: 5, name: "Wide Roster", desc: "Unlock 40 playable Pokemon.", group: :collection },
    { id: :unlock_50, rarity: 5, name: "Big Roster", desc: "Unlock 50 playable Pokemon.", group: :collection },
    { id: :unlock_40, rarity: 6, name: "Packed Selection", desc: "Unlock 60 playable Pokemon.", group: :collection },
    { id: :unlock_70, rarity: 7, name: "Living Selection", desc: "Unlock 70 playable Pokemon.", group: :collection },
    { id: :mew_unlocked, rarity: 6, name: "Mythic Friend", desc: "Unlock Mew.", group: :collection },
    { id: :deoxys_unlocked, rarity: 7, name: "Space Signal", desc: "Unlock Deoxys.", group: :collection },
    { id: :finish_star_1, rarity: 3, name: "First Adventure Badge", desc: "Complete every current Adventure Badge fragment on one Pokemon.", group: :finish },
    { id: :finish_star_3_mid, rarity: 3, name: "Badge Triangle", desc: "Complete every current Adventure Badge fragment on 3 Pokemon.", group: :finish },
    { id: :finish_star_3, rarity: 4, name: "Star Pattern", desc: "Complete every current Adventure Badge fragment on 5 Pokemon.", group: :finish },
    { id: :finish_star_10, rarity: 4, name: "Badge Path", desc: "Complete every current Adventure Badge fragment on 10 Pokemon.", group: :finish },
    { id: :finish_star_7, rarity: 5, name: "Seven Stars", desc: "Complete every current Adventure Badge fragment on 15 Pokemon.", group: :finish },
    { id: :finish_star_11, rarity: 6, name: "Star Collector", desc: "Complete every current Adventure Badge fragment on 30 Pokemon.", group: :finish },
    { id: :finish_star_40, rarity: 6, name: "Badge Archive", desc: "Complete every current Adventure Badge fragment on 40 Pokemon.", group: :finish },
    { id: :finish_star_20, rarity: 7, name: "Constellation", desc: "Complete every current Adventure Badge fragment on 50 Pokemon.", group: :finish },
    { id: :boss_finish_5, rarity: 4, name: "Boss Badge Proof", desc: "Earn the Boss Adventure Badge on 15 Pokemon.", group: :finish },
    { id: :boss_finish_30, rarity: 6, name: "Boss Badge Line", desc: "Earn the Boss Adventure Badge on 30 Pokemon.", group: :finish },
    { id: :rush_finish_5, rarity: 5, name: "Rush Badge Proof", desc: "Earn the Rush Adventure Badge on 15 Pokemon.", group: :finish },
    { id: :tower_finish_3, rarity: 6, name: "Tower Badge Proof", desc: "Earn the Tower Adventure Badge on 10 Pokemon.", group: :finish },
    { id: :shop_opened, rarity: 1, name: "Kecleon Visitor", desc: "Open Kecleon's Upgrade Shop.", group: :shop },
    { id: :shop_first_upgrade, rarity: 2, name: "First Upgrade", desc: "Buy one permanent upgrade.", group: :shop },
    { id: :training_opened, rarity: 1, name: "Personal Coach", desc: "Open a Pokemon Training tree.", group: :training },
    { id: :training_first_upgrade, rarity: 2, name: "Candy Lesson", desc: "Buy one Pokemon Training upgrade.", group: :training },
    { id: :training_10_slots, rarity: 3, name: "Focused Practice", desc: "Buy 10 Pokemon Training upgrade slots across all Pokemon.", group: :training },
    { id: :training_25_slots, rarity: 4, name: "Serious Training", desc: "Buy 25 Pokemon Training upgrade slots across all Pokemon.", group: :training },
    { id: :training_complete_one, rarity: 5, name: "Trusted Partner", desc: "Complete one Pokemon Training tree before Shiny Form.", group: :training },
    { id: :training_three_complete, rarity: 6, name: "Training Team", desc: "Complete three Pokemon Training trees before Shiny Form.", group: :training },
    { id: :training_equipment_unlock, rarity: 4, name: "Ready Pocket", desc: "Unlock one Pokemon equipment slot.", group: :training },
    { id: :training_shiny_unlock, rarity: 6, name: "Bright Bond", desc: "Unlock one Shiny Form upgrade.", group: :training },
    { id: :training_shiny_run, rarity: 5, name: "Sparkling Start", desc: "Start a run with Shiny visuals enabled.", group: :training },
    { id: :candies_1000, rarity: 3, name: "Candy Jar", desc: "Own at least 1000 Candies.", group: :training },
    { id: :candies_5000, rarity: 5, name: "Candy Vault", desc: "Own at least 5000 Candies.", group: :training },
    { id: :shop_5_upgrades, rarity: 3, name: "Small Investment", desc: "Buy 5 permanent upgrade slots.", group: :shop },
    { id: :shop_10_upgrades, rarity: 4, name: "Permanent Growth", desc: "Buy 20 permanent upgrade slots.", group: :shop },
    { id: :shop_35_upgrades, rarity: 5, name: "Deep Preparation", desc: "Buy 35 permanent upgrade slots.", group: :shop },
    { id: :shop_25_upgrades, rarity: 5, name: "Prepared Build", desc: "Buy 45 permanent upgrade slots.", group: :shop },
    { id: :shop_standard_complete, rarity: 6, name: "Prepared Champion", desc: "Complete the main permanent upgrade tree.", group: :shop },
    { id: :dark_fragment, rarity: 5, name: "Dark Fragment", desc: "Own at least one Dark Fragment.", group: :shop },
    { id: :endless_shop_first, rarity: 5, name: "Endless Investment", desc: "Buy one Endless upgrade slot.", group: :shop },
    { id: :endless_shop_5, rarity: 6, name: "Endless Foundation", desc: "Buy 5 Endless upgrade slots.", group: :shop },
    { id: :moves_first, rarity: 2, name: "Move Tutor", desc: "Pick up a MOVES item and learn one extra skill.", group: :upgrade },
    { id: :moves_full_slots, rarity: 3, name: "Triple Technique", desc: "Fill all skill slots during one run.", group: :upgrade },
    { id: :moves_10_total, rarity: 3, name: "Move Collector", desc: "Learn 10 extra skills from MOVES items across runs.", group: :upgrade },
    { id: :egg_first_hatch, rarity: 2, name: "Tiny Partner", desc: "Hatch one Egg event.", group: :event },
    { id: :egg_partner_saved, rarity: 3, name: "Protected Shell", desc: "Hatch an Egg while it still has at least 75% HP.", group: :event },
    { id: :egg_5_hatches, rarity: 4, name: "Daycare Route", desc: "Hatch 5 Egg events across runs.", group: :event },
    { id: :egg_15_hatches, rarity: 5, name: "Nest Keeper", desc: "Hatch 15 Egg events across runs.", group: :event },
    { id: :egg_all_babies, rarity: 5, name: "Baby Brigade", desc: "Hatch every available Baby Pokemon at least once.", group: :event },
    { id: :egg_munchlax, rarity: 3, name: "Snack Buddy", desc: "Hatch Munchlax from an Egg event.", group: :event },
    { id: :egg_shiny_first, rarity: 4, name: "Shiny Shell", desc: "Hatch one Shiny Baby companion.", group: :event },
    { id: :egg_shiny_3, rarity: 5, name: "Sparkling Nursery", desc: "Hatch 3 Shiny Baby companions across runs.", group: :event },
    { id: :baby_survivor, rarity: 4, name: "Partner Guard", desc: "Win a run while a Baby companion is still with you.", group: :event },
    { id: :egg_shiny_guard, rarity: 6, name: "Radiant Partner", desc: "Win a run while a Shiny Baby companion is still with you.", group: :event },
    { id: :sleep_first_awaken, rarity: 2, name: "Gentle Wake", desc: "Awaken one Sleeping Pokemon event.", group: :event },
    { id: :sleep_all_tapu, rarity: 5, name: "Island Blessings", desc: "Awaken every Sleeping Guardian at least once.", group: :event },
    { id: :sleep_10_awakened, rarity: 4, name: "Guardian Friend", desc: "Awaken 10 Sleeping Pokemon events across runs.", group: :event },
    { id: :sleep_25_awakened, rarity: 6, name: "Guardian Circle", desc: "Awaken 25 Sleeping Pokemon events across runs.", group: :event },
    { id: :tower_egg_floor_set, rarity: 5, name: "Tower Caretaker", desc: "Hatch Eggs on Tower floors 15, 25 and 35 across runs.", group: :tower },
    { id: :event_swarm_alert, rarity: 2, name: "Swarm Alarm", desc: "Trigger one Swarm Alert event.", group: :event },
    { id: :event_swarm_alert_5, rarity: 4, name: "Storm Walker", desc: "Trigger 5 Swarm Alert events across runs.", group: :event },
    { id: :event_elite_hunt_first, rarity: 3, name: "Elite Hunter", desc: "Defeat one Elite Hunt event Pokemon.", group: :event },
    { id: :event_gimmighoul_hunt, rarity: 3, name: "Coin Catcher", desc: "Defeat Gimmighoul during an Elite Hunt.", group: :event },
    { id: :event_delibird_hunt, rarity: 3, name: "Gift Chaser", desc: "Defeat Delibird during an Elite Hunt.", group: :event },
    { id: :event_elite_hunt_pair, rarity: 4, name: "Rare Pair", desc: "Defeat both Elite Hunt event Pokemon across runs.", group: :event },
    { id: :event_elite_hunt_10, rarity: 5, name: "Event Tracker", desc: "Defeat 10 Elite Hunt event Pokemon across runs.", group: :event },
    { id: :event_lost_kecleon, rarity: 3, name: "Lost Merchant", desc: "Wake Lost Kecleon once.", group: :event },
    { id: :event_lost_kecleon_5, rarity: 5, name: "Merchant Guide", desc: "Wake Lost Kecleon 5 times across runs.", group: :event },
    { id: :event_joker_first, rarity: 3, name: "Joker Deal", desc: "Accept one Joker bonus from Lost Kecleon.", group: :event },
    { id: :event_joker_5, rarity: 5, name: "Risk Collector", desc: "Accept 5 Joker bonuses across runs.", group: :event },
    { id: :event_joker_all, rarity: 6, name: "All In", desc: "Accept every current Joker bonus at least once.", group: :event },
    { id: :endless_shop_complete, rarity: 7, name: "Endless Prepared", desc: "Complete every Endless permanent upgrade slot.", group: :shop },
    { id: :dark_fragment_10, rarity: 6, name: "Dark Savings", desc: "Own at least 10 Dark Fragments.", group: :shop },
    { id: :skill_collector, rarity: 4, name: "Many Styles", desc: "Unlock 20 different playable main skills.", group: :collection },
    { id: :battle_pass_tome1_complete, rarity: 6, name: "Tome Finisher", desc: "Complete Tome 1: Legend of the Fish.", group: :battle_pass },
    { id: :breach_extract_first, rarity: 2, name: "Home with the Loot", desc: "Extract successfully from Breach once.", group: :breach, counter: [:breach_stat, :extractions, 1] },
    { id: :breach_extract_five, rarity: 4, name: "Return Ticket", desc: "Extract successfully from Breach 5 times across seasons.", group: :breach, counter: [:breach_stat, :extractions, 5] },
    { id: :breach_rooms_ten, rarity: 2, name: "Door Explorer", desc: "Clear 10 Breach rooms across seasons.", group: :breach, counter: [:breach_stat, :rooms, 10] },
    { id: :breach_rooms_fifty, rarity: 4, name: "Room for More", desc: "Clear 50 Breach rooms across seasons.", group: :breach, counter: [:breach_stat, :rooms, 50] },
    { id: :breach_rooms_hundred, rarity: 5, name: "Beyond the Door", desc: "Clear 100 Breach rooms across seasons.", group: :breach, counter: [:breach_stat, :rooms, 100] },
    { id: :breach_unfair_first, rarity: 3, name: "Against the Odds", desc: "Clear an Unfair Breach room and finish the run without abandoning.", group: :breach, counter: [:breach_stat, :unfair_rooms, 1] },
    { id: :breach_unfair_ten, rarity: 5, name: "Risk Appetite", desc: "Clear 10 Unfair Breach rooms across seasons.", group: :breach, counter: [:breach_stat, :unfair_rooms, 10] },
    { id: :breach_fusion_first, rarity: 2, name: "Better Together", desc: "Fuse a Breach module and finish the run without abandoning.", group: :breach, counter: [:breach_stat, :fusions, 1] },
    { id: :breach_fusion_ten, rarity: 4, name: "Module Artisan", desc: "Fuse 10 Breach modules across seasons.", group: :breach, counter: [:breach_stat, :fusions, 10] },
    { id: :breach_training_fifty, rarity: 3, name: "Study Break", desc: "Gain 50 levels through Breach training across completed runs.", group: :breach, counter: [:breach_stat, :levels, 50] },
    { id: :breach_extract_trio, rarity: 4, name: "Expedition Team", desc: "Extract from Breach with 3 different Pokemon across seasons.", group: :breach, counter: [:breach_species, :pokemon, 3] },
    { id: :breach_extract_five_species, rarity: 5, name: "Many Ways Home", desc: "Extract from Breach with 5 different Pokemon across seasons.", group: :breach, counter: [:breach_species, :pokemon, 5] },
    { id: :training_five_complete, rarity: 5, name: "Team Coach", desc: "Complete the main training tree of 5 Pokemon, excluding Shiny.", group: :training, counter: [:pokemon_training_complete, nil, 5] },
    { id: :training_shiny_three, rarity: 5, name: "Prismatic Trio", desc: "Purchase the Shiny upgrade for 3 different Pokemon.", group: :training, counter: [:pokemon_training_shiny, nil, 3] },
    { id: :training_equipment_five, rarity: 3, name: "Ready for Anything", desc: "Unlock equipment slots for 5 different Pokemon.", group: :training, counter: [:pokemon_training_equipment, nil, 5] },
    { id: :egg_thirty, rarity: 5, name: "Nursery Keeper", desc: "Hatch 30 event Eggs across runs.", group: :event, counter: [:stat, :egg_hatches, 30] },
    { id: :egg_shiny_six, rarity: 5, name: "Lucky Little Stars", desc: "Hatch 6 Shiny companions across runs.", group: :event, counter: [:stat, :egg_shiny_hatches, 6] },
    { id: :sleep_fifty, rarity: 5, name: "Gentle Awakening", desc: "Wake 50 sleeping Pokemon across runs.", group: :event, counter: [:stat, :sleep_awakened, 50] },
    { id: :swarm_ten, rarity: 4, name: "Calm in the Swarm", desc: "Survive 10 Swarm Alerts across runs.", group: :event, counter: [:stat, :swarm_alerts_survived, 10] },
    { id: :hunt_twenty, rarity: 5, name: "Treasure Tracker", desc: "Defeat 20 event Delibird or Gimmighoul across runs.", group: :event, counter: [:stat, :elite_hunts_defeated, 20] },
    { id: :kecleon_ten, rarity: 5, name: "Merchant's Friend", desc: "Wake Lost Kecleon 10 times across runs.", group: :event, counter: [:stat, :lost_kecleon_helped, 10] },
    { id: :joker_ten, rarity: 5, name: "Deal Maker", desc: "Accept 10 Joker bonuses across runs.", group: :event, counter: [:stat, :joker_bonuses_taken, 10] },
    { id: :moves_twentyfive, rarity: 4, name: "Borrowed Tricks", desc: "Learn 25 additional skills from MOVES across runs.", group: :upgrade, counter: [:stat, :moves_learned_total, 25] },
    { id: :eevee_first_path, rarity: 3, name: "A New Shade", desc: "Discover one Eevee evolution during a run.", group: :evolution, counter: [:eevee_forms, nil, 1] },
    { id: :eevee_four_paths, rarity: 5, name: "Prism Explorer", desc: "Discover 4 different Eevee evolutions across runs.", group: :evolution, counter: [:eevee_forms, nil, 4] },
    { id: :eevee_eight_paths, rarity: 6, name: "Every Shade", desc: "Discover all 8 Eevee evolutions across runs.", group: :evolution, counter: [:eevee_forms, nil, 8] },
    { id: :battle_pass_tome2_complete, rarity: 6, name: "Dragon Scholar", desc: "Complete Tome 2: Draconic Ascent.", group: :battle_pass, counter: [:battle_pass_complete, :battle_pass_2, 1] },
    { id: :battle_pass_tome3_complete, rarity: 6, name: "Natural Champion", desc: "Complete Tome 3: Natural Power.", group: :battle_pass, counter: [:battle_pass_complete, :battle_pass_3, 1] },
    { id: :battle_pass_tome4_complete, rarity: 6, name: "Limit Breaker", desc: "Complete Tome 4: Boundless Power.", group: :battle_pass, counter: [:battle_pass_complete, :battle_pass_4, 1] },
    { id: :battle_pass_tome5_complete, rarity: 6, name: "Sky and Sea", desc: "Complete Tome 5: Predators of Sky and Sea.", group: :battle_pass, counter: [:battle_pass_complete, :battle_pass_5, 1] },
    { id: :battle_pass_tome6_complete, rarity: 6, name: "Prism Keeper", desc: "Complete Tome 6: Paths of the Prism.", group: :battle_pass, counter: [:battle_pass_complete, :battle_pass_6, 1] },
    { id: :battle_pass_tome7_complete, rarity: 6, name: "Mind over Matter", desc: "Complete Tome 7: Beyond the Mind.", group: :battle_pass, counter: [:battle_pass_complete, :battle_pass_7, 1] },
    { id: :z_move_first, rarity: 2, name: "Z Spark", desc: "Activate a Z-Move once.", group: :z_moves, counter: [:z_move_count, nil, 1] },
    { id: :z_move_ten, rarity: 3, name: "Crystal Rhythm", desc: "Activate Z-Moves 10 times across runs.", group: :z_moves, counter: [:z_move_count, nil, 10] },
    { id: :z_move_fifty, rarity: 4, name: "Resonance Rising", desc: "Activate Z-Moves 50 times across runs.", group: :z_moves, counter: [:z_move_count, nil, 50] },
    { id: :z_move_hundred, rarity: 5, name: "Z Veteran", desc: "Activate Z-Moves 100 times across runs.", group: :z_moves, counter: [:z_move_count, nil, 100] },
    { id: :z_types_three, rarity: 3, name: "Three Facets", desc: "Use 3 different elemental Z-Crystals across runs.", group: :z_moves, counter: [:z_move_types, nil, 3] },
    { id: :z_types_nine, rarity: 5, name: "Spectrum Seeker", desc: "Use 9 different elemental Z-Crystals across runs.", group: :z_moves, counter: [:z_move_types, nil, 9] },
    { id: :z_types_all, rarity: 7, name: "Full Spectrum", desc: "Use all 18 elemental Z-Crystals across runs.", group: :z_moves, counter: [:z_move_types, nil, 18] },
    { id: :battle_pass_tome8_complete, rarity: 6, name: "Resonance Scholar", desc: "Complete Tome 8: Elemental Resonance.", group: :battle_pass, counter: [:battle_pass_complete, :battle_pass_8, 1] },
    { id: :all_survivors, rarity: 7, name: "Survivor Master", desc: "Unlock every playable Pokemon, except password and seasonal Pokemon.", group: :collection }
  ]

  ADDITIONAL_COUNTER_ACHIEVEMENTS = ACHIEVEMENTS.select { |data| data[:counter] }.freeze

  # Translation extraction markers for dynamic achievement text.
  # The vanilla extractor only sees literal _INTL calls, while medals store
  # titles/descriptions as data and translate them later when drawn.
  def translation_extraction_markers
    _INTL("Z Spark")
    _INTL("Activate a Z-Move once.")
    _INTL("Crystal Rhythm")
    _INTL("Activate Z-Moves 10 times across runs.")
    _INTL("Resonance Rising")
    _INTL("Activate Z-Moves 50 times across runs.")
    _INTL("Z Veteran")
    _INTL("Activate Z-Moves 100 times across runs.")
    _INTL("Three Facets")
    _INTL("Use 3 different elemental Z-Crystals across runs.")
    _INTL("Spectrum Seeker")
    _INTL("Use 9 different elemental Z-Crystals across runs.")
    _INTL("Full Spectrum")
    _INTL("Use all 18 elemental Z-Crystals across runs.")
    _INTL("Resonance Scholar")
    _INTL("Complete Tome 8: Elemental Resonance.")
    _INTL("Home with the Loot")
    _INTL("Extract successfully from Breach once.")
    _INTL("Return Ticket")
    _INTL("Extract successfully from Breach 5 times across seasons.")
    _INTL("Door Explorer")
    _INTL("Clear 10 Breach rooms across seasons.")
    _INTL("Room for More")
    _INTL("Clear 50 Breach rooms across seasons.")
    _INTL("Beyond the Door")
    _INTL("Clear 100 Breach rooms across seasons.")
    _INTL("Against the Odds")
    _INTL("Clear an Unfair Breach room and finish the run without abandoning.")
    _INTL("Risk Appetite")
    _INTL("Clear 10 Unfair Breach rooms across seasons.")
    _INTL("Better Together")
    _INTL("Fuse a Breach module and finish the run without abandoning.")
    _INTL("Module Artisan")
    _INTL("Fuse 10 Breach modules across seasons.")
    _INTL("Study Break")
    _INTL("Gain 50 levels through Breach training across completed runs.")
    _INTL("Expedition Team")
    _INTL("Extract from Breach with 3 different Pokemon across seasons.")
    _INTL("Many Ways Home")
    _INTL("Extract from Breach with 5 different Pokemon across seasons.")
    _INTL("Team Coach")
    _INTL("Complete the main training tree of 5 Pokemon, excluding Shiny.")
    _INTL("Prismatic Trio")
    _INTL("Purchase the Shiny upgrade for 3 different Pokemon.")
    _INTL("Ready for Anything")
    _INTL("Unlock equipment slots for 5 different Pokemon.")
    _INTL("Nursery Keeper")
    _INTL("Hatch 30 event Eggs across runs.")
    _INTL("Lucky Little Stars")
    _INTL("Hatch 6 Shiny companions across runs.")
    _INTL("Gentle Awakening")
    _INTL("Wake 50 sleeping Pokemon across runs.")
    _INTL("Calm in the Swarm")
    _INTL("Survive 10 Swarm Alerts across runs.")
    _INTL("Treasure Tracker")
    _INTL("Defeat 20 event Delibird or Gimmighoul across runs.")
    _INTL("Merchant's Friend")
    _INTL("Wake Lost Kecleon 10 times across runs.")
    _INTL("Deal Maker")
    _INTL("Accept 10 Joker bonuses across runs.")
    _INTL("Borrowed Tricks")
    _INTL("Learn 25 additional skills from MOVES across runs.")
    _INTL("A New Shade")
    _INTL("Discover one Eevee evolution during a run.")
    _INTL("Prism Explorer")
    _INTL("Discover 4 different Eevee evolutions across runs.")
    _INTL("Every Shade")
    _INTL("Discover all 8 Eevee evolutions across runs.")
    _INTL("Dragon Scholar")
    _INTL("Complete Tome 2: Draconic Ascent.")
    _INTL("Natural Champion")
    _INTL("Complete Tome 3: Natural Power.")
    _INTL("Limit Breaker")
    _INTL("Complete Tome 4: Boundless Power.")
    _INTL("Sky and Sea")
    _INTL("Complete Tome 5: Predators of Sky and Sea.")
    _INTL("Prism Keeper")
    _INTL("Complete Tome 6: Paths of the Prism.")
    _INTL("Mind over Matter")
    _INTL("Complete Tome 7: Beyond the Mind.")
    _INTL("Common")
    _INTL("Uncommon")
    _INTL("Rare")
    _INTL("Super Rare")
    _INTL("Epic")
    _INTL("Legendary")
    _INTL("Mythic")
_INTL("Swarm Alarm")
_INTL("Trigger one Swarm Alert event.")
_INTL("Storm Walker")
_INTL("Trigger 5 Swarm Alert events across runs.")
_INTL("Elite Hunter")
_INTL("Defeat one Elite Hunt event Pokemon.")
_INTL("Coin Catcher")
_INTL("Defeat Gimmighoul during an Elite Hunt.")
_INTL("Gift Chaser")
_INTL("Defeat Delibird during an Elite Hunt.")
_INTL("Rare Pair")
_INTL("Defeat both Elite Hunt event Pokemon across runs.")
_INTL("Event Tracker")
_INTL("Defeat 10 Elite Hunt event Pokemon across runs.")
_INTL("Lost Merchant")
_INTL("Wake Lost Kecleon once.")
_INTL("Merchant Guide")
_INTL("Wake Lost Kecleon 5 times across runs.")
_INTL("Joker Deal")
_INTL("Accept one Joker bonus from Lost Kecleon.")
_INTL("Risk Collector")
_INTL("Accept 5 Joker bonuses across runs.")
_INTL("All In")
_INTL("Accept every current Joker bonus at least once.")
    _INTL("Tome Finisher")
    _INTL("Complete Tome 1: Legend of the Fish.")
    _INTL("First Steps")
    _INTL("Finish any run, won or lost.")
    _INTL("First Victory")
    _INTL("Win any game mode once.")
    _INTL("One More Run")
    _INTL("Finish 3 runs in total.")
    _INTL("Survivor Habit")
    _INTL("Finish 15 runs in total.")
    _INTL("Run Regular")
    _INTL("Finish 30 runs in total.")
    _INTL("Just One More")
    _INTL("Finish 50 runs in total.")
    _INTL("Survivor Marathon")
    _INTL("Finish 100 runs in total.")
    _INTL("Classic Survivor")
    _INTL("Validate a Classic run.")
    _INTL("Ultra Breaker")
    _INTL("Defeat the Classic Ultra Boss.")
    _INTL("Classic Trio")
    _INTL("Validate Classic Mode with 5 different Pokemon.")
    _INTL("Classic Rotation")
    _INTL("Validate Classic Mode with 10 different Pokemon.")
    _INTL("Classic Specialist")
    _INTL("Validate Classic Mode with 20 different Pokemon.")
    _INTL("Leafy First Clear")
    _INTL("Validate Classic Mode with Bulbasaur.")
    _INTL("Flame First Clear")
    _INTL("Validate Classic Mode with Cyndaquil.")
    _INTL("Bubble First Clear")
    _INTL("Validate Classic Mode with Mudkip.")
    _INTL("Rush Breaker")
    _INTL("Clear Rush Mode.")
    _INTL("Rush Streak")
    _INTL("Clear Rush Mode with 3 different Pokemon.")
    _INTL("Boss Sprint")
    _INTL("Clear Rush Mode in under 12 minutes.")
    _INTL("Rush Blitz")
    _INTL("Clear Rush Mode in under 10 minutes.")
    _INTL("Rush Rotation")
    _INTL("Clear Rush Mode with 8 different Pokemon.")
    _INTL("Rush Veteran")
    _INTL("Clear Rush Mode with 15 different Pokemon.")
    _INTL("First Stair")
    _INTL("Reach floor 10 in Tower Mode.")
    _INTL("Steady Climb")
    _INTL("Reach floor 20 in Tower Mode.")
    _INTL("First Climb")
    _INTL("Reach floor 30 in Tower Mode.")
    _INTL("Mid Tower")
    _INTL("Reach floor 25 in Tower Mode.")
    _INTL("Upper Tower")
    _INTL("Reach floor 40 in Tower Mode.")
    _INTL("Final Gate")
    _INTL("Reach floor 50 in Tower Mode.")
    _INTL("Tower Conqueror")
    _INTL("Clear Tower Mode.")
    _INTL("Careful Climber")
    _INTL("Reach floor 40 in Tower Mode with less than 500 damage taken.")
    _INTL("Untouched Summit")
    _INTL("Clear Tower Mode with less than 1500 damage taken.")
    _INTL("Endless Entry")
    _INTL("Finish an Endless run with at least 100000 score.")
    _INTL("Endless Spark")
    _INTL("Survive 5 minutes in Endless Mode.")
    _INTL("Endless Pulse")
    _INTL("Survive 10 minutes in Endless Mode.")
    _INTL("Endless Flow")
    _INTL("Survive 15 minutes in Endless Mode.")
    _INTL("Deep Endless")
    _INTL("Survive 20 minutes in Endless Mode.")
    _INTL("Endless Wall")
    _INTL("Survive 30 minutes in Endless Mode.")
    _INTL("Endless Legend")
    _INTL("Survive 45 minutes in Endless Mode.")
    _INTL("Endless Myth")
    _INTL("Survive 60 minutes in Endless Mode.")
    _INTL("First Growth")
    _INTL("Reach level 25 during a run.")
    _INTL("Getting Warm")
    _INTL("Reach level 50 during a run.")
    _INTL("Limit Broken")
    _INTL("Reach level 100 during a run.")
    _INTL("Beyond Training")
    _INTL("Reach level 150 during a run.")
    _INTL("Power Curve")
    _INTL("Reach level 200 during a run.")
    _INTL("Overlevel Mastery")
    _INTL("Reach level 300 during a run.")
    _INTL("Rainbow Level")
    _INTL("Reach level 400 during a run.")
    _INTL("Level Horizon")
    _INTL("Reach level 500 during a run.")
    _INTL("Level Singularity")
    _INTL("Reach level 700 during a run.")
    _INTL("Score Seed")
    _INTL("Reach 250000 score during a run.")
    _INTL("Score Bloom")
    _INTL("Reach 500000 score during a run.")
    _INTL("Million Spark")
    _INTL("Reach 1000000 score during a run.")
    _INTL("Double Million")
    _INTL("Reach 2000000 score during a run.")
    _INTL("Heated Score")
    _INTL("Reach 3000000 score during a run.")
    _INTL("Score Inferno")
    _INTL("Reach 5000000 score during a run.")
    _INTL("Score Supernova")
    _INTL("Reach 7000000 score during a run.")
    _INTL("Rainbow Score")
    _INTL("Reach 9000000 score during a run.")
    _INTL("Ranking Visitor")
    _INTL("Open the leaderboard.")
    _INTL("Different Angle")
    _INTL("Change the leaderboard sorting once.")
    _INTL("My Own Track")
    _INTL("View only your own leaderboard runs.")
    _INTL("Pokemon Lens")
    _INTL("Open the Pokemon leaderboard filter.")
    _INTL("Shared Result")
    _INTL("Share one winning run online.")
    _INTL("Regular Challenger")
    _INTL("Share 10 winning runs online.")
    _INTL("Known Challenger")
    _INTL("Share 25 winning runs online.")
    _INTL("Classic Record")
    _INTL("Share a Classic result online.")
    _INTL("Rush Record")
    _INTL("Share a Rush result online.")
    _INTL("Tower Record")
    _INTL("Share a Tower result online.")
    _INTL("Endless Record")
    _INTL("Share an Endless result online.")
    _INTL("All Boards Open")
    _INTL("Share one online result in each game mode.")
    _INTL("Careful Tinkerer")
    _INTL("Open the Options menu.")
    _INTL("Medal Case")
    _INTL("Open the Achievements menu.")
    _INTL("Crowd Control")
    _INTL("Defeat 500 enemies during a run.")
    _INTL("Clean Sweep")
    _INTL("Defeat 1000 enemies during a run.")
    _INTL("Swarm Breaker")
    _INTL("Defeat 2000 enemies during a run.")
    _INTL("Wave Cutter")
    _INTL("Defeat 3000 enemies during a run.")
    _INTL("Field Cleaner")
    _INTL("Defeat 5000 enemies during a run.")
    _INTL("Massive Sweep")
    _INTL("Defeat 7000 enemies during a run.")
    _INTL("Total Sweep")
    _INTL("Defeat 9000 enemies during a run.")
    _INTL("Screen Clearer")
    _INTL("Defeat 12000 enemies during a run.")
    _INTL("True Shape")
    _INTL("Reach a final evolution or final boost during a run.")
    _INTL("Spirit Flame")
    _INTL("Evolve Quilava into Hisuian Typhlosion during a run.")
    _INTL("Blade Evolution")
    _INTL("Evolve Kirlia into Gallade during a run.")
    _INTL("Surfing Spark")
    _INTL("Evolve Pikachu into Alolan Raichu during a run.")
    _INTL("Steel Shell Dragon")
    _INTL("Evolve Goomy through its Hisuian evolution path during a run.")
    _INTL("Branching Paths")
    _INTL("Discover 3 alternate evolution forms across runs.")
    _INTL("Alternate Specialist")
    _INTL("Discover every current alternate evolution form.")
    _INTL("Perfect Form")
    _INTL("Reach final form and level 100 in the same run.")
    _INTL("No More Choices")
    _INTL("Exhaust every available run bonus during a run.")
    _INTL("New Hand")
    _INTL("Use every reroll during one run.")
    _INTL("Strict Draft")
    _INTL("Use every ban during one run.")
    _INTL("Growing Roster")
    _INTL("Unlock 15 playable Pokemon.")
    _INTL("Roster Builder")
    _INTL("Unlock 25 playable Pokemon.")
    _INTL("Wide Roster")
    _INTL("Unlock 40 playable Pokemon.")
    _INTL("Big Roster")
    _INTL("Unlock 50 playable Pokemon.")
    _INTL("Packed Selection")
    _INTL("Unlock 60 playable Pokemon.")
    _INTL("Living Selection")
    _INTL("Unlock 70 playable Pokemon.")
    _INTL("Mythic Friend")
    _INTL("Unlock Mew.")
    _INTL("Space Signal")
    _INTL("Unlock Deoxys.")
    _INTL("First Adventure Badge")
    _INTL("Complete every current Adventure Badge fragment on one Pokemon.")
    _INTL("Badge Triangle")
    _INTL("Complete every current Adventure Badge fragment on 3 Pokemon.")
    _INTL("Star Pattern")
    _INTL("Complete every current Adventure Badge fragment on 5 Pokemon.")
    _INTL("Badge Path")
    _INTL("Complete every current Adventure Badge fragment on 10 Pokemon.")
    _INTL("Seven Stars")
    _INTL("Complete every current Adventure Badge fragment on 15 Pokemon.")
    _INTL("Star Collector")
    _INTL("Complete every current Adventure Badge fragment on 30 Pokemon.")
    _INTL("Badge Archive")
    _INTL("Complete every current Adventure Badge fragment on 40 Pokemon.")
    _INTL("Constellation")
    _INTL("Complete every current Adventure Badge fragment on 50 Pokemon.")
    _INTL("Boss Badge Proof")
    _INTL("Earn the Boss Adventure Badge on 15 Pokemon.")
    _INTL("Boss Badge Line")
    _INTL("Earn the Boss Adventure Badge on 30 Pokemon.")
    _INTL("Rush Badge Proof")
    _INTL("Earn the Rush Adventure Badge on 15 Pokemon.")
    _INTL("Tower Badge Proof")
    _INTL("Earn the Tower Adventure Badge on 10 Pokemon.")
    _INTL("Personal Coach")
    _INTL("Open a Pokemon Training tree.")
    _INTL("Candy Lesson")
    _INTL("Buy one Pokemon Training upgrade.")
    _INTL("Focused Practice")
    _INTL("Buy 10 Pokemon Training upgrade slots across all Pokemon.")
    _INTL("Serious Training")
    _INTL("Buy 25 Pokemon Training upgrade slots across all Pokemon.")
    _INTL("Trusted Partner")
    _INTL("Complete one Pokemon Training tree before Shiny Form.")
    _INTL("Training Team")
    _INTL("Complete three Pokemon Training trees before Shiny Form.")
    _INTL("Ready Pocket")
    _INTL("Unlock one Pokemon equipment slot.")
    _INTL("Bright Bond")
    _INTL("Unlock one Shiny Form upgrade.")
    _INTL("Sparkling Start")
    _INTL("Start a run with Shiny visuals enabled.")
    _INTL("Candy Jar")
    _INTL("Own at least 1000 Candies.")
    _INTL("Candy Vault")
    _INTL("Own at least 5000 Candies.")
    _INTL("Kecleon Visitor")
    _INTL("Open Kecleon's Upgrade Shop.")
    _INTL("First Upgrade")
    _INTL("Buy one permanent upgrade.")
    _INTL("Small Investment")
    _INTL("Buy 5 permanent upgrade slots.")
    _INTL("Permanent Growth")
    _INTL("Buy 20 permanent upgrade slots.")
    _INTL("Deep Preparation")
    _INTL("Buy 35 permanent upgrade slots.")
    _INTL("Prepared Build")
    _INTL("Buy 45 permanent upgrade slots.")
    _INTL("Prepared Champion")
    _INTL("Complete the main permanent upgrade tree.")
    _INTL("Dark Fragment")
    _INTL("Own at least one Dark Fragment.")
    _INTL("Endless Investment")
    _INTL("Buy one Endless upgrade slot.")
    _INTL("Endless Foundation")
    _INTL("Buy 5 Endless upgrade slots.")
    _INTL("Move Tutor")
    _INTL("Pick up a MOVES item and learn one extra skill.")
    _INTL("Triple Technique")
    _INTL("Fill all skill slots during one run.")
    _INTL("Move Collector")
    _INTL("Learn 10 extra skills from MOVES items across runs.")
    _INTL("Tiny Partner")
    _INTL("Hatch one Egg event.")
    _INTL("Protected Shell")
    _INTL("Hatch an Egg while it still has at least 75% HP.")
    _INTL("Daycare Route")
    _INTL("Hatch 5 Egg events across runs.")
    _INTL("Baby Brigade")
    _INTL("Hatch every available Baby Pokemon at least once.")
    _INTL("Snack Buddy")
    _INTL("Hatch Munchlax from an Egg event.")
    _INTL("Shiny Shell")
    _INTL("Hatch one Shiny Baby companion.")
    _INTL("Sparkling Nursery")
    _INTL("Hatch 3 Shiny Baby companions across runs.")
    _INTL("Partner Guard")
    _INTL("Win a run while a Baby companion is still with you.")
    _INTL("Radiant Partner")
    _INTL("Win a run while a Shiny Baby companion is still with you.")
    _INTL("Gentle Wake")
    _INTL("Awaken one Sleeping Pokemon event.")
    _INTL("Island Blessings")
    _INTL("Awaken every Sleeping Guardian at least once.")
    _INTL("Guardian Friend")
    _INTL("Awaken 10 Sleeping Pokemon events across runs.")
    _INTL("Tower Caretaker")
    _INTL("Hatch Eggs on Tower floors 15, 25 and 35 across runs.")
    _INTL("Endless Prepared")
    _INTL("Complete every Endless permanent upgrade slot.")
    _INTL("Dark Savings")
    _INTL("Own at least 10 Dark Fragments.")
    _INTL("Many Styles")
    _INTL("Unlock 20 different playable main skills.")
    _INTL("Survivor Master")
    _INTL("Unlock every playable Pokemon, except password and seasonal Pokemon.")
    _INTL("Achievement")
    _INTL("Achievement Medals")
    _INTL("Locked Achievement")
    _INTL("Hint: {1}")
    _INTL("Keep playing to discover this medal.")
  rescue
  end

  ACHIEVEMENT_COUNTERS = {
    :comeback_attempt => [:stat, :runs, 3],
    :habit_forming => [:stat, :runs, 15],
    :run_regular => [:stat, :runs, 30],
    :run_obsessed => [:stat, :runs, 50],
    :run_marathon => [:stat, :runs, 100],
    :classic_three => [:list, :classic_winners, 5],
    :classic_rotation => [:list, :classic_winners, 10],
    :classic_ten => [:list, :classic_winners, 20],
    :rush_three_wins => [:list, :rush_winners, 3],
    :rush_three => [:list, :rush_winners, 8],
    :rush_veteran => [:list, :rush_winners, 15],
    :tower_floor_10 => [:stat, :max_tower_floor, 10],
    :tower_floor_20 => [:stat, :max_tower_floor, 20],
    :tower_floor_30 => [:stat, :max_tower_floor, 30],
    :tower_halfway => [:stat, :max_tower_floor, 25],
    :tower_floor_75 => [:stat, :max_tower_floor, 40],
    :tower_floor_90 => [:stat, :max_tower_floor, 50],
    :endless_entry => [:stat, :max_endless_score, 100_000],
    :endless_5_minutes => [:stat, :max_endless_seconds, 300],
    :endless_10_minutes => [:stat, :max_endless_seconds, 600],
    :endless_15_minutes => [:stat, :max_endless_seconds, 900],
    :endless_20_minutes => [:stat, :max_endless_seconds, 1200],
    :endless_30_minutes => [:stat, :max_endless_seconds, 1800],
    :endless_45_minutes => [:stat, :max_endless_seconds, 2700],
    :endless_60_minutes => [:stat, :max_endless_seconds, 3600],
    :level_25 => [:stat, :max_level, 25],
    :level_50 => [:stat, :max_level, 50],
    :level_100 => [:stat, :max_level, 100],
    :level_150 => [:stat, :max_level, 150],
    :level_200 => [:stat, :max_level, 200],
    :level_300 => [:stat, :max_level, 300],
    :level_400 => [:stat, :max_level, 400],
    :level_500 => [:stat, :max_level, 500],
    :level_700 => [:stat, :max_level, 700],
    :score_250k => [:stat, :max_score, 250_000],
    :score_500k => [:stat, :max_score, 500_000],
    :score_1m => [:stat, :max_score, 1_000_000],
    :score_2m => [:stat, :max_score, 2_000_000],
    :score_3m => [:stat, :max_score, 3_000_000],
    :score_5m => [:stat, :max_score, 5_000_000],
    :score_7m => [:stat, :max_score, 7_000_000],
    :score_9m => [:stat, :max_score, 9_000_000],
    :leaderboard_three_submits => [:stat, :leaderboard_submits, 10],
    :leaderboard_25_submits => [:stat, :leaderboard_submits, 25],
    :kills_500 => [:stat, :max_kills, 500],
    :kills_1000 => [:stat, :max_kills, 1000],
    :kills_2000 => [:stat, :max_kills, 2000],
    :kills_3000 => [:stat, :max_kills, 3000],
    :kills_5000 => [:stat, :max_kills, 5000],
    :kills_7000 => [:stat, :max_kills, 7000],
    :kills_9000 => [:stat, :max_kills, 9000],
    :kills_10000 => [:stat, :max_kills, 12000],
    :unlock_10 => [:list, :unlocked, 15],
    :unlock_25_mid => [:list, :unlocked, 25],
    :unlock_25 => [:list, :unlocked, 40],
    :unlock_50 => [:list, :unlocked, 50],
    :unlock_40 => [:list, :unlocked, 60],
    :unlock_70 => [:list, :unlocked, 70],
    :finish_star_1 => [:full_badges, nil, 1],
    :finish_star_3_mid => [:full_badges, nil, 3],
    :finish_star_3 => [:full_badges, nil, 5],
    :finish_star_10 => [:full_badges, nil, 10],
    :finish_star_7 => [:full_badges, nil, 15],
    :finish_star_11 => [:full_badges, nil, 30],
    :finish_star_40 => [:full_badges, nil, 40],
    :finish_star_20 => [:full_badges, nil, 50],
    :boss_finish_5 => [:progress_list, :boss_finished, 15],
    :boss_finish_30 => [:progress_list, :boss_finished, 30],
    :rush_finish_5 => [:progress_list, :rush_finished, 15],
    :tower_finish_3 => [:progress_list, :tower_finished, 10],
    :training_10_slots => [:pokemon_training_slots, nil, 10],
    :training_25_slots => [:pokemon_training_slots, nil, 25],
    :training_complete_one => [:pokemon_training_complete, nil, 1],
    :training_three_complete => [:pokemon_training_complete, nil, 3],
    :training_equipment_unlock => [:pokemon_training_equipment, nil, 1],
    :training_shiny_unlock => [:pokemon_training_shiny, nil, 1],
    :candies_1000 => [:candy_currency, nil, 1000],
    :candies_5000 => [:candy_currency, nil, 5000],
    :shop_5_upgrades => [:shop_slots, nil, 5],
    :shop_10_upgrades => [:shop_slots, nil, 20],
    :shop_35_upgrades => [:shop_slots, nil, 35],
    :shop_25_upgrades => [:shop_slots, nil, 45],
    :endless_shop_5 => [:endless_shop_slots, nil, 5],
    :moves_10_total => [:stat, :moves_learned_total, 10],
    :egg_5_hatches => [:stat, :egg_hatches, 5],
    :egg_15_hatches => [:stat, :egg_hatches, 15],
    :egg_all_babies => [:event_species, :egg_babies, :baby],
    :egg_munchlax => [:event_species, :egg_babies, [:MUNCHLAX]],
    :egg_shiny_first => [:stat, :egg_shiny_hatches, 1],
    :egg_shiny_3 => [:stat, :egg_shiny_hatches, 3],
    :sleep_10_awakened => [:stat, :sleep_awakened, 10],
    :sleep_all_tapu => [:event_species, :sleep_awakened_keys, :sleep],
    :tower_egg_floor_set => [:event_species, :tower_egg_floors, :tower_egg_floors],
    :event_swarm_alert_5 => [:stat, :swarm_alerts_survived, 5],
    :event_elite_hunt_10 => [:stat, :elite_hunts_defeated, 10],
    :event_elite_hunt_pair => [:event_species, :elite_hunt_species, [:GIMMIGHOUL, :DELIBIRD]],
    :event_lost_kecleon_5 => [:stat, :lost_kecleon_helped, 5],
    :event_joker_5 => [:stat, :joker_bonuses_taken, 5],
    :event_joker_all => [:event_species, :joker_bonus_ids, :joker],
    :dark_fragment_10 => [:stat, :dark_fragments_max, 10],
    :endless_shop_complete => [:endless_shop_complete, nil, 1],
    :skill_collector => [:skill_count, nil, 20],
    :battle_pass_tome1_complete => [:battle_pass_complete, :battle_pass_1, 1]
  }
  module_function

  def all
    ACHIEVEMENTS
  end

  def visible_all
    all.select { |data| !data[:hidden] || earned?(data[:id]) }
  rescue
    all.reject { |data| data[:hidden] }
  end

  def progress
    base = PokemonSurvivor.survivor_progress rescue {}
    store = base[:achievements]
    store = base["achievements"] if !store.is_a?(Hash) && base.is_a?(Hash)
    store = {} if !store.is_a?(Hash)
    normalized = {}
    store.each_pair { |k, v| normalized[k.to_sym] = v }
    base[:achievements] = normalized if base.is_a?(Hash)
    normalized
  rescue
    {}
  end

  def earned?(id)
    !!progress[id.to_sym]
  rescue
    false
  end

  def earned_count
    visible_all.count { |data| earned?(data[:id]) }
  rescue
    0
  end

  def total_count
    visible_all.length
  end

  def achievement(id)
    all.find { |data| data[:id] == id.to_sym }
  rescue
    nil
  end

  def pokemon_training_hash(save = nil)
    save ||= PokemonSurvivor.survivor_progress rescue {}
    data = save[:pokemon_training]
    data = save["pokemon_training"] if !data.is_a?(Hash) && save.is_a?(Hash)
    data.is_a?(Hash) ? data : {}
  rescue
    {}
  end

  def pokemon_training_slot_count(save = nil)
    pokemon_training_hash(save).values.inject(0) do |sum, upgrades|
      next sum if !upgrades.is_a?(Hash)
      sum + upgrades.values.inject(0) { |inner, value| inner + value.to_i }
    end
  rescue
    0
  end

  def pokemon_training_core_upgrade_ids
    return [] if !defined?(PokemonSurvivor::POKEMON_TRAINING_UPGRADES)
    excluded = PokemonSurvivor::POKEMON_TRAINING_CORE_EXCLUDED rescue []
    PokemonSurvivor::POKEMON_TRAINING_UPGRADES.map { |upgrade| upgrade[:id] }.compact.reject { |id| excluded.include?(id) }
  rescue
    []
  end

  def pokemon_training_complete_count(save = nil, include_shiny = false)
    ids = include_shiny ? (PokemonSurvivor::POKEMON_TRAINING_UPGRADES.map { |u| u[:id] } rescue []) : pokemon_training_core_upgrade_ids
    return 0 if ids.empty?
    pokemon_training_hash(save).count do |_species, upgrades|
      next false if !upgrades.is_a?(Hash)
      ids.all? do |id|
        data = PokemonSurvivor.pokemon_training_data(id) rescue nil
        max = data && data[:values] ? data[:values].length : 0
        upgrades[id.to_sym].to_i >= max && max > 0
      end
    end
  rescue
    0
  end

  def pokemon_training_upgrade_owner_count(save = nil, id = nil)
    return 0 if !id
    pokemon_training_hash(save).count do |_species, upgrades|
      upgrades.is_a?(Hash) && upgrades[id.to_sym].to_i > 0
    end
  rescue
    0
  end
  def z_move_achievement_progress
    save = PokemonSurvivor.survivor_progress
    history = save[:z_move_history].is_a?(Hash) ? save[:z_move_history] : {}
    stats = save[:battle_pass_stats].is_a?(Hash) ? save[:battle_pass_stats] : {}
    passes = save[:battle_passes].is_a?(Hash) ? save[:battle_passes] : {}
    tome = passes[:battle_pass_8] || passes["battle_pass_8"]
    tome = {} unless tome.is_a?(Hash)
    used = tome[:z_crystals_used].is_a?(Hash) ? tome[:z_crystals_used].keys : []
    used += history[:crystals].is_a?(Array) ? history[:crystals] : []
    valid = PokemonSurvivor.const_defined?(:Z_MOVE_DATA) ? PokemonSurvivor::Z_MOVE_DATA.keys.map(&:to_s) - ["eeviumz"] : []
    { activations: [history[:activations].to_i, stats[:tome8_z_activations].to_i].max,
      crystals: used.map(&:to_s).uniq & valid }
  end

  def record_z_move_activation(crystal_id)
    return false unless crystal_id && PokemonSurvivor.const_defined?(:Z_MOVE_DATA)
    return false unless PokemonSurvivor::Z_MOVE_DATA[crystal_id]
    history = z_move_achievement_progress
    history[:activations] += 1
    if crystal_id != :eeviumz && !history[:crystals].include?(crystal_id.to_s)
      history[:crystals] << crystal_id.to_s
    end
    PokemonSurvivor.survivor_progress[:z_move_history] = history
    check_additional_counters(true, :z_moves)
    true
  end

  def counter_for(data)
    data = achievement(data) if !data.is_a?(Hash)
    return nil if !data
    rule = data[:counter] || ACHIEVEMENT_COUNTERS[data[:id].to_sym]
    return nil if !rule
    save = PokemonSurvivor.survivor_progress rescue {}
    stats = achievement_stats
    kind, key, target = rule
    current = case kind
              when :z_move_count
                z_move_achievement_progress[:activations]
              when :z_move_types
                z_move_achievement_progress[:crystals].length
              when :stat
                stats[key].to_i
              when :breach_stat, :breach_species
                seasons = save[:breach_seasons].is_a?(Hash) ? save[:breach_seasons].values : []
                seasons = seasons.select { |entry| entry.is_a?(Hash) }
                if kind == :breach_stat
                  seasons.sum { |entry| entry[:stats].is_a?(Hash) ? entry[:stats][key].to_i : 0 }
                else
                  seasons.flat_map { |entry| entry[:pokemon].is_a?(Array) ? entry[:pokemon] : [] }.
                    map { |species| PokemonSurvivor.species_key(species) }.uniq.length
                end
              when :eevee_forms
                forms = save[:eevee_forms].is_a?(Array) ? save[:eevee_forms] : []
                valid = [:VAPOREON, :JOLTEON, :FLAREON, :ESPEON, :UMBREON, :LEAFEON, :GLACEON, :SYLVEON]
                (forms.map { |species| PokemonSurvivor.species_key(species) }.uniq & valid).length
              when :list
                if key == :unlocked
                  (save[:unlocked] || []).length
                else
                  list = stats[key].is_a?(Array) ? stats[key] : []
                  if key == :classic_winners
                    list = list + (PokemonSurvivor.progress_species_list(save, :survived_15) rescue [])
                  elsif key == :rush_winners
                    list = list + (PokemonSurvivor.progress_species_list(save, :rush_finished) rescue [])
                  elsif key == :tower_winners
                    list = list + (PokemonSurvivor.progress_species_list(save, :tower_finished) rescue [])
                  end
                  list.map { |entry| PokemonSurvivor.species_key(entry) rescue entry.to_sym }.uniq.length
                end
              when :progress_list
                (PokemonSurvivor.progress_species_list(save, key) rescue []).length
              when :full_badges
                (PokemonSurvivor.retroactive_finished_hero_keys(save) rescue []).length
              when :shop_slots
                upgrades = save[:shop_upgrades].is_a?(Hash) ? save[:shop_upgrades] : {}
                upgrades.values.inject(0) { |sum, value| sum + value.to_i }
              when :endless_shop_slots
                upgrades = save[:shop_upgrades].is_a?(Hash) ? save[:shop_upgrades] : {}
                upgrades.inject(0) { |sum, pair| pair[0].to_s.start_with?("endless_") ? sum + pair[1].to_i : sum }
              when :skill_count
                unlocked = (save[:unlocked] || []).map { |entry| PokemonSurvivor.species_key(entry) rescue entry.to_sym }.uniq
                skills = []
                unlocked.each do |species|
                  hero = PokemonSurvivor.hero_data(species) rescue nil
                  skills << hero[:skill] if hero && hero[:skill]
                end
                skills.compact.uniq.length
              when :event_species
                expected = case target
                           when :baby
                             PokemonSurvivor::EVENT_BABY_KEYS rescue []
                           when :sleep
                             PokemonSurvivor::EVENT_SLEEP_KEYS rescue []
                           when :joker
                             (Scene_PokemonSurvivor::JOKER_EVENT_DATA rescue []).map { |entry| entry[:id] }
                           when :tower_egg_floors
                             [15, 25, 35]
                           else
                             target.is_a?(Array) ? target : []
                           end
                have = stats[key].is_a?(Array) ? stats[key] : []
                expected = expected.map { |entry| PokemonSurvivor.species_key(entry) rescue entry.to_i }.uniq
                have = have.map { |entry| PokemonSurvivor.species_key(entry) rescue entry.to_i }.uniq
                target = expected.length
                (expected & have).length
              when :endless_shop_complete
                PokemonSurvivor.shop_tree_complete?(:endless) ? 1 : 0 rescue 0
              when :battle_pass_complete
                pass = (PokemonSurvivor::BATTLE_PASS_DATA.find { |entry| entry[:id] == key } rescue nil)
                pass && PokemonSurvivor.battle_pass_completed?(pass) ? 1 : 0
              when :pokemon_training_slots
                pokemon_training_slot_count(save)
              when :pokemon_training_complete
                pokemon_training_complete_count(save, false)
              when :pokemon_training_equipment
                pokemon_training_upgrade_owner_count(save, :training_equipment)
              when :pokemon_training_shiny
                pokemon_training_upgrade_owner_count(save, :training_shiny)
              when :candy_currency
                save[:candy_currency].to_i rescue 0
              else
                0
              end
    current = target if earned?(data[:id]) && current < target.to_i
    [current.to_i, target.to_i]
  rescue
    nil
  end
  def unlock(id, show_popup = true)
    id = id.to_sym
    return nil if earned?(id)
    data = achievement(id)
    return nil if !data
    progress[id] = Time.now.to_i
    PokemonSurvivorAchievementPopup.queue(data) if show_popup && defined?(PokemonSurvivorAchievementPopup)
    data
  rescue
    nil
  end

  def check(ids, show_popup = true)
    unlocked = []
    ids.each do |id|
      data = unlock(id, show_popup)
      unlocked << data if data
    end
    unlocked
  rescue
    []
  end

  # Called by progress-changing events and menu recovery, never by the frame loop.
  def check_additional_counters(show_popup = true, group = nil, stat_key = nil)
    candidates = ADDITIONAL_COUNTER_ACHIEVEMENTS.select do |data|
      (!group || data[:group] == group) &&
        (!stat_key || data[:counter][0, 2] == [:stat, stat_key.to_sym])
    end
    ids = candidates.filter_map do |data|
      next if earned?(data[:id])
      count = counter_for(data)
      data[:id] if count && count[1] > 0 && count[0] >= count[1]
    end
    check(ids, show_popup)
  end

  def achievement_stats
    base = PokemonSurvivor.survivor_progress rescue {}
    store = base[:achievement_stats]
    store = base["achievement_stats"] if !store.is_a?(Hash) && base.is_a?(Hash)
    store = {} if !store.is_a?(Hash)
    normalized = {}
    store.each_pair do |key, value|
      if value.is_a?(Array) && key.to_sym == :leaderboard_modes
        normalized[key.to_sym] = value.map { |entry| entry.to_s.downcase.to_sym }.uniq
      elsif value.is_a?(Array)
        normalized[key.to_sym] = value.map { |entry| PokemonSurvivor.species_key(entry) rescue entry.to_sym }.uniq
      else
        normalized[key.to_sym] = value.to_i
      end
    end
    store.replace(normalized)
    base[:achievement_stats] = store if base.is_a?(Hash)
    store
  rescue
    {}
  end

def add_stat_species(stats, key, species)
  stats[key] ||= []
  list = stats[key].map { |entry| PokemonSurvivor.species_key(entry) rescue entry.to_sym }
  species = PokemonSurvivor.species_key(species) rescue species.to_sym
  stats[key] << species if !list.include?(species)
rescue
end

def add_stat_value(stats, key, value)
  stats[key] ||= []
  normalized = PokemonSurvivor.species_key(value) rescue value.to_i
  list = stats[key].map { |entry| PokemonSurvivor.species_key(entry) rescue entry.to_i }
  stats[key] << normalized if !list.include?(normalized)
rescue
end

def increment_stat(key, amount = 1)
  stats = achievement_stats
  stats[key.to_sym] = stats[key.to_sym].to_i + amount.to_i
  check_additional_counters(true, nil, key)
  stats
rescue
  {}
end


ALT_EVOLUTION_ACHIEVEMENT_IDS = {
  :TYPHLOSION_1 => :alt_hisuian_typhlosion,
  :GALLADE      => :alt_gallade,
  :RAICHU_1     => :alt_alolan_raichu,
  :SLIGGOO_1    => :alt_hisuian_goodra,
  :GOODRA_1     => :alt_hisuian_goodra,
  :DECIDUEYE_1  => :alt_hisuian_decidueye
} unless const_defined?(:ALT_EVOLUTION_ACHIEVEMENT_IDS)

ALT_EVOLUTION_COMPLETE_IDS = [:alt_hisuian_typhlosion, :alt_gallade, :alt_alolan_raichu, :alt_hisuian_goodra, :alt_hisuian_decidueye] unless const_defined?(:ALT_EVOLUTION_COMPLETE_IDS)

def record_alternate_evolution(_base, evolved_name, show_popup = true)
  key = PokemonSurvivor.species_key(evolved_name) rescue evolved_name.to_sym
  id = ALT_EVOLUTION_ACHIEVEMENT_IDS[key]
  return [] if !id
  stats = achievement_stats
  stats[:alternate_evolutions] ||= []
  add_stat_species(stats, :alternate_evolutions, key)
  ids = [id]
  earned = ALT_EVOLUTION_COMPLETE_IDS.select { |entry| earned?(entry) || ids.include?(entry) }
  ids << :alt_forms_3 if earned.length >= 3
  ids << :alt_forms_all if (ALT_EVOLUTION_COMPLETE_IDS - earned).empty?
  check(ids, show_popup)
rescue
  []
end
def event_species_complete?(stats, key, expected)
  have = stats[key].is_a?(Array) ? stats[key] : []
  expected = expected.map { |entry| PokemonSurvivor.species_key(entry) rescue entry.to_i }.uniq
  have = have.map { |entry| PokemonSurvivor.species_key(entry) rescue entry.to_i }.uniq
  !expected.empty? && (expected - have).empty?
rescue
  false
end

  def record_run(scene, won)
    stats = achievement_stats
    mode = (scene.instance_variable_get(:@run_mode) rescue :classic).to_sym
    base = PokemonSurvivor.species_key(scene.instance_variable_get(:@hero_base_name)) rescue :UNKNOWN
    abandoned = scene.instance_variable_get(:@run_abandoned) rescue false
    stats[:runs] = stats[:runs].to_i + 1
    stats[:wins] = stats[:wins].to_i + 1 if won
    stats[:losses] = stats[:losses].to_i + 1 if !won && !abandoned
    stats[:"#{mode}_runs"] = stats[:"#{mode}_runs"].to_i + 1
    if won
      stats[:"#{mode}_wins"] = stats[:"#{mode}_wins"].to_i + 1
      add_stat_species(stats, :classic_winners, base) if mode == :classic
      add_stat_species(stats, :rush_winners, base) if mode == :rush
      add_stat_species(stats, :tower_winners, base) if mode == :tower
    end
    stats[:max_level] = [stats[:max_level].to_i, (scene.instance_variable_get(:@level).to_i rescue 1)].max
    stats[:max_score] = [stats[:max_score].to_i, (scene.instance_variable_get(:@score).to_i rescue 0)].max
    stats[:max_kills] = [stats[:max_kills].to_i, (scene.instance_variable_get(:@kills).to_i rescue 0)].max
    stats[:max_tower_floor] = [stats[:max_tower_floor].to_i, (scene.instance_variable_get(:@tower_floor).to_i rescue 0)].max if mode == :tower
    stats[:max_endless_score] = [stats[:max_endless_score].to_i, (scene.instance_variable_get(:@score).to_i rescue 0)].max if mode == :endless && !abandoned
    stats[:max_endless_seconds] = [stats[:max_endless_seconds].to_i, (scene.instance_variable_get(:@timer).to_i rescue 0)].max if mode == :endless && !abandoned
    stats
  rescue
    {}
  end

  def check_run(scene)
    mode = (scene.instance_variable_get(:@run_mode) rescue :classic).to_sym
    abandoned = scene.instance_variable_get(:@run_abandoned) rescue false
    level = scene.instance_variable_get(:@level).to_i rescue 1
    score = scene.instance_variable_get(:@score).to_i rescue 0
    timer = scene.instance_variable_get(:@timer).to_f rescue 0.0
    kills = scene.instance_variable_get(:@kills).to_i rescue 0
    tower_floor = scene.instance_variable_get(:@tower_floor).to_i rescue 0
    tower_damage = scene.instance_variable_get(:@tower_damage_taken).to_i rescue 0
    ultra = scene.instance_variable_get(:@ultra_boss_defeated) rescue false
    won = scene.leaderboard_run_won? rescue false
    base = PokemonSurvivor.species_key(scene.instance_variable_get(:@hero_base_name)) rescue :UNKNOWN
    final_form = scene.final_power_reached?(base) rescue false
    shiny_active = PokemonSurvivor.pokemon_shiny_active?(base) rescue false
    record_run(scene, won)
    ids = []
    ids << :first_run
    ids << :first_victory if won
    ids << :classic_clear if mode == :classic && won
    ids << :classic_ultra if mode == :classic && ultra
    ids << :classic_bulbasaur if mode == :classic && won && base == :BULBASAUR
    ids << :classic_cyndaquil if mode == :classic && won && base == :CYNDAQUIL
    ids << :classic_mudkip if mode == :classic && won && base == :MUDKIP
    ids << :rush_clear if mode == :rush && won
    ids << :rush_quick if mode == :rush && won && timer < 720.0
    ids << :rush_blitz if mode == :rush && won && timer < 600.0
    ids << :tower_floor_10 if mode == :tower && tower_floor >= 10
    ids << :tower_floor_20 if mode == :tower && tower_floor >= 20
    ids << :tower_floor_30 if mode == :tower && tower_floor >= 30
    ids << :tower_halfway if mode == :tower && tower_floor >= 25
    ids << :tower_floor_75 if mode == :tower && tower_floor >= 40
    ids << :tower_floor_90 if mode == :tower && tower_floor >= 50
    ids << :tower_clear if mode == :tower && won
    ids << :tower_careful if mode == :tower && tower_floor >= 40 && tower_damage < 500
    ids << :tower_precise if mode == :tower && won && tower_damage < 1500
    ids << :endless_entry if mode == :endless && !abandoned && score >= 100_000
    ids << :endless_5_minutes if mode == :endless && !abandoned && timer >= 300.0
    ids << :endless_10_minutes if mode == :endless && !abandoned && timer >= 600.0
    ids << :endless_15_minutes if mode == :endless && !abandoned && timer >= 900.0
    ids << :endless_20_minutes if mode == :endless && !abandoned && timer >= 1200.0
    ids << :endless_30_minutes if mode == :endless && !abandoned && timer >= 1800.0
    ids << :endless_45_minutes if mode == :endless && !abandoned && timer >= 2700.0
    ids << :endless_60_minutes if mode == :endless && !abandoned && timer >= 3600.0
    ids << :level_25 if level >= 25
    ids << :level_50 if level >= 50
    ids << :level_100 if level >= 100
    ids << :level_150 if level >= 150
    ids << :level_200 if level >= 200
    ids << :level_300 if level >= 300
    ids << :level_400 if level >= 400
    ids << :level_500 if level >= 500
    ids << :level_700 if level >= 700
    ids << :score_250k if score >= 250_000
    ids << :score_500k if score >= 500_000
    ids << :score_1m if score >= 1_000_000
    ids << :score_2m if score >= 2_000_000
    ids << :score_3m if score >= 3_000_000
    ids << :score_5m if score >= 5_000_000
    ids << :score_7m if score >= 7_000_000
    ids << :score_9m if score >= 9_000_000
    ids << :kills_500 if kills >= 500
    ids << :kills_1000 if kills >= 1000
    ids << :kills_2000 if kills >= 2000
    ids << :kills_3000 if kills >= 3000
    ids << :kills_5000 if kills >= 5000
    ids << :kills_7000 if kills >= 7000
    ids << :kills_9000 if kills >= 9000
    ids << :kills_10000 if kills >= 12000
    ids << :final_form if final_form
    ids << :final_level_100 if final_form && level >= 100
    ids << :training_shiny_run if shiny_active
    ids << :full_build if scene.instance_variable_get(:@upgrades_exhausted) rescue false
    ids << :reroll_empty if (scene.instance_variable_get(:@rerolls_left).to_i rescue 3) <= 0
    ids << :ban_empty if (scene.instance_variable_get(:@bans_left).to_i rescue 3) <= 0
    check(ids, true) + check_retroactive(true)
  rescue
    []
  end

  def all_survivors_required_species
    excluded = [:PSYDUCK, :WHISMUR]
    if defined?(PokemonSurvivor::Challenge::SEASONS)
      excluded.concat(PokemonSurvivor::Challenge::SEASONS.values.map { |pokemon| PokemonSurvivor.species_key(pokemon) })
    end
    if defined?(PokemonSurvivor::Titan::SEASONS)
      PokemonSurvivor::Titan::SEASONS.each_value do |season|
        pokemon = season[:reward_pokemon]
        excluded << PokemonSurvivor.species_key(pokemon) if pokemon
      end
    end
    PokemonSurvivor::BASE_HERO_KEYS.map { |key| PokemonSurvivor.species_key(key) }.uniq - excluded
  end

  def check_retroactive(show_popup = false)
    save = PokemonSurvivor.survivor_progress rescue {}
    unlocked = (save[:unlocked] || []).map { |entry| PokemonSurvivor.species_key(entry) rescue entry.to_sym }.uniq
    playable = all_survivors_required_species
    skills = []
    unlocked.each do |key|
      data = PokemonSurvivor.hero_data(key) rescue nil
      skills << data[:skill] if data && data[:skill]
    end
    shop_upgrades = save[:shop_upgrades].is_a?(Hash) ? save[:shop_upgrades] : {}
    training_slots = pokemon_training_slot_count(save)
    training_complete = pokemon_training_complete_count(save, false)
    training_equipment = pokemon_training_upgrade_owner_count(save, :training_equipment)
    training_shiny = pokemon_training_upgrade_owner_count(save, :training_shiny)
    stats = achievement_stats
    classic_winners = stats[:classic_winners].is_a?(Array) ? stats[:classic_winners] : []
    rush_winners = stats[:rush_winners].is_a?(Array) ? stats[:rush_winners] : []
    tower_winners = stats[:tower_winners].is_a?(Array) ? stats[:tower_winners] : []
    survived_15 = PokemonSurvivor.progress_species_list(save, :survived_15) rescue []
    classic_winners = (classic_winners + survived_15).map { |entry| PokemonSurvivor.species_key(entry) rescue entry.to_sym }.uniq
    rush_winners = (rush_winners + (PokemonSurvivor.progress_species_list(save, :rush_finished) rescue [])).map { |entry| PokemonSurvivor.species_key(entry) rescue entry.to_sym }.uniq
    tower_winners = (tower_winners + (PokemonSurvivor.progress_species_list(save, :tower_finished) rescue [])).map { |entry| PokemonSurvivor.species_key(entry) rescue entry.to_sym }.uniq
    bought_slots = shop_upgrades.values.inject(0) { |sum, v| sum + v.to_i }
    endless_slots = shop_upgrades.inject(0) { |sum, pair| pair[0].to_s.start_with?("endless_") ? sum + pair[1].to_i : sum }
    boss_finished = PokemonSurvivor.progress_species_list(save, :boss_finished) rescue []
    rush_finished = PokemonSurvivor.progress_species_list(save, :rush_finished) rescue []
    tower_finished = PokemonSurvivor.progress_species_list(save, :tower_finished) rescue []
    ids = []
    ids << :first_run if stats[:runs].to_i > 0
    ids << :first_victory if stats[:wins].to_i > 0
    ids << :classic_clear if !classic_winners.empty?
    ids << :comeback_attempt if stats[:runs].to_i >= 3
    ids << :habit_forming if stats[:runs].to_i >= 15
    ids << :run_regular if stats[:runs].to_i >= 30
    ids << :run_obsessed if stats[:runs].to_i >= 50
    ids << :run_marathon if stats[:runs].to_i >= 100
    leaderboard_modes = stats[:leaderboard_modes].is_a?(Array) ? stats[:leaderboard_modes].map { |entry| entry.to_sym rescue entry } : []
    ids << :leaderboard_open if stats[:leaderboard_opened].to_i > 0
    ids << :leaderboard_sort if stats[:leaderboard_sorts].to_i > 0
    ids << :leaderboard_my_runs if stats[:leaderboard_my_runs].to_i > 0
    ids << :leaderboard_filter if stats[:leaderboard_filters].to_i > 0
    ids << :leaderboard_first_submit if stats[:leaderboard_submits].to_i >= 1
    ids << :leaderboard_three_submits if stats[:leaderboard_submits].to_i >= 10
    ids << :leaderboard_25_submits if stats[:leaderboard_submits].to_i >= 25
    ids << :leaderboard_classic_submit if leaderboard_modes.include?(:classic)
    ids << :leaderboard_rush_submit if leaderboard_modes.include?(:rush)
    ids << :leaderboard_tower_submit if leaderboard_modes.include?(:tower)
    ids << :leaderboard_endless_submit if leaderboard_modes.include?(:endless)
    ids << :leaderboard_mode_set if [:classic, :rush, :tower, :endless].all? { |entry| leaderboard_modes.include?(entry) }
    ids << :options_opened if stats[:options_opened].to_i > 0
    ids << :achievements_opened if stats[:achievements_opened].to_i > 0
    ids << :shop_opened if stats[:shop_opened].to_i > 0 || bought_slots > 0
    ids << :training_opened if stats[:training_opened].to_i > 0 || training_slots > 0
    ids << :training_first_upgrade if training_slots >= 1
    ids << :training_10_slots if training_slots >= 10
    ids << :training_25_slots if training_slots >= 25
    ids << :training_complete_one if training_complete >= 1
    ids << :training_three_complete if training_complete >= 3
    ids << :training_equipment_unlock if training_equipment >= 1
    ids << :training_shiny_unlock if training_shiny >= 1
    ids << :training_shiny_run if stats[:shiny_runs_started].to_i > 0
    ids << :candies_1000 if (save[:candy_currency].to_i rescue 0) >= 1000
    ids << :candies_5000 if (save[:candy_currency].to_i rescue 0) >= 5000
    ids << :classic_three if classic_winners.length >= 5
    ids << :classic_rotation if classic_winners.length >= 10
    ids << :classic_ten if classic_winners.length >= 20
    ids << :classic_bulbasaur if classic_winners.include?(:BULBASAUR)
    ids << :classic_cyndaquil if classic_winners.include?(:CYNDAQUIL)
    ids << :classic_mudkip if classic_winners.include?(:MUDKIP)
    ids << :rush_three_wins if rush_winners.length >= 3
    ids << :rush_three if rush_winners.length >= 8
    ids << :rush_veteran if rush_winners.length >= 15
    ids << :unlock_10 if unlocked.length >= 15
    ids << :unlock_25_mid if unlocked.length >= 25
    ids << :unlock_25 if unlocked.length >= 40
    ids << :unlock_50 if unlocked.length >= 50
    ids << :unlock_40 if unlocked.length >= 60
    ids << :mew_unlocked if unlocked.include?(:MEW)
    ids << :unlock_70 if unlocked.length >= 70
    ids << :deoxys_unlocked if unlocked.include?(:DEOXYS)
    ids << :skill_collector if skills.compact.uniq.length >= 20
    ids << :all_survivors if playable.length > 0 && (playable - unlocked).empty?
    ids << :shop_first_upgrade if bought_slots >= 1
    ids << :shop_5_upgrades if bought_slots >= 5
    ids << :shop_10_upgrades if bought_slots >= 20
    ids << :shop_35_upgrades if bought_slots >= 35
    ids << :shop_25_upgrades if bought_slots >= 45
    ids << :shop_standard_complete if (PokemonSurvivor.endless_shop_currency_unlocked? rescue false)
    current_dark_fragments = save[:dark_shop_currency].to_i rescue 0
    ids << :dark_fragment if current_dark_fragments > 0
    ids << :dark_fragment_10 if current_dark_fragments >= 10 || stats[:dark_fragments_max].to_i >= 10
    ids << :egg_first_hatch if stats[:egg_hatches].to_i >= 1
    ids << :sleep_first_awaken if stats[:sleep_awakened].to_i >= 1
    ids << :moves_first if stats[:moves_learned_total].to_i >= 1
    ids << :moves_10_total if stats[:moves_learned_total].to_i >= 10
    ids << :egg_5_hatches if stats[:egg_hatches].to_i >= 5
    ids << :egg_15_hatches if stats[:egg_hatches].to_i >= 15
    ids << :sleep_10_awakened if stats[:sleep_awakened].to_i >= 10
    ids << :sleep_25_awakened if stats[:sleep_awakened].to_i >= 25
    ids << :egg_all_babies if event_species_complete?(stats, :egg_babies, (PokemonSurvivor::EVENT_BABY_KEYS rescue []))
    ids << :egg_munchlax if event_species_complete?(stats, :egg_babies, [:MUNCHLAX])
    ids << :egg_shiny_first if stats[:egg_shiny_hatches].to_i >= 1
    ids << :egg_shiny_3 if stats[:egg_shiny_hatches].to_i >= 3
    ids << :sleep_all_tapu if event_species_complete?(stats, :sleep_awakened_keys, (PokemonSurvivor::EVENT_SLEEP_KEYS rescue []))
    ids << :tower_egg_floor_set if event_species_complete?(stats, :tower_egg_floors, [15, 25, 35])
    ids << :event_swarm_alert if stats[:swarm_alerts_survived].to_i >= 1
    ids << :event_swarm_alert_5 if stats[:swarm_alerts_survived].to_i >= 5
    ids << :event_elite_hunt_first if stats[:elite_hunts_defeated].to_i >= 1
    ids << :event_elite_hunt_10 if stats[:elite_hunts_defeated].to_i >= 10
    ids << :event_gimmighoul_hunt if event_species_complete?(stats, :elite_hunt_species, [:GIMMIGHOUL])
    ids << :event_delibird_hunt if event_species_complete?(stats, :elite_hunt_species, [:DELIBIRD])
    ids << :event_elite_hunt_pair if event_species_complete?(stats, :elite_hunt_species, [:GIMMIGHOUL, :DELIBIRD])
    ids << :event_lost_kecleon if stats[:lost_kecleon_helped].to_i >= 1
    ids << :event_lost_kecleon_5 if stats[:lost_kecleon_helped].to_i >= 5
    ids << :event_joker_first if stats[:joker_bonuses_taken].to_i >= 1
    ids << :event_joker_5 if stats[:joker_bonuses_taken].to_i >= 5
    joker_ids = (Scene_PokemonSurvivor::JOKER_EVENT_DATA rescue []).map { |entry| entry[:id] }
    ids << :event_joker_all if event_species_complete?(stats, :joker_bonus_ids, joker_ids)
    ids << :endless_shop_first if endless_slots >= 1
    ids << :endless_shop_5 if endless_slots >= 5
    ids << :endless_shop_complete if (PokemonSurvivor.shop_tree_complete?(:endless) rescue false)
    tome1 = (PokemonSurvivor::BATTLE_PASS_DATA.find { |entry| entry[:id] == :battle_pass_1 } rescue nil)
    ids << :battle_pass_tome1_complete if tome1 && (PokemonSurvivor.battle_pass_completed?(tome1) rescue false)
    ids << :classic_ultra if boss_finished.length >= 1
    ids << :rush_clear if rush_finished.length >= 1
    ids << :tower_clear if tower_finished.length >= 1
    alt_forms = stats[:alternate_evolutions].is_a?(Array) ? stats[:alternate_evolutions].map { |entry| PokemonSurvivor.species_key(entry) rescue entry.to_sym } : []
    ids << :alt_hisuian_typhlosion if alt_forms.include?(:TYPHLOSION_1)
    ids << :alt_gallade if alt_forms.include?(:GALLADE)
    ids << :alt_alolan_raichu if alt_forms.include?(:RAICHU_1)
    ids << :alt_hisuian_goodra if alt_forms.include?(:SLIGGOO_1) || alt_forms.include?(:GOODRA_1)
    ids << :alt_hisuian_decidueye if alt_forms.include?(:DECIDUEYE_1)
    alt_earned = ALT_EVOLUTION_COMPLETE_IDS.select { |entry| earned?(entry) || ids.include?(entry) }
    ids << :alt_forms_3 if alt_earned.length >= 3
    ids << :alt_forms_all if (ALT_EVOLUTION_COMPLETE_IDS - alt_earned).empty?
    full = PokemonSurvivor.retroactive_finished_hero_keys(save) rescue []
    ids << :finish_star_1 if full.length >= 1
    ids << :finish_star_3_mid if full.length >= 3
    ids << :finish_star_3 if full.length >= 5
    ids << :finish_star_10 if full.length >= 10
    ids << :finish_star_7 if full.length >= 15
    ids << :finish_star_11 if full.length >= 30
    ids << :finish_star_40 if full.length >= 40
    ids << :finish_star_20 if full.length >= 50
    ids << :boss_finish_5 if boss_finished.length >= 15
    ids << :boss_finish_30 if boss_finished.length >= 30
    ids << :rush_finish_5 if rush_finished.length >= 15
    ids << :tower_finish_3 if tower_finished.length >= 10
    ids << :level_25 if stats[:max_level].to_i >= 25
    ids << :level_50 if stats[:max_level].to_i >= 50
    ids << :level_100 if stats[:max_level].to_i >= 100
    ids << :level_150 if stats[:max_level].to_i >= 150
    ids << :level_200 if stats[:max_level].to_i >= 200
    ids << :level_300 if stats[:max_level].to_i >= 300
    ids << :level_400 if stats[:max_level].to_i >= 400
    ids << :level_500 if stats[:max_level].to_i >= 500
    ids << :level_700 if stats[:max_level].to_i >= 700
    ids << :score_250k if stats[:max_score].to_i >= 250_000
    ids << :score_500k if stats[:max_score].to_i >= 500_000
    ids << :score_1m if stats[:max_score].to_i >= 1_000_000
    ids << :score_2m if stats[:max_score].to_i >= 2_000_000
    ids << :score_3m if stats[:max_score].to_i >= 3_000_000
    ids << :score_5m if stats[:max_score].to_i >= 5_000_000
    ids << :score_7m if stats[:max_score].to_i >= 7_000_000
    ids << :score_9m if stats[:max_score].to_i >= 9_000_000
    ids << :kills_500 if stats[:max_kills].to_i >= 500
    ids << :kills_1000 if stats[:max_kills].to_i >= 1000
    ids << :kills_2000 if stats[:max_kills].to_i >= 2000
    ids << :kills_3000 if stats[:max_kills].to_i >= 3000
    ids << :kills_5000 if stats[:max_kills].to_i >= 5000
    ids << :kills_7000 if stats[:max_kills].to_i >= 7000
    ids << :kills_9000 if stats[:max_kills].to_i >= 9000
    ids << :kills_10000 if stats[:max_kills].to_i >= 12000
    { tower_floor_10: 10, tower_floor_20: 20, tower_halfway: 25,
      tower_floor_30: 30, tower_floor_75: 40, tower_floor_90: 50 }.each do |id, floor|
      ids << id if stats[:max_tower_floor].to_i >= floor
    end
    ids << :endless_entry if stats[:max_endless_score].to_i >= 100_000
    { endless_5_minutes: 300, endless_10_minutes: 600, endless_15_minutes: 900,
      endless_20_minutes: 1200, endless_30_minutes: 1800,
      endless_45_minutes: 2700, endless_60_minutes: 3600 }.each do |id, seconds|
      ids << id if stats[:max_endless_seconds].to_i >= seconds
    end
    check(ids, show_popup) + check_additional_counters(show_popup)
  rescue
    []
  end

  def live_ids(scene)
    mode = (scene.instance_variable_get(:@run_mode) rescue :classic).to_sym
    abandoned = scene.instance_variable_get(:@run_abandoned) rescue false
    level = scene.instance_variable_get(:@level).to_i rescue 1
    score = scene.instance_variable_get(:@score).to_i rescue 0
    timer = scene.instance_variable_get(:@timer).to_f rescue 0.0
    tower_floor = scene.instance_variable_get(:@tower_floor).to_i rescue 0
    ids = []
    kills = scene.instance_variable_get(:@kills).to_i rescue 0
    tower_damage = scene.instance_variable_get(:@tower_damage_taken).to_i rescue 0
    base = PokemonSurvivor.species_key(scene.instance_variable_get(:@hero_base_name)) rescue :UNKNOWN
    final_form = scene.final_power_reached?(base) rescue false
    shiny_active = PokemonSurvivor.pokemon_shiny_active?(base) rescue false
    ids << :level_25 if level >= 25
    ids << :level_50 if level >= 50
    ids << :level_100 if level >= 100
    ids << :level_150 if level >= 150
    ids << :level_200 if level >= 200
    ids << :level_300 if level >= 300
    ids << :level_400 if level >= 400
    ids << :level_500 if level >= 500
    ids << :level_700 if level >= 700
    ids << :score_250k if score >= 250_000
    ids << :score_500k if score >= 500_000
    ids << :score_1m if score >= 1_000_000
    ids << :score_2m if score >= 2_000_000
    ids << :score_3m if score >= 3_000_000
    ids << :score_5m if score >= 5_000_000
    ids << :score_7m if score >= 7_000_000
    ids << :score_9m if score >= 9_000_000
    ids << :kills_500 if kills >= 500
    ids << :kills_1000 if kills >= 1000
    ids << :kills_2000 if kills >= 2000
    ids << :kills_3000 if kills >= 3000
    ids << :kills_5000 if kills >= 5000
    ids << :kills_7000 if kills >= 7000
    ids << :kills_9000 if kills >= 9000
    ids << :kills_10000 if kills >= 12000
    ids << :final_form if final_form
    ids << :final_level_100 if final_form && level >= 100
    ids << :training_shiny_run if shiny_active
    ids << :full_build if scene.instance_variable_get(:@upgrades_exhausted) rescue false
    ids << :reroll_empty if (scene.instance_variable_get(:@rerolls_left).to_i rescue 3) <= 0
    ids << :ban_empty if (scene.instance_variable_get(:@bans_left).to_i rescue 3) <= 0
    ids << :tower_floor_10 if mode == :tower && tower_floor >= 10
    ids << :tower_floor_20 if mode == :tower && tower_floor >= 20
    ids << :tower_floor_30 if mode == :tower && tower_floor >= 30
    ids << :tower_halfway if mode == :tower && tower_floor >= 25
    ids << :tower_floor_75 if mode == :tower && tower_floor >= 40
    ids << :tower_floor_90 if mode == :tower && tower_floor >= 50
    ids << :tower_careful if mode == :tower && tower_floor >= 40 && tower_damage < 500
    ids << :endless_entry if mode == :endless && !abandoned && score >= 100_000
    ids << :endless_5_minutes if mode == :endless && !abandoned && timer >= 300.0
    ids << :endless_10_minutes if mode == :endless && !abandoned && timer >= 600.0
    ids << :endless_15_minutes if mode == :endless && !abandoned && timer >= 900.0
    ids << :endless_20_minutes if mode == :endless && !abandoned && timer >= 1200.0
    ids << :endless_30_minutes if mode == :endless && !abandoned && timer >= 1800.0
    ids << :endless_45_minutes if mode == :endless && !abandoned && timer >= 2700.0
    ids << :endless_60_minutes if mode == :endless && !abandoned && timer >= 3600.0
    ids
  rescue
    []
  end

  def record_leaderboard_submit(scene)
    stats = achievement_stats
    mode = (scene.instance_variable_get(:@run_mode) rescue :classic).to_sym
    base = PokemonSurvivor.species_key(scene.instance_variable_get(:@hero_base_name)) rescue :UNKNOWN
    stats[:leaderboard_submits] = stats[:leaderboard_submits].to_i + 1
    add_stat_species(stats, :leaderboard_pokemon, base)
    stats[:leaderboard_modes] ||= []
    modes = stats[:leaderboard_modes].map { |entry| entry.to_sym rescue entry }
    stats[:leaderboard_modes] << mode if !modes.include?(mode)
    ids = [:leaderboard_first_submit]
    ids << :leaderboard_three_submits if stats[:leaderboard_submits].to_i >= 10
    ids << :leaderboard_25_submits if stats[:leaderboard_submits].to_i >= 25
    ids << :leaderboard_classic_submit if mode == :classic
    ids << :leaderboard_rush_submit if mode == :rush
    ids << :leaderboard_tower_submit if mode == :tower
    ids << :leaderboard_endless_submit if mode == :endless
    modes = stats[:leaderboard_modes].map { |entry| entry.to_sym rescue entry }
    ids << :leaderboard_mode_set if [:classic, :rush, :tower, :endless].all? { |entry| modes.include?(entry) }
    check(ids, true)
  rescue
    []
  end
  def rarity_name(rarity)
    RARITY_NAMES[rarity.to_i] || RARITY_NAMES[1]
  end

  def rarity_color(rarity)
    RARITY_COLORS[rarity.to_i] || RARITY_COLORS[1]
  end

  def medal_name(rarity)
    "#{rarity.to_i}STAR"
  end
end


# Lightweight global achievement pop-up. It keeps one bitmap/sprite alive and only



