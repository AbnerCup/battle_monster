#===============================================================================
# Pokemon Survivor - Scene shell, selection menu, leaderboard
#===============================================================================

class Scene_PokemonSurvivor
  include PokemonSurvivor

  def initialize
    PokemonSurvivor.apply_retroactive_unlocks_on_menu_open if PokemonSurvivor.respond_to?(:apply_retroactive_unlocks_on_menu_open)
    @heroes = PokemonSurvivor.hero_names.select { |name| PokemonSurvivor::BASE_HERO_KEYS.include?(PokemonSurvivor.species_key(name)) }
    if PokemonSurvivor.const_defined?(:BATTLE_PASS_SLOT_KEY) && PokemonSurvivor.respond_to?(:battle_pass_slot_unlocked?) && PokemonSurvivor.battle_pass_slot_unlocked? && !@heroes.include?(PokemonSurvivor::BATTLE_PASS_SLOT_KEY)
      @heroes.unshift(PokemonSurvivor::BATTLE_PASS_SLOT_KEY)
    end
    @hero_index = 0
    @hero_scroll_row = 0
    @state = :select
    @select_focus = :heroes
    @sprites = {}
    @bitmaps = {}
    @leaderboard_sort = :score
    @leaderboard_pokemon_filter = nil
  end

  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites["screen"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSEPlay("Survivor/GUI menu open", PokemonSurvivor::UI_MENU_VOLUME, 100) rescue nil
    play_survivor_menu_bgm
    draw_select
  end

  def pbMain
    @last_time = System.uptime rescue 0
    @accumulator = 0.0
    loop do
      Graphics.update
      Input.update
      now = System.uptime rescue (@last_time + PokemonSurvivor::STEP_DT)
      PokemonSurvivor.online_retry_tick(true) if [:select, :select_menu, :gameover, :leaderboard].include?(@state)
      frame_dt = [[now - @last_time, 0.0].max, 0.12].min
      @last_time = now
      run_bonus_panel_toggled = false
      if @state == :play && run_bonus_panel_triggered?
        toggle_run_bonus_panel
        run_bonus_panel_toggled = true
      end
      update_run_view_zoom_input if @state == :play && respond_to?(:update_run_view_zoom_input)
      update_hitbox_debug_toggle if @state == :play && respond_to?(:update_hitbox_debug_toggle)
      update_run_speed_input(frame_dt) if @state == :play
      capture_ultimate_action_input if @state == :play && !run_bonus_panel_toggled
      case @state
      when :select
        update_select
      when :mode_select
        update_mode_select
      when :select_menu
        update_select_menu
      when :leaderboard
        update_leaderboard
      when :leaderboard_filter
        update_leaderboard_filter
      when :shop
        update_shop
      when :pokemon_training
        update_pokemon_training
      when :equipment_menu
        update_pokemon_equipment_menu if respond_to?(:update_pokemon_equipment_menu)
      when :perf_options
        update_performance_options
      when :control_options
        update_control_options if respond_to?(:update_control_options)
      when :play
        if !@evolution_anim && (survivor_cancel_triggered?)
          open_pause
          next
        end
        @accumulator += frame_dt * run_speed_multiplier
        steps = 0
        max_steps = (PokemonSurvivor::MAX_STEPS_FRAME * run_speed_multiplier).ceil
        while @accumulator >= PokemonSurvivor::STEP_DT && steps < max_steps
          update_game(PokemonSurvivor::STEP_DT)
          @accumulator -= PokemonSurvivor::STEP_DT
          steps += 1
          break if @state != :play
        end
        draw_game if @state == :play
      when :upgrade
        update_upgrade
      when :baby_choice
        update_baby_choice
      when :sleep_reward
        update_sleep_reward
      when :joker_choice
        update_joker_choice if respond_to?(:update_joker_choice)
      when :pause
        update_pause
      when :gameover
        update_gameover
      end
    end
  end

  def reset_run_speed_state(hero_name = nil, mode = nil)
    @run_speed_index = 0
    @run_speed_notice_timer = 0.0
    @run_speed_available = false
    if hero_name && !@breach_run
      @run_speed_available = case mode
                            when :classic then Array(PokemonSurvivor.survivor_progress[:survived_15]).any?
                            when :rush then Array(PokemonSurvivor.survivor_progress[:rush_finished]).any?
                            when :tower then Array(PokemonSurvivor.survivor_progress[:tower_finished]).any?
                            when :endless then PokemonSurvivor.shop_tree_complete?(:standard)
                            else false
                            end
    end
    @run_speed_hint_timer = @run_speed_available ? 10.0 : 0.0
  end

  def run_speed_available?
    @run_speed_available && !@breach_run && @run_mode != :breach
  end

  def run_speed_multiplier
    run_speed_available? ? 1.0 + @run_speed_index.to_i : 1.0
  end

  # Read input once per displayed frame, not once per accelerated simulation step.
  def update_run_speed_input(real_dt)
    @run_speed_notice_timer = [@run_speed_notice_timer.to_f - real_dt, 0.0].max
    @run_speed_hint_timer = [@run_speed_hint_timer.to_f - real_dt, 0.0].max
    return unless @state == :play && run_speed_available? && !@evolution_anim
    faster = PokemonSurvivor.control_trigger?(:speed_up)
    slower = PokemonSurvivor.control_trigger?(:speed_down)
    return if faster == slower
    previous = @run_speed_index.to_i
    @run_speed_index = [[previous + (faster ? 1 : -1), 0].max, 2].min
    return if previous == @run_speed_index
    @run_speed_notice_timer = 3.0
    @run_speed_hint_timer = 0.0
  end

  def pbEndScene
    clear_transient_run_state if respond_to?(:clear_transient_run_state)
    pbSEPlay("Survivor/GUI menu close", PokemonSurvivor::UI_MENU_VOLUME, 100) rescue nil
    stop_survivor_bgm
    dispose_survivor_bitmap_caches
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose if @viewport && !@viewport.disposed?
  end

  def dispose_survivor_cached_bitmap(bitmap)
    return unless bitmap && bitmap.respond_to?(:disposed?) && bitmap.respond_to?(:dispose)
    PokemonSurvivor.unregister_eight_direction_bitmap(bitmap)
    bitmap.dispose unless bitmap.disposed?
  end

  def dispose_survivor_bitmap_caches
    [
      :@bitmaps,
      :@scroll_text_cache,
      :@leaderboard_rainbow_text_cache,
      :@shop_text_cache,
      :@shop_scrolling_text_cache,
      :@shop_description_cache,
      :@shop_upgrade_cost_cache,
      :@battle_pass_scroll_cache,
      :@achievement_text_cache,
      :@select_hero_slot_cache,
      :@shop_background_surface_cache,
      :@shop_monochrome_cache,
      :@shop_mirrored_cache,
      :@ui_single_line_text_cache,
      :@ui_wrapped_text_cache,
      :@upgrade_pokemon_icon_cache,
      :@leaderboard_pokemon_icon_cache,
      :@focus_step_cooldown_cache,
      :@event_sleep_wake_zone_cache,
      :@event_egg_activation_circle_cache,
      :@tower_objective_zone_cache,
      :@joker_title_cache,
      :@candy_exchange_text_cache
    ].each do |ivar|
      cache = instance_variable_get(ivar) rescue nil
      next if !cache.respond_to?(:each_value)
      cache.each_value { |bmp| dispose_survivor_cached_bitmap(bmp) }
      cache.clear rescue nil
    end
    [:@shop_static_tree_cache, :@run_bonus_panel_surface, :@achievement_backdrop].each do |ivar|
      bitmap = instance_variable_get(ivar)
      dispose_survivor_cached_bitmap(bitmap)
      instance_variable_set(ivar, nil)
    end
    PokemonSurvivor.clear_tinted_character_cache
    @shop_static_tree_cache_key = nil
    @tower_boss_pattern_timers = {}
    @enemy_grid = @enemy_grid_storage = nil
    @enemy_grid_row_pool = []
    @enemy_grid_bucket_pool = []
  end

  def selected_hero_name
    @heroes[@hero_index] || @heroes[0] || "BULBASAUR"
  end

  def try_password_unlock_for_selected_hero
    name = PokemonSurvivor.species_key(selected_hero_name)
    password = PokemonSurvivor::HERO_UNLOCK_PASSWORDS[name]
    return false if !password
    entered = PokemonSurvivor.password_text_input(_INTL("Enter {1} password.", PokemonSurvivor.species_name(name)), password.length, "")
    if entered.to_s.strip.upcase == password
      if PokemonSurvivor.unlock_hero(name)
        pbPlayDecisionSE rescue nil
        pbMessage(_INTL("{1} unlocked!", PokemonSurvivor.species_name(name))) rescue nil
        save_password_unlock_progress
      else
        pbPlayDecisionSE rescue nil
        pbMessage(_INTL("{1} is already unlocked.", PokemonSurvivor.species_name(name))) rescue nil
      end
      @confirming_hero = false
      draw_select
      return true
    end
    pbPlayBuzzerSE rescue nil
    pbMessage(_INTL("Wrong password.")) rescue nil
    draw_select
    false
  rescue
    false
  end

  def save_password_unlock_progress
    if defined?(pbSaveScreen)
      pbSaveScreen
    elsif defined?(PokemonSaveScreen)
      PokemonSaveScreen.new.pbSaveScreen
    end
  rescue
  end

  def update_select
    return if update_prestige_visual_hold
    if @select_focus != :shop && respond_to?(:battle_pass_slot_key?) && battle_pass_slot_key?(selected_hero_name)
      @confirming_hero = false
      if select_action_triggered? || survivor_confirm_triggered?
        open_battle_pass_menu if respond_to?(:open_battle_pass_menu)
        return
      end
    end
    if select_action_triggered? && !@confirming_hero
      open_survivor_save_menu
      draw_select
      return
    end
    if @confirming_hero
      if select_leaderboard_triggered? && PokemonSurvivor.respond_to?(:pokemon_equipment_slot_unlocked?) && PokemonSurvivor.pokemon_equipment_slot_unlocked?(selected_hero_name) && respond_to?(:open_pokemon_equipment_menu)
        open_pokemon_equipment_menu(selected_hero_name)
        return
      elsif select_action_triggered? && PokemonSurvivor.hero_unlocked?(selected_hero_name) && respond_to?(:open_or_toggle_pokemon_training)
        open_or_toggle_pokemon_training(selected_hero_name)
        return
      elsif survivor_confirm_triggered?
        if PokemonSurvivor.hero_unlocked?(selected_hero_name)
          open_mode_select(selected_hero_name)
        else
          try_password_unlock_for_selected_hero
        end
        return
      elsif select_back_triggered?
        @confirming_hero = false
        pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
      end
      draw_select
      return
    end
    old = @hero_index
    old_scroll = @hero_scroll_row
    old_focus = @select_focus || :heroes
    cols = select_grid_columns
    if @select_focus == :shop
      if Input.repeat?(Input::DOWN) || Input.repeat?(Input::LEFT) || Input.repeat?(Input::RIGHT)
        @select_focus = :heroes
      end
    else
      @select_focus = :heroes
      if Input.repeat?(Input::UP)
        if @hero_index.to_i - cols >= 0
          @hero_index -= cols
        else
          @select_focus = :shop
        end
      else
        @hero_index -= 1 if Input.repeat?(Input::LEFT)
        @hero_index += 1 if Input.repeat?(Input::RIGHT)
        @hero_index += cols if Input.repeat?(Input::DOWN)
      end
    end
    @hero_index = 0 if @hero_index < 0
    @hero_index = @heroes.length - 1 if @hero_index >= @heroes.length
    ensure_select_scroll
    pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil if old != @hero_index || old_scroll != @hero_scroll_row || old_focus != @select_focus
    draw_select
    if @select_focus != :shop && defined?(PokemonSurvivor::BREACH_SLOT_KEY) && selected_hero_name == PokemonSurvivor::BREACH_SLOT_KEY && survivor_confirm_triggered?
      @confirming_hero = false
      return if respond_to?(:breach_initial_check_pending?) && breach_initial_check_pending?
      breach_open_season
      return
    end
    if @select_focus != :shop && respond_to?(:battle_pass_slot_key?) && battle_pass_slot_key?(selected_hero_name) && (survivor_confirm_triggered?)
      @confirming_hero = false
      open_battle_pass_menu if respond_to?(:open_battle_pass_menu)
      return
    end
    if survivor_confirm_triggered?
      if @select_focus == :shop
        open_shop
      else
        @confirming_hero = true
        pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
        draw_select
      end
    elsif select_shop_triggered?
      open_shop
    elsif select_leaderboard_triggered?
      open_leaderboard
    elsif select_performance_triggered?
      open_select_menu
    end
  end
  def select_action_triggered?
    return PokemonSurvivor.control_trigger?(:action) if PokemonSurvivor.respond_to?(:control_trigger?)
    return true if Input.const_defined?(:ACTION) && Input.trigger?(Input::ACTION)
    false
  rescue
    false
  end

  def select_leaderboard_triggered?
    return PokemonSurvivor.control_trigger?(:menu) if PokemonSurvivor.respond_to?(:control_trigger?)
    return true if Input.const_defined?(:SPECIAL) && Input.trigger?(Input::SPECIAL)
    return true if Input.const_defined?(:MENU) && Input.const_defined?(:ACTION) && Input::MENU != Input::ACTION && Input.trigger?(Input::MENU)
    false
  rescue
    false
  end

  def select_back_triggered?
    return PokemonSurvivor.control_trigger?(:cancel) if PokemonSurvivor.respond_to?(:control_trigger?)
    return true if Input.const_defined?(:BACK) && Input.trigger?(Input::BACK)
    return true if Input.const_defined?(:B) && Input.trigger?(Input::B)
    return true if Input.const_defined?(:ESC) && Input.trigger?(Input::ESC)
    false
  rescue
    false
  end

  def select_performance_triggered?
    return PokemonSurvivor.control_trigger?(:cancel) if PokemonSurvivor.respond_to?(:control_trigger?)
    return true if Input.const_defined?(:BACK) && Input.trigger?(Input::BACK)
    false
  rescue
    false
  end

  PERFORMANCE_OPTION_ITEMS = [
    [:screen_size, "Screen Size", :screen],
    [:bgm_volume, "Music Volume", :volume],
    [:se_volume, "SFX Volume", :volume],
    [:tv_filter, "CRT Filter", :toggle],
    [:color_accessibility, "Color Accessibility", :choice],
    [:reduced_vfx, "Reduced VFX", :toggle],
    [:reinforced_hp_bars, "Enemy HP Bars", :toggle],
    [:run_info_panel, "Run Info Panel", :choice],
    [:auto_bonus, "Auto Bonuses", :choice],
    [:controls, "Controls", :action],
    [:website, "Website", :action],
    [:discord, "Discord", :action]
  ]

  SELECT_MENU_ITEMS = [
    [:achievements, "Achievements"],
    [:options, "Options"],
    [:save, "Save"],
    [:quit, "Quit Game"],
    [:cancel, "Cancel"]
  ]

  def open_select_menu
    @select_menu_index ||= 0
    @state = :select_menu
    pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    draw_select_menu
  rescue
  end

  def close_select_menu
    @state = :select
    @select_menu_index = 0
    pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
    draw_select
  rescue
  end

  def update_select_menu
    old = @select_menu_index.to_i
    @select_menu_index = (@select_menu_index.to_i - 1) % SELECT_MENU_ITEMS.length if Input.repeat?(Input::UP)
    @select_menu_index = (@select_menu_index.to_i + 1) % SELECT_MENU_ITEMS.length if Input.repeat?(Input::DOWN)
    pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil if old != @select_menu_index.to_i
    if survivor_confirm_triggered?
      case SELECT_MENU_ITEMS[@select_menu_index.to_i][0]
      when :achievements
        if respond_to?(:open_achievements)
          open_achievements
        else
          pbPlayBuzzerSE rescue nil
          draw_select_menu
        end
      when :options
        open_performance_options
      when :save
        open_survivor_save_menu
        draw_select_menu
      when :quit
        quit_survivor_game
      else
        close_select_menu
      end
      return
    elsif select_back_triggered?
      close_select_menu
      return
    end
    draw_select_menu
  rescue
    close_select_menu
  end

  def draw_select_menu
    draw_select
    bmp = @sprites["screen"].bitmap
    over = @sprites["overlay"].bitmap
    over.clear
    draw_options_scrolling_background(bmp)
    w = [Graphics.width - 96, 318].min
    h = 320
    x = (Graphics.width - w) / 2
    y = (Graphics.height - h) / 2
    draw_panel(bmp, x, y, w, h, Color.new(92, 188, 255), Color.new(18, 29, 50))
    draw_pixel_round_rect(bmp, x + 14, y + 12, w - 28, 32, Color.new(8, 13, 26, 188))
    PokemonSurvivor.draw_text_center(bmp, _INTL("Menu"), x + 18, y + 18, w - 36, Color.new(255, 238, 160))
    SELECT_MENU_ITEMS.each_with_index do |item, i|
      draw_select_menu_button(bmp, x + 34, y + 60 + (i * 50), w - 68, 42, _INTL(item[1]), @select_menu_index.to_i == i, i)
      draw_menu_notification(bmp, x + 34, y + 60 + (i * 50)) if item[0] == :achievements && achievements_notification?
    end
    draw_help(over, [[:up, ""], [:down, _INTL("Select")], [:confirm, _INTL("Confirm")], [:cancel, _INTL("Back")]])
    draw_tv_filter(over)
  rescue
  end

  def draw_select_menu_button(bitmap, x, y, w, h, label, selected, index = 0)
    palettes = [
      [Color.new(255, 196, 86), Color.new(62, 42, 24), Color.new(255, 232, 140)],
      [Color.new(84, 126, 184), Color.new(28, 48, 78), Color.new(150, 192, 255)],
      [Color.new(82, 178, 118), Color.new(26, 62, 42), Color.new(154, 238, 174)],
      [Color.new(206, 82, 160), Color.new(76, 24, 64), Color.new(255, 154, 220)],
      [Color.new(176, 72, 76), Color.new(68, 28, 36), Color.new(255, 142, 132)]
    ]
    edge, fill, shine = palettes[index.to_i] || palettes[0]
    if selected
      fill = Color.new([fill.red + 34, 255].min, [fill.green + 34, 255].min, [fill.blue + 34, 255].min)
      shine = Color.new([shine.red + 22, 255].min, [shine.green + 22, 255].min, [shine.blue + 22, 255].min)
    end
    draw_modern_button_frame(bitmap, x, y, w, h, edge, fill, shine, selected)
    PokemonSurvivor.draw_text_center(bitmap, label, x + 10, y + 11, w - 20, Color.new(226, 232, 244), Color.new(30, 30, 38))
  rescue
  end

  def quit_survivor_game
    if defined?(pbConfirmMessage) && !pbConfirmMessage(_INTL("Quit the game?"))
      draw_select_menu
      return
    end
    pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCloseMenuSE rescue nil
    pbDisposeSpriteHash(@sprites) rescue nil
    @sprites = {}
    @state = :quit
    $scene = nil
    Kernel.exit
  rescue SystemExit
    raise
  rescue
    $scene = nil
  end

  def open_performance_options
    @state = :perf_options
    @perf_option_index ||= 0
    pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    play_survivor_bgm_name(PokemonSurvivor::OPTIONS_BGM) if respond_to?(:play_survivor_bgm_name)
    draw_performance_options
  rescue
  end

  def close_performance_options
    @state = :select_menu
    @select_menu_index ||= 1
    pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
    play_survivor_menu_bgm if respond_to?(:play_survivor_menu_bgm)
    draw_select_menu
  rescue
    @state = :select
    draw_select rescue nil
  end


  def update_performance_options
    old = @perf_option_index.to_i
    @perf_option_index = (@perf_option_index.to_i - 1) % PERFORMANCE_OPTION_ITEMS.length if Input.repeat?(Input::UP)
    @perf_option_index = (@perf_option_index.to_i + 1) % PERFORMANCE_OPTION_ITEMS.length if Input.repeat?(Input::DOWN)
    if old != @perf_option_index.to_i
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
    end
    item = PERFORMANCE_OPTION_ITEMS[@perf_option_index.to_i]
    if Input.repeat?(Input::LEFT)
      change_performance_option(item, -1)
    elsif Input.repeat?(Input::RIGHT)
      change_performance_option(item, 1)
    elsif survivor_confirm_triggered?
      activate_performance_option(item)
    elsif select_back_triggered?
      close_performance_options
      return
    end
    draw_performance_options
  rescue
    close_performance_options
  end

  def performance_visible_rows

    5
  end

  def ensure_performance_scroll
    @perf_scroll_index ||= 0
    visible = performance_visible_rows
    index = @perf_option_index.to_i
    @perf_scroll_index = index if index < @perf_scroll_index
    bottom = @perf_scroll_index + visible - 1
    @perf_scroll_index = index - visible + 1 if index > bottom
    max_scroll = [PERFORMANCE_OPTION_ITEMS.length - visible, 0].max
    @perf_scroll_index = [[@perf_scroll_index, 0].max, max_scroll].min
  rescue
    @perf_scroll_index = 0
  end
  def activate_performance_option(item)
    key = item[0]
    case item[2]
    when :toggle
      PokemonSurvivor.toggle_performance_option(item[0])
      pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    when :screen, :choice
      change_performance_option(item, 1)
    when :action
      case key
      when :controls
        open_control_options if respond_to?(:open_control_options)
      when :website
        open_survivor_website
      when :discord
        open_survivor_discord
      else
        pbPlayBuzzerSE
      end
    else
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
    end
  rescue
  end

  def change_performance_option(item, dir)
    key = item[0]
    case item[2]
    when :toggle
      PokemonSurvivor.toggle_performance_option(key)
      pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    when :screen
      count = PokemonSurvivor::SCREEN_SIZE_LABELS.length
      PokemonSurvivor.set_screen_size_index((PokemonSurvivor.screen_size_index + dir.to_i) % count)
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
    when :choice
      if key == :color_accessibility
        PokemonSurvivor.cycle_color_accessibility(dir.to_i)
        invalidate_color_accessibility_surfaces
      elsif key == :auto_bonus
        PokemonSurvivor.cycle_auto_bonus_mode(dir.to_i)
      else
        PokemonSurvivor.cycle_run_info_panel_mode(dir.to_i)
      end
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
    when :volume
      if key == :bgm_volume
        PokemonSurvivor.set_bgm_volume(PokemonSurvivor.bgm_volume + (dir.to_i * 5))
        replay_survivor_current_bgm
      elsif key == :se_volume
        PokemonSurvivor.set_se_volume(PokemonSurvivor.se_volume + (dir.to_i * 5))
        pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
      end
    end
  rescue
  end

  def replay_survivor_current_bgm
    bgm = @survivor_current_bgm
    return if !bgm || bgm.to_s.empty?
    @survivor_current_bgm = nil
    play_survivor_bgm_name(bgm)
  rescue
  end

  def open_survivor_website
    url = "https://drchips.fr/leaderboard-SB/"
    pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    platform = (System.platform rescue "")
    if platform[/Windows/i]
      system("cmd /c start \"\" \"#{url}\"")
    elsif platform[/Mac/i]
      system("open", url)
    else
      system("xdg-open", url)
    end
  rescue
    pbMessage(_INTL("Unable to open the website.")) rescue nil
  end
  def open_survivor_discord
    url = PokemonSurvivor::DISCORD_INVITE_URL
    pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    platform = (System.platform rescue "")
    if platform[/Windows/i]
      system("cmd /c start \"\" \"#{url}\"")
    elsif platform[/Mac/i]
      system("open", url)
    else
      system("xdg-open", url)
    end
  rescue
    pbMessage(_INTL("Unable to open the Discord page.")) rescue nil
  end

  def performance_option_value(item)
    key = item[0]
    case item[2]
    when :toggle
      PokemonSurvivor.performance_option?(key) ? _INTL("On") : _INTL("Off")
    when :screen
      PokemonSurvivor::SCREEN_SIZE_LABELS[PokemonSurvivor.screen_size_index] || "M"
    when :volume
      key == :bgm_volume ? _INTL("{1}%", PokemonSurvivor.bgm_volume) : _INTL("{1}%", PokemonSurvivor.se_volume)
    when :choice
      return PokemonSurvivor.color_accessibility_label if key == :color_accessibility
      key == :auto_bonus ? PokemonSurvivor.auto_bonus_label : PokemonSurvivor.run_info_panel_label
    when :action
      case key
      when :controls then _INTL("Controls")
      when :website then _INTL("Website")
      else _INTL("Discord")
      end
    else
      ""
    end
  rescue
    ""
  end

  def draw_performance_volume_bar(bitmap, x, y, w, h, rate, color)
    rate = [[rate.to_f, 0.0].max, 1.0].min
    bitmap.fill_rect(x, y, w, h, Color.new(3, 6, 13))
    bitmap.fill_rect(x + 1, y + 1, w - 2, h - 2, Color.new(46, 58, 82))
    bitmap.fill_rect(x + 2, y + 2, w - 4, h - 4, Color.new(16, 22, 34))
    fill_w = ((w - 4) * rate).round
    light = Color.new([color.red + 52, 255].min, [color.green + 52, 255].min, [color.blue + 52, 255].min)
    dark = Color.new([color.red - 46, 0].max, [color.green - 46, 0].max, [color.blue - 46, 0].max)
    if fill_w > 0
      bitmap.fill_rect(x + 2, y + 2, fill_w, h - 4, color)
      bitmap.fill_rect(x + 3, y + 3, [fill_w - 2, 0].max, 2, light)
      bitmap.fill_rect(x + 3, y + h - 4, [fill_w - 2, 0].max, 1, dark)
    end
    step = (w - 4) / 10.0
    empty_mark = Color.new(38, 50, 72)
    1.upto(9) do |i|
      sx = x + 2 + (step * i).round
      mark_color = sx < x + 2 + fill_w ? light : empty_mark
      bitmap.fill_rect(sx, y + 3, 1, [h - 6, 1].max, mark_color)
    end
    knob_x = x + 2 + fill_w
    knob_x = [[knob_x, x + 4].max, x + w - 5].min
    bitmap.fill_rect(knob_x - 2, y - 2, 5, h + 4, Color.new(3, 6, 13))
    bitmap.fill_rect(knob_x - 1, y - 1, 3, h + 2, Color.new(255, 238, 160))
    bitmap.fill_rect(knob_x, y, 1, h, Color.new(255, 255, 220))
  rescue
  end
  def draw_performance_option_button(bitmap, x, y, w, h, item, label, value, selected, index)
    key = item[0]
    palettes = {
      screen_size: [Color.new(84, 126, 184), Color.new(28, 48, 78), Color.new(150, 192, 255)],
      bgm_volume: [Color.new(78, 150, 166), Color.new(24, 58, 70), Color.new(146, 232, 244)],
      se_volume: [Color.new(88, 164, 118), Color.new(28, 68, 48), Color.new(156, 246, 188)],
      tv_filter: [Color.new(86, 126, 154), Color.new(30, 48, 66), Color.new(156, 204, 232)],
      color_accessibility: [Color.new(218, 128, 166), Color.new(70, 34, 52), Color.new(255, 192, 218)],
      reduced_vfx: [Color.new(176, 118, 64), Color.new(70, 44, 28), Color.new(255, 204, 126)],
      reinforced_hp_bars: [Color.new(176, 72, 76), Color.new(68, 28, 36), Color.new(255, 142, 132)],
      run_info_panel: [Color.new(82, 154, 206), Color.new(24, 54, 82), Color.new(154, 220, 255)],
      auto_bonus: [Color.new(202, 160, 64), Color.new(70, 54, 24), Color.new(255, 224, 134)],
      controls: [Color.new(64, 214, 204), Color.new(18, 70, 76), Color.new(132, 255, 246)],
      website: [Color.new(72, 176, 142), Color.new(22, 66, 56), Color.new(142, 246, 210)],
      discord: [Color.new(142, 96, 190), Color.new(48, 34, 78), Color.new(214, 166, 255)]
    }
    edge, fill, shine = palettes[key] || [Color.new(84, 126, 184), Color.new(28, 48, 78), Color.new(150, 192, 255)]
    enabled = true
    if !enabled
      edge = Color.new(82, 88, 104)
      fill = Color.new(28, 32, 42)
      shine = Color.new(116, 124, 142)
    elsif selected
      fill = Color.new([fill.red + 34, 255].min, [fill.green + 34, 255].min, [fill.blue + 34, 255].min)
      shine = Color.new([shine.red + 22, 255].min, [shine.green + 22, 255].min, [shine.blue + 22, 255].min)
    end
    text_color = enabled ? Color.new(226, 232, 244) : Color.new(154, 160, 176)
    shadow = Color.new(30, 30, 38)
    draw_modern_button_frame(bitmap, x, y, w, h, edge, fill, shine, selected)
    type = item[2]
    if type == :action
      PokemonSurvivor.draw_text_center(bitmap, value, x + 10, y + ((h - 20) / 2), w - 20, text_color, shadow)
      return
    end
    text_y = y + ((h - 20) / 2)
    if key == :color_accessibility
      value_w = [210, w - 154].min
      value_x = x + w - 24 - value_w
      draw_battle_pass_scrolling_text(bitmap, label, x + 14, text_y, value_x - x - 24, 20, text_color, shadow)
      pbSetSystemFont(bitmap)
      text_w = bitmap.text_size(value.to_s).width
      if text_w <= 78
        PokemonSurvivor.draw_text_center(bitmap, value, x + w - 102, text_y, 78, shine, shadow)
      elsif text_w <= value_w
        draw_text_box(bitmap, value, x + w - 24 - text_w, text_y, text_w, 20, shine, shadow, 0)
      else
        draw_battle_pass_scrolling_text(bitmap, value, value_x, text_y, value_w, 20, shine, shadow)
      end
      return
    end
    draw_text_box(bitmap, label, x + 14, text_y, w - 188, 20, text_color, shadow, 0)
    if type == :volume
      current = key == :bgm_volume ? PokemonSurvivor.bgm_volume : PokemonSurvivor.se_volume
      bar_x = x + w - 146
      bar_w = 88
      bar_h = 12
      bar_y = y + ((h - bar_h) / 2)
      draw_performance_volume_bar(bitmap, bar_x, bar_y, bar_w, bar_h, current.to_f / 100.0, shine)
      PokemonSurvivor.draw_text_center(bitmap, value, x + w - 54, text_y, 42, shine, shadow)
    else
      PokemonSurvivor.draw_text_center(bitmap, value, x + w - 102, text_y, 78, shine, shadow)
    end
  rescue
  end

  def draw_performance_options
    draw_select
    bmp = @sprites["screen"].bitmap
    over = @sprites["overlay"].bitmap
    over.clear
    w = [Graphics.width - 46, 486].min
    h = [Graphics.height - 82, 302].min
    x = (Graphics.width - w) / 2
    y = (Graphics.height - h) / 2
    draw_options_scrolling_background(bmp)
    draw_panel(bmp, x, y, w, h, Color.new(92, 188, 255), Color.new(18, 29, 50))
    draw_hud_header_strip(bmp, x + 14, y + 12, w - 28, 32, Color.new(92, 188, 255), Color.new(8, 13, 26))
    PokemonSurvivor.draw_text_center(bmp, _INTL("Performance Options"), x + 18, y + 23, w - 36, Color.new(255, 238, 160))
    row_h = 46
    first_y = y + 62
    visible = performance_visible_rows
    ensure_performance_scroll
    first = @perf_scroll_index.to_i
    last = [first + visible, PERFORMANCE_OPTION_ITEMS.length].min
    first.upto(last - 1) do |i|
      item = PERFORMANCE_OPTION_ITEMS[i]
      label = _INTL(item[1])
      selected = i == @perf_option_index.to_i
      row_y = first_y + ((i - first) * row_h)
      value = performance_option_value(item)
      draw_performance_option_button(bmp, x + 20, row_y, w - 58, 39, item, label, value, selected, i)
    end
    if PERFORMANCE_OPTION_ITEMS.length > visible
      bar_x = x + w - 27
      bar_y = first_y
      bar_h = (visible * row_h) - 7
      total = PERFORMANCE_OPTION_ITEMS.length
      thumb_h = [[(bar_h * visible / total).round, 18].max, bar_h].min
      max_scroll = [total - visible, 1].max
      thumb_y = bar_y + ((bar_h - thumb_h) * first / max_scroll)
      draw_select_scrollbar(bmp, bar_x, bar_y, 7, bar_h, thumb_y, thumb_h)
    end
    draw_help(over, [[:up, ""], [:down, _INTL("Select")], [:left, ""], [:right, _INTL("Change")], [:confirm, _INTL("Confirm")], [:cancel, _INTL("Back")]])
    draw_tv_filter(over)
  rescue
  end

  def open_survivor_save_menu
    pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    if defined?(pbSaveScreen)
      pbSaveScreen
    elsif defined?(PokemonSaveScreen)
      PokemonSaveScreen.new.pbSaveScreen
    else
      pbMessage(_INTL("Save is not available right now.")) rescue nil
    end
  rescue
    pbMessage(_INTL("Save is not available right now.")) rescue nil
  end

  def open_mode_select(hero_name)
    @mode_select_hero = hero_name
    @mode_select_index = 0
    @confirming_hero = false
    @state = :mode_select
    pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    play_survivor_cry(hero_name, 76, 100) if respond_to?(:play_survivor_cry)
    PokemonSurvivor.gamepad_vibrate_event(:pokemon_select) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
    draw_mode_select
  end

  def rush_mode_select_available?
    name = @mode_select_hero || selected_hero_name
    PokemonSurvivor.hero_finished?(name) && PokemonSurvivor.hero_boss_finished?(name)
  rescue
    false
  end

  def tower_mode_select_available?
    PokemonSurvivor.hero_rush_finished?(@mode_select_hero || selected_hero_name)
  rescue
    false
  end

  def endless_mode_select_available?
    PokemonSurvivor.shop_tree_complete?(:standard)
  rescue
    false
  end

  def update_mode_select
    if PokemonSurvivor.control_trigger?(:action)
      open_porygon_rigging
      return
    end
    old = @mode_select_index.to_i
    @mode_select_index = (@mode_select_index.to_i - 1) % 5 if Input.repeat?(Input::UP)
    @mode_select_index = (@mode_select_index.to_i + 1) % 5 if Input.repeat?(Input::DOWN)
    pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil if old != @mode_select_index.to_i
    if survivor_confirm_triggered?
      case @mode_select_index.to_i
      when 0
        start_porygon_configured_run(@mode_select_hero || selected_hero_name, :classic)
      when 1
        if rush_mode_select_available?
          start_porygon_configured_run(@mode_select_hero || selected_hero_name, :rush)
        else
          pbPlayBuzzerSE rescue nil
          pbMessage(_INTL("Clear Classic Mode with this Pokemon to unlock Rush Mode.")) rescue nil
          draw_mode_select
        end
      when 2
        if tower_mode_select_available?
          start_porygon_configured_run(@mode_select_hero || selected_hero_name, :tower)
        else
          pbPlayBuzzerSE rescue nil
          pbMessage(_INTL("Clear Rush Mode with this Pokemon to unlock Tower Mode.")) rescue nil
          draw_mode_select
        end
      when 3
        if endless_mode_select_available?
          start_porygon_configured_run(@mode_select_hero || selected_hero_name, :endless)
        else
          pbPlayBuzzerSE rescue nil
          pbMessage(_INTL("Complete Kecleon's Upgrade Shop to unlock Endless Mode.")) rescue nil
          draw_mode_select
        end
      else
        close_mode_select
      end
      return
    elsif select_back_triggered?
      close_mode_select
      return
    end
    draw_mode_select
  end

  def close_mode_select
    @state = :select
    @mode_select_hero = nil
    @mode_select_index = 0
    pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
    draw_select
  end

  def open_leaderboard
    if PokemonSurvivor.respond_to?(:leaderboard_version_allowed?) && !PokemonSurvivor.leaderboard_version_allowed?
      pbMessage(_INTL("Please update the game to view the leaderboard.")) rescue nil
      PokemonSurvivor.supabase_log_result(:leaderboard, "blocked_outdated_version local=#{PokemonSurvivor.leaderboard_local_version rescue "unknown"}") rescue nil
      return
    end
    return if !PokemonSurvivor.ensure_online_trainer_name(:leaderboard)
    @state = :leaderboard
    @leaderboard_mode ||= :classic
    @leaderboard_anim_time = 0.0
    @leaderboard_index ||= 0
    @leaderboard_scroll_row ||= 0
    @leaderboard_sort = :score
    @leaderboard_pokemon_filter ||= nil
    pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    play_survivor_bgm_name(@survivor_menu_bgm || PokemonSurvivor::LEADERBOARD_BGM)
    reload_leaderboard
  end

  def reload_leaderboard
    @leaderboard_entries = nil
    @leaderboard_error = nil
    @leaderboard_index = 0
    @leaderboard_scroll_row = 0
    draw_leaderboard(true)
    @leaderboard_entries = PokemonSurvivor.fetch_leaderboard_entries(@leaderboard_mode, PokemonSurvivor::LEADERBOARD_LIMIT, @leaderboard_sort, @leaderboard_pokemon_filter)
    @leaderboard_error = _INTL("Leaderboard unavailable.") if @leaderboard_entries.empty? && PokemonSurvivor.leaderboard_read_configured?
    @leaderboard_error = _INTL("Leaderboard is not configured.") if !PokemonSurvivor.leaderboard_read_configured?
    draw_leaderboard(false)
    @leaderboard_anim_time = 0.0
  rescue
    @leaderboard_entries = []
    @leaderboard_error = _INTL("Leaderboard unavailable.")
    draw_leaderboard(false) rescue nil
  end
  def update_leaderboard
    if Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)
      modes = [:classic, :rush, :tower, :endless]
      modes << :breach if PokemonSurvivor.respond_to?(:breach_current_season) && PokemonSurvivor.breach_current_season
      idx = modes.index(@leaderboard_mode) || 0
      @leaderboard_mode = modes[(idx + (Input.trigger?(Input::LEFT) ? -1 : 1)) % modes.length]
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue pbPlayCursorSE rescue nil
      reload_leaderboard
    elsif select_leaderboard_triggered?
      sorts = [:score, :level, :player]
      idx = sorts.index(@leaderboard_sort) || 0
      @leaderboard_sort = sorts[(idx + 1) % sorts.length]
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue pbPlayCursorSE rescue nil
      reload_leaderboard
    elsif select_action_triggered?
      open_leaderboard_filter
    elsif leaderboard_move_vertical
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue pbPlayCursorSE rescue nil
      draw_leaderboard(false)
    elsif survivor_confirm_triggered? && leaderboard_rank_reward_selected?
      claim_leaderboard_rank_reward
    elsif survivor_confirm_triggered? || select_back_triggered?
      @state = :select
      pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
      play_survivor_menu_bgm
      draw_select
    else
      now = System.uptime rescue 0.0
      @leaderboard_anim_time ||= 0.0
      if now - @leaderboard_anim_time >= 0.016
        @leaderboard_anim_time = now
        draw_leaderboard(false)
      end
    end
  end
  def leaderboard_filter_choices
    choices = PokemonSurvivor.hero_names.select { |name| PokemonSurvivor.hero_unlocked?(name) }
    [nil] + choices.map { |name| PokemonSurvivor.species_key(name).to_s }.uniq
  rescue
    [nil]
  end

  def open_leaderboard_filter
    choices = leaderboard_filter_choices
    current = @leaderboard_pokemon_filter ? PokemonSurvivor.species_key(@leaderboard_pokemon_filter).to_s : nil
    @leaderboard_filter_index = choices.index(current) || 0
    @leaderboard_filter_scroll = 0
    @state = :leaderboard_filter
    pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    draw_leaderboard_filter
  rescue
  end

  def update_leaderboard_filter
    choices = leaderboard_filter_choices
    old = @leaderboard_filter_index.to_i
    @leaderboard_filter_index -= 1 if Input.repeat?(Input::UP)
    @leaderboard_filter_index += 1 if Input.repeat?(Input::DOWN)
    @leaderboard_filter_index = 0 if @leaderboard_filter_index < 0
    @leaderboard_filter_index = choices.length - 1 if @leaderboard_filter_index >= choices.length
    ensure_leaderboard_filter_scroll(choices.length)
    pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue pbPlayCursorSE rescue nil if old != @leaderboard_filter_index.to_i
    if survivor_confirm_triggered?
      @leaderboard_pokemon_filter = choices[@leaderboard_filter_index.to_i]
      @leaderboard_pokemon_filter = nil if @leaderboard_pokemon_filter.to_s.empty?
      @state = :leaderboard
      pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
      reload_leaderboard
      return
    elsif select_back_triggered?
      @state = :leaderboard
      pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
      draw_leaderboard(false)
      return
    end
    draw_leaderboard_filter
  rescue
    @state = :leaderboard
    draw_leaderboard(false) rescue nil
  end

  def ensure_leaderboard_filter_scroll(total)
    visible = leaderboard_filter_visible_rows
    @leaderboard_filter_scroll ||= 0
    row = @leaderboard_filter_index.to_i
    @leaderboard_filter_scroll = row if row < @leaderboard_filter_scroll
    bottom = @leaderboard_filter_scroll + visible - 1
    @leaderboard_filter_scroll = row - visible + 1 if row > bottom
    max_scroll = [total.to_i - visible, 0].max
    @leaderboard_filter_scroll = [[@leaderboard_filter_scroll, 0].max, max_scroll].min
  rescue
    @leaderboard_filter_scroll = 0
  end

  def leaderboard_filter_visible_rows
    6
  end

  def draw_leaderboard_filter
    draw_leaderboard(false)
    bmp = @sprites["screen"].bitmap
    over = @sprites["overlay"].bitmap
    pbSetSystemFont(bmp)
    choices = leaderboard_filter_choices
    ensure_leaderboard_filter_scroll(choices.length)
    w = 344
    row_h = 42
    visible = [leaderboard_filter_visible_rows, choices.length].min
    h = 72 + (visible * row_h)
    x = (Graphics.width - w) / 2
    y = (Graphics.height - h) / 2
    draw_panel(bmp, x, y, w, h, Color.new(92, 188, 255), Color.new(18, 29, 50))
    PokemonSurvivor.draw_text_center(bmp, _INTL("Filter Pokemon"), x + 16, y + 21, w - 32, Color.new(255, 238, 160))
    first = @leaderboard_filter_scroll.to_i
    last = [first + visible, choices.length].min
    first.upto(last - 1) do |i|
      key = choices[i]
      label = key.to_s.empty? ? _INTL("All Pokemon") : PokemonSurvivor.leaderboard_pokemon_display_name(key)
      draw_leaderboard_filter_button(bmp, x + 24, y + 54 + ((i - first) * row_h), w - 56, 36, label, i == @leaderboard_filter_index.to_i, key)
    end
    if choices.length > visible
      bar_h = visible * row_h - 6
      thumb_h = [[(bar_h * visible / choices.length).round, 18].max, bar_h].min
      max_scroll = [choices.length - visible, 1].max
      thumb_y = y + 54 + ((bar_h - thumb_h) * first / max_scroll)
      draw_select_scrollbar(bmp, x + w - 23, y + 54, 7, bar_h, thumb_y, thumb_h)
    end
    over.clear
    draw_help(over, [[:up, ""], [:down, _INTL("Select")], [:confirm, _INTL("Confirm")], [:cancel, _INTL("Back")]])
    draw_tv_filter(over)
  rescue
  end

  def cached_leaderboard_pokemon_icon(key)
    folder = "#{PokemonSurvivor::ROOT}/Menu HUD/Leader Board/Pokemon Icons"
    @leaderboard_pokemon_icon_cache ||= {}
    candidates = key.to_s.empty? ? ["ALLPOKEMON"] : [key.to_s, PokemonSurvivor.species_key(key).to_s, key.to_s.upcase].uniq
    candidates.each do |name|
      cache_key = "#{folder}/#{name}"
      cached = @leaderboard_pokemon_icon_cache[cache_key]
      return cached if cached && !cached.disposed?
      bmp = PokemonSurvivor.load_bitmap(folder, name)
      if bmp && !bmp.disposed?
        @leaderboard_pokemon_icon_cache[cache_key] = bmp
        return bmp
      end
    end
    nil
  rescue
    nil
  end

  def leaderboard_filter_fallback_icon
    cached_icon_bitmap(mode_button_icon_name(0))
  rescue
    nil
  end

  def draw_leaderboard_filter_button(bitmap, x, y, w, h, label, selected, key)
    edge = Color.new(84, 126, 184)
    fill = Color.new(28, 48, 78)
    shine = Color.new(150, 192, 255)
    if selected
      fill = Color.new([fill.red + 34, 255].min, [fill.green + 34, 255].min, [fill.blue + 34, 255].min)
      shine = Color.new([shine.red + 22, 255].min, [shine.green + 22, 255].min, [shine.blue + 22, 255].min)
    end
    draw_modern_button_frame(bitmap, x, y, w, h, edge, fill, shine, selected)
    icon = cached_leaderboard_pokemon_icon(key) || leaderboard_filter_fallback_icon
    text_w = bitmap.text_size(label).width rescue (label.to_s.length * 8)
    if icon && !icon.disposed?
      icon_area = h - 8
      scale = [icon_area.to_f / [icon.width, icon.height].max, 1.0].min
      iw = [(icon.width * scale).round, 1].max
      ih = [(icon.height * scale).round, 1].max
      gap = 4
      max_text_w = [w - (iw * 2) - (gap * 2) - 28, 42].max
      text_w = [text_w, max_text_w].min
      group_w = (iw * 2) + (gap * 2) + text_w
      group_x = x + ((w - group_w) / 2)
      icon_y = y + ((h - ih) / 2)
      bitmap.stretch_blt(Rect.new(group_x, icon_y, iw, ih), icon, Rect.new(0, 0, icon.width, icon.height))
      bitmap.stretch_blt(Rect.new(group_x + iw + gap + text_w + gap, icon_y, iw, ih), icon, Rect.new(0, 0, icon.width, icon.height))
      PokemonSurvivor.draw_text_center(bitmap, label, group_x + iw + gap, y + ((h - 20) / 2), text_w, Color.new(226, 232, 244), Color.new(30, 30, 38))
    else
      PokemonSurvivor.draw_text_center(bitmap, label, x + 12, y + ((h - 20) / 2), w - 24, Color.new(226, 232, 244), Color.new(30, 30, 38))
    end
  rescue
    draw_mode_button(bitmap, x, y, w, h, label, selected, 0)
  end
  def leaderboard_sort_label
    return _INTL("My Runs") if @leaderboard_sort == :player
    @leaderboard_sort == :level ? _INTL("Level") : _INTL("Score")
  rescue
    _INTL("Score")
  end

  def leaderboard_filter_label
    return _INTL("All Pokemon") if @leaderboard_pokemon_filter.to_s.empty?
    PokemonSurvivor.leaderboard_pokemon_display_name(@leaderboard_pokemon_filter)
  rescue
    _INTL("All Pokemon")
  end
  def leaderboard_visible_rows
    7
  end

  def leaderboard_move_vertical
    rows = @leaderboard_entries || []
    return false if rows.empty?
    old = @leaderboard_index.to_i
    @leaderboard_index -= 1 if Input.repeat?(Input::UP)
    @leaderboard_index += 1 if Input.repeat?(Input::DOWN)
    @leaderboard_index = 0 if @leaderboard_index < 0
    @leaderboard_index = rows.length - 1 if @leaderboard_index >= rows.length
    ensure_leaderboard_scroll
    old != @leaderboard_index.to_i
  rescue
    false
  end

  def ensure_leaderboard_scroll
    @leaderboard_scroll_row ||= 0
    row = @leaderboard_index.to_i
    visible = leaderboard_visible_rows
    @leaderboard_scroll_row = row if row < @leaderboard_scroll_row
    bottom = @leaderboard_scroll_row + visible - 1
    @leaderboard_scroll_row = row - visible + 1 if row > bottom
    max_scroll = [(@leaderboard_entries || []).length - visible, 0].max
    @leaderboard_scroll_row = [[@leaderboard_scroll_row, 0].max, max_scroll].min
  rescue
    @leaderboard_scroll_row = 0
  end
  def draw_leaderboard(loading = false)
    bmp = @sprites["screen"].bitmap
    over = @sprites["overlay"].bitmap
    bmp.clear
    over.clear
    pbSetSystemFont(bmp)
    draw_select_background(bmp)
    x = 18
    y = 38
    w = Graphics.width - 36
    h = Graphics.height - 72
    draw_panel(bmp, x, y, w, h, Color.new(92, 188, 255), Color.new(18, 29, 50))
    mode_name = case @leaderboard_mode
                when :breach then _INTL("Breach - Season {1}", (PokemonSurvivor.breach_current_season || {})[:id].to_i)
                when :rush then _INTL("Rush")
                when :tower then _INTL("Tower")
                when :endless then _INTL("Endless")
                else _INTL("Classic")
                end
    title_color = case @leaderboard_mode
                  when :rush then Color.new(184, 104, 255)
                  when :tower then Color.new(128, 230, 160)
                  when :endless then Color.new(255, 178, 92)
                  else Color.new(92, 188, 255)
                  end
    draw_hud_header_strip(bmp, x + 16, y + 14, w - 32, 34, title_color, Color.new(8, 13, 26))
    draw_text_box_ellipsis(bmp, _INTL("Leaderboard - {1}", mode_name), x + 16, y + 22, w - 32, 22, title_color, Color.new(40, 40, 48), 2)
    if loading
      draw_text_box_ellipsis(bmp, _INTL("Loading..."), x + 20, y + (h / 2) - 8, w - 40, 22, Color.white, Color.new(40, 40, 48), 2)
    elsif @leaderboard_error
      draw_text_box_ellipsis(bmp, @leaderboard_error, x + 20, y + (h / 2) - 8, w - 40, 22, Color.white, Color.new(40, 40, 48), 2)
    else
      draw_leaderboard_rows(bmp, x + 10, y + 62, w - 20, [h - 154, 204].min)
    end
    filter_text = _INTL("Sort: {1}   Filter: {2}", leaderboard_sort_label, leaderboard_filter_label)
    draw_text_box_ellipsis(bmp, filter_text, x + 16, y + h - 32, w - 32, 22, Color.new(198, 214, 236), Color.new(40, 40, 48), 2)
    confirm_label = leaderboard_rank_reward_selected? ? _INTL("Claim") : _INTL("Back")
    draw_help(over, [[:left, ""], [:right, _INTL("Mode")], [:up, ""], [:down, _INTL("Scroll")], [:ready_menu, _INTL("Sort")], [:action, _INTL("Filter")], [:confirm, confirm_label], [:cancel, _INTL("Back")]])
    draw_tv_filter(over)
  rescue
  end
  def draw_leaderboard_rows(bitmap, x, y, w, h)
    rows = @leaderboard_entries || []
    visible_rows = leaderboard_visible_rows
    row_h = 23
    row_gap = 3
    list_h = (visible_rows * (row_h + row_gap)) - row_gap
    h = [h.to_i, list_h + 36].min
    ensure_leaderboard_scroll
    first = @leaderboard_scroll_row.to_i
    shown = rows[first, visible_rows] || []
    header_color = Color.new(122, 255, 176)
    sort_header_color = Color.new(255, 224, 92)
    inner_x = x + 8
    scroll_w = rows.length > visible_rows ? 10 : 0
    inner_w = w - 18 - scroll_w
    gap = 8
    rank_w = 56
    lv_w = 58
    score_w = 104
    flexible_w = [inner_w - rank_w - lv_w - score_w - (gap * 4), 100].max
    player_w = (flexible_w * 0.46).to_i
    pokemon_w = flexible_w - player_w
    rank_x = inner_x
    player_x = rank_x + rank_w + gap
    pokemon_x = player_x + player_w + gap
    lv_x = pokemon_x + pokemon_w + gap
    score_x = lv_x + lv_w + gap
    draw_leaderboard_cell(bitmap, _INTL("Rank"), rank_x, y, rank_w, 20, header_color, Color.new(32, 32, 40), 0)
    draw_leaderboard_cell(bitmap, _INTL("Player"), player_x, y, player_w, 20, @leaderboard_sort == :player ? sort_header_color : header_color, Color.new(32, 32, 40), 0)
    draw_leaderboard_cell(bitmap, _INTL("Pokemon"), pokemon_x, y, pokemon_w, 20, header_color, Color.new(32, 32, 40), 0)
    draw_leaderboard_cell(bitmap, _INTL("Lv."), lv_x, y, lv_w, 20, @leaderboard_sort == :level ? sort_header_color : header_color, Color.new(32, 32, 40), 2)
    draw_leaderboard_cell(bitmap, _INTL("Score"), score_x, y, score_w, 20, @leaderboard_sort == :score ? sort_header_color : header_color, Color.new(32, 32, 40), 2)
    draw_leaderboard_header_rule(bitmap, inner_x, y + 24, inner_w)
    list_y = y + 32
    shown.each_with_index do |entry, local_i|
      index = first + local_i
      row_y = list_y + (local_i * (row_h + row_gap))
      selected = index == @leaderboard_index.to_i
      fill = selected ? Color.new(32, 58, 92, 210) : (index.even? ? Color.new(8, 13, 26, 190) : Color.new(18, 29, 50, 190))
      bitmap.fill_rect(x, row_y, w - scroll_w - 2, row_h - 2, fill)
      bitmap.fill_rect(x + 2, row_y, w - scroll_w - 6, 1, Color.new(92, 188, 255, selected ? 168 : 78))
      rank = entry[:rank].to_i > 0 ? entry[:rank].to_i.to_s : (index + 1).to_s
      pokemon_text = entry[:pokemon_name].to_s
      pokemon_color = PokemonSurvivor.leaderboard_pokemon_color(entry[:pokemon])
      draw_leaderboard_rank_cell(bitmap, entry[:rank].to_i, rank_x, row_y + 2, rank_w, 18)
      player_color = leaderboard_player_color(entry[:player])
      draw_leaderboard_cell(bitmap, entry[:player].to_s, player_x, row_y + 2, player_w, 18, player_color, Color.new(32, 32, 40), 0)
      draw_leaderboard_cell(bitmap, pokemon_text, pokemon_x, row_y + 2, pokemon_w, 18, pokemon_color, Color.new(32, 32, 40), 0)
      draw_leaderboard_level_cell(bitmap, entry[:level].to_i, lv_x, row_y + 2, lv_w, 18)
      draw_leaderboard_score_cell(bitmap, entry[:score].to_i, score_x, row_y + 2, score_w, 18)
    end
    PokemonSurvivor.draw_text_center(bitmap, _INTL("No scores yet."), x, list_y + 52, w, Color.white) if rows.empty?
    draw_leaderboard_scrollbar(bitmap, x + w - 12, list_y, 7, list_h, first, visible_rows, rows.length) if rows.length > visible_rows
  rescue
  end

  def leaderboard_local_player?(name)
    local = PokemonSurvivor.leaderboard_player_name.to_s.strip.downcase
    other = name.to_s.strip.downcase
    !local.empty? && local == other
  rescue
    false
  end

  def leaderboard_player_color(name)
    return Color.new(122, 255, 176) if leaderboard_local_player?(name)
    Color.white
  rescue
    Color.white
  end
  def draw_leaderboard_scrollbar(bitmap, x, y, w, h, first, visible, total)
    thumb_h = [[(h.to_f * visible.to_f / total.to_f).round, 18].max, h].min
    max_scroll = [total - visible, 1].max
    thumb_y = y + (((h - thumb_h).to_f * first.to_f / max_scroll.to_f).round)
    draw_select_scrollbar(bitmap, x, y, w, h, thumb_y, thumb_h)
  rescue
  end
  def draw_leaderboard_header_rule(bitmap, x, y, w)
    bitmap.fill_rect(x, y, w, 1, Color.new(92, 188, 255, 168))
    bitmap.fill_rect(x, y + 2, w, 1, Color.new(8, 13, 26, 192))
    bitmap.fill_rect(x + 4, y + 4, w - 8, 1, Color.new(255, 238, 160, 92))
  rescue
  end

  def leaderboard_rank_color(rank)
    rank = [[rank.to_i, 2].max, 100].min
    return Color.new(226, 236, 250) if rank == 2
    return Color.new(232, 158, 88) if rank == 3
    step = [[100 - rank, 0].max, 96].min
    leaderboard_gradient_color(step, 96)
  rescue
    Color.white
  end

  def leaderboard_rank_shine_color(base, rank)
    return base if rank.to_i <= 0 || rank.to_i > 10
    pulse = Math.sin(((System.uptime rescue 0.0) * 5.4) + (rank.to_i * 0.65))
    mix = 0.18 + (((pulse + 1.0) / 2.0) * 0.42)
    Color.new(
      (base.red + ((255 - base.red) * mix)).round,
      (base.green + ((255 - base.green) * mix)).round,
      (base.blue + ((235 - base.blue) * mix)).round
    )
  rescue
    base
  end

  def draw_leaderboard_rank_cell(bitmap, rank, x, y, w, h)
    rank = rank.to_i
    text = rank.to_s
    if rank == 1
      base = leaderboard_rainbow_color(0, ((System.uptime rescue 0.0) * 6).to_i)
      color = leaderboard_rank_shine_color(base, rank)
    else
      color = leaderboard_rank_shine_color(leaderboard_rank_color(rank), rank)
    end
    draw_leaderboard_cell(bitmap, text, x, y, w, h, color, Color.new(32, 32, 40), 0)
  rescue
    draw_leaderboard_cell(bitmap, rank.to_i.to_s, x, y, w, h, Color.white, Color.new(32, 32, 40), 0) rescue nil
  end

  def leaderboard_gradient_color(step, max_step)
    palette = [
      Color.new(196, 202, 218),
      Color.new(122, 214, 255),
      Color.new(122, 255, 176),
      Color.new(255, 238, 120),
      Color.new(255, 180, 82),
      Color.new(255, 112, 74),
      Color.new(255, 72, 118)
    ]
    step = [[step.to_i, 0].max, max_step.to_i].min
    return palette[0] if max_step.to_i <= 0
    pos = step.to_f * (palette.length - 1).to_f / max_step.to_f
    index = [[pos.floor, 0].max, palette.length - 2].min
    mix = pos - index
    a = palette[index]
    b = palette[index + 1]
    Color.new(
      (a.red + ((b.red - a.red) * mix)).round,
      (a.green + ((b.green - a.green) * mix)).round,
      (a.blue + ((b.blue - a.blue) * mix)).round
    )
  rescue
    Color.white
  end

  def leaderboard_value_gradient_color(step, max_step)
    max_step = max_step.to_f
    ratio = max_step <= 0 ? 0.0 : step.to_f / max_step
    leaderboard_value_ratio_color(ratio)
  rescue
    Color.white
  end

  def leaderboard_value_ratio_color(ratio)
    palette = [
      Color.new(168, 198, 236),
      Color.new(118, 186, 255),
      Color.new(92, 220, 246),
      Color.new(92, 238, 204),
      Color.new(128, 252, 174),
      Color.new(190, 252, 132),
      Color.new(244, 232, 106),
      Color.new(255, 198, 88),
      Color.new(255, 150, 82),
      Color.new(255, 104, 92)
    ]
    ratio = [[ratio.to_f, 0.0].max, 1.0].min
    eased = ratio * ratio * (3.0 - (2.0 * ratio))
    pos = eased * (palette.length - 1).to_f
    index = [[pos.floor, 0].max, palette.length - 2].min
    mix = pos - index
    a = palette[index]
    b = palette[index + 1]
    Color.new(
      (a.red + ((b.red - a.red) * mix)).round,
      (a.green + ((b.green - a.green) * mix)).round,
      (a.blue + ((b.blue - a.blue) * mix)).round
    )
  rescue
    Color.white
  end

  def leaderboard_score_ratio(score)
    threshold = [leaderboard_score_rainbow_threshold.to_i, 1].max
    value = [[score.to_i, 0].max, threshold].min
    return 0.0 if value <= 0
    Math.log(value + 1.0) / Math.log(threshold + 1.0)
  rescue
    0.0
  end

  def leaderboard_format_number(value)
    text = value.to_i.to_s
    sign = text[0, 1] == '-' ? '-' : ''
    text = text[1, text.length - 1] if !sign.empty?
    sign + text.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
  rescue
    value.to_s
  end

  def leaderboard_level_rainbow_threshold
    case @leaderboard_mode
    when :rush
      180
    when :tower
      400
    when :endless
      5_000
    else
      510
    end
  rescue
    510
  end

  def leaderboard_score_rainbow_threshold
    case @leaderboard_mode
    when :rush
      6_000_000
    when :tower
      6_000_000
    when :endless
      100_000_000_000
    else
      22_000_000
    end
  rescue
    22_000_000
  end

  def leaderboard_level_color(level)
    threshold = [leaderboard_level_rainbow_threshold.to_i, 1].max
    ratio = [[level.to_i, 0].max, threshold].min.to_f / threshold.to_f
    leaderboard_value_ratio_color(ratio)
  rescue
    Color.white
  end
  def leaderboard_rainbow_color(index, tick = 0)
    colors = [
      Color.new(255, 72, 118),
      Color.new(255, 150, 74),
      Color.new(255, 238, 92),
      Color.new(122, 255, 176),
      Color.new(92, 188, 255),
      Color.new(184, 104, 255)
    ]
    colors[(index.to_i + tick.to_i) % colors.length]
  rescue
    Color.white
  end

  def cached_leaderboard_rainbow_text_bitmap(text, w, h, tick)
    @leaderboard_rainbow_text_cache ||= {}
    text = text.to_s
    w = [w.to_i, 1].max
    h = [h.to_i, 1].max
    tick = tick.to_i % 6
    key = [text, w, h, tick].join(":")
    cached = @leaderboard_rainbow_text_cache[key]
    return cached if cached && !cached.disposed?
    bmp = Bitmap.new(w, h)
    pbSetSystemFont(bmp)
    widths = text.each_char.map { |ch| bmp.text_size(ch).width rescue 10 }
    total_w = widths.inject(0) { |sum, value| sum + value }
    draw_x = [(w - total_w) / 2, 0].max
    text.each_char.with_index do |ch, i|
      color = leaderboard_rainbow_color(i, tick)
      pbDrawTextPositions(bmp, [[ch, draw_x, 0, 0, color, Color.new(32, 32, 40)]])
      draw_x += widths[i]
    end
    if @leaderboard_rainbow_text_cache.length > 48
      old_key = @leaderboard_rainbow_text_cache.keys.first
      old = @leaderboard_rainbow_text_cache.delete(old_key)
      old.dispose if old && !old.disposed?
    end
    @leaderboard_rainbow_text_cache[key] = bmp
    bmp
  rescue
    nil
  end
  def draw_leaderboard_level_cell(bitmap, level, x, y, w, h)
    text = level.to_i.to_s
    return draw_leaderboard_cell(bitmap, text, x, y, w, h, leaderboard_level_color(level), Color.new(32, 32, 40), 2) if level.to_i < leaderboard_level_rainbow_threshold
    tick = ((System.uptime rescue 0.0) * 6).to_i
    pbSetSystemFont(bitmap)
    text_w = bitmap.text_size(text).width rescue 0
    if text_w <= w.to_i
      line = cached_leaderboard_rainbow_text_bitmap(text, w, h, tick)
      bitmap.blt(x, y, line, Rect.new(0, 0, w.to_i, h.to_i)) if line && !line.disposed?
    else
      draw_leaderboard_rainbow_numeric_cell(bitmap, text, x, y, w, h, tick)
    end
  rescue
  end

  def leaderboard_score_color(score)
    leaderboard_value_ratio_color(leaderboard_score_ratio(score))
  rescue
    Color.white
  end
  def leaderboard_smooth_scroll_offset(max_offset, speed = 18.0)
    max_offset = max_offset.to_f
    return 0 if max_offset <= 0
    span = max_offset * 2.0
    pos = ((System.uptime rescue 0.0) * speed.to_f) % [span, 1.0].max
    value = pos > max_offset ? span - pos : pos
    value.round
  rescue
    0
  end

  def draw_leaderboard_score_cell(bitmap, score, x, y, w, h)
    text = leaderboard_format_number(score)
    return draw_leaderboard_cell(bitmap, text, x, y, w, h, leaderboard_score_color(score), Color.new(32, 32, 40), 2) if score.to_i < leaderboard_score_rainbow_threshold
    tick = ((System.uptime rescue 0.0) * 6).to_i
    pbSetSystemFont(bitmap)
    text_w = bitmap.text_size(text).width rescue 0
    if text_w <= w.to_i
      line = cached_leaderboard_rainbow_text_bitmap(text, w, h, tick)
      bitmap.blt(x, y, line, Rect.new(0, 0, w.to_i, h.to_i)) if line && !line.disposed?
    else
      draw_leaderboard_rainbow_numeric_cell(bitmap, text, x, y, w, h, tick)
    end
  rescue
  end

  def draw_leaderboard_numeric_cell(bitmap, text, x, y, w, h, base = Color.white, shadow = Color.new(40, 40, 48))
    draw_leaderboard_cell(bitmap, text, x, y, w, h, base, shadow, 2)
  rescue
  end

  def cached_leaderboard_rainbow_text_line(text, h, tick)
    @leaderboard_rainbow_text_cache ||= {}
    text = text.to_s
    h = [h.to_i, 1].max
    tick = tick.to_i % 6
    key = ["line", text, h, tick].join(":")
    cached = @leaderboard_rainbow_text_cache[key]
    return cached if cached && !cached.disposed?
    probe = @sprites && @sprites["screen"] ? @sprites["screen"].bitmap : nil
    pbSetSystemFont(probe) if probe
    widths = text.each_char.map { |ch| probe ? (probe.text_size(ch).width rescue 10) : 10 }
    total_w = widths.inject(0) { |sum, value| sum + value }
    bmp = Bitmap.new([total_w + 24, 1].max, h)
    pbSetSystemFont(bmp)
    draw_x = 0
    text.each_char.with_index do |ch, i|
      color = leaderboard_rainbow_color(i, tick)
      pbDrawTextPositions(bmp, [[ch, draw_x, 0, 0, color, Color.new(32, 32, 40)]])
      draw_x += widths[i]
    end
    if @leaderboard_rainbow_text_cache.length > 64
      old_key = @leaderboard_rainbow_text_cache.keys.first
      old = @leaderboard_rainbow_text_cache.delete(old_key)
      old.dispose if old && !old.disposed?
    end
    @leaderboard_rainbow_text_cache[key] = bmp
    bmp
  rescue
    nil
  end

  def draw_leaderboard_rainbow_numeric_cell(bitmap, text, x, y, w, h, tick)
    w = w.to_i
    h = h.to_i
    return if w <= 0 || h <= 0
    line = cached_leaderboard_rainbow_text_line(text, h, tick)
    return if !line || line.disposed?
    if line.width <= w
      bitmap.blt(x + w - line.width, y, line, Rect.new(0, 0, line.width, h))
      return
    end
    max_offset = [line.width - w, 0].max
    offset = leaderboard_smooth_scroll_offset(max_offset, 18.0)
    bitmap.blt(x, y, line, Rect.new(offset, 0, w, h))
  rescue
  end
  def draw_leaderboard_cell(bitmap, text, x, y, w, h, base = Color.white, shadow = Color.new(40, 40, 48), align = 0)
    w = w.to_i
    h = h.to_i
    return if w <= 0 || h <= 0
    pbSetSystemFont(bitmap)
    text = text.to_s
    text_w = bitmap.text_size(text).width rescue 0
    if align == 2 && text_w <= w
      pbDrawTextPositions(bitmap, [[text, x + (w / 2), y, align, base, shadow]])
      return
    elsif align != 2 && text_w <= w
      pbDrawTextPositions(bitmap, [[text, x, y, align, base, shadow]])
      return
    end
    line = cached_scroll_text_bitmap(text, base, shadow, h, text_w)
    return if !line || line.disposed?
    max_offset = [line.width - w, 0].max
    offset = leaderboard_smooth_scroll_offset(max_offset, align == 2 ? 18.0 : 22.0)
    bitmap.blt(x, y, line, Rect.new(offset, 0, w, h))
  rescue
  end

  def cached_scroll_text_bitmap(text, base, shadow, h, measured_w = nil)
    @scroll_text_cache ||= {}
    h = h.to_i
    key = [text.to_s, base.red, base.green, base.blue, shadow.red, shadow.green, shadow.blue, h].join(":")
    cached = @scroll_text_cache[key]
    return cached if cached && !cached.disposed?
    probe = @sprites && @sprites["screen"] ? @sprites["screen"].bitmap : nil
    pbSetSystemFont(probe) if probe
    text_w = measured_w || (probe.text_size(text.to_s).width rescue text.to_s.length * 10)
    bmp = Bitmap.new([text_w + 24, 1].max, [h, 1].max)
    pbSetSystemFont(bmp)
    pbDrawTextPositions(bmp, [[text.to_s, 0, 0, false, base, shadow]])
    if @scroll_text_cache.length > 96
      old_key = @scroll_text_cache.keys.first
      old = @scroll_text_cache.delete(old_key)
      old.dispose if old && !old.disposed?
    end
    @scroll_text_cache[key] = bmp
    bmp
  rescue
    nil
  end
  def select_grid_columns
    5
  end

  def select_visible_rows
    3
  end

  def ensure_select_scroll
    @hero_scroll_row ||= 0
    row = @hero_index / select_grid_columns
    @hero_scroll_row = row if row < @hero_scroll_row
    bottom = @hero_scroll_row + select_visible_rows - 1
    @hero_scroll_row = row - select_visible_rows + 1 if row > bottom
    total_rows = ((@heroes.length + select_grid_columns - 1) / select_grid_columns)
    max_scroll = [total_rows - select_visible_rows, 0].max
    @hero_scroll_row = [[@hero_scroll_row, 0].max, max_scroll].min
  rescue
    @hero_scroll_row = 0
  end

  def draw_select
    bmp = @sprites["screen"].bitmap
    over = @sprites["overlay"].bitmap
    bmp.clear
    over.clear
    pbSetSystemFont(bmp)
    draw_select_background(bmp)
    draw_select_header(bmp)
    draw_select_grid(bmp)
    draw_hero_confirm_panel(bmp) if @confirming_hero && !(respond_to?(:battle_pass_slot_key?) && battle_pass_slot_key?(selected_hero_name))
    selected_key = PokemonSurvivor.species_key(selected_hero_name)
    selected_unlocked = PokemonSurvivor.hero_unlocked?(selected_key)
    help = if @confirming_hero && selected_unlocked
             list = [[:confirm, _INTL("Start")], [:action, selected_hero_training_action_label]]
             list << [:ready_menu, _INTL("Equipment")] if PokemonSurvivor.respond_to?(:pokemon_equipment_slot_unlocked?) && PokemonSurvivor.pokemon_equipment_slot_unlocked?(selected_key)
             list << [:cancel, _INTL("Back")]
             list
           elsif @confirming_hero && PokemonSurvivor::HERO_UNLOCK_PASSWORDS.key?(selected_key)
             [[:confirm, _INTL("Unlock")], [:cancel, _INTL("Back")]]
           elsif @confirming_hero
             [[:cancel, _INTL("Back")]]
           else
             [[:left, ""], [:right, _INTL("Pokemon")], [:up, ""], [:down, _INTL("Scroll")], [:confirm, @select_focus == :shop ? _INTL("Shop") : _INTL("Select")], [:ready_menu, _INTL("Leaderboard")], [:action, _INTL("Save")], [:cancel, _INTL("Menu")]]
           end
    draw_help(over, help)
    draw_tv_filter(over)
  end


  def draw_mode_select
    draw_select
    bmp = @sprites["screen"].bitmap
    over = @sprites["overlay"].bitmap
    over.clear
    bitmap = bmp
    bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0, 118))
    name = @mode_select_hero || selected_hero_name
    display_name = PokemonSurvivor.species_name(name)
    w = [Graphics.width - 72, 360].min
    rigging_available = PokemonSurvivor.porygon_rigging_unlocked?(name)
    h = rigging_available ? 350 : 334
    x = (Graphics.width - w) / 2
    y = (Graphics.height - h) / 2
    draw_panel(bitmap, x, y, w, h, Color.new(255, 198, 70), Color.new(18, 29, 50))
    draw_pixel_round_rect(bitmap, x + 14, y + 12, w - 28, 32, Color.new(8, 13, 26, 188))
    draw_text_box_ellipsis(bitmap, _INTL("Mode for {1}", display_name), x + 18, y + 18, w - 36, 22, Color.new(255, 238, 160), Color.new(40, 40, 48), 2)
    rush_available = rush_mode_select_available?
    tower_available = tower_mode_select_available?
    endless_available = endless_mode_select_available?
    labels = [_INTL("Classic Mode"), _INTL("Rush Mode"), _INTL("Tower Mode"), _INTL("Endless Mode"), _INTL("Cancel")]
    0.upto(4) do |i|
      enabled = (i != 1 || rush_available) && (i != 2 || tower_available) && (i != 3 || endless_available)
      draw_mode_button(bitmap, x + 34, y + 60 + (i * 50), w - 68, 42, labels[i], @mode_select_index.to_i == i, i, enabled)
    end
    if rigging_available
      if defined?(ControlHelpText)
        ControlHelpText.draw_segments(bitmap, [[:action, _INTL("Porygon Trickery")]],
          x + 18, y + 316, 2, Color.new(255, 218, 100), Color.new(30, 30, 40), w - 36)
      else
        draw_porygon_centered_text(bitmap, _INTL("Porygon Trickery"), x + 18, y + 310,
          w - 36, 28, Color.new(255, 218, 100), true)
      end
    end
    draw_tv_filter(over)
  rescue
  end

  def draw_mode_button(bitmap, x, y, w, h, label, selected, index = 0, enabled = true)
    palettes = [
      [Color.new(84, 126, 184), Color.new(28, 48, 78), Color.new(150, 192, 255)],
      [Color.new(142, 96, 190), Color.new(48, 34, 78), Color.new(214, 166, 255)],
      [Color.new(92, 172, 128), Color.new(30, 64, 54), Color.new(150, 245, 190)],
      [Color.new(246, 224, 78), Color.new(96, 82, 22), Color.new(255, 248, 144)],
      [Color.new(176, 72, 76), Color.new(68, 28, 36), Color.new(255, 142, 132)]
    ]
    edge, fill, shine = palettes[index.to_i] || palettes[0]
    if !enabled
      edge = Color.new(82, 88, 104)
      fill = Color.new(28, 32, 42)
      shine = Color.new(116, 124, 142)
    elsif selected
      fill = Color.new([fill.red + 34, 255].min, [fill.green + 34, 255].min, [fill.blue + 34, 255].min)
      shine = Color.new([shine.red + 22, 255].min, [shine.green + 22, 255].min, [shine.blue + 22, 255].min)
    end
    text_color = enabled ? Color.new(226, 232, 244) : Color.new(154, 160, 176)
    draw_modern_button_frame(bitmap, x, y, w, h, edge, fill, shine, selected)
    icon_name = mode_button_icon_name(index)
    text_w = bitmap.text_size(label).width rescue (label.to_s.length * 8)
    icon = cached_icon_bitmap(icon_name)
    icon_scale = 0.5
    icon_w = icon && !icon.disposed? ? (icon.width * icon_scale).round : 0
    if icon_w <= 0
      draw_text_box_ellipsis(bitmap, label, x + 10, y + 11, w - 20, 22, text_color, Color.new(30, 30, 38), 2)
      return
    end
    gap = 4
    group_w = text_w + (icon_w * 2) + (gap * 2)
    group_x = x + ((w - group_w) / 2)
    draw_mode_button_icon(bitmap, icon_name, group_x + (icon_w / 2), y + (h / 2), icon_scale)
    draw_mode_button_icon(bitmap, icon_name, group_x + icon_w + gap + text_w + gap + (icon_w / 2), y + (h / 2), icon_scale)
    PokemonSurvivor.draw_text_center(bitmap, label, group_x + icon_w + gap, y + 11, text_w, text_color, Color.new(30, 30, 38))
  rescue
  end

  def mode_button_icon_name(index)
    case index.to_i
    when 0 then "ICON_BOSS_CLASSIC_MENU"
    when 1 then "ICON_BOSS_RUSH_MENU"
    when 2 then "ICON_BOSS_TOWER"
    when 3 then "ICON_BOSS_ENDLESS"
    else nil
    end
  rescue
    nil
  end

  def draw_mode_button_icon(bitmap, name, cx, cy, scale = 1.0)
    icon = cached_icon_bitmap(name)
    return if !icon || icon.disposed?
    dest_w = (icon.width * scale.to_f).round
    dest_h = (icon.height * scale.to_f).round
    src = Rect.new(0, 0, icon.width, icon.height)
    dest = Rect.new((cx - dest_w / 2).round, (cy - dest_h / 2).round, dest_w, dest_h)
    bitmap.stretch_blt(dest, icon, src)
  rescue
  end

  def select_hero_menu_bitmap(name)
    # Menu previews belong to this Pokemon, never to the previous run's starter.
    if PokemonSurvivor.eight_direction_hero?(name) && respond_to?(:cached_hero_idle_bitmap)
      idle = cached_hero_idle_bitmap(name, name)
      return idle if idle && !idle.disposed?
    end
    cached_bitmap(PokemonSurvivor::HERO_DIR, name, name)
  rescue
    cached_bitmap(PokemonSurvivor::HERO_DIR, name, name)
  end

  def select_hero_menu_frame(name, bitmap, animate = true)
    return 0 if !animate
    frames = PokemonSurvivor.charset_frame_count(bitmap, PokemonSurvivor::DIR8_DOWN, PokemonSurvivor.eight_direction_hero?(name) ? PokemonSurvivor::CHARSET_8_DIRECTIONS : PokemonSurvivor::CHARSET_DIRECTIONS)
    (((System.uptime rescue 0.0) * PokemonSurvivor::IDLE_ANIMATION_FPS).floor % frames)
  rescue
    0
  end

  def draw_select_hero_menu_sprite(bitmap, name, x, y, zoom, animate = true)
    if @confirming_hero && @prestige_hold_key == PokemonSurvivor.species_key(name) && !@prestige_hold_done
      elapsed = [System.uptime - @prestige_hold_started, 0.0].max
      x += (Math.sin(elapsed * 48.0) * (1.0 + [elapsed, 3.0].min)).round
    end
    source = select_hero_menu_bitmap(name)
    directions = PokemonSurvivor.eight_direction_hero?(name) ? PokemonSurvivor::CHARSET_8_DIRECTIONS : PokemonSurvivor::CHARSET_DIRECTIONS
    direction = directions >= PokemonSurvivor::CHARSET_8_DIRECTIONS ? PokemonSurvivor::DIR8_DOWN : PokemonSurvivor::DIR_DOWN
    frame = animate ? select_hero_menu_frame(name, source, true) : 0
    PokemonSurvivor.draw_character_centered(bitmap, source, x, y, direction, frame, zoom, directions)
  rescue
  end
  def draw_select_background(bitmap)
    draw_options_scrolling_background(bitmap)
    panel_x = 10
    panel_y = 10
    panel_w = Graphics.width - 20
    panel_h = Graphics.height - 20
    draw_clean_panel(bitmap, panel_x, panel_y, panel_w, panel_h, Color.new(92, 188, 255), Color.new(27, 43, 70, 224))
  rescue
    draw_menu_background(bitmap)
  end

  def draw_select_header(bitmap)
    x = 24
    y = 20
    w = Graphics.width - 48
    shop_w = 126
    gap = 12
    title_w = w - shop_w - gap
    draw_clean_panel(bitmap, x, y, title_w, 48, Color.new(255, 224, 92), Color.new(18, 30, 52))
    PokemonSurvivor.draw_text_center(bitmap, _INTL("Choose a Pokemon"), x, y + 14, title_w, Color.new(255, 238, 160))
    draw_shop_header_button(bitmap, x + title_w + gap, y, shop_w, 48, @select_focus == :shop) if respond_to?(:draw_shop_header_button)
  end
  def draw_select_grid(bitmap)
    cols = select_grid_columns
    rows = select_visible_rows
    slot_w = 74
    slot_h = 74
    gap = 10
    grid_w = (slot_w * cols) + (gap * (cols - 1))
    start_x = (Graphics.width - grid_w) / 2
    start_y = 94
    panel_h = (slot_h * rows) + (gap * (rows - 1))
    panel_x = start_x - 16
    panel_y = start_y - 18
    panel_w = grid_w + 38
    draw_panel(bitmap, panel_x, panel_y, panel_w, panel_h + 32, Color.new(112, 132, 255), Color.new(18, 29, 50))
    first = @hero_scroll_row.to_i * cols
    last = [first + (cols * rows), @heroes.length].min
    (first...last).each do |i|
      local = i - first
      col = local % cols
      row = local / cols
      x = start_x + (col * (slot_w + gap))
      y = start_y + (row * (slot_h + gap))
      selected = (@select_focus != :shop && i == @hero_index)
      if PokemonSurvivor.const_defined?(:BREACH_SLOT_KEY) && @heroes[i] == PokemonSurvivor::BREACH_SLOT_KEY
        draw_breach_select_slot(bitmap, x, y, slot_w, slot_h, selected)
        next
      end
      if respond_to?(:battle_pass_slot_key?) && battle_pass_slot_key?(@heroes[i])
        draw_battle_pass_select_slot(bitmap, x, y, slot_w, slot_h, selected) if respond_to?(:draw_battle_pass_select_slot)
        next
      end
      hero = PokemonSurvivor.hero_data(@heroes[i])
      locked = !PokemonSurvivor.hero_unlocked?(@heroes[i])
      finished = !locked && PokemonSurvivor.hero_finished?(@heroes[i])
      boss_finished = !locked && PokemonSurvivor.hero_boss_finished?(@heroes[i])
      evolution_finished = !locked && PokemonSurvivor.hero_evolution_finished?(@heroes[i])
      level_finished = !locked && PokemonSurvivor.hero_level_finished?(@heroes[i])
      rush_finished = !locked && PokemonSurvivor.hero_rush_finished?(@heroes[i])
      tower_finished = !locked && PokemonSurvivor.hero_tower_finished?(@heroes[i])
      accent = selected ? Color.new(255, 224, 92) : (locked ? Color.new(92, 102, 122) : hero[:color])
      fill = if selected
               locked ? Color.new(54, 52, 72) : Color.new(58, 78, 112)
             else
               locked ? Color.new(22, 28, 42) : Color.new(30, 42, 66)
             end
      if selected
        draw_hero_slot(bitmap, x, y, slot_w, slot_h, @heroes[i], accent, fill, true, locked, finished, boss_finished, evolution_finished, level_finished, rush_finished, tower_finished)
      else
        draw_cached_select_hero_slot(bitmap, x, y, slot_w, slot_h, @heroes[i], accent, fill, locked, finished, boss_finished, evolution_finished, level_finished, rush_finished, tower_finished)
      end
    end
    total_rows = ((@heroes.length + cols - 1) / cols)
    return if total_rows <= rows
    bar_x = start_x + grid_w + 8
    bar_y = start_y
    bar_h = panel_h
    thumb_h = [[(bar_h * rows / total_rows).round, 18].max, bar_h].min
    max_scroll = [total_rows - rows, 1].max
    thumb_y = bar_y + ((bar_h - thumb_h) * @hero_scroll_row.to_i / max_scroll)
    draw_select_scrollbar(bitmap, bar_x, bar_y, 7, bar_h, thumb_y, thumb_h)
  end

  def draw_select_scrollbar(bitmap, x, y, w, h, thumb_y, thumb_h)
    bitmap.fill_rect(x, y, w, h, Color.new(3, 6, 13))
    bitmap.fill_rect(x + 1, y + 1, w - 2, h - 2, Color.new(34, 46, 68))
    bitmap.fill_rect(x + 2, y + 2, w - 4, h - 4, Color.new(8, 13, 26))
    bitmap.fill_rect(x + 2, y + 2, 1, h - 4, Color.new(66, 84, 118))
    tx = x + 1
    tw = w - 2
    ty = [[thumb_y.to_i, y + 1].max, y + h - thumb_h.to_i - 1].min
    th = [[thumb_h.to_i, 12].max, h - 2].min
    bitmap.fill_rect(tx, ty, tw, th, Color.new(122, 92, 42))
    bitmap.fill_rect(tx + 1, ty + 1, tw - 2, th - 2, Color.new(255, 198, 70))
    bitmap.fill_rect(tx + 2, ty + 2, [tw - 4, 1].max, 2, Color.new(255, 238, 150))
    bitmap.fill_rect(tx + tw - 2, ty + 2, 1, [th - 4, 1].max, Color.new(164, 112, 42))
    bitmap.fill_rect(tx + 2, ty + th - 3, [tw - 4, 1].max, 1, Color.new(164, 112, 42))
  rescue
  end

  def select_hero_slot_cache_key(name, w, h, accent, fill, locked, finished, boss_finished, evolution_finished, level_finished, rush_finished, tower_finished)
    key_name = PokemonSurvivor.species_key(name).to_s
    shiny = PokemonSurvivor.respond_to?(:pokemon_shiny_active?) && PokemonSurvivor.pokemon_shiny_active?(key_name) ? 1 : 0
    alt = PokemonSurvivor.pokemon_alt_active?(key_name) ? 1 : 0
    [key_name, shiny, alt, w.to_i, h.to_i, accent.red, accent.green, accent.blue, fill.red, fill.green, fill.blue, locked ? 1 : 0, finished ? 1 : 0, boss_finished ? 1 : 0, evolution_finished ? 1 : 0, level_finished ? 1 : 0, rush_finished ? 1 : 0, tower_finished ? 1 : 0].join(":")
  rescue
    name.to_s
  end

  def cached_select_hero_slot_bitmap(name, w, h, accent, fill, locked, finished, boss_finished, evolution_finished, level_finished, rush_finished, tower_finished)
    @select_hero_slot_cache ||= {}
    key = select_hero_slot_cache_key(name, w, h, accent, fill, locked, finished, boss_finished, evolution_finished, level_finished, rush_finished, tower_finished)
    cached = @select_hero_slot_cache[key]
    return cached if cached && !cached.disposed?
    if @select_hero_slot_cache.length >= 96
      _, old = @select_hero_slot_cache.shift
      old.dispose if old && !old.disposed?
    end
    # Completion badges extend 12px above and 11px beyond the slot's right edge.
    bmp = Bitmap.new(w + 11, h + 12)
    draw_hero_slot(bmp, 0, 12, w, h, name, accent, fill, false, locked, finished, boss_finished, evolution_finished, level_finished, rush_finished, tower_finished)
    @select_hero_slot_cache[key] = bmp
    bmp
  rescue
    nil
  end

  def draw_cached_select_hero_slot(bitmap, x, y, w, h, name, accent, fill, locked, finished, boss_finished, evolution_finished, level_finished, rush_finished, tower_finished)
    slot = cached_select_hero_slot_bitmap(name, w, h, accent, fill, locked, finished, boss_finished, evolution_finished, level_finished, rush_finished, tower_finished)
    if slot && !slot.disposed?
      bitmap.blt(x, y - 12, slot, Rect.new(0, 0, slot.width, slot.height))
    else
      draw_hero_slot(bitmap, x, y, w, h, name, accent, fill, false, locked, finished, boss_finished, evolution_finished, level_finished, rush_finished, tower_finished)
    end
  rescue
    draw_hero_slot(bitmap, x, y, w, h, name, accent, fill, false, locked, finished, boss_finished, evolution_finished, level_finished, rush_finished, tower_finished) rescue nil
  end

  def draw_hero_slot(bitmap, x, y, w, h, name, accent, fill, selected, locked = false, finished = false, boss_finished = false, evolution_finished = false, level_finished = false, rush_finished = false, tower_finished = false)
    border = selected ? Color.new(255, 224, 92) : Color.new(58, 78, 110)
    border = Color.new(80, 84, 98) if locked
    slot_fill = selected ? brighten_color(fill, 10) : fill
    draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(4, 7, 14))
    draw_pixel_round_rect(bitmap, x + 1, y + 1, w - 2, h - 2, border)
    draw_pixel_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, Color.new(8, 13, 26))
    draw_pixel_round_rect(bitmap, x + 3, y + 3, w - 6, h - 6, slot_fill)
    bitmap.fill_rect(x + 7, y + 6, w - 14, 2, brighten_color(accent, selected ? 28 : 12))
    bitmap.fill_rect(x + 8, y + 9, w - 16, 1, Color.new(255, 255, 255, selected ? 56 : 26))
    bitmap.fill_rect(x + 7, y + h - 10, w - 14, 2, selected ? Color.new(122, 255, 176) : Color.new(42, 58, 84))
    if locked
      PokemonSurvivor.draw_text_center(bitmap, "?", x, y + 27, w, selected ? Color.new(255, 238, 160) : Color.new(210, 216, 230), Color.new(20, 20, 26))
    else
      draw_select_hero_menu_sprite(bitmap, name, x + (w / 2), y + 40, 2.0, selected)
    end
    draw_completion_badges(bitmap, x, y, w, h, finished, boss_finished, evolution_finished, level_finished, rush_finished, tower_finished) if !locked
  rescue
  end

  def draw_completion_badges(bitmap, x, y, w, h, finished = false, boss_finished = false, evolution_finished = false, level_finished = false, rush_finished = false, tower_finished = false)
    empty = cached_vfx_bitmap("VFX_EMPTY")
    badges = []
    badges << empty if empty && !empty.disposed?
    evolution = cached_vfx_bitmap("VFX_EVOLUTION_FINISH") if evolution_finished
    level = cached_vfx_bitmap("VFX_LEVEL_FINISH") if level_finished
    rush = cached_vfx_bitmap("VFX_RUSH_FINISH") if rush_finished
    tower = cached_vfx_bitmap("VFX_TOWER_FINISH") if tower_finished
    finish = cached_vfx_bitmap("VFX_FINISH") if finished
    boss = cached_vfx_bitmap("VFX_BOSS_FINISH") if boss_finished
    badges << evolution if evolution && !evolution.disposed?
    badges << level if level && !level.disposed?
    badges << rush if rush && !rush.disposed?
    badges << tower if tower && !tower.disposed?
    badges << finish if finish && !finish.disposed?
    badges << boss if boss && !boss.disposed?
    return if badges.empty?
    max_w = badges.map(&:width).max
    max_h = badges.map(&:height).max
    badge_w = [[max_w, 1].max, w - 8].min
    badge_h = [[max_h, 1].max, h - 8].min
    dest_x = x + w - badge_w + 11
    dest_y = y - 12
    dest_x = [[dest_x, x + 2].max, x + w - badge_w + 11].min
    dest_y = [[dest_y, y - 12].max, y + h - badge_h - 4].min
    badges.each do |sheet|
      src = Rect.new(0, 0, sheet.width, sheet.height)
      dest = Rect.new(dest_x, dest_y, badge_w, badge_h)
      bitmap.stretch_blt(dest, sheet, src)
    end
  rescue
  end

  def draw_hero_confirm_panel(bitmap)
    name = selected_hero_name
    hero = PokemonSurvivor.hero_data(name)
    skill = PokemonSurvivor.localized_skill(hero[:skill]) || {}
    passive = PokemonSurvivor.hero_passive(name)
    unlocked = PokemonSurvivor.hero_unlocked?(name)
    accent = unlocked ? hero[:color] : Color.new(132, 142, 162)
    display_name = unlocked ? PokemonSurvivor.species_name(name) : "???"
    x = 14
    y = 14
    w = Graphics.width - 28
    h = Graphics.height - 52
    bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(7, 10, 18))
    step = 24
    offset = ((System.uptime rescue 0) * 32).to_i % step
    stripe_x = -Graphics.height
    while stripe_x < Graphics.width
      bitmap.fill_rect(stripe_x + offset, 0, 2, Graphics.height, Color.new(20, 32, 58))
      stripe_x += step
    end
    bitmap.fill_rect(8, 8, Graphics.width - 16, h + 12, Color.new(3, 6, 13))
    draw_panel(bitmap, x, y, w, h, accent, Color.new(20, 32, 54))
    title = unlocked ? _INTL("Start with {1}?", display_name) : _INTL("{1} is locked", display_name)
    draw_soft_badge(bitmap, x + 16, y + 16, w - 32, 38, Color.new(8, 13, 26, 172))
    bitmap.fill_rect(x + 24, y + 20, w - 48, 2, brighten_color(accent, 22))
    PokemonSurvivor.draw_text_center(bitmap, title, x + 18, y + 27, w - 36, unlocked ? Color.new(255, 238, 160) : Color.new(255, 132, 132))
    portrait_x = x + 92
    portrait_y = y + 148
    draw_pixel_round_rect(bitmap, x + 28, y + 70, 128, 156, Color.new(4, 7, 14))
    draw_pixel_round_rect(bitmap, x + 32, y + 74, 120, 148, Color.new(34, 47, 74))
    draw_pixel_round_rect(bitmap, x + 38, y + 80, 108, 136, Color.new(accent.red / 4, accent.green / 4, accent.blue / 4, 180))
    if unlocked
      draw_select_hero_menu_sprite(bitmap, name, portrait_x, portrait_y, 3.0)
      draw_pokemon_equipment_slot(bitmap, name, x + 108, y + 178, 42, 42, accent) if respond_to?(:draw_pokemon_equipment_slot) && PokemonSurvivor.pokemon_equipment_slot_unlocked?(name)
      draw_menu_notification(bitmap, x + 28, y + 70) if training_notification?(name)
    else
      old_size = bitmap.font.size rescue nil
      bitmap.font.size = 64 if bitmap.font && bitmap.font.respond_to?(:size=)
      PokemonSurvivor.draw_text_center(bitmap, "?", x + 38, y + 116, 108, Color.new(230, 236, 248), Color.new(20, 20, 28))
      bitmap.font.size = old_size if old_size && bitmap.font && bitmap.font.respond_to?(:size=)
    end
    types = unlocked ? PokemonSurvivor.species_types(name).map { |type| type_name(type) }.join(" / ") : "???"
    hp_text = unlocked ? hero[:hp].to_s : "???"
    speed_text = unlocked ? format("%.2f", hero[:speed]) : "???"
    skill_text = unlocked ? (skill[:name] || "???") : "???"
    passive_text = unlocked ? (passive[:name] || "???") : "???"
    info_x = x + 176
    info_w = w - 204
    draw_soft_badge(bitmap, info_x, y + 70, info_w, 70, Color.new(8, 13, 26, 148))
    draw_text_box(bitmap, _INTL("Type: {1}", types), info_x + 12, y + 78, info_w - 24, 26, unlocked ? Color.new(132, 214, 255) : Color.new(196, 202, 218))
    hp_w = 96
    speed_x = info_x + 12 + hp_w + 12
    draw_text_box(bitmap, _INTL("HP: {1}", hp_text), info_x + 12, y + 110, hp_w, 26, unlocked ? Color.new(122, 255, 176) : Color.new(196, 202, 218))
    draw_text_box(bitmap, _INTL("Speed: {1}", speed_text), speed_x, y + 110, info_x + info_w - speed_x - 12, 26, unlocked ? Color.new(255, 224, 92) : Color.new(196, 202, 218))
    draw_soft_badge(bitmap, info_x, y + 152, info_w, 78, Color.new(8, 13, 26, 138))
    bitmap.fill_rect(info_x + 10, y + 160, info_w - 20, 2, accent)
    draw_text_box(bitmap, _INTL("Skill: {1}", skill_text), info_x + 12, y + 168, info_w - 24, 26, accent)
    draw_text_box(bitmap, _INTL("Passive: {1}", passive_text), info_x + 12, y + 196, info_w - 24, 26, Color.new(198, 214, 236))
    desc = if unlocked
             _INTL("{1}\n{2}", skill[:desc], passive[:desc])
           else
             PokemonSurvivor.hero_unlock_requirement(name)
           end
    desc_x = x + 28
    desc_y = y + 240
    desc_w = w - 56
    desc_h = 72
    draw_soft_badge(bitmap, desc_x, desc_y, desc_w, desc_h, Color.new(8, 13, 26, 138))
    draw_scrolling_wrapped_text(bitmap, desc, desc_x + 12, desc_y + 12, desc_w - 24, desc_h - 18, 24, Color.new(220, 226, 240))
  end


end


























































































































