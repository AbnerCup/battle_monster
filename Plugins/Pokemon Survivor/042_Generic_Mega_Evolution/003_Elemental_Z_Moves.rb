#===============================================================================
# Pokemon Survivor - Elemental Z-Moves (world-space attacks and hit shapes)
#===============================================================================
module PokemonSurvivor
  ELEMENTAL_Z_MOVES = {
    normaliumz: [:NORMAL, :cross, "VFX_NORMAL2", 4, 0.20, 32],
    firiumz: [:FIRE, :fire_orbits, "VFX_FIRE9", 6, 0.0, 45],
    wateriumz: [:WATER, :water_blast, "VFX_WATER6", 6, 0.65, 90],
    grassiumz: [:GRASS, :grass_shots, "VFX_GRASS6", 12, 0.45, 46],
    electriumz: [:ELECTRIC, :electric_shots, "VFX_ELECTRIC3", 2, 0.40, 34],
    iciumz: [:ICE, :ice_shots, "VFX_ICE5", 6, 0.40, 48],
    fightiniumz: [:FIGHTING, :strikes, "VFX_FIGHTING7", 9, 0.85, 12],
    poisoniumz: [:POISON, :poison_strikes, "VFX_POISON5", 15, 1.20, 12],
    groundiumz: [:GROUND, :ground_waves, "VFX_GROUND2", 12, 1.0, 105],
    flyiniumz: [:FLYING, :tempest, "VFX_FLYING2", 52, 0.0, 40],
    psychiumz: [:PSYCHIC, :prisons, "VFX_PSYCHIC7", 3, 0.0, 26],
    buginiumz: [:BUG, :spikes, "VFX_BUG4", 13, 0.90, 40],
    rockiumz: [:ROCK, :rain, "VFX_ROCK2", 8, 0.25, 65],
    ghostiumz: [:GHOST, :ghost_shots, "VFX_GHOST2", 2, 0.55, 40],
    dragoniumz: [:DRAGON, :geysers, "VFX_DRAGON6", 14, 1.0, 45],
    darkiniumz: [:DARK, :cross, "VFX_DARK2", 8, 0.20, 32],
    steeliumz: [:STEEL, :steel_orbits, "VFX_STEEL_ORBIT", 4, 0.0, 24],
    fairiumz: [:FAIRY, :fairy_orbits, "VFX_FAIRY5", 4, 1.60, 48]
  }.freeze
  elemental = ELEMENTAL_Z_MOVES.each_with_object({}) do |(id, row), result|
    type, effect, vfx, frames, interval, damage = row
    result[id] = { charge_time: 10.0, duration: 15.0, damage_multiplier: 1.5,
      attack_rate: 2.0, effect: effect, interval: interval,
      skill: {id: id, type: type, vfx: vfx, vfx_frames: frames, damage: damage,
              z_move: true}.freeze }.freeze
  end
  redefine_const(:Z_MOVE_DATA, Z_MOVE_DATA.merge(elemental).freeze)
end

