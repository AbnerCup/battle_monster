#===============================================================================
# Pokemon Survivor - Dynamic level pressure
# Scales enemy stats upward when permanent progression or fast leveling makes a
# run outpace its intended danger curve.
#===============================================================================

module PokemonSurvivor
  DYNAMIC_LEVEL_PRESSURE_MODES = [:classic, :tower, :endless]
end

class Scene_PokemonSurvivor
  alias spawn_enemy_without_dynamic_level_pressure spawn_enemy unless method_defined?(:spawn_enemy_without_dynamic_level_pressure)
  def spawn_enemy(kind, forced_name = nil)
    before_count = @enemies ? @enemies.length : 0
    spawn_enemy_without_dynamic_level_pressure(kind, forced_name)
    return if !@enemies || @enemies.length <= before_count
    @enemies[before_count..-1].each { |enemy| apply_dynamic_level_pressure_to_enemy(enemy) }
  rescue
    # A failed post-spawn adjustment must never spawn a second enemy.
    nil
  end

  def dynamic_level_pressure_enabled?
    return false if rush_mode? rescue false
    PokemonSurvivor::DYNAMIC_LEVEL_PRESSURE_MODES.include?(@run_mode)
  rescue
    false
  end

  def dynamic_level_pressure_seconds
    seconds = @timer.to_i
    seconds = endless_pressure_seconds(seconds) if endless_mode? && respond_to?(:endless_pressure_seconds)
    [seconds, 0].max
  rescue
    [@timer.to_i, 0].max
  end

  def dynamic_level_pressure_expected_level
    seconds = dynamic_level_pressure_seconds
    level = case @run_mode
            when :classic
              1.0 + (seconds / 7.7)
            when :tower
              floor = [@tower_floor.to_i, 1].max
              1.0 + [seconds / 9.2, floor * 4.4].max
            when :endless
              stage = respond_to?(:endless_difficulty_stage) ? endless_difficulty_stage.to_i : (seconds / 300)
              1.0 + (seconds / 7.2) + ([stage - 4, 0].max * 8.5)
            else
              @level.to_f
            end
    [level, 8.0].max
  rescue
    [@level.to_f, 8.0].max
  end

  def dynamic_shop_progress_ratio(tree = :standard)
    @dynamic_shop_progress_cache ||= {}
    key = tree || :standard
    return @dynamic_shop_progress_cache[key] if @dynamic_shop_progress_cache.key?(key)
    upgrades = PokemonSurvivor.shop_upgrades(tree) rescue []
    total = 0
    bought = 0
    upgrades.each do |upgrade|
      next if !upgrade || upgrade[:infinite]
      max = (upgrade[:values] || []).length
      next if max <= 0
      total += max
      bought += [[PokemonSurvivor.shop_upgrade_level(upgrade[:id]).to_i, 0].max, max].min
    end
    @dynamic_shop_progress_cache[key] = total > 0 ? (bought.to_f / total.to_f) : 0.0
  rescue
    0.0
  end

  def dynamic_training_progress_ratio
    pokemon = @hero_base_name || @hero_name || (@hero && @hero.name)
    @dynamic_training_progress_cache ||= {}
    key = PokemonSurvivor.species_key(pokemon) rescue pokemon.to_s
    return @dynamic_training_progress_cache[key] if @dynamic_training_progress_cache.key?(key)
    upgrades = PokemonSurvivor::POKEMON_TRAINING_UPGRADES rescue []
    total = 0
    bought = 0
    upgrades.each do |upgrade|
      next if !upgrade || upgrade[:id] == :training_shiny
      max = (upgrade[:values] || []).length
      next if max <= 0
      total += max
      bought += [[PokemonSurvivor.pokemon_training_level(pokemon, upgrade[:id]).to_i, 0].max, max].min
    end
    if PokemonSurvivor.respond_to?(:pokemon_shiny_active?) && PokemonSurvivor.pokemon_shiny_active?(pokemon)
      bought += 4
      total += 4
    end
    @dynamic_training_progress_cache[key] = total > 0 ? (bought.to_f / total.to_f) : 0.0
  rescue
    0.0
  end

  def dynamic_permanent_progress_pressure
    return 0.0 if endless_mode? && !PokemonSurvivor.respond_to?(:shop_upgrades)
    standard = dynamic_shop_progress_ratio(:standard)
    endless = endless_mode? ? dynamic_shop_progress_ratio(:endless) : 0.0
    training = dynamic_training_progress_ratio
    equipment = 0.0
    equipment = 0.16 if PokemonSurvivor.respond_to?(:equipped_item_for) && PokemonSurvivor.equipped_item_for(@hero_base_name || @hero_name)
    tree_pressure = endless_mode? ? (standard * 0.35 + endless * 0.45) : (standard * 0.55)
    raw = tree_pressure + (training * 0.55) + equipment
    time_factor = case @run_mode
                  when :classic
                    [[@timer.to_f / 360.0, 0.40].max, 1.0].min
                  when :tower
                    [[@tower_floor.to_i / 18.0, 0.35].max, 1.0].min
                  when :endless
                    [[@timer.to_f / 900.0, 0.35].max, 1.0].min
                  else
                    1.0
                  end
    [raw * time_factor, 1.65].min
  rescue
    0.0
  end

  def dynamic_level_pressure_rate
    return 0.0 if !dynamic_level_pressure_enabled?
    seconds = [@timer.to_f, 1.0].max
    return 0.0 if seconds < 25.0 && @run_mode != :tower
    bucket = (seconds * 2.0).floor
    cache_key = [@run_mode, bucket, @level.to_i, @tower_floor.to_i]
    if @dynamic_level_pressure_rate_cache_key == cache_key
      return @dynamic_level_pressure_rate_cache_value.to_f
    end
    current = [@level.to_i, 1].max.to_f
    expected = dynamic_level_pressure_expected_level
    over_ratio = current > expected ? ((current - expected) / [expected, 1.0].max) : 0.0
    early_guard = [[seconds / 120.0, 0.42].max, 1.0].min
    snowball = over_ratio * early_guard
    snowball *= 1.20 if over_ratio >= 0.75
    snowball *= 1.35 if over_ratio >= 1.50
    permanent = dynamic_permanent_progress_pressure
    pressure = snowball + permanent
    value = [[pressure, 0.0].max, dynamic_level_pressure_cap].min
    @dynamic_level_pressure_rate_cache_key = cache_key
    @dynamic_level_pressure_rate_cache_value = value
    value
  rescue
    0.0
  end

  def dynamic_level_pressure_cap
    case @run_mode
    when :classic then 2.85
    when :tower then 3.10
    when :endless then 4.40
    else 0.0
    end
  end

  def dynamic_late_run_pressure
    seconds = dynamic_level_pressure_seconds
    case @run_mode
    when :classic
      [[(seconds - 420) / 480.0, 0.0].max, 1.0].min
    when :tower
      [[(@tower_floor.to_i - 24) / 26.0, 0.0].max, 1.0].min
    when :endless
      [[(seconds - 900) / 1800.0, 0.0].max, 1.0].min
    else
      0.0
    end
  rescue
    0.0
  end

  def dynamic_level_pressure_multipliers(enemy)
    pressure = dynamic_level_pressure_rate
    late = dynamic_late_run_pressure
    return [1.0, 1.0, 1.0] if pressure <= 0.0 && late <= 0.0
    boss_like = enemy && (enemy.kind == :boss || enemy.kind == :ultra_boss)
    elite_like = enemy && [:reinforced, :event_hunt].include?(enemy.kind)
    hp_weight = boss_like ? 0.82 : (elite_like ? 0.68 : 0.58)
    dmg_weight = boss_like ? 0.46 : 0.42
    spd_weight = boss_like ? 0.060 : 0.075
    hp_limit = boss_like ? 2.90 : (elite_like ? 2.20 : 1.75)
    dmg_limit = @run_mode == :endless ? 1.65 : 1.18
    spd_limit = @run_mode == :endless ? 0.28 : 0.22
    hp_mult = 1.0 + [pressure * hp_weight + late * (boss_like ? 0.45 : 0.28), hp_limit].min
    damage_mult = 1.0 + [pressure * dmg_weight + late * 0.22, dmg_limit].min
    speed_mult = 1.0 + [pressure * spd_weight + late * 0.035, spd_limit].min
    [hp_mult, damage_mult, speed_mult]
  rescue
    [1.0, 1.0, 1.0]
  end

  def apply_dynamic_level_pressure_to_enemy(enemy)
    return if !enemy || !dynamic_level_pressure_enabled?
    return if enemy.hp.to_i <= 0
    return if [:chest, :ultra_chest, :event_egg, :event_sleep, :event_baby].include?(enemy.kind)
    return if enemy.instance_variable_get(:@dynamic_level_pressure_applied)
    hp_mult, damage_mult, speed_mult = dynamic_level_pressure_multipliers(enemy)
    return if hp_mult <= 1.0 && damage_mult <= 1.0 && speed_mult <= 1.0
    enemy.max_hp = [(enemy.max_hp.to_i * hp_mult).round, enemy.max_hp.to_i, 1].max
    enemy.hp = enemy.max_hp
    enemy.damage = [(enemy.damage.to_i * damage_mult).round, enemy.damage.to_i, 1].max
    enemy.speed = enemy.speed.to_f * speed_mult
    enemy.instance_variable_set(:@dynamic_level_pressure_applied, true)
  rescue
  end
end
