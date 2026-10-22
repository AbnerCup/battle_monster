#===============================================================================
# Pokemon Survivor Version Guard
# Blocks online leaderboard submissions when the local game version is outdated.
#===============================================================================

module PokemonSurvivor
  LEADERBOARD_LOCAL_VERSION = "9.0"
  LEADERBOARD_VERSION_CONFIG_TABLE = "survivor_game_config"
  LEADERBOARD_VERSION_CONFIG_KEY = "leaderboard_min_version"

  module_function

  def leaderboard_local_version
    LEADERBOARD_LOCAL_VERSION.to_s.strip
  rescue
    ""
  end

  def leaderboard_version_value_from_output(output)
    text = sanitize_leaderboard_output(output).to_s.sub(/\A\uFEFF/, "").strip
    return "" if text.empty? || text.start_with?("ERROR")
    if text.include?("\t")
      parts = text.split(/\r?\n/).first.to_s.split("\t")
      return parts.last.to_s.strip
    end
    lines = text.split(/\r?\n/).reject { |line| line.to_s.strip.empty? }
    return "" if lines.empty?
    if lines.length > 1 && lines[0].downcase.include?("value")
      cols = csv_split_line(lines[1])
      return cols.last.to_s.strip
    end
    cols = csv_split_line(lines[0])
    cols.last.to_s.strip
  rescue
    ""
  end

  def fetch_leaderboard_required_version
    return "" if !leaderboard_read_configured?
    key = supabase_anon_key
    url = "#{supabase_url}/rest/v1/#{LEADERBOARD_VERSION_CONFIG_TABLE}?select=value&key=eq.#{url_query_escape(LEADERBOARD_VERSION_CONFIG_KEY)}&limit=1"
    if respond_to?(:supabase_curl_get_csv)
      output = supabase_curl_get_csv(url).to_s
      version = leaderboard_version_value_from_output(output)
      supabase_log_result(:version_check, "transport=curl\nrequired=#{version}\noutput=#{output.to_s[0, 500]}") rescue nil
      return version if version.match?(/\A\d+(?:\.\d+)*\z/)
    end
    return "" unless windows_platform?
    script = "try { " +
             "$h=@{apikey=#{powershell_escape(key)};Authorization=#{powershell_escape("Bearer #{key}")}}; " +
             "$r=Invoke-RestMethod -Uri #{powershell_escape(url)} -Headers $h -Method Get -TimeoutSec 8; " +
             "if (@($r).Count -gt 0) { $r[0].value } else { '' } " +
             "} catch { 'ERROR`t' + $_.Exception.Message }"
    output = run_powershell_for_leaderboard(script).to_s
    version = leaderboard_version_value_from_output(output)
    supabase_log_result(:version_check, "transport=powershell\nrequired=#{version}\noutput=#{output.to_s[0, 500]}") rescue nil
    version
  rescue => e
    supabase_log_result(:version_check, "ruby_error #{e.class}: #{e.message}") rescue nil
    ""
  end

  def compare_version_numbers(local, required)
    left = local.to_s.scan(/\d+/).map(&:to_i)
    right = required.to_s.scan(/\d+/).map(&:to_i)
    length = [left.length, right.length].max
    i = 0
    while i < length
      a = left[i] || 0
      b = right[i] || 0
      return -1 if a < b
      return 1 if a > b
      i += 1
    end
    0
  rescue
    local.to_s <=> required.to_s
  end

  def leaderboard_version_allowed?
    required = fetch_leaderboard_required_version
    return true if required.to_s.strip.empty?
    allowed = compare_version_numbers(leaderboard_local_version, required) >= 0
    supabase_log_result(:version_check, "local=#{leaderboard_local_version}\nrequired=#{required}\nallowed=#{allowed}") rescue nil
    allowed
  rescue
    false
  end

  def seasonal_run_version_status
    required = fetch_leaderboard_required_version.to_s.strip
    local = leaderboard_local_version
    return :unavailable unless required.match?(/\A\d+(?:\.\d+)*\z/) && local.match?(/\A\d+(?:\.\d+)*\z/)
    compare_version_numbers(local, required) >= 0 ? :allowed : :outdated
  rescue StandardError
    :unavailable
  end
end

class Scene_PokemonSurvivor
  def seasonal_run_version_allowed?
    status = breach_wait(_INTL("Checking game version...")) { PokemonSurvivor.seasonal_run_version_status }
    return true if status == :allowed
    if status == :outdated
      pbMessage(_INTL("Please update the game to start a seasonal run."))
    else
      pbMessage(_INTL("The game version could not be verified. Check your connection and try again."))
    end
    false
  end
end
