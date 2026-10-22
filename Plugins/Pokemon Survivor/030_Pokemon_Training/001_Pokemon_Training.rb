#===============================================================================
# Pokemon Survivor - Pokemon Training
#===============================================================================

module PokemonSurvivor

  POKEMON_TRAINING_UPGRADES = [
    { id: :training_hp, name: "Sturdy Partner", desc: "This Pokemon starts every mode with higher max HP.", effect: :pokemon_max_hp_percent, values: [2, 4, 7, 10, 14], costs: [45, 95, 180, 330, 600], icon: "HP" },
    { id: :training_damage, name: "Battle Bond", desc: "This Pokemon deals more damage with all player abilities.", effect: :pokemon_damage_percent, values: [1, 3, 5, 8, 12], costs: [60, 130, 260, 480, 850], icon: "Atk" },
    { id: :training_speed, name: "Agile Habit", desc: "This Pokemon starts every mode with higher movement speed.", effect: :pokemon_speed_percent, values: [1, 3, 5, 7], costs: [45, 95, 190, 370], icon: "Speed" },
    { id: :training_pickup, name: "Pickup Practice", desc: "This Pokemon attracts nearby drops from farther away.", effect: :pokemon_pickup_percent, values: [6, 14, 24, 36], costs: [50, 115, 250, 520], icon: "Magnet" },
    { id: :training_burst, name: "Personal Pulse", desc: "This Pokemon charges Burst faster in every mode.", effect: :pokemon_burst_charge_percent, values: [2, 5, 9, 14], costs: [70, 155, 330, 700], icon: "Burst" },
    { id: :training_draft, name: "Favorite Draft", desc: "This Pokemon starts runs with extra rerolls and bans.", effect: :pokemon_draft_bonus, values: [1, 2], costs: [260, 720], icon: "Reroll" },
    { id: :training_equipment, name: "Equipment Slot", desc: "Unlocks one held item equipment slot for this Pokemon.", effect: :pokemon_equipment_slot, values: [1], costs: [1200], icon: "Revive" },
    { id: :training_shiny, name: "Shiny Form", desc: "Unlocks Shiny play and grants +31% EXP, damage, HP, speed, pickup range, contact resistance, and projectile resistance.", effect: :pokemon_shiny_unlock, values: [1], costs: [3000], icon: "Shiny", special: :core_unlock }
  ] unless const_defined?(:POKEMON_TRAINING_UPGRADES)

  POKEMON_TRAINING_CORE_EXCLUDED = [:training_shiny].freeze unless const_defined?(:POKEMON_TRAINING_CORE_EXCLUDED)

  module_function

  def training_translation_strings
    [
      _INTL("Candies"), _INTL("Pokemon Training"), _INTL("Training Core"),
      _INTL("Training for {1}"), _INTL("Permanent upgrades for this Pokemon only."),
      _INTL("Earned {1} Candies."), _INTL("Training"),
      _INTL("Sturdy Partner"), _INTL("This Pokemon starts every mode with higher max HP."),
      _INTL("Battle Bond"), _INTL("This Pokemon deals more damage with all player abilities."),
      _INTL("Agile Habit"), _INTL("This Pokemon starts every mode with higher movement speed."),
      _INTL("Pickup Practice"), _INTL("This Pokemon attracts nearby drops from farther away."),
      _INTL("Personal Pulse"), _INTL("This Pokemon charges Burst faster in every mode."),
      _INTL("Favorite Draft"), _INTL("This Pokemon starts runs with extra rerolls and bans."),
      _INTL("Equipment Slot"), _INTL("Unlocks one held item equipment slot for this Pokemon."),
      _INTL("Shiny Form"), _INTL("Unlocks Shiny play and grants +31% EXP, damage, HP, speed, pickup range, contact resistance, and projectile resistance."),
      _INTL("Complete this Pokemon training tree to unlock its Shiny form."),
      _INTL("Empty equipment slot"),
      _INTL("Normal"), _INTL("Shiny")
    ]
  rescue
    []
  end

  def candy_currency
    survivor_progress[:candy_currency].to_i
  rescue
    0
  end

  def add_candy_currency(amount)
    progress = survivor_progress
    gain = [amount.to_i, 0].max
    progress[:candy_currency] = [progress[:candy_currency].to_i + gain, 0].max
    gain
  rescue
    0
  end

  def spend_candy_currency(amount)
    progress = survivor_progress
    cost = [amount.to_i, 0].max
    return false if progress[:candy_currency].to_i < cost
    progress[:candy_currency] = [progress[:candy_currency].to_i - cost, 0].max
    true
  rescue
    false
  end

  def pokemon_training_data(id)
    POKEMON_TRAINING_UPGRADES.find { |upgrade| upgrade[:id] == id.to_sym }
  rescue
    nil
  end

  def pokemon_training_store(pokemon)
    progress = survivor_progress
    progress[:pokemon_training] = {} if !progress[:pokemon_training].is_a?(Hash)
    key = species_key(pokemon)
    progress[:pokemon_training][key] ||= {}
    progress[:pokemon_training][key]
  rescue
    {}
  end

  def pokemon_training_level(pokemon, id)
    pokemon_training_store(pokemon)[id.to_sym].to_i
  rescue
    0
  end

  def pokemon_training_max(id)
    data = pokemon_training_data(id)
    data ? data[:values].length : 0
  rescue
    0
  end

  def pokemon_training_discount_basis_points(pokemon, id = nil)
    return 0 if id && id.to_sym == :training_shiny
    return 1000 if hero_tower_finished?(pokemon)
    return 750 if hero_rush_finished?(pokemon)
    return 500 if hero_finished?(pokemon)
    0
  end

  def pokemon_training_cost_multiplier(pokemon)
    key = species_key(pokemon)
    if defined?(Titan::SEASONS) && Titan::SEASONS.each_value.any? { |season| season[:reward_pokemon] && species_key(season[:reward_pokemon]) == key }
      return 2
    end
    if defined?(Challenge::SEASONS) && Challenge::SEASONS.each_value.any? { |reward| reward && species_key(reward) == key }
      return 2
    end
    1
  end

  def pokemon_training_cost(pokemon, id, rank = nil)
    data = pokemon_training_data(id)
    level = rank.nil? ? pokemon_training_level(pokemon, id) : rank.to_i - 1
    return nil if !data || level < 0 || level >= data[:costs].length
    base = data[:costs][level].to_i
    discount = pokemon_training_discount_basis_points(pokemon, id)
    # Round up to whole Candies without exceeding the advertised discount.
    ((base * (10_000 - discount) + 9_999) / 10_000) * pokemon_training_cost_multiplier(pokemon)
  rescue
    nil
  end

  def pokemon_training_value(pokemon, id)
    data = pokemon_training_data(id)
    level = pokemon_training_level(pokemon, id)
    return 0 if !data || level <= 0
    data[:values][level - 1].to_i
  rescue
    0
  end

  def pokemon_training_effect_value(pokemon, effect)
    total = 0
    POKEMON_TRAINING_UPGRADES.each do |upgrade|
      next if upgrade[:effect] != effect
      total += pokemon_training_value(pokemon, upgrade[:id])
    end
    total
  rescue
    0
  end

  def pokemon_training_effect_multiplier(pokemon, effect)
    1.0 + (pokemon_training_effect_value(pokemon, effect).to_f / 100.0)
  rescue
    1.0
  end

  def pokemon_training_core_complete?(pokemon)
    POKEMON_TRAINING_UPGRADES.all? do |upgrade|
      next true if POKEMON_TRAINING_CORE_EXCLUDED.include?(upgrade[:id])
      pokemon_training_level(pokemon, upgrade[:id]) >= (upgrade[:values] || []).length
    end
  rescue
    false
  end

  def pokemon_shiny_unlocked?(pokemon)
    pokemon_training_level(pokemon, :training_shiny) > 0
  rescue
    false
  end

  def pokemon_equipment_slot_unlocked?(pokemon)
    pokemon_training_level(pokemon, :training_equipment) > 0
  rescue
    false
  end

  def buy_pokemon_training_upgrade(pokemon, id)
    data = pokemon_training_data(id)
    return false if !data
    if id.to_sym == :training_shiny
      return false if !pokemon_training_core_complete?(pokemon) || pokemon_shiny_unlocked?(pokemon)
    end
    level = pokemon_training_level(pokemon, id)
    return false if level >= data[:values].length
    cost = pokemon_training_cost(pokemon, id).to_i
    return false if !spend_candy_currency(cost)
    pokemon_training_store(pokemon)[id.to_sym] = level + 1
    true
  rescue
    false
  end


  def pokemon_shiny_active_store
    progress = survivor_progress
    progress[:pokemon_shiny_active] = {} if !progress[:pokemon_shiny_active].is_a?(Hash)
    progress[:pokemon_shiny_active]
  rescue
    {}
  end

  def pokemon_shiny_active?(pokemon)
    key = species_key(pokemon)
    pokemon_shiny_unlocked?(key) && pokemon_shiny_active_store[key].to_i > 0
  rescue
    false
  end

  def set_pokemon_shiny_active(pokemon, active)
    key = species_key(pokemon)
    return false if !pokemon_shiny_unlocked?(key)
    pokemon_shiny_active_store[key] = active ? 1 : 0
    true
  rescue
    false
  end

  def toggle_pokemon_shiny_active(pokemon)
    key = species_key(pokemon)
    set_pokemon_shiny_active(key, !pokemon_shiny_active?(key))
  rescue
    false
  end

  def shiny_asset_available?(name)
    !!resolve(HERO_SHINY_DIR, name)
  rescue
    false
  end

  def hero_graphics_folder(name, base_name = nil)
    base = species_key(base_name || name)
    asset = name.to_s
    if pokemon_alt_active?(base)
      alt_folder = pokemon_shiny_active?(base) ? HERO_ALT_SHINY_DIR : HERO_ALT_DIR
      return alt_folder if resolve(alt_folder, asset)
    end
    return HERO_SHINY_DIR if pokemon_shiny_active?(base) && shiny_asset_available?(asset)
    HERO_DIR
  rescue
    HERO_DIR
  end

  def candy_run_currency_reward(score, level, won = false)
    score_value = [score.to_i, 0].max
    level_value = [[level.to_i, 1].max, 9999].min
    score_part = Math.sqrt(score_value).to_i / 8
    level_part = (level_value / 2) + ([level_value - 100, 0].max / 5)
    base = score_part + level_part
    base = won ? ((base * 1.12).round + 12) : (base * 0.55).round
    [base, won ? 18 : 4].max
  rescue
    0
  end

  def pokemon_prestige_crystal_owned?(pokemon)
    key = species_key(pokemon)
    account = survivor_progress[:titan_online]
    account.is_a?(Hash) && account[:cosmetics].is_a?(Hash) &&
      account[:cosmetics][key] == :prestige_crystal
  end

  def pokemon_alt_available?(pokemon)
    pokemon_shiny_unlocked?(pokemon) && pokemon_prestige_crystal_owned?(pokemon)
  end

  def pokemon_alt_active?(pokemon)
    flags = survivor_progress[:pokemon_alt_active]
    flags.is_a?(Hash) && flags[species_key(pokemon)] == true && pokemon_alt_available?(pokemon)
  end

  def toggle_pokemon_alt_active(pokemon)
    key = species_key(pokemon)
    return false unless pokemon_alt_available?(key)
    active = pokemon_alt_active?(key)
    folder = pokemon_shiny_active?(key) ? HERO_ALT_SHINY_DIR : HERO_ALT_DIR
    return false if !active && !resolve(folder, key.to_s)
    progress = survivor_progress
    progress[:pokemon_alt_active] = {} unless progress[:pokemon_alt_active].is_a?(Hash)
    progress[:pokemon_alt_active][key] = !active
    true
  end
