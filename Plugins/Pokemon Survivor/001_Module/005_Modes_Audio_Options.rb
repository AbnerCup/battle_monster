#===============================================================================
# Pokemon Survivor - modes, audio and options
#===============================================================================
module PokemonSurvivor
  BACKGROUNDS = ["Cave 2", "Cave 3", "Cave 4", "Cave", "Field", "Forest 2", "Forest", "Ice", "Ice 2", "Route", "Temple", "Tower 2", "Tower"]
  RUSH_BACKGROUND = "Rush"
  TOWER_BACKGROUND = "Tower Mode"
  TOWER_MAX_FLOOR = 50
  TOWER_FINAL_BOSS = "RAYQUAZA"
  TOWER_FINAL_BOSSES = ["RAYQUAZA", "GIRATINA", "KYUREM", "ZYGARDE_2", "NECROZMA", "ETERNATUS", "TERAPAGOS_1"]
  FUTURE_RESERVED_BOSSES = [:ARCEUS, :REGIGIGAS, :DARKRAI, :KYUREM_1, :KYUREM_2, :HOOPA, :HOOPA_1, :VOLCANION, :ZYGARDE, :ZYGARDE_2, :TYPENULL, :SILVALLY, :ZERAORA, :WISHIWASHI_1, :NECROZMA_1, :NECROZMA_2, :NECROZMA_3, :ETERNATUS_1, :ZACIAN_1, :ZAMAZENTA_1]
  ULTRA_BEAST_BOSS_KEYS = [:NIHILEGO, :BUZZWOLE, :PHEROMOSA, :XURKITREE, :CELESTEELA, :KARTANA, :GUZZLORD, :POIPOLE, :NAGANADEL, :STAKATAKA, :BLACEPHALON]
  FUTURE_RESERVED_BOSSES.concat([:TERAPAGOS, :TERAPAGOS_1, :OGERPON] + (1..7).map { |form| "OGERPON_#{form}".to_sym })
  PARADOX_BOSS_KEYS = [:GREATTUSK, :FLUTTERMANE, :IRONBUNDLE, :IRONHANDS, :IRONLEAVES,
    :IRONMOTH, :IRONTHORNS, :IRONVALIANT, :ROARINGMOON, :SANDYSHOCKS, :SCREAMTAIL,
    :SLITHERWING, :WALKINGWAKE].freeze
  RUSH_BOSS_THEMES = [
    [[:ARTICUNO, :ARTICUNO_1], [:MOLTRES, :MOLTRES_1], [:ZAPDOS, :ZAPDOS_1], [:MEWTWO]],
    [[:RAIKOU], [:SUICUNE], [:ENTEI], [:HOOH, :LUGIA]],
    [[:REGIROCK], [:REGICE], [:REGISTEEL], [:KYOGRE, :GROUDON]],
    [[:UXIE], [:MESPRIT], [:AZELF], [:DIALGA, :PALKIA]],
    [[:LANDORUS], [:THUNDURUS], [:TORNADUS], [:RESHIRAM, :ZEKROM]],
    [[:NOIVERN], [:XERNEAS], [:YVELTAL], [:ZYGARDE_1]],
    [ULTRA_BEAST_BOSS_KEYS, ULTRA_BEAST_BOSS_KEYS, ULTRA_BEAST_BOSS_KEYS, [:SOLGALEO, :LUNALA]],
    [[:REGIELEKI], [:REGIDRAGO], [:ENAMORUS, :ENAMORUS_1], [:ZACIAN, :ZAMAZENTA]],
    [PARADOX_BOSS_KEYS, PARADOX_BOSS_KEYS, PARADOX_BOSS_KEYS, [:KORAIDON, :MIRAIDON]]
  ]
  RUSH_BOSS_HP = [104000, 270000, 680000, 1560000]
  RUSH_BOSS_DAMAGE = [16, 28, 44, 64]
  RUSH_BOSS_XP = [90, 240, 620, 1100]
  RUSH_BOSS_SHOT_COOLDOWNS = [1.45, 1.18, 0.96, 0.72]
  BGM_BY_BACKGROUND = BACKGROUNDS.each_with_object({}) { |name, hash| hash[name.to_s] = "Survivor/#{name}" }
  DEFAULT_BGM = "Survivor/Battle wild"
  MENU_BGM = "Survivor/Menu"
  LEADERBOARD_BGM = "Survivor/Leaderboard"
  ACHIEVEMENT_BGM = "Survivor/Achievement"
  OPTIONS_BGM = "Survivor/Options"
  UPGRADE_BGM = nil
  RESULT_BGM = "Survivor/Result"
  ULTRA_BOSS_BGM = "Survivor/Ultra Boss"
  AUDIO_REFERENCE_VOLUME = 80
  BGM_VOLUME = 48
  UI_MENU_VOLUME = 58
  UI_CURSOR_VOLUME = 52
  UI_DECISION_VOLUME = 64
  SFX_ITEM_VOLUME = 62
  SFX_SHOT_VOLUME = 28
  SFX_HIT_VOLUME = 34
  SFX_KO_VOLUME = 30
  SFX_BOSS_KO_VOLUME = 66
  SFX_HERO_HIT_VOLUME = 64
  SFX_LEVEL_VOLUME = 70
  SFX_XP_VOLUME = 28
  SFX_EVOLUTION_VOLUME = 70
  SFX_EVOLUTION_VFX_VOLUME = 66
  SFX_UPGRADE_CONSUME_VOLUME = 66
  TV_FILTER_VFX = "VFX_TV_FILTER"
  TV_FILTER_OPACITY = 58
  TV_FILTER_SCROLL_X = 10.0
  TV_FILTER_SCROLL_Y = 28.0
  TV_FILTER_STRIP_HEIGHT = 6
  TV_FILTER_EDGE_PINCH = 10
  TV_FILTER_WAVE = 2
  DISCORD_INVITE_URL = "https://discord.com/invite/TBWbpbF4aG"
  SCREEN_SIZE_LABELS = ["S", "M", "L", "XL", "Full"]
  SHOP_CURRENCY_NAME = "Fragments"
  DARK_SHOP_CURRENCY_NAME = "Dark Fragment"
  CANDY_CURRENCY_NAME = "Candies"
  DARK_FRAGMENT_CONVERSION_RATE = 1000
  LEADERBOARD_MODES = ["classic", "rush", "tower", "endless"]
  ENDLESS_DIFFICULTY_STEP_SECONDS = 5 * 60
  ENDLESS_SCORE_PER_SECOND = 140
  ENDLESS_SCORE_PER_LEVEL = 1250
  ENDLESS_SCORE_STAGE_BONUS = 7500
  ENDLESS_SHOP_UPGRADES = [
    { id: :endless_xp, name: "Endless EXP", desc: "Increases EXP gained from drops in Endless Mode only.", effect: :endless_xp_gain_percent, values: [6, 14, 24, 36], costs: [2, 4, 8, 15], icon: "Exp" },
    { id: :endless_hp, name: "Endless Vitality", desc: "Start Endless Mode with higher max HP.", effect: :endless_max_hp_percent, values: [4, 8, 14, 22], costs: [2, 5, 9, 17], icon: "HP" },
    { id: :endless_damage, name: "Endless Power", desc: "Attacks deal more damage in Endless Mode only.", effect: :endless_damage_percent, values: [3, 6, 10, 15], costs: [2, 5, 10, 19], icon: "Atk" },
    { id: :endless_speed, name: "Endless Footwork", desc: "Start Endless Mode with higher movement speed.", effect: :endless_speed_percent, values: [3, 6, 9, 13], costs: [2, 4, 8, 16], icon: "Speed" },
    { id: :endless_burst, name: "Endless Burst", desc: "Burst gauge charges faster in Endless Mode only.", effect: :endless_burst_charge_percent, values: [4, 8, 13, 19], costs: [3, 6, 11, 21], icon: "Burst" },
    { id: :endless_pressure, name: "Endless Control", desc: "Endless difficulty rises slightly more slowly.", effect: :endless_pressure_relief_percent, values: [5, 10, 15, 20], costs: [3, 6, 12, 23], icon: "Steady" },
    { id: :endless_reroll, name: "Endless Draft", desc: "Start Endless Mode with extra bonus rerolls and bans.", effect: :endless_draft_bonus, values: [1, 2], costs: [3, 8], icon: "Reroll" },
    { id: :endless_revive, name: "Endless Charm", desc: "Start Endless Mode with extra fatal-hit saves.", effect: :endless_fatal_guard_charges, values: [1, 2], costs: [12, 28], icon: "Revive" },
    { id: :endless_candy_exchange, name: "Candy", desc: "Trade Dark Fragments for Candies. This can be bought any number of times.", effect: :candy_exchange_amount, values: [75], costs: [1], icon: "Candy", infinite: true }
  ]
  SHOP_UPGRADES = [
    { id: :xp_drop, name: "EXP Boost", desc: "EXP drops give more EXP.", effect: :xp_gain_percent, values: [10, 25, 50, 90, 150, 240, 380, 600], costs: [120, 300, 720, 1450, 2900, 5600, 11200, 24000], icon: "Exp" },
    { id: :coin_gain, name: "Fragment Bonus", desc: "Earn more Fragments after completed or lost runs.", effect: :coin_gain_percent, values: [5, 10, 18, 28, 40], costs: [180, 460, 1050, 2300, 5200], icon: "Coin" },
    { id: :starting_hp, name: "HP Training", desc: "Start each run with more max HP. Stacks with run bonuses.", effect: :max_hp_percent, values: [5, 10, 18, 28, 40], costs: [220, 540, 1250, 2700, 5900], icon: "HP" },
    { id: :starting_damage, name: "Attack Training", desc: "Start each run with stronger attacks. Stacks with run bonuses.", effect: :damage_percent, values: [3, 7, 12, 18, 25], costs: [260, 650, 1500, 3300, 7200], icon: "Atk" },
    { id: :starting_speed, name: "Move Training", desc: "Start each run with higher movement speed. Stacks with run bonuses.", effect: :speed_percent, values: [3, 6, 10, 15], costs: [180, 480, 1150, 2600], icon: "Speed" },
    { id: :burst_starter, name: "Burst Training", desc: "Start each run with faster Burst charge. Stacks with run bonuses.", effect: :burst_charge_percent, values: [3, 7, 12, 18, 25], costs: [300, 760, 1750, 3900, 8400], icon: "Burst" },
    { id: :sharp_start, name: "Sharp Start", desc: "Levels 1 to 10 need less EXP.", effect: :early_level_xp_percent, values: [25], costs: [3600], icon: "Sharp" },
    { id: :steady_burst, name: "Steady Burst", desc: "Start each run with Burst partly charged.", effect: :starting_burst_percent, values: [8, 16, 25], costs: [1400, 3600, 7600], icon: "Steady" },
    { id: :fatal_guard_stock, name: "Last Stand Charm", desc: "Start each run with extra saves from fatal hits.", effect: :fatal_guard_charges, values: [1, 2], costs: [2200, 6800], icon: "Revive" },
    { id: :reroll_stock, name: "Prepared Choices", desc: "Start each run with extra bonus rerolls.", effect: :reroll_bonus, values: [1, 2, 3], costs: [520, 1500, 4200], icon: "Reroll" },
    { id: :ban_stock, name: "Strict Draft", desc: "Start each run with extra bonus bans.", effect: :ban_bonus, values: [1, 2, 3], costs: [520, 1500, 4200], icon: "Ban" }
  ]
  RUN_INFO_PANEL_MODES = [:stats, :bonuses, :both]
  RUN_INFO_PANEL_LABELS = {
    stats: "Stats",
    bonuses: "Bonuses",
    both: "Both"
  }
  AUTO_BONUS_MODES = [:semi_auto, :auto, :disabled].freeze
  DEFAULT_PERFORMANCE_OPTIONS = {
    tv_filter: false,
    color_accessibility: :off,
    reduced_vfx: false,
    reinforced_hp_bars: true,
    run_info_panel: :stats,
    auto_bonus: :semi_auto
  }

  def performance_options
    $PokemonSurvivorPerformanceOptions ||= DEFAULT_PERFORMANCE_OPTIONS.dup
    load_persistent_survivor_options if respond_to?(:load_persistent_survivor_options) && !$PokemonSurvivorPerformanceOptions[:persistent_options_loaded]
    $PokemonSurvivorPerformanceOptions ||= DEFAULT_PERFORMANCE_OPTIONS.dup
    DEFAULT_PERFORMANCE_OPTIONS.each_pair { |key, value| $PokemonSurvivorPerformanceOptions[key] = value if !$PokemonSurvivorPerformanceOptions.key?(key) }
    $PokemonSurvivorPerformanceOptions
  rescue
    DEFAULT_PERFORMANCE_OPTIONS.dup
  end

  def performance_option?(key)
    performance_options[key] != false
  rescue
    DEFAULT_PERFORMANCE_OPTIONS[key] != false
  end

  def set_performance_option(key, value)
    performance_options[key] = value ? true : false
    save_persistent_survivor_options if respond_to?(:save_persistent_survivor_options)
  rescue
  end

  def toggle_performance_option(key)
    set_performance_option(key, !performance_option?(key))
  rescue
  end

  def run_info_panel_mode
    value = performance_options[:run_info_panel]
    value = value.to_sym if value.respond_to?(:to_sym)
    RUN_INFO_PANEL_MODES.include?(value) ? value : :stats
  rescue
    :stats
  end

  def set_run_info_panel_mode(value)
    value = value.to_sym if value.respond_to?(:to_sym)
    value = :stats if !RUN_INFO_PANEL_MODES.include?(value)
    performance_options[:run_info_panel] = value
    save_persistent_survivor_options if respond_to?(:save_persistent_survivor_options)
  rescue
  end

  def cycle_run_info_panel_mode(dir = 1)
    current = run_info_panel_mode
    index = RUN_INFO_PANEL_MODES.index(current) || 0
    set_run_info_panel_mode(RUN_INFO_PANEL_MODES[(index + dir.to_i) % RUN_INFO_PANEL_MODES.length])
  rescue
  end

  def run_info_panel_label
    _INTL(RUN_INFO_PANEL_LABELS[run_info_panel_mode] || "Stats")
  rescue
    _INTL("Stats")
  end

  def auto_bonus_mode
    value = performance_options[:auto_bonus]
    value = value.to_sym if value.respond_to?(:to_sym)
    AUTO_BONUS_MODES.include?(value) ? value : :semi_auto
  end

  def cycle_auto_bonus_mode(dir = 1)
    index = AUTO_BONUS_MODES.index(auto_bonus_mode)
    performance_options[:auto_bonus] = AUTO_BONUS_MODES[(index + dir.to_i) % AUTO_BONUS_MODES.length]
    save_persistent_survivor_options if respond_to?(:save_persistent_survivor_options)
  end

  def auto_bonus_label
    case auto_bonus_mode
    when :auto then _INTL("Auto")
    when :disabled then _INTL("Disabled")
    else _INTL("Semi-Auto")
    end
  end

  def ensure_pokemon_system
    $PokemonSystem = PokemonSystem.new if !$PokemonSystem && defined?(PokemonSystem)
    if $PokemonSystem && respond_to?(:load_persistent_survivor_options) && !@loading_persistent_survivor_options
      opts = $PokemonSurvivorPerformanceOptions
      system_id = $PokemonSystem.object_id rescue nil
      needs_reload = !opts.is_a?(Hash) || !opts[:persistent_options_loaded] || (@persistent_options_system_id && @persistent_options_system_id != system_id)
      if needs_reload
        @loading_persistent_survivor_options = true
        load_persistent_survivor_options(@persistent_options_system_id && @persistent_options_system_id != system_id)
        @loading_persistent_survivor_options = false
      end
      @persistent_options_system_id = system_id
    end
    $PokemonSystem
  rescue
    @loading_persistent_survivor_options = false
    nil
  end

  def screen_size_index
    system = ensure_pokemon_system
    [[(system.screensize rescue 1).to_i, 0].max, SCREEN_SIZE_LABELS.length - 1].min
  rescue
    1
  end

  def set_screen_size_index(value)
    system = ensure_pokemon_system
    return if !system
    value = [[value.to_i, 0].max, SCREEN_SIZE_LABELS.length - 1].min
    return if (system.screensize rescue value) == value
    system.screensize = value
    pbSetResizeFactor(value) if defined?(pbSetResizeFactor)
    save_persistent_survivor_options if respond_to?(:save_persistent_survivor_options)
  rescue
  end

  def bgm_volume
    system = ensure_pokemon_system
    [[(system.bgmvolume rescue AUDIO_REFERENCE_VOLUME).to_i, 0].max, 100].min
  rescue
    AUDIO_REFERENCE_VOLUME
  end

  def set_bgm_volume(value)
    system = ensure_pokemon_system
    return if !system
    system.bgmvolume = [[value.to_i, 0].max, 100].min
    save_persistent_survivor_options if respond_to?(:save_persistent_survivor_options)
  rescue
  end

  def se_volume
    system = ensure_pokemon_system
    [[(system.sevolume rescue 100).to_i, 0].max, 100].min
  rescue
    100
  end

  def set_se_volume(value)
    system = ensure_pokemon_system
    return if !system
    system.sevolume = [[value.to_i, 0].max, 100].min
    if $game_system && ($game_system.playing_bgs rescue nil)
      $game_system.playing_bgs.volume = system.sevolume rescue nil
      playing_bgs = ($game_system.getPlayingBGS rescue nil)
      if playing_bgs
        $game_system.bgs_pause rescue nil
        $game_system.bgs_resume(playing_bgs) rescue nil
      end
    end
    save_persistent_survivor_options if respond_to?(:save_persistent_survivor_options)
  rescue
  end

  def survivor_bgm_volume
    [[(BGM_VOLUME.to_f * bgm_volume.to_f / AUDIO_REFERENCE_VOLUME.to_f).round, 0].max, 100].min
  rescue
    BGM_VOLUME
  end

  module_function :performance_options, :performance_option?, :set_performance_option, :toggle_performance_option,
                  :auto_bonus_mode, :cycle_auto_bonus_mode, :auto_bonus_label,
                  :run_info_panel_mode, :set_run_info_panel_mode, :cycle_run_info_panel_mode, :run_info_panel_label,
                  :ensure_pokemon_system, :screen_size_index, :set_screen_size_index,
                  :bgm_volume, :set_bgm_volume, :se_volume, :set_se_volume, :survivor_bgm_volume,
                  :password_text_input, :whismur_unlock_password?

  ENEMY_ARCHETYPES = {
    :normal => { hp: 1.00, damage: 1.00, speed: 1.00, value: 1.00, radius: 1.00 },
    :quick  => { hp: 0.70, damage: 0.85, speed: 1.45, value: 1.05, radius: 0.88 },
    :sturdy => { hp: 1.75, damage: 1.05, speed: 0.72, value: 1.35, radius: 1.12 },
    :sharp  => { hp: 0.95, damage: 1.55, speed: 1.12, value: 1.25, radius: 1.00 },
    :elite  => { hp: 2.40, damage: 1.65, speed: 0.95, value: 2.20, radius: 1.18 }
  }
  ENEMY_SHOOTERS = [:SEADRA, :HORSEA, :STARYU, :STARMIE, :MAGNEMITE, :MAGNETON,
                    :VOLTORB, :ELECTRODE, :ABRA, :KADABRA, :GASTLY, :HAUNTER,
                    :REMORAID, :OCTILLERY, :INKAY, :MALAMAR,
                    :PORYGON, :PORYGON2, :VULPIX, :GROWLITHE,
                    :BELLSPROUT, :SEEDOT, :SNORUNT, :VANILLITE,
                    :MACHOP, :RIOLU, :EKANS, :KOFFING, :SANDSHREW, :PHANPY,
                    :NOIBAT, :VENONAT, :SEWADDLE, :ROGGENROLA, :BOLDORE,
                    :KLINK, :KLANG, :DRATINI, :GOOMY, :CLEFAIRY, :SPRITZEE,
                    :SMOLIV, :TADBULB, :WATTREL, :FLITTLE,
                    :GLIMMET, :VAROOM, :TATSUGIRI, :TOEDSCOOL,
                    :ODDISH, :SHELLDER, :HOUNDOUR, :SLUGMA,
                    :CACNEA, :SPHEAL, :HIPPOPOTAS, :SNOVER,
                    :ELGYEM, :LITWICK, :CLAUNCHER, :SKRELP,
                    :MAREANIE, :JANGMOO, :SNOM, :DURALUDON]
  ENEMY_WILD_PROJECTILE_TYPES = { SNOVER: :ICE, SNOM: :BUG }.freeze
  # Enemy shots use flying projectiles, not player trail/zone/orbit visuals.
  ENEMY_PROJECTILE_VFX = VFX_BY_TYPE.merge(
    ICE: "VFX_ICE", POISON: "VFX_POISON", STEEL: "VFX_STEEL",
    GROUND: "VFX_GROUND4", FLYING: "VFX_FLYING_ORBIT", BUG: "VFX_BUG3", FAIRY: "VFX_FAIRY2"
  ).freeze
  ENEMY_PROJECTILE_VFX_REPLACEMENTS = {
    "VFX_FAIRY" => "VFX_FAIRY2", "VFX_DRAGON_TRAIL" => "VFX_DRAGON",
    "VFX_GROUND" => "VFX_GROUND4", "VFX_ICE_ZONE" => "VFX_ICE",
    "VFX_POISON_TRAIL" => "VFX_POISON", "VFX_FLYING" => "VFX_FLYING_ORBIT",
    "VFX_BUG" => "VFX_BUG3"
  }.freeze
  WILD_ITEMS = {
    "BERRY"     => { weight: 42, color: Color.new(255, 96, 118) },
    "EXPITEM"   => { weight: 30, color: Color.new(92, 255, 180) },
    "LIFEITEM"  => { weight: 18, color: Color.new(255, 238, 96) },
    "POWERITEM" => { weight: 10, color: Color.new(255, 132, 64) }
  }
  SUPABASE_URL      = ""
  SUPABASE_KEY_ENV  = "SURVIVOR_SUPABASE_ANON_KEY"
  SUPABASE_KEY_FILE = "Data/SurvivorSupabaseAnonKey.txt"
  SUPABASE_URL_FILE = "Data/SurvivorSupabaseUrl.txt"
  SUPABASE_LAST_RESULT_FILE = "Data/SurvivorSupabaseLast.txt"
  SUPABASE_OUTPUT_FILE = "Data/SurvivorSupabaseOutput.txt"
  TRAINER_NAME_STATUS_FILE = "Data/SurvivorTrainerNameStatus.txt"
  SUPABASE_TABLE    = "survivor_runs"
  SUPABASE_SUBMIT_URL = ""
  SUPABASE_SUBMIT_URL_FILE = "Data/SurvivorSupabaseSubmitUrl.txt"
  SUPABASE_ENABLED  = true
  LEADERBOARD_LIMIT = 100
  TRAINER_NAME_MAX_LENGTH = 7
  PROTECTED_TEXT_VERSION = "SVENC1"
  PROTECTED_TEXT_KEY = "PokemonSurvivorsBurstLeaderboardGuard"
end

