# Server-backed Titan adapter. Rendering only reads the cached snapshot.
module PokemonSurvivor
  module Titan
    def self.auth_sessions
      @auth_sessions ||= {}
    end

    class OnlineState
      attr_reader :season_id, :season, :last_error

      def initialize(root, wait, save)
        @root, @wait, @save = root, wait, save
        @root[:titan_online] ||= { delivered: {}, cosmetics: {} }
        @account = @root[:titan_online]
        @account[:delivered] ||= {}
        @account[:cosmetics] ||= {}
        @season_id = 0
        @valid_until = Titan.auth_sessions[@account[:access_token]].to_f
        @data = { training: {}, purchases: {}, claimed: [], cosmetics: {} }
      end

      def request(payload)
        raw = @wait.call do
          PokemonSurvivor.supabase_curl_post_json("#{PokemonSurvivor.supabase_url}/functions/v1/titan-season", payload)
        end
        decode_response(raw)
      rescue StandardError
        @last_error = "connection_unavailable"
        nil
      end

      def decode_response(raw)
        lines = raw.to_s.strip.split(/\r?\n/).map { |line| line.split("\t", -1) }
        unless lines.first == ["OK"]
          @last_error = lines.first && lines.first[0] == "ERROR" ? lines.first[1] : "connection_unavailable"
          @retry_after = PokemonSurvivor.online_retry_after(raw)
          return nil
        end
        @last_error = nil
        lines.drop(1)
      rescue StandardError
        @last_error = "connection_unavailable"
        nil
      end

      def persist
        return true if @save.call
        @last_error = "save_failed"
        false
      end

      def authenticate
        if PokemonSurvivor.online_titan_busy?(@account)
          @last_error = "retry_pending"
          return false
        end
        if @valid_until > System.uptime && @auth_unsaved
          @auth_unsaved = !persist
          return !@auth_unsaved
        end
        return true if @valid_until > System.uptime
        refresh = @account[:refresh_token]
        # An existing account must never silently become a fresh anonymous user.
        if @account[:user_id] && refresh.to_s.empty?
          @last_error = "session_expired"
          return false
        end
        payload = refresh.to_s.empty? ? { action: "register" } : { action: "refresh", refresh_token: refresh }
        lines = request(payload)
        apply_auth_response(lines)
      end

      def apply_auth_response(lines)
        auth = lines && lines.find { |line| line[0] == "AUTH" }
        return false unless auth && auth.length == 5
        if @account[:user_id] && @account[:user_id] != auth[3]
          @last_error = "account_mismatch"
          return false
        end
        @account[:access_token], @account[:refresh_token], @account[:user_id] = auth[1, 3]
        @valid_until = System.uptime + [auth[4].to_i - 120, 1].max
        @auth_unsaved = !persist
        Titan.auth_sessions.clear
        Titan.auth_sessions[@account[:access_token]] = @valid_until unless @auth_unsaved
        !@auth_unsaved
      end

      def send_action(payload)
        return nil unless authenticate
        result = request(payload.merge(access_token: @account[:access_token]))
        if !result && @last_error == "session_expired"
          @valid_until = 0
          Titan.auth_sessions.clear
          result = request(payload.merge(access_token: @account[:access_token])) if authenticate
        end
        result
      end

      def connect
        return false unless authenticate && retry_pending
        refresh(0) && persist
      end

      def refresh(id = @season_id)
        lines = send_action(action: "status", season_id: id)
        lines && accept(lines)
      end

      def accept(lines)
        state = lines.find { |line| line[0] == "STATE" }
        unless state && state.length == 12 && Titan.season_configured?(state[1].to_i)
          @last_error = "unsupported_season"
          return false
        end
        @season_id = state[1].to_i
        @season = { id: @season_id, remaining: state[2].to_i, checked_at: System.uptime }
        @data = { training: {}, purchases: {}, claimed: [], cosmetics: {} }
        [:total_hp, :hp, :ores, :crystals, :damage, :candies, :fragments].each_with_index { |key, i| @data[key] = state[i + 3].to_i }
        lines.each do |line|
          case line[0]
          when "TRAINING" then @data[:training][line[1].to_sym] = line[2].to_i
          when "PURCHASE" then @data[:purchases][line[1].to_sym] = line[2].to_i
          when "CLAIMED" then @data[:claimed] << line[1].to_i
          when "DELIVERY" then deliver(line)
          end
        end
        true
      end

      def deliver(line)
        return unless line.length == 9
        key = line[1].to_i
        old = @account[:delivered][key] ||= { candies: 0, fragments: 0 }
        candies, fragments = line[2].to_i, line[3].to_i
        PokemonSurvivor.add_candy_currency(candies - old[:candies]) if candies > old[:candies]
        if fragments > old[:fragments]
          PokemonSurvivor.add_shop_currency(fragments - old[:fragments])
          PokemonSurvivor.convert_shop_currency_to_dark_if_unlocked
        end
        old[:candies] = [old[:candies], candies].max
        old[:fragments] = [old[:fragments], fragments].max
        PokemonSurvivor.unlock_hero(line[4].to_sym) if line[6].to_i > 0
        PokemonSurvivor.unlock_equipment_item(line[5].to_sym) if line[7].to_i > 0 && !line[5].to_s.empty?
        @account[:cosmetics][line[4].to_sym] = :prestige_crystal if line[8].to_i > 0
      end

      def discard_abandoned_submission
        payload = @account[:pending]
        return unless payload && payload[:action].to_s == "submit" && payload[:outcome].to_s == "abandoned"
        @account.delete(:pending)
        @account.delete(:retry_at)
        @account.delete(:retry_attempts)
        persist
      end

      def retry_pending
        discard_abandoned_submission
        payload = @account[:pending]
        return true unless payload
        if @account[:retry_at].to_i > Time.now.to_i
          @last_error = "retry_pending"
          return false
        end
        lines = send_action(payload)
        complete_pending(lines)
      end

      def complete_pending(lines)
        unless lines
          # Transport/server failures stay queued; rejected operations never grant locally.
          if ["invalid_request", "invalid_request_id", "request_conflict", "season_unavailable", "invalid_start",
              "boss_defeated", "unknown_run", "invalid_run", "submission_conflict", "upgrade_complete",
              "upgrade_locked", "not_enough_ores", "unknown_item", "purchase_limit", "reward_locked",
              "not_enough_crystals", "nothing_to_claim"].include?(@last_error)
            @account.delete(:pending)
            @account.delete(:retry_at)
            @account.delete(:retry_attempts)
            persist
          else
            @account[:retry_attempts] = @account[:retry_attempts].to_i + 1
            delay = [15 * (2 ** [@account[:retry_attempts] - 1, 5].min), @retry_after.to_i].max
            @account[:retry_at] = Time.now.to_i + delay + 1 + rand(5)
            persist
          end
          return false
        end
        return false unless accept(lines)
        record_confirmed_repeat_purchase(@account[:pending])
        @last_lines = lines
        @account.delete(:pending)
        @account.delete(:retry_at)
        @account.delete(:retry_attempts)
        persist
      end

      def background_job
        discard_abandoned_submission
        return nil unless @account[:pending] && @account[:retry_at].to_i <= Time.now.to_i
        original = @account[:pending].dup
        if @valid_until > System.uptime
          [:pending, original.merge(access_token: @account[:access_token]), original]
        elsif !@account[:refresh_token].to_s.empty?
          [:auth, { action: "refresh", refresh_token: @account[:refresh_token] }, original]
        end
      end

      def complete_background(job, output)
        return unless @account[:pending] == job[2]
        lines = decode_response(output)
        if job[0] == :auth
          complete_pending(nil) unless apply_auth_response(lines)
        else
          if @last_error == "session_expired"
            @valid_until = 0
            Titan.auth_sessions.clear
          end
          complete_pending(lines)
        end
      end

      def mutate(action, extra = {})
        return nil unless retry_pending
        payload = { action: action, season_id: @season_id,
          request_id: "titan-#{Time.now.to_i}-#{rand(1 << 30)}-#{rand(1 << 30)}" }.merge(extra)
        @account[:pending] = payload
        return nil unless persist && retry_pending
        @last_lines
      end

      def snapshot
        @data
      end

      def begin_run(player, pokemon)
        lines = mutate("start", player_name: player.to_s, pokemon: pokemon.to_s)
        line = lines && lines.find { |entry| entry[0] == "RUN" }
        return nil unless line
        { key: line[1], hp: line[2].to_i, total_hp: line[3].to_i,
          player: player, pokemon: pokemon, season_id: @season_id }
      end

      def settle(run, damage, seconds, outcome)
        # Abandonment is local only; the server expires the unused run session.
        return { damage: 0, ores: 0 } if outcome.to_s == "abandoned"
        lines = mutate("submit", season_id: run[:season_id], run_id: run[:key],
          damage: damage.to_i, seconds: seconds.to_i, outcome: outcome.to_s)
        line = lines && lines.find { |entry| entry[0] == "RECEIPT" }
        line ? { damage: line[2].to_i, ores: line[3].to_i } : nil
      end

      def leaderboard
        lines = send_action(action: "leaderboard", season_id: @season_id)
        return nil unless lines && accept(lines)
        lines.select { |line| line[0] == "BOARD" }.map do |line|
          name = line[2].b.gsub(/%([0-9a-f]{2})/i) { [$1.to_i(16)].pack("C") }.force_encoding("UTF-8")
          { rank: line[1].to_i, player: name, damage: line[3].to_i }
        end
      end

      def rank(id)
        @data[:training][id].to_i
      end

      def buy_training(id)
        !!mutate("training", item: id.to_s)
      end

      def milestone_ready?(index)
        entry = MILESTONES[index] if index.is_a?(Integer) && index >= 0
        entry && !@data[:claimed].include?(index) &&
          (@data[:total_hp] - @data[:hp]) * 100 >= @data[:total_hp] * entry[:percent]
      end

      def claim(index)
        milestone_ready?(index) && !!mutate("claim", index: index)
      end

      def claim_all
        !!mutate("claim_all")
      end

      def shop_available?(id)
        if id == :ore_candies
          return Titan.training_complete?(@data[:training]) && @data[:ores].to_i >= ORE_CANDIES[:cost]
        end
        item = Titan.season_shop(@season_id)[id]
        item && (item[:repeatable] || @data[:purchases][id].to_i < item[:limit]) &&
          @data[item[:currency] || :crystals].to_i >= item[:cost] &&
          Titan.shop_requirements_met?(item, @data)
      end

      # Cosmetic history only: purchases and currency still require server approval.
      def record_confirmed_repeat_purchase(payload)
        return unless payload && payload[:action].to_s == "buy"
        return unless ["ore_candies", "ore_candies_batch"].include?(payload[:item].to_s)
        @account[:repeat_purchase_icons] ||= {}
        @account[:repeat_purchase_icons][payload[:season_id].to_i] = true
      end

      def repeat_purchase_claimed?(id)
        return true if @data[:purchases][id].to_i > 0
        return false unless id == :ore_candies
        return true if (@account[:repeat_purchase_icons] || {})[@season_id]
        # Earlier Ore exchanges had no purchase counter. Titan's other Candy
        # source is the Crystal exchange, whose count and unit gain are known.
        crystal_candies = @data[:purchases][:candies].to_i * SHOP[:candies][:quantity].to_i
        @data[:candies].to_i > crystal_candies
      end

      def buy(id, quantity = 1)
        return false unless quantity.is_a?(Integer) && quantity.between?(1, 999999)
        if id == :ore_candies && quantity > 1
          return false unless shop_available?(id) && @data[:ores].to_i >= ORE_CANDIES[:cost] * quantity
          return !!mutate("buy", item: "ore_candies_batch", quantity: quantity)
        end
        if [:candies, :fragments].include?(id) && quantity > 1
          item = Titan.season_shop(@season_id)[id]
          return false unless item && shop_available?(id)
          return false if @data[:purchases][id].to_i + quantity > item[:limit]
          return false if @data[:crystals].to_i < item[:cost] * quantity
          return !!mutate("buy", item: "#{id}_batch", quantity: quantity)
        end
        return false if quantity != 1
        shop_available?(id) && !!mutate("buy", item: id.to_s)
      end
    end
  end
end
