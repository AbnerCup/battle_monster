#===============================================================================
# Pokemon Survivor - Auto Hook for TikTok Live Tournament Mode
# Redirects Title Screen and Main Entry Point to Scene_TikTokTournament
#===============================================================================

def pbStartTikTokTournament
  scene = Scene_TikTokTournament.new
  pbFadeOutIn do
    scene.pbStartScene
    scene.pbMain
    scene.pbEndScene
  end
end

# 1. Main Entry Point
def pbPokemonSurvivor
  pbStartTikTokTournament
end

# 2. Essentials 20 & 21 EventHandlers Hooks
if defined?(EventHandlers)
  EventHandlers.add(:on_start_title, :start_tiktok_tournament, proc {
    pbStartTikTokTournament
  }) rescue nil

  EventHandlers.add(:on_game_start, :start_tiktok_tournament, proc {
    pbStartTikTokTournament
  }) rescue nil
end

# 3. Hook Title Screen (Scene_Intro) so pressing ENTER or auto-timer opens tournament
if defined?(Scene_Intro)
  class Scene_Intro
    alias closeTitle_original closeTitle rescue nil

    def closeTitle
      pbSEPlay(@cry, 100, 100) rescue nil if @cry
      pbBGMStop(1.0) rescue nil
      disposeTitle rescue nil
      pbStartTikTokTournament
    end
  end
end
