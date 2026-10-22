#===============================================================================
# Pokemon Survivor - Tower objective variants
#===============================================================================

# Keep the objective's keyed rendering API while providing a full combat target.
class PokemonSurvivorSeal < PokemonSurvivorEntity
  attr_accessor :shot_timer

  def [](key)
    public_send(key)
  end

  def []=(key, value)
    public_send("#{key}=", value)
  end
end

class Scene_PokemonSurvivor
  TOWER_PRESSURE_SECONDS = 24.0 unless const_defined?(:TOWER_PRESSURE_SECONDS)
  TOWER_HOLD_SECONDS = 13.0 unless const_defined?(:TOWER_HOLD_SECONDS)
  TOWER_ZONE_RADIUS = 86 unless const_defined?(:TOWER_ZONE_RADIUS)
  TOWER_WISP_RADIUS = 24 unless const_defined?(:TOWER_WISP_RADIUS)

  unless method_defined?(:shift_world_entities_without_tower_objectives)
    alias_method :shift_world_entities_without_tower_objectives, :shift_world_entities
  end

  def shift_world_entities(dx, dy)
    shift_world_entities_without_tower_objectives(dx, dy)
    (@tower_wisps || []).each do |wisp|
      wisp[:x] = wisp[:x].to_f + dx.to_f
      wisp[:y] = wisp[:y].to_f + dy.to_f
    end
    if @tower_zone
      @tower_zone[:x] = @tower_zone[:x].to_f + dx.to_f
      @tower_zone[:y] = @tower_zone[:y].to_f + dy.to_f
    end
  rescue
  end

  unless method_defined?(:cleanup_tower_floor_before_next_start_without_tower_objectives)
    alias_method :cleanup_tower_floor_before_next_start_without_tower_objectives, :cleanup_tower_floor_before_next_start
  end

  def cleanup_tower_floor_before_next_start
    cleanup_tower_floor_before_next_start_without_tower_objectives
    clear_tower_objective_state
  rescue
  end


  unless method_defined?(:defeat_enemy_without_tower_objectives)
    alias_method :defeat_enemy_without_tower_objectives, :defeat_enemy
  end

  unless method_defined?(:cleanup_active_entities_without_tower_objectives)
    alias_method :cleanup_active_entities_without_tower_objectives, :cleanup_active_entities
  end

  def cleanup_active_entities
    return cleanup_active_entities_without_tower_objectives if !tower_mode? || @tower_objective_type != :elite_pair
    margin = PokemonSurvivor::ENEMY_CULL_MARGIN
    prune_doom_enemies if respond_to?(:prune_doom_enemies)
    @enemies.delete_if do |enemy|
      next true if !enemy
      next false if enemy.instance_variable_get(:@tower_objective_elite)
      next false if enemy.kind == :boss || enemy.kind == :chest || enemy.kind == :ultra_boss || enemy.kind == :ultra_chest
      enemy.hp.to_i <= 0 || !point_on_screen?(enemy.x, enemy.y, margin)
    end
    trim_projectiles_to_limit if respond_to?(:trim_projectiles_to_limit)
    @effects.shift(@effects.length - PokemonSurvivor::MAX_EFFECTS) if @effects && @effects.length > PokemonSurvivor::MAX_EFFECTS
    compact_xp_gems if @xp_gems && respond_to?(:compact_xp_gems) && @xp_gems.length > xp_gem_limit
  rescue
    cleanup_active_entities_without_tower_objectives rescue nil
  end
  def defeat_enemy(enemy)
    already_defeated = enemy && enemy.instance_variable_get(:@defeated)
    defeat_enemy_without_tower_objectives(enemy)
    record_tower_objective_enemy_defeat(enemy) if tower_mode? && enemy && !already_defeated
  rescue
    defeat_enemy_without_tower_objectives(enemy) rescue nil
  end

  unless method_defined?(:closest_visible_enemies_from_without_tower_wisps)
    alias_method :closest_visible_enemies_from_without_tower_wisps, :closest_visible_enemies_from
  end

  def closest_visible_enemies_from(x, y, radius, count, excluded = nil)
    limit = [count.to_i, 1].max
    wisps = tower_wisp_targets_for(x, y, radius).reject { |wisp| wisp.equal?(excluded) }
    wisps.sort_by! { |wisp| point_distance_sq(x, y, wisp[:x], wisp[:y]) }
    return wisps.first(limit) if !wisps.empty? && @tower_objective_type == :break_seal
    best = closest_visible_enemies_from_without_tower_wisps(x, y, radius, limit, excluded)
    wisps.each do |wisp|
      next if best.include?(wisp)
      dist = point_distance_sq(x, y, wisp[:x], wisp[:y])
      insert_at = best.length
      best.each_with_index do |enemy, i|
        enemy_dist = point_distance_sq(x, y, enemy.x, enemy.y) rescue 99_999_999
        if dist < enemy_dist
          insert_at = i
          break
        end
      end
      best.insert(insert_at, wisp)
      best.pop while best.length > limit
    end
    best
  rescue
    closest_visible_enemies_from_without_tower_wisps(x, y, radius, count, excluded) rescue []
  end

  unless method_defined?(:nearest_visible_enemy_from_without_tower_wisps)
    alias_method :nearest_visible_enemy_from_without_tower_wisps, :nearest_visible_enemy_from
  end

  def nearest_visible_enemy_from(x, y)
    wisps = tower_wisp_targets_for(x, y, 9999)
    if !wisps.empty? && @tower_objective_type == :break_seal
      return wisps.min_by { |wisp| point_distance_sq(x, y, wisp[:x], wisp[:y]) }
    end
    best = nearest_visible_enemy_from_without_tower_wisps(x, y)
    best_dist = best ? point_distance_sq(x, y, best.x, best.y) : nil
    wisps.each do |wisp|
      dist = point_distance_sq(x, y, wisp[:x], wisp[:y])
      if !best_dist || dist < best_dist
        best = wisp
        best_dist = dist
      end
    end
    best
  rescue
    nearest_visible_enemy_from_without_tower_wisps(x, y) rescue nil
  end

  def tower_wisp_targets_for(x, y, radius)
    return [] if !tower_mode? || !@tower_wisps || @tower_wisps.empty?
    radius_sq = radius.to_f * radius.to_f
    (@tower_wisps || []).select do |wisp|
      next false if !wisp || wisp[:hp].to_i <= 0
      next false if !point_on_screen?(wisp[:x], wisp[:y], 64)
      point_distance_sq(x, y, wisp[:x], wisp[:y]) <= radius_sq
    end
  rescue
    []
  end
  def tower_egg_floor?
    [15, 25, 35].include?(@tower_floor.to_i)
  rescue
    false
  end

  def tower_floor_required_kos
    [[8 + (@tower_floor.to_i / 3), 8].max, 30].min
  rescue
    10
  end

  def tower_special_objective_type
    floor = @tower_floor.to_i
    return nil if floor <= 1
    return nil if floor >= PokemonSurvivor::TOWER_MAX_FLOOR
    return nil if tower_egg_floor? || tower_floor_boss_floor?
    case floor % 9
    when 2 then :pressure
    when 3 then :zone_kills
    when 4 then :hold_zone
    when 5 then :break_seal
    when 6 then :elite_pair
    when 7 then floor >= 12 ? :boss_ambush : :pressure
    else nil
    end
  rescue
    nil
  end

  def clear_tower_objective_state
    invalidate_enemy_grid
    @tower_objective_type = nil
    @tower_objective_timer = 0.0
    @tower_objective_count = 0
    @tower_objective_target = 0
    @tower_zone = nil
    @tower_wisps = []
  rescue
  end

  def setup_tower_objective_state
    @tower_objective_type = tower_special_objective_type
    @tower_objective_timer = 0.0
    @tower_objective_count = 0
    @tower_objective_target = 0
    @tower_zone = nil
    @tower_wisps = []
  rescue
  end

  def start_tower_floor
    update_tower_floor_bgm
    update_tower_floor_background
    @tower_floor_started = true
    @tower_floor_kills_start = @kills.to_i
    @tower_boss_defeated = false
    @tower_egg_hatched_this_floor = false
    setup_tower_objective_state
    boss_style = tower_floor_boss_floor? || @tower_floor.to_i >= PokemonSurvivor::TOWER_MAX_FLOOR || @tower_objective_type == :boss_ambush
    apply_tower_boss_preparation if boss_style
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
    else
      start_tower_special_objective
    end
  rescue
  end

  def start_tower_special_objective
    case @tower_objective_type
    when :pressure
      @tower_objective_target = TOWER_PRESSURE_SECONDS + [@tower_floor.to_i * 0.24, 8.0].min
    when :zone_kills
      @tower_objective_target = [[6 + (@tower_floor.to_i / 4), 6].max, 16].min
      spawn_tower_objective_zone
    when :hold_zone
      @tower_objective_target = TOWER_HOLD_SECONDS + [@tower_floor.to_i * 0.13, 6.0].min
      spawn_tower_objective_zone
    when :break_seal
      @tower_objective_target = [[4 + (@tower_floor.to_i / 14), 4].max, 7].min
      spawn_tower_wisps(@tower_objective_target)
    when :elite_pair
      @tower_objective_target = 2
      spawn_tower_elite_pair
    when :boss_ambush
      @tower_objective_target = 1
      before = @enemies.length
      spawn_enemy(:boss)
      enemy = @enemies.last if @enemies.length > before
      place_tower_objective_enemy_far(enemy) if enemy
    end
  rescue
  end

  def tower_objective_spawn_point(distance = 290, margin = 58)
    return [Graphics.width / 2, Graphics.height / 2] if !@hero
    18.times do
      angle = rand * Math::PI * 2.0
      spread = 0.82 + (rand * 0.36)
      x = @hero.x + Math.cos(angle) * distance.to_f * spread
      y = @hero.y + Math.sin(angle) * distance.to_f * spread
      if respond_to?(:clamp_world_spawn_position)
        x, y = clamp_world_spawn_position(x, y, margin)
      else
        x = [[x, -260 + margin.to_f].max, Graphics.width + 260 - margin.to_f].min
        y = [[y, -220 + margin.to_f].max, Graphics.height + 220 - margin.to_f].min
      end
      return [x, y]
    end
    if respond_to?(:clamp_world_spawn_position)
      clamp_world_spawn_position(@hero.x, @hero.y, margin)
    else
      [@hero.x, @hero.y]
    end
  rescue
    [Graphics.width / 2, Graphics.height / 2]
  end

  def spawn_tower_objective_zone
    radius = @tower_objective_type == :zone_kills ? TOWER_ZONE_RADIUS * 2 : TOWER_ZONE_RADIUS
    x, y = tower_objective_spawn_point(285, radius.to_i + 42)
    @tower_zone = { x: x, y: y, radius: radius }
  rescue
  end

  def tower_wisp_target_hash(x, y, hp, shot_cd)
    wisp = PokemonSurvivorSeal.new(:tower_wisp, "WILL_O_WISP", x, y)
    wisp.hp = wisp.max_hp = hp
    wisp.radius = TOWER_WISP_RADIUS
    wisp.shot_timer = shot_cd
    wisp
  end
  def spawn_tower_wisps(count)
    invalidate_enemy_grid
    @tower_wisps = []
    count.to_i.times do |i|
      angle = (Math::PI * 2.0 * i / [count.to_i, 1].max) + (rand * 0.45)
      distance = 250 + (i % 3) * 72 + rand(64)
      x = @hero.x + Math.cos(angle) * distance
      y = @hero.y + Math.sin(angle) * distance
      if respond_to?(:clamp_world_spawn_position)
        x, y = clamp_world_spawn_position(x, y, TOWER_WISP_RADIUS + 54)
      else
        x, y = tower_objective_spawn_point(distance, TOWER_WISP_RADIUS + 54)
      end
      hp = [540 + (@tower_floor.to_i * 54) + (@level.to_i * 15), 720].max
      shot_cd = 2.45 + (i * 0.28)
      @tower_wisps << tower_wisp_target_hash(x, y, hp, shot_cd)
    end
  rescue
    @tower_wisps = []
  end

  def place_tower_objective_enemy_far(enemy)
    return if !enemy
    x, y = tower_objective_spawn_point(330 + rand(90), 78)
    enemy.x = x
    enemy.y = y
    invalidate_enemy_grid if respond_to?(:invalidate_enemy_grid)
  rescue
  end
  def spawn_tower_elite_pair
    @tower_elite_pair_spawned = 0
    2.times do
      before = @enemies.length
      spawn_enemy(:wild)
      enemy = @enemies.last if @enemies.length > before
      next if !enemy
      enemy.instance_variable_set(:@tower_objective_elite, true)
      place_tower_objective_enemy_far(enemy)
      enemy.max_hp = [(enemy.max_hp.to_i * 10.0).round, enemy.max_hp.to_i + 540].max
      enemy.hp = enemy.max_hp
      enemy.damage = [(enemy.damage.to_i * 1.42).round, enemy.damage.to_i + 1].max
      enemy.value = [(enemy.value.to_i * 2.35).round, enemy.value.to_i + 16].max
      enemy.radius = (enemy.radius.to_i + 3) if enemy.respond_to?(:radius=)
      @tower_elite_pair_spawned = @tower_elite_pair_spawned.to_i + 1
    end
    @tower_objective_target = [[@tower_elite_pair_spawned.to_i, 1].max, 2].min
  rescue
  end

  def sync_tower_elite_pair_objective
    return if @tower_objective_type != :elite_pair
    spawned = [@tower_elite_pair_spawned.to_i, @tower_objective_target.to_i, 1].max
    alive = (@enemies || []).count { |enemy| enemy && enemy.instance_variable_get(:@tower_objective_elite) && enemy.hp.to_i > 0 }
    defeated = [[spawned - alive, 0].max, @tower_objective_target.to_i].min
    @tower_objective_count = [@tower_objective_count.to_i, defeated].max
  rescue
  end

  def update_tower_mode(dt)
    return if @tower_complete
    return if @pending_upgrade || @state == :upgrade
    start_tower_floor if !@tower_floor_started
    update_tower_special_objective(dt)
    finish_tower_floor if tower_floor_complete?
  rescue
  end

  def update_tower_special_objective(dt)
    case @tower_objective_type
    when :pressure
      @tower_objective_timer = @tower_objective_timer.to_f + dt.to_f
    when :hold_zone
      @tower_objective_timer = @tower_objective_timer.to_f + dt.to_f if hero_inside_tower_zone?
    when :elite_pair
      sync_tower_elite_pair_objective
    when :break_seal
      update_tower_wisp_attacks(dt)
      @tower_objective_count = @tower_objective_target.to_i - (@tower_wisps || []).length
    end
  rescue
  end

  def hero_inside_tower_zone?
    return false if !@tower_zone || !@hero
    dx = @hero.x.to_f - @tower_zone[:x].to_f
    dy = @hero.y.to_f - @tower_zone[:y].to_f
    (dx * dx + dy * dy) <= (@tower_zone[:radius].to_f * @tower_zone[:radius].to_f)
  rescue
    false
  end

  def tower_special_objective_complete?
    case @tower_objective_type
    when :pressure, :hold_zone
      @tower_objective_timer.to_f >= @tower_objective_target.to_f
    when :zone_kills, :elite_pair, :boss_ambush, :break_seal
      @tower_objective_count.to_i >= @tower_objective_target.to_i
    else
      false
    end
  rescue
    false
  end

  def tower_floor_complete?
    return false if !@tower_floor_started
    if @tower_floor.to_i >= PokemonSurvivor::TOWER_MAX_FLOOR
      return @tower_complete
    elsif tower_egg_floor?
      return @tower_egg_hatched_this_floor && !@event_egg
    elsif tower_floor_boss_floor?
      return @tower_boss_defeated && !tower_boss_alive?
    elsif @tower_objective_type
      return tower_special_objective_complete?
    end
    (@kills.to_i - @tower_floor_kills_start.to_i) >= tower_floor_required_kos
  rescue
    false
  end

  def record_tower_objective_enemy_defeat(enemy)
    return if !enemy || !@tower_objective_type
    case @tower_objective_type
    when :zone_kills
      return if !@tower_zone
      dx = enemy.x.to_f - @tower_zone[:x].to_f
      dy = enemy.y.to_f - @tower_zone[:y].to_f
      @tower_objective_count = @tower_objective_count.to_i + 1 if (dx * dx + dy * dy) <= (@tower_zone[:radius].to_f * @tower_zone[:radius].to_f)
    when :elite_pair
      @tower_objective_count = @tower_objective_count.to_i + 1 if enemy.instance_variable_get(:@tower_objective_elite)
    when :boss_ambush
      @tower_objective_count = 1 if enemy.kind == :boss || enemy.kind == :ultra_boss
    end
  rescue
  end

  def update_tower_wisp_attacks(dt)
    return if !@tower_wisps || @tower_wisps.empty? || !@projectiles || !@hero
    @tower_wisps.each_with_index do |wisp, index|
      wisp[:shot_timer] = wisp[:shot_timer].to_f - dt.to_f
      next if wisp[:shot_timer].to_f > 0.0
      wisp[:shot_timer] = 3.15 + (index * 0.22) + rand * 0.35
      spawn_tower_wisp_ring(wisp)
    end
  rescue
  end

  def spawn_tower_wisp_ring(wisp)
    return if !wisp || !@projectiles
    count = 8
    count = 6 if PokemonSurvivor.performance_option?(:reduced_vfx)
    step = Math::PI * 2.0 / count.to_f
    offset = ((@timer || 0.0).to_f % step) + rand * 0.18
    count.times do |i|
      break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
      angle = offset + (step * i)
      p = PokemonSurvivorEntity.new(:enemy_projectile, "WILL_O_WISP", wisp[:x], wisp[:y])
      p.owner = :enemy
      p.damage = tower_wisp_projectile_damage
      p.attack_type = :GHOST
      p.speed = 3.15
      p.pierce = 1
      p.radius = PokemonSurvivor::PROJECTILE_RADIUS
      p.vx = Math.cos(angle)
      p.vy = Math.sin(angle)
      p.color = Color.new(184, 126, 255)
      p.vfx_name = "VFX_GHOST"
      p.ttl = 3.1
      @projectiles << p
    end
  rescue
  end

  def tower_wisp_projectile_damage
    base = 4 + (@tower_floor.to_i / 8) + (@level.to_i / 38)
    [[base, 4].max, 18].min
  rescue
    6
  end


  def cleanup_destroyed_tower_wisps
    return if !@tower_wisps
    before = @tower_wisps.length
    @tower_wisps.delete_if { |wisp| wisp[:hp].to_i <= 0 }
    broken = before - @tower_wisps.length
    @tower_objective_count = @tower_objective_count.to_i + broken if broken > 0
  rescue
  end

  def spawn_tower_wave
    return @spawn_timer = 0.20 if spawn_queue_pending?
    return @spawn_timer = 0.5 if @pending_upgrade || @state == :upgrade
    return @spawn_timer = 0.5 if @tower_floor.to_i >= PokemonSurvivor::TOWER_MAX_FLOOR && tower_boss_alive?
    cleanup_active_entities
    active_wild = @enemies.count { |e| e.kind == :wild } rescue 0
    cap = [[8 + (@tower_floor.to_i / 8), 8].max, 20].min
    cap += 6 if @tower_objective_type == :pressure
    cap = 10 if @tower_objective_type == :boss_ambush
    cap = 8 if tower_floor_boss_floor?
    return @spawn_timer = 0.55 if active_wild >= cap
    count = [[2 + (@tower_floor.to_i / 12), 2].max, 6].min
    count += 2 if @tower_objective_type == :pressure
    count = [count, cap - active_wild].min
    enqueue_enemy_spawns(:wild, count) if count > 0
    base = @tower_objective_type == :pressure ? 0.72 : 1.05
    floor_pressure = @tower_floor.to_i * 0.004
    @spawn_timer = [[base - floor_pressure - (@level.to_i * 0.001), 0.38].max, 1.1].min
  rescue
    @spawn_timer = 0.8
  end

  def tower_objective_text
    if @tower_floor.to_i >= PokemonSurvivor::TOWER_MAX_FLOOR
      boss = (@tower_final_boss_name || PokemonSurvivor::TOWER_FINAL_BOSS).to_s
      return _INTL("Defeat: {1}", boss)
    elsif tower_egg_floor?
      done = @tower_egg_hatched_this_floor ? 1 : 0
      return _INTL("Hatch Egg: {1}/1", done)
    elsif tower_floor_boss_floor?
      return _INTL("Defeat Boss")
    end
    case @tower_objective_type
    when :pressure
      done = [[@tower_objective_timer.to_f.ceil, 0].max, @tower_objective_target.to_i].min
      return _INTL("Survive: {1}/{2}s", done, @tower_objective_target.to_i)
    when :zone_kills
      return _INTL("Zone KOs: {1}/{2}", @tower_objective_count.to_i, @tower_objective_target.to_i)
    when :hold_zone
      done = [[@tower_objective_timer.to_f.ceil, 0].max, @tower_objective_target.to_i].min
      return _INTL("Hold Zone: {1}/{2}s", done, @tower_objective_target.to_i)
    when :break_seal
      return _INTL("Break Seal: {1}/{2}", @tower_objective_count.to_i, @tower_objective_target.to_i)
    when :elite_pair
      return _INTL("Elites: {1}/{2}", @tower_objective_count.to_i, @tower_objective_target.to_i)
    when :boss_ambush
      return _INTL("Boss Ambush")
    end
    needed = tower_floor_required_kos
    done = [[@kills.to_i - @tower_floor_kills_start.to_i, 0].max, needed].min
    _INTL("KOs: {1}/{2}", done, needed)
  rescue
    _INTL("Climb")
  end

  def draw_tower_objective_world_markers(bitmap)
    draw_tower_objective_zone(bitmap) if @tower_zone
    draw_tower_wisps(bitmap) if @tower_wisps && !@tower_wisps.empty?
    draw_tower_objective_edge_indicators(bitmap)
  rescue
  end

  def draw_tower_objective_edge_indicators(bitmap)
    frame = (((@timer || 0.0) * 12.0).floor)
    limit = PokemonSurvivor.performance_option?(:reduced_vfx) ? 3 : 6
    drawn = 0
    if @tower_zone && [:zone_kills, :hold_zone].include?(@tower_objective_type)
      if !point_on_screen?(@tower_zone[:x], @tower_zone[:y], @tower_zone[:radius].to_i)
        pos = tower_objective_edge_indicator_position(@tower_zone[:x], @tower_zone[:y])
        if pos
          draw_vfx_frame(bitmap, "VFX_EXCLAIM", pos[0], pos[1], 1.0, pos[2], nil, frame)
          drawn += 1
        end
      end
    end
    (@tower_wisps || []).each do |wisp|
      break if drawn >= limit
      next if point_on_screen?(wisp[:x], wisp[:y], 44)
      pos = tower_objective_edge_indicator_position(wisp[:x], wisp[:y])
      next if !pos
      draw_vfx_frame(bitmap, "VFX_EXCLAIM", pos[0], pos[1], 1.0, pos[2], nil, frame)
      drawn += 1
    end
  rescue
  end

  def tower_objective_edge_indicator_position(x, y)
    w = @screen_w || Graphics.width
    h = @screen_h || Graphics.height
    center_x = w * 0.5
    center_y = h * 0.5
    sx = respond_to?(:world_screen_x) ? world_screen_x(x) : x.to_f
    sy = respond_to?(:world_screen_y) ? world_screen_y(y) : y.to_f
    dx = sx.to_f - center_x
    dy = sy.to_f - center_y
    dx = 0.01 if dx.abs < 0.01
    dy = 0.01 if dy.abs < 0.01
    inset_x = 24.0
    inset_top = 72.0
    inset_bottom = 28.0
    max_x = center_x - inset_x
    max_y = dy < 0 ? center_y - inset_top : center_y - inset_bottom
    scale = [max_x / dx.abs, max_y / dy.abs].min
    pos_x = [[center_x + (dx * scale), inset_x].max, w - inset_x].min
    pos_y = [[center_y + (dy * scale), inset_top].max, h - inset_bottom].min
    distance_ratio = [[((dx * dx + dy * dy) ** 0.5) / 420.0, 0.0].max, 1.0].min
    [pos_x, pos_y, 190 + (distance_ratio * 55).round]
  rescue
    nil
  end
  def draw_tower_objective_zone(bitmap)
    return if !@tower_zone
    gameplay_radius = @tower_zone[:radius].to_i
    draw_radius = [(gameplay_radius * run_view_zoom).round, 12].max
    inside = hero_inside_tower_zone?
    zone = if respond_to?(:cached_event_sleep_wake_zone)
             cached_event_sleep_wake_zone(draw_radius, inside)
           else
             cached_tower_objective_zone(draw_radius, inside)
           end
    return if !zone || zone.disposed?
    x = (world_screen_x(@tower_zone[:x]) - draw_radius).round
    y = (world_screen_y(@tower_zone[:y]) - draw_radius).round
    bitmap.blt(x, y, zone, Rect.new(0, 0, zone.width, zone.height), 245)
  rescue
  end

  def cached_tower_objective_zone(radius, active = false)
    @tower_objective_zone_cache ||= {}
    key = [radius.to_i, active ? 1 : 0, PokemonSurvivor.color_accessibility_mode]
    cached = @tower_objective_zone_cache[key]
    return cached if cached && !cached.disposed?
    size = [radius.to_i * 2, 1].max
    bmp = Bitmap.new(size, size)
    center = (size - 1) / 2.0
    radius_f = radius.to_f
    inner = radius_f - 2.0
    ring = active ? Color.new(122, 255, 176, 205) : Color.new(184, 126, 255, 165)
    glow = active ? Color.new(122, 255, 176, 42) : Color.new(184, 126, 255, 30)
    core = active ? Color.new(255, 230, 104, 36) : Color.new(112, 214, 255, 22)
    accessible = PokemonSurvivor.color_accessibility_enabled?
    ring = PokemonSurvivor.accessible_color(ring)
    glow = PokemonSurvivor.accessible_color(glow)
    core = PokemonSurvivor.accessible_color(core)
    marker = Color.new(255, 255, 255, 180)
    0.upto(size - 1) do |yy|
      0.upto(size - 1) do |xx|
        dx = xx - center
        dy = yy - center
        dist = Math.sqrt((dx * dx) + (dy * dy))
        next if dist > radius_f
        if accessible && active && dist >= radius_f - 6.0 && dist < radius_f - 5.0
          bmp.set_pixel(xx, yy, marker)
          next
        end
        if dist >= inner
          next if accessible && !active && ((Math.atan2(dy, dx) * 12 / Math::PI).floor % 2 == 0)
          bmp.set_pixel(xx, yy, ring)
        elsif dist >= radius_f - 8.0
          bmp.set_pixel(xx, yy, glow)
        elsif ((xx + yy) % 9) == 0
          bmp.set_pixel(xx, yy, core)
        end
      end
    end
    @tower_objective_zone_cache[key] = bmp
    bmp
  rescue
    nil
  end

  def draw_tower_wisps(bitmap)
    frame = ((@timer.to_f * 12).floor % 8)
    @tower_wisps.each do |wisp|
      next if !point_on_screen?(wisp[:x], wisp[:y], 70)
      sx = world_screen_x(wisp[:x]).round
      sy = world_screen_y(wisp[:y]).round
      draw_vfx_frame(bitmap, "VFX_WILLOWISP", sx, sy, world_screen_zoom(1.0), 245, nil, frame)
      max_hp = [wisp[:max_hp].to_i, 1].max
      rate = [[wisp[:hp].to_f / max_hp.to_f, 0.0].max, 1.0].min
      z = run_view_zoom
      bar_w = [(42 * z).round, 12].max
      bar_h = [(6 * z).round, 4].max
      bar_x = sx - (bar_w / 2)
      bar_y = sy + [28 * z, 22].max.round
      if respond_to?(:draw_enemy_status_bar)
        draw_enemy_status_bar(bitmap, bar_x, bar_y, bar_w, bar_h, rate, enemy_hp_bar_color(rate))
      else
        bitmap.fill_rect(bar_x, bar_y, bar_w, bar_h, Color.new(3, 6, 13, 210))
        bitmap.fill_rect(bar_x + 2, bar_y + 2, ((bar_w - 4) * rate).round, bar_h - 4, Color.new(92, 255, 132))
      end
    end
  rescue
  end
end










# Right-aligned Tower objective HUD text.
class Scene_PokemonSurvivor
  def draw_tower_objective_badge(bitmap)
    label = tower_objective_text
    box_w = 214
    x = Graphics.width - box_w - 12
    y = 44
    draw_soft_badge(bitmap, x, y, box_w, 20, Color.new(0, 0, 0, 142))
    draw_text_box(bitmap, label, x + 8, y, box_w - 16, 20, Color.new(220, 244, 230), Color.new(34, 42, 48), 2)
  rescue
  end
end









