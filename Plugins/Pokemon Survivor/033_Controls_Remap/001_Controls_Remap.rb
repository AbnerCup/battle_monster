#===============================================================================
# Pokemon Survivor - Controls remap and gamepad feedback
#===============================================================================

module PokemonSurvivor
  CONTROL_FIXED_CONFIRM_KEYS = ["Enter", "Space"].freeze
  CONTROL_ACTIONS = [
    { id: :confirm, name: "Confirm / Burst", helper: :confirm, default_key: "C", desc: "Confirm choices in menus. In runs, this also activates Burst when ready." },
    { id: :cancel, name: "Back / Pause", helper: :cancel, default_key: "X", desc: "Go back in menus. In runs, this opens Pause." },
    { id: :action, name: "Save / Run Info", helper: :action, default_key: "Z", desc: "Save or open Pokemon training from selection. In runs, this toggles the run info panel." },
    { id: :menu, name: "Leaderboard / Sort", helper: :ready_menu, default_key: "D", desc: "Open the leaderboard from selection. In some menus, this sorts, filters, or opens secondary views." },
    { id: :zoom_toggle, name: "Zoom", helper: :zoom_toggle, default_key: "R", desc: "Toggle the run camera zoom." },
    { id: :focus_step, name: "Dash", helper: :focus_step, default_key: "A", desc: "Dash a short distance during runs and gain a brief moment of invulnerability." },
    { id: :speed_down, name: "Slower", helper: :speed_down, default_key: "F", desc: "Reduce run speed when acceleration is unlocked." },
    { id: :speed_up, name: "Faster", helper: :speed_up, default_key: "G", desc: "Increase run speed up to x3 when acceleration is unlocked." }
  ]
  CONTROL_ACTION_ORDER = [:confirm, :cancel, :action, :menu, :zoom_toggle, :focus_step, :speed_down, :speed_up]
  CONTROL_MENU_ITEMS = [:confirm, :cancel, :action, :menu, :zoom_toggle, :focus_step, :speed_down, :speed_up, :vibration]
  CONTROL_PICKER_COLUMNS = 6
  CONTROL_PICKER_VISIBLE_ROWS = 3
  CONTROL_GAMEPAD_KEYS = [
    "Button A", "Button B", "Button X", "Button Y",
    "Button Back", "Button Guide", "Button Start",
    "Left Shoulder", "Right Shoulder", "Left Trigger", "Right Trigger"
  ]

  module_function

  def default_control_bindings
    hash = { vibration: false }
    CONTROL_ACTIONS.each { |action| hash[action[:id]] = action[:default_key] }
    hash
  end

  def control_bindings
    opts = performance_options rescue nil
    if opts
      opts[:control_bindings] = default_control_bindings.merge(opts[:control_bindings] || {}) if !opts[:control_bindings].is_a?(Hash)
      default_control_bindings.each_pair { |key, value| opts[:control_bindings][key] = value if !opts[:control_bindings].key?(key) }
      normalize_legacy_control_bindings(opts[:control_bindings])
      return opts[:control_bindings]
    end
    $PokemonSurvivorControlBindings ||= default_control_bindings.dup
    normalize_legacy_control_bindings($PokemonSurvivorControlBindings)
    $PokemonSurvivorControlBindings
  rescue
    default_control_bindings.dup
  end

  def normalize_legacy_control_bindings(bindings)
    return if !bindings.is_a?(Hash)
    legacy = { confirm: "C", cancel: "X", action: "Z", menu: "D", zoom_toggle: "R", focus_step: "A" }
    CONTROL_ACTION_ORDER.each do |key|
      value = bindings[key]
      if value.is_a?(Symbol) && CONTROL_ACTION_ORDER.include?(value)
        bindings[key] = legacy[value] || legacy[key]
      elsif value.nil? || value.to_s.empty?
        bindings[key] = legacy[key]
      end
    end
  rescue
  end

  def control_action_data(action)
    action = action.to_sym if action.respond_to?(:to_sym)
    CONTROL_ACTIONS.find { |data| data[:id] == action } || CONTROL_ACTIONS[0]
  rescue
    CONTROL_ACTIONS[0]
  end

  def control_key_name(action)
    action = action.to_sym if action.respond_to?(:to_sym)
    value = control_bindings[action]
    value = control_action_data(action)[:default_key] if value.nil? || value.to_s.empty?
    value.to_s
  rescue
    control_action_data(action)[:default_key].to_s
  end

  def set_control_key_name(action, key_name)
    action = action.to_sym if action.respond_to?(:to_sym)
    return if !CONTROL_ACTION_ORDER.include?(action)
    key_name = key_name.to_s
    return if key_name.empty?
    control_bindings[action] = key_name
    @control_input_version = (@control_input_version || 0) + 1
  rescue
  end

  def control_action_label(action)
    _INTL(control_action_data(action)[:name].to_s)
  rescue
    action.to_s
  end

  def control_binding_label(action)
    key_name = control_key_name(action)
    if defined?(ControlHelpText) && ControlHelpText.respond_to?(:keyboard_display_key) && ControlHelpText.keyboard_key?(key_name)
      return ControlHelpText.keyboard_display_key(key_name).to_s
    end
    key_name
  rescue
    ""
  end

  def cycle_control_action(action, dir = 1)
    keys = control_picker_keys(control_key_kind(control_key_name(action)))
    return if keys.empty?
    current = control_key_name(action)
    index = keys.index(current) || 0
    set_control_key_name(action, keys[(index + dir.to_i) % keys.length])
  rescue
  end
  def control_action_description(action)
    _INTL(control_action_data(action)[:desc].to_s)
  rescue
    ""
  end

  def control_help_action(action)
    action = action.to_sym if action.respond_to?(:to_sym)
    case action
    when :confirm then :confirm
    when :cancel then :cancel
    when :action then :action
    when :ready_menu, :special, :menu then :menu
    when :zoom, :zoom_toggle, :zoom_in, :zoom_out then :zoom_toggle
    when :focus_step, :dash then :focus_step
    when :speed_down, :speed_up then action
    else nil
    end
  rescue
    nil
  end

  def control_help_key_name(action)
    mapped = control_help_action(action)
    return nil if !mapped
    control_key_name(mapped)
  rescue
    nil
  end

  def control_trigger?(action)
    control_key_triggered?(control_key_name(action))
  rescue
    false
  end

  def control_press?(action)
    control_key_pressed?(control_key_name(action))
  rescue
    false
  end

  def control_key_code(key_name)
    return nil if !defined?(Keys) || !Keys.respond_to?(:key_code)
    Keys.key_code(key_name.to_s)
  rescue
    nil
  end

  def control_key_triggered?(key_name)
    code = control_key_code(key_name)
    return false if code.nil?
    if defined?(Input::GAMEPAD_OFFSET) && code >= Input::GAMEPAD_OFFSET && (!defined?(Input::AXIS_OFFSET) || code < Input::AXIS_OFFSET)
      return false if !Input.const_defined?(:Controller)
      return Input::Controller.triggerex?(code - Input::GAMEPAD_OFFSET) rescue false
    elsif defined?(Input::AXIS_OFFSET) && code >= Input::AXIS_OFFSET
      return Input.axis_triggerex?(code - Input::AXIS_OFFSET) rescue false
    end
    Input.triggerex?(code) rescue false
  rescue
    false
  end

  def control_key_pressed?(key_name)
    code = control_key_code(key_name)
    return false if code.nil?
    if defined?(Input::GAMEPAD_OFFSET) && code >= Input::GAMEPAD_OFFSET && (!defined?(Input::AXIS_OFFSET) || code < Input::AXIS_OFFSET)
      return false if !Input.const_defined?(:Controller)
      return Input::Controller.pressex?(code - Input::GAMEPAD_OFFSET) rescue false
    elsif defined?(Input::AXIS_OFFSET) && code >= Input::AXIS_OFFSET
      return Input.axis_pressex?(code - Input::AXIS_OFFSET) rescue false
    end
    Input.pressex?(code) rescue false
  rescue
    false
  end

  def control_key_has_icon?(key_name)
    return false if key_name.nil? || key_name.to_s.empty?
    return true if !defined?(ControlHelpText) || !ControlHelpText.respond_to?(:icon_path_for_key)
    path = ControlHelpText.icon_path_for_key(key_name.to_s) rescue nil
    path && !path.to_s.empty?
  rescue
    false
  end

  def control_keyboard_keys
    return [] if !defined?(Keys) || !Keys.const_defined?(:KEYBOARD_LIST)
    Keys::KEYBOARD_LIST.keys.select do |name|
      name && !name.to_s.empty? && name.to_s != "None" && control_key_has_icon?(name)
    end
  rescue
    []
  end

  def control_gamepad_keys
    available = []
    available += Keys::GAMEPAD_LIST.keys if defined?(Keys) && Keys.const_defined?(:GAMEPAD_LIST)
    available += Keys::GAMEPAD_AXIS_LIST.keys if defined?(Keys) && Keys.const_defined?(:GAMEPAD_AXIS_LIST)
    allowed = CONTROL_GAMEPAD_KEYS.select { |name| available.include?(name) && control_key_has_icon?(name) }
    allowed.empty? ? CONTROL_GAMEPAD_KEYS.select { |name| control_key_has_icon?(name) } : allowed
  rescue
    CONTROL_GAMEPAD_KEYS.select { |name| control_key_has_icon?(name) }
  end

  def control_picker_keys(kind = :keyboard)
    kind == :gamepad ? control_gamepad_keys : control_keyboard_keys
  rescue
    []
  end

  def control_key_kind(key_name)
    return :gamepad if defined?(ControlHelpText) && ControlHelpText.respond_to?(:gamepad_key?) && ControlHelpText.gamepad_key?(key_name)
    :keyboard
  rescue
    :keyboard
  end

  def vibration_enabled?
    control_bindings[:vibration] == true
  rescue
    false
  end

  def set_vibration_enabled(value)
    control_bindings[:vibration] = value ? true : false
  rescue
  end

  def toggle_vibration_enabled
    set_vibration_enabled(!vibration_enabled?)
  rescue
  end

  def gamepad_vibrate(strength = 0.45, duration = 0.16)
    return false if !vibration_enabled?
    begin
      controller = Input.const_defined?(:Controller) ? Input::Controller : nil
      [:vibrate, :rumble, :set_vibration].each do |meth|
        next if !controller || !controller.respond_to?(meth)
        controller.send(meth, strength.to_f, duration.to_f)
        return true
      end
    rescue
    end
    false
  rescue
    false
  end
