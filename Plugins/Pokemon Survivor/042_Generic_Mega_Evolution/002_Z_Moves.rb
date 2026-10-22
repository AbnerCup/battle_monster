#===============================================================================
# Pokemon Survivor - Z-Crystal charge, shared buffs and species-specific attacks
#===============================================================================
module PokemonSurvivor
  Z_MOVE_DATA = {
    eeviumz: {
      species: [:EEVEE], charge_time: 10.0, duration: 15.0,
      damage_multiplier: 1.5, attack_rate: 2.0, effect: :normal_rain,
      interval: 0.20, skill: {
        id: :eevium_z_rain, type: :NORMAL, damage: 32, radius: 18,
        vfx: "VFX_NORMAL", vfx_fps: 24, vfx_loop: true,
        rain_direct: true, z_move: true
      }.freeze
    }.freeze
  }.freeze unless const_defined?(:Z_MOVE_DATA)
end

module SurvivorZMoveRuntime
  def reset_burst_run_state
    reset_z_move_state
    super
  end

  def reset_z_move_state
    @z_move_timer = 0.0
    @z_move_charge = 0.0
    @z_move_prompt_timer = 0.0
    @z_move_action_buffer_timer = 0.0
    @z_move_icon_timer = 0.0
    @z_move_shot_timer = 0.0
    @z_move_data = nil
    @z_move_icon = nil
    @effects.delete_if { |fx| fx[6].is_a?(Hash) && fx[6][:z_move] } if @effects
  end

  def current_z_move_data
    return nil unless @hero && @hero.hp > 0 && @equipped_item
    data = PokemonSurvivor::Z_MOVE_DATA[@equipped_item[:id]]
    return nil unless data
    return data unless data[:species]
    return nil unless data[:species].include?(PokemonSurvivor.species_key(@hero_base_name))
    data if data[:species].include?(PokemonSurvivor.species_key(@hero.name))
  end

  def z_move_active?
    @z_move_timer.to_f > 0.0
  end

  def z_move_ready?
    data = current_z_move_data
    data && !z_move_active? && ultimate_ready? && @z_move_charge.to_f >= data[:charge_time]
  end

  def ultimate_ready?
    return false if z_move_active?
    super
  end

  def capture_ultimate_action_input
    super
    return if @state != :play || @evolution_anim || z_move_active?
    @z_move_action_buffer_timer = 0.2 if current_z_move_data && select_leaderboard_triggered?
  end

  def update_ultimate(dt)
    return if @evolution_anim
    if z_move_active?
      @ultimate_charge = 0.0
      @ultimate_action_buffer = false
      @ultimate_action_buffer_timer = 0.0
      @z_move_icon_timer = [@z_move_icon_timer.to_f - dt, 0.0].max
      @z_move_timer = [@z_move_timer - dt, 0.0].max
      @ultimate_drain_timer = @z_move_timer
      if z_move_active?
        update_z_move_effect(dt)
      else
        reset_z_move_state
      end
      return
    end
    was_ready = ultimate_ready?
    super
    data = current_z_move_data
    unless data && ultimate_ready?
      @z_move_charge = 0.0
      @z_move_prompt_timer = 0.0
      @z_move_action_buffer_timer = 0.0
      return
    end
    was_z_ready = z_move_ready?
    @z_move_charge = [@z_move_charge.to_f + (was_ready ? dt : 0.0), data[:charge_time]].min
    @z_move_prompt_timer = !was_z_ready && z_move_ready? ? 3.0 : [@z_move_prompt_timer.to_f - dt, 0.0].max
    if @z_move_action_buffer_timer.to_f > 0.0 && z_move_ready?
      activate_z_move(data)
    else
      @z_move_action_buffer_timer = [@z_move_action_buffer_timer.to_f - dt, 0.0].max
    end
  end

  def activate_z_move(data = current_z_move_data)
    return false unless data && z_move_ready?
    @z_move_data = data
    @z_move_timer = data[:duration]
    @z_move_icon_timer = 0.65
    @z_move_shot_timer = 0.0
    @z_move_icon = cached_bitmap(PokemonSurvivor::EQUIPMENT_DIR, @equipped_item[:icon])
    @z_move_action_buffer_timer = 0.0
    @z_move_prompt_timer = 0.0
    @ultimate_charge = 0.0
    @ultimate_drain_duration = data[:duration]
    @ultimate_drain_timer = data[:duration]
    @ultimate_prompt_timer = 0.0
    @ultimate_action_buffer = false
    @ultimate_action_buffer_timer = 0.0
    play_survivor_cry(@hero.name) if respond_to?(:play_survivor_cry)
    play_survivor_se(:z_move, "Survivor/Shiny sparkle", 0.5, PokemonSurvivor::SFX_EVOLUTION_VFX_VOLUME, 100)
    PokemonSurvivor.gamepad_vibrate_event(:burst) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
    # Recover older Tome counters before this activation is added to them.
    if defined?(PokemonSurvivorAchievements) && PokemonSurvivorAchievements.respond_to?(:record_z_move_activation)
      PokemonSurvivorAchievements.record_z_move_activation(@equipped_item[:id])
    end
    if PokemonSurvivor.respond_to?(:battle_pass_record_tome8_z_move)
      PokemonSurvivor.battle_pass_record_tome8_z_move(@equipped_item[:id])
    end
    true
  end

  def update_z_move_effect(dt)
    return unless @z_move_data && @z_move_data[:effect] == :normal_rain
    @z_move_shot_timer -= dt
    return if @z_move_shot_timer > 0.0
    @z_move_shot_timer = @z_move_data[:interval]
    # Reuse world-anchored rain, with at most eight concurrent drops across rains.
    slots = [8 - bulbasaur_poison_rain_active_count, 0].max
    [slots, 2].min.times { spawn_bulbasaur_poison_rain_drop(@z_move_data[:skill]) }
  end

  def equipment_skill_rate
    super * (z_move_active? ? @z_move_data[:attack_rate] : 1.0)
  end

  def passive_damage_multiplier
    super * (z_move_active? ? @z_move_data[:damage_multiplier] : 1.0)
  end

  def apply_passive_burst_on_kill
    return if z_move_active?
    super
  end

  def on_enemy_defeated_by_source(enemy, source)
    super
  ensure
    @ultimate_charge = 0.0 if z_move_active?
  end

  def damage_enemy(enemy, base_damage, attack_type, color = nil, source = nil)
    # Seals bypass the normal damage multiplier pipeline.
    if z_move_active? && enemy && enemy.kind == :tower_wisp
      base_damage = (base_damage * @z_move_data[:damage_multiplier]).ceil
    end
    super(enemy, base_damage, attack_type, color, source)
  end

  def show_ultimate_prompt?
    return @z_move_prompt_timer.to_f > 0.0 if z_move_ready?
    super
  end

  def draw_ultimate_prompt(bitmap)
    return super unless z_move_ready?
    draw_special_action_prompt(bitmap, _INTL("Z-Moves"))
  end

  def draw_hud(bitmap)
    super
    data = @z_move_data || current_z_move_data
    return unless data
    rate = z_move_active? ? @z_move_timer / data[:duration] : @z_move_charge.to_f / data[:charge_time]
    draw_special_charge_gauge(bitmap, rate)
  end

  def draw_hero(bitmap)
    super
    return unless @z_move_icon_timer.to_f > 0.0 && @z_move_icon && !@z_move_icon.disposed?
    age = 0.65 - @z_move_icon_timer
    opacity = (255 * [@z_move_icon_timer / 0.25, 1.0].min).round
    scale = world_screen_zoom(1.0 + age * 0.8)
    w = (@z_move_icon.width * scale).round
    h = (@z_move_icon.height * scale).round
    x = world_screen_x(hero_visual_x).round
    y = world_screen_y(hero_visual_y - 16).round
    shine = (@z_move_shine ||= Color.new(255, 245, 180))
    if age < 0.3
      spread = (8 + age * 60).round
      bitmap.fill_rect(x - spread, y - 1, spread * 2, 2, shine)
      bitmap.fill_rect(x - 1, y - spread, 2, spread * 2, shine)
    end
    bitmap.stretch_blt(Rect.new(x - w / 2, y - h / 2, w, h), @z_move_icon, @z_move_icon.rect, opacity)
  end
end

Scene_PokemonSurvivor.prepend(SurvivorZMoveRuntime) unless Scene_PokemonSurvivor.ancestors.include?(SurvivorZMoveRuntime)
