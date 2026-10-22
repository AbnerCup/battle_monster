#===============================================================================
# Pokemon Survivor - Player setup, passives, Deoxys, ultimates, run result and unlocks
#===============================================================================

class Scene_PokemonSurvivor

  def start_game(hero_name, mode = :classic)
    return if !PokemonSurvivor.hero_unlocked?(hero_name)
    dispose_survivor_bitmap_caches
    @porygon_run_settings = @porygon_pending_settings
    @porygon_pending_settings = nil
    @porygon_run_settings = nil if @breach_run || @titan_run || !PokemonSurvivor::PORYGON_MODES.include?(mode)
    @run_mode = mode == :tower ? :tower : (mode == :rush ? :rush : (mode == :endless ? :endless : :classic))
    # Purchases between runs must be reflected without carrying cached pressure over.
    @dynamic_shop_progress_cache = {}
    @dynamic_training_progress_cache = {}
    @dynamic_level_pressure_rate_cache_key = nil
    @dynamic_level_pressure_rate_cache_value = 0.0
    reset_run_speed_state(hero_name, @run_mode)
    @state = :play
    @timer = 0.0
    @chestboss_currency_popup = nil
    @run_reward_popup_queue = []
    @score = 0
    @classic_competitive_stats = nil
    @level = 1
    @xp = 0
    @xp_next = 12
    @kills = 0
    @tower_final_boss_name = tower_mode? ? PokemonSurvivor.random_tower_final_boss : nil
    @bg_name = tower_mode? ? PokemonSurvivor::TOWER_BACKGROUND : (rush_mode? ? PokemonSurvivor::RUSH_BACKGROUND : PokemonSurvivor.classic_background_names.sample.to_s)
    @rush_bgm_name = arena_mode? ? PokemonSurvivor.classic_background_names.sample.to_s : nil
    play_survivor_bgm
    @world_x = 0.0
    @world_y = 0.0
    @run_view_zoom = 1.0
    @enemies = []
    @projectiles = []
    @charge_shots = []
    @xp_gems = []
    @items = []
    @effects = []
    invalidate_enemy_grid
    clear_tower_objective_state if respond_to?(:clear_tower_objective_state)
    @tower_transition_phase = nil
    @tower_transition_timer = 0.0
    @tower_fade_alpha = 0
    @spawn_queue = []
    @spawn_queue_index = 0
    @bitmap_preload_queue = build_bitmap_preload_queue
    @spawn_timer = 0.0
    @boss_timer = 180.0
    @chest_timer = 45.0
    @item_timer = 16.0
    @ultra_boss_spawned = false
    @ultra_boss_defeated = false
    @ultra_chest_quarter = 1
    @upgrade_options = []
    @upgrade_levels = Hash.new(0)
    @run_bonus_panel_open = false
    @run_bonus_panel_mode = :stats
    @run_bonus_panel_slide = 0.0
    @banned_upgrade_ids = []
    @rerolls_left = 3
    @bans_left = 3
    @upgrade_hold_action = nil
    @upgrade_hold_timer = 0.0
    @upgrade_hold_lock_action = nil
    @pending_upgrade = false
    @pending_upgrade_count = 0
    @pending_upgrade_queue = []
    @pending_move_count = 0
    @current_upgrade_kind = nil
    @moves_drop_pity = 0
    @wild_moves_drop_pity = 0
    @upgrades_exhausted = false
    @tower_fallback_upgrade_id = nil
    @pause_index = 0
    @doom_spawn_count = 0
    @doom_final_started = false
    @hero_base_name = hero_name
    @hero_shiny_active = PokemonSurvivor.pokemon_shiny_active?(hero_name) rescue false
    @hero_power_stage = 0
    @run_finished = false
    @run_abandoned = false
    @run_won = false
    @victory = false
    @run_result = nil
    @leaderboard_submitted = false
    @shop_currency_awarded = false
    @candy_currency_awarded = false
    @leaderboard_run_key = PokemonSurvivor.leaderboard_run_key
    @run_unlock_messages = []
    @final_evolution_times = {}
    @lost_half_hp = false
    @rush_boss_sequence = rush_mode? ? PokemonSurvivor.rush_boss_sequence : []
    @rush_boss_generation = rush_mode? ? PokemonSurvivor.rush_boss_generation_for_sequence(@rush_boss_sequence) : nil
    @rush_wave_index = 0
    @rush_total_waves = @rush_boss_sequence.length
    @rush_spawn_delay = rush_mode? ? 0.65 : 999_999.0
    @rush_complete = false
    @rush_final_boss_defeated = false
    @rush_time_score_awarded = false
    @endless_score_awarded = false
    @rush_wall_flash = {}
    @tower_floor = 1
    @tower_floor_started = false
    @tower_floor_kills_start = 0
    @tower_bosses_defeated = 0
    @tower_damage_taken = 0
    @tower_complete = false
    @tower_score_awarded = false
    @tower_bgm_floor_bucket = 0
    @rush_boss_ring_timers = {}
    @run_objective_popup_timer = 4.0
    @run_objective_popup_text = run_objective_popup_text
    @run_info_hint_timer = 10.0
    @focus_step_cooldown = 0.0
    @focus_step_flash_timer = 0.0
    @focus_step_input_buffer = 0.0
    @focus_step_button_down = false
    @focus_step_anim = nil
    @focus_step_afterimages = []
    setup_random_events if respond_to?(:setup_random_events)
    build_hero(hero_name)
    endless_mode? ? apply_endless_shop_upgrades : apply_roguelite_shop_upgrades
    apply_pokemon_training_upgrades
    request_upgrade(0.05, 3) if rush_mode?
    draw_game
  end


  def apply_roguelite_shop_upgrades
    return if endless_mode?
    hp_mult = PokemonSurvivor.shop_effect_multiplier(:max_hp_percent)
    if @hero && hp_mult > 1.0
      @hero.max_hp = [(@hero.max_hp.to_i * hp_mult).round, 1].max
      @hero.hp = @hero.max_hp
    end
    @damage_mult *= PokemonSurvivor.shop_effect_multiplier(:damage_percent)
    @xp_gain_mult *= PokemonSurvivor.shop_effect_multiplier(:xp_gain_percent)
    @burst_charge_mult = (@burst_charge_mult || 1.0) * PokemonSurvivor.shop_effect_multiplier(:burst_charge_percent)
    if @ultimate_data
      start_percent = PokemonSurvivor.shop_effect_value(:starting_burst_percent).to_f
      @ultimate_charge = [@ultimate_data[:cooldown].to_f * (start_percent / 100.0), @ultimate_data[:cooldown].to_f].min if start_percent > 0
    end
    @bonus_fatal_guard_charges = @bonus_fatal_guard_charges.to_i + PokemonSurvivor.shop_effect_value(:fatal_guard_charges).to_i
    @bonus_fatal_guard_enabled = @bonus_fatal_guard_charges.to_i > 0
    if @hero
      @hero.speed *= PokemonSurvivor.shop_effect_multiplier(:speed_percent)
    end
    @rerolls_left = @rerolls_left.to_i + PokemonSurvivor.shop_effect_value(:reroll_bonus).to_i
    @bans_left = @bans_left.to_i + PokemonSurvivor.shop_effect_value(:ban_bonus).to_i
  rescue
  end
  def apply_pokemon_training_upgrades
    base = PokemonSurvivor.species_key(@hero_base_name)
    hp_mult = PokemonSurvivor.pokemon_training_effect_multiplier(base, :pokemon_max_hp_percent)
    if @hero && hp_mult > 1.0
      @hero.max_hp = [(@hero.max_hp.to_i * hp_mult).round, 1].max
      @hero.hp = @hero.max_hp
    end
    @damage_mult *= PokemonSurvivor.pokemon_training_effect_multiplier(base, :pokemon_damage_percent)
    @pickup_mult = (@pickup_mult || 1.0) * PokemonSurvivor.pokemon_training_effect_multiplier(base, :pokemon_pickup_percent)
    @burst_charge_mult = (@burst_charge_mult || 1.0) * PokemonSurvivor.pokemon_training_effect_multiplier(base, :pokemon_burst_charge_percent)
    @hero.speed *= PokemonSurvivor.pokemon_training_effect_multiplier(base, :pokemon_speed_percent) if @hero
    apply_pokemon_shiny_training_bonus(base) if PokemonSurvivor.pokemon_shiny_unlocked?(base)
    draft_bonus = PokemonSurvivor.pokemon_training_effect_value(base, :pokemon_draft_bonus).to_i
    @rerolls_left = @rerolls_left.to_i + draft_bonus
    @bans_left = @bans_left.to_i + draft_bonus
    apply_pokemon_equipment_effects(base) if respond_to?(:apply_pokemon_equipment_effects)
  rescue
  end

  def apply_pokemon_shiny_training_bonus(base)
    return if !@hero
    mult = 1.31
    old_max = @hero.max_hp.to_i
    @hero.max_hp = [(@hero.max_hp.to_i * mult).round, 1].max
    @hero.hp = [@hero.hp.to_i + (@hero.max_hp - old_max), @hero.max_hp].min
    @damage_mult = (@damage_mult || 1.0) * mult
    @xp_gain_mult = (@xp_gain_mult || 1.0) * mult
    @pickup_mult = (@pickup_mult || 1.0) * mult
    @hero.speed *= mult
    @shield_mult = (@shield_mult || 1.0) * 0.69
    @enemy_projectile_shield_mult = (@enemy_projectile_shield_mult || 1.0) * 0.69
  rescue
  end

  def apply_endless_shop_upgrades
    hp_mult = PokemonSurvivor.shop_effect_multiplier(:endless_max_hp_percent, :endless)
    if @hero && hp_mult > 1.0
      @hero.max_hp = [(@hero.max_hp.to_i * hp_mult).round, 1].max
      @hero.hp = @hero.max_hp
    end
    @damage_mult *= PokemonSurvivor.shop_effect_multiplier(:endless_damage_percent, :endless)
    @xp_gain_mult *= PokemonSurvivor.shop_effect_multiplier(:endless_xp_gain_percent, :endless)
    @burst_charge_mult = (@burst_charge_mult || 1.0) * PokemonSurvivor.shop_effect_multiplier(:endless_burst_charge_percent, :endless)
    @endless_pressure_relief_percent = PokemonSurvivor.shop_effect_value(:endless_pressure_relief_percent, :endless).to_i
    @bonus_fatal_guard_charges = @bonus_fatal_guard_charges.to_i + PokemonSurvivor.shop_effect_value(:endless_fatal_guard_charges, :endless).to_i
    @bonus_fatal_guard_enabled = @bonus_fatal_guard_charges.to_i > 0
    @hero.speed *= PokemonSurvivor.shop_effect_multiplier(:endless_speed_percent, :endless) if @hero
    draft_bonus = PokemonSurvivor.shop_effect_value(:endless_draft_bonus, :endless).to_i
    @rerolls_left = @rerolls_left.to_i + draft_bonus
    @bans_left = @bans_left.to_i + draft_bonus
  rescue
  end
  def run_objective_popup_text
    if rush_mode?
      _INTL("Defeat the 4 Bosses.")
    elsif tower_mode?
      _INTL("Conquer the Tower.")
    elsif endless_mode?
      _INTL("Survive as long as possible.")
    else
      _INTL("Survive 15 minutes.")
    end
  rescue
    ""
  end

  def rush_mode?
    @run_mode == :rush
  rescue
    false
  end

  def tower_mode?
    @run_mode == :tower
  rescue
    false
  end

  def endless_mode?
    @run_mode == :endless
  rescue
    false
  end

  def arena_mode?
    rush_mode? || tower_mode?
  rescue
    false
  end

  def setup_hero_sprite_set(name)
    return if !@hero
    @hero.name = name.to_s
    @hero.bitmap = cached_bitmap(PokemonSurvivor::HERO_DIR, name)
    @hero.walk_bitmap = @hero.bitmap
    @hero.idle_bitmap = nil
    @hero.charset_directions = PokemonSurvivor::CHARSET_DIRECTIONS
    if PokemonSurvivor.eight_direction_hero?(name)
      @hero.charset_directions = PokemonSurvivor::CHARSET_8_DIRECTIONS
      PokemonSurvivor.register_eight_direction_bitmap(@hero.walk_bitmap, PokemonSurvivor.eight_direction_asset_frame_count(name))
      @hero.idle_bitmap = cached_hero_idle_bitmap(name) if respond_to?(:cached_hero_idle_bitmap)
      PokemonSurvivor.register_eight_direction_bitmap(@hero.idle_bitmap, PokemonSurvivor.eight_direction_asset_frame_count("#{name}_IDLE")) if @hero.idle_bitmap
    end
  rescue
  end
  def build_hero(name)
    reset_burst_run_state
    data = PokemonSurvivor.hero_data(name)
    @hero_name = name
    @hero_skill = data[:skill]
    @learned_skills = [@hero_skill]
    @skill_cooldowns = {}
    @hero_color = data[:color]
    @hero = PokemonSurvivorEntity.new(:hero, name, Graphics.width / 2, Graphics.height / 2)
    @hero.max_hp = data[:hp].to_i
    @hero.hp = @hero.max_hp
    @hero.speed = data[:speed].to_f
    @hero_base_speed = @hero.speed
    @hero.radius = PokemonSurvivor::HERO_RADIUS
    setup_hero_sprite_set(name)

    @hero.types = PokemonSurvivor.species_types(name)
    @base_attack_type = PokemonSurvivor::SKILLS[@hero_skill][:type] || @hero.types[0] || :NORMAL
    @hero.attack_type = @base_attack_type
    @invuln = 0.0
    @pickup_mult = 1.0
    @damage_mult = 1.0
    @cooldown_mult = 1.0
    @projectile_count_bonus = 0
    @shield_mult = 1.0
    @enemy_projectile_shield_mult = 1.0
    @chest_xp_mult = 1.0
    @xp_gain_mult = 1.0
    @burst_charge_mult = 1.0
    @endless_pressure_relief_percent = 0
    @boss_damage_mult = 1.0
    @mewtwo_boss_active = false
    @passive_regen_rate = 0.0
    @skill_power_mult = Hash.new(1.0)
    @skill_cooldown_mult = Hash.new(1.0)
    @skill_radius_bonus = Hash.new(0)
    @skill_count_bonus = Hash.new(0)
    @skill_line_bonus = Hash.new(0)
    @skill_orbit_speed_bonus = Hash.new(0)
    @skill_knockback_bonus = Hash.new(0)
    @skill_freeze_bonus = Hash.new(0.0)
    @skill_pierce_bonus = Hash.new(0)
    @skill_bounce_bonus = Hash.new(0)
    @skill_impact_bonus = Hash.new(0)
    @skill_dot_damage_bonus = Hash.new(0)
    @skill_speed_mult = Hash.new(1.0)
    @equipped_item = nil
    @equipment_type_damage_mult = Hash.new(1.0)
    @equipment_last_hit_time = 0.0
    @equipment_contact_mult = 1.0
    @equipment_dash_cooldown_mult = 1.0
    @equipment_dot_mult = 1.0
    @equipment_control_duration_mult = 1.0
    @equipment_hunt_reward_mult = 1.0
    @equipment_currency_gain_mult = 1.0
    @equipment_fragment_gain_mult = 1.0
    @equipment_shiny_candy_mult = 1.0
    @equipment_shell_bell_kills = 0
    @equipment_shell_bell_heal_percent = 0.0
    @equipment_shell_bell_counter = 0
    @equipment_control_resist_percent = 0
    @equipment_baby_hp_mult = 1.0
    @equipment_baby_damage_mult = 1.0
    @equipment_baby_revive_percent = 0
    @equipment_baby_revive_available = false
    @equipment_status_chance_mult = 1.0
    @equipment_boss_kill_damage_percent = 0.0
    @equipment_boss_kill_damage_stacks = 0
    @equipment_endless_score_interval_percent = 0
    @global_skill_radius_bonus = 0
    @element_focus_mult = 1.0
    @status_duration_mult = 1.0
    @rare_draft_level = 0
    @tower_floor_momentum_level = 0
    @tower_floor_momentum_awarded_floor = 0
    @boss_preparation_level = 0
    @overlevel_bonus_rate = 0.0
    @clean_focus_charge_mult = 1.0
    @clean_focus_nohit_timer = 0.0
    @guarded_heart_mult = 1.0
    @orbit_hit_timers = {}
    @orbit_shot_timers = {}
    @sfx_next_time = {}
    @item_invuln_timer = 0.0
    @power_boost_timer = 0.0
    @force_magnet_timer = 0.0
    @abra_dash_count = 0
    @hero_item_flash_timer = 0.0
    @hero_item_flash_color = nil
    @hero_item_effect_tints = {}
    @gauge_flash_timer = 0.0
    @level_flash_timer = 0.0
    @upgrade_delay_timer = 0.0
    @passive_key = PokemonSurvivor.species_key(name)
    @berry_heal_mult = 1.0
    @passive_low_hp_damage_mult = 1.0
    @passive_low_hp_threshold = 0.0
    @passive_poison_dot_bonus = 0.0
    @passive_ground_zone_duration_mult = 1.0
    @passive_ground_slow_mult = nil
    @passive_level_heal_rate = 0.0
    @passive_fatal_guard_used = false
    @mimikyu_disguise_broken = false
    @bonus_fatal_guard_charges = 0
    @bonus_fatal_guard_enabled = false
    @bonus_fatal_guard_used = false
    @passive_hit_power_timer = 0.0
    @passive_hit_power_mult = 1.0
    @passive_starly_hit_chain = 0
    @passive_starly_hit_bonus = 0.0
    @passive_burst_on_kill = 0.0
    @vampiric_chance = 0.0
    @vampiric_heal_rate = 0.001
    @deoxys_form_name = :DEOXYS
    @deoxys_last_form_rate = 1.0
    @goomy_steel_route = nil
    @applin_guard_charge_ready_at = 0.0
    apply_hero_passive
    @ultimate_data = PokemonSurvivor.ultimate_data(@hero_base_name || name)
    @ultimate_charge = 0.0
    @ultimate_ready_flash = 0.0
    @ultimate_prompt_timer = 0.0
    @ultimate_drain_timer = 0.0
    @ultimate_drain_duration = 0.0
    @ultimate_action_buffer = false
    @ultimate_action_buffer_timer = 0.0
    @pending_evolution_stage = nil
    @evolution_anim = nil
    @run_start_max_hp = @hero.max_hp
  end

  def apply_hero_passive
    case @passive_key
    when :ZIGZAGOON_1
      @pickup_mult *= 1.20
    when :SQUIRTLE
      @shield_mult *= 0.90
    when :SKARMORY, :SUICUNE
      @enemy_projectile_shield_mult = (@enemy_projectile_shield_mult || 1.0) * 0.85
    when :HATENNA
      @enemy_projectile_shield_mult = (@enemy_projectile_shield_mult || 1.0) * 0.80
    when :ROOKIDEE
      @shield_mult *= 0.90
    when :BULBASAUR
      @skill_power_mult[:leaf] *= 1.15
      @berry_heal_mult = 1.10
    when :CYNDAQUIL
      @passive_low_hp_damage_mult = 1.25
      @passive_low_hp_threshold = 0.50
    when :MUDKIP
      @passive_level_heal_rate = 0.08
    when :MAREEP
      @skill_power_mult[:thunder_ring] *= 1.15
      @skill_speed_mult[:thunder_ring] *= 1.10
    when :RALTS
      @skill_cooldown_mult[:fairy_guard] *= 0.88
      @skill_radius_bonus[:fairy_guard] += 8
    when :GASTLY
      @passive_fatal_guard_used = false
    when :ARON
      @hero.max_hp += 25
      @hero.hp = @hero.max_hp
      @shield_mult *= 0.86
    when :NIDORANm
      @skill_power_mult[:poison_aura] *= 1.20
      @passive_poison_dot_bonus = 1.0
    when :BAGON
      @skill_power_mult[:dragon_arc] *= 1.15
      @damage_mult *= 1.08
    when :BELDUM
      @skill_power_mult[:steel_orbit] *= 1.15
      @skill_radius_bonus[:steel_orbit] += 12
      @skill_speed_mult[:steel_orbit] *= 1.25
    when :ZANGOOSE
      @damage_mult *= 1.12
      @hero.speed *= 1.05
    when :SABLEYE
      @chest_xp_mult *= 1.40
    when :MACHOP
      @passive_hit_power_mult = 1.35
    when :TRAPINCH
      @skill_power_mult[:ground_spike] *= 1.12
      @skill_radius_bonus[:ground_spike] += 8
      @passive_ground_zone_duration_mult = 1.35
      @passive_ground_slow_mult = 0.16
    when :ZUBAT
      @skill_cooldown_mult[:flying_gust] *= 0.88
      @skill_knockback_bonus[:flying_gust] += 10
      @hero.speed *= 1.06
    when :SPHEAL
      @hero.max_hp += 18
      @hero.hp = @hero.max_hp
      @skill_radius_bonus[:ice_zone] += 6
      @skill_freeze_bonus[:ice_zone] += 0.5
    when :SPINARAK
      @skill_cooldown_mult[:bug_thread] *= 0.90
      @skill_freeze_bonus[:bug_thread] += 0.45
    when :AZURILL
      @skill_power_mult[:water_orbit] *= 1.10
      @skill_cooldown_mult[:water_orbit] *= 0.92
      @skill_knockback_bonus[:water_orbit] += 10
    when :WHISMUR
      @skill_cooldown_mult[:echo_charge] *= 0.90
      @skill_knockback_bonus[:echo_charge] += 12
    when :DRATINI
      @skill_power_mult[:dragon_shot] *= 1.12
      @skill_speed_mult[:dragon_shot] *= 1.08
    when :CHIMCHAR
      @skill_power_mult[:fire2_combo] *= 1.12
      @skill_cooldown_mult[:fire2_combo] *= 0.90
      @hero.speed *= 1.04
    when :FENNEKIN
      @skill_power_mult[:foxfire_seek] *= 1.14
      @skill_cooldown_mult[:foxfire_seek] *= 0.90
      @skill_dot_damage_bonus[:foxfire_seek] += 1
      @hero.speed *= 1.04
    when :FROAKIE
      @skill_power_mult[:water_shuriken] *= 1.08
      @skill_speed_mult[:water_shuriken] *= 1.12
      @hero.speed *= 1.05
    when :HONEDGE
      @skill_power_mult[:living_blade] *= 1.12
      @skill_radius_bonus[:living_blade] += 8
      @shield_mult *= 0.94
    when :GOOMY
      @skill_power_mult[:slime_wave] *= 1.08
      @skill_radius_bonus[:slime_wave] += 8
      @passive_ground_zone_duration_mult = [@passive_ground_zone_duration_mult.to_f, 1.18].max
      @shield_mult *= 0.94
    when :NOIBAT
      @skill_cooldown_mult[:sonic_wave] *= 0.90
      @skill_speed_mult[:sonic_wave] *= 1.10
      @burst_charge_mult *= 1.08
    when :TYRUNT
      @skill_power_mult[:fossil_jaw] *= 1.16
      @boss_damage_mult *= 1.10
    when :HAWLUCHA
      @skill_power_mult[:sky_press] *= 1.12
      @skill_cooldown_mult[:sky_press] *= 0.94
      @hero.speed *= 1.08
    when :STARLY
      @skill_cooldown_mult[:flying_spread] *= 0.94
      @hero.speed *= 1.08
    when :SHINX
      @skill_power_mult[:shinx_charge] *= 1.10
      @skill_cooldown_mult[:shinx_charge] *= 0.96
    when :GIBLE
      @skill_power_mult[:dragon_pierce] *= 1.12
      @skill_speed_mult[:dragon_pierce] *= 0.94
    when :RIOLU
      @skill_power_mult[:aura_charge] *= 1.10
      @skill_cooldown_mult[:aura_charge] *= 0.96
    when :CROAGUNK
      @skill_power_mult[:toxic_bounce] *= 1.08
      @skill_cooldown_mult[:toxic_bounce] *= 0.95
    when :LITWICK
      @skill_power_mult[:litwick_ghost_bounce] *= 1.10
      @skill_cooldown_mult[:litwick_ghost_bounce] *= 0.94
    when :SANDILE
      @skill_power_mult[:sandile_ground_zone] *= 1.10
      @passive_ground_zone_duration_mult = [@passive_ground_zone_duration_mult.to_f, 1.20].max
    when :PAWNIARD
      @skill_power_mult[:steel_volley] *= 1.10
      @skill_cooldown_mult[:steel_volley] *= 0.94
    when :DRILBUR
      @skill_cooldown_mult[:drill_spikes] *= 0.92
      @skill_power_mult[:drill_spikes] *= 1.08
      @hero.speed *= 1.04
    when :VENIPEDE
      @skill_cooldown_mult[:toxic_thread] *= 0.92
      @skill_dot_damage_bonus[:toxic_thread] += 1
    when :VANILLITE
      @skill_radius_bonus[:ice_zone] += 8
      @skill_freeze_bonus[:ice_zone] += 0.35
    when :DEINO
      @skill_power_mult[:dragon_pulse] *= 1.12
      @passive_burst_on_kill += 0.001
    when :LARVESTA
      @skill_power_mult[:cinder_swarm] *= 1.10
      @skill_cooldown_mult[:cinder_swarm] *= 0.93
    when :ZORUA
      @skill_cooldown_mult[:night_bolt] *= 0.92
      @hero.speed *= 1.05
    when :ZORUA_1
      @skill_cooldown_mult[:twin_mirage] *= 0.92
      @skill_power_mult[:twin_mirage] *= 1.12
