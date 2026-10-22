#===============================================================================
# Pokemon Survivor - Classic/Endless event variety
#===============================================================================

module PokemonSurvivor
  class << self
    alias wild_names_without_event_delibird wild_names unless method_defined?(:wild_names_without_event_delibird)
    def wild_names
      wild_names_without_event_delibird.reject { |name| species_key(name) == :DELIBIRD }
    rescue
      wild_names_without_event_delibird
    end

    alias arena_wild_names_without_event_delibird arena_wild_names unless method_defined?(:arena_wild_names_without_event_delibird)
    def arena_wild_names
      arena_wild_names_without_event_delibird.reject { |name| species_key(name) == :DELIBIRD }
    rescue
      arena_wild_names_without_event_delibird
    end
  end
end

class Scene_PokemonSurvivor
  SWARM_ALERT_CLASSIC_MIN = 165.0
  SWARM_ALERT_CLASSIC_MAX = 260.0
  SWARM_ALERT_ENDLESS_MIN = 300.0
  SWARM_ALERT_ENDLESS_MAX = 480.0
  SWARM_ALERT_DURATION = 26.0
  ELITE_HUNT_CLASSIC_MIN = 230.0
  ELITE_HUNT_CLASSIC_MAX = 520.0
  CLASSIC_KECLEON_SPAWN_TIME = 60.0
  CLASSIC_DELIBIRD_SPAWN_TIME = 300.0
  CLASSIC_GIMMIGHOUL_SPAWN_TIME = 600.0
  ELITE_HUNT_ENDLESS_MIN = 600.0
  ELITE_HUNT_ENDLESS_MAX = 1200.0
  ELITE_HUNT_FLEE_SECONDS = 210.0
  ELITE_HUNT_ESCAPE_SECONDS = 28.0
  LOST_KECLEON_CLASSIC_MIN = 300.0
  LOST_KECLEON_CLASSIC_MAX = 650.0
  LOST_KECLEON_ENDLESS_MIN = 300.0
  LOST_KECLEON_ENDLESS_MAX = 900.0
  LOST_KECLEON_ACTIVATE_RADIUS = 72.0
  LOST_KECLEON_ACTIVATE_SECONDS = 3.0
  LOST_KECLEON_WAKE_SECONDS = 1.0

  JOKER_EVENT_DATA = [
    {
      id: :glass_cannon, name: "Glass Cannon", tag: "Joker",
      desc: "Damage +45%. Damage taken +22%.",
      apply: proc { |s| s.instance_variable_set(:@damage_mult, (s.instance_variable_get(:@damage_mult) || 1.0).to_f * 1.45); s.instance_variable_set(:@shield_mult, (s.instance_variable_get(:@shield_mult) || 1.0).to_f * 1.22) },
      remove: proc { |s| s.instance_variable_set(:@damage_mult, (s.instance_variable_get(:@damage_mult) || 1.0).to_f / 1.45); s.instance_variable_set(:@shield_mult, (s.instance_variable_get(:@shield_mult) || 1.0).to_f / 1.22) }
    },
    {
      id: :iron_shell, name: "Iron Shell", tag: "Joker",
      desc: "Damage taken -28%. Speed -18%.",
      apply: proc { |s| s.instance_variable_set(:@shield_mult, (s.instance_variable_get(:@shield_mult) || 1.0).to_f * 0.72); h = s.instance_variable_get(:@hero); h.speed *= 0.82 if h },
      remove: proc { |s| s.instance_variable_set(:@shield_mult, (s.instance_variable_get(:@shield_mult) || 1.0).to_f / 0.72); h = s.instance_variable_get(:@hero); h.speed /= 0.82 if h }
    },
    {
      id: :overclock, name: "Overclock", tag: "Joker",
      desc: "Skills recharge +22%. Enemy shots hurt +25%.",
      apply: proc { |s| s.instance_variable_set(:@cooldown_mult, (s.instance_variable_get(:@cooldown_mult) || 1.0).to_f * 0.78); s.instance_variable_set(:@enemy_projectile_shield_mult, (s.instance_variable_get(:@enemy_projectile_shield_mult) || 1.0).to_f * 1.25) },
      remove: proc { |s| s.instance_variable_set(:@cooldown_mult, (s.instance_variable_get(:@cooldown_mult) || 1.0).to_f / 0.78); s.instance_variable_set(:@enemy_projectile_shield_mult, (s.instance_variable_get(:@enemy_projectile_shield_mult) || 1.0).to_f / 1.25) }
    },
    {
      id: :greedy_notes, name: "Greedy Notes", tag: "Joker",
      desc: "EXP +45%. Pickup range -25%.",
      apply: proc { |s| s.instance_variable_set(:@xp_gain_mult, (s.instance_variable_get(:@xp_gain_mult) || 1.0).to_f * 1.45); s.instance_variable_set(:@pickup_mult, (s.instance_variable_get(:@pickup_mult) || 1.0).to_f * 0.75) },
      remove: proc { |s| s.instance_variable_set(:@xp_gain_mult, (s.instance_variable_get(:@xp_gain_mult) || 1.0).to_f / 1.45); s.instance_variable_set(:@pickup_mult, (s.instance_variable_get(:@pickup_mult) || 1.0).to_f / 0.75) }
    },
    {
      id: :boss_bait, name: "Boss Bait", tag: "Joker",
      desc: "Boss damage +55%. Contact damage taken +15%.",
      apply: proc { |s| s.instance_variable_set(:@boss_damage_mult, (s.instance_variable_get(:@boss_damage_mult) || 1.0).to_f * 1.55); s.instance_variable_set(:@shield_mult, (s.instance_variable_get(:@shield_mult) || 1.0).to_f * 1.15) },
      remove: proc { |s| s.instance_variable_set(:@boss_damage_mult, (s.instance_variable_get(:@boss_damage_mult) || 1.0).to_f / 1.55); s.instance_variable_set(:@shield_mult, (s.instance_variable_get(:@shield_mult) || 1.0).to_f / 1.15) }
    },
    {
      id: :wild_tempo, name: "Wild Tempo", tag: "Joker",
      desc: "Speed +28%. Max HP -16%.",
      apply: proc { |s| h = s.instance_variable_get(:@hero); if h; loss = [(h.max_hp.to_i * 0.16).round, 1].max; h.max_hp = [h.max_hp.to_i - loss, 1].max; h.hp = [h.hp.to_i, h.max_hp.to_i].min; h.speed *= 1.28; s.instance_variable_set(:@joker_wild_tempo_hp_loss, loss); end },
      remove: proc { |s| h = s.instance_variable_get(:@hero); if h; h.speed /= 1.28; loss = s.instance_variable_get(:@joker_wild_tempo_hp_loss).to_i; h.max_hp += loss if loss > 0; end; s.instance_variable_set(:@joker_wild_tempo_hp_loss, 0) }
    },
    {
      id: :cursed_magnet, name: "Cursed Magnet", tag: "Joker",
      desc: "Pickup range +80%. Damage taken +18%.",
      apply: proc { |s| s.instance_variable_set(:@pickup_mult, (s.instance_variable_get(:@pickup_mult) || 1.0).to_f * 1.80); s.instance_variable_set(:@shield_mult, (s.instance_variable_get(:@shield_mult) || 1.0).to_f * 1.18) },
      remove: proc { |s| s.instance_variable_set(:@pickup_mult, (s.instance_variable_get(:@pickup_mult) || 1.0).to_f / 1.80); s.instance_variable_set(:@shield_mult, (s.instance_variable_get(:@shield_mult) || 1.0).to_f / 1.18) }
    },
    {
      id: :burst_pact, name: "Burst Pact", tag: "Joker",
      desc: "Burst charge +70%. Damage -12%.",
      apply: proc { |s| s.instance_variable_set(:@burst_charge_mult, (s.instance_variable_get(:@burst_charge_mult) || 1.0).to_f * 1.70); s.instance_variable_set(:@damage_mult, (s.instance_variable_get(:@damage_mult) || 1.0).to_f * 0.88) },
      remove: proc { |s| s.instance_variable_set(:@burst_charge_mult, (s.instance_variable_get(:@burst_charge_mult) || 1.0).to_f / 1.70); s.instance_variable_set(:@damage_mult, (s.instance_variable_get(:@damage_mult) || 1.0).to_f / 0.88) }
    },
    {
      id: :sharp_debt, name: "Sharp Debt", tag: "Joker",
      desc: "Extra attack +1. Skill recharge -12%.",
      apply: proc { |s| s.instance_variable_set(:@projectile_count_bonus, s.instance_variable_get(:@projectile_count_bonus).to_i + 1); s.instance_variable_set(:@cooldown_mult, (s.instance_variable_get(:@cooldown_mult) || 1.0).to_f * 1.12) },
      remove: proc { |s| s.instance_variable_set(:@projectile_count_bonus, [s.instance_variable_get(:@projectile_count_bonus).to_i - 1, 0].max); s.instance_variable_set(:@cooldown_mult, (s.instance_variable_get(:@cooldown_mult) || 1.0).to_f / 1.12) }
    }
  ].freeze unless const_defined?(:JOKER_EVENT_DATA)

  alias setup_random_events_without_classic_endless_variety setup_random_events unless method_defined?(:setup_random_events_without_classic_endless_variety)
  def setup_random_events
    cleanup_classic_endless_variety_events if respond_to?(:cleanup_classic_endless_variety_events)
    setup_random_events_without_classic_endless_variety
    @swarm_alert_timer = event_variety_delay(classic_mode? ? SWARM_ALERT_CLASSIC_MIN : SWARM_ALERT_ENDLESS_MIN, classic_mode? ? SWARM_ALERT_CLASSIC_MAX : SWARM_ALERT_ENDLESS_MAX)
    @swarm_alert_active_timer = 0.0
    @swarm_alert_pulse_timer = 0.0
    reset_swarm_kill_pace
    @elite_hunt_timer = event_variety_delay(classic_mode? ? ELITE_HUNT_CLASSIC_MIN : ELITE_HUNT_ENDLESS_MIN, classic_mode? ? ELITE_HUNT_CLASSIC_MAX : ELITE_HUNT_ENDLESS_MAX)
    @elite_hunt_spawned_classic = false
    @classic_delibird_spawned = false
    @classic_gimmighoul_spawned = false
    @lost_kecleon_timer = classic_mode? ? CLASSIC_KECLEON_SPAWN_TIME : event_variety_delay(LOST_KECLEON_ENDLESS_MIN, LOST_KECLEON_ENDLESS_MAX)
    @lost_kecleon_spawned_classic = false
    @event_lost_kecleon = nil
    @current_joker_bonus_id = nil
    @joker_options = []
    @joker_choice_index = 0
    @joker_choice_consume_start = nil
  rescue
  end

  alias update_random_events_without_classic_endless_variety update_random_events unless method_defined?(:update_random_events_without_classic_endless_variety)
  def update_random_events(dt)
    update_random_events_without_classic_endless_variety(dt)
    update_swarm_alert_event(dt)
    update_elite_hunt_event(dt)
    update_lost_kecleon_event(dt)
  rescue
  end

  def classic_or_endless_events_enabled?
    @state == :play && (@run_mode == :classic || endless_mode?)
  rescue
    false
  end

  def classic_mode?
    @run_mode == :classic
  rescue
    false
  end

  def event_variety_delay(min, max)
    min.to_f + (rand(10_000).to_f / 10_000.0) * [max.to_f - min.to_f, 1.0].max
  rescue
    min.to_f
  end


