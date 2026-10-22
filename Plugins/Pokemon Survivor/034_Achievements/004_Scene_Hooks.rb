#===============================================================================
# Pokemon Survivor Achievements - scene hooks
#===============================================================================
module PokemonSurvivorAchievementSceneHooks
  def open_shop(*args, &block)
    if defined?(PokemonSurvivorAchievements)
      stats = PokemonSurvivorAchievements.achievement_stats
      stats[:shop_opened] = stats[:shop_opened].to_i + 1
      PokemonSurvivorAchievements.check([:shop_opened], true)
    end
    return super(*args, &block) if defined?(super)
  end


  def open_pokemon_training(*args, &block)
    if defined?(PokemonSurvivorAchievements)
      stats = PokemonSurvivorAchievements.achievement_stats
      stats[:training_opened] = stats[:training_opened].to_i + 1
      PokemonSurvivorAchievements.check([:training_opened], true)
      PokemonSurvivorAchievements.check_retroactive(false)
    end
    return super(*args, &block) if defined?(super)
  rescue
    return super(*args, &block) if defined?(super)
  end

  def start_game(*args, &block)
    result = defined?(super) ? super(*args, &block) : nil
    if @state == :play && PokemonSurvivor.pokemon_shiny_active?(@hero_base_name) && defined?(PokemonSurvivorAchievements)
      stats = PokemonSurvivorAchievements.achievement_stats
      stats[:shiny_runs_started] = stats[:shiny_runs_started].to_i + 1
      PokemonSurvivorAchievements.check([:training_shiny_run], true)
    end
    result
  rescue
    result
  end

  def buy_selected_training_upgrade(*args, &block)
    before_slots = PokemonSurvivorAchievements.pokemon_training_slot_count rescue 0
    before_shiny = PokemonSurvivorAchievements.pokemon_training_upgrade_owner_count(nil, :training_shiny) rescue 0
    before_equipment = PokemonSurvivorAchievements.pokemon_training_upgrade_owner_count(nil, :training_equipment) rescue 0
    result = defined?(super) ? super(*args, &block) : nil
    if defined?(PokemonSurvivorAchievements)
      after_slots = PokemonSurvivorAchievements.pokemon_training_slot_count rescue before_slots
      after_shiny = PokemonSurvivorAchievements.pokemon_training_upgrade_owner_count(nil, :training_shiny) rescue before_shiny
      after_equipment = PokemonSurvivorAchievements.pokemon_training_upgrade_owner_count(nil, :training_equipment) rescue before_equipment
      ids = []
      ids << :training_first_upgrade if after_slots > before_slots && after_slots >= 1
      ids << :training_10_slots if after_slots >= 10
      ids << :training_25_slots if after_slots >= 25
      ids << :training_complete_one if (PokemonSurvivorAchievements.pokemon_training_complete_count(nil, false) rescue 0) >= 1
      ids << :training_three_complete if (PokemonSurvivorAchievements.pokemon_training_complete_count(nil, false) rescue 0) >= 3
      ids << :training_equipment_unlock if after_equipment > before_equipment || after_equipment >= 1
      ids << :training_shiny_unlock if after_shiny > before_shiny || after_shiny >= 1
      ids << :candies_1000 if (PokemonSurvivor.candy_currency rescue 0) >= 1000
      ids << :candies_5000 if (PokemonSurvivor.candy_currency rescue 0) >= 5000
      PokemonSurvivorAchievements.check(ids, true) if !ids.empty?
      PokemonSurvivorAchievements.check_additional_counters(true, :training)
    end
    result
  rescue
    return super(*args, &block) if defined?(super)
  end
  def apply_upgrade(upgrade, *args, &block)
    kind = @current_upgrade_kind
    before = (@learned_skills || []).length rescue 0
    result = defined?(super) ? super(upgrade, *args, &block) : nil
    after = (@learned_skills || []).length rescue before
    if kind == :moves && after > before && defined?(PokemonSurvivorAchievements)
      @achievement_moves_this_run = @achievement_moves_this_run.to_i + (after - before)
      PokemonSurvivorAchievements.increment_stat(:moves_learned_total, after - before)
      ids = [:moves_first]
      ids << :moves_10_total if (PokemonSurvivorAchievements.achievement_stats[:moves_learned_total].to_i rescue 0) >= 10
      ids << :moves_full_slots if after >= (PokemonSurvivor::MAX_ACTIVE_SKILLS rescue 3)
      PokemonSurvivorAchievements.check(ids, true)
    end
    result
  rescue
    return super(upgrade, *args, &block) if defined?(super)
  end

  def hatch_event_egg(egg, *args, &block)
    hp_rate = egg && egg.max_hp.to_i > 0 ? egg.hp.to_f / egg.max_hp.to_f : 0.0 rescue 0.0
    floor = @tower_floor.to_i rescue 0
    result = defined?(super) ? super(egg, *args, &block) : nil
    if defined?(PokemonSurvivorAchievements)
      stats = PokemonSurvivorAchievements.increment_stat(:egg_hatches, 1)
      PokemonSurvivorAchievements.add_stat_value(stats, :tower_egg_floors, floor) if tower_mode? && [15, 25, 35].include?(floor)
      ids = [:egg_first_hatch]
      ids << :egg_partner_saved if hp_rate >= 0.75
      ids << :egg_5_hatches if stats[:egg_hatches].to_i >= 5
      ids << :egg_15_hatches if stats[:egg_hatches].to_i >= 15
      ids << :tower_egg_floor_set if PokemonSurvivorAchievements.event_species_complete?(stats, :tower_egg_floors, [15, 25, 35])
      PokemonSurvivorAchievements.check(ids, true)
    end
    result
  rescue
    return super(egg, *args, &block) if defined?(super)
  end

  def build_event_baby(*args, &block)
    result = defined?(super) ? super(*args, &block) : nil
    baby = result
    if baby && defined?(PokemonSurvivorAchievements)
      stats = PokemonSurvivorAchievements.achievement_stats
      key = baby.instance_variable_get(:@baby_key) rescue nil
      PokemonSurvivorAchievements.add_stat_species(stats, :egg_babies, key) if key
      ids = []
      shiny = baby.instance_variable_get(:@baby_shiny) rescue false
      stats = PokemonSurvivorAchievements.increment_stat(:egg_shiny_hatches, 1) if shiny
      ids << :egg_munchlax if key == :MUNCHLAX
      ids << :egg_shiny_first if stats[:egg_shiny_hatches].to_i >= 1
      ids << :egg_shiny_3 if stats[:egg_shiny_hatches].to_i >= 3
      ids << :egg_all_babies if PokemonSurvivorAchievements.event_species_complete?(stats, :egg_babies, (PokemonSurvivor::EVENT_BABY_KEYS rescue []))
      PokemonSurvivorAchievements.check(ids, true) if !ids.empty?
    end
    result
  rescue
    result
  end

  def apply_sleep_reward(key, *args, &block)
    result = defined?(super) ? super(key, *args, &block) : nil
    if result && defined?(PokemonSurvivorAchievements)
      stats = PokemonSurvivorAchievements.increment_stat(:sleep_awakened, 1)
      PokemonSurvivorAchievements.add_stat_species(stats, :sleep_awakened_keys, key)
      ids = [:sleep_first_awaken]
      ids << :sleep_10_awakened if stats[:sleep_awakened].to_i >= 10
      ids << :sleep_25_awakened if stats[:sleep_awakened].to_i >= 25
      ids << :sleep_all_tapu if PokemonSurvivorAchievements.event_species_complete?(stats, :sleep_awakened_keys, (PokemonSurvivor::EVENT_SLEEP_KEYS rescue []))
      PokemonSurvivorAchievements.check(ids, true)
    end
    result
  rescue
    result
  end
  def open_performance_options(*args, &block)
    if defined?(PokemonSurvivorAchievements)
      stats = PokemonSurvivorAchievements.achievement_stats
      stats[:options_opened] = stats[:options_opened].to_i + 1
      PokemonSurvivorAchievements.check([:options_opened], true)
    end
    return super(*args, &block) if defined?(super)
  rescue
    return super(*args, &block) if defined?(super)
  end

  def open_leaderboard(*args, &block)
    result = defined?(super) ? super(*args, &block) : nil
    if @state == :leaderboard && defined?(PokemonSurvivorAchievements)
      stats = PokemonSurvivorAchievements.achievement_stats
      stats[:leaderboard_opened] = stats[:leaderboard_opened].to_i + 1
      PokemonSurvivorAchievements.check([:leaderboard_open], true)
    end
    result
  rescue
    return super(*args, &block) if defined?(super)
  end

  def update_leaderboard(*args, &block)
    old_sort = @leaderboard_sort
    result = defined?(super) ? super(*args, &block) : nil
    return result if @state != :leaderboard || !defined?(PokemonSurvivorAchievements)
    if old_sort != @leaderboard_sort
      stats = PokemonSurvivorAchievements.achievement_stats
      stats[:leaderboard_sorts] = stats[:leaderboard_sorts].to_i + 1
      ids = [:leaderboard_sort]
      if @leaderboard_sort == :player
        stats[:leaderboard_my_runs] = stats[:leaderboard_my_runs].to_i + 1
        ids << :leaderboard_my_runs
      end
      PokemonSurvivorAchievements.check(ids, true)
    end
    result
  rescue
    return super(*args, &block) if defined?(super)
  end

  def open_leaderboard_filter(*args, &block)
    if defined?(PokemonSurvivorAchievements)
      stats = PokemonSurvivorAchievements.achievement_stats
      stats[:leaderboard_filters] = stats[:leaderboard_filters].to_i + 1
      PokemonSurvivorAchievements.check([:leaderboard_filter], true)
    end
    return super(*args, &block) if defined?(super)
  end

  def activate_performance_option(item, *args, &block)
    if item && item[0] == :achievements
      open_achievements
      return
    end
    return super(item, *args, &block) if defined?(super)
  rescue
  end

  def performance_option_value(item, *args, &block)
    if item && item[0] == :achievements
      return _INTL("{1}/{2}", PokemonSurvivorAchievements.earned_count, PokemonSurvivorAchievements.total_count)
    end
    return super(item, *args, &block) if defined?(super)
    ""
  rescue
    ""
  end

  def draw_performance_option_button(bitmap, x, y, w, h, item, label, value, selected, index, *args, &block)
    if item && item[0] == :achievements
      edge = Color.new(255, 196, 86)
      fill = selected ? Color.new(94, 62, 30) : Color.new(62, 42, 24)
      shine = Color.new(255, 232, 140)
      draw_modern_button_frame(bitmap, x, y, w, h, edge, fill, shine, selected)
      draw_text_box(bitmap, _INTL(label.to_s), x + 16, y + 10, w - 132, 24, selected ? Color.new(255, 238, 160) : Color.white, Color.new(28, 28, 34), false)
      draw_text_box(bitmap, value.to_s, x + w - 118, y + 10, 100, 24, shine, Color.new(28, 28, 34), true)
      return
    end
    return super(bitmap, x, y, w, h, item, label, value, selected, index, *args, &block) if defined?(super)
  rescue
  end

  def update_game(dt, *args, &block)
    result = defined?(super) ? super(dt, *args, &block) : nil
    now = System.uptime rescue 0
    return result if now - (@achievement_live_check_time || 0.0) < 0.45
    @achievement_live_check_time = now
    PokemonSurvivorAchievements.check(PokemonSurvivorAchievements.live_ids(self), true) rescue nil
    result
  end

  def buy_selected_shop_upgrade(*args, &block)
    before = PokemonSurvivorAchievements.earned_count rescue 0
    result = defined?(super) ? super(*args, &block) : nil
    PokemonSurvivorAchievements.check_retroactive(true) if (PokemonSurvivorAchievements.earned_count rescue 0) >= before
    result
  rescue
    result
  end

  def submit_current_run_to_leaderboard(*args, &block)
    already = @leaderboard_submitted
    result = defined?(super) ? super(*args, &block) : nil
    if !already && @leaderboard_submitted
      PokemonSurvivorAchievements.record_leaderboard_submit(self) rescue nil
    end
    result
  rescue
    result
  end

  def finish_run(*args, &block)
    already_finished = @run_finished
    result = defined?(super) ? super(*args, &block) : nil
    return result if already_finished
    unlocked = PokemonSurvivorAchievements.check_run(self) rescue []
    run_won = !@run_abandoned && leaderboard_run_won?
    baby = @event_baby rescue nil
    if run_won && baby && baby.hp.to_i > 0
      baby_ids = [:baby_survivor]
      baby_ids << :egg_shiny_guard if (baby.instance_variable_get(:@baby_shiny) rescue false)
      extra = PokemonSurvivorAchievements.check(baby_ids, true) rescue []
      unlocked = (unlocked + extra).compact.uniq
    end
    if unlocked.length > 0 && @run_unlock_messages
      unlocked.each do |data|
        @run_unlock_messages << _INTL("Achievement unlocked: {1}", _INTL(data[:name].to_s))
      end
    end
    result
  rescue
    result
  end
end
