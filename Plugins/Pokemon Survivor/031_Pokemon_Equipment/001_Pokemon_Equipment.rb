#===============================================================================
# Pokemon Survivor - Pokemon Equipment
#===============================================================================

module PokemonSurvivor
  EQUIPMENT_ELEMENT_ITEMS = [
    [:silk_scarf, "Silk Scarf", "Normal-type attacks deal 10% more damage.", :NORMAL, "Silk Scarf"],
    [:charcoal, "Charcoal", "Fire-type attacks deal 10% more damage.", :FIRE, "Charcoal"],
    [:mystic_water, "Mystic Water", "Water-type attacks deal 10% more damage.", :WATER, "Mystic Water"],
    [:miracle_seed, "Miracle Seed", "Grass-type attacks deal 10% more damage.", :GRASS, "Miracle Seed"],
    [:magnet_item, "Magnet", "Electric-type attacks deal 10% more damage.", :ELECTRIC, "Magnet"],
    [:never_melt_ice, "Never-Melt Ice", "Ice-type attacks deal 10% more damage.", :ICE, "Never-Melt Ice"],
    [:sharp_beak, "Sharp Beak", "Flying-type attacks deal 10% more damage.", :FLYING, "Sharp Beak"],
    [:silver_powder, "Silver Powder", "Bug-type attacks deal 10% more damage.", :BUG, "Silver Powder"],
    [:black_belt, "Black Belt", "Fighting-type attacks deal 10% more damage.", :FIGHTING, "Black Belt"],
    [:poison_barb, "Poison Barb", "Poison-type attacks deal 10% more damage.", :POISON, "Poison Barb"],
    [:soft_sand, "Soft Sand", "Ground-type attacks deal 10% more damage.", :GROUND, "Soft Sand"],
    [:twisted_spoon, "Twisted Spoon", "Psychic-type attacks deal 10% more damage.", :PSYCHIC, "Twisted Spoon"],
    [:hard_stone, "Hard Stone", "Rock-type attacks deal 10% more damage.", :ROCK, "Hard Stone"],
    [:spell_tag, "Spell Tag", "Ghost-type attacks deal 10% more damage.", :GHOST, "Spell Tag"],
    [:dragon_fang, "Dragon Fang", "Dragon-type attacks deal 10% more damage.", :DRAGON, "Dragon Fang"],
    [:black_glasses, "Black Glasses", "Dark-type attacks deal 10% more damage.", :DARK, "Black Glasses"],
    [:metal_coat, "Metal Coat", "Steel-type attacks deal 10% more damage.", :STEEL, "Metal Coat"],
    [:fairy_feather, "Fairy Feather", "Fairy-type attacks deal 10% more damage.", :FAIRY, "Fairy Feather"]
  ] unless const_defined?(:EQUIPMENT_ELEMENT_ITEMS)

  EQUIPMENT_ITEMS = ([
    { id: :mawilite, name: "Mawilite", desc: "Mawile can Mega Evolve after Burst is fully charged.", effect: :mega_stone, species: [:MAWILE, :MAWILE_1], mega_species: :MAWILE_1, rarity: :legendary, icon: "MAWILITE" },
    { id: :eelektrossite, name: "Eelektrossite", desc: "Eelektross can Mega Evolve after Burst is fully charged.", effect: :mega_stone, species: [:TYNAMO, :EELEKTRIK, :EELEKTROSS, :EELEKTROSS_1], mega_species: :EELEKTROSS_1, rarity: :legendary, icon: "EELEKTROSSITE" },
    { id: :dragalgite, name: "Dragalgite", desc: "Dragalge can Mega Evolve after Burst is fully charged.", effect: :mega_stone, species: [:SKRELP, :DRAGALGE, :DRAGALGE_1], mega_species: :DRAGALGE_1, rarity: :legendary, icon: "DRAGALGITE" },
    # Unlock sources are assigned separately; elemental crystals work with every Pokemon.
    { id: :normaliumz, name: "Normalium Z", desc: "For 15 seconds, rotating volleys strike in four directions.", effect: :z_crystal, type: :NORMAL, rarity: :legendary, icon: "NORMALIUMZ" },
    { id: :firiumz, name: "Firium Z", desc: "For 15 seconds, eight fire orbs circle you in pairs on four rings, alternating directions.", effect: :z_crystal, type: :FIRE, rarity: :legendary, icon: "FIRIUMZ" },
    { id: :wateriumz, name: "Waterium Z", desc: "For 15 seconds, water bursts erupt on enemies and scatter damaging fragments.", effect: :z_crystal, type: :WATER, rarity: :legendary, icon: "WATERIUMZ" },
    { id: :grassiumz, name: "Grassium Z", desc: "For 15 seconds, grass shots explode on impact and damage nearby enemies.", effect: :z_crystal, type: :GRASS, rarity: :legendary, icon: "GRASSIUMZ" },
    { id: :electriumz, name: "Electrium Z", desc: "For 15 seconds, electric shots scatter in all directions and erupt into paralyzing blasts.", effect: :z_crystal, type: :ELECTRIC, rarity: :legendary, icon: "ELECTRIUMZ" },
    { id: :iciumz, name: "Icium Z", desc: "For 15 seconds, ice shots paralyze enemies, then leave them slowed.", effect: :z_crystal, type: :ICE, rarity: :legendary, icon: "ICIUMZ" },
    { id: :fightiniumz, name: "Fightinium Z", desc: "For 15 seconds, six flurries pull enemies in, strike repeatedly, then push them away.", effect: :z_crystal, type: :FIGHTING, rarity: :legendary, icon: "FIGHTINIUMZ" },
    { id: :poisoniumz, name: "Poisonium Z", desc: "For 15 seconds, six toxic flurries strike repeatedly and poison enemies.", effect: :z_crystal, type: :POISON, rarity: :legendary, icon: "POISONIUMZ" },
    { id: :groundiumz, name: "Groundium Z", desc: "For 15 seconds, expanding ground shockwaves erupt around you.", effect: :z_crystal, type: :GROUND, rarity: :legendary, icon: "GROUNDIUMZ" },
    { id: :flyiniumz, name: "Flyinium Z", desc: "A giant tornado pulls enemies in, then splits into eight homing tornadoes before the 15 seconds end.", effect: :z_crystal, type: :FLYING, rarity: :legendary, icon: "FLYINIUMZ" },
    { id: :psychiumz, name: "Psychium Z", desc: "For 15 seconds, eight psychic spheres circle a fixed area, trapping and damaging enemies.", effect: :z_crystal, type: :PSYCHIC, rarity: :legendary, icon: "PSYCHIUMZ" },
    { id: :buginiumz, name: "Buginium Z", desc: "For 15 seconds, insect spikes rise beneath enemies and strike as they grow.", effect: :z_crystal, type: :BUG, rarity: :legendary, icon: "BUGINIUMZ" },
    { id: :rockiumz, name: "Rockium Z", desc: "For 15 seconds, rocks rain onto nearby enemies and paralyze them.", effect: :z_crystal, type: :ROCK, rarity: :legendary, icon: "ROCKIUMZ" },
    { id: :ghostiumz, name: "Ghostium Z", desc: "For 15 seconds, ghost shots cling to enemies for 3 seconds, pulling in and damaging nearby foes.", effect: :z_crystal, type: :GHOST, rarity: :legendary, icon: "GHOSTIUMZ" },
    { id: :dragoniumz, name: "Dragonium Z", desc: "For 15 seconds, violent dragon geysers erupt beneath nearby enemies and slow them.", effect: :z_crystal, type: :DRAGON, rarity: :legendary, icon: "DRAGONIUMZ" },
    { id: :darkiniumz, name: "Darkinium Z", desc: "For 15 seconds, rotating dark volleys strike in four directions.", effect: :z_crystal, type: :DARK, rarity: :legendary, icon: "DARKINIUMZ" },
    { id: :steeliumz, name: "Steelium Z", desc: "For 15 seconds, twelve steel orbs rapidly circle you, damaging and pushing enemies away.", effect: :z_crystal, type: :STEEL, rarity: :legendary, icon: "STEELIUMZ" },
    { id: :fairiumz, name: "Fairium Z", desc: "For 15 seconds, eight fairy orbs repeatedly circle you, launch at enemies and burst on impact.", effect: :z_crystal, type: :FAIRY, rarity: :legendary, icon: "FAIRIUMZ" },
    { id: :eeviumz, name: "Eevium Z", desc: "Eevee only. Charge beyond Burst to unleash a 15-second Normal rain, double attack speed and 50% more damage.", effect: :z_crystal, species: [:EEVEE], rarity: :legendary, icon: "EEVIUMZ" },
    { id: :fire_stone, name: "Fire Stone", desc: "Eevee evolves into Flareon at its next evolution. Eevee only.", effect: :eevee_stone, rarity: :super_rare, icon: "Fire Stone" },
    { id: :thunder_stone, name: "Thunder Stone", desc: "Eevee evolves into Jolteon at its next evolution. Eevee only.", effect: :eevee_stone, rarity: :super_rare, icon: "Thunder Stone" },
    { id: :water_stone, name: "Water Stone", desc: "Eevee evolves into Vaporeon at its next evolution. Eevee only.", effect: :eevee_stone, rarity: :super_rare, icon: "Water Stone" },
    { id: :sun_stone, name: "Dawn Stone", desc: "Eevee evolves into Espeon at its next evolution. Eevee only.", effect: :eevee_stone, rarity: :super_rare, icon: "Dawn Stone" },
    { id: :moon_stone, name: "Dusk Stone", desc: "Eevee evolves into Umbreon at its next evolution. Eevee only.", effect: :eevee_stone, rarity: :super_rare, icon: "Dusk Stone" },
    { id: :leaf_stone, name: "Leaf Stone", desc: "Eevee evolves into Leafeon at its next evolution. Eevee only.", effect: :eevee_stone, rarity: :super_rare, icon: "Leaf Stone" },
    { id: :ice_stone, name: "Ice Stone", desc: "Eevee evolves into Glaceon at its next evolution. Eevee only.", effect: :eevee_stone, rarity: :super_rare, icon: "Ice Stone" },
    { id: :shiny_stone, name: "Shiny Stone", desc: "Eevee evolves into Sylveon at its next evolution. Eevee only.", effect: :eevee_stone, rarity: :super_rare, icon: "Shiny Stone" },
    { id: :protective_pads, name: "Protective Pads", desc: "Take 15% less contact damage.", effect: :contact_defense, value: 15, rarity: :rare, icon: "Protective Pads" },
    { id: :wide_lens, name: "Wide Lens", desc: "Compatible skills gain 12% of their base attack radius.", effect: :skill_radius_percent, value: 12, rarity: :rare, icon: "Wide Lens" },
    { id: :life_orb, name: "Life Orb", desc: "Deal 20% more damage, but lose 15% max HP.", effect: :damage_hp_trade, damage: 20, hp: -15, rarity: :epic, icon: "Life Orb" },
    { id: :assault_vest, name: "Assault Vest", desc: "Take 20% less projectile damage, but Burst charges 15% slower.", effect: :projectile_burst_trade, defense: 20, charge: -15, rarity: :super_rare, icon: "Assault Vest" },
    { id: :eject_button, name: "Eject Button", desc: "Dash cooldown is 15% shorter. Cannot go below 3 seconds.", effect: :dash_cooldown_percent, value: 15, rarity: :super_rare, icon: "Eject Button" },
    { id: :metronome, name: "Metronome", desc: "Each second without taking a hit grants 1% damage, up to 15%. Resets when hit.", effect: :nohit_damage, value: 15, rarity: :super_rare, icon: "Metronome" },
    { id: :binding_band, name: "Binding Band", desc: "Burn and poison damage increases by 20%. Initial hits are unchanged.", effect: :dot_damage_percent, value: 20, rarity: :rare, icon: "Binding Band" },
    { id: :light_clay, name: "Light Clay", desc: "Slows and paralysis you inflict last 15% longer.", effect: :control_duration_percent, value: 15, rarity: :rare, icon: "Light Clay" },
    { id: :cleanse_tag, name: "Cleanse Tag", desc: "Slows affecting you wear off 30% sooner.", effect: :slow_recovery_percent, value: 30, rarity: :uncommon, icon: "Cleanse Tag" },
    { id: :adrenaline_orb, name: "Adrenaline Orb", desc: "Below 30% HP, gain 12% movement speed and 15% skill attack rate.", effect: :low_hp_haste, rarity: :epic, icon: "Adrenaline Orb" },
    { id: :amulet_coin, name: "Amulet Coin", desc: "Gain 20% more Candies and Fragments from Delibird and Gimmighoul events only.", effect: :hunt_reward_percent, value: 20, rarity: :rare, icon: "Amulet Coin" },
    { id: :quick_claw, name: "Quick Claw", desc: "Main skill recovers 8% faster.", effect: :main_skill_cooldown_percent, value: 8, rarity: :rare, icon: "Quick Claw" },
    { id: :training_band, name: "Training Band", desc: "Gain 8% damage, but lose 5% movement speed.", effect: :damage_speed_trade, damage: 8, speed: -5, rarity: :rare, icon: "Training Band" },
    { id: :shell_bell, name: "Shell Bell", desc: "Every 120 defeated enemies, restore 0.35% of max HP.", effect: :shell_bell, kills: 120, heal_percent: 0.35, rarity: :super_rare, icon: "Shell Bell" },
    { id: :focus_lens, name: "Focus Lens", desc: "Deal 12% more damage to Bosses and Mini Bosses.", effect: :boss_damage_percent, value: 12, rarity: :rare, icon: "Focus Lens" },
    { id: :magnet_pin, name: "Magnet Pin", desc: "Increase pickup range by 20%.", effect: :pickup_percent, value: 20, rarity: :common, icon: "Magnet Pin" },
    { id: :burst_battery, name: "Burst Battery", desc: "Start with 15% Burst charge, but charge Burst 5% slower after that.", effect: :starting_burst_trade, start: 15, charge: -5, rarity: :rare, icon: "Burst Battery" },
    { id: :heavy_boots, name: "Heavy Boots", desc: "Resist slow and knockback effects better, but lose 4% movement speed.", effect: :control_resist_speed_trade, resist: 20, speed: -4, rarity: :uncommon, icon: "Heavy Boots" },
    { id: :lucky_egg, name: "Lucky Egg", desc: "Baby companions gain 20% max HP and 15% damage.", effect: :baby_companion_percent, hp: 20, damage: 15, rarity: :rare, icon: "Lucky Egg" },
    { id: :old_coin, name: "Old Coin", desc: "Gain 8% more Fragments at the end of a run.", effect: :fragment_gain_percent, value: 8, rarity: :rare, icon: "Old Coin" },
    { id: :guardian_feather, name: "Guardian Feather", desc: "Once per run, a Baby companion survives a lethal hit with 20% HP.", effect: :baby_revive, value: 20, rarity: :super_rare, icon: "Guardian Feather" },
    { id: :scope_charm, name: "Scope Charm", desc: "Status effects from compatible skills trigger 8% more often.", effect: :status_chance_percent, value: 8, rarity: :rare, icon: "Scope Charm" },
    { id: :mystic_thread, name: "Mystic Thread", desc: "Player status effects last 10% longer.", effect: :status_duration_percent, value: 10, rarity: :rare, icon: "Mystic Thread" },
    { id: :boss_bell, name: "Boss Bell", desc: "Each Boss defeated grants +4% damage for this run, up to +20%.", effect: :boss_kill_damage_percent, value: 4, rarity: :super_rare, icon: "Boss Bell" },
    { id: :safety_orb, name: "Safety Orb", desc: "Take 8% less damage, but deal 4% less damage.", effect: :defense_damage_trade, defense: 8, damage: -4, rarity: :rare, icon: "Safety Orb" },
    { id: :shiny_brooch, name: "Shiny Brooch", desc: "When playing Shiny, gain 10% more Candies after a run.", effect: :shiny_candy_percent, value: 10, rarity: :epic, icon: "Shiny Brooch" },
    { id: :berry_pouch, name: "Berry Pouch", desc: "Berries heal 25% more HP.", effect: :berry_heal_percent, value: 25, rarity: :uncommon, icon: "Berry Pouch" },
    { id: :endless_token, name: "Endless Token", desc: "In Endless Mode, score scaling improves every 10 minutes survived.", effect: :endless_score_interval_percent, value: 5, rarity: :epic, icon: "Endless Token" }
  ] + EQUIPMENT_ELEMENT_ITEMS.map do |id, name, desc, type, icon|
    { id: id, name: name, desc: desc, effect: :type_damage_percent, type: type, value: 10, rarity: :uncommon, icon: icon }
  end).freeze unless const_defined?(:EQUIPMENT_ITEMS)

  BATTLE_PASS_LOCKED_EQUIPMENT_IDS = [:mystic_water, :lucky_egg, :guardian_feather, :old_coin, :shiny_brooch, :magnet_pin, :berry_pouch, :focus_lens, :shell_bell, :boss_bell, :quick_claw, :endless_token] unless const_defined?(:BATTLE_PASS_LOCKED_EQUIPMENT_IDS)

  module_function

  def equipment_items
    EQUIPMENT_ITEMS
  rescue
    []
  end

  def equipment_unlock_store
    progress = survivor_progress
    progress[:equipment_unlocked] = {} if !progress[:equipment_unlocked].is_a?(Hash)
    progress[:equipment_unlocked]
  rescue
    {}
  end

  def equipment_unlocked?(id)
    key = id.to_sym rescue nil
    return false if !key
    equipment_unlock_store[key].to_i > 0
  rescue
    false
  end

  def unlock_equipment_item(id)
    key = id.to_sym rescue nil
    return false if !key || !equipment_data(key)
    equipment_unlock_store[key] = 1
    true
  rescue
    false
  end

  def available_equipment_items
    equipment_items.select { |item| equipment_unlocked?(item[:id]) }
  rescue
    []
  end
  def equipment_data(id)
    return nil if id.nil? || id.to_s.empty?
    equipment_items.find { |item| item[:id] == id.to_sym }
  rescue
    nil
  end

  def pokemon_equipment_store
    progress = survivor_progress
    progress[:pokemon_equipment] = {} if !progress[:pokemon_equipment].is_a?(Hash)
    progress[:pokemon_equipment]
  rescue
    {}
  end

  def equipped_pokemon_item(pokemon)
    key = species_key(pokemon)
    value = pokemon_equipment_store[key] || pokemon_equipment_store[key.to_s]
    value && !value.to_s.empty? ? value.to_sym : nil
  rescue
    nil
  end

  def equip_pokemon_item(pokemon, item_id)
    return false if !equipment_data(item_id)
    return false if equipment_data(item_id)[:effect] == :eevee_stone && species_key(pokemon) != :EEVEE
    return false if !equipment_species_compatible?(pokemon, equipment_data(item_id))
    return false if respond_to?(:equipment_unlocked?) && !equipment_unlocked?(item_id)
    pokemon_equipment_store[species_key(pokemon)] = item_id.to_sym
    true
  rescue
    false
  end

  def equipment_species_compatible?(pokemon, item)
    return true if !item || !item[:species]
    item[:species].include?(species_key(pokemon))
  end

  def unequip_pokemon_item(pokemon)
    pokemon_equipment_store.delete(species_key(pokemon))
    pokemon_equipment_store.delete(species_key(pokemon).to_s)
    true
  rescue
    false
  end

  def equipment_translation_strings
    equipment_items.each do |item|
      _INTL(item[:name].to_s)
      _INTL(item[:desc].to_s)
    end
  rescue
    []
  end