end

if defined?(ControlHelpText)
  module ControlHelpText
    class << self
      alias survivor_controls_original_key key unless method_defined?(:survivor_controls_original_key)
      def key(action)
        if defined?(PokemonSurvivor) && PokemonSurvivor.respond_to?(:control_help_key_name)
          mapped = PokemonSurvivor.control_help_key_name(action) rescue nil
          return mapped if mapped && !mapped.to_s.empty?
        end
        survivor_controls_original_key(action)
      end
    end
  end
end

class Scene_PokemonSurvivor
  def survivor_confirm_triggered?
    return PokemonSurvivor.control_trigger?(:confirm) if PokemonSurvivor.respond_to?(:control_trigger?)
    Input.trigger?(Input::USE) || Input.trigger?(Input::C)
  rescue
    false
  end

  def survivor_cancel_triggered?
    return PokemonSurvivor.control_trigger?(:cancel) if PokemonSurvivor.respond_to?(:control_trigger?)
    Input.trigger?(Input::BACK) || Input.trigger?(Input::B)
  rescue
    false
  end

  def open_control_options
    @state = :control_options
    @control_option_index ||= 0
    @control_picker_action = nil
    @control_picker_index = 0
    @control_picker_kind ||= :keyboard
    pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    draw_control_options
  rescue
  end

  def close_control_options
    @state = :perf_options
    @perf_option_index ||= 0
    @control_picker_action = nil
    pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
    draw_performance_options
  rescue
    @state = :select_menu
    draw_select_menu rescue nil
  end

  def update_control_options
    if @control_picker_action
      update_control_picker
      return
    end
    items = PokemonSurvivor::CONTROL_MENU_ITEMS
    old = @control_option_index.to_i
    @control_option_index = (@control_option_index.to_i - 1) % items.length if Input.repeat?(Input::UP)
    @control_option_index = (@control_option_index.to_i + 1) % items.length if Input.repeat?(Input::DOWN)
    pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil if old != @control_option_index.to_i
    item = items[@control_option_index.to_i]
    if survivor_confirm_triggered?
      if item == :vibration
        PokemonSurvivor.toggle_vibration_enabled
        pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
        PokemonSurvivor.gamepad_vibrate(0.55, 0.18) rescue nil
      else
        @control_picker_action = item
        @control_picker_kind = PokemonSurvivor.control_key_kind(PokemonSurvivor.control_key_name(item))
        keys = PokemonSurvivor.control_picker_keys(@control_picker_kind)
        current = PokemonSurvivor.control_key_name(item)
        @control_picker_index = [keys.index(current) || 0, keys.length - 1].min
        @control_picker_scroll = 0
        ensure_control_picker_scroll
        pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
      end
    elsif survivor_cancel_triggered?
      close_control_options
      return
    end
    draw_control_options
  rescue
    close_control_options
  end

  def control_picker_tab_triggered?
    return PokemonSurvivor.control_trigger?(:menu) if PokemonSurvivor.respond_to?(:control_trigger?)
    return true if Input.const_defined?(:SPECIAL) && Input.trigger?(Input::SPECIAL)
    return true if Input.const_defined?(:MENU) && Input.trigger?(Input::MENU)
    false
  rescue
    false
  end
  def update_control_picker
    keys = PokemonSurvivor.control_picker_keys(@control_picker_kind)
    return close_control_picker if keys.empty?
    cols = PokemonSurvivor::CONTROL_PICKER_COLUMNS
    old = @control_picker_index.to_i
    if control_picker_tab_triggered?
      switch_control_picker_kind
      return
    elsif Input.repeat?(Input::LEFT)
      @control_picker_index -= 1
    elsif Input.repeat?(Input::RIGHT)
      @control_picker_index += 1
    elsif Input.repeat?(Input::UP)
      @control_picker_index -= cols
    elsif Input.repeat?(Input::DOWN)
      @control_picker_index += cols
    elsif survivor_confirm_triggered?
      PokemonSurvivor.set_control_key_name(@control_picker_action, keys[@control_picker_index.to_i])
      close_control_picker(false)
      pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
      return
    elsif survivor_cancel_triggered?
      close_control_picker
      return
    end
    @control_picker_index = [[@control_picker_index.to_i, 0].max, keys.length - 1].min
    ensure_control_picker_scroll
    pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil if old != @control_picker_index.to_i
    draw_control_options
  rescue
    close_control_picker
  end

  def switch_control_picker_kind
    @control_picker_kind = @control_picker_kind == :keyboard ? :gamepad : :keyboard
    current = PokemonSurvivor.control_key_name(@control_picker_action)
    keys = PokemonSurvivor.control_picker_keys(@control_picker_kind)
    @control_picker_index = keys.index(current) || 0
    @control_picker_scroll = 0
    ensure_control_picker_scroll
    pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
    draw_control_options
  rescue
  end

  def close_control_picker(play_sound = true)
    @control_picker_action = nil
    pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil if play_sound
    draw_control_options
  rescue
  end

  def ensure_control_picker_scroll
    @control_picker_scroll ||= 0
    cols = PokemonSurvivor::CONTROL_PICKER_COLUMNS
    visible_rows = PokemonSurvivor::CONTROL_PICKER_VISIBLE_ROWS
    row = @control_picker_index.to_i / cols
    @control_picker_scroll = row if row < @control_picker_scroll.to_i
    bottom = @control_picker_scroll.to_i + visible_rows - 1
    @control_picker_scroll = row - visible_rows + 1 if row > bottom
    total_rows = (PokemonSurvivor.control_picker_keys(@control_picker_kind).length + cols - 1) / cols
    max_scroll = [total_rows - visible_rows, 0].max
    @control_picker_scroll = [[@control_picker_scroll.to_i, 0].max, max_scroll].min
  rescue
    @control_picker_scroll = 0
  end

  def control_option_label(item)
    return _INTL("Vibration") if item == :vibration
    PokemonSurvivor.control_action_label(item)
  rescue
    item.to_s
  end

  def control_option_value(item)
    return (PokemonSurvivor.vibration_enabled? ? _INTL("On") : _INTL("Off")) if item == :vibration
    PokemonSurvivor.control_binding_label(item)
  rescue
    ""
  end

  def draw_control_key_icon(bitmap, key_name, x, y)
    if defined?(ControlHelpText)
      path = ControlHelpText.icon_path_for_key(key_name) rescue nil
      if path
        icon = ControlHelpText.cached_icon_bitmap(path) rescue nil
        if icon && !icon.disposed?
          size = ControlHelpText::ICON_SIZE
          bitmap.blt(x, y, icon, Rect.new(0, 0, [icon.width, size].min, [icon.height, size].min))
          return size
        end
      end
      label = ControlHelpText.gamepad_key?(key_name) ? key_name.to_s : ControlHelpText.keyboard_display_key(key_name).to_s rescue key_name.to_s
    else
      label = key_name.to_s
    end
    draw_text_box(bitmap, label, x, y - 2, 44, 20, Color.white, Color.new(30, 30, 38), 2)
    44
  rescue
    16
  end

  def draw_control_options
    draw_select
    bmp = @sprites["screen"].bitmap
    over = @sprites["overlay"].bitmap
    over.clear
    draw_options_scrolling_background(bmp)
    w = [Graphics.width - 32, 560].min
    h = [Graphics.height - 70, 350].min
    x = (Graphics.width - w) / 2
    y = (Graphics.height - h) / 2
    draw_panel(bmp, x, y, w, h, Color.new(255, 196, 86), Color.new(18, 29, 50))
    draw_hud_header_strip(bmp, x + 14, y + 12, w - 28, 32, Color.new(255, 196, 86), Color.new(8, 13, 26))
    title = @control_picker_action ? _INTL("Choose Input") : _INTL("Controls")
    PokemonSurvivor.draw_text_center(bmp, title, x + 18, y + 23, w - 36, Color.new(255, 238, 160))
    if @control_picker_action
      draw_control_picker(bmp, x, y, w, h)
    else
      draw_control_binding_list(bmp, x, y, w, h)
    end
    help = @control_picker_action ? [[:up, ""], [:down, ""], [:left, ""], [:right, _INTL("Input")], [:ready_menu, _INTL("Keyboard/Gamepad")], [:confirm, _INTL("Assign")], [:cancel, _INTL("Back")]] : [[:up, ""], [:down, _INTL("Select")], [:confirm, _INTL("Open")], [:cancel, _INTL("Back")]]
    draw_help(over, help)
    draw_tv_filter(over)
  rescue
  end

  def draw_control_binding_list(bitmap, x, y, w, h)
    row_h = 46
    first_y = y + 62
    items = PokemonSurvivor::CONTROL_MENU_ITEMS
    palettes = {
      confirm: [Color.new(122, 255, 176), Color.new(24, 62, 44), Color.new(174, 255, 208)],
      cancel: [Color.new(255, 142, 132), Color.new(70, 34, 42), Color.new(255, 184, 174)],
      action: [Color.new(255, 196, 86), Color.new(70, 46, 24), Color.new(255, 232, 140)],
      menu: [Color.new(92, 188, 255), Color.new(24, 54, 82), Color.new(154, 220, 255)],
      zoom_toggle: [Color.new(96, 232, 214), Color.new(20, 62, 68), Color.new(164, 255, 244)],
      focus_step: [Color.new(255, 156, 72), Color.new(86, 42, 20), Color.new(255, 212, 126)],
      vibration: [Color.new(184, 104, 255), Color.new(54, 34, 82), Color.new(222, 176, 255)]
    }
    items.each_with_index do |item, i|
      row_y = first_y + (i * row_h)
      selected = i == @control_option_index.to_i
      edge, fill, shine = palettes[item] || palettes[:menu]
      fill = Color.new([fill.red + 34, 255].min, [fill.green + 34, 255].min, [fill.blue + 34, 255].min) if selected
      shine = Color.new([shine.red + 22, 255].min, [shine.green + 22, 255].min, [shine.blue + 22, 255].min) if selected
      draw_modern_button_frame(bitmap, x + 20, row_y, w - 40, 39, edge, fill, shine, selected)
      draw_text_box(bitmap, control_option_label(item), x + 34, row_y + 9, w - 170, 20, Color.new(226, 232, 244), Color.new(30, 30, 38), 0)
      if item == :vibration
        draw_text_box(bitmap, control_option_value(item), x + w - 128, row_y + 9, 92, 20, shine, Color.new(30, 30, 38), 2)
      else
        icon_size = defined?(ControlHelpText) ? ControlHelpText::ICON_SIZE : 16
        key_name = PokemonSurvivor.control_key_name(item)
        draw_control_key_icon(bitmap, key_name, x + w - 74, row_y + ((39 - icon_size) / 2))
      end
    end
  rescue
  end

  def draw_control_picker(bitmap, x, y, w, h)
    action = @control_picker_action
    selected_name = PokemonSurvivor.control_action_label(action)
    kind_label = @control_picker_kind == :gamepad ? _INTL("Gamepad") : _INTL("Keyboard")
    draw_text_box(bitmap, _INTL("{1} - {2}", selected_name, kind_label), x + 28, y + 54, w - 56, 22, Color.new(226, 232, 244), Color.new(30, 30, 38), 2)
    keys = PokemonSurvivor.control_picker_keys(@control_picker_kind)
    cols = PokemonSurvivor::CONTROL_PICKER_COLUMNS
    visible_rows = PokemonSurvivor::CONTROL_PICKER_VISIBLE_ROWS
    cell_w = (w - 78) / cols
    cell_h = 56
    start_x = x + 28
    start_y = y + 84
    ensure_control_picker_scroll
    first = @control_picker_scroll.to_i * cols
    last = [first + (visible_rows * cols), keys.length].min
    palettes[:speed_down] = [Color.new(236, 164, 212), Color.new(68, 34, 60), Color.new(255, 210, 238)]
    palettes[:speed_up] = [Color.new(212, 236, 110), Color.new(50, 62, 24), Color.new(240, 255, 174)]
    first.upto(last - 1) do |i|
      key_name = keys[i]
      local = i - first
      cx = start_x + ((local % cols) * cell_w)
      cy = start_y + ((local / cols) * cell_h)
      selected = i == @control_picker_index.to_i
      current = PokemonSurvivor.control_key_name(action) == key_name
      edge = selected ? Color.new(255, 238, 160) : (current ? Color.new(122, 255, 176) : Color.new(92, 188, 255))
      fill = selected ? Color.new(62, 48, 24) : (current ? Color.new(20, 56, 42) : Color.new(18, 34, 58))
      shine = selected ? Color.new(255, 232, 140) : (current ? Color.new(174, 255, 208) : Color.new(154, 220, 255))
      draw_modern_button_frame(bitmap, cx, cy, cell_w - 8, 46, edge, fill, shine, selected)
      icon_size = defined?(ControlHelpText) ? ControlHelpText::ICON_SIZE : 16
      draw_control_key_icon(bitmap, key_name, cx + ((cell_w - 8 - icon_size) / 2), cy + ((46 - icon_size) / 2))
    end
    if keys.length > visible_rows * cols
      bar_x = x + w - 22
      bar_y = start_y
      bar_h = (visible_rows * cell_h) - 10
      total_rows = (keys.length + cols - 1) / cols
      thumb_h = [[(bar_h * visible_rows / total_rows).round, 18].max, bar_h].min
      max_scroll = [total_rows - visible_rows, 1].max
      thumb_y = bar_y + ((bar_h - thumb_h) * @control_picker_scroll.to_i / max_scroll)
      draw_select_scrollbar(bitmap, bar_x, bar_y, 7, bar_h, thumb_y, thumb_h)
    end
    desc = PokemonSurvivor.control_action_description(action)
    draw_soft_badge(bitmap, x + 28, y + h - 72, w - 56, 34, Color.new(8, 13, 26, 210))
    draw_text_box(bitmap, desc, x + 40, y + h - 63, w - 80, 20, Color.new(198, 214, 236), Color.new(30, 30, 38), 2)
  rescue
  end
