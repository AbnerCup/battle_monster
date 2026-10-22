#===============================================================================
# Pokemon Survivor Achievements - graphics update hook
#===============================================================================
module Graphics
  class << self
    alias psv_achievements_graphics_update update unless method_defined?(:psv_achievements_graphics_update)
    def update(*args)
      psv_achievements_graphics_update(*args)
      PokemonSurvivorAchievementPopup.update if defined?(PokemonSurvivorAchievementPopup)
    end
  end
end