end

class Scene_PokemonSurvivor
  def apply_pokemon_equipment_effects(base)
    @equipped_item = nil
    @equipment_last_hit_time = 0.0
    return if PokemonSurvivor.respond_to?(:pokemon_equipment_slot_unlocked?) && !PokemonSurvivor.pokemon_equipment_slot_unlocked?(base)
    equipped_id = PokemonSurvivor.equipped_pokemon_item(base)
    item = PokemonSurvivor.equipment_data(equipped_id)
    item = nil if equipped_id && PokemonSurvivor.respond_to?(:equipment_unlocked?) && !PokemonSurvivor.equipment_unlocked?(equipped_id)
    @equipped_item = item
    return if !item
    @equipment_type_damage_mult ||= Hash.new(1.0)
    case item[:effect]
    when :contact_defense
      @equipment_contact_mult = 1.0 - item[:value] / 100.0
    when :skill_radius_percent
      PokemonSurvivor::SKILLS.each do |id, skill|
        next if skill[:radius].to_f <= 0 || [:fire_twister, :splash].include?(skill[:kind])
        @skill_radius_bonus[id] += (skill[:radius].to_f * item[:value] / 100.0).round
      end
    when :damage_hp_trade
      @damage_mult *= 1.0 + item[:damage] / 100.0
      @hero.max_hp = [(@hero.max_hp * (1.0 + item[:hp] / 100.0)).round, 1].max
      @hero.hp = [@hero.hp, @hero.max_hp].min
    when :projectile_burst_trade
      @enemy_projectile_shield_mult = (@enemy_projectile_shield_mult || 1.0) * (1.0 - item[:defense] / 100.0)
      @burst_charge_mult = (@burst_charge_mult || 1.0) * (1.0 + item[:charge] / 100.0)
    when :dash_cooldown_percent
      @equipment_dash_cooldown_mult = 1.0 - item[:value] / 100.0
    when :dot_damage_percent
      @equipment_dot_mult = 1.0 + item[:value] / 100.0
    when :control_duration_percent
      @equipment_control_duration_mult = 1.0 + item[:value] / 100.0
    when :hunt_reward_percent
      @equipment_hunt_reward_mult = 1.0 + item[:value] / 100.0
    when :main_skill_cooldown_percent
      @skill_cooldown_mult[@hero_skill] *= 1.0 - (item[:value].to_f / 100.0) if @hero_skill && @skill_cooldown_mult
    when :damage_speed_trade
      @damage_mult *= 1.0 + (item[:damage].to_f / 100.0)
      @hero.speed *= 1.0 + (item[:speed].to_f / 100.0) if @hero
    when :shell_bell
      @equipment_shell_bell_kills = item[:kills].to_i
      @equipment_shell_bell_heal_percent = item[:heal_percent].to_f
      @equipment_shell_bell_counter = 0
    when :boss_damage_percent
      @boss_damage_mult = (@boss_damage_mult || 1.0) * (1.0 + (item[:value].to_f / 100.0))
    when :pickup_percent
      @pickup_mult = (@pickup_mult || 1.0) * (1.0 + (item[:value].to_f / 100.0))
    when :starting_burst_trade
      if @ultimate_data
        @ultimate_charge = [@ultimate_data[:cooldown].to_f * (item[:start].to_f / 100.0), @ultimate_data[:cooldown].to_f].min
      end
      @burst_charge_mult = (@burst_charge_mult || 1.0) * (1.0 + (item[:charge].to_f / 100.0))
    when :control_resist_speed_trade
      @equipment_control_resist_percent = item[:resist].to_i
      @hero.speed *= 1.0 + (item[:speed].to_f / 100.0) if @hero
    when :baby_companion_percent
      @equipment_baby_hp_mult = 1.0 + (item[:hp].to_f / 100.0)
      @equipment_baby_damage_mult = 1.0 + (item[:damage].to_f / 100.0)
    when :currency_gain_percent
      @equipment_currency_gain_mult = (@equipment_currency_gain_mult || 1.0) * (1.0 + (item[:value].to_f / 100.0))
    when :fragment_gain_percent
      @equipment_fragment_gain_mult = (@equipment_fragment_gain_mult || 1.0) * (1.0 + (item[:value].to_f / 100.0))
    when :baby_revive
      @equipment_baby_revive_percent = item[:value].to_i
      @equipment_baby_revive_available = true
    when :status_chance_percent
      @equipment_status_chance_mult = (@equipment_status_chance_mult || 1.0) * (1.0 + (item[:value].to_f / 100.0))
    when :status_duration_percent
      @status_duration_mult = (@status_duration_mult || 1.0) * (1.0 + (item[:value].to_f / 100.0))
    when :boss_kill_damage_percent
      @equipment_boss_kill_damage_percent = item[:value].to_f
      @equipment_boss_kill_damage_stacks = 0
    when :defense_damage_trade
      @shield_mult = (@shield_mult || 1.0) * (1.0 - (item[:defense].to_f / 100.0))
      @enemy_projectile_shield_mult = (@enemy_projectile_shield_mult || 1.0) * (1.0 - (item[:defense].to_f / 100.0))
      @damage_mult *= 1.0 + (item[:damage].to_f / 100.0)
    when :shiny_candy_percent
      @equipment_shiny_candy_mult = 1.0 + (item[:value].to_f / 100.0) if PokemonSurvivor.pokemon_shiny_active?(base)
    when :berry_heal_percent
      @berry_heal_mult = (@berry_heal_mult || 1.0) * (1.0 + (item[:value].to_f / 100.0))
    when :endless_score_interval_percent
      @equipment_endless_score_interval_percent = item[:value].to_i
    when :type_damage_percent
      type = item[:type].to_sym rescue nil
      @equipment_type_damage_mult[type] = @equipment_type_damage_mult[type].to_f * (1.0 + (item[:value].to_f / 100.0)) if type
    end
  rescue
  end

  def equipment_type_damage_multiplier(type)
    @equipment_type_damage_mult ||= Hash.new(1.0)
    @equipment_type_damage_mult[type.to_sym].to_f > 0 ? @equipment_type_damage_mult[type.to_sym].to_f : 1.0
  rescue
    1.0
  end

  def trigger_equipment_enemy_defeated(enemy = nil, source = nil)
    if !@breach_run && @equipment_shell_bell_kills.to_i > 0 && @hero && @hero.hp.to_i > 0
      @equipment_shell_bell_counter = @equipment_shell_bell_counter.to_i + 1
      if @equipment_shell_bell_counter >= @equipment_shell_bell_kills.to_i
        @equipment_shell_bell_counter = 0
        heal = [(@hero.max_hp.to_f * (@equipment_shell_bell_heal_percent.to_f / 100.0)).round, 1].max
        @hero.hp = [@hero.hp.to_i + heal, @hero.max_hp.to_i].min
      end
    end
    if @equipment_boss_kill_damage_percent.to_f > 0 && enemy && [:boss, :ultra_boss, :chest, :ultra_chest].include?(enemy.kind)
      previous = [[@equipment_boss_kill_damage_stacks.to_i, 0].max, 5].min
      @equipment_boss_kill_damage_stacks = [previous + 1, 5].min
      old_bonus = [previous * @equipment_boss_kill_damage_percent.to_f, 20.0].min
      new_bonus = [@equipment_boss_kill_damage_stacks * @equipment_boss_kill_damage_percent.to_f, 20.0].min
      # Replace only this item's multiplier; its stacks must not compound.
      @damage_mult *= (100.0 + new_bonus) / (100.0 + old_bonus)
    end
  rescue
  end