def cleanup_classic_endless_variety_events
  remove_current_joker_bonus if @current_joker_bonus_id
  cleanup_event_hunt_enemies if respond_to?(:cleanup_event_hunt_enemies)
  @swarm_alert_active_timer = 0.0
  @swarm_alert_pulse_timer = 0.0
  @elite_hunt_timer = 0.0
  @event_lost_kecleon = nil
  @joker_options = []
  @joker_choice_index = 0
  @joker_choice_consume_start = nil
  @current_joker_bonus_id = nil
rescue
end


def record_event_variety_achievement(kind, species = nil)
  return if !defined?(PokemonSurvivorAchievements)
  stats = PokemonSurvivorAchievements.achievement_stats
  ids = []
  case kind
  when :swarm_alert
    stats = PokemonSurvivorAchievements.increment_stat(:swarm_alerts_survived, 1)
    ids << :event_swarm_alert
    ids << :event_swarm_alert_5 if stats[:swarm_alerts_survived].to_i >= 5
  when :elite_hunt_defeated
    stats = PokemonSurvivorAchievements.increment_stat(:elite_hunts_defeated, 1)
    PokemonSurvivorAchievements.add_stat_species(stats, :elite_hunt_species, species) if species
    ids << :event_elite_hunt_first
    ids << :event_gimmighoul_hunt if (PokemonSurvivor.species_key(species) == :GIMMIGHOUL rescue false)
    ids << :event_delibird_hunt if (PokemonSurvivor.species_key(species) == :DELIBIRD rescue false)
    ids << :event_elite_hunt_pair if PokemonSurvivorAchievements.event_species_complete?(stats, :elite_hunt_species, [:GIMMIGHOUL, :DELIBIRD])
    ids << :event_elite_hunt_10 if stats[:elite_hunts_defeated].to_i >= 10
  when :lost_kecleon_helped
    stats = PokemonSurvivorAchievements.increment_stat(:lost_kecleon_helped, 1)
    ids << :event_lost_kecleon
    ids << :event_lost_kecleon_5 if stats[:lost_kecleon_helped].to_i >= 5
  when :joker_taken
    stats = PokemonSurvivorAchievements.increment_stat(:joker_bonuses_taken, 1)
    PokemonSurvivorAchievements.add_stat_species(stats, :joker_bonus_ids, species) if species
    ids << :event_joker_first
    ids << :event_joker_5 if stats[:joker_bonuses_taken].to_i >= 5
    joker_ids = (Scene_PokemonSurvivor::JOKER_EVENT_DATA rescue []).map { |entry| entry[:id] }
    ids << :event_joker_all if PokemonSurvivorAchievements.event_species_complete?(stats, :joker_bonus_ids, joker_ids)
  end
  PokemonSurvivorAchievements.check(ids, true) if !ids.empty?
