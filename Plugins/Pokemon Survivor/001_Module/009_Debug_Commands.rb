#===============================================================================
# Pokemon Survivor - debug commands
#===============================================================================
module PokemonSurvivor
  module_function

  FULL_UNLOCK_CURRENCY_AMOUNT = 99_999 unless const_defined?(:FULL_UNLOCK_CURRENCY_AMOUNT)

  def full_unlock
    permission = full_unlock_permission
    if permission == :deny
      reset_unauthorized_full_unlock_save
      return false
    end
    return false unless permission == :allow
    return false unless $DEBUG
    progress = survivor_progress
    if const_defined?(:BASE_HERO_KEYS)
      progress[:unlocked] = BASE_HERO_KEYS.map { |key| species_key(key) }.uniq
      [:survived_15, :boss_finished, :evolution_finished, :level_finished,
       :rush_finished, :tower_finished].each do |badge|
        progress[badge] = progress_species_list(progress, badge) | progress[:unlocked]
      end
    end
    equipment_items.each { |item| unlock_equipment_item(item[:id]) }
    if const_defined?(:Titan) && Titan.const_defined?(:SEASONS)
      progress[:titan_online] = {} unless progress[:titan_online].is_a?(Hash)
      account = progress[:titan_online]
      account[:cosmetics] = {} unless account[:cosmetics].is_a?(Hash)
      Titan::SEASONS.each_value do |season|
        next unless season[:reward_pokemon] && season[:reward_cosmetic] == :prestige_crystal
        account[:cosmetics][species_key(season[:reward_pokemon])] = :prestige_crystal
      end
    end
    if const_defined?(:Challenge) && Challenge.const_defined?(:SEASONS)
      progress[:titan_online] = {} unless progress[:titan_online].is_a?(Hash)
      account = progress[:titan_online]
      account[:cosmetics] = {} unless account[:cosmetics].is_a?(Hash)
      Challenge::SEASONS.each_value do |pokemon|
        next unless pokemon
        account[:cosmetics][species_key(pokemon)] = :prestige_crystal
      end
    end
    amount = FULL_UNLOCK_CURRENCY_AMOUNT.to_i
    progress[:shop_currency] = [progress[:shop_currency].to_i, amount].max
    progress[:dark_shop_currency] = [progress[:dark_shop_currency].to_i, amount].max
    progress[:candy_currency] = [progress[:candy_currency].to_i, amount].max
    true
  rescue
    false
  end

  def full_unlock_online_wait
    result = nil
    worker = Thread.new do
      begin
        result = yield
      rescue StandardError
        result = nil
      end
    end
    while worker.alive?
      Graphics.update
      Input.update
    end
    worker.join
    result
  end

  def full_unlock_permission
    return :unavailable unless defined?(Titan::OnlineState) && defined?(Game) && Game.respond_to?(:save)
    store = Titan::OnlineState.new(survivor_progress,
      proc { |&job| full_unlock_online_wait(&job) }, proc { Game.save })
    return :unavailable unless store.authenticate
    account = survivor_progress[:titan_online]
    request_id = "unlock_#{leaderboard_run_key}"
    lines = store.request(action: "full_unlock_permission", access_token: account[:access_token], request_id: request_id)
    return :unavailable unless lines.is_a?(Array) && lines.length == 1
    result = lines.first
    return :unavailable unless result.length == 4 && result[0] == "FULL_UNLOCK" &&
      result[1] == account[:user_id] && result[2] == request_id
    return :allow if result[3] == "allow"
    return :deny if result[3] == "deny"
    :unavailable
  rescue StandardError
    :unavailable
  end

  def reset_unauthorized_full_unlock_save
    # Use vanilla new-game initialization, not just Survivor's progress hash.
    account = survivor_progress[:titan_online]
    identity = {}
    [:access_token, :refresh_token, :user_id].each { |key| identity[key] = account[key] } if account.is_a?(Hash)
    Game.start_new
    @fallback_survivor_progress = nil
    @normalized_survivor_progress = nil
    survivor_progress[:titan_online] = identity unless identity.empty?
    unless Game.save
      pbMessage(_INTL("The save could not be reset. The game will now close."))
      Kernel.exit
    end
    pbMessage(_INTL("Cheating isn't Kecleon friendly."))
    Kernel.exit
  rescue StandardError
    pbMessage(_INTL("The save could not be reset. The game will now close."))
    Kernel.exit
  end
end

def pbFullUnlock
  if PokemonSurvivor.full_unlock
    pbMessage(_INTL("Full unlock applied.")) rescue nil
    return true
  end
  pbMessage(_INTL("Full unlock unavailable. Server authorization and debug mode are required.")) rescue nil
  false
end

def pbSurvivorAccountID
  return false unless $DEBUG
  account = PokemonSurvivor.survivor_progress[:titan_online]
  id = account.is_a?(Hash) ? account[:user_id].to_s : ""
  unless id =~ /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i
    pbMessage(_INTL("Connect to the Titan menu first, then try again."))
    return false
  end
  pbMessage(_INTL("Supabase account ID: {1}", id))
  id
end