end
class Scene_PokemonSurvivor
  EQUIPMENT_MENU_COLUMNS = 7 unless const_defined?(:EQUIPMENT_MENU_COLUMNS)
  EQUIPMENT_MENU_TILE = 48 unless const_defined?(:EQUIPMENT_MENU_TILE)
  EQUIPMENT_MENU_GAP = 8 unless const_defined?(:EQUIPMENT_MENU_GAP)

  def open_pokemon_equipment_menu(pokemon = nil)
    @equipment_pokemon = PokemonSurvivor.species_key(pokemon || selected_hero_name)
    @equipment_items = [{ id: nil, name: "No item", desc: "Remove the equipped item.", rarity: :common, icon: nil }] + PokemonSurvivor.available_equipment_items
    @equipment_items.reject! { |item| item[:effect] == :eevee_stone && @equipment_pokemon != :EEVEE }
    @equipment_items.reject! { |item| !PokemonSurvivor.equipment_species_compatible?(@equipment_pokemon, item) }
    equipped = PokemonSurvivor.equipped_pokemon_item(@equipment_pokemon)
    @equipment_index = @equipment_items.index { |item| item[:id] == equipped } || 0
    @equipment_scroll_row = 0
    @state = :equipment_menu
    pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    draw_pokemon_equipment_menu
    mark_equipment_notifications_seen(@equipment_items)
  rescue
    @state = :select
  end

  def close_pokemon_equipment_menu
    @state = :select
    @confirming_hero = true
    pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
    draw_select
  rescue
  end

  def update_pokemon_equipment_menu
    old = @equipment_index.to_i
    cols = equipment_grid_columns
    max = [@equipment_items.length - 1, 0].max
    if Input.repeat?(Input::LEFT)
      @equipment_index = [@equipment_index.to_i - 1, 0].max
    elsif Input.repeat?(Input::RIGHT)
      @equipment_index = [@equipment_index.to_i + 1, max].min
    elsif Input.repeat?(Input::UP)
      @equipment_index = [@equipment_index.to_i - cols, 0].max
    elsif Input.repeat?(Input::DOWN)
      @equipment_index = [@equipment_index.to_i + cols, max].min
    end
    pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil if old != @equipment_index.to_i
    if survivor_confirm_triggered?
      item = @equipment_items[@equipment_index.to_i]
      if item && item[:id]
        PokemonSurvivor.equip_pokemon_item(@equipment_pokemon, item[:id])
      else
        PokemonSurvivor.unequip_pokemon_item(@equipment_pokemon)
      end
      pbSEPlay("Mart buy item", 80, 100) rescue pbPlayDecisionSE rescue nil
      draw_pokemon_equipment_menu
      return
    elsif survivor_cancel_triggered?
      close_pokemon_equipment_menu
      return
    end
    draw_pokemon_equipment_menu
  rescue
    close_pokemon_equipment_menu
  end

  def draw_pokemon_equipment_menu
    draw_select
    bmp = @sprites["screen"].bitmap
    over = @sprites["overlay"].bitmap
    over.clear
    draw_options_scrolling_background(bmp) if respond_to?(:draw_options_scrolling_background)
    w = [Graphics.width - 56, 584].min
    h = [Graphics.height - 54, 392].min
    x = (Graphics.width - w) / 2
    y = (Graphics.height - h) / 2
    draw_panel(bmp, x, y, w, h, Color.new(245, 198, 92), Color.new(16, 25, 43))
    draw_pixel_round_rect(bmp, x + 14, y + 12, w - 28, 38, Color.new(10, 16, 30, 232))
    title = _INTL("Equipment for {1}", PokemonSurvivor.species_name(@equipment_pokemon))
    draw_text_box(bmp, title, x + 22, y + 21, w - 44, 22, Color.new(255, 238, 176), Color.new(34, 30, 24), 2)

    grid_y = y + 62
    grid_h = h - 164
    cols = equipment_grid_columns
    tile = EQUIPMENT_MENU_TILE
    gap = EQUIPMENT_MENU_GAP
    content_w = (cols * tile) + ((cols - 1) * gap)
    grid_x = x + ((w - content_w) / 2)
    rows = equipment_visible_grid_rows(grid_h)
    ensure_equipment_scroll
    equipped = PokemonSurvivor.equipped_pokemon_item(@equipment_pokemon)
    first = @equipment_scroll_row.to_i * cols
    last = [first + (rows * cols), @equipment_items.length].min
    (first...last).each do |i|
      item = @equipment_items[i]
      local = i - first
      cx = grid_x + ((local % cols) * (tile + gap))
      cy = grid_y + ((local / cols) * (tile + gap))
      selected = i == @equipment_index.to_i
      owned = item[:id] && item[:id] == equipped
      draw_equipment_icon_slot(bmp, item, cx, cy, tile, selected, owned)
    end
    total_rows = ((@equipment_items.length + cols - 1) / cols)
    if total_rows > rows && respond_to?(:draw_leaderboard_scrollbar)
      draw_leaderboard_scrollbar(bmp, grid_x + content_w + 10, grid_y, 7, rows * (tile + gap) - gap, @equipment_scroll_row.to_i, rows, total_rows)
    end

    item = @equipment_items[@equipment_index.to_i] || @equipment_items[0]
    desc_y = y + h - 100
    draw_pixel_round_rect(bmp, x + 18, desc_y, w - 36, 88, Color.new(8, 13, 26, 232))
    name = _INTL(item[:name].to_s)
    rarity = item[:rarity] ? item[:rarity].to_s.gsub("_", " ").capitalize : ""
    name_color = item[:id] && item[:id] == equipped ? Color.new(126, 255, 174) : equipment_rarity_color(item[:rarity])
    draw_text_box(bmp, name, x + 30, desc_y + 8, 230, 22, name_color, Color.new(28, 28, 34), 0)
    draw_text_box(bmp, rarity, x + 268, desc_y + 8, 108, 22, equipment_rarity_color(item[:rarity]), Color.new(28, 28, 34), 0)
    draw_scrolling_wrapped_text(bmp, _INTL(item[:desc].to_s), x + 30, desc_y + 34, w - 60, 42, 20, Color.new(218, 228, 244), Color.new(28, 28, 34))
    draw_help(over, [[:left, ""], [:right, _INTL("Navigate")], [:up, ""], [:down, ""], [:confirm, _INTL("Equip")], [:cancel, _INTL("Back")]])
    draw_tv_filter(over)
  rescue
  end

  def equipment_grid_columns
    7
  rescue
    7
  end

  def equipment_visible_grid_rows(grid_h)
    [[((grid_h.to_i + EQUIPMENT_MENU_GAP) / (EQUIPMENT_MENU_TILE + EQUIPMENT_MENU_GAP)), 2].max, 4].min
  rescue
    3
  end

  def ensure_equipment_scroll
    @equipment_scroll_row ||= 0
    cols = equipment_grid_columns
    rows = equipment_visible_grid_rows(([Graphics.height - 54, 392].min) - 164)
    selected_row = @equipment_index.to_i / cols
    @equipment_scroll_row = selected_row if selected_row < @equipment_scroll_row.to_i
    bottom = @equipment_scroll_row.to_i + rows - 1
    @equipment_scroll_row = selected_row - rows + 1 if selected_row > bottom
    total_rows = ((@equipment_items.length + cols - 1) / cols)
    @equipment_scroll_row = [[@equipment_scroll_row.to_i, 0].max, [total_rows - rows, 0].max].min
  rescue
    @equipment_scroll_row = 0
  end

  def draw_equipment_icon_slot(bitmap, item, x, y, size, selected = false, equipped = false)
    edge = selected ? Color.new(255, 224, 92) : equipment_rarity_color(item[:rarity])
    edge = Color.new(126, 255, 174) if equipped
    fill = selected ? Color.new(42, 46, 58, 248) : Color.new(14, 16, 22, 240)
    fill = Color.new(28, 42, 34, 246) if equipped
    draw_pixel_round_rect(bitmap, x, y, size, size, Color.new(4, 5, 8))
    draw_pixel_round_rect(bitmap, x + 1, y + 1, size - 2, size - 2, edge)
    draw_pixel_round_rect(bitmap, x + 3, y + 3, size - 6, size - 6, fill)
    if equipped
      pulse = 0.5 + (Math.sin((System.uptime rescue 0.0) * 5.5) * 0.5)
      glow = 72 + (pulse * 70).to_i
      bitmap.fill_rect(x + 5, y + 5, size - 10, 2, Color.new(126, 255, 174, glow))
      bitmap.fill_rect(x + 5, y + size - 7, size - 10, 2, Color.new(126, 255, 174, glow))
      bitmap.fill_rect(x + 5, y + 5, 2, size - 10, Color.new(126, 255, 174, glow))
      bitmap.fill_rect(x + size - 7, y + 5, 2, size - 10, Color.new(126, 255, 174, glow))
    end
    if item && item[:icon]
      draw_equipment_item_icon(bitmap, item[:icon], x + (size / 2), y + (size / 2), size - 10)
    else
      cx = x + (size / 2)
      cy = y + (size / 2)
      bitmap.fill_rect(cx - 8, cy - 1, 16, 2, Color.new(198, 214, 236))
      bitmap.fill_rect(cx - 1, cy - 8, 2, 16, Color.new(198, 214, 236))
    end
  rescue
  end

  def draw_equipment_item_icon(bitmap, icon, cx, cy, max_size)
    folder = PokemonSurvivor.const_defined?(:EQUIPMENT_DIR) ? PokemonSurvivor::EQUIPMENT_DIR : PokemonSurvivor::SHOP_DIR
    src = cached_bitmap(folder, icon) rescue nil
    src = cached_bitmap(PokemonSurvivor::SHOP_DIR, icon) rescue nil if !src || src.disposed?
    return if !src || src.disposed?
    scale = [1.0, max_size.to_f / src.width.to_f, max_size.to_f / src.height.to_f].min
    dw = [src.width * scale, 1].max.to_i
    dh = [src.height * scale, 1].max.to_i
    rect = Rect.new(cx - (dw / 2), cy - (dh / 2), dw, dh)
    bitmap.stretch_blt(rect, src, Rect.new(0, 0, src.width, src.height))
  rescue
  end

  def equipment_rarity_color(rarity)
    case rarity
    when :common then Color.new(224, 232, 240)
    when :uncommon then Color.new(126, 232, 150)
    when :rare then Color.new(104, 198, 255)
    when :super_rare then Color.new(190, 132, 255)
    when :epic then Color.new(255, 214, 94)
    when :legendary then Color.new(255, 122, 84)
    else Color.new(224, 232, 240)
    end
  rescue
    Color.white
  end
end




