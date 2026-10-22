# Persist only submissions explicitly requested by the player. Workers do network
# I/O only; all save/progression changes happen on the scene's main thread.
module PokemonSurvivor
  module_function

  def online_retry_after(text)
    match = text.to_s.match(/(?:ERROR\s+)?rate_limited(?:\s+|:)(\d+)/i)
    match ? [[match[1].to_i, 1].max, 3600].min : 0
  end

  def online_cooldown_remaining(url)
    @online_cooldowns ||= {}
    [(@online_cooldowns[url].to_f - System.uptime).ceil, 0].max
  end

  def online_note_response(url, output)
    if output.to_s.include?("session_expired") && defined?(Titan)
      Titan.auth_sessions.clear
    end
    seconds = online_retry_after(output)
    if seconds > 0
      @online_cooldowns ||= {}
      @online_cooldowns[url] = System.uptime + seconds + 1
    end
    output
  end

  def online_save_progress
    return false unless defined?(Game) && Game.respond_to?(:save)
    PlayerShop.prepare_for_save if defined?(PlayerShop) && PlayerShop.respond_to?(:prepare_for_save)
    Game.save
  rescue StandardError
    false
  end

  def online_submission_queue
    survivor_progress[:online_submissions] ||= {}
  end

  def online_enqueue_submission(kind, payload)
    token = kind == :breach ? payload[:session_id] : payload[:run_key]
    return nil if token.to_s.empty?
    id = "#{kind}:#{token}"
    queue = online_submission_queue
    queue[id] ||= { kind: kind, payload: payload.dup, attempts: 0, next_try: 0, status: :pending }
    return nil unless online_save_progress
    id
  end

  def online_submission_url(kind)
    kind == :breach ? "#{supabase_url}/functions/v1/breach" : supabase_submit_url
  end

  def online_submission_success?(kind, output)
    text = output.to_s.strip
    kind == :breach ? text == "OK" : !!(text =~ /"ok"\s*:\s*true\b/)
  end

  def online_submission_rejected?(output)
    # Unknown/network/server errors stay pending. A final refusal remains saved
    # for diagnosis, but is not sent endlessly and does not trigger any ban.
    !!(output.to_s =~ /\b(?:invalid_mode|invalid_level|invalid_score|invalid_time|invalid_floor|invalid_bosses|invalid_damage|invalid_kills|invalid_validation_hash|endless_too_short|endless_score_too_low|season_closed_or_invalid_run|invalid_run|invalid_payload)\b/)
  end

  def online_finish_submission(id, output)
    entry = online_submission_queue[id]
    return false unless entry
    if online_submission_success?(entry[:kind], output)
      online_submission_queue.delete(id)
    elsif online_submission_rejected?(output)
      entry[:status] = :rejected
      entry[:response] = output.to_s[0, 512]
    else
      entry[:attempts] = entry[:attempts].to_i + 1
      delay = [15 * (2 ** [entry[:attempts] - 1, 5].min), online_retry_after(output)].max
      entry[:next_try] = Time.now.to_i + delay + 1 + rand(5)
    end
    online_save_progress
  end

  def online_send_submission(id)
    entry = online_submission_queue[id]
    return "ERROR\tsave_failed" unless entry
    return entry[:response].to_s if entry[:status] == :rejected
    return "QUEUED" if entry[:next_try].to_i > Time.now.to_i
    payload = entry[:payload].dup
    if entry[:kind] == :classic
      token = rank_reward_access_token
      return "QUEUED" if token.to_s.empty?
      payload[:access_token] = token
    end
    output = supabase_curl_post_json(online_submission_url(entry[:kind]), payload).to_s
    online_finish_submission(id, output)
    return output if online_submission_success?(entry[:kind], output) || online_submission_rejected?(output)
    "QUEUED"
  end

  def online_retry_tick(allow_start)
    if @online_retry_worker
      return if @online_retry_worker.alive?
      output = @online_retry_worker.value
      root, id = @online_retry_root, @online_retry_id
      titan, job = @online_retry_titan, @online_retry_titan_job
      @online_retry_worker = @online_retry_root = @online_retry_id = nil
      @online_retry_titan = @online_retry_titan_job = nil
      if root.equal?(survivor_progress)
        titan ? titan.complete_background(job, output) : online_finish_submission(id, output)
      end
    end
    return if online_titan_notification_tick(allow_start)
    return unless allow_start
    now = System.uptime
    return if now < @online_retry_check_at.to_f
    @online_retry_check_at = now + 1.0
    root = survivor_progress
    queue = root[:online_submissions]
    @online_retry_titan = @online_retry_titan_job = nil
    pair = queue.is_a?(Hash) && queue.find { |_id, entry| entry[:status] == :pending && entry[:next_try].to_i <= Time.now.to_i }
    if pair
      id, entry = pair
      url, payload = online_submission_url(entry[:kind]), entry[:payload].dup
      if entry[:kind] == :classic
        token = rank_reward_access_token
        return if token.to_s.empty?
        payload[:access_token] = token
      end
    else
      return unless defined?(Titan::OnlineState) && root[:titan_online].is_a?(Hash) && root[:titan_online][:pending]
      titan = Titan::OnlineState.new(root, proc { |&b| b.call }, proc { online_save_progress })
      job = titan.background_job
      return unless job
      url, payload = "#{supabase_url}/functions/v1/titan-season", job[1]
      @online_retry_titan, @online_retry_titan_job = titan, job
    end
    return unless online_save_progress
    @online_retry_root, @online_retry_id = root, id
    @online_retry_worker = Thread.new do
      begin
        supabase_curl_post_json(url, payload).to_s
      rescue StandardError
        ""
      end
    end
  end

  def online_titan_busy?(account)
    (@online_retry_titan && @online_retry_worker && @online_retry_root && @online_retry_root[:titan_online].equal?(account)) ||
      (@titan_notification_worker && @titan_notification_root && @titan_notification_root[:titan_online].equal?(account))
  end

  def request_titan_notification_refresh
    return if @titan_notification_worker
    @titan_notification_root = survivor_progress
    @titan_notification_state = nil
    @titan_notification_stage = :auth
    @titan_notification_snapshot = nil
  end

  def titan_notification_snapshot
    @titan_notification_snapshot if @titan_notification_snapshot_root.equal?(survivor_progress)
  end

  def titan_notification_refresh_pending?
    !!(@titan_notification_worker || @titan_notification_stage)
  end

  # Network work runs off-thread; authentication and saves are applied on the main thread.
  def online_titan_notification_tick(allow_start)
    if @titan_notification_worker
      return true if @titan_notification_worker.alive?
      output = @titan_notification_worker.value
      @titan_notification_worker = nil
      if @titan_notification_root.equal?(survivor_progress)
        lines = @titan_notification_state.decode_response(output)
        if @titan_notification_stage == :auth
          @titan_notification_stage = @titan_notification_state.apply_auth_response(lines) ? :status : nil
        else
          if lines && @titan_notification_state.accept(lines)
            @titan_notification_snapshot = @titan_notification_state
            @titan_notification_snapshot_root = @titan_notification_root
          end
          @titan_notification_stage = nil
        end
      else
        @titan_notification_stage = nil
      end
    end
    return false unless allow_start && @titan_notification_stage
    unless @titan_notification_root.equal?(survivor_progress)
      @titan_notification_stage = nil
      return false
    end
    account = @titan_notification_root[:titan_online]
    if account.is_a?(Hash) && account[:pending]
      @titan_notification_stage = nil
      return false
    end
    @titan_notification_state ||= Titan::OnlineState.new(@titan_notification_root,
      proc { |&job| job.call }, proc { online_save_progress })
    account = @titan_notification_root[:titan_online]
    if @titan_notification_stage == :auth && Titan.auth_sessions[account[:access_token]].to_f > System.uptime
      @titan_notification_stage = :status
    end
    if @titan_notification_stage == :status
      payload = { action: "status", season_id: 0, access_token: account[:access_token] }
    elsif !account[:refresh_token].to_s.empty?
      payload = { action: "refresh", refresh_token: account[:refresh_token] }
    elsif !account[:user_id]
      payload = { action: "register" }
    else
      @titan_notification_stage = nil
      return false
    end
    url = "#{supabase_url}/functions/v1/titan-season"
    @titan_notification_worker = Thread.new do
      begin
        supabase_curl_post_json(url, payload).to_s
      rescue StandardError
        ""
      end
    end
    true
  end
end
