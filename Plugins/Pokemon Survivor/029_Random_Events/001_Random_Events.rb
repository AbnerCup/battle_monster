#===============================================================================
# Pokemon Survivor - Random run events
#===============================================================================

class Scene_PokemonSurvivor

  EGG_EVENT_SPAWN_MIN = 95.0
  EGG_EVENT_SPAWN_MAX = 175.0
  EGG_EVENT_RESPAWN_MIN = 185.0
  EGG_EVENT_RESPAWN_MAX = 300.0
  EGG_EVENT_ACTIVATE_RADIUS = 72.0
  EGG_EVENT_ACTIVATE_SECONDS = 3.0
  EGG_EVENT_HATCH_MIN_SECONDS = 30.0
  EGG_EVENT_HATCH_MAX_SECONDS = 30.0
  EGG_EVENT_HURT_SECONDS = 0.26
  EGG_EVENT_HATCH_FLASH_SECONDS = 1.1
  EGG_EVENT_FOLLOW_DISTANCE = 52.0
  EGG_EVENT_BABY_DISTANCE = 66.0
  EVENT_BABY_HP_RATE = 0.48
  EVENT_BABY_DAMAGE_INVULN = 0.45
  SLEEP_EVENT_SPAWN_MIN = 120.0
  SLEEP_EVENT_SPAWN_MAX = 220.0
  SLEEP_EVENT_RESPAWN_MIN = 210.0
  SLEEP_EVENT_RESPAWN_MAX = 340.0
  SLEEP_EVENT_ACTIVATE_RADIUS = EGG_EVENT_ACTIVATE_RADIUS
  SLEEP_EVENT_ACTIVATE_SECONDS = EGG_EVENT_ACTIVATE_SECONDS
  SLEEP_EVENT_WAKE_SECONDS = 10.0
  SLEEP_EVENT_POSE_SECONDS = 0.95
  SLEEP_EVENT_DAMAGE_INVULN = 0.45
  SLEEP_EVENT_CLASSIC_TIMES = [180.0, 360.0, 540.0, 720.0].freeze

  BABY_EVENT_DATA = {
    :ELEKID => {
      name: "Elekid", type: :ELECTRIC, skill: :thunder_ring,
      desc: "Burst charge speed +14%. Fires Electric shots.",
      apply: proc { |scene| scene.instance_variable_set(:@burst_charge_mult, (scene.instance_variable_get(:@burst_charge_mult) || 1.0).to_f * 1.14) },
      remove: proc { |scene| scene.instance_variable_set(:@burst_charge_mult, (scene.instance_variable_get(:@burst_charge_mult) || 1.0).to_f / 1.14) }
    },
    :HAPPINY => {
      name: "Happiny", type: :NORMAL, skill: :normal_shot,
      desc: "EXP gained +25%. Pickup range +10%. Fires Normal shots.",
      apply: proc do |scene|
        scene.instance_variable_set(:@xp_gain_mult, (scene.instance_variable_get(:@xp_gain_mult) || 1.0).to_f * 1.25)
        scene.instance_variable_set(:@pickup_mult, (scene.instance_variable_get(:@pickup_mult) || 1.0).to_f * 1.10)
      end,
      remove: proc do |scene|
        scene.instance_variable_set(:@xp_gain_mult, (scene.instance_variable_get(:@xp_gain_mult) || 1.0).to_f / 1.25)
        scene.instance_variable_set(:@pickup_mult, (scene.instance_variable_get(:@pickup_mult) || 1.0).to_f / 1.10)
      end
    },
    :MAGBY => {
      name: "Magby", type: :FIRE, skill: :fire,
      desc: "Damage dealt +12%. Fires Fire shots.",
      apply: proc { |scene| scene.instance_variable_set(:@damage_mult, (scene.instance_variable_get(:@damage_mult) || 1.0).to_f * 1.12) },
      remove: proc { |scene| scene.instance_variable_set(:@damage_mult, (scene.instance_variable_get(:@damage_mult) || 1.0).to_f / 1.12) }
    },
    :SMOOCHUM => {
      name: "Smoochum", type: :ICE, skill: :ice_shatter,
      desc: "Status effects last longer. Skills recharge slightly faster. Fires Ice shots.",
      apply: proc do |scene|
        scene.instance_variable_set(:@status_duration_mult, (scene.instance_variable_get(:@status_duration_mult) || 1.0).to_f * 1.12)
        scene.instance_variable_set(:@cooldown_mult, (scene.instance_variable_get(:@cooldown_mult) || 1.0).to_f * 0.96)
      end,
      remove: proc do |scene|
        scene.instance_variable_set(:@status_duration_mult, (scene.instance_variable_get(:@status_duration_mult) || 1.0).to_f / 1.12)
        scene.instance_variable_set(:@cooldown_mult, (scene.instance_variable_get(:@cooldown_mult) || 1.0).to_f / 0.96)
      end
    },
    :TOGEPI => {
      name: "Togepi", type: :FAIRY, skill: :fairy_guard,
      desc: "Damage taken -7%. Companion HP +15%. Fires Fairy shots.",
      apply: proc do |scene|
        scene.instance_variable_set(:@shield_mult, (scene.instance_variable_get(:@shield_mult) || 1.0).to_f * 0.93)
        scene.instance_variable_set(:@event_baby_hp_bonus_mult, (scene.instance_variable_get(:@event_baby_hp_bonus_mult) || 1.0).to_f * 1.15)
      end,
      remove: proc do |scene|
        scene.instance_variable_set(:@shield_mult, (scene.instance_variable_get(:@shield_mult) || 1.0).to_f / 0.93)
        scene.instance_variable_set(:@event_baby_hp_bonus_mult, (scene.instance_variable_get(:@event_baby_hp_bonus_mult) || 1.0).to_f / 1.15)
      end
    },
    :TYROGUE => {
      name: "Tyrogue", type: :FIGHTING, skill: :fighting_dash,
      desc: "Skills recharge faster. Move speed rises slightly. Fires Fighting shots.",
      apply: proc do |scene|
        scene.instance_variable_set(:@cooldown_mult, (scene.instance_variable_get(:@cooldown_mult) || 1.0).to_f * 0.94)
        hero = scene.instance_variable_get(:@hero)
        hero.speed *= 1.05 if hero
      end,
      remove: proc do |scene|
        scene.instance_variable_set(:@cooldown_mult, (scene.instance_variable_get(:@cooldown_mult) || 1.0).to_f / 0.94)
        hero = scene.instance_variable_get(:@hero)
        hero.speed /= 1.05 if hero
      end
    },
    :MANTYKE => {
      name: "Mantyke", type: :WATER, skill: :water,
      desc: "Pickup range +18%. Enemy projectile damage -6%. Fires Water shots.",
      apply: proc do |scene|
        scene.instance_variable_set(:@pickup_mult, (scene.instance_variable_get(:@pickup_mult) || 1.0).to_f * 1.18)
        scene.instance_variable_set(:@enemy_projectile_shield_mult, (scene.instance_variable_get(:@enemy_projectile_shield_mult) || 1.0).to_f * 0.94)
      end,
      remove: proc do |scene|
        scene.instance_variable_set(:@pickup_mult, (scene.instance_variable_get(:@pickup_mult) || 1.0).to_f / 1.18)
        scene.instance_variable_set(:@enemy_projectile_shield_mult, (scene.instance_variable_get(:@enemy_projectile_shield_mult) || 1.0).to_f / 0.94)
      end
    },
    :MIMEJR => {
      name: "Mime Jr.", type: :PSYCHIC, skill: :psychic,
      desc: "Boss damage +10%. Enemy projectile damage -5%. Fires Psychic shots.",
      apply: proc do |scene|
        scene.instance_variable_set(:@boss_damage_mult, (scene.instance_variable_get(:@boss_damage_mult) || 1.0).to_f * 1.10)
        scene.instance_variable_set(:@enemy_projectile_shield_mult, (scene.instance_variable_get(:@enemy_projectile_shield_mult) || 1.0).to_f * 0.95)
      end,
      remove: proc do |scene|
        scene.instance_variable_set(:@boss_damage_mult, (scene.instance_variable_get(:@boss_damage_mult) || 1.0).to_f / 1.10)
        scene.instance_variable_set(:@enemy_projectile_shield_mult, (scene.instance_variable_get(:@enemy_projectile_shield_mult) || 1.0).to_f / 0.95)
      end
    },
    :MUNCHLAX => {
      name: "Munchlax", type: :NORMAL, skill: :normal_shot,
      desc: "Max HP +10%. Damage taken -5%. Fires sturdy Normal shots.",
      apply: proc do |scene|
        hero = scene.instance_variable_get(:@hero)
        if hero
          bonus = [[(hero.max_hp.to_i * 0.10).round, 10].max, 70].min
          hero.max_hp += bonus
          hero.hp = [hero.hp.to_i + bonus, hero.max_hp.to_i].min
          scene.instance_variable_set(:@event_munchlax_hp_bonus, bonus)
        end
        scene.instance_variable_set(:@shield_mult, (scene.instance_variable_get(:@shield_mult) || 1.0).to_f * 0.95)
      end,
      remove: proc do |scene|
        hero = scene.instance_variable_get(:@hero)
        bonus = scene.instance_variable_get(:@event_munchlax_hp_bonus).to_i
        if hero && bonus > 0
          hero.max_hp = [hero.max_hp.to_i - bonus, 1].max
          hero.hp = [hero.hp.to_i, hero.max_hp.to_i].min
        end
        scene.instance_variable_set(:@event_munchlax_hp_bonus, 0)
        scene.instance_variable_set(:@shield_mult, (scene.instance_variable_get(:@shield_mult) || 1.0).to_f / 0.95)
      end
    }
  }.freeze unless const_defined?(:BABY_EVENT_DATA)

  SLEEP_EVENT_DATA = {
    :TAPUBULU => {
      name: "Tapu Bulu", type: :GRASS,
      desc: "Max HP +12%. Damage dealt +8% for this run.",
      apply: proc do |scene|
        hero = scene.instance_variable_get(:@hero)
        if hero
          bonus = [[(hero.max_hp.to_i * 0.12).round, 12].max, 80].min
          hero.max_hp += bonus
          hero.hp = [hero.hp.to_i + bonus, hero.max_hp.to_i].min
        end
        scene.instance_variable_set(:@damage_mult, (scene.instance_variable_get(:@damage_mult) || 1.0).to_f * 1.08)
      end
    },
    :TAPUKOKO => {
      name: "Tapu Koko", type: :ELECTRIC,
      desc: "Move speed +8%. Burst charge speed +18% for this run.",
      apply: proc do |scene|
        hero = scene.instance_variable_get(:@hero)
        hero.speed *= 1.08 if hero
        scene.instance_variable_set(:@burst_charge_mult, (scene.instance_variable_get(:@burst_charge_mult) || 1.0).to_f * 1.18)
      end
    },
    :TAPULELE => {
      name: "Tapu Lele", type: :PSYCHIC,
      desc: "Status durations +18%. EXP gained +15% for this run.",
      apply: proc do |scene|
        scene.instance_variable_set(:@status_duration_mult, (scene.instance_variable_get(:@status_duration_mult) || 1.0).to_f * 1.18)
        scene.instance_variable_set(:@xp_gain_mult, (scene.instance_variable_get(:@xp_gain_mult) || 1.0).to_f * 1.15)
      end
    },
    :TAPUFINI => {
      name: "Tapu Fini", type: :WATER,
      desc: "Damage taken -10%. Restores 20% HP instantly.",
      apply: proc do |scene|
        scene.instance_variable_set(:@shield_mult, (scene.instance_variable_get(:@shield_mult) || 1.0).to_f * 0.90)
        hero = scene.instance_variable_get(:@hero)
        hero.hp = [hero.hp.to_i + (hero.max_hp.to_i * 0.20).round, hero.max_hp.to_i].min if hero
      end
    }
  }.freeze unless const_defined?(:SLEEP_EVENT_DATA)