rescue
end

  def draw_swarm_alert_border(bitmap)
    return if classic_swarm_paused_for_final_boss?
    remaining = @swarm_alert_active_timer.to_f
    return if remaining <= 0.0
    elapsed = [SWARM_ALERT_DURATION - remaining, 0.0].max
    fade = [[elapsed / 0.6, remaining / 0.6, 1.0].min, 0.0].max
    pulse = 0.5 - 0.5 * Math.cos(elapsed * Math::PI * 2.0 / 3.0)
    opacity = (22.0 + 48.0 * pulse) * fade
    colors = (@swarm_border_colors ||= Array.new(8) { Color.new(220, 34, 42, 0) })
    width = bitmap.width
    height = bitmap.height
    # Non-overlapping edge bands keep the centre clear and corners equally soft.
    colors.each_with_index do |color, band|
      inset = band * 3
      w = width - inset * 2
      h = height - inset * 2
      next if w <= 6 || h <= 6
      color.alpha = (opacity * ((8 - band) / 8.0) ** 2).round
      next if color.alpha <= 0
      bitmap.fill_rect(inset, inset, w, 3, color)
      bitmap.fill_rect(inset, height - inset - 3, w, 3, color)
      bitmap.fill_rect(inset, inset + 3, 3, h - 6, color)
      bitmap.fill_rect(width - inset - 3, inset + 3, 3, h - 6, color)
    end
  end

  def reset_swarm_kill_pace
    @swarm_pace_kills = @kills.to_i
    @swarm_pace_elapsed = 0.0
    @swarm_kill_rate = 0.0
  end

  def swarm_kill_pace_multiplier(dt)
    reset_swarm_kill_pace if @swarm_pace_kills.nil? || @kills.to_i < @swarm_pace_kills
    @swarm_pace_elapsed += [dt.to_f, 0.0].max
    if @swarm_pace_elapsed >= 2.0
      rate = (@kills.to_i - @swarm_pace_kills) / @swarm_pace_elapsed
      # Smooth recent kills over roughly ten simulation seconds, not real time.
      weight = [@swarm_pace_elapsed / 10.0, 1.0].min
      @swarm_kill_rate += (rate - @swarm_kill_rate) * weight
      @swarm_pace_kills = @kills.to_i
      @swarm_pace_elapsed = 0.0
    end
    1.0 + [[(@swarm_kill_rate - 4.0) / 4.0, 0.0].max, 2.0].min
  end

  def classic_swarm_paused_for_final_boss?
    @run_mode == :classic && !@breach_run && !@titan_run && !@challenge_run && ultra_enemy_alive?(:ultra_boss)
  end

  def update_swarm_alert_event(dt)
    return if !classic_or_endless_events_enabled?
    if classic_swarm_paused_for_final_boss?
      reset_swarm_kill_pace
      return
    end
    if @swarm_alert_active_timer.to_f > 0.0
      reset_swarm_kill_pace
      @swarm_alert_active_timer = [@swarm_alert_active_timer.to_f - dt.to_f, 0.0].max
      @swarm_alert_pulse_timer = @swarm_alert_pulse_timer.to_f - dt.to_f
      if @swarm_alert_pulse_timer <= 0.0
        count = endless_mode? ? 4 : 3
        count += 1 if @timer.to_i >= 600
        enqueue_enemy_spawns(:wild, count) if respond_to?(:enqueue_enemy_spawns)
        @spawn_timer = [@spawn_timer.to_f, 0.18].min
        @swarm_alert_pulse_timer = endless_mode? ? 0.82 : 0.95
      end
      return
    end
    @swarm_alert_timer = @swarm_alert_timer.to_f - dt.to_f * swarm_kill_pace_multiplier(dt)
    return if @swarm_alert_timer > 0.0
    @swarm_alert_active_timer = SWARM_ALERT_DURATION
    record_event_variety_achievement(:swarm_alert) if !@event_variety_swarm_seen
    @event_variety_swarm_seen = true
    @swarm_alert_pulse_timer = 0.01
    set_hero_item_flash(Color.new(255, 92, 92), 0.85) rescue nil
    @swarm_alert_timer = event_variety_delay(endless_mode? ? SWARM_ALERT_ENDLESS_MIN : SWARM_ALERT_CLASSIC_MIN, endless_mode? ? SWARM_ALERT_ENDLESS_MAX : SWARM_ALERT_CLASSIC_MAX)
  rescue
  end

  def update_elite_hunt_event(dt)
    return if !classic_or_endless_events_enabled?
    cleanup_event_hunt_enemies
    update_event_hunt_enemy(dt) if event_hunt_enemy_alive?
    if classic_mode?
      spawn_classic_timed_event_hunts
      return
    end
    return if event_hunt_enemy_alive?
    @elite_hunt_timer = @elite_hunt_timer.to_f - dt.to_f
    return if @elite_hunt_timer > 0.0
    spawn_event_hunt_enemy
    @elite_hunt_timer = event_variety_delay(ELITE_HUNT_ENDLESS_MIN, ELITE_HUNT_ENDLESS_MAX)
  rescue
  end

  def spawn_classic_timed_event_hunts
    time = @timer.to_f
    if !@classic_delibird_spawned && time >= CLASSIC_DELIBIRD_SPAWN_TIME
      spawn_event_hunt_enemy(:DELIBIRD)
      @classic_delibird_spawned = true
    end
    if !@classic_gimmighoul_spawned && time >= CLASSIC_GIMMIGHOUL_SPAWN_TIME
      spawn_event_hunt_enemy(:GIMMIGHOUL)
      @classic_gimmighoul_spawned = true
    end
  rescue
  end

  def event_hunt_enemy_alive?
    (@enemies || []).any? { |e| e && e.kind == :event_hunt && e.hp.to_i > 0 && !e.instance_variable_get(:@defeated) }
  rescue
    false
  end

  def event_hunt_enemies
    (@enemies || []).select { |e| e && e.kind == :event_hunt }
  rescue
    []
  end

  def cleanup_event_hunt_enemies
    return if !@enemies
    @enemies.delete_if { |e| e && e.kind == :event_hunt && (e.hp.to_i <= 0 || e.instance_variable_get(:@event_fled)) }
  rescue
  end


  def random_event_playable_spawn_position
    if respond_to?(:random_event_map_position)
      x, y = random_event_map_position
    else
      angle = rand * Math::PI * 2
      distance = 280 + rand(260)
      x = @hero.x + Math.cos(angle) * distance
      y = @hero.y + Math.sin(angle) * distance
    end
    respond_to?(:clamp_world_spawn_position) ? clamp_world_spawn_position(x, y, 64) : [x, y]
  rescue
    [@hero.x, @hero.y]
  end

  def random_event_visible_playable_spawn_position(min_distance = 150, max_distance = 260)
    return random_event_playable_spawn_position if !@hero
    18.times do
      angle = rand * Math::PI * 2
      distance = min_distance.to_f + rand([max_distance.to_f - min_distance.to_f, 1.0].max)
      x = @hero.x + Math.cos(angle) * distance
      y = @hero.y + Math.sin(angle) * distance
      x, y = respond_to?(:clamp_world_spawn_position) ? clamp_world_spawn_position(x, y, 64) : [x, y]
      return [x, y] if !respond_to?(:point_on_screen?) || point_on_screen?(x, y, 64)
    end
    random_event_playable_spawn_position
  rescue
    [@hero.x, @hero.y]
  end

  def spawn_event_hunt_enemy(key = nil)
    key ||= (rand(2) == 0 ? :GIMMIGHOUL : :DELIBIRD)
    x, y = random_event_playable_spawn_position
    e = PokemonSurvivorEntity.new(:event_hunt, key.to_s, x, y)
    e.kind = :event_hunt
    e.radius = 18
    e.max_hp = event_hunt_max_hp(key)
    e.hp = e.max_hp
    e.value = 0
    e.speed = key == :DELIBIRD ? 1.72 : 1.42
    e.damage = 0
    e.types = PokemonSurvivor.species_types(key) rescue [key == :DELIBIRD ? :ICE : :GHOST]
    e.attack_type = e.types[0] || :NORMAL
    e.bitmap = cached_event_bitmap(key.to_s, key == :GIMMIGHOUL ? 4 : event_hunt_frame_count(key))
    e.walk_bitmap = e.bitmap
    e.idle_bitmap = e.bitmap
    e.charset_directions = PokemonSurvivor::CHARSET_8_DIRECTIONS
    e.direction = PokemonSurvivor::DIR8_DOWN
    e.moving = true
    e.instance_variable_set(:@event_hunt_key, key)
    e.instance_variable_set(:@event_flee_timer, ELITE_HUNT_FLEE_SECONDS)
    e.instance_variable_set(:@event_hit_reward_cooldown, 0.0)
    e.instance_variable_set(:@event_hit_counter, 0)
    e.instance_variable_set(:@event_hunt_gold_tint, true)
    add_ultimate_effect(e.x, e.y, 0.42, { type: e.attack_type || :NORMAL, vfx: "VFX_LEVEL_UP_BURST" }, 76, :ring) rescue nil
    play_survivor_cry(key, 76, 100) if respond_to?(:play_survivor_cry)
    (@enemies ||= []) << e
    invalidate_enemy_grid if respond_to?(:invalidate_enemy_grid)
    set_hero_item_flash(key == :DELIBIRD ? Color.new(255, 154, 196) : Color.new(255, 220, 92), 0.85) rescue nil
  rescue
  end

  def event_hunt_max_hp(key)
    pressure = endless_mode? ? endless_pressure_seconds(@timer.to_i) : @timer.to_i
    species_scale = 0.86 + (PokemonSurvivor.species_base_total(key) / 520.0)
    stage_scale = 1.0 + (PokemonSurvivor.evolution_stage(key) * 0.16)
    level_scale = 1.0 + ([(@level.to_i - 1), 0].max * 0.026)
    phase_scale = 1.0 + (PokemonSurvivor.hero_difficulty_phase(@level) * 0.16)
    late_cap = endless_mode? ? 2.6 : 0.85
    late_hp_scale = 1.0 + [[(pressure - 360), 0].max / 600.0, late_cap].min
    complete_build_scale = @upgrades_exhausted ? 1.28 : 1.0
    tier = PokemonSurvivor.enemy_progress_tier(pressure, @level)
    scale = (0.62 + (pressure / 270.0) + (tier * 0.08)) * species_scale * stage_scale * level_scale * phase_scale * late_hp_scale * complete_build_scale
    target = respond_to?(:current_run_target_seconds) ? current_run_target_seconds.to_f : 900.0
    boss_hp = (1100 * scale * (1.25 + [@timer.to_i / [target, 1.0].max, 0.75].min)).round
    boss_hp *= 10 if classic_mode?
    boss_hp = (boss_hp * 0.92).round if key == :DELIBIRD
    [boss_hp, endless_mode? ? 12000 : 8000].max
  rescue
    endless_mode? ? 12000 : 8000
  end

  def event_hunt_frame_count(key)
    return 4 if key == :GIMMIGHOUL
    frames = PokemonSurvivor.eight_direction_enemy_asset_frame_count(key) if PokemonSurvivor.respond_to?(:eight_direction_enemy_asset_frame_count)
    frames.to_i > 0 ? frames.to_i : 4
  rescue
    4
  end

  def update_event_hunt_enemy(dt)
    moved = false
    event_hunt_enemies.each do |enemy|
      timer = enemy.instance_variable_get(:@event_flee_timer).to_f - dt.to_f
      enemy.instance_variable_set(:@event_flee_timer, timer)
      enemy.instance_variable_set(:@event_hit_reward_cooldown, [enemy.instance_variable_get(:@event_hit_reward_cooldown).to_f - dt.to_f, 0.0].max)
      if timer <= 0.0
        enemy.instance_variable_set(:@event_fled, true)
        add_ultimate_effect(enemy.x, enemy.y, 0.28, { type: enemy.attack_type || :NORMAL, vfx: "VFX_LEVEL_UP_BURST" }, 52, :ring) rescue nil
        next
      end
      if timer > ELITE_HUNT_ESCAPE_SECONDS
        enemy.moving = false if enemy.respond_to?(:moving=)
        next
      end
      next if !@hero
      dx = enemy.x - @hero.x
      dy = enemy.y - @hero.y
      len = [Math.sqrt(dx * dx + dy * dy), 1.0].max
      away_x = dx / len
      away_y = dy / len
      strafe = Math.sin((@timer.to_f * 1.35) + enemy.object_id.to_f) * 0.28
      escape_rate = (ELITE_HUNT_ESCAPE_SECONDS - timer) / ELITE_HUNT_ESCAPE_SECONDS.to_f
      escape_rate = 0.0 if escape_rate < 0.0
      escape_rate = 1.0 if escape_rate > 1.0
      urgency = 1.0 + (escape_rate * 0.55)
      move_speed = enemy.speed.to_f * (len < 260 ? 1.18 : 0.88) * urgency
      next_x = enemy.x + ((away_x - (away_y * strafe)) * move_speed * 60.0 * dt.to_f)
      next_y = enemy.y + ((away_y + (away_x * strafe)) * move_speed * 60.0 * dt.to_f)
      if respond_to?(:clamp_world_spawn_position)
        enemy.x, enemy.y = clamp_world_spawn_position(next_x, next_y, 48)
      else
        enemy.x = next_x
        enemy.y = next_y
      end
      enemy.direction = direction_from_vector_8(away_x, away_y) rescue enemy.direction
      enemy.moving = true if enemy.respond_to?(:moving=)
      moved = true
    end
    invalidate_enemy_grid if moved && respond_to?(:invalidate_enemy_grid)
  rescue
  end

  alias damage_enemy_without_event_hunt_rewards damage_enemy unless method_defined?(:damage_enemy_without_event_hunt_rewards)
  def damage_enemy(enemy, base_damage, attack_type, color = nil, source = nil)
    damage_enemy_without_event_hunt_rewards(enemy, base_damage, attack_type, color, source)
  rescue
    damage_enemy_without_event_hunt_rewards(enemy, base_damage, attack_type, color, source) rescue nil
  end

  alias defeat_enemy_without_event_hunt_rewards defeat_enemy unless method_defined?(:defeat_enemy_without_event_hunt_rewards)
  def defeat_enemy(enemy)
    if enemy && enemy.kind == :event_hunt
      return if enemy.instance_variable_get(:@defeated)
      enemy.instance_variable_set(:@defeated, true)
      enemy.defeated = true if enemy.respond_to?(:defeated=)
      enemy.hp = 0
      grant_event_hunt_final_reward(enemy)
      record_event_variety_achievement(:elite_hunt_defeated, enemy.instance_variable_get(:@event_hunt_key))
      add_ultimate_effect(enemy.x, enemy.y, 0.38, { type: enemy.attack_type || :NORMAL, vfx: "VFX_LEVEL_UP_BURST" }, 72, :ring) rescue nil
      play_survivor_se(:event_hunt_ko, "Survivor/Pkmn faint", 0.16, PokemonSurvivor::SFX_KO_VOLUME, 116) rescue nil
      return
    end
    defeat_enemy_without_event_hunt_rewards(enemy)
  rescue
  end

  def grant_event_hunt_hit_reward(_enemy)
    # Event hunt rewards are paid only once, when the target is defeated.
  end

  def grant_event_hunt_final_reward(enemy)
    key = enemy.instance_variable_get(:@event_hunt_key)
    if key == :DELIBIRD
      amount = endless_mode? ? (18 + rand(10)) : (12 + rand(7))
      amount = (amount * (@equipment_hunt_reward_mult || 1.0)).round
      PokemonSurvivor.add_candy_currency(amount) if PokemonSurvivor.respond_to?(:add_candy_currency)
      show_chestboss_currency_popup("ICON_CANDY", amount) if respond_to?(:show_chestboss_currency_popup)
    else
      amount = endless_mode? ? (260 + rand(121)) : (170 + rand(81))
      amount = (amount * (@equipment_hunt_reward_mult || 1.0)).round
      PokemonSurvivor.add_shop_currency(amount) if PokemonSurvivor.respond_to?(:add_shop_currency)
      show_chestboss_currency_popup("ICON_FRAGMENT", amount) if respond_to?(:show_chestboss_currency_popup)
    end
    set_hero_item_flash(Color.new(255, 224, 92), 0.9) rescue nil
  rescue
  end

  def update_lost_kecleon_event(dt)
    return if !classic_or_endless_events_enabled?
    if @event_lost_kecleon
      update_lost_kecleon_entity(@event_lost_kecleon, dt)
      return
    end
    @lost_kecleon_timer = @lost_kecleon_timer.to_f - dt.to_f
    return if @lost_kecleon_timer > 0.0
    return if classic_mode? && @lost_kecleon_spawned_classic
    spawn_lost_kecleon
    @lost_kecleon_spawned_classic = true if classic_mode?
    @lost_kecleon_timer = event_variety_delay(LOST_KECLEON_ENDLESS_MIN, LOST_KECLEON_ENDLESS_MAX)
  rescue
  end

  def lost_kecleon_graphics_dir
    PokemonSurvivor.const_defined?(:EVENT_DIR) ? "#{PokemonSurvivor::EVENT_DIR}/Seller" : nil
  rescue
    nil
  end

  def spawn_lost_kecleon
    x, y = random_event_visible_playable_spawn_position(120, 220)
    k = PokemonSurvivorEntity.new(:event_kecleon, "KECLEON", x, y)
    k.radius = 18
    k.max_hp = 1
    k.hp = 1
    k.speed = 0
    k.bitmap = cached_bitmap(lost_kecleon_graphics_dir, "KECLEON_Sleep")
    k.instance_variable_set(:@event_state, :sleeping)
    k.instance_variable_set(:@activate_timer, 0.0)
    k.instance_variable_set(:@wake_timer, 0.0)
    @event_lost_kecleon = k
    set_hero_item_flash(Color.new(122, 255, 176), 0.85) rescue nil
  rescue
  end

  def update_lost_kecleon_entity(kecleon, dt)
    state = kecleon.instance_variable_get(:@event_state) || :sleeping
    case state
    when :sleeping
      if point_distance_sq(kecleon.x, kecleon.y, @hero.x, @hero.y) <= LOST_KECLEON_ACTIVATE_RADIUS * LOST_KECLEON_ACTIVATE_RADIUS
        timer = kecleon.instance_variable_get(:@activate_timer).to_f + dt.to_f
        kecleon.instance_variable_set(:@activate_timer, timer)
        if timer >= LOST_KECLEON_ACTIVATE_SECONDS
          kecleon.instance_variable_set(:@event_state, :waking)
          kecleon.instance_variable_set(:@wake_timer, 0.0)
          kecleon.bitmap = cached_bitmap(lost_kecleon_graphics_dir, "KECLEON_Wake")
          play_survivor_cry(:KECLEON, 76, 100) if respond_to?(:play_survivor_cry)
        end
      else
        kecleon.instance_variable_set(:@activate_timer, 0.0)
      end
    when :waking
      timer = kecleon.instance_variable_get(:@wake_timer).to_f + dt.to_f
      kecleon.instance_variable_set(:@wake_timer, timer)
      if timer >= LOST_KECLEON_WAKE_SECONDS
        @event_lost_kecleon = nil
        record_event_variety_achievement(:lost_kecleon_helped)
        open_joker_choice
      end
    end
  rescue
  end

  def open_joker_choice
    source = (JOKER_EVENT_DATA rescue []).shuffle
    @joker_options = source.first(3)
    @joker_choice_index = 0
    @joker_choice_consume_start = nil
    @joker_reroll_started_at = nil
    @joker_reroll_release_required = upgrade_reroll_pressed?
    @state = :joker_choice
    draw_joker_choice
  rescue
    @state = :play
  end

  def reroll_joker_options
    return false if @state != :joker_choice || @joker_choice_consume_start || @rerolls_left.to_i <= 0
    old_ids = (@joker_options || []).map { |data| data[:id] }
    pool = JOKER_EVENT_DATA.reject { |data| old_ids.include?(data[:id]) }
    return false if pool.empty?
    options = pool.shuffle.first(3)
    if options.length < 3
      options.concat(JOKER_EVENT_DATA.select { |data| old_ids.include?(data[:id]) }.shuffle.first(3 - options.length))
    end
    @joker_options = options
    @joker_choice_index = 0
    @rerolls_left -= 1
    pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
    PokemonSurvivor.gamepad_vibrate_event(:upgrade_reroll) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
    true
  end

  def update_joker_reroll_hold
    pressed = upgrade_reroll_pressed?
    if !pressed
      @joker_reroll_started_at = nil
      @joker_reroll_release_required = false
      return false
    end
    return true if @joker_reroll_release_required
    return false if @rerolls_left.to_i <= 0
    @joker_reroll_started_at ||= System.uptime
    if joker_reroll_hold_progress >= 1.0
      reroll_joker_options
      @joker_reroll_started_at = nil
      @joker_reroll_release_required = true
    end
    true
  end

  def joker_reroll_hold_progress
    return 0.0 unless @joker_reroll_started_at
    [[(System.uptime - @joker_reroll_started_at) / UPGRADE_HOLD_SECONDS, 0.0].max, 1.0].min
  end

  def current_joker_data
    id = @current_joker_bonus_id
    (JOKER_EVENT_DATA rescue []).find { |j| j[:id] == id }
  rescue
    nil
  end

  def remove_current_joker_bonus
    data = current_joker_data
    data[:remove].call(self) if data && data[:remove]
    @current_joker_bonus_id = nil
  rescue
  end

  def apply_joker_bonus(data)
    return if !data
    remove_current_joker_bonus if @current_joker_bonus_id
    data[:apply].call(self) if data[:apply]
    @current_joker_bonus_id = data[:id]
    record_event_variety_achievement(:joker_taken, data[:id])
    set_hero_item_flash(Color.new(255, 210, 255), 0.9) rescue nil
  rescue
  end

  def update_joker_choice
    if @joker_choice_consume_start
      elapsed = (System.uptime rescue 0.0) - @joker_choice_consume_start.to_f
      if elapsed >= 0.50 && !@joker_consume_se_played
        @joker_consume_se_played = true
        play_survivor_se(:joker_consume, "Survivor/Mining reveal", 0.25, PokemonSurvivor::SFX_UPGRADE_CONSUME_VOLUME, 118) rescue nil
      end
      if elapsed >= 0.94
        apply_joker_bonus((@joker_options || [])[@joker_choice_index.to_i])
        PokemonSurvivor.gamepad_vibrate_event(:upgrade_take) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
        @joker_options = []
        @joker_choice_consume_start = nil
        @joker_consume_se_played = false
        @state = :play
        draw_game
        return
      end
      draw_joker_choice
      return
    end
    if update_joker_reroll_hold
      draw_joker_choice
      return
    end
    if Input.trigger?(Input::LEFT)
      @joker_choice_index = [@joker_choice_index.to_i - 1, 0].max
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
    elsif Input.trigger?(Input::RIGHT)
      @joker_choice_index = [@joker_choice_index.to_i + 1, (@joker_options || []).length - 1].min
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
    elsif survivor_confirm_triggered?
      @joker_choice_consume_start = System.uptime rescue 0.0
      @joker_consume_se_played = false
      pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue nil
    elsif survivor_cancel_triggered?
      @joker_options = []
      @state = :play
      draw_game
      return
    end
    draw_joker_choice
  rescue
    @joker_options = []
    @joker_choice_consume_start = nil
    @joker_consume_se_played = false
    @state = :play
  end

  def draw_joker_choice
    draw_game(false)
    bmp = @sprites["overlay"].bitmap
    pbSetSystemFont(bmp)
    x = 28
    y = 44
    w = Graphics.width - 56
    h = Graphics.height - y - 48
    now = System.uptime rescue 0.0
    choosing = !!@joker_choice_consume_start
    choose_elapsed = choosing ? (now - @joker_choice_consume_start.to_f) : 0.0
    choose_out = [[choose_elapsed / 0.28, 0.0].max, 1.0].min
    center_progress = [[(choose_elapsed - 0.28) / 0.22, 0.0].max, 1.0].min
    consume = [[(choose_elapsed - 0.50) / 0.42, 0.0].max, 1.0].min
    bmp.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0, 105))
    if !choosing || choose_out < 1.0
      panel_y = y + (choosing ? (choose_out * 42).to_i : 0)
      draw_panel(bmp, x, panel_y, w, h, rainbow_color((System.uptime rescue 0.0) * 90), Color.new(19, 31, 53)) rescue draw_soft_badge(bmp, x, panel_y, w, h, Color.new(18, 24, 38, 235))
      title_x = x + 16
      title_y = panel_y + 12
      title_w = w - 32
      title_h = 34
      draw_pixel_round_rect(bmp, title_x, title_y, title_w, title_h, Color.new(8, 13, 26)) rescue nil
      PokemonSurvivor.draw_text_center(bmp, _INTL("Lost Kecleon's deal"), title_x, title_y + 9, title_w, Color.new(255, 238, 160))
    end
    options = @joker_options || []
    gap = 7
    card_w = (w - 34) / 3
    card_h = h - 66
    options.each_with_index do |data, i|
      cx = x + 10 + (i * (card_w + gap))
      cy = y + 48
      chosen = choosing && i == @joker_choice_index.to_i
      if choosing
        if chosen
          target_x = x + ((w - card_w) / 2)
          target_y = y + 52
          ease = center_progress * center_progress * (3.0 - (2.0 * center_progress))
          cx = (cx + ((target_x - cx) * ease)).to_i
          cy = (cy + ((target_y - cy) * ease)).to_i
          cx += (Math.sin(consume * Math::PI * 8.0) * (1.0 - consume) * 4).to_i if consume > 0
        else
          cy += (choose_out * (Graphics.height - cy + 42 + (i * 16))).to_i
        end
      end
      next if choosing && !chosen && choose_out >= 1.0
      hold = choosing ? 0.0 : joker_reroll_hold_progress
      if hold > 0.0
        cx += (Math.sin(now * 42.0 + i * 1.7) * (hold * 8).ceil).to_i
        cy += (Math.cos(now * 34.0 + i) * [hold * 3, 1].max).to_i
      end
      draw_joker_slot(bmp, data, cx, cy, card_w, card_h, i == @joker_choice_index.to_i, consume, chosen)
    end
    draw_help(bmp, [[:left, ""], [:right, _INTL("Choose")], [:confirm, _INTL("Take")], [:action, _INTL("Hold Reroll: {1}", @rerolls_left.to_i)], [:cancel, _INTL("Cancel")]]) if respond_to?(:draw_help) && !choosing
    draw_tv_filter(bmp) if respond_to?(:draw_tv_filter) && PokemonSurvivor.performance_option?(:tv_filter)
  rescue
  end

  def draw_joker_slot(bitmap, data, x, y, w, h, selected, closing = 0.0, chosen = false)
    return if !data
    pulse = selected ? ((Math.sin((System.uptime rescue 0.0) * 8.0) + 1.0) * 0.5) : 0.0
    edge = rainbow_color((System.uptime rescue 0.0) * 130 + x)
    bg = selected ? Color.new(52 + (pulse * 18).to_i, 48 + (pulse * 16).to_i, 82 + (pulse * 22).to_i) : Color.new(18, 24, 42)
    draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(3, 6, 13))
    draw_pixel_round_rect(bitmap, x + 1, y + 1, w - 2, h - 2, edge)
    draw_pixel_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, Color.new(8, 13, 26))
    draw_pixel_round_rect(bitmap, x + 3, y + 3, w - 6, h - 6, bg)
    bitmap.fill_rect(x + 7, y + 6, w - 14, 3, edge)
    draw_joker_scrolling_title(bitmap, _INTL(data[:name].to_s), x + 10, y + 12, w - 20, 28, edge, Color.new(20, 20, 28))
    draw_soft_badge(bitmap, x + 8, y + 50, w - 16, 24, Color.new(28, 20, 42)) rescue nil
    draw_text_box(bitmap, _INTL(data[:tag].to_s), x + 12, y + 53, w - 24, 20, edge, Color.new(20, 20, 28), 2)
    bitmap.fill_rect(x + 8, y + 84, w - 16, 2, edge)
    draw_scrolling_wrapped_text(bitmap, _INTL(data[:desc].to_s), x + 12, y + 94, w - 24, h - 104, 22, Color.new(228, 232, 244), Color.new(34, 30, 42), selected && closing <= 0.0 ? [:joker, data[:id]] : nil) rescue draw_wrapped_text(bitmap, _INTL(data[:desc].to_s), x + 12, y + 94, w - 24, 22, 5, Color.new(228, 232, 244))
    if chosen && closing.to_f > 0
      burn_h = [(h * (closing.to_f ** 1.12)).to_i, h - 6].min
      ember_h = [(h * ([[closing.to_f - 0.08, 0.0].max, 1.0].min ** 1.05)).to_i, h - 8].min
      erase_y = y + h - 5 - burn_h
      ember_y = y + h - 3 - ember_h
      clear_overlay_area(bitmap, x - 2, erase_y, w + 4, burn_h + 6) if burn_h > 0 && respond_to?(:clear_overlay_area)
      if ember_h > 0 && ember_y > y + 4
        bitmap.fill_rect(x + 6, ember_y, w - 12, 3, Color.new(255, 238, 160))
        bitmap.fill_rect(x + 9, ember_y + 3, w - 18, 2, Color.new(255, 154, 62))
        flicker = ((System.uptime rescue 0.0) * 40).to_i % 12
        sx = x + 10 + flicker
        while sx < x + w - 10
          bitmap.fill_rect(sx, ember_y - 1, 1, 5, Color.new(255, 196, 96))
          sx += 24
        end
      end
    end
  rescue
  end

  def draw_joker_scrolling_title(bitmap, text, x, y, w, h, base, shadow)
    pbSetSystemFont(bitmap)
    label = text.to_s
    text_w = bitmap.text_size(label).width rescue 0
    if text_w <= w
      draw_text_box(bitmap, label, x, y + 3, w, h - 6, base, shadow, 2)
      return
    end
    line = cached_joker_title_bitmap(label, text_w + 34, h, base, shadow)
    return draw_text_box_ellipsis(bitmap, label, x, y, w, h, base, shadow, 2) if !line || line.disposed?
    max_offset = [line.width - w, 1].max
    offset = scroll_offset(max_offset, 3.2) rescue (((System.uptime rescue 0.0) * 54).to_i % max_offset)
    bitmap.blt(x, y, line, Rect.new(offset, 0, w, h))
  rescue
    draw_text_box_ellipsis(bitmap, text.to_s, x, y, w, h, base, shadow, 2) rescue nil
  end

  def cached_joker_title_bitmap(text, width, h, base, shadow)
    @joker_title_cache ||= {}
    width = [width.to_i, 1].max
    h = [h.to_i, 1].max
    key = [text, width, h, base.red, base.green, base.blue, base.alpha, shadow.red, shadow.green, shadow.blue, shadow.alpha].join(":")
    cached = @joker_title_cache[key]
    return cached if cached && !cached.disposed?
    bmp = Bitmap.new(width, h)
    pbSetSystemFont(bmp)
    pbDrawTextPositions(bmp, [[text, 0, 3, false, base, shadow], [text, width - 18, 3, false, base, shadow]])
    if @joker_title_cache.length > 24
      old_key = @joker_title_cache.keys.first
      old = @joker_title_cache.delete(old_key)
      old.dispose if old && !old.disposed?
    end
    @joker_title_cache[key] = bmp
    bmp
  rescue
    nil
  end

  def rainbow_color(seed = 0.0)
    t = ((seed.to_f / 60.0) % 6.0)
    c = 220
    x = (c * (1.0 - ((t % 2.0) - 1.0).abs)).round
    case t.floor
    when 0 then Color.new(c, x, 92)
    when 1 then Color.new(x, c, 92)
    when 2 then Color.new(92, c, x)
    when 3 then Color.new(92, x, c)
    when 4 then Color.new(x, 92, c)
    else Color.new(c, 92, x)
    end
  rescue
    Color.new(255, 220, 92)
  end

  alias draw_random_events_without_classic_endless_variety draw_random_events unless method_defined?(:draw_random_events_without_classic_endless_variety)
  def draw_random_events(bitmap)
    draw_random_events_without_classic_endless_variety(bitmap)
    draw_lost_kecleon(bitmap, @event_lost_kecleon) if @event_lost_kecleon
    draw_lost_kecleon_edge_indicator(bitmap, @event_lost_kecleon) if @event_lost_kecleon
    draw_event_hunt_edge_indicators(bitmap)
  rescue
  end

  def draw_lost_kecleon(bitmap, kecleon)
    return if !kecleon
    draw_lost_kecleon_activation_circle(bitmap, kecleon)
    return if !point_on_screen?(kecleon.x, kecleon.y, 64)
    state = kecleon.instance_variable_get(:@event_state) || :sleeping
    frames = state == :waking ? 9 : 2
    source = state == :waking ? cached_bitmap(lost_kecleon_graphics_dir, "KECLEON_Wake") : cached_bitmap(lost_kecleon_graphics_dir, "KECLEON_Sleep")
    frame = if state == :waking
              [[(kecleon.instance_variable_get(:@wake_timer).to_f * 9.0).floor, 0].max, frames - 1].min
            else
              ((@timer.to_f * 3.0).floor % frames)
            end
    draw_event_sleep_single_row_sprite(bitmap, source, world_screen_x(kecleon.x), world_screen_y(kecleon.y), frame, frames, world_screen_zoom(2.0)) if source
  rescue
  end

  def draw_lost_kecleon_activation_circle(bitmap, kecleon)
    timer = kecleon.instance_variable_get(:@activate_timer).to_f
    return if timer <= 0.0
    rate = [[timer / LOST_KECLEON_ACTIVATE_SECONDS.to_f, 0.0].max, 1.0].min
    circle = cached_event_egg_activation_circle(rate)
    return if !circle || circle.disposed?
    bitmap.blt((world_screen_x(kecleon.x) - circle.width / 2).round, (world_screen_y(kecleon.y + 2)).round, circle, Rect.new(0, 0, circle.width, circle.height), 245)
  rescue
  end

  def draw_lost_kecleon_edge_indicator(bitmap, kecleon)
    return if !kecleon || point_on_screen?(kecleon.x, kecleon.y, 48)
    pos = special_enemy_edge_indicator_position(kecleon)
    return if !pos
    frame = (((@timer || 0.0) * 12.0).floor)
    draw_vfx_frame(bitmap, "VFX_EXCLAIM", pos[0], pos[1], 1.0, pos[2], nil, frame)
  rescue
  end

  def draw_event_hunt_edge_indicators(bitmap)
    frame = (((@timer || 0.0) * 12.0).floor)
    event_hunt_enemies.each do |enemy|
      next if !enemy || enemy.hp.to_i <= 0 || point_on_screen?(enemy.x, enemy.y, 48)
      pos = special_enemy_edge_indicator_position(enemy)
      next if !pos
      draw_vfx_frame(bitmap, "VFX_EXCLAIM", pos[0], pos[1], 1.0, pos[2], nil, frame)
    end
  rescue
  end

  alias weighted_wild_item_name_without_endless_berry_rule weighted_wild_item_name unless method_defined?(:weighted_wild_item_name_without_endless_berry_rule)
  def weighted_wild_item_name
    if endless_mode?
      weighted = []
      PokemonSurvivor::WILD_ITEMS.each_pair do |name, data|
        next if name.to_s.upcase == "BERRY"
        data[:weight].to_i.times { weighted << name }
      end
      return weighted.sample || "EXPITEM"
    end
    weighted_wild_item_name_without_endless_berry_rule
  rescue
    endless_mode? ? "EXPITEM" : weighted_wild_item_name_without_endless_berry_rule
  end

  alias build_bitmap_preload_queue_without_classic_endless_events build_bitmap_preload_queue unless method_defined?(:build_bitmap_preload_queue_without_classic_endless_events)
  def build_bitmap_preload_queue
    queue = build_bitmap_preload_queue_without_classic_endless_events
    if PokemonSurvivor.const_defined?(:EVENT_DIR)
      ["GIMMIGHOUL", "DELIBIRD"].each { |name| queue << [PokemonSurvivor::EVENT_DIR, name] }
      seller_dir = "#{PokemonSurvivor::EVENT_DIR}/Seller"
      ["KECLEON_Sleep", "KECLEON_Wake"].each { |name| queue << [seller_dir, name] }
    end
    queue << [PokemonSurvivor::VFX_DIR, "VFX_EXCLAIM"] if PokemonSurvivor.const_defined?(:VFX_DIR)
    queue
  rescue
    build_bitmap_preload_queue_without_classic_endless_events rescue []
  end
  def self.classic_endless_event_translation_markers
    [
      _INTL("Lost Kecleon's deal"),
      _INTL("Joker"),
      _INTL("Glass Cannon"),
      _INTL("Damage +45%. Damage taken +22%."),
      _INTL("Iron Shell"),
      _INTL("Damage taken -28%. Speed -18%."),
      _INTL("Overclock"),
      _INTL("Skills recharge +22%. Enemy shots hurt +25%."),
      _INTL("Greedy Notes"),
      _INTL("EXP +45%. Pickup range -25%."),
      _INTL("Boss Bait"),
      _INTL("Boss damage +55%. Contact damage taken +15%."),
      _INTL("Wild Tempo"),
      _INTL("Speed +28%. Max HP -16%."),
      _INTL("Cursed Magnet"),
      _INTL("Pickup range +80%. Damage taken +18%."),
      _INTL("Burst Pact"),
      _INTL("Burst charge +70%. Damage -12%."),
      _INTL("Sharp Debt"),
      _INTL("Extra attack +1. Skill recharge -12%."),
      _INTL("Take")
    ]
  end
end
