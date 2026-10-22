module SurvivorTitanMenus
  TITAN_MENU_PALETTES = {
    start: [[82, 178, 118], [26, 62, 42], [154, 238, 174]],
    training: [[84, 150, 224], [28, 48, 78], [150, 192, 255]],
    shop: [[255, 196, 86], [62, 42, 24], [255, 232, 140]],
    milestones: [[178, 126, 232], [52, 32, 76], [224, 190, 255]],
    leaderboard: [[72, 196, 196], [22, 58, 62], [152, 244, 236]],
    cancel: [[176, 72, 76], [68, 28, 36], [255, 142, 132]]
  }.freeze
  TITAN_MENU_ACTIONS = [:start, :training, :shop, :milestones, :leaderboard, :cancel].freeze

  def draw_titan_menu_button(bitmap, x, y, w, h, selected, index)
    palette = TITAN_MENU_PALETTES.fetch(TITAN_MENU_ACTIONS.fetch(index))
    edge, fill, shine = palette.map { |rgb| Color.new(*rgb) }
    if selected
      fill = Color.new([fill.red + 34, 255].min, [fill.green + 34, 255].min, [fill.blue + 34, 255].min)
      shine = Color.new([shine.red + 22, 255].min, [shine.green + 22, 255].min, [shine.blue + 22, 255].min)
    end
    draw_modern_button_frame(bitmap, x, y, w, h, edge, fill, shine, selected)
  end

  def breach_open_season
    previous_menu_bgm = @survivor_menu_bgm
    @survivor_menu_bgm = "Survivor/Breach"
    play_survivor_menu_bgm
    loop do
      @season_notification_chooser = true
      choice = breach_choose(_INTL("Breach"), [
        [_INTL("Breach"), _INTL("Explore the current season's rooms.")],
        [_INTL("Titan"), _INTL("Join other players to defeat the seasonal Titan.")],
        [_INTL("Challenge"), _INTL("Beat another player's record to climb the seasonal rankings.")],
        [_INTL("Cancel"), _INTL("Return to classic modes.")]
      ])
      @season_notification_chooser = false
      break if choice.nil? || choice == 3
      case choice
      when 0 then super
      when 1 then titan_open_menu
      when 2 then challenge_open_menu
      end
      return if @state == :play
    end
  ensure
    @season_notification_chooser = false
    @survivor_menu_bgm = previous_menu_bgm
    play_survivor_menu_bgm unless @state == :play
    draw_select if @state == :select
    @last_time = System.uptime
    @accumulator = 0.0
    Input.update
  end

  def titan_open_menu
    previous_menu_bgm = @survivor_menu_bgm
    @survivor_menu_bgm = "Survivor/Titan"
    play_survivor_menu_bgm
    while PokemonSurvivor.titan_notification_refresh_pending?
      Graphics.update
      Input.update
      PokemonSurvivor.online_retry_tick(true)
      draw_breach_menu(_INTL("Titan"), [], 0, _INTL("Connecting to Titan..."))
    end
    @titan_store = PokemonSurvivor::Titan::OnlineState.new(PokemonSurvivor.survivor_progress,
      proc { |&job| titan_wait_online(&job) },
      proc { breach_save_menu_progress })
    unless @titan_store.connect
      titan_online_error
      return
    end
    @titan_menu_season = @titan_store.season
    breach_save_menu_progress
    loop do
      data = @titan_store.snapshot
      choice = titan_choose_menu(_INTL("Breach Titan - Season {1}", @titan_store.season_id), [
        [_INTL("Start a run"), _INTL("Choose your Pokemon and face the Titan. Healing is disabled.")],
        [_INTL("Upgrades"), _INTL("Spend Ores to grow stronger in Titan runs this season.")],
        [_INTL("Secret Shop"), _INTL("Trade Crystal Shards for rewards and exclusive unlocks.")],
        [_INTL("Crystal Bounty"), _INTL("Collect Crystal Shards as the Titan loses health.")],
        [_INTL("Leaderboard"), _INTL("See the rankings by total damage dealt to the Titan.")],
        [_INTL("Cancel"), _INTL("Return to the Breach mode selection.")]
      ], "")
      break if choice.nil? || choice == 5
      case choice
      when 0
        if data[:hp] <= 0
          pbMessage(_INTL("This season's Titan has already been defeated."))
          next
        end
        hero = titan_choose_pokemon
        next unless hero
        next unless seasonal_run_version_allowed?
        return if titan_prepare_run(hero)
        next
      when 1 then titan_tree_menu(:training)
      when 2 then titan_tree_menu(:shop)
      when 3 then titan_milestones_menu
      when 4 then titan_leaderboard_menu
      end
      # Purchases, claims and leaderboard responses already update the snapshot.
      # Merely returning from a submenu must not issue another status request.
      @titan_menu_season = @titan_store.season
    end
  ensure
    breach_save_menu_progress
    @survivor_menu_bgm = previous_menu_bgm
    play_survivor_menu_bgm unless @state == :play
  end

  def titan_wait_online
    return breach_wait(_INTL("Connecting to Titan...")) { yield } unless [:training, :shop].include?(@titan_tree_kind)
    # Keep the shop animated, but do not accept another purchase while awaiting validation.
    worker = Thread.new do
      begin
        yield
      rescue StandardError
        nil
      end
    end
    while worker.alive?
      Graphics.update
      Input.update
      update_shop_background_animation
      draw_shop
    end
    worker.value
  ensure
    @last_time = System.uptime
    @accumulator = 0.0
    Input.update
  end

  def titan_online_error
    if @titan_store && @titan_store.last_error == "season_unavailable"
      pbMessage(_INTL("There is no open Titan season right now."))
    elsif @titan_store && @titan_store.last_error == "save_failed"
      pbMessage(_INTL("Your progress could not be saved. Titan cannot continue safely."))
    elsif @titan_store && @titan_store.last_error == "unsupported_season"
      pbMessage(_INTL("Update the game to play this Titan season."))
    else
      pbMessage(_INTL("Titan could not connect. Please try again. Pending results are kept for the next connection."))
    end
  end

  def titan_choose_pokemon
    @titan_pokemon_picker = true
    breach_choose_pokemon
  ensure
    @titan_pokemon_picker = false
  end

  def titan_menu_neighbor(index, direction)
    case direction
    when :up then [5, 0, 0, 1, 2, 3][index]
    when :down then [1, 3, 4, 5, 5, 0][index]
    when :left, :right then [0, 2, 1, 4, 3, 5][index]
    else index
    end
  end

  def titan_choose_menu(title, entries, footer)
    index, released = 0, false
    Input.update
    loop do
      Graphics.update
      Input.update
      old = index
      { up: Input::UP, down: Input::DOWN, left: Input::LEFT, right: Input::RIGHT }.each do |direction, key|
        if Input.repeat?(key)
          index = titan_menu_neighbor(index, direction)
          break
        end
      end
      pbPlayCursorSE if old != index
      released = true unless PokemonSurvivor.control_press?(:confirm)
      draw_breach_menu(title, entries, index, footer, @titan_menu_season, :titan)
      return index if released && survivor_confirm_triggered?
      return nil if survivor_cancel_triggered?
    end
  ensure
    @last_time, @accumulator = System.uptime, 0.0
    Input.update
  end

  def titan_leaderboard_menu
    entries = @titan_store.leaderboard
    unless entries
      titan_online_error
      return
    end
    rows = entries.map do |row|
      row.merge(damage_text: row[:damage].to_i.to_s.reverse.scan(/.{1,3}/).join(".").reverse)
    end
    index, first = 0, 0
    Input.update
    released = false
    loop do
      Graphics.update
      Input.update
      released = true unless PokemonSurvivor.control_press?(:confirm)
      break if survivor_cancel_triggered? || (released && survivor_confirm_triggered?)
      old = index
      index -= 1 if Input.repeat?(Input::UP)
      index += 1 if Input.repeat?(Input::DOWN)
      index = [[index, 0].max, [rows.length - 1, 0].max].min
      first = titan_leaderboard_scroll(index, first, rows.length)
      pbPlayCursorSE if index != old
      draw_titan_leaderboard(rows, index, first)
    end
  ensure
    Input.update
    @last_time = System.uptime
    @accumulator = 0.0
  end

  def breach_pokemon_picker_title(hero_name)
    return super unless @titan_pokemon_picker
    _INTL("Titan - {1}", PokemonSurvivor.species_name(hero_name))
  end

  def titan_prepare_run(hero)
    @titan_session = @titan_store.begin_run(PokemonSurvivor.leaderboard_player_name, hero)
    unless @titan_session
      titan_online_error
      return false
    end
    completed = false
    breach_screen_transition { start_game(hero, :titan) }
    passives, moves = [], []
    2.times do |index|
      @titan_build_step = index + 1
      pool = available_move_upgrades.reject { |upgrade| moves.any? { |taken| taken[:skill] == upgrade[:skill] } }
      selected = titan_choose_upgrade(_INTL("Extra skill {1}/2 - Max Upgrades", index + 1), pool, 2 - index)
      return false unless selected
      moves << selected
    end
    4.times do |index|
      @titan_build_step = index + 3
      pool = available_upgrades.reject do |upgrade|
        upgrade[:skill] || upgrade[:target_skill] || upgrade[:tower_fallback] ||
          [:lifesteal, :second_wind, :rare_draft, :chestxp, :floor_momentum, :boss_preparation].include?(upgrade[:id]) ||
          PokemonSurvivor::Titan::WEAKER_PASSIVES.include?(upgrade[:id]) ||
          passives.any? { |taken| taken[:id] == upgrade[:id] }
      end
      selected = titan_choose_upgrade(_INTL("Passive {1}/4 - Max Level", index + 1), pool, 4 - index)
      return false unless selected
      passives << selected
    end
    titan_apply_loadout(passives, moves)
    completed = true
    breach_screen_transition { draw_game }
    true
  ensure
    unless completed
      cancelled_session = @titan_session
      clear_transient_run_state if titan_mode?
      return_to_select_menu if titan_mode?
      @titan_preparing = false
      @titan_build_step = nil
      play_survivor_menu_bgm
      @titan_store.settle(cancelled_session, 0, 0, :abandoned) if cancelled_session
    end
    @titan_draft_cards = nil
    @last_time = System.uptime
    @accumulator = 0.0
  end

  def titan_draft_pool(pool)
    pool.reject { |upgrade| (@banned_upgrade_ids || []).include?(upgrade[:id]) }.uniq { |upgrade| upgrade[:id] }
  end

  def titan_draft_weight(upgrade)
    weight = rarity_weight(upgrade_rarity(upgrade))
    skill = PokemonSurvivor::SKILLS[upgrade[:skill]]
    skill && @hero && (@hero.types || []).include?(skill[:type]) ? weight * 2 : weight
  end

  def weighted_upgrade_pick(pool)
    return super unless titan_mode? && @titan_preparing && pool.any? { |upgrade| upgrade[:skill] }
    weights = pool.map { |upgrade| titan_draft_weight(upgrade) }
    roll = rand(weights.inject(0, :+))
    pool.each_with_index do |upgrade, index|
      roll -= weights[index]
      return upgrade if roll < 0
    end
    pool.last
  end

  def titan_refresh_draft(pool, previous = [])
    fresh = pool.reject { |upgrade| previous.any? { |old| old[:id] == upgrade[:id] } }
    offers = choose_weighted_upgrades(fresh, 3)
    offers.concat(choose_weighted_upgrades(pool.reject { |upgrade| offers.include?(upgrade) }, 3 - offers.length))
    @titan_draft_cards = offers.map do |upgrade|
      upgrade.merge(breach_card: true, category_label: _INTL("Max Level"),
        badge_text: _INTL("Lv.{1}/{1}", upgrade[:max]))
    end
    offers
  end

  def titan_change_draft(action, pool, offers, index, remaining)
    pool = titan_draft_pool(pool)
    if action == :ban
      return nil if @bans_left.to_i <= 0 || pool.length <= remaining
      @banned_upgrade_ids ||= []
      @banned_upgrade_ids << offers[index][:id]
      @bans_left -= 1
      pool = titan_draft_pool(pool)
    else
      return nil if @rerolls_left.to_i <= 0 || pool.all? { |upgrade| offers.include?(upgrade) }
      @rerolls_left -= 1
    end
    pbPlayCursorSE
    PokemonSurvivor.gamepad_vibrate_event(action == :ban ? :upgrade_ban : :upgrade_reroll)
    titan_refresh_draft(pool, offers)
  end

  def titan_choose_upgrade(title, pool, remaining = 1)
    pool = titan_draft_pool(pool)
    if pool.length < remaining
      pbMessage(_INTL("Unlock more skills before preparing this Titan run."))
      return nil
    end
    offers = titan_refresh_draft(pool)
    index, opened, chosen_at = 0, System.uptime, nil
    hold_started, released, sounded = nil, false, false
    Input.update
    loop do
      Graphics.update
      Input.update
      now = System.uptime
      if chosen_at
        if now - chosen_at >= 0.50 && !sounded
          sounded = true
          play_survivor_se(:breach_choice, "Survivor/Mining reveal", 0.25, PokemonSurvivor::SFX_UPGRADE_CONSUME_VOLUME, 118)
          PokemonSurvivor.gamepad_vibrate_event(:upgrade_take)
        end
        return offers[index] if now - chosen_at >= 0.94
      else
        reroll, ban = upgrade_reroll_pressed?, upgrade_ban_pressed?
        released = true unless reroll || ban || PokemonSurvivor.control_press?(:confirm)
        if released
          wanted = reroll ? :reroll : (ban ? :ban : nil)
          wanted = nil if wanted == :reroll && @rerolls_left.to_i <= 0
          wanted = nil if wanted == :ban && @bans_left.to_i <= 0
          if wanted
            hold_started = now if @breach_draft_hold_action != wanted || !hold_started
            @breach_draft_hold_action = wanted
            @breach_draft_hold_progress = [(now - hold_started) / Scene_PokemonSurvivor::UPGRADE_HOLD_SECONDS, 1.0].min
            if @breach_draft_hold_progress >= 1.0
              changed = titan_change_draft(wanted, pool, offers, index, remaining)
              changed ? offers = changed : pbPlayBuzzerSE
              index, opened, released, hold_started = 0, System.uptime, false, nil
              @breach_draft_hold_action, @breach_draft_hold_progress = nil, 0.0
            end
          else
            hold_started, @breach_draft_hold_action, @breach_draft_hold_progress = nil, nil, 0.0
            old = index
            index = (index - 1) % offers.length if Input.repeat?(Input::LEFT)
            index = (index + 1) % offers.length if Input.repeat?(Input::RIGHT)
            pbPlayCursorSE if old != index
            if survivor_confirm_triggered? && now - opened >= 0.24
              chosen_at = now
              pbPlayDecisionSE
            end
          end
        end
      end
      draw_breach_choice_cards(title, @titan_draft_cards, index, opened, chosen_at, false, :titan)
    end
  ensure
    @titan_draft_cards = nil
    @breach_draft_hold_action, @breach_draft_hold_progress = nil, 0.0
    dispose_breach_choice_surface
    @last_time, @accumulator = System.uptime, 0.0
    Input.update
  end

  def draw_breach_choice_cards(title, cards, index, *args)
    super(title, @titan_draft_cards || cards, index, *args)
  end

  def titan_training_description(id)
    node = PokemonSurvivor::Titan::TRAINING.find { |entry| entry[:id] == id }
    node ? _INTL(node[:desc]) : ""
  end

  def titan_shop_name(id)
    item = PokemonSurvivor::Titan.season_shop(@titan_store.season_id)[id]
    if item && item[:catchup]
      return PokemonSurvivor.species_name(item[:reward]) if item[:kind] == :pokemon
      equipment = PokemonSurvivor.equipment_data(item[:reward])
      return equipment ? _INTL(equipment[:name]) : item[:reward].to_s
    end
    case id
    when :fragments then _INTL("Fragments")
    when :candies, :ore_candies then _INTL("Candies")
    when :pokemon then PokemonSurvivor.species_name(PokemonSurvivor::Titan.season(@titan_store.season_id)[:reward_pokemon])
    when :equipment then _INTL("Mewtwonite Y")
    when :prestige then _INTL("Prestige Crystal")
    end
  end

  def titan_tree_menu(kind)
    # Keep Kecleon's camera, selection and cached tree intact across this modal.
    saved = {}
    instance_variables.grep(/^@shop_/).each { |key| saved[key] = instance_variable_get(key) }
    saved.each_key { |key| remove_instance_variable(key) }
    @titan_tree_kind = kind
    titan_build_tree
    @shop_index, @shop_show_details, @shop_bg_frame = 0, true, 0
    @shop_last_time = System.uptime
    center_shop_on_selected
    released = false
    Input.update
    loop do
      Graphics.update
      Input.update
      break if survivor_cancel_triggered?
      old = @shop_index
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
      elsif shop_details_triggered?
        @shop_show_details = !@shop_show_details
        invalidate_shop_static_cache
      end
      if old != @shop_index
        center_shop_on_selected
        pbPlayCursorSE
      end
      released = true unless PokemonSurvivor.control_press?(:confirm)
      if released && survivor_confirm_triggered?
        success = titan_buy_tree_node(selected_shop_node)
        if success
          @titan_tree_snapshot = @titan_store.snapshot
          invalidate_shop_state_cache
          pbSEPlay("Survivor/Mart buy item", PokemonSurvivor::UI_DECISION_VOLUME, 100)
          breach_save_menu_progress
        else
          pbPlayBuzzerSE
        end
        released = false
      end
      update_shop_background_animation
      draw_shop
    end
  ensure
    if saved
      # Only dispose the modal's surfaces, never Kecleon's saved bitmap cache.
      instance_variables.grep(/^@shop_/).each do |key|
        value = instance_variable_get(key)
        values = value.is_a?(Hash) ? value.values : [value]
        values.each { |entry| entry.dispose if entry.is_a?(Bitmap) && !entry.disposed? }
        remove_instance_variable(key)
      end
      saved.each { |key, value| instance_variable_set(key, value) }
    end
    @titan_tree_kind = @titan_tree_snapshot = @titan_tree_nodes = @titan_tree_links = nil
    @last_time = System.uptime
    @accumulator = 0.0
    Input.update
  end

  def titan_menu_surface(title)
    bitmap, overlay = @sprites["screen"].bitmap, @sprites["overlay"].bitmap
    overlay.clear
    draw_select_background(bitmap)
    pbSetSystemFont(bitmap)
    draw_panel(bitmap, 18, 14, Graphics.width - 36, Graphics.height - 58, Color.new(154, 146, 240), Color.new(18, 24, 34))
    draw_battle_pass_scrolling_text(bitmap, title, 34, 28, Graphics.width - 68, 24, Color.white, Color.new(32, 32, 40), 2)
    titan_currency_strip(bitmap, @titan_store.snapshot)
    bitmap
  end

  def titan_tree_title
    @titan_tree_kind == :training ? _INTL("Special Kecleon Shop") : _INTL("Crystal Shop")
  end

  def titan_build_tree
    @titan_tree_snapshot = @titan_store.snapshot
    @titan_tree_nodes = [{ id: :titan_core, root: true, x: 0, y: 0,
      icon: @titan_tree_kind == :training ? "Ore" : "Crystal Shard" }]
    @titan_tree_links = []
    if @titan_tree_kind == :training
      catalog = PokemonSurvivor::Titan::TRAINING.each_with_object({}) { |data, result| result[data[:id]] = data }
      Scene_PokemonSurvivor::SHOP_TREE_LAYOUT.each do |id, level, x, y|
        data = catalog[id]
        next unless data && level <= data[:costs].length
        # Steady Burst fills the space left by Titan's absent Fragment branch.
        x, y = level, 0 if id == :steady_burst && !catalog[:coin_gain]
        @titan_tree_nodes << { id: shop_node_id(id, level), upgrade: data,
          level: level, x: x, y: y, icon: data[:icon] }
      end
      @titan_tree_links = PokemonSurvivor::Titan.training_links.dup
      @titan_tree_nodes << { id: :ore_candies, upgrade: PokemonSurvivor::Titan::ORE_CANDIES,
        level: 1, x: 0, y: -1, icon: "Candy" }
      @titan_tree_links << [:titan_core, :ore_candies]
    else
      season = PokemonSurvivor::Titan.season(@titan_store.season_id)
      reward_pokemon = season[:reward_pokemon].to_s
      has_equipment = !!season[:reward_item]
      positions = { fragments: [0, 1, "Fragment"], candies: [0, -1, "Candy"],
        pokemon: [1, 0, reward_pokemon], equipment: [2, 0, season[:reward_item].to_s.upcase],
        prestige: [has_equipment ? 3 : 2, 0, "Prestige"] }
      PokemonSurvivor::Titan.season_shop(@titan_store.season_id).each do |id, item|
        if item[:catchup]
          past = PokemonSurvivor::Titan::SEASONS.keys.sort.select { |s| s < @titan_store.season_id }
          column = -(past.index(item[:season]) + 1)
          equipment = item[:kind] == :equipment
          @titan_tree_nodes << { id: id, upgrade: item.merge(id: id), level: 1,
            x: column, y: equipment ? 1 : 0, icon: item[:reward].to_s.upcase }
          parent = if equipment
                     "catchup_#{item[:season]}_pokemon".to_sym
                   elsif column == -1
                     :titan_core
                   else
                     "catchup_#{past[-column - 2]}_pokemon".to_sym
                   end
          @titan_tree_links << [parent, id]
          next
        end
        x, y, icon = positions.fetch(id)
        @titan_tree_nodes << { id: id, upgrade: item.merge(id: id), level: 1, x: x, y: y, icon: icon }
        parent = { equipment: :pokemon, prestige: has_equipment ? :equipment : :pokemon }.fetch(id, :titan_core)
        @titan_tree_links << [parent, id]
      end
    end
  end

  def shop_all_nodes
    @titan_tree_kind ? @titan_tree_nodes : super
  end

  def shop_root_node
    @titan_tree_kind ? @titan_tree_nodes.first : super
  end

  def shop_slot_frame_name(node)
    return "SlotUpLeftRight" if @titan_tree_kind == :training && node[:root]
    return "SlotUpRightDown" if @titan_tree_kind == :shop && node[:root]
    super
  end

  def shop_tree_links
    @titan_tree_kind ? @titan_tree_links : super
  end

  def shop_node_at(x, y)
    return super unless @titan_tree_kind
    @titan_tree_nodes.find { |node| node[:x] == x && node[:y] == y }
  end

  def shop_connected_nodes?(a, b)
    return super unless @titan_tree_kind
    a && b && (@titan_tree_links.include?([a[:id], b[:id]]) || @titan_tree_links.include?([b[:id], a[:id]]))
  end

  def shop_node_state(node)
    return super unless @titan_tree_kind
    return :bought if node[:root]
    data = node[:upgrade]
    if data[:id] == :ore_candies
      return PokemonSurvivor::Titan.training_complete?(@titan_tree_snapshot[:training]) ? :available : :locked
    end
    if @titan_tree_kind == :training
      rank = @titan_tree_snapshot[:training][data[:id]].to_i
      return :bought if rank >= node[:level]
      available = rank + 1 == node[:level] &&
        PokemonSurvivor::Titan.training_purchase_available?(@titan_tree_snapshot[:training], data[:id], @titan_tree_links)
      return available ? :available : :locked
    end
    view = @titan_tree_snapshot
    if data[:catchup]
      owned = data[:kind] == :pokemon ? PokemonSurvivor.hero_unlocked?(data[:reward]) :
        PokemonSurvivor.equipment_unlocked?(data[:reward])
      return :bought if owned
    end
    return :bought if !data[:repeatable] && view[:purchases][data[:id]].to_i >= data[:limit]
    return :locked unless PokemonSurvivor::Titan.shop_requirements_met?(data, view)
    :available
  end

  def shop_node_affordable?(node)
    return super unless @titan_tree_kind
    return false if node[:root] || shop_node_state(node) != :available
    data = node[:upgrade]
    return @titan_tree_snapshot[:ores].to_i >= data[:cost] if data[:id] == :ore_candies
    @titan_tree_kind == :training ? @titan_tree_snapshot[:ores] >= data[:costs][node[:level] - 1] :
      @titan_tree_snapshot[data[:currency] || :crystals].to_i >= data[:cost]
  end

  def titan_buy_tree_node(node)
    return false unless node && shop_node_affordable?(node)
    id = node[:upgrade][:id]
    quantity = 1
    if @titan_tree_kind == :training && id == :ore_candies
      quantity = choose_candy_exchange_quantity(@titan_store.snapshot[:ores],
        node[:upgrade][:cost], node[:upgrade][:quantity], _INTL("Ores"))
      return false if quantity <= 0
    elsif @titan_tree_kind == :shop && [:candies, :fragments].include?(id)
      data = node[:upgrade]
      snapshot = @titan_store.snapshot
      quantity = choose_candy_exchange_quantity(snapshot[:crystals], data[:cost], data[:quantity],
        _INTL("Crystal Shards"), limit: data[:limit] - snapshot[:purchases][id].to_i,
        payment_icon: "Crystal Shard", reward_icon: id == :fragments ? "ICON_FRAGMENT" : "ICON_CANDY",
        reward_name: titan_shop_name(id))
      return false if quantity <= 0
    end
    success = if @titan_tree_kind == :training && id != :ore_candies
      @titan_store.buy_training(id)
    elsif id == :ore_candies
      @titan_store.buy(id, quantity)
    else
      @titan_store.buy(id, quantity)
    end
    titan_online_error if !success && @titan_store.last_error
    if success && (id == :ore_candies || (@titan_tree_kind == :shop && [:candies, :fragments].include?(id)))
      icon = id == :fragments ? "ICON_FRAGMENT" : "ICON_CANDY"
      enqueue_shop_resource_popup(icon, node[:upgrade][:quantity] * quantity)
    end
    success
  end

  def draw_shop_header(bitmap)
    return super unless @titan_tree_kind
    style = Scene_PokemonSurvivor
    cy = 12 + (style::SHOP_HEADER_H - 20) / 2
    ore_payment = @titan_tree_kind == :training || (selected_shop_node || {}).dig(:upgrade, :currency) == :ores
    icon = ore_payment ? "Ore" : "Crystal Shard"
    shop_icon = @titan_tree_kind == :training ? "ICON_SHOP_SEASONS" : "ICON_SHOP"
    draw_mode_button_icon(bitmap, shop_icon, 38, cy, 1.0)
    balance = @titan_tree_snapshot[ore_payment ? :ores : :crystals]
    source = cached_bitmap(PokemonSurvivor::SHOP_DIR, icon)
    icon_w = source && !source.disposed? ? (source.width * 0.7).round : 0
    gap = icon_w > 0 ? 4 : 0
    max_text_w = [Graphics.width - 14 - 180 - icon_w - gap, 1].max
    line = cached_shop_scrolling_text_bitmap(balance.to_s, 1, 26, style::SHOP_BLUE, style::SHOP_SHADOW_COLOR)
    content_w = [bitmap.text_size(balance.to_s).width.to_i + 2, 1].max
    text_w = [content_w, max_text_w].min
    text_x = Graphics.width - 14 - text_w
    title_w = [Graphics.width - 270, text_x - gap - icon_w - 12 - 72].min
    draw_shop_scrolling_text(bitmap, titan_tree_title, 72, cy - 13, [title_w, 1].max, 26,
      style::SHOP_GOLD, style::SHOP_SHADOW_COLOR)
    draw_shop_upgrade_icon(bitmap, icon, text_x - gap - (icon_w - icon_w / 2), cy, 0.7, nil, :bought, false)
    if line && !line.disposed?
      source_rect = Rect.new(0, 0, content_w, 26)
      if content_w <= max_text_w
        bitmap.blt(text_x, cy - 13, line, source_rect)
      else
        # Only exceptionally long balances shrink; the complete amount stays fixed.
        text_h = [(26.0 * text_w / content_w).round, 1].max
        bitmap.stretch_blt(Rect.new(text_x, cy - text_h / 2, text_w, text_h), line, source_rect)
      end
    end
  end

  def shop_info_h
    return super unless @titan_tree_kind
    @shop_show_details == false ? 0 : Scene_PokemonSurvivor::SHOP_INFO_H + 24
  end

  def draw_titan_tree_description(bitmap, text, x, y, w, h)
    lines = shop_wrapped_lines(bitmap, text, w)
    line_h = 24
    padding = 4
    total_h = [lines.length * line_h + padding * 2, h].max
    @shop_description_cache ||= {}
    key = [:titan, lines, w, total_h, line_h, padding]
    block = @shop_description_cache[key]
    if !block || block.disposed?
      block = Bitmap.new(w, total_h)
      pbSetSystemFont(block)
      style = Scene_PokemonSurvivor
      lines.each_with_index do |line, i|
        pbDrawTextPositions(block, [[line, 0, padding + i * line_h, false,
          style::SHOP_DIM_COLOR, style::SHOP_SHADOW_COLOR]])
      end
      if @shop_description_cache.length >= 64
        old = @shop_description_cache.delete(@shop_description_cache.keys.first)
        old.dispose if old && !old.disposed?
      end
      @shop_description_cache[key] = block
    end
    offset = shop_scroll_offset(total_h - h, 6, 75)
    bitmap.blt(x, y, block, Rect.new(0, offset, w, h))
  end

  def draw_shop_info(bitmap)
    return super unless @titan_tree_kind
    return if @shop_show_details == false
    style = Scene_PokemonSurvivor
    node = selected_shop_node
    y = Graphics.height - style::SHOP_FOOTER_H - shop_info_h + 8
    title, desc, cost_text = titan_tree_details(node)
    draw_shop_scrolling_text(bitmap, title, 22, y, Graphics.width - 44, 22, style::SHOP_GOLD, style::SHOP_SHADOW_COLOR)
    draw_titan_tree_description(bitmap, desc, 22, y + 29, Graphics.width - 44, 56)
    color = shop_node_state(node) == :bought ? style::SHOP_GREEN :
      (shop_node_affordable?(node) ? style::SHOP_GOLD : style::SHOP_RED)
    draw_shop_scrolling_text(bitmap, cost_text, 22, y + 90, Graphics.width - 44, 26, color, style::SHOP_SHADOW_COLOR)
  end

  def titan_tree_details(node)
    return [titan_tree_title, _INTL("Upgrades and purchases for this Titan season only."), _INTL("Season {1}", @titan_store.season_id)] if node[:root]
    data, view = node[:upgrade], @titan_tree_snapshot
    id = data[:id]
    if data[:catchup]
      desc = data[:kind] == :pokemon ? _INTL("Unlock a Pokemon from Season {1}.", data[:season]) :
        _INTL("Equipment from Season {1}. Requires {2}.", data[:season], PokemonSurvivor.species_name(data[:pokemon]))
      return [titan_shop_name(id), desc, _INTL("Cost: {1} Crystal Shards", data[:cost])]
    end
    if id == :ore_candies
      status = shop_node_state(node) == :locked ? _INTL("Locked") : _INTL("Available")
      return [titan_shop_name(id),
        _INTL("Exchange {1} Ores for {2} Candies. Repeatable after completing all Titan training upgrades.", data[:cost], data[:quantity]),
        _INTL("{1} - Cost: {2} Ores", status, data[:cost])]
    end
    if @titan_tree_kind == :training
      title = _INTL("{1} {2}", PokemonSurvivor::Titan.training_name(id), node[:level])
      status = shop_node_state(node) == :bought ? _INTL("Unlocked") :
        (shop_node_state(node) == :locked ? _INTL("Unlock the previous rank and a connected upgrade first.") : _INTL("Available"))
      return [title, titan_training_description(id), _INTL("{1} - Cost: {2} Ores", status, data[:costs][node[:level] - 1])]
    end
    title = _INTL("{1} - {2}/{3}", titan_shop_name(id), view[:purchases][id].to_i, data[:limit])
    desc = case id
           when :pokemon then _INTL("Unlock {1} once the Titan has lost 50% of its total HP.", titan_shop_name(:pokemon))
           when :equipment then _INTL("Requires {1} and 75% of the Titan's total HP lost.", titan_shop_name(:pokemon))
           when :prestige then _INTL("A cosmetic for {1}. Requires this Pokemon and the Titan's defeat. No combat bonus.", titan_shop_name(:pokemon))
           else _INTL("Gain {1} {2}.", data[:quantity], titan_shop_name(id))
           end
    cost = shop_node_state(node) == :bought ? _INTL("Complete") : _INTL("Cost: {1} Crystal Shards", data[:cost])
    [title, desc, cost]
  end

  def shop_buy_help_label
    return super unless @titan_tree_kind
    node = selected_shop_node
    return _INTL("Core") if node[:root]
    return _INTL("Bought") if shop_node_state(node) == :bought
    shop_node_affordable?(node) ? _INTL("Buy") : _INTL("Locked")
  end

  def draw_shop_talent_icon_only(bitmap, node, clip)
    if @titan_tree_kind && [:fragments, :candies, :ore_candies].include?(node[:id]) && @titan_store.repeat_purchase_claimed?(node[:id])
      cx, cy = shop_screen_pos(node)
      scale = shop_node_affordable?(node) ? shop_breath_scale : 1.0
      return draw_shop_upgrade_icon(bitmap, node[:icon], cx, cy, scale, clip, :bought, false)
    end
    kind = node[:upgrade] && node[:upgrade][:catchup] ? node[:upgrade][:kind] : node[:id]
    return super unless @titan_tree_kind == :shop && [:pokemon, :equipment].include?(kind)
    cx, cy = shop_screen_pos(node)
    icon = if kind == :pokemon
             cached_leaderboard_pokemon_icon(node[:icon])
           else
             cached_bitmap(PokemonSurvivor::EQUIPMENT_DIR, node[:icon])
           end
    return unless icon && !icon.disposed?
    iw, ih = icon.width, icon.height
    scale = shop_node_affordable?(node) ? shop_breath_scale : 1.0
    w, h = (iw * scale).round, (ih * scale).round
    rects = shop_clipped_rect(cx - w / 2, cy - h / 2, w, h, clip)
    return unless rects
    dest, source = rects
    source = Rect.new(source.x * iw / w, source.y * ih / h, source.width * iw / w, source.height * ih / h)
    bitmap.stretch_blt(dest, icon, source, shop_node_state(node) == :locked ? 110 : 255)
  end

  def titan_menu_footer(bitmap, title, desc)
    y = Graphics.height - 119
    draw_soft_badge(bitmap, 28, y, Graphics.width - 56, 66, Color.new(0, 0, 0, 190))
    draw_battle_pass_scrolling_text(bitmap, title, 38, y + 5, Graphics.width - 76, 24, Color.new(255, 228, 140))
    draw_battle_pass_scrolling_text(bitmap, desc, 38, y + 33, Graphics.width - 76, 24, Color.white)
    overlay = @sprites["overlay"].bitmap
    draw_help(overlay, [[:left, ""], [:right, _INTL("Select")], [:confirm, _INTL("Confirm")], [:cancel, _INTL("Back")]])
    draw_tv_filter(overlay)
  end

  def titan_milestones_menu
    index, released = 0, false
    entries = PokemonSurvivor::Titan::MILESTONES
    surface = Bitmap.new(Graphics.width, 208)
    scroll = 0.0
    data = @titan_store.snapshot
    Input.update
    loop do
      Graphics.update
      Input.update
      break if survivor_cancel_triggered?
      old = index
      index = (index - 1) % entries.length if Input.repeat?(Input::LEFT)
      index = (index + 1) % entries.length if Input.repeat?(Input::RIGHT)
      pbPlayCursorSE if old != index
      released = true unless PokemonSurvivor.control_press?(:confirm)
      auto = battle_pass_auto_claim_triggered?
      if auto || (released && survivor_confirm_triggered?)
        changed = auto ? @titan_store.claim_all : @titan_store.claim(index)
        if changed
          pbPlayDecisionSE
          breach_save_menu_progress
          data = @titan_store.snapshot
        else
          pbPlayBuzzerSE
        end
        released = false
      end
      target = titan_milestone_scroll_target(index, surface.width, entries.length)
      scroll += (target - scroll) * 0.24
      draw_titan_milestones(data, index, surface, scroll)
    end
  ensure
    surface.dispose if surface && !surface.disposed?
    @last_time = System.uptime
    @accumulator = 0.0
    Input.update
  end
end

[SurvivorTitanRun, SurvivorTitanRendering, SurvivorTitanMenus].each do |extension|
  Scene_PokemonSurvivor.prepend(extension) unless Scene_PokemonSurvivor.ancestors.include?(extension)
end
