module SurvivorChallengeRun
  def challenge_mode?
    !!@challenge_run
  end

  def start_game(hero, mode = :classic)
    @challenge_run = mode == :challenge
    @challenge_preparing = @challenge_run
    @challenge_wave = -1
    @challenge_kills_without_chest = 0
    @challenge_result_ready = false
    @challenge_session = nil unless @challenge_run
    super
    return unless challenge_mode?
    @run_mode = :challenge
    @breach_run = true # Existing healing gates; breach_mode? below remains false.
    @run_speed_available, @run_speed = false, 1.0
    @boss_timer = @chest_timer = @item_timer = 999_999.0
    @post_run_auto_saved = false
    breach_change_background
  end

  def breach_mode?
    !challenge_mode? && super
  end

  def world_walls_enabled?
    challenge_mode? || super
  end

  def world_tile_span
    challenge_mode? ? 3.0 : super
  end

  def challenge_apply_loadout(passives, moves)
    raise ArgumentError unless passives.length == 7 && moves.length == 2
    moves.each { |upgrade| apply_upgrade(upgrade) }
    raise ArgumentError, 'Challenge requires three skills' unless @learned_skills.length == 3
    passives.each { |upgrade| titan_max_upgrade(upgrade) }
    @level = PokemonSurvivor::Challenge::LEVEL
    @xp = 0
    apply_hero_growth_stage(1)
    apply_hero_growth_stage(2)
    @hero.hp = @hero.max_hp
    @hero.singleton_class.prepend(SurvivorTitanHealth)
    @hero.instance_variable_set(:@titan_no_heal, true)
    @pending_upgrade = false
    @pending_upgrade_count = 0
    @pending_upgrade_queue = []
    @pending_evolution_stage = @evolution_anim = nil
    @challenge_preparing = false
    @timer, @last_time, @accumulator = 0.0, System.uptime, 0.0
  end

  def apply_pokemon_equipment_effects(base)
    return super unless challenge_mode?
    @equipped_item = nil
    @equipment_last_hit_time = 0.0
  end

  [:apply_roguelite_shop_upgrades, :apply_endless_shop_upgrades, :gain_direct_xp,
   :update_xp, :check_hero_evolution, :spawn_boss, :spawn_chest, :update_ultra_spawns,
   :spawn_wild_item, :spawn_moves_item, :request_move_upgrade, :spawn_boss_reward_item].each do |method|
    define_method(method) { |*args| super(*args) unless challenge_mode? }
  end

  [:random_event_enabled?, :sleep_event_enabled?, :classic_or_endless_events_enabled?,
   :can_drop_moves_item?, :classic_mode_timer_complete?, :run_speed_available?,
   :leaderboard_share_eligible?, :leaderboard_run_won?, :porygon_rigging_active?].each do |method|
    define_method(method) { |*args| challenge_mode? ? false : super(*args) }
  end

  def hero_take_damage(amount, invuln_time = 0.55)
    key = @passive_key
    @passive_key = nil if challenge_mode? && key == :MIMIKYU
    super
  ensure
    @passive_key = key
  end

  def available_upgrades
    pool = super
    return pool unless challenge_mode? && !@challenge_preparing
    pool.select { |upgrade| upgrade[:target_skill] && !upgrade[:skill] && !upgrade[:tower_fallback] }
  end

  def chestboss_bonus_available?
    challenge_mode? ? !available_upgrades.empty? : super
  end

  def apply_wild_item(name, count = 1)
    return super unless challenge_mode?
    super if name == 'CHESTBOSS' && chestboss_bonus_available?
  end

  def update_items(dt)
    if challenge_mode?
      @items.delete_if { |item| item.name != 'CHESTBOSS' }
      if !@items.empty? && !chestboss_bonus_available?
        @items.clear
      else
        @items.each do |item|
          item.ttl = Float::INFINITY
          dx, dy = @hero.x - item.x, @hero.y - item.y
          distance = Math.sqrt(dx * dx + dy * dy)
          next if distance <= 0.0
          step = [600.0 * dt, distance].min / distance
          item.x += dx * step
          item.y += dy * step
        end
      end
    end
    super
  end

  def defeat_enemy(enemy)
    return super unless challenge_mode?
    return if !enemy || enemy.instance_variable_get(:@defeated)
    enemy.instance_variable_set(:@defeated, true)
    enemy.defeated = true if enemy.respond_to?(:defeated=)
    enemy.hp = 0
    @kills += 1
    @score = @kills
    apply_passive_burst_on_kill
    play_enemy_ko_cry(enemy)
    if chestboss_bonus_available?
      @challenge_kills_without_chest = @challenge_kills_without_chest.to_i + 1
      if @challenge_kills_without_chest >= 150 || rand(100) == 0
        spawn_boss_chest(enemy.x, enemy.y, 1)
        @challenge_kills_without_chest = 0
      end
    else
      @challenge_kills_without_chest = 0
    end
  end

  def update_game(dt)
    return super unless challenge_mode?
    return if @challenge_preparing
    wave = (@timer / 30).floor
    if wave > @challenge_wave && @timer < 900
      @challenge_wave = wave
      enqueue_enemy_spawns(:wild, [24 + wave * 2, 64].min)
      @swarm_alert_active_timer = 4.0
    end
    @swarm_alert_active_timer = [@swarm_alert_active_timer.to_f - dt, 0.0].max
    super
  end

  def spawn_wave
    return super unless challenge_mode?
    if @timer >= 900
      @spawn_queue.clear
      @spawn_queue_index = 0
      titan_spawn_clone
      @spawn_timer = 0.8
    else
      enqueue_enemy_spawns(:wild, [3 + (@timer / 90).floor, 12].min)
      @spawn_timer = 0.65
    end
  end

  def spawn_enemy(kind, forced_name = nil)
    return super unless challenge_mode?
    return if @timer >= 900
    before = @enemies.length
    result = super
    if @enemies.length > before
      enemy = @enemies.last
      stats = challenge_enemy_pressure(@timer)
      enemy.max_hp = enemy.hp = stats[:hp]
      enemy.damage = stats[:damage]
      enemy.speed = stats[:speed]
      enemy.shooter = rand < stats[:shooter_chance]
      enemy.cooldown = 1.5 + rand * 2.0
    end
    result
  end

  def challenge_enemy_pressure(seconds)
    # Thirty-second opening, then continuous two-minute ramps without stat jumps.
    minutes = [seconds.to_f - 30.0, 0.0].max / 60.0
    ramp = (1..7).sum { |step| [[(minutes - step * 2.0) / 2.0, 0.0].max, 1.0].min }
    {
      hp: (120 * (1.0 + minutes * 0.45)**2.8 * (1.0 + ramp * 0.12)).round,
      damage: (10 * (1.0 + minutes * 0.30)**1.45).round,
      speed: [1.0 + minutes * 0.19 + ramp * 0.06, 3.8].min,
      shooter_chance: [minutes * 0.04, 0.40].min,
      shot_interval: [3.6 - minutes * 0.12, 2.0].max
    }
  end

  def update_enemy_shot(enemy, dt)
    return super unless challenge_mode? && enemy.kind == :wild
    return unless enemy.shooter && enemy_visible?(enemy)
    return if @timer < 30 || @projectiles.length >= PokemonSurvivor::MAX_PROJECTILES
    enemy.cooldown -= dt
    return if enemy.cooldown > 0
    dx, dy = @hero.x - enemy.x, @hero.y - enemy.y
    length = [Math.sqrt(dx * dx + dy * dy), 1.0].max
    spawn_enemy_projectile(enemy, dx / length, dy / length)
    enemy.cooldown = challenge_enemy_pressure(@timer)[:shot_interval]
  end

  def finish_run(*args)
    return super unless challenge_mode?
    return if @run_finished
    @run_finished = true
    @challenge_store.settle(@challenge_session, @kills, @timer, !!@run_abandoned)
    @state = :gameover
    clear_transient_run_state
    cleanup_classic_endless_variety_events
    @state = :gameover
    @result_text = @run_abandoned ? _INTL('Run abandoned') : _INTL('Challenge ended')
    auto_save_successful_run_once
  end

  def seasonal_run_result_data
    return super unless challenge_mode?
    result = @challenge_store.result
    text = if result && result[:expired]
             _INTL('Season ended - score not ranked')
           elsif result
             _INTL('Ranking points: {1}', result[:delta])
           else
             _INTL('Result saved - awaiting connection')
           end
    { title: _INTL('Challenge ended'), classic_layout: true, primary: _INTL('KOs: {1}', @kills),
      stats: [[_INTL('Level'), @level], [_INTL('Target'), @challenge_session[:ko]],
        [_INTL('Time'), '%d:%02d' % [@timer.to_i / 60, @timer.to_i % 60]]],
      rewards: text, actions: [_INTL('Return to Challenge')], index: 0 }
  end

  def update_gameover
    return super unless challenge_mode?
    draw_gameover
    @challenge_result_ready = true unless PokemonSurvivor.control_press?(:confirm) || PokemonSurvivor.control_press?(:cancel)
    return unless @challenge_result_ready && (survivor_confirm_triggered? || survivor_cancel_triggered?)
    return_to_select_menu
    challenge_open_menu
  end

  def return_to_select_menu
    if challenge_mode?
      @challenge_run = @challenge_preparing = false
      @challenge_session = nil
      @run_mode = :classic
    end
    super
  end

  def draw_hud(bitmap)
    super
    return unless challenge_mode? && @challenge_session
    text = _INTL('Target: {1} KOs', @challenge_session[:ko])
    line = @bitmaps['__challenge_target_hud']
    if !line || line.disposed?
      line = @bitmaps['__challenge_target_hud'] = Bitmap.new(178, 22)
      @challenge_target_text_key = nil
    end
    pbSetSmallFont(line)
    line.font.size = 20
    key = [text, line.font.name, line.font.size]
    if @challenge_target_text_key != key
      line.clear
      fitted = ellipsize_text(line, text, 176)
      pbDrawTextPositions(line, [[fitted, 0, 0, false, Color.new(230, 205, 255), Color.new(40, 40, 48)]])
      @challenge_target_text_key = key
    end
    bitmap.blt(18, 47, line, Rect.new(0, 0, 178, 22))
  end
end
