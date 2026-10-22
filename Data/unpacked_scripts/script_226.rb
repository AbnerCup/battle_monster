#===============================================================================
#
#===============================================================================
class PokegearButton < Sprite
  attr_reader :index
  attr_reader :name
  attr_reader :selected

  TEXT_BASE_COLOR = Color.new(248, 248, 248)
  TEXT_SHADOW_COLOR = Color.new(40, 40, 40)

  def initialize(command, x, y, viewport = nil)
    super(viewport)
    @image = command[0]
    @name  = command[1]
    @selected = false
    if $player.female? && pbResolveBitmap("Graphics/UI/Pokegear/icon_button_f")
      @button = AnimatedBitmap.new("Graphics/UI/Pokegear/icon_button_f")
    else
      @button = AnimatedBitmap.new("Graphics/UI/Pokegear/icon_button")
    end
    @contents = Bitmap.new(@button.width, @button.height)
    self.bitmap = @contents
    self.x = x - (@button.width / 2)
    self.y = y
    pbSetSystemFont(self.bitmap)
    refresh
  end

  def dispose
    @button.dispose
    @contents.dispose
    super
  end

  def selected=(val)
    oldsel = @selected
    @selected = val
    refresh if oldsel != val
  end

  def refresh
    self.bitmap.clear
    rect = Rect.new(0, 0, @button.width, @button.height / 2)
    rect.y = @button.height / 2 if @selected
    self.bitmap.blt(0, 0, @button.bitmap, rect)
    textpos = [
      [@name, rect.width / 2, (rect.height / 2) - 10, :center, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR]
    ]
    pbDrawTextPositions(self.bitmap, textpos)
    imagepos = [
      [sprintf("Graphics/UI/Pokegear/icon_%s", @image), 18, 10]
    ]
    pbDrawImagePositions(self.bitmap, imagepos)
  end
end

#===============================================================================
#
#===============================================================================
class PokemonPokegear_Scene
  def pbUpdate
    @commands.length.times do |i|
      @sprites["button#{i}"].selected = (i == @index)
    end
    pbUpdateSpriteHash(@sprites)
  end

  def pbRefresh
    return if !@sprites
    @commands.length.times do |i|
      next if !@sprites["button#{i}"]
      @sprites["button#{i}"].refresh
      @sprites["button#{i}"].selected = (i == @index)
    end
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(commands)
    @commands = commands
    @index = 0
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    if $player.female? && pbResolveBitmap("Graphics/UI/Pokegear/bg_f")
      @sprites["background"].setBitmap("Graphics/UI/Pokegear/bg_f")
    else
      @sprites["background"].setBitmap("Graphics/UI/Pokegear/bg")
    end
    @commands.length.times do |i|
      @sprites["button#{i}"] = PokegearButton.new(@commands[i], Graphics.width / 2, 0, @viewport)
      button_height = @sprites["button#{i}"].bitmap.height / 2
      @sprites["button#{i}"].y = ((Graphics.height - (@commands.length * button_height)) / 2) + (i * button_height)
    end
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbScene
    ret = -1
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        ret = @index
        break
      elsif Input.trigger?(Input::UP)
        pbPlayCursorSE if @commands.length > 1
        @index -= 1
        @index = @commands.length - 1 if @index < 0
      elsif Input.trigger?(Input::DOWN)
        pbPlayCursorSE if @commands.length > 1
        @index += 1
        @index = 0 if @index >= @commands.length
      end
    end
    return ret
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    dispose
  end

  def dispose
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
#
#===============================================================================
class PokemonPokegearScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    # Get all commands
    command_list = []
    commands = []
    MenuHandlers.each_available(:pokegear_menu) do |option, hash, name|
      command_list.push([hash["icon_name"] || "", name])
      commands.push(hash)
    end
    @scene.pbStartScene(command_list)
    # Main loop
    end_scene = false
    loop do
      choice = @scene.pbScene
      if choice < 0
        end_scene = true
        break
      end
      break if commands[choice]["effect"].call(@scene)
    end
    @scene.pbEndScene if end_scene
  end
end

#===============================================================================
#
#===============================================================================
MenuHandlers.add(:pokegear_menu, :map, {
  "name"      => _INTL("Map"),
  "icon_name" => "map",
  "order"     => 10,
  "effect"    => proc { |menu|
    pbFadeOutIn do
      scene = PokemonRegionMap_Scene.new(-1, false)
      screen = PokemonRegionMapScreen.new(scene)
      ret = screen.pbStartScreen
      if ret
        $game_temp.fly_destination = ret
        menu.dispose
        next 99999
      end
    end
    next $game_temp.fly_destination
  }
})

MenuHandlers.add(:pokegear_menu, :trainer_card, {
  "name"      => proc { next $player.name },
  "icon_name" => "trainer",
  "order"     => 20,
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    pbFadeOutIn {
      scene = PokemonTrainerCard_Scene.new
      screen = PokemonTrainerCardScreen.new(scene)
      screen.pbStartScreen
    }
    next false
  }
})

MenuHandlers.add(:pokegear_menu, :phone, {
  "name"      => _INTL("Phone"),
  "icon_name" => "phone",
  "order"     => 30,
"condition" => proc { next $bag.has?(:POKENAV) },
  "effect"    => proc { |menu|
    pbFadeOutIn do
      scene = PokemonPokenav_Scene.new
      screen = PokemonPokenavScreen.new(scene)
      screen.pbStartScreen
    end
    next false
  }
})

MenuHandlers.add(:pokegear_menu, :itemcrafterball, {
  "name"      => _INTL("Ball"),
  "icon_name" => "craftingball",
  "order"     => 40,
  "condition" => proc { next $bag.has?(:ITEMCRAFTER) },
  "effect"    => proc { |menu|
    pbFadeOutIn do
      pbItemCrafter(pbGetRecipes("Ball"))
    end
    next false
  }
})

MenuHandlers.add(:pokegear_menu, :itemcrafterpotion, {
  "name"      => _INTL("Potion"),
  "icon_name" => "craftingpotion",
  "order"     => 41,
  "condition" => proc { next $bag.has?(:ITEMCRAFTER) },
  "effect"    => proc { |menu|
    pbFadeOutIn do
      pbItemCrafter(pbGetRecipes("Potion"))
    end
    next false
  }
})

MenuHandlers.add(:pokegear_menu, :itemcrafterutility, {
  "name"      => _INTL("Utility"),
  "icon_name" => "craftingutility",
  "order"     => 42,
  "condition" => proc { next $bag.has?(:ITEMCRAFTER) },
  "effect"    => proc { |menu|
    pbFadeOutIn do
      pbItemCrafter(pbGetRecipes("Utility"))
    end
    next false
  }
})

MenuHandlers.add(:pokegear_menu, :medals, {
  "name"      => _INTL("Success"),
  "icon_name" => "success",
  "order"     => 43,
  "condition" => proc { next $bag.has?(:MEDALBOX) },
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    scene = PokemonMedalBox_Scene.new
    scene.pbStartScene
    scene.pbMain
    scene.pbEndScene
    menu.pbRefresh
    next false
  }
})