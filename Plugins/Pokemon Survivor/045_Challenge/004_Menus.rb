module SurvivorChallengeMenus
  def challenge_online_error
    error = @challenge_store && @challenge_store.last_error
    message = case error
    when 'season_unavailable' then _INTL('There is no open Challenge season right now.')
    when 'rewards_locked' then _INTL('Rewards open once 100 players have points and first place reaches 200 points.')
    when 'not_enough_crystals' then _INTL('Not enough Dark Crystals.')
    when 'active_run' then _INTL('An unfinished challenge is already registered for this account.')
    when 'save_failed' then _INTL('Progress could not be saved. Please try again before continuing.')
    else _INTL('Challenge could not connect. Pending results are kept for the next connection.')
    end
    pbMessage(message)
  end

  def challenge_open_menu
    previous_bgm = @survivor_menu_bgm
    @survivor_menu_bgm = 'Survivor/Breach'
    play_survivor_menu_bgm
    @challenge_store = PokemonSurvivor::Challenge::OnlineState.new(PokemonSurvivor.survivor_progress,
      proc { |&job| breach_wait(_INTL('Connecting to Challenge...'), &job) }, proc { breach_save_menu_progress })
    unless @challenge_store.connect
      challenge_online_error
      return
    end
    loop do
      data = @challenge_store.snapshot
      choice = breach_choose(_INTL('Challenge - Season {1}', @challenge_store.season_id), [
        [_INTL('Start a run'), _INTL('Beat a higher-ranked player. Only Pokemon training applies.')],
        [_INTL('Leaderboard'), _INTL('Compare ranking points and best KO records.')],
        [_INTL('Secret Shop'), _INTL('Exchange Dark Crystals for seasonal rewards.')],
        [_INTL('Cancel'), _INTL('Return to the seasonal mode selection.')]
      ], _INTL('Points: {1} - Dark Crystals: {2}', data[:points], data[:crystals]), true, @challenge_store.season)
      break if choice.nil? || choice == 3
      case choice
      when 0
        target = challenge_choose_target
        next unless target
        @challenge_pokemon_picker = true
        hero = breach_choose_pokemon
        @challenge_pokemon_picker = false
        next unless hero
        return if challenge_prepare_run(hero, target)
      when 1 then challenge_board_menu
      when 2 then challenge_shop
      end
    end
  ensure
    @challenge_pokemon_picker = false
    @challenge_store.close if @challenge_store && @state != :play
    breach_save_menu_progress
    @survivor_menu_bgm = previous_bgm
    play_survivor_menu_bgm unless @state == :play
  end

  def breach_pokemon_picker_title(hero)
    @challenge_pokemon_picker ? _INTL('Challenge - {1}', PokemonSurvivor.species_name(hero)) : super
  end

  def challenge_choose_target
    board = @challenge_store.leaderboard
    unless board
      challenge_online_error
      return nil
    end
    targets = challenge_compatible_targets(board)
    if targets.empty?
      pbMessage(_INTL('No eligible opponents are available right now.'))
      return nil
    end
    challenge_board_menu(targets, true)
  end

  def challenge_compatible_targets(board)
    rank = @challenge_store.snapshot[:rank]
    targets = if rank == 1
                board.select { |row| row[:id] == @challenge_store.own_id }
              else
                board.select { |row| row[:id] != @challenge_store.own_id && (rank == 0 || row[:rank] < rank) }
              end
    if targets.empty? && @challenge_store.snapshot[:points] == 0 && board.none? { |row| row[:id] != @challenge_store.own_id }
      targets = [{ id: 'rookie', name: 'Rookie', points: 0, ko: 500, rank: 0 }]
    end
    targets
  end

  def challenge_board_menu(board = nil, choosing_target = false)
    board ||= @challenge_store.leaderboard
    return challenge_online_error unless board
    index, first, released = 0, 0, false
    Input.update
    loop do
      Graphics.update
      Input.update
      released = true unless PokemonSurvivor.control_press?(:confirm)
      return nil if survivor_cancel_triggered?
      if released && survivor_confirm_triggered?
        return choosing_target && board[index] ? board[index][:id] : nil
      end
      if !choosing_target && battle_pass_auto_claim_triggered?
        challenge_rank_rewards
        released = false
        Input.update
      end
      index -= 1 if Input.repeat?(Input::UP)
      index += 1 if Input.repeat?(Input::DOWN)
      index = [[index, 0].max, [board.length - 1, 0].max].min
      first = titan_leaderboard_scroll(index, first, board.length)
      draw_challenge_leaderboard(board, index, first, choosing_target)
    end
  ensure
    @last_time, @accumulator = System.uptime, 0.0
    Input.update
  end

  def draw_challenge_leaderboard(rows, index, first, choosing_target = false)
    bitmap, overlay = @sprites['screen'].bitmap, @sprites['overlay'].bitmap
    overlay.clear
    draw_select_background(bitmap)
    pbSetSystemFont(bitmap)
    w, h = Graphics.width - 36, Graphics.height - 72
    blue, shadow = Color.new(92, 188, 255), Color.new(32, 32, 40)
    draw_panel(bitmap, 18, 38, w, h, blue, Color.new(18, 29, 50))
    draw_hud_header_strip(bitmap, 34, 52, w - 32, 34, blue, Color.new(8, 13, 26))
    draw_leaderboard_cell(bitmap, _INTL('Challenge - Season {1}', @challenge_store.season_id),
      34, 60, w - 32, 22, blue, shadow, 2)
    available = w - 44
    widths = [48, (available * 0.40).floor, (available * 0.25).floor]
    widths << available - widths.inject(0, :+)
    xs = [36]
    3.times { |i| xs << xs.last + widths[i] }
    [_INTL('Rank'), _INTL('Player'), _INTL('Points'), _INTL('KOs')].each_with_index do |title, i|
      draw_leaderboard_cell(bitmap, title, xs[i], 100, widths[i] - 6, 20, Color.new(122, 255, 176), shadow, 0)
    end
    draw_leaderboard_header_rule(bitmap, 36, 124, available)
    visible = leaderboard_visible_rows
    (rows[first, visible] || []).each_with_index do |row, offset|
      y = 132 + offset * 26
      bitmap.fill_rect(28, y, w - 32, 21, first + offset == index ? Color.new(32, 58, 92, 210) : Color.new(8, 13, 26, 190))
      draw_leaderboard_rank_cell(bitmap, row[:rank], xs[0], y + 2, widths[0] - 6, 18)
      draw_leaderboard_cell(bitmap, row[:name], xs[1], y + 2, widths[1] - 6, 18, leaderboard_player_color(row[:name]), shadow)
      [row[:points], row[:ko]].each_with_index do |value, i|
        draw_leaderboard_numeric_cell(bitmap, leaderboard_format_number(value), xs[i + 2], y + 2, widths[i + 2] - 6, 18, Color.new(255, 224, 92), shadow)
      end
    end
    if rows.empty?
      draw_leaderboard_cell(bitmap, _INTL('No ranked players yet.'), 34, 170, w - 32, 24, Color.white, shadow, 2)
    elsif rows.length > visible
      draw_leaderboard_scrollbar(bitmap, Graphics.width - 40, 132, 7, visible * 26 - 3, first, visible, rows.length)
    end
    action = choosing_target ? [:confirm, _INTL('Challenge')] : [:action, _INTL('Claim rewards')]
    draw_help(overlay, [[:up, ''], [:down, _INTL('Scroll')], action, [:cancel, _INTL('Back')]])
    draw_tv_filter(overlay)
  end

  def challenge_rank_rewards
    data = @challenge_store.snapshot
    before = data[:crystals]
    unless @challenge_store.claim_all
      challenge_online_error
      return
    end
    amount = @challenge_store.snapshot[:crystals] - before
    if amount > 0
      pbPlayDecisionSE
      pbMessage(_INTL('Received {1} Dark Crystals!', amount))
    else
      pbPlayBuzzerSE
      pbMessage(_INTL('No rank rewards to claim right now.'))
    end
  end

  def challenge_prepare_run(hero, target)
    return false unless seasonal_run_version_allowed?
    session = @challenge_store.begin_run(hero, target)
    unless session
      challenge_online_error
      return false
    end
    completed = false
    @challenge_session = session
    breach_screen_transition { start_game(hero, :challenge) }
    moves, passives = [], []
    2.times do |index|
      @challenge_build_step = index + 1
      pool = available_move_upgrades.reject { |u| moves.any? { |taken| taken[:skill] == u[:skill] } }
      choice = titan_choose_upgrade(_INTL('Extra skill {1}/2 - Level 1', index + 1), pool, 2 - index)
      return false unless choice
      moves << choice
    end
    7.times do |index|
      @challenge_build_step = index + 3
      pool = available_upgrades.reject do |u|
        u[:skill] || u[:target_skill] || u[:tower_fallback] ||
          [:lifesteal, :second_wind, :rare_draft, :chestxp, :floor_momentum, :boss_preparation,
           :expgain, :expgain_small, :magnet, :boss_damage, :overlevel_instinct].include?(u[:id]) ||
          PokemonSurvivor::Titan::WEAKER_PASSIVES.include?(u[:id]) || passives.any? { |taken| taken[:id] == u[:id] }
      end
      choice = titan_choose_upgrade(_INTL('Passive {1}/7 - Max Level', index + 1), pool, 7 - index)
      return false unless choice
      passives << choice
    end
    challenge_apply_loadout(passives, moves)
    completed = true
    breach_screen_transition { draw_game }
    true
  ensure
    if session && !completed
      @challenge_store.settle(session, 0, 0, true)
      return_to_select_menu
    end
    @last_time, @accumulator = System.uptime, 0.0
    Input.update
  end

  def titan_refresh_draft(pool, previous = [])
    offers = super
    if challenge_mode? && @challenge_preparing
      @titan_draft_cards.each do |card|
        next unless card[:skill]
        card[:category_label] = _INTL('Skill')
        card[:badge_text] = _INTL('Lv.1')
      end
    end
    offers
  end

  def draw_breach_shard_balance(bitmap)
    return super unless challenge_mode? && @challenge_preparing
    draw_soft_badge(bitmap, 28, 6, Graphics.width - 56, 30, Color.new(0, 0, 0, 180))
    draw_battle_pass_scrolling_text(bitmap, _INTL('Challenge preparation - {1}/9', @challenge_build_step),
      38, 10, Graphics.width - 76, 22, Color.white, Color.new(35, 35, 42), 2)
  end

  def weighted_upgrade_pick(pool)
    return super unless challenge_mode? && @challenge_preparing && pool.any? { |u| u[:skill] }
    weights = pool.map { |u| titan_draft_weight(u) }
    roll = rand(weights.inject(0, :+))
    pool.each_with_index { |u, i| roll -= weights[i]; return u if roll < 0 }
    pool.last
  end

  def challenge_shop
    previous = @titan_store
    @challenge_shop_active = true
    @titan_store = @challenge_store
    titan_tree_menu(:shop)
  ensure
    @titan_store = previous
    @challenge_shop_active = false
  end

  def titan_tree_title
    @challenge_shop_active ? _INTL('Dark Crystal Shop') : super
  end

  def titan_build_tree
    return super unless @challenge_shop_active
    @titan_tree_snapshot = @challenge_store.snapshot
    @titan_tree_nodes = [{ id: :titan_core, root: true, x: 0, y: 0, icon: 'Dark Crystal Shard' }]
    @titan_tree_links = []
    x = 0
    previous = :titan_core
    @titan_tree_snapshot[:offers].sort_by { |o| [o[:id] == :pokemon ? 0 : o[:id] == :prestige ? 1 : 2, o[:id].to_s] }.each do |data|
      if [:candies, :fragments].include?(data[:kind])
        nx, ny = 0, data[:kind] == :candies ? -1 : 1
        icon = data[:kind] == :candies ? 'Candy' : 'Fragment'
        parent = :titan_core
      else
        x += 1
        nx, ny = x, 0
        icon = data[:kind] == :prestige ? 'Prestige' : data[:reward]
        parent = previous
        previous = data[:id]
      end
      @titan_tree_nodes << { id: data[:id], upgrade: data, level: 1, x: nx, y: ny, icon: icon }
      @titan_tree_links << [parent, data[:id]]
    end
  end

  def shop_node_state(node)
    return super unless @challenge_shop_active
    return :bought if node[:root]
    data = node[:upgrade]
    view = @titan_tree_snapshot
    return :bought if view[:purchases][data[:id]].to_i >= data[:limit] || view[:owned].include?(data[:reward])
    :available
  end

  def titan_buy_tree_node(node)
    return super unless @challenge_shop_active
    return false unless node && shop_node_affordable?(node)
    quantity = 1
    data = node[:upgrade]
    if [:candies, :fragments].include?(data[:kind])
      snapshot = @challenge_store.snapshot
      quantity = choose_candy_exchange_quantity(snapshot[:crystals], data[:cost], data[:quantity],
        _INTL('Dark Crystals'), limit: data[:limit] - snapshot[:purchases][node[:id]].to_i,
        payment_icon: 'Dark Crystal Shard', reward_icon: data[:kind] == :candies ? 'ICON_CANDY' : 'ICON_FRAGMENT',
        reward_name: data[:kind] == :candies ? _INTL('Candies') : _INTL('Fragments'))
      return false if quantity <= 0
    end
    success = @challenge_store.buy(node[:id], quantity)
    challenge_online_error unless success
    if success && [:candies, :fragments].include?(node[:upgrade][:kind])
      enqueue_shop_resource_popup(node[:upgrade][:kind] == :candies ? 'ICON_CANDY' : 'ICON_FRAGMENT', node[:upgrade][:quantity] * quantity)
    end
    success
  end

  def titan_tree_details(node)
    return super unless @challenge_shop_active
    return [titan_tree_title, _INTL('Dark Crystals carry over between seasons.'), _INTL('Season {1}', @challenge_store.season_id)] if node[:root]
    data = node[:upgrade]
    name = case data[:kind]
    when :pokemon then PokemonSurvivor.species_name(data[:reward])
    when :prestige then _INTL('Prestige Crystal')
    when :candies then _INTL('Candies')
    when :fragments then _INTL('Fragments')
    else data[:reward]
    end
    desc = if data[:kind] == :prestige
      _INTL('Unlock an exclusive appearance for {1}. Only available this season.', PokemonSurvivor.species_name(data[:reward].sub('PRESTIGE_', '')))
    elsif data[:kind] == :pokemon
      _INTL('Unlock {1}.', name)
    else
      _INTL('Gain {1} {2}.', data[:quantity], name)
    end
    [name, desc, _INTL('Cost: {1} Dark Crystals - {2}/{3}', data[:cost], @titan_tree_snapshot[:purchases][data[:id]].to_i, data[:limit])]
  end

  def draw_shop_header(bitmap)
    return super unless @challenge_shop_active
    cy = 12 + (Scene_PokemonSurvivor::SHOP_HEADER_H - 20) / 2
    draw_mode_button_icon(bitmap, 'ICON_SHOP_SEASONS_CHALLENGE', 38, cy, 1.0)
    pbSetSystemFont(bitmap)
    text = @titan_tree_snapshot[:crystals].to_s
    source = cached_bitmap(PokemonSurvivor::SHOP_DIR, 'Dark Crystal Shard')
    width = bitmap.text_size(text).width.ceil + 24
    x = Graphics.width - 16 - width
    bitmap.blt(x - source.width - 6, cy - source.height / 2, source, source.rect) if source
    draw_shop_scrolling_text(bitmap, text, x, cy - 13, width, 40, Scene_PokemonSurvivor::SHOP_BLUE, Scene_PokemonSurvivor::SHOP_SHADOW_COLOR)
    draw_shop_scrolling_text(bitmap, titan_tree_title, 72, cy - 13, [x - (source ? source.width : 0) - 88, 1].max, 26,
      Scene_PokemonSurvivor::SHOP_GOLD, Scene_PokemonSurvivor::SHOP_SHADOW_COLOR)
  end
end

[SurvivorChallengeRun, SurvivorChallengeMenus].each do |extension|
  Scene_PokemonSurvivor.prepend(extension) unless Scene_PokemonSurvivor.ancestors.include?(extension)
end