end

class Scene_PokemonSurvivor
  TRAINING_TILE_SIZE = 48
  TRAINING_CELL_SIZE = 64
  TRAINING_HEADER_H = 66
  TRAINING_FOOTER_H = 34
  TRAINING_INFO_H = 112

  remove_const(:TRAINING_TREE_LAYOUT) if const_defined?(:TRAINING_TREE_LAYOUT)
  remove_const(:TRAINING_TREE_LINKS) if const_defined?(:TRAINING_TREE_LINKS)

  TRAINING_TREE_LAYOUT = [
    [:training_pickup, 1, -1, 0], [:training_pickup, 2, -2, 0], [:training_pickup, 3, -3, 0], [:training_pickup, 4, -4, 0],
    [:training_hp, 1, -1, -1], [:training_hp, 2, -2, -1], [:training_hp, 3, -3, -1], [:training_hp, 4, -3, -2], [:training_hp, 5, -2, -2],
    [:training_speed, 1, -1, 1], [:training_speed, 2, -2, 1], [:training_speed, 3, -3, 1], [:training_speed, 4, -3, 2],
    [:training_damage, 1, 1, 0], [:training_damage, 2, 2, 0], [:training_damage, 3, 3, 0], [:training_damage, 4, 4, 0], [:training_damage, 5, 4, -1],
    [:training_burst, 1, 1, -1], [:training_burst, 2, 2, -1], [:training_burst, 3, 3, -1], [:training_burst, 4, 3, -2],
    [:training_draft, 1, 1, 1], [:training_draft, 2, 2, 1], [:training_equipment, 1, 3, 1]
  ] unless const_defined?(:TRAINING_TREE_LAYOUT)

  TRAINING_TREE_LINKS = [
    [:training_core, :training_pickup_1], [:training_core, :training_damage_1],
    [:training_pickup_1, :training_pickup_2], [:training_pickup_2, :training_pickup_3], [:training_pickup_3, :training_pickup_4],
    [:training_pickup_1, :training_hp_1], [:training_hp_1, :training_hp_2], [:training_hp_2, :training_hp_3], [:training_hp_3, :training_hp_4], [:training_hp_4, :training_hp_5],
    [:training_pickup_1, :training_speed_1], [:training_speed_1, :training_speed_2], [:training_speed_2, :training_speed_3], [:training_speed_3, :training_speed_4],
    [:training_damage_1, :training_damage_2], [:training_damage_2, :training_damage_3], [:training_damage_3, :training_damage_4], [:training_damage_4, :training_damage_5],
    [:training_damage_1, :training_burst_1], [:training_burst_1, :training_burst_2], [:training_burst_2, :training_burst_3], [:training_burst_3, :training_burst_4],
    [:training_damage_1, :training_draft_1], [:training_draft_1, :training_draft_2], [:training_draft_2, :training_equipment_1]
  ] unless const_defined?(:TRAINING_TREE_LINKS)


  def open_or_toggle_pokemon_training(pokemon = nil)
    key = PokemonSurvivor.species_key(pokemon || selected_hero_name)
    if PokemonSurvivor.pokemon_shiny_unlocked?(key)
      PokemonSurvivor.toggle_pokemon_shiny_active(key)
      refresh_pokemon_visual_selection
    else
      open_pokemon_training(key)
    end
  rescue
    open_pokemon_training(pokemon) rescue nil
  end

  def refresh_pokemon_visual_selection
    if @bitmaps
      @bitmaps.delete_if do |cache_key, bmp|
        match = cache_key.to_s.include?(PokemonSurvivor::HERO_DIR)
        bmp.dispose if match && bmp && !bmp.disposed?
        match
      end
    end
    @missing_hero_idle_cache = nil
    @confirming_hero = true
    pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    PokemonSurvivor.gamepad_vibrate_event(:shiny_toggle) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
    draw_select
  end

  def reset_prestige_visual_hold
    @prestige_hold_key = @prestige_hold_started = @prestige_hold_done = nil
  end

  def update_prestige_visual_hold
    key = PokemonSurvivor.species_key(selected_hero_name)
    unless @confirming_hero && PokemonSurvivor.hero_unlocked?(key) && PokemonSurvivor.pokemon_alt_available?(key)
      reset_prestige_visual_hold
      return false
    end
    reset_prestige_visual_hold if @prestige_hold_key && @prestige_hold_key != key
    if select_back_triggered?
      reset_prestige_visual_hold
      return false
    end
    if !@prestige_hold_key && select_action_triggered?
      @prestige_hold_key, @prestige_hold_started = key, System.uptime
      @prestige_hold_done = false
    end
    return false unless @prestige_hold_key
    if PokemonSurvivor.control_press?(:action)
      if !@prestige_hold_done && System.uptime - @prestige_hold_started >= 2.0
        @prestige_hold_done = true
        if PokemonSurvivor.toggle_pokemon_alt_active(key)
          refresh_pokemon_visual_selection
        else
          pbPlayBuzzerSE
        end
      end
      draw_select
    else
      short_press = !@prestige_hold_done
      reset_prestige_visual_hold
      open_or_toggle_pokemon_training(key) if short_press
    end
    true
  end

  def selected_hero_training_action_label
    key = PokemonSurvivor.species_key(selected_hero_name)
    if PokemonSurvivor.pokemon_alt_available?(key)
      short = PokemonSurvivor.pokemon_shiny_active?(key) ? _INTL("Normal") : _INTL("Shiny")
      held = PokemonSurvivor.pokemon_alt_active?(key) ? _INTL("Original") : _INTL("Alt")
      return _INTL("{1} / Hold: {2}", short, held)
    end
    return _INTL("Normal") if PokemonSurvivor.pokemon_shiny_active?(key)
    return _INTL("Shiny") if PokemonSurvivor.pokemon_shiny_unlocked?(key)
    _INTL("Training")
  rescue
    _INTL("Training")
  end
  def open_pokemon_training(pokemon = nil)
    @training_pokemon = PokemonSurvivor.species_key(pokemon || selected_hero_name)
    @training_index = 0
    @training_show_details = true if @training_show_details.nil?
    @training_bg_frame = 0
    @training_last_time = System.uptime rescue 0
    rebuild_training_tree_cache(true)
    center_training_on_selected
    @state = :pokemon_training
    pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    draw_pokemon_training
  rescue
    @state = :select
  end

  def close_pokemon_training
    @state = :select
    @confirming_hero = true
    pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
    draw_select
  rescue
  end

  def update_pokemon_training
    dirty = update_training_background_animation
    old = @training_index.to_i
    if Input.repeat?(Input::LEFT)
      move_training_tree_selection(-1, 0)
    elsif Input.repeat?(Input::RIGHT)
      move_training_tree_selection(1, 0)
    elsif Input.repeat?(Input::UP)
      move_training_tree_selection(0, -1)
    elsif Input.repeat?(Input::DOWN)
      move_training_tree_selection(0, 1)
    elsif training_details_triggered?
      @training_show_details = !@training_show_details
      dirty = true
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
    elsif survivor_confirm_triggered?
      buy_selected_training_upgrade
      return
    elsif survivor_cancel_triggered?
      close_pokemon_training
      return
    end
    if old != @training_index.to_i
      center_training_on_selected
      dirty = true
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
    end
    draw_pokemon_training if dirty
  rescue
    close_pokemon_training
  end

  def training_details_triggered?
    return PokemonSurvivor.control_trigger?(:action) if PokemonSurvivor.respond_to?(:control_trigger?)
    return true if Input.const_defined?(:ACTION) && Input.trigger?(Input::ACTION)
    false
  rescue
    false
  end

  def update_training_background_animation
    now = System.uptime rescue 0
    elapsed = now - (@training_last_time || now)
    return false if elapsed < (1.0 / 60.0)
    @training_last_time = now
    @training_bg_frame = @training_bg_frame.to_i + [(elapsed * 60).floor, 2].min
    true
  rescue
    @training_bg_frame = Graphics.frame_count / 2
    true
  end

  def training_root_node
    shiny = PokemonSurvivor.pokemon_training_data(:training_shiny)
    if shiny && PokemonSurvivor.pokemon_training_core_complete?(@training_pokemon)
      return { id: :training_core, root: true, upgrade: shiny, level: 1, x: 0, y: 0, icon: shiny[:icon], name: _INTL("Shiny Form"), desc: _INTL("Unlocks Shiny play and grants +31% EXP, damage, HP, speed, pickup range, contact resistance, and projectile resistance.") }
    end
    { id: :training_core, root: true, x: 0, y: 0, icon: "ICON_CANDY", name: _INTL("Training Core"), desc: _INTL("Permanent upgrades for this Pokemon only.") }
  rescue
    { id: :training_core, root: true, x: 0, y: 0 }
  end

  def rebuild_training_tree_cache(force = false)
    key = [@training_pokemon, PokemonSurvivor.pokemon_training_core_complete?(@training_pokemon), PokemonSurvivor.pokemon_shiny_unlocked?(@training_pokemon)]
    return if !force && @training_tree_cache_key == key && @training_all_nodes_cache
    nodes = [training_root_node]
    TRAINING_TREE_LAYOUT.each do |entry|
      upgrade_id, level, x, y = entry
      data = PokemonSurvivor.pokemon_training_data(upgrade_id)
      next if !data || level.to_i > (data[:values] || []).length
      nodes << { id: training_node_id(upgrade_id, level), upgrade: data, level: level, x: x, y: y, icon: data[:icon] }
    end
    @training_tree_cache_key = key
    @training_all_nodes_cache = nodes
    @training_node_pos_cache = {}
    @training_node_id_cache = {}
    nodes.each do |node|
      @training_node_pos_cache[[node[:x].to_i, node[:y].to_i]] = node
      @training_node_id_cache[node[:id]] = node
    end
    @training_link_cache = {}
    TRAINING_TREE_LINKS.each do |left, right|
      @training_link_cache[[left, right]] = true
      @training_link_cache[[right, left]] = true
    end
    @training_state_cache = nil
  rescue
    @training_all_nodes_cache = [training_root_node]
  end

  def invalidate_training_state_cache
    @training_state_cache = nil
  rescue
  end

  def training_node_id(id, level)
    "#{id}_#{level}".to_sym
  rescue
    id
  end

  def training_all_nodes
    rebuild_training_tree_cache if !@training_all_nodes_cache
    @training_all_nodes_cache || [training_root_node]
  rescue
    [training_root_node]
  end

  def selected_training_node
    nodes = training_all_nodes
    @training_index = [[@training_index.to_i, 0].max, nodes.length - 1].min
    nodes[@training_index]
  rescue
    nil
  end

  def training_node_at(x, y)
    rebuild_training_tree_cache if !@training_node_pos_cache
    @training_node_pos_cache[[x.to_i, y.to_i]]
  rescue
    nil
  end

  def training_connected_nodes?(a, b)
    return false if !a || !b
    rebuild_training_tree_cache if !@training_link_cache
    @training_link_cache[[a[:id], b[:id]]] == true
  rescue
    false
  end

  def move_training_tree_selection(dx, dy)
    nodes = training_all_nodes
    current = nodes[@training_index.to_i]
    return if !current
    cur_x = current[:x].to_i
    cur_y = current[:y].to_i
    candidates = nodes.each_with_index.select do |node, _i|
      next false if node.equal?(current)
      vx = node[:x].to_i - cur_x
      vy = node[:y].to_i - cur_y
      dx != 0 ? vx * dx > 0 : vy * dy > 0
    end
    target = candidates.min_by do |node, _i|
      vx = node[:x].to_i - cur_x
      vy = node[:y].to_i - cur_y
      dx != 0 ? (vx.abs + (vy.abs * 3)) : (vy.abs + (vx.abs * 3))
    end
    @training_index = target[1] if target
  rescue
  end

  def center_training_on_selected
    node = selected_training_node
    return if !node
    @training_camera_x = node[:x].to_i * TRAINING_CELL_SIZE
    @training_camera_y = node[:y].to_i * TRAINING_CELL_SIZE
  rescue
    @training_camera_x = 0
    @training_camera_y = 0
  end

  def training_screen_pos(node)
    info_h = @training_show_details == false ? 0 : TRAINING_INFO_H
    cx = Graphics.width / 2 + (node[:x].to_i * TRAINING_CELL_SIZE) - (@training_camera_x || 0)
    cy = TRAINING_HEADER_H + ((Graphics.height - TRAINING_HEADER_H - TRAINING_FOOTER_H - info_h) / 2) + (node[:y].to_i * TRAINING_CELL_SIZE) - (@training_camera_y || 0)
    [cx, cy]
  rescue
    [Graphics.width / 2, Graphics.height / 2]
  end

  def training_tree_clip_rect
    info_h = @training_show_details == false ? 0 : TRAINING_INFO_H
    Rect.new(10, TRAINING_HEADER_H + 6, Graphics.width - 20, Graphics.height - TRAINING_HEADER_H - TRAINING_FOOTER_H - info_h - 8)
  end

  def draw_pokemon_training
    bmp = @sprites["screen"].bitmap
    over = @sprites["overlay"].bitmap
    bmp.clear
    over.clear
    pbSetSystemFont(bmp)
    draw_training_background(bmp)
    draw_training_tree_panel(bmp)
    draw_training_links(bmp)
    draw_training_nodes(bmp)
    draw_training_header(bmp)
    draw_training_info(bmp) if @training_show_details != false
    draw_training_footer(over)
    draw_tv_filter(over)
  rescue
  end

  def draw_training_background(bitmap)
    bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(18, 22, 34))
  rescue
  end

  def draw_training_header(bitmap)
    draw_pixel_round_rect(bitmap, 8, 8, Graphics.width - 16, TRAINING_HEADER_H - 12, Color.new(18, 22, 34))
    draw_pixel_round_rect(bitmap, 10, 10, Graphics.width - 20, TRAINING_HEADER_H - 16, Color.new(34, 42, 62))
    draw_pixel_round_rect(bitmap, 12, 12, Graphics.width - 24, TRAINING_HEADER_H - 20, Color.new(44, 54, 78))
    center_y = 12 + ((TRAINING_HEADER_H - 20) / 2)
    name = PokemonSurvivor.species_name(@training_pokemon)
    draw_training_header_pokemon_icon(bitmap, 38, center_y)
    draw_shop_scrolling_text(bitmap, _INTL("Training for {1}", name), 72, center_y - 13, Graphics.width - 270, 26, SHOP_GOLD, SHOP_SHADOW_COLOR, false)
    draw_fragment_value(bitmap, PokemonSurvivor.candy_currency, Graphics.width - 190, center_y - 18, 168, 36, SHOP_BLUE, 2, "ICON_CANDY")
  rescue
  end

  def draw_training_header_pokemon_icon(bitmap, cx, cy)
    key = PokemonSurvivor.species_key(@training_pokemon).to_s
    folder = "#{PokemonSurvivor::SHOP_DIR}/Icon Shop"
    icon = cached_bitmap(folder, key) rescue nil
    if icon && !icon.disposed?
      bitmap.blt(cx - (icon.width / 2), cy - (icon.height / 2), icon, Rect.new(0, 0, icon.width, icon.height))
      return
    end
    draw_mode_button_icon(bitmap, "ICON_CANDY", cx, cy, 1.0)
  rescue
    draw_mode_button_icon(bitmap, "ICON_CANDY", cx, cy, 1.0) rescue nil
  end

  def draw_training_tree_panel(bitmap)
    clip = training_tree_clip_rect
    draw_pixel_round_rect(bitmap, clip.x - 2, clip.y - 2, clip.width + 4, clip.height + 4, Color.new(14, 18, 30))
    draw_pixel_round_rect(bitmap, clip.x, clip.y, clip.width, clip.height, Color.new(20, 26, 42))
    draw_inner_glow(bitmap, clip.x, clip.y, clip.width, clip.height, Color.new(255, 178, 92), 42)
    draw_training_scrolling_background(bitmap, clip)
  rescue
  end

  def draw_training_scrolling_background(bitmap, clip)
    bg = cached_bitmap(PokemonSurvivor::SHOP_DIR, "Background_Training") rescue nil
    return if !bg || bg.disposed?
    step_x = [bg.width, 1].max
    step_y = [bg.height, 1].max
    offset = ((@training_bg_frame.to_i / 2) % [step_x, step_y].max)
    start_x = clip.x - (offset % step_x)
    start_y = clip.y - (offset % step_y)
    yy = start_y
    while yy < clip.y + clip.height
      xx = start_x
      while xx < clip.x + clip.width
        rects = shop_clipped_rect(xx, yy, bg.width, bg.height, clip)
        bitmap.blt(rects[0].x, rects[0].y, bg, rects[1]) if rects
        xx += step_x
      end
      yy += step_y
    end
  rescue
  end

  def draw_training_links(bitmap)
    clip = training_tree_clip_rect
    training_all_nodes.each do |node|
      right = training_node_at(node[:x].to_i + 1, node[:y].to_i)
      down = training_node_at(node[:x].to_i, node[:y].to_i + 1)
      draw_training_link_between(bitmap, node, right, clip) if training_connected_nodes?(node, right)
      draw_training_link_between(bitmap, node, down, clip) if training_connected_nodes?(node, down)
    end
  rescue
  end

  def draw_training_link_between(bitmap, a, b, clip)
    ax, ay = training_screen_pos(a)
    bx, by = training_screen_pos(b)
    active = training_link_active?(a, b)
    if ay == by
      draw_shop_native_link(bitmap, "SlotHorizontal", (ax + bx) / 2, ay, clip, false, !active)
    elsif ax == bx
      draw_shop_native_link(bitmap, "SlotVertical", ax, (ay + by) / 2, clip, false, !active)
    end
  rescue
  end

  def training_link_active?(a, b)
    [a, b].all? { |node| node && (node[:root] || training_node_state(node) != :locked) }
  rescue
    false
  end

  def draw_training_nodes(bitmap)
    clip = training_tree_clip_rect
    selected = selected_training_node
    training_all_nodes.each do |node|
      cx, cy = training_screen_pos(node)
      x = cx - (TRAINING_TILE_SIZE / 2)
      y = cy - (TRAINING_TILE_SIZE / 2)
      next if x + TRAINING_TILE_SIZE <= clip.x || y + TRAINING_TILE_SIZE <= clip.y || x >= clip.x + clip.width || y >= clip.y + clip.height
      draw_training_node(bitmap, node, x, y, node == selected, clip)
    end
  rescue
  end

  def draw_training_node(bitmap, node, x, y, selected, clip)
    state = node[:root] && !node[:upgrade] ? :bought : training_node_state(node)
    frame = training_slot_frame_name(node)
    draw_shop_bitmap(bitmap, frame, x, y, TRAINING_TILE_SIZE, TRAINING_TILE_SIZE, clip, state == :locked)
    if node[:root] && !node[:upgrade]
      draw_mode_button_icon(bitmap, "ICON_CANDY", x + (TRAINING_TILE_SIZE / 2), y + (TRAINING_TILE_SIZE / 2), 1.0)
    else
      icon = node[:icon] || (node[:upgrade] && node[:upgrade][:icon]) || "Atk"
      if icon.to_s.start_with?("ICON_")
        draw_mode_button_icon(bitmap, icon, x + (TRAINING_TILE_SIZE / 2), y + (TRAINING_TILE_SIZE / 2), 1.0)
      else
        draw_shop_upgrade_icon(bitmap, icon, x + (TRAINING_TILE_SIZE / 2), y + (TRAINING_TILE_SIZE / 2), 1.0, clip, state, training_node_affordable?(node))
      end
    end
  rescue
  end

  def training_slot_frame_name(node)
    dirs = []
    dirs << :left if training_connected_nodes?(node, training_node_at(node[:x].to_i - 1, node[:y].to_i))
    dirs << :right if training_connected_nodes?(node, training_node_at(node[:x].to_i + 1, node[:y].to_i))
    dirs << :up if training_connected_nodes?(node, training_node_at(node[:x].to_i, node[:y].to_i - 1))
    dirs << :down if training_connected_nodes?(node, training_node_at(node[:x].to_i, node[:y].to_i + 1))
    left = dirs.include?(:left)
    right = dirs.include?(:right)
    up = dirs.include?(:up)
    down = dirs.include?(:down)
    return "SlotLeftRight" if node[:root] && left && right && !up && !down
    return "SlotAll" if left && right && up && down
    return "SlotLeftRightDown" if left && right && down && !up
    return "SlotUpLeftDown" if up && left && down && !right
    return "SlotUpLeftRight" if up && left && right && !down
    return "SlotUpRightDown" if up && right && down && !left
    return "SlotLeftRight" if left && right && !up && !down
    return "SlotUpDown" if up && down && !left && !right
    return "SlotLeftDown" if left && down && !up && !right
    return "SlotLeftUp" if left && up && !down && !right
    return "SlotRightDown" if right && down && !up && !left
    return "SlotUpRight" if right && up && !down && !left
    return "SlotLeft" if left
    return "SlotRight" if right
    return "SlotUp" if up
    return "SlotDown" if down
    "SlotNeutrals"
  rescue
    "SlotNeutrals"
  end

  def training_node_bought?(node)
    return false if !node || !node[:upgrade]
    PokemonSurvivor.pokemon_training_level(@training_pokemon, node[:upgrade][:id]) >= node[:level].to_i
  rescue
    false
  end

  def training_node_connected_to_core?(node)
    training_connected_nodes?(training_root_node, node)
  rescue
    false
  end

  def training_node_connected_to_bought?(node)
    TRAINING_TREE_LINKS.any? do |left, right|
      other_id = nil
      other_id = right if left == node[:id]
      other_id = left if right == node[:id]
      next false if !other_id
      other = @training_node_id_cache[other_id]
      training_node_bought?(other)
    end
  rescue
    false
  end

  def training_node_progress_available?(node)
    current = PokemonSurvivor.pokemon_training_level(@training_pokemon, node[:upgrade][:id])
    return false if node[:level].to_i != current + 1
    return true if training_node_connected_to_core?(node)
    training_node_connected_to_bought?(node)
  rescue
    false
  end

  def training_node_state(node)
    return :locked if !node
    if node[:root] && node[:upgrade]
      return :bought if PokemonSurvivor.pokemon_shiny_unlocked?(@training_pokemon)
      return PokemonSurvivor.pokemon_training_core_complete?(@training_pokemon) ? :available : :locked
    end
    return :bought if node[:root]
    @training_state_cache ||= {}
    cached = @training_state_cache[node[:id]]
    return cached if cached
    state = if training_node_bought?(node)
              :bought
            elsif training_node_progress_available?(node)
              :available
            else
              :locked
            end
    @training_state_cache[node[:id]] = state
    state
  rescue
    :locked
  end

  def training_node_affordable?(node)
    return false if !node || !node[:upgrade]
    cost = PokemonSurvivor.pokemon_training_cost(@training_pokemon, node[:upgrade][:id], node[:level])
    return false if cost.nil?
    PokemonSurvivor.candy_currency >= cost
  rescue
    false
  end

  def buy_selected_training_upgrade
    node = selected_training_node
    return pbPlayBuzzerSE rescue nil if !node || (!node[:upgrade] && node[:root])
    if training_node_state(node) != :available
      pbPlayBuzzerSE rescue nil
      draw_pokemon_training
      return
    end
    if PokemonSurvivor.buy_pokemon_training_upgrade(@training_pokemon, node[:upgrade][:id])
      invalidate_training_state_cache
      rebuild_training_tree_cache(true)
      pbSEPlay("Survivor/Mart buy item", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    else
      pbPlayBuzzerSE rescue nil
    end
    draw_pokemon_training
  rescue
  end

  def draw_training_info(bitmap)
    node = selected_training_node
    return if !node
    y = Graphics.height - TRAINING_FOOTER_H - TRAINING_INFO_H + 8
    draw_pixel_round_rect(bitmap, 10, y - 4, Graphics.width - 20, TRAINING_INFO_H - 8, Color.new(34, 42, 62))
    if node[:root] && !node[:upgrade]
      draw_shop_scrolling_text(bitmap, _INTL("Training Core"), 22, y, Graphics.width - 44, 22, SHOP_GOLD, SHOP_SHADOW_COLOR, false)
      draw_shop_scrolling_description(bitmap, _INTL("Permanent upgrades for this Pokemon only."), 22, y + 30, Graphics.width - 44, 52)
      draw_shop_scrolling_text(bitmap, _INTL("Complete this Pokemon training tree to unlock its Shiny form."), 22, y + 78, Graphics.width - 44, 26, SHOP_DIM_COLOR, SHOP_SHADOW_COLOR, false)
      return
    end
    data = node[:upgrade]
    level = PokemonSurvivor.pokemon_training_level(@training_pokemon, data[:id])
    max = PokemonSurvivor.pokemon_training_max(data[:id])
    state = training_node_state(node)
    cost = PokemonSurvivor.pokemon_training_cost(@training_pokemon, data[:id], node[:level]).to_i
    enough = PokemonSurvivor.candy_currency >= cost
    status = state == :bought ? _INTL("Unlocked") : (state == :available && enough ? _INTL("Available") : _INTL("Locked"))
    status_color = state == :bought ? SHOP_GREEN : ((state == :available && enough) ? SHOP_GOLD : SHOP_RED)
    title = node[:root] ? _INTL(data[:name].to_s) : _INTL("{1} {2}", _INTL(data[:name].to_s), node[:level].to_i)
    draw_shop_scrolling_text(bitmap, title, 22, y, Graphics.width - 170, 22, shop_upgrade_title_color(data), SHOP_SHADOW_COLOR, false)
    draw_shop_scrolling_text(bitmap, status, Graphics.width - 150, y, 128, 22, status_color, SHOP_SHADOW_COLOR, true)
    draw_shop_scrolling_description(bitmap, _INTL(data[:desc].to_s), 22, y + 25, Graphics.width - 44, 36)
    draw_training_cost(bitmap, data, node, level, max, 22, y + 62, Graphics.width - 44, 48)
  rescue
  end

  def draw_training_cost(bitmap, data, node, current_level, max, x, y, w, h)
    if training_node_state(node) == :bought
      draw_shop_scrolling_text(bitmap, _INTL("Level {1}/{2} unlocked.", node[:level].to_i, max), x, y + 6, w, h - 6, SHOP_GREEN, SHOP_SHADOW_COLOR, false)
      return
    end
    value = (data[:values] || [])[node[:level].to_i - 1].to_i
    label = shop_value_label(data, value)
    prefix = training_node_state(node) == :available ? _INTL("Bonus: {1}  Cost:", label) : _INTL("Requires level {1} first.  Cost:", node[:level].to_i - 1)
    cost = PokemonSurvivor.pokemon_training_cost(@training_pokemon, data[:id], node[:level]).to_i
    discount = PokemonSurvivor.pokemon_training_discount_basis_points(@training_pokemon, data[:id])
    percent = discount % 100 == 0 ? discount / 100 : discount / 100.0
    quantity = discount > 0 ? _INTL("{1} (-{2}%)", cost, percent) : cost.to_s
    color = (training_node_state(node) == :available && PokemonSurvivor.candy_currency >= cost) ? SHOP_GOLD : SHOP_RED
    line = cached_shop_upgrade_cost_bitmap(prefix, quantity, "ICON_CANDY", w, h, color)
    return if !line || line.disposed?
    offset = shop_scroll_offset([line.width - w + 10, 0].max, 5, 70)
    bitmap.blt(x, y + ((h - line.height) / 2), line, Rect.new(offset, 0, [w, line.width - offset].min, line.height))
  rescue
  end

  def draw_training_footer(bitmap)
    detail = @training_show_details == false ? _INTL("Show Details") : _INTL("Hide Details")
    draw_help(bitmap, [[:up, ""], [:down, ""], [:left, ""], [:right, _INTL("Navigate")], [:confirm, _INTL("Buy")], [:action, detail], [:cancel, _INTL("Back")]])
  rescue
  end

  def draw_pokemon_equipment_slot(bitmap, pokemon, x, y, w, h, accent)
    return if !PokemonSurvivor.pokemon_equipment_slot_unlocked?(pokemon)
    edge = brighten_color(accent, 18) rescue Color.new(255, 216, 92)
    draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(4, 7, 14))
    draw_pixel_round_rect(bitmap, x + 1, y + 1, w - 2, h - 2, edge)
    draw_pixel_round_rect(bitmap, x + 3, y + 3, w - 6, h - 6, Color.new(18, 28, 46))
    item_id = PokemonSurvivor.equipped_pokemon_item(pokemon) rescue nil
    item = PokemonSurvivor.respond_to?(:equipment_data) ? PokemonSurvivor.equipment_data(item_id) : nil
    if item && item[:icon] && respond_to?(:draw_equipment_item_icon)
      draw_equipment_item_icon(bitmap, item[:icon], x + (w / 2), y + (h / 2), [w, h].min - 8)
    else
      cx = x + (w / 2)
      cy = y + (h / 2)
      bitmap.fill_rect(cx - 8, cy - 1, 16, 2, Color.new(198, 214, 236))
      bitmap.fill_rect(cx - 1, cy - 8, 2, 16, Color.new(198, 214, 236))
    end
    draw_menu_notification(bitmap, x, y) if equipment_notification?(pokemon)
  rescue
  end
end

