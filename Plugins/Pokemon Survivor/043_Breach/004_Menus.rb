module SurvivorBreachMenus
  CHOICE_COLORS = {
    training: [86, 190, 255], skills: [192, 142, 255], modules: [255, 172, 78],
    healing: [98, 222, 154], treasure: [255, 220, 92], boss: [255, 102, 118],
    skirmish: [110, 200, 245], observatory: [100, 220, 190],
    foundry: [245, 155, 100], trial: [225, 135, 180],
    power: [255, 112, 100], tempo: [88, 216, 224], guard: [100, 164, 255],
    stride: [174, 220, 92], magnet: [240, 144, 210], burst: [255, 206, 76],
    reach: [158, 148, 244], recovery: [96, 222, 158]
  }.freeze

  def pbStartScene
    super
    PokemonSurvivor.request_titan_notification_refresh if breach_season_slot_unlocked?
    # Keep the ordinary selection menu responsive even with no connection.
    @breach_refresh_worker = Thread.new do
      begin
        season = PokemonSurvivor.breach_refresh_season
        PokemonSurvivor.breach_fetch_quests(season) if season
      rescue StandardError
        nil
      end
    end
  end

  def refresh_breach_slot
    return if @breach_pokemon_picker_active
    return unless @heroes
    available = breach_season_slot_unlocked?
    index = @heroes.index(PokemonSurvivor::BREACH_SLOT_KEY)
    target = [4, @heroes.length - (index.nil? ? 0 : 1)].min
    return if (!available && index.nil?) || (available && index == target)
    current = selected_hero_name
    @heroes.delete(PokemonSurvivor::BREACH_SLOT_KEY)
    if available
      @heroes.insert(target, PokemonSurvivor::BREACH_SLOT_KEY)
    end
    @hero_index = @heroes.index(current) || [@hero_index.to_i, @heroes.length - 1].min
  end

  def breach_season_slot_unlocked?
    progress = PokemonSurvivor.survivor_progress
    return true if progress[:breach_unlocked] == true
    completed = PokemonSurvivor.progress_species_list(progress, :unlocked) & PokemonSurvivor::BASE_HERO_KEYS
    [:survived_15, :boss_finished, :evolution_finished, :level_finished,
     :rush_finished, :tower_finished].each do |badge|
      completed &= PokemonSurvivor.progress_species_list(progress, badge)
      return false if completed.empty?
    end
    progress[:breach_unlocked] = true
  end

  def refresh_battle_pass_slot
    return if @breach_pokemon_picker_active
    super
    refresh_breach_slot
  end

  def breach_initial_check_pending?
    !!((@breach_refresh_worker && @breach_refresh_worker.alive?) ||
      PokemonSurvivor.titan_notification_refresh_pending?)
  end

  def update_select
    if !@breach_pokemon_picker_active && @breach_refresh_worker && !@breach_refresh_worker.alive?
      @breach_refresh_worker = nil
      refresh_breach_slot
    end
    if selected_hero_name == PokemonSurvivor::BREACH_SLOT_KEY && @select_focus != :shop
      @confirming_hero = false
      if survivor_confirm_triggered? || select_action_triggered?
        return if breach_initial_check_pending?
        breach_open_season
        return
      end
    end
    super
    @confirming_hero = false if selected_hero_name == PokemonSurvivor::BREACH_SLOT_KEY
  end

  def draw_breach_select_slot(bitmap, x, y, w, h, selected)
    pending = breach_initial_check_pending?
    edge = pending ? Color.new(96, 104, 116) : (selected ? rainbow_color(System.uptime * 90.0) : Color.new(82, 154, 226))
    draw_pixel_round_rect(bitmap, x, y, w, h, edge)
    draw_pixel_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, Color.new(24, 34, 49))
    icon = cached_icon_bitmap("ICON_SEASON")
    return unless icon && !icon.disposed?
    phase = System.uptime * 10.0
    ox = (Math.sin(phase) * 1.5).round
    oy = (Math.cos(phase * 0.75) * 1.0).round
    bitmap.blt(x + (w - icon.width) / 2 + ox, y + (h - icon.height) / 2 + oy,
               icon, Rect.new(0, 0, icon.width, icon.height), pending ? 112 : 255)
    draw_menu_notification(bitmap, x, y) if !pending && (breach_notification? || titan_notification?)
  end

  def breach_wait(message)
    worker = Thread.new do
      begin
        yield
      rescue StandardError
        nil
      end
    end
    until !worker.alive?
      Graphics.update
      Input.update
      draw_breach_menu(_INTL("Breach"), [], 0, message)
    end
    worker.value
  ensure
    @last_time = System.uptime
    @accumulator = 0.0
  end

  def breach_choose(title, entries, footer = "", allow_cancel = true, season = nil)
    index = 0
    Input.update
    loop do
      Graphics.update
      Input.update
      index = (index - 1) % entries.length if !entries.empty? && Input.repeat?(Input::UP)
      index = (index + 1) % entries.length if !entries.empty? && Input.repeat?(Input::DOWN)
      draw_breach_menu(title, entries, index, footer.respond_to?(:call) ? footer.call : footer, season)
      return index if !entries.empty? && survivor_confirm_triggered?
      return nil if allow_cancel && survivor_cancel_triggered?
    end
  ensure
    @last_time = System.uptime
    @accumulator = 0.0
    Input.update
  end

  def breach_screen_transition
    viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    viewport.z = 999999
    cover = Sprite.new(viewport)
    cover.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    cover.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0))
    cover.opacity = 0
    breach_fade_cover(cover, 0, 255)
    result = yield
    breach_fade_cover(cover, 255, 0)
    result
  ensure
    cover.bitmap.dispose if cover && cover.bitmap && !cover.bitmap.disposed?
    cover.dispose if cover && !cover.disposed?
    viewport.dispose if viewport && !viewport.disposed?
    Input.update
    @last_time = System.uptime
    @accumulator = 0.0
  end

  def breach_fade_cover(cover, from, to)
    started = System.uptime
    loop do
      progress = [[(System.uptime - started) / 0.18, 0.0].max, 1.0].min
      cover.opacity = (from + (to - from) * progress).round
      Graphics.update
      Input.update
      break if progress >= 1.0
    end
  end

  def draw_breach_menu(title, entries, index, footer = "", season = nil, layout = nil)
    bitmap = @sprites["screen"].bitmap
    overlay = @sprites["overlay"].bitmap
    bitmap.clear
    overlay.clear
    pbSetSystemFont(bitmap)
    if breach_mode? && @tower_fade_alpha.to_i >= 255
      bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0))
    else
      draw_select_background(bitmap)
    end
    x = 18
    width = Graphics.width - 36
    draw_panel(bitmap, x, 18, width, 42, Color.new(94, 226, 200), Color.new(18, 35, 40))
    if season
      icon = cached_icon_bitmap("ICON_SEASON")
      icon_w = icon && !icon.disposed? ? [icon.width, 30].min : 0
      title_w = [bitmap.text_size(title).width + 8, width - 32 - icon_w * 2].min
      title_x = x + (width - title_w) / 2
      if icon_w > 0
        zoom = [30.0 / icon.width, 30.0 / icon.height, 1.0].min
        PokemonSurvivor.draw_bitmap_centered(bitmap, icon, title_x - 8 - icon_w / 2, 39, zoom)
        PokemonSurvivor.draw_bitmap_centered(bitmap, icon, title_x + title_w + 8 + icon_w / 2, 39, zoom)
      end
      draw_battle_pass_scrolling_text(bitmap, title, title_x, 28, title_w, 24, Color.white, Color.new(30, 30, 40), 2)
    else
      draw_shop_scrolling_text(bitmap, title, x + 10, 28, width - 20, 24, Color.white, Color.new(30, 30, 40))
    end
    top = 68
    row_step = (season || layout == :titan) ? [44, (Graphics.height - 103 - top - 36) / 4].min : 48
    visible = season ? 4 : [[(Graphics.height - 180) / 48, 1].max, 5].min
    first = [[index - visible + 1, 0].max, [entries.length - visible, 0].max].min
    if layout == :titan
      [[0], [1, 2], [3, 4], [5]].each_with_index do |indices, row_index|
        button_w = (width - 24 - (indices.length - 1) * 10) / indices.length
        indices.each_with_index do |entry_index, column|
          row = entries[entry_index]
          next unless row
          bx, by = x + 8 + column * (button_w + 10), top + row_index * row_step
          draw_titan_menu_button(bitmap, bx, by, button_w, row_step - 6, entry_index == index, entry_index)
          draw_shop_scrolling_text(bitmap, row[0], bx + 10, by + (row_step - 30) / 2, button_w - 20, 24,
            Color.white, Color.new(30, 30, 40))
          draw_menu_notification(bitmap, bx, by) if entry_index == 3 && titan_notification?
        end
      end
    else
      visible.times do |offset|
        row = entries[first + offset]
        next unless row
        draw_select_menu_button(bitmap, x + 8, top + offset * row_step, width - 24, row_step - 6,
                                "", first + offset == index, offset)
        draw_shop_scrolling_text(bitmap, row[0], x + 18, top + offset * row_step + (row_step - 30) / 2, width - 44, 24,
                                 Color.white, Color.new(30, 30, 40))
        notify = season && first + offset == 1 && breach_notification?(season)
        if @season_notification_chooser && !season && entries.length >= 3
          notify ||= first + offset == 0 && breach_notification?
          notify ||= first + offset == 1 && titan_notification?
        end
        draw_menu_notification(bitmap, x + 8, top + offset * row_step) if notify
      end
      if entries.length > visible
        draw_leaderboard_scrollbar(bitmap, Graphics.width - 28, top, 6, visible * row_step - 6, first, visible, entries.length)
      end
    end
    if season || layout == :titan
      row_count = layout == :titan ? 4 : [entries.length, visible].min
      countdown_y = top + row_count * row_step + 2
      draw_breach_season_countdown(bitmap, season, x, countdown_y, width)
    end
    description = entries[index] ? entries[index][1].to_s : ""
    description = [footer.to_s, description].reject { |text| text.empty? }.join("\n")
    y = Graphics.height - 103
    draw_panel(bitmap, x, y, width, 62, Color.new(94, 226, 200), Color.new(18, 35, 40))
    draw_scrolling_wrapped_text(bitmap, description, x + 10, y + 11,
      width - 20, 46, 24, Color.white, Color.new(40, 40, 48), nil, 5.0)
    help = [[:up, ""], [:down, _INTL("Select")], [:confirm, _INTL("Confirm")], [:cancel, _INTL("Back")]]
    help = [[:up, ""], [:down, ""], [:left, ""], [:right, _INTL("Select")], [:confirm, _INTL("Confirm")], [:cancel, _INTL("Back")]] if layout == :titan
    draw_help(overlay, help)
    draw_tv_filter(overlay)
  end

  def breach_season_time_text(season)
    seconds = [PokemonSurvivor.breach_seconds_left(season), 0].max
    days, remainder = seconds.divmod(86400)
    minutes, seconds = remainder.divmod(60)
    _INTL("{1}d {2}m {3}s", days, minutes, sprintf("%02d", seconds))
  end

  def draw_breach_season_countdown(bitmap, season, x, y, width)
    seconds = [PokemonSurvivor.breach_seconds_left(season), 0].max
    reference = 1.0
    if season
      progress = PokemonSurvivor.breach_progress(season[:id])
      reference = [progress[:countdown_reference].to_f, season[:remaining].to_f, 1.0].max
      progress[:countdown_reference] = reference
    end
    text = season ? breach_season_time_text(season) : _INTL("Season time unavailable")
    pbSetSystemFont(bitmap)
    panel_width = width - 32
    panel_x = x + (width - panel_width) / 2
    @bitmaps ||= {}
    bar = @bitmaps["breach_countdown_bar"]
    if !bar || bar.disposed? || bar.width != panel_width
      bar.dispose if bar && !bar.disposed?
      bar = Bitmap.new(panel_width, 30)
      @bitmaps["breach_countdown_bar"] = bar
    end
    bar.clear
    draw_status_bar(bar, 0, 0, panel_width, 30, seconds / reference,
      rainbow_color(System.uptime * 45.0), false, false)
    # Remove the shared HUD border and round the remaining gauge surface.
    bar.clear_rect(0, 0, panel_width, 2)
    bar.clear_rect(0, 28, panel_width, 2)
    bar.clear_rect(0, 0, 2, 30)
    bar.clear_rect(panel_width - 2, 0, 2, 30)
    [8, 5, 3, 2, 1, 1].each_with_index do |inset, row|
      bar.clear_rect(2, row + 2, inset, 1)
      bar.clear_rect(panel_width - 2 - inset, row + 2, inset, 1)
      bar.clear_rect(2, 27 - row, inset, 1)
      bar.clear_rect(panel_width - 2 - inset, 27 - row, inset, 1)
    end
    bitmap.blt(panel_x, y, bar, Rect.new(0, 0, panel_width, 30))
    draw_battle_pass_scrolling_text(bitmap, text, panel_x + 12, y + 5, panel_width - 24, 24,
      Color.white, Color.new(15, 25, 45), 2)
  end

  def breach_open_season
    breach_open_current_season
  end

  def breach_open_current_season
    previous_menu_bgm = @survivor_menu_bgm
    @survivor_menu_bgm = "Survivor/Breach"
    play_survivor_menu_bgm
    season = breach_wait(_INTL("Checking the season...")) { PokemonSurvivor.breach_refresh_season }
    unless season
      pbMessage(_INTL("No season is currently open or available. Check your connection and try again later."))
      return
    end
    quests = breach_wait(_INTL("Loading quests...")) { PokemonSurvivor.breach_fetch_quests(season) }
    unless quests
      pbMessage(_INTL("Season rewards could not be loaded. Please try again."))
      return
    end
    menu_opened = true
    breach_save_menu_progress
    # Freeze this menu's season: claiming remains possible until it is closed.
    loop do
      footer = ""
      choice = breach_choose(_INTL("Breach - Season {1}", season[:id]), [
        [_INTL("Start a run"), _INTL("Training and equipment active. Kecleon upgrades inactive.")],
        [_INTL("Season rewards"), _INTL("Claim Candies and Fragments.")],
        [_INTL("Leaderboard"), _INTL("View the current season's leaderboard.")],
        [_INTL("Cancel"), _INTL("Return to classic modes.")]
      ], footer, true, season)
      break if choice.nil? || choice == 3
      if choice == 1
        breach_rewards_menu(season, quests)
      elsif choice == 2
        breach_open_leaderboard
      else
        hero = breach_choose_pokemon
        next if hero.nil?
        next unless seasonal_run_version_allowed?
        token = nil
        breach_screen_transition do
          token = breach_wait(_INTL("Checking access...")) do
            PokemonSurvivor.breach_online_action(action: "start", season_id: season[:id],
              pokemon: hero.to_s.upcase, player_name: PokemonSurvivor.leaderboard_player_name)
          end
          if token.to_s.match?(/\ASTART:[0-9a-f-]{36}\z/i)
            @breach_season = season.dup
            @breach_session = token.split(":", 2)[1]
            @breach_quests = quests
            start_game(hero, :breach)
            draw_game
          else
            draw_breach_menu(_INTL("Breach - Season {1}", season[:id]), [
              [_INTL("Start a run"), _INTL("Training and equipment active. Kecleon upgrades inactive.")],
              [_INTL("Season rewards"), _INTL("Claim Candies and Fragments.")],
              [_INTL("Leaderboard"), _INTL("View the current season's leaderboard.")],
              [_INTL("Cancel"), _INTL("Return to classic modes.")]
            ], 0, footer, season)
          end
        end
        unless token.to_s.match?(/\ASTART:[0-9a-f-]{36}\z/i)
          pbMessage(_INTL("Unable to start. Check your connection and the active season."))
          next
        end
        return
      end
    end
  ensure
    breach_save_menu_progress if menu_opened
    @survivor_menu_bgm = previous_menu_bgm
    play_survivor_menu_bgm unless @state == :play
    if @state == :select
      breach_screen_transition do
        breach_wait(_INTL("Checking the season...")) { PokemonSurvivor.breach_refresh_season }
        refresh_breach_slot
        draw_select
      end
    end
  end

  def breach_save_menu_progress
    return false unless defined?(Game) && Game.respond_to?(:save)
    PlayerShop.prepare_for_save if defined?(PlayerShop) && PlayerShop.respond_to?(:prepare_for_save)
    saved = Game.save
    PlayerShop.refresh_all_item_icons_for_current_map if defined?(PlayerShop) && PlayerShop.respond_to?(:refresh_all_item_icons_for_current_map)
    saved
  rescue StandardError
    false
  ensure
    @last_time = System.uptime
    @accumulator = 0.0
  end

  def breach_open_leaderboard
    previous_state = @state
    @leaderboard_mode = :breach
    @leaderboard_pokemon_filter = nil
    open_leaderboard
    while @state == :leaderboard || @state == :leaderboard_filter
      Graphics.update
      Input.update
      if @state == :leaderboard
        break if select_back_triggered? || (survivor_confirm_triggered? && !leaderboard_rank_reward_selected?)
        update_leaderboard
      else
        update_leaderboard_filter
      end
    end
  ensure
    @state = previous_state
    play_survivor_menu_bgm
    Input.update
    @last_time = System.uptime
    @accumulator = 0.0
  end

  def breach_season_rule_text(season)
    case PokemonSurvivor.breach_season_style(season[:id])
    when :training then _INTL("Training rooms grant 45 extra Shards.")
    when :modules then _INTL("An extra module every 4 cleared rooms.")
    else _INTL("Standard routes and rewards.")
    end
  end

  def breach_eligible_pokemon
    badges = [:hero_finished?, :hero_boss_finished?, :hero_evolution_finished?,
              :hero_level_finished?, :hero_rush_finished?, :hero_tower_finished?]
    PokemonSurvivor.hero_names.select do |name|
      PokemonSurvivor.hero_unlocked?(name) && badges.all? { |badge| PokemonSurvivor.send(badge, name) }
    end
  end

  def breach_choose_pokemon
    heroes = breach_eligible_pokemon
    if heroes.empty?
      pbMessage(_INTL("Complete all Adventure Badges with a Pokemon to enter Breach."))
      return nil
    end
    # Borrow the normal grid without changing the main menu's selection or list.
    saved = [@heroes, @hero_index, @hero_scroll_row, @select_focus, @confirming_hero, @state]
    @heroes, @hero_index, @hero_scroll_row, @select_focus = heroes, 0, 0, :heroes
    @breach_pokemon_picker_active = true
    @breach_pokemon_start_requested = false
    @confirming_hero = false
    @state = :select
    Input.update
    released = false
    loop do
      Graphics.update
      Input.update
      if @state == :pokemon_training
        update_pokemon_training
        next
      elsif @state == :equipment_menu
        update_pokemon_equipment_menu
        next
      elsif @confirming_hero
        released = true unless PokemonSurvivor.control_press?(:confirm)
        if released
          update_select
          return selected_hero_name if @breach_pokemon_start_requested
        else
          draw_select
        end
        next
      end
      old = @hero_index
      columns = select_grid_columns
      @hero_index = (@hero_index - 1) % heroes.length if Input.repeat?(Input::LEFT)
      @hero_index = (@hero_index + 1) % heroes.length if Input.repeat?(Input::RIGHT)
      @hero_index = [@hero_index - columns, 0].max if Input.repeat?(Input::UP)
      @hero_index = [@hero_index + columns, heroes.length - 1].min if Input.repeat?(Input::DOWN)
      pbPlayCursorSE if old != @hero_index
      ensure_select_scroll
      bitmap = @sprites["screen"].bitmap
      overlay = @sprites["overlay"].bitmap
      overlay.clear
      draw_select_background(bitmap)
      draw_panel(bitmap, 18, 16, Graphics.width - 36, 52, Color.new(94, 226, 200), Color.new(18, 35, 40))
      title = breach_pokemon_picker_title(heroes[@hero_index])
      draw_battle_pass_scrolling_text(bitmap, title, 28, 30, Graphics.width - 56, 24, Color.white)
      draw_select_grid(bitmap)
      draw_help(overlay, [[:left, ""], [:right, _INTL("Pokemon")], [:up, ""], [:down, _INTL("Scroll")], [:confirm, _INTL("Select")], [:cancel, _INTL("Back")]])
      draw_tv_filter(overlay)
      return nil if survivor_cancel_triggered?
      pressed = PokemonSurvivor.control_press?(:confirm)
      released = true unless pressed
      if released && survivor_confirm_triggered?
        pbPlayDecisionSE
        @confirming_hero = true
        released = false
        draw_select
      end
    end
  ensure
    @breach_pokemon_picker_active = false
    @breach_pokemon_start_requested = false
    @heroes, @hero_index, @hero_scroll_row, @select_focus, @confirming_hero, @state = saved if saved
    @last_time = System.uptime
    @accumulator = 0.0
    Input.update
  end

  def breach_pokemon_picker_title(hero_name)
    _INTL("Breach - {1}", PokemonSurvivor.species_name(hero_name))
  end

  def open_mode_select(hero_name)
    return super unless @breach_pokemon_picker_active
    @breach_pokemon_start_requested = true
  end

  def breach_card_choose(title, entries, footer = "", allow_cancel = true, camp_controls = false)
    return nil if entries.empty?
    cards = entries.map do |entry|
      { id: :breach_choice, breach_card: true, name: entry[0], desc: entry[1],
        category_label: entry[2] || title, badge_text: footer, breach_disabled: entry[3] == false,
        breach_color: CHOICE_COLORS[entry[4]] }
    end
    index = cards.index { |card| !card[:breach_disabled] }
    return nil unless index
    opened = System.uptime
    chosen_at = nil
    sounded = false
    released = false
    camp_released = false
    camp_hold = { action: nil, started: nil, progress: 0.0 }
    Input.update
    loop do
      Graphics.update
      Input.update
      now = System.uptime
      if chosen_at
        elapsed = now - chosen_at
        if elapsed >= 0.50 && !sounded
          sounded = true
          play_survivor_se(:breach_choice, "Survivor/Mining reveal", 0.25, PokemonSurvivor::SFX_UPGRADE_CONSUME_VOLUME, 118)
          PokemonSurvivor.gamepad_vibrate_event(:upgrade_take) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
        end
        return index if elapsed >= 0.94
      else
        if camp_controls
          next_pressed = upgrade_reroll_pressed?
          extract_pressed = PokemonSurvivor.control_press?(:cancel)
          camp_released = true unless next_pressed || extract_pressed || PokemonSurvivor.control_press?(:confirm)
          action = if camp_released && next_pressed != extract_pressed
                     next_pressed ? :next_room : (@breach_rooms.to_i >= 3 ? :extract : :leave)
                   end
          breach_update_camp_hold(camp_hold, action, now)
          if camp_hold[:progress] >= 1.0
            draw_breach_choice_cards(title, cards, index, opened, nil, false, false, camp_hold)
            pbPlayDecisionSE
            PokemonSurvivor.gamepad_vibrate_event(:upgrade_take) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
            return action
          end
          if next_pressed || extract_pressed
            draw_breach_choice_cards(title, cards, index, opened, nil, false, false, camp_hold)
            next
          end
        end
        old = index
        [-1, 1].each do |direction|
          next unless Input.repeat?(direction == -1 ? Input::LEFT : Input::RIGHT)
          cards.length.times do
            index = (index + direction) % cards.length
            break unless cards[index][:breach_disabled]
          end
        end
        pbPlayCursorSE if old != index
        return nil if allow_cancel && survivor_cancel_triggered?
        released = true unless PokemonSurvivor.control_press?(:confirm)
        if released && now - opened >= 0.24 && !cards[index][:breach_disabled] && survivor_confirm_triggered?
          if block_given? && !yield(index)
            opened, released = System.uptime, false
            Input.update
            next
          end
          chosen_at = System.uptime
          pbPlayDecisionSE
        end
      end
      draw_breach_choice_cards(title, cards, index, opened, chosen_at, allow_cancel, false, camp_controls ? camp_hold : nil)
    end
  ensure
    dispose_breach_choice_surface
    @last_time = System.uptime
    @accumulator = 0.0
    Input.update
  end

  def breach_update_camp_hold(hold, action, now)
    if action.nil?
      hold.update(action: nil, started: nil, progress: 0.0)
      return
    end
    hold[:started] = now if hold[:action] != action || hold[:started].nil?
    hold[:action] = action
    hold[:progress] = [[(now - hold[:started]) / Scene_PokemonSurvivor::UPGRADE_HOLD_SECONDS, 0.0].max, 1.0].min
  end

  def draw_breach_choice_cards(title, cards, index, opened, chosen_at, allow_cancel = true, skill_controls = false, camp_hold = nil)
    bitmap = @sprites["screen"].bitmap
    overlay = @sprites["overlay"].bitmap
    # The tower transition must remain black beneath the consumption animation.
    bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0))
    overlay.clear
    pbSetSystemFont(overlay)
    draw_breach_shard_balance(overlay)
    draw_breach_camp_status(overlay) if camp_hold
    now = System.uptime
    progress = [[(now - opened) / 0.24, 0.0].max, 1.0].min
    elapsed = chosen_at ? now - chosen_at : 0.0
    out = [elapsed / 0.28, 1.0].min
    center = [[(elapsed - 0.28) / 0.22, 0.0].max, 1.0].min
    consume = [[(elapsed - 0.50) / 0.42, 0.0].max, 1.0].min
    status_height = camp_hold ? 38 : 0
    x, y, w, h = 28, 44 + status_height, Graphics.width - 56, Graphics.height - 92 - status_height
    if !chosen_at || out < 1.0
      py = y + (out * 42).to_i
      draw_panel(overlay, x, py, w, h, Color.new(122, 255, 176), Color.new(19, 31, 53))
      draw_pixel_round_rect(overlay, x + 16, py + 12, w - 32, 34, Color.new(8, 13, 26))
      draw_battle_pass_scrolling_text(overlay, title, x + 26, py + 18, w - 52, 24, Color.new(255, 238, 160), Color.new(40, 40, 48), 2)
    end
    card_w, card_h = (w - 34) / 3, h - 66
    track_x, track_w = x + 10, w - 20
    total_w = cards.length * (card_w + 7) - 7
    max_scroll = [total_w - track_w, 0].max
    context = [cards.object_id, opened, track_w]
    if @breach_choice_scroll_context != context
      @breach_choice_scroll_context = context
      @breach_choice_scroll = 0.0
      @breach_choice_scroll_time = now
    end
    unless chosen_at
      target = [[index * (card_w + 7) - (track_w - card_w) / 2.0, 0.0].max, max_scroll].min
      dt = [[now - @breach_choice_scroll_time, 0.0].max, 0.1].min
      @breach_choice_scroll += (target - @breach_choice_scroll) * (1.0 - Math.exp(-16.0 * dt))
      @breach_choice_scroll = target if (target - @breach_choice_scroll).abs < 0.25
    end
    @breach_choice_scroll_time = now
    surface = breach_choice_surface(track_w)
    surface.clear
    pbSetSystemFont(surface)
    start_x = track_x + [((track_w - total_w) / 2), 0].max - @breach_choice_scroll.round
    cards.each_with_index do |card, i|
      selected = i == index
      cx, cy = start_x + i * (card_w + 7), y + 48
      next if !selected && (cx + card_w + 8 < track_x || cx - 8 > track_x + track_w)
      if chosen_at
        if selected
          ease = center * center * (3.0 - 2.0 * center)
          cx = (cx + (x + (w - card_w) / 2 - cx) * ease).to_i
          cy = (cy + (y + 52 - cy) * ease).to_i
          cx += (Math.sin(consume * Math::PI * 8) * (1 - consume) * 4).to_i if consume > 0
        else
          next if out >= 1
          cy += (out * (Graphics.height - cy + 42 + i * 16)).to_i
        end
      else
        cy += ((1 - progress) * (36 + i * 16)).to_i
      end
      hold = skill_controls && !chosen_at ? @breach_draft_hold_progress.to_f : 0.0
      ban = skill_controls && @breach_draft_hold_action == :ban && selected ? hold : 0.0
      shake = hold > 0 && (@breach_draft_hold_action == :reroll || selected) ? hold : 0.0
      if camp_hold && !chosen_at && [:next_room, :extract, :leave].include?(camp_hold[:action])
        shake = camp_hold[:progress]
        ban = camp_hold[:progress] if [:extract, :leave].include?(camp_hold[:action])
      end
      if shake > 0
        cx += (Math.sin(now * 42 + i) * shake * 8).round
      end
      draw_upgrade_card(surface, card, cx - track_x, cy, card_w, card_h, selected, progress, consume, !!chosen_at && selected, ban)
    end
    overlay.blt(track_x, 0, surface, Rect.new(0, 0, track_w, Graphics.height))
    unless chosen_at
      draw_breach_choice_scrollbar(overlay, track_x, y + h - 12, track_w, cards.length, index, @breach_choice_scroll, total_w) if progress >= 1.0
      help = [[:left, ""], [:right, _INTL("Choice {1}/{2}", index + 1, cards.length)], [:confirm, _INTL("Choose")]]
      help << [:cancel, _INTL("Back")] if allow_cancel
      if skill_controls
        help = [[:left, ""], [:right, skill_controls == :titan ? _INTL("Choices") : _INTL("Skills")], [:confirm, _INTL("Choose")],
          [:action, _INTL("Hold Reroll: {1}", @rerolls_left.to_i)],
          [:ready_menu, _INTL("Hold Ban: {1}", @bans_left.to_i)]]
        help << [:cancel, _INTL("Back")] if allow_cancel
      end
      if camp_hold
        help = [[:left, ""], [:right, _INTL("Choice {1}/{2}", index + 1, cards.length)], [:confirm, _INTL("Choose")],
          [:action, _INTL("Hold Next room")]]
        help << [:cancel, @breach_rooms.to_i >= 3 ? _INTL("Hold Extract") : _INTL("Hold Leave")]
      end
      help.reject! { |entry| entry[0] == :confirm } if cards.all? { |card| card[:breach_disabled] }
      draw_help(overlay, help)
    end
    draw_tv_filter(overlay)
  end

  def breach_choice_surface(width)
    surface = @breach_choice_surface
    if !surface || surface.disposed? || surface.width != width || surface.height != Graphics.height
      surface.dispose if surface && !surface.disposed?
      @breach_choice_surface = Bitmap.new(width, Graphics.height)
    end
    @breach_choice_surface
  end

  def dispose_breach_choice_surface
    @breach_choice_surface.dispose if @breach_choice_surface && !@breach_choice_surface.disposed?
    @breach_choice_surface = nil
    @breach_choice_scroll_context = nil
  end

  def draw_breach_choice_scrollbar(bitmap, x, y, w, count, index, scroll = nil, total_w = nil)
    return if count <= 1
    thumb_w = [[w / count, 28].max, w - 2].min
    position = [[index, 0].max, count - 1].min.to_f / (count - 1)
    if scroll && total_w && total_w > w
      thumb_w = [[(w * w.to_f / total_w).round, 28].max, w - 2].min
      position = [[scroll.to_f / (total_w - w), 0.0].max, 1.0].min
    end
    thumb_x = x + 1 + ((w - thumb_w - 2) * position).round
    draw_battle_pass_horizontal_scrollbar(bitmap, x, y, w, 7, thumb_x, thumb_w)
  end

  def draw_breach_shard_balance(bitmap)
    total = Graphics.width - 56
    room_w, voucher_w = [(total * 0.22).floor, 96].min, (total * 0.31).floor
    w, h = total - room_w - voucher_w - 16, 32
    x, y = Graphics.width - 28 - w, 6
    draw_battle_pass_flat_panel(bitmap, 28, y, room_w, h, Color.new(94, 226, 200), Color.new(18, 35, 40))
    draw_battle_pass_scrolling_text(bitmap, _INTL("Room: {1}", @breach_rooms.to_i), 36, y + 5, room_w - 16, 22,
      Color.new(255, 238, 160), Color.new(25, 25, 30), 2)
    voucher_x = 28 + room_w + 8
    draw_battle_pass_flat_panel(bitmap, voucher_x, y, voucher_w, h, Color.new(192, 142, 255), Color.new(30, 24, 42))
    draw_battle_pass_scrolling_text(bitmap, _INTL("Vouchers: {1}", @breach_skill_vouchers.to_i), voucher_x + 8, y + 5, voucher_w - 16, 22,
      Color.new(255, 238, 160), Color.new(25, 25, 30), 2)
    draw_battle_pass_flat_panel(bitmap, x, y, w, h, Color.new(94, 226, 200), Color.new(18, 35, 40))
    icon = cached_bitmap(PokemonSurvivor::ITEM_DIR, "SHARD")
    text_x = x + 10
    if icon && !icon.disposed?
      bitmap.blt(text_x, y + (h - icon.height) / 2, icon, Rect.new(0, 0, icon.width, icon.height))
      text_x += icon.width + 8
    end
    amount = [@breach_shards.to_i, 0].max.to_s
    amount = _INTL("Shards: {1}", amount) unless icon && !icon.disposed?
    draw_battle_pass_scrolling_text(bitmap, amount, text_x, y + 5, x + w - 10 - text_x, 22,
      Color.new(255, 238, 160), Color.new(25, 25, 30), 2)
  end

  def breach_quests_menu(season, quests)
    breach_rewards_menu(season, quests, :quests)
  end

  def breach_reward_rows(season, quests)
    progress = PokemonSurvivor.breach_progress(season[:id])
    quests.map do |quest|
      { quest: quest, value: PokemonSurvivor.breach_quest_value(season, quest),
        validated: !!(progress[:validated][quest[:id]] || progress[:claimed][quest[:id]]),
        claimed: !!progress[:claimed][quest[:id]] }
    end
  end

  def breach_rewards_menu(season, quests, page = :rewards)
    indices = { rewards: 0, quests: 0 }
    scroll = 0.0
    surface = Bitmap.new(Graphics.width - 32, [Graphics.height - 194, 150].max)
    rows = breach_reward_rows(season, quests)
    Input.update
    loop do
      Graphics.update
      Input.update
      break if survivor_cancel_triggered?
      if battle_pass_reward_claim_triggered?
        page = page == :rewards ? :quests : :rewards
      elsif !rows.empty?
        previous = page == :rewards ? Input::LEFT : Input::UP
        following = page == :rewards ? Input::RIGHT : Input::DOWN
        indices[page] = (indices[page] - 1) % rows.length if Input.repeat?(previous)
        indices[page] = (indices[page] + 1) % rows.length if Input.repeat?(following)
        auto = battle_pass_auto_claim_triggered?
        if auto || survivor_confirm_triggered?
          targets = auto ? quests : [quests[indices[page]]]
          method = page == :quests ? :breach_validate_quest : :breach_claim_quest
          changed = false
          targets.each { |quest| changed = PokemonSurvivor.send(method, season, quest) || changed }
          if changed
            Game.save if defined?(Game) && Game.respond_to?(:save)
            pbPlayDecisionSE
            rows = breach_reward_rows(season, quests)
          end
        end
      end
      if page == :rewards
        total = rows.length * 142 - 14
        target = [[indices[page] * 142 - (surface.width - 128) / 2, 0].max, [total - surface.width, 0].max].min
        scroll += (target - scroll) * 0.28
      end
      draw_breach_rewards_screen(season, rows, page, indices[page], surface, scroll)
    end
  ensure
    surface.dispose if surface && !surface.disposed?
    @last_time = System.uptime
    @accumulator = 0.0
    Input.update
  end

  def breach_quest_description(quest)
    count = quest[:target]
    case quest[:metric]
    when :rooms then _INTL("Clear {1} rooms this season.", count)
    when :runs then _INTL("Play {1} runs this season.", count)
    when :kills then _INTL("Defeat {1} enemies this season.", count)
    when :extractions then _INTL("Extract successfully {1} times this season.", count)
    when :fusions then _INTL("Fuse modules {1} times this season.", count)
    when :levels then _INTL("Gain {1} levels this season.", count)
    when :pokemon then _INTL("Extract with {1} different Pokemon this season.", count)
    when :threat then _INTL("Overcome {1} Threat points by clearing rooms this season.", count)
    when :unfair_rooms then _INTL("Clear {1} Unfair rooms this season.", count)
    else _INTL(quest[:name])
    end
  end

  def breach_reward_status(row, page)
    return _INTL("Claimed") if row[:claimed]
    return page == :quests ? _INTL("Validated") : _INTL("Ready") if row[:validated]
    return _INTL("Ready") if page == :quests && row[:value] >= row[:quest][:target]
    _INTL("Locked")
  end

  def draw_breach_rewards_screen(season, rows, page, index, surface, scroll)
    bitmap = @sprites["screen"].bitmap
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    draw_battle_pass_reward_background(bitmap)
    pbSetSystemFont(bitmap)
    gold = Color.new(255, 214, 92)
    white = Color.new(232, 238, 248)
    shadow = Color.new(25, 25, 30)
    dark = Color.new(18, 24, 42)
    draw_battle_pass_flat_panel(bitmap, 8, 8, Graphics.width - 16, 54, dark, Color.new(28, 38, 64))
    icon = cached_icon_bitmap("ICON_SEASON")
    title_x = 20
    if icon && !icon.disposed?
      bitmap.blt(18, 8 + (54 - icon.height) / 2, icon, Rect.new(0, 0, icon.width, icon.height))
      title_x = 26 + icon.width
    end
    right_w = 140
    title_w = [Graphics.width - right_w - title_x - 24, 1].max
    title = page == :rewards ? _INTL("Season {1} - Rewards", season[:id]) : _INTL("Season {1} - Quests", season[:id])
    draw_battle_pass_scrolling_text(bitmap, title, title_x, 14, title_w, 24, gold, shadow)
    validated = rows.count { |row| row[:validated] }
    draw_battle_pass_gauge(bitmap, title_x, 44, title_w, 10, validated.to_f / [rows.length, 1].max, Color.new(80, 190, 255), gold)
    right_x = Graphics.width - right_w - 18
    draw_battle_pass_scrolling_text(bitmap, _INTL("{1}/{2}", validated, rows.length), right_x, 12, right_w, 22, white, shadow, 2)
    draw_battle_pass_scrolling_text(bitmap, breach_season_time_text(season), right_x, 35, right_w, 22, gold, shadow, 2)

    surface.clear
    pbSetSystemFont(surface)
    top = 76
    draw_battle_pass_flat_panel(bitmap, 8, top - 6, Graphics.width - 16, surface.height + 12, dark)
    if page == :rewards
      rows.each_with_index do |row, i|
        x = i * 142 - scroll.round
        next if x + 128 <= 0 || x >= surface.width
        draw_breach_reward_card(surface, row, i + 1, x, 0, 128, surface.height, i == index)
      end
    else
      visible = [surface.height / 32, 1].max + 1
      row_h = surface.height / visible
      slot_h = row_h - [[row_h - 24, 2].max, 4].min
      first = [[index - visible / 2, 0].max, [rows.length - visible, 0].max].min
      rows[first, visible].to_a.each_with_index do |row, i|
        y = i * row_h
        ready = row[:value] >= row[:quest][:target]
        fill = row[:validated] ? Color.new(24, 58, 42) : (ready ? Color.new(56, 54, 34) : Color.new(22, 28, 44))
        draw_battle_pass_flat_panel(surface, 0, y, surface.width - 16, slot_h,
          first + i == index ? gold : Color.new(72, 92, 132), fill)
        name_inset = ready && !row[:validated] ? 24 : 10
        name_w = surface.width - 138 - name_inset
        text_y = y + (slot_h - 22) / 2
        draw_battle_pass_scrolling_text(surface, _INTL(row[:quest][:name]), name_inset, text_y, name_w, 22, white, shadow)
        draw_battle_pass_scrolling_text(surface, breach_reward_status(row, :quests), surface.width - 128, text_y, 100, 22, gold, shadow, 2)
        draw_menu_notification(surface, 0, y) if ready && !row[:validated]
      end
      draw_battle_pass_quest_scrollbar(surface, surface.width - 8, 0, 6, surface.height, rows.length, visible, first)
    end
    bitmap.blt(16, top, surface, Rect.new(0, 0, surface.width, surface.height))
    if page == :rewards && rows.length * 142 - 14 > surface.width
      total = rows.length * 142 - 14
      thumb = [(surface.width * surface.width.to_f / total).to_i, 28].max
      tx = 16 + ((surface.width - thumb) * scroll / (total - surface.width)).to_i
      draw_battle_pass_horizontal_scrollbar(bitmap, 16, top + surface.height + 8, surface.width, 7, tx, thumb)
    end
    row = rows[index]
    y = top + surface.height + 22
    draw_battle_pass_flat_panel(bitmap, 8, y, Graphics.width - 16, 62, dark, Color.new(30, 42, 66))
    if row
      quest = row[:quest]
      text = page == :quests ? breach_quest_description(quest) : _INTL(quest[:name])
      draw_battle_pass_scrolling_text(bitmap, text, 20, y + 4, Graphics.width - 40, 22, white, shadow)
      detail = page == :quests ? _INTL("{1}/{2}", [row[:value], quest[:target]].min, quest[:target]) :
        PokemonSurvivor.breach_reward_text(quest)
      draw_battle_pass_scrolling_text(bitmap, detail, 20, y + 28, Graphics.width - 40, 22, gold, shadow)
      draw_battle_pass_quest_progress_bar(bitmap, 20, y + 51, Graphics.width - 40, 10,
        row[:value], quest[:target], row[:validated], row[:claimed])
    else
      draw_battle_pass_scrolling_text(bitmap, _INTL("No season quests available."), 20, y + 18, Graphics.width - 40, 24, white, shadow)
    end
    helpers = page == :quests ? [[:up, ""], [:down, _INTL("Quests")], [:confirm, _INTL("Validate")], [:action, _INTL("Validate All")], [:menu, _INTL("Rewards")]] :
      [[:left, ""], [:right, _INTL("Rewards")], [:confirm, _INTL("Claim Reward")], [:action, _INTL("Auto Claim")], [:menu, _INTL("Quests")]]
    draw_help(overlay, helpers + [[:cancel, _INTL("Back")]])
    draw_tv_filter(overlay)
  end

  def draw_breach_reward_card(bitmap, row, tier, x, y, w, h, selected)
    gold = Color.new(255, 214, 92)
    shadow = Color.new(32, 32, 40)
    ready = row[:validated]
    edge = selected ? gold : (ready ? Color.new(126, 255, 174) : Color.new(52, 62, 86))
    fill = row[:claimed] ? Color.new(24, 58, 42) : Color.new(28, 48, 78)
    draw_battle_pass_flat_panel(bitmap, x, y, w, h, edge, fill)
    draw_pixel_round_rect(bitmap, x + 10, y + 8, w - 20, 28, Color.new(8, 13, 26))
    draw_battle_pass_scrolling_text(bitmap, _INTL("Reward {1}", tier), x + 14, y + 11, w - 28, 22, gold, shadow, 2)
    # One currency per tier, centered above its quantity.
    area_y = y + 42
    area_h = h - 84
    draw_pixel_round_rect(bitmap, x + 10, area_y, w - 20, area_h, Color.new(8, 13, 26))
    kind = row[:quest][:candies].to_i > 0 ? :candies : :fragments
    icon = cached_icon_bitmap(kind == :candies ? "ICON_CANDY" : "ICON_FRAGMENT")
    if icon && !icon.disposed?
      size = [area_h - 32, 40, icon.width, icon.height].min
      bitmap.stretch_blt(Rect.new(x + (w - size) / 2, area_y + (area_h - size - 26) / 2, size, size), icon, Rect.new(0, 0, icon.width, icon.height))
    end
    draw_battle_pass_scrolling_text(bitmap, _INTL("x{1}", row[:quest][kind]), x + 14, area_y + area_h - 26, w - 28, 22, Color.white, shadow, 2)
    draw_pixel_round_rect(bitmap, x + 10, y + h - 34, w - 20, 26, Color.new(8, 13, 26))
    color = row[:claimed] ? Color.new(92, 188, 255) : (ready ? Color.new(92, 232, 148) : Color.new(236, 84, 84))
    draw_battle_pass_scrolling_text(bitmap, breach_reward_status(row, :rewards), x + 14, y + h - 32, w - 28, 22, color, shadow, 2)
    draw_menu_notification(bitmap, x, y) if ready && !row[:claimed]
  end

  def draw_breach_camp_status(bitmap)
    total = Graphics.width - 56
    level_w = [(total * 0.22).floor, 96].min
    x, y, h = 28, 44, 32
    draw_battle_pass_flat_panel(bitmap, x, y, level_w, h, Color.new(94, 226, 200), Color.new(18, 35, 40))
    draw_battle_pass_scrolling_text(bitmap, _INTL("Lv.{1}", @level), x + 8, y + 5, level_w - 16, 22,
      Color.new(255, 238, 160), Color.new(25, 25, 30), 2)
    hp_x, hp_w = x + level_w + 8, total - level_w - 8
    draw_battle_pass_flat_panel(bitmap, hp_x, y, hp_w, h, Color.new(94, 226, 200), Color.new(18, 35, 40))
    rate = [[@hero.hp.to_f / [@hero.max_hp.to_f, 1.0].max, 0.0].max, 1.0].min
    color = rate > 0.5 ? Color.new(72, 224, 112) : (rate >= 0.25 ? Color.new(248, 200, 56) : Color.new(240, 72, 72))
    draw_status_bar(bitmap, hp_x + 8, y + 8, hp_w - 16, 16, rate, color)
  end

  def breach_skill_menu_cards
    cards = breach_skill_cards
    return cards unless cards.empty?
    required = breach_next_skill_level
    description = required ? _INTL("Reach Pokemon level {1} to improve your skills further.", required) : _INTL("No skill upgrades available.")
    [{ id: :breach_skills_unavailable, breach_card: true, breach_disabled: true,
       name: _INTL("Skills"), desc: description, category_label: _INTL("Back"), badge_text: "" }]
  end

  def breach_healing_cost
    base = 65 + [@breach_rooms.to_i, 0].max * 6
    (base * (4 + [@breach_heal_purchases.to_i, 0].max) + 3) / 4
  end

  def breach_buy_healing
    cost = breach_healing_cost
    return false if @breach_shards.to_i < cost || @hero.hp >= @hero.max_hp
    @breach_shards -= cost
    @hero.hp = [@hero.hp + (@hero.max_hp * 0.25).ceil, @hero.max_hp].min
    @breach_heal_purchases = @breach_heal_purchases.to_i + 1
    true
  end

  def breach_open_camp
    breach_module_choice_menu
    loop do
      level_cost = 60 + @level.to_i * 6
      healing_cost = breach_healing_cost
      choice = breach_card_choose(_INTL("Breach camp"), [
        [_INTL("Training"), _INTL("Gain 5 levels. Unlock stronger skill upgrades and progress towards evolution."), _INTL("{1} Shards", level_cost), @breach_shards.to_i >= level_cost && @level < 9999, :training],
        [_INTL("Skills"), _INTL("Improve your attacks."), breach_skill_progress_text, true, :skills],
        [_INTL("Modules"), _INTL("Inspect, equip, fuse or sell your modules."), _INTL("{1}/6", @breach_modules.length), !(@breach_modules || []).empty? || !(@breach_inventory || []).empty? || !(@breach_module_drafts || []).empty?, :modules],
        [_INTL("Heal"), _INTL("Restore 25% HP. Each purchase raises the price for this run."), _INTL("{1} Shards", healing_cost), @hero.hp < @hero.max_hp && @breach_shards.to_i >= healing_cost, :healing]
      ], "", false, true)
      case choice
      when 0
        next if @breach_shards < level_cost || @level >= 9999
        @breach_shards -= level_cost
        [5, 9999 - @level].min.times { @level += 1; apply_passive_level_bonus }
        check_hero_evolution
      when 1 then breach_skill_menu
      when 2 then breach_modules_menu
      when 3
        breach_buy_healing
      when :next_room
        routes = breach_route_choices
        choices = routes.map do |route|
          risk = PokemonSurvivor::BREACH_DIFFICULTIES[route[:difficulty]]
          difficulty = _INTL(risk[:name])
          description = _INTL(route[:desc])
          [_INTL(route[:name]), description, difficulty, true, route[:id]]
        end
        pick = breach_card_choose(_INTL("Choose a route"), choices)
        next if pick.nil?
        @breach_route = routes[pick]
        return
      when :extract
        next if @breach_rooms < 3
        next unless pbConfirmMessage(_INTL("Extract and secure your loot?"))
        @breach_extracted = true
        finish_run
        return
      when :leave
        next unless pbConfirmMessage(_INTL("Leave this Breach run and return to the season menu? No rewards will be kept."))
        @run_abandoned = true
        finish_run
        return :leave
      end
    end
  end

  def breach_skill_menu
    breach_refresh_skill_offers
    if @breach_skill_offers.empty?
      if breach_vouchers_convertible? && @breach_skill_vouchers.to_i > 0
        breach_convert_vouchers_menu
        return
      end
    end
    index, opened, chosen_at = 0, System.uptime, nil
    payment = nil
    hold_started, released, sounded = nil, false, false
    cards = breach_skill_menu_cards
    index = cards.index { |card| !card[:breach_disabled] } || 0
    Input.update
    loop do
      Graphics.update
      Input.update
      now = System.uptime
      if chosen_at
        if now - chosen_at >= 0.50 && !sounded
          sounded = true
          play_survivor_se(:breach_choice, "Survivor/Mining reveal", 0.25, PokemonSurvivor::SFX_UPGRADE_CONSUME_VOLUME, 118)
          PokemonSurvivor.gamepad_vibrate_event(:upgrade_take) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
        end
        if now - chosen_at >= 0.94
          upgrade = @breach_skill_offers[index]
          if breach_purchase_skill(upgrade, payment)
            @breach_skill_offers = nil
            check_hero_evolution
          end
          breach_refresh_skill_offers
          cards = breach_skill_menu_cards
          index = cards.index { |card| !card[:breach_disabled] } || 0
          opened, chosen_at, payment = System.uptime, nil, nil
          sounded, released, hold_started = false, false, nil
          @breach_draft_hold_action, @breach_draft_hold_progress = nil, 0.0
          next
        end
      else
        return if survivor_cancel_triggered?
        reroll, ban = upgrade_reroll_pressed?, upgrade_ban_pressed?
        any_pressed = reroll || ban || PokemonSurvivor.control_press?(:confirm)
        released = true unless any_pressed
        if released
          wanted = reroll ? :reroll : (ban ? :ban : nil)
          wanted = nil if wanted == :reroll && @rerolls_left.to_i <= 0
          wanted = nil if wanted == :ban && @bans_left.to_i <= 0
          if wanted
            hold_started = now if @breach_draft_hold_action != wanted || !hold_started
            @breach_draft_hold_action = wanted
            @breach_draft_hold_progress = [(now - hold_started) / Scene_PokemonSurvivor::UPGRADE_HOLD_SECONDS, 1.0].min
            if @breach_draft_hold_progress >= 1
              wanted == :reroll ? breach_reroll_skills : breach_ban_skill(@breach_skill_offers[index])
              cards, index, opened = breach_skill_menu_cards, 0, System.uptime
              index = cards.index { |card| !card[:breach_disabled] } || 0
              released, hold_started = false, nil
              @breach_draft_hold_progress = 0.0
            end
          else
            hold_started = nil
            @breach_draft_hold_action = nil
            @breach_draft_hold_progress = 0.0
            old = index
            [-1, 1].each do |direction|
              next unless Input.repeat?(direction == -1 ? Input::LEFT : Input::RIGHT)
              cards.length.times do
                index = (index + direction) % cards.length
                break unless cards[index][:breach_disabled]
              end
            end
            pbPlayCursorSE if old != index
            if survivor_confirm_triggered? && now - opened >= 0.24 && !cards[index][:breach_disabled]
              if breach_skill_voucher_usable?(@breach_skill_offers[index]) || @breach_shards >= breach_skill_cost(@breach_skill_offers[index])
                payment = breach_choose_skill_payment(@breach_skill_offers[index])
                if payment
                  chosen_at = System.uptime
                  pbPlayDecisionSE
                else
                  opened, released = System.uptime, false
                end
              else
                pbMessage(_INTL("Not enough Shards."))
                released = false
              end
            end
          end
        end
      end
      draw_breach_choice_cards(_INTL("Skills"), cards, index, opened, chosen_at, true, true)
    end
  ensure
    @breach_draft_hold_action = nil
    @breach_draft_hold_progress = 0.0
    dispose_breach_choice_surface
    @last_time = System.uptime
    @accumulator = 0.0
    Input.update
  end

  def breach_route_choices
    if @breach_route_offers && @breach_route_offers_room == @breach_rooms
      return @breach_route_offers
    end
    choices = []
    weights = PokemonSurvivor.breach_route_weights(@breach_rooms)
    3.times do |index|
      remaining = PokemonSurvivor::BREACH_ROUTES.reject { |route| choices.any? { |chosen| chosen[:id] == route[:id] } }
      difficulty = [:easy, :hard, :unfair][index]
      if @breach_rooms.to_i >= 3
        available = weights.select { |key, _| remaining.any? { |route| route[:difficulty] == key } }
        roll = rand * available.values.sum
        difficulty = available.keys.last
        available.each do |key, weight|
          roll -= weight
          if roll < 0
            difficulty = key
            break
          end
        end
      end
      pool = remaining.select { |route| route[:difficulty] == difficulty }
      fresh = pool.reject { |route| route[:id] == @breach_route[:id] }
      pool = fresh unless fresh.empty?
      diverse = pool.reject { |route| choices.any? { |chosen| chosen[:objective] == route[:objective] } }
      choices << (diverse.empty? ? pool : diverse).sample
    end
    @breach_route_offers_room = @breach_rooms
    @breach_route_offers = choices.freeze
  end

  def breach_skill_pool
    breach_uncapped_skill_pool.select { |upgrade| @level.to_i >= breach_skill_required_level(upgrade) }
  end

  def breach_uncapped_skill_pool
    pool = active_skill_upgrades
    pool = pool + available_move_upgrades if @learned_skills.length < PokemonSurvivor::MAX_ACTIVE_SKILLS
    breach_allowed_skill_upgrades(pool).select do |upgrade|
      @upgrade_levels[upgrade[:id]].to_i < upgrade[:max].to_i
    end
  end

  def breach_skill_required_level(upgrade)
    return 1 if upgrade[:skill]
    # Each bonus rank requires ten more Pokemon levels; learning a move stays free of level gates.
    6 + [@upgrade_levels[upgrade[:id]].to_i, 0].max * 10
  end

  def breach_next_skill_level
    breach_uncapped_skill_pool.map { |upgrade| breach_skill_required_level(upgrade) }.
      select { |required| required > @level.to_i }.min
  end

  def breach_allowed_skill_upgrades(pool)
    pool.select do |upgrade|
      !(@banned_upgrade_ids || []).include?(upgrade[:id]) &&
        upgrade[:max].to_i > 0 &&
        (!upgrade[:target_skill] || @learned_skills.include?(upgrade[:target_skill]))
    end.uniq { |upgrade| upgrade[:id] }
  end

  def breach_skill_progress_text
    if @learned_skills.length < PokemonSurvivor::MAX_ACTIVE_SKILLS
      return _INTL("{1}/{2}", @learned_skills.length, PokemonSurvivor::MAX_ACTIVE_SKILLS)
    end
    acquired = 0
    total = 0
    # Keep capped upgrades in the denominator; exclude banned upgrades entirely.
    breach_allowed_skill_upgrades(active_skill_upgrades).each do |upgrade|
      next if upgrade[:skill]
      cap = upgrade[:max].to_i
      total += cap
      acquired += [[@upgrade_levels[upgrade[:id]].to_i, 0].max, cap].min
    end
    _INTL("{1}/{2}", acquired, total)
  end

  def breach_skill_cost(upgrade)
    upgrade[:skill] ? 180 + @learned_skills.length * 60 : 80 + @upgrade_levels[upgrade[:id]].to_i * 40
  end

  def breach_skill_voucher_usable?(upgrade)
    @breach_skill_vouchers.to_i > 0 && breach_voucher_levels(upgrade) > 0
  end

  def breach_voucher_levels(upgrade)
    return 0 if !upgrade || upgrade[:skill] || (@banned_upgrade_ids || []).include?(upgrade[:id])
    current = @upgrade_levels[upgrade[:id]].to_i
    unlocked = @level.to_i < 6 ? 0 : ((@level.to_i - 6) / 10) + 1
    [[2, upgrade[:max].to_i - current, unlocked - current].min, 0].max
  end

  def breach_choose_skill_payment(upgrade)
    return :shards unless breach_skill_voucher_usable?(upgrade)
    current = @upgrade_levels[upgrade[:id]].to_i
    levels = breach_voucher_levels(upgrade)
    choices = [
      [_INTL("Pay with Shards"), _INTL("Gain one upgrade level. Keep your Vouchers."), _INTL("{1} Shards", breach_skill_cost(upgrade)), @breach_shards.to_i >= breach_skill_cost(upgrade), :training],
      [_INTL("Use a Voucher"), _INTL("{1}: Lv.{2} -> Lv.{3}. Uses one Voucher.", _INTL(upgrade[:name]), current, current + levels), _INTL("+{1} levels", levels), true, :skills]
    ]
    choice = breach_card_choose(_INTL("Choose payment"), choices)
    choice.nil? ? nil : (choice == 0 ? :shards : :voucher)
  end

  def breach_purchase_skill(upgrade, payment)
    return false unless [:shards, :voucher].include?(payment)
    return false unless breach_skill_pool.any? { |entry| entry[:id] == upgrade[:id] }
    if payment == :voucher
      return false unless breach_skill_voucher_usable?(upgrade)
      count = breach_voucher_levels(upgrade)
      @breach_skill_vouchers -= 1
    else
      cost = breach_skill_cost(upgrade)
      return false if @breach_shards.to_i < cost
      @breach_shards -= cost
      count = 1
    end
    count.times { apply_upgrade(upgrade) }
    true
  end

  def breach_vouchers_convertible?
    return false if @learned_skills.length < PokemonSurvivor::MAX_ACTIVE_SKILLS
    breach_allowed_skill_upgrades(active_skill_upgrades).none? do |upgrade|
      !upgrade[:skill] && @upgrade_levels[upgrade[:id]].to_i < upgrade[:max].to_i
    end
  end

  def breach_convert_vouchers
    return false unless breach_vouchers_convertible? && @breach_skill_vouchers.to_i > 0
    @breach_shards += @breach_skill_vouchers * 160
    @breach_skill_vouchers = 0
    true
  end

  def breach_convert_vouchers_menu
    count = @breach_skill_vouchers.to_i
    entries = [[_INTL("Convert Vouchers"), _INTL("All available skill upgrades are complete. Exchange {1} Vouchers for {2} Shards.", count, count * 160), _INTL("160 Shards each"), true, :treasure]]
    return if breach_card_choose(_INTL("Skills complete"), entries).nil?
    return unless pbConfirmMessage(_INTL("Exchange {1} Vouchers for {2} Shards?", count, count * 160))
    breach_convert_vouchers
  end

  def breach_refresh_skill_offers
    pool = breach_skill_pool
    ids = (@breach_skill_offers || []).map { |upgrade| upgrade[:id] }
    @breach_skill_offers = ids.map { |id| pool.find { |upgrade| upgrade[:id] == id } }.compact.first(3)
    remaining = pool.reject { |upgrade| @breach_skill_offers.any? { |offered| offered[:id] == upgrade[:id] } }
    @breach_skill_offers.concat(breach_choose_skill_offers(remaining, 3 - @breach_skill_offers.length, @breach_skill_offers))
  end

  def breach_choose_skill_offers(pool, count, offered = [])
    return [] if count <= 0 || pool.empty?
    if offered.any? { |upgrade| PokemonSurvivor::EEVEE_ORBIT_SKILLS.key?(upgrade[:skill]) }
      pool = pool.reject { |upgrade| PokemonSurvivor::EEVEE_ORBIT_SKILLS.key?(upgrade[:skill]) }
    end
    # The eight Eevee spheres share one draft slot instead of eight lottery tickets.
    groups = pool.group_by do |upgrade|
      PokemonSurvivor::EEVEE_ORBIT_SKILLS.key?(upgrade[:skill]) ? :eevee_spheres : upgrade[:id]
    end
    candidates = groups.values.map { |entries| entries.sample }
    choices = []
    learning, improving = candidates.partition { |upgrade| upgrade[:skill] }
    if count >= 2 && !learning.empty? && !improving.empty?
      choices.concat(choose_weighted_upgrades(learning, 1))
      choices.concat(choose_weighted_upgrades(improving, 1))
    end
    choices.concat(choose_weighted_upgrades(candidates - choices, count - choices.length))
    choices
  end

  def breach_skill_cards
    @breach_skill_offers.map do |upgrade|
      payment = breach_skill_voucher_usable?(upgrade) ? _INTL("{1} Shards / 1 Voucher", breach_skill_cost(upgrade)) : _INTL("{1} Shards", breach_skill_cost(upgrade))
      upgrade.merge(breach_card: true, category_label: payment,
        breach_disabled: !breach_skill_voucher_usable?(upgrade) && @breach_shards.to_i < breach_skill_cost(upgrade),
        badge_text: _INTL("Lv.{1}/{2}", @upgrade_levels[upgrade[:id]].to_i, upgrade[:max]))
    end
  end

  def breach_reroll_skills
    return false if @rerolls_left.to_i <= 0
    ids = @breach_skill_offers.map { |upgrade| upgrade[:id] }
    fresh = breach_skill_pool.reject { |upgrade| ids.include?(upgrade[:id]) }
    return false if fresh.empty?
    choices = breach_choose_skill_offers(fresh, 3)
    choices.concat(breach_choose_skill_offers(@breach_skill_offers, 3 - choices.length, choices)) if choices.length < 3
    @breach_skill_offers = choices
    @rerolls_left -= 1
    pbPlayCursorSE
    PokemonSurvivor.gamepad_vibrate_event(:upgrade_reroll) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
    true
  end

  def breach_ban_skill(upgrade)
    return false if !upgrade || @bans_left.to_i <= 0
    @banned_upgrade_ids ||= []
    return false if @banned_upgrade_ids.include?(upgrade[:id])
    return false if acquired_irreversible_upgrade?(upgrade) && @upgrade_levels[upgrade[:id]].to_i > 0
    return false unless confirm_ban_acquired_upgrade(upgrade)
    return false if @upgrade_levels[upgrade[:id]].to_i > 0 && !remove_upgrade_effect(upgrade)
    @banned_upgrade_ids << upgrade[:id]
    @bans_left -= 1
    previous = (@breach_skill_offers || []).map { |offer| offer[:id] }
    pool = breach_skill_pool
    fresh = pool.reject { |offer| previous.include?(offer[:id]) }
    @breach_skill_offers = breach_choose_skill_offers(fresh, 3)
    if @breach_skill_offers.length < 3
      remaining = pool.select { |offer| previous.include?(offer[:id]) }
      @breach_skill_offers.concat(breach_choose_skill_offers(remaining, 3 - @breach_skill_offers.length, @breach_skill_offers))
    end
    pbPlayCancelSE
    PokemonSurvivor.gamepad_vibrate_event(:upgrade_ban) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
    true
  end

  def breach_module_choice_menu
    while (offers = (@breach_module_drafts || []).first)
      entries = offers.map do |id|
        rank = breach_module_rank(id)
        label = rank >= 3 ? _INTL("40 Shards when installed") : _INTL("Rank {1}/3", rank + 1)
        effect = breach_module_effect_text(id, [rank + 1, 3].min)
        [breach_module_name(id), effect, label, true, id]
      end
      pick = breach_card_choose(_INTL("Choose a module"), entries)
      return if pick.nil?
      breach_take_module_choice(pick)
    end
  end

  def breach_modules_menu
    breach_module_choice_menu
    loop do
      entries = [
        [_INTL("Equipped Modules"), _INTL("Inspect active effects or sell a module."), _INTL("{1}/6", @breach_modules.length), !@breach_modules.empty?, :modules],
        [_INTL("Module Reserve"), _INTL("Equip, fuse or sell stored modules."), _INTL("Stored: {1}", @breach_inventory.length), !@breach_inventory.empty?, :treasure],
        [_INTL("Auto-sell Modules"), _INTL("Sell new modules automatically. Requires six equipped modules at max rank. Resets each run."),
          @breach_auto_sell_modules ? _INTL("On") : _INTL("Off"), @breach_auto_sell_modules || breach_auto_sell_modules_available?, :modules],
        [_INTL("Sell All Unequipped"), _INTL("Sell all stored modules. Equipped modules are kept."),
          _INTL("{1} Shards", breach_reserve_sale_total), !@breach_inventory.empty?, :treasure]
      ]
      pick = breach_card_choose(_INTL("Module inventory"), entries)
      return if pick.nil?
      case pick
      when 0, 1 then breach_module_inventory_menu(pick == 0)
      when 2
        next unless @breach_auto_sell_modules || breach_auto_sell_modules_available?
        @breach_auto_sell_modules = !@breach_auto_sell_modules
        pbPlayDecisionSE
      when 3
        next if @breach_inventory.empty?
        next unless pbConfirmMessage(_INTL("Sell all {1} stored modules for {2} Shards? Equipped modules will be kept.",
          @breach_inventory.length, breach_reserve_sale_total))
        pbPlayDecisionSE if breach_sell_all_reserve
      end
    end
  end

  def breach_module_name(id)
    case id
    when :power then _INTL("Damage Module")
    when :tempo then _INTL("Attack Cooldown Module")
    when :guard then _INTL("Contact Armor Module")
    when :stride then _INTL("Movement Speed Module")
    when :magnet then _INTL("Pickup Range Module")
    when :burst then _INTL("Burst Charge Module")
    when :reach then _INTL("Projectile Armor Module")
    when :recovery then _INTL("Room Healing Module")
    when :dash then _INTL("Dash Cooldown Module")
    when :salvage then _INTL("Shard Gain Module")
    when :precision then _INTL("Boss Damage Module")
    when :momentum then _INTL("Dash Damage Module")
    when :barrier then _INTL("Room Shield Module")
    when :execution then _INTL("Finisher Module")
    when :companion then _INTL("Companion Module")
    when :control then _INTL("Status Duration Module")
    when :last_stand then _INTL("Low-HP Armor Module")
    when :reserve then _INTL("Burst Refund Module")
    else _INTL("Module")
    end
  end

  def breach_module_effect_text(id, rank)
    rank = [[rank.to_i, 1].max, 3].min
    data = PokemonSurvivor::BREACH_MODULES.find { |entry| entry[:id] == id }
    return "" unless data
    factor = data[:factor] || data[:speed]
    amount = factor ? format("%.1f", ((factor ** rank - 1.0) * 100).abs).sub(/\.0$/, "") : nil
    case id
    when :power then _INTL("Damage +{1}%.", amount)
    when :tempo then _INTL("Attack cooldown -{1}%.", amount)
    when :guard then _INTL("Contact damage taken -{1}%.", amount)
    when :stride then _INTL("Movement speed +{1}%.", amount)
    when :magnet then _INTL("Pickup range +{1}%. Each +1% pickup range grants +0.5% Shards in Breach (max +50%).", amount)
    when :burst then _INTL("Burst charge speed +{1}%.", amount)
    when :reach then _INTL("Projectile damage taken -{1}%.", amount)
    when :recovery then _INTL("Restore {1}% HP after each room.", 2 * rank)
    when :dash
      reduction = format("%.1f", (1.0 - 0.95 ** rank) * 100).sub(/\.0$/, "")
      _INTL("Dash cooldown -{1}%. Minimum: 3s.", reduction)
    when :salvage then _INTL("Shards from enemies +{1}%.", 8 * rank)
    when :precision then _INTL("Damage to bosses, elites and Seals +{1}%.", 10 * rank)
    when :momentum then _INTL("Damage +{1}% for 3s after a Dash.", 10 * rank)
    when :barrier then _INTL("Start each room with a shield worth {1}% max HP.", 5 * rank)
    when :execution then _INTL("Damage +{1}% against enemies below 25% HP.", 8 * rank)
    when :companion then _INTL("Companion damage and max HP +{1}%. No healing.", 10 * rank)
    when :control then _INTL("Inflicted status duration +{1}%.", amount)
    when :last_stand
      reduction = format("%.1f", (1.0 - 0.95 ** rank) * 100).sub(/\.0$/, "")
      _INTL("Below 30% HP, damage taken -{1}%.", reduction)
    when :reserve then _INTL("Once per room, recover {1}% Burst charge after it ends.", 5 * rank)
    else _INTL(data[:desc])
    end
  end

  def breach_module_rank_label(rank)
    rank.to_i >= 3 ? _INTL("MAX 3/3") : _INTL("Rank {1}/3", rank)
  end

  def breach_module_inventory_menu(equipped)
    loop do
      list = equipped ? @breach_modules : @breach_inventory
      return if list.empty?
      entries = list.map do |item|
        id = equipped ? item[:id] : item
        rank = equipped ? item[:rank] : 1
        status = if equipped
                   _INTL("Equipped | {1}", breach_module_rank_label(rank))
                 elsif breach_module_rank(id) > 0
                   _INTL("Owned: {1}", breach_module_rank_label(breach_module_rank(id)))
                 else
                   _INTL("In reserve")
                 end
        [breach_module_name(id), breach_module_effect_text(id, rank), status, true, id]
      end
      pick = breach_card_choose(equipped ? _INTL("Equipped Modules") : _INTL("Module Reserve"), entries)
      return if pick.nil?
      id = equipped ? list[pick][:id] : list[pick]
      rank = equipped ? list[pick][:rank] : 1
      amount = breach_module_sale_value(equipped, pick)
      actions = []
      unless equipped
        owned = breach_module_rank(id)
        if owned < 3
          actions << [owned > 0 ? _INTL("Fuse Module") : _INTL("Equip Module"), breach_module_effect_text(id, owned + 1), breach_module_rank_label(owned + 1), true, id]
        end
      end
      actions << [_INTL("Sell Module"), equipped ? _INTL("Remove this module and lose its active effect.") : _INTL("Sell this stored module. Equipped effects are unchanged."), _INTL("{1} Shards", amount), true, :treasure]
      action = breach_card_choose(breach_module_name(id), actions) do |selected|
        if selected == actions.length - 1
          message = _INTL("Sell {1} for {2} Shards?", breach_module_name(id), amount)
          message += "\n" + _INTL("Lose: {1}", breach_module_effect_text(id, rank)) if equipped
          pbConfirmMessage(message)
        else
          true
        end
      end
      next if action.nil?
      if action == actions.length - 1
        breach_sell_module(equipped, pick)
      else
        replace = nil
        if @breach_modules.length >= 6 && breach_module_rank(id) == 0
          replace = breach_card_choose(_INTL("Replace a module"), @breach_modules.map do |entry|
            [breach_module_name(entry[:id]), breach_module_effect_text(entry[:id], entry[:rank]), breach_module_rank_label(entry[:rank]), true, entry[:id]]
          end)
          next if replace.nil?
          old = @breach_modules[replace]
          next unless pbConfirmMessage(_INTL("Lose: {1}\nGain: {2}\nRecover {3} Shards?", breach_module_effect_text(old[:id], old[:rank]), breach_module_effect_text(id, 1), 20 * old[:rank]))
        end
        breach_install_module(pick, replace)
      end
    end
  end

  def breach_result_menu
    old_index = @breach_result_index.to_i
    @breach_result_index = (@breach_result_index.to_i - 1) % 3 if Input.repeat?(Input::LEFT)
    @breach_result_index = (@breach_result_index.to_i + 1) % 3 if Input.repeat?(Input::RIGHT)
    pbPlayCursorSE if old_index != @breach_result_index.to_i
    draw_gameover
    @seasonal_result_ready = true unless PokemonSurvivor.control_press?(:confirm) || PokemonSurvivor.control_press?(:cancel)
    return unless @seasonal_result_ready
    choice = survivor_cancel_triggered? ? 2 : (survivor_confirm_triggered? ? @breach_result_index.to_i : nil)
    return if choice.nil?
    @seasonal_result_ready = false
    case choice
    when 0
      quests = @breach_quests
      breach_rewards_menu(@breach_season, quests) if quests
    when 1
      return if @leaderboard_submitted
      return unless leaderboard_share_eligible?
      payload = { action: "submit", session_id: @breach_session,
        rooms: @breach_rooms, level: @level, run_time_seconds: @timer.to_i,
        ruleset: PokemonSurvivor::BREACH_RULESET, hard_rooms: @breach_hard_rooms, unfair_rooms: @breach_unfair_rooms }
      queued_id = PokemonSurvivor.online_enqueue_submission(:breach, payload)
      unless queued_id
        pbMessage(_INTL("Your score could not be saved. Please try again."))
        return
      end
      entry = PokemonSurvivor.online_submission_queue[queued_id]
      result = "QUEUED"
      if entry[:status] == :rejected
        result = entry[:response].to_s
      elsif entry[:next_try].to_i <= Time.now.to_i
        result = breach_wait(_INTL("Sending score...")) { PokemonSurvivor.breach_online_action(entry[:payload]) }.to_s
        PokemonSurvivor.online_finish_submission(queued_id, result)
        result = "QUEUED" unless result == "OK" || PokemonSurvivor.online_submission_rejected?(result)
      end
      @leaderboard_submitted = ["OK", "QUEUED"].include?(result)
      message = if result == "OK"
                  _INTL("Score sent!")
                elsif result == "QUEUED"
                  _INTL("Score saved for automatic sending when the connection is available.")
                else
                  _INTL("Score not sent. Check your connection; the season may have ended.")
                end
      pbMessage(message)
    else
      breach_screen_transition do
        @breach_run = false
        return_to_select_menu
        breach_wait(_INTL("Checking the season...")) { PokemonSurvivor.breach_refresh_season }
        refresh_breach_slot
        draw_select
      end
    end
  end
end

Scene_PokemonSurvivor.prepend(SurvivorBreachRun) unless Scene_PokemonSurvivor.ancestors.include?(SurvivorBreachRun)
Scene_PokemonSurvivor.prepend(SurvivorBreachMenus) unless Scene_PokemonSurvivor.ancestors.include?(SurvivorBreachMenus)
