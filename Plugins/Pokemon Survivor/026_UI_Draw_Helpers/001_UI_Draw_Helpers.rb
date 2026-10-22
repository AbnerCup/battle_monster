#===============================================================================
# Pokemon Survivor - Text helpers, upgrade cards, pause/results and help bar
#===============================================================================

class Scene_PokemonSurvivor

  def wrapped_lines(bitmap, text, max_width, max_lines = nil)
    if text.to_s.match?(/[\u1100-\u11ff\u2e80-\u9fff\uac00-\ud7af\uf900-\ufaff\uff00-\uffef]/)
      lines = cjk_wrapped_lines(bitmap, text.to_s, max_width)
      if max_lines && lines.length > max_lines
        return [] if max_lines <= 0
        lines = lines.first(max_lines)
        last = lines[-1].dup
        last = last[0...-1] while !last.empty? && bitmap.text_size(last + "...").width > max_width
        lines[-1] = last + "..."
      end
      return lines
    end
    words = text.to_s.split(/\s+/)
    lines = []
    current = ""
    words.each do |word|
      test = current.empty? ? word : "#{current} #{word}"
      if bitmap.text_size(test).width <= max_width
        current = test
      else
        lines << current unless current.empty?
        remaining = word.scan(/\X/)
        # Only split words that cannot fit on a fresh line; reserve the hyphen.
        while remaining.length > 1 && bitmap.text_size(remaining.join).width > max_width
          count = 0
          1.upto(remaining.length - 1) do |length|
            break if bitmap.text_size(remaining.first(length).join + "-").width > max_width
            count = length
          end
          if count > 0
            lines << remaining.shift(count).join + "-"
          else
            lines << remaining.shift
          end
        end
        current = remaining.join
      end
    end
    lines << current unless current.empty?
    if max_lines && lines.length > max_lines
      return [] if max_lines <= 0
      lines = lines.first(max_lines)
      ellipsis = "..."
      line = lines[-1].dup
      while (bitmap.text_size(line + ellipsis).width rescue 0) > max_width && line.length > 0
        line = line[0, line.length - 1]
      end
      lines[-1] = line + ellipsis
    end
    lines
  rescue
    [text.to_s]
  end

  def ellipsize_text(bitmap, text, max_width)
    text = text.to_s
    return text if max_width.to_i <= 0
    return text if (bitmap.text_size(text).width rescue text.length * 8) <= max_width
    ellipsis = "..."
    ellipsis_w = bitmap.text_size(ellipsis).width rescue 18
    limit = [max_width.to_i - ellipsis_w, 1].max
    chars = text.each_char.to_a
    while chars.length > 0
      candidate = chars.join
      return candidate + ellipsis if (bitmap.text_size(candidate).width rescue candidate.length * 8) <= limit
      chars.pop
    end
    ellipsis
  rescue
    text.to_s[0, [max_width.to_i / 8, 1].max] + "..."
  end

  def draw_text_box_ellipsis(bitmap, text, x, y, w, h, base = Color.white, shadow = Color.new(40, 40, 48), align = false)
    w = w.to_i
    h = h.to_i
    return if w <= 0 || h <= 0
    pbSetSystemFont(bitmap)
    fitted = ellipsize_text(bitmap, text.to_s, w)
    draw_x = (align == 2) ? x + (w / 2) : x
    pbDrawTextPositions(bitmap, [[fitted, draw_x, y, align, base, shadow]])
  rescue
  end
  def draw_wrapped_text(bitmap, text, x, y, w, line_h, max_lines, base, shadow = Color.new(40, 40, 48), align = false)
    wrapped_lines(bitmap, text, w, max_lines).each_with_index do |line, i|
      pbDrawTextPositions(bitmap, [[line, x, y + (i * line_h), align, base, shadow]])
    end
  rescue
  end

  def point_on_screen?(x, y, margin = 0)
    w = @screen_w || Graphics.width
    h = @screen_h || Graphics.height
    m = margin.to_f
    if respond_to?(:run_view_zoom) && respond_to?(:world_screen_x) && respond_to?(:world_screen_y) && run_view_zoom < 0.999
      z = run_view_zoom
      xf = world_screen_x(x)
      yf = world_screen_y(y)
      m *= z
    else
      xf = x.to_f
      yf = y.to_f
    end
    xf >= -m && xf <= w + m && yf >= -m && yf <= h + m
  rescue
    true
  end

  def cjk_wrapped_lines(bitmap, text, max_width)
    width = [max_width.to_i, 1].max
    language = defined?($PokemonSystem) && $PokemonSystem ? $PokemonSystem.language : nil
    key = [text, width, bitmap.font.name, bitmap.font.size, bitmap.font.bold, bitmap.font.italic, language]
    @ui_cjk_wrap_cache ||= {}
    cached = @ui_cjk_wrap_cache[key]
    return cached.dup if cached
    lines = []
    text.gsub("\r\n", "\n").split("\n", -1).each do |paragraph|
      current = ""
      # Grapheme clusters keep combining marks attached to their characters.
      paragraph.scan(/\X/).each do |character|
        candidate = current + character
        if !current.empty? && bitmap.text_size(candidate).width > width
          lines << current
          current = character
        else
          current = candidate
        end
      end
      lines << current
    end
    @ui_cjk_wrap_cache.shift if @ui_cjk_wrap_cache.length >= 64
    @ui_cjk_wrap_cache[key] = lines.map { |line| line.freeze }.freeze
    lines.dup
  end

  def scroll_offset(max_offset, speed = 18.0)
    return 0 if max_offset <= 0
    span = max_offset * 2
    pos = ((System.uptime rescue 0) * speed).to_i % [span, 1].max
    pos > max_offset ? span - pos : pos
  rescue
    0
  end

  def draw_text_box(bitmap, text, x, y, w, h, base = Color.white, shadow = Color.new(40, 40, 48), align = false)
    w = w.to_i
    h = h.to_i
    return if w <= 0 || h <= 0
    pbSetSystemFont(bitmap)
    text = text.to_s
    text_w = bitmap.text_size(text).width rescue 0
    draw_x = (align == 2) ? x + (w / 2) : x
    return pbDrawTextPositions(bitmap, [[text, draw_x, y, align, base, shadow]]) if text_w <= w
    line = cached_single_line_text_bitmap(text, base, shadow, h, text_w)
    return if !line || line.disposed?
    offset = scroll_offset([line.width - w, 0].max, 22.0)
    bitmap.blt(x, y, line, Rect.new(offset, 0, w, h))
  rescue
  end

  def cached_single_line_text_bitmap(text, base, shadow, h, measured_w = nil)
    @ui_single_line_text_cache ||= {}
    h = [h.to_i, 1].max
    text = text.to_s
    key = [text, base.red, base.green, base.blue, base.alpha, shadow.red, shadow.green, shadow.blue, shadow.alpha, h].join(":")
    cached = @ui_single_line_text_cache[key]
    return cached if cached && !cached.disposed?
    width = [(measured_w || text.length * 10).to_i + 24, 1].max
    bmp = Bitmap.new(width, h)
    pbSetSystemFont(bmp)
    pbDrawTextPositions(bmp, [[text, 0, 0, false, base, shadow]])
    if @ui_single_line_text_cache.length > 96
      old_key = @ui_single_line_text_cache.keys.first
      old = @ui_single_line_text_cache.delete(old_key)
      old.dispose if old && !old.disposed?
    end
    @ui_single_line_text_cache[key] = bmp
    bmp
  rescue
    nil
  end

  def selected_card_text_offset(key, max_offset)
    now = System.uptime
    state = @selected_card_text_scroll
    if !state || state[:key] != key || now - state[:seen] > 0.25 || state[:max] != max_offset
      state = { :key => key, :max => max_offset, :seen => now,
                :offset => scroll_offset(max_offset, 10.0), :manual_at => nil, :direction => 1 }
      @selected_card_text_scroll = state
    end
    dt = [[now - state[:seen], 0.0].max, 0.05].min
    state[:seen] = now
    direction = (Input.press?(Input::DOWN) ? 1 : 0) - (Input.press?(Input::UP) ? 1 : 0)
    if direction != 0
      state[:offset] = [[state[:offset] + direction * 90.0 * dt, 0.0].max, max_offset].min
      state[:manual_at] = now
      state[:direction] = direction
      state[:anchor] = state[:offset]
    elsif state[:manual_at]
      elapsed = now - state[:manual_at] - 3.0
      if elapsed > 0.0 && max_offset > 0
        # Resume from the last manual position without snapping to the global clock.
        phase = state[:direction] > 0 ? state[:anchor] : max_offset * 2 - state[:anchor]
        phase = (phase + elapsed * 10.0) % (max_offset * 2)
        state[:offset] = phase > max_offset ? max_offset * 2 - phase : phase
      end
    else
      state[:offset] = scroll_offset(max_offset, 10.0)
    end
    state[:offset].to_i
  end

  def draw_scrolling_wrapped_text(bitmap, text, x, y, w, h, line_h, base, shadow = Color.new(40, 40, 48), manual_key = nil, scroll_speed = 10.0)
    w = w.to_i
    h = h.to_i
    line_h = [line_h.to_i, 1].max
    return if w <= 0 || h <= 0
    pbSetSystemFont(bitmap)
    lines = wrapped_lines(bitmap, text, w, nil)
    content_h = [lines.length * line_h, h].max
    manual_offset = selected_card_text_offset([@state, manual_key, text], content_h - h) if manual_key
    if content_h <= h || lines.length <= (h / line_h)
      lines.first(h / line_h).each_with_index do |line, i|
        pbDrawTextPositions(bitmap, [[line, x, y + (i * line_h), false, base, shadow]])
      end
      return
    end
    block = cached_wrapped_text_bitmap(lines, w, content_h, line_h, base, shadow)
    return if !block || block.disposed?
    offset = manual_offset || scroll_offset(content_h - h, scroll_speed)
    bitmap.blt(x, y, block, Rect.new(0, offset, w, h))
  rescue
  end

  def cached_wrapped_text_bitmap(lines, w, content_h, line_h, base, shadow)
    @ui_wrapped_text_cache ||= {}
    w = [w.to_i, 1].max
    content_h = [content_h.to_i, 1].max
    key = [lines.join("
"), w, content_h, line_h.to_i, base.red, base.green, base.blue, base.alpha, shadow.red, shadow.green, shadow.blue, shadow.alpha].join(":")
    cached = @ui_wrapped_text_cache[key]
    return cached if cached && !cached.disposed?
    bmp = Bitmap.new(w, content_h)
    pbSetSystemFont(bmp)
    lines.each_with_index do |line, i|
      pbDrawTextPositions(bmp, [[line, 0, i * line_h, false, base, shadow]])
    end
    if @ui_wrapped_text_cache.length > 64
      old_key = @ui_wrapped_text_cache.keys.first
      old = @ui_wrapped_text_cache.delete(old_key)
      old.dispose if old && !old.disposed?
    end
    @ui_wrapped_text_cache[key] = bmp
    bmp
  rescue
    nil
  end

  def type_name(type)
    data = GameData::Type.try_get(type) rescue nil
    return data.name if data
    type.to_s.split("_").map { |p| p.capitalize }.join(" ")
  end

  def type_color(type)
    case type
    when :FIRE     then Color.new(255, 118, 64)
    when :WATER    then Color.new(78, 174, 255)
    when :GRASS    then Color.new(86, 220, 122)
    when :PSYCHIC  then Color.new(255, 116, 208)
    when :POISON   then Color.new(184, 104, 255)
    when :ELECTRIC then Color.new(255, 224, 74)
    when :ROCK     then Color.new(190, 166, 112)
    when :ICE      then Color.new(130, 232, 255)
    when :FAIRY    then Color.new(255, 150, 218)
    when :STEEL    then Color.new(172, 188, 210)
    when :GROUND   then Color.new(210, 174, 92)
    when :FIGHTING then Color.new(230, 88, 78)
    when :DARK     then Color.new(120, 102, 150)
    when :DRAGON   then Color.new(112, 132, 255)
    when :GHOST    then Color.new(154, 116, 224)
    when :NORMAL   then Color.new(210, 210, 190)
    else Color.new(132, 214, 255)
    end
  end

  def upgrade_skill_data(upgrade)
    skill_id = upgrade[:skill] || upgrade[:target_skill]
    skill_id ? PokemonSurvivor.localized_skill(skill_id) : nil
  end

  def upgrade_rarity(upgrade)
    return upgrade[:rarity] if upgrade && upgrade[:rarity]
    return :rare if upgrade[:skill]
    return :uncommon if upgrade[:target_skill]
    :common
  rescue
    :common
  end

  def upgrade_primary_hero_key(upgrade)
    skill_id = upgrade[:target_skill] || upgrade[:skill]
    return nil if !skill_id
    return :FEEBAS if [:fairy_splash, :fairy_pump].include?(skill_id)
    if skill_id == :splash && @hero_skill == :splash
      base_key = PokemonSurvivor.species_key(@hero_base_name || @passive_key || @hero_name) rescue nil
      return :FEEBAS if [:FEEBAS, :MILOTIC].include?(base_key)
      return :MAGIKARP if [:MAGIKARP, :GYARADOS].include?(base_key)
    end
    skill_owner_aliases = {
      :splash => :MAGIKARP,
      :hydro_pump => :MAGIKARP,
      :fairy_pump => :FEEBAS
    }
    return skill_owner_aliases[skill_id] if skill_owner_aliases[skill_id]
    PokemonSurvivor::BASE_HERO_KEYS.each do |hero_key|
      data = PokemonSurvivor::HERO_BASE[hero_key]
      return hero_key if data && data[:skill] == skill_id
    end
    # Some evolutions replace their base Pokemon's skill with an exclusive move.
    PokemonSurvivor::HERO_BASE.each_pair do |hero_key, data|
      return hero_key if data && data[:skill] == skill_id
    end
    nil
  rescue
    nil
  end
  def cached_upgrade_pokemon_icon(hero_key)
    return nil if !hero_key
    folder = "#{PokemonSurvivor::ROOT}/Menu HUD/Leader Board/Pokemon Icons"
    @upgrade_pokemon_icon_cache ||= {}
    candidates = [hero_key.to_s, PokemonSurvivor.species_key(hero_key).to_s, hero_key.to_s.upcase].uniq
    candidates.each do |name|
      cache_key = "#{folder}/#{name}"
      cached = @upgrade_pokemon_icon_cache[cache_key]
      return cached if cached && !cached.disposed?
      bmp = PokemonSurvivor.load_bitmap(folder, name)
      if bmp && !bmp.disposed?
        @upgrade_pokemon_icon_cache[cache_key] = bmp
        return bmp
      end
    end
    cached_upgrade_pokemon_sprite_icon(hero_key)
  rescue
    nil
  end

  def cached_upgrade_pokemon_sprite_icon(hero_key)
    return nil if !hero_key
    @upgrade_pokemon_icon_cache ||= {}
    key = PokemonSurvivor.species_key(hero_key).to_s
    cache_key = "upgrade_sprite_icon:#{key}"
    cached = @upgrade_pokemon_icon_cache[cache_key]
    return cached if cached && !cached.disposed?
    source = nil
    ["#{key}_IDLE", "#{key}_Idle", "#{key}_idle", key].each do |name|
      source = PokemonSurvivor.load_bitmap(PokemonSurvivor::HERO_DIR, name)
      break if source && !source.disposed?
    end
    return nil if !source || source.disposed?
    directions = PokemonSurvivor.eight_direction_hero?(key) ? PokemonSurvivor::CHARSET_8_DIRECTIONS : PokemonSurvivor::CHARSET_DIRECTIONS
    direction = directions >= PokemonSurvivor::CHARSET_8_DIRECTIONS ? PokemonSurvivor::DIR8_DOWN : PokemonSurvivor::DIR_DOWN
    src = PokemonSurvivor.charset_rect(source, direction, 0, directions)
    size = 32
    icon = Bitmap.new(size, size)
    scale = [size.to_f / [src.width, src.height].max, 1.0].min
    dest_w = [(src.width * scale).round, 1].max
    dest_h = [(src.height * scale).round, 1].max
    dest = Rect.new((size - dest_w) / 2, (size - dest_h) / 2, dest_w, dest_h)
    icon.stretch_blt(dest, source, src)
    @upgrade_pokemon_icon_cache[cache_key] = icon
    icon
  rescue
    icon.dispose if icon && !icon.disposed?
    nil
  ensure
    if source
      PokemonSurvivor.unregister_eight_direction_bitmap(source)
      source.dispose if !source.disposed?
    end
  end

  def draw_upgrade_level_badge(bitmap, upgrade, x, y, w, h, color)
    if upgrade[:breach_card] && !upgrade[:skill] && !upgrade[:target_skill]
      draw_battle_pass_scrolling_text(bitmap, upgrade[:badge_text].to_s, x, y, w, h, color, Color.new(40, 40, 48), 2)
      return
    end
    text = _INTL("Lv.{1}/{2}", @upgrade_levels[upgrade[:id]].to_i, upgrade[:max])
    icon = cached_upgrade_pokemon_icon(upgrade_primary_hero_key(upgrade))
    if icon && !icon.disposed?
      pbSetSystemFont(bitmap)
      icon_w = icon.width.to_i
      icon_h = icon.height.to_i
      text_w = (bitmap.text_size(text.to_s).width + 6 rescue 56)
      text_w = [[text_w, 56].max, w.to_i].min
      pbDrawTextPositions(bitmap, [[text, x, y, false, color, Color.new(40, 40, 48)]])
      icon_x = x.to_i + w.to_i - icon_w + 14
      icon_y = y.to_i + ((h.to_i - icon_h) / 2) - 5
      bitmap.blt(icon_x, icon_y, icon, Rect.new(0, 0, icon_w, icon_h))
    else
      draw_text_box(bitmap, text, x, y, w, h, color)
    end
  rescue
    draw_text_box(bitmap, _INTL("Lv.{1}/{2}", @upgrade_levels[upgrade[:id]].to_i, upgrade[:max]), x, y, w, h, color)
  end

  def rarity_color(rarity)
    case rarity
    when :uncommon   then Color.new(122, 255, 176)
    when :rare       then Color.new(92, 188, 255)
    when :super_rare then Color.new(255, 210, 92)
    when :epic       then Color.new(190, 126, 255)
    when :legendary  then Color.new(255, 132, 64)
    else Color.new(222, 226, 236)
    end
  end

  def clear_overlay_area(bitmap, x, y, w, h)
    return if w.to_i <= 0 || h.to_i <= 0
    alpha = tower_mode? && @tower_fade_alpha.to_i >= 255 ? 255 : 105
    bitmap.fill_rect(x.to_i, y.to_i, w.to_i, h.to_i, Color.new(0, 0, 0, alpha))
  rescue
  end

  def draw_upgrade_card(bitmap, upgrade, x, y, w, h, selected, anim_progress = 1.0, closing = 0.0, chosen = false, ban_progress = 0.0)
    disabled = (upgrade[:breach_card] && upgrade[:breach_disabled]) || upgrade[:porygon_excluded]
    selected = false if disabled && !upgrade[:porygon_excluded]
    skill = upgrade_skill_data(upgrade)
    type = skill ? skill[:type] : nil
    rarity = upgrade_rarity(upgrade)
    rarity_col = rarity_color(rarity)
    accent = skill ? type_color(type) : Color.new(180, 188, 202)
    category_fill = skill ? Color.new([accent.red / 2 + 34, 255].min, [accent.green / 2 + 34, 255].min, [accent.blue / 2 + 34, 255].min) : Color.new(68, 74, 86)
    pulse = selected ? ((Math.sin((System.uptime rescue 0.0) * 8.0) + 1.0) * 0.5) : 0.0
    bg = selected ? Color.new(46 + (pulse * 14).to_i, 64 + (pulse * 16).to_i, 98 + (pulse * 18).to_i) : Color.new(18, 29, 48)
    border = rarity_col
    if upgrade[:breach_card] && (upgrade[:breach_color] || skill)
      accent = Color.new(*upgrade[:breach_color]) if upgrade[:breach_color]
      border = accent
      rarity_col = accent
      category_fill = Color.new(accent.red * 0.30, accent.green * 0.30, accent.blue * 0.30)
      strength = selected ? 0.22 + pulse * 0.08 : 0.10
      bg = Color.new(18 + accent.red * strength, 22 + accent.green * strength, 28 + accent.blue * strength)
    end
    if disabled
      rarity_col = Color.new(124, 128, 136)
      accent = Color.new(70, 74, 82)
      category_fill = Color.new(38, 41, 48)
      bg = Color.new(24, 27, 34)
      border = Color.new(68, 72, 80)
      if upgrade[:porygon_excluded] && selected
        border = Color.new(184, 190, 202)
        bg = Color.new(40, 44, 54)
      end
    end
    draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(3, 6, 13))
    draw_pixel_round_rect(bitmap, x + 1, y + 1, w - 2, h - 2, border)
    draw_pixel_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, Color.new(8, 13, 26))
    draw_pixel_round_rect(bitmap, x + 3, y + 3, w - 6, h - 6, bg)
    bitmap.fill_rect(x + 7, y + 6, w - 14, 3, brighten_color(accent, 22))
    if PokemonSurvivor.color_accessibility_enabled? && !upgrade[:breach_card]
      rank = [:common, :uncommon, :rare, :epic, :super_rare, :legendary].index(rarity) || 0
      (rank + 1).times { |i| bitmap.fill_rect(x + 1, y + 14 + i * 7, 3, 4, Color.new(245, 245, 245)) }
    end
    draw_soft_badge(bitmap, x + 8, y + 50, w - 16, 24, category_fill)
    title_color = rarity_col
    if upgrade[:breach_card]
      draw_battle_pass_scrolling_text(bitmap, upgrade[:name], x + 8, y + 14, w - 16, 26, title_color)
    else
      draw_text_box(bitmap, upgrade[:name], x + 8, y + 14, w - 16, 26, title_color)
    end
    category = skill ? _INTL("{1} Skill", type_name(type)) : _INTL("Passive")
    category = upgrade[:category_label] if upgrade[:breach_card]
    if upgrade[:breach_card]
      draw_battle_pass_scrolling_text(bitmap, category, x + 12, y + 53, w - 24, 24, disabled ? rarity_col : Color.white, Color.new(40, 40, 48), 2)
    else
      draw_text_box(bitmap, category, x + 12, y + 53, w - 24, 24, Color.white, Color.new(40, 40, 48), 2)
    end
    description_y = 120
    if upgrade[:breach_card] && upgrade[:badge_text].to_s.empty?
      description_y = 84
    else
      draw_upgrade_level_badge(bitmap, upgrade, x + 10, y + 82, w - 20, 24, Color.new(122, 255, 176))
      bitmap.fill_rect(x + 8, y + 108, w - 16, 2, accent)
    end
    draw_scrolling_wrapped_text(bitmap, upgrade[:desc], x + 10, y + description_y, w - 20, h - description_y - 10, 22, disabled ? rarity_col : Color.new(220, 226, 240), Color.new(40, 40, 48), selected && closing <= 0.0 ? [:upgrade, upgrade[:id]] : nil)
    if ban_progress.to_f > 0
      fill_h = [(h * ban_progress.to_f).round, h].min
      red_y = y + h - fill_h
      bitmap.fill_rect(x + 3, red_y, w - 6, fill_h, Color.new(150, 18, 34))
      bitmap.fill_rect(x + 5, red_y + 1, w - 10, [fill_h - 2, 1].max, Color.new(210, 34, 58)) if fill_h > 3
      bitmap.fill_rect(x + 6, red_y, w - 12, 3, Color.new(255, 126, 132)) if fill_h > 4
    end
    if chosen && closing > 0
      burn_h = [(h * (closing ** 1.12)).to_i, h - 6].min
      ember_h = [(h * ([closing - 0.08, 0.0].max ** 1.05)).to_i, h - 8].min
      erase_y = y + h - 5 - burn_h
      ember_y = y + h - 3 - ember_h
      if burn_h > 0
        clear_overlay_area(bitmap, x - 2, erase_y, w + 4, burn_h + 6)
      end
      if ember_h > 0 && ember_y > y + 4
        bitmap.fill_rect(x + 6, ember_y, w - 12, 3, Color.new(255, 238, 160))
        bitmap.fill_rect(x + 9, ember_y + 3, w - 18, 2, Color.new(255, 154, 62))
        flicker = ((System.uptime rescue 0.0) * 40).to_i % 12
        sx = x + 10 + flicker
        while sx < x + w - 10
          bitmap.fill_rect(sx, ember_y - 1, 1, 5, Color.new(255, 196, 96))
          sx += 24
        end
      end
    end
  rescue
  end


  def draw_upgrade_action_helper(bitmap, mode, progress, choose_out)
    slide = if mode == :choose
              1.0 - choose_out.to_f
            elsif mode == :in
              progress.to_f
            else
              1.0
            end
    slide = [[slide, 0.0].max, 1.0].min
    return if slide <= 0.0
    y = (Graphics.height - 34 + ((1.0 - slide) * 38)).round
    helper_alpha = tower_mode? && @tower_fade_alpha.to_i >= 255 ? 255 : 145
    draw_pixel_round_rect(bitmap, 8, y - 2, Graphics.width - 16, 28, Color.new(0, 0, 0, helper_alpha))
    reroll_text = _INTL("Hold Reroll: {1}", @rerolls_left.to_i)
    ban_text = _INTL("Hold Ban: {1}", @bans_left.to_i)
    segments = [[:left, ""], [:right, _INTL("Upgrade")], [:confirm, _INTL("Choose")], [:action, reroll_text], [:ready_menu, ban_text]]
    if defined?(ControlHelpText)
      ControlHelpText.draw_segments(bitmap, segments, 16, y + 4, 2, Color.white, Color.new(40, 40, 48), Graphics.width - 32)
    else
      PokemonSurvivor.draw_text_center(bitmap, _INTL("Choose / Hold Reroll: {1} / Hold Ban: {2}", @rerolls_left.to_i, @bans_left.to_i), 0, y + 2, Graphics.width, Color.white)
    end
  rescue
  end

  def draw_upgrade
    draw_game(false)
    bmp = @sprites["overlay"].bitmap
    pbSetSystemFont(bmp)
    x = 28
    y = 44
    w = Graphics.width - 56
    h = Graphics.height - y - 48
    now = System.uptime rescue 0.0
    mode = @upgrade_anim_mode
    progress = [[(now - @upgrade_anim_start.to_f) / 0.24, 0.0].max, 1.0].min
    choose_elapsed = mode == :choose ? (now - @upgrade_anim_start.to_f) : 0.0
    choose_out = [[choose_elapsed / 0.28, 0.0].max, 1.0].min
    center_progress = [[(choose_elapsed - 0.28) / 0.22, 0.0].max, 1.0].min
    consume = [[(choose_elapsed - 0.50) / 0.42, 0.0].max, 1.0].min
    veil_alpha = mode == :in ? (105 * progress).to_i : 105
    if tower_mode? && @tower_fade_alpha.to_i >= 255
      veil_alpha = 255
    elsif tower_mode? && @tower_fade_alpha.to_i > 0
      veil_alpha = [veil_alpha, @tower_fade_alpha.to_i].max
    end
    bmp.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0, veil_alpha))
    if mode != :choose || choose_out < 1.0
      panel_y = y + (mode == :choose ? (choose_out * 42).to_i : 0)
      draw_panel(bmp, x, panel_y, w, h, Color.new(122, 255, 176), Color.new(19, 31, 53))
      title_x = x + 16
      title_y = panel_y + 12
      title_w = w - 32
      title_h = 34
      draw_pixel_round_rect(bmp, title_x, title_y, title_w, title_h, Color.new(8, 13, 26))
      PokemonSurvivor.draw_text_center(bmp, _INTL("Choose an upgrade"), title_x, title_y + 9, title_w, Color.new(255, 238, 160))
    end
    card_w = (w - 34) / 3
    card_h = h - 66
    @upgrade_options.each_with_index do |upgrade, i|
      cx = x + 10 + (i * (card_w + 7))
      cy = y + 48
      selected = (i == @upgrade_index)
      if mode == :in
        cy += ((1.0 - progress) * (36 + (i * 16))).to_i
      elsif mode == :choose
        if i == (@chosen_upgrade_index || @upgrade_index)
          target_x = x + ((w - card_w) / 2)
          target_y = y + 52
          ease = center_progress * center_progress * (3.0 - (2.0 * center_progress))
          cx = (cx + ((target_x - cx) * ease)).to_i
          cy = (cy + ((target_y - cy) * ease)).to_i
          cx += (Math.sin(consume * Math::PI * 8.0) * (1.0 - consume) * 4).to_i if consume > 0
        else
          cy += (choose_out * (Graphics.height - cy + 42 + (i * 16))).to_i
        end
      end
      next if mode == :choose && i != (@chosen_upgrade_index || @upgrade_index) && choose_out >= 1.0
      hold_reroll = upgrade_hold_progress(:reroll)
      hold_ban = (i == @upgrade_index) ? upgrade_hold_progress(:ban) : 0.0
      if hold_reroll > 0.0
        amp = (hold_reroll * 8).ceil
        cx += (Math.sin(((System.uptime rescue 0.0) * 42.0) + (i * 1.7)) * amp).to_i
        cy += (Math.cos(((System.uptime rescue 0.0) * 34.0) + i) * [hold_reroll * 3, 1].max).to_i
      elsif hold_ban > 0.0
        amp = (hold_ban * 6).ceil
        cx += (Math.sin((System.uptime rescue 0.0) * 46.0) * amp).to_i
      end
      draw_upgrade_card(bmp, upgrade, cx, cy, card_w, card_h, selected, progress, consume, mode == :choose && i == (@chosen_upgrade_index || @upgrade_index), hold_ban)
    end
    draw_upgrade_action_helper(bmp, mode, progress, choose_out)
    draw_tv_filter(bmp)
  end

  def active_run_bonus_entries
    return [] if !@upgrade_levels
    levels = @upgrade_levels
    ids = levels.keys.select { |id| levels[id].to_i > 0 }
    pool = PokemonSurvivor.localized_upgrade_pool
    by_id = {}
    pool.each { |upgrade| by_id[upgrade[:id]] = upgrade if upgrade && upgrade[:id] }
    ordered = []
    pool.each do |upgrade|
      next if !upgrade || !ids.include?(upgrade[:id])
      ordered << upgrade
    end
    ids.each do |id|
      next if by_id[id]
      ordered << { id: id, name: id.to_s.gsub("_", " ").split.map(&:capitalize).join(" "), max: levels[id].to_i, rarity: :common }
    end
    if respond_to?(:sleep_event_data)
      (@sleep_event_awakened_keys || []).each do |key|
        data = sleep_event_data(key)
        next if !data || data.empty?
        ordered << { id: PokemonSurvivor.species_key(key), name: data[:name].to_s, max: 1, rarity: :epic, run_event: true, level_text: _INTL("Active") }
      end
    end
    ordered
  rescue
    []
  end

  def run_bonus_stat_percent(multiplier, inverse = false)
    value = multiplier.to_f
    value = 1.0 if value <= 0
    percent = inverse ? ((1.0 - value) * 100.0) : ((value - 1.0) * 100.0)
    sign = percent >= 0 ? "+" : ""
    _INTL("{1}{2}%", sign, percent.round)
  rescue
    _INTL("+0%")
  end

  def active_run_stat_entries
    speed_base = @hero_base_speed.to_f > 0 ? @hero_base_speed.to_f : (@hero ? @hero.speed.to_f : 1.0)
    speed_mult = @hero ? (@hero.speed.to_f / speed_base) : 1.0
    post_mult = respond_to?(:post_100_bonus_multiplier) ? post_100_bonus_multiplier.to_f : 1.0
    entries = []
    entries << [_INTL("Damage"), run_bonus_stat_percent(effective_run_damage_multiplier * post_mult)]
    entries << [_INTL("Recharge"), run_bonus_stat_percent(@cooldown_mult || 1.0, true)]
    entries << [_INTL("Projectiles"), _INTL("+{1}", @projectile_count_bonus.to_i)]
    entries << [_INTL("Move Speed"), run_bonus_stat_percent(speed_mult)]
    entries << [_INTL("XP Pickup"), run_bonus_stat_percent(@pickup_mult || 1.0)]
    entries << [_INTL("XP Gain"), run_bonus_stat_percent(effective_run_xp_multiplier)]
    entries << [_INTL("Contact Guard"), run_bonus_stat_percent((@shield_mult || 1.0) * (@equipment_contact_mult || 1.0) * mewtwo_guard_multiplier, true)]
    entries << [_INTL("Projectile Guard"), run_bonus_stat_percent((@shield_mult || 1.0) * (@enemy_projectile_shield_mult || 1.0) * mewtwo_guard_multiplier, true)]
    entries << [_INTL("Burst Charge"), run_bonus_stat_percent(@burst_charge_mult || 1.0)]
    entries << [_INTL("Status Duration"), run_bonus_stat_percent(@status_duration_mult || 1.0)]
    entries << [_INTL("Boss Damage"), run_bonus_stat_percent(@boss_damage_mult || 1.0)]
    if @vampiric_chance.to_f > 0
      chance = (1.0 / @vampiric_chance.to_f).round rescue 0
      heal = (@vampiric_heal_rate.to_f * 100.0).round(1)
      entries << [_INTL("Vampirism"), _INTL("1/{1}  {2}%", chance, heal)]
    end
    entries
  rescue
    []
  end

  def draw_run_bonus_panel(bitmap)
    slide = @run_bonus_panel_slide.to_f
    return if slide <= 0.0
    slide = [[slide, 0.0].max, 1.0].min
    pbSetSystemFont(bitmap)
    panel_w = [Graphics.width - 32, 248].min
    panel_h = [Graphics.height - 76, 326].min
    x = (-panel_w + 10 + ((panel_w + 2) * slide)).round
    y = 68
    alpha = (178 * slide).round
    mode = (@run_bonus_panel_mode == :stats) ? :stats : :bonuses
    title = mode == :stats ? _INTL("Run Stats") : _INTL("Run Bonuses")
    draw_soft_badge(bitmap, x, y, panel_w, panel_h, Color.new(6, 10, 20, alpha))
    draw_soft_badge(bitmap, x + 4, y + 4, panel_w - 8, 26, Color.new(18, 32, 58, (210 * slide).round))
    PokemonSurvivor.draw_text_center(bitmap, title, x + 10, y + 9, panel_w - 20, Color.new(255, 238, 160, (255 * slide).round), Color.new(36, 36, 44, (255 * slide).round))
    body_x = x + 8
    body_y = y + 36
    body_w = panel_w - 16
    body_h = panel_h - 62
    mode == :stats ? draw_run_bonus_stats_panel_body(bitmap, body_x, body_y, body_w, body_h, slide) : draw_run_bonus_list_panel_body(bitmap, body_x, body_y, body_w, body_h, slide)
    footer_y = y + panel_h - 25
    draw_soft_badge(bitmap, x + 8, footer_y, panel_w - 16, 22, Color.new(0, 0, 0, (120 * slide).round))
    panel_setting = PokemonSurvivor.run_info_panel_mode rescue :stats
    label = (panel_setting == :both && mode == :bonuses) ? _INTL("Stats") : _INTL("Hide")
    if defined?(ControlHelpText)
      ControlHelpText.draw_segments(bitmap, [[:action, label]], x + 18, footer_y + 2, 2, Color.new(220, 226, 240, (255 * slide).round), Color.new(32, 32, 40, (255 * slide).round), panel_w - 36)
    else
      PokemonSurvivor.draw_text_center(bitmap, _INTL("A: {1}", label), x + 12, footer_y + 2, panel_w - 24, Color.new(220, 226, 240, (255 * slide).round), Color.new(32, 32, 40, (255 * slide).round))
    end
  rescue
  end

  def run_bonus_panel_surface(width, height)
    surface = @run_bonus_panel_surface
    if !surface || surface.disposed? || surface.width != width || surface.height != height
      surface.dispose if surface && !surface.disposed?
      surface = @run_bonus_panel_surface = Bitmap.new(width, height)
    else
      surface.clear
    end
    surface
  end

  def draw_run_bonus_list_panel_body(bitmap, body_x, body_y, body_w, body_h, slide)
    entries = active_run_bonus_entries
    if entries.empty?
      draw_soft_badge(bitmap, body_x, body_y, body_w, 32, Color.new(12, 20, 34, (190 * slide).round))
      PokemonSurvivor.draw_text_center(bitmap, _INTL("No run bonuses yet."), body_x + 6, body_y + 8, body_w - 12, Color.new(198, 214, 236, (255 * slide).round), Color.new(34, 34, 42, (255 * slide).round))
      return
    end
    row_h = 28
    content_h = entries.length * row_h
    offset = scroll_offset([content_h - body_h, 0].max, 12.0)
    tmp = run_bonus_panel_surface(body_w, body_h)
    pbSetSystemFont(tmp)
    entries.each_with_index do |upgrade, i|
      row_y = (i * row_h) - offset
      next if row_y > body_h || row_y + row_h < 0
      level = @upgrade_levels[upgrade[:id]].to_i
      max = [upgrade[:max].to_i, level].max
      level_text = upgrade[:run_event] ? (upgrade[:level_text] || _INTL("Active")) : _INTL("Lv.{1}/{2}", level, max)
      rarity = upgrade_rarity(upgrade)
      accent = rarity_color(rarity)
      fill = Color.new([accent.red / 5 + 10, 255].min, [accent.green / 5 + 14, 255].min, [accent.blue / 5 + 22, 255].min, (150 * slide).round)
      draw_soft_badge(tmp, 0, row_y + 1, body_w, row_h - 3, fill)
      draw_text_box(tmp, upgrade[:name], 7, row_y + 5, body_w - 54, 20, accent, Color.new(24, 24, 32))
      level_w = tmp.text_size(level_text.to_s).width rescue 0
      pbDrawTextPositions(tmp, [[level_text.to_s, body_w - level_w - 7, row_y + 5, false, Color.new(122, 255, 176), Color.new(24, 24, 32)]])
    end
    bitmap.blt(body_x, body_y, tmp, Rect.new(0, 0, body_w, body_h), (255 * slide).round)
  rescue
  end

  def draw_run_bonus_stats_panel_body(bitmap, body_x, body_y, body_w, body_h, slide)
    entries = active_run_stat_entries
    row_h = 26
    content_h = entries.length * row_h
    offset = scroll_offset([content_h - body_h, 0].max, 10.0)
    tmp = run_bonus_panel_surface(body_w, body_h)
    pbSetSystemFont(tmp)
    entries.each_with_index do |entry, i|
      row_y = (i * row_h) - offset
      next if row_y > body_h || row_y + row_h < 0
      accent = i.even? ? Color.new(92, 188, 255) : Color.new(122, 255, 176)
      fill = i.even? ? Color.new(13, 24, 42, (150 * slide).round) : Color.new(12, 30, 31, (150 * slide).round)
      draw_soft_badge(tmp, 0, row_y + 1, body_w, row_h - 3, fill)
      value_w = 76
      value_x = body_w - value_w - 6
      draw_text_box(tmp, entry[0], 7, row_y + 4, value_x - 12, 20, Color.new(220, 226, 240), Color.new(24, 24, 32))
      value_text = entry[1].to_s
      value_text_w = tmp.text_size(value_text).width rescue 0
      pbDrawTextPositions(tmp, [[value_text, value_x + value_w - value_text_w, row_y + 4, false, accent, Color.new(24, 24, 32)]])
    end
    bitmap.blt(body_x, body_y, tmp, Rect.new(0, 0, body_w, body_h), (255 * slide).round)
  rescue
  end

  def draw_pause
    draw_game(false)
    bmp = @sprites["overlay"].bitmap
    pbSetSystemFont(bmp)
    x = 96
    y = 92
    w = Graphics.width - 192
    h = endless_mode? ? 218 : 176
    y = (Graphics.height - h) / 2 if endless_mode?
    bmp.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0, 96))
    draw_panel(bmp, x, y, w, h, Color.new(255, 224, 92), Color.new(20, 32, 54))
    PokemonSurvivor.draw_text_center(bmp, _INTL("Paused"), x, y + 24, w, Color.new(255, 238, 160))
    options = [_INTL("Continue"), _INTL("Give Up")]
    options << _INTL("Self-Destruct") if endless_mode?
    options.each_with_index do |text, i|
      oy = y + 72 + (i * 42)
      selected = (i == @pause_index)
      locked = i == 2 && @timer.to_f < 600.0
      if i == 0
        fill = selected ? Color.new(44, 92, 84) : Color.new(20, 54, 56)
        accent = selected ? Color.new(142, 255, 202) : Color.new(86, 186, 168)
      elsif i == 2
        fill = selected ? Color.new(108, 66, 24) : Color.new(58, 37, 18)
        accent = selected ? Color.new(255, 202, 100) : Color.new(218, 152, 68)
      else
        fill = selected ? Color.new(104, 48, 58) : Color.new(58, 24, 36)
        accent = selected ? Color.new(255, 154, 142) : Color.new(196, 82, 92)
      end
      if locked
        fill = Color.new(40, 40, 46)
        accent = Color.new(112, 112, 124)
      end
      draw_modern_button_frame(bmp, x + 34, oy, w - 68, 32, accent, fill, brighten_color(accent, 32), selected)
      text_color = locked ? Color.new(144, 144, 156) : (selected ? brighten_color(accent, 24) : Color.white)
      draw_text_box(bmp, text, x + 42, oy + 5, w - 84, 22, text_color, Color.new(32, 32, 40), 2)
    end
    draw_help(bmp, [[:up, ""], [:down, _INTL("Select")], [:confirm, _INTL("Choose")], [:cancel, _INTL("Continue")]])
    draw_tv_filter(bmp)
  end

  def draw_gameover
    summary = seasonal_run_result_data if respond_to?(:seasonal_run_result_data)
    return draw_seasonal_run_result(summary) if summary
    stats = competitive_run_stats
    bmp = @sprites["screen"].bitmap
    over = @sprites["overlay"].bitmap
    bmp.clear
    over.clear
    @screen_w = Graphics.width
    @screen_h = Graphics.height
    draw_world_background(bmp) rescue draw_menu_background(bmp)
    pbSetSystemFont(over)
    x = 44
    y = 58
    w = Graphics.width - 88
    h = Graphics.height - 112
    accent = (@result_text == _INTL("You survived!")) ? Color.new(122, 255, 176) : Color.new(255, 224, 92)
    draw_panel(over, x, y, w, h, accent, Color.new(20, 32, 54))
    PokemonSurvivor.draw_text_center(over, @result_text || _INTL("Survival ended."), x + 18, y + 26, w - 36, accent)
    score_y = y + 76
    draw_soft_badge(over, x + 56, score_y, w - 112, 48, Color.new(10, 17, 31))
    PokemonSurvivor.draw_text_center(over, _INTL("Score {1}", stats[:score]), x + 56, score_y + 15, w - 112, Color.new(255, 238, 160))
    stat_y = y + 142
    stat_w = (w - 72) / 3
    draw_result_stat(over, x + 20, stat_y, stat_w, _INTL("Level"), stats[:level].to_s, Color.new(122, 255, 176))
    draw_result_stat(over, x + 36 + stat_w, stat_y, stat_w, _INTL("KOs"), stats[:kills].to_s, Color.new(255, 132, 96))
    time = stats[:seconds].to_i
    time_text = _INTL("{1}:{2}", (time / 60).to_s.rjust(2, "0"), (time % 60).to_s.rjust(2, "0"))
    draw_result_stat(over, x + 52 + (stat_w * 2), stat_y, stat_w, _INTL("Time"), time_text, Color.new(92, 188, 255))
    if @run_unlock_messages && !@run_unlock_messages.empty?
      unlock_y = stat_y + 64
      draw_soft_badge(over, x + 20, unlock_y, w - 40, 48, Color.new(10, 17, 31))
      draw_scrolling_wrapped_text(over, @run_unlock_messages.join("  "), x + 30, unlock_y + 14, w - 60, 24, 24, Color.new(122, 255, 176))
    end
    draw_leaderboard_share_prompt(over) if @leaderboard_share_pending
    help = @leaderboard_share_pending ? [[:left, ""], [:right, _INTL("Choice")], [:confirm, _INTL("Choose")], [:cancel, _INTL("No")]] : [[:confirm, _INTL("Pokemon")]]
    draw_help(over, help)
    draw_tv_filter(over)
  end

  # Seasonal results use the ordinary result panels, stat boxes and helpers.
  def draw_seasonal_run_result(summary)
    bmp, over = @sprites["screen"].bitmap, @sprites["overlay"].bitmap
    bmp.clear
    over.clear
    @screen_w, @screen_h = Graphics.width, Graphics.height
    draw_world_background(bmp)
    pbSetSystemFont(over)
    classic = summary[:classic_layout]
    x, y, w, h = 44, classic ? 58 : 18, Graphics.width - 88, Graphics.height - (classic ? 112 : 64)
    accent = Color.new(255, 224, 92)
    shadow = Color.new(40, 40, 48)
    draw_panel(over, x, y, w, h, accent, Color.new(20, 32, 54))
    draw_battle_pass_scrolling_text(over, summary[:title], x + 18, y + (classic ? 26 : 10), w - 36, 24, accent, shadow, 2)
    if classic
      draw_soft_badge(over, x + 56, y + 76, w - 112, 48, Color.new(10, 17, 31))
      draw_battle_pass_scrolling_text(over, summary[:primary], x + 66, y + 91, w - 132, 24, Color.new(255, 238, 160), shadow, 2)
    else
      draw_soft_badge(over, x + 20, y + 42, w - 40, 58, Color.new(10, 17, 31))
      draw_battle_pass_scrolling_text(over, summary[:primary], x + 30, y + 47, w - 60, 24, Color.new(255, 238, 160), shadow, 2)
      draw_battle_pass_scrolling_text(over, summary[:subtitle], x + 30, y + 75, w - 60, 20, Color.new(198, 214, 236), shadow, 2)
    end
    colors = [Color.new(122, 255, 176), Color.new(255, 132, 96), Color.new(92, 188, 255)]
    stat_w = (w - 72) / 3
    summary[:stats].each_with_index do |entry, i|
      draw_result_stat(over, x + 20 + (stat_w + 16) * (i % 3), y + (classic ? 142 : 112) + (i / 3) * 64,
        stat_w, entry[0], entry[1].to_s, colors[i % 3])
    end
    reward_y = y + h - (classic ? 66 : 78)
    draw_soft_badge(over, x + 20, reward_y, w - 40, classic ? 24 : 30, Color.new(10, 17, 31))
    message = summary[:rewards]
    message += "  " + @run_unlock_messages.join("  ") if @run_unlock_messages && !@run_unlock_messages.empty?
    draw_battle_pass_scrolling_text(over, message, x + 30, reward_y + (classic ? 1 : 4), w - 60, 22, colors[0], shadow, 2)
    actions = summary[:actions]
    button_w = (w - 40 - (actions.length - 1) * 8) / actions.length
    actions.each_with_index do |label, i|
      bx, by = x + 20 + i * (button_w + 8), y + h - 38
      selected = i == summary[:index]
      draw_modern_button_frame(over, bx, by, button_w, 28, accent,
        selected ? Color.new(75, 89, 119) : Color.new(38, 48, 70), accent, selected)
      draw_battle_pass_scrolling_text(over, label, bx + 6, by + 4, button_w - 12, 20,
        selected ? accent : Color.white, shadow, 2)
    end
    help = actions.length > 1 ? [[:left, ""], [:right, _INTL("Choice")]] : []
    draw_help(over, help + [[:confirm, _INTL("Confirm")], [:cancel, _INTL("Return")]])
    draw_tv_filter(over)
  end

  def draw_leaderboard_share_prompt(bitmap)
    w = [Graphics.width - 110, 420].min
    h = 116
    x = (Graphics.width - w) / 2
    y = Graphics.height - 188
    draw_soft_badge(bitmap, x, y, w, h, Color.new(18, 29, 50))
    bitmap.fill_rect(x + 24, y + 16, w - 48, 2, Color.new(92, 188, 255))
    draw_text_box_ellipsis(bitmap, _INTL("Share this result online?"), x + 18, y + 24, w - 36, 22, Color.new(255, 238, 160), Color.new(40, 40, 48), 2)
    stats = competitive_run_stats
    score_text = _INTL("Score {1} / Lv. {2}", stats[:score], stats[:level])
    draw_text_box_ellipsis(bitmap, score_text, x + 18, y + 48, w - 36, 22, Color.new(198, 214, 236), Color.new(40, 40, 48), 2)
    bw = (w - 58) / 2
    by = y + 76
    draw_leaderboard_share_button(bitmap, x + 20, by, bw, 28, _INTL("Yes"), @leaderboard_share_index.to_i == 0, Color.new(54, 118, 84), Color.new(122, 255, 176))
    draw_leaderboard_share_button(bitmap, x + 38 + bw, by, bw, 28, _INTL("No"), @leaderboard_share_index.to_i == 1, Color.new(126, 58, 62), Color.new(255, 142, 132))
  rescue
  end

  def draw_leaderboard_share_button(bitmap, x, y, w, h, label, selected, fill, shine)
    fill = Color.new([fill.red + 32, 255].min, [fill.green + 32, 255].min, [fill.blue + 32, 255].min) if selected
    draw_modern_button_frame(bitmap, x, y, w, h, shine, fill, shine, selected)
    draw_text_box_ellipsis(bitmap, label, x + 8, y + 6, w - 16, 20, selected ? Color.new(255, 238, 160) : Color.white, Color.new(30, 30, 38), 2)
  rescue
  end
  def draw_result_stat(bitmap, x, y, w, label, value, accent)
    base = Color.new([accent.red / 3 + 20, 255].min, [accent.green / 3 + 26, 255].min, [accent.blue / 3 + 38, 255].min)
    dark = Color.new([base.red - 18, 0].max, [base.green - 18, 0].max, [base.blue - 18, 0].max)
    light = brighten_color(accent, 18)
    draw_soft_badge(bitmap, x, y, w, 58, dark)
    draw_soft_badge(bitmap, x + 2, y + 2, w - 4, 54, base)
    bitmap.fill_rect(x + 8, y + 6, w - 16, 3, light)
    bitmap.fill_rect(x + 8, y + 50, w - 16, 2, Color.new([dark.red - 8, 0].max, [dark.green - 8, 0].max, [dark.blue - 8, 0].max))
    draw_text_box(bitmap, label, x + 8, y + 13, w - 16, 20, Color.new(226, 234, 246), Color.new(24, 24, 32), 2)
    draw_text_box(bitmap, value, x + 8, y + 34, w - 16, 20, Color.white, Color.new(24, 24, 32), 2)
  rescue
  end

  def draw_help(bitmap, segments)
    pbSetSystemFont(bitmap)
    y = Graphics.height - 30
    draw_pixel_round_rect(bitmap, 8, y - 2, Graphics.width - 16, 26, Color.new(0, 0, 0, 155))
    if defined?(ControlHelpText)
      ControlHelpText.draw_segments(bitmap, segments, 16, y + 3, 2, Color.white, Color.new(40, 40, 48), Graphics.width - 32)
    else
      PokemonSurvivor.draw_text_center(bitmap, _INTL("Confirm / Back"), 0, y + 1, Graphics.width, Color.white)
    end
  rescue
  end

end















































