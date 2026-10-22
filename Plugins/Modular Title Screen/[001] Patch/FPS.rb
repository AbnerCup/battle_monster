#===============================================================================
# Modular Title Screen - 60 FPS Logical Cap
# Pokémon Essentials v19.x
#
# Place this below the COMPLETE Modular Title Screen script.
#===============================================================================

module ModularTitleFrameCap
  TARGET_FPS = 60.0

  def self.apply_target_frame_rate
    Graphics.frame_rate = TARGET_FPS.to_i if Graphics.respond_to?(:frame_rate=) && Graphics.frame_rate != TARGET_FPS.to_i
  rescue
  end

  def self.reset!
    apply_target_frame_rate
  end

  def self.real_fps
    apply_target_frame_rate
    fps = Graphics.frame_rate rescue TARGET_FPS
    fps = TARGET_FPS if fps.nil? || fps <= 0
    return fps.to_f
  end

  def self.update_ratio
    return TARGET_FPS / real_fps
  end

  def self.frames_for_seconds(seconds)
    return (seconds * TARGET_FPS).ceil
  end

  def self.splash_fade_frames
    return frames_for_seconds((IntroEventScene::FADE_TICKS rescue 8).to_f / 20.0)
  end

  def self.splash_hold_frames
    return frames_for_seconds((IntroEventScene::SECONDS_PER_SPLASH rescue 2).to_f)
  end

  def self.render_frames_per_logical_frame
    apply_target_frame_rate
    return [(real_fps / TARGET_FPS).round, 1].max
  end

  def self.wait_logical_frame
    render_frames_per_logical_frame.times do
      Graphics.update
      Input.update
    end
  end

  def self.wait_graphics_frames(amount = 1)
    amount.times do
      Graphics.update
      Input.update
    end
  end
end

#===============================================================================
# Intro animations wait cap
#===============================================================================

module MTS_FrameCap_IntroWait
  def wait(frames = 1, advance = true)
    return false if @skip

    frames.times do
      @currentFrame += 1 if advance
      self.updateScene if self.respond_to?(:updateScene)
      ModularTitleFrameCap.wait_logical_frame
      @skip = true if ModularTitleFrameCap.title_confirm_triggered?
      break if @skip
    end

    return true
  end
end

[
  MTS_INTRO_ANIM,
  MTS_INTRO_ANIM1,
  MTS_INTRO_ANIM2,
  MTS_INTRO_ANIM3,
  MTS_INTRO_ANIM4,
  MTS_INTRO_ANIM5,
  MTS_INTRO_ANIM6,
  MTS_INTRO_ANIM7
].each do |klass|
  if defined?(klass) && !klass.ancestors.include?(MTS_FrameCap_IntroWait)
    klass.prepend(MTS_FrameCap_IntroWait)
  end
end

#===============================================================================
# ModularTitleScreen main update cap
#===============================================================================

class ModularTitleScreen
  alias mts_framecap_initialize initialize unless method_defined?(:mts_framecap_initialize)
  def initialize
    ModularTitleFrameCap.reset!
    mts_framecap_initialize
    @mts_framecap_acc = 0.0
  end

  def update
    @mts_framecap_acc += ModularTitleFrameCap.update_ratio

    while @mts_framecap_acc >= 1.0
      @currentFrame += 1
      self.updateElements

      if !@totalFrames.nil? && @totalFrames >= 0 && @currentFrame >= @totalFrames
        self.restart
      end

      @mts_framecap_acc -= 1.0
    end
  end

  def playBGM
    bgm = nil

    for mod in @mods
      arg = mod.to_s.upcase
      if arg.include?("BGM:")
        bgm = arg.gsub("BGM:", "")
        break
      end
    end

    bgm = $data_system.title_bgm.name if bgm.nil?
    @totalFrames = (getPlayTime("Audio/BGM/" + bgm).floor - 1) * ModularTitleFrameCap::TARGET_FPS
    pbBGMPlay(bgm)
  end

  def restart
    pbBGMStop(0)

    51.times do
      @viewport.tone.red   -= 5
      @viewport.tone.green -= 5
      @viewport.tone.blue  -= 5
      self.updateElements
      ModularTitleFrameCap.wait_graphics_frames(
        (ModularTitleFrameCap.real_fps / ModularTitleFrameCap::TARGET_FPS).ceil
      )
    end

    raise Reset.new
  end
end


module ModularTitleFrameCap
  TITLE_KEY_ENTER = 0x0D
  TITLE_KEY_SPACE = 0x20

  def self.raw_title_key_pressed?(code)
    return false if !defined?(Win32API)
    @title_get_async_key_state ||= Win32API.new("user32", "GetAsyncKeyState", ["L"], "L")
    (@title_get_async_key_state.call(code.to_i).to_i & 0x8000) != 0
  rescue
    false
  end

  def self.title_key_trigger?(code)
    @title_raw_key_states ||= {}
    @title_recent_key_triggers ||= {}
    now = System.uptime rescue 0.0
    current = raw_title_key_pressed?(code)
    previous = @title_raw_key_states[code.to_i] ? true : false
    @title_raw_key_states[code.to_i] = current ? true : false
    triggered = false
    triggered ||= Input.triggerex?(code) if Input.respond_to?(:triggerex?)
    triggered ||= current && !previous
    if triggered
      last = @title_recent_key_triggers[code.to_i].to_f
      return false if last > 0.0 && now - last < 0.075
      @title_recent_key_triggers[code.to_i] = now
    end
    triggered ? true : false
  rescue
    false
  end

  def self.title_confirm_triggered?
    return true if Input.trigger?(Input::C)
    return true if Input.const_defined?(:USE) && Input.trigger?(Input::USE)
    return true if Input.respond_to?(:triggerex?) && Input.triggerex?(TITLE_KEY_ENTER)
    return true if Input.respond_to?(:triggerex?) && Input.triggerex?(TITLE_KEY_SPACE)
    return true if Input.respond_to?(:pressex?) && Input.pressex?(TITLE_KEY_ENTER)
    return true if Input.respond_to?(:pressex?) && Input.pressex?(TITLE_KEY_SPACE)
    return true if title_key_trigger?(TITLE_KEY_ENTER)
    return true if title_key_trigger?(TITLE_KEY_SPACE)
    false
  rescue
    false
  end
