#===============================================================================
# Game Logo visuals and animations
#===============================================================================
# Game logo class
class MTS_Element_Logo
  LOGO1_CENTER_X_OFFSET = -4
  LOGO1_CENTER_Y_OFFSET = 0

  attr_accessor :x, :y
  def id; return "logo"; end
  def id?(val); return self.id == val; end
  # main class constructor
  def initialize(viewport)
    @viewport = viewport
    @outline = 0
    @glow = 0
    @bounce = -1
    @shine = false
    @sparkle = false
    @disposed = false
    @sprites = {}
    @fpIndex = 0
    @custom_logo_x = false
    # coordinates
    @x = @viewport.rect.width / 2
    @y = @viewport.rect.height / 2 + 42
    #---------------------------------------------------------------------------
    # checks for logo modifiers
    for mod in ModularTitle::MODIFIERS
      if mod.is_a?(String)
        # positioning modifier
        if mod.include?("logoX:")
          @x = mod.gsub("logoX:","").to_i
          @custom_logo_x = true
        end
        @y = mod.gsub("logoY:","").to_i if mod.include?("logoY:")
        # additional logo modifiers
        if mod.include?("logo:")
          mfr = mod.gsub("logo:","")
          # outline modifier
          if mfr.include?("outline")
            @outline = mfr.gsub("outline","").to_i;
            @outline = 3 if @outline <= 0
          end
          # glow modifier
          @glow = 1 if mfr.include?("glow")
          # bounce modifier
          @bounce = 0 if mfr.include?("bounce")
          # shine modifier
          @shine = true if mfr.include?("shine")
          # sparkling modifier
          @sparkle = true if mfr.include?("sparkle")
        end
      end
    end
    # creates transparent sublogo compatibility sprites ------------------------
    @sprites["logo2"] = Sprite.new(@viewport)
    @sprites["glow2"] = Sprite.new(@viewport)
    @sprites["glow2"].visible = false
    @sprites["glow2"].opacity = 0
      @sprites["logo2"].bitmap = Bitmap.new(1,1)
      @sprites["glow2"].bitmap = Bitmap.new(1,1)
      # logo metrics -----------------------------------------------------------
      @sprites["logo2"].z = 99999
      @sprites["logo2"].ox = @sprites["logo2"].bitmap.width/2
      @sprites["logo2"].visible = false
      @sprites["logo2"].opacity = 0
      @sprites["logo2"].color = Color.new(255,255,255,0)
      # glow metrics -----------------------------------------------------------
      @sprites["glow2"].z = 998
      @sprites["glow2"].ox = @sprites["glow2"].bitmap.width/2
      @sprites["glow2"].oy = 10
      @sprites["glow2"].color = Color.new(255,255,255,0)
    # creates logo -------------------------------------------------------------
    @sprites["logo1"] = Sprite.new(@viewport)
    @sprites["glow1"] = Sprite.new(@viewport)
    @sprites["glow1"].visible = @glow > 0
    @sprites["glow1"].opacity = 0
      # draw bitmap ------------------------------------------------------------
      bmp = pbBitmap("Graphics/MODTS/logo1")
      @sprites["logo1"].bitmap = Bitmap.new(bmp.width+@outline*2,bmp.height+@outline*2)
      @sprites["logo1"].bitmap.blt(@outline,@outline,bmp,bmp.rect)
      @sprites["logo1"].create_outline(Color.new(255,255,255,128),@outline) if @outline > 0
      # draw outside glow ------------------------------------------------------
      @sprites["glow1"].bitmap = Bitmap.new(bmp.width+16,bmp.height+16)
      @sprites["glow1"].bitmap.blt(8,8,bmp,bmp.rect)
      @sprites["glow1"].glow(Color.new(252,242,209),35,false)
      bmp.dispose
      # logo metrics -----------------------------------------------------------
      @sprites["logo1"].z = 999
      @sprites["logo1"].ox = @sprites["logo1"].bitmap.width/2
      @sprites["logo1"].oy = @sprites["logo1"].bitmap.height/2
      @sprites["logo1"].color = Color.new(255,255,255,0)
      # glow metrics
      @sprites["glow1"].z = 998
      @sprites["glow1"].ox = @sprites["glow1"].bitmap.width/2
      @sprites["glow1"].oy = @sprites["glow1"].bitmap.height/2
    # creates logo shine -------------------------------------------------------
    @sprites["shine"] = Sprite.new(@viewport)
    bmp = pbBitmap("Graphics/MODTS/logo3")
    @sprites["shine"].bitmap = Bitmap.new(bmp.width+@outline*2,bmp.height+@outline*2)
    @sprites["shine"].bitmap.blt(@outline,@outline,bmp,bmp.rect)
    @sprites["shine"].z = 999
    @sprites["shine"].ox = @sprites["shine"].bitmap.width/2
    @sprites["shine"].oy = @sprites["shine"].bitmap.height/2
    @sprites["shine"].src_rect.width = 16
    @sprites["shine"].src_rect.x = -16
    @sprites["shine"].visible = @shine
    bmp.dispose
    # creates sparkling particles (if applicable) ------------------------------
    if @sparkle
      for i in 0...12
        @sprites["s#{i}"] = Sprite.new(@viewport)
        @sprites["s#{i}"].z = 999
        @sprites["s#{i}"].bitmap = pbBitmap("Graphics/MODTS/Particles/special002")
        @sprites["s#{i}"].center!
        @sprites["s#{i}"].zoom_x = 0
        @sprites["s#{i}"].zoom_y = 0
        @sprites["s#{i}"].opacity = 0
      end
    end
  end
  # method to reposition the logo
  def position(x = nil, y = nil)
    @x = x if !x.nil?
    @y = y if !y.nil?
  
    main_x = x.nil? ? self.x : x
    main_y = y.nil? ? self.y : y
    main_x += LOGO1_CENTER_X_OFFSET if !@custom_logo_x
    main_y += LOGO1_CENTER_Y_OFFSET
  
    @sprites["logo1"].x = main_x
    @sprites["logo1"].y = main_y
  
    @sprites["logo2"].x = main_x
    @sprites["logo2"].y = main_y
  
    @sprites["shine"].x = main_x
    @sprites["shine"].y = main_y
  
    @sprites["glow1"].x = main_x
    @sprites["glow1"].y = main_y
  
    @sprites["glow2"].x = main_x
    @sprites["glow2"].y = main_y
  end
  # sets visibility
  def visible=(val)
    for key in @sprites.keys
      @sprites[key].visible = val
    end
  end
  # disposes of everything
  def dispose
    @disposed = true
    pbDisposeSpriteHash(@sprites)
  end
  # update method
  def update
    return if self.disposed?
    # glow animation
    @sprites["logo1"].color.alpha += @glow*0.5
    @sprites["glow1"].opacity += @glow
    @glow *= -1 if @sprites["logo1"].color.alpha <= 0 || @sprites["logo1"].color.alpha > 63
    # bounce animation
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
      @bounce = 0 if @bounce >= Graphics.frame_rate*10
    end
    # shine animation
    if @shine
      @sprites["shine"].src_rect.x += 10
      @sprites["shine"].x = self.x + @sprites["shine"].src_rect.x
      @sprites["shine"].src_rect.x = -16 if @sprites["shine"].src_rect.x > Graphics.width*12
    end
    # sparkling animation
    if @sparkle
      for i in 0...12
        next if i > @fpIndex/20
        if @sprites["s#{i}"].opacity <= 0
          z = 0.8 + rand(7)/10.0
          @sprites["s#{i}"].zoom_x = z
          @sprites["s#{i}"].zoom_y = z
          @sprites["s#{i}"].opacity = 255
          @sprites["s#{i}"].angle = rand(360)
          @sprites["s#{i}"].toggle = rand(2)==0 ? 1 : -1
          @sprites["s#{i}"].x = self.x - @sprites["logo1"].bitmap.width/2 + rand(@sprites["logo1"].bitmap.width)
          @sprites["s#{i}"].y = self.y - @sprites["logo1"].bitmap.height*0.85 + rand(@sprites["logo1"].bitmap.height*0.7)
        end
        @sprites["s#{i}"].zoom_x -= 0.05 if @sprites["s#{i}"].zoom_x > 0
        @sprites["s#{i}"].zoom_y -= 0.05 if @sprites["s#{i}"].zoom_y > 0
        @sprites["s#{i}"].angle += 4*@sprites["s#{i}"].toggle
        @sprites["s#{i}"].opacity -= 4
      end
    end
    @fpIndex += 1 if @fpIndex < 512
  end
  # sprite handlers
  def logo; return @sprites["logo1"]; end
  def logo=(val); @sprites["logo1"]=val; end
  def sublogo; return @sprites["logo2"]; end
  def sublogo=(val); @sprites["logo2"]=val; end
  # checks if disposed
  def disposed?; return @disposed; end
  # end
end
#===============================================================================
