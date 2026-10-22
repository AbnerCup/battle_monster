module PokemonSurvivor
  module_function

  def breach_csv(path)
    return nil unless leaderboard_read_configured?
    raw = sanitize_leaderboard_output(supabase_curl_get_csv("#{supabase_url}/rest/v1/#{path}").to_s)
    lines = raw.split(/\r?\n/).reject { |line| line.strip.empty? }
    return nil if lines.empty? || raw.start_with?("ERROR", "{", "[")
    headers = csv_split_line(lines.shift).map { |name| name.to_s.sub(/^\uFEFF/, "") }
    lines.map { |line| Hash[headers.zip(csv_split_line(line))] }
  end

  def breach_refresh_season
    @breach_online_season = nil
    rows = breach_csv("breach_status?select=season_id,end_epoch,server_epoch,ruleset&limit=1")
    return nil if !rows || rows.empty?
    row = rows.first
    return nil unless row["season_id"] && row["server_epoch"]
    id = row["season_id"].to_i
    return nil if id <= 0 || row["ruleset"].to_i != BREACH_RULESET
    remaining = row["end_epoch"].to_f - row["server_epoch"].to_f
    return nil if remaining <= 0
    @breach_online_season = { id: id, remaining: remaining, checked_at: System.uptime }
  end

  def breach_current_season
    season = @breach_online_season
    season if season && breach_seconds_left(season) > 0
  end

  def breach_seconds_left(season)
    return 0 unless season
    [season[:remaining].to_f - (System.uptime - season[:checked_at].to_f), 0].max.to_i
  end

  def breach_fetch_quests(season)
    rows = breach_csv("breach_quests?season_id=eq.#{season[:id].to_i}&ruleset=eq.#{BREACH_RULESET}&select=id,name,metric,target,candies,fragments&order=position.asc")
    return nil unless rows
    allowed = [:rooms, :runs, :kills, :extractions, :fusions, :levels, :pokemon, :threat, :unfair_rooms]
    quests = rows.map do |row|
      metric = row["metric"].to_s.to_sym
      next unless allowed.include?(metric) && row["target"].to_i > 0
      { id: row["id"].to_s, name: row["name"].to_s, metric: metric, target: row["target"].to_i,
        candies: [row["candies"].to_i, 0].max, fragments: [row["fragments"].to_i, 0].max }
    end.compact
    return nil unless quests.length == 120 && quests.map { |q| q[:id] }.uniq.length == 120
    return nil unless quests.all? { |q| (q[:candies] > 0) != (q[:fragments] > 0) }
    # Older deployed seasons retain their IDs and targets, but receive the new reward floor.
    quests.each_with_index do |quest, index|
      amount = 15 + (index / 14) * 5
      quest[:candies] = [quest[:candies], amount * 12].max if quest[:candies] > 0
      quest[:fragments] = [quest[:fragments], amount * 40].max if quest[:fragments] > 0
    end
    breach_progress(season[:id])[:notification_quests] = quests
    quests
  end

  def breach_online_action(payload)
    if payload[:action].to_s == "start"
      token = rank_reward_access_token
      return "ERROR\tsession_expired" if token.to_s.empty?
      payload = payload.merge(access_token: token)
    end
    # Endpoint returns simple text; no optional JSON/URI Ruby library is required.
    response = supabase_curl_post_json("#{supabase_url}/functions/v1/breach", payload)
    response.to_s.strip
  end

  def breach_leaderboard_entries(season, limit, sort, pokemon_filter)
    return [] unless season
    order = sort.to_s == "level" ? "level.desc,score.desc" : "score.desc,level.desc"
    filter = ""
    filter += "&pokemon=eq.#{url_query_escape(pokemon_filter)}" if pokemon_filter && !pokemon_filter.to_s.empty?
    filter += "&player_name=eq.#{url_query_escape(leaderboard_player_name)}" if sort.to_s == "player"
    rows = breach_csv("breach_runs?season_id=eq.#{season[:id]}&ruleset=eq.#{BREACH_RULESET}&select=player_name,pokemon,level,score&order=#{order},created_at.asc,id.asc&limit=1000#{filter}")
    return [] unless rows
    entries = rows.map do |row|
      name = leaderboard_pokemon_display_name(row["pokemon"])
      { player: row["player_name"], pokemon: row["pokemon"], pokemon_name: name,
        level: row["level"].to_i, score: row["score"].to_i, submissions: 1 }
    end
    compact_best_leaderboard_entries(entries, limit, sort)
  end
end

module SurvivorBreachOnline
  def fetch_leaderboard_entries(mode = :classic, limit = PokemonSurvivor::LEADERBOARD_LIMIT, sort = :score, pokemon_filter = nil)
    return super unless mode.to_sym == :breach
    breach_leaderboard_entries(breach_current_season, limit, sort, pokemon_filter)
  end
end
PokemonSurvivor.singleton_class.prepend(SurvivorBreachOnline) unless PokemonSurvivor.singleton_class.ancestors.include?(SurvivorBreachOnline)
