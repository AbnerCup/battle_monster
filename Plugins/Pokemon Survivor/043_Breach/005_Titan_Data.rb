#===============================================================================
# Titan season definitions. Boss assets never use the ordinary enemy frame table.
# The scene integration must opt in explicitly; this file adds no run hooks.
#===============================================================================
module PokemonSurvivor
  module Titan
    BOSS_DIRECTORY = "Graphics/UI/Survivor Game/Seasons Boss".freeze
    BOSS_TIME = 300
    EVOLUTION_TIME = 600
    CLONE_TIME = 900
    SEAL_COUNT = 8
    ORE_ICON = "Ore".freeze
    CRYSTAL_ICON = "Crystal Shard".freeze
    BOSS_BGM = "Season_Boss".freeze
    BOSS_PHASE2_BGM = "Season_Boss2".freeze

    def self.deep_freeze(value)
      value.each { |key, item| deep_freeze(key); deep_freeze(item) } if value.is_a?(Hash)
      value.each { |item| deep_freeze(item) } if value.is_a?(Array)
      value.freeze
    end

    SEASONS = deep_freeze({
      1 => {
        boss: :MEWTWO, final: :MEWTWO_1,
        frames: { MEWTWO: { walk: 6, shoot: 13 }, MEWTWO_1: { walk: 6, shoot: 13 } },
        background: "Season_1", map_bgm: "Seasons", boss_bgm: BOSS_BGM,
        projectile: { vfx: "VFX_PSYCHIC5", frames: 6, loop: true,
                      type: :PSYCHIC, visual_scale: 2.0 },
        reward_pokemon: :MEWTWO, reward_frames: [6, 8],
        reward_item: :mewtwonitey, reward_mega: :MEWTWO_2, mega_frames: [6, 8],
        reward_cosmetic: :prestige_crystal,
        # Calibration starts from 1,000 successful contributions, not a run limit.
        target_contributions: 100 * 10,
        playable_ready: true
      },
      2 => {
        boss: :LUGIA, final: :LUGIA_1, species: :LUGIA, patterns: :lugia,
        frames: { LUGIA: { walk: 2, shoot: 10 }, LUGIA_1: { walk: 2, shoot: 10 } },
        background: "Season_2", map_bgm: "Seasons", boss_bgm: BOSS_BGM,
        projectile: { vfx: "VFX_FLYING", type: :FLYING, visual_scale: 2.0 },
        reward_pokemon: :CELEBI, reward_cosmetic: :prestige_crystal,
        playable_ready: true
      },
      3 => {
        boss: :KYUREM, final: :KYUREM_1, final_forms: [:KYUREM_1, :KYUREM_2],
        species: :KYUREM, types: [:DRAGON, :ICE], patterns: :kyurem,
        frames: { KYUREM: { walk: 4, shoot: 12 }, KYUREM_1: { walk: 4, shoot: 17 },
                  KYUREM_2: { walk: 4, shoot: 16 } },
        background: "Season_3", map_bgm: "Seasons", boss_bgm: BOSS_BGM,
        projectile: { vfx: "VFX_ICE", type: :ICE, visual_scale: 2.0 },
        reward_pokemon: :VICTINI, reward_cosmetic: :prestige_crystal,
        playable_ready: true
      }
    })

    # Same effects and cumulative ranks as the standard shop, priced in Ores.
    # Titan runs do not award Fragments, so that economy-only node is omitted.
    TRAINING = deep_freeze(PokemonSurvivor::SHOP_UPGRADES.reject { |node| node[:id] == :coin_gain }.map do |node|
      { id: node[:id], name: node[:name].dup, desc: node[:desc].dup,
        icon: node[:icon].dup, effect: node[:effect], values: node[:values].dup,
        costs: node[:costs].map { |cost| [(cost / 1500.0).ceil, 1].max } }
    end)
    WEAKER_PASSIVES = [:damage, :speed, :move, :max_hp_small, :magnet_small,
      :expgain_small, :shield_small, :burst_charge].freeze
    # 20 milestones fund all unique rewards (600) and currency purchases (500).
    MILESTONES = deep_freeze((1..20).map do |index|
      { percent: index * 5, crystals: index == 20 ? 340 : 40 }
    end)
    SHOP = deep_freeze({
      fragments: { cost: 2, quantity: 200, limit: 100 },
      candies: { cost: 3, quantity: 20, limit: 100 },
      pokemon: { cost: 300, quantity: 1, limit: 1, damage_percent: 50 },
      equipment: { cost: 200, quantity: 1, limit: 1, damage_percent: 75, requires_pokemon: true },
      prestige: { cost: 100, quantity: 1, limit: 1, damage_percent: 100, requires_pokemon: true }
    })
    ORE_CANDIES = deep_freeze({ id: :ore_candies, cost: 1, quantity: 100, currency: :ores, repeatable: true })

    module_function

    def season(id)
      SEASONS[id.to_i]
    end

    def season_configured?(id)
      data = season(id)
      !!(data && data[:boss] && data[:final] && data[:frames] && data[:background] && data[:projectile])
    end

    def season_shop(id)
      data = season(id)
      return {} unless data
      result = SHOP.reject do |key, _item|
        (key == :equipment && !data[:reward_item]) ||
          (key == :prestige && !data[:reward_cosmetic])
      end
      SEASONS.keys.sort.each do |previous|
        next unless previous < id.to_i
        reward = season(previous)
        [:pokemon, :equipment].each do |kind|
          value = reward[kind == :pokemon ? :reward_pokemon : :reward_item]
          next unless value
          key = "catchup_#{previous}_#{kind}".to_sym
          result[key] = { cost: SHOP[kind][:cost], quantity: 1, limit: 1,
            catchup: true, season: previous, kind: kind, reward: value,
            pokemon: reward[:reward_pokemon] }
        end
      end
      result
    end

    def shop_requirements_met?(item, view)
      if item[:catchup] && item[:kind] == :equipment
        return PokemonSurvivor.hero_unlocked?(item[:pokemon])
      end
      threshold = item[:damage_percent].to_i
      if threshold > 0
        total = view[:total_hp].to_i
        return false if total <= 0
        lost = [[total - view[:hp].to_i, 0].max, total].min
        return false if lost * 100 < total * threshold
      end
      return false if item[:requires_pokemon] && view[:purchases][:pokemon].to_i == 0
      true
    end

    def boss_asset(season_id, final, animation = :walk)
      data = season(season_id)
      return nil unless season_configured?(season_id) && [:walk, :shoot].include?(animation)
      species = data[final ? :final : :boss]
      suffix = animation == :shoot ? "_Shoot" : ""
      { path: "#{BOSS_DIRECTORY}/#{species}#{suffix}",
        columns: data[:frames][species][animation], rows: 8 }
    end

    def ores(seconds, outcome)
      return 0 unless [:lost, :won].include?(outcome)
      seconds = [seconds.to_i, 0].max
      minutes = [[seconds / 60 - 5, 0].max, 10].min
      minutes + (outcome == :lost && seconds >= CLONE_TIME ? 1 : 0)
    end

    def shield_hp(total_hp, remaining_seals)
      remaining_seals.to_i > 0 ? [[(total_hp.to_i + 99) / 100, 0].max, 250_000].min : 0
    end

    def training_name(id)
      node = TRAINING.find { |entry| entry[:id] == id }
      node ? _INTL(node[:name]) : ""
    end

    def training_complete?(ranks)
      !TRAINING.empty? && TRAINING.all? { |entry| ranks[entry[:id]].to_i >= entry[:costs].length }
    end

    def training_effect(ranks, effect)
      TRAINING.select { |node| node[:effect] == effect }.sum do |node|
        rank = [[ranks[node[:id]].to_i, 0].max, node[:values].length].min
        rank > 0 ? node[:values][rank - 1] : 0
      end
    end

    def training_links
      return @training_links if @training_links
      catalog = TRAINING.each_with_object({}) { |node, result| result[node[:id]] = node }
      ids = TRAINING.flat_map { |node| (1..node[:costs].length).map { |rank| "#{node[:id]}_#{rank}".to_sym } }
      parents = Scene_PokemonSurvivor::SHOP_TREE_LINKS.each_with_object({}) { |(a, b), result| result[b] = a }
      unless catalog[:coin_gain]
        parents[:steady_burst_1] = :shop_core
        parents[:starting_damage_1] = :steady_burst_1
        parents[:burst_starter_1] = :steady_burst_1
      end
      @training_links = ids.map do |id|
        parent = parents[id]
        parent = parents[parent] while parent && parent != :shop_core && !ids.include?(parent)
        [parent == :shop_core ? :titan_core : parent, id] if parent
      end.compact.freeze
    end

    def training_node_ranks
      @training_node_ranks ||= TRAINING.each_with_object({}) do |node, result|
        node[:costs].length.times do |index|
          result["#{node[:id]}_#{index + 1}".to_sym] = [node[:id], index + 1]
        end
      end
    end

    def training_purchase_available?(ranks, id, links = nil)
      node = TRAINING.find { |entry| entry[:id] == id }
      level = ranks[id].to_i + 1
      return false unless node && level.between?(1, node[:costs].length)
      target = "#{id}_#{level}".to_sym
      (links || training_links).any? do |a, b|
        neighbor = a == target ? b : (b == target ? a : nil)
        next false unless neighbor
        next true if neighbor == :titan_core
        other = training_node_ranks[neighbor]
        other && ranks[other[0]].to_i >= other[1]
      end
    end

    def translation_markers
      _INTL("Mewtwonite Y")
      _INTL("Mewtwo can Mega Evolve after Burst is fully charged.")
    end

    def estimated_community_hp(damage_per_run, participants = 100, days = 10)
      raise ArgumentError, "positive damage estimate required" unless damage_per_run.is_a?(Integer) && damage_per_run > 0
      raise ArgumentError, "positive participation required" unless participants.is_a?(Integer) && days.is_a?(Integer) && participants > 0 && days > 0
      damage_per_run * participants * days
    end

    # Measures local effective damage, never raw overkill or shield absorption.
    # The server still has to clamp this contribution to its current HP atomically.
    class DamageLedger
      attr_reader :hp, :shield, :damage, :shield_damage

      def initialize(hp, shield = 0)
        raise ArgumentError unless hp.is_a?(Integer) && hp >= 0 && shield.is_a?(Integer) && shield >= 0
        @hp, @shield = hp, shield
        @damage = @shield_damage = 0
      end

      def hit(amount)
        raise ArgumentError unless amount.is_a?(Integer) && amount >= 0
        return 0 if @hp == 0
        absorbed = [amount, @shield].min
        @shield -= absorbed
        @shield_damage += absorbed
        dealt = [amount - absorbed, @hp].min
        @hp -= dealt
        @damage += dealt
        dealt
      end
    end
  end
end
