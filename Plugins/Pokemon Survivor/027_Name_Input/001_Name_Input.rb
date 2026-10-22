#===============================================================================
# Pokemon Survivor - Custom trainer name HUD
#===============================================================================

class PokemonSurvivorNameInputScene
  KEY_A = 0x41
  KEY_Z = 0x5A
  KEY_BACKSPACE = 0x08
  KEY_TAB = 0x09
  KEY_ENTER = 0x0D
  KEY_ESCAPE = 0x1B
  KEY_SHIFT = 0x10
  KEY_CAPS_LOCK = 0x14

  def initialize(initial_name = "", options = {})
    @name = PokemonSurvivor.normalized_trainer_name(initial_name)
    @name = "" if @name.upcase == "PLAYER"
    @allow_offline_temp = options[:allow_offline_temp] ? true : false
    @require_online = options[:require_online] ? true : false
    @can_cancel = options[:can_cancel] ? true : false
    @result = false
    @message = @require_online ? _INTL("Choose an online trainer name.") : _INTL("Please choose your trainer name.")
    @error = _INTL("Max 7 characters: A-Z, a-z, 0-9.")
    @checking = false
    @sprites = {}
  end

  def main
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites["screen"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    start_native_name_input
    draw
    loop do
      Graphics.update
      Input.update
      changed = update_input
      draw if changed || cursor_refresh_due? || @scrolling_text_active
      break if @done
    end
    @result
  ensure
    stop_native_name_input
    @menu_hud_background.dispose if @menu_hud_background && !@menu_hud_background.disposed? rescue nil
    @key_icon_cache.each_value { |icon| icon.dispose if icon && !icon.disposed? } if @key_icon_cache rescue nil
    pbDisposeSpriteHash(@sprites) rescue nil
    @viewport.dispose if @viewport && !@viewport.disposed?
  end

  def update_input
    return true if @checking
    text = @native_text_input ? Input.gets.to_s : nil
    if key_trigger?(KEY_ENTER)
      validate_and_apply
      Input.text_input = true if @native_text_input && !@done
      return true
    end
    if key_trigger?(KEY_BACKSPACE)
      @name = @name[0, @name.length - 1] if @name.length > 0
      @error = _INTL("Max 7 characters: A-Z, a-z, 0-9.") if @name.empty?
      pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue nil
      return true
    end
    if key_trigger?(KEY_ESCAPE)
      if @can_cancel
        @done = true
        @result = false
        pbSEPlay("Survivor/GUI sel cancel", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayCancelSE rescue nil
      else
        @error = _INTL("Please enter a valid name to continue.")
        pbPlayBuzzerSE rescue nil
      end
      return true
    end
    text = triggered_letter.to_s unless @native_text_input
    text = text.to_s.gsub(/[^A-Za-z0-9]/, "")
    remaining = [PokemonSurvivor::TRAINER_NAME_MAX_LENGTH - @name.length, 0].max
    text = text[0, remaining].to_s
    if !text.empty?
      @name += text
      @error = _INTL("Press Enter to confirm.")
      pbSEPlay("Survivor/GUI sel cursor", PokemonSurvivor::UI_CURSOR_VOLUME, 100) rescue nil
      return true
    end
    false
  rescue
    true
  end

  def validate_and_apply
    clean = PokemonSurvivor.normalized_trainer_name(@name)
    error = PokemonSurvivor.trainer_name_error(clean)
    if error
      @error = error
      pbPlayBuzzerSE rescue nil
      return false
    end
    @checking = true
    @error = _INTL("Checking name...")
    draw
    taken = PokemonSurvivor.trainer_name_taken_online?(clean, true)
    @checking = false
    if taken == :unavailable
      if @allow_offline_temp && !@require_online && PokemonSurvivor.apply_trainer_name(clean)
        return false if !PokemonSurvivor.confirm_trainer_name_save_loop
        PokemonSurvivor.mark_trainer_name_temporary(true)
        pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
        @result = true
        @done = true
        return true
      end
      @error = _INTL("Name check is unavailable. Try again.")
      pbPlayBuzzerSE rescue nil
      return false
    elsif taken
      @error = _INTL("This name is already taken. Choose another one.")
      @name = ""
      pbPlayBuzzerSE rescue nil
      return false
    end
    if PokemonSurvivor.apply_trainer_name(clean)
      return false if !PokemonSurvivor.confirm_trainer_name_save_loop
      PokemonSurvivor.mark_trainer_name_temporary(false)
      pbSEPlay("Survivor/GUI sel decision", PokemonSurvivor::UI_DECISION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
      @result = true
      @done = true
      return true
    end
    @error = _INTL("Trainer name could not be changed right now.")
    pbPlayBuzzerSE rescue nil
    false
  rescue
    @checking = false
    @error = _INTL("Trainer name could not be changed right now.")
    false
  end

  def start_native_name_input
    @native_text_input = false
    return unless Input.respond_to?(:gets) && Input.respond_to?(:text_input=)
    @previous_text_input = Input.respond_to?(:text_input) ? Input.text_input : false
    Input.text_input = true
    @native_text_input = true
    Input.gets # Discard text left over from the previous screen.
  end

  def stop_native_name_input
    return unless @native_text_input
    Input.text_input = @previous_text_input ? true : false
    @native_text_input = false
  end

  def triggered_letter
    code = KEY_A
    while code <= KEY_Z
      return typed_letter_for(code) if key_trigger?(code)
      code += 1
    end
    nil
  rescue
    nil
  end

  def typed_letter_for(code)
    letter = code.chr
    if defined?(ControlHelpText) && ControlHelpText.respond_to?(:keyboard_display_key)
      letter = ControlHelpText.keyboard_display_key(letter).to_s
    elsif detected_azerty_keyboard?
      letter = { "A" => "Q", "Q" => "A", "Z" => "W", "W" => "Z" }[letter] || letter
    end
    letter = letter[0, 1].to_s
    uppercase_letter? ? letter.upcase : letter.downcase
  rescue
    code.chr.downcase rescue ""
  end

  def detected_azerty_keyboard?
    return ControlHelpText.keyboard_layout == :azerty if defined?(ControlHelpText) && ControlHelpText.respond_to?(:keyboard_layout)
    return false if !defined?(Win32API)
    @keyboard_layout_api ||= Win32API.new("user32", "GetKeyboardLayout", ["L"], "L")
    lang_id = @keyboard_layout_api.call(0).to_i & 0xFFFF
    lang_id == 0x040C || lang_id == 0x080C || lang_id == 0x100C || lang_id == 0x140C || lang_id == 0x180C
  rescue
    false
  end

  def uppercase_letter?
    shift = key_pressed?(KEY_SHIFT)
    caps = caps_lock_active?
    shift != caps
  rescue
    false
  end

  def key_pressed?(code)
    pressed = false
    pressed ||= Input.pressex?(code) if Input.respond_to?(:pressex?)
    pressed ||= raw_key_pressed?(code)
    pressed ? true : false
  rescue
    false
  end

  def raw_key_pressed?(code)
    return false if !defined?(Win32API)
    @get_async_key_state_api ||= Win32API.new("user32", "GetAsyncKeyState", ["L"], "L")
    (@get_async_key_state_api.call(code.to_i).to_i & 0x8000) != 0
  rescue
    false
  end

  def caps_lock_active?
    return false if !defined?(Win32API)
    @get_key_state_api ||= Win32API.new("user32", "GetKeyState", ["L"], "L")
    (@get_key_state_api.call(KEY_CAPS_LOCK).to_i & 1) == 1
  rescue
    false
  end

  def key_trigger?(code)
    if @native_text_input
      key = { KEY_ENTER => :RETURN, KEY_BACKSPACE => :BACKSPACE, KEY_ESCAPE => :ESCAPE }[code]
      return false if !key || !Input.respond_to?(:triggerex?)
      return true if Input.triggerex?(key)
      return key == :BACKSPACE && Input.respond_to?(:repeatex?) && Input.repeatex?(key)
    end
    @raw_key_states ||= {}
    @recent_key_triggers ||= {}
    now = System.uptime rescue 0.0
    current = raw_key_pressed?(code)
    previous = @raw_key_states[code.to_i] ? true : false
    @raw_key_states[code.to_i] = current ? true : false
    triggered = false
    triggered ||= Input.triggerex?(code) if Input.respond_to?(:triggerex?)
    triggered ||= current && !previous
    if triggered
      last = @recent_key_triggers[code.to_i].to_f
      return false if last > 0.0 && now - last < 0.075
      @recent_key_triggers[code.to_i] = now
    end
    triggered ? true : false
  rescue
    false
  end

  def cursor_refresh_due?
    now = System.uptime rescue 0.0
    old = @cursor_tick.to_i
    @cursor_tick = (now * 2).to_i
    old != @cursor_tick
  rescue
    false
  end

  def draw
    bitmap = @sprites["screen"].bitmap
    @scrolling_text_active = false
    bitmap.clear
    pbSetSystemFont(bitmap)
    draw_background(bitmap)
    w = [Graphics.width - 80, 420].min
    h = 168
    x = (Graphics.width - w) / 2
    y = (Graphics.height - h) / 2
    draw_panel(bitmap, x, y, w, h)
    draw_clipped_text(bitmap, @message, x + 16, y + 18, w - 32, 28, Color.new(255, 238, 160), Color.new(40, 40, 48), 2)
    draw_name_field(bitmap, x + 42, y + 62, w - 84, 42)
    draw_clipped_text(bitmap, @error, x + 18, y + 114, w - 36, 28, error_color, Color.new(40, 40, 48), 2)

  rescue
  end

  def draw_background(bitmap)
    bg = menu_hud_background
    if bg && !bg.disposed?
      bitmap.stretch_blt(Rect.new(0, 0, Graphics.width, Graphics.height), bg, Rect.new(0, 0, bg.width, bg.height))
      return
    end
    bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(7, 10, 18))
    bitmap.fill_rect(13, 13, Graphics.width - 26, Graphics.height - 26, Color.new(20, 31, 52, 232))
    bitmap.fill_rect(18, 18, Graphics.width - 36, Graphics.height - 36, Color.new(27, 43, 70, 224))
  rescue
  end

  def menu_hud_background
    return @menu_hud_background if @menu_hud_background && !@menu_hud_background.disposed?
    path = pbResolveBitmap("Graphics/UI/Survivor Game/Menu HUD/bg_B2W2") rescue nil
    @menu_hud_background = Bitmap.new(path) if path
    @menu_hud_background
  rescue
    nil
  end

  def local_round_rect(bitmap, x, y, w, h, color)
    return if w.to_i <= 0 || h.to_i <= 0
    x = x.to_i; y = y.to_i; w = w.to_i; h = h.to_i
    return bitmap.fill_rect(x, y, w, h, color) if w < 8 || h < 8
    bitmap.fill_rect(x + 3, y, w - 6, h, color)
    bitmap.fill_rect(x + 1, y + 1, w - 2, h - 2, color)
    bitmap.fill_rect(x, y + 3, w, h - 6, color)
  rescue
    bitmap.fill_rect(x, y, w, h, color) rescue nil
  end

  def draw_panel(bitmap, x, y, w, h)
    accent = Color.new(122, 255, 176)
    local_round_rect(bitmap, x, y, w, h, Color.new(3, 6, 13))
    local_round_rect(bitmap, x + 1, y + 1, w - 2, h - 2, Color.new(12, 20, 36))
    local_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, Color.new(58, 88, 112))
    local_round_rect(bitmap, x + 4, y + 4, w - 8, h - 8, Color.new(12, 21, 38))
    local_round_rect(bitmap, x + 6, y + 6, w - 12, h - 12, Color.new(18, 29, 50))
    bitmap.fill_rect(x + 10, y + 8, w - 20, 2, accent)
    bitmap.fill_rect(x + 12, y + 11, w - 24, 1, Color.new(255, 255, 255, 42))
    bitmap.fill_rect(x + 10, y + h - 11, w - 20, 2, Color.new(255, 198, 70))
  rescue
  end

  def draw_name_field(bitmap, x, y, w, h)
    local_round_rect(bitmap, x, y, w, h, Color.new(3, 6, 13))
    local_round_rect(bitmap, x + 2, y + 2, w - 4, h - 4, Color.new(34, 46, 68))
    local_round_rect(bitmap, x + 4, y + 4, w - 8, h - 8, Color.new(8, 13, 26))
    bitmap.fill_rect(x + 8, y + 6, w - 16, 2, Color.new(122, 255, 176))
    bitmap.fill_rect(x + 10, y + h - 7, w - 20, 1, Color.new(255, 198, 70))
    shown = @name.empty? ? "_" : @name
    cursor = ((System.uptime rescue 0.0) * 2).to_i.even? ? "_" : ""
    draw_clipped_text(bitmap, shown + cursor, x + 8, y + 11, w - 16, 24, Color.white, Color.new(40, 40, 48), 2)
  rescue
  end

  def draw_clipped_text(bitmap, text, x, y, w, h, base = Color.white, shadow = Color.new(40, 40, 48), align = false)
    w = w.to_i
    h = h.to_i
    return if w <= 0 || h <= 0
    tmp = Bitmap.new(w, h)
    pbSetSystemFont(tmp)
    value = text.to_s
    text_w = tmp.text_size(value).width rescue 0
    if text_w > w
      @scrolling_text_active = true
      offset = name_text_scroll_offset([text_w - w + 18, 0].max)
      pbDrawTextPositions(tmp, [[value, -offset, 0, false, base, shadow]])
    else
      draw_x = align == 2 ? w / 2 : 0
      pbDrawTextPositions(tmp, [[value, draw_x, 0, align, base, shadow]])
    end
    bitmap.blt(x, y, tmp, Rect.new(0, 0, w, h))
    tmp.dispose
  rescue
    tmp.dispose if tmp && !tmp.disposed? rescue nil
  end

  def name_text_scroll_offset(max_offset)
    max_offset = max_offset.to_f
    return 0 if max_offset <= 0
    pause = 0.55
    speed = 22.0
    travel = max_offset / speed
    cycle = (travel * 2.0) + (pause * 2.0)
    pos = (System.uptime rescue 0.0) % [cycle, 0.001].max
    return 0 if pos < pause
    pos -= pause
    return max_offset if pos > travel && pos < travel + pause
    pos -= pause if pos >= travel + pause
    value = pos <= travel ? pos * speed : max_offset - ((pos - travel) * speed)
    [[value, 0.0].max, max_offset].min
  rescue
    0
  end

  def error_color
    return Color.new(122, 255, 176) if @checking
    return Color.new(255, 132, 132) if @error.to_s[/taken|invalid|unavailable|could not|valid name/i]
    Color.new(220, 226, 240)
  rescue
    Color.white
  end
end

module PokemonSurvivor
  module_function

  def prompt_trainer_rename(options = {})
    options ||= {}
    options = { allow_offline_temp: true }.merge(options)
    scene = PokemonSurvivorNameInputScene.new(leaderboard_player_name, options)
    scene.main ? true : false
  rescue
    false
  end

  def ensure_online_trainer_name(context = nil)
    clean = normalized_trainer_name(leaderboard_player_name)
    return prompt_trainer_rename({ allow_offline_temp: false, require_online: true, can_cancel: true }) if clean.empty?
    return true if trainer_name_online_verified?
    error = trainer_name_error(clean)
    return prompt_trainer_rename({ allow_offline_temp: false, require_online: true, can_cancel: true }) if error
    availability = trainer_name_taken_online?(clean, true)
    if availability == false
      return false if !confirm_trainer_name_save_loop
      mark_trainer_name_temporary(false)
      return true
    end
    mark_trainer_name_temporary(true) if availability == :unavailable
    prompt_trainer_rename({ allow_offline_temp: false, require_online: true, can_cancel: true })
  rescue
    false
  end
end












