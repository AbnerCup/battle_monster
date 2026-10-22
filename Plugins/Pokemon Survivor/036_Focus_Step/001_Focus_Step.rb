#===============================================================================
# Pokemon Survivor - Dash
#===============================================================================

class Scene_PokemonSurvivor
  FOCUS_STEP_COOLDOWN = 12.0
  FOCUS_STEP_INVULN = 0.24
  FOCUS_STEP_MIN_DISTANCE = 78.0
  FOCUS_STEP_MAX_DISTANCE = 132.0
  FOCUS_STEP_DURATION = 0.14
  FOCUS_STEP_AFTERIMAGE_LIFETIME = 0.20
  FOCUS_STEP_AFTERIMAGE_INTERVAL = 0.035
  FOCUS_STEP_INPUT_BUFFER = 0.16

  def focus_step_cooldown_duration
    level = @upgrade_levels ? @upgrade_levels[:dash_training].to_i : 0
    passive = @passive_key == :ABRA ? 0.8 : 1.0
    [(FOCUS_STEP_COOLDOWN - (level * 1.5)) * (@equipment_dash_cooldown_mult || 1.0) * passive, 3.0].max
  rescue
    FOCUS_STEP_COOLDOWN
  end

  def update_focus_step(dt)
    duration = focus_step_cooldown_duration
    @focus_step_cooldown = [[@focus_step_cooldown.to_f - dt.to_f, 0.0].max, duration].min
    @focus_step_flash_timer = [@focus_step_flash_timer.to_f - dt.to_f, 0.0].max
    @focus_step_input_buffer = [@focus_step_input_buffer.to_f - dt.to_f, 0.0].max
    @focus_step_input_buffer = FOCUS_STEP_INPUT_BUFFER if focus_step_input_triggered?
    update_focus_step_afterimages(dt)
    if headache_movement_locked?
      @focus_step_anim = nil
      @focus_step_input_buffer = 0.0
      return
    end
    if focus_step_active?
      update_focus_step_animation(dt)
      return
    end
    return if !@hero || @hero.hp.to_i <= 0
    return if @pending_upgrade || @pending_evolution_stage || @evolution_anim
    return if tower_mode? && respond_to?(:tower_floor_transition_active?) && tower_floor_transition_active?
    return if @focus_step_cooldown.to_f > 0.0
    return if @focus_step_input_buffer.to_f <= 0.0
    @focus_step_input_buffer = 0.0
    start_focus_step
  rescue
  end

  def focus_step_input_triggered?
    down = false
    triggered = false
    if PokemonSurvivor.respond_to?(:control_press?)
      down ||= PokemonSurvivor.control_press?(:focus_step)
    end
    if PokemonSurvivor.respond_to?(:control_trigger?)
      triggered ||= PokemonSurvivor.control_trigger?(:focus_step)
    end
    triggered ||= down && !@focus_step_button_down
    @focus_step_button_down = down
    triggered
  rescue
    false
  end
  def focus_step_active?
    !!@focus_step_anim
  rescue
    false
  end

  def start_focus_step
    return if headache_movement_locked?
    dx, dy = focus_step_direction_vector
    len = Math.sqrt((dx * dx) + (dy * dy))
    return if len <= 0.0
    dx /= len
    dy /= len
    distance = focus_step_distance
    actual = clamp_world_scroll(dx * distance, dy * distance)
    sx = actual[0].to_f
    sy = actual[1].to_f
    return if sx.abs < 0.5 && sy.abs < 0.5
    @focus_step_anim = {
      elapsed: 0.0, duration: FOCUS_STEP_DURATION, sx: sx, sy: sy,
      moved_x: 0.0, moved_y: 0.0, dx: dx, dy: dy, distance: Math.sqrt((sx * sx) + (sy * sy)),
      bitmap: draw_hero_bitmap, direction: @hero.direction,
      frame: (character_frame(@hero, draw_hero_bitmap) rescue 0),
      afterimage_timer: 0.0
    }
    @last_move_dx = dx
    @abra_dash_count = @abra_dash_count.to_i + 1 if PokemonSurvivor.species_key(@hero_base_name) == :ABRA
    if (@learned_skills || []).include?(:psi_trail)
      @focus_step_anim[:psi_count] = psi_trail_count
      @focus_step_anim[:psi_emitted] = 0
    end
    @last_move_dy = dy
    @hero.moving = true
    @hero.direction = @hero.charset_directions.to_i >= PokemonSurvivor::CHARSET_8_DIRECTIONS ? direction_from_vector_8(dx, dy) : direction_from_vector(dx, dy)
    @invuln = [@invuln.to_f, FOCUS_STEP_INVULN].max
    @focus_step_cooldown = focus_step_cooldown_duration
    @focus_step_flash_timer = FOCUS_STEP_DURATION
    trigger_gauge_flash if respond_to?(:trigger_gauge_flash)
    pbSEPlay("Survivor/Battle throw", 76, 116) rescue pbSEPlay("Survivor/Battle throw") rescue nil
    PokemonSurvivor.gamepad_vibrate_event(:focus_step, 0.75) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
  rescue
  end

  def update_focus_step_animation(dt)
    anim = @focus_step_anim
    return if !anim
    duration = [anim[:duration].to_f, 0.01].max
    previous = [[anim[:elapsed].to_f / duration, 0.0].max, 1.0].min
    anim[:elapsed] = anim[:elapsed].to_f + dt.to_f
    current = [[anim[:elapsed].to_f / duration, 0.0].max, 1.0].min
    previous_eased = 1.0 - ((1.0 - previous) * (1.0 - previous))
    current_eased = 1.0 - ((1.0 - current) * (1.0 - current))
    move_x = anim[:sx].to_f * (current_eased - previous_eased)
    move_y = anim[:sy].to_f * (current_eased - previous_eased)
    if move_x.abs > 0.001 || move_y.abs > 0.001
      @world_x += move_x
      @world_y += move_y
      anim[:moved_x] = anim[:moved_x].to_f + move_x
      anim[:moved_y] = anim[:moved_y].to_f + move_y
      shift_world_entities(-move_x, -move_y)
    end
    emit_psi_dash_trail(anim, current_eased) if anim[:psi_count]
    @hero.moving = true if @hero
    anim[:afterimage_timer] = anim[:afterimage_timer].to_f - dt.to_f
    if anim[:afterimage_timer].to_f <= 0.0
      spawn_focus_step_afterimage(anim)
      anim[:afterimage_timer] = FOCUS_STEP_AFTERIMAGE_INTERVAL
    end
    @focus_step_anim = nil if current >= 1.0
  rescue
    @focus_step_anim = nil
  end

  def spawn_focus_step_afterimage(anim)
    return if !@hero || !anim || !anim[:bitmap] || anim[:bitmap].disposed?
    @focus_step_afterimages ||= []
    travelled = Math.sqrt((anim[:moved_x].to_f * anim[:moved_x].to_f) + (anim[:moved_y].to_f * anim[:moved_y].to_f))
    offset = [[travelled, 18.0].max, 58.0].min
    @focus_step_afterimages << {
      x: hero_visual_x - (anim[:dx].to_f * offset),
      y: hero_visual_y - (anim[:dy].to_f * offset),
      bitmap: anim[:bitmap], direction: anim[:direction], frame: anim[:frame].to_i,
      life: FOCUS_STEP_AFTERIMAGE_LIFETIME, max_life: FOCUS_STEP_AFTERIMAGE_LIFETIME, distance_rate: (travelled / [anim[:distance].to_f, 1.0].max)
    }
    @focus_step_afterimages.shift while @focus_step_afterimages.length > 6
  rescue
  end

  def update_focus_step_afterimages(dt)
    return if !@focus_step_afterimages
    @focus_step_afterimages.each { |img| img[:life] = img[:life].to_f - dt.to_f }
    @focus_step_afterimages.delete_if { |img| img[:life].to_f <= 0.0 || !img[:bitmap] || img[:bitmap].disposed? }
  rescue
  end

  def draw_focus_step_afterimages(bitmap)
    return if !@focus_step_afterimages || @focus_step_afterimages.empty?
    @focus_step_afterimages.each do |img|
      next if !img[:bitmap] || img[:bitmap].disposed?
      life_rate = [[img[:life].to_f / [img[:max_life].to_f, 0.01].max, 0.0].max, 1.0].min
      distance_rate = [[img[:distance_rate].to_f, 0.0].max, 1.0].min
      trail_rate = 0.18 + (distance_rate * 0.82)
      rate = life_rate * trail_rate
      directions = PokemonSurvivor.eight_direction_bitmap?(img[:bitmap]) ? PokemonSurvivor::CHARSET_8_DIRECTIONS : 4
      zoom = directions.to_i >= PokemonSurvivor::CHARSET_8_DIRECTIONS ? 2.0 : 1.0
      tint = Color.new(118, 206, 255)
      PokemonSurvivor.draw_character_centered_tinted(bitmap, img[:bitmap], world_screen_x(img[:x]), world_screen_y(img[:y]), img[:direction], img[:frame], world_screen_zoom(zoom), tint, 0.10 + (0.28 * rate), directions)
    end
  rescue
  end

  def draw_focus_step_cooldown(bitmap)
    cooldown = @focus_step_cooldown.to_f
    duration = focus_step_cooldown_duration
    return if cooldown <= 0.0 || cooldown >= duration
    progress = 1.0 - (cooldown / duration)
    icon = focus_step_cooldown_bitmap(progress)
    return if !icon || icon.disposed?
    scale = world_screen_zoom(1.0)
    size = (icon.width * scale).round
    x = (world_screen_x(hero_visual_x) + (26 * scale)).round
    y = (world_screen_y(hero_visual_y) - (42 * scale)).round
    if scale == 1.0
      bitmap.blt(x, y, icon, Rect.new(0, 0, icon.width, icon.height))
    else
      src = Rect.new(0, 0, icon.width, icon.height)
      bitmap.stretch_blt(Rect.new(x, y, size, size), icon, src)
    end
  rescue
  end

  def focus_step_cooldown_bitmap(progress)
    @focus_step_cooldown_cache ||= {}
    bucket = [[(progress.to_f * 60).round, 0].max, 60].min
    return @focus_step_cooldown_cache[bucket] if @focus_step_cooldown_cache[bucket] && !@focus_step_cooldown_cache[bucket].disposed?
    size = 18
    center = (size - 1) / 2.0
    radius = 8.0
    bmp = Bitmap.new(size, size)
    bg = Color.new(0, 0, 0, 132)
    fill = PokemonSurvivor.accessible_color(focus_step_cooldown_color(bucket / 60.0))
    edge = Color.new(236, 248, 255, 230)
    full = Math::PI * 2.0 * (bucket / 60.0)
    size.times do |yy|
      size.times do |xx|
        px = xx - center
        py = yy - center
        dist = Math.sqrt((px * px) + (py * py))
        next if dist > radius
        angle = Math.atan2(px, -py)
        angle += Math::PI * 2.0 if angle < 0.0
        color = angle <= full ? fill : bg
        bmp.set_pixel(xx, yy, color)
      end
    end
    # Fine rim for readability.
    size.times do |yy|
      size.times do |xx|
        px = xx - center
        py = yy - center
        dist = Math.sqrt((px * px) + (py * py))
        bmp.set_pixel(xx, yy, edge) if dist > radius - 1.0 && dist <= radius
      end
    end
    @focus_step_cooldown_cache[bucket] = bmp
    bmp
  rescue
    nil
  end
  def focus_step_cooldown_color(progress)
    progress = [[progress.to_f, 0.0].max, 1.0].min
    stops = [
      [0.00, Color.new(255, 70, 54, 236)],
      [0.18, Color.new(255, 148, 54, 232)],
      [0.40, Color.new(255, 224, 82, 230)],
      [0.64, Color.new(118, 238, 122, 226)],
      [0.84, Color.new(84, 232, 226, 224)],
      [1.00, Color.new(76, 176, 255, 220)]
    ]
    lower = stops[0]
    upper = stops[-1]
    stops.each_cons(2) do |a, b|
      if progress >= a[0] && progress <= b[0]
        lower = a
        upper = b
        break
      end
    end
    span = [upper[0] - lower[0], 0.001].max
    t = (progress - lower[0]) / span
    a = lower[1]
    b = upper[1]
    Color.new(
      (a.red + ((b.red - a.red) * t)).round,
      (a.green + ((b.green - a.green) * t)).round,
      (a.blue + ((b.blue - a.blue) * t)).round,
      (a.alpha + ((b.alpha - a.alpha) * t)).round
    )
  rescue
    Color.new(94, 210, 255, 220)
  end
  def focus_step_distance
    speed = @hero ? @hero.speed.to_f : 0.0
    [[FOCUS_STEP_MIN_DISTANCE + (speed * 10.0), FOCUS_STEP_MIN_DISTANCE].max, FOCUS_STEP_MAX_DISTANCE].min
  rescue
    92.0
  end

  def focus_step_direction_vector
    dx = 0.0
    dy = 0.0
    dx -= 1.0 if Input.press?(Input::LEFT)
    dx += 1.0 if Input.press?(Input::RIGHT)
    dy -= 1.0 if Input.press?(Input::UP)
    dy += 1.0 if Input.press?(Input::DOWN)
    if dx != 0.0 || dy != 0.0
      return @psyduck_confusion_timer.to_f > 0 ? [-dx, -dy] : [dx, dy]
    end
    dx = @last_move_dx.to_f
    dy = @last_move_dy.to_f
    return [dx, dy] if dx != 0.0 || dy != 0.0
    focus_step_vector_from_direction(@hero ? @hero.direction : PokemonSurvivor::DIR_DOWN)
  rescue
    [0.0, 1.0]
  end

  def focus_step_vector_from_direction(direction)
    case direction.to_i
    when PokemonSurvivor::DIR_LEFT, PokemonSurvivor::DIR8_LEFT then [-1.0, 0.0]
    when PokemonSurvivor::DIR_RIGHT, PokemonSurvivor::DIR8_RIGHT then [1.0, 0.0]
    when PokemonSurvivor::DIR_UP, PokemonSurvivor::DIR8_UP then [0.0, -1.0]
    when PokemonSurvivor::DIR8_UP_LEFT then [-1.0, -1.0]
    when PokemonSurvivor::DIR8_UP_RIGHT then [1.0, -1.0]
    when PokemonSurvivor::DIR8_DOWN_LEFT then [-1.0, 1.0]
    when PokemonSurvivor::DIR8_DOWN_RIGHT then [1.0, 1.0]
    else [0.0, 1.0]
    end
  rescue
    [0.0, 1.0]
  end
end