end
# Keep keyboard and gamepad bindings active at the same time.
module PokemonSurvivor
  CONTROL_DEFAULT_KEYS = {
    confirm: { keyboard: "C", gamepad: "Button A" },
    cancel: { keyboard: "X", gamepad: "Button B" },
    action: { keyboard: "Z", gamepad: "Button X" },
    menu: { keyboard: "D", gamepad: "Button Y" },
    zoom_toggle: { keyboard: "R", gamepad: "Right Shoulder" },
    focus_step: { keyboard: "A", gamepad: "Left Shoulder" },
    speed_down: { keyboard: "F", gamepad: "Left Trigger" },
    speed_up: { keyboard: "G", gamepad: "Right Trigger" }
  }

  module_function

  def default_control_bindings
    hash = { vibration: false }
    CONTROL_DEFAULT_KEYS.each_pair { |action, data| hash[action] = data.dup }
    hash
  end

  def normalize_legacy_control_bindings(bindings)
    return if !bindings.is_a?(Hash)
    legacy = { confirm: "C", cancel: "X", action: "Z", menu: "D", zoom_toggle: "R", focus_step: "A" }
    CONTROL_ACTION_ORDER.each do |action|
      defaults = CONTROL_DEFAULT_KEYS[action] || { keyboard: legacy[action], gamepad: nil }
      value = bindings[action]
      if value.is_a?(Hash)
        value[:keyboard] ||= value["keyboard"] || defaults[:keyboard]
        value[:gamepad] ||= value["gamepad"] || defaults[:gamepad]
        bindings[action] = { keyboard: value[:keyboard].to_s, gamepad: value[:gamepad].to_s }
      elsif value.is_a?(Symbol) && CONTROL_ACTION_ORDER.include?(value)
        bindings[action] = defaults.dup
      elsif value && !value.to_s.empty?
        kind = control_key_kind(value.to_s)
        bindings[action] = defaults.dup
        bindings[action][kind] = value.to_s
      else
        bindings[action] = defaults.dup
      end
    end
  rescue
  end

  def control_key_name(action, kind = nil)
    action = action.to_sym if action.respond_to?(:to_sym)
    normalize_legacy_control_bindings(control_bindings)
    data = control_bindings[action]
    defaults = CONTROL_DEFAULT_KEYS[action] || { keyboard: "C", gamepad: "Button A" }
    if kind.nil?
      kind = :keyboard
      kind = :gamepad if defined?(ControlHelpText) && ControlHelpText.respond_to?(:last_input_type) && ControlHelpText.last_input_type == :gamepad
    end
    kind = kind.to_sym if kind.respond_to?(:to_sym)
    value = data.is_a?(Hash) ? (data[kind] || data[kind.to_s]) : data
    value = defaults[kind] if value.nil? || value.to_s.empty?
    value.to_s
  rescue
    "C"
  end

  def set_control_key_name(action, key_name, kind = nil)
    action = action.to_sym if action.respond_to?(:to_sym)
    return if !CONTROL_ACTION_ORDER.include?(action)
    key_name = key_name.to_s
    return if key_name.empty?
    kind ||= control_key_kind(key_name)
    kind = kind.to_sym if kind.respond_to?(:to_sym)
    bindings = control_bindings
    normalize_legacy_control_bindings(bindings)
    bindings[action] = (CONTROL_DEFAULT_KEYS[action] || {}).dup if !bindings[action].is_a?(Hash)
    old_key = control_key_name(action, kind)
    other = CONTROL_ACTION_ORDER.find do |other_action|
      other_action != action && control_key_name(other_action, kind).to_s == key_name
    end
    if other
      bindings[other] = (CONTROL_DEFAULT_KEYS[other] || {}).dup if !bindings[other].is_a?(Hash)
      bindings[other][kind] = old_key
    end
    bindings[action][kind] = key_name
    @control_input_version = (@control_input_version || 0) + 1
  rescue
  end

  def control_binding_label(action)
    control_key_name(action)
  rescue
    ""
  end

  def control_help_key_name(action)
    mapped = control_help_action(action)
    return nil if !mapped
    control_key_name(mapped)
  rescue
    nil
  end

  def control_trigger?(action)
    return true if action == :confirm && CONTROL_FIXED_CONFIRM_KEYS.any? { |key| control_key_triggered?(key) }
    control_key_triggered?(control_key_name(action, :keyboard)) || control_key_triggered?(control_key_name(action, :gamepad))
  rescue
    false
  end

  def control_press?(action)
    return true if action == :confirm && CONTROL_FIXED_CONFIRM_KEYS.any? { |key| control_key_pressed?(key) }
    control_key_pressed?(control_key_name(action, :keyboard)) || control_key_pressed?(control_key_name(action, :gamepad))
  rescue
    false
  end

  def control_key_triggered?(key_name)
    code = control_key_code(key_name)
    return false if code.nil?
    begin
      return true if Input.triggerex?(code)
    rescue
    end
    if defined?(Input::GAMEPAD_OFFSET) && code >= Input::GAMEPAD_OFFSET && (!defined?(Input::AXIS_OFFSET) || code < Input::AXIS_OFFSET)
      begin
        return true if Input.const_defined?(:Controller) && Input::Controller.triggerex?(code - Input::GAMEPAD_OFFSET)
      rescue
      end
    elsif defined?(Input::AXIS_OFFSET) && code >= Input::AXIS_OFFSET
      begin
        return true if Input.axis_triggerex?(code - Input::AXIS_OFFSET)
      rescue
      end
    end
    false
  rescue
    false
  end

  def control_key_pressed?(key_name)
    code = control_key_code(key_name)
    return false if code.nil?
    begin
      return true if Input.pressex?(code)
    rescue
    end
    if defined?(Input::GAMEPAD_OFFSET) && code >= Input::GAMEPAD_OFFSET && (!defined?(Input::AXIS_OFFSET) || code < Input::AXIS_OFFSET)
      begin
        return true if Input.const_defined?(:Controller) && Input::Controller.pressex?(code - Input::GAMEPAD_OFFSET)
      rescue
      end
    elsif defined?(Input::AXIS_OFFSET) && code >= Input::AXIS_OFFSET
      begin
        return true if Input.axis_pressex?(code - Input::AXIS_OFFSET)
      rescue
      end
    end
    false
  rescue
    false
  end
