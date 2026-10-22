#===============================================================================
# Pokemon Survivor - TikTok Tournament Render Stack
# 1. Background / Aura: Circular PFP medallion + Tier ring
# 2. Body: Animated in-game Pokemon sprite (Walk / Idle)
# 3. Top UI: Clean @nickname with high contrast outline
# 4. Bottom UI: Dynamic HP bar + Ultimate + Type (Colored by Elemental Type)
# 5. Bracket Tree Slots: English notation ([W], [X], [TBD]) with colored types
#===============================================================================

module PokemonSurvivor
  class << self
    def get_cached_hero(species)
      @hero_cache ||= {}
      key = species.to_s.upcase
      return @hero_cache[key] if @hero_cache[key] && !@hero_cache[key].disposed?

      # Search in Hero, Wild (e.g. Snorlax, Wooper, Torchic), Boss (e.g. Heracross), Alt, Event, and Ultra Boss directories
      dirs_to_check = [
        PokemonSurvivor::HERO_DIR,
        PokemonSurvivor::WILD_DIR,
        PokemonSurvivor::BOSS_DIR,
        PokemonSurvivor::HERO_ALT_DIR,
        PokemonSurvivor::EVENT_DIR,
        PokemonSurvivor::ULTRA_BOSS_DIR
      ]

      bmp = nil
      dirs_to_check.each do |dir|
        bmp = PokemonSurvivor.load_bitmap(dir, key) rescue nil
        bmp ||= PokemonSurvivor.load_bitmap(dir, "#{key}_Idle") rescue nil
        break if bmp && !bmp.disposed?
      end

      # Fallback only if asset not found anywhere
      bmp ||= PokemonSurvivor.load_bitmap(PokemonSurvivor::HERO_DIR, "PIKACHU") rescue nil

      @hero_cache[key] = bmp
      bmp
    end

    def get_cached_avatar(pfp_path)
      return nil unless pfp_path && !pfp_path.empty?
      @avatar_cache ||= {}
      clean_key = pfp_path.to_s.tr('\\', '/')
      cached = @avatar_cache[clean_key]
      return cached if cached && !cached.disposed?

      candidates = [
        clean_key,
        (clean_key.end_with?(".png") ? clean_key[0..-5] : clean_key),
        "Graphics/Avatars/" + File.basename(clean_key),
        "Graphics/Avatars/" + File.basename(clean_key, ".*")
      ]

      bmp = nil
      candidates.each do |c|
        resolved = pbResolveBitmap(c) rescue nil
        target_path = resolved || (File.exist?(c) ? c : nil)
        next unless target_path && File.file?(target_path)

        # Pre-check signature: Only load valid PNG or JPEG to prevent RGSS "Unsupported image format" errors
        is_supported = false
        begin
          File.open(target_path, "rb") do |f|
            magic = f.read(8)
            # PNG: 89 50 4E 47 0D 0A 1A 0A | JPG: FF D8
            is_supported = magic && (magic.start_with?("\x89PNG\r\n\x1a\n".b) || magic.start_with?("\xFF\xD8".b))
          end
        rescue Exception
          is_supported = false
        end

        if is_supported
          begin
            bmp = Bitmap.new(target_path)
            break if bmp && !bmp.disposed?
          rescue Exception => e
            bmp = nil
          end
        end
      end

      @avatar_cache[clean_key] = bmp if bmp
      bmp
    end

    def draw_circular_avatar(target_bitmap, pfp_path, cx, cy, radius, border_color, is_host = false, label = nil)
      glow = is_host ? 3 : 1
      glow_col = is_host ? Color.new(255, 215, 0, 90) : Color.new(border_color.red, border_color.green, border_color.blue, 60)
      target_bitmap.fill_rect(cx - radius - glow, cy - radius - glow, (radius + glow) * 2, (radius + glow) * 2, glow_col) rescue nil

      # Background box
      target_bitmap.fill_rect(cx - radius, cy - radius, radius * 2, radius * 2, Color.new(15, 23, 42)) rescue nil

      drawn_pfp = false
      pfp_bmp = get_cached_avatar(pfp_path)
      if pfp_bmp && !pfp_bmp.disposed?
        target_bitmap.stretch_blt(
          Rect.new(cx - radius + 2, cy - radius + 2, radius * 2 - 4, radius * 2 - 4),
          pfp_bmp,
          Rect.new(0, 0, pfp_bmp.width, pfp_bmp.height)
        ) rescue nil
        drawn_pfp = true
      end

      # Retro monogram if no PFP image
      if !drawn_pfp && label
        tag = label.to_s.gsub('@', '').strip[0..1].upcase
        target_bitmap.font.name = ["Arial", "Segoe UI"]
        target_bitmap.font.size = [[radius - 1, 9].max, 14].min
        target_bitmap.font.bold = true
        pbDrawTextPositions(target_bitmap, [
          [tag, cx, cy - (radius / 2).round + 1, 2, Color.white, Color.new(0, 0, 0, 220), :shadow]
        ]) rescue nil
      end

      # Crisp Border
      border_w = is_host ? 3 : 2
      (0...border_w).each do |b|
        r = radius + b
        target_bitmap.fill_rect(cx - r, cy - r, r * 2, 1, border_color) rescue nil
        target_bitmap.fill_rect(cx - r, cy + r - 1, r * 2, 1, border_color) rescue nil
        target_bitmap.fill_rect(cx - r, cy - r, 1, r * 2, border_color) rescue nil
        target_bitmap.fill_rect(cx + r - 1, cy - r, 1, r * 2, border_color) rescue nil
      end

      # Beveled / rounded corner clip for sleek medallion look
      if radius >= 12
        corner_c = Color.new(10, 15, 26)
        target_bitmap.fill_rect(cx - radius - border_w, cy - radius - border_w, 2, 2, corner_c) rescue nil
        target_bitmap.fill_rect(cx + radius + border_w - 2, cy - radius - border_w, 2, 2, corner_c) rescue nil
        target_bitmap.fill_rect(cx - radius - border_w, cy + radius + border_w - 2, 2, 2, corner_c) rescue nil
        target_bitmap.fill_rect(cx + radius + border_w - 2, cy + radius + border_w - 2, 2, 2, corner_c) rescue nil
      end
    end

    def type_short(type_sym)
      case type_sym.to_s.upcase
      when "NORMAL"   then "NOR"
      when "FIRE"     then "FIR"
      when "WATER"    then "WAT"
      when "GRASS"    then "GRA"
      when "ELECTRIC" then "ELE"
      when "ICE"      then "ICE"
      when "FIGHTING" then "FIG"
      when "POISON"   then "POI"
      when "GROUND"   then "GRO"
      when "FLYING"   then "FLY"
      when "PSYCHIC"  then "PSY"
      when "BUG"      then "BUG"
      when "ROCK"     then "ROC"
      when "GHOST"    then "GHO"
      when "DRAGON"   then "DRA"
      when "STEEL"    then "STE"
      when "DARK"     then "DAR"
      when "FAIRY"    then "FAI"
      else type_sym.to_s[0..2].upcase
      end
    end

    SIGNATURE_MOVES_BY_SPECIES = {
      :CHARIZARD => { basic: "Flamethrower",   ult: "G-Max Wildfire" },
      :PIKACHU   => { basic: "Thunderbolt",    ult: "Volt Tackle" },
      :BLASTOISE => { basic: "Hydro Pump",     ult: "G-Max Cannonade" },
      :VENUSAUR  => { basic: "Solar Beam",     ult: "G-Max Vine Lash" },
      :GENGAR    => { basic: "Shadow Ball",    ult: "G-Max Terror" },
      :LUCARIO   => { basic: "Aura Sphere",    ult: "Close Combat" },
      :MEWTWO    => { basic: "Psystrike",      ult: "Psystrike Nova" },
      :RAYQUAZA  => { basic: "Dragon Ascent",  ult: "Draco Meteor" },
      :GARCHOMP  => { basic: "Dragon Claw",    ult: "Earthquake" },
      :TYRANITAR => { basic: "Stone Edge",     ult: "Hyper Beam" },
      :SNORLAX   => { basic: "Body Slam",      ult: "G-Max Replenish" },
      :EEVEE     => { basic: "Swift",          ult: "Extreme Evoboost" },
      :GRENINJA  => { basic: "Water Shuriken", ult: "Hydro Cannon" },
      :DRAGONITE => { basic: "Dragon Pulse",   ult: "Outrage" },
      :ARCANINE  => { basic: "Fire Blast",     ult: "Flare Blitz" },
      :GYARADOS  => { basic: "Waterfall",      ult: "Hydro Pump" }
    }

    SIGNATURE_MOVES_BY_TYPE = {
      :FIRE     => { basic: "Flamethrower", ult: "Blast Burn" },
      :WATER    => { basic: "Hydro Pump",   ult: "Hydro Cannon" },
      :GRASS    => { basic: "Solar Beam",   ult: "Frenzy Plant" },
      :ELECTRIC => { basic: "Thunderbolt",  ult: "Thunder Storm" },
      :ICE      => { basic: "Ice Beam",     ult: "Blizzard" },
      :FIGHTING => { basic: "Close Combat", ult: "Focus Blast" },
      :POISON   => { basic: "Sludge Bomb",  ult: "Gunk Shot" },
      :GROUND   => { basic: "Earth Power",  ult: "Earthquake" },
      :FLYING   => { basic: "Air Slash",    ult: "Brave Bird" },
      :PSYCHIC  => { basic: "Psychic",      ult: "Psycho Boost" },
      :BUG      => { basic: "Bug Buzz",     ult: "Megahorn" },
      :ROCK     => { basic: "Rock Slide",   ult: "Stone Edge" },
      :GHOST    => { basic: "Shadow Ball",  ult: "Phantom Force" },
      :DRAGON   => { basic: "Dragon Pulse", ult: "Draco Meteor" },
      :STEEL    => { basic: "Flash Cannon", ult: "Meteor Mash" },
      :DARK     => { basic: "Dark Pulse",   ult: "Night Slash" },
      :FAIRY    => { basic: "Dazzling Gleam", ult: "Moonblast" },
      :NORMAL   => { basic: "Hyper Voice",  ult: "Hyper Beam" }
    }

    def get_move_name(species, type, is_ult = false)
      spec_sym = species.to_s.upcase.to_sym
      type_sym = type.to_s.upcase.to_sym
      info = SIGNATURE_MOVES_BY_SPECIES[spec_sym] || SIGNATURE_MOVES_BY_TYPE[type_sym] || SIGNATURE_MOVES_BY_TYPE[:NORMAL]
      is_ult ? info[:ult] : info[:basic]
    end

    def draw_arena_match_hud(target_bitmap, ax, ay, aw, ah, cx, cy, e1, e2)
      return unless e1 && e2
      target_bitmap.font.name = ["Arial", "Segoe UI"]
      target_bitmap.font.bold = true

      # --- LEFT FIGHTER (P1) CORNER AVATAR + HUD ---
      p1_tier_col = case e1[:tier]
                    when 4 then Color.new(255, 215, 0)
                    when 3 then Color.new(245, 100, 220)
                    when 2 then Color.new(56, 189, 248)
                    else Color.new(234, 179, 8)
                    end
      av1_x = ax + 14
      av1_y = ay + 28
      draw_circular_avatar(target_bitmap, e1[:pfp_path], av1_x, av1_y, 10, p1_tier_col, e1[:is_host], e1[:nickname])

      p1_box_x = ax + 28
      target_bitmap.fill_rect(p1_box_x - 1, ay + 14, 52, 31, Color.new(0, 0, 0, 180))
      target_bitmap.fill_rect(p1_box_x, ay + 15, 50, 29, Color.new(15, 23, 42))

      p1_nick = PokemonSurvivor.format_name(e1[:nickname], 8)
      p1_pref = e1[:is_host] ? "* " : "@"
      p1_name_col = e1[:is_host] ? Color.new(255, 230, 80) : Color.white
      target_bitmap.font.size = 11
      pbDrawTextPositions(target_bitmap, [
        ["#{p1_pref}#{p1_nick}", p1_box_x + 2, ay + 15, 0, p1_name_col, Color.new(0, 0, 0, 220), :shadow]
      ])

      # P1 HP Bar
      bar_w = 46
      bar_h = 5
      bar_y = ay + 26
      target_bitmap.fill_rect(p1_box_x + 2, bar_y - 1, bar_w + 2, bar_h + 2, Color.black)
      target_bitmap.fill_rect(p1_box_x + 2, bar_y, bar_w, bar_h, Color.new(30, 41, 59))
      hp1_pct = [[e1[:hp].to_f / [e1[:max_hp], 1].max, 0.0].max, 1.0].min
      fill1_w = (bar_w * hp1_pct).round
      hp1_col = hp1_pct > 0.5 ? Color.new(34, 215, 94) : (hp1_pct > 0.25 ? Color.new(250, 204, 21) : Color.new(239, 68, 68))
      target_bitmap.fill_rect(p1_box_x + 2, bar_y, fill1_w, bar_h, hp1_col)
      ult1_pct = [[(e1[:ult] || 0).to_f / 100.0, 0.0].max, 1.0].min
      if ult1_pct > 0
        target_bitmap.fill_rect(p1_box_x + 2, bar_y + bar_h + 1, (bar_w * ult1_pct).round, 2, ult1_pct >= 1.0 ? Color.new(244, 114, 182) : Color.new(56, 189, 248))
      end

      # P1 Species & Type
      sp1_name = PokemonSurvivor.format_name(e1[:species_name] || e1[:species], 6)
      t1_sym = e1[:type] || :NORMAL
      t1_col = PokemonSurvivor.type_color(t1_sym)
      target_bitmap.font.size = 9
      pbDrawTextPositions(target_bitmap, [
        ["#{sp1_name} [#{type_short(t1_sym)}]", p1_box_x + 2, ay + 33, 0, t1_col, Color.new(0, 0, 0, 220), :shadow]
      ])

      # --- RIGHT FIGHTER (P2) CORNER AVATAR + HUD ---
      p2_tier_col = case e2[:tier]
                    when 4 then Color.new(255, 215, 0)
                    when 3 then Color.new(245, 100, 220)
                    when 2 then Color.new(56, 189, 248)
                    else Color.new(234, 179, 8)
                    end
      av2_x = ax + aw - 14
      av2_y = ay + 28
      draw_circular_avatar(target_bitmap, e2[:pfp_path], av2_x, av2_y, 10, p2_tier_col, e2[:is_host], e2[:nickname])

      p2_box_x = ax + aw - 28 - 50
      target_bitmap.fill_rect(p2_box_x - 1, ay + 14, 52, 31, Color.new(0, 0, 0, 180))
      target_bitmap.fill_rect(p2_box_x, ay + 15, 50, 29, Color.new(15, 23, 42))

      p2_nick = PokemonSurvivor.format_name(e2[:nickname], 8)
      target_bitmap.font.size = 11
      pbDrawTextPositions(target_bitmap, [
        ["@#{p2_nick}", p2_box_x + 48, ay + 15, 1, Color.white, Color.new(0, 0, 0, 220), :shadow]
      ])

      # P2 HP Bar
      p2_bar_x = p2_box_x + 2
      target_bitmap.fill_rect(p2_bar_x - 1, bar_y - 1, bar_w + 2, bar_h + 2, Color.black)
      target_bitmap.fill_rect(p2_bar_x, bar_y, bar_w, bar_h, Color.new(30, 41, 59))
      hp2_pct = [[e2[:hp].to_f / [e2[:max_hp], 1].max, 0.0].max, 1.0].min
      fill2_w = (bar_w * hp2_pct).round
      hp2_col = hp2_pct > 0.5 ? Color.new(34, 215, 94) : (hp2_pct > 0.25 ? Color.new(250, 204, 21) : Color.new(239, 68, 68))
      target_bitmap.fill_rect(p2_bar_x + (bar_w - fill2_w), bar_y, fill2_w, bar_h, hp2_col)
      ult2_pct = [[(e2[:ult] || 0).to_f / 100.0, 0.0].max, 1.0].min
      if ult2_pct > 0
        u2_w = (bar_w * ult2_pct).round
        target_bitmap.fill_rect(p2_bar_x + (bar_w - u2_w), bar_y + bar_h + 1, u2_w, 2, ult2_pct >= 1.0 ? Color.new(244, 114, 182) : Color.new(56, 189, 248))
      end

      # P2 Species & Type
      sp2_name = PokemonSurvivor.format_name(e2[:species_name] || e2[:species], 6)
      t2_sym = e2[:type] || :NORMAL
      t2_col = PokemonSurvivor.type_color(t2_sym)
      target_bitmap.font.size = 9
      pbDrawTextPositions(target_bitmap, [
        ["#{sp2_name} [#{type_short(t2_sym)}]", p2_box_x + 48, ay + 33, 1, t2_col, Color.new(0, 0, 0, 220), :shadow]
      ])

      # Center VS marker
      target_bitmap.font.size = 11
      pbDrawTextPositions(target_bitmap, [
        ["VS", cx, ay + 21, 2, Color.new(250, 204, 21), Color.black, :outline]
      ])
    end

    def draw_arena_fighter_sprite(target_bitmap, entity, scale = 0.95)
      return unless entity
      x = entity[:x]
      y = entity[:y]
      hero_bmp = get_cached_hero(entity[:species])
      if hero_bmp && !hero_bmp.disposed?
        frame = (entity[:anim_frame] || 0) % 4
        dir = (entity[:facing] == 1) ? PokemonSurvivor::DIR_RIGHT : PokemonSurvivor::DIR_LEFT
        zoom = (entity[:is_host] ? 1.25 : 1.10) * (entity[:dynamax].to_i > 0 ? 1.5 : 1.0) * scale
        PokemonSurvivor.draw_character_centered(target_bitmap, hero_bmp, x, y, dir, frame, zoom)
      end
    end

    def draw_tournament_participant(target_bitmap, entity, scale = 1.0)
      return unless entity
      x = entity[:x]
      y = entity[:y]
      tier = entity[:tier] || 1
      is_host = entity[:is_host] || false
      dynamax = entity[:dynamax].to_i > 0

      # Formatted name and species (max 10 chars)
      nick = PokemonSurvivor.format_name(entity[:nickname], 10)
      sp_name = PokemonSurvivor.format_name(entity[:species_name] || entity[:species], 10)
      type_sym = entity[:type] || :NORMAL
      type_color = PokemonSurvivor.type_color(type_sym)

      # Tier Border Color
      border_color = case tier
                     when 4 then Color.new(255, 215, 0)   # Gold Champion
                     when 3 then Color.new(245, 100, 220) # Pink Shiny / Gift
                     when 2 then Color.new(56, 189, 248)  # Cyan Follow
                     else Color.new(234, 179, 8)          # Orange/Bronze Taps
                     end

      # -------------------------------------------------------------
      # LAYER 1: Medallion PFP / Aura
      # -------------------------------------------------------------
      medallion_y = y + (10 * scale).round
      medallion_rad = ((is_host ? 15 : 12) * scale).round
      draw_circular_avatar(target_bitmap, entity[:pfp_path], x, medallion_y, medallion_rad, border_color, is_host, nick)

      # -------------------------------------------------------------
      # LAYER 2: Animated Pokemon Sprite
      # -------------------------------------------------------------
      hero_bmp = get_cached_hero(entity[:species])
      if hero_bmp && !hero_bmp.disposed?
        frame = (entity[:anim_frame] || 0) % 4
        dir = (entity[:facing] == 1) ? PokemonSurvivor::DIR_RIGHT : PokemonSurvivor::DIR_LEFT
        zoom = (is_host ? 1.30 : 1.15) * (dynamax ? 1.5 : 1.0) * scale
        PokemonSurvivor.draw_character_centered(target_bitmap, hero_bmp, x, y - (10 * scale).round, dir, frame, zoom)
      end

      # -------------------------------------------------------------
      # LAYER 3: Top UI (@nickname with clear contrast)
      # -------------------------------------------------------------
      name_y = y - ((is_host ? 42 : 36) * scale).round
      target_bitmap.font.bold = true

      if is_host
        target_bitmap.font.size = 10
        pbDrawTextPositions(target_bitmap, [
          ["[CHAMPION]", x, name_y - 12, 2, Color.new(255, 215, 0), Color.black, :outline]
        ])
      end

      target_bitmap.font.size = is_host ? 12 : 11
      name_col = is_host ? Color.new(255, 245, 170) : Color.white
      pbDrawTextPositions(target_bitmap, [
        ["@#{nick}", x, name_y, 2, name_col, Color.black, :outline]
      ])

      # -------------------------------------------------------------
      # LAYER 4: Bottom UI (Dynamic HP Bar + Ultimate + Type Badge)
      # -------------------------------------------------------------
      bar_w = ((is_host ? 54 : 44) * scale).round
      bar_h = 5
      bar_x = x - bar_w / 2
      bar_y = y + (16 * scale).round

      # Backing
      target_bitmap.fill_rect(bar_x - 1, bar_y - 1, bar_w + 2, bar_h + 2, Color.black)
      target_bitmap.fill_rect(bar_x, bar_y, bar_w, bar_h, Color.new(30, 41, 59))

      # Health Fill
      hp_pct = [[entity[:hp].to_f / [entity[:max_hp], 1].max, 0.0].max, 1.0].min
      fill_w = (bar_w * hp_pct).round
      hp_col = hp_pct > 0.5 ? Color.new(34, 197, 94) : (hp_pct > 0.25 ? Color.new(234, 179, 8) : Color.new(239, 68, 68))
      target_bitmap.fill_rect(bar_x, bar_y, fill_w, bar_h, hp_col)

      # Ultimate Gauge
      ult_pct = [[(entity[:ult] || 0).to_f / 100.0, 0.0].max, 1.0].min
      if ult_pct > 0
        ult_w = (bar_w * ult_pct).round
        ult_col = ult_pct >= 1.0 ? Color.new(236, 72, 153) : Color.new(56, 189, 248)
        target_bitmap.fill_rect(bar_x, bar_y + bar_h + 1, ult_w, 2, ult_col)
      end

      # Pokemon Species and Distinctive Elemental Type Badge
      target_bitmap.font.size = 10
      target_bitmap.font.bold = true
      badge_text = "#{sp_name} [#{type_sym}]"
      pbDrawTextPositions(target_bitmap, [
        [badge_text, x, bar_y + bar_h + 3, 2, type_color, Color.black, :outline]
      ])
    end

    # -------------------------------------------------------------------------
    # BRACKET TREE CARD RENDERER (HD Arial Vector, High Contrast & Neon Types)
    # -------------------------------------------------------------------------
    def draw_bracket_slot(target_bitmap, x, y, player, active = false, status = nil, slot_w = 152, slot_h = 36)
      target_bitmap.font.name = ["Arial", "Segoe UI"]
      target_bitmap.font.bold = true

      if player
        is_host = player[:is_host]
        border_col = if status == :eliminated
                       Color.new(239, 68, 68)     # Bright Red
                     elsif status == :winner
                       Color.new(34, 197, 94)     # Bright Neon Emerald
                     elsif is_host
                       Color.new(255, 215, 0)     # Championship Gold
                     elsif active
                       Color.new(251, 191, 36)    # Radiant Yellow
                     else
                       Color.new(56, 189, 248)    # Cyan
                     end

        bg_col = if status == :eliminated
                   Color.new(24, 16, 22)
                 elsif status == :winner
                   Color.new(16, 36, 24)
                 elsif is_host
                   Color.new(42, 30, 14)
                 else
                   Color.new(15, 23, 42)
                 end

        # Solid background box
        target_bitmap.fill_rect(x, y, slot_w, slot_h, bg_col)
        # 2px solid border
        target_bitmap.fill_rect(x, y, slot_w, 2, border_col)
        target_bitmap.fill_rect(x, y + slot_h - 2, slot_w, 2, border_col)
        target_bitmap.fill_rect(x, y, 2, slot_h, border_col)
        target_bitmap.fill_rect(x + slot_w - 2, y, 2, slot_h, border_col)

        # Circular Avatar Medallion (Left element)
        av_x = (slot_h >= 34) ? (x + 14) : (x + 11)
        av_y = y + (slot_h / 2.0).round
        av_rad = (slot_h >= 44) ? 13 : ((slot_h >= 34) ? 10 : 8)
        draw_circular_avatar(target_bitmap, player[:pfp_path], av_x, av_y, av_rad, border_col, is_host, player[:nickname])

        # Mini Pokemon Icon (Standing beside avatar)
        hero_bmp = get_cached_hero(player[:species])
        if hero_bmp && !hero_bmp.disposed?
          icon_x = (slot_h >= 34) ? (x + 36) : (x + 28)
          icon_y = y + (slot_h / 2.0).round
          icon_zoom = (slot_h >= 44) ? 1.15 : ((slot_h >= 34) ? 0.95 : 0.75)
          PokemonSurvivor.draw_character_centered(target_bitmap, hero_bmp, icon_x, icon_y, PokemonSurvivor::DIR_DOWN, 0, icon_zoom)
        end

        text_offset_x = (slot_h >= 34) ? 52 : 40
        max_name_len = (slot_w >= 140) ? 11 : ((slot_w >= 100) ? 9 : 7)
        nick = PokemonSurvivor.format_name(player[:nickname], max_name_len)
        sp = PokemonSurvivor.format_name(player[:species_name] || player[:species], 8)
        t_sym = player[:type] || :NORMAL
        type_col = PokemonSurvivor.type_color(t_sym)

        # Nickname: size 15 for giant GF cards, 13 for standard cards, 11 for compact
        nick_font_size = (slot_h >= 44) ? 15 : ((slot_h >= 32) ? 13 : 11)
        target_bitmap.font.size = nick_font_size
        nick_col = if status == :eliminated
                     Color.new(148, 163, 184)
                   elsif is_host
                     Color.new(255, 230, 80)
                   else
                     Color.white
                   end

        nick_y = (slot_h >= 44) ? (y + 5) : ((slot_h >= 32) ? (y + 2) : y)
        pbDrawTextPositions(target_bitmap, [
          ["@#{nick}", x + text_offset_x, nick_y, 0, nick_col, Color.new(0, 0, 0, 220), :shadow]
        ])

        # Species & Type: size 12 for standard, 13 for giant GF cards
        sp_font_size = (slot_h >= 44) ? 13 : ((slot_h >= 32) ? 11 : 9)
        target_bitmap.font.size = sp_font_size
        sp_y = (slot_h >= 44) ? (y + 24) : ((slot_h >= 32) ? (y + 18) : (y + 13))
        
        # Pokemon Species in clean bright white, followed by distinctive type badge
        if slot_w >= 120
          pbDrawTextPositions(target_bitmap, [
            ["#{sp} ", x + text_offset_x, sp_y, 0, Color.white, Color.new(0, 0, 0, 220), :shadow]
          ])
          sp_w = target_bitmap.text_size("#{sp} ").width
          pbDrawTextPositions(target_bitmap, [
            ["[#{type_short(t_sym)}]", x + text_offset_x + sp_w, sp_y, 0, type_col, Color.new(0, 0, 0, 220), :shadow]
          ])
        else
          pbDrawTextPositions(target_bitmap, [
            ["#{sp}", x + text_offset_x, sp_y, 0, Color.white, Color.new(0, 0, 0, 220), :shadow]
          ])
        end

        # Status Tag: Bold Pill at Right Side
        if status == :winner
          tag_x = x + slot_w - ((slot_w >= 120) ? 24 : 18)
          tag_y = y + ((slot_h - 16) / 2.0).round
          target_bitmap.font.size = (slot_h >= 32) ? 13 : 10
          pbDrawTextPositions(target_bitmap, [
            ["[W]", tag_x, tag_y, 0, Color.new(34, 197, 94), Color.black, :shadow]
          ])
        elsif status == :eliminated
          tag_x = x + slot_w - ((slot_w >= 120) ? 24 : 18)
          tag_y = y + ((slot_h - 16) / 2.0).round
          target_bitmap.font.size = (slot_h >= 32) ? 13 : 10
          pbDrawTextPositions(target_bitmap, [
            ["[X]", tag_x, tag_y, 0, Color.new(239, 68, 68), Color.black, :shadow]
          ])
        end
      else
        # Empty / Undecided Slot ([TBD])
        target_bitmap.fill_rect(x, y, slot_w, slot_h, Color.new(11, 17, 28))
        target_bitmap.fill_rect(x, y, slot_w, 1, Color.new(51, 65, 85))
        target_bitmap.fill_rect(x, y + slot_h - 1, slot_w, 1, Color.new(51, 65, 85))
        target_bitmap.fill_rect(x, y, 1, slot_h, Color.new(51, 65, 85))
        target_bitmap.fill_rect(x + slot_w - 2, y, 1, slot_h, Color.new(51, 65, 85))
        target_bitmap.font.size = (slot_h >= 32) ? 13 : 10
        target_bitmap.font.bold = true
        tbd_y = y + ((slot_h - 16) / 2.0).round
        pbDrawTextPositions(target_bitmap, [
          ["[ TBD ]", x + slot_w / 2, tbd_y, 2, Color.new(100, 116, 139), Color.black, :none]
        ])
      end
    end
  end
end
