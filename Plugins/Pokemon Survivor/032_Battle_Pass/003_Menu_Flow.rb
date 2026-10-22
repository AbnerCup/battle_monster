#===============================================================================
# Pokemon Survivor - Battle Pass - menu state and navigation
#===============================================================================
class Scene_PokemonSurvivor
  prepend PokemonSurvivorBattlePassSceneHooks unless ancestors.include?(PokemonSurvivorBattlePassSceneHooks)

  if method_defined?(:draw_select) && !method_defined?(:battle_pass_original_draw_select)
    alias battle_pass_original_draw_select draw_select
    def draw_select
      refresh_battle_pass_slot
      battle_pass_original_draw_select
    end
  end

  if method_defined?(:update_select) && !method_defined?(:battle_pass_original_update_select)
    alias battle_pass_original_update_select update_select
    def update_select
      refresh_battle_pass_slot
      if @select_focus != :shop && battle_pass_slot_key?(selected_hero_name)
        @confirming_hero = false
        if survivor_confirm_triggered?
          open_battle_pass_menu
          return
        end
      end
      battle_pass_original_update_select
      @confirming_hero = false if @select_focus != :shop && battle_pass_slot_key?(selected_hero_name)
    end
  end

  def battle_pass_slot_key?(key)
    key == PokemonSurvivor::BATTLE_PASS_SLOT_KEY
  rescue
    false
  end

  def refresh_battle_pass_slot
    @heroes ||= []
    had = @heroes.include?(PokemonSurvivor::BATTLE_PASS_SLOT_KEY)
    should = PokemonSurvivor.battle_pass_slot_unlocked?
    return if had == should && (!should || @heroes.first == PokemonSurvivor::BATTLE_PASS_SLOT_KEY)
    current = @heroes[@hero_index.to_i]
    @heroes.delete(PokemonSurvivor::BATTLE_PASS_SLOT_KEY)
    @heroes.unshift(PokemonSurvivor::BATTLE_PASS_SLOT_KEY) if should
    @hero_index = @heroes.index(current) || 0
    @hero_scroll_row = 0 if @hero_index.to_i == 0
  rescue
  end


  def refresh_select_heroes_after_battle_pass_claim(preferred = nil)
    current = preferred || selected_hero_name
    @heroes = PokemonSurvivor.hero_names.select { |name| PokemonSurvivor::BASE_HERO_KEYS.include?(PokemonSurvivor.species_key(name)) }
    @heroes.unshift(PokemonSurvivor::BATTLE_PASS_SLOT_KEY) if PokemonSurvivor.battle_pass_slot_unlocked? && !@heroes.include?(PokemonSurvivor::BATTLE_PASS_SLOT_KEY)
    @hero_index = @heroes.index(current) || @heroes.index(PokemonSurvivor.species_key(current).to_s) || @hero_index.to_i
    @hero_index = [[@hero_index.to_i, 0].max, [@heroes.length - 1, 0].max].min
    refresh_breach_slot if respond_to?(:refresh_breach_slot)
    @hero_scroll_row = 0 if @hero_index.to_i == 0
    true
  rescue
    false
  end
  def draw_battle_pass_select_slot(bitmap, x, y, w, h, selected)
    edge = selected ? Color.new(255, 224, 92) : Color.new(245, 198, 92)
    fill = selected ? Color.new(70, 58, 96) : Color.new(34, 30, 52)
    draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(4, 7, 14))
    draw_pixel_round_rect(bitmap, x + 1, y + 1, w - 2, h - 2, edge)
    draw_pixel_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, Color.new(8, 13, 26))
    draw_pixel_round_rect(bitmap, x + 3, y + 3, w - 6, h - 6, fill)
    phase = (System.uptime rescue 0.0) * 10.0
    ox = (Math.sin(phase) * 1.5).round
    oy = (Math.cos(phase * 0.75) * 1.0).round
    icon = cached_icon_bitmap("ICON_BATTLEPASS") rescue nil
    if icon && !icon.disposed?
      bitmap.blt(x + ((w - icon.width) / 2) + ox, y + ((h - icon.height) / 2) + oy, icon, Rect.new(0, 0, icon.width, icon.height))
    else
      PokemonSurvivor.draw_text_center(bitmap, "BP", x, y + 28, w, Color.new(255, 238, 160), Color.new(30, 30, 38))
    end
    draw_menu_notification(bitmap, x, y) if battle_pass_notification?
  rescue
  end

  def open_battle_pass_menu
    @battle_pass_index = 0
    @battle_pass_reward_index = 0
    @battle_pass_quest_index = 0
    @battle_pass_scroll_x = 0.0
    @battle_pass_target_scroll_x = 0.0
    @battle_pass_menu_scroll_y = 0.0
    @battle_pass_menu_target_scroll_y = 0.0
    @battle_pass_redraw_frame = -1
    pbSEPlay("Survivor/GUI menu open", PokemonSurvivor::UI_MENU_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    loop do
      Graphics.update
      Input.update
      update_battle_pass_menu
      break if @state != :battle_pass_menu
    end
    draw_select
  rescue
    @state = :select
    draw_select rescue nil
  end

  def update_battle_pass_menu
    @state = :battle_pass_menu
    passes = PokemonSurvivor::BATTLE_PASS_DATA
    return close_battle_pass_menu if !passes || passes.empty?
    old_pass = @battle_pass_index.to_i
    @battle_pass_index = (@battle_pass_index.to_i - 1) % passes.length if Input.repeat?(Input::UP)
    @battle_pass_index = (@battle_pass_index.to_i + 1) % passes.length if Input.repeat?(Input::DOWN)
    sync_battle_pass_menu_scroll if old_pass != @battle_pass_index.to_i
    @battle_pass_reward_index = 0 if old_pass != @battle_pass_index.to_i
    pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil if old_pass != @battle_pass_index.to_i
    if survivor_confirm_triggered?
      resolve_battle_pass_selection(passes[@battle_pass_index.to_i], true)
    elsif survivor_cancel_triggered?
      close_battle_pass_menu
      return
    end
    draw_battle_pass_menu
  rescue
    close_battle_pass_menu
  end

  def battle_pass_menu_height
    [Graphics.height - 46, 414].min
  end

  def battle_pass_menu_list_height
    [222, battle_pass_menu_height - 124].min
  end

  def sync_battle_pass_menu_scroll
    passes = PokemonSurvivor::BATTLE_PASS_DATA
    return if !passes || passes.empty?
    card_h = 86
    gap = 14
    view_h = battle_pass_menu_list_height
    total_h = passes.length * card_h + [passes.length - 1, 0].max * gap
    max_scroll = [total_h - view_h, 0].max
    current = [[@battle_pass_menu_target_scroll_y.to_f, 0.0].max, max_scroll].min
    selected_y = @battle_pass_index.to_i * (card_h + gap)
    wanted = current
    wanted = selected_y if selected_y < current
    wanted = selected_y + card_h - view_h if selected_y + card_h > current + view_h
    @battle_pass_menu_target_scroll_y = [[wanted, 0].max, max_scroll].min
    @battle_pass_menu_scroll_y = @battle_pass_menu_target_scroll_y if @battle_pass_menu_scroll_y.nil?
  rescue
    @battle_pass_menu_target_scroll_y = 0.0
    @battle_pass_menu_scroll_y = 0.0
  end

  def close_battle_pass_menu
    @state = :select
    pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
  rescue
    @state = :select
  end

  def open_battle_pass_content(pass)
    @battle_pass_content_id = pass[:id]
    @battle_pass_reward_index = 0
    @battle_pass_quest_index = 0
    @battle_pass_scroll_x = 0.0
    @battle_pass_target_scroll_x = 0.0
    pbSEPlay("Survivor/GUI menu open", PokemonSurvivor::UI_MENU_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    loop do
      Graphics.update
      Input.update
      update_battle_pass_content
      break if @state != :battle_pass_content
    end
  rescue
    @state = :battle_pass_menu
  end

  def open_battle_pass_quest_menu
    @battle_pass_quest_index ||= 0
    pbSEPlay("Survivor/GUI menu open", PokemonSurvivor::UI_MENU_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    loop do
      Graphics.update
      Input.update
      update_battle_pass_quest_menu
      break if @state != :battle_pass_quests
    end
    @state = :battle_pass_content if @state == :battle_pass_quest_return
  rescue
    @state = :battle_pass_content
  end
  def update_battle_pass_content
    @state = :battle_pass_content
    old_reward = @battle_pass_reward_index.to_i
    rewards = battle_pass_rewards_for_selected
    @battle_pass_reward_index = [@battle_pass_reward_index.to_i, rewards.length - 1].min
    @battle_pass_reward_index = 0 if @battle_pass_reward_index < 0
    @battle_pass_reward_index = (@battle_pass_reward_index.to_i - 1) % rewards.length if rewards.length > 0 && Input.repeat?(Input::LEFT)
    @battle_pass_reward_index = (@battle_pass_reward_index.to_i + 1) % rewards.length if rewards.length > 0 && Input.repeat?(Input::RIGHT)
    update_battle_pass_target_scroll if old_reward != @battle_pass_reward_index.to_i
    pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil if old_reward != @battle_pass_reward_index.to_i
    if battle_pass_auto_claim_triggered?
      auto_claim_ready_battle_pass_rewards
      return
    elsif survivor_confirm_triggered?
      claim_selected_battle_pass_reward
    elsif battle_pass_reward_claim_triggered?
      open_battle_pass_quest_menu
      return
    elsif survivor_cancel_triggered?
      @state = :battle_pass_menu
      pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
      return
    end
    draw_battle_pass_content
  rescue
    @state = :battle_pass_menu
  end

  def update_battle_pass_quest_menu
    @state = :battle_pass_quests
    quests = PokemonSurvivor.battle_pass_quest_list(selected_battle_pass)
    old_quest = @battle_pass_quest_index.to_i
    @battle_pass_quest_index = [@battle_pass_quest_index.to_i, quests.length - 1].min
    @battle_pass_quest_index = 0 if @battle_pass_quest_index < 0
    @battle_pass_quest_index = (@battle_pass_quest_index.to_i - 1) % quests.length if quests.length > 0 && Input.repeat?(Input::UP)
    @battle_pass_quest_index = (@battle_pass_quest_index.to_i + 1) % quests.length if quests.length > 0 && Input.repeat?(Input::DOWN)
    pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil if old_quest != @battle_pass_quest_index.to_i
    if battle_pass_auto_claim_triggered?
      auto_claim_ready_battle_pass_quests
      return
    elsif survivor_confirm_triggered?
      claim_selected_battle_pass_quest
    elsif survivor_cancel_triggered? || battle_pass_reward_claim_triggered?
      @state = :battle_pass_quest_return
      pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
      return
    end
    draw_battle_pass_quest_menu
  rescue
    @state = :battle_pass_quest_return
  end
  def battle_pass_reward_claim_triggered?
    return PokemonSurvivor.control_trigger?(:menu) if PokemonSurvivor.respond_to?(:control_trigger?)
    return true if Input.const_defined?(:MENU) && Input.const_defined?(:ACTION) && Input::MENU != Input::ACTION && Input.trigger?(Input::MENU)
    false
  rescue
    false
  end

  def battle_pass_auto_claim_triggered?
    return select_action_triggered? if respond_to?(:select_action_triggered?)
    return PokemonSurvivor.control_trigger?(:action) if PokemonSurvivor.respond_to?(:control_trigger?)
    return true if Input.const_defined?(:ACTION) && Input.trigger?(Input::ACTION)
    false
  rescue
    false
  end

  def auto_claim_ready_battle_pass_rewards
    pass = selected_battle_pass
    rewards = battle_pass_rewards_for_selected
    return if !pass || rewards.empty?
    level = PokemonSurvivor.battle_pass_level(pass)
    farthest = 0
    claimed = 0
    preferred = nil
    rewards.each_with_index do |reward, index|
      next if !reward
      farthest = index if level.to_i >= reward[:tier].to_i
      next if level.to_i < reward[:tier].to_i
      next if PokemonSurvivor.battle_pass_reward_claimed?(pass, reward)
      result = PokemonSurvivor.battle_pass_claim_reward(pass, reward)
      if result == true
        claimed += 1
        preferred = PokemonSurvivor.species_key(reward[:hero]).to_s if reward[:kind] == :hero
      end
    end
    @battle_pass_reward_index = [[farthest.to_i, 0].max, [rewards.length - 1, 0].max].min
    update_battle_pass_target_scroll
    refresh_select_heroes_after_battle_pass_claim(preferred) if claimed > 0 && respond_to?(:refresh_select_heroes_after_battle_pass_claim)
    if claimed > 0
      pbSEPlay("Mart buy item", 72, 118) rescue pbPlayDecisionSE rescue nil
      pbMessage(claimed == 1 ? _INTL("Reward claimed.") : _INTL("{1} rewards claimed.", claimed)) rescue nil
    else
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
    end
    draw_battle_pass_content
  rescue
    draw_battle_pass_content rescue nil
  end
  def auto_claim_ready_battle_pass_quests
    pass = selected_battle_pass
    quests = PokemonSurvivor.battle_pass_quest_list(selected_battle_pass)
    return if !pass || quests.empty?
    claimed = 0
    farthest = @battle_pass_quest_index.to_i
    quests.each_with_index do |quest, index|
      next if !quest
      next if !PokemonSurvivor.battle_pass_quest_complete?(quest)
      next if PokemonSurvivor.battle_pass_quest_claimed?(pass, quest)
      result = PokemonSurvivor.battle_pass_claim_quest(pass, quest)
      if result == true
        claimed += 1
        farthest = index
      end
    end
    @battle_pass_quest_index = [[farthest.to_i, 0].max, [quests.length - 1, 0].max].min
    if claimed > 0
      pbSEPlay("Mart buy item", 72, 118) rescue pbPlayDecisionSE rescue nil
      pbMessage(claimed == 1 ? _INTL("Quest completed.") : _INTL("{1} quests completed.", claimed)) rescue nil
    else
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
    end
    draw_battle_pass_quest_menu
  rescue
    draw_battle_pass_quest_menu rescue nil
  end
  def claim_selected_battle_pass_quest
    pass = selected_battle_pass
    quest = PokemonSurvivor.battle_pass_quest_list(selected_battle_pass)[@battle_pass_quest_index.to_i]
    result = PokemonSurvivor.battle_pass_claim_quest(pass, quest)
    case result
    when true
      pbSEPlay("Mart buy item", 72, 118) rescue pbPlayDecisionSE rescue nil
      pbMessage(_INTL("Quest completed.")) rescue nil
    when :claimed
      pbPlayBuzzerSE rescue nil
      pbMessage(_INTL("This quest has already been claimed.")) rescue nil
    else
      pbPlayBuzzerSE rescue nil
      pbMessage(_INTL("This quest is not complete yet.")) rescue nil
    end
  rescue
  end

  def claim_selected_battle_pass_reward
    pass = selected_battle_pass
    reward = battle_pass_rewards_for_selected[@battle_pass_reward_index.to_i]
    result = PokemonSurvivor.battle_pass_claim_reward(pass, reward)
    case result
    when true
      refresh_select_heroes_after_battle_pass_claim(PokemonSurvivor.species_key(reward[:hero]).to_s) if reward && reward[:kind] == :hero
      pbSEPlay("Mart buy item", 72, 118) rescue pbPlayDecisionSE rescue nil
      pbMessage(_INTL("Reward claimed.")) rescue nil
    when :claimed
      pbPlayBuzzerSE rescue nil
      pbMessage(_INTL("This reward has already been claimed.")) rescue nil
    when :level_locked
      pbPlayBuzzerSE rescue nil
      pbMessage(_INTL("Reach Battle Pass level {1} to claim this reward.", reward[:tier].to_i)) rescue nil
    end
  rescue
  end
  def selected_battle_pass
    id = @battle_pass_content_id
    return PokemonSurvivor::BATTLE_PASS_DATA.find { |pass| pass[:id] == id } if id
    PokemonSurvivor::BATTLE_PASS_DATA[@battle_pass_index.to_i] || PokemonSurvivor::BATTLE_PASS_DATA.first
  rescue
    PokemonSurvivor::BATTLE_PASS_DATA.first
  end

  def resolve_battle_pass_selection(pass, open_after_unlock = false)
    if PokemonSurvivor.battle_pass_unlocked?(pass[:id])
      open_battle_pass_content(pass)
      return
    end
    result = PokemonSurvivor.unlock_battle_pass(pass)
    case result
    when true
      pbSEPlay("Mart buy item", 80, 100) rescue pbPlayDecisionSE rescue nil
      pbMessage(_INTL("{1} unlocked!", _INTL(pass[:name].to_s))) rescue nil
      open_battle_pass_content(pass) if open_after_unlock
    when :already
      pbPlayDecisionSE rescue nil
      open_battle_pass_content(pass)
    when :previous_locked
      pbPlayBuzzerSE rescue nil
      pbMessage(_INTL("Complete the previous Tome to unlock this Battle Pass.")) rescue nil
    when :not_enough_candies
      pbPlayBuzzerSE rescue nil
      pbMessage(_INTL("Not enough Candies.")) rescue nil
    end
  rescue
  end

  def battle_pass_rewards_for_selected
    pass = selected_battle_pass
    PokemonSurvivor.battle_pass_reward_list(pass)
  rescue
    []
  end

  def update_battle_pass_target_scroll
    rewards = battle_pass_rewards_for_selected
    card_w = 128
    gap = 14
    track_w = Graphics.width - 16
    selected_center = gap + @battle_pass_reward_index.to_i * (card_w + gap) + (card_w / 2)
    @battle_pass_target_scroll_x = selected_center - (track_w / 2)
    max_scroll = [gap + rewards.length * (card_w + gap) - track_w, 0].max
    @battle_pass_target_scroll_x = [[@battle_pass_target_scroll_x, 0].max, max_scroll].min
  rescue
    @battle_pass_target_scroll_x = 0
  end
end




