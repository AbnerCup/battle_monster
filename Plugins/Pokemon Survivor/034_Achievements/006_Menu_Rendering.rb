#===============================================================================
# Pokemon Survivor Achievements - menu rendering
#===============================================================================
class Scene_PokemonSurvivor
  def draw_achievements
    bmp = @sprites["screen"].bitmap
    over = @sprites["overlay"].bitmap
    over.clear
    bmp.clear
    draw_options_scrolling_background(bmp) rescue begin
      if @achievement_backdrop && !@achievement_backdrop.disposed?
        bmp.blt(0, 0, @achievement_backdrop, Rect.new(0, 0, Graphics.width, Graphics.height))
      else
        draw_menu_background(bmp) rescue bmp.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(7, 10, 18))
      end
    end
    x = 24
    y = 14
    w = Graphics.width - 48
    h = Graphics.height - 54
    draw_panel(bmp, x, y, w, h, Color.new(255, 196, 86), Color.new(14, 24, 42))
    draw_achievement_header(bmp, x, y, w)
    grid_x = x + 12
    grid_y = y + 52
    grid_w = w - 24
    grid_h = h - 84
    draw_achievement_medal_case(bmp, grid_x, grid_y, grid_w, grid_h)
    draw_achievement_rows(bmp, grid_x, grid_y, grid_w, grid_h)
    draw_achievement_detail(bmp) if @achievement_detail_open
    help = @achievement_detail_open ? [[:left, ""], [:right, _INTL("Navigate")], [:confirm, _INTL("Back")], [:cancel, _INTL("Back")]] : [[:up, ""], [:down, _INTL("Navigate")], [:left, ""], [:right, _INTL("Navigate")], [:confirm, _INTL("Details")], [:cancel, _INTL("Back")]]
    draw_help(over, help)
      draw_tv_filter(over) rescue nil
  rescue
  end
  def draw_achievement_header(bitmap, x, y, w)
    draw_pixel_round_rect(bitmap, x + 16, y + 12, w - 32, 36, Color.new(8, 13, 26, 214)) rescue bitmap.fill_rect(x + 16, y + 12, w - 32, 36, Color.new(8, 13, 26, 214))
    bitmap.fill_rect(x + 28, y + 16, w - 56, 2, Color.new(255, 196, 86, 190))
    PokemonSurvivor.draw_text_center(bitmap, _INTL("Achievement Medals"), x + 28, y + 25, w - 56, Color.new(255, 238, 160), Color.new(32, 28, 28))
    count_text = _INTL("{1}/{2}", PokemonSurvivorAchievements.earned_count, PokemonSurvivorAchievements.total_count)
    draw_achievement_text(bitmap, count_text, x + w - 100, y + 25, 72, 22, Color.new(255, 238, 160), Color.new(28, 28, 34), true)
  rescue
  end
  def draw_achievement_medal_case(bitmap, x, y, w, h)
    panel = cached_achievement_case_bitmap(w, h)
    if panel && !panel.disposed?
      bitmap.blt(x, y, panel, Rect.new(0, 0, w, h))
      return
    end
    draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(6, 10, 20, 232)) rescue bitmap.fill_rect(x, y, w, h, Color.new(6, 10, 20, 232))
  rescue
  end

  def cached_achievement_case_bitmap(w, h)
    @bitmaps ||= {}
    w = w.to_i
    h = h.to_i
    return nil if w <= 0 || h <= 0
    key = "achievement_case_solid:#{w}:#{h}"
    cached = @bitmaps[key]
    return cached if cached && !cached.disposed?
    bmp = Bitmap.new(w, h)
    draw_pixel_round_rect(bmp, 0, 0, w, h, Color.new(5, 8, 18, 255)) rescue bmp.fill_rect(0, 0, w, h, Color.new(5, 8, 18, 255))
    draw_pixel_round_rect(bmp, 3, 3, w - 6, h - 6, Color.new(18, 28, 48, 255)) rescue bmp.fill_rect(3, 3, w - 6, h - 6, Color.new(18, 28, 48, 255))
    draw_pixel_round_rect(bmp, 8, 8, w - 16, h - 16, Color.new(9, 14, 28, 255)) rescue bmp.fill_rect(8, 8, w - 16, h - 16, Color.new(9, 14, 28, 255))
    bmp.fill_rect(14, h - 14, w - 28, 1, Color.new(4, 8, 18, 180))
    @bitmaps[key] = bmp
    bmp
  rescue
    nil
  end
  def draw_achievement_rows(bitmap, x, y, w, h)
    rows = PokemonSurvivorAchievements.visible_all
    cols = achievement_grid_cols
    tile = achievement_tile_size
    visible_rows = [[achievement_visible_rows, (h / tile).floor].min, 1].max
    @achievement_effective_visible_rows = visible_rows
    ensure_achievement_scroll(false, visible_rows)
    first_row = @achievement_scroll.to_i
    first = first_row * cols
    last = [first + (visible_rows * cols), rows.length].min
    grid_w = cols * tile
    grid_h = visible_rows * tile
    start_x = x + ((w - grid_w) / 2)
    start_y = y + ((h - grid_h) / 2)
    @achievement_visible_medals = []
    first.upto(last - 1) do |i|
      data = rows[i]
      next if !data
      col = i % cols
      row = (i / cols) - first_row
      cx = start_x + (col * tile) + (tile / 2)
      cy = start_y + (row * tile) + (tile / 2)
      selected = i == @achievement_index.to_i
      earned = PokemonSurvivorAchievements.earned?(data[:id])
      color = PokemonSurvivorAchievements.rarity_color(data[:rarity])
      slot_color = earned ? color : Color.new(82, 90, 108)
      draw_achievement_medal_slot(bitmap, cx, cy, slot_color, selected, earned)
      draw_achievement_medal(bitmap, cx, cy, data[:rarity], earned)
      @achievement_visible_medals << { :x => cx, :y => cy, :scale => 0.5 } if earned
    end
    draw_achievement_sparkles(bitmap)
    total_rows = (rows.length + cols - 1) / cols
    draw_achievement_scrollbar(bitmap, x + w - 12, y + 12, 7, h - 24, first_row, total_rows, visible_rows)
  rescue
  end
  def draw_achievement_medal_slot(bitmap, cx, cy, color, selected, earned)
    pulse_step = selected ? (((Math.sin(@achievement_frame.to_i / 8.0) + 1.0) * 3).round) : 0
    slot = cached_achievement_slot_bitmap(color, selected, earned, pulse_step)
    if slot && !slot.disposed?
      bitmap.blt(cx - (slot.width / 2), cy - (slot.height / 2), slot, Rect.new(0, 0, slot.width, slot.height))
      return
    end
    draw_pixel_round_rect(bitmap, cx - 20, cy - 20, 40, 40, Color.new(color.red, color.green, color.blue, selected ? 238 : 96)) rescue nil
  rescue
  end

  def cached_achievement_slot_bitmap(color, selected, earned, pulse_step = 0)
    @bitmaps ||= {}
    key = "achievement_slot_solid:#{color.red}:#{color.green}:#{color.blue}:#{selected ? 1 : 0}:#{earned ? 1 : 0}:#{pulse_step.to_i}"
    cached = @bitmaps[key]
    return cached if cached && !cached.disposed?
    bmp = Bitmap.new(42, 40)
    pulse = selected ? pulse_step.to_i * 8 : 0
    edge = selected ? Color.new(255, 224, 92, 255) : Color.new([color.red / 2, 56].max, [color.green / 2, 56].max, [color.blue / 2, 64].max, 255)
    inner_edge = selected ? Color.new(255, 250, 186, [190 + pulse, 255].min) : Color.new(42, 54, 76, 255)
    fill = earned ? Color.new(12, 18, 32, 255) : Color.new(24, 28, 38, 255)
    tint = earned ? Color.new([color.red / 2, 42].max, [color.green / 2, 42].max, [color.blue / 2, 48].max, 150) : Color.new(58, 62, 76, 255)
    draw_pixel_round_rect(bmp, 0, 0, 42, 40, Color.new(0, 0, 0, 255)) rescue bmp.fill_rect(0, 0, 42, 40, Color.new(0, 0, 0, 255))
    draw_pixel_round_rect(bmp, 1, 1, 40, 38, edge) rescue bmp.fill_rect(1, 1, 40, 38, edge)
    draw_pixel_round_rect(bmp, 3, 3, 36, 34, inner_edge) rescue bmp.fill_rect(3, 3, 36, 34, inner_edge)
    draw_pixel_round_rect(bmp, 5, 5, 32, 30, fill) rescue bmp.fill_rect(5, 5, 32, 30, fill)
    draw_pixel_round_rect(bmp, 8, 8, 26, 24, tint) rescue bmp.fill_rect(8, 8, 26, 24, tint)
    if selected
      bmp.fill_rect(0, 6, 2, 28, Color.new(255, 224, 92, 235))
      bmp.fill_rect(40, 6, 2, 28, Color.new(255, 224, 92, 235))
      bmp.fill_rect(6, 0, 30, 2, Color.new(255, 224, 92, 235))
      bmp.fill_rect(6, 38, 30, 2, Color.new(255, 224, 92, 235))
    end
    @bitmaps[key] = bmp
    bmp
  rescue
    nil
  end
  def draw_achievement_detail(bitmap)
    rows = PokemonSurvivorAchievements.visible_all
    data = rows[@achievement_index.to_i]
    return if !data
    earned = PokemonSurvivorAchievements.earned?(data[:id])
    color = PokemonSurvivorAchievements.rarity_color(data[:rarity])
    w = [Graphics.width - 72, 560].min
    h = 252
    x = (Graphics.width - w) / 2
    y = (Graphics.height - h) / 2
    draw_options_scrolling_background(bitmap) rescue nil
    draw_panel(bitmap, x, y, w, h, color, Color.new(14, 24, 42))
    header_h = 42
    draw_pixel_round_rect(bitmap, x + 14, y + 12, w - 28, header_h, Color.new(7, 12, 24, 230)) rescue bitmap.fill_rect(x + 14, y + 12, w - 28, header_h, Color.new(7, 12, 24, 230))
    bitmap.fill_rect(x + 26, y + 16, w - 52, 2, Color.new(color.red, color.green, color.blue, earned ? 210 : 112))
    title = earned ? _INTL(data[:name].to_s) : _INTL("Locked Achievement")
    PokemonSurvivor.draw_text_center(bitmap, title, x + 28, y + 27, w - 56, earned ? color : Color.new(162, 170, 184), Color.new(24, 24, 32))

    medal_x = x + 92
    medal_y = y + 126
    draw_pixel_round_rect(bitmap, medal_x - 50, medal_y - 50, 100, 100, Color.new(4, 8, 18, 210)) rescue nil
    draw_achievement_medal(bitmap, medal_x, medal_y, data[:rarity], earned, 1.0, true)
    draw_achievement_counter_box(bitmap, data, medal_x - 54, medal_y + 58, 108, 28, color)

    info_x = x + 158
    info_y = y + 74
    info_w = w - 184
    draw_pixel_round_rect(bitmap, info_x, info_y, info_w, 32, Color.new(8, 13, 26, 206)) rescue bitmap.fill_rect(info_x, info_y, info_w, 32, Color.new(8, 13, 26, 206))
    rarity = _INTL(PokemonSurvivorAchievements.rarity_name(data[:rarity]))
    draw_achievement_text(bitmap, rarity, info_x + 10, info_y + 6, info_w - 20, 20, earned ? Color.new(255, 238, 160) : Color.new(142, 150, 166), Color.new(24, 24, 32), false)

    desc = earned ? _INTL(data[:desc].to_s) : _INTL("Hint: {1}", _INTL((data[:hint] || data[:desc] || "Keep playing to discover this medal.").to_s))
    draw_pixel_round_rect(bitmap, info_x, info_y + 44, info_w, 108, Color.new(10, 16, 30, 196)) rescue bitmap.fill_rect(info_x, info_y + 44, info_w, 108, Color.new(10, 16, 30, 196))
    draw_achievement_wrapped_text(bitmap, desc, info_x + 10, info_y + 56, info_w - 20, 88, earned ? Color.new(214, 224, 238) : Color.new(132, 142, 158), Color.new(24, 24, 32))
    pulse = ((Math.sin(@achievement_frame.to_i / 9.0) + 1.0) * 3).round
    alpha = [190 + (pulse * 10), 255].min
    arrow_color = Color.new(color.red, color.green, color.blue, alpha)
    shadow = Color.new(4, 6, 12, 230)
    left_x = [x - 38 - pulse, 4].max
    right_x = [x + w + 16 + pulse, Graphics.width - 28].min
    arrow_y = y + (h / 2) - 14
    [["<", left_x], [">", right_x]].each do |char, ax|
      PokemonSurvivor.draw_text_center(bitmap, char, ax + 1, arrow_y, 24, shadow, shadow) rescue nil
      PokemonSurvivor.draw_text_center(bitmap, char, ax - 1, arrow_y, 24, shadow, shadow) rescue nil
      PokemonSurvivor.draw_text_center(bitmap, char, ax, arrow_y + 1, 24, shadow, shadow) rescue nil
      PokemonSurvivor.draw_text_center(bitmap, char, ax, arrow_y, 24, arrow_color, Color.new(24, 24, 32)) rescue nil
      PokemonSurvivor.draw_text_center(bitmap, char, ax + 1, arrow_y, 24, arrow_color, Color.new(24, 24, 32)) rescue nil
    end
  rescue
  end
  def draw_achievement_counter_box(bitmap, data, x, y, w, h, color)
    counter = PokemonSurvivorAchievements.counter_for(data) rescue nil
    return if !counter || counter[1].to_i <= 1
    current = [[counter[0].to_i, 0].max, counter[1].to_i].min
    target = counter[1].to_i
    draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(5, 9, 18, 226)) rescue bitmap.fill_rect(x, y, w, h, Color.new(5, 9, 18, 226))
    draw_pixel_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, Color.new([color.red / 4, 30].max, [color.green / 4, 30].max, [color.blue / 4, 38].max, 218)) rescue nil
    text = _INTL("{1}/{2}", current, target)
    PokemonSurvivor.draw_text_center(bitmap, text, x + 8, y + 5, w - 16, Color.new(255, 238, 160), Color.new(24, 24, 32))
  rescue
  end
  def draw_achievement_wrapped_text(bitmap, text, x, y, w, h, color, shadow)
    temp = cached_achievement_wrapped_text_bitmap(text.to_s, w, h, color, shadow)
    bitmap.blt(x, y, temp, Rect.new(0, 0, w, h)) if temp && !temp.disposed?
  rescue
  end

  def cached_achievement_wrapped_text_bitmap(text, w, h, color, shadow)
    @achievement_text_cache ||= {}
    w = [w.to_i, 1].max
    h = [h.to_i, 1].max
    key = "wrap:#{text}:#{w}:#{h}:#{color.red}:#{color.green}:#{color.blue}:#{shadow.red}:#{shadow.green}:#{shadow.blue}"
    cached = @achievement_text_cache[key]
    return cached if cached && !cached.disposed?
    bmp = Bitmap.new(w, h)
    pbSetSystemFont(bmp) rescue nil
    words = text.to_s.split(/\s+/)
    lines = [""]
    words.each do |word|
      test = lines[-1].empty? ? word : "#{lines[-1]} #{word}"
      if (bmp.text_size(test).width rescue test.length * 8) > w && !lines[-1].empty?
        lines << word
      else
        lines[-1] = test
      end
    end
    line_h = 22
    lines[0, (h / line_h).floor].each_with_index do |line, i|
      pbDrawTextPositions(bmp, [[line, 0, i * line_h, false, color, shadow]]) rescue nil
    end
    if @achievement_text_cache.length > 96
      old_key = @achievement_text_cache.keys.first
      old = @achievement_text_cache.delete(old_key)
      old.dispose if old && !old.disposed?
    end
    @achievement_text_cache[key] = bmp
  rescue
    nil
  end
  def draw_achievement_sparkles(bitmap)
    (@achievement_sparkles || []).each do |sparkle|
      sheet = cached_bitmap(PokemonSurvivorAchievements::HUD_DIR, sparkle[:sheet].to_s) rescue nil
      next if !sheet || sheet.disposed?
      frame_size = [sheet.height, 1].max
      frames = [sheet.width / frame_size, 1].max
      frame = [[sparkle[:timer].to_i / 6, 0].max, frames - 1].min
      scale = sparkle[:scale].to_f <= 0 ? 0.5 : sparkle[:scale].to_f
      size = [(frame_size * scale).round, 12].max
      x = sparkle[:x].to_i - (size / 2)
      y = sparkle[:y].to_i - (size / 2)
      bitmap.stretch_blt(Rect.new(x, y, size, size), sheet, Rect.new(frame * frame_size, 0, frame_size, frame_size))
    end
  rescue
  end
  def draw_achievement_scrollbar(bitmap, x, y, w, h, first, total, visible)
    return if total <= visible
    thumb_h = [[(h * visible / total.to_f).round, 18].max, h].min
    max_scroll = [total - visible, 1].max
    thumb_y = y + ((h - thumb_h) * first.to_i / max_scroll)
    if respond_to?(:draw_select_scrollbar)
      draw_select_scrollbar(bitmap, x, y, w, h, thumb_y, thumb_h)
      return
    end
    bitmap.fill_rect(x, y, w, h, Color.new(3, 6, 13))
    bitmap.fill_rect(x + 1, y + 1, w - 2, h - 2, Color.new(34, 46, 68))
    bitmap.fill_rect(x + 2, y + 2, w - 4, h - 4, Color.new(8, 13, 26))
    bitmap.fill_rect(x + 2, y + 2, 1, h - 4, Color.new(66, 84, 118))
    tx = x + 1
    tw = w - 2
    ty = [[thumb_y.to_i, y + 1].max, y + h - thumb_h.to_i - 1].min
    th = [[thumb_h.to_i, 12].max, h - 2].min
    bitmap.fill_rect(tx, ty, tw, th, Color.new(122, 92, 42))
    bitmap.fill_rect(tx + 1, ty + 1, tw - 2, th - 2, Color.new(255, 198, 70))
    bitmap.fill_rect(tx + 2, ty + 2, [tw - 4, 1].max, 2, Color.new(255, 238, 150))
    bitmap.fill_rect(tx + tw - 2, ty + 2, 1, [th - 4, 1].max, Color.new(164, 112, 42))
    bitmap.fill_rect(tx + 2, ty + th - 3, [tw - 4, 1].max, 1, Color.new(164, 112, 42))
  rescue
  end
  def draw_achievement_medal(bitmap, cx, cy, rarity, earned, scale = 0.5, draw_socket = nil)
    scale = [[scale.to_f, 0.25].max, 1.0].min
    color = PokemonSurvivorAchievements.rarity_color(rarity)
    draw_socket = scale >= 0.99 if draw_socket.nil?
    draw_achievement_medal_socket(bitmap, cx, cy, color, earned, scale) if draw_socket
    name = earned ? PokemonSurvivorAchievements.medal_name(rarity) : "HINTMEDAL"
    medal = cached_achievement_medal_bitmap(name, scale)
    medal = cached_achievement_medal_bitmap(PokemonSurvivorAchievements.medal_name(rarity), scale) if (!medal || medal.disposed?) && earned
    if medal && !medal.disposed?
      bitmap.blt(cx - (medal.width / 2), cy - (medal.height / 2), medal, Rect.new(0, 0, medal.width, medal.height))
    else
      fallback = earned ? color : Color.new(92, 98, 112)
      size = [(26 * scale).round, 10].max
      draw_pixel_round_rect(bitmap, cx - (size / 2), cy - (size / 2), size, size, fallback) rescue bitmap.fill_rect(cx - (size / 2), cy - (size / 2), size, size, fallback)
      shine_w = [(18 * scale).round, 6].max
      shine_h = [(4 * scale).round, 2].max
      bitmap.fill_rect(cx - (shine_w / 2), cy - (shine_h / 2), shine_w, shine_h, Color.new(255, 255, 255, earned ? 54 : 26))
    end
  rescue
  end

  def cached_achievement_medal_bitmap(name, scale)
    scale = [[scale.to_f, 0.25].max, 1.0].min
    base = cached_bitmap(PokemonSurvivorAchievements::HUD_DIR, name.to_s) rescue nil
    return nil if !base || base.disposed?
    return base if scale >= 0.99
    key = "#{PokemonSurvivorAchievements::HUD_DIR}/#{name}:scaled:#{(scale * 100).round}"
    @bitmaps ||= {}
    cached = @bitmaps[key]
    return cached if cached && !cached.disposed?
    w = [(base.width * scale).round, 1].max
    h = [(base.height * scale).round, 1].max
    scaled = Bitmap.new(w, h)
    scaled.stretch_blt(Rect.new(0, 0, w, h), base, Rect.new(0, 0, base.width, base.height))
    @bitmaps[key] = scaled
    scaled
  rescue
    nil
  end

  def draw_achievement_medal_socket(bitmap, cx, cy, color, earned, scale = 0.5)
    scale = [[scale.to_f, 0.25].max, 1.0].min
    alpha = earned ? 218 : 116
    if scale >= 0.99
      draw_pixel_round_rect(bitmap, cx - 36, cy - 34, 72, 69, Color.new(0, 0, 0, 96)) rescue bitmap.fill_rect(cx - 36, cy - 34, 72, 69, Color.new(0, 0, 0, 96))
      draw_pixel_round_rect(bitmap, cx - 35, cy - 35, 70, 70, Color.new(color.red, color.green, color.blue, alpha)) rescue bitmap.fill_rect(cx - 35, cy - 35, 70, 70, Color.new(color.red, color.green, color.blue, alpha))
      inner = earned ? Color.new(10, 14, 26, 232) : Color.new(26, 30, 40, 224)
      draw_pixel_round_rect(bitmap, cx - 32, cy - 32, 64, 64, inner) rescue bitmap.fill_rect(cx - 32, cy - 32, 64, 64, inner)
      glow = earned ? Color.new([color.red / 3, 32].max, [color.green / 3, 32].max, [color.blue / 3, 38].max, 194) : Color.new(50, 54, 66, 174)
      draw_pixel_round_rect(bitmap, cx - 29, cy - 29, 58, 58, glow) rescue bitmap.fill_rect(cx - 29, cy - 29, 58, 58, glow)
      return
    end
    draw_pixel_round_rect(bitmap, cx - 18, cy - 17, 36, 34, Color.new(0, 0, 0, 92)) rescue bitmap.fill_rect(cx - 18, cy - 17, 36, 34, Color.new(0, 0, 0, 92))
    draw_pixel_round_rect(bitmap, cx - 17, cy - 17, 34, 34, Color.new(color.red, color.green, color.blue, alpha)) rescue bitmap.fill_rect(cx - 17, cy - 17, 34, 34, Color.new(color.red, color.green, color.blue, alpha))
    inner = earned ? Color.new(10, 14, 26, 232) : Color.new(26, 30, 40, 224)
    draw_pixel_round_rect(bitmap, cx - 15, cy - 15, 30, 30, inner) rescue bitmap.fill_rect(cx - 15, cy - 15, 30, 30, inner)
    glow = earned ? Color.new([color.red / 3, 32].max, [color.green / 3, 32].max, [color.blue / 3, 38].max, 184) : Color.new(50, 54, 66, 164)
    draw_pixel_round_rect(bitmap, cx - 13, cy - 13, 26, 26, glow) rescue bitmap.fill_rect(cx - 13, cy - 13, 26, 26, glow)
    bitmap.fill_rect(cx - 11, cy - 12, 22, 1, Color.new(255, 255, 255, earned ? 48 : 20))
    bitmap.fill_rect(cx - 11, cy + 11, 22, 1, Color.new(0, 0, 0, 72))
  rescue
  end
  def draw_achievement_text(bitmap, text, x, y, w, h, color, shadow, align_right = false)
    if respond_to?(:draw_shop_scrolling_text)
      draw_shop_scrolling_text(bitmap, text.to_s, x, y, w, h, color, shadow, align_right)
    else
      temp = cached_achievement_plain_text_bitmap(text.to_s, w, h, color, shadow, align_right)
      bitmap.blt(x, y, temp, Rect.new(0, 0, w, h)) if temp && !temp.disposed?
    end
  rescue
  end

  def cached_achievement_plain_text_bitmap(text, w, h, color, shadow, align_right = false)
    @achievement_text_cache ||= {}
    w = [w.to_i, 1].max
    h = [h.to_i, 1].max
    key = "plain:#{text}:#{w}:#{h}:#{color.red}:#{color.green}:#{color.blue}:#{shadow.red}:#{shadow.green}:#{shadow.blue}:#{align_right ? 1 : 0}"
    cached = @achievement_text_cache[key]
    return cached if cached && !cached.disposed?
    bmp = Bitmap.new(w, h)
    pbSetSystemFont(bmp) rescue nil
    pbDrawTextPositions(bmp, [[text.to_s, align_right ? w - 2 : 0, 0, align_right, color, shadow]]) rescue nil
    if @achievement_text_cache.length > 96
      old_key = @achievement_text_cache.keys.first
      old = @achievement_text_cache.delete(old_key)
      old.dispose if old && !old.disposed?
    end
    @achievement_text_cache[key] = bmp
  rescue
    nil
  end
end


