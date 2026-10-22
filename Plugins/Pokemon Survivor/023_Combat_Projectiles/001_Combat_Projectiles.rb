#===============================================================================
# Pokemon Survivor - Skills, projectiles, damage, XP, evolutions and combat helpers
#===============================================================================

class Scene_PokemonSurvivor

  def update_attacks(dt)
    update_headache(dt)
    dt *= equipment_skill_rate
    @learned_skills.each do |skill_id|
      next if skill_id == :headache && @headache_charge
      @skill_cooldowns[skill_id] = @skill_cooldowns[skill_id].to_f - dt
      fire_skill(skill_id) if @skill_cooldowns[skill_id] <= 0
    end
  end

  def hero_visual_x
    @hero.x + PokemonSurvivor::HERO_DRAW_OFFSET_X
  end

  def hero_visual_y
    @hero.y + PokemonSurvivor::HERO_DRAW_OFFSET_Y
  end

  def hero_effect_x
    @hero.x + PokemonSurvivor::HERO_EFFECT_OFFSET_X
  end

  def hero_effect_y
    @hero.y + PokemonSurvivor::HERO_EFFECT_OFFSET_Y
  end

  def fire_skill(skill_id)
    skill = PokemonSurvivor::SKILLS[skill_id]
    return if !skill
    case skill[:kind]
    when :impact_rain
      count = skill[:count] + @projectile_count_bonus.to_i + @skill_count_bonus[skill_id].to_i
      count = [count, projectile_count_cap(skill, skill[:max_count], count)].min
      count.times { spawn_bulbasaur_poison_rain_drop(skill.merge(id: skill_id, impact_rain: true)) }
    when :guard_twister
      count = skill[:count] + @projectile_count_bonus.to_i + @skill_count_bonus[skill_id].to_i
      count = [count, projectile_count_cap(skill, skill[:max_count], count)].min
      count.times do |i|
        break if @effects.length >= PokemonSurvivor::MAX_EFFECTS
        angle = @timer.to_f + i * Math::PI * 2.0 / count
        x, y = @hero.x + Math.cos(angle) * 80.0, @hero.y + Math.sin(angle) * 80.0
        radius = skill[:radius] + @skill_radius_bonus[skill_id].to_i
        spawn_charmander_twister_at(x, y, skill, radius, skill[:duration])
      end
    when :pursuit_guard
      fire_ancestral_flames(skill)
    when :psychic_headache
      return if @headache_charge
      if headache_direct?
        spawn_headache_blasts(skill, false)
      else
        @headache_charge = { phase: :wait, age: 0.0 }
      end
    when :psychic_dash
      interval = psi_trail_auto_interval
      return if !interval
      fire_psi_volley(skill, @hero.x, @hero.y)
      cooldown = interval * @cooldown_mult * @skill_cooldown_mult[skill_id] * projectile_haste_cooldown_mult(skill)
      @skill_cooldowns[skill_id] = [cooldown, 0.10].max
      return
    when :eevee_sweep
      fire_eevee_sweep(skill)
    when :fae_bloom
      fire_fae_bloom(skill)
    when :rook_tornado
      fire_rook_tornado(skill)
    when :apple_orbit
      fire_apple_orbit(skill)
    when :fire_twister
      fire_charmander_twister(skill)
    when :splash
      fire_splash(skill)
    when :survivor_swing
      fire_survivor_swing(skill)
    when :returning_swing
      fire_returning_swing(skill)
    when :drill_spikes
      fire_drill_spikes(skill)
    when :vortex
      fire_vortex(skill)
    when :aura
      fire_aura(skill)
    when :ring
      fire_ring(skill)
    when :nova
      fire_nova(skill)
    when :zone
      fire_zone(skill)
    when :contact
      fire_contact(skill)
    when :trail
      fire_trail(skill)
    when :boomerang
      fire_boomerang(skill)
    when :side_seek
      fire_side_seek(skill)
    when :charge_shot
      fire_charge_shot(skill)
    when :orbit
      @skill_cooldowns[skill_id] = 0.12
      return
    when :orbit_shot
      @skill_cooldowns[skill_id] = 0.12
      return
    when :dual_orbit_shot
      @skill_cooldowns[skill_id] = 0.12
      return
    else
      fire_projectile(skill)
    end
    cooldown = skill[:cooldown].to_f * @cooldown_mult * @skill_cooldown_mult[skill_id] * projectile_haste_cooldown_mult(skill)
    @skill_cooldowns[skill_id] = [cooldown, 0.10].max
  end


  def headache_direct?
    return PokemonSurvivor.species_key(@hero.name) == :GOLDUCK if PokemonSurvivor.species_key(@hero_base_name) == :PSYDUCK
    @hero_power_stage.to_i >= 2
  end

  def headache_movement_locked?
    !!(@headache_charge && (@headache_charge[:phase] == :failure || @headache_charge[:phase] == :success))
  end

  def update_headache(dt)
    if @headache_charge
      if !(@learned_skills || []).include?(:headache) || headache_direct?
        @headache_charge = nil
        @skill_cooldowns[:headache] = 0.0
      else
        charge = @headache_charge
        charge[:age] += dt
        if charge[:phase] == :wait && charge[:age] >= 20.0 / 6.0
          charge[:phase] = rand(8) == 0 ? :success : :failure
          charge[:age] = 0.0
          @focus_step_anim = nil
          @focus_step_input_buffer = 0.0
          @hero.moving = false
          prepare_psyduck_charge_bitmap if respond_to?(:prepare_psyduck_charge_bitmap)
          if charge[:phase] == :success
            spawn_headache_blasts(PokemonSurvivor::SKILLS[:headache], true)
          end
        elsif headache_movement_locked? && charge[:age] >= 0.5
          @headache_charge = nil
          @skill_cooldowns[:headache] = 0.0 if charge[:phase] == :failure
        end
      end
    end
    update_headache_waves(dt)
  end

  def spawn_headache_blasts(skill, charged)
    count = skill[:count].to_i + @projectile_count_bonus.to_i + @skill_count_bonus[:headache].to_i
    count = charged ? 12 : [[count, 1].max, projectile_count_cap(skill, skill[:max_count], count)].min
    targets = closest_visible_enemies_from(@hero.x, @hero.y, 9999, count)
    return if targets.empty?
    radius = skill[:radius].to_f + @skill_radius_bonus[:headache].to_f
    source = skill.merge(id: :headache, damage: (skill[:damage] * @skill_power_mult[:headache]).ceil)
    @headache_waves ||= []
    targets.each do |enemy|
      @headache_waves << { x: enemy.x, y: enemy.y, age: 0.0, duration: 8.0 / 12.0,
                           radius: radius, skill: source, hit: {}, fx: nil }
    end
  end

  def update_headache_waves(dt)
    return if !@headache_waves || @headache_waves.empty?
    @headache_waves.each do |wave|
      wave[:age] += dt
      progress = [wave[:age] / wave[:duration], 1.0].min
      radius = wave[:radius] * Math.sin(progress * Math::PI / 2.0)
      source = wave[:skill]
      # Damage is independent of the visual-effect budget; each blast hits once.
      if !wave[:fx] && @effects.length < PokemonSurvivor::MAX_EFFECTS
        wave[:fx] = [wave[:x], wave[:y], wave[:duration] - wave[:age] + dt,
                     skill_color(source), radius, :ground_zone, source, nil,
                     [wave[:age] - dt, 0.0].max, { headache_wave: true }]
        @effects << wave[:fx]
      end
      wave[:fx][4] = radius if wave[:fx]
      each_nearby_enemy_for(wave[:x], wave[:y], radius + PokemonSurvivor::BOSS_RADIUS + 10) do |enemy|
        next if !enemy || enemy.hp <= 0 || wave[:hit][enemy.object_id]
        next if point_distance_sq(wave[:x], wave[:y], enemy.x, enemy.y) > (radius + enemy.radius.to_f) ** 2
        wave[:hit][enemy.object_id] = true
        damage_enemy(enemy, source[:damage], :PSYCHIC, skill_color(source), source)
      end
    end
    @headache_waves.delete_if { |wave| wave[:age] >= wave[:duration] }
  end

  def fire_fae_bloom(skill)
    id = skill_id_for(skill)
    count = skill[:count].to_i + @projectile_count_bonus.to_i + @skill_count_bonus[id].to_i
    count = [[count, 1].max, projectile_count_cap(skill, skill[:max_count], count)].min
    targets = closest_visible_enemies_from(@hero.x, @hero.y, 9999, count)
    return if targets.empty?
    radius = skill[:radius].to_f + @skill_radius_bonus[id].to_f
    count.times do |i|
      target = targets[i % targets.length]
      angle = Math.atan2(target.y - @hero.y, target.x - @hero.x)
      angle += (i / targets.length) * 0.24 if i >= targets.length
      spawn_projectile(angle, skill) do |p|
        p.radius = radius * 0.25
        p.instance_variable_set(:@fae_max_radius, radius)
        p.vfx_scale = radius / 40.0
        p.ttl = skill[:vfx_frames].to_f / skill[:vfx_fps]
        p.pierce = 1
      end
    end
  end

  def equipment_adrenaline_active?
    @equipped_item && @equipped_item[:effect] == :low_hp_haste && @hero &&
      @hero.hp > 0 && @hero.hp * 10 < @hero.max_hp * 3
  end

  def equipment_skill_rate
    equipment_adrenaline_active? ? 1.15 : 1.0
  end

  def spawn_psychic_pursuit(skill, data)
    source = skill.merge(psychic_pursuit: true, keep_until_expiry: true,
                         infinite_pierce: true, hit_interval: 0.40, vfx_loop: true)
    claims = {}
    8.times do |i|
      spawn_projectile(i * Math::PI / 4.0, source) do |p|
        p.ttl = data[:burst_time].to_f
        p.pierce = 1
        p.homing = false
        p.instance_variable_set(:@psychic_claims, claims)
        p.instance_variable_set(:@psychic_idle_angle, i * Math::PI / 4.0)
      end
    end
  end

  def update_psychic_pursuit(p, dt)
    return if p.age < 0.12
    claims = p.instance_variable_get(:@psychic_claims)
    target = p.homing_target
    p.homing_refresh = p.homing_refresh.to_f - dt
    if p.homing_refresh <= 0.0 || (target && target.hp <= 0)
      claims.delete(target.object_id) if target && claims[target.object_id].equal?(p)
      claims.delete_if { |_id, shot| shot.ttl <= 0.0 || shot.pierce.to_i <= 0 }
      target = nearest_psychic_pursuit_target(p, claims)
      p.homing_target = target
      claims[target.object_id] = p if target
      p.homing_refresh = 0.18
    end
    angle = p.instance_variable_get(:@psychic_idle_angle).to_f + p.age * 1.8
    aim_x = target ? target.x : @hero.x + Math.cos(angle) * 72.0
    aim_y = target ? target.y : @hero.y + Math.sin(angle) * 72.0
    dx = aim_x - p.x
    dy = aim_y - p.y
    distance = Math.sqrt(dx * dx + dy * dy)
    if distance <= 0.01
      p.vx = p.vy = 0.0
    else
      step = [distance, p.speed * 60.0 * dt].min
      movement = [p.speed * 60.0 * dt, 0.001].max
      p.vx = dx / distance * step / movement
      p.vy = dy / distance * step / movement
    end
  end

  def nearest_psychic_pursuit_target(projectile, claims)
    best = nil
    distance = Float::INFINITY
    (@enemies || []).each do |enemy|
      next if enemy.hp <= 0 || claims.key?(enemy.object_id) || !enemy_visible?(enemy)
      d = point_distance_sq(projectile.x, projectile.y, enemy.x, enemy.y)
      next if d >= distance
      best, distance = enemy, d
    end
    if respond_to?(:tower_wisp_targets_for)
      tower_wisp_targets_for(projectile.x, projectile.y, 9999).each do |wisp|
        next if wisp.hp <= 0 || claims.key?(wisp.object_id)
        d = point_distance_sq(projectile.x, projectile.y, wisp.x, wisp.y)
        next if d >= distance
        best, distance = wisp, d
      end
    end
    best
  end

  def projectile_damage_frame_active?(projectile)
    return false if projectile.ttl.to_f <= 0.0
    source = projectile.source_skill
    return true if !source
    frame = projectile.age.to_f * (source[:vfx_fps] || 18.0)
    return false if source[:damage_from_frame] && frame < source[:damage_from_frame]
    return false if source[:damage_until_frame] && frame >= source[:damage_until_frame]
    true
  end

  def spawn_toxic_bombardment(skill, data)
    targets = closest_visible_enemies_from(@hero.x, @hero.y, 600, 48)
    targets = targets.select { |enemy| point_distance_sq(@hero.x, @hero.y, enemy.x, enemy.y) <= 600.0 * 600.0 }
    source = skill.merge(keep_until_expiry: true, infinite_pierce: true,
                         hit_interval: 9999.0, vfx_loop: false, vfx_fps: data[:vfx_fps] || 18.0,
                         damage_from_frame: data[:damage_from_frame], damage_until_frame: data[:damage_until_frame])
    targets.shuffle.first(data[:count].to_i).each do |target|
      spawn_projectile_from(target.x, target.y, 0.0, source) do |p|
        p.speed = p.vx = p.vy = 0.0
        p.radius = data[:radius].to_f
        p.vfx_scale = p.radius / (data[:visual_radius_base] || 36.0)
        p.ttl = data[:burst_time].to_f
        p.pierce = 1
      end
    end
  end

  # Keep only a token on the enemy, not the expired projectile or its captures.
  def attraction_source_available?(enemy, source)
    owner = enemy.instance_variable_get(:@survivor_attraction_owner)
    owner.nil? || owner.equal?(source.instance_variable_get(:@survivor_attraction_token))
  end

  def claim_enemy_attraction(enemy, source)
    return false if !enemy || enemy.hp <= 0 || !attraction_source_available?(enemy, source)
    token = source.instance_variable_get(:@survivor_attraction_token)
    unless token
      token = Object.new
      source.instance_variable_set(:@survivor_attraction_token, token)
    end
    enemy.instance_variable_set(:@survivor_attraction_owner, token)
    true
  end

  def spawn_fairy_prisons(skill, data)
    source = skill.merge(fairy_prison: true, keep_until_expiry: true,
                         infinite_pierce: true, hit_interval: data[:frame_ticks] ? 1.0 / 12.0 : 0.50, vfx_loop: true)
    source.merge!(frame_tick_fps: 12.0, vfx_fps: 12.0, hit_interval: 0.0) if data[:frame_ticks]
    claims = {}
    @fairy_prisons = []
    count = data[:sphere_count] || 8
    orbit_radius = data.fetch(:orbit_radius, 135.0).to_f
    count.times do |i|
      angle = i * Math::PI * 2.0 / count
      x = @hero.x + Math.cos(angle) * orbit_radius
      y = @hero.y + Math.sin(angle) * orbit_radius
      x, y = clamp_world_spawn_position(x, y, data[:radius]) if respond_to?(:clamp_world_spawn_position)
      spawn_projectile_from(x, y, 0.0, source) do |p|
        p.ttl = data[:burst_time].to_f
        p.radius = data[:radius].to_f
        p.vfx_scale = p.radius / 32.0
        p.speed = p.vx = p.vy = 0.0
        p.pierce = 1
        p.instance_variable_set(:@fairy_prison_data, { claims: claims, captured: {}, angle: angle,
                                follow_player: data[:follow_player],
                                orbit_radius: orbit_radius,
                                offset_x: x - @hero.x, offset_y: y - @hero.y })
        @fairy_prisons << p
      end
    end
  end

  def update_fairy_prisons(dt)
    return if !@fairy_prisons || @fairy_prisons.empty?
    active = @fairy_prisons.select { |p| p.ttl > dt && p.pierce.to_i > 0 && @projectiles.include?(p) }
    return if active.empty?
    claims = active.first.instance_variable_get(:@fairy_prison_data)[:claims]
    moved = false
    active.each do |p|
      data = p.instance_variable_get(:@fairy_prison_data)
      # Recover the fixed center from the last offset, including camera movement.
      center_x = p.x - data[:offset_x]
      center_y = p.y - data[:offset_y]
      center_x, center_y = @hero.x, @hero.y if data[:follow_player]
      angle = data[:angle] + (p.age + dt) * 0.65
      orbit_radius = data.fetch(:orbit_radius, 135.0)
      x = center_x + Math.cos(angle) * orbit_radius
      y = center_y + Math.sin(angle) * orbit_radius
      x, y = clamp_world_spawn_position(x, y, p.radius) if respond_to?(:clamp_world_spawn_position)
      dx, dy = x - p.x, y - p.y
      data[:captured].each_value do |enemy|
        next if enemy.hp <= 0
        enemy.x += dx
        enemy.y += dy
        moved = true
      end
      p.x, p.y = x, y
      data[:offset_x], data[:offset_y] = x - center_x, y - center_y
    end
    (@enemies || []).each do |enemy|
      next if enemy.hp <= 0
      p = claims[enemy.object_id]
      unless p && active.include?(p)
        p = nil
        nearest = 150.0 * 150.0
        active.each do |sphere|
          next unless attraction_source_available?(enemy, sphere)
          d = point_distance_sq(sphere.x, sphere.y, enemy.x, enemy.y)
          next if d > nearest
          p, nearest = sphere, d
        end
      end
      next if !p
      data = p.instance_variable_get(:@fairy_prison_data)
      dx = p.x - enemy.x
      dy = p.y - enemy.y
      distance_sq = dx * dx + dy * dy
      next if distance_sq > 150.0 * 150.0
      next unless claim_enemy_attraction(enemy, p)
      data[:claims][enemy.object_id] = p
      distance = Math.sqrt(distance_sq)
      if distance > 0.01
        step = [240.0 * dt, distance].min
        enemy.x += dx / distance * step
        enemy.y += dy / distance * step
        moved = true
      end
      if distance <= p.radius + enemy.radius + 240.0 * dt
        data[:captured][enemy.object_id] = enemy
        constrain_enemy_to_fairy_prison(enemy, p)
        moved = true
      end
    end
    invalidate_enemy_grid if moved
  end

  def constrain_enemy_to_fairy_prison(enemy, p)
    radius = [p.radius - enemy.radius, 2.0].max
    dx = enemy.x - p.x
    dy = enemy.y - p.y
    distance_sq = dx * dx + dy * dy
    return false if distance_sq <= radius * radius
    scale = radius / Math.sqrt(distance_sq)
    enemy.x = p.x + dx * scale
    enemy.y = p.y + dy * scale
    true
  end

  def enforce_fairy_prison_bounds
    return if !@fairy_prisons
    @fairy_prisons.delete_if { |p| p.ttl <= 0.0 || p.pierce.to_i <= 0 || !@projectiles.include?(p) }
    if @fairy_prisons.empty?
      @fairy_prisons = nil
      return
    end
    moved = false
    @fairy_prisons.each do |p|
      data = p.instance_variable_get(:@fairy_prison_data)
      data[:captured].delete_if do |id, enemy|
        dead = enemy.hp <= 0
        data[:claims].delete(id) if dead
        dead
      end
      data[:captured].each_value { |enemy| moved = constrain_enemy_to_fairy_prison(enemy, p) || moved }
    end
    invalidate_enemy_grid if moved
  end

  def fire_apple_orbit(skill)
    skill_id = skill_id_for(skill)
    count = skill[:count].to_i + @projectile_count_bonus.to_i + @skill_count_bonus[skill_id].to_i
    count = [[count, 1].max, projectile_count_cap(skill, skill[:max_count], count)].min
    radius = skill[:radius].to_f + @skill_radius_bonus[skill_id].to_f
    scale = radius / [skill[:radius].to_f, 1.0].max
    launch_targets = {}
    count.times do |i|
      break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
      angle = Math::PI * 2.0 * i / count.to_f
      spawn_projectile_from(@hero.x + Math.cos(angle) * radius, @hero.y + Math.sin(angle) * radius, angle, skill) do |p|
        p.orbit_target = @hero
        p.orbit_angle = angle
        p.orbit_radius = radius
        p.orbit_remaining = Math::PI * 2.0
        p.apple_launch_targets = launch_targets
        p.radius = 12.0 * scale
        p.vfx_scale = scale
        p.pierce = 1
        p.bounces = 0
        p.ttl = 2.2
      end
    end
  end

  def apple_orbit_projectile?(projectile)
    projectile.orbit_target && projectile.source_skill && projectile.source_skill[:kind] == :apple_orbit
  end

  def psi_trail_auto_interval
    return nil unless PokemonSurvivor.species_key(@hero_base_name) == :ABRA
    case PokemonSurvivor.species_key(@hero && @hero.name)
    when :KADABRA then 2.0
    when :ALAKAZAM, :ALAKAZAM_1 then 0.9
    end
  end

  def psi_trail_count(skill = PokemonSurvivor::SKILLS[:psi_trail])
    wanted = skill[:count].to_i + @projectile_count_bonus.to_i + @skill_count_bonus[:psi_trail].to_i
    [[wanted, 1].max, projectile_count_cap(skill, skill[:max_count], wanted)].min
  end

  def nearest_psi_target(x, y, visited = nil)
    best = nil
    distance = nil
    targets = @enemies || []
    targets = targets + tower_wisp_targets_for(x, y, 9999) if respond_to?(:tower_wisp_targets_for)
    targets.each do |enemy|
      next if !enemy || enemy.hp <= 0 || !enemy_visible?(enemy) || (visited && visited[enemy.object_id])
      d = point_distance_sq(x, y, enemy.x, enemy.y)
      next if distance && d >= distance
      best, distance = enemy, d
    end
    best
  end

  def spawn_psi_shot(skill, x, y, fallback_angle = 0.0)
    target = nearest_psi_target(x, y)
    angle = target ? Math.atan2(target.y - y, target.x - x) : fallback_angle
    spawn_projectile_from(x, y, angle, skill) do |p|
      p.radius *= 2.0
      p.vfx_scale = (p.vfx_scale || 1.0) * 2.0
      p.homing_target = target
      p.homing_refresh = 0.12
      p.instance_variable_set(:@psi_hit_targets, {})
      p.ttl = 3.5
    end
  end

  def fire_psi_volley(skill, x, y)
    count = psi_trail_count(skill)
    count.times { |i| spawn_psi_shot(skill, x, y, i * Math::PI * 2.0 / count) }
  end

  def emit_psi_dash_trail(anim, progress)
    return unless anim[:psi_count] && (@learned_skills || []).include?(:psi_trail)
    count = anim[:psi_count]
    while anim[:psi_emitted] < count
      fraction = (anim[:psi_emitted] + 0.5) / count.to_f
      break if fraction > progress
      # Emission positions are on the actual clamped Dash path, after camera scrolling.
      x = @hero.x - anim[:sx] * (progress - fraction)
      y = @hero.y - anim[:sy] * (progress - fraction)
      spawn_psi_shot(PokemonSurvivor::SKILLS[:psi_trail], x, y, Math.atan2(-anim[:dy], -anim[:dx]))
      anim[:psi_emitted] += 1
    end
  end

  def fire_eevee_sweep(skill)
    id = skill_id_for(skill)
    count = skill[:count].to_i + @projectile_count_bonus.to_i + @skill_count_bonus[id].to_i
    count = [[count, 1].max, projectile_count_cap(skill, skill[:max_count], count)].min
    radius = skill[:radius] + @skill_radius_bonus[id].to_f
    target = nearest_visible_enemy
    angle = target ? Math.atan2(target.y - @hero.y, target.x - @hero.x) : survivor_swing_facing_angle
    count.times do |i|
      break if @effects.length >= PokemonSurvivor::MAX_EFFECTS
      previous_size = @effects.length
      spawn_drill_spike(angle + i * Math::PI * 2.0 / count - Math::PI / 4.0, skill, radius)
      next if @effects.length == previous_size
      meta = @effects.last[9]
      meta[:eevee_sweep] = true
      meta[:visual_slide_in] = false
      meta.delete(:visual_angle_override)
    end
  end

  def eevee_sweep_angle(fx, meta)
    duration = [fx[6][:duration].to_f, 0.01].max
    meta[:angle] + [[fx[8].to_f / duration, 0.0].max, 1.0].min * Math::PI / 2.0
  end

  def persistent_player_projectile?(projectile)
    apple_orbit_projectile?(projectile) || (projectile.source_skill && projectile.source_skill[:infinite_pierce])
  end

  def charge_orchard_guard
    return if PokemonSurvivor.species_key(@hero_base_name) != :APPLIN || !@ultimate_data || @ultimate_drain_timer.to_f > 0.0
    return if @timer.to_f < @applin_guard_charge_ready_at.to_f
    cooldown = @ultimate_data[:cooldown].to_f
    @ultimate_charge = [@ultimate_charge.to_f + cooldown * 0.01, cooldown].min
    @applin_guard_charge_ready_at = @timer.to_f + 0.5
  end

  def fire_splash(skill)
    radius = skill[:radius].to_i
    @effects << [hero_effect_x, hero_effect_y, 0.20, skill_color(skill), radius, :ring, skill] if radius > 0
  rescue
  end

  def projectile_overcap_allowed?(skill)
    return false if !skill || skill[:ignore_projectile_count] || skill[:strict_max_count]
    return false if skill[:max_count].to_i == 1
    skill_id = skill_id_for(skill) rescue nil
    return false if skill_id == :normal_sweep
    true
  rescue
    false
  end

  def fire_rook_tornado(skill)
    skill_id = skill_id_for(skill)
    count = skill[:count].to_i + @projectile_count_bonus.to_i + @skill_count_bonus[skill_id].to_i
    count = [[count, 1].max, projectile_count_cap(skill, skill[:max_count], count)].min
    targets = closest_visible_enemies_from(@hero.x, @hero.y, 9999, count)
    return if targets.empty?
    count.times do |i|
      target = targets[i % targets.length]
      angle = Math.atan2(target.y - @hero.y, target.x - @hero.x)
      spawn_rook_tornado(angle, skill)
    end
  end

  def spawn_rook_tornado_burst(skill, data)
    source = skill.merge(vfx_frames: 52, vfx_fps: 12.0, vfx_loop: false,
                         infinite_pierce: true, hit_interval: 0.45, freeze_status: :rook_tornado)
    8.times { |i| spawn_rook_tornado(Math::PI * 2.0 * i / 8.0, source, true) }
  end

  def spawn_steel_tempest(skill, data)
    source = skill.merge(keep_until_expiry: true, infinite_pierce: true,
                         hit_interval: 0.45, vfx_frames: 52, vfx_fps: 12.0,
                         vfx_loop: true, pull_radius: 280.0, pull_speed: 260.0,
                         pull_min_distance: 0.0)
    angle = survivor_swing_facing_angle
    spawn_projectile(angle, source) do |p|
      offset = data[:radius].to_f * 0.75
      p.x = @hero.x + Math.cos(angle) * offset
      p.y = @hero.y + Math.sin(angle) * offset
      p.speed = data[:speed].to_f
      p.radius = data[:radius].to_f
      p.vfx_scale = p.radius / 24.0
      p.ttl = data[:burst_time].to_f
      p.cooldown = 0.0
      p.pierce = 1
      p.homing = false
      p.tornado_motion = { phase_x: rand * Math::PI * 2.0, phase_y: rand * Math::PI * 2.0,
                           jitter_x: 0.0, jitter_y: 0.0, max_radius: p.radius }
      update_rook_tornado_position(p, 0.0)
    end
  end

  def finish_steel_tempest(projectile)
    moved = false
    each_nearby_enemy_for(projectile.x, projectile.y, 328.0) do |enemy|
      next if enemy.hp <= 0 || enemy.kind == :tower_wisp
      next if point_distance_sq(projectile.x, projectile.y, enemy.x, enemy.y) > 280.0 ** 2
      dx, dy = enemy.x - @hero.x, enemy.y - @hero.y
      distance = Math.sqrt(dx * dx + dy * dy)
      dx, dy, distance = 1.0, 0.0, 1.0 if distance < 0.001
      resistance = [:boss, :ultra_boss, :chest, :ultra_chest].include?(enemy.kind) ? 0.25 : 1.0
      x, y = enemy.x + dx / distance * 180.0 * resistance, enemy.y + dy / distance * 180.0 * resistance
      x, y = clamp_world_spawn_position(x, y, enemy.radius) if respond_to?(:clamp_world_spawn_position)
      enemy.x, enemy.y = x, y
      moved = true
    end
    invalidate_enemy_grid if moved
  end

  def spawn_rook_tornado(angle, skill, orbit = false)
    skill_id = skill_id_for(skill)
    radius = skill[:radius].to_f + @skill_radius_bonus[skill_id].to_f
    spawn_projectile(angle, skill) do |p|
      p.radius = radius
      p.vfx_scale = radius / 24.0
      p.ttl = skill[:vfx_frames].to_f / skill[:vfx_fps].to_f
      p.pierce = 1
      p.bounces = 0
      p.homing = false
      p.tornado_motion = { phase_x: rand * Math::PI * 2.0, phase_y: rand * Math::PI * 2.0,
                           jitter_x: 0.0, jitter_y: 0.0, max_radius: radius }
      p.radius = radius * 0.50 unless orbit
      unless orbit
        p.tornado_motion[:hit_y] = 26.0 * p.vfx_scale
        p.tornado_motion[:hit_height] = 0.15
      end
      if orbit
        p.tornado_motion[:burst_tornado] = true
        p.tornado_motion[:launch_angle] = angle
        p.tornado_motion[:release_at] = (skill[:vfx_frames].to_f - 12.0) / skill[:vfx_fps]
        p.tornado_motion[:hit_y] = 0.0
        p.tornado_motion[:hit_height] = 1.0
        p.orbit_target = @hero
        p.orbit_angle = angle
        p.orbit_radius = 92.0
        update_rook_tornado_position(p, 0.0)
      end
    end
  end

  def update_rook_tornado_position(projectile, dt)
    motion = projectile.tornado_motion
    age = projectile.age.to_f
    jitter_x = (Math.sin(age * 3.1 + motion[:phase_x]) - Math.sin(motion[:phase_x])) * 8.0
    jitter_y = (Math.sin(age * 2.7 + motion[:phase_y]) - Math.sin(motion[:phase_y])) * 8.0
    if motion[:burst_tornado] && projectile.orbit_target && age >= motion[:release_at]
      projectile.orbit_target = nil
      projectile.vx = Math.cos(motion[:launch_angle])
      projectile.vy = Math.sin(motion[:launch_angle])
      projectile.speed = 4.0
    end
    if projectile.orbit_target
      target = projectile.orbit_target
      return projectile.ttl = 0.0 if target.hp <= 0
      angle = projectile.orbit_angle + age * 1.5
      projectile.x = target.x + Math.cos(angle) * projectile.orbit_radius + jitter_x
      projectile.y = target.y + Math.sin(angle) * projectile.orbit_radius + jitter_y
    elsif motion[:burst_tornado]
      flight_dt = [dt, [age - motion[:release_at], 0.0].max].min
      projectile.x += projectile.vx * projectile.speed * 60.0 * flight_dt + jitter_x - motion[:jitter_x]
      projectile.y += projectile.vy * projectile.speed * 60.0 * flight_dt + jitter_y - motion[:jitter_y]
    else
      # Relative jitter preserves map anchoring when the camera shifts every entity.
      source = projectile.source_skill
      frame = age * source[:vfx_fps].to_f
      frame %= source[:vfx_frames].to_f if source[:vfx_loop] && source[:vfx_frames].to_f > 0.0
      growth_frames = [source[:vfx_frames].to_f - 12.0, 1.0].max
      growth = [[frame / growth_frames, 0.0].max, 1.0].min
      size_growth = [[frame / (growth_frames * 0.60), 0.0].max, 1.0].min
      fade = [[(frame - growth_frames) / 12.0, 0.0].max, 1.0].min
      projectile.radius = motion[:max_radius] * (0.50 + 0.65 * size_growth) * (1.0 - fade)
      motion[:hit_y] = (26.0 - 30.0 * growth - 24.0 * fade) * projectile.vfx_scale
      motion[:hit_height] = 0.15 + 0.70 * size_growth - 0.60 * fade
      projectile.x += projectile.vx * projectile.speed * 60.0 * dt + jitter_x - motion[:jitter_x]
      projectile.y += projectile.vy * projectile.speed * 60.0 * dt + jitter_y - motion[:jitter_y]
    end
    motion[:jitter_x] = jitter_x
    motion[:jitter_y] = jitter_y
  end

  def spawn_blazing_striker(skill, data)
    enemy = nearest_visible_enemy
    angle = enemy ? Math.atan2(enemy.y - @hero.y, enemy.x - @hero.x) : survivor_swing_facing_angle
    source = skill.merge(infinite_pierce: true, pull_radius: 190.0, pull_speed: 300.0, pull_min_distance: 100.0, hit_interval: 0.30)
    spawn_projectile(angle, source) do |p|
      p.radius = data[:radius].to_f
      p.vfx_scale = p.radius / 24.0
      p.ttl = data[:burst_time].to_f
      p.cooldown = 0.0
      p.pierce = 1
    end
  end

  def update_blazing_striker_pull(projectile, dt)
    source = projectile.source_skill
    return if !source || !source[:pull_radius] || projectile.ttl <= 0.0
    if !@hero || point_distance_sq(projectile.x, projectile.y, @hero.x, @hero.y) < source[:pull_min_distance].to_f ** 2
      projectile.cooldown = 0.0
      return
    end
    projectile.cooldown = projectile.cooldown.to_f + dt
    return if projectile.cooldown < 0.08
    elapsed = [projectile.cooldown, 0.16].min
    projectile.cooldown = 0.0
    radius = source[:pull_radius].to_f
    moved = false
    each_nearby_enemy_for(projectile.x, projectile.y, radius + 48) do |enemy|
      next if enemy.hp <= 0 || enemy.kind == :tower_wisp
      dx = projectile.x - enemy.x
      dy = projectile.y - enemy.y
      distance_sq = dx * dx + dy * dy
      next if distance_sq > radius * radius || distance_sq <= 1.0
      next unless claim_enemy_attraction(enemy, projectile)
      distance = Math.sqrt(distance_sq)
      resistance = [:boss, :ultra_boss, :chest, :ultra_chest].include?(enemy.kind) ? 0.25 : 1.0
      step = [source[:pull_speed] * elapsed * resistance, distance].min
      x = enemy.x + dx / distance * step
      y = enemy.y + dy / distance * step
      x, y = clamp_world_spawn_position(x, y, enemy.radius) if respond_to?(:clamp_world_spawn_position)
      enemy.x, enemy.y = x, y
      moved = true
    end
    invalidate_enemy_grid if moved
  end

  def blazing_striker_touches_wall?(projectile)
    return false if !world_walls_enabled?
    x = projectile.x + @world_x.to_f - Graphics.width / 2.0
    y = projectile.y + @world_y.to_f - Graphics.height / 2.0
    x.abs + projectile.radius >= world_limit_x || y.abs + projectile.radius >= world_limit_y
  end

  def trigger_ember_impact(enemy, source)
    return if source.respond_to?(:orbit_target) && source.orbit_target && source.source_skill && source.source_skill[:eevee_orbit]
    skill = source.respond_to?(:source_skill) ? source.source_skill : source
    if skill.is_a?(Hash) && skill[:forest_relay]
      spawn_forest_relay(enemy, skill)
      return
    end
    if skill.is_a?(Hash) && skill[:relay_spark]
      spark = { id: skill_id_for(skill), kind: :psychic_dash, type: :ELECTRIC,
        damage: 12, speed: 6.5, pierce: 1, bounce: 2, homing: true,
        vfx: "VFX_ELECTRIC2_SHOT", freeze: 0.6 }
      target = nearest_psi_target(enemy.x, enemy.y, { enemy.object_id => true })
      if target
        angle = Math.atan2(target.y - enemy.y, target.x - enemy.x)
        spawn_projectile_from(enemy.x, enemy.y, angle, spark) do |p|
          p.instance_variable_set(:@psi_hit_targets, { enemy.object_id => true })
          p.homing_target = target
        end
      end
    end
    if skill.is_a?(Hash) && skill[:impact_flurry]
      spawn_impact_flurry(enemy, skill)
      return
    end
    if skill.is_a?(Hash) && skill[:impact_twister]
      twister = PokemonSurvivor::SKILLS[:fire_twister].merge(id: skill_id_for(skill))
      spawn_charmander_twister_at(enemy.x, enemy.y, twister, twister[:radius], twister[:duration]) if @effects.length < PokemonSurvivor::MAX_EFFECTS
      return
    end
    if skill.is_a?(Hash) && skill[:psychic_well]
      spawn_psychic_well(enemy.x, enemy.y, skill)
      return
    end
    return if !skill.is_a?(Hash) || !skill[:impact_blast]
    skill_id = skill_id_for(skill)
    radius = skill[:impact_radius].to_f + (@skill_radius_bonus ||= Hash.new(0))[skill_id].to_f
    radius *= dreepy_projectile_size_multiplier
    duration = (skill[:impact_frames] || 12).to_f / 24.0
    blast = skill.merge(id: skill_id, impact_blast: false, kind: :zone,
                       damage: skill[:impact_damage], dot: skill[:impact_dot] || skill[:burn_time],
                       type: skill[:impact_type] || skill[:type],
                       vfx: skill[:impact_vfx] || "VFX_FIRE6", vfx_loop: false, vfx_fps: 24.0,
                       vfx_radius: skill[:impact_vfx_radius] || 27.0)
    damage_enemies_in_radius(enemy.x, enemy.y, radius, blast)
    if @effects.length < PokemonSurvivor::MAX_EFFECTS
      @effects << [enemy.x, enemy.y, duration, skill_color(blast), radius, :circle, blast]
    end
  end

  def spawn_psychic_well(x, y, skill)
    radius = skill[:well_radius].to_f
    duration = skill[:well_duration].to_f + @upgrade_levels[:psychic_well_duration].to_i * 0.5
    field = skill.merge(id: :psychic_well, psychic_well: false, kind: :zone,
      damage: skill[:well_damage], speed: 0.0, pierce: 1, homing: false,
      infinite_pierce: true, keep_until_expiry: true, hit_interval: 0.40,
      pull_radius: radius * 1.5, pull_speed: 100.0, pull_min_distance: 0.0,
      vfx: "VFX_PSYCHIC7", vfx_frames: 3, vfx_loop: true)
    spawn_projectile_from(x, y, 0.0, field) do |projectile|
      projectile.ttl = duration
      projectile.radius = radius
      projectile.vx = projectile.vy = 0.0
      sheet = cached_vfx_bitmap("VFX_PSYCHIC7")
      projectile.vfx_scale = sheet && !sheet.disposed? ? radius * 2.0 / [sheet.height, 1].max : 0.5
    end
  end

  def projectile_count_cap(skill, base_max, wanted_count = nil)
    max = [base_max.to_i, 1].max
    wanted = wanted_count ? wanted_count.to_i : 0
    has_extra = wanted > max || @projectile_count_bonus.to_i > 0
    max += 1 if has_extra && projectile_overcap_allowed?(skill)
    max
  rescue
    [base_max.to_i, 1].max
  end

  def fire_projectile(skill)
    skill_id = skill_id_for(skill)
    count = skill[:count].to_i + @projectile_count_bonus + @skill_count_bonus[skill_id]
    count = [count, projectile_count_cap(skill, skill[:max_count] || 8, count)].min
    target = nearest_visible_enemy
    return if !target
    base_angle = Math.atan2(target.y - @hero.y, target.x - @hero.x)
    if skill[:evolution_pair] || skill[:parallel_shots]
      count = @hero_power_stage.to_i >= 1 ? 2 : 1 if skill[:evolution_pair]
      count.times do |i|
        offset = (i - (count - 1) / 2.0) * 20.0
        spawn_projectile_from(@hero.x - Math.sin(base_angle) * offset,
                              @hero.y + Math.cos(base_angle) * offset, base_angle, skill)
      end
      return
    end
    if skill[:four_direction_shots]
      [0.0, -Math::PI / 2.0, Math::PI / 2.0, Math::PI].first(count).each do |offset|
        spawn_projectile(base_angle + offset, skill)
      end
      return
    end
    spread = count <= 1 ? 0 : 0.22
    count.times do |i|
      offset = (i - ((count - 1) / 2.0)) * spread
      spawn_projectile(base_angle + offset, skill)
    end
  end

  def fire_boomerang(skill)
    skill_id = skill_id_for(skill)
    count = skill[:count].to_i + @projectile_count_bonus + @skill_count_bonus[skill_id]
    count = [count, projectile_count_cap(skill, skill[:max_count] || 6, count)].min
    target = nearest_visible_enemy
    return if !target
    base_angle = Math.atan2(target.y - @hero.y, target.x - @hero.x)
    spread = count <= 1 ? 0 : 0.28
    count.times do |i|
      offset = (i - ((count - 1) / 2.0)) * spread
      spawn_projectile(base_angle + offset, skill) do |p|
        p.boomerang = true
        if skill_id == :bone_return
          p.radius *= 1.5
          p.vfx_scale = (p.vfx_scale || 1.0) * 1.5
        end
      end
    end
  end

  def fire_side_seek(skill)
    skill_id = skill_id_for(skill)
    count = skill[:count].to_i + @skill_count_bonus[skill_id]
    count = [[count, 2].max, projectile_count_cap(skill, skill[:max_count] || 6, count)].min
    target = nearest_visible_enemy
    return if !target
    offsets = []
    pair_count = (count / 2.0).ceil
    pair_count.times do |i|
      distance = 22 + (i * 14)
      offsets << -distance
      offsets << distance
    end
    offsets.first(count).each do |side_offset|
      spawn_side_homing_projectile(side_offset, skill)
    end
  end

  def spawn_side_homing_projectile(side_offset, skill)
    dir = @hero.direction || PokemonSurvivor::DIR_DOWN
    side_x = 1
    side_y = 0
    case dir
    when PokemonSurvivor::DIR_UP, PokemonSurvivor::DIR_DOWN
      side_x = side_offset < 0 ? -1 : 1
      side_y = 0
    else
      side_x = 0
      side_y = side_offset < 0 ? -1 : 1
    end
    x = @hero.x + side_x * side_offset.abs
    y = @hero.y + side_y * side_offset.abs
    target = nearest_visible_enemy_from(x, y)
    return if !target
    angle = Math.atan2(target.y - y, target.x - x)
    spawn_projectile_from(x, y, angle, skill) { |p| p.homing = true }
  end

  def fire_charge_shot(skill)
    @charge_shots ||= []
    skill_id = skill_id_for(skill)
    max_count = skill[:count].to_i + @projectile_count_bonus.to_i + @skill_count_bonus[skill_id].to_i
    max_count = [[max_count, 1].max, projectile_count_cap(skill, skill[:max_count] || 4, max_count)].min
    active = @charge_shots.count { |shot| shot[:skill_id] == skill_id }
    spawn_count = [max_count - active, 0].max
    return if spawn_count <= 0
    spawn_count.times do |i|
      slot = active + i
      @charge_shots << {
        skill_id: skill_id,
        skill: skill,
        timer: 0.0,
        total: [skill[:charge_time].to_f * @skill_cooldown_mult[skill_id].to_f * @cooldown_mult.to_f * (@eevee_burst_timer.to_f > 0 ? 0.2 : 1.0), 0.65].max,
        slot: slot,
        count: max_count
      }
    end
  rescue
  end

  def update_charge_shots(dt)
    dt *= equipment_skill_rate
    return if !@charge_shots || @charge_shots.empty?
    @charge_shot_launch_targets = {}
    @charge_shots.each do |shot|
      shot[:timer] = shot[:timer].to_f + dt.to_f
      next if shot[:timer] < shot[:total].to_f
      launch_charge_shot(shot)
      shot[:done] = true
    end
    @charge_shots.delete_if { |shot| shot[:done] }
    @charge_shot_launch_targets = nil
  rescue
    @charge_shots = []
    @charge_shot_launch_targets = nil
  end

  def spawn_impact_flurry(enemy, skill)
    spawn_impact_flurry_at(enemy.x, enemy.y, skill)
  end

  def spawn_forest_relay(enemy, skill)
    id = skill_id_for(skill)
    count = skill[:relay_count].to_i
    targets = closest_visible_enemies_from(enemy.x, enemy.y, 420, count, enemy)
    reserved = { enemy.object_id => true }
    targets.each { |target| reserved[target.object_id] = true }
    targets.each do |target|
      break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
      shot = { id: id, kind: :projectile, type: :GRASS, damage: 14,
        speed: 6.0, pierce: 1, homing: true, vfx: "VFX_GRASS6",
        vfx_frames: 12, vfx_loop: true, impact_flurry: true,
        impact_type: :GRASS, impact_vfx: "VFX_GRASS6_EX",
        impact_frames: 5, impact_damage: 4, impact_radius: 30 }
      angle = Math.atan2(target.y - enemy.y, target.x - enemy.x)
      spawn_projectile_from(enemy.x, enemy.y, angle, shot) do |projectile|
        excluded = reserved.dup
        excluded.delete(target.object_id)
        projectile.instance_variable_set(:@gen9_excluded_targets, excluded)
        projectile.instance_variable_set(:@forest_reserved_targets, reserved)
        projectile.homing_target = target
        projectile.homing_refresh = 10.0
      end
    end
  end

  def spawn_impact_flurry_at(x, y, skill)
    return if @effects.length >= PokemonSurvivor::MAX_EFFECTS
    id = skill_id_for(skill)
    frames = skill[:impact_frames].to_i
    radius = skill[:impact_radius].to_f + @skill_radius_bonus[id].to_f
    if skill[:impact_pull_radius]
      field = { id: id, kind: :zone, type: skill[:impact_type], damage: skill[:impact_damage],
        speed: 0.0, pierce: 1, infinite_pierce: true, keep_until_expiry: true,
        pull_radius: skill[:impact_pull_radius], pull_speed: 180.0,
        pull_min_distance: 0.0, frame_tick_fps: 24.0, hit_interval: 0.0,
        vfx: skill[:impact_vfx], vfx_loop: false, vfx_frames: frames, vfx_fps: 24.0 }
      spawn_projectile_from(x, y, 0.0, field) do |p|
        p.ttl = frames / 24.0
        p.radius = radius
        p.vx = p.vy = 0.0
      end
      return
    end
    flurry = { id: id, kind: :survivor_swing, type: skill[:impact_type],
      damage: skill[:impact_damage], duration: frames / 24.0, vfx: skill[:impact_vfx],
      vfx_frames: frames, vfx_fps: 24.0, vfx_loop: false, tick_per_frame: true,
      single_row_vfx: !skill[:impact_8dir], centered_visual: true, radial_hit: true,
      visual_scale: 1.0, visual_radius_base: radius, hit_radius_mult: 1.0 }
    flurry[:freeze] = skill[:impact_freeze] if skill[:impact_freeze]
    flurry[:dot] = skill[:impact_dot] if skill[:impact_dot]
    if skill[:impact_knockback]
      flurry[:knockback] = skill[:impact_knockback]
      flurry[:knock_limit] = 1
    end
    previous = @effects.length
    spawn_survivor_swing(0.0, flurry, radius)
    return if @effects.length == previous
    fx = @effects.last
    fx[0], fx[1] = x, y
    fx[9][:fixed_world] = true
  end

  def fire_ancestral_flames(skill)
    id = skill_id_for(skill)
    return if @projectiles.any? { |p| p.ttl > 0 && p.source_skill && p.source_skill[:ancestral_guard] }
    count = [[skill[:count] + @projectile_count_bonus.to_i + @skill_count_bonus[id].to_i, 1].max, 4].min
    source = skill.merge(id: id, ancestral_guard: true, psychic_pursuit: true,
      infinite_pierce: true, keep_until_expiry: true, hit_interval: 0.4)
    claims = {}
    count.times do |i|
      spawn_projectile(i * Math::PI * 2.0 / count, source) do |p|
        p.ttl = 4.0
        p.homing = false
        p.instance_variable_set(:@psychic_claims, claims)
        p.instance_variable_set(:@psychic_idle_angle, i * Math::PI * 2.0 / count)
      end
    end
  end

  def launch_charge_shot(shot)
    skill = shot[:skill]
    pos = charge_shot_position(shot)
    target = charge_shot_unique_target(shot, pos[0], pos[1])
    angle = target ? Math.atan2(target.y - pos[1], target.x - pos[0]) : charge_shot_slot_angle(shot)
    shot_skill = skill.clone
    shot_skill[:id] = shot[:skill_id]
    shot_skill[:vfx] = skill[:shot_vfx] || (skill[:type] == :ELECTRIC ? "VFX_ELECTRIC2_SHOT" : projectile_vfx_name(skill))
    spawn_projectile_from(pos[0], pos[1], angle, shot_skill) do |p|
      p.radius = skill[:radius].to_i + @skill_radius_bonus[shot[:skill_id]].to_i + 5
      p.ttl = 2.6
    end
  rescue
  end

  def charge_shot_unique_target(shot, x, y)
    reserved = (@charge_shot_launch_targets ||= {})[shot[:skill_id]] ||= []
    targets = visible_enemy_targets_from(x, y, 420, [shot[:count].to_i + 3, 6].max)
    target = targets.find { |candidate| candidate && !reserved.any? { |used| used.equal?(candidate) } }
    target ||= nearest_visible_enemy_from(x, y) || nearest_visible_enemy
    reserved << target if target
    target
  rescue
    nearest_visible_enemy_from(x, y) || nearest_visible_enemy
  end

  def charge_shot_slot_angle(shot)
    count = [shot[:count].to_i, 1].max
    return hero_facing_angle if count <= 1
    hero_facing_angle + ((Math::PI * 2.0) * (shot[:slot].to_i % count).to_f / count.to_f)
  rescue
    hero_facing_angle
  end

  def charge_shot_position(shot)
    count = [shot[:count].to_i, 1].max
    angle = charge_shot_slot_angle(shot)
    offset = count <= 1 ? 34.0 : 42.0
    x = @hero.x + Math.cos(angle) * offset
    y = @hero.y + Math.sin(angle) * offset
    [x, y]
  rescue
    [@hero.x, @hero.y]
  end

  def charge_shot_progress(shot)
    [[shot[:timer].to_f / [shot[:total].to_f, 0.01].max, 0.0].max, 1.0].min
  rescue
    0.0
  end

  def projectile_haste_cooldown_mult(skill = nil)
    return 0.5 if @ceruledge_burst_timer.to_f > 0
    return 0.2 if @galar_rush_timer.to_f > 0 && skill && skill_id_for(skill) == :night_raid
    return 0.2 if @eevee_burst_timer.to_f > 0
    return 0.5 if @kubfu_focus_timer.to_f > 0 && skill && skill_id_for(skill) == :disciplined_strikes
    if @projectile_overdrive_timer.to_f > 0 && skill
      return @projectile_overdrive_mult.to_f if @passive_key == :ENTEI && skill_id_for(skill) == :volcanic_guard
      return @projectile_overdrive_mult.to_f if [:projectile, :nova].include?(skill[:kind]) || skill_id_for(skill) == :steel_volley
    end
    return 0.5 if @larvitar_haste_timer.to_f > 0 && skill && skill[:kind] == :projectile
    1.0
  rescue
    1.0
  end

  def fire_nova(skill)
    skill_id = skill_id_for(skill)
    count = skill[:count].to_i + @projectile_count_bonus + @skill_count_bonus[skill_id]
    count = [[count, 6].max, projectile_count_cap(skill, skill[:max_count] || 16, count)].min
    count.times do |i|
      angle = (Math::PI * 2 * i / count) + (@timer * 0.35)
      spawn_projectile(angle, skill)
    end
  end

  def fire_charmander_twister(skill, forced_count = nil)
    return if !@hero
    skill_id = skill_id_for(skill)
    count = forced_count || (skill[:count].to_i + @projectile_count_bonus.to_i + @skill_count_bonus[skill_id].to_i)
    count = [[count, 1].max, projectile_count_cap(skill, skill[:max_count] || 4, count)].min
    targets = visible_enemy_targets_from(@hero.x, @hero.y, skill[:range].to_i, count)
    duration = skill[:duration].to_f + @charmander_twister_duration_bonus.to_f
    targets.each { |enemy| spawn_charmander_twister_at(enemy.x, enemy.y, skill, skill[:radius].to_i, duration) }
  end

  def spawn_charmander_twister_at(x, y, skill, radius, duration)
    source = skill.dup
    source[:id] ||= skill_id_for(skill)
    # Zero-based frames: 1, 2, 3, 4, 5, 4, 3, 4, 5, 6, 7.
    source[:vfx_sequence] = [0, 1, 2, 3, 4, 3, 2, 3, 4, 5, 6]
    source[:vfx_frame_time] = [duration.to_f, 0.22].max / 11.0
    phase = rand * Math::PI * 2.0
    meta = { charmander_twister: true, origin_x: x, origin_y: y,
             phase: phase, orbit_sign: rand(2) == 0 ? -1.0 : 1.0 }
    @effects << [x, y, duration, skill_color(source), radius, :zone, source, 0.0, 0.0, meta]
  end

  def update_charmander_twister_position(fx, meta)
    step = fx[6][:vfx_frame_time]
    moving_age = [fx[8].to_f - step, 0.0].max
    radius = [moving_age / step, 1.0].min * fx[4].to_f * 0.45
    angle = meta[:phase] + moving_age * 5.0 * meta[:orbit_sign]
    fx[0] = meta[:origin_x] + Math.cos(angle) * radius
    fx[1] = meta[:origin_y] + Math.sin(angle) * radius
  end

  def fire_vortex(skill)
    skill_id = skill_id_for(skill)
    return if @projectiles.any? { |p| dragon_chain_projectile?(p) }
    count = skill[:count].to_i + @skill_count_bonus[skill_id]
    count = [[count, 1].max, projectile_count_cap(skill, skill[:max_count] || 8, count)].min
    sides = [[4 + @skill_line_bonus[skill_id].to_i, 4].max, 8].min
    reserve_projectile_slots(count * sides)
    base_radius = skill[:radius].to_i + @skill_radius_bonus[skill_id]
    spacing = 14
    phase = (@timer * 0.18) % (Math::PI * 2)
    rotation_speed = skill[:speed].to_f + (@skill_orbit_speed_bonus[skill_id].to_i * 0.18)
    sides.times do |side|
      side_angle = phase + (Math::PI * 2 * side / sides)
      count.times do |i|
        radius = base_radius + (spacing * i)
        spawn_projectile_from(hero_effect_x + Math.cos(side_angle) * radius,
                              hero_effect_y + Math.sin(side_angle) * radius,
                              side_angle, skill) do |p|
          p.orbit_target = @hero
          p.orbit_angle = side_angle
          p.orbit_radius = radius
          p.orbit_growth = 0.0
          p.pierce = 9999
          p.ttl = 5.0
          p.hit_cooldowns = {}
          p.speed = rotation_speed
        end
      end
    end
  end

  def fire_aura(skill)
    skill_id = skill_id_for(skill)
    radius = skill[:radius].to_i + @skill_radius_bonus[skill_id]
    damage_enemies_in_radius(@hero.x, @hero.y, radius, skill)
    @effects << [hero_effect_x, hero_effect_y, 0.18, skill_color(skill), radius, :circle, skill]
  end

  def fire_ring(skill)
    skill_id = skill_id_for(skill)
    radius = skill[:radius].to_i + @skill_radius_bonus[skill_id]
    damage_enemies_in_radius(@hero.x, @hero.y, radius, skill)
    @effects << [hero_effect_x, hero_effect_y, 0.28, skill_color(skill), radius, :ring, skill]
  end

  def fire_zone(skill)
    skill_id = skill_id_for(skill)
    target = nearest_visible_enemy || nearest_enemy
    return if !target
    radius = skill[:radius].to_i + @skill_radius_bonus[skill_id]
    range = skill[:range].to_i
    return if distance(target, @hero) > range
    count = zone_strike_count(skill, skill_id)
    targets = visible_enemy_targets_from(@hero.x, @hero.y, range, count)
    targets = [target] if targets.empty?
    duration = [0.36, skill[:freeze].to_f, skill[:dot].to_f, skill[:slow].to_f].max
    if (skill[:type] == :GROUND || skill_id == :slime_wave) && @passive_ground_zone_duration_mult.to_f > 1.0
      duration *= @passive_ground_zone_duration_mult.to_f
    end
    zone_skill = skill[:id] ? skill : skill.clone
    zone_skill[:id] ||= skill_id
    if skill[:type] == :GROUND && @passive_ground_slow_mult
      zone_skill = zone_skill.clone
      zone_skill[:id] ||= skill_id
      zone_skill[:slow_mult] = @passive_ground_slow_mult.to_f
    end
    targets.first(count).each do |enemy|
      damage_enemies_in_radius(enemy.x, enemy.y, radius, zone_skill)
      zone_kind = skill[:type] == :GROUND ? :ground_zone : :zone
      tick = skill[:type] == :GROUND ? 0.45 : nil
      @effects << [enemy.x, enemy.y, duration, skill_color(skill), radius, zone_kind, zone_skill, tick, 0.0]
    end
  end
  def zone_strike_count(skill, skill_id)
    return 1 if skill[:type] != :FAIRY
    count = skill[:count].to_i + @skill_count_bonus[skill_id]
    [[count, 1].max, projectile_count_cap(skill, skill[:max_count] || 5, count)].min
  rescue
    1
  end

  def fire_trail(skill)
    return if !@hero.moving
    skill_id = skill_id_for(skill)
    radius = skill[:radius].to_i + @skill_radius_bonus[skill_id]
    duration = skill[:duration].to_f
    duration *= @passive_ground_zone_duration_mult.to_f if skill_id == :slime_wave && @passive_ground_zone_duration_mult.to_f > 1.0
    dx = @last_move_dx || 0
    dy = @last_move_dy || 1
    x = @hero.x - (dx * 28)
    y = @hero.y - (dy * 28)
    @effects << [x, y, duration, skill_color(skill), radius, :poison_zone, skill]
  end
  def fire_contact(skill)
    skill_id = skill_id_for(skill)
    radius = @hero.radius + skill[:radius].to_i + @skill_radius_bonus[skill_id]
    damage_enemies_in_radius(@hero.x, @hero.y, radius, skill)
    @effects << [hero_effect_x, hero_effect_y, 0.14, skill_color(skill), radius, :ring, skill]
  end

  def update_orbit_skills(dt)
    return if !@learned_skills
    @orbit_hit_timers.delete_if do |key, value|
      value = value.to_f - dt.to_f
      @orbit_hit_timers[key] = value
      value <= 0
    end
    build_enemy_grid
    @learned_skills.each do |skill_id|
      skill = PokemonSurvivor::SKILLS[skill_id]
      next if !skill || ![:orbit, :orbit_shot, :dual_orbit_shot].include?(skill[:kind])
      update_orbit_shots(skill_id, skill, dt) if skill[:kind] == :orbit_shot
      update_dual_orbit_shots(skill_id, skill, dt) if skill[:kind] == :dual_orbit_shot
      positions = skill[:kind] == :dual_orbit_shot ? dual_orbit_positions(skill_id, skill) : orbit_positions(skill_id, skill)
      positions.each do |pos|
        destroy_enemy_projectiles_near(pos[0], pos[1], pos[2] + 6) if skill[:type] == :STEEL
        each_nearby_enemy_for(pos[0], pos[1], pos[2] + PokemonSurvivor::BOSS_RADIUS + 4) do |e|
          next if e.hp <= 0
          next if point_distance_sq(pos[0], pos[1], e.x, e.y) > ((pos[2] + e.radius) * (pos[2] + e.radius))
          side = pos[4]
          key = [skill_id, side, e.object_id]
          next if @orbit_hit_timers[key]
          hit_skill = skill[:kind] == :dual_orbit_shot ? dual_orbit_contact_skill(skill, side) : skill
          if skill[:orbit_respawn_time]
            hit_skill = skill.merge(id: skill_id, instant_ko_normal: e.kind == :wild)
          end
          base_damage = (hit_skill[:damage].to_i * @skill_power_mult[skill_id]).ceil
          damage_enemy(e, base_damage, hit_skill[:type], skill_color(hit_skill), hit_skill)
          fire_orbit_contact_shot(pos[0], pos[1], e, skill_id, skill) if hit_skill[:contact_shot]
          if hit_skill[:orbit_freeze]
            apply_enemy_status_once(e, :freeze) do
              e.freeze_timer = [e.freeze_timer.to_f, hit_skill[:orbit_freeze].to_f].max
            end
          end
          interval = hit_skill[:cooldown].to_f * @skill_cooldown_mult[skill_id]
          @orbit_hit_timers[key] = [interval, 0.12].max
          if skill[:orbit_respawn_time]
            @orbit_hit_timers[[skill_id, :orbit_respawn, pos[5]]] = skill[:orbit_respawn_time].to_f
            break
          end
        end
      end
    end
  end

  def fire_orbit_contact_shot(x, y, hit_enemy, skill_id, skill)
    return if !skill[:contact_shot] || @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
    key = [skill_id, :contact_shot, hit_enemy.object_id]
    return if @orbit_hit_timers[key]
    count = skill[:contact_shot_count].to_i + @projectile_count_bonus.to_i
    count = [[count, 1].max, projectile_count_cap(skill, 4, count)].min
    targets = visible_enemy_targets_from(x, y, 300, count)
    targets = targets.reject { |target| target.equal?(hit_enemy) }
    targets = [hit_enemy].compact if targets.empty?
    shot = skill.clone
    shot[:id] = skill_id
    shot[:kind] = :projectile
    shot[:count] = 1
    shot[:pierce] = 1
    shot[:bounce] = skill[:bounce] || 1
    shot[:damage] = [(skill[:damage].to_i * (skill[:contact_shot_damage_mult] || 0.75).to_f).ceil, 1].max
    shot[:vfx] = skill[:contact_shot_vfx] || skill[:vfx]
    targets.first(count).each do |target|
      break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
      next if !target || target.hp.to_i <= 0
      angle = Math.atan2(target.y - y, target.x - x)
      spawn_projectile_from(x, y, angle, shot) do |p|
        p.ttl = 1.25
        p.hit_cooldowns ||= {}
        p.hit_cooldowns[hit_enemy.object_id] = 0.12 if hit_enemy
      end
    end
    @orbit_hit_timers[key] = [skill[:contact_shot_cooldown].to_f, 0.22].max
  rescue
  end
  def orbit_positions(skill_id, skill)
    count = skill[:count].to_i + @skill_count_bonus[skill_id]
    max_count = skill[:max_count] || 6
    count = [[count, 1].max, projectile_count_cap(skill, max_count, count)].min
    radius = skill[:radius].to_i + @skill_radius_bonus[skill_id]
    hit_radius = skill[:hit_radius] ? skill[:hit_radius].to_i : PokemonSurvivor::PROJECTILE_RADIUS + 2
    tempo_level = @upgrade_levels[:"#{skill_id}_tempo"].to_i
    orbit_level = (@skill_orbit_speed_bonus ||= Hash.new(0))[skill_id].to_i
    speed = (skill[:orbit_speed] || skill[:speed]).to_f * (1.0 + (tempo_level * 0.12) + (orbit_level * 0.10)) * (@skill_speed_mult[skill_id] || 1.0)
    phase = (@timer || 0) * speed
    ret = []
    count.times do |i|
      next if skill[:orbit_respawn_time] && @orbit_hit_timers[[skill_id, :orbit_respawn, i]]
      angle = phase + (Math::PI * 2 * i / count)
      pos = [hero_effect_x + Math.cos(angle) * radius, hero_effect_y + Math.sin(angle) * radius, hit_radius]
      pos[5] = i if skill[:orbit_respawn_time]
      ret << pos
    end
    ret
  end

  def dual_orbit_positions(skill_id, skill)
    count = skill[:count].to_i + @skill_count_bonus[skill_id]
    max_count = skill[:max_count] || 3
    count = [[count, 1].max, projectile_count_cap(skill, max_count, count)].min
    radius = skill[:radius].to_i + @skill_radius_bonus[skill_id]
    hit_radius = skill[:hit_radius] ? skill[:hit_radius].to_i : PokemonSurvivor::PROJECTILE_RADIUS + 3
    tempo_level = @upgrade_levels[:"#{skill_id}_tempo"].to_i
    orbit_level = (@skill_orbit_speed_bonus ||= Hash.new(0))[skill_id].to_i
    speed = (skill[:orbit_speed] || skill[:speed]).to_f * (1.0 + (tempo_level * 0.10) + (orbit_level * 0.10)) * (@skill_speed_mult[skill_id] || 1.0)
    phase = (@timer || 0) * speed
    ret = []
    count.times do |i|
      angle = phase + (Math::PI * 2 * i / count)
      ret << [hero_effect_x + Math.cos(angle) * radius, hero_effect_y + Math.sin(angle) * radius, hit_radius, angle, :ghost]
      opposite = angle + Math::PI
      ret << [hero_effect_x + Math.cos(opposite) * radius, hero_effect_y + Math.sin(opposite) * radius, hit_radius, opposite, :normal]
    end
    ret
  end

  def dual_orbit_contact_skill(skill, side)
    ret = skill.clone
    ret[:id] = skill_id_for(skill) || :twin_mirage
    if side == :normal
      ret[:name] = _INTL("Twin Mirage Normal")
      ret[:type] = :NORMAL
      ret[:vfx] = skill[:normal_orbit_vfx] || "VFX_NORMAL_ORBIT"
      ret[:slow] = nil
      ret[:slow_mult] = nil
      ret[:knockback] = skill[:knockback] || 38
      ret[:knock_limit] = skill[:knock_limit] || 1
    else
      ret[:name] = _INTL("Twin Mirage Ghost")
      ret[:type] = :GHOST
      ret[:vfx] = skill[:ghost_orbit_vfx] || "VFX_GHOST_ORBIT"
      ret[:slow] = skill[:slow] || 1.5
      ret[:slow_mult] = skill[:slow_mult] || 0.42
      ret[:knockback] = nil
      ret[:knock_limit] = nil
    end
    ret
  rescue
    skill
  end

  def destroy_enemy_projectiles_near(x, y, radius)
    r2 = radius * radius
    @projectiles.each do |p|
      next if p.owner != :enemy
      next if point_distance_sq(x, y, p.x, p.y) > r2
      p.ttl = 0
      p.pierce = 0
    end
  rescue
  end

  def update_orbit_shots(skill_id, skill, dt)
    @orbit_shot_timers[skill_id] = @orbit_shot_timers[skill_id].to_f - dt * equipment_skill_rate
    return if @orbit_shot_timers[skill_id] > 0
    positions = orbit_positions(skill_id, skill)
    positions.each do |pos|
      break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
      shot_count = 1 + @projectile_count_bonus.to_i
      shot_count = [[shot_count, 1].max, projectile_count_cap(skill, 6, shot_count)].min
      targets = visible_enemy_targets_from(pos[0], pos[1], 260, shot_count)
      next if targets.empty?
      targets.each do |target|
        break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
        angle = Math.atan2(target.y - pos[1], target.x - pos[0])
        spawn_projectile_from(pos[0], pos[1], angle, skill)
      end
    end
    cooldown = skill[:shot_cooldown].to_f * @skill_cooldown_mult[skill_id]
    cooldown *= 0.2 if @eevee_burst_timer.to_f > 0
    @orbit_shot_timers[skill_id] = [cooldown, 0.18].max
    @orbit_shot_timers[skill_id] *= 0.5 if skill_id == :aurora_orbit && @aurora_current_timer.to_f > 0
  rescue
  end

  def update_dual_orbit_shots(skill_id, skill, dt)
    @orbit_shot_timers[skill_id] = @orbit_shot_timers[skill_id].to_f - dt * equipment_skill_rate
    return if @orbit_shot_timers[skill_id] > 0
    shot_count = 1 + @projectile_count_bonus.to_i
    shot_count = [[shot_count, 1].max, projectile_count_cap(skill, 4, shot_count)].min
    dual_orbit_positions(skill_id, skill).each do |pos|
      break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
      side = pos[4]
      targets = visible_enemy_targets_from(pos[0], pos[1], 280, shot_count)
      next if targets.empty?
      shot_skill = skill.clone
      shot_skill[:id] = skill_id
      shot_skill[:count] = 1
      shot_skill[:pierce] = 1
      if side == :normal
        shot_skill[:name] = _INTL("Twin Mirage Normal Shot")
        shot_skill[:type] = :NORMAL
        shot_skill[:vfx] = skill[:normal_shot_vfx] || "VFX_NORMAL2_SHOT"
        shot_skill[:bounce] = 0
        shot_skill[:slow] = nil
        shot_skill[:slow_mult] = nil
        shot_skill[:knockback] = skill[:knockback] || 38
        shot_skill[:knock_limit] = skill[:knock_limit] || 1
        shot_skill[:damage] = [(skill[:damage].to_i * 1.15).ceil, 1].max
      else
        shot_skill[:name] = _INTL("Twin Mirage Ghost Shot")
        shot_skill[:type] = :GHOST
        shot_skill[:vfx] = skill[:ghost_shot_vfx] || "VFX_GHOST"
        shot_skill[:bounce] = skill[:bounce].to_i + (@skill_bounce_bonus ||= Hash.new(0))[skill_id].to_i
        shot_skill[:slow] = skill[:slow] || 1.5
        shot_skill[:slow_mult] = skill[:slow_mult] || 0.42
        shot_skill[:knockback] = nil
        shot_skill[:knock_limit] = nil
      end
      targets.each do |target|
        break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
        angle = Math.atan2(target.y - pos[1], target.x - pos[0])
        spawn_projectile_from(pos[0], pos[1], angle, shot_skill)
      end
    end
    cooldown = skill[:shot_cooldown].to_f * @skill_cooldown_mult[skill_id]
    cooldown *= 0.2 if @eevee_burst_timer.to_f > 0
    @orbit_shot_timers[skill_id] = [cooldown, 0.22].max
  rescue
  end

  def closest_visible_enemies_from(x, y, radius, count, excluded = nil)
    build_enemy_grid if !@enemy_grid
    limit = [count.to_i, 1].max
    candidates = nearby_enemies_for(x, y, radius)
    candidates = @enemies if candidates.empty?
    best = []
    candidates.each do |e|
      next if !e || e.hp <= 0 || e.equal?(excluded) || !enemy_visible?(e)
      dist = point_distance_sq(x, y, e.x, e.y)
      next if best.length >= limit && dist >= best[-1][0]
      insert_at = best.length
      best.each_with_index do |pair, i|
        if dist < pair[0]
          insert_at = i
          break
        end
      end
      best.insert(insert_at, [dist, e])
      best.pop while best.length > limit
    end
    best.map { |pair| pair[1] }
  rescue
    []
  end

  def visible_enemy_targets_from(x, y, radius, count)
    closest_visible_enemies_from(x, y, radius, count)
  rescue
    []
  end

  def nearest_visible_enemy_from(x, y)
    best = nil
    best_dist = nil
    found = false
    each_nearby_enemy_for(x, y, 260) do |e|
      next if !e || e.hp <= 0 || !enemy_visible?(e)
      found = true
      dist = point_distance_sq(x, y, e.x, e.y)
      if !best_dist || dist < best_dist
        best = e
        best_dist = dist
      end
    end
    if !found
      (@enemies || []).each do |e|
        next if !e || e.hp <= 0 || !enemy_visible?(e)
        dist = point_distance_sq(x, y, e.x, e.y)
        if !best_dist || dist < best_dist
          best = e
          best_dist = dist
        end
      end
    end
    best
  rescue
    nil
  end
  def point_distance(x1, y1, x2, y2)
    dx = x1 - x2
    dy = y1 - y2
    Math.sqrt(dx * dx + dy * dy)
  end

  def point_distance_sq(x1, y1, x2, y2)
    dx = x1 - x2
    dy = y1 - y2
    (dx * dx) + (dy * dy)
  end

  def collision?(a, b)
    if a.respond_to?(:tornado_motion) && a.tornado_motion && !a.orbit_target
      return rook_tornado_collision?(a, b)
    end
    radius = a.radius + b.radius
    point_distance_sq(a.x, a.y, b.x, b.y) <= radius * radius
  rescue
    false
  end

  def invalidate_enemy_grid
    @enemy_grid = nil
  rescue
  end

  def build_enemy_grid
    return @enemy_grid if @enemy_grid
    cell = PokemonSurvivor::ENEMY_GRID_CELL
    # Recycle empty containers only; never retain targets from an older grid.
    # A hit can rebuild the grid inside another collision iterator.
    grid = @enemy_grid_query_depth.to_i > 0 ? {} : (@enemy_grid_storage || {})
    @enemy_grid_storage = grid
    rows = (@enemy_grid_row_pool ||= [])
    buckets = (@enemy_grid_bucket_pool ||= [])
    grid.each_value do |row|
      row.each_value do |bucket|
        bucket.clear
        buckets << bucket if buckets.length < 512
      end
      row.clear
      rows << row if rows.length < 128
    end
    grid.clear
    @enemy_grid = grid
    (@enemies || []).each do |enemy|
      next if enemy.hp <= 0
      gx = (enemy.x / cell).floor
      gy = (enemy.y / cell).floor
      row = (@enemy_grid[gx] ||= rows.pop || {})
      row[gy] ||= buckets.pop || []
      row[gy] << enemy
    end
    # Seals use the same collision geometry and hit cooldowns, but no enemy AI.
    if respond_to?(:tower_wisp_targets_for)
      tower_wisp_targets_for(@hero.x, @hero.y, 9999).each do |seal|
        gx = (seal.x / cell).floor
        gy = (seal.y / cell).floor
        row = (@enemy_grid[gx] ||= rows.pop || {})
        (row[gy] ||= buckets.pop || []) << seal
      end
    end
  rescue
    @enemy_grid = {}
  end

  def each_nearby_enemy_for(x, y, radius)
    build_enemy_grid if !@enemy_grid
    @enemy_grid_query_depth = @enemy_grid_query_depth.to_i + 1
    query_entered = true
    cell = PokemonSurvivor::ENEMY_GRID_CELL
    min_x = ((x - radius) / cell).floor
    max_x = ((x + radius) / cell).floor
    min_y = ((y - radius) / cell).floor
    max_y = ((y + radius) / cell).floor
    gx = min_x
    while gx <= max_x
      row = @enemy_grid[gx]
      if row
        gy = min_y
        while gy <= max_y
          bucket = row[gy]
          bucket.each { |enemy| yield(enemy) } if bucket
          gy += 1
        end
      end
      gx += 1
    end
  rescue
    (@enemies || []).each { |enemy| yield(enemy) }
  ensure
    @enemy_grid_query_depth -= 1 if query_entered
  end
  def nearby_enemies_for(x, y, radius)
    ret = []
    each_nearby_enemy_for(x, y, radius) { |enemy| ret << enemy }
    ret
  rescue
    @enemies || []
  end

  def damage_enemies_in_radius(x, y, radius, skill)
    build_enemy_grid if !@enemy_grid
    skill_id = skill_id_for(skill)
    base_damage = (skill[:damage].to_i * @skill_power_mult[skill_id]).ceil
    color = skill_color(skill)
    type = skill[:type]
    each_nearby_enemy_for(x, y, radius + 48) do |e|
      next if e.hp <= 0
      hit_radius = radius + e.radius
      next if !point_on_screen?(e.x, e.y, hit_radius + 48)
      next if point_distance_sq(x, y, e.x, e.y) > hit_radius * hit_radius
      damage_enemy(e, base_damage, type, color, skill)
    end
  end

  def spawn_projectile(angle, skill)
    spawn_projectile_from(@hero.x, @hero.y, angle, skill) { |p| yield(p) if block_given? }
  end

  def dreepy_projectile_size_multiplier
    return 1.5 if @ceruledge_burst_timer.to_f > 0
    @passive_key == :DREEPY && @projectile_overdrive_timer.to_f > 0.0 ? 1.5 : 1.0
  end

  def resize_dreepy_burst_projectile(projectile, scale)
    return if projectile.owner != :player
    previous = projectile.instance_variable_get(:@dreepy_size_scale) || 1.0
    return if previous == scale
    ratio = scale / previous
    projectile.radius *= ratio
    projectile.vfx_scale = (projectile.vfx_scale || 1.0) * ratio
    projectile.instance_variable_set(:@dreepy_size_scale, scale)
  end

  def spawn_projectile_from(x, y, angle, skill)
    return if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
    p = PokemonSurvivorEntity.new(:projectile, skill[:name], x, y)
    p.owner = :player
    skill_id = skill_id_for(skill)
    p.damage = (skill[:damage].to_i * @skill_power_mult[skill_id]).ceil
    p.attack_type = skill[:type] || @hero.attack_type || :NORMAL
    p.source_skill = skill
    p.speed = skill[:speed].to_f * @skill_speed_mult[skill_id]
    p.pierce = skill[:pierce].to_i + (@skill_pierce_bonus ||= Hash.new(0))[skill_id].to_i
    p.bounces = skill[:bounce].to_i + (@skill_bounce_bonus ||= Hash.new(0))[skill_id].to_i
    p.boomerang = false
    p.homing = false
    p.radius = PokemonSurvivor::PROJECTILE_RADIUS
    p.vx = Math.cos(angle)
    p.vy = Math.sin(angle)
    p.color = skill_color(skill)
    p.vfx_name = projectile_vfx_name(skill)
    p.ttl = skill[:kind] == :boomerang ? 1.55 : 2.2
    p.age = 0.0
    p.homing = true if skill[:homing]
    if skill[:psychic_well]
      p.radius *= 2.0
      p.vfx_scale = 2.0
    end
    yield(p) if block_given?
    resize_dreepy_burst_projectile(p, dreepy_projectile_size_multiplier)
    @projectiles << p
    play_survivor_se(:shot, "Survivor/Battle throw", 0.10, PokemonSurvivor::SFX_SHOT_VOLUME, 118)
  end

  def update_projectiles(dt)
    update_fairy_prisons(dt)
    build_enemy_grid
    dreepy_scale = dreepy_projectile_size_multiplier
    apple_shields = nil
    if @learned_skills.include?(:apple_aegis)
      apple_shields = @projectiles.select { |p| p.pierce.to_i > 0 && apple_orbit_projectile?(p) }
    end
    @projectiles.each do |p|
      next if p.pierce.to_i <= 0
      # Restore the base size before movement skills recalculate their own radius.
      resize_dreepy_burst_projectile(p, 1.0) if p.instance_variable_get(:@dreepy_size_scale)
      p.age = p.age.to_f + dt
      update_projectile_hit_cooldowns(p, dt)
      source = p.source_skill
      frame_ticks = 1
      if source && source[:frame_tick_fps]
        frame = (p.age * source[:frame_tick_fps]).floor
        previous_frame = p.instance_variable_get(:@last_damage_frame)
        frame_ticks = frame - (previous_frame || -1)
        p.instance_variable_set(:@last_damage_frame, frame)
      end
      pursuit = source && source[:psychic_pursuit]
      update_psychic_pursuit(p, dt) if pursuit
      if p.tornado_motion
        update_rook_tornado_position(p, dt)
      else
        update_orbit_projectile(p, dt) if p.orbit_target
        update_boomerang_projectile(p) if p.boomerang
        update_homing_projectile(p, dt) if p.homing
        if !p.orbit_target
          travel_mult = p.owner == :player && @ceruledge_burst_timer.to_f > 0 ? 2.0 : 1.0
          p.x += p.vx * p.speed * 60.0 * dt * travel_mult
          p.y += p.vy * p.speed * 60.0 * dt * travel_mult
        end
      end
      if source && source[:kind] == :fae_bloom
        progress = [[p.age * source[:vfx_fps] / 10.0, 0.0].max, 1.0].min
        p.radius = p.instance_variable_get(:@fae_max_radius) * (0.25 + 0.75 * progress)
      end
      p.ttl -= dt
      if source && source[:kind] == :steel_tempest && p.ttl <= 0.0 && p.ttl + dt > 0.0
        finish_steel_tempest(p)
      end
      resize_dreepy_burst_projectile(p, dreepy_scale) if dreepy_scale != 1.0
      next if p.tornado_motion && p.ttl <= 0.0
      next if source && source[:keep_until_expiry] && p.ttl <= 0.0
      next if source && (source[:damage_from_frame] || source[:damage_until_frame]) && !projectile_damage_frame_active?(p)
      if p.source_skill && p.source_skill[:kind] == :blazing_striker && blazing_striker_touches_wall?(p)
        p.ttl = 0.0
        if @ultimate_data && @ultimate_data[:kind] == :blazing_striker
          @ultimate_charge = 0.0
          @ultimate_drain_timer = 0.0
          @ultimate_drain_duration = 0.0
        end
        next
      end
      next if p.ttl <= 0.0 && p.source_skill && p.source_skill[:pull_radius]
      update_blazing_striker_pull(p, dt) if p.owner == :player && p.source_skill && p.source_skill[:pull_radius]
      if p.owner == :enemy
        if apple_shields && apple_shields.any? { |apple| apple.orbit_target && collision?(p, apple) }
          p.pierce = 0
          charge_orchard_guard
          next
        end
        if deoxys_current_form == :DEOXYS_2
          p.pierce = 0
          next
        end
        persistent_titan = p.instance_variable_get(:@titan_persistent_homing)
        if @item_invuln_timer <= 0 && (!persistent_titan || @invuln.to_f <= 0) && collision?(p, @hero)
          type_mod = PokemonSurvivor.type_multiplier(p.attack_type, @hero.types)
          hurt = (p.damage.to_i * type_mod * @shield_mult * (@enemy_projectile_shield_mult || 1.0) * mewtwo_guard_multiplier).ceil
          hurt = 1 if hurt < 1 && p.damage.to_i > 0
          hero_take_damage(hurt, 0.35)
          p.pierce = 0 unless persistent_titan
        end
        next
      end
      hit_y = p.y + (p.tornado_motion ? p.tornado_motion[:hit_y].to_f : 0.0)
      next if frame_ticks <= 0
      each_nearby_enemy_for(p.x, hit_y, p.radius + PokemonSurvivor::BOSS_RADIUS + 8) do |e|
        next if e.hp <= 0
        next if (p.instance_variable_get(:@gen9_excluded_targets) || {}).key?(e.object_id)
        next if pursuit && !e.equal?(p.homing_target)
        next if !point_on_screen?(e.x, e.y, 96)
        next if !collision?(p, e)
        next if source && source[:kind] == :psychic_dash && (p.instance_variable_get(:@psi_hit_targets) || {})[e.object_id]
        next if projectile_hit_cooldown_active?(p, e)
        if persistent_player_projectile?(p)
          interval = p.source_skill[:hit_interval] || (apple_orbit_projectile?(p) ? 0.45 : 9999.0)
          set_projectile_hit_cooldown(p, e, interval)
        elsif dragon_chain_projectile?(p)
          next if projectile_hit_cooldown_active?(p, e)
          set_projectile_hit_cooldown(p, e, 0.42)
        elsif sweep_projectile?(p)
          next if projectile_hit_cooldown_active?(p, e)
          set_projectile_hit_cooldown(p, e, 0.18)
        end
        frame_ticks.times do
          break if e.hp <= 0
          damage_enemy(e, p.damage, p.attack_type, p.color, p)
        end
        defeat_enemy(e) if e.hp.to_i <= 0 && !e.instance_variable_get(:@defeated)
        split_skill_projectile(p, e) if p.source_skill && p.source_skill[:split].to_i > 0
        split_impact_radial_projectile(p, e) if p.source_skill && p.source_skill[:impact_radial]
        split_impact_homing_projectile(p, e) if p.source_skill && p.source_skill[:impact_homing]
        if persistent_player_projectile?(p) || dragon_chain_projectile?(p) || sweep_projectile?(p)
          next
        elsif p.bounces.to_i > 0
          p.bounces -= 1
          redirect_projectile_to_next_enemy(p, e)
          break
        else
          p.pierce -= 1
        end
        break if p.pierce <= 0
      end
    end
    @projectiles.delete_if do |p|
      p.ttl <= 0 || p.pierce <= 0 ||
        (!p.orbit_target && !p.tornado_motion && !(p.source_skill && (p.source_skill[:pull_radius] || p.source_skill[:keep_until_expiry])) && !point_on_screen?(p.x, p.y, 80))
    end
    prune_defeated_enemies
  end

  def prune_defeated_enemies
    return if !@enemies
    @enemies.delete_if do |enemy|
      next true if !enemy
      if enemy.hp.to_i <= 0
        defeat_enemy(enemy) if !enemy.instance_variable_get(:@defeated)
        true
      else
        false
      end
    end
  rescue
    @enemies.delete_if { |enemy| enemy && enemy.hp.to_i <= 0 } if @enemies
  end

  def sweep_projectile?(projectile)
    skill = projectile && projectile.source_skill
    skill && skill[:kind] == :sweep
  rescue
    false
  end

  def dragon_chain_projectile?(projectile)
    projectile && projectile.owner == :player && projectile.orbit_target && projectile.attack_type == :DRAGON
  rescue
    false
  end

  def update_projectile_hit_cooldowns(projectile, dt)
    return if !projectile || !projectile.hit_cooldowns
    projectile.hit_cooldowns.delete_if do |key, value|
      value = value.to_f - dt.to_f
      projectile.hit_cooldowns[key] = value
      value <= 0
    end
  rescue
  end

  def projectile_hit_cooldown_active?(projectile, enemy)
    projectile.hit_cooldowns ||= {}
    projectile.hit_cooldowns[enemy.object_id].to_f > 0
  rescue
    false
  end

  def set_projectile_hit_cooldown(projectile, enemy, seconds)
    projectile.hit_cooldowns ||= {}
    projectile.hit_cooldowns[enemy.object_id] = seconds.to_f
  rescue
  end

  def update_orbit_projectile(projectile, dt)
    target = projectile.orbit_target
    return projectile.ttl = 0 if !target || target.hp <= 0
    if apple_orbit_projectile?(projectile)
      skill = projectile.source_skill
      skill_id = skill_id_for(skill)
      spin = skill[:orbit_speed].to_f * (1.0 + @skill_orbit_speed_bonus[skill_id].to_i * 0.10) * @skill_speed_mult[skill_id].to_f
      turn = [spin * dt, projectile.orbit_remaining.to_f].min
      projectile.orbit_angle += turn
      projectile.orbit_remaining -= turn
      projectile.x = target.x + Math.cos(projectile.orbit_angle) * projectile.orbit_radius
      projectile.y = target.y + Math.sin(projectile.orbit_angle) * projectile.orbit_radius
      projectile.ttl = 2.2 + dt
      if projectile.orbit_remaining <= 0.0
        reserved = projectile.apple_launch_targets ||= {}
        enemy = closest_visible_enemies_from(projectile.x, projectile.y, 9999, reserved.length + 1).find do |candidate|
          !reserved.key?(candidate.object_id)
        end
        if !enemy
          projectile.orbit_remaining = Math::PI * 2.0
          return
        end
        # Reservations belong to this volley only, including apples still orbiting.
        reserved[enemy.object_id] = true
        angle = Math.atan2(enemy.y - projectile.y, enemy.x - projectile.x)
        projectile.orbit_target = nil
        projectile.vx = Math.cos(angle)
        projectile.vy = Math.sin(angle)
        projectile.hit_cooldowns.clear if projectile.hit_cooldowns
      end
      return
    end
    projectile.orbit_angle = projectile.orbit_angle.to_f + projectile.speed.to_f * dt
    projectile.orbit_radius = projectile.orbit_radius.to_f + (projectile.orbit_growth.to_f * 60.0 * dt)
    radius = [projectile.orbit_radius.to_f, 12.0].max
    projectile.x = target.x + Math.cos(projectile.orbit_angle) * radius
    projectile.y = target.y + Math.sin(projectile.orbit_angle) * radius
  rescue
    projectile.ttl = 0
  end

  def split_impact_radial_projectile(projectile, hit_enemy)
    return if projectile.split_done
    return if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
    skill = PokemonSurvivor::SKILLS[:normal_shot].clone
    source = projectile.source_skill || {}
    source_id = source[:id] || skill_id_for(source)
    count = [[source[:impact_radial].to_i + (@skill_impact_bonus ||= Hash.new(0))[source_id].to_i, 2].max, 8].min
    skill[:id] = source[:id] || skill[:id]
    skill[:type] = source[:impact_type] || :NORMAL
    skill[:damage] = [(projectile.damage.to_i * 0.34).ceil, 1].max
    skill[:speed] = 5.8
    skill[:pierce] = 1
    skill[:count] = 1
    skill[:vfx] = source[:impact_vfx] || "VFX_NORMAL"
    offset = 0.0
    count.times do |i|
      break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
      angle = offset + (Math::PI * 2.0 * i / count.to_f)
      spawn_projectile_from(projectile.x, projectile.y, angle, skill) do |p|
        p.ttl = 1.15
        p.radius = PokemonSurvivor::PROJECTILE_RADIUS
        p.split_done = true
        p.hit_cooldowns ||= {}
        p.hit_cooldowns[hit_enemy.object_id] = 0.18 if hit_enemy
      end
    end
    projectile.split_done = true
  rescue
  end
  def split_impact_homing_projectile(projectile, hit_enemy)
    return if projectile.split_done
    return if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
    source = projectile.source_skill || {}
    source_id = source[:id] || skill_id_for(source)
    count = [[source[:impact_homing].to_i + (@skill_impact_bonus ||= Hash.new(0))[source_id].to_i, 1].max, 6].min
    targets = closest_visible_enemies_from(projectile.x, projectile.y, 420, count, hit_enemy)
    targets = [hit_enemy].compact if targets.empty? && hit_enemy
    skill = PokemonSurvivor::SKILLS[:normal_shot].clone
    skill[:id] = source[:id] || skill[:id]
    skill[:name] = source[:name]
    skill[:type] = source[:impact_type] || source[:type] || :NORMAL
    skill[:damage] = [(projectile.damage.to_i * (source[:impact_damage_mult] || 0.45).to_f).ceil, 1].max
    skill[:speed] = source[:impact_speed] || 6.1
    skill[:dot] = source[:impact_dot] if source[:impact_dot]
    skill[:pierce] = 1
    skill[:count] = 1
    skill[:vfx] = source[:impact_vfx] || source[:vfx] || projectile.vfx_name
    targets.first(count).each do |target|
      break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
      next if !target || target.hp.to_i <= 0
      angle = Math.atan2(target.y - projectile.y, target.x - projectile.x)
      spawn_projectile_from(projectile.x, projectile.y, angle, skill) do |p|
        p.homing = true
        p.split_done = true
        p.ttl = 1.35
        p.radius = PokemonSurvivor::PROJECTILE_RADIUS
        p.hit_cooldowns ||= {}
        p.hit_cooldowns[hit_enemy.object_id] = 0.14 if hit_enemy
      end
    end
    projectile.split_done = true
  rescue
  end
  def split_skill_projectile(projectile, hit_enemy)
    return if projectile.split_done
    return if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
    skill = projectile.source_skill || PokemonSurvivor::SKILLS[:ghost_wisp]
    return if skill[:split].to_i <= 0
    source_id = skill_id_for(skill)
    split_count = [[skill[:split].to_i + (@skill_impact_bonus ||= Hash.new(0))[source_id].to_i, 1].max, 8].min
    targets = closest_visible_enemies_from(projectile.x, projectile.y, 420, split_count, hit_enemy)
    targets.each do |target|
      break if @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
      angle = Math.atan2(target.y - projectile.y, target.x - projectile.x)
      spawn_projectile_from(projectile.x, projectile.y, angle, skill) do |p|
        p.homing = true
        p.split_done = true
        p.damage = [(projectile.damage * 0.55).ceil, 1].max
      end
    end
    projectile.split_done = true
  rescue
  end

  def update_boomerang_projectile(projectile)
    return if projectile.age.to_f < 0.58
    dx = @hero.x - projectile.x
    dy = @hero.y - projectile.y
    len = [Math.sqrt(dx * dx + dy * dy), 1].max
    projectile.vx = dx / len
    projectile.vy = dy / len
  rescue
  end

  def update_homing_projectile(projectile, dt)
    reserved = projectile.instance_variable_get(:@forest_reserved_targets)
    if reserved
      target = projectile.homing_target
      if !target || target.hp <= 0 || !enemy_visible?(target)
        target = nearest_psi_target(projectile.x, projectile.y, reserved)
        reserved[target.object_id] = true if target
        projectile.homing_target = target
      end
      unless target
        projectile.pierce = 0
        return
      end
      excluded = reserved.dup
      excluded.delete(target.object_id)
      projectile.instance_variable_set(:@gen9_excluded_targets, excluded)
      projectile.homing_refresh = dt.to_f + 1.0
    end
    if projectile.source_skill && projectile.source_skill[:cinder_chorus]
      return if projectile.orbit_target
      target = projectile.homing_target
      if !target || target.hp <= 0 || !enemy_visible?(target)
        target = cinder_chorus_target(projectile, 560)
        projectile.homing_target = target
      end
      unless target
        projectile.orbit_target = @hero
        projectile.orbit_angle = Math.atan2(projectile.y - @hero.y, projectile.x - @hero.x)
        projectile.orbit_radius = 80.0
        projectile.speed = 2.1
        return
      end
      # Keep the reserved target instead of the generic nearest-target refresh.
      projectile.homing_refresh = dt.to_f + 1.0
    end
    projectile.homing_refresh = projectile.homing_refresh.to_f - dt.to_f
    target = projectile.homing_target
    psychic_dash = projectile.source_skill && projectile.source_skill[:kind] == :psychic_dash
    excluded = projectile.instance_variable_get(:@gen9_excluded_targets)
    target = nil if target && excluded && excluded.key?(target.object_id)
    if (!psychic_dash && projectile.homing_refresh <= 0) || !target || target.hp.to_i <= 0 || !enemy_visible?(target)
      if excluded
        target = nearest_psi_target(projectile.x, projectile.y, excluded)
      elsif psychic_dash
        target = nearest_psi_target(projectile.x, projectile.y, projectile.instance_variable_get(:@psi_hit_targets))
      else
        target = nearest_visible_enemy_from(projectile.x, projectile.y)
      end
      projectile.homing_target = target
      projectile.homing_refresh = 0.12
    end
    return if !target
    dx = target.x - projectile.x
    dy = target.y - projectile.y
    len = [Math.sqrt(dx * dx + dy * dy), 1].max
    turn = [dt * 8.0, 1.0].min
    projectile.vx = (projectile.vx * (1.0 - turn)) + ((dx / len) * turn)
    projectile.vy = (projectile.vy * (1.0 - turn)) + ((dy / len) * turn)
    norm = [Math.sqrt(projectile.vx * projectile.vx + projectile.vy * projectile.vy), 1].max
    projectile.vx /= norm
    projectile.vy /= norm
  rescue
  end
  def redirect_projectile_to_next_enemy(projectile, previous_enemy)
    if projectile.source_skill && projectile.source_skill[:kind] == :psychic_dash
      visited = projectile.instance_variable_get(:@psi_hit_targets) || {}
      visited[previous_enemy.object_id] = true
      projectile.instance_variable_set(:@psi_hit_targets, visited)
      target = nearest_psi_target(projectile.x, projectile.y, visited)
      return projectile.pierce = 0 if !target
      angle = Math.atan2(target.y - projectile.y, target.x - projectile.x)
      projectile.vx, projectile.vy = Math.cos(angle), Math.sin(angle)
      projectile.homing_target = target
      projectile.homing_refresh = 0.12
      projectile.ttl = [projectile.ttl, 0.55].max
      return
    end
    target = nil
    best_dist = nil
    candidates = nearby_enemies_for(projectile.x, projectile.y, 260)
    candidates = @enemies if candidates.empty?
    candidates.each do |e|
      next if !e || e.hp <= 0 || e == previous_enemy || !enemy_visible?(e)
      dist = point_distance_sq(projectile.x, projectile.y, e.x, e.y)
      if !best_dist || dist < best_dist
        target = e
        best_dist = dist
      end
    end
    return projectile.pierce = 0 if !target
    dx = target.x - projectile.x
    dy = target.y - projectile.y
    len = [Math.sqrt(dx * dx + dy * dy), 1].max
    projectile.vx = dx / len
    projectile.vy = dy / len
    projectile.ttl = [projectile.ttl, 0.55].max
  rescue
    projectile.pierce = 0
  end
  def source_skill_hash(source)
    return source.source_skill if source && source.respond_to?(:source_skill) && source.source_skill
    return source if source.respond_to?(:[])
    nil
  rescue
    nil
  end

  def starly_damage_multiplier(source)
    return 1.0 if @passive_key != :STARLY
    skill = source_skill_hash(source)
    return 1.0 if !skill || skill[:type] != :FLYING
    1.0 + [[@passive_starly_hit_bonus.to_f, 0.0].max, 0.30].min
  rescue
    1.0
  end

  def register_starly_hit(source)
    return if @passive_key != :STARLY
    skill = source_skill_hash(source)
    return if !skill || skill[:type] != :FLYING
    @passive_starly_hit_chain = [[@passive_starly_hit_chain.to_i + 1, 0].max, 30].min
    @passive_starly_hit_bonus = @passive_starly_hit_chain.to_i * 0.01
  rescue
  end

  def reset_starly_hit_chain
    return if @passive_key != :STARLY
    @passive_starly_hit_chain = 0
    @passive_starly_hit_bonus = 0.0
  rescue
  end

  def on_enemy_defeated_by_source(enemy, source)
    skill = source_skill_hash(source)
    skill_id = skill_id_for(skill) if skill
    if @passive_key == :SHINX && @ultimate_data
      @ultimate_charge = [@ultimate_charge.to_f + (@ultimate_data[:cooldown].to_f * 0.002), @ultimate_data[:cooldown].to_f].min
    elsif @passive_key == :GIBLE && @ultimate_data && skill_id == :dragon_pierce
      @ultimate_charge = [@ultimate_charge.to_f + (@ultimate_data[:cooldown].to_f * 0.001), @ultimate_data[:cooldown].to_f].min
    elsif !@breach_run && @passive_key == :CROAGUNK && skill && skill[:type] == :POISON && @hero && @hero.hp.to_i > 0
      heal = [(@hero.max_hp.to_f * 0.001).round, 1].max
      @hero.hp = [@hero.hp.to_i + heal, @hero.max_hp.to_i].min
    end
  rescue
  end
  def effective_attack_type_for_damage(attack_type, enemy, source = nil)
    skill = source.respond_to?(:source_skill) ? source.source_skill : source
    dual = skill.respond_to?(:[]) ? skill[:dual_types] : nil
    return attack_type if !dual || !enemy
    candidates = ([attack_type] + dual).compact.map { |t| t.to_sym rescue t }.uniq
    candidates.max_by { |type| PokemonSurvivor.type_multiplier(type, enemy.types) || 1.0 } || attack_type
  rescue
    attack_type
  end

  def rook_tornado_collision?(projectile, target)
    rook_tornado_hits_circle?(projectile, target.x, target.y, target.radius)
  end

  def rook_tornado_hits_circle?(projectile, x, y, radius)
    return false if projectile.radius <= 0.0
    rx = projectile.radius + radius
    motion = projectile.tornado_motion
    ry = projectile.radius * motion[:hit_height] + radius
    dx = (x - projectile.x) / rx
    dy = (y - projectile.y - motion[:hit_y]) / ry
    dx * dx + dy * dy <= 1.0
  end

  def damage_enemy(enemy, base_damage, attack_type, color = nil, source = nil)
    return if !enemy || enemy.hp <= 0
    if enemy.kind == :tower_wisp
      enemy.hp -= [base_damage.to_i, 1].max
      if @effects && @effects.length < PokemonSurvivor::MAX_EFFECTS
        @effects << [enemy.x, enemy.y, 0.14, Color.new(142, 210, 255), 18, :hit, nil]
      end
      defeat_enemy(enemy) if enemy.hp <= 0
      trigger_ember_impact(enemy, source)
      return
    end
    attack_type = effective_attack_type_for_damage(attack_type, enemy, source)
    type_mod = PokemonSurvivor.type_multiplier(attack_type, enemy.types)
    power_mult = @power_boost_timer.to_f > 0 ? 4.0 : 1.0
    power_mult *= passive_damage_multiplier
    power_mult *= gen9_passive_damage_multiplier(enemy, attack_type)
    power_mult *= 1.15 if @passive_key == :PSYDUCK && attack_type == :PSYCHIC
    power_mult *= 1.10 if @passive_key == :EEVEE && @hero && (@hero.types || []).include?(attack_type)
    if @equipped_item && @equipped_item[:effect] == :nohit_damage
      seconds = [[(@timer.to_f - @equipment_last_hit_time.to_f).floor, 0].max, @equipped_item[:value].to_i].min
      power_mult *= 1.0 + seconds / 100.0
    end
    if @passive_key == :CARVANHA && (attack_type == :DARK || attack_type == :WATER) && enemy.hp * 2 < enemy.max_hp
      power_mult *= 1.20
    end
    if @passive_key == :KUBFU && attack_type == :FIGHTING && point_distance_sq(@hero.x, @hero.y, enemy.x, enemy.y) <= 120.0 * 120.0
      power_mult *= 1.15
    end
    if @passive_key == :TOXEL && attack_type == :ELECTRIC && enemy.dot_type == :POISON && enemy.dot_timer.to_f > 0.0
      power_mult *= 1.20
    end
    if @passive_key == :IMPIDIMP && (attack_type == :DARK || attack_type == :FAIRY) &&
       point_distance_sq(@hero.x, @hero.y, enemy.x, enemy.y) <= 120.0 * 120.0
      power_mult *= 1.15
    end
    if @passive_key == :DREEPY && [:GHOST, :DRAGON].include?(attack_type) &&
       [:boss, :ultra_boss, :chest, :ultra_chest].include?(enemy.kind)
      power_mult *= 1.15
    end
    power_mult *= 1.10 if @passive_key == :ROOKIDEE && attack_type == :STEEL
    power_mult *= 1.25 if @passive_key == :SCORBUNNY && attack_type == :FIRE && @hero && @hero.hp * 3 <= @hero.max_hp
    power_mult *= @passive_hit_power_mult.to_f if @passive_hit_power_timer.to_f > 0
    boss_mult = enemy && (enemy.kind == :boss || enemy.kind == :ultra_boss) ? (@boss_damage_mult || 1.0) : 1.0
    if @passive_key == :MEWTWO && @treecko_barrage_timer.to_f > 0.0 && enemy && [:boss, :ultra_boss].include?(enemy.kind)
      boss_mult *= 1.5
    end
    element_mult = attack_type == @base_attack_type ? (@element_focus_mult || 1.0) : 1.0
    power_mult *= starly_damage_multiplier(source) if respond_to?(:starly_damage_multiplier)
    stab_mult = stab_damage_multiplier(attack_type)
    equip_type_mult = respond_to?(:equipment_type_damage_multiplier) ? equipment_type_damage_multiplier(attack_type) : 1.0
    damage = (base_damage.to_i * effective_run_damage_multiplier * boss_mult * element_mult * equip_type_mult * stab_mult * post_100_bonus_multiplier * power_mult * deoxys_attack_multiplier * aegislash_attack_multiplier * type_mod).ceil
    damage = 1 if damage < 1 && base_damage.to_i > 0 && type_mod > 0
    if magikarp_splash_instant_ko?(enemy, source) && damage > 0
      damage = enemy.hp.to_i
    end
    actual_damage = [damage, enemy.hp].min
    enemy.hp -= damage
    heal_from_gen9_attack(source, actual_damage)
    show_hit_effect(enemy, color || Color.white, source) if damage > 0
    register_starly_hit(source) if damage > 0 && respond_to?(:register_starly_hit)
    hit_se = type_mod > 1.0 ? "Survivor/Battle damage super" : (type_mod < 1.0 ? "Survivor/Battle damage weak" : "Survivor/Battle damage normal")
    play_survivor_se(:enemy_hit, hit_se, 0.055, PokemonSurvivor::SFX_HIT_VOLUME, 110) if damage > 0
    if enemy.hp <= 0
      on_enemy_defeated_by_source(enemy, source) if respond_to?(:on_enemy_defeated_by_source)
      trigger_equipment_enemy_defeated(enemy, source) if respond_to?(:trigger_equipment_enemy_defeated)
      try_vampiric_projectile_heal(source) if damage > 0
      try_grass_life_drain(source)
      defeat_enemy(enemy)
      trigger_ember_impact(enemy, source)
      return
    end
    try_vampiric_projectile_heal(source) if damage > 0
    apply_attack_extra_effect(enemy, source)
    trigger_ember_impact(enemy, source)
  end

  def gen9_passive_damage_multiplier(enemy, type)
    case @passive_key
    when :CELEBI
      return 1.15 if [:PSYCHIC, :GRASS].include?(type)
    when :VICTINI
      return 1.2 if [:FIRE, :PSYCHIC].include?(type) && enemy.dot_type == :FIRE && enemy.dot_timer.to_f > 0
    when :CUBONE
      return 1.15 if [:GROUND, :FIRE].include?(type)
    when :MAWILE
      return 1.2 if type == :STEEL && enemy.freeze_timer.to_f > 0
    when :TYNAMO
      return 1.15 if type == :ELECTRIC
    when :SKRELP
      return 1.15 if [:POISON, :DRAGON].include?(type)
    when :ENTEI
      return 1.2 if type == :FIRE && enemy.dot_type == :FIRE && enemy.dot_timer.to_f > 0
    when :RAIKOU
      return 1.2 if type == :ELECTRIC && enemy.freeze_timer.to_f > 0
    when :SPRIGATITO
      return 1.2 if type == :GRASS && @hero.hp * 4 > @hero.max_hp * 3
    when :FUECOCO
      return 1.25 if type == :FIRE && enemy.dot_type == :FIRE && enemy.dot_timer.to_f > 0
    when :PAWMI
      return 1.2 if type == :FIGHTING && enemy.freeze_timer.to_f > 0
    when :CHARCADET
      return 1.15 if [:FIRE, :PSYCHIC, :GHOST].include?(type) && point_distance_sq(@hero.x, @hero.y, enemy.x, enemy.y) <= 14400
    when :FRIGIBAX
      return 1.2 if type == :ICE && enemy.slow_timer.to_f > 0
    when :TINKATINK
      return 1.15 if [:STEEL, :FAIRY].include?(type) && [:boss, :ultra_boss, :chest, :ultra_chest].include?(enemy.kind)
    when :GIMMIGHOUL
      return 1.25 if type == :STEEL && enemy.freeze_timer.to_f > 0
    end
    1.0
  end

  def heal_from_gen9_attack(source, damage)
    return if @breach_run || (respond_to?(:titan_mode?) && titan_mode?)
    return if !@hero || @hero.hp <= 0 || damage <= 0
    skill = source.respond_to?(:source_skill) ? source.source_skill : source
    return unless skill.is_a?(Hash)
    rate = skill[:life_steal].to_f
    rate = 0.0625 if @ceruledge_burst_timer.to_f > 0 && skill_id_for(skill) == @hero_skill
    return if rate <= 0
    @hero.hp = [@hero.hp + (damage * rate).floor, @hero.max_hp].min
  end

  def show_hit_effect(enemy, color, source = nil)
    return if PokemonSurvivor.performance_option?(:reduced_vfx)
    return if !@effects || @effects.length >= PokemonSurvivor::MAX_EFFECTS
    return if !allow_hit_effect?
    return if !point_on_screen?(enemy.x, enemy.y, 48)
    if high_volume_hit_source?(source)
      now = System.uptime rescue (@timer || 0.0)
      return if now < @next_high_volume_hit_vfx.to_f
      @next_high_volume_hit_vfx = now + 0.035
    end
    @effects << [enemy.x, enemy.y, 0.16, color || Color.white, 16, :hit, source]
  rescue
  end

  def high_volume_hit_source?(source)
    skill = source
    skill = source.source_skill if source && source.respond_to?(:source_skill) && source.source_skill
    return false if !skill || !skill.is_a?(Hash)
    [:radial, :nova, :thunder_ring_burst, :bubble_tide].include?(skill[:kind]) || skill[:count].to_i >= 8
  rescue
    false
  end

  def allow_hit_effect?
    return true if !@enemies || @enemies.length < 120
    @hit_effect_skip = (@hit_effect_skip.to_i + 1) % 3
    @hit_effect_skip == 0
  rescue
    true
  end

  def try_vampiric_projectile_heal(source)
    return if @breach_run
    chance = @vampiric_chance.to_f
    return if chance <= 0 || !@hero || @hero.hp.to_i <= 0
    return if !source || !source.respond_to?(:owner) || source.owner != :player
    return if @hero.hp.to_i >= @hero.max_hp.to_i
    return if rand >= chance

    heal_rate = [[@vampiric_heal_rate.to_f, 0.001].max, 0.005].min
    heal = [(@hero.max_hp.to_f * heal_rate).round, 1].max
    @hero.hp = [@hero.hp.to_i + heal, @hero.max_hp.to_i].min
  rescue
  end

  def passive_damage_multiplier
    return 1.0 if @passive_low_hp_damage_mult.to_f <= 1.0 || @passive_low_hp_threshold.to_f <= 0
    return 1.0 if !@hero || @hero.max_hp.to_i <= 0
    rate = @hero.hp.to_f / @hero.max_hp.to_f
    rate <= @passive_low_hp_threshold.to_f ? @passive_low_hp_damage_mult.to_f : 1.0
  rescue
    1.0
  end

  def stab_damage_multiplier(attack_type)
    return 1.0 if !attack_type || !@hero
    return PokemonSurvivor::STAB_DAMAGE_MULTIPLIER if @passive_key == :FEEBAS && attack_type == :FAIRY
    types = @hero.types || []
    types.include?(attack_type) ? PokemonSurvivor::STAB_DAMAGE_MULTIPLIER : 1.0
  rescue
    1.0
  end


  def magikarp_splash_instant_ko?(enemy, source)
    return false if !enemy || !source
    skill = source.respond_to?(:source_skill) && source.source_skill ? source.source_skill : source
    return false if !skill.respond_to?(:[]) || !skill[:instant_ko_normal]
    ![:boss, :ultra_boss, :chest, :ultra_chest, :event_egg, :event_sleep, :event_baby].include?(enemy.kind)
  rescue
    false
  end
  def apply_attack_extra_effect(enemy, source)
    return if !source
    skill = source.respond_to?(:source_skill) && source.source_skill ? source.source_skill : source
    return if !skill.respond_to?(:[])
    skill_id = skill_id_for(skill)
    if skill[:freeze]
      freeze_time = (skill[:freeze].to_f + (@skill_freeze_bonus ||= Hash.new(0.0))[skill_id].to_f) * (@status_duration_mult || 1.0)
      freeze_time *= (@equipment_control_duration_mult || 1.0)
      apply_enemy_status_once(enemy, skill[:freeze_status] || :freeze) do
        enemy.freeze_timer = [enemy.freeze_timer.to_f, freeze_time].max
      end
    end
    if skill[:slow]
      apply_enemy_status_once(enemy, :slow) do
        slow_time = skill[:slow].to_f * (@status_duration_mult || 1.0)
        slow_time *= (@equipment_control_duration_mult || 1.0)
        enemy.slow_timer = [enemy.slow_timer.to_f, slow_time].max
        enemy.slow_mult = skill[:slow_mult] ? skill[:slow_mult].to_f : 0.45
      end
    end
    if skill[:dot]
      apply_enemy_status_once(enemy, :dot) do
        dot_time = (skill[:dot].to_f + (@passive_poison_dot_bonus.to_f if skill[:type] == :POISON).to_f) * (@status_duration_mult || 1.0)
        enemy.dot_timer = [enemy.dot_timer.to_f, dot_time].max
        enemy.dot_tick_timer = 0.01 if enemy.dot_tick_timer.to_f <= 0
        dot_bonus = (@skill_dot_damage_bonus ||= Hash.new(0))[skill_id].to_i
        dot_damage = [(skill[:damage].to_i / 2) + dot_bonus, 1].max
        dot_damage = (dot_damage * stab_damage_multiplier(skill[:type])).ceil
        dot_damage = (dot_damage * (@equipment_dot_mult || 1.0)).ceil if [:FIRE, :POISON].include?(skill[:type])
        enemy.dot_damage = [dot_damage, enemy.dot_damage.to_i].max
        enemy.dot_type = skill[:type]
        enemy.dot_source = skill
      end
    end
    base_knock = skill[:knockback].to_i
    return if base_knock <= 0
    knock = base_knock + (@skill_knockback_bonus ||= Hash.new(0))[skill_id].to_i
    knock_limit = skill[:knock_limit] ? skill[:knock_limit].to_i : ((skill[:type] == :STEEL) ? 10 : 1)
    unless skill[:unlimited_knockback]
      return if enemy.knockback_count.to_i >= knock_limit
      enemy.knockback_count = enemy.knockback_count.to_i + 1
    end
    dx = enemy.x - @hero.x
    dy = enemy.y - @hero.y
    len = [Math.sqrt(dx * dx + dy * dy), 1].max
    enemy.x, enemy.y = clamp_world_spawn_position(
      enemy.x + dx / len * knock, enemy.y + dy / len * knock, enemy.radius)
  rescue
  end

  def apply_enemy_status_once(enemy, status_key)
    enemy.status_locks ||= {}
    return false if enemy.status_locks[status_key]
    enemy.status_locks[status_key] = true
    yield if block_given?
    true
  rescue
    false
  end

  def try_grass_life_drain(source)
    return if @breach_run
    skill = source.respond_to?(:source_skill) && source.source_skill ? source.source_skill : source
    return if !skill.respond_to?(:[]) || skill[:type] != :GRASS
    skill_id = skill_id_for(skill)
    bonus = @upgrade_levels[:"#{skill_id}_power"].to_i + @upgrade_levels[:"#{skill_id}_tempo"].to_i
    chance = [[20 - (bonus * 2), 4].max, 20].min
    return if rand(chance) != 0
    heal = [(@hero.max_hp * 0.08).round, 6].max
    @hero.hp = [@hero.hp + heal, @hero.max_hp].min
  rescue
  end

  def defeat_enemy(enemy)
    if enemy && enemy.kind == :tower_wisp
      enemy.defeated = true
      cleanup_destroyed_tower_wisps
      return
    end
    return if !enemy || enemy.instance_variable_get(:@defeated)
    enemy.instance_variable_set(:@defeated, true)
    enemy.defeated = true if enemy.respond_to?(:defeated=)
    enemy.hp = 0
    @kills += 1
    @score += enemy.value.to_i
    apply_passive_burst_on_kill
    boss_kind = (enemy.kind == :boss || enemy.kind == :ultra_boss)
    chest_kind = (enemy.kind == :chest || enemy.kind == :ultra_chest)
    @ultra_boss_defeated = true if enemy.kind == :ultra_boss && !arena_mode?
    play_enemy_ko_cry(enemy) if respond_to?(:play_enemy_ko_cry)
    play_survivor_se(boss_kind ? :boss_ko : :enemy_ko, "Survivor/Pkmn faint", boss_kind ? 0.05 : 0.24, boss_kind ? PokemonSurvivor::SFX_BOSS_KO_VOLUME : PokemonSurvivor::SFX_KO_VOLUME, boss_kind ? 86 : 126)
    PokemonSurvivor.gamepad_vibrate_event(enemy.kind == :ultra_boss ? :ultra_boss_ko : :boss_ko) if boss_kind && PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
    spawn_boss_reward_item(enemy.x, enemy.y, enemy.kind == :ultra_chest ? 3 : 1) if (boss_kind || chest_kind) && !arena_mode?
    try_spawn_wild_moves_item(enemy) if enemy.kind == :wild
    on_rush_boss_defeated(enemy) if rush_mode? && boss_kind
    on_tower_boss_defeated(enemy) if tower_mode? && boss_kind
    return if tower_mode? && boss_kind
    return if respond_to?(:breach_enemy_shard_drops_expired?) && breach_enemy_shard_drops_expired?
    gem = PokemonSurvivorEntity.new(:xp, "XP", enemy.x, enemy.y)
    gem.value = enemy.value
    gem.radius = PokemonSurvivor::XP_RADIUS
    gem.age = 0.0
    @xp_gems << gem
    compact_xp_gems if @xp_gems.length > xp_gem_limit
  end

  def apply_passive_burst_on_kill
    return if @passive_burst_on_kill.to_f <= 0 || !@ultimate_data
    cooldown = [@ultimate_data[:cooldown].to_f, 1.0].max
    @ultimate_charge = [[@ultimate_charge.to_f + (cooldown * @passive_burst_on_kill.to_f), 0.0].max, cooldown].min
  rescue
  end
  def try_spawn_wild_moves_item(enemy)
    return if !enemy || enemy.hp.to_i > 0
    return if !rush_mode? && !tower_mode?
    return if !respond_to?(:can_drop_moves_item?) || !can_drop_moves_item?
    if rand < wild_moves_drop_chance
      @wild_moves_drop_pity = 0
      spawn_moves_item(enemy.x, enemy.y)
    else
      @wild_moves_drop_pity = @wild_moves_drop_pity.to_i + 1
    end
  rescue
  end

  def wild_moves_drop_chance
    missing = respond_to?(:skill_slots_remaining) ? skill_slots_remaining(true).to_i : 0
    base = missing >= 2 ? 0.012 : 0.008
    chance = base + (@wild_moves_drop_pity.to_i * 0.00035)
    [[chance, 0.0].max, 1.0].min
  rescue
    0.01
  end
  def spawn_boss_reward_item(x, y, upgrade_count = 1)
    can_offer_move = respond_to?(:can_drop_moves_item?) && can_drop_moves_item?
    if can_offer_move && rand < moves_drop_chance
      @moves_drop_pity = 0
      spawn_moves_item(x, y)
    else
      @moves_drop_pity = @moves_drop_pity.to_i + 1 if can_offer_move
      spawn_boss_chest(x, y, upgrade_count)
    end
  rescue
    spawn_boss_chest(x, y, upgrade_count) rescue nil
  end

  def moves_drop_chance
    missing = respond_to?(:skill_slots_remaining) ? skill_slots_remaining(true).to_i : 0
    base = 0.25 + ([[missing, 0].max, 2].min * 0.05)
    pity = [@moves_drop_pity.to_i * 0.15, 0.40].min
    [[base + pity, 0.25].max, 0.75].min
  rescue
    0.30
  end

  def spawn_boss_chest(x, y, upgrade_count = 1)
    if respond_to?(:world_walls_enabled?) && world_walls_enabled?
      pos = clamp_world_spawn_position(x, y, PokemonSurvivor::ITEM_RADIUS + 8)
      x = pos[0]
      y = pos[1]
    end
    item = PokemonSurvivorEntity.new(:item, "CHESTBOSS", x, y)
    item.radius = PokemonSurvivor::ITEM_RADIUS
    item.bitmap = cached_bitmap(PokemonSurvivor::ITEM_DIR, "CHESTBOSS")
    item.color = Color.new(255, 224, 92)
    item.value = [[upgrade_count.to_i, 1].max, 3].min
    item.ttl = PokemonSurvivor.const_defined?(:WILD_ITEM_LIFETIME) ? PokemonSurvivor::WILD_ITEM_LIFETIME : 12.0
    @items << item
  rescue
  end

  def spawn_moves_item(x, y)
    return if !respond_to?(:can_drop_moves_item?) || !can_drop_moves_item?
    if respond_to?(:world_walls_enabled?) && world_walls_enabled?
      pos = clamp_world_spawn_position(x, y, PokemonSurvivor::ITEM_RADIUS + 8)
      x = pos[0]
      y = pos[1]
    end
    item = PokemonSurvivorEntity.new(:item, "MOVES", x, y)
    item.radius = PokemonSurvivor::ITEM_RADIUS
    item.bitmap = cached_bitmap(PokemonSurvivor::ITEM_DIR, "MOVES")
    item.color = Color.new(132, 188, 255)
    item.value = 1
    item.ttl = 0
    @items << item
  rescue
  end
  def cleanup_active_entities
    margin = PokemonSurvivor::ENEMY_CULL_MARGIN
    prune_doom_enemies
    @enemies.delete_if do |e|
      next false if e.kind == :boss || e.kind == :chest || e.kind == :ultra_boss || e.kind == :ultra_chest
      e.hp <= 0 || !point_on_screen?(e.x, e.y, margin)
    end
    trim_projectiles_to_limit
    @effects.shift(@effects.length - PokemonSurvivor::MAX_EFFECTS) if @effects.length > PokemonSurvivor::MAX_EFFECTS
    compact_xp_gems if @xp_gems.length > xp_gem_limit
  rescue
  end

  def trim_projectiles_to_limit
    overflow = @projectiles.length - PokemonSurvivor::MAX_PROJECTILES
    return if overflow <= 0
    @projectiles.delete_if do |p|
      break false if overflow <= 0
      next false if dragon_chain_projectile?(p)
      overflow -= 1
      true
    end
    overflow = @projectiles.length - PokemonSurvivor::MAX_PROJECTILES
    @projectiles.shift(overflow) if overflow > 0
  rescue
  end

  def farthest_entities_from(list, x, y, count)
    limit = [count.to_i, 0].max
    return [] if limit <= 0
    best = []
    list.each do |entity|
      next if !entity
      dist = point_distance_sq(entity.x, entity.y, x, y)
      insert_at = best.length
      best.each_with_index do |pair, i|
        if dist > pair[0]
          insert_at = i
          break
        end
      end
      best.insert(insert_at, [dist, entity])
      best.pop while best.length > limit
    end
    best.map { |pair| pair[1] }
  rescue
    []
  end

  def prune_doom_enemies
    now = System.uptime rescue (@timer || 0.0)
    return if now < @next_doom_prune_time.to_f
    @next_doom_prune_time = now + 0.35
    doom = []
    (@enemies || []).each { |e| doom << e if e && PokemonSurvivor.doom_enemy?(e.name) }
    overflow = doom.length - PokemonSurvivor::MAX_DOOM_ENEMIES
    return if overflow <= 0
    center_x = @hero ? @hero.x : Graphics.width / 2
    center_y = @hero ? @hero.y : Graphics.height / 2
    farthest_entities_from(doom, center_x, center_y, overflow).each { |e| e.hp = 0 }
  rescue
  end

  def xp_gem_limit
    return PokemonSurvivor::MAX_XP_GEMS if rush_mode?
    seconds = @timer.to_i
    return PokemonSurvivor::MAX_XP_GEMS if seconds < 600
    return 140 if seconds < 780
    120
  rescue
    PokemonSurvivor::MAX_XP_GEMS
  end

  def compact_xp_gems
    @xp_gems.delete_if { |gem| xp_drop_expired?(gem) }
    overflow = @xp_gems.length - xp_gem_limit
    return if overflow <= 0
    center_x = @hero ? @hero.x : Graphics.width / 2
    center_y = @hero ? @hero.y : Graphics.height / 2
    removed_value = 0
    farthest_entities_from(@xp_gems, center_x, center_y, overflow).each do |g|
      removed_value += g.value.to_i
      g.value = 0
    end
    @xp_gems.delete_if { |g| g.value.to_i <= 0 }
    target = @xp_gems.min_by { |g| point_distance_sq(g.x, g.y, center_x, center_y) }
    if target
      target.value += removed_value
    else
      gem = PokemonSurvivorEntity.new(:xp, "XP", center_x, center_y)
      gem.value = removed_value
      gem.radius = PokemonSurvivor::XP_RADIUS
      gem.age = 0.0
      @xp_gems << gem
    end
  rescue
  end

  def xp_drop_expired?(gem)
    return false if respond_to?(:breach_mode?) && breach_mode?
    gem.age.to_f >= PokemonSurvivor::XP_DROP_LIFETIME
  end

  def update_xp(dt)
    range = @force_magnet_timer.to_f > 0 ? 9999 : 42 * @pickup_mult
    range_sq = range * range
    hx = @hero.x
    hy = @hero.y
    @xp_gems.each do |gem|
      gem.age = gem.age.to_f + dt.to_f
      if xp_drop_expired?(gem)
        gem.value = 0
        next
      end
      next if gem.age.to_f < 0.16
      dx = hx - gem.x
      dy = hy - gem.y
      dist_sq = (dx * dx) + (dy * dy)
      if dist_sq < range_sq
        len = [Math.sqrt(dist_sq), 1].max
        gem.x += dx / len * 4.8 * 60.0 * dt
        gem.y += dy / len * 4.8 * 60.0 * dt
        dx = hx - gem.x
        dy = hy - gem.y
        dist_sq = (dx * dx) + (dy * dy)
      end
      pickup = @hero.radius + gem.radius
      if dist_sq < pickup * pickup
        gain_direct_xp(gem.value)
        play_survivor_se(:xp_pickup, "Survivor/Item get", 0.055, PokemonSurvivor::SFX_XP_VOLUME, 132)
        gem.value = 0
      end
    end
    @xp_gems.delete_if { |g| g.value.to_i <= 0 }
  end

  def survivor_xp_next_for_level(level)
    current_level = [level.to_i, 1].max
    value = (12 + (current_level * 7) + (current_level * current_level / 2)).to_i
    standard_shop = [:classic, :rush, :tower].include?(@run_mode) && !(respond_to?(:breach_mode?) && breach_mode?)
    reduction = standard_shop ? PokemonSurvivor.shop_effect_value(:early_level_xp_percent).to_i : 0
    value = (value * (100 - reduction) / 100.0).round if reduction > 0 && current_level < 10
    [value, 1].max
  rescue
    (12 + (level.to_i * 7) + (level.to_i * level.to_i / 2)).to_i
  end
  def gain_direct_xp(amount)
    @xp += [amount.to_i, 0].max
    while @xp >= @xp_next
      @xp -= @xp_next
      @level += 1
      @xp_next = survivor_xp_next_for_level(@level)
      apply_passive_level_bonus
      check_hero_evolution
      trigger_level_up_burst
      request_upgrade(0.48)
      break
    end
  rescue
  end

  def apply_passive_level_bonus
    if !rush_mode? && @level.to_i > 100 && @hero && @hero.hp.to_i > 0
      heal = [(@hero.max_hp * 0.01).round, 1].max
      @hero.hp = [@hero.hp.to_i + heal, @hero.max_hp].min
      trigger_gauge_flash(0.45)
      set_hero_item_flash(Color.new(122, 255, 176), 0.45)
    end
    if @passive_level_heal_rate.to_f > 0 && @hero && @hero.hp.to_i > 0
      heal = [(@hero.max_hp * @passive_level_heal_rate.to_f).round, 1].max
      @hero.hp = [@hero.hp.to_i + heal, @hero.max_hp].min
      trigger_gauge_flash(0.45)
      set_hero_item_flash(Color.new(92, 188, 255), 0.45)
    end
    if @passive_key == :MEW && (@level.to_i % 3) == 0
      @force_magnet_timer = [@force_magnet_timer.to_f, 2.5].max
      set_hero_item_flash(Color.new(255, 116, 208), 0.65)
    end
  rescue
  end

  def trigger_level_up_burst
    @level_flash_timer = 0.55
    trigger_gauge_flash(0.55)
    repel_nearby_threats(150, 78, true)
    @effects << [@hero.x, @hero.y, 0.42, Color.new(255, 238, 160), 150, :level_burst, nil, nil, 0.0]
    @effects.shift(@effects.length - PokemonSurvivor::MAX_EFFECTS) if @effects.length > PokemonSurvivor::MAX_EFFECTS
    set_hero_item_flash(Color.new(255, 238, 160), 0.55)
    play_survivor_se(:level_up, "Survivor/Pkmn level up", 0.4, PokemonSurvivor::SFX_LEVEL_VOLUME, 100)
    PokemonSurvivor.gamepad_vibrate_event(:level_up) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
  rescue
  end

  def check_hero_evolution
    return if !@hero
    return if @evolution_anim
    @hero_power_stage ||= 0
    if PokemonSurvivor.species_key(@hero_base_name) == :CHARCADET &&
       PokemonSurvivor.species_key(@hero.name) == :CHARCADET && @hero_power_stage >= 1 && charcadet_evolution_form
      queue_hero_evolution_stage(@hero_power_stage)
      return
    end
    if PokemonSurvivor.species_key(@hero_base_name) == :KUBFU &&
       PokemonSurvivor.species_key(@hero.name) == :KUBFU && @hero_power_stage >= 1 && kubfu_evolution_form
      queue_hero_evolution_stage(@hero_power_stage)
      return
    end
    levels = PokemonSurvivor.hero_evolution_levels(@hero_base_name || @hero.name)
    return if !levels
    first_level = levels[0].to_i
    second_level = levels[1].to_i
    if first_level > 0 && @level.to_i >= first_level && @hero_power_stage < 1
      queue_hero_evolution_stage(1) if evolution_skill_gate_open?(1)
    elsif second_level > 0 && @level.to_i >= second_level && @hero_power_stage < 2
      queue_hero_evolution_stage(2) if evolution_skill_gate_open?(2)
    end
  end

  def evolution_skill_gate_open?(stage)
    base = PokemonSurvivor.species_key(@hero_base_name || (@hero && @hero.name))
    return true if [:MAGIKARP, :FEEBAS].include?(base)
    return true if base == :ABRA && stage.to_i == 1
    learned = (@learned_skills || []).length
    required = stage.to_i >= 2 ? 3 : 2
    learned >= required
  rescue
    true
  end

  def queue_hero_evolution_stage(stage)
    @pending_evolution_stage = [@pending_evolution_stage.to_i, stage.to_i].max
  rescue
  end

  def learned_skill_type?(type)
    wanted = type.to_sym rescue type
    (@learned_skills || []).any? do |skill_id|
      skill = PokemonSurvivor::SKILLS[skill_id]
      skill && skill[:type] == wanted
    end
  rescue
    false
  end

  def kubfu_evolution_form(choose = false)
    water = learned_skill_type?(:WATER)
    dark = learned_skill_type?(:DARK)
    # Eligibility checks must not consume the evolution's random draw.
    return choose ? (rand(2) == 0 ? "URSHIFU" : "URSHIFU_1") : "KUBFU" if water && dark
    return "URSHIFU_1" if water
    return "URSHIFU" if dark
    nil
  end

  def charcadet_evolution_form(choose = false)
    psychic = learned_skill_type?(:PSYCHIC)
    ghost = learned_skill_type?(:GHOST)
    # Checking eligibility must not reroll the form selected for the animation.
    return choose ? (rand(2) == 0 ? "ARMAROUGE" : "CERULEDGE") : "CHARCADET" if psychic && ghost
    return "ARMAROUGE" if psychic
    return "CERULEDGE" if ghost
    nil
  end

  def special_evolution_name(stage, default_name)
    base = PokemonSurvivor.species_key(@hero_base_name || (@hero && @hero.name))
    current = PokemonSurvivor.species_key(@hero && @hero.name)
    return "MIMIKYU_1" if base == :MIMIKYU && @mimikyu_disguise_broken
    case base
    when :CUBONE
      return current.to_s if [:MAROWAK, :MAROWAK_1].include?(current)
      return (learned_skill_type?(:FIRE) || learned_skill_type?(:GHOST)) ? "MAROWAK_1" : "MAROWAK" if stage.to_i >= 1
    when :CHARCADET
      return current.to_s if [:ARMAROUGE, :CERULEDGE].include?(current)
      return charcadet_evolution_form(true) || "CHARCADET"
    when :TOXEL
      return current.to_s if [:TOXTRICITY, :TOXTRICITY_1].include?(current)
      return rand(2) == 0 ? "TOXTRICITY" : "TOXTRICITY_1" if stage.to_i >= 1
    when :EEVEE
      return current.to_s if PokemonSurvivor::EEVEE_STONE_FORMS.value?(current)
      stone = @equipped_item && @equipped_item[:id]
      return (PokemonSurvivor::EEVEE_STONE_FORMS[stone] || :EEVEE).to_s
    when :KUBFU
      return current.to_s if [:URSHIFU, :URSHIFU_1].include?(current)
      return kubfu_evolution_form(true) || "KUBFU"
    when :APPLIN
      if stage.to_i == 1
        second = PokemonSurvivor::SKILLS[(@learned_skills || [])[1]]
        return "FLAPPLE" if second && second[:type] == :FLYING
        return "DIPPLIN" if second && second[:type] == :DRAGON
        return "APPLETUN"
      elsif stage.to_i >= 2
        return "HYDRAPPLE" if [:DIPPLIN, :HYDRAPPLE].include?(current)
        return current.to_s if [:FLAPPLE, :APPLETUN].include?(current)
      end
    when :GOOMY
      if stage.to_i == 1
        @goomy_steel_route = learned_skill_type?(:STEEL)
        return @goomy_steel_route ? "SLIGGOO_1" : "SLIGGOO"
      elsif stage.to_i >= 2
        route = @goomy_steel_route.nil? ? (current == :SLIGGOO_1) : @goomy_steel_route
        return route ? "GOODRA_1" : "GOODRA"
      end
    when :CYNDAQUIL
      return "TYPHLOSION_1" if stage.to_i >= 2 && current == :QUILAVA && learned_skill_type?(:GHOST)
    when :ROWLET
      return "DECIDUEYE_1" if stage.to_i >= 2 && current == :DARTRIX && learned_skill_type?(:FIGHTING)
    when :RALTS
      return "GALLADE" if stage.to_i >= 2 && current == :KIRLIA && learned_skill_type?(:FIGHTING)
    when :PICHU
      return "RAICHU_1" if stage.to_i >= 2 && current == :PIKACHU && learned_skill_type?(:PSYCHIC)
    end
    default_name
  rescue
    default_name
  end

  def special_final_evolution_name(stage, default_name)
    special_evolution_name(stage, default_name)
  rescue
    default_name
  end
  def start_pending_hero_evolution
    stage = @pending_evolution_stage.to_i
    return if stage <= 0 || !@hero
    @pending_evolution_stage = nil
    new_name = PokemonSurvivor.hero_evolution_name(@hero_base_name || @hero.name, stage)
    new_name = special_evolution_name(stage, new_name)
    return apply_hero_growth_stage(stage) if !new_name
    new_name = @hero.name if PokemonSurvivor.species_key(@hero_base_name) == :DEOXYS
    boost_only = new_name.to_s == @hero.name.to_s
    @evolution_anim = {
      stage: stage,
      old_name: @hero.name,
      old_bitmap: @hero.bitmap,
      new_name: new_name,
      new_bitmap: cached_bitmap(PokemonSurvivor::HERO_DIR, new_name),
      elapsed: 0.0,
      vfx_name: boost_only ? "VFX_BOOST" : "VFX_EVOLUTION"
    }
    @hero.moving = false
    @invuln = [@invuln.to_f, 16.0 / 60.0].max
    repel_nearby_threats(170, 10.0, true)
    pbSEPlay("Survivor/Battle recall", PokemonSurvivor::SFX_EVOLUTION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    play_survivor_se(:evolution_vfx, "Survivor/Shiny sparkle", 0.5, PokemonSurvivor::SFX_EVOLUTION_VFX_VOLUME, 92)
  rescue
    apply_hero_growth_stage(stage, [:KUBFU, :TOXEL, :CHARCADET].include?(PokemonSurvivor.species_key(@hero_base_name)) ? new_name : nil) rescue nil
  end

  def update_hero_evolution_animation(dt)
    return if !@evolution_anim
    @evolution_anim[:elapsed] = @evolution_anim[:elapsed].to_f + dt
    repel_nearby_threats(178, 11.5, true)
    if @evolution_anim[:elapsed] >= (16.0 / 60.0)
      anim = @evolution_anim
      stage = anim[:stage].to_i
      @evolution_anim = nil
      if anim[:transform_only]
        apply_deoxys_form(anim[:new_name])
      else
        chosen_name = [:KUBFU, :TOXEL, :CHARCADET].include?(PokemonSurvivor.species_key(@hero_base_name)) ? anim[:new_name] : nil
        apply_hero_growth_stage(stage, chosen_name)
      end
    end
  rescue
    @evolution_anim = nil
  end

  def repel_nearby_threats(radius, force, include_projectiles = false)
    repel_entities_from_hero(@enemies, radius, force)
    repel_entities_from_hero((@projectiles || []).select { |p| p.owner == :enemy }, radius, force * 1.35, false) if include_projectiles
  rescue
  end

  def repel_entities_from_hero(list, radius, force, constrain_to_map = true)
    return if !@hero || !list
    moved = false
    list.each do |entity|
      next if !entity || (entity.respond_to?(:hp) && entity.hp.to_i <= 0)
      next if constrain_to_map && entity.kind == :tower_wisp
      dx = entity.x - @hero.x
      dy = entity.y - @hero.y
      dist = Math.sqrt(dx * dx + dy * dy)
      next if dist <= 0 || dist > radius
      power = force.to_f * (1.0 - (dist / radius.to_f))
      x = entity.x + dx / dist * power
      y = entity.y + dy / dist * power
      x, y = clamp_world_spawn_position(x, y, entity.radius) if constrain_to_map
      entity.x, entity.y = x, y
      moved = true
      if entity.respond_to?(:vx) && entity.respond_to?(:vy)
        entity.vx += dx / dist * power * 0.02
        entity.vy += dy / dist * power * 0.02
      end
    end
    invalidate_enemy_grid if moved && constrain_to_map
  rescue
  end

  def apply_hero_growth_stage(stage, chosen_name = nil)
    kubfu_form_only = [:KUBFU, :CHARCADET].include?(PokemonSurvivor.species_key(@hero_base_name)) && stage.to_i <= @hero_power_stage.to_i
    @hero_power_stage = stage
    factor = (stage.to_i >= 2) ? 2.0 : 1.5
    new_name = PokemonSurvivor.hero_evolution_name(@hero_base_name || @hero.name, stage)
    new_name = chosen_name || special_evolution_name(stage, new_name)
    new_name = @hero.name if PokemonSurvivor.species_key(@hero_base_name) == :DEOXYS
    old_name = @hero.name
    evolved = new_name && new_name.to_s != old_name.to_s
    if evolved
      setup_hero_sprite_set(new_name)
      @hero.types = PokemonSurvivor.species_types(new_name)
      @upgrades_exhausted = false if PokemonSurvivor.species_key(@hero_base_name) == :ABRA
      replace_eevee_main_skill(new_name) if PokemonSurvivor.species_key(@hero_base_name) == :EEVEE
      replace_charcadet_main_skill(new_name) if PokemonSurvivor.species_key(@hero_base_name) == :CHARCADET
      replace_charcadet_main_skill(new_name) if PokemonSurvivor.species_key(@hero_base_name) == :CUBONE && new_name.to_s == "MAROWAK_1"
      if defined?(PokemonSurvivorAchievements) && PokemonSurvivorAchievements.respond_to?(:record_alternate_evolution)
        PokemonSurvivorAchievements.record_alternate_evolution(old_name, new_name, true) rescue nil
      end
    end
    cry_name = evolved ? new_name : (@hero.name || new_name || @hero_base_name)
    play_survivor_cry(cry_name, 76, 100) if respond_to?(:play_survivor_cry)
    return if kubfu_form_only
    @final_evolution_times[PokemonSurvivor.species_key(@hero_base_name)] = @timer.to_f if stage.to_i >= 2 && @final_evolution_times
    old_max = @hero.max_hp.to_i
    @hero.max_hp = [(@hero.max_hp.to_i * factor).round, old_max + 1].max
    @hero.hp = [@hero.hp.to_i + (@hero.max_hp - old_max), @hero.max_hp].min
    trigger_gauge_flash
    @hero.speed *= factor if stage.to_i < 2
    @damage_mult *= factor
    @hero_color = PokemonSurvivor.hero_data(new_name || @hero.name)[:color] rescue @hero_color
    replace_splash_after_evolution(stage, evolved, new_name) if splash_should_transform_after_evolution?(stage, evolved, new_name)
    if evolved && [:MAGIKARP, :FEEBAS].include?(PokemonSurvivor.species_key(@hero_base_name))
      @ultimate_data = PokemonSurvivor.ultimate_data(new_name) || @ultimate_data
      @ultimate_charge = [@ultimate_charge.to_f, @ultimate_data[:cooldown].to_f].min if @ultimate_data
    end
  end


def replace_charcadet_main_skill(name)
  form = PokemonSurvivor.species_key(name)
  return unless [:ARMAROUGE, :CERULEDGE, :MAROWAK_1].include?(form)
  replacement = PokemonSurvivor::HERO_BASE[form][:skill]
  old = @hero_skill
  return if old == replacement
  transfer_splash_upgrades(old, replacement)
  @learned_skills.map! { |id| id == old ? replacement : id }
  @learned_skills.uniq!
  @hero_skill = replacement
  @base_attack_type = PokemonSurvivor::SKILLS[replacement][:type]
  @hero.attack_type = @base_attack_type
  @skill_cooldowns.delete(old)
  @skill_cooldowns[replacement] = 0.0
  @upgrades_exhausted = false
end

def replace_eevee_main_skill(name)
  form = PokemonSurvivor.species_key(name)
  return unless PokemonSurvivor::EEVEE_STONE_FORMS.value?(form)
  replacement = PokemonSurvivor::HERO_BASE[form][:skill]
  old = @hero_skill
  return if old == replacement
  transfer_splash_upgrades(old, replacement)
  @learned_skills.map! { |id| id == old ? replacement : id }
  @learned_skills.uniq!
  @hero_skill = replacement
  @base_attack_type = PokemonSurvivor::SKILLS[replacement][:type]
  @hero.attack_type = @base_attack_type
  @skill_cooldowns.delete(old)
  @skill_cooldowns[replacement] = 0.0
  @upgrades_exhausted = false
  progress = PokemonSurvivor.survivor_progress
  progress[:eevee_forms] = [] unless progress[:eevee_forms].is_a?(Array)
  progress[:eevee_forms] << form unless progress[:eevee_forms].include?(form)
  PokemonSurvivorAchievements.check_additional_counters(true, :evolution) if defined?(PokemonSurvivorAchievements)
end

def splash_should_transform_after_evolution?(stage, evolved, new_name)
  return false if !@learned_skills || !@learned_skills.any? { |skill| [:splash, :fairy_splash].include?(skill) }
  base = PokemonSurvivor.species_key(@hero_base_name || (@hero && @hero.name))
  return evolved if base == :MAGIKARP || base == :FEEBAS
  return true if stage.to_i >= 2
  return false if !evolved || !new_name
  !(PokemonSurvivor.next_evolution_species(new_name) rescue nil)
rescue
  false
end

def replacement_splash_skill(skill_id = :splash)
  return :fairy_pump if skill_id == :fairy_splash
  base = PokemonSurvivor.species_key(@hero_base_name || (@hero && @hero.name))
  return :fairy_pump if base == :FEEBAS && @hero_skill == :splash
  :hydro_pump
rescue
  :hydro_pump
end

def replace_splash_after_evolution(stage = nil, evolved = nil, new_name = nil)
  return if !@learned_skills
  [:splash, :fairy_splash].each do |old_skill|
    next if !@learned_skills.include?(old_skill)
    replacement = replacement_splash_skill(old_skill)
    next if !PokemonSurvivor::SKILLS[replacement]
    transfer_splash_upgrades(old_skill, replacement)
    @learned_skills.map! { |skill_id| skill_id == old_skill ? replacement : skill_id }
    @learned_skills.uniq!
    if @hero_skill == old_skill
      @hero_skill = replacement
      @base_attack_type = PokemonSurvivor::SKILLS[replacement][:type]
    end
    @skill_cooldowns ||= {}
    @skill_cooldowns.delete(old_skill)
    @skill_cooldowns[replacement] = 0.0
  end
  @upgrades_exhausted = false
rescue
end

def transfer_splash_upgrades(old_skill, replacement)
  # Preserve upgrades and their caps when a harmless move becomes its final attack.
  [:power_mult, :cooldown_mult, :speed_mult, :radius_bonus, :count_bonus,
   :line_bonus, :orbit_speed_bonus, :knockback_bonus, :freeze_bonus,
   :pierce_bonus, :bounce_bonus, :impact_bonus, :dot_damage_bonus].each do |suffix|
    values = instance_variable_get("@skill_#{suffix}")
    next if !values || !values.key?(old_skill)
    value = values.delete(old_skill)
    if suffix.to_s.end_with?("_mult")
      values[replacement] = (values[replacement] || 1.0) * value
    else
      values[replacement] = (values[replacement] || 0) + value
    end
  end
  prefix = "#{old_skill}_"
  (@upgrade_levels || {}).keys.each do |id|
    next if !id.to_s.start_with?(prefix)
    mapped = "#{replacement}_#{id.to_s[prefix.length..-1]}".to_sym
    @upgrade_levels[mapped] = @upgrade_levels[mapped].to_i + @upgrade_levels.delete(id).to_i
  end
  if @banned_upgrade_ids
    @banned_upgrade_ids.map! do |id|
      id.to_s.start_with?(prefix) ? "#{replacement}_#{id.to_s[prefix.length..-1]}".to_sym : id
    end
    @banned_upgrade_ids.uniq!
  end
end

  def fire_survivor_swing(skill, forced_count = nil)
    return if !@hero
    skill_id = skill_id_for(skill)
    count = if skill[:ignore_projectile_count] || skill[:max_count].to_i == 1
      1
    else
      global_count = (skill[:use_global_projectile_count] == false) ? 0 : @projectile_count_bonus.to_i
      value = forced_count || (skill[:count].to_i + global_count + (@skill_count_bonus ||= Hash.new(0))[skill_id].to_i)
      [[value.to_i, 1].max, projectile_count_cap(skill, skill[:max_count] || 4, value)].min
    end
    base = survivor_swing_facing_angle
    angles = if skill[:target_nearest]
      survivor_swing_nearest_angles(count, base)
    else
      skill[:full_swing] ? [base] : [base, base - (Math::PI / 2.0), base + (Math::PI / 2.0), base + Math::PI]
    end
    radius = skill[:radius].to_i + (@skill_radius_bonus ||= Hash.new(0))[skill_id].to_i
    if skill_id == :normal_sweep && @zangoose_surge_timer.to_f > 0
      radius = (radius * [@zangoose_surge_radius_mult.to_f, 1.5].max).round
    end
    radius = (radius * 1.5).round if skill_id == :disciplined_strikes && @kubfu_focus_timer.to_f > 0
    angles.first(count).each { |angle| spawn_survivor_swing(angle, skill, radius) }
    play_survivor_se(:shot, "Survivor/Battle throw", 0.10, PokemonSurvivor::SFX_SHOT_VOLUME, 118) if respond_to?(:play_survivor_se)
  rescue
  end


  def fire_returning_swing(skill, forced_count = nil)
    return if !@hero
    skill_id = skill_id_for(skill)
    wanted = skill[:count].to_i + @projectile_count_bonus.to_i + (@skill_count_bonus ||= Hash.new(0))[skill_id].to_i
    count = [[wanted, 1].max, projectile_count_cap(skill, skill[:max_count] || 4, wanted)].min
    count = forced_count if forced_count
    target = nearest_visible_enemy
    base_angle = target ? Math.atan2(target.y - @hero.y, target.x - @hero.x) : survivor_swing_facing_angle
    radius = skill[:radius].to_i + (@skill_radius_bonus ||= Hash.new(0))[skill_id].to_i
    count.times do |i|
      angle = base_angle + (Math::PI * 2.0 * i / count.to_f)
      previous_count = @effects.length
      spawn_survivor_swing(angle, skill, radius)
      next if @effects.length == previous_count
      fx = @effects[-1]
      next if !fx || !fx[9].is_a?(Hash) || fx[6][:id] != skill_id
      meta = fx[9]
      meta[:returning_swing] = true
      meta[:fixed_world] = true
      meta[:launch_angle] = angle
      meta[:travel_radius] = skill[:travel_radius].to_f
      meta[:travel_duration] = fx[2]
      # This is a moving blade, not a periodic zone centered on the Pokemon.
      fx[7] = nil
      update_returning_swing_position(fx, meta, 0.0)
    end
    play_survivor_se(:shot, "Survivor/Battle throw", 0.10, PokemonSurvivor::SFX_SHOT_VOLUME, 118)
  end

  def update_returning_swing_position(fx, meta, age)
    progress = [[age.to_f / [meta[:travel_duration].to_f, 0.01].max, 0.0].max, 1.0].min
    angle = meta[:launch_angle].to_f
    distance = meta[:travel_radius].to_f
    if progress < 0.25
      t = progress / 0.25
      distance *= t * t * (3.0 - 2.0 * t)
    elsif progress < 0.75
      t = (progress - 0.25) / 0.5
      angle += Math::PI * t * t * (3.0 - 2.0 * t)
    else
      t = (progress - 0.75) / 0.25
      distance *= 1.0 - t * t * (3.0 - 2.0 * t)
      angle += Math::PI
    end
    fx[0] = @hero.x + Math.cos(angle) * distance
    fx[1] = @hero.y + Math.sin(angle) * distance
    # Keep the launch direction's animation row for the whole blade sequence.
    meta[:visual_angle_override] = meta[:launch_angle].to_f
  end

  def fire_drill_spikes(skill)
    return if !@hero
    skill_id = skill_id_for(skill)
    global_count = (skill[:use_global_projectile_count] == false) ? 0 : @projectile_count_bonus.to_i
    wanted = skill[:count].to_i + global_count + (@skill_count_bonus ||= Hash.new(0))[skill_id].to_i
    count = [[wanted, 1].max, projectile_count_cap(skill, skill[:max_count] || 8, wanted)].min
    base = survivor_swing_facing_angle
    angles = drill_spike_angles(count, base)
    radius = skill[:radius].to_i + (@skill_radius_bonus ||= Hash.new(0))[skill_id].to_i
    angles.first(count).each { |angle| spawn_drill_spike(angle, skill, radius) }
    play_survivor_se(:shot, "Survivor/Battle throw", 0.09, PokemonSurvivor::SFX_SHOT_VOLUME, 112) if respond_to?(:play_survivor_se)
  rescue
  end

  def drill_spike_angles(count, fallback_angle = 0.0)
    count = [[count.to_i, 1].max, 8].min
    raw = survivor_swing_nearest_angles(count, fallback_angle)
    min_gap = (Math::PI * 2.0 / [count, 4].max) * 0.72
    angles = []
    raw.each do |angle|
      a = angle.to_f
      0.upto(7) do |step|
        candidate = a + (step * min_gap)
        if angles.all? { |used| survivor_swing_angle_delta(candidate, used).abs >= min_gap * 0.82 }
          angles << candidate
          break
        end
      end
      break if angles.length >= count
    end
    while angles.length < count
      angles << fallback_angle.to_f + (Math::PI * 2.0 * angles.length / count.to_f)
    end
    angles
  rescue
    [fallback_angle.to_f]
  end

  def spawn_drill_spike(angle, skill, radius)
    source = skill.clone
    source[:id] = skill_id_for(skill)
    duration = [skill[:duration].to_f, 0.22].max
    meta = {
      survivor_swing: true,
      angle: angle.to_f,
      hit: {},
      radius: radius.to_i,
      arc: (skill[:arc] || 0.48).to_f,
      spin_speed: 0.0,
      visual_offset: radius.to_f * (skill[:visual_offset_mult] || 1.02).to_f,
      visual_angle: angle.to_f,
      visual_angle_override: angle.to_f,
      visual_slide_in: true,
      visual_slide_start_mult: 0.18,
      visual_slide_time: 0.16,
      lock_visual_angle: false,
      centered_visual: false,
      visual_scale: skill[:visual_scale].to_f > 0 ? skill[:visual_scale].to_f : 1.0,
      visual_radius_base: skill[:visual_radius_base].to_f > 0 ? skill[:visual_radius_base].to_f : 46.0,
      hit_radius_mult: skill[:hit_radius_mult].to_f > 0 ? skill[:hit_radius_mult].to_f : 0.42,
      cone_hit: true,
      cone_min_mult: 0.10,
      cone_width_mult: 0.48,
      cone_enemy_radius_mult: 0.85,
      cone_origin_offset_mult: 0.42
    }
    @effects << [@hero.x, @hero.y, duration, skill_color(source), radius.to_i, :survivor_swing, source, 0.0, 0.0, meta]
  rescue
  end
  def survivor_swing_nearest_angles(count, fallback_angle = 0.0)
    count = [[count.to_i, 1].max, 8].min
    origin_x = @hero.x.to_f
    origin_y = @hero.y.to_f
    candidates = []
    tied_distances = false
    targets = @enemies || []
    targets = targets + tower_wisp_targets_for(origin_x, origin_y, 9999) if respond_to?(:tower_wisp_targets_for)
    targets.each do |enemy|
      next if !enemy || enemy.hp.to_i <= 0
      dx = enemy.x.to_f - origin_x
      dy = enemy.y.to_f - origin_y
      dist2 = (dx * dx) + (dy * dy)
      next if dist2 <= 1.0
      if candidates.length >= count && dist2 >= candidates[-1][0]
        tied_distances = true if dist2 == candidates[-1][0]
        next
      end
      index = 0
      while index < candidates.length && candidates[index][0] <= dist2
        tied_distances = true if candidates[index][0] == dist2
        index += 1
      end
      candidates.insert(index, [dist2, dx, dy])
      candidates.pop if candidates.length > count
    end
    if tied_distances
      # Ruby's sort tie order is not stable; preserve the original targeting.
      candidates = []
      targets.each do |enemy|
        next if !enemy || enemy.hp.to_i <= 0
        dx = enemy.x.to_f - origin_x
        dy = enemy.y.to_f - origin_y
        dist2 = (dx * dx) + (dy * dy)
        candidates << [dist2, Math.atan2(dy, dx)] if dist2 > 1.0
      end
      angles = candidates.sort_by { |data| data[0] }.first(count).map { |data| data[1] }
    else
      angles = candidates.map { |data| Math.atan2(data[2], data[1]) }
    end
    if angles.length < count
      base = angles[0] || fallback_angle.to_f
      missing = count - angles.length
      missing.times { |i| angles << base + ((Math::PI * 2.0) * (i + 1) / count.to_f) }
    end
    angles
  rescue
    [fallback_angle.to_f]
  end

  def survivor_swing_facing_angle
    if @hero && @hero.moving && (@last_move_dx.to_f.abs > 0.001 || @last_move_dy.to_f.abs > 0.001)
      return Math.atan2(@last_move_dy.to_f, @last_move_dx.to_f)
    end
    case @hero.direction
    when PokemonSurvivor::DIR8_DOWN, PokemonSurvivor::DIR_DOWN then Math::PI / 2.0
    when PokemonSurvivor::DIR8_DOWN_RIGHT then Math::PI / 4.0
    when PokemonSurvivor::DIR8_RIGHT, PokemonSurvivor::DIR_RIGHT then 0.0
    when PokemonSurvivor::DIR8_UP_RIGHT then -Math::PI / 4.0
    when PokemonSurvivor::DIR8_UP, PokemonSurvivor::DIR_UP then -Math::PI / 2.0
    when PokemonSurvivor::DIR8_UP_LEFT then -3.0 * Math::PI / 4.0
    when PokemonSurvivor::DIR8_LEFT, PokemonSurvivor::DIR_LEFT then Math::PI
    when PokemonSurvivor::DIR8_DOWN_LEFT then 3.0 * Math::PI / 4.0
    else 0.0
    end
  rescue
    0.0
  end

  def spawn_survivor_swing(angle, skill, radius)
    source = skill.clone
    source[:id] = skill_id_for(skill)
    duration = [skill[:duration].to_f, 0.18].max
    meta = {
      survivor_swing: true,
      angle: angle.to_f,
      hit: {},
      radius: radius.to_i,
      arc: (skill[:arc] || Math::PI * 2.0).to_f,
      spin_speed: skill[:spin_speed].to_f,
      visual_offset: skill[:centered_visual] ? 0.0 : radius.to_f * (skill[:visual_offset_mult] || 0.42).to_f,
      visual_angle: angle.to_f,
      lock_visual_angle: !!skill[:target_nearest],
      centered_visual: !!skill[:centered_visual],
      visual_scale: skill[:visual_scale].to_f > 0 ? skill[:visual_scale].to_f : 1.0,
      visual_radius_base: skill[:visual_radius_base].to_f > 0 ? skill[:visual_radius_base].to_f : 78.0,
      hit_radius_mult: skill[:hit_radius_mult].to_f > 0 ? skill[:hit_radius_mult].to_f : 0.58,
      radial_hit: !!skill[:radial_hit],
      cone_hit: !!skill[:cone_hit],
      cone_min_mult: skill[:cone_min_mult].to_f > 0 ? skill[:cone_min_mult].to_f : 0.0,
      cone_width_mult: skill[:cone_width_mult].to_f > 0 ? skill[:cone_width_mult].to_f : 1.0,
      cone_enemy_radius_mult: skill[:cone_enemy_radius_mult].to_f >= 0 ? skill[:cone_enemy_radius_mult].to_f : 1.0,
      cone_origin_offset_mult: skill[:cone_origin_offset_mult].to_f > 0 ? skill[:cone_origin_offset_mult].to_f : 0.0
    }
    @effects << [@hero.x, @hero.y, duration, skill_color(source), radius.to_i, :survivor_swing, source, 0.0, 0.0, meta]
  rescue
  end

  def update_survivor_swing_effects(_dt)
    (@effects || []).each do |fx|
      meta = fx[9]
      next if !meta.is_a?(Hash) || !meta[:survivor_swing]
      scale = @ceruledge_burst_timer.to_f > 0 ? 1.5 : 1.0
      previous_scale = meta[:ceruledge_scale] || 1.0
      if scale != previous_scale
        ratio = scale / previous_scale
        meta[:radius] *= ratio
        meta[:visual_offset] *= ratio
        fx[4] *= ratio
        meta[:ceruledge_scale] = scale
      end
      if meta[:returning_swing] && @hero
        extra = @ceruledge_burst_timer.to_f > 0 ? _dt.to_f : 0.0
        meta[:extra_travel_age] = meta[:extra_travel_age].to_f + extra
        fx[2] -= extra
        update_returning_swing_position(fx, meta, fx[8].to_f + _dt.to_f + meta[:extra_travel_age])
      end
      if @hero && @hero.hp.to_i > 0 && !meta[:fixed_world]
        fx[0] = @hero.x
        fx[1] = @hero.y
      end
      source = fx[6]
      if source && source[:tick_per_frame]
        # Visit animation frames, not rendering updates, so low FPS cannot lose ticks.
        last = [((fx[8].to_f + _dt.to_f) * source[:vfx_fps]).ceil - 1, source[:vfx_frames] - 1].min
        first = meta.fetch(:last_damage_frame, -1) + 1
        (first..last).each do |frame|
          meta[:damage_frame] = frame
          update_survivor_swing_hits(fx, meta)
        end
        meta[:last_damage_frame] = last
      else
        update_survivor_swing_hits(fx, meta)
      end
    end
  rescue
  end

  def update_survivor_swing_hits(fx, meta)
    source = fx[6]
    return if !source.respond_to?(:[])
    skill_id = source[:id] || skill_id_for(source)
    radius = meta[:radius].to_i
    origin_x = fx[0].to_f
    origin_y = fx[1].to_f
    base_damage = (source[:damage].to_i * @skill_power_mult[skill_id].to_f).ceil
    if skill_id == :normal_sweep && @zangoose_surge_timer.to_f > 0 && @zangoose_surge_power_mult.to_f > 0
      base_damage = (base_damage * @zangoose_surge_power_mult.to_f).ceil
    end
    age = fx[8].to_f
    spin_bonus = (@skill_orbit_speed_bonus ||= Hash.new(0))[skill_id].to_i * 0.20
    spin_mult = (@zangoose_surge_timer.to_f > 0 ? [@zangoose_surge_spin_mult.to_f, 1.0].max : 1.0)
    angle = meta[:angle].to_f + (age * (meta[:spin_speed].to_f + spin_bonus) * spin_mult)
    angle = eevee_sweep_angle(fx, meta) if meta[:eevee_sweep]
    half_arc = meta[:arc].to_f / 2.0
    centered = !!meta[:centered_visual]
    visual_offset = meta[:visual_offset].to_f
    hit_x = centered ? origin_x : origin_x + Math.cos(angle) * visual_offset
    hit_y = centered ? origin_y : origin_y + Math.sin(angle) * visual_offset
    hit_radius = centered ? radius : [(radius.to_f * (meta[:hit_radius_mult] || 0.58).to_f).round, 20].max
    search_radius = visual_offset.abs + hit_radius + PokemonSurvivor::BOSS_RADIUS + 12
    color = skill_color(source)
    hit_token = source[:tick_per_frame] ? meta[:damage_frame].to_i + 1 : true
    each_nearby_enemy_for(origin_x, origin_y, search_radius) do |enemy|
      next if !enemy || enemy.hp.to_i <= 0 || meta[:hit][enemy.object_id] == hit_token
      dx_from_origin = enemy.x - origin_x
      dy_from_origin = enemy.y - origin_y
      enemy_angle = Math.atan2(dy_from_origin, dx_from_origin)
      next if !meta[:cone_hit] && !meta[:radial_hit] && meta[:arc].to_f < (Math::PI * 2.0 - 0.01) && survivor_swing_angle_delta(enemy_angle, angle).abs > half_arc
      if meta[:cone_hit]
        forward_x = Math.cos(angle)
        forward_y = Math.sin(angle)
        cone_origin_x = origin_x + (forward_x * radius.to_f * meta[:cone_origin_offset_mult].to_f)
        cone_origin_y = origin_y + (forward_y * radius.to_f * meta[:cone_origin_offset_mult].to_f)
        dx_from_cone = enemy.x - cone_origin_x
        dy_from_cone = enemy.y - cone_origin_y
        cone_enemy_angle = Math.atan2(dy_from_cone, dx_from_cone)
        next if survivor_swing_angle_delta(cone_enemy_angle, angle).abs > half_arc
        forward = (dx_from_cone * forward_x) + (dy_from_cone * forward_y)
        min_forward = radius.to_f * meta[:cone_min_mult].to_f
        next if forward < min_forward
        enemy_margin = enemy.radius.to_i * meta[:cone_enemy_radius_mult].to_f
        next if forward > radius + enemy_margin
        side = (dx_from_cone * -forward_y) + (dy_from_cone * forward_x)
        side_limit = (forward * Math.tan(half_arc) * meta[:cone_width_mult].to_f).abs + enemy_margin
        next if side.abs > side_limit
        knock_origin_x = cone_origin_x
        knock_origin_y = cone_origin_y
      else
        dx = enemy.x - hit_x
        dy = enemy.y - hit_y
        limit = hit_radius + enemy.radius.to_i
        next if (dx * dx + dy * dy) > limit * limit
        knock_origin_x = hit_x
        knock_origin_y = hit_y
      end
      meta[:hit][enemy.object_id] = hit_token
      apply_survivor_swing_knockback(enemy, source, knock_origin_x, knock_origin_y)
      damage_source = source.clone
      if source[:impact_once]
        impacts = (meta[:impact_targets] ||= {})
        damage_source[:impact_flurry] = false if impacts[enemy.object_id]
        impacts[enemy.object_id] = true
      end
      damage_source[:knockback] = nil
      damage_source[:knock_limit] = nil
      damage_enemy(enemy, base_damage, source[:type], color, damage_source)
      defeat_enemy(enemy) if enemy.hp.to_i <= 0 && !enemy.instance_variable_get(:@defeated)
    end
    fire_volt_pummel_spark(fx, meta) if source[:spark_chain]
  rescue
  end


  def fire_volt_pummel_spark(fx, meta)
    return if meta[:spark_sent] || meta[:hit].empty?
    target = nearest_psi_target(fx[0], fx[1], meta[:hit])
    return unless target
    meta[:spark_sent] = true
    shot = { id: fx[6][:id], kind: :projectile, type: :ELECTRIC, damage: 12,
      speed: 6.5, pierce: 1, homing: true, freeze: 0.7,
      vfx: "VFX_ELECTRIC_SHOT", vfx_loop: true }
    angle = Math.atan2(target.y - fx[1], target.x - fx[0])
    spawn_projectile_from(fx[0], fx[1], angle, shot) do |p|
      p.homing_target = target
      p.instance_variable_set(:@gen9_excluded_targets, meta[:hit])
    end
  end

  def apply_survivor_swing_knockback(enemy, skill, origin_x, origin_y)
    return if !enemy || !skill.respond_to?(:[])
    return if enemy.kind == :tower_wisp
    skill_id = skill[:id] || skill_id_for(skill)
    return if skill_id == :night_raid && @galar_rush_timer.to_f > 0
    base_knock = skill[:knockback].to_i
    return if base_knock <= 0
    knock = base_knock + (@skill_knockback_bonus ||= Hash.new(0))[skill_id].to_i
    knock_limit = skill[:knock_limit] ? skill[:knock_limit].to_i : 1
    return if enemy.knockback_count.to_i >= knock_limit
    enemy.knockback_count = enemy.knockback_count.to_i + 1
    dx = enemy.x - origin_x.to_f
    dy = enemy.y - origin_y.to_f
    len = [Math.sqrt(dx * dx + dy * dy), 1].max
    enemy.x, enemy.y = clamp_world_spawn_position(
      enemy.x + dx / len * knock, enemy.y + dy / len * knock, enemy.radius)
  rescue
  end
  def survivor_swing_angle_delta(a, b)
    d = (a.to_f - b.to_f) % (Math::PI * 2.0)
    d -= Math::PI * 2.0 if d > Math::PI
    d
  rescue
    0.0
  end
def update_effects(dt)
    update_survivor_swing_effects(dt)

    @effects.each do |fx|
      fx[2] -= dt
      fx[8] = fx[8].to_f + dt
      meta = fx[9] rescue nil
      update_charmander_twister_position(fx, meta) if meta.is_a?(Hash) && meta[:charmander_twister]
      # Swings and rain apply damage through their own hitboxes, not a second zone.
      own_hitbox = meta.is_a?(Hash) && (meta[:poison_rain_drop] || meta[:survivor_swing] || meta[:headache_wave])
      update_poison_zone(fx, dt) if !own_hitbox && (fx[5] == :poison_zone || fx[5] == :ground_zone || fx[7])
    end
    @effects.delete_if { |fx| fx[2] <= 0 }
  end

  def update_poison_zone(fx, dt)
    fx[7] = fx[7].to_f - dt
    return if fx[7] > 0
    skill = fx[6]
    return if !skill
    damage_enemies_in_radius(fx[0], fx[1], fx[4].to_i, skill)
    fx[7] = 0.45
  rescue
  end

  def nearest_enemy
    return nil if !@hero
    best = nil
    best_dist = nil
    targets = @enemies || []
    targets = targets + tower_wisp_targets_for(@hero.x, @hero.y, 9999) if respond_to?(:tower_wisp_targets_for)
    targets.each do |e|
      next if !e || e.hp.to_i <= 0
      dist = point_distance_sq(e.x, e.y, @hero.x, @hero.y)
      if !best_dist || dist < best_dist
        best = e
        best_dist = dist
      end
    end
    best
  rescue
    nil
  end

  def nearest_visible_enemy
    return nil if !@hero
    best = nil
    best_dist = nil
    found = false
    each_nearby_enemy_for(@hero.x, @hero.y, 560) do |e|
      next if !e || e.hp <= 0 || !enemy_visible?(e)
      found = true
      dist = point_distance_sq(e.x, e.y, @hero.x, @hero.y)
      if !best_dist || dist < best_dist
        best = e
        best_dist = dist
      end
    end
    if !found
      (@enemies || []).each do |e|
        next if !e || e.hp <= 0 || !enemy_visible?(e)
        dist = point_distance_sq(e.x, e.y, @hero.x, @hero.y)
        if !best_dist || dist < best_dist
          best = e
          best_dist = dist
        end
      end
    end
    best
  rescue
    nil
  end
  def enemy_visible?(enemy)
    point_on_screen?(enemy.x, enemy.y, 24)
  rescue
    false
  end
  def distance(a, b)
    dx = a.x - b.x
    dy = a.y - b.y
    Math.sqrt(dx * dx + dy * dy)
  end

  def direction_from_vector(dx, dy)
    if dy.abs >= dx.abs
      return dy < 0 ? PokemonSurvivor::DIR_UP : PokemonSurvivor::DIR_DOWN
    end
    dx < 0 ? PokemonSurvivor::DIR_LEFT : PokemonSurvivor::DIR_RIGHT
  end


  def direction_from_vector_8(dx, dy)
    angle = Math.atan2(dy.to_f, dx.to_f) * 180.0 / Math::PI
    angle += 360.0 if angle < 0
    sector = ((angle + 22.5) / 45.0).floor % 8
    case sector
    when 0 then PokemonSurvivor::DIR8_RIGHT
    when 1 then PokemonSurvivor::DIR8_DOWN_RIGHT
    when 2 then PokemonSurvivor::DIR8_DOWN
    when 3 then PokemonSurvivor::DIR8_DOWN_LEFT
    when 4 then PokemonSurvivor::DIR8_LEFT
    when 5 then PokemonSurvivor::DIR8_UP_LEFT
    when 6 then PokemonSurvivor::DIR8_UP
    else PokemonSurvivor::DIR8_UP_RIGHT
    end
  rescue
    PokemonSurvivor::DIR_DOWN
  end

  def character_frame(entity, source = nil)
    return 0 if !entity
    directions = entity.charset_directions
    directions = PokemonSurvivor::CHARSET_8_DIRECTIONS if PokemonSurvivor.eight_direction_bitmap?(source)
    frames = PokemonSurvivor.charset_frame_count(source, entity.direction, directions)
    speed = 8.0
    if !entity.moving
      return 0 if PokemonSurvivor.static_eight_direction_idle?(entity.name)
      return 0 if directions.to_i < PokemonSurvivor::CHARSET_8_DIRECTIONS
      speed = PokemonSurvivor::IDLE_ANIMATION_FPS
    end
    (((@timer || 0) * speed).floor % frames)
  rescue
    0
  end


  def enemy_projectile_color(enemy)
    return Color.new(255, 96, 214) if enemy && enemy.kind == :ultra_boss
    return Color.new(218, 88, 255) if enemy && enemy.kind == :boss
    Color.new(196, 76, 224)
  rescue
    Color.new(196, 76, 224)
  end
  def archetype_color(archetype)
    case archetype
    when :quick  then Color.new(110, 220, 255)
    when :sturdy then Color.new(255, 210, 92)
    when :sharp  then Color.new(255, 96, 110)
    when :elite  then Color.new(190, 126, 255)
    else Color.new(120, 150, 190)
    end
  end

  def skill_color(skill)
    case skill[:type]
    when :FIRE     then Color.new(255, 118, 64)
    when :WATER    then Color.new(78, 174, 255)
    when :GRASS    then Color.new(86, 220, 122)
    when :PSYCHIC  then Color.new(255, 116, 208)
    when :POISON   then Color.new(184, 104, 255)
    when :ELECTRIC then Color.new(255, 224, 74)
    when :ROCK     then Color.new(190, 166, 112)
    when :ICE      then Color.new(130, 232, 255)
    when :FAIRY    then Color.new(255, 150, 218)
    when :STEEL    then Color.new(172, 188, 210)
    when :GROUND   then Color.new(210, 174, 92)
    when :FIGHTING then Color.new(230, 88, 78)
    when :DARK     then Color.new(120, 102, 150)
    when :DRAGON   then Color.new(112, 132, 255)
    when :GHOST    then Color.new(154, 116, 224)
    when :NORMAL   then Color.new(210, 210, 190)
    else Color.white
    end
  end

  def vfx_name_for_type(type)
    PokemonSurvivor::VFX_BY_TYPE[type] || PokemonSurvivor::VFX_BY_TYPE[type.to_s.to_sym] rescue nil
  end

  def projectile_vfx_name(skill)
    return skill[:vfx] if skill && skill[:vfx]
    return skill[:shot_vfx] if skill && skill[:kind] == :charge_shot && skill[:shot_vfx]
    return "VFX_ELECTRIC2_SHOT" if skill && skill[:kind] == :charge_shot && skill[:type] == :ELECTRIC
    return "VFX_ELECTRIC_SHOT" if skill && skill[:kind] == :orbit_shot && skill[:type] == :ELECTRIC
    return "VFX_PSYCHIC" if skill && skill[:kind] == :orbit_shot && skill[:type] == :PSYCHIC
    return vfx_name_for_type(skill[:type]) if skill
    nil
  rescue
    nil
  end

  def orbit_vfx_name(skill)
    return skill[:orbit_vfx] if skill && skill[:orbit_vfx]
    return "VFX_ELECTRIC_ORBIT" if skill && skill[:kind] == :orbit_shot && skill[:type] == :ELECTRIC
    return "VFX_PSYCHIC2" if skill && skill[:kind] == :orbit_shot && skill[:type] == :PSYCHIC
    return projectile_vfx_name(skill)
  rescue
    nil
  end

  def skill_id_for(skill)
    PokemonSurvivor::SKILLS.each_pair { |id, data| return id if data.equal?(skill) || data == skill }
    return skill[:id] if skill.respond_to?(:[]) && skill[:id]
    nil
  rescue
    nil
  end


end












































































