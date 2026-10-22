#===============================================================================
# Color accessibility: drawing palettes, never Pokemon sprite recoloring.
#===============================================================================
module PokemonSurvivor
  COLOR_ACCESSIBILITY_MODES = [:off, :protanopia, :deuteranopia, :tritanopia].freeze
  COLOR_ACCESSIBILITY_PALETTES = {
    protanopia: [[240, 210, 70], [230, 145, 40], [70, 170, 240],
                 [130, 225, 245], [150, 150, 240], [235, 170, 210]],
    deuteranopia: [[240, 190, 60], [220, 115, 45], [85, 180, 245],
                   [155, 225, 245], [170, 150, 230], [235, 170, 210]],
    tritanopia: [[240, 110, 125], [245, 175, 155], [80, 210, 190],
                [160, 235, 220], [65, 165, 170], [220, 145, 185]]
  }.freeze

  module_function

  def normalize_color_accessibility(value)
    value = value.to_sym if value.respond_to?(:to_sym)
    COLOR_ACCESSIBILITY_MODES.include?(value) ? value : :off
  end

  def color_accessibility_mode
    opts = $PokemonSurvivorPerformanceOptions
    opts ? normalize_color_accessibility(opts[:color_accessibility]) : :off
  end

  def color_accessibility_enabled?
    color_accessibility_mode != :off
  end

  def cycle_color_accessibility(direction = 1)
    opts = performance_options
    index = COLOR_ACCESSIBILITY_MODES.index(normalize_color_accessibility(opts[:color_accessibility]))
    opts[:color_accessibility] = COLOR_ACCESSIBILITY_MODES[(index + direction.to_i) % COLOR_ACCESSIBILITY_MODES.length]
    @accessible_color_cache = nil
    save_persistent_survivor_options if respond_to?(:save_persistent_survivor_options)
  end

  def color_accessibility_label
    case color_accessibility_mode
    when :protanopia then _INTL("Protanopia")
    when :deuteranopia then _INTL("Deuteranopia")
    when :tritanopia then _INTL("Tritanopia")
    else _INTL("Off")
    end
  end

  def accessible_color(color)
    mode = color_accessibility_mode
    return color if mode == :off || !color || color.alpha <= 0
    r, g, b = color.red.to_i, color.green.to_i, color.blue.to_i
    high = [r, g, b].max
    low = [r, g, b].min
    delta = high - low
    # Keep neutral text, shadows, and dark panel backgrounds unchanged.
    return color if high < 64 || delta < 24
    if @accessible_color_cache_mode != mode
      @accessible_color_cache_mode = mode
      @accessible_color_cache = {}
    end
    cache = (@accessible_color_cache ||= {})
    key = (r << 24) | (g << 16) | (b << 8) | color.alpha.to_i
    cached = cache[key]
    return cached if cached
    hue = if high == r
            ((g - b).to_f / delta) % 6.0
          elsif high == g
            (b - r).to_f / delta + 2.0
          else
            (r - g).to_f / delta + 4.0
          end
    swatch = COLOR_ACCESSIBILITY_PALETTES[mode][hue.round % 6]
    scale = high / 255.0
    neutral = low.to_f / high
    rgb = swatch.map { |channel| ((channel * (1.0 - neutral) + 255 * neutral) * scale).round }
    result = Color.new(rgb[0], rgb[1], rgb[2], color.alpha)
    cache.clear if cache.length >= 4096
    cache[key] = result
  end

  def accessibility_recolor_effect(bitmap)
    return bitmap if !color_accessibility_enabled? || !bitmap || bitmap.disposed?
    bitmap.height.times do |y|
      bitmap.width.times do |x|
        color = bitmap.get_pixel(x, y)
        next if color.alpha <= 0
        adapted = accessible_color(color)
        bitmap.set_pixel(x, y, adapted) unless adapted.equal?(color)
      end
    end
    bitmap
  end

  def color_accessibility_translation_markers
    _INTL("Color Accessibility")
  end
end

# Primitive UI drawing covers native menus as well as Survivor's generated HUDs.
# blt/stretch_blt/set_pixel are deliberately untouched: Pokemon and Shiny assets
# keep their original pixels, and already-colored cached surfaces aren't tinted twice.
module SurvivorAccessibleBitmap
  def fill_rect(*args)
    args[-1] = PokemonSurvivor.accessible_color(args[-1]) if PokemonSurvivor.color_accessibility_enabled?
    super(*args)
  end

  def gradient_fill_rect(*args)
    if PokemonSurvivor.color_accessibility_enabled?
      offset = args[0].is_a?(Rect) ? 1 : 4
      args[offset] = PokemonSurvivor.accessible_color(args[offset])
      args[offset + 1] = PokemonSurvivor.accessible_color(args[offset + 1])
    end
    super(*args)
  end

  def draw_text(*args)
    return super(*args) unless PokemonSurvivor.color_accessibility_enabled?
    adapted = PokemonSurvivor.accessible_color(font.color)
    return super(*args) if adapted.equal?(font.color)
    original = font.color.clone
    begin
      font.color = adapted
      super(*args)
    ensure
      font.color = original
    end
  end
end
Bitmap.prepend(SurvivorAccessibleBitmap) unless Bitmap.ancestors.include?(SurvivorAccessibleBitmap)
