#===============================================================================
# Pokemon Survivor - Battle Pass - data and progression logic
#===============================================================================
module PokemonSurvivor
  BATTLE_PASS_SLOT_KEY = :__BATTLE_PASS_SLOT unless const_defined?(:BATTLE_PASS_SLOT_KEY)
  BATTLE_PASS_REQUIRED_CLASSIC_RUNS = 3 unless const_defined?(:BATTLE_PASS_REQUIRED_CLASSIC_RUNS)
  BATTLE_PASS_MAX_LEVEL = 60 unless const_defined?(:BATTLE_PASS_MAX_LEVEL)
  BATTLE_PASS_XP_PER_LEVEL = 100 unless const_defined?(:BATTLE_PASS_XP_PER_LEVEL)
  BATTLE_PASS_REWARD_RARITY_COLORS = {
    common: Color.new(232, 238, 248),
    rare: Color.new(112, 238, 154),
    super_rare: Color.new(96, 204, 255),
    epic: Color.new(192, 126, 255),
    legendary: Color.new(255, 206, 82)
  }.freeze unless const_defined?(:BATTLE_PASS_REWARD_RARITY_COLORS)
  BATTLE_PASS_QUESTS = [].freeze unless const_defined?(:BATTLE_PASS_QUESTS)
  BATTLE_PASS_DATA = [].freeze unless const_defined?(:BATTLE_PASS_DATA)
  BATTLE_PASS_TEXT_FOR_EXTRACTION = [].freeze unless const_defined?(:BATTLE_PASS_TEXT_FOR_EXTRACTION)
  module_function

  def classic_completed_runs_count
    progress = survivor_progress
    [progress[:classic_completed_runs_count].to_i, (progress[:survived_15] || []).length].max
  rescue
    0
  end

  def battle_pass_slot_unlocked?
    return true if classic_completed_runs_count >= BATTLE_PASS_REQUIRED_CLASSIC_RUNS
    battle_pass_store.each_value do |entry|
      if entry.is_a?(Hash)
        return true if (entry[:unlocked] || entry["unlocked"] || 0).to_i > 0
      else
        return true if (entry || 0).to_i > 0
      end
    end
    false
  rescue
    false
  end

  def battle_pass_store
    progress = survivor_progress
    progress[:battle_passes] = {} if !progress[:battle_passes].is_a?(Hash)
    progress[:battle_passes]
  rescue
    {}
  end

  def battle_pass_entry(id)
    store = battle_pass_store
    key = id.to_sym
    string_key = key.to_s
    previous = store[key]
    if previous.nil? && store.key?(string_key)
      previous = store[string_key]
      store.delete(string_key)
    end
    store[key] = previous.is_a?(Hash) ? previous : {}
    entry = store[key]
    if previous.is_a?(Hash)
      entry[:unlocked] = 1 if (previous["unlocked"] || 0).to_i > 0 || (previous[:unlocked] || 0).to_i > 0
      entry[:xp] = previous["xp"] if entry[:xp].nil? && previous.key?("xp")
      entry[:claimed_quests] = previous["claimed_quests"] if !entry[:claimed_quests].is_a?(Hash) && previous["claimed_quests"].is_a?(Hash)
      entry[:claimed_rewards] = previous["claimed_rewards"] if !entry[:claimed_rewards].is_a?(Hash) && previous["claimed_rewards"].is_a?(Hash)
    else
      entry[:unlocked] = 1 if (previous || 0).to_i > 0
    end
    entry[:xp] = (entry[:xp] || 0).to_i
    entry[:claimed_quests] = {} if !entry[:claimed_quests].is_a?(Hash)
    entry[:claimed_rewards] = {} if !entry[:claimed_rewards].is_a?(Hash)
    entry[:claimed_quests].keys.grep(String).each do |old_key|
      value = entry[:claimed_quests].delete(old_key).to_i
      key_id = old_key.to_sym
      entry[:claimed_quests][key_id] = [entry[:claimed_quests][key_id].to_i, value].max
    end
    entry[:claimed_rewards].keys.grep(String).each do |old_key|
      value = entry[:claimed_rewards].delete(old_key).to_i
      tier = old_key.to_i
      entry[:claimed_rewards][tier] = [entry[:claimed_rewards][tier].to_i, value].max
    end
    store[key] = entry
    entry
  rescue
    { xp: 0, claimed_quests: {}, claimed_rewards: {} }
  end
  def battle_pass_unlocked?(id)
    entry = battle_pass_entry(id)
    return (entry[:unlocked] || entry["unlocked"] || 0).to_i > 0 if entry.is_a?(Hash)
    return true if (entry || 0).to_i > 0
    false
  rescue
    false
  end

  def battle_pass_level(pass)
    xp = battle_pass_entry(pass[:id])[:xp].to_i
    [[1 + (xp / BATTLE_PASS_XP_PER_LEVEL.to_i), 1].max, BATTLE_PASS_MAX_LEVEL.to_i].min
  rescue
    1
  end

  def battle_pass_xp_into_level(pass)
    return 0 if battle_pass_level(pass) >= BATTLE_PASS_MAX_LEVEL.to_i
    battle_pass_entry(pass[:id])[:xp].to_i % BATTLE_PASS_XP_PER_LEVEL.to_i
  rescue
    0
  end

  def battle_pass_add_xp(pass, amount)
    entry = battle_pass_entry(pass[:id])
    max_xp = (BATTLE_PASS_MAX_LEVEL.to_i - 1) * BATTLE_PASS_XP_PER_LEVEL.to_i
    entry[:xp] = [[entry[:xp].to_i + amount.to_i, 0].max, max_xp].min
    entry[:xp]
  rescue
    0
  end

  def battle_pass_stats
    progress = survivor_progress
    progress[:battle_pass_stats] = {} if !progress[:battle_pass_stats].is_a?(Hash)
    stats = progress[:battle_pass_stats]
    [:runs, :wins, :classic_runs, :rush_runs, :tower_runs, :endless_runs, :endless_seconds, :kills, :score, :highest_level,
     :magikarp_runs, :magikarp_wins, :magikarp_kills, :magikarp_highest_level,
     :feebas_runs, :feebas_wins, :feebas_kills, :feebas_highest_level].each { |k| stats[k] = stats[k].to_i }
    stats
  rescue
    {}
  end

  def battle_pass_record_run(scene)
    return if !scene || (scene.instance_variable_get(:@run_abandoned) rescue false)
    stats = battle_pass_stats
    mode = scene.instance_variable_get(:@run_mode) rescue nil
    timer = scene.instance_variable_get(:@timer).to_f rescue 0.0
    stats[:runs] = stats[:runs].to_i + 1
    stats[:kills] = stats[:kills].to_i + (scene.instance_variable_get(:@kills).to_i rescue 0)
    stats[:score] = stats[:score].to_i + (scene.instance_variable_get(:@score).to_i rescue 0)
    level = scene.instance_variable_get(:@level).to_i rescue 1
    kills = scene.instance_variable_get(:@kills).to_i rescue 0
    won = scene.respond_to?(:leaderboard_run_won?) && scene.leaderboard_run_won?
    base = species_key(scene.instance_variable_get(:@hero_base_name) || scene.instance_variable_get(:@hero_name) || (scene.instance_variable_get(:@hero).name rescue nil))
    stats[:highest_level] = [stats[:highest_level].to_i, level].max
    stats[:wins] = stats[:wins].to_i + 1 if won
    if base == :MAGIKARP
      stats[:magikarp_runs] = stats[:magikarp_runs].to_i + 1
      stats[:magikarp_kills] = stats[:magikarp_kills].to_i + kills
      stats[:magikarp_highest_level] = [stats[:magikarp_highest_level].to_i, level].max
      stats[:magikarp_wins] = stats[:magikarp_wins].to_i + 1 if won
    elsif base == :FEEBAS
      stats[:feebas_runs] = stats[:feebas_runs].to_i + 1
      stats[:feebas_kills] = stats[:feebas_kills].to_i + kills
      stats[:feebas_highest_level] = [stats[:feebas_highest_level].to_i, level].max
      stats[:feebas_wins] = stats[:feebas_wins].to_i + 1 if won
    end
    case mode
    when :rush
      stats[:rush_runs] = stats[:rush_runs].to_i + 1
    when :tower
      stats[:tower_runs] = stats[:tower_runs].to_i + 1
    when :endless
      stats[:endless_runs] = stats[:endless_runs].to_i + 1
      stats[:endless_seconds] = stats[:endless_seconds].to_i + timer.to_i
    else
      stats[:classic_runs] = stats[:classic_runs].to_i + 1
    end
    true
  rescue
    false
  end

  def battle_pass_quest_list(pass)
    quests = pass && pass[:quests].is_a?(Array) ? pass[:quests] : nil
    quests = BATTLE_PASS_QUESTS if !quests && const_defined?(:BATTLE_PASS_QUESTS)
    quests || []
  rescue
    []
  end
  def battle_pass_quest_progress(quest)
    battle_pass_stats[quest[:metric]].to_i
  rescue
    0
  end

  def battle_pass_quest_complete?(quest)
    battle_pass_quest_progress(quest) >= quest[:target].to_i
  rescue
    false
  end

  def battle_pass_quest_claimed?(pass, quest)
    battle_pass_entry(pass[:id])[:claimed_quests][quest[:id].to_sym].to_i > 0
  rescue
    false
  end

  def battle_pass_claim_quest(pass, quest)
    return :locked if !battle_pass_unlocked?(pass[:id])
    return :claimed if battle_pass_quest_claimed?(pass, quest)
    return :incomplete if !battle_pass_quest_complete?(quest)
    entry = battle_pass_entry(pass[:id])
    entry[:claimed_quests][quest[:id].to_sym] = 1
    battle_pass_add_xp(pass, quest[:xp].to_i)
    true
  rescue
    :incomplete
  end

  def battle_pass_restore_claimed_reward_unlocks
    return false if !const_defined?(:BATTLE_PASS_DATA)
    BATTLE_PASS_DATA.each do |pass|
      entry = battle_pass_entry(pass[:id])
      claimed = entry[:claimed_rewards]
      next if !claimed.is_a?(Hash)
      battle_pass_reward_list(pass).each do |reward|
        next if claimed[reward[:tier].to_i].to_i <= 0
        battle_pass_apply_claimed_reward_unlock(reward)
      end
    end
    true
  rescue
    false
  end
  def battle_pass_reward_list(pass)
    rewards = pass && pass[:rewards].is_a?(Array) ? pass[:rewards] : []
    return rewards.map { |reward| battle_pass_normalize_reward(reward) } if !rewards.empty?
    []
  rescue
    []
  end

  def battle_pass_normalize_reward(reward)
    ret = reward.clone rescue {}
    ret[:tier] = [ret[:tier].to_i, 1].max
    ret[:kind] = (ret[:kind] || ret[:type] || :fragment).to_sym rescue :fragment
    ret[:hero] = ret[:id] if ret[:kind] == :hero && ret[:hero].nil? && ret[:id]
    ret[:equipment] = ret[:id] if ret[:kind] == :equipment && ret[:equipment].nil? && ret[:id]
    ret[:amount] = [ret[:amount].to_i, 1].max
    ret[:rarity] = (ret[:rarity] || :common).to_sym rescue :common
    ret[:icon] = ret[:icon].to_s
    ret[:name] = ret[:name].to_s.empty? ? battle_pass_reward_item_name(ret) : ret[:name].to_s
    if ret[:icon].empty?
      ret[:icon] = case ret[:kind]
                   when :candy then "ICON_CANDY"
                   when :fragment then "ICON_FRAGMENT"
                   when :dark_fragment then "ICON_DARKFRAGMENT"
                   when :hero then (ret[:hero] || ret[:name]).to_s
                   when :equipment
                     item = equipment_data(ret[:equipment]) if respond_to?(:equipment_data)
                     icon = item && item[:icon].to_s
                     icon && !icon.empty? ? icon : ret[:name]
                   else ret[:name]
                   end
    end
    ret
  rescue
    reward
  end

  def battle_pass_reward_item_name(reward)
    case reward[:kind]
    when :hero
      species_name(reward[:hero] || reward[:name])
    when :equipment
      item = equipment_data(reward[:equipment]) if respond_to?(:equipment_data)
      item ? item[:name].to_s : reward[:name].to_s
    when :candy
      "Candies"
    when :fragment, :dark_fragment
      "Fragments"
    else
      reward[:name].to_s
    end
  rescue
    reward[:name].to_s
  end
  def battle_pass_reward_claimed?(pass, reward)
    claimed = battle_pass_entry(pass[:id])[:claimed_rewards][reward[:tier].to_i].to_i > 0
    battle_pass_apply_claimed_reward_unlock(reward) if claimed
    claimed
  rescue
    false
  end

  def battle_pass_apply_claimed_reward_unlock(reward)
    case reward[:kind]
    when :hero
      unlock_hero(reward[:hero] || reward[:name]) if respond_to?(:unlock_hero)
    when :equipment
      unlock_equipment_item(reward[:equipment]) if respond_to?(:unlock_equipment_item)
    end
    true
  rescue
    false
  end
  def battle_pass_claim_reward(pass, reward)
    return :locked if !battle_pass_unlocked?(pass[:id])
    return :claimed if battle_pass_reward_claimed?(pass, reward)
    return :level_locked if battle_pass_level(pass) < reward[:tier].to_i
    case reward[:kind]
    when :candy
      add_candy_currency(reward[:amount].to_i) if respond_to?(:add_candy_currency)
    when :fragment
      add_shop_currency(reward[:amount].to_i) if respond_to?(:add_shop_currency)
    when :dark_fragment
      add_shop_currency(reward[:amount].to_i * 1000) if respond_to?(:add_shop_currency)
    when :hero
      unlock_hero(reward[:hero] || reward[:name]) if respond_to?(:unlock_hero)
    when :equipment
      unlock_equipment_item(reward[:equipment]) if respond_to?(:unlock_equipment_item)
    end
    battle_pass_entry(pass[:id])[:claimed_rewards][reward[:tier].to_i] = 1
    if defined?(PokemonSurvivorAchievements) && pass[:id].to_sym == :battle_pass_1 && battle_pass_completed?(pass)
      PokemonSurvivorAchievements.check([:battle_pass_tome1_complete], true) rescue nil
    end
    PokemonSurvivorAchievements.check_additional_counters(true, :battle_pass) if defined?(PokemonSurvivorAchievements)
    true  rescue
    :locked
  end

  def battle_pass_completed?(pass)
    return false if !pass || !battle_pass_unlocked?(pass[:id])
    rewards = battle_pass_reward_list(pass)
    return false if rewards.empty?
    battle_pass_level(pass) >= BATTLE_PASS_MAX_LEVEL.to_i && rewards.all? { |reward| battle_pass_reward_claimed?(pass, reward) }
  rescue
    false
  end

  # Battle Pass tomes are unlocked strictly in BATTLE_PASS_DATA order.
  # Tome 1 has no predecessor. Every future Tome N requires Tome N-1 to be
  # fully completed before it can be purchased/activated. No date or online
  # verification is involved.
  def battle_pass_data_index(pass_or_id)
    id = pass_or_id.is_a?(Hash) ? pass_or_id[:id] : pass_or_id
    return nil if id.nil?
    BATTLE_PASS_DATA.index { |entry| entry[:id].to_sym == id.to_sym }
  rescue
    nil
  end

  def previous_battle_pass(pass)
    index = battle_pass_data_index(pass)
    return nil if index.nil? || index <= 0
    BATTLE_PASS_DATA[index - 1]
  rescue
    nil
  end

  def battle_pass_previous_completed?(pass)
    previous = previous_battle_pass(pass)
    return true if !previous
    battle_pass_completed?(previous)
  rescue
    false
  end

  def battle_pass_unlock_requirement_met?(pass)
    battle_pass_previous_completed?(pass)
  rescue
    false
  end

  def unlock_battle_pass(pass)
    return :already if battle_pass_unlocked?(pass[:id])
    return :previous_locked if !battle_pass_unlock_requirement_met?(pass)
    cost = pass[:cost].to_i
    return :not_enough_candies if cost > 0 && candy_currency < cost
    return :not_enough_candies if cost > 0 && !spend_candy_currency(cost)
    battle_pass_entry(pass[:id])[:unlocked] = 1
    true
  rescue
    :previous_locked
  end


end


