#===============================================================================
# Porygon Rigging - persistent Pokemon settings and per-run pricing
#===============================================================================
module PokemonSurvivor
  PORYGON_MODES = [:classic, :rush, :tower, :endless].freeze
  PORYGON_EXCLUSION_COST = { eggs: 50, skills: 25, passives: 25 }.freeze
  PORYGON_SLEEP_COST = 50
  module_function

  def porygon_rigging_unlocked?(pokemon)
    return false unless hero_unlocked?(pokemon) && shop_tree_complete?(:standard)
    [:hero_finished?, :hero_boss_finished?, :hero_evolution_finished?,
     :hero_level_finished?, :hero_rush_finished?, :hero_tower_finished?].all? do |badge|
      send(badge, pokemon)
    end
  end

  def porygon_catalog(pokemon, category, mode = nil)
    case category
    when :eggs
      EVENT_BABY_KEYS.map { |key| species_key(key) }.uniq
    when :skills
      own = hero_data(pokemon)[:skill]
      localized_upgrade_pool.select { |u| u[:skill] && u[:skill] != own && skill_unlocked_for_learning?(u[:skill]) }.
        map { |u| u[:skill] }.uniq
    when :passives
      localized_upgrade_pool.reject do |u|
        u[:skill] || u[:target_skill] ||
          (mode && mode != :tower && [:floor_momentum, :boss_preparation].include?(u[:id])) ||
          (mode == :rush && [:max_hp_small, :max_hp, :lifesteal].include?(u[:id]))
      end.map { |u| u[:id] }.uniq
    when :sleep
      EVENT_SLEEP_KEYS.map { |key| species_key(key) }.uniq
    else
      []
    end
  end

  def porygon_default_settings
    { enabled: false, eggs: [], skills: [], passives: [], sleep: [] }
  end

  def porygon_normalize(pokemon, settings)
    settings = {} unless settings.is_a?(Hash)
    result = porygon_default_settings
    result[:enabled] = settings[:enabled] == true
    [:eggs, :skills, :passives].each do |category|
      catalog = porygon_catalog(pokemon, category)
      excluded = Array(settings[category]).select { |id| id.is_a?(String) || id.is_a?(Symbol) }.map(&:to_sym).uniq & catalog
      minimum = category == :eggs ? 2 : 6
      excluded = excluded.first([catalog.length - minimum, 0].max)
      result[category] = excluded
    end
    order = Array(settings[:sleep]).select { |id| id.is_a?(String) || id.is_a?(Symbol) }.map { |key| species_key(key) }.uniq
    catalog = porygon_catalog(pokemon, :sleep)
    result[:sleep] = order if order.length == catalog.length && (order - catalog).empty?
    result
  end

  def porygon_settings(pokemon)
    return porygon_default_settings unless porygon_rigging_unlocked?(pokemon)
    store = survivor_progress[:porygon_rigging]
    porygon_normalize(pokemon, store.is_a?(Hash) ? store[species_key(pokemon)] : nil)
  end

  def porygon_cost(pokemon, settings, mode)
    return 0 unless porygon_rigging_unlocked?(pokemon)
    return 0 unless PORYGON_MODES.include?(mode) && settings[:enabled]
    cost = [:eggs, :skills, :passives].sum do |category|
      (settings[category] & porygon_catalog(pokemon, category, mode)).length * PORYGON_EXCLUSION_COST[category]
    end
    cost + (mode != :tower && !settings[:sleep].empty? ? PORYGON_SLEEP_COST : 0)
  end
end
