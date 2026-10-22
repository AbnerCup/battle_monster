module Compiler
  SCRIPT_REPLACEMENTS = [
    ["Kernel.",                      ""],
    ["$PokemonBag.pbQuantity",       "$bag.quantity"],
    ["$PokemonBag.pbHasItem?",       "$bag.has?"],
    ["$PokemonBag.pbCanStore?",      "$bag.can_add?"],
    ["$PokemonBag.pbStoreItem",      "$bag.add"],
    ["$PokemonBag.pbStoreAllOrNone", "$bag.add_all"],
    ["$PokemonBag.pbChangeItem",     "$bag.replace_item"],
    ["$PokemonBag.pbDeleteItem",     "$bag.remove"],
    ["$PokemonBag.pbIsRegistered?",  "$bag.registered?"],
    ["$PokemonBag.pbRegisterItem",   "$bag.register"],
    ["$PokemonBag.pbUnregisterItem", "$bag.unregister"],
    ["$PokemonBag",                  "$bag"],
    ["pbQuantity",                   "$bag.quantity"],
    ["pbHasItem?",                   "$bag.has?"],
    ["pbCanStore?",                  "$bag.can_add?"],
    ["pbStoreItem",                  "$bag.add"],
    ["pbStoreAllOrNone",             "$bag.add_all"],
    ["$Trainer",                     "$player"],
    ["$SaveVersion",                 "$save_engine_version"],
    ["$game_version",                "$save_game_version"],
    ["$MapFactory",                  "$map_factory"],
    ["pbDayCareDeposited",           "DayCare.count"],
    ["pbDayCareGetDeposited",        "DayCare.get_details"],
    ["pbDayCareGetLevelGain",        "DayCare.get_level_gain"],
    ["pbDayCareDeposit",             "DayCare.deposit"],
    ["pbDayCareWithdraw",            "DayCare.withdraw"],
    ["pbDayCareChoose",              "DayCare.choose"],
    ["pbDayCareGetCompatibility",    "DayCare.get_compatibility"],
    ["pbEggGenerated?",              "DayCare.egg_generated?"],
    ["pbDayCareGenerateEgg",         "DayCare.collect_egg"],
    ["get_character(0)",             "get_self"],
    ["get_character(-1)",            "get_player"],
    ["pbCheckAble",                  "$player.has_other_able_pokemon?"],
    ["$PokemonTemp.lastbattle",      "$game_temp.last_battle_record"],
    ["calcStats",                    "calc_stats"]
  ]

  module_function

  #---------------------------------------------------------------------------
  # PATCH SHOP EVENTS
  #---------------------------------------------------------------------------
  def shop_event_name?(name)
    return false if !name
    return true if name =~ /^Sell \d+ Point(?: Down)?$/i
    return true if name =~ /^Selling \d+ Method(?: Down)?$/i
    return false
  end

  #=============================================================================
  # Convert events used as counters into proper counters.
  #=============================================================================
  # Checks if the event has just 1 page, which has no conditions and no commands
  # and whose movement type is "Fixed".
  def plain_event?(event)
    return false unless event
    return false if shop_event_name?(event.name)
    return false if event.pages.length > 1
    return false if event.pages[0].move_type != 0
    return false if event.pages[0].condition.switch1_valid ||
                    event.pages[0].condition.switch2_valid ||
                    event.pages[0].condition.variable_valid ||
                    event.pages[0].condition.self_switch_valid
    return true if event.pages[0].list.length <= 1
    return false
  end

  # Checks if the event has just 1 page, which has no conditions and whose
  # movement type is "Fixed". Then checks if there are no commands, or it looks
  # like a simple Mart or a Poké Center nurse event.
  def plain_event_or_mart?(event)
    return false unless event
    return false if shop_event_name?(event.name)
    return false if event.pages.length > 1
    return false if event.pages[0].move_type != 0
    return false if event.pages[0].condition.switch1_valid ||
                    event.pages[0].condition.switch2_valid ||
                    event.pages[0].condition.variable_valid ||
                    event.pages[0].condition.self_switch_valid
    # No commands in the event
    return true if event.pages[0].list.length <= 1
    # pbPokemonMart events
    return true if event.pages[0].list.length <= 12 &&
                   event.pages[0].graphic.character_name != "" &&
                   event.pages[0].list[0].code == 355 &&
                   event.pages[0].list[0].parameters[0][/^pbPokemonMart/]
    # pbSetPokemonCenter events
    return true if event.pages[0].list.length > 8 &&
                   event.pages[0].graphic.character_name != "" &&
                   event.pages[0].list[0].code == 355 &&
                   event.pages[0].list[0].parameters[0][/^pbSetPokemonCenter/]
    return false
  end

  # Given two events that are next to each other, decides whether otherEvent is
  # likely to be a "counter event", i.e. is placed on a tile with the Counter
  # flag, or is on a non-passable tile between two passable tiles (e.g. a desk)
  # where one of those two tiles is occupied by thisEvent.
  def likely_counter?(thisEvent, otherEvent, mapID, mapData)
    # Protection supplémentaire pour les events de shop
    return false if shop_event_name?(thisEvent&.name)
    return false if shop_event_name?(otherEvent&.name)

    # Check whether otherEvent is on a counter tile
    return true if mapData.isCounterTile?(mapID, otherEvent.x, otherEvent.y)
    # Check whether otherEvent is between an event with a graphic (e.g. an NPC)
    # and a spot where the player can be
    yonderX = otherEvent.x + (otherEvent.x - thisEvent.x)
    yonderY = otherEvent.y + (otherEvent.y - thisEvent.y)
    return thisEvent.pages[0].graphic.character_name != "" &&
           otherEvent.pages[0].graphic.character_name == "" &&
           otherEvent.pages[0].trigger == 0 &&
           mapData.isPassable?(mapID, thisEvent.x, thisEvent.y) &&
           !mapData.isPassable?(mapID, otherEvent.x, otherEvent.y) &&
           mapData.isPassable?(mapID, yonderX, yonderY)
  end

  # Checks all events in the given map to see if any look like they've been
  # placed on a desk with an NPC behind it, where the event on the desk is the
  # actual interaction with the NPC.
  def check_counters(map, mapID, mapData)
    toDelete = []
    changed = false
    map.events.each_key do |key|
      event = map.events[key]
      next if !event
      next if shop_event_name?(event.name)
      next if !plain_event_or_mart?(event)

      # Found an event that is empty or looks like a simple Mart or a Poké
      # Center nurse. Check adjacent events to see if they are "counter events".
      neighbors = []
      neighbors.push(mapData.getEventFromXY(mapID, event.x, event.y - 1))
      neighbors.push(mapData.getEventFromXY(mapID, event.x, event.y + 1))
      neighbors.push(mapData.getEventFromXY(mapID, event.x - 1, event.y))
      neighbors.push(mapData.getEventFromXY(mapID, event.x + 1, event.y))
      neighbors.compact!

      neighbors.each do |otherEvent|
        next if !otherEvent
        next if shop_event_name?(otherEvent.name)
        next if plain_event?(otherEvent)
        next if !likely_counter?(event, otherEvent, mapID, mapData)

        # Found an adjacent event that looks like it's supposed to be a counter.
        # Set the counter flag of the tile beneath the counter event, copy the
        # counter event's pages to the NPC event, and delete the counter event.
        mapData.setCounterTile(mapID, otherEvent.x, otherEvent.y)
        savedPage = event.pages[0]
        event.pages = otherEvent.pages
        apply_pages(savedPage, event.pages)
        toDelete.push(otherEvent.id)
        changed = true
      end
    end
    toDelete.each { |key| map.events.delete(key) }
    return changed
  end
end