end
#===============================================================================
# Scene_Intro main loop cap
#===============================================================================

class Scene_Intro
  alias mts_framecap_main main unless method_defined?(:mts_framecap_main)
  def main
    ModularTitleFrameCap.reset!
    mts_framecap_main
  end

  def update
    ModularTitleFrameCap.apply_target_frame_rate
    ret = 0

    loop do
      @screen.update

      Graphics.update
      Input.update

      if Input.press?(Input::DOWN) && Input.press?(Input::B) && Input.press?(Input::CTRL)
        ret = 1
        break
      end

      if ModularTitleFrameCap.title_confirm_triggered? || (defined?($mouse) && $mouse.leftClick?)
        ret = 2
        break
      end
    end

    case ret
    when 1
      closeTitleDelete
    when 2
      closeTitle
    end
  end

  def cyclePics
    pics = IntroEventScene::SPLASH_IMAGES

    fade_frames = ModularTitleFrameCap.splash_fade_frames

    hold_frames = ModularTitleFrameCap.splash_hold_frames

    sprite = Sprite.new
    sprite.opacity = 0

    for i in 0...pics.length
      bitmap = pbBitmap("Graphics/Titles/#{pics[i]}")
      sprite.bitmap = bitmap

      fade_frames.times do
        sprite.opacity += 255.0 / fade_frames
        ModularTitleFrameCap.wait_logical_frame
      end

      hold_frames.times do
        ModularTitleFrameCap.wait_logical_frame
      end

      fade_frames.times do
        sprite.opacity -= 255.0 / fade_frames
        ModularTitleFrameCap.wait_logical_frame
      end
    end

    sprite.dispose
  end

  def wait(frames = 1, advance = true)
    return false if @skip

    frames.times do
      ModularTitleFrameCap.wait_logical_frame
      @skip = true if ModularTitleFrameCap.title_confirm_triggered?
      break if @skip
    end

    return true
  end
end

#===============================================================================
# Optional safety patch for logo bounce
# Replaces Graphics.frame_rate * 10 with a fixed 60 FPS duration.
#===============================================================================

class MTS_Element_Logo
  def update
    return if self.disposed?

    # Glow animation
    @sprites["logo1"].color.alpha += @glow * 0.5
    @sprites["glow1"].opacity += @glow
    @glow *= -1 if @sprites["logo1"].color.alpha <= 0 || @sprites["logo1"].color.alpha > 63

    # Bounce animation capped at 60 FPS logic
    if @bounce >= 0
      if @bounce >= 0 && @bounce < 8
        @sprites["logo1"].oy += 2
        @sprites["glow1"].oy += 2
        @sprites["shine"].oy += 2
      elsif @bounce >= 8 && @bounce < 16
        @sprites["logo1"].oy -= 2
        @sprites["glow1"].oy -= 2
        @sprites["shine"].oy -= 2
      end

      @bounce += 1
      @bounce = 0 if @bounce >= ModularTitleFrameCap::TARGET_FPS * 10
    end

    # Shine animation
    if @shine
      @sprites["shine"].src_rect.x += 10
      @sprites["shine"].x = self.x + @sprites["shine"].src_rect.x
      @sprites["shine"].src_rect.x = -16 if @sprites["shine"].src_rect.x > Graphics.width * 12
    end

    # Sparkle animation
    if @sparkle
      for i in 0...12
        next if i > @fpIndex / 20
        if @sprites["s#{i}"].opacity <= 0
          z = 0.8 + rand(7) / 10.0
          @sprites["s#{i}"].zoom_x = z
          @sprites["s#{i}"].zoom_y = z
          @sprites["s#{i}"].opacity = 255
          @sprites["s#{i}"].angle = rand(360)
          @sprites["s#{i}"].toggle = rand(2) == 0 ? 1 : -1
          @sprites["s#{i}"].x = self.x - @sprites["logo1"].bitmap.width / 2 + rand(@sprites["logo1"].bitmap.width)
          @sprites["s#{i}"].y = self.y - @sprites["logo1"].bitmap.height * 0.85 + rand(@sprites["logo1"].bitmap.height * 0.7)
        end
        @sprites["s#{i}"].zoom_x -= 0.05 if @sprites["s#{i}"].zoom_x > 0
        @sprites["s#{i}"].zoom_y -= 0.05 if @sprites["s#{i}"].zoom_y > 0
        @sprites["s#{i}"].angle += 4 * @sprites["s#{i}"].toggle
        @sprites["s#{i}"].opacity -= 4
      end
    end

    @fpIndex += 1 if @fpIndex < 512
  end
end

#===============================================================================