end

class Scene_PokemonSurvivor
  def draw_control_binding_list(bitmap, x, y, w, h)
    row_h = 46
    first_y = y + 62
    items = PokemonSurvivor::CONTROL_MENU_ITEMS
    palettes = {
      confirm: [Color.new(122, 255, 176), Color.new(24, 62, 44), Color.new(174, 255, 208)],
      cancel: [Color.new(255, 142, 132), Color.new(70, 34, 42), Color.new(255, 184, 174)],
      action: [Color.new(255, 196, 86), Color.new(70, 46, 24), Color.new(255, 232, 140)],
      menu: [Color.new(92, 188, 255), Color.new(24, 54, 82), Color.new(154, 220, 255)],
      zoom_toggle: [Color.new(96, 232, 214), Color.new(20, 62, 68), Color.new(164, 255, 244)],
      focus_step: [Color.new(255, 156, 72), Color.new(86, 42, 20), Color.new(255, 212, 126)],
      vibration: [Color.new(184, 104, 255), Color.new(54, 34, 82), Color.new(222, 176, 255)]
    }
    items.each_with_index do |item, i|
      row_y = first_y + (i * row_h)
      selected = i == @control_option_index.to_i
      edge, fill, shine = palettes[item] || palettes[:menu]
      fill = Color.new([fill.red + 34, 255].min, [fill.green + 34, 255].min, [fill.blue + 34, 255].min) if selected
      shine = Color.new([shine.red + 22, 255].min, [shine.green + 22, 255].min, [shine.blue + 22, 255].min) if selected
      draw_modern_button_frame(bitmap, x + 20, row_y, w - 40, 39, edge, fill, shine, selected)
      draw_text_box(bitmap, control_option_label(item), x + 34, row_y + 9, w - 188, 20, Color.new(226, 232, 244), Color.new(30, 30, 38), 0)
      if item == :vibration
        draw_text_box(bitmap, control_option_value(item), x + w - 128, row_y + 9, 92, 20, shine, Color.new(30, 30, 38), 2)
      else
        icon_size = defined?(ControlHelpText) ? ControlHelpText::ICON_SIZE : 16
        keyboard_key = PokemonSurvivor.control_key_name(item, :keyboard)
        gamepad_key = PokemonSurvivor.control_key_name(item, :gamepad)
        draw_control_key_icon(bitmap, keyboard_key, x + w - 104, row_y + ((39 - icon_size) / 2))
        draw_control_key_icon(bitmap, gamepad_key, x + w - 70, row_y + ((39 - icon_size) / 2))
      end
    end
  rescue
  end
end

