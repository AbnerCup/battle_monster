#===============================================================================
# Pokemon Survivor - Battle Pass - finish run hook
#===============================================================================
module PokemonSurvivorBattlePassSceneHooks
  def finish_run(*args, &block)
    already_finished = @run_finished
    result = super(*args, &block)
    PokemonSurvivor.battle_pass_record_run(self) if !already_finished && @run_finished
    result
  rescue
    result
  end
end
