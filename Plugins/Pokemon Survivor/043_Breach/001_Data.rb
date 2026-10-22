#===============================================================================
# Breach: season-local progression. No shop currency is spent during a run.
#===============================================================================
module PokemonSurvivor
  BREACH_SLOT_KEY = "BREACH_SEASON"
  BREACH_RULESET = 2
  BREACH_THREAT_SECONDS_PER_POINT = 5.0
  BREACH_ROOM_SHARD_SECONDS = 120.0
  BREACH_MODULES = [
    { id: :power, name: "Power Module", desc: "+8% damage per rank.", ivar: :@damage_mult, factor: 1.08 },
    { id: :tempo, name: "Tempo Module", desc: "Attacks recharge 6% faster per rank.", ivar: :@cooldown_mult, factor: 0.94 },
    { id: :guard, name: "Guard Module", desc: "Take 6% less contact damage per rank.", ivar: :@shield_mult, factor: 0.94 },
    { id: :stride, name: "Stride Module", desc: "+6% movement speed per rank.", speed: 1.06 },
    { id: :magnet, name: "Magnet Module", desc: "+15% pickup range per rank.", ivar: :@pickup_mult, factor: 1.15 },
    { id: :burst, name: "Burst Module", desc: "Burst charges 8% faster per rank.", ivar: :@burst_charge_mult, factor: 1.08 },
    { id: :reach, name: "Ward Module", desc: "Take 6% less projectile damage per rank.", ivar: :@enemy_projectile_shield_mult, factor: 0.94 },
    { id: :recovery, name: "Recovery Module", desc: "Restore 2% HP after each room per rank.", heal: 0.02 },
    { id: :dash, name: "Dash Module", desc: "Dash recharges 5% faster per rank. Minimum: 3s." },
    { id: :salvage, name: "Salvage Module", desc: "+8% Shards from enemies per rank." },
    { id: :precision, name: "Precision Module", desc: "+10% damage to bosses, elites and Seals per rank." },
    { id: :momentum, name: "Momentum Module", desc: "+10% damage per rank for 3s after a Dash." },
    { id: :barrier, name: "Barrier Module", desc: "Start each room with a shield worth 5% max HP per rank." },
    { id: :execution, name: "Execution Module", desc: "+8% damage per rank against enemies below 25% HP." },
    { id: :companion, name: "Companion Module", desc: "+10% companion damage and max HP per rank. No healing." },
    { id: :control, name: "Control Module", desc: "Inflicted status effects last 10% longer per rank.", ivar: :@status_duration_mult, factor: 1.10 },
    { id: :last_stand, name: "Last Stand Module", desc: "Below 30% HP, take 5% less damage per rank." },
    { id: :reserve, name: "Reserve Module", desc: "Once per room, recover 5% Burst charge per rank after it ends." }
  ].freeze
  BREACH_ROUTES = [
    { id: :training, name: "Training Grounds", desc: "More Shards. Survive the pressure.", objective: :pressure, difficulty: :easy },
    { id: :skills, name: "Archives", desc: "Earn a skill voucher. Hold the zone.", objective: :hold_zone, difficulty: :hard },
    { id: :modules, name: "Workshop", desc: "Earn a module. Break the seal.", objective: :break_seal, difficulty: :hard },
    { id: :healing, name: "Sanctuary", desc: "Hold the zone. Restore 30% HP, heal companions and gain a 10% HP shield for the next room.", objective: :hold_zone, difficulty: :easy },
    { id: :treasure, name: "Vault", desc: "More run loot. Defeat the elite pair.", objective: :elite_pair, difficulty: :unfair },
    { id: :boss, name: "Hunt", desc: "More loot and a module. Defeat the boss.", objective: :boss_ambush, difficulty: :unfair },
    { id: :skirmish, name: "Proving Grounds", desc: "Defeat enemies in the zone. Gain 3 extra levels.", objective: :zone_kills, difficulty: :easy },
    { id: :observatory, name: "Observatory", desc: "Survive the pressure. Remove up to 20 time-based Threat points.", objective: :pressure, difficulty: :hard },
    { id: :foundry, name: "Foundry", desc: "Break the seals on Unfair difficulty. Earn two modules.", objective: :break_seal, difficulty: :unfair },
    { id: :trial, name: "Duel Grounds", desc: "Defeat the elite pair. Earn two skill vouchers.", objective: :elite_pair, difficulty: :hard }
  ].freeze
  BREACH_DIFFICULTIES = {
    easy: { name: "Easy", threat: 10, time_threat_mult: 1.0, candies: 4, fragments: 36, shards: 40, hp_mult: 1.0, damage_mult: 1.0 },
    hard: { name: "Hard", threat: 25, time_threat_mult: 2.5, candies: 7, fragments: 63, shards: 70, hp_mult: 1.2, damage_mult: 1.1 },
    unfair: { name: "Unfair", threat: 50, time_threat_mult: 5.0, candies: 12, fragments: 108, shards: 120, hp_mult: 1.4, damage_mult: 1.2 }
  }.freeze

  module_function

  def breach_route_weights(rooms)
    progress = [[(rooms.to_i - 3) / 27.0, 0.0].max, 1.0].min
    { easy: 40.0 - 35.0 * progress, hard: 40.0 - 15.0 * progress,
      unfair: 20.0 + 50.0 * progress }
  end

  def breach_season_style(season_id)
    # A small rotating rule changes the route economy without changing rewards.
    [:balanced, :training, :modules][(season_id.to_i - 1) % 3]
  end

  def breach_score(rooms, threat)
    rooms = [rooms.to_i, 0].max
    # One room and ten earned Threat points have the same score weight.
    rooms * 100_000 + [threat.to_i, 0].max * 10_000
  end

  def breach_loot(rooms, hard_rooms = 0, unfair_rooms = 0, extracted = false)
    rooms = [rooms.to_i, 0].max
    unfair = [[unfair_rooms.to_i, 0].max, rooms].min
    hard = [[hard_rooms.to_i, 0].max, rooms - unfair].min
    easy = rooms - hard - unfair
    divisor = extracted ? 1 : 4
    { candies: (easy * 4 + hard * 7 + unfair * 12) / divisor,
      fragments: (easy * 36 + hard * 63 + unfair * 108) / divisor }
  end

  def breach_earned_threat(rooms, hard_rooms, unfair_rooms)
    rooms.to_i * 10 + hard_rooms.to_i * 15 + unfair_rooms.to_i * 40
  end

  def breach_reward_text(quest)
    quest[:candies].to_i > 0 ? _INTL("{1} Candies", quest[:candies]) : _INTL("{1} Fragments", quest[:fragments])
  end

  def breach_season_quests
    # Keep deployed IDs so claimed rewards cannot be claimed again after updating.
    legacy = [
      ['rooms_3','First Steps',:rooms,3], ['runs_3','Try Again',:runs,3],
      ['kills_500','Crowd Control',:kills,500], ['extract_1','Safe Return',:extractions,1],
      ['fusion_3','A Better Build',:fusions,3], ['rooms_15','Finding a Way',:rooms,15],
      ['levels_100','Field Training',:levels,100], ['pokemon_3','Different Paths',:pokemon,3],
      ['kills_3000','Breach Patrol',:kills,3000], ['extract_5','Return Specialist',:extractions,5],
      ['rooms_40','Season Explorer',:rooms,40], ['fusion_12','Module Crafter',:fusions,12],
      ['pokemon_5','Versatile Team',:pokemon,5], ['rooms_75','Beyond the Breach',:rooms,75]
    ]
    tracks = [
      [:rooms, 'Season Explorer', [90,110,135,160,190,220,260,300,340,380,420,460,500,550,600]],
      [:kills, 'Breach Patrol', [4000,5500,7000,9000,11500,14000,17000,20000,24000,28000,33000,39000,45000,52000,60000]],
      [:extractions, 'Return Specialist', [6,7,8,10,12,14,16,18,20,23,26,29,32,36,40]],
      [:fusions, 'Module Crafter', [15,18,22,26,30,35,40,46,52,60,68,76,84,92,100]],
      [:levels, 'Field Training', [150,200,275,350,450,575,700,850,1000,1200,1450,1700,1950,2200,2500]],
      [:pokemon, 'Versatile Team', (6..20).to_a],
      [:threat, 'Rising Stakes', [100,200,350,550,800,1100,1500,2000,2700,3500,4500,6000,8000,11000,15000]]
    ]
    15.times do |rank|
      tracks.each do |metric, name, targets|
        legacy << ["v2_#{metric}_#{targets[rank]}", name, metric, targets[rank]]
      end
    end
    legacy << ['v2_unfair_30', 'Against the Odds', :unfair_rooms, 30]
    legacy.each_with_index.map do |(id, name, metric, target), index|
      amount = 15 + (index / 14) * 5
      { id: id, name: name, metric: metric, target: target,
        candies: index.even? ? amount * 12 : 0, fragments: index.odd? ? amount * 40 : 0 }
    end
  end

  def breach_progress(season_id)
    root = survivor_progress
    root[:breach_seasons] = {} unless root[:breach_seasons].is_a?(Hash)
    id = season_id.to_i
    entry = root[:breach_seasons][id] ||= {}
    entry[:stats] ||= {}
    entry[:claimed] ||= {}
    entry[:validated] ||= {}
    entry[:pokemon] ||= []
    entry
  end

  def breach_quest_value(season, quest)
    entry = breach_progress(season[:id])
    quest[:metric] == :pokemon ? entry[:pokemon].length : entry[:stats][quest[:metric]].to_i
  end

  def breach_claim_quest(season, quest)
    entry = breach_progress(season[:id])
    return false if entry[:claimed][quest[:id]]
    return false unless entry[:validated][quest[:id]]
    return false if breach_quest_value(season, quest) < quest[:target]
    entry[:claimed][quest[:id]] = true
    add_candy_currency(quest[:candies])
    add_shop_currency(quest[:fragments])
    true
  end

  def breach_validate_quest(season, quest)
    entry = breach_progress(season[:id])
    return false if entry[:claimed][quest[:id]] || entry[:validated][quest[:id]]
    return false if breach_quest_value(season, quest) < quest[:target]
    entry[:validated][quest[:id]] = true
    true
  end
end
