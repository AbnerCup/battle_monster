module PokemonSurvivor
  module Challenge
    LEVEL = 100
    PASSIVES = 4
    ROOKIE_KO = 500
    SEASONS = { 1 => :ENTEI, 2 => :RAIKOU, 3 => :SUICUNE }.freeze

    def self.rank_reward(rank)
      case rank
      when 1 then 75
      when 2 then 45
      when 3 then 35
      when 4..10 then 20
      when 11..25 then 12
      when 26..50 then 8
      when 51..100 then 5
      when 101..200 then 3
      when 201..500 then 2
      when 501..1000 then 1
      else 0
      end
    end

    def self.claimable(best, claimed)
      (best...claimed).inject(0) { |sum, rank| sum + rank_reward(rank) }
    end
  end
end

module SurvivorChallengePrestige
  def pokemon_prestige_crystal_owned?(pokemon)
    account = survivor_progress[:challenge_online]
    owned = account.is_a?(Hash) ? account[:owned] : nil
    (owned.is_a?(Array) && owned.include?("PRESTIGE_#{species_key(pokemon)}")) || super
  end
end
PokemonSurvivor.singleton_class.prepend(SurvivorChallengePrestige)
