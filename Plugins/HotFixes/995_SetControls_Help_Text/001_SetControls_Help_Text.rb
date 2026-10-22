module ControlHelpText
  ROOT = "Graphics/UI/Controls"
  ICON_SIZE = 16
  ICON_TEXT_GAP = 4
  SEGMENT_GAP = 14

  ACTIONS = {
    :down        => ["Down", "Down"],
    :left        => ["Left", "Left"],
    :right       => ["Right", "Right"],
    :up          => ["Up", "Up"],
    :confirm     => ["Action", "C"],
    :cancel      => ["Cancel", "X"],
    :action      => ["Menu", "Z"],
    :menu        => ["Menu", "Z"],
    :scroll_up   => ["Scroll Up", "A"],
    :scroll_down => ["Scroll Down", "S"],
    :ready_menu  => ["Ready Menu", "D"],
    :special     => ["Ready Menu", "D"]
  }

  KEYBOARD_ICONS = {
    "Down" => "Down",
    "Left" => "Left",
    "Right" => "Right",
    "Up" => "Up",
    "Esc" => "x",
    "Enter" => "c",
    "Space" => "c",
    "Shift" => "z"
  }

  AZERTY_LANGUAGE_IDS = [
    0x040c, # French - France
    0x080c, # French - Belgium
    0x0813, # Dutch - Belgium
    0x180c  # French - Monaco
  ]

  AZERTY_KEY_LABELS = {
    "A" => "q",
    "Q" => "a",
    "Z" => "w",
    "W" => "z"
  }

  XBOX_ICONS = {
    "Button A" => "A",
    "Button B" => "B",
    "Button X" => "X",
    "Button Y" => "Y",
    "Button Back" => "Share",
    "Button Start" => "Option",
    "Left Shoulder" => "LB",
    "Right Shoulder" => "RB",
    "Left Trigger" => "LT",
    "Right Trigger" => "RT",
    "D-Pad Down" => "Down",
    "D-Pad Left" => "Left",
    "D-Pad Right" => "Right",
    "D-Pad Up" => "Up",
    "L-Stick Down" => "Down",
    "L-Stick Left" => "Left",
    "L-Stick Right" => "Right",
    "L-Stick Up" => "Up"
  }

  PLAYSTATION_ICONS = {
    "Button A" => "Cross",
    "Button B" => "Circle",
    "Button X" => "Square",
    "Button Y" => "Triangle",
    "Button Back" => "Share",
    "Button Start" => "Option",
    "Left Shoulder" => "L1",
    "Right Shoulder" => "R1",
    "Left Trigger" => "L2",
    "Right Trigger" => "R2",
    "D-Pad Down" => "Down",
    "D-Pad Left" => "Left",
    "D-Pad Right" => "Right",
    "D-Pad Up" => "Up",
    "L-Stick Down" => "Down",
    "L-Stick Left" => "Left",
    "L-Stick Right" => "Right",
    "L-Stick Up" => "Up"
  }

  @last_input_type = :keyboard
  @controller_family = :xbox
  @keyboard_layout = :qwerty
  @input_version = 0

  def self.last_input_type
    return @last_input_type || :keyboard
  end

  def self.controller_family
    detect_controller_family
    return @controller_family || :xbox
  end

  def self.input_version
    return @input_version || 0
  end

  def self.keyboard_layout
    detect_keyboard_layout
    return @keyboard_layout || :qwerty
  end

  def self.set_last_input_type(type)
    return if @last_input_type == type
    @last_input_type = type
    @input_version = input_version + 1
  end

  def self.detect_controller_family
    name = ""
    begin
      controller = Input.const_defined?(:Controller) ? Input::Controller : nil
      if controller
        [:name, :device_name, :controller_name, :description].each do |meth|
          next if !controller.respond_to?(meth)
          name = controller.send(meth).to_s
          break if !name.empty?
        end
      end
    rescue
      name = ""
    end
    family = name[/playstation|dualshock|dualsense|ps4|ps5|sony/i] ? :playstation : :xbox
    if @controller_family != family
      @controller_family = family
      @input_version = input_version + 1
    end
  end

  def self.detect_keyboard_layout
    layout = :qwerty
    begin
      if defined?(Win32API)
        api = @get_keyboard_layout_api ||= Win32API.new("user32", "GetKeyboardLayout", ["L"], "L")
        lang_id = api.call(0).to_i & 0xffff
        layout = AZERTY_LANGUAGE_IDS.include?(lang_id) ? :azerty : :qwerty
      end
    rescue
      layout = :qwerty
    end
    if @keyboard_layout != layout
      @keyboard_layout = layout
      @input_version = input_version + 1
    end
    return @keyboard_layout
  end

  def self.keyboard_key?(key_name)
    return true if !key_name
    return false if key_name[/Button|D-Pad|Shoulder|Trigger|Stick/i]
    return false if key_name[/L-Stick|RStick|Joystick/i]
    return true
  end

  def self.gamepad_key?(key_name)
    return !keyboard_key?(key_name)
  end

  def self.keys_for(action)
    data = ACTIONS[action]
    return [] if !data
    control_action, fallback = data
    begin
      if defined?(SetControls) && SetControls.respond_to?(:key_array) && $PokemonSystem
        keys = SetControls.key_array(control_action)
        keys = keys.select { |k| k && !k.to_s.empty? && k.to_s != "None" }
        return keys if !keys.empty?
      end
    rescue
    end
    return [fallback]
  end

  def self.key(action)
    keys = keys_for(action)
    preferred = preferred_key(keys)
    return preferred || action.to_s
  end

  def self.pair(first, second)
    return _INTL("{1}/{2}", key(first), key(second))
  end

  def self.preferred_key(keys)
    return nil if !keys || keys.empty?
    if last_input_type == :gamepad
      key = keys.find { |k| gamepad_key?(k) }
      return key if key
    end
    key = keys.find { |k| keyboard_key?(k) }
    return key if key
    return keys[0]
  end

  def self.icon_name_for_key(key_name)
    return nil if !key_name
    key_name = key_name.to_s
    if gamepad_key?(key_name)
      table = controller_family == :playstation ? PLAYSTATION_ICONS : XBOX_ICONS
      return table[key_name]
    end
    mapped = keyboard_icon_name(key_name)
    return mapped
  end

  def self.keyboard_icon_name(key_name)
    return nil if !key_name
    return KEYBOARD_ICONS[key_name] if KEYBOARD_ICONS[key_name]
    display = keyboard_display_key(key_name)
    return display.downcase if display && display[/\A[A-Z0-9]\z/i]
    return key_name.downcase
  end

  def self.keyboard_display_key(key_name)
    key_name = key_name.to_s
    return key_name if key_name.empty?
    if keyboard_layout == :azerty
      return AZERTY_KEY_LABELS[key_name] || AZERTY_KEY_LABELS[key_name.upcase] || key_name
    end
    return key_name
  end

  def self.icon_path_for_key(key_name)
    icon_name = icon_name_for_key(key_name)
    return nil if !icon_name || icon_name.empty?
    folder = gamepad_key?(key_name) ? (controller_family == :playstation ? "Playstation" : "Xbox") : "Keyboard"
    path = "#{ROOT}/#{folder}/#{icon_name}"
    begin
      return path if pbResolveBitmap(path)
    rescue
    end
    return nil
  end

  def self.icon_path(action)
    return icon_path_for_key(key(action))
  end

  def self.segment_width(bitmap, action, label = nil)
    label = label.to_s
    text_w = label.empty? ? 0 : (bitmap.text_size(label).width rescue 0)
    return ICON_SIZE + (label.empty? ? 0 : ICON_TEXT_GAP + text_w)
  end

  def self.cached_icon_bitmap(path)
    return nil if !path || path.empty?
    @icon_bitmap_cache ||= {}
    cached = @icon_bitmap_cache[path]
    return cached if cached && !cached.disposed?
    bmp = Bitmap.new(path)
    @icon_bitmap_cache[path] = bmp
    bmp
  rescue
    nil
  end

  def self.draw_icon(bitmap, action, x, y)
    key_name = key(action)
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
    display_key = gamepad_key?(key_name) ? key_name : keyboard_display_key(key_name)
    pbDrawTextPositions(bitmap, [[display_key, x, y - 2, 0, Color.white, Color.new(0, 0, 0)]])
    return bitmap.text_size(display_key).width rescue ICON_SIZE
  rescue
    return ICON_SIZE
  end

  def self.draw_segments(bitmap, segments, x, y, align = 0, base = Color.white, shadow = Color.new(0, 0, 0), width = nil)
    width ||= bitmap.width - x
    total = 0
    segments.each do |segment|
      action = segment[0]
      label = segment[1].to_s
      total += segment_width(bitmap, action, label)
    end
    segments.each_with_index do |segment, i|
      next if i >= segments.length - 1
      total += segment[1].to_s.empty? ? 3 : SEGMENT_GAP
    end
    if total > width
      return draw_scrolling_segments(bitmap, segments, x, y, width, total, base, shadow)
    end
    draw_x = x
    draw_x = x + ((width - total) / 2) if align == 2
    draw_x = x + width - total if align == 1

    draw_segments_raw(bitmap, segments, draw_x, y, base, shadow)
    return total
  end

  def self.draw_segments_raw(bitmap, segments, draw_x, y, base, shadow)
    segments.each_with_index do |segment, i|
      action = segment[0]
      label = segment[1].to_s
      icon_y = y + 1
      draw_icon(bitmap, action, draw_x, icon_y)
      draw_x += ICON_SIZE
      if !label.empty?
        draw_x += ICON_TEXT_GAP
        pbDrawTextPositions(bitmap, [[label, draw_x, y, 0, base, shadow]])
        draw_x += bitmap.text_size(label).width rescue 0
      end
      draw_x += (label.empty? ? 3 : SEGMENT_GAP) if i < segments.length - 1
    end
  end

  def self.draw_scrolling_segments(bitmap, segments, x, y, width, total, base, shadow)
    height = 24
    temp = Bitmap.new(total, height)
    pbSetSystemFont(temp)
    draw_segments_raw(temp, segments, 0, 0, base, shadow)
    offset = smooth_scroll_offset(total - width, 5, 70)
    bitmap.blt(x, y, temp, Rect.new(offset, 0, width, height))
    return total
  ensure
    temp.dispose if temp && !temp.disposed?
  end

  def self.smooth_scroll_offset(distance, frames_per_pixel = 5, pause = 70)
    return 0 if distance <= 0
    frame = ((System.uptime rescue 0) * 60).floor
    travel_frames = [distance.to_i * [frames_per_pixel, 1].max, 1].max
    cycle = (pause * 2) + (travel_frames * 2)
    pos = frame % cycle
    return 0 if pos < pause
    pos -= pause
    if pos < travel_frames
      t = pos / travel_frames.to_f
      return (distance * ((1.0 - Math.cos(t * Math::PI)) / 2.0)).round
    end
    pos -= travel_frames
    return distance if pos < pause
    pos -= pause
    t = pos / travel_frames.to_f
    (distance * ((1.0 + Math.cos(t * Math::PI)) / 2.0)).round
  rescue
    0
  end

  def self.update_last_input
    frame = Graphics.frame_count rescue nil
    return if frame && @last_input_scan_frame == frame
    @last_input_scan_frame = frame if frame
    detect_keyboard_layout
    begin
      if defined?(Keys)
        Keys::KEYBOARD_LIST.values.each do |code|
          if Input.triggerex?(code) || Input.pressex?(code)
            set_last_input_type(:keyboard)
            return
          end
        end
      end
    rescue
    end
    begin
      controller = Input.const_defined?(:Controller) ? Input::Controller : nil
      if controller && defined?(Keys)
        Keys::GAMEPAD_LIST.values.each do |code|
          if controller.triggerex?(code) || controller.pressex?(code)
            set_last_input_type(:gamepad)
            detect_controller_family
            return
          end
        end
      end
    rescue
    end
    begin
      if defined?(Keys)
        Keys::GAMEPAD_AXIS_LIST.values.each do |code|
          if Input.axis_triggerex?(code) || Input.axis_pressex?(code)
            set_last_input_type(:gamepad)
            detect_controller_family
            return
          end
        end
      end
    rescue
    end
  end
end

EventHandlers.add(:on_frame_update, :control_help_text_last_input, proc {
  ControlHelpText.update_last_input if defined?(ControlHelpText)
}) if defined?(EventHandlers)

module Input
  class << self
    alias control_help_text_update update unless method_defined?(:control_help_text_update)
    def update(*args)
      ret = control_help_text_update(*args)
      ControlHelpText.update_last_input if defined?(ControlHelpText)
      return ret
    end
  end
end