def setup_random_events
  reset_event_baby_state(true)
  @event_egg = nil
  @event_sleep = nil
  @sleep_event_seen_keys = []
  @sleep_event_awakened_keys = []
  @pending_sleep_reward_key = nil
  @pending_sleep_reward_queue = []
  @sleep_reward_consume_start = nil
  @sleep_event_classic_index = 0
  @rush_sleep_spawned_waves = []
  @random_event_timer = random_event_enabled? && !tower_mode? ? random_event_delay(false) : 999_999.0
  @sleep_event_timer = endless_mode? ? sleep_event_delay(false) : 999_999.0
rescue
end

def reset_event_baby_state(remove_bonus = true)
  remove_event_baby_bonus if remove_bonus && @event_baby_bonus_key
  @event_baby = nil
  @pending_baby_choice = nil
  @baby_choice_index = 1
  @baby_choice_consume_start = nil
  @baby_choice_pending_index = nil
  @event_baby_bonus_key = nil
  @event_baby_hp_bonus_mult = 1.0
rescue
  @event_baby = nil
  @pending_baby_choice = nil
  @event_baby_bonus_key = nil
  @event_baby_hp_bonus_mult = 1.0
end

  def random_event_enabled?
    @run_mode == :classic || rush_mode? || endless_mode? || (tower_mode? && respond_to?(:tower_egg_floor?) && tower_egg_floor?)
  rescue
    false
  end

  def random_event_delay(respawn = true)
    min = respawn ? EGG_EVENT_RESPAWN_MIN : EGG_EVENT_SPAWN_MIN
    max = respawn ? EGG_EVENT_RESPAWN_MAX : EGG_EVENT_SPAWN_MAX
    min + (random_event_unit * [max - min, 1.0].max)
  rescue
    180.0
  end

  def sleep_event_enabled?
    return false if tower_mode?
    @run_mode == :classic || rush_mode? || endless_mode?
  rescue
    false
  end

  def sleep_event_delay(respawn = true)
    min = respawn ? SLEEP_EVENT_RESPAWN_MIN : SLEEP_EVENT_SPAWN_MIN
    max = respawn ? SLEEP_EVENT_RESPAWN_MAX : SLEEP_EVENT_SPAWN_MAX
    min + (random_event_unit * [max - min, 1.0].max)
  rescue
    240.0
  end

  def sleep_event_available?
    !available_sleep_event_keys.empty?
  rescue
    false
  end

  def available_sleep_event_keys
    blocked = []
    blocked.concat((@sleep_event_awakened_keys ||= []).map { |key| PokemonSurvivor.species_key(key) rescue key })
    blocked << (PokemonSurvivor.species_key(@event_sleep.instance_variable_get(:@sleep_key)) rescue nil) if @event_sleep
    blocked << (PokemonSurvivor.species_key(@pending_sleep_reward_key) rescue nil) if @pending_sleep_reward_key
    blocked.concat((@pending_sleep_reward_queue ||= []).map { |key| PokemonSurvivor.species_key(key) rescue key })
    blocked.compact!
    (PokemonSurvivor::EVENT_SLEEP_KEYS rescue []).compact.map { |key| PokemonSurvivor.species_key(key) }.reject { |key| blocked.include?(key) }
  rescue
    []
  end

  def random_event_sleep_key
    available = available_sleep_event_keys
    if porygon_rigging_active? && !tower_mode?
      ordered = @porygon_run_settings[:sleep].find { |key| available.include?(key) }
      return ordered if ordered
    end
    available.sample
  rescue
    nil
  end

  def random_event_unit
    rand(10_000).to_f / 10_000.0
  rescue
    0.5
  end

  def update_random_events(dt)
    enabled = random_event_enabled?
    sleep_enabled = sleep_event_enabled?
    return if !enabled && !sleep_enabled && !@event_egg && !@event_baby && !@event_sleep
    if enabled && tower_mode?
      spawn_random_event_egg(true) if !@event_egg && !@tower_egg_hatched_this_floor && @state != :baby_choice && @state != :sleep_reward
    elsif enabled
      @random_event_timer = @random_event_timer.to_f - dt.to_f if !@event_egg
      spawn_random_event_egg if !@event_egg && @random_event_timer.to_f <= 0.0
    end
    update_sleep_event_schedule(dt) if sleep_enabled
    update_event_egg(dt) if @event_egg
    update_event_baby(dt) if @event_baby
    update_event_sleep(dt) if @event_sleep
  rescue
  end

  def update_sleep_event_schedule(dt)
    if @run_mode == :classic
      update_classic_sleep_event_schedule
    elsif rush_mode?
      update_rush_sleep_event_schedule
    elsif endless_mode?
      update_endless_sleep_event_schedule(dt)
    end
  rescue
  end

  def sleep_event_spawn_allowed?
    return false if @event_sleep || !sleep_event_available?
    return false if @state == :baby_choice || @state == :sleep_reward
    true
  rescue
    false
  end

  def update_classic_sleep_event_schedule
    times = SLEEP_EVENT_CLASSIC_TIMES rescue [180.0, 360.0, 540.0, 720.0]
    @sleep_event_classic_index ||= 0
    return if @sleep_event_classic_index >= times.length
    return if @timer.to_f < times[@sleep_event_classic_index].to_f
    return if !sleep_event_spawn_allowed?
    spawn_random_event_sleep(false)
    @sleep_event_classic_index += 1
  rescue
  end

  def update_endless_sleep_event_schedule(dt)
    return if !sleep_event_spawn_allowed?
    @sleep_event_timer = @sleep_event_timer.to_f - dt.to_f
    spawn_random_event_sleep(false) if @sleep_event_timer.to_f <= 0.0
  rescue
  end

  def update_rush_sleep_event_schedule
    return if !respond_to?(:rush_boss_alive?) || !rush_boss_alive?
    wave = @rush_wave_index.to_i
    return if !rush_sleep_wave_spawnable?(wave)
    spawn_rush_sleep_for_wave(wave)
  rescue
  end

  def rush_sleep_wave_spawnable?(wave)
    return false if !rush_mode? || tower_mode?
    total = @rush_total_waves.to_i
    total = (@rush_boss_sequence || []).length if total <= 0
    return false if total <= 1
    return false if wave < 0 || wave >= total - 1
    spawned = (@rush_sleep_spawned_waves ||= [])
    return false if spawned.include?(wave)
    sleep_event_spawn_allowed?
  rescue
    false
  end

  def spawn_rush_sleep_for_wave(wave = nil)
    wave = @rush_wave_index.to_i if wave.nil?
    return if !rush_sleep_wave_spawnable?(wave)
    (@rush_sleep_spawned_waves ||= []) << wave
    spawn_random_event_sleep(true)
  rescue
  end
  def spawn_random_event_egg(on_map = false)
    return if @event_egg
    x, y = on_map ? random_event_map_position : random_event_offscreen_position
    egg = PokemonSurvivorEntity.new(:event_egg, "EGG", x, y)
    egg.max_hp = event_egg_max_hp
    egg.hp = egg.max_hp
    egg.radius = 18
    egg.speed = event_egg_follow_speed
    egg.bitmap = cached_event_bitmap("EGG", 7)
    egg.idle_bitmap = cached_event_bitmap("EGG_Idle", 5)
    egg.walk_bitmap = egg.bitmap
    egg.charset_directions = PokemonSurvivor::CHARSET_8_DIRECTIONS
    egg.direction = PokemonSurvivor::DIR8_DOWN
    egg.moving = false
    egg.instance_variable_set(:@event_state, :waiting)
    egg.instance_variable_set(:@activate_timer, 0.0)
    egg.instance_variable_set(:@escort_timer, 0.0)
    egg.instance_variable_set(:@hatch_duration, random_event_egg_hatch_duration)
    egg.instance_variable_set(:@hurt_timer, 0.0)
    egg.instance_variable_set(:@hit_invuln, 0.0)
    egg.instance_variable_set(:@hatch_timer, 0.0)
    @event_egg = egg
    @random_event_timer = tower_mode? ? 999_999.0 : random_event_delay(true)
  rescue
  end

  def spawn_random_event_sleep(on_map = false)
    return if @event_sleep || !sleep_event_available?
    key = random_event_sleep_key
    return if !key
    x, y = on_map ? random_event_map_position : random_event_offscreen_position
    sleep = PokemonSurvivorEntity.new(:event_sleep, key.to_s, x, y)
    sleep.max_hp = event_sleep_max_hp
    sleep.hp = sleep.max_hp
    sleep.radius = 18
    sleep.speed = 0.0
    sleep.bitmap = cached_event_sleep_bitmap(key, false)
    sleep.idle_bitmap = sleep.bitmap
    sleep.walk_bitmap = sleep.bitmap
    sleep.charset_directions = PokemonSurvivor::CHARSET_8_DIRECTIONS
    sleep.types = PokemonSurvivor.species_types(key) rescue [sleep_event_data(key)[:type] || :NORMAL]
    sleep.attack_type = sleep_event_data(key)[:type] || sleep.types[0] || :NORMAL
    sleep.direction = PokemonSurvivor::DIR8_DOWN
    sleep.moving = false
    sleep.instance_variable_set(:@sleep_key, key)
    sleep.instance_variable_set(:@event_state, :waiting)
    sleep.instance_variable_set(:@activate_timer, 0.0)
    sleep.instance_variable_set(:@wake_timer, 0.0)
    sleep.instance_variable_set(:@pose_timer, 0.0)
    sleep.instance_variable_set(:@hit_invuln, 0.0)
    @sleep_event_seen_keys ||= []
    @sleep_event_seen_keys << key if !@sleep_event_seen_keys.include?(key)
    @event_sleep = sleep
    @sleep_event_timer = sleep_event_delay(true)
  rescue
  end

  def sleep_event_data(key)
    SLEEP_EVENT_DATA[PokemonSurvivor.species_key(key)] || {}
  rescue
    {}
  end

  def event_sleep_max_hp
    level = @level.to_i
    seconds = endless_mode? ? endless_pressure_seconds(@timer.to_i) : @timer.to_i
    [[95 + (level * 6) + (seconds / 7), 120].max, 980].min
  rescue
    140
  end

  def update_event_sleep(dt)
    sleep = @event_sleep
    return if !sleep || !@hero
    sleep.instance_variable_set(:@hit_invuln, [sleep.instance_variable_get(:@hit_invuln).to_f - dt.to_f, 0.0].max)
    state = sleep.instance_variable_get(:@event_state) || :waiting
    case state
    when :waiting
      update_waiting_event_sleep(sleep, dt)
    when :guard
      update_guard_event_sleep(sleep, dt)
      update_event_sleep_damage(sleep)
    when :posing
      update_posing_event_sleep(sleep, dt)
    end
    if sleep.hp.to_i <= 0
      add_ultimate_effect(sleep.x, sleep.y, 0.34, { type: sleep.attack_type || :NORMAL, vfx: "VFX_LEVEL_UP_BURST" }, 64, :ring) rescue nil
      @event_sleep = nil
    end
  rescue
  end

  def update_waiting_event_sleep(sleep, dt)
    sleep.moving = false
    if point_distance_sq(sleep.x, sleep.y, @hero.x, @hero.y) <= SLEEP_EVENT_ACTIVATE_RADIUS * SLEEP_EVENT_ACTIVATE_RADIUS
      timer = sleep.instance_variable_get(:@activate_timer).to_f + dt.to_f
      sleep.instance_variable_set(:@activate_timer, timer)
      if timer >= SLEEP_EVENT_ACTIVATE_SECONDS
        sleep.instance_variable_set(:@event_state, :guard)
        sleep.instance_variable_set(:@activate_timer, SLEEP_EVENT_ACTIVATE_SECONDS)
        sleep.instance_variable_set(:@wake_timer, 0.0)
        set_hero_item_flash(Color.new(210, 238, 255), 0.6) rescue nil
      end
    else
      sleep.instance_variable_set(:@activate_timer, 0.0)
    end
  rescue
  end

  def update_guard_event_sleep(sleep, dt)
    sleep.moving = false
    if point_distance_sq(sleep.x, sleep.y, @hero.x, @hero.y) <= SLEEP_EVENT_ACTIVATE_RADIUS * SLEEP_EVENT_ACTIVATE_RADIUS
      sleep.instance_variable_set(:@wake_timer, sleep.instance_variable_get(:@wake_timer).to_f + dt.to_f)
    end
    if sleep.instance_variable_get(:@wake_timer).to_f >= SLEEP_EVENT_WAKE_SECONDS
      sleep.instance_variable_set(:@event_state, :posing)
      sleep.instance_variable_set(:@pose_timer, SLEEP_EVENT_POSE_SECONDS)
      sleep.bitmap = cached_event_sleep_bitmap(sleep.instance_variable_get(:@sleep_key), true)
      play_survivor_cry(sleep.instance_variable_get(:@sleep_key), 76, 100) if respond_to?(:play_survivor_cry)
      sleep.direction = direction_from_vector_8(@hero.x - sleep.x, @hero.y - sleep.y) rescue PokemonSurvivor::DIR8_DOWN
      set_hero_item_flash(Color.new(255, 238, 168), 0.7) rescue nil
      PokemonSurvivor.gamepad_vibrate_event(:sleep_awaken) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
    end
  rescue
  end

  def update_posing_event_sleep(sleep, dt)
    timer = sleep.instance_variable_get(:@pose_timer).to_f - dt.to_f
    sleep.instance_variable_set(:@pose_timer, timer)
    return if timer > 0.0
    key = sleep.instance_variable_get(:@sleep_key)
    add_ultimate_effect(sleep.x, sleep.y, 0.46, { type: sleep.attack_type || :NORMAL, vfx: "VFX_LEVEL_UP_BURST" }, 84, :ring) rescue nil
    @event_sleep = nil
    open_sleep_reward(key)
  rescue
    @event_sleep = nil
  end

  def update_event_sleep_damage(sleep)
    return if !sleep || sleep.hp.to_i <= 0 || sleep.instance_variable_get(:@hit_invuln).to_f > 0
    each_nearby_enemy_for(sleep.x, sleep.y, sleep.radius + PokemonSurvivor::BOSS_RADIUS + 8) do |enemy|
      next if !enemy || enemy.hp.to_i <= 0
      next if !collision?(enemy, sleep)
      type_mod = PokemonSurvivor.type_multiplier(enemy.attack_type, sleep.types)
      amount = [(enemy.damage.to_i * type_mod * 0.72).ceil, 1].max
      event_sleep_take_damage(sleep, amount)
      break
    end
    return if sleep.instance_variable_get(:@hit_invuln).to_f > 0 || !@projectiles
    @projectiles.each do |projectile|
      next if !projectile || projectile.owner != :enemy || projectile.pierce.to_i <= 0
      next if !collision?(projectile, sleep)
      type_mod = PokemonSurvivor.type_multiplier(projectile.attack_type, sleep.types)
      amount = [(projectile.damage.to_i * type_mod * 0.76).ceil, 1].max
      event_sleep_take_damage(sleep, amount)
      projectile.pierce = 0
      break
    end
  rescue
  end

  def event_sleep_take_damage(sleep, amount)
    return if !sleep || amount.to_i <= 0
    sleep.hp = [sleep.hp.to_i - amount.to_i, 0].max
    sleep.instance_variable_set(:@hit_invuln, SLEEP_EVENT_DAMAGE_INVULN)
    play_survivor_se(:event_sleep_hurt, "Survivor/Battle damage normal", 0.12, PokemonSurvivor::SFX_HIT_VOLUME, 100) rescue nil
  rescue
  end

  def event_sleep_wake_rate(sleep)
    [[sleep.instance_variable_get(:@wake_timer).to_f / SLEEP_EVENT_WAKE_SECONDS, 0.0].max, 1.0].min
  rescue
    0.0
  end

  def random_event_map_position
    return [Graphics.width / 2, Graphics.height / 2] if !@hero
    angle = random_event_unit * Math::PI * 2.0
    dist = 138.0 + (random_event_unit * 86.0)
    x = @hero.x + Math.cos(angle) * dist
    y = @hero.y + Math.sin(angle) * dist
    x, y = clamp_world_spawn_position(x, y, 58) if respond_to?(:clamp_world_spawn_position)
    [x, y]
  rescue
    [Graphics.width / 2, Graphics.height / 2]
  end

  def random_event_offscreen_position
    w = @screen_w || Graphics.width
    h = @screen_h || Graphics.height
    margin = 92
    12.times do
      side = rand(4)
      x, y = case side
             when 0 then [rand(w), -margin]
             when 1 then [w + margin, rand(h)]
             when 2 then [rand(w), h + margin]
             else [-margin, rand(h)]
             end
      x, y = clamp_world_spawn_position(x, y, 52) if respond_to?(:clamp_world_spawn_position)
      return [x, y] if !point_on_screen?(x, y, 56)
    end
    angle = random_event_unit * Math::PI * 2.0
    dist = [([w, h].max * 0.55), 220.0].max
    x = (w * 0.5) + Math.cos(angle) * dist
    y = (h * 0.5) + Math.sin(angle) * dist
    x, y = clamp_world_spawn_position(x, y, 52) if respond_to?(:clamp_world_spawn_position)
    [x, y]
  rescue
    x = Graphics.width / 2
    y = 56
    respond_to?(:clamp_world_spawn_position) ? clamp_world_spawn_position(x, y, 52) : [x, y]
  end

  def event_egg_max_hp
    level = @level.to_i
    seconds = endless_mode? ? endless_pressure_seconds(@timer.to_i) : @timer.to_i
    [[70 + (level * 5) + (seconds / 8), 90].max, 850].min
  rescue
    120
  end

  def event_egg_follow_speed
    return 1.4 if !@hero
    [[@hero.speed.to_f * 0.92, 1.35].max, 5.5].min
  rescue
    1.4
  end

  def random_event_egg_hatch_duration
    EGG_EVENT_HATCH_MIN_SECONDS + (random_event_unit * (EGG_EVENT_HATCH_MAX_SECONDS - EGG_EVENT_HATCH_MIN_SECONDS))
  rescue
    120.0
  end

  def event_egg_hatch_rate(egg)
    duration = egg.instance_variable_get(:@hatch_duration).to_f
    return 0.0 if duration <= 0.0
    [[egg.instance_variable_get(:@escort_timer).to_f / duration, 0.0].max, 1.0].min
  rescue
    0.0
  end

  def update_event_egg(dt)
    egg = @event_egg
    return if !egg
    egg.instance_variable_set(:@hurt_timer, [egg.instance_variable_get(:@hurt_timer).to_f - dt.to_f, 0.0].max)
    egg.instance_variable_set(:@hit_invuln, [egg.instance_variable_get(:@hit_invuln).to_f - dt.to_f, 0.0].max)
    state = egg.instance_variable_get(:@event_state) || :waiting
    case state
    when :waiting
      update_waiting_event_egg(egg, dt)
    when :escort
      update_escort_event_egg(egg, dt)
      update_event_egg_damage(egg, dt)
    when :hatching
      update_hatching_event_egg(egg, dt)
    end
    if egg.hp.to_i <= 0
      add_ultimate_effect(egg.x, egg.y, 0.34, { type: :NORMAL, vfx: "VFX_LEVEL_UP_BURST" }, 64, :ring) rescue nil
      @event_egg = nil
    end
  rescue
  end

  def update_waiting_event_egg(egg, dt)
    egg.moving = false
    dist = point_distance_sq(egg.x, egg.y, @hero.x, @hero.y)
    if dist <= EGG_EVENT_ACTIVATE_RADIUS * EGG_EVENT_ACTIVATE_RADIUS
      timer = egg.instance_variable_get(:@activate_timer).to_f + dt.to_f
      egg.instance_variable_set(:@activate_timer, timer)
      if timer >= EGG_EVENT_ACTIVATE_SECONDS
        egg.instance_variable_set(:@event_state, :escort)
        egg.instance_variable_set(:@escort_timer, 0.0)
        set_hero_item_flash(Color.new(255, 232, 148), 0.6) rescue nil
      end
    else
      egg.instance_variable_set(:@activate_timer, 0.0)
    end
  rescue
  end

  def update_escort_event_egg(egg, dt)
    target_x, target_y = follower_target_position(EGG_EVENT_FOLLOW_DISTANCE, Math::PI / 7.0)
    dx = target_x - egg.x
    dy = target_y - egg.y
    len = Math.sqrt(dx * dx + dy * dy)
    egg.moving = len > 4.0
    if len > 1.0
      egg.direction = direction_from_vector_8(dx, dy)
      speed = event_egg_follow_speed * 60.0 * dt.to_f
      step = [speed, len].min
      egg.x += dx / len * step
      egg.y += dy / len * step
    end
    egg.instance_variable_set(:@escort_timer, egg.instance_variable_get(:@escort_timer).to_f + dt.to_f)
    hatch_duration = egg.instance_variable_get(:@hatch_duration).to_f
    hatch_duration = random_event_egg_hatch_duration if hatch_duration <= 0
    egg.instance_variable_set(:@hatch_duration, hatch_duration)
    if egg.instance_variable_get(:@escort_timer).to_f >= hatch_duration
      egg.instance_variable_set(:@event_state, :hatching)
      egg.instance_variable_set(:@hatch_timer, EGG_EVENT_HATCH_FLASH_SECONDS)
      egg.instance_variable_set(:@hurt_timer, EGG_EVENT_HURT_SECONDS)
      egg.moving = false
    end
  rescue
  end

  def update_hatching_event_egg(egg, dt)
    timer = egg.instance_variable_get(:@hatch_timer).to_f - dt.to_f
    egg.instance_variable_set(:@hatch_timer, timer)
    hatch_event_egg(egg) if timer <= 0.0
  rescue
  end

  def update_event_egg_damage(egg, dt)
    return if egg.instance_variable_get(:@hit_invuln).to_f > 0
    @enemies.each do |enemy|
      next if !enemy || enemy.hp.to_i <= 0
      next if !collision?(enemy, egg)
      event_egg_take_damage(egg, [enemy.damage.to_i, 1].max)
      break
    end
    @projectiles.each do |projectile|
      next if !projectile || projectile.owner != :enemy || projectile.pierce.to_i <= 0
      next if !collision?(projectile, egg)
      event_egg_take_damage(egg, [projectile.damage.to_i, 1].max)
      projectile.pierce = 0
      break
    end
  rescue
  end

  def event_egg_take_damage(egg, amount)
    egg.hp = [egg.hp.to_i - amount.to_i, 0].max
    egg.instance_variable_set(:@hurt_timer, EGG_EVENT_HURT_SECONDS)
    egg.instance_variable_set(:@hit_invuln, 0.32)
    play_survivor_se(:event_egg_hurt, "Survivor/Battle damage normal", 0.12, PokemonSurvivor::SFX_HIT_VOLUME, 96) rescue nil
  rescue
  end

  def hatch_event_egg(egg)
    baby_key = random_event_baby_key
    baby = build_event_baby(baby_key, egg.x, egg.y)
    add_ultimate_effect(egg.x, egg.y, 0.46, { type: baby.attack_type, vfx: "VFX_LEVEL_UP_BURST" }, 84, :ring) rescue nil
    vibration_event = baby.instance_variable_get(:@baby_shiny) ? :egg_shiny_hatch : :egg_hatch
    PokemonSurvivor.gamepad_vibrate_event(vibration_event) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
    @event_egg = nil
    @tower_egg_hatched_this_floor = true if tower_mode? && respond_to?(:tower_egg_floor?) && tower_egg_floor?
    if @event_baby
      @pending_baby_choice = [@event_baby, baby]
      @baby_choice_index = 1
      @state = :baby_choice
      draw_baby_choice
    else
      set_event_baby(baby)
    end
  rescue
    @event_egg = nil
  end

  def current_event_baby_key
    return nil if !@event_baby
    @event_baby.instance_variable_get(:@baby_key)
  rescue
    nil
  end

  def random_event_baby_key
    keys = (PokemonSurvivor::EVENT_BABY_KEYS rescue []).compact.map { |entry| PokemonSurvivor.species_key(entry) }
    keys.reject! { |key| porygon_excluded?(:eggs, key) }
    current = PokemonSurvivor.species_key(current_event_baby_key) rescue nil
    keys = keys.reject { |key| key == current } if current
    keys.sample || :TOGEPI
  rescue
    :TOGEPI
  end

  def build_event_baby(key, x, y)
    data = BABY_EVENT_DATA[key] || BABY_EVENT_DATA[:TOGEPI]
    name = key.to_s
    shiny = (rand(4) == 0)
    baby = PokemonSurvivorEntity.new(:event_baby, name, x, y)
    baby.radius = 13
    baby.speed = event_baby_follow_speed
    baby.max_hp = event_baby_max_hp(shiny)
    baby.hp = baby.max_hp
    baby.damage = 1
    baby.bitmap = cached_baby_event_bitmap(name, false, shiny)
    baby.idle_bitmap = cached_baby_event_bitmap(name, true, shiny)
    baby.walk_bitmap = baby.bitmap
    baby.charset_directions = PokemonSurvivor::CHARSET_8_DIRECTIONS
    baby.types = PokemonSurvivor.species_types(key)
    baby.attack_type = data[:type] || baby.types[0] || :NORMAL
    baby.direction = PokemonSurvivor::DIR8_DOWN
    baby.cooldown = 0.8
    baby.instance_variable_set(:@baby_key, key)
    baby.instance_variable_set(:@baby_shiny, shiny)
    baby.instance_variable_set(:@shot_timer, 0.8)
    baby.instance_variable_set(:@hit_invuln, 0.0)
    baby.instance_variable_set(:@last_synced_max_hp, baby.max_hp.to_i)
    play_survivor_se(:event_baby_shiny, "Survivor/Shiny", 0.2, PokemonSurvivor::SFX_EVOLUTION_VFX_VOLUME, 100) if shiny
    baby
  rescue
    nil
  end
  def set_event_baby(baby)
    return if !baby
    remove_event_baby_bonus
    @event_baby = baby
    apply_event_baby_bonus(baby.instance_variable_get(:@baby_key))
    set_hero_item_flash(Color.new(255, 238, 168), 0.8) rescue nil
  rescue
  end

  def apply_event_baby_bonus(key)
    data = BABY_EVENT_DATA[key]
    return if !data
    @event_baby_bonus_key = key
    data[:apply].call(self) if data[:apply]
  rescue
  end

  def remove_event_baby_bonus
    key = @event_baby_bonus_key
    data = BABY_EVENT_DATA[key]
    data[:remove].call(self) if data && data[:remove]
    @event_baby_bonus_key = nil
  rescue
  end


  def heal_event_baby_rate(rate, minimum = 1)
    baby = @event_baby
    return if !baby || baby.hp.to_i <= 0 || baby.max_hp.to_i <= 0
    heal = [(baby.max_hp.to_f * rate.to_f).round, minimum.to_i].max
    heal_event_baby(heal)
  rescue
  end

  def event_baby_needs_heal?
    baby = @event_baby
    baby && baby.hp.to_i > 0 && baby.hp.to_i < baby.max_hp.to_i
  rescue
    false
  end
  def update_event_baby(dt)
    baby = @event_baby
    return if !baby || !@hero
    sync_event_baby_stats(baby)
    baby.instance_variable_set(:@hit_invuln, [baby.instance_variable_get(:@hit_invuln).to_f - dt.to_f, 0.0].max)
    update_event_baby_damage(baby, dt)
    return if !@event_baby || baby.hp.to_i <= 0
    target_x, target_y = follower_target_position(EGG_EVENT_BABY_DISTANCE, -Math::PI / 8.0)
    dx = target_x - baby.x
    dy = target_y - baby.y
    len = Math.sqrt(dx * dx + dy * dy)
    baby.moving = len > 3.0
    if len > 1.0
      baby.direction = direction_from_vector_8(dx, dy)
      step = [event_baby_follow_speed * 60.0 * dt.to_f, len].min
      baby.x += dx / len * step
      baby.y += dy / len * step
    end
    timer = baby.instance_variable_get(:@shot_timer).to_f - dt.to_f
    if timer <= 0.0
      spawn_event_baby_projectile(baby)
      timer = event_baby_shot_cooldown(baby)
    end
    baby.instance_variable_set(:@shot_timer, timer)
  rescue
  end


  def event_baby_max_hp(shiny = false)
    base = @hero && @hero.max_hp.to_i > 0 ? @hero.max_hp.to_i : 120
    hp_mult = (@event_baby_hp_bonus_mult || 1.0).to_f
    hp_mult *= 2.0 if shiny
    cap = shiny ? 1240 : 620
    [[(base * EVENT_BABY_HP_RATE * hp_mult).round, 45].max, cap].min
  rescue
    shiny ? 160 : 80
  end
  def event_baby_follow_speed
    return 2.0 if !@hero
    [[@hero.speed.to_f, 1.6].max, 6.0].min
  rescue
    2.0
  end

  def sync_event_baby_stats(baby)
    return if !baby || !@hero
    old_max = baby.instance_variable_get(:@last_synced_max_hp).to_i
    new_max = event_baby_max_hp(baby.instance_variable_get(:@baby_shiny))
    return if new_max <= 0 || old_max == new_max
    rate = old_max > 0 ? (baby.hp.to_f / old_max.to_f) : 1.0
    baby.max_hp = new_max
    baby.hp = [[(new_max * rate).round, 1].max, new_max].min
    baby.instance_variable_set(:@last_synced_max_hp, new_max)
  rescue
  end

  def update_event_baby_damage(baby, dt)
    return if !baby || baby.hp.to_i <= 0
    update_event_baby_contact_damage(baby)
    update_event_baby_projectile_damage(baby)
  rescue
  end

  def update_event_baby_contact_damage(baby)
    return if baby.instance_variable_get(:@hit_invuln).to_f > 0
    each_nearby_enemy_for(baby.x, baby.y, baby.radius + PokemonSurvivor::BOSS_RADIUS + 8) do |enemy|
      next if !enemy || enemy.hp.to_i <= 0
      next if !collision?(enemy, baby)
      type_mod = PokemonSurvivor.type_multiplier(enemy.attack_type, baby.types)
      amount = [(enemy.damage.to_i * type_mod * 0.72).ceil, 1].max
      event_baby_take_damage(baby, amount)
      break
    end
  rescue
  end

  def update_event_baby_projectile_damage(baby)
    return if baby.instance_variable_get(:@hit_invuln).to_f > 0
    return if !@projectiles || @projectiles.empty?
    @projectiles.each do |projectile|
      next if !projectile || projectile.owner != :enemy || projectile.pierce.to_i <= 0
      next if !collision?(projectile, baby)
      type_mod = PokemonSurvivor.type_multiplier(projectile.attack_type, baby.types)
      amount = [(projectile.damage.to_i * type_mod * 0.76).ceil, 1].max
      event_baby_take_damage(baby, amount)
      projectile.pierce = 0
      break
    end
  rescue
  end

  def event_baby_take_damage(baby, amount)
    return if !baby || amount.to_i <= 0
    baby.hp = [baby.hp.to_i - amount.to_i, 0].max
    baby.instance_variable_set(:@hit_invuln, EVENT_BABY_DAMAGE_INVULN)
    play_survivor_se(:event_baby_hurt, "Survivor/Battle damage normal", 0.12, PokemonSurvivor::SFX_HIT_VOLUME, 104) rescue nil
    remove_event_baby if baby.hp.to_i <= 0
  rescue
  end

  def remove_event_baby
    remove_event_baby_bonus
    @event_baby = nil
    set_hero_item_flash(Color.new(180, 180, 210), 0.55) rescue nil
  rescue
    @event_baby = nil
  end

  def heal_event_baby(amount)
    baby = @event_baby
    return if !baby || baby.hp.to_i <= 0 || amount.to_i <= 0
    sync_event_baby_stats(baby)
    baby.hp = [baby.hp.to_i + amount.to_i, baby.max_hp.to_i].min
  rescue
  end
  def follower_target_position(distance, angle_offset = 0.0)
    dx = @hero.vx.to_f
    dy = @hero.vy.to_f
    if dx.abs < 0.01 && dy.abs < 0.01
      case @hero.direction
      when PokemonSurvivor::DIR8_RIGHT then dx = 1.0
      when PokemonSurvivor::DIR8_LEFT then dx = -1.0
      when PokemonSurvivor::DIR8_UP then dy = -1.0
      when PokemonSurvivor::DIR8_DOWN then dy = 1.0
      else dy = 1.0
      end
    end
    len = Math.sqrt(dx * dx + dy * dy)
    dx /= len if len > 0
    dy /= len if len > 0
    base = Math.atan2(dy, dx) + Math::PI + angle_offset.to_f
    [@hero.x + Math.cos(base) * distance.to_f, @hero.y + Math.sin(base) * distance.to_f]
  rescue
    [@hero.x, @hero.y + distance.to_f]
  end

  def event_baby_shot_cooldown(baby)
    key = baby.instance_variable_get(:@baby_key)
    data = BABY_EVENT_DATA[key] || {}
    skill_id = data[:skill]
    skill = PokemonSurvivor::SKILLS[skill_id] || {}
    base = (skill[:cooldown] || 0.72).to_f + 0.36
    [[base * @cooldown_mult.to_f * (@skill_cooldown_mult[skill_id] || 1.0).to_f, 0.42].max, 2.2].min
  rescue
    1.0
  end

  def spawn_event_baby_projectile(baby)
    target = nearest_enemy_to(baby.x, baby.y, 360)
    angle = target ? Math.atan2(target.y - baby.y, target.x - baby.x) : ((@timer.to_f * 2.1) % (Math::PI * 2.0))
    key = baby.instance_variable_get(:@baby_key)
    data = BABY_EVENT_DATA[key] || BABY_EVENT_DATA[:TOGEPI]
    skill_id = data[:skill]
    base_skill = PokemonSurvivor::SKILLS[skill_id] || PokemonSurvivor::SKILLS[:normal_shot]
    skill = base_skill.clone
    skill[:id] = skill_id
    skill[:name] = _INTL("{1} Support", data[:name].to_s)
    skill[:type] = data[:type] || skill[:type] || :NORMAL
    skill[:damage] = [(skill[:damage].to_i * 0.42).ceil, 4].max
    skill[:speed] = [(skill[:speed] || 5.0).to_f * ((@skill_speed_mult ||= Hash.new(1.0))[skill_id] || 1.0).to_f, 4.6].max
    skill[:pierce] = [[skill[:pierce].to_i + ((@skill_pierce_bonus ||= Hash.new(0))[skill_id] || 0).to_i, 1].max, 3].min
    shots = [[1 + @projectile_count_bonus.to_i + ((@skill_count_bonus ||= Hash.new(0))[skill_id] || 0).to_i, 1].max, 3].min
    spread = shots <= 1 ? 0.0 : 0.16
    shots.times do |i|
      offset = (i - ((shots - 1) / 2.0)) * spread
      spawn_projectile_from(baby.x, baby.y, angle + offset, skill) do |p|
        p.ttl = 1.7
        p.radius = PokemonSurvivor::PROJECTILE_RADIUS
      end
    end
  rescue
  end

  def nearest_enemy_to(x, y, radius)
    best = nil
    best_dist = radius.to_f * radius.to_f
    each_nearby_enemy_for(x, y, radius.to_f) do |enemy|
      next if !enemy || enemy.hp.to_i <= 0
      dist = point_distance_sq(x, y, enemy.x, enemy.y)
      if dist < best_dist
        best = enemy
        best_dist = dist
      end
    end
    best
  rescue
    nil
  end

  def open_sleep_reward(key)
    key = PokemonSurvivor.species_key(key)
    return if key.nil?
    @pending_sleep_reward_queue ||= []
    if @state == :play && !@pending_sleep_reward_key && !@sleep_reward_consume_start
      start_sleep_reward_choice(key)
      return
    end
    @pending_sleep_reward_queue << key if !@pending_sleep_reward_queue.include?(key) && @pending_sleep_reward_key != key
  rescue
    @pending_sleep_reward_queue ||= []
    @pending_sleep_reward_queue << key if key && !@pending_sleep_reward_queue.include?(key)
  end
  def start_sleep_reward_choice(key)
    @pending_sleep_reward_key = PokemonSurvivor.species_key(key)
    @sleep_reward_consume_start = nil
    @sleep_reward_consume_se_played = false
    @state = :sleep_reward
    draw_sleep_reward
  rescue
  end

  def sleep_reward_queue_blocked?(ignore_pending_upgrade = false)
    return true if @state && @state != :play
    pending_upgrade_block = (@pending_upgrade || @pending_upgrade_count.to_i > 0 || @upgrade_anim_mode)
    if @upgrades_exhausted && !(@pending_upgrade_queue || []).include?(:moves)
      pending_upgrade_block = !!@upgrade_anim_mode
    end
    return true if !ignore_pending_upgrade && pending_upgrade_block
    return true if @upgrade_anim_mode
    return true if @pending_evolution_stage || @evolution_anim
    false
  rescue
    true
  end

  def pending_sleep_reward?
    @pending_sleep_reward_queue ||= []
    !@pending_sleep_reward_queue.empty?
  rescue
    false
  end

  def process_pending_sleep_reward
    return false if !pending_sleep_reward?
    return false if @state && @state != :play
    return false if @pending_sleep_reward_key || @sleep_reward_consume_start
    return false if @upgrade_anim_mode || @pending_evolution_stage || @evolution_anim
    key = @pending_sleep_reward_queue.shift
    start_sleep_reward_choice(key)
    true
  rescue
    false
  end

  def update_sleep_reward
    if @sleep_reward_consume_start
      elapsed = (System.uptime rescue 0.0) - @sleep_reward_consume_start.to_f
      if elapsed >= 0.50 && !@sleep_reward_consume_se_played
        @sleep_reward_consume_se_played = true
        play_survivor_se(:sleep_reward_consume, "Survivor/Mining reveal", 0.25, PokemonSurvivor::SFX_UPGRADE_CONSUME_VOLUME, 118) rescue nil
      end
      if elapsed >= 0.94
        apply_sleep_reward(@pending_sleep_reward_key)
        PokemonSurvivor.gamepad_vibrate_event(:upgrade_take) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
        @pending_sleep_reward_key = nil
        @sleep_reward_consume_start = nil
        @sleep_reward_consume_se_played = false
        @state = :play
        if pending_sleep_reward? && !sleep_reward_queue_blocked?(true)
          key = @pending_sleep_reward_queue.shift
          start_sleep_reward_choice(key)
        else
          draw_game
        end
        return
      end
      draw_sleep_reward
      return
    end
    if survivor_confirm_triggered?
      @sleep_reward_consume_start = System.uptime rescue 0.0
      @sleep_reward_consume_se_played = false
      pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    end
    draw_sleep_reward
  rescue
    key = @pending_sleep_reward_key
    @pending_sleep_reward_key = nil
    @sleep_reward_consume_start = nil
    @sleep_reward_consume_se_played = false
    @pending_sleep_reward_queue ||= []
    @pending_sleep_reward_queue.unshift(key) if key && !@pending_sleep_reward_queue.include?(key)
    @state = :play
  end

  def apply_sleep_reward(key)
    key = PokemonSurvivor.species_key(key)
    data = sleep_event_data(key)
    return false if data.empty?
    ensure_passive_upgrade_defaults if respond_to?(:ensure_passive_upgrade_defaults)
    data[:apply].call(self) if data[:apply]
    @sleep_event_awakened_keys ||= []
    @sleep_event_awakened_keys << key if !@sleep_event_awakened_keys.include?(key)
    set_hero_item_flash(Color.new(255, 238, 168), 0.85) rescue nil
    true
  rescue
    false
  end

  def draw_sleep_reward
    draw_game(false)
    bmp = @sprites["overlay"].bitmap
    pbSetSystemFont(bmp)
    x = 28
    y = 54
    w = Graphics.width - 56
    h = Graphics.height - y - 48
    now = System.uptime rescue 0.0
    choosing = !!@sleep_reward_consume_start
    choose_elapsed = choosing ? (now - @sleep_reward_consume_start.to_f) : 0.0
    choose_out = [[choose_elapsed / 0.28, 0.0].max, 1.0].min
    consume = [[(choose_elapsed - 0.50) / 0.42, 0.0].max, 1.0].min
    bmp.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0, tower_mode? && @tower_fade_alpha.to_i >= 255 ? 255 : 105))
    if !choosing || choose_out < 1.0
      panel_y = y + (choosing ? (choose_out * 42).to_i : 0)
      draw_panel(bmp, x, panel_y, w, h, Color.new(255, 224, 92), Color.new(19, 31, 53)) rescue draw_soft_badge(bmp, x, panel_y, w, h, Color.new(18, 24, 38, 235))
      title_x = x + 16
      title_y = panel_y + 12
      title_w = w - 32
      draw_pixel_round_rect(bmp, title_x, title_y, title_w, 34, Color.new(8, 13, 26)) rescue nil
      draw_text_box_ellipsis(bmp, _INTL("Awakened blessing"), title_x + 8, title_y + 7, title_w - 16, 22, Color.new(255, 238, 164), Color.new(30, 24, 20), 2)
    end
    card_w = (w - 34) / 3
    card_h = h - 66
    cx = x + ((w - card_w) / 2)
    cy = y + 52
    cx += (Math.sin(consume * Math::PI * 8.0) * (1.0 - consume) * 4).to_i if consume > 0
    draw_sleep_reward_slot(bmp, @pending_sleep_reward_key, cx, cy, card_w, card_h, true, consume, choosing)
    draw_help(bmp, [[:confirm, _INTL("Claim")]]) if respond_to?(:draw_help) && !choosing
    draw_tv_filter(bmp) if respond_to?(:draw_tv_filter) && PokemonSurvivor.performance_option?(:tv_filter)
  rescue
  end

