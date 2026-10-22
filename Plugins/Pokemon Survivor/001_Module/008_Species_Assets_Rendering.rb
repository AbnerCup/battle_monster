#===============================================================================
# Pokemon Survivor - species helpers and low-level asset drawing
#===============================================================================
module PokemonSurvivor
  module_function
  def hero_unlock_requirement(name)
    hint = HERO_UNLOCK_HINTS[species_key(name)]
    if hint
      names = hint.drop(1).map do |base, species|
        hero_unlocked?(base) ? species_name(species) : "???"
      end
      return _INTL(hint[0], *names)
    end
    text = HERO_UNLOCK_REQUIREMENTS[species_key(name)]
    text ? _INTL(text) : _INTL("Locked.")
  end

  def wild_names
    return @wild_names_cache if @wild_names_cache
    names = files_in(WILD_DIR)
    reserved = reserved_role_species
    names.select! do |name|
      doom_enemy?(name) || (valid_survivor_species?(name) && !reserved.include?(species_key(name)) && !FUTURE_RESERVED_BOSSES.include?(species_key(name)))
    end
    @wild_names_cache = names.empty? ? valid_survivor_names(BASE_HERO_KEYS).map(&:to_s) : names
  end

  def arena_wild_names
    @arena_wild_names_cache ||= wild_names.reject { |name| doom_enemy?(name) || !valid_survivor_species?(name) }
  rescue
    valid_survivor_names(BASE_HERO_KEYS).map(&:to_s)
  end

  def boss_names
    @boss_names_cache ||= begin
      names = files_in(BOSS_DIR)
      names = valid_survivor_names(names.empty? ? role_fallback_names(:boss) : names)
      final_reserved = TOWER_FINAL_BOSSES.map { |entry| species_key(entry) }
      filtered = names.reject { |name| final_reserved.include?(species_key(name)) || FUTURE_RESERVED_BOSSES.include?(species_key(name)) }
      filtered.empty? ? valid_survivor_names(wild_names).first(1) : filtered
    end
  end

  def chest_names
    @chest_names_cache ||= begin
      names = valid_survivor_names(files_in(CHEST_DIR)).reject { |name| FUTURE_RESERVED_BOSSES.include?(species_key(name)) }
      names.empty? ? role_fallback_names(:chest) : names
    end
  end

  def ultra_boss_names
    @ultra_boss_names_cache ||= begin
      names = files_in(ULTRA_BOSS_DIR)
      names = valid_survivor_names(names.empty? ? boss_names : names)
      final_reserved = TOWER_FINAL_BOSSES.map { |entry| species_key(entry) }
      filtered = names.reject { |name| final_reserved.include?(species_key(name)) || FUTURE_RESERVED_BOSSES.include?(species_key(name)) }
      filtered.empty? ? boss_names : filtered
    end
  end


  def ultra_beast_boss_names
    @ultra_beast_boss_names_cache ||= begin
      names = valid_survivor_names(files_in(ULTRA_BEAST_DIR))
      reserved = FUTURE_RESERVED_BOSSES
      names.reject { |name| reserved.include?(species_key(name)) }
    end
  rescue
    []
  end

  def tower_boss_names
    names = (boss_names + ultra_beast_boss_names + paradox_boss_names).uniq
    names.empty? ? boss_names : names
  rescue
    boss_names
  end
  def paradox_boss_names
    @paradox_boss_names_cache ||= valid_survivor_names(files_in(PARADOX_DIR)).reject do |name|
      FUTURE_RESERVED_BOSSES.include?(species_key(name)) || tower_final_boss?(name)
    end
  rescue
    []
  end

  def rush_boss_sequence
    themes = RUSH_BOSS_THEMES.reject { |entry| entry[0].equal?(PARADOX_BOSS_KEYS) && paradox_boss_names.empty? }
    theme = themes.sample || RUSH_BOSS_THEMES[0]
    theme.map do |choices|
      pool = if choices.equal?(PARADOX_BOSS_KEYS)
               paradox_boss_names
             elsif choices.equal?(ULTRA_BEAST_BOSS_KEYS)
               ultra_beast_boss_names
             else
               choices
             end
      pool = choices if pool.nil? || pool.empty?
      (pool.sample || pool[0]).to_s
    end
  rescue
    ["ARTICUNO", "MOLTRES", "ZAPDOS", "MEWTWO"]
  end

  def tower_final_boss_names
    valid_survivor_names(TOWER_FINAL_BOSSES)
  rescue
    [TOWER_FINAL_BOSS]
  end

  def random_tower_final_boss
    names = tower_final_boss_names
    (names.sample || TOWER_FINAL_BOSS).to_s
  rescue
    TOWER_FINAL_BOSS
  end

  def tower_final_boss?(name)
    tower_final_boss_names.map { |entry| species_key(entry) }.include?(species_key(name))
  rescue
    species_key(name) == species_key(TOWER_FINAL_BOSS)
  end
  def ultra_chest_names
    @ultra_chest_names_cache ||= begin
      names = valid_survivor_names(files_in(ULTRA_CHEST_DIR)).reject { |name| FUTURE_RESERVED_BOSSES.include?(species_key(name)) }
      names.empty? ? chest_names : names
    end
  end

  def reserved_role_species
    return @reserved_role_species_cache if @reserved_role_species_cache
    keys = []
    files_in(BOSS_DIR).each { |name| keys << species_key(name) }
    files_in(CHEST_DIR).each { |name| keys << species_key(name) }
    files_in(ULTRA_BOSS_DIR).each { |name| keys << species_key(name) }
    files_in(ULTRA_BEAST_DIR).each { |name| keys << species_key(name) }
    files_in(PARADOX_DIR).each { |name| keys << species_key(name) }
    files_in(ULTRA_CHEST_DIR).each { |name| keys << species_key(name) }
    @reserved_role_species_cache = keys.uniq
  rescue
    []
  end

  def role_fallback_names(kind)
    names = valid_survivor_names(files_in(WILD_DIR))
    reserved = reserved_role_species
    names.reject! { |name| doom_enemy?(name) || reserved.include?(species_key(name)) || FUTURE_RESERVED_BOSSES.include?(species_key(name)) }
    chest_fallback = valid_survivor_names(["CHANSEY", "DITTO", "MAGIKARP"])
    return chest_fallback if kind == :chest && names.empty? && !chest_fallback.empty?
    names.empty? ? valid_survivor_names(BASE_HERO_KEYS).map(&:to_s) : names
  end

  def species_key(name)
    key = name.to_s.upcase.gsub(/[^A-Z0-9_]/, "").to_sym
    return :NIDORANm if [:NIDORANM, :NIDORANMA, :NIDORAN_M].include?(key)
    return :NIDORANf if [:NIDORANF, :NIDORANFE, :NIDORAN_F].include?(key)
    key
  end

  def game_species_key(name)
    key = species_key(name)
    exact = GameData::Species.try_get(key) rescue nil
    return key if exact
    special = { :NIDORANm => :NIDORANmA, :NIDORANf => :NIDORANfE }[key]
    return special if special && (GameData::Species.try_get(special) rescue nil)
    text = key.to_s
    if text[/\A(.+)_\d+\z/]
      base = $1.to_sym
      base_data = GameData::Species.try_get(base) rescue nil
      return base if base_data
    end
    key
  rescue
    species_key(name)
  end

  def species_name(name)
    key = game_species_key(name)
    data = GameData::Species.try_get(key) rescue nil
    return data.name if data
    name.to_s.gsub("_", " ")
  end

  def leaderboard_pokemon_color(name)
    key = species_key(name)
    data = HERO_BASE[key]
    return data[:color] if data && data[:color]
    Color.white
  rescue
    Color.white
  end

  def leaderboard_pokemon_display_name(name)
    key = species_key(name)
    return species_name(key) if HERO_BASE.key?(key)
    name.to_s
  rescue
    name.to_s
  end

  def species_types(name)
    @species_types_cache ||= {}
    key = species_key(name)
    return @species_types_cache[key] if @species_types_cache.key?(key)
    override = FORM_TYPE_OVERRIDES[key] rescue nil
    return @species_types_cache[key] = override if override && !override.empty?
    data = species_data(key)
    types = []
    types = data.types if data && data.respond_to?(:types)
    types = [:NORMAL] if !types || types.empty?
    @species_types_cache[key] = types
  rescue
    [:NORMAL]
  end

  def form_species_parts(name)
    key = species_key(name)
    text = key.to_s
    return nil if !text[/\A(.+)_(\d+)\z/]
    [$1.to_sym, $2.to_i]
  rescue
    nil
  end

  def species_form_data(base, form)
    candidates = ["#{base}_#{form}".to_sym, "#{base}_#{form}", "#{base},#{form}", "#{base}-#{form}"]
    candidates.each do |candidate|
      data = GameData::Species.try_get(candidate) rescue nil
      return data if data
    end
    nil
  rescue
    nil
  end

  def species_data(name)
    @species_data_cache ||= {}
    key = species_key(name)
    return @species_data_cache[key] if @species_data_cache.key?(key)
    exact = GameData::Species.try_get(key) rescue nil
    if !exact
      parts = form_species_parts(key)
      exact = species_form_data(parts[0], parts[1]) if parts
    end
    exact = GameData::Species.try_get(game_species_key(key)) rescue nil if !exact
    @species_data_cache[key] = exact
  end

  def species_base_total(name)
    @species_base_total_cache ||= {}
    key = species_key(name)
    return @species_base_total_cache[key] if @species_base_total_cache.key?(key)
    data = species_data(name)
    stats = data.base_stats if data && data.respond_to?(:base_stats)
    stats = data.baseStats if data && !stats && data.respond_to?(:baseStats)
    total = if !stats
              320
            elsif stats.respond_to?(:values)
              stats.values.compact.map(&:to_i).sum
            else
              stats.compact.map(&:to_i).sum
            end
    @species_base_total_cache[key] = total
  rescue
    320
  end

  def previous_species_id(species)
    data = GameData::Species.try_get(game_species_key(species)) rescue nil
    return nil if !data
    return data.get_previous_species if data.respond_to?(:get_previous_species)
    GameData::Species.each do |candidate|
      evos = candidate.get_evolutions(true) rescue []
      evos.each { |evo| return candidate.id if evo[0] == species || evo[0].to_sym == species rescue false }
    end
    nil
  rescue
    nil
  end

  def evolution_stage(name)
    @evolution_stage_cache ||= {}
    species = species_key(name)
    return @evolution_stage_cache[species] if @evolution_stage_cache.key?(species)
    stage = 0
    seen = {}
    while species && !seen[species]
      seen[species] = true
      prev = previous_species_id(species)
      break if !prev || prev == species
      stage += 1
      species = prev
    end
    @evolution_stage_cache[species_key(name)] = stage
  rescue
    0
  end

  def deoxys_form_species?(name)
    [:DEOXYS_1, :DEOXYS_2, :DEOXYS_3].include?(species_key(name))
  rescue
    false
  end

  def base_hero_species?(name)
    key = species_key(name)
    return true if BASE_HERO_KEYS.include?(key)
    evolution_stage(key) <= 0
  rescue
    false
  end

  def next_evolution_species(species)
    key = species_key(species)
    return HERO_EVOLUTION_OVERRIDES[key] if HERO_EVOLUTION_OVERRIDES[key]
    data = GameData::Species.try_get(game_species_key(key)) rescue nil
    return nil if !data
    evos = data.get_evolutions(true) rescue []
    evos = data.get_evolutions rescue [] if !evos || evos.empty?
    evos.each do |evo|
      target = evo[0] rescue nil
      return species_key(target) if target
    end
    nil
  rescue
    nil
  end

  def hero_evolution_name(base_name, growth_stage)
    key = species_key(base_name)
    return key.to_s if NON_EVOLVING_HEROES.include?(key)
    first = next_evolution_species(key)
    return key.to_s if !first
    return first.to_s if growth_stage.to_i <= 1
    second = next_evolution_species(first)
    (second || first).to_s
  rescue
    base_name.to_s
  end

  def hero_evolution_levels(base_name)
    key = species_key(base_name)
    non_evolving_levels = NON_EVOLVING_POWER_LEVELS[key]
    return non_evolving_levels if non_evolving_levels
    if NON_EVOLVING_HEROES.include?(key) || !next_evolution_species(key)
      return DEFAULT_NON_EVOLVING_POWER_LEVELS
    end
    HERO_EVOLUTION_LEVELS[key] || [25, 50]
  rescue
    [25, 50]
  end

  def hero_difficulty_phase(level)
    return 2 if level.to_i >= 50
    return 1 if level.to_i >= 25
    0
  end

  def enemy_progress_tier(seconds, level = 1)
    phase = hero_difficulty_phase(level)
    pressure = seconds.to_i
    pressure += [[level.to_i - 1, 0].max, 24].min * 5
    pressure += [[level.to_i - 25, 0].max, 24].min * 7
    pressure += [[level.to_i - 50, 0].max, 30].min * 10
    tier = if pressure < 90
             0
           elsif pressure < 230
             1
           elsif pressure < 470
             2
           else
             3
           end
    tier = [tier, 1].min if phase == 0
    tier = [tier, 2].min if phase == 1 && seconds.to_i < 420
    return tier
  end

  def doom_enemy?(name)
    name.to_s == DOOM_ENEMY_NAME
  end

  def enemy_allowed?(name, tier, kind = :wild, seconds = 0)
    return true if kind == :boss || kind == :chest
    return false if doom_enemy?(name) && seconds.to_i < DOOM_START_TIME
    total = species_base_total(name)
    stage = evolution_stage(name)
    case tier
    when 0 then stage <= 0 && total <= 360
    when 1 then stage <= 1 && total <= 460
    when 2 then stage <= 2 && total <= 535
    else true
    end
  end

  def hostile_to_base_attack?(name, base_attack_type)
    mod = type_multiplier(base_attack_type, species_types(name))
    mod < 1.0
  rescue
    false
  end

  def weighted_enemy_name(names, tier, level = 1, seconds = 0, base_attack_type = nil)
    weighted_enemy_pool(names, tier, level, seconds, base_attack_type).sample
  rescue
    names.sample
  end

  def spawn_wild_enemy_pool(arena = false, endless = false)
    @spawn_wild_enemy_pools ||= {}
    key = [!!arena, !!endless]
    return @spawn_wild_enemy_pools[key] if @spawn_wild_enemy_pools.key?(key)
    names = arena ? arena_wild_names : wild_names
    names = names.reject { |entry| doom_enemy?(entry) } if endless
    # Only register immutable snapshots; arbitrary caller-owned pools stay dynamic.
    names = names.map { |entry| entry.is_a?(String) ? entry.dup.freeze : entry }.freeze
    @spawn_enemy_pool_signatures ||= {}
    @spawn_enemy_pool_signatures[names.object_id] = names.map { |entry| species_key(entry).to_s }.sort.join("|")
    @spawn_wild_enemy_pools[key] = names
  end

  def weighted_enemy_pool(names, tier, level = 1, seconds = 0, base_attack_type = nil)
    @weighted_enemy_pool_cache ||= {}
    phase = hero_difficulty_phase(level)
    doom_bucket = seconds.to_i >= DOOM_ONLY_TIME ? :doom_only : (seconds.to_i >= DOOM_START_TIME ? ((seconds.to_i - DOOM_START_TIME) / 180) : :pre_doom)
    pool_signature = @spawn_enemy_pool_signatures && @spawn_enemy_pool_signatures[names.object_id]
    pool_signature ||= (names || []).map { |entry| species_key(entry).to_s }.sort.join("|")
    key = [pool_signature, tier.to_i, phase, [level.to_i / 5, 20].min, doom_bucket, base_attack_type]
    return @weighted_enemy_pool_cache[key] if @weighted_enemy_pool_cache[key]
    doom = names.find { |name| doom_enemy?(name) }
    return @weighted_enemy_pool_cache[key] = [doom] if doom && seconds.to_i >= DOOM_ONLY_TIME
    pool = names.select { |name| enemy_allowed?(name, tier, :wild, seconds) }
    pool.delete_if { |name| doom_enemy?(name) } if seconds.to_i < DOOM_START_TIME
    weak_pool = pool.select { |name| type_multiplier(base_attack_type, species_types(name)) > 1.0 }
    soft_pool = pool.select { |name| !hostile_to_base_attack?(name, base_attack_type) }
    if phase == 0 && level.to_i <= 9 && !weak_pool.empty?
      pool = weak_pool
    elsif phase == 0 && level.to_i < 25 && !weak_pool.empty?
      mixed = weak_pool * 5
      mixed.concat(soft_pool * 2)
      mixed.concat(pool.select { |name| !weak_pool.include?(name) && !soft_pool.include?(name) })
      pool = mixed
    elsif phase == 1 && !weak_pool.empty?
      mixed = weak_pool * 3
      mixed.concat(soft_pool * 2)
      mixed.concat(pool)
      pool = mixed
    elsif phase >= 2 && !weak_pool.empty?
      mixed = weak_pool * 2
      mixed.concat(soft_pool)
      mixed.concat(pool * 2)
      pool = mixed
    end
    if doom && seconds.to_i >= DOOM_START_TIME
      doom_weight = 1 + ((seconds.to_i - DOOM_START_TIME) / 180)
      doom_weight.times { pool << doom }
    end
    pool = names if pool.empty?
    weighted = []
    pool.each do |name|
      next if doom_enemy?(name) && seconds.to_i < DOOM_START_TIME
      total = species_base_total(name)
      stage = evolution_stage(name)
      effective = type_multiplier(base_attack_type, species_types(name)) > 1.0
      hostile = hostile_to_base_attack?(name, base_attack_type)
      weight = case tier
               when 0 then [10 - (stage * 4) - ((total - 250) / 35), 1].max
               when 1 then [6 - (stage * 2) + ((total - 320) / 95), 1].max
               when 2 then [3 + stage + ((total - 370) / 90), 1].max
               else [2 + (stage * 2) + ((total - 390) / 70), 1].max
               end
      weight += 6 if effective && phase == 0 && level.to_i <= 9
      weight += 4 if effective && phase == 0 && level.to_i < 25
      weight += 2 if effective && phase == 1
      weight += 2 if !hostile && phase == 0
      weight = [weight / 2, 1].max if hostile && phase == 0 && level.to_i < 18
      weight = 1 if doom_enemy?(name) && seconds.to_i < DOOM_ONLY_TIME
      weight.times { weighted << name }
    end
    @weighted_enemy_pool_cache[key] = (weighted.empty? ? pool : weighted)
  rescue
    names
  end

  def type_multiplier(attack_type, target_types)
    types = target_types || []
    return 1.0 if !attack_type || types.empty?
    if defined?(Effectiveness) && Effectiveness.respond_to?(:calculate)
      # Share identical matchups within a frame, without caching combat state.
      frame = Graphics.frame_count
      if @type_multiplier_cache_frame != frame
        @type_multiplier_cache = {}
        @type_multiplier_cache_frame = frame
      end
      matchups = (@type_multiplier_cache[attack_type] ||= {})
      cached = matchups[types]
      return cached if cached
      value = Effectiveness.calculate(attack_type, *types)
      normal = if Effectiveness.const_defined?(:NORMAL_EFFECTIVE)
                 Effectiveness::NORMAL_EFFECTIVE.to_f
               elsif Effectiveness.const_defined?(:NORMAL)
                 Effectiveness::NORMAL.to_f
               end
      mult = normal && normal > 1.0 ? value.to_f / normal : value.to_f
      mult = 0.25 if mult <= 0.0
      matchups[types.dup.freeze] = mult if matchups.length < 128
      return mult
    end
    1.0
  rescue
    1.0
  end

  def hero_data(name)
    key = species_key(name)
    data = HERO_BASE[key]
    return data.clone if data
    {
      hp: 110,
      speed: 2.35,
      skill: skill_for_species(key),
      color: Color.new(92, 188, 255)
    }
  end

  def sanitize_visible_text(text)
    return text if !text.is_a?(String)
    cleaned = text.gsub(/\bVFX_[A-Z0-9_]+\b\s*/i, "")
    cleaned.gsub!(/\s+/, " ")
    cleaned.gsub!(/\s+([,.!?:;])/, "\\1")
    cleaned.strip
  end

  def localized_data(data)
    return nil if !data
    ret = data.clone
    ret[:name] = sanitize_visible_text(_INTL(ret[:name])) if ret[:name].is_a?(String)
    ret[:desc] = sanitize_visible_text(_INTL(ret[:desc])) if ret[:desc].is_a?(String)
    ret
  rescue
    data.clone rescue data
  end

  def localized_skill(skill_id)
    localized_data(SKILLS[skill_id])
  end

  def localized_upgrade_pool
    pool = UPGRADE_POOL.map { |upgrade| localized_data(upgrade) }
    registered = {}
    pool.each { |upgrade| registered[upgrade[:skill]] = true if upgrade[:skill] }
    # New playable skills remain learnable even without a hand-written learn entry.
    unlocked_hero_skills.each do |skill_id|
      next if registered[skill_id] || !SKILLS[skill_id]
      skill = localized_skill(skill_id)
      pool << {
        id: "learn_shared_#{skill_id}".to_sym,
        name: _INTL("Learn {1}", skill[:name]), desc: skill[:desc],
        max: 1, skill: skill_id, rarity: skill[:learn_rarity] || :epic
      }
      registered[skill_id] = true
    end
    pool
  end

  def hero_passive(name)
    key = species_key(name)
    localized_data(HERO_PASSIVES[key]) || { name: _INTL("Survivor Instinct"), desc: _INTL("This Pokemon has no special passive yet.") }
  end

  def ultimate_data(name)
    key = species_key(name)
    data = ULTIMATES[key]
    localized_data(data)
  end

  def skill_for_species(species)
    data = GameData::Species.try_get(game_species_key(species)) rescue nil
    types = []
    types = data.types if data && data.respond_to?(:types)
    return :fire if types.include?(:FIRE)
    return :flying_gust if types.include?(:FLYING)
    return :bug_thread if types.include?(:BUG)
    return :water if types.include?(:WATER)
    return :leaf if types.include?(:GRASS)
    return :thunder_ring if types.include?(:ELECTRIC)
    return :poison_aura if types.include?(:POISON)
    return :ice_zone if types.include?(:ICE)
    return :fairy_guard if types.include?(:FAIRY)
    return :steel_orbit if types.include?(:STEEL)
    return :ground_spike if types.include?(:GROUND)
    return :fighting_dash if types.include?(:FIGHTING)
    return :dark_wave if types.include?(:DARK)
    return :dragon_arc if types.include?(:DRAGON)
    return :ghost_wisp if types.include?(:GHOST)
    return :psychic_sweep if species_key(species) == :DEOXYS
    return :psychic if types.include?(:PSYCHIC) || types.include?(:FAIRY)
    return :normal_shot if types.include?(:NORMAL)
    :normal_shot
  rescue
    :normal_shot
  end


  def eight_direction_hero_keys
    @eight_direction_hero_keys ||= EIGHT_DIRECTION_HERO_SPRITES.map { |entry| species_key(entry) }.uniq
  rescue
    EIGHT_DIRECTION_HERO_SPRITES.map { |entry| species_key(entry) }
  end

  def eight_direction_hero?(name)
    eight_direction_hero_keys.include?(species_key(name))
  rescue
    false
  end

  def static_eight_direction_idle?(name)
    EIGHT_DIRECTION_STATIC_IDLE_HEROES.map { |entry| species_key(entry) }.include?(species_key(name))
  rescue
    false
  end

  def eight_direction_asset_name?(name)
    base = name.to_s.upcase.sub(/_IDLE\z/, "")
    eight_direction_hero_keys.include?(species_key(base))
  rescue
    false
  end

  def eight_direction_asset_frame_count(name)
    key = name.to_s.upcase
    key = key.sub(/_IDLE\z/, "_IDLE")
    EIGHT_DIRECTION_ASSET_FRAMES[key]
  rescue
    nil
  end

  def eight_direction_enemy_asset_frame_count(name)
    raw_key = name.to_s.upcase
    key = species_key(name).to_s
    EIGHT_DIRECTION_ENEMY_ASSET_FRAMES[raw_key] || EIGHT_DIRECTION_ENEMY_ASSET_FRAMES[key] || EIGHT_DIRECTION_ASSET_FRAMES[raw_key] || EIGHT_DIRECTION_ASSET_FRAMES[key]
  rescue
    nil
  end

  def eight_direction_enemy_folder?(folder)
    path = folder.to_s
    path == WILD_DIR || path == BOSS_DIR || path == ULTRA_BEAST_DIR || path == PARADOX_DIR || path == ULTRA_BOSS_DIR || path == CHEST_DIR || path == ULTRA_CHEST_DIR
  rescue
    false
  end

  def register_eight_direction_bitmap(bitmap, frame_count = nil)
    return if !bitmap || bitmap.disposed?
    @eight_direction_bitmap_ids ||= {}
    @eight_direction_bitmap_ids[bitmap.object_id] = true
    @eight_direction_bitmap_frames ||= {}
    if frame_count.to_i > 0
      @eight_direction_bitmap_frames[bitmap.object_id] = frame_count.to_i
    else
      @eight_direction_bitmap_frames.delete(bitmap.object_id)
    end
  rescue
  end

  def eight_direction_bitmap?(bitmap)
    @eight_direction_bitmap_ids ||= {}
    !!(bitmap && !bitmap.disposed? && @eight_direction_bitmap_ids[bitmap.object_id])
  rescue
    false
  end

  def unregister_eight_direction_bitmap(bitmap)
    return if !bitmap
    @eight_direction_bitmap_ids.delete(bitmap.object_id) if @eight_direction_bitmap_ids
    @eight_direction_bitmap_frames.delete(bitmap.object_id) if @eight_direction_bitmap_frames
  end

  def eight_direction_bitmap_frame_count(bitmap)
    @eight_direction_bitmap_frames ||= {}
    @eight_direction_bitmap_frames[bitmap.object_id]
  rescue
    nil
  end


  def charset_frame_count(source, direction = DIR_DOWN, directions = nil)
    return CHARSET_FRAMES if !source || source.disposed?
    dirs = directions.to_i > 0 ? directions.to_i : (eight_direction_bitmap?(source) ? CHARSET_8_DIRECTIONS : CHARSET_DIRECTIONS)
    if dirs >= CHARSET_8_DIRECTIONS && source.height >= CHARSET_8_DIRECTIONS && source.height % CHARSET_8_DIRECTIONS == 0
      frames = eight_direction_bitmap_frame_count(source).to_i
      return [frames, 1].max if frames > 0
      return CHARSET_FRAMES
    end
    CHARSET_FRAMES
  rescue
    CHARSET_FRAMES
  end
  def load_bitmap(folder, name)
    path = resolve(folder, name)
    if path
      bitmap = Bitmap.new(path)
      if [HERO_DIR, HERO_SHINY_DIR, HERO_ALT_DIR, HERO_ALT_SHINY_DIR].include?(folder.to_s) && eight_direction_asset_name?(name)
        register_eight_direction_bitmap(bitmap, eight_direction_asset_frame_count(name))
      elsif eight_direction_enemy_folder?(folder)
        frames = eight_direction_enemy_asset_frame_count(name).to_i
        register_eight_direction_bitmap(bitmap, frames) if frames > 0
      end
      return bitmap
    end
    nil
  rescue Exception
    nil
  end

  def draw_bitmap_centered(target, source, x, y, zoom = 1.0)
    return if !target || !source || source.disposed?
    w = (source.width * zoom).round
    h = (source.height * zoom).round
    left = (x - w / 2).round
    top = (y - h / 2).round
    source_rect = Rect.new(0, 0, source.width, source.height)
    if w == source.width && h == source.height
      target.blt(left, top, source, source_rect)
    else
      target.stretch_blt(Rect.new(left, top, w, h), source, source_rect)
    end
  rescue
  end

  def charset_rect(source, direction = DIR_DOWN, frame = 0, directions = nil)
    return Rect.new(0, 0, source.width, source.height) if !source
    dirs = directions.to_i > 0 ? directions.to_i : (eight_direction_bitmap?(source) ? CHARSET_8_DIRECTIONS : CHARSET_DIRECTIONS)
    if dirs >= CHARSET_8_DIRECTIONS && source.height >= CHARSET_8_DIRECTIONS && source.height % CHARSET_8_DIRECTIONS == 0
      frame_h = [source.height / CHARSET_8_DIRECTIONS, 1].max
      frames = eight_direction_bitmap_frame_count(source).to_i
      return Rect.new(0, 0, source.width, source.height) if frames <= 0
      frames = [[frames, 1].max, source.width].min
      frame_w = [source.width / frames, 1].max
      col = [[frame.to_i, 0].max, frames - 1].min
      row = [[direction.to_i, 0].max, CHARSET_8_DIRECTIONS - 1].min
      return Rect.new(col * frame_w, row * frame_h, frame_w, frame_h)
    end
    if source.width >= CHARSET_FRAMES && source.height >= CHARSET_DIRECTIONS &&
       source.width % CHARSET_FRAMES == 0 && source.height % CHARSET_DIRECTIONS == 0
      frame_w = source.width / CHARSET_FRAMES
      frame_h = source.height / CHARSET_DIRECTIONS
      col = [[frame.to_i, 0].max, CHARSET_FRAMES - 1].min
      row = [[direction.to_i, 0].max, CHARSET_DIRECTIONS - 1].min
      return Rect.new(col * frame_w, row * frame_h, frame_w, frame_h)
    end
    Rect.new(0, 0, source.width, source.height)
  rescue
    Rect.new(0, 0, source.width, source.height)
  end

  def draw_character_centered(target, source, x, y, direction = DIR_DOWN, frame = 0, zoom = 1.0, directions = nil)
    return if !target || !source || source.disposed?
    src = charset_rect(source, direction, frame, directions)
    w = (src.width * zoom).round
    h = (src.height * zoom).round
    rect = Rect.new((x - w / 2).round, (y - h / 2 + CHARACTER_VISUAL_Y_OFFSET).round, w, h)
    target.stretch_blt(rect, source, src)
  rescue
  end

  def tinted_character_bitmap(source, src, tint, strength)
    @tinted_character_cache ||= {}
    strength_key = (strength.to_f * 100).round
    key = [source.object_id, src.x, src.y, src.width, src.height, tint.red, tint.green, tint.blue, tint.alpha, strength_key]
    cached = @tinted_character_cache[key]
    if cached && !cached.disposed?
      # Keep frequently drawn clone frames warm without enlarging the cache.
      @tinted_character_cache.delete(key)
      @tinted_character_cache[key] = cached
      return cached
    end
    if @tinted_character_cache.length >= 384
      _, old = @tinted_character_cache.shift
      old.dispose if old && !old.disposed?
    end
    tinted = Bitmap.new(src.width, src.height)
    strength = [[strength.to_f, 0.0].max, 1.0].min
    inverse = 1.0 - strength
    for py in 0...src.height
      for px in 0...src.width
        color = source.get_pixel(src.x + px, src.y + py)
        next if color.alpha <= 0
        red = (color.red * inverse + tint.red * strength).round
        green = (color.green * inverse + tint.green * strength).round
        blue = (color.blue * inverse + tint.blue * strength).round
        tinted.set_pixel(px, py, Color.new(red, green, blue, color.alpha))
      end
    end
    @tinted_character_cache[key] = tinted
    tinted
  rescue
    nil
  end

  def draw_character_centered_tinted(target, source, x, y, direction, frame, zoom, tint, strength = 0.35, directions = nil)
    return draw_character_centered(target, source, x, y, direction, frame, zoom, directions) if !tint
    return if !target || !source || source.disposed?
    src = charset_rect(source, direction, frame, directions)
    tinted = tinted_character_bitmap(source, src, tint, strength)
    return draw_character_centered(target, source, x, y, direction, frame, zoom, directions) if !tinted || tinted.disposed?
    w = (src.width * zoom).round
    h = (src.height * zoom).round
    rect = Rect.new((x - w / 2).round, (y - h / 2 + CHARACTER_VISUAL_Y_OFFSET).round, w, h)
    target.stretch_blt(rect, tinted, Rect.new(0, 0, tinted.width, tinted.height))
  rescue
    draw_character_centered(target, source, x, y, direction, frame, zoom, directions)
  end
  def clear_tinted_character_cache
    return if !@tinted_character_cache
    @tinted_character_cache.each_value do |bmp|
      next if !bmp
      unregister_eight_direction_bitmap(bmp)
      bmp.dispose if !bmp.disposed?
    end
    @tinted_character_cache.clear
  rescue
  end

  def draw_text_center(bitmap, text, x, y, w, base = Color.white, shadow = Color.new(40, 40, 48))
    pbSetSystemFont(bitmap)
    pbDrawTextPositions(bitmap, [[text.to_s, x + (w / 2), y, 2, base, shadow]])
  rescue
  end
end

