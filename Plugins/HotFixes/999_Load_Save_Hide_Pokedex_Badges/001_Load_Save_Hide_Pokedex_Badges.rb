#===============================================================================
# Replace vanilla Pokédex/Badges lines with Pokemon Survivor progress stats.
#===============================================================================

module SurvivorLoadSaveStats
  FINISH_KEYS = [:survived_15, :boss_finished, :evolution_finished, :level_finished, :rush_finished, :tower_finished]

  module_function

  def species_key(name)
    return PokemonSurvivor.species_key(name) if defined?(PokemonSurvivor) && PokemonSurvivor.respond_to?(:species_key)
    name.to_s.upcase.gsub(/[^A-Z0-9_]/, "").to_sym
  rescue
    name.to_sym rescue nil
  end

  def progress_from_save_data(save_data)
    global = save_data[:global_metadata] || save_data[:pokemon_global] rescue nil
    progress_from_global(global)
  rescue
    nil
  end

  def progress_from_global(global)
    return nil if !global
    global.instance_variable_get(:@pokemon_survivor_progress)
  rescue
    nil
  end

  def current_progress
    return PokemonSurvivor.survivor_progress if defined?(PokemonSurvivor) && PokemonSurvivor.respond_to?(:survivor_progress)
    progress_from_global($PokemonGlobal)
  rescue
    nil
  end

  def known_hero_keys
    if defined?(PokemonSurvivor) && PokemonSurvivor.const_defined?(:BASE_HERO_KEYS)
      return PokemonSurvivor::BASE_HERO_KEYS.map { |key| species_key(key) }.uniq
    end
    []
  rescue
    []
  end

  def stats_for_progress(progress)
    progress ||= {}
    unlocked = Array(progress[:unlocked]).map { |entry| species_key(entry) }.compact.uniq
    if defined?(PokemonSurvivor) && PokemonSurvivor.const_defined?(:INITIAL_UNLOCKED_HEROES)
      unlocked = (PokemonSurvivor::INITIAL_UNLOCKED_HEROES.map { |key| species_key(key) } + unlocked).uniq
    end
    known = known_hero_keys
    unlocked &= known if !known.empty?
    completed = unlocked.count do |key|
      FINISH_KEYS.all? do |finish_key|
        Array(progress[finish_key]).map { |entry| species_key(entry) }.include?(key)
      end
    end
    [unlocked.length, completed]
  rescue
    [0, 0]
  end

  def stats_for_save_data(save_data)
    stats_for_progress(progress_from_save_data(save_data))
  end

  def current_stats
    stats_for_progress(current_progress)
  end

  def load_stat_positions(bitmap, label, value, y, base, shadow)
    left = 32
    right = bitmap.width - 32
    value = value.to_s
    available = [right - left - bitmap.text_size(value).width - 16, 0].max
    label = label.to_s
    if bitmap.text_size(label).width > available
      characters = label.scan(/\X/)
      characters.pop while !characters.empty? && bitmap.text_size(characters.join + "...").width > available
      label = bitmap.text_size("...").width <= available ? characters.join + "..." : ""
    end
    [[label, left, y, :left, base, shadow],
     [value, right, y, :right, base, shadow]]
  end
end

