#===============================================================================
# Pokemon Survivor - Battle Pass Tomes
#===============================================================================

module PokemonSurvivor
  CHARMANDER_LINE = [:CHARMANDER, :CHARMELEON, :CHARIZARD].freeze unless const_defined?(:CHARMANDER_LINE)
  TREECKO_LINE = [:TREECKO, :GROVYLE, :SCEPTILE, :SCEPTILE_1].freeze unless const_defined?(:TREECKO_LINE)
  CHARIZARDITE_ITEM_ID = :charizardite unless const_defined?(:CHARIZARDITE_ITEM_ID)

  def self.append_unique(array, value)
    array << value if array && !array.include?(value)
  rescue
  end

  def self.insert_hero_before(anchor, values)
    values.each { |value| HERO_ORDER.delete(value) } if const_defined?(:HERO_ORDER)
    index = HERO_ORDER.index(anchor) || HERO_ORDER.length
    HERO_ORDER.insert(index, *values)
  rescue
  end

  def self.redefine_const(name, value)
    remove_const(name) if const_defined?(name)
    const_set(name, value)
  rescue
  end

  def self.tome1_quests
    [
      { id: :run_3, name: "First Steps", desc: "Complete 3 runs.", metric: :runs, target: 3, xp: 80 },
      { id: :run_10, name: "Again and Again", desc: "Complete 10 runs.", metric: :runs, target: 10, xp: 160 },
      { id: :classic_3, name: "Classic Training", desc: "Complete 3 Classic runs.", metric: :classic_runs, target: 3, xp: 130 },
      { id: :rush_2, name: "Rush Practice", desc: "Complete 2 Rush runs.", metric: :rush_runs, target: 2, xp: 150 },
      { id: :tower_1, name: "Tower Climber", desc: "Complete 1 Tower run.", metric: :tower_runs, target: 1, xp: 180 },
      { id: :endless_15, name: "Endless Warmup", desc: "Survive 15 minutes in Endless total.", metric: :endless_seconds, target: 900, xp: 170 },
      { id: :kills_2500, name: "Crowd Control", desc: "Defeat 2500 enemies.", metric: :kills, target: 2500, xp: 220 },
      { id: :kills_7500, name: "Battle Flow", desc: "Defeat 7500 enemies.", metric: :kills, target: 7500, xp: 340 },
      { id: :score_1m, name: "Score Hunter", desc: "Earn 1000000 total score.", metric: :score, target: 1_000_000, xp: 230 },
      { id: :score_5m, name: "Score Master", desc: "Earn 5000000 total score.", metric: :score, target: 5_000_000, xp: 420 },
      { id: :level_100, name: "Level Break", desc: "Reach level 100 in a run.", metric: :highest_level, target: 100, xp: 260 },
      { id: :wins_5, name: "Clean Victory", desc: "Win 5 runs.", metric: :wins, target: 5, xp: 360 },
      { id: :magikarp_runs, name: "Splash Debut", desc: "Complete 3 runs with Magikarp.", metric: :magikarp_runs, target: 3, xp: 160 },
      { id: :magikarp_level, name: "Tiny Current", desc: "Reach level 50 with Magikarp.", metric: :magikarp_highest_level, target: 50, xp: 190 },
      { id: :magikarp_win, name: "Brave Splash", desc: "Win a run with Magikarp.", metric: :magikarp_wins, target: 1, xp: 250 },
      { id: :run_25, name: "Another Lap", desc: "Complete 25 runs.", metric: :runs, target: 25, xp: 520 },
      { id: :wins_12, name: "Victory Current", desc: "Win 12 runs.", metric: :wins, target: 12, xp: 640 },
      { id: :score_12m, name: "Score Legend", desc: "Earn 12000000 total score.", metric: :score, target: 12_000_000, xp: 620 },
      { id: :magikarp_kills, name: "Splash Payoff", desc: "Defeat 5000 enemies with Magikarp.", metric: :magikarp_kills, target: 5000, xp: 360 },
      { id: :feebas_runs, name: "Prism Debut", desc: "Complete 3 runs with Feebas.", metric: :feebas_runs, target: 3, xp: 260 },
      { id: :feebas_level, name: "Prism Scale", desc: "Reach level 70 with Feebas.", metric: :feebas_highest_level, target: 70, xp: 320 },
      { id: :feebas_win, name: "Beautiful Current", desc: "Win a run with Feebas.", metric: :feebas_wins, target: 1, xp: 420 },
      { id: :run_40, name: "Tome Regular", desc: "Complete 40 runs.", metric: :runs, target: 40, xp: 450 },
      { id: :wins_20, name: "Tome Victor", desc: "Win 20 runs.", metric: :wins, target: 20, xp: 650 },
      { id: :kills_15000, name: "Fish Route Sweep", desc: "Defeat 15000 enemies.", metric: :kills, target: 15_000, xp: 650 },
      { id: :score_25m, name: "Deep Current", desc: "Earn 25000000 total score.", metric: :score, target: 25_000_000, xp: 700 },
      { id: :level_200, name: "Strong Current", desc: "Reach level 200 in a run.", metric: :highest_level, target: 200, xp: 500 },
      { id: :endless_30, name: "Long Swim", desc: "Survive 30 minutes in Endless total.", metric: :endless_seconds, target: 1800, xp: 420 },
      { id: :magikarp_level_120, name: "Golden Splash", desc: "Reach level 120 with Magikarp.", metric: :magikarp_highest_level, target: 120, xp: 350 },
      { id: :feebas_kills, name: "Prism Payoff", desc: "Defeat 3000 enemies with Feebas.", metric: :feebas_kills, target: 3000, xp: 420 },
      { id: :feebas_level_150, name: "Milotic Dream", desc: "Reach level 150 with Feebas.", metric: :feebas_highest_level, target: 150, xp: 450 }
    ]
  end

  def self.tome1_rewards
    [
      { tier: 1, type: :hero, id: :MAGIKARP, name: "Magikarp", amount: 1, rarity: :legendary },
      { tier: 2, type: :candy, amount: 30, rarity: :common },
      { tier: 3, type: :fragment, amount: 120, rarity: :common },
      { tier: 4, type: :equipment, id: :mystic_water, name: "Mystic Water", amount: 1, rarity: :rare },
      { tier: 5, type: :candy, amount: 45, rarity: :common },
      { tier: 6, type: :fragment, amount: 180, rarity: :common },
      { tier: 7, type: :candy, amount: 55, rarity: :common },
      { tier: 8, type: :fragment, amount: 240, rarity: :common },
      { tier: 9, type: :equipment, id: :lucky_egg, name: "Lucky Egg", amount: 1, rarity: :rare },
      { tier: 10, type: :fragment, amount: 340, rarity: :rare },
      { tier: 11, type: :candy, amount: 70, rarity: :common },
      { tier: 12, type: :fragment, amount: 420, rarity: :rare },
      { tier: 13, type: :candy, amount: 85, rarity: :rare },
      { tier: 14, type: :equipment, id: :guardian_feather, name: "Guardian Feather", amount: 1, rarity: :super_rare },
      { tier: 15, type: :fragment, amount: 560, rarity: :rare },
      { tier: 16, type: :candy, amount: 105, rarity: :rare },
      { tier: 17, type: :fragment, amount: 700, rarity: :rare },
      { tier: 18, type: :candy, amount: 125, rarity: :rare },
      { tier: 19, type: :fragment, amount: 850, rarity: :rare },
      { tier: 20, type: :equipment, id: :old_coin, name: "Old Coin", amount: 1, rarity: :epic },
      { tier: 21, type: :candy, amount: 150, rarity: :rare },
      { tier: 22, type: :fragment, amount: 1050, rarity: :super_rare },
      { tier: 23, type: :candy, amount: 180, rarity: :super_rare },
      { tier: 24, type: :fragment, amount: 1250, rarity: :super_rare },
      { tier: 25, type: :candy, amount: 220, rarity: :super_rare },
      { tier: 26, type: :fragment, amount: 1450, rarity: :super_rare },
      { tier: 27, type: :candy, amount: 260, rarity: :super_rare },
      { tier: 28, type: :fragment, amount: 1700, rarity: :super_rare },
      { tier: 29, type: :candy, amount: 320, rarity: :epic },
      { tier: 30, type: :equipment, id: :shiny_brooch, name: "Shiny Brooch", amount: 1, rarity: :legendary },
      { tier: 31, type: :hero, id: :FEEBAS, name: "Feebas", amount: 1, rarity: :legendary },
      { tier: 32, type: :candy, amount: 90, rarity: :common },
      { tier: 33, type: :fragment, amount: 650, rarity: :rare },
      { tier: 34, type: :candy, amount: 105, rarity: :rare },
      { tier: 35, type: :fragment, amount: 800, rarity: :rare },
      { tier: 36, type: :equipment, id: :magnet_pin, name: "Magnet Pin", amount: 1, rarity: :rare },
      { tier: 37, type: :fragment, amount: 950, rarity: :rare },
      { tier: 38, type: :candy, amount: 135, rarity: :rare },
      { tier: 39, type: :fragment, amount: 1100, rarity: :super_rare },
      { tier: 40, type: :equipment, id: :berry_pouch, name: "Berry Pouch", amount: 1, rarity: :super_rare },
      { tier: 41, type: :fragment, amount: 1250, rarity: :super_rare },
      { tier: 42, type: :candy, amount: 170, rarity: :super_rare },
      { tier: 43, type: :fragment, amount: 1450, rarity: :super_rare },
      { tier: 44, type: :equipment, id: :focus_lens, name: "Focus Lens", amount: 1, rarity: :epic },
      { tier: 45, type: :fragment, amount: 1650, rarity: :super_rare },
      { tier: 46, type: :candy, amount: 210, rarity: :super_rare },
      { tier: 47, type: :fragment, amount: 1850, rarity: :epic },
      { tier: 48, type: :equipment, id: :shell_bell, name: "Shell Bell", amount: 1, rarity: :epic },
      { tier: 49, type: :fragment, amount: 2100, rarity: :epic },
      { tier: 50, type: :candy, amount: 260, rarity: :epic },
      { tier: 51, type: :fragment, amount: 2350, rarity: :epic },
      { tier: 52, type: :equipment, id: :boss_bell, name: "Boss Bell", amount: 1, rarity: :legendary },
      { tier: 53, type: :fragment, amount: 2600, rarity: :epic },
      { tier: 54, type: :candy, amount: 315, rarity: :epic },
      { tier: 55, type: :fragment, amount: 2900, rarity: :epic },
      { tier: 56, type: :equipment, id: :quick_claw, name: "Quick Claw", amount: 1, rarity: :legendary },
      { tier: 57, type: :fragment, amount: 3200, rarity: :legendary },
      { tier: 58, type: :candy, amount: 380, rarity: :legendary },
      { tier: 59, type: :fragment, amount: 3600, rarity: :legendary },
      { tier: 60, type: :equipment, id: :endless_token, name: "Endless Token", amount: 1, rarity: :legendary }
    ]
  end

  def self.tome1_texts
    texts = [
      "Battle Pass", "Tome", "Locked", "Unlocked", "Completed", "Unlock", "Rewards", "Quests", "Ready", "Claimed", "Level", "EXP",
      "Auto Claim", "Gain {1}", "Requires {1} Candies.", "Complete the previous Tome first.", "Open Battle Pass", "Quest reward claimed.",
      "All ready rewards claimed.", "All ready quests claimed.", "Not enough Candies.", "Battle Pass unlocked.", "No completed quest to claim.",
      "Tome 1: Legend of the Fish", "First Steps", "Complete 3 runs.", "Again and Again", "Complete 10 runs.",
      "Classic Training", "Complete 3 Classic runs.", "Rush Practice", "Complete 2 Rush runs.", "Tower Climber", "Complete 1 Tower run.",
      "Endless Warmup", "Survive 15 minutes in Endless total.", "Crowd Control", "Defeat 2500 enemies.", "Battle Flow", "Defeat 7500 enemies.",
      "Score Hunter", "Earn 1000000 total score.", "Score Master", "Earn 5000000 total score.", "Level Break", "Reach level 100 in a run.",
      "Clean Victory", "Win 5 runs.", "Splash Debut", "Complete 3 runs with Magikarp.", "Tiny Current", "Reach level 50 with Magikarp.",
      "Brave Splash", "Win a run with Magikarp.", "Another Lap", "Complete 25 runs.", "Victory Current", "Win 12 runs.",
      "Score Legend", "Earn 12000000 total score.", "Splash Payoff", "Defeat 5000 enemies with Magikarp.", "Prism Debut", "Complete 3 runs with Feebas.",
      "Prism Scale", "Reach level 70 with Feebas.", "Beautiful Current", "Win a run with Feebas.", "Tome Regular", "Complete 40 runs.",
      "Tome Victor", "Win 20 runs.", "Fish Route Sweep", "Defeat 15000 enemies.", "Deep Current", "Earn 25000000 total score.",
      "Strong Current", "Reach level 200 in a run.", "Long Swim", "Survive 30 minutes in Endless total.", "Golden Splash", "Reach level 120 with Magikarp.",
      "Prism Payoff", "Defeat 3000 enemies with Feebas.", "Milotic Dream", "Reach level 150 with Feebas.",
      "Magikarp", "Feebas", "Mystic Water", "Lucky Egg", "Guardian Feather", "Old Coin", "Shiny Brooch", "Magnet Pin", "Berry Pouch",
      "Focus Lens", "Shell Bell", "Boss Bell", "Quick Claw", "Endless Token", "Candy", "Fragment"
    ]
    texts.map { |text| _INTL(text) }
  end

  def self.register_tome1_battle_pass
    redefine_const(:BATTLE_PASS_QUESTS, tome1_quests.freeze)
    passes = const_defined?(:BATTLE_PASS_DATA) ? BATTLE_PASS_DATA.dup : []
    passes.reject! { |pass| pass[:id] == :battle_pass_1 }
    passes.unshift({ id: :battle_pass_1, name: "Tome 1: Legend of the Fish", cost: 1000, quests: BATTLE_PASS_QUESTS, rewards: tome1_rewards })
    redefine_const(:BATTLE_PASS_DATA, passes.freeze)
    redefine_const(:BATTLE_PASS_TEXT_FOR_EXTRACTION, tome1_texts.freeze)
  end
  def self.charizardite_compatible?(pokemon)
    key = species_key(pokemon)
    CHARMANDER_LINE.include?(key)
  rescue
    false
  end

  def self.register_charmander_tome2_data
    insert_hero_before(:MAGIKARP, CHARMANDER_LINE + TREECKO_LINE) if const_defined?(:HERO_ORDER)
    if const_defined?(:HERO_BASE)
      HERO_BASE[:CHARMANDER] = { hp: 92, speed: 2.70, skill: :fire_twister, color: Color.new(255, 126, 62) }
      HERO_BASE[:CHARMELEON] = { hp: 112, speed: 2.62, skill: :fire_twister, color: Color.new(255, 112, 54) }
      HERO_BASE[:CHARIZARD] = { hp: 144, speed: 2.78, skill: :fire_twister, color: Color.new(255, 138, 66) }
      HERO_BASE[:CHARIZARD_1] = { hp: 144, speed: 2.78, skill: :fire_twister, color: Color.new(255, 188, 82) }
      HERO_BASE[:TREECKO] = { hp: 96, speed: 2.92, skill: :leaf_blade_sweep, color: Color.new(96, 224, 118) }
      HERO_BASE[:GROVYLE] = { hp: 116, speed: 3.04, skill: :leaf_blade_sweep, color: Color.new(86, 210, 110) }
      HERO_BASE[:SCEPTILE] = { hp: 138, speed: 3.16, skill: :leaf_blade_sweep, color: Color.new(76, 196, 102) }
      HERO_BASE[:SCEPTILE_1] = { hp: 138, speed: 3.16, skill: :leaf_blade_sweep, color: Color.new(112, 232, 130) }
    end
    append_unique(BASE_HERO_KEYS, :CHARMANDER) if const_defined?(:BASE_HERO_KEYS)
    append_unique(BASE_HERO_KEYS, :TREECKO) if const_defined?(:BASE_HERO_KEYS)
    if const_defined?(:BATTLE_PASS_HIDDEN_HERO_KEYS)
      append_unique(BATTLE_PASS_HIDDEN_HERO_KEYS, :CHARMANDER)
      append_unique(BATTLE_PASS_HIDDEN_HERO_KEYS, :TREECKO)
    end
    HERO_EVOLUTION_LEVELS[:CHARMANDER] = [24, 54] if const_defined?(:HERO_EVOLUTION_LEVELS)
    if const_defined?(:HERO_EVOLUTION_OVERRIDES)
      HERO_EVOLUTION_OVERRIDES[:CHARMANDER] = :CHARMELEON
      HERO_EVOLUTION_OVERRIDES[:CHARMELEON] = :CHARIZARD
    end
    if const_defined?(:HERO_UNLOCK_REQUIREMENTS)
      HERO_UNLOCK_REQUIREMENTS[:CHARMANDER] = "Unlock Battle Pass II Tier 1."
      HERO_UNLOCK_REQUIREMENTS[:TREECKO] = "Unlock Battle Pass II Tier 31."
    end
    if const_defined?(:HERO_PASSIVES)
      HERO_PASSIVES[:CHARMANDER] = { name: "Flame Spiral", desc: "Fire Tornado lasts longer and burns enemies more reliably." }
      HERO_PASSIVES[:TREECKO] = { name: "Leaf Tempo", desc: "Leaf Blade Sweep recharges faster after pushing enemies back." }
    end
    if const_defined?(:EIGHT_DIRECTION_ASSET_FRAMES)
      EIGHT_DIRECTION_ASSET_FRAMES["CHARMANDER"] = 4
      EIGHT_DIRECTION_ASSET_FRAMES["CHARMANDER_IDLE"] = 4
      EIGHT_DIRECTION_ASSET_FRAMES["CHARMELEON"] = 4
      EIGHT_DIRECTION_ASSET_FRAMES["CHARMELEON_IDLE"] = 6
      EIGHT_DIRECTION_ASSET_FRAMES["CHARIZARD"] = 5
      EIGHT_DIRECTION_ASSET_FRAMES["CHARIZARD_IDLE"] = 5
      EIGHT_DIRECTION_ASSET_FRAMES["CHARIZARD_1"] = 4
      EIGHT_DIRECTION_ASSET_FRAMES["CHARIZARD_1_IDLE"] = 4
      EIGHT_DIRECTION_ASSET_FRAMES["TREECKO"] = 4
      EIGHT_DIRECTION_ASSET_FRAMES["TREECKO_IDLE"] = 3
      EIGHT_DIRECTION_ASSET_FRAMES["GROVYLE"] = 5
      EIGHT_DIRECTION_ASSET_FRAMES["GROVYLE_IDLE"] = 2
      EIGHT_DIRECTION_ASSET_FRAMES["SCEPTILE"] = 4
      EIGHT_DIRECTION_ASSET_FRAMES["SCEPTILE_IDLE"] = 2
      EIGHT_DIRECTION_ASSET_FRAMES["SCEPTILE_1"] = 4
      EIGHT_DIRECTION_ASSET_FRAMES["SCEPTILE_1_IDLE"] = 2
    end
    register_charmander_skill_data
    register_charizardite_equipment
    register_tome2_battle_pass
  rescue
  end

  def self.register_charmander_skill_data
    return if !const_defined?(:SKILLS) || !const_defined?(:ULTIMATES)
    SKILLS[:fire_twister] = {
      name: "Fire Tornado",
      desc: "Summons a fire tornado on enemies. It can burn everything it touches.",
      kind: :fire_twister, type: :FIRE, cooldown: 1.24, damage: 11, radius: 42, range: 220,
      duration: 1.18, dot: 2.2, count: 1, max_count: 4, vfx: "VFX_FIRE3", vfx_fps: 12, vfx_loop: false
    }
    ultimate = {
      name: "Wildfire Spiral",
      desc: "Creates eight fire tornadoes on random enemies.",
      kind: :fire_twister_burst, type: :FIRE, cooldown: 74.0, damage: 17, radius: 48, range: 520,
      duration: 1.36, dot: 3.0, count: 8, vfx: "VFX_FIRE3", vfx_fps: 14, vfx_loop: false
    }
    ULTIMATES[:CHARMANDER] = ultimate
    ULTIMATES[:CHARMELEON] = ultimate
    ULTIMATES[:CHARIZARD] = ultimate
    SKILLS[:leaf_blade_sweep] = {
      name: "Leaf Blade Sweep",
      desc: "Creates grass sweeps near the Pokemon that aim at nearby enemies.",
      kind: :survivor_swing, type: :GRASS, cooldown: 0.76, damage: 17, radius: 34,
      count: 1, max_count: 6, knockback: 38, knock_limit: 1, duration: 0.30,
      arc: Math::PI * 2.0, spin_speed: 0.0, full_swing: false, radial_hit: true,
      vfx: "VFX_GRASS3", vfx_fps: 30, vfx_loop: false, visual_offset_mult: 1.28, hit_radius_mult: 1.0, visual_scale: 1.35, visual_radius_base: 48, target_nearest: true
    }
    treecko_barrage = {
      id: :ultimate_treecko, name: "Leafblade Barrage",
      desc: "Fires very fast rotating grass shots for 5 seconds.",
      kind: :treecko_barrage, type: :GRASS, cooldown: 44.0, damage: 12, speed: 8.2, radius: 124,
      barrage_time: 5.0, shot_interval: 0.09, pierce: 3, knockback: 26, vfx: "VFX_GRASS2"
    }
    TREECKO_LINE.each { |key| ULTIMATES[key] = treecko_barrage }
    if const_defined?(:UPGRADE_POOL) && !UPGRADE_POOL.any? { |entry| entry[:id] == :learn_fire_twister }
      pool = UPGRADE_POOL.dup
      pool << { id: :learn_fire_twister, name: "Learn Fire Tornado", desc: "Adds fire tornadoes that can burn enemies.", max: 1, skill: :fire_twister, rarity: :epic }
      redefine_const(:UPGRADE_POOL, pool.freeze)
    end
  rescue
  end

  def self.register_charizardite_equipment
    return if !const_defined?(:EQUIPMENT_ITEMS)
    items = EQUIPMENT_ITEMS.dup
    unless items.any? { |item| item[:id] == CHARIZARDITE_ITEM_ID }
      items << { id: CHARIZARDITE_ITEM_ID, name: "Charizardite", desc: "Charizard can Mega Evolve after Burst is fully charged.", effect: :charizardite, rarity: :legendary, icon: "CHARIZARDITE" }
    end
    redefine_const(:EQUIPMENT_ITEMS, items.freeze)
    if const_defined?(:BATTLE_PASS_LOCKED_EQUIPMENT_IDS)
      locked = BATTLE_PASS_LOCKED_EQUIPMENT_IDS.dup
      append_unique(locked, CHARIZARDITE_ITEM_ID)
      redefine_const(:BATTLE_PASS_LOCKED_EQUIPMENT_IDS, locked.freeze)
    end
  rescue
  end

  def self.tome2_rewards
    rewards = []
    rewards << { tier: 1, kind: :hero, hero: :CHARMANDER, amount: 1, icon: "CHARMANDER", name: "Charmander", rarity: :legendary, text: "Unlock Charmander." }
    rewards << { tier: 2, kind: :candy, amount: 35, icon: "ICON_CANDY", name: "Candy Cache", rarity: :common, text: "Gain 35 Candies." }
    rewards << { tier: 3, kind: :fragment, amount: 150, icon: "ICON_FRAGMENT", name: "Fragment Cache", rarity: :common, text: "Gain 150 Fragments." }
    rewards << { tier: 4, kind: :equipment, equipment: :charcoal, amount: 1, icon: "Charcoal", name: "Charcoal", rarity: :uncommon, text: "Unlock Charcoal equipment." }
    rewards << { tier: 5, kind: :candy, amount: 50, icon: "ICON_CANDY", name: "Candy Cache", rarity: :common, text: "Gain 50 Candies." }
    rewards << { tier: 6, kind: :fragment, amount: 220, icon: "ICON_FRAGMENT", name: "Fragment Cache", rarity: :common, text: "Gain 220 Fragments." }
    rewards << { tier: 7, kind: :candy, amount: 65, icon: "ICON_CANDY", name: "Candy Cache", rarity: :rare, text: "Gain 65 Candies." }
    rewards << { tier: 8, kind: :equipment, equipment: :sharp_beak, amount: 1, icon: "Sharp Beak", name: "Sharp Beak", rarity: :uncommon, text: "Unlock Sharp Beak equipment." }
    rewards << { tier: 9, kind: :fragment, amount: 340, icon: "ICON_FRAGMENT", name: "Fragment Cache", rarity: :rare, text: "Gain 340 Fragments." }
    rewards << { tier: 10, kind: :candy, amount: 90, icon: "ICON_CANDY", name: "Candy Cache", rarity: :rare, text: "Gain 90 Candies." }
    rewards << { tier: 11, kind: :fragment, amount: 460, icon: "ICON_FRAGMENT", name: "Fragment Cache", rarity: :rare, text: "Gain 460 Fragments." }
    rewards << { tier: 12, kind: :equipment, equipment: :dragon_fang, amount: 1, icon: "Dragon Fang", name: "Dragon Fang", rarity: :uncommon, text: "Unlock Dragon Fang equipment." }
    rewards << { tier: 13, kind: :candy, amount: 110, icon: "ICON_CANDY", name: "Candy Cache", rarity: :rare, text: "Gain 110 Candies." }
    rewards << { tier: 14, kind: :fragment, amount: 620, icon: "ICON_FRAGMENT", name: "Fragment Cache", rarity: :super_rare, text: "Gain 620 Fragments." }
    rewards << { tier: 15, kind: :equipment, equipment: :scope_charm, amount: 1, icon: "Scope Charm", name: "Scope Charm", rarity: :rare, text: "Unlock Scope Charm equipment." }
    rewards << { tier: 16, kind: :candy, amount: 135, icon: "ICON_CANDY", name: "Candy Cache", rarity: :super_rare, text: "Gain 135 Candies." }
    rewards << { tier: 17, kind: :fragment, amount: 780, icon: "ICON_FRAGMENT", name: "Fragment Cache", rarity: :super_rare, text: "Gain 780 Fragments." }
    rewards << { tier: 18, kind: :candy, amount: 155, icon: "ICON_CANDY", name: "Candy Cache", rarity: :super_rare, text: "Gain 155 Candies." }
    rewards << { tier: 19, kind: :fragment, amount: 940, icon: "ICON_FRAGMENT", name: "Fragment Cache", rarity: :super_rare, text: "Gain 940 Fragments." }
    rewards << { tier: 20, kind: :equipment, equipment: :safety_orb, amount: 1, icon: "Safety Orb", name: "Safety Orb", rarity: :rare, text: "Unlock Safety Orb equipment." }
    rewards << { tier: 21, kind: :candy, amount: 180, icon: "ICON_CANDY", name: "Candy Cache", rarity: :super_rare, text: "Gain 180 Candies." }
    rewards << { tier: 22, kind: :fragment, amount: 1180, icon: "ICON_FRAGMENT", name: "Fragment Cache", rarity: :epic, text: "Gain 1180 Fragments." }
    rewards << { tier: 23, kind: :candy, amount: 210, icon: "ICON_CANDY", name: "Candy Cache", rarity: :epic, text: "Gain 210 Candies." }
    rewards << { tier: 24, kind: :fragment, amount: 1380, icon: "ICON_FRAGMENT", name: "Fragment Cache", rarity: :epic, text: "Gain 1380 Fragments." }
    rewards << { tier: 25, kind: :equipment, equipment: :spell_tag, amount: 1, icon: "Spell Tag", name: "Spell Tag", rarity: :uncommon, text: "Unlock Spell Tag equipment." }
    rewards << { tier: 26, kind: :candy, amount: 245, icon: "ICON_CANDY", name: "Candy Cache", rarity: :epic, text: "Gain 245 Candies." }
    rewards << { tier: 27, kind: :fragment, amount: 1600, icon: "ICON_FRAGMENT", name: "Fragment Cache", rarity: :epic, text: "Gain 1600 Fragments." }
    rewards << { tier: 28, kind: :candy, amount: 290, icon: "ICON_CANDY", name: "Candy Cache", rarity: :epic, text: "Gain 290 Candies." }
    rewards << { tier: 29, kind: :fragment, amount: 1850, icon: "ICON_FRAGMENT", name: "Fragment Cache", rarity: :legendary, text: "Gain 1850 Fragments." }
    rewards << { tier: 30, kind: :equipment, equipment: :charizardite, amount: 1, icon: "CHARIZARDITE", name: "Charizardite", rarity: :legendary, text: "Unlock Charizardite equipment." }
    rewards << { tier: 31, kind: :hero, hero: :TREECKO, amount: 1, icon: "TREECKO", name: "Treecko", rarity: :legendary, text: "Unlock Treecko." }
    extras = [
      [:candy, 120], [:fragment, 850], [:equipment, :miracle_seed], [:candy, 145], [:fragment, 1000],
      [:candy, 165], [:fragment, 1180], [:equipment, :black_glasses], [:candy, 190], [:fragment, 1360],
      [:equipment, :metal_coat], [:candy, 220], [:fragment, 1580], [:candy, 255], [:equipment, :fairy_feather],
      [:fragment, 1820], [:candy, 295], [:fragment, 2100], [:equipment, :hard_stone], [:candy, 340],
      [:fragment, 2400], [:equipment, :never_melt_ice], [:candy, 395], [:fragment, 2750], [:equipment, :black_belt],
      [:candy, 460], [:equipment, :sceptilite], [:equipment, :poison_barb]
    ]
    tier = 32
    extras.each do |kind, value|
      if kind == :candy
        rewards << { tier: tier, kind: :candy, amount: value, icon: "ICON_CANDY", name: "Candy Cache", rarity: tier >= 50 ? :legendary : :epic, text: "Gain #{value} Candies." }
      elsif kind == :fragment
        rewards << { tier: tier, kind: :fragment, amount: value, icon: "ICON_FRAGMENT", name: "Fragment Cache", rarity: tier >= 50 ? :legendary : :epic, text: "Gain #{value} Fragments." }
      else
        # Mega equipment is registered after the tomes during plugin loading.
        item = value == :sceptilite ? { name: "Sceptilite", icon: "SCEPTILITE", rarity: :legendary } : equipment_data(value)
        item_name = item ? item[:name].to_s : value.to_s
        item_icon = value == :sceptilite ? item[:icon] : item_name
        rewards << { tier: tier, kind: :equipment, equipment: value, amount: 1, icon: item_icon, name: item_name, rarity: item && item[:rarity] ? item[:rarity] : :rare, text: "Unlock #{item_name} equipment." }
      end
      tier += 1
    end
    rewards << { tier: 60, kind: :equipment, equipment: :training_band, amount: 1, icon: "Training Band", name: "Training Band", rarity: :legendary, text: "Unlock Training Band equipment." }
    rewards.sort_by { |r| r[:tier].to_i }.uniq { |r| r[:tier].to_i }
  rescue
    []
  end

  def self.tome2_quests
    [
      { id: :charmander_runs, name: "Flame Debut", desc: "Complete 3 runs with Charmander.", metric: :charmander_runs, target: 3, xp: 170 },
      { id: :charmander_level, name: "Rising Ember", desc: "Reach level 60 with Charmander.", metric: :charmander_highest_level, target: 60, xp: 210 },
      { id: :charmander_win, name: "Burning Victory", desc: "Win a run with Charmander.", metric: :charmander_wins, target: 1, xp: 310 },
      { id: :charmander_kills, name: "Wildfire Sweep", desc: "Defeat 4000 enemies with Charmander.", metric: :charmander_kills, target: 4000, xp: 390 },
      { id: :charmander_level_150, name: "Charizard Flight", desc: "Reach level 150 with Charmander.", metric: :charmander_highest_level, target: 150, xp: 470 },
      { id: :treecko_runs, name: "Forest Debut", desc: "Complete 3 runs with Treecko.", metric: :treecko_runs, target: 3, xp: 250 },
      { id: :treecko_level, name: "Branch Climber", desc: "Reach level 80 with Treecko.", metric: :treecko_highest_level, target: 80, xp: 320 },
      { id: :treecko_win, name: "Leaf Victory", desc: "Win a run with Treecko.", metric: :treecko_wins, target: 1, xp: 430 },
      { id: :tome2_runs_45, name: "Second Tome Regular", desc: "Complete 45 runs.", metric: :runs, target: 45, xp: 520 },
      { id: :tome2_wins_25, name: "Second Tome Victor", desc: "Win 25 runs.", metric: :wins, target: 25, xp: 680 },
      { id: :tome2_score_35m, name: "Burning Score", desc: "Earn 35000000 total score.", metric: :score, target: 35_000_000, xp: 720 },
      { id: :tome2_endless_45, name: "Long Flame", desc: "Survive 45 minutes in Endless total.", metric: :endless_seconds, target: 2700, xp: 540 },
      { id: :tome2_treecko_kills, name: "Forest Sweep", desc: "Defeat 5000 enemies with Treecko.", metric: :treecko_kills, target: 5000, xp: 500 },
      { id: :tome2_treecko_mastery, name: "Forest Mastery", desc: "Reach level 150 with Treecko.", metric: :treecko_highest_level, target: 150, xp: 500 }
    ]
  end

  def self.register_tome2_battle_pass
    return if !const_defined?(:BATTLE_PASS_DATA)
    passes = BATTLE_PASS_DATA.dup.reject { |pass| pass[:id] == :battle_pass_2 }
    passes << { id: :battle_pass_2, name: "Tome 2: Draconic Ascent", cost: 2500, quests: tome2_quests, rewards: tome2_rewards }
    redefine_const(:BATTLE_PASS_DATA, passes.freeze)
    if const_defined?(:BATTLE_PASS_TEXT_FOR_EXTRACTION)
      texts = BATTLE_PASS_TEXT_FOR_EXTRACTION.dup
      ["Tome 2: Draconic Ascent", "Charmander", "Charmeleon", "Charizard", "Treecko", "Charizardite",
       "Unlock Charmander.", "Unlock Treecko.", "Unlock Charizardite equipment.", "Fire Tornado",
       "Summons a fire tornado on enemies. It can burn everything it touches.", "Wildfire Spiral",
       "Creates eight fire tornadoes on random enemies.", "Flame Spiral", "Fire Tornado lasts longer and burns enemies more reliably.",
       "Flame Debut", "Complete 3 runs with Charmander.", "Rising Ember", "Reach level 60 with Charmander.",
       "Burning Victory", "Win a run with Charmander.", "Wildfire Sweep", "Defeat 4000 enemies with Charmander.",
       "Charizard Flight", "Reach level 150 with Charmander.", "Forest Debut", "Complete 3 runs with Treecko.",
       "Branch Climber", "Reach level 80 with Treecko.", "Leaf Victory", "Win a run with Treecko.",
       "Second Tome Regular", "Complete 45 runs.", "Second Tome Victor", "Win 25 runs.",
       "Burning Score", "Earn 35000000 total score.", "Long Flame", "Survive 45 minutes in Endless total."].each { |text| texts << _INTL(text) }
      redefine_const(:BATTLE_PASS_TEXT_FOR_EXTRACTION, texts.freeze)
    end
  rescue
  end
