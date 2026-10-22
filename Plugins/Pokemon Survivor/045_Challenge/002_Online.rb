module PokemonSurvivor::Challenge
  class OnlineState
    attr_reader :season_id, :season, :last_error, :run, :result

    def initialize(root, wait, save)
      @root, @wait, @save = root, wait, save
      @account = root[:challenge_online] ||= { delivered_candies: 0, delivered_fragments: 0, owned: [] }
      @season_id, @data = 0, {}
      @auth = PokemonSurvivor::Titan::OnlineState.new(root, wait, save)
    end

    def snapshot
      @data
    end

    def persist
      return true if @save.call
      @last_error = 'save_failed'
      false
    end

    def request(payload, refreshed = false)
      return nil unless @auth.authenticate
      token = @root[:titan_online][:access_token]
      raw = @wait.call do
        PokemonSurvivor.supabase_curl_post_json("#{PokemonSurvivor.supabase_url}/functions/v1/challenge-season", payload.merge(access_token: token))
      end
      lines = raw.to_s.strip.split(/\r?\n/).map { |line| line.split("\t", -1) }
      unless lines.first == ['OK']
        @last_error = lines.first && lines.first[0] == 'ERROR' ? lines.first[1] : 'connection_unavailable'
        if @last_error == 'session_expired' && !refreshed
          PokemonSurvivor::Titan.auth_sessions.delete(token)
          @auth = PokemonSurvivor::Titan::OnlineState.new(@root, @wait, @save)
          return request(payload, true)
        end
        return nil
      end
      @last_error = nil
      lines.drop(1)
    rescue StandardError
      @last_error = 'connection_unavailable'
      nil
    end

    def accept(lines)
      s = lines.find { |line| line[0] == 'STATE' }
      return false unless s && s.length == 12
      @season_id = s[1].to_i
      @season = { id: @season_id, remaining: s[2].to_i, checked_at: System.uptime }
      @data = { purchases: {}, offers: [], owned: [], crystals: s[3].to_i, candies: s[4].to_i,
        fragments: s[5].to_i, points: s[6].to_i, best_ko: s[7].to_i, best_rank: s[8].to_i,
        claimed_rank: s[9].to_i, rank: s[10].to_i, rewards_open: s[11] == '1' }
      lines.each do |line|
        case line[0]
        when 'MENU' then @menu = line[1]
        when 'OWNED' then @data[:owned] << line[1]
        when 'OFFER'
          @data[:offers] << { id: line[1].to_sym, kind: line[2].to_sym, reward: line[3],
            cost: line[4].to_i, quantity: line[5].to_i, limit: line[6].to_i }
          @data[:purchases][line[1].to_sym] = line[7].to_i
        when 'RUN'
          @run = { id: line[1], target: decode(line[2]), ko: line[3].to_i, gain: line[4].to_i, loss: line[5].to_i }
          @account[:active_run] = @run.merge(season_id: @season_id)
        when 'RESULT'
          @result = { delta: line[1].to_i, expired: line[2] == '1' }
          @account.delete(:active_run)
        end
      end
      deliver
      true
    end

    def decode(text)
      text.gsub(/%([0-9a-f]{2})/i) { [$1.to_i(16)].pack('C') }.force_encoding('UTF-8')
    end

    def deliver
      [:candies, :fragments].each do |key|
        previous = @account["delivered_#{key}".to_sym].to_i
        amount = @data[key] - previous
        if amount > 0
          key == :candies ? PokemonSurvivor.add_candy_currency(amount) : PokemonSurvivor.add_shop_currency(amount)
        end
        @account["delivered_#{key}".to_sym] = [previous, @data[key]].max
      end
      PokemonSurvivor.convert_shop_currency_to_dark_if_unlocked
      @account[:owned] = @data[:owned].dup
      @data[:owned].each do |reward|
        # Unconfigured seasonal heroes stay owned without receiving invented gameplay.
        next if reward.start_with?('PRESTIGE_')
        if PokemonSurvivor::HERO_BASE.key?(reward.to_sym)
          PokemonSurvivor.unlock_hero(reward.to_sym)
        elsif reward.start_with?('EQUIPMENT_')
          PokemonSurvivor.unlock_equipment_item(reward.sub('EQUIPMENT_', '').downcase.to_sym)
        end
      end
    end

    def mutate(action, attributes = {})
      return false if @account[:pending] && !retry_pending
      payload = { action: action, season_id: @season_id,
        request_id: PokemonSurvivor.leaderboard_run_key }.merge(attributes)
      @account[:pending] = payload
      return false unless persist
      retry_pending
    end

    def retry_pending
      payload = @account[:pending]
      return true unless payload
      lines = request(payload)
      if lines && accept(lines)
        @account.delete(:pending)
        return persist
      end
      terminal = %w[invalid_request invalid_request_id invalid_target invalid_start invalid_run unknown_run
        season_unavailable already_owned purchase_limit not_enough_crystals menu_closed rewards_locked
        request_conflict submission_conflict active_run]
      if terminal.include?(@last_error)
        if payload[:action] == 'submit' && %w[season_unavailable unknown_run submission_conflict].include?(@last_error)
          @account.delete(:active_run)
        end
        @account.delete(:pending)
        persist
      end
      false
    end

    def connect
      return false unless retry_pending
      # A game closed during combat forfeits its saved challenge rather than avoiding a loss.
      if (active = @account[:active_run])
        @season_id = active[:season_id]
        return false unless settle(active, 0, 0, true)
      end
      @season_id = 0
      mutate('open')
    end

    def close
      mutate('close', menu: @menu) if @menu
    end

    def begin_run(hero, target)
      @run = nil
      @result = nil
      mutate('start', pokemon: hero.to_s, target: target,
        player_name: PokemonSurvivor.leaderboard_player_name) ? @run : nil
    end

    def settle(run, kills, seconds, abandoned)
      mutate('submit', run_id: run[:id], kills: kills.to_i, seconds: seconds.to_i,
        outcome: abandoned ? 'abandoned' : 'ended')
    end

    def leaderboard
      lines = request(action: 'leaderboard', season_id: @season_id)
      return nil unless lines && accept(lines) && persist
      lines.select { |l| l[0] == 'BOARD' }.map do |l|
        { id: l[1], name: decode(l[2]), points: l[3].to_i, ko: l[4].to_i, rank: l[5].to_i }
      end
    end

    def own_id
      @root[:titan_online][:user_id]
    end

    def buy(item, quantity = 1)
      return false unless quantity.is_a?(Integer) && quantity.between?(1, 100)
      if quantity > 1
        offer = @data[:offers].find { |entry| entry[:id] == item }
        return false unless offer && [:candies, :fragments].include?(offer[:kind])
        return false if @data[:purchases][item].to_i + quantity > offer[:limit]
        return false if @data[:crystals].to_i < offer[:cost] * quantity
        return mutate('buy', menu: @menu, item: "#{item}_batch", quantity: quantity)
      end
      mutate('buy', menu: @menu, item: item.to_s)
    end

    def claim_all
      mutate('claim', menu: @menu)
    end

    def repeat_purchase_claimed?(id)
      @data[:purchases][id].to_i > 0
    end
  end
end
