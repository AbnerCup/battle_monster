#===============================================================================
# Pokemon Survivor - Supabase leaderboard and trainer names
#===============================================================================

module PokemonSurvivor
  module_function

  def survivor_read_text_file(path)
    return "" if path.to_s.empty? || !FileTest.exist?(path)
    File.open(path, "rb") { |file| file.read.to_s }.to_s.strip
  rescue
    ""
  end

  def supabase_url
    survivor_read_text_file(SUPABASE_URL_FILE)
  rescue
    ""
  end

  def supabase_anon_key
    survivor_read_text_file(SUPABASE_KEY_FILE)
  rescue
    ""
  end

  def supabase_submit_url
    survivor_read_text_file(SUPABASE_SUBMIT_URL_FILE)
  rescue
    ""
  end

  def leaderboard_read_configured?
    return false if !SUPABASE_ENABLED
    return false if supabase_url.empty?
    return false if supabase_anon_key.empty?
    true
  rescue
    false
  end

  def supabase_submit_configured?
    return false if !SUPABASE_ENABLED
    return false if supabase_submit_url.empty?
    true
  rescue
    false
  end

  def leaderboard_player_name
    name = ($player.name rescue nil)
    name = ($Trainer.name rescue nil) if name.to_s.strip.empty? && defined?($Trainer)
    name = "Player" if name.to_s.strip.empty?
    name.to_s[0, 80]
  rescue
    "Player"
  end

  def leaderboard_run_player_name(hero_name = nil, level = nil)
    leaderboard_player_name
  rescue
    "Player"
  end

  def supabase_pokemon_name(hero_name)
    species_key(hero_name).to_s
  rescue
    hero_name.to_s
  end

  def normalized_trainer_name(name)
    clean = name.to_s.strip.gsub(/[^A-Za-z0-9]/, "")
    clean[0, 7].to_s
  rescue
    ""
  end

  def apply_trainer_name(name)
    clean = normalized_trainer_name(name)
    return false if clean.empty?
    if defined?($player) && $player
      $player.name = clean
    elsif defined?($Trainer) && $Trainer
      $Trainer.name = clean
    else
      return false
    end
    true
  rescue
    false
  end

  def trainer_name_banned_words
    return NAME_BANLIST if const_defined?(:NAME_BANLIST)
    []
  rescue
    []
  end

  def trainer_name_error(name)
    clean = normalized_trainer_name(name)
    return _INTL("Please enter a valid name.") if clean.empty?
    return _INTL("Name must be 7 letters or less.") if name.to_s.strip.length > 7
    lower = clean.downcase
    trainer_name_banned_words.each do |word|
      banned = word.to_s.downcase.gsub(/[^a-z0-9]/, "")
      next if banned.empty?
      blocked = banned.length <= 3 ? (lower == banned) : (lower.include?(banned))
      return _INTL("This name cannot be used.") if blocked
    end
    nil
  rescue
    nil
  end

  def trainer_name_status_file
    save_path = ""
    save_path = SaveData::FILE_PATH.to_s if defined?(SaveData) && SaveData.const_defined?(:FILE_PATH)
    save_dir = save_path.empty? ? "" : File.dirname(save_path)
    return File.join(save_dir, "SurvivorTrainerNameStatus.txt") if !save_dir.to_s.empty? && FileTest.directory?(save_dir)
    TRAINER_NAME_STATUS_FILE
  rescue
    TRAINER_NAME_STATUS_FILE
  end

  def trainer_name_status_files
    files = [trainer_name_status_file, TRAINER_NAME_STATUS_FILE].compact.map(&:to_s).reject(&:empty?).uniq
    files
  rescue
    [TRAINER_NAME_STATUS_FILE]
  end

  def normalize_trainer_name_status(raw)
    text = raw.to_s.strip.sub(/\A\uFEFF/, "")
    return "" if text.empty?
    low = text.downcase
    return "temporary" if low.include?("temporary") || low.include?("temp")
    return "verified" if low.include?("verified") || low.include?("valid") || low.include?("online")
    current = normalized_trainer_name(leaderboard_player_name).downcase
    legacy = normalized_trainer_name(text).downcase
    return "verified" if !current.empty? && legacy == current
    low
  rescue
    ""
  end

  def read_trainer_name_status
    trainer_name_status_files.each do |path|
      raw = survivor_read_text_file(path)
      status = normalize_trainer_name_status(raw)
      next if status.empty?
      if path != trainer_name_status_file && FileTest.exist?(trainer_name_status_file) == false
        write_trainer_name_status(status) rescue nil
      end
      return status
    end
    ""
  rescue
    ""
  end

  def write_trainer_name_status(value)
    path = trainer_name_status_file
    dir = File.dirname(path) rescue ""
    Dir.mkdir(dir) if !dir.to_s.empty? && !FileTest.directory?(dir) rescue nil
    File.open(path, "wb") { |file| file.write(value.to_s) }
    true
  rescue
    false
  end

  def mark_trainer_name_temporary(flag = true)
    write_trainer_name_status(flag ? "temporary" : "verified")
  rescue
    false
  end
  def confirm_trainer_name_save_loop
    loop do
      result = nil
      if defined?(pbSaveScreen)
        result = pbSaveScreen
      elsif defined?(PokemonSaveScreen)
        result = PokemonSaveScreen.new.pbSaveScreen
      else
        pbMessage(_INTL("Save is not available right now.")) rescue nil
        return false
      end
      return true if result != false
      retry_save = pbConfirmMessage(_INTL("Your trainer name must be saved before continuing. Save now?")) rescue true
      return false if !retry_save
    end
  rescue
    false
  end

  def save_after_trainer_name_validation
    confirm_trainer_name_save_loop
  rescue
    false
  end

  def trainer_name_online_verified?
    read_trainer_name_status == "verified"
  rescue
    false
  end

  def local_trainer_name_temporary?
    read_trainer_name_status == "temporary"
  rescue
    false
  end

  def windows_platform?
    platform = RUBY_PLATFORM.to_s
    return true if platform =~ /mswin|mingw|cygwin|bccwin/i
    return true if defined?(System) && System.respond_to?(:platform) && System.platform[/Windows/i]
    false
  rescue
    false
  end

  def wine_platform?
    return true if ENV["WINEPREFIX"].to_s.length > 0 rescue false
    return true if ENV["WINELOADERNOEXEC"].to_s.length > 0 rescue false
    false
  rescue
    false
  end

  def android_platform?
    platform = RUBY_PLATFORM.to_s.downcase
    platform.include?("android") || platform.include?("linux-android")
  rescue
    false
  end

  def steam_deck_platform?
    platform = RUBY_PLATFORM.to_s.downcase
    return false if !platform.include?("linux") && !wine_platform?
    env = ["SteamDeck", "SteamAppId", "SteamGameId", "XDG_CURRENT_DESKTOP", "DESKTOP_SESSION"].map { |key| ENV[key].to_s rescue "" }.join(" ").downcase
    env.include?("steam") || env.include?("gamescope") || env.include?("deck")
  rescue
    false
  end

  def sanitize_leaderboard_output(output)
    text = output.to_s.dup
    if text.respond_to?(:force_encoding)
      text.force_encoding("UTF-8")
      if text.respond_to?(:valid_encoding?) && !text.valid_encoding?
        text = text.encode("UTF-8", "Windows-1252", invalid: :replace, undef: :replace, replace: "") rescue text
        text = text.encode("UTF-8", invalid: :replace, undef: :replace, replace: "") rescue text
      end
    end
    text.to_s
  rescue
    output.to_s rescue ""
  end

  def supabase_log_result(action, details = "")
    stamp = Time.now.strftime("%Y-%m-%d %H:%M:%S %z") rescue Time.now.to_s
    text = "#{stamp}\naction=#{action}\n#{details}\n"
    File.open(SUPABASE_LAST_RESULT_FILE, "wb") { |file| file.write(text) }
    true
  rescue
    false
  end

  def shell_quote(value)
    %Q{"#{value.to_s.gsub('"', '\\"')}"}
  rescue
    %Q{""}
  end

  def vbs_escape(value)
    value.to_s.gsub('"', '""')
  rescue
    ""
  end

  def windows_hidden_command(command)
    temp = ENV["TEMP"].to_s
    temp = "Data" if temp.empty?
    vbs_file = File.join(temp, "SurvivorHiddenCommand_#{Time.now.to_i}_#{rand(999999)}.vbs")
    File.open(vbs_file, "wb") do |file|
      file.write("Set sh = CreateObject(\"WScript.Shell\")\r\n")
      file.write("sh.Run \"#{vbs_escape(command)}\", 0, True\r\n")
    end
    ok = system("wscript.exe //B //Nologo #{shell_quote(vbs_file)}")
    File.delete(vbs_file) if FileTest.exist?(vbs_file) rescue nil
    ok
  rescue
    system(command) rescue false
  ensure
    File.delete(vbs_file) if vbs_file && FileTest.exist?(vbs_file) rescue nil
  end

  def windows_hidden_batch(command, output_file = nil)
    temp = ENV["TEMP"].to_s
    temp = "Data" if temp.empty?
    batch_file = File.join(temp, "SurvivorHiddenCommand_#{Time.now.to_i}_#{rand(999999)}.cmd")
    lines = ["@echo off"]
    lines << "chcp 65001 >NUL"
    if output_file && !output_file.to_s.empty?
      lines << "#{command} > #{shell_quote(output_file)} 2>&1"
    else
      lines << command.to_s
    end
    File.open(batch_file, "wb") { |file| file.write(lines.join("\r\n") + "\r\n") }
    ok = windows_hidden_command("cmd.exe /C #{shell_quote(batch_file)}")
    File.delete(batch_file) if FileTest.exist?(batch_file) rescue nil
    ok
  rescue
    system(command) rescue false
  ensure
    File.delete(batch_file) if batch_file && FileTest.exist?(batch_file) rescue nil
  end

  def windows_hidden_capture(command)
    temp = ENV["TEMP"].to_s
    temp = "Data" if temp.empty?
    output_file = File.join(temp, "SurvivorHiddenOutput_#{Time.now.to_i}_#{rand(999999)}.txt")
    windows_hidden_batch(command, output_file)
    output = ""
    File.open(output_file, "rb") { |file| output = file.read.to_s } if FileTest.exist?(output_file)
    File.delete(output_file) if FileTest.exist?(output_file) rescue nil
    output
  rescue
    ""
  ensure
    File.delete(output_file) if output_file && FileTest.exist?(output_file) rescue nil
  end

  def powershell_escape(value)
    "'#{value.to_s.gsub("'", "''")}'"
  rescue
    "''"
  end

  def url_query_escape(value)
    value.to_s.bytes.map do |byte|
      char = byte.chr
      char =~ /[A-Za-z0-9_.~-]/ ? char : "%%%02X" % byte
    end.join
  rescue
    value.to_s
  end
  alias url_encode url_query_escape unless method_defined?(:url_encode)

  def json_escape(value)
    value.to_s.gsub('\\', '\\\\').gsub('"', '\\"').gsub("\r", "\\r").gsub("\n", "\\n").gsub("\t", "\\t")
  rescue
    ""
  end

  def csv_split_line(line)
    values = []
    current = ""
    quoted = false
    i = 0
    text = line.to_s
    while i < text.length
      char = text[i, 1]
      if quoted
        if char == '"'
          if text[i + 1, 1] == '"'
            current += '"'
            i += 1
          else
            quoted = false
          end
        else
          current += char
        end
      else
        if char == '"'
          quoted = true
        elsif char == ','
          values << current
          current = ""
        else
          current += char
        end
      end
      i += 1
    end
    values << current
    values
  rescue
    line.to_s.split(',')
  end

  def ruby_http_available?
    # RGSS builds used by Pokemon Essentials often ship without Ruby's stdlib
    # networking files. Avoid probing them with require because handled LoadError
    # exceptions are still shown to players in debug builds.
    @leaderboard_ruby_http_available = false
  rescue
    false
  end

  def run_ruby_http_for_leaderboard(method, url, headers = {}, body = nil)
    nil
  rescue
    nil
  end

  def curl_available?
    return @leaderboard_curl_available if !@leaderboard_curl_available.nil?
    output = ""
    command = windows_platform? ? "curl --version 2> NUL" : "curl --version 2>/dev/null"
    if windows_platform? && respond_to?(:windows_hidden_capture)
      output = windows_hidden_capture(command)
    elsif defined?(IO) && IO.respond_to?(:popen)
      IO.popen(command) { |io| output = io.read.to_s }
    else
      command = windows_platform? ? "curl --version > NUL 2>&1" : "curl --version > /dev/null 2>&1"
      return @leaderboard_curl_available = (windows_platform? ? windows_hidden_command(command) : system(command))
    end
    @leaderboard_curl_available = output.downcase.include?("curl")
  rescue
    @leaderboard_curl_available = false
  end

  def leaderboard_portable_http_available?
    ruby_http_available? || curl_available?
  rescue
    false
  end

  def run_curl_for_leaderboard(command)
    return nil if !curl_available?
    output = ""
    if windows_platform? && respond_to?(:windows_hidden_capture)
      output = windows_hidden_capture(command)
    elsif defined?(IO) && IO.respond_to?(:popen)
      IO.popen(command) { |io| output = io.read.to_s }
    else
      output_file = File.join(ENV["TEMP"].to_s.empty? ? "Data" : ENV["TEMP"].to_s, "SurvivorSupabaseOutput_#{Time.now.to_i}_#{rand(999999)}.txt")
      system("#{command} > #{shell_quote(output_file)}")
      File.open(output_file, "rb") { |file| output = file.read.to_s } if FileTest.exist?(output_file)
      File.delete(output_file) if FileTest.exist?(output_file) rescue nil
    end
    sanitize_leaderboard_output(output)
  rescue
    nil
  end

  def supabase_curl_get_csv(url)
    key = supabase_anon_key
    output = run_ruby_http_for_leaderboard("get", url, {
      "apikey" => key,
      "Authorization" => "Bearer #{key}",
      "Accept" => "text/csv"
    })
    return output if output && !output.to_s.strip.empty? && !output.to_s.start_with?("ERROR")
    command = "curl -L -sS --max-time 8 " +
              "-H #{shell_quote("apikey: #{key}")} " +
              "-H #{shell_quote("Authorization: Bearer #{key}")} " +
              "-H #{shell_quote("Accept: text/csv")} " +
              shell_quote(url)
    run_curl_for_leaderboard(command)
  rescue
    nil
  end

  def supabase_curl_post_json(url, payload)
    remaining = online_cooldown_remaining(url)
    return "ERROR\trate_limited\t#{remaining}" if remaining > 0
    key = supabase_anon_key
    body = "{" + payload.map { |k, v| "\"#{json_escape(k)}\":#{v.is_a?(Numeric) ? v.to_i : "\"#{json_escape(v)}\""}" }.join(",") + "}"
    output = run_ruby_http_for_leaderboard("post", url, {
      "apikey" => key,
      "Authorization" => "Bearer #{key}",
      "Content-Type" => "application/json"
    }, body)
    return online_note_response(url, output) if output && !output.to_s.strip.empty? &&
      (!output.to_s.start_with?("ERROR") || output.to_s.start_with?("ERROR\t"))
    command = "curl -L -sS --max-time 8 -X POST " +
              "-H #{shell_quote("apikey: #{key}")} " +
              "-H #{shell_quote("Authorization: Bearer #{key}")} " +
              "-H #{shell_quote("Content-Type: application/json")} " +
              "--data #{shell_quote(body)} " + shell_quote(url)
    online_note_response(url, run_curl_for_leaderboard(command))
  rescue
    nil
  end

  def run_powershell_for_leaderboard(script, require_read_config = true)
    return nil if require_read_config && !leaderboard_read_configured?
    output_file = File.join(ENV["TEMP"].to_s.empty? ? "Data" : ENV["TEMP"].to_s, "SurvivorSupabaseOutput_#{Time.now.to_i}_#{rand(999999)}.txt")
    script_file = File.join(ENV["TEMP"].to_s.empty? ? "Data" : ENV["TEMP"].to_s, "SurvivorSupabaseRequest_#{Time.now.to_i}_#{rand(999999)}.ps1")
    wrapped = "$ErrorActionPreference = 'Stop'\r\n" +
              "try {\r\n  & { #{script} } | Out-File -LiteralPath #{powershell_escape(output_file)} -Encoding UTF8\r\n" +
              "} catch {\r\n  ('ERROR' + [char]9 + $_.Exception.Message) | Out-File -LiteralPath #{powershell_escape(output_file)} -Encoding UTF8\r\n}\r\n"
    File.open(script_file, "wb") { |file| file.write(wrapped) }
    command = "powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File #{shell_quote(script_file)}"
    if windows_platform? && respond_to?(:windows_hidden_command)
      windows_hidden_command(command)
    elsif defined?(IO) && IO.respond_to?(:popen)
      IO.popen(command) { |io| io.read rescue nil }
    else
      system(command)
    end
    output = ""
    File.open(output_file, "rb") { |file| output = file.read.to_s } if FileTest.exist?(output_file)
    File.delete(output_file) if FileTest.exist?(output_file) rescue nil
    File.delete(script_file) if FileTest.exist?(script_file) rescue nil
    sanitize_leaderboard_output(output)
  rescue
    nil
  end
  def trainer_name_taken_online?(name, allow_current = true)
    return false if allow_current && normalized_trainer_name(name).downcase == leaderboard_player_name.to_s.strip.downcase
    return :unavailable if !leaderboard_read_configured?
    clean = normalized_trainer_name(name)
    url = "#{supabase_url}/rest/v1/#{SUPABASE_TABLE}?select=player_name&player_name=ilike.#{url_query_escape(clean)}&limit=1"
    output = supabase_curl_get_csv(url).to_s
    if output.to_s.strip.empty? || output.start_with?("ERROR")
      key = supabase_anon_key
      script = "try { $h=@{apikey=#{powershell_escape(key)};Authorization=#{powershell_escape("Bearer #{key}")}}; $r=Invoke-RestMethod -Uri #{powershell_escape(url)} -Headers $h -Method Get -TimeoutSec 8; if (@($r).Count -gt 0) { 'TAKEN' } else { 'FREE' } } catch { 'ERROR`t' + $_.Exception.Message }"
      output = run_powershell_for_leaderboard(script).to_s
      return true if output.strip.start_with?("TAKEN")
      return false if output.strip.start_with?("FREE")
      return :unavailable
    end
    rows = sanitize_leaderboard_output(output).sub(/\A\uFEFF/, "").split(/\r?\n/).reject { |line| line.to_s.strip.empty? }
    rows.length > 1
  rescue
    :unavailable
  end

  def leaderboard_run_key
    "survivor-#{Time.now.to_i}-#{rand(1_000_000)}"
  rescue
    "survivor-#{rand(1_000_000)}"
  end

  def compact_best_leaderboard_entries(entries, limit = LEADERBOARD_LIMIT, sort = :score)
    seen = {}
    compacted = []
    return compacted if limit.to_i <= 0
    # Keep server tie order, but never rely on input order to select the best run.
    ordered = Array(entries).select { |entry| entry.is_a?(Hash) }.each_with_index.sort_by do |entry, index|
      score, level = entry[:score].to_i, entry[:level].to_i
      sort.to_s == "level" ? [-level, -score, index] : [-score, -level, index]
    end
    ordered.each do |entry, _index|
      player = normalized_trainer_name(entry[:player]).downcase
      pokemon = entry[:pokemon].to_s.strip.upcase
      key = [player, pokemon]
      next if player.empty? || pokemon.empty? || seen[key]
      seen[key] = true
      compacted << entry.dup
      break if compacted.length >= limit.to_i
    end
    compacted.each_with_index { |entry, index| entry[:rank] = index + 1 }
    compacted
  rescue
    []
  end

  def fetch_leaderboard_entries(mode = :classic, limit = LEADERBOARD_LIMIT, sort = :score, pokemon_filter = nil)
    return [] if !leaderboard_read_configured?
    display_limit = [[limit.to_i, 1].max, LEADERBOARD_LIMIT].min
    request_limit = [[display_limit * 10, display_limit].max, 1000].min
    mode = mode.to_s
    mode = LEADERBOARD_MODES.include?(mode) ? mode : "classic"
    player_only = sort.to_s == "player"
    sort_key = sort.to_s == "level" ? "level" : "score"
    order = (sort_key == "level" ? "level.desc,score.desc" : "score.desc,level.desc") + ",created_at.asc,id.asc"
    filters = []
    filter = pokemon_filter.to_s.strip
    filters << "pokemon=eq.#{url_query_escape(filter)}" if !filter.empty?
    player_name = normalized_trainer_name(leaderboard_player_name)
    return [] if player_only && player_name.empty?
    filters << "player_name=ilike.#{url_query_escape(player_name)}" if player_only
    filter_query = filters.empty? ? "" : "&#{filters.join("&")}"
    url = "#{supabase_url}/rest/v1/#{SUPABASE_TABLE}?select=player_name,pokemon,level,score,mode,run_time_seconds,created_at&mode=eq.#{mode}#{filter_query}&order=#{order}&limit=#{request_limit}"
    output = sanitize_leaderboard_output(supabase_curl_get_csv(url).to_s)
    if output.to_s.strip.empty? || output.start_with?("ERROR")
      key = supabase_anon_key
      script = "try { $h=@{apikey=#{powershell_escape(key)};Authorization=#{powershell_escape("Bearer #{key}")}}; $r=Invoke-RestMethod -Uri #{powershell_escape(url)} -Headers $h -Method Get -TimeoutSec 8; $i=0; $r | ForEach-Object { $i++; \"$i`t$($_.player_name)`t$($_.pokemon)`t$($_.level)`t$($_.score)\" } } catch { 'ERROR`t' + $_.Exception.Message }"
      output = sanitize_leaderboard_output(run_powershell_for_leaderboard(script).to_s)
      entries = output.split(/\r?\n/).map do |line|
        line = line.to_s.sub(/^\uFEFF/, "").strip
        rank, player, pokemon, level, score = line.split("\t", 5)
        next nil if rank.to_s.empty? || player.to_s.empty? || rank == "ERROR"
        display_pokemon = leaderboard_pokemon_display_name(pokemon)
        { rank: rank.to_i, player: player.to_s, pokemon: pokemon.to_s, pokemon_name: display_pokemon, level: level.to_i, name: "#{player} - #{display_pokemon} Lv. #{level.to_i}", score: score.to_i, submissions: 1 }
      end.compact
      return compact_best_leaderboard_entries(entries, display_limit, sort)
    end
    entries = output.split(/\r?\n/).each_with_index.map do |line, index|
      next nil if index == 0 || line.to_s.strip.empty?
      cols = csv_split_line(line)
      player, pokemon, level_value, score_value = cols[0], cols[1], cols[2], cols[3]
      next nil if player.to_s.empty?
      display_pokemon = leaderboard_pokemon_display_name(pokemon)
      { rank: index, player: player.to_s, pokemon: pokemon.to_s, pokemon_name: display_pokemon, level: level_value.to_i, name: "#{player} - #{display_pokemon} Lv. #{level_value.to_i}", score: score_value.to_i, submissions: 1 }
    end.compact
    compact_best_leaderboard_entries(entries, display_limit, sort)
  rescue
    []
  end

  def leaderboard_client_version
    respond_to?(:leaderboard_local_version) ? leaderboard_local_version.to_s : "unknown"
  rescue
    "unknown"
  end

  def leaderboard_run_checksum(player_name, pokemon, level, score, mode, run_time, floor_reached, bosses_defeated, damage_taken, kills)
    seed = "SVB6|#{leaderboard_client_version}|#{player_name}|#{pokemon}|#{level.to_i}|#{score.to_i}|#{mode}|#{run_time.to_i}|#{floor_reached.to_i}|#{bosses_defeated.to_i}|#{damage_taken.to_i}|#{kills.to_i}"
    hash = 2166136261
    seed.each_byte do |byte|
      hash ^= byte
      hash = (hash * 16777619) & 0xFFFFFFFF
    end
    hash.to_s(16).rjust(8, "0")
  rescue
    ""
  end

  def submit_leaderboard_run(score, idempotency_key = nil, hero_name = nil, level = nil, mode = nil, run_time = nil, extra_stats = nil)
    return nil if respond_to?(:leaderboard_version_allowed?) && !leaderboard_version_allowed?
    return nil if !supabase_submit_configured?
    score = score.to_i
    return nil if score <= 0
    player_name = leaderboard_run_player_name(hero_name, level)
    pokemon = supabase_pokemon_name(hero_name)
    mode = mode.to_s
    mode = LEADERBOARD_MODES.include?(mode) ? mode : "classic"
    extra_stats ||= {}
    floor_reached = extra_stats[:floor_reached].to_i
    bosses_defeated = extra_stats[:bosses_defeated].to_i
    damage_taken = extra_stats[:damage_taken].to_i
    kills = extra_stats[:kills].to_i
    client_version = leaderboard_client_version
    validation_hash = leaderboard_run_checksum(player_name, pokemon, level, score, mode, run_time, floor_reached, bosses_defeated, damage_taken, kills)
    payload = {
      player_name: player_name, pokemon: pokemon, level: level.to_i, score: score, mode: mode,
      run_time_seconds: run_time.to_i, floor_reached: floor_reached, bosses_defeated: bosses_defeated,
      damage_taken: damage_taken, kills: kills, client_version: client_version, validation_hash: validation_hash,
      run_key: idempotency_key || leaderboard_run_key
    }
    queued_id = online_enqueue_submission(:classic, payload)
    return "ERROR\tsave_failed" unless queued_id
    entry = online_submission_queue[queued_id]
    return entry[:response].to_s if entry[:status] == :rejected
    return "QUEUED" if entry[:next_try].to_i > Time.now.to_i
    token = rank_reward_access_token
    return "QUEUED" if token.to_s.empty?
    payload = payload.merge(access_token: token)
    output = sanitize_leaderboard_output(supabase_curl_post_json(supabase_submit_url, payload).to_s).strip
    if !payload[:access_token] && (output.empty? || (output.start_with?("ERROR") && !output.start_with?("ERROR\t")))
      script = "try { $h=@{apikey=#{powershell_escape(supabase_anon_key)};Authorization=#{powershell_escape("Bearer #{supabase_anon_key}")};'Content-Type'='application/json'}; $body=@{player_name=#{powershell_escape(player_name)};pokemon=#{powershell_escape(pokemon)};level=#{level.to_i};score=#{score};mode=#{powershell_escape(mode)};run_time_seconds=#{run_time.to_i};floor_reached=#{floor_reached};bosses_defeated=#{bosses_defeated};damage_taken=#{damage_taken};kills=#{kills};client_version=#{powershell_escape(client_version)};validation_hash=#{powershell_escape(validation_hash)};run_key=#{powershell_escape(payload[:run_key])}} | ConvertTo-Json -Depth 4; $r=Invoke-RestMethod -Uri #{powershell_escape(supabase_submit_url)} -Headers $h -Method Post -Body $body -TimeoutSec 8; 'OK ' + ($r | ConvertTo-Json -Compress -Depth 6) } catch { 'ERROR ' + $_.Exception.Message + ' ' + $_.ErrorDetails.Message }"
      output = run_powershell_for_leaderboard(script, false).to_s.strip
    end
    supabase_log_result(:submit, "player=#{player_name}\npokemon=#{pokemon}\nlevel=#{level.to_i}\nscore=#{score}\nmode=#{mode}\nresponse=#{output}") rescue nil
    online_finish_submission(queued_id, output)
    online_submission_success?(:classic, output) || online_submission_rejected?(output) ? output : "QUEUED"
  rescue
    nil
  end
end
