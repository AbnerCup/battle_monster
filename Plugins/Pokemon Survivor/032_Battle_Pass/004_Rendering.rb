#===============================================================================
# Pokemon Survivor - Battle Pass - HUD rendering
#===============================================================================
class Scene_PokemonSurvivor
  def draw_battle_pass_menu
    bmp = @sprites["screen"].bitmap
    over = @sprites["overlay"].bitmap
    over.clear
    bitmap = bmp
    draw_battle_pass_reward_background(bitmap)
    @battle_pass_scroll_x ||= 0.0
    @battle_pass_target_scroll_x ||= 0.0
    @battle_pass_scroll_x += (@battle_pass_target_scroll_x.to_f - @battle_pass_scroll_x.to_f) * 0.26
    w = [Graphics.width - 54, 586].min
    h = battle_pass_menu_height
    x = (Graphics.width - w) / 2
    y = [(Graphics.height - h) / 2 - 12, 8].max
    draw_panel(bitmap, x, y, w, h, Color.new(245, 198, 92), Color.new(18, 29, 50))
    draw_battle_pass_header(bitmap, x, y, w)
    pass_list_h = battle_pass_menu_list_height
    pass_list_y = y + 72
    draw_battle_pass_pass_cards(bitmap, x + 18, pass_list_y, w - 36, pass_list_h)
    draw_battle_pass_menu_hint(bitmap, x + 18, y + h - 40, w - 36, 28)
    draw_help(over, [[:up, ""], [:down, _INTL("Pass")], [:confirm, _INTL("Open")], [:cancel, _INTL("Back")]])
    draw_tv_filter(over)
  rescue
  end

  def draw_battle_pass_content
    bmp = @sprites["screen"].bitmap
    over = @sprites["overlay"].bitmap
    over.clear
    bitmap = bmp
    draw_battle_pass_reward_background(bitmap)
    @battle_pass_scroll_x ||= 0.0
    @battle_pass_target_scroll_x ||= 0.0
    @battle_pass_scroll_x += (@battle_pass_target_scroll_x.to_f - @battle_pass_scroll_x.to_f) * 0.24
    pass = selected_battle_pass
    draw_battle_pass_content_header(bitmap, pass)
    draw_battle_pass_reward_track(bitmap, 8, 70, Graphics.width - 16, 204)
    draw_battle_pass_details(bitmap, 8, 282, Graphics.width - 16, 70)
    draw_help(over, [[:left, ""], [:right, _INTL("Rewards")], [:confirm, _INTL("Claim Reward")], [:action, _INTL("Auto Claim")], [:menu, _INTL("Quests")], [:cancel, _INTL("Back")]])
    draw_tv_filter(over)
  rescue
  end

  def draw_battle_pass_quest_menu
    bmp = @sprites["screen"].bitmap
    over = @sprites["overlay"].bitmap
    over.clear
    bitmap = bmp
    draw_battle_pass_reward_background(bitmap)
    pass = selected_battle_pass
    draw_battle_pass_content_header(bitmap, pass)
    draw_battle_pass_quest_panel(bitmap, 12, 70, Graphics.width - 24, 220)
    draw_battle_pass_quest_details(bitmap, 12, 298, Graphics.width - 24, 54)
    draw_help(over, [[:up, ""], [:down, _INTL("Quests")], [:confirm, _INTL("Claim Quest")], [:action, _INTL("Auto Claim")], [:menu, _INTL("Rewards")], [:cancel, _INTL("Back")]])
    draw_tv_filter(over)
  rescue
  end

  def draw_battle_pass_bottom_quest_line(bitmap, x, y, w, h)
    pass = selected_battle_pass
    quests = PokemonSurvivor.battle_pass_quest_list(pass)
    quest = quests[@battle_pass_quest_index.to_i] || quests.first
    return if !pass || !quest
    progress = PokemonSurvivor.battle_pass_quest_progress(quest)
    target = [quest[:target].to_i, 1].max
    complete = progress >= target
    claimed = PokemonSurvivor.battle_pass_quest_claimed?(pass, quest)
    fill = claimed ? Color.new(24, 58, 42, 238) : (complete ? Color.new(56, 54, 34, 238) : Color.new(18, 26, 46, 238))
    edge = complete && !claimed ? Color.new(255, 214, 92, 255) : Color.new(72, 92, 132, 255)
    draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(6, 10, 20, 245))
    draw_pixel_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, fill)
    draw_text_box(bitmap, _INTL("Quest: {1}", _INTL(quest[:name].to_s)), x + 10, y + 1, w - 192, h, Color.new(222, 232, 248), Color.new(25, 25, 30), 0)
    draw_text_box(bitmap, _INTL("{1}/{2}", [progress, target].min, target), x + w - 180, y + 1, 86, h, edge, Color.new(25, 25, 30), 2)
    draw_text_box(bitmap, _INTL("+{1} XP", quest[:xp].to_i), x + w - 88, y + 1, 78, h, complete && !claimed ? Color.new(92, 232, 148) : Color.new(168, 174, 188), Color.new(25, 25, 30), 2)
  rescue
  end
  def draw_battle_pass_reward_background(bitmap)
    if respond_to?(:draw_options_scrolling_background)
      draw_options_scrolling_background(bitmap)
    else
      bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(12, 18, 32, 255))
    end
  rescue
    bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(12, 18, 32, 255))
  end
  def battle_pass_tome_icon(pass)
    number = pass && pass[:id].to_s[/\Abattle_pass_(\d+)\z/, 1]
    icon = cached_icon_bitmap("PASS#{number}") if number
    return icon if icon && !icon.disposed?
    cached_icon_bitmap("ICON_BATTLEPASS")
  end

  def draw_battle_pass_content_header(bitmap, pass)
    draw_battle_pass_flat_panel(bitmap, 8, 8, Graphics.width - 16, 52, Color.new(18, 24, 42, 245), Color.new(28, 38, 64, 245))
    pbSetSystemFont(bitmap)
    title = pass ? _INTL(pass[:name].to_s) : _INTL("Battle Pass")
    level = pass ? PokemonSurvivor.battle_pass_level(pass) : 1
    xp = pass ? PokemonSurvivor.battle_pass_xp_into_level(pass) : 0
    max_level = PokemonSurvivor::BATTLE_PASS_MAX_LEVEL.to_i
    xp_max = PokemonSurvivor::BATTLE_PASS_XP_PER_LEVEL.to_i
    icon = battle_pass_tome_icon(pass)
    title_x = 20
    if icon && !icon.disposed?
      bitmap.blt(18, 8 + ((52 - icon.height) / 2), icon, Rect.new(0, 0, icon.width, icon.height))
      title_x = 18 + icon.width + 8
    end
    title_w = [Graphics.width - 182 - title_x, 1].max
    draw_battle_pass_scrolling_text(bitmap, title, title_x, 13, title_w, 24, Color.new(255, 214, 92), Color.new(32, 32, 40), 0)
    draw_text_box(bitmap, _INTL("Pass Lv. {1}/{2}", level, max_level), Graphics.width - 176, 12, 158, 20, Color.new(92, 188, 255), Color.new(32, 32, 40), 2)
    exp_text = level >= max_level ? _INTL("EXP MAX") : _INTL("EXP {1}/{2}", xp, xp_max)
    draw_text_box(bitmap, exp_text, Graphics.width - 176, 32, 158, 20, Color.new(92, 232, 148), Color.new(32, 32, 40), 2)
    draw_battle_pass_xp_bar(bitmap, title_x, 44, [title_w - 12, 1].max, 10, pass)
  rescue
  end
  def draw_battle_pass_xp_bar(bitmap, x, y, w, h, pass)
    level = pass ? PokemonSurvivor.battle_pass_level(pass) : 1
    max_level = [PokemonSurvivor::BATTLE_PASS_MAX_LEVEL.to_i, 1].max
    xp_per_level = [PokemonSurvivor::BATTLE_PASS_XP_PER_LEVEL.to_i, 1].max
    xp = pass ? PokemonSurvivor.battle_pass_xp_into_level(pass) : 0
    raw = level >= max_level ? max_level.to_f : (level.to_i - 1).to_f + (xp.to_f / xp_per_level.to_f)
    ratio = [[raw / [max_level - 1, 1].max.to_f, 0.0].max, 1.0].min
    draw_battle_pass_gauge(bitmap, x, y, w, h, ratio, Color.new(80, 190, 255), Color.new(255, 214, 92))
  rescue
  end

  def draw_battle_pass_gauge(bitmap, x, y, w, h, ratio, fill_a, fill_b)
    ratio = [[ratio.to_f, 0.0].max, 1.0].min
    draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(3, 6, 13, 255))
    draw_pixel_round_rect(bitmap, x + 1, y + 1, w - 2, h - 2, Color.new(116, 152, 190, 255))
    draw_pixel_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, Color.new(18, 26, 46, 255))
    draw_pixel_round_rect(bitmap, x + 3, y + 3, w - 6, h - 6, Color.new(34, 44, 70, 255))
    inner_x = x + 4
    inner_y = y + 4
    inner_w = [w - 8, 1].max
    inner_h = [h - 8, 1].max
    fill_w = [(inner_w * ratio).round, 0].max
    return if fill_w <= 0
    fill_w.times do |i|
      t = i.to_f / [fill_w - 1, 1].max
      r = fill_a.red + ((fill_b.red - fill_a.red) * t).to_i
      g = fill_a.green + ((fill_b.green - fill_a.green) * t).to_i
      b = fill_a.blue + ((fill_b.blue - fill_a.blue) * t).to_i
      bitmap.fill_rect(inner_x + i, inner_y, 1, inner_h, Color.new(r, g, b, 255))
    end
    bitmap.fill_rect(inner_x + 1, inner_y, [fill_w - 2, 0].max, 2, Color.new(255, 255, 235, 150)) if fill_w > 3
    bitmap.fill_rect(inner_x + 1, inner_y + inner_h - 1, [fill_w - 2, 0].max, 1, Color.new(12, 22, 38, 130)) if fill_w > 3 && inner_h > 2
  rescue
  end
  def draw_battle_pass_flat_panel(bitmap, x, y, w, h, color1, color2 = nil)
    color2 ||= color1
    draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(4, 7, 14, color1.alpha))
    draw_pixel_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, color1)
    draw_pixel_round_rect(bitmap, x + 4, y + 4, w - 8, h - 8, color2)
  rescue
  end

  def draw_battle_pass_reward_track(bitmap, x, y, w, h)
    rewards = battle_pass_rewards_for_selected
    return if rewards.empty?
    @battle_pass_scroll_x ||= 0.0
    card_w = 128
    card_h = h
    gap = 14
    rewards.each_with_index do |reward, i|
      rx = x + gap + i * (card_w + gap) - @battle_pass_scroll_x.to_i
      next if rx + card_w < x || rx > x + w
      ry = y
      ry -= 2 if i == @battle_pass_reward_index.to_i && ((Graphics.frame_count rescue 0) / 24).even?
      draw_battle_pass_reward_slot(bitmap, rx, ry, card_w, card_h, reward, i == @battle_pass_reward_index.to_i)
    end
    draw_battle_pass_reward_scrollbar(bitmap, x + 8, y + h + 3, w - 16, 7, rewards.length, card_w, gap)
  rescue
  end

  def draw_battle_pass_reward_scrollbar(bitmap, x, y, w, h, count, card_w, gap)
    total = gap + count * (card_w + gap)
    return if total <= w
    h = [h.to_i, 7].max
    view_ratio = [w.to_f / total.to_f, 1.0].min
    thumb_w = [[(w * view_ratio).to_i, 28].max, w].min
    max_scroll = [total - w, 1].max
    thumb_x = x + ((w - thumb_w) * (@battle_pass_scroll_x.to_f / max_scroll.to_f)).to_i
    draw_battle_pass_horizontal_scrollbar(bitmap, x, y, w, h, thumb_x, thumb_w)
  rescue
  end

  def draw_battle_pass_horizontal_scrollbar(bitmap, x, y, w, h, thumb_x, thumb_w)
    bitmap.fill_rect(x, y, w, h, Color.new(3, 6, 13))
    bitmap.fill_rect(x + 1, y + 1, w - 2, h - 2, Color.new(34, 46, 68))
    bitmap.fill_rect(x + 2, y + 2, w - 4, h - 4, Color.new(8, 13, 26))
    bitmap.fill_rect(x + 2, y + 2, w - 4, 1, Color.new(66, 84, 118))
    tx = [[thumb_x.to_i, x + 1].max, x + w - thumb_w.to_i - 1].min
    tw = [[thumb_w.to_i, 12].max, w - 2].min
    ty = y + 1
    th = h - 2
    bitmap.fill_rect(tx, ty, tw, th, Color.new(122, 92, 42))
    bitmap.fill_rect(tx + 1, ty + 1, tw - 2, th - 2, Color.new(255, 198, 70))
    bitmap.fill_rect(tx + 2, ty + 2, 2, [th - 4, 1].max, Color.new(255, 238, 150))
    bitmap.fill_rect(tx + tw - 3, ty + 2, 1, [th - 4, 1].max, Color.new(164, 112, 42))
    bitmap.fill_rect(tx + 2, ty + th - 3, [tw - 4, 1].max, 1, Color.new(164, 112, 42))
  rescue
  end

  def draw_battle_pass_progress(bitmap, x, y, w, h, count)
    draw_battle_pass_xp_bar(bitmap, x, y, w, h, selected_battle_pass)
  rescue
  end

  def draw_battle_pass_menu_hint(bitmap, x, y, w, h)
    draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(6, 10, 20, 245))
    draw_pixel_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, Color.new(30, 42, 66, 245))
    pass = PokemonSurvivor::BATTLE_PASS_DATA[@battle_pass_index.to_i] || PokemonSurvivor::BATTLE_PASS_DATA.first
    text = PokemonSurvivor.battle_pass_unlocked?(pass[:id]) ? _INTL("Open this Battle Pass.") : _INTL("Unlock this Battle Pass to view its rewards.")
    line_h = 22
    line_y = y + ((h - line_h) / 2) - 1
    draw_text_box(bitmap, text, x + 12, line_y, w - 24, line_h, Color.new(222, 232, 248), Color.new(25, 25, 30), 2)
  rescue
  end
  def draw_battle_pass_header(bitmap, x, y, w)
    draw_pixel_round_rect(bitmap, x + 16, y + 12, w - 32, 34, Color.new(8, 13, 26, 238))
    icon = cached_icon_bitmap("ICON_BATTLEPASS") rescue nil
    ix = x + 26
    if icon && !icon.disposed?
      bitmap.blt(ix, y + 14 + ((30 - icon.height) / 2), icon, Rect.new(0, 0, icon.width, icon.height))
    end
    PokemonSurvivor.draw_text_center(bitmap, _INTL("Battle Pass"), x + 64, y + 20, w - 128, Color.new(255, 238, 160), Color.new(38, 32, 28))
    candy = cached_icon_bitmap("ICON_CANDY") rescue nil
    amount = PokemonSurvivor.candy_currency rescue 0
    if candy && !candy.disposed?
      cx = x + w - 128
      bitmap.blt(cx, y + 14 + ((30 - candy.height) / 2), candy, Rect.new(0, 0, candy.width, candy.height))
      amount_x = cx + candy.width + 4
      amount_w = [x + w - 24 - amount_x, 44].max
      draw_battle_pass_scrolling_text(bitmap, amount.to_i.to_s, amount_x, y + 20, amount_w, 18, Color.new(255, 238, 160), Color.new(38, 32, 28), 0)
    end
  rescue
  end

  def draw_battle_pass_pass_cards(bitmap, x, y, w, h)
    passes = PokemonSurvivor::BATTLE_PASS_DATA
    return if !passes || passes.empty?
    gap = 14
    card_h = 86
    total_h = passes.length * card_h + [passes.length - 1, 0].max * gap
    max_scroll = [total_h - h, 0].max
    @battle_pass_menu_target_scroll_y ||= 0.0
    @battle_pass_menu_scroll_y ||= @battle_pass_menu_target_scroll_y.to_f
    @battle_pass_menu_target_scroll_y = [[@battle_pass_menu_target_scroll_y.to_f, 0.0].max, max_scroll].min
    @battle_pass_menu_scroll_y += (@battle_pass_menu_target_scroll_y.to_f - @battle_pass_menu_scroll_y.to_f) * 0.34
    scroll_y = [[@battle_pass_menu_scroll_y.to_f, 0.0].max, max_scroll].min
    # Include the notification's overhang without changing card scroll coordinates.
    badge_margin = 3
    list = Bitmap.new([w - 16, 1].max, [h + badge_margin * 2, 1].max)
    begin
      # Keep the frame outside the clipped scrolling surface.
      draw_pixel_round_rect(bitmap, x - 2, y - 6, list.width + 4, h + 12, Color.new(6, 10, 20, 255))
      draw_pixel_round_rect(bitmap, x, y - 2, list.width, h + 4, Color.new(18, 29, 50, 255))
      list.fill_rect(0, 0, list.width, list.height, Color.new(18, 29, 50, 255))
      start_y = total_h <= h ? ((h - total_h) / 2) : -scroll_y.to_i
      passes.each_with_index do |pass, i|
        card_y = start_y + (i * (card_h + gap))
        next if card_y + card_h < 0 || card_y > h
        draw_battle_pass_pass_card(list, 10, card_y + badge_margin, list.width - 20, card_h, pass, @battle_pass_index.to_i == i)
      end
      bitmap.blt(x, y - badge_margin, list, Rect.new(0, 0, list.width, list.height))
    ensure
      list.dispose if list && !list.disposed?
    end
    draw_battle_pass_menu_scrollbar(bitmap, x + w - 10, y + 2, 6, h - 4, total_h, h, scroll_y) if total_h > h
  rescue
  end

  def draw_battle_pass_menu_scrollbar(bitmap, x, y, w, h, total_h, view_h, scroll_y)
    return if total_h.to_i <= view_h.to_i
    thumb_h = [[(h * view_h.to_f / total_h.to_f).to_i, 18].max, h].min
    max_scroll = [total_h.to_f - view_h.to_f, 1.0].max
    thumb_y = y + ((h - thumb_h) * (scroll_y.to_f / max_scroll)).to_i
    if respond_to?(:draw_select_scrollbar)
      draw_select_scrollbar(bitmap, x, y, w, h, thumb_y, thumb_h)
    else
      draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(4, 7, 14, 220))
      draw_pixel_round_rect(bitmap, x, thumb_y, w, thumb_h, Color.new(255, 198, 70, 245))
    end
  rescue
  end

  def draw_battle_pass_scrolling_text(bitmap, text, x, y, w, h, base = Color.white, shadow = Color.new(40, 40, 48), align = 0)
    w = w.to_i
    h = h.to_i
    return if w <= 0 || h <= 0
    pbSetSystemFont(bitmap)
    text = text.to_s
    text_w = bitmap.text_size(text).width rescue 0
    if text_w <= w
      draw_text_box(bitmap, text, x, y, w, h, base, shadow, align)
      return
    end
    @battle_pass_scroll_cache ||= {}
    key = [text, base.red, base.green, base.blue, shadow.red, shadow.green, shadow.blue, h].join(":")
    line = @battle_pass_scroll_cache[key]
    if !line || line.disposed?
      line = Bitmap.new([text_w + 28, 1].max, [h, 1].max)
      pbSetSystemFont(line)
      pbDrawTextPositions(line, [[text, 0, 0, false, base, shadow]])
      if @battle_pass_scroll_cache.length > 48
        old_key = @battle_pass_scroll_cache.keys.first
        old = @battle_pass_scroll_cache.delete(old_key)
        old.dispose if old && !old.disposed?
      end
      @battle_pass_scroll_cache[key] = line
    end
    max_offset = [line.width - w, 0].max
    cycle = [max_offset + 44, 1].max
    speed = 24.0
    raw = (((System.uptime rescue 0.0).to_f * speed).to_i % (cycle * 2))
    offset = raw <= cycle ? [raw, max_offset].min : [cycle * 2 - raw, max_offset].min
    bitmap.blt(x, y, line, Rect.new(offset, 0, w, h))
  rescue
    draw_text_box(bitmap, text.to_s, x, y, w, h, base, shadow, align) rescue nil
  end
  def draw_battle_pass_pass_card(bitmap, x, y, w, h, pass, selected)
    unlocked = PokemonSurvivor.battle_pass_unlocked?(pass[:id])
    completed = PokemonSurvivor.battle_pass_completed?(pass)
    edge = completed ? Color.new(92, 188, 255) : (unlocked ? Color.new(126, 255, 174) : Color.new(245, 198, 92))
    fill = completed ? Color.new(24, 48, 78) : (unlocked ? Color.new(24, 60, 46) : Color.new(58, 44, 32))
    shine = completed ? Color.new(150, 218, 255) : (unlocked ? Color.new(164, 255, 198) : Color.new(255, 224, 120))
    draw_modern_button_frame(bitmap, x, y, w, h, edge, fill, shine, selected)
    status = completed ? _INTL("Completed") : (unlocked ? _INTL("Unlocked") : _INTL("Locked"))
    status_color = completed ? Color.new(92, 188, 255) : (unlocked ? Color.new(126, 255, 174) : Color.new(255, 190, 96))
    icon = battle_pass_tome_icon(pass)
    text_x = x + 12
    if icon && !icon.disposed?
      bitmap.blt(text_x, y + ((h - icon.height) / 2), icon, Rect.new(0, 0, icon.width, icon.height))
      text_x += icon.width + 12
    end
    text_w = [x + w - 12 - text_x, 1].max
    half_w = [(text_w - 8) / 2, 1].max
    draw_battle_pass_scrolling_text(bitmap, _INTL(pass[:name].to_s), text_x, y + 10, text_w, 24, Color.new(255, 238, 160), Color.new(28, 28, 34), 0)
    draw_battle_pass_scrolling_text(bitmap, _INTL("Cost: {1}", pass[:cost].to_i), text_x, y + 38, half_w, 22, Color.new(222, 232, 248), Color.new(28, 28, 34), 0)
    draw_battle_pass_scrolling_text(bitmap, _INTL("Status: {1}", status), text_x + half_w + 8, y + 38, half_w, 22, status_color, Color.new(28, 28, 34), 2)
    draw_menu_notification(bitmap, x, y) if battle_pass_notification?(pass)
  rescue
  end
  def draw_battle_pass_reward_slot(bitmap, x, y, w, h, reward, selected, presentation = nil)
    if presentation
      pass_unlocked = true
      ready, claimed = presentation[:ready], presentation[:claimed]
    else
      pass = selected_battle_pass
      pass_unlocked = pass && PokemonSurvivor.battle_pass_unlocked?(pass[:id])
      ready = pass_unlocked && PokemonSurvivor.battle_pass_level(pass) >= reward[:tier].to_i
      claimed = pass_unlocked && PokemonSurvivor.battle_pass_reward_claimed?(pass, reward)
    end
    rarity = PokemonSurvivor::BATTLE_PASS_REWARD_RARITY_COLORS[reward[:rarity]] || Color.new(232, 238, 248)
    edge = selected ? Color.new(255, 214, 92) : (ready ? rarity : Color.new(52, 62, 86))
    fill = claimed ? Color.new(24, 58, 42, 245) : (pass_unlocked ? Color.new(28, 48, 78, 245) : Color.new(26, 28, 40, 245))
    draw_battle_pass_flat_panel(bitmap, x, y, w, h, edge, fill)

    tier_x = x + 12
    tier_y = y + 8
    tier_w = w - 24
    tier_h = 32
    draw_pixel_round_rect(bitmap, tier_x, tier_y, tier_w, tier_h, Color.new(4, 7, 14, 255))
    draw_pixel_round_rect(bitmap, tier_x + 2, tier_y + 2, tier_w - 4, tier_h - 4, ready ? Color.new(44, 98, 68, 255) : Color.new(42, 52, 76, 255))
    tier_label = presentation ? presentation[:tier_label] : _INTL("Tier {1}", reward[:tier].to_i)
    draw_battle_pass_scrolling_text(bitmap, tier_label, tier_x + 4, tier_y + 6, tier_w - 8, 22, Color.new(248, 248, 248), Color.new(32, 32, 40), 2)

    icon_x = x + 14
    icon_y = y + 48
    icon_w = w - 28
    icon_h = h - 96
    draw_pixel_round_rect(bitmap, icon_x, icon_y, icon_w, icon_h, Color.new(8, 13, 26, 255))
    draw_pixel_round_rect(bitmap, icon_x + 2, icon_y + 2, icon_w - 4, icon_h - 4, Color.new(36, 46, 70, 255))
    draw_battle_pass_reward_icon(bitmap, reward, icon_x, icon_y, icon_w, icon_h)

    status = claimed ? _INTL("Claimed") : (ready ? _INTL("Ready") : _INTL("Locked"))
    status_color = claimed ? Color.new(92, 188, 255) : (ready ? Color.new(92, 232, 148) : Color.new(236, 84, 84))
    status_x = x + 12
    status_y = y + h - 40
    status_w = w - 24
    status_h = 30
    draw_pixel_round_rect(bitmap, status_x, status_y, status_w, status_h, Color.new(8, 13, 26, 230))
    draw_text_box(bitmap, status, status_x + 4, status_y + 5, status_w - 8, 22, status_color, Color.new(32, 32, 40), 2)

    if selected
      pulse = 35 + (((Math.sin((System.uptime rescue 0.0) * 6.0) + 1.0) * 25).to_i rescue 0)
      sel = Color.new(255, 214, 92, 180 + pulse)
      bitmap.fill_rect(x + 4, y + 4, w - 8, 3, sel)
      bitmap.fill_rect(x + 4, y + h - 7, w - 8, 3, sel)
      bitmap.fill_rect(x + 4, y + 4, 3, h - 8, sel)
      bitmap.fill_rect(x + w - 7, y + 4, 3, h - 8, sel)
    end
    draw_menu_notification(bitmap, x, y) if ready && !claimed
  rescue
  end
  def draw_battle_pass_reward_icon(bitmap, reward, area_x, area_y, area_w, area_h)
    label_h = 28
    content_h = area_h - label_h
    if reward[:kind] == :equipment && respond_to?(:draw_equipment_item_icon)
      draw_equipment_item_icon(bitmap, reward[:icon].to_s, area_x + (area_w / 2), area_y + (content_h / 2), [content_h - 12, area_w - 18].min)
    else
      icon = nil
      icon = cached_bitmap(PokemonSurvivor::SHOP_DIR, reward[:shop_icon]) if reward[:shop_icon]
      if reward[:kind] == :hero && respond_to?(:cached_leaderboard_pokemon_icon)
        icon = cached_leaderboard_pokemon_icon(reward[:hero] || reward[:name]) rescue nil
      end
      icon = cached_icon_bitmap(reward[:icon].to_s) rescue nil if !icon || icon.disposed?
      if icon && !icon.disposed?
        max_icon_w = [area_w - 18, 56].min
        max_icon_h = [content_h - 16, 56].min
        scale = [max_icon_w.to_f / [icon.width, 1].max, max_icon_h.to_f / [icon.height, 1].max, 1.0].min
        draw_w = [(icon.width * scale).to_i, 1].max
        draw_h = [(icon.height * scale).to_i, 1].max
        ix = area_x + ((area_w - draw_w) / 2)
        iy = area_y + 8 + (((content_h - 16) - draw_h) / 2)
        bitmap.stretch_blt(Rect.new(ix, iy, draw_w, draw_h), icon, Rect.new(0, 0, icon.width, icon.height))
      else
        PokemonSurvivor.draw_text_center(bitmap, "?", area_x, area_y + ((content_h) / 2) - 8, area_w, Color.new(248, 248, 248), Color.new(32, 32, 40))
      end
    end
    rarity = PokemonSurvivor::BATTLE_PASS_REWARD_RARITY_COLORS[reward[:rarity]] || Color.new(232, 238, 248)
    amount_text = _INTL("x{1}", [reward[:amount].to_i, 1].max)
    draw_text_box(bitmap, amount_text, area_x + 7, area_y + area_h - label_h - 1, area_w - 14, label_h, rarity, Color.new(32, 32, 40), 2)
  rescue
  end

  def draw_battle_pass_quest_panel(bitmap, x, y, w, h)
    pass = selected_battle_pass
    quests = PokemonSurvivor.battle_pass_quest_list(selected_battle_pass)
    draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(6, 10, 20, 245))
    draw_pixel_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, Color.new(30, 42, 66, 245))
    draw_text_box(bitmap, _INTL("Battle Pass Quests"), x + 14, y + 7, w - 28, 24, Color.new(255, 214, 92), Color.new(25, 25, 30), 2)
    return if quests.empty? || !pass
    row_h = 28
    visible = [[(h - 44) / row_h, 1].max, quests.length].min
    first = @battle_pass_quest_index.to_i - (visible / 2)
    first = 0 if first < 0
    first = [first, [quests.length - visible, 0].max].min
    quests[first, visible].each_with_index do |quest, local_i|
      index = first + local_i
      row_y = y + 36 + (local_i * row_h)
      draw_battle_pass_quest_row(bitmap, x + 12, row_y, w - 38, row_h - 4, pass, quest, index == @battle_pass_quest_index.to_i)
    end
    draw_battle_pass_quest_scrollbar(bitmap, x + w - 16, y + 38, 6, h - 48, quests.length, visible, first)
  rescue
  end
  def draw_battle_pass_quest_row(bitmap, x, y, w, h, pass, quest, selected)
    progress = PokemonSurvivor.battle_pass_quest_progress(quest)
    target = [quest[:target].to_i, 1].max
    complete = progress >= target
    claimed = PokemonSurvivor.battle_pass_quest_claimed?(pass, quest)
    edge = selected ? Color.new(255, 214, 92) : Color.new(72, 92, 132)
    fill = claimed ? Color.new(24, 58, 42, 245) : (complete ? Color.new(56, 54, 34, 245) : Color.new(22, 28, 44, 245))
    draw_pixel_round_rect(bitmap, x, y, w, h, edge)
    draw_pixel_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, fill)
    name_inset = complete && !claimed ? 24 : 10
    name_w = w - 108 - name_inset
    draw_text_box(bitmap, _INTL(quest[:name].to_s), x + name_inset, y + 3, name_w, 20, complete ? Color.new(255, 238, 160) : Color.new(222, 232, 248), Color.new(25, 25, 30), 0)
    xp = _INTL("+{1} XP", quest[:xp].to_i)
    draw_text_box(bitmap, xp, x + w - 106, y + 3, 98, 20, complete && !claimed ? Color.new(92, 232, 148) : Color.new(168, 174, 188), Color.new(25, 25, 30), 2)
    draw_menu_notification(bitmap, x, y) if complete && !claimed
  rescue
  end
  def draw_battle_pass_quest_scrollbar(bitmap, x, y, w, h, count, visible, first)
    return if count <= visible
    thumb_h = [[(h * visible.to_f / count.to_f).to_i, 18].max, h].min
    max_first = [count - visible, 1].max
    thumb_y = y + ((h - thumb_h) * (first.to_f / max_first.to_f)).to_i
    if respond_to?(:draw_select_scrollbar)
      draw_select_scrollbar(bitmap, x, y, w, h, thumb_y, thumb_h)
    else
      draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(4, 7, 14, 220))
      draw_pixel_round_rect(bitmap, x, thumb_y, w, thumb_h, Color.new(255, 198, 70, 245))
    end
  rescue
  end

  def draw_battle_pass_quest_details(bitmap, x, y, w, h)
    pass = selected_battle_pass
    quest = PokemonSurvivor.battle_pass_quest_list(pass)[@battle_pass_quest_index.to_i]
    draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(6, 10, 20, 245))
    draw_pixel_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, Color.new(30, 42, 66, 245))
    return if !pass || !quest
    progress = PokemonSurvivor.battle_pass_quest_progress(quest)
    target = [quest[:target].to_i, 1].max
    complete = progress >= target
    claimed = PokemonSurvivor.battle_pass_quest_claimed?(pass, quest)
    count_color = claimed ? Color.new(255, 214, 92) : (complete ? Color.new(92, 232, 148) : Color.new(92, 188, 255))
    draw_text_box(bitmap, _INTL(quest[:desc].to_s), x + 12, y + 7, w - 132, 22, Color.new(222, 232, 248), Color.new(25, 25, 30), 0)
    draw_text_box(bitmap, _INTL("{1}/{2}", [progress, target].min, target), x + w - 112, y + 7, 100, 22, count_color, Color.new(25, 25, 30), 2)
    draw_battle_pass_quest_progress_bar(bitmap, x + 12, y + 34, w - 24, 10, progress, target, complete, claimed)
  rescue
  end
  def draw_battle_pass_quest_progress_bar(bitmap, x, y, w, h, progress, target, complete = false, claimed = false)
    ratio = [[progress.to_f / [target.to_i, 1].max, 0.0].max, 1.0].min
    fill_a = claimed ? Color.new(255, 198, 70, 255) : (complete ? Color.new(92, 232, 148, 255) : Color.new(82, 118, 166, 255))
    fill_b = claimed ? Color.new(255, 246, 168, 255) : (complete ? Color.new(178, 255, 206, 255) : Color.new(148, 176, 214, 255))
    draw_battle_pass_gauge(bitmap, x, y, w, h, ratio, fill_a, fill_b)
  rescue
  end

  def draw_battle_pass_details(bitmap, x, y, w, h)
    pass = selected_battle_pass
    reward = battle_pass_rewards_for_selected[@battle_pass_reward_index.to_i]
    draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(6, 10, 20, 245))
    draw_pixel_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, Color.new(30, 42, 66, 245))
    return if !pass || !reward
    rarity = PokemonSurvivor::BATTLE_PASS_REWARD_RARITY_COLORS[reward[:rarity]] || Color.new(232, 238, 248)
    ready = PokemonSurvivor.battle_pass_level(pass) >= reward[:tier].to_i
    title_w = ((w - 36) * 0.42).to_i
    gain_x = x + 18 + title_w
    gain_w = w - title_w - 36
    amount = [reward[:amount].to_i, 1].max
    gain_text = case reward[:kind]
                when :hero
                  _INTL("Unlock {1}.", PokemonSurvivor.species_name(reward[:hero] || reward[:name]))
                when :equipment
                  item = PokemonSurvivor.equipment_data(reward[:equipment]) if PokemonSurvivor.respond_to?(:equipment_data)
                  _INTL("Unlock {1} equipment.", _INTL((item && item[:name]) || reward[:name].to_s))
                when :candy
                  _INTL("Gain {1} Candies.", amount)
                else
                  _INTL("Gain {1} Fragments.", amount)
                end
    draw_text_box(bitmap, _INTL(reward[:name].to_s), x + 12, y + 8, title_w, 22, rarity, Color.new(25, 25, 30), 0)
    draw_text_box(bitmap, gain_text, gain_x, y + 8, gain_w, 22, Color.new(222, 232, 248), Color.new(25, 25, 30), 0)
    hint = ready ? _INTL("Claim Reward") : _INTL("Reach Battle Pass level {1} to claim this reward.", reward[:tier].to_i)
    draw_text_box(bitmap, hint, x + 12, y + 36, w - 24, 22, ready ? Color.new(92, 232, 148) : Color.new(168, 174, 188), Color.new(25, 25, 30), 0)
  rescue
  end
end




