end

PokemonSurvivor.register_tome1_battle_pass
PokemonSurvivor.register_charmander_tome2_data

module PokemonSurvivor
  class << self
    alias battle_pass_stats_without_charmander_tome2 battle_pass_stats unless method_defined?(:battle_pass_stats_without_charmander_tome2)
    def battle_pass_stats
      stats = battle_pass_stats_without_charmander_tome2
      [:charmander_runs, :charmander_wins, :charmander_kills, :charmander_highest_level,
       :treecko_runs, :treecko_wins, :treecko_kills, :treecko_highest_level].each { |k| stats[k] = stats[k].to_i }
      stats
    rescue
      {}
    end

    alias battle_pass_record_run_without_charmander_tome2 battle_pass_record_run unless method_defined?(:battle_pass_record_run_without_charmander_tome2)
    def battle_pass_record_run(scene)
      battle_pass_record_run_without_charmander_tome2(scene)
      return if !scene || (scene.instance_variable_get(:@run_abandoned) rescue false)
      stats = battle_pass_stats
      base = species_key(scene.instance_variable_get(:@hero_base_name) || scene.instance_variable_get(:@hero_name) || scene.instance_variable_get(:@selected_hero))
      family = case base
               when :CHARMANDER, :CHARMELEON, :CHARIZARD then :charmander
               when :TREECKO, :GROVYLE, :SCEPTILE then :treecko
               else nil
               end
      return if !family
      level = scene.instance_variable_get(:@level).to_i rescue 1
      won = scene.respond_to?(:leaderboard_run_won?) && scene.leaderboard_run_won?
      kills = scene.instance_variable_get(:@kills).to_i rescue 0
      stats[:"#{family}_runs"] = stats[:"#{family}_runs"].to_i + 1
      stats[:"#{family}_wins"] = stats[:"#{family}_wins"].to_i + 1 if won
      stats[:"#{family}_kills"] = stats[:"#{family}_kills"].to_i + kills
      stats[:"#{family}_highest_level"] = [stats[:"#{family}_highest_level"].to_i, level].max
    rescue
    end

    alias equip_pokemon_item_without_charizardite_gate equip_pokemon_item unless method_defined?(:equip_pokemon_item_without_charizardite_gate)
    def equip_pokemon_item(pokemon, item_id)
      key = item_id.to_sym rescue nil
      return false if key == CHARIZARDITE_ITEM_ID && !charizardite_compatible?(pokemon)
      equip_pokemon_item_without_charizardite_gate(pokemon, item_id)
    rescue
      false
    end
  end