# Keep all Survivor helper icons synchronized with the custom remap.
module PokemonSurvivor
  module_function

  def control_current_input_kind
    if defined?(ControlHelpText) && ControlHelpText.respond_to?(:last_input_type)
      return :gamepad if ControlHelpText.last_input_type == :gamepad
    end
    :keyboard
  rescue
    :keyboard
  end

  def control_help_key_name(action)
    mapped = control_help_action(action)
    return nil if !mapped
    control_key_name(mapped, control_current_input_kind)
  rescue
    nil
  end

  def set_control_key_name(action, key_name, kind = nil)
    action = action.to_sym if action.respond_to?(:to_sym)
    return if !CONTROL_ACTION_ORDER.include?(action)
    key_name = key_name.to_s
    return if key_name.empty?
    kind ||= control_key_kind(key_name)
    kind = kind.to_sym if kind.respond_to?(:to_sym)
    bindings = control_bindings
    normalize_legacy_control_bindings(bindings)
    bindings[action] = (CONTROL_DEFAULT_KEYS[action] || {}).dup if !bindings[action].is_a?(Hash)
    old_key = control_key_name(action, kind)
    other = CONTROL_ACTION_ORDER.find do |other_action|
      other_action != action && control_key_name(other_action, kind).to_s == key_name
    end
    if other
      bindings[other] = (CONTROL_DEFAULT_KEYS[other] || {}).dup if !bindings[other].is_a?(Hash)
      bindings[other][kind] = old_key
    end
    bindings[action][kind] = key_name
    if defined?(ControlHelpText)
      ControlHelpText.set_last_input_type(kind) if ControlHelpText.respond_to?(:set_last_input_type)
      if ControlHelpText.respond_to?(:input_version)
        ControlHelpText.instance_variable_set(:@input_version, ControlHelpText.input_version.to_i + 1) rescue nil
      end
    end
    @control_input_version = (@control_input_version || 0) + 1
  rescue
  end
end

if defined?(ControlHelpText)
  module ControlHelpText
    class << self
      alias survivor_controls_original_keys_for keys_for unless method_defined?(:survivor_controls_original_keys_for)
      def keys_for(action)
        if defined?(PokemonSurvivor) && PokemonSurvivor.respond_to?(:control_help_key_name)
          key_name = PokemonSurvivor.control_help_key_name(action) rescue nil
          return [key_name] if key_name && !key_name.to_s.empty?
        end
        survivor_controls_original_keys_for(action)
      end

      def key(action)
        keys = keys_for(action)
        preferred = preferred_key(keys)
        preferred || action.to_s
      rescue
        survivor_controls_original_key(action) rescue action.to_s
      end

      def icon_path(action)
        icon_path_for_key(key(action))
      rescue
        nil
      end
    end
  end
end
# Keyboard arrows stay reserved for menu/run navigation and cannot be assigned.
module PokemonSurvivor
  CONTROL_RESERVED_KEYBOARD_KEYS = ["Up", "Down", "Left", "Right", "Arrow Up", "Arrow Down", "Arrow Left", "Arrow Right", "Ctrl", "Control", "Left Ctrl", "Right Ctrl", "Shift", "Left Shift", "Right Shift", "Alt", "Left Alt", "Right Alt", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "Print Screen", "Pause", "Break"]

  module_function

  def control_fixed_confirm_key?(key_name)
    CONTROL_FIXED_CONFIRM_KEYS.include?(key_name.to_s) || [0x0D, 0x20].include?(control_key_code(key_name))
  end

  def control_reserved_keyboard_key?(key_name)
    CONTROL_RESERVED_KEYBOARD_KEYS.include?(key_name.to_s) || control_fixed_confirm_key?(key_name)
  rescue
    false
  end

  def control_keyboard_keys
    return [] if !defined?(Keys) || !Keys.const_defined?(:KEYBOARD_LIST)
    Keys::KEYBOARD_LIST.keys.select do |name|
      name && !name.to_s.empty? && name.to_s != "None" && !control_reserved_keyboard_key?(name) && control_key_has_icon?(name)
    end
  rescue
    []
  end
end
# Final draw-time bridge: helpers resolve Survivor actions to the current remapped icon.
if defined?(ControlHelpText)
  module ControlHelpText
    class << self
      alias survivor_controls_original_draw_icon draw_icon unless method_defined?(:survivor_controls_original_draw_icon)
      def draw_icon(bitmap, action, x, y)
        key_name = nil
        if defined?(PokemonSurvivor) && PokemonSurvivor.respond_to?(:control_help_key_name)
          key_name = PokemonSurvivor.control_help_key_name(action) rescue nil
        end
        return survivor_controls_original_draw_icon(bitmap, action, x, y) if !key_name || key_name.to_s.empty?
        path = icon_path_for_key(key_name)
        if path
          icon = cached_icon_bitmap(path)
          if icon && !icon.disposed?
            src_w = [icon.width, ICON_SIZE].min
            src_h = [icon.height, ICON_SIZE].min
            bitmap.blt(x, y, icon, Rect.new(0, 0, src_w, src_h))
            return ICON_SIZE
          end
        end
        display_key = gamepad_key?(key_name) ? key_name.to_s : keyboard_display_key(key_name).to_s
        pbDrawTextPositions(bitmap, [[display_key, x, y - 2, 0, Color.white, Color.new(0, 0, 0)]])
        return bitmap.text_size(display_key).width rescue ICON_SIZE
      rescue
        survivor_controls_original_draw_icon(bitmap, action, x, y) rescue ICON_SIZE
      end
    end
  end
end
# Also mirror the remap into the native helper action table for older callers.
module PokemonSurvivor
  module_function

  def sync_control_help_actions!
    return if !defined?(ControlHelpText) || !ControlHelpText.const_defined?(:ACTIONS)
    actions = ControlHelpText::ACTIONS
    map = {
      confirm: [:confirm],
      cancel: [:cancel],
      action: [:action],
      menu: [:menu],
      ready_menu: [:menu],
      special: [:menu],
      focus_step: [:focus_step]
    }
    map.each_pair do |helper_action, survivor_actions|
      survivor_action = survivor_actions[0]
      next if !actions[helper_action]
      keyboard_key = control_key_name(survivor_action, :keyboard)
      actions[helper_action][1] = keyboard_key if keyboard_key && !keyboard_key.empty?
    end
  rescue
  end

  def set_control_key_name(action, key_name, kind = nil)
    action = action.to_sym if action.respond_to?(:to_sym)
    return if !CONTROL_ACTION_ORDER.include?(action)
    key_name = key_name.to_s
    return if key_name.empty?
    kind ||= control_key_kind(key_name)
    kind = kind.to_sym if kind.respond_to?(:to_sym)
    bindings = control_bindings
    normalize_legacy_control_bindings(bindings)
    bindings[action] = (CONTROL_DEFAULT_KEYS[action] || {}).dup if !bindings[action].is_a?(Hash)
    old_key = control_key_name(action, kind)
    other = CONTROL_ACTION_ORDER.find do |other_action|
      other_action != action && control_key_name(other_action, kind).to_s == key_name
    end
    if other
      bindings[other] = (CONTROL_DEFAULT_KEYS[other] || {}).dup if !bindings[other].is_a?(Hash)
      bindings[other][kind] = old_key
    end
    bindings[action][kind] = key_name
    sync_control_help_actions!
    if defined?(ControlHelpText)
      ControlHelpText.set_last_input_type(kind) if ControlHelpText.respond_to?(:set_last_input_type)
      if ControlHelpText.respond_to?(:input_version)
        ControlHelpText.instance_variable_set(:@input_version, ControlHelpText.input_version.to_i + 1) rescue nil
      end
    end
    @control_input_version = (@control_input_version || 0) + 1
  rescue
  end
end