def draw_sleep_reward_slot(bitmap, key, x, y, w, h, selected, closing = 0.0, chosen = false)
  key = PokemonSurvivor.species_key(key)
  data = sleep_event_data(key)
  type = data[:type] || :NORMAL
  accent = type_color(type) rescue Color.new(132, 214, 255)
  rarity_col = rarity_color(:epic) rescue Color.new(196, 122, 255)
  pulse = selected ? ((Math.sin((System.uptime rescue 0.0) * 8.0) + 1.0) * 0.5) : 0.0
  bg = selected ? Color.new(46 + (pulse * 14).to_i, 64 + (pulse * 16).to_i, 98 + (pulse * 18).to_i) : Color.new(18, 29, 48)
  draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(3, 6, 13))
  draw_pixel_round_rect(bitmap, x + 1, y + 1, w - 2, h - 2, rarity_col)
  draw_pixel_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, Color.new(8, 13, 26))
  draw_pixel_round_rect(bitmap, x + 3, y + 3, w - 6, h - 6, bg)
  bitmap.fill_rect(x + 7, y + 6, w - 14, 3, brighten_color(accent, 22)) if respond_to?(:brighten_color)
  icon = cached_event_sleep_icon(key)
  if icon && !icon.disposed?
    icon_x = x + ((w - icon.width) / 2)
    icon_y = y + 20
    bitmap.blt(icon_x, icon_y, icon, Rect.new(0, 0, icon.width, icon.height), 255)
  else
    source = cached_event_sleep_bitmap(key, false)
    PokemonSurvivor.draw_character_centered(bitmap, source, x + (w / 2), y + 42, PokemonSurvivor::DIR8_DOWN, 0, 1.0, PokemonSurvivor::CHARSET_8_DIRECTIONS) if source
  end
  draw_soft_badge(bitmap, x + 10, y + 82, w - 20, 24, Color.new(10, 17, 31)) rescue bitmap.fill_rect(x + 10, y + 82, w - 20, 24, Color.new(10, 17, 31))
  draw_text_box(bitmap, _INTL("Run Boost"), x + 10, y + 84, w - 20, 20, Color.new(122, 255, 176), Color.new(24, 24, 32), 2)
  bitmap.fill_rect(x + 8, y + 108, w - 16, 2, accent)
  draw_scrolling_wrapped_text(bitmap, _INTL(data[:desc].to_s), x + 10, y + 120, w - 20, h - 130, 22, Color.new(220, 226, 240), Color.new(40, 40, 48), selected && closing <= 0.0 ? [:sleep, key] : nil) rescue draw_wrapped_text(bitmap, _INTL(data[:desc].to_s), x + 10, y + 120, w - 20, 22, 3, Color.new(220, 226, 240))
  if chosen && closing.to_f > 0
    burn_h = [(h * (closing.to_f ** 1.12)).to_i, h - 6].min
    ember_h = [(h * ([[closing.to_f - 0.08, 0.0].max, 1.0].min ** 1.05)).to_i, h - 8].min
    erase_y = y + h - 5 - burn_h
    ember_y = y + h - 3 - ember_h
    clear_overlay_area(bitmap, x - 2, erase_y, w + 4, burn_h + 6) if burn_h > 0 && respond_to?(:clear_overlay_area)
    if ember_h > 0 && ember_y > y + 4
      bitmap.fill_rect(x + 6, ember_y, w - 12, 3, Color.new(255, 238, 160))
      bitmap.fill_rect(x + 9, ember_y + 3, w - 18, 2, Color.new(255, 154, 62))
    end
  end
