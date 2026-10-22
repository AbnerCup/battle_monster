#===============================================================================
# Pokemon Survivor - Player movement, rush walls, spawning, items, audio and enemies
#===============================================================================

class Scene_PokemonSurvivor

  def update_player(dt)
    if headache_movement_locked?
      @hero.moving = false
      return
    end
    if @hero.slow_timer.to_f > 0.0
      recovery = @equipped_item && @equipped_item[:effect] == :slow_recovery_percent ? 1.0 / 0.70 : 1.0
      @hero.slow_timer = [@hero.slow_timer - dt * recovery, 0.0].max
    end
    if @doom_final_started
      @hero.moving = false
      return
    end
    if respond_to?(:focus_step_active?) && focus_step_active?
      @hero.moving = true
      return
    end
    dx = 0
    dy = 0
    dx -= 1 if Input.press?(Input::LEFT)
    dx += 1 if Input.press?(Input::RIGHT)
    dy -= 1 if Input.press?(Input::UP)
    dy += 1 if Input.press?(Input::DOWN)
    if @psyduck_confusion_timer.to_f > 0
      dx = -dx
      dy = -dy
    end
    @hero.moving = (dx != 0 || dy != 0)
    if dx != 0 || dy != 0
      @hero.direction = @hero.charset_directions.to_i >= PokemonSurvivor::CHARSET_8_DIRECTIONS ? direction_from_vector_8(dx, dy) : direction_from_vector(dx, dy)
      len = Math.sqrt((dx * dx) + (dy * dy))
      scroll = @hero.speed * deoxys_move_multiplier * aegislash_move_multiplier * 60.0 * dt
      scroll *= 1.12 if equipment_adrenaline_active?
      scroll *= @hero.slow_mult.to_f if @hero.slow_timer.to_f > 0.0
      sx = dx / len * scroll
      sy = dy / len * scroll
      actual = clamp_world_scroll(sx, sy)
      sx = actual[0]
      sy = actual[1]
      @world_x += sx
      @world_y += sy
      @last_move_dx = dx / len
      @last_move_dy = dy / len
      shift_world_entities(-sx, -sy) if sx != 0 || sy != 0
    end
  end


  def world_walls_enabled?
    arena_mode? || @run_mode == :classic || @run_mode == :endless
  rescue
    false
  end

  def world_tile_span
    arena_mode? ? 3.0 : 9.0
  rescue
    3.0
  end

  def world_limit_x
    bg = cached_background_bitmap(@bg_name)
    tile = respond_to?(:run_background_tile_width) ? run_background_tile_width(bg).to_f : (bg && !bg.disposed? ? bg.width.to_f : Graphics.width.to_f)
    [(tile * world_tile_span) - (Graphics.width * 0.5), tile * 0.5].max
  rescue
    Graphics.width.to_f
  end

  def world_limit_y
    bg = cached_background_bitmap(@bg_name)
    tile = respond_to?(:run_background_tile_height) ? run_background_tile_height(bg).to_f : (bg && !bg.disposed? ? bg.height.to_f : Graphics.height.to_f)
    [(tile * world_tile_span) - (Graphics.height * 0.5), tile * 0.5].max
  rescue
    Graphics.height.to_f
  end

  def rush_world_limit_x
    world_limit_x
  end

  def rush_world_limit_y
    world_limit_y
  end

  def clamp_world_scroll(sx, sy)
    return [sx, sy] if !world_walls_enabled?
    limit_x = world_limit_x
    limit_y = world_limit_y
    next_x = @world_x.to_f + sx.to_f
    next_y = @world_y.to_f + sy.to_f
    clamped_x = [[next_x, -limit_x].max, limit_x].min
    clamped_y = [[next_y, -limit_y].max, limit_y].min
    flash_rush_wall(:right) if next_x > limit_x + 0.01
    flash_rush_wall(:left) if next_x < -limit_x - 0.01
    flash_rush_wall(:bottom) if next_y > limit_y + 0.01
    flash_rush_wall(:top) if next_y < -limit_y - 0.01
    [clamped_x - @world_x.to_f, clamped_y - @world_y.to_f]
  rescue
    [sx, sy]
  end

  def clamp_rush_world_scroll(sx, sy)
    clamp_world_scroll(sx, sy)
  end

  def flash_rush_wall(side)
    @rush_wall_flash ||= {}
    @rush_wall_flash[side] = 0.22
  rescue
  end

  def update_rush_wall_flash(dt)
    return if !@rush_wall_flash
    @rush_wall_flash.keys.each do |side|
      @rush_wall_flash[side] = @rush_wall_flash[side].to_f - dt.to_f
    end
    @rush_wall_flash.delete_if { |_side, time| time.to_f <= 0 }
  rescue
  end

  def shift_world_entities(dx, dy)
    (@headache_waves || []).each do |wave|
      wave[:x] += dx
      wave[:y] += dy
    end
    (@enemies || []).each do |e|
      e.x += dx
      e.y += dy
    end
    (@projectiles || []).each do |p|
      p.x += dx
      p.y += dy
    end
    (@xp_gems || []).each do |gem|
      gem.x += dx
      gem.y += dy
    end
    (@items || []).each do |item|
      item.x += dx
      item.y += dy
    end
    [@event_egg, @event_baby, @event_sleep, @event_lost_kecleon].each do |entity|
      next if !entity
      entity.x += dx
      entity.y += dy
    end
    (@effects || []).each do |fx|
      next if fx[5] == :level_burst
      fx[0] += dx
      fx[1] += dy
      meta = fx[9]
      if meta.is_a?(Hash) && meta[:charmander_twister]
        meta[:origin_x] += dx
        meta[:origin_y] += dy
      end
      if meta.is_a?(Hash) && meta[:poison_rain_drop]
        meta[:target_x] += dx
        meta[:start_y] += dy
        meta[:target_y] += dy
      end
    end
  end

  def start_doom_finale
    @doom_final_started = true
    @spawn_queue = []
    @spawn_queue_index = 0
    @enemies.delete_if { |e| e.kind == :wild }
    @projectiles.delete_if { |p| p.owner == :enemy } rescue nil
    @boss_timer = 999_999.0
    @chest_timer = 999_999.0
    @spawn_timer = 0.0
    @doom_spawn_count = 0
  rescue
  end

  def spawn_wave
    return spawn_rush_wave if rush_mode?
    return spawn_tower_wave if tower_mode?
    return @spawn_timer = 0.15 if spawn_queue_pending?
    seconds = @timer.to_i
    pressure_seconds = endless_mode? ? endless_pressure_seconds(seconds) : seconds
    tier = PokemonSurvivor.enemy_progress_tier(pressure_seconds, @level)
    phase = PokemonSurvivor.hero_difficulty_phase(@level)
    cleanup_active_entities
    active_wild = @enemies.count { |e| e.kind == :wild } rescue 0
    classic_enemy_cap = classic_wild_enemy_cap(pressure_seconds)
    doom_only = @run_mode == :classic && seconds >= PokemonSurvivor::DOOM_ONLY_TIME
    active_doom = @enemies.count { |e| PokemonSurvivor.doom_enemy?(e.name) } rescue 0
    if doom_only
      return @spawn_timer = 0.42 if active_doom >= PokemonSurvivor::MAX_DOOM_ENEMIES
    elsif active_wild >= classic_enemy_cap
      return @spawn_timer = 0.95
    end
    count = 3 + (pressure_seconds / 82) + (tier / 2) + (@level.to_i / 18)
    count += 1 if @level.to_i >= 10
    count += 1 if @level.to_i >= 18
    count += 1 if @level.to_i >= 28
    count += 1 if @level.to_i >= 42
    count += 1 if @level.to_i >= 55
    count += 2 if phase == 0 && @level.to_i >= 10 && (seconds / 22) % 4 == 0
    count += 1 if phase == 1 && @level.to_i >= 36 && (seconds / 30) % 4 == 1
    count += 2 if phase == 2 && (seconds / 28) % 3 == 2
    count += 2 if @run_mode == :classic && seconds >= PokemonSurvivor::DOOM_START_TIME
    count += 1 if seconds >= 600
    count += 1 if seconds >= 720
    count += 2 if seconds >= 840
    count += 18 if doom_only
    cap = doom_only ? 26 : (phase == 0 ? 12 : (phase == 1 ? 17 : 22))
    cap += 3 if seconds >= 600 && !doom_only
    cap += 2 if seconds >= 780 && !doom_only
    count = [count, 8].min if seconds < 120
    count = [count, doom_only ? PokemonSurvivor::MAX_DOOM_ENEMIES - active_doom : classic_enemy_cap - active_wild].min
    count = [count, cap].min
    enqueue_enemy_spawns(:wild, count)
    early_relief = seconds < 180 ? 0.25 : 0.0
    phase_pressure = phase * 0.10
    if doom_only
      @spawn_timer = 0.16
    else
      late_pressure = pressure_seconds >= 600 ? 0.28 : 0.0
      late_pressure += 0.18 if pressure_seconds >= 780
      if endless_mode?
        late_pressure += 0.10 if seconds >= 30 * 60
        late_pressure += 0.14 if seconds >= 45 * 60
        late_pressure += 0.18 if seconds >= 55 * 60
        min_timer = if seconds >= 55 * 60
                      0.48
                    elsif seconds >= 45 * 60
                      0.54
                    elsif seconds >= 30 * 60
                      0.60
                    else
                      pressure_seconds >= 780 ? 0.72 : (pressure_seconds >= 600 ? 0.66 : 0.58)
                    end
      else
        min_timer = pressure_seconds >= 780 ? 0.72 : (pressure_seconds >= 600 ? 0.66 : 0.58)
      end
      @spawn_timer = [2.82 + early_relief - (pressure_seconds / 760.0) - (tier * 0.035) - (@level.to_i * 0.0015) - phase_pressure - late_pressure, min_timer].max
    end
  end


  def classic_wild_enemy_cap(seconds)
    seconds = seconds.to_i
    return PokemonSurvivor::MAX_WILD_ENEMIES if seconds < 600
    return 240 if seconds < 780
    return 225 if seconds < 840
    210
  rescue
    PokemonSurvivor::MAX_WILD_ENEMIES
  end

  def spawn_rush_wave
    return @spawn_timer = 0.20 if spawn_queue_pending?
    cleanup_active_entities
    active_wild = @enemies.count { |e| e.kind == :wild } rescue 0
    cap = 10
    return @spawn_timer = 0.42 if active_wild >= cap
    count = 3 + [@level.to_i / 30, 4].min
    count = [count, cap - active_wild].min
    enqueue_enemy_spawns(:wild, count)
    @spawn_timer = [1.05 - (@rush_wave_index.to_i * 0.12) - (@level.to_i * 0.002), 0.45].max
  rescue
    @spawn_timer = 0.8
  end

  def rush_boss_alive?
    @enemies.any? { |e| (e.kind == :boss || e.kind == :ultra_boss) && e.hp.to_i > 0 }
  rescue
    false
  end

  def update_rush_mode(dt)
    return finalize_rush_victory if @rush_complete && @state == :play
    return if @rush_complete
    return if @pending_upgrade || @state == :upgrade
    return if rush_boss_alive?
    @rush_spawn_delay -= dt
    return if @rush_spawn_delay.to_f > 0
    sequence = @rush_boss_sequence || []
    if @rush_wave_index.to_i >= sequence.length
      return finalize_rush_victory if sequence.length > 0
      return
    end
    boss_name = sequence[@rush_wave_index.to_i]
    kind = (@rush_wave_index.to_i >= sequence.length - 1) ? :ultra_boss : :boss
    before_count = @enemies.length
    spawn_enemy(kind, boss_name)
    spawned = @enemies.length > before_count && @enemies.any? { |e| e && e.name.to_s == boss_name.to_s && e.kind == kind && e.hp.to_i > 0 }
    if !spawned
      @rush_wave_index = @rush_wave_index.to_i + 1
      return finalize_rush_victory if @rush_wave_index.to_i >= rush_total_wave_count
      @rush_spawn_delay = 0.25
      return
    end
    spawn_rush_sleep_for_wave(@rush_wave_index.to_i) if kind == :boss && respond_to?(:spawn_rush_sleep_for_wave)
    @rush_spawn_delay = 999_999.0
  rescue
    @rush_spawn_delay = 0.25
  end

  def rush_total_wave_count
    total = @rush_total_waves.to_i
    total = (@rush_boss_sequence || []).length if total <= 0
    total > 0 ? total : 4
  rescue
    4
  end

  def finalize_rush_victory
    return if @state == :gameover && @rush_complete
    @rush_final_boss_defeated = true
    @rush_complete = true
    award_rush_time_score rescue nil
    finish_run rescue nil
    @state = :gameover
    @result_text = _INTL("Rush cleared!")
    play_survivor_result_bgm rescue nil
    draw_gameover rescue nil
  rescue
    @state = :gameover
    @result_text = _INTL("Rush cleared!") rescue "Rush cleared!"
  end
  def on_rush_boss_defeated(enemy)
    @rush_wave_index = @rush_wave_index.to_i + 1
    if @rush_wave_index.to_i >= rush_total_wave_count
      finalize_rush_victory
    else
      @rush_spawn_delay = 2.0
    end
  rescue
    finalize_rush_victory if @rush_wave_index.to_i >= rush_total_wave_count
  end
  def award_rush_time_score
    return if !rush_mode? || @rush_time_score_awarded
    seconds = [@timer.to_f, 1.0].max
    fast_target = 8.0 * 60.0
    clear_score = 1_250_000
    speed_bonus = (2_650_000 * rush_time_score_factor(seconds, fast_target)).round
    level_bonus = rush_time_scaled_level_score(seconds, fast_target)
    combat_value = [@score.to_i * 0.18, 0.0].max
    combat_bonus = (180_000 * combat_value / (180_000 + combat_value)).round
    @score = [clear_score + speed_bonus + level_bonus + combat_bonus, 0].max
    @rush_time_score_awarded = true
  rescue
  end

  def rush_time_score_factor(seconds, target)
    ratio = target.to_f / [seconds.to_f, 1.0].max
    return [ratio, 0.06].max if ratio <= 1.45
    excess = ratio - 1.45
    1.45 + excess / (1.0 + excess / 0.35)
  rescue
    0.1
  end

  def rush_time_scaled_level_score(seconds, target)
    level = [[@level.to_i, 1].max, 9999].min
    useful_level = [level, 160].min
    over_level = [level - 160, 0].max
    base = (useful_level * 1_450) + (over_level * 90)
    penalty = rush_time_score_factor(seconds, target) / 1.45
    (base * [[penalty, 0.04].max, 1.0].min).round
  rescue
    0
  end

  def tower_boss_alive?
    @enemies.any? { |e| (e.kind == :boss || e.kind == :ultra_boss) && e.hp.to_i > 0 }
  rescue
    false
  end

  def tower_egg_floor?
    [25, 50, 75].include?(@tower_floor.to_i)
  rescue
    false
  end

  def tower_floor_boss_floor?
    floor = @tower_floor.to_i
    return false if tower_egg_floor?
    return true if floor >= PokemonSurvivor::TOWER_MAX_FLOOR
    floor >= 30 && floor % 10 == 0
  rescue
    false
  end

  def tower_floor_required_kos
    [[8 + (@tower_floor.to_i / 2), 8].max, 48].min
  rescue
    10
  end

  def start_tower_floor
    update_tower_floor_bgm
    update_tower_floor_background
    @tower_floor_started = true
    @tower_floor_kills_start = @kills.to_i
    @tower_boss_defeated = false
    @tower_egg_hatched_this_floor = false
    apply_tower_boss_preparation if tower_floor_boss_floor? || @tower_floor.to_i >= PokemonSurvivor::TOWER_MAX_FLOOR
    @spawn_timer = 0.2
    if tower_egg_floor?
      @event_egg = nil
      spawn_random_event_egg(true) if respond_to?(:spawn_random_event_egg)
    elsif @tower_floor.to_i >= PokemonSurvivor::TOWER_MAX_FLOOR
      @enemies.clear
      @projectiles.delete_if { |p| p.owner == :enemy } rescue nil
      spawn_enemy(:ultra_boss, @tower_final_boss_name || PokemonSurvivor.random_tower_final_boss)
    elsif tower_floor_boss_floor?
      spawn_enemy(:boss)
    end
  rescue
  end

  def update_tower_mode(dt)
    return if @tower_complete
    return if @pending_upgrade || @state == :upgrade
    start_tower_floor if !@tower_floor_started
    if tower_floor_complete?
      finish_tower_floor
    end
  rescue
  end

  def tower_floor_complete?
    return false if !@tower_floor_started
    if @tower_floor.to_i >= PokemonSurvivor::TOWER_MAX_FLOOR
      return @tower_complete
    elsif tower_egg_floor?
      return @tower_egg_hatched_this_floor && !@event_egg
    elsif tower_floor_boss_floor?
      return @tower_boss_defeated && !tower_boss_alive?
    end
    (@kills.to_i - @tower_floor_kills_start.to_i) >= tower_floor_required_kos
  rescue
    false
  end

  def tower_floor_transition_active?
    !!@tower_transition_phase
  rescue
    false
  end

  def apply_tower_floor_momentum
    return if !tower_mode? || @tower_floor_momentum_level.to_i <= 0
    floor = @tower_floor.to_i
    return if @tower_floor_momentum_awarded_floor.to_i >= floor
    @tower_floor_momentum_awarded_floor = floor
    @damage_mult *= 1.0 + (0.0025 * @tower_floor_momentum_level.to_i)
  rescue
  end

  def apply_tower_boss_preparation
    return if !tower_mode? || @boss_preparation_level.to_i <= 0 || !@hero || @hero.hp.to_i <= 0
    heal_rate = 0.035 * @boss_preparation_level.to_i
    heal = [(@hero.max_hp.to_f * heal_rate).round, 1].max
    @hero.hp = [@hero.hp.to_i + heal, @hero.max_hp.to_i].min
    trigger_gauge_flash(0.45) if respond_to?(:trigger_gauge_flash)
    set_hero_item_flash(Color.new(122, 255, 176), 0.45) if respond_to?(:set_hero_item_flash)
  rescue
  end
  def finish_tower_floor
    return if @tower_floor.to_i >= PokemonSurvivor::TOWER_MAX_FLOOR
    return if tower_floor_transition_active?
    apply_tower_floor_momentum
    begin_tower_floor_transition
  rescue
  end

  def begin_tower_floor_transition
    @tower_transition_phase = :magnet
    @tower_transition_duration = 1.10
    @tower_transition_timer = @tower_transition_duration
    @tower_fade_alpha = 0
    @force_magnet_timer = [@force_magnet_timer.to_f, 999.0].max
    @spawn_queue.clear if @spawn_queue
    @spawn_queue_index = 0
  rescue
  end

  def update_tower_floor_transition(dt)
    @invuln = [@invuln.to_f, 0.25].max
    update_effects(dt)
    process_bitmap_preload_queue
    case @tower_transition_phase
    when :magnet
      @force_magnet_timer = [@force_magnet_timer.to_f, 0.18].max
      update_xp(dt)
      update_tower_moves_magnet(dt)
      if (!@xp_gems || @xp_gems.empty?) && !tower_moves_items_pending?
        @force_magnet_timer = 0.0
        @tower_transition_phase = :fade_out
        @tower_transition_duration = 0.38
        @tower_transition_timer = @tower_transition_duration
        @tower_fade_alpha = 0
      end
    when :fade_out
      @tower_transition_timer = @tower_transition_timer.to_f - dt.to_f
      progress = 1.0 - [[@tower_transition_timer.to_f / [@tower_transition_duration.to_f, 0.01].max, 0.0].max, 1.0].min
      @tower_fade_alpha = (progress * 255).round
      if @tower_transition_timer <= 0
        @tower_fade_alpha = 255
        @tower_floor = [@tower_floor.to_i + 1, PokemonSurvivor::TOWER_MAX_FLOOR].min
        @tower_floor_started = false
        @tower_transition_phase = nil
        request_upgrade(0.0)
      end
    when :fade_in
      @tower_transition_timer = @tower_transition_timer.to_f - dt.to_f
      progress = [[@tower_transition_timer.to_f / [@tower_transition_duration.to_f, 0.01].max, 0.0].max, 1.0].min
      @tower_fade_alpha = (progress * 255).round
      if @tower_transition_timer <= 0
        @tower_transition_phase = nil
        @tower_transition_timer = 0.0
        @tower_fade_alpha = 0
        start_tower_floor
      end
    else
      @tower_transition_phase = nil
      @tower_fade_alpha = 0
    end
  rescue
    @tower_transition_phase = nil
    @tower_fade_alpha = 0
  end

  def update_tower_moves_magnet(dt)
    return if !@items || @items.empty? || !@hero
    hx = @hero.x
    hy = @hero.y
    @items.each do |item|
      next if !item || item.value.to_i <= 0
      next if item.name.to_s.upcase != "MOVES"
      dx = hx - item.x
      dy = hy - item.y
      dist_sq = (dx * dx) + (dy * dy)
      len = [Math.sqrt(dist_sq), 1].max
      speed = 5.8 * 60.0 * dt.to_f
      item.x += dx / len * speed
      item.y += dy / len * speed
      next if !collision?(item, @hero)
      apply_wild_item(item.name, item.value.to_i)
      item.value = 0
    end
    @items.delete_if { |item| item && item.value.to_i <= 0 }
  rescue
  end

  def tower_moves_items_pending?
    (@items || []).any? { |item| item && item.value.to_i > 0 && item.name.to_s.upcase == "MOVES" }
  rescue
    false
  end
  def prepare_next_tower_floor_after_bonus
    return if !tower_mode?
    return if @tower_fade_alpha.to_i < 255
    return if @pending_upgrade_count.to_i > 0 || @pending_upgrade
    cleanup_tower_floor_before_next_start
    reset_player_for_tower_floor
    @tower_transition_phase = :fade_in
    @tower_transition_duration = 0.38
    @tower_transition_timer = @tower_transition_duration
    @tower_fade_alpha = 255
  rescue
  end

  def cleanup_tower_floor_before_next_start
    @enemies.clear if @enemies
    @items.clear if @items
    @projectiles.clear if @projectiles
    @effects.delete_if { |fx| fx && fx[5] != :level_burst } if @effects
    @spawn_queue.clear if @spawn_queue
    @spawn_queue_index = 0
    @orbit_hit_timers.clear if @orbit_hit_timers
    @orbit_shot_timers.clear if @orbit_shot_timers
    @charge_shots.clear if @charge_shots
    @enemy_grid = nil
  rescue
  end

  def reset_player_for_tower_floor
    return if !@hero
    @hero.x = Graphics.width / 2
    @hero.y = Graphics.height / 2
    @world_x = 0.0
    @world_y = 0.0
    @spawn_timer = 0.35
    @item_timer = [@item_timer.to_f, 2.0].max
    @invuln = [@invuln.to_f, 1.0].max
  rescue
  end

  def collect_remaining_tower_floor_xp
    return if !@xp_gems || @xp_gems.empty?
    total = 0
    @xp_gems.each { |gem| total += gem.value.to_i if gem && gem.value.to_i > 0 && !xp_drop_expired?(gem) }
    @xp_gems.clear
    gain_direct_xp(total) if total > 0
  rescue
  end
  def spawn_tower_wave
    return @spawn_timer = 0.20 if spawn_queue_pending?
    return @spawn_timer = 0.5 if @pending_upgrade || @state == :upgrade
    return @spawn_timer = 0.5 if @tower_floor.to_i >= PokemonSurvivor::TOWER_MAX_FLOOR && tower_boss_alive?
    cleanup_active_entities
    active_wild = @enemies.count { |e| e.kind == :wild } rescue 0
    cap = [[10 + (@tower_floor.to_i / 6), 10].max, 34].min
    cap = 12 if tower_floor_boss_floor?
    return @spawn_timer = 0.55 if active_wild >= cap
    count = [[3 + (@tower_floor.to_i / 10), 3].max, 8].min
    count = [count, cap - active_wild].min
    enqueue_enemy_spawns(:wild, count)
    @spawn_timer = [[1.05 - (@tower_floor.to_i * 0.004) - (@level.to_i * 0.001), 0.42].max, 1.1].min
  rescue
    @spawn_timer = 0.8
  end

  def on_tower_boss_defeated(enemy)
    @tower_bosses_defeated = @tower_bosses_defeated.to_i + 1
    if PokemonSurvivor.tower_final_boss?(enemy.name) || @tower_floor.to_i >= PokemonSurvivor::TOWER_MAX_FLOOR
      @tower_complete = true
      award_tower_score
      finish_run
      @state = :gameover
      @result_text = _INTL("Tower cleared!")
      play_survivor_result_bgm
      draw_gameover
    else
      @tower_boss_defeated = true
    end
  rescue
  end

  def award_tower_score
    return if @tower_score_awarded
    floor = [[@tower_floor.to_i, 1].max, PokemonSurvivor::TOWER_MAX_FLOOR].min
    seconds = [@timer.to_f, 1.0].max
    target = [floor * 45.0, 180.0].max
    time_factor = tower_time_score_factor(seconds, target)
    floor_score = (floor * 18_500 * time_factor).round
    boss_score = (@tower_bosses_defeated.to_i * 42_000 * time_factor).round
    level_score = tower_time_scaled_level_score(seconds, target)
    damage_score = tower_damage_score(time_factor)
    combat_value = [@score.to_i * 0.10, 0.0].max
    combat_bonus = (260_000 * combat_value / (260_000 + combat_value)).round
    clear_bonus = floor >= PokemonSurvivor::TOWER_MAX_FLOOR ? (1_400_000 * time_factor).round : 0
    @score = [floor_score + boss_score + level_score + damage_score + combat_bonus + clear_bonus, 0].max
    @tower_score_awarded = true
  rescue
  end

  def tower_time_score_factor(seconds, target)
    ratio = target.to_f / [seconds.to_f, 1.0].max
    return [ratio, 0.08].max if ratio <= 1.35
    excess = ratio - 1.35
    1.35 + excess / (1.0 + excess / 0.25)
  rescue
    0.1
  end

  def tower_time_scaled_level_score(seconds, target)
    level = [[@level.to_i, 1].max, 9999].min
    useful_level = [level, 260].min
    over_level = [level - 260, 0].max
    base = (useful_level * 1_100) + (over_level * 70)
    penalty = tower_time_score_factor(seconds, target) / 1.35
    (base * [[penalty, 0.05].max, 1.0].min).round
  rescue
    0
  end

  def tower_damage_score(time_factor)
    clean = [[160_000 - (@tower_damage_taken.to_i * 28), 0].max, 160_000].min
    (clean * [[time_factor, 0.25].max, 1.0].min).round
  rescue
    0
  end

  def apply_tower_boss_stats(enemy)
    floor = [[@tower_floor.to_i, 1].max, PokemonSurvivor::TOWER_MAX_FLOOR].min
    if PokemonSurvivor.tower_final_boss?(enemy.name)
      apply_tower_final_boss_stats(enemy, floor)
    else
      apply_regular_tower_boss_stats(enemy, floor)
    end
    enemy.value = enemy_xp_value(enemy, enemy.name, 80 + (floor * 4))
  rescue
  end

  def apply_regular_tower_boss_stats(enemy, floor)
    boss_rank = [[((floor - 30) / 10) + 1, 1].max, 7].min
    level = [[@level.to_i, 1].max, 9999].min
    level_pressure = [level, 260].min * 620
    overlevel_pressure = [[level - 260, 0].max, 340].min * 110
    hp_by_rank = [0, 92_000, 210_000, 390_000, 650_000, 1_020_000, 1_530_000, 2_220_000]
    floor_pressure = 1.0 + ((floor - 30) * 0.006)
    enemy.max_hp = [((hp_by_rank[boss_rank] + level_pressure + overlevel_pressure) * floor_pressure).round, 1].max
    enemy.damage = 18 + (boss_rank * 7) + (floor / 7) + [[level / 95, 0].max, 8].min
    enemy.speed = 0.66 + [floor * 0.0022, 0.24].min
    enemy.shooter = true
    enemy.cooldown = tower_boss_shot_cooldown
    @rush_boss_ring_timers ||= {}
    @rush_boss_ring_timers[enemy.object_id] = [11.5 - (boss_rank * 0.7), 6.4].max
  rescue
  end

  def apply_tower_final_boss_stats(enemy, floor)
    level = [[@level.to_i, 1].max, 9999].min
    capped_level = [level, 520].min
    overlevel = [[level - 520, 0].max, 480].min
    final_key = PokemonSurvivor.species_key(enemy.name)
    species_mult = case final_key
    when :RAYQUAZA then 1.08
    when :GIRATINA then 1.16
    when :KYUREM then 1.12
    when :ZYGARDE_2 then 1.22
    else 1.10
    end
    enemy.max_hp = [((30_000_000 + (capped_level * 31_000) + (overlevel * 8_000)) * species_mult).round, 1].max
    enemy.damage = 84 + (capped_level / 13) + (overlevel / 55)
    enemy.speed = 0.80
    enemy.attack_type = tower_final_boss_attack_type(final_key)
    enemy.shooter = true
    enemy.cooldown = tower_boss_shot_cooldown
    @rush_boss_ring_timers ||= {}
    @rush_boss_ring_timers[enemy.object_id] = 2.85
  rescue
  end

  def tower_final_boss_attack_type(final_key)
    tower_final_boss_primary_type(final_key)
  rescue
    :FLYING
  end

  def tower_final_boss_primary_type(final_key)
    case final_key
    when :GIRATINA then :GHOST
    when :KYUREM then :ICE
    when :ZYGARDE_2 then :GROUND
    when :TERAPAGOS_1 then :NORMAL
    else :FLYING
    end
  rescue
    :FLYING
  end

  def tower_final_boss_primary_vfx(final_key)
    case final_key
    when :GIRATINA then "VFX_GHOST"
    when :KYUREM then "VFX_ICE"
    when :ZYGARDE_2 then "VFX_GROUND"
    when :TERAPAGOS_1 then "VFX_NORMAL"
    else "VFX_FLYING"
    end
  rescue
    "VFX_FLYING"
  end

  def tower_boss_shot_cooldown
    floor = @tower_floor.to_i
    return 0.26 if floor >= PokemonSurvivor::TOWER_MAX_FLOOR
    [[1.22 - (floor * 0.0065), 0.48].max, 1.22].min
  rescue
    0.9
  end
  def tower_rayquaza_projectile_vfx(enemy, type)
    return nil if !tower_mode? || !enemy || !PokemonSurvivor.tower_final_boss?(enemy.name)
    return @tower_projectile_vfx_override if @tower_projectile_vfx_override
    final_key = PokemonSurvivor.species_key(enemy.name)
    @enemy_ring_projectile_cast ? "VFX_DRAGON" : tower_final_boss_primary_vfx(final_key)
  rescue
    nil
  end
  def current_run_target_seconds
    PokemonSurvivor::DOOM_ONLY_TIME
  rescue
    15 * 60
  end

  def endless_pressure_seconds(seconds = nil)
    seconds = (seconds.nil? ? @timer.to_i : seconds.to_i)
    return seconds if !endless_mode?
    stage = endless_difficulty_stage
    relief = [[@endless_pressure_relief_percent.to_f, 0.0].max, 60.0].min / 100.0
    steady_pressure = stage * (95.0 * (1.0 - relief)).round
    late_pressure = [seconds - (30 * 60), 0].max * 0.20
    late_pressure += [seconds - (45 * 60), 0].max * 0.35
    late_pressure += [seconds - (55 * 60), 0].max * 0.60
    seconds + steady_pressure + late_pressure.round
  rescue
    seconds.to_i
  end

  def ultra_boss_spawn_time
    (current_run_target_seconds * 0.75).to_i
  rescue
    675
  end

  def ultra_chest_interval
    (current_run_target_seconds / 4.0)
  rescue
    225.0
  end

  def ultra_enemy_alive?(kind)
    @enemies.any? { |e| e.kind == kind && e.hp.to_i > 0 }
  rescue
    false
  end

  def update_ultra_spawns
    return if endless_mode?
    if !@ultra_boss_spawned && @timer.to_i >= ultra_boss_spawn_time
      @ultra_boss_spawned = true
      spawn_enemy(:ultra_boss)
    end
    interval = ultra_chest_interval
    while @ultra_chest_quarter.to_i <= 3 && @timer.to_f >= interval * @ultra_chest_quarter.to_i
      spawn_enemy(:ultra_chest) if !ultra_enemy_alive?(:ultra_chest)
      @ultra_chest_quarter = @ultra_chest_quarter.to_i + 1
    end
  rescue
  end

  def spawn_boss
    return @boss_timer = 25.0 if @enemies.any? { |e| e.kind == :boss }
    spawn_enemy(:boss)
    @boss_timer = @timer.to_i < 300 ? 118.0 : 58.0
  end

  def spawn_chest
    return @chest_timer = 18.0 if @enemies.count { |e| e.kind == :chest } >= 2
    spawn_enemy(:chest)
    @chest_timer = @timer.to_i < 300 ? 58.0 : 42.0
  end

  def enqueue_enemy_spawns(kind, count)
    @spawn_queue ||= []
    @spawn_queue_index ||= 0
    count.to_i.times { @spawn_queue << kind }
  rescue
  end

  def spawn_queue_pending?
    @spawn_queue && @spawn_queue_index.to_i < @spawn_queue.length
  rescue
    false
  end

  def process_spawn_queue
    return if !spawn_queue_pending?
    if rush_mode?
      budget = 6
    elsif tower_mode?
      budget = 5
    elsif @run_mode == :classic && @timer.to_i >= PokemonSurvivor::DOOM_ONLY_TIME
      budget = 7
    elsif @timer.to_i >= 780
      budget = 3
    elsif @timer.to_i >= 600
      budget = 4
    else
      budget = 5
    end
    @spawn_queue_index ||= 0
    budget.times do
      break if @spawn_queue_index >= @spawn_queue.length
      kind = @spawn_queue[@spawn_queue_index]
      @spawn_queue_index += 1
      break if !kind
      spawn_enemy(kind)
    end
    if @spawn_queue_index >= @spawn_queue.length
      @spawn_queue.clear
      @spawn_queue_index = 0
    end
  rescue
  end

  def build_bitmap_preload_queue
    queue = []
    PokemonSurvivor.wild_names.each { |name| queue << [PokemonSurvivor::WILD_DIR, name] }
    PokemonSurvivor.boss_names.each { |name| queue << [PokemonSurvivor::BOSS_DIR, name] }
    PokemonSurvivor.chest_names.each { |name| queue << [PokemonSurvivor::CHEST_DIR, name] }
    PokemonSurvivor.ultra_boss_names.each { |name| queue << [PokemonSurvivor::ULTRA_BOSS_DIR, name] }
    PokemonSurvivor.ultra_beast_boss_names.each { |name| queue << [PokemonSurvivor::ULTRA_BEAST_DIR, name] }
    PokemonSurvivor.paradox_boss_names.each { |name| queue << [PokemonSurvivor::PARADOX_DIR, name] }
    PokemonSurvivor.ultra_chest_names.each { |name| queue << [PokemonSurvivor::ULTRA_CHEST_DIR, name] }
    PokemonSurvivor::WILD_ITEMS.each_key { |name| queue << [PokemonSurvivor::ITEM_DIR, name] }
    queue << [PokemonSurvivor::ITEM_DIR, "CHESTBOSS"]
    queue << [PokemonSurvivor::ITEM_DIR, "MOVES"]
    if PokemonSurvivor.const_defined?(:EVENT_DIR)
      queue << [PokemonSurvivor::EVENT_DIR, "EGG"]
      queue << [PokemonSurvivor::EVENT_DIR, "EGG_Idle"]
      queue << [PokemonSurvivor::EVENT_DIR, "EGG_Hurt"]
    end
    if PokemonSurvivor.const_defined?(:EVENT_BABY_DIR)
      (PokemonSurvivor::EVENT_BABY_KEYS rescue []).each do |name|
        queue << [PokemonSurvivor::EVENT_BABY_DIR, name.to_s]
        queue << [PokemonSurvivor::EVENT_BABY_DIR, "#{name}_Idle"]
        queue << [PokemonSurvivor::EVENT_BABY_DIR, "#{name}_Icon"]
      end
    end
    if PokemonSurvivor.const_defined?(:EVENT_BABY_SHINY_DIR)
      (PokemonSurvivor::EVENT_BABY_KEYS rescue []).each do |name|
        queue << [PokemonSurvivor::EVENT_BABY_SHINY_DIR, name.to_s]
        queue << [PokemonSurvivor::EVENT_BABY_SHINY_DIR, "#{name}_Idle"]
        queue << [PokemonSurvivor::EVENT_BABY_SHINY_DIR, "#{name}_Icon"]
      end
    end
    if PokemonSurvivor.const_defined?(:EVENT_SLEEP_DIR)
      (PokemonSurvivor::EVENT_SLEEP_KEYS rescue []).each do |name|
        queue << [PokemonSurvivor::EVENT_SLEEP_DIR, "#{name}_Sleep"]
        queue << [PokemonSurvivor::EVENT_SLEEP_DIR, "#{name}_Pose"]
      end
    end
    queue << [PokemonSurvivor::VFX_DIR, "VFX_QUESTION_EGG"]
    queue << [PokemonSurvivor::VFX_DIR, "VFX_QUESTION_SLEEP"]
    queue.uniq
  rescue
    []
  end

  def process_bitmap_preload_queue
    return if !@bitmap_preload_queue || @bitmap_preload_queue.empty?
    folder, name = @bitmap_preload_queue.shift
    cached_bitmap(folder, name)
  rescue
  end

  def spawn_wild_item
    name = weighted_wild_item_name
    angle = rand * Math::PI * 2
    dist = 90 + rand(150)
    x = Graphics.width / 2 + Math.cos(angle) * dist
    y = Graphics.height / 2 + Math.sin(angle) * dist
    if world_walls_enabled?
      pos = clamp_world_spawn_position(x, y, PokemonSurvivor::ITEM_RADIUS + 8)
      x = pos[0]
      y = pos[1]
    end
    item = PokemonSurvivorEntity.new(:item, name, x, y)
    item.radius = PokemonSurvivor::ITEM_RADIUS
    item.bitmap = cached_bitmap(PokemonSurvivor::ITEM_DIR, name)
    item.color = (PokemonSurvivor::WILD_ITEMS[name] || {})[:color] || Color.white
    item.ttl = PokemonSurvivor::WILD_ITEM_LIFETIME
    @items << item
    @item_timer = [18.0 - (@timer.to_i / 180), 8.0].max + rand(4)
  end

  def weighted_wild_item_name
    weighted = []
    PokemonSurvivor::WILD_ITEMS.each_pair do |name, data|
      next if (@breach_run || arena_mode?) && name.to_s.upcase == "BERRY"
      data[:weight].to_i.times { weighted << name }
    end
    weighted.sample || ((@breach_run || arena_mode?) ? "EXPITEM" : "BERRY")
  rescue
    (@breach_run || arena_mode?) ? "EXPITEM" : "BERRY"
  end

  def update_items(dt)
    @items.each do |item|
      if @storm_collector_timer.to_f > 0
        dx, dy = @hero.x - item.x, @hero.y - item.y
        distance = Math.sqrt(dx * dx + dy * dy)
        if distance > 0
          step = [600.0 * dt, distance].min / distance
          item.x += dx * step
          item.y += dy * step
        end
      end
      item.ttl -= dt unless item.name.to_s.upcase == "MOVES"
      next if !collision?(item, @hero)
      apply_wild_item(item.name, item.value.to_i)
      item.value = 0
    end
    @items.delete_if { |item| item.value.to_i <= 0 || (item.name.to_s.upcase != "MOVES" && item.ttl.to_f <= 0) }
  end

  def apply_wild_item(name, upgrade_count = 1)
    item_name = name.to_s.upcase
    return if @breach_run && item_name == "BERRY"
    case item_name
    when "BERRY"
      berry_rate = 0.28 * (@berry_heal_mult || 1.0).to_f
      hero_needs_heal = @hero.hp.to_i < @hero.max_hp.to_i
      baby_needs_heal = respond_to?(:event_baby_needs_heal?) && event_baby_needs_heal?
      if !hero_needs_heal && !baby_needs_heal
        gain_direct_xp((@xp_next.to_i * 0.20).ceil)
        set_hero_item_flash(Color.new(92, 255, 180), 0.72)
      else
        if hero_needs_heal
          heal = [(@hero.max_hp * berry_rate).round, 20].max
          @hero.hp = [@hero.hp + heal, @hero.max_hp].min
        end
        heal_event_baby_rate(berry_rate, 1) if baby_needs_heal && respond_to?(:heal_event_baby_rate)
        trigger_gauge_flash
        set_hero_item_flash(Color.new(255, 96, 118), 0.72)
      end
    when "EXPITEM"
      @force_magnet_timer = [@force_magnet_timer.to_f, 4.0].max
      set_hero_item_effect_tint(Color.new(92, 255, 180), :@force_magnet_timer)
    when "LIFEITEM"
      @item_invuln_timer = [@item_invuln_timer.to_f, 10.0].max
      set_hero_item_effect_tint(Color.new(255, 238, 96), :@item_invuln_timer)
    when "POWERITEM"
      @power_boost_timer = [@power_boost_timer.to_f, 10.0].max
      set_hero_item_effect_tint(Color.new(255, 132, 64), :@power_boost_timer)
    when "CHESTBOSS"
      if chestboss_bonus_available?
        request_upgrade(0.0, upgrade_count.to_i)
        set_hero_item_flash(Color.new(255, 224, 92), 0.72)
      else
        award_chestboss_currency_fallback(upgrade_count)
      end
    when "MOVES"
      if respond_to?(:request_move_upgrade) && can_drop_moves_item?
        request_move_upgrade(0.0, 1)
        set_hero_item_flash(Color.new(132, 188, 255), 0.72)
      end
    end
    play_survivor_se(:item, "Survivor/Item get", 0.18, PokemonSurvivor::SFX_ITEM_VOLUME, 100)
    PokemonSurvivor.gamepad_vibrate_event(:item_pickup) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
  end

  def chestboss_bonus_available?
    if respond_to?(:real_upgrade_available?)
      available = real_upgrade_available?
      @upgrades_exhausted = false if available
      return available
    end
    pool = available_upgrades rescue []
    pool.any? { |upgrade| !respond_to?(:tower_fallback_upgrade?) || !tower_fallback_upgrade?(upgrade) }
  rescue
    false
  end

  def award_chestboss_currency_fallback(upgrade_count = 1)
    count = [[upgrade_count.to_i, 1].max, 3].min
    if rand(2) == 0 && PokemonSurvivor.respond_to?(:add_candy_currency)
      amount = (18 + rand(13)) * count
      PokemonSurvivor.add_candy_currency(amount)
      show_chestboss_currency_popup("ICON_CANDY", amount)
      set_hero_item_flash(Color.new(255, 154, 196), 0.72)
    else
      amount = (120 + rand(81)) * count
      PokemonSurvivor.add_shop_currency(amount) if PokemonSurvivor.respond_to?(:add_shop_currency)
      show_chestboss_currency_popup("ICON_FRAGMENT", amount)
      set_hero_item_flash(Color.new(92, 210, 255), 0.72)
    end
  rescue
  end

  def show_chestboss_currency_popup(icon_name, amount)
    enqueue_run_reward_popup({
      icon: icon_name.to_s,
      amount: amount.to_i,
      duration: 2.55
    })
  rescue
  end

  def enqueue_run_reward_popup(data)
    @run_reward_popup_queue ||= []
    @run_reward_popup_queue << data
    advance_run_reward_popup if !@chestboss_currency_popup
  end

  def advance_run_reward_popup
    @chestboss_currency_popup = (@run_reward_popup_queue || []).shift
    if @chestboss_currency_popup
      @chestboss_currency_popup[:start] = System.uptime
      fill_run_reward_popup_stack
    end
  end

  def fill_run_reward_popup_stack
    data = @chestboss_currency_popup
    return unless data && data[:name]
    age = System.uptime - data[:start].to_f
    return if age >= 0.6
    stack = (data[:stack] ||= [])
    capacity = [[(Graphics.height - 90) / 66, 1].max, 3].min
    queue = (@run_reward_popup_queue ||= [])
    while stack.length + 1 < capacity && queue.first && queue.first[:name]
      stack << queue.shift
    end
    if !stack.empty? || !queue.empty?
      duration = queue.length >= 6 ? 1.0 : 1.35
      data[:duration] = [data[:duration].to_f, duration].min
    end
  end

  def set_hero_item_flash(color, duration)
    @hero_item_flash_color = color
    @hero_item_flash_timer = [duration.to_f, 0.2].max
  rescue
  end

  def set_hero_item_effect_tint(color, timer)
    @hero_item_effect_tints ||= {}
    # Keep the most recently collected active item last, including repeat pickups.
    @hero_item_effect_tints.delete(timer)
    @hero_item_effect_tints[timer] = color
    @hero_item_flash_color = nil
    @hero_item_flash_timer = 0.0
  end

  def hero_item_active_tint_color
    color = nil
    if @hero_item_effect_tints
      @hero_item_effect_tints.delete_if do |timer, tint|
        expired = instance_variable_get(timer).to_f <= 0.0
        color = tint if !expired
        expired
      end
    end
    return @hero_item_flash_color if @hero_item_flash_timer.to_f > 0.0 && @hero_item_flash_color
    color
  end

  def play_survivor_se(key, name, cooldown = 0.08, volume = 60, pitch = 100)
    @sfx_next_time ||= {}
    now = System.uptime rescue (@timer || 0.0)
    return if @sfx_next_time[key].to_f > now
    @sfx_next_time[key] = now + cooldown.to_f
    pbSEPlay(name, volume, pitch) rescue pbSEPlay(name) rescue nil
  rescue
  end
  def survivor_cry_se_name(name)
    @survivor_cry_se_cache ||= {}
    key = PokemonSurvivor.species_key(name).to_s rescue name.to_s.upcase.gsub(/[^A-Z0-9_]/, "")
    return @survivor_cry_se_cache[key] if @survivor_cry_se_cache.key?(key)
    candidates = [key]
    candidates << key.sub(/_\d+\z/, "") if key[/_\d+\z/]
    result = nil
    candidates.uniq.each do |candidate|
      ["ogg", "wav", "mp3"].each do |ext|
        if File.exist?("Audio/SE/Cries/#{candidate}.#{ext}")
          result = "Cries/#{candidate}"
          break
        end
      end
      break if result
    end
    @survivor_cry_se_cache[key] = result
  rescue
    nil
  end
  def play_survivor_cry(name, volume = 72, pitch = 100)
    se = survivor_cry_se_name(name)
    return if !se || se.empty?
    pbSEPlay(se, volume, pitch) rescue pbSEPlay(se) rescue nil
  rescue
  end

  def queue_survivor_cry(name, volume = 72, pitch = 100, delay = 0.06)
    @pending_survivor_cries ||= []
    @pending_survivor_cries << {
      name: name,
      volume: volume,
      pitch: pitch,
      delay: [delay.to_f, 0.0].max
    }
  rescue
  end

  def update_survivor_cry_queue(dt)
    return if !@pending_survivor_cries || @pending_survivor_cries.empty?
    @pending_survivor_cries.each { |cry| cry[:delay] = cry[:delay].to_f - dt.to_f }
    ready, waiting = @pending_survivor_cries.partition { |cry| cry[:delay].to_f <= 0.0 }
    @pending_survivor_cries = waiting
    ready.each { |cry| play_survivor_cry(cry[:name], cry[:volume], cry[:pitch]) }
  rescue
    @pending_survivor_cries = []
  end

  def special_enemy_cry_kind?(kind)
    kind == :chest || kind == :ultra_chest || kind == :boss || kind == :ultra_boss
  rescue
    false
  end

  def play_enemy_spawn_cry(enemy)
    return if !enemy || !special_enemy_cry_kind?(enemy.kind)
    return if enemy.instance_variable_get(:@spawn_cry_played)
    enemy.instance_variable_set(:@spawn_cry_played, true)
    play_survivor_cry(enemy.name, enemy.kind == :ultra_boss ? 82 : 74, 100)
  rescue
  end

  def play_enemy_ko_cry(enemy)
    return if !enemy || !special_enemy_cry_kind?(enemy.kind)
    return if enemy.instance_variable_get(:@ko_cry_played)
    enemy.instance_variable_set(:@ko_cry_played, true)
    play_survivor_cry(enemy.name, enemy.kind == :ultra_boss ? 82 : 74, 94)
  rescue
  end

  def update_tower_floor_background
    return if !tower_mode?
    floor = [[@tower_floor.to_i, 1].max, PokemonSurvivor::TOWER_MAX_FLOOR].min
    target = floor >= PokemonSurvivor::TOWER_MAX_FLOOR ? (@tower_final_boss_name || PokemonSurvivor::TOWER_FINAL_BOSS) : PokemonSurvivor::TOWER_BACKGROUND
    @bg_name = target.to_s if @bg_name.to_s != target.to_s
  rescue
  end

  def update_tower_floor_bgm
    return if !tower_mode?
    floor = [[@tower_floor.to_i, 1].max, PokemonSurvivor::TOWER_MAX_FLOOR].min
    return if floor >= PokemonSurvivor::TOWER_MAX_FLOOR
    bucket = floor / 20
    return if bucket <= 0 || @tower_bgm_floor_bucket.to_i == bucket
    choices = PokemonSurvivor.classic_background_names
    choices = choices.reject { |name| name.to_s == @rush_bgm_name.to_s } if choices.length > 1
    @tower_bgm_floor_bucket = bucket
    @rush_bgm_name = choices.sample.to_s
    play_survivor_bgm_name(PokemonSurvivor.bgm_for_background(@rush_bgm_name))
  rescue
  end

  def play_survivor_bgm
    bgm = arena_mode? ? PokemonSurvivor.bgm_for_background(@rush_bgm_name) : PokemonSurvivor.bgm_for_background(@bg_name)
    play_survivor_bgm_name(bgm)
  rescue
  end

  def play_survivor_bgm_name(bgm)
    bgm = bgm.to_s.empty? ? PokemonSurvivor::DEFAULT_BGM : bgm.to_s
    return if @survivor_current_bgm == bgm
    @survivor_current_bgm = bgm
    @survivor_bgm_playing = true
    pbBGMPlay(bgm, PokemonSurvivor.survivor_bgm_volume, 100) rescue pbBGMPlay(PokemonSurvivor::DEFAULT_BGM, PokemonSurvivor.survivor_bgm_volume, 100) rescue nil
  rescue
  end

  def play_boss_encounter_bgm(kind, name)
    if tower_mode? && PokemonSurvivor.tower_final_boss?(name)
      play_survivor_bgm_name("Survivor/#{PokemonSurvivor.species_key(name)}")
    elsif rush_mode? && (kind == :boss || kind == :ultra_boss)
      generation = @rush_boss_generation || PokemonSurvivor.rush_boss_generation_for_sequence(@rush_boss_sequence)
      play_survivor_bgm_name(PokemonSurvivor.bgm_for_rush_generation(generation))
    elsif !arena_mode? && kind == :ultra_boss
      play_survivor_bgm_name(PokemonSurvivor::ULTRA_BOSS_BGM)
    end
  rescue
  end

  def play_survivor_menu_bgm
    bgm = @survivor_menu_bgm || (@state == :shop ? "Survivor/Breach" : PokemonSurvivor::MENU_BGM)
    play_survivor_bgm_name(bgm)
  rescue
  end

  def play_survivor_upgrade_bgm
    return if !PokemonSurvivor::UPGRADE_BGM
    play_survivor_bgm_name(PokemonSurvivor::UPGRADE_BGM)
  rescue
  end

  def play_survivor_result_bgm
    play_survivor_bgm_name(PokemonSurvivor::RESULT_BGM)
  rescue
  end

  def stop_survivor_bgm
    return if !@survivor_bgm_playing
    @survivor_bgm_playing = false
    pbBGMStop(1.0) rescue pbBGMStop rescue nil
  rescue
  end

  def trigger_gauge_flash(duration = 0.45)
    @gauge_flash_timer = [duration.to_f, 0.1].max
  rescue
  end


  def clamp_world_spawn_position(x, y, margin = 40)
    return [x, y] if !world_walls_enabled?
    cx = Graphics.width / 2.0
    cy = Graphics.height / 2.0
    min_x = cx - world_limit_x - @world_x.to_f + margin.to_f
    max_x = cx + world_limit_x - @world_x.to_f - margin.to_f
    min_y = cy - world_limit_y - @world_y.to_f + margin.to_f
    max_y = cy + world_limit_y - @world_y.to_f - margin.to_f
    safe_x = min_x > max_x ? cx : [[x.to_f, min_x].max, max_x].min
    safe_y = min_y > max_y ? cy : [[y.to_f, min_y].max, max_y].min
    [safe_x, safe_y]
  rescue
    [x, y]
  end
  def spawn_enemy(kind, forced_name = nil)
    angle = rand * Math::PI * 2
    dist = if rush_mode? && kind == :wild
             190 + rand(130)
           else
             [Graphics.width, Graphics.height].max / 2 + 52
           end
    x = Graphics.width / 2 + Math.cos(angle) * dist
    y = Graphics.height / 2 + Math.sin(angle) * dist
    if world_walls_enabled?
      pos = clamp_world_spawn_position(x, y, kind == :wild ? 34 : 58)
      x = pos[0]
      y = pos[1]
    end
    name = if forced_name
             forced_name
           elsif kind == :wild && @doom_final_started && !arena_mode?
             PokemonSurvivor::DOOM_ENEMY_NAME
           elsif kind == :boss
             tower_mode? ? PokemonSurvivor.tower_boss_names.sample : PokemonSurvivor.boss_names.sample
           elsif kind == :chest
             PokemonSurvivor.chest_names.sample
           elsif kind == :ultra_boss
             PokemonSurvivor.ultra_boss_names.sample
           elsif kind == :ultra_chest
             PokemonSurvivor.ultra_chest_names.sample
           else
              pool = PokemonSurvivor.spawn_wild_enemy_pool(arena_mode?, endless_mode?)
              seconds = arena_mode? ? 0 : (endless_mode? ? [endless_pressure_seconds(@timer.to_i), PokemonSurvivor::DOOM_ONLY_TIME - 1].min : @timer.to_i)
              PokemonSurvivor.weighted_enemy_name(pool, PokemonSurvivor.enemy_progress_tier(seconds, @level), @level, seconds, @base_attack_type)
           end
    return if !PokemonSurvivor.valid_survivor_species?(name) && !(name.to_s == PokemonSurvivor::DOOM_ENEMY_NAME && @run_mode == :classic)
    e = PokemonSurvivorEntity.new(kind, name, x, y)
    @doom_spawn_count += 1 if kind == :wild && PokemonSurvivor.doom_enemy?(name)
    e.types = PokemonSurvivor.species_types(name)
    e.attack_type = e.types[0] || :NORMAL
    e.shooter = enemy_can_shoot?(name, kind)
    e.archetype = enemy_archetype(kind)
    mod = PokemonSurvivor::ENEMY_ARCHETYPES[e.archetype] || PokemonSurvivor::ENEMY_ARCHETYPES[:normal]
    tier = PokemonSurvivor.enemy_progress_tier(endless_mode? ? endless_pressure_seconds(@timer.to_i) : @timer.to_i, @level)
    species_scale = 0.86 + (PokemonSurvivor.species_base_total(name) / 520.0)
    stage_scale = 1.0 + (PokemonSurvivor.evolution_stage(name) * 0.16)
    level_scale = 1.0 + ([(@level.to_i - 1), 0].max * 0.026)
    phase_scale = 1.0 + (PokemonSurvivor.hero_difficulty_phase(@level) * 0.16)
    late_hp_scale = 1.0 + [[((endless_mode? ? endless_pressure_seconds(@timer.to_i) : @timer.to_i) - 360), 0].max / 600.0, endless_mode? ? 2.6 : 0.85].min
    complete_build_scale = @upgrades_exhausted ? 1.28 : 1.0
    scale = (0.62 + ((endless_mode? ? endless_pressure_seconds(@timer.to_i) : @timer.to_i) / 270.0) + (tier * 0.08)) * species_scale * stage_scale * level_scale * phase_scale * late_hp_scale * complete_build_scale
    case kind
    when :boss
      e.max_hp = (360 * scale * (1.0 + [@timer.to_i / 900.0, 0.55].min)).round
      e.damage = (20 + @timer / 48).round
      e.speed = 0.70
      e.radius = PokemonSurvivor::BOSS_RADIUS
      e.value = enemy_xp_value(e, name, 22)
      e.bitmap = arena_mode? ? cached_enemy_role_bitmap(name, [PokemonSurvivor::BOSS_DIR, PokemonSurvivor::ULTRA_BEAST_DIR, PokemonSurvivor::PARADOX_DIR, PokemonSurvivor::ULTRA_BOSS_DIR, PokemonSurvivor::WILD_DIR]) : cached_bitmap(PokemonSurvivor::BOSS_DIR, name)
    when :chest
      e.max_hp = (88 * scale).round
      e.damage = 0
      e.speed = 0.45
      e.radius = PokemonSurvivor::CHEST_RADIUS
      e.value = enemy_xp_value(e, name, (28 * @chest_xp_mult).round)
      e.bitmap = cached_bitmap(PokemonSurvivor::CHEST_DIR, name)
    when :ultra_boss
      e.max_hp = (1100 * scale * (1.25 + [@timer.to_i / current_run_target_seconds.to_f, 0.75].min)).round
      e.damage = (32 + @timer / 34).round
      e.speed = 0.82
      e.radius = PokemonSurvivor::ULTRA_BOSS_RADIUS
      e.value = enemy_xp_value(e, name, 70)
      e.bitmap = arena_mode? ? cached_enemy_role_bitmap(name, [PokemonSurvivor::ULTRA_BOSS_DIR, PokemonSurvivor::BOSS_DIR, PokemonSurvivor::ULTRA_BEAST_DIR, PokemonSurvivor::PARADOX_DIR, PokemonSurvivor::WILD_DIR]) : cached_bitmap(PokemonSurvivor::ULTRA_BOSS_DIR, name)
    when :ultra_chest
      e.max_hp = (260 * scale).round
      e.damage = 0
      e.speed = 0.38
      e.radius = PokemonSurvivor::ULTRA_CHEST_RADIUS
      e.value = enemy_xp_value(e, name, (48 * @chest_xp_mult).round)
      e.bitmap = cached_bitmap(PokemonSurvivor::ULTRA_CHEST_DIR, name)
    else
      e.max_hp = (31 * scale).round
      e.damage = (6 + (endless_mode? ? endless_pressure_seconds(@timer.to_i) : @timer.to_i) / 95).round
      e.speed = 0.82 + [(endless_mode? ? endless_pressure_seconds(@timer.to_i) : @timer.to_i) / 460.0, endless_mode? ? 1.35 : 0.76].min
      e.radius = PokemonSurvivor::ENEMY_RADIUS
      e.value = enemy_xp_value(e, name, 3 + ((endless_mode? ? endless_pressure_seconds(@timer.to_i) : @timer.to_i) / 105).to_i)
      e.bitmap = cached_bitmap(PokemonSurvivor::WILD_DIR, name)
    end
    if kind != :chest && kind != :ultra_chest
      e.max_hp = [(e.max_hp * mod[:hp]).round, 1].max
      e.damage = [(e.damage * mod[:damage] * enemy_late_damage_multiplier).round, 1].max
      e.speed *= mod[:speed]
      e.value = [(e.value * mod[:value]).round, 1].max
      e.radius = [(e.radius * mod[:radius]).round, 8].max
    end
    if PokemonSurvivor.eight_direction_bitmap?(e.bitmap)
      e.charset_directions = PokemonSurvivor::CHARSET_8_DIRECTIONS
    end
    apply_doom_enemy_stats(e) if PokemonSurvivor.doom_enemy?(name)
    e.archetype = :normal if kind == :wild && e.archetype != :normal && active_reinforced_wild_count >= PokemonSurvivor::MAX_REINFORCED_WILD_ENEMIES
    apply_classic_ultra_boss_stats(e) if !arena_mode? && kind == :ultra_boss
    apply_rush_boss_stats(e) if rush_mode? && (kind == :boss || kind == :ultra_boss)
    apply_tower_boss_stats(e) if tower_mode? && (kind == :boss || kind == :ultra_boss)
    e.hp = e.max_hp
    @enemies << e
    play_enemy_spawn_cry(e)
    if kind == :boss || kind == :ultra_boss
      PokemonSurvivor.gamepad_vibrate_event(kind == :ultra_boss ? :ultra_boss_spawn : :boss_spawn) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
    end
    play_boss_encounter_bgm(kind, name)
  end


  def cached_enemy_role_bitmap(name, folders)
    search_folders = (folders || []) + [PokemonSurvivor::WILD_DIR, PokemonSurvivor::HERO_DIR, PokemonSurvivor::HERO_SHINY_DIR]
    search_folders.compact.uniq.each do |folder|
      next if !(PokemonSurvivor.resolve(folder, name) rescue nil)
      bmp = cached_bitmap(folder, name)
      return bmp if bmp && !bmp.disposed?
    end
    cached_bitmap(PokemonSurvivor::WILD_DIR, name)
  rescue
    nil
  end

  def apply_classic_ultra_boss_stats(enemy)
    enemy.max_hp = [(enemy.max_hp.to_i * 10), 1].max
    enemy.shooter = true
    enemy.cooldown = rush_boss_shot_cooldown
    @rush_boss_ring_timers ||= {}
    @rush_boss_ring_timers[enemy.object_id] = 30.0
  rescue
  end

  def rush_style_boss_projectile?(enemy)
    return false if !enemy
    return true if arena_mode? && (enemy.kind == :boss || enemy.kind == :ultra_boss)
    return true if !arena_mode? && enemy.kind == :ultra_boss
    false
  rescue
    false
  end
  def apply_rush_boss_stats(enemy)
    wave = [[@rush_wave_index.to_i, 0].max, PokemonSurvivor::RUSH_BOSS_HP.length - 1].min
    hp = PokemonSurvivor::RUSH_BOSS_HP[wave].to_i
    damage = PokemonSurvivor::RUSH_BOSS_DAMAGE[wave].to_i
    enemy.max_hp = [(hp * (1.0 + [@level.to_i - 1, 0].max * 0.006)).round, 1].max
    enemy.damage = damage
    enemy.speed = 0.68 + (wave * 0.06)
    enemy.value = enemy_xp_value(enemy, enemy.name, PokemonSurvivor::RUSH_BOSS_XP[wave].to_i)
    enemy.shooter = true
    enemy.cooldown = [0.45, PokemonSurvivor::RUSH_BOSS_SHOT_COOLDOWNS[wave].to_f * 0.65].max
    enemy.radius = (wave >= 3) ? PokemonSurvivor::ULTRA_BOSS_RADIUS : PokemonSurvivor::BOSS_RADIUS
    @rush_boss_ring_timers ||= {}
    @rush_boss_ring_timers[enemy.object_id] = 30.0
  rescue
  end
  def enemy_late_damage_multiplier
    return 1.0 if rush_mode?
    seconds = endless_mode? ? endless_pressure_seconds(@timer.to_i) : @timer.to_i
    return 1.0 if seconds < 600
    if endless_mode?
      stage = endless_difficulty_stage
      progress = [[(seconds - 600).to_f / 900.0, 0.0].max, 1.0].min
      late_stage = [[stage - 5, 0].max, 8].min
      mult = 1.06 + (progress * 0.18) + (late_stage * 0.055)
      mult += [[(@timer.to_f - (45 * 60)) / 900.0, 0.0].max, 1.0].min * 0.28
      mult += [[(@timer.to_f - (55 * 60)) / 600.0, 0.0].max, 1.0].min * 0.22
      mult += 0.10 if @hero && @hero.max_hp.to_i >= 170
      mult += 0.10 if @vampiric_chance.to_f > 0
      mult += 0.08 if @upgrades_exhausted
      return [mult, 2.15].min
    end
    progress = [[(seconds - 600).to_f / 300.0, 0.0].max, 1.0].min
    mult = 1.08 + (progress * 0.20)
    mult += 0.08 if @hero && @hero.max_hp.to_i >= 170
    mult += 0.08 if @vampiric_chance.to_f > 0
    mult += 0.06 if @upgrades_exhausted
    [mult, 1.45].min
  rescue
    1.0
  end
  def enemy_xp_value(enemy, name, base_value)
    value = base_value.to_i
    stage = PokemonSurvivor.evolution_stage(name)
    total = PokemonSurvivor.species_base_total(name)
    species_mult = 1.0 + [[(total.to_i - 260) / 190.0, 0.0].max, 2.25].min
    value = (value * species_mult).round
    value = (value * (1.0 + (stage * 0.60))).round
    value = (value * 1.25).round if total >= 460
    value = (value * 1.45).round if total >= 535
    value = (value * 3.0).round if enemy && enemy.kind == :boss
    value = (value * 5.0).round if enemy && enemy.kind == :ultra_boss
    value = (value * 2.0).round if enemy && enemy.kind == :chest
    value = (value * 3.0).round if enemy && enemy.kind == :ultra_chest
    value = (value * 5.0).round if PokemonSurvivor.doom_enemy?(name)
    value = (value * effective_run_xp_multiplier).round
    [value, 1].max
  rescue
    [base_value.to_i, 1].max
  end

  def apply_doom_enemy_stats(enemy)
    rank = [@doom_spawn_count.to_i, 1].max
    minutes_over = [[(@timer.to_i - PokemonSurvivor::DOOM_START_TIME) / 60, 0].max, 60].min
    enemy.archetype = :elite
    enemy.max_hp = 250_000 + (rank * 125_000) + (minutes_over * 75_000)
    enemy.damage = 60 + (rank * 8) + (minutes_over * 4)
    doom_speed = 0.62 + [minutes_over * 0.015, 0.55].min
    doom_speed = @hero.speed.to_f if @timer.to_i >= PokemonSurvivor::DOOM_ONLY_TIME && @hero
    enemy.speed = doom_speed
    enemy.radius = PokemonSurvivor::BOSS_RADIUS
    enemy.value = enemy_xp_value(enemy, enemy.name, 80 + (rank * 10))
  end

  def active_reinforced_wild_count
    (@enemies || []).count do |enemy|
      enemy && enemy.hp.to_i > 0 && enemy.kind == :wild && enemy.archetype && enemy.archetype != :normal
    end
  rescue
    0
  end

  def enemy_archetype(kind)
    return :normal if kind == :chest || kind == :ultra_chest
    return :elite if kind == :boss || kind == :ultra_boss
    return :normal if kind == :wild && active_reinforced_wild_count >= PokemonSurvivor::MAX_REINFORCED_WILD_ENEMIES
    roll = rand(100)
    tier = PokemonSurvivor.enemy_progress_tier(endless_mode? ? endless_pressure_seconds(@timer.to_i) : @timer.to_i, @level)
    phase = PokemonSurvivor.hero_difficulty_phase(@level)
    return :elite if phase >= 2 && tier >= 3 && roll < 8
    return :elite if phase >= 1 && tier >= 2 && @level.to_i >= 34 && roll < 3
    return :sharp if @level.to_i >= 18 && roll < 6 + (tier * 2) + (phase * 2)
    return :sturdy if @timer >= 45 && roll < 15 + (tier * 3) + (phase * 3)
    return :quick if @timer >= 30 && roll < 34 + (tier * 3) + (phase * 3)
    :normal
  end

  def boss_catchup_speed_mult(enemy, distance)
    return 1.0 if !enemy
    kind = enemy.kind
    return 1.0 if kind != :boss && kind != :ultra_boss && kind != :chest && kind != :ultra_chest
    threshold = (kind == :chest || kind == :ultra_chest) ? 270.0 : 310.0
    return 1.0 if distance.to_f <= threshold
    extra = (distance.to_f - threshold) / 220.0
    cap = (kind == :ultra_boss || kind == :ultra_chest) ? 2.25 : 2.0
    [[1.0 + extra, 1.0].max, cap].min
  rescue
    1.0
  end
  def update_enemies(dt)
    @enemies.each do |e|
      update_enemy_status(e, dt)
      next if e.hp <= 0
      dx = @hero.x - e.x
      dy = @hero.y - e.y
      len = Math.sqrt(dx * dx + dy * dy)
      next if len <= 0
      e.slow_timer = [e.slow_timer.to_f - dt, 0.0].max if e.slow_timer.to_f > 0
      e.freeze_timer = [e.freeze_timer.to_f - dt, 0.0].max if e.freeze_timer.to_f > 0
      e.moving = true
      e.direction = e.charset_directions.to_i >= PokemonSurvivor::CHARSET_8_DIRECTIONS ? direction_from_vector_8(dx, dy) : direction_from_vector(dx, dy)
      slow_mult = e.freeze_timer.to_f > 0 ? 0.0 : (e.slow_timer.to_f > 0 ? e.slow_mult.to_f : 1.0)
      catchup_mult = boss_catchup_speed_mult(e, len)
      move_speed = e.speed * slow_mult * catchup_mult
      e.x += dx / len * move_speed * 60.0 * dt
      e.y += dy / len * move_speed * 60.0 * dt
      update_enemy_shot(e, dt)
      if !arena_mode? && PokemonSurvivor.doom_enemy?(e.name) && collision?(e, @hero)
        if @timer.to_i >= PokemonSurvivor::DOOM_ONLY_TIME
          hero_take_damage(@hero.hp.to_i, 0.0)
        elsif @invuln <= 0
          hurt = [(@hero.max_hp * 0.5).ceil, 1].max
          hero_take_damage(hurt, 0.55)
        end
        next
      end
      if collision?(e, @hero) && @invuln <= 0
        next if @item_invuln_timer > 0
        type_mod = PokemonSurvivor.type_multiplier(e.attack_type, @hero.types)
        hurt = (e.damage.to_i * type_mod * @shield_mult * (@equipment_contact_mult || 1.0) * mewtwo_guard_multiplier).ceil
        hurt = 1 if hurt < 1 && e.damage.to_i > 0
        hero_take_damage(hurt, 0.55)
      end
    end
    invalidate_enemy_grid
  end

  def hero_take_damage(amount, invuln_time = 0.55)
    return if @eevee_burst_timer.to_f > 0.0
    amount = (amount.to_i * deoxys_damage_taken_multiplier * aegislash_damage_taken_multiplier * (@guarded_heart_mult || 1.0)).ceil
    return if amount <= 0 || !@hero
    amount = breach_absorb_damage(amount, invuln_time) if @breach_run && respond_to?(:breach_absorb_damage)
    return if amount <= 0
    @equipment_last_hit_time = @timer.to_f
    if @passive_key == :GASTLY && !@passive_fatal_guard_used && amount >= @hero.hp.to_i
      @passive_fatal_guard_used = true
      @hero.hp = 1
      @invuln = [invuln_time.to_f, 1.2].max
      set_hero_item_flash(Color.new(154, 116, 224), 0.9)
      play_survivor_se(:fatal_guard, "Survivor/Battle recall", 0.8, PokemonSurvivor::SFX_EVOLUTION_VFX_VOLUME, 118)
      return
    elsif @passive_key == :MIMIKYU && !@passive_fatal_guard_used && amount >= @hero.hp.to_i
      @passive_fatal_guard_used = true
      @mimikyu_disguise_broken = true
      setup_hero_sprite_set(:MIMIKYU_1) if respond_to?(:setup_hero_sprite_set)
      @hero.types = PokemonSurvivor.species_types(:MIMIKYU_1) rescue @hero.types
      @damage_mult *= 2.0
      @hero.hp = @hero.max_hp
      @invuln = [invuln_time.to_f, 1.8].max
      set_hero_item_flash(Color.new(255, 150, 218), 1.1)
      play_survivor_se(:mimikyu_disguise, "Survivor/Shiny sparkle", 0.8, PokemonSurvivor::SFX_EVOLUTION_VFX_VOLUME, 110)
      return
    elsif @bonus_fatal_guard_enabled && @bonus_fatal_guard_charges.to_i > 0 && amount >= @hero.hp.to_i
      @bonus_fatal_guard_charges = [@bonus_fatal_guard_charges.to_i - 1, 0].max
      @bonus_fatal_guard_enabled = @bonus_fatal_guard_charges.to_i > 0
      @bonus_fatal_guard_used = @bonus_fatal_guard_charges.to_i <= 0
      @hero.hp = [(@hero.max_hp.to_i * 0.25).round, 1].max
      @invuln = [invuln_time.to_f, 1.5].max
      trigger_gauge_flash
      set_hero_item_flash(Color.new(255, 238, 160), 1.0)
      play_survivor_se(:second_wind, "Survivor/Battle recall", 0.8, PokemonSurvivor::SFX_EVOLUTION_VFX_VOLUME, 112)
      return
    end
    @clean_focus_nohit_timer = 0.0 if @clean_focus_charge_mult.to_f > 1.0
    reset_starly_hit_chain if respond_to?(:reset_starly_hit_chain)
    @tower_damage_taken = @tower_damage_taken.to_i + amount.to_i if tower_mode?
    @hero.hp -= amount
    play_survivor_se(:hero_hit, "Survivor/Battle damage super", 0.28, PokemonSurvivor::SFX_HERO_HIT_VOLUME, 92)
    PokemonSurvivor.gamepad_vibrate_event(:hero_hit, [[amount.to_f / [@hero.max_hp.to_f, 1.0].max * 4.0, 0.45].max, 1.25].min) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
    @passive_hit_power_timer = 4.0 if @passive_key == :MACHOP && @hero.hp.to_i > 0
    mark_lost_half_hp_if_needed
    @invuln = invuln_time.to_f if invuln_time.to_f > 0
  rescue
  end

  def mark_lost_half_hp_if_needed
    return if @lost_half_hp || !@hero || @hero.max_hp.to_i <= 0
    @lost_half_hp = true if (@hero.hp.to_f / @hero.max_hp.to_f) <= 0.50
  rescue
  end
  def break_dragon_chains
    return if !@projectiles
    @projectiles.delete_if { |p| dragon_chain_projectile?(p) }
  rescue
  end

  def refresh_dragon_chains
    return if !@projectiles || !@hero
    skill = PokemonSurvivor::SKILLS[:dragon_arc]
    skill_id = :dragon_arc
    chains = @projectiles.select { |p| dragon_chain_projectile?(p) }
    return if chains.empty?
    base_radius = skill[:radius].to_i + @skill_radius_bonus[skill_id]
    spacing = 14
    rotation_speed = skill[:speed].to_f + (@skill_orbit_speed_bonus[skill_id].to_i * 0.18)
    chains.each_with_index do |p, i|
      ring = i % [[skill[:count].to_i + @skill_count_bonus[skill_id], 1].max, (skill[:max_count] || 8).to_i].min
      p.orbit_radius = [p.orbit_radius.to_f, base_radius + (spacing * ring)].max
      p.speed = rotation_speed
      p.ttl = [p.ttl.to_f, 0.35].max
    end
  rescue
  end

  def reserve_projectile_slots(required)
    return if !@projectiles
    required = [required.to_i, 0].max
    overflow = @projectiles.length + required - PokemonSurvivor::MAX_PROJECTILES
    return if overflow <= 0
    @projectiles.delete_if do |p|
      break false if overflow <= 0
      next false if dragon_chain_projectile?(p) || p.owner == :enemy
      overflow -= 1
      true
    end
    overflow = @projectiles.length + required - PokemonSurvivor::MAX_PROJECTILES
    return if overflow <= 0
    @projectiles.delete_if do |p|
      break false if overflow <= 0
      next false if dragon_chain_projectile?(p)
      overflow -= 1
      true
    end
  rescue
  end

  def update_enemy_status(enemy, dt)
    return if !enemy || enemy.hp <= 0
    if enemy.dot_timer.to_f > 0
      enemy.dot_timer = [enemy.dot_timer.to_f - dt, 0.0].max
      enemy.dot_tick_timer = enemy.dot_tick_timer.to_f - dt
      if enemy.dot_tick_timer <= 0
        enemy.hp -= [(enemy.dot_damage.to_i * post_100_bonus_multiplier).ceil, 1].max
        enemy.dot_tick_timer = 0.45
        if enemy.hp <= 0
          on_enemy_defeated_by_source(enemy, enemy.dot_source) if respond_to?(:on_enemy_defeated_by_source)
          defeat_enemy(enemy)
        end
      end
    end
  rescue
  end

  def enemy_can_shoot?(name, kind = :wild)
    return false if kind == :chest || kind == :ultra_chest
    return true if rush_mode? && (kind == :boss || kind == :ultra_boss)
    return true if kind == :ultra_boss
    return true if kind == :boss && PokemonSurvivor.species_types(name).any? { |type| [:FIRE, :WATER, :ELECTRIC, :ICE, :PSYCHIC, :GHOST, :DRAGON, :DARK].include?(type) }
    PokemonSurvivor::ENEMY_SHOOTERS.include?(PokemonSurvivor.species_key(name))
  rescue
    false
  end

  def update_enemy_shot(enemy, dt)
    return if !enemy.shooter || enemy.kind == :chest || enemy.kind == :ultra_chest
    return if !arena_mode? && enemy.kind != :ultra_boss && @timer.to_i < 150
    return if !arena_mode? && enemy.kind != :ultra_boss && @level.to_i < 25
    return if !enemy_visible?(enemy)
    update_rush_boss_ring_attack(enemy, dt) if rush_style_boss_projectile?(enemy) && !tower_style_boss_projectile?(enemy)
    update_tower_boss_special_attacks(enemy, dt) if tower_style_boss_projectile?(enemy)
    return if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
    enemy.cooldown -= dt
    return if enemy.cooldown > 0
    dx = @hero.x - enemy.x
    dy = @hero.y - enemy.y
    len = [Math.sqrt(dx * dx + dy * dy), 1].max
    spawn_enemy_projectile(enemy, dx / len, dy / len)
    enemy.cooldown = if rush_style_boss_projectile?(enemy)
                       rush_boss_shot_cooldown
                     elsif enemy.kind == :ultra_boss
                       [2.15 - (@timer.to_i / 900.0), 0.92].max
                     else
                       [3.3 - (@timer.to_i / 420.0) - (@level.to_i * 0.025), 1.15].max
                     end
  end


  def tower_style_boss_projectile?(enemy)
    return false if !enemy || !(enemy.kind == :boss || enemy.kind == :ultra_boss)
    return true if tower_mode?
    return true if rush_mode?
    return true if !arena_mode? && enemy.kind == :ultra_boss
    false
  rescue
    false
  end

  def tower_rayquaza_enemy?(enemy)
    tower_mode? && enemy && PokemonSurvivor.tower_final_boss?(enemy.name)
  rescue
    false
  end

  def update_tower_boss_special_attacks(enemy, dt)
    return if !tower_style_boss_projectile?(enemy)
    return if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES - 16
    if tower_rayquaza_enemy?(enemy)
      update_rayquaza_special_attacks(enemy, dt)
    else
      update_regular_tower_boss_special_attacks(enemy, dt)
    end
  rescue
  end

  def tower_boss_pattern_timer(enemy, key, default)
    @tower_boss_pattern_timers ||= {}
    data = (@tower_boss_pattern_timers[enemy.object_id] ||= {})
    data[key] = default.to_f if !data.key?(key)
    data
  rescue
    {}
  end

  def boss_pattern_pressure(enemy)
    if tower_mode?
      return [[@tower_floor.to_i, 1].max, PokemonSurvivor::TOWER_MAX_FLOOR].min
    elsif rush_mode?
      wave = [[@rush_wave_index.to_i, 0].max, 3].min
      return enemy && enemy.kind == :ultra_boss ? 92 : 38 + (wave * 16)
    end
    75
  rescue
    50
  end

  def boss_pattern_timer_mult(enemy)
    return 0.58 if rush_mode? && enemy && enemy.kind == :ultra_boss
    return 0.78 if rush_mode?
    return 0.88 if !arena_mode? && enemy && enemy.kind == :ultra_boss
    1.0
  rescue
    1.0
  end

  def update_regular_tower_boss_special_attacks(enemy, dt)
    pressure = boss_pattern_pressure(enemy)
    timer_mult = boss_pattern_timer_mult(enemy)
    data = tower_boss_pattern_timer(enemy, :fan, rush_mode? && enemy.kind == :ultra_boss ? 0.75 : 2.4)
    data[:fan] = data[:fan].to_f - dt.to_f
    if data[:fan] <= 0
      data[:fan] = [[5.2 - (pressure * 0.025), 2.1].max, 5.2].min * timer_mult
      count = pressure >= 70 ? 7 : (pressure >= 50 ? 5 : 3)
      count += 2 if rush_mode? && enemy.kind == :ultra_boss
      tower_spawn_fan(enemy, count, Math::PI / 4.0, enemy.attack_type || :NORMAL, nil, 1.0, rush_mode? ? 1.08 : 1.0)
    end
    data[:cross] = data.fetch(:cross, rush_mode? && enemy.kind == :ultra_boss ? 2.8 : 5.5).to_f - dt.to_f
    if data[:cross] <= 0
      data[:cross] = [[8.5 - (pressure * 0.035), 3.6].max, 8.5].min * timer_mult
      ring_count = pressure >= 60 ? 12 : 8
      ring_count += 4 if rush_mode? && enemy.kind == :ultra_boss
      tower_spawn_ring(enemy, ring_count, enemy.attack_type || :NORMAL, nil, 0.82, rush_mode? ? 1.0 : 0.92, 0.15)
    end
    data[:spiral] = data.fetch(:spiral, rush_mode? && enemy.kind == :ultra_boss ? 3.2 : 7.0).to_f - dt.to_f
    if pressure >= 50 && data[:spiral] <= 0
      data[:spiral] = 6.0 * timer_mult
      spiral_count = pressure >= 80 ? 14 : 10
      spiral_count += 4 if rush_mode? && enemy.kind == :ultra_boss
      tower_spawn_spiral(enemy, spiral_count, enemy.attack_type || :NORMAL, nil, 0.75, rush_mode? ? 1.18 : 1.08)
    end
  rescue
  end

  def update_rayquaza_special_attacks(enemy, dt)
    final_key = PokemonSurvivor.species_key(enemy.name)
    primary_type = tower_final_boss_primary_type(final_key)
    primary_vfx = tower_final_boss_primary_vfx(final_key)
    data = tower_boss_pattern_timer(enemy, :ray_fan, 0.55)
    data[:ray_fan] = data[:ray_fan].to_f - dt.to_f
    if data[:ray_fan] <= 0
      data[:ray_fan] = 1.05
      tower_spawn_fan(enemy, 7, Math::PI / 3.0, primary_type, primary_vfx, 0.88, 1.18)
    end
    data[:ray_lance] = data.fetch(:ray_lance, 1.6).to_f - dt.to_f
    if data[:ray_lance] <= 0
      data[:ray_lance] = 2.05
      tower_spawn_fan(enemy, 5, Math::PI / 7.0, :DRAGON, "VFX_DRAGON", 1.08, 1.34)
    end
    data[:ray_spiral] = data.fetch(:ray_spiral, 2.8).to_f - dt.to_f
    if data[:ray_spiral] <= 0
      data[:ray_spiral] = 3.35
      tower_spawn_spiral(enemy, 22, :DRAGON, "VFX_DRAGON", 0.74, 1.20)
    end
    data[:ray_storm] = data.fetch(:ray_storm, 5.2).to_f - dt.to_f
    if data[:ray_storm] <= 0
      data[:ray_storm] = 5.8
      spawn_rayquaza_double_ring(enemy)
    end
  rescue
  end
  def tower_angle_to_hero(enemy)
    Math.atan2(@hero.y - enemy.y, @hero.x - enemy.x)
  rescue
    rand * Math::PI * 2.0
  end

  def tower_spawn_fan(enemy, count, spread, type, vfx = nil, damage_mult = 1.0, speed_mult = 1.0)
    count = [count.to_i, 1].max
    base = tower_angle_to_hero(enemy)
    start = base - (spread.to_f / 2.0)
    step = count <= 1 ? 0.0 : spread.to_f / (count - 1).to_f
    count.times do |i|
      break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
      tower_spawn_enemy_projectile(enemy, start + (step * i), type, vfx, damage_mult, speed_mult, 3.2)
    end
  rescue
  end

  def tower_spawn_ring(enemy, count, type, vfx = nil, damage_mult = 1.0, speed_mult = 1.0, offset = 0.0)
    count = [count.to_i, 1].max
    step = Math::PI * 2.0 / count.to_f
    base = ((System.uptime rescue 0.0).to_f * offset.to_f) % step
    count.times do |i|
      break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
      tower_spawn_enemy_projectile(enemy, base + (step * i), type, vfx, damage_mult, speed_mult, 3.8)
    end
  rescue
  end

  def tower_spawn_spiral(enemy, count, type, vfx = nil, damage_mult = 1.0, speed_mult = 1.0)
    count = [count.to_i, 1].max
    base = ((System.uptime rescue 0.0).to_f * 2.35) % (Math::PI * 2.0)
    step = Math::PI * 2.0 / count.to_f
    count.times do |i|
      break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
      tower_spawn_enemy_projectile(enemy, base + (step * i), type, vfx, damage_mult, speed_mult, 4.2)
    end
  rescue
  end

  def tower_spawn_enemy_projectile(enemy, angle, type, vfx = nil, damage_mult = 1.0, speed_mult = 1.0, ttl = 3.4)
    old_type = enemy.attack_type
    old_damage = @tower_projectile_damage_mult
    old_speed = @tower_projectile_speed_mult
    old_vfx = @tower_projectile_vfx_override
    old_ttl = @tower_projectile_ttl
    enemy.attack_type = type || old_type
    @tower_projectile_damage_mult = damage_mult.to_f
    @tower_projectile_speed_mult = speed_mult.to_f
    @tower_projectile_vfx_override = vfx
    @tower_projectile_ttl = ttl.to_f
    spawn_enemy_projectile(enemy, Math.cos(angle), Math.sin(angle))
  rescue
  ensure
    enemy.attack_type = old_type if enemy
    @tower_projectile_damage_mult = old_damage
    @tower_projectile_speed_mult = old_speed
    @tower_projectile_vfx_override = old_vfx
    @tower_projectile_ttl = old_ttl
  end

  def boss_ring_interval(enemy)
    return 3.2 if tower_mode? && enemy && PokemonSurvivor.tower_final_boss?(enemy.name)
    return 12.0 if tower_mode?
    30.0
  rescue
    30.0
  end

  def update_rush_boss_ring_attack(enemy, dt)
    @rush_boss_ring_timers ||= {}
    key = enemy.object_id
    interval = boss_ring_interval(enemy)
    @rush_boss_ring_timers[key] = interval if !@rush_boss_ring_timers.key?(key)
    @rush_boss_ring_timers[key] = @rush_boss_ring_timers[key].to_f - dt.to_f
    return if @rush_boss_ring_timers[key] > 0
    @rush_boss_ring_timers[key] = interval
    spawn_rush_boss_ring_projectiles(enemy)
  rescue
  end

  def spawn_rayquaza_double_ring(enemy)
    final_key = PokemonSurvivor.species_key(enemy.name)
    primary_type = tower_final_boss_primary_type(final_key)
    primary_vfx = tower_final_boss_primary_vfx(final_key)
    tower_spawn_ring(enemy, 32, :DRAGON, "VFX_DRAGON", 1.00, 1.10, 0.28)
    tower_spawn_ring(enemy, 24, primary_type, primary_vfx, 0.82, 0.82, 0.42)
    tower_spawn_fan(enemy, 9, Math::PI / 2.4, :DRAGON, "VFX_DRAGON", 1.10, 1.18)
  rescue
  end
  def spawn_rush_boss_ring_projectiles(enemy)
    return spawn_rayquaza_double_ring(enemy) if tower_rayquaza_enemy?(enemy)
    count = tower_mode? && enemy && PokemonSurvivor.tower_final_boss?(enemy.name) ? 28 : 20
    step = Math::PI * 2.0 / count.to_f
    offset = (System.uptime rescue 0.0).to_f % step
    @enemy_ring_projectile_cast = true
    count.times do |i|
      break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
      angle = offset + (step * i)
      spawn_enemy_projectile(enemy, Math.cos(angle), Math.sin(angle))
    end
  rescue
  ensure
    @enemy_ring_projectile_cast = false
  end

  def rush_boss_shot_cooldown
    return tower_boss_shot_cooldown if tower_mode?
    wave = [[@rush_wave_index.to_i, 0].max, PokemonSurvivor::RUSH_BOSS_SHOT_COOLDOWNS.length - 1].min
    base = PokemonSurvivor::RUSH_BOSS_SHOT_COOLDOWNS[wave].to_f
    [base - (@level.to_i * 0.002), 0.48].max
  rescue
    0.9
  end

  def spawn_enemy_projectile(enemy, vx, vy)
    p = PokemonSurvivorEntity.new(:enemy_projectile, enemy.name, enemy.x, enemy.y)
    p.owner = :enemy
    damage_mult = @tower_projectile_damage_mult || 1.0
    p.damage = [(enemy.damage * (rush_style_boss_projectile?(enemy) ? 0.34 : 0.42) * damage_mult).round, 1].max
    p.attack_type = enemy.attack_type || :NORMAL
    if enemy.kind == :wild
      p.attack_type = PokemonSurvivor::ENEMY_WILD_PROJECTILE_TYPES.fetch(PokemonSurvivor.species_key(enemy.name), p.attack_type)
    end
    speed_mult = @tower_projectile_speed_mult || 1.0
    p.speed = (rush_style_boss_projectile?(enemy) ? (tower_mode? ? 4.4 : (3.8 + [@rush_wave_index.to_i * 0.35, 1.2].min)) : (3.2 + [@timer.to_i / 520.0, 1.1].min)) * speed_mult
    p.pierce = 1
    p.radius = PokemonSurvivor::PROJECTILE_RADIUS
    p.vx = vx
    p.vy = vy
    p.color = enemy_projectile_color(enemy)
    p.vfx_name = tower_rayquaza_projectile_vfx(enemy, p.attack_type) || PokemonSurvivor::ENEMY_PROJECTILE_VFX[p.attack_type] || vfx_name_for_type(p.attack_type)
    p.vfx_name = PokemonSurvivor::ENEMY_PROJECTILE_VFX_REPLACEMENTS.fetch(p.vfx_name, p.vfx_name)
    p.ttl = @tower_projectile_ttl || 3.4
    @projectiles << p
  end


end





























