PokemonSurvivor.sync_control_help_actions! if defined?(PokemonSurvivor) && PokemonSurvivor.respond_to?(:sync_control_help_actions!)
# Robust save migration + helper rendering for remapped controls.
module PokemonSurvivor
  module_function

  def normalize_legacy_control_bindings(bindings)
    return if !bindings.is_a?(Hash)
    legacy = { confirm: "C", cancel: "X", action: "Z", menu: "D", zoom_toggle: "R", focus_step: "A" }
    CONTROL_ACTION_ORDER.each do |action|
      defaults = CONTROL_DEFAULT_KEYS[action] || { keyboard: legacy[action], gamepad: nil }
      value = bindings[action]
      value = bindings[action.to_s] if value.nil? && bindings.key?(action.to_s)
      if value.is_a?(Hash)
        keyboard = value[:keyboard] || value["keyboard"] || defaults[:keyboard]
        gamepad = value[:gamepad] || value["gamepad"] || defaults[:gamepad]
        bindings[action] = { keyboard: keyboard.to_s, gamepad: gamepad.to_s }
      elsif value.is_a?(Symbol) && CONTROL_ACTION_ORDER.include?(value)
        bindings[action] = defaults.dup
      elsif value && !value.to_s.empty?
        kind = control_key_kind(value.to_s)
        bindings[action] = defaults.dup
        bindings[action][kind] = value.to_s
      else
        bindings[action] = defaults.dup
      end
      bindings.delete(action.to_s) if bindings.key?(action.to_s)
    end
    # Preserve unrelated bindings when retiring an old Enter/Space assignment.
    CONTROL_ACTION_ORDER.each do |action|
      next unless control_fixed_confirm_key?(bindings[action][:keyboard])
      used = CONTROL_ACTION_ORDER.map { |id| bindings[id][:keyboard] }
      defaults = CONTROL_DEFAULT_KEYS.values.map { |keys| keys[:keyboard] }
      candidates = [CONTROL_DEFAULT_KEYS[action][:keyboard]] + defaults
      replacement = candidates.find { |key| !used.include?(key) }
      bindings[action][:keyboard] = replacement if replacement
    end
    # New speed controls must not duplicate a trigger/key already used by a save.
    [:keyboard, :gamepad].each do |kind|
      used = CONTROL_ACTION_ORDER.reject { |id| [:speed_down, :speed_up].include?(id) }.map { |id| bindings[id][kind] }
      [:speed_down, :speed_up].each do |id|
        key = bindings[id][kind]
        if used.include?(key)
          candidates = CONTROL_DEFAULT_KEYS.values.map { |data| data[kind] }
          candidates += CONTROL_GAMEPAD_KEYS if kind == :gamepad
          key = candidates.find { |candidate| !used.include?(candidate) } || key
          bindings[id][kind] = key
        end
        used << key
      end
    end
  rescue
  end

  def control_key_name(action, kind = nil)
    action = action.to_sym if action.respond_to?(:to_sym)
    bindings = control_bindings
    normalize_legacy_control_bindings(bindings)
    data = bindings[action] || bindings[action.to_s]
    defaults = CONTROL_DEFAULT_KEYS[action] || { keyboard: "C", gamepad: "Button A" }
    kind ||= control_current_input_kind
    kind = kind.to_sym if kind.respond_to?(:to_sym)
    value = data.is_a?(Hash) ? (data[kind] || data[kind.to_s]) : data
    value = defaults[kind] if value.nil? || value.to_s.empty?
    value.to_s
  rescue
    "C"
  end
end

if defined?(ControlHelpText)
  module ControlHelpText
    class << self
      def survivor_resolved_key(action)
        if defined?(PokemonSurvivor) && PokemonSurvivor.respond_to?(:control_help_key_name)
          key_name = PokemonSurvivor.control_help_key_name(action) rescue nil
          return key_name if key_name && !key_name.to_s.empty?
        end
        key(action)
      rescue
        action.to_s
      end

      def segment_width(bitmap, action, label = nil)
        label = label.to_s
        key_name = survivor_resolved_key(action)
        text_w = label.empty? ? 0 : (bitmap.text_size(label).width rescue 0)
        icon_w = ICON_SIZE
        if key_name && icon_path_for_key(key_name).nil?
          display_key = gamepad_key?(key_name) ? key_name.to_s : keyboard_display_key(key_name).to_s
          icon_w = bitmap.text_size(display_key).width rescue ICON_SIZE
        end
        return icon_w + (label.empty? ? 0 : ICON_TEXT_GAP + text_w)
      rescue
        ICON_SIZE
      end

      def draw_segments_raw(bitmap, segments, draw_x, y, base, shadow)
        segments.each_with_index do |segment, i|
          action = segment[0]
          label = segment[1].to_s
          icon_y = y + 1
          icon_w = draw_icon(bitmap, action, draw_x, icon_y)
          draw_x += [icon_w.to_i, ICON_SIZE].max
          if !label.empty?
            draw_x += ICON_TEXT_GAP
            pbDrawTextPositions(bitmap, [[label, draw_x, y, 0, base, shadow]])
            draw_x += bitmap.text_size(label).width rescue 0
          end
          draw_x += (label.empty? ? 3 : SEGMENT_GAP) if i < segments.length - 1
        end
      rescue
      end
    end
  end
end
# Persistent controls storage. Remaps are global user preferences, so they are
# saved immediately and reloaded after game restart or F12 soft reset.
module PokemonSurvivor
  CONTROL_CONFIG_FILE = "SurvivorControls.rxdata"

  module_function


  def save_control_config
    data = (load_control_config || {}).dup
    data[:control_bindings] = control_bindings
    data[:survivor_options] = persistent_survivor_options_snapshot if respond_to?(:persistent_survivor_options_snapshot)
    data[:version] = 2
    path = control_config_path
    dir = File.dirname(path) rescue nil
    Dir.mkdir(dir) if dir && !dir.empty? && !FileTest.directory?(dir) rescue nil
    File.open(path, "wb") { |file| Marshal.dump(data, file) }
    @control_config_data = data
    @control_config_loaded = true
    true
  rescue
    false
  end

  def control_bindings
    opts = performance_options rescue nil
    if opts
      stored = load_control_config
      if stored.is_a?(Hash) && stored[:control_bindings].is_a?(Hash) && !opts[:control_bindings_loaded]
        opts[:control_bindings] = stored[:control_bindings]
        opts[:control_bindings_loaded] = true
      end
      opts[:control_bindings] = default_control_bindings if !opts[:control_bindings].is_a?(Hash)
      normalize_legacy_control_bindings(opts[:control_bindings])
      return opts[:control_bindings]
    end
    stored = load_control_config
    if stored.is_a?(Hash) && stored[:control_bindings].is_a?(Hash)
      $PokemonSurvivorControlBindings = stored[:control_bindings]
    end
    $PokemonSurvivorControlBindings ||= default_control_bindings.dup
    normalize_legacy_control_bindings($PokemonSurvivorControlBindings)
    $PokemonSurvivorControlBindings
  rescue
    default_control_bindings.dup
  end

  def set_control_key_name(action, key_name, kind = nil)
    action = action.to_sym if action.respond_to?(:to_sym)
    return if !CONTROL_ACTION_ORDER.include?(action)
    key_name = key_name.to_s
    return if key_name.empty?
    kind ||= control_key_kind(key_name)
    kind = kind.to_sym if kind.respond_to?(:to_sym)
    bindings = control_bindings
    normalize_legacy_control_bindings(bindings)
    bindings[action] = (CONTROL_DEFAULT_KEYS[action] || {}).dup if !bindings[action].is_a?(Hash)
    old_key = control_key_name(action, kind)
    other = CONTROL_ACTION_ORDER.find do |other_action|
      other_action != action && control_key_name(other_action, kind).to_s == key_name
    end
    if other
      bindings[other] = (CONTROL_DEFAULT_KEYS[other] || {}).dup if !bindings[other].is_a?(Hash)
      bindings[other][kind] = old_key
    end
    return if control_fixed_confirm_key?(key_name)
    bindings[action][kind] = key_name
    sync_control_help_actions! if respond_to?(:sync_control_help_actions!)
    save_control_config
    if defined?(ControlHelpText)
      ControlHelpText.set_last_input_type(kind) if ControlHelpText.respond_to?(:set_last_input_type)
      if ControlHelpText.respond_to?(:input_version)
        ControlHelpText.instance_variable_set(:@input_version, ControlHelpText.input_version.to_i + 1) rescue nil
      end
    end
    @control_input_version = (@control_input_version || 0) + 1
  rescue
  end

  def set_vibration_enabled(value)
    control_bindings[:vibration] = value ? true : false
    save_control_config
  rescue
  end