rescue
end
  def update_baby_choice
    if @baby_choice_consume_start
      elapsed = (System.uptime rescue 0.0) - @baby_choice_consume_start.to_f
      if elapsed >= 0.94
        choice = (@pending_baby_choice || [])[@baby_choice_pending_index.to_i]
        set_event_baby(choice) if choice
        @pending_baby_choice = nil
        @baby_choice_consume_start = nil
        @baby_choice_pending_index = nil
        @state = :play
        draw_game
        return
      end
      draw_baby_choice
      return
    end
    if Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)
      @baby_choice_index = @baby_choice_index.to_i == 0 ? 1 : 0
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
    elsif survivor_confirm_triggered?
      @baby_choice_pending_index = @baby_choice_index.to_i
      @baby_choice_consume_start = System.uptime rescue 0.0
      pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    elsif survivor_cancel_triggered?
      @baby_choice_pending_index = 0
      @baby_choice_consume_start = System.uptime rescue 0.0
      pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
    end
    draw_baby_choice
  rescue
    @pending_baby_choice = nil
    @baby_choice_consume_start = nil
    @baby_choice_pending_index = nil
    @state = :play
  end

  def draw_baby_choice
    draw_game(false)
    bmp = @sprites["overlay"].bitmap
    pbSetSystemFont(bmp)
    x = 28
    y = 54
    w = Graphics.width - 56
    h = Graphics.height - y - 48
    bmp.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0, tower_mode? && @tower_fade_alpha.to_i >= 255 ? 255 : 105))
    choices = @pending_baby_choice || []
    gap = 10
    card_w = (w - 30 - gap) / 2
    card_h = h - 68
    now = System.uptime rescue 0.0
    choosing = !!@baby_choice_consume_start
    choose_elapsed = choosing ? (now - @baby_choice_consume_start.to_f) : 0.0
    choose_out = [[choose_elapsed / 0.28, 0.0].max, 1.0].min
    center_progress = [[(choose_elapsed - 0.28) / 0.22, 0.0].max, 1.0].min
    consume = [[(choose_elapsed - 0.50) / 0.42, 0.0].max, 1.0].min
    if !choosing || choose_out < 1.0
      panel_y = y + (choosing ? (choose_out * 42).to_i : 0)
      draw_panel(bmp, x, panel_y, w, h, Color.new(255, 224, 92), Color.new(19, 31, 53)) rescue draw_soft_badge(bmp, x, panel_y, w, h, Color.new(18, 24, 38, 235))
      title_x = x + 16
      title_y = panel_y + 12
      title_w = w - 32
      title_h = 34
      draw_pixel_round_rect(bmp, title_x, title_y, title_w, title_h, Color.new(8, 13, 26)) rescue nil
      draw_text_box_ellipsis(bmp, _INTL("Choose your companion"), title_x + 8, title_y + 7, title_w - 16, 22, Color.new(255, 238, 164), Color.new(30, 24, 20), 2)
    end
    choices.each_with_index do |baby, i|
      cx = x + 10 + (i * (card_w + gap))
      cy = y + 50
      chosen = choosing && i == @baby_choice_pending_index.to_i
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
      draw_baby_choice_slot(bmp, baby, cx, cy, card_w, card_h, i == @baby_choice_index.to_i, consume, chosen)
    end
    draw_help(bmp, [[:left, ""], [:right, _INTL("Choose")], [:confirm, _INTL("Keep")], [:cancel, _INTL("Old")]]) if respond_to?(:draw_help) && !choosing
    draw_tv_filter(bmp) if respond_to?(:draw_tv_filter) && PokemonSurvivor.performance_option?(:tv_filter)
  rescue
  end

  def draw_baby_choice_slot(bitmap, baby, x, y, w, h, selected, closing = 0.0, chosen = false)
    key = baby ? baby.instance_variable_get(:@baby_key) : nil
    data = BABY_EVENT_DATA[key] || {}
    type = data[:type] || (baby && baby.attack_type) || :NORMAL
    accent = type_color(type) rescue Color.new(132, 214, 255)
    rarity_col = rarity_color(:super_rare) rescue Color.new(255, 210, 92)
    pulse = selected ? ((Math.sin((System.uptime rescue 0.0) * 8.0) + 1.0) * 0.5) : 0.0
    bg = selected ? Color.new(46 + (pulse * 14).to_i, 64 + (pulse * 16).to_i, 98 + (pulse * 18).to_i) : Color.new(18, 29, 48)
    draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(3, 6, 13))
    draw_pixel_round_rect(bitmap, x + 1, y + 1, w - 2, h - 2, rarity_col)
    draw_pixel_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, Color.new(8, 13, 26))
    draw_pixel_round_rect(bitmap, x + 3, y + 3, w - 6, h - 6, bg)
    bitmap.fill_rect(x + 7, y + 6, w - 14, 3, brighten_color(accent, 22)) if respond_to?(:brighten_color)
    icon = cached_baby_event_icon(key.to_s, baby && baby.instance_variable_get(:@baby_shiny))
    icon_w = icon && !icon.disposed? ? icon.width : 0
    icon_h = icon && !icon.disposed? ? icon.height : 0
    icon_x = x + 12
    icon_y = y + 13
    bitmap.blt(icon_x, icon_y, icon, Rect.new(0, 0, icon_w, icon_h), 255) if icon && !icon.disposed?
    title_x = x + 20 + [icon_w, 32].max
    draw_text_box_ellipsis(bitmap, _INTL(data[:name].to_s), title_x, y + 14, w - (title_x - x) - 12, 26, rarity_col, Color.new(24, 24, 32), false)
    category_fill = Color.new([accent.red / 2 + 34, 255].min, [accent.green / 2 + 34, 255].min, [accent.blue / 2 + 34, 255].min)
    badge_text = baby.equal?(@event_baby) ? _INTL("Current") : _INTL("New")
    type_badge_w = [[w - (title_x - x) - 24, 72].max, 138].min
    draw_soft_badge(bitmap, title_x, y + 46, type_badge_w, 22, category_fill)
    draw_text_box(bitmap, type_name(type), title_x + 6, y + 48, type_badge_w - 12, 20, Color.white, Color.new(40, 40, 48), 2)
    status_w = 96
    status_x = title_x
    status_y = y + 72
    draw_soft_badge(bitmap, status_x, status_y, status_w, 22, Color.new(10, 17, 31)) rescue bitmap.fill_rect(status_x, status_y, status_w, 22, Color.new(10, 17, 31))
    draw_text_box(bitmap, badge_text, status_x + 4, status_y + 2, status_w - 8, 20, Color.new(122, 255, 176), Color.new(24, 24, 32), 2)
    bitmap.fill_rect(x + 8, y + 102, w - 16, 2, accent)
    draw_scrolling_wrapped_text(bitmap, _INTL(data[:desc].to_s), x + 10, y + 114, w - 20, h - 124, 22, Color.new(220, 226, 240), Color.new(40, 40, 48), selected && closing <= 0.0 ? [:baby, baby.object_id] : nil) rescue draw_wrapped_text(bitmap, _INTL(data[:desc].to_s), x + 10, y + 114, w - 20, 22, 3, Color.new(220, 226, 240))
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

  def draw_random_events(bitmap)
    draw_event_egg(bitmap, @event_egg) if @event_egg
    draw_event_baby(bitmap, @event_baby) if @event_baby
    draw_event_sleep(bitmap, @event_sleep) if @event_sleep
    draw_event_egg_edge_indicator(bitmap) if @event_egg
    draw_event_sleep_edge_indicator(bitmap) if @event_sleep
  rescue
  end

  def draw_event_egg(bitmap, egg)
    return if !egg || !point_on_screen?(egg.x, egg.y, 64)
    state = egg.instance_variable_get(:@event_state) || :waiting
    hurt = egg.instance_variable_get(:@hurt_timer).to_f > 0
    source = hurt ? cached_event_bitmap("EGG_Hurt", 2) : (egg.moving ? egg.walk_bitmap : egg.idle_bitmap)
    frames = hurt ? 2 : (egg.moving ? 7 : 5)
    PokemonSurvivor.register_eight_direction_bitmap(source, frames) if source
    frame = event_entity_frame(egg, frames, hurt ? 14.0 : 6.0, hurt)
    zoom = 2.0
    opacity = state == :hatching && ((Graphics.frame_count / 4) % 2 == 0) ? 150 : 255
    draw_event_egg_activation_circle(bitmap, egg) if state == :waiting
    PokemonSurvivor.draw_character_centered(bitmap, source, world_screen_x(egg.x), world_screen_y(egg.y), egg.direction, frame, world_screen_zoom(zoom), PokemonSurvivor::CHARSET_8_DIRECTIONS) if source
    draw_event_egg_hp_bar(bitmap, egg) if state == :escort || state == :hatching
  rescue
  end

  def draw_event_egg_activation_circle(bitmap, egg)
    timer = egg.instance_variable_get(:@activate_timer).to_f
    return if timer <= 0.0
    rate = [[timer / EGG_EVENT_ACTIVATE_SECONDS.to_f, 0.0].max, 1.0].min
    circle = cached_event_egg_activation_circle(rate)
    return if !circle || circle.disposed?
    x = (world_screen_x(egg.x) - (circle.width / 2)).round
    y = (world_screen_y(egg.y + 2)).round
    bitmap.blt(x, y, circle, Rect.new(0, 0, circle.width, circle.height), 245)
  rescue
  end

  def cached_event_egg_activation_circle(rate)
    @event_egg_activation_circle_cache ||= {}
    step = [[(rate.to_f * 24).round, 0].max, 24].min
    cached = @event_egg_activation_circle_cache[step]
    return cached if cached && !cached.disposed?
    w = 86
    h = 36
    cx = (w - 1) / 2.0
    cy = (h - 1) / 2.0
    max_dist = 1.0
    bmp = Bitmap.new(w, h)
    fill_radius = step / 24.0
    edge = Color.new(24, 32, 48, 178)
    glow = Color.new(255, 232, 128, 218)
    core = Color.new(122, 255, 176, 210)
    glow = PokemonSurvivor.accessible_color(glow)
    core = PokemonSurvivor.accessible_color(core)
    0.upto(h - 1) do |yy|
      0.upto(w - 1) do |xx|
        nx = (xx - cx) / cx
        ny = (yy - cy) / cy
        dist = Math.sqrt((nx * nx) + (ny * ny))
        next if dist > max_dist
        if dist >= 0.84
          bmp.set_pixel(xx, yy, edge)
        elsif dist <= fill_radius
          blend = [[1.0 - (dist / [fill_radius, 0.01].max), 0.0].max, 1.0].min
          color = Color.new(
            (core.red + ((glow.red - core.red) * blend)).round,
            (core.green + ((glow.green - core.green) * blend)).round,
            (core.blue + ((glow.blue - core.blue) * blend)).round,
            210
          )
          bmp.set_pixel(xx, yy, color)
        else
          bmp.set_pixel(xx, yy, Color.new(8, 13, 24, 116))
        end
      end
    end
    @event_egg_activation_circle_cache[step] = bmp
    bmp
  rescue
    nil
  end

  def draw_event_sleep(bitmap, sleep)
    return if !sleep || !point_on_screen?(sleep.x, sleep.y, 64)
    state = sleep.instance_variable_get(:@event_state) || :waiting
    posing = state == :posing
    key = sleep.instance_variable_get(:@sleep_key)
    source = cached_event_sleep_bitmap(key, posing)
    frames = event_sleep_frame_count(key, posing)
    PokemonSurvivor.register_eight_direction_bitmap(source, frames) if source && posing
    frame = if posing
              elapsed = SLEEP_EVENT_POSE_SECONDS - sleep.instance_variable_get(:@pose_timer).to_f
              [[(elapsed * 8.0).floor, 0].max, frames - 1].min
            else
              ((@timer.to_f * 3.5).floor % [frames, 1].max)
            end
    draw_event_sleep_wake_zone(bitmap, sleep) if state == :guard
    draw_event_sleep_activation_circle(bitmap, sleep) if state == :waiting
    blink_hidden = sleep.instance_variable_get(:@hit_invuln).to_f > 0 && ((Graphics.frame_count / 4) % 2 == 0)
    if source && !blink_hidden
      if posing
        PokemonSurvivor.draw_character_centered(bitmap, source, world_screen_x(sleep.x), world_screen_y(sleep.y), sleep.direction, frame, world_screen_zoom(2.0), PokemonSurvivor::CHARSET_8_DIRECTIONS)
      else
        draw_event_sleep_single_row_sprite(bitmap, source, world_screen_x(sleep.x), world_screen_y(sleep.y), frame, frames, world_screen_zoom(2.0))
      end
    end
    draw_event_sleep_bars(bitmap, sleep) if state == :guard
  rescue
  end

  def draw_event_sleep_single_row_sprite(bitmap, source, x, y, frame, frames, zoom = 1.0)
    return if !bitmap || !source || source.disposed?
    frames = [frames.to_i, 1].max
    frame_w = [source.width / frames, 1].max
    frame_h = source.height
    col = [[frame.to_i, 0].max, frames - 1].min
    src = Rect.new(col * frame_w, 0, frame_w, frame_h)
    w = (frame_w * zoom.to_f).round
    h = (frame_h * zoom.to_f).round
    rect = Rect.new((x - w / 2).round, (y - h / 2 + PokemonSurvivor::CHARACTER_VISUAL_Y_OFFSET).round, w, h)
    bitmap.stretch_blt(rect, source, src)
  rescue
  end

