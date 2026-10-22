#===============================================================================
# Pokemon Survivor - menu notification badges (local state only)
#===============================================================================
class Scene_PokemonSurvivor
  def draw_menu_notification(bitmap, x, y)
    icon = cached_bitmap(PokemonSurvivor::ICON_DIR, "NOTIFICATION")
    return if !icon || icon.disposed?
    bitmap.blt(x - 3, y - 3, icon, Rect.new(0, 0, icon.width, icon.height))
  end

  def menu_notification_cached(key)
    @menu_notification_cache ||= {}
    now = System.uptime
    owner = PokemonSurvivor.survivor_progress.object_id
    entry = @menu_notification_cache[key]
    return entry[2] if entry && entry[0] == owner && now >= entry[1] && now - entry[1] < 0.25
    value = !!yield
    @menu_notification_cache[key] = [owner, now, value]
    value
  end

  def menu_notification_seen
    progress = PokemonSurvivor.survivor_progress
    progress[:menu_notification_seen] = {} unless progress[:menu_notification_seen].is_a?(Hash)
    progress[:menu_notification_seen]
  end

  def achievements_notification?
    menu_notification_cached(:achievements) do
      seen = menu_notification_seen[:achievements] || []
      PokemonSurvivorAchievements.progress.any? { |id, value| value && !seen.include?(id) }
    end
  end

  def mark_achievement_notifications_seen
    menu_notification_seen[:achievements] = PokemonSurvivorAchievements.progress.select { |_id, value| value }.keys
    @menu_notification_cache = nil
  end

  def equipment_notification?(pokemon)
    menu_notification_cached([:equipment, pokemon]) do
      next false unless PokemonSurvivor.pokemon_equipment_slot_unlocked?(pokemon)
      seen = menu_notification_seen[:equipment] || []
      PokemonSurvivor.available_equipment_items.any? do |item|
        !seen.include?(item[:id]) &&
          !(item[:effect] == :eevee_stone && PokemonSurvivor.species_key(pokemon) != :EEVEE) &&
          PokemonSurvivor.equipment_species_compatible?(pokemon, item)
      end
    end
  end

  def mark_equipment_notifications_seen(items)
    seen = menu_notification_seen
    seen[:equipment] = ((seen[:equipment] || []) + items.map { |item| item[:id] }.compact).uniq
    @menu_notification_cache = nil
  end

  def battle_pass_notification?(pass = nil)
    menu_notification_cached([:battle_pass, pass && pass[:id]]) do
      passes = pass ? [pass] : PokemonSurvivor::BATTLE_PASS_DATA
      passes.any? do |entry|
        next false unless PokemonSurvivor.battle_pass_unlocked?(entry[:id])
        level = PokemonSurvivor.battle_pass_level(entry)
        claimed = PokemonSurvivor.battle_pass_entry(entry[:id])[:claimed_rewards]
        PokemonSurvivor.battle_pass_reward_list(entry).any? { |reward| reward[:tier].to_i <= level && claimed[reward[:tier].to_i].to_i <= 0 } ||
          PokemonSurvivor.battle_pass_quest_list(entry).any? do |quest|
            PokemonSurvivor.battle_pass_quest_complete?(quest) && !PokemonSurvivor.battle_pass_quest_claimed?(entry, quest)
          end
      end
    end
  end

  def breach_notification?(season = PokemonSurvivor.breach_current_season)
    return false unless season
    menu_notification_cached([:breach, season[:id]]) do
      progress = PokemonSurvivor.breach_progress(season[:id])
      quests = progress[:notification_quests] || []
      quests.any? do |quest|
        !progress[:claimed][quest[:id]] && PokemonSurvivor.breach_quest_value(season, quest) >= quest[:target]
      end
    end
  end

  def titan_notification?
    store = @titan_store || PokemonSurvivor.titan_notification_snapshot
    return false unless store && store.season && PokemonSurvivor.breach_seconds_left(store.season) > 0
    PokemonSurvivor::Titan::MILESTONES.each_index.any? { |index| store.milestone_ready?(index) }
  end

  def training_notification?(pokemon)
    menu_notification_cached([:training, pokemon]) do
      next false unless PokemonSurvivor.hero_unlocked?(pokemon)
      balance = PokemonSurvivor.candy_currency
      if !PokemonSurvivor.pokemon_shiny_unlocked?(pokemon) && PokemonSurvivor.pokemon_training_core_complete?(pokemon)
        cost = PokemonSurvivor.pokemon_training_cost(pokemon, :training_shiny, 1)
        next true if cost && balance >= cost
      end
      bought = { :training_core => true }
      candidates = []
      TRAINING_TREE_LAYOUT.each do |id, level, _x, _y|
        current = PokemonSurvivor.pokemon_training_level(pokemon, id)
        node_id = training_node_id(id, level)
        if current >= level
          bought[node_id] = true
        elsif current + 1 == level
          cost = PokemonSurvivor.pokemon_training_cost(pokemon, id, level)
          candidates << node_id if cost && balance >= cost
        end
      end
      candidates.any? do |node_id|
        TRAINING_TREE_LINKS.any? do |left, right|
          (left == node_id && bought[right]) || (right == node_id && bought[left])
        end
      end
    end
  end
end
