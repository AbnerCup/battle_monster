#===============================================================================
# Pokemon Survivor Achievements - menu state and navigation
#===============================================================================
class Scene_PokemonSurvivor
  prepend PokemonSurvivorAchievementSceneHooks unless ancestors.include?(PokemonSurvivorAchievementSceneHooks)

  def open_achievements
    stats = PokemonSurvivorAchievements.achievement_stats
    stats[:achievements_opened] = stats[:achievements_opened].to_i + 1
    PokemonSurvivorAchievements.check([:achievements_opened], true)
    PokemonSurvivorAchievements.check_retroactive(false)
    mark_achievement_notifications_seen
    @achievement_index ||= 0
    @achievement_scroll ||= 0
    @achievement_frame ||= 0
    @achievement_sparkles = []
    @achievement_sparkle_wait = 0
    @achievement_visible_medals = []
    @achievement_backdrop&.dispose if @achievement_backdrop && !@achievement_backdrop.disposed? rescue nil
    @achievement_backdrop = Bitmap.new(Graphics.width, Graphics.height)
    @achievement_backdrop.blt(0, 0, @sprites["screen"].bitmap, Rect.new(0, 0, Graphics.width, Graphics.height)) rescue nil
    @achievement_last_time = System.uptime rescue 0
    pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    play_survivor_bgm_name(PokemonSurvivor::ACHIEVEMENT_BGM) if respond_to?(:play_survivor_bgm_name)
    loop do
      Graphics.update
      Input.update
      update_achievement_frame
      update_achievement_sparkles
      update_achievement_input
      draw_achievements
      break if @achievement_closing
    end
    @achievement_backdrop&.dispose if @achievement_backdrop && !@achievement_backdrop.disposed? rescue nil
    @achievement_backdrop = nil
    @achievement_closing = false
    play_survivor_menu_bgm if respond_to?(:play_survivor_menu_bgm)
    if @state == :select_menu && respond_to?(:draw_select_menu)
      draw_select_menu
    elsif @state == :perf_options
      draw_performance_options rescue draw_select rescue nil
    else
      draw_select rescue nil
    end
  rescue
    @achievement_backdrop&.dispose if @achievement_backdrop && !@achievement_backdrop.disposed? rescue nil
    @achievement_backdrop = nil
    @achievement_closing = false
    play_survivor_menu_bgm if respond_to?(:play_survivor_menu_bgm)
    if @state == :select_menu && respond_to?(:draw_select_menu)
      draw_select_menu
    elsif @state == :perf_options
      draw_performance_options rescue nil
    else
      draw_select rescue nil
    end
  end

  def update_achievement_frame
    now = System.uptime rescue 0
    elapsed = now - (@achievement_last_time || now)
    return if elapsed < (1.0 / 60.0)
    @achievement_last_time = now
    @achievement_frame = @achievement_frame.to_i + [(elapsed * 60).floor, 1].max
  rescue
    @achievement_frame = Graphics.frame_count
  end

  def update_achievement_sparkles
    @achievement_sparkles ||= []
    @achievement_sparkles.each { |sparkle| sparkle[:timer] = sparkle[:timer].to_i + 1 }
    @achievement_sparkles.delete_if { |sparkle| sparkle[:timer].to_i >= 36 }
    @achievement_sparkle_wait = @achievement_sparkle_wait.to_i + 1
    return if @achievement_sparkle_wait < 14
    @achievement_sparkle_wait = 0
    return if rand(4) != 0
    positions = @achievement_visible_medals || []
    return if positions.empty? || @achievement_sparkles.length >= 3
    base = positions[rand(positions.length)]
    @achievement_sparkles << {
      :x => base[:x].to_i + (rand(17) - 8),
      :y => base[:y].to_i + (rand(17) - 8),
      :sheet => rand(2) == 0 ? "SPARKLE" : "SPARKLE2",
      :timer => 0,
      :scale => base[:scale] || 0.5
    }
  rescue
    @achievement_sparkles = []
  end
  def update_achievement_input
    if @achievement_detail_open
      if Input.repeat?(Input::LEFT)
        move_achievement_detail(-1)
      elsif Input.repeat?(Input::RIGHT)
        move_achievement_detail(1)
      elsif survivor_cancel_triggered? || survivor_confirm_triggered?
        pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
        @achievement_detail_open = false
      end
      return
    end
    count = PokemonSurvivorAchievements.total_count
    return if count <= 0
    old = @achievement_index.to_i
    cols = achievement_grid_cols
    @achievement_grid_col = @achievement_index.to_i % cols if @achievement_grid_col.nil?
    if Input.repeat?(Input::LEFT)
      move_achievement_grid(-1, 0)
    elsif Input.repeat?(Input::RIGHT)
      move_achievement_grid(1, 0)
    elsif Input.repeat?(Input::UP)
      move_achievement_grid(0, -1)
    elsif Input.repeat?(Input::DOWN)
      move_achievement_grid(0, 1)
    end
    if old != @achievement_index.to_i
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
    end
    if survivor_confirm_triggered?
      @achievement_detail_open = true
      pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    elsif survivor_cancel_triggered?
      pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
      @achievement_closing = true
    end
    ensure_achievement_scroll(true)
  rescue
  end

  def move_achievement_grid(dx, dy)
    count = PokemonSurvivorAchievements.total_count
    cols = achievement_grid_cols
    rows = (count + cols - 1) / cols
    index = @achievement_index.to_i
    row = index / cols
    col = index % cols
    @achievement_grid_col = [[@achievement_grid_col || col, 0].max, cols - 1].min
    if dx != 0
      row_start = row * cols
      row_end = [row_start + cols - 1, count - 1].min
      if dx < 0
        index = index <= row_start ? row_end : index - 1
      else
        index = index >= row_end ? row_start : index + 1
      end
      @achievement_grid_col = index % cols
    elsif dy != 0
      row = [[row + dy.to_i, 0].max, rows - 1].min
      wanted = (row * cols) + @achievement_grid_col.to_i
      row_end = [[(row * cols) + cols - 1, count - 1].min, row * cols].max
      index = [[wanted, row * cols].max, row_end].min
    end
    @achievement_index = [[index, 0].max, count - 1].min
    ensure_achievement_scroll(true)
  rescue
  end
  def move_achievement_detail(delta)
    count = PokemonSurvivorAchievements.total_count
    return if count <= 0
    @achievement_index = (@achievement_index.to_i + delta.to_i) % count
    @achievement_grid_col = @achievement_index.to_i % achievement_grid_cols
    ensure_achievement_scroll(false)
    pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
  rescue
  end
  def achievement_grid_cols
    9
  end

  def achievement_visible_rows
    7
  end

  def achievement_tile_size
    44
  end

  def ensure_achievement_scroll(center_on_selection = false, visible_override = nil)
    @achievement_scroll ||= 0
    cols = achievement_grid_cols
    visible = (visible_override || @achievement_effective_visible_rows || achievement_visible_rows).to_i
    visible = [visible, 1].max
    total_rows = (PokemonSurvivorAchievements.total_count + cols - 1) / cols
    max_scroll = [total_rows - visible, 0].max
    index_row = @achievement_index.to_i / cols
    if center_on_selection && total_rows > visible
      @achievement_scroll = index_row - (visible / 2)
    else
      @achievement_scroll = index_row if index_row < @achievement_scroll
      bottom = @achievement_scroll + visible - 1
      @achievement_scroll = index_row - visible + 1 if index_row > bottom
    end
    @achievement_scroll = [[@achievement_scroll, 0].max, max_scroll].min
  rescue
  end
end
