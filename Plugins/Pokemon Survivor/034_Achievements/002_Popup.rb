#===============================================================================
# Pokemon Survivor Achievements - achievement popup
#===============================================================================
module PokemonSurvivorAchievementPopup
  WIDTH = 260
  HEIGHT = 58
  LIFE_FRAMES = 168
  SLIDE_FRAMES = 16
  MAX_QUEUE = 8

  module_function

  def queue(data)
    return if !data.is_a?(Hash)
    @queue ||= []
    return if @queue.any? { |entry| entry[:id] == data[:id] }
    return if @current && @current[:id] == data[:id]
    @queue << data
    @queue.shift while @queue.length > MAX_QUEUE
  rescue
  end

  def update
    start_next if !@current && @queue && @queue.length > 0
    return if !@current
    ensure_sprite
    @frame = @frame.to_i + 1
    apply_motion
    finish_current if @frame >= LIFE_FRAMES
  rescue
    dispose
  end

  def play_popup_se
    volume = defined?(PokemonSurvivor::UI_DECISION_VOLUME) ? PokemonSurvivor::UI_DECISION_VOLUME : 64
    pbSEPlay("Survivor/Achievement", volume, 100) rescue nil
  rescue
  end

  def start_next
    @current = @queue.shift
    @frame = 0
    play_popup_se
    redraw
  rescue
  end

  def ensure_sprite
    return if @sprite && !@sprite.disposed?
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 999_999
    @sprite = Sprite.new(@viewport)
    redraw
  rescue
  end

  def redraw
    ensure_sprite if !@sprite || @sprite.disposed?
    @sprite.bitmap.dispose if @sprite.bitmap && !@sprite.bitmap.disposed?
    bmp = Bitmap.new(WIDTH, HEIGHT)
    pbSetSystemFont(bmp) rescue nil
    data = @current || {}
    rarity = data[:rarity].to_i
    accent = PokemonSurvivorAchievements.rarity_color(rarity) rescue Color.new(255, 216, 92)
    draw_round_rect(bmp, 0, 0, WIDTH, HEIGHT, Color.new(accent.red, accent.green, accent.blue, 224))
    draw_round_rect(bmp, 2, 2, WIDTH - 4, HEIGHT - 4, Color.new(8, 12, 22, 248))
    icon_cx = 34
    icon_cy = HEIGHT / 2
    draw_medal(bmp, icon_cx, icon_cy, rarity)
    title = _INTL("Achievement") rescue "Achievement"
    name = _INTL(data[:name].to_s) rescue data[:name].to_s
    text_x = 58
    text_w = WIDTH - text_x - 12
    draw_text_centered(bmp, title, text_x, 10, text_w, 18, Color.new(184, 196, 214), Color.new(24, 24, 32))
    draw_text_centered(bmp, name, text_x, 32, text_w, 20, accent, Color.new(24, 24, 32))
    @sprite.bitmap = bmp
    @sprite.z = 999_999
    apply_motion
  rescue
  end
  def apply_motion
    return if !@sprite || @sprite.disposed?
    phase_in = [@frame.to_f / SLIDE_FRAMES, 1.0].min
    phase_out = @frame > LIFE_FRAMES - SLIDE_FRAMES ? [(LIFE_FRAMES - @frame).to_f / SLIDE_FRAMES, 0.0].max : 1.0
    phase = [phase_in, phase_out].min
    target_x = Graphics.width - WIDTH - 12
    @sprite.x = target_x + ((1.0 - phase) * 42).round
    @sprite.y = 18
    @sprite.opacity = (255 * phase).round
  rescue
  end

  def finish_current
    @current = nil
    if @queue && @queue.length > 0
      start_next
    else
      dispose_sprite
    end
  rescue
  end

  def dispose_sprite
    @sprite.bitmap.dispose if @sprite && @sprite.bitmap && !@sprite.bitmap.disposed?
    @sprite.dispose if @sprite && !@sprite.disposed?
    @viewport.dispose if @viewport && !@viewport.disposed?
    @sprite = nil
    @viewport = nil
  rescue
  end

  def dispose
    dispose_sprite
    @current = nil
    @queue = []
  rescue
  end

  def draw_round_rect(bitmap, x, y, w, h, color)
    if defined?(PokemonSurvivor) && PokemonSurvivor.respond_to?(:draw_pixel_round_rect)
      PokemonSurvivor.draw_pixel_round_rect(bitmap, x, y, w, h, color)
      return
    end
    bitmap.fill_rect(x + 3, y, w - 6, h, color)
    bitmap.fill_rect(x, y + 3, w, h - 6, color)
  rescue
    bitmap.fill_rect(x, y, w, h, color) rescue nil
  end

  def draw_medal(bitmap, cx, cy, rarity)
    accent = PokemonSurvivorAchievements.rarity_color(rarity) rescue Color.new(255, 216, 92)
    medal = cached_medal(PokemonSurvivorAchievements.medal_name(rarity)) rescue nil
    if medal && !medal.disposed?
      mw = [(medal.width * 0.5).round, 1].max
      mh = [(medal.height * 0.5).round, 1].max
      bitmap.stretch_blt(Rect.new(cx - (mw / 2), cy - (mh / 2), mw, mh), medal, Rect.new(0, 0, medal.width, medal.height))
    else
      draw_round_rect(bitmap, cx - 8, cy - 8, 16, 16, accent)
    end
  rescue
  end
  def draw_popup_medal_socket(bitmap, cx, cy, accent)
    draw_round_rect(bitmap, cx - 22, cy - 21, 44, 42, Color.new(0, 0, 0, 100))
    draw_round_rect(bitmap, cx - 21, cy - 21, 42, 42, Color.new(accent.red, accent.green, accent.blue, 216))
    draw_round_rect(bitmap, cx - 18, cy - 18, 36, 36, Color.new(9, 13, 24, 238))
    draw_round_rect(bitmap, cx - 15, cy - 15, 30, 30, Color.new([accent.red / 3, 28].max, [accent.green / 3, 28].max, [accent.blue / 3, 34].max, 210))
  rescue
  end
  def cached_medal(name)
    @medal_cache ||= {}
    cached = @medal_cache[name]
    return cached if cached && !cached.disposed?
    path = "#{PokemonSurvivorAchievements::HUD_DIR}/#{name}"
    bmp = nil
    if defined?(AnimatedBitmap)
      bmp = AnimatedBitmap.new(path).bitmap rescue nil
    end
    if !bmp && defined?(RPG) && RPG.respond_to?(:Cache)
      bmp = RPG::Cache.load_bitmap(PokemonSurvivorAchievements::HUD_DIR + "/", name) rescue nil
    end
    @medal_cache[name] = bmp if bmp
    bmp
  rescue
    nil
  end

  def draw_text_centered(bitmap, text, x, y, w, h, color, shadow)
    temp = Bitmap.new(w, h)
    pbSetSystemFont(temp) rescue nil
    fitted = ellipsis_text(temp, text.to_s, w)
    width = temp.text_size(fitted).width rescue (fitted.length * 8)
    tx = [[(w - width) / 2, 0].max, w - 2].min
    pbDrawTextPositions(temp, [[fitted, tx, 0, false, color, shadow]]) rescue nil
    bitmap.blt(x, y, temp, Rect.new(0, 0, w, h))
    temp.dispose
  rescue
    draw_text(bitmap, text, x, y, w, h, color, shadow, false) rescue nil
  end
  def ellipsis_text(bitmap, text, max_w)
    text = text.to_s
    return text if (bitmap.text_size(text).width rescue text.length * 8) <= max_w
    suffix = "..."
    suffix_w = bitmap.text_size(suffix).width rescue 18
    limit = [max_w.to_i - suffix_w, 1].max
    chars = text.each_char.to_a
    while chars.length > 0
      candidate = chars.join
      return candidate + suffix if (bitmap.text_size(candidate).width rescue candidate.length * 8) <= limit
      chars.pop
    end
    suffix
  rescue
    text.to_s[0, [max_w.to_i / 8, 1].max] + "..."
  end
  def draw_text(bitmap, text, x, y, w, h, color, shadow, align_right = false)
    temp = Bitmap.new(w, h)
    pbSetSystemFont(temp) rescue nil
    pbDrawTextPositions(temp, [[text.to_s, align_right ? w - 2 : 0, 0, align_right, color, shadow]]) rescue nil
    bitmap.blt(x, y, temp, Rect.new(0, 0, w, h))
    temp.dispose
  rescue
  end
end
