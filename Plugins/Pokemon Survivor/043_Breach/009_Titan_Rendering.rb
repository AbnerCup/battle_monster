module SurvivorTitanRendering
  def titan_leaderboard_scroll(index, first, count)
    visible = leaderboard_visible_rows
    first = index if index < first
    first = index - visible + 1 if index >= first + visible
    [[first, 0].max, [count - visible, 0].max].min
  end

  def draw_titan_leaderboard(rows, index, first)
    bitmap, overlay = @sprites["screen"].bitmap, @sprites["overlay"].bitmap
    bitmap.clear
    overlay.clear
    pbSetSystemFont(bitmap)
    draw_select_background(bitmap)
    x, y, w, h = 18, 38, Graphics.width - 36, Graphics.height - 72
    blue, shadow = Color.new(92, 188, 255), Color.new(32, 32, 40)
    draw_panel(bitmap, x, y, w, h, blue, Color.new(18, 29, 50))
    draw_hud_header_strip(bitmap, x + 16, y + 14, w - 32, 34, blue, Color.new(8, 13, 26))
    title = _INTL("Leaderboard - Titan - Season {1}", @titan_store.season_id)
    draw_leaderboard_cell(bitmap, title, x + 16, y + 22, w - 32, 22, blue, shadow, 2)
    visible = leaderboard_visible_rows
    list_x, header_y, list_y = x + 10, y + 62, y + 94
    scroll_w = rows.length > visible ? 10 : 0
    inner_w = w - 38 - scroll_w
    rank_x, rank_w, gap = list_x + 8, 56, 8
    player_x = rank_x + rank_w + gap
    player_w = ((inner_w - rank_w - gap * 2) * 0.52).floor
    damage_x, damage_w = player_x + player_w + gap, inner_w - rank_w - player_w - gap * 2
    header_color = Color.new(122, 255, 176)
    draw_leaderboard_cell(bitmap, _INTL("Rank"), rank_x, header_y, rank_w, 20, header_color, shadow, 0)
    draw_leaderboard_cell(bitmap, _INTL("Player"), player_x, header_y, player_w, 20, header_color, shadow, 0)
    draw_leaderboard_cell(bitmap, _INTL("Total Damage"), damage_x, header_y, damage_w, 20, Color.new(255, 224, 92), shadow, 2)
    draw_leaderboard_header_rule(bitmap, rank_x, header_y + 24, inner_w)
    (rows[first, visible] || []).each_with_index do |row, offset|
      row_index, row_y = first + offset, list_y + offset * 26
      selected = row_index == index
      fill = selected ? Color.new(32, 58, 92, 210) :
        (row_index.even? ? Color.new(8, 13, 26, 190) : Color.new(18, 29, 50, 190))
      bitmap.fill_rect(list_x, row_y, w - 22 - scroll_w, 21, fill)
      bitmap.fill_rect(list_x + 2, row_y, w - 26 - scroll_w, 1, Color.new(92, 188, 255, selected ? 168 : 78))
      rank = row[:rank].to_i > 0 ? row[:rank].to_i : row_index + 1
      draw_leaderboard_rank_cell(bitmap, rank, rank_x, row_y + 2, rank_w, 18)
      draw_leaderboard_cell(bitmap, row[:player].to_s, player_x, row_y + 2, player_w, 18,
        leaderboard_player_color(row[:player]), shadow, 0)
      draw_leaderboard_numeric_cell(bitmap, row[:damage_text], damage_x, row_y + 2, damage_w, 18,
        Color.new(255, 224, 92), shadow)
    end
    if rows.empty?
      draw_leaderboard_cell(bitmap, _INTL("No contributions yet."), list_x, list_y + 52, w - 20, 22, Color.white, shadow, 2)
    elsif rows.length > visible
      draw_leaderboard_scrollbar(bitmap, x + w - 22, list_y, 7, visible * 26 - 3, first, visible, rows.length)
    end
    draw_leaderboard_cell(bitmap, _INTL("Community damage"), x + 16, y + h - 32, w - 32, 22,
      Color.new(198, 214, 236), shadow, 2)
    draw_help(overlay, [[:up, ""], [:down, _INTL("Scroll")], [:confirm, _INTL("Back")], [:cancel, _INTL("Back")]])
    draw_tv_filter(overlay)
  end

  def world_screen_x(x)
    super(x - (titan_mode? ? @titan_camera_x.to_f : 0.0))
  end

  def world_screen_y(y)
    super(y - (titan_mode? ? @titan_camera_y.to_f : 0.0))
  end

  def draw_world_background(bitmap)
    super
    draw_titan_arena_walls(bitmap) if titan_mode? && @titan_arena
    draw_tower_wisps(bitmap) if titan_mode?
    draw_titan_pattern_warnings(bitmap) if titan_mode?
  end

  def draw_titan_arena_walls(bitmap)
    left, right, top, bottom = @titan_arena[:bounds]
    visibility = [left, right, top, bottom].each_with_index.map do |bound, index|
      position = index < 2 ? @world_x.to_f : @world_y.to_f
      world_wall_visibility(index.even? ? position - bound : bound - position)
    end
    ox, oy = Graphics.width / 2.0 - @world_x.to_f, Graphics.height / 2.0 - @world_y.to_f
    left, right = world_screen_x(left + ox).round, world_screen_x(right + ox).round
    top, bottom = world_screen_y(top + oy).round, world_screen_y(bottom + oy).round
    pulse = 150 + (Math.sin(@timer.to_f * 3) * 35).round
    # Clip long strips to the screen; no map-sized temporary bitmap is needed.
    [[left - 3, top, 6, bottom - top], [right - 3, top, 6, bottom - top],
     [left, top - 3, right - left, 6], [left, bottom - 3, right - left, 6]].each_with_index do |strip, index|
      fade = visibility[index]
      next if fade <= 0.0
      color = Color.new(112, 154, 255, (pulse * fade).round)
      light = Color.new(218, 232, 255, (220 * fade).round)
      x, y, w, h = strip
      x2, y2 = [x + w, bitmap.width].min, [y + h, bitmap.height].min
      x, y = [x, 0].max, [y, 0].max
      next if x2 <= x || y2 <= y
      draw_world_wall_rect(bitmap, x, y, x2 - x, y2 - y, color)
      if w == 6
        draw_world_wall_rect(bitmap, x + (x2 - x) / 2, y, 1, y2 - y, light)
      else
        draw_world_wall_rect(bitmap, x, y + (y2 - y) / 2, x2 - x, 1, light)
      end
    end
  end

  def draw_special_enemy_edge_indicators(bitmap)
    super
    draw_tower_objective_edge_indicators(bitmap) if titan_mode?
  end

  def draw_enemy(bitmap, enemy)
    if titan_mode? && enemy.equal?(@titan_boss) && @titan_leap && @titan_leap[:phase] == :airborne
      progress = [@titan_leap[:elapsed] / 0.65, 1.0].min
      height = Math.sin(progress * Math::PI) * 80.0
      PokemonSurvivor.draw_character_centered(bitmap, enemy.bitmap, world_screen_x(enemy.x),
        world_screen_y(enemy.y - height), enemy.direction, character_frame(enemy, enemy.bitmap), world_screen_zoom(2.7), 8)
      return
    end
    return super unless titan_mode? && enemy.equal?(@titan_boss) && @titan_cinematic
    scene = @titan_cinematic
    shoot = scene[:phase] == :shoot
    sheet = shoot ? @titan_shoot_bitmap : enemy.bitmap
    frame = shoot ? [(scene[:elapsed] * 12).floor, titan_shoot_frames - 1].min : character_frame(enemy, sheet)
    PokemonSurvivor.draw_character_centered(bitmap, sheet, world_screen_x(enemy.x), world_screen_y(enemy.y),
      enemy.direction, frame, world_screen_zoom(2.7), 8)
    if scene[:phase] == :evolve
      draw_vfx_frame(bitmap, "VFX_EVOLUTION", world_screen_x(enemy.x), world_screen_y(enemy.y),
        world_screen_zoom(1.5), 255, nil, [(scene[:elapsed] / 1.3 * 16).floor, 15].min)
    end
  end

  def draw_projectile(bitmap, projectile)
    return super unless projectile.instance_variable_get(:@titan_projectile)
    if projectile.instance_variable_get(:@titan_rupture)
      opacity = [[(projectile.ttl / 0.35 * 255).round, 0].max, 255].min
      draw_titan_rupture_zone(bitmap, projectile.x, projectile.y, opacity, true)
      return
    end
    name = projectile.vfx_name
    if projectile_8dir_vfx?(name)
      return if draw_projectile_8dir_vfx(bitmap, name, world_screen_x(projectile.x),
        world_screen_y(projectile.y), projectile)
    end
    if projectile.instance_variable_get(:@titan_hunting_tornado)
      warning = projectile.age.to_f < 1.0
      opacity = warning ? (100 + 70 * Math.sin(projectile.age.to_f * 18)).round : 255
      draw_vfx_frame(bitmap, name, world_screen_x(projectile.x), world_screen_y(projectile.y),
        world_screen_zoom(projectile.vfx_scale), opacity, nil, (projectile.age.to_f * 12).floor % 52)
      return
    end
    sheet = cached_enemy_projectile_vfx_bitmap(name)
    return super unless sheet && !sheet.disposed?
    frames = vfx_frame_count(name)
    width = sheet.width / frames
    frame = (@timer * 12).floor % frames
    angle = Math.atan2(projectile.vy, projectile.vx) * 180.0 / Math::PI
    image = rotated_enemy_projectile_vfx_frame_bitmap(name, sheet, frame, width, sheet.height, angle)
    scale = world_screen_zoom(projectile.vfx_scale || 2.0)
    w, h = (image.width * scale).round, (image.height * scale).round
    x, y = world_screen_x(projectile.x), world_screen_y(projectile.y)
    bitmap.stretch_blt(Rect.new((x - w / 2).round, (y - h / 2).round, w, h), image,
      Rect.new(0, 0, image.width, image.height))
  end

  def draw_titan_pattern_warnings(bitmap)
    if @titan_leap
      draw_titan_rupture_zone(bitmap, @titan_leap[:to_x] - @world_x.to_f,
        @titan_leap[:to_y] - @world_y.to_f, 210, false, 48)
    end
    (@titan_pattern_warnings || []).each do |warning|
      pulse = (170 + 65 * Math.sin(warning[:elapsed] * 12)).round
      if warning[:kind] == :rupture
        draw_titan_rupture_zone(bitmap, warning[:x] - @world_x.to_f, warning[:y] - @world_y.to_f, pulse)
      elsif warning[:kind] == :closing_ring
        titan_closing_ring_points(warning) do |x, y, angle|
          draw_vfx_frame(bitmap, PokemonSurvivor::Titan.season(@titan_session[:season_id])[:projectile][:vfx], world_screen_x(x), world_screen_y(y),
            world_screen_zoom(2.0), pulse, angle * 180.0 / Math::PI, 0)
        end
      else
        titan_pincer_points(warning) do |x, y, _angle|
          draw_vfx_frame(bitmap, PokemonSurvivor::Titan.season(@titan_session[:season_id])[:projectile][:vfx], world_screen_x(x), world_screen_y(y),
            world_screen_zoom(2.0), pulse, nil, 0)
        end
      end
    end
  end

  def draw_titan_rupture_zone(bitmap, x, y, opacity, active = false, radius = 140)
    key = "__titan_rupture_#{active}_#{PokemonSurvivor.color_accessibility_mode}"
    zone = @bitmaps[key]
    unless zone && !zone.disposed?
      zone = @bitmaps[key] = Bitmap.new(280, 280)
      ring = PokemonSurvivor.accessible_color(Color.new(245, 160, 255, 240))
      fill = PokemonSurvivor.accessible_color(Color.new(190, 85, 235, active ? 130 : 32))
      # Cache the disk once; avoid rebuilding a large bitmap each frame.
      280.times do |row|
        dy = row - 139.5
        extent = Math.sqrt([140.0**2 - dy**2, 0.0].max)
        left, right = (140 - extent).ceil, (140 + extent).floor
        zone.fill_rect(left, row, right - left, 1, ring)
        if dy.abs < 137
          inner = Math.sqrt(137.0**2 - dy**2)
          zone.fill_rect((140 - inner).ceil, row, (inner * 2).floor, 1, fill)
        end
      end
    end
    size = world_screen_zoom(radius * 2).round
    bitmap.stretch_blt(Rect.new((world_screen_x(x) - size / 2.0).round,
      (world_screen_y(y) - size / 2.0).round, size, size), zone, Rect.new(0, 0, 280, 280), opacity)
  end

  def enemy_sprite_tint(enemy)
    if titan_mode? && enemy.equal?(@titan_boss) && @titan_charge && @titan_charge[:phase] == :warning
      return Color.new(255, 48, 60)
    end
    if titan_mode? && enemy.equal?(@titan_boss) && @titan_leap && @titan_leap[:phase] == :warning
      return Color.new(255, 48, 60)
    end
    super
  end

  def enemy_tint_strength(enemy)
    if titan_mode? && enemy.equal?(@titan_boss) && @titan_charge && @titan_charge[:phase] == :warning
      return 0.7 + Math.sin(@titan_charge[:elapsed] * 18.0) * 0.15
    end
    if titan_mode? && enemy.equal?(@titan_boss) && @titan_leap && @titan_leap[:phase] == :warning
      return 0.65 + Math.sin(@titan_leap[:elapsed] * 14.0) * 0.15
    end
    super
  end

  def show_run_objective_popup?
    titan_mode? ? false : super
  end

  def titan_damage_percent(damage)
    total = @titan_session && @titan_session[:total_hp].to_f
    return "0%" unless total && total > 0
    value = [[damage.to_f / total * 100.0, 0.0].max, 100.0].min
    return "<0.0001%" if value > 0 && value < 0.0001
    "#{format('%.4f', value).sub(/0+$/, '').sub(/\.$/, '')}%"
  end

  def draw_titan_hud_objective(bitmap)
    x, w = 300, Graphics.width - 318
    time = @timer.to_i
    clock = _INTL("{1}:{2}", (time / 60).to_s.rjust(2, "0"), (time % 60).to_s.rjust(2, "0"))
    old_size = bitmap.font.size
    if @titan_boss
      ledger = @titan_boss.titan_ledger
      title = _INTL("{1} - Phase {2}", PokemonSurvivor.species_name(@titan_boss.name), @titan_final ? 2 : 1)
      clock_w = [bitmap.text_size(clock).width + 4, w].min
      # Center the 24px text row, 2px gap and 10px gauge inside the y=8, h=56 HUD.
      text_y = 18
      gauge_y = text_y + 26
      titan_hud_text(bitmap, title, x, text_y, w - clock_w - 8, Color.white, false)
      titan_hud_text(bitmap, clock, x + w - clock_w, text_y, clock_w, Color.new(255, 224, 92))
      draw_status_bar(bitmap, x, gauge_y, w, 10,
        ledger.hp.to_f / @titan_session[:total_hp], Color.new(218, 100, 164))
      if ledger.shield > 0
        draw_status_bar(bitmap, x, gauge_y, w, 5,
          ledger.shield.to_f / @titan_shield_total, Color.new(78, 172, 255))
      end
    else
      remaining = [300 - @timer.to_i, 0].max
      count = PokemonSurvivor::Titan::SEAL_COUNT - (@tower_wisps || []).count { |seal| seal.hp > 0 }
      titan_hud_text(bitmap, _INTL("Seals {1}/8", count), x, 10, w, Color.white)
      label = _INTL("Titan in {1}:{2}", remaining / 60, (remaining % 60).to_s.rjust(2, "0"))
      titan_hud_text(bitmap, label, x, 36, w, Color.new(255, 224, 92))
    end
  ensure
    bitmap.font.size = old_size if old_size
  end

  def titan_hud_text(bitmap, text, x, y, width, color, right = true)
    fitted = ellipsize_text(bitmap, text, width)
    pbDrawTextPositions(bitmap, [[fitted, right ? x + width : x, y, right ? 1 : false,
      color, Color.new(35, 35, 42)]])
  end

  def draw_breach_shard_balance(bitmap)
    return super unless @titan_preparing
    draw_soft_badge(bitmap, 28, 6, Graphics.width - 56, 30, Color.new(0, 0, 0, 180))
    draw_text_box_ellipsis(bitmap, _INTL("Titan preparation - {1}/6", @titan_build_step.to_i),
      38, 10, Graphics.width - 76, 22, Color.white, Color.new(35, 35, 42), 2)
  end

  def seasonal_run_result_data
    return nil unless titan_mode? || breach_mode?
    seconds = @timer.to_i
    time = _INTL("{1}:{2}", (seconds / 60).to_s.rjust(2, "0"), (seconds % 60).to_s.rjust(2, "0"))
    stats = [[_INTL("Level"), @level], [_INTL("KOs"), @kills], [_INTL("Time"), time]]
    if titan_mode?
      receipt = @titan_receipt || { damage: 0, ores: 0 }
      damage = @titan_result_damage || receipt[:damage]
      stats[1] = [_INTL("Total"), titan_damage_percent(damage)]
      { title: @result_text || _INTL("Titan run ended"), classic_layout: true,
        primary: _INTL("Damage: {1}", damage.to_i.to_s.reverse.scan(/.{1,3}/).join(".").reverse),
        stats: stats,
        rewards: @titan_receipt ? _INTL("Ores: {1}", receipt[:ores]) : _INTL("Result saved - awaiting connection"),
        actions: [_INTL("Return to Titan")], index: 0 }
    else
      loot = @breach_final_loot || { candies: 0, fragments: 0 }
      stats += [[_INTL("Rooms"), @breach_rooms], [_INTL("Threat"), breach_total_threat],
        [_INTL("Modules"), (@breach_modules || []).length]]
      { title: @result_text || _INTL("Breach ended"), primary: _INTL("Score {1}", @score.to_i),
        subtitle: _INTL("Breach - Season {1}", @breach_season[:id]), stats: stats,
        rewards: _INTL("{1} Candies + {2} Fragments", loot[:candies], loot[:fragments]),
        actions: [_INTL("Rewards"), @leaderboard_submitted ? _INTL("Sent") : _INTL("Send score"), _INTL("Return")],
        index: @breach_result_index.to_i }
    end
  end

  def titan_milestone_scroll_target(index, width, count)
    total = count * 142 - 14 + 44
    [[22 + index * 142 - (width - 128) / 2, 0].max, [total - width, 0].max].min
  end

  def draw_titan_milestones(data, index, surface, scroll)
    bitmap, overlay = @sprites["screen"].bitmap, @sprites["overlay"].bitmap
    overlay.clear
    draw_battle_pass_reward_background(bitmap)
    entries = PokemonSurvivor::Titan::MILESTONES
    gold, shadow = Color.new(255, 214, 92), Color.new(32, 32, 40)
    white, dark = Color.new(232, 238, 248), Color.new(18, 24, 42, 245)
    ratio = [[(data[:total_hp] - data[:hp]).to_f / [data[:total_hp], 1].max, 0.0].max, 1.0].min
    draw_battle_pass_flat_panel(bitmap, 8, 8, Graphics.width - 16, 52, dark, Color.new(28, 38, 64, 245))
    icon = cached_bitmap(PokemonSurvivor::SHOP_DIR, PokemonSurvivor::Titan::CRYSTAL_ICON)
    if icon && !icon.disposed?
      scale = [32.0 / icon.width, 32.0 / icon.height, 1.0].min
      iw, ih = (icon.width * scale).round, (icon.height * scale).round
      bitmap.stretch_blt(Rect.new(18 + (32 - iw) / 2, 18 + (32 - ih) / 2, iw, ih), icon, Rect.new(0, 0, icon.width, icon.height))
    end
    title_w = Graphics.width - 238
    draw_battle_pass_scrolling_text(bitmap, _INTL("Boss Milestones"), 58, 13, title_w, 24, gold, shadow)
    draw_battle_pass_gauge(bitmap, 58, 44, title_w - 8, 10, ratio, Color.new(80, 190, 255), gold)
    draw_battle_pass_scrolling_text(bitmap, _INTL("Claimed {1}/{2}", data[:claimed].length, entries.length),
      Graphics.width - 176, 12, 158, 20, Color.new(92, 188, 255), shadow, 2)
    remaining_hp = data[:total_hp].to_i > 0 ? [[data[:hp].to_f / data[:total_hp], 0.0].max, 1.0].min : 0.0
    draw_battle_pass_scrolling_text(bitmap, _INTL("Boss HP: {1}%", sprintf("%.2f", remaining_hp * 100)),
      Graphics.width - 176, 34, 158, 20, Color.new(92, 232, 148), shadow, 2)

    # Match the Battle Pass's full-width track and leave room at both ends.
    surface.clear
    entries.each_with_index do |entry, i|
      x = 22 + i * 142 - scroll.round
      next if x + 128 <= 0 || x >= surface.width
      claimed = data[:claimed].include?(i)
      ready = (data[:total_hp] - data[:hp]) * 100 >= data[:total_hp] * entry[:percent]
      reward = { tier: i + 1, amount: entry[:crystals], shop_icon: PokemonSurvivor::Titan::CRYSTAL_ICON }
      presentation = { ready: ready, claimed: claimed, tier_label: _INTL("{1}% HP", entry[:percent]) }
      lifted = i == index && (Graphics.frame_count / 24).even?
      draw_battle_pass_reward_slot(surface, x, lifted ? 0 : 2, 128, 204, reward, i == index, presentation)
    end
    bitmap.blt(0, 68, surface, Rect.new(0, 0, surface.width, surface.height))
    total = entries.length * 142 - 14 + 44
    if total > surface.width
      track_w = surface.width - 32
      thumb = [(track_w * surface.width.to_f / total).round, 28].max
      thumb_x = 16 + ((track_w - thumb) * scroll / (total - surface.width)).round
      draw_battle_pass_horizontal_scrollbar(bitmap, 16, 277, track_w, 7, thumb_x, thumb)
    end
    entry = entries[index]
    draw_battle_pass_flat_panel(bitmap, 8, 290, Graphics.width - 16, 56, dark, Color.new(30, 42, 66))
    draw_battle_pass_scrolling_text(bitmap, _INTL("Reduce the Titan's total HP by {1}%.", entry[:percent]),
      20, 294, Graphics.width - 40, 22, white, shadow)
    draw_battle_pass_scrolling_text(bitmap, _INTL("Gain {1} Crystal Shards", entry[:crystals]),
      20, 320, Graphics.width - 40, 22, gold, shadow)
    draw_help(overlay, [[:left, ""], [:right, _INTL("Rewards")], [:confirm, _INTL("Claim Reward")],
      [:action, _INTL("Auto Claim")], [:cancel, _INTL("Back")]])
    draw_tv_filter(overlay)
  end

  def titan_currency_strip(bitmap, data)
    width = (Graphics.width - 64) / 2
    [[PokemonSurvivor::Titan::ORE_ICON, data[:ores]],
     [PokemonSurvivor::Titan::CRYSTAL_ICON, data[:crystals]]].each_with_index do |entry, index|
      x = 28 + index * (width + 8)
      draw_soft_badge(bitmap, x, 65, width, 32, Color.new(0, 0, 0, 190))
      icon = cached_bitmap("Graphics/UI/Survivor Game/Menu HUD/Shop", entry[0])
      text_x = x + 10
      if icon && !icon.disposed?
        scale = [28.0 / icon.width, 28.0 / icon.height, 1.0].min
        iw, ih = (icon.width * scale).round, (icon.height * scale).round
        bitmap.stretch_blt(Rect.new(text_x, 65 + (32 - ih) / 2, iw, ih), icon,
          Rect.new(0, 0, icon.width, icon.height))
        text_x += iw + 8
      end
      draw_text_box_ellipsis(bitmap, entry[1].to_s, text_x, 70, x + width - text_x - 10, 22,
        Color.white, Color.new(30, 30, 36), 1)
    end
  end
end