end
# Store controls outside Data to avoid Essentials recompilation prompts.
module PokemonSurvivor
  module_function

  def control_config_path
    if defined?(RTP) && RTP.respond_to?(:getSaveFileName)
      return RTP.getSaveFileName(CONTROL_CONFIG_FILE)
    end
    save_path = ""
    save_path = SaveData::FILE_PATH.to_s if defined?(SaveData) && SaveData.const_defined?(:FILE_PATH)
    dir = save_path.to_s.empty? ? "" : File.dirname(save_path)
    if dir.to_s.empty? || !FileTest.directory?(dir)
      base = ENV["APPDATA"].to_s rescue ""
      dir = File.join(base, "Pokemon Survivors Burst") if !base.empty?
    end
    dir = "." if dir.to_s.empty?
    File.join(dir, CONTROL_CONFIG_FILE)
  rescue
    CONTROL_CONFIG_FILE
  end

  def migrate_old_control_config
    return if @old_control_config_migrated
    @old_control_config_migrated = true
    old_path = File.join("Data", CONTROL_CONFIG_FILE)
    new_path = control_config_path
    return if !FileTest.exist?(old_path)
    return if FileTest.exist?(new_path)
    raw = File.open(old_path, "rb") { |file| file.read }
    dir = File.dirname(new_path) rescue nil
    Dir.mkdir(dir) if dir && !dir.empty? && !FileTest.directory?(dir) rescue nil
    File.open(new_path, "wb") { |file| file.write(raw) }
  rescue
  end

  def load_control_config
    return @control_config_data if @control_config_loaded
    @control_config_loaded = true
    migrate_old_control_config
    path = control_config_path
    @control_config_data = nil
    @control_config_data = File.open(path, "rb") { |file| Marshal.load(file) } if FileTest.exist?(path)
    @control_config_data
  rescue
    @control_config_data = nil
  end

  def persistent_survivor_options_snapshot
    opts = ($PokemonSurvivorPerformanceOptions || DEFAULT_PERFORMANCE_OPTIONS.dup).dup rescue {}
    opts.delete(:control_bindings)
    opts.delete(:control_bindings_loaded)
    opts.delete(:persistent_options_loaded)
    {
      performance_options: opts,
      screen_size_index: screen_size_index,
      bgm_volume: bgm_volume,
      se_volume: se_volume
    }
  rescue
    {}
  end

  def normalize_persistent_performance_options(opts)
    result = DEFAULT_PERFORMANCE_OPTIONS.dup
    return result if !opts.is_a?(Hash)
    opts.each_pair do |key, value|
      key = key.to_sym if key.respond_to?(:to_sym)
      next if !result.key?(key)
      if key == :color_accessibility
        result[key] = normalize_color_accessibility(value)
      elsif key == :auto_bonus
        value = value.to_sym if value.respond_to?(:to_sym)
        result[key] = AUTO_BONUS_MODES.include?(value) ? value : :semi_auto
      elsif key == :run_info_panel
        value = value.to_sym if value.respond_to?(:to_sym)
        value = :stats if !RUN_INFO_PANEL_MODES.include?(value)
        result[key] = value
      else
        result[key] = value ? true : false
      end
    end
    result
  rescue
    DEFAULT_PERFORMANCE_OPTIONS.dup
  end

  def apply_persistent_survivor_options(data)
    return false if !data.is_a?(Hash)
    opts = normalize_persistent_performance_options(data[:performance_options] || data["performance_options"])
    opts[:persistent_options_loaded] = true
    $PokemonSurvivorPerformanceOptions = opts
    system = ensure_pokemon_system
    if system
      screen = data[:screen_size_index] || data["screen_size_index"]
      bgm = data[:bgm_volume] || data["bgm_volume"]
      se = data[:se_volume] || data["se_volume"]
      if !screen.nil?
        screen = [[screen.to_i, 0].max, SCREEN_SIZE_LABELS.length - 1].min
        system.screensize = screen
        pbSetResizeFactor(screen) if defined?(pbSetResizeFactor)
      end
      system.bgmvolume = [[bgm.to_i, 0].max, 100].min if !bgm.nil?
      system.sevolume = [[se.to_i, 0].max, 100].min if !se.nil?
    end
    true
  rescue
    false
  end

  def load_persistent_survivor_options(force = false)
    opts = $PokemonSurvivorPerformanceOptions
    return true if !force && opts.is_a?(Hash) && opts[:persistent_options_loaded]
    data = load_control_config
    if data.is_a?(Hash) && (data[:survivor_options] || data["survivor_options"])
      apply_persistent_survivor_options(data[:survivor_options] || data["survivor_options"])
    else
      $PokemonSurvivorPerformanceOptions ||= DEFAULT_PERFORMANCE_OPTIONS.dup
      $PokemonSurvivorPerformanceOptions[:persistent_options_loaded] = true
      true
    end
  rescue
    false
  end

  def save_persistent_survivor_options
    data = (load_control_config || {}).dup
    data[:control_bindings] = control_bindings if respond_to?(:control_bindings)
    data[:survivor_options] = persistent_survivor_options_snapshot
    data[:version] = 2
    path = control_config_path
    dir = File.dirname(path) rescue nil
    Dir.mkdir(dir) if dir && !dir.empty? && !FileTest.directory?(dir) rescue nil
    File.open(path, "wb") { |file| Marshal.dump(data, file) }
    @control_config_data = data
    @control_config_loaded = true
    true
  rescue
    false
  end
end


#===============================================================================
# Pokemon Survivor - native gamepad vibration backend
#===============================================================================
module PokemonSurvivor
  module_function

  GAMEPAD_VIBRATION_DLLS = ["xinput1_4", "xinput1_3", "xinput9_1_0", "xinput1_2", "xinput1_1"] unless const_defined?(:GAMEPAD_VIBRATION_DLLS)
  GAMEPAD_VIBRATION_MIN_INTERVAL = 0.08 unless const_defined?(:GAMEPAD_VIBRATION_MIN_INTERVAL)

  def gamepad_vibration_api
    return @gamepad_vibration_api if defined?(@gamepad_vibration_api_checked) && @gamepad_vibration_api_checked
    @gamepad_vibration_api_checked = true
    @gamepad_vibration_api = nil
    return nil if !defined?(Win32API)
    GAMEPAD_VIBRATION_DLLS.each do |dll|
      begin
        @gamepad_vibration_api = Win32API.new(dll, "XInputSetState", ["L", "P"], "L")
        @gamepad_vibration_dll = dll
        break
      rescue
        @gamepad_vibration_api = nil
      end
    end
    @gamepad_vibration_api
  rescue
    @gamepad_vibration_api = nil
  end

  def gamepad_vibration_available?
    return false if !vibration_enabled?
    return false if !Input.const_defined?(:Controller)
    !!gamepad_vibration_api
  rescue
    false
  end

  def gamepad_vibration_motor_value(strength)
    [[(strength.to_f * 65_535).round, 0].max, 65_535].min
  rescue
    0
  end

  def gamepad_vibration_send(user_index, left_strength, right_strength = nil)
    api = gamepad_vibration_api
    return false if !api
    left = gamepad_vibration_motor_value(left_strength)
    right = gamepad_vibration_motor_value(right_strength.nil? ? left_strength : right_strength)
    state = [left, right].pack("SS")
    api.call(user_index.to_i, state) == 0
  rescue
    false
  end

  def gamepad_vibration_stop_all
    4.times { |i| gamepad_vibration_send(i, 0.0, 0.0) }
  rescue
  end

  def gamepad_vibrate(strength = 0.45, duration = 0.16, right_strength = nil)
    return false if !gamepad_vibration_available?
    now = System.uptime rescue Time.now.to_f
    return false if now < @next_gamepad_vibration_time.to_f
    @next_gamepad_vibration_time = now + GAMEPAD_VIBRATION_MIN_INTERVAL
    strength = [[strength.to_f, 0.0].max, 1.0].min
    right_strength = right_strength.nil? ? strength : [[right_strength.to_f, 0.0].max, 1.0].min
    duration = [[duration.to_f, 0.03].max, 0.75].min
    played = false
    4.times { |i| played = true if gamepad_vibration_send(i, strength, right_strength) }
    return false if !played
    token = Object.new
    @gamepad_vibration_token = token
    Thread.new do
      begin
        sleep(duration)
        PokemonSurvivor.gamepad_vibration_stop_all if PokemonSurvivor.instance_variable_get(:@gamepad_vibration_token).equal?(token)
      rescue
      end
    end
    true
  rescue
    false
  end

  def gamepad_vibrate_event(event, intensity = 1.0)
    return false if !vibration_enabled?
    scale = [[intensity.to_f, 0.25].max, 1.4].min
    case event
    when :burst
      gamepad_vibrate(0.52 * scale, 0.16, 0.68 * scale)
    when :hero_hit
      gamepad_vibrate(0.28 * scale, 0.10, 0.36 * scale)
    when :boss_spawn
      gamepad_vibrate(0.48 * scale, 0.20, 0.62 * scale)
    when :ultra_boss_spawn
      gamepad_vibrate(0.70 * scale, 0.28, 0.88 * scale)
    when :boss_ko
      gamepad_vibrate(0.38 * scale, 0.14, 0.54 * scale)
    when :ultra_boss_ko
      gamepad_vibrate(0.58 * scale, 0.22, 0.82 * scale)
    when :level_up
      gamepad_vibrate(0.34 * scale, 0.12, 0.46 * scale)
    when :upgrade_take
      gamepad_vibrate(0.30 * scale, 0.10, 0.40 * scale)
    when :upgrade_reroll
      gamepad_vibrate(0.22 * scale, 0.08, 0.30 * scale)
    when :upgrade_ban
      gamepad_vibrate(0.42 * scale, 0.14, 0.32 * scale)
    when :egg_hatch
      gamepad_vibrate(0.45 * scale, 0.22, 0.60 * scale)
    when :egg_shiny_hatch
      gamepad_vibrate(0.70 * scale, 0.30, 0.90 * scale)
    when :sleep_awaken
      gamepad_vibrate(0.38 * scale, 0.18, 0.52 * scale)
    when :sleep_reward
      gamepad_vibrate(0.34 * scale, 0.12, 0.46 * scale)
    when :item_pickup
      gamepad_vibrate(0.24 * scale, 0.08, 0.34 * scale)
    when :pokemon_select
      gamepad_vibrate(0.32 * scale, 0.12, 0.48 * scale)
    when :shiny_toggle
      gamepad_vibrate(0.40 * scale, 0.16, 0.58 * scale)
    else
      gamepad_vibrate(0.36 * scale, 0.12, 0.44 * scale)
    end
  rescue
    false
  end
