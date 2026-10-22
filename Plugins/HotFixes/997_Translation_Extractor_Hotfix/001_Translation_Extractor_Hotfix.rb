#===============================================================================
# Translation extraction hotfix
#-------------------------------------------------------------------------------
# Keeps the vanilla translation files, compilation and encryption pipeline, but
# improves detection of static _INTL/_ISPRINTF/_I strings and adds display text
# stored in plugin data tables.
#===============================================================================

if defined?(Translator)
  module Translator
    class << self
      if method_defined?(:gather_script_and_event_texts) && !method_defined?(:pokemon_survivor_vanilla_gather_script_and_event_texts)
        alias pokemon_survivor_vanilla_gather_script_and_event_texts gather_script_and_event_texts
      end
    end

    DISPLAY_TEXT_KEYS = [
      :name, :desc, :description, :text, :label, :title, :message,
      "name", "desc", "description", "text", "label", "title", "message"
    ] if !const_defined?(:DISPLAY_TEXT_KEYS)

    module_function

    def gather_script_and_event_texts
      pokemon_survivor_vanilla_gather_script_and_event_texts if respond_to?(:pokemon_survivor_vanilla_gather_script_and_event_texts)
      extra_texts = []
      gather_extra_plugin_script_texts(extra_texts)
      gather_runtime_table_texts(extra_texts)
      extra_texts.compact!
      extra_texts.map! { |text| text.to_s }
      extra_texts.reject! { |text| text.empty? }
      extra_texts.uniq!
      if defined?(MessageTypes) && MessageTypes.const_defined?(:SCRIPT_TEXTS) && !extra_texts.empty?
        MessageTypes.addMessagesAsHash(MessageTypes::SCRIPT_TEXTS, extra_texts)
        add_core_messages_as_hash(MessageTypes::SCRIPT_TEXTS, extra_texts)
      end
    rescue
      # Extraction must never stop the vanilla compiler from running.
    end


    def add_core_messages_as_hash(type, texts)
      return if !defined?(MessageTypes) || !defined?(Translation)
      messages = MessageTypes.class_variable_get(:@@messages) rescue nil
      return if !messages
      messages.load_default_messages if messages.respond_to?(:load_default_messages)
      core_messages = messages.instance_variable_get(:@default_core_messages)
      core_messages = [] if !core_messages.is_a?(Array)
      messages.instance_variable_set(:@default_core_messages, core_messages)
      core_messages[type] = {} if !core_messages[type].is_a?(Hash)
      texts.each do |text|
        next if !text || text.empty?
        key = Translation.stringToKey(text)
        next if !key || key.empty?
        core_messages[type][key] = text
      end
    rescue
    end
    def find_translatable_text_from_RGSS_script(items, script)
      scan_translatable_calls(items, script, ["_INTL", "_ISPRINTF", "_I"])
    end

    # Plugin data keeps English source text until the UI displays it.
    def scan_plugin_display_strings(items, script)
      source = script.to_s.dup.force_encoding(Encoding::UTF_8)
      matcher = /(?<![A-Za-z0-9_])(?:name|desc|description|text|label|title|message|tag|hint)\s*:\s*/
      source.to_enum(:scan, matcher).each do
        text, _after = read_first_static_string_argument(source, Regexp.last_match.end(0))
        add_translator_text(items, text) if text && !text.empty? && !text.include?('#{')
      end
    end

    def find_translatable_text_from_event_script(items, script)
      scan_translatable_calls(items, script, ["_I", "_INTL", "_ISPRINTF"])
    end

    def scan_translatable_calls(items, script, names)
      source = script.to_s.dup
      source.force_encoding(Encoding::UTF_8) if source.respond_to?(:force_encoding)
      source = source.encode("UTF-8", invalid: :replace, undef: :replace, replace: "") if source.respond_to?(:encode)
      matcher = /(?<![A-Za-z0-9_])(?:#{names.map { |name| Regexp.escape(name) }.join("|")})\s*\(/m
      index = 0
      while (match = matcher.match(source, index))
        text, after = read_first_static_string_argument(source, match.end(0))
        add_translator_text(items, text) if text && !text.empty?
        index = [after || match.end(0), match.end(0) + 1].max
      end
    rescue
    end

    def read_first_static_string_argument(source, index)
      index = skip_space_and_comments(source, index)
      text, index = read_ruby_string_literal(source, index)
      return [nil, index] if !text
      loop do
        next_index = skip_space_and_comments(source, index)
        extra, after = read_ruby_string_literal(source, next_index)
        break if !extra
        text += extra
        index = after
      end
      [text, index]
    end

    def skip_space_and_comments(source, index)
      loop do
        index += 1 while index < source.length && source[index] =~ /\s/
        if source[index] == "#"
          index += 1
          index += 1 while index < source.length && source[index] != "\n"
        else
          break
        end
      end
      index
    rescue
      index
    end

    def read_ruby_string_literal(source, index)
      char = source[index]
      return read_quoted_string(source, index, char, char == '"') if char == '"' || char == "'"
      return read_percent_string(source, index) if char == "%"
      [nil, index]
    end

    def read_quoted_string(source, index, quote, expand_escapes)
      i = index + 1
      output = ""
      escaped = false
      while i < source.length
        char = source[i]
        if escaped
          output << decode_string_escape(char, expand_escapes)
          escaped = false
        elsif char == "\\"
          escaped = true
        elsif char == quote
          return [output, i + 1]
        else
          output << char
        end
        i += 1
      end
      [nil, index]
    end

    def read_percent_string(source, index)
      return [nil, index] if source[index] != "%"
      marker = source[index + 1]
      if marker == "Q" || marker == "q"
        open_char = source[index + 2]
        i = index + 3
        expand_escapes = marker == "Q"
      else
        open_char = marker
        i = index + 2
        expand_escapes = true
      end
      return [nil, index] if !open_char
      pairs = { "(" => ")", "[" => "]", "{" => "}", "<" => ">" }
      close_char = pairs[open_char] || open_char
      nesting = 0
      output = ""
      escaped = false
      while i < source.length
        char = source[i]
        if escaped
          output << decode_string_escape(char, expand_escapes)
          escaped = false
        elsif char == "\\"
          escaped = true
        elsif pairs[open_char] && char == open_char
          nesting += 1
          output << char
        elsif char == close_char
          return [output, i + 1] if nesting <= 0
          nesting -= 1
          output << char
        else
          output << char
        end
        i += 1
      end
      [nil, index]
    end

    def decode_string_escape(char, expand_escapes)
      return char if !expand_escapes
      case char
      when "n" then "\n"
      when "r" then "\r"
      when "t" then "\t"
      when "1" then "\1"
      else char
      end
    end

    def gather_extra_plugin_script_texts(items)
      paths = []
      paths = Dir.glob("Plugins/**/*.rb") if defined?(Dir) && Dir.respond_to?(:glob)
      paths.each_with_index do |path, i|
        Graphics.update if defined?(Graphics) && i % 24 == 0
        File.open(path, "rb") do |file|
          source = file.read
          find_translatable_text_from_RGSS_script(items, source)
          scan_plugin_display_strings(items, source)
        end
      rescue
      end
    rescue
    end

    def gather_runtime_table_texts(items)
      gather_pokemon_survivor_table_texts(items)
      gather_scene_pokemon_survivor_texts(items)
      if defined?(PokemonSurvivorAchievements)
        collect_display_strings(items, PokemonSurvivorAchievements::ACHIEVEMENTS) if PokemonSurvivorAchievements.const_defined?(:ACHIEVEMENTS)
        collect_all_strings(items, PokemonSurvivorAchievements::RARITY_NAMES) if PokemonSurvivorAchievements.const_defined?(:RARITY_NAMES)
      end
    rescue
    end

    def gather_pokemon_survivor_table_texts(items)
      return if !defined?(PokemonSurvivor)
      collect_all_strings(items, PokemonSurvivor::HERO_UNLOCK_REQUIREMENTS) if PokemonSurvivor.const_defined?(:HERO_UNLOCK_REQUIREMENTS)
      [:HERO_PASSIVES, :SKILLS, :ULTIMATES].each do |constant_name|
        next if !PokemonSurvivor.const_defined?(constant_name)
        collect_display_strings(items, PokemonSurvivor.const_get(constant_name))
      end
      [:PASSIVE_UPGRADES, :PASSIVE_UPGRADE_POOL, :UPGRADES, :UPGRADE_POOL,
       :SHOP_UPGRADES, :ENDLESS_SHOP_UPGRADES, :POKEMON_TRAINING_UPGRADES,
       :EQUIPMENT_ITEMS, :BATTLE_PASS_DATA, :BATTLE_PASS_QUESTS,
       :BABY_EVENT_DATA, :SLEEP_EVENT_DATA].each do |constant_name|
        next if !PokemonSurvivor.const_defined?(constant_name)
        collect_display_strings(items, PokemonSurvivor.const_get(constant_name))
      end
      [:RUN_INFO_PANEL_LABELS, :SCREEN_SIZE_LABELS, :BATTLE_PASS_TEXT_FOR_EXTRACTION].each do |constant_name|
        collect_all_strings(items, PokemonSurvivor.const_get(constant_name)) if PokemonSurvivor.const_defined?(constant_name)
      end
    rescue
    end

    def gather_scene_pokemon_survivor_texts(items)
      return if !defined?(Scene_PokemonSurvivor)
      [:PERFORMANCE_OPTION_ITEMS, :SELECT_MENU_ITEMS].each do |constant_name|
        next if !Scene_PokemonSurvivor.const_defined?(constant_name)
        Scene_PokemonSurvivor.const_get(constant_name).each do |item|
          add_translator_text(items, item[1]) if item.is_a?(Array) && item[1].is_a?(String)
        end
      end
      collect_display_strings(items, Scene_PokemonSurvivor::JOKER_EVENT_DATA) if Scene_PokemonSurvivor.const_defined?(:JOKER_EVENT_DATA)
    rescue
    end

    def collect_display_strings(items, value, key = nil)
      case value
      when Hash
        value.each { |child_key, child_value| collect_display_strings(items, child_value, child_key) }
      when Array
        value.each { |child| collect_display_strings(items, child, key) }
      when String
        add_translator_text(items, value) if display_text_key?(key)
      end
    rescue
    end

    def collect_all_strings(items, value)
      case value
      when Hash
        value.each_value { |child| collect_all_strings(items, child) }
      when Array
        value.each { |child| collect_all_strings(items, child) }
      when String
        add_translator_text(items, value)
      end
    rescue
    end

    def display_text_key?(key)
      return false if key.nil?
      DISPLAY_TEXT_KEYS.include?(key) || [:tag, "tag", :hint, "hint"].include?(key)
    rescue
      false
    end

    def add_translator_text(items, text)
      return if !text || text.empty?
      items << text if !items.include?(text)
    end
  end
end

