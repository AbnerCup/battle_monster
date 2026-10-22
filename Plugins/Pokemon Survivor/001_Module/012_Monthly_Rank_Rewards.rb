# Monthly leaderboard rewards. Identity is shared with Titan, not inferred from a nickname.
module PokemonSurvivor
  module_function

  def rank_reward_access_token
    store = Titan::OnlineState.new(survivor_progress, proc { |&job| job.call }, proc { online_save_progress })
    return nil unless store.authenticate
    survivor_progress[:titan_online][:access_token]
  rescue StandardError
    nil
  end

  def rank_reward_eligible_row?(mode, sort, filter, row)
    return false unless [:classic, :rush, :tower, :endless, :breach].include?(mode)
    return false unless sort.to_s == "score" && filter.to_s.empty? && row.is_a?(Hash)
    return false unless row[:rank].to_i.between?(1, 100)
    player = normalized_trainer_name(leaderboard_player_name).downcase
    !player.empty? && normalized_trainer_name(row[:player]).downcase == player
  end

  def deliver_rank_reward(raw)
    fields = raw.to_s.strip.split("\t")
    return nil unless fields.length == 6 && fields[0] == "OK"
    return nil unless fields[1] =~ /\A\d+\z/ && fields[2] =~ /\A\d+\z/ && fields[3] =~ /\A\d{4}-\d{2}-\d{2}\z/
    return nil unless fields[4..5].all? { |value| value =~ /\A\d+\z/ }
    return nil unless fields[1].to_i.between?(1,100) && fields[2].to_i.between?(0,100)
    root = survivor_progress
    account = root[:titan_online] || {}
    return nil if account[:user_id].to_s.empty?
    totals = fields[4..5].map(&:to_i)
    old = (root[:rank_reward_delivered] || {})[account[:user_id]] || [0,0]
    gains = totals.each_with_index.map { |value,i| [value-old[i].to_i,0].max }
    keys = [:candy_currency,:shop_currency,:dark_shop_currency,:rank_reward_delivered]
    backup = Marshal.load(Marshal.dump(Hash[keys.map { |key| [key,root[key]] }]))
    add_candy_currency(gains[0])
    add_shop_currency(gains[1])
    convert_shop_currency_to_dark_if_unlocked
    root[:rank_reward_delivered] ||= {}
    root[:rank_reward_delivered][account[:user_id]] = totals.each_with_index.map { |value,i| [value,old[i].to_i].max }
    unless online_save_progress
      backup.each { |key,value| root[key] = value }
      return nil
    end
    { rank: fields[1].to_i, from: fields[2].to_i, candies: gains[0], fragments: gains[1] }
  end
end

class Scene_PokemonSurvivor
  def leaderboard_rank_reward_selected?
    row = (@leaderboard_entries || [])[@leaderboard_index.to_i]
    PokemonSurvivor.rank_reward_eligible_row?(@leaderboard_mode,@leaderboard_sort,@leaderboard_pokemon_filter,row)
  end

  def claim_leaderboard_rank_reward
    return unless leaderboard_rank_reward_selected?
    token = PokemonSurvivor.rank_reward_access_token
    unless token
      pbMessage(_INTL("Unable to verify your online identity. Please try again."))
      return
    end
    row = @leaderboard_entries[@leaderboard_index.to_i]
    season = PokemonSurvivor.breach_current_season
    payload = { mode: @leaderboard_mode.to_s, season_id: @leaderboard_mode == :breach && season ? season[:id] : 0,
      player_name: row[:player], pokemon: row[:pokemon], access_token: token }
    raw = breach_wait(_INTL("Checking monthly rank rewards...")) do
      PokemonSurvivor.supabase_curl_post_json("#{PokemonSurvivor.supabase_url}/functions/v1/rank-rewards",payload)
    end
    if raw.to_s.include?("owned_run_required")
      pbMessage(_INTL("This score is not linked to your online identity. Submit a new run to unlock rank rewards."))
      return
    end
    reward = PokemonSurvivor.deliver_rank_reward(raw)
    unless reward
      pbMessage(_INTL("Reward unavailable. Check your connection and try again. Validated rewards are kept for your next claim."))
      return
    end
    if reward[:candies] == 0 && reward[:fragments] == 0
      pbMessage(_INTL("You have already claimed these ranks this month."))
    else
      show_rank_reward_popup(reward)
    end
  ensure
    draw_leaderboard(false)
    Input.update
    @last_time = System.uptime
    @accumulator = 0.0
  end

  def show_rank_reward_popup(reward)
    opened = System.uptime
    released = false
    pbSEPlay("Survivor/GUI sel decision") rescue nil
    loop do
      Graphics.update
      Input.update
      draw_leaderboard(false)
      bitmap = @sprites["overlay"].bitmap
      bitmap.clear
      pbSetSystemFont(bitmap)
      width = [Graphics.width - 40, 430].min
      x, y = (Graphics.width-width)/2, (Graphics.height-156)/2
      draw_panel(bitmap,x,y,width,156,Color.new(112,208,255),Color.new(12,22,38,235))
      draw_leaderboard_cell(bitmap,_INTL("Monthly rank reward: {1}",reward[:rank]),x+12,y+12,width-24,32,Color.white,Color.new(32,32,40),2)
      draw_leaderboard_cell(bitmap,_INTL("Candies: +{1}",reward[:candies]),x+12,y+52,width-24,32,Color.white,Color.new(32,32,40),2)
      draw_leaderboard_cell(bitmap,_INTL("Fragments: +{1}",reward[:fragments]),x+12,y+88,width-24,32,Color.white,Color.new(32,32,40),2)
      released ||= !Input.press?(Input::USE)
      break if System.uptime-opened >= 4.0 || (released && (survivor_confirm_triggered? || select_back_triggered?))
    end
  end
end