class PokemonLoadPanel < Sprite
  def survivor_progress_stats=(value)
    @survivor_progress_stats = value
    @refreshBitmap = true
    refresh
  end

  def refresh
    return if @refreshing
    return if disposed?
    @refreshing = true
    if !self.bitmap || self.bitmap.disposed?
      self.bitmap = Bitmap.new(@bgbitmap.width, 222)
      pbSetSystemFont(self.bitmap)
    end
    if @refreshBitmap
      @refreshBitmap = false
      self.bitmap&.clear
      if @isContinue
        self.bitmap.blt(0, 0, @bgbitmap.bitmap, Rect.new(0, (@selected) ? 222 : 0, @bgbitmap.width, 222))
      else
        self.bitmap.blt(0, 0, @bgbitmap.bitmap, Rect.new(0, 444 + ((@selected) ? 46 : 0), @bgbitmap.width, 46))
      end
      textpos = []
      if @isContinue
        unlocked, completed = @survivor_progress_stats || [0, 0]
        textpos.push([@title, 32, 16, :left, TEXT_COLOR, TEXT_SHADOW_COLOR])
        if @trainer.male?
          textpos.push([@trainer.name, 32, 70, :left, MALE_TEXT_COLOR, MALE_TEXT_SHADOW_COLOR])
        elsif @trainer.female?
          textpos.push([@trainer.name, 32, 70, :left, FEMALE_TEXT_COLOR, FEMALE_TEXT_SHADOW_COLOR])
        else
          textpos.push([@trainer.name, 32, 70, :left, TEXT_COLOR, TEXT_SHADOW_COLOR])
        end
        textpos.concat(SurvivorLoadSaveStats.load_stat_positions(self.bitmap, _INTL("Unlocked Pokemon:"), unlocked, 118, TEXT_COLOR, TEXT_SHADOW_COLOR))
        textpos.concat(SurvivorLoadSaveStats.load_stat_positions(self.bitmap, _INTL("Completed Pokemon:"), completed, 150, TEXT_COLOR, TEXT_SHADOW_COLOR))
        textpos.push([_INTL("Time:"), 32, 182, :left, TEXT_COLOR, TEXT_SHADOW_COLOR])
        hour = @totalsec / 60 / 60
        min  = @totalsec / 60 % 60
        if hour > 0
          textpos.push([_INTL("{1}h {2}m", hour, min), 206, 182, :right, TEXT_COLOR, TEXT_SHADOW_COLOR])
        else
          textpos.push([_INTL("{1}m", min), 206, 182, :right, TEXT_COLOR, TEXT_SHADOW_COLOR])
        end
      else
        textpos.push([@title, 32, 14, :left, TEXT_COLOR, TEXT_SHADOW_COLOR])
      end
      pbDrawTextPositions(self.bitmap, textpos)
    end
    @refreshing = false
  rescue
    @refreshing = false
  end
end

class PokemonLoad_Scene
  alias survivor_stats_pbStartScene pbStartScene
  def pbStartScene(commands, show_continue, trainer, stats, map_id)
    survivor_stats_pbStartScene(commands, show_continue, trainer, stats, map_id)
    if show_continue && @sprites && @sprites["panel0"] && @survivor_load_stats
      @sprites["panel0"].survivor_progress_stats = @survivor_load_stats
    end
  end

  def survivor_load_stats=(value)
    @survivor_load_stats = value
  end

  def pbSetParty(_trainer)
    # Intentionally empty: the load screen now shows save text only.
  end
end

class PokemonLoadScreen
  alias survivor_stats_pbStartLoadScreen pbStartLoadScreen
  def pbStartLoadScreen
    @scene.survivor_load_stats = SurvivorLoadSaveStats.stats_for_save_data(@save_data) if @scene.respond_to?(:survivor_load_stats=)
    survivor_stats_pbStartLoadScreen
  end
end

class PokemonSave_Scene
  def pbStartScreen
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    totalsec = $stats.play_time.to_i
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    mapname = $game_map.name
    if $player.male?
      text_tag = shadowc3tag(MALE_TEXT_BASE, MALE_TEXT_SHADOW)
    elsif $player.female?
      text_tag = shadowc3tag(FEMALE_TEXT_BASE, FEMALE_TEXT_SHADOW)
    else
      text_tag = shadowc3tag(OTHER_TEXT_BASE, OTHER_TEXT_SHADOW)
    end
    location_tag = shadowc3tag(LOCATION_TEXT_BASE, LOCATION_TEXT_SHADOW)
    unlocked, completed = SurvivorLoadSaveStats.current_stats
    loctext = location_tag + "<ac>" + mapname + "</ac></c3>"
    loctext += _INTL("Player") + "<r>" + text_tag + $player.name + "</c3><br>"
    loctext += _INTL("Unlocked Pokemon") + "<r>" + text_tag + unlocked.to_s + "</c3><br>"
    loctext += _INTL("Completed Pokemon") + "<r>" + text_tag + completed.to_s + "</c3><br>"
    if hour > 0
      loctext += _INTL("Time") + "<r>" + text_tag + _INTL("{1}h {2}m", hour, min) + "</c3>"
    else
      loctext += _INTL("Time") + "<r>" + text_tag + _INTL("{1}m", min) + "</c3>"
    end
    @sprites["locwindow"] = Window_AdvancedTextPokemon.new(loctext)
    @sprites["locwindow"].viewport = @viewport
    @sprites["locwindow"].x = 0
    @sprites["locwindow"].y = 0
    @sprites["locwindow"].width = 228 if @sprites["locwindow"].width < 228
    @sprites["locwindow"].visible = true
  end
end


