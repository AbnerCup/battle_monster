#===============================================================================
# Pokemon Survivor - shop and survivor progression helpers
#===============================================================================
module PokemonSurvivor
  @normalized_survivor_progress = nil
  module_function


  def shop_translation_strings
    [
      _INTL("Fragments"),
      _INTL("Dark Fragment"),
      _INTL("Earned {1} Dark Fragment."),
      _INTL("Roguelite Shop"),
      _INTL("Shop Core"),
      _INTL("Permanent roguelite upgrades branch from here."),
      _INTL("Choose a branch and unlock permanent upgrades."),
      _INTL("Move from the empty core slot to browse the tree."),
      _INTL("Core"),
      _INTL("Upgrade"),
      _INTL("Buy"),
      _INTL("Shop"),
      _INTL("Earned {1} Fragments."),
      _INTL("EXP Boost"),
      _INTL("EXP drops give more EXP."),
      _INTL("Fragment Bonus"),
      _INTL("Earn more Fragments after completed or lost runs."),
      _INTL("HP Training"),
      _INTL("Start each run with more max HP. Stacks with run bonuses."),
      _INTL("Attack Training"),
      _INTL("Start each run with stronger attacks. Stacks with run bonuses."),
      _INTL("Move Training"),
      _INTL("Start each run with higher movement speed. Stacks with run bonuses."),
      _INTL("Burst Training"),
      _INTL("Start each run with faster Burst charge. Stacks with run bonuses."),
      _INTL("Last Stand Charm"),
      _INTL("Start each run with extra saves from fatal hits."),
      _INTL("Prepared Choices"),
      _INTL("Start each run with extra bonus rerolls."),
      _INTL("Strict Draft"),
      _INTL("Start each run with extra bonus bans."),
      _INTL("Sharp Start"),
      _INTL("Levels 1 to 10 need less EXP."),
      _INTL("Steady Burst"),
      _INTL("Start each run with Burst partly charged."),
      _INTL("Endless Kecleon Shop"),
      _INTL("Endless-only permanent upgrades will branch from here."),
      _INTL("Current shop upgrades are disabled in Endless Mode."),
      _INTL("Switch"),
      _INTL("Choose this core to return to the classic tree."),
      _INTL("Choose this core to open the Endless Kecleon Shop."),
      _INTL("Complete every standard upgrade to unlock the Endless Kecleon Shop."),
      _INTL("Classic Upgrade Tree"),
      _INTL("Return to Kecleon's standard upgrade tree."),
      _INTL("Endless EXP"),
      _INTL("Increases EXP gained from drops in Endless Mode only."),
      _INTL("Endless Vitality"),
      _INTL("Start Endless Mode with higher max HP."),
      _INTL("Endless Power"),
      _INTL("Attacks deal more damage in Endless Mode only."),
      _INTL("Endless Footwork"),
      _INTL("Start Endless Mode with higher movement speed."),
      _INTL("Endless Burst"),
      _INTL("Burst gauge charges faster in Endless Mode only."),
      _INTL("Endless Control"),
      _INTL("Endless difficulty rises slightly more slowly."),
      _INTL("Endless Draft"),
      _INTL("Start Endless Mode with extra bonus rerolls and bans."),
      _INTL("Endless Charm"),
      _INTL("Start Endless Mode with extra fatal-hit saves."),
      _INTL("Candy"),
      _INTL("Trade Dark Fragments for Candies. This can be bought any number of times."),
      _INTL("+{1} Candies"),
      _INTL("Current: {1}"),
      _INTL("Next: {1}"),
      _INTL("Bonus: {1}  Cost:"),
      _INTL("Requires level {1} first.  Cost:"),
      _INTL("Level {1}/{2} unlocked."),
      _INTL("Fully upgraded."),
      _INTL("Unlocked"),
      _INTL("Available"),
      _INTL("Locked"),
      _INTL("Navigate"),
      _INTL("Unlock"),
      _INTL("Buy"),
      _INTL("Bought"),
      _INTL("Next Buy"),
      _INTL("Show Details"),
      _INTL("Hide Details"),
      _INTL("Navigate / Buy / Details / Close"),
      _INTL("Close"),
      _INTL("Cost"),
      _INTL("Lv. {1}/{2}"),
      _INTL("MAX"),
      _INTL("+{1}"),
      _INTL("+{1}%")
    ]
  end

  def shop_upgrades(tree = :standard)
    tree.to_sym == :endless ? ENDLESS_SHOP_UPGRADES : SHOP_UPGRADES
  rescue
    []
  end

  def shop_upgrade_data(id, tree = nil)
    pools = tree.nil? ? [SHOP_UPGRADES, ENDLESS_SHOP_UPGRADES] : [shop_upgrades(tree)]
    pools.each do |pool|
      data = pool.find { |upgrade| upgrade[:id] == id.to_sym }
      return data if data
    end
    nil
  rescue
    nil
  end

  def shop_currency
    survivor_progress[:shop_currency].to_i
  rescue
    0
  end

  def dark_shop_currency
    convert_shop_currency_to_dark_if_unlocked
    survivor_progress[:dark_shop_currency].to_i
  rescue
    0
  end

  def dark_fragment_balance_text(dark, fragments = shop_currency)
    rate = [DARK_FRAGMENT_CONVERSION_RATE.to_i, 1].max
    # Truncate display only: never imply that a whole Dark Fragment is affordable.
    hundredths = [(dark.to_i * rate + fragments.to_i), 0].max * 100 / rate
    format("%d.%02d", hundredths / 100, hundredths % 100)
  end

  def endless_shop_currency_unlocked?
    shop_tree_complete?(:standard)
  rescue
    false
  end

  def convert_shop_currency_to_dark_if_unlocked
    return 0 if !endless_shop_currency_unlocked?
    progress = survivor_progress
    fragments = [progress[:shop_currency].to_i, 0].max
    rate = [DARK_FRAGMENT_CONVERSION_RATE.to_i, 1].max
    converted = fragments / rate
    return 0 if converted <= 0
    progress[:shop_currency] = fragments - (converted * rate)
    progress[:dark_shop_currency] = [progress[:dark_shop_currency].to_i + converted, 0].max
    converted
  rescue
    0
  end

  def active_shop_currency(tree = :standard)
    tree.to_sym == :endless ? dark_shop_currency : shop_currency
  rescue
    0
  end

  def shop_currency_icon(tree = :standard)
    tree.to_sym == :endless ? "ICON_DARKFRAGMENT" : "ICON_FRAGMENT"
  rescue
    "ICON_FRAGMENT"
  end

  def selection_shop_currency
    endless_shop_currency_unlocked? ? dark_shop_currency : shop_currency
  rescue
    shop_currency
  end

  def selection_shop_currency_icon
    endless_shop_currency_unlocked? ? "ICON_DARKFRAGMENT" : "ICON_FRAGMENT"
  rescue
    "ICON_FRAGMENT"
  end

  def spend_active_shop_currency(amount, tree = :standard)
    progress = survivor_progress
    cost = [amount.to_i, 0].max
    if tree.to_sym == :endless
      convert_shop_currency_to_dark_if_unlocked
      return false if progress[:dark_shop_currency].to_i < cost
      progress[:dark_shop_currency] = [progress[:dark_shop_currency].to_i - cost, 0].max
    else
      return false if progress[:shop_currency].to_i < cost
      progress[:shop_currency] = [progress[:shop_currency].to_i - cost, 0].max
    end
    true
  rescue
    false
  end
  def add_shop_currency(amount)
    progress = survivor_progress
    gain = [amount.to_i, 0].max
    progress[:shop_currency] = [progress[:shop_currency].to_i + gain, 0].max
    gain
  rescue
    0
  end

  def spend_shop_currency(amount)
    progress = survivor_progress
    cost = [amount.to_i, 0].max
    return false if progress[:shop_currency].to_i < cost
    progress[:shop_currency] = [progress[:shop_currency].to_i - cost, 0].max
    true
  rescue
    false
  end

  def shop_upgrade_level(id)
    survivor_progress[:shop_upgrades][id.to_sym].to_i
  rescue
    0
  end

  def shop_upgrade_max(id)
    data = shop_upgrade_data(id)
    data ? data[:values].length : 0
  rescue
    0
  end

  def shop_upgrade_tree(id)
    key = id.to_sym
    ENDLESS_SHOP_UPGRADES.any? { |upgrade| upgrade[:id] == key } ? :endless : :standard
  rescue
    :standard
  end

  def shop_upgrade_cost(id)
    data = shop_upgrade_data(id)
    level = shop_upgrade_level(id)
    return nil if !data || level >= data[:costs].length
    data[:costs][level].to_i
  rescue
    nil
  end

  def shop_upgrade_value(id)
    data = shop_upgrade_data(id)
    level = shop_upgrade_level(id)
    return 0 if !data || level <= 0
    data[:values][level - 1].to_i
  rescue
    0
  end

  def shop_effect_value(effect, tree = :standard)
    total = 0
    shop_upgrades(tree).each do |upgrade|
      next if upgrade[:effect] != effect
      total += shop_upgrade_value(upgrade[:id])
    end
    total
  rescue
    0
  end

  def shop_effect_multiplier(effect, tree = :standard)
    1.0 + (shop_effect_value(effect, tree).to_f / 100.0)
  rescue
    1.0
  end

  def shop_tree_complete?(tree = :standard)
    shop_upgrades(tree).all? do |upgrade|
      next true if upgrade[:infinite]
      shop_upgrade_level(upgrade[:id]) >= (upgrade[:values] || []).length
    end
  rescue
    false
  end

  def buy_shop_upgrade(id, quantity = 1)
    data = shop_upgrade_data(id)
    return false if !data
    return false unless quantity.is_a?(Integer) && quantity > 0
    return false if quantity != 1 && id != :endless_candy_exchange
    level = shop_upgrade_level(id)
    if data[:infinite]
      cost = (data[:costs] || [])[0].to_i * quantity
      tree = shop_upgrade_tree(id)
      return false if cost <= 0 || !shop_tree_complete?(tree)
      return false if !spend_active_shop_currency(cost, tree)
      gain = (data[:values] || [])[0].to_i * quantity
      add_candy_currency(gain) if respond_to?(:add_candy_currency)
      progress = survivor_progress
      progress[:shop_upgrades][id.to_sym] = level + quantity
      return true
    end
    return false if level >= data[:values].length
    cost = shop_upgrade_cost(id).to_i
    tree = shop_upgrade_tree(id)
    return false if !spend_active_shop_currency(cost, tree)
    progress = survivor_progress
    progress[:shop_upgrades][id.to_sym] = level + 1
    true
  rescue
    false
  end

  def shop_run_currency_reward(score, level, won = false, apply_coin_bonus = true)
    score_value = [score.to_i, 0].max
    level_value = [[level.to_i, 1].max, 9999].min
    score_part = Math.sqrt(score_value).to_i / 3
    level_part = level_value + ([level_value - 100, 0].max / 2)
    base = score_part + level_part
    base = won ? ((base * 1.18).round + 35) : (base * 0.5).round
    base = [base, won ? 45 : 10].max
    apply_coin_bonus ? (base * shop_effect_multiplier(:coin_gain_percent)).round : base
  rescue
    0
  end
  def invalid_survivor_species?(name)
    key = species_key(name)
    return true if key == :NONE || key == :MISSINGNO || key == :MISSINGNO_1 || key.to_s == "000"
    return true if name.to_s.strip.empty?
    false
  rescue
    true
  end

  def valid_survivor_species?(name)
    return false if invalid_survivor_species?(name)
    !!(GameData::Species.try_get(game_species_key(name)) rescue nil)
  rescue
    false
  end

  def valid_survivor_names(names)
    (names || []).compact.map(&:to_s).reject { |name| !valid_survivor_species?(name) }.uniq
  rescue
    []
  end

  def files_in(folder)
    @files_cache ||= {}
    @files_cache[folder] ||= Dir.glob("#{folder}/*.{png,bmp}").map { |f| File.basename(f, ".*") }.sort
  rescue
    []
  end

  def background_names
    # Titan loads its seasonal background directly, never through the random pool.
    names = files_in(BACKGROUND_DIR).reject { |name| name.to_s =~ /\ASeason_\d+\z/i }
    names = BACKGROUNDS.map(&:to_s) if names.empty?
    names
  rescue
    BACKGROUNDS.map(&:to_s)
  end

  def classic_background_names
    excluded = ([RUSH_BACKGROUND, TOWER_BACKGROUND] + TOWER_FINAL_BOSSES).map { |name| name.to_s.upcase }
    names = background_names.reject do |name|
      up = name.to_s.upcase
      excluded.include?(up) || (GameData::Species.try_get(species_key(name)) rescue nil)
    end
    names.empty? ? BACKGROUNDS.map(&:to_s) : names
  rescue
    BACKGROUNDS.map(&:to_s)
  end

  def bgm_for_background(name)
    bg_name = name.to_s
    return DEFAULT_BGM if bg_name.empty?
    BGM_BY_BACKGROUND[bg_name] || "Survivor/#{bg_name}"
  rescue
    DEFAULT_BGM
  end

  def audio_bgm_exists?(name)
    @audio_bgm_exists_cache ||= {}
    key = name.to_s
    return @audio_bgm_exists_cache[key] if @audio_bgm_exists_cache.key?(key)
    base = File.join("Audio", "BGM", key)
    @audio_bgm_exists_cache[key] = ["ogg", "mp3", "mid", "wav"].any? { |ext| File.exist?("#{base}.#{ext}") }
  rescue
    false
  end

  def rush_boss_generation_for_sequence(sequence)
    keys = (sequence || []).map { |entry| species_key(entry) }
    return 1 if keys.any? { |key| [:ARTICUNO, :ARTICUNO_1, :MOLTRES, :MOLTRES_1, :ZAPDOS, :ZAPDOS_1, :MEWTWO].include?(key) }
    return 2 if keys.any? { |key| [:RAIKOU, :SUICUNE, :ENTEI, :HOOH, :LUGIA].include?(key) }
    return 3 if keys.any? { |key| [:REGIROCK, :REGICE, :REGISTEEL, :KYOGRE, :GROUDON].include?(key) }
    return 4 if keys.any? { |key| [:UXIE, :MESPRIT, :AZELF, :DIALGA, :PALKIA].include?(key) }
    return 5 if keys.any? { |key| [:LANDORUS, :THUNDURUS, :TORNADUS, :RESHIRAM, :ZEKROM].include?(key) }
    return 6 if keys.any? { |key| [:NOIVERN, :XERNEAS, :YVELTAL, :ZYGARDE_1].include?(key) }
    return 7 if keys.any? { |key| (defined?(ULTRA_BEAST_BOSS_KEYS) && ULTRA_BEAST_BOSS_KEYS.include?(key)) || [:SOLGALEO, :LUNALA].include?(key) }
    return 8 if keys.any? { |key| [:REGIELEKI, :REGIDRAGO, :ENAMORUS, :ENAMORUS_1, :ZACIAN, :ZAMAZENTA].include?(key) }
    return 9 if keys.any? { |key| PARADOX_BOSS_KEYS.include?(key) || [:KORAIDON, :MIRAIDON].include?(key) }
    1
  rescue
    1
  end

  def bgm_for_rush_generation(generation)
    gen = [[generation.to_i, 1].max, 9].min
    candidates = [
      "Survivor/Rush Gen #{gen}",
      "Survivor/Rush GEN#{gen}",
      "Survivor/Gen #{gen}",
      "Survivor/GEN#{gen}",
      "Survivor/Generation #{gen}"
    ]
    candidates.each { |bgm| return bgm if audio_bgm_exists?(bgm) }
    return ULTRA_BOSS_BGM if audio_bgm_exists?(ULTRA_BOSS_BGM)
    DEFAULT_BGM
  rescue
    ULTRA_BOSS_BGM
  end
  def resolve(folder, name)
    @resolve_cache ||= {}
    @resolve_missing_cache ||= {}
    key = "#{folder}/#{name}"
    return @resolve_cache[key] if @resolve_cache.key?(key)
    return nil if @resolve_missing_cache[key]
    ["png", "bmp"].each do |ext|
      path = "#{folder}/#{name}.#{ext}"
      resolved = pbResolveBitmap(path) rescue nil
      if resolved
        @resolve_cache[key] = resolved
        return resolved
      end
      if !defined?(pbResolveBitmap) && FileTest.exist?(path)
        @resolve_cache[key] = path
        return path
      end
    end
    path = "#{folder}/#{name}"
    resolved = pbResolveBitmap(path) rescue nil
    if resolved
      @resolve_cache[key] = resolved
      return resolved
    end
    @resolve_missing_cache[key] = true
    nil
  rescue
    @resolve_missing_cache ||= {}
    @resolve_missing_cache["#{folder}/#{name}"] = true rescue nil
    nil
  end

  def hero_names
    battle_pass_restore_claimed_reward_unlocks if respond_to?(:battle_pass_restore_claimed_reward_unlocks)
    names = BASE_HERO_KEYS.reject { |key| battle_pass_hidden_hero?(key) }.map(&:to_s)
    order = {}
    (HERO_ACCESSIBILITY_ORDER + HERO_ORDER).uniq.each_with_index { |key, i| order[key] = i }
    names.sort_by { |name| [order.fetch(species_key(name), 999), name.to_s] }
  end

  def battle_pass_hidden_hero?(name)
    key = species_key(name)
    hidden = defined?(BATTLE_PASS_HIDDEN_HERO_KEYS) ? BATTLE_PASS_HIDDEN_HERO_KEYS : []
    hidden.include?(key) && !hero_unlocked?(key)
  rescue
    false
  end

  def survivor_progress
    if defined?($PokemonGlobal) && $PokemonGlobal
      progress = $PokemonGlobal.instance_variable_get(:@pokemon_survivor_progress)
      if !progress.is_a?(Hash)
        progress = {}
        $PokemonGlobal.instance_variable_set(:@pokemon_survivor_progress, progress)
      end
    else
      @fallback_survivor_progress ||= {}
      progress = @fallback_survivor_progress
    end
    # Normalize on load/new game, not on every menu cell or combat stat read.
    return progress if @normalized_survivor_progress.equal?(progress)
    normalized = normalize_survivor_progress(progress)
    @normalized_survivor_progress = progress if normalized.equal?(progress)
    normalized
  rescue
    @fallback_survivor_progress ||= default_survivor_progress
  end

  def default_survivor_progress
    {
      unlocked: INITIAL_UNLOCKED_HEROES.dup,
      eevee_forms: [],
      survived_15: [],
      boss_finished: [],
      evolution_finished: [],
      level_finished: [],
      rush_finished: [],
      tower_finished: [],
      shop_currency: 0,
      dark_shop_currency: 0,
      candy_currency: 0,
      classic_completed_runs_count: 0,
      battle_passes: {},
      pokemon_training: {},
      pokemon_equipment: {},
      pokemon_shiny_active: {},
      equipment_unlocked: {},
      shop_upgrades: {},
      crt_default_off_migrated: false
    }
  end

  def normalize_survivor_progress(progress)
    progress = {} if !progress.is_a?(Hash)
    defaults = default_survivor_progress
    if !progress[:crt_default_off_migrated] && !progress["crt_default_off_migrated"]
      opts = performance_options rescue DEFAULT_PERFORMANCE_OPTIONS.dup
      opts[:tv_filter] = false if opts.is_a?(Hash)
      $PokemonSurvivorPerformanceOptions = opts if opts.is_a?(Hash)
      progress[:crt_default_off_migrated] = true
    end
    defaults.each_pair do |key, value|
      string_key = key.to_s
      progress[key] = progress[string_key] if !progress.key?(key) && progress.key?(string_key)
      case value
      when Array
        list = progress[key].is_a?(Array) ? progress[key] : value.dup
        progress[key] = list.compact.map { |entry| species_key(entry) }.uniq
      when Hash
        hash = progress[key].is_a?(Hash) ? progress[key] : {}
        normalized = {}
        if key == :pokemon_training
          hash.each_pair do |entry_key, entry_value|
            species = species_key(entry_key)
            next if species == :NONE
            levels = entry_value.is_a?(Hash) ? entry_value : {}
            normalized[species] = {}
            levels.each_pair do |upgrade_key, upgrade_value|
              key_sym = upgrade_key.to_sym
              key_sym = :training_pickup if key_sym == :training_exp
              normalized[species][key_sym] = upgrade_value.to_i
            rescue
            end
          rescue
          end
        elsif key == :pokemon_equipment
          hash.each_pair do |entry_key, entry_value|
            species = species_key(entry_key)
            next if species == :NONE
            normalized[species] = entry_value.to_sym if entry_value && !entry_value.to_s.empty?
          rescue
          end
        elsif key == :battle_passes
          hash.each_pair do |entry_key, entry_value|
            pass_key = entry_key.to_sym
            if entry_value.is_a?(Hash)
              pass_data = {}
              pass_data[:unlocked] = (entry_value[:unlocked] || 0).to_i
              pass_data[:unlocked] = (entry_value["unlocked"] || 0).to_i if pass_data[:unlocked] <= 0 && entry_value.key?("unlocked")
              pass_data[:xp] = (entry_value[:xp] || 0).to_i
              pass_data[:xp] = (entry_value["xp"] || 0).to_i if pass_data[:xp] <= 0 && entry_value.key?("xp")
              claimed_quests = entry_value[:claimed_quests] || entry_value["claimed_quests"] || {}
              claimed_rewards = entry_value[:claimed_rewards] || entry_value["claimed_rewards"] || {}
              pass_data[:claimed_quests] = {}
              pass_data[:claimed_rewards] = {}
              claimed_quests.each_pair { |quest_key, quest_value| pass_data[:claimed_quests][quest_key.to_sym] = (quest_value || 0).to_i } if claimed_quests.is_a?(Hash)
              claimed_rewards.each_pair { |reward_key, reward_value| pass_data[:claimed_rewards][(reward_key || 0).to_i] = (reward_value || 0).to_i } if claimed_rewards.is_a?(Hash)
              normalized[pass_key] = pass_data
            else
              normalized[pass_key] = { unlocked: (entry_value || 0).to_i, xp: 0, claimed_quests: {}, claimed_rewards: {} }
            end
          rescue
          end
        else
          hash.each_pair do |entry_key, entry_value|
            normalized[entry_key.to_sym] = entry_value.to_i
          rescue
          end
        end
        progress[key] = normalized
      else
        if value == true || value == false
          current = progress[key]
          current = progress[string_key] if current.nil? && defined?(string_key) && progress.key?(string_key)
          progress[key] = current.nil? ? value : !!current
        else
          progress[key] = progress[key].nil? ? value : progress[key].to_i
        end
      end
    end
    progress[:unlocked] = (INITIAL_UNLOCKED_HEROES + progress[:unlocked]).map { |entry| species_key(entry) }.uniq.select { |entry| BASE_HERO_KEYS.include?(entry) }
    progress[:classic_completed_runs_count] = [progress[:classic_completed_runs_count].to_i, progress[:survived_15].length].max
    progress
  rescue
    default_survivor_progress
  end
  def hero_unlocked?(name)
    key = species_key(name)
    survivor_progress[:unlocked].map { |entry| species_key(entry) }.include?(key)
  rescue
    INITIAL_UNLOCKED_HEROES.include?(species_key(name))
  end

  def hero_finished?(name)
    key = species_key(name)
    survivor_progress[:survived_15].map { |entry| species_key(entry) }.include?(key)
  rescue
    false
  end

  def hero_boss_finished?(name)
    key = species_key(name)
    survivor_progress[:boss_finished].map { |entry| species_key(entry) }.include?(key)
  rescue
    false
  end

  def hero_evolution_finished?(name)
    key = species_key(name)
    survivor_progress[:evolution_finished].map { |entry| species_key(entry) }.include?(key)
  rescue
    false
  end

  def hero_level_finished?(name)
    key = species_key(name)
    survivor_progress[:level_finished].map { |entry| species_key(entry) }.include?(key)
  rescue
    false
  end

  def hero_rush_finished?(name)
    key = species_key(name)
    survivor_progress[:rush_finished].map { |entry| species_key(entry) }.include?(key)
  rescue
    false
  end

  def hero_tower_finished?(name)
    key = species_key(name)
    survivor_progress[:tower_finished].map { |entry| species_key(entry) }.include?(key)
  rescue
    false
  end

  def unlocked_hero_skills
    skills = [:normal_shot]
    survivor_progress[:unlocked].each do |entry|
      data = hero_data(species_key(entry))
      skills << data[:skill] if data && data[:skill]
    end
    (survivor_progress[:eevee_forms] || []).each do |form|
      key = species_key(form)
      skills << HERO_BASE[key][:skill] if EEVEE_STONE_FORMS.value?(key) && HERO_BASE[key]
    end
    skills.compact.uniq.reject { |id| id == :prism_sweep }
  rescue
    (INITIAL_UNLOCKED_HEROES.map { |key| hero_data(key)[:skill] } + [:normal_shot]).compact.uniq
  end

  def skill_unlocked_for_learning?(skill)
    return false if skill == :prism_sweep
    return true if skill == :normal_shot
    unlocked_hero_skills.include?(skill)
  rescue
    skill == :normal_shot
  end

  def unlock_hero(name)
    key = species_key(name)
    progress = survivor_progress
    unlocked = progress[:unlocked].map { |entry| species_key(entry) }
    return false if unlocked.include?(key)
    progress[:unlocked] << key
    true
  rescue
    false
  end

  def progress_species_list(progress, key)
    list = progress[key].is_a?(Array) ? progress[key] : []
    list.map { |entry| species_key(entry) }.uniq
  rescue
    []
  end

  def progress_has_species?(progress, key, species)
    progress_species_list(progress, key).include?(species_key(species))
  rescue
    false
  end

  def progress_has_any_species?(progress, key, species_list)
    stored = progress_species_list(progress, key)
    species_list.any? { |species| stored.include?(species_key(species)) }
  rescue
    false
  end

  def progress_classic_valid?(progress, species)
    key = species_key(species)
    progress_has_species?(progress, :survived_15, key) && progress_has_species?(progress, :boss_finished, key)
  rescue
    false
  end

  def retroactive_finished_hero_keys(progress)
    playable = BASE_HERO_KEYS - [:DEOXYS]
    finish_lists = [:survived_15, :boss_finished, :evolution_finished, :level_finished, :rush_finished, :tower_finished].map do |finish_key|
      progress_species_list(progress, finish_key)
    end
    playable.select { |key| finish_lists.all? { |list| list.include?(key) } }.uniq
  rescue
    []
  end

  def apply_retroactive_unlocks_on_menu_open
    unlocked_now = []
    (BASE_HERO_KEYS.length + 2).times do
      progress = survivor_progress
      unlocked = progress_species_list(progress, :unlocked)
      playable = BASE_HERO_KEYS - [:DEOXYS]
      playable_unlocked = unlocked.select { |key| playable.include?(key) }.uniq
      nonstarter_unlocked = playable_unlocked.reject { |key| INITIAL_UNLOCKED_HEROES.include?(key) }
      candidates = []
      GEN9_SURVIVOR_UNLOCKS.each do |child, parent|
        candidates << child if progress_classic_valid?(progress, parent)
      end
      candidates << :APPLIN if progress_classic_valid?(progress, :GOOMY)
      candidates << :SCORBUNNY if progress_classic_valid?(progress, :FROAKIE)
      candidates << :ROOKIDEE if progress_classic_valid?(progress, :NOIBAT)
      candidates << :DREEPY if progress_classic_valid?(progress, :WIMPOD)
      candidates << :HATENNA if progress_classic_valid?(progress, :FENNEKIN)
      candidates << :IMPIDIMP if progress_classic_valid?(progress, :HATENNA)
      candidates << :TOXEL if progress_classic_valid?(progress, :CROAGUNK)
      candidates << :KUBFU if progress_classic_valid?(progress, :RIOLU)
      candidates << :ZIGZAGOON_1 if progress_classic_valid?(progress, :SCORBUNNY)

      candidates << :CHIMCHAR if nonstarter_unlocked.length >= 6
      candidates << :FENNEKIN if nonstarter_unlocked.length >= 10
      candidates << :ROWLET if playable_unlocked.length >= 14
      candidates << :GIBLE if playable_unlocked.length >= 25
      candidates << :MEW if (playable_unlocked - [:MEW]).length >= 13
      candidates << :PICHU if progress_has_species?(progress, :rush_finished, :ZUBAT)
      candidates << :SABLEYE if progress_has_species?(progress, :rush_finished, :GASTLY)
      candidates << :RIOLU if progress_has_species?(progress, :tower_finished, :PICHU)
      candidates << :LITWICK if progress_classic_valid?(progress, :GASTLY)
      candidates << :SANDILE if progress_classic_valid?(progress, :TRAPINCH)
      candidates << :ZORUA if progress_classic_valid?(progress, :SABLEYE)
      candidates << :ZORUA_1 if progress_classic_valid?(progress, :ZORUA)
      candidates << :FROAKIE if progress_classic_valid?(progress, :AZURILL)
      candidates << :GRUBBIN if progress_classic_valid?(progress, :SHINX)
      candidates << :MIMIKYU if progress_classic_valid?(progress, :ZORUA)
      candidates << :VENIPEDE if progress_classic_valid?(progress, :SPINARAK)
      candidates << :VANILLITE if progress_classic_valid?(progress, :SPHEAL)
      candidates << :PAWNIARD if progress_has_species?(progress, :rush_finished, :ARON)
      candidates << :HONEDGE if progress_has_species?(progress, :rush_finished, :PAWNIARD)
      candidates << :HAWLUCHA if progress_has_species?(progress, :rush_finished, :RIOLU)
      candidates << :WIMPOD if progress_has_species?(progress, :rush_finished, :CROAGUNK)
      candidates << :ROCKRUFF if progress_has_species?(progress, :rush_finished, :LARVITAR)
      candidates << :LARVESTA if progress_has_species?(progress, :rush_finished, :CHIMCHAR)
      candidates << :DEINO if progress_has_species?(progress, :tower_finished, :DRATINI)
      candidates << :JANGMOO if progress_has_species?(progress, :tower_finished, :GIBLE)
      candidates << :GOOMY if progress_classic_valid?(progress, :DEINO) && progress_has_species?(progress, :level_finished, :DEINO)
      if progress_classic_valid?(progress, :TRAPINCH) && progress_has_species?(progress, :level_finished, :TRAPINCH)
        candidates << :DRILBUR
      end
      mudkip_family = [:MUDKIP, :MARSHTOMP, :SWAMPERT]
      if progress_has_any_species?(progress, :survived_15, mudkip_family) &&
         progress_has_any_species?(progress, :boss_finished, mudkip_family) &&
         progress_has_any_species?(progress, :evolution_finished, mudkip_family) &&
         progress_has_any_species?(progress, :level_finished, mudkip_family)
        candidates << :AZURILL
      end

      if progress_classic_valid?(progress, :SPINARAK) && progress_has_species?(progress, :evolution_finished, :SPINARAK)
        candidates << :BELLSPROUT
      end

      if playable_unlocked.length >= 21 && retroactive_finished_hero_keys(progress).length >= 11
        candidates << :DEOXYS
      end

      changed = false
      candidates.each do |hero|
        next if unlocked.include?(species_key(hero))
        if unlock_hero(hero)
          unlocked_now << species_key(hero)
          changed = true
        end
      end
      break if !changed
    end
    unlocked_now.uniq
  rescue
    []
  end
end



