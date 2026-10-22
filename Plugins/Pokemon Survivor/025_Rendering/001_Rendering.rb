#===============================================================================
# Pokemon Survivor - Bitmap caches, world rendering, entities and HUD
#===============================================================================

class Scene_PokemonSurvivor

  VFX_FRAME_COUNTS = {
    "VFX_PSYCHIC8" => 12,
    "VFX_GRASS6" => 12,
    "VFX_GRASS6_EX" => 5,
    "VFX_FIRE11" => 9,
    "VFX_FIGHTING7" => 9,
    "VFX_GRASS8" => 9,
    "VFX_FIRE10" => 5,
    "VFX_ICE6" => 1,
    "VFX_STEEL6" => 1,
    "VFX_STEEL7" => 10,
    "VFX_FAIRY7" => 20,
    "VFX_GHOST4" => 9,
    "VFX_PSYCHIC_WAIT" => 20,
    "VFX_PSYCHIC_WAIT2" => 5,
    "VFX_PSYCHIC6" => 8,
    "VFX_NULL" => 7,
    "VFX_DARK7" => 21,
    "VFX_PSYCHIC5" => 6,
    "VFX_PSYCHIC7" => 3,
    "VFX_NORMAL4" => 7,
    "VFX_FIRE8" => 9,
    "VFX_ELECTRIC4" => 13,
    "VFX_PSYCHIC4" => 11,
    "VFX_DARK6" => 18,
    "VFX_GRASS5" => 3,
    "VFX_ICE4" => 6,
    "VFX_FAIRY5" => 4,
    "VFX_FAIRY6" => 10,
    "VFX_ELECTRIC3" => 2,
    "VFX_POISON3" => 18,
    "VFX_POISON4" => 26,
    "VFX_POISON5" => 15,
    "VFX_DARK4" => 9,
    "VFX_FAIRY4" => 3,
    "VFX_FAIRY3" => 13,
    "VFX_GHOST3" => 2,
    "VFX_DRAGON5" => 12,
    "VFX_FLYING2" => 52,
    "VFX_FLYING3" => 52,
    "VFX_STEEL5" => 52,
    "VFX_GRASS_ORBIT2" => 8,
    "VFX_GRASS4" => 8,
    "VFX_LEVEL_UP_BURST" => 5,
    "VFX_EVOLUTION" => 16,
    "VFX_TRANSFORM" => 16,
    "VFX_BOOST" => 16,
    "VFX_FIRE" => 7,
    "VFX_FIRE2" => 7,
    "VFX_FIRE3" => 7,
    "VFX_FIRE4" => 9,
    "VFX_FIRE5" => 4,
    "VFX_FIRE6" => 12,
    "VFX_FIRE7" => 3,
    "VFX_STEEL2" => 8,
    "VFX_FIGHTING4" => 2,
    "VFX_FIGHTING5" => 11,
    "VFX_FIGHTING6" => 9,
    "VFX_WATER4" => 8,
    "VFX_PSYCHIC3" => 2,
    "VFX_PSYCHIC_ORBIT" => 12,
    "VFX_DARK3" => 8,
    "VFX_STEEL3" => 9,
    "VFX_STEEL4" => 4,
    "VFX_GHOST2" => 2,
    "VFX_GRASS" => 8,
    "VFX_GRASS2" => 12,
    "VFX_GRASS3" => 9,
    "VFX_NORMAL3" => 9,
    "VFX_GRASS_ORBIT" => 12,
    "VFX_ELECTRIC3_SHOT" => 4,
    "VFX_BUG3" => 2,
    "VFX_GROUND4" => 8,
    "VFX_FIGHTING3" => 3,
    "VFX_FAIRY2" => 8,
    "VFX_ROCK2" => 8,
    "VFX_ROCK3" => 12,
    "VFX_STEEL8" => 12,
    "VFX_GROUND5" => 8,
    "VFX_GROUND6" => 6,
    "VFX_DARK5" => 12,
    "VFX_WATER5" => 2,
    "VFX_BUG" => 2,
    "VFX_BUG2" => 2,
    "VFX_DARK" => 7,
    "VFX_DARK2" => 8,
    "VFX_DRAGON" => 7,
    "VFX_DRAGON2" => 7,
    "VFX_DRAGON3" => 8,
    "VFX_DRAGON4" => 4,
    "VFX_DRAGON_TRAIL" => 7,
    "VFX_ELECTRIC_ORBIT" => 2,
    "VFX_ELECTRIC2" => 2,
    "VFX_GROUND" => 7,
    "VFX_GROUND2" => 12,
    "VFX_GROUND3" => 8,
    "VFX_WATER2" => 4,
    "VFX_WATER3" => 4,
    "VFX_WATER_ZONE" => 17,
    "VFX_ICE2" => 4,
    "VFX_ICE3" => 2,
    "VFX_FAIRY" => 7,
    "VFX_FAIRY_ZONE" => 8,
    "VFX_FIGHTING2" => 4,
    "VFX_POISON_TRAIL" => 7,
    "VFX_POISON2" => 11,
    "VFX_FLYING" => 8,
    "VFX_FLYING_ORBIT" => 4,
    "VFX_GHOST" => 7,
    "VFX_GHOST_ORBIT" => 4,
    "VFX_NORMAL_ORBIT" => 4,
    "VFX_NORMAL2_SHOT" => 4,
    "VFX_PSYCHIC2" => 8,
    "VFX_ROCK" => 8,
    "VFX_ROCK_ORBIT" => 8,
    "VFX_STEEL" => 8,
    "VFX_EXCLAIM" => 24,
    "VFX_EXCLAIM_BOSS" => 24,
    "VFX_EXCLAIM_ULTRA_BOSS" => 24,
    "VFX_EXCLAIM_CHEST" => 24,
    "VFX_EXCLAIM_ULTRA_CHEST" => 24,
    "VFX_QUESTION" => 10,
    "VFX_QUESTION_MOVES" => 10,
    "VFX_QUESTION_EGG" => 10,
    "VFX_WILLOWISP" => 8,
    "VFX_QUESTION_SLEEP" => 10
  }.freeze unless const_defined?(:VFX_FRAME_COUNTS)
  def cached_bitmap(folder, name, base_name = nil)
    if folder.to_s == PokemonSurvivor::HERO_DIR && PokemonSurvivor.respond_to?(:hero_graphics_folder)
      base_hint = base_name || (survivor_run_visual_state? ? @hero_base_name : nil)
      folder = PokemonSurvivor.hero_graphics_folder(name, base_hint)
    end
    key = "#{folder}/#{name}"
    if @bitmaps[key] && !@bitmaps[key].disposed?
      return @bitmaps[key]
    end
    @bitmaps[key] = PokemonSurvivor.load_bitmap(folder, name)
    if folder.to_s == PokemonSurvivor::SHOP_DIR && ["Background", "Background_Endless", "Background_Training"].include?(name.to_s)
      PokemonSurvivor.accessibility_recolor_effect(@bitmaps[key])
    end
    register_cached_bitmap_frame_data(@bitmaps[key], folder, name)
    @bitmaps[key] ||= fallback_bitmap(name)
    @bitmaps[key]
  end

  def register_cached_bitmap_frame_data(bitmap, folder, name)
    return if !bitmap || bitmap.disposed?
    if [PokemonSurvivor::HERO_DIR, PokemonSurvivor::HERO_SHINY_DIR, PokemonSurvivor::HERO_ALT_DIR, PokemonSurvivor::HERO_ALT_SHINY_DIR].include?(folder.to_s) && PokemonSurvivor.eight_direction_asset_name?(name)
      PokemonSurvivor.register_eight_direction_bitmap(bitmap, PokemonSurvivor.eight_direction_asset_frame_count(name))
    elsif PokemonSurvivor.eight_direction_enemy_folder?(folder)
      frames = PokemonSurvivor.eight_direction_enemy_asset_frame_count(name).to_i
      PokemonSurvivor.register_eight_direction_bitmap(bitmap, frames) if frames > 0
    end
  rescue
  end



  def cached_hero_idle_bitmap(name, base_name = nil)
    key = PokemonSurvivor.species_key(name).to_s
    @missing_hero_idle_cache ||= {}
    base_hint = base_name || (survivor_run_visual_state? ? @hero_base_name : nil)
    missing_key = "#{key}:#{base_hint}"
    return nil if @missing_hero_idle_cache[missing_key]
    folders = []
    folder = PokemonSurvivor.hero_graphics_folder("#{key}_Idle", base_hint || key) if PokemonSurvivor.respond_to?(:hero_graphics_folder)
    folders << folder if folder
    folders << PokemonSurvivor::HERO_DIR
    folders.uniq.each do |hero_folder|
      ["#{key}_IDLE", "#{key}_Idle", "#{key}_idle"].each do |candidate|
        cache_key = "#{hero_folder}/#{candidate}"
        if @bitmaps[cache_key] && !@bitmaps[cache_key].disposed?
          return @bitmaps[cache_key]
        end
        bitmap = PokemonSurvivor.load_bitmap(hero_folder, candidate)
        if bitmap && !bitmap.disposed?
          PokemonSurvivor.register_eight_direction_bitmap(bitmap, PokemonSurvivor.eight_direction_asset_frame_count(candidate))
          @bitmaps[cache_key] = bitmap
          return bitmap
        end
      end
    end
    @missing_hero_idle_cache[missing_key] = true
    nil
  rescue
    nil
  end

  def survivor_run_visual_state?
    [:play, :upgrade, :baby_choice, :sleep_reward, :pause, :gameover].include?(@state) || !!@evolution_anim
  rescue
    false
  end

  def cached_icon_bitmap(name)
    return nil if !name || name.to_s.empty?
    key = "#{PokemonSurvivor::ICON_DIR}/#{name}"
    return @bitmaps[key] if @bitmaps[key] && !@bitmaps[key].disposed?
    @bitmaps[key] = PokemonSurvivor.load_bitmap(PokemonSurvivor::ICON_DIR, name)
    @bitmaps[key]
  rescue
    nil
  end

  def cached_monochrome_icon_bitmap(name)
    base = cached_icon_bitmap(name)
    return nil if !base || base.disposed?
    key = "#{PokemonSurvivor::ICON_DIR}/#{name}:mono"
    cached = @bitmaps[key]
    return cached if cached && !cached.disposed?
    mono = Bitmap.new(base.width, base.height)
    for yy in 0...base.height
      for xx in 0...base.width
        color = base.get_pixel(xx, yy)
        next if color.alpha <= 0
        gray = ((color.red * 0.30) + (color.green * 0.59) + (color.blue * 0.11)).round
        mono.set_pixel(xx, yy, Color.new(gray, gray, gray, color.alpha))
      end
    end
    @bitmaps[key] = mono
    mono
  rescue
    base
  end
  def cached_vfx_bitmap(name)
    return nil if !name || name.to_s.empty?
    requested = name.to_s
    key = "#{PokemonSurvivor::VFX_DIR}/#{requested}"
    return @bitmaps[key] if @bitmaps[key] && !@bitmaps[key].disposed?
    bmp = PokemonSurvivor.load_bitmap(PokemonSurvivor::VFX_DIR, requested)
    if !bmp || bmp.disposed?
      fallback = { "VFX_ELECTRIC3_SHOT" => "VFX_ELECTRIC2_SHOT", "VFX_POISON2" => "VFX_POISON" }[requested]
      bmp = PokemonSurvivor.load_bitmap(PokemonSurvivor::VFX_DIR, fallback) if fallback
    end
    @bitmaps[key] = PokemonSurvivor.accessibility_recolor_effect(bmp)
    @bitmaps[key]
  rescue
    nil
  end

  def draw_vfx_frame(target, name, x, y, zoom = 1.0, opacity = 255, angle_degrees = nil, frame_index = nil, frame_count = nil)
    sheet = cached_vfx_bitmap(name)
    return false if !sheet || sheet.disposed?
    frames = frame_count.to_i > 0 ? frame_count.to_i : vfx_frame_count(name)
    frame_w = [sheet.width / frames, 1].max
    frame_h = sheet.height
    frame = frame_index.nil? ? (((@timer || 0) * 12).floor % frames) : frame_index.to_i % frames
    src_bitmap = angle_degrees.nil? ? sheet : rotated_vfx_frame_bitmap(name, sheet, frame, frame_w, frame_h, angle_degrees)
    src = angle_degrees.nil? ? Rect.new(frame * frame_w, 0, frame_w, frame_h) : Rect.new(0, 0, src_bitmap.width, src_bitmap.height)
    dest_w = (src.width * zoom).round
    dest_h = (src.height * zoom).round
    dest_x = (x - dest_w / 2).round
    dest_y = (y - dest_h / 2).round
    if dest_w == src.width && dest_h == src.height
      target.blt(dest_x, dest_y, src_bitmap, src, opacity)
    else
      target.stretch_blt(Rect.new(dest_x, dest_y, dest_w, dest_h), src_bitmap, src, opacity)
    end
    true
  rescue
    false
  end

  def vfx_frame_count(name)
    [VFX_FRAME_COUNTS[name.to_s] || 4, 1].max
  rescue
    4
  end
  def rotated_vfx_frame_bitmap(name, sheet, frame, frame_w, frame_h, angle_degrees)
    step = 22.5
    angle = ((angle_degrees.to_f / step).round * step) % 360
    key = "#{PokemonSurvivor::VFX_DIR}/#{name}:frame#{frame}:rot#{angle}"
    return @bitmaps[key] if @bitmaps[key] && !@bitmaps[key].disposed?
    src = Bitmap.new(frame_w, frame_h)
    src.blt(0, 0, sheet, Rect.new(frame * frame_w, 0, frame_w, frame_h))
    rotated = rotate_bitmap(src, angle)
    src.dispose
    @bitmaps[key] = rotated
    rotated
  rescue
    sheet
  end

  def rotate_bitmap(source, angle_degrees)
    return source.clone if angle_degrees.to_f % 360 == 0
    radians = angle_degrees.to_f * Math::PI / 180.0
    cos = Math.cos(radians)
    sin = Math.sin(radians)
    size = Math.sqrt((source.width * source.width) + (source.height * source.height)).ceil
    out = Bitmap.new(size, size)
    cx = source.width / 2.0
    cy = source.height / 2.0
    ox = size / 2.0
    oy = size / 2.0
    for y in 0...size
      dy = y - oy
      for x in 0...size
        dx = x - ox
        sx = (dx * cos + dy * sin + cx).round
        sy = (-dx * sin + dy * cos + cy).round
        next if sx < 0 || sy < 0 || sx >= source.width || sy >= source.height
        color = source.get_pixel(sx, sy)
        out.set_pixel(x, y, color) if color.alpha > 0
      end
    end
    out
  rescue
    source.clone
  end

  def fallback_bitmap(name)
    bmp = Bitmap.new(48, 48)
    bmp.fill_rect(8, 8, 32, 32, Color.new(70, 92, 128))
    bmp.fill_rect(10, 10, 28, 28, Color.new(120, 180, 255))
    pbSetSystemFont(bmp)
    pbDrawTextPositions(bmp, [[name.to_s[0, 1], 24, 11, 2, Color.white, Color.new(32, 32, 40)]])
    bmp
  rescue
    Bitmap.new(48, 48)
  end

  def draw_menu_background(bitmap)
    bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(7, 10, 18))
    bitmap.fill_rect(10, 10, Graphics.width - 20, Graphics.height - 20, Color.new(3, 6, 13))
    bitmap.fill_rect(13, 13, Graphics.width - 26, Graphics.height - 26, Color.new(22, 34, 56))
    bitmap.fill_rect(18, 18, Graphics.width - 36, 3, Color.new(112, 132, 255))
    bitmap.fill_rect(18, Graphics.height - 21, Graphics.width - 36, 3, Color.new(122, 255, 176))
  end

  def options_scrolling_background_bitmap
    @bitmaps ||= {}
    key = "menu_hud_background_options"
    cached = @bitmaps[key]
    return cached if cached && !cached.disposed?
    path = "Graphics/UI/Survivor Game/Menu HUD/Background/Background_Options"
    resolved = pbResolveBitmap(path) rescue nil
    resolved ||= "#{path}.png" if File.exist?("#{path}.png") rescue nil
    return nil if !resolved
    bmp = Bitmap.new(resolved)
    PokemonSurvivor.accessibility_recolor_effect(bmp)
    @bitmaps[key] = bmp
    bmp
  rescue
    nil
  end

  def draw_options_scrolling_background(bitmap)
    bg = options_scrolling_background_bitmap
    if !bg || bg.disposed? || bg.width <= 0 || bg.height <= 0
      draw_menu_background(bitmap) rescue bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(7, 10, 18))
      return
    end
    sw = Graphics.width
    sh = Graphics.height
    tile_w = bg.width
    tile_h = bg.height
    tick = Graphics.frame_count rescue (((System.uptime rescue 0.0) * 60).to_i)
    speed = (tick.to_i / 2)
    ox = speed % tile_w
    oy = (-speed) % tile_h
    y = -tile_h + oy
    while y < sh
      x = -tile_w + ox
      while x < sw
        bitmap.blt(x, y, bg, Rect.new(0, 0, tile_w, tile_h))
        x += tile_w
      end
      y += tile_h
    end
  rescue
    draw_menu_background(bitmap) rescue nil
  end
  def brighten_color(color, amount)
    Color.new(
      [[color.red.to_i + amount.to_i, 0].max, 255].min,
      [[color.green.to_i + amount.to_i, 0].max, 255].min,
      [[color.blue.to_i + amount.to_i, 0].max, 255].min,
      color.alpha
    )
  rescue
    color
  end

  def dim_color(color, amount)
    brighten_color(color, -amount.to_i)
  rescue
    color
  end

  def draw_pixel_round_rect(bitmap, x, y, w, h, color)
    return if w.to_i <= 0 || h.to_i <= 0
    x = x.to_i; y = y.to_i; w = w.to_i; h = h.to_i
    return bitmap.fill_rect(x, y, w, h, color) if w < 8 || h < 8
    bitmap.fill_rect(x + 3, y, w - 6, h, color)
    bitmap.fill_rect(x + 1, y + 1, w - 2, h - 2, color)
    bitmap.fill_rect(x, y + 3, w, h - 6, color)
  rescue
    bitmap.fill_rect(x, y, w, h, color) rescue nil
  end

  def draw_inner_glow(bitmap, x, y, w, h, color, alpha = 120)
    return if w.to_i <= 8 || h.to_i <= 8
    glow = Color.new(color.red, color.green, color.blue, alpha.to_i)
    bitmap.fill_rect(x + 5, y + 4, w - 10, 1, glow)
    bitmap.fill_rect(x + 4, y + 5, 1, h - 10, glow)
    bitmap.fill_rect(x + w - 5, y + 5, 1, h - 10, Color.new(color.red / 2, color.green / 2, color.blue / 2, [alpha.to_i - 35, 45].max))
    bitmap.fill_rect(x + 5, y + h - 5, w - 10, 1, Color.new(4, 8, 16, [alpha.to_i + 20, 180].min))
  rescue
  end

  def draw_panel(bitmap, x, y, w, h, accent = Color.new(132, 214, 255), fill = Color.new(26, 38, 62))
    return if w.to_i <= 0 || h.to_i <= 0
    x = x.to_i; y = y.to_i; w = w.to_i; h = h.to_i
    outline = Color.new(2, 5, 12)
    bevel = Color.new([[accent.red / 2 + 36, 0].max, 255].min, [[accent.green / 2 + 36, 0].max, 255].min, [[accent.blue / 2 + 42, 0].max, 255].min)
    deep = Color.new([[fill.red - 18, 0].max, 255].min, [[fill.green - 18, 0].max, 255].min, [[fill.blue - 18, 0].max, 255].min)
    draw_pixel_round_rect(bitmap, x, y, w, h, outline)
    draw_pixel_round_rect(bitmap, x + 1, y + 1, w - 2, h - 2, Color.new(12, 20, 36))
    draw_pixel_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, bevel)
    draw_pixel_round_rect(bitmap, x + 4, y + 4, w - 8, h - 8, deep)
    draw_pixel_round_rect(bitmap, x + 6, y + 6, w - 12, h - 12, fill)
  rescue
  end

  def draw_clean_panel(bitmap, x, y, w, h, accent = Color.new(132, 214, 255), fill = Color.new(26, 38, 62))
    return if w.to_i <= 0 || h.to_i <= 0
    x = x.to_i; y = y.to_i; w = w.to_i; h = h.to_i
    bevel = Color.new([[accent.red / 2 + 30, 0].max, 255].min, [[accent.green / 2 + 30, 0].max, 255].min, [[accent.blue / 2 + 36, 0].max, 255].min)
    deep = Color.new([[fill.red - 16, 0].max, 255].min, [[fill.green - 16, 0].max, 255].min, [[fill.blue - 16, 0].max, 255].min)
    draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(2, 5, 12))
    draw_pixel_round_rect(bitmap, x + 1, y + 1, w - 2, h - 2, Color.new(12, 20, 36))
    draw_pixel_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, bevel)
    draw_pixel_round_rect(bitmap, x + 4, y + 4, w - 8, h - 8, deep)
    draw_pixel_round_rect(bitmap, x + 6, y + 6, w - 12, h - 12, fill)
  rescue
  end
  def draw_modern_button_frame(bitmap, x, y, w, h, edge, fill, shine, selected = false)
    pulse = selected ? ((Math.sin((System.uptime rescue 0.0) * 7.5) + 1.0) * 0.5) : 0.0
    fill = brighten_color(fill, selected ? (24 + (pulse * 16).to_i) : 0)
    shine = brighten_color(shine, selected ? 20 : 0)
    draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(3, 6, 13))
    draw_pixel_round_rect(bitmap, x + 1, y + 1, w - 2, h - 2, edge)
    draw_pixel_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, Color.new(8, 13, 26))
    inner_fill = brighten_color(fill, selected ? 10 : 0)
    draw_pixel_round_rect(bitmap, x + 3, y + 3, w - 6, h - 6, inner_fill)
    if w > 20 && h > 16
      upper = brighten_color(inner_fill, selected ? 16 : 8)
      lower = dim_color(inner_fill, selected ? 6 : 12)
      draw_pixel_round_rect(bitmap, x + 3, y + 3, w - 6, h - 6, lower)
      draw_pixel_round_rect(bitmap, x + 3, y + 3, w - 6, ((h - 6) / 2) + 3, upper)
    end
  rescue
  end


  def run_view_zoom
    value = @run_view_zoom.to_f
    value = 1.0 if value <= 0.0
    [[value, 0.72].max, 1.0].min
  rescue
    1.0
  end

  def run_view_zoomed?
    @state == :play && run_view_zoom < 0.999
  rescue
    false
  end

  def set_run_view_zoom(value)
    value = [[value.to_f, 0.72].max, 1.0].min
    return if (@run_view_zoom || 1.0).to_f == value
    @run_view_zoom = value
    pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
  rescue
    @run_view_zoom = 1.0
  end

  def update_run_view_zoom_input
    return if @state != :play
    return if !PokemonSurvivor.respond_to?(:control_trigger?)
    set_run_view_zoom(run_view_zoomed? ? 1.0 : 0.76) if PokemonSurvivor.control_trigger?(:zoom_toggle)
  rescue
  end

  def world_screen_x(x)
    zoom = run_view_zoom
    return x.to_f if zoom >= 0.999
    center = Graphics.width / 2.0
    center + ((x.to_f - center) * zoom)
  rescue
    x.to_f
  end

  def world_screen_y(y)
    zoom = run_view_zoom
    return y.to_f if zoom >= 0.999
    center = Graphics.height / 2.0
    center + ((y.to_f - center) * zoom)
  rescue
    y.to_f
  end

  def world_screen_zoom(value = 1.0)
    value.to_f * run_view_zoom
  rescue
    value.to_f
  end
  def draw_hud_header_strip(bitmap, x, y, w, h, accent, fill = Color.new(8, 13, 26, 190))
    draw_pixel_round_rect(bitmap, x, y, w, h, Color.new(3, 6, 13, fill.alpha))
    draw_pixel_round_rect(bitmap, x + 1, y + 1, w - 2, h - 2, fill)
    bitmap.fill_rect(x + 6, y + 4, w - 12, 2, brighten_color(accent, 22)) if w > 16
  rescue
  end
  def draw_game(apply_tv_filter = true)
    bmp = @sprites["screen"].bitmap
    over = @sprites["overlay"].bitmap
    bmp.clear
    over.clear
    @screen_w = Graphics.width
    @screen_h = Graphics.height
    @drawn_minor_hp_bars = 0
    @minor_hp_bar_budget = (@enemies && @enemies.length > 160) ? 28 : 56
    effects = @effects || []
    draw_world_background(bmp)
    draw_rush_world_walls(bmp) if world_walls_enabled?
    draw_tower_objective_world_markers(bmp) if tower_mode? && respond_to?(:draw_tower_objective_world_markers)
    effects.each do |fx|
      next if fx[5] != :poison_zone && fx[5] != :ground_zone
      draw_effect(bmp, fx) if effect_on_screen?(fx)
    end
    effects.each do |fx|
      next if fx[5] == :level_burst || fx[5] == :poison_zone || fx[5] == :ground_zone
      next if !ground_layer_effect?(fx)
      draw_effect(bmp, fx) if effect_on_screen?(fx)
    end
    @items.each { |item| draw_wild_item(bmp, item) if point_on_screen?(item.x, item.y, 36) }
    @projectiles.each { |p| draw_projectile(bmp, p) if point_on_screen?(p.x, p.y, 32) }
    draw_charge_shots(bmp)
    @xp_gems.each { |g| draw_xp_gem(bmp, g) if point_on_screen?(g.x, g.y, 28) }
    draw_enemies_by_visual_priority(bmp)
    draw_special_enemy_edge_indicators(bmp)
    draw_moves_drop_edge_indicators(bmp)
    draw_random_events(bmp) if respond_to?(:draw_random_events)
    mid_count = 0
    mid_limit = PokemonSurvivor.performance_option?(:reduced_vfx) ? 24 : 99_999
    effects.each do |fx|
      next if fx[5] == :level_burst || fx[5] == :poison_zone || fx[5] == :ground_zone || ground_layer_effect?(fx)
      draw_effect(bmp, fx) if effect_on_screen?(fx)
      mid_count += 1
      break if mid_count >= mid_limit
    end
    draw_orbitals(bmp)
    draw_hero(bmp)
    draw_evolution_vfx(bmp) if @evolution_anim
    effects.each { |fx| draw_effect(bmp, fx) if fx[5] == :level_burst }
    draw_swarm_alert_border(over) if respond_to?(:draw_swarm_alert_border)
    draw_hud(over)
    draw_run_info_hint(over) if show_run_info_hint?
    draw_run_speed_feedback(over)
    draw_run_objective_popup(over) if show_run_objective_popup?
    draw_chestboss_currency_popup(over) if @chestboss_currency_popup
    draw_tower_floor_transition_overlay(over) if tower_mode? && @tower_fade_alpha.to_i > 0
    draw_ultimate_prompt(over) if show_ultimate_prompt?
    draw_run_bonus_panel(over) if respond_to?(:draw_run_bonus_panel)
    draw_tv_filter(over) if apply_tv_filter
  end
  def draw_enemies_by_visual_priority(bitmap)
    return if !@enemies || @enemies.empty?
    lists = (@enemy_draw_priority_lists ||= [[], [], []])
    event_hunts, bosses, ultra_bosses = lists
    @enemies.each do |enemy|
      next if !enemy
      case enemy.kind
      when :ultra_boss
        ultra_bosses << enemy
      when :boss
        bosses << enemy
      when :event_hunt
        event_hunts << enemy
      else
        draw_enemy(bitmap, enemy) if point_on_screen?(enemy.x, enemy.y, 64)
      end
    end
    event_hunts.each { |enemy| draw_enemy(bitmap, enemy) if point_on_screen?(enemy.x, enemy.y, 84) }
    bosses.each { |enemy| draw_enemy(bitmap, enemy) if point_on_screen?(enemy.x, enemy.y, 84) }
    ultra_bosses.each { |enemy| draw_enemy(bitmap, enemy) if point_on_screen?(enemy.x, enemy.y, 96) }
  rescue
  ensure
    lists.each(&:clear) if lists
  end
  def draw_special_enemy_edge_indicators(bitmap)
    return if !@enemies || @enemies.empty?
    frame = (((@timer || 0.0) * 12.0).floor)
    limit = PokemonSurvivor.performance_option?(:reduced_vfx) ? 4 : 8
    drawn = 0
    @enemies.each do |enemy|
      next if drawn >= limit
      next if !special_enemy_edge_indicator?(enemy)
      icon = special_enemy_edge_indicator_vfx(enemy)
      next if !icon
      pos = special_enemy_edge_indicator_position(enemy)
      next if !pos
      draw_vfx_frame(bitmap, icon, pos[0], pos[1], 1.0, pos[2], nil, frame)
      drawn += 1
    end
  rescue
  end

  def special_enemy_edge_indicator?(enemy)
    return false if !enemy || enemy.hp.to_i <= 0
    return false if ![:boss, :ultra_boss, :chest, :ultra_chest].include?(enemy.kind)
    !point_on_screen?(enemy.x, enemy.y, 48)
  rescue
    false
  end

  def special_enemy_edge_indicator_vfx(enemy)
    case enemy.kind
    when :ultra_boss then "VFX_EXCLAIM_ULTRA_BOSS"
    when :boss then "VFX_EXCLAIM_BOSS"
    when :ultra_chest then "VFX_EXCLAIM_ULTRA_CHEST"
    when :chest then "VFX_EXCLAIM_CHEST"
    else nil
    end
  rescue
    nil
  end

  def special_enemy_edge_indicator_position(enemy)
    w = @screen_w || Graphics.width
    h = @screen_h || Graphics.height
    center_x = w * 0.5
    center_y = h * 0.5
    sx = respond_to?(:world_screen_x) ? world_screen_x(enemy.x) : enemy.x.to_f
    sy = respond_to?(:world_screen_y) ? world_screen_y(enemy.y) : enemy.y.to_f
    dx = sx.to_f - center_x
    dy = sy.to_f - center_y
    dx = 0.01 if dx.abs < 0.01
    dy = 0.01 if dy.abs < 0.01
    inset_x = 24.0
    inset_top = 72.0
    inset_bottom = 28.0
    max_x = center_x - inset_x
    max_y = dy < 0 ? center_y - inset_top : center_y - inset_bottom
    scale = [max_x / dx.abs, max_y / dy.abs].min
    x = center_x + (dx * scale)
    y = center_y + (dy * scale)
    x = [[x, inset_x].max, w - inset_x].min
    y = [[y, inset_top].max, h - inset_bottom].min
    distance_ratio = [[((dx * dx + dy * dy) ** 0.5) / 420.0, 0.0].max, 1.0].min
    opacity = 190 + (distance_ratio * 55).round
    [x, y, opacity]
  rescue
    nil
  end

  def draw_moves_drop_edge_indicators(bitmap)
    return if !@items || @items.empty?
    frame = (((@timer || 0.0) * 12.0).floor)
    limit = PokemonSurvivor.performance_option?(:reduced_vfx) ? 3 : 6
    drawn = 0
    @items.each do |item|
      next if drawn >= limit
      next if !moves_drop_edge_indicator?(item)
      pos = special_enemy_edge_indicator_position(item)
      next if !pos
      draw_vfx_frame(bitmap, "VFX_QUESTION_MOVES", pos[0], pos[1], 1.0, pos[2], nil, frame)
      drawn += 1
    end
  rescue
  end

  def moves_drop_edge_indicator?(item)
    return false if !item || item.value.to_i <= 0
    return false if item.name.to_s.upcase != "MOVES"
    !point_on_screen?(item.x, item.y, 42)
  rescue
    false
  end
  def draw_charge_shots(bitmap)
    return if !@charge_shots || @charge_shots.empty?
    @charge_shots.each do |shot|
      pos = charge_shot_position(shot)
      progress = charge_shot_progress(shot)
      radius_bonus = (@skill_radius_bonus && @skill_radius_bonus[shot[:skill_id]].to_i) || 0
      zoom = 0.38 + (progress * 0.92) + (radius_bonus * 0.012)
      opacity = 150 + (progress * 105).round
      frame = ((@timer.to_f * 8).floor % 4)
      skill = shot[:skill]
      vfx_name = (skill && (skill[:charge_vfx] || skill[:vfx])) || "VFX_ELECTRIC2"
      draw_vfx_frame(bitmap, vfx_name, world_screen_x(pos[0]), world_screen_y(pos[1]), world_screen_zoom(zoom), opacity, nil, frame)
    end
  rescue
  end
  def foreground_effect?(fx)
    false
  rescue
    false
  end

  def foreground_projectile?(projectile)
    false
  rescue
    false
  end

  def draw_tv_filter(bitmap)
    return if !PokemonSurvivor.performance_option?(:tv_filter)
    filter = cached_vfx_bitmap(PokemonSurvivor::TV_FILTER_VFX)
    return if !filter || filter.disposed? || filter.width <= 0 || filter.height <= 0
    now = System.uptime rescue (@timer || 0.0)
    ox = (now * PokemonSurvivor::TV_FILTER_SCROLL_X).to_i % filter.width
    oy = (now * PokemonSurvivor::TV_FILTER_SCROLL_Y).to_i % filter.height
    w = Graphics.width
    h = Graphics.height
    strip_h = PokemonSurvivor::TV_FILTER_STRIP_HEIGHT
    src_w = filter.width
    src = Rect.new(0, 0, src_w, 0)
    dest = Rect.new(0, 0, src_w, 0)
    geometry_key = [h, strip_h, PokemonSurvivor::TV_FILTER_EDGE_PINCH]
    if @tv_filter_geometry_key != geometry_key
      @tv_filter_geometry_key = geometry_key
      @tv_filter_geometry = {}
    end
    y = 0
    while y < h
      row_h = [strip_h, h - y].min
      geometry = @tv_filter_geometry[y] ||= begin
        ny = ((y + (row_h / 2.0)) / h.to_f) - 0.5
        power = (ny.abs * 2.0) ** 2
        [power, (PokemonSurvivor::TV_FILTER_EDGE_PINCH * power).round]
      end
      edge_power, inset = geometry
      wave = (Math.sin((y * 0.045) + (now * 1.2)) * PokemonSurvivor::TV_FILTER_WAVE * edge_power).round
      src_y = (y + oy) % filter.height
      part_h = [row_h, filter.height - src_y].min
      while part_h > 0
        src.set(0, src_y, src_w, part_h)
        x = -ox - src_w
        while x < w + src_w
          dest.set(x + inset + wave, y, src_w, part_h)
          bitmap.stretch_blt(dest, filter, src, PokemonSurvivor::TV_FILTER_OPACITY)
          x += src_w
        end
        row_h -= part_h
        y += part_h
        src_y = 0
        part_h = [row_h, filter.height].min
      end
    end
  rescue
  end

  def effect_on_screen?(fx)
    meta = fx[9] rescue nil
    if meta.is_a?(Hash) && meta[:poison_rain_drop]
      return point_on_screen?(meta[:target_x] || fx[0], meta[:target_y] || fx[1], (fx[4] || 32).to_i + 180)
    end
    point_on_screen?(fx[0], fx[1], (fx[4] || 32).to_i + 12)
  rescue
    true
  end
  def ground_layer_effect?(fx)
    false
  rescue
    false
  end

  def run_background_tile_width(bg = nil)
    width = bg && !bg.disposed? ? bg.width.to_i : 0
    return Graphics.width if width <= 0
    [width, Graphics.width].max
  rescue
    Graphics.width
  end

  def run_background_tile_height(bg = nil)
    height = bg && !bg.disposed? ? bg.height.to_i : 0
    return Graphics.height if height <= 0
    [height, Graphics.height].max
  rescue
    Graphics.height
  end

  def draw_world_background(bitmap)
    bg = cached_background_bitmap(@bg_name)
    if (!bg || bg.disposed?)
      @bg_name = PokemonSurvivor.background_names.sample.to_s
      bg = cached_background_bitmap(@bg_name)
    end
    if bg && !bg.disposed?
      tile_w = run_background_tile_width(bg)
      tile_h = run_background_tile_height(bg)
      zoom = run_view_zoom
      draw_w = [(tile_w * zoom).ceil, 1].max
      draw_h = [(tile_h * zoom).ceil, 1].max
      ox = @world_x.round % tile_w
      oy = @world_y.round % tile_h
      src = Rect.new(0, 0, bg.width, bg.height)
      x = world_screen_x(-ox).floor
      x -= draw_w while x > 0
      while x < Graphics.width
        y = world_screen_y(-oy).floor
        y -= draw_h while y > 0
        while y < Graphics.height
          if zoom >= 0.999 && tile_w == bg.width && tile_h == bg.height
            bitmap.blt(x, y, bg, src)
          else
            bitmap.stretch_blt(Rect.new(x, y, draw_w, draw_h), bg, src)
          end
          y += draw_h
        end
        x += draw_w
      end
    else
      bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(18, 28, 36))
    end
  end


  def world_wall_visibility(distance)
    approach = [[1.0 - distance.to_f / 160.0, 0.0].max, 1.0].min
    approach * approach * (3.0 - 2.0 * approach)
  end

  def draw_rush_world_walls(bitmap)
    return if !world_walls_enabled?
    return if respond_to?(:titan_mode?) && titan_mode? && @titan_arena
    hx = hero_visual_x.round
    hy = hero_visual_y.round
    radius = PokemonSurvivor::HERO_RADIUS + 5
    zoom = run_view_zoom
    limit_x, limit_y = world_limit_x, world_limit_y
    distances = { left: limit_x + @world_x.to_f, right: limit_x - @world_x.to_f,
                  top: limit_y + @world_y.to_f, bottom: limit_y - @world_y.to_f }
    distances.each_pair do |side, distance|
      visibility = world_wall_visibility(distance)
      next if visibility <= 0.0
      offset = [distance, 0.0].max * zoom
      alpha = (visibility * 170).round
      main = Color.new(210, 42, 58, alpha)
      light = Color.new(255, 118, 120, (visibility * 215).round)
      dark = Color.new(70, 8, 18, (visibility * 195).round)
      case side
      when :left
        draw_rush_wall_strip(bitmap, (hx - radius - 8 - offset).round, hy - 36, 10, 72, :vertical, main, light, dark)
      when :right
        draw_rush_wall_strip(bitmap, (hx + radius - 2 + offset).round, hy - 36, 10, 72, :vertical, main, light, dark)
      when :top
        draw_rush_wall_strip(bitmap, hx - 36, (hy - radius - 8 - offset).round, 72, 10, :horizontal, main, light, dark)
      when :bottom
        draw_rush_wall_strip(bitmap, hx - 36, (hy + radius - 2 + offset).round, 72, 10, :horizontal, main, light, dark)
      end
    end
  rescue
  end

  def draw_world_wall_rect(bitmap, x, y, w, h, color)
    return if w <= 0 || h <= 0 || color.alpha <= 0
    @bitmaps ||= {}
    key = "world_wall_color:#{color.red}:#{color.green}:#{color.blue}"
    swatch = @bitmaps[key]
    if !swatch || swatch.disposed?
      swatch = Bitmap.new(1, 1)
      swatch.fill_rect(0, 0, 1, 1, Color.new(color.red, color.green, color.blue, 255))
      @bitmaps[key] = swatch
    end
    # fill_rect replaces destination alpha; blitting blends over the scenery.
    bitmap.stretch_blt(Rect.new(x, y, w, h), swatch, Rect.new(0, 0, 1, 1), color.alpha.to_i)
  end

  def draw_rush_wall_strip(bitmap, x, y, w, h, dir, main, light, dark)
    draw_world_wall_rect(bitmap, x, y, w, h, dark)
    draw_world_wall_rect(bitmap, x + 2, y + 2, [w - 4, 1].max, [h - 4, 1].max, main)
    if dir == :vertical
      step = 18
      yy = y + 4
      while yy < y + h
        draw_world_wall_rect(bitmap, x + 3, yy, [w - 6, 1].max, 2, light)
        yy += step
      end
    else
      step = 18
      xx = x + 4
      while xx < x + w
        draw_world_wall_rect(bitmap, xx, y + 3, 2, [h - 6, 1].max, light)
        xx += step
      end
    end
  rescue
  end
  def cached_background_bitmap(name)
    @background_resolve_cache ||= {}
    chosen = name.to_s
    chosen = PokemonSurvivor.background_names.first.to_s if chosen.empty?
    cache_key = "#{PokemonSurvivor::BACKGROUND_DIR}/#{chosen}"
    resolved = @background_resolve_cache[cache_key]
    if resolved.nil?
      resolved = PokemonSurvivor.resolve(PokemonSurvivor::BACKGROUND_DIR, chosen) ? true : false
      @background_resolve_cache[cache_key] = resolved
    end
    chosen = PokemonSurvivor.background_names.first.to_s if !resolved
    key = "#{PokemonSurvivor::BACKGROUND_DIR}/#{chosen}"
    return @bitmaps[key] if @bitmaps[key] && !@bitmaps[key].disposed?
    @bitmaps[key] = PokemonSurvivor.load_bitmap(PokemonSurvivor::BACKGROUND_DIR, chosen)
    PokemonSurvivor.accessibility_recolor_effect(@bitmaps[key])
    @bitmaps[key]
  rescue
    nil
  end
  def draw_hero_bitmap
    return @hero.bitmap if !@hero
    return @psyduck_charge_bitmap if headache_movement_locked? && PokemonSurvivor.species_key(@hero.name) == :PSYDUCK && @psyduck_charge_bitmap && !@psyduck_charge_bitmap.disposed?
    if PokemonSurvivor.eight_direction_hero?(@hero.name)
      return @hero.walk_bitmap || @hero.bitmap if @hero.moving
      return @hero.idle_bitmap || @hero.walk_bitmap || @hero.bitmap
    end
    @hero.bitmap
  rescue
    @hero ? @hero.bitmap : nil
  end

  def draw_hero(bitmap)
    evolution_frame = @evolution_anim ? [(@evolution_anim[:elapsed].to_f * 60).floor, 15].min : nil
    return if evolution_frame && evolution_frame >= 6 && evolution_frame < 12
    draw_bitmap = draw_hero_bitmap
    draw_bitmap = @evolution_anim[:old_bitmap] if evolution_frame && evolution_frame < 6
    draw_bitmap = @evolution_anim[:new_bitmap] if evolution_frame && evolution_frame >= 12
    blink = !@evolution_anim && @eevee_burst_timer.to_f <= 0 && @z_move_timer.to_f <= 0 && @invuln > 0 && ((Graphics.frame_count / 4) % 2 == 0)
    if blink
      draw_focus_step_afterimages(bitmap) if respond_to?(:draw_focus_step_afterimages)
      draw_focus_step_cooldown(bitmap) if respond_to?(:draw_focus_step_cooldown)
      draw_psyduck_indicators(bitmap)
      return
    end
    tint = hero_item_tint_color
    tint = rainbow_color(@timer.to_f * 180.0) if @eevee_burst_timer.to_f > 0 || @z_move_timer.to_f > 0
    directions = @hero.charset_directions
    directions = PokemonSurvivor::CHARSET_8_DIRECTIONS if PokemonSurvivor.eight_direction_bitmap?(draw_bitmap)
    zoom = hero_ultimate_breath_zoom
    zoom *= 2.0 if directions.to_i >= PokemonSurvivor::CHARSET_8_DIRECTIONS
    frame = character_frame(@hero, draw_bitmap)
    frame = [(@headache_charge[:age] * 20.0).floor, 9].min if headache_movement_locked? && draw_bitmap == @psyduck_charge_bitmap
    draw_focus_step_afterimages(bitmap) if respond_to?(:draw_focus_step_afterimages)
    if tint
      PokemonSurvivor.draw_character_centered_tinted(bitmap, draw_bitmap, world_screen_x(hero_visual_x), world_screen_y(hero_visual_y), @hero.direction, frame, world_screen_zoom(zoom), tint, 0.42, directions)
    else
      PokemonSurvivor.draw_character_centered(bitmap, draw_bitmap, world_screen_x(hero_visual_x), world_screen_y(hero_visual_y), @hero.direction, frame, world_screen_zoom(zoom), directions)
    end
    draw_focus_step_cooldown(bitmap) if respond_to?(:draw_focus_step_cooldown)
    draw_psyduck_indicators(bitmap)
  end

  def prepare_psyduck_charge_bitmap
    return unless PokemonSurvivor.species_key(@hero.name) == :PSYDUCK
    name = @headache_charge && @headache_charge[:phase] == :success ? "PSYDUCK_Shoot" : "PSYDUCK_Charge"
    folder = PokemonSurvivor.respond_to?(:hero_graphics_folder) ? PokemonSurvivor.hero_graphics_folder(name, @hero_base_name) : PokemonSurvivor::HERO_DIR
    @psyduck_charge_bitmap = cached_bitmap(folder, name)
    @psyduck_charge_bitmap ||= cached_bitmap(PokemonSurvivor::HERO_DIR, name)
    PokemonSurvivor.register_eight_direction_bitmap(@psyduck_charge_bitmap, 10) if @psyduck_charge_bitmap
  end

  def draw_psyduck_indicators(bitmap)
    return if !@headache_charge && @psyduck_confusion_timer.to_f <= 0 && @psyduck_burst_wait_timer.to_f <= 0
    sheet = draw_hero_bitmap
    height = sheet ? sheet.height.to_f / [@hero.charset_directions.to_i, 1].max * 2.0 : 64.0
    x = world_screen_x(hero_visual_x)
    y = world_screen_y(hero_visual_y - height * 0.5 - 2)
    zoom = world_screen_zoom(1.0)
    if @headache_charge && @headache_charge[:phase] != :success
      waiting = @headache_charge[:phase] == :wait
      name = waiting ? "VFX_PSYCHIC_WAIT" : "VFX_PSYCHIC_WAIT2"
      frame = [(@headache_charge[:age] * (waiting ? 6.0 : 10.0)).floor, waiting ? 19 : 4].min
      draw_vfx_frame(bitmap, name, x, y, zoom, 255, nil, frame)
    end
    if @psyduck_burst_wait_timer.to_f > 0
      frame = [((0.5 - @psyduck_burst_wait_timer) * 10).floor, 4].min
      draw_vfx_frame(bitmap, "VFX_PSYCHIC_WAIT2", x, y, zoom, 255, nil, frame)
    end
    if @psyduck_confusion_timer.to_f > 0
      frame = ((30.0 - @psyduck_confusion_timer) * 12).floor % 7
      draw_vfx_frame(bitmap, "VFX_NULL", world_screen_x(hero_visual_x + 22), world_screen_y(hero_visual_y - height * 0.5), zoom, 255, nil, frame)
    end
  end
  def hero_ultimate_breath_zoom
    return 1.0 if @evolution_anim || !ultimate_ready?
    pulse = (Math.sin((System.uptime rescue 0.0) * 7.5) + 1.0) * 0.5
    1.0 + (pulse * 0.055)
  rescue
    1.0
  end

  def draw_evolution_vfx(bitmap)
    return if !@evolution_anim
    frame = [(@evolution_anim[:elapsed].to_f * 60).floor, 15].min
    vfx = @evolution_anim[:vfx_name] || "VFX_EVOLUTION"
    draw_vfx_frame(bitmap, vfx, world_screen_x(hero_visual_x), world_screen_y(hero_visual_y), world_screen_zoom(1.0), 255, nil, frame) || draw_vfx_frame(bitmap, "VFX_EVOLUTION", world_screen_x(hero_visual_x), world_screen_y(hero_visual_y), world_screen_zoom(1.0), 255, nil, frame)
  rescue
  end

  def hero_item_tint_color
    color = hero_item_active_tint_color
    return if !color
    pulse = ((Math.sin((System.uptime rescue 0) * 10.0) + 1.0) * 0.5)
    Color.new(
      [[color.red + (pulse * 42).round, 0].max, 255].min,
      [[color.green + (pulse * 42).round, 0].max, 255].min,
      [[color.blue + (pulse * 42).round, 0].max, 255].min
    )
  rescue
    nil
  end

  def draw_enemy(bitmap, e)
    zoom = e.kind == :boss || e.kind == :ultra_boss ? 1.35 : 1.0
    zoom = 1.15 if e.kind == :chest || e.kind == :ultra_chest || e.kind == :event_hunt
    zoom *= 2.0 if e.charset_directions.to_i >= PokemonSurvivor::CHARSET_8_DIRECTIONS
    frame = character_frame(e, e.bitmap)
    draw_special_enemy_outline(bitmap, e, zoom, frame)
    tint = enemy_sprite_tint(e)
    if tint
      PokemonSurvivor.draw_character_centered_tinted(bitmap, e.bitmap, world_screen_x(e.x), world_screen_y(e.y), e.direction, frame, world_screen_zoom(zoom), tint, enemy_tint_strength(e), e.charset_directions)
    else
      PokemonSurvivor.draw_character_centered(bitmap, e.bitmap, world_screen_x(e.x), world_screen_y(e.y), e.direction, frame, world_screen_zoom(zoom), e.charset_directions)
    end
    draw_special_enemy_hp_bar(bitmap, e)
    draw_hitbox_debug_circle(bitmap, e.x, e.y, e.radius.to_i) if @show_hitbox_debug
  end

  def draw_special_enemy_outline(bitmap, enemy, zoom, frame)
    color = special_enemy_outline_color(enemy)
    return if !color || !enemy.bitmap || enemy.bitmap.disposed?
    strength = enemy.kind == :ultra_boss ? 0.42 : 0.34
    offsets = [[-1, 0], [1, 0], [0, -1], [0, 1]]
    offsets << [-1, -1] << [1, -1] << [-1, 1] << [1, 1] if enemy.kind == :ultra_boss
    offsets.each do |ox, oy|
      PokemonSurvivor.draw_character_centered_tinted(bitmap, enemy.bitmap, world_screen_x(enemy.x + ox), world_screen_y(enemy.y + oy), enemy.direction, frame, world_screen_zoom(zoom), color, strength, enemy.charset_directions)
    end
  rescue
  end

  def special_enemy_outline_color(enemy)
    case enemy.kind
    when :boss
      Color.new(210, 58, 62)
    when :ultra_boss
      Color.new(146, 84, 218)
    when :event_hunt
      Color.new(255, 224, 92)
    when :chest
      Color.new(230, 202, 84)
    when :ultra_chest
      Color.new(238, 190, 64)
    else
      nil
    end
  rescue
    nil
  end


  def special_enemy_hp_bar?(enemy)
    return false if !PokemonSurvivor.performance_option?(:reinforced_hp_bars)
    return false if !enemy || enemy.max_hp.to_i <= 1
    return true if [:boss, :ultra_boss, :chest, :ultra_chest, :event_hunt].include?(enemy.kind)
    enemy.archetype && enemy.archetype != :normal
  rescue
    false
  end

  def draw_special_enemy_hp_bar(bitmap, enemy)
    return if !special_enemy_hp_bar?(enemy)
    if enemy.kind == :wild && enemy.archetype && enemy.archetype != :normal
      return if enemy.hp.to_i >= enemy.max_hp.to_i && @enemies && @enemies.length > 120
      @drawn_minor_hp_bars ||= 0
      @minor_hp_bar_budget ||= 56
      return if @drawn_minor_hp_bars >= @minor_hp_bar_budget
      @drawn_minor_hp_bars += 1
    end
    rate = [[enemy.hp.to_f / [enemy.max_hp.to_f, 1.0].max, 0.0].max, 1.0].min
    boss_like_event = enemy.kind == :event_hunt
    w = (enemy.kind == :ultra_boss || boss_like_event ? 56 : (enemy.kind == :boss ? 50 : 42))
    h = enemy.kind == :ultra_boss || enemy.kind == :boss || boss_like_event ? 7 : 6
    z = run_view_zoom
    draw_w = [(w * z).round, 12].max
    draw_h = [(h * z).round, 4].max
    x = (world_screen_x(enemy.x) - (draw_w / 2)).round
    y = (world_screen_y(enemy.y - enemy.radius - 14)).round
    draw_enemy_status_bar(bitmap, x, y, draw_w, draw_h, rate, enemy_hp_bar_color(rate))
  rescue
  end

  def enemy_hp_bar_color(rate)
    @enemy_hp_bar_green ||= Color.new(92, 255, 132)
    @enemy_hp_bar_orange ||= Color.new(255, 174, 64)
    @enemy_hp_bar_red ||= Color.new(255, 84, 96)
    return @enemy_hp_bar_green if rate.to_f > 0.50
    return @enemy_hp_bar_orange if rate.to_f >= 0.25
    @enemy_hp_bar_red
  rescue
    Color.new(255, 84, 96)
  end

  def enemy_sprite_tint(enemy)
    return Color.new(255, 226, 86) if enemy && enemy.kind == :event_hunt
    return nil if !enemy || enemy.archetype == :normal
    archetype_color(enemy.archetype)
  rescue
    nil
  end

  def enemy_tint_strength(enemy)
    return 0.26 if enemy && enemy.kind == :event_hunt
    return 0.16 if enemy.kind == :chest || enemy.kind == :ultra_chest
    return 0.24 if enemy.kind == :boss || enemy.kind == :ultra_boss
    0.20
  rescue
    0.20
  end

  def draw_projectile(bitmap, p)
    if p.owner == :enemy
      p.vfx_name = PokemonSurvivor::ENEMY_PROJECTILE_VFX_REPLACEMENTS.fetch(p.vfx_name, p.vfx_name)
    end
    x = world_screen_x(p.x).round
    y = world_screen_y(p.y).round
    angle = projectile_draw_angle(p)
    draw_projectile_hitbox_debug(bitmap, p) if @show_hitbox_debug
    if p.vfx_name
      frame = projectile_vfx_frame_index(p)
      if p.owner == :enemy
        return if draw_enemy_projectile_vfx(bitmap, p.vfx_name, x, y, angle, frame)
      else
        return if draw_projectile_8dir_vfx(bitmap, p.vfx_name, x, y, p, frame)
        return if draw_vfx_frame(bitmap, p.vfx_name, x, y, world_screen_zoom(p.vfx_scale || 1.0), 245, angle, frame)
      end
    end
    size = [(p.owner == :enemy ? 8 : 10) * run_view_zoom, 3].max.round
    bitmap.fill_rect(x - size / 2, y - size / 2, size, size, Color.new(30, 30, 40))
    bitmap.fill_rect(x - size / 2 + 1, y - size / 2 + 1, size - 2, size - 2, p.color)
  end

  def projectile_8dir_vfx?(name)
    ["VFX_STEEL4", "VFX_FIRE7", "VFX_GHOST3", "VFX_ELECTRIC3", "VFX_ICE6"].include?(name.to_s)
  rescue
    false
  end

  def draw_projectile_8dir_vfx(target, name, x, y, projectile, frame_index = nil)
    return false if !projectile_8dir_vfx?(name)
    sheet = cached_vfx_bitmap(name)
    return false if !sheet || sheet.disposed?
    angle = Math.atan2(projectile.vy.to_f, projectile.vx.to_f)
    frame = frame_index.nil? ? (((@timer || 0.0) * 18.0).floor % vfx_frame_count(name)) : frame_index.to_i
    draw_survivor_swing_vfx(target, sheet, x, y, world_screen_zoom(projectile.vfx_scale || 1.0), angle, frame, name)
    true
  rescue
    false
  end
  def draw_enemy_projectile_vfx(target, name, x, y, angle_degrees = nil, frame_index = nil)
    sheet = cached_enemy_projectile_vfx_bitmap(name)
    return false if !sheet || sheet.disposed?
    frames = vfx_frame_count(name)
    frame_w = [sheet.width / frames, 1].max
    frame_h = sheet.height
    frame = frame_index.nil? ? (((@timer || 0) * 12).floor % frames) : frame_index.to_i % frames
    src_bitmap = angle_degrees.nil? ? sheet : rotated_enemy_projectile_vfx_frame_bitmap(name, sheet, frame, frame_w, frame_h, angle_degrees)
    src = angle_degrees.nil? ? Rect.new(frame * frame_w, 0, frame_w, frame_h) : Rect.new(0, 0, src_bitmap.width, src_bitmap.height)
    zoom = run_view_zoom
    dest_w = [(src.width * zoom).round, 1].max
    dest_h = [(src.height * zoom).round, 1].max
    dest = Rect.new((x - dest_w / 2).round, (y - dest_h / 2).round, dest_w, dest_h)
    target.stretch_blt(dest, src_bitmap, src, 245)
    true
  rescue
    false
  end

  def cached_enemy_projectile_vfx_bitmap(name)
    base = cached_vfx_bitmap(name)
    return nil if !base || base.disposed?
    key = "#{PokemonSurvivor::VFX_DIR}/#{name}:enemy_projectile_outline"
    cached = @bitmaps[key]
    return cached if cached && !cached.disposed?
    frames = [vfx_frame_count(name), 1].max
    frame_w = [base.width / frames, 1].max
    cell_w = frame_w + 2
    cell_h = base.height + 2
    tinted = Bitmap.new(cell_w * frames, cell_h)
    # Pad each frame separately so outlines never bleed into adjacent frames.
    frames.times do |frame|
      alpha = Array.new(cell_w * cell_h, 0)
      base.height.times do |yy|
        frame_w.times do |xx|
          opacity = base.get_pixel(frame * frame_w + xx, yy).alpha
          next if opacity <= 0
          3.times do |dy|
            3.times do |dx|
              index = (yy + dy) * cell_w + xx + dx
              alpha[index] = opacity if opacity > alpha[index]
            end
          end
        end
      end
      black = Color.new(0, 0, 0, 0)
      alpha.each_with_index do |opacity, index|
        next if opacity <= 0
        black.alpha = opacity
        tinted.set_pixel(frame * cell_w + index % cell_w, index / cell_w, black)
      end
    end
    for yy in 0...base.height
      for xx in 0...base.width
        color = base.get_pixel(xx, yy)
        next if color.alpha <= 0
        lum = [color.red, color.green, color.blue].max
        frame = xx / frame_w
        next if frame >= frames
        dest_x = frame * cell_w + xx % frame_w + 1
        tint = Color.new([150 + (lum * 0.35), 255].min, [34 + (lum * 0.20), 255].min, [176 + (lum * 0.30), 255].min, color.alpha)
        tinted.set_pixel(dest_x, yy + 1, PokemonSurvivor.accessible_color(tint))
      end
    end
    @bitmaps[key] = tinted
    tinted
  rescue
    tinted.dispose if tinted && !tinted.disposed?
    base
  end

  def rotated_enemy_projectile_vfx_frame_bitmap(name, sheet, frame, frame_w, frame_h, angle_degrees)
    step = 22.5
    angle = ((angle_degrees.to_f / step).round * step) % 360
    key = "#{PokemonSurvivor::VFX_DIR}/#{name}:enemy_projectile_outline:frame#{frame}:rot#{angle}"
    return @bitmaps[key] if @bitmaps[key] && !@bitmaps[key].disposed?
    src = Bitmap.new(frame_w, frame_h)
    src.blt(0, 0, sheet, Rect.new(frame * frame_w, 0, frame_w, frame_h))
    rotated = rotate_bitmap(src, angle)
    src.dispose
    @bitmaps[key] = rotated
    rotated
  rescue
    sheet
  end

  def projectile_vfx_frame_index(projectile)
    return nil if !projectile
    name = projectile.vfx_name.to_s
    return nil if name.empty?
    frames = vfx_frame_count(name)
    speed = name == "VFX_PSYCHIC2" ? 14.0 : 12.0
    source = projectile.source_skill
    speed *= source[:vfx_speed_mult].to_f if source && source[:vfx_speed_mult]
    if source && source[:vfx_loop] == false
      speed = source[:vfx_fps].to_f if source[:vfx_fps]
      return [[(projectile.age.to_f * speed).floor, 0].max, frames - 1].min
    end
    ((projectile.age.to_f * speed).floor % frames)
  rescue
    nil
  end

  def projectile_draw_angle(projectile)
    return nil if projectile.source_skill && projectile.source_skill[:vfx_fixed_orientation]
    return nil if projectile.tornado_motion
    return nil if projectile.source_skill && projectile.source_skill[:kind] == :fae_bloom
    if projectile.orbit_target
      if projectile.source_skill && projectile.source_skill[:vfx_radial_orientation]
        return projectile.orbit_angle.to_f * 180.0 / Math::PI + 90.0
      end
      return ((projectile.orbit_angle.to_f + (Math::PI / 2.0)) * 180.0 / Math::PI) + 90.0
    end
    return nil if projectile.vx.to_f == 0 && projectile.vy.to_f == 0
    (Math.atan2(projectile.vy.to_f, projectile.vx.to_f) * 180.0 / Math::PI) + 90.0
  rescue
    nil
  end

  def draw_wild_item(bitmap, item)
    PokemonSurvivor.draw_bitmap_centered(bitmap, item.bitmap, world_screen_x(item.x), world_screen_y(item.y), world_screen_zoom(1.0))
  rescue
    x = world_screen_x(item.x).round
    y = world_screen_y(item.y).round
    color = item.color || Color.white
    bitmap.fill_rect(x - 8, y - 8, 16, 16, Color.new(30, 30, 40))
    bitmap.fill_rect(x - 6, y - 6, 12, 12, color)
  end

  def draw_orbitals(bitmap)
    (@learned_skills || []).each do |skill_id|
      skill = PokemonSurvivor::SKILLS[skill_id]
      next if !skill || ![:orbit, :orbit_shot, :dual_orbit_shot].include?(skill[:kind])
      positions = skill[:kind] == :dual_orbit_shot ? dual_orbit_positions(skill_id, skill) : orbit_positions(skill_id, skill)
      positions.each do |pos|
        color = skill[:kind] == :dual_orbit_shot && pos[4] == :normal ? Color.new(210, 210, 190) : skill_color(skill)
        vfx_name = skill[:kind] == :dual_orbit_shot ? dual_orbit_vfx_name(skill, pos[4]) : orbit_vfx_name(skill)
        x = world_screen_x(pos[0]).round
        y = world_screen_y(pos[1]).round
        r = [(pos[2].to_i * run_view_zoom).round, 2].max
        if vfx_name
          frame = (((@timer || 0.0) * 10.0).floor % vfx_frame_count(vfx_name))
          angle = pos[3] ? (((((pos[3].to_f + (Math::PI / 2.0)) * 180.0 / Math::PI) + 90.0) / 45.0).round * 45.0) : nil
          next if draw_vfx_frame(bitmap, vfx_name, x, y, world_screen_zoom(1.0), 245, angle, frame)
        end
        if skill[:kind] == :orbit_shot
          bitmap.fill_rect(x - r, y - r, r * 2, r * 2, Color.new(28, 32, 40, 150))
          bitmap.fill_rect(x - r + 2, y - r + 2, (r - 2) * 2, (r - 2) * 2, Color.new(color.red, color.green, color.blue, 215))
          bitmap.fill_rect(x - 1, y - r - 4, 2, r + 4, Color.new(color.red, color.green, color.blue, 170))
          bitmap.fill_rect(x - r - 4, y - 1, r + 4, 2, Color.new(color.red, color.green, color.blue, 170))
        else
          bitmap.fill_rect(x - r, y - r, r * 2, r * 2, Color.new(28, 32, 40, 130))
          bitmap.fill_rect(x - r + 2, y - r + 2, (r - 2) * 2, (r - 2) * 2, Color.new(color.red, color.green, color.blue, 190))
        end
      end
    end
  rescue
  end

  def dual_orbit_vfx_name(skill, side)
    side == :normal ? (skill[:normal_orbit_vfx] || "VFX_NORMAL_ORBIT") : (skill[:ghost_orbit_vfx] || "VFX_GHOST_ORBIT")
  rescue
    orbit_vfx_name(skill)
  end

  def draw_xp_gem(bitmap, gem)
    x = world_screen_x(gem.x).round
    y = world_screen_y(gem.y).round
    exp_icon = xp_gem_bitmap(gem.value)
    if exp_icon && !exp_icon.disposed?
      PokemonSurvivor.draw_bitmap_centered(bitmap, exp_icon, x, y, world_screen_zoom(1.0))
      return
    end
    bitmap.fill_rect(x - 4, y - 4, 8, 8, Color.new(30, 30, 40))
    bitmap.fill_rect(x - 3, y - 3, 6, 6, Color.new(92, 255, 180))
  end

  def xp_gem_bitmap(value)
    icon_name, hue = xp_gem_icon_and_hue(value)
    base = cached_bitmap(PokemonSurvivor::ITEM_DIR, icon_name)
    base = cached_bitmap(PokemonSurvivor::ITEM_DIR, "EXP") if !base || base.disposed?
    return base if !base || base.disposed?
    return base if hue.nil?
    key = "#{PokemonSurvivor::ITEM_DIR}/#{icon_name}:hue:#{hue}"
    return @bitmaps[key] if @bitmaps[key] && !@bitmaps[key].disposed?
    tinted = Bitmap.new(base.width, base.height)
    tinted.blt(0, 0, base, Rect.new(0, 0, base.width, base.height))
    tinted.hue_change(hue)
    @bitmaps[key] = tinted
    tinted
  rescue
    cached_bitmap(PokemonSurvivor::ITEM_DIR, "EXP_XS") || cached_bitmap(PokemonSurvivor::ITEM_DIR, "EXP")
  end

  def xp_gem_icon_and_hue(value)
    value = [value.to_i, 1].max
    # Values above the final tier share its last colour; keep the cache bounded.
    value = 999 if value > 999
    cache = (@xp_gem_style_cache ||= [])
    return cache[value] if cache[value]
    tiers = [
      ["EXP_XS", 1, 25],
      ["EXP_S", 25, 75],
      ["EXP_M", 75, 175],
      ["EXP_L", 175, 400],
      ["EXP_XL", 400, 1000]
    ]
    tier = tiers.find { |entry| value < entry[2] } || tiers[-1]
    icon_name = tier[0]
    start_value = tier[1].to_i
    end_value = tier[2].to_i
    local = [[value - start_value, 0].max, [end_value - start_value - 1, 1].max].min
    span = [end_value - start_value, 1].max.to_f
    ratio = local / span
    hue = xp_gem_hue_from_ratio(ratio)
    cache[value] = [icon_name, hue].freeze
  rescue
    ["EXP_XS", nil]
  end

  def xp_gem_hue_from_ratio(ratio)
    ratio = [[ratio.to_f, 0.0].max, 1.0].min
    return nil if ratio < 0.20
    return 45 if ratio < 0.42
    return 105 if ratio < 0.66
    return 175 if ratio < 0.86
    255
  rescue
    nil
  end

  def xp_gem_hue(value)
    xp_gem_icon_and_hue(value)[1]
  rescue
    nil
  end

  def draw_effect(bitmap, fx)
    meta = fx[9] rescue nil
    swing_source = fx[6] rescue nil
    if meta.is_a?(Hash) && meta[:charmander_twister] && swing_source
      step = swing_source[:vfx_frame_time].to_f
      opacity = [[(fx[2].to_f / step * 255).round, 0].max, 255].min
      draw_vfx_frame(bitmap, swing_source[:vfx], world_screen_x(fx[0]).round,
                     world_screen_y(fx[1]).round, world_screen_zoom([fx[4].to_f / 46.0, 0.75].max),
                     opacity, nil, effect_vfx_frame_index(swing_source[:vfx], fx))
      return
    end
    if meta.is_a?(Hash) && meta[:survivor_swing] && swing_source && swing_source.respond_to?(:[])
      draw_survivor_swing_effect(bitmap, fx, meta, swing_source)
      return
    end
    if meta.is_a?(Hash) && meta[:poison_rain_drop] && swing_source && swing_source.respond_to?(:[])
      draw_poison_rain_drop_effect(bitmap, fx, meta, swing_source)
      return
    end
    x, y, t, color, radius, kind, source = fx
    radius = 18 if !radius
    alpha = [[(t * 520).round, 45].max, 150].min
    cx = world_screen_x(x).round
    cy = world_screen_y(y).round
    source = nil if source && !source.respond_to?(:[])
    vfx_name = if kind == :level_burst
                 "VFX_LEVEL_UP_BURST"
               elsif kind == :hit
                 "VFX_HIT"
               elsif source
                 source[:vfx] || vfx_name_for_type(source[:type])
               else
                 nil
               end
    zoom = (kind == :zone || kind == :poison_zone || kind == :ground_zone || kind == :circle || kind == :ring) ? [radius.to_f / 46.0, 0.75].max : 1.0
    zoom = radius.to_f / source[:vfx_radius].to_f if source && source[:vfx_radius].to_f > 0.0
    zoom = world_screen_zoom(zoom)
    radius = [(radius.to_f * run_view_zoom).round, 2].max
    frame_index = effect_vfx_frame_index(vfx_name, fx)
    if vfx_name && draw_vfx_frame(bitmap, vfx_name, cx, cy, zoom, [[alpha + 80, 160].max, 255].min, nil, frame_index)
      draw_hitbox_debug_circle(bitmap, x, y, fx[4].to_i) if @show_hitbox_debug && meta.is_a?(Hash) && (meta[:tyrunt_shockwave] || meta[:headache_wave])
      return
    end
    case kind
    when :level_burst
      return
    when :ring
      r = radius.to_i
      bitmap.fill_rect(cx - r, cy - r, r * 2, 2, Color.new(color.red, color.green, color.blue, alpha))
      bitmap.fill_rect(cx - r, cy + r, r * 2, 2, Color.new(color.red, color.green, color.blue, alpha))
      bitmap.fill_rect(cx - r, cy - r, 2, r * 2, Color.new(color.red, color.green, color.blue, alpha))
      bitmap.fill_rect(cx + r, cy - r, 2, r * 2, Color.new(color.red, color.green, color.blue, alpha))
    when :circle, :zone, :poison_zone, :ground_zone
      r = radius.to_i
      bitmap.fill_rect(cx - r, cy - r, r * 2, r * 2, Color.new(color.red, color.green, color.blue, alpha / 3))
      bitmap.fill_rect(cx - r, cy - r, r * 2, 2, Color.new(color.red, color.green, color.blue, alpha))
      bitmap.fill_rect(cx - r, cy + r, r * 2, 2, Color.new(color.red, color.green, color.blue, alpha))
    else
      size = [[radius.to_i, 4].max, 28].min
      bitmap.fill_rect(cx - size / 2, cy - size / 2, size, size, Color.new(color.red, color.green, color.blue, alpha))
    end
  rescue
  end


  def draw_poison_rain_drop_effect(bitmap, fx, meta, source)
    vfx_name = source[:vfx] || "VFX_POISON2"
    if vfx_name.to_s == "VFX_POISON2" && !PokemonSurvivor.resolve(PokemonSurvivor::VFX_DIR, "VFX_POISON2")
      vfx_name = "VFX_POISON"
    end
    sheet = cached_vfx_bitmap(vfx_name)
    return if !sheet || sheet.disposed?
    age = fx[8].to_f
    fall_time = [meta[:fall_time].to_f, 0.05].max
    impact_time = [meta[:impact_time].to_f, 0.05].max
    frames = [vfx_frame_count(vfx_name).to_i, 1].max
    frame = if source[:rain_direct] && source[:vfx_loop]
      (age * source[:vfx_fps].to_f).floor % frames
    elsif age < fall_time
      0
    else
      impact_age = [[age - fall_time, 0.0].max, impact_time].min
      1 + [[(impact_age / impact_time * (frames - 1).to_f).floor, 0].max, frames - 2].min
    end
    x = world_screen_x(fx[0].to_f).round
    y = world_screen_y(fx[1].to_f).round
    draw_vfx_frame(bitmap, vfx_name, x, y, world_screen_zoom(1.25), 255, nil, frame)
    draw_hitbox_debug_circle(bitmap, (meta[:target_x] || fx[0]).to_f, meta[:target_y].to_f, fx[4].to_i) if @show_hitbox_debug && !source[:rain_direct]
  rescue
  end
  def draw_survivor_swing_effect(bitmap, fx, meta, source)
    vfx_name = source[:vfx] || "VFX_NORMAL3"
    sheet = cached_vfx_bitmap(vfx_name)
    return if !sheet || sheet.disposed?
    age = fx[8].to_f
    duration = [fx[2].to_f + age, source[:duration].to_f, 0.18].max
    frames = [source[:vfx_frames].to_i > 0 ? source[:vfx_frames].to_i : vfx_frame_count(vfx_name).to_i, 1].max
    frame = if meta[:eevee_sweep]
      (age * source[:vfx_fps]).floor % frames
    elsif meta[:returning_swing]
      ((age / duration * frames.to_f * 4.0).floor % frames)
    else
      [[(age / duration * frames.to_f).floor, 0].max, frames - 1].min
    end
    skill_id = source[:id] || skill_id_for(source)
    spin_bonus = (@skill_orbit_speed_bonus ||= Hash.new(0))[skill_id].to_i * 0.20
    spin_mult = (@zangoose_surge_timer.to_f > 0 ? [@zangoose_surge_spin_mult.to_f, 1.0].max : 1.0)
    angle = meta[:angle].to_f + (age * (meta[:spin_speed].to_f + spin_bonus) * spin_mult)
    angle = eevee_sweep_angle(fx, meta) if meta[:eevee_sweep]
    offset = meta[:visual_offset].to_f
    if meta[:visual_slide_in]
      slide_time = [meta[:visual_slide_time].to_f, 0.01].max
      t = [[age / slide_time, 0.0].max, 1.0].min
      t = 1.0 - ((1.0 - t) * (1.0 - t))
      start_mult = [[meta[:visual_slide_start_mult].to_f, 0.0].max, 1.0].min
      offset *= start_mult + ((1.0 - start_mult) * t)
    end
    visual_world_x = fx[0].to_f + Math.cos(angle) * offset
    visual_world_y = fx[1].to_f + Math.sin(angle) * offset
    visual_angle = if meta.key?(:visual_angle_override)
      meta[:visual_angle_override].to_f
    elsif meta[:lock_visual_angle] && @hero
      Math.atan2(visual_world_y - @hero.y.to_f, visual_world_x - @hero.x.to_f)
    else
      meta[:centered_visual] ? meta[:visual_angle].to_f : angle
    end
    x = world_screen_x(visual_world_x).round
    y = world_screen_y(visual_world_y).round
    visual_base = [meta[:visual_radius_base].to_f, 1.0].max
    visual_zoom = [fx[4].to_f / visual_base, 0.70].max * [meta[:visual_scale].to_f, 1.0].max
    if source[:single_row_vfx]
      rotation = meta[:eevee_sweep] ? angle * 180.0 / Math::PI - 90.0 : nil
      draw_vfx_frame(bitmap, vfx_name, x, y, world_screen_zoom(visual_zoom), 255, rotation, frame, frames)
    else
      draw_survivor_swing_vfx(bitmap, sheet, x, y, world_screen_zoom(visual_zoom), visual_angle, frame, vfx_name)
    end
    draw_survivor_swing_hitbox_debug(bitmap, fx, meta, angle) if @show_hitbox_debug
  rescue
  end

  def update_hitbox_debug_toggle
    unless $DEBUG
      @show_hitbox_debug = false
      return
    end
    return if @state != :play
    if PokemonSurvivor.respond_to?(:control_key_triggered?) && PokemonSurvivor.control_key_triggered?("Right Stick")
      @show_hitbox_debug = !@show_hitbox_debug
    end
  rescue
  end

  def draw_survivor_swing_hitbox_debug(bitmap, fx, meta, angle)
    origin_x = fx[0].to_f
    origin_y = fx[1].to_f
    radius = [meta[:radius].to_i, 1].max
    arc = meta[:arc].to_f
    if meta[:cone_hit]
      cone_origin_x = origin_x + (Math.cos(angle) * radius.to_f * meta[:cone_origin_offset_mult].to_f)
      cone_origin_y = origin_y + (Math.sin(angle) * radius.to_f * meta[:cone_origin_offset_mult].to_f)
      draw_hitbox_debug_cone(bitmap, cone_origin_x, cone_origin_y, radius, angle, arc, meta[:cone_min_mult].to_f, meta[:cone_width_mult].to_f)
      return
    end
    offset = meta[:centered_visual] ? 0.0 : meta[:visual_offset].to_f
    hit_x = origin_x + Math.cos(angle) * offset
    hit_y = origin_y + Math.sin(angle) * offset
    hit_radius = meta[:centered_visual] ? radius : [(radius.to_f * (meta[:hit_radius_mult] || 0.58).to_f).round, 20].max
    draw_hitbox_debug_circle(bitmap, hit_x, hit_y, hit_radius)
  rescue
  end

  def draw_hitbox_debug_cone(bitmap, origin_x, origin_y, radius, angle, arc, min_mult = 0.0, width_mult = 1.0)
    half = arc.to_f / 2.0
    min_r = [radius.to_f * min_mult.to_f, 0.0].max
    steps = 18
    color = Color.new(255, 0, 0, 185)
    fill = Color.new(255, 0, 0, 44)
    visual_half = half * [width_mult.to_f, 0.05].max
    0.upto(steps) do |i|
      t = i.to_f / steps
      a = angle - visual_half + ((visual_half * 2.0) * t)
      draw_hitbox_debug_dot(bitmap, origin_x + Math.cos(a) * radius, origin_y + Math.sin(a) * radius, 4, color)
      mid = min_r + ((radius - min_r) * 0.52)
      draw_hitbox_debug_dot(bitmap, origin_x + Math.cos(a) * mid, origin_y + Math.sin(a) * mid, 3, fill) if i.even?
    end
    [angle - visual_half, angle, angle + visual_half].each do |a|
      0.upto(10) do |i|
        r = min_r + ((radius - min_r) * i / 10.0)
        draw_hitbox_debug_dot(bitmap, origin_x + Math.cos(a) * r, origin_y + Math.sin(a) * r, 4, color)
      end
    end
  rescue
  end

  def draw_hitbox_debug_circle(bitmap, world_x, world_y, radius)
    color = Color.new(255, 0, 0, 185)
    fill = Color.new(255, 0, 0, 38)
    steps = 32
    0.upto(steps - 1) do |i|
      a = Math::PI * 2.0 * i / steps
      draw_hitbox_debug_dot(bitmap, world_x + Math.cos(a) * radius, world_y + Math.sin(a) * radius, 4, color)
      draw_hitbox_debug_dot(bitmap, world_x + Math.cos(a) * radius * 0.55, world_y + Math.sin(a) * radius * 0.55, 3, fill) if i.even?
    end
    draw_hitbox_debug_dot(bitmap, world_x, world_y, 5, color)
  rescue
  end

  def draw_projectile_hitbox_debug(bitmap, projectile)
    return if !projectile
    if projectile.respond_to?(:tornado_motion) && projectile.tornado_motion && !projectile.orbit_target
      radius = projectile.radius.to_f
      motion = projectile.tornado_motion
      color = Color.new(255, 0, 0, 180)
      32.times do |i|
        angle = i * Math::PI * 2.0 / 32.0
        draw_hitbox_debug_dot(bitmap, projectile.x + Math.cos(angle) * radius,
                             projectile.y + motion[:hit_y] + Math.sin(angle) * radius * motion[:hit_height], 4, color)
      end
      return
    end
    radius = if projectile.respond_to?(:radius) && projectile.radius.to_i > 0
               projectile.radius.to_i
             elsif projectile.respond_to?(:size) && projectile.size.to_i > 0
               projectile.size.to_i
             else
               8
             end
    draw_hitbox_debug_circle(bitmap, projectile.x, projectile.y, radius)
  rescue
  end

  def draw_hitbox_debug_dot(bitmap, world_x, world_y, size = 3, color = nil)
    color ||= Color.new(255, 0, 0, 180)
    scale = respond_to?(:run_view_zoom) ? run_view_zoom.to_f : 1.0
    s = [[(size.to_f * scale).round, 1].max, 6].min
    x = world_screen_x(world_x).round - (s / 2)
    y = world_screen_y(world_y).round - (s / 2)
    return if x < -s || y < -s || x >= Graphics.width || y >= Graphics.height
    bitmap.fill_rect(x, y, s, s, color)
  rescue
  end

  def draw_survivor_swing_vfx(target, sheet, x, y, zoom, angle, frame, vfx_name = nil)
    cols = [vfx_frame_count(vfx_name).to_i, 1].max
    rows = 8
    frame_w = [sheet.width / cols, 1].max
    frame_h = [sheet.height / rows, 1].max
    row = survivor_swing_vfx_row(angle)
    src = Rect.new([[frame.to_i, 0].max, cols - 1].min * frame_w, row * frame_h, frame_w, frame_h)
    dest_w = [(frame_w * zoom.to_f).round, 1].max
    dest_h = [(frame_h * zoom.to_f).round, 1].max
    target.stretch_blt(Rect.new((x - dest_w / 2).round, (y - dest_h / 2).round, dest_w, dest_h), sheet, src, 255)
  rescue
  end

  def survivor_swing_vfx_row(angle)
    deg = (angle.to_f * 180.0 / Math::PI) % 360.0
    idx = ((deg / 45.0).round) % 8
    [6, 7, 0, 1, 2, 3, 4, 5][idx]
  rescue
    0
  end
  def effect_vfx_frame_index(vfx_name, fx)
    age = fx[8].to_f
    frames = vfx_frame_count(vfx_name)
    return [[(age / 0.42 * frames).floor, 0].max, frames - 1].min if vfx_name == "VFX_LEVEL_UP_BURST"
    source = fx[6]
    if source.respond_to?(:[]) && source[:vfx_sequence].is_a?(Array)
      sequence = source[:vfx_sequence]
      step = source[:vfx_frame_time] ? source[:vfx_frame_time].to_f : 0.085
      index = [[(age / [step, 0.01].max).floor, 0].max, sequence.length - 1].min
      return [[sequence[index].to_i, 0].max, frames - 1].min
    end
    fps = source.respond_to?(:[]) && source[:vfx_fps] ? source[:vfx_fps].to_f : 12.0
    frame = (age * fps).floor
    loop_enabled = source.respond_to?(:[]) && source[:vfx_loop] == true
    return [[frame, 0].max, frames - 1].min if source.respond_to?(:[]) && source[:vfx_loop] == false
    return [[frame, 0].max, frames - 1].min if !loop_enabled && (vfx_name == "VFX_ICE_ZONE" || vfx_name == "VFX_GROUND_ZONE" || vfx_name == "VFX_GROUND2" || vfx_name == "VFX_GROUND3" || vfx_name == "VFX_WATER_ZONE")
    frame % frames
  rescue
    0
  end

  def draw_chestboss_currency_popup(bitmap)
    data = @chestboss_currency_popup
    return if !data
    fill_run_reward_popup_stack
    now = System.uptime rescue 0.0
    age = now - data[:start].to_f
    duration = [data[:duration].to_f, 0.1].max
    if age >= duration
      advance_run_reward_popup
      return
    end
    draw_run_reward_popup_row(bitmap, data, age, duration, 70)
    (data[:stack] || []).each_with_index do |entry, index|
      draw_run_reward_popup_row(bitmap, entry, age, duration, 70 + (index + 1) * 66)
    end
  end

  def draw_run_reward_popup_row(bitmap, data, age, duration, y)
    slide_in = [[age / 0.22, 0.0].max, 1.0].min
    slide_out = age > duration - 0.34 ? [[(duration - age) / 0.34, 0.0].max, 1.0].min : 1.0
    slide = [slide_in, slide_out].min
    panel_w = data[:name] ? [300, Graphics.width - 24].min : 132
    panel_h = data[:name] ? 60 : 38
    x = (Graphics.width + 6 - ((panel_w + 18) * slide)).round
    alpha = (176 * slide).round
    text_alpha = (255 * slide).round
    draw_soft_badge(bitmap, x, y, panel_w, panel_h, Color.new(0, 0, 0, alpha))
    if data[:name]
      draw_text_box_ellipsis(bitmap, data[:name], x + 12, y + 5, panel_w - 24, 24,
                            Color.new(255, 255, 255, text_alpha), Color.new(32, 32, 40, text_alpha))
      draw_text_box(bitmap, _INTL("Lv.{1}", data[:level]), x + 12, y + 31, panel_w - 24, 24,
                    Color.new(255, 238, 160, text_alpha), Color.new(32, 32, 40, text_alpha))
      return
    end
    icon = (data[:icon_dir] ? cached_bitmap(data[:icon_dir], data[:icon]) : cached_icon_bitmap(data[:icon])) rescue nil
    if icon && !icon.disposed?
      icon_size = [icon.width, icon.height, 24].min
      src_x = [(icon.width - icon_size) / 2, 0].max
      src_y = [(icon.height - icon_size) / 2, 0].max
      bitmap.blt(x + 12, y + ((panel_h - icon_size) / 2), icon, Rect.new(src_x, src_y, icon_size, icon_size), text_alpha)
    end
    amount = [data[:amount].to_i, 0].max
    draw_text_box(bitmap, "x#{amount}", x + 44, y + 9, panel_w - 54, 22, Color.new(255, 238, 160, text_alpha), Color.new(32, 32, 40, text_alpha), false)
  rescue
  end
  def draw_hud(bitmap)
    pbSetSystemFont(bitmap)
    hp_rate = [[@hero.hp.to_f / [@hero.max_hp, 1].max, 0].max, 1].min
    xp_rate = [[@xp.to_f / [@xp_next, 1].max, 0].max, 1].min
    hp_color = if hp_rate > 0.50
                 Color.new(92, 255, 132)
               elsif hp_rate >= 0.25
                 Color.new(255, 174, 64)
               else
                 Color.new(255, 84, 96)
               end
    gauge_flash = @gauge_flash_timer.to_f > 0
    draw_soft_badge(bitmap, 8, 8, Graphics.width - 16, 56, Color.new(0, 0, 0, 130))
    draw_status_bar(bitmap, 18, 14, 178, 12, hp_rate, hp_color, gauge_flash)
    if @ultimate_data
      ultimate_rate = [[@ultimate_charge.to_f / [@ultimate_data[:cooldown].to_f, 1.0].max, 0.0].max, 1.0].min
      ultimate_ready = ultimate_rate >= 1.0
      ultimate_color = ultimate_ready ? Color.new(255, 218, 82) : Color.new(178, 116, 255)
      draw_status_bar(bitmap, 18, 31, 178, 12, ultimate_rate, ultimate_color, @ultimate_ready_flash.to_f > 0)
    end
    unless (respond_to?(:breach_mode?) && breach_mode?) || (respond_to?(:challenge_mode?) && challenge_mode?)
      draw_status_bar(bitmap, 18, 48, 178, 10, xp_rate, Color.new(78, 174, 255), gauge_flash, true)
    end
    time = @timer.to_i
    positions = [[_INTL("Lv.{1}", @level), 214, 27, false, Color.white, Color.new(40, 40, 48)]]
    if respond_to?(:titan_mode?) && titan_mode?
      pbDrawTextPositions(bitmap, positions)
      draw_titan_hud_objective(bitmap)
    elsif rush_mode?
      positions << [_INTL("KOs {1}", @kills), 300, 27, false, Color.white, Color.new(40, 40, 48)]
      pbDrawTextPositions(bitmap, positions)
      draw_rush_boss_icons(bitmap)
    elsif tower_mode?
      floor_txt = _INTL("Floor {1}/{2}", [[@tower_floor.to_i, 1].max, PokemonSurvivor::TOWER_MAX_FLOOR].min, PokemonSurvivor::TOWER_MAX_FLOOR)
      floor_txt = _INTL("Room: {1}", @tower_floor) if respond_to?(:breach_mode?) && breach_mode?
      positions << [floor_txt, Graphics.width - 150, 18, false, Color.new(150, 245, 190), Color.new(40, 40, 48)]
      pbDrawTextPositions(bitmap, positions)
      draw_tower_objective_badge(bitmap)
    else
      positions << [_INTL("KOs {1}", @kills), 300, 27, false, Color.white, Color.new(40, 40, 48)]
      txt = _INTL("{1}:{2}", (time / 60).to_s.rjust(2, "0"), (time % 60).to_s.rjust(2, "0"))
      positions << [txt, Graphics.width - 78, 27, false, Color.new(255, 224, 92), Color.new(40, 40, 48)]
      pbDrawTextPositions(bitmap, positions)
    end
  end


  def draw_run_speed_feedback(bitmap)
    return unless @state == :play && run_speed_available?
    if @run_speed_hint_timer.to_f > 0 && !@run_bonus_panel_open
      pbSetSystemFont(bitmap)
      [:speed_down, :speed_up].each_with_index do |action, index|
        y = Graphics.height - 72 + index * 32
        size = defined?(ControlHelpText) ? ControlHelpText::ICON_SIZE : 16
        label = action == :speed_down ? _INTL("Slower") : _INTL("Faster")
        text_w = bitmap.text_size(label).width
        width = [[size + 6 + text_w + 24, 126].max, 214, Graphics.width - 24].min
        text_w = [text_w, width - size - 30].min
        x = 12 + (width - size - 6 - text_w) / 2
        draw_soft_badge(bitmap, 12, y, width, 28, Color.new(0, 0, 0, 142))
        key = PokemonSurvivor.control_key_name(action, PokemonSurvivor.control_current_input_kind)
        draw_control_key_icon(bitmap, key, x, y + (28 - size) / 2)
        draw_text_box_ellipsis(bitmap, label, x + size + 6, y + 5, text_w, 20, Color.new(220, 226, 240), Color.new(32, 32, 40), false)
      end
    end
    return unless @run_speed_notice_timer.to_f > 0 && @run_speed_index.to_i > 0
    icon = cached_icon_bitmap(@run_speed_index == 1 ? "Speedx1" : "Speedx2") if @run_speed_index.to_i > 0
    if icon && !icon.disposed?
      frame_w = icon.width / 2
      frame = ((3.0 - @run_speed_notice_timer) * 6).to_i % 2
      bitmap.blt(12, Graphics.height - icon.height - 12, icon, Rect.new(frame * frame_w, 0, frame_w, icon.height))
    else
      pbSetSystemFont(bitmap)
      draw_soft_badge(bitmap, 12, Graphics.height - 44, 132, 30, Color.new(0, 0, 0, 142))
      draw_text_box_ellipsis(bitmap, _INTL("Speed: x{1}", run_speed_multiplier), 20, Graphics.height - 39, 116, 22, Color.new(235, 240, 255), Color.new(32, 32, 40), 1)
    end
  end

  def show_run_info_hint?
    @run_info_hint_timer.to_f > 0 && @state == :play && !@run_bonus_panel_open
  rescue
    false
  end

  def draw_run_info_hint(bitmap)
    fade = [[@run_info_hint_timer.to_f / 0.45, 0.0].max, 1.0].min
    alpha = (142 * fade).round
    text_alpha = (235 * fade).round
    label = _INTL("Run Info")
    pbSetSystemFont(bitmap)
    icon_size = defined?(ControlHelpText) ? ControlHelpText::ICON_SIZE : 16
    gap = 6
    text_w = bitmap.text_size(label).width rescue 70
    box_w = [[icon_size + gap + text_w + 24, 126].max, 214].min
    box_h = 28
    x = 12
    y = 70
    draw_soft_badge(bitmap, x, y, box_w, box_h, Color.new(0, 0, 0, alpha))
    content_w = icon_size + gap + [text_w, box_w - icon_size - gap - 24].min
    start_x = x + ((box_w - content_w) / 2)
    if defined?(ControlHelpText)
      ControlHelpText.draw_icon(bitmap, :action, start_x, y + ((box_h - icon_size) / 2)) rescue nil
      draw_text_box_ellipsis(bitmap, label, start_x + icon_size + gap, y + 5, box_w - (start_x - x) - icon_size - gap - 10, 20, Color.new(220, 226, 240, text_alpha), Color.new(32, 32, 40, text_alpha), false)
    else
      draw_text_box_ellipsis(bitmap, _INTL("A: {1}", label), x + 8, y + 5, box_w - 16, 20, Color.new(220, 226, 240, text_alpha), Color.new(32, 32, 40, text_alpha), 2)
    end
  rescue
  end
  def show_run_objective_popup?
    @run_objective_popup_timer.to_f > 0 && @run_objective_popup_text && !@run_objective_popup_text.to_s.empty?
  rescue
    false
  end

  def draw_run_objective_popup(bitmap)
    label = @run_objective_popup_text.to_s
    return if label.empty?
    pbSetSystemFont(bitmap)
    text_w = bitmap.text_size(label).width rescue 150
    box_w = [[text_w + 28, 158].max, 286].min
    box_h = 30
    x = [[(hero_visual_x - (box_w / 2)).round, 8].max, Graphics.width - box_w - 8].min
    y = [[(hero_visual_y - 62).round, 68].max, Graphics.height - box_h - 8].min
    fade = [[@run_objective_popup_timer.to_f / 0.45, 0.0].max, 1.0].min
    alpha = (168 * fade).round
    edge_alpha = (225 * fade).round
    draw_soft_badge(bitmap, x, y, box_w, box_h, Color.new(0, 0, 0, alpha))
    draw_text_box_ellipsis(bitmap, label, x + 8, y + 5, box_w - 16, 20, Color.new(255, 238, 160, edge_alpha), Color.new(36, 36, 44, edge_alpha), 2)
  rescue
  end
  def tower_objective_text
    if @tower_floor.to_i >= PokemonSurvivor::TOWER_MAX_FLOOR
      boss = (@tower_final_boss_name || PokemonSurvivor::TOWER_FINAL_BOSS).to_s
      return _INTL("Objective: Defeat {1}", boss)
    elsif respond_to?(:tower_egg_floor?) && tower_egg_floor?
      done = @tower_egg_hatched_this_floor ? 1 : 0
      return _INTL("Objective: Hatch Egg {1}/1", done)
    elsif tower_floor_boss_floor?
      return _INTL("Objective: Defeat the boss")
    end
    needed = tower_floor_required_kos
    done = [[@kills.to_i - @tower_floor_kills_start.to_i, 0].max, needed].min
    _INTL("Objective: KOs {1}/{2}", done, needed)
  rescue
    _INTL("Objective: Climb")
  end

  def draw_tower_objective_badge(bitmap)
    label = tower_objective_text
    box_w = 214
    x = Graphics.width - box_w - 12
    y = 44
    draw_soft_badge(bitmap, x, y, box_w, 20, Color.new(0, 0, 0, 142))
    draw_text_box(bitmap, label, x + 8, y, box_w - 16, 20, Color.new(220, 244, 230), Color.new(34, 42, 48), false)
  rescue
  end

  def draw_tower_floor_transition_overlay(bitmap)
    alpha = [[@tower_fade_alpha.to_i, 0].max, 255].min
    return if alpha <= 0
    bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0, alpha))
  rescue
  end
  def draw_rush_boss_icons(bitmap)
    total = (@rush_total_waves.to_i <= 0 ? 4 : @rush_total_waves.to_i)
    defeated = [[@rush_wave_index.to_i, 0].max, total].min
    icon_name = "ICON_BOSS_RUSH"
    icon = cached_icon_bitmap(icon_name)
    size = icon && !icon.disposed? ? [(icon.width * 0.5).round, 8].max : 11
    gap = 3
    full_w = (size * total) + (gap * (total - 1))
    x = Graphics.width - full_w - 18
    y = 24
    total.times do |i|
      icon = i < defeated ? cached_monochrome_icon_bitmap(icon_name) : cached_icon_bitmap(icon_name)
      if icon && !icon.disposed?
        src = Rect.new(0, 0, icon.width, icon.height)
        dest = Rect.new(x + (i * (size + gap)), y, size, size)
        bitmap.stretch_blt(dest, icon, src, i < defeated ? 170 : 255)
      else
        color = i < defeated ? Color.new(112, 112, 122) : Color.new(218, 88, 255)
        bitmap.fill_rect(x + (i * (size + gap)), y, size, size, Color.new(30, 30, 40))
        bitmap.fill_rect(x + (i * (size + gap)) + 2, y + 2, size - 4, size - 4, color)
      end
    end
  rescue
  end
  def draw_ultimate_prompt(bitmap)
    pbSetSystemFont(bitmap)
    label = _INTL("Burst")
    icon_w = defined?(ControlHelpText) ? ControlHelpText::ICON_SIZE : 16
    text_w = bitmap.text_size(label).width rescue 54
    box_w = [[text_w + icon_w + 28, 84].max, 136].min
    x = [[(hero_visual_x - (box_w / 2)).round, 6].max, Graphics.width - box_w - 6].min
    y = [[(hero_visual_y + 31).round, 6].max, Graphics.height - 28].min
    draw_soft_badge(bitmap, x, y, box_w, 22, Color.new(0, 0, 0, 130))
    text_x = x + 8
    pbDrawTextPositions(bitmap, [[label, text_x, y + 1, false, Color.new(255, 224, 92), Color.new(40, 40, 48)]])
    icon_x = text_x + text_w + 6
    if defined?(ControlHelpText)
      ControlHelpText.draw_icon(bitmap, :confirm, icon_x, y + 4)
    else
      pbDrawTextPositions(bitmap, [["C", icon_x, y + 1, false, Color.white, Color.new(40, 40, 48)]])
    end
  rescue
  end

  def show_ultimate_prompt?
    ultimate_ready? && @ultimate_prompt_timer.to_f > 0
  rescue
    false
  end

  def draw_soft_badge(bitmap, x, y, w, h, color)
    bitmap.fill_rect(x + 4, y, w - 8, h, color)
    bitmap.fill_rect(x + 2, y + 1, w - 4, h - 2, color)
    bitmap.fill_rect(x + 1, y + 2, w - 2, h - 4, color)
    bitmap.fill_rect(x, y + 4, w, h - 8, color)
  rescue
    bitmap.fill_rect(x, y, w, h, color)
  end

  def draw_status_bar(bitmap, x, y, w, h, rate, color, flash = false, fixed_marks = false)
    rate = [[rate.to_f, 0.0].max, 1.0].min
    bitmap.fill_rect(x, y, w, h, Color.new(3, 6, 13))
    bitmap.fill_rect(x + 1, y + 1, w - 2, h - 2, Color.new(46, 58, 82))
    bitmap.fill_rect(x + 2, y + 2, w - 4, h - 4, Color.new(16, 22, 34))
    fill_w = ((w - 4) * rate).round
    draw_color = if flash && ((System.uptime rescue 0.0) * 18).to_i.even?
                   Color.new([color.red + 64, 255].min, [color.green + 64, 255].min, [color.blue + 64, 255].min)
                 else
                   color
                 end
    light = Color.new([draw_color.red + 52, 255].min, [draw_color.green + 52, 255].min, [draw_color.blue + 52, 255].min)
    if fill_w > 0
      bitmap.fill_rect(x + 2, y + 2, fill_w, h - 4, draw_color)
      bitmap.fill_rect(x + 3, y + 3, [fill_w - 2, 0].max, 2, light)
    end
    if fixed_marks
      step = (w - 4) / 20.0
      empty_mark = Color.new(38, 50, 72)
      1.upto(19) do |i|
        sx = x + 2 + (step * i).round
        mark_color = sx < x + 2 + fill_w ? light : empty_mark
        bitmap.fill_rect(sx, y + 3, 1, [h - 6, 1].max, mark_color)
      end
    elsif fill_w > 0
      stripe_color = light
        stripe = ((System.uptime rescue 0.0) * 32).to_i % 12
        sx = x + 2 - stripe
        while sx < x + 2 + fill_w
          bitmap.fill_rect(sx, y + 3, 1, [h - 6, 1].max, stripe_color) if sx >= x + 2
          sx += 12
        end
    end
  rescue
  end

  def cached_enemy_status_bar_bitmap(w, h, fill_w, color)
    @bitmaps ||= {}
    fill_w = [[fill_w.to_i, 0].max, w.to_i - 4].min
    fill_w = ((fill_w + 1) / 2) * 2 if w.to_i <= 42
    key = "enemy_hp_bar:#{w}:#{h}:#{fill_w}:#{color.red}:#{color.green}:#{color.blue}"
    cached = @bitmaps[key]
    return cached if cached && !cached.disposed?
    bmp = Bitmap.new(w, h)
    bmp.fill_rect(0, 0, w, h, Color.new(3, 6, 13, 210))
    bmp.fill_rect(1, 1, w - 2, h - 2, Color.new(46, 58, 82, 225))
    bmp.fill_rect(2, 2, w - 4, h - 4, Color.new(16, 22, 34, 235))
    light = Color.new([color.red + 52, 255].min, [color.green + 52, 255].min, [color.blue + 52, 255].min)
    if fill_w > 0
      bmp.fill_rect(2, 2, fill_w, h - 4, color)
      bmp.fill_rect(3, 3, [fill_w - 2, 0].max, 1, light)
    end
    step = (w - 4) / 8.0
    empty_mark = Color.new(38, 50, 72, 225)
    1.upto(7) do |i|
      sx = 2 + (step * i).round
      mark_color = sx < 2 + fill_w ? light : empty_mark
      bmp.fill_rect(sx, 2, 1, [h - 4, 1].max, mark_color)
    end
    @bitmaps[key] = bmp
    bmp
  rescue
    nil
  end

  def draw_enemy_status_bar(bitmap, x, y, w, h, rate, color)
    rate = [[rate.to_f, 0.0].max, 1.0].min
    fill_w = ((w - 4) * rate).round
    bar = cached_enemy_status_bar_bitmap(w, h, fill_w, color)
    if bar && !bar.disposed?
      bitmap.blt(x, y, bar, Rect.new(0, 0, w, h))
      return
    end
    bitmap.fill_rect(x, y, w, h, Color.new(3, 6, 13, 210))
    bitmap.fill_rect(x + 2, y + 2, fill_w, h - 4, color) if fill_w > 0
  rescue
  end


end




























































