def draw_event_sleep_wake_zone(bitmap, sleep)
  return if !sleep || !@hero
  radius = SLEEP_EVENT_ACTIVATE_RADIUS.to_i
  inside = point_distance_sq(sleep.x, sleep.y, @hero.x, @hero.y) <= SLEEP_EVENT_ACTIVATE_RADIUS * SLEEP_EVENT_ACTIVATE_RADIUS
  zone = cached_event_sleep_wake_zone(radius, inside)
  return if !zone || zone.disposed?
  x = (world_screen_x(sleep.x) - radius).round
  y = (world_screen_y(sleep.y + PokemonSurvivor::CHARACTER_VISUAL_Y_OFFSET) - radius).round
  bitmap.blt(x, y, zone, Rect.new(0, 0, zone.width, zone.height), 255)
rescue
end

  def cached_event_sleep_wake_zone(radius, active = false)
    @event_sleep_wake_zone_cache ||= {}
    key = [radius.to_i, active ? 1 : 0, PokemonSurvivor.color_accessibility_mode]
    cached = @event_sleep_wake_zone_cache[key]
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
    @event_sleep_wake_zone_cache[key] = bmp
    bmp
  rescue
    nil
  end
  def draw_event_sleep_activation_circle(bitmap, sleep)
    timer = sleep.instance_variable_get(:@activate_timer).to_f
    return if timer <= 0.0
    rate = [[timer / SLEEP_EVENT_ACTIVATE_SECONDS.to_f, 0.0].max, 1.0].min
    circle = cached_event_egg_activation_circle(rate)
    return if !circle || circle.disposed?
    x = (world_screen_x(sleep.x) - (circle.width / 2)).round
    y = (world_screen_y(sleep.y + 2)).round
    bitmap.blt(x, y, circle, Rect.new(0, 0, circle.width, circle.height), 245)
  rescue
  end

  def draw_event_sleep_bars(bitmap, sleep)
    w = 50
    h = 6
    z = run_view_zoom
    w = [(w * z).round, 12].max
    h = [(h * z).round, 4].max
    x = (world_screen_x(sleep.x) - w / 2).round
    y = (world_screen_y(sleep.y + 28)).round
    hp_rate = [[sleep.hp.to_f / [sleep.max_hp.to_f, 1.0].max, 0.0].max, 1.0].min
    draw_enemy_status_bar(bitmap, x, y, w, h, hp_rate, enemy_hp_bar_color(hp_rate)) if respond_to?(:draw_enemy_status_bar)
    draw_event_sleep_wake_bar(bitmap, sleep, x, y + h, w, h)
  rescue
  end

  def draw_event_sleep_wake_bar(bitmap, sleep, x, y, w, h)
    rate = event_sleep_wake_rate(sleep)
    color = Color.new(184, 126, 255)
    color = Color.new(255, 230, 104) if rate >= 0.82
    if respond_to?(:draw_enemy_status_bar)
      draw_enemy_status_bar(bitmap, x, y, w, h, rate, color)
    else
      bitmap.fill_rect(x, y, w, h, Color.new(20, 20, 28))
      bitmap.fill_rect(x, y, (w * rate).round, h, color)
    end
  rescue
  end

  def draw_event_sleep_edge_indicator(bitmap)
    sleep = @event_sleep
    return if !sleep || point_on_screen?(sleep.x, sleep.y, 48)
    frame = (((@timer || 0.0) * 12.0).floor)
    pos = special_enemy_edge_indicator_position(sleep)
    if pos
      draw_vfx_frame(bitmap, "VFX_QUESTION_SLEEP", pos[0], pos[1], 1.0, pos[2], nil, frame)
    end
  rescue
  end