end

class Scene_PokemonSurvivor
  alias start_game_without_charmander_tome2 start_game unless method_defined?(:start_game_without_charmander_tome2)
  def start_game(*args)
    reset_charmander_tome2_state
    start_game_without_charmander_tome2(*args)
    reset_charmander_tome2_state_after_build
  end

  def reset_charmander_tome2_state
    @charizardite_equipped = false
    @charizard_mega_charge = 0.0
    @charizard_mega_active = false
    @charizard_mega_timer = 0.0
    @charizard_mega_damage_mult = 1.0
    @charizard_mega_cooldown_mult = 1.0
    @charizard_mega_count_bonus = 0
    @charizard_mega_action_buffer = false
    @charizard_mega_action_buffer_timer = 0.0
    @charmander_twister_duration_bonus = 0.0
    @charmander_burn_chance_bonus = 0.0
  rescue
  end

  def reset_charmander_tome2_state_after_build
    @charizard_mega_charge = 0.0
    @charizard_mega_active = false
    @charizard_mega_timer = 0.0
    @charizard_mega_action_buffer = false
    @charizard_mega_action_buffer_timer = 0.0
  rescue
  end

  alias setup_hero_sprite_set_without_charmander_tome2 setup_hero_sprite_set unless method_defined?(:setup_hero_sprite_set_without_charmander_tome2)
  def setup_hero_sprite_set(name)
    setup_hero_sprite_set_without_charmander_tome2(name)
    @hero_name = name if @hero && PokemonSurvivor::CHARMANDER_LINE.include?(PokemonSurvivor.species_key(@hero_base_name || @passive_key))
  rescue
    setup_hero_sprite_set_without_charmander_tome2(name) rescue nil
  end
  alias apply_hero_passive_without_charmander_tome2 apply_hero_passive unless method_defined?(:apply_hero_passive_without_charmander_tome2)
  def apply_hero_passive
    apply_hero_passive_without_charmander_tome2
    if PokemonSurvivor.species_key(@passive_key || @hero_base_name) == :CHARMANDER
      @skill_power_mult[:fire_twister] *= 1.08 if @skill_power_mult
      @skill_cooldown_mult[:fire_twister] *= 0.94 if @skill_cooldown_mult
      @skill_dot_damage_bonus[:fire_twister] += 1 if @skill_dot_damage_bonus
      @charmander_burn_chance_bonus = 0.10
    end
  rescue
  end

  alias apply_pokemon_equipment_effects_without_charmander_tome2 apply_pokemon_equipment_effects unless method_defined?(:apply_pokemon_equipment_effects_without_charmander_tome2)
  def apply_pokemon_equipment_effects(base)
    apply_pokemon_equipment_effects_without_charmander_tome2(base)
    @charizardite_equipped = !!(@equipped_item && @equipped_item[:id] == PokemonSurvivor::CHARIZARDITE_ITEM_ID && PokemonSurvivor.charizardite_compatible?(base))
  rescue
  end

  alias open_pokemon_equipment_menu_without_charmander_tome2 open_pokemon_equipment_menu unless method_defined?(:open_pokemon_equipment_menu_without_charmander_tome2)
  def open_pokemon_equipment_menu(pokemon = nil)
    open_pokemon_equipment_menu_without_charmander_tome2(pokemon)
    filter_charizardite_equipment_items
    draw_pokemon_equipment_menu if @state == :equipment_menu
  rescue
    @state = :select
  end

  def filter_charizardite_equipment_items
    return if !@equipment_items
    compatible = PokemonSurvivor.charizardite_compatible?(@equipment_pokemon)
    @equipment_items = @equipment_items.select { |item| item[:id] != PokemonSurvivor::CHARIZARDITE_ITEM_ID || compatible }
    equipped = PokemonSurvivor.equipped_pokemon_item(@equipment_pokemon)
    @equipment_index = @equipment_items.index { |item| item[:id] == equipped } || 0
  rescue
  end

  alias add_new_survivor_skill_upgrades_without_charmander_tome2 add_new_survivor_skill_upgrades unless method_defined?(:add_new_survivor_skill_upgrades_without_charmander_tome2)
  def add_new_survivor_skill_upgrades(ret, skill_id, skill, skill_name)
    add_new_survivor_skill_upgrades_without_charmander_tome2(ret, skill_id, skill, skill_name)
    if skill_id == :leaf_blade_sweep
      ret << { id: :leaf_blade_sweep_edge, name: _INTL("Leaf Blade Edge"), desc: _INTL("Leaf Blade Sweep damage +10%."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :leaf_blade_sweep_reach, name: _INTL("Leaf Blade Reach"), desc: _INTL("Leaf Blade Sweep reaches farther."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_radius }
      ret << { id: :leaf_blade_sweep_spread, name: _INTL("Leaf Blade Spread"), desc: _INTL("Leaf Blade Sweep adds another blade."), max: 5, rarity: :epic, target_skill: skill_id, effect: :skill_count }
      ret << { id: :leaf_blade_sweep_tempo, name: _INTL("Leaf Blade Tempo"), desc: _INTL("Leaf Blade Sweep recharge time -6%."), max: 3, rarity: :super_rare, target_skill: skill_id, effect: :skill_cooldown_light }

    elsif skill_id == :normal_sweep
      ret << { id: :normal_sweep_edge, name: _INTL("Rival Edge"), desc: _INTL("Rival Sweep damage +10%."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :normal_sweep_reach, name: _INTL("Rival Reach"), desc: _INTL("Rival Sweep reaches farther."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_radius }
      ret << { id: :normal_sweep_tempo, name: _INTL("Rival Tempo"), desc: _INTL("Rival Sweep recharge time -6%."), max: 4, rarity: :super_rare, target_skill: skill_id, effect: :skill_cooldown_light }
      ret << { id: :normal_sweep_spin, name: _INTL("Rival Spin"), desc: _INTL("Rival Sweep spins faster."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_orbit_speed }
    end
  rescue
  end

end

#===============================================================================
# Tomes 3 and 4
#===============================================================================

module PokemonSurvivor
  module_function

  def redefine_const(name, value)
    remove_const(name) if const_defined?(name)
    const_set(name, value)
  rescue
  end unless respond_to?(:redefine_const)

  def battle_pass_reward_equipment(tier, equipment_id, rarity = nil)
    display = const_defined?(:BATTLE_PASS_EQUIPMENT_DISPLAY) ? BATTLE_PASS_EQUIPMENT_DISPLAY[equipment_id.to_sym] : nil
    item = equipment_data(equipment_id) if respond_to?(:equipment_data)
    name = display ? display[0].to_s : (item ? item[:name].to_s : equipment_id.to_s)
    icon = display ? display[1].to_s : (item && item[:icon] ? item[:icon].to_s : name)
    item_rarity = display ? display[2] : (item && item[:rarity])
    {
      tier: tier, kind: :equipment, equipment: equipment_id, amount: 1,
      icon: icon, name: name, rarity: rarity || item_rarity || :rare,
      text: "Unlock #{name} equipment."
    }
  rescue
    { tier: tier, kind: :equipment, equipment: equipment_id, amount: 1, icon: equipment_id.to_s, name: equipment_id.to_s, rarity: rarity || :rare, text: "Unlock #{equipment_id} equipment." }
  end

  def battle_pass_currency_reward(tier, kind, amount, rarity = nil)
    if kind == :candy
      { tier: tier, kind: :candy, amount: amount, icon: "ICON_CANDY", name: "Candy Cache", rarity: rarity || :rare, text: "Gain #{amount} Candies." }
    else
      { tier: tier, kind: :fragment, amount: amount, icon: "ICON_FRAGMENT", name: "Fragment Cache", rarity: rarity || :rare, text: "Gain #{amount} Fragments." }
    end
  rescue
    {}
  end

  def tome3_rewards
    fixed = {
      1 => battle_pass_reward_equipment(1, :excadrite, :legendary),
      6 => battle_pass_reward_equipment(6, :soft_sand, :uncommon),
      12 => battle_pass_reward_equipment(12, :lucarionite, :legendary),
      18 => battle_pass_reward_equipment(18, :silver_powder, :uncommon),
      24 => battle_pass_reward_equipment(24, :hawluchanite, :legendary),
      32 => battle_pass_reward_equipment(32, :magnet_item, :uncommon),
      42 => battle_pass_reward_equipment(42, :tyranitarite, :legendary),
      50 => battle_pass_reward_equipment(50, :heavy_boots, :uncommon)
    }
    build_tome_reward_track(fixed, 42, 180)
  rescue
    []
  end

  def tome4_rewards
    fixed = {
      1 => battle_pass_reward_equipment(1, :gengarite, :legendary),
      8 => battle_pass_reward_equipment(8, :twisted_spoon, :uncommon),
      15 => battle_pass_reward_equipment(15, :sablenite, :legendary),
      24 => battle_pass_reward_equipment(24, :galladite, :legendary),
      36 => battle_pass_reward_equipment(36, :mystic_thread, :rare),
      48 => battle_pass_reward_equipment(48, :gardevoirite, :legendary)
    }
    build_tome_reward_track(fixed, 50, 220)
  rescue
    []
  end

  def build_tome_reward_track(fixed, candy_start, fragment_start)
    rewards = []
    (1..60).each do |tier|
      if fixed[tier]
        rewards << fixed[tier]
      elsif tier.even?
        amount = candy_start + (tier * 9)
        rewards << battle_pass_currency_reward(tier, :candy, amount, tier >= 50 ? :legendary : (tier >= 30 ? :epic : :rare))
      else
        amount = fragment_start + (tier * 42)
        rewards << battle_pass_currency_reward(tier, :fragment, amount, tier >= 50 ? :legendary : (tier >= 30 ? :epic : :rare))
      end
    end
    rewards
  rescue
    []
  end

  def tome3_quests
    [
      { id: :tome3_drilbur_runs, name: "Drill Training", desc: "Complete 3 runs with Drilbur.", metric: :drilbur_runs, target: 3, xp: 210 },
      { id: :tome3_drilbur_level, name: "Deep Drill", desc: "Reach level 100 with Drilbur.", metric: :drilbur_highest_level, target: 100, xp: 320 },
      { id: :tome3_riolu_win, name: "Aura Victory", desc: "Win a run with Riolu.", metric: :riolu_wins, target: 1, xp: 360 },
      { id: :tome3_riolu_kills, name: "Aura Combo", desc: "Defeat 5000 enemies with Riolu.", metric: :riolu_kills, target: 5000, xp: 430 },
      { id: :tome3_hawlucha_runs, name: "Ring Entrance", desc: "Complete 3 runs with Hawlucha.", metric: :hawlucha_runs, target: 3, xp: 260 },
      { id: :tome3_hawlucha_level, name: "High Flight", desc: "Reach level 120 with Hawlucha.", metric: :hawlucha_highest_level, target: 120, xp: 420 },
      { id: :tome3_larvitar_win, name: "Stone Tyrant", desc: "Win a run with Larvitar.", metric: :larvitar_wins, target: 1, xp: 420 },
      { id: :tome3_larvitar_kills, name: "Mountain Sweep", desc: "Defeat 7000 enemies with Larvitar.", metric: :larvitar_kills, target: 7000, xp: 520 },
      { id: :tome3_tower_runs, name: "Natural Trial", desc: "Complete 3 Tower runs.", metric: :tower_runs, target: 3, xp: 520 },
      { id: :tome3_score, name: "Natural Force", desc: "Earn 45000000 total score.", metric: :score, target: 45_000_000, xp: 720 },
      { id: :tome3_drilbur_win, name: "Drill Victory", desc: "Win a run with Drilbur.", metric: :drilbur_wins, target: 1, xp: 600 },
      { id: :tome3_hawlucha_win, name: "Ring Champion", desc: "Win a run with Hawlucha.", metric: :hawlucha_wins, target: 1, xp: 600 },
      { id: :tome3_larvitar_level, name: "Mountain Mastery", desc: "Reach level 150 with Larvitar.", metric: :larvitar_highest_level, target: 150, xp: 600 }
    ]
  end

  def tome4_quests
    [
      { id: :tome4_gastly_runs, name: "Shadow Practice", desc: "Complete 3 runs with Gastly.", metric: :gastly_runs, target: 3, xp: 230 },
      { id: :tome4_gastly_level, name: "Deep Haunt", desc: "Reach level 130 with Gastly.", metric: :gastly_highest_level, target: 130, xp: 440 },
      { id: :tome4_sableye_win, name: "Gem Victory", desc: "Win a run with Sableye.", metric: :sableye_wins, target: 1, xp: 430 },
      { id: :tome4_sableye_kills, name: "Gem Sweep", desc: "Defeat 6000 enemies with Sableye.", metric: :sableye_kills, target: 6000, xp: 520 },
      { id: :tome4_gallade_runs, name: "Blade Focus", desc: "Complete 2 runs ending as Gallade.", metric: :gallade_runs, target: 2, xp: 420 },
      { id: :tome4_gallade_win, name: "Blade Victory", desc: "Win a run ending as Gallade.", metric: :gallade_wins, target: 1, xp: 520 },
      { id: :tome4_gardevoir_runs, name: "Grace Focus", desc: "Complete 2 runs ending as Gardevoir.", metric: :gardevoir_runs, target: 2, xp: 420 },
      { id: :tome4_gardevoir_win, name: "Grace Victory", desc: "Win a run ending as Gardevoir.", metric: :gardevoir_wins, target: 1, xp: 520 },
      { id: :tome4_endless, name: "Limit Break", desc: "Survive 60 minutes in Endless total.", metric: :endless_seconds, target: 3600, xp: 680 },
      { id: :tome4_score, name: "Unlimited Score", desc: "Earn 60000000 total score.", metric: :score, target: 60_000_000, xp: 780 },
      { id: :tome4_gastly_win, name: "Shadow Victory", desc: "Win a run with Gastly.", metric: :gastly_wins, target: 1, xp: 500 },
      { id: :tome4_sableye_level, name: "Gem Mastery", desc: "Reach level 150 with Sableye.", metric: :sableye_highest_level, target: 150, xp: 500 }
    ]
  end

  def tome5_rewards
    fixed = {
      1 => { tier: 1, kind: :hero, hero: :CARVANHA, amount: 1, icon: "CARVANHA", name: "Carvanha", rarity: :legendary, text: "Unlock Carvanha." },
      8 => battle_pass_reward_equipment(8, :wide_lens),
      12 => battle_pass_reward_equipment(12, :silk_scarf),
      24 => battle_pass_reward_equipment(24, :adrenaline_orb),
      30 => { tier: 30, kind: :equipment, equipment: :sharpedonite, amount: 1, icon: "SHARPEDONITE", name: "Sharpedonite", rarity: :legendary, text: "Unlock Sharpedonite equipment." },
      31 => { tier: 31, kind: :hero, hero: :SKARMORY, amount: 1, icon: "SKARMORY", name: "Skarmory", rarity: :legendary, text: "Unlock Skarmory." },
      38 => battle_pass_reward_equipment(38, :protective_pads),
      45 => battle_pass_reward_equipment(45, :burst_battery),
      54 => battle_pass_reward_equipment(54, :assault_vest),
      60 => { tier: 60, kind: :equipment, equipment: :skarmorite, amount: 1, icon: "SKARMORITE", name: "Skarmorite", rarity: :legendary, text: "Unlock Skarmorite equipment." }
    }
    build_tome_reward_track(fixed, 55, 240)
  end

  def tome5_quests
    [
      { id: :tome5_runs, name: "Sea Trials", desc: "Complete 3 runs during Tome 5.", metric: :tome5_runs, target: 3, xp: 400 },
      { id: :tome5_kills, name: "Hunting Grounds", desc: "Defeat 8000 enemies during Tome 5.", metric: :tome5_kills, target: 8000, xp: 500 },
      { id: :tome5_wins, name: "Apex Victories", desc: "Win 3 runs during Tome 5.", metric: :tome5_wins, target: 3, xp: 600 },
      { id: :tome5_carvanha_runs, name: "First Bite", desc: "Complete 3 runs with Carvanha during Tome 5.", metric: :tome5_carvanha_runs, target: 3, xp: 400 },
      { id: :tome5_carvanha_kills, name: "Feeding Time", desc: "Defeat 5000 enemies with Carvanha during Tome 5.", metric: :tome5_carvanha_kills, target: 5000, xp: 600 },
      { id: :tome5_carvanha_level, name: "Deep Water", desc: "Reach level 100 with Carvanha during Tome 5.", metric: :tome5_carvanha_highest_level, target: 100, xp: 500 },
      { id: :tome5_carvanha_win, name: "Ocean Predator", desc: "Win a run with Carvanha during Tome 5.", metric: :tome5_carvanha_wins, target: 1, xp: 600 },
      { id: :tome5_skarmory_runs, name: "Steel Wings", desc: "Complete 3 runs with Skarmory during Tome 5.", metric: :tome5_skarmory_runs, target: 3, xp: 400 },
      { id: :tome5_skarmory_kills, name: "Storm Hunter", desc: "Defeat 5000 enemies with Skarmory during Tome 5.", metric: :tome5_skarmory_kills, target: 5000, xp: 600 },
      { id: :tome5_skarmory_level, name: "Above the Clouds", desc: "Reach level 100 with Skarmory during Tome 5.", metric: :tome5_skarmory_highest_level, target: 100, xp: 500 },
      { id: :tome5_skarmory_win, name: "Sky Predator", desc: "Win a run with Skarmory during Tome 5.", metric: :tome5_skarmory_wins, target: 1, xp: 600 },
      { id: :tome5_runs_final, name: "Sky and Sea Mastery", desc: "Complete 8 runs during Tome 5.", metric: :tome5_runs, target: 8, xp: 800 }
    ]
  end

  def tome6_rewards
    fixed = {
      1 => { tier: 1, kind: :hero, hero: :EEVEE, amount: 1, icon: "EEVEE", name: "Eevee", rarity: :legendary, text: "Unlock Eevee." },
      5 => battle_pass_reward_equipment(5, :water_stone),
      10 => battle_pass_reward_equipment(10, :fire_stone),
      15 => battle_pass_reward_equipment(15, :thunder_stone),
      20 => battle_pass_reward_equipment(20, :sun_stone),
      24 => battle_pass_reward_equipment(24, :eject_button),
      25 => battle_pass_reward_equipment(25, :moon_stone),
      35 => battle_pass_reward_equipment(35, :leaf_stone),
      40 => battle_pass_reward_equipment(40, :ice_stone),
      45 => battle_pass_reward_equipment(45, :shiny_stone),
      50 => battle_pass_reward_equipment(50, :light_clay),
      55 => battle_pass_reward_equipment(55, :eeviumz),
      60 => battle_pass_reward_equipment(60, :metronome)
    }
    build_tome_reward_track(fixed, 60, 260)
  end

  def tome6_quests
    quests = [
      { id: :tome6_runs, name: "First Paths", desc: "Complete 3 runs during Tome 6.", metric: :tome6_runs, target: 3, xp: 500 },
      { id: :tome6_runs_8, name: "Many Possibilities", desc: "Complete 8 runs during Tome 6.", metric: :tome6_runs, target: 8, xp: 600 },
      { id: :tome6_kills, name: "Prism Power", desc: "Defeat 10000 enemies during Tome 6.", metric: :tome6_kills, target: 10000, xp: 600 },
      { id: :tome6_wins, name: "Brilliant Victories", desc: "Win 3 runs during Tome 6.", metric: :tome6_wins, target: 3, xp: 600 },
      { id: :tome6_eevee_runs, name: "Eevee Explorer", desc: "Complete 3 runs starting with Eevee during Tome 6.", metric: :tome6_eevee_runs, target: 3, xp: 500 },
      { id: :tome6_eevee_level, name: "Adaptive Growth", desc: "Reach level 100 starting with Eevee during Tome 6.", metric: :tome6_eevee_highest_level, target: 100, xp: 600 },
      { id: :tome6_eevee_kills, name: "Prismatic Force", desc: "Defeat 8000 enemies starting with Eevee during Tome 6.", metric: :tome6_eevee_kills, target: 8000, xp: 600 },
      { id: :tome6_eevee_win, name: "Eevee Champion", desc: "Win a run starting with Eevee during Tome 6.", metric: :tome6_eevee_wins, target: 1, xp: 600 }
    ]
    [:VAPOREON, :FLAREON, :JOLTEON, :ESPEON, :UMBREON, :LEAFEON, :GLACEON, :SYLVEON].each do |form|
      key = :"tome6_#{form.to_s.downcase}"
      name = form.to_s.capitalize
      quests << { id: key, name: name, desc: _INTL("Complete a run ending as {1} during Tome 6.", species_name(form)), metric: key, target: 1, xp: 300 }
    end
    quests
  end

  def tome7_rewards
    fixed = {
      1 => { tier: 1, kind: :hero, hero: :ABRA, amount: 1, icon: "ABRA", name: "Abra", rarity: :legendary, text: "Unlock Abra." },
      12 => battle_pass_reward_equipment(12, :cleanse_tag),
      30 => { tier: 30, kind: :equipment, equipment: :alakazite, amount: 1, icon: "ALAKAZITE", name: "Alakazite", rarity: :legendary, text: "Unlock Alakazite equipment." },
      40 => battle_pass_reward_equipment(40, :amulet_coin),
      60 => battle_pass_reward_equipment(60, :life_orb)
    }
    build_tome_reward_track(fixed, 65, 280)
  end

  def tome7_quests
    [
      { id: :tome7_runs, name: "Mind Opening", desc: "Complete 3 runs during Tome 7.", metric: :tome7_runs, target: 3, xp: 500 },
      { id: :tome7_runs_10, name: "Beyond the Mind", desc: "Complete 10 runs during Tome 7.", metric: :tome7_runs, target: 10, xp: 700 },
      { id: :tome7_kills, name: "Psychic Trials", desc: "Defeat 10000 enemies during Tome 7.", metric: :tome7_kills, target: 10000, xp: 600 },
      { id: :tome7_wins, name: "Clear Thoughts", desc: "Win 3 runs during Tome 7.", metric: :tome7_wins, target: 3, xp: 600 },
      { id: :tome7_abra_runs, name: "First Teleport", desc: "Complete 3 runs starting with Abra during Tome 7.", metric: :tome7_abra_runs, target: 3, xp: 500 },
      { id: :tome7_abra_level, name: "Growing Mind", desc: "Reach level 100 starting with Abra during Tome 7.", metric: :tome7_abra_highest_level, target: 100, xp: 500 },
      { id: :tome7_abra_level_150, name: "Mind Unbound", desc: "Reach level 150 starting with Abra during Tome 7.", metric: :tome7_abra_highest_level, target: 150, xp: 600 },
      { id: :tome7_abra_kills, name: "Mental Impact", desc: "Defeat 8000 enemies starting with Abra during Tome 7.", metric: :tome7_abra_kills, target: 8000, xp: 700 },
      { id: :tome7_abra_win, name: "Psychic Victory", desc: "Win a run starting with Abra during Tome 7.", metric: :tome7_abra_wins, target: 1, xp: 600 },
      { id: :tome7_alakazam, name: "Master of Spoons", desc: "Complete 2 runs ending as Alakazam or Mega Alakazam during Tome 7.", metric: :tome7_alakazam_runs, target: 2, xp: 600 },
      { id: :tome7_dash_30, name: "Blink Training", desc: "Use Dash 30 times starting with Abra during Tome 7.", metric: :tome7_abra_dashes, target: 30, xp: 500 },
      { id: :tome7_dash_100, name: "Psychic Footwork", desc: "Use Dash 100 times starting with Abra during Tome 7.", metric: :tome7_abra_dashes, target: 100, xp: 700 }
    ]
  end

  def tome8_rewards
    fixed = {
      1 => battle_pass_reward_equipment(1, :normaliumz),
      4 => battle_pass_reward_equipment(4, :firiumz),
      7 => battle_pass_reward_equipment(7, :wateriumz),
      10 => battle_pass_reward_equipment(10, :grassiumz),
      13 => battle_pass_reward_equipment(13, :electriumz),
      16 => battle_pass_reward_equipment(16, :iciumz),
      19 => battle_pass_reward_equipment(19, :fightiniumz),
      22 => battle_pass_reward_equipment(22, :poisoniumz),
      25 => battle_pass_reward_equipment(25, :groundiumz),
      28 => battle_pass_reward_equipment(28, :flyiniumz),
      31 => battle_pass_reward_equipment(31, :psychiumz),
      35 => battle_pass_reward_equipment(35, :buginiumz),
      39 => battle_pass_reward_equipment(39, :rockiumz),
      43 => battle_pass_reward_equipment(43, :ghostiumz),
      47 => battle_pass_reward_equipment(47, :dragoniumz),
      51 => battle_pass_reward_equipment(51, :darkiniumz),
      55 => battle_pass_reward_equipment(55, :steeliumz),
      60 => battle_pass_reward_equipment(60, :fairiumz)
    }
    build_tome_reward_track(fixed, 70, 300)
  end

  def tome8_quests
    [
      { id: :tome8_first_run, name: "First Resonance", desc: "Complete 1 run during Tome 8.", metric: :tome8_runs, target: 1, xp: 300 },
      { id: :tome8_runs_3, name: "Crystal Practice", desc: "Complete 3 runs during Tome 8.", metric: :tome8_runs, target: 3, xp: 400 },
      { id: :tome8_runs_6, name: "Growing Resonance", desc: "Complete 6 runs during Tome 8.", metric: :tome8_runs, target: 6, xp: 500 },
      { id: :tome8_runs_10, name: "Elemental Journey", desc: "Complete 10 runs during Tome 8.", metric: :tome8_runs, target: 10, xp: 600 },
      { id: :tome8_runs_15, name: "Crystal Mastery", desc: "Complete 15 runs during Tome 8.", metric: :tome8_runs, target: 15, xp: 700 },
      { id: :tome8_kills_2000, name: "First Sparks", desc: "Defeat 2000 enemies during Tome 8.", metric: :tome8_kills, target: 2000, xp: 300 },
      { id: :tome8_kills_8000, name: "Gathering Power", desc: "Defeat 8000 enemies during Tome 8.", metric: :tome8_kills, target: 8000, xp: 400 },
      { id: :tome8_kills_20000, name: "Elemental Surge", desc: "Defeat 20000 enemies during Tome 8.", metric: :tome8_kills, target: 20000, xp: 500 },
      { id: :tome8_kills_40000, name: "Resonant Force", desc: "Defeat 40000 enemies during Tome 8.", metric: :tome8_kills, target: 40000, xp: 600 },
      { id: :tome8_level_50, name: "Awakening Power", desc: "Reach level 50 during Tome 8.", metric: :tome8_highest_level, target: 50, xp: 300 },
      { id: :tome8_level_100, name: "Radiant Growth", desc: "Reach level 100 during Tome 8.", metric: :tome8_highest_level, target: 100, xp: 400 },
      { id: :tome8_level_200, name: "Power Unbound", desc: "Reach level 200 during Tome 8.", metric: :tome8_highest_level, target: 200, xp: 600 },
      { id: :tome8_win_1, name: "Crystal Victory", desc: "Win 1 run during Tome 8.", metric: :tome8_wins, target: 1, xp: 400 },
      { id: :tome8_wins_3, name: "Elemental Champion", desc: "Win 3 runs during Tome 8.", metric: :tome8_wins, target: 3, xp: 500 },
      { id: :tome8_wins_6, name: "Resonant Triumph", desc: "Win 6 runs during Tome 8.", metric: :tome8_wins, target: 6, xp: 600 },
      { id: :tome8_score_5m, name: "Bright Beginning", desc: "Earn 5000000 total score during Tome 8.", metric: :tome8_score, target: 5000000, xp: 300 },
      { id: :tome8_score_20m, name: "Brilliant Path", desc: "Earn 20000000 total score during Tome 8.", metric: :tome8_score, target: 20000000, xp: 400 },
      { id: :tome8_score_60m, name: "Spectrum of Power", desc: "Earn 60000000 total score during Tome 8.", metric: :tome8_score, target: 60000000, xp: 600 },
      { id: :tome8_z_first, name: "Z Awakening", desc: "Activate a Z-Move during Tome 8.", metric: :tome8_z_activations, target: 1, xp: 200 },
      { id: :tome8_z_10, name: "Z Practice", desc: "Activate Z-Moves 10 times during Tome 8.", metric: :tome8_z_activations, target: 10, xp: 350 },
      { id: :tome8_z_30, name: "Z Mastery", desc: "Activate Z-Moves 30 times during Tome 8.", metric: :tome8_z_activations, target: 30, xp: 500 },
      { id: :tome8_z_fire, name: "Blazing Crystal", desc: "Activate Firium Z 3 times during Tome 8.", metric: :tome8_z_firiumz, target: 3, xp: 300 },
      { id: :tome8_z_water, name: "Surging Crystal", desc: "Activate Waterium Z 3 times during Tome 8.", metric: :tome8_z_wateriumz, target: 3, xp: 300 },
      { id: :tome8_z_grass, name: "Blooming Crystal", desc: "Activate Grassium Z 3 times during Tome 8.", metric: :tome8_z_grassiumz, target: 3, xp: 300 },
      { id: :tome8_z_six, name: "Elemental Explorer", desc: "Activate 6 different elemental Z-Crystals during Tome 8.", metric: :tome8_z_distinct, target: 6, xp: 500 }
    ]
  end

  # Literal markers keep these data-driven labels visible to translation extraction.
  def tome8_translation_texts
    [
      _INTL("Tome 8: Elemental Resonance"),
      _INTL("Z Awakening"),
      _INTL("Activate a Z-Move during Tome 8."),
      _INTL("Z Practice"),
      _INTL("Activate Z-Moves 10 times during Tome 8."),
      _INTL("Z Mastery"),
      _INTL("Activate Z-Moves 30 times during Tome 8."),
      _INTL("Blazing Crystal"),
      _INTL("Activate Firium Z 3 times during Tome 8."),
      _INTL("Surging Crystal"),
      _INTL("Activate Waterium Z 3 times during Tome 8."),
      _INTL("Blooming Crystal"),
      _INTL("Activate Grassium Z 3 times during Tome 8."),
      _INTL("Elemental Explorer"),
      _INTL("Activate 6 different elemental Z-Crystals during Tome 8."),
      _INTL("First Resonance"),
      _INTL("Complete 1 run during Tome 8."),
      _INTL("Crystal Practice"),
      _INTL("Complete 3 runs during Tome 8."),
      _INTL("Growing Resonance"),
      _INTL("Complete 6 runs during Tome 8."),
      _INTL("Elemental Journey"),
      _INTL("Complete 10 runs during Tome 8."),
      _INTL("Crystal Mastery"),
      _INTL("Complete 15 runs during Tome 8."),
      _INTL("First Sparks"),
      _INTL("Defeat 2000 enemies during Tome 8."),
      _INTL("Gathering Power"),
      _INTL("Defeat 8000 enemies during Tome 8."),
      _INTL("Elemental Surge"),
      _INTL("Defeat 20000 enemies during Tome 8."),
      _INTL("Resonant Force"),
      _INTL("Defeat 40000 enemies during Tome 8."),
      _INTL("Awakening Power"),
      _INTL("Reach level 50 during Tome 8."),
      _INTL("Radiant Growth"),
      _INTL("Reach level 100 during Tome 8."),
      _INTL("Power Unbound"),
      _INTL("Reach level 200 during Tome 8."),
      _INTL("Crystal Victory"),
      _INTL("Win 1 run during Tome 8."),
      _INTL("Elemental Champion"),
      _INTL("Win 3 runs during Tome 8."),
      _INTL("Resonant Triumph"),
      _INTL("Win 6 runs during Tome 8."),
      _INTL("Bright Beginning"),
      _INTL("Earn 5000000 total score during Tome 8."),
      _INTL("Brilliant Path"),
      _INTL("Earn 20000000 total score during Tome 8."),
      _INTL("Spectrum of Power"),
      _INTL("Earn 60000000 total score during Tome 8.")
    ]
  end

  def tome9_rewards
    fixed = {
      1 => { tier: 1, kind: :hero, hero: :SQUIRTLE, amount: 1, icon: "SQUIRTLE", name: "Squirtle", rarity: :legendary, text: "Unlock Squirtle." },
      31 => { tier: 31, kind: :hero, hero: :CUBONE, amount: 1, icon: "CUBONE", name: "Cubone", rarity: :legendary, text: "Unlock Cubone." },
      60 => battle_pass_reward_equipment(60, :binding_band)
    }
    build_tome_reward_track(fixed, 75, 320)
  end

  def tome10_rewards
    fixed = {
      1 => { tier: 1, kind: :hero, hero: :MAWILE, amount: 1, icon: "MAWILE", name: "Mawile", rarity: :legendary, text: "Unlock Mawile." },
      20 => battle_pass_reward_equipment(20, :mawilite),
      21 => { tier: 21, kind: :hero, hero: :TYNAMO, amount: 1, icon: "TYNAMO", name: "Tynamo", rarity: :legendary, text: "Unlock Tynamo." },
      40 => battle_pass_reward_equipment(40, :eelektrossite),
      41 => { tier: 41, kind: :hero, hero: :SKRELP, amount: 1, icon: "SKRELP", name: "Skrelp", rarity: :legendary, text: "Unlock Skrelp." },
      60 => battle_pass_reward_equipment(60, :dragalgite)
    }
    build_tome_reward_track(fixed, 80, 340)
  end

  def new_survivor_tome_quests(number, heroes)
    prefix = "tome#{number}"
    quests = []
    [[1, 300], [3, 400], [6, 500], [10, 600], [15, 700]].each do |target, xp|
      quests << { id: :"#{prefix}_runs_#{target}", name: _INTL("Field Journey {1}", target),
        desc: _INTL("Complete {1} runs during Tome {2}.", target, number), metric: :"#{prefix}_runs", target: target, xp: xp }
    end
    [[2000, 300], [8000, 400], [20000, 500], [40000, 600]].each do |target, xp|
      quests << { id: :"#{prefix}_kills_#{target}", name: _INTL("Hunting Trail {1}", target),
        desc: _INTL("Defeat {1} enemies during Tome {2}.", target, number), metric: :"#{prefix}_kills", target: target, xp: xp }
    end
    [[50, 300], [100, 400], [200, 600]].each do |target, xp|
      quests << { id: :"#{prefix}_level_#{target}", name: _INTL("Growing Resolve {1}", target),
        desc: _INTL("Reach level {1} during Tome {2}.", target, number), metric: :"#{prefix}_highest_level", target: target, xp: xp }
    end
    [[1, 400], [3, 500], [6, 600]].each do |target, xp|
      quests << { id: :"#{prefix}_wins_#{target}", name: _INTL("Proven Courage {1}", target),
        desc: _INTL("Win {1} runs during Tome {2}.", target, number), metric: :"#{prefix}_wins", target: target, xp: xp }
    end
    heroes.each do |hero|
      key = "#{prefix}_#{hero.to_s.downcase}"
      name = species_name(hero)
      quests << { id: :"#{key}_runs", name: _INTL("{1}'s Journey", name),
        desc: _INTL("Complete 3 runs starting with {1} during Tome {2}.", name, number), metric: :"#{key}_runs", target: 3, xp: 400 }
      quests << { id: :"#{key}_kills", name: _INTL("{1}'s Strength", name),
        desc: _INTL("Defeat 5000 enemies starting with {1} during Tome {2}.", name, number), metric: :"#{key}_kills", target: 5000, xp: 500 }
      quests << { id: :"#{key}_level", name: _INTL("{1}'s Potential", name),
        desc: _INTL("Reach level 100 starting with {1} during Tome {2}.", name, number), metric: :"#{key}_highest_level", target: 100, xp: 500 }
      quests << { id: :"#{key}_win", name: _INTL("{1}'s Triumph", name),
        desc: _INTL("Win a run starting with {1} during Tome {2}.", name, number), metric: :"#{key}_wins", target: 1, xp: 600 }
    end
    quests
  end

  def tome9_quests
    new_survivor_tome_quests(9, [:SQUIRTLE, :CUBONE])
  end

  def tome10_quests
    new_survivor_tome_quests(10, [:MAWILE, :TYNAMO, :SKRELP])
  end

  def register_tome3_and_tome4_battle_passes
    return if !const_defined?(:BATTLE_PASS_DATA)
    passes = BATTLE_PASS_DATA.dup.reject { |pass| [:battle_pass_3, :battle_pass_4, :battle_pass_5, :battle_pass_6, :battle_pass_7, :battle_pass_8, :battle_pass_9, :battle_pass_10].include?(pass[:id]) }
    passes << { id: :battle_pass_3, name: "Tome 3: Natural Power", cost: 5000, quests: tome3_quests, rewards: tome3_rewards }
    passes << { id: :battle_pass_4, name: "Tome 4: Boundless Power", cost: 7500, quests: tome4_quests, rewards: tome4_rewards }
    passes << { id: :battle_pass_5, name: "Tome 5: Predators of Sky and Sea", cost: 10000, quests: tome5_quests, rewards: tome5_rewards }
    passes << { id: :battle_pass_6, name: "Tome 6: Paths of the Prism", cost: 12500, quests: tome6_quests, rewards: tome6_rewards }
    passes << { id: :battle_pass_7, name: "Tome 7: Beyond the Mind", cost: 15000, quests: tome7_quests, rewards: tome7_rewards }
    passes << { id: :battle_pass_8, name: "Tome 8: Elemental Resonance", cost: 17500, quests: tome8_quests, rewards: tome8_rewards }
    passes << { id: :battle_pass_9, name: "Tome 9: Tides of the Bonekeeper", cost: 20000, quests: tome9_quests, rewards: tome9_rewards }
    passes << { id: :battle_pass_10, name: "Tome 10: Fangs of the Abyss", cost: 22500, quests: tome10_quests, rewards: tome10_rewards }
    redefine_const(:BATTLE_PASS_DATA, passes.freeze)
    register_tome3_4_translation_texts
  rescue
  end

  def register_tome3_4_translation_texts
    return if !const_defined?(:BATTLE_PASS_TEXT_FOR_EXTRACTION)
    texts = BATTLE_PASS_TEXT_FOR_EXTRACTION.dup
    texts.concat(tome8_translation_texts)
    texts.concat([_INTL("Tome 9: Tides of the Bonekeeper"), _INTL("Tome 10: Fangs of the Abyss"),
      _INTL("Mawilite"), _INTL("Eelektrossite"), _INTL("Dragalgite"),
      _INTL("Mawile can Mega Evolve after Burst is fully charged."),
      _INTL("Eelektross can Mega Evolve after Burst is fully charged."),
      _INTL("Dragalge can Mega Evolve after Burst is fully charged.")])
    [9, 10].each do |number|
      send("tome#{number}_quests").each { |q| texts.concat([q[:name], q[:desc]]) }
      send("tome#{number}_rewards").each { |r| texts.concat([r[:name], r[:text]].compact) }
    end
    additions = [
      "Tome 3: Natural Power", "Tome 4: Boundless Power", "Excadrite", "Lucarionite", "Hawluchanite", "Tyranitarite",
      "Gengarite", "Sablenite", "Galladite", "Gardevoirite", "Soft Sand", "Silver Powder", "Magnet", "Heavy Boots", "Twisted Spoon", "Mystic Thread",
      "Drill Training", "Complete 3 runs with Drilbur.", "Deep Drill", "Reach level 100 with Drilbur.",
      "Aura Victory", "Win a run with Riolu.", "Aura Combo", "Defeat 5000 enemies with Riolu.",
      "Ring Entrance", "Complete 3 runs with Hawlucha.", "High Flight", "Reach level 120 with Hawlucha.",
      "Stone Tyrant", "Win a run with Larvitar.", "Mountain Sweep", "Defeat 7000 enemies with Larvitar.",
      "Natural Trial", "Complete 3 Tower runs.", "Natural Force", "Earn 45000000 total score.",
      "Shadow Practice", "Complete 3 runs with Gastly.", "Deep Haunt", "Reach level 130 with Gastly.",
      "Gem Victory", "Win a run with Sableye.", "Gem Sweep", "Defeat 6000 enemies with Sableye.",
      "Blade Focus", "Complete 2 runs ending as Gallade.", "Blade Victory", "Win a run ending as Gallade.",
      "Grace Focus", "Complete 2 runs ending as Gardevoir.", "Grace Victory", "Win a run ending as Gardevoir.",
      "Limit Break", "Survive 60 minutes in Endless total.", "Unlimited Score", "Earn 60000000 total score."
    ]
    additions.each { |text| texts << _INTL(text) }
    redefine_const(:BATTLE_PASS_TEXT_FOR_EXTRACTION, texts.freeze)
  rescue
  end
end

PokemonSurvivor.register_tome3_and_tome4_battle_passes

module PokemonSurvivor
  class << self
    alias battle_pass_stats_without_tome3_4 battle_pass_stats unless method_defined?(:battle_pass_stats_without_tome3_4)
    def battle_pass_stats
      stats = battle_pass_stats_without_tome3_4
      [:drilbur_runs, :drilbur_wins, :drilbur_kills, :drilbur_highest_level,
       :riolu_runs, :riolu_wins, :riolu_kills, :riolu_highest_level,
       :hawlucha_runs, :hawlucha_wins, :hawlucha_kills, :hawlucha_highest_level,
       :larvitar_runs, :larvitar_wins, :larvitar_kills, :larvitar_highest_level,
       :gastly_runs, :gastly_wins, :gastly_kills, :gastly_highest_level,
       :sableye_runs, :sableye_wins, :sableye_kills, :sableye_highest_level,
       :gallade_runs, :gallade_wins, :gallade_kills, :gallade_highest_level,
       :gardevoir_runs, :gardevoir_wins, :gardevoir_kills, :gardevoir_highest_level].each { |k| stats[k] = stats[k].to_i }
      stats
    rescue
      {}
    end

    alias battle_pass_record_run_without_tome3_4 battle_pass_record_run unless method_defined?(:battle_pass_record_run_without_tome3_4)
    def battle_pass_record_run(scene)
      battle_pass_record_run_without_tome3_4(scene)
      return if !scene || (scene.instance_variable_get(:@run_abandoned) rescue false)
      battle_pass_record_tome5_run(scene)
      battle_pass_record_tome6_run(scene)
      battle_pass_record_tome7_run(scene)
      battle_pass_record_tome8_run(scene)
      battle_pass_record_new_survivor_tomes(scene)
      stats = battle_pass_stats
      base = species_key(scene.instance_variable_get(:@hero_base_name) || scene.instance_variable_get(:@selected_hero) || scene.instance_variable_get(:@hero_name))
      current = species_key(scene.instance_variable_get(:@hero).name) rescue base
      family = battle_pass_family_for_mega_quest(base, current)
      return if !family
      level = scene.instance_variable_get(:@level).to_i rescue 1
      won = scene.respond_to?(:leaderboard_run_won?) ? scene.leaderboard_run_won? : (scene.instance_variable_get(:@run_won) rescue false)
      kills = scene.instance_variable_get(:@kills).to_i rescue 0
      stats[:"#{family}_runs"] = stats[:"#{family}_runs"].to_i + 1
      stats[:"#{family}_wins"] = stats[:"#{family}_wins"].to_i + 1 if won
      stats[:"#{family}_kills"] = stats[:"#{family}_kills"].to_i + kills
      stats[:"#{family}_highest_level"] = [stats[:"#{family}_highest_level"].to_i, level].max
    rescue
    end

    def battle_pass_family_for_mega_quest(base, current)
      return :drilbur if [:DRILBUR, :EXCADRILL, :EXCADRILL_1].include?(base) || [:DRILBUR, :EXCADRILL, :EXCADRILL_1].include?(current)
      return :riolu if [:RIOLU, :LUCARIO, :LUCARIO_1].include?(base) || [:RIOLU, :LUCARIO, :LUCARIO_1].include?(current)
      return :hawlucha if [:HAWLUCHA, :HAWLUCHA_1].include?(base) || [:HAWLUCHA, :HAWLUCHA_1].include?(current)
      return :larvitar if [:LARVITAR, :PUPITAR, :TYRANITAR, :TYRANITAR_1].include?(base) || [:LARVITAR, :PUPITAR, :TYRANITAR, :TYRANITAR_1].include?(current)
      return :gastly if [:GASTLY, :HAUNTER, :GENGAR, :GENGAR_1].include?(base) || [:GASTLY, :HAUNTER, :GENGAR, :GENGAR_1].include?(current)
      return :sableye if [:SABLEYE, :SABLEYE_1].include?(base) || [:SABLEYE, :SABLEYE_1].include?(current)
      return :gallade if [:GALLADE, :GALLADE_1].include?(current)
      return :gardevoir if [:GARDEVOIR, :GARDEVOIR_1].include?(current)
      nil
    rescue
      nil
    end

    def battle_pass_record_tome5_run(scene)
      return if !battle_pass_unlocked?(:battle_pass_5)
      stats = battle_pass_stats
      base = species_key(scene.instance_variable_get(:@hero_base_name) || scene.instance_variable_get(:@hero_name))
      family = case base
               when :CARVANHA, :SHARPEDO, :SHARPEDO_1 then :carvanha
               when :SKARMORY, :SKARMORY_1 then :skarmory
               end
      kills = scene.instance_variable_get(:@kills).to_i
      level = scene.instance_variable_get(:@level).to_i
      won = scene.respond_to?(:leaderboard_run_won?) && scene.leaderboard_run_won?
      prefixes = [:tome5]
      prefixes << :"tome5_#{family}" if family
      prefixes.each do |prefix|
        stats[:"#{prefix}_runs"] = stats[:"#{prefix}_runs"].to_i + 1
        stats[:"#{prefix}_wins"] = stats[:"#{prefix}_wins"].to_i + 1 if won
        stats[:"#{prefix}_kills"] = stats[:"#{prefix}_kills"].to_i + kills
        stats[:"#{prefix}_highest_level"] = [stats[:"#{prefix}_highest_level"].to_i, level].max
      end
    end

    def battle_pass_record_tome8_z_move(crystal_id)
      return false unless battle_pass_unlocked?(:battle_pass_8)
      return false unless crystal_id && const_defined?(:Z_MOVE_DATA) && Z_MOVE_DATA[crystal_id]
      stats = battle_pass_stats
      stats[:tome8_z_activations] = stats[:tome8_z_activations].to_i + 1
      key = :"tome8_z_#{crystal_id}"
      stats[key] = stats[key].to_i + 1
      # Eevee's exclusive crystal counts as an activation, not an elemental crystal.
      if crystal_id != :eeviumz
        entry = battle_pass_entry(:battle_pass_8)
        entry[:z_crystals_used] = {} unless entry[:z_crystals_used].is_a?(Hash)
        entry[:z_crystals_used][crystal_id.to_s] = true
        stats[:tome8_z_distinct] = entry[:z_crystals_used].length
      end
      true
    end

    def battle_pass_record_new_survivor_tomes(scene)
      return if !scene || scene.instance_variable_get(:@run_abandoned)
      base = species_key(scene.instance_variable_get(:@hero_base_name))
      won = scene.respond_to?(:leaderboard_run_won?) && scene.leaderboard_run_won?
      stats = battle_pass_stats
      { 9 => [:SQUIRTLE, :CUBONE], 10 => [:MAWILE, :TYNAMO, :SKRELP] }.each do |number, heroes|
        next unless battle_pass_unlocked?(:"battle_pass_#{number}")
        prefixes = ["tome#{number}"]
        prefixes << "tome#{number}_#{base.to_s.downcase}" if heroes.include?(base)
        prefixes.each do |prefix|
          stats[:"#{prefix}_runs"] = stats[:"#{prefix}_runs"].to_i + 1
          stats[:"#{prefix}_wins"] = stats[:"#{prefix}_wins"].to_i + 1 if won
          stats[:"#{prefix}_kills"] = stats[:"#{prefix}_kills"].to_i + scene.instance_variable_get(:@kills).to_i
          stats[:"#{prefix}_highest_level"] = [stats[:"#{prefix}_highest_level"].to_i, scene.instance_variable_get(:@level).to_i].max
        end
      end
    end

    def battle_pass_record_tome8_run(scene)
      return if !scene || scene.instance_variable_get(:@run_abandoned)
      return if !battle_pass_unlocked?(:battle_pass_8)
      stats = battle_pass_stats
      stats[:tome8_runs] = stats[:tome8_runs].to_i + 1
      stats[:tome8_kills] = stats[:tome8_kills].to_i + scene.instance_variable_get(:@kills).to_i
      stats[:tome8_score] = stats[:tome8_score].to_i + scene.instance_variable_get(:@score).to_i
      stats[:tome8_highest_level] = [stats[:tome8_highest_level].to_i, scene.instance_variable_get(:@level).to_i].max
      if scene.respond_to?(:leaderboard_run_won?) && scene.leaderboard_run_won?
        stats[:tome8_wins] = stats[:tome8_wins].to_i + 1
      end
    end

    def battle_pass_record_tome7_run(scene)
      return if !battle_pass_unlocked?(:battle_pass_7)
      stats = battle_pass_stats
      base = species_key(scene.instance_variable_get(:@hero_base_name))
      current = species_key(scene.instance_variable_get(:@hero).name) rescue base
      prefixes = [:tome7]
      prefixes << :tome7_abra if base == :ABRA
      won = scene.respond_to?(:leaderboard_run_won?) && scene.leaderboard_run_won?
      prefixes.each do |prefix|
        stats[:"#{prefix}_runs"] = stats[:"#{prefix}_runs"].to_i + 1
        stats[:"#{prefix}_wins"] = stats[:"#{prefix}_wins"].to_i + 1 if won
        stats[:"#{prefix}_kills"] = stats[:"#{prefix}_kills"].to_i + scene.instance_variable_get(:@kills).to_i
        stats[:"#{prefix}_highest_level"] = [stats[:"#{prefix}_highest_level"].to_i, scene.instance_variable_get(:@level).to_i].max
      end
      if base == :ABRA
        stats[:tome7_abra_dashes] = stats[:tome7_abra_dashes].to_i + scene.instance_variable_get(:@abra_dash_count).to_i
        stats[:tome7_alakazam_runs] = stats[:tome7_alakazam_runs].to_i + 1 if [:ALAKAZAM, :ALAKAZAM_1].include?(current)
      end
    end

    def battle_pass_record_tome6_run(scene)
      return if !battle_pass_unlocked?(:battle_pass_6)
      stats = battle_pass_stats
      base = species_key(scene.instance_variable_get(:@hero_base_name))
      current = species_key(scene.instance_variable_get(:@hero).name) rescue base
      prefixes = [:tome6]
      prefixes << :tome6_eevee if base == :EEVEE
      won = scene.respond_to?(:leaderboard_run_won?) && scene.leaderboard_run_won?
      prefixes.each do |prefix|
        stats[:"#{prefix}_runs"] = stats[:"#{prefix}_runs"].to_i + 1
        stats[:"#{prefix}_wins"] = stats[:"#{prefix}_wins"].to_i + 1 if won
        stats[:"#{prefix}_kills"] = stats[:"#{prefix}_kills"].to_i + scene.instance_variable_get(:@kills).to_i
        stats[:"#{prefix}_highest_level"] = [stats[:"#{prefix}_highest_level"].to_i, scene.instance_variable_get(:@level).to_i].max
      end
      if base == :EEVEE && EEVEE_STONE_FORMS.value?(current)
        key = :"tome6_#{current.to_s.downcase}"
        stats[key] = stats[key].to_i + 1
      end
    end
  end
end






























