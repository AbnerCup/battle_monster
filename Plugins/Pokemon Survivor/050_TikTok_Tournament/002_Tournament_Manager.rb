#===============================================================================
# Pokemon Survivor - TikTok Tournament Manager & Adaptive Bracket System
# 1. Minimum 8 participants rule (Auto-fills with Host / Gym Leaders only if < 8).
# 2. Host streamer only enters if there are open spots.
# 3. Dynamic Bracket Tree: 8-man (Quarters -> Semis -> Final) or 16-man.
# 4. 220+ Unique Pokemon: NO DUPLICATES in any tournament!
# 5. Full English Localization & Characteristic Type Colors.
#===============================================================================

module PokemonSurvivor
  TOURNAMENT_PHASE_REGISTRATION = :registration
  TOURNAMENT_PHASE_REVEAL       = :reveal       # 4s reveal for latest entrant
  TOURNAMENT_PHASE_BRACKET      = :bracket      # Visual bracket tree
  TOURNAMENT_PHASE_ROUNDS       = :rounds       # Simultaneous combat in arenas
  TOURNAMENT_PHASE_GRAND_FINAL  = :grand_final  # Center 1v1 Grand Final showdown
  TOURNAMENT_PHASE_PODIUM       = :podium       # Champion victory podium

  def self.format_name(str, max_len = 10)
    return "" if str.nil?
    s = str.to_s.strip
    return s if s.length <= max_len
    "#{s[0...(max_len - 1)]}."
  end

  # Distinctive, high-contrast characteristic colors for each Pokemon Elemental Type
  def self.type_color(type)
    t = type.to_s.upcase.to_sym rescue :NORMAL
    case t
    when :FIRE      then Color.new(255, 130, 40)   # Vivid Flame Orange
    when :WATER     then Color.new(56, 189, 248)   # Bright Water Cyan/Blue
    when :GRASS     then Color.new(74, 222, 128)   # Bright Neon Grass Green
    when :ELECTRIC  then Color.new(253, 224, 71)   # Bright Radiant Electric Yellow
    when :PSYCHIC   then Color.new(244, 114, 182)  # Vivid Psychic Pink
    when :ICE       then Color.new(186, 245, 255)  # Crystal Glacier Ice Cyan
    when :DRAGON    then Color.new(192, 132, 252)  # Bright Royal Dragon Lilac
    when :DARK      then Color.new(203, 213, 225)  # Luminous Platinum
    when :FAIRY     then Color.new(251, 182, 206)  # Fairy Pastel Pink
    when :NORMAL    then Color.new(241, 245, 249)  # Clean Bright Pure Ivory
    when :FIGHTING  then Color.new(255, 95, 95)    # Bright Scarlet Fighting Red
    when :FLYING    then Color.new(196, 181, 253)  # Bright Sky Lavender
    when :POISON    then Color.new(216, 70, 239)   # Bright Radiant Poison Magenta
    when :GROUND    then Color.new(251, 191, 36)   # Bright Sun Gold Ground
    when :ROCK      then Color.new(245, 158, 11)   # Bright Amber Rock
    when :BUG       then Color.new(163, 230, 53)   # Vivid Lime Bug Green
    when :GHOST     then Color.new(167, 139, 250)  # Bright Glowing Ghost Lavender
    when :STEEL     then Color.new(215, 228, 240)  # Gleaming Radiant Steel
    else                 Color.new(241, 245, 249)  # Default Bright
    end
  end

  TIER1_SPECIES = [
    :PICHU, :PIKACHU, :MACHOP, :BELLSPROUT, :STARLY, :APPLIN, :SANDILE, :MAREEP,
    :SPINARAK, :MAGIKARP, :ZUBAT, :CUBONE, :ABRA, :BAGON, :ARON, :BELDUM,
    :CARVANHA, :DRATINI, :DREEPY, :FEEBAS, :FROAKIE, :GIBLE, :LARVITAR, :RIOLU,
    :ROWLET, :SCORBUNNY, :SNORLAX, :SPRIGATITO, :SQUIRTLE, :TREECKO, :WOOPER,
    :CHIKORITA, :CYNDAQUIL, :TOTODILE, :TORCHIC, :MUDKIP, :CHIMCHAR, :PIPLUP,
    :TURTWIG, :FENNEKIN, :CHESPIN, :FUECOCO, :QUILAVA, :IVYSAUR, :CHARMELEON
  ].freeze

  TIER2_SPECIES = [
    :CHARMANDER, :BULBASAUR, :EEVEE, :LUCARIO, :GENGAR, :ALAKAZAM, :AMPHAROS,
    :BLASTOISE, :VENUSAUR, :CROBAT, :DRAGONAIR, :FLYGON, :GARDEVOIR, :GRENINJA,
    :HAWLUCHA, :HERACROSS, :INFERNAPE, :JOLTEON, :VAPOREON, :FLAREON, :ESPEON,
    :UMBREON, :LEAFEON, :GLACEON, :SYLVEON, :LUXRAY, :MILOTIC, :MIMIKYU,
    :RAICHU, :SCEPTILE, :SWAMPERT, :TYPHLOSION, :ZOROARK, :ARMAROUGE, :CERULEDGE,
    :AGGRON, :CHANDELURE, :AEGISLASH, :CORVIKNIGHT, :EXCADRILL, :GALLADE
  ].freeze

  TIER3_SPECIES = [
    :MEWTWO, :CHARIZARD, :GARCHOMP, :DRAGONITE, :SALAMENCE, :METAGROSS, :TYRANITAR,
    :HYDREIGON, :DRAGAPULT, :BAXCALIBUR, :KINGAMBIT, :VOLCARONA, :GHOLDENGO,
    :TINKATON, :CINDERACE, :MEOWSCARADA, :SKELEDIRGE, :DECIDUEYE, :KOMMOO,
    :ENTEI, :RAIKOU, :SUICUNE, :CELEBI, :VICTINI, :DEOXYS, :MEW, :URSHIFU
  ].freeze

  CHAMPION_SPECIES = [
    :MEWTWO, :CHARIZARD, :GARCHOMP, :LUCARIO, :DRAGONITE, :TYRANITAR, :SALAMENCE,
    :METAGROSS, :GENGAR, :BLASTOISE, :GRENINJA
  ].freeze

  GYM_LEADERS = [
    { name: "Gym.Brock", species: :MACHOP, type: :FIGHTING, hp: 150, atk: 18 },
    { name: "Gym.Misty", species: :SQUIRTLE, type: :WATER, hp: 155, atk: 18 },
    { name: "Gym.Surge", species: :PIKACHU, type: :ELECTRIC, hp: 150, atk: 20 },
    { name: "Gym.Erika", species: :BELLSPROUT, type: :GRASS, hp: 150, atk: 17 },
    { name: "Gym.Sabrina", species: :GENGAR, type: :GHOST, hp: 165, atk: 21 },
    { name: "Gym.Blaine", species: :CHARMANDER, type: :FIRE, hp: 160, atk: 20 },
    { name: "Gym.Gio", species: :SANDILE, type: :GROUND, hp: 165, atk: 20 },
    { name: "Elite.Lance", species: :DRAGONITE, type: :DRAGON, hp: 190, atk: 23 },
    { name: "Champ.Cynthia", species: :GARCHOMP, type: :DRAGON, hp: 195, atk: 24 },
    { name: "Rival.Blue", species: :EEVEE, type: :NORMAL, hp: 155, atk: 18 }
  ].freeze

  class TournamentManager
    attr_accessor :phase, :players, :matches, :round_queue, :winners
    attr_accessor :countdown, :reveal_timer, :bracket_timer, :current_round
    attr_accessor :champion_winner, :last_registered_index, :used_species
    attr_accessor :bracket_matches, :bracket_size # 8 or 16

    def initialize
      reset!
    end

    def reset!
      @phase = TOURNAMENT_PHASE_REGISTRATION
      @players = [] # Open to viewers first!
      @matches = [nil, nil, nil, nil, nil, nil]
      @round_queue = []
      @winners = []
      @countdown = 35
      @reveal_timer = 4.0
      @bracket_timer = 4.5
      @current_round = 0
      @champion_winner = nil
      @last_registered_index = -1
      @used_species = []
      @bracket_size = 16
      init_bracket_structure!(16)
    end

    def init_bracket_structure!(size = 16)
      @bracket_size = size
      if size == 8
        # Round 0: Quarterfinals (4 matches, 0..3)
        r0 = (0...4).map do |i|
          { id: "R0_M#{i}", round: 0, index: i, p1: nil, p2: nil, winner: nil, loser: nil, next_m: i / 2, next_slot: i % 2 }
        end
        # Round 1: Semifinals (2 matches, 0..1)
        r1 = (0...2).map do |i|
          { id: "R1_M#{i}", round: 1, index: i, p1: nil, p2: nil, winner: nil, loser: nil, next_m: 0, next_slot: i }
        end
        # Round 2: Grand Final (1 match)
        r2 = [
          { id: "R2_M0", round: 2, index: 0, p1: nil, p2: nil, winner: nil, loser: nil, next_m: nil, next_slot: nil }
        ]
        @bracket_matches = [r0, r1, r2]
      else
        # Round 0: Round of 16 (8 matches, 0..7)
        r0 = (0...8).map do |i|
          { id: "R0_M#{i}", round: 0, index: i, p1: nil, p2: nil, winner: nil, loser: nil, next_m: i / 2, next_slot: i % 2 }
        end
        # Round 1: Quarterfinals (4 matches, 0..3)
        r1 = (0...4).map do |i|
          { id: "R1_M#{i}", round: 1, index: i, p1: nil, p2: nil, winner: nil, loser: nil, next_m: i / 2, next_slot: i % 2 }
        end
        # Round 2: Semifinals (2 matches, 0..1)
        r2 = (0...2).map do |i|
          { id: "R2_M#{i}", round: 2, index: i, p1: nil, p2: nil, winner: nil, loser: nil, next_m: 0, next_slot: i }
        end
        # Round 3: Grand Final (1 match)
        r3 = [
          { id: "R3_M0", round: 3, index: 0, p1: nil, p2: nil, winner: nil, loser: nil, next_m: nil, next_slot: nil }
        ]
        @bracket_matches = [r0, r1, r2, r3]
      end
    end

    def register_player(user_id, nickname, tier, pfp_path = nil, gift_value = 0, is_host = false)
      return if @players.length >= 16

      existing = @players.find { |p| p[:user_id] == user_id }
      if existing
        if tier > existing[:tier] && !existing[:is_host]
          existing[:tier] = tier
          existing[:gift_value] += gift_value
          # Upgrade pokemon species to higher tier if upgraded to Tier 3
          if tier == 3 && existing[:tier] < 3
            avail = TIER3_SPECIES.reject { |s| @used_species.include?(s) }
            new_sp = avail.sample || :CHARIZARD
            @used_species << new_sp
            existing[:species] = new_sp
            existing[:species_name] = PokemonSurvivor.format_name(new_sp, 10)
            existing[:type] = PokemonSurvivor.species_types(new_sp)&.first || :DRAGON
          end
        end
        return
      end

      clean_nick = PokemonSurvivor.format_name(nickname, 10)

      # PICK UNIQUE POKEMON (NO REPETITIONS EVER)
      pool = case tier
             when 4 then CHAMPION_SPECIES
             when 3 then TIER3_SPECIES
             when 2 then TIER2_SPECIES
             else TIER1_SPECIES
             end

      avail = pool.reject { |s| @used_species.include?(s) }
      if avail.empty?
        avail = (TIER1_SPECIES + TIER2_SPECIES + TIER3_SPECIES).reject { |s| @used_species.include?(s) }
      end
      chosen_species = avail.sample || :PIKACHU
      @used_species << chosen_species

      clean_species = PokemonSurvivor.format_name(chosen_species, 10)
      base_data = PokemonSurvivor.hero_data(chosen_species) || { hp: 120, speed: 2.5, attack: 18 }
      primary_type = PokemonSurvivor.species_types(chosen_species)&.first || :NORMAL

      hp = base_data[:hp] || 120
      atk = 18 + (tier * 3)
      if is_host
        hp = (hp * 1.10).round
        atk = (atk * 1.08).round
      end

      player = {
        user_id: user_id,
        raw_nickname: nickname,
        nickname: clean_nick,
        tier: tier,
        is_host: is_host,
        title: is_host ? "League Champion" : "Challenger",
        species: chosen_species,
        species_name: clean_species,
        type: primary_type,
        hp: hp,
        max_hp: hp,
        attack: atk,
        pfp_path: pfp_path,
        gift_value: gift_value,
        eliminated: false
      }

      @players << player
      @last_registered_index = @players.length - 1

      if @players.length >= 16
        trigger_reveal_countdown!
      end
    end

    def trigger_reveal_countdown!
      return if @phase != TOURNAMENT_PHASE_REGISTRATION
      @phase = TOURNAMENT_PHASE_REVEAL
      @reveal_timer = 4.0
    end

    def start_bracket!
      # RULE: Minimum 8 slots. Fill with Streamer / Gym Leaders only if < 8 (or to complete 16)
      target_slots = (@players.length <= 8) ? 8 : 16

      missing = target_slots - @players.length
      if missing > 0
        # Streamer enters ONLY if there are open spots
        host_p = @players.find { |p| p[:is_host] }
        if !host_p && missing > 0
          register_player("host_streamer", "CampeonStreamer", 4, nil, 0, true)
          missing = target_slots - @players.length
        end

        # Fill remaining missing spots with Gym Leaders (WITH STRICTLY UNIQUE POKEMON)
        if missing > 0
          GYM_LEADERS.take(missing).each_with_index do |ldr, idx|
            clean_name = PokemonSurvivor.format_name(ldr[:name], 10)

            sp = ldr[:species]
            if @used_species.include?(sp)
              avail = (TIER2_SPECIES + TIER1_SPECIES).reject { |s| @used_species.include?(s) }
              sp = avail.sample || sp
            end
            @used_species << sp

            clean_sp = PokemonSurvivor.format_name(sp, 10)
            @players << {
              user_id: "bot_leader_#{idx}",
              raw_nickname: ldr[:name],
              nickname: clean_name,
              tier: 2,
              is_host: false,
              title: "Gym Leader",
              species: sp,
              species_name: clean_sp,
              type: ldr[:type],
              hp: ldr[:hp],
              max_hp: ldr[:hp],
              attack: ldr[:atk],
              pfp_path: nil,
              gift_value: 0,
              eliminated: false
            }
          end
          @last_registered_index = @players.length - 1
        end
      end

      # Set up bracket structure for 8 or 16 players
      init_bracket_structure!(target_slots)

      # Seed host at position 0 if present, challengers shuffled
      host_p = @players.find { |p| p[:is_host] }
      challengers = @players.reject { |p| p[:is_host] }.shuffle
      final_roster = host_p ? [host_p] + challengers : challengers

      # Fill initial round matches
      match_count = target_slots / 2
      (0...match_count).each do |m_idx|
        p1 = final_roster[m_idx * 2]
        p2 = final_roster[m_idx * 2 + 1]
        m = @bracket_matches[0][m_idx]
        m[:p1] = p1
        m[:p2] = p2
      end

      @round_queue = @bracket_matches[0].dup
      @current_round = 0
      @winners = []
      @bracket_timer = 4.5
      @phase = TOURNAMENT_PHASE_BRACKET
    end

    def record_match_result!(match_obj, winner, loser)
      match_obj[:winner] = winner
      match_obj[:loser] = loser
      loser[:eliminated] = true

      final_round = (@bracket_size == 8) ? 2 : 3
      if match_obj[:next_m] && match_obj[:round] < final_round
        next_match = @bracket_matches[match_obj[:round] + 1][match_obj[:next_m]]
        if match_obj[:next_slot] == 0
          next_match[:p1] = winner
        else
          next_match[:p2] = winner
        end
      end
    end
  end
end