module SurvivorElementalZMoves
  Z_SPIKE_HEIGHTS = [0.12, 0.3, 0.55, 0.8, 1.0, 0.9, 0.78, 0.64, 0.5, 0.36, 0.24, 0.14, 0.06].freeze
  Z_GEYSER_HEIGHTS = [0.12, 0.55, 1.0, 1.0, 1.0, 1.0, 0.8, 0.6, 0.4, 0.25, 0.15, 0.1, 0.07, 0.04].freeze

  def reset_z_move_state
    @elemental_z_actors = []
    @elemental_z_pending = []
    @elemental_z_started = false
    @elemental_z_split = false
    @elemental_z_elapsed = 0.0
    @elemental_z_captures = {}
    @elemental_z_grid_dirty = false
    super
  end

  def update_z_move_effect(dt)
    return super if !@z_move_data || @z_move_data[:effect] == :normal_rain
    @elemental_z_actors ||= []
    @elemental_z_pending ||= []
    @elemental_z_elapsed = @elemental_z_elapsed.to_f + dt
    @z_move_shot_timer = @z_move_shot_timer.to_f - dt
    unless @elemental_z_started && (@z_move_data[:interval] <= 0 || @z_move_shot_timer > 0)
      emit_elemental_z_wave
      @elemental_z_started = true
      @z_move_shot_timer = @z_move_data[:interval]
    end
    if @z_move_data[:effect] == :tempest && @z_move_timer <= 2.5 && !@elemental_z_split
      split_elemental_z_tempest
      @elemental_z_split = true
    end
    @elemental_z_actors.concat(@elemental_z_pending)
    @elemental_z_pending.clear
    build_enemy_grid unless @enemy_grid
    @elemental_z_actors.each { |actor| update_elemental_z_actor(actor, dt) }
    @elemental_z_actors.delete_if { |actor| actor[:age] >= actor[:life] }
    invalidate_enemy_grid if @elemental_z_grid_dirty
    @elemental_z_grid_dirty = false
  end

  def shift_world_entities(dx, dy)
    super
    [@elemental_z_actors, @elemental_z_pending].each do |list|
      (list || []).each do |actor|
        [:x, :anchor_x, :landing_x].each { |key| actor[key] += dx if actor.key?(key) }
        [:y, :anchor_y, :landing_y].each { |key| actor[key] += dy if actor.key?(key) }
      end
    end
  end

  def elemental_z_targets(count)
    closest_visible_enemies_from(@hero.x, @hero.y, 720.0, count)
  end

  def elemental_z_angle(target = nil)
    target ? Math.atan2(target.y - @hero.y, target.x - @hero.x) : survivor_swing_facing_angle
  end

  def add_elemental_z_actor(source, options = {})
    # Bounded independently of minor hit particles: damage never depends on VFX settings.
    return if @elemental_z_actors.length + @elemental_z_pending.length >= 96
    actor = {source: source, x: @hero.x, y: @hero.y, age: 0.0, life: 2.0,
      motion: :fixed, scale: 1.0, angle: 0.0, speed: 300.0, loop: true,
      fps: 18.0, hit: {}, tick: 999.0, shape: :circle, frame: 0}.merge(options)
    sheet = cached_vfx_bitmap(source[:vfx])
    frames = source[:vfx_frames]
    actor[:width] = sheet && !sheet.disposed? ? sheet.width.to_f / frames : 48.0
    actor[:height] = sheet && !sheet.disposed? ? sheet.height.to_f / (actor[:dir8] ? 8 : 1) : 48.0
    actor[:sheet] = sheet
    @elemental_z_pending << actor
    actor
  end

  def elemental_z_source(**changes)
    @z_move_data[:skill].merge(changes)
  end

  def emit_elemental_z_wave
    source = @z_move_data[:skill]
    effect = @z_move_data[:effect]
    case effect
    when :cross
      4.times do |i|
        add_elemental_z_actor(source, motion: :shot, angle: @elemental_z_elapsed * 2.6 + i * Math::PI / 2,
          speed: 330.0, life: 1.7, scale: 1.25, pierce: true)
      end
    when :fire_orbits, :steel_orbits
      count = effect == :fire_orbits ? 8 : 12
      count.times do |i|
        ring = i % 4
        orbit_source = effect == :steel_orbits ? source.merge(knockback: 28) : source
        angle = effect == :fire_orbits ? ring * Math::PI / 2 + (i / 4) * Math::PI : i * Math::PI * 2 / count
        add_elemental_z_actor(orbit_source, motion: :orbit, orbit: effect == :fire_orbits ? 48.0 + ring * 32 : 100.0,
          angle: angle, spin: effect == :fire_orbits ? (ring.even? ? 3.2 : -3.2) : 5.8,
          life: 15.0, tick: 0.35, scale: effect == :fire_orbits ? 2.25 : 1.0)
      end
    when :water_blast, :spikes, :geysers
      elemental_z_targets(12).sample(3).each do |enemy|
        slow = effect == :geysers ? {slow: 2.0, slow_mult: 0.45} : {}
        add_elemental_z_actor(source.merge(slow), x: enemy.x, y: enemy.y,
          shape: effect == :water_blast ? :water : (effect == :spikes ? :spike : :geyser),
          loop: false, fps: 14.0, life: source[:vfx_frames] / 14.0,
          tick: effect == :water_blast ? 999.0 : 0.25, scale: 2.0)
      end
    when :grass_shots, :ice_shots, :ghost_shots
      elemental_z_targets(effect == :ghost_shots ? 2 : 3).each do |enemy|
        status = effect == :ice_shots ? {freeze: 0.8, slow: 2.8, slow_mult: 0.45} : {}
        impact = {grass_shots: :grass, ghost_shots: :ghost}[effect]
        add_elemental_z_actor(source.merge(status), motion: :shot, angle: elemental_z_angle(enemy),
          impact: impact, dir8: effect == :ice_shots, scale: 1.6, life: 2.0)
      end
    when :electric_shots
      8.times do
        add_elemental_z_actor(source.merge(freeze: 0.8), motion: :shot, angle: rand * Math::PI * 2,
          impact: :electric, dir8: true, scale: 1.6, life: 1.7)
      end
    when :strikes, :poison_strikes
      angle = elemental_z_angle(elemental_z_targets(1).first)
      6.times do |i|
        poison = effect == :poison_strikes
        add_elemental_z_actor(poison ? source.merge(dot: 3.0) : source, motion: :orbit, orbit: 100.0,
          angle: angle + i * Math::PI / 3, spin: 0.0, shape: :strikes,
          fps: 15.0, loop: false, life: source[:vfx_frames] / 15.0,
          scale: 2.0, tick: 1.0 / 15.0, per_frame: true,
          pull: poison ? nil : 110.0, pull_speed: 180.0, final_push: !poison)
      end
    when :ground_waves
      add_elemental_z_actor(source, shape: :wave, scale: 3.0, loop: false, fps: 12.0, life: 1.0)
    when :tempest
      angle = elemental_z_angle(elemental_z_targets(1).first)
      add_elemental_z_actor(source, x: @hero.x + Math.cos(angle) * 100,
        y: @hero.y + Math.sin(angle) * 100, motion: :tempest, angle: angle,
        scale: 3.0, life: 15.0, fps: 12.0, tick: 0.35,
        speed: 80.0, pull: 260.0, pull_speed: 220.0, shape: :tornado)
    when :prisons
      8.times do |i|
        add_elemental_z_actor(source, motion: :prison, anchor_x: @hero.x, anchor_y: @hero.y,
          orbit: 125.0, angle: i * Math::PI / 4, spin: 0.5,
          scale: 1.5, life: 15.0, tick: 0.35, pull: 115.0, pull_speed: 230.0)
      end
    when :rain
      elemental_z_targets(12).sample(2).each do |enemy|
        add_elemental_z_actor(source.merge(freeze: 0.8), x: enemy.x, y: enemy.y - 160,
          motion: :rain, landing_x: enemy.x, landing_y: enemy.y, scale: 1.5,
          life: 0.35 + (source[:vfx_frames] - 1) / 18.0 + 0.12,
          fall_time: 0.35, loop: false, rain_impact_animation: true)
      end
    when :fairy_orbits
      targets = elemental_z_targets(8)
      8.times do |i|
        add_elemental_z_actor(source, motion: :apple, orbit: 75.0, angle: i * Math::PI / 4,
          spin: Math::PI * 2 / 0.75, release: 0.75, target: targets[i], impact: :fairy,
          scale: 1.3, life: 2.3, speed: 360.0, tick: 0.35)
      end
    end
  end

  def split_elemental_z_tempest
    parent = @elemental_z_actors.find { |actor| actor[:motion] == :tempest }
    return unless parent
    parent[:life] = parent[:age]
    targets = elemental_z_targets(8)
    8.times do |i|
      add_elemental_z_actor(parent[:source], x: parent[:x], y: parent[:y], motion: :homing,
        target: targets[i], angle: i * Math::PI / 4, scale: 1.0, speed: 235.0,
        life: @z_move_timer, fps: 12.0, tick: 0.4, pierce: true, shape: :tornado)
    end
  end

  def update_elemental_z_actor(actor, dt)
    return if actor[:age] >= actor[:life]
    old_age = actor[:age]
    actor[:age] = [old_age + dt, actor[:life]].min
    source = actor[:source]
    frames = source[:vfx_frames]
    raw_frame = (actor[:age] * actor[:fps]).floor
    actor[:frame] = actor[:loop] ? raw_frame % frames : [raw_frame, frames - 1].min
    motion = actor[:motion]
    if [:orbit, :apple, :prison].include?(motion)
      actor[:angle] += actor[:spin] * dt
      cx = motion == :prison ? actor[:anchor_x] : @hero.x
      cy = motion == :prison ? actor[:anchor_y] : @hero.y
      actor[:x] = cx + Math.cos(actor[:angle]) * actor[:orbit]
      actor[:y] = cy + Math.sin(actor[:angle]) * actor[:orbit]
      if motion == :apple && actor[:age] >= actor[:release]
        target = actor[:target]
        actor[:angle] = Math.atan2(target.y - actor[:y], target.x - actor[:x]) if target && target.hp > 0
        actor[:motion] = :shot
        actor[:hit].clear
      end
    elsif [:shot, :homing, :tempest].include?(motion)
      target = actor[:target]
      if motion == :homing
        if !target || target.hp <= 0 || !enemy_visible?(target)
          claimed = @elemental_z_actors.select { |a| a != actor && a[:motion] == :homing }.map { |a| a[:target] }
          target = elemental_z_targets(16).find { |enemy| !claimed.include?(enemy) }
          actor[:target] = target
        end
        actor[:angle] = Math.atan2(target.y - actor[:y], target.x - actor[:x]) if target
      end
      actor[:x] += Math.cos(actor[:angle]) * actor[:speed] * dt
      actor[:y] += Math.sin(actor[:angle]) * actor[:speed] * dt
    elsif motion == :rain
      progress = [actor[:age] / actor[:fall_time], 1.0].min
      actor[:y] = actor[:landing_y] - 160.0 * (1.0 - progress)
      if actor[:rain_impact_animation]
        impact_age = actor[:age] - actor[:fall_time]
        actor[:frame] = impact_age < 0 ? 0 : [1 + (impact_age * actor[:fps]).floor, frames - 1].min
      end
    elsif motion == :attached
      target = actor[:target]
      if target && target.hp > 0
        actor[:x], actor[:y] = target.x, target.y
      end
    end
    if actor[:motion] == :tempest && respond_to?(:clamp_world_spawn_position)
      actor[:x], actor[:y] = clamp_world_spawn_position(actor[:x], actor[:y], actor[:width] * actor[:scale] / 2)
    end
    if actor[:pull] && !actor[:pushed]
      pull_elemental_z_enemies(actor, dt)
    end
    return if motion == :rain && actor[:age] < actor[:fall_time]
    if actor[:rain_impact_animation]
      return if actor[:impact_applied]
      actor[:impact_applied] = true
    end
    return if actor[:shape] == :impact && actor[:frame] < 1
    # Kubfu-like attacks hit once for every animation frame, even when a frame spans two updates.
    if actor[:per_frame]
      previous = actor[:last_damage_frame] || -1
      (previous + 1..actor[:frame]).each { |frame| damage_elemental_z_shape(actor, frame) }
      actor[:last_damage_frame] = actor[:frame]
    else
      damage_elemental_z_shape(actor)
    end
    if actor[:final_push] && actor[:frame] == frames - 1 && !actor[:pushed]
      push_elemental_z_enemies(actor)
      actor[:pushed] = true
    end
  end

  def elemental_z_shape(actor)
    half_w = actor[:width] * actor[:scale] * 0.42
    half_h = actor[:height] * actor[:scale] * 0.42
    x, y, frame = actor[:x], actor[:y], actor[:frame]
    factor = 1.0
    case actor[:shape]
    when :water then factor = frame == 0 ? 0.16 : [0.45 + frame * 0.15, 1.0].min
    when :impact then factor = frame == 0 ? 0.0 : [0.6 + frame * 0.2, 1.0].min
    when :wave then factor = [(actor[:age] / actor[:life]) ** 0.65, 0.06].max
    when :spike, :geyser
      heights = actor[:shape] == :spike ? Z_SPIKE_HEIGHTS : Z_GEYSER_HEIGHTS
      growth = heights[frame]
      bottom = y + half_h
      half_h *= growth
      half_w *= 0.35 + growth * 0.65
      y = bottom - half_h
    when :tornado
      half_w *= 0.85
      half_h *= 0.70
      y += actor[:height] * actor[:scale] * 0.12
    end
    [x, y, [half_w * factor, 1.0].max, [half_h * factor, 1.0].max]
  end

  def damage_elemental_z_shape(actor, frame = nil)
    x, y, rx, ry = elemental_z_shape(actor)
    source = actor[:source]
    each_nearby_enemy_for(x, y, [rx, ry].max + PokemonSurvivor::BOSS_RADIUS + 48) do |enemy|
      next if !enemy || enemy.hp <= 0 || !enemy_visible?(enemy)
      dx, dy = enemy.x - x, enemy.y - y
      next if (dx / (rx + enemy.radius)) ** 2 + (dy / (ry + enemy.radius)) ** 2 > 1.0
      if actor[:shape] == :water && actor[:frame] >= 2
        hole = [rx * 0.3 - enemy.radius, 0.0].max
        next if dx * dx + dy * dy < hole * hole
      end
      previous = actor[:hit][enemy.object_id]
      next if previous && (frame ? previous == frame : actor[:age] - previous < actor[:tick])
      actor[:hit][enemy.object_id] = frame || actor[:age]
      damage_enemy(enemy, source[:damage], source[:type], skill_color(source), source)
      if [:shot, :homing].include?(actor[:motion]) && !actor[:pierce]
        spawn_elemental_z_impact(actor, enemy) if actor[:impact]
        actor[:life] = actor[:age]
        break
      end
    end
  end

  def spawn_elemental_z_impact(actor, enemy)
    case actor[:impact]
    when :grass then vfx, frames, status = "VFX_GRASS6_EX", 5, {}
    when :electric then vfx, frames, status = "VFX_ELECTRIC4", 13, {freeze: 0.8}
    when :fairy then vfx, frames, status = "VFX_FAIRY6", 10, {}
    when :ghost
      add_elemental_z_actor(actor[:source], x: enemy.x, y: enemy.y, target: enemy,
        motion: :attached, life: 3.0, scale: 3.0, tick: 0.35, pull: 135.0, pull_speed: 210.0)
      return
    end
    source = actor[:source].merge(vfx: vfx, vfx_frames: frames, damage: 48).merge(status)
    add_elemental_z_actor(source, x: enemy.x, y: enemy.y, shape: :impact,
      loop: false, fps: 18.0, life: frames / 18.0, scale: actor[:impact] == :electric ? 1.0 : 2.0)
  end

  def move_elemental_z_enemy(enemy, x, y)
    return if enemy.kind == :tower_wisp
    x, y = clamp_world_spawn_position(x, y, enemy.radius) if respond_to?(:clamp_world_spawn_position)
    enemy.x, enemy.y = x, y
    @elemental_z_grid_dirty = true
  end

  def pull_elemental_z_enemies(actor, dt)
    radius = actor[:pull]
    each_nearby_enemy_for(actor[:x], actor[:y], radius + PokemonSurvivor::BOSS_RADIUS) do |enemy|
      next if enemy.hp <= 0 || enemy.kind == :tower_wisp
      claim = @elemental_z_captures && @elemental_z_captures[enemy.object_id]
      next if actor[:motion] == :prison && claim && !claim[1].equal?(actor)
      dx, dy = actor[:x] - enemy.x, actor[:y] - enemy.y
      length = Math.sqrt(dx * dx + dy * dy)
      next if length > radius || length < 0.1
      next unless claim_enemy_attraction(enemy, actor)
      resistance = [:boss, :ultra_boss, :chest, :ultra_chest].include?(enemy.kind) ? 0.25 : 1.0
      step = [actor[:pull_speed] * dt * resistance, length].min
      move_elemental_z_enemy(enemy, enemy.x + dx / length * step, enemy.y + dy / length * step)
      if actor[:motion] == :prison && length <= actor[:width] * actor[:scale] * 0.4 + step
        @elemental_z_captures ||= {}
        @elemental_z_captures[enemy.object_id] ||= [enemy, actor]
      end
    end
  end

  def update_enemies(dt)
    super
    return unless z_move_active? && @elemental_z_captures && !@elemental_z_captures.empty?
    @elemental_z_captures.delete_if do |_id, pair|
      enemy, actor = pair
      next true if enemy.hp <= 0 || actor[:age] >= actor[:life]
      dx, dy = enemy.x - actor[:x], enemy.y - actor[:y]
      length = Math.sqrt(dx * dx + dy * dy)
      radius = [actor[:width] * actor[:scale] * 0.35 - enemy.radius, 2.0].max
      if length > radius
        move_elemental_z_enemy(enemy, actor[:x] + dx / length * radius, actor[:y] + dy / length * radius)
      end
      false
    end
    invalidate_enemy_grid if @elemental_z_grid_dirty
    @elemental_z_grid_dirty = false
  end

  def push_elemental_z_enemies(actor)
    each_nearby_enemy_for(actor[:x], actor[:y], 110.0) do |enemy|
      next if enemy.hp <= 0 || enemy.kind == :tower_wisp
      dx, dy = enemy.x - actor[:x], enemy.y - actor[:y]
      length = Math.sqrt(dx * dx + dy * dy)
      next if length > 110.0
      dx, dy, length = Math.cos(actor[:angle]), Math.sin(actor[:angle]), 1.0 if length < 0.1
      force = [:boss, :ultra_boss, :chest, :ultra_chest].include?(enemy.kind) ? 20.0 : 80.0
      move_elemental_z_enemy(enemy, enemy.x + dx / length * force, enemy.y + dy / length * force)
    end
  end

  def draw_hero(bitmap)
    draw_elemental_z_actors(bitmap) if @elemental_z_actors && !@elemental_z_actors.empty?
    super
  end

  def draw_elemental_z_actors(bitmap)
    @elemental_z_actors.each do |actor|
      sheet = actor[:sheet]
      next if !sheet || sheet.disposed? || actor[:age] >= actor[:life]
      next unless point_on_screen?(actor[:x], actor[:y], [actor[:width], actor[:height]].max * actor[:scale])
      row = actor[:dir8] ? survivor_swing_vfx_row(actor[:angle]) : 0
      rect = Rect.new(actor[:frame] * actor[:width], row * actor[:height], actor[:width], actor[:height])
      scale = world_screen_zoom(actor[:scale])
      w, h = (actor[:width] * scale).round, (actor[:height] * scale).round
      x, y = world_screen_x(actor[:x]), world_screen_y(actor[:y])
      fade = [[(actor[:life] - actor[:age]) / 0.12, 1.0].min, 0.0].max
      bitmap.stretch_blt(Rect.new((x - w / 2).round, (y - h / 2).round, w, h), sheet, rect, (255 * fade).round)
      if @show_hitbox_debug && !actor[:impact_applied] && !(actor[:motion] == :rain && actor[:age] < actor[:fall_time]) &&
         !(actor[:shape] == :impact && actor[:frame] < 1)
        hx, hy, rx, ry = elemental_z_shape(actor)
        24.times do |i|
          angle = i * Math::PI / 12
          draw_hitbox_debug_dot(bitmap, hx + Math.cos(angle) * rx, hy + Math.sin(angle) * ry)
        end
      end
    end
  end
end

Scene_PokemonSurvivor.prepend(SurvivorElementalZMoves) unless Scene_PokemonSurvivor.ancestors.include?(SurvivorElementalZMoves)
