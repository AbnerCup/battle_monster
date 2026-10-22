#===============================================================================
# Pokemon Survivor - Roguelite Shop
#===============================================================================

class Scene_PokemonSurvivor
  SHOP_TILE_SIZE = 48
  SHOP_CELL_SIZE = 62
  SHOP_HEADER_H = 66
  SHOP_FOOTER_H = 34
  SHOP_INFO_H = 112
  SHOP_BASE_COLOR = Color.new(248, 248, 248)
  SHOP_SHADOW_COLOR = Color.new(40, 44, 58)
  SHOP_DIM_COLOR = Color.new(158, 172, 192)
  SHOP_GOLD = Color.new(255, 216, 92)
  SHOP_GREEN = Color.new(96, 232, 148)
  SHOP_RED = Color.new(236, 84, 84)
  SHOP_BLUE = Color.new(96, 184, 255)

  SHOP_NAV_NODES = []

  SHOP_TREE_LAYOUT = [
    [:starting_hp, 1, -1, -1], [:starting_hp, 2, -2, -1], [:starting_hp, 3, -3, -1], [:starting_hp, 4, -3, -2], [:starting_hp, 5, -2, -2],
    [:starting_damage, 1, 1, -1], [:starting_damage, 2, 2, -1], [:starting_damage, 3, 3, -1], [:starting_damage, 4, 3, -2], [:starting_damage, 5, 2, -2],
    [:xp_drop, 1, -1, 0], [:xp_drop, 2, -2, 0], [:xp_drop, 3, -3, 0], [:xp_drop, 4, -4, 0], [:xp_drop, 5, -4, 1], [:xp_drop, 6, -4, 2], [:xp_drop, 7, -3, 2], [:xp_drop, 8, -3, 3],
    [:coin_gain, 1, 1, 0], [:coin_gain, 2, 2, 0], [:coin_gain, 3, 3, 0], [:coin_gain, 4, 4, 0], [:coin_gain, 5, 4, 1], [:steady_burst, 1, 4, 2], [:steady_burst, 2, 3, 2], [:steady_burst, 3, 3, 3],
    [:starting_speed, 1, -1, 1], [:starting_speed, 2, -2, 1], [:starting_speed, 3, -2, 2], [:starting_speed, 4, -1, 2],
    [:burst_starter, 1, 1, 1], [:burst_starter, 2, 2, 1], [:burst_starter, 3, 2, 2], [:burst_starter, 4, 1, 2], [:burst_starter, 5, 1, 3], [:sharp_start, 1, 2, 3],
    [:fatal_guard_stock, 1, -1, 3], [:fatal_guard_stock, 2, -2, 3],
    [:reroll_stock, 1, 1, 4], [:reroll_stock, 2, 2, 4], [:reroll_stock, 3, 3, 4],
    [:ban_stock, 1, -1, 4], [:ban_stock, 2, -2, 4], [:ban_stock, 3, -3, 4]
  ]

  SHOP_TREE_LINKS = [
    [:shop_core, :xp_drop_1], [:shop_core, :coin_gain_1],
    [:xp_drop_1, :starting_hp_1], [:starting_hp_1, :starting_hp_2], [:starting_hp_2, :starting_hp_3], [:starting_hp_3, :starting_hp_4], [:starting_hp_4, :starting_hp_5],
    [:coin_gain_1, :starting_damage_1], [:starting_damage_1, :starting_damage_2], [:starting_damage_2, :starting_damage_3], [:starting_damage_3, :starting_damage_4], [:starting_damage_4, :starting_damage_5],
    [:xp_drop_1, :xp_drop_2], [:xp_drop_2, :xp_drop_3], [:xp_drop_3, :xp_drop_4], [:xp_drop_4, :xp_drop_5], [:xp_drop_5, :xp_drop_6], [:xp_drop_6, :xp_drop_7], [:xp_drop_7, :xp_drop_8],
    [:coin_gain_1, :coin_gain_2], [:coin_gain_2, :coin_gain_3], [:coin_gain_3, :coin_gain_4], [:coin_gain_4, :coin_gain_5], [:coin_gain_5, :steady_burst_1], [:steady_burst_1, :steady_burst_2], [:steady_burst_2, :steady_burst_3],
    [:xp_drop_1, :starting_speed_1], [:starting_speed_1, :starting_speed_2], [:starting_speed_2, :starting_speed_3], [:starting_speed_3, :starting_speed_4],
    [:coin_gain_1, :burst_starter_1], [:burst_starter_1, :burst_starter_2], [:burst_starter_2, :burst_starter_3], [:burst_starter_3, :burst_starter_4], [:burst_starter_4, :burst_starter_5], [:burst_starter_5, :sharp_start_1],
    [:burst_starter_5, :reroll_stock_1], [:reroll_stock_1, :reroll_stock_2], [:reroll_stock_2, :reroll_stock_3],
    [:starting_speed_4, :fatal_guard_stock_1], [:fatal_guard_stock_1, :fatal_guard_stock_2],
    [:fatal_guard_stock_1, :ban_stock_1], [:ban_stock_1, :ban_stock_2], [:ban_stock_2, :ban_stock_3]
  ]

  ENDLESS_SHOP_TREE_LAYOUT = [
    [:endless_xp, 1, -1, 0], [:endless_xp, 2, -2, 0], [:endless_xp, 3, -3, 0], [:endless_xp, 4, -4, 0],
    [:endless_damage, 1, -1, -1], [:endless_damage, 2, -2, -1], [:endless_damage, 3, -3, -1], [:endless_damage, 4, -4, -1],
    [:endless_burst, 1, -1, 1], [:endless_burst, 2, -2, 1], [:endless_burst, 3, -3, 1], [:endless_burst, 4, -4, 1],
    [:endless_hp, 1, 1, 0], [:endless_hp, 2, 2, 0], [:endless_hp, 3, 3, 0], [:endless_hp, 4, 4, 0],
    [:endless_speed, 1, 1, -1], [:endless_speed, 2, 2, -1], [:endless_speed, 3, 3, -1], [:endless_speed, 4, 4, -1],
    [:endless_pressure, 1, 1, 1], [:endless_pressure, 2, 2, 1], [:endless_pressure, 3, 3, 1], [:endless_pressure, 4, 4, 1],
    [:endless_reroll, 1, 0, -1], [:endless_reroll, 2, 0, -2],
    [:endless_revive, 1, 0, 1], [:endless_revive, 2, 0, 2],
    [:endless_candy_exchange, 1, 0, 3]
  ]

  ENDLESS_SHOP_TREE_LINKS = [
    [:shop_core, :endless_xp_1], [:endless_xp_1, :endless_xp_2], [:endless_xp_2, :endless_xp_3], [:endless_xp_3, :endless_xp_4],
    [:endless_xp_1, :endless_damage_1], [:endless_damage_1, :endless_damage_2], [:endless_damage_2, :endless_damage_3], [:endless_damage_3, :endless_damage_4],
    [:endless_xp_1, :endless_burst_1], [:endless_burst_1, :endless_burst_2], [:endless_burst_2, :endless_burst_3], [:endless_burst_3, :endless_burst_4],
    [:shop_core, :endless_hp_1], [:endless_hp_1, :endless_hp_2], [:endless_hp_2, :endless_hp_3], [:endless_hp_3, :endless_hp_4],
    [:endless_hp_1, :endless_speed_1], [:endless_speed_1, :endless_speed_2], [:endless_speed_2, :endless_speed_3], [:endless_speed_3, :endless_speed_4],
    [:endless_hp_1, :endless_pressure_1], [:endless_pressure_1, :endless_pressure_2], [:endless_pressure_2, :endless_pressure_3], [:endless_pressure_3, :endless_pressure_4],
    [:shop_core, :endless_reroll_1], [:endless_reroll_1, :endless_reroll_2],
    [:shop_core, :endless_revive_1], [:endless_revive_1, :endless_revive_2], [:endless_revive_2, :endless_candy_exchange_1]
  ]
  def select_shop_triggered?
    false
  rescue
    false
  end

  def open_shop
    @shop_resource_popup = nil
    @shop_resource_popup_queue = []
    @state = :shop
    play_survivor_menu_bgm
    @shop_index = 0 if @shop_index.nil?
    @shop_bg_frame ||= 0
    @shop_last_time = System.uptime rescue 0
    @shop_show_details = true if @shop_show_details.nil?
    @shop_tree_mode = :standard if @shop_tree_mode.nil?
    rebuild_shop_tree_cache
    invalidate_shop_static_cache
    PokemonSurvivor.convert_shop_currency_to_dark_if_unlocked
    @shop_index = [[@shop_index.to_i, 0].max, shop_selectable_nodes.length - 1].min
    center_shop_on_selected
    pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    draw_shop
  rescue
  end

  def close_shop
    @shop_resource_popup = nil
    @shop_resource_popup_queue = nil
    @state = :select
    play_survivor_menu_bgm
    pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
    draw_select
  rescue
  end

  def update_shop
    dirty = update_shop_background_animation
    old = @shop_index.to_i
    if Input.repeat?(Input::LEFT)
      move_shop_tree_selection(-1, 0)
    elsif Input.repeat?(Input::RIGHT)
      move_shop_tree_selection(1, 0)
    elsif Input.repeat?(Input::UP)
      move_shop_tree_selection(0, -1)
    elsif Input.repeat?(Input::DOWN)
      move_shop_tree_selection(0, 1)
    elsif shop_next_available_triggered?
      select_next_available_shop_node
      dirty = true
    elsif shop_details_triggered?
      @shop_show_details = !@shop_show_details
      dirty = true
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
    elsif survivor_confirm_triggered?
      buy_selected_shop_upgrade
      return
    elsif survivor_cancel_triggered?
      close_shop
      return
    end
    if old != @shop_index
      center_shop_on_selected
      dirty = true
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
    end
    draw_shop if dirty
  rescue
    close_shop
  end
  def shop_details_triggered?
    return PokemonSurvivor.control_trigger?(:action) if PokemonSurvivor.respond_to?(:control_trigger?)
    return true if Input.const_defined?(:ACTION) && Input.trigger?(Input::ACTION)
    false
  rescue
    false
  end

  def shop_next_available_triggered?
    return PokemonSurvivor.control_trigger?(:menu) if PokemonSurvivor.respond_to?(:control_trigger?)
    return true if Input.const_defined?(:SPECIAL) && Input.trigger?(Input::SPECIAL)
    return true if Input.const_defined?(:MENU) && Input.const_defined?(:ACTION) && Input::MENU != Input::ACTION && Input.trigger?(Input::MENU)
    false
  rescue
    false
  end

  def select_next_available_shop_node
    nodes = shop_selectable_nodes
    target = nodes.each_with_index.find { |node, _i| !node[:root] && !node[:nav] && shop_node_state(node) == :available }
    if target
      @shop_index = target[1]
      center_shop_on_selected
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
    else
      pbPlayBuzzerSE rescue nil
    end
  rescue
  end
  def update_shop_background_animation
    now = System.uptime rescue 0
    elapsed = now - (@shop_last_time || now)
    return false if elapsed < (1.0 / 30.0)
    steps = [(elapsed * 60).floor, 2].min
    @shop_last_time = now
    @shop_bg_frame = @shop_bg_frame.to_i + steps
    true
  rescue
    @shop_bg_frame = Graphics.frame_count / 2
    true
  end

  def buy_selected_shop_upgrade
    node = selected_shop_node
    return handle_shop_root_action(node) if node && node[:root]
    return pbPlayBuzzerSE rescue nil if !node || node[:nav]
    data = node[:upgrade]
    if shop_node_state(node) != :available
      pbPlayBuzzerSE rescue nil
      draw_shop
      return
    end
    quantity = 1
    if data[:id] == :endless_candy_exchange
      quantity = choose_candy_exchange_quantity(PokemonSurvivor.active_shop_currency(shop_tree_mode),
        data[:costs][0], data[:values][0], _INTL("Dark Fragments"))
      return if quantity <= 0
    end
    result = PokemonSurvivor.buy_shop_upgrade(data[:id], quantity)
    if result == true || result == :ok
      if data[:id] == :endless_candy_exchange
        enqueue_shop_resource_popup("ICON_CANDY", (data[:values] || [])[0].to_i * quantity)
      end
      invalidate_shop_state_cache
      rebuild_shop_tree_cache(true)
      invalidate_shop_static_cache
      pbSEPlay("Survivor/Mart buy item", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    else
      pbPlayBuzzerSE rescue nil
    end
    draw_shop
  rescue
  end

  def choose_candy_exchange_quantity(balance, cost, gain, currency, options = {})
    return 0 if cost.to_i <= 0
    maximum = [balance.to_i / cost.to_i, 999999].min
    maximum = [maximum, options[:limit].to_i].min if options[:limit]
    return 0 if maximum < 1
    quantity = 1
    Input.update
    loop do
      Graphics.update
      Input.update
      return 0 if survivor_cancel_triggered?
      return quantity if survivor_confirm_triggered?
      delta = 0
      delta = -1 if Input.repeat?(Input::LEFT)
      delta = 1 if Input.repeat?(Input::RIGHT)
      delta = 10 if Input.repeat?(Input::UP)
      delta = -10 if Input.repeat?(Input::DOWN)
      quantity = [[quantity + delta, 1].max, maximum].min
      quantity = quantity == maximum ? 1 : maximum if shop_next_available_triggered?
      update_shop_background_animation
      draw_shop
      draw_candy_exchange_dialog(@sprites["screen"].bitmap, quantity, maximum, balance, cost, gain, currency, options)
    end
  ensure
    if @candy_exchange_text_cache
      @candy_exchange_text_cache.each_value { |line| line.dispose unless line.disposed? }
      @candy_exchange_text_cache = nil
    end
    @last_time = System.uptime
    @accumulator = 0
    Input.update
    draw_shop
  end

  def draw_candy_exchange_dialog(bitmap, quantity, maximum, balance, cost, gain, currency, options = {})
    width = [Graphics.width - 32, 480].min
    height = 296
    x = (Graphics.width - width) / 2
    y = (Graphics.height - SHOP_FOOTER_H - height) / 2
    bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0, 170))
    draw_pixel_round_rect(bitmap, x + 4, y + 6, width, height, Color.new(0, 0, 0, 120))
    draw_pixel_round_rect(bitmap, x, y, width, height, SHOP_GOLD)
    draw_pixel_round_rect(bitmap, x + 2, y + 2, width - 4, height - 4, Color.new(22, 25, 32))
    draw_pixel_round_rect(bitmap, x + 7, y + 7, width - 14, 43, Color.new(48, 47, 44))
    title = options[:reward_name] ? _INTL("Exchange {1}", options[:reward_name]) : _INTL("Exchange Candies")
    draw_candy_exchange_text(bitmap, title, x + 16, y + 13, width - 32, 30, SHOP_GOLD)
    draw_candy_exchange_text(bitmap, _INTL("Quantity"), x + 52, y + 56, width - 104, 30, SHOP_DIM_COLOR)
    draw_candy_exchange_text(bitmap, quantity.to_s, x + 64, y + 88, width - 128, 32, SHOP_BASE_COLOR)
    draw_candy_exchange_text(bitmap, "<", x + 18, y + 88, 36, 32, quantity > 1 ? SHOP_GOLD : SHOP_DIM_COLOR)
    draw_candy_exchange_text(bitmap, ">", x + width - 54, y + 88, 36, 32, quantity < maximum ? SHOP_GOLD : SHOP_DIM_COLOR)
    draw_candy_exchange_text(bitmap, _INTL("Max: {1}", maximum), x + 32, y + 123, width - 64, 30, SHOP_DIM_COLOR)
    bitmap.fill_rect(x + 18, y + 158, width - 36, 1, Color.new(82, 79, 68))
    half = (width - 36) / 2
    bitmap.fill_rect(x + width / 2, y + 170, 1, 76, Color.new(82, 79, 68))
    ore = @titan_tree_kind == :training
    payment_icon = if options[:payment_icon]
      cached_bitmap(PokemonSurvivor::SHOP_DIR, options[:payment_icon])
    else
      ore ? cached_bitmap(PokemonSurvivor::SHOP_DIR, "Ore") : cached_icon_bitmap("ICON_DARKFRAGMENT")
    end
    reward_icon = cached_icon_bitmap(options[:reward_icon] || "ICON_CANDY")
    [[x + 18, _INTL("Cost"), cost * quantity, payment_icon, SHOP_GOLD],
     [x + 18 + half, _INTL("Gain"), gain * quantity, reward_icon, SHOP_GREEN]].each do |left, label, amount, icon, color|
      draw_candy_exchange_text(bitmap, label, left + 8, y + 163, half - 16, 30, color)
      has_icon = icon && !icon.disposed?
      icon_width = has_icon ? icon.width : 0
      gap = has_icon ? 8 : 0
      text = "x#{amount}"
      text_width = [bitmap.text_size(text).width.ceil + 4, half - 16 - icon_width - gap].min
      row_x = left + (half - icon_width - gap - text_width) / 2
      center_y = y + 220
      bitmap.blt(row_x, center_y - icon.height / 2, icon, icon.rect) if has_icon
      draw_candy_exchange_amount(bitmap, text, row_x + icon_width + gap, center_y, text_width)
    end
    remaining = balance - cost * quantity
    remaining = PokemonSurvivor.dark_fragment_balance_text(remaining) unless ore || options[:payment_icon]
    draw_candy_exchange_text(bitmap, _INTL("Remaining: {1} {2}", remaining, currency),
      x + 16, y + 255, width - 32, 30, SHOP_DIM_COLOR)
    draw_help(bitmap, [[:confirm, _INTL("Exchange")], [:ready_menu, _INTL("Max / Min")], [:cancel, _INTL("Cancel")]])
  end

  def draw_candy_exchange_amount(bitmap, text, x, center_y, width, color = SHOP_BASE_COLOR)
    pbSetSystemFont(bitmap)
    bitmap.font.size = 24
    @candy_exchange_text_cache ||= {}
    key = [:exchange_text, text, bitmap.font.name, color]
    line = @candy_exchange_text_cache[key]
    unless line && !line.disposed?
      if @candy_exchange_text_cache.length >= 16
        @candy_exchange_text_cache.delete(@candy_exchange_text_cache.keys.first).dispose
      end
      line = Bitmap.new(bitmap.text_size(text).width.ceil + 4, 96)
      pbSetSystemFont(line)
      line.font.size = 24
      line.font.color = color
      line.draw_text(0, 16, line.width, 64, text, 0)
      # Font rectangles include uneven padding. Center the visible glyphs instead.
      top = nil
      bottom = nil
      line.height.times do |yy|
        next unless (0...line.width).any? { |xx| line.get_pixel(xx, yy).alpha > 0 }
        top ||= yy
        bottom = yy
      end
      line.instance_variable_set(:@candy_ink_bounds, top ? [top, bottom - top + 1] : [0, line.height])
      @candy_exchange_text_cache[key] = line
    end
    top, ink_height = line.instance_variable_get(:@candy_ink_bounds)
    offset = shop_scroll_offset([line.width - width, 0].max, 5, 70)
    shown_width = [width, line.width].min
    # Keep the whole vertical surface: accents and font offsets must not be
    # clipped to the measured ink rectangle. Only horizontal overflow scrolls.
    bitmap.blt(x + (width - shown_width) / 2, center_y - top - ink_height / 2, line,
      Rect.new(offset, 0, shown_width, line.height))
  end

  def draw_candy_exchange_text(bitmap, text, x, y, width, height, color)
    draw_candy_exchange_amount(bitmap, text, x, y + height / 2, width, color)
  end

  def handle_shop_root_action(node)
    if shop_tree_mode == :endless
      switch_shop_tree(:standard)
    elsif endless_shop_unlocked?
      switch_shop_tree(:endless)
    else
      pbPlayBuzzerSE rescue nil
    end
  rescue
  end

  def switch_shop_tree(mode)
    @shop_tree_mode = mode == :endless ? :endless : :standard
    rebuild_shop_tree_cache(true)
    invalidate_shop_static_cache
    @shop_index = 0
    @shop_bg_frame = 0
    @shop_last_time = System.uptime rescue 0
    center_shop_on_selected
    pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    draw_shop
  rescue
  end

  def shop_tree_mode
    @shop_tree_mode == :endless ? :endless : :standard
  rescue
    :standard
  end

  def endless_shop_unlocked?
    PokemonSurvivor.shop_tree_complete?(:standard)
  rescue
    false
  end

  def move_shop_tree_selection(dx, dy)
    nodes = shop_selectable_nodes
    current = nodes[@shop_index.to_i]
    return if !current
    cur_x = current[:x].to_i
    cur_y = current[:y].to_i
    candidates = nodes.each_with_index.select do |node, _i|
      next false if node.equal?(current)
      vx = node[:x].to_i - cur_x
      vy = node[:y].to_i - cur_y
      if dx != 0
        vx * dx > 0
      else
        vy * dy > 0
      end
    end
    target = candidates.min_by do |node, _i|
      vx = node[:x].to_i - cur_x
      vy = node[:y].to_i - cur_y
      dx != 0 ? (vx.abs + (vy.abs * 3)) : (vy.abs + (vx.abs * 3))
    end
    @shop_index = target[1] if target
  rescue
  end

  def center_shop_on_selected
    node = selected_shop_node
    return if !node
    @shop_camera_x = node[:x].to_i * SHOP_CELL_SIZE
    @shop_camera_y = node[:y].to_i * SHOP_CELL_SIZE
  rescue
    @shop_camera_x = 0
    @shop_camera_y = 0
  end

  def shop_root_node
    if shop_tree_mode == :endless
      { id: :shop_core, root: true, x: 0, y: 0, icon: "Classic Core", name: _INTL("Classic Upgrade Tree"), desc: _INTL("Return to Kecleon's standard upgrade tree.") }
    elsif endless_shop_unlocked?
      { id: :shop_core, root: true, x: 0, y: 0, icon: "Endless Core", name: _INTL("Endless Kecleon Shop"), desc: _INTL("Endless-only permanent upgrades will branch from here.") }
    else
      { id: :shop_core, root: true, x: 0, y: 0, icon: nil, name: _INTL("Shop Core"), desc: _INTL("Permanent roguelite upgrades branch from here.") }
    end
  rescue
    { id: :shop_core, root: true, x: 0, y: 0, icon: nil, name: _INTL("Shop Core"), desc: _INTL("Permanent roguelite upgrades branch from here.") }
  end

  def rebuild_shop_tree_cache(force = false)
    mode = shop_tree_mode
    unlocked = endless_shop_unlocked?
    endless_complete = PokemonSurvivor.shop_tree_complete?(:endless)
    key = [mode, unlocked, endless_complete]
    return if !force && @shop_tree_cache_key == key && @shop_all_nodes_cache
    nodes = [shop_root_node]
    shop_tree_layout.each do |entry|
      upgrade_id, level, x, y = entry
      upgrade = PokemonSurvivor.shop_upgrade_data(upgrade_id, mode)
      next if !upgrade
      next if upgrade[:infinite] && !endless_complete
      next if !upgrade[:infinite] && level.to_i > (upgrade[:values] || []).length
      nodes << { id: shop_node_id(upgrade_id, level), upgrade: upgrade, level: level, x: x, y: y, icon: upgrade[:icon] }
    end
    @shop_tree_cache_key = key
    @shop_all_nodes_cache = nodes
    @shop_node_pos_cache = {}
    @shop_node_id_cache = {}
    nodes.each do |node|
      @shop_node_pos_cache[[node[:x].to_i, node[:y].to_i]] = node
      @shop_node_id_cache[node[:id]] = node
    end
    @shop_link_cache = {}
    shop_tree_links.each do |left, right|
      @shop_link_cache[[left, right]] = true
      @shop_link_cache[[right, left]] = true
    end
    @shop_state_cache = nil
    invalidate_shop_static_cache
  rescue
    @shop_all_nodes_cache = [shop_root_node]
    @shop_node_pos_cache = {}
    @shop_node_id_cache = {}
    @shop_link_cache = {}
    @shop_state_cache = nil
  end

  def invalidate_shop_state_cache
    @shop_state_cache = nil
    invalidate_shop_static_cache
  rescue
  end

  def invalidate_shop_static_cache
    @shop_static_tree_cache_key = nil
    @shop_static_tree_available_icons = nil
    @shop_static_tree_version = @shop_static_tree_version.to_i + 1
    if @shop_static_tree_cache && !@shop_static_tree_cache.disposed?
      @shop_static_tree_cache.dispose
    end
    @shop_static_tree_cache = nil
  rescue
  end

  def shop_selectable_nodes
    shop_all_nodes
  rescue
    []
  end

  def shop_all_nodes
    rebuild_shop_tree_cache if !@shop_all_nodes_cache
    @shop_all_nodes_cache || [shop_root_node]
  rescue
    [shop_root_node]
  end

  def shop_upgrade_nodes
    shop_all_nodes.reject { |node| node[:root] }
  rescue
    []
  end
  def shop_node_id(id, level)
    "#{id}_#{level}".to_sym
  rescue
    id
  end

  def selected_shop_node
    nodes = shop_selectable_nodes
    @shop_index = [[@shop_index.to_i, 0].max, nodes.length - 1].min
    nodes[@shop_index]
  rescue
    nil
  end

  def shop_node_at(x, y)
    rebuild_shop_tree_cache if !@shop_node_pos_cache
    @shop_node_pos_cache[[x.to_i, y.to_i]]
  rescue
    nil
  end

  def shop_connected_nodes?(a, b)
    return false if !a || !b
    rebuild_shop_tree_cache if !@shop_link_cache
    @shop_link_cache[[a[:id], b[:id]]] == true
  rescue
    false
  end

  def shop_tree_layout
    shop_tree_mode == :endless ? ENDLESS_SHOP_TREE_LAYOUT : SHOP_TREE_LAYOUT
  rescue
    SHOP_TREE_LAYOUT
  end

  def shop_tree_links
    shop_tree_mode == :endless ? ENDLESS_SHOP_TREE_LINKS : SHOP_TREE_LINKS
  rescue
    SHOP_TREE_LINKS
  end
  def shop_bridge_connections
    []
  rescue
    []
  end
  def draw_shop
    bmp = @sprites["screen"].bitmap
    over = @sprites["overlay"].bitmap
    bmp.clear
    over.clear
    pbSetSystemFont(bmp)
    draw_shop_background(bmp)
    draw_shop_overlay(bmp)
    draw_shop_resource_popup(bmp)
    draw_tv_filter(over)
  rescue
  end

  def enqueue_shop_resource_popup(icon, amount)
    return if amount.to_i <= 0
    @shop_resource_popup_queue ||= []
    @shop_resource_popup_queue << { icon: icon, amount: amount.to_i }
  end

  def draw_shop_resource_popup(bitmap)
    queue = @shop_resource_popup_queue
    return unless @shop_resource_popup || (queue && !queue.empty?)
    now = System.uptime
    if @shop_resource_popup && now - @shop_resource_popup[:start] >= @shop_resource_popup[:duration]
      @shop_resource_popup = nil
    end
    if !@shop_resource_popup && queue && !queue.empty?
      @shop_resource_popup = queue.shift
      @shop_resource_popup[:start] = now
      @shop_resource_popup[:duration] = queue.empty? ? 1.6 : 0.9
    end
    data = @shop_resource_popup
    return unless data
    draw_run_reward_popup_row(bitmap, data, now - data[:start], data[:duration], SHOP_HEADER_H + 8)
  end

  def draw_shop_background(bitmap)
    bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(18, 22, 34))
  rescue
  end

  def draw_shop_overlay(bitmap)
    draw_shop_tree_panel(bitmap)
    draw_shop_static_tree(bitmap)
    draw_shop_available_talents(bitmap)
    draw_shop_ui_panels(bitmap)
    draw_shop_header(bitmap)
    draw_shop_info(bitmap)
    draw_shop_footer(bitmap)
  rescue
  end

  def shop_info_h
    @shop_show_details == false ? 0 : SHOP_INFO_H
  end

  def shop_body_top
    SHOP_HEADER_H + 8
  end

  def shop_body_bottom
    Graphics.height - SHOP_FOOTER_H - shop_info_h - 4
  end

  def shop_tree_clip_rect
    Rect.new(10, shop_body_top - 2, Graphics.width - 20, shop_body_bottom - shop_body_top + 4)
  end

  def draw_shop_ui_panels(bitmap)
    draw_pixel_round_rect(bitmap, 8, 8, Graphics.width - 16, SHOP_HEADER_H - 12, Color.new(18, 22, 34))
    draw_pixel_round_rect(bitmap, 10, 10, Graphics.width - 20, SHOP_HEADER_H - 16, Color.new(34, 42, 62))
    draw_pixel_round_rect(bitmap, 12, 12, Graphics.width - 24, SHOP_HEADER_H - 20, Color.new(44, 54, 78))
    if shop_info_h > 0
      draw_pixel_round_rect(bitmap, 10, Graphics.height - SHOP_FOOTER_H - shop_info_h + 4, Graphics.width - 20, shop_info_h - 8, Color.new(34, 42, 62))
    end
  rescue
  end

  def draw_shop_header(bitmap)
    header_y = 12
    header_h = SHOP_HEADER_H - 20
    center_y = header_y + (header_h / 2)
    shop_icon = shop_tree_mode == :endless ? "ICON_SHOP_ENDLESS" : "ICON_SHOP"
    draw_mode_button_icon(bitmap, shop_icon, 38, center_y, 1.0)
    title = shop_tree_mode == :endless ? _INTL("Endless Kecleon Shop") : _INTL("Kecleon's Upgrade Shop")
    draw_shop_scrolling_text(bitmap, title, 72, center_y - 13, Graphics.width - 270, 26, SHOP_GOLD, SHOP_SHADOW_COLOR, false)
    draw_fragment_value(bitmap, PokemonSurvivor.active_shop_currency(shop_tree_mode), Graphics.width - 190, center_y - 18, 168, 36, SHOP_BLUE, 2, PokemonSurvivor.shop_currency_icon(shop_tree_mode))
  rescue
  end

  def draw_shop_tree_panel(bitmap)
    draw_pixel_round_rect(bitmap, 8, shop_body_top - 4, Graphics.width - 16, shop_body_bottom - shop_body_top + 8, Color.new(14, 18, 30))
    clip = shop_tree_clip_rect
    draw_pixel_round_rect(bitmap, clip.x, clip.y, clip.width, clip.height, Color.new(20, 26, 42))
    draw_inner_glow(bitmap, clip.x, clip.y, clip.width, clip.height, SHOP_BLUE, 42)
    draw_shop_scrolling_background(bitmap, clip)
  rescue
  end

  def draw_shop_scrolling_background(bitmap, clip)
    bg_name = shop_tree_mode == :endless ? "Background_Endless" : "Background"
    bg = cached_bitmap(PokemonSurvivor::SHOP_DIR, bg_name)
    return if !bg || bg.disposed?
    step_x = [bg.width, 1].max
    step_y = [bg.height, 1].max
    surface = cached_shop_background_surface(bg_name, clip.width, clip.height, step_x, step_y)
    return if !surface || surface.disposed?
    offset = ((@shop_bg_frame.to_i / 2) % [step_x, step_y].max)
    src = Rect.new(offset % step_x, offset % step_y, clip.width, clip.height)
    bitmap.blt(clip.x, clip.y, surface, src)
  rescue
  end

  def cached_shop_background_surface(bg_name, clip_w, clip_h, step_x, step_y)
    @shop_background_surface_cache ||= {}
    key = [shop_tree_mode, bg_name, clip_w.to_i, clip_h.to_i, step_x.to_i, step_y.to_i].join(":")
    cached = @shop_background_surface_cache[key]
    return cached if cached && !cached.disposed?
    bg = cached_bitmap(PokemonSurvivor::SHOP_DIR, bg_name)
    return nil if !bg || bg.disposed?
    w = [clip_w.to_i + step_x.to_i, 1].max
    h = [clip_h.to_i + step_y.to_i, 1].max
    surface = Bitmap.new(w, h)
    yy = 0
    while yy < h
      xx = 0
      while xx < w
        surface.blt(xx, yy, bg, Rect.new(0, 0, bg.width, bg.height))
        xx += step_x
      end
      yy += step_y
    end
    if @shop_background_surface_cache.length > 4
      old_key = @shop_background_surface_cache.keys.first
      old = @shop_background_surface_cache.delete(old_key)
      old.dispose if old && !old.disposed?
    end
    @shop_background_surface_cache[key] = surface
    surface
  rescue
    nil
  end

  def shop_screen_pos(node)
    cx = Graphics.width / 2 + (node[:x].to_i * SHOP_CELL_SIZE) - (@shop_camera_x || 0)
    cy = SHOP_HEADER_H + ((Graphics.height - SHOP_HEADER_H - SHOP_FOOTER_H - shop_info_h) / 2) + (node[:y].to_i * SHOP_CELL_SIZE) - (@shop_camera_y || 0)
    [cx, cy]
  rescue
    [Graphics.width / 2, Graphics.height / 2]
  end

  def draw_shop_static_tree(bitmap)
    cache = cached_shop_static_tree
    return if !cache || cache.disposed?
    bitmap.blt(0, 0, cache, Rect.new(0, 0, cache.width, cache.height))
  rescue
  end

  def cached_shop_static_tree
    key = [shop_tree_mode, @shop_camera_x.to_i, @shop_camera_y.to_i, Graphics.width, Graphics.height, shop_info_h, @shop_static_tree_version.to_i].join(":")
    if @shop_static_tree_cache && !@shop_static_tree_cache.disposed? && @shop_static_tree_cache_key == key
      return @shop_static_tree_cache
    end
    @shop_static_tree_cache.dispose if @shop_static_tree_cache && !@shop_static_tree_cache.disposed?
    @shop_static_tree_available_icons = []
    bmp = Bitmap.new(Graphics.width, Graphics.height)
    draw_shop_branch_links(bmp)
    draw_shop_talents(bmp, :static)
    @shop_static_tree_cache = bmp
    @shop_static_tree_cache_key = key
    bmp
  rescue
    nil
  end


  def draw_shop_available_talents(bitmap)
    list = @shop_static_tree_available_icons || []
    if list.empty?
      draw_shop_talents(bitmap, :available)
      return
    end
    clip = shop_tree_clip_rect
    list.each { |node| draw_shop_talent_icon_only(bitmap, node, clip) }
  rescue
  end

  def draw_shop_branch_links(bitmap)
    clip = shop_tree_clip_rect
    nodes = shop_all_nodes
    nodes.each do |node|
      right = shop_node_at(node[:x].to_i + 1, node[:y].to_i)
      down = shop_node_at(node[:x].to_i, node[:y].to_i + 1)
      draw_shop_link_between(bitmap, node, right, clip) if shop_connected_nodes?(node, right)
      draw_shop_link_between(bitmap, node, down, clip) if shop_connected_nodes?(node, down)
    end
    shop_bridge_connections.each { |a, b| draw_shop_link_between(bitmap, a, b, clip) }
  rescue
  end

  def draw_shop_link_between(bitmap, a, b, clip)
    ax, ay = shop_screen_pos(a)
    bx, by = shop_screen_pos(b)
    active = shop_link_active?(a, b)
    if ay == by
      draw_shop_native_link(bitmap, "SlotHorizontal", (ax + bx) / 2, ay, clip, false, !active)
    elsif ax == bx
      draw_shop_native_link(bitmap, "SlotVertical", ax, (ay + by) / 2, clip, false, !active)
    end
  rescue
  end

  def shop_link_active?(a, b)
    return true if !a || !b
    [a, b].all? do |node|
      node[:root] || node[:nav] || shop_node_state(node) != :locked
    end
  rescue
    false
  end
  def draw_shop_native_link(bitmap, name, center_x, center_y, clip, mirror = false, monochrome = false)
    src = monochrome ? cached_shop_monochrome_bitmap(name) : cached_bitmap(PokemonSurvivor::SHOP_DIR, name)
    return if !src || src.disposed?
    x = center_x - (SHOP_TILE_SIZE / 2)
    y = center_y - (SHOP_TILE_SIZE / 2)
    rects = shop_clipped_rect(x, y, SHOP_TILE_SIZE, SHOP_TILE_SIZE, clip)
    return if !rects
    src_rect = Rect.new(
      (rects[1].x * src.width / SHOP_TILE_SIZE.to_f).round,
      (rects[1].y * src.height / SHOP_TILE_SIZE.to_f).round,
      (rects[1].width * src.width / SHOP_TILE_SIZE.to_f).round,
      (rects[1].height * src.height / SHOP_TILE_SIZE.to_f).round
    )
    bitmap.stretch_blt(rects[0], src, src_rect)
  rescue
  end

  def cached_shop_monochrome_bitmap(name)
    @shop_monochrome_cache ||= {}
    cached = @shop_monochrome_cache[name]
    return cached if cached && !cached.disposed?
    src = cached_bitmap(PokemonSurvivor::SHOP_DIR, name)
    return nil if !src || src.disposed?
    mono = Bitmap.new(src.width, src.height)
    for yy in 0...src.height
      for xx in 0...src.width
        color = src.get_pixel(xx, yy)
        next if color.alpha <= 0
        gray = ((color.red * 0.30) + (color.green * 0.59) + (color.blue * 0.11)).round
        r = ((gray * 0.48) + 28).round
        g = ((gray * 0.48) + 34).round
        b = ((gray * 0.48) + 46).round
        mono.set_pixel(xx, yy, Color.new(r, g, b, color.alpha))
      end
    end
    @shop_monochrome_cache[name] = mono
    mono
  rescue
    cached_bitmap(PokemonSurvivor::SHOP_DIR, name)
  end
  def cached_shop_mirrored_bitmap(name)
    @shop_mirrored_cache ||= {}
    cached = @shop_mirrored_cache[name]
    return cached if cached && !cached.disposed?
    src = cached_bitmap(PokemonSurvivor::SHOP_DIR, name)
    return nil if !src || src.disposed?
    mirrored = Bitmap.new(src.width, src.height)
    x = 0
    while x < src.width
      y = 0
      while y < src.height
        mirrored.set_pixel(src.width - 1 - x, y, src.get_pixel(x, y))
        y += 1
      end
      x += 1
    end
    @shop_mirrored_cache[name] = mirrored
    mirrored
  rescue
    cached_bitmap(PokemonSurvivor::SHOP_DIR, name)
  end
  def draw_shop_talents(bitmap, layer = :all)
    clip = shop_tree_clip_rect
    selected = selected_shop_node
    shop_all_nodes.each do |node|
      cx, cy = shop_screen_pos(node)
      x = cx - (SHOP_TILE_SIZE / 2)
      y = cy - (SHOP_TILE_SIZE / 2)
      next if x + SHOP_TILE_SIZE <= clip.x || y + SHOP_TILE_SIZE <= clip.y || x >= clip.x + clip.width || y >= clip.y + clip.height
      animated = shop_node_icon_animated?(node)
      if layer == :static && animated
        draw_shop_talent_frame_only(bitmap, node, x, y, clip)
        @shop_static_tree_available_icons << node if @shop_static_tree_available_icons
        next
      end
      next if layer == :available && !animated
      draw_shop_talent(bitmap, node, x, y, node == selected, clip)
    end
  rescue
  end

  def draw_shop_talent(bitmap, node, x, y, selected, clip)
    draw_shop_talent_frame_only(bitmap, node, x, y, clip)
    draw_shop_talent_icon_only(bitmap, node, clip)
  rescue
  end

  def draw_shop_talent_frame_only(bitmap, node, x, y, clip)
    frame_name = shop_slot_frame_name(node)
    state = (node[:root] || node[:nav]) ? :bought : shop_node_state(node)
    draw_shop_bitmap(bitmap, frame_name, x, y, SHOP_TILE_SIZE, SHOP_TILE_SIZE, clip, state == :locked)
  rescue
  end

  def draw_shop_talent_icon_only(bitmap, node, clip)
    cx, cy = shop_screen_pos(node)
    state = (node[:root] || node[:nav]) ? :bought : shop_node_state(node)
    if node[:root] || node[:nav]
      draw_shop_upgrade_icon(bitmap, node[:icon], cx, cy, 1.0, clip, :bought, false) if node[:icon]
      return
    end
    enough = shop_node_affordable?(node)
    scale = 1.0
    if node[:upgrade][:id] == :endless_candy_exchange && PokemonSurvivor.shop_upgrade_level(:endless_candy_exchange) > 0
      # Keep repeat purchases available while retaining the icon's original colors.
      scale = shop_breath_scale if state == :available && enough
      state = :bought
    end
    draw_shop_upgrade_icon(bitmap, node[:icon] || "Exp", cx, cy, scale, clip, state, enough)
  rescue
  end

  def shop_node_icon_animated?(node)
    return false if !node || node[:root] || node[:nav]
    shop_node_state(node) == :available && shop_node_affordable?(node)
  rescue
    false
  end

  def shop_node_affordable?(node)
    return false if !node || !node[:upgrade]
    costs = node[:upgrade][:costs] || []
    cost = costs[node[:level].to_i - 1].to_i
    PokemonSurvivor.active_shop_currency(shop_tree_mode) >= cost
  rescue
    false
  end

  def shop_icon_state_color(state, enough = false)
    case state
    when :bought
      Color.new(118, 255, 172)
    when :locked
      Color.new(118, 126, 142)
    else
      nil
    end
  rescue
    nil
  end

  def shop_icon_state_scale(state, enough)
    1.0
  rescue
    1.0
  end
  def shop_node_bought?(node)
    return false if !node || !node[:upgrade]
    return false if node[:upgrade][:infinite]
    PokemonSurvivor.shop_upgrade_level(node[:upgrade][:id]) >= node[:level].to_i
  rescue
    false
  end

  def shop_node_connected_to_core?(node)
    shop_connected_nodes?(shop_root_node, node)
  rescue
    false
  end

  def shop_node_connected_to_bought?(node)
    return false if !node
    rebuild_shop_tree_cache if !@shop_node_id_cache
    shop_tree_links.any? do |left, right|
      other_id = nil
      other_id = right if left == node[:id]
      other_id = left if right == node[:id]
      next false if !other_id
      other = @shop_node_id_cache[other_id]
      shop_node_bought?(other)
    end
  rescue
    false
  end

  def shop_node_progress_available?(node)
    return false if !node || !node[:upgrade]
    if node[:upgrade][:infinite]
      return false if !PokemonSurvivor.shop_tree_complete?(:endless)
      return true if shop_node_connected_to_core?(node)
      return shop_node_connected_to_bought?(node)
    end
    current = PokemonSurvivor.shop_upgrade_level(node[:upgrade][:id])
    return false if node[:level].to_i != current + 1
    return true if shop_node_connected_to_core?(node)
    shop_node_connected_to_bought?(node)
  rescue
    false
  end

  def shop_node_state(node)
    return :locked if !node
    @shop_state_cache ||= {}
    cached = @shop_state_cache[node[:id]]
    return cached if cached
    state = if shop_node_bought?(node)
              :bought
            elsif shop_node_progress_available?(node)
              :available
            else
              :locked
            end
    @shop_state_cache[node[:id]] = state
    state
  rescue
    :locked
  end

  def draw_shop_info(bitmap)
    return if @shop_show_details == false
    node = selected_shop_node
    return if !node
    return draw_shop_root_info(bitmap) if node[:root]
    return draw_shop_nav_info(bitmap, node) if node[:nav]
    data = node[:upgrade]
    y = Graphics.height - SHOP_FOOTER_H - shop_info_h + 8
    level = PokemonSurvivor.shop_upgrade_level(data[:id])
    max = PokemonSurvivor.shop_upgrade_max(data[:id])
    state = shop_node_state(node)
    cost = (data[:costs] || [])[node[:level].to_i - 1].to_i
    enough = PokemonSurvivor.active_shop_currency(shop_tree_mode) >= cost
    status = case state
             when :bought then _INTL("Unlocked")
             when :available then (enough ? _INTL("Available") : _INTL("Locked"))
             else _INTL("Locked")
             end
    status_color = state == :bought ? SHOP_GREEN : ((state == :available && enough) ? SHOP_GOLD : SHOP_RED)
    title = data[:infinite] ? _INTL(data[:name].to_s) : _INTL("{1} {2}", _INTL(data[:name].to_s), node[:level].to_i)
    draw_shop_scrolling_text(bitmap, title, 22, y, Graphics.width - 170, 22, shop_upgrade_title_color(data), SHOP_SHADOW_COLOR, false)
    draw_shop_scrolling_text(bitmap, status, Graphics.width - 150, y, 128, 22, status_color, SHOP_SHADOW_COLOR, true)
    draw_shop_scrolling_description(bitmap, _INTL(data[:desc].to_s), 22, y + 25, Graphics.width - 44, 36)
    draw_shop_upgrade_cost(bitmap, data, node, level, max, 22, y + 62, Graphics.width - 44, 48)
  rescue
  end

  def draw_shop_nav_info(bitmap, node)
    y = Graphics.height - SHOP_FOOTER_H - shop_info_h + 8
    draw_shop_scrolling_text(bitmap, _INTL(node[:name].to_s), 22, y, Graphics.width - 44, 22, SHOP_GOLD, SHOP_SHADOW_COLOR, false)
    draw_shop_scrolling_description(bitmap, _INTL(node[:desc].to_s), 22, y + 30, Graphics.width - 44, 52)
    draw_shop_scrolling_text(bitmap, _INTL("Current shop upgrades are disabled in Endless Mode."), 22, y + 78, Graphics.width - 44, 26, SHOP_DIM_COLOR, SHOP_SHADOW_COLOR, false)
  rescue
  end

  def draw_shop_root_info(bitmap)
    y = Graphics.height - SHOP_FOOTER_H - shop_info_h + 8
    node = shop_root_node
    draw_shop_scrolling_text(bitmap, _INTL(node[:name].to_s), 22, y, Graphics.width - 44, 22, SHOP_GOLD, SHOP_SHADOW_COLOR, false)
    draw_shop_scrolling_description(bitmap, _INTL(node[:desc].to_s), 22, y + 30, Graphics.width - 44, 52)
    footer = if shop_tree_mode == :endless
               _INTL("Choose this core to return to the classic tree.")
             elsif endless_shop_unlocked?
               _INTL("Choose this core to open the Endless Kecleon Shop.")
             else
               _INTL("Complete every standard upgrade to unlock the Endless Kecleon Shop.")
             end
    draw_shop_scrolling_text(bitmap, footer, 22, y + 78, Graphics.width - 44, 26, SHOP_DIM_COLOR, SHOP_SHADOW_COLOR, false)
  rescue
  end

  def shop_upgrade_title_color(data)
    case data && data[:effect]
    when :xp_gain_percent
      Color.new(112, 255, 154)
    when :coin_gain_percent
      Color.new(255, 218, 92)
    when :max_hp_percent
      Color.new(255, 116, 116)
    when :damage_percent
      Color.new(255, 154, 82)
    when :speed_percent
      Color.new(120, 224, 255)
    when :burst_charge_percent, :starting_burst_percent
      Color.new(184, 132, 255)
    when :early_level_xp_percent
      Color.new(255, 244, 146)
    when :fatal_guard_charges
      Color.new(255, 128, 196)
    when :reroll_bonus
      Color.new(126, 246, 226)
    when :ban_bonus
      Color.new(196, 154, 255)
    when :endless_xp_gain_percent
      Color.new(112, 255, 154)
    when :endless_max_hp_percent
      Color.new(255, 116, 116)
    when :endless_damage_percent
      Color.new(255, 154, 82)
    when :endless_speed_percent
      Color.new(120, 224, 255)
    when :endless_burst_charge_percent
      Color.new(184, 132, 255)
    when :endless_pressure_relief_percent
      Color.new(255, 244, 146)
    when :endless_draft_bonus
      Color.new(126, 246, 226)
    when :endless_fatal_guard_charges
      Color.new(255, 128, 196)
    when :candy_exchange_amount
      Color.new(255, 186, 112)
    else
      SHOP_BASE_COLOR
    end
  rescue
    SHOP_BASE_COLOR
  end
  def draw_shop_upgrade_cost(bitmap, data, node, current_level, max, x, y, w, h, align_right = false)
    if shop_node_state(node) == :bought
      text = _INTL("Level {1}/{2} unlocked.", node[:level].to_i, max)
      draw_shop_scrolling_text(bitmap, text, x, y + 6, w, h - 6, SHOP_GREEN, SHOP_SHADOW_COLOR, align_right)
      return
    end
    state = shop_node_state(node)
    value = shop_upgrade_preview_value(data, node[:level])
    prefix = if data[:infinite]
               state == :available ? _INTL("Bonus: {1}  Cost:", shop_value_label(data, value)) : _INTL("Complete the Endless Kecleon Shop first.  Cost:")
             else
               state == :available ? _INTL("Bonus: {1}  Cost:", shop_value_label(data, value)) : _INTL("Requires level {1} first.  Cost:", node[:level].to_i - 1)
             end
    cost_index = data[:infinite] ? 0 : node[:level].to_i - 1
    qty_text = (data[:costs] || [])[cost_index].to_i.to_s
    color = (state == :available && PokemonSurvivor.active_shop_currency(shop_tree_mode) >= qty_text.to_i) ? SHOP_GOLD : SHOP_RED
    line = cached_shop_upgrade_cost_bitmap(prefix, qty_text, PokemonSurvivor.shop_currency_icon(shop_tree_mode), w, h, color)
    return if !line || line.disposed?
    offset = shop_scroll_offset([line.width - w + 10, 0].max, 5, 70)
    src_x = align_right && line.width <= w ? 0 : offset
    draw_x = align_right && line.width <= w ? x + w - line.width : x
    bitmap.blt(draw_x, y, line, Rect.new(src_x, 0, [w, line.width].min, h))
  rescue
  end

  def cached_shop_upgrade_cost_bitmap(prefix, qty_text, icon_path, w, h, color)
    @shop_upgrade_cost_cache ||= {}
    w = [w.to_i, 1].max
    h = [h.to_i, 1].max
    key = [prefix.to_s, qty_text.to_s, icon_path.to_s, h, color.red, color.green, color.blue, color.alpha].join(":")
    cached = @shop_upgrade_cost_cache[key]
    return cached if cached && !cached.disposed?
    icon = cached_icon_bitmap(icon_path)
    icon_w = icon && !icon.disposed? ? icon.width : 0
    icon_h = icon && !icon.disposed? ? icon.height : 0
    gap = 4
    probe = @sprites && @sprites["screen"] ? @sprites["screen"].bitmap : nil
    pbSetSystemFont(probe) if probe
    text_w = probe ? (probe.text_size(prefix.to_s).width rescue prefix.to_s.length * 10) : prefix.to_s.length * 10
    qty_w = probe ? (probe.text_size(qty_text.to_s).width rescue qty_text.to_s.length * 10) : qty_text.to_s.length * 10
    total_w = [text_w + gap + icon_w + gap + qty_w, w, 1].max
    bmp = Bitmap.new(total_w, h)
    pbSetSystemFont(bmp)
    text_y = ((h - 22) / 2)
    pbDrawTextPositions(bmp, [[prefix.to_s, 0, text_y, false, color, SHOP_SHADOW_COLOR]])
    icon_x = text_w + gap
    bmp.blt(icon_x, ((h - icon_h) / 2), icon, Rect.new(0, 0, icon.width, icon.height)) if icon && !icon.disposed?
    pbDrawTextPositions(bmp, [[qty_text.to_s, icon_x + icon_w + gap, text_y, false, color, SHOP_SHADOW_COLOR]])
    if @shop_upgrade_cost_cache.length > 96
      old_key = @shop_upgrade_cost_cache.keys.first
      old = @shop_upgrade_cost_cache.delete(old_key)
      old.dispose if old && !old.disposed?
    end
    @shop_upgrade_cost_cache[key] = bmp
    bmp
  rescue
    nil
  end

  def draw_shop_footer(bitmap)
    detail_text = @shop_show_details == false ? _INTL("Show Details") : _INTL("Hide Details")
    draw_help(bitmap, [[:up, ""], [:down, ""], [:left, ""], [:right, _INTL("Navigate")], [:confirm, shop_buy_help_label], [:ready_menu, _INTL("Next Buy")], [:action, detail_text], [:cancel, _INTL("Close")]])
  rescue
  end

  def shop_buy_help_label
    node = selected_shop_node
    return _INTL("Switch") if node && node[:root] && (shop_tree_mode == :endless || endless_shop_unlocked?)
    return _INTL("Core") if !node || node[:root] || node[:nav]
    return _INTL("Bought") if shop_node_state(node) == :bought
    return _INTL("Buy") if shop_node_state(node) == :available
    _INTL("Locked")
  rescue
    _INTL("Buy")
  end

  def shop_slot_frame_name(node)
    dirs = shop_connection_dirs(node)
    return shop_tree_mode == :endless ? "SlotAll" : "SlotLeftRight" if node[:root]
    return "SlotNeutrals" if node[:nav]
    return "SlotNeutrals" if dirs.empty?
    left = dirs.include?(:left)
    right = dirs.include?(:right)
    up = dirs.include?(:up)
    down = dirs.include?(:down)
    return "SlotLeftRight" if left && right && !up && !down
    return "SlotUpDown" if up && down && !left && !right
    return "SlotLeftDown" if left && down && !up && !right
    return "SlotLeftUp" if left && up && !down && !right
    return "SlotRightDown" if right && down && !up && !left
    return "SlotUpRight" if right && up && !down && !left
    return "SlotAll" if left && right && up && down
    return "SlotLeftRightDown" if left && right && down && !up
    return "SlotUpLeftDown" if up && left && down && !right
    return "SlotUpLeftRight" if up && left && right && !down
    return "SlotUpRightDown" if up && right && down && !left
    return "SlotLeft" if left
    return "SlotRight" if right
    return "SlotUp" if up
    return "SlotDown" if down
    "SlotNeutrals"
  rescue
    "SlotNeutrals"
  end

  def shop_connection_dirs(node)
    dirs = []
    [[-1, 0, :left], [1, 0, :right], [0, -1, :up], [0, 1, :down]].each do |dx, dy, dir|
      other = shop_node_at(node[:x].to_i + dx, node[:y].to_i + dy)
      dirs << dir if shop_connected_nodes?(node, other)
    end
    dirs.uniq
  rescue
    []
  end

  def shop_tree_position(id)
    node = shop_all_nodes.find { |n| n[:id] == id }
    node ? [node[:x], node[:y]] : [0, 0]
  rescue
    [0, 0]
  end

  def shop_upgrade_preview_value(data, level)
    values = data[:values] || []
    return 0 if values.empty? || level.to_i <= 0
    values[[level.to_i - 1, values.length - 1].min].to_i
  rescue
    0
  end

  def shop_value_label(data, value)
    case data[:effect]
    when :reroll_bonus, :ban_bonus, :fatal_guard_charges, :endless_draft_bonus, :endless_fatal_guard_charges, :pokemon_draft_bonus
      _INTL("+{1}", value.to_i)
    when :candy_exchange_amount
      _INTL("+{1} Candies", value.to_i)
    when :pokemon_equipment_slot, :pokemon_shiny_unlock
      _INTL("Unlock")
    else
      _INTL("+{1}%", value.to_i)
    end
  rescue
    value.to_s
  end

  def shop_breath_scale
    frame = @state == :pokemon_training ? @training_bg_frame.to_i : @shop_bg_frame.to_i
    phase = (frame % 48) * Math::PI * 2.0 / 48.0
    0.93 + ((1.0 - Math.cos(phase)) * 0.04)
  rescue
    1.0
  end
  def draw_shop_upgrade_icon(bitmap, name, cx, cy, scale = 0.65, clip = nil, state = nil, enough = false)
    icon = cached_shop_state_icon(name, state, enough) || cached_bitmap(PokemonSurvivor::SHOP_DIR, name)
    return if !icon || icon.disposed?
    scale = scale.to_f * shop_breath_scale if state == :available && enough
    w = (icon.width * scale.to_f).round
    h = (icon.height * scale.to_f).round
    x = (cx - w / 2).round
    y = (cy - h / 2).round
    rects = shop_clipped_rect(x, y, w, h, clip)
    return if !rects
    src = Rect.new((rects[1].x * icon.width / w.to_f).round, (rects[1].y * icon.height / h.to_f).round, (rects[1].width * icon.width / w.to_f).round, (rects[1].height * icon.height / h.to_f).round)
    bitmap.stretch_blt(rects[0], icon, src)
  rescue
  end

  def cached_shop_state_icon(name, state, enough)
    return nil if state == :bought
    return cached_shop_monochrome_bitmap(name) if state == :available
    tint = shop_icon_state_color(state, enough)
    return nil if !tint
    base = cached_bitmap(PokemonSurvivor::SHOP_DIR, name)
    return nil if !base || base.disposed?
    key = "#{PokemonSurvivor::SHOP_DIR}/#{name}:#{state}:plain"
    cached = @bitmaps[key]
    return cached if cached && !cached.disposed?
    tinted = Bitmap.new(base.width, base.height)
    for yy in 0...base.height
      for xx in 0...base.width
        src = base.get_pixel(xx, yy)
        next if src.alpha <= 0
        gray = ((src.red * 0.30) + (src.green * 0.59) + (src.blue * 0.11)).round
        strength = state == :locked ? 0.50 : 0.62
        r = [(gray * (1.0 - strength)) + (tint.red * strength), 255].min.round
        g = [(gray * (1.0 - strength)) + (tint.green * strength), 255].min.round
        b = [(gray * (1.0 - strength)) + (tint.blue * strength), 255].min.round
        a = src.alpha
        tinted.set_pixel(xx, yy, Color.new(r, g, b, a))
      end
    end
    @bitmaps[key] = tinted
    tinted
  rescue
    nil
  end
  def draw_shop_bitmap(bitmap, name, x, y, w, h, clip = nil, monochrome = false)
    src = monochrome ? cached_shop_monochrome_bitmap(name) : cached_bitmap(PokemonSurvivor::SHOP_DIR, name)
    if src && !src.disposed?
      rects = shop_clipped_rect(x, y, w, h, clip)
      return if !rects
      src_rect = Rect.new((rects[1].x * src.width / w.to_f).round, (rects[1].y * src.height / h.to_f).round, (rects[1].width * src.width / w.to_f).round, (rects[1].height * src.height / h.to_f).round)
      bitmap.stretch_blt(rects[0], src, src_rect)
    else
      shop_fill_rect_clipped(bitmap, x, y, w, h, Color.new(42, 50, 70), clip)
    end
  rescue
  end

  def shop_clipped_rect(x, y, w, h, clip)
    return [Rect.new(x, y, w, h), Rect.new(0, 0, w, h)] if !clip
    dx1 = [x, clip.x].max
    dy1 = [y, clip.y].max
    dx2 = [x + w, clip.x + clip.width].min
    dy2 = [y + h, clip.y + clip.height].min
    return nil if dx2 <= dx1 || dy2 <= dy1
    [Rect.new(dx1, dy1, dx2 - dx1, dy2 - dy1), Rect.new(dx1 - x, dy1 - y, dx2 - dx1, dy2 - dy1)]
  rescue
    nil
  end

  def shop_fill_rect_clipped(bitmap, x, y, w, h, color, clip)
    rects = shop_clipped_rect(x, y, w, h, clip)
    return if !rects
    bitmap.fill_rect(rects[0].x, rects[0].y, rects[0].width, rects[0].height, color)
  rescue
  end

  def draw_shop_clipped_text(bitmap, text, x, y, w, h, color, shadow, align_right = false, clip = nil)
    return if w <= 0 || h <= 0
    temp = cached_shop_text_bitmap(text.to_s, w, h, color, shadow, align_right)
    return if !temp || temp.disposed?
    rects = shop_clipped_rect(x, y, w, h, clip)
    bitmap.blt(rects[0].x, rects[0].y, temp, rects[1]) if rects
  rescue
  end

  def cached_shop_text_bitmap(text, w, h, color, shadow, align_right = false)
    @shop_text_cache ||= {}
    w = [w.to_i, 1].max
    h = [h.to_i, 1].max
    key = [text.to_s, w, h, align_right ? 1 : 0, color.red, color.green, color.blue, color.alpha, shadow.red, shadow.green, shadow.blue, shadow.alpha].join(":")
    cached = @shop_text_cache[key]
    return cached if cached && !cached.disposed?
    bmp = Bitmap.new(w, h)
    pbSetSystemFont(bmp)
    pbDrawTextPositions(bmp, [[text.to_s, align_right ? w - 2 : 0, 0, align_right, color, shadow]])
    if @shop_text_cache.length > 128
      old_key = @shop_text_cache.keys.first
      old = @shop_text_cache.delete(old_key)
      old.dispose if old && !old.disposed?
    end
    @shop_text_cache[key] = bmp
    bmp
  rescue
    nil
  end

  def shop_scroll_frame
    return @training_bg_frame.to_i if @state == :pokemon_training && !@training_bg_frame.nil?
    @shop_bg_frame.to_i
  rescue
    0
  end

  def shop_scroll_offset(distance, frames_per_pixel = 4, pause = 55)
    return 0 if distance <= 0
    travel = [distance.to_i * [frames_per_pixel, 1].max, 1].max
    cycle = (pause * 2) + (travel * 2)
    pos = shop_scroll_frame % cycle
    return 0 if pos < pause
    pos -= pause
    if pos < travel
      t = pos / travel.to_f
      return (distance * ((1.0 - Math.cos(t * Math::PI)) / 2.0)).round
    end
    pos -= travel
    return distance if pos < pause
    pos -= pause
    t = pos / travel.to_f
    (distance * ((1.0 + Math.cos(t * Math::PI)) / 2.0)).round
  rescue
    0
  end

  def draw_shop_scrolling_text(bitmap, text, x, y, w, h, color, shadow, align_right = false)
    w = [w.to_i, 1].max
    h = [h.to_i, 1].max
    text = text.to_s
    line = cached_shop_scrolling_text_bitmap(text, w, h, color, shadow)
    return if !line || line.disposed?
    text_w = line.width
    offset = shop_scroll_offset(text_w - w, 5, 70)
    src_x = align_right && text_w <= w ? 0 : offset
    draw_x = align_right && text_w <= w ? x + w - text_w : x
    bitmap.blt(draw_x, y, line, Rect.new(src_x, 0, [w, text_w].min, h))
  rescue
  end

  def cached_shop_scrolling_text_bitmap(text, w, h, color, shadow)
    @shop_scrolling_text_cache ||= {}
    probe = @sprites && @sprites["screen"] ? @sprites["screen"].bitmap : nil
    pbSetSystemFont(probe) if probe
    text_w = probe ? (probe.text_size(text.to_s).width rescue text.to_s.length * 10) : text.to_s.length * 10
    width = [text_w.to_i + 24, w.to_i, 1].max
    key = [text.to_s, width, h.to_i, color.red, color.green, color.blue, color.alpha, shadow.red, shadow.green, shadow.blue, shadow.alpha].join(":")
    cached = @shop_scrolling_text_cache[key]
    return cached if cached && !cached.disposed?
    bmp = Bitmap.new(width, [h.to_i, 1].max)
    pbSetSystemFont(bmp)
    pbDrawTextPositions(bmp, [[text.to_s, 0, 0, false, color, shadow]])
    if @shop_scrolling_text_cache.length > 96
      old_key = @shop_scrolling_text_cache.keys.first
      old = @shop_scrolling_text_cache.delete(old_key)
      old.dispose if old && !old.disposed?
    end
    @shop_scrolling_text_cache[key] = bmp
    bmp
  rescue
    nil
  end

  def draw_shop_scrolling_description(bitmap, text, x, y, w, h)
    line_h = 21
    lines = shop_wrapped_lines(bitmap, text, w)
    total_h = [lines.length * line_h, h].max
    offset = shop_scroll_offset(total_h - h, 6, 75)
    block = cached_shop_description_bitmap(lines, w, total_h, line_h)
    bitmap.blt(x, y, block, Rect.new(0, offset, w, h)) if block && !block.disposed?
  rescue
  end

  def cached_shop_description_bitmap(lines, w, total_h, line_h)
    @shop_description_cache ||= {}
    w = [w.to_i, 1].max
    total_h = [total_h.to_i, 1].max
    key = [lines.join("\n"), w, total_h, line_h.to_i].join(":")
    cached = @shop_description_cache[key]
    return cached if cached && !cached.disposed?
    bmp = Bitmap.new(w, total_h)
    pbSetSystemFont(bmp)
    lines.each_with_index { |line, i| pbDrawTextPositions(bmp, [[line, 0, i * line_h, false, SHOP_DIM_COLOR, SHOP_SHADOW_COLOR]]) }
    if @shop_description_cache.length > 64
      old_key = @shop_description_cache.keys.first
      old = @shop_description_cache.delete(old_key)
      old.dispose if old && !old.disposed?
    end
    @shop_description_cache[key] = bmp
    bmp
  rescue
    nil
  end

  def shop_wrapped_lines(bitmap, text, max_width)
    lines = wrapped_lines(bitmap, text, max_width)
    lines.empty? ? [text.to_s] : lines
  rescue
    [text.to_s]
  end

  def selection_shop_purchase_available?
    tree = PokemonSurvivor.endless_shop_currency_unlocked? ? :endless : :standard
    currency = PokemonSurvivor.active_shop_currency(tree)
    upgrades = PokemonSurvivor.shop_upgrades(tree)
    levels = upgrades.map { |data| PokemonSurvivor.shop_upgrade_level(data[:id]) }
    key = [tree, currency, levels]
    return @selection_shop_purchase_available if @selection_shop_purchase_key == key

    layout = tree == :endless ? ENDLESS_SHOP_TREE_LAYOUT : SHOP_TREE_LAYOUT
    links = tree == :endless ? ENDLESS_SHOP_TREE_LINKS : SHOP_TREE_LINKS
    data_by_id = {}
    level_by_id = {}
    upgrades.each_with_index do |data, index|
      data_by_id[data[:id]] = data
      level_by_id[data[:id]] = levels[index]
    end
    complete = upgrades.all? { |data| data[:infinite] || level_by_id[data[:id]] >= (data[:values] || []).length }
    bought = { :shop_core => true }
    candidates = []
    layout.each do |id, level, _x, _y|
      data = data_by_id[id]
      next if !data
      next if !data[:infinite] && level > (data[:values] || []).length
      node_id = shop_node_id(id, level)
      current = level_by_id[id]
      if !data[:infinite] && current >= level
        bought[node_id] = true
        next
      end
      next unless data[:infinite] ? complete : level == current + 1
      cost = (data[:costs] || [])[level - 1]
      candidates << node_id if cost && currency >= cost.to_i
    end
    @selection_shop_purchase_available = candidates.any? do |node_id|
      links.any? do |left, right|
        (left == node_id && bought[right]) || (right == node_id && bought[left])
      end
    end
    @selection_shop_purchase_key = key
    @selection_shop_purchase_available
  end

  def draw_shop_header_button(bitmap, x, y, w, h, selected = false)
    fill = selected ? Color.new(116, 92, 176) : Color.new(42, 34, 78)
    edge = Color.new(142, 96, 190)
    shine = selected ? Color.new(246, 224, 255) : Color.new(214, 166, 255)
    draw_modern_button_frame(bitmap, x, y, w, h, edge, fill, shine, selected)
    draw_select_fragment_value(bitmap, PokemonSurvivor.selection_shop_currency, x, y, w, h, SHOP_GREEN, 0, PokemonSurvivor.selection_shop_currency_icon)
    if selection_shop_purchase_available?
      draw_menu_notification(bitmap, x, y)
    end
  rescue
  end

  def draw_select_fragment_value(bitmap, value, x, y, w, h, color = SHOP_GOLD, align = 0, icon_name = "ICON_FRAGMENT")
    icon = cached_icon_bitmap(icon_name)
    text = icon_name == "ICON_DARKFRAGMENT" ? PokemonSurvivor.dark_fragment_balance_text(value) : value.to_i.to_s
    pad = 4
    icon_w = icon && !icon.disposed? ? icon.width : 0
    icon_h = icon && !icon.disposed? ? icon.height : 0
    gap = icon_w > 0 ? 4 : 0
    icon_x = x + pad
    text_x = icon_x + icon_w + gap
    text_w = [x + w - text_x - pad, 20].max
    if icon && !icon.disposed?
      bitmap.blt(icon_x, y + ((h - icon_h) / 2), icon, Rect.new(0, 0, icon.width, icon.height))
    end
    draw_text_box(bitmap, text, text_x, y + ((h - 20) / 2), text_w, 20, color, SHOP_SHADOW_COLOR, 0)
  rescue
    draw_text_box(bitmap, text || value.to_s, x + 4, y, w - 8, h, color, SHOP_SHADOW_COLOR, align)
  end

  def draw_fragment_value(bitmap, value, x, y, w, h, color = SHOP_GOLD, align = 2, icon_name = "ICON_FRAGMENT")
    icon = cached_icon_bitmap(icon_name)
    text = icon_name == "ICON_DARKFRAGMENT" ? PokemonSurvivor.dark_fragment_balance_text(value) : value.to_i.to_s
    text_w = bitmap.text_size(text).width rescue (text.length * 8)
    icon_w = icon && !icon.disposed? ? icon.width : 0
    icon_h = icon && !icon.disposed? ? icon.height : 0
    gap = icon_w > 0 ? 4 : 0
    total = icon_w + gap + text_w
    start_x = case align.to_i
              when 1 then x + ((w - total) / 2)
              when 2 then x + w - total
              else x
              end
    if icon && !icon.disposed?
      bitmap.blt(start_x, y + ((h - icon_h) / 2), icon, Rect.new(0, 0, icon.width, icon.height))
    end
    draw_text_box(bitmap, text, start_x + icon_w + gap, y + ((h - 20) / 2), text_w + 2, 20, color, SHOP_SHADOW_COLOR, 0)
  rescue
    draw_text_box(bitmap, text || value.to_s, x, y, w, h, color, SHOP_SHADOW_COLOR, align)
  end

end

























