end



# Scrollable controls list override. Keeps every control row inside the HUD.
class Scene_PokemonSurvivor
  def open_control_options
    @state = :control_options
    @control_option_index ||= 0
    @control_option_scroll ||= 0
    ensure_control_option_scroll if respond_to?(:ensure_control_option_scroll)
    @control_picker_action = nil
    @control_picker_index = 0
    @control_picker_kind ||= :keyboard
    pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    draw_control_options
  rescue
  end

  def update_control_options
    if @control_picker_action
      update_control_picker
      return
    end
    items = PokemonSurvivor::CONTROL_MENU_ITEMS
    old = @control_option_index.to_i
    moved = false
    if Input.repeat?(Input::UP)
      @control_option_index = (@control_option_index.to_i - 1) % items.length
      moved = true
    elsif Input.repeat?(Input::DOWN)
      @control_option_index = (@control_option_index.to_i + 1) % items.length
      moved = true
    end
    sync_control_option_scroll_after_move(old) if moved
    ensure_control_option_scroll unless moved
    pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil if old != @control_option_index.to_i
    item = items[@control_option_index.to_i]
    if survivor_confirm_triggered?
      if item == :vibration
        PokemonSurvivor.toggle_vibration_enabled
        pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
        PokemonSurvivor.gamepad_vibrate(0.55, 0.18) rescue nil
      else
        @control_picker_action = item
        @control_picker_kind = PokemonSurvivor.control_key_kind(PokemonSurvivor.control_key_name(item))
        keys = PokemonSurvivor.control_picker_keys(@control_picker_kind)
        current = PokemonSurvivor.control_key_name(item)
        @control_picker_index = [keys.index(current) || 0, keys.length - 1].min
        @control_picker_scroll = 0
        ensure_control_picker_scroll
        pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
      end
    elsif survivor_cancel_triggered?
      close_control_options
      return
    end
    draw_control_options
  rescue
    close_control_options
  end

  def control_option_visible_rows(_panel_h = 350)
    5
  end

  def sync_control_option_scroll_after_move(old_index)
    items = PokemonSurvivor::CONTROL_MENU_ITEMS
    visible = control_option_visible_rows
    index = [[@control_option_index.to_i, 0].max, items.length - 1].min
    max_scroll = [items.length - visible, 0].max
    @control_option_index = index
    if old_index.to_i == 0 && index == items.length - 1
      @control_option_scroll = max_scroll
    elsif old_index.to_i == items.length - 1 && index == 0
      @control_option_scroll = 0
    elsif index < @control_option_scroll.to_i
      @control_option_scroll = index
    elsif index >= @control_option_scroll.to_i + visible
      @control_option_scroll = index - visible + 1
    end
    @control_option_scroll = [[@control_option_scroll.to_i, 0].max, max_scroll].min
  rescue
    @control_option_scroll = 0
  end

  def ensure_control_option_scroll
    @control_option_scroll ||= 0
    items = PokemonSurvivor::CONTROL_MENU_ITEMS
    visible = control_option_visible_rows
    index = [[@control_option_index.to_i, 0].max, items.length - 1].min
    @control_option_index = index
    @control_option_scroll = index if index < @control_option_scroll.to_i
    bottom = @control_option_scroll.to_i + visible - 1
    @control_option_scroll = index - visible + 1 if index > bottom
    max_scroll = [items.length - visible, 0].max
    @control_option_scroll = [[@control_option_scroll.to_i, 0].max, max_scroll].min
  rescue
    @control_option_scroll = 0
  end

  def draw_control_binding_list(bitmap, x, y, w, h)
    row_h = 46
    first_y = y + 62
    items = PokemonSurvivor::CONTROL_MENU_ITEMS
    visible = control_option_visible_rows(h)
    ensure_control_option_scroll
    first = @control_option_scroll.to_i
    last = [first + visible, items.length].min
    palettes = {
      confirm: [Color.new(122, 255, 176), Color.new(24, 62, 44), Color.new(174, 255, 208)],
      cancel: [Color.new(255, 142, 132), Color.new(70, 34, 42), Color.new(255, 184, 174)],
      action: [Color.new(255, 196, 86), Color.new(70, 46, 24), Color.new(255, 232, 140)],
      menu: [Color.new(92, 188, 255), Color.new(24, 54, 82), Color.new(154, 220, 255)],
      zoom_toggle: [Color.new(96, 232, 214), Color.new(20, 62, 68), Color.new(164, 255, 244)],
      vibration: [Color.new(184, 104, 255), Color.new(54, 34, 82), Color.new(222, 176, 255)]
    }
    first.upto(last - 1) do |i|
      item = items[i]
      row_y = first_y + ((i - first) * row_h)
      selected = i == @control_option_index.to_i
      edge, fill, shine = palettes[item] || palettes[:menu]
      fill = Color.new([fill.red + 34, 255].min, [fill.green + 34, 255].min, [fill.blue + 34, 255].min) if selected
      shine = Color.new([shine.red + 22, 255].min, [shine.green + 22, 255].min, [shine.blue + 22, 255].min) if selected
      draw_modern_button_frame(bitmap, x + 20, row_y, w - 52, 39, edge, fill, shine, selected)
      draw_text_box(bitmap, control_option_label(item), x + 34, row_y + 9, w - 200, 20, Color.new(226, 232, 244), Color.new(30, 30, 38), 0)
      if item == :vibration
        draw_text_box(bitmap, control_option_value(item), x + w - 142, row_y + 9, 92, 20, shine, Color.new(30, 30, 38), 2)
      else
        icon_size = defined?(ControlHelpText) ? ControlHelpText::ICON_SIZE : 16
        keyboard_key = PokemonSurvivor.control_key_name(item, :keyboard)
        gamepad_key = PokemonSurvivor.control_key_name(item, :gamepad)
        draw_control_key_icon(bitmap, keyboard_key, x + w - 118, row_y + ((39 - icon_size) / 2))
        draw_control_key_icon(bitmap, gamepad_key, x + w - 84, row_y + ((39 - icon_size) / 2))
      end
    end
    if items.length > visible
      bar_x = x + w - 24
      bar_y = first_y
      bar_h = (visible * row_h) - 7
      thumb_h = [[(bar_h * visible / items.length).round, 18].max, bar_h].min
      max_scroll = [items.length - visible, 1].max
      thumb_y = bar_y + ((bar_h - thumb_h) * @control_option_scroll.to_i / max_scroll)
      draw_select_scrollbar(bitmap, bar_x, bar_y, 7, bar_h, thumb_y, thumb_h)
    end
  rescue
  end
end





