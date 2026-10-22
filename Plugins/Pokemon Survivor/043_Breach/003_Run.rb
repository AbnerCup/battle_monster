#===============================================================================
# Tower transitions are reused; Breach progression and settlement stay separate.
#===============================================================================
module SurvivorBreachRun
  def breach_mode?
    !!@breach_run
  end

  def start_game(hero_name, mode = :classic)
    if mode == :breach || @run_mode == :breach
      @tower_transition_phase = nil
      @tower_transition_timer = 0.0
      @tower_fade_alpha = 0
      @post_run_auto_saved = false
    end
    @breach_run = mode == :breach
    @breach_shards = 0
    @breach_heal_purchases = 0
    @breach_rooms = 0
    @breach_combat_seconds = 0.0
    @breach_room_combat_seconds = 0.0
    @breach_hard_rooms = 0
    @breach_unfair_rooms = 0
    @breach_vaults = 0
    @breach_modules = []
    @breach_auto_sell_modules = false
    @breach_inventory = []
    @breach_module_drafts = []
    @breach_module_ranks = {}
    @breach_momentum_until = 0.0
    @breach_barrier_hp = 0
    @breach_sanctuary_shield = false
    @breach_reserve_used = false
    @breach_reserve_pending = 0.0
    @breach_salvage_fraction = 0
    @breach_fusions = 0
    @breach_skill_vouchers = 0
    @breach_skill_offers = nil
    @breach_extracted = false
    @breach_final_loot = nil
    unless @breach_run
      @breach_season = nil
      @breach_session = nil
      @breach_quests = nil
    end
    @breach_route = PokemonSurvivor::BREACH_ROUTES.first
    @breach_route_offers = nil
    @breach_route_offers_room = nil
    super(hero_name, breach_mode? ? :tower : mode)
    if breach_mode?
      @run_mode = :breach
      @random_event_timer = 35.0
      @run_objective_popup_text = _INTL("Clear rooms. Extract your loot.")
      breach_change_background
    end
  end

  def tower_mode?
    breach_mode? || super
  end

  def draw_hud(bitmap)
    super
    return unless breach_mode?
    threat = breach_current_threat
    text = _INTL("Threat: {1}%", threat)
    line = @bitmaps["__breach_threat_hud"]
    if !line || line.disposed?
      line = @bitmaps["__breach_threat_hud"] = Bitmap.new(178, 22)
      @breach_threat_text_key = nil
    end
    pbSetSmallFont(line)
    line.font.size = 20
    key = [text, line.font.name, line.font.size]
    if @breach_threat_text_key != key
      line.clear
      fitted = ellipsize_text(line, text, 176)
      pbDrawTextPositions(line, [[fitted, 0, 0, false, Color.new(255, 190, 115), Color.new(40, 40, 48)]])
      @breach_threat_text_key = key
    end
    # Leave a gap below Burst and keep clear of the helper starting at y=70.
    bitmap.blt(18, 47, line, Rect.new(0, 0, 178, 22))
  end

  def apply_roguelite_shop_upgrades
    super unless breach_mode?
  end

  def apply_endless_shop_upgrades
    super unless breach_mode?
  end

  def chestboss_bonus_available?
    breach_mode? ? false : super
  end

  def can_drop_moves_item?
    breach_mode? ? false : super
  end

  def spawn_wild_item
    super unless breach_mode?
  end

  def spawn_boss_reward_item(x, y, upgrade_count = 1)
    super unless breach_mode?
  end

  def spawn_boss_chest(x, y, upgrade_count = 1)
    super unless breach_mode?
  end

  def spawn_moves_item(x, y)
    super unless breach_mode?
  end

  def apply_wild_item(name, upgrade_count = 1)
    super unless breach_mode?
  end

  def request_upgrade(delay = 0.0, count = 1)
    return super unless breach_mode?
  end

  def request_move_upgrade(delay = 0.0, count = 1)
    return super unless breach_mode?
  end

  def gain_direct_xp(amount)
    return super unless breach_mode?
    value = [amount.to_i, 0].max
    # Keep fractional bonuses so small Shard drops are neither rounded up nor lost.
    bonus = value * (8 * breach_module_rank(:salvage) + breach_pickup_shard_bonus) + @breach_salvage_fraction.to_f
    whole = (bonus / 100.0 + 1e-9).floor
    @breach_shards += value + whole
    @breach_salvage_fraction = [bonus - whole * 100, 0.0].max
  end

  def breach_pickup_shard_bonus
    # Half the extra pickup percentage becomes Shard yield, including end-room magnets.
    [[((@pickup_mult || 1.0).to_f - 1.0) * 50.0, 0.0].max, 50.0].min
  end

  def xp_gem_icon_and_hue(value)
    return super unless breach_mode?
    ["SHARD", xp_gem_hue_from_ratio([value.to_f / 1000.0, 1.0].min)]
  end

  def tower_egg_floor?
    breach_mode? ? false : super
  end

  def random_event_enabled?
    breach_mode? || super
  end

  def sleep_event_enabled?
    breach_mode? ? false : super
  end

  def tower_floor_boss_floor?
    breach_mode? ? false : super
  end

  def update_game(dt)
    previous_timer = @timer
    waiting = breach_mode? && tower_floor_transition_active?
    if breach_mode? && !waiting && @state == :play &&
      @tower_floor_started && !@evolution_anim && !@run_finished
      @breach_room_combat_seconds = @breach_room_combat_seconds.to_f + [dt.to_f, 0.0].max
      breach_update_timed_threat(dt)
    end
    super
    @timer = previous_timer if waiting
  end

  def breach_timed_threat
    (@breach_combat_seconds.to_f / PokemonSurvivor::BREACH_THREAT_SECONDS_PER_POINT).floor
  end

  def breach_enemy_shard_drops_expired?
    breach_mode? && @breach_room_combat_seconds.to_f >= PokemonSurvivor::BREACH_ROOM_SHARD_SECONDS
  end

  def breach_update_timed_threat(dt)
    previous = breach_timed_threat
    difficulty = PokemonSurvivor::BREACH_DIFFICULTIES[@breach_route[:difficulty]]
    # Weighted combat time retains earned Threat when switching to an easier room.
    @breach_combat_seconds = @breach_combat_seconds.to_f + [dt.to_f, 0.0].max * difficulty[:time_threat_mult]
    return if breach_timed_threat == previous
    pressure = breach_pressure
    (@enemies || []).each { |enemy| breach_refresh_enemy_pressure(enemy, pressure, true) }
    (@tower_wisps || []).each { |seal| breach_refresh_enemy_pressure(seal, pressure, false) }
  end

  def breach_refresh_enemy_pressure(enemy, pressure, damaging)
    return unless enemy && enemy.hp.to_f > 0 && enemy.max_hp.to_f > 0
    initial = enemy.instance_variable_get(:@breach_spawn_pressure)
    return unless initial
    # Capture after elite modifiers, then use fixed bases to avoid rounding drift.
    base_hp = enemy.instance_variable_get(:@breach_pressure_base_hp)
    unless base_hp
      base_hp = enemy.max_hp.to_f / initial
      enemy.instance_variable_set(:@breach_pressure_base_hp, base_hp)
      if damaging
        enemy.instance_variable_set(:@breach_pressure_base_damage, enemy.damage.to_f / breach_damage_pressure(initial))
      end
    end
    hp_rate = enemy.hp.to_f / enemy.max_hp
    enemy.max_hp = [(base_hp * pressure).ceil, 1].max
    enemy.hp = [[(enemy.max_hp * hp_rate).round, 1].max, enemy.max_hp].min
    if damaging
      base_damage = enemy.instance_variable_get(:@breach_pressure_base_damage)
      enemy.damage = [(base_damage * breach_damage_pressure(pressure)).ceil, 1].max
    end
  end

  def update_tower_mode(dt)
    return super unless breach_mode?
    start_tower_floor unless @tower_floor_started
    update_tower_special_objective(dt)
    return if @state != :play || pending_sleep_reward?
    finish_tower_floor if tower_special_objective_complete?
  end

  def start_tower_floor
    return super unless breach_mode?
    @breach_room_combat_seconds = 0.0
    @breach_barrier_hp = (@hero.max_hp * 0.05 * breach_module_rank(:barrier)).floor
    if @breach_sanctuary_shield
      @breach_barrier_hp += (@hero.max_hp * 0.10).ceil
      @breach_sanctuary_shield = false
    end
    @breach_reserve_used = false
    @tower_floor_started = true
    @tower_floor_kills_start = @kills.to_i
    @tower_boss_defeated = false
    clear_tower_objective_state
    @tower_objective_type = @breach_route[:objective]
    @spawn_timer = 0.2
    start_tower_special_objective
    case @tower_objective_type
    when :hold_zone then @tower_objective_target = rand(6..30)
    when :zone_kills then @tower_objective_target = rand(12..60)
    end
  end

  def spawn_tower_wave
    return super unless breach_mode?
    return @spawn_timer = 0.3 if spawn_queue_pending?
    active = @enemies.count { |enemy| enemy.kind == :wild }
    cap = [18 + @breach_rooms / 3, 48].min
    enqueue_enemy_spawns(:wild, [4, cap - active].min) if active < cap
    @spawn_timer = [1.0 - @breach_rooms * 0.012, 0.40].max
  end

  def spawn_enemy(kind, forced_name = nil)
    before = @enemies && @enemies.length
    result = super
    if breach_mode? && before && @enemies.length > before
      enemy = @enemies.last
      breach_apply_enemy_stats(enemy)
    end
    result
  end

  def breach_apply_enemy_stats(enemy)
    # Replace inherited Tower/time/player-level multipliers, rather than stacking them.
    rooms = [@breach_rooms.to_i, 0].max
    pressure = breach_pressure
    boss = [:boss, :ultra_boss].include?(enemy.kind)
    mod = PokemonSurvivor::ENEMY_ARCHETYPES[enemy.archetype] || PokemonSurvivor::ENEMY_ARCHETYPES[:normal]
    species = [[PokemonSurvivor.species_base_total(enemy.name) / 400.0, 0.75].max, 1.5].min
    base_hp = boss ? 2400 + rooms * 350 : 45 + rooms * 7
    enemy.max_hp = [(base_hp * species * mod[:hp] * pressure * breach_route_stat_mult(:hp_mult)).ceil, 1].max
    enemy.max_hp *= 4 if enemy.kind == :wild && enemy.archetype == :elite && !@breach_spawning_elite_pair
    enemy.hp = enemy.max_hp
    base_damage = boss ? 18 + rooms * 0.65 : 6 + rooms * 0.45
    enemy.damage = [(base_damage * mod[:damage] * breach_damage_pressure(pressure) * breach_route_stat_mult(:damage_mult)).ceil, 1].max
    enemy.speed = (boss ? 0.72 : 0.88 + [rooms * 0.012, 0.48].min) * mod[:speed]
    enemy.value = [(boss ? 60 + rooms * 4 : 3 + rooms / 4) * mod[:value], 1].max.round
    enemy.instance_variable_set(:@breach_spawn_pressure, pressure)
    enemy.instance_variable_set(:@breach_pressure_base_hp, nil)
  end

  def breach_total_threat
    PokemonSurvivor.breach_earned_threat(@breach_rooms, @breach_hard_rooms, @breach_unfair_rooms)
  end

  def spawn_tower_elite_pair
    return super unless breach_mode?
    previous = (@enemies || []).dup
    @breach_spawning_elite_pair = true
    begin
      result = super
      ((@enemies || []) - previous).each do |enemy|
        next unless enemy.instance_variable_get(:@tower_objective_elite)
        enemy.max_hp *= 4
        enemy.hp = enemy.max_hp
      end
      result
    ensure
      @breach_spawning_elite_pair = false
    end
  end

  def breach_current_threat
    difficulty = PokemonSurvivor::BREACH_DIFFICULTIES[@breach_route[:difficulty]]
    # Route risk is immediate; score and loot are banked only after clearing it.
    pending = tower_floor_transition_active? ? 0 : difficulty[:threat]
    [breach_total_threat + pending + breach_timed_threat, 0].max
  end

  def breach_pressure
    threat = breach_current_threat / 100.0
    ramp = [[(@breach_rooms.to_i - 2) / 10.0, 0.0].max, 1.0].min
    # The opening ramp ends, but long-run stat growth keeps accelerating without a cap.
    escalation = [threat - 1.0, 0.0].max ** 1.35 * 0.10
    1.0 + Math.sqrt(threat) * 0.35 + (threat * 0.20 + escalation) * ramp
  end

  def breach_damage_pressure(pressure)
    1.0 + (pressure - 1.0) * (@breach_rooms.to_i < 3 ? 0.35 : 0.55)
  end

  def breach_route_stat_mult(stat)
    return 1.0 if @breach_rooms.to_i < 3
    PokemonSurvivor::BREACH_DIFFICULTIES[@breach_route[:difficulty]][stat]
  end

  def update_enemy_shot(enemy, dt)
    if breach_mode? && @breach_rooms.to_i >= 3 &&
       ([:boss, :ultra_boss].include?(enemy.kind) || enemy.archetype == :elite)
      # Only advance attack clocks; movement, status duration and projectile caps stay unchanged.
      dt *= 1.0 + [[(breach_pressure - 1.0) * 0.15, 0.0].max, 0.50].min
    end
    super(enemy, dt)
  end

  def spawn_tower_wisps(count)
    result = super
    if breach_mode?
      (@tower_wisps || []).each do |seal|
        seal.max_hp = ((600 + @breach_rooms.to_i * 45) * breach_pressure * breach_route_stat_mult(:hp_mult)).ceil
        seal.hp = seal.max_hp
        seal.instance_variable_set(:@breach_spawn_pressure, breach_pressure)
      end
    end
    result
  end

  def tower_wisp_projectile_damage
    damage = super
    breach_mode? ? ((8 + @breach_rooms.to_i * 0.4) * breach_damage_pressure(breach_pressure) * breach_route_stat_mult(:damage_mult)).ceil : damage
  end

  def on_tower_boss_defeated(enemy)
    return super unless breach_mode?
    @tower_bosses_defeated += 1
    @tower_boss_defeated = true
  end

  def finish_tower_floor
    return super unless breach_mode?
    return if tower_floor_transition_active?
    @breach_rooms += 1
    @breach_hard_rooms += 1 if @breach_route[:difficulty] == :hard
    @breach_unfair_rooms += 1 if @breach_route[:difficulty] == :unfair
    @breach_shards += PokemonSurvivor::BREACH_DIFFICULTIES[@breach_route[:difficulty]][:shards]
    @breach_shards += @breach_rooms * 10
    [2, 9999 - @level].min.times { @level += 1; apply_passive_level_bonus }
    check_hero_evolution
    case @breach_route[:id]
    when :training then @breach_shards += 90 + @breach_rooms * 15
    when :skills then @breach_skill_vouchers += 1
    when :modules, :boss then breach_award_module_choice
    when :skirmish
      [3, 9999 - @level].min.times { @level += 1; apply_passive_level_bonus }
      check_hero_evolution
    when :observatory
      @breach_combat_seconds = [@breach_combat_seconds.to_f - 20 * PokemonSurvivor::BREACH_THREAT_SECONDS_PER_POINT, 0.0].max
    when :foundry then 2.times { breach_award_module_choice }
    when :trial then @breach_skill_vouchers += 2
    when :healing
      @hero.hp = [@hero.hp + (@hero.max_hp * 0.30).ceil, @hero.max_hp].min
      @breach_sanctuary_shield = true
    end
    style = PokemonSurvivor.breach_season_style(@breach_season[:id])
    @breach_shards += 45 if style == :training && @breach_route[:id] == :training
    breach_award_module_choice if style == :modules && @breach_rooms % 4 == 0
    breach_award_module_choice if @breach_rooms % 3 == 0
    [@event_baby, @event_egg].compact.each do |companion|
      next if companion.hp.to_i <= 0
      rate = @breach_route[:id] == :healing ? 1.0 : 0.10
      companion.hp = [companion.hp + (companion.max_hp * rate).ceil, companion.max_hp].min
    end
    @breach_vaults += 1 if [:treasure, :boss].include?(@breach_route[:id])
    recovery = @breach_modules.select { |entry| entry[:id] == :recovery }.sum { |entry| entry[:rank] }
    @hero.hp = [@hero.hp + (@hero.max_hp * recovery * 0.02).ceil, @hero.max_hp].min
    @score = PokemonSurvivor.breach_score(@breach_rooms, breach_total_threat)
    @breach_barrier_hp = 0
    begin_tower_floor_transition
  end

  def update_tower_floor_transition(dt)
    return super unless breach_mode?
    @invuln = [@invuln.to_f, 0.25].max
    case @tower_transition_phase
    when :magnet
      @force_magnet_timer = 999.0
      update_xp(dt)
      update_tower_moves_magnet(dt)
      if @xp_gems.empty? && !tower_moves_items_pending?
        @force_magnet_timer = 0.0
        @tower_transition_phase = :fade_out
        @tower_transition_timer = 0.38
      end
    when :fade_out
      @tower_transition_timer -= dt
      @tower_fade_alpha = (255 * (1.0 - [@tower_transition_timer / 0.38, 0].max)).round
      if @tower_transition_timer <= 0
        @tower_fade_alpha = 255
        @tower_transition_phase = :camp
        if breach_open_camp == :leave
          return_to_select_menu
          breach_open_current_season
          return
        end
        return if @run_finished
        cleanup_tower_floor_before_next_start
        reset_player_for_tower_floor
        [@event_baby].compact.each { |baby| baby.x = @hero.x; baby.y = @hero.y }
        [@event_egg].compact.each do |event|
          event.x, event.y = random_event_visible_playable_spawn_position(120, 220)
        end
        @tower_floor = @breach_rooms + 1
        breach_change_background
        @tower_transition_phase = :fade_in
        @tower_transition_timer = 0.38
      end
    when :fade_in
      @tower_transition_timer -= dt
      @tower_fade_alpha = (255 * [@tower_transition_timer / 0.38, 0].max).round
      if @tower_transition_timer <= 0
        @tower_transition_phase = nil
        @tower_fade_alpha = 0
        start_tower_floor
      end
    end
  end

  def breach_change_background
    @bg_name = PokemonSurvivor.classic_background_names.sample.to_s
    @rush_bgm_name = @bg_name
    play_survivor_bgm_name(PokemonSurvivor.bgm_for_background(@bg_name))
  end

  def tower_objective_text
    return super unless breach_mode?
    target = @tower_objective_target.to_i
    count = @tower_objective_count.to_i
    seconds = [@tower_objective_timer.to_f.ceil, target].min
    case @tower_objective_type
    when :pressure then _INTL("Survive: {1}/{2}s", seconds, target)
    when :hold_zone then _INTL("Hold Zone: {1}/{2}s", seconds, target)
    when :zone_kills then _INTL("Zone KOs: {1}/{2}", count, target)
    when :break_seal then _INTL("Break Seal: {1}/{2}", count, target)
    when :elite_pair then _INTL("Elites: {1}/{2}", count, target)
    else _INTL("Defeat Boss")
    end
  end

  def update_random_events(dt)
    return super unless breach_mode?
    @random_event_timer -= dt unless @event_egg
    spawn_random_event_egg(true) if !@event_egg && @random_event_timer <= 0
    update_event_egg(dt) if @event_egg
    return if @state != :play
    update_event_baby(dt) if @event_baby
  end

  def spawn_random_event_egg(on_map = false)
    result = super
    @random_event_timer = 60.0 + rand(30) if breach_mode?
    result
  end

  def random_event_egg_hatch_duration
    duration = super
    breach_mode? ? [[duration * 0.5, 30.0].max, 60.0].min : duration
  end

  def event_egg_take_damage(egg, amount)
    return super unless breach_mode?
    super(egg, amount.to_f > 0 ? [(amount * 0.65).ceil, 1].max : 0)
  end

  def event_baby_take_damage(baby, amount)
    return super unless breach_mode?
    return if !baby || baby.hp.to_i <= 0 || amount.to_f <= 0
    super(baby, [(amount * 0.65).ceil, 1].max)
    baby.instance_variable_set(:@hit_invuln, 1.0) if baby.hp.to_i > 0
  end

  def classic_or_endless_events_enabled?
    breach_mode? ? false : super
  end

  def breach_module_change(entry, direction)
    data = PokemonSurvivor::BREACH_MODULES.find { |module_data| module_data[:id] == entry[:id] }
    return unless data
    if data[:ivar]
      current = instance_variable_get(data[:ivar]) || 1.0
      instance_variable_set(data[:ivar], current * data[:factor] ** (entry[:rank] * direction))
    elsif data[:speed]
      @hero.speed *= data[:speed] ** (entry[:rank] * direction)
    end
  end

  def breach_module_rank(id)
    return 0 unless breach_mode?
    (@breach_module_ranks || {})[id].to_i
  end

  def breach_award_module_choice
    @breach_module_drafts ||= []
    pool = PokemonSurvivor::BREACH_MODULES.map { |data| data[:id] }
    useful = pool.reject { |id| breach_module_rank(id) >= 3 }
    offers = useful.sample(3)
    offers.concat((pool - offers).sample(3 - offers.length)) if offers.length < 3
    if @breach_auto_sell_modules && breach_auto_sell_modules_available?
      amount = offers.map { |id| breach_reserve_module_sale_value(id) }.max.to_i
      breach_gain_module_sale_shards(amount)
      return
    end
    @breach_module_drafts << offers
  end

  def breach_take_module_choice(index)
    offers = (@breach_module_drafts || []).first
    return false unless offers && index.is_a?(Integer) && index >= 0 && index < offers.length
    @breach_inventory << offers[index]
    @breach_module_drafts.shift
    true
  end

  def focus_step_cooldown_duration
    duration = super
    breach_mode? ? [duration * (0.95 ** breach_module_rank(:dash)), 3.0].max : duration
  end

  def start_focus_step
    previous = @focus_step_anim
    result = super
    if breach_mode? && @focus_step_anim && !@focus_step_anim.equal?(previous)
      @breach_momentum_until = @timer.to_f + 3.0
    end
    result
  end

  def damage_enemy(enemy, base_damage, attack_type, color = nil, source = nil)
    return super unless breach_mode? && enemy && enemy.hp > 0
    mult = 1.0
    if [:boss, :chest, :ultra_boss, :ultra_chest, :tower_wisp].include?(enemy.kind) ||
       enemy.instance_variable_get(:@tower_objective_elite) || enemy.archetype == :elite
      mult *= 1.0 + 0.10 * breach_module_rank(:precision)
    end
    mult *= 1.0 + 0.10 * breach_module_rank(:momentum) if @timer.to_f < @breach_momentum_until.to_f
    mult *= 1.0 + 0.08 * breach_module_rank(:execution) if enemy.hp * 4 < enemy.max_hp
    skill = source.respond_to?(:source_skill) ? source.source_skill : source
    mult *= 1.0 + 0.10 * breach_module_rank(:companion) if skill.is_a?(Hash) && skill[:breach_companion]
    super(enemy, mult == 1.0 ? base_damage : (base_damage * mult).ceil, attack_type, color, source)
  end

  # Called after normal damage resistance, before fatal-hit passives and HP loss.
  def breach_absorb_damage(amount, invuln_time)
    return amount unless breach_mode? && @hero
    if @hero.hp * 10 < @hero.max_hp * 3
      amount = (amount * (0.95 ** breach_module_rank(:last_stand))).ceil
    end
    absorbed = [amount, @breach_barrier_hp.to_i].min
    @breach_barrier_hp = @breach_barrier_hp.to_i - absorbed
    if absorbed > 0
      @invuln = [@invuln.to_f, invuln_time.to_f].max
      set_hero_item_flash(Color.new(120, 210, 255), 0.18)
    end
    amount - absorbed
  end

  def event_baby_max_hp(shiny = false)
    value = super
    return value unless breach_mode?
    (value * 1.5 * (1.0 + 0.10 * breach_module_rank(:companion))).round
  end

  def sync_event_baby_stats(baby)
    return super unless breach_mode? && baby
    rank = breach_module_rank(:companion)
    changed = baby.instance_variable_get(:@breach_companion_rank).to_i != rank
    hp = baby.hp
    result = super
    baby.hp = [hp, baby.max_hp].min if changed
    baby.instance_variable_set(:@breach_companion_rank, rank)
    result
  end

  def spawn_event_baby_projectile(baby)
    first = (@projectiles || []).length
    result = super
    if breach_mode?
      first.upto(@projectiles.length - 1) do |i|
        p = @projectiles[i]
        p.source_skill = p.source_skill.merge(breach_companion: true) if p.source_skill.is_a?(Hash)
      end
    end
    result
  end

  def start_ultimate_gauge_drain(data)
    result = super
    if breach_mode? && !@breach_reserve_used && breach_module_rank(:reserve) > 0
      @breach_reserve_used = true
      @breach_reserve_pending = 0.05 * breach_module_rank(:reserve)
    end
    result
  end

  def update_ultimate(dt)
    result = super
    if breach_mode? && @breach_reserve_pending.to_f > 0 && @ultimate_drain_timer.to_f <= 0 && !@charizard_mega_active
      fraction = @breach_reserve_pending
      @breach_reserve_pending = 0.0
      if @ultimate_data && breach_module_rank(:reserve) > 0
        cap = @ultimate_data[:cooldown].to_f
        @ultimate_charge = [@ultimate_charge.to_f + cap * fraction, cap].min
      end
    end
    result
  end

  def breach_install_module(inventory_index, replace_index = nil)
    return false unless inventory_index.is_a?(Integer) && inventory_index >= 0 && inventory_index < @breach_inventory.length
    id = @breach_inventory[inventory_index]
    return false unless id
    if @breach_modules.any? { |entry| entry[:id] == id && entry[:rank] >= 3 }
      @breach_inventory.delete_at(inventory_index)
      @breach_shards += 40
      return true
    end
    existing = @breach_modules.find { |entry| entry[:id] == id && entry[:rank] < 3 }
    if existing
      breach_module_change(existing, -1)
      existing[:rank] += 1
      breach_module_change(existing, 1)
      @breach_fusions += 1
    else
      if @breach_modules.length >= 6
        return false unless replace_index.is_a?(Integer) && replace_index >= 0 && @breach_modules[replace_index]
        old = @breach_modules.delete_at(replace_index)
        breach_module_change(old, -1)
        @breach_shards += 20 * old[:rank]
      end
      entry = {id: id, rank: 1}
      @breach_modules << entry
      breach_module_change(entry, 1)
    end
    @breach_inventory.delete_at(inventory_index)
    breach_refresh_module_effects
    true
  end

  def breach_module_sale_value(equipped, index)
    list = equipped ? @breach_modules : @breach_inventory
    return 0 unless index.is_a?(Integer) && index >= 0 && list && list[index]
    return 20 * list[index][:rank].to_i if equipped
    breach_reserve_module_sale_value(list[index])
  end

  def breach_reserve_module_sale_value(id)
    breach_module_rank(id) >= 3 ? 40 : 20
  end

  def breach_auto_sell_modules_available?
    breach_mode? && (@breach_modules || []).length == 6 &&
      @breach_modules.all? { |entry| entry[:rank].to_i >= 3 }
  end

  def breach_reserve_sale_total
    (@breach_inventory || []).sum { |id| breach_reserve_module_sale_value(id) }
  end

  def breach_gain_module_sale_shards(amount)
    return if amount.to_i <= 0
    @breach_shards += amount
    enqueue_run_reward_popup({ icon: "SHARD", icon_dir: PokemonSurvivor::ITEM_DIR,
      amount: amount, duration: 2.55 })
  end

  def breach_sell_all_reserve
    amount = breach_reserve_sale_total
    return false if amount <= 0
    @breach_inventory.clear
    breach_gain_module_sale_shards(amount)
    true
  end

  def breach_sell_module(equipped, index)
    amount = breach_module_sale_value(equipped, index)
    return false if amount <= 0
    if equipped
      entry = @breach_modules.delete_at(index)
      breach_module_change(entry, -1)
    else
      @breach_inventory.delete_at(index)
    end
    @breach_shards += amount
    breach_refresh_module_effects
    true
  end

  def breach_refresh_module_effects
    @breach_auto_sell_modules = false unless breach_auto_sell_modules_available?
    @breach_module_ranks = {}
    @breach_modules.each { |entry| @breach_module_ranks[entry[:id]] = entry[:rank] }
    sync_event_baby_stats(@event_baby) if @event_baby
    @breach_reserve_pending = 0.0 if breach_module_rank(:reserve) == 0
    if @hero
      maximum = (@hero.max_hp * 0.05 * breach_module_rank(:barrier)).floor
      @breach_barrier_hp = [@breach_barrier_hp.to_i, maximum].min
    end
  end

  def leaderboard_run_won?
    breach_mode? ? !!@breach_extracted : super
  end

  def leaderboard_share_eligible?
    return super unless breach_mode?
    !@run_abandoned && @breach_rooms > 0 && !@leaderboard_submitted &&
      PokemonSurvivor.breach_seconds_left(@breach_season) > 0
  end

  def finish_run(*args)
    return super unless breach_mode?
    return if @run_finished
    @run_finished = true
    @tower_transition_phase = nil
    @tower_fade_alpha = 0
    clear_transient_run_state
    cleanup_classic_endless_variety_events
    @score = PokemonSurvivor.breach_score(@breach_rooms, breach_total_threat)
    entry = PokemonSurvivor.breach_progress(@breach_season[:id])
    stats = entry[:stats]
    unless @run_abandoned
      { rooms: @breach_rooms, runs: @breach_rooms > 0 ? 1 : 0, kills: @kills, extractions: @breach_extracted ? 1 : 0,
        fusions: @breach_fusions, levels: [@level - 1, 0].max,
        threat: breach_total_threat, unfair_rooms: @breach_unfair_rooms }.each do |key, value|
        stats[key] = stats[key].to_i + value.to_i
      end
    end
    entry[:pokemon] |= [PokemonSurvivor.species_key(@hero_base_name)] if @breach_extracted && !@run_abandoned
    loot = PokemonSurvivor.breach_loot(@breach_rooms, @breach_hard_rooms, @breach_unfair_rooms, @breach_extracted)
    loot = {candies: 0, fragments: 0} if @run_abandoned
    PokemonSurvivor.add_candy_currency(loot[:candies])
    PokemonSurvivor.add_shop_currency(loot[:fragments])
    @run_unlock_messages = []
    unless @run_abandoned
      unlock_from_run(PokemonSurvivor.species_key(@hero_base_name), @timer.to_f)
      unlock_population_requirements
      unlock_mew_if_ready
    end
    @breach_final_loot = loot
    @breach_result_index = 0
    @seasonal_result_ready = false
    @state = :gameover
    @result_text = @breach_extracted ? _INTL("Extraction successful!") : _INTL("Breach ended")
    PokemonSurvivorAchievements.check_additional_counters(true, :breach) if defined?(PokemonSurvivorAchievements)
    auto_save_successful_run_once
  end

  def update_gameover
    return super unless breach_mode?
    breach_result_menu
  end

  def draw_gameover
    super
  end

  def return_to_select_menu
    @breach_run = false
    super
  end
end
