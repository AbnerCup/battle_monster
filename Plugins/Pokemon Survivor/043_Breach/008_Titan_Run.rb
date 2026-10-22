# Titan is a separate run type. The existing Breach flag is used only for its
# no-healing gates; breach_mode? remains false, so no room/Shard logic is entered.
module SurvivorTitanHealth
  def hp=(value)
    value = [value, @hp].min if @titan_no_heal && @hp
    super(value)
  end
end

class PokemonSurvivorTitanBoss < PokemonSurvivorEntity
  attr_accessor :titan_ledger

  def hp
    @titan_ledger ? @titan_ledger.hp + @titan_ledger.shield : super
  end

  def hp=(value)
    return super unless @titan_ledger
    @titan_ledger.hit([hp - value.to_i, 0].max)
  end
end

module SurvivorTitanRun
  def titan_mode?
    !!@titan_run
  end

  def breach_mode?
    !titan_mode? && super
  end

  def start_game(hero_name, mode = :classic)
    return if !PokemonSurvivor.hero_unlocked?(hero_name)
    @titan_run = mode == :titan
    @titan_training_ranks = if @titan_run && @titan_store && @titan_session && @titan_store.season_id == @titan_session[:season_id]
                             @titan_store.snapshot[:training]
                           else
                             {}
                           end
    @titan_boss = @titan_ai = @titan_cinematic = @titan_receipt = nil
    @titan_arena = nil
    @titan_pattern_warnings = []
    titan_reset_escape_state
    @titan_result_damage = nil
    @seasonal_result_ready = false
    @titan_camera_x = @titan_camera_y = 0.0
    @titan_final = @titan_won = false
    @titan_swarm_minute = 0
    @titan_queued_weak = 0
    @titan_preparing = @titan_run
    @post_run_auto_saved = false
    @titan_session = nil unless @titan_run
    super(hero_name, @titan_run ? :classic : mode)
    return unless @titan_run
    @run_mode = :titan
    @xp_next = survivor_xp_next_for_level(@level)
    @breach_run = true
    @run_speed_available = false
    @run_speed = 1.0
    @bg_name = PokemonSurvivor::Titan.season(@titan_session[:season_id])[:background]
    @run_objective_popup_text = _INTL("Break the eight seals before 5:00.")
    @random_event_timer = 45.0
    @spawn_timer = 0.5
    @boss_timer = @chest_timer = @item_timer = 999_999.0
    @tower_objective_type = :break_seal
    @titan_weak_pool = PokemonSurvivor.wild_names.reject { |name| PokemonSurvivor.doom_enemy?(name) }.select do |name|
      types = PokemonSurvivor.species_types(name)
      (@hero.types || []).any? { |type| PokemonSurvivor.type_multiplier(type, types) > 1.0 }
    end
    spawn_tower_wisps(PokemonSurvivor::Titan::SEAL_COUNT)
    titan_spread_seals
    titan_play_music("Seasons")
  end

  def titan_spread_seals
    return unless titan_mode?
    cx = Graphics.width / 2.0 - @world_x.to_f
    cy = Graphics.height / 2.0 - @world_y.to_f
    limit_x, limit_y = world_limit_x, world_limit_y
    count = @tower_wisps.length
    # A bounded ring around the start, independent of the map's overall size.
    @tower_wisps.each_with_index do |seal, i|
      angle = Math::PI * 2.0 * i / count + (rand - 0.5) * 0.20
      dx, dy = Math.cos(angle), Math.sin(angle)
      radius = 220.0 + rand * 100.0
      margin = seal.radius.to_f + 54
      radius = [radius, [limit_x - margin, 0].max / dx.abs].min if dx.abs > 0.000001
      radius = [radius, [limit_y - margin, 0].max / dy.abs].min if dy.abs > 0.000001
      x = cx + dx * radius
      y = cy + dy * radius
      seal.x, seal.y = clamp_world_spawn_position(x, y, margin)
      seal.hp = seal.max_hp = 36_000
    end
    invalidate_enemy_grid
  end

  def titan_apply_loadout(passives, moves)
    raise ArgumentError unless passives.length == 4 && moves.length == 2
    moves.each { |upgrade| apply_upgrade(upgrade) }
    raise ArgumentError, "Titan requires three skills" unless @learned_skills.length == 3
    passives.each { |upgrade| titan_max_upgrade(upgrade) }
    titan_max_skill_upgrades
    @hero.hp = @hero.max_hp
    @hero.singleton_class.prepend(SurvivorTitanHealth)
    @hero.instance_variable_set(:@titan_no_heal, true)
    @titan_preparing = false
    @pending_upgrade = false
    @pending_upgrade_count = 0
    @pending_upgrade_queue = []
    @timer = 0.0
    @last_time = System.uptime
    @accumulator = 0.0
  end

  def titan_max_upgrade(upgrade)
    remaining = [upgrade[:max].to_i - @upgrade_levels[upgrade[:id]].to_i, 0].max
    remaining.times { apply_upgrade(upgrade) }
  end

  def titan_max_skill_upgrades
    active_skill_upgrades.group_by { |upgrade| upgrade[:id] }.each_value do |entries|
      titan_max_upgrade(entries.max_by { |upgrade| upgrade[:max].to_i })
    end
  end

  def apply_hero_growth_stage(*args)
    result = super
    titan_max_skill_upgrades if titan_mode? && !@titan_preparing
    result
  end

  def apply_roguelite_shop_upgrades
    return super unless titan_mode?
    effect = proc { |key| PokemonSurvivor::Titan.training_effect(@titan_training_ranks || {}, key) }
    @hero.max_hp = [(@hero.max_hp * (1.0 + effect.call(:max_hp_percent) / 100.0)).round, 1].max
    @hero.hp = @hero.max_hp
    @damage_mult *= 1.0 + effect.call(:damage_percent) / 100.0
    @xp_gain_mult *= 1.0 + effect.call(:xp_gain_percent) / 100.0
    @burst_charge_mult = (@burst_charge_mult || 1.0) * (1.0 + effect.call(:burst_charge_percent) / 100.0)
    @hero.speed *= 1.0 + effect.call(:speed_percent) / 100.0
    if @ultimate_data
      @ultimate_charge = @ultimate_data[:cooldown].to_f * effect.call(:starting_burst_percent) / 100.0
    end
    @bonus_fatal_guard_charges = @bonus_fatal_guard_charges.to_i + effect.call(:fatal_guard_charges)
    @bonus_fatal_guard_enabled = @bonus_fatal_guard_charges > 0
    @rerolls_left = @rerolls_left.to_i + effect.call(:reroll_bonus)
    @bans_left = @bans_left.to_i + effect.call(:ban_bonus)
  end

  def apply_endless_shop_upgrades
    super unless titan_mode?
  end

  def world_walls_enabled?
    titan_mode? || super
  end

  def titan_begin_arena_shrink
    return if @titan_arena
    lx, ly = world_limit_x.to_f, world_limit_y.to_f
    hx, hy = lx * 0.5, ly * 0.5
    cx = [[@world_x.to_f, -lx + hx].max, lx - hx].min
    cy = [[@world_y.to_f, -ly + hy].max, ly - hy].min
    @titan_arena = { elapsed: 0.0, from: [-lx, lx, -ly, ly],
      to: [cx - hx, cx + hx, cy - hy, cy + hy], bounds: [-lx, lx, -ly, ly] }
  end

  def clamp_world_scroll(sx, sy)
    return super unless titan_mode? && @titan_arena
    left, right, top, bottom = @titan_arena[:bounds]
    x, y = @world_x.to_f + sx, @world_y.to_f + sy
    flash_rush_wall(:left) if x < left
    flash_rush_wall(:right) if x > right
    flash_rush_wall(:top) if y < top
    flash_rush_wall(:bottom) if y > bottom
    [[[x, left].max, right].min - @world_x.to_f,
     [[y, top].max, bottom].min - @world_y.to_f]
  end

  def clamp_world_spawn_position(x, y, margin = 40)
    return super unless titan_mode? && @titan_arena
    left, right, top, bottom = @titan_arena[:bounds]
    mx = [margin.to_f, (right - left) * 0.5].min
    my = [margin.to_f, (bottom - top) * 0.5].min
    ox, oy = Graphics.width / 2.0 - @world_x.to_f, Graphics.height / 2.0 - @world_y.to_f
    [[[x, ox + left + mx].max, ox + right - mx].min,
     [[y, oy + top + my].max, oy + bottom - my].min]
  end

  def titan_update_arena(dt)
    return unless @titan_arena
    arena = @titan_arena
    if arena[:elapsed] < 8.0
      arena[:elapsed] = [arena[:elapsed] + dt, 8.0].min
      t = arena[:elapsed] / 8.0
      t = t * t * (3.0 - 2.0 * t)
      4.times { |i| arena[:bounds][i] = arena[:from][i] + (arena[:to][i] - arena[:from][i]) * t }
    end
    # Keep the camera/player inside without changing any world-space positions.
    sx, sy = clamp_world_scroll(0.0, 0.0)
    if sx != 0.0 || sy != 0.0
      @world_x += sx
      @world_y += sy
      shift_world_entities(-sx, -sy)
    end
    moved = false
    (@enemies || []).each do |enemy|
      x, y = clamp_world_spawn_position(enemy.x, enemy.y, enemy.radius)
      moved ||= x != enemy.x || y != enemy.y
      enemy.x, enemy.y = x, y
    end
    invalidate_enemy_grid if moved
    (@xp_gems || []).each do |gem|
      gem.x, gem.y = clamp_world_spawn_position(gem.x, gem.y, gem.radius)
    end
    [@event_egg, @event_baby].each do |entity|
      next unless entity
      entity.x, entity.y = clamp_world_spawn_position(entity.x, entity.y, entity.radius)
    end
  end

  def blazing_striker_touches_wall?(projectile)
    return super unless titan_mode? && @titan_arena
    left, right, top, bottom = @titan_arena[:bounds]
    x = projectile.x + @world_x.to_f - Graphics.width / 2.0
    y = projectile.y + @world_y.to_f - Graphics.height / 2.0
    r = projectile.radius.to_f
    x - r <= left || x + r >= right || y - r <= top || y + r >= bottom
  end

  def random_event_enabled?
    titan_mode? || super
  end

  def sleep_event_enabled?
    titan_mode? ? false : super
  end

  def classic_or_endless_events_enabled?
    titan_mode? ? false : super
  end

  [:spawn_boss, :spawn_chest, :update_ultra_spawns, :spawn_wild_item,
   :chestboss_bonus_available?, :can_drop_moves_item?].each do |method|
    define_method(method) { |*args| titan_mode? ? false : super(*args) }
  end
  [:request_upgrade, :request_move_upgrade, :spawn_boss_reward_item,
   :spawn_boss_chest, :spawn_moves_item, :apply_wild_item,
   :heal_event_baby, :heal_event_baby_rate].each do |method|
    define_method(method) { |*args| super(*args) unless titan_mode? }
  end

  def hero_take_damage(amount, invuln_time = 0.55)
    # Broken Disguise must not negate a lethal hit through its healing branch.
    key = @passive_key
    @passive_key = nil if titan_mode? && key == :MIMIKYU
    super
  ensure
    @passive_key = key
  end

  def tower_wisp_targets_for(x, y, radius)
    return super unless titan_mode?
    (@tower_wisps || []).select do |seal|
      seal.hp > 0 && point_on_screen?(seal.x, seal.y, 64) &&
        point_distance_sq(x, y, seal.x, seal.y) <= radius * radius
    end
  end

  def update_game(dt)
    return super unless titan_mode?
    return if @titan_preparing
    if @titan_cinematic
      titan_update_cinematic(dt)
      return
    end
    titan_update_arena(dt) unless @evolution_anim
    if @titan_boss && @titan_boss.hp <= 0
      @titan_won = true
      play_survivor_cry(@titan_boss.name)
      finish_run
      return
    end
    if !@titan_boss && (@timer >= PokemonSurvivor::Titan::BOSS_TIME ||
        (@tower_wisps && @tower_wisps.none? { |seal| seal.hp > 0 }))
      titan_spawn_boss
      return
    elsif @timer >= 600 && !@titan_final
      @titan_final = true
      @spawn_queue.clear
      @spawn_queue_index = 0
      @enemies.select! { |enemy| enemy.equal?(@titan_boss) }
      @projectiles.delete_if { |p| p.owner == :enemy }
      @titan_pattern_warnings.clear
      titan_reset_escape_state
      @titan_cinematic = { phase: :out, elapsed: 0.0, evolve: true }
      return
    end
    if @timer >= 900 && !@doom_final_started
      @doom_final_started = true
      @spawn_timer = 0
    end
    unless @evolution_anim
      minute = (@timer / 60).floor
      if minute > @titan_swarm_minute && minute < 5
        @titan_swarm_minute = minute
        @titan_queued_weak += 24
        enqueue_enemy_spawns(:wild, 24)
        @swarm_alert_active_timer = 6.0
      end
      @swarm_alert_active_timer = [@swarm_alert_active_timer.to_f - dt, 0.0].max
      update_tower_wisp_attacks(dt) if @timer < 300
      if @titan_ai && @titan_boss.hp > 0
        boss = @titan_boss
        aim = Math.atan2(@hero.y - boss.y, @hero.x - boss.x)
        distance = Math.sqrt((@hero.x - boss.x)**2 + (@hero.y - boss.y)**2)
        offscreen = !point_on_screen?(boss.x, boss.y, boss.radius)
        escape_response = titan_update_escape_response(dt, distance, offscreen)
        unless escape_response
          @titan_ai.update(dt, aim, distance, offscreen) { |angle, pattern| titan_fire_pattern(angle, pattern) }
        end
        titan_update_pattern_warnings(dt)
        boss.speed = escape_response ? 0.0 : 0.9 * @titan_ai.speed_multiplier
        # Catch up even with trained movement speed; status effects still apply.
        if !escape_response && @titan_ai.pursuing?
          boss.speed = [boss.speed, @hero.speed.to_f * (offscreen ? 1.65 : 1.15)].max
          boss.speed = [boss.speed, [distance - 100.0, 0.0].max / (60.0 * dt)].min if dt > 0
        end
        boss.damage = (40 * @titan_ai.contact_multiplier).round
        boss.damage *= 2 if @titan_charge && @titan_charge[:phase] == :rush
      end
    end
    super
  end

  def spawn_wave
    return super unless titan_mode?
    if @timer >= 900
      titan_spawn_clone
      @spawn_timer = 0.8
    elsif @timer < 600
      enqueue_enemy_spawns(:wild, 3) if @enemies.count { |e| e.kind == :wild } < 70
      @spawn_timer = 1.4
    else
      @spawn_timer = 1.0
    end
  end

  def spawn_enemy(kind, forced_name = nil)
    return if titan_mode? && @timer >= 600
    if titan_mode? && kind == :wild && @titan_queued_weak.to_i > 0
      @titan_queued_weak -= 1
      forced_name = @titan_weak_pool.sample unless @titan_weak_pool.empty?
    end
    before = @enemies.length
    result = super(kind, forced_name)
    if titan_mode? && @enemies.length > before && kind == :wild && (enemy = @enemies.last) && enemy.kind == :wild
      enemy.max_hp = [30 + @level * 2, 1500].min
      enemy.hp = enemy.max_hp
      enemy.damage = 8 + (@timer / 90).to_i
      enemy.shooter = false
    end
    result
  end

  def titan_spawn_boss
    titan_begin_arena_shrink
    data = PokemonSurvivor::Titan.season(@titan_session[:season_id])
    x, y = tower_objective_spawn_point(260, 65)
    boss = PokemonSurvivorTitanBoss.new(:ultra_boss, data[:boss].to_s, x, y)
    remaining = @tower_wisps.count { |seal| seal.hp > 0 }
    @titan_shield_total = PokemonSurvivor::Titan.shield_hp(@titan_session[:total_hp], remaining)
    boss.titan_ledger = PokemonSurvivor::Titan::DamageLedger.new(@titan_session[:hp], @titan_shield_total)
    boss.max_hp = @titan_session[:total_hp] + @titan_shield_total
    boss.radius = 28
    boss.speed = 0
    boss.damage = 40
    boss.value = 0
    boss.shooter = false
    @titan_boss = boss
    @titan_ai = PokemonSurvivor::Titan::BossPatterns.new(data[:patterns])
    titan_set_boss_form(false)
    @enemies << boss
    @tower_wisps.clear
    @tower_objective_type = nil
    invalidate_enemy_grid
    @titan_cinematic = { phase: :out, elapsed: 0.0, evolve: false }
  end

  def titan_set_boss_form(final)
    data = PokemonSurvivor::Titan.season(@titan_session[:season_id])
    name = data[final ? :final : :boss]
    @titan_final_form = nil unless final
    if final && data[:final_forms]
      @titan_final_form ||= data[:final_forms].sample
      name = @titan_final_form
    end
    boss = @titan_boss
    boss.name = name.to_s
    boss.types = data[:types] ? data[:types].dup : PokemonSurvivor.species_types(data[:species] || name)
    boss.attack_type = data[:projectile][:type]
    boss.bitmap = cached_bitmap(PokemonSurvivor::Titan::BOSS_DIRECTORY, name.to_s)
    PokemonSurvivor.register_eight_direction_bitmap(boss.bitmap, data[:frames][name][:walk])
    @titan_shoot_bitmap = cached_bitmap(PokemonSurvivor::Titan::BOSS_DIRECTORY, "#{name}_Shoot")
    @titan_shoot_frame_count = data[:frames][name][@titan_shoot_bitmap ? :shoot : :walk]
    @titan_shoot_bitmap ||= boss.bitmap
    PokemonSurvivor.register_eight_direction_bitmap(@titan_shoot_bitmap, @titan_shoot_frame_count)
    boss.charset_directions = 8
    boss.direction = direction_from_vector_8(@hero.x - boss.x, @hero.y - boss.y)
  end

  def titan_update_cinematic(dt)
    scene = @titan_cinematic
    scene[:elapsed] += dt
    t = scene[:elapsed]
    boss = @titan_boss
    dx, dy = boss.x - Graphics.width / 2.0, boss.y - Graphics.height / 2.0
    case scene[:phase]
    when :out
      p = [t, 1.0].min
      p = p * p * (3 - 2 * p)
      @titan_camera_x, @titan_camera_y = dx * p, dy * p
      if t >= 1.0
        scene[:phase], scene[:elapsed] = scene[:evolve] ? :evolve : :shoot, 0.0
        play_survivor_cry(titan_boss_species) unless scene[:evolve]
      end
    when :evolve
      if t >= 0.65 && !scene[:changed]
        scene[:changed] = true
        titan_set_boss_form(true)
        profile = case @titan_boss.name.to_sym
                  when :KYUREM_1 then :kyurem_fire
                  when :KYUREM_2 then :kyurem_electric
                  end
        @titan_ai.evolve!(profile)
      end
      if t >= 1.3
        scene[:phase], scene[:elapsed] = :shoot, 0.0
        play_survivor_cry(titan_boss_species)
      end
    when :shoot
      scene[:phase], scene[:elapsed] = :back, 0.0 if t >= titan_shoot_frames / 12.0
    when :back
      p = [t, 1.0].min
      p = p * p * (3 - 2 * p)
      @titan_camera_x, @titan_camera_y = dx * (1.0 - p), dy * (1.0 - p)
      if t >= 1.0
        @titan_camera_x = @titan_camera_y = 0.0
        @titan_cinematic = nil
        titan_play_music(scene[:evolve] ? PokemonSurvivor::Titan::BOSS_PHASE2_BGM : PokemonSurvivor::Titan::BOSS_BGM)
      end
    end
  end

  def titan_fire(angle)
    return nil if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
    boss = @titan_boss
    p = PokemonSurvivorEntity.new(:enemy_projectile, boss.name, boss.x, boss.y)
    config = PokemonSurvivor::Titan.season(@titan_session[:season_id])[:projectile]
    if PokemonSurvivor::Titan.season(@titan_session[:season_id])[:patterns] == :kyurem
      if [:satellites, :chain].include?(@titan_cast_pattern)
        config = { vfx: "VFX_DRAGON3", type: :DRAGON, visual_scale: 2.0 }
      elsif [:aimed, :frost_fan, :ice_barrage].include?(@titan_cast_pattern)
        config = { vfx: "VFX_ICE6", type: :ICE, visual_scale: 2.0 }
      elsif [:spiral, :fusion_flare, :fusion_bolt].include?(@titan_cast_pattern)
        fire = boss.name.to_sym == :KYUREM_1
        config = { vfx: fire ? "VFX_FIRE8" : "VFX_ELECTRIC2_SHOT",
          type: fire ? :FIRE : :ELECTRIC, visual_scale: 2.0 }
      end
    end
    p.owner, p.attack_type = :enemy, config[:type]
    p.damage = (18 * @titan_ai.projectile_multiplier).round
    p.speed, p.pierce, p.radius = 4.0, 1, PokemonSurvivor::PROJECTILE_RADIUS * 2
    p.vx, p.vy = Math.cos(angle), Math.sin(angle)
    p.color = Color.new(214, 118, 255)
    p.vfx_name, p.vfx_scale, p.ttl = config[:vfx], config[:visual_scale], 5.0
    p.instance_variable_set(:@titan_projectile, true)
    @projectiles << p
    p
  end

  def titan_reset_escape_state
    @titan_charge = nil
    @titan_lugia_flee_count = 0
    @titan_lugia_last_flee = nil
    @titan_flee_time = @titan_trap_cooldown = @titan_leap_cooldown = @titan_trap_pause = 0.0
    @titan_escape_episode = false
    @titan_leap = nil
  end

  def titan_update_escape_response(dt, distance, offscreen)
    return titan_update_glacial_charge(dt) if @titan_charge
    @titan_trap_cooldown = [@titan_trap_cooldown - dt, 0.0].max
    @titan_leap_cooldown = [@titan_leap_cooldown - dt, 0.0].max
    return titan_update_leap(dt) if @titan_leap
    if @titan_trap_pause > 0
      @titan_trap_pause = [@titan_trap_pause - dt, 0.0].max
      return true
    end
    @titan_escape_episode = false if !offscreen && distance <= 150
    if offscreen && !@titan_escape_episode
      @titan_escape_episode = true
      interrupted = !@titan_ai.pursuing? && @titan_ai.pattern[:interval]
      if interrupted && @titan_leap_cooldown <= 0 && rand(4) == 0
        titan_begin_leap
        return true
      end
    end
    dx, dy = @hero.x - @titan_boss.x, @hero.y - @titan_boss.y
    away = @hero.moving && distance > 240 &&
      (@last_move_dx.to_f * dx + @last_move_dy.to_f * dy) / [distance, 1.0].max > 0.35
    @titan_flee_time = away ? @titan_flee_time + dt : [@titan_flee_time - dt * 2, 0.0].max
    return false unless @titan_flee_time >= 4.0 && @titan_trap_cooldown <= 0 && @titan_pattern_warnings.length < 2
    # Leave the opening toward the arena interior, not toward a nearby wall.
    gap_x = Graphics.width / 2.0 - @world_x.to_f - @hero.x
    gap_y = Graphics.height / 2.0 - @world_y.to_f - @hero.y
    gap = if gap_x.abs + gap_y.abs < 1
            Math.atan2(@last_move_dy.to_f, @last_move_dx.to_f)
          else
            Math.atan2(gap_y, gap_x)
          end
    @titan_pattern_warnings << { kind: :closing_ring, x: @hero.x + @world_x.to_f,
      y: @hero.y + @world_y.to_f, elapsed: 0.0, delay: 1.0, gap: gap }
    @titan_flee_time, @titan_trap_cooldown, @titan_trap_pause = 0.0, 12.0, 1.2
    if PokemonSurvivor::Titan.season(@titan_session[:season_id])[:patterns] == :lugia
      @titan_lugia_flee_count = 0 if !@titan_lugia_last_flee || @timer - @titan_lugia_last_flee > 45.0
      @titan_lugia_last_flee = @timer
      @titan_lugia_flee_count += 1
      if @titan_lugia_flee_count >= 2
        titan_spawn_hunting_tornadoes(true)
        @titan_lugia_flee_count = 0
      end
    end
    true
  end

  def titan_begin_leap
    angle = Math.atan2(@titan_boss.y - @hero.y, @titan_boss.x - @hero.x)
    x, y = clamp_world_spawn_position(@hero.x + Math.cos(angle) * 120,
      @hero.y + Math.sin(angle) * 120, @titan_boss.radius + 24)
    @titan_leap = { phase: :warning, elapsed: 0.0,
      from_x: @titan_boss.x + @world_x.to_f, from_y: @titan_boss.y + @world_y.to_f,
      to_x: x + @world_x.to_f, to_y: y + @world_y.to_f }
    @titan_flee_time, @titan_leap_cooldown = 0.0, 35.0
  end

  def titan_update_leap(dt)
    leap = @titan_leap
    leap[:elapsed] += dt
    if leap[:phase] == :warning
      if leap[:elapsed] >= 1.0
        leap[:phase], leap[:elapsed] = :airborne, 0.0
      end
      return true
    end
    progress = [leap[:elapsed] / 0.65, 1.0].min
    @titan_boss.x = leap[:from_x] + (leap[:to_x] - leap[:from_x]) * progress - @world_x.to_f
    @titan_boss.y = leap[:from_y] + (leap[:to_y] - leap[:from_y]) * progress - @world_y.to_f
    invalidate_enemy_grid
    return true if progress < 1.0
    12.times do |index|
      p = titan_fire(index * Math::PI / 6.0)
      break unless p
      p.speed, p.ttl = 2.4, 30.0
      p.homing = true
      p.source_skill = { keep_until_expiry: true }
      p.instance_variable_set(:@titan_persistent_homing, true)
    end
    @titan_leap = nil
    true
  end

  def collision?(a, b)
    if titan_mode?
      return false if [a, b].any? { |entity| entity.instance_variable_get(:@titan_hunting_tornado) && entity.age.to_f < 1.0 }
    end
    if titan_mode? && @titan_leap && @titan_leap[:phase] == :airborne &&
       ((a.equal?(@titan_boss) && b.equal?(@hero)) || (b.equal?(@titan_boss) && a.equal?(@hero)))
      return false
    end
    super
  end

  def titan_closing_ring_points(warning)
    20.times do |index|
      next if index <= 1 || index == 19
      angle = warning[:gap] + index * Math::PI / 10.0
      yield warning[:x] - @world_x.to_f + Math.cos(angle) * 180,
        warning[:y] - @world_y.to_f + Math.sin(angle) * 180, angle + Math::PI
    end
  end

  def titan_fire_pattern(angle, pattern)
    @titan_cast_pattern = pattern
    case pattern
    when :glacial_charge
      @titan_charge ||= { phase: :warning, elapsed: 0.0, angle: angle,
        speed: [@hero.speed.to_f * (@titan_ai.phase == 2 ? 3.6 : 3.0), 8.0].max }
    when :hunting_tornadoes
      titan_spawn_hunting_tornadoes(false)
    when :storm_cage
      return if @titan_pattern_warnings.length >= 2
      @titan_pattern_warnings << { kind: :closing_ring,
        x: @hero.x + @world_x.to_f, y: @hero.y + @world_y.to_f,
        elapsed: 0.0, delay: 1.4, gap: angle + Math::PI / 2.0 }
    when :satellites
      4.times do |index|
        p = titan_fire(angle + index * Math::PI / 2.0)
        break unless p
        if PokemonSurvivor::Titan.season(@titan_session[:season_id])[:patterns] == :lugia
          p.vfx_name, p.attack_type = "VFX_PSYCHIC5", :PSYCHIC
        end
        p.orbit_target = @titan_boss
        p.orbit_radius = 72.0
        p.orbit_angle = angle + index * Math::PI / 2.0
        p.x = @titan_boss.x + Math.cos(p.orbit_angle) * p.orbit_radius
        p.y = @titan_boss.y + Math.sin(p.orbit_angle) * p.orbit_radius
        p.ttl = 7.0
        p.instance_variable_set(:@titan_satellite, { launch_at: 1.2 + index * 0.35, homing_left: 2.0 })
      end
    when :pincers, :rupture
      return if @titan_pattern_warnings.length >= 2
      x, y = if pattern == :pincers
               clamp_world_spawn_position(@hero.x, @hero.y, 220)
             else
               [@titan_boss.x, @titan_boss.y]
             end
      # Absolute terrain coordinates stay fixed when movement scrolls the world.
      @titan_pattern_warnings << { kind: pattern, x: x + @world_x.to_f, y: y + @world_y.to_f,
        elapsed: 0.0, delay: pattern == :rupture ? 1.4 : 1.2, vertical: rand(2) == 0 }
    else
      p = titan_fire(angle)
      p.speed = 2.6 if p && pattern == :offset_rings
      if p && pattern == :fusion_flare
        p.speed, p.radius = 2.8, p.radius * 1.25
        p.vfx_scale *= 1.25
      elsif p && pattern == :fusion_bolt
        p.speed = 5.4
      elsif p && pattern == :ice_barrage
        p.speed = @titan_ai.phase == 2 ? 4.5 : 8.5
        p.ttl = 4.0
        if @titan_ai.phase == 2
          p.homing = true
          p.instance_variable_set(:@titan_ice_seeker, true)
        end
      end
    end
  ensure
    @titan_cast_pattern = nil
  end

  def titan_spawn_hunting_tornadoes(punishment)
    active = @projectiles.count { |p| p.ttl.to_f > 0 && p.instance_variable_get(:@titan_hunting_tornado) }
    count = punishment ? 4 : 2
    return if active + count > 8 || @projectiles.length + count > PokemonSurvivor::MAX_PROJECTILES
    count.times do |index|
      angle = index * Math::PI * 2.0 / count + Math::PI / 4.0
      center = punishment ? @hero : @titan_boss
      distance = punishment ? 170.0 : 65.0
      x, y = clamp_world_spawn_position(center.x + Math.cos(angle) * distance,
        center.y + Math.sin(angle) * distance, 20)
      p = titan_fire(angle)
      next unless p
      p.x, p.y = x, y
      p.vfx_name, p.vfx_scale, p.attack_type = "VFX_FLYING2", 1.0, :FLYING
      p.ttl = punishment ? 3.0 : 25.0
      p.homing = true
      p.instance_variable_set(:@titan_hunting_tornado, { punishment: punishment, damage: p.damage })
      p.instance_variable_set(:@titan_persistent_homing, true)
      p.radius, p.damage, p.speed = 0.0, 0, 0.0
      p.source_skill = { keep_until_expiry: true }
    end
  end

  def titan_update_glacial_charge(dt)
    charge = @titan_charge
    charge[:elapsed] += dt
    if charge[:phase] == :warning
      if charge[:elapsed] >= 0.9
        charge[:phase], charge[:elapsed] = :rush, 0.0
      end
      return true
    end
    if charge[:phase] == :rush
      boss = @titan_boss
      step = charge[:speed] * 60.0 * dt
      x = boss.x + Math.cos(charge[:angle]) * step
      y = boss.y + Math.sin(charge[:angle]) * step
      boss.x, boss.y = clamp_world_spawn_position(x, y, boss.radius)
      boss.direction = direction_from_vector_8(Math.cos(charge[:angle]), Math.sin(charge[:angle]))
      invalidate_enemy_grid
      if charge[:elapsed] >= 0.55 || (boss.x - x).abs > 0.1 || (boss.y - y).abs > 0.1
        charge[:phase], charge[:elapsed] = :recovery, 0.0
      end
      return true
    end
    @titan_charge = nil if charge[:elapsed] >= 0.8
    true
  end

  def titan_boss_species
    data = PokemonSurvivor::Titan.season(@titan_session[:season_id])
    data[:species] || @titan_boss.name
  end

  def titan_shoot_frames
    @titan_shoot_frame_count
  end

  def titan_pincer_points(warning)
    x, y = warning[:x] - @world_x.to_f, warning[:y] - @world_y.to_f
    [-1, 1].each do |side|
      (-5..5).each do |index|
        next if index.abs <= 1
        offset = index * 32.0
        if warning[:vertical]
          yield x + offset, y + side * 200, -side * Math::PI / 2.0
        else
          yield x + side * 200, y + offset, side == 1 ? Math::PI : 0.0
        end
      end
    end
  end

  def titan_update_pattern_warnings(dt)
    @titan_pattern_warnings.delete_if do |warning|
      warning[:elapsed] += dt
      next false if warning[:elapsed] < warning[:delay]
      if warning[:kind] == :pincers
        titan_pincer_points(warning) do |x, y, angle|
          p = titan_fire(angle)
          next unless p
          p.x, p.y, p.speed, p.ttl = x, y, 2.8, 2.8
        end
      elsif warning[:kind] == :closing_ring
        titan_closing_ring_points(warning) do |x, y, angle|
          p = titan_fire(angle)
          next unless p
          p.x, p.y, p.speed, p.ttl = x, y, 1.6, 1.4
          p.source_skill = { keep_until_expiry: true }
        end
      else
        p = titan_fire(0.0)
        if p
          p.x, p.y = warning[:x] - @world_x.to_f, warning[:y] - @world_y.to_f
          p.radius, p.speed, p.ttl = 140.0, 0.0, 0.35
          p.damage = (p.damage * 1.5).round
          p.instance_variable_set(:@titan_rupture, true)
        end
      end
      true
    end
  end

  def update_orbit_projectile(projectile, dt)
    satellite = projectile.instance_variable_get(:@titan_satellite)
    return super unless titan_mode? && satellite
    boss = projectile.orbit_target
    return projectile.ttl = 0.0 unless boss && boss.hp > 0
    projectile.orbit_angle += dt * 2.4
    projectile.x = boss.x + Math.cos(projectile.orbit_angle) * projectile.orbit_radius
    projectile.y = boss.y + Math.sin(projectile.orbit_angle) * projectile.orbit_radius
    return if projectile.age.to_f < satellite[:launch_at]
    angle = Math.atan2(@hero.y - projectile.y, @hero.x - projectile.x)
    projectile.vx, projectile.vy = Math.cos(angle), Math.sin(angle)
    projectile.orbit_target = nil
    projectile.homing = true
    projectile.speed, projectile.ttl = 3.2, 4.0
  end

  def update_homing_projectile(projectile, dt)
    if titan_mode? && projectile.instance_variable_get(:@titan_ice_seeker)
      current = Math.atan2(projectile.vy, projectile.vx)
      target = Math.atan2(@hero.y - projectile.y, @hero.x - projectile.x)
      delta = (target - current + Math::PI) % (Math::PI * 2.0) - Math::PI
      angle = current + [[delta, -1.8 * dt].max, 1.8 * dt].min
      projectile.vx, projectile.vy = Math.cos(angle), Math.sin(angle)
      return
    end
    tornado = projectile.instance_variable_get(:@titan_hunting_tornado)
    if titan_mode? && tornado
      if projectile.age.to_f < 1.0
        projectile.speed = 0.0
        projectile.radius = 0.0
        projectile.damage = 0
        return
      end
      projectile.radius = 18.0
      projectile.damage = tornado[:damage]
      projectile.speed = @hero.speed.to_f * (tornado[:punishment] ? 1.35 : 0.92)
      dx, dy = @hero.x - projectile.x, @hero.y - projectile.y
      length = [Math.sqrt(dx * dx + dy * dy), 1.0].max
      projectile.vx, projectile.vy = dx / length, dy / length
      return
    end
    if titan_mode? && projectile.instance_variable_get(:@titan_persistent_homing)
      # Initially fan out from the landing point before pursuing the player.
      return if projectile.age.to_f < 0.65
      current = Math.atan2(projectile.vy, projectile.vx)
      target = Math.atan2(@hero.y - projectile.y, @hero.x - projectile.x)
      delta = (target - current + Math::PI) % (Math::PI * 2.0) - Math::PI
      angle = current + [[delta, -1.6 * dt].max, 1.6 * dt].min
      projectile.vx, projectile.vy = Math.cos(angle), Math.sin(angle)
      return
    end
    satellite = projectile.instance_variable_get(:@titan_satellite)
    return super unless titan_mode? && satellite
    # Two seconds of pursuit (~384 world pixels), then a straight, escapable trajectory.
    turn_dt = [dt, satellite[:homing_left]].min
    current = Math.atan2(projectile.vy, projectile.vx)
    target = Math.atan2(@hero.y - projectile.y, @hero.x - projectile.x)
    delta = (target - current + Math::PI) % (Math::PI * 2.0) - Math::PI
    angle = current + [[delta, -3.0 * turn_dt].max, 3.0 * turn_dt].min
    projectile.vx, projectile.vy = Math.cos(angle), Math.sin(angle)
    satellite[:homing_left] = [satellite[:homing_left] - dt, 0.0].max
    projectile.homing = false if satellite[:homing_left] <= 0
  end

  def update_enemy_shot(enemy, dt)
    super unless titan_mode? && enemy.equal?(@titan_boss)
  end

  def boss_catchup_speed_mult(enemy, distance)
    titan_mode? && enemy.equal?(@titan_boss) ? 1.0 : super
  end

  def defeat_enemy(enemy)
    return if titan_mode? && enemy.equal?(@titan_boss)
    super
  end

  def titan_spawn_clone
    return if @enemies.count { |e| e.instance_variable_get(:@titan_clone) } >= 18
    angle = rand * Math::PI * 2
    x, y = clamp_world_spawn_position(@hero.x + Math.cos(angle) * 250, @hero.y + Math.sin(angle) * 250, 20)
    clone = PokemonSurvivorEntity.new(:wild, PokemonSurvivor::DOOM_ENEMY_NAME, x, y)
    clone.bitmap = cached_bitmap(PokemonSurvivor::WILD_DIR, PokemonSurvivor::DOOM_ENEMY_NAME)
    clone.max_hp = clone.hp = 1_000_000_000
    clone.speed = @hero.speed * 1.35
    clone.damage = @hero.max_hp * 100
    clone.radius = 20
    clone.types, clone.attack_type = [:GHOST], :GHOST
    clone.charset_directions = 8 if PokemonSurvivor.eight_direction_bitmap?(clone.bitmap)
    clone.instance_variable_set(:@titan_clone, true)
    @enemies << clone
  end

  def finish_run(*args)
    return super unless titan_mode?
    return if @run_finished
    @run_finished = true
    damage = @titan_boss ? @titan_boss.titan_ledger.damage : 0
    @titan_result_damage = @run_abandoned ? 0 : damage
    @seasonal_result_ready = false
    outcome = @run_abandoned ? :abandoned : (@titan_won ? :won : :lost)
    @titan_receipt = @titan_store.settle(@titan_session, damage, @timer, outcome)
    @state = :gameover
    clear_transient_run_state
    cleanup_classic_endless_variety_events
    @titan_cinematic = nil
    @titan_camera_x = @titan_camera_y = 0.0
    @state = :gameover
    @result_text = @run_abandoned ? _INTL("Run abandoned") : _INTL("Titan run ended")
    auto_save_successful_run_once
  end

  def leaderboard_share_eligible?
    titan_mode? ? false : super
  end

  def run_speed_available?
    titan_mode? ? false : super
  end

  def survivor_xp_next_for_level(level)
    return super unless titan_mode?
    value = [level.to_i, 1].max
    base = 12 + value * 7 + value * value / 2
    reduction = value <= 10 ? PokemonSurvivor::Titan.training_effect(@titan_training_ranks || {}, :early_level_xp_percent) : 0
    [(base * (1.0 - reduction / 100.0)).round, 1].max
  end

  def sync_event_baby_stats(baby)
    result = super
    if titan_mode? && baby && !baby.instance_variable_get(:@titan_no_heal)
      baby.singleton_class.prepend(SurvivorTitanHealth)
      baby.instance_variable_set(:@titan_no_heal, true)
    end
    result
  end

  def leaderboard_run_won?
    titan_mode? ? false : super
  end

  def draw_gameover
    super
  end

  def update_gameover
    return super unless titan_mode?
    draw_gameover
    @seasonal_result_ready = true unless PokemonSurvivor.control_press?(:confirm) || PokemonSurvivor.control_press?(:cancel)
    return unless @seasonal_result_ready && (survivor_confirm_triggered? || survivor_cancel_triggered?)
    return_to_select_menu
    titan_open_menu
  end

  def return_to_select_menu
    if titan_mode?
      @titan_run = false
      @titan_preparing = false
      @titan_session = nil
      @titan_result_damage = nil
      @titan_training_ranks = {}
      @titan_queued_weak = 0
      @titan_cinematic = @titan_boss = @titan_ai = nil
      @titan_pattern_warnings = []
      titan_reset_escape_state
      @titan_camera_x = @titan_camera_y = 0.0
      @run_mode = :classic
    end
    super
  end

  def titan_play_music(name)
    # Missing optional season music must not interrupt a run.
    path = "Audio/BGM/Survivor/#{name}"
    play_survivor_bgm_name("Survivor/#{name}") if Dir.glob("#{path}.*").any?
  end
end
