#===============================================================================
# Pokemon Survivor - paths and core constants
#===============================================================================
module PokemonSurvivor
  ROOT              = "Graphics/UI/Survivor Game"
  HERO_DIR          = "#{ROOT}/Pokemon Survivor"
  HERO_SHINY_DIR    = "#{ROOT}/Pokemon Survivor Shiny"
  HERO_ALT_DIR      = "#{ROOT}/Pokemon Survivor Alt"
  HERO_ALT_SHINY_DIR = "#{ROOT}/Pokemon Survivor Alt Shiny"
  WILD_DIR          = "#{ROOT}/Pokemon Wild"
  BOSS_DIR          = "#{ROOT}/Pokemon Boss"
  ULTRA_BEAST_DIR   = "#{ROOT}/Pokemon Boss/ULTRABEAST"
  PARADOX_DIR       = "#{ROOT}/Pokemon Boss/PARADOX"
  CHEST_DIR         = "#{ROOT}/Pokemon Chest"
  ULTRA_BOSS_DIR    = "#{ROOT}/Pokemon Ultra Boss"
  ULTRA_CHEST_DIR   = "#{ROOT}/Pokemon Ultra Chest"
  BACKGROUND_DIR    = "#{ROOT}/Background"
  ITEM_DIR          = "#{ROOT}/Items Wild"
  EVENT_DIR         = "#{ROOT}/Pokemon Event"
  EVENT_BABY_DIR    = "#{ROOT}/Pokemon Event/BABY"
  EVENT_BABY_SHINY_DIR = "#{ROOT}/Pokemon Event/BABY Shiny"
  EVENT_SLEEP_DIR   = "#{ROOT}/Pokemon Event/SLEEP"
  ICON_DIR          = "#{ROOT}/Icons"
  VFX_DIR           = "#{ROOT}/VFX"
  SHOP_DIR          = "#{ROOT}/Menu HUD/Shop"
  EQUIPMENT_DIR     = "#{ROOT}/Menu HUD/Equipment"
  VFX_BY_TYPE       = {
    :NORMAL   => "VFX_NORMAL",
    :FIRE     => "VFX_FIRE",
    :WATER    => "VFX_WATER",
    :GRASS    => "VFX_GRASS",
    :ELECTRIC => "VFX_ELECTRIC_SHOT",
    :ICE      => "VFX_ICE_ZONE",
    :FLYING   => "VFX_FLYING",
    :BUG      => "VFX_BUG",
    :FIGHTING => "VFX_FIGHTING",
    :POISON   => "VFX_POISON_TRAIL",
    :GROUND   => "VFX_GROUND",
    :PSYCHIC  => "VFX_PSYCHIC",
    :ROCK     => "VFX_ROCK",
    :GHOST    => "VFX_GHOST",
    :DRAGON   => "VFX_DRAGON",
    :DARK     => "VFX_DARK",
    :STEEL    => "VFX_STEEL_ORBIT",
    :FAIRY    => "VFX_FAIRY"
  }

  MAX_SECONDS       = 3600
  DOOM_ENEMY_NAME   = "000"
  DOOM_START_TIME   = 10 * 60
  DOOM_ONLY_TIME    = 15 * 60
  STEP_DT           = 1.0 / 60.0
  MAX_STEPS_FRAME   = 4
  MAX_ACTIVE_SKILLS = 3
  STAB_DAMAGE_MULTIPLIER = 1.20
  FORM_TYPE_OVERRIDES = {
    :NIDORANm => [:POISON], :NIDORANf => [:POISON],
    :ARCANINE_1 => [:FIRE, :ROCK], :ARTICUNO_1 => [:PSYCHIC, :FLYING], :AVALUGG_1 => [:ICE, :ROCK],
    :BASCULIN_1 => [:WATER], :BASCULIN_2 => [:WATER], :BRAVIARY_1 => [:PSYCHIC, :FLYING],
    :BURMY_1 => [:BUG], :BURMY_2 => [:BUG], :CASTFORM_1 => [:FIRE], :CASTFORM_2 => [:WATER], :CASTFORM_3 => [:ICE],
    :CHERRIM_1 => [:GRASS], :DARMANITAN_1 => [:ICE], :DARMANITAN_2 => [:ICE, :FIRE], :DARUMAKA_1 => [:ICE],
    :DEERLING_1 => [:NORMAL, :GRASS], :DEERLING_2 => [:NORMAL, :GRASS], :DEERLING_3 => [:NORMAL, :GRASS],
    :ELECTRODE_1 => [:ELECTRIC, :GRASS], :EXEGGUTOR_1 => [:GRASS, :DRAGON], :FARFETCHD_1 => [:FIGHTING],
    :GASTRODON_1 => [:WATER, :GROUND], :GEODUDE_1 => [:ROCK, :ELECTRIC], :GOLEM_1 => [:ROCK, :ELECTRIC],
    :GOODRA_1 => [:STEEL, :DRAGON], :GRAVELER_1 => [:ROCK, :ELECTRIC], :GRIMER_1 => [:POISON, :DARK],
    :GROWLITHE_1 => [:FIRE, :ROCK], :JELLICENT_1 => [:WATER, :GHOST], :KYUREM_1 => [:DRAGON, :ICE], :KYUREM_2 => [:DRAGON, :ICE],
    :LANDORUS_1 => [:GROUND, :FLYING], :LILLIGANT_1 => [:GRASS, :FIGHTING], :LINOONE_1 => [:DARK, :NORMAL],
    :MAROWAK_1 => [:FIRE, :GHOST], :MELOETTA_1 => [:NORMAL, :FIGHTING], :MEOWTH_1 => [:DARK], :MEOWTH_2 => [:STEEL],
    :MOLTRES_1 => [:DARK, :FLYING], :MRMIME_1 => [:ICE, :PSYCHIC], :MUK_1 => [:POISON, :DARK], :NINETALES_1 => [:ICE, :FAIRY],
    :PERSIAN_1 => [:DARK], :PONYTA_1 => [:PSYCHIC], :QWILFISH_1 => [:DARK, :POISON], :RAICHU_1 => [:ELECTRIC, :PSYCHIC],
    :RAPIDASH_1 => [:PSYCHIC, :FAIRY], :RATICATE_1 => [:DARK, :NORMAL], :RATTATA_1 => [:DARK, :NORMAL],
    :ROTOM_1 => [:ELECTRIC, :FIRE], :ROTOM_2 => [:ELECTRIC, :WATER], :ROTOM_3 => [:ELECTRIC, :ICE], :ROTOM_4 => [:ELECTRIC, :FLYING], :ROTOM_5 => [:ELECTRIC, :GRASS],
    :SAMUROTT_1 => [:WATER, :DARK], :SANDSHREW_1 => [:ICE, :STEEL], :SANDSLASH_1 => [:ICE, :STEEL],
    :SAWSBUCK_1 => [:NORMAL, :GRASS], :SAWSBUCK_2 => [:NORMAL, :GRASS], :SAWSBUCK_3 => [:NORMAL, :GRASS],
    :SHAYMIN_1 => [:GRASS, :FLYING], :SHELLOS_1 => [:WATER], :SLIGGOO_1 => [:STEEL, :DRAGON],
    :SLOWBRO_1 => [:POISON, :PSYCHIC], :SLOWKING_1 => [:POISON, :PSYCHIC], :SLOWPOKE_1 => [:PSYCHIC],
    :SNEASEL_1 => [:FIGHTING, :POISON], :TAUROS_1 => [:FIGHTING], :TAUROS_2 => [:FIGHTING, :FIRE], :TAUROS_3 => [:FIGHTING, :WATER],
    :TYPHLOSION_1 => [:FIRE, :GHOST], :UNFEZANT_1 => [:NORMAL, :FLYING], :VOLTORB_1 => [:ELECTRIC, :GRASS],
    :VULPIX_1 => [:ICE], :WEEZING_1 => [:POISON, :FAIRY], :WOOPER_1 => [:POISON, :GROUND],
    :WORMADAM_1 => [:BUG, :GROUND], :WORMADAM_2 => [:BUG, :STEEL], :YAMASK_1 => [:GROUND, :GHOST],
    :ZAPDOS_1 => [:FIGHTING, :FLYING], :ZIGZAGOON_1 => [:DARK, :NORMAL], :ZORUA_1 => [:NORMAL, :GHOST], :ZOROARK_1 => [:NORMAL, :GHOST],
    :AEGISLASH_1 => [:STEEL, :GHOST], :DECIDUEYE_1 => [:GRASS, :FIGHTING], :HOOPA_1 => [:PSYCHIC, :DARK], :LYCANROC_1 => [:ROCK], :LYCANROC_2 => [:ROCK],
    :MAGEARNA_1 => [:STEEL, :FAIRY], :MARSHADOW_1 => [:FIGHTING, :GHOST], :MIMIKYU_1 => [:GHOST, :FAIRY], :ORICORIO_1 => [:FIRE, :FLYING], :ORICORIO_2 => [:ELECTRIC, :FLYING],
    :WISHIWASHI_1 => [:WATER], :ZYGARDE_1 => [:DRAGON, :GROUND], :ZYGARDE_2 => [:DRAGON, :GROUND]
  }.freeze unless const_defined?(:FORM_TYPE_OVERRIDES)
  CHARSET_FRAMES    = 4
  IDLE_ANIMATION_FPS = 6.0
  CHARSET_DIRECTIONS = 4
  CHARSET_8_DIRECTIONS = 8
  DIR_DOWN          = 0
  DIR_LEFT          = 1
  DIR_RIGHT         = 2
  DIR_UP            = 3
  DIR8_DOWN         = 0
  DIR8_DOWN_RIGHT   = 1
  DIR8_RIGHT        = 2
  DIR8_UP_RIGHT     = 3
  DIR8_UP           = 4
  DIR8_UP_LEFT      = 5
  DIR8_LEFT         = 6
  DIR8_DOWN_LEFT    = 7
  HERO_RADIUS       = 14
  HERO_DRAW_OFFSET_X = 0
  HERO_DRAW_OFFSET_Y = -8
  HERO_EFFECT_OFFSET_X = 0
  HERO_EFFECT_OFFSET_Y = 0
  ENEMY_RADIUS      = 15
  PROJECTILE_RADIUS = 8
  ITEM_RADIUS       = 16
  XP_RADIUS         = 10
  XP_DROP_LIFETIME   = 300.0
  CHEST_RADIUS      = 17
  BOSS_RADIUS       = 24
  ULTRA_BOSS_RADIUS = 30
  ULTRA_CHEST_RADIUS = 21
  MAX_WILD_ENEMIES  = 280
  MAX_DOOM_ENEMIES  = 128
  MAX_REINFORCED_WILD_ENEMIES = 5
  MAX_PROJECTILES   = 240
  MAX_XP_GEMS       = 160
  WILD_ITEM_LIFETIME = 12.0
  MAX_EFFECTS       = 80
  ENEMY_CULL_MARGIN = 160
  ENEMY_GRID_CELL   = 64
  CHARACTER_VISUAL_Y_OFFSET = 10
  EVENT_BABY_KEYS = [:ELEKID, :HAPPINY, :MAGBY, :SMOOCHUM, :TOGEPI, :TYROGUE, :MANTYKE, :MIMEJR, :MUNCHLAX]
  EVENT_SLEEP_KEYS = [:TAPUBULU, :TAPUKOKO, :TAPULELE, :TAPUFINI]
end


