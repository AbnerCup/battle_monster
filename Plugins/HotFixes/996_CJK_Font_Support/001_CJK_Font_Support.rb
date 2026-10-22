#===============================================================================
# CJK font support. Fonts are bundled with the game; no OS installation needed.
#===============================================================================
module SurvivorCJKFonts
  TEXT_Y_OFFSET = 7
  FAMILIES = {
    "korean" => "ko",
    "japanese" => "ja",
    "chinese" => "zh_hans"
  }.freeze
  CJK_TEXT = /[\u1100-\u11ff\u2e80-\u9fff\uac00-\ud7af\uf900-\ufaff\uff00-\uffef]/
  KOREAN_TEXT = /[\u1100-\u11ff\u3130-\u318f\uac00-\ud7af]/
  JAPANESE_TEXT = /[\u3040-\u30ff\u31f0-\u31ff\uff65-\uff9f]/

  def self.selected_language
    return nil unless defined?($PokemonSystem) && $PokemonSystem
    return nil unless defined?(Settings::LANGUAGES)
    entry = Settings::LANGUAGES[$PokemonSystem.language.to_i]
    entry && entry[1].to_s.downcase
  end

  def self.font_for(text, _current_name = "Power Green")
    text = text.to_s
    # In TikTok Tournament mode, keep crisp HD vector font for Latin/ASCII text!
    if defined?($scene) && $scene && $scene.class.name.to_s.include?("TikTok")
      return nil unless CJK_TEXT.match?(text)
    end
    language = selected_language
    return nil unless FAMILIES.key?(language) || CJK_TEXT.match?(text)
    # Script detection also renders the language picker before a CJK language
    # has been selected. Han-only strings use the selected regional variant.
    key = if KOREAN_TEXT.match?(text)
            "korean"
          elsif JAPANESE_TEXT.match?(text) || text == "\u65e5\u672c\u8a9e"
            "japanese"
          else
            FAMILIES.key?(language) ? language : "chinese"
          end
    family = "Fusion Poke Pixel Small #{FAMILIES[key]}"
    @available ||= {}
    @available[family] = Font.exist?(family) unless @available.key?(family)
    @available[family] ? family : nil
  end

  def self.with_font(bitmap, text)
    family = font_for(text, bitmap.font.name)
    return yield(false) unless family
    font = bitmap.font
    old_name = font.name
    old_size = font.size
    begin
      font.name = family
      # Always use Small's 25px reference size, preserving custom size ratios.
      pixel_font = Array(old_name).any? { |name| name.to_s.start_with?("Power ") }
      if pixel_font
        small_source = Array(old_name).any? { |name| name.to_s.include?("Small") }
        base_size = small_source ? 21.0 : 27.0
        font.size = [(old_size * 25.0 / base_size).round, 12].max
      end
      yield(true)
    ensure
      font.name = old_name
      font.size = old_size
    end
  end
end

module SurvivorCJKBitmapText
  def draw_text(*args)
    text = args[0].is_a?(Rect) ? args[1] : args[4]
    SurvivorCJKFonts.with_font(self, text) do |using_cjk|
      if using_cjk
        # Leave layout measurements unchanged and never mutate a caller's Rect.
        if args[0].is_a?(Rect)
          args[0] = Rect.new(args[0].x, args[0].y + SurvivorCJKFonts::TEXT_Y_OFFSET,
                             args[0].width, args[0].height)
        else
          args[1] += SurvivorCJKFonts::TEXT_Y_OFFSET
        end
      end
      super(*args)
    end
  end

  def text_size(text)
    SurvivorCJKFonts.with_font(self, text) { super(text) }
  end
end

Bitmap.prepend(SurvivorCJKBitmapText) unless Bitmap.ancestors.include?(SurvivorCJKBitmapText)