def cached_event_sleep_bitmap(key, pose = false)
  suffix = pose ? "Pose" : "Sleep"
  name = "#{PokemonSurvivor.species_key(key)}_#{suffix}"
  cached_bitmap(PokemonSurvivor::EVENT_SLEEP_DIR, name)
rescue
  nil
end

def cached_event_sleep_icon(key)
  name = "#{PokemonSurvivor.species_key(key)}_Icon"
  cached_bitmap(PokemonSurvivor::EVENT_SLEEP_DIR, name)
rescue
  nil
end

  def event_sleep_frame_count(key, pose = false)
    frames = (PokemonSurvivor::EVENT_SLEEP_FRAME_COUNTS[PokemonSurvivor.species_key(key)] rescue nil) || [4, 4]
    pose ? frames[0].to_i : frames[1].to_i
  rescue
    4
  end

  def draw_event_baby(bitmap, baby)
    return if !baby || !point_on_screen?(baby.x, baby.y, 64)
    source = baby.moving ? baby.walk_bitmap : baby.idle_bitmap
    frames = event_baby_frame_count(baby.instance_variable_get(:@baby_key), baby.moving)
    PokemonSurvivor.register_eight_direction_bitmap(source, frames) if source
    frame = event_entity_frame(baby, frames, baby.moving ? 7.5 : 5.5, false)
    PokemonSurvivor.draw_character_centered(bitmap, source, world_screen_x(baby.x), world_screen_y(baby.y), baby.direction, frame, world_screen_zoom(2.0), PokemonSurvivor::CHARSET_8_DIRECTIONS) if source
    draw_event_baby_hp_bar(bitmap, baby)
  rescue
  end


  def draw_event_baby_hp_bar(bitmap, baby)
    return if !baby || baby.max_hp.to_i <= 1
    w = 42
    h = 6
    z = run_view_zoom
    w = [(w * z).round, 12].max
    h = [(h * z).round, 4].max
    x = (world_screen_x(baby.x) - (w / 2)).round
    y = (world_screen_y(baby.y + 23)).round
    y = [[y, 0].max, Graphics.height - h].min
    hp_rate = [[baby.hp.to_f / [baby.max_hp.to_f, 1.0].max, 0.0].max, 1.0].min
    draw_enemy_status_bar(bitmap, x, y, w, h, hp_rate, enemy_hp_bar_color(hp_rate)) if respond_to?(:draw_enemy_status_bar)
  rescue
  end
  def event_entity_frame(entity, frames, fps, once = false)
    frames = [frames.to_i, 1].max
    if once
      elapsed = EGG_EVENT_HURT_SECONDS - entity.instance_variable_get(:@hurt_timer).to_f
      return [[(elapsed * fps.to_f).floor, 0].max, frames - 1].min
    end
    ((@timer.to_f * fps.to_f).floor % frames)
  rescue
    0
  end

  def draw_event_egg_hp_bar(bitmap, egg)
    w = 46
    h = 6
    z = run_view_zoom
    w = [(w * z).round, 12].max
    h = [(h * z).round, 4].max
    x = (world_screen_x(egg.x) - w / 2).round
    y = (world_screen_y(egg.y + 28)).round
    hp_rate = [[egg.hp.to_f / [egg.max_hp.to_f, 1.0].max, 0.0].max, 1.0].min
    draw_enemy_status_bar(bitmap, x, y, w, h, hp_rate, enemy_hp_bar_color(hp_rate)) if respond_to?(:draw_enemy_status_bar)
    draw_event_egg_hatch_bar(bitmap, egg, x, y + h, w, h)
  rescue
  end

  def draw_event_egg_hatch_bar(bitmap, egg, x, y, w, h)
    rate = event_egg_hatch_rate(egg)
    color = Color.new(92, 186, 255)
    color = Color.new(255, 230, 104) if rate >= 0.82
    if respond_to?(:draw_enemy_status_bar)
      draw_enemy_status_bar(bitmap, x, y, w, h, rate, color)
    else
      bitmap.fill_rect(x, y, w, h, Color.new(3, 6, 13, 210))
      bitmap.fill_rect(x + 2, y + 2, ((w - 4) * rate).round, h - 4, color)
    end
  rescue
  end

  def draw_event_egg_edge_indicator(bitmap)
    egg = @event_egg
    return if !egg || egg.hp.to_i <= 0 || point_on_screen?(egg.x, egg.y, 48)
    frame = (((@timer || 0.0) * 12.0).floor)
    pos = special_enemy_edge_indicator_position(egg)
    if pos
      draw_vfx_frame(bitmap, "VFX_QUESTION_EGG", pos[0], pos[1], 1.0, pos[2], nil, frame)
    end
  rescue
  end

  def cached_event_bitmap(name, frames = nil)
    bmp = cached_bitmap(PokemonSurvivor::EVENT_DIR, name)
    PokemonSurvivor.register_eight_direction_bitmap(bmp, frames) if bmp && frames.to_i > 0
    bmp
  rescue
    nil
  end

  def cached_baby_event_bitmap(name, idle = false, shiny = false)
    frames = event_baby_frame_count(name, !idle)
    filename = idle ? "#{name}_Idle" : name.to_s
    dirs = []
    dirs << PokemonSurvivor::EVENT_BABY_SHINY_DIR if shiny && PokemonSurvivor.const_defined?(:EVENT_BABY_SHINY_DIR)
    dirs << PokemonSurvivor::EVENT_BABY_DIR
    bmp = nil
    dirs.each do |dir|
      bmp = cached_bitmap(dir, filename)
      break if bmp && !bmp.disposed?
    end
    PokemonSurvivor.register_eight_direction_bitmap(bmp, frames) if bmp && frames.to_i > 0
    bmp
  rescue
    nil
  end

  def cached_baby_event_icon(name, shiny = false)
    dirs = []
    dirs << PokemonSurvivor::EVENT_BABY_SHINY_DIR if shiny && PokemonSurvivor.const_defined?(:EVENT_BABY_SHINY_DIR)
    dirs << PokemonSurvivor::EVENT_BABY_DIR
    dirs.each do |dir|
      bmp = cached_bitmap(dir, "#{name}_Icon")
      return bmp if bmp && !bmp.disposed?
    end
    nil
  rescue
    nil
  end
  def event_baby_frame_count(name, walk = true)
    key = PokemonSurvivor.species_key(name)
    data = PokemonSurvivor::EVENT_BABY_FRAME_COUNTS[key] || [4, 4]
    walk ? data[0].to_i : data[1].to_i
  rescue
    4
  end

end











