when :FEEBAS
  @pickup_mult *= 1.08
when :ROWLET
  @skill_power_mult[:leaf_orbit] *= 1.12
  @skill_orbit_speed_bonus[:leaf_orbit] += 1
when :GRUBBIN
  @skill_power_mult[:battery_shuriken] *= 1.10
  @skill_freeze_bonus[:battery_shuriken] += 0.25
when :WIMPOD
  @skill_cooldown_mult[:toxic_scuttle] *= 0.90
  @skill_dot_damage_bonus[:toxic_scuttle] += 1
when :JANGMOO
  @skill_power_mult[:scale_lance] *= 1.12
  @boss_damage_mult *= 1.08
when :KOMALA
  @skill_radius_bonus[:drowsy_spin] += 8
  @shield_mult *= 0.94
when :MIMIKYU
  @passive_fatal_guard_used = false
  @mimikyu_disguise_broken = false
  @skill_power_mult[:fairy_arc] *= 1.10
when :ROCKRUFF
  @skill_cooldown_mult[:rock_run] *= 0.90
  @skill_knockback_bonus[:rock_run] += 12
  @hero.speed *= 1.06
    when :MAGIKARP
      @pickup_mult *= 1.08
      @skill_power_mult[:hydro_pump] *= 1.10
      @skill_radius_bonus[:hydro_pump] += 4
    when :MEW
      @passive_level_heal_rate = 0.10
    end
  rescue
  end

  def run_bonus_panel_triggered?
    return PokemonSurvivor.control_trigger?(:action) if PokemonSurvivor.respond_to?(:control_trigger?)
    return true if Input.const_defined?(:ACTION) && Input.trigger?(Input::ACTION)
    false
  rescue
    false
  end

  def toggle_run_bonus_panel
    @run_info_hint_timer = 0.0
    setting = PokemonSurvivor.run_info_panel_mode rescue :stats
    if setting == :both
      if !@run_bonus_panel_open
        @run_bonus_panel_open = true
        @run_bonus_panel_mode = :bonuses
      elsif @run_bonus_panel_mode == :bonuses
        @run_bonus_panel_mode = :stats
      else
        @run_bonus_panel_open = false
      end
    else
      if !@run_bonus_panel_open
        @run_bonus_panel_open = true
        @run_bonus_panel_mode = setting == :bonuses ? :bonuses : :stats
      else
        @run_bonus_panel_open = false
      end
    end
    pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue pbPlayCursorSE rescue nil
  rescue
  end

  def update_run_bonus_panel(dt)
    @run_bonus_panel_slide = 0.0 if @run_bonus_panel_slide.nil?
    target = @run_bonus_panel_open ? 1.0 : 0.0
    speed = dt.to_f * 8.5
    if @run_bonus_panel_slide < target
      @run_bonus_panel_slide = [@run_bonus_panel_slide + speed, target].min
    elsif @run_bonus_panel_slide > target
      @run_bonus_panel_slide = [@run_bonus_panel_slide - speed, target].max
    end
  rescue
    @run_bonus_panel_slide = @run_bonus_panel_open ? 1.0 : 0.0
  end
  # The passive adds base stats, not a multiplier on purchased run bonuses.
  # These values are shared by combat, XP drops and the statistics panel.
  def effective_run_damage_multiplier
    (@damage_mult || 1.0).to_f + (@mewtwo_boss_active ? 1.0 : 0.0)
  end

  def effective_run_xp_multiplier
    (@xp_gain_mult || 1.0).to_f + (@mewtwo_boss_active ? 1.0 : 0.0)
  end

  def mewtwo_guard_multiplier
    @mewtwo_boss_active ? 0.5 : 1.0
  end

  def update_game(dt)
    @mewtwo_boss_active = @passive_key == :MEWTWO && @enemies.any? { |enemy| enemy.hp > 0 && [:boss, :ultra_boss].include?(enemy.kind) }
    if @evolution_anim
      update_hero_evolution_animation(dt)
      update_effects(dt)
      return
    end
    update_run_bonus_panel(dt)
    @timer += dt
    capture_classic_competitive_stats if classic_mode_timer_complete?
    if tower_mode? && tower_floor_transition_active?
      update_tower_floor_transition(dt)
      return
    end
    if tower_mode? && !tower_floor_transition_active? && @tower_fade_alpha.to_i >= 255 && !@tower_floor_started && !@pending_upgrade && @pending_upgrade_count.to_i <= 0
      # Automatic rewards skip the choice menu, but not the floor preparation.
      prepare_next_tower_floor_after_bonus
      update_tower_floor_transition(dt) if tower_floor_transition_active?
      return
    end
    start_doom_finale if classic_mode_timer_complete? && !@doom_final_started
    @spawn_timer -= dt
    @boss_timer -= dt if !arena_mode?
    @chest_timer -= dt if !arena_mode?
    @item_timer -= dt
    @invuln -= dt if @invuln > 0
    @psyduck_confusion_timer = [@psyduck_confusion_timer.to_f - dt, 0.0].max
    @psyduck_burst_wait_timer = [@psyduck_burst_wait_timer.to_f - dt, 0.0].max
    update_focus_step(dt) if respond_to?(:update_focus_step)
    @item_invuln_timer -= dt if @item_invuln_timer > 0
    @power_boost_timer -= dt if @power_boost_timer > 0
    @force_magnet_timer -= dt if @force_magnet_timer > 0
    @clean_focus_nohit_timer = @clean_focus_nohit_timer.to_f + dt.to_f if @clean_focus_charge_mult.to_f > 1.0
    @kubfu_focus_timer = [@kubfu_focus_timer.to_f - dt, 0.0].max if @kubfu_focus_timer.to_f > 0
    if @projectile_overdrive_timer.to_f > 0
      @projectile_overdrive_timer -= dt
      @projectile_overdrive_mult = 1.0 if @projectile_overdrive_timer <= 0
    end
    @hero_item_flash_timer -= dt if @hero_item_flash_timer.to_f > 0
    @run_objective_popup_timer -= dt if @run_objective_popup_timer.to_f > 0
    @run_info_hint_timer -= dt if @run_info_hint_timer.to_f > 0
    @passive_hit_power_timer -= dt if @passive_hit_power_timer.to_f > 0
    @gauge_flash_timer -= dt if @gauge_flash_timer.to_f > 0
    update_rush_wall_flash(dt) if @rush_wall_flash && !@rush_wall_flash.empty?
    @level_flash_timer -= dt if @level_flash_timer.to_f > 0
    @upgrade_delay_timer -= dt if @upgrade_delay_timer.to_f > 0
    invalidate_enemy_grid
    update_deoxys_form
    update_aegislash_form
    update_survivor_cry_queue(dt) if respond_to?(:update_survivor_cry_queue)
    update_ultimate(dt)
    update_player(dt)
    update_zubat_burst(dt)
    update_treecko_zangoose_burst_timers(dt)
    if respond_to?(:update_random_events)
      update_random_events(dt)
      return if @state != :play
    end
    process_bitmap_preload_queue
    cleanup_active_entities
    process_spawn_queue
    spawn_wave if @spawn_timer <= 0
    if rush_mode?
      update_rush_mode(dt)
    elsif tower_mode?
      update_tower_mode(dt)
    else
      spawn_boss if @boss_timer <= 0 && !@doom_final_started
      spawn_chest if @chest_timer <= 0 && !@doom_final_started
      update_ultra_spawns if !@doom_final_started
    end
    return if tower_mode? && tower_floor_transition_active?
    spawn_wild_item if @item_timer <= 0
    update_charge_shots(dt)
    update_attacks(dt)
    update_orbit_skills(dt)
    update_enemies(dt)
    update_items(dt)
    update_projectiles(dt)
    update_xp(dt)
    check_hero_evolution
    update_effects(dt)
    enforce_fairy_prison_bounds
    if respond_to?(:process_pending_sleep_reward) && @hero.hp.to_i > 0 && process_pending_sleep_reward
      return
    elsif @pending_upgrade && @upgrade_delay_timer.to_f <= 0
      open_upgrade
    elsif @pending_evolution_stage && !@pending_upgrade
      start_pending_hero_evolution
    elsif @hero.hp <= 0
      finish_run
      @state = :gameover
      @result_text = _INTL("Survival ended.")
      play_survivor_result_bgm
      draw_gameover
    elsif classic_mode_timer_complete?
      finish_run
      @state = :gameover
      @result_text = _INTL("You survived!")
      play_survivor_result_bgm
      draw_gameover
    end
  end


  def classic_mode_timer_complete?
    @run_mode == :classic && @timer.to_f >= PokemonSurvivor::MAX_SECONDS
  rescue
    false
  end

  def endless_difficulty_stage
    return 0 if !endless_mode?
    [(@timer.to_f / PokemonSurvivor::ENDLESS_DIFFICULTY_STEP_SECONDS.to_f).floor, 0].max
  rescue
    0
  end

  def award_endless_score
    return if @endless_score_awarded
    seconds = [@timer.to_f, 0.0].max
    stage = endless_difficulty_stage
    time_score = (seconds * PokemonSurvivor::ENDLESS_SCORE_PER_SECOND).round
    level_score = @level.to_i * PokemonSurvivor::ENDLESS_SCORE_PER_LEVEL
    stage_score = stage.to_i * PokemonSurvivor::ENDLESS_SCORE_STAGE_BONUS
    @score = [@score.to_i + time_score + level_score + stage_score, 0].max
    @endless_score_awarded = true
  rescue
  end
  def update_passive_regen(dt)
    return if @passive_regen_rate.to_f <= 0 || !@hero || @hero.hp.to_i <= 0 || @hero.hp.to_i >= @hero.max_hp.to_i
    @passive_regen_timer = @passive_regen_timer.to_f - dt.to_f
    return if @passive_regen_timer > 0
    @passive_regen_timer = 1.0
    heal = [(@hero.max_hp.to_f * @passive_regen_rate.to_f).round, 1].max
    @hero.hp = [@hero.hp.to_i + heal, @hero.max_hp.to_i].min
  rescue
  end
  def deoxys_hero?
    PokemonSurvivor.species_key(@hero_base_name || (@hero && @hero.name)) == :DEOXYS
  rescue
    false
  end

  def deoxys_current_form
    return nil if !deoxys_hero?
    PokemonSurvivor.species_key(@hero.name)
  rescue
    nil
  end

  def target_deoxys_form
    return :DEOXYS if !@hero || @hero.max_hp.to_i <= 0
    rate = @hero.hp.to_f / @hero.max_hp.to_f
    return :DEOXYS_2 if rate <= 0.25
    return :DEOXYS_1 if rate <= 0.50
    return :DEOXYS_3 if rate <= 0.75
    return :DEOXYS if rate >= 0.76
    deoxys_current_form || :DEOXYS
  rescue
    :DEOXYS
  end

  def update_deoxys_form
    return if !deoxys_hero? || !@hero || @hero.hp.to_i <= 0 || @evolution_anim
    target = target_deoxys_form
    return if target == deoxys_current_form
    start_deoxys_transform(target)
  rescue
  end

  def start_deoxys_transform(new_name)
    old_name = @hero.name
    @deoxys_form_name = PokemonSurvivor.species_key(new_name)
    @evolution_anim = {
      stage: 0,
      old_name: old_name,
      old_bitmap: @hero.bitmap,
      new_name: new_name.to_s,
      new_bitmap: cached_bitmap(PokemonSurvivor::HERO_DIR, new_name),
      elapsed: 0.0,
      transform_only: true,
      vfx_name: "VFX_TRANSFORM"
    }
    @hero.moving = false
    @invuln = [@invuln.to_f, 16.0 / 60.0].max
    repel_nearby_threats(150, 8.0, true)
    pbSEPlay("Survivor/Battle recall", PokemonSurvivor::SFX_EVOLUTION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    play_survivor_se(:deoxys_transform_vfx, "Survivor/Shiny sparkle", 0.5, PokemonSurvivor::SFX_EVOLUTION_VFX_VOLUME, 92)
  rescue
    apply_deoxys_form(new_name) rescue nil
  end

  def apply_deoxys_form(new_name)
    return if !@hero
    setup_hero_sprite_set(new_name)
    play_survivor_cry(new_name, 76, 100) if respond_to?(:play_survivor_cry)
    @hero.types = PokemonSurvivor.species_types(:DEOXYS)
    @hero_color = PokemonSurvivor.hero_data(new_name)[:color] rescue @hero_color
  rescue
  end

  def deoxys_attack_multiplier
    deoxys_current_form == :DEOXYS_1 ? 2.0 : 1.0
  rescue
    1.0
  end

  def deoxys_damage_taken_multiplier
    deoxys_current_form == :DEOXYS_2 ? 0.5 : 1.0
  rescue
    1.0
  end

  def deoxys_burst_charge_multiplier
    return 0.0 if deoxys_current_form == :DEOXYS_2
    return 2.0 if deoxys_current_form == :DEOXYS_3
    1.0
  rescue
    1.0
  end

  def deoxys_move_multiplier
    deoxys_current_form == :DEOXYS_3 ? 2.0 : 1.0
  rescue
    1.0
  end

  def aegislash_hero?
    PokemonSurvivor.species_key(@hero_base_name || (@hero && @hero.name)) == :HONEDGE
  rescue
    false
  end

  def aegislash_current_form
    return nil if !aegislash_hero?
    PokemonSurvivor.species_key(@hero.name)
  rescue
    nil
  end

  def target_aegislash_form
    return nil if !@hero || @hero.max_hp.to_i <= 0
    current = aegislash_current_form
    return nil if current != :AEGISLASH && current != :AEGISLASH_1
    (@hero.hp.to_f / @hero.max_hp.to_f) > 0.50 ? :AEGISLASH_1 : :AEGISLASH
  rescue
    nil
  end

  def update_aegislash_form
    return if !aegislash_hero? || !@hero || @hero.hp.to_i <= 0 || @evolution_anim
    target = target_aegislash_form
    return if !target || target == aegislash_current_form
    setup_hero_sprite_set(target)
    @hero.types = PokemonSurvivor.species_types(target)
    @hero_color = PokemonSurvivor.hero_data(target)[:color] rescue @hero_color
  rescue
  end

  def aegislash_attack_multiplier
    aegislash_current_form == :AEGISLASH_1 ? 2.0 : 1.0
  rescue
    1.0
  end

  def aegislash_damage_taken_multiplier
    case aegislash_current_form
    when :AEGISLASH_1 then 1.75
    when :AEGISLASH then 0.33
    else 1.0
    end
  rescue
    1.0
  end

  def aegislash_move_multiplier
    aegislash_current_form == :AEGISLASH ? 0.50 : 1.0
  rescue
    1.0
  end

  def update_ultimate(dt)
    return if !@ultimate_data
    cooldown = [@ultimate_data[:cooldown].to_f, 1.0].max
    was_ready = ultimate_ready?
    charge_rate = post_100_bonus_multiplier * deoxys_burst_charge_multiplier * (@burst_charge_mult || 1.0)
    charge_rate *= @clean_focus_charge_mult.to_f if @clean_focus_charge_mult.to_f > 1.0 && @clean_focus_nohit_timer.to_f >= 4.0
    charge_rate = [charge_rate, cooldown / minimum_burst_recharge_time].min
    if @ultimate_drain_timer.to_f > 0.0
      @ultimate_drain_timer = [@ultimate_drain_timer.to_f - dt.to_f, 0.0].max
      duration = [@ultimate_drain_duration.to_f, 0.01].max
      @ultimate_charge = cooldown * (@ultimate_drain_timer.to_f / duration)
      @ultimate_ready_flash -= dt if @ultimate_ready_flash.to_f > 0
      @ultimate_prompt_timer -= dt if @ultimate_prompt_timer.to_f > 0
      @ultimate_charge = 0.0 if @ultimate_drain_timer.to_f <= 0.0
      expire_ultimate_action_buffer(dt)
      return
    end
    @ultimate_charge = [[@ultimate_charge.to_f + (dt.to_f * charge_rate), 0.0].max, cooldown].min
    @ultimate_ready_flash -= dt if @ultimate_ready_flash.to_f > 0
    @ultimate_prompt_timer -= dt if @ultimate_prompt_timer.to_f > 0
    if !was_ready && ultimate_ready?
      @ultimate_ready_flash = 0.65
      @ultimate_prompt_timer = 3.0
    end
    if ultimate_action_triggered?
      if ultimate_ready?
        activate_ultimate
      else
        @ultimate_prompt_timer = 0.45 if @ultimate_charge.to_f > 0
        set_hero_item_flash(Color.new(152, 152, 152), 0.16)
      end
    end
    expire_ultimate_action_buffer(dt)
  rescue
  end

  def minimum_burst_recharge_time
    current = @hero && PokemonSurvivor.species_key(@hero.name)
    PokemonSurvivor::EEVEE_STONE_FORMS.value?(current) ? 12.0 : 5.0
  end

  def ultimate_ready?
    return false if !@ultimate_data
    return false if @ultimate_drain_timer.to_f > 0.0
    @ultimate_charge.to_f >= @ultimate_data[:cooldown].to_f
  rescue
    false
  end

  def post_100_bonus_levels
    [[@level.to_i - 100, 0].max, 9899].min
  rescue
    0
  end

  def post_100_bonus_multiplier
    rate = 0.01 + @overlevel_bonus_rate.to_f
    1.0 + (post_100_bonus_levels * rate)
  rescue
    1.0
  end

  def ultimate_action_triggered?
    return false if !@ultimate_action_buffer
    @ultimate_action_buffer = false
    @ultimate_action_buffer_timer = 0.0
    true
  rescue
    false
  end

  def capture_ultimate_action_input
    return if @evolution_anim
    if raw_ultimate_action_triggered?
      @ultimate_action_buffer = true
      @ultimate_action_buffer_timer = 0.16
    end
  rescue
  end

  def input_constant_value(name)
    Input.const_get(name) if Input.const_defined?(name)
  rescue
    nil
  end

  def input_distinct_from_action?(name)
    value = input_constant_value(name)
    action = input_constant_value(:ACTION)
    return false if value.nil?
    return true if action.nil?
    value != action
  rescue
    true
  end

  def raw_ultimate_action_triggered?
    return PokemonSurvivor.control_trigger?(:confirm) if PokemonSurvivor.respond_to?(:control_trigger?)
    return true if Input.const_defined?(:USE) && Input.trigger?(Input::USE)
    return true if Input.const_defined?(:C) && Input.trigger?(Input::C)
    return true if input_distinct_from_action?(:A) && Input.trigger?(Input::A)
    return true if input_distinct_from_action?(:SPECIAL) && Input.trigger?(Input::SPECIAL)
    false
  rescue
    false
  end

  def expire_ultimate_action_buffer(dt)
    return if !@ultimate_action_buffer
    @ultimate_action_buffer_timer = @ultimate_action_buffer_timer.to_f - dt.to_f
    return if @ultimate_action_buffer_timer > 0
    @ultimate_action_buffer = false
    @ultimate_action_buffer_timer = 0.0
  rescue
    @ultimate_action_buffer = false
    @ultimate_action_buffer_timer = 0.0
  end

  def active_ultimate_data
    data = @ultimate_data
    current = PokemonSurvivor.species_key(@hero && @hero.name)
    case current
    when :MAROWAK_1
      return (data || {}).merge(id: :ultimate_alolan_marowak, name: _INTL("Ancestral Dance"),
        desc: _INTL("Fires a rotating Ghost barrage for 8 seconds."),
        kind: :treecko_barrage, type: :GHOST, damage: 28, speed: 8.0, pierce: 3,
        burst_time: 8.0, barrage_time: 8.0, shot_interval: 0.14,
        barrage_directions: 4, vfx: "VFX_GHOST2")
    when :ARMAROUGE
      return (data || {}).merge(id: :ultimate_armarouge, name: _INTL("Psychic Artillery"), desc: _INTL("Fires seeking Psychic shots that create pulling fields for 12 seconds."), kind: :gen9_burst, type: :PSYCHIC, burst_time: 12.0)
    when :CERULEDGE
      return (data || {}).merge(id: :ultimate_ceruledge, name: _INTL("Bitter Fury"), desc: _INTL("For 6 seconds, attacks fire and travel twice as fast, grow larger, and your blades restore HP where healing is allowed."), kind: :gen9_burst, type: :GHOST, burst_time: 6.0)
    when :GOLDUCK
      return (data || {}).merge(id: :ultimate_golduck, name: _INTL("Aqua Cyclone"), desc: _INTL("Fires a rotating Water barrage for 5 seconds."), kind: :treecko_barrage, type: :WATER, damage: 28, speed: 8.2, pierce: 3, burst_time: 5.0, barrage_time: 5.0, shot_interval: 0.12, vfx: "VFX_WATER5")
    when :LINOONE_1, :OBSTAGOON
      if data && data[:kind] == :galar_rush
        evolved = data.merge(magnet_time: 5.0)
        evolved = evolved.merge(power_time: 5.0, power_mult: 2.0) if current == :OBSTAGOON
        return evolved
      end
    when :URSHIFU
      return (data || {}).merge(id: :ultimate_urshifu, name: _INTL("Wicked Barrage"), desc: _INTL("Launches waves of powerful returning Dark blades for 6 seconds. Slows enemies hit."), kind: :returning_blade_burst, type: :DARK, damage: 36, radius: 42, slow: 2.0, count: 4, burst_time: 6.0, interval: 0.55, vfx: "VFX_DARK4", vfx_fps: 30)
    when :URSHIFU_1
      return (data || {}).merge(id: :ultimate_urshifu_rapid, name: _INTL("Surging Torrent"), desc: _INTL("Strikes up to six nearby targets with powerful Water blasts that paralyze enemies caught in them."), kind: :toxic_bombardment, type: :WATER, damage: 90, radius: 48, speed: 0, pierce: 1, count: 6, freeze: 1.5, burst_time: 8.0 / 12.0, vfx: "VFX_WATER4", vfx_fps: 12.0, damage_from_frame: 1, damage_until_frame: 7, visual_radius_base: 28.0)
    when :CORVIKNIGHT
      return data.merge(type: :STEEL, vfx: "VFX_STEEL5") if data && data[:kind] == :rook_tornado_burst
    when :FLAPPLE
      return (data || {}).merge({ id: :ultimate_flapple, name: _INTL("Orchard Cyclone"), desc: _INTL("Fires a rotating barrage of piercing leaves for 4 seconds."), kind: :treecko_barrage, type: :GRASS, damage: 28, speed: 8.2, pierce: 1, infinite_pierce: true, barrage_time: 4.0, shot_interval: 0.12, vfx: "VFX_GRASS" })
    when :APPLETUN
      return (data || {}).merge({ id: :ultimate_appletun, name: _INTL("Sweet Harvest"), desc: _INTL("Rains heavy apples for 4 seconds. Heals 1 HP per 8 damage dealt, except in Breach."), heal_from_damage: 0.125 })
    when :HYDRAPPLE
      return (data || {}).merge({ id: :ultimate_hydrapple, name: _INTL("Dragon Orchard"), desc: _INTL("Fires a rotating barrage of large Dragon projectiles for 4 seconds."), kind: :treecko_barrage, type: :DRAGON, damage: 36, speed: 8.2, pierce: 3, vfx_scale: 2.0, barrage_time: 4.0, shot_interval: 0.12, vfx: "VFX_DRAGON" })
    when :TYPHLOSION_1
      return (data || {}).merge({
        id: :ultimate_typhlosion_hisui,
        name: _INTL("Spectral Wildfire"),
        desc: _INTL("Rapidly fires ghostly flames in four directions, choosing Fire or Ghost damage for each target."),
        kind: :treecko_barrage,
        type: :FIRE,
        dual_types: [:FIRE, :GHOST],
        damage: 18,
        speed: 8.4,
        pierce: 3,
        radius: 124,
        barrage_time: 5.0,
        shot_interval: 0.055,
        vfx: "VFX_FIRE4"
      })
    when :RAICHU_1
      return (data || {}).merge({ id: :ultimate_raichu_alola, name: _INTL("Psychic Swarm"), kind: :radial, type: :PSYCHIC, cooldown: 43.0, damage: 30, speed: 7.5, count: 28, pierce: 3, radius: 120, vfx: "VFX_PSYCHIC3" })
    when :GALLADE
      return (data || {}).merge({ id: :ultimate_gallade_focus, name: _INTL("Focused Blades"), kind: :target_lock_barrage, type: :FIGHTING, cooldown: 48.0, damage: 22, speed: 8.4, pierce: 2, target_count: 4, barrage_time: 5.0, shot_interval: 0.12, vfx: "VFX_FIGHTING4" })
    when :GOODRA_1
      return (data || {}).merge({ id: :ultimate_goodra_hisui, name: _INTL("Steel Ring"), kind: :expanding_orbit_burst, type: :STEEL, cooldown: 50.0, damage: 20, radius: 42, count: 8, burst_time: 3.2, spin_speed: 9.2, expand_speed: 76, knockback: 54, vfx: "VFX_STEEL2" })
    when :DECIDUEYE_1
      return (data || {}).merge({ id: :ultimate_decidueye_hisui, name: _INTL("Fighting Downpour"), kind: :poison_rain, type: :FIGHTING, cooldown: 44.0, damage: 58, radius: 50, rain_time: 5.0, interval: 0.13, impact_damage_mult: 0.55, vfx: "VFX_FIGHTING5", vfx_fps: 24 })
    when :MIMIKYU_1
      return (data || {}).merge({ id: :ultimate_mimikyu_busted, name: _INTL("Dark Echo"), kind: :repeating_shockwave, type: :DARK, cooldown: 48.0, damage: 42, radius: 164, count: 1, burst_time: 5.0, interval: 0.74, vfx: "VFX_DARK3", vfx_fps: 18 })
    when :HONEDGE
      return (data || {}).merge({ id: :ultimate_honedge_blades, name: _INTL("Haunted Blades"), kind: :enemy_swing_burst, type: :STEEL, cooldown: 49.0, damage: 24, radius: 42, target_count: 8, burst_time: 5.0, interval: 0.55, vfx: "VFX_STEEL3", vfx_fps: 30 })
    when :ZOROARK_1
      return (data || {}).merge({ id: :ultimate_zoroark_hisui, name: _INTL("Triple Haunt"), kind: :triple_radial_burst, type: :GHOST, cooldown: 46.0, damage: 30, speed: 7.2, count: 18, pierce: 3, radius: 128, vfx: "VFX_GHOST2" })
    end
    data
  rescue
    @ultimate_data
  end
  def ultimate_skill(data)
    {
      id: data[:id] || :ultimate,
      name: data[:name] || _INTL("Ultimate"),
      kind: data[:kind] || :zone,
      type: data[:type] || @hero.attack_type || :NORMAL,
      damage: (data[:damage] || 0).to_i,
      speed: (data[:speed] || 0).to_f,
      pierce: (data[:pierce] || 0).to_i,
      bounce: (data[:bounce] || 0).to_i,
      radius: (data[:radius] || 0).to_i,
      freeze: data[:freeze],
      slow: data[:slow],
      slow_mult: data[:slow_mult],
      dot: data[:dot],
      knockback: data[:knockback],
      count: data[:count],
      burst_time: data[:burst_time],
      zone_time: data[:zone_time],
      vfx: data[:vfx],
      shot_vfx: data[:shot_vfx],
      impact_radial: data[:impact_radial],
      impact_type: data[:impact_type],
      impact_vfx: data[:impact_vfx],
      dual_types: data[:dual_types],
      rain_direct: data[:rain_direct],
      heal_from_damage: data[:heal_from_damage],
      knock_limit: data[:knock_limit],
      unlimited_knockback: data[:unlimited_knockback],
      instant_ko_normal: data[:instant_ko_normal]
    }
  end

  def ultimate_drain_duration(data)
    return 0.0 if !data
    duration = [:burst_time, :barrage_time, :rain_time, :surge_time, :haste_time, :power_time, :magnet_time, :zone_time, :field_time, :trap_time, :shield].map { |key| data[key].to_f }.max
    return duration if duration > 0.0
    case data[:kind]
    when :poison_crown
      4.2
    when :sand_pit
      3.2
    when :aurora_floe
      3.8
    when :spider_nest
      3.0
    when :tyrunt_shockwave
      repeats = data[:targeted] ? [[data[:repeat].to_i, 1].max, 3].min : 1
      repeat_delay = data[:repeat_delay] ? data[:repeat_delay].to_f : 0.82
      wave_time = data[:targeted] ? 0.54 : 0.62
      extra_stagger = data[:targeted] ? ([[data[:count].to_i, 1].max, 4].min - 1) * 0.08 : ([[data[:count].to_i, 1].max, 4].min - 1) * 0.18
      ((repeats - 1) * repeat_delay) + extra_stagger + wave_time
    else
      0.0
    end
  rescue
    0.0
  end

  def start_ultimate_gauge_drain(data)
    cooldown = [@ultimate_data && @ultimate_data[:cooldown].to_f, 1.0].compact.max
    duration = ultimate_drain_duration(data)
    if duration > 0.0
      @ultimate_charge = cooldown
      @ultimate_drain_duration = duration
      @ultimate_drain_timer = duration
    else
      @ultimate_charge = 0.0
      @ultimate_drain_duration = 0.0
      @ultimate_drain_timer = 0.0
    end
  rescue
    @ultimate_charge = 0.0
    @ultimate_drain_duration = 0.0
    @ultimate_drain_timer = 0.0
  end
  def activate_ultimate
    data = active_ultimate_data
    return if !data || !ultimate_ready?
    skill = ultimate_skill(data)
    start_ultimate_gauge_drain(data)
    @ultimate_ready_flash = 0.0
    @ultimate_prompt_timer = 0.0
    play_survivor_se(:ultimate_cast, "Survivor/Shiny sparkle", 0.18, 72, 88)
    play_survivor_se(:ultimate_cast_extra, "Survivor/Battle recall", 0.18, 54, 118)
    PokemonSurvivor.gamepad_vibrate_event(:burst) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
    if respond_to?(:queue_survivor_cry)
      queue_survivor_cry(@hero.name || @hero_base_name, 76, 100, 0.08)
    elsif respond_to?(:play_survivor_cry)
      play_survivor_cry(@hero.name || @hero_base_name, 76, 100)
    end
    apply_ultimate_support_effects(data, skill)
    case data[:kind]
    when :aurora_current
      @aurora_current_timer = data[:burst_time].to_f
      @orbit_shot_timers[:aurora_orbit] = 0.0
    when :storm_collector
      @storm_collector_timer = data[:burst_time].to_f
    when :survivor_orbit_burst
      source = skill.merge(infinite_pierce: true, keep_until_expiry: true,
        hit_interval: 0.35, vfx_loop: true)
      source[:vfx_fixed_orientation] = true if data[:vfx_fixed_orientation]
      source[:vfx_radial_orientation] = true if data[:vfx_radial_orientation]
      data[:count].to_i.times do |i|
        angle = i * Math::PI * 2.0 / data[:count]
        spawn_projectile(angle, source) do |p|
          p.orbit_target = @hero
          p.orbit_angle = angle
          p.orbit_radius = data[:radius].to_f
          p.orbit_growth = 0.0
          p.speed = 2.4
          p.radius = 20.0
          p.pierce = 1
          p.ttl = data[:burst_time].to_f
        end
      end
    when :kubfu_focus
      @kubfu_focus_timer = data[:burst_time].to_f
      @skill_cooldowns[:disciplined_strikes] = 0.0
    when :gen9_burst
      spawn_gen9_burst(skill, data)
    when :returning_blade_burst
      spawn_returning_blade_burst(skill, data)
    when :fire_twister_burst
      fire_charmander_twister(skill, data[:count].to_i)
    when :blazing_striker
      spawn_blazing_striker(skill, data)
    when :rook_tornado_burst
      spawn_rook_tornado_burst(skill, data)
    when :steel_tempest
      spawn_steel_tempest(skill, data)
    when :psychic_pursuit
      spawn_psychic_pursuit(skill, data)
    when :fairy_prison
      spawn_fairy_prisons(skill, data)
    when :toxic_bombardment
      spawn_toxic_bombardment(skill, data)
    when :radial
      spawn_ultimate_radial_projectiles(skill, data[:count].to_i)
      add_ultimate_effect(@hero.x, @hero.y, 0.34, skill, 96, :ring)
    when :water_wave
      spawn_ultimate_water_waves(skill)
    when :root_devour
      spawn_ultimate_root_devour(skill, data)
    when :thunder_ring_burst
      spawn_ultimate_thunder_ring(skill)
    when :fairy_rain
      spawn_ultimate_fairy_rain(skill)
    when :poison_rain
      spawn_ultimate_poison_rain(skill, data)
    when :ghost_rift
      spawn_ultimate_ghost_rift(skill)
    when :steel_rain
      spawn_ultimate_steel_rain(skill)
    when :psyduck_confusion
      @psyduck_confusion_timer = data[:burst_time].to_f
      @psyduck_burst_wait_timer = 0.5
    when :galar_rush
      @galar_rush_timer = data[:burst_time].to_f
      @galar_pull_timer = 0.0
      spawn_ultimate_projectile_overdrive(skill, data)
    when :psi_echoes
      @psi_echo_timer = data[:burst_time].to_f
      @psi_echo_next = 1.0
      fire_psi_volley(PokemonSurvivor::SKILLS[:psi_trail], @hero.x, @hero.y)
    when :projectile_overdrive
      spawn_ultimate_projectile_overdrive(skill, data)
    when :eevee_rush
      @eevee_burst_timer = data[:burst_time].to_f
      @item_invuln_timer = [@item_invuln_timer.to_f, @eevee_burst_timer].max
    when :poison_crown
      spawn_ultimate_poison_crown(skill)
    when :dragon_breath
      spawn_ultimate_dragon_breath(skill)
    when :magnet_crash
      spawn_ultimate_magnet_crash(skill, data)
    when :slash_dash
      spawn_ultimate_slash_dash(skill)
    when :gem_rain
      spawn_ultimate_gem_rain(skill)
    when :fighting_wave
      spawn_ultimate_fighting_wave(skill)
    when :sand_pit
      spawn_ultimate_sand_pit(skill)
    when :sonic_swarm
      spawn_ultimate_sonic_swarm(skill)
    when :aurora_floe
      spawn_ultimate_aurora_floe(skill)
    when :spider_nest
      spawn_ultimate_spider_nest(skill)
    when :bubble_tide
      spawn_ultimate_bubble_tide(skill)
    when :echo_chamber
      spawn_ultimate_echo_chamber(skill)
    when :dragon_current
      spawn_ultimate_dragon_current(skill)
    when :aura_ring_chain
      spawn_ultimate_aura_ring_chain(skill)
    when :twin_eclipse
      spawn_ultimate_twin_eclipse(skill)
    when :mew_random
      spawn_ultimate_mew_random(skill)
    when :treecko_barrage
      spawn_ultimate_treecko_barrage(skill, data)
    when :forest_dance
      @forest_dance_timer = data[:burst_time].to_f
      @forest_dance_shot_timer = 0.0
      @forest_dance_skill = PokemonSurvivor::SKILLS[:leaf_blade_sweep].merge(
        id: :ultimate_forest_dance, type: data[:type], damage: skill[:damage],
        vfx: data[:vfx], count: 5, max_count: 5, use_global_projectile_count: false)
    when :zangoose_surge
      spawn_ultimate_zangoose_surge(skill, data)
    when :target_lock_barrage
      spawn_ultimate_target_lock_barrage(skill, data)
    when :expanding_orbit_burst
      spawn_ultimate_expanding_orbit_burst(skill, data)
    when :repeating_shockwave
      spawn_ultimate_repeating_shockwave(skill, data)
    when :enemy_swing_burst
      spawn_ultimate_enemy_swing_burst(skill, data)
    when :triple_radial_burst
      spawn_ultimate_triple_radial_burst(skill, data)
    when :tyrunt_shockwave
      spawn_ultimate_tyrunt_shockwave(skill, data)
    when :drilbur_spike_burst
      spawn_ultimate_drilbur_spike_burst(skill, data)
    else
      damage_enemies_in_radius(@hero.x, @hero.y, data[:radius].to_i, skill)
      add_ultimate_effect(@hero.x, @hero.y, 0.36, skill, data[:radius].to_i, :ring)
    end
  rescue
  end

  def update_forest_dance(dt)
    return if @forest_dance_timer.to_f <= 0 || !@hero || !@forest_dance_skill
    elapsed = [dt.to_f, @forest_dance_timer].min
    @forest_dance_shot_timer -= elapsed
    while @forest_dance_shot_timer <= 0 && @forest_dance_timer > 0
      remaining = @forest_dance_timer - elapsed + @forest_dance_shot_timer
      if remaining > 0 && @effects.length + 5 <= PokemonSurvivor::MAX_EFFECTS
        source = @forest_dance_skill.merge(duration: [0.30, remaining].min)
        fire_survivor_swing(source, 5)
      end
      @forest_dance_shot_timer += 0.40
    end
    @forest_dance_timer = [@forest_dance_timer - elapsed, 0.0].max
    @forest_dance_skill = nil if @forest_dance_timer <= 0
  end

  def spawn_ultimate_treecko_barrage(skill, data)
    @treecko_barrage_timer = [@treecko_barrage_timer.to_f, data[:barrage_time].to_f].max
    @treecko_barrage_interval = [data[:shot_interval].to_f, 0.04].max
    @treecko_barrage_shot_timer = 0.0
    @treecko_barrage_angle = 0.0
    @treecko_barrage_skill = {
      barrage_directions: data[:barrage_directions] || 4,
      id: data[:id] == :ultimate_typhlosion_hisui ? :typhlosion_hisui_barrage_shot : :treecko_barrage_shot,
      kind: :projectile,
      type: data[:type] || :GRASS,
      dual_types: data[:dual_types],
      life_steal: data[:life_steal],
      damage: data[:damage].to_i,
      speed: data[:speed].to_f,
      pierce: data[:pierce].to_i,
      knockback: data[:knockback],
      infinite_pierce: data[:infinite_pierce],
      vfx_scale: data[:vfx_scale],
      vfx: data[:vfx] || "VFX_GRASS2"
    }
    add_ultimate_effect(@hero.x, @hero.y, 0.36, { type: data[:type] || :GRASS, vfx: data[:vfx] || "VFX_GRASS2", vfx_loop: false, vfx_fps: 18 }, data[:radius].to_i, :ring) if respond_to?(:add_ultimate_effect)
  rescue
  end

  def spawn_ultimate_zangoose_surge(skill, data)
    @zangoose_surge_timer = [@zangoose_surge_timer.to_f, data[:surge_time].to_f].max
    @zangoose_surge_radius_mult = [data[:radius_mult].to_f, 1.0].max
    @zangoose_surge_spin_mult = [data[:spin_mult].to_f, 1.0].max
    @zangoose_surge_power_mult = [data[:power_mult].to_f, 1.0].max
    add_ultimate_effect(@hero.x, @hero.y, 0.34, { type: :NORMAL, vfx: "VFX_NORMAL", vfx_loop: false, vfx_fps: 18 }, data[:radius].to_i, :ring) if respond_to?(:add_ultimate_effect)
  rescue
  end

  def update_treecko_barrage_timer(dt)
    return if @treecko_barrage_timer.to_f <= 0 || !@hero
    @treecko_barrage_timer = [@treecko_barrage_timer.to_f - dt.to_f, 0.0].max
    @treecko_barrage_shot_timer = @treecko_barrage_shot_timer.to_f - dt.to_f
    while @treecko_barrage_shot_timer.to_f <= 0 && @treecko_barrage_timer.to_f > 0
      spawn_treecko_barrage_four_way
      @treecko_barrage_shot_timer += [@treecko_barrage_interval.to_f, 0.04].max
    end
  rescue
  end

  def spawn_treecko_barrage_four_way
    skill = @treecko_barrage_skill || { id: :treecko_barrage_shot, kind: :projectile, type: :GRASS, damage: 12, speed: 8.2, pierce: 3, vfx: "VFX_GRASS2" }
    @treecko_barrage_angle = (@treecko_barrage_angle.to_f + 0.42) % (Math::PI * 2.0)
    base = @treecko_barrage_angle.to_f
    directions = [skill.fetch(:barrage_directions, 4).to_i, 1].max
    directions.times do |index|
      angle = base + index * Math::PI * 2.0 / directions
      spawn_projectile_from(@hero.x, @hero.y, angle, skill) do |p|
        p.ttl = 1.45
        scale = skill[:vfx_scale] || 1.0
        p.radius = (PokemonSurvivor::PROJECTILE_RADIUS + 1) * scale
        p.vfx_scale = scale
      end
    end
    play_survivor_se(:shot, "Survivor/Battle throw", 0.045, PokemonSurvivor::SFX_SHOT_VOLUME, 124) if respond_to?(:play_survivor_se)
  rescue
  end


  def spawn_ultimate_drilbur_spike_burst(skill, data)
    @drilbur_spike_burst_timer = [@drilbur_spike_burst_timer.to_f, data[:burst_time].to_f].max
    @drilbur_spike_burst_interval = [data[:interval].to_f, 0.06].max
    @drilbur_spike_burst_shot_timer = 0.0
    @drilbur_spike_burst_skill = skill.merge({ id: :ultimate_drilbur_spike, kind: :projectile, vfx: data[:vfx] || "VFX_STEEL4", radius: 13 })
    add_ultimate_effect(@hero.x, @hero.y, 0.34, { type: :STEEL, vfx: data[:vfx] || "VFX_STEEL4", vfx_loop: false, vfx_fps: 22 }, data[:radius].to_i, :ring) if respond_to?(:add_ultimate_effect)
  rescue
  end

  def update_drilbur_spike_burst(dt)
    return if @drilbur_spike_burst_timer.to_f <= 0 || !@hero
    @drilbur_spike_burst_timer = [@drilbur_spike_burst_timer.to_f - dt.to_f, 0.0].max
    @drilbur_spike_burst_shot_timer = @drilbur_spike_burst_shot_timer.to_f - dt.to_f
    while @drilbur_spike_burst_shot_timer.to_f <= 0 && @drilbur_spike_burst_timer.to_f > 0
      skill = @drilbur_spike_burst_skill || { id: :ultimate_drilbur_spike, kind: :projectile, type: :STEEL, damage: 18, speed: 7.6, pierce: 4, vfx: "VFX_STEEL4", radius: 13, count: 8 }
      count = [[skill[:count].to_i, 4].max, 12].min
      step = (Math::PI * 2.0) / count.to_f
      base_angle = survivor_swing_facing_angle
      angles = Array.new(count) { |i| base_angle + (step * i) }
      angles.each do |angle|
        spawn_projectile_from(@hero.x, @hero.y, angle, skill) do |p|
          p.ttl = 1.15
          p.radius = skill[:radius].to_i > 0 ? skill[:radius].to_i : 13
        end
      end
      @drilbur_spike_burst_shot_timer += [@drilbur_spike_burst_interval.to_f, 0.06].max
    end
  rescue
    @drilbur_spike_burst_timer = 0.0
  end
  def spawn_ultimate_target_lock_barrage(skill, data)
    @target_lock_barrages ||= []
    targets = visible_enemy_targets_from(@hero.x, @hero.y, 9999, [[data[:target_count].to_i, 1].max, 6].min)
    return if targets.empty?
    @target_lock_barrages << { timer: data[:barrage_time].to_f, interval: [data[:shot_interval].to_f, 0.05].max, shot_timer: 0.0, targets: targets, skill: skill.merge({ vfx: data[:vfx] || skill[:vfx] }) }
  rescue
  end

  def update_target_lock_barrages(dt)
    return if !@target_lock_barrages || @target_lock_barrages.empty?
    @target_lock_barrages.each do |burst|
      burst[:timer] = burst[:timer].to_f - dt.to_f
      burst[:shot_timer] = burst[:shot_timer].to_f - dt.to_f
      burst[:targets] = (burst[:targets] || []).select { |e| e && e.hp.to_i > 0 }
      next if burst[:targets].empty?
      while burst[:shot_timer].to_f <= 0 && burst[:timer].to_f > 0
        burst[:targets].each do |target|
          angle = Math.atan2(target.y.to_f - @hero.y.to_f, target.x.to_f - @hero.x.to_f)
          spawn_projectile_from(@hero.x, @hero.y, angle, burst[:skill]) { |p| p.ttl = 1.25; p.homing = false }
        end
        burst[:shot_timer] += burst[:interval].to_f
      end
    end
    @target_lock_barrages.delete_if { |burst| burst[:timer].to_f <= 0 || (burst[:targets] || []).empty? }
  rescue
    @target_lock_barrages = []
  end

  def spawn_ultimate_expanding_orbit_burst(skill, data)
    @goodra_steel_rings ||= []
    count = [[data[:count].to_i, 1].max, 12].min
    count.times do |i|
      @goodra_steel_rings << { angle: Math::PI * 2.0 * i / count, radius: 28.0, timer: data[:burst_time].to_f, hit: {}, skill: skill, spin_speed: data[:spin_speed].to_f, expand_speed: data[:expand_speed].to_f, hit_radius: data[:radius].to_i }
    end
  rescue
  end

  def update_goodra_steel_rings(dt)
    return if !@goodra_steel_rings || @goodra_steel_rings.empty? || !@hero
    @goodra_steel_rings.each do |orb|
      orb[:timer] = orb[:timer].to_f - dt.to_f
      orb[:angle] = orb[:angle].to_f + orb[:spin_speed].to_f * dt.to_f
      orb[:radius] = orb[:radius].to_f + orb[:expand_speed].to_f * dt.to_f
      x = @hero.x.to_f + Math.cos(orb[:angle]) * orb[:radius]
      y = @hero.y.to_f + Math.sin(orb[:angle]) * orb[:radius]
      add_ultimate_effect(x, y, 0.10, orb[:skill], orb[:hit_radius].to_i, :ring) if @effects && @effects.length < PokemonSurvivor::MAX_EFFECTS
      each_nearby_enemy_for(x, y, orb[:hit_radius].to_i + PokemonSurvivor::BOSS_RADIUS + 8) do |enemy|
        next if !enemy || enemy.hp.to_i <= 0
        oid = enemy.object_id
        next if orb[:hit][oid].to_f > 0
        dx = enemy.x.to_f - x
        dy = enemy.y.to_f - y
        limit = orb[:hit_radius].to_i + enemy.radius.to_i
        next if (dx * dx + dy * dy) > limit * limit
        orb[:hit][oid] = 0.22
        damage_enemy(enemy, orb[:skill][:damage].to_i, :STEEL, skill_color(orb[:skill]), orb[:skill])
        apply_survivor_swing_knockback(enemy, orb[:skill], x, y) if respond_to?(:apply_survivor_swing_knockback)
      end
      orb[:hit].keys.each { |key| orb[:hit][key] = orb[:hit][key].to_f - dt.to_f; orb[:hit].delete(key) if orb[:hit][key].to_f <= 0 }
    end
    @goodra_steel_rings.delete_if { |orb| orb[:timer].to_f <= 0 }
  rescue
    @goodra_steel_rings = []
  end

  def spawn_ultimate_repeating_shockwave(skill, data)
    @repeating_shockwave_bursts ||= []
    @repeating_shockwave_bursts << { timer: data[:burst_time].to_f, interval: [data[:interval].to_f, 0.35].max, shot_timer: 0.0, data: data, skill: skill }
  rescue
  end

  def update_repeating_shockwaves(dt)
    return if !@repeating_shockwave_bursts || @repeating_shockwave_bursts.empty?
    @repeating_shockwave_bursts.each do |burst|
      burst[:timer] = burst[:timer].to_f - dt.to_f
      burst[:shot_timer] = burst[:shot_timer].to_f - dt.to_f
      while burst[:shot_timer].to_f <= 0 && burst[:timer].to_f > 0
        spawn_ultimate_tyrunt_shockwave(burst[:skill], burst[:data].merge({ count: 1, repeat: 1, targeted: false }))
        burst[:shot_timer] += burst[:interval].to_f
      end
    end
    @repeating_shockwave_bursts.delete_if { |burst| burst[:timer].to_f <= 0 }
  rescue
    @repeating_shockwave_bursts = []
  end

  def spawn_ultimate_enemy_swing_burst(skill, data)
    @enemy_swing_bursts ||= []
    targets = visible_enemy_targets_from(@hero.x, @hero.y, 9999, [[data[:target_count].to_i, 1].max, 10].min)
    centers = targets.map { |e| [e.x.to_f, e.y.to_f] }
    fallback_ring_points([[data[:target_count].to_i - centers.length, 0].max, 8].min, 120).each { |p| centers << [p[0].to_f, p[1].to_f] } if centers.length < data[:target_count].to_i
    @enemy_swing_bursts << { timer: data[:burst_time].to_f, interval: [data[:interval].to_f, 0.25].max, shot_timer: 0.0, centers: centers.first(data[:target_count].to_i), skill: skill.merge({ kind: :survivor_swing, vfx: data[:vfx] || "VFX_STEEL3", duration: 0.32, spin_speed: 0.0, centered_visual: true, visual_scale: 1.35, visual_radius_base: 48 }) }
  rescue
  end

  def update_enemy_swing_bursts(dt)
    return if !@enemy_swing_bursts || @enemy_swing_bursts.empty?
    @enemy_swing_bursts.each do |burst|
      burst[:timer] = burst[:timer].to_f - dt.to_f
      burst[:shot_timer] = burst[:shot_timer].to_f - dt.to_f
      while burst[:shot_timer].to_f <= 0 && burst[:timer].to_f > 0
        (burst[:centers] || []).each { |center| spawn_fixed_survivor_swing(center[0], center[1], burst[:skill], burst[:skill][:radius].to_i) }
        burst[:shot_timer] += burst[:interval].to_f
      end
    end
    @enemy_swing_bursts.delete_if { |burst| burst[:timer].to_f <= 0 }
  rescue
    @enemy_swing_bursts = []
  end

  def spawn_fixed_survivor_swing(x, y, skill, radius)
    return if !@effects || @effects.length >= PokemonSurvivor::MAX_EFFECTS
    source = skill.clone
    source[:id] ||= skill[:id] || :ultimate_fixed_swing
    duration = [source[:duration].to_f, 0.18].max
    meta = { survivor_swing: true, fixed_world: true, angle: 0.0, hit: {}, radius: radius.to_i, arc: Math::PI * 2.0, spin_speed: 0.0, visual_offset: 0.0, visual_angle: 0.0, centered_visual: true, visual_scale: source[:visual_scale] || 1.35, visual_radius_base: source[:visual_radius_base] || 48.0, hit_radius_mult: 0.58, radial_hit: true }
    @effects << [x.to_f, y.to_f, duration, skill_color(source), radius.to_i, :survivor_swing, source, 0.0, 0.0, meta]
  rescue
  end

  def spawn_ultimate_triple_radial_burst(skill, data)
    count = [[data[:count].to_i, 6].max, 30].min
    3.times do |cycle|
      offset = cycle * (Math::PI / 7.0)
      count.times do |i|
        angle = offset + (Math::PI * 2.0 * i / count)
        spawn_projectile(angle, skill) { |p| p.ttl = 1.65 }
      end
    end
    add_ultimate_effect(@hero.x, @hero.y, 0.42, skill, data[:radius].to_i, :ring)
  rescue
  end
  def spawn_ultimate_tyrunt_shockwave(skill, data)
    @tyrunt_shockwaves ||= []
    max_radius = [[data[:radius].to_i, 72].max, data[:targeted] ? 148 : 188].min
    waves = [[data[:count].to_i, 1].max, 4].min
    default_vfx = data[:targeted] ? "VFX_GROUND3" : "VFX_GROUND2"
    wave_skill = skill.merge({ vfx: data[:vfx] || default_vfx, vfx_fps: data[:vfx_fps] || 24, vfx_loop: false })
    centers = []
    if data[:targeted]
      range = [data[:target_range].to_i, 260].max
      centers = visible_enemy_targets_from(@hero.x, @hero.y, range, waves).map { |target| [target.x.to_f, target.y.to_f] }
      if centers.length < waves
        fallback_ring_points(waves - centers.length, 96).each { |point| centers << [point[0].to_f, point[1].to_f] }
      end
    else
      waves.times { centers << [@hero.x.to_f, @hero.y.to_f] }
    end
    repeats = data[:targeted] ? [[data[:repeat].to_i, 1].max, 3].min : 1
    repeat_delay = data[:repeat_delay] ? data[:repeat_delay].to_f : 0.82
    repeats.times do |cycle|
      cycle_centers = centers
      if data[:targeted] && cycle > 0
        cycle_centers = visible_enemy_targets_from(@hero.x, @hero.y, [data[:target_range].to_i, 260].max, waves).map { |target| [target.x.to_f, target.y.to_f] }
        if cycle_centers.length < waves
          fallback_ring_points(waves - cycle_centers.length, 96).each { |point| cycle_centers << [point[0].to_f, point[1].to_f] }
        end
      end
      cycle_centers.first(waves).each_with_index do |center, i|
        @tyrunt_shockwaves << {
          delay: (cycle * repeat_delay) + (data[:targeted] ? i * 0.08 : i * 0.18),
          age: 0.0,
          duration: data[:targeted] ? 0.54 : 0.62,
          x: center[0].to_f,
          y: center[1].to_f,
          max_radius: max_radius,
          last_radius: 0.0,
          hit: {},
          skill: wave_skill,
          fx: nil
        }
      end
    end
    add_ultimate_effect(@hero.x, @hero.y, 0.32, wave_skill, 72, :ring) if !data[:targeted] && respond_to?(:add_ultimate_effect)
  rescue
  end

  def update_tyrunt_shockwaves(dt)
    return if !@tyrunt_shockwaves || @tyrunt_shockwaves.empty?
    @tyrunt_shockwaves.each do |wave|
      wave[:delay] = wave[:delay].to_f - dt.to_f
      next if wave[:delay] > 0
      wave[:age] = wave[:age].to_f + dt.to_f
      skill = wave[:skill]
      if !wave[:fx] && @effects && @effects.length < PokemonSurvivor::MAX_EFFECTS
        wave[:fx] = [wave[:x], wave[:y], wave[:duration].to_f, skill_color(skill), 8, :ground_zone, skill, 0.0, 0.0, { tyrunt_shockwave: true }]
        @effects << wave[:fx]
      end
      progress = [[wave[:age].to_f / [wave[:duration].to_f, 0.1].max, 0.0].max, 1.0].min
      radius = wave[:max_radius].to_f * Math.sin(progress * Math::PI / 2.0)
      wave[:fx][4] = radius.round if wave[:fx]
      search = radius + PokemonSurvivor::BOSS_RADIUS + 10
      each_nearby_enemy_for(wave[:x], wave[:y], search) do |enemy|
        next if !enemy || enemy.hp.to_i <= 0 || wave[:hit][enemy.object_id]
        dx = enemy.x.to_f - wave[:x].to_f
        dy = enemy.y.to_f - wave[:y].to_f
        limit = radius + enemy.radius.to_i
        next if (dx * dx + dy * dy) > limit * limit
        wave[:hit][enemy.object_id] = true
        damage_enemy(enemy, skill[:damage].to_i, skill[:type] || :GROUND, skill_color(skill), skill)
        defeat_enemy(enemy) if enemy.hp.to_i <= 0 && !enemy.instance_variable_get(:@defeated)
      end
      wave[:last_radius] = radius
    end
    @tyrunt_shockwaves.delete_if { |wave| wave[:delay].to_f <= 0 && wave[:age].to_f >= wave[:duration].to_f }
  rescue
    @tyrunt_shockwaves = []
  end
  def spawn_returning_blade_burst(skill, data)
    source = PokemonSurvivor::SKILLS[:living_blade].merge(skill)
    source.merge!(kind: :returning_swing, vfx: data[:vfx], knockback: nil, knock_limit: nil)
    @returning_blade_burst = { remaining: data[:burst_time].to_f, shot_timer: data[:interval].to_f,
                              interval: data[:interval].to_f, count: data[:count].to_i, skill: source }
    fire_returning_swing(source, data[:count].to_i)
  end

  def update_returning_blade_burst(dt)
    burst = @returning_blade_burst
    return if !burst
    burst[:remaining] -= dt
    burst[:shot_timer] -= dt
    if burst[:shot_timer] <= 0 && burst[:remaining] >= burst[:skill][:duration]
      fire_returning_swing(burst[:skill], burst[:count])
      burst[:shot_timer] += burst[:interval]
    end
    @returning_blade_burst = nil if burst[:remaining] <= 0
  end

  def spawn_gen9_burst(skill, data)
    form = PokemonSurvivor.species_key(@hero.name)
    @gen9_burst = { form: form, base: @passive_key, remaining: data[:burst_time].to_f,
                   shot_timer: 0.0, skill: skill }
    if form == :CERULEDGE
      @ceruledge_burst_timer = data[:burst_time].to_f
    elsif @passive_key == :TINKATINK
      spawn_fairy_prisons(skill.merge(speed: 0.0, pierce: 1, vfx: "VFX_FAIRY4"),
        data.merge(radius: 38, sphere_count: 4, orbit_radius: 105.0, follow_player: true, frame_ticks: true))
    elsif @passive_key == :FUECOCO
      @gen9_burst[:orbs] = []
      @gen9_burst[:orb_source] = { id: :ultimate_cinder_chorus, kind: :projectile, type: :FIRE,
        damage: 28, speed: 6.5, pierce: 1, homing: true, vfx: "VFX_FIRE10",
        vfx_frames: 5, vfx_loop: true, impact_blast: true, impact_radius: 32,
        impact_damage: 20, burn_time: 3.0, cinder_chorus: true }
      refill_cinder_chorus(@gen9_burst)
    end
  end

  def update_gen9_burst(dt)
    @ceruledge_burst_timer = [@ceruledge_burst_timer.to_f - dt, 0.0].max
    burst = @gen9_burst
    return unless burst
    burst[:remaining] -= dt
    if burst[:form] == :ARMAROUGE && burst[:remaining] > 0
      burst[:shot_timer] -= dt
      while burst[:shot_timer] <= 0
        fire_projectile(PokemonSurvivor::SKILLS[:psychic_well].merge(id: :ultimate_armarouge))
        burst[:shot_timer] += 0.4
      end
    end
    if burst[:orbs] && burst[:remaining] > 0
      refill_cinder_chorus(burst)
      burst[:orbs].each do |p|
        next unless p.orbit_target
        target = cinder_chorus_target(p, 180)
        next unless target
        p.orbit_target = nil
        p.speed = 6.5
        p.homing_target = target
        angle = Math.atan2(target.y - p.y, target.x - p.x)
        p.vx, p.vy = Math.cos(angle), Math.sin(angle)
      end
    end
    return if burst[:remaining] > 0
    (burst[:orbs] || []).each { |p| p.ttl = 0.0; p.pierce = 0 }
    if burst[:base] == :TINKATINK
      source = { id: :ultimate_fairy_forge_wave, type: :GROUND, damage: 60, knockback: 65, vfx: "VFX_GROUND2" }
      spawn_ultimate_tyrunt_shockwave(source, { radius: 180, count: 1, vfx: "VFX_GROUND2" })
    end
    @gen9_burst = nil
  end

  def refill_cinder_chorus(burst)
    return if burst[:remaining] <= 0 || !@hero
    burst[:orbs].delete_if { |p| p.ttl <= 0 || p.pierce <= 0 || !@projectiles.include?(p) }
    occupied = burst[:orbs].map { |p| p.instance_variable_get(:@cinder_slot) }
    8.times do |slot|
      next if occupied.include?(slot)
      angle = slot * Math::PI / 4.0 + @timer.to_f * 2.1
      x = @hero.x + Math.cos(angle) * 80.0
      y = @hero.y + Math.sin(angle) * 80.0
      spawn_projectile_from(x, y, angle, burst[:orb_source]) do |p|
        p.orbit_target = @hero
        p.orbit_angle = angle
        p.orbit_radius = 80.0
        p.orbit_growth = 0.0
        p.homing_target = nil
        p.speed = 2.1
        p.pierce = 1
        p.ttl = burst[:remaining]
        p.instance_variable_set(:@cinder_slot, slot)
        burst[:orbs] << p
      end
    end
  end

  def cinder_chorus_target(projectile, range)
    burst = @gen9_burst
    return nil if !burst || !burst[:orbs] || burst[:remaining] <= 0
    reserved = {}
    burst[:orbs].each do |other|
      next if other.equal?(projectile) || other.ttl <= 0 || other.pierce <= 0 || other.orbit_target
      target = other.homing_target
      reserved[target.object_id] = true if target && target.hp > 0
    end
    best = nil
    distance = range * range
    each_nearby_enemy_for(projectile.x, projectile.y, range) do |enemy|
      next if !enemy || enemy.hp <= 0 || reserved[enemy.object_id] || !enemy_visible?(enemy)
      d = point_distance_sq(projectile.x, projectile.y, enemy.x, enemy.y)
      next if d > distance
      best, distance = enemy, d
    end
    best
  end

  def update_treecko_zangoose_burst_timers(dt)
    update_forest_dance(dt)
    @aurora_current_timer = [@aurora_current_timer.to_f - dt, 0.0].max
    @storm_collector_timer = [@storm_collector_timer.to_f - dt, 0.0].max
    update_gen9_burst(dt)
    update_galar_rush(dt)
    update_psi_echoes(dt)
    @eevee_burst_timer = [@eevee_burst_timer.to_f - dt, 0.0].max if @eevee_burst_timer.to_f > 0
    update_returning_blade_burst(dt)
    update_treecko_barrage_timer(dt)
    update_bulbasaur_poison_rain(dt)
    update_tyrunt_shockwaves(dt)
    update_target_lock_barrages(dt)
    update_goodra_steel_rings(dt)
    update_repeating_shockwaves(dt)
    update_enemy_swing_bursts(dt)
    update_drilbur_spike_burst(dt)
    @zangoose_surge_timer = [@zangoose_surge_timer.to_f - dt.to_f, 0.0].max if @zangoose_surge_timer.to_f > 0
  rescue
  end
  def update_psi_echoes(dt)
    return if @psi_echo_timer.to_f <= 0
    elapsed = [dt, @psi_echo_timer].min
    @psi_echo_timer -= elapsed
    @psi_echo_next -= elapsed
    while @psi_echo_next <= 0 && @psi_echo_timer - @psi_echo_next > 0.0001
      fire_psi_volley(PokemonSurvivor::SKILLS[:psi_trail], @hero.x, @hero.y)
      @psi_echo_next += 1.0
    end
  end

  def update_galar_rush(dt)
    return if @galar_rush_timer.to_f <= 0
    @galar_rush_timer = [@galar_rush_timer - dt, 0.0].max
    @galar_pull_timer = @galar_pull_timer.to_f + dt
    return if @galar_pull_timer < 0.08 || @galar_rush_timer <= 0
    elapsed = [@galar_pull_timer, 0.16].min
    @galar_pull_timer = 0.0
    centers = []
    (@effects || []).each do |fx|
      next unless fx[2].to_f > 0 && fx[6] && skill_id_for(fx[6]) == :night_raid && fx[9].is_a?(Hash)
      meta = fx[9]
      centers << [@hero.x + Math.cos(meta[:angle]) * meta[:visual_offset],
                  @hero.y + Math.sin(meta[:angle]) * meta[:visual_offset], fx]
    end
    return if centers.empty?
    reach = centers.map { |x, y| Math.sqrt(point_distance_sq(x, y, @hero.x, @hero.y)) }.max + 180.0
    moved = false
    each_nearby_enemy_for(@hero.x, @hero.y, reach) do |enemy|
      next if enemy.hp <= 0 || enemy.kind == :tower_wisp
      center = nil
      best = 180.0 ** 2
      centers.each do |xy|
        next unless attraction_source_available?(enemy, xy[2])
        distance = point_distance_sq(enemy.x, enemy.y, xy[0], xy[1])
        center, best = xy, distance if distance < best
      end
      next if !center || best <= 1.0
      next unless claim_enemy_attraction(enemy, center[2])
      distance = Math.sqrt(best)
      resistance = [:boss, :ultra_boss, :chest, :ultra_chest].include?(enemy.kind) ? 0.25 : 1.0
      step = [220.0 * elapsed * resistance, distance].min
      x = enemy.x + (center[0] - enemy.x) / distance * step
      y = enemy.y + (center[1] - enemy.y) / distance * step
      x, y = clamp_world_spawn_position(x, y, enemy.radius) if respond_to?(:clamp_world_spawn_position)
      enemy.x, enemy.y = x, y
      moved = true
    end
    invalidate_enemy_grid if moved
  end

  def apply_ultimate_support_effects(data, skill)
    if !@breach_run && @hero && @passive_key == :RIOLU
      @hero.hp = [@hero.hp.to_i + (@hero.max_hp.to_f * 0.05).ceil, @hero.max_hp.to_i].min
      trigger_gauge_flash
    elsif !@breach_run && @hero && @passive_key == :CROAGUNK
      @hero.hp = [@hero.hp.to_i + (@hero.max_hp.to_f * 0.01).ceil, @hero.max_hp.to_i].min
      trigger_gauge_flash
    end
    if !@breach_run && data[:heal].to_f > 0 && @hero
      @hero.hp = [@hero.hp.to_i + (@hero.max_hp.to_i * data[:heal].to_f).ceil, @hero.max_hp.to_i].min
      trigger_gauge_flash
    end
    @item_invuln_timer = [@item_invuln_timer.to_f, data[:shield].to_f].max if data[:shield].to_f > 0
    @force_magnet_timer = [@force_magnet_timer.to_f, data[:magnet_time].to_f].max if data[:magnet_time].to_f > 0
    if data[:power_time].to_f > 0
      @passive_hit_power_timer = [@passive_hit_power_timer.to_f, data[:power_time].to_f].max
      @passive_hit_power_mult = [@passive_hit_power_mult.to_f, data[:power_mult].to_f].max if data[:power_mult].to_f > 0
    end
    clear_enemy_projectiles_near_hero(data[:radius].to_i + 40) if data[:clear_shots]
  rescue
  end

  def spawn_ultimate_radial_projectiles(skill, count)
    count = [[count.to_i, 6].max, 64].min
    step = Math::PI * 2.0 / count.to_f
    offset = (System.uptime rescue 0.0).to_f % step
    count.times do |i|
      angle = offset + (step * i)
      spawn_projectile_from(@hero.x, @hero.y, angle, skill) do |p|
        p.ttl = 2.8
        p.radius = PokemonSurvivor::PROJECTILE_RADIUS + 2
      end
    end
  rescue
  end


  def spawn_ultimate_projectile_overdrive(skill, data)
    @projectile_overdrive_timer = [@projectile_overdrive_timer.to_f, data[:haste_time].to_f].max
    @projectile_overdrive_mult = data[:haste_mult].to_f > 0 ? data[:haste_mult].to_f : 0.2
    add_ultimate_effect(@hero.x, @hero.y, 0.72, skill, data[:radius].to_i, :ring)
    clear_enemy_projectiles_near_hero(data[:radius].to_i + 30)
  rescue
  end

  def spawn_ultimate_larvitar_shell(skill, data)
    @larvitar_haste_timer = [@larvitar_haste_timer.to_f, data[:haste_time].to_f].max
    @item_invuln_timer = [@item_invuln_timer.to_f, data[:shield].to_f].max
    add_ultimate_effect(@hero.x, @hero.y, 0.72, skill, data[:radius].to_i, :ring)
    repel_nearby_threats(data[:radius].to_i, 10.0, true)
  rescue
  end

  def spawn_ultimate_root_devour(skill, data)
    radius = [data[:radius].to_i, 120].max
    base_damage = data[:damage].to_i
    total = 0
    build_enemy_grid
    nearby_enemies_for(@hero.x, @hero.y, radius + PokemonSurvivor::BOSS_RADIUS + 8).each do |enemy|
      next if !enemy || enemy.hp.to_i <= 0
      next if point_distance_sq(@hero.x, @hero.y, enemy.x, enemy.y) > (radius + enemy.radius) * (radius + enemy.radius)
      before = enemy.hp.to_i
      damage_enemy(enemy, base_damage, data[:type] || :GRASS, skill_color(skill), skill)
      total += [before - [enemy.hp.to_i, 0].max, 0].max
    end
    heal = (total * data[:heal_from_damage].to_f).round
    @hero.hp = [@hero.hp.to_i + heal, @hero.max_hp.to_i].min if heal > 0 && !@breach_run
    add_ultimate_effect(@hero.x, @hero.y, 0.62, skill.merge({ vfx: data[:vfx] || "VFX_GRASS" }), radius, :zone)
  rescue
  end
  def spawn_ultimate_water_waves(skill)
    count = [[skill[:count].to_i, 3].max, 9].min
    base = hero_facing_angle
    spread = 0.34
    count.times do |i|
      offset = (i - ((count - 1) / 2.0)) * spread
      spawn_projectile_from(@hero.x, @hero.y, base + offset, skill) do |p|
        p.ttl = 3.1
        p.radius = PokemonSurvivor::PROJECTILE_RADIUS + 7
        p.pierce = [skill[:pierce].to_i, 8].max
      end
    end
    add_ultimate_effect(@hero.x, @hero.y, 0.32, skill, 96, :ring)
  rescue
  end

  def spawn_ultimate_thunder_ring(skill)
    radius = [skill[:radius].to_i, 80].max
    damage_enemies_in_radius(@hero.x, @hero.y, radius, skill)
    add_ultimate_effect(@hero.x, @hero.y, 0.34, skill, radius, :ring)
    spawn_ultimate_radial_projectiles(skill, skill[:count].to_i)
  rescue
  end


  def spawn_ultimate_poison_rain(skill, data)
    @bulbasaur_poison_rain_timer = [@bulbasaur_poison_rain_timer.to_f, data[:rain_time].to_f].max
    @bulbasaur_poison_rain_interval = [data[:interval].to_f, 0.06].max
    @bulbasaur_poison_rain_shot_timer = 0.0
    @bulbasaur_poison_rain_skill = skill.merge({
      vfx: data[:vfx] || "VFX_POISON2",
      vfx_fps: data[:vfx_fps] || 24,
      vfx_loop: !!data[:vfx_loop],
      impact_damage_mult: data[:impact_damage_mult] || 0.45
    })
  rescue
  end

  def update_bulbasaur_poison_rain(dt)
    update_bulbasaur_poison_rain_spawner(dt)
    update_bulbasaur_poison_rain_drops
  rescue
    @bulbasaur_poison_rain_timer = 0.0
  end

  def update_bulbasaur_poison_rain_spawner(dt)
    return if @bulbasaur_poison_rain_timer.to_f <= 0 || !@bulbasaur_poison_rain_skill || !@hero
    @bulbasaur_poison_rain_timer = [@bulbasaur_poison_rain_timer.to_f - dt.to_f, 0.0].max
    @bulbasaur_poison_rain_shot_timer = @bulbasaur_poison_rain_shot_timer.to_f - dt.to_f
    while @bulbasaur_poison_rain_shot_timer.to_f <= 0 && @bulbasaur_poison_rain_timer.to_f > 0
      active = bulbasaur_poison_rain_active_count
      drops = [[8 - active, 0].max, 8].min
      drops.times { spawn_bulbasaur_poison_rain_drop(@bulbasaur_poison_rain_skill) }
      @bulbasaur_poison_rain_shot_timer += [@bulbasaur_poison_rain_interval.to_f, 0.36].max
      break if drops <= 0
    end
    @bulbasaur_poison_rain_skill = nil if @bulbasaur_poison_rain_timer.to_f <= 0
  rescue
  end

  def bulbasaur_poison_rain_active_count
    return 0 if !@effects
    @effects.count do |fx|
      meta = fx[9] rescue nil
      meta.is_a?(Hash) && meta[:poison_rain_drop]
    end
  rescue
    0
  end

  def spawn_bulbasaur_poison_rain_drop(skill)
    return if !@effects
    if @effects.length >= PokemonSurvivor::MAX_EFFECTS
      drop_index = @effects.index { |fx| fx && (fx[5] == :hit || fx[5] == :spark || fx[5] == :trail) }
      @effects.delete_at(drop_index) if drop_index
    end
    return if @effects.length >= PokemonSurvivor::MAX_EFFECTS
    targets = visible_enemy_targets_from(@hero.x, @hero.y, 9999, 10)
    target = targets.empty? ? nil : targets.sample
    return if skill[:rain_direct] && !target
    if target
      tx = target.x.to_f
      ty = target.y.to_f
    else
      angle = rand * Math::PI * 2.0
      dist = 64 + rand(120)
      tx = @hero.x.to_f + Math.cos(angle) * dist
      ty = @hero.y.to_f + Math.sin(angle) * dist
    end
    fall_time = 0.58
    impact_time = 0.38
    start_y = ty - 210.0
    meta = { poison_rain_drop: true, fixed_world: true, target_x: tx, start_y: start_y, target_y: ty, fall_time: fall_time, impact_time: impact_time, damaged: false }
    meta[:direct_target] = target if skill[:rain_direct]
    @effects << [tx, start_y, fall_time + impact_time, skill_color(skill), skill[:radius].to_i, :poison_rain_drop, skill, nil, 0.0, meta]
  rescue
  end

  def update_bulbasaur_poison_rain_drops
    return if !@effects
    @effects.each do |fx|
      meta = fx[9] rescue nil
      next if !meta.is_a?(Hash) || !meta[:poison_rain_drop]
      skill = fx[6]
      age = fx[8].to_f
      fall_time = [meta[:fall_time].to_f, 0.05].max
      if skill[:rain_direct]
        target = meta[:direct_target]
        if !target || target.hp.to_f <= 0
          fx[2] = 0.0
          next
        end
        meta[:target_x] = target.x.to_f
        meta[:target_y] = target.y.to_f
        meta[:start_y] = target.y.to_f - 210.0
      end
      if age < fall_time
        t = [[age / fall_time, 0.0].max, 1.0].min
        fx[0] = meta[:target_x].to_f if meta[:target_x]
        fx[1] = meta[:start_y].to_f + ((meta[:target_y].to_f - meta[:start_y].to_f) * t)
      else
        fx[0] = meta[:target_x].to_f if meta[:target_x]
        fx[1] = meta[:target_y].to_f
        next if meta[:damaged]
        meta[:damaged] = true
        if skill[:impact_rain]
          damage_enemies_in_radius(fx[0], fx[1], fx[4], skill)
          spawn_impact_flurry_at(fx[0], fx[1], skill)
          fx[2] = 0.0
          next
        end
        if skill[:rain_direct]
          target = meta[:direct_target]
          before = target.hp.to_f
          damage_enemy(target, skill[:damage], skill[:type], skill_color(skill), skill)
          dealt = [[before - target.hp.to_f, 0.0].max, before].min
          if skill[:heal_from_damage].to_f > 0 && !(respond_to?(:breach_mode?) && breach_mode?)
            heal = (dealt * skill[:heal_from_damage].to_f).floor
            @hero.hp = [@hero.hp + heal, @hero.max_hp].min if @hero.hp > 0
          end
          fx[2] = 0.0
          next
        end
        damage_enemies_in_radius((meta[:target_x] || fx[0]).to_f, meta[:target_y].to_f, fx[4].to_i, skill)
        splash = skill.clone
        splash[:damage] = [(skill[:damage].to_i * skill[:impact_damage_mult].to_f).ceil, 1].max
        damage_enemies_in_radius((meta[:target_x] || fx[0]).to_f, meta[:target_y].to_f, (fx[4].to_i * 0.72).round, splash)
      end
    end
  rescue
  end
  def spawn_ultimate_fairy_rain(skill)
    targets = visible_enemy_targets_from(@hero.x, @hero.y, 9999, [[skill[:count].to_i, 3].max, 12].min)
    if targets.empty?
      count = [[skill[:count].to_i, 3].max, 12].min
      count.times do |i|
        angle = (Math::PI * 2.0 * i / count) + (@timer.to_f * 0.2)
        dist = 68 + (i % 3) * 34
        x = @hero.x + Math.cos(angle) * dist
        y = @hero.y + Math.sin(angle) * dist
        damage_enemies_in_radius(x, y, skill[:radius].to_i, skill)
        add_ultimate_effect(x, y, 0.48, skill, skill[:radius].to_i, :zone)
      end
    else
      targets.each do |target|
        damage_enemies_in_radius(target.x, target.y, skill[:radius].to_i, skill)
        add_ultimate_effect(target.x, target.y, 0.48, skill, skill[:radius].to_i, :zone)
      end
    end
  rescue
  end

  def spawn_ultimate_ghost_rift(skill)
    radius = [skill[:radius].to_i, 120].max
    pull_enemies_toward_hero(radius, 54)
    damage_enemies_in_radius(@hero.x, @hero.y, radius, skill)
    add_ultimate_effect(@hero.x, @hero.y, 0.70, skill, radius, :circle)
    count = [[skill[:count].to_i, 3].max, 10].min
    count.times do |i|
      angle = (Math::PI * 2.0 * i / count) + (@timer.to_f * 0.4)
      spawn_projectile_from(@hero.x, @hero.y, angle, skill) do |p|
        p.homing = true
        p.ttl = 3.2
        p.damage = [(p.damage * 0.65).ceil, 1].max
      end
    end
  rescue
  end

  def spawn_ultimate_steel_rain(skill)
    clear_enemy_projectiles_near_hero(240)
    targets = visible_enemy_targets_from(@hero.x, @hero.y, 9999, [[skill[:count].to_i, 4].max, 12].min)
    targets = fallback_ring_points([[skill[:count].to_i, 4].max, 12].min, 112) if targets.empty?
    targets.each do |target|
      x = target.respond_to?(:x) ? target.x : target[0]
      y = target.respond_to?(:y) ? target.y : target[1]
      damage_enemies_in_radius(x, y, skill[:radius].to_i, skill)
      add_ultimate_effect(x, y, 0.36, skill, skill[:radius].to_i, :ring)
    end
  rescue
  end

  def spawn_ultimate_poison_crown(skill)
    radius = 84
    duration = skill[:zone_time].to_f > 0.0 ? skill[:zone_time].to_f : 4.2
    8.times do |i|
      angle = (Math::PI * 2.0 / 8.0) * i
      x = @hero.x + Math.cos(angle) * radius
      y = @hero.y + Math.sin(angle) * radius
      @effects << [x, y, duration, skill_color(skill), skill[:radius].to_i, :poison_zone, skill, 0.01, 0.0]
      add_ultimate_effect(x, y, 0.22, skill, skill[:radius].to_i, :ring)
    end
    damage_enemies_in_radius(@hero.x, @hero.y, radius + skill[:radius].to_i, skill)
  rescue
  end

  def spawn_ultimate_dragon_breath(skill)
    count = [[skill[:count].to_i, 5].max, 15].min
    base = hero_facing_angle
    spread = 0.20
    count.times do |i|
      offset = (i - ((count - 1) / 2.0)) * spread
      spawn_projectile_from(@hero.x, @hero.y, base + offset, skill) do |p|
        p.ttl = 2.6
        p.radius = PokemonSurvivor::PROJECTILE_RADIUS + 5
      end
    end
    cone_x = @hero.x + Math.cos(base) * (skill[:radius].to_i * 0.45)
    cone_y = @hero.y + Math.sin(base) * (skill[:radius].to_i * 0.45)
    damage_enemies_in_cone(@hero.x, @hero.y, base, skill[:radius].to_i, Math::PI / 3.0, skill)
    add_ultimate_effect(cone_x, cone_y, 0.42, skill, skill[:radius].to_i / 2, :zone)
  rescue
  end

  def spawn_ultimate_magnet_crash(skill, data)
    radius = data[:radius].to_i
    pull_enemies_toward_hero(radius, 78)
    damage_enemies_in_radius(@hero.x, @hero.y, radius, skill)
    4.times do |i|
      angle = Math::PI * 2.0 * i / 4.0
      x = @hero.x + Math.cos(angle) * (radius * 0.42)
      y = @hero.y + Math.sin(angle) * (radius * 0.42)
      damage_enemies_in_radius(x, y, (radius * 0.28).round, skill)
      add_ultimate_effect(x, y, 0.32, skill, (radius * 0.28).round, :ring)
    end
    repel_nearby_threats(radius, 13.0, true)
    add_ultimate_effect(@hero.x, @hero.y, 0.42, skill, radius, :circle)
  rescue
  end

  def spawn_ultimate_slash_dash(skill)
    count = [[skill[:count].to_i, 4].max, 12].min
    base = hero_facing_angle
    count.times do |i|
      offset = (i - ((count - 1) / 2.0)) * 0.18
      spawn_projectile_from(@hero.x, @hero.y, base + offset, skill) do |p|
        p.ttl = 1.65
        p.radius = PokemonSurvivor::PROJECTILE_RADIUS + 4
      end
    end
    damage_enemies_in_cone(@hero.x, @hero.y, base, skill[:radius].to_i, Math::PI / 4.0, skill)
    add_ultimate_effect(@hero.x + Math.cos(base) * 54, @hero.y + Math.sin(base) * 54, 0.28, skill, 82, :zone)
  rescue
  end

  def spawn_ultimate_gem_rain(skill)
    @force_magnet_timer = [@force_magnet_timer.to_f, 4.0].max
    targets = visible_enemy_targets_from(@hero.x, @hero.y, 9999, [[skill[:count].to_i, 5].max, 14].min)
    targets = fallback_ring_points([[skill[:count].to_i, 5].max, 14].min, 132) if targets.empty?
    targets.each do |target|
      x = target.respond_to?(:x) ? target.x : target[0]
      y = target.respond_to?(:y) ? target.y : target[1]
      damage_enemies_in_radius(x, y, skill[:radius].to_i, skill)
      add_ultimate_effect(x, y, 0.34, skill, skill[:radius].to_i, :zone)
    end
  rescue
  end

  def spawn_ultimate_fighting_wave(skill)
    count = [[skill[:count].to_i, 3].max, 9].min
    base = hero_facing_angle
    count.times do |i|
      offset = (i - ((count - 1) / 2.0)) * 0.24
      spawn_projectile_from(@hero.x, @hero.y, base + offset, skill) do |p|
        p.ttl = 2.4
        p.radius = PokemonSurvivor::PROJECTILE_RADIUS + 8
        p.pierce = [skill[:pierce].to_i, 8].max
      end
    end
    damage_enemies_in_cone(@hero.x, @hero.y, base, skill[:radius].to_i, Math::PI / 3.8, skill)
    add_ultimate_effect(@hero.x + Math.cos(base) * 72, @hero.y + Math.sin(base) * 72, 0.38, skill, skill[:radius].to_i / 2, :ring)
  rescue
  end

  def spawn_ultimate_sand_pit(skill)
    radius = [skill[:radius].to_i, 130].max
    pull_enemies_toward_hero(radius, 92)
    damage_enemies_in_radius(@hero.x, @hero.y, radius, skill)
    add_ultimate_effect(@hero.x, @hero.y, 0.58, skill, radius, :ground_zone)
    count = [[skill[:count].to_i, 4].max, 10].min
    zone_radius = [[(radius * 0.28).round, 42].max, 64].min
    count.times do |i|
      angle = (Math::PI * 2.0 * i / count.to_f) + (@timer.to_f * 0.25)
      dist = radius * (i.even? ? 0.42 : 0.66)
      x = @hero.x + Math.cos(angle) * dist
      y = @hero.y + Math.sin(angle) * dist
      damage_enemies_in_radius(x, y, zone_radius, skill)
      @effects << [x, y, 3.2, skill_color(skill), zone_radius, :ground_zone, skill, 0.32, 0.0] if @effects.length < PokemonSurvivor::MAX_EFFECTS
    end
    pull_enemies_toward_hero(radius, 44)
    clear_enemy_projectiles_near_hero(radius * 0.75)
  rescue
  end
  def spawn_ultimate_sonic_swarm(skill)
    @zubat_burst_timer = [skill[:burst_time].to_f, 3.0].max
    @zubat_burst_shot_timer = 0.0
    @zubat_burst_skill = skill
    @zubat_burst_salvo = 0
    add_ultimate_effect(@hero.x, @hero.y, 0.34, skill, [skill[:radius].to_i, 110].max, :ring)
  rescue
  end

  def update_zubat_burst(dt)
    return if @zubat_burst_timer.to_f <= 0 || !@zubat_burst_skill || !@hero
    @zubat_burst_timer -= dt.to_f
    @zubat_burst_shot_timer -= dt.to_f
    return if @zubat_burst_shot_timer > 0
    @zubat_burst_shot_timer = 0.12
    @zubat_burst_salvo = @zubat_burst_salvo.to_i + 1
    fire_zubat_burst_salvo(@zubat_burst_skill)
    @zubat_burst_skill = nil if @zubat_burst_timer <= 0
  rescue
    @zubat_burst_timer = 0.0
    @zubat_burst_skill = nil
  end

  def fire_zubat_burst_salvo(skill)
    return if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
    base = hero_facing_angle
    front_offsets = [-0.16, 0.0, 0.16]
    side_offsets = (@zubat_burst_salvo.to_i % 3 == 0) ? [-0.72, 0.72] : []
    offsets = front_offsets + side_offsets
    side_lane = [-18, 0, 18]
    offsets.each_with_index do |offset, i|
      break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
      lane = side_lane[i % side_lane.length]
      side_angle = base + (Math::PI / 2.0)
      x = @hero.x + Math.cos(side_angle) * lane
      y = @hero.y + Math.sin(side_angle) * lane
      spawn_projectile_from(x, y, base + offset, skill) do |p|
        p.ttl = 1.75
        p.radius = PokemonSurvivor::PROJECTILE_RADIUS + 2
        p.pierce = [skill[:pierce].to_i, 3].max
      end
    end
  rescue
  end

  def spawn_ultimate_aurora_floe(skill)
    radius = [skill[:radius].to_i, 120].max
    damage_enemies_in_radius(@hero.x, @hero.y, radius, skill)
    add_ultimate_effect(@hero.x, @hero.y, 0.62, skill, radius, :circle)
    count = [[skill[:count].to_i, 4].max, 10].min
    count.times do |i|
      angle = (Math::PI * 2.0 * i / count.to_f) + (@timer.to_f * 0.15)
      dist = radius * (i.even? ? 0.38 : 0.62)
      x = @hero.x + Math.cos(angle) * dist
      y = @hero.y + Math.sin(angle) * dist
      damage_enemies_in_radius(x, y, skill[:radius].to_i / 3, skill)
      @effects << [x, y, 3.8, skill_color(skill), [skill[:radius].to_i / 3, 38].max, :zone, skill, 0.34, 0.0] if @effects.length < PokemonSurvivor::MAX_EFFECTS
    end
    repel_nearby_threats(radius, 6.5, true)
  rescue
  end

  def spawn_ultimate_spider_nest(skill)
    count = [[skill[:count].to_i, 5].max, 14].min
    targets = visible_enemy_targets_from(@hero.x, @hero.y, 9999, count)
    targets = fallback_ring_points(count, 118) if targets.empty?
    targets.each do |target|
      x = target.respond_to?(:x) ? target.x : target[0]
      y = target.respond_to?(:y) ? target.y : target[1]
      angle = Math.atan2(y - @hero.y, x - @hero.x)
      spawn_projectile_from(@hero.x, @hero.y, angle, skill) do |p|
        p.ttl = 1.7
        p.radius = PokemonSurvivor::PROJECTILE_RADIUS + 3
        p.pierce = [skill[:pierce].to_i, 2].max
      end
      damage_enemies_in_radius(x, y, skill[:radius].to_i, skill)
      @effects << [x, y, 3.0, skill_color(skill), skill[:radius].to_i, :zone, skill, 0.36, 0.0] if @effects.length < PokemonSurvivor::MAX_EFFECTS
    end
  rescue
  end
  def spawn_ultimate_bubble_tide(skill)
    radius = [skill[:radius].to_i, 110].max
    damage_enemies_in_radius(@hero.x, @hero.y, radius, skill)
    repel_nearby_threats(radius, 7.5, true)
    add_ultimate_effect(@hero.x, @hero.y, 0.46, skill, radius, :circle)
    count = [[skill[:count].to_i, 8].max, 16].min
    count.times do |i|
      break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
      angle = (Math::PI * 2.0 * i / count.to_f) + (@timer.to_f * 0.18)
      spawn_projectile_from(@hero.x, @hero.y, angle, skill) do |p|
        p.ttl = 2.35
        p.radius = PokemonSurvivor::PROJECTILE_RADIUS + 3
        p.bounces = [skill[:bounce].to_i, 1].max
      end
    end
  rescue
  end

  def spawn_ultimate_echo_chamber(skill)
    base = hero_facing_angle
    radius = [skill[:radius].to_i, 120].max
    damage_enemies_in_cone(@hero.x, @hero.y, base, radius, Math::PI / 2.6, skill)
    repel_nearby_threats(radius, 6.0, false)
    add_ultimate_effect(@hero.x + Math.cos(base) * 54, @hero.y + Math.sin(base) * 54, 0.38, skill, radius / 2, :ring)
    count = [[skill[:count].to_i, 4].max, 10].min
    count.times do |i|
      break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
      side = i.even? ? 1 : -1
      angle = base + (side * (Math::PI / 2.0)) + ((i / 2) * 0.10 * side)
      spawn_projectile_from(@hero.x, @hero.y, angle, skill) do |p|
        p.ttl = 1.45
        p.radius = PokemonSurvivor::PROJECTILE_RADIUS + 3
      end
    end
  rescue
  end

  def spawn_ultimate_dragon_current(skill)
    radius = [skill[:radius].to_i, 120].max
    clear_enemy_projectiles_near_hero(radius * 0.8)
    add_ultimate_effect(@hero.x, @hero.y, 0.44, skill, radius, :ring)
    count = [[skill[:count].to_i, 6].max, 14].min
    base = (@timer.to_f * 0.32) % (Math::PI * 2.0)
    count.times do |i|
      break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
      angle = base + (Math::PI * 2.0 * i / count.to_f)
      x = @hero.x + Math.cos(angle) * 18
      y = @hero.y + Math.sin(angle) * 18
      spawn_projectile_from(x, y, angle, skill) do |p|
        p.ttl = 2.25
        p.radius = PokemonSurvivor::PROJECTILE_RADIUS + 2
        p.pierce = [skill[:pierce].to_i, 5].max
      end
    end
  rescue
  end
  def spawn_ultimate_aura_ring_chain(skill)
    rings = [[skill[:count].to_i, 4].max, 8].min
    base_radius = [skill[:radius].to_i, 96].max
    rings.times do |i|
      break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
      count = 10
      radius = base_radius + (i * 10)
      base = (@timer.to_f * 0.28) + (i * 0.18)
      count.times do |j|
        break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
        angle = base + (Math::PI * 2.0 * j / count.to_f)
        spawn_projectile_from(@hero.x, @hero.y, angle, skill) do |p|
          p.ttl = 0.72 + (i * 0.055)
          p.radius = PokemonSurvivor::PROJECTILE_RADIUS + 4
          p.pierce = [skill[:pierce].to_i, 2].max
          p.speed = [skill[:speed].to_f + (i * 0.18), 8.4].min
        end
      end
      add_ultimate_effect(@hero.x, @hero.y, 0.18 + (i * 0.035), skill, radius, :ring) if i.even?
    end
  rescue
  end
  def spawn_ultimate_twin_eclipse(skill)
    count = [[skill[:count].to_i, 10].max, 36].min
    step = Math::PI * 2.0 / count.to_f
    offset = (System.uptime rescue 0.0).to_f % step
    count.times do |i|
      ghost = (i % 2 == 0)
      shot = skill.clone
      if ghost
        shot[:name] = _INTL("Twin Eclipse Ghost")
        shot[:type] = :GHOST
        shot[:vfx] = "VFX_GHOST"
        shot[:slow] = skill[:slow] || 2.0
        shot[:slow_mult] = 0.35
        shot[:knockback] = nil
        shot[:knock_limit] = nil
      else
        shot[:name] = _INTL("Twin Eclipse Normal")
        shot[:type] = :NORMAL
        shot[:vfx] = "VFX_NORMAL2_SHOT"
        shot[:slow] = nil
        shot[:slow_mult] = nil
        shot[:knockback] = skill[:knockback] || 70
        shot[:knock_limit] = 2
      end
      angle = offset + (step * i)
      spawn_projectile_from(@hero.x, @hero.y, angle, shot) do |p|
        p.ttl = 2.65
        p.radius = PokemonSurvivor::PROJECTILE_RADIUS + 3
      end
    end
    add_ultimate_effect(@hero.x, @hero.y, 0.40, skill, skill[:radius].to_i, :ring)
  rescue
  end

  def spawn_ultimate_mew_random(skill)
    types = [:FIRE, :WATER, :ELECTRIC, :GRASS, :PSYCHIC, :FAIRY, :DRAGON, :GHOST, :DARK]
    type = types.sample || :PSYCHIC
    mixed = skill.clone
    mixed[:type] = type
    mixed[:speed] = 6.0 if mixed[:speed].to_f <= 0
    mixed[:pierce] = 4 if mixed[:pierce].to_i <= 0
    mixed[:kind] = type == :ELECTRIC ? :thunder_ring_burst : :radial
    case type
    when :GRASS, :FAIRY
      damage_enemies_in_radius(@hero.x, @hero.y, skill[:radius].to_i, mixed)
      add_ultimate_effect(@hero.x, @hero.y, 0.44, mixed, skill[:radius].to_i, :ring)
    when :WATER
      spawn_ultimate_water_waves(mixed)
    when :ELECTRIC
      spawn_ultimate_thunder_ring(mixed)
    when :DRAGON
      spawn_ultimate_dragon_breath(mixed)
    else
      spawn_ultimate_radial_projectiles(mixed, skill[:count].to_i)
      add_ultimate_effect(@hero.x, @hero.y, 0.36, mixed, 120, :ring)
    end
  rescue
  end

  def hero_facing_angle
    case @hero.direction
    when PokemonSurvivor::DIR8_DOWN then Math::PI / 2.0
    when PokemonSurvivor::DIR8_DOWN_RIGHT then Math::PI / 4.0
    when PokemonSurvivor::DIR8_RIGHT then 0.0
    when PokemonSurvivor::DIR8_UP_RIGHT then -Math::PI / 4.0
    when PokemonSurvivor::DIR8_UP then -Math::PI / 2.0
    when PokemonSurvivor::DIR8_UP_LEFT then -Math::PI * 3.0 / 4.0
    when PokemonSurvivor::DIR8_LEFT then Math::PI
    when PokemonSurvivor::DIR8_DOWN_LEFT then Math::PI * 3.0 / 4.0
    else 0.0
    end
  rescue
    0.0
  end
  def fallback_ring_points(count, radius)
    ret = []
    count.to_i.times do |i|
      angle = (Math::PI * 2.0 * i / count.to_f) + (@timer.to_f * 0.2)
      ret << [@hero.x + Math.cos(angle) * radius.to_f, @hero.y + Math.sin(angle) * radius.to_f]
    end
    ret
  rescue
    []
  end

  def damage_enemies_in_cone(x, y, angle, radius, half_width, skill)
    build_enemy_grid
    skill_id = skill_id_for(skill)
    base_damage = (skill[:damage].to_i * @skill_power_mult[skill_id]).ceil
    nearby_enemies_for(x, y, radius + 48).each do |e|
      next if e.hp <= 0
      dx = e.x - x
      dy = e.y - y
      dist_sq = dx * dx + dy * dy
      next if dist_sq > ((radius + e.radius) * (radius + e.radius))
      enemy_angle = Math.atan2(dy, dx)
      delta = normalize_angle(enemy_angle - angle).abs
      next if delta > half_width.to_f
      damage_enemy(e, base_damage, skill[:type], skill_color(skill), skill)
    end
  rescue
  end

  def normalize_angle(angle)
    while angle > Math::PI
      angle -= Math::PI * 2.0
    end
    while angle < -Math::PI
      angle += Math::PI * 2.0
    end
    angle
  rescue
    0.0
  end

  def clear_enemy_projectiles_near_hero(radius)
    return if !@projectiles || !@hero
    r2 = radius.to_f * radius.to_f
    @projectiles.delete_if do |p|
      next false if p.owner != :enemy
      dx = p.x - @hero.x
      dy = p.y - @hero.y
      dx * dx + dy * dy <= r2
    end
  rescue
  end

  def pull_enemies_toward_hero(radius, force)
    return if !@enemies || !@hero
    source = Object.new
    nearby_enemies_for(@hero.x, @hero.y, radius).each do |e|
      next if !e || e.hp.to_i <= 0
      dx = @hero.x - e.x
      dy = @hero.y - e.y
      dist = [Math.sqrt(dx * dx + dy * dy), 1.0].max
      next if dist > radius.to_f
      power = force.to_f * (1.0 - (dist / radius.to_f))
      next if power <= 0.0 || !claim_enemy_attraction(e, source)
      e.x += dx / dist * power
      e.y += dy / dist * power
    end
  rescue
  end

  def add_ultimate_effect(x, y, duration, skill, radius, kind)
    return if !@effects || @effects.length >= PokemonSurvivor::MAX_EFFECTS
    @effects << [x, y, duration, skill_color(skill), radius, kind, skill, nil, 0.0]
  rescue
  end

  def open_pause
    @state = :pause
    @pause_index ||= 0
    @accumulator = 0.0
    pbSEPlay("Survivor/GUI menu open", PokemonSurvivor::UI_MENU_VOLUME, 100) rescue nil
    draw_pause
  end

  def update_pause
    old = @pause_index
    @pause_index -= 1 if Input.repeat?(Input::UP)
    @pause_index += 1 if Input.repeat?(Input::DOWN)
    @pause_index = 0 if @pause_index < 0
    @pause_index = [@pause_index, endless_mode? ? 2 : 1].min
    if survivor_cancel_triggered?
      resume_from_pause
      return
    end
    if survivor_confirm_triggered?
      if @pause_index == 0
        resume_from_pause
      elsif @pause_index == 2 && endless_mode?
        confirm_endless_self_destruct
      else
        abandon_run
      end
      return
    end
    pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil if old != @pause_index
    draw_pause
  end

  def resume_from_pause
    @state = :play
    @accumulator = 0.0
    @last_time = System.uptime rescue @last_time
    pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
    draw_game
  end

  # Stop both active emitters and delayed attacks before another run can tick.
  def reset_burst_run_state
    @aurora_current_timer = 0.0
    @storm_collector_timer = 0.0
    @current_mega_evolution_data = nil
    @mega_prompt_timer = 0.0
    @charizard_mega_active = false
    @charizard_mega_charge = 0.0
    @charizard_mega_timer = 0.0
    @charizard_mega_damage_mult = 1.0
    @charizard_mega_cooldown_mult = 1.0
    @charizard_mega_count_bonus = 0
    @charizard_mega_action_buffer = false
    @charizard_mega_action_buffer_timer = 0.0
    @mewtwo_boss_active = false
    @headache_charge = nil
    @headache_waves = []
    @psyduck_charge_bitmap = nil
    @psyduck_confusion_timer = 0.0
    @psyduck_burst_wait_timer = 0.0
    @galar_rush_timer = 0.0
    @galar_pull_timer = 0.0
    @psi_echo_timer = 0.0
    @psi_echo_next = 0.0
    @eevee_burst_timer = 0.0
    @fairy_prisons = nil
    @treecko_barrage_timer = 0.0
    @forest_dance_timer = 0.0
    @forest_dance_shot_timer = 0.0
    @forest_dance_skill = nil
    @treecko_barrage_shot_timer = 0.0
    @treecko_barrage_interval = 0.0
    @treecko_barrage_angle = 0.0
    @treecko_barrage_skill = nil
    @bulbasaur_poison_rain_timer = 0.0
    @bulbasaur_poison_rain_shot_timer = 0.0
    @bulbasaur_poison_rain_interval = 0.0
    @bulbasaur_poison_rain_skill = nil
    @target_lock_barrages = []
    @goodra_steel_rings = []
    @repeating_shockwave_bursts = []
    @enemy_swing_bursts = []
    @tyrunt_shockwaves = []
    @zangoose_surge_timer = 0.0
    @zangoose_surge_radius_mult = 1.0
    @zangoose_surge_spin_mult = 1.0
    @zangoose_surge_power_mult = 1.0
    @drilbur_spike_burst_timer = 0.0
    @drilbur_spike_burst_shot_timer = 0.0
    @drilbur_spike_burst_interval = 0.0
    @drilbur_spike_burst_skill = nil
    @zubat_burst_timer = 0.0
    @zubat_burst_shot_timer = 0.0
    @zubat_burst_skill = nil
    @zubat_burst_salvo = 0
    @kubfu_focus_timer = 0.0
    @returning_blade_burst = nil
    @gen9_burst = nil
    @ceruledge_burst_timer = 0.0
    @projectile_overdrive_timer = 0.0
    @projectile_overdrive_mult = 1.0
    @larvitar_haste_timer = 0.0
    @ultimate_charge = 0.0
    @ultimate_drain_timer = 0.0
    @ultimate_drain_duration = 0.0
    @ultimate_ready_flash = 0.0
    @ultimate_prompt_timer = 0.0
    @ultimate_action_buffer = false
    @ultimate_action_buffer_timer = 0.0
  end

  def confirm_endless_self_destruct
    return unless endless_mode? && @state == :pause && @hero && !@run_finished
    return if @timer.to_f < 600.0
    if pbConfirmMessage(_INTL("Knock out your Pokemon and end this run? Your score and earned rewards will be counted."))
      @hero.hp = 0
      finish_run
      @state = :gameover
      @result_text = _INTL("Survival ended.")
      play_survivor_result_bgm
      draw_gameover
    else
      draw_pause
    end
    @accumulator = 0.0
    @last_time = System.uptime
  end

  def clear_transient_run_state
    reset_run_speed_state
    @applin_guard_charge_ready_at = 0.0
    reset_burst_run_state
    @charge_shots = []
    @projectiles = [] if @state != :play
    @effects = [] if @state != :play
    @run_bonus_panel_open = false
    @run_bonus_panel_mode = :stats
    @run_bonus_panel_slide = 0.0
  rescue
  end
  def abandon_run
    @run_abandoned = true
    finish_run
    @state = :gameover
    @result_text = _INTL("Run abandoned.")
    pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
    play_survivor_result_bgm
    draw_gameover
  end

  def finish_run
    award_endless_score if @run_mode == :endless && !@run_abandoned
    clear_transient_run_state
    return if @run_finished
    @run_finished = true
    @run_unlock_messages = []
    return if @run_abandoned
    base = PokemonSurvivor.species_key(@hero_base_name)
    survived = @timer.to_f
    progress = PokemonSurvivor.survivor_progress
    add_progress_finish(progress, :level_finished, base) if @level.to_i >= 100
    add_progress_finish(progress, :evolution_finished, base) if final_power_reached?(base)
    unlock_from_run(base, survived)
    unlock_population_requirements
    unlock_mew_if_ready
    if rush_mode?
      rush_validated = @rush_complete || @rush_final_boss_defeated
      add_progress_finish(progress, :rush_finished, base) if rush_validated
      if rush_validated
        add_run_unlock(:PICHU) if base == :ZUBAT
        add_run_unlock(:SABLEYE) if base == :GASTLY
        add_run_unlock(:DRATINI) if base == :BAGON && @level.to_i >= 70
        add_run_unlock(:CROAGUNK) if poison_unlock_runner?(base) && @timer.to_f < 600.0
        add_run_unlock(:PAWNIARD) if base == :ARON
        add_run_unlock(:HONEDGE) if base == :PAWNIARD
        add_run_unlock(:NOIBAT) if base == :ZUBAT && @level.to_i >= 80
        add_run_unlock(:HAWLUCHA) if base == :RIOLU
        add_run_unlock(:LARVESTA) if base == :CHIMCHAR
        unlock_population_requirements
        unlock_mew_if_ready
        unlock_deoxys_if_ready
      end
      award_roguelite_shop_currency(rush_validated)
      prepare_leaderboard_share_prompt
      return
    end
    if endless_mode?
      award_roguelite_shop_currency(false)
      prepare_leaderboard_share_prompt
      return
    end
    if tower_mode?
      tower_validated = @tower_complete
      award_tower_score
      add_progress_finish(progress, :tower_finished, base) if tower_validated
      if tower_validated
        add_run_unlock(:RIOLU) if base == :PICHU
        add_run_unlock(:DEINO) if base == :DRATINI
        unlock_population_requirements
        unlock_mew_if_ready
        unlock_deoxys_if_ready
      end
      award_roguelite_shop_currency(tower_validated)
      prepare_leaderboard_share_prompt
      return
    end
    add_progress_finish(progress, :boss_finished, base) if @ultra_boss_defeated
    classic_finished = survived >= current_run_target_seconds
    run_validated = classic_finished && @ultra_boss_defeated
    if classic_finished
      progress[:classic_completed_runs_count] = progress[:classic_completed_runs_count].to_i + 1
      add_progress_finish(progress, :survived_15, base)
    end
    if run_validated
      unlock_population_requirements
      unlock_mew_if_ready
      unlock_deoxys_if_ready
    end
    award_roguelite_shop_currency(run_validated)
    prepare_leaderboard_share_prompt
  rescue
  end


  def award_roguelite_shop_currency(run_won)
    return if @run_abandoned || @shop_currency_awarded
    award_pokemon_training_candies(run_won)
    gained = PokemonSurvivor.shop_run_currency_reward(@score.to_i, @level.to_i, run_won, !endless_mode?)
    fragment_mult = (@equipment_currency_gain_mult || 1.0).to_f * (@equipment_fragment_gain_mult || 1.0).to_f
    gained = (gained.to_i * fragment_mult).round
    return if gained.to_i <= 0
    PokemonSurvivor.add_shop_currency(gained)
    dark_gained = PokemonSurvivor.convert_shop_currency_to_dark_if_unlocked
    @shop_currency_awarded = true
    if PokemonSurvivor.endless_shop_currency_unlocked?
      @run_unlock_messages << _INTL("Earned {1} Dark Fragment.", dark_gained.to_i) if dark_gained.to_i > 0
    else
      @run_unlock_messages << _INTL("Earned {1} Fragments.", gained)
    end
  rescue
  end
  def award_pokemon_training_candies(run_won)
    return if @run_abandoned || @candy_currency_awarded
    gained = PokemonSurvivor.candy_run_currency_reward(@score.to_i, @level.to_i, run_won)
    candy_mult = (@equipment_shiny_candy_mult || 1.0).to_f
    gained = (gained.to_i * candy_mult).round
    return if gained.to_i <= 0
    PokemonSurvivor.add_candy_currency(gained)
    @candy_currency_awarded = true
    @run_unlock_messages << _INTL("Earned {1} Candies.", gained)
  rescue
  end
  def capture_classic_competitive_stats
    return unless @run_mode == :classic && !@breach_run && !@titan_run && !@challenge_run
    return if @classic_competitive_stats || @timer.to_f < PokemonSurvivor::MAX_SECONDS
    @classic_competitive_stats = {
      score: @score.to_i, level: @level.to_i, kills: @kills.to_i,
      seconds: PokemonSurvivor::MAX_SECONDS, won: !!@ultra_boss_defeated
    }.freeze
  end

  def competitive_run_stats
    @classic_competitive_stats || { score: @score.to_i, level: @level.to_i,
      kills: @kills.to_i, seconds: @timer.to_f }
  end

  def leaderboard_run_won?
    return @classic_competitive_stats[:won] if @classic_competitive_stats
    if endless_mode?
      return !@run_abandoned && @timer.to_f >= 60.0 && @score.to_i >= 100_000
    elsif rush_mode?
      return @rush_complete || @rush_final_boss_defeated
    elsif tower_mode?
      return @tower_complete
    end
    @timer.to_f >= current_run_target_seconds && @ultra_boss_defeated
  rescue
    false
  end

  def leaderboard_share_eligible?
    return false if @run_abandoned
    return false if !leaderboard_run_won?
    return false if @leaderboard_submitted
    return false if competitive_run_stats[:score] <= 0
    return false if !PokemonSurvivor.supabase_submit_configured?
    true
  rescue
    false
  end

  def prepare_leaderboard_share_prompt
    return if !leaderboard_share_eligible?
    @leaderboard_share_pending = true
    @leaderboard_share_index = 0
  rescue
  end

  def resolve_leaderboard_share_choice(share)
    return if !@leaderboard_share_pending
    @leaderboard_share_pending = false
    if share
      submit_current_run_to_leaderboard
    else
      @leaderboard_submitted = true
    end
    draw_gameover rescue nil
  rescue
    @leaderboard_share_pending = false
  end


  def leaderboard_extra_stats
    kills = competitive_run_stats[:kills]
    return { floor_reached: endless_difficulty_stage, bosses_defeated: 0, damage_taken: 0, kills: kills } if endless_mode?
    return {
      floor_reached: [[@tower_floor.to_i, 1].max, PokemonSurvivor::TOWER_MAX_FLOOR].min,
      bosses_defeated: @tower_bosses_defeated.to_i,
      damage_taken: @tower_damage_taken.to_i,
      kills: kills
    } if tower_mode?
    { floor_reached: 0, bosses_defeated: 0, damage_taken: 0, kills: kills }
  rescue
    { floor_reached: 0, bosses_defeated: 0, damage_taken: 0, kills: 0 }
  end
  def submit_current_run_to_leaderboard
    return if @leaderboard_submitted
    return if @run_abandoned
    return if !leaderboard_run_won?
    return if !PokemonSurvivor.ensure_online_trainer_name(:share_score)
    stats = competitive_run_stats
    result = PokemonSurvivor.submit_leaderboard_run(stats[:score], @leaderboard_run_key, @hero_base_name, stats[:level], @run_mode, stats[:seconds], leaderboard_extra_stats)
    @leaderboard_submitted = result == "QUEUED" || PokemonSurvivor.online_submission_success?(:classic, result)
    pbMessage(_INTL("Score saved for automatic sending when the connection is available.")) if result == "QUEUED"
  rescue
  end

  def add_progress_finish(progress, key, base)
    progress[key] ||= []
    keys = progress[key].map { |entry| PokemonSurvivor.species_key(entry) }
    progress[key] << base if !keys.include?(base)
  rescue
  end

  def final_power_reached?(base)
    base = PokemonSurvivor.species_key(base)
    return true if @final_evolution_times && @final_evolution_times[base].to_f > 0
    return true if @hero_power_stage.to_i >= 2
    false
  rescue
    false
  end

  def unlock_from_run(base, survived)
    return if @run_abandoned
    classic_won = classic_mode? && survived.to_f >= current_run_target_seconds && @ultra_boss_defeated
    PokemonSurvivor::GEN9_SURVIVOR_UNLOCKS.each do |child, parent|
      add_run_unlock(child) if classic_won && base == parent
    end
    kills = @kills.to_i
    level = @level.to_i
    score = @score.to_i
    final_time = (@final_evolution_times || {})[base].to_f
    add_run_unlock(:STARLY) if classic_mode? && score >= 1_000_000
    case base
    when :BULBASAUR
      add_run_unlock(:MAREEP) if final_time > 0
    when :GOOMY
      add_run_unlock(:APPLIN) if classic_won
    when :FROAKIE
      add_run_unlock(:SCORBUNNY) if classic_won
    when :SCORBUNNY
      add_run_unlock(:ZIGZAGOON_1) if classic_won
    when :NOIBAT
      add_run_unlock(:ROOKIDEE) if classic_won
    when :WIMPOD
      add_run_unlock(:DREEPY) if classic_won
    when :FENNEKIN
      add_run_unlock(:HATENNA) if classic_won
    when :HATENNA
      add_run_unlock(:IMPIDIMP) if classic_won
    when :CROAGUNK
      add_run_unlock(:TOXEL) if classic_won
    when :RIOLU
      add_run_unlock(:KUBFU) if classic_won
    when :CYNDAQUIL
      add_run_unlock(:RALTS) if survived >= 600
    when :MUDKIP, :MARSHTOMP, :SWAMPERT
      add_run_unlock(:ARON) if level >= 75
      add_run_unlock(:AZURILL) if classic_won && final_power_reached?(base) && level >= 100
    when :MAREEP
      add_run_unlock(:ZANGOOSE) if final_time > 0 && kills >= 2500
    when :RALTS
      add_run_unlock(:GASTLY) if kills >= 2000
    when :ARON
      add_run_unlock(:NIDORANm) if final_time > 0
    when :ZANGOOSE
      add_run_unlock(:BELDUM) if kills >= 5000
    when :GASTLY
      # Sableye is unlocked by clearing Rush mode with Gastly.
      add_run_unlock(:LITWICK) if classic_won
    when :NIDORANm
      add_run_unlock(:BAGON) if final_time > 0 && final_time <= 720
    when :SABLEYE
      add_run_unlock(:MACHOP) if survived >= 900
      add_run_unlock(:ZORUA) if classic_won
    when :BELDUM
      add_run_unlock(:TRAPINCH) if final_time > 0 && kills >= 7000
    when :BAGON
      add_run_unlock(:ZUBAT) if @ultra_boss_defeated
    when :MACHOP
      add_run_unlock(:SPHEAL) if level >= 100
    when :SPHEAL
      add_run_unlock(:LARVITAR) if classic_won && final_power_reached?(base) && kills >= 7000
      add_run_unlock(:VANILLITE) if classic_won
    when :TRAPINCH
      add_run_unlock(:SPINARAK) if final_time > 0 && level >= 90
      add_run_unlock(:SANDILE) if classic_won
      add_run_unlock(:DRILBUR) if level >= 100
    when :SPINARAK
      add_run_unlock(:BELLSPROUT) if classic_won && final_power_reached?(base)
      add_run_unlock(:VENIPEDE) if classic_won
    when :BELLSPROUT
      add_run_unlock(:SHINX) if classic_won && kills >= 5000
    when :PICHU
      # Shinx is unlocked by a valid Classic Bellsprout run.
    when :ZORUA
      add_run_unlock(:ZORUA_1) if classic_won
    when :LARVITAR
      add_run_unlock(:TYRUNT) if classic_won && kills >= 7000
    when :DEINO
      add_run_unlock(:GOOMY) if level >= 100
    when :AZURILL
      add_run_unlock(:FROAKIE) if classic_won
    end
  rescue
  end

  def unlocked_nonstarter_playable_count
    (unlocked_playable_hero_keys - PokemonSurvivor::INITIAL_UNLOCKED_HEROES).length
  rescue
    0
  end

  def unlock_population_requirements
    add_run_unlock(:CHIMCHAR) if unlocked_nonstarter_playable_count >= 6
    add_run_unlock(:FENNEKIN) if unlocked_nonstarter_playable_count >= 10
    add_run_unlock(:GIBLE) if unlocked_playable_hero_keys.length >= 25
  rescue
  end

  def poison_unlock_runner?(base)
    key = PokemonSurvivor.species_key(base)
    return false if key == :CROAGUNK
    PokemonSurvivor.species_types(key).include?(:POISON)
  rescue
    false
  end
  def unlocked_playable_hero_keys
    unlocked = PokemonSurvivor.survivor_progress[:unlocked].map { |entry| PokemonSurvivor.species_key(entry) }
    playable = PokemonSurvivor::BASE_HERO_KEYS - [:DEOXYS]
    unlocked.select { |key| playable.include?(key) }.uniq
  rescue
    []
  end

  def unlock_mew_if_ready
    unlocked = unlocked_playable_hero_keys - [:MEW]
    add_run_unlock(:MEW) if unlocked.length >= 13
  rescue
  end

  def fully_finished_playable_hero_keys
    progress = PokemonSurvivor.survivor_progress
    playable = PokemonSurvivor::BASE_HERO_KEYS - [:DEOXYS]
    finish_lists = [:survived_15, :boss_finished, :evolution_finished, :level_finished, :rush_finished, :tower_finished].map do |key|
      progress[key].map { |entry| PokemonSurvivor.species_key(entry) }.uniq
    end
    playable.select { |key| finish_lists.all? { |list| list.include?(key) } }.uniq
  rescue
    []
  end

  def unlock_deoxys_if_ready
    return if unlocked_playable_hero_keys.length < 21
    return if fully_finished_playable_hero_keys.length < 11
    add_run_unlock(:DEOXYS)
  rescue
  end

  def add_run_unlock(hero)
    return if !PokemonSurvivor.unlock_hero(hero)
    @run_unlock_messages << _INTL("{1} unlocked!", PokemonSurvivor.species_name(hero))
  rescue
  end


end

















































































































