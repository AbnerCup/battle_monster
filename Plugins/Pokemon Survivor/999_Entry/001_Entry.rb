#===============================================================================
# Pokemon Survivor - Entry point
#===============================================================================

def pbPokemonSurvivor
  if defined?(pbStartTikTokTournament)
    pbStartTikTokTournament
  else
    scene = Scene_PokemonSurvivor.new
    pbFadeOutIn do
      scene.pbStartScene
      scene.pbMain
      scene.pbEndScene
    end
  end
end

def pbSurvivorRenameTrainer
  PokemonSurvivor.prompt_trainer_rename
end
