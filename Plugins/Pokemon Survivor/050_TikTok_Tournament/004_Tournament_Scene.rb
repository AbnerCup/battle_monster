#===============================================================================
# Pokemon Survivor - Scene_TikTokTournament
# Full Tournament Bracket Tree + 6 Simultaneous Arenas
# 100% Consistent Progression, Adaptive Geometry, Clean Floor Platforms
# Full English Localization & Characteristic Type Colors
#===============================================================================

class Scene_TikTokTournament
  include PokemonSurvivor

  def initialize
    @manager = PokemonSurvivor::TournamentManager.new
    @sprites = {}
    @active_matches = [nil, nil, nil, nil, nil, nil] # 6 simultaneous arenas
    @arena_results = [nil, nil, nil, nil, nil, nil] # Stores last winner in each arena
    @berries = []
    @projectiles = []
    @floating_texts = []
    @sparks = []
    @anim_tick = 0
    @podium_timer = 0
  end

  def main
    Graphics.transition(0)
    pbStartScene
    pbMain
    pbEndScene
    Graphics.freeze
    $scene = nil
  end

  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites["screen"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)

    # Enforce crisp HD TrueType vector fonts globally (prevents pixel font degradation on mobile)
    Font.default_name = ["Arial", "Segoe UI"] rescue nil
    Font.default_size = 14 rescue nil

    # Start background TCP network client
    PokemonSurvivor.start_tiktok_client('127.0.0.1', 8081)

    pbBGMPlay("Survivor/Route 201") rescue nil
  end

  def pbMain
    loop do
      Graphics.update
      Input.update
      @anim_tick = (@anim_tick + 1) % 240

      # 1. Process TikTok Events from Backend
      process_incoming_events

      # 2. Update Scene State
      case @manager.phase
      when :registration, :reveal
        update_registration
        draw_registration
      when :bracket
        update_bracket
        draw_bracket
      when :rounds, :grand_final
        update_combat
        draw_combat
      when :podium
        update_podium
        draw_podium
      end

      # Allow ESC soft reset
      if Input.trigger?(Input::BACK)
        break
      end
    end
  end

  def pbEndScene
    @sprites.each_value { |s| s.dispose rescue nil }
    @sprites.clear
    @viewport.dispose rescue nil
  end

  # ===========================================================================
  # EVENT PROCESSING FROM TIKTOK BACKEND
  # ===========================================================================
  def process_incoming_events
    events = PokemonSurvivor.poll_tiktok_events
    events.each do |data|
      event_type = data["event"]
      case event_type
      when "spawn_player"
        @manager.register_player(
          data["user_id"],
          data["user"],
          data["tier"].to_i,
          data["game_pfp"] || data["pfp_path"],
          data["gift_value"].to_i,
          data["is_host"] == true
        )
      when "registration_tick"
        @manager.countdown = data["time_left"].to_i
      when "start_tournament"
        if @manager.phase == :registration
          @manager.start_bracket!
        end
      when "comment", "chat_cheer"
        cmt = data["comment"] || (data["target"] ? "##{data['target']}" : "")
        handle_chat_comment(data["user"], cmt)
      when "like", "like_drop"
        count = (data["like_count"] || data["count"] || 1).to_i
        handle_taps(count)
      when "gift", "gift_airstrike", "gift_dynamax"
        handle_gift_event(data["user"], data["gift_name"], (data["gift_value"] || data["power"] || 1).to_i, data["target_player"])
      when "tournament_reset"
        @manager.reset!
        @active_matches = [nil, nil, nil, nil, nil, nil]
        @arena_results = [nil, nil, nil, nil, nil, nil]
        @berries.clear
        @projectiles.clear
        @floating_texts.clear
      end
    end
  end

  def handle_chat_comment(user, text)
    c = text.to_s.strip
    boost_side = nil
    boost_side = 1 if c.include?("#1")
    boost_side = -1 if c.include?("#2")

    if boost_side
      @active_matches.compact.each do |m|
        target = (boost_side == 1) ? m[:e1] : m[:e2]
        target[:ult] = [(target[:ult] || 0) + 12, 100].min
        @floating_texts << {
          text: "#{user}: #{(boost_side == 1) ? '#1' : '#2'}",
          x: target[:x],
          y: target[:y] - 22,
          color: Color.new(56, 189, 248),
          life: 30
        }
      end
    end
  end

  def handle_taps(count)
    drop_count = [count / 5, 3].min
    drop_count = 1 if drop_count < 1
    (0...6).each do |a|
      m = @active_matches[a]
      next unless m
      ax, ay, aw, ah, cx, cy = arena_bounds(a)
      drop_count.times do
        bx = cx + rand(-45..45)
        by = ay + 15
        target_y = cy + rand(-10..15)
        @berries << { x: bx, y: by, target_y: target_y, arena: a, life: 180 }
      end
    end
  end

  def handle_gift_event(user, gift_name, value, target_name)
    target_match = @active_matches.compact.first
    return unless target_match

    is_gf = (@manager.phase == :grand_final)

    # Identify target fighter (by target_name or sender or default to e1)
    target_entity = nil
    if target_name
      target_entity = (target_match[:p1][:nickname].downcase.include?(target_name.downcase)) ? target_match[:e1] : target_match[:e2]
    end
    target_entity ||= target_match[:e1]
    rival_entity = (target_entity == target_match[:e1]) ? target_match[:e2] : target_match[:e1]

    if value >= 500
      # VIP GIFT (Lion, Universe, Whale): FULMINANT KO / INSTANT WIN!
      rival_entity[:hp] = 0
      float_y1 = target_entity[:y] - (is_gf ? 52 : 42)
      float_y2 = rival_entity[:y] - (is_gf ? 46 : 25)
      @floating_texts << {
        text: "VIP WIN: #{user}!",
        x: target_entity[:x],
        y: float_y1,
        color: Color.new(255, 215, 0),
        life: 70
      }
      @floating_texts << {
        text: "INSTANT K.O.!",
        x: rival_entity[:x],
        y: float_y2,
        color: Color.new(239, 68, 68),
        life: 70
      }
      pbSEPlay("Battle damage super") rescue nil
      pbSEPlay("Battle fainted") rescue nil
    elsif value >= 100
      # MEDIUM GIFT (Donuts, Caps, Hearts): +100 HP HEAL + DYNAMAX!
      target_entity[:dynamax] = 260
      target_entity[:hp] = [target_entity[:hp] + 100, target_entity[:max_hp] * 2].min
      float_y = target_entity[:y] - (is_gf ? 52 : 42)
      @floating_texts << {
        text: "DYNAMAX (+100 HP): #{user}!",
        x: target_entity[:x],
        y: float_y,
        color: Color.new(236, 72, 153),
        life: 55
      }
      pbSEPlay("Battle dynamax") rescue nil
    else
      # SMALL GIFT (Rose, GG, etc.): +25 HP or +50 HP HEAL
      heal = value >= 30 ? 50 : 25
      target_entity[:hp] = [target_entity[:hp] + heal, target_entity[:max_hp]].min
      float_y = target_entity[:y] - (is_gf ? 46 : 25)
      @floating_texts << {
        text: "+#{heal} HP: #{user}",
        x: target_entity[:x],
        y: float_y,
        color: Color.new(34, 197, 94),
        life: 45
      }
      pbSEPlay("Item recovery") rescue nil
    end
  end

  # ===========================================================================
  # GEOMETRY & BOUNDS: 6 SIMULTANEOUS ARENAS (3 Columns x 2 Rows)
  # ===========================================================================
  def arena_bounds(index)
    col = index % 3
    row = index / 3
    w = Graphics.width / 3.0
    h = (Graphics.height - 24) / 2.0
    ax = (col * w).round
    ay = (row * h).round
    cx = (ax + w / 2.0).round
    cy = (ay + h * 0.62).round
    [ax, ay, w.round, h.round, cx, cy]
  end

  # ===========================================================================
  # REGISTRATION & REVEAL COUNTDOWN
  # ===========================================================================
  def update_registration
    if @manager.phase == :reveal
      @manager.reveal_timer -= (1.0 / 60.0)
      if @manager.reveal_timer <= 0 || Input.trigger?(Input::C)
        @manager.start_bracket!
      end
    else
      @reg_frame_timer = (@reg_frame_timer || 0) + 1
      if @reg_frame_timer >= 60
        @reg_frame_timer = 0
        @manager.countdown -= 1 if @manager.countdown > 0
        if @manager.countdown <= 0
          @manager.trigger_reveal_countdown!
        end
      end

      if Input.trigger?(Input::C)
        @manager.trigger_reveal_countdown!
      end
    end
  end

  # ===========================================================================
  # BRACKET TREE DISPLAY & PROGRESSION
  # ===========================================================================
  def update_bracket
    @manager.bracket_timer -= (1.0 / 60.0)
    if @manager.bracket_timer <= 0 || Input.trigger?(Input::C)
      final_round = (@manager.bracket_size == 8) ? 2 : 3
      if @manager.current_round == final_round
        # Grand Final showdown!
        @manager.phase = :grand_final
        m_obj = @manager.bracket_matches[final_round][0]
        spawn_match_in_arena(1, m_obj)
      else
        @manager.phase = :rounds
        spawn_round_matches!
      end
    end
  end

  def spawn_round_matches!
    @arena_results = [nil, nil, nil, nil, nil, nil]
    (0...6).each do |a|
      next if @manager.phase == :grand_final && a != 1
      if @active_matches[a].nil? && !@manager.round_queue.empty?
        m_obj = @manager.round_queue.shift
        spawn_match_in_arena(a, m_obj)
      end
    end
  end

  def spawn_match_in_arena(arena_idx, match_obj)
    ax, ay, aw, ah, cx, cy = arena_bounds(arena_idx)
    p1_data = match_obj[:p1]
    p2_data = match_obj[:p2]

    is_gf = (@manager.phase == :grand_final)
    if is_gf
      cx = Graphics.width / 2
      cy = 205
      sep = (Graphics.width >= 800) ? 140 : 110
      e1 = p1_data.dup.merge(x: cx - sep, y: cy, facing: 1, side: 1, ult: 0, anim_frame: 0, cooldown: 0.8)
      e2 = p2_data.dup.merge(x: cx + sep, y: cy, facing: -1, side: -1, ult: 0, anim_frame: 0, cooldown: 0.8)
    else
      e1 = p1_data.dup.merge(x: cx - 40, y: cy, facing: 1, side: 1, ult: 0, anim_frame: 0, cooldown: 0.8)
      e2 = p2_data.dup.merge(x: cx + 40, y: cy, facing: -1, side: -1, ult: 0, anim_frame: 0, cooldown: 0.8)
    end

    @active_matches[arena_idx] = {
      match_obj: match_obj,
      p1: p1_data,
      p2: p2_data,
      e1: e1,
      e2: e2,
      timer: 65.0
    }
  end

  def update_combat
    dt = 1.0 / 60.0
    is_gf = (@manager.phase == :grand_final)

    @active_matches.each_with_index do |m, a|
      next unless m
      m[:timer] -= dt

      update_entity_ai(m[:e1], m[:e2], a)
      update_entity_ai(m[:e2], m[:e1], a)

      dead1 = m[:e1][:hp] <= 0
      dead2 = m[:e2][:hp] <= 0
      if dead1 || dead2 || m[:timer] <= 0
        winner = if dead1 && !dead2 then m[:p2]
                 elsif dead2 && !dead1 then m[:p1]
                 else
                   (m[:e1][:hp].to_f / m[:e1][:max_hp] >= m[:e2][:hp].to_f / m[:e2][:max_hp]) ? m[:p1] : m[:p2]
                 end
        loser = (winner == m[:p1]) ? m[:p2] : m[:p1]

        # Record exact match result into bracket tree!
        @manager.record_match_result!(m[:match_obj], winner, loser)

        @arena_results[a] = { winner: winner, loser: loser }
        @active_matches[a] = nil
      end
    end

    # Projectiles
    hit_radius_x = is_gf ? 28 : 18
    hit_radius_y = is_gf ? 28 : 18

    @projectiles.reject! do |pr|
      pr[:x] += pr[:vx]
      pr[:y] += pr[:vy]
      pr[:life] -= 1

      # Grand Final: Smooth glowing comet particle trail behind energy orbs
      if is_gf && (@anim_tick % 2 == 0)
        p_trail_col = PokemonSurvivor.type_color(pr[:type] || :NORMAL)
        @sparks << {
          x: pr[:x] - (pr[:vx] * 0.7),
          y: pr[:y] + rand(-2..2),
          vx: -pr[:vx] * 0.15,
          vy: rand(-0.8..0.8),
          color: p_trail_col,
          size: pr[:is_ult] ? 3 : 2,
          life: 10
        }
      end

      target = pr[:target]
      hit_x = (pr[:x] - target[:x]).abs < hit_radius_x
      hit_y = (pr[:y] - (target[:y] - 10)).abs < hit_radius_y
      hit = hit_x && hit_y
      if hit
        # Controlled type multiplier: slight advantage (1.25x max, 0.80x min floor)
        raw_mult = PokemonSurvivor.type_multiplier(pr[:type], [target[:type]]) rescue 1.0
        clamped_mult = if raw_mult > 1.0
                         1.25
                       elsif raw_mult < 1.0
                         0.80
                       else
                         1.0
                       end

        final_dmg = (pr[:damage] * clamped_mult).round
        final_dmg = (final_dmg * 0.5).round if target[:dynamax].to_i > 0
        final_dmg = [final_dmg, 8].max # Ensure attacks always deal visible, meaningful damage

        target[:hp] = [target[:hp] - final_dmg, 0].max

        # Dynamic Ultimate generation on combat engagement
        if pr[:source]
          pr[:source][:ult] = [(pr[:source][:ult] || 0) + 5, 100].min rescue nil
        end
        target[:ult] = [(target[:ult] || 0) + 3, 100].min

        crit = clamped_mult > 1.0
        txt = crit ? "#{final_dmg} CRIT!" : "#{final_dmg}"
        col = crit ? Color.new(251, 191, 36) : (clamped_mult < 1.0 ? Color.new(148, 163, 184) : Color.white)
        float_y = target[:y] - (is_gf ? 38 : 18)
        @floating_texts << { text: txt, x: target[:x], y: float_y, color: col, life: 25 }
        pbSEPlay("Battle damage super") rescue nil if crit

        # Smooth elemental impact sparks
        p_hit_col = PokemonSurvivor.type_color(pr[:type] || :NORMAL)
        spark_count = is_gf ? (pr[:is_ult] ? 10 : 6) : 4
        spark_count.times do
          sp_ang = rand * Math::PI * 2
          sp_spd = rand(1.5..3.8)
          @sparks << {
            x: pr[:x],
            y: pr[:y],
            vx: Math.cos(sp_ang) * sp_spd,
            vy: Math.sin(sp_ang) * sp_spd,
            color: crit ? Color.new(255, 220, 50) : p_hit_col,
            size: is_gf ? 3 : 2,
            life: 14
          }
        end
      end
      hit || pr[:life] <= 0
    end

    # Update Elemental Sparks
    @sparks.reject! do |sp|
      sp[:x] += sp[:vx]
      sp[:y] += sp[:vy]
      sp[:life] -= 1
      sp[:life] <= 0
    end

    # Berries
    @berries.reject! do |b|
      b[:y] += 2.2 if b[:y] < b[:target_y]
      b[:life] -= 1
      collected = false
      @active_matches.compact.each do |m|
        [m[:e1], m[:e2]].each do |e|
          if (e[:x] - b[:x]).abs < (is_gf ? 24 : 16) && (e[:y] - 10 - b[:y]).abs < (is_gf ? 24 : 16)
            e[:hp] = [e[:hp] + 25, e[:max_hp]].min
            float_y = e[:y] - (is_gf ? 38 : 20)
            @floating_texts << { text: "+25 HP", x: e[:x], y: float_y, color: Color.new(34, 197, 94), life: 25 }
            collected = true
          end
        end
      end
      collected || b[:life] <= 0
    end

    @floating_texts.reject! do |ft|
      ft[:y] -= 0.35
      ft[:life] -= 1
      ft[:life] <= 0
    end

    # Feed queued matches into freed-up arenas
    if !@manager.round_queue.empty?
      (0...6).each do |a|
        if @active_matches[a].nil? && !@manager.round_queue.empty?
          m_obj = @manager.round_queue.shift
          spawn_match_in_arena(a, m_obj)
        end
      end
    end

    # Advance round if all matches in round are finished
    if @active_matches.compact.empty? && @manager.round_queue.empty?
      advance_tournament_round!
    end
  end

  def update_entity_ai(e, rival, arena_idx)
    e[:dynamax] = [e[:dynamax].to_i - 1, 0].max if e[:dynamax].to_i > 0
    e[:facing] = rival[:x] >= e[:x] ? 1 : -1
    e[:anim_frame] = (e[:anim_frame] + 0.20) % 4
    e[:last_move_timer] = (e[:last_move_timer] || 0) - 1 if (e[:last_move_timer] || 0) > 0

    is_gf = (@manager.phase == :grand_final)

    dist = (rival[:x] - e[:x]).abs
    # Smooth, agile movement
    speed = e[:is_host] ? 2.4 : 2.2
    speed *= 1.25 if e[:dynamax].to_i > 0

    min_dist = is_gf ? 115 : 46
    max_dist = is_gf ? 175 : 82

    if dist > max_dist
      e[:x] += (rival[:x] > e[:x] ? speed : -speed)
    elsif dist < min_dist
      e[:x] += (rival[:x] > e[:x] ? -speed : speed)
    end

    # Clamp X within arena platform bounds
    if is_gf
      e[:x] = [[e[:x], 70].max, Graphics.width - 70].min
    else
      ax, _, aw, _, _, _ = arena_bounds(arena_idx)
      e[:x] = [[e[:x], ax + 25].max, ax + aw - 25].min
    end

    # Attack Cadence: Smooth 0.52s (host 0.48s) - Fluid and lively!
    e[:cooldown] = (e[:cooldown] || 0.52) - (1.0 / 60.0)
    if e[:cooldown] <= 0
      e[:cooldown] = e[:is_host] ? 0.48 : 0.52
      angle = Math.atan2((rival[:y] - 10) - (e[:y] - 10), rival[:x] - e[:x])
      dmg = e[:attack] || 18
      dmg = (dmg * 1.3).round if e[:dynamax].to_i > 0
      spd_mult = is_gf ? 7.6 : 6.8

      # In Grand Final, record signature move name for on-screen HUD badge
      if is_gf
        move_name = PokemonSurvivor.get_move_name(e[:species], e[:type], false)
        e[:last_move_name] = move_name
        e[:last_move_timer] = 34
        e[:last_move_color] = PokemonSurvivor.type_color(e[:type] || :NORMAL)
        e[:last_move_is_ult] = false
      end

      @projectiles << {
        x: e[:x], y: e[:y] - 10,
        vx: Math.cos(angle) * spd_mult,
        vy: Math.sin(angle) * spd_mult,
        type: e[:type] || :NORMAL,
        damage: dmg,
        target: rival,
        source: e,
        life: 55,
        is_ult: false,
        is_gf: is_gf
      }
    end

    # Ultimate charge: Smooth and active (charges in ~12-14 seconds)
    e[:ult] = (e[:ult] || 0) + (1.0 / 60.0) * 4.2
    if e[:ult] >= 100
      e[:ult] = 0
      txt_y = e[:y] - (is_gf ? 52 : 38)
      ult_name = PokemonSurvivor.get_move_name(e[:species], e[:type], true)

      if is_gf
        e[:last_move_name] = ult_name
        e[:last_move_timer] = 55
        e[:last_move_color] = Color.new(255, 220, 50)
        e[:last_move_is_ult] = true
        @floating_texts << { text: "★ #{ult_name.upcase} ★", x: e[:x], y: txt_y, color: Color.new(255, 215, 0), life: 48 }
      else
        @floating_texts << { text: "ULTIMATE!", x: e[:x], y: txt_y, color: Color.new(245, 158, 11), life: 45 }
      end
      pbSEPlay("Battle ability") rescue nil

      # Multi-projectile ultimate volley
      offsets = is_gf ? [-0.07, 0.0, 0.07] : [-0.08, 0.0, 0.08]
      offsets.each do |offset|
        angle = Math.atan2((rival[:y] - 10) - (e[:y] - 10), rival[:x] - e[:x]) + offset
        u_spd = is_gf ? 8.4 : 7.2
        @projectiles << {
          x: e[:x], y: e[:y] - 10,
          vx: Math.cos(angle) * u_spd,
          vy: Math.sin(angle) * u_spd,
          type: e[:type] || :NORMAL,
          damage: (e[:attack] * 0.90).round,
          target: rival,
          source: e,
          life: 55,
          is_ult: true,
          is_gf: is_gf
        }
      end
    end
  end

  def advance_tournament_round!
    final_round = (@manager.bracket_size == 8) ? 2 : 3
    if @manager.current_round >= final_round
      # Grand Final finished!
      champ = @manager.bracket_matches[final_round][0][:winner]
      @manager.champion_winner = champ
      @manager.phase = :podium
      @podium_timer = 0
      pbMEPlay("Survivor/Victory") rescue nil
    else
      # Move to next round
      @manager.current_round += 1
      next_round_matches = @manager.bracket_matches[@manager.current_round]
      @manager.round_queue = next_round_matches.dup
      @manager.bracket_timer = 4.5
      @manager.phase = :bracket # Show updated bracket tree!
    end
  end

  def update_podium
    @podium_timer = (@podium_timer || 0) + 1
    if @podium_timer >= 60 * 8 || Input.trigger?(Input::C)
      @podium_timer = 0
      @manager.reset!
      PokemonSurvivor.send_tiktok_event({ "event" => "tournament_reset" })
    end
  end

  # ===========================================================================
  # RENDERING: 1. REGISTRATION & REVEAL (English & Unobstructed Card Layout)
  # ===========================================================================
  def draw_registration
    bmp = @sprites["screen"].bitmap
    bmp.clear

    bmp.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(10, 15, 26))

    bmp.font.name = ["Arial", "Segoe UI"]
    bmp.font.size = 20
    bmp.font.bold = true
    pbDrawTextPositions(bmp, [
      ["* CHERNO CUP - TIKTOK LIVE *", Graphics.width / 2, 12, 2, Color.new(255, 215, 0), Color.black, :shadow]
    ])

    bmp.font.size = 13
    if @manager.phase == :reveal
      flash_col = (@anim_tick / 10).even? ? Color.new(255, 220, 50) : Color.new(56, 189, 248)
      pbDrawTextPositions(bmp, [
        ["* FULL LOBBY!! REVEALING CONTENDERS IN #{@manager.reveal_timer.ceil}s... *", Graphics.width / 2, 38, 2, flash_col, Color.black, :shadow]
      ])
      bmp.font.size = 12
      pbDrawTextPositions(bmp, [
        ["Each trainer gets a UNIQUE Fighter without duplicates", Graphics.width / 2, 58, 2, Color.white, Color.black, :shadow]
      ])
    else
      countdown_col = @manager.countdown <= 10 ? Color.new(239, 68, 68) : Color.new(249, 115, 22)
      pbDrawTextPositions(bmp, [
        ["* TOURNAMENT STARTS IN #{@manager.countdown}s * (Auto-fills with Gym Leaders)", Graphics.width / 2, 38, 2, countdown_col, Color.black, :shadow]
      ])
      bmp.font.size = 12
      pbDrawTextPositions(bmp, [
        ["Comment: Tier 1 | Follow: Tier 2 | Gifts: Tier 3 & In-Game Powers", Graphics.width / 2, 58, 2, Color.new(56, 189, 248), Color.black, :shadow]
      ])
    end

    start_x = 18
    start_y = 80
    cell_w = (Graphics.width - 36) / 4
    cell_h = (Graphics.height - 94) / 4

    (0...16).each do |i|
      col = i % 4
      row = i / 4
      cx = start_x + (col * cell_w)
      cy = start_y + (row * cell_h)
      card_w = cell_w - 6
      card_h = cell_h - 6

      p = @manager.players[i]
      if p
        is_host = p[:is_host]
        is_last = (i == @manager.last_registered_index) && (@manager.phase == :reveal)

        border_col = is_last ? Color.new(255, 240, 50) : (is_host ? Color.new(255, 215, 0) : Color.new(56, 189, 248))
        card_bg = is_last ? Color.new(50, 40, 20) : (is_host ? Color.new(35, 28, 15) : Color.new(18, 26, 44))
        border_thickness = is_last ? 3 : 2

        bmp.fill_rect(cx, cy, card_w, card_h, card_bg)
        bmp.fill_rect(cx, cy, card_w, border_thickness, border_col)
        bmp.fill_rect(cx, cy + card_h - border_thickness, card_w, border_thickness, border_col)
        bmp.fill_rect(cx, cy, border_thickness, card_h, border_col)
        bmp.fill_rect(cx + card_w - border_thickness, cy, border_thickness, card_h, border_col)

        # 1. TOP HEADER: @nickname centered across the full card width (No cuts!)
        nick_str = PokemonSurvivor.format_name(p[:nickname], 12)
        spec_str = PokemonSurvivor.format_name(p[:species_name] || p[:species], 10)
        type_sym = p[:type] || :NORMAL
        type_col = PokemonSurvivor.type_color(type_sym)

        bmp.font.size = 11
        bmp.font.bold = true
        if is_host
          name_txt = "[CHAMP] @#{nick_str}"
          name_col = Color.new(255, 220, 60)
        elsif is_last
          name_txt = "@#{nick_str}"
          name_col = Color.new(255, 255, 120)
        else
          name_txt = "@#{nick_str}"
          name_col = Color.white
        end
        pbDrawTextPositions(bmp, [
          [name_txt, cx + (card_w / 2), cy + 4, 2, name_col, Color.new(0, 0, 0, 220), :shadow]
        ])

        # 2. Subtle Divider line under name
        bmp.fill_rect(cx + 4, cy + 18, card_w - 8, 1, is_host ? Color.new(80, 60, 20) : Color.new(30, 42, 65))

        # 3. AVATAR MEDALLION (User TikTok Profile Picture)
        tier_col = case p[:tier]
                   when 4 then Color.new(255, 215, 0)
                   when 3 then Color.new(245, 100, 220)
                   when 2 then Color.new(56, 189, 248)
                   else Color.new(234, 179, 8)
                   end
        PokemonSurvivor.draw_circular_avatar(bmp, p[:pfp_path], cx + 16, cy + 39, 11, tier_col, is_host, p[:nickname])

        # 4. POKEMON PARTNER SPRITE (Standing proudly beside avatar)
        hero_bmp = PokemonSurvivor.get_cached_hero(p[:species])
        if hero_bmp && !hero_bmp.disposed?
          zoom = is_last ? 1.05 : 0.95
          PokemonSurvivor.draw_character_centered(bmp, hero_bmp, cx + 42, cy + 40, PokemonSurvivor::DIR_DOWN, 0, zoom)
        end

        # 5. RIGHT SIDE: Pokemon species name, type in its distinctive color, and Tier
        text_x = cx + 59

        # Row 1: Species Name
        spec_str = PokemonSurvivor.format_name(p[:species_name] || p[:species], 8)
        bmp.font.size = 10
        bmp.font.bold = true
        pbDrawTextPositions(bmp, [
          [spec_str, text_x, cy + 20, 0, Color.white, Color.new(0, 0, 0, 220), :shadow]
        ])

        # Row 2: Characteristic Elemental Type Color
        bmp.font.size = 10
        bmp.font.bold = true
        pbDrawTextPositions(bmp, [
          ["[#{PokemonSurvivor.type_short(type_sym)}]", text_x, cy + 33, 0, type_col, Color.new(0, 0, 0, 220), :shadow]
        ])

        # Row 3: Tier / Entry Tag
        bmp.font.size = 9
        bmp.font.bold = true
        tag_str = is_last ? "[LATEST]" : (is_host ? "CHAMP" : "TIER #{p[:tier]}")
        tag_col = is_last ? Color.new(255, 190, 50) : (is_host ? Color.new(255, 215, 0) : Color.new(148, 163, 184))
        pbDrawTextPositions(bmp, [
          [tag_str, text_x, cy + 46, 0, tag_col, Color.new(0, 0, 0, 220), :shadow]
        ])
      else
        # Open / Available Slot
        bmp.fill_rect(cx, cy, card_w, card_h, Color.new(12, 18, 28))
        bmp.fill_rect(cx, cy, card_w, 1, Color.new(30, 41, 59))
        bmp.fill_rect(cx, cy + card_h - 1, card_w, 1, Color.new(30, 41, 59))
        bmp.fill_rect(cx, cy, 1, card_h, Color.new(30, 41, 59))
        bmp.fill_rect(cx + card_w - 1, cy, 1, card_h, Color.new(30, 41, 59))

        bmp.font.size = 10
        bmp.font.bold = true
        pbDrawTextPositions(bmp, [
          ["Slot #{i + 1} (Open)", cx + (card_w / 2), cy + (card_h / 2) - 6, 2, Color.new(71, 85, 105), Color.black, :none]
        ])
      end
    end
  end

  # ===========================================================================
  # RENDERING: 2. BRACKET TREE (Full English & Characteristic Colors)
  # ===========================================================================
  def draw_bracket
    bmp = @sprites["screen"].bitmap
    bmp.clear

    bmp.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(14, 18, 30))

    # Header
    bmp.font.name = ["Arial", "Segoe UI"]
    bmp.font.size = 20
    bmp.font.bold = true
    round_names = (@manager.bracket_size == 8) ? ["QUARTERFINALS", "SEMIFINALS", "GRAND FINAL"] : ["ROUND OF 16", "QUARTERFINALS", "SEMIFINALS", "GRAND FINAL"]
    r_name = round_names[@manager.current_round] || "TOURNAMENT ROUND"
    pbDrawTextPositions(bmp, [
      ["* CHERNO CUP - BRACKET TREE *", Graphics.width / 2, 8, 2, Color.new(255, 215, 0), Color.new(0, 0, 0, 220), :shadow],
      ["Round: #{r_name} | Matches starting in #{@manager.bracket_timer.ceil}s...", Graphics.width / 2, 28, 2, Color.new(56, 189, 248), Color.new(0, 0, 0, 220), :shadow]
    ])

    w = Graphics.width
    cx = w / 2

    neon_cyan = Color.new(56, 189, 248)
    neon_gold = Color.new(255, 215, 0)

    if @manager.bracket_size == 8
      # =========================================================================
      # 8-PLAYER WIDESCREEN HD BRACKET (Left -> Right: Quarters -> Semis -> Final)
      # Ultra-clear 152px cards with 14-16pt bold Arial vector font for mobile!
      # =========================================================================
      slot_w = 152
      slot_h = 36

      x_qf = 8
      x_sf = 178
      x_gf = 348

      # Column Badges at Top
      bmp.font.size = 11
      bmp.font.bold = true
      pbDrawTextPositions(bmp, [
        ["[ QUARTERFINALS ]", x_qf + slot_w / 2, 45, 2, neon_cyan, Color.black, :shadow],
        ["[ SEMIFINALS ]",    x_sf + slot_w / 2, 45, 2, neon_gold, Color.black, :shadow],
        ["[ GRAND FINAL ]",   x_gf + slot_w / 2, 45, 2, Color.new(244, 114, 182), Color.black, :shadow]
      ])

      # -----------------------------------------------------------------------
      # 1. QUARTERFINALS (Column 1: 4 Matches, 8 Players)
      # -----------------------------------------------------------------------
      qf_y = [
        [58, 96],    # Match 0
        [136, 174],  # Match 1
        [214, 252],  # Match 2
        [292, 330]   # Match 3
      ]

      (0...4).each do |m_idx|
        m = @manager.bracket_matches[0][m_idx]
        y1, y2 = qf_y[m_idx]
        st1 = m[:winner] == m[:p1] ? :winner : (m[:loser] == m[:p1] ? :eliminated : nil)
        st2 = m[:winner] == m[:p2] ? :winner : (m[:loser] == m[:p2] ? :eliminated : nil)
        PokemonSurvivor.draw_bracket_slot(bmp, x_qf, y1, m[:p1], false, st1, slot_w, slot_h)
        PokemonSurvivor.draw_bracket_slot(bmp, x_qf, y2, m[:p2], false, st2, slot_w, slot_h)

        # Connector branches into Semifinals
        mid_x = x_qf + slot_w + 10
        p1_cy = y1 + slot_h / 2
        p2_cy = y2 + slot_h / 2
        bmp.fill_rect(x_qf + slot_w, p1_cy - 1, 10, 2, neon_cyan)
        bmp.fill_rect(x_qf + slot_w, p2_cy - 1, 10, 2, neon_cyan)
        bmp.fill_rect(mid_x - 1, p1_cy, 2, p2_cy - p1_cy, neon_cyan)
        dst_y = (p1_cy + p2_cy) / 2
        bmp.fill_rect(mid_x, dst_y - 1, x_sf - mid_x, 2, neon_cyan)
      end

      # -----------------------------------------------------------------------
      # 2. SEMIFINALS (Column 2: 2 Matches, 4 Players)
      # -----------------------------------------------------------------------
      sf_y = [
        [77, 155],   # Semi 0 (Winners of M0 & M1)
        [233, 311]   # Semi 1 (Winners of M2 & M3)
      ]

      (0...2).each do |s_idx|
        sm = @manager.bracket_matches[1][s_idx]
        y1, y2 = sf_y[s_idx]
        st1 = sm[:winner] == sm[:p1] ? :winner : (sm[:loser] == sm[:p1] ? :eliminated : nil)
        st2 = sm[:winner] == sm[:p2] ? :winner : (sm[:loser] == sm[:p2] ? :eliminated : nil)
        PokemonSurvivor.draw_bracket_slot(bmp, x_sf, y1, sm[:p1], false, st1, slot_w, slot_h)
        PokemonSurvivor.draw_bracket_slot(bmp, x_sf, y2, sm[:p2], false, st2, slot_w, slot_h)

        # Connector branches into Grand Final
        mid_x = x_sf + slot_w + 10
        p1_cy = y1 + slot_h / 2
        p2_cy = y2 + slot_h / 2
        bmp.fill_rect(x_sf + slot_w, p1_cy - 1, 10, 2, neon_gold)
        bmp.fill_rect(x_sf + slot_w, p2_cy - 1, 10, 2, neon_gold)
        bmp.fill_rect(mid_x - 1, p1_cy, 2, p2_cy - p1_cy, neon_gold)
        dst_y = (p1_cy + p2_cy) / 2
        bmp.fill_rect(mid_x, dst_y - 1, x_gf - mid_x, 2, neon_gold)
      end

      # -----------------------------------------------------------------------
      # 3. GRAND FINAL (Column 3: 1 Match, 2 Finalists - Giant 48px Cards!)
      # -----------------------------------------------------------------------
      slot_h_gf = 48
      gf_m = @manager.bracket_matches[2][0]
      gf_y1 = 88
      gf_y2 = 236
      st_fa = gf_m[:winner] == gf_m[:p1] ? :winner : (gf_m[:loser] == gf_m[:p1] ? :eliminated : nil)
      st_fb = gf_m[:winner] == gf_m[:p2] ? :winner : (gf_m[:loser] == gf_m[:p2] ? :eliminated : nil)
      PokemonSurvivor.draw_bracket_slot(bmp, x_gf, gf_y1, gf_m[:p1], false, st_fa, slot_w, slot_h_gf)
      PokemonSurvivor.draw_bracket_slot(bmp, x_gf, gf_y2, gf_m[:p2], false, st_fb, slot_w, slot_h_gf)

      # Center VS Box in the Grand Final Area
      gf_cx = x_gf + slot_w / 2

      bmp.fill_rect(gf_cx - 32, 168, 64, 34, Color.new(24, 16, 36))
      bmp.fill_rect(gf_cx - 32, 168, 64, 2, Color.new(255, 215, 0))
      bmp.fill_rect(gf_cx - 32, 200, 64, 2, Color.new(255, 215, 0))
      bmp.font.size = 20
      bmp.font.bold = true
      pbDrawTextPositions(bmp, [
        ["VS", gf_cx, 174, 2, Color.new(255, 215, 0), Color.black, :shadow]
      ])

      # Championship match banner above Final
      bmp.font.size = 12
      bmp.font.bold = true
      pbDrawTextPositions(bmp, [
        ["* CHAMPIONSHIP MATCH *", gf_cx, 68, 2, Color.new(255, 215, 0), Color.black, :shadow]
      ])

      if @manager.champion_winner
        champ = @manager.champion_winner
        champ_nick = PokemonSurvivor.format_name(champ[:nickname], 12)
        bmp.fill_rect(x_gf, 296, slot_w, 28, Color.new(25, 42, 22))
        bmp.fill_rect(x_gf, 296, slot_w, 2, Color.new(34, 197, 94))
        bmp.font.size = 12
        pbDrawTextPositions(bmp, [
          ["🏆 @#{champ_nick} 🏆", gf_cx, 302, 2, Color.new(255, 235, 90), Color.black, :shadow]
        ])
      end
    else
      # --- 16-PLAYER BRACKET (Round of 16 -> Quarters -> Semis -> Grand Final) ---
      slot_w = 84
      slot_h = 24
      branch_gap = 22

      fin_a_x = cx - slot_w - 20
      fin_b_x = cx + 20
      fin_y   = 184

      x_oct_l   = 16
      x_cuart_l = x_oct_l + slot_w + branch_gap
      x_semi_l  = x_cuart_l + slot_w + branch_gap

      x_oct_r   = w - 16 - slot_w
      x_cuart_r = x_oct_r - slot_w - branch_gap
      x_semi_r  = x_cuart_r - slot_w - branch_gap

      oct_y = [68, 98, 134, 164, 204, 234, 270, 300]
      cuart_y = [83, 149, 219, 285]
      semi_y  = [116, 252]

      # 1. Left Wing Round of 16
      (0...4).each do |m_idx|
        m = @manager.bracket_matches[0][m_idx]
        y1 = oct_y[m_idx * 2]
        y2 = oct_y[m_idx * 2 + 1]
        st1 = m[:winner] == m[:p1] ? :winner : (m[:loser] == m[:p1] ? :eliminated : nil)
        st2 = m[:winner] == m[:p2] ? :winner : (m[:loser] == m[:p2] ? :eliminated : nil)
        PokemonSurvivor.draw_bracket_slot(bmp, x_oct_l, y1, m[:p1], false, st1, slot_w, slot_h)
        PokemonSurvivor.draw_bracket_slot(bmp, x_oct_l, y2, m[:p2], false, st2, slot_w, slot_h)

        mid_x = x_oct_l + slot_w + (branch_gap / 2).round
        dst_x = x_cuart_l
        dst_y = cuart_y[m_idx] + 12
        bmp.fill_rect(x_oct_l + slot_w, y1 + 12, (branch_gap / 2).round, 2, neon_cyan)
        bmp.fill_rect(x_oct_l + slot_w, y2 + 12, (branch_gap / 2).round, 2, neon_cyan)
        bmp.fill_rect(mid_x, y1 + 12, 2, y2 - y1, neon_cyan)
        bmp.fill_rect(mid_x, dst_y, (branch_gap / 2).round, 2, neon_cyan)
      end

      # 2. Left Wing Quarterfinals
      (0...2).each do |m_idx|
        m = @manager.bracket_matches[1][m_idx]
        y1 = cuart_y[m_idx * 2]
        y2 = cuart_y[m_idx * 2 + 1]
        st1 = m[:winner] == m[:p1] ? :winner : (m[:loser] == m[:p1] ? :eliminated : nil)
        st2 = m[:winner] == m[:p2] ? :winner : (m[:loser] == m[:p2] ? :eliminated : nil)
        PokemonSurvivor.draw_bracket_slot(bmp, x_cuart_l, y1, m[:p1], false, st1, slot_w, slot_h)
        PokemonSurvivor.draw_bracket_slot(bmp, x_cuart_l, y2, m[:p2], false, st2, slot_w, slot_h)

        mid_x = x_cuart_l + slot_w + (branch_gap / 2).round
        dst_x = x_semi_l
        dst_y = semi_y[m_idx] + 12
        bmp.fill_rect(x_cuart_l + slot_w, y1 + 12, (branch_gap / 2).round, 2, neon_cyan)
        bmp.fill_rect(x_cuart_l + slot_w, y2 + 12, (branch_gap / 2).round, 2, neon_cyan)
        bmp.fill_rect(mid_x, y1 + 12, 2, y2 - y1, neon_cyan)
        bmp.fill_rect(mid_x, dst_y, (branch_gap / 2).round, 2, neon_cyan)
      end

      # 3. Left Wing Semifinal
      semi_m0 = @manager.bracket_matches[2][0]
      st1 = semi_m0[:winner] == semi_m0[:p1] ? :winner : (semi_m0[:loser] == semi_m0[:p1] ? :eliminated : nil)
      st2 = semi_m0[:winner] == semi_m0[:p2] ? :winner : (semi_m0[:loser] == semi_m0[:p2] ? :eliminated : nil)
      PokemonSurvivor.draw_bracket_slot(bmp, x_semi_l, semi_y[0], semi_m0[:p1], false, st1, slot_w, slot_h)
      PokemonSurvivor.draw_bracket_slot(bmp, x_semi_l, semi_y[1], semi_m0[:p2], false, st2, slot_w, slot_h)

      mid_x_s = x_semi_l + slot_w + 14
      bmp.fill_rect(x_semi_l + slot_w, semi_y[0] + 12, 14, 2, neon_gold)
      bmp.fill_rect(x_semi_l + slot_w, semi_y[1] + 12, 14, 2, neon_gold)
      bmp.fill_rect(mid_x_s, semi_y[0] + 12, 2, semi_y[1] - semi_y[0], neon_gold)
      bmp.fill_rect(mid_x_s, fin_y + 12, fin_a_x - mid_x_s, 2, neon_gold)

      # 4. Right Wing Round of 16
      (0...4).each do |m_idx|
        m = @manager.bracket_matches[0][m_idx + 4]
        y1 = oct_y[m_idx * 2]
        y2 = oct_y[m_idx * 2 + 1]
        st1 = m[:winner] == m[:p1] ? :winner : (m[:loser] == m[:p1] ? :eliminated : nil)
        st2 = m[:winner] == m[:p2] ? :winner : (m[:loser] == m[:p2] ? :eliminated : nil)
        PokemonSurvivor.draw_bracket_slot(bmp, x_oct_r, y1, m[:p1], false, st1, slot_w, slot_h)
        PokemonSurvivor.draw_bracket_slot(bmp, x_oct_r, y2, m[:p2], false, st2, slot_w, slot_h)

        mid_x = x_oct_r - (branch_gap / 2).round
        dst_x = x_cuart_r + slot_w
        dst_y = cuart_y[m_idx] + 12
        bmp.fill_rect(mid_x, y1 + 12, (branch_gap / 2).round, 2, neon_cyan)
        bmp.fill_rect(mid_x, y2 + 12, (branch_gap / 2).round, 2, neon_cyan)
        bmp.fill_rect(mid_x, y1 + 12, 2, y2 - y1, neon_cyan)
        bmp.fill_rect(dst_x, dst_y, mid_x - dst_x, 2, neon_cyan)
      end

      # 5. Right Wing Quarterfinals
      (0...2).each do |m_idx|
        m = @manager.bracket_matches[1][m_idx + 2]
        y1 = cuart_y[m_idx * 2]
        y2 = cuart_y[m_idx * 2 + 1]
        st1 = m[:winner] == m[:p1] ? :winner : (m[:loser] == m[:p1] ? :eliminated : nil)
        st2 = m[:winner] == m[:p2] ? :winner : (m[:loser] == m[:p2] ? :eliminated : nil)
        PokemonSurvivor.draw_bracket_slot(bmp, x_cuart_r, y1, m[:p1], false, st1, slot_w, slot_h)
        PokemonSurvivor.draw_bracket_slot(bmp, x_cuart_r, y2, m[:p2], false, st2, slot_w, slot_h)

        mid_x = x_cuart_r - (branch_gap / 2).round
        dst_x = x_semi_r + slot_w
        dst_y = semi_y[m_idx] + 12
        bmp.fill_rect(mid_x, y1 + 12, (branch_gap / 2).round, 2, neon_cyan)
        bmp.fill_rect(mid_x, y2 + 12, (branch_gap / 2).round, 2, neon_cyan)
        bmp.fill_rect(mid_x, y1 + 12, 2, y2 - y1, neon_cyan)
        bmp.fill_rect(dst_x, dst_y, mid_x - dst_x, 2, neon_cyan)
      end

      # 6. Right Wing Semifinal
      semi_m1 = @manager.bracket_matches[2][1]
      st1 = semi_m1[:winner] == semi_m1[:p1] ? :winner : (semi_m1[:loser] == semi_m1[:p1] ? :eliminated : nil)
      st2 = semi_m1[:winner] == semi_m1[:p2] ? :winner : (semi_m1[:loser] == semi_m1[:p2] ? :eliminated : nil)
      PokemonSurvivor.draw_bracket_slot(bmp, x_semi_r, semi_y[0], semi_m1[:p1], false, st1, slot_w, slot_h)
      PokemonSurvivor.draw_bracket_slot(bmp, x_semi_r, semi_y[1], semi_m1[:p2], false, st2, slot_w, slot_h)

      mid_x_r = x_semi_r - 14
      bmp.fill_rect(mid_x_r, semi_y[0] + 12, 14, 2, neon_gold)
      bmp.fill_rect(mid_x_r, semi_y[1] + 12, 14, 2, neon_gold)
      bmp.fill_rect(mid_x_r, semi_y[0] + 12, 2, semi_y[1] - semi_y[0], neon_gold)
      bmp.fill_rect(fin_b_x + slot_w, fin_y + 12, mid_x_r - (fin_b_x + slot_w), 2, neon_gold)

      # 7. Center Grand Final (Round 3)
      final_m = @manager.bracket_matches[3][0]
      st_fa = final_m[:winner] == final_m[:p1] ? :winner : (final_m[:loser] == final_m[:p1] ? :eliminated : nil)
      st_fb = final_m[:winner] == final_m[:p2] ? :winner : (final_m[:loser] == final_m[:p2] ? :eliminated : nil)
      PokemonSurvivor.draw_bracket_slot(bmp, fin_a_x, fin_y, final_m[:p1], false, st_fa, slot_w, slot_h)
      PokemonSurvivor.draw_bracket_slot(bmp, fin_b_x, fin_y, final_m[:p2], false, st_fb, slot_w, slot_h)

      # Center VS Text
      bmp.font.size = 14
      bmp.font.bold = true
      pbDrawTextPositions(bmp, [
        ["VS", cx, fin_y + 5, 2, Color.new(255, 215, 0), Color.black, :shadow]
      ])
    end

    bmp.fill_rect(0, Graphics.height - 22, Graphics.width, 22, Color.new(10, 14, 24))
    bmp.font.size = 10
    pbDrawTextPositions(bmp, [
      ["Winners advance to the next round | The Champion defends the crown", Graphics.width / 2, Graphics.height - 17, 2, Color.new(148, 163, 184), Color.black, :shadow]
    ])
  end

  # ===========================================================================
  # RENDERING: 3. COMBAT (Clean Platforms, Unobstructed Text, English)
  # ===========================================================================
  def draw_combat
    bmp = @sprites["screen"].bitmap
    bmp.clear

    bmp.font.name = ["Arial", "Segoe UI"]
    bmp.font.bold = true

    if @manager.phase == :grand_final
      bmp.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(24, 12, 34))

      # Grand Battle Stage Platform
      plat_y = 236
      plat_x = 24
      plat_w = Graphics.width - 48
      plat_h = Graphics.height - plat_y - 24

      # Stage Base & Shadows
      bmp.fill_rect(plat_x, plat_y, plat_w, plat_h, Color.new(42, 20, 56))
      # Gold Border & Neon Accent
      bmp.fill_rect(plat_x, plat_y, plat_w, 3, Color.new(255, 215, 0))
      bmp.fill_rect(plat_x, plat_y + 3, plat_w, 1, Color.new(180, 140, 20))

      # Grand Final Title Header
      bmp.font.size = 20
      bmp.font.bold = true
      pbDrawTextPositions(bmp, [
        ["* CHERNO CUP - GRAND FINAL *", Graphics.width / 2, 12, 2, Color.new(255, 215, 0), Color.black, :shadow]
      ])

      m = @active_matches[1]
      if m
        bmp.font.size = 15
        pbDrawTextPositions(bmp, [
          ["TIME: #{m[:timer].ceil}s", Graphics.width / 2, 36, 2, Color.white, Color.black, :shadow]
        ])

        e1 = m[:e1]
        e2 = m[:e2]
        bmp.font.bold = true

        # Left Champ / Fighter (P1)
        p1_tier_col = case e1[:tier]
                      when 4 then Color.new(255, 215, 0)
                      when 3 then Color.new(245, 100, 220)
                      when 2 then Color.new(56, 189, 248)
                      else Color.new(234, 179, 8)
                      end
        PokemonSurvivor.draw_circular_avatar(bmp, e1[:pfp_path], 28, 66, 18, p1_tier_col, e1[:is_host], e1[:nickname])

        p1_nick = PokemonSurvivor.format_name(e1[:nickname], 12)
        p1_sp = PokemonSurvivor.format_name(e1[:species_name] || e1[:species], 10)
        t1_sym = e1[:type] || :NORMAL
        t1_col = PokemonSurvivor.type_color(t1_sym)
        bmp.font.size = 14
        pbDrawTextPositions(bmp, [
          ["@#{p1_nick}", 54, 48, 0, Color.new(255, 245, 170), Color.black, :shadow],
          ["#{p1_sp} [#{t1_sym}]", 54, 75, 0, t1_col, Color.black, :shadow]
        ])
        bar_w = 155
        bar_h = 8
        bar_y = 64
        bmp.fill_rect(53, bar_y - 1, bar_w + 2, bar_h + 2, Color.black)
        bmp.fill_rect(54, bar_y, bar_w, bar_h, Color.new(30, 41, 59))
        hp1_pct = [[e1[:hp].to_f / [e1[:max_hp], 1].max, 0.0].max, 1.0].min
        hp1_col = hp1_pct > 0.5 ? Color.new(34, 197, 94) : (hp1_pct > 0.25 ? Color.new(234, 179, 8) : Color.new(239, 68, 68))
        bmp.fill_rect(54, bar_y, (bar_w * hp1_pct).round, bar_h, hp1_col)

        # Right Challenger / Fighter (P2)
        p2_tier_col = case e2[:tier]
                      when 4 then Color.new(255, 215, 0)
                      when 3 then Color.new(245, 100, 220)
                      when 2 then Color.new(56, 189, 248)
                      else Color.new(234, 179, 8)
                      end
        PokemonSurvivor.draw_circular_avatar(bmp, e2[:pfp_path], Graphics.width - 28, 66, 18, p2_tier_col, e2[:is_host], e2[:nickname])

        p2_nick = PokemonSurvivor.format_name(e2[:nickname], 12)
        p2_sp = PokemonSurvivor.format_name(e2[:species_name] || e2[:species], 10)
        t2_sym = e2[:type] || :NORMAL
        t2_col = PokemonSurvivor.type_color(t2_sym)
        bmp.font.size = 14
        p2_bar_x = Graphics.width - 54 - bar_w
        pbDrawTextPositions(bmp, [
          ["@#{p2_nick}", Graphics.width - 54, 48, 1, Color.white, Color.black, :shadow],
          ["#{p2_sp} [#{t2_sym}]", Graphics.width - 54, 75, 1, t2_col, Color.black, :shadow]
        ])
        bmp.fill_rect(p2_bar_x - 1, bar_y - 1, bar_w + 2, bar_h + 2, Color.black)
        bmp.fill_rect(p2_bar_x, bar_y, bar_w, bar_h, Color.new(30, 41, 59))
        hp2_pct = [[e2[:hp].to_f / [e2[:max_hp], 1].max, 0.0].max, 1.0].min
        hp2_col = hp2_pct > 0.5 ? Color.new(34, 197, 94) : (hp2_pct > 0.25 ? Color.new(234, 179, 8) : Color.new(239, 68, 68))
        f2_w = (bar_w * hp2_pct).round
        bmp.fill_rect(p2_bar_x + (bar_w - f2_w), bar_y, f2_w, bar_h, hp2_col)

        # P1 Attack Move Callout Badge (Grand Final)
        if (e1[:last_move_timer] || 0) > 0
          m1_col = e1[:last_move_color] || t1_col
          is_ult1 = e1[:last_move_is_ult]
          b1_w = 145
          bmp.fill_rect(54, 91, b1_w, 16, Color.new(10, 15, 26, 210))
          bmp.fill_rect(54, 91, b1_w, 1, is_ult1 ? Color.new(255, 215, 0) : m1_col)
          bmp.fill_rect(54, 91 + 15, b1_w, 1, is_ult1 ? Color.new(255, 215, 0) : m1_col)
          bmp.font.size = is_ult1 ? 11 : 10
          bmp.font.bold = true
          p1_m_text = is_ult1 ? "★ #{e1[:last_move_name].upcase} ★" : "> #{e1[:last_move_name].upcase}"
          pbDrawTextPositions(bmp, [
            [p1_m_text, 58, 92, 0, is_ult1 ? Color.new(255, 220, 50) : m1_col, Color.black, :shadow]
          ])
        end

        # P2 Attack Move Callout Badge (Grand Final)
        if (e2[:last_move_timer] || 0) > 0
          m2_col = e2[:last_move_color] || t2_col
          is_ult2 = e2[:last_move_is_ult]
          b2_w = 145
          b2_x = Graphics.width - 54 - b2_w
          bmp.fill_rect(b2_x, 91, b2_w, 16, Color.new(10, 15, 26, 210))
          bmp.fill_rect(b2_x, 91, b2_w, 1, is_ult2 ? Color.new(255, 215, 0) : m2_col)
          bmp.fill_rect(b2_x, 91 + 15, b2_w, 1, is_ult2 ? Color.new(255, 215, 0) : m2_col)
          bmp.font.size = is_ult2 ? 11 : 10
          bmp.font.bold = true
          p2_m_text = is_ult2 ? "★ #{e2[:last_move_name].upcase} ★" : "#{e2[:last_move_name].upcase} <"
          pbDrawTextPositions(bmp, [
            [p2_m_text, b2_x + b2_w - 4, 92, 1, is_ult2 ? Color.new(255, 220, 50) : m2_col, Color.black, :shadow]
          ])
        end

        # Center VS
        bmp.font.size = 18
        pbDrawTextPositions(bmp, [
          ["VS", Graphics.width / 2, 56, 2, Color.new(255, 215, 0), Color.black, :shadow]
        ])

        PokemonSurvivor.draw_arena_fighter_sprite(bmp, m[:e1], 1.35)
        PokemonSurvivor.draw_arena_fighter_sprite(bmp, m[:e2], 1.35)
      end
    else
      # 6 Simultaneous Arenas (3 Columns x 2 Rows)
      w = Graphics.width / 3.0
      h = (Graphics.height - 24) / 2.0

      (0...6).each do |a|
        ax, ay, aw, ah, cx, cy = arena_bounds(a)
        is_champion_lane = (a == 1)

        # 1. Arena Background
        bg_col = is_champion_lane ? Color.new(34, 18, 42) : Color.new(15, 23, 42)
        bmp.fill_rect(ax, ay, aw, ah, bg_col)

        # 2. Floor Platform at the very bottom edge (Never cuts text or sprites!)
        floor_line_y = ay + ah - 6
        border_col = is_champion_lane ? Color.new(255, 215, 0) : Color.new(56, 189, 248)
        bmp.fill_rect(ax + 8, floor_line_y, aw - 16, 4, is_champion_lane ? Color.new(48, 25, 58) : Color.new(24, 34, 58))
        bmp.fill_rect(ax + 8, floor_line_y, aw - 16, 1, border_col)

        # 3. Arena Header
        bmp.font.size = 11
        bmp.font.bold = true
        label_text = is_champion_lane ? "* ARENA 2: CHAMPION *" : "[ ARENA #{a + 1} ]"
        label_col = is_champion_lane ? Color.new(255, 215, 0) : Color.new(56, 189, 248)

        m = @active_matches[a]
        timer_text = m ? "#{m[:timer].ceil}s" : "--"
        pbDrawTextPositions(bmp, [
          ["#{label_text} [#{timer_text}]", cx, ay + 3, 2, label_col, Color.black, :shadow]
        ])

        # 4. Render Active Fighters or Match Result (Completely unobstructed!)
        if m
          PokemonSurvivor.draw_arena_match_hud(bmp, ax, ay, aw, ah, cx, cy, m[:e1], m[:e2])
          PokemonSurvivor.draw_arena_fighter_sprite(bmp, m[:e1], 0.95)
          PokemonSurvivor.draw_arena_fighter_sprite(bmp, m[:e2], 0.95)
        elsif @arena_results[a]
          res = @arena_results[a]
          win_nick = PokemonSurvivor.format_name(res[:winner][:nickname], 12)
          win_sp = PokemonSurvivor.format_name(res[:winner][:species_name] || res[:winner][:species], 10)

          bmp.font.size = 12
          bmp.font.bold = true
          pbDrawTextPositions(bmp, [
            ["[ MATCH COMPLETE ]", cx, cy - 14, 2, Color.new(148, 163, 184), Color.black, :shadow],
            ["Winner: @#{win_nick} (#{win_sp})", cx, cy + 2, 2, Color.new(255, 215, 0), Color.black, :shadow]
          ])
        else
          bmp.font.size = 11
          pbDrawTextPositions(bmp, [
            ["[ Waiting for Next Round ]", cx, cy - 6, 2, Color.new(100, 116, 139), Color.black, :none]
          ])
        end
      end

      # Neon Division Lines
      bmp.fill_rect((w).round - 2, 0, 4, (h * 2).round, Color.new(56, 189, 248))
      bmp.fill_rect((w * 2).round - 2, 0, 4, (h * 2).round, Color.new(56, 189, 248))
      bmp.fill_rect(0, (h).round - 2, Graphics.width, 4, Color.new(255, 215, 0))
    end

    # 4. Projectiles (Smooth in standard arenas, Grand cinematic energy orbs in Grand Final)
    is_gf = (@manager.phase == :grand_final)
    @projectiles.each do |pr|
      p_col = PokemonSurvivor.type_color(pr[:type] || :NORMAL)
      if is_gf
        # Grand Final: Large luminous plasma orbs with glowing halo and intense energy core
        orb_rad = pr[:is_ult] ? 9 : 6
        pulse = (Math.sin((@anim_tick * 0.25) + (pr[:x] * 0.1)) * 1.5).round
        total_rad = orb_rad + pulse

        # Glowing translucent energy aura
        bmp.fill_rect(pr[:x] - total_rad, pr[:y] - total_rad, total_rad * 2, total_rad * 2, Color.new(p_col.red, p_col.green, p_col.blue, 90))
        # Solid elemental core
        bmp.fill_rect(pr[:x] - (orb_rad - 1), pr[:y] - (orb_rad - 1), (orb_rad - 1) * 2, (orb_rad - 1) * 2, p_col)
        # Intense white energy center
        bmp.fill_rect(pr[:x] - 2, pr[:y] - 2, 4, 4, Color.white)
      else
        rad = 3
        bmp.fill_rect(pr[:x] - rad, pr[:y] - rad, rad * 2, rad * 2, p_col)
        bmp.fill_rect(pr[:x] - 1, pr[:y] - 1, 3, 3, Color.white)
      end
    end

    # 4b. Elemental Sparks & Impact Particles
    @sparks.each do |sp|
      bmp.fill_rect(sp[:x].round, sp[:y].round, sp[:size] || 2, sp[:size] || 2, sp[:color])
    end

    # 5. Berries (+25 HP)
    @berries.each do |b|
      bmp.fill_rect(b[:x] - 4, b[:y] - 4, 8, 8, Color.new(239, 68, 68))
      bmp.fill_rect(b[:x] - 2, b[:y] - 7, 4, 3, Color.new(34, 197, 94))
    end

    # 6. Floating Texts
    @floating_texts.each do |ft|
      bmp.font.size = 11
      bmp.font.bold = true
      pbDrawTextPositions(bmp, [
        [ft[:text], ft[:x], ft[:y], 2, ft[:color], Color.black, :outline]
      ])
    end

    # 7. Bottom Chat Banner
    bmp.fill_rect(0, Graphics.height - 24, Graphics.width, 24, Color.new(8, 12, 20))
    bmp.font.size = 10
    bmp.font.bold = true
    pbDrawTextPositions(bmp, [
      ["CHAT: #1 (Vote Left) | #2 (Vote Right) | TAPS: Drop Berries (+25 HP) | GIFTS: Dynamax / Airstrike", Graphics.width / 2, Graphics.height - 18, 2, Color.new(56, 189, 248), Color.black, :outline]
    ])
  end

  # ===========================================================================
  # RENDERING: 4. PODIUM (Full English, Type Colored Text)
  # ===========================================================================
  def draw_podium
    bmp = @sprites["screen"].bitmap
    bmp.clear

    bmp.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(16, 12, 28))

    bmp.font.name = ["Arial", "Segoe UI"]
    bmp.font.size = 22
    bmp.font.bold = true
    pbDrawTextPositions(bmp, [
      ["* CHERNO CUP CHAMPION!! *", Graphics.width / 2, 20, 2, Color.new(255, 215, 0), Color.black, :shadow]
    ])

    if @manager.champion_winner
      champ = @manager.champion_winner
      is_host = champ[:is_host]
      cx = Graphics.width / 2
      floor_y = 195

      # Crown Medallion of the Champion Trainer (PFP)
      pfp_rad = 22
      pfp_y = 75
      champ_border = Color.new(255, 215, 0)
      PokemonSurvivor.draw_circular_avatar(bmp, champ[:pfp_path], cx, pfp_y, pfp_rad, champ_border, true, champ[:nickname])

      # Crown indicator text over avatar
      bmp.font.size = 12
      bmp.font.bold = true
      pbDrawTextPositions(bmp, [
        ["* WINNING TRAINER *", cx, pfp_y - pfp_rad - 15, 2, Color.new(255, 230, 80), Color.black, :shadow]
      ])

      ped_w = 160
      bmp.fill_rect(cx - ped_w / 2, floor_y + 36, ped_w, 20, Color.new(45, 32, 15))
      bmp.fill_rect(cx - ped_w / 2, floor_y + 36, ped_w, 2, Color.new(255, 215, 0))

      hero_bmp = PokemonSurvivor.get_cached_hero(champ[:species])
      if hero_bmp && !hero_bmp.disposed?
        frame = (@anim_tick / 15) % 4
        PokemonSurvivor.draw_character_centered(bmp, hero_bmp, cx, floor_y, PokemonSurvivor::DIR_DOWN, frame, 2.4)
      end

      nick_str = PokemonSurvivor.format_name(champ[:nickname], 12)
      sp_str = PokemonSurvivor.format_name(champ[:species_name] || champ[:species], 10)
      type_sym = champ[:type] || :NORMAL
      type_col = PokemonSurvivor.type_color(type_sym)

      title = is_host ? "[LEAGUE CHAMPION] @#{nick_str}" : "@#{nick_str}"
      bmp.font.size = 17
      bmp.font.bold = true
      pbDrawTextPositions(bmp, [
        [title, cx, floor_y + 64, 2, Color.new(255, 225, 60), Color.black, :shadow]
      ])

      bmp.font.size = 14
      spec_text = "MASTER OF #{sp_str} [#{type_sym}]"
      pbDrawTextPositions(bmp, [
        [spec_text, cx, floor_y + 86, 2, type_col, Color.black, :shadow]
      ])
    end

    bmp.font.size = 12
    bmp.font.bold = true
    pbDrawTextPositions(bmp, [
      ["Starting next Cherno CUP tournament shortly...", Graphics.width / 2, Graphics.height - 24, 2, Color.new(203, 213, 225), Color.black, :shadow]
    ])
  end
end
