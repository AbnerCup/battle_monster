#===============================================================================
# Wine/macOS compatibility layer
#===============================================================================
# Some Wine/macOS setups are stricter than Windows about the working directory,
# filename casing, and asset path encoding. This patch only intervenes when the
# normal asset lookup fails.
#===============================================================================

module SurvivorWineCompat
  module_function

  GRAPHIC_EXTS = ["png", "bmp"]
  AUDIO_EXTS   = ["ogg", "wav", "mp3", "mid"]
  FORCE_ENABLE = false unless const_defined?(:FORCE_ENABLE)

  def wine_runtime?
    ENV.keys.each { |key| return true if key.to_s.upcase.start_with?("WINE") } rescue nil
    false
  rescue
    false
  end

  def active?
    return @active if !@active.nil?
    return @active = true if FORCE_ENABLE
    platform = RUBY_PLATFORM.to_s.downcase
    return @active = true if platform[/darwin|linux/]
    return @active = true if wine_runtime?
    @active = false
  rescue
    false
  end

  def game_root
    return @game_root if @game_root && FileTest.directory?(@game_root)
    candidates = []
    candidates << File.expand_path("../..", __dir__) if defined?(__dir__)
    candidates << Dir.pwd
    current = File.expand_path(Dir.pwd) rescue Dir.pwd
    5.times do
      candidates << current
      parent = File.expand_path("..", current) rescue current
      break if parent == current
      current = parent
    end
    @game_root = candidates.compact.uniq.find do |path|
      FileTest.directory?(File.join(path, "Graphics")) && FileTest.directory?(File.join(path, "Audio"))
    end || File.expand_path("../..", __dir__)
  rescue
    Dir.pwd
  end

  def normalize_key(value)
    text = value.to_s.downcase
    text = text.unicode_normalize(:nfd).gsub(/\p{Mn}/, "") if text.respond_to?(:unicode_normalize)
    text.tr("àáâãäåæçèéêëìíîïñòóôõöøùúûüýÿ", "aaaaaaaceeeeiiiinoooooouuuuyy")
  rescue
    value.to_s.downcase
  end

  def path_parts(path)
    path.to_s.tr("\\", "/").split("/").reject { |part| part.nil? || part.empty? || part == "." }
  rescue
    []
  end

  def resolve_case_path(path)
    return path if FileTest.exist?(path)
    absolute = path.to_s[/\A[A-Za-z]:[\\\/]/] || path.to_s.start_with?("/")
    base = absolute ? File::SEPARATOR : game_root
    parts = path_parts(absolute ? path.sub(/\A[A-Za-z]:[\\\/]?/, "") : path)
    if absolute && path.to_s[/\A([A-Za-z]:)/]
      base = $1 + File::SEPARATOR
    end
    parts.each do |part|
      return nil if !FileTest.directory?(base)
      exact = File.join(base, part)
      if FileTest.exist?(exact)
        base = exact
        next
      end
      wanted = normalize_key(part)
      match = Dir.children(base).find { |entry| normalize_key(entry) == wanted } rescue nil
      return nil if !match
      base = File.join(base, match)
    end
    FileTest.exist?(base) ? base : nil
  rescue
    nil
  end

  def resolve_existing(path, extensions = nil)
    @path_cache ||= {}
    key = [path.to_s, (extensions || []).join("|")].join("::")
    cached = @path_cache[key]
    return cached if @path_cache.key?(key)
    candidates = [path.to_s]
    if extensions && File.extname(path.to_s).empty?
      extensions.each { |ext| candidates << "#{path}.#{ext}" }
    end
    result = nil
    candidates.each do |candidate|
      candidate = candidate.tr("\\", "/")
      local = candidate[/\A[A-Za-z]:[\\\/]/] || candidate.start_with?("/") ? candidate : File.join(game_root, candidate)
      result = FileTest.exist?(local) ? local : resolve_case_path(local)
      break if result
    end
    @path_cache[key] = result
    result
  rescue
    nil
  end

  def resolve_graphic(path)
    resolve_existing(path, GRAPHIC_EXTS)
  end

  def resolve_audio(path)
    resolve_existing(path, AUDIO_EXTS)
  end
end

if SurvivorWineCompat.active? && defined?(Kernel)
  module Kernel
    if method_defined?(:pbResolveBitmap) && !method_defined?(:survivor_wine_pbResolveBitmap)
      alias survivor_wine_pbResolveBitmap pbResolveBitmap
      def pbResolveBitmap(path)
        resolved = survivor_wine_pbResolveBitmap(path) rescue nil
        return resolved if resolved
        SurvivorWineCompat.resolve_graphic(path)
      rescue
        nil
      end
    end

    if method_defined?(:pbBitmap) && !method_defined?(:survivor_wine_pbBitmap)
      alias survivor_wine_pbBitmap pbBitmap
      def pbBitmap(name)
        resolved = SurvivorWineCompat.resolve_graphic(name)
        if resolved
          bmp = Bitmap.new(resolved) rescue nil
          if bmp
            bmp.storedPath = name rescue nil
            return bmp
          end
        end
        survivor_wine_pbBitmap(name)
      rescue
        survivor_wine_pbBitmap(name) rescue Bitmap.new(2, 2)
      end
    end
  end
end

if SurvivorWineCompat.active? && defined?(PokemonSurvivor)
  module PokemonSurvivor
    class << self
      if method_defined?(:resolve) && !method_defined?(:survivor_wine_resolve)
        alias survivor_wine_resolve resolve
        def resolve(folder, name)
          resolved = survivor_wine_resolve(folder, name) rescue nil
          return resolved if resolved
          SurvivorWineCompat.resolve_graphic("#{folder}/#{name}")
        rescue
          nil
        end
      end

      if method_defined?(:audio_bgm_exists?) && !method_defined?(:survivor_wine_audio_bgm_exists?)
        alias survivor_wine_audio_bgm_exists? audio_bgm_exists?
        def audio_bgm_exists?(name)
          return true if survivor_wine_audio_bgm_exists?(name) rescue false
          !!SurvivorWineCompat.resolve_audio("Audio/BGM/#{name}")
        rescue
          false
        end
      end
    end
  end
end