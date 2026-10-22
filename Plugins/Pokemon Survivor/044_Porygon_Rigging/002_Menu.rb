#===============================================================================
# Porygon Rigging - mode selection editor and paid run snapshot
#===============================================================================
class Scene_PokemonSurvivor
  def porygon_rigging_active?
    @porygon_run_settings && @porygon_run_settings[:enabled] &&
      !@breach_run && !@titan_run && PokemonSurvivor::PORYGON_MODES.include?(@run_mode)
  end

  def porygon_excluded?(category, id)
    porygon_rigging_active? && @porygon_run_settings[category].include?(id)
  end

  def start_porygon_configured_run(pokemon, mode)
    return unless PokemonSurvivor.hero_unlocked?(pokemon)
    settings = PokemonSurvivor.porygon_settings(pokemon)
    cost = PokemonSurvivor.porygon_cost(pokemon, settings, mode)
    tree = PokemonSurvivor.endless_shop_currency_unlocked? ? :endless : :standard
    if cost > 0
      PokemonSurvivor.active_shop_currency(tree)
      progress = PokemonSurvivor.survivor_progress
      fragments = progress[:shop_currency].to_i
      dark = progress[:dark_shop_currency].to_i
      rate = PokemonSurvivor::DARK_FRAGMENT_CONVERSION_RATE
      balance = fragments + (tree == :endless ? dark * rate : 0)
      if balance < cost
        pbMessage(_INTL("Not enough currency for Porygon Trickery. Change or disable it before starting."))
        return
      end
      return unless confirm_porygon_payment(cost, tree)
      if tree == :endless
        # Break only the Dark Fragments needed and preserve the exact change.
        needed = [(cost - fragments + rate - 1) / rate, 0].max
        progress[:dark_shop_currency] = dark - needed
        progress[:shop_currency] = fragments + needed * rate - cost
      else
        progress[:shop_currency] = fragments - cost
      end
      unless PokemonSurvivor.online_save_progress
        progress[:shop_currency] = fragments
        progress[:dark_shop_currency] = dark
        pbMessage(_INTL("The purchase could not be saved. No currency was spent."))
        return
      end
    end
    @porygon_pending_settings = settings if settings[:enabled] && PokemonSurvivor::PORYGON_MODES.include?(mode)
    start_game(pokemon, mode)
  ensure
    @porygon_pending_settings = nil
    draw_mode_select if @state == :mode_select
    @last_time = System.uptime
    @accumulator = 0.0
    Input.update
  end

  def confirm_porygon_payment(cost, tree)
    selected = 1
    rate = PokemonSurvivor::DARK_FRAGMENT_CONVERSION_RATE
    amount = tree == :endless ? format("%.3f", cost.to_f / rate).sub(/0+$/, "").sub(/\.$/, "") : cost.to_s
    currency = tree == :endless ? _INTL("Dark Fragments") : _INTL("Fragments")
    icon = cached_icon_bitmap(tree == :endless ? "ICON_DARKFRAGMENT" : "ICON_FRAGMENT")
    Input.update
    loop do
      Graphics.update
      Input.update
      if Input.repeat?(Input::LEFT) || Input.repeat?(Input::RIGHT) || Input.repeat?(Input::UP) || Input.repeat?(Input::DOWN)
        selected = 1 - selected
      end
      draw_mode_select
      bitmap = @sprites["screen"].bitmap
      overlay = @sprites["overlay"].bitmap
      overlay.clear
      bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0, 150))
      width = [Graphics.width - 48, 360].min
      height = 180
      x, y = (Graphics.width - width) / 2, (Graphics.height - height) / 2
      draw_panel(bitmap, x, y, width, height, Color.new(236, 126, 174), Color.new(24, 30, 48))
      @shop_bg_frame = @shop_bg_frame.to_i + 1
      draw_porygon_centered_text(bitmap, _INTL("Ready to pay?"), x + 16, y + 12, width - 32, 32, Color.white, true)
      has_icon = icon && !icon.disposed?
      icon_width = has_icon ? icon.width : 0
      label = _INTL("{1} {2}", amount, currency)
      pbSetSystemFont(bitmap)
      text_width = [bitmap.text_size(label).width.ceil + 8, width - 40 - icon_width].min
      group_width = text_width + icon_width + (has_icon ? 8 : 0)
      left = x + (width - group_width) / 2
      bitmap.blt(left, y + 75 - icon.height / 2, icon, Rect.new(0, 0, icon.width, icon.height)) if has_icon
      draw_porygon_centered_text(bitmap, label, left + icon_width + (has_icon ? 8 : 0), y + 55,
        text_width, 40, Color.new(255, 218, 100), true)
      button_width = (width - 44) / 2
      [_INTL("Pay"), _INTL("Cancel")].each_with_index do |label_text, i|
        bx = x + 16 + i * (button_width + 12)
        draw_select_menu_button(bitmap, bx, y + 118, button_width, 42, "", selected == i, i == 0 ? 2 : 4)
        draw_porygon_centered_text(bitmap, label_text, bx + 6, y + 118, button_width - 12, 42, Color.white, true)
      end
      draw_help(overlay, [[:left, ""], [:right, _INTL("Select")], [:confirm, _INTL("Confirm")], [:cancel, _INTL("Back")]])
      draw_tv_filter(overlay)
      return false if survivor_cancel_triggered?
      return selected == 0 if survivor_confirm_triggered?
    end
  ensure
    Input.update
    draw_mode_select
  end

  def porygon_price_text(pokemon, settings, mode)
    amount = PokemonSurvivor.porygon_cost(pokemon, settings, mode)
    _INTL("{1} Fragments / run", amount)
  end

  def open_porygon_rigging
    pokemon = @mode_select_hero || selected_hero_name
    unless PokemonSurvivor.porygon_rigging_unlocked?(pokemon)
      pbMessage(_INTL("Unlock Endless Mode and complete this Pokemon's Adventure Badge to unlock Porygon Trickery."))
      return
    end
    draft = PokemonSurvivor.porygon_settings(pokemon)
    mode = PokemonSurvivor::PORYGON_MODES[@mode_select_index.to_i] || :classic
    @porygon_editor_pokemon, @porygon_editor_mode = pokemon, mode
    index = 0
    totals = [:eggs, :skills, :passives].map { |category| PokemonSurvivor.porygon_catalog(pokemon, category).length }
    title = _INTL("Porygon Trickery - {1}", PokemonSurvivor.species_name(pokemon))
    Input.update
    loop do
      Graphics.update
      Input.update
      index = porygon_main_navigation(index)
      labels = [:eggs, :skills, :passives].each_with_index.map do |category, i|
        total = totals[i]
        _INTL("{1}: {2}/{3}", porygon_category_name(category), total - draft[category].length, total)
      end
      labels << _INTL("Sleep order: {1}", draft[:sleep].empty? ? _INTL("Random") : _INTL("Custom"))
      labels += [draft[:enabled] ? _INTL("Disable") : _INTL("Enable"), _INTL("Reset"), _INTL("Confirm"), _INTL("Cancel")]
      @porygon_editor_draft = draft
      descriptions = [
        _INTL("Keep at least 2 possible companions. Each exclusion costs 50 Fragments per run."),
        _INTL("Keep at least 6 learnable skills. Each exclusion costs 25 Fragments per run."),
        _INTL("Keep at least 6 passive bonuses. Each exclusion costs 25 Fragments per run."),
        _INTL("Choose the awakening order for 50 Fragments per run. No charge in Tower."),
        _INTL("Enable or disable these settings for this Pokemon's next runs."),
        _INTL("Restore random choices and disable rigging. Confirm to save."),
        _INTL("Save these settings. Payment is requested when starting each run."),
        _INTL("Return without saving changes.")
      ]
      status = draft[:enabled] ? _INTL("Enabled") : _INTL("Disabled")
      draw_porygon_list(title, labels, index, descriptions[index],
        status)
      break if survivor_cancel_triggered?
      next unless survivor_confirm_triggered?
      case index
      when 0, 1, 2 then porygon_choose_pool(pokemon, draft, [:eggs, :skills, :passives][index])
      when 3 then porygon_choose_sleep(pokemon, draft)
      when 4 then draft[:enabled] = !draft[:enabled]
      when 5
        if pbConfirmMessage(_INTL("Reset all Porygon Trickery settings for this Pokemon?"))
          draft = PokemonSurvivor.porygon_default_settings
        end
        Input.update
      when 6
        progress = PokemonSurvivor.survivor_progress
        progress[:porygon_rigging] ||= {}
        key = PokemonSurvivor.species_key(pokemon)
        previous = progress[:porygon_rigging][key]
        progress[:porygon_rigging][key] = PokemonSurvivor.porygon_normalize(pokemon, draft)
        if PokemonSurvivor.online_save_progress
          break
        end
        progress[:porygon_rigging][key] = previous
        pbMessage(_INTL("The settings could not be saved. Please try again."))
      when 7 then break
      end
    end
  ensure
    @porygon_editor_pokemon = @porygon_editor_mode = @porygon_editor_draft = nil
    @porygon_editor_price_key = @porygon_editor_price = nil
    Input.update
    @last_time = System.uptime
    @accumulator = 0.0
    draw_mode_select
  end

  def porygon_category_name(category)
    case category
    when :eggs then _INTL("Egg companions")
    when :skills then _INTL("Skills")
    when :passives then _INTL("Passive bonuses")
    else _INTL("Sleep order")
    end
  end

  def porygon_choose_pool(pokemon, draft, category)
    ids = PokemonSurvivor.porygon_catalog(pokemon, category)
    return if ids.empty?
    upgrades = PokemonSurvivor.localized_upgrade_pool
    ids = porygon_sorted_choices(ids, category, upgrades) unless category == :eggs
    cards = if category != :eggs
              ids.map do |id|
                upgrades.find { |u| category == :skills ? u[:skill] == id : u[:id] == id }
              end
            end
    @porygon_grid_scroll = 0.0
    @porygon_grid_target = 0.0
    names = ids.map do |id|
      category == :eggs ? PokemonSurvivor.species_name(id) :
        (category == :skills ? PokemonSurvivor.localized_skill(id)[:name] : upgrades.find { |u| u[:id] == id }[:name])
    end
    index = 0
    Input.update
    loop do
      Graphics.update
      Input.update
      if category == :eggs
        index = porygon_portrait_navigation(index, ids.length)
      else
        index = porygon_portrait_navigation(index, ids.length, 3)
      end
      allowed = ids.map { |id| !draft[category].include?(id) }
      description = if category == :eggs
                      porygon_event_description(ids[index])
                    elsif category == :skills
                      PokemonSurvivor.localized_skill(ids[index])[:desc]
                    else
                      upgrades.find { |u| u[:id] == ids[index] }[:desc]
                    end
      draw_porygon_list(porygon_category_name(category), names, index, description,
        _INTL("{1}/{2} kept", allowed.count(true), ids.length), allowed, false, category == :eggs ? ids : nil, nil, cards)
      if survivor_cancel_triggered?
        if PokemonSurvivor.porygon_normalize(pokemon, draft)[category] == draft[category]
          break
        end
        minimum = category == :eggs ? 2 : 6
        pbMessage(_INTL("Keep at least {1} choices before leaving this list.", [minimum, ids.length].min))
        Input.update
        next
      end
      if PokemonSurvivor.control_trigger?(:action)
        draft[category] = draft[category].empty? ? ids.dup : []
        next
      end
      next unless survivor_confirm_triggered?
      id = ids[index]
      proposed = draft[category].dup
      proposed.include?(id) ? proposed.delete(id) : proposed.push(id)
      draft[category] = proposed
    end
    Input.update
  end

  def porygon_choose_sleep(pokemon, draft)
    ids = PokemonSurvivor.porygon_catalog(pokemon, :sleep)
    return if ids.empty?
    order = []
    index = 0
    Input.update
    loop do
      Graphics.update
      Input.update
      index = porygon_portrait_navigation(index, ids.length)
      labels = ids.map do |id|
        place = order.index(id)
        place ? _INTL("{1}. {2}", place + 1, PokemonSurvivor.species_name(id)) : PokemonSurvivor.species_name(id)
      end
      draw_porygon_list(_INTL("Sleep order"), labels, index,
        porygon_event_description(ids[index], true),
        _INTL("{1}/{2}", order.length, ids.length), nil, true, ids, order)
      break if survivor_cancel_triggered?
      if PokemonSurvivor.control_trigger?(:menu)
        draft[:sleep] = []
        break
      end
      next unless survivor_confirm_triggered?
      order.include?(ids[index]) ? order.delete(ids[index]) : order.push(ids[index])
      if order.length == ids.length
        draft[:sleep] = order
        break
      end
    end
    Input.update
  end

  def porygon_event_description(key, sleep_event = false)
    data = (sleep_event ? SLEEP_EVENT_DATA : BABY_EVENT_DATA)[PokemonSurvivor.species_key(key)] || {}
    _INTL("{1} - {2}", PokemonSurvivor.species_name(key), _INTL(data[:desc].to_s))
  end

  def porygon_sorted_choices(ids, category, upgrades)
    types = [:NORMAL, :FIRE, :WATER, :ELECTRIC, :GRASS, :ICE, :FIGHTING, :POISON,
             :GROUND, :FLYING, :PSYCHIC, :BUG, :ROCK, :GHOST, :DRAGON, :DARK, :STEEL, :FAIRY]
    rarities = [:common, :uncommon, :rare, :epic, :super_rare, :legendary]
    by_id = {}
    upgrades.each { |u| by_id[category == :skills ? u[:skill] : u[:id]] ||= u }
    ids.sort_by do |id|
      data = by_id[id] || {}
      if category == :skills
        skill = PokemonSurvivor.localized_skill(id)
        [types.index(skill[:type]) || types.length, skill[:name].to_s.downcase, id.to_s]
      else
        [rarities.index(upgrade_rarity(data)) || rarities.length, data[:name].to_s.downcase, id.to_s]
      end
    end
  end

  def porygon_editor_price_text
    return "" unless @porygon_editor_draft
    draft = @porygon_editor_draft
    key = [draft[:enabled], draft[:eggs].dup, draft[:skills].dup, draft[:passives].dup, draft[:sleep].dup]
    if @porygon_editor_price_key != key
      @porygon_editor_price = porygon_price_text(@porygon_editor_pokemon, draft, @porygon_editor_mode)
      @porygon_editor_price_key = key
    end
    @porygon_editor_price
  end

  def porygon_portrait_columns(count)
    [[(Graphics.width - 56 + 10) / 82, 1].max, count].min
  end

  def porygon_portrait_navigation(index, count, columns = nil)
    columns ||= porygon_portrait_columns(count)
    if Input.repeat?(Input::LEFT)
      return (index - 1) % count
    elsif Input.repeat?(Input::RIGHT)
      return (index + 1) % count
    elsif Input.repeat?(Input::UP)
      return index - columns if index >= columns
      return [((count - 1) / columns) * columns + index, count - 1].min
    elsif Input.repeat?(Input::DOWN)
      return index + columns < count ? index + columns : index % columns
    end
    index
  end

  def porygon_portrait_bitmap(key)
    @porygon_portrait_sources ||= {}
    source = @porygon_portrait_sources[key] ||= begin
      folder = "#{PokemonSurvivor::ROOT}/Menu HUD/Porygon Trickery"
      if pbResolveBitmap("#{folder}/#{key}")
        [folder, key.to_s]
      else
        [PokemonSurvivor::EVENT_BABY_DIR, "#{key}_Icon"]
      end
    end
    cached_bitmap(*source)
  end

  def draw_porygon_portrait_grid(bitmap, ids, index, allowed, order, top, bottom)
    size, gap = 72, 10
    columns = porygon_portrait_columns(ids.length)
    rows = (ids.length + columns - 1) / columns
    visible = [[(bottom - top + gap) / (size + gap), 1].max, rows].min
    first = [[index / columns - visible + 1, 0].max, rows - visible].min
    start_x = (Graphics.width - (columns * (size + gap) - gap)) / 2
    start_y = top + ((bottom - top - (visible * (size + gap) - gap)) / 2)
    (first * columns...[((first + visible) * columns), ids.length].min).each do |i|
      x = start_x + (i % columns) * (size + gap)
      y = start_y + (i / columns - first) * (size + gap)
      selected = i == index
      included = !allowed || allowed[i]
      edge = selected ? Color.new(255, 218, 100) : Color.new(100, 140, 180)
      fill = included ? Color.new(28, 48, 68) : Color.new(30, 30, 38)
      draw_modern_button_frame(bitmap, x, y, size, size, edge, fill, edge, selected)
      portrait = porygon_portrait_bitmap(ids[i])
      if portrait && !portrait.disposed?
        bitmap.blt(x + (size - portrait.width) / 2, y + (size - portrait.height) / 2,
          portrait, Rect.new(0, 0, portrait.width, portrait.height), included ? 255 : 90)
      end
      if allowed
        bitmap.fill_rect(x + size - 18, y + size - 18, 12, 12, Color.new(8, 13, 26))
        bitmap.fill_rect(x + size - 16, y + size - 16, 8, 8, included ? Color.new(100, 236, 164) : Color.new(104, 108, 120))
      elsif order && order.include?(ids[i])
        position = order.index(ids[i])
        colors = [[46, 112, 190], [38, 132, 84], [164, 92, 24], [150, 62, 142]]
        draw_pixel_round_rect(bitmap, x + size - 28, y + size - 28, 26, 26, Color.new(8, 13, 26))
        draw_pixel_round_rect(bitmap, x + size - 27, y + size - 27, 24, 24, Color.new(*colors[position % colors.length]))
        draw_porygon_centered_text(bitmap, (position + 1).to_s,
          x + size - 27, y + size - 27, 24, 24, Color.white, true)
      end
    end
    if rows > visible
      draw_leaderboard_scrollbar(bitmap, Graphics.width - 24, top, 6, bottom - top, first, visible, rows)
    end
  end

  def draw_porygon_centered_text(bitmap, text, x, y, width, height, color, center_x = false)
    pbSetSystemFont(bitmap)
    @shop_scrolling_text_cache ||= {}
    key = [:porygon, text.to_s, bitmap.font.name, bitmap.font.size, color.red, color.green, color.blue, color.alpha]
    line = @shop_scrolling_text_cache[key]
    unless line && !line.disposed?
      if @shop_scrolling_text_cache.length >= 96
        old = @shop_scrolling_text_cache.delete(@shop_scrolling_text_cache.keys.first)
        old.dispose if old && !old.disposed?
      end
      line = Bitmap.new([bitmap.text_size(text.to_s).width.ceil + 8, 1].max, 96)
      pbSetSystemFont(line)
      pbDrawTextPositions(line, [[text.to_s, 0, 24, false, color, Color.new(30, 30, 40)]])
      top = bottom = nil
      line.height.times do |yy|
        next unless (0...line.width).any? { |xx| line.get_pixel(xx, yy).alpha > 0 }
        top ||= yy
        bottom = yy
      end
      line.instance_variable_set(:@porygon_ink_bounds, top ? [top, bottom - top + 1] : [0, 0])
      @shop_scrolling_text_cache[key] = line
    end
    top, ink_height = line.instance_variable_get(:@porygon_ink_bounds)
    if center_x == true && ink_height > 0
      bounds = line.instance_variable_get(:@porygon_horizontal_ink_bounds)
      unless bounds
        columns = (0...line.width).select do |xx|
          (top...top + ink_height).any? { |yy| line.get_pixel(xx, yy).alpha > 0 }
        end
        bounds = columns.empty? ? [0, line.width] : [columns.first, columns.last - columns.first + 1]
        line.instance_variable_set(:@porygon_horizontal_ink_bounds, bounds)
      end
      left, ink_width = bounds
      shown = [width, ink_width].min
      offset = shop_scroll_offset([ink_width - width, 0].max, 5, 70)
      bitmap.blt(x + (width - shown) / 2, y + (height - ink_height) / 2,
        line, Rect.new(left + offset, top, shown, ink_height))
      return
    end
    shown_width = [width, line.width].min
    offset = shop_scroll_offset([line.width - width, 0].max, 5, 70)
    dest_x = center_x == :right ? x + width - shown_width : (center_x ? x + (width - shown_width) / 2 : x)
    bitmap.blt(dest_x, y + (height - ink_height) / 2, line, Rect.new(offset, top, shown_width, ink_height)) if ink_height > 0
  end

  def draw_porygon_description(bitmap, text, x, y, width, height)
    pbSetSystemFont(bitmap)
    lines = wrapped_lines(bitmap, text.to_s, width, nil)
    line_height = 24
    content_height = lines.length * line_height
    color = Color.white
    if content_height <= height
      top = y + (height - content_height) / 2
      lines.each_with_index do |line, i|
        draw_porygon_centered_text(bitmap, line, x, top + i * line_height, width, line_height, color)
      end
      return
    end
    @ui_wrapped_text_cache ||= {}
    key = [:porygon, lines, width, bitmap.font.name, bitmap.font.size]
    block = @ui_wrapped_text_cache[key]
    unless block && !block.disposed?
      if @ui_wrapped_text_cache.length >= 64
        old = @ui_wrapped_text_cache.delete(@ui_wrapped_text_cache.keys.first)
        old.dispose if old && !old.disposed?
      end
      block = Bitmap.new(width, content_height)
      lines.each_with_index do |line, i|
        draw_porygon_centered_text(block, line, 0, i * line_height, width, line_height, color)
      end
      @ui_wrapped_text_cache[key] = block
    end
    bitmap.blt(x, y, block, Rect.new(0, scroll_offset(content_height - height, 10.0), width, height))
  end

  def draw_porygon_upgrade_list(bitmap, cards, index, allowed, top, bottom)
    previous_levels = @upgrade_levels
    @upgrade_levels = {}
    width = (Graphics.width - 90) / 3
    height = Graphics.height - 158
    viewport_height = bottom - top
    row_height = height + 32
    rows = (cards.length + 2) / 3
    content_height = rows * row_height - 8
    target = @porygon_grid_target.to_f
    row_top = (index / 3) * row_height
    target = row_top if row_top < target
    target = row_top + height + 24 - viewport_height if row_top + height + 24 > target + viewport_height
    @porygon_grid_target = [[target, 0].max, [content_height - viewport_height, 0].max].min
    @porygon_grid_scroll = @porygon_grid_scroll.to_f + (@porygon_grid_target - @porygon_grid_scroll.to_f) * 0.35
    @porygon_grid_scroll = @porygon_grid_target if (@porygon_grid_target - @porygon_grid_scroll).abs < 0.5
    surface = @bitmaps["porygon_upgrade_grid"]
    if !surface || surface.disposed? || surface.width != Graphics.width || surface.height != viewport_height
      surface.dispose if surface && !surface.disposed?
      surface = @bitmaps["porygon_upgrade_grid"] = Bitmap.new(Graphics.width, viewport_height)
    end
    surface.clear
    pbSetSystemFont(surface)
    first = (@porygon_grid_scroll / row_height).floor
    last = [((@porygon_grid_scroll + viewport_height) / row_height).floor, rows - 1].min
    (first..last).each do |row|
      3.times do |column|
        i = row * 3 + column
        next if i >= cards.length
        x = (Graphics.width - (width * 3 + 14)) / 2 + column * (width + 7)
        y = row * row_height - @porygon_grid_scroll.round
        preview = cards[i].merge(porygon_excluded: !allowed[i])
        draw_upgrade_card(surface, preview, x, y, width, height, i == index)
        surface.fill_rect(x + width - 21, y + height - 21, 18, 18, Color.new(8, 13, 26))
        surface.fill_rect(x + width - 18, y + height - 18, 12, 12,
          allowed[i] ? Color.new(100, 236, 164) : Color.new(104, 108, 120))
        label = allowed[i] ? _INTL("Included") : _INTL("Excluded")
        color = allowed[i] ? Color.new(100, 236, 164) : Color.new(255, 145, 145)
        draw_porygon_centered_text(surface, label, x, y + height, width, 24, color, true)
      end
    end
    bitmap.blt(0, top, surface, Rect.new(0, 0, Graphics.width, viewport_height))
    if content_height > viewport_height
      draw_leaderboard_scrollbar(bitmap, Graphics.width - 24, top, 6, viewport_height,
        @porygon_grid_scroll.round, viewport_height, content_height)
    end
  ensure
    @upgrade_levels = previous_levels
  end

  def porygon_main_navigation(index)
    if Input.repeat?(Input::LEFT) || Input.repeat?(Input::RIGHT)
      return index >= 4 ? (index.even? ? index + 1 : index - 1) : index
    end
    return [6, 0, 1, 2, 3, 3, 4, 5][index] if Input.repeat?(Input::UP)
    return [1, 2, 3, 4, 6, 7, 0, 0][index] if Input.repeat?(Input::DOWN)
    index
  end

  def draw_porygon_main_buttons(bitmap, labels, index, top, bottom)
    rows = [[0], [1], [2], [3], [4, 5], [6, 7]]
    selected_row = index < 4 ? index : 4 + (index - 4) / 2
    visible = [[(bottom - top) / 36, 1].max, rows.length].min
    first = [[selected_row - visible + 1, 0].max, rows.length - visible].min
    full_width = Graphics.width - 52
    visible.times do |offset|
      items = rows[first + offset]
      y = top + offset * 36
      button_width = items.length == 1 ? full_width : (full_width - 10) / 2
      items.each_with_index do |item, column|
        x = 22 + column * (button_width + 10)
        draw_porygon_menu_button(bitmap, x, y, button_width, 32, item, item == index)
        draw_porygon_centered_text(bitmap, labels[item], x + 10, y, button_width - 20, 32, Color.white)
      end
    end
    if rows.length > visible
      draw_leaderboard_scrollbar(bitmap, Graphics.width - 24, top, 6, visible * 36 - 4, first, visible, rows.length)
    end
  end

  def draw_porygon_menu_button(bitmap, x, y, width, height, row, selected)
    colors = [
      [232, 192, 76],  # Egg companions
      [84, 144, 224],  # Skills
      [166, 116, 220], # Passive bonuses
      [222, 116, 182], # Sleep order
      [62, 186, 192],  # Enable / Disable
      [228, 140, 62],  # Reset
      [82, 178, 118],  # Confirm
      [206, 72, 76]   # Cancel
    ]
    rgb = colors[row] || colors[0]
    edge = Color.new(*rgb)
    fill = Color.new(*rgb.map { |value| (value * 0.28).round + (selected ? 34 : 0) })
    shine = Color.new(*rgb.map { |value| [value + (selected ? 64 : 40), 255].min })
    draw_modern_button_frame(bitmap, x, y, width, height, edge, fill, shine, selected)
  end

  def draw_porygon_list(title, labels, index, description, status, allowed = nil, sleep_order = false, portraits = nil, order = nil, cards = nil)
    @shop_bg_frame = @shop_bg_frame.to_i + 1
    bitmap, overlay = @sprites["screen"].bitmap, @sprites["overlay"].bitmap
    overlay.clear
    draw_options_scrolling_background(bitmap)
    draw_panel(bitmap, 6, 4, Graphics.width - 12, Graphics.height - 8,
      Color.new(72, 82, 108), Color.new(14, 20, 34, 215))
    pbSetSystemFont(bitmap)
    width = Graphics.width - 32
    draw_panel(bitmap, 16, 12, width, 64, Color.new(236, 126, 174), Color.new(34, 28, 52))
    icon = porygon_portrait_bitmap(:PORYGONZ)
    if icon && !icon.disposed?
      bitmap.blt(24, 12 + (64 - icon.height) / 2, icon, Rect.new(0, 0, icon.width, icon.height))
    end
    draw_porygon_centered_text(bitmap, title, 72, 18, width - 68, 26, Color.white)
    price_width = ((width - 68) * 0.64).to_i
    draw_porygon_centered_text(bitmap, status, 72, 44, width - 76 - price_width, 26, Color.new(255, 218, 100))
    draw_porygon_centered_text(bitmap, porygon_editor_price_text, Graphics.width - 28 - price_width,
      44, price_width, 26, Color.new(255, 218, 100), :right)
    top = 84
    bottom = Graphics.height - (cards ? 40 : 112)
    if portraits
      draw_porygon_portrait_grid(bitmap, portraits, index, allowed, order, top, bottom)
    elsif cards
      draw_porygon_upgrade_list(bitmap, cards, index, allowed, top, bottom)
    else
      draw_porygon_main_buttons(bitmap, labels, index, top, bottom)
    end
    unless cards
      draw_panel(bitmap, 16, Graphics.height - 104, width, 64, Color.new(100, 184, 232), Color.new(24, 34, 50))
      draw_porygon_description(bitmap, description, 28, Graphics.height - 96, width - 24, 48)
    end
    help = [[:up, ""], [:down, _INTL("Select")], [:confirm, allowed ? _INTL("Toggle") : _INTL("Confirm")]]
    help = [[:left, ""], [:right, _INTL("Select")], [:confirm, allowed ? _INTL("Toggle") : _INTL("Confirm")]] if portraits
    help << [:menu, _INTL("Random")] if sleep_order
    if allowed
      help << [:action, allowed.all? ? _INTL("Disable all") : _INTL("Enable all")]
    end
    help << [:cancel, _INTL("Back")]
    draw_help(overlay, help)
    draw_tv_filter(overlay)
  end
end
