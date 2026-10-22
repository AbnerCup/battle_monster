#===============================================================================
# Pokemon Survivor - module bootstrap
#===============================================================================

if defined?(PokemonSystem)
  module PokemonSurvivorSystemDefaults
    def initialize(*args)
      super(*args)
      @screensize = 2 if !defined?(@screensize) || @screensize.nil?
      @bgmvolume = 50 if !defined?(@bgmvolume) || @bgmvolume.nil?
      @sevolume = 50 if !defined?(@sevolume) || @sevolume.nil?
    end
  end
  PokemonSystem.prepend(PokemonSurvivorSystemDefaults) if !PokemonSystem.ancestors.include?(PokemonSurvivorSystemDefaults)
end

# The main PokemonSurvivor module is split in 001_Module/*.rb.
# Essentials loads plugin Ruby files recursively in filename order.
