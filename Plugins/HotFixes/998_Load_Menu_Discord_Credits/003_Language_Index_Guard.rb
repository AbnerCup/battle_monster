#===============================================================================
# Keep old/malformed language preferences from breaking StartGame or load menus.
#===============================================================================
module SurvivorLanguageIndexGuard
  def language
    value = super
    languages = Settings::LANGUAGES
    return value if value.is_a?(Integer) && value >= 0 && value < languages.length
    fallback = languages.index { |entry| entry.is_a?(Array) && entry[1] == "english" } || 0
    self.language = fallback
    fallback
  end
end

PokemonSystem.prepend(SurvivorLanguageIndexGuard) unless PokemonSystem.ancestors.include?(SurvivorLanguageIndexGuard)
