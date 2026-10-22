#===============================================================================
# Pokemon Survivor - Upgrade state, reroll, ban, gameover and cache entry helpers
#===============================================================================

class Scene_PokemonSurvivor

  def request_upgrade(delay = 0.0, count = 1)
    if tower_auto_fallback_upgrade_active?
      count.to_i.times { apply_tower_auto_fallback_upgrade }
      return
    end
    enqueue_upgrade_choices(:upgrade, delay, count)
  end

  def request_move_upgrade(delay = 0.0, count = 1)
    remaining = skill_slots_remaining(true)
    return if remaining <= 0
    enqueue_upgrade_choices(:moves, delay, [count.to_i, remaining].min)
  end

  def enqueue_upgrade_choices(kind, delay = 0.0, count = 1)
    if kind != :moves && @upgrades_exhausted
      return if !real_upgrade_available?
      @upgrades_exhausted = false
    end
    amount = [[count.to_i, 1].max, 3].min
    @pending_upgrade_queue ||= []
    amount.times { @pending_upgrade_queue << kind }
    @pending_move_count = @pending_move_count.to_i + amount if kind == :moves
    @pending_upgrade_count = @pending_upgrade_queue.length
    @pending_upgrade = true
    @upgrade_delay_timer = [@upgrade_delay_timer.to_f, delay.to_f].max
  rescue
  end

  def skill_slots_remaining(include_pending = false)
    learned = (@learned_skills || []).length
    pending = include_pending ? @pending_move_count.to_i : 0
    [PokemonSurvivor::MAX_ACTIVE_SKILLS - learned - pending, 0].max
  rescue
    0
  end

  def can_drop_moves_item?
    skill_slots_remaining(true) > 0 && !available_move_upgrades.empty?
  rescue
    false
  end

  def prune_move_items_if_full
    return if skill_slots_remaining(true) > 0
    (@items || []).delete_if { |item| item && item.name.to_s.upcase == "MOVES" }
  rescue
  end

  def open_upgrade
    @pending_upgrade = false
    @pending_upgrade_queue ||= []
    if @pending_upgrade_queue.empty? && @pending_upgrade_count.to_i > 0
      @pending_upgrade_count.to_i.times { @pending_upgrade_queue << :upgrade }
    end
    @pending_upgrade_count = 1 if @pending_upgrade_count.to_i <= 0 && @pending_upgrade_queue.empty?
    @current_upgrade_kind = @pending_upgrade_queue.shift || :upgrade
    @state = :upgrade
    @upgrade_index = 0
    @upgrade_anim_mode = :in
    @upgrade_anim_start = System.uptime rescue 0.0
    lock_upgrade_input_from_previous_action
    @chosen_upgrade_index = nil
    pool = (@current_upgrade_kind == :moves) ? available_move_upgrades : available_upgrades
    if pool.empty?
      if @current_upgrade_kind == :moves
        consume_pending_upgrade_choice
        @state = :play
        @upgrade_options = []
        return
      elsif tower_mode?
        pool = tower_fallback_upgrades
      else
        @upgrades_exhausted = true
        # Exhausted passive/skill upgrades must not discard queued MOVES pickups.
        @pending_upgrade_queue.select! { |kind| kind == :moves }
        @pending_move_count = @pending_upgrade_queue.length
        @pending_upgrade_count = @pending_upgrade_queue.length + 1
        consume_pending_upgrade_choice
        @state = :play
        prepare_next_tower_floor_after_bonus if respond_to?(:prepare_next_tower_floor_after_bonus)
        @upgrade_options = []
        return
      end
    end
    refresh_upgrade_options(pool)
    return if auto_take_owned_upgrade
    draw_upgrade
  end

  def auto_take_owned_upgrade
    return false if @current_upgrade_kind != :upgrade
    mode = PokemonSurvivor.auto_bonus_mode
    return false if mode == :disabled
    return false if !@upgrade_options || @upgrade_options.empty?
    return false unless @upgrade_options.all? do |upgrade|
      upgrade && !upgrade[:skill] &&
        (mode == :auto || (!tower_fallback_upgrade?(upgrade) && @upgrade_levels[upgrade[:id]].to_i > 0)) &&
        @upgrade_levels[upgrade[:id]].to_i < upgrade[:max].to_i
    end
    upgrade = @upgrade_options.sample
    apply_upgrade(upgrade)
    enqueue_run_reward_popup({
      name: upgrade[:name].to_s,
      level: @upgrade_levels[upgrade[:id]].to_i,
      duration: 2.55
    })
    PokemonSurvivor.gamepad_vibrate_event(:upgrade_take) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
    @upgrade_anim_mode = nil
    @chosen_upgrade_index = nil
    @upgrade_consume_se_played = false
    clear_upgrade_hold_action(true)
    consume_pending_upgrade_choice
    @upgrade_options = []
    @state = :play
    prepare_next_tower_floor_after_bonus if respond_to?(:prepare_next_tower_floor_after_bonus)
    true
  end

  def real_upgrade_available?
    pool = available_upgrades rescue []
    pool.any? { |upgrade| !respond_to?(:tower_fallback_upgrade?) || !tower_fallback_upgrade?(upgrade) }
  rescue
    false
  end
  def available_upgrades
    pool = (PokemonSurvivor.localized_upgrade_pool.reject { |u| u[:skill] } + active_skill_upgrades).select do |u|
      next false if !u[:target_skill] && porygon_excluded?(:passives, u[:id])
      next false if @banned_upgrade_ids && @banned_upgrade_ids.include?(u[:id])
      next false if @breach_run && u[:id] == :lifesteal
      next false if @upgrade_levels[u[:id]].to_i >= u[:max].to_i
      next false if rush_mode? && rush_disabled_upgrade?(u[:id])
      next false if tower_only_upgrade?(u[:id]) && !tower_mode?
      next false if u[:target_skill] && !@learned_skills.include?(u[:target_skill])
      true
    end
    pool = active_skill_upgrades.select { |u| @upgrade_levels[u[:id]].to_i < u[:max].to_i && !(@banned_upgrade_ids && @banned_upgrade_ids.include?(u[:id])) && !(rush_mode? && rush_disabled_upgrade?(u[:id])) } if pool.empty?
    pool = tower_fallback_upgrades if pool.empty? && tower_mode?
    pool
  rescue
    []
  end

  def available_move_upgrades
    return [] if (@learned_skills || []).length >= PokemonSurvivor::MAX_ACTIVE_SKILLS
    PokemonSurvivor.localized_upgrade_pool.select do |u|
      next false if !u[:skill]
      next false if porygon_excluded?(:skills, u[:skill])
      next false if @banned_upgrade_ids && @banned_upgrade_ids.include?(u[:id])
      next false if @upgrade_levels[u[:id]].to_i >= u[:max].to_i
      next false if !PokemonSurvivor.skill_unlocked_for_learning?(u[:skill])
      next false if (@learned_skills || []).include?(u[:skill])
      if [:splash, :fairy_splash].include?(u[:skill])
        next false if (@learned_skills || []).include?(replacement_splash_skill(u[:skill]))
      end
      true
    end
  rescue
    []
  end


  def tower_fallback_upgrades
    [
      { id: :tower_fragment_cache, name: _INTL("Fragment Cache"), desc: _INTL("Gain a small amount of Fragments."), max: 9999, rarity: :common, tower_fallback: true },
      { id: :tower_first_aid, name: _INTL("Emergency Heal"), desc: _INTL("Restore a little HP immediately."), max: 9999, rarity: :common, tower_fallback: true },
      { id: :tower_run_power, name: _INTL("Battle Momentum"), desc: _INTL("Damage dealt during this run increases slightly."), max: 9999, rarity: :common, tower_fallback: true }
    ]
  rescue
    []
  end

  def tower_fallback_upgrade?(upgrade)
    return false if !upgrade
    return true if upgrade[:tower_fallback]
    [:tower_fragment_cache, :tower_first_aid, :tower_run_power].include?(upgrade[:id])
  rescue
    false
  end

  def tower_auto_fallback_upgrade_active?
    return false if PokemonSurvivor.auto_bonus_mode != :semi_auto
    tower_mode? && @tower_fallback_upgrade_id && @tower_fallback_upgrade_id != false
  rescue
    false
  end

  def tower_locked_fallback_upgrade
    id = @tower_fallback_upgrade_id
    return nil if !id
    tower_fallback_upgrades.find { |upgrade| upgrade[:id] == id }
  rescue
    nil
  end

  def apply_tower_auto_fallback_upgrade
    upgrade = tower_locked_fallback_upgrade
    return false if !upgrade
    apply_upgrade(upgrade)
    true
  rescue
    false
  end

  def confirm_tower_fallback_upgrade(upgrade)
    return true if !tower_fallback_upgrade?(upgrade)
    return true if @tower_fallback_upgrade_id
    text = _INTL("Choose {1} for the rest of this Tower run? Future level-ups will automatically take this bonus.", upgrade[:name].to_s)
    return pbConfirmMessage(text) if defined?(pbConfirmMessage)
    pbMessage(text) rescue nil
    true
  rescue
    false
  end
  def rush_disabled_upgrade?(id)
    [:max_hp_small, :max_hp, :lifesteal].include?(id)
  rescue
    false
  end

  def tower_only_upgrade?(id)
    [:floor_momentum, :boss_preparation].include?(id)
  rescue
    false
  end
  def refresh_upgrade_options(pool = nil, avoid_current = false)
    pool ||= available_upgrades
    source = pool.compact
    if avoid_current && @upgrade_options && !@upgrade_options.empty?
      current_ids = @upgrade_options.map { |u| u[:id] }
      filtered = source.reject { |u| current_ids.include?(u[:id]) }
      source = filtered if filtered.length >= [3, source.length].min
    end
    @upgrade_options = choose_weighted_upgrades(source, 3)
    @upgrade_options = [source.sample].compact if !@upgrade_options || @upgrade_options.empty?
    @upgrade_index = [[@upgrade_index.to_i, 0].max, @upgrade_options.length - 1].min if @upgrade_options && !@upgrade_options.empty?
  rescue
    @upgrade_options = []
  end


  def current_upgrade_pool
    @current_upgrade_kind == :moves ? available_move_upgrades : available_upgrades
  rescue
    []
  end
  UPGRADE_HOLD_SECONDS = 1.15
  UPGRADE_INPUT_LOCK_SECONDS = 0.18

  def upgrade_reroll_pressed?
    return PokemonSurvivor.control_press?(:action) if PokemonSurvivor.respond_to?(:control_press?)
    return true if Input.const_defined?(:ACTION) && Input.press?(Input::ACTION)
    false
  rescue
    false
  end

  def upgrade_ban_pressed?
    return PokemonSurvivor.control_press?(:menu) if PokemonSurvivor.respond_to?(:control_press?)
    return true if Input.const_defined?(:SPECIAL) && Input.press?(Input::SPECIAL)
    return true if Input.const_defined?(:MENU) && Input.const_defined?(:ACTION) && Input::MENU != Input::ACTION && Input.press?(Input::MENU)
    false
  rescue
    false
  end



  def upgrade_confirm_triggered?
    return PokemonSurvivor.control_trigger?(:confirm) if PokemonSurvivor.respond_to?(:control_trigger?)
    return true if Input.const_defined?(:USE) && Input.trigger?(Input::USE)
    return true if Input.const_defined?(:C) && Input.trigger?(Input::C)
    false
  rescue
    false
  end
  def upgrade_confirm_pressed?
    return PokemonSurvivor.control_press?(:confirm) if PokemonSurvivor.respond_to?(:control_press?)
    return true if Input.const_defined?(:USE) && Input.press?(Input::USE)
    return true if Input.const_defined?(:C) && Input.press?(Input::C)
    false
  rescue
    false
  end

  def upgrade_any_action_pressed?
    return true if upgrade_confirm_pressed?
    return true if upgrade_reroll_pressed?
    return true if upgrade_ban_pressed?
    return true if Input.const_defined?(:A) && Input.const_defined?(:ACTION) && Input::A != Input::ACTION && Input.press?(Input::A)
    false
  rescue
    false
  end

  def lock_upgrade_input_from_previous_action
    @upgrade_input_lock_timer = UPGRADE_INPUT_LOCK_SECONDS
    @upgrade_input_release_required = upgrade_any_action_pressed?
    @ultimate_action_buffer = false if instance_variable_defined?(:@ultimate_action_buffer)
    @ultimate_action_buffer_timer = 0.0 if instance_variable_defined?(:@ultimate_action_buffer_timer)
  rescue
    @upgrade_input_lock_timer = UPGRADE_INPUT_LOCK_SECONDS
    @upgrade_input_release_required = true
  end

  def update_upgrade_input_guard
    @upgrade_input_lock_timer = [@upgrade_input_lock_timer.to_f - (PokemonSurvivor::STEP_DT rescue (1.0 / 60.0)), 0.0].max
    if @upgrade_input_release_required
      return true if upgrade_any_action_pressed?
      @upgrade_input_release_required = false
    end
    @upgrade_input_lock_timer.to_f > 0.0
  rescue
    false
  end

  def update_upgrade_hold_action
    pressed_reroll = upgrade_reroll_pressed?
    pressed_ban = upgrade_ban_pressed?
    if @upgrade_hold_lock_action
      still_pressed = (@upgrade_hold_lock_action == :reroll) ? pressed_reroll : pressed_ban
      if still_pressed
        clear_upgrade_hold_action(false)
        return false
      end
      @upgrade_hold_lock_action = nil
    end
    wanted = nil
    wanted = :reroll if pressed_reroll && @rerolls_left.to_i > 0
    wanted = :ban if !wanted && pressed_ban && bannable_selected_upgrade?
    if !wanted
      clear_upgrade_hold_action(false)
      return false
    end
    if @upgrade_hold_action != wanted
      @upgrade_hold_action = wanted
      @upgrade_hold_timer = 0.0
    end
    frame_dt = PokemonSurvivor::STEP_DT rescue (1.0 / 60.0)
    @upgrade_hold_timer = [@upgrade_hold_timer.to_f + frame_dt, UPGRADE_HOLD_SECONDS].min
    return false if @upgrade_hold_timer < UPGRADE_HOLD_SECONDS
    done = wanted == :reroll ? reroll_upgrade_options : ban_selected_upgrade
    return false if !done
    @upgrade_hold_lock_action = wanted
    clear_upgrade_hold_action(false)
    true
  rescue
    clear_upgrade_hold_action
    false
  end

  def clear_upgrade_hold_action(clear_lock = false)
    @upgrade_hold_action = nil
    @upgrade_hold_timer = 0.0
    @upgrade_hold_lock_action = nil if clear_lock
  rescue
  end

  def upgrade_hold_progress(action = nil)
    return 0.0 if action && @upgrade_hold_action != action
    [[@upgrade_hold_timer.to_f / UPGRADE_HOLD_SECONDS, 0.0].max, 1.0].min
  rescue
    0.0
  end

  def bannable_selected_upgrade?
    upgrade = @upgrade_options && @upgrade_options[@upgrade_index]
    return false if !upgrade || !upgrade[:id]
    return false if @bans_left.to_i <= 0
    return false if @banned_upgrade_ids && @banned_upgrade_ids.include?(upgrade[:id])
    return false if acquired_irreversible_upgrade?(upgrade) && @upgrade_levels[upgrade[:id]].to_i > 0
    true
  rescue
    false
  end

  def acquired_irreversible_upgrade?(upgrade)
    id = upgrade && upgrade[:id]
    [:tower_fragment_cache, :tower_first_aid].include?(id)
  rescue
    false
  end

  def reroll_upgrade_options
    return false if @rerolls_left.to_i <= 0
    pool = current_upgrade_pool
    return false if pool.empty?
    @rerolls_left -= 1
    refresh_upgrade_options(pool, true)
    @upgrade_index = 0
    @upgrade_anim_mode = :in
    @upgrade_anim_start = System.uptime rescue 0.0
    pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
    PokemonSurvivor.gamepad_vibrate_event(:upgrade_reroll) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
    true
  rescue
    false
  end

  def confirm_ban_acquired_upgrade(upgrade)
    return true if @upgrade_levels[upgrade[:id]].to_i <= 0
    text = _INTL("Ban this acquired bonus and lose one level of its effect?")
    return pbConfirmMessage(text) if defined?(pbConfirmMessage)
    pbMessage(text) rescue nil
    true
  rescue
    false
  end

  def ban_selected_upgrade
    return false if @bans_left.to_i <= 0
    upgrade = @upgrade_options && @upgrade_options[@upgrade_index]
    return false if !upgrade || !upgrade[:id]
    @banned_upgrade_ids ||= []
    return false if @banned_upgrade_ids.include?(upgrade[:id])
    return false if acquired_irreversible_upgrade?(upgrade) && @upgrade_levels[upgrade[:id]].to_i > 0
    return false if !confirm_ban_acquired_upgrade(upgrade)
    return false if @upgrade_levels[upgrade[:id]].to_i > 0 && !remove_upgrade_effect(upgrade)
    @banned_upgrade_ids << upgrade[:id]
    @bans_left -= 1
    refresh_upgrade_options(current_upgrade_pool, false)
    @upgrade_index = 0
    @upgrade_anim_mode = :in
    @upgrade_anim_start = System.uptime rescue 0.0
    pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
    PokemonSurvivor.gamepad_vibrate_event(:upgrade_ban) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
    true
  rescue
    false
  end

  def choose_weighted_upgrades(pool, count)
    choices = []
    available = pool.compact.dup
    count.to_i.times do
      break if available.empty?
      picked = weighted_upgrade_pick(available)
      break if !picked
      choices << picked
      available.delete(picked)
    end
    choices
  rescue
    pool.sample(count.to_i)
  end

  def weighted_upgrade_pick(pool)
    weighted = []
    pool.each do |upgrade|
      rarity_weight(upgrade_rarity(upgrade)).times { weighted << upgrade }
    end
    weighted.sample || pool.sample
  rescue
    pool.sample
  end

  def rarity_weight(rarity)
    base = case rarity
           when :legendary then 3
           when :epic then 10
           when :super_rare then 22
           when :rare then 45
           when :uncommon then 70
           else 100
           end
    draft = @rare_draft_level.to_i
    return base if draft <= 0
    case rarity
    when :legendary then base + draft
    when :epic then base + (draft * 4)
    when :super_rare then base + (draft * 7)
    when :rare then base + (draft * 10)
    else [base - (draft * 12), 55].max
    end
  end
  def active_skill_upgrades
    ret = []
    (@learned_skills || []).each do |skill_id|
      skill = PokemonSurvivor::SKILLS[skill_id]
      next if !skill
      skill_name = _INTL(skill[:name])
      ret << {
        id: :"#{skill_id}_power",
        name: _INTL("{1} Power", skill_name),
        desc: _INTL("This attack deals more damage."),
        max: 6,
        target_skill: skill_id,
        effect: :skill_power
      }
      ret << {
        id: :"#{skill_id}_tempo",
        name: _INTL("{1} Attack Speed", skill_name),
        desc: _INTL("This attack is ready sooner."),
        max: 5,
        target_skill: skill_id,
        effect: :skill_cooldown
      } unless skill[:kind] == :psychic_dash && !psi_trail_auto_interval
      if [:aura, :ring, :zone, :contact, :orbit, :apple_orbit, :orbit_shot, :dual_orbit_shot, :trail, :vortex, :sweep, :charge_shot, :returning_swing, :rook_tornado, :eevee_sweep].include?(skill[:kind])
        ret << {
          id: :"#{skill_id}_reach",
          name: _INTL("{1} Reach", skill_name),
          desc: _INTL("This attack covers more area."),
          max: 4,
          target_skill: skill_id,
          effect: :skill_radius
        }
      end
      if !skill[:ignore_projectile_count] && ([:projectile, :nova, :orbit, :apple_orbit, :orbit_shot, :dual_orbit_shot, :boomerang, :side_seek, :vortex, :sweep, :charge_shot, :returning_swing, :rook_tornado, :eevee_sweep].include?(skill[:kind]) || (skill[:kind] == :zone && skill[:type] == :FAIRY))
        max_count = skill[:max_count] ? [skill[:max_count].to_i - skill[:count].to_i, 1].max : 3
        ret << {
          id: :"#{skill_id}_spread",
          name: skill[:type] == :FAIRY ? _INTL("{1} Petals", skill_name) : _INTL("{1} Spread", skill_name),
          desc: skill[:type] == :FAIRY ? _INTL("Adds one more fairy blossom.") : _INTL("Adds one more shot."),
          max: max_count,
          target_skill: skill_id,
          effect: :skill_count
        }
      end
      if skill[:kind] == :vortex
        ret << {
          id: :"#{skill_id}_lines",
          name: _INTL("{1} Sides", skill_name),
          desc: _INTL("Adds one more orbit side."),
          max: 4,
          target_skill: skill_id,
          effect: :skill_lines
        }
      end
      if [:orbit, :apple_orbit, :orbit_shot, :dual_orbit_shot].include?(skill[:kind]) || skill[:kind] == :vortex
        ret << {
          id: :"#{skill_id}_rotation",
          name: _INTL("{1} Rotation", skill_name),
          desc: _INTL("Orbits spin faster."),
          max: 4,
          rarity: :rare,
          target_skill: skill_id,
          effect: :skill_orbit_speed
        }
        ret << {
          id: :"#{skill_id}_overdrive",
          name: _INTL("{1} Overdrive", skill_name),
          desc: _INTL("Orbits spin much faster."),
          max: 2,
          rarity: :epic,
          target_skill: skill_id,
          effect: :skill_orbit_speed_plus
        }
      end
      if skill[:type] == :FLYING && skill[:knockback].to_i > 0
        ret << {
          id: :"#{skill_id}_gale",
          name: _INTL("{1} Gale", skill_name),
          desc: _INTL("Flying hits push harder."),
          max: 3,
          target_skill: skill_id,
          effect: :skill_knockback
        }
      end
      if skill[:type] == :BUG && skill[:freeze].to_f > 0
        ret << {
          id: :"#{skill_id}_cocoon",
          name: _INTL("{1} Cocoon", skill_name),
          desc: _INTL("Bug hits freeze longer."),
          max: 3,
          target_skill: skill_id,
          effect: :skill_freeze
        }
      end
      add_new_survivor_skill_upgrades(ret, skill_id, skill, skill_name)
    end
    ret
  end

  def add_new_survivor_skill_upgrades(ret, skill_id, skill, skill_name)
    if [:shell_rain, :volcanic_guard, :ancestral_flames, :iron_jaw].include?(skill_id)
      unless skill[:kind] == :survivor_swing || skill_id == :ancestral_flames
        ret << { id: :"#{skill_id}_reach", name: _INTL("{1} Reach", skill_name),
          desc: _INTL("This attack covers more area."), max: 4,
          target_skill: skill_id, effect: :skill_radius }
      end
      ret << { id: :"#{skill_id}_spread", name: _INTL("{1} Spread", skill_name),
        desc: _INTL("Adds one more attack."), max: skill[:max_count] - skill[:count],
        target_skill: skill_id, effect: :skill_count }
    end
    if [:bone_return, :toxic_drag, :iron_jaw].include?(skill_id)
      ret << { id: :"#{skill_id}_reach", name: _INTL("{1} Reach", skill_name),
        desc: _INTL("This attack covers more area."), max: 4,
        target_skill: skill_id, effect: :skill_radius }
    end
    if PokemonSurvivor::GEN9_SKILL_IDS.include?(skill_id)
      unless skill[:kind] == :returning_swing
        ret << { id: :"#{skill_id}_reach", name: _INTL("{1} Reach", skill_name),
          desc: _INTL("This attack covers more area."), max: 4, rarity: :rare,
          target_skill: skill_id, effect: :skill_radius } unless skill[:impact_twister]
      end
      if skill_id == :volt_pummel
        ret << { id: :volt_pummel_spread, name: _INTL("{1} Spread", skill_name),
          desc: _INTL("Adds one more series of Fighting strikes."), max: 5,
          rarity: :epic, target_skill: skill_id, effect: :skill_count }
      end
    end
    case skill_id
    when :forest_echo, :victory_flurry
      ret << { id: :"#{skill_id}_reach", name: _INTL("{1} Reach", skill_name),
        desc: _INTL("This attack covers more area."), max: 4, rarity: :rare,
        target_skill: skill_id, effect: :skill_radius }
      if skill_id == :victory_flurry
        ret << { id: :victory_flurry_spread, name: _INTL("{1} Spread", skill_name),
          desc: _INTL("Adds one more attack."), max: 5, rarity: :epic,
          target_skill: skill_id, effect: :skill_count }
        ret << { id: :victory_flurry_heat, name: _INTL("Victory Heat"),
          desc: _INTL("Burns from Victory Flurry deal more damage."), max: 3, rarity: :rare,
          target_skill: skill_id, effect: :skill_dot_damage }
      end
    when :psychic_well
      ret << { id: :psychic_well_duration, name: _INTL("Lasting Vortex"), desc: _INTL("Psy Vortex fields last 0.5 seconds longer."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_zone_duration }
    when :headache
      ret << { id: :headache_reach, name: _INTL("Headache Reach"), desc: _INTL("Psychic blasts cover a wider area."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_radius }
      ret << { id: :headache_spread, name: _INTL("Headache Spread"), desc: _INTL("Adds one target to direct blasts after evolution."), max: 5, rarity: :epic, target_skill: skill_id, effect: :skill_count }
    when :night_raid
      ret << { id: :night_raid_reach, name: _INTL("Night Raid Reach"), desc: _INTL("Night Raid covers a wider area."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_radius }
      ret << { id: :night_raid_spread, name: _INTL("Night Raid Spread"), desc: _INTL("Adds one more Dark sweep."), max: 5, rarity: :epic, target_skill: skill_id, effect: :skill_count }
    when :psi_trail
      ret << { id: :psi_trail_spread, name: _INTL("Psi Trail Spread"), desc: _INTL("Adds one Psychic shot to each Dash and volley."), max: 5, rarity: :rare, target_skill: skill_id, effect: :skill_count }
      ret << { id: :psi_trail_rebound, name: _INTL("Psi Trail Rebound"), desc: _INTL("Psi Trail bounces to one more enemy."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_bounce }
    when :night_fang
      ret << { id: :night_fang_reach, name: _INTL("Night Fang Reach"), desc: _INTL("Night Fang covers a wider area."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_radius }
      ret << { id: :night_fang_spread, name: _INTL("Night Fang Spread"), desc: _INTL("Adds one more Dark fang."), max: 5, rarity: :epic, target_skill: skill_id, effect: :skill_count }
      ret << { id: :night_fang_stun, name: _INTL("Night Fang Stun"), desc: _INTL("Night Fang paralysis lasts longer."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_freeze }
    when :toxic_spark
      ret << { id: :toxic_spark_blast, name: _INTL("Toxic Blast"), desc: _INTL("Toxic Spark impacts cover a wider area."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_radius }
      ret << { id: :toxic_spark_venom, name: _INTL("Toxic Venom"), desc: _INTL("Toxic Spark poison deals more damage."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_dot_damage }
    when :disciplined_strikes
      ret << { id: :disciplined_strikes_reach, name: _INTL("Disciplined Reach"), desc: _INTL("Disciplined Strikes covers a wider area."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_radius }
      ret << { id: :disciplined_strikes_spread, name: _INTL("Disciplined Spread"), desc: _INTL("Adds one more series of Fighting strikes."), max: 5, rarity: :epic, target_skill: skill_id, effect: :skill_count }
    when :mischief_sweep
      ret << { id: :mischief_sweep_reach, name: _INTL("Mischief Reach"), desc: _INTL("Mischief Sweep reaches farther."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_radius }
    when :fae_bloom
      ret << { id: :fae_bloom_reach, name: _INTL("Fae Bloom Reach"), desc: _INTL("Fae Bloom grows to a larger size."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_radius }
      ret << { id: :fae_bloom_spread, name: _INTL("Fae Bloom Spread"), desc: _INTL("Adds one more Fairy wave."), max: 3, rarity: :epic, target_skill: skill_id, effect: :skill_count }
    when :phantom_warhead
      ret << { id: :phantom_warhead_blast, name: _INTL("Dragon Detonation"), desc: _INTL("Phantom Warhead explosions cover a wider area."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_radius }
    when :iron_gale
      ret << { id: :iron_gale_bind, name: _INTL("Gale Bind"), desc: _INTL("Numbing Gale paralyzes enemies for longer."), max: 2, rarity: :rare, target_skill: skill_id, effect: :skill_freeze }
    when :steel_gale
      ret << { id: :steel_gale_bind, name: _INTL("Steel Bind"), desc: _INTL("Steel Gale paralyzes enemies for longer."), max: 2, rarity: :rare, target_skill: skill_id, effect: :skill_freeze }
    when :ember_strike
      ret << { id: :ember_strike_blast, name: _INTL("Ember Blast"), desc: _INTL("Ember Strike explosions cover a wider area."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_radius }
      ret << { id: :ember_strike_burn, name: _INTL("Ember Heat"), desc: _INTL("Ember Strike burns deal more damage."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_dot_damage }
    when :water_orbit
      ret << { id: :water_orbit_splash, name: _INTL("Bubble Ring Splash"), desc: _INTL("Bubble Ring shot damage +10%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :water_orbit_rebound, name: _INTL("Bubble Ring Rebound"), desc: _INTL("Bubble Ring shots gain one extra bounce."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_bounce }
    when :fire2_combo
      ret << { id: :fire2_combo_heat, name: _INTL("Flame Combo Heat"), desc: _INTL("Flame Combo damage +10%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :fire2_combo_sparks, name: _INTL("Flame Combo Sparks"), desc: _INTL("Flame Combo gains +1 pierce."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_pierce }
    when :drill_spikes
      ret << { id: :drill_spikes_power, name: _INTL("Steel Spines Power"), desc: _INTL("Steel Spines damage +10%."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :drill_spikes_flow, name: _INTL("Steel Spines Attack Speed"), desc: _INTL("Steel Spines recharge time -6%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_cooldown_light }
      ret << { id: :drill_spikes_reach, name: _INTL("Steel Spines Reach"), desc: _INTL("Steel Spines appear a little farther out."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_radius }
    when :steel_volley
      ret << { id: :steel_volley_edge, name: _INTL("Iron Shards Edge"), desc: _INTL("Iron Shards gains +1 pierce."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_pierce }
      ret << { id: :steel_volley_pressure, name: _INTL("Iron Shards Power"), desc: _INTL("Iron Shards damage +10%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
    when :cinder_swarm
      ret << { id: :cinder_swarm_heat, name: _INTL("Cinder Swarm Heat"), desc: _INTL("Cinder Swarm damage +10%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :cinder_swarm_sparks, name: _INTL("Cinder Swarm Sparks"), desc: _INTL("Cinder Swarm releases one extra split wisp."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_impact }
    when :sandile_ground_zone
      ret << { id: :sandile_ground_zone_fault, name: _INTL("Sand Pit Power"), desc: _INTL("Sand Pit damage +10%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :sandile_ground_zone_crater, name: _INTL("Sand Pit Area"), desc: _INTL("Sand Pit covers a wider area."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_radius }
    when :flying_spread
      ret << { id: :flying_spread_tailwind, name: _INTL("Wing Volley Attack Speed"), desc: _INTL("Wing Volley recharge time -6%."), max: 3, rarity: :common, target_skill: skill_id, effect: :skill_cooldown_light }
      ret << { id: :flying_spread_focus, name: _INTL("Wing Volley Power"), desc: _INTL("Wing Volley damage +10%."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
    when :ice_shatter
      ret << { id: :ice_shatter_cold, name: _INTL("Ice Shatter Cold"), desc: _INTL("Ice Shatter damage +10%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :ice_shatter_splinters, name: _INTL("Ice Shatter Splinters"), desc: _INTL("Ice Shatter releases one extra homing fragment."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_impact }
    when :toxic_thread
      ret << { id: :toxic_thread_barbs, name: _INTL("Toxic Thread Barbs"), desc: _INTL("Toxic Thread poison damage +1."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_dot_damage }
      ret << { id: :toxic_thread_force, name: _INTL("Toxic Thread Push"), desc: _INTL("Toxic Thread pushes enemies harder."), max: 2, rarity: :rare, target_skill: skill_id, effect: :skill_knockback }
    when :night_bolt
      ret << { id: :night_bolt_pressure, name: _INTL("Night Bolt Power"), desc: _INTL("Night Bolt damage +10%."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :night_bolt_edge, name: _INTL("Night Bolt Edge"), desc: _INTL("Night Bolt gains +1 pierce."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_pierce }
    when :shinx_charge
      ret << { id: :shinx_charge_compression, name: _INTL("Spark Break Compression"), desc: _INTL("Spark Break impact damage +10%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :shinx_charge_fragments, name: _INTL("Spark Break Fragments"), desc: _INTL("Spark Break releases one extra impact shot."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_impact }
    when :dragon_pierce
      ret << { id: :dragon_pierce_jaw, name: _INTL("Dragon Fang Jaw"), desc: _INTL("Dragon Fang deals +10% damage."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :dragon_pierce_edge, name: _INTL("Dragon Fang Edge"), desc: _INTL("Dragon Fang pierces one more enemy."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_pierce }
    when :litwick_ghost_bounce
      ret << { id: :litwick_ghost_bounce_rebound, name: _INTL("Spectral Bounce Rebound"), desc: _INTL("Spectral Bounce gains one extra bounce."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_bounce }
      ret << { id: :litwick_ghost_bounce_focus, name: _INTL("Spectral Bounce Power"), desc: _INTL("Spectral Bounce damage +10%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
    when :dragon_pulse
      ret << { id: :dragon_pulse_focus, name: _INTL("Draco Lance Power"), desc: _INTL("Draco Lance deals +10% damage."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :dragon_pulse_flow, name: _INTL("Draco Lance Attack Speed"), desc: _INTL("Draco Lance is ready 6% sooner."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_cooldown_light }
    when :aura_charge
      ret << { id: :aura_charge_snap, name: _INTL("Aura Bolt Attack Speed"), desc: _INTL("Aura Bolt recharge time -6%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_cooldown_light }
      ret << { id: :aura_charge_focus, name: _INTL("Aura Bolt Power"), desc: _INTL("Aura Bolt damage +10%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :aura_charge_impact, name: _INTL("Aura Bolt Impact"), desc: _INTL("Aura Bolt push +8."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_knockback }
    when :toxic_bounce
      ret << { id: :toxic_bounce_venom, name: _INTL("Toxic Ricochet Venom"), desc: _INTL("Toxic Ricochet hits deal +10% damage."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :toxic_bounce_pressure, name: _INTL("Toxic Ricochet Venom"), desc: _INTL("Toxic Ricochet poison deals +1 damage."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_dot_damage }
      ret << { id: :toxic_bounce_rebound, name: _INTL("Toxic Ricochet Rebound"), desc: _INTL("Toxic Ricochet bounces once more."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_bounce }
    when :foxfire_seek
      ret << { id: :foxfire_seek_heat, name: _INTL("Foxfire Arc Heat"), desc: _INTL("Foxfire Arc damage +10%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :foxfire_seek_spark, name: _INTL("Foxfire Arc Spark"), desc: _INTL("Foxfire Arc gains +1 pierce."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_pierce }
    when :hydro_pump
      ret << { id: :hydro_pump_pressure, name: _INTL("Hydro Pump Power"), desc: _INTL("Hydro Pump deals +10% damage."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :hydro_pump_surge, name: _INTL("Hydro Pump Area"), desc: _INTL("Hydro Pump covers more area."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_radius }
      ret << { id: :hydro_pump_force, name: _INTL("Hydro Pump Push"), desc: _INTL("Hydro Pump pushes harder."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_knockback }
    when :leaf_orbit
      ret << { id: :leaf_orbit_power, name: _INTL("Leaf Ring Power"), desc: _INTL("Leaf Ring damage +10%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :leaf_orbit_speed, name: _INTL("Leaf Ring Spin"), desc: _INTL("Leaf Ring rotates faster."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_orbit_speed }
      ret << { id: :leaf_orbit_rebound, name: _INTL("Leaf Ring Rebound"), desc: _INTL("Leaf Ring contact leaves gain one extra bounce."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_bounce }
    when :battery_shuriken
      ret << { id: :battery_shuriken_flow, name: _INTL("Spark Shuriken Attack Speed"), desc: _INTL("Spark Shuriken recharge time -6%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_cooldown_light }
      ret << { id: :battery_shuriken_power, name: _INTL("Spark Shuriken Power"), desc: _INTL("Spark Shuriken damage +10%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :battery_shuriken_stun, name: _INTL("Spark Shuriken Stun"), desc: _INTL("Spark Shuriken paralysis lasts longer."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_freeze }
    when :toxic_scuttle
      ret << { id: :toxic_scuttle_venom, name: _INTL("Toxic Burst Venom"), desc: _INTL("Toxic Burst poison ticks deal +1 damage."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_dot_damage }
      ret << { id: :toxic_scuttle_sparks, name: _INTL("Toxic Burst Fragments"), desc: _INTL("Toxic Burst releases one extra poisonous fragment."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_impact }
      ret << { id: :toxic_scuttle_flow, name: _INTL("Toxic Burst Attack Speed"), desc: _INTL("Toxic Burst recharge time -6%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_cooldown_light }
    when :scale_lance
      ret << { id: :scale_lance_power, name: _INTL("Scale Spear Power"), desc: _INTL("Scale Spear damage +10%."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :scale_lance_speed, name: _INTL("Scale Spear Attack Speed"), desc: _INTL("Scale Spear recharge time -6%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_cooldown_light }
    when :rock_run
      ret << { id: :rock_run_flow, name: _INTL("Rock Rush Attack Speed"), desc: _INTL("Rock Rush recharge time -6%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_cooldown_light }
      ret << { id: :rock_run_force, name: _INTL("Rock Rush Push"), desc: _INTL("Rock Rush pushes enemies harder."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_knockback }
    when :water_shuriken
      ret << { id: :water_shuriken_flow, name: _INTL("Aqua Shuriken Attack Speed"), desc: _INTL("Aqua Shuriken recharge time -6%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_cooldown_light }
      ret << { id: :water_shuriken_rebound, name: _INTL("Aqua Shuriken Rebound"), desc: _INTL("Aqua Shuriken gains one extra bounce."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_bounce }
    when :living_blade
      ret << { id: :living_blade_edge, name: _INTL("Spirit Blade Edge"), desc: _INTL("Spirit Blade damage +10%."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :living_blade_guard, name: _INTL("Spirit Blade Guard"), desc: _INTL("Spirit Blade pushes enemies harder."), max: 2, rarity: :rare, target_skill: skill_id, effect: :skill_knockback }
    when :slime_wave
      ret << { id: :slime_wave_spread, name: _INTL("Dragon Trail Reach"), desc: _INTL("Dragon Trail covers more area."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_radius }
      ret << { id: :slime_wave_pressure, name: _INTL("Dragon Trail Power"), desc: _INTL("Dragon Trail deals +10% damage."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
    when :sonic_wave
      ret << { id: :sonic_wave_echo, name: _INTL("Gale Ring Pair"), desc: _INTL("Gale Ring gains one more orbit."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_count }
      ret << { id: :sonic_wave_tempo, name: _INTL("Gale Ring Attack Speed"), desc: _INTL("Gale Ring recharge time -6%."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_cooldown_light }
    when :fossil_jaw
      ret << { id: :fossil_jaw_crush, name: _INTL("Rock Claw Crush"), desc: _INTL("Rock Claw damage +10%."), max: 4, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :fossil_jaw_force, name: _INTL("Rock Claw Stun"), desc: _INTL("Rock Claw paralysis lasts longer."), max: 2, rarity: :epic, target_skill: skill_id, effect: :skill_freeze }
    when :sky_press
      ret << { id: :sky_press_snap, name: _INTL("Sky Press Attack Speed"), desc: _INTL("Sky Press is ready 6% sooner."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_cooldown_light }
      ret << { id: :sky_press_impact, name: _INTL("Sky Press Impact"), desc: _INTL("Sky Press deals +10% damage."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
    when :twin_mirage
      ret << { id: :twin_mirage_balance, name: _INTL("Twin Mirage Balance"), desc: _INTL("Twin Mirage hits deal +10% damage."), max: 3, rarity: :rare, target_skill: skill_id, effect: :skill_power_light }
      ret << { id: :twin_mirage_rebound, name: _INTL("Twin Mirage Rebound"), desc: _INTL("Twin Mirage ghost shots bounce once more."), max: 1, rarity: :epic, target_skill: skill_id, effect: :skill_bounce }
      ret << { id: :twin_mirage_pressure, name: _INTL("Twin Mirage Push"), desc: _INTL("Twin Mirage normal shots push harder."), max: 2, rarity: :rare, target_skill: skill_id, effect: :skill_knockback }
    end
  rescue
  end
  def update_upgrade
    if !@upgrade_options || @upgrade_options.empty?
      consume_pending_upgrade_choice
      @state = :play
      return
    end
    if @upgrade_anim_mode == :choose
      elapsed = (System.uptime rescue 0.0) - @upgrade_anim_start.to_f
      if elapsed >= 0.50 && !@upgrade_consume_se_played
        @upgrade_consume_se_played = true
        play_survivor_se(:upgrade_consume, "Survivor/Mining reveal", 0.25, PokemonSurvivor::SFX_UPGRADE_CONSUME_VOLUME, 118)
      end
      if elapsed >= 0.92
        apply_upgrade(@upgrade_options[@chosen_upgrade_index || @upgrade_index])
        PokemonSurvivor.gamepad_vibrate_event(:upgrade_take) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
        @upgrade_anim_mode = nil
        @chosen_upgrade_index = nil
        @upgrade_consume_se_played = false
        clear_upgrade_hold_action(true)
        consume_pending_upgrade_choice
        @state = :play
        prepare_next_tower_floor_after_bonus if respond_to?(:prepare_next_tower_floor_after_bonus)
        @accumulator = 0.0
        @last_time = System.uptime rescue @last_time
        return
      end
      draw_upgrade
      return
    end
    @upgrade_anim_mode = nil if @upgrade_anim_mode == :in && (System.uptime rescue 0.0) - @upgrade_anim_start.to_f >= 0.24
    old = @upgrade_index
    @upgrade_index -= 1 if Input.repeat?(Input::LEFT)
    @upgrade_index += 1 if Input.repeat?(Input::RIGHT)
    @upgrade_index = 0 if @upgrade_index < 0
    @upgrade_index = @upgrade_options.length - 1 if @upgrade_index >= @upgrade_options.length
    if old != @upgrade_index
      clear_upgrade_hold_action(true)
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
    end
    if update_upgrade_input_guard
      clear_upgrade_hold_action(false)
      draw_upgrade
      return
    end
    if update_upgrade_hold_action
      draw_upgrade
      return
    end
    if upgrade_confirm_triggered?
      selected_upgrade = @upgrade_options && @upgrade_options[@upgrade_index]
      if PokemonSurvivor.auto_bonus_mode == :semi_auto && tower_mode? && tower_fallback_upgrade?(selected_upgrade) && !@tower_fallback_upgrade_id
        if !confirm_tower_fallback_upgrade(selected_upgrade)
          lock_upgrade_input_from_previous_action
          draw_upgrade
          return
        end
        @tower_fallback_upgrade_id = selected_upgrade[:id]
      end
      @chosen_upgrade_index = @upgrade_index
      @upgrade_anim_mode = :choose
      @upgrade_anim_start = System.uptime rescue 0.0
      @upgrade_consume_se_played = false
      pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
      draw_upgrade
      return
    end
    draw_upgrade
  end

  def consume_pending_upgrade_choice
    if @current_upgrade_kind == :moves
      @pending_move_count = [@pending_move_count.to_i - 1, 0].max
      prune_move_items_if_full
    end
    @current_upgrade_kind = nil
    @pending_upgrade_count = [@pending_upgrade_count.to_i - 1, 0].max
    if @pending_upgrade_count.to_i > 0 && (!@upgrades_exhausted || (@pending_upgrade_queue || []).include?(:moves))
      @pending_upgrade = true
      @upgrade_delay_timer = 0.12
    end
  rescue
    @pending_upgrade_count = 0
    @pending_move_count = 0
    @current_upgrade_kind = nil
    @pending_upgrade = false
  end


  def ensure_passive_upgrade_defaults
    @damage_mult = 1.0 if !@damage_mult
    @cooldown_mult = 1.0 if !@cooldown_mult
    @projectile_count_bonus = 0 if !@projectile_count_bonus
    @pickup_mult = 1.0 if !@pickup_mult
    @xp_gain_mult = 1.0 if !@xp_gain_mult
    @shield_mult = 1.0 if !@shield_mult
    @chest_xp_mult = 1.0 if !@chest_xp_mult
    @enemy_projectile_shield_mult = 1.0 if !@enemy_projectile_shield_mult
    @passive_regen_rate = 0.0 if !@passive_regen_rate
    @vampiric_chance = 0.0 if !@vampiric_chance
    @vampiric_heal_rate = 0.001 if !@vampiric_heal_rate
    @burst_charge_mult = 1.0 if !@burst_charge_mult
    @boss_damage_mult = 1.0 if !@boss_damage_mult
    @bonus_fatal_guard_charges = 0 if @bonus_fatal_guard_charges.nil?
    @bonus_fatal_guard_enabled = @bonus_fatal_guard_charges.to_i > 0 if @bonus_fatal_guard_enabled.nil?
    @bonus_fatal_guard_used = false if @bonus_fatal_guard_used.nil?
    @global_skill_radius_bonus = 0 if @global_skill_radius_bonus.nil?
    @element_focus_mult = 1.0 if !@element_focus_mult
    @status_duration_mult = 1.0 if !@status_duration_mult
    @rare_draft_level = 0 if @rare_draft_level.nil?
    @tower_floor_momentum_level = 0 if @tower_floor_momentum_level.nil?
    @boss_preparation_level = 0 if @boss_preparation_level.nil?
    @overlevel_bonus_rate = 0.0 if @overlevel_bonus_rate.nil?
    @clean_focus_charge_mult = 1.0 if !@clean_focus_charge_mult
    @clean_focus_nohit_timer = 0.0 if @clean_focus_nohit_timer.nil?
    @guarded_heart_mult = 1.0 if !@guarded_heart_mult
    @skill_pierce_bonus = Hash.new(0) if !@skill_pierce_bonus
    @skill_bounce_bonus = Hash.new(0) if !@skill_bounce_bonus
    @skill_impact_bonus = Hash.new(0) if !@skill_impact_bonus
    @skill_dot_damage_bonus = Hash.new(0) if !@skill_dot_damage_bonus
  rescue
  end
  def remove_upgrade_effect(upgrade)
    ensure_passive_upgrade_defaults
    id = upgrade[:id]
    return false if !id || @upgrade_levels[id].to_i <= 0
    if upgrade[:effect]
      skill = upgrade[:target_skill]
      case upgrade[:effect]
      when :skill_power
        @skill_power_mult[skill] /= 1.18 if skill
      when :skill_power_light
        @skill_power_mult[skill] /= 1.10 if skill
      when :skill_cooldown
        @skill_cooldown_mult[skill] /= 0.90 if skill
      when :skill_cooldown_light
        @skill_cooldown_mult[skill] /= 0.94 if skill
      when :skill_radius
        @skill_radius_bonus[skill] = [@skill_radius_bonus[skill].to_i - 8, 0].max if skill
        refresh_dragon_chains if [:dragon_arc, :fairy_arc].include?(skill)
      when :skill_count
        @skill_count_bonus[skill] = [@skill_count_bonus[skill].to_i - 1, 0].max if skill
        refresh_dragon_chains if [:dragon_arc, :fairy_arc].include?(skill)
      when :skill_lines
        @skill_line_bonus[skill] = [@skill_line_bonus[skill].to_i - 1, 0].max if skill
        refresh_dragon_chains if [:dragon_arc, :fairy_arc].include?(skill)
      when :skill_orbit_speed
        @skill_orbit_speed_bonus[skill] = [@skill_orbit_speed_bonus[skill].to_i - 1, 0].max if skill
        refresh_dragon_chains if [:dragon_arc, :fairy_arc].include?(skill)
      when :skill_orbit_speed_plus
        @skill_orbit_speed_bonus[skill] = [@skill_orbit_speed_bonus[skill].to_i - 2, 0].max if skill
        refresh_dragon_chains if [:dragon_arc, :fairy_arc].include?(skill)
      when :skill_knockback
        @skill_knockback_bonus[skill] = [@skill_knockback_bonus[skill].to_i - 8, 0].max if skill
      when :skill_freeze
        @skill_freeze_bonus[skill] = [@skill_freeze_bonus[skill].to_f - 0.25, 0.0].max if skill
      when :skill_pierce
        @skill_pierce_bonus[skill] = [@skill_pierce_bonus[skill].to_i - 1, 0].max if skill
      when :skill_bounce
        @skill_bounce_bonus[skill] = [@skill_bounce_bonus[skill].to_i - 1, 0].max if skill
      when :skill_impact
        @skill_impact_bonus[skill] = [@skill_impact_bonus[skill].to_i - 1, 0].max if skill
      when :skill_dot_damage
        @skill_dot_damage_bonus[skill] = [@skill_dot_damage_bonus[skill].to_i - 1, 0].max if skill
      end
      @upgrade_levels[id] = [@upgrade_levels[id].to_i - 1, 0].max
      return true
    end
    case id
    when :damage
      @damage_mult /= 1.08
    when :damage_plus
      @damage_mult /= 1.15
    when :speed
      @cooldown_mult /= 0.96
    when :speed_plus
      @cooldown_mult /= 0.90
    when :count
      @projectile_count_bonus = [@projectile_count_bonus.to_i - 1, 0].max
    when :move
      @hero.speed /= 1.05 if @hero
    when :move_plus
      @hero.speed /= 1.12 if @hero
    when :max_hp_small
      if @hero
        @hero.max_hp = [@hero.max_hp.to_i - 8, 1].max
        @hero.hp = [@hero.hp.to_i, @hero.max_hp.to_i].min
      end
    when :max_hp
      if @hero
        @hero.max_hp = [@hero.max_hp.to_i - 20, 1].max
        @hero.hp = [@hero.hp.to_i, @hero.max_hp.to_i].min
      end
    when :magnet_small
      @pickup_mult /= 1.12
    when :magnet
      @pickup_mult /= 1.25
    when :expgain_small
      @xp_gain_mult /= 1.05
    when :expgain
      @xp_gain_mult /= 1.15
    when :shield_small
      @shield_mult /= 0.96
    when :shield
      @shield_mult /= 0.92
    when :projectile_guard
      @enemy_projectile_shield_mult /= 0.88
    when :burst_charge
      @burst_charge_mult /= 1.08
    when :burst_charge_plus
      @burst_charge_mult /= 1.15
    when :boss_damage
      @boss_damage_mult /= 1.12
    when :chestxp
      @chest_xp_mult /= 1.35
    when :legend_pulse
      @damage_mult /= 1.15
      @burst_charge_mult /= 1.15
      @projectile_count_bonus = [@projectile_count_bonus.to_i - 1, 0].max
    when :second_wind
      @bonus_fatal_guard_charges = [@bonus_fatal_guard_charges.to_i - 1, 0].max
      @bonus_fatal_guard_enabled = @bonus_fatal_guard_charges.to_i > 0
    when :wide_cast
      @global_skill_radius_bonus = [@global_skill_radius_bonus.to_i - 6, 0].max
      (@learned_skills || []).each { |skill_id| @skill_radius_bonus[skill_id] = [@skill_radius_bonus[skill_id].to_i - 6, 0].max }
    when :quick_recovery
      @skill_cooldown_mult[@hero_skill] /= 0.92 if @hero_skill
    when :element_focus
      @element_focus_mult /= 1.07
    when :status_mastery
      @status_duration_mult /= 1.12
    when :rare_draft
      @rare_draft_level = [@rare_draft_level.to_i - 1, 0].max
    when :floor_momentum
      @tower_floor_momentum_level = [@tower_floor_momentum_level.to_i - 1, 0].max
    when :boss_preparation
      @boss_preparation_level = [@boss_preparation_level.to_i - 1, 0].max
    when :overlevel_instinct
      @overlevel_bonus_rate = [@overlevel_bonus_rate.to_f - 0.002, 0.0].max
    when :clean_focus
      @clean_focus_charge_mult /= 1.06
    when :guarded_heart
      @guarded_heart_mult /= 0.97
    when :tower_run_power
      @damage_mult /= 1.01
    when :lifesteal
      # Recalculated below after the stored level is reduced.
    else
      return false if id.to_s.start_with?("learn_")
    end
    @upgrade_levels[id] = [@upgrade_levels[id].to_i - 1, 0].max
    if id == :lifesteal
      level = @upgrade_levels[id].to_i
      if level <= 0
        @vampiric_chance = 0.0
        @vampiric_heal_rate = 0.0
      else
        ratio = [[(level - 1).to_f / 4.0, 0.0].max, 1.0].min
        @vampiric_chance = 0.005 + (ratio * (1.0 / 150.0 - 0.005))
        @vampiric_heal_rate = 0.001 + (ratio * 0.004)
      end
    end
    true
  rescue
    false
  end
  def apply_upgrade(upgrade)
    return if @breach_run && upgrade[:id] == :lifesteal
    ensure_passive_upgrade_defaults
    id = upgrade[:id]
    return if rush_mode? && rush_disabled_upgrade?(id)
    if upgrade[:skill] && !upgrade[:effect]
      skill = upgrade[:skill]
      return if !PokemonSurvivor::SKILLS[skill] || @learned_skills.include?(skill)
      if [:splash, :fairy_splash].include?(skill)
        return if @learned_skills.include?(replacement_splash_skill(skill))
      end
      return if @learned_skills.length >= PokemonSurvivor::MAX_ACTIVE_SKILLS
      @upgrade_levels[id] += 1
      @learned_skills << skill
      @skill_radius_bonus[skill] += @global_skill_radius_bonus.to_i if @global_skill_radius_bonus.to_i > 0
      @skill_cooldowns[skill] = 0.0
      @upgrades_exhausted = false
      if [:splash, :fairy_splash].include?(skill)
        evolved = @hero && @hero.name.to_s != @hero_base_name.to_s
        if splash_should_transform_after_evolution?(@hero_power_stage, evolved, @hero && @hero.name)
          replace_splash_after_evolution
        end
      end
      prune_move_items_if_full
      start_pending_hero_evolution if @pending_evolution_stage
      return
    end
    @upgrade_levels[id] += 1
    if upgrade[:effect]
      skill = upgrade[:target_skill]
      case upgrade[:effect]
      when :skill_power
        @skill_power_mult[skill] *= 1.18 if skill
      when :skill_power_light
        @skill_power_mult[skill] *= 1.10 if skill
      when :skill_cooldown
        @skill_cooldown_mult[skill] *= 0.90 if skill
      when :skill_cooldown_light
        @skill_cooldown_mult[skill] *= 0.94 if skill
      when :skill_radius
        @skill_radius_bonus[skill] += 8 if skill
        refresh_dragon_chains if [:dragon_arc, :fairy_arc].include?(skill)
      when :skill_count
        @skill_count_bonus[skill] += 1 if skill
        refresh_dragon_chains if [:dragon_arc, :fairy_arc].include?(skill)
      when :skill_lines
        @skill_line_bonus[skill] += 1 if skill
        refresh_dragon_chains if [:dragon_arc, :fairy_arc].include?(skill)
      when :skill_orbit_speed
        @skill_orbit_speed_bonus[skill] += 1 if skill
        refresh_dragon_chains if [:dragon_arc, :fairy_arc].include?(skill)
      when :skill_orbit_speed_plus
        @skill_orbit_speed_bonus[skill] += 2 if skill
        refresh_dragon_chains if [:dragon_arc, :fairy_arc].include?(skill)
      when :skill_knockback
        @skill_knockback_bonus[skill] += 8 if skill
      when :skill_freeze
        @skill_freeze_bonus[skill] += 0.25 if skill
      when :skill_pierce
        @skill_pierce_bonus[skill] += 1 if skill
      when :skill_bounce
        @skill_bounce_bonus[skill] += 1 if skill
      when :skill_impact
        @skill_impact_bonus[skill] += 1 if skill
      when :skill_dot_damage
        @skill_dot_damage_bonus[skill] += 1 if skill
      end
      start_pending_hero_evolution if @pending_evolution_stage
      return
    end
    case id
    when :damage
      @damage_mult *= 1.08
    when :damage_plus
      @damage_mult *= 1.15
    when :speed
      @cooldown_mult *= 0.96
    when :speed_plus
      @cooldown_mult *= 0.90
    when :count
      @projectile_count_bonus += 1
    when :move
      @hero.speed *= 1.05
    when :move_plus
      @hero.speed *= 1.12
    when :max_hp_small
      @hero.max_hp += 8
      @hero.hp = [@hero.hp + 8, @hero.max_hp].min
    when :max_hp
      @hero.max_hp += 20
      @hero.hp = [@hero.hp + 20, @hero.max_hp].min
    when :magnet_small
      @pickup_mult *= 1.12
    when :magnet
      @pickup_mult *= 1.25
    when :expgain_small
      @xp_gain_mult *= 1.05
    when :expgain
      @xp_gain_mult *= 1.15
    when :shield_small
      @shield_mult *= 0.96
    when :shield
      @shield_mult *= 0.92
    when :projectile_guard
      @enemy_projectile_shield_mult *= 0.88
    when :lifesteal
      level = @upgrade_levels[id].to_i
      ratio = [[(level - 1).to_f / 4.0, 0.0].max, 1.0].min
      @vampiric_chance = 0.005 + (ratio * (1.0 / 150.0 - 0.005))
      @vampiric_heal_rate = 0.001 + (ratio * 0.004)
    when :burst_charge
      @burst_charge_mult *= 1.08
    when :burst_charge_plus
      @burst_charge_mult *= 1.15
    when :boss_damage
      @boss_damage_mult *= 1.12
    when :chestxp
      @chest_xp_mult *= 1.35
    when :legend_pulse
      @damage_mult *= 1.15
      @burst_charge_mult *= 1.15
      @projectile_count_bonus += 1
    when :second_wind
      @bonus_fatal_guard_charges = @bonus_fatal_guard_charges.to_i + 1
      @bonus_fatal_guard_enabled = true
      @bonus_fatal_guard_used = false
    when :wide_cast
      @global_skill_radius_bonus = @global_skill_radius_bonus.to_i + 6
      (@learned_skills || []).each { |skill_id| @skill_radius_bonus[skill_id] += 6 }
    when :quick_recovery
      @skill_cooldown_mult[@hero_skill] *= 0.92 if @hero_skill
    when :element_focus
      @element_focus_mult *= 1.07
    when :status_mastery
      @status_duration_mult *= 1.12
    when :rare_draft
      @rare_draft_level = @rare_draft_level.to_i + 1
    when :floor_momentum
      @tower_floor_momentum_level = @tower_floor_momentum_level.to_i + 1
    when :boss_preparation
      @boss_preparation_level = @boss_preparation_level.to_i + 1
    when :overlevel_instinct
      @overlevel_bonus_rate += 0.002
    when :clean_focus
      @clean_focus_charge_mult *= 1.06
    when :guarded_heart
      @guarded_heart_mult *= 0.97
    when :tower_fragment_cache
      PokemonSurvivor.add_shop_currency(25)
    when :tower_first_aid
      if @hero
        heal = [(@hero.max_hp.to_i * 0.005).ceil, 1].max
        @hero.hp = [@hero.hp.to_i + heal, @hero.max_hp.to_i].min
      end
    when :tower_run_power
      @damage_mult *= 1.01
    end
    start_pending_hero_evolution if @pending_evolution_stage
  end

  def update_gameover
    update_gameover_visual_refresh
    if @leaderboard_share_pending
      old = @leaderboard_share_index.to_i
      @leaderboard_share_index = (@leaderboard_share_index.to_i + 1) % 2 if Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)
      if old != @leaderboard_share_index.to_i
        pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue pbPlayCursorSE rescue nil
        draw_gameover
      end
      if upgrade_confirm_triggered?
        pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
        resolve_leaderboard_share_choice(@leaderboard_share_index.to_i == 0)
      elsif survivor_cancel_triggered?
        pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
        resolve_leaderboard_share_choice(false)
      end
      return false
    end
    return_to_select_menu if upgrade_confirm_triggered? || survivor_cancel_triggered?
    false
  end

  def update_gameover_visual_refresh
    now = System.uptime rescue 0.0
    @gameover_anim_time ||= 0.0
    return if now - @gameover_anim_time < 0.016
    @gameover_anim_time = now
    draw_gameover
  rescue
  end
  def return_to_select_menu
    clear_transient_run_state if respond_to?(:clear_transient_run_state)
    @breach_pokemon_picker_active = false
    @breach_pokemon_start_requested = false
    if PokemonSurvivor.respond_to?(:apply_retroactive_unlocks_on_menu_open)
      unlocked = PokemonSurvivor.apply_retroactive_unlocks_on_menu_open
      @post_run_auto_saved = false unless unlocked.empty?
    end
    if respond_to?(:breach_season_slot_unlocked?)
      previously_unlocked = PokemonSurvivor.survivor_progress[:breach_unlocked] == true
      @post_run_auto_saved = false if breach_season_slot_unlocked? && !previously_unlocked
    end
    auto_save_successful_run_once
    @state = :select
    @confirming_hero = false
    dispose_survivor_bitmap_caches
    @heroes = PokemonSurvivor.hero_names.select { |name| PokemonSurvivor::BASE_HERO_KEYS.include?(PokemonSurvivor.species_key(name)) }
    if PokemonSurvivor.const_defined?(:BATTLE_PASS_SLOT_KEY) && PokemonSurvivor.respond_to?(:battle_pass_slot_unlocked?) && PokemonSurvivor.battle_pass_slot_unlocked? && !@heroes.include?(PokemonSurvivor::BATTLE_PASS_SLOT_KEY)
      @heroes.unshift(PokemonSurvivor::BATTLE_PASS_SLOT_KEY)
    end
    @hero_index = [[@hero_index.to_i, 0].max, @heroes.length - 1].min
    refresh_breach_slot if respond_to?(:refresh_breach_slot)
    ensure_select_scroll
    play_survivor_menu_bgm
    draw_select
  rescue
    @state = :select
    draw_select rescue nil
  end



  def auto_save_successful_run_once
    return if @post_run_auto_saved
    @post_run_auto_saved = true
    PlayerShop.prepare_for_save if defined?(PlayerShop) && PlayerShop.respond_to?(:prepare_for_save)
    if defined?(Game) && Game.respond_to?(:save)
      Game.save
      PlayerShop.refresh_all_item_icons_for_current_map if defined?(PlayerShop) && PlayerShop.respond_to?(:refresh_all_item_icons_for_current_map)
    end
  rescue
  end

  def different_save_file_would_be_overwritten?
    return false if !defined?(SaveData) || !SaveData.respond_to?(:exists?)
    return false if !$game_temp || !$game_temp.respond_to?(:begun_new_game)
    SaveData.exists? && $game_temp.begun_new_game
  rescue
    false
  end

end








































