#===============================================================================
# Pokemon Survivor - Runtime performance optimizations
#===============================================================================

module PokemonSurvivor
  PERFORMANCE_CLOSE_TARGET_POOL_MULT = 3 unless const_defined?(:PERFORMANCE_CLOSE_TARGET_POOL_MULT)
end

class Scene_PokemonSurvivor
  alias draw_game_without_survivor_perf_cache draw_game unless method_defined?(:draw_game_without_survivor_perf_cache)
  def draw_game(apply_tv_filter = true)
    prepare_survivor_frame_cache
    draw_game_without_survivor_perf_cache(apply_tv_filter)
  ensure
    @survivor_point_screen_frame = nil
  end

  def prepare_survivor_frame_cache
    @screen_w = Graphics.width
    @screen_h = Graphics.height
    zoom = (respond_to?(:run_view_zoom) ? run_view_zoom : 1.0).to_f
    zoom = 1.0 if zoom <= 0.0
    cache = (@survivor_screen_cache ||= {})
    cache[:frame] = Graphics.frame_count
    cache[:width] = @screen_w
    cache[:height] = @screen_h
    cache[:zoom] = zoom
    cache[:center_x] = @screen_w / 2.0
    cache[:center_y] = @screen_h / 2.0
    cache[:min_x] = cache[:center_x] - cache[:center_x] / zoom
    cache[:max_x] = cache[:center_x] + cache[:center_x] / zoom
    cache[:min_y] = cache[:center_y] - cache[:center_y] / zoom
    cache[:max_y] = cache[:center_y] + cache[:center_y] / zoom
  rescue
    @survivor_screen_cache = nil
  end

  def survivor_screen_cache
    cache = @survivor_screen_cache
    return cache if cache && cache[:frame] == Graphics.frame_count
    prepare_survivor_frame_cache
    @survivor_screen_cache
  rescue
    nil
  end

  def point_on_screen?(x, y, margin = 0)
    cache = survivor_screen_cache
    w = cache ? cache[:width].to_f : Graphics.width.to_f
    h = cache ? cache[:height].to_f : Graphics.height.to_f
    z = cache ? cache[:zoom].to_f : 1.0
    m = margin.to_f
    xf = x.to_f
    yf = y.to_f
    if z < 0.999
      return xf >= cache[:min_x] - m && xf <= cache[:max_x] + m &&
             yf >= cache[:min_y] - m && yf <= cache[:max_y] + m
    end
    xf >= -m && xf <= w + m && yf >= -m && yf <= h + m
  rescue
    true
  end

  def survivor_insert_near_target(pool, limit, enemy, dist)
    return if limit <= 0 || (pool.length >= limit && dist >= pool[-1][0])
    insert_at = pool.length
    pool.each_with_index do |pair, i|
      if dist < pair[0]
        insert_at = i
        break
      end
    end
    pool.insert(insert_at, [dist, enemy])
    pool.pop while pool.length > limit
  rescue
  end

  def survivor_close_enemy_pool(x, y, radius, limit)
    limit = [[limit.to_i, 1].max, 32].min
    radius = [radius.to_f, 1.0].max
    pool = []
    range_sq = radius * radius
    if respond_to?(:each_nearby_enemy_for)
      each_nearby_enemy_for(x, y, radius) do |enemy|
        next if !enemy || enemy.hp.to_i <= 0
        dist = point_distance_sq(x, y, enemy.x, enemy.y)
        next if dist > range_sq
        survivor_insert_near_target(pool, limit, enemy, dist)
      end
    end
    if pool.empty?
      (@enemies || []).each do |enemy|
        next if !enemy || enemy.hp.to_i <= 0
        survivor_insert_near_target(pool, limit, enemy, point_distance_sq(x, y, enemy.x, enemy.y))
      end
    end
    pool.map { |pair| pair[1] }
  rescue
    []
  end

  def survivor_pick_targets_from_pool(pool, count)
    count = [count.to_i, 0].max
    ret = []
    while count > 0 && !pool.empty?
      ret << pool.delete_at(rand(pool.length))
      count -= 1
    end
    ret
  rescue
    []
  end

  if method_defined?(:fire_charmander_twister)
    alias fire_charmander_twister_without_survivor_perf fire_charmander_twister unless method_defined?(:fire_charmander_twister_without_survivor_perf)
    def fire_charmander_twister(skill, forced_count = nil)
      return if !@hero || !@enemies
      skill_id = skill_id_for(skill)
      global_bonus = @projectile_count_bonus.to_i
      skill_bonus = (@skill_count_bonus[skill_id].to_i rescue 0)
      count = forced_count || (skill[:count].to_i + global_bonus + skill_bonus)
      count += skill_bonus if @charizard_mega_active
      max_count = forced_count ? forced_count.to_i : (@charizard_mega_active ? 8 : (skill[:max_count] || 4).to_i)
      count = [[count, 1].max, projectile_count_cap(skill, max_count, count)].min
      range = (skill[:range] || 220).to_i
      pool_limit = [count * PokemonSurvivor::PERFORMANCE_CLOSE_TARGET_POOL_MULT, count].max
      targets = survivor_pick_targets_from_pool(survivor_close_enemy_pool(@hero.x, @hero.y, range, pool_limit), count)
      return if targets.empty?
      radius = skill[:radius].to_i
      duration = skill[:duration].to_f + @charmander_twister_duration_bonus.to_f
      targets.each { |enemy| spawn_charmander_twister_at(enemy.x, enemy.y, skill, radius, duration) }
    rescue
      fire_charmander_twister_without_survivor_perf(skill, forced_count) rescue nil
    end
  end

  if method_defined?(:update_projectiles)
    alias update_projectiles_without_survivor_perf update_projectiles unless method_defined?(:update_projectiles_without_survivor_perf)
    def update_projectiles(dt)
      @survivor_skip_bulk_wisp_projectile_hits = true
      update_projectiles_without_survivor_perf(dt)
    ensure
      @survivor_skip_bulk_wisp_projectile_hits = false
    end
  end

  if method_defined?(:update_tower_wisp_projectile_hits)
    alias update_tower_wisp_projectile_hits_without_survivor_perf update_tower_wisp_projectile_hits unless method_defined?(:update_tower_wisp_projectile_hits_without_survivor_perf)
    def update_tower_wisp_projectile_hits
      return if @survivor_skip_bulk_wisp_projectile_hits
      update_tower_wisp_projectile_hits_without_survivor_perf
    rescue
    end
  end

  if method_defined?(:event_hunt_enemies)
    def event_hunt_enemies
      ret = []
      (@enemies || []).each do |enemy|
        ret << enemy if enemy && enemy.kind == :event_hunt
      end
      ret
    rescue
      []
    end
  end

  def survivor_lite_enemy?(enemy)
    return false if !enemy || enemy.hp.to_i <= 0
    enemy.kind == :wild
  rescue
    false
  end

  def survivor_enemy_lod_interval(enemy)
    return 1 if !survivor_lite_enemy?(enemy)
    return 1 if !@hero
    return 1 if point_on_screen?(enemy.x, enemy.y, 112)
    dx = @hero.x.to_f - enemy.x.to_f
    dy = @hero.y.to_f - enemy.y.to_f
    dist_sq = (dx * dx) + (dy * dy)
    return 2 if dist_sq <= 520.0 * 520.0
    return 3 if dist_sq <= 760.0 * 760.0
    4
  rescue
    1
  end

  def survivor_lod_update_due?(enemy, interval)
    return true if interval.to_i <= 1
    frame = @survivor_enemy_sim_step.to_i
    phase = (enemy.object_id & 0x7fffffff) % interval.to_i
    (frame % interval.to_i) == phase
  rescue
    true
  end

  def survivor_enemy_step_dt(enemy, dt, interval)
    key = :@survivor_lod_accum_dt
    total = enemy.instance_variable_get(key).to_f + dt.to_f
    enemy.instance_variable_set(key, 0.0)
    total
  rescue
    dt.to_f
  end

  alias update_enemies_without_survivor_lod update_enemies unless method_defined?(:update_enemies_without_survivor_lod)
  def update_enemies(dt)
    return update_enemies_without_survivor_lod(dt) if !@enemies || !@hero
    # Accelerated runs can simulate several steps within one displayed frame.
    @survivor_enemy_sim_step = @survivor_enemy_sim_step.to_i + 1
    @enemies.each do |e|
      update_enemy_status(e, dt)
      next if e.hp <= 0
      interval = survivor_enemy_lod_interval(e)
      if interval > 1 && !survivor_lod_update_due?(e, interval)
        e.instance_variable_set(:@survivor_lod_accum_dt, e.instance_variable_get(:@survivor_lod_accum_dt).to_f + dt.to_f)
        next
      end
      step_dt = survivor_enemy_step_dt(e, dt, interval)
      dx = @hero.x - e.x
      dy = @hero.y - e.y
      len = Math.sqrt(dx * dx + dy * dy)
      next if len <= 0
      e.slow_timer = [e.slow_timer.to_f - step_dt, 0.0].max if e.slow_timer.to_f > 0
      e.freeze_timer = [e.freeze_timer.to_f - step_dt, 0.0].max if e.freeze_timer.to_f > 0
      e.moving = true
      e.direction = e.charset_directions.to_i >= PokemonSurvivor::CHARSET_8_DIRECTIONS ? direction_from_vector_8(dx, dy) : direction_from_vector(dx, dy)
      slow_mult = e.freeze_timer.to_f > 0 ? 0.0 : (e.slow_timer.to_f > 0 ? e.slow_mult.to_f : 1.0)
      catchup_mult = boss_catchup_speed_mult(e, len)
      move_speed = e.speed * slow_mult * catchup_mult
      e.x += dx / len * move_speed * 60.0 * step_dt
      e.y += dy / len * move_speed * 60.0 * step_dt
      update_enemy_shot(e, step_dt)
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
        hurt = (e.damage.to_i * type_mod * @shield_mult).ceil
        hurt = 1 if hurt < 1 && e.damage.to_i > 0
        hero_take_damage(hurt, 0.55)
      end
    end
    invalidate_enemy_grid
  rescue
    update_enemies_without_survivor_lod(dt) rescue nil
  end

  alias character_frame_without_survivor_lod character_frame unless method_defined?(:character_frame_without_survivor_lod)
  def character_frame(entity, source = nil)
    if entity && entity.kind && entity.kind != :hero && survivor_lite_enemy?(entity)
      return 0 if !point_on_screen?(entity.x, entity.y, 128)
      interval = survivor_enemy_lod_interval(entity)
      if interval > 1
        directions = entity.charset_directions
        directions = PokemonSurvivor::CHARSET_8_DIRECTIONS if PokemonSurvivor.eight_direction_bitmap?(source)
        frames = PokemonSurvivor.charset_frame_count(source, entity.direction, directions)
        speed = entity.moving ? (8.0 / interval.to_f) : PokemonSurvivor::IDLE_ANIMATION_FPS
        return (((@timer || 0) * speed).floor % frames)
      end
    end
    character_frame_without_survivor_lod(entity, source)
  rescue
    character_frame_without_survivor_lod(entity, source) rescue 0
  end

  alias special_enemy_hp_bar_without_survivor_lod special_enemy_hp_bar? unless method_defined?(:special_enemy_hp_bar_without_survivor_lod)
  def special_enemy_hp_bar?(enemy)
    return false if !special_enemy_hp_bar_without_survivor_lod(enemy)
    return true if !enemy || [:boss, :ultra_boss, :chest, :ultra_chest, :event_hunt].include?(enemy.kind)
    return true if enemy.hp.to_i < enemy.max_hp.to_i
    return false if @enemies && @enemies.length >= 120 && !point_on_screen?(enemy.x, enemy.y, 80)
    return false if @enemies && @enemies.length >= 170 && point_distance_sq(@hero.x, @hero.y, enemy.x, enemy.y) > 300.0 * 300.0
    true
  rescue
    false
  end

  alias draw_enemies_by_visual_priority_without_survivor_lod draw_enemies_by_visual_priority unless method_defined?(:draw_enemies_by_visual_priority_without_survivor_lod)
  def draw_enemies_by_visual_priority(bitmap)
    @drawn_minor_hp_bars = 0
    @minor_hp_bar_budget = @enemies && @enemies.length >= 170 ? 34 : 56
    draw_enemies_by_visual_priority_without_survivor_lod(bitmap)
  ensure
    @drawn_minor_hp_bars = 0
  end
end